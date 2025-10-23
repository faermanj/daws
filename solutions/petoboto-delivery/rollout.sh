#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

ENV_ID=${ENV_ID:-"delivery1"}

aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-delivery-staging \
    --parameter-overrides StagingWeight=0.10 \
    --template-file solutions/petoboto-delivery/staging.cform.yaml
