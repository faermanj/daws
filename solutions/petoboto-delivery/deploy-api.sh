#!/bin/bash

mvn -f ./solutions/petoboto-api-fn clean verify
sam deploy \
    --stack-name ${ENV_ID}-petoboto-api-fn \
    --template-file solutions/petoboto-api-fn/sam.cform.yaml \
    --capabilities CAPABILITY_IAM \
    --resolve-s3 \
    --force-upload \
    --no-confirm-changeset \
    --no-fail-on-empty-changeset \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name ${ENV_ID}-petoboto-api-domain \
    --template-file solutions/petoboto-api-fn/domain.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID
API_URL=$(aws cloudformation describe-stacks --stack-name ${ENV_ID}-petoboto-api-fn --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
echo $API_URL
