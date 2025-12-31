# QuickRecorder Notarization Setup Guide

This guide explains how to set up and use Apple's notarization service with QuickRecorder.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Credential Storage Options](#credential-storage-options)
3. [Setup Keychain (Recommended)](#setup-keychain-recommended)
4. [Setup Environment Variables (.env)](#setup-environment-variables-env)
5. [Running Notarization](#running-notarization)
6. [Troubleshooting](#troubleshooting)

---

## Prerequisites

- macOS 10.15+ (Catalina or later)
- Xcode 13+ (with `notarytool`)
- Apple Developer Account
- App-specific password

### Getting Your App-Specific Password

1. Go to [appleid.apple.com](https://appleid.apple.com/account/manage)
2. Sign in with your Apple ID
3. Navigate to **Security** → **App-specific passwords**
4. Create a new app-specific password for "QuickRecorder"
5. Copy the 16-character password (format: `xxxx-xxxx-xxxx-xxxx`)

---

## Credential Storage Options

### Option 1: Keychain (Recommended) ⭐

Most secure. Uses Touch ID or Apple Watch for approval.

### Option 2: .env File

Simple but less secure. File is git-ignored.

### Option 3: Environment Variables

Good for CI/CD pipelines.

---

## Setup Keychain (Recommended)

### Step 1: Run Setup Script

```bash
./buildRelease.sh --setup-keychain
```

This will prompt you for:
- Your Apple ID email
- Your app-specific password

Both are stored securely in Keychain with Touch ID/Apple Watch protection.

### Step 2: Verify Setup

Test that credentials are stored:

```bash
security find-internet-password -s "hisgarden" -a "appleid" -g
security find-internet-password -s "hisgarden" -a "notarize" -w
```

The second command will prompt for Touch ID/Apple Watch.

### Step 3: Run Notarization

```bash
just notarize
```

You'll be prompted with Touch ID or Apple Watch to approve Keychain access.

---

## Setup Environment Variables (.env)

### Step 1: Copy Sample File

```bash
cp .env.sample .env
```

### Step 2: Edit .env

```bash
nano .env
```

Fill in (Apple ID only, password will be prompted):
```bash
APPLE_ID=your-email@example.com
# APPLE_TEAM_ID=ABCD1234EF  # Only if you have multiple teams
```

⚠️ **DO NOT store `APPLE_ID_PASSWORD` in .env file!**

The password will be retrieved securely from:
1. Keychain (if set up)
2. Interactive prompt (masked input)
3. Environment variable (if explicitly set before running)

### Step 3: Verify Git Ignores .env

Ensure `.env` is in your `.gitignore`:

```bash
echo ".env" >> .gitignore
```

### Step 4: Run Notarization

```bash
just notarize
```

---

## Running Notarization

### Quick Start

```bash
just notarize
```

### What Happens

1. **Credential Retrieval** - Tries Keychain → .env → environment variables
2. **Archive Creation** - Builds and archives the app
3. **Export** - Extracts the `.app` from the archive
4. **Zip Creation** - Compresses the `.app` for notarization
5. **Submission** - Sends to Apple's notarization service
6. **Waiting** - Waits for Apple to process (typically < 1 minute)
7. **Stapling** - Attaches the notarization ticket to the app

### Output

```
✅ Archive created: archive/QuickRecorder-20251229-1346.xcarchive
✅ Exported to: archive/QuickRecorder-20251229-1346.app
✅ Created zip: archive/QuickRecorder-20251229-1346.zip (3.8M)
✅ Retrieved credentials from Keychain
✅ Notarization completed successfully!
Submission ID: abc-123-def-456
✅ Ticket stapled successfully!
```

---

## Using in CI/CD

### Method 1: Environment Variables (Most Secure for CI/CD)

Store credentials in your CI/CD platform's secret management:

```bash
export APPLE_ID="your-email@example.com"
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
# Optionally:
# export APPLE_TEAM_ID="ABCD1234EF"

just notarize
```

### Method 2: Interactive Prompt

If you prefer to be prompted during the build:

```bash
export APPLE_ID="your-email@example.com"
just notarize
# You'll be prompted to enter the password (masked input)
```

⚠️ **Never commit `APPLE_ID_PASSWORD` to version control!**

---

## Troubleshooting

### Error: "Missing credentials"

**Solution:** Ensure credentials are set up via one of these methods:
1. Run `./buildRelease.sh --setup-keychain` (recommended)
2. Create/edit `.env` file with credentials
3. Export environment variables

### Error: "multiple provider"

Your Apple ID has multiple developer teams. Add to `.env`:

```bash
APPLE_TEAM_ID=ABCD1234EF
```

To find your team ID:

```bash
xcrun notarytool history --apple-id your-email@example.com --password xxxx-xxxx-xxxx-xxxx
```

### Error: "Invalid password"

Check that:
1. You're using an **app-specific password**, not your Apple ID password
2. The password is copied exactly from [appleid.apple.com](https://appleid.apple.com/account/manage)
3. For Keychain: Run `./buildRelease.sh --setup-keychain` again

### Error: "Archive Missing Bundle Identifier"

The `Info.plist` is missing `CFBundleIdentifier`. This should be fixed, but if you see it:

1. Ensure `Info.plist` has `CFBundleIdentifier`
2. Regenerate the project: `xcodegen generate`

### Keychain Touch ID Not Prompting

If `just notarize` doesn't prompt for Touch ID:

1. Verify credentials are in Keychain:
   ```bash
   security find-internet-password -s "hisgarden" -a "appleid"
   security find-internet-password -s "hisgarden" -a "notarize"
   ```

2. Re-setup Keychain:
   ```bash
   ./buildRelease.sh --setup-keychain
   ```

---

## Security Best Practices

1. **Never commit `.env`** - It's in `.gitignore`
2. **Use Keychain** - Requires biometric authentication
3. **Rotate passwords** - Create new app-specific passwords periodically
4. **Review Keychain entries** - Use Keychain Access app to audit stored credentials
5. **Limit CI/CD exposure** - Store credentials securely in CI/CD platform

---

## Related Commands

```bash
# Build and notarize (all-in-one)
just notarize

# Setup Keychain (one-time)
./buildRelease.sh --setup-keychain

# View build logs
just logs

# View recent errors
just errors

# Export notarized app to Desktop
just export
```

---

## References

- [Apple Notarization Overview](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [notarytool Documentation](https://developer.apple.com/wwdc22/10109)
- [App-Specific Passwords](https://support.apple.com/en-us/HT204915)

---

## Questions or Issues?

Check the main README.md or create an issue on GitHub.

