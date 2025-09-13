#!/usr/bin/env bash

set -euo pipefail

if [[ $# -ne 1 ]]; then
    exit 1
fi

DOMAIN_NAME="$1"

# Find the hosted zone ID
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN_NAME" --query "HostedZones[?Name == '$DOMAIN_NAME.'].Id" --output text | sed 's|/hostedzone/||')

if [[ -z "$HOSTED_ZONE_ID" ]]; then
    exit 0
fi

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
    # Print each record to be deleted
    echo "$CHANGE_BATCH" | jq -r '.Changes[].ResourceRecordSet | "route53\trecord-set\t\(.Name) \(.Type)"'
    aws route53 change-resource-record-sets --hosted-zone-id "$HOSTED_ZONE_ID" --change-batch "$CHANGE_BATCH"
fi

rm "$TMPFILE"

# Delete the hosted zone
aws route53 delete-hosted-zone --id "$HOSTED_ZONE_ID"
echo -e "route53	hosted-zone	${HOSTED_ZONE_ID}"
