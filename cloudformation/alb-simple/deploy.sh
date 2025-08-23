#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}

aws cloudformation deploy --stack-name acm-simple \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/cloudformation/acm-simple/template.cform.yaml

aws cloudformation deploy --stack-name vpc-3ha \
    --template-file $DIR/cloudformation/vpc-3ha/vpc.cform.yaml

aws cloudformation deploy --stack-name alb-simple  \
    --template-file $DIR/cloudformation/alb-simple/template.cform.yaml

aws cloudformation deploy --stack-name alb-simple-alias \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/cloudformation/alb-simple/alias.cform.yaml

aws cloudformation deploy --stack-name alb-simple-instances  \
    --template-file $DIR/cloudformation/alb-simple/instances.cform.yaml

sleep 30;

URL="https://$ENV_ID.$DOMAIN_NAME"
echo "$URL"

for i in {1..10}; do 
    echo -n "$i: "; 
    curl -k "$URL"; 
done