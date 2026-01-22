#!/usr/bin/env bash

set -e

echo "=============================================="
echo "========= [13] CONFIGURING FILE WATCHERS ======"
echo "=============================================="

echo "macOS uses FSEvents instead of inotify for file system monitoring."
echo "FSEvents is automatically configured and doesn't require manual tuning."
echo ""

# Check current file descriptor limits (useful for development tools)
echo "Checking file descriptor limits..."
CURRENT_LIMIT=$(ulimit -n)
echo "Current file descriptor limit: $CURRENT_LIMIT"

# macOS default is usually 256, but can be increased if needed
RECOMMENDED_LIMIT=1024

if [ "$CURRENT_LIMIT" -lt "$RECOMMENDED_LIMIT" ]; then
    echo ""
    echo "⚠️  File descriptor limit is below recommended value ($RECOMMENDED_LIMIT)"
    echo "   Current limit: $CURRENT_LIMIT"
    echo ""
    echo "Configuring file descriptor limit..."
    
    # Increase limit for current session
    if ulimit -n "$RECOMMENDED_LIMIT" 2>/dev/null; then
        echo "✓ File descriptor limit increased to $RECOMMENDED_LIMIT for this session"
    else
        echo "⚠️  Could not increase limit for this session (may require different method)"
    fi
    
    # Make it persistent by adding to ~/.zshrc
    if [ -f "$HOME/.zshrc" ]; then
        if ! grep -q "ulimit -n $RECOMMENDED_LIMIT" "$HOME/.zshrc" 2>/dev/null; then
            echo "" >> "$HOME/.zshrc"
            echo "# Increase file descriptor limit (added by install script)" >> "$HOME/.zshrc"
            echo "ulimit -n $RECOMMENDED_LIMIT 2>/dev/null || true" >> "$HOME/.zshrc"
            echo "✓ Added ulimit configuration to ~/.zshrc (will apply after restart)"
        else
            echo "✓ ulimit configuration already exists in ~/.zshrc"
        fi
    else
        echo "⚠️  ~/.zshrc not found, creating it..."
        echo "# Increase file descriptor limit (added by install script)" > "$HOME/.zshrc"
        echo "ulimit -n $RECOMMENDED_LIMIT 2>/dev/null || true" >> "$HOME/.zshrc"
        echo "✓ Created ~/.zshrc with ulimit configuration"
    fi
    
    echo ""
else
    echo "✓ File descriptor limit is adequate ($CURRENT_LIMIT)"
fi

echo ""
echo "Note: FSEvents on macOS handles file watching automatically."
echo "      No additional configuration needed for most development tools."

echo "=============================================="
echo "============== [13] DONE ===================="
echo "=============================================="
echo "▶ Next, run: bash 14-configure-cursor.sh"
