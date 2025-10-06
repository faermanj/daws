#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}

aws cloudformation deploy \
    --stack-name petoboto-healthcheck \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
    --template-file solutions/petoboto-extra/healthcheck.cform.yaml

