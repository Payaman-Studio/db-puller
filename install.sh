#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Payaman-Studio/db-puller/main"

echo "Installing db-puller..."

for CMD in adb fzf; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "Warning: '$CMD' not found. db-puller needs it to run."
    fi
done

if [ -w "/usr/local/bin" ]; then
    INSTALL_PATH="/usr/local/bin/db-puller"
    curl -fsSL "$REPO_RAW/db-puller.sh" -o "$INSTALL_PATH"
elif command -v sudo >/dev/null 2>&1; then
    INSTALL_PATH="/usr/local/bin/db-puller"
    curl -fsSL "$REPO_RAW/db-puller.sh" | sudo tee "$INSTALL_PATH" >/dev/null
else
    mkdir -p "$HOME/.local/bin"
    INSTALL_PATH="$HOME/.local/bin/db-puller"
    curl -fsSL "$REPO_RAW/db-puller.sh" -o "$INSTALL_PATH"
fi

chmod +x "$INSTALL_PATH"

echo "Installed to $INSTALL_PATH"

case ":$PATH:" in
    *":$(dirname "$INSTALL_PATH"):"*) ;;
    *) echo "Note: $(dirname "$INSTALL_PATH") is not in your PATH. Add it to your shell profile." ;;
esac

echo "Run it with: db-puller"