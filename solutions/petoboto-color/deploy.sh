#!/bin/bash
set -e
DIR=$(cd $(dirname $0) && pwd)

COLOR_A=${1:-"blue"}
COLOR_B=${2:-"green"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
ENV_ID=${ENV_ID:-"project"}
WEIGHT_A=${WEIGHT_A:-50}
WEIGHT_B=${WEIGHT_B:-50}

source $DIR/deploy-foundation.sh
source $DIR/deploy-service.sh "$COLOR_A"
source $DIR/deploy-service.sh "$COLOR_B"

aws cloudformation deploy \
    --stack-name petoboto-apex \
    --parameter-overrides \
        EnvId=$ENV_ID \
        DomainName=$DOMAIN_NAME \
        HostedZoneId=$ZONE_ID \
        ColorA="$COLOR_A" \
        ColorB="$COLOR_B" \
        WeightA=$WEIGHT_A \
        WeightB=$WEIGHT_B \
    --template-file solutions/petoboto-color/apex.cform.yaml
