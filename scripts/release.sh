#!/bin/bash

# =============================================================================
# QuickRecorder Release Workflow
# =============================================================================
# This script automates the complete release process:
#   1. Creates DMG from notarized app
#   2. Updates appcast.xml
#   3. Commits changes to git
#   4. Pushes to GitHub
#
# Usage:
#   ./scripts/release.sh [version] [app_path]
#
# Examples:
#   ./scripts/release.sh 1.7.0 archive/export-*/QuickRecorder.app
#   ./scripts/release.sh 1.7.0  # Auto-find app
#   ./scripts/release.sh         # Auto-detect version and find app
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
APP_PATH="${2:-}"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ARCHIVE_DIR="${REPO_DIR}/archive"
RELEASES_DIR="${REPO_DIR}/releases"

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
# App Detection
# -----------------------------------------------------------------------------

find_latest_app() {
    # Look for the most recent exported app
    local latest_app=$(find "${ARCHIVE_DIR}" -name "QuickRecorder.app" -type d -maxdepth 2 -print0 2>/dev/null | \
        xargs -0 ls -dt 2>/dev/null | head -1)

    if [ -n "$latest_app" ] && [ -d "$latest_app" ]; then
        echo "$latest_app"
        return 0
    fi

    return 1
}

get_app_path() {
    local app_path=""

    if [ -n "$APP_PATH" ]; then
        app_path="$APP_PATH"
    else
        app_path=$(find_latest_app)
    fi

    if [ -z "$app_path" ] || [ ! -d "$app_path" ]; then
        log_error "Could not find QuickRecorder.app"
        log_info "Please provide app path: $0 1.7.0 archive/export-*/QuickRecorder.app"
        log_info "Or run 'just notarize' first to create the app"
        exit 1
    fi

    echo "$app_path"
}

# -----------------------------------------------------------------------------
# DMG Creation
# -----------------------------------------------------------------------------

create_dmg() {
    local app_path="$1"
    local version="$2"
    local dmg_name="QuickRecorder-${version}.dmg"
    local dmg_path="${RELEASES_DIR}/${dmg_name}"

    log_info "Creating DMG: ${dmg_name}"

    # Create releases directory if it doesn't exist
    mkdir -p "${RELEASES_DIR}"

    # Remove existing DMG if present
    [ -f "$dmg_path" ] && rm -f "$dmg_path"

    # Create temporary directory for DMG contents
    local temp_dir=$(mktemp -d)
    local app_name=$(basename "$app_path")

    # Copy app to temp directory
    cp -R "$app_path" "${temp_dir}/"

    # Create DMG
    hdiutil create -volname "QuickRecorder" \
        -srcfolder "$temp_dir" \
        -ov \
        -format UDZO \
        -fs HFS+ \
        "$dmg_path" > /dev/null 2>&1

    # Cleanup
    rm -rf "$temp_dir"

    if [ -f "$dmg_path" ]; then
        local dmg_size=$(du -h "$dmg_path" | cut -f1)
        log_success "DMG created: ${dmg_path} (${dmg_size})"
        echo "$dmg_path"
        return 0
    else
        log_error "Failed to create DMG"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Appcast Update
# -----------------------------------------------------------------------------

update_appcast() {
    local version="$1"
    local zip_path="$2"

    log_info "Updating appcast.xml..."

    if [ ! -f "$zip_path" ]; then
        log_error "ZIP file not found: ${zip_path}"
        return 1
    fi

    # Use the generate-appcast script
    if bash "${REPO_DIR}/scripts/generate-appcast.sh" "$version" "$zip_path" > /dev/null 2>&1; then
        log_success "Appcast updated"
        return 0
    else
        log_error "Failed to update appcast"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Git Operations
# -----------------------------------------------------------------------------

check_git_status() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not a git repository"
        return 1
    fi

    # Check if there are uncommitted changes
    if ! git diff-index --quiet HEAD -- 2>/dev/null; then
        log_warning "You have uncommitted changes"
        log_info "Files with changes:"
        git diff --name-only
        echo ""
        read -p "Continue anyway? (y/N) " -n 1 -r
        echo ""
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Aborted"
            exit 1
        fi
    fi

    return 0
}

commit_changes() {
    local version="$1"

    log_info "Staging changes..."

    # Stage appcast.xml
    if [ -f "${REPO_DIR}/appcast.xml" ]; then
        git add "${REPO_DIR}/appcast.xml"
    fi

    # Check if there are staged changes
    if git diff --cached --quiet 2>/dev/null; then
        log_warning "No changes to commit"
        return 1
    fi

    log_info "Committing changes..."
    git commit -m "Release v${version}: Update appcast" > /dev/null 2>&1

    if [ $? -eq 0 ]; then
        log_success "Changes committed"
        return 0
    else
        log_error "Failed to commit changes"
        return 1
    fi
}

push_to_github() {
    local version="$1"

    log_info "Pushing to GitHub..."

    # Get current branch
    local branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "main")

    if git push origin "$branch" 2>&1; then
        log_success "Pushed to GitHub (branch: ${branch})"
        return 0
    else
        log_error "Failed to push to GitHub"
        log_info "You may need to push manually: git push origin ${branch}"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

main() {
    # Step 1: Get version
    VERSION=$(get_current_version)
    log_info "Version: ${VERSION}"

    # Step 2: Get app path
    APP_PATH=$(get_app_path)
    log_info "App: ${APP_PATH}"

    # Step 3: Check git status
    if ! check_git_status; then
        exit 1
    fi

    # Step 3.5: Staple notarization ticket to app
    log_info "Stapling notarization ticket..."
    if xcrun stapler staple "$APP_PATH" 2>&1 | grep -q "action worked"; then
        log_success "Notarization ticket stapled"
    else
        log_warning "Stapling failed or ticket already stapled"
        log_info "This is OK if the app was already stapled or notarization is still processing"
    fi

    # Step 3.6: Remove AppleDouble files (._* files) that break code signature
    log_info "Cleaning AppleDouble files..."
    find "$APP_PATH" -name "._*" -type f -delete 2>/dev/null || true
    local removed_count=$(find "$APP_PATH" -name "._*" -type f 2>/dev/null | wc -l | tr -d ' ')
    if [ "$removed_count" -eq 0 ]; then
        log_success "No AppleDouble files found (clean)"
    else
        log_warning "Removed ${removed_count} AppleDouble files"
        # Re-sign after removing files
        log_info "Re-signing after cleanup..."
        codesign --force --sign "Developer ID Application: Jin Wen (NSDC3EDS2G)" \
            --timestamp \
            --options runtime \
            "$APP_PATH" > /dev/null 2>&1
        log_success "Re-signed after cleanup"
    fi

    # Step 4: Create ZIP from app (for appcast)
    log_info "Creating ZIP for appcast..."
    local zip_name="QuickRecorder-${VERSION}.zip"
    local zip_path="${RELEASES_DIR}/${zip_name}"
    mkdir -p "${RELEASES_DIR}"

    if [ -f "$zip_path" ]; then
        log_info "ZIP already exists: ${zip_path}"
    else
        cd "$(dirname "$APP_PATH")"
        ditto -c -k --norsrc --keepParent "$(basename "$APP_PATH")" "$zip_path" > /dev/null 2>&1
        if [ -f "$zip_path" ]; then
            local zip_size=$(du -h "$zip_path" | cut -f1)
            log_success "ZIP created: ${zip_path} (${zip_size})"
        else
            log_error "Failed to create ZIP"
            exit 1
        fi
    fi

    # Step 5: Create DMG
    DMG_PATH=$(create_dmg "$APP_PATH" "$VERSION")
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Step 6: Update appcast
    if ! update_appcast "$VERSION" "$zip_path"; then
        exit 1
    fi

    # Step 7: Commit changes
    if ! commit_changes "$VERSION"; then
        log_warning "Skipping commit (no changes or commit failed)"
    fi

    # Step 8: Push to GitHub
    if ! push_to_github "$VERSION"; then
        log_warning "Push failed - you may need to push manually"
    fi

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Release workflow completed!"
    echo ""
    echo "Files created:"
    echo "  📦 DMG: ${DMG_PATH}"
    echo "  📦 ZIP: ${zip_path}"
    echo "  📄 Appcast: ${REPO_DIR}/appcast.xml"
    echo ""
    echo "Next steps:"
    echo "  1. Create GitHub release: https://github.com/hisgarden/QuickRecorder/releases/new"
    echo "     - Tag: v${VERSION}"
    echo "     - Title: Version ${VERSION}"
    echo "     - Upload: ${zip_path}"
    echo "  2. Verify appcast is accessible:"
    echo "     https://raw.githubusercontent.com/hisgarden/QuickRecorder/main/appcast.xml"
    echo ""
}

# Run main
main

