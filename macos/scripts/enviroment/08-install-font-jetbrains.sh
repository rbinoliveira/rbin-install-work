#!/usr/bin/env bash

set -e

echo "=============================================="
echo "======== [08] INSTALLING CASKAYDIA FONT ======"
echo "=============================================="

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check if font is already installed via Homebrew
if brew list --cask font-caskaydia-cove-nerd-font &> /dev/null 2>&1; then
    echo "✓ CaskaydiaCove Nerd Font is already installed via Homebrew"
    echo "=============================================="
    echo "============== [08] DONE ===================="
    echo "=============================================="
    echo "▶ Next, run: bash 09-install-cursor.sh"
    exit 0
fi

# Try installing via Homebrew cask first (easiest method)
echo "Installing CaskaydiaCove Nerd Font via Homebrew..."
if brew install --cask font-caskaydia-cove-nerd-font; then
    echo "✓ Font installed successfully via Homebrew"
    echo "=============================================="
    echo "============== [08] DONE ===================="
    echo "=============================================="
    echo "▶ Next, run: bash 09-install-cursor.sh"
    exit 0
fi

# Fallback: Manual installation if Homebrew cask doesn't work
echo "Homebrew cask installation failed, trying manual installation..."

# Check for required tools (curl and unzip are usually pre-installed on macOS)
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    brew install curl
fi

if ! command -v unzip &> /dev/null; then
    echo "Installing unzip..."
    brew install unzip
fi

# macOS font directory
FONT_DIR="$HOME/Library/Fonts/CascadiaCode"
mkdir -p "$FONT_DIR"

echo "Downloading CascadiaCode Nerd Font..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

if curl -L -o CascadiaCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip; then
    echo "Extracting font..."
    unzip -o CascadiaCode.zip -d "$FONT_DIR" > /dev/null
    rm CascadiaCode.zip
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    
    echo "✓ Font installed successfully to $FONT_DIR"
    echo "⚠️  You may need to restart your terminal or applications to use the font"
else
    echo "❌ Failed to download font"
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "=============================================="
echo "============== [08] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 09-install-cursor.sh"

