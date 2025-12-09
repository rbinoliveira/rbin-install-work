#!/usr/bin/env bash

# ────────────────────────────────────────────────────────────────
# Module Guard - Prevent Direct Execution
# ────────────────────────────────────────────────────────────────
# This script should only be executed by 00-install-all.sh
if [ -z "$INSTALL_ALL_RUNNING" ]; then
    SCRIPT_NAME=$(basename "$0")
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    INSTALL_SCRIPT="$SCRIPT_DIR/00-install-all.sh"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  This script should not be executed directly"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "The script \"$SCRIPT_NAME\" is a module and should only be"
    echo "executed as part of the complete installation process."
    echo ""
    echo "To run the complete installation, use:"
    echo "  bash $INSTALL_SCRIPT"
    echo ""
    echo "Or from the project root:"
    echo "  bash run.sh"
    echo ""
    exit 1
fi


set -e

echo "=============================================="
echo "========= [10] INSTALLING CLAUDE CLI ========="
echo "=============================================="

# Load NVM if available
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

# Check if Node.js/npm is available
if ! command -v npm &> /dev/null; then
    echo "⚠️  npm not found. Claude Code CLI requires Node.js/npm."
    echo "   Please install Node.js first (script 05-install-node-nvm.sh)"
    echo "   Claude Code CLI will be installed when Node.js is available."
    exit 0
fi

echo "Installing Claude Code CLI via npm..."

# Check if already installed
if npm list -g @anthropic-ai/claude-code &> /dev/null; then
    VERSION=$(npm list -g @anthropic-ai/claude-code 2>/dev/null | grep claude-code | head -1 || echo "unknown")
    echo "✓ Claude Code CLI is already installed"
    echo "  Version: $VERSION"
else
    echo "→ Installing @anthropic-ai/claude-code..."
    if npm install -g @anthropic-ai/claude-code; then
        echo "✓ Claude Code CLI installed successfully"

        # Verify installation
        if command -v claude &> /dev/null; then
            echo "✓ Claude command is available"
            claude --version 2>/dev/null || echo "⚠️  Version check failed, but Claude is installed"
        else
            echo "⚠️  Claude command not found in PATH"
            echo "   You may need to restart your terminal or add npm global bin to PATH"
        fi
    else
        echo "❌ Failed to install Claude Code CLI"
        exit 1
    fi
fi

echo "=============================================="
echo "============== [10] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 10-configure-terminal.sh"
