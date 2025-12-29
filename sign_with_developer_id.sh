#!/bin/bash
set -e

# This script will work once you have "Developer ID Application" certificate
# Get it from: https://developer.apple.com/account/resources/certificates/list

APP="QuickRecorder_Distribution.app"
CERT="Developer ID Application: Jin Wen (NSDC3EDS2G)"
ENTITLEMENTS="QuickRecorder/QuickRecorder.entitlements"

echo "========================================="
echo "Developer ID Signing for Notarization"
echo "========================================="
echo ""

# Check if certificate exists
if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
    echo "❌ ERROR: Developer ID Application certificate not found!"
    echo ""
    echo "You currently have:"
    security find-identity -v -p codesigning
    echo ""
    echo "You need to create 'Developer ID Application' certificate at:"
    echo "https://developer.apple.com/account/resources/certificates/list"
    echo ""
    echo "See NOTARIZATION_FIX.md for detailed instructions."
    exit 1
fi

echo "✓ Developer ID certificate found"
echo ""

# Remove ALL signatures
echo "Step 1: Removing existing signatures..."
find "$APP" -type d \( -name "*.app" -or -name "*.framework" -or -name "*.xpc" \) | sort -r | while read bundle; do
    codesign --remove-signature "$bundle" 2>/dev/null || true
done
echo "  ✓ Signatures removed"
echo ""

# Sign everything
echo "Step 2: Signing with Developer ID..."

# Sparkle components
echo "  → Signing Sparkle components..."
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

# XPC services
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Downloader.xpc"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/XPCServices/Installer.xpc"

# Updater app
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B/Updater.app"

# Framework
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework/Versions/B"
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/Frameworks/Sparkle.framework"

# Main app
echo "  → Signing main application..."
codesign --force --sign "$CERT" --options runtime --timestamp \
    "$APP/Contents/MacOS/QuickRecorder"
codesign --force --sign "$CERT" --options runtime --timestamp --entitlements "$ENTITLEMENTS" \
    "$APP"

echo "  ✓ Signing complete"
echo ""

# Verify
echo "Step 3: Verifying signatures..."
codesign --verify --deep --strict --verbose=2 "$APP"
echo ""

echo "========================================="
echo "✅ Success! App signed with Developer ID"
echo "========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Create zip for notarization:"
echo "   ditto -c -k --keepParent $APP QuickRecorder_Distribution.zip"
echo ""
echo "2. Submit for notarization:"
echo "   xcrun notarytool submit QuickRecorder_Distribution.zip \\"
echo "     --keychain-profile notary-profile --wait"
echo ""
echo "3. If successful, staple the ticket:"
echo "   xcrun stapler staple $APP"
echo ""
echo "4. Verify Gatekeeper approval:"
echo "   spctl -a -vv $APP"
echo ""
echo "5. Create DMG for distribution:"
echo "   hdiutil create -volname \"QuickRecorder\" \\"
echo "     -srcfolder $APP -ov -format UDZO QuickRecorder.dmg"
