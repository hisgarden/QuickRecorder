#!/bin/bash
# Complete notarization script for QuickRecorder.
#
# Credentials live in macOS Keychain under profile QuickRecorder-notarize,
# stored once via `xcrun notarytool store-credentials`. macOS prompts for
# Touch ID / passcode on every notarytool invocation; the App-Specific
# Password value never enters this script's variable scope.
#
# One-time setup: ./scripts/buildRelease.sh --setup-keychain

set -euo pipefail

KEYCHAIN_PROFILE="QuickRecorder-notarize"

# Verify notarytool is available (Xcode 13+).
verify_notarytool() {
    if ! command -v xcrun &> /dev/null; then
        echo "❌ xcrun not found. Please install Xcode."
        exit 1
    fi

    if ! xcrun notarytool --version &> /dev/null; then
        echo "❌ notarytool not found. Please update Xcode (requires Xcode 13+)."
        exit 1
    fi
}

# Verify the keychain profile resolves; bail with a clear pointer if not.
verify_keychain_profile() {
    if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
        echo "❌ Keychain profile '$KEYCHAIN_PROFILE' not found or unreadable."
        echo ""
        echo "Run: ./scripts/buildRelease.sh --setup-keychain"
        echo ""
        echo "This stores your Apple ID + Team ID + App-Specific Password in"
        echo "macOS Keychain via xcrun notarytool store-credentials. Touch ID"
        echo "or passcode prompts on every notarytool access."
        exit 1
    fi
}

# Load .env solely for APPLE_TEAM_ID, used during xcodebuild export plist
# generation. APPLE_ID and the password are never read from env -- notarytool
# resolves them from Keychain via --keychain-profile.
load_env_for_team_id() {
    if [ -f ".env" ]; then
        # shellcheck disable=SC1091
        source .env 2>/dev/null || true
    fi
}

# Main notarization flow.
main() {
    echo "🔏 Notarization Workflow"
    echo ""

    # Step 1: Verify prerequisites.
    verify_notarytool
    echo "✅ notarytool available"

    verify_keychain_profile
    echo "✅ Keychain profile '$KEYCHAIN_PROFILE' resolves"

    load_env_for_team_id
    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        echo "❌ APPLE_TEAM_ID not set in .env or environment."
        echo "   Required for code-sign export plist generation."
        exit 1
    fi
    echo "   Team ID:    $APPLE_TEAM_ID  (from .env)"
    echo ""

    # Step 2: Validate credentials by fetching submission history.
    # macOS Keychain prompts for Touch ID / passcode here.
    echo "🔐 Validating credentials (Touch ID prompt expected)..."
    if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
        echo "❌ Credential validation failed. The keychain profile may be"
        echo "   storing an invalid or revoked App-Specific Password."
        echo "   Re-run: ./scripts/buildRelease.sh --setup-keychain"
        exit 1
    fi
    echo "✅ Credentials validated"
    echo ""

    # Step 3: Build and archive.
    echo "📦 Building & archiving (2-3 minutes)..."

    mkdir -p archive

    ARCHIVE_PATH="archive/QuickRecorder-$(date +%Y%m%d-%H%M).xcarchive"
    BUILD_LOG="archive/build-$(date +%Y%m%d-%H%M).log"

    if ! xcodebuild archive \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -configuration Release \
        -archivePath "$ARCHIVE_PATH" \
        OTHER_CODE_SIGN_FLAGS="--timestamp" \
        ENABLE_HARDENED_RUNTIME=YES \
        > "$BUILD_LOG" 2>&1; then
        echo "❌ Build failed"
        echo ""
        echo "Build log: $BUILD_LOG"
        echo ""
        echo "Last errors in build log:"
        tail -20 "$BUILD_LOG" | grep -E "error:|warning:" || tail -20 "$BUILD_LOG"
        echo ""
        echo "Full log: cat $BUILD_LOG"
        echo ""
        echo "Common fixes:"
        echo "  1. Check: xcodegen generate"
        echo "  2. Check: project.yml has DEVELOPMENT_TEAM set"
        echo "  3. Check: CODE_SIGN_STYLE is Manual"
        echo "  4. Verify certificate: security find-identity -v -p codesigning"
        exit 1
    fi

    echo "✅ Archive created"

    # Step 4: Export with Developer ID signing.
    EXPORT_DIR="archive/export-$(date +%Y%m%d-%H%M)"
    EXPORT_OPTIONS_PLIST="archive/ExportOptions.plist"

    cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>${APPLE_TEAM_ID}</string>
    <key>uploadSymbols</key>
    <false/>
    <key>compileBitcode</key>
    <false/>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>generateAppStoreInformation</key>
    <false/>
</dict>
</plist>
EOF

    echo "📤 Exporting with Developer ID signing..."
    if ! xcodebuild -exportArchive \
        -archivePath "$ARCHIVE_PATH" \
        -exportPath "$EXPORT_DIR" \
        -exportOptionsPlist "$EXPORT_OPTIONS_PLIST" \
        > "$BUILD_LOG.export" 2>&1; then
        echo "❌ Export failed"
        echo ""
        echo "Export log: $BUILD_LOG.export"
        tail -30 "$BUILD_LOG.export"
        exit 1
    fi

    EXPORT_PATH="$EXPORT_DIR/QuickRecorder.app"

    if [ ! -d "$EXPORT_PATH" ]; then
        echo "❌ Exported app not found at: $EXPORT_PATH"
        ls -la "$EXPORT_DIR"
        exit 1
    fi

    echo "✅ Exported with Developer ID signing"

    # Step 5: Strip AppleDouble metadata that breaks the code signature.
    echo "🧹 Cleaning AppleDouble files..."
    find "$EXPORT_PATH" -name "._*" -type f -delete 2>/dev/null || true

    # Step 6: Zip for upload (--norsrc avoids resource forks).
    ZIP_PATH="archive/QuickRecorder-$(date +%Y%m%d-%H%M).zip"

    if ! ditto -c -k --norsrc --keepParent "$EXPORT_PATH" "$ZIP_PATH"; then
        echo "❌ Failed to create zip"
        exit 1
    fi

    ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
    echo "✅ Ready for notarization ($ZIP_SIZE)"
    echo ""

    # Step 7: Submit for notarization.
    # macOS Keychain may prompt for Touch ID again here.
    echo "🔏 Submitting to Apple..."
    echo "   Uploading... (waiting for response)"

    xcrun notarytool submit "$ZIP_PATH" \
        --keychain-profile "$KEYCHAIN_PROFILE" \
        --wait \
        --output-format json > archive/notarization.json 2>&1

    # Step 8: Parse response and act on status.
    if [ ! -f archive/notarization.json ]; then
        echo "❌ No response from Apple"
        exit 1
    fi

    STATUS=$(grep -o '"status":"[^"]*"' archive/notarization.json | head -1 | cut -d'"' -f4)
    SUBMISSION_ID=$(grep -o '"id":"[^"]*"' archive/notarization.json | head -1 | cut -d'"' -f4)
    MESSAGE=$(grep -o '"message":"[^"]*"' archive/notarization.json | head -1 | cut -d'"' -f4)

    if [ "$STATUS" = "Accepted" ]; then
        echo "   ✅ Approved!"
        [ -n "$SUBMISSION_ID" ] && echo "   Submission: $SUBMISSION_ID"
        echo ""

        echo "🔖 Stapling ticket..."
        if xcrun stapler staple "$EXPORT_PATH" 2>&1 | grep -q "Successfully"; then
            echo "✅ Stapled"
        else
            echo "⚠️  Stapling warning (app still notarized)"
        fi

        echo ""
        echo "✅ READY FOR DISTRIBUTION"
        echo "   App:  $EXPORT_PATH"
        echo "   Zip:  $ZIP_PATH"
        echo "   Size: $ZIP_SIZE"
        echo ""
        echo "Next steps:"
        echo "  1. Create .dmg: hdiutil create -volname QuickRecorder -srcfolder \"$EXPORT_PATH\" QuickRecorder.dmg"
        echo "  2. Distribute to users"

    elif [ "$STATUS" = "Invalid" ]; then
        echo "   ❌ REJECTED"
        [ -n "$SUBMISSION_ID" ] && echo "   Submission: $SUBMISSION_ID"
        echo ""
        echo "📋 View detailed errors:"
        echo "   xcrun notarytool log \"$SUBMISSION_ID\" --keychain-profile $KEYCHAIN_PROFILE"
        echo ""
        echo "Common issues:"
        echo "  • Binaries not signed with Developer ID certificate"
        echo "  • Missing hardened runtime"
        echo "  • No timestamp on signature"
        echo "  • Unsigned third-party frameworks"
        exit 1

    elif [ "$STATUS" = "In Progress" ]; then
        echo "   ⏳ Still processing..."
        [ -n "$SUBMISSION_ID" ] && echo "   Submission: $SUBMISSION_ID"
        echo ""
        echo "Check status manually:"
        echo "   xcrun notarytool log \"$SUBMISSION_ID\" --keychain-profile $KEYCHAIN_PROFILE"
        exit 1

    else
        echo "   ❌ FAILED"
        [ -n "$STATUS" ] && echo "   Status: $STATUS"
        [ -n "$MESSAGE" ] && echo "   Message: $MESSAGE"
        [ -n "$SUBMISSION_ID" ] && echo "   Submission: $SUBMISSION_ID"
        echo ""
        echo "Full response:"
        python3 -m json.tool < archive/notarization.json 2>/dev/null || cat archive/notarization.json
        echo ""
        echo "Get more details:"
        echo "   xcrun notarytool log \"$SUBMISSION_ID\" --keychain-profile $KEYCHAIN_PROFILE"
        exit 1
    fi
}

main
