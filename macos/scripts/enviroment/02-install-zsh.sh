#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [02] INSTALLING ZSH ================"
echo "=============================================="

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

# Check if zsh is already installed
if ! command -v zsh &> /dev/null; then
    echo "ZSH is not installed. Installing via Homebrew..."
    
    # Check if Homebrew is installed
    if ! command -v brew &> /dev/null; then
        echo "❌ Homebrew is not installed. Please install Homebrew first:"
        echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        exit 1
    fi
    
    # Install zsh via Homebrew
    brew install zsh
else
    echo "✓ ZSH is already installed"
fi

# Ensure curl and git are available (usually pre-installed on macOS)
if ! command -v curl &> /dev/null; then
    echo "Installing curl..."
    if command -v brew &> /dev/null; then
        brew install curl
    else
        echo "⚠️  curl is not available and Homebrew is not installed"
    fi
fi

if ! command -v git &> /dev/null; then
    echo "Installing git..."
    if command -v brew &> /dev/null; then
        brew install git
    else
        echo "⚠️  git is not available and Homebrew is not installed"
    fi
fi

ZSH_BIN=$(which zsh)

echo "=============================================="
echo "===== [02] SETTING DEFAULT SHELL ============"
echo "=============================================="

if [ "$SHELL" != "$ZSH_BIN" ]; then
  # On macOS, we need to add zsh to /etc/shells first if not already there
  if ! grep -Fxq "$ZSH_BIN" /etc/shells 2>/dev/null; then
    echo "Adding $ZSH_BIN to /etc/shells..."
    echo "$ZSH_BIN" | sudo tee -a /etc/shells
  fi
  
  chsh -s "$ZSH_BIN"
  echo "✔ Default shell changed to ZSH"
  echo "⚠️  You may need to logout/login for the change to take effect"
else
  echo "✔ ZSH is already the default shell"
fi

echo "=============================================="
echo "===== [02] CREATING MINIMAL .zshrc ==========="
echo "=============================================="

cat > ~/.zshrc << 'EOF'
# ==========================================
#  Minimal ZSH bootstrap configuration file
# ==========================================

# Initialize completion system
autoload -Uz compinit
compinit

# Additional helper configurations will be appended below
# --------------------------------------------
EOF

echo "=============================================="
echo "===== [02] MINIMAL CONFIG CREATED ============"
echo "=============================================="
echo "Full ZSH configuration will be added by script 04"

echo "=============================================="
echo "============== [02] DONE ===================="
echo "=============================================="
echo "⚠️  Please close the terminal and open it again."
echo "▶ Next, run: bash 03-install-zinit.sh"

