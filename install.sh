#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Payaman-Studio/db-puller/main"
INSTALL_PATH="/usr/local/bin/db-puller"

echo "Installing db-puller..."

for CMD in adb fzf; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "Warning: '$CMD' not found. db-puller needs it to run."
    fi
done

curl -fsSL "$REPO_RAW/db-puller.sh" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "Installed to $INSTALL_PATH"
echo "Run it with: db-puller"
