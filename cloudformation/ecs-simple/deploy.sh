#!/bin/bash
set -e
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

ENV_ID=${ENV_ID:-"project"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}

aws cloudformation deploy --stack-name acm-simple \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/../acm-simple/template.cform.yaml

aws cloudformation deploy --stack-name vpc-3ha \
    --template-file $DIR/../vpc-3ha/template.cform.yaml

aws cloudformation deploy --stack-name alb-simple  \
    --template-file $DIR/../alb-simple/template.cform.yaml

aws cloudformation deploy --stack-name alb-simple-alias \
    --parameter-overrides HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
    --template-file $DIR/../alb-simple/alias.cform.yaml

aws cloudformation deploy --stack-name ecs-simple  \
    --capabilities CAPABILITY_NAMED_IAM \
    --template-file $DIR/../ecs-simple/template.cform.yaml

aws cloudformation deploy --stack-name ecs-2048  \
    --template-file $DIR/../ecs-simple/ecs-2048.cform.yaml

fibonacci() {
    # Fast-doubling method: O(log n) using integer arithmetic
    local n=${1:-0}
    if (( n <= 0 )); then echo 0; return; fi
    if (( n == 1 )); then echo 1; return; fi

    local a=0 b=1 bit=1
    # Find highest power of two <= n
    while (( bit <= n )); do
        bit=$(( bit << 1 ))
    done
    bit=$(( bit >> 1 ))

    while (( bit > 0 )); do
        # c = F(2k) = F(k) * (2*F(k+1) - F(k))
        # d = F(2k+1) = F(k)^2 + F(k+1)^2
        local two_b_minus_a=$(( (b << 1) - a ))
        local c=$(( a * two_b_minus_a ))
        local d=$(( a*a + b*b ))
        if (( n & bit )); then
            a=$d
            b=$(( c + d ))
        else
            a=$c
            b=$d
        fi
        bit=$(( bit >> 1 ))
    done
    echo "$a"
}

sleep 42;

URL="https://$ENV_ID.$DOMAIN_NAME"
echo "$URL"
