# Code Signing & Notarization Guide

For macOS app distribution, you must **code sign** your app and get Apple's **notarization approval**. This guide walks through the complete process.

## Overview

```
1. Get Developer ID Certificates
    ↓
2. Import Certificates into Keychain
    ↓
3. Configure Xcode with Team ID
    ↓
4. Build with Code Signing
    ↓
5. Notarize with Apple
    ↓
6. Staple Ticket
    ↓
✅ Ready to Distribute!
```

## Requirements

- Apple Developer Account ($99/year)
- Mac with Xcode installed
- Developer ID certificate (for application signing)
- App-specific password (for notarization)

## Step 1: Get Developer ID Certificates

### 1.1 Create Certificates on Apple Developer Website

1. Go to [developer.apple.com](https://developer.apple.com)
2. Sign in with your Apple ID
3. Go to **Certificates, Identifiers & Profiles** → **Certificates**
4. Click **+** to create a new certificate
5. Select **Developer ID Application**
6. Follow the steps to create a Certificate Signing Request (CSR)
7. Download the certificate and double-click to install in Keychain

### 1.2 Verify Certificate in Keychain

```bash
# Open Keychain
open ~/Library/Keychains/login.keychain-db

# Look for: "Developer ID Application: Your Name (TEAMID)"
```

## Step 2: Configure Xcode

### 2.1 Set Team ID

The build scripts need to know your Team ID. Your Team ID is the 10-character code in your certificate (e.g., `NSDC3EDS2G`).

**Option A: Via project.yml**
```yaml
settings:
  DEVELOPMENT_TEAM: NSDC3EDS2G
  CODE_SIGN_IDENTITY: "Developer ID Application"
```

**Option B: Via .env file**
```bash
echo 'APPLE_TEAM_ID=NSDC3EDS2G' >> .env
```

**Option C: Via command line**
```bash
export DEVELOPMENT_TEAM=NSDC3EDS2G
just notarize
```

### 2.2 Find Your Team ID

```bash
# From certificate in Keychain
security find-identity -v -p codesigning

# Output:
#   1) ABC123DEF "Developer ID Application: Your Name (NSDC3EDS2G)"
# Your Team ID is NSDC3EDS2G
```

## Step 3: Build with Code Signing

### Standard Build (with signing)

```bash
just notarize
```

This now:
1. ✅ Builds with code signing enabled
2. ✅ Enables hardened runtime
3. ✅ Adds secure timestamp
4. ✅ Archives the app
5. ✅ Notarizes with Apple
6. ✅ Staples the ticket

### Manual Code Signing

```bash
# Sign an existing app
codesign --deep --force --verify --verbose \
    --sign "Developer ID Application: Your Name (NSDC3EDS2G)" \
    --timestamp \
    --options runtime \
    ./QuickRecorder.app
```

## Step 4: Notarization

### Submit for Notarization

```bash
just notarize
```

The script will:
1. Verify prerequisites
2. Check credentials
3. Build and sign
4. Archive and zip
5. Submit to Apple
6. Wait for approval (~1-2 minutes)
7. Staple the ticket

### Manual Submission

```bash
# Submit for notarization
xcrun notarytool submit QuickRecorder.zip \
    --apple-id your@email.com \
    --password xxxx-xxxx-xxxx-xxxx \
    --team-id NSDC3EDS2G \
    --wait

# Wait for status: "Accepted"
```

## Step 5: Stapling

### Automatic Stapling

The `just notarize` command now staples automatically. But you can staple manually:

```bash
just staple archive/QuickRecorder.app
```

### Manual Stapling

```bash
xcrun stapler staple QuickRecorder.app
```

## Troubleshooting

### ❌ "The binary is not signed"

**Cause:** Build was done with `CODE_SIGNING_ALLOWED=NO`

**Solution:**
```bash
# Update project.yml or build settings
# Ensure CODE_SIGNING_ALLOWED is NOT set to NO
just notarize
```

### ❌ "The signature does not include a secure timestamp"

**Cause:** Signing was done without `--timestamp`

**Solution:**
```bash
# The notarize script now adds --timestamp automatically
# Or manually:
codesign --sign "Developer ID Application: ..." \
    --timestamp \
    ./QuickRecorder.app
```

### ❌ "The executable does not have the hardened runtime enabled"

**Cause:** Build doesn't have `ENABLE_HARDENED_RUNTIME=YES`

**Solution:**
```bash
# Update build settings
# The notarize script now sets ENABLE_HARDENED_RUNTIME=YES
just notarize
```

### ❌ "The binary is not signed with a valid Developer ID certificate"

**Cause:** Certificate not found or Team ID mismatch

**Solution:**
1. Verify certificate in Keychain:
   ```bash
   security find-identity -v -p codesigning
   ```

2. Verify Team ID matches:
   ```bash
   # In your certificate name: Developer ID Application: Name (TEAMID)
   cat .env | grep APPLE_TEAM_ID
   ```

3. Re-sign the app:
   ```bash
   codesign --deep --force --verify --verbose \
       --sign "Developer ID Application: Your Name (NSDC3EDS2G)" \
       --timestamp \
       --options runtime \
       ./QuickRecorder.app
   ```

### ❌ "Credential test failed"

**Cause:** Invalid Apple ID or password

**Solution:**
1. Verify Apple ID email
2. Verify app-specific password (not Apple ID password)
3. Get new app-specific password: [appleid.apple.com](https://appleid.apple.com/account/manage)

## Build Settings Reference

### Code Signing Settings

```yaml
# In project.yml
settings:
  DEVELOPMENT_TEAM: NSDC3EDS2G
  CODE_SIGN_IDENTITY: "Developer ID Application"
  CODE_SIGNING_REQUIRED: YES
  CODE_SIGNING_ALLOWED: YES
  ENABLE_HARDENED_RUNTIME: YES
  OTHER_CODE_SIGN_FLAGS: "--timestamp"
```

### What Each Does

| Setting | Purpose |
|---------|---------|
| `DEVELOPMENT_TEAM` | Your Apple Developer Team ID |
| `CODE_SIGN_IDENTITY` | Type of certificate to use |
| `CODE_SIGNING_REQUIRED` | Must be signed (YES) |
| `CODE_SIGNING_ALLOWED` | Allow signing (YES) |
| `ENABLE_HARDENED_RUNTIME` | Enable hardened runtime (required for notarization) |
| `OTHER_CODE_SIGN_FLAGS` | Additional flags like `--timestamp` |

## Verification

### Check if App is Signed

```bash
codesign -dvv QuickRecorder.app

# Output should show:
# Identifier=dev.hisgarden.QuickRecorder
# CodeDirectory v=... length=...
# Authority=Developer ID Application: Your Name (TEAMID)
# Timestamp=...
```

### Check Hardened Runtime

```bash
codesign -dvv QuickRecorder.app | grep runtime

# Should show: runtime enabled
```

### Check Notarization Status

```bash
xcrun notarytool history \
    --apple-id your@email.com \
    --password xxxx-xxxx-xxxx-xxxx \
    --team-id NSDC3EDS2G

# Look for Status: "Accepted"
```

## Quick Reference

| Task | Command |
|------|---------|
| Full workflow | `just notarize` |
| Sign existing app | `codesign --deep --force --sign "Developer ID Application: ..." --timestamp --options runtime ./app` |
| Check signature | `codesign -dvv app` |
| Notarize manually | `xcrun notarytool submit app.zip --apple-id ... --password ... --team-id ... --wait` |
| Staple ticket | `just staple` |
| Check status | `xcrun notarytool history --apple-id ... --password ...` |

## Common Issues Summary

| Issue | Fix |
|-------|-----|
| Binary not signed | Enable code signing in build |
| No hardened runtime | Add `ENABLE_HARDENED_RUNTIME=YES` |
| No timestamp | Add `--timestamp` to signing |
| Wrong Team ID | Update `.env` or project settings |
| Invalid credential | Get new app-specific password |

## Apple Resources

- [Notarizing macOS Software Before Distribution](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Resolving Common Notarization Issues](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/resolving_common_notarization_issues)
- [Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [Developer ID Program](https://developer.apple.com/programs/mac/)

## Next Steps

1. ✅ Get Developer ID certificate
2. ✅ Import into Keychain
3. ✅ Set Team ID in `.env`
4. ✅ Run: `just notarize`
5. ✅ Verify in notarization log
6. ✅ Distribute with confidence!

---

**Questions?** Check CODE_SIGNING_GUIDE.md or Apple's official documentation.

