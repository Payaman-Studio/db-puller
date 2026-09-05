#!/bin/bash
set -e

REPO_RAW="https://raw.githubusercontent.com/Payaman-Studio/db-puller/main"
INSTALL_DIR="$HOME/.local/bin"
INSTALL_PATH="$INSTALL_DIR/db-puller"

echo "Installing db-puller..."

for CMD in adb fzf; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "Warning: '$CMD' not found. db-puller needs it to run."
    fi
done

mkdir -p "$INSTALL_DIR"
curl -fsSL "$REPO_RAW/db-puller.sh" -o "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

echo "Installed to $INSTALL_PATH"

case ":$PATH:" in
    *":$INSTALL_DIR:"*) ;;
    *)
        echo ""
        echo "Note: $INSTALL_DIR is not in your PATH."
        echo "Add this to your shell profile (~/.zshrc or ~/.bashrc):"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac

echo ""
echo "Run it with: db-puller"