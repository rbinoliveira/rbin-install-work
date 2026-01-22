#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [17] INSTALLING AWS CLI ============"
echo "=============================================="

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if AWS CLI is already installed
if command -v aws &> /dev/null; then
    CURRENT_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2)
    echo "✓ AWS CLI is already installed (version: $CURRENT_VERSION)"
    echo "=============================================="
    echo "============== [17] DONE ===================="
    echo "=============================================="
    echo "▶ Next, run: bash 18-configure-aws-sso.sh"
    exit 0
fi

echo "Installing AWS CLI v2..."

# Try Homebrew first (easiest on macOS)
if command -v brew &> /dev/null; then
    echo "Installing AWS CLI via Homebrew..."
    if brew install awscli; then
        echo "✓ AWS CLI installed successfully via Homebrew"
        echo "=============================================="
        echo "============== [17] DONE ===================="
        echo "=============================================="
        echo "▶ Next, run: bash 18-configure-aws-sso.sh"
        exit 0
    else
        echo "⚠️  Homebrew installation failed, trying official installer..."
    fi
fi

# Fallback to official installer
echo "Installing AWS CLI using official installer..."

# Create temporary directory
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Detect architecture
ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_TYPE="x86_64"
elif [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
    ARCH_TYPE="arm64"
else
    echo "⚠️  Unsupported architecture: $ARCH"
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    exit 1
fi

echo "Detected architecture: $ARCH_TYPE"
echo "Downloading AWS CLI v2 for macOS..."

# Download AWS CLI v2 for macOS
if curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"; then
    echo "Installing AWS CLI..."
    sudo installer -pkg AWSCLIV2.pkg -target /
    
    # Verify installation
    if command -v aws &> /dev/null; then
        INSTALLED_VERSION=$(aws --version 2>&1 | awk '{print $1}' | cut -d'/' -f2)
        echo "✓ AWS CLI installed successfully (version: $INSTALLED_VERSION)"
    else
        echo "⚠️  AWS CLI installed but not in PATH"
        echo "   You may need to restart your terminal"
    fi
else
    echo "❌ Failed to download AWS CLI installer"
    echo ""
    echo "Please install manually:"
    echo "  1. Visit: https://aws.amazon.com/cli/"
    echo "  2. Download AWS CLI v2 for macOS"
    echo "  3. Run the installer"
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Cleanup
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo "=============================================="
echo "============== [18] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 19-configure-aws-sso.sh"

