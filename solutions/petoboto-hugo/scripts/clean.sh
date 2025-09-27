#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR/.."
echo "Cleaning Hugo site in [$(pwd)]..."
rm -rf public/ resources/_gen/ .hugo_build.lock
echo "Cleaned."
