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

aws cloudformation deploy --stack-name alb  \
    --template-file $DIR/../alb/template.cform.yaml

aws cloudformation deploy --stack-name alb-alias \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/../alb/alias.cform.yaml

echo "alb deploy done"
