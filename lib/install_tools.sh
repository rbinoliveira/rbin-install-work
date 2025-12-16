#!/usr/bin/env bash

#
# Tool Installation Module
#
# Handles installation of Claude Code and Cursor configuration
# with API key prompts and validation.
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

export ENV_FILE=".env"
export ENV_EXAMPLE=".env.example"

# ────────────────────────────────────────────────────────────────
# API Key Management
# ────────────────────────────────────────────────────────────────

prompt_api_key() {
    local key_name="$1"
    local description="$2"
    local url="$3"
    local format_hint="$4"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "API Key Required: $description"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Get your API key from: $url"
    echo "Format: $format_hint"
    echo ""

    if [ "$FORCE_MODE" = true ]; then
        echo "Force mode: Skipping API key prompt"
        return 1
    fi

    read -p "Enter your $description (or press Enter to skip): " -r api_key

    if [ -z "$api_key" ]; then
        echo "Skipped."
        return 1
    fi

    echo "$api_key"
    return 0
}

validate_anthropic_key() {
    local key="$1"

    # Basic format validation
    if [[ ! "$key" =~ ^sk-ant- ]]; then
        echo "ERROR: Invalid Anthropic API key format. Should start with 'sk-ant-'" >&2
        return 1
    fi

    return 0
}

create_or_update_env() {
    local key_name="$1"
    local key_value="$2"

    # Create .env from example if it doesn't exist
    if [ ! -f "$ENV_FILE" ]; then
        if [ -f "$ENV_EXAMPLE" ]; then
            cp "$ENV_EXAMPLE" "$ENV_FILE"
            chmod 600 "$ENV_FILE"
            echo "✓ Created $ENV_FILE from $ENV_EXAMPLE"
        else
            touch "$ENV_FILE"
            chmod 600 "$ENV_FILE"
            echo "✓ Created new $ENV_FILE"
        fi
    fi

    # Update or add the key
    if grep -q "^${key_name}=" "$ENV_FILE"; then
        # Update existing key
        if is_macos; then
            sed -i '' "s|^${key_name}=.*|${key_name}=${key_value}|" "$ENV_FILE"
        else
            sed -i "s|^${key_name}=.*|${key_name}=${key_value}|" "$ENV_FILE"
        fi
        echo "✓ Updated $key_name in $ENV_FILE"
    else
        # Add new key
        echo "${key_name}=${key_value}" >> "$ENV_FILE"
        echo "✓ Added $key_name to $ENV_FILE"
    fi

    log_info "Updated $key_name in $ENV_FILE"
}

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

    # Prompt for API key
    local api_key
    if api_key=$(prompt_api_key "ANTHROPIC_API_KEY" \
                                "Anthropic API Key" \
                                "https://console.anthropic.com/settings/keys" \
                                "Starts with 'sk-ant-'"); then

        # Validate key format
        if validate_anthropic_key "$api_key"; then
            # Store in .env
            create_or_update_env "ANTHROPIC_API_KEY" "$api_key"
        else
            echo "Skipping Claude installation due to invalid API key"
            return 1
        fi
    else
        echo "Skipping Claude installation (no API key provided)"
        log_info "Skipped Claude installation - no API key"
        return 0
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
    echo "Cursor configuration:"
    echo "  • API keys can be configured in Cursor's AI settings"
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

    if [ -f "$ENV_FILE" ]; then
        echo ""
        echo "Configuration saved to: $ENV_FILE"
        echo "Verify your API keys are correct before using the tools."
        echo ""
    fi

    log_info "Installation completed"
}

# Export functions
export -f prompt_api_key
export -f validate_anthropic_key
export -f create_or_update_env
export -f install_node_npm
export -f install_claude
export -f configure_cursor
export -f install_all_tools
