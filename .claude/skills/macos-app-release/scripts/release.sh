#!/bin/bash
set -e

# Automated macOS App Release Script
# This script is designed to be used with the macos-app-release Claude Skill

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
info() { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }

# Parse command line arguments
VERSION=""
APP_NAME=""
CERT_IDENTITY=""
ENTITLEMENTS=""
NOTARY_PROFILE="notary-profile"
SKIP_BUILD=false
SKIP_NOTARIZE=false
SKIP_RELEASE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --version)
            VERSION="$2"
            shift 2
            ;;
        --app-name)
            APP_NAME="$2"
            shift 2
            ;;
        --cert)
            CERT_IDENTITY="$2"
            shift 2
            ;;
        --entitlements)
            ENTITLEMENTS="$2"
            shift 2
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --skip-notarize)
            SKIP_NOTARIZE=true
            shift
            ;;
        --skip-release)
            SKIP_RELEASE=true
            shift
            ;;
        --help)
            echo "Usage: $0 --version VERSION --app-name APP_NAME --cert CERT_IDENTITY --entitlements PATH"
            echo ""
            echo "Options:"
            echo "  --version         Release version (e.g., 1.7.3)"
            echo "  --app-name        Application name (e.g., QuickRecorder)"
            echo "  --cert            Code signing identity"
            echo "  --entitlements    Path to entitlements file"
            echo "  --skip-build      Skip build phase"
            echo "  --skip-notarize   Skip notarization phase"
            echo "  --skip-release    Skip GitHub release phase"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            ;;
    esac
done

# Validate required parameters
[[ -z "$VERSION" ]] && error "Version is required (--version)"
[[ -z "$APP_NAME" ]] && error "App name is required (--app-name)"

APP="${APP_NAME}.app"

echo "========================================="
echo "${APP_NAME} Release Script v${VERSION}"
echo "========================================="
echo ""

# Phase 1: Build
if [[ "$SKIP_BUILD" == false ]]; then
    info "Phase 1: Building application..."
    
    if [[ -f "${APP_NAME}.xcodeproj/project.pbxproj" ]]; then
        xcodebuild -project "${APP_NAME}.xcodeproj" \
            -scheme "${APP_NAME}" \
            -configuration Release \
            -derivedDataPath ./build \
            build || error "Build failed"
        
        cp -R "./build/Build/Products/Release/${APP}" . || error "Failed to copy app bundle"
        info "Build complete: ${APP}"
    else
        warn "No Xcode project found, skipping build"
    fi
else
    info "Phase 1: Skipping build (--skip-build)"
fi

# Verify app exists
[[ ! -d "$APP" ]] && error "Application bundle not found: ${APP}"

# Phase 2: Code Signing
if [[ -n "$CERT_IDENTITY" ]]; then
    info "Phase 2: Code signing..."
    
    # Check if certificate exists
    if ! security find-identity -v -p codesigning | grep -q "Developer ID Application"; then
        error "Developer ID Application certificate not found"
    fi
    
    # Remove existing signatures
    find "$APP" -type d \( -name "*.app" -or -name "*.framework" -or -name "*.xpc" \) | \
        sort -r | while read bundle; do
        codesign --remove-signature "$bundle" 2>/dev/null || true
    done
    
    # Sign nested components
    find "$APP" -type f \( -name "*.dylib" -o -perm +111 \) | while read binary; do
        if file "$binary" | grep -q "Mach-O"; then
            codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp "$binary" 2>/dev/null || true
        fi
    done
    
    find "$APP" -name "*.xpc" | while read xpc; do
        codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp "$xpc"
    done
    
    find "$APP" -name "*.app" -not -path "$APP" | sort -r | while read nested; do
        codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp "$nested"
    done
    
    find "$APP" -name "*.framework" | while read framework; do
        codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp "$framework"
    done
    
    # Sign main bundle
    if [[ -n "$ENTITLEMENTS" && -f "$ENTITLEMENTS" ]]; then
        codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp \
            --entitlements "$ENTITLEMENTS" "$APP" || error "Failed to sign main bundle"
    else
        codesign --force --sign "$CERT_IDENTITY" --options runtime --timestamp \
            "$APP" || error "Failed to sign main bundle"
    fi
    
    # Verify signature
    codesign --verify --deep --strict --verbose=2 "$APP" || error "Signature verification failed"
    info "Code signing complete"
else
    warn "Phase 2: No certificate specified, skipping code signing"
fi

# Phase 3: Notarization
if [[ "$SKIP_NOTARIZE" == false && -n "$CERT_IDENTITY" ]]; then
    info "Phase 3: Notarizing..."
    
    # Create zip
    ditto -c -k --keepParent "$APP" "${APP_NAME}.zip" || error "Failed to create zip"
    
    # Submit for notarization
    SUBMISSION_OUTPUT=$(xcrun notarytool submit "${APP_NAME}.zip" \
        --keychain-profile "$NOTARY_PROFILE" \
        --wait 2>&1)
    
    if echo "$SUBMISSION_OUTPUT" | grep -q "status: Accepted"; then
        info "Notarization accepted"
        
        # Staple ticket
        xcrun stapler staple "$APP" || warn "Failed to staple ticket"
        
        # Verify Gatekeeper
        if spctl -a -vv "$APP" 2>&1 | grep -q "accepted"; then
            info "Gatekeeper verification passed"
        else
            warn "Gatekeeper verification failed"
        fi
    else
        error "Notarization failed. Output:\n${SUBMISSION_OUTPUT}"
    fi
else
    info "Phase 3: Skipping notarization"
fi

# Phase 4: Create Distribution Packages
info "Phase 4: Creating distribution packages..."

# DMG
hdiutil create -volname "$APP_NAME" \
    -srcfolder "$APP" \
    -ov -format UDZO \
    "${APP_NAME}_v${VERSION}.dmg" || error "Failed to create DMG"
info "DMG created: ${APP_NAME}_v${VERSION}.dmg"

# Zip
ditto -c -k --keepParent "$APP" "${APP_NAME}_v${VERSION}.zip" || error "Failed to create zip"
info "Zip created: ${APP_NAME}_v${VERSION}.zip"

# Checksums
shasum -a 256 "${APP_NAME}_v${VERSION}.dmg" > "${APP_NAME}_v${VERSION}_SHA256.txt"
shasum -a 256 "${APP_NAME}_v${VERSION}.zip" >> "${APP_NAME}_v${VERSION}_SHA256.txt"
info "Checksums generated"

# Phase 5: Git operations
info "Phase 5: Git operations..."

git add .
git commit -m "Release v${VERSION}

Co-Authored-By: Warp <agent@warp.dev>" || warn "Nothing to commit"

git tag -a "v${VERSION}" -m "Release v${VERSION}

Co-Authored-By: Warp <agent@warp.dev>" || warn "Tag already exists"

info "Git commit and tag created"

# Phase 6: GitHub Release
if [[ "$SKIP_RELEASE" == false ]]; then
    info "Phase 6: Creating GitHub release..."
    
    if command -v gh &> /dev/null; then
        gh release create "v${VERSION}" \
            "${APP_NAME}_v${VERSION}.dmg" \
            "${APP_NAME}_v${VERSION}.zip" \
            "${APP_NAME}_v${VERSION}_SHA256.txt" \
            --title "${APP_NAME} v${VERSION}" \
            --generate-notes || error "Failed to create GitHub release"
        
        info "GitHub release created"
    else
        warn "GitHub CLI (gh) not found. Please create release manually."
    fi
else
    info "Phase 6: Skipping GitHub release"
fi

echo ""
echo "========================================="
echo "✅ Release v${VERSION} complete!"
echo "========================================="
echo ""
echo "Files created:"
echo "  - ${APP_NAME}_v${VERSION}.dmg"
echo "  - ${APP_NAME}_v${VERSION}.zip"
echo "  - ${APP_NAME}_v${VERSION}_SHA256.txt"
echo ""

if command -v gh &> /dev/null; then
    REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || echo "USERNAME/REPO")
    echo "Download URL:"
    echo "https://github.com/${REPO}/releases/tag/v${VERSION}"
fi
