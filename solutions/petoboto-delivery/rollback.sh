#!/bin/bash 

ENV_ID=${ENV_ID:-"delivery"}
STAGING_WEIGHT=${STAGING_WEIGHT:-"0.00"}

echo "Updating staging distribution with weight $STAGING_WEIGHT"
aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-delivery-staging \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
        EnvColor="green" \
        ResourcesBucketName=$BUCKET_NAME_STAGING \
        StagingWeight=$STAGING_WEIGHT \
    --template-file solutions/petoboto-delivery/staging.cform.yaml

