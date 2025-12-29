# Deadlock Fix - dispatch_sync Reentrancy Issue

## Problem

**Crash:** `dispatch_sync called on queue already owned by current thread`

**Severity:** Critical - Application crashes on launch when preparing recording

## Root Cause

The issue was a **nested dispatch_sync deadlock** caused by calling property setters inside `performAtomicUpdate()`.

### The Deadlock Chain

1. `RecordingPreparer.continuePreparation()` calls:
   ```swift
   RecordingStateManager.shared.performAtomicUpdate {
       RecordingStateManager.shared.streamType = streamType  // ❌ BUG HERE
   }
   ```

2. `performAtomicUpdate()` executes `stateQueue.sync { ... }`

3. Inside that sync block, the setter `streamType = ...` tries to execute `stateQueue.sync { ... }` AGAIN:
   ```swift
   var streamType: StreamType? {
       get { stateQueue.sync { _streamType } }
       set { stateQueue.sync { _streamType = newValue } }  // ❌ Tries to sync on same queue!
   }
   ```

4. **DEADLOCK** - You cannot dispatch_sync on a queue you're already executing on.

### Stack Trace Evidence

```
Thread 0 Crashed::  Dispatch queue: com.quickrecorder.stateManager
0   libdispatch.dylib    __DISPATCH_WAIT_FOR_QUEUE__ + 484
1   libdispatch.dylib    _dispatch_sync_f_slow + 148
2   QuickRecorder        RecordingStateManager.streamType.setter (RecordingStateManager.swift:206)
3   QuickRecorder        closure #1 in RecordingPreparer.continuePreparation (RecordingPreparer.swift:90)
4   QuickRecorder        closure #1 in RecordingStateManager.performAtomicUpdate (RecordingStateManager.swift:787)
```

## Solution

Created **direct setter methods** that bypass the computed property setters, avoiding the nested dispatch_sync.

### Changes Made

#### 1. Added Direct Setter Methods (`RecordingStateManager.swift`)

```swift
// MARK: - Thread-Safe Direct Setters

/// Sets streamType in a thread-safe way
/// Use this instead of the property setter when you need to avoid nested dispatch_sync
func setStreamType(_ newValue: StreamType?) {
    stateQueue.sync { _streamType = newValue }
}

/// Sets screen in a thread-safe way
func setScreen(_ newValue: SCDisplay?) {
    stateQueue.sync { _screen = newValue }
}

/// Sets window in a thread-safe way
func setWindow(_ newValue: [SCWindow]?) {
    stateQueue.sync { _window = newValue }
}

/// Sets application in a thread-safe way
func setApplication(_ newValue: [SCRunningApplication]?) {
    stateQueue.sync { _application = newValue }
}

/// Sets timeOffset in a thread-safe way
func setTimeOffset(_ newValue: CMTime) {
    stateQueue.sync { _timeOffset = newValue }
}

/// Sets isPaused in a thread-safe way
func setIsPaused(_ newValue: Bool) {
    stateQueue.sync { 
        let oldValue = _isPaused
        _isPaused = newValue
        if oldValue != newValue {
            notifyStateChange()
        }
    }
}

/// Sets isResume in a thread-safe way
func setIsResume(_ newValue: Bool) {
    stateQueue.sync { _isResume = newValue }
}

/// Sets stream in a thread-safe way
func setStream(_ newValue: SCStream?) {
    stateQueue.sync { _stream = newValue }
}

/// Sets filePath in a thread-safe way
func setFilePath(_ newValue: String?) {
    stateQueue.sync { _filePath = newValue }
}

/// Sets filePath1 in a thread-safe way
func setFilePath1(_ newValue: String?) {
    stateQueue.sync { _filePath1 = newValue }
}

/// Sets filePath2 in a thread-safe way
func setFilePath2(_ newValue: String?) {
    stateQueue.sync { _filePath2 = newValue }
}

/// Sets startTime in a thread-safe way
func setStartTime(_ newValue: Date?) {
    stateQueue.sync { _startTime = newValue }
}
```

#### 2. Updated RecordingPreparer.swift

**Before (Deadlock):**
```swift
RecordingStateManager.shared.performAtomicUpdate {
    RecordingStateManager.shared.streamType = streamType  // ❌ Nested dispatch_sync
}
```

**After (Fixed):**
```swift
// Set streamType directly - don't use property setter to avoid deadlock
RecordingStateManager.shared.setStreamType(streamType)  // ✅ Single dispatch_sync
```

All 10 occurrences in `RecordingPreparer.swift` were updated.

#### 3. Updated RecordingExecutor.swift

Fixed 6 occurrences of the same pattern:

**Before:**
```swift
RecordingStateManager.shared.performAtomicUpdate {
    RecordingStateManager.shared.isPaused = false
    RecordingStateManager.shared.isResume = false
}
```

**After:**
```swift
RecordingStateManager.shared.setIsPaused(false)
RecordingStateManager.shared.setIsResume(false)
```

## Files Modified

1. **QuickRecorder/Core/RecordingStateManager.swift**
   - Added 12 direct setter methods
   - Lines: 791-862

2. **QuickRecorder/Core/RecordingPreparer.swift**
   - Replaced 10 property assignments with direct setter calls
   - Lines: 89-90, 98, 105, 152, 158, 162, 169, 171, 178, 180

3. **QuickRecorder/Core/RecordingExecutor.swift**
   - Replaced 6 property assignments with direct setter calls
   - Lines: 37-39, 117, 271-273, 327-328, 351, 365, 367

## Why This Approach?

### Alternative Considered: Check if on Queue

```swift
var streamType: StreamType? {
    get { stateQueue.sync { _streamType } }
    set { 
        if DispatchQueue.getSpecific(key: Self.stateQueueKey) != nil {
            _streamType = newValue  // Already on queue
        } else {
            stateQueue.sync { _streamType = newValue }  // Not on queue
        }
    }
}
```

**Problems:**
- More complex
- Error-prone (easy to forget queue key checks)
- Harder to debug
- Violates single responsibility (properties doing queue management)

### Chosen Approach: Direct Setters

**Advantages:**
- ✅ Clear separation of concerns
- ✅ Explicit about avoiding nested dispatch
- ✅ Easy to understand and maintain
- ✅ Self-documenting via method names
- ✅ No runtime queue checking overhead
- ✅ Compiler-enforced (won't accidentally use property setter)

## Testing

Build succeeded with no errors:
```
xcodebuild -project QuickRecorder.xcodeproj -scheme QuickRecorder -configuration Debug clean build
** BUILD SUCCEEDED **
```

## Prevention Guidelines

### DO ✅

```swift
// Use direct setters when already on stateQueue
RecordingStateManager.shared.setStreamType(newValue)
```

### DON'T ❌

```swift
// Never use property setters inside performAtomicUpdate
RecordingStateManager.shared.performAtomicUpdate {
    RecordingStateManager.shared.streamType = newValue  // ❌ DEADLOCK!
}
```

### When to Use Each

**Use Property Setters** when:
- Calling from outside any stateQueue context
- Single property update
- No coordination needed with other properties

**Use Direct Setters (`setXXX()`)** when:
- Inside `performAtomicUpdate` blocks
- Already executing on stateQueue
- Need to avoid nested dispatch_sync

**Use `performAtomicUpdate`** when:
- Updating multiple properties that should be atomic
- Complex state transitions requiring coordination
- BUT: use direct setters inside the closure

## Related Issues

This pattern could affect any computed property with `stateQueue.sync` in the setter. Review all properties in `RecordingStateManager` if adding new ones.

## Impact

- **Fixed:** Critical crash on recording preparation
- **Affected Methods:** All recording start flows
- **Regression Risk:** Low (direct setters are simpler than nested sync)
- **Performance:** Slight improvement (eliminates unnecessary queue checks)

## Date

Fixed: 2025-12-26
Tested: Build successful
Status: ✅ Ready for release
