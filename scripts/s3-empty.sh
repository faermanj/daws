#!/usr/bin/env bash
set -ex

# Function to empty a bucket
empty_bucket() {
    local bucket="$1"
    echo "Emptying bucket: $bucket"
    aws s3 rm "s3://$bucket" --recursive
}

# Function to process all buckets
janitor_s3() {
    buckets=$(aws s3api list-buckets --query "Buckets[].Name" --output text)
    for bucket in $buckets; do
        empty_bucket "$bucket"
    done
}

# Main
janitor_s3