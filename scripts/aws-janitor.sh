#!/bin/bash
set -e 
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

$DIR/cloudformation-janitor.sh
$DIR/ec2-janitor.sh
$DIR/lambda-janitor.sh
$DIR/s3-janitor.sh

