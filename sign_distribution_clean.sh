#!/bin/bash
set -e

APP="QuickRecorder_Distribution.app"
CERT="Apple Distribution: Jin Wen (NSDC3EDS2G)"
ENTITLEMENTS="QuickRecorder/QuickRecorder.entitlements"

echo "========================================="
echo "Clean Distribution Signing for Notarization"
echo "========================================="
echo ""

# Step 1: Remove ALL signatures recursively
echo "Step 1: Removing ALL existing signatures..."
find "$APP" -type d \( -name "*.app" -or -name "*.framework" -or -name "*.xpc" \) | sort -r | while read bundle; do
    echo "  Removing signature: $bundle"
    codesign --remove-signature "$bundle" 2>/dev/null || true
done

# Also remove from individual binaries
find "$APP" -type f -perm +111 | while read binary; do
    if file "$binary" | grep -q "Mach-O"; then
        codesign --remove-signature "$binary" 2>/dev/null || true
    fi
done

echo "  ✓ All signatures removed"
echo ""

# Step 2: Sign from deepest to shallowest
echo "Step 2: Signing all components (deepest first)..."

# Sign individual Mach-O binaries in Sparkle first
echo "  → Signing Sparkle Mach-O binaries..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app/Contents/MacOS/Updater"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc/Contents/MacOS/Downloader"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc/Contents/MacOS/Installer"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Autoupdate"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Sparkle"

# Sign XPC services
echo "  → Signing XPC services..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc"

# Sign Updater.app
echo "  → Signing Updater.app..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app"

# Sign the framework itself (Version B)
echo "  → Signing Sparkle framework (Version B)..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B"

# Sign the framework root
echo "  → Signing Sparkle framework (root)..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework"

# Sign main app executable
echo "  → Signing main app executable..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/MacOS/QuickRecorder"

# Finally sign the main app bundle
echo "  → Signing main app bundle..."
codesign --force --sign "$CERT" --options runtime --timestamp --entitlements "$ENTITLEMENTS" \
    "$APP"

echo ""
echo "Step 3: Verifying signatures..."
echo "  → Main app..."
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 | head -20

echo ""
echo "  → Checking Updater binary specifically..."
codesign -dvvv "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app/Contents/MacOS/Updater" 2>&1 | grep -E "(Authority|Identifier|TeamIdentifier)"

echo ""
echo "========================================="
echo "✅ Signing Complete!"
echo "========================================="
echo "Certificate: $CERT"
echo "App: $APP"
echo ""
echo "Next steps:"
echo "1. Create zip: ditto -c -k --keepParent $APP QuickRecorder_Distribution.zip"
echo "2. Submit: xcrun notarytool submit QuickRecorder_Distribution.zip --keychain-profile notary-profile --wait"
