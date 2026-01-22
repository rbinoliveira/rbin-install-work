#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ENV_FILE="$PROJECT_ROOT/.env"
ENV_EXAMPLE="$PROJECT_ROOT/.env.example"

# Validate .env file exists
if [ ! -f "$ENV_FILE" ]; then
    echo "❌ .env file not found: $ENV_FILE"
    echo ""
    if [ -f "$ENV_EXAMPLE" ]; then
        echo "📝 Please create .env file from template:"
        echo "   cp $ENV_EXAMPLE $ENV_FILE"
        echo "   nano $ENV_FILE"
    else
        echo "📝 Please create .env file:"
        echo "   nano $ENV_FILE"
    fi
    echo ""
    exit 1
fi

# Load .env file
set -a
if [ -f "$ENV_FILE" ]; then
    # Source the .env file, ignoring comments and empty lines
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip comments and empty lines
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ -z "${line// }" ]] && continue
        # Export the variable
        eval "export $line" 2>/dev/null || true
    done < "$ENV_FILE"
fi
set +a

# Function to get variable value from .env file
get_var_from_env() {
    local var_name="$1"
    local value=""
    
    if [ -f "$ENV_FILE" ]; then
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
        done < "$ENV_FILE"
    fi
    
    echo "$value"
}

# Get AWS SSO variables from .env (they should have been set in run.sh)
AWS_SSO_START_URL="${AWS_SSO_START_URL:-$(get_var_from_env "AWS_SSO_START_URL")}"
AWS_SSO_REGION="${AWS_SSO_REGION:-$(get_var_from_env "AWS_SSO_REGION")}"

# If still not set, these are optional - don't fail, just skip AWS SSO configuration
if [ -z "$AWS_SSO_START_URL" ]; then
    echo "⚠️  AWS_SSO_START_URL not found in .env file"
    echo ""
    echo "AWS SSO configuration will be skipped."
    echo "You can configure it later by:"
    echo "  1. Adding AWS_SSO_START_URL to .env file"
    echo "  2. Running this script again: bash 18-configure-aws-sso.sh"
    echo ""
    echo "=============================================="
    echo "============== [18] SKIPPED ================="
    echo "=============================================="
    echo "▶ Next, run: bash 19-install-dotnet.sh"
    exit 0
fi

# Set default region if not provided
if [ -z "$AWS_SSO_REGION" ]; then
    AWS_SSO_REGION="us-east-1"
fi

# Use first account as default if available
AWS_DEFAULT_ACCOUNT_ID="${AWS_ACCOUNT_1_ID:-}"
AWS_DEFAULT_ROLE="${AWS_ACCOUNT_1_ROLE:-}"
AWS_DEFAULT_REGION="${AWS_SSO_REGION:-us-east-1}"

if [ -z "$AWS_DEFAULT_ACCOUNT_ID" ] || [ -z "$AWS_DEFAULT_ROLE" ]; then
    echo "⚠️  AWS_ACCOUNT_1_ID and AWS_ACCOUNT_1_ROLE not set in .env"
    echo "   Using minimal configuration. You can add accounts later."
    AWS_DEFAULT_ACCOUNT_ID=""
    AWS_DEFAULT_ROLE=""
fi

echo "=============================================="
echo "======= [18] CONFIGURING AWS SSO ============="
echo "=============================================="

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo "❌ AWS CLI is not installed. Please run 17-install-aws-cli.sh first."
    exit 1
fi

echo "Configuring AWS SSO..."
echo ""

# Check if already configured with profiles
has_valid_config=false
if [ -f "$HOME/.aws/config" ]; then
    # Check if has SSO session configured
    if grep -q "sso_start_url" "$HOME/.aws/config"; then
        # Check if has at least one profile with account_id
        if grep -A 5 "^\[default\]" "$HOME/.aws/config" 2>/dev/null | grep -q "sso_account_id"; then
            has_valid_config=true
        elif grep -q "^\[profile " "$HOME/.aws/config" 2>/dev/null; then
            while IFS= read -r profile_line; do
                if grep -A 5 "$profile_line" "$HOME/.aws/config" 2>/dev/null | grep -q "sso_account_id"; then
                    has_valid_config=true
                    break
                fi
            done < <(grep "^\[profile " "$HOME/.aws/config" 2>/dev/null)
        fi
    fi
fi

if [ "$has_valid_config" = true ]; then
    # In smart mode, don't reconfigure if already configured with profiles
    if [ "$INSTALL_ACTION" = "smart" ]; then
        echo "✓ AWS SSO is already configured with account profiles. Skipping reconfiguration."
        echo "=============================================="
        echo "============== [18] DONE ===================="
        echo "=============================================="
        exit 0
    fi
    echo "⚠️  AWS SSO appears to be already configured."
    read -p "Do you want to reconfigure? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Configuration skipped."
        exit 0
    fi
    # Backup existing config
    if [ -f "$HOME/.aws/config" ]; then
        cp "$HOME/.aws/config" "$HOME/.aws/config.backup.$(date +%Y%m%d_%H%M%S)"
        echo "✓ Existing config backed up"
    fi
fi

# Create .aws directory if it doesn't exist
mkdir -p "$HOME/.aws"

# Configure AWS SSO
echo "Setting up AWS SSO configuration..."

# Create config file with SSO session
cat > "$HOME/.aws/config" << EOF
[sso-session default]
sso_start_url = $AWS_SSO_START_URL
sso_region = $AWS_SSO_REGION
EOF

# Add default profile if account and role are configured
if [ -n "$AWS_DEFAULT_ACCOUNT_ID" ] && [ -n "$AWS_DEFAULT_ROLE" ]; then
    cat >> "$HOME/.aws/config" << EOF

[default]
sso_session = default
sso_account_id = $AWS_DEFAULT_ACCOUNT_ID
sso_role_name = $AWS_DEFAULT_ROLE
region = $AWS_DEFAULT_REGION
output = json
EOF
fi

# Add additional accounts from .env
account_num=1
while true; do
    account_id_var="AWS_ACCOUNT_${account_num}_ID"
    role_var="AWS_ACCOUNT_${account_num}_ROLE"
    profile_var="AWS_ACCOUNT_${account_num}_PROFILE"

    account_id="${!account_id_var}"
    role="${!role_var}"
    profile="${!profile_var}"

    if [ -z "$account_id" ] || [ -z "$role" ]; then
        break
    fi

    # Use profile name or default to account number
    profile_name="${profile:-account-${account_num}}"

    # Skip if this is account 1 and we already added it as default
    if [ "$account_num" -eq 1 ] && [ -n "$AWS_DEFAULT_ACCOUNT_ID" ] && [ "$account_id" = "$AWS_DEFAULT_ACCOUNT_ID" ]; then
        account_num=$((account_num + 1))
        continue
    fi

    cat >> "$HOME/.aws/config" << EOF

[profile $profile_name]
sso_session = default
sso_account_id = $account_id
sso_role_name = $role
region = $AWS_DEFAULT_REGION
output = json
EOF

    account_num=$((account_num + 1))
done

echo "✓ AWS SSO configuration created"
echo ""
echo "Configuration details:"
echo "  - SSO Start URL: $AWS_SSO_START_URL"
echo "  - SSO Region: $AWS_SSO_REGION"
if [ -n "$AWS_DEFAULT_ACCOUNT_ID" ] && [ -n "$AWS_DEFAULT_ROLE" ]; then
    echo "  - Default Account: $AWS_DEFAULT_ACCOUNT_ID"
    echo "  - Default Role: $AWS_DEFAULT_ROLE"
fi
echo "  - Default Region: $AWS_DEFAULT_REGION"
echo "  - Output Format: json"
echo ""

echo "=============================================="
echo "============== [18] DONE ===================="
echo "=============================================="
echo ""

# Check if profiles were created in config
has_profiles=false
if [ -f "$HOME/.aws/config" ]; then
    if grep -q "^\[profile " "$HOME/.aws/config" 2>/dev/null || grep -q "^\[default\]" "$HOME/.aws/config" 2>/dev/null; then
        # Check if default profile has account_id and role
        if grep -A 5 "^\[default\]" "$HOME/.aws/config" 2>/dev/null | grep -q "sso_account_id"; then
            has_profiles=true
        fi
        # Check if any profile has account_id and role
        if [ "$has_profiles" = false ]; then
            while IFS= read -r profile_line; do
                if grep -A 5 "$profile_line" "$HOME/.aws/config" 2>/dev/null | grep -q "sso_account_id"; then
                    has_profiles=true
                    break
                fi
            done < <(grep "^\[profile " "$HOME/.aws/config" 2>/dev/null)
        fi
    fi
fi

# Check if profiles were created
if [ -z "$AWS_DEFAULT_ACCOUNT_ID" ] || [ -z "$AWS_DEFAULT_ROLE" ]; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "⚠️  IMPORTANT: AWS SSO Login Required"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "No AWS account profiles were configured in .env file."
    echo ""
    if [ "$has_profiles" = false ]; then
        echo "⚠️  No profiles found in ~/.aws/config."
        echo ""
        
        # Check if user wants to auto-discover (auto-proceed in smart mode)
        should_auto_discover=false
        if [ "$INSTALL_ACTION" = "smart" ]; then
            # In smart mode, try to auto-discover automatically
            echo "Attempting to automatically discover and create profiles..."
            echo ""
            should_auto_discover=true
        elif [ -t 0 ]; then
            read -p "Do you want to automatically discover and create profiles? [Y/n]: " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Nn]$ ]]; then
                echo ""
                echo "To create profiles manually, use:"
                echo "   aws configure sso"
                echo ""
                echo "Or login first and then run this script again:"
                echo "   🔐 aws sso login --sso-session default"
                echo ""
                exit 1
            fi
            should_auto_discover=true
        else
            echo "To create profiles, login first:"
            echo "   🔐 aws sso login --sso-session default"
            echo ""
            echo "Then run this script again to automatically discover and create profiles."
            echo ""
            exit 1
        fi

        if [ "$should_auto_discover" = true ]; then
            # Auto-discover logic for both smart and interactive modes
            echo ""

            # Step 1: Check login status
            echo "Step 1: Checking AWS SSO login status..."
            is_logged_in=false

            # Check if there's a valid SSO token in cache
            sso_token=""
            if [ -d "$HOME/.aws/sso/cache" ]; then
                # Find the most recent cache file with a valid access token
                for cache_file in "$HOME/.aws/sso/cache"/*.json; do
                    if [ -f "$cache_file" ]; then
                        if command -v jq &>/dev/null; then
                            token=$(jq -r '.accessToken // empty' "$cache_file" 2>/dev/null)
                            expires=$(jq -r '.expiresAt // empty' "$cache_file" 2>/dev/null)
                            if [ -n "$token" ] && [ "$token" != "null" ] && [ -n "$expires" ]; then
                                # Check if token is not expired (simple check)
                                sso_token="$token"
                                break
                            fi
                        fi
                    fi
                done
            fi

            # Test if we can list accounts
            if [ -n "$sso_token" ] && aws sso list-accounts --access-token "$sso_token" --region "$AWS_SSO_REGION" &>/dev/null 2>&1; then
                echo "✓ Already logged in to AWS SSO"
                is_logged_in=true
            else
                # Not logged in
                if [ "$INSTALL_ACTION" = "smart" ]; then
                    # In smart mode, cannot do interactive login
                    echo "⚠️  Not logged in to AWS SSO (smart mode)"
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo "⚠️  AWS Account Configuration Incomplete"
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                    echo "AWS SSO session is configured but account profiles could not be"
                    echo "created automatically because you're not logged in to AWS SSO."
                    echo ""
                    echo "To complete the setup:"
                    echo ""
                    echo "1. Login to AWS SSO (will open browser for authentication):"
                    echo "   "
                    echo "   🔐 aws sso login --sso-session default"
                    echo "   "
                    echo "   Or simply:"
                    echo "   🔐 aws sso login"
                    echo ""
                    echo "2. Then run this script again to auto-discover accounts:"
                    echo "   bash $SCRIPT_DIR/18-configure-aws-sso.sh"
                    echo ""
                    echo "   Or run the full setup:"
                    echo "   bash $PROJECT_ROOT/run.sh"
                    echo ""
                    echo "3. Or configure profiles manually:"
                    echo "   aws configure sso"
                    echo ""
                    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
                    echo ""
                else
                    # In interactive mode, try to login
                    echo "Attempting to login to AWS SSO..."
                    if aws sso login --sso-session default 2>&1; then
                        echo "✓ Login successful"
                        is_logged_in=true
                    else
                        echo "⚠️  Login failed. Please login manually:"
                        echo "   aws sso login --sso-session default"
                        echo ""
                        echo "Then run this script again."
                        exit 1
                    fi
                fi
            fi
            echo ""

            # If not logged in (smart mode), exit with error to stop installation
            if [ "$is_logged_in" = false ]; then
                exit 1
            fi
                
                # Step 2: List accounts
                echo "Step 2: Discovering available accounts..."
                accounts_json=""
                if [ -n "$sso_token" ]; then
                    accounts_json=$(aws sso list-accounts --access-token "$sso_token" --region "$AWS_SSO_REGION" 2>&1)
                else
                    accounts_json=$(aws sso list-accounts --sso-session default 2>&1)
                fi

                if [ $? -eq 0 ] && echo "$accounts_json" | grep -q "accountId"; then
                    echo "✓ Found accounts"
                    echo ""

                    # Step 3: Create profiles
                    echo "Step 3: Creating profiles..."
                    profile_count=0
                    first_account=true

                    # Extract account IDs into array
                    account_ids=()
                    # Use jq if available, otherwise use grep/sed
                    if command -v jq &> /dev/null; then
                        while IFS= read -r account_id; do
                            [ -n "$account_id" ] && account_ids+=("$account_id")
                        done < <(echo "$accounts_json" | jq -r '.accountList[]?.accountId // empty' 2>/dev/null)
                    else
                        # Fallback: extract using grep and sed
                        while IFS= read -r account_id; do
                            [ -n "$account_id" ] && account_ids+=("$account_id")
                        done < <(echo "$accounts_json" | grep -o '"accountId": "[^"]*"' | sed 's/"accountId": "\([^"]*\)"/\1/')
                    fi
                    
                    # Process each account
                    for account_id in "${account_ids[@]}"; do
                        if [ -n "$account_id" ]; then
                            # Get account name
                            account_name=""
                            if command -v jq &> /dev/null; then
                                account_name=$(echo "$accounts_json" | jq -r ".accountList[] | select(.accountId == \"$account_id\") | .accountName // \"account-${account_id:0:4}\"" 2>/dev/null)
                            else
                                account_name=$(echo "$accounts_json" | grep -A 10 "\"accountId\": \"$account_id\"" | grep -o '"accountName": "[^"]*"' | head -1 | sed 's/"accountName": "\([^"]*\)"/\1/')
                                account_name="${account_name:-account-${account_id:0:4}}"
                            fi
                            account_name=$(echo "$account_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')

                            # List roles for this account
                            echo "  Discovering roles for account $account_id ($account_name)..."
                            roles_json=""
                            if [ -n "$sso_token" ]; then
                                roles_json=$(aws sso list-account-roles --access-token "$sso_token" --region "$AWS_SSO_REGION" --account-id "$account_id" 2>&1)
                            else
                                roles_json=$(aws sso list-account-roles --sso-session default --account-id "$account_id" 2>&1)
                            fi

                            if [ $? -eq 0 ] && echo "$roles_json" | grep -q "roleName"; then
                                # Get first role (usually AdministratorAccess or similar)
                                role_name=""
                                if command -v jq &> /dev/null; then
                                    role_name=$(echo "$roles_json" | jq -r '.roleList[0].roleName // empty' 2>/dev/null)
                                else
                                    role_name=$(echo "$roles_json" | grep -o '"roleName": "[^"]*"' | head -1 | sed 's/"roleName": "\([^"]*\)"/\1/')
                                fi

                                if [ -n "$role_name" ]; then
                                    # Determine profile name
                                    profile_name=""
                                    if [ "$first_account" = true ]; then
                                        profile_name="default"
                                        first_account=false
                                    else
                                        profile_name="$account_name"
                                    fi
                                    
                                    # Check if profile already exists
                                    if ! grep -q "^\[profile $profile_name\]" "$HOME/.aws/config" 2>/dev/null && \
                                       ! ( [ "$profile_name" = "default" ] && grep -q "^\[default\]" "$HOME/.aws/config" 2>/dev/null ); then
                                        
                                        # Create profile
                                        if [ "$profile_name" = "default" ]; then
                                            cat >> "$HOME/.aws/config" << PROFILE_EOF

[default]
sso_session = default
sso_account_id = $account_id
sso_role_name = $role_name
region = $AWS_DEFAULT_REGION
output = json
PROFILE_EOF
                                        else
                                            cat >> "$HOME/.aws/config" << PROFILE_EOF

[profile $profile_name]
sso_session = default
sso_account_id = $account_id
sso_role_name = $role_name
region = $AWS_DEFAULT_REGION
output = json
PROFILE_EOF
                                        fi
                                        
                                        echo "    ✓ Created profile: $profile_name (role: $role_name)"
                                        profile_count=$((profile_count + 1))
                                    else
                                        echo "    ⚠️  Profile $profile_name already exists, skipping"
                                    fi
                                else
                                    echo "    ⚠️  No roles found for account $account_id"
                                fi
                            else
                                echo "    ⚠️  Could not list roles for account $account_id"
                            fi
                        fi
                    done
                    
                    if [ $profile_count -gt 0 ]; then
                        echo ""
                        echo "✓ Created $profile_count profile(s) automatically"
                        echo ""
                        echo "You can now run this script again or run.sh to extract the account variables."
                    else
                        echo ""
                        echo "⚠️  Could not create profiles automatically"
                        echo ""
                        echo "Please create profiles manually using:"
                        echo "   aws configure sso"
                    fi
                else
                    echo "⚠️  Could not list accounts. You may need to login first:"
                    echo ""
                    echo "   🔐 aws sso login --sso-session default"
                    echo ""
                    echo "Or create profiles manually using:"
                    echo "   aws configure sso"
                fi
        fi
    else
        echo "✓ Profiles found in ~/.aws/config, but not in .env file."
        echo "  You can extract them by running the main script (run.sh) again."
    fi
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
else
    echo "📝 Next steps:"
    echo ""
    echo "1. ⚠️  Login to AWS SSO (REQUIRED):"
    echo "   🔐 aws sso login --sso-session default"
    echo ""
    echo "2. Test the configuration:"
    echo "   aws sts get-caller-identity"
    echo ""
fi

echo "🎉 AWS SSO configuration complete!"
