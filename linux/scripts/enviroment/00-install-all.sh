#!/usr/bin/env bash

set -e

# Check if running as root/sudo
if [ "$EUID" -eq 0 ] || [ "$(id -u)" -eq 0 ]; then
    echo "=============================================="
    echo "⚠️  WARNING: Running as root/sudo"
    echo "=============================================="
    echo ""
    echo "This script should NOT be run with sudo!"
    echo ""
    echo "Problems with running as root:"
    echo "  ❌ Configurations will be installed for root, not your user"
    echo "  ❌ Home directory will be /root instead of ~"
    echo "  ❌ Environment variables won't be preserved"
    echo "  ❌ .env file will be read as root"
    echo ""
    echo "The script will use sudo automatically when needed"
    echo "for specific operations (like installing system packages)."
    echo ""
    read -p "Do you want to continue anyway? (NOT RECOMMENDED) (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Exiting. Please run without sudo:"
        echo "  bash linux/scripts/enviroment/00-install-all.sh"
        exit 1
    fi
    echo ""
    echo "⚠️  Continuing as root (NOT RECOMMENDED)..."
    echo ""
fi

echo "=============================================="
echo "========= COMPLETE INSTALLATION =============="
echo "=============================================="
echo ""
echo "This script will install and configure your development environment."
echo ""

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Load environment variables from .env file if it exists
if [ -f "$ENV_FILE" ]; then
    echo "📝 Loading configuration from .env file..."
    # Source the .env file, ignoring comments and empty lines
    set -a
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Export the variable
        eval "export $line" 2>/dev/null || true
    done < "$ENV_FILE"
    set +a
    echo "✓ Configuration loaded from .env"
elif [ -f "$ENV_EXAMPLE" ]; then
    echo "📝 .env file not found. Creating from .env.example..."
    cp "$ENV_EXAMPLE" "$ENV_FILE"
    echo "✓ Created .env file from template"
    echo ""
    echo "⚠️  Please edit .env file with your information:"
    echo "   $ENV_FILE"
    echo ""
    echo "   Or run: bash setup-env.sh"
    echo ""
    read -p "Press Enter after editing .env file to continue, or Ctrl+C to cancel..."
    # Reload after user edits
    set -a
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Export the variable
        eval "export $line" 2>/dev/null || true
    done < "$ENV_FILE"
    set +a
fi

# Validate required configuration from .env
echo "📝 Validating configuration from .env file..."
echo ""

# Check Git user name
if [ -z "$GIT_USER_NAME" ] || [ "$GIT_USER_NAME" = "Your Name" ]; then
    echo "❌ GIT_USER_NAME is required in .env file"
    echo "   Please set GIT_USER_NAME in: $ENV_FILE"
    exit 1
fi

# Check Git email
if [ -z "$GIT_USER_EMAIL" ] || [ "$GIT_USER_EMAIL" = "your.email@example.com" ]; then
    echo "❌ GIT_USER_EMAIL is required in .env file"
    echo "   Please set GIT_USER_EMAIL in: $ENV_FILE"
    exit 1
fi

# GitHub token is optional, no validation needed

# Export variables for child scripts
export GIT_USER_NAME
export GIT_USER_EMAIL
export GITHUB_TOKEN

echo ""
echo "=============================================="
echo "Configuration summary:"
echo "  Git Name: $GIT_USER_NAME"
echo "  Git Email: $GIT_USER_EMAIL"
if [ -n "$GITHUB_TOKEN" ]; then
    echo "  GitHub Token: ${GITHUB_TOKEN:0:10}... (configured)"
else
    echo "  GitHub Token: (not configured)"
fi
echo "=============================================="
echo ""
echo "⚠️  ATTENTION:"
echo "   - After Docker installation (final step), you may need to"
echo "     logout/login to use Docker without sudo (Linux only)."
echo ""

# Part 1: Initial setup (01-02)
echo ""
echo "=============================================="
echo "PHASE 1: Initial Setup"
echo "=============================================="

echo ""
echo "Running script 01: configure-git.sh"
echo "=============================================="
bash "$SCRIPT_DIR/01-configure-git.sh"

echo ""
echo "Running script 02: install-zsh.sh"
echo "=============================================="
bash "$SCRIPT_DIR/02-install-zsh.sh"

echo ""
echo "=============================================="
echo "PHASE 2: Environment Configuration"
echo "=============================================="

# Part 2: Environment setup (03-04)
echo ""
echo "Running script 03: install-zinit.sh"
echo "=============================================="
bash "$SCRIPT_DIR/03-install-zinit.sh"

echo ""
echo "Running script 04: install-starship.sh"
echo "=============================================="
bash "$SCRIPT_DIR/04-install-starship.sh"

echo ""
echo "=============================================="
echo "PHASE 3: Development Tools"
echo "=============================================="

# Part 3: Development tools (05-08)
scripts=(
  "05-install-node-nvm.sh"
  "06-install-yarn.sh"
  "07-install-tools.sh"
  "08-install-font-jetbrains.sh"
)

for script in "${scripts[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Before each script, reload NVM if it exists
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo "❌ $script failed with exit code $EXIT_CODE"
    echo "⚠️  Continuing with next script..."
  fi
done

echo ""
echo "=============================================="
echo "PHASE 4: Application Setup"
echo "=============================================="

# Part 4: Applications and configuration
scripts=(
  "09-install-cursor.sh"
  "10-install-claude.sh"
  "10-configure-terminal.sh"
  "11-configure-ssh.sh"
  "12-configure-inotify.sh"
  "13-install-task-master.sh"
  "13-install-cursor-extensions.sh"
  "14-configure-cursor.sh"
  "15-install-docker.sh"
  "16-install-aws-vpn-client.sh"
  "17-install-aws-cli.sh"
  "18-configure-aws-sso.sh"
  "19-install-dotnet.sh"
  "20-install-java.sh"
  "21-configure-github-token.sh"
  "22-install-insomnia.sh"
  "23-install-heidisql.sh"
)

for script in "${scripts[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Before each script, reload NVM if it exists
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo "❌ $script failed with exit code $EXIT_CODE"
    echo "⚠️  Continuing with next script..."
  fi
done

echo ""
echo "=============================================="
echo "🎉 INSTALLATION COMPLETE!"
echo "=============================================="
echo "All scripts have been executed successfully!"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Close and reopen your terminal to ensure"
echo "     all configurations are loaded."
echo "   - On Linux: You may need to logout/login to"
echo "     use Docker without sudo."
echo ""
echo "After restarting, verify installations:"
echo "  node -v"
echo "  yarn -v"
echo "  docker --version"
echo ""
