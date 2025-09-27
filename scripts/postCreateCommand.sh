#!/bin/bash
echo "Running postCreateCommand as [$(whoami)]..."

# Install Hugo (latest version)
echo "Installing Hugo..."
HUGO_URL=$(curl -s https://api.github.com/repos/gohugoio/hugo/releases/latest | grep "browser_download_url.*hugo_extended.*Linux-64bit.tar.gz" | head -1 | cut -d '"' -f 4)
cd /tmp
curl -L -o hugo.tar.gz "$HUGO_URL"
tar -xzf hugo.tar.gz
sudo mv hugo /usr/local/bin/
rm -f hugo.tar.gz LICENSE README.md
echo "Hugo installed successfully!"
hugo version

echo "Done."