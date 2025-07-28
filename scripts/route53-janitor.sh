#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <domain-name>"
    exit 1
fi

DOMAIN_NAME="$1"

# Find the hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN_NAME" --query "HostedZones[?Name == '$DOMAIN_NAME.'].Id" --output text | sed 's|/hostedzone/||')

if [[ -z "$HOSTED_ZONE_ID" ]]; then
    echo "Hosted zone for $DOMAIN_NAME not found."
    exit 1
fi

echo "Found hosted zone ID: $HOSTED_ZONE_ID"

# Get all record sets except SOA and NS at the root
TMPFILE=$(mktemp)
aws route53 list-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" > "$TMPFILE"

CHANGE_BATCH=$(jq '
    .ResourceRecordSets
    | map(select(.Type != "SOA" and .Type != "NS" or .Name != "'$DOMAIN_NAME.'"))
    | map({
            Action: "DELETE",
            ResourceRecordSet: .
        })
    | {Changes: .}
' "$TMPFILE")

NUM_CHANGES=$(echo "$CHANGE_BATCH" | jq '.Changes | length')

if [[ "$NUM_CHANGES" -gt 0 ]]; then
    echo "Deleting $NUM_CHANGES record sets..."
    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch "$CHANGE_BATCH"
else
    echo "No record sets to delete."
fi

rm "$TMPFILE"

# Delete the hosted zone
echo "Deleting hosted zone $HOSTED_ZONE_ID..."
aws route53 delete-hosted-zone --id "$HOSTED_ZONE_ID"

echo "Done."