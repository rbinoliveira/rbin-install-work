#!/usr/bin/env bash

# Don't exit on error immediately - we want to handle errors gracefully
set +e

echo "=============================================="
echo "========= [05] INSTALLING NODE + NVM ========="
echo "=============================================="

export NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
  echo "Installing NVM..."
  echo "This may take a few moments..."
  echo "Downloading NVM installer..."
  curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh -o /tmp/nvm-install.sh
  CURL_EXIT=$?
  if [ $CURL_EXIT -ne 0 ]; then
    echo "❌ Failed to download NVM installer. Please check your internet connection."
    exit 1
  fi
  echo "Running NVM installer..."
  bash /tmp/nvm-install.sh
  INSTALL_EXIT=$?
  rm -f /tmp/nvm-install.sh
  if [ $INSTALL_EXIT -ne 0 ]; then
    echo "❌ Failed to install NVM. Exit code: $INSTALL_EXIT"
    exit 1
  fi
  echo "✓ NVM installed successfully"
else
  echo "✓ NVM already installed."
fi

# Load NVM
echo "Loading NVM..."
if [ -s "$NVM_DIR/nvm.sh" ]; then
  \. "$NVM_DIR/nvm.sh" || {
    echo "❌ Failed to load NVM"
    exit 1
  }
  echo "✓ NVM loaded"
else
  echo "❌ NVM installation file not found"
  exit 1
fi

# Load bash completion if available
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" || true

echo "Installing Node 22..."
echo "This may take a few minutes - please be patient..."
if [ -s "$NVM_DIR/nvm.sh" ]; then
  # Source NVM again to ensure it's loaded
  echo "Sourcing NVM..."
  source "$NVM_DIR/nvm.sh"
  
  # Check if nvm command is available
  if ! command -v nvm &> /dev/null && ! type nvm &> /dev/null; then
    echo "⚠️  NVM command not found after sourcing. Trying alternative method..."
    export PATH="$NVM_DIR:$PATH"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  fi
  
  # Check if Node 22 is already installed
  if nvm list 22 &> /dev/null | grep -q "v22"; then
    echo "✓ Node 22 is already installed"
  else
    # Install Node 22
    echo "Downloading and compiling Node.js 22 (this can take 5-10 minutes)..."
    echo "Progress: Starting download..."
    echo "⚠️  This step may take 5-10 minutes. Please be patient..."
    nvm install 22
    INSTALL_NODE_EXIT=$?
    
    if [ $INSTALL_NODE_EXIT -ne 0 ]; then
      echo "⚠️  Failed to install Node 22. Exit code: $INSTALL_NODE_EXIT"
      echo "You can try installing manually later with: nvm install 22"
      exit 1
    fi
  fi
  
  echo "Setting Node 22 as default..."
  # Set as default and use it
  nvm alias default 22 || true
  nvm use 22 || true
  
  # Verify installation
  echo "Verifying installation..."
  if command -v node &> /dev/null; then
    echo "✓ Node  -> $(node -v)"
    echo "✓ NPM   -> $(npm -v)"
  else
    echo "⚠️  Node installed but not in PATH. Please restart terminal."
    echo "   After restart, run: nvm use 22"
  fi
else
  echo "⚠️  NVM installation failed. Please check the installation."
  exit 1
fi

echo "=============================================="
echo "============== [05] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 06-install-yarn.sh"

