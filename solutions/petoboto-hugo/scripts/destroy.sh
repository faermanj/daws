#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
set -ex

STACK_NAME="${STACK_NAME:-petoboto-hugo}"
BUCKET_NAME="$(aws cloudformation describe-stacks \
        --stack-name "$STACK_NAME" \
        --query "Stacks[0].Outputs[?contains(@.OutputKey, 'BucketName')].[OutputValue]" \
        --output text)"
echo "Emptying bucket $BUCKET_NAME ..."
aws s3 rm "s3://$BUCKET_NAME" --recursive


aws cloudformation delete-stack --stack-name "$STACK_NAME"
echo "Waiting for stack $STACK_NAME to be deleted..."
aws cloudformation wait stack-delete-complete --stack-name "$STACK_NAME"
echo "Stack $STACK_NAME deleted."
echo "Done."
