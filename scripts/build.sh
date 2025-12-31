#!/bin/bash
# QuickRecorder build script with logging and exit code capture

set -euo pipefail

LOG_FILE="${1:-logs/build-$(date +%Y%m%d-%H%M%S).log}"

echo "============================================================" | tee "$LOG_FILE"
echo "  QuickRecorder Build with Analysis" | tee -a "$LOG_FILE"
echo "  Started: $(date)" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Configuration: Debug" | tee -a "$LOG_FILE"
echo "Log File: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Prerequisites:" | tee -a "$LOG_FILE"

if command -v xcodegen >/dev/null 2>&1; then
    echo "  ✅ XcodeGen" | tee -a "$LOG_FILE"
else
    echo "  ❌ XcodeGen missing" | tee -a "$LOG_FILE"
fi

if xcode-select -p >/dev/null 2>&1; then
    echo "  ✅ CLT" | tee -a "$LOG_FILE"
else
    echo "  ❌ CLT missing" | tee -a "$LOG_FILE"
fi

echo "" | tee -a "$LOG_FILE"
echo "Building..." | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Capture xcodebuild exit code correctly using PIPESTATUS
set +o pipefail
xcodebuild build \
    -project QuickRecorder.xcodeproj \
    -scheme QuickRecorder \
    -destination "platform=macOS" \
    -configuration Debug \
    CODE_SIGNING_ALLOWED=NO \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGN_IDENTITY="-" \
    2>&1 | tee -a "$LOG_FILE"
BUILD_RESULT=${PIPESTATUS[0]}
set -o pipefail

echo "" | tee -a "$LOG_FILE"
echo "============================================================" | tee -a "$LOG_FILE"

if [ "$BUILD_RESULT" -eq 0 ]; then
    echo "BUILD RESULT: ✅ Success" | tee -a "$LOG_FILE"
else
    echo "BUILD RESULT: ❌ Failed (exit code: $BUILD_RESULT)" | tee -a "$LOG_FILE"
fi

echo "============================================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

if [ "$BUILD_RESULT" -ne 0 ]; then
    echo "Error Summary:" | tee -a "$LOG_FILE"
    if grep -q "error:" "$LOG_FILE" 2>/dev/null; then
        grep "error:" "$LOG_FILE" | head -10 | nl | tee -a "$LOG_FILE"
    else
        echo "  (no errors found in log)" | tee -a "$LOG_FILE"
    fi
    echo "" | tee -a "$LOG_FILE"
fi

echo "Log: $LOG_FILE" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

exit "$BUILD_RESULT"





