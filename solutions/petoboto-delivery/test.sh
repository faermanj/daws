#!/bin/bash
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..
export AWS_PAGER=""
ENV_ID=${ENV_ID:-"delivery"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
DEFAULT_HOST=${ENV_ID}.${DOMAIN_NAME}
HOST=${HOST:-$DEFAULT_HOST}
COUNT=0
GREEN=0
GREEN_RATIO=0

while true; do
  URL="https://$HOST/css/styles.css"
  HEAD=$(curl -s $URL | grep "ENV_COLOR")
  COUNT=$((COUNT + 1))
  IS_GREEN=$(echo $HEAD | grep "ENV_COLOR=green" || true)
  GREEN_RATIO=$(awk "BEGIN {printf \"%.2f\", $GREEN/$COUNT}")
  if [ -n "$IS_GREEN" ]; then
    GREEN=$((GREEN + 1))
  fi
  echo "$(date +%H:%M:%S) [$URL] [$COUNT/$GREEN/$GREEN_RATIO]: $HEAD"
  sleep 0.333
done
