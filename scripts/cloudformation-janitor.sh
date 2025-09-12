#!/bin/bash

# cloudformation-janitor.sh
# Loops until all CloudFormation stacks are deleted in the current AWS account/region.

set -euo pipefail

echo "Starting CloudFormation janitor..."

while true; do
    stacks=$(aws cloudformation list-stacks --stack-status-filter CREATE_IN_PROGRESS CREATE_FAILED CREATE_COMPLETE ROLLBACK_IN_PROGRESS ROLLBACK_FAILED ROLLBACK_COMPLETE DELETE_FAILED UPDATE_IN_PROGRESS UPDATE_COMPLETE UPDATE_ROLLBACK_IN_PROGRESS UPDATE_ROLLBACK_FAILED UPDATE_ROLLBACK_COMPLETE REVIEW_IN_PROGRESS DELETE_IN_PROGRESS --query "StackSummaries[].StackName" --output text)
    if [[ -z "$stacks" ]]; then
        echo "All CloudFormation stacks are deleted."
        break
    fi

    echo "Stacks to delete: $stacks"
    for stack in $stacks; do
        echo "Deleting stack[$stack]"
        aws cloudformation delete-stack --stack-name "$stack"

        echo "Waiting delete completion for stack[$stack]"
        aws cloudformation wait stack-delete-complete --stack-name "$stack"
    done

done
