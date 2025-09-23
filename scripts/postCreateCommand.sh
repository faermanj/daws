#!/bin/bash
echo "Running post-create commands as [$(whoami)]..."
sudo apt update
sudo apt install hugo -y
echo "Done."