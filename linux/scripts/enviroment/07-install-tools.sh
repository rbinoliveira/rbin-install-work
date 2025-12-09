#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [07] INSTALLING TOOLS ============"
echo "=============================================="

echo "Installing productivity tools..."

# Update package list
sudo apt update -y

# Install tools
sudo apt install -y \
  zoxide \
  fzf \
  fd-find \
  bat \
  lsd \
  lazygit

# Create symlinks for fd (apt installs as fdfind)
if [ ! -L /usr/local/bin/fd ] && [ -f /usr/bin/fdfind ]; then
  sudo ln -s /usr/bin/fdfind /usr/local/bin/fd
fi

# Install FZF keybindings
if [ -f /usr/share/fzf/key-bindings.zsh ]; then
  echo "✓ FZF keybindings available"
else
  echo "⚠️  FZF keybindings not found, they may be in a different location"
fi

echo ""
echo "Installed tools:"
echo "  ✓ zoxide - smart cd"
echo "  ✓ fzf - fuzzy finder"
echo "  ✓ fd - fast find"
echo "  ✓ bat - better cat"
echo "  ✓ lsd - better ls"
echo "  ✓ lazygit - git TUI"

echo "=============================================="
echo "============== [07] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 08-install-font-jetbrains.sh"

