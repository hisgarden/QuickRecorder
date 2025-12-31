#!/bin/bash

# =============================================================================
# GitHub Release Creator (using GitHub CLI)
# =============================================================================
# This script creates a GitHub release using the GitHub CLI (gh)
#
# Usage:
#   ./scripts/create-gh-release.sh [version] [zip_path]
#
# Examples:
#   ./scripts/create-gh-release.sh 1.7.0 releases/QuickRecorder-1.7.0.zip
#   ./scripts/create-gh-release.sh 1.7.0  # Auto-find zip file
#   ./scripts/create-gh-release.sh         # Auto-detect version and zip
#
# Requirements:
#   - GitHub CLI (gh): brew install gh
#   - Authenticated: gh auth login
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERSION="${1:-}"
ZIP_PATH="${2:-}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASES_DIR="${REPO_DIR}/releases"
ARCHIVE_DIR="${REPO_DIR}/archive"

# -----------------------------------------------------------------------------
# Helper Functions
# -----------------------------------------------------------------------------

log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$1"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$1"
}

log_warning() {
    echo -e "${YELLOW}⚠️  ${NC}$1"
}

log_error() {
    echo -e "${RED}❌ ${NC}$1"
}

# -----------------------------------------------------------------------------
# Prerequisites Check
# -----------------------------------------------------------------------------

check_gh_cli() {
    if ! command -v gh &> /dev/null; then
        log_error "GitHub CLI (gh) is not installed"
        echo ""
        echo "Install with Homebrew:"
        echo "  brew install gh"
        echo ""
        echo "Or visit: https://cli.github.com/"
        exit 1
    fi

    # Check if authenticated
    if ! gh auth status &> /dev/null; then
        log_error "GitHub CLI is not authenticated"
        echo ""
        echo "Authenticate with:"
        echo "  gh auth login"
        echo ""
        exit 1
    fi

    log_success "GitHub CLI authenticated"
}

# -----------------------------------------------------------------------------
# Version Detection
# -----------------------------------------------------------------------------

detect_version_from_project_yml() {
    if [ -f "${REPO_DIR}/project.yml" ]; then
        grep 'MARKETING_VERSION:' "${REPO_DIR}/project.yml" | awk '{print $2}' | tr -d '"'
    fi
}

get_current_version() {
    local version=""

    if [ -n "$VERSION" ]; then
        version="$VERSION"
    else
        version=$(detect_version_from_project_yml)
    fi

    if [ -z "$version" ]; then
        log_error "Could not detect version number"
        log_info "Please provide version as an argument: $0 1.7.0"
        exit 1
    fi

    echo "$version"
}

# -----------------------------------------------------------------------------
# File Detection
# -----------------------------------------------------------------------------

find_release_zip() {
    local version="$1"
    local patterns=(
        "${RELEASES_DIR}/QuickRecorder-${version}.zip"
        "${ARCHIVE_DIR}/QuickRecorder-${version}.zip"
        "${RELEASES_DIR}/QuickRecorder-*.zip"
        "${ARCHIVE_DIR}/QuickRecorder-*.zip"
    )

    for pattern in "${patterns[@]}"; do
        local file=$(ls -t $pattern 2>/dev/null | head -1)
        if [ -n "$file" ] && [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done

    return 1
}

get_zip_path() {
    local version="$1"
    local zip_path=""

    if [ -n "$ZIP_PATH" ]; then
        zip_path="$ZIP_PATH"
    else
        zip_path=$(find_release_zip "$version")
    fi

    if [ -z "$zip_path" ] || [ ! -f "$zip_path" ]; then
        log_error "Could not find ZIP file for version ${version}"
        log_info "Please provide ZIP path: $0 ${version} releases/QuickRecorder-${version}.zip"
        exit 1
    fi

    echo "$zip_path"
}

# -----------------------------------------------------------------------------
# Release Notes
# -----------------------------------------------------------------------------

generate_release_notes() {
    local version="$1"

    cat <<EOF
## QuickRecorder ${version} - First Notarized Release

This is the first officially notarized release of QuickRecorder, ready for secure distribution outside the Mac App Store.

### ✨ New Features
- **Full Apple notarization** for Gatekeeper compliance
- **Developer ID signing** for secure distribution
- **Automatic update support** via Sparkle
- **Enhanced security** with hardened runtime

### 🚀 Improvements
- Improved screen recording stability
- Better audio capture performance
- Enhanced window selection workflow
- Updated Swift Package Manager dependencies

### 🐛 Bug Fixes
- Fixed multiple dialog appearances
- Fixed duplicate dock icons
- Resolved test suite integration issues
- Improved SwiftUI color asset resolution

### 🛠 Developer
- Migrated to XcodeGen for project management
- Comprehensive TDD test suite with XCTest
- Automated build and notarization workflows
- Complete CI/CD pipeline setup

---

### 📥 Installation

1. Download \`QuickRecorder-${version}.zip\`
2. Unzip the file
3. **Important:** Right-click on \`QuickRecorder.app\` → Select "Open" → Click "Open" in the dialog
4. Or move to Applications and use: \`xattr -d com.apple.quarantine QuickRecorder.app\`

> **Note:** macOS may show "Apple could not verify" on first launch. This is normal for apps distributed outside the Mac App Store. Use **Right-click → Open** to bypass this.

**System Requirements:** macOS 12.3 or later

See [INSTALL.md](https://github.com/hisgarden/QuickRecorder/blob/main/INSTALL.md) for detailed instructions.
EOF
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  GitHub Release Creator"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Step 1: Check GitHub CLI
    check_gh_cli

    # Step 2: Get version
    VERSION=$(get_current_version)
    log_info "Version: ${VERSION}"

    # Step 3: Get ZIP path
    ZIP_PATH=$(get_zip_path "$VERSION")
    log_info "ZIP file: ${ZIP_PATH}"
    local zip_size=$(du -h "$ZIP_PATH" | cut -f1)
    log_info "Size: ${zip_size}"

    # Step 4: Generate release notes
    log_info "Generating release notes..."
    RELEASE_NOTES=$(generate_release_notes "$VERSION")

    # Step 5: Create release
    local tag="v${VERSION}"
    log_info "Creating GitHub release: ${tag}"
    echo ""

    # Create release with gh CLI
    echo "$RELEASE_NOTES" | gh release create "$tag" \
        "$ZIP_PATH" \
        --title "Version ${VERSION}" \
        --notes-file - \
        --repo hisgarden/QuickRecorder

    if [ $? -eq 0 ]; then
        echo ""
        log_success "Release created successfully!"
        echo ""
        echo "Release URL:"
        echo "  https://github.com/hisgarden/QuickRecorder/releases/tag/${tag}"
        echo ""
        echo "Next steps:"
        echo "  1. Verify the release at: https://github.com/hisgarden/QuickRecorder/releases"
        echo "  2. Check appcast is accessible: https://raw.githubusercontent.com/hisgarden/QuickRecorder/main/appcast.xml"
        echo "  3. Test automatic updates in the app"
        echo ""
    else
        log_error "Failed to create release"
        echo ""
        echo "Troubleshooting:"
        echo "  - Check authentication: gh auth status"
        echo "  - Re-authenticate: gh auth login"
        echo "  - Check repository access: gh repo view hisgarden/QuickRecorder"
        exit 1
    fi
}

# Run main
main

