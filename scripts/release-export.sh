#!/bin/bash
# QuickRecorder release build + export script

set -euo pipefail

echo "🚀 Release Build + Export..."
echo ""

echo "Building Release configuration..."

# Capture exit code properly
set +o pipefail
xcodebuild build \
    -project QuickRecorder.xcodeproj \
    -scheme QuickRecorder \
    -destination "platform=macOS" \
    -configuration Release \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="-"
BUILD_RESULT=${PIPESTATUS[0]}
set -o pipefail

if [ "$BUILD_RESULT" -ne 0 ]; then
    echo ""
    echo "❌ Build failed. Cannot export."
    exit "$BUILD_RESULT"
fi

echo ""

echo "Finding .app..."
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "QuickRecorder.app" -type d -path "*/Release/*" 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "❌ Could not find QuickRecorder.app"
    echo "   Expected location: ~/Library/Developer/Xcode/DerivedData/.../Release/QuickRecorder.app"
    exit 1
fi

# Export to same location where Xcode built the .app
DEST_DIR="$(dirname "$APP_PATH")/exported"
mkdir -p "$DEST_DIR"
DEST="$DEST_DIR/QuickRecorder.app"

echo "Copying to build directory..."
cp -R "$APP_PATH" "$DEST"
SIZE=$(du -h "$DEST" | cut -f1)

echo "✅ Exported to: $DEST ($SIZE)"

