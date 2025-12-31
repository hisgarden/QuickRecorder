#!/bin/bash
# Complete notarization script for QuickRecorder

set -e

# Get Apple ID from Keychain
get_apple_id() {
    security find-internet-password -s "hisgarden" -a "appleid" -g 2>/dev/null | \
    grep "acct" | sed 's/.*"\(.*\)".*/\1/' || echo ""
}

# Get App-Specific Password from Keychain (prompts Touch ID/Apple Watch)
get_password() {
    security find-internet-password -s "hisgarden" -a "notarize" -w 2>/dev/null || echo ""
}

# Get credentials from various sources
get_credentials() {
    local source=""
    local apple_id=""
    local password=""
    
    # Try Keychain first
    apple_id=$(get_apple_id)
    password=$(get_password)
    
    if [ -n "$apple_id" ] && [ -n "$password" ]; then
        source="Keychain"
        echo "$source|$apple_id|$password"
        return 0
    fi
    
    # Try .env file
    if [ -f ".env" ]; then
        set -a
        # shellcheck disable=SC1091
        source .env 2>/dev/null || true
        set +a
        
        if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ]; then
            source=".env file"
            echo "$source|$APPLE_ID|$APP_SPECIFIC_PASSWORD"
            return 0
        fi
    fi
    
    # Try environment variables
    if [ -n "$APPLE_ID" ] && [ -n "$APP_SPECIFIC_PASSWORD" ]; then
        source="environment variables"
        echo "$source|$APPLE_ID|$APP_SPECIFIC_PASSWORD"
        return 0
    fi
    
    # No credentials found
    echo "error|||"
    return 1
}

# Verify notarytool is available
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

# Main notarization flow
main() {
    echo "🔏 Notarization Workflow"
    echo ""
    
    # Step 1: Verify prerequisites
    verify_notarytool
    
    # Step 2: Verify credentials
    CREDS=$(bash scripts/credentials.sh verify)
    
    if [ -z "$CREDS" ] || [[ "$CREDS" == "error"* ]]; then
        echo "❌ Credentials not found"
        echo ""
        echo "Setup options:"
        echo "  1. Keychain: ./buildRelease.sh --setup-keychain"
        echo "  2. Interactive: Run 'just notarize' and enter app-specific password"
        echo "  3. Environment: export APPLE_ID and APP_SPECIFIC_PASSWORD"
        exit 1
    fi
    
    SOURCE=$(echo "$CREDS" | cut -d'|' -f1)
    APPLE_ID=$(echo "$CREDS" | cut -d'|' -f2)
    APP_SPECIFIC_PASSWORD=$(echo "$CREDS" | cut -d'|' -f3)
    APPLE_TEAM_ID=$(echo "$CREDS" | cut -d'|' -f4)
    
    if [ "$SOURCE" = "error" ] || [ -z "$APPLE_ID" ] || [ -z "$APP_SPECIFIC_PASSWORD" ]; then
        echo "❌ Credential validation failed"
        exit 1
    fi
    
    echo "✅ Prerequisites verified"
    echo "   Apple ID: $APPLE_ID"
    [ -n "$APPLE_TEAM_ID" ] && echo "   Team ID: $APPLE_TEAM_ID"
    echo ""
    
    # Step 3: Test credentials with Apple
    echo "🔐 Testing credentials..."
    TEST_OUTPUT=$(mktemp)
    TEST_RESULT=0
    
    if [ -n "$APPLE_TEAM_ID" ]; then
        xcrun notarytool history \
            --apple-id "$APPLE_ID" \
            --password "$APP_SPECIFIC_PASSWORD" \
            --team-id "$APPLE_TEAM_ID" \
            > "$TEST_OUTPUT" 2>&1 || TEST_RESULT=$?
    else
        xcrun notarytool history \
            --apple-id "$APPLE_ID" \
            --password "$APP_SPECIFIC_PASSWORD" \
            > "$TEST_OUTPUT" 2>&1 || TEST_RESULT=$?
    fi
    
    if [ $TEST_RESULT -ne 0 ]; then
        echo "❌ Credential test failed"
        echo ""
        echo "Error:"
        cat "$TEST_OUTPUT"
        rm -f "$TEST_OUTPUT"
        exit 1
    fi
    
    rm -f "$TEST_OUTPUT"
    echo "✅ Credentials validated"
    echo ""
    
    # Step 4: Verify code signing configuration
    echo "🔑 Checking code signing configuration..."
    
    # If we have APPLE_TEAM_ID set, that's enough - Xcode will find the right certificate
    if [ -n "$APPLE_TEAM_ID" ]; then
        echo "✅ Code signing configured"
        echo "   Team ID: $APPLE_TEAM_ID"
        echo ""
    else
        echo "⚠️  No team ID found - will use default code signing identity"
        echo ""
    fi
    
    # Step 5: Build and archive
    echo "📦 Building & archiving (2-3 minutes)..."
    
    # Create archive directory
    mkdir -p archive
    
    # Build and archive
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
        
        # Show last 20 lines of log for quick diagnosis
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
    
    # Export app from archive using proper Xcode export
    EXPORT_DIR="archive/export-$(date +%Y%m%d-%H%M)"
    EXPORT_OPTIONS_PLIST="archive/ExportOptions.plist"
    
    # Create export options plist
    cat > "$EXPORT_OPTIONS_PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>NSDC3EDS2G</string>
    <key>signingCertificate</key>
    <string>Developer ID Application: Jin Wen (NSDC3EDS2G)</string>
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
    
    # The exported app will be in EXPORT_DIR/QuickRecorder.app
    EXPORT_PATH="$EXPORT_DIR/QuickRecorder.app"
    
    if [ ! -d "$EXPORT_PATH" ]; then
        echo "❌ Exported app not found at: $EXPORT_PATH"
        ls -la "$EXPORT_DIR"
        exit 1
    fi
    
    echo "✅ Exported with Developer ID signing"
    
    # Clean AppleDouble files (._* files) that break code signature
    echo "🧹 Cleaning AppleDouble files..."
    find "$EXPORT_PATH" -name "._*" -type f -delete 2>/dev/null || true
    
    # Create zip for notarization (using --norsrc to avoid resource forks)
    ZIP_PATH="archive/QuickRecorder-$(date +%Y%m%d-%H%M).zip"
    
    if ! ditto -c -k --norsrc --keepParent "$EXPORT_PATH" "$ZIP_PATH"; then
        echo "❌ Failed to create zip"
        exit 1
    fi
    
    ZIP_SIZE=$(du -h "$ZIP_PATH" | cut -f1)
    echo "✅ Ready for notarization ($ZIP_SIZE)"
    echo ""
    
    # Step 6: Submit for notarization
    echo "🔏 Submitting to Apple..."
    TEAM_ID="${APPLE_TEAM_ID:-}"
    
    NOTARY_LOG="archive/notary-$(date +%Y%m%d-%H%M).log"
    
    echo "   Uploading... (waiting for response)"
    
    if [ -n "$TEAM_ID" ]; then
        xcrun notarytool submit "$ZIP_PATH" \
            --apple-id "$APPLE_ID" \
            --password "$APP_SPECIFIC_PASSWORD" \
            --team-id "$TEAM_ID" \
            --wait \
            --output-format json > archive/notarization.json 2>&1
    else
        xcrun notarytool submit "$ZIP_PATH" \
            --apple-id "$APPLE_ID" \
            --password "$APP_SPECIFIC_PASSWORD" \
            --wait \
            --output-format json > archive/notarization.json 2>&1
    fi
    
    # Parse response
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
        
        # Staple the ticket
        echo "🔖 Stapling ticket..."
        if xcrun stapler staple "$EXPORT_PATH" 2>&1 | grep -q "Successfully"; then
            echo "✅ Stapled"
        else
            echo "⚠️  Stapling warning (app still notarized)"
        fi
        
        echo ""
        echo "✅ READY FOR DISTRIBUTION"
        echo "   App: $EXPORT_PATH"
        echo "   Zip: $ZIP_PATH"
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
        echo "   xcrun notarytool log \"$SUBMISSION_ID\" \\"
        echo "       --apple-id \"$APPLE_ID\" \\"
        echo "       --password \"<app-specific-password>\" \\"
        echo "       --team-id \"$TEAM_ID\""
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
        echo "   xcrun notarytool log \"$SUBMISSION_ID\" \\"
        echo "       --apple-id \"$APPLE_ID\" \\"
        echo "       --password \"<app-specific-password>\" \\"
        echo "       --team-id \"$TEAM_ID\""
        exit 1
        
    else
        echo "   ❌ FAILED"
        [ -n "$STATUS" ] && echo "   Status: $STATUS"
        [ -n "$MESSAGE" ] && echo "   Message: $MESSAGE"
        [ -n "$SUBMISSION_ID" ] && echo "   Submission: $SUBMISSION_ID"
        echo ""
        echo "Full response:"
        cat archive/notarization.json | python3 -m json.tool 2>/dev/null || cat archive/notarization.json
        echo ""
        echo "Get more details:"
        echo "   xcrun notarytool log \"$SUBMISSION_ID\" \\"
        echo "       --apple-id \"$APPLE_ID\" \\"
        echo "       --password \"<app-specific-password>\" \\"
        echo "       --team-id \"$TEAM_ID\""
        exit 1
    fi
}

# Run main
main

