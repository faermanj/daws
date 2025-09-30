#!/bin/bash
set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/..

REPO_NAME="crud-api" 
IMAGE_TAG="0.0.1"
LOCAL_IMAGE="${REPO_NAME}:${IMAGE_TAG}"

if ! aws ecr-public describe-repositories --repository-names "${REPO_NAME}" >/dev/null 2>&1; then
  aws ecr-public create-repository --repository-name "${REPO_NAME}"
fi

REGISTRY_URI=$(aws ecr-public describe-registries --query 'registries[0].registryUri' --output text)
echo REGISTRY_URI=$REGISTRY_URI
aws ecr-public get-login-password | docker login --username AWS --password-stdin "${REGISTRY_URI}"
docker build -f Containerfile --no-cache --progress=plain -t $LOCAL_IMAGE .
docker tag "${LOCAL_IMAGE}" "${REGISTRY_URI}/${REPO_NAME}:${IMAGE_TAG}"
docker push "${REGISTRY_URI}/${REPO_NAME}:${IMAGE_TAG}"
ALIAS=$(aws ecr-public describe-registries --query 'registries[0].registryUri' --output text | sed 's#public\.ecr\.aws/##')
echo "https://gallery.ecr.aws/${ALIAS}/${REPO_NAME}"
