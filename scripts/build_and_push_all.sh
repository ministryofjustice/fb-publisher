#!/usr/bin/env sh
# exit as soon as any command fails
set -e

REPO_SCOPE=${REPO_SCOPE:-aldavidson}
TAG=${TAG:-latest}

login_to_ecr_with_creds_for() {
  AWS_ACCESS_KEY_ID_ENCODED=`kubectl -n formbuilder-repos get secrets ecr-repo-fb-publisher-$TYPE -o jsonpath='{.data.access_key_id}'`
  AWS_SECRET_ACCESS_KEY_ENCODED=`kubectl -n formbuilder-repos get secrets ecr-repo-fb-publisher-$TYPE -o jsonpath='{.data.secret_access_key}'`

  if [ `uname` == 'Darwin' ]
  then
    export AWS_ACCESS_KEY_ID=`echo $AWS_ACCESS_KEY_ID_ENCODED | base64 --decode`
    export AWS_SECRET_ACCESS_KEY=`echo $AWS_SECRET_ACCESS_KEY_ENCODED | base64 --decode`
  else
    export AWS_ACCESS_KEY_ID=`echo $AWS_ACCESS_KEY_ID_ENCODED | base64 -d`
    export AWS_SECRET_ACCESS_KEY=`echo $AWS_SECRET_ACCESS_KEY_ENCODED | base64 -d`
  fi

  eval $(aws ecr get-login --no-include-email --region eu-west-2)
}

for TYPE in web worker
do
  REPO_NAME=${REPO_SCOPE}/fb-publisher-${TYPE}
  echo "Building ${REPO_NAME}"
  docker build -f docker/${TYPE}/Dockerfile -t ${REPO_NAME}:${TAG} -t ${REPO_NAME}:${CIRCLE_SHA1} --build-arg BASE_IMAGE=${REPO_SCOPE}/fb-publisher-base:${TAG} --build-arg BUNDLE_FLAGS="--without test development" .

  login_to_ecr_with_creds_for ${TYPE}
  echo "Pushing ${REPO_NAME}"
  docker push ${REPO_NAME}:${TAG}
  docker push ${REPO_NAME}:${CIRCLE_SHA1}
done
