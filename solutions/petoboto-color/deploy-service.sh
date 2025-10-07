#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

# Settings Variables
ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
DB_PASSWORD=${DB_PASSWORD:-"Masterkey123"}
COLOR=${1:-"flicts"}

echo "Deploying service:"
echo "  ENV_ID=$ENV_ID"
echo "  COLOR=$COLOR"
echo "  DOMAIN_NAME=$DOMAIN_NAME"
echo "  ZONE_ID=$ZONE_ID"


# Resources Bucket
aws cloudformation deploy \
    --stack-name petoboto-resources-$COLOR \
    --template-file solutions/petoboto-resources/bucket-color.cform.yaml \
    --parameter-overrides \
        EnvId=$ENV_ID \
        Color=$COLOR
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name petoboto-resources-$COLOR \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME=$BUCKET_NAME
if [ -n "$COLOR" ]; then
    cp ./solutions/petoboto-resources/src/css/styles.$COLOR.css ./solutions/petoboto-resources/src/css/styles.css
fi
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME/ 

mvn -f ./solutions/petoboto-api-fn clean verify
sam deploy \
    --stack-name petoboto-api-fn-$COLOR \
    --template-file solutions/petoboto-api-fn/sam-color.cform.yaml \
    --capabilities CAPABILITY_IAM \
    --resolve-s3 \
    --force-upload \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset \
    --parameter-overrides \
        EnvId=$ENV_ID \
        Color=$COLOR
aws cloudformation deploy \
    --stack-name petoboto-api-domain-color-$COLOR \
    --template-file solutions/petoboto-api-fn/domain-color.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
        Color=$COLOR
API_URL=$(aws cloudformation describe-stacks --stack-name petoboto-api-fn-$COLOR --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
echo $API_URL


popd
echo "Done."