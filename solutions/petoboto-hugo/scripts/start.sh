#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
echo "Starting Hugo site in [$(pwd)]..."
git submodule update --init --recursive
hugo server -D 
