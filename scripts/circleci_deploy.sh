#!/usr/bin/env sh

set -e -u -o pipefail

# example usage
# ./scripts/circleci_deploy.sh test KUBE_TOKEN_TEST
# ./scripts/circleci_deploy.sh integration KUBE_TOKEN_INTEGRATION

environment_name=$1
kube_token=$2

echo "kubectl configure credentials"
kubectl config set-credentials "circleci_${environment_name}" --token="${kube_token}"

echo "kubectl configure context"
kubectl config set-context "circleci_${environment_name}" --cluster="$KUBE_CLUSTER" --user="circleci_${environment_name}" --namespace="formbuilder-publisher-${environment_name}"

echo "kubectl use circleci context"
kubectl config use-context "circleci_${environment_name}"

echo "apply kubernetes changes to ${environment_name}"
./scripts/deploy_platform.sh -p $environment_name -s $CIRCLE_SHA1
