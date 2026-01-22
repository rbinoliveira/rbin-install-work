#!/usr/bin/env bash

# ────────────────────────────────────────────────────────────────────────────────
# Environment Variables Validator Library
# ────────────────────────────────────────────────────────────────────────────────
# This library provides functions to validate and collect required environment
# variables from the .env file before any installation begins.
# ────────────────────────────────────────────────────────────────────────────────

# Function to get variable value from .env
get_var_from_env() {
    local var_name="$1"
    local env_file="$2"
    local value=""

    if [ -f "$env_file" ]; then
        while IFS= read -r line || [ -n "$line" ]; do
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue

            if [[ "$line" =~ ^[[:space:]]*${var_name}[[:space:]]*=[[:space:]]*(.+)$ ]]; then
                value="${BASH_REMATCH[1]}"
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
                value="${value#"${value%%[![:space:]]*}"}"
                value="${value%"${value##*[![:space:]]}"}"
                break
            fi
        done < "$env_file"
    fi

    echo "$value"
}

# Function to save variable to .env
save_var_to_env() {
    local var_name="$1"
    local var_value="$2"
    local env_file="$3"

    if grep -q "^[[:space:]]*${var_name}[[:space:]]*=" "$env_file" 2>/dev/null; then
        # Update existing line
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=\"${var_value}\"|" "$env_file"
        else
            sed -i "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=\"${var_value}\"|" "$env_file"
        fi
    else
        # Append new line
        echo "${var_name}=\"${var_value}\"" >> "$env_file"
    fi
}

# Function to validate if a value is acceptable (not empty, not placeholder)
is_valid_value() {
    local value="$1"

    # Check if empty
    if [ -z "$value" ]; then
        return 1
    fi

    # Check if it's a placeholder value
    case "$value" in
        "Your Name"|"your.email@example.com"|"https://your-org.awsapps.com/start"|"required"|"optional")
            return 1
            ;;
    esac

    return 0
}

# Function to prompt user for a variable value
prompt_for_variable() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="$3"
    local env_file="$4"

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📝 Required Variable: $var_name"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "$prompt_text"
    echo ""

    while true; do
        if [ -n "$default_value" ]; then
            read -p "Enter value for $var_name [$default_value]: " user_input
            user_input="${user_input:-$default_value}"
        else
            read -p "Enter value for $var_name: " user_input
        fi

        if ! is_valid_value "$user_input"; then
            echo "❌ Error: $var_name is required and cannot be empty or a placeholder value."
            echo "   Please enter a valid value."
            echo ""
            continue
        fi

        # Save to .env
        save_var_to_env "$var_name" "$user_input" "$env_file"
        echo "✓ Saved $var_name to .env file"
        echo ""
        break
    done
}

# Main validation function
validate_required_env_variables() {
    local env_file="$1"
    local env_example="$2"

    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚙️  Environment Variables Validation"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📝 Checking required environment variables..."
    echo "   Installation will NOT proceed until all required variables are set."
    echo ""

    # Create .env file if it doesn't exist
    if [ ! -f "$env_file" ]; then
        echo "📝 Creating new .env file..."
        if [ -f "$env_example" ]; then
            cp "$env_example" "$env_file"
            echo "✓ Created .env file from .env.example"
        else
            touch "$env_file"
            echo "✓ Created empty .env file"
        fi
        echo ""
    fi

    # Define required variables
    # Format: "VAR_NAME:Prompt Text:default_value"
    # All these variables are REQUIRED for the installation
    local required_vars=(
        "GIT_USER_NAME:Your Git user name (for Git commits):"
        "GIT_USER_EMAIL:Your Git user email (for Git commits):"
        "GITHUB_TOKEN:Your GitHub personal access token (for private repos):"
        "AWS_SSO_START_URL:Your AWS SSO Start URL (e.g., https://company.awsapps.com/start):"
        "AWS_SSO_REGION:Your AWS SSO Region (e.g., us-east-1):us-east-1"
    )

    # No optional variables - all are required
    local optional_vars=()

    # First pass: check what's missing in required variables
    local missing_required=()

    for var_info in "${required_vars[@]}"; do
        IFS=':' read -r var_name prompt_text default_value <<< "$var_info"
        local current_value=$(get_var_from_env "$var_name" "$env_file")

        # If empty and has default, use default
        if [ -z "$current_value" ] && [ -n "$default_value" ]; then
            current_value="$default_value"
        fi

        if ! is_valid_value "$current_value"; then
            missing_required+=("$var_info")
        fi
    done

    # If there are missing required variables, prompt for them
    if [ ${#missing_required[@]} -gt 0 ]; then
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 Missing Required Variables"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "The following required variables need to be configured:"
        echo ""

        for var_info in "${missing_required[@]}"; do
            IFS=':' read -r var_name prompt_text default_value <<< "$var_info"
            prompt_for_variable "$var_name" "$prompt_text" "$default_value" "$env_file"
        done
    fi

    # Final validation: ensure all REQUIRED variables are set
    # Loop until all are valid
    while true; do
        echo ""
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "🔍 Final Validation"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""

        local validation_failed=false
        local still_missing=()

        # Validate required variables
        for var_info in "${required_vars[@]}"; do
            IFS=':' read -r var_name prompt_text default_value <<< "$var_info"
            local value=$(get_var_from_env "$var_name" "$env_file")

            # If empty and has default, use default
            if [ -z "$value" ] && [ -n "$default_value" ]; then
                value="$default_value"
            fi

            if ! is_valid_value "$value"; then
                echo "❌ Missing or invalid: $var_name"
                validation_failed=true
                still_missing+=("$var_info")
            else
                echo "✓ $var_name is set"
            fi
        done

        echo ""

        if [ "$validation_failed" = false ]; then
            break
        fi

        # Otherwise, prompt for missing ones
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo "📝 Missing Required Variables"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "Please provide the following required variables:"
        echo ""

        for var_info in "${still_missing[@]}"; do
            IFS=':' read -r var_name prompt_text default_value <<< "$var_info"
            prompt_for_variable "$var_name" "$prompt_text" "$default_value" "$env_file"
        done
    done

    # Show summary
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📄 Environment Variables Summary"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Show required variables
    for var_info in "${required_vars[@]}"; do
        IFS=':' read -r var_name prompt_text default_value <<< "$var_info"
        local current_value=$(get_var_from_env "$var_name" "$env_file")

        # Mask sensitive values
        if [[ "$var_name" =~ (TOKEN|SECRET|PASSWORD|KEY) ]]; then
            echo "✓ $var_name = $(echo "$current_value" | sed 's/\(.\{10\}\).*/\1.../' 2>/dev/null || echo "***HIDDEN***")"
        else
            echo "✓ $var_name = $(echo "$current_value" | sed 's/\(.\{50\}\).*/\1.../' 2>/dev/null || echo "$current_value")"
        fi
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "✅ All Required Variables Are Set!"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "ℹ️  Note: AWS Account variables (AWS_ACCOUNT_*_ID) will be"
    echo "   automatically populated after AWS SSO configuration."
    echo ""

    return 0
}

# Function to load environment variables from .env file
load_env_file() {
    local env_file="$1"

    if [ -f "$env_file" ]; then
        echo "📝 Loading environment variables from .env file..."
        set -a
        while IFS= read -r line || [ -n "$line" ]; do
            # Skip comments and empty lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ -z "${line// }" ]] && continue
            # Export the variable
            eval "export $line" 2>/dev/null || true
        done < "$env_file"
        set +a
        echo "✓ Environment variables loaded"
        echo ""
    fi
}

# Function to populate AWS account variables from ~/.aws/config
populate_aws_accounts() {
    local env_file="$1"

    # Check if aws_helper.sh functions are available
    if ! declare -f get_aws_env_variables > /dev/null 2>&1; then
        echo "⚠️  AWS helper functions not available. Skipping AWS account population."
        return 0
    fi

    # Check if AWS config exists
    if [ ! -f "$HOME/.aws/config" ]; then
        echo "⏭️  No AWS config found at ~/.aws/config. Skipping AWS account population."
        return 0
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "🔍 Discovering AWS Accounts"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Get AWS variables from config
    local aws_vars_output
    aws_vars_output=$(get_aws_env_variables)

    if [ -z "$aws_vars_output" ]; then
        echo "⏭️  No AWS accounts found in ~/.aws/config"
        echo ""
        return 0
    fi

    # Check if we already have AWS_ACCOUNT_*_ID variables in .env
    local existing_accounts=$(grep -c "^AWS_ACCOUNT_.*_ID=" "$env_file" 2>/dev/null || echo "0")

    if [ "$existing_accounts" -gt 0 ]; then
        echo "ℹ️  Found $existing_accounts AWS account(s) already in .env file."
        echo ""

        # In smart mode, keep existing accounts
        if [ "${INSTALL_ACTION:-}" = "smart" ] || [ "${INSTALL_MODE:-}" = "smart" ]; then
            echo "⏭️  Keeping existing AWS accounts in .env (smart mode)"
            echo ""
            return 0
        fi

        read -p "Do you want to update AWS accounts from ~/.aws/config? [y/N]: " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "⏭️  Keeping existing AWS accounts in .env"
            echo ""
            return 0
        fi

        # Remove existing AWS_ACCOUNT_* lines
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' '/^AWS_ACCOUNT_/d' "$env_file"
        else
            sed -i '/^AWS_ACCOUNT_/d' "$env_file"
        fi
        echo "✓ Removed existing AWS account variables"
    fi

    # Add AWS variables to .env
    local account_count=0
    echo ""
    echo "Adding AWS accounts to .env file:"
    echo ""

    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Check if this is an AWS_ACCOUNT line
        if [[ "$line" =~ ^AWS_ACCOUNT_[0-9]+_(ID|ROLE|PROFILE)= ]]; then
            echo "$line" >> "$env_file"

            # Count accounts (only count ID lines)
            if [[ "$line" =~ ^AWS_ACCOUNT_[0-9]+_ID= ]]; then
                account_count=$((account_count + 1))
                # Extract and show account ID
                local account_id=$(echo "$line" | sed 's/^AWS_ACCOUNT_[0-9]*_ID=//')
                echo "  ✓ Account $account_count: $account_id"
            fi
        elif [[ "$line" =~ ^AWS_SSO_ ]]; then
            # Update AWS_SSO variables if they exist
            local var_name=$(echo "$line" | sed 's/=.*//')
            local var_value=$(echo "$line" | sed 's/^[^=]*=//')

            # Check if this variable already exists in .env
            if grep -q "^${var_name}=" "$env_file" 2>/dev/null; then
                # Update existing line
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s|^${var_name}=.*|${line}|" "$env_file"
                else
                    sed -i "s|^${var_name}=.*|${line}|" "$env_file"
                fi
            else
                # Add new line
                echo "$line" >> "$env_file"
            fi
        fi
    done <<< "$aws_vars_output"

    echo ""
    if [ $account_count -gt 0 ]; then
        echo "✓ Added $account_count AWS account(s) to .env file"
    else
        echo "⏭️  No AWS accounts found to add"
    fi
    echo ""
}
