#!/bin/bash
set -e 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/s3-janitor.sh

$DIR/cloudformation-janitor.sh

$DIR/ec2-janitor.sh
$DIR/lambda-janitor.sh
# $DIR/cloudfront-janitor.sh

