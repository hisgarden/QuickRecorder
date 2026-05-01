#!/bin/bash
# Check detailed notarization errors via Keychain profile
# Usage: bash scripts/check-notarization.sh SUBMISSION_ID

set -euo pipefail

KEYCHAIN_PROFILE="QuickRecorder-notarize"

if [ -z "${1:-}" ]; then
    echo "Usage: bash scripts/check-notarization.sh SUBMISSION_ID"
    echo ""
    echo "Get submission ID from notarization.json:"
    echo "  cat archive/notarization.json | grep id"
    exit 1
fi

SUBMISSION_ID="$1"

# Verify the keychain profile exists. notarytool stores it via
# `xcrun notarytool store-credentials` -- run `--setup-keychain` first.
if ! xcrun notarytool history --keychain-profile "$KEYCHAIN_PROFILE" >/dev/null 2>&1; then
    echo "❌ Keychain profile '$KEYCHAIN_PROFILE' not found."
    echo "Run: ./scripts/buildRelease.sh --setup-keychain"
    exit 1
fi

echo "🔍 Checking notarization log..."
echo "   Submission: $SUBMISSION_ID"
echo "   Profile:    $KEYCHAIN_PROFILE"
echo ""

# Fetch the log -- macOS Keychain prompts for Touch ID / passcode on access.
xcrun notarytool log "$SUBMISSION_ID" \
    --keychain-profile "$KEYCHAIN_PROFILE" 2>&1
