#!/usr/bin/env bash

set -e

echo "=============================================="
echo "===== [16] INSTALLING AWS VPN CLIENT ========="
echo "=============================================="

# Check if AWS VPN Client is already installed
if [ -d "/Applications/AWS VPN Client.app" ]; then
    echo "✓ AWS VPN Client is already installed"
    echo "=============================================="
    echo "============== [16] DONE ===================="
    echo "=============================================="
    exit 0
fi

# Detect macOS architecture
ARCH=$(uname -m)
if [ "$ARCH" = "arm64" ]; then
    ARCH_TYPE="arm64"
    PKG_ARCH="arm64"
elif [ "$ARCH" = "x86_64" ]; then
    ARCH_TYPE="x86_64"
    PKG_ARCH="x86_64"
else
    echo "⚠️  Unknown architecture: $ARCH"
    ARCH_TYPE="x86_64"
    PKG_ARCH="x86_64"
fi

echo "Detected macOS architecture: $ARCH_TYPE"
echo ""

# Check if Homebrew is installed (for curl if needed)
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    if command -v brew &> /dev/null; then
        brew install curl
    else
        echo "⚠️  curl is required but not available"
    fi
fi

echo "Installing AWS VPN Client for macOS..."
echo ""
echo "AWS VPN Client for macOS must be downloaded and installed manually."
echo ""
echo "Installation options:"
echo ""
echo "Option 1: Download and install manually (Recommended)"
echo "  1. Visit: https://aws.amazon.com/vpn/client-vpn-download/"
echo "  2. Download the macOS installer (.pkg file)"
echo "  3. Open the .pkg file and follow the installation wizard"
echo "  4. The app will be installed to /Applications/AWS VPN Client.app"
echo ""

# In smart mode, skip interactive prompts - just provide instructions
if [ "$INSTALL_ACTION" != "smart" ] && [ -t 0 ]; then
    read -p "Do you want to try automatic download? [y/N]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Attempting to download AWS VPN Client..."
        
        # Create temporary directory
        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"
        
        # AWS VPN Client download URL (this may change, so we'll try common patterns)
        # Note: AWS doesn't provide a direct download link, so we'll guide the user
        echo ""
        echo "⚠️  AWS VPN Client requires manual download from AWS website"
        echo "   Direct download links are not publicly available"
        echo ""
        echo "Please:"
        echo "  1. Visit: https://aws.amazon.com/vpn/client-vpn-download/"
        echo "  2. Sign in with your AWS account"
        echo "  3. Download the macOS installer"
        echo "  4. Run the installer: open ~/Downloads/awsvpnclient*.pkg"
        echo ""
        
        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    fi
fi

# Check if user has downloaded the file
if [ -f ~/Downloads/awsvpnclient*.pkg ] || [ -f ~/Downloads/AWSVPNClient*.pkg ]; then
    PKG_FILE=$(ls ~/Downloads/awsvpnclient*.pkg ~/Downloads/AWSVPNClient*.pkg 2>/dev/null | head -1)
    if [ -n "$PKG_FILE" ]; then
        echo "Found installer: $PKG_FILE"
        echo "Opening installer..."
        open "$PKG_FILE"
        echo ""
        echo "⚠️  Please complete the installation in the installer window"
        echo "   Once installed, AWS VPN Client will be available in Applications"
        echo ""
        echo "After installation, verify with:"
        echo "   ls -la /Applications/AWS\\ VPN\\ Client.app"
    fi
else
    echo "No installer found in ~/Downloads"
    echo ""
    echo "To install after downloading:"
    echo "  1. Download the .pkg file to ~/Downloads"
    echo "  2. Run: open ~/Downloads/awsvpnclient*.pkg"
    echo "  3. Follow the installation wizard"
fi

echo ""
echo "=============================================="
echo "============== [17] DONE ===================="
echo "=============================================="
echo ""
echo "📝 IMPORTANT NOTES:"
echo ""
echo "1. Configuration:"
echo "   - You need to import a configuration file when"
echo "     running the client for the first time"
echo "   - Access the configuration file from the"
echo "     AWS Client VPN Access Portal"
echo ""
echo "2. First run:"
echo "   - Open AWS VPN Client from Applications"
echo "   - Import your configuration file (.ovpn)"
echo "   - Connect to your VPN"
echo ""
echo "3. Docker compatibility:"
echo "   - On macOS, Docker Desktop should continue working"
echo "     when VPN is connected"
echo ""
echo "🎉 AWS VPN Client installation instructions provided!"

