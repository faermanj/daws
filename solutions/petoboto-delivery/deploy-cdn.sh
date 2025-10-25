#!/bin/bash

# Delivery Distribution (blue)
aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-delivery \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
        EnvColor="blue" \
        ResourcesBucketName=$BUCKET_NAME_MAIN \
    --template-file solutions/petoboto-delivery/template.cform.yaml

# Staging Distribution (green)
aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-delivery-staging \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
        EnvColor="green" \
        ResourcesBucketName=$BUCKET_NAME_STAGING \
    --template-file solutions/petoboto-delivery/staging.cform.yaml

DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" \
    --output text)
echo "http://$DISTRIBUTION_DOMAIN/"
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
    --output text)

aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-alias \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
    --template-file solutions/petoboto-delivery/alias.cform.yaml

aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*"
