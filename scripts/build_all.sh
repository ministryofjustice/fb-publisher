#!/usr/bin/env sh
# exit as soon as any command fails
set -e

REPO_SCOPE=${REPO_SCOPE:-aldavidson}
TAG=${TAG:- latest}

for TYPE in base web worker
do
  REPO_NAME=${REPO_SCOPE}/fb-publisher-${TYPE}
  echo "Building ${REPO_NAME}"
  docker build -f docker/${TYPE}/Dockerfile -t ${REPO_NAME}:${TAG} --build-arg BUNDLE_FLAGS='--deployment --without test development' --build-arg BASE_IMAGE=${REPO_SCOPE}/fb-publisher-base:${TAG} .
done
