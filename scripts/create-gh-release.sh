#!/bin/bash

# =============================================================================
# GitHub Release Creator (using GitHub CLI)
# =============================================================================
# This script creates a GitHub release using the GitHub CLI (gh)
#
# Usage:
#   ./scripts/create-gh-release.sh [--force] [version] [dmg_or_zip_path]
#
# Examples:
#   ./scripts/create-gh-release.sh 1.7.0 QuickRecorder.dmg
#   ./scripts/create-gh-release.sh 1.7.0  # Auto-find DMG or ZIP file
#   ./scripts/create-gh-release.sh         # Auto-detect version and file
#   ./scripts/create-gh-release.sh --force 1.7.1  # Overwrite existing release
#
# Options:
#   --force, -f    Delete existing release if tag already exists
#
# Note: If a release with the same tag already exists, you'll be prompted
#       to delete it before creating a new one (unless --force is used).
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
FORCE_OVERWRITE=false
VERSION=""
ZIP_PATH=""

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --force|-f)
            FORCE_OVERWRITE=true
            shift
            ;;
        *)
            if [ -z "$VERSION" ]; then
                VERSION="$1"
            elif [ -z "$ZIP_PATH" ]; then
                ZIP_PATH="$1"
            fi
            shift
            ;;
    esac
done
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

find_release_file() {
    local version="$1"
    
    # Prioritize DMG files over ZIP files, and prefer latest/most recent files
    # Check for version-specific DMG first
    local dmg_patterns=(
        "${REPO_DIR}/QuickRecorder.dmg"
        "${RELEASES_DIR}/QuickRecorder-${version}.dmg"
        "${ARCHIVE_DIR}/QuickRecorder-${version}.dmg"
        "${RELEASES_DIR}/QuickRecorder-*.dmg"
        "${ARCHIVE_DIR}/QuickRecorder-*.dmg"
    )
    
    # Check for ZIP files as fallback
    local zip_patterns=(
        "${RELEASES_DIR}/QuickRecorder-${version}.zip"
        "${ARCHIVE_DIR}/QuickRecorder-${version}.zip"
        "${RELEASES_DIR}/QuickRecorder-*.zip"
        "${ARCHIVE_DIR}/QuickRecorder-*.zip"
    )

    # Try DMG files first (prioritize DMG)
    for pattern in "${dmg_patterns[@]}"; do
        local file=$(ls -t $pattern 2>/dev/null | head -1)
        if [ -n "$file" ] && [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done
    
    # Fallback to ZIP files if no DMG found
    for pattern in "${zip_patterns[@]}"; do
        local file=$(ls -t $pattern 2>/dev/null | head -1)
        if [ -n "$file" ] && [ -f "$file" ]; then
            echo "$file"
            return 0
        fi
    done

    return 1
}

get_release_file() {
    local version="$1"
    local file_path=""

    if [ -n "$ZIP_PATH" ]; then
        file_path="$ZIP_PATH"
    else
        file_path=$(find_release_file "$version")
    fi

    if [ -z "$file_path" ] || [ ! -f "$file_path" ]; then
        log_error "Could not find release file (DMG or ZIP) for version ${version}"
        log_info "Please provide file path: $0 ${version} QuickRecorder.dmg"
        log_info "Or create DMG first: task create-dmg"
        exit 1
    fi

    echo "$file_path"
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

1. Download \`QuickRecorder-${version}.dmg\` (or \`.zip\`)
2. Open the DMG file (or unzip if using ZIP)
3. Drag \`QuickRecorder.app\` to your Applications folder
4. **Important:** On first launch, right-click on \`QuickRecorder.app\` → Select "Open" → Click "Open" in the dialog
5. Or use: \`xattr -d com.apple.quarantine QuickRecorder.app\`

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

    # Step 3: Get release file (DMG or ZIP)
    RELEASE_FILE=$(get_release_file "$VERSION")
    log_info "Release file: ${RELEASE_FILE}"
    local file_size=$(du -h "$RELEASE_FILE" | cut -f1)
    log_info "Size: ${file_size}"

    # Step 4: Generate release notes
    log_info "Generating release notes..."
    RELEASE_NOTES=$(generate_release_notes "$VERSION")

    # Step 5: Check if release already exists
    local tag="v${VERSION}"
    if gh release view "$tag" --repo hisgarden/QuickRecorder &>/dev/null; then
        log_warning "Release ${tag} already exists"
        
        if [ "$FORCE_OVERWRITE" = true ]; then
            log_info "Force overwrite enabled - deleting existing release: ${tag}"
            gh release delete "$tag" --repo hisgarden/QuickRecorder --yes || {
                log_error "Failed to delete existing release"
                exit 1
            }
            log_success "Deleted existing release"
        else
            echo ""
            echo "Options:"
            echo "  1. Delete existing release and create new one"
            echo "  2. Skip (keep existing release)"
            echo ""
            read -p "Delete existing release? (y/N): " -n 1 -r
            echo ""
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                log_info "Deleting existing release: ${tag}"
                gh release delete "$tag" --repo hisgarden/QuickRecorder --yes || {
                    log_error "Failed to delete existing release"
                    exit 1
                }
                log_success "Deleted existing release"
            else
                log_info "Skipping - keeping existing release"
                echo ""
                echo "To overwrite, use: $0 --force ${VERSION}"
                echo ""
                echo "Release URL:"
                echo "  https://github.com/hisgarden/QuickRecorder/releases/tag/${tag}"
                exit 0
            fi
        fi
    fi

    # Step 6: Create release
    log_info "Creating GitHub release: ${tag}"
    echo ""

    # Create release with gh CLI
    echo "$RELEASE_NOTES" | gh release create "$tag" \
        "$RELEASE_FILE" \
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

