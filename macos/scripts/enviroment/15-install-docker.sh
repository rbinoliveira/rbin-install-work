#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [15] INSTALLING DOCKER ============="
echo "=============================================="

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "✓ Docker is already installed: $(docker --version)"
    if docker ps &> /dev/null 2>&1; then
        echo "✓ Docker daemon is running"
        echo "=============================================="
        echo "============== [15] DONE ===================="
        echo "=============================================="
        echo "🎉 Docker is already installed and running!"
        exit 0
    else
        echo "⚠️  Docker is installed but daemon is not running"
        echo "   Please start Docker Desktop from Applications"
    fi
fi

# Check if Docker Desktop is installed but not in PATH
if [ -d "/Applications/Docker.app" ]; then
    echo "✓ Docker Desktop is installed"
    echo "⚠️  Please start Docker Desktop from Applications"
    echo "   Once started, Docker commands will be available"
    echo "=============================================="
    echo "============== [16] DONE ===================="
    echo "=============================================="
    exit 0
fi

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

echo "Installing Docker Desktop via Homebrew..."
echo "This will install Docker Desktop, which includes:"
echo "  - Docker Engine"
echo "  - Docker CLI"
echo "  - Docker Compose"
echo "  - Docker Desktop GUI"
echo ""

# In smart mode, skip interactive prompts
if [ "$INSTALL_ACTION" != "smart" ] && [ -t 0 ]; then
    read -p "Do you want to install Docker Desktop? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping Docker installation"
        exit 0
    fi
fi

# Install Docker Desktop via Homebrew cask
if brew install --cask docker; then
    echo "✓ Docker Desktop installed successfully"
    echo ""
    echo "⚠️  IMPORTANT: Docker Desktop needs to be started manually"
    echo "   1. Open Docker Desktop from Applications"
    echo "   2. Wait for Docker to start (whale icon in menu bar)"
    echo "   3. Docker commands will be available after Docker Desktop starts"
    echo ""
    echo "To start Docker Desktop now, run:"
    echo "   open -a Docker"
    echo ""
    
    # Try to open Docker Desktop
    if [ -d "/Applications/Docker.app" ]; then
        echo "Opening Docker Desktop..."
        open -a Docker
        echo "✓ Docker Desktop launch initiated"
        echo ""
        echo "⏳ Waiting for Docker to start (this may take a minute)..."
        sleep 5
        
        # Wait for Docker to be ready (with timeout)
        TIMEOUT=60
        ELAPSED=0
        while [ $ELAPSED -lt $TIMEOUT ]; do
            if docker ps &> /dev/null 2>&1; then
                echo "✓ Docker is running!"
                break
            fi
            sleep 2
            ELAPSED=$((ELAPSED + 2))
            echo "  Still waiting... (${ELAPSED}s/${TIMEOUT}s)"
        done
        
        if docker ps &> /dev/null 2>&1; then
            echo "✓ Docker is ready to use"
        else
            echo "⚠️  Docker Desktop is starting but not ready yet"
            echo "   Please wait for Docker Desktop to fully start"
        fi
    fi
else
    echo "❌ Failed to install Docker Desktop"
    echo ""
    echo "Alternative installation methods:"
    echo "  1. Download from: https://www.docker.com/products/docker-desktop"
    echo "  2. Or try: brew install --cask docker --force"
    exit 1
fi

echo "=============================================="
echo "============== [15] DONE ===================="
echo "=============================================="
echo "🎉 Docker Desktop installed successfully!"
echo ""
echo "Note: On macOS, Docker runs without sudo once Docker Desktop is started."
echo "      No need to add user to docker group (Linux-only requirement)."
echo ""
echo "🎉 INSTALLATION COMPLETE!"
echo "=============================================="
echo "All scripts have been executed successfully!"
echo "Restart the terminal to apply all changes."

