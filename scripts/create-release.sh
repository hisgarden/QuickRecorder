#!/bin/bash

# =============================================================================
# GitHub Release Creator
# =============================================================================
# This script creates a GitHub release using the GitHub API
#
# Usage:
#   ./scripts/create-release.sh [version] [zip_path]
#
# Examples:
#   ./scripts/create-release.sh 1.7.0 releases/QuickRecorder-1.7.0.zip
#   ./scripts/create-release.sh 1.7.0  # Auto-find zip file
#   ./scripts/create-release.sh         # Auto-detect version and zip
#
# Requirements:
#   - GitHub Personal Access Token with 'repo' scope
#   - Set GITHUB_TOKEN environment variable or use --token flag
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
REPO_OWNER="hisgarden"
REPO_NAME="QuickRecorder"
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

print_usage() {
    cat <<EOF
GitHub Release Creator

Usage: $0 [OPTIONS] [VERSION] [ZIP_PATH]

OPTIONS:
    -h, --help              Show this help message
    -t, --token TOKEN       GitHub Personal Access Token
    -d, --draft             Create as draft release
    -p, --prerelease        Mark as pre-release
    -n, --notes FILE        Path to release notes file

ARGUMENTS:
    VERSION                 Version number (e.g., 1.7.0). Auto-detected if not provided.
    ZIP_PATH                Path to the ZIP file to upload. Auto-detected if not provided.

ENVIRONMENT:
    GITHUB_TOKEN            GitHub Personal Access Token (required if not using --token)

EXAMPLES:
    $0 1.7.0 releases/QuickRecorder-1.7.0.zip
    $0 --token ghp_xxxxx 1.7.0
    $0 --draft 1.7.0  # Create as draft

For more information, visit:
https://docs.github.com/en/rest/releases/releases
EOF
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
# GitHub API Functions
# -----------------------------------------------------------------------------

check_github_token() {
    if [ -z "$GITHUB_TOKEN" ]; then
        log_error "GitHub token not found"
        log_info "Set GITHUB_TOKEN environment variable or use --token flag"
        log_info ""
        log_info "To create a token:"
        log_info "  1. Go to: https://github.com/settings/tokens"
        log_info "  2. Generate new token (classic) with 'repo' scope"
        log_info "  3. Set: export GITHUB_TOKEN=ghp_xxxxx"
        exit 1
    fi
}

create_release() {
    local version="$1"
    local tag="v${version}"
    local name="Version ${version}"
    local body="$2"
    local draft="${3:-false}"
    local prerelease="${4:-false}"

    log_info "Creating GitHub release: ${tag}"

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: application/json" \
        "https://api.github.com/repos/${REPO_OWNER}/${REPO_NAME}/releases" \
        -d "{
            \"tag_name\": \"${tag}\",
            \"name\": \"${name}\",
            \"body\": ${body},
            \"draft\": ${draft},
            \"prerelease\": ${prerelease}
        }")

    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 201 ]; then
        local upload_url=$(echo "$response_body" | grep -o '"upload_url":"[^"]*' | cut -d'"' -f4 | sed 's/{?name,label}//')
        echo "$upload_url"
        return 0
    else
        log_error "Failed to create release (HTTP ${http_code})"
        echo "$response_body" | grep -o '"message":"[^"]*' | cut -d'"' -f4 || echo "$response_body"
        return 1
    fi
}

upload_asset() {
    local upload_url="$1"
    local file_path="$2"
    local file_name=$(basename "$file_path")
    local mime_type="application/zip"

    log_info "Uploading asset: ${file_name}"

    local response=$(curl -s -w "\n%{http_code}" \
        -X POST \
        -H "Authorization: token ${GITHUB_TOKEN}" \
        -H "Accept: application/vnd.github.v3+json" \
        -H "Content-Type: ${mime_type}" \
        --data-binary "@${file_path}" \
        "${upload_url}?name=${file_name}")

    local http_code=$(echo "$response" | tail -n1)
    local response_body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 201 ]; then
        log_success "Asset uploaded: ${file_name}"
        return 0
    else
        log_error "Failed to upload asset (HTTP ${http_code})"
        echo "$response_body" | grep -o '"message":"[^"]*' | cut -d'"' -f4 || echo "$response_body"
        return 1
    fi
}

# -----------------------------------------------------------------------------
# Release Notes
# -----------------------------------------------------------------------------

generate_release_notes() {
    local version="$1"
    local notes_file="$2"

    if [ -n "$notes_file" ] && [ -f "$notes_file" ]; then
        # Read from file and escape for JSON
        cat "$notes_file" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n'
    else
        # Generate default release notes
        cat <<EOF | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n'
## QuickRecorder ${version}

This is the first officially notarized release of QuickRecorder, ready for secure distribution outside the Mac App Store.

### New Features
- Full Apple notarization for Gatekeeper compliance
- Developer ID signing for secure distribution
- Automatic update support via Sparkle
- Enhanced security with hardened runtime

### Improvements
- Improved screen recording stability
- Better audio capture performance
- Enhanced window selection workflow
- Updated Swift Package Manager dependencies

### Bug Fixes
- Fixed multiple dialog appearances
- Fixed duplicate dock icons
- Resolved test suite integration issues
- Improved SwiftUI color asset resolution

### Developer
- Migrated to XcodeGen for project management
- Comprehensive TDD test suite with XCTest
- Automated build and notarization workflows
- Complete CI/CD pipeline setup
EOF
    fi
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

main() {
    # Parse arguments
    DRAFT=false
    PRERELEASE=false
    NOTES_FILE=""

    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -t|--token)
                GITHUB_TOKEN="$2"
                shift 2
                ;;
            -d|--draft)
                DRAFT=true
                shift
                ;;
            -p|--prerelease)
                PRERELEASE=true
                shift
                ;;
            -n|--notes)
                NOTES_FILE="$2"
                shift 2
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
            *)
                if [ -z "$VERSION" ]; then
                    VERSION="$1"
                elif [ -z "$ZIP_PATH" ]; then
                    ZIP_PATH="$1"
                else
                    log_error "Too many arguments: $1"
                    print_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  GitHub Release Creator"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Step 1: Get version
    VERSION=$(get_current_version)
    log_info "Version: ${VERSION}"

    # Step 2: Get ZIP path
    ZIP_PATH=$(get_zip_path "$VERSION")
    log_info "ZIP file: ${ZIP_PATH}"

    # Step 3: Check GitHub token
    check_github_token

    # Step 4: Generate release notes
    RELEASE_NOTES=$(generate_release_notes "$VERSION" "$NOTES_FILE")
    RELEASE_NOTES_JSON=$(echo -n "\"${RELEASE_NOTES}\"")

    # Step 5: Create release
    UPLOAD_URL=$(create_release "$VERSION" "$RELEASE_NOTES_JSON" "$DRAFT" "$PRERELEASE")
    if [ $? -ne 0 ]; then
        exit 1
    fi

    # Step 6: Upload asset
    if ! upload_asset "$UPLOAD_URL" "$ZIP_PATH"; then
        exit 1
    fi

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_success "Release created successfully!"
    echo ""
    echo "Release URL:"
    echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/tag/v${VERSION}"
    echo ""
    echo "View all releases:"
    echo "  https://github.com/${REPO_OWNER}/${REPO_NAME}/releases"
    echo ""
}

# Run main
main "$@"





