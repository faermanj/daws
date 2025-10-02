#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR/../../..
BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name s3-distribution --query "Stacks[0].Outputs[?OutputKey=='BucketName'].OutputValue" --output text)
echo "Deploying to bucket: $BUCKET_NAME"
aws s3 sync $DIR/solutions/petoboto-resources/src/ s3://$BUCKET_NAME --delete
