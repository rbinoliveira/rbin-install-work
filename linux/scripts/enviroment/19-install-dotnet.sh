#!/usr/bin/env bash
set -e
echo "=============================================="
echo "========= [19] INSTALLING DOTNET ============"
echo "=============================================="
# .NET version to install (try 10.0 first, fallback to 8.0 LTS)
DOTNET_VERSION="10"
FALLBACK_VERSION="8"
# Check if .NET is already installed
if command -v dotnet &> /dev/null; then
    CURRENT_VERSION=$(dotnet --version 2>/dev/null | head -n 1)
    MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)
    if [ "$MAJOR_VERSION" = "$DOTNET_VERSION" ]; then
        echo "✓ .NET ${DOTNET_VERSION} is already installed (version: $CURRENT_VERSION)"
        echo "Skipping installation..."
        exit 0
    else
        echo ":atenção:  .NET $MAJOR_VERSION is installed, but .NET ${DOTNET_VERSION} is required"
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
    echo ":atenção:  Cannot detect Ubuntu version"
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
# Install .NET SDK (try preferred version, fallback to LTS)
echo "Installing .NET SDK ${DOTNET_VERSION}.0..."
if ! sudo apt-get install -y dotnet-sdk-${DOTNET_VERSION}.0 2>&1; then
    echo ":atenção:  .NET SDK ${DOTNET_VERSION}.0 not available, trying LTS version ${FALLBACK_VERSION}.0..."
    if ! sudo apt-get install -y dotnet-sdk-${FALLBACK_VERSION}.0 2>&1; then
        echo ":x_vermelho: Failed to install .NET SDK ${DOTNET_VERSION}.0 or ${FALLBACK_VERSION}.0"
        echo ""
        echo "Available .NET SDK versions:"
        apt-cache search dotnet-sdk | grep -E "^dotnet-sdk-[0-9]" | head -5
        echo ""
        echo "Please install manually or check available versions:"
        echo "  apt-cache search dotnet-sdk"
        exit 1
    else
        DOTNET_VERSION="$FALLBACK_VERSION"
        echo "✓ Installed .NET SDK ${FALLBACK_VERSION}.0 (LTS)"
    fi
else
    echo "✓ Installed .NET SDK ${DOTNET_VERSION}.0"
fi
# Verify installation
if command -v dotnet &> /dev/null; then
    INSTALLED_VERSION=$(dotnet --version)
    echo "✓ .NET SDK installed successfully (version: $INSTALLED_VERSION)"
    # Show installed SDKs
    echo ""
    echo "Installed SDKs:"
    dotnet --list-sdks
else
    echo ":x_vermelho: .NET SDK installation failed"
    exit 1
fi
echo "=============================================="
        echo "============== [19] DONE ===================="
        echo "=============================================="
        echo ":seta_para_frente: Next, run: bash 20-install-java.sh"