#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [03] INSTALLING ZINIT ============="
echo "=============================================="

# Install Zinit (fast Zsh plugin manager)
if [[ ! -d "$HOME/.zinit/bin" ]]; then
  echo "Installing Zinit..."
  mkdir -p "$HOME/.zinit/bin"
  git clone https://github.com/zdharma-continuum/zinit.git "$HOME/.zinit/bin"
  echo "✓ Zinit installed"
else
  echo "✓ Zinit already installed"
fi

echo "=============================================="
echo "============== [03] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 04-install-starship.sh"

