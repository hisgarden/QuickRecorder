# QuickRecorder Debugging Guide

## Viewing Console Logs

There are several ways to view console logs for QuickRecorder:

### Method 1: Xcode Console (Recommended for Development)

If you're running the app from Xcode:

1. **Build and Run** the app from Xcode (⌘R)
2. The **Console** panel appears at the bottom of Xcode
3. Look for logs prefixed with:
   - `🔍` - Debug/Info messages
   - `✅` - Success messages
   - `⚠️` - Warnings
   - `❌` - Errors

**Filter logs**: Type "AppSelector" or "SCContext" in the console filter box to see only relevant messages.

### Method 2: macOS Console App

1. Open **Console.app** (Applications > Utilities > Console)
2. In the search box, type: `QuickRecorder` or `dev.hisgarden.QuickRecorder`
3. Select your Mac in the sidebar (under "Devices")
4. Run QuickRecorder and watch the logs appear

**Tip**: Use the search filter to narrow down logs:
- Search for: `AppSelector` or `SCContext`
- Or search for emoji: `🔍` or `✅` or `❌`

### Method 3: Terminal (Command Line)

Open Terminal and run:

```sh
# Stream all QuickRecorder logs in real-time
log stream --predicate 'process == "QuickRecorder"' --level debug

# Or filter for specific messages
log stream --predicate 'process == "QuickRecorder" AND (eventMessage CONTAINS "AppSelector" OR eventMessage CONTAINS "SCContext")' --level debug
```

**To stop streaming**: Press `Ctrl+C`

### Method 4: View Recent Logs

To see recent logs without streaming:

```sh
# Show last 50 log entries for QuickRecorder
log show --predicate 'process == "QuickRecorder"' --last 5m --style compact | tail -50
```

## What to Look For

When debugging the app list issue, look for these log sequences:

### Successful Flow:
```
🔍 AppSelector: Checking screen recording permission...
✅ AppSelector: Permission granted, fetching available content...
🔍 SCContext: Requesting available content from ScreenCaptureKit...
✅ SCContext: Received content - 1 display(s), 15 window(s), 8 application(s)
✅ AppSelector: Found 1 display(s), fetching windows...
📋 AppSelector: Found 12 window(s)
  Display 123456: 10 window(s) on this display
    - App: Safari (com.apple.Safari)
✅ AppSelector: Ready with 2 total app(s) across 1 display(s)
```

### Permission Issues:
```
🔍 AppSelector: Checking screen recording permission...
⚠️  AppSelector: Screen recording permission not granted
```

### Content Fetch Issues:
```
🔍 SCContext: Requesting available content from ScreenCaptureKit...
❌ SCContext: Error fetching available content: [error message]
```

### Empty Results:
```
✅ SCContext: Received content - 1 display(s), 0 window(s), 0 application(s)
⚠️  AppSelector: No displays found in content
```

## Quick Debug Commands

### Check if app is running:
```sh
ps aux | grep QuickRecorder
```

### View all QuickRecorder logs from last hour:
```sh
log show --predicate 'process == "QuickRecorder"' --last 1h --style compact
```

### Filter for specific error messages:
```sh
log show --predicate 'process == "QuickRecorder" AND eventMessage CONTAINS "Error"' --last 1h
```

## Common Issues

### No logs appearing?
- Make sure the app is actually running
- Check that you're filtering for the correct process name
- Try running from Xcode to see logs directly

### Too many logs?
- Use the search/filter features in Console.app
- Filter by specific keywords like "AppSelector" or "SCContext"
- Use the log level filter (Info, Debug, Error)

### Permission denied errors?
- Check System Settings > Privacy & Security > Screen Recording
- Make sure QuickRecorder has permission enabled

