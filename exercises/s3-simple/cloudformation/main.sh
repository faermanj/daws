#!/bin/bash
set -e

# Script to create S3 bucket using CloudFormation and upload image

# Configuration
STACK_NAME="s3-simple"
TEMPLATE_FILE="main.cfn.yaml"
IMAGE_FILE="guiri_vanlife.jpg"

aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" 

if [ $? -eq 0 ]; then
    echo "CloudFormation stack deployed successfully!"
else
    echo "Failed to deploy CloudFormation stack."
    exit 1
fi

# Get the bucket name from stack outputs
echo "Retrieving bucket name from stack outputs..."
BUCKET_NAME=$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue' \
    --output text)

if [ -z "$BUCKET_NAME" ]; then
    echo "Failed to retrieve bucket name from stack outputs."
    exit 1
fi

echo "Bucket name: $BUCKET_NAME"

# Upload image to S3 bucket
echo "Uploading image '$IMAGE_FILE' to S3 bucket '$BUCKET_NAME'..."
aws s3 cp "$IMAGE_FILE" "s3://$BUCKET_NAME/"

if [ $? -eq 0 ]; then
    echo "Image uploaded successfully!"
    echo "Image URL: https://$BUCKET_NAME.s3.amazonaws.com/$IMAGE_FILE"
else
    echo "Failed to upload image to S3 bucket."
    exit 1
fi
