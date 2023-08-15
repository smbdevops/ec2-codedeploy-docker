#!/usr/bin/env bash
TF_ENV=$1
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd $DIR

if [ $# -gt 0 ]; then
  if [ "$2" == "init" ]; then
    terraform -chdir=./$TF_ENV init -backend-config=../backend-$TF_ENV.tf -var-file=../variables.tfvars -var-file=./variables.tfvars
  elif [ "$2" == "output" ]; then
    terraform -chdir=./$TF_ENV output
  else
    terraform -chdir=./$TF_ENV $2 -var-file=../variables.tfvars -var-file=./variables.tfvars
  fi
fi

cd -