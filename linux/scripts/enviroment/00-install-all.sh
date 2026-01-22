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
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Load check_installed functions
if [ -f "$PROJECT_ROOT/lib/check_installed.sh" ]; then
    source "$PROJECT_ROOT/lib/check_installed.sh"
fi

# Load apt helper functions
if [ -f "$PROJECT_ROOT/lib/apt_helper.sh" ]; then
    source "$PROJECT_ROOT/lib/apt_helper.sh"
fi

# Load environment validator library
if [ -f "$PROJECT_ROOT/lib/env_validator.sh" ]; then
    source "$PROJECT_ROOT/lib/env_validator.sh"
else
    echo "❌ Error: env_validator.sh library not found!"
    echo "   Expected location: $PROJECT_ROOT/lib/env_validator.sh"
    exit 1
fi

# Validate and collect required environment variables
if ! validate_required_env_variables "$ENV_FILE" "$ENV_EXAMPLE"; then
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ Environment validation failed!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Installation cannot proceed without required variables."
    echo "Please check your .env file: $ENV_FILE"
    echo ""
    exit 1
fi

# Load environment variables
load_env_file "$ENV_FILE"

# Export variables for child scripts
export GIT_USER_NAME
export GIT_USER_EMAIL
export GITHUB_TOKEN
export AWS_SSO_START_URL
export AWS_SSO_REGION
export INSTALL_ALL_RUNNING=1

# Part 1: Initial setup (01-02)
echo ""
echo "=============================================="
echo "PHASE 1: Initial Setup"
echo "=============================================="

scripts_phase1=(
  "01-configure-git.sh"
  "02-install-zsh.sh"
)

for script in "${scripts_phase1[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Handle different installation actions
  if [ "$INSTALL_ACTION" = "select" ]; then
    # Convert SELECTED_SCRIPTS string to array
    if [ -n "$SELECTED_SCRIPTS" ]; then
      IFS=' ' read -ra SELECTED_ARRAY <<< "$SELECTED_SCRIPTS"
    else
      SELECTED_ARRAY=()
    fi
    # Check if this script is in the selected list
    script_selected=false
    for selected in "${SELECTED_ARRAY[@]}"; do
      if [ "$selected" = "$script" ]; then
        script_selected=true
        break
      fi
    done
    if [ "$script_selected" = false ]; then
      echo "⏭️  Skipping $script (not selected)"
      continue
    fi
  elif [ "$INSTALL_ACTION" = "smart" ]; then
    # Smart mode: check if already installed
    if check_script_installed "$script"; then
      echo "✓ $script is already installed/configured. Skipping..."
      continue
    fi
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    # Reinstall all: force reinstall
    echo "🔄 Reinstalling $script..."
  fi

  # In smart mode, don't ask - just install automatically
  if [ "$INSTALL_ACTION" = "smart" ]; then
    echo "Installing/running $script (smart mode - automatic)..."
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    echo "Installing/running $script (reinstall mode)..."
  elif [ "$INSTALL_ACTION" = "select" ]; then
    # For select mode, ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  else
    # Default: ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  fi

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
  fi
done

echo ""
echo "=============================================="
echo "PHASE 2: Environment Configuration"
echo "=============================================="

# Part 2: Environment setup (03-04)
scripts_phase2=(
  "03-install-zinit.sh"
  "04-install-starship.sh"
)

for script in "${scripts_phase2[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Handle different installation actions
  if [ "$INSTALL_ACTION" = "select" ]; then
    # Convert SELECTED_SCRIPTS string to array
    if [ -n "$SELECTED_SCRIPTS" ]; then
      IFS=' ' read -ra SELECTED_ARRAY <<< "$SELECTED_SCRIPTS"
    else
      SELECTED_ARRAY=()
    fi
    # Check if this script is in the selected list
    script_selected=false
    for selected in "${SELECTED_ARRAY[@]}"; do
      if [ "$selected" = "$script" ]; then
        script_selected=true
        break
      fi
    done
    if [ "$script_selected" = false ]; then
      echo "⏭️  Skipping $script (not selected)"
      continue
    fi
  elif [ "$INSTALL_ACTION" = "smart" ]; then
    # Smart mode: check if already installed
    if check_script_installed "$script"; then
      echo "✓ $script is already installed/configured. Skipping..."
      continue
    fi
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    # Reinstall all: force reinstall
    echo "🔄 Reinstalling $script..."
  fi

  # In smart mode, don't ask - just install automatically
  if [ "$INSTALL_ACTION" = "smart" ]; then
    echo "Installing/running $script (smart mode - automatic)..."
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    echo "Installing/running $script (reinstall mode)..."
  elif [ "$INSTALL_ACTION" = "select" ]; then
    # For select mode, ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  else
    # Default: ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  fi

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
  fi
done

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

  # Handle different installation actions
  if [ "$INSTALL_ACTION" = "select" ]; then
    # Convert SELECTED_SCRIPTS string to array
    if [ -n "$SELECTED_SCRIPTS" ]; then
      IFS=' ' read -ra SELECTED_ARRAY <<< "$SELECTED_SCRIPTS"
    else
      SELECTED_ARRAY=()
    fi
    # Check if this script is in the selected list
    script_selected=false
    for selected in "${SELECTED_ARRAY[@]}"; do
      if [ "$selected" = "$script" ]; then
        script_selected=true
        break
      fi
    done
    if [ "$script_selected" = false ]; then
      echo "⏭️  Skipping $script (not selected)"
      continue
    fi
  elif [ "$INSTALL_ACTION" = "smart" ]; then
    # Smart mode: check if already installed
    if check_script_installed "$script"; then
      echo "✓ $script is already installed/configured. Skipping..."
      continue
    fi
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    # Reinstall all: force reinstall
    echo "🔄 Reinstalling $script..."
  fi

  # In smart mode, don't ask - just install automatically
  if [ "$INSTALL_ACTION" = "smart" ]; then
    echo "Installing/running $script (smart mode - automatic)..."
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    echo "Installing/running $script (reinstall mode)..."
  elif [ "$INSTALL_ACTION" = "select" ]; then
    # For select mode, ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  else
    # Default: ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  fi

  # Before each script, reload NVM if it exists
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
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
  "11-configure-terminal.sh"
  "12-configure-ssh.sh"
  "13-configure-inotify.sh"
  "14-configure-cursor.sh"
  "15-install-docker.sh"
  "16-install-aws-vpn-client.sh"
  "17-install-aws-cli.sh"
  "18-configure-aws-sso.sh"
  "19-install-dotnet.sh"
  "20-install-java.sh"
  "21-configure-github-token.sh"
  "22-install-insomnia.sh"
  "23-install-tableplus.sh"
)

for script in "${scripts[@]}"; do
  echo ""
  echo "Running: $script"
  echo "=============================================="

  # Handle different installation actions
  if [ "$INSTALL_ACTION" = "select" ]; then
    # Convert SELECTED_SCRIPTS string to array
    if [ -n "$SELECTED_SCRIPTS" ]; then
      IFS=' ' read -ra SELECTED_ARRAY <<< "$SELECTED_SCRIPTS"
    else
      SELECTED_ARRAY=()
    fi
    # Check if this script is in the selected list
    script_selected=false
    for selected in "${SELECTED_ARRAY[@]}"; do
      if [ "$selected" = "$script" ]; then
        script_selected=true
        break
      fi
    done
    if [ "$script_selected" = false ]; then
      echo "⏭️  Skipping $script (not selected)"
      continue
    fi
  elif [ "$INSTALL_ACTION" = "smart" ]; then
    # Smart mode: check if already installed
    if check_script_installed "$script"; then
      echo "✓ $script is already installed/configured. Skipping..."
      continue
    fi
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    # Reinstall all: force reinstall
    echo "🔄 Reinstalling $script..."
  fi

  # In smart mode, don't ask - just install automatically
  if [ "$INSTALL_ACTION" = "smart" ]; then
    echo "Installing/running $script (smart mode - automatic)..."
  elif [ "$INSTALL_ACTION" = "reinstall" ]; then
    echo "Installing/running $script (reinstall mode)..."
  elif [ "$INSTALL_ACTION" = "select" ]; then
    # For select mode, ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  else
    # Default: ask user
    if [ -t 0 ]; then
      read -p "Do you want to install/run $script? [Y/n]: " -n 1 -r
      echo ""
      if [[ $REPLY =~ ^[Nn]$ ]]; then
        echo "Skipping $script"
        continue
      else
        echo "Installing/running $script..."
      fi
    else
      echo "Installing/running $script (non-interactive mode)..."
    fi
  fi

  # Before each script, reload NVM if it exists
  export NVM_DIR="$HOME/.nvm"
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" || true

  if bash "$SCRIPT_DIR/$script"; then
    echo "✓ $script completed successfully"
  else
    EXIT_CODE=$?
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "❌ INSTALLATION FAILED"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Script: $script"
    echo "Exit code: $EXIT_CODE"
    echo ""
    echo "Installation stopped due to error."
    echo "Please fix the issue and run the installation again:"
    echo "  bash $SCRIPT_DIR/00-install-all.sh"
    echo ""
    exit $EXIT_CODE
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
