#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load platform detection library (must be first)
if [ -f "$SCRIPT_DIR/lib/platform.sh" ]; then
    source "$SCRIPT_DIR/lib/platform.sh"
fi

# Load AWS helper library
if [ -f "$SCRIPT_DIR/lib/aws_helper.sh" ]; then
    source "$SCRIPT_DIR/lib/aws_helper.sh"
fi

# Load check_installed functions
if [ -f "$SCRIPT_DIR/lib/check_installed.sh" ]; then
    source "$SCRIPT_DIR/lib/check_installed.sh"
fi

# Load environment validator library
if [ -f "$SCRIPT_DIR/lib/env_validator.sh" ]; then
    source "$SCRIPT_DIR/lib/env_validator.sh"
fi

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🚀 Enterprise Scripts - Interactive Launcher 🚀         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ────────────────────────────────
# Installation Action Selection (First Menu)
# ────────────────────────────────

select_installation_action() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🚀 Installation Action Selection"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Choose what you want to do:"
    echo ""
    echo "  1) 🧠 Smart Install"
    echo "     Installs only what's missing"
    echo "     Automatically skips tools that are already installed"
    echo ""
    echo "  2) 🔄 Reinstall All"
    echo "     Reinstalls everything from scratch"
    echo "     Useful for updating or fixing issues"
    echo ""
    echo "  3) 🎯 Select What to Run"
    echo "     Choose specific scripts to run"
    echo "     You'll see a list and select by number (e.g., 1,2,3)"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    while true; do
        read -p "Select action [1/2/3] (default: 1): " -n 1 -r
        echo ""

        if [[ -z "$REPLY" ]] || [[ "$REPLY" == "1" ]]; then
            export INSTALL_ACTION="smart"
            export INSTALL_MODE="smart"
            echo ""
            echo "✓ Selected: Smart Install"
            echo ""
            break
        elif [[ "$REPLY" == "2" ]]; then
            export INSTALL_ACTION="reinstall"
            export INSTALL_MODE="interactive"
            echo ""
            echo "✓ Selected: Reinstall All"
            echo ""
            break
        elif [[ "$REPLY" == "3" ]]; then
            export INSTALL_ACTION="select"
            export INSTALL_MODE="interactive"
            echo ""
            echo "✓ Selected: Select What to Run"
            echo ""
            break
        else
            echo "❌ Invalid option. Please enter 1, 2, or 3."
            echo ""
        fi
    done
}

select_installation_action

# ────────────────────────────────
# Request Sudo Password Once
# ────────────────────────────────

request_sudo_password() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔐 Administrator Password Required"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Some installation steps require administrator privileges."
    echo "Please enter your password once. It will be cached for this session."
    echo ""
    
    # Request sudo password and cache it
    sudo -v
    
    # Keep sudo alive by refreshing it every 5 minutes in background
    (while true; do
        sleep 300
        sudo -n true 2>/dev/null || exit 1
    done) &
    
    echo "✓ Administrator privileges granted"
    echo ""
}

# Request sudo password once at the beginning
request_sudo_password

# ────────────────────────────────
# Complete Environment Variables Setup
# ────────────────────────────────

setup_complete_environment() {
    local env_file="$SCRIPT_DIR/.env"
    local env_example="$SCRIPT_DIR/.env.example"

    # Use the shared validation library
    if ! validate_required_env_variables "$env_file" "$env_example"; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "❌ Environment validation failed!"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Installation cannot proceed without required variables."
        echo "Please check your .env file: $env_file"
        echo ""
        exit 1
    fi

    # Load environment variables
    load_env_file "$env_file"
}

# Setup complete environment before installation
setup_complete_environment

# ────────────────────────────────
# Platform Detection
# ────────────────────────────────

# Platform is automatically detected by platform.sh
# Verify that detected platform is supported
if [ "$PLATFORM" != "linux" ] && [ "$PLATFORM" != "macos" ]; then
    echo "❌ Error: Unsupported platform detected: $PLATFORM"
    echo "   This script only supports Linux and macOS."
    exit 1
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🖥️  Platform Detected"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
print_platform_info
echo ""


# ────────────────────────────────
# Get All Available Scripts
# ────────────────────────────────

get_all_scripts() {
    local platform_dir="$SCRIPT_DIR/$PLATFORM/scripts/enviroment"
    local scripts=()
    
    # Get all scripts from 00-install-all.sh by extracting from script arrays
    if [ -f "$platform_dir/00-install-all.sh" ]; then
        # Extract all script names from arrays (scripts_phase1, scripts_phase2, scripts)
        while IFS= read -r line; do
            # Match lines like: "01-configure-git.sh" or "09-install-cursor.sh"
            if [[ "$line" =~ \"([0-9]+-[^\"]+\.sh)\" ]]; then
                scripts+=("${BASH_REMATCH[1]}")
            fi
        done < <(grep -E '^[[:space:]]+"[0-9]+-.*\.sh"' "$platform_dir/00-install-all.sh")
    fi
    
    # If no scripts found, try to list files directly
    if [ ${#scripts[@]} -eq 0 ]; then
        for script in "$platform_dir"/*.sh; do
            if [ -f "$script" ]; then
                local basename_script=$(basename "$script")
                if [[ "$basename_script" =~ ^[0-9]+- ]]; then
                    scripts+=("$basename_script")
                fi
            fi
        done
    fi
    
    # Remove duplicates and sort
    local unique_scripts=($(printf '%s\n' "${scripts[@]}" | sort -u))
    
    # Output as space-separated string
    echo "${unique_scripts[@]}"
}

# ────────────────────────────────
# Select Scripts to Run
# ────────────────────────────────

select_scripts_to_run() {
    local platform_dir="$SCRIPT_DIR/$PLATFORM/scripts/enviroment"
    local all_scripts=($(get_all_scripts))
    local selected_scripts=()
    
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Available Scripts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    local index=1
    for script in "${all_scripts[@]}"; do
        local script_name=$(echo "$script" | sed 's/^[0-9]*-//;s/\.sh$//' | tr '-' ' ' | sed 's/\b\(.\)/\u\1/g')
        printf "  %2d) %s\n" "$index" "$script"
        ((index++))
    done
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Enter the numbers of scripts you want to run, separated by commas."
    echo "Example: 1,2,3 or 1,5,10"
    echo ""
    
    while true; do
        read -p "Select scripts: " user_input
        echo ""
        
        if [ -z "$user_input" ]; then
            echo "❌ Please enter at least one script number."
            echo ""
            continue
        fi
        
        # Parse comma-separated numbers
        local valid_selection=true
        IFS=',' read -ra numbers <<< "$user_input"
        
        for num in "${numbers[@]}"; do
            # Remove whitespace
            num=$(echo "$num" | tr -d '[:space:]')
            
            # Check if it's a valid number
            if ! [[ "$num" =~ ^[0-9]+$ ]]; then
                echo "❌ Invalid number: $num"
                valid_selection=false
                continue
            fi
            
            # Check if number is in range
            if [ "$num" -lt 1 ] || [ "$num" -gt ${#all_scripts[@]} ]; then
                echo "❌ Number $num is out of range (1-${#all_scripts[@]})"
                valid_selection=false
                continue
            fi
            
            # Add to selected scripts (convert to 0-based index)
            local script_index=$((num - 1))
            selected_scripts+=("${all_scripts[$script_index]}")
        done
        
        if [ "$valid_selection" = true ] && [ ${#selected_scripts[@]} -gt 0 ]; then
            break
        else
            echo "Please try again."
            echo ""
            selected_scripts=()
        fi
    done
    
    # Export selected scripts as space-separated string (will be converted to array in install script)
    export SELECTED_SCRIPTS="${selected_scripts[*]}"
    
    echo "✓ Selected scripts:"
    for script in "${selected_scripts[@]}"; do
        echo "   - $script"
    done
    echo ""
}

# ────────────────────────────────
# Run Installation Based on Action
# ────────────────────────────────

INSTALL_SCRIPT="$SCRIPT_DIR/$PLATFORM/scripts/enviroment/00-install-all.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "❌ Error: Installation script not found at $INSTALL_SCRIPT"
    exit 1
fi

# Export action for the install script
export INSTALL_ACTION

# Handle different actions
if [ "$INSTALL_ACTION" = "select" ]; then
    select_scripts_to_run
    export SELECTED_SCRIPTS
elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    export FORCE_REINSTALL=true
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🚀 Starting Installation for $PLATFORM_NAME"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Run the installation script
cd "$(dirname "$INSTALL_SCRIPT")"
bash "$INSTALL_SCRIPT"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Installation completed!"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ────────────────────────────────
# Populate AWS Accounts After Installation
# ────────────────────────────────

# Try to populate AWS accounts if AWS was configured
if [ -f "$SCRIPT_DIR/.env" ]; then
    populate_aws_accounts "$SCRIPT_DIR/.env"
fi

# ────────────────────────────────
# Final Instructions
# ────────────────────────────────

print_final_instructions() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Next Steps - Important Instructions"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # 1. Restart Terminal
    echo "1️⃣  RESTART YOUR TERMINAL"
    echo "   ⚠️  This is REQUIRED for all configurations to take effect!"
    echo "   → Close this terminal window completely"
    echo "   → Open a new terminal window"
    echo "   → Or run: source ~/.zshrc"
    echo ""

    # 2. SSH Key Configuration
    if [ -f "$HOME/.ssh/id_ed25519.pub" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "2️⃣  CONFIGURE SSH KEY ON GITHUB"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "   ✅ Your SSH public key has been generated!"
        echo ""
        echo "   📋 Your SSH Public Key:"
        echo "   ────────────────────────────────────────────────────────────"
        cat "$HOME/.ssh/id_ed25519.pub" | sed 's/^/   /'
        echo "   ────────────────────────────────────────────────────────────"
        echo ""
        echo "   📝 Steps to add it to GitHub:"
        echo ""
        echo "   1. Copy your SSH public key (command below):"
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "      cat ~/.ssh/id_ed25519.pub | pbcopy"
        else
            echo "      cat ~/.ssh/id_ed25519.pub | xclip -sel clip"
            echo "      (or manually copy the key shown above)"
        fi
        echo ""
        echo "   2. Go to GitHub Settings:"
        echo "      https://github.com/settings/keys"
        echo ""
        echo "   3. Click 'New SSH key'"
        echo ""
        echo "   4. Add a title (e.g., 'My Development Machine')"
        echo ""
        echo "   5. Paste your public key and click 'Add SSH key'"
        echo ""
        echo "   ✅ Test SSH connection (after adding to GitHub):"
        echo "      ssh -T git@github.com"
        echo ""
        echo "   💡 Expected output: 'Hi username! You've successfully authenticated...'"
        echo ""
    else
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "2️⃣  CONFIGURE SSH KEY (Optional)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "   If you need to configure SSH for GitHub, run:"
        echo "   bash $SCRIPT_DIR/$PLATFORM/scripts/enviroment/12-configure-ssh.sh"
        echo ""
    fi

    # 3. GitHub Token
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "3️⃣  GITHUB TOKEN (For Private Repositories)"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   If you need access to private GitHub repositories:"
    echo ""
    echo "   1. Generate a token:"
    echo "      https://github.com/settings/tokens"
    echo ""
    echo "   2. Click 'Generate new token' → 'Generate new token (classic)'"
    echo ""
    echo "   3. Select scope: 'repo' (for private repositories)"
    echo ""
    echo "   4. Configure it:"
    echo "      bash $SCRIPT_DIR/$PLATFORM/scripts/enviroment/21-configure-github-token.sh"
    echo ""
    echo "   Or add manually to ~/.zshrc:"
    echo "      export GITHUB_TOKEN=your_token_here"
    echo ""

    # 4. AWS SSO Configuration
    if [ -f "$SCRIPT_DIR/.env" ]; then
        if grep -q "AWS_SSO_START_URL" "$SCRIPT_DIR/.env" 2>/dev/null; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "4️⃣  AWS SSO CONFIGURATION"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "   Your AWS SSO is configured. To login:"
            echo ""
            echo "   aws sso login"
            echo ""
            echo "   📝 Verify AWS configuration:"
            echo "      aws sts get-caller-identity"
            echo ""
        fi
    fi

    # 5. Docker (Linux specific)
    if [ "$PLATFORM" = "linux" ]; then
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "5️⃣  DOCKER CONFIGURATION (Linux)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "   ⚠️  To use Docker without sudo, you need to:"
        echo "      → Logout and login again"
        echo "      → Or restart your session"
        echo ""
        echo "   ✅ Verify Docker:"
        echo "      docker --version"
        echo "      docker ps"
        echo ""
    fi

    # 6. Verify Installations
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "6️⃣  VERIFY INSTALLATIONS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   After restarting your terminal, verify:"
    echo ""
    echo "   # Git"
    echo "   git --version"
    echo "   git config --global user.name"
    echo "   git config --global user.email"
    echo ""
    echo "   # Node.js & Yarn"
    echo "   node -v"
    echo "   npm -v"
    echo "   yarn -v"
    echo ""
    echo "   # Shell & Tools"
    echo "   zsh --version"
    echo "   starship --version"
    echo "   nvm --version"
    echo ""
    if [ "$PLATFORM" = "linux" ]; then
        echo "   # Docker"
        echo "   docker --version"
        echo ""
    fi
    echo "   # AWS CLI"
    echo "   aws --version"
    echo ""

    # 7. Additional Resources
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "7️⃣  ADDITIONAL RESOURCES"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   📚 Documentation:"
    echo "      See README.md for detailed information"
    echo ""
    echo "   🔧 Troubleshooting:"
    echo "      - If tools are not found, restart terminal"
    echo "      - Check ~/.zshrc for environment variables"
    echo "      - Verify .env file configuration"
    echo ""
    echo "   💡 Tips:"
    echo "      - Use 'nvm use 22' to activate Node.js 22"
    echo "      - Starship prompt will appear after restart"
    echo "      - Zinit plugins load automatically"
    echo ""

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🎉 Setup Complete!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "   Remember: RESTART YOUR TERMINAL before continuing!"
    echo ""
}

print_final_instructions
