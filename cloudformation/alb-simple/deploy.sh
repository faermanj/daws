#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}

aws cloudformation deploy --stack-name acm-simple \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/../acm-simple/template.cform.yaml

aws cloudformation deploy --stack-name vpc-3ha \
    --template-file $DIR/../vpc-3ha/template.cform.yaml

aws cloudformation deploy --stack-name alb-simple  \
    --template-file $DIR/../alb-simple/template.cform.yaml

aws cloudformation deploy --stack-name alb-simple-alias \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/../alb-simple/alias.cform.yaml

aws cloudformation deploy --stack-name alb-simple-instances  \
    --template-file $DIR/../alb-simple/instances.cform.yaml

sleep 42;

URL="https://$ENV_ID.$DOMAIN_NAME"
echo "curl $URL"
curl $URL
curl $URL
