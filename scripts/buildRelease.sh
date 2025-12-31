#!/bin/bash
#
#  QuickRecorder Release Build Script
#  Builds and optionally exports a release .dmg or .app
#
#  Usage:
#    ./buildRelease.sh              # Release build
#    ./buildRelease.sh --archive    # Build + archive (Xcode Organizer)
#    ./buildRelease.sh --notarize   # Build + archive + notarize (secure: Keychain + Touch ID)
#    ./buildRelease.sh --export     # Build + export .app to Desktop
#
#  Secure Notarization Setup:
#    1. Create App-Specific Password at: https://appleid.apple.com/account/manage
#    2. Store in Keychain:
#       security add-internet-password \
#         -s "hisgarden" \
#         -a "your@email.com" \
#         -w "xxxx-xxxx-xxxx-xxxx" \
#         -T "/Applications/Xcode.app/Contents/Applications/Application Loader.app"
#    3. Run with --secure flag:
#       ./buildRelease.sh --notarize --secure
#
#  Requirements:
#    - XcodeGen must be installed
#    - Xcode project must be generated
#    - For notarization: Apple Developer account
#

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

PROJECT_NAME="QuickRecorder"
BUILD_DIR="build"
RELEASE_DIR="release"

# =============================================================================
# Secure Credential Functions (Keychain + Touch ID/Watch)
# =============================================================================

# Get Apple ID from Keychain securely
get_apple_id() {
    if [ "$SECURE" = true ]; then
        security find-internet-password -s "hisgarden" -a "appleid" -g 2>/dev/null | \
        grep "acct" | sed 's/.*"\(.*\)".*/\1/'
    else
        echo "$APPLE_ID"
    fi
}

# Get App-Specific Password from Keychain securely (prompts Touch ID/Apple Watch)
get_app_password() {
    if [ "$SECURE" = true ]; then
        # This command will prompt with Touch ID or Apple Watch
        # The -T flag specifies trusted application, leaving empty allows system prompt
        security find-internet-password -s "hisgarden" -a "notarize" -w 2>/dev/null
    else
        echo "$APPLE_ID_PASSWORD"
    fi
}

# Setup Keychain credentials (run once)
setup_keychain() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔐 Secure Keychain Setup${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    echo "This will store your Apple ID and app-specific password in Keychain."
    echo "Access will require Touch ID or Apple Watch approval.\n"
    
    read -p "Enter your Apple ID email: " APPLE_ID_INPUT
    read -p "Enter your App-Specific Password: " APPLE_PASSWORD_INPUT
    
    echo ""
    echo "Storing Apple ID in Keychain..."
    security add-internet-password \
        -s "hisgarden" \
        -a "appleid" \
        -r "http" \
        -w "$APPLE_ID_INPUT" \
        -T "" \
        -U
    
    echo "Storing App-Specific Password in Keychain..."
    security add-internet-password \
        -s "hisgarden" \
        -a "notarize" \
        -r "http" \
        -w "$APPLE_PASSWORD_INPUT" \
        -T "" \
        -U
    
    echo ""
    echo -e "${GREEN}✓${NC} Credentials stored securely in Keychain!"
    echo "You will be prompted with Touch ID or Apple Watch when notarizing."
}

# Check if Keychain credentials exist
check_keychain_credentials() {
    if [ "$SECURE" = true ]; then
        security find-internet-password -s "hisgarden" -a "appleid" > /dev/null 2>&1 && \
        security find-internet-password -s "hisgarden" -a "notarize" > /dev/null 2>&1
    fi
}

# =============================================================================
# Argument Parsing
# =============================================================================

# Parse arguments
ARCHIVE=false
NOTARIZE=false
EXPORT=false
SECURE=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --archive|-a)
            ARCHIVE=true
            shift
            ;;
        --notarize|-n)
            ARCHIVE=true
            NOTARIZE=true
            shift
            ;;
        --secure|-s)
            SECURE=true
            shift
            ;;
        --setup-keychain)
            setup_keychain
            exit 0
            ;;
        --export|-e)
            EXPORT=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --help|-h)
            echo "QuickRecorder Release Build Script"
            echo ""
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --archive, -a        Create archive (Xcode Organizer)"
            echo "  --notarize, -n       Create archive + notarize"
            echo "  --secure, -s         Use Keychain + Touch ID/Watch for credentials"
            echo "  --setup-keychain     Setup secure Keychain credentials (run once)"
            echo "  --export, -e         Export .app to Desktop"
            echo "  --verbose, -v        Verbose output"
            echo "  --help, -h           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                    # Release build only"
            echo "  $0 --archive          # Build + archive"
            echo "  $0 --notarize --secure  # Full secure build + notarize"
            echo ""
            echo "Secure Notarization (Recommended):"
            echo "  1. Create App-Specific Password: https://appleid.apple.com/account/manage"
            echo "  2. Setup Keychain: ./buildRelease.sh --setup-keychain"
            echo "  3. Notarize: ./buildRelease.sh --notarize --secure"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo -e "${CYAN}"
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                                                   ║"
echo "║   🚀 QuickRecorder - Release Build                 ║"
echo "║                                                   ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Check prerequisites
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Prerequisites Check${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

# Check XcodeGen
if ! command -v xcodegen &> /dev/null; then
    echo -e "${YELLOW}⚠️  XcodeGen not found. Running setup...${NC}"
    if command -v brew &> /dev/null; then
        brew install xcodegen
    else
        echo -e "${RED}❌ Homebrew not found. Please install XcodeGen manually.${NC}"
        exit 1
    fi
fi

# Check project exists
if [ ! -d "$PROJECT_NAME.xcodeproj" ]; then
    echo -e "${YELLOW}⚠️  Xcode project not found. Generating...${NC}"
    xcodegen generate
fi

# Clean previous builds
echo -e "${GREEN}✓${NC} Cleaning previous builds..."
rm -rf "$BUILD_DIR"
rm -rf "$RELEASE_DIR"

# Build Release
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}🔨 Building Release (Configuration: Release)${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if xcodebuild build \
    -project "$PROJECT_NAME.xcodeproj" \
    -scheme "$PROJECT_NAME" \
    -destination 'platform=macOS' \
    -configuration Release \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="-" \
    2>&1 | tee "$BUILD_DIR/build.log"; then
    echo -e "\n${GREEN}✓${NC} Release build successful!"
else
    echo -e "\n${RED}❌ Release build failed${NC}"
    echo -e "${YELLOW}Check $BUILD_DIR/build.log for details${NC}"
    exit 1
fi

# Get build products path
BUILD_PRODUCTS=$(xcodebuild -project "$PROJECT_NAME.xcodeproj" -scheme "$PROJECT_NAME" -configuration Release -showBuildSettings 2>/dev/null | grep " BUILD_DIR =" | head -1 | cut -d '=' -f2 | tr -d ' ')
APP_PATH="$BUILD_PRODUCTS/$PROJECT_NAME.app"

echo -e "\n${GREEN}✓${NC} Build artifacts:"
echo "  App: $APP_PATH"
echo "  Size: $(du -h "$APP_PATH" | cut -f1)"

# Archive if requested
if [ "$ARCHIVE" = true ]; then
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📦 Creating Archive${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    ARCHIVE_PATH="archive/$PROJECT_NAME-$(date +%Y%m%d-%H%M).xcarchive"
    
    if xcodebuild archive \
        -project "$PROJECT_NAME.xcodeproj" \
        -scheme "$PROJECT_NAME" \
        -destination 'platform=macOS' \
        -configuration Release \
        CODE_SIGNING_ALLOWED=NO \
        CODE_SIGNING_REQUIRED=NO \
        ARCHIVE_PATH="$ARCHIVE_PATH"; then
        echo -e "\n${GREEN}✓${NC} Archive created: $ARCHIVE_PATH"
    else
        echo -e "\n${RED}❌ Archive failed${NC}"
        exit 1
    fi
    
    # Notarize if requested
    if [ "$NOTARIZE" = true ]; then
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}🔏 Notarization${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
        
        if [ "$SECURE" = true ]; then
            # Secure mode: Use Keychain with Touch ID/Apple Watch
            echo "🔐 Retrieving credentials from Keychain..."
            echo "(You may be prompted for Touch ID or Apple Watch)\n"
            
            APPLE_ID=$(get_apple_id)
            APPLE_ID_PASSWORD=$(get_app_password)
            
            if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
                echo -e "${RED}❌ Keychain credentials not found${NC}"
                echo "Run './buildRelease.sh --setup-keychain' first to configure secure credentials."
                exit 1
            fi
        else
            # Standard mode: Use environment variables
            if [ -z "$APPLE_ID" ] || [ -z "$APPLE_ID_PASSWORD" ]; then
                echo -e "${RED}❌ APPLE_ID and APPLE_ID_PASSWORD environment variables required${NC}"
                echo "Run with --secure flag to use Keychain, or set:"
                echo "  export APPLE_ID=\"your@email.com\""
                echo "  export APPLE_ID_PASSWORD=\"app-specific-password\""
                exit 1
            fi
        fi
        
        echo "📤 Submitting for notarization..."
        xcrun altool --notarize-app \
            --primary-bundle-id "dev.hisgarden.QuickRecorder" \
            --username "$APPLE_ID" \
            --password "$APPLE_ID_PASSWORD" \
            --file "$ARCHIVE_PATH" \
            --output-format json | tee archive/notarization.json
        
        REQUEST_UUID=$(cat archive/notarization.json | python3 -c "import sys, json; print(json.load(sys.stdin).get('requestUUID', ''))" 2>/dev/null || echo "")
        
        if [ -n "$REQUEST_UUID" ]; then
            echo ""
            echo -e "${GREEN}✓${NC} Notarization submitted successfully!"
            echo "Request UUID: $REQUEST_UUID"
            echo ""
            echo "To check status:"
            echo "  xcrun altool --notarization-info $REQUEST_UUID -u $APPLE_ID -p <password>"
            echo ""
            echo "After approval, staple the ticket:"
            echo "  xcrun stapler staple $ARCHIVE_PATH"
        else
            echo -e "${RED}❌ Failed to get Request UUID${NC}"
            exit 1
        fi
    fi
fi

# Export if requested
if [ "$EXPORT" = true ]; then
    echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}📤 Exporting Application${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
    
    DEST_DIR="$HOME/Desktop/release"
    mkdir -p "$DEST_DIR"
    
    # Find latest release build
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "QuickRecorder.app" -type d -path "*/Release/*" 2>/dev/null | head -1)
    
    if [ -z "$APP_PATH" ]; then
        echo -e "${RED}❌ No Release build found in DerivedData${NC}"
        exit 1
    fi
    
    cp -R "$APP_PATH" "$DEST/"
    SIZE=$(du -h "$DEST/QuickRecorder.app" | cut -f1)
    echo -e "${GREEN}✓${NC} Exported: $DEST/QuickRecorder.app ($SIZE)"
fi

echo -e "\n${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ✅ Build Complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
