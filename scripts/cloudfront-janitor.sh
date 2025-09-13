#!/usr/bin/env bash

set -euo pipefail

if [ $# -ne 1 ]; then
    exit 1
fi

DOMAIN="$1"

# Find the CloudFront distribution ID by domain name
DIST_ID=$(aws cloudfront list-distributions \
    --query "DistributionList.Items[?Aliases.Items[?@=='$DOMAIN']].Id" \
    --output text)

if [ -z "$DIST_ID" ]; then
    exit 0
fi

# Get the current ETag for the distribution
ETAG=$(aws cloudfront get-distribution --id "$DIST_ID" --query "ETag" --output text)

# Disable the distribution
aws cloudfront update-distribution \
    --id "$DIST_ID" \
    --if-match "$ETAG" \
    --distribution-config "$(aws cloudfront get-distribution-config --id "$DIST_ID" | \
        jq '.DistributionConfig | .Enabled = false')" > /dev/null

# Wait for the distribution to be disabled
while true; do
    STATUS=$(aws cloudfront get-distribution --id "$DIST_ID" --query "Distribution.Status" --output text)
    ENABLED=$(aws cloudfront get-distribution --id "$DIST_ID" --query "Distribution.DistributionConfig.Enabled" --output text)
    if [[ "$STATUS" == "Deployed" && "$ENABLED" == "False" ]]; then
        break
    fi
    sleep 30
done

# Get the latest ETag after disablement
ETAG=$(aws cloudfront get-distribution --id "$DIST_ID" --query "ETag" --output text)

# Delete the distribution
aws cloudfront delete-distribution --id "$DIST_ID" --if-match "$ETAG"
echo -e "cloudfront	distribution	${DIST_ID}"
