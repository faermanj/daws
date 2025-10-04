#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
DB_PASSWORD=${DB_PASSWORD:-"Masterkey123"}

# TLS Certificate
aws cloudformation deploy \
    --stack-name acm-simple \
    --template-file cloudformation/acm-simple/template.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \

# Resources Bucket
aws cloudformation deploy \
    --stack-name petoboto-resources \
    --template-file solutions/petoboto-resources/bucket.cform.yaml
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name petoboto-resources \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME=$BUCKET_NAME
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME/ 

# VPC, Lambda and API
aws cloudformation deploy \
    --stack-name vpc-3ha \
    --template-file cloudformation/vpc-3ha/template.cform.yaml
aws cloudformation deploy \
    --stack-name rds-mysql-sls \
    --template-file cloudformation/rds-mysql-sls/template.cform.yaml \
    --parameter-overrides DBPassword=$DB_PASSWORD

mvn -f ./solutions/petoboto-api-fn clean verify
sam deploy \
    --stack-name petoboto-api-fn \
    --template-file solutions/petoboto-api-fn/sam.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --capabilities CAPABILITY_IAM \
    --resolve-s3
API_URL=$(aws cloudformation describe-stacks --stack-name petoboto-api-fn --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
echo $API_URL

# Distribution and Alias
aws cloudformation deploy \
    --stack-name petoboto-distribution \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
    --template-file solutions/petoboto-distribution/template.cform.yaml
DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" \
    --output text)
echo "http://$DISTRIBUTION_DOMAIN/"
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
    --output text)
aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*"

aws cloudformation deploy \
    --stack-name petoboto-alias \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file solutions/petoboto-distribution/alias.cform.yaml

# Suggested Tests
HOST=${ENV_ID}.${DOMAIN_NAME}
echo "http://$HOST/tuna-1mb.jpg"
echo time curl -s "http://$HOST/tuna-1mb.jpg" -o /dev/null
echo ab -k -n 655350 -c 128 -r "http://$HOST/tuna-1mb.jpg"

popd
echo "Done."