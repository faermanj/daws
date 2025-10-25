#!/bin/bash
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..
export AWS_PAGER=""
ENV_ID=${ENV_ID:-"delivery"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
HOST=${ENV_ID}.${DOMAIN_NAME}

## while true check head of styles css for color applied
while true; do
  URL="https://$HOST/css/styles.css"
  HEAD=$(curl -s $URL | grep "background: #")
  echo "$(date +%H:%M:%S): $HEAD"
  sleep 1.2345
done
