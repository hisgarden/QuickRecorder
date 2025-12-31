#!/bin/bash
# Check detailed notarization errors
# Usage: bash scripts/check-notarization.sh SUBMISSION_ID

if [ -z "$1" ]; then
    echo "Usage: bash scripts/check-notarization.sh SUBMISSION_ID"
    echo ""
    echo "Get submission ID from notarization.json:"
    echo "  cat archive/notarization.json | grep id"
    exit 1
fi

SUBMISSION_ID="$1"

# Load credentials from .env if available
if [ -f ".env" ]; then
    set -a
    source .env 2>/dev/null || true
    set +a
fi

# Check if we have credentials
if [ -z "$APPLE_ID" ]; then
    echo "❌ APPLE_ID not found"
    echo "Please set APPLE_ID in .env or environment"
    exit 1
fi

if [ -z "$APP_SPECIFIC_PASSWORD" ]; then
    echo "❌ APP_SPECIFIC_PASSWORD not found"
    echo "Please set APP_SPECIFIC_PASSWORD in .env or environment"
    exit 1
fi

TEAM_ID="${APPLE_TEAM_ID:-}"

echo "🔍 Checking notarization errors..."
echo "   Submission: $SUBMISSION_ID"
echo "   Apple ID: $APPLE_ID"
[ -n "$TEAM_ID" ] && echo "   Team ID: $TEAM_ID"
echo ""

# Fetch the log
if [ -n "$TEAM_ID" ]; then
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" \
        --team-id "$TEAM_ID" 2>&1
else
    xcrun notarytool log "$SUBMISSION_ID" \
        --apple-id "$APPLE_ID" \
        --password "$APP_SPECIFIC_PASSWORD" 2>&1
fi





