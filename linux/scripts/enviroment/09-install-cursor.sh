#!/usr/bin/env bash

# ────────────────────────────────────────────────────────────────
# Module Guard - Prevent Direct Execution
# ────────────────────────────────────────────────────────────────
# This script should only be executed by 00-install-all.sh
if [ -z "$INSTALL_ALL_RUNNING" ]; then
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_SCRIPT="$SCRIPT_DIR/00-install-all.sh"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  This script should not be executed directly"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The script \"$SCRIPT_NAME\" is a module and should only be"
    echo "executed as part of the complete installation process."
    echo ""
    echo "To run the complete installation, use:"
    echo "  bash $INSTALL_SCRIPT"
    echo ""
    echo "Or from the project root:"
    echo "  bash run.sh"
    echo ""
    exit 1
fi


# Don't use set -e here because we need to handle installation failures gracefully
set +e

echo "=============================================="
echo "========= [09] INSTALLING CURSOR ============"
echo "=============================================="

echo "Downloading Cursor Editor..."

INSTALLED=false

# Install wget if not available
if ! command -v wget &> /dev/null; then
  echo "Installing wget..."
  sudo apt update -y
  sudo apt install -y wget
fi

# Try to download .deb directly from the downloader endpoint
DEB_URL="https://downloader.cursor.sh/linux/deb/x64"
echo "Downloading from: $DEB_URL"

if wget "$DEB_URL" -O cursor.deb 2>&1; then
  # Verify it's actually a .deb file
  if [ -f cursor.deb ] && file cursor.deb 2>/dev/null | grep -q "Debian binary package"; then
    echo "✓ Valid .deb file downloaded"
    echo "Installing Cursor..."
    if sudo dpkg -i cursor.deb 2>&1; then
      INSTALLED=true
    else
      echo "Fixing dependencies..."
      sudo apt --fix-broken install -y
      if sudo dpkg -i cursor.deb 2>&1; then
        INSTALLED=true
      fi
    fi
    rm -f cursor.deb
  else
    echo "⚠️  Downloaded file is not a valid .deb package"
    rm -f cursor.deb
  fi
fi

# If direct download failed, try alternative methods
if [ "$INSTALLED" = false ]; then
  echo "Trying alternative installation method..."

  # Check if cursor is already installed
  if command -v cursor &> /dev/null; then
    echo "✓ Cursor is already installed"
    INSTALLED=true
  else
    echo "⚠️  Automatic installation failed."
    echo ""
    echo "Please install Cursor manually:"
    echo "  1. Visit: https://cursor.sh"
    echo "  2. Click 'Download' and select Linux (.deb)"
    echo "  3. Install with: sudo dpkg -i ~/Downloads/cursor*.deb"
    echo ""
    echo "Or try: sudo snap install cursor"
    exit 0
  fi
fi

if [ "$INSTALLED" = true ]; then
  echo "Verifying installation..."

  # Find the correct cursor executable
  CURSOR_CMD=""
  if [ -f "/usr/share/cursor/bin/cursor" ]; then
    CURSOR_CMD="/usr/share/cursor/bin/cursor"
  elif [ -f "/usr/share/cursor/cursor" ]; then
    CURSOR_CMD="/usr/share/cursor/cursor"
  elif [ -f "/opt/cursor/cursor" ]; then
    CURSOR_CMD="/opt/cursor/cursor"
  fi

  # Remove incorrect /usr/local/bin/cursor if it exists and is not executable
  if [ -f "/usr/local/bin/cursor" ] && ! /usr/local/bin/cursor --version &> /dev/null; then
    echo "Removing incorrect cursor symlink..."
    sudo rm -f /usr/local/bin/cursor
  fi

  # Create correct symlink if cursor is installed but not in PATH
  if [ -n "$CURSOR_CMD" ] && [ ! -f "/usr/local/bin/cursor" ]; then
    echo "Creating cursor symlink..."
    sudo ln -sf "$CURSOR_CMD" /usr/local/bin/cursor
  fi

  # Verify installation
  if [ -n "$CURSOR_CMD" ] && $CURSOR_CMD --version &> /dev/null; then
    echo "✓ Cursor installed successfully!"
    $CURSOR_CMD --version 2>/dev/null | head -1
  elif command -v cursor &> /dev/null && cursor --version &> /dev/null; then
    echo "✓ Cursor installed successfully!"
    cursor --version 2>/dev/null | head -1
  else
    echo "✓ Cursor installed (version check unavailable)"
  fi
else
  echo "❌ Cursor installation failed"
  exit 1
fi

echo "=============================================="
echo "============== [09] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 10-install-claude.sh"
