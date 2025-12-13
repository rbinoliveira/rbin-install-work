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

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║         🚀 Enterprise Scripts - Interactive Launcher 🚀         ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# ────────────────────────────────
# Installation Mode Selection
# ────────────────────────────────

select_installation_mode() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔧 Installation Mode Selection"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Choose the installation mode:"
    echo ""
    echo "  1) 🧠 Smart Mode - Installs only what's missing"
    echo "     Automatically skips tools that are already installed"
    echo ""
    echo "  2) 🎯 Interactive Mode - Manual selection"
    echo "     You choose what to install for each tool"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    while true; do
        read -p "Select mode [1/2] (default: 2): " -n 1 -r
        echo ""

        if [[ -z "$REPLY" ]] || [[ "$REPLY" == "2" ]]; then
            export INSTALL_MODE="interactive"
            echo ""
            echo "✓ Selected: Interactive Mode"
            echo ""
            break
        elif [[ "$REPLY" == "1" ]]; then
            export INSTALL_MODE="smart"
            echo ""
            echo "✓ Selected: Smart Mode"
            echo "  The script will automatically skip already installed tools."
            echo ""
            break
        else
            echo "❌ Invalid option. Please enter 1 or 2."
            echo ""
        fi
    done
}

select_installation_mode

# ────────────────────────────────
# Environment Variables Setup
# ────────────────────────────────

setup_environment_variables() {
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚙️  Environment Configuration"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check if .env exists, if not create empty file
    local env_file="$SCRIPT_DIR/.env"
    local env_example="$SCRIPT_DIR/.env.example"

    if [ ! -f "$env_file" ]; then
        echo "📝 Creating new .env file..."
        touch "$env_file"
        echo "✓ Created empty .env file"
        if [ -f "$env_example" ]; then
            echo ""
            echo "💡 Tip: You can use .env.example as a reference:"
            echo "   cat $env_example"
            echo ""
        fi
    fi

    # Show current .env file contents
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 Current .env file contents:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    if [ -s "$env_file" ]; then
        # Show contents with line numbers and highlight empty/commented lines
        local line_num=1
        while IFS= read -r line || [ -n "$line" ]; do
            if [[ "$line" =~ ^[[:space:]]*# ]]; then
                printf "  %3d: %s\n" "$line_num" "$line"
            elif [[ -z "${line// }" ]]; then
                printf "  %3d: (empty line)\n" "$line_num"
            else
                # Mask sensitive values (tokens, keys, etc)
                local masked_line="$line"
                if [[ "$line" =~ ^[[:space:]]*(GITHUB_TOKEN|AWS_.*_KEY|.*TOKEN|.*SECRET|.*PASSWORD)[[:space:]]*= ]]; then
                    masked_line=$(echo "$line" | sed 's/=.*/=***HIDDEN***/')
                fi
                printf "  %3d: %s\n" "$line_num" "$masked_line"
            fi
            ((line_num++))
        done < "$env_file"
    else
        echo "  (file is empty)"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Ask if user wants to continue with current .env or edit it
    local edited_env=false
    read -p "Is the .env file correct? Continue? [Y/n]: " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo ""
        echo "Opening .env file for editing..."
        echo "  File location: $env_file"
        echo ""

        # Try to use common editors
        if command -v nano &> /dev/null; then
            nano "$env_file"
        elif command -v vim &> /dev/null; then
            vim "$env_file"
        elif command -v vi &> /dev/null; then
            vi "$env_file"
        else
            echo "⚠️  No text editor found (nano, vim, vi)"
            echo "   Please edit the file manually: $env_file"
            echo ""
            read -p "Press Enter after editing the file..."
        fi

        echo ""
        echo "✓ .env file updated"
        echo ""
        edited_env=true
    else
        echo "✓ Continuing with current .env file"
        echo ""
    fi

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Checking required environment variables..."
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Variables that might be needed for installation
    local required_vars=(
        "GIT_USER_NAME:Your Git user name (for Git commits):true"
        "GIT_USER_EMAIL:Your Git user email (for Git commits):true"
    )


    # Check required variables
    for var_info in "${required_vars[@]}"; do
        IFS=':' read -r var_name prompt_text is_required <<< "$var_info"

        # Check if variable exists in .env
        local value
        if [ -f "$env_file" ]; then
            # Try to read from .env
            while IFS= read -r line || [ -n "$line" ]; do
                # Skip comments and empty lines
                [[ "$line" =~ ^[[:space:]]*# ]] && continue
                [[ -z "${line// }" ]] && continue

                # Check if this line matches our variable
                if [[ "$line" =~ ^[[:space:]]*${var_name}[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                    value="${BASH_REMATCH[1]}"
                    # Remove quotes if present
                    value="${value#\"}"
                    value="${value%\"}"
                    value="${value#\'}"
                    value="${value%\'}"
                    # Remove leading/trailing whitespace
                    value="${value#"${value%%[![:space:]]*}"}"
                    value="${value%"${value##*[![:space:]]}"}"
                    break
                fi
            done < "$env_file"
        fi

        # If not found or empty (after removing quotes and spaces), prompt user
        if [ -z "${value// }" ] || [ -z "$value" ]; then
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📝 Missing Required Variable: $var_name"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "$prompt_text"
            echo ""

            while true; do
                read -p "Enter value for $var_name: " user_input

                if [ -z "$user_input" ]; then
                    if [ "$is_required" = "true" ]; then
                        echo "❌ Error: $var_name is required and cannot be empty."
                        echo "   Please enter a value."
                        echo ""
                        continue
                    else
                        echo "⚠️  No value provided. Skipping..."
                        echo ""
                        break
                    fi
                else
                    # Save to .env
                    if grep -q "^[[:space:]]*${var_name}[[:space:]]*=" "$env_file" 2>/dev/null; then
                        # Update existing line
                        if [[ "$OSTYPE" == "darwin"* ]]; then
                            sed -i '' "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=\"${user_input}\"|" "$env_file"
                        else
                            sed -i "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=\"${user_input}\"|" "$env_file"
                        fi
                    else
                        # Append new line
                        echo "${var_name}=\"${user_input}\"" >> "$env_file"
                    fi

                    echo "✓ Saved $var_name to .env file"
                    echo ""
                    break
                fi
            done
        else
            echo "✓ Found $var_name in .env file (using existing value)"
        fi
    done


    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ Environment configuration complete"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Check for AWS Account variables
    check_aws_account_variables
}

# ────────────────────────────────
# Check AWS Account Variables
# ────────────────────────────────

check_aws_account_variables() {
    local env_file="$SCRIPT_DIR/.env"

    # Check if AWS account variables exist using library function
    if has_aws_account_variables "$env_file"; then
        return 0
    fi

    # If no AWS account variables found, suggest getting them
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "☁️  AWS Account Variables Not Found"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "No AWS account variables (AWS_ACCOUNT_*_ID) found in .env file."
    echo ""

    # Check if AWS config exists
    if [ -f "$HOME/.aws/config" ]; then
        echo "📋 We can extract AWS account information from your AWS configuration."
        echo ""

        read -p "Do you want to see your AWS variables now? [Y/n]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Nn]$ ]]; then
            echo ""
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo "📋 Your AWS Variables (copy and paste to .env):"
            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""

            # Use library function to get AWS variables
            get_aws_env_variables

            echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
            echo ""
            echo "💡 To add these to your .env file automatically, run:"
            echo "   get_aws_env_variables >> $env_file"
            echo ""

            read -p "Do you want to add these variables to .env now? [y/N]: " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                get_aws_env_variables >> "$env_file"
                echo "✓ AWS variables added to .env file"
            fi

            echo ""
            read -p "Press Enter to continue..."
        fi
    else
        echo "⚠️  AWS configuration file (~/.aws/config) not found."
        echo ""
        echo "To configure AWS SSO, run:"
        echo "   bash $SCRIPT_DIR/linux/scripts/enviroment/18-configure-aws-sso.sh"
        echo ""
        echo "Or for macOS:"
        echo "   bash $SCRIPT_DIR/macos/scripts/enviroment/18-configure-aws-sso.sh"
        echo ""
    fi
    echo ""
}

# Setup environment variables before installation
setup_environment_variables

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
# Run Installation Script
# ────────────────────────────────

INSTALL_SCRIPT="$SCRIPT_DIR/$PLATFORM/scripts/enviroment/00-install-all.sh"

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo "❌ Error: Installation script not found at $INSTALL_SCRIPT"
    exit 1
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
    echo "      bash $SCRIPT_DIR/$PLATFORM/scripts/enviroment/22-configure-github-token.sh"
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
