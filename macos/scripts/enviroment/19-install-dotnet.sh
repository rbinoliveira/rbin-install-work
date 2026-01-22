#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [19] INSTALLING DOTNET 9 ==========="
echo "=============================================="

# .NET version to install (current LTS)
DOTNET_VERSION="9"
DOTNET_CHANNEL="9.0"

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if .NET is already installed
if command -v dotnet &> /dev/null; then
    CURRENT_VERSION=$(dotnet --version 2>/dev/null | head -n 1)
    MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)
    
    # Check if .NET 9 SDK is already installed
    if dotnet --list-sdks 2>/dev/null | grep -q "^${DOTNET_VERSION}\."; then
        echo "✓ .NET ${DOTNET_VERSION} is already installed"
        echo ""
        echo "Installed SDKs:"
        dotnet --list-sdks
        echo ""
        echo "=============================================="
        echo "============== [19] DONE ===================="
        echo "=============================================="
        echo "▶ Next, run: bash 20-install-java.sh"
        exit 0
    else
        echo "✓ .NET is installed (version: $CURRENT_VERSION)"
        echo "⚠️  .NET ${DOTNET_VERSION} SDK not found, installing .NET ${DOTNET_VERSION}..."
        echo "   (Multiple .NET versions can coexist)"
    fi
else
    echo "Installing .NET SDK ${DOTNET_VERSION}..."
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "Installing .NET SDK ${DOTNET_VERSION} via Homebrew..."
echo ""

# Install .NET SDK using Homebrew (dotnet-sdk includes multiple versions)
INSTALLED_VIA_BREW=false
if brew install --cask dotnet-sdk; then
    INSTALLED_VIA_BREW=true
    echo "✓ .NET SDK installed successfully via Homebrew"
    
    # Check if .NET 9 is available after installation
    if command -v dotnet &> /dev/null; then
        if dotnet --list-sdks | grep -q "^${DOTNET_VERSION}\."; then
            echo "✓ .NET ${DOTNET_VERSION} SDK is available"
        else
            echo "⚠️  .NET SDK installed but .NET ${DOTNET_VERSION} not found in installed SDKs"
            echo "   Installing .NET ${DOTNET_VERSION} SDK via official installer..."
            INSTALLED_VIA_BREW=false  # Will try official installer
        fi
    fi
fi

# If Homebrew didn't work or .NET 9 is not available, try official installer
if [ "$INSTALLED_VIA_BREW" = false ]; then
    echo ""
    echo "Installing .NET SDK ${DOTNET_VERSION} using official installer..."
    
    # Use channel 9.0 without specific version to get latest 9.x
    set +e  # Don't fail on installer errors
    INSTALL_OUTPUT=$(curl -sSL https://dot.net/v1/dotnet-install.sh | bash /dev/stdin --channel ${DOTNET_CHANNEL} 2>&1)
    INSTALL_EXIT=$?
    set -e
    
    if [ $INSTALL_EXIT -eq 0 ]; then
        # Add to PATH if not already there
        DOTNET_PATH="$HOME/.dotnet"
        if [ -d "$DOTNET_PATH" ]; then
            if ! echo "$PATH" | grep -q "$DOTNET_PATH"; then
                echo ""
                echo "⚠️  Add .NET to your PATH by adding this to ~/.zshrc:"
                echo "   export PATH=\"\$PATH:\$HOME/.dotnet\""
                echo ""
                # Try to add it for this session
                export PATH="$PATH:$HOME/.dotnet"
            fi
        fi
        echo "✓ .NET SDK ${DOTNET_VERSION} installed successfully"
    else
        echo "⚠️  Official installer had issues, but .NET may still be installed"
        echo "$INSTALL_OUTPUT" | tail -5
        echo ""
        
        # Check if dotnet is available anyway
        if command -v dotnet &> /dev/null; then
            echo "✓ .NET is available, continuing..."
        else
            echo "❌ .NET SDK installation failed"
            echo ""
            echo "Please install manually:"
            echo "  1. Visit: https://dotnet.microsoft.com/download/dotnet/${DOTNET_CHANNEL}"
            echo "  2. Download the macOS installer (.pkg file)"
            echo "  3. Run: open ~/Downloads/dotnet-sdk-*.pkg"
            echo ""
            echo "Or try: brew install --cask dotnet-sdk"
            exit 1
        fi
    fi
fi

# Verify installation
if command -v dotnet &> /dev/null; then
    INSTALLED_VERSION=$(dotnet --version)
    echo ""
    echo "✓ .NET SDK is available (version: $INSTALLED_VERSION)"

    # Show installed SDKs
    echo ""
    echo "Installed SDKs:"
    dotnet --list-sdks
    
    # Check if .NET 9 is in the list
    if dotnet --list-sdks | grep -q "^${DOTNET_VERSION}\."; then
        echo ""
        echo "✓ .NET ${DOTNET_VERSION} SDK is available and ready to use"
    else
        echo ""
        echo "⚠️  .NET ${DOTNET_VERSION} SDK not found in installed SDKs"
        echo "   Current version: $INSTALLED_VERSION"
        echo ""
        echo "   To install .NET ${DOTNET_VERSION} specifically:"
        echo "   1. Visit: https://dotnet.microsoft.com/download/dotnet/${DOTNET_CHANNEL}"
        echo "   2. Download the macOS installer"
        echo "   3. Or run: dotnet --list-sdks to see available versions"
        echo ""
        echo "   Note: Multiple .NET versions can coexist"
    fi
else
    echo "⚠️  .NET command not found in PATH"
    echo "   You may need to restart your terminal or add .NET to PATH"
    echo "   Try: export PATH=\"\$PATH:\$HOME/.dotnet\""
    echo ""
    echo "   Or restart your terminal to reload PATH"
fi

echo "=============================================="
echo "============== [19] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 20-install-java.sh"
