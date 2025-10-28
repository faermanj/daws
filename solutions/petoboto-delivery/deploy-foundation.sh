#!/bin/bash

# VPC, Lambda and API
aws cloudformation deploy \
    --stack-name ${ENV_ID}-vpc-3nat \
    --template-file cloudformation/vpc-3nat/template.cform.yaml \
    --parameter-overrides EnvId=$ENV_ID
aws cloudformation deploy \
    --stack-name ${ENV_ID}-rds-mysql-sls \
    --template-file cloudformation/rds-mysql-sls/template.cform.yaml \
    --parameter-overrides DBPassword=$DB_PASSWORD EnvId=$ENV_ID

# TLS Certificate
aws cloudformation deploy \
    --stack-name ${ENV_ID}-acm-simple \
    --template-file cloudformation/acm-simple/template.cform.yaml \
    --parameter-overrides \
        HostedZoneId=$ZONE_ID \
        DomainName=$DOMAIN_NAME \
        EnvId=$ENV_ID
