#!/bin/bash 
#TODO

# aws cloudformation deploy --stack-name s3-distribution --template-file solutions/petoboto-resources/bucket.cform.yaml
# aws s3 cp solutions/petoboto-resources/src/ s3://$BUCKET_NAME/ --acl public-read


# aws cloudformation deploy --stack-name vpc-3ha --template-file cloudformation/vpc-3ha/template.cform.yaml
# aws cloudformation deploy --stack-name rds-mysql-sls --template-file cloudformation/rds-mysql-sls/template.cform.yaml --parameter-overrides DBPassword=Masterkey123
# mvn -f solutions/petoboto-api-fn clean verify
# sam deploy --stack-name petoboto-api-fn --template-file solutions/petoboto-api-fn/sam.cform.yaml --capabilities CAPABILITY_IAM --resolve-s3
# API_URL=$(aws cloudformation describe-stacks --stack-name petoboto-api-fn --query "Stacks[0].Outputs[?OutputKey=='PetobotoApiUrl'].OutputValue" --output text)
# echo $API_URL
# curl -s "$API_URL/api/pets/" 

# aws cloudformation deploy --stack-name cloudfront --template-file cloudformation/cloudfront/template.cform.yaml
# DISTRIBUTION_DOMAIN=$(aws cloudformation describe-stacks --stack-name cloudfront --query "Stacks[0].Outputs[?OutputKey=='DistributionDomainName'].OutputValue" --output text)
# echo "http://$DISTRIBUTION_DOMAIN/"
# echo "http://$DISTRIBUTION_DOMAIN/tuna-bigfile.jpg"
# time curl -s "http://$DISTRIBUTION_DOMAIN/tuna-bigfile.jpg" -o /dev/null
# ab -k -t 333 -c 22 -r "http://$DISTRIBUTION_DOMAIN/tuna-bigfile.jpg"
