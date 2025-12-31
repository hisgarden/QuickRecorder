# Stapling Notarization Ticket Guide

After your app is notarized by Apple, you need to "staple" the notarization ticket to the app bundle. This embeds the approval directly into your app so users don't need an internet connection to verify it.

## What is Stapling?

**Stapling** attaches the notarization ticket to your app, making it self-contained. Without stapling:
- Users see "Checking with Apple..." when launching (requires internet)
- Offline verification fails

With stapling:
- App launches immediately (works offline)
- Notarization proof is embedded in the bundle

## Quick Start

### After Notarization Succeeds

Once `just notarize` completes successfully, wait a moment for Apple to process (usually < 1 minute), then:

```bash
just staple
```

This will:
1. Find the latest app in `archive/`
2. Staple the notarization ticket
3. Verify it worked

### Specific App Path

If you want to staple a specific app:

```bash
just staple archive/QuickRecorder-20251229-1407.app
```

Or using the script directly:

```bash
bash staple.sh archive/QuickRecorder-20251229-1407.app
```

## Step-by-Step Workflow

### 1. Start Notarization

```bash
just notarize
```

You'll see:
```
📋 Verifying prerequisites...
🔐 Verifying credentials...
🔗 Testing credentials with notarytool...
📦 Building and archiving...
🔏 Submitting for notarization...
(waiting for Apple...)
✅ Notarization completed successfully!
Submission ID: abc-123-def-456
```

### 2. Wait for Approval

Apple typically approves within 1-2 minutes. You can check status:

```bash
xcrun notarytool history \
    --apple-id your@email.com \
    --password xxxx-xxxx-xxxx-xxxx
```

Look for `Status: Accepted`

### 3. Staple the Ticket

```bash
just staple
```

Output:
```
🔏 Stapling Notarization Ticket

📍 Searching for notarized app...
✅ Found app: archive/QuickRecorder-20251229-1407.app

📌 Stapling notarization ticket...
✅ Stapling successful!

Your app is now ready for distribution:
  Location: archive/QuickRecorder-20251229-1407.app
```

### 4. Verify Stapling

```bash
codesign -dvv archive/QuickRecorder-20251229-1407.app
```

Look for `Authority=Developer ID` and `Timestamp=` entries

## Troubleshooting

### ❌ "No notarized app found"

**Cause:** No app in `archive/` directory.

**Solution:**
1. Run `just notarize` first
2. Or provide the explicit path: `just staple /path/to/app`

### ❌ "Stapling failed (you can try manually later)"

**Possible causes:**

#### 1. Notarization Not Yet Approved
Apple is still processing. Wait 1-2 minutes and try again:
```bash
just staple
```

#### 2. Network Issue
Temporary connection problem. Try again:
```bash
just staple
```

#### 3. Invalid Submission
The notarization might have failed. Check status:
```bash
xcrun notarytool history \
    --apple-id hisgarden@pm.me \
    --password glwq-supf-omii-osae \
    --team-id NSDC3EDS2G
```

If status is `Invalid` or `Rejected`, create a new submission:
```bash
just notarize
```

## Common Scenarios

### Scenario 1: Notarization Succeeds, Stapling Fails Immediately

**Cause:** Apple hasn't finished processing yet (normal, < 1 minute delay)

**Solution:**
```bash
# Wait 30 seconds
sleep 30

# Try again
just staple
```

### Scenario 2: Want to Staple Multiple Copies

```bash
# Staple original
just staple archive/QuickRecorder-20251229-1407.app

# Staple backup
just staple archive/QuickRecorder-20251229-1407-backup.app
```

### Scenario 3: Lost the App, Need to Re-Notarize

```bash
# Create a new submission (will generate new app)
just notarize

# After approval, staple
just staple
```

## Verification Commands

### Check Stapling Status

```bash
codesign -dvv archive/QuickRecorder.app 2>&1 | grep -E "Authority|Timestamp"
```

**Stapled** output includes:
```
Authority=Developer ID Application: Your Name (TEAM_ID)
Timestamp=... (timestamp from Apple)
```

**Not stapled** output:
```
Authority=Developer ID Application: Your Name (TEAM_ID)
(no Timestamp line)
```

### Check Detailed Info

```bash
xcrun stapler validate archive/QuickRecorder.app
```

Output:
```
The validate action worked!
```

### Check Notarization Status

```bash
xcrun notarytool history \
    --apple-id hisgarden@pm.me \
    --password glwq-supf-omii-osae \
    --team-id NSDC3EDS2G
```

Look for your submission ID and status.

## After Stapling: Distribution

Once stapled, you can:

### Create .dmg for Distribution
```bash
hdiutil create -volname QuickRecorder \
    -srcfolder archive/QuickRecorder.app \
    -ov -format UDZO \
    QuickRecorder.dmg
```

### Create .zip for Distribution
```bash
cd archive
zip -r QuickRecorder.zip QuickRecorder.app
cd ..
```

### Upload to GitHub Releases
```bash
# Upload QuickRecorder.dmg or QuickRecorder.zip
```

### Share Direct Download
Users can download and run without Gatekeeper warnings!

## Best Practices

1. **Always staple** - Never distribute unsigned notarized apps
2. **Test before distributing** - Launch the app locally after stapling
3. **Keep archives** - Store notarized apps for reference
4. **Use .dmg for macOS** - Standard distribution format
5. **Include checksum** - Let users verify download integrity

## Files Created

After notarization and stapling:

```
archive/
├── QuickRecorder-20251229-1407.xcarchive  # Full Xcode archive
├── QuickRecorder-20251229-1407.app        # Notarized & stapled app
├── QuickRecorder-20251229-1407.zip        # Zipped for distribution
└── notarization.json                       # Apple's response
```

## Quick Reference

| Task | Command |
|------|---------|
| Full workflow | `just notarize && sleep 30 && just staple` |
| Just staple | `just staple` |
| Staple specific app | `just staple path/to/app` |
| Check status | `xcrun notarytool history ...` |
| Verify stapling | `codesign -dvv path/to/app` |
| Create .dmg | `hdiutil create -volname QuickRecorder ...` |

## Related Commands

```bash
# Complete notarization workflow
just notarize              # Build + archive + submit for notarization
just staple                # Staple the ticket after approval
just logs                  # View build logs
just errors                # View build errors
```

---

**Need help?** Check the NOTARIZATION_SETUP.md and NOTARIZATION_VERIFICATION.md guides.

