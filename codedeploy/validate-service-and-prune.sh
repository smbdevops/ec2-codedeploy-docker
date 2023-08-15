#!/usr/bin/env bash
SOURCE=$(dirname "$0")
if [ "${SOURCE}" = '.' ]; then
  SOURCE=$(pwd)
fi
IMAGE_NAME=$(cat ${SOURCE}/image_name)

WAIT_COUNT=0
WAIT_MAX=90
while true; do
  WAIT_COUNT=$((WAIT_COUNT+1))
  if [[ $WAIT_COUNT -ge $WAIT_MAX ]]; then
    echo >&2 "Exceeded maximum check count of ${WAIT_MAX}"
    exit 2
  fi
  if [ $(docker inspect --format='{{json .State.Health}}' "$IMAGE_NAME" 2>/dev/null | jq '.Status' | grep "unhealthy" | wc -l) -gt 0 ]; then
    echo >&2 "example-app is not healthy."
    sleep 1;
    break;
  fi

  echo >&2 "$IMAGE_NAME is healthy. Starting system prune."
  ## clean things up to ensure we don't run out of disk space with repeated deployments
  docker system prune -a -f
  exit 0
done;
echo >&2 "example-app failed multiple healthchecks"
exit 2
