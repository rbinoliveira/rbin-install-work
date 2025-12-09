#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [04] INSTALLING STARSHIP ==========="
echo "=============================================="

echo "Installing Starship prompt..."
curl -sS https://starship.rs/install.sh | sh

echo "Copying starship.toml..."
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
mkdir -p ~/.config
cp "$SCRIPT_DIR/../config/starship.toml" ~/.config/starship.toml

echo "Updating .zshrc with Zinit + Starship + custom config..."
# Copy the complete zsh-config which includes Zinit and Starship
if [ -f "$SCRIPT_DIR/../config/zsh-config" ]; then
  cat "$SCRIPT_DIR/../config/zsh-config" > ~/.zshrc
  echo "✓ zsh-config applied successfully"
else
  echo "⚠️  zsh-config not found, using fallback configuration"
  # Fallback if file doesn't exist
  cat >> ~/.zshrc << 'EOF'
# Load Starship prompt
eval "$(starship init zsh)"
EOF
fi

echo "=============================================="
echo "============== [04] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 05-install-node-nvm.sh"

