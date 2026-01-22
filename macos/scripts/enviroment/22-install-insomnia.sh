#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [22] INSTALLING INSOMNIA ==========="
echo "=============================================="

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if Insomnia is already installed
if command -v insomnia &> /dev/null || [ -d "/Applications/Insomnia.app" ]; then
    echo "✓ Insomnia is already installed"
    if [ -d "/Applications/Insomnia.app" ] && command -v defaults &> /dev/null; then
        INSOMNIA_VERSION=$(defaults read /Applications/Insomnia.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null || echo "installed")
        if [ -n "$INSOMNIA_VERSION" ] && [ "$INSOMNIA_VERSION" != "installed" ]; then
            echo "  Version: $INSOMNIA_VERSION"
        fi
    fi
    echo "Skipping installation..."
else
    echo "Installing Insomnia..."

    # Check if Homebrew is available
    if command -v brew &> /dev/null; then
        echo ""
        echo "📥 Installing Insomnia via Homebrew Cask..."

        if brew install --cask insomnia; then
            echo "✓ Insomnia installed successfully via Homebrew"
            INSTALLED=true
        else
            echo "⚠️  Homebrew installation failed, trying direct download..."
            INSTALLED=false
        fi
    else
        INSTALLED=false
    fi

    # Method 2: Direct download if Homebrew failed or not available
    if [ "$INSTALLED" != true ]; then
        echo ""
        echo "📥 Downloading Insomnia directly..."

        # Get latest version from GitHub releases
        LATEST_VERSION=$(curl -s https://api.github.com/repos/Kong/insomnia/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/' | sed 's/^v//')

        if [ -z "$LATEST_VERSION" ]; then
            echo "❌ Failed to get latest Insomnia version"
            echo "   Please install Insomnia manually from: https://insomnia.rest/download"
            exit 1
        fi

        echo "  Downloading Insomnia v${LATEST_VERSION}..."

        TEMP_DIR=$(mktemp -d)
        cd "$TEMP_DIR"

        # Detect architecture
        ARCH=$(uname -m)
        if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
            DMG_ARCH="arm64"
        else
            DMG_ARCH="x64"
        fi

        # Download .dmg
        DMG_URL="https://github.com/Kong/insomnia/releases/download/v${LATEST_VERSION}/Insomnia-${LATEST_VERSION}-${DMG_ARCH}.dmg"
        DMG_FILE="$TEMP_DIR/Insomnia.dmg"

        if curl -sSL "$DMG_URL" -o "$DMG_FILE"; then
            echo "  Mounting and installing..."

            # Mount DMG
            MOUNT_POINT=$(hdiutil attach "$DMG_FILE" -nobrowse -quiet | tail -1 | awk -F'\t' '{print $3}')

            if [ -n "$MOUNT_POINT" ] && [ -d "$MOUNT_POINT/Insomnia.app" ]; then
                # Copy to Applications
                sudo cp -R "$MOUNT_POINT/Insomnia.app" /Applications/

                # Unmount
                hdiutil detach "$MOUNT_POINT" -quiet

                echo "✓ Insomnia installed successfully"
                INSTALLED=true
            else
                echo "❌ Failed to mount or find Insomnia.app in DMG"
            fi

            rm -f "$DMG_FILE"
        else
            echo "❌ Failed to download Insomnia"
        fi

        cd - > /dev/null
        rm -rf "$TEMP_DIR"
    fi

    # Final check
    if [ "$INSTALLED" != true ]; then
        echo "❌ Failed to install Insomnia automatically"
        echo ""
        echo "Please install Insomnia manually:"
        echo "  1. Visit: https://insomnia.rest/download"
        echo "  2. Download the macOS version"
        echo "  3. Install Insomnia.app to /Applications"
        exit 1
    fi
fi

echo "=============================================="
echo "============== [22] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 23-install-tableplus.sh"
