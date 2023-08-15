#!/usr/bin/env bash
set -x  ## enable debug-level output
set -e  ## exit on any error
ls -alh "${SOURCE}"
df -h ## We want to know how much free space we have at the beginning for logging purposes.


SOURCE=$(dirname "$0")
if [ "${SOURCE}" = '.' ]; then
  SOURCE=$(pwd)
fi

REPOSITORY=$(cat "${SOURCE}"/repository)
IMAGE_NAME=$(cat "${SOURCE}"/image_name)
TAG=$(cat "${SOURCE}"/tag_name)

## authenticate to ECR
docker login -u AWS -p $(aws ecr get-login-password) "${REPOSITORY}"

## If pulling in multiple images ... adjust this script to account for this fact.
docker pull "${REPOSITORY}/${IMAGE_NAME}:${TAG}"
