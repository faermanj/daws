#!/bin/bash 
set -e
DIR=$(cd $(dirname $0) && pwd)
pushd $DIR/../..

export AWS_PAGER=""

ENV_ID=${ENV_ID:-"delivery1"}
DOMAIN_NAME=${DOMAIN_NAME:-"petoboto.com"}
ZONE_ID=${ZONE_ID:-"Z01386901AXGFXHXKIDJX"}
DB_PASSWORD=${DB_PASSWORD:-"Masterkey123"}
HOST=${ENV_ID}.${DOMAIN_NAME}


source $DIR/deploy-storage.sh
source $DIR/deploy-foundation.sh
source $DIR/deploy-api.sh
source $DIR/deploy-cdn.sh

echo "https://$HOST/images/pets/tuna/tuna-1.png"
echo time curl -s "https://$HOST/images/pets/tuna/tuna-1mb.jpg" -o /dev/null
echo ab -k -n 1024 -c 8 -r "https://$HOST/images/pets/tuna/tuna-1mb.jpg"

popd
echo "Done."
