# MainActor.run Async/Await Fix

## Problem

**Build Error:**
```
SCContext.swift:880:58: error: cannot pass function of type '@Sendable () async -> Bool' 
to parameter expecting synchronous function type
```

## Root Cause

`MainActor.run` expects a **synchronous** closure, but the code was passing an **async** closure with `await withCheckedContinuation`.

### The Buggy Code (Line 880)

```swift
let userOpenedSettings = await MainActor.run {
    return await withCheckedContinuation { continuation in  // ❌ Cannot await inside MainActor.run
        // ... alert code
    }
}
```

**Why it fails:**
- `MainActor.run(_:)` signature: `func run<T>(_ body: @MainActor @Sendable () -> T) -> T`
- The closure must be **synchronous** (no `async` or `await`)
- But we're using `await withCheckedContinuation`, making it async

## Solution

Restructured the code to use `Task { @MainActor in }` instead of `MainActor.run`:

### The Fix

**File:** `QuickRecorder/SCContext.swift`

**Before (Broken):**
```swift
let userOpenedSettings = await MainActor.run {
    return await withCheckedContinuation { continuation in
        // Alert code...
    }
}
```

**After (Fixed):**
```swift
let userOpenedSettings = await withCheckedContinuation { continuation in
    Task { @MainActor in  // ✅ Create MainActor task instead
        let alert = NSAlert()
        // ... alert code ...
    }
}
```

### Key Changes

1. **Moved `withCheckedContinuation` outside**: Now it's the outer await
2. **Wrapped UI code in `Task { @MainActor in }`**: Ensures alert runs on main thread
3. **Continuation resumes from completion handler**: Alert callback resumes the continuation

## Why This Works

```swift
// Outer continuation waits for inner Task to complete
await withCheckedContinuation { continuation in
    // Create a MainActor task (doesn't need to be awaited here)
    Task { @MainActor in
        // UI code runs on main thread
        alert.beginSheetModal(for: window) { response in
            // Callback resumes the outer continuation
            continuation.resume(returning: true/false)
        }
    }
}
```

**Flow:**
1. `withCheckedContinuation` suspends current task
2. `Task { @MainActor in }` starts new task on main thread
3. Alert is shown (non-blocking modal sheet)
4. User clicks button → callback fires
5. `continuation.resume()` resumes the suspended task
6. `userOpenedSettings` gets the boolean result

## Technical Details

### MainActor.run vs Task { @MainActor in }

| `MainActor.run` | `Task { @MainActor in }` |
|----------------|--------------------------|
| Synchronous closure only | Can be async |
| Returns immediately | Returns Task handle |
| Blocks current task | Spawns new task |
| Use for quick sync work | Use for async/await work |

### When to Use Each

**Use `MainActor.run`:**
```swift
await MainActor.run {
    label.text = "Hello"  // ✅ Quick sync UI update
    return someValue
}
```

**Use `Task { @MainActor in }`:**
```swift
Task { @MainActor in
    let result = await fetchData()  // ✅ Async work on main thread
    label.text = result
}
```

## Impact

- **Fixed:** Build error preventing compilation
- **Behavior:** Unchanged - alert still shows on main thread correctly
- **Thread Safety:** Maintained - UI still runs on MainActor
- **No Breaking Changes:** Same async/await flow

## Changes Made

**File:** `QuickRecorder/SCContext.swift`
- **Line 878-913:** Restructured MainActor usage
- **Changed:** `await MainActor.run { return await ... }` 
- **To:** `await withCheckedContinuation { Task { @MainActor in ... } }`

## Testing

Build succeeds:
```bash
xcodebuild -project QuickRecorder.xcodeproj -scheme QuickRecorder build
** BUILD SUCCEEDED **
```

## Related Documentation

- [Swift Concurrency: MainActor](https://developer.apple.com/documentation/swift/mainactor)
- [withCheckedContinuation](https://developer.apple.com/documentation/swift/withcheckedcontinuation(function:_:))
- [Task { @MainActor in }](https://developer.apple.com/documentation/swift/task)

## Date

Fixed: 2025-12-27  
Status: ✅ Build successful  
Issue: Type mismatch in MainActor.run  
Solution: Use Task { @MainActor in } for async closures
