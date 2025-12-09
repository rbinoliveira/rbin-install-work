#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [08] INSTALLING JETBRAINS FONT ====="
echo "=============================================="

# Install required packages
echo "Installing required packages (wget, unzip, fontconfig)..."
sudo apt update -y
sudo apt install -y wget unzip fontconfig

FONT_DIR="$HOME/.local/share/fonts/JetBrainsMono"
mkdir -p "$FONT_DIR"

echo "Downloading JetBrainsMono Nerd Font..."
wget -q https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.zip

echo "Extracting font..."
unzip -o JetBrainsMono.zip -d "$FONT_DIR" > /dev/null
rm JetBrainsMono.zip

echo "Updating font cache..."
fc-cache -fv

echo "Font installed successfully."

echo "=============================================="
echo "============== [08] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 09-install-cursor.sh"

