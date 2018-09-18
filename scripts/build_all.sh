#!/usr/bin/env bash

REPO_SCOPE=${REPO_SCOPE:-aldavidson}

for TYPE in base web worker
do
  REPO_NAME=${REPO_SCOPE}/fb-publisher-${TYPE}
  echo "Building ${REPO_NAME}"
  docker build -f docker/${TYPE}/Dockerfile -t ${REPO_NAME} .
  echo "Pushing ${REPO_NAME} to dockerhub"
  docker push ${REPO_NAME}
done
