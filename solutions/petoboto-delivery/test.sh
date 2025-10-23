#!/bin/bash
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..
export AWS_PAGER=""
ENV_ID=${ENV_ID:-"delivery1"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
HOST=${ENV_ID}.${DOMAIN_NAME}

## while true check head of styles css for color applied
while true; do
  URL="https://$HOST/css/styles.css"
  HEAD=$(curl -s $URL | grep background | head -n1)
  echo $HEAD
  sleep 5
done
