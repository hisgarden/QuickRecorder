#!/bin/bash
# Update Homebrew cask for QuickRecorder
# Usage: ./scripts/update-homebrew-cask.sh [version] [dmg_path]

set -euo pipefail

VERSION="${1:-}"
DMG_PATH="${2:-}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TAP_DIR="/tmp/homebrew-tap-quickrecorder"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$1"
}

log_error() {
    echo -e "${RED}❌ ${NC}$1"
}

# Get version from project.yml if not provided
if [ -z "$VERSION" ]; then
    VERSION=$(grep 'MARKETING_VERSION:' "${REPO_DIR}/project.yml" | awk '{print $2}' | tr -d '"')
    if [ -z "$VERSION" ]; then
        log_error "Could not detect version. Please provide version: $0 1.7.1"
        exit 1
    fi
fi

log_info "Version: ${VERSION}"

# Find DMG file if not provided
if [ -z "$DMG_PATH" ]; then
    # Check current directory first (most recent build)
    DMG_PATH=$(find "${REPO_DIR}" -maxdepth 1 -name "QuickRecorder.dmg" -type f 2>/dev/null | head -1)
    if [ -z "$DMG_PATH" ]; then
        # Try releases directory
        DMG_PATH=$(find "${REPO_DIR}/releases" -name "QuickRecorder-${VERSION}.dmg" -type f 2>/dev/null | head -1)
    fi
    if [ -z "$DMG_PATH" ]; then
        # Try archive exports
        DMG_PATH=$(find "${REPO_DIR}/archive/export-*" -name "QuickRecorder.app" -type d 2>/dev/null | sort -r | head -1)
        if [ -n "$DMG_PATH" ]; then
            log_info "Found app, will create DMG first..."
            # Create DMG if we found an app but no DMG
            "${REPO_DIR}/scripts/create-dmg.sh" "$DMG_PATH" || {
                log_error "Failed to create DMG. Please create DMG first: task create-dmg"
                exit 1
            }
            DMG_PATH="${REPO_DIR}/QuickRecorder.dmg"
        fi
    fi
    if [ -z "$DMG_PATH" ] || [ ! -f "$DMG_PATH" ]; then
        log_error "DMG file not found. Please provide path: $0 ${VERSION} path/to/QuickRecorder.dmg"
        log_info "Or create DMG first: task create-dmg"
        exit 1
    fi
fi

if [ ! -f "$DMG_PATH" ]; then
    log_error "DMG file not found: ${DMG_PATH}"
    exit 1
fi

# Calculate SHA256
log_info "Calculating SHA256..."
SHA256=$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')
log_info "SHA256: ${SHA256}"

# Clone or update tap repository
if [ -d "$TAP_DIR" ]; then
    log_info "Updating existing tap repository..."
    cd "$TAP_DIR"
    git pull origin main
else
    log_info "Cloning tap repository..."
    git clone git@github.com:hisgarden/homebrew-tap.git "$TAP_DIR"
    cd "$TAP_DIR"
fi

# Update cask file
CASK_FILE="${TAP_DIR}/Casks/quickrecorder.rb"
if [ ! -f "$CASK_FILE" ]; then
    log_error "Cask file not found: ${CASK_FILE}"
    exit 1
fi

log_info "Updating cask file..."

# Update version
sed -i '' "s/version \".*\"/version \"${VERSION}\"/" "$CASK_FILE"

# Update SHA256
sed -i '' "s/sha256 \".*\"/sha256 \"${SHA256}\"/" "$CASK_FILE"

# Update URL (if needed)
DMG_URL="https://github.com/hisgarden/QuickRecorder/releases/download/v${VERSION}/QuickRecorder.dmg"
sed -i '' "s|url \".*\"|url \"${DMG_URL}\"|" "$CASK_FILE"

log_success "Cask file updated"

# Show diff
log_info "Changes:"
git diff "$CASK_FILE" || true

# Commit and push
read -p "Commit and push changes? (y/N): " -n 1 -r
echo ""
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git add "$CASK_FILE"
    git commit -m "Update QuickRecorder to v${VERSION}"
    git push origin main
    log_success "Homebrew cask updated to v${VERSION}"
    echo ""
    echo "Users can now install with:"
    echo "  brew tap hisgarden/tap"
    echo "  brew install --cask quickrecorder"
else
    log_info "Changes not committed. Review ${CASK_FILE} and commit manually."
fi
