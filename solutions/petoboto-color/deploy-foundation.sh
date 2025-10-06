#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
DB_PASSWORD=${DB_PASSWORD:-"Masterkey123"}
# PAINT IT BLACK ;)

echo "Deploying foundation:"
echo "  ENV_ID=$ENV_ID"
echo "  DOMAIN_NAME=$DOMAIN_NAME"
echo "  ZONE_ID=$ZONE_ID"

# TLS Certificate
aws cloudformation deploy \
    --stack-name acm-simple \
    --template-file cloudformation/acm-simple/template.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID

# VPC, Lambda and API
aws cloudformation deploy \
    --stack-name vpc-3ha \
    --template-file cloudformation/vpc-3ha/template.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name rds-mysql-sls \
    --template-file cloudformation/rds-mysql-sls/template.cform.yaml \
    --parameter-overrides DBPassword=$DB_PASSWORD EnvId=$ENV_ID

popd
echo "Done."