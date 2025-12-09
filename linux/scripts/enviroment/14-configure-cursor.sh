#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [15] CONFIGURING CURSOR ============"
echo "=============================================="

# Determine Cursor user directory based on OS
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  CURSOR_USER_DIR="$HOME/.config/Cursor/User"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  CURSOR_USER_DIR="$HOME/Library/Application Support/Cursor/User"
else
  echo "❌ Operating system not automatically supported."
  exit 1
fi

mkdir -p "$CURSOR_USER_DIR"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS_PATH="$CURSOR_USER_DIR/settings.json"
KEYBINDINGS_PATH="$CURSOR_USER_DIR/keybindings.json"

echo "Detected Cursor directory: $CURSOR_USER_DIR"
echo ""

echo "Copying settings.json..."
cp "$SCRIPT_DIR/../config/user-settings.json" "$SETTINGS_PATH"
echo "→ settings.json updated successfully!"

echo "Copying keybindings.json..."
cp "$SCRIPT_DIR/../config/cursor-keyboard.json" "$KEYBINDINGS_PATH"
echo "→ keybindings.json updated successfully!"

echo "=============================================="
echo "============== [15] DONE ===================="
echo "=============================================="
echo "🎉 Cursor configured successfully!"
echo "   Open Cursor again to apply everything."
echo ""
echo "▶ Next, run: bash 15-install-docker.sh (final step)"

