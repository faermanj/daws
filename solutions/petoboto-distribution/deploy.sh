#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/..

ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}

aws cloudformation deploy --stack-name acm-simple \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/../acm-simple/template.cform.yaml

aws cloudformation deploy \
    --stack-name petoboto-resources \
    --template-file solutions/petoboto-resources/bucket.cform.yaml
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name petoboto-resources --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)
echo BUCKET_NAME=$BUCKET_NAME
aws s3 cp solutions/petoboto-resources/src/ s3://$BUCKET_NAME/ --acl public-read


aws cloudformation deploy --stack-name vpc-3ha --template-file cloudformation/vpc-3ha/template.cform.yaml
aws cloudformation deploy --stack-name rds-mysql-sls --template-file cloudformation/rds-mysql-sls/template.cform.yaml --parameter-overrides DBPassword=Masterkey123
mvn -f solutions/petoboto-api-fn clean verify
sam deploy --stack-name petoboto-api-fn --template-file solutions/petoboto-api-fn/sam.cform.yaml --capabilities CAPABILITY_IAM --resolve-s3
API_URL=$(aws cloudformation describe-stacks --stack-name petoboto-api-fn --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
echo $API_URL


aws cloudformation deploy \
    --stack-name cloudfront \
    --template-file cloudformation/cloudfront/template.cform.yaml
DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks --stack-name cloudfront --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" --output text)
echo "http://$DISTRIBUTION_DOMAIN/"

aws cloudformation deploy --stack-name petoboto-distribution \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file solutions/petoboto-distribution/alias.cform.yaml

HOST=${ENV_ID}.${DOMAIN_NAME}
echo "http://$HOST/tuna-bigfile.jpg"
echo time curl -s "http://$HOST/tuna-bigfile.jpg" -o /dev/null
echo ab -k -t 333 -c 22 -r "http://$HOST/tuna-bigfile.jpg"

popd
echo "Done.