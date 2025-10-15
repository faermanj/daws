#!/usr/bin/env bash

set -e

echo -n ""

# For each resource, list and delete until none remain.

# 1) Lambda functions
while true; do
  fns=$(aws lambda list-functions --query 'Functions[].FunctionName' --output text 2>/dev/null)
  if [[ -z "${fns}" ]]; then
    break
  fi
  for fn in ${fns}; do
    aws lambda delete-function --function-name "${fn}"
    echo -e "lambda	function	${fn}"
  done
done

# 2) Lambda layers (delete all versions)
while true; do
  layers=$(aws lambda list-layers --query 'Layers[].LayerName' --output text 2>/dev/null)
  if [[ -z "${layers}" ]]; then
    break
  fi
  for layer in ${layers}; do
    while true; do
      vers=$(aws lambda list-layer-versions --layer-name "${layer}" --query 'LayerVersions[].Version' --output text 2>/dev/null)
      [[ -z "${vers}" ]] && break
      for v in ${vers}; do
        aws lambda delete-layer-version --layer-name "${layer}" --version-number "${v}"
        echo -e "lambda	layer-version	${layer}:${v}"
      done
    done
  done
done

# 3) CloudWatch log groups for Lambda
while true; do
  lgs=$(aws logs describe-log-groups --log-group-name-prefix '/aws/lambda/' --query 'logGroups[].logGroupName' --output text 2>/dev/null)
  if [[ -z "${lgs}" ]]; then
    break
  fi
  for lg in ${lgs}; do
    aws logs delete-log-group --log-group-name "${lg}"
    echo -e "lambda	log-group	${lg}"
  done
done
echo -n ""
