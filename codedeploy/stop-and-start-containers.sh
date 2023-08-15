#!/usr/bin/env bash
set -x
set -e

SOURCE=$(dirname "$0")
if [ "${SOURCE}" = '.' ]; then
  SOURCE=$(pwd)
fi

REPOSITORY=$(cat "${SOURCE}"/repository)
IMAGE_NAME=$(cat "${SOURCE}"/image_name)
TAG=$(cat "${SOURCE}"/tag_name)

bash -c "${SOURCE}"/example-app-run.sh -r "${REPOSITORY}" -i "${IMAGE_NAME}" -t "${TAG}"