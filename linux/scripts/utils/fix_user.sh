#!/bin/bash

# Script to diagnose and fix user login issues
# Usage: sudo ./fix_user.sh [number]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root or with sudo${NC}"
   exit 1
fi

echo -e "${BLUE}=== User Fix Script ===${NC}"
echo -e "${YELLOW}Listing all system users...${NC}\n"

# Get all users with login shells (excluding system users with nologin/false shells)
# Also include users with UID >= 1000 (regular users)
mapfile -t USERS < <(awk -F: '($3 >= 1000 && $3 < 65534) || $1 == "root" {print $1}' /etc/passwd | sort)

# Check if we have any users
if [ ${#USERS[@]} -eq 0 ]; then
    echo -e "${RED}No users found${NC}"
    exit 1
fi

# Display users with numbers
echo -e "${CYAN}Available users:${NC}"
echo -e "${CYAN}────────────────${NC}"
for i in "${!USERS[@]}"; do
    NUM=$((i + 1))
    USER_INFO=$(getent passwd "${USERS[$i]}")
    USER_HOME=$(echo "$USER_INFO" | cut -d: -f6)
    USER_SHELL=$(echo "$USER_INFO" | cut -d: -f7)
    printf "${GREEN}%3d${NC}) ${YELLOW}%-20s${NC} ${BLUE}%s${NC} ${CYAN}%s${NC}\n" "$NUM" "${USERS[$i]}" "$USER_HOME" "$USER_SHELL"
done
echo -e "${CYAN}────────────────${NC}"
echo -e "Total: ${#USERS[@]} users\n"

# Check if a number was provided as argument
if [ -n "$1" ]; then
    SELECTION="$1"
else
    # Ask user to select
    read -p "Enter user number to fix (1-${#USERS[@]}): " SELECTION
fi

# Validate selection
if ! [[ "$SELECTION" =~ ^[0-9]+$ ]]; then
    echo -e "${RED}Error: Invalid input. Please enter a number.${NC}"
    exit 1
fi

if [ "$SELECTION" -lt 1 ] || [ "$SELECTION" -gt ${#USERS[@]} ]; then
    echo -e "${RED}Error: Number out of range. Please enter a number between 1 and ${#USERS[@]}.${NC}"
    exit 1
fi

# Get selected username (array is 0-indexed)
USERNAME="${USERS[$((SELECTION - 1))]}"

echo -e "\n${GREEN}Selected user: ${USERNAME}${NC}"
echo -e "${BLUE}Starting diagnostics...${NC}\n"

# Function to print section headers
print_section() {
    echo -e "\n${YELLOW}>>> $1${NC}"
}

# Function to print success
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

# Function to print error
print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to print info
print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if user exists
print_section "Checking if user exists"
if ! id "$USERNAME" &>/dev/null; then
    print_error "User $USERNAME does not exist"
    read -p "Do you want to create this user? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        useradd -m -s /bin/bash "$USERNAME"
        print_success "User $USERNAME created"
        passwd "$USERNAME"
    else
        exit 1
    fi
else
    print_success "User $USERNAME exists"
fi

# Get user information
USER_INFO=$(getent passwd "$USERNAME")
USER_HOME=$(echo "$USER_INFO" | cut -d: -f6)
USER_SHELL=$(echo "$USER_INFO" | cut -d: -f7)
USER_UID=$(echo "$USER_INFO" | cut -d: -f3)
USER_GID=$(echo "$USER_INFO" | cut -d: -f4)

print_info "Home directory: $USER_HOME"
print_info "Shell: $USER_SHELL"
print_info "UID: $USER_UID"
print_info "GID: $USER_GID"

# Check if account is locked
print_section "Checking account lock status"
if passwd -S "$USERNAME" 2>/dev/null | grep -q "L"; then
    print_error "Account is locked"
    read -p "Do you want to unlock this account? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        passwd -u "$USERNAME"
        print_success "Account unlocked"
    fi
else
    print_success "Account is not locked"
fi

# Check shell validity
print_section "Checking shell"
if [ ! -f "$USER_SHELL" ]; then
    print_error "Shell $USER_SHELL does not exist"
    read -p "Do you want to set shell to /bin/bash? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chsh -s /bin/bash "$USERNAME"
        print_success "Shell changed to /bin/bash"
        USER_SHELL="/bin/bash"
    fi
elif ! grep -q "^$USER_SHELL$" /etc/shells; then
    print_error "Shell $USER_SHELL is not in /etc/shells"
    read -p "Do you want to add it to /etc/shells? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "$USER_SHELL" >> /etc/shells
        print_success "Shell added to /etc/shells"
    fi
else
    print_success "Shell is valid"
fi

# Check home directory
print_section "Checking home directory"
if [ ! -d "$USER_HOME" ]; then
    print_error "Home directory $USER_HOME does not exist"
    read -p "Do you want to create it? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        mkdir -p "$USER_HOME"
        cp -rT /etc/skel "$USER_HOME" 2>/dev/null || true
        chown -R "$USERNAME":"$USER_GID" "$USER_HOME"
        chmod 755 "$USER_HOME"
        print_success "Home directory created"
    fi
else
    print_success "Home directory exists"
    
    # Check home directory ownership
    print_section "Checking home directory ownership"
    OWNER=$(stat -c '%U' "$USER_HOME")
    if [ "$OWNER" != "$USERNAME" ]; then
        print_error "Home directory is owned by $OWNER instead of $USERNAME"
        read -p "Do you want to fix ownership? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chown -R "$USERNAME":"$USER_GID" "$USER_HOME"
            print_success "Ownership fixed"
        fi
    else
        print_success "Home directory ownership is correct"
    fi
    
    # Check home directory permissions
    print_section "Checking home directory permissions"
    PERMS=$(stat -c '%a' "$USER_HOME")
    if [[ ! "$PERMS" =~ ^7[0-5][0-5]$ ]]; then
        print_error "Home directory permissions are $PERMS (should be 755 or similar)"
        read -p "Do you want to fix permissions to 755? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            chmod 755 "$USER_HOME"
            print_success "Permissions fixed"
        fi
    else
        print_success "Home directory permissions are acceptable"
    fi
fi

# Check password expiry
print_section "Checking password expiry"
if chage -l "$USERNAME" 2>/dev/null | grep -q "password must be changed"; then
    print_error "Password has expired"
    read -p "Do you want to reset password expiry? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        chage -d 0 "$USERNAME"
        print_success "Password expiry reset (user will be prompted to change password on next login)"
    fi
else
    print_success "Password has not expired"
fi

# Check if user has a password set
print_section "Checking password status"
PASSWD_STATUS=$(passwd -S "$USERNAME" 2>/dev/null | awk '{print $2}')
if [ "$PASSWD_STATUS" = "NP" ] || [ "$PASSWD_STATUS" = "L" ]; then
    print_error "User has no password set or account is locked"
    read -p "Do you want to set a password now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        passwd "$USERNAME"
        print_success "Password set"
    fi
else
    print_success "User has a password set"
fi

# Check .bashrc and .profile
print_section "Checking shell configuration files"
if [ -d "$USER_HOME" ]; then
    for config_file in .bashrc .profile .bash_profile; do
        if [ ! -f "$USER_HOME/$config_file" ] && [ -f "/etc/skel/$config_file" ]; then
            print_info "Creating $config_file from /etc/skel"
            cp "/etc/skel/$config_file" "$USER_HOME/$config_file"
            chown "$USERNAME":"$USER_GID" "$USER_HOME/$config_file"
        fi
    done
    print_success "Shell configuration files checked"
fi

# Check sudo access (if needed)
print_section "Checking sudo access"
if groups "$USERNAME" | grep -q sudo || groups "$USERNAME" | grep -q wheel; then
    print_success "User has sudo access"
else
    print_info "User does not have sudo access"
    read -p "Do you want to add user to sudo group? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if grep -q "^sudo:" /etc/group; then
            usermod -aG sudo "$USERNAME"
            print_success "User added to sudo group"
        elif grep -q "^wheel:" /etc/group; then
            usermod -aG wheel "$USERNAME"
            print_success "User added to wheel group"
        else
            print_error "Neither sudo nor wheel group exists"
        fi
    fi
fi

# Check if user can log in (test with su)
print_section "Testing user login capability"
if su - "$USERNAME" -c "echo 'Login test successful'" &>/dev/null; then
    print_success "User can successfully log in"
else
    print_error "User login test failed"
    print_info "This might be due to shell configuration issues or other system restrictions"
fi

# Final summary
echo -e "\n${BLUE}=== Summary ===${NC}"
echo -e "${GREEN}User fix script completed for: ${USERNAME}${NC}"
echo -e "${YELLOW}If the user still cannot log in, check:${NC}"
echo "  1. PAM configuration in /etc/pam.d/"
echo "  2. SSH configuration if logging in remotely"
echo "  3. System logs: journalctl -u sshd or /var/log/auth.log"
echo "  4. SELinux/AppArmor restrictions"
echo ""

exit 0

