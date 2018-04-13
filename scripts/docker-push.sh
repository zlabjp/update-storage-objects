#!/usr/bin/env bash

set -eux

DOCKER_TAG="$(echo "${DOCKER_TAG}" | sed -e "s/^v//")"

docker tag zlabjp/update-storage-objects:latest zlabjp/update-storage-objects:${DOCKER_TAG}
docker push zlabjp/update-storage-objects:${DOCKER_TAG}
