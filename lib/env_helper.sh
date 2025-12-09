#!/usr/bin/env bash

#
# Environment Variables Helper Module
#
# Provides functions to check and get environment variables from .env file
# or prompt user for input if not found.
#
# Usage:
#   source lib/env_helper.sh
#   get_env_var "GIT_USER_NAME" "Your Git name" true
#

set -eo pipefail

# ────────────────────────────────────────────────────────────────
# Get Environment Variable with Fallback to User Input
# ────────────────────────────────────────────────────────────────

get_env_var() {
    local var_name="$1"
    local prompt_text="${2:-$var_name}"
    local required="${3:-false}"
    local save_to_env="${4:-true}"
    
    # Try to get from environment first (may have been loaded from .env)
    local value="${!var_name}"
    
    # If not in environment, try to read from .env file
    if [ -z "$value" ]; then
        # Find project root (assuming we're in a subdirectory)
        local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        local project_root="$(cd "$script_dir/../.." && pwd)"
        local env_file="$project_root/.env"
        
        if [ -f "$env_file" ]; then
            # Read from .env file
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
                    break
                fi
            done < "$env_file"
        fi
    fi
    
    # If still empty and required, prompt user
    if [ -z "$value" ] && [ "$required" = "true" ]; then
        echo ""
        echo "⚠️  $var_name is required but not found in .env file"
        read -p "Enter $prompt_text: " value
        
        # Validate input
        if [ -z "$value" ]; then
            echo "❌ Error: $var_name cannot be empty"
            return 1
        fi
        
        # Save to .env if requested
        if [ "$save_to_env" = "true" ] && [ -f "$env_file" ]; then
            # Check if variable already exists in .env
            if grep -q "^[[:space:]]*${var_name}[[:space:]]*=" "$env_file" 2>/dev/null; then
                # Update existing line
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=${value}|" "$env_file"
                else
                    sed -i "s|^[[:space:]]*${var_name}[[:space:]]*=.*|${var_name}=${value}|" "$env_file"
                fi
            else
                # Append new line
                echo "${var_name}=${value}" >> "$env_file"
            fi
            echo "✓ Saved $var_name to .env file"
        fi
    fi
    
    # Export the variable
    export "$var_name=$value"
    echo "$value"
}

# ────────────────────────────────────────────────────────────────
# Check if .env file exists
# ────────────────────────────────────────────────────────────────

check_env_file() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/../.." && pwd)"
    local env_file="$project_root/.env"
    
    if [ -f "$env_file" ]; then
        return 0
    else
        return 1
    fi
}

# ────────────────────────────────────────────────────────────────
# Get .env file path
# ────────────────────────────────────────────────────────────────

get_env_file_path() {
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local project_root="$(cd "$script_dir/../.." && pwd)"
    echo "$project_root/.env"
}

# Export functions for use in other scripts
export -f get_env_var
export -f check_env_file
export -f get_env_file_path

