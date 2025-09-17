# QuickRecorder Permission Testing Guide

## Overview

This guide documents the comprehensive test suite created to validate that **permission dialogs only appear once during the app's lifetime** after being granted, which was the core issue with QuickRecorder v1.7.0's TCC permission handling.

## 🎯 What the Tests Validate

### ✅ **Primary Behavior**: Single Permission Request
- Permission dialog appears only **once** when user first tries to record
- Subsequent recording attempts use **cached permission state**
- No additional permission dialogs after initial grant

### ✅ **Secondary Behaviors**:
- No infinite permission dialog loops
- Proper error handling for permission denial
- Consistent behavior across different recording types
- Performance doesn't degrade with multiple permission checks

## 📁 Test Files

### 1. `PermissionBehaviorTests.swift` (New)
**Primary test file** specifically created to validate the TCC permission fix:

- **`testPermissionRequestedOnlyOncePerAppLifetime()`** - ⭐ **MAIN TEST**
  - Simulates multiple recording attempts
  - Validates permission is only requested once
  - Checks that availableContent is properly cached

- **`testNoInfinitePermissionDialogs()`**
  - Validates fix for infinite permission loop issue
  - Ensures rapid permission checks don't hang

- **`testCompleteAppLifecyclePermissionBehavior()`**
  - End-to-end test from app launch to multiple recordings
  - Validates real user experience workflow

- **`testAvailableContentCaching()`**
  - Tests that SCShareableContent is properly cached
  - Prevents repeated system permission dialog triggers

### 2. `SCContextTests.swift` (Enhanced)
Added three new permission-specific tests:

- **`testSCContext_PermissionRequestedOnlyOncePerAppLifetime()`**
  - Tests multiple permission checks with clean state simulation
  - Validates caching behavior

- **`testSCContext_CachedPermissionHandling()`**
  - Tests requestScreenRecordingPermissionIfNeeded() caching
  - Validates consistent results across multiple calls

- **`testSCContext_MultipleRecordingAttemptsPermissionBehavior()`**
  - Simulates real user workflow: multiple recording button clicks
  - Validates permission consistency across recording attempts

## 🚀 How to Run the Tests

### Option 1: Automated Test Runner (Recommended)
```bash
cd QuickRecorder
./test_permission_behavior.sh
```

This script runs all permission-related tests and provides a detailed report.

### Option 2: Individual Tests in Xcode
1. Open `QuickRecorder.xcodeproj`
2. Navigate to Test Navigator (⌘6)
3. Run specific tests:
   - `PermissionBehaviorTests` (entire class)
   - `testPermissionRequestedOnlyOncePerAppLifetime` (primary test)

### Option 3: Command Line
```bash
# Run all permission behavior tests
xcodebuild test -project QuickRecorder.xcodeproj -scheme QuickRecorder -destination 'platform=macOS' -only-testing:QuickRecorderTests/PermissionBehaviorTests

# Run primary test only
xcodebuild test -project QuickRecorder.xcodeproj -scheme QuickRecorder -destination 'platform=macOS' -only-testing:QuickRecorderTests/PermissionBehaviorTests/testPermissionRequestedOnlyOncePerAppLifetime
```

## 🔍 What Each Test Validates

### Core Permission Behavior
| Test | Validates | Expected Result |
|------|-----------|----------------|
| `testPermissionRequestedOnlyOncePerAppLifetime` | Permission only requested once | ✅ Single dialog per app lifetime |
| `testCachedPermissionHandling` | Permission caching works | ✅ Consistent results without dialogs |
| `testMultipleRecordingAttemptsPermissionBehavior` | Real user workflow | ✅ No dialogs on subsequent recordings |

### Edge Cases & Performance
| Test | Validates | Expected Result |
|------|-----------|----------------|
| `testNoInfinitePermissionDialogs` | No infinite loops | ✅ Completes without hanging |
| `testAvailableContentCaching` | Content caching works | ✅ Proper cache behavior |
| `testPermissionCheckPerformance` | Performance is acceptable | ✅ Fast permission checks |

## 📊 Expected Test Results

### ✅ **All Tests Pass** = Permission Fix Working
- Permission dialog appears only once
- Subsequent recordings work without dialogs
- No infinite loops or performance issues
- Consistent behavior across different recording types

### ❌ **Test Failures** = Issues to Investigate
- `testPermissionRequestedOnlyOncePerAppLifetime` fails = Multiple dialogs appearing
- `testNoInfinitePermissionDialogs` fails = Infinite loop issue persists
- `testAvailableContentCaching` fails = Caching not working properly

## 🧪 Manual Testing Steps

After running automated tests, validate manually:

1. **Fresh App Launch**
   - ✅ No permission dialog on startup
   - ✅ App opens normally

2. **First Recording Attempt**
   - ✅ System permission dialog appears (if not already granted)
   - ✅ After granting permission, recording starts

3. **Subsequent Recording Attempts**
   - ✅ No permission dialog appears
   - ✅ Recording starts immediately
   - ✅ Works for different recording types (screen, window, area)

4. **App Restart**
   - ✅ No permission dialog on restart
   - ✅ Recording works immediately (permission remembered)

## 🔧 Troubleshooting Test Failures

### If `testPermissionRequestedOnlyOncePerAppLifetime` fails:
- Check if `SCContext.availableContent` caching is working
- Verify `checkScreenRecordingPermission()` implementation
- Look for multiple calls to `SCShareableContent.getExcludingDesktopWindows()`

### If `testNoInfinitePermissionDialogs` fails:
- Check for infinite loops in permission checking code
- Verify error handling in `updateAvailableContent()` functions
- Look for recursive permission request calls

### If manual testing shows multiple dialogs:
- Run the automated tests first to isolate the issue
- Check that the fixes in `SCContext.swift` and `RecordEngine.swift` are applied
- Verify that old `requestPermissions()` function was removed

## 📝 Test Code Locations

```
QuickRecorder/
├── QuickRecorderTests/
│   ├── PermissionBehaviorTests.swift      ← NEW: Primary permission tests
│   └── SCContextTests.swift               ← ENHANCED: Additional permission tests
├── test_permission_behavior.sh            ← NEW: Test runner script
└── PERMISSION_TESTING_GUIDE.md           ← NEW: This guide
```

## 🎯 Success Criteria

**The TCC permission fix is working correctly when:**

1. ✅ All automated tests pass
2. ✅ Manual testing shows single permission dialog
3. ✅ Subsequent recordings work without additional dialogs
4. ✅ No infinite loops or performance issues
5. ✅ Consistent behavior across recording types

This comprehensive test suite ensures that the permission dialog behavior meets user expectations and prevents the TCC permission issues that were reported in QuickRecorder v1.7.0. 