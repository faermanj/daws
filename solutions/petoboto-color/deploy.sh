#!/bin/bash
set -e
DIR=$(cd $(dirname $0) && pwd)

COLOR_A=${1:-"blue"}
COLOR_B=${2:-"green"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
ENV_ID=${ENV_ID:-"project"}
WEIGHT_A=${WEIGHT_A:-80}
WEIGHT_B=${WEIGHT_B:-20}

source $DIR/deploy-foundation.sh
source $DIR/deploy-service.sh "$COLOR_A"
source $DIR/deploy-service.sh "$COLOR_B"

aws cloudformation deploy \
    --stack-name petoboto-weights \
    --template-file solutions/petoboto-color/color-weights.cform.yaml \
    --parameter-overrides \
        EnvId="$ENV_ID" \
        DomainName="$DOMAIN_NAME" \
        HostedZoneId="$ZONE_ID" \
        ColorA="$COLOR_A" \
        ColorB="$COLOR_B" \
        WeightA="$WEIGHT_A" \
        WeightB="$WEIGHT_B"

# Distribution and Alias
aws cloudformation deploy \
    --stack-name petoboto-distribution \
    --template-file solutions/petoboto-color/template.cform.yaml \
    --parameter-overrides \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID
DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" \
    --output text)
echo "http://$DISTRIBUTION_DOMAIN/"
DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name petoboto-distribution \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
    --output text)
aws cloudformation deploy \
    --stack-name petoboto-alias \
    --template-file solutions/petoboto-color/alias.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID

aws cloudformation deploy \
    --stack-name petoboto-healthcheck \
    --template-file solutions/petoboto-color/healthcheck.cform.yaml \
    --parameter-overrides \
        EnvId=$ENV_ID \
        Color=$COLOR \
        DomainName=$DOMAIN_NAME

aws cloudfront create-invalidation \
    --distribution-id $DISTRIBUTION_ID \
    --paths "/*"

# Suggested Tests
HOST=${ENV_ID}-${COLOR}.${DOMAIN_NAME}
echo "http://$HOST/tuna-1mb.jpg"
echo time curl -s "http://$HOST/tuna-1mb.jpg" -o /dev/null
echo ab -k -n 2048 -c 16 -r "http://$HOST/tuna-1mb.jpg"
