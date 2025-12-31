#!/bin/bash

# =============================================================================
# Sparkle Appcast Generator
# =============================================================================
# This script generates or updates an appcast.xml file for Sparkle updates.
#
# Usage:
#   ./scripts/generate-appcast.sh [version] [dmg_path]
#
# Examples:
#   ./scripts/generate-appcast.sh 1.2.1 /path/to/QuickRecorder-1.2.1.zip
#   ./scripts/generate-appcast.sh 1.2.1  # Auto-detects version and dmg
#
# Requirements:
#   - Homebrew: /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
#   - For DSA signing: brew install openssl
#   - For ED25519 signing: brew install libsodium
# =============================================================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
VERSION=""
DMG_PATH=""
APP_NAME="QuickRecorder"
CHANNEL="stable"
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APPCAST_FILE="${REPO_DIR}/appcast.xml"
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

print_usage() {
    cat <<EOF
Sparkle Appcast Generator

Usage: $0 [OPTIONS] [VERSION] [DMG_PATH]

OPTIONS:
    -h, --help              Show this help message
    -s, --signing-key KEY   Path to private signing key (DSA or ED25519)
    -f, --force             Overwrite existing release files
    -n, --notes FILE        Path to release notes markdown file
    --dry-run               Show what would be done without making changes

ARGUMENTS:
    VERSION                 Version number (e.g., 1.2.1). Auto-detected if not provided.
    DMG_PATH                Path to the release DMG/ZIP file. Auto-detected if not provided.

EXAMPLES:
    $0 1.2.1 /path/to/QuickRecorder-1.2.1.zip
    $0 --signing-key keys/dsa_priv.pem 1.2.1 QuickRecorder-1.2.1.dmg
    $0 --dry-run  # Preview what would happen

For more information about Sparkle appcasts, visit:
https://sparkle-project.org/documentation/
EOF
}

# -----------------------------------------------------------------------------
# Version Detection
# -----------------------------------------------------------------------------

detect_version_from_info_plist() {
    local info_plist="${REPO_DIR}/QuickRecorder/Info.plist"
    if [ -f "$info_plist" ]; then
        grep -A1 '<key>CFBundleShortVersionString</key>' "$info_plist" | grep '<string>' | sed 's/.*<string>\(.*\)<\/string>.*/\1/'
    fi
}

detect_version_from_project_yml() {
    if [ -f "${REPO_DIR}/project.yml" ]; then
        grep 'MARKETING_VERSION:' "${REPO_DIR}/project.yml" | awk '{print $2}' | tr -d '"'
    fi
}

get_current_version() {
    local version=""

    # Try to detect version from arguments
    if [ -n "$VERSION" ]; then
        version="$VERSION"
    else
        # Try to detect from Info.plist
        version=$(detect_version_from_info_plist)

        # Fall back to project.yml
        if [ -z "$version" ]; then
            version=$(detect_version_from_project_yml)
        fi
    fi

    if [ -z "$version" ]; then
        log_error "Could not detect version number"
        log_info "Please provide version as an argument: $0 1.2.1"
        exit 1
    fi

    echo "$version"
}

# -----------------------------------------------------------------------------
# File Detection
# -----------------------------------------------------------------------------

find_release_file() {
    local version="$1"
    local patterns=(
        "${REPO_DIR}/releases/${APP_NAME}-${version}.zip"
        "${REPO_DIR}/releases/${APP_NAME}-${version}.dmg"
        "${REPO_DIR}/archive/${APP_NAME}-${version}.zip"
        "${REPO_DIR}/archive/${APP_NAME}-${version}.dmg"
        "${REPO_DIR}/${APP_NAME}-${version}.zip"
        "${REPO_DIR}/${APP_NAME}-${version}.dmg"
    )

    for pattern in "${patterns[@]}"; do
        if [ -f "$pattern" ]; then
            echo "$pattern"
            return 0
        fi
    done

    return 1
}

# -----------------------------------------------------------------------------
# File Size Calculation
# -----------------------------------------------------------------------------

get_file_size() {
    local file="$1"
    if [ -f "$file" ]; then
        stat -f%z "$file" 2>/dev/null || stat -c%s "$file" 2>/dev/null || echo "0"
    else
        echo "0"
    fi
}

# -----------------------------------------------------------------------------
# SHA-256 Calculation
# -----------------------------------------------------------------------------

calculate_sha256() {
    local file="$1"
    if [ -f "$file" ]; then
        shasum -a 256 "$file" | awk '{print $1}'
    else
        echo ""
    fi
}

# -----------------------------------------------------------------------------
# Release Notes Generation
# -----------------------------------------------------------------------------

generate_release_notes() {
    local version="$1"
    local notes_file="$2"

    if [ -n "$notes_file" ] && [ -f "$notes_file" ]; then
        # Use provided markdown file
        cat "$notes_file"
    else
        # Generate default release notes based on version
        if [[ "$version" == "1.7.0"* ]]; then
            # Special notes for first notarized release
            cat <<EOF
<h2>QuickRecorder ${version}</h2>
<p>This is the first officially notarized release of QuickRecorder, ready for secure distribution outside the Mac App Store.</p>
<h3>New Features</h3>
<ul>
    <li>Full Apple notarization for Gatekeeper compliance</li>
    <li>Developer ID signing for secure distribution</li>
    <li>Automatic update support via Sparkle</li>
    <li>Enhanced security with hardened runtime</li>
</ul>
<h3>Improvements</h3>
<ul>
    <li>Improved screen recording stability</li>
    <li>Better audio capture performance</li>
    <li>Enhanced window selection workflow</li>
</ul>
EOF
        else
            # Standard release notes for other versions
            cat <<EOF
<h2>QuickRecorder ${version}</h2>
<p>This update includes improvements and bug fixes.</p>
<ul>
    <li>General stability improvements</li>
    <li>Performance optimizations</li>
</ul>
EOF
        fi
    fi
}

# -----------------------------------------------------------------------------
# DSA Signing
# -----------------------------------------------------------------------------

generate_dsa_signature() {
    local file="$1"
    local private_key="$2"

    if [ ! -f "$private_key" ]; then
        log_warning "DSA signing key not found: $private_key"
        echo ""
        return 1
    fi

    if ! command -v openssl &> /dev/null; then
        log_warning "OpenSSL not found. Install with: brew install openssl"
        echo ""
        return 1
    fi

    # Generate DSA signature using OpenSSL
    local signature=$(openssl dgst -sha256 -sign "$private_key" "$file" | base64)

    echo "dsaSig=${signature}"
}

# -----------------------------------------------------------------------------
# ED25519 Signing
# -----------------------------------------------------------------------------

generate_ed25519_signature() {
    local file="$1"
    local private_key="$2"

    if [ ! -f "$private_key" ]; then
        log_warning "ED25519 signing key not found: $private_key"
        echo ""
        return 1
    fi

    if ! command -v sodium &> /dev/null; then
        log_warning "libsodium not found. Install with: brew install libsodium"
        echo ""
        return 1
    fi

    # Generate ED25519 signature
    local signature=$(sodium -v -q "$file" -s "$private_key" 2>/dev/null | grep signature | awk '{print $2}')

    if [ -z "$signature" ]; then
        # Fallback to different command format
        local file_hash=$(shasum -a 256 "$file" | awk '{print $1}')
        signature=$(echo "$file_hash" | xxd -r -p | sodium -v -q -s "$private_key" 2>/dev/null | grep signature | awk '{print $2}')
    fi

    echo "edSig=${signature}"
}

# -----------------------------------------------------------------------------
# Appcast XML Generation
# -----------------------------------------------------------------------------

generate_appcast_xml() {
    local version="$1"
    local file_path="$2"
    local signature="$3"
    local release_notes="$4"
    local pub_date="$5"

    # Calculate file properties
    local file_size=$(get_file_size "$file_path")
    local file_hash=$(calculate_sha256 "$file_path")
    local file_name=$(basename "$file_path")
    local download_url="https://github.com/hisgarden/QuickRecorder/releases/download/v${version}/${file_name}"

    # Use provided pub_date or generate current date
    if [ -z "$pub_date" ]; then
        pub_date=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")
    fi

    # Escape XML characters in release notes
    release_notes=$(echo "$release_notes" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g; s/'\''/\&apos;/g')

    # Generate XML
    cat <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
  <channel>
    <title>QuickRecorder Changelog</title>
    <description>QuickRecorder updates</description>
    <language>en</language>
    <item>
      <title>Version ${version}</title>
      <description><![CDATA[${release_notes}]]></description>
      <pubDate>${pub_date}</pubDate>
      <enclosure url="${download_url}"
                 sparkle:version="${version}"
                 sparkle:shortVersionString="${version}"
                 ${signature}
                 length="${file_size}"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
EOF
}

# -----------------------------------------------------------------------------
# Main Execution
# -----------------------------------------------------------------------------

main() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  Sparkle Appcast Generator"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                print_usage
                exit 0
                ;;
            -s|--signing-key)
                SIGNING_KEY="$2"
                shift 2
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -n|--notes)
                NOTES_FILE="$2"
                shift 2
                ;;
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                print_usage
                exit 1
                ;;
            *)
                if [ -z "$VERSION" ]; then
                    VERSION="$1"
                elif [ -z "$DMG_PATH" ]; then
                    DMG_PATH="$1"
                else
                    log_error "Too many arguments: $1"
                    print_usage
                    exit 1
                fi
                shift
                ;;
        esac
    done

    # Get version
    VERSION=$(get_current_version)
    log_info "Version: ${VERSION}"

    # Find release file
    if [ -z "$DMG_PATH" ]; then
        log_info "Searching for release file..."
        DMG_PATH=$(find_release_file "$VERSION")

        if [ -z "$DMG_PATH" ]; then
            log_error "Could not find release file for version ${VERSION}"
            log_info "Please provide the path to your release file:"
            log_info "  $0 ${VERSION} /path/to/${APP_NAME}-${VERSION}.zip"
            exit 1
        fi
    fi

    log_info "Release file: ${DMG_PATH}"

    if [ ! -f "$DMG_PATH" ]; then
        log_error "Release file not found: ${DMG_PATH}"
        exit 1
    fi

    # Get file size
    FILE_SIZE=$(get_file_size "$DMG_PATH")
    log_info "File size: ${FILE_SIZE} bytes"

    # Generate release notes
    RELEASE_NOTES=$(generate_release_notes "$VERSION" "$NOTES_FILE")

    # Generate signature if signing key provided
    SIGNATURE=""
    if [ -n "$SIGNING_KEY" ]; then
        log_info "Generating signature with key: ${SIGNING_KEY}"

        if [[ "$SIGNING_KEY" == *.pem ]] || [[ "$SIGNING_KEY" == *dsa* ]]; then
            SIGNATURE=$(generate_dsa_signature "$DMG_PATH" "$SIGNING_KEY")
        else
            SIGNATURE=$(generate_ed25519_signature "$DMG_PATH" "$SIGNING_KEY")
        fi

        if [ -n "$SIGNATURE" ]; then
            log_success "Signature generated"
        fi
    else
        log_warning "No signing key provided. Appcast will not be signed."
        log_info "To enable automatic update verification, generate a signing key and use --signing-key"
    fi

    # Generate appcast XML
    APPCAST_CONTENT=$(generate_appcast_xml "$VERSION" "$DMG_PATH" "$SIGNATURE" "$RELEASE_NOTES")

    # Output
    if [ "$DRY_RUN" = true ]; then
        log_info "Dry run - would generate appcast at: ${APPCAST_FILE}"
        echo ""
        echo "$APPCAST_CONTENT"
        echo ""
    else
        log_info "Generating appcast.xml..."
        echo "$APPCAST_CONTENT" > "$APPCAST_FILE"

        if [ $? -eq 0 ]; then
            log_success "Appcast generated: ${APPCAST_FILE}"
            echo ""
            echo "Next steps:"
            echo "  1. Review the appcast: cat ${APPCAST_FILE}"
            echo "  2. Commit to GitHub: git add ${APPCAST_FILE} && git push"
            echo "  3. Create GitHub release with the DMG/ZIP file"
            echo ""
            echo "GitHub Release URL:"
            echo "  https://github.com/hisgarden/QuickRecorder/releases/new?tag=v${VERSION}&title=v${VERSION}"
        else
            log_error "Failed to generate appcast"
            exit 1
        fi
    fi
}

# Run main
main "$@"

