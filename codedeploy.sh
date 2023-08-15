#!/usr/bin/env bash
set -e
set -x

if [[ $(which jq | wc -l) -eq 0 ]]; then
    echo >&2 "Missing JQ dependency. install using apt install jq -y"
    exit 2
fi


if [[ $(which aws | wc -l) -eq 0 ]]; then
    echo >&2 "Missing aws dependency. install directions located at https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 2
fi


RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

## Variables (store content in S3_BUCKET/app-name/year-month/artifact-name.zip for easy removal/cleanup and organization.
YEAR_MONTH=$(date +"%Y-%m")

REPOSITORY=""
IMAGE_NAME=""
IMAGE_TAG=""

AWS_CODE_DEPLOY_APPLICATION_NAME=""
AWS_CODE_DEPLOY_DEPLOYMENT_GROUP=""

AWS_PROFILE=""
S3_BUCKET=""
DEPLOYMENT_ID=""

while getopts 'hb:t:n:g:p:r:' OPTION; do
  case ${OPTION} in
  h)
    show_help
    exit 0
    ;;
  b)
    S3_BUCKET=$OPTARG
    ;;
  r)
    REPOSITORY=$OPTARG
    ;;

  t)
    IMAGE_TAG=$OPTARG
    ;;
  g)
    AWS_CODE_DEPLOY_DEPLOYMENT_GROUP=$OPTARG
    ;;
  n)
    AWS_CODE_DEPLOY_APPLICATION_NAME=$OPTARG
    ;;
  p)
    AWS_PROFILE=$OPTARG
    ;;
  
  *)
    echo >&2 "Unexpected input was supplied. Please review the required options."
    show_help
    exit 2
    ;;
  esac
done

function check_minimum_arguments() {
  local IS_VALID
  IS_VALID=1

  if [ -z "${AWS_CODE_DEPLOY_APPLICATION_NAME}" ]; then
    echo >&2 -e "${RED}Missing AWS Application Name specified with -n argument.${NC}"
    IS_VALID=0
  fi

  if [ -z "${S3_BUCKET}" ]; then
    echo >&2 -e "${RED}Missing AWS Artifact S3 bucket specified with the -a argument.${NC}"
    IS_VALID=0
  fi

  if [ -z "${AWS_PROFILE}" ]; then
    echo >&2 -e "${RED}missing AWS profile name specified with the -p argument.${NC}"
    IS_VALID=0
  fi

  if [ -z "${AWS_CODE_DEPLOY_DEPLOYMENT_GROUP}" ]; then
    echo >&2 -e "${RED}missing AWS CodeDeploy deployment group specified with the -g argument.${NC}"
    IS_VALID=0
  fi

 if [ -z "${IMAGE_TAG}" ]; then
    echo >&2 -e "${RED}missing Git Commit ID -c argument.${NC}"
    IS_VALID=0
  fi

  if [ ${IS_VALID} -eq 0 ]; then
    show_help
    exit 2
  fi
}

function show_help() {
  cat <<"EOF"
-h Display this menu
-p AWS Profile name (used your ~/.aws/credentials)
-r Repository name
-i Image Name of docker
-t Image Tag to push
-g AWS CodeDeploy deployment group (develop,production,etc.)
-a Arfifact bucket name (where the zip file is placed)
-n AWS CodeDeploy application name
EOF
}


SOURCE=$(dirname "$0")
if [ "${SOURCE}" = '.' ]; then
  SOURCE=$(pwd)
fi

if [ ${#SOURCE} -lt 3 ]; then
  echo >&2 "SOURCE directory is TOO SHORT!"
  exit 2
fi


function check_if_artifact_already_exists_and_just_deploy_if_it_does() {
  local COMMAND
  local COMMAND_OUTPUT
  local COMMAND_EXIT_CODE

  COMMAND="aws s3 ls s3://${S3_BUCKET}/${AWS_CODE_DEPLOY_APPLICATION_NAME}/${YEAR_MONTH}/${IMAGE_TAG}.zip --profile ${AWS_PROFILE} --region ${AWS_REGION} | wc -l"
  COMMAND_OUTPUT=$(eval ${COMMAND})
  COMMAND_EXIT_CODE=$?

  if [ ${COMMAND_EXIT_CODE} -gt 0 ]; then
    echo -e "${RED}An error occurred while checking to see if the deployed artifact already exists.${NC} Command output: ${COMMAND_OUTPUT}" >&2
    exit 2
  fi

  if [ ${COMMAND_OUTPUT} -eq 1 ]; then
    echo -e "${GREEN}Deployment artifact already exists for this commit. Proceeding immediately to codedeploy steps.${NC}" >&2
    start_deployment
    watch_deploy
    exit 0
  fi
  echo >&2 "code artifact does not already exist on S3. Continuing with build process..."
  return
}

function zip_and_upload_artifact_to_s3() {
  echo >&2 "Creating the AWS CodeDeploy artifact on S3"
  echo "${REPOSITORY}" > ${SOURCE}/codedeploy/repository
  echo "${IMAGE_NAME}" > ${SOURCE}/codedeploy/image_name
  echo "${TAG}" > ${SOURCE}/codedeploy/tag_name

  cp ${SOURCE}/example-app/run.sh ${SOURCE}/codedeploy/example-app-run.sh
  ls -alh ${SOURCE}/codedeploy
  aws deploy push --application-name ${AWS_CODE_DEPLOY_APPLICATION_NAME} --s3-location "s3://${S3_BUCKET}/${AWS_CODE_DEPLOY_APPLICATION_NAME}/${YEAR_MONTH}/${IMAGE_TAG}.zip" --source ${SOURCE}/codedeploy --profile ${AWS_PROFILE} --region ${AWS_REGION}
  echo >&2 "S3 artifact uploaded. Now calling CodeDeploy to ship it to the ${AWS_CODE_DEPLOY_DEPLOYMENT_GROUP} group."
  rm -f ${SOURCE}/codedeploy/example-app-run.sh
}

function start_deployment() {
  CD_CMD="aws deploy create-deployment --application-name ${AWS_CODE_DEPLOY_APPLICATION_NAME} --s3-location bucket=${S3_BUCKET},key=\"${AWS_CODE_DEPLOY_APPLICATION_NAME}/${YEAR_MONTH}/${IMAGE_TAG}.zip\",bundleType=zip --deployment-group-name ${AWS_CODE_DEPLOY_DEPLOYMENT_GROUP} --profile ${AWS_PROFILE} --region=${AWS_REGION}"
  echo ${CD_CMD}

  DEPLOYMENT_ID=$(eval ${CD_CMD} | jq -r ".deploymentId")
  echo "Deployment Id: ${DEPLOYMENT_ID}"
}

function watch_deploy() {
  local DEPLOY_CHECK_COUNT
  DEPLOY_CHECK_COUNT=0

  if [[ -z "${DEPLOYMENT_ID}" ]]; then
    echo >&2 "DEPLOYMENT_ID was not supplied. Look above for the error."
    post_deploy_failed
    exit 2
  fi

  while true; do
    DEPLOY_CHECK_COUNT=$(expr ${DEPLOY_CHECK_COUNT} + 1)
    if [ ${DEPLOY_CHECK_COUNT} -ge 120 ]; then
      echo >&2 "Been deploying for far too long. failing."
      post_deploy_failed
      exit 2
    fi

    echo >&2 "sleeping for 10 seconds."
    sleep 10
    DEPLOY_STATUS_CHECK_CMD="aws deploy get-deployment --deployment-id ${DEPLOYMENT_ID} --profile ${AWS_PROFILE} --region=${AWS_REGION} --query \"deploymentInfo.status\" --output text || true"
    DEPLOY_STATUS=$(eval "${DEPLOY_STATUS_CHECK_CMD}")
    echo >&2 "Current deploy status: ${DEPLOY_STATUS}"
    if [ "$(echo ${DEPLOY_STATUS} | grep -i "succeeded" | wc -l)" == "1" ]; then
      echo >&2 "DEPLOY COMPLETE"
      post_deploy_successful
      exit 0
    fi

    if [ "$(echo "${DEPLOY_STATUS}" | grep -i "stopped" | wc -l)" == "1" ]; then
      echo >&2 "DEPLOY STOPPED"
      post_deploy_failed $DEPLOYMENT_ID
      exit 2
    fi

    if [ "$(echo "${DEPLOY_STATUS}" | grep -i "failed" | wc -l)" == "1" ]; then
      echo >&2 "DEPLOY FAILED"
      post_deploy_failed $DEPLOYMENT_ID
      exit 2
    fi
  done
}

function post_deploy_successful() {
  echo >&2 "POST_DEPLOY_SUCCESSFUL"
  ## notify services like bugsnag, newrelic, or other APM / bug monitoring systems that a new release has been rolled out.
}

function post_deploy_failed() {
  echo >&2 "POST_DEPLOY_FAILED_SCRIPTS WOULD EXECUTE HERE"

  CMD="aws deploy list-deployment-instances --profile ${AWS_PROFILE} --region $AWS_REGION --deployment-id $DEPLOYMENT_ID"

  if [ -z "${DEPLOYMENT_ID}" ]; then
    echo "post_deploy_failed without a DEPLOYMENT_ID set"
  else
    for instance_id in $($CMD | jq -r '.instancesList[]'); do
        checkFileForError ${DEPLOYMENT_ID} $instance_id
    done
  fi
}

function checkFileForError() {
  DEPLOYMENT_ID=$1
  INSTANCE_ID=$2

  CMD="aws deploy get-deployment-target --profile ${AWS_PROFILE} --deployment-id $DEPLOYMENT_ID --target-id $INSTANCE_ID --region $AWS_REGION"

  for row in $($CMD | jq -r '.deploymentTarget.instanceTarget.lifecycleEvents[] | @base64'); do

    _jq() {
      echo "${row}" | base64 --decode | jq -r "${1}"
    }

    status=$(_jq '.status')
    if [ "${status}" == "Failed" ]; then
      echo >&2 "Failed"
      logTail=$(_jq '.diagnostics.logTail')
      echo >&2 "logTail $logTail"
    fi
  done
}

check_minimum_arguments
check_if_artifact_already_exists_and_just_deploy_if_it_does
zip_and_upload_artifact_to_s3
start_deployment
watch_deploy
exit 0