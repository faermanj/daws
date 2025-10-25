#!/bin/bash 
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
pushd $DIR/../..

ENV_ID=${ENV_ID:-"delivery"}

DELIVERY_DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
    --output text)
STAGING_DISTRIBUTION_ID=$(aws cloudformation describe-stacks \
    --stack-name ${ENV_ID}-petoboto-delivery-staging \
    --query "Stacks[0].Outputs[?OutputKey=='DistributionId'].OutputValue" \
    --output text)
echo "Promoting staging distribution ($STAGING_DISTRIBUTION_ID) to delivery distribution ($DELIVERY_DISTRIBUTION_ID)"

aws cloudfront update-distribution-with-staging-config \
    --id "$DELIVERY_DISTRIBUTION_ID" \
    --staging-distribution-id "$STAGING_DISTRIBUTION_ID"

echo "Promotion complete: staging config is now live on delivery distribution."

popd
echo "Done."