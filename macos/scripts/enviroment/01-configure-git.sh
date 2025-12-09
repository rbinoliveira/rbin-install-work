#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [01] CONFIGURING GIT ==============="
echo "=============================================="

# Validate required values from .env
if [ -z "$GIT_USER_NAME" ]; then
    echo "❌ GIT_USER_NAME is required in .env file"
    exit 1
fi

if [ -z "$GIT_USER_EMAIL" ]; then
    echo "❌ GIT_USER_EMAIL is required in .env file"
    exit 1
fi

echo "Setting up Git identity..."
echo "  Name: $GIT_USER_NAME"
echo "  Email: $GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"
git config --global init.defaultBranch main
git config --global color.ui auto

echo "=============================================="
echo "============== [01] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 02-install-zsh.sh"

