#!/bin/bash 
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
pushd $DIR/../..

ENV_ID=${ENV_ID:-"delivery"}
export AWS_PAGER=""

DELIVERY_DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
    --output text)
STAGING_DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery-staging \
    --query "Stacks[0].Outputs[?OutputKey=='StagingDistributionId'].OutputValue" \
    --output text)

PRIMARY_ETAG=$(aws cloudfront get-distribution \
    --id "$DELIVERY_DISTRIBUTION_ID" \
    --query 'ETag' \
    --output text | tr -d '"')
STAGING_ETAG=$(aws cloudfront get-distribution \
    --id "$STAGING_DISTRIBUTION_ID" \
    --query 'ETag' \
    --output text | tr -d '"')

IF_MATCH="$PRIMARY_ETAG,$STAGING_ETAG"

echo "Promoting staging distribution ($STAGING_DISTRIBUTION_ID) to delivery distribution ($DELIVERY_DISTRIBUTION_ID)"
echo "Using If-Match: $IF_MATCH"

aws cloudfront update-distribution-with-staging-config \
    --id "$DELIVERY_DISTRIBUTION_ID" \
    --staging-distribution-id "$STAGING_DISTRIBUTION_ID" \
    --if-match "$IF_MATCH"

echo "Promotion complete: staging config is now live on delivery distribution."

popd
echo "Done."