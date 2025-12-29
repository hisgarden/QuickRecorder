#!/bin/sh
#
# Cleanup duplicate Screen Recording permissions for QuickRecorder
#
# This script helps remove duplicate entries from macOS Screen Recording permissions
# that can occur when the bundle identifier changes or multiple copies are installed.

set -e

BUNDLE_ID="dev.hisgarden.QuickRecorder"
OLD_BUNDLE_ID="com.lihaoyun6.QuickRecorder"

echo "========================================="
echo "QuickRecorder Permission Cleanup"
echo "========================================="
echo ""
echo "Current bundle identifier: $BUNDLE_ID"
echo "Old bundle identifier: $OLD_BUNDLE_ID"
echo ""

# Check if tccutil is available (macOS 10.14+)
if ! command -v tccutil >/dev/null 2>&1; then
    echo "⚠️  tccutil not found. This script requires macOS 10.14 or later."
    echo ""
    echo "Manual cleanup steps:"
    echo "1. Open System Settings > Privacy & Security > Screen Recording"
    echo "2. Remove the duplicate QuickRecorder entry (the one that's OFF)"
    echo "3. Keep only the entry that's ON"
    exit 1
fi

echo "📋 Current Screen Recording permissions:"
echo ""
tccutil reset ScreenCapture "$BUNDLE_ID" 2>/dev/null || echo "   No permission entry found for $BUNDLE_ID"
tccutil reset ScreenCapture "$OLD_BUNDLE_ID" 2>/dev/null || echo "   No permission entry found for $OLD_BUNDLE_ID"
echo ""

echo "✅ Reset Screen Recording permissions for both bundle identifiers"
echo ""
echo "Next steps:"
echo "1. Run QuickRecorder again"
echo "2. When prompted, grant Screen Recording permission"
echo "3. This should create a single, clean permission entry"
echo ""
echo "To verify, check:"
echo "   System Settings > Privacy & Security > Screen Recording"
echo ""

