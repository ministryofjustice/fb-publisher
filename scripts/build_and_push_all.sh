#!/usr/bin/env bash
# exit as soon as any command fails
set -e

REPO_SCOPE=${REPO_SCOPE:-aldavidson}
TAG=${TAG:-latest}
AWS_ACCESS_KEY_ID_BASE=${AWS_ACCESS_KEY_ID_BASE:-${AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY_BASE=${AWS_SECRET_ACCESS_KEY_BASE:-${AWS_SECRET_ACCESS_KEY}}
AWS_ACCESS_KEY_ID_API=${AWS_ACCESS_KEY_ID_API:-${AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY_API=${AWS_SECRET_ACCESS_KEY_API:-${AWS_SECRET_ACCESS_KEY}}
AWS_ACCESS_KEY_ID_WORKER=${AWS_ACCESS_KEY_ID_WORKER:-${AWS_ACCESS_KEY_ID}}
AWS_SECRET_ACCESS_KEY_WORKER=${AWS_SECRET_ACCESS_KEY_WORKER:-${AWS_SECRET_ACCESS_KEY}}

concat_and_uppercase() {
  echo "$1_$2" | tr '[:lower:]' '[:upper:]'
}

login_to_ecr_with_creds_for() {
  KEY_VAR_NAME=$(concat_and_uppercase "AWS_ACCESS_KEY_ID" $1)
  SECRET_VAR_NAME=$(concat_and_uppercase "AWS_SECRET_ACCESS_KEY" $1)
  echo "Logging in with per-repo credentials ${KEY_VAR_NAME} ${SECRET_VAR_NAME}"
  export AWS_ACCESS_KEY_ID=${!KEY_VAR_NAME}
  export AWS_SECRET_ACCESS_KEY=${!SECRET_VAR_NAME}
  eval $(aws ecr get-login --no-include-email --region eu-west-1)
}

for TYPE in base web worker
do
  REPO_NAME=${REPO_SCOPE}/fb-publisher-${TYPE}
  echo "Building ${REPO_NAME}"
  docker build -f docker/${TYPE}/Dockerfile -t ${REPO_NAME}:${TAG} --build-arg BASE_IMAGE=${REPO_SCOPE}/fb-publisher-base:${TAG} .

  login_to_ecr_with_creds_for ${TYPE}
  echo "Pushing ${REPO_NAME}"
  docker push ${REPO_NAME}:${TAG}

done
