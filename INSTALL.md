# QuickRecorder Installation Guide

## Download and Install

1. Download `QuickRecorder-1.7.0.zip` from [GitHub Releases](https://github.com/hisgarden/QuickRecorder/releases)
2. Unzip the file
3. Move `QuickRecorder.app` to your Applications folder

## If you see "Apple could not verify" error

This happens because macOS adds a quarantine flag to downloaded files. **The app IS properly notarized**, but you need to tell macOS it's safe.

### Method 1: Right-click to open (Easiest)

1. **Right-click** (or Control-click) on `QuickRecorder.app`
2. Select **"Open"** from the menu
3. Click **"Open"** in the dialog that appears
4. The app will now open normally from now on

### Method 2: Remove quarantine flag (Terminal)

```bash
# Navigate to where you downloaded the app
cd ~/Downloads

# Remove the quarantine attribute
xattr -d com.apple.quarantine QuickRecorder.app

# Now you can open the app normally
open QuickRecorder.app
```

### Method 3: One-line installer

Copy and paste this into Terminal:

```bash
cd ~/Downloads && xattr -d com.apple.quarantine QuickRecorder.app && mv QuickRecorder.app /Applications/ && open /Applications/QuickRecorder.app
```

## Verification

To verify the app is properly notarized:

```bash
# Check code signature
codesign -dvv /Applications/QuickRecorder.app

# Check notarization
spctl -a -vv -t install /Applications/QuickRecorder.app

# You should see: "accepted" and "source=Notarized Developer ID"
```

## System Requirements

- macOS 12.3 or later
- Apple Silicon (M1/M2/M3) or Intel Mac

## Troubleshooting

### "QuickRecorder.app is damaged and can't be opened"

This usually means the app wasn't fully downloaded. Try:
1. Re-download the ZIP file
2. Verify the ZIP file size matches the GitHub release
3. Use the terminal method above

### Still having issues?

1. Check your macOS version: `sw_vers`
2. Open Console.app and look for "QuickRecorder" errors
3. Report the issue at: https://github.com/hisgarden/QuickRecorder/issues

## Why is this happening?

macOS adds a **quarantine attribute** to all files downloaded from the internet. Even though QuickRecorder is:
- ✅ Properly signed with a Developer ID certificate
- ✅ Notarized by Apple
- ✅ Passes all Gatekeeper checks

...you still need to use one of the methods above on first launch. This is normal macOS behavior for all apps distributed outside the Mac App Store.

## Security

QuickRecorder is:
- Open source: [View the code](https://github.com/hisgarden/QuickRecorder)
- Notarized by Apple (verified by Apple's servers)
- Signed with Developer ID: Jin Wen (NSDC3EDS2G)
- Scanned for malware by Apple before notarization approval

You can verify the notarization status at any time using the commands in the "Verification" section above.





