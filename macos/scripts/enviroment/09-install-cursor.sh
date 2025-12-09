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


set -e

echo "=============================================="
echo "========= [09] INSTALLING CURSOR ============"
echo "=============================================="

INSTALLED=false

# Check if Cursor is already installed
if [ -d "/Applications/Cursor.app" ] || command -v cursor &> /dev/null; then
    echo "✓ Cursor is already installed"
    if [ -d "/Applications/Cursor.app" ]; then
        if command -v defaults &> /dev/null; then
            VERSION=$(defaults read /Applications/Cursor.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "unknown")
            echo "  Version: $VERSION"
        fi
    fi
    INSTALLED=true
fi

# Install via Homebrew if not installed
if [ "$INSTALLED" = false ]; then
    echo "Installing Cursor via Homebrew..."

    if command -v brew &> /dev/null; then
        if brew install --cask cursor; then
            echo "✓ Cursor installed successfully via Homebrew"
            INSTALLED=true
        else
            echo "⚠️  Homebrew installation failed"
        fi
    else
        echo "⚠️  Homebrew not found"
        echo ""
        echo "Please install Cursor manually:"
        echo "  1. Visit: https://cursor.sh"
        echo "  2. Click 'Download' and select macOS"
        echo "  3. Drag Cursor.app to Applications folder"
        echo ""
        echo "Or install Homebrew first, then run this script again"
        exit 0
    fi
fi

if [ "$INSTALLED" = true ]; then
    echo "Verifying installation..."

    # Wait a moment for the app to be fully available
    sleep 2

    if [ -d "/Applications/Cursor.app" ]; then
        echo "✓ Cursor.app found in Applications"
    fi

    # Check for command-line tool
    if command -v cursor &> /dev/null; then
        echo "✓ Cursor command-line tool is available"
        cursor --version 2>/dev/null || echo "⚠️  Version check failed, but Cursor is installed"
    else
        echo "⚠️  Cursor command-line tool not found in PATH"
        echo "   This is normal - the app is installed, but CLI may need manual setup"
    fi
else
    echo "❌ Cursor installation failed"
    exit 1
fi

echo "=============================================="
echo "============== [09] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 10-install-claude.sh"
