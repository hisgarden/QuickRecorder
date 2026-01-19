#!/bin/bash
# Create DMG from QuickRecorder.app
# Usage: ./scripts/create-dmg.sh [app_path]

set -euo pipefail

APP_PATH="${1:-}"

# Auto-find latest export if not provided
if [ -z "$APP_PATH" ]; then
    APP_PATH=$(find archive/export-* -name "QuickRecorder.app" -type d 2>/dev/null | sort -r | head -1)
    if [ -z "$APP_PATH" ]; then
        echo "❌ No app found. Usage: $0 [app_path]"
        echo "   Example: $0 archive/export-20260119-1045/QuickRecorder.app"
        exit 1
    fi
fi

if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found: $APP_PATH"
    exit 1
fi

DMG_NAME="QuickRecorder.dmg"

# Remove existing DMG if present
if [ -f "$DMG_NAME" ]; then
    echo "🗑️  Removing existing DMG: $DMG_NAME"
    rm -f "$DMG_NAME"
fi

# Unmount any existing QuickRecorder volume (wait for unmount to complete)
if [ -d "/Volumes/QuickRecorder" ]; then
    echo "📂 Unmounting existing QuickRecorder volume..."
    hdiutil detach "/Volumes/QuickRecorder" -force 2>/dev/null || true
    sleep 1
fi

echo "📦 Creating DMG from: $APP_PATH"

# Create temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create DMG with absolute path and unique volume name to avoid conflicts
DMG_PATH="$(cd "$(dirname "$DMG_NAME")" && pwd)/$(basename "$DMG_NAME")"
VOLUME_NAME="QuickRecorder-$(date +%s)"
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    -fs HFS+ \
    "$DMG_PATH"

# Rename the volume inside the DMG to "QuickRecorder" if needed
# (hdiutil doesn't support renaming after creation, but we can attach and rename)
if [ -f "$DMG_PATH" ]; then
    # Attach, rename volume, detach
    hdiutil attach "$DMG_PATH" -mountpoint /tmp/QuickRecorderDMG 2>/dev/null && \
    diskutil rename /tmp/QuickRecorderDMG "QuickRecorder" 2>/dev/null && \
    hdiutil detach /tmp/QuickRecorderDMG 2>/dev/null || true
fi

if [ -f "$DMG_PATH" ]; then
    SIZE=$(du -h "$DMG_PATH" | cut -f1)
    echo "✅ DMG created: $DMG_NAME ($SIZE)"
else
    echo "❌ Failed to create DMG"
    exit 1
fi
