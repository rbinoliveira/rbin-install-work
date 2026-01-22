#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [19] INSTALLING DOTNET 9 ==========="
echo "=============================================="

# .NET version to install (current LTS)
DOTNET_VERSION="9"

# Check if .NET is already installed
if command -v dotnet &> /dev/null; then
    CURRENT_VERSION=$(dotnet --version 2>/dev/null | head -n 1)
    MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)

    if [ "$MAJOR_VERSION" = "$DOTNET_VERSION" ]; then
        echo "✓ .NET ${DOTNET_VERSION} is already installed (version: $CURRENT_VERSION)"
        echo "Skipping installation..."
        exit 0
    else
        echo "⚠️  .NET $MAJOR_VERSION is installed, but .NET ${DOTNET_VERSION} is required"
        echo "Installing .NET ${DOTNET_VERSION}..."
    fi
else
    echo "Installing .NET SDK ${DOTNET_VERSION}..."
fi

# Detect Ubuntu version
if [ -f /etc/os-release ]; then
    . /etc/os-release
    UBUNTU_VERSION=$(lsb_release -rs 2>/dev/null || echo "0")
else
    echo "⚠️  Cannot detect Ubuntu version"
    exit 1
fi

echo "Detected Ubuntu version: $UBUNTU_VERSION"
echo ""

# Add Microsoft repository
echo "Adding Microsoft repository..."
wget https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/packages-microsoft-prod.deb -O /tmp/packages-microsoft-prod.deb
sudo dpkg -i /tmp/packages-microsoft-prod.deb
rm /tmp/packages-microsoft-prod.deb

# Update package list
echo "Updating package list..."
sudo apt-get update -y

# Install .NET SDK 9
echo "Installing .NET SDK ${DOTNET_VERSION}.0..."
sudo apt-get install -y dotnet-sdk-${DOTNET_VERSION}.0

# Verify installation
if command -v dotnet &> /dev/null; then
    INSTALLED_VERSION=$(dotnet --version)
    echo "✓ .NET SDK installed successfully (version: $INSTALLED_VERSION)"

    # Show installed SDKs
    echo ""
    echo "Installed SDKs:"
    dotnet --list-sdks
else
    echo "❌ .NET SDK installation failed"
    exit 1
fi

echo "=============================================="
        echo "============== [19] DONE ===================="
        echo "=============================================="
        echo "▶ Next, run: bash 20-install-java.sh"
