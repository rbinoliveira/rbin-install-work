#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [11] CONFIGURING TERMINAL ========="
echo "=============================================="

# Use name from .env
if [ -z "$GIT_USER_NAME" ]; then
    echo "❌ GIT_USER_NAME is required in .env file"
    exit 1
fi

# Use first name or username from Git name
TERMINAL_PROFILE_NAME=$(echo "$GIT_USER_NAME" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')
if [ -z "$TERMINAL_PROFILE_NAME" ]; then
    TERMINAL_PROFILE_NAME="Developer"
fi

echo "Configuring macOS Terminal.app with Dracula theme..."

# Check if iTerm2 is installed
if [ -d "/Applications/iTerm.app" ]; then
    echo "✓ iTerm2 detected"
    echo ""
    echo "To configure iTerm2 with Dracula theme:"
    echo "  1. Open iTerm2"
    echo "  2. Go to Preferences > Profiles > Colors"
    echo "  3. Click 'Color Presets' and select 'Dracula'"
    echo "  4. Or download from: https://github.com/dracula/iterm"
    echo ""
    echo "To set CaskaydiaCove Nerd Font:"
    echo "  1. Go to Preferences > Profiles > Text"
    echo "  2. Set Font to 'CaskaydiaCove Nerd Font'"
    echo ""
else
    echo "Configuring Terminal.app..."
    echo ""
    echo "⚠️  Terminal.app configuration requires manual setup or AppleScript."
    echo ""
    echo "To configure Terminal.app with Dracula theme:"
    echo "  1. Open Terminal.app"
    echo "  2. Go to Terminal > Preferences > Profiles"
    echo "  3. Create a new profile named '$TERMINAL_PROFILE_NAME'"
    echo "  4. Set the following colors (Dracula theme):"
    echo "     - Background: #282a36"
    echo "     - Text: #f8f8f2"
    echo "     - Bold Text: #ffffff"
    echo "     - Selection: #44475a"
    echo "     - Cursor: #f8f8f2"
    echo "     - ANSI Colors:"
    echo "       • Black: #000000"
    echo "       • Red: #ff5555"
    echo "       • Green: #50fa7b"
    echo "       • Yellow: #f1fa8c"
    echo "       • Blue: #bd93f9"
    echo "       • Magenta: #ff79c6"
    echo "       • Cyan: #8be9fd"
    echo "       • White: #bbbbbb"
    echo "       • Bright Black: #44475a"
    echo "       • Bright Red: #ff6e6e"
    echo "       • Bright Green: #69ff94"
    echo "       • Bright Yellow: #ffffa5"
    echo "       • Bright Blue: #d6caff"
    echo "       • Bright Magenta: #ff92df"
    echo "       • Bright Cyan: #a6f0ff"
    echo "       • Bright White: #ffffff"
    echo "  5. Set Font to 'CaskaydiaCove Nerd Font' (size 13)"
    echo "  6. Set this profile as default"
    echo ""
    echo "Alternatively, you can use a tool like 'terminal-dracula' or configure via AppleScript."
    echo ""
    
    # Try to use osascript to configure Terminal.app (may require user interaction)
    if command -v osascript &> /dev/null; then
        echo "Attempting to configure Terminal.app via AppleScript..."
        osascript <<EOF 2>/dev/null || echo "⚠️  AppleScript configuration requires Terminal.app permissions"
tell application "Terminal"
    -- Create or get the profile
    set default settings to settings set "$TERMINAL_PROFILE_NAME"
    
    -- Set font
    set font name of default settings to "CaskaydiaCove Nerd Font"
    set font size of default settings to 13
    
    -- Set Dracula colors
    set background color of default settings to {40, 42, 54}
    set normal text color of default settings to {248, 248, 242}
    set bold text color of default settings to {255, 255, 255}
    set cursor color of default settings to {248, 248, 242}
    
    -- ANSI colors (simplified - full palette would be more complex)
    set red color of default settings to {255, 85, 85}
    set green color of default settings to {80, 250, 123}
    set blue color of default settings to {189, 147, 249}
    set yellow color of default settings to {241, 250, 140}
    set magenta color of default settings to {255, 121, 198}
    set cyan color of default settings to {139, 233, 253}
    set white color of default settings to {187, 187, 187}
    set black color of default settings to {0, 0, 0}
end tell
EOF
        if [ $? -eq 0 ]; then
            echo "✓ Terminal.app configured successfully"
        else
            echo "⚠️  Could not configure Terminal.app automatically"
            echo "   Please configure manually using the instructions above"
        fi
    fi
fi

echo "=============================================="
echo "============== [11] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 12-configure-ssh.sh"
