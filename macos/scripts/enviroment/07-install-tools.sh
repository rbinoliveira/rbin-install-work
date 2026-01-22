#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [07] INSTALLING TOOLS ============"
echo "=============================================="

# Load platform detection if available
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
if [ -f "$PROJECT_ROOT/lib/platform.sh" ]; then
    source "$PROJECT_ROOT/lib/platform.sh"
fi

echo "Installing productivity tools..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    echo "❌ Homebrew is not installed. Please install Homebrew first:"
    echo "   /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check which tools are already installed
TOOLS_TO_INSTALL=()
TOOLS_ALREADY_INSTALLED=()

check_tool() {
    local tool="$1"
    if command -v "$tool" &> /dev/null; then
        TOOLS_ALREADY_INSTALLED+=("$tool")
        return 0
    else
        TOOLS_TO_INSTALL+=("$tool")
        return 0
    fi
}

# Check tools (fd is just 'fd' on macOS via Homebrew, not 'fdfind')
set +e
check_tool zoxide
check_tool fzf
check_tool fd
check_tool bat
check_tool lsd
check_tool lazygit
set -e

# Show already installed tools
if [ ${#TOOLS_ALREADY_INSTALLED[@]} -gt 0 ]; then
    echo "Tools already installed:"
    for tool in "${TOOLS_ALREADY_INSTALLED[@]}"; do
        echo "  ✓ $tool"
    done
    echo ""

    if [ ${#TOOLS_TO_INSTALL[@]} -eq 0 ]; then
        echo "All tools are already installed and ready to use."
        echo "To upgrade tools later, run: brew upgrade zoxide fzf fd bat lsd lazygit"
        # Skip installation - all tools are already present
        TOOLS_TO_INSTALL=()
    fi
fi

# Install tools via Homebrew if needed
if [ ${#TOOLS_TO_INSTALL[@]} -gt 0 ]; then
    echo "Tools to install: ${TOOLS_TO_INSTALL[*]}"
    echo ""
    
    # Separate tools into new installs and reinstalls
    TOOLS_NEW=()
    TOOLS_REINSTALL=()
    
    for tool in "${TOOLS_TO_INSTALL[@]}"; do
        # Check if tool is installed via Homebrew
        if brew list "$tool" &> /dev/null 2>&1; then
            TOOLS_REINSTALL+=("$tool")
        else
            TOOLS_NEW+=("$tool")
        fi
    done
    
    # Install new tools
    if [ ${#TOOLS_NEW[@]} -gt 0 ]; then
        echo "Installing new tools via Homebrew: ${TOOLS_NEW[*]}"
        if ! brew install "${TOOLS_NEW[@]}"; then
            echo "❌ Failed to install: ${TOOLS_NEW[*]}"
            exit 1
        fi
        echo "✓ Successfully installed: ${TOOLS_NEW[*]}"
    fi
    
    # Upgrade/reinstall existing tools
    if [ ${#TOOLS_REINSTALL[@]} -gt 0 ]; then
        echo "Upgrading existing tools: ${TOOLS_REINSTALL[*]}"
        # Use upgrade instead of install for already-installed tools
        # This handles the case where tools are already installed gracefully
        set +e  # Don't fail if upgrade says everything is up-to-date or has permission issues
        UPGRADE_OUTPUT=$(brew upgrade "${TOOLS_REINSTALL[@]}" 2>&1)
        UPGRADE_EXIT=$?
        set -e
        
        # Check if the error is just about everything being up-to-date
        if echo "$UPGRADE_OUTPUT" | grep -q "already installed and up-to-date"; then
            echo "✓ All tools are already up-to-date"
        elif [ $UPGRADE_EXIT -eq 0 ]; then
            echo "✓ Successfully upgraded: ${TOOLS_REINSTALL[*]}"
        elif echo "$UPGRADE_OUTPUT" | grep -q "not writable\|permission"; then
            echo "⚠️  Homebrew permission issue detected. Tools are already installed."
            echo "   To fix permissions, run: sudo chown -R $(whoami) $(brew --prefix)"
            echo "   Or continue - tools are already installed and functional."
        else
            echo "⚠️  Upgrade had some issues, but tools are already installed."
            echo "$UPGRADE_OUTPUT" | grep -v "already installed and up-to-date" || true
        fi
    fi
fi

# Install FZF keybindings (Homebrew installs fzf with keybindings)
if command -v fzf &> /dev/null; then
    # Check if keybindings are already in .zshrc
    if ! grep -q "fzf key-bindings" ~/.zshrc 2>/dev/null; then
        # Get fzf installation path
        FZF_SHELL=$(brew --prefix)/opt/fzf/shell
        if [ -f "$FZF_SHELL/key-bindings.zsh" ]; then
            echo ""
            echo "⚠️  FZF keybindings are available but not configured in .zshrc"
            echo "   To enable them, add this to your ~/.zshrc:"
            echo "   [ -f $FZF_SHELL/key-bindings.zsh ] && source $FZF_SHELL/key-bindings.zsh"
        fi
    else
        echo "✓ FZF keybindings configured"
    fi
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

