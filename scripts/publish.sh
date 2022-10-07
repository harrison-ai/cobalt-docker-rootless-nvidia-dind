#!/usr/bin/env bash
#
# Publish the given image to dockerhub.
#

set -e

if [  "$#" -ne 2 ]; then
    >&2 echo "Usage: $(basename $0) <image-name> <tag>"
    exit 1
fi

IMAGE_NAME="$1"
TAG="$2"

echo "Tagging image ${IMAGE_NAME} with tags: '${IMAGE_NAME}:${TAG}', '${IMAGE_NAME}:latest'"

docker tag "${IMAGE_NAME}" "${IMAGE_NAME}:${TAG}"
docker tag "${IMAGE_NAME}" "${IMAGE_NAME}:latest"

echo "Pushing '${IMAGE_NAME}:${TAG}' and '${IMAGE_NAME}:latest'"
docker push "${IMAGE_NAME}:${TAG}"
docker push "${IMAGE_NAME}:latest"
