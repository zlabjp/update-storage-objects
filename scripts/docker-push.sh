#!/usr/bin/env bash

set -eu

DOCKER_TAG="$(echo "${DOCKER_TAG}" | sed -e "s/^v//")"

echo "${DOCKER_PASSWORD}" | docker login -u "${DOCKER_USERNAME}" --password-stdin
docker push zlabjp/update-storage-objects:latest
docker push zlabjp/update-storage-objects:${DOCKER_TAG}
