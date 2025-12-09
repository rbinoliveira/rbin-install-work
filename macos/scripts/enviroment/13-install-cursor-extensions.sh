#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [14] INSTALLING CURSOR EXTENSIONS ==="
echo "=============================================="

# Find the correct cursor executable
CURSOR_CMD=""
if command -v cursor &> /dev/null; then
  # Check if the cursor command is actually executable (not XML error)
  if cursor --version &> /dev/null; then
    CURSOR_CMD="cursor"
  fi
fi

# Try alternative paths if cursor command doesn't work
if [ -z "$CURSOR_CMD" ]; then
  if [ -f "/usr/share/cursor/bin/cursor" ] && /usr/share/cursor/bin/cursor --version &> /dev/null; then
    CURSOR_CMD="/usr/share/cursor/bin/cursor"
  elif [ -f "/usr/share/cursor/cursor" ] && /usr/share/cursor/cursor --version &> /dev/null; then
    CURSOR_CMD="/usr/share/cursor/cursor"
  elif [ -f "/opt/cursor/cursor" ] && /opt/cursor/cursor --version &> /dev/null; then
    CURSOR_CMD="/opt/cursor/cursor"
  fi
fi

if [ -z "$CURSOR_CMD" ]; then
  echo "❌ Cursor is not installed or not found"
  echo "   Please install Cursor first by running: bash 09-install-cursor.sh"
  echo "   Or install it manually from: https://cursor.sh"
  exit 1
fi

echo "Using Cursor: $CURSOR_CMD"
$CURSOR_CMD --version 2>/dev/null || echo "⚠️  Version check failed, but continuing..."

echo ""
EXTS=(
  "naumovs.color-highlight"
  "mikestead.dotenv"
  "dbaeumer.vscode-eslint"
  "eamodio.gitlens"
  "shd101wyy.markdown-preview-enhanced"
  "Prisma.prisma"
  "sainoba.px-to-rem"
  "natqe.reload"
  "bradlc.vscode-tailwindcss"
  "oderwat.indent-rainbow"
  "castrogusttavo.symbols"
  "catppuccin.catppuccin-vsc"
)

for ext in "${EXTS[@]}"; do
  echo "→ Installing: $ext"
  $CURSOR_CMD --install-extension "$ext" 2>&1 | grep -v "XML\|Error\|Access" || echo "⚠ Failed to install $ext (ignoring)"
done

echo ""
echo "All extensions attempted."

echo "=============================================="
echo "============== [14] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 14-configure-cursor.sh"

