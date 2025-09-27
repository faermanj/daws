#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
echo "Starting Hugo site in [$(pwd)]..."
hugo server -D 
