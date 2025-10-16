#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

ENV_ID=${ENV_ID:-"delivery"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
DB_PASSWORD=${DB_PASSWORD:-"Masterkey123"}
GITHUB_REPO=${GITHUB_REPO:-"faermanj/daws"}

# TLS Certificate
aws cloudformation deploy \
    --stack-name acm-simple \
    --template-file cloudformation/acm-simple/template.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID

# Resources Bucket
aws cloudformation deploy \
    --stack-name petoboto-resources \
    --template-file solutions/petoboto-resources/bucket.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name petoboto-resources \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME=$BUCKET_NAME
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME/ 

# VPC, Lambda and API
aws cloudformation deploy \
    --stack-name vpc-3ha \
    --template-file cloudformation/vpc-3ha/template.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name rds-mysql-sls \
    --template-file cloudformation/rds-mysql-sls/template.cform.yaml \
    --parameter-overrides DBPassword=$DB_PASSWORD EnvId=$ENV_ID

mvn -f ./solutions/petoboto-api-fn clean verify
sam deploy \
    --stack-name petoboto-api-fn \
    --template-file solutions/petoboto-api-fn/sam.cform.yaml \
    --capabilities CAPABILITY_IAM \
    --resolve-s3 \
    --force-upload \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name petoboto-api-domain \
    --template-file solutions/petoboto-api-fn/domain.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID
API_URL=$(aws cloudformation describe-stacks --stack-name petoboto-api-fn --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
echo $API_URL

# Distribution with CD
aws cloudformation deploy \
    --stack-name petoboto-distribution-cd \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
    --template-file solutions/petoboto-distribution-cd/template.cform.yaml

# CD Pipeline
aws cloudformation deploy \
    --stack-name petoboto-distribution-cd-pipeline \
    --template-file solutions/petoboto-distribution-cd/cd.cform.yaml \
    --parameter-overrides \
        EnvId=$ENV_ID \
        GitHubRepo=$GITHUB_REPO \
    --capabilities CAPABILITY_IAM

DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution-cd \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainNameCD'].OutputValue" \
    --output text)
echo "http://$DISTRIBUTION_DOMAIN/"
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution-cd \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionIdCD'].OutputValue" \
    --output text)
GITHUB_CONNECTION=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution-cd-pipeline \
    --query "Stacks[0].Outputs[?OutputKey=='GitHubConnectionArn'].OutputValue" \
    --output text)

aws cloudformation deploy \
    --stack-name petoboto-alias \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
    --template-file solutions/petoboto-distribution-cd/alias.cform.yaml

aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*"

# Output connection info
echo ""
echo "IMPORTANT: Activate GitHub connection manually:"
echo "Connection ARN: $GITHUB_CONNECTION"
echo "1. Go to CodePipeline > Settings > Connections"
echo "2. Find the connection and click 'Update pending connection'"
echo "3. Authorize with GitHub"
echo ""

# Suggested Tests
HOST=${ENV_ID}-cd.${DOMAIN_NAME}
echo "http://$HOST/tuna-1mb.jpg"
echo time curl -s "http://$HOST/tuna-1mb.jpg" -o /dev/null
echo ab -k -n 655350 -c 128 -r "http://$HOST/tuna-1mb.jpg"

popd
echo "Done."