#!/bin/bash
set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

cd $DIR/../../..

DBPassword=${DBPassword:-"Masterkey123"}

pwd

mvn -f solutions/crud-quarkus/ clean verify

aws cloudformation deploy \
    --stack-name vpc-3ha \
    --template-file cloudformation/vpc-3ha/template.cform.yaml

aws cloudformation deploy \
    --stack-name rds-mysql-sls \
    --template-file cloudformation/rds-mysql-sls/template.cform.yaml \
    --parameter-overrides "DBPassword=$DBPassword" 

sam deploy \
    --resolve-s3 \
    --template-file solutions/crud-quarkus/crud-api-fn/sam.cform.yaml \
    --stack-name crud-api-fn \
    --capabilities CAPABILITY_IAM

echo "Done" 