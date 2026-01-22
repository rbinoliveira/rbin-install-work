#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [20] INSTALLING JAVA 21 ==========="
echo "=============================================="

# Java version to install (current LTS)
JAVA_VERSION="21"

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if Java is already installed
if command -v java &> /dev/null; then
    CURRENT_VERSION=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
    MAJOR_VERSION=$(echo "$CURRENT_VERSION" | cut -d. -f1)

    if [ "$MAJOR_VERSION" = "$JAVA_VERSION" ]; then
        echo "✓ Java ${JAVA_VERSION} is already installed (version: $CURRENT_VERSION)"
        echo "Skipping installation..."

        # Verify JAVA_HOME is set
        if [ -z "$JAVA_HOME" ]; then
            echo "⚠️  JAVA_HOME is not set. Setting it up..."
            # On macOS, find Java home using /usr/libexec/java_home
            if command -v /usr/libexec/java_home &> /dev/null; then
                JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${JAVA_VERSION} 2>/dev/null || /usr/libexec/java_home)
            else
                JAVA_HOME_PATH=$(dirname $(dirname $(readlink $(which java) || which java)))
            fi
            if ! grep -q "JAVA_HOME" ~/.zshrc 2>/dev/null; then
                echo "" >> ~/.zshrc
                echo "# Java ${JAVA_VERSION} Configuration" >> ~/.zshrc
                echo "export JAVA_HOME=\"$JAVA_HOME_PATH\"" >> ~/.zshrc
                echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc
            fi
            echo "✓ JAVA_HOME configured (will be available after restart)"
        fi
        
        echo "=============================================="
        echo "============== [20] DONE ===================="
        echo "=============================================="
        echo "▶ Next, run: bash 21-configure-github-token.sh"
        exit 0
    else
        echo "⚠️  Java $MAJOR_VERSION is installed, but Java ${JAVA_VERSION} is required"
        echo "Installing Java ${JAVA_VERSION}..."
        echo "   (Multiple Java versions can coexist)"
    fi
else
    echo "Installing OpenJDK ${JAVA_VERSION}..."
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "Installing Java ${JAVA_VERSION} via Homebrew..."
echo ""

# Try cask first (Eclipse Temurin - easier, no special permissions needed)
INSTALLED=false
echo "Method 1: Trying Eclipse Temurin (recommended)..."
if brew install --cask temurin${JAVA_VERSION} 2>&1; then
    echo "✓ Java ${JAVA_VERSION} installed successfully via Temurin"
    INSTALLED=true
else
    echo "⚠️  Temurin installation failed, trying OpenJDK formula..."
    
    # Try formula (may require permissions fix)
    set +e  # Don't fail on permission errors
    INSTALL_OUTPUT=$(brew install openjdk@${JAVA_VERSION} 2>&1)
    INSTALL_EXIT=$?
    set -e
    
    if [ $INSTALL_EXIT -eq 0 ]; then
        echo "✓ OpenJDK ${JAVA_VERSION} installed successfully"
        INSTALLED=true
    elif echo "$INSTALL_OUTPUT" | grep -q "not writable\|permission"; then
        echo "⚠️  Homebrew permission issue detected"
        echo ""
        echo "To fix Homebrew permissions, run:"
        echo "   sudo chown -R $(whoami) $(brew --prefix)"
        echo ""
        echo "Or try installing via cask (no permissions needed):"
        echo "   brew install --cask temurin${JAVA_VERSION}"
        echo ""
        echo "Trying alternative: Download from Adoptium..."
        INSTALLED=false
    else
        echo "⚠️  Installation failed:"
        echo "$INSTALL_OUTPUT" | tail -5
        INSTALLED=false
    fi
fi

# If Homebrew failed, try direct download
if [ "$INSTALLED" = false ]; then
    echo ""
    echo "Method 2: Downloading from Adoptium..."
    
    # Detect architecture
    ARCH=$(uname -m)
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then
        ARCH_TYPE="aarch64"
    else
        ARCH_TYPE="x64"
    fi
    
    TEMP_DIR=$(mktemp -d)
    cd "$TEMP_DIR"
    
    # Try to get latest JDK 21 from Adoptium API
    echo "  Fetching latest JDK ${JAVA_VERSION} download URL..."
    DOWNLOAD_URL=$(curl -s "https://api.adoptium.net/v3/assets/latest/${JAVA_VERSION}/hotspot?architecture=${ARCH_TYPE}&image_type=jdk&os=mac&vendor=eclipse" | grep -o '"link": *"[^"]*\.pkg"' | head -1 | cut -d'"' -f4)
    
    if [ -n "$DOWNLOAD_URL" ]; then
        echo "  Downloading JDK ${JAVA_VERSION}..."
        PKG_FILE="$TEMP_DIR/jdk${JAVA_VERSION}.pkg"
        
        if curl -L -o "$PKG_FILE" "$DOWNLOAD_URL"; then
            echo "  Installing JDK ${JAVA_VERSION}..."
            sudo installer -pkg "$PKG_FILE" -target /
            
            if command -v java &> /dev/null || /usr/libexec/java_home -v ${JAVA_VERSION} &> /dev/null; then
                echo "✓ Java ${JAVA_VERSION} installed successfully"
                INSTALLED=true
            fi
        fi
    fi
    
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
fi

# Final check
if [ "$INSTALLED" = false ]; then
    echo ""
    echo "❌ Failed to install Java ${JAVA_VERSION} automatically"
    echo ""
    echo "Please install manually using one of these methods:"
    echo ""
    echo "Option 1: Fix Homebrew permissions and retry"
    echo "   sudo chown -R $(whoami) $(brew --prefix)"
    echo "   brew install --cask temurin${JAVA_VERSION}"
    echo ""
    echo "Option 2: Download from Adoptium"
    echo "   1. Visit: https://adoptium.net/temurin/releases/?version=${JAVA_VERSION}"
    echo "   2. Download JDK ${JAVA_VERSION} for macOS (${ARCH_TYPE})"
    echo "   3. Run the installer"
    echo ""
    echo "Option 3: Use SDKMAN (Java version manager)"
    echo "   curl -s \"https://get.sdkman.io\" | bash"
    echo "   source \"\$HOME/.sdkman/bin/sdkman-init.sh\""
    echo "   sdk install java ${JAVA_VERSION}-tem"
    echo ""
    exit 1
fi

# Set JAVA_HOME
echo ""
echo "Configuring JAVA_HOME..."

# On macOS, use /usr/libexec/java_home to find the correct path (works for all installation methods)
if command -v /usr/libexec/java_home &> /dev/null; then
    JAVA_HOME_PATH=$(/usr/libexec/java_home -v ${JAVA_VERSION} 2>/dev/null || /usr/libexec/java_home -v ${JAVA_VERSION}.0 2>/dev/null || /usr/libexec/java_home)
    if [ -z "$JAVA_HOME_PATH" ] || [ ! -d "$JAVA_HOME_PATH" ]; then
        # Try to find any Java ${JAVA_VERSION}
        JAVA_HOME_PATH=$(/usr/libexec/java_home -V 2>&1 | grep "${JAVA_VERSION}" | head -1 | awk '{print $NF}' || /usr/libexec/java_home)
    fi
else
    # Fallback: find Java in Homebrew installation
    if [ -d "$(brew --prefix)/opt/openjdk@${JAVA_VERSION}" ]; then
        JAVA_HOME_PATH=$(brew --prefix)/opt/openjdk@${JAVA_VERSION}
    elif [ -d "$(brew --prefix)/opt/temurin${JAVA_VERSION}" ]; then
        JAVA_HOME_PATH=$(brew --prefix)/opt/temurin${JAVA_VERSION}
    elif [ -d "/Library/Java/JavaVirtualMachines/temurin-${JAVA_VERSION}.jdk/Contents/Home" ]; then
        JAVA_HOME_PATH="/Library/Java/JavaVirtualMachines/temurin-${JAVA_VERSION}.jdk/Contents/Home"
    elif [ -d "/Library/Java/JavaVirtualMachines" ]; then
        # Find latest JDK ${JAVA_VERSION} in standard location
        JAVA_HOME_PATH=$(ls -d /Library/Java/JavaVirtualMachines/*${JAVA_VERSION}*.jdk/Contents/Home 2>/dev/null | head -1)
    else
        JAVA_HOME_PATH=$(dirname $(dirname $(which java 2>/dev/null || echo "")))
    fi
fi

if [ -d "$JAVA_HOME_PATH" ]; then
    if ! grep -q "JAVA_HOME" ~/.zshrc 2>/dev/null; then
        echo "" >> ~/.zshrc
        echo "# Java ${JAVA_VERSION} Configuration" >> ~/.zshrc
        echo "export JAVA_HOME=\"$JAVA_HOME_PATH\"" >> ~/.zshrc
        echo "export PATH=\$JAVA_HOME/bin:\$PATH" >> ~/.zshrc
    else
        # Update existing JAVA_HOME
        sed -i.bak "s|export JAVA_HOME=.*|export JAVA_HOME=\"$JAVA_HOME_PATH\"|" ~/.zshrc 2>/dev/null || \
        sed -i '' "s|export JAVA_HOME=.*|export JAVA_HOME=\"$JAVA_HOME_PATH\"|" ~/.zshrc 2>/dev/null || true
        rm -f ~/.zshrc.bak 2>/dev/null || true
    fi
    echo "✓ JAVA_HOME configured: $JAVA_HOME_PATH"
    echo "   (will be available after restart or: source ~/.zshrc)"
    
    # Set for current session
    export JAVA_HOME="$JAVA_HOME_PATH"
    export PATH="$JAVA_HOME/bin:$PATH"
else
    echo "⚠️  Could not determine JAVA_HOME path"
    echo "   Please set it manually in ~/.zshrc"
fi

# Verify installation
if command -v java &> /dev/null; then
    INSTALLED_VERSION=$(java -version 2>&1 | head -n 1)
    echo ""
    echo "✓ Java installed successfully"
    echo "  $INSTALLED_VERSION"

    # Show Java version details
    echo ""
    echo "Java details:"
    java -version
    echo ""
    echo "JAVA_HOME: $JAVA_HOME"
else
    echo "⚠️  Java command not found in PATH"
    echo "   You may need to restart your terminal or run: source ~/.zshrc"
    echo "   Or set JAVA_HOME manually"
fi

echo "=============================================="
echo "============== [20] DONE ===================="
echo "=============================================="
echo "⚠️  Restart terminal or run: source ~/.zshrc"
echo "▶ Next, run: bash 21-configure-github-token.sh"
