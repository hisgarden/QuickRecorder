#!/bin/bash

# Permission Behavior Test Runner for QuickRecorder v1.7.0 TCC Fix Validation
# This script runs the specific tests that validate the permission dialog fix

echo "🧪 Running QuickRecorder Permission Behavior Tests"
echo "=================================================="
echo ""

# Check if we're in the right directory
if [ ! -f "QuickRecorder.xcodeproj/project.pbxproj" ]; then
    echo "❌ Error: Run this script from the QuickRecorder root directory"
    echo "   Expected: QuickRecorder.xcodeproj should be in current directory"
    exit 1
fi

echo "📍 Current directory: $(pwd)"
echo "🎯 Testing the TCC permission dialog fix..."
echo ""

# Function to run a specific test
run_test() {
    local test_name=$1
    local description=$2
    
    echo "🔍 Running: $description"
    echo "   Test: $test_name"
    
    xcodebuild test \
        -project QuickRecorder.xcodeproj \
        -scheme QuickRecorder \
        -destination 'platform=macOS' \
        -only-testing:"QuickRecorderTests/$test_name" \
        2>/dev/null
    
    if [ $? -eq 0 ]; then
        echo "   ✅ PASSED"
    else
        echo "   ❌ FAILED"
        return 1
    fi
    echo ""
}

# Run the key permission behavior tests
echo "Running Key Permission Tests:"
echo "=============================="

# Primary test for the TCC fix
run_test "PermissionBehaviorTests/testPermissionRequestedOnlyOncePerAppLifetime" \
         "Single Permission Request Test (PRIMARY)"

# Test for infinite loop fix
run_test "PermissionBehaviorTests/testNoInfinitePermissionDialogs" \
         "No Infinite Dialog Loop Test"

# End-to-end workflow test
run_test "PermissionBehaviorTests/testCompleteAppLifecyclePermissionBehavior" \
         "Complete App Lifecycle Test"

# Test available content caching
run_test "PermissionBehaviorTests/testAvailableContentCaching" \
         "Permission Caching Test"

# Run additional permission tests from SCContextTests
echo "Running Additional Permission Tests:"
echo "==================================="

run_test "SCContextTests/testSCContext_PermissionRequestedOnlyOncePerAppLifetime" \
         "Multiple Permission Check Test"

run_test "SCContextTests/testSCContext_CachedPermissionHandling" \
         "Cached Permission Handling Test"

run_test "SCContextTests/testSCContext_MultipleRecordingAttemptsPermissionBehavior" \
         "Multiple Recording Attempts Test"

echo "📊 Test Summary:"
echo "==============="
echo "✅ If all tests PASSED, the TCC permission dialog fix is working correctly"
echo "❌ If any tests FAILED, there may be issues with the permission behavior"
echo ""
echo "🎯 What these tests validate:"
echo "   • Permission dialog only appears once per app lifetime"
echo "   • No infinite permission dialog loops"
echo "   • Cached permission state works correctly"
echo "   • Multiple recording attempts work without additional dialogs"
echo "   • Performance is acceptable"
echo ""
echo "📝 To run individual tests:"
echo "   xcodebuild test -project QuickRecorder.xcodeproj -scheme QuickRecorder -destination 'platform=macOS' -only-testing:QuickRecorderTests/PermissionBehaviorTests/testPermissionRequestedOnlyOncePerAppLifetime"
echo ""
echo "🚀 Ready to test the app manually:"
echo "   1. Build and run QuickRecorder"
echo "   2. Try to record (permission dialog should appear once)"
echo "   3. Try to record again (no permission dialog should appear)"
echo "   4. Try different recording types (no permission dialog should appear)" 