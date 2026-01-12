#!/usr/bin/env bash

#
# Tool Installation Module
#
# Handles installation of Claude Code and Cursor configuration.
#
# Usage:
#   source lib/install_tools.sh
#   install_all_tools
#

set -eo pipefail

# Ensure required modules are available
if [ -z "$PLATFORM" ]; then
    echo "ERROR: Platform detection must be sourced before install tools" >&2
    return 1 2>/dev/null || exit 1
fi

# ────────────────────────────────────────────────────────────────
# Configuration
# ────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────
# Installation Functions
# ────────────────────────────────────────────────────────────────

install_node_npm() {
    echo ""
    echo "Checking Node.js and npm..."

    if command -v node >/dev/null 2>&1 && command -v npm >/dev/null 2>&1; then
        local node_version
        node_version=$(node --version)
        echo "✓ Node.js is installed: $node_version"
        log_info "Node.js already installed: $node_version"
        return 0
    fi

    echo "Node.js not found. Installing..."
    log_info "Installing Node.js"

    if is_macos; then
        if command -v brew >/dev/null 2>&1; then
            brew install node
        else
            echo "ERROR: Homebrew not found. Please install Homebrew first: https://brew.sh/"
            log_error "Homebrew not found, cannot install Node.js"
            return 1
        fi
    elif is_linux; then
        if has_package_manager; then
            case "$PKG_MANAGER" in
                apt-get)
                    sudo apt-get update
                    sudo apt-get install -y nodejs npm
                    ;;
                dnf)
                    sudo dnf install -y nodejs npm
                    ;;
                yum)
                    sudo yum install -y nodejs npm
                    ;;
            esac
        else
            echo "ERROR: No supported package manager found"
            log_error "No package manager found, cannot install Node.js"
            return 1
        fi
    fi

    echo "✓ Node.js installed successfully"
    log_info "Node.js installed successfully"
}

install_claude() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Installing Claude Code CLI"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if already installed
    if [ "$CLAUDE_INSTALLED" = "true" ]; then
        if ! prompt_reinstall_if_needed "Claude Code" "CLAUDE_INSTALLED" "CLAUDE_VERSION"; then
            return 0
        fi
    fi

    # Install via npm
    echo "Installing @anthropic-ai/claude-code via npm..."
    log_info "Installing Claude Code CLI"

    if npm install -g @anthropic-ai/claude-code; then
        echo "✓ Claude Code CLI installed successfully"
        log_info "Claude Code CLI installed successfully"
        return 0
    else
        echo "✗ Failed to install Claude Code CLI"
        log_error "Failed to install Claude Code CLI"
        return 1
    fi
}

configure_cursor() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Configuring Cursor IDE"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    # Check if Cursor is installed
    if [ "$CURSOR_INSTALLED" != "true" ]; then
        echo "ℹ️  Cursor IDE is not installed on this system."
        echo ""
        echo "To install Cursor:"
        echo "  1. Visit https://cursor.sh/"
        echo "  2. Download and install for your platform"
        echo "  3. Re-run this script to configure"
        echo ""
        log_info "Cursor not installed, skipping configuration"
        return 0
    fi

    echo "✓ Cursor IDE detected"
    echo ""

    log_info "Cursor detected, user should configure via Cursor settings"
    return 0
}

# ────────────────────────────────────────────────────────────────
# Main Installation Function
# ────────────────────────────────────────────────────────────────

install_all_tools() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📦 Install Development Tools"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "This will install and configure:"
    echo "  • Node.js and npm (if not already installed)"
    echo "  • Claude Code CLI"
    echo "  • Cursor IDE configuration"
    echo ""

    if [ "$FORCE_MODE" = false ]; then
        read -p "Continue with installation? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Installation cancelled."
            log_info "User cancelled installation"
            return 0
        fi
    fi

    log_info "Starting tool installation"

    # Track results
    local node_success=false
    local claude_success=false
    local cursor_configured=false

    # Install Node.js/npm first
    if install_node_npm; then
        node_success=true
    fi

    # Run tool detection to get current state
    detect_all_tools

    # Install Claude
    if install_claude; then
        claude_success=true
    fi

    # Configure Cursor
    if configure_cursor; then
        cursor_configured=true
    fi

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Installation Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ "$node_success" = true ]; then
        echo "✓ Node.js and npm"
    else
        echo "✗ Node.js and npm (failed or skipped)"
    fi

    if [ "$claude_success" = true ]; then
        echo "✓ Claude Code CLI"
    else
        echo "✗ Claude Code CLI (failed or skipped)"
    fi

    if [ "$cursor_configured" = true ]; then
        echo "ℹ️  Cursor IDE (configure via Cursor settings)"
    else
        echo "ℹ️  Cursor IDE (not installed or skipped)"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

    log_info "Installation completed"
}

# Export functions
export -f install_node_npm
export -f install_claude
export -f configure_cursor
export -f install_all_tools
