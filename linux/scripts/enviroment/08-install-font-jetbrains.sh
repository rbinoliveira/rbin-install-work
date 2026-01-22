#!/usr/bin/env bash

set -e

echo "=============================================="
echo "======== [08] INSTALLING CASKAYDIA FONT ======"
echo "=============================================="

# Install required packages
echo "Installing required packages (wget, unzip, fontconfig)..."
sudo apt update -y
sudo apt install -y wget unzip fontconfig

FONT_DIR="$HOME/.local/share/fonts/CascadiaCode"
mkdir -p "$FONT_DIR"

echo "Downloading CascadiaCode Nerd Font..."
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/CascadiaCode.zip

echo "Extracting font..."
unzip -o CascadiaCode.zip -d "$FONT_DIR" > /dev/null
rm CascadiaCode.zip

echo "Updating font cache..."
fc-cache -fv

echo "Font installed successfully."

echo "=============================================="
echo "============== [08] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 09-install-cursor.sh"

