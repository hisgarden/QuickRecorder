#!/bin/bash
#
#  QuickRecorder Release Build Script
#  Builds and optionally exports a release .dmg or .app
#
#  Usage:
#    ./buildRelease.sh              # Release build
#    ./buildRelease.sh --archive    # Build + archive (Xcode Organizer)
#    ./buildRelease.sh --notarize   # Build + archive + notarize via Keychain (Touch ID prompt)
#    ./buildRelease.sh --export     # Build + export .app to Desktop
#
#  One-time setup (per machine):
#    ./buildRelease.sh --setup-keychain
#      Stores Apple ID + Team ID + App-Specific Password in macOS Keychain via
#      `xcrun notarytool store-credentials` under profile QuickRecorder-notarize.
#      Touch ID / passcode prompts on every subsequent notarytool access.
#
#  Requirements:
#    - XcodeGen installed
#    - Xcode project generated
#    - Xcode 13+ (for `xcrun notarytool`)
#    - Apple Developer account (for notarization)
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
KEYCHAIN_PROFILE="QuickRecorder-notarize"

# =============================================================================
# Keychain Profile Setup (notarytool-native)
# =============================================================================

# Store Apple ID + Team ID + App-Specific Password in macOS Keychain via
# `xcrun notarytool store-credentials`. Run once per machine. Touch ID /
# passcode is prompted by macOS on every subsequent notarytool access; the
# password value never enters shell variable scope.
setup_keychain() {
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BLUE}🔐 Keychain Profile Setup (${KEYCHAIN_PROFILE})${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""

    if ! xcrun notarytool --version >/dev/null 2>&1; then
        echo -e "${RED}❌ xcrun notarytool not available. Requires Xcode 13+.${NC}"
        exit 1
    fi

    # Read Apple ID + Team ID from .env if present, otherwise prompt.
    if [ -f ".env" ]; then
        # shellcheck disable=SC1091
        source .env 2>/dev/null || true
    fi

    if [ -z "${APPLE_ID:-}" ]; then
        read -p "Apple ID email: " APPLE_ID
    else
        echo "Apple ID:    $APPLE_ID  (from .env)"
    fi

    if [ -z "${APPLE_TEAM_ID:-}" ]; then
        read -p "Apple Team ID (10-char alphanumeric): " APPLE_TEAM_ID
    else
        echo "Team ID:     $APPLE_TEAM_ID  (from .env)"
    fi

    echo ""
    echo "notarytool will now prompt for your App-Specific Password and store"
    echo "the credential bundle in macOS Keychain under profile:"
    echo "  $KEYCHAIN_PROFILE"
    echo ""
    echo "Generate one at: https://appleid.apple.com/account/manage"
    echo ""

    if xcrun notarytool store-credentials "$KEYCHAIN_PROFILE" \
        --apple-id "$APPLE_ID" \
        --team-id "$APPLE_TEAM_ID"; then
        echo ""
        echo -e "${GREEN}✓${NC} Keychain profile '$KEYCHAIN_PROFILE' configured."
        echo "Verify with: xcrun notarytool history --keychain-profile $KEYCHAIN_PROFILE"
    else
        echo ""
        echo -e "${RED}❌ Failed to store credentials.${NC}"
        exit 1
    fi
}

# =============================================================================
# Argument Parsing
# =============================================================================

# Parse arguments
ARCHIVE=false
NOTARIZE=false
EXPORT=false
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
            echo "  --notarize, -n       Create archive + notarize via Keychain (Touch ID prompt)"
            echo "  --setup-keychain     One-time: store credentials in Keychain via notarytool"
            echo "  --export, -e         Export .app to Desktop"
            echo "  --verbose, -v        Verbose output"
            echo "  --help, -h           Show this help"
            echo ""
            echo "Examples:"
            echo "  $0                    # Release build only"
            echo "  $0 --archive          # Build + archive"
            echo "  $0 --notarize         # Build + archive + notarize (uses Keychain)"
            echo ""
            echo "First-time setup:"
            echo "  1. Create App-Specific Password: https://appleid.apple.com/account/manage"
            echo "  2. Run: ./scripts/buildRelease.sh --setup-keychain"
            echo "     Stores credentials in macOS Keychain under profile QuickRecorder-notarize"
            echo "  3. From now on: ./scripts/buildRelease.sh --notarize"
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
    
    # Notarize if requested -- delegate to scripts/notarize.sh, which uses
    # the canonical xcrun notarytool + --keychain-profile flow.
    if [ "$NOTARIZE" = true ]; then
        echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BLUE}🔏 Notarization (via scripts/notarize.sh)${NC}"
        echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

        if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
            echo -e "${RED}❌ Keychain profile '$KEYCHAIN_PROFILE' not found.${NC}"
            echo "Run: ./scripts/buildRelease.sh --setup-keychain"
            exit 1
        fi

        if ! bash scripts/notarize.sh "$APP_PATH"; then
            echo -e "${RED}❌ Notarization failed${NC}"
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
