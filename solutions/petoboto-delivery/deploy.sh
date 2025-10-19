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
    --stack-name acm-simple-cd \
    --template-file cloudformation/acm-simple/template.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID

# Main/Blue Bucket
ENV_COLOR="blue"
aws cloudformation deploy \
    --stack-name petoboto-resources-$ENV_COLOR \
    --template-file solutions/petoboto-resources/bucket-color.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID EnvColor=$ENV_COLOR
BUCKET_NAME_MAIN=$(aws cloudformation describe-stacks \
    --stack-name petoboto-resources-$ENV_COLOR \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME_MAIN=$BUCKET_NAME_MAIN
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME_MAIN/
aws s3 cp ./solutions/petoboto-resources/src/css/styles.$ENV_COLOR.css s3://$BUCKET_NAME_MAIN/styles.css
echo "Deployed main resources to $BUCKET_NAME_MAIN"

# Staging/Green Bucket
ENV_COLOR="green"
aws cloudformation deploy \
    --stack-name petoboto-resources-$ENV_COLOR \
    --template-file solutions/petoboto-resources/bucket-color.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID EnvColor=$ENV_COLOR
BUCKET_NAME_STAGING=$(aws cloudformation describe-stacks \
    --stack-name petoboto-resources-$ENV_COLOR \
    --query "Stacks[0].Outputs[?OutputKey=='ResourcesBucketName'].OutputValue" \
    --output text)
echo BUCKET_NAME_STAGING=$BUCKET_NAME_STAGING
aws s3 sync ./solutions/petoboto-resources/src/ s3://$BUCKET_NAME_STAGING/
aws s3 cp ./solutions/petoboto-resources/src/css/styles.$ENV_COLOR.css s3://$BUCKET_NAME_STAGING/styles.css
echo "Deployed staging resources to $BUCKET_NAME_STAGING"

# VPC, Lambda and API
aws cloudformation deploy \
    --stack-name vpc-3ha-cd \
    --template-file cloudformation/vpc-3ha/template.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name rds-mysql-sls-cd \
    --template-file cloudformation/rds-mysql-sls/template.cform.yaml \
    --parameter-overrides DBPassword=$DB_PASSWORD EnvId=$ENV_ID

mvn -f ./solutions/petoboto-api-fn clean verify
sam deploy \
    --stack-name petoboto-api-fn-cd \
    --template-file solutions/petoboto-api-fn/sam.cform.yaml \
    --capabilities CAPABILITY_IAM \
    --resolve-s3 \
    --force-upload \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name petoboto-api-domain-cd \
    --template-file solutions/petoboto-api-fn/domain.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID
API_URL=$(aws cloudformation describe-stacks --stack-name petoboto-api-fn-cd --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
echo $API_URL



# Distribution with CD (main/blue)
aws cloudformation deploy \
    --stack-name petoboto-delivery \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
        EnvColor=$ENV_COLOR \
    --template-file solutions/petoboto-delivery/template.cform.yaml

# Staging Distribution (CD Alias, green)
aws cloudformation deploy \
    --stack-name petoboto-delivery-staging \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
        ResourcesBucketName=$BUCKET_NAME_STAGING \
    --template-file solutions/petoboto-delivery/staging.cform.yaml

DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name petoboto-delivery \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainNameCD'].OutputValue" \
    --output text)
echo "http://$DISTRIBUTION_DOMAIN/"
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name petoboto-delivery \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionIdCD'].OutputValue" \
    --output text)

aws cloudformation deploy \
    --stack-name petoboto-alias-cd \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID \
    --template-file solutions/petoboto-delivery/alias.cform.yaml

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