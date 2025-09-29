#!/bin/bash
set -ex
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
mvn -f crud-api clean package
cp -a ./crud-api/target/quarkus-app dist/
echo "Distribution built in ./dist"