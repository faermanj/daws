#!/bin/bash 

ENV_ID=${ENV_ID:-"delivery"}
STAGING_WEIGHT=${STAGING_WEIGHT:-"0.13"}

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

# Use UpdateDistribution to modify the staging distribution's configuration.
POLICY_ID=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery-staging \
    --query "Stacks[0].Outputs[?OutputKey=='ContinuousDeploymentPolicyId'].OutputValue" \
    --output text)

echo "Setting delivery policy ID: $POLICY_ID"
aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-delivery \
    --parameter-overrides \
        ContinuousDeploymentPolicyId=$POLICY_ID \
    --template-file solutions/petoboto-delivery/template.cform.yaml




