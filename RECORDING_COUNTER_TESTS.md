# Recording Counter Test Cases

## Overview
Test cases added to verify that the recording timer/counter appears and counts correctly when the record button is pressed.

## Test File
`QuickRecorderTests/RecordingStateManagerTests.swift`

## Added Test Cases

### 1. `testRecordingLengthCounter_ShowsImmediatelyOnStart()`
**Purpose:** Verifies that the recording counter shows "00:00" immediately when recording starts.

**Test Steps:**
1. Verify start time is nil before recording
2. Start recording
3. Check that start time is set immediately
4. Verify recording length shows "00:00"

**Expected Result:** Counter displays "00:00" immediately after pressing record button.

---

### 2. `testRecordingLengthCounter_CountsUpOverTime()`
**Purpose:** Verifies the counter increments correctly over time.

**Test Steps:**
1. Start recording (counter shows "00:00")
2. Wait 1.5 seconds
3. Check recording length

**Expected Result:** Counter advances to "00:01" after ~1.5 seconds.

---

### 3. `testRecordingLengthCounter_UpdatesCorrectlyAfterMultipleSeconds()`
**Purpose:** Tests counter accuracy over longer durations.

**Test Steps:**
1. Start recording
2. Wait 3.5 seconds
3. Check recording length

**Expected Result:** Counter shows "00:03" or "00:04" after ~3.5 seconds.

---

### 4. `testRecordingLengthCounter_NoRaceCondition()`
**Purpose:** Verifies the fix for the race condition where startTime was set asynchronously.

**Test Steps:**
1. Start recording
2. Call `getRecordingLength()` multiple times in rapid succession
3. Verify start time is never nil

**Expected Result:** All calls return valid time (not stuck at "00:00" due to nil startTime).

**This test specifically validates the fix:** Changed from `stateQueue.async` to `stateQueue.sync` in `startRecording()`.

---

### 5. `testRecordingLengthCounter_RealisticTimerScenario()`
**Purpose:** Simulates the real StatusBar timer scenario (updates every 0.5 seconds).

**Test Steps:**
1. Start recording
2. Read counter at 0.5s intervals for 2 seconds (5 readings total)
3. Verify progression

**Expected Result:** 
- First reading: "00:00"
- Last reading: "00:01" or "00:02"
- Counter progresses naturally

---

### 6. `testRecordingLengthCounter_ShowsPausedTime()`
**Purpose:** Verifies counter freezes at paused time.

**Test Steps:**
1. Start recording, wait 1.5s
2. Pause recording
3. Wait 1s while paused
4. Check counter hasn't advanced

**Expected Result:** Counter stays at "00:01" while paused.

---

### 7. `testRecordingLengthCounter_ResumesCorrectlyAfterUnpause()`
**Purpose:** Verifies counter resumes from correct position after unpause.

**Test Steps:**
1. Record for 1.5s, pause, wait 1s
2. Resume recording
3. Wait 1.5s more
4. Check counter

**Expected Result:** Counter continues from paused time (shows "00:02" or "00:03").

---

## Running the Tests

### Run all counter tests:
```bash
xcodebuild test -project QuickRecorder.xcodeproj \
  -scheme QuickRecorder \
  -destination 'platform=macOS' \
  -only-testing:QuickRecorderTests/RecordingStateManagerTests
```

### Run a specific test:
```bash
xcodebuild test -project QuickRecorder.xcodeproj \
  -scheme QuickRecorder \
  -destination 'platform=macOS' \
  -only-testing:QuickRecorderTests/RecordingStateManagerTests/testRecordingLengthCounter_ShowsImmediatelyOnStart
```

## What These Tests Verify

✅ **Counter appears immediately** when record button is pressed  
✅ **Counter starts at "00:00"** and counts up  
✅ **No race condition** - startTime is set synchronously  
✅ **Counter updates every 0.5s** as expected in the UI  
✅ **Pause/Resume works correctly** - counter freezes and resumes properly  
✅ **Timer is accurate** over multiple seconds

## Related Code

- **Recording State Manager:** `QuickRecorder/Core/RecordingStateManager.swift` (lines 314-337)
- **Status Bar Timer:** `QuickRecorder/ViewModel/StatusBar.swift` (line 138-142)
- **Timer Display:** `QuickRecorder/ViewModel/StatusBar.swift` (lines 91, 126)

## The Race Condition Fix

The bug was that `startRecording()` used `stateQueue.async`, which returned immediately before `_startTime` was set. This caused the timer to show "00:00" indefinitely.

**Fix:** Changed to `stateQueue.sync` to ensure `_startTime` is set before the method returns.

```swift
// Before (Buggy):
func startRecording() {
    stateQueue.async { [weak self] in  // ❌ Returns immediately
        self?._startTime = Date()
        // ...
    }
}

// After (Fixed):
func startRecording() {
    stateQueue.sync {  // ✅ Blocks until complete
        _startTime = Date()
        // ...
    }
}
```

## Test Results

All tests **PASSED** ✅

The recording counter now:
- Shows immediately when recording starts
- Counts up correctly
- Has no race condition issues
- Works correctly with pause/resume
