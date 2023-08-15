#!/usr/bin/env bash
REPOSITORY=""
IMAGE_NAME=""
TAG=""

function show_help() {
  cat <<"EOF"
-h Display this menu
-r Repository URI
-i Image to launch
-t Tag of the Docker image
EOF
}


while getopts 'hr:i:t:' OPTION; do
  case ${OPTION} in
  h)
    show_help
    exit 0
    ;;
  r)
    REPOSITORY=$OPTARG
    ;;
  i)
    IMAGE_NAME=$OPTARG
    ;;
  t)
    TAG=$OPTARG
    ;;
  *)
    echo >&2 "Unexpected input was supplied. Please review the required options."
    show_help
    exit 2
    ;;
  esac
done

IMAGE=$REPOSITORY/$IMAGE_NAME:${TAG}


function check_minimum_arguments() {
  local IS_VALID
  IS_VALID=1

  if [ -z "${REPOSITORY}" ]; then
    echo >&2 -e "${RED}Missing Repository argument. specify with -r argument. Example: '-r AWS_ACCOUNT_ID.dkr.ecr.us-west-1.amazonaws.com'.${NC}"
    IS_VALID=0
  fi

  if [ -z "${IMAGE_NAME}" ]; then
    echo >&2 -e "${RED}Missing Container Image name. Specify with the -i argument. Example: '-i nginx'.${NC}"
    IS_VALID=0
  fi

  if [ -z "${TAG}" ]; then
    echo >&2 -e "${RED}missing image tag to deploy. specify with the -t argument. Example: '-t latest'.${NC}"
    IS_VALID=0
  fi

  if [ ${IS_VALID} -eq 0 ]; then
    show_help
    exit 2
  fi
}

function stop_if_running {
    # shellcheck disable=SC2126
    if [[ $(uname -a | grep -i -c "darwin") -eq 1 ]]; then
        ## MacOS version
        docker ps -a | grep "${IMAGE}" | cut -d ' ' -f 1 | xargs docker kill || /usr/bin/true
        docker container ls -a | grep "${IMAGE}" | cut -d ' ' -f 1 | xargs docker container rm || /usr/bin/true
    else
        ## GNU version
        docker ps -a | grep "${IMAGE}" | cut -d ' ' -f 1 | xargs --no-run-if-empty docker kill || /usr/bin/true;
        docker container ls -a | grep "${IMAGE}" | cut -d ' ' -f 1 | xargs --no-run-if-empty docker container rm || /usr/bin/true;
    fi
}

function run {
    docker run -d \
        --name "${IMAGE_NAME}" \
        -p 8080:80 \
        --log-opt tag="{{.Name}}" \
        --restart unless-stopped \
        "${IMAGE}"
}

check_minimum_arguments
stop_if_running
run
