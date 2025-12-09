#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [06] INSTALLING YARN =============="
echo "=============================================="

# Load NVM if not already loaded
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

# Verify Node is installed
if ! command -v node &> /dev/null; then
  echo "⚠️  Node.js is not installed. Installing Node first..."
  source "$NVM_DIR/nvm.sh"
  nvm install 22
  nvm use 22
  nvm alias default 22
fi

if ! command -v node &> /dev/null; then
  echo "❌ Node.js installation failed. Cannot install Yarn."
  exit 1
fi

echo "Enabling Corepack + Yarn 1..."
corepack enable || {
  echo "⚠️  Corepack enable failed. Trying alternative method..."
  npm install -g yarn
}

# Try Corepack first, fallback to npm if it fails
if command -v corepack &> /dev/null; then
  corepack prepare yarn@1 --activate || {
    echo "⚠️  Corepack prepare failed. Using npm to install Yarn..."
    npm install -g yarn
  }
else
  echo "Installing Yarn via npm..."
  npm install -g yarn
fi

# Verify Yarn installation
if command -v yarn &> /dev/null; then
  echo "✓ Yarn  -> $(yarn -v)"
else
  echo "❌ Yarn installation failed."
  exit 1
fi

echo "=============================================="
echo "============== [06] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 07-install-tools.sh"

