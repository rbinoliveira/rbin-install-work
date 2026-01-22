#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [12] CONFIGURING SSH =============="
echo "=============================================="

# Check if OpenSSH is installed (usually pre-installed on macOS)
if ! command -v ssh &> /dev/null; then
    echo "OpenSSH not found. Installing via Homebrew..."
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew is not installed. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    brew install openssh
else
    echo "✓ OpenSSH is already installed"
fi

# Validate email from .env
if [ -z "$GIT_USER_EMAIL" ]; then
    echo "❌ GIT_USER_EMAIL is required in .env file"
    exit 1
fi

echo "Generating SSH key with email: $GIT_USER_EMAIL"
if [ ! -f ~/.ssh/id_ed25519 ]; then
  ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f ~/.ssh/id_ed25519 -N ""
  echo "✓ SSH key generated"
else
  echo "✓ SSH key already exists"
fi

echo "Starting SSH agent..."
eval "$(ssh-agent -s)" > /dev/null
ssh-add ~/.ssh/id_ed25519 2>/dev/null || echo "⚠️  Key may already be added to agent"

echo "Setting correct permissions..."
chmod 700 ~/.ssh
chmod 600 ~/.ssh/id_ed25519 2>/dev/null || true
chmod 644 ~/.ssh/id_ed25519.pub 2>/dev/null || true

echo "Copying public key to clipboard..."
# Use pbcopy on macOS instead of xclip
if command -v pbcopy &> /dev/null; then
    cat ~/.ssh/id_ed25519.pub | pbcopy
    echo "✓ Public key copied to clipboard"
else
    echo "⚠️  pbcopy not available, displaying public key:"
    echo ""
    cat ~/.ssh/id_ed25519.pub
    echo ""
    echo "Please copy the key above manually"
fi

echo "=============================================="
echo "============== [12] DONE ===================="
echo "=============================================="
echo "✅ SSH public key copied to clipboard!"
echo "   Go to GitHub/GitLab Settings → SSH Keys and paste it."
echo "▶ Next, run: bash 13-configure-inotify.sh"

