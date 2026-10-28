#!/bin/bash
#
#  Tests for scripts/install-app.sh
#  Builds throwaway ad-hoc-signed QuickRecorder.app bundles in a temp dir and
#  installs them into a fake INSTALL_DIR, so /Applications is never touched.
#
#  Usage:
#    ./scripts/tests/test-install-app.sh
#

set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/../install-app.sh"
BUNDLE_ID="dev.hisgarden.QuickRecorder"

PASS=0
FAIL=0
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

assert_eq() {
    if [ "$2" = "$3" ]; then pass "$1"; else fail "$1 (expected '$2', got '$3')"; fi
}

# make_app <dest_dir> <version> <build> [bundle_id]
make_app() {
    local app="$1/QuickRecorder.app"
    mkdir -p "$app/Contents/MacOS"
    cp /usr/bin/true "$app/Contents/MacOS/QuickRecorder"
    plutil -create xml1 "$app/Contents/Info.plist"
    plutil -insert CFBundleIdentifier -string "${4:-$BUNDLE_ID}" "$app/Contents/Info.plist"
    plutil -insert CFBundleExecutable -string QuickRecorder "$app/Contents/Info.plist"
    plutil -insert CFBundleShortVersionString -string "$2" "$app/Contents/Info.plist"
    plutil -insert CFBundleVersion -string "$3" "$app/Contents/Info.plist"
    codesign --force --sign - "$app" 2>/dev/null
}

installed_version() {
    plutil -extract CFBundleShortVersionString raw "$INSTALL_DIR/QuickRecorder.app/Contents/Info.plist"
}

# reset <installed_version> <installed_build> [installed_bundle_id]
reset() {
    rm -rf "$WORK/install" "$WORK/backup" "$WORK/src"
    export INSTALL_DIR="$WORK/install" BACKUP_ROOT="$WORK/backup"
    mkdir -p "$INSTALL_DIR" "$BACKUP_ROOT"
    make_app "$INSTALL_DIR" "$1" "$2" "${3:-$BUNDLE_ID}"
}

run_install() {
    "$INSTALL_SCRIPT" "$@" >"$WORK/out.log" 2>&1
}

echo "version_compare"
# shellcheck source=SCRIPTDIR/../install-app.sh
source "$INSTALL_SCRIPT"
assert_eq "equal versions"       0  "$(version_compare 1.7.1 1.7.1)"
assert_eq "patch upgrade"        1  "$(version_compare 1.7.2 1.7.1)"
assert_eq "minor downgrade"      -1 "$(version_compare 1.6.9 1.7.1)"
assert_eq "numeric not lexical"  1  "$(version_compare 1.10.0 1.9.0)"
assert_eq "missing component"    0  "$(version_compare 1.7 1.7.0)"

echo "upgrade replaces the bundle wholesale"
reset 1.7.1 171
touch "$INSTALL_DIR/QuickRecorder.app/Contents/stale-file"
make_app "$WORK/src" 1.7.2 172
if run_install "$WORK/src/QuickRecorder.app"; then pass "exit 0"; else fail "exit 0"; fi
assert_eq "new version installed" 1.7.2 "$(installed_version)"
if [ ! -e "$INSTALL_DIR/QuickRecorder.app/Contents/stale-file" ]; then
    pass "stale file removed"
else
    fail "stale file removed"
fi
BACKUP_APP="$(find "$BACKUP_ROOT" -maxdepth 2 -path "*/installed-backup-*/QuickRecorder.app" | head -1)"
assert_eq "old bundle backed up" 1.7.1 \
    "$(plutil -extract CFBundleShortVersionString raw "$BACKUP_APP/Contents/Info.plist" 2>/dev/null)"

echo "downgrade is refused without --force"
reset 1.7.1 171
make_app "$WORK/src" 1.6.9 169
if run_install "$WORK/src/QuickRecorder.app"; then fail "non-zero exit"; else pass "non-zero exit"; fi
assert_eq "installed app untouched" 1.7.1 "$(installed_version)"

echo "downgrade is allowed with --force"
if run_install --force "$WORK/src/QuickRecorder.app"; then pass "exit 0"; else fail "exit 0"; fi
assert_eq "forced version installed" 1.6.9 "$(installed_version)"

echo "same version, newer build is an upgrade"
reset 1.7.1 171
make_app "$WORK/src" 1.7.1 172
if run_install "$WORK/src/QuickRecorder.app"; then pass "exit 0"; else fail "exit 0"; fi

echo "same version, older build is refused"
reset 1.7.1 172
make_app "$WORK/src" 1.7.1 171
if run_install "$WORK/src/QuickRecorder.app"; then fail "non-zero exit"; else pass "non-zero exit"; fi

echo "foreign target bundle is never deleted"
reset 1.0.0 100 com.example.Other
make_app "$WORK/src" 1.7.2 172
if run_install "$WORK/src/QuickRecorder.app"; then fail "non-zero exit"; else pass "non-zero exit"; fi
assert_eq "foreign app untouched" 1.0.0 "$(installed_version)"

echo "foreign source bundle is rejected"
reset 1.7.1 171
make_app "$WORK/src" 9.9.9 999 com.example.Other
if run_install "$WORK/src/QuickRecorder.app"; then fail "non-zero exit"; else pass "non-zero exit"; fi
assert_eq "installed app untouched" 1.7.1 "$(installed_version)"

echo "--dry-run changes nothing"
reset 1.7.1 171
make_app "$WORK/src" 1.7.2 172
if run_install --dry-run "$WORK/src/QuickRecorder.app"; then pass "exit 0"; else fail "exit 0"; fi
assert_eq "installed app untouched" 1.7.1 "$(installed_version)"
assert_eq "no backup made" "" "$(ls "$BACKUP_ROOT")"

echo "fresh install with nothing in place"
reset 1.7.1 171
rm -rf "$INSTALL_DIR/QuickRecorder.app"
make_app "$WORK/src" 1.7.2 172
if run_install "$WORK/src/QuickRecorder.app"; then pass "exit 0"; else fail "exit 0"; fi
assert_eq "version installed" 1.7.2 "$(installed_version)"

echo "missing source fails cleanly"
reset 1.7.1 171
if run_install "$WORK/does-not-exist.app"; then fail "non-zero exit"; else pass "non-zero exit"; fi

echo ""
echo "Passed: $PASS  Failed: $FAIL"
[ "$FAIL" -eq 0 ]

################################################################################
# Changelog:
# 2026-10-27  Add tests for install-app.sh (upgrade, downgrade guard, safety)
################################################################################
