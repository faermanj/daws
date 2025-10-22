#!/bin/bash
echo "Running postCreateCommand as [$(whoami)]..."

# Install Hugo (latest version) if not installed
if ! command -v hugo &> /dev/null
then
    echo "Hugo not found, proceeding with installation..."
    HUGO_URL=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep "browser_download_url.*hugo_extended.*Linux-64bit.tar.gz" | head -1 | cut -d '"' -f 4)
    cd /tmp
    curl -L -o hugo.tar.gz "$HUGO_URL"
    tar -xzf hugo.tar.gz
    sudo mv hugo /usr/local/bin/
    rm -f hugo.tar.gz LICENSE README.md
    echo "Hugo installed successfully!"
fi
hugo version

# Install mysql client if not installed 
if ! command -v mysql &> /dev/null
then
    echo "MySQL client not found, proceeding with installation..."
    sudo apt-get update
    sudo apt-get install -y mysql-client
    echo "MySQL client installed successfully!"
fi
mysql --version


echo "Done [postCreateCommand.sh]."