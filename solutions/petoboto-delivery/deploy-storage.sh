#!/bin/bash

# Main/Blue Bucket
ENV_COLOR="blue"
aws cloudformation deploy \
    --stack-name ${ENV_ID}-$ENV_COLOR-petoboto-resources \
    --template-file solutions/petoboto-resources/bucket-color.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID EnvColor=$ENV_COLOR
BUCKET_NAME_MAIN=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-$ENV_COLOR-petoboto-resources \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME_MAIN=$BUCKET_NAME_MAIN
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME_MAIN/
echo "Applying color [$ENV_COLOR]"
aws s3 cp ./solutions/petoboto-resources/src/css/styles.$ENV_COLOR.css s3://$BUCKET_NAME_MAIN/css/styles.css
echo "Deployed main resources [$ENV_COLOR] to $BUCKET_NAME_MAIN"

# Staging/Green Bucket
ENV_COLOR="green"
aws cloudformation deploy \
    --stack-name ${ENV_ID}-$ENV_COLOR-petoboto-resources \
    --template-file solutions/petoboto-resources/bucket-color.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID EnvColor=$ENV_COLOR
BUCKET_NAME_STAGING=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-$ENV_COLOR-petoboto-resources \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME_STAGING=$BUCKET_NAME_STAGING
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME_STAGING/
echo "Applying color [$ENV_COLOR]"
aws s3 cp ./solutions/petoboto-resources/src/css/styles.$ENV_COLOR.css s3://$BUCKET_NAME_STAGING/css/styles.css
echo "Deployed staging resources [$ENV_COLOR] to $BUCKET_NAME_STAGING"
