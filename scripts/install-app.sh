#!/bin/bash
#
#  Install a QuickRecorder build into /Applications, replacing the old bundle
#  wholesale (never merging into it).
#
#  Usage:
#    ./scripts/install-app.sh [--force] [--dry-run] [path/to/QuickRecorder.app]
#
#  With no path, the most recently built Release app in DerivedData is used.
#
#  Steps:
#    1. Verify source and target are QuickRecorder (bundle id check)
#    2. Refuse a downgrade unless --force
#    3. Quit the app if it is running from the target path
#    4. Move the current bundle to archive/installed-backup-<timestamp>/
#    5. ditto the new bundle into place and verify its code signature
#
#  Environment (mainly for tests):
#    INSTALL_DIR   Install location (default: /Applications)
#    BACKUP_ROOT   Backup location  (default: <repo>/archive)
#

BUNDLE_ID="dev.hisgarden.QuickRecorder"
APP_NAME="QuickRecorder.app"

# version_compare <a> <b>: prints 1 if a > b, -1 if a < b, 0 if equal.
# Compares dot-separated numeric components; missing components count as 0.
version_compare() {
    local -a a b
    local i x y
    IFS=. read -ra a <<<"$1"
    IFS=. read -ra b <<<"$2"
    for ((i = 0; i < ${#a[@]} || i < ${#b[@]}; i++)); do
        x=$((10#${a[i]:-0}))
        y=$((10#${b[i]:-0}))
        if ((x > y)); then echo 1; return; fi
        if ((x < y)); then echo -1; return; fi
    done
    echo 0
}

plist_value() {
    plutil -extract "$2" raw "$1/Contents/Info.plist" 2>/dev/null || true
}

die() {
    echo "❌ $*" >&2
    exit 1
}

latest_release_build() {
    # shellcheck disable=SC2012  # need mtime ordering; paths are fixed-format
    ls -td "$HOME"/Library/Developer/Xcode/DerivedData/QuickRecorder-*/Build/Products/Release/"$APP_NAME" 2>/dev/null | head -1 || true
}

quit_if_running() {
    local target="$1" i
    pgrep -f "$target/Contents/MacOS/" >/dev/null || return 0
    echo "⏹  Quitting running QuickRecorder..."
    osascript -e "quit app id \"$BUNDLE_ID\"" >/dev/null 2>&1 || true
    for ((i = 0; i < 20; i++)); do
        pgrep -f "$target/Contents/MacOS/" >/dev/null || return 0
        sleep 0.5
    done
    die "QuickRecorder is still running; quit it and retry"
}

main() {
    local force=false dry_run=false src=""
    while [ $# -gt 0 ]; do
        case "$1" in
            --force) force=true ;;
            --dry-run) dry_run=true ;;
            -h|--help) sed -n '3,21p' "${BASH_SOURCE[0]}"; exit 0 ;;
            -*) die "Unknown option: $1" ;;
            *) src="$1" ;;
        esac
        shift
    done

    local repo_root
    repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
    local install_dir="${INSTALL_DIR:-/Applications}"
    local backup_root="${BACKUP_ROOT:-$repo_root/archive}"
    local target="$install_dir/$APP_NAME"

    [ -n "$src" ] || src="$(latest_release_build)"
    [ -n "$src" ] || die "No Release build found in DerivedData. Run 'just release' first."
    [ -d "$src" ] || die "Not found: $src"
    src="$(cd "$src" && pwd)"

    [ "$(plist_value "$src" CFBundleIdentifier)" = "$BUNDLE_ID" ] \
        || die "Source is not $BUNDLE_ID: $src"
    codesign --verify --deep --strict "$src" 2>/dev/null \
        || die "Source code signature is invalid: $src"

    local new_ver new_build
    new_ver="$(plist_value "$src" CFBundleShortVersionString)"
    new_build="$(plist_value "$src" CFBundleVersion)"
    [ -n "$new_ver" ] && [ -n "$new_build" ] \
        || die "Cannot read version from $src/Contents/Info.plist"
    echo "📦 Source:    $new_ver ($new_build)  $src"

    if [ -e "$target" ]; then
        [ "$(plist_value "$target" CFBundleIdentifier)" = "$BUNDLE_ID" ] \
            || die "Refusing to replace $target: it is not $BUNDLE_ID"

        local old_ver old_build cmp
        old_ver="$(plist_value "$target" CFBundleShortVersionString)"
        old_build="$(plist_value "$target" CFBundleVersion)"
        echo "💻 Installed: $old_ver ($old_build)  $target"

        cmp="$(version_compare "$new_ver" "$old_ver")"
        [ "$cmp" != 0 ] || cmp="$(version_compare "$new_build" "$old_build")"
        if [ "$cmp" = -1 ]; then
            $force || die "Downgrade from $old_ver ($old_build) to $new_ver ($new_build); pass --force to allow"
            echo "⚠️  Forcing downgrade"
        fi
    else
        echo "💻 Installed: none"
    fi

    if brew list --cask quickrecorder >/dev/null 2>&1; then
        echo "⚠️  Homebrew cask 'quickrecorder' is installed; 'brew upgrade' will overwrite this build"
    fi

    if $dry_run; then
        echo "🔎 Dry run: nothing changed"
        return 0
    fi

    local backup_dir=""
    if [ -e "$target" ]; then
        quit_if_running "$target"
        backup_dir="$backup_root/installed-backup-$(date +%Y-%m-%d-%H%M%S)"
        mkdir -p "$backup_dir"
        mv "$target" "$backup_dir/"
        echo "🗄  Backed up previous app to $backup_dir/$APP_NAME"
    fi

    # From here on a failure must put the previous app back, or nothing is installed.
    if ! ditto "$src" "$target" || ! codesign --verify --deep --strict "$target"; then
        rm -rf "$target"
        if [ -n "$backup_dir" ]; then
            mv "$backup_dir/$APP_NAME" "$target"
            rmdir "$backup_dir" 2>/dev/null || true
            die "Install failed; restored previous app at $target"
        fi
        die "Install failed; nothing installed at $target"
    fi
    echo "✅ Installed QuickRecorder $new_ver ($new_build) to $target"
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
    set -euo pipefail
    main "$@"
fi

################################################################################
# Changelog:
# 2026-10-29  Refuse unreadable source version; roll back if copy/verify fails
# 2026-10-27  Add install-app.sh: safe replace with backup and downgrade guard
################################################################################
