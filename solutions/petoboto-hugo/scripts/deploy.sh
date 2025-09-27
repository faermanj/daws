#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
set -ex

STACK_NAME="${STACK_NAME:-petoboto-hugo}"
TEMPLATE_FILE="${TEMPLATE_FILE:-template.cform.yaml}"
BUILD_DIR="${BUILD_DIR:-public}"

if ! command -v hugo >/dev/null 2>&1; then
    echo "hugo not found on PATH" >&2
    exit 1
fi

if [ ! -f "$TEMPLATE_FILE" ]; then
    echo "Template $TEMPLATE_FILE not found" >&2
    exit 1
fi

echo "Building site..."
hugo --minify

echo "Deploying CloudFormation stack $STACK_NAME..."
aws cloudformation deploy \
    --template-file "$TEMPLATE_FILE" \
    --stack-name "$STACK_NAME" 

echo "Resolving bucket..."
BUCKET_NAME="$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query "Stacks[0].Outputs[?contains(@.OutputKey, 'BucketName')].[OutputValue]" \
        --output text)"

if [ -z "$BUCKET_NAME" ]; then
    echo "Could not determine S3 bucket (set S3_BUCKET env var or ensure stack outputs a Bucket output)" >&2
    exit 1
fi

echo "Syncing site to s3://$BUCKET_NAME/ ..."
aws s3 sync "$BUILD_DIR"/ "s3://$BUCKET_NAME/" --delete


SITE_URL="$(aws cloudformation describe-stacks \
    --stack-name "$STACK_NAME" \
    --query "Stacks[0].Outputs[?OutputKey=='WebsiteURL'].OutputValue" \
    --output text  )"
echo "Site URL: $SITE_URL"
echo "Deployment complete."
