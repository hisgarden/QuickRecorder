# Notarization Verification Process

When you run `just notarize`, the script now performs comprehensive verification **before** starting the long build process. This ensures you don't waste time building if something is wrong with your credentials.

## Verification Stages

### 1. ✅ Prerequisites Check
**What it checks:**
- `xcrun` command is available
- `notarytool` is installed (Xcode 13+)

**Why:** Ensures your Xcode setup is complete before proceeding.

**Error:** 
```
❌ xcrun not found. Please install Xcode.
❌ notarytool not found. Please update Xcode (requires Xcode 13+).
```

### 2. 🔐 Credentials Retrieval
**What it checks:**
- Tries to get credentials from Keychain (most secure)
- Falls back to `.env` file if Keychain empty
- Falls back to environment variables
- Falls back to interactive prompt with masked input

**Why:** Verifies credentials exist and are accessible before starting build.

**Error:**
```
❌ No credentials found

Please configure credentials using one of these methods:
  1. Keychain: ./buildRelease.sh --setup-keychain
  2. Interactive prompt: Just run 'just notarize' and enter password
  3. Environment: export APPLE_ID and APPLE_ID_PASSWORD
```

### 3. 📋 Credentials Validation
**What it checks:**
- Apple ID is not empty
- Password is not empty
- Team ID is retrieved (if configured)

**Why:** Quick validation before the expensive credential test.

### 4. 🔗 Credentials Test with Apple
**What it checks:**
- Calls `xcrun notarytool history` with your credentials
- Verifies they actually work with Apple's servers
- Tests team ID if provided

**Why:** Catches invalid credentials immediately, before archiving.

**Error:**
```
❌ Credential test failed. Check your Apple ID and password.
```

### 5. 📦 Build & Archive
**Only starts after all verification passes!**

This is the long task (several minutes) that only runs once credentials are confirmed.

### 6. 🔏 Notarization Submission
**After successful build**, submits to Apple and waits for approval.

## Flow Diagram

```
just notarize
    ↓
1. Check xcrun & notarytool
    ↓ ✅ OK?
2. Retrieve credentials (Keychain → .env → env → prompt)
    ↓ ✅ Found?
3. Validate credentials (not empty)
    ↓ ✅ Valid?
4. TEST with Apple's servers (notarytool history)
    ↓ ✅ Works?
═══════════════════════════════════════════════════════════
5. BUILD & ARCHIVE (expensive operation - only now!)
    ↓ ✅ Success?
6. NOTARIZE (wait for approval)
    ↓ ✅ Approved?
7. STAPLE ticket
    ↓
✅ Done!
```

## Common Errors and Solutions

### Error: "No credentials found"

**Cause:** None of the credential sources provided credentials.

**Solution:**
```bash
# Option 1: Setup Keychain (recommended)
./buildRelease.sh --setup-keychain
just notarize

# Option 2: Set environment variable
export APPLE_ID="your-email@example.com"
just notarize
# You'll be prompted for password

# Option 3: Create .env file
echo 'APPLE_ID=your-email@example.com' > .env
just notarize
# You'll be prompted for password
```

### Error: "Credential test failed"

**Cause:** The credentials work with your Mac but not with Apple's servers.

**Solutions:**
1. Verify Apple ID email is correct
2. Verify you're using an **app-specific password**, not your Apple ID password
3. Get a new app-specific password from https://appleid.apple.com/account/manage
4. Re-setup Keychain:
   ```bash
   ./buildRelease.sh --setup-keychain
   ```

### Error: "multiple provider" (during notarization)

**Cause:** You have multiple developer teams and need to specify which one.

**Solution:**
Find your team ID:
```bash
xcrun notarytool history --apple-id your-email@example.com --password <password>
```

Add to `.env`:
```bash
APPLE_TEAM_ID=ABCD1234EF
```

Re-run:
```bash
just notarize
```

### Error: "notarytool not found"

**Cause:** Your Xcode version is too old (before 13.0).

**Solution:**
```bash
# Update Xcode
softwareupdate -i -a

# Or install from App Store:
# https://apps.apple.com/us/app/xcode/id497799835
```

## Verification Timing

The verification process is **very fast** (< 5 seconds):
- Prerequisites check: < 1s
- Credential retrieval: < 1s
- Validation: < 1s
- Apple credential test: < 2s

**Total verification: ~5 seconds**

This saves you 10+ minutes if credentials are wrong!

## Security Benefits

1. **No wasted time** - Fail fast if credentials are wrong
2. **Credentials tested with Apple** - Ensures they actually work
3. **Clear error messages** - Know exactly what's wrong
4. **Masked password input** - Shows `***` when you type
5. **Multiple credential sources** - Choose what's secure for your use case

## Credential Priority

The script checks credentials in this order:

1. **Keychain** (most secure - uses Touch ID/Apple Watch)
2. **.env file** (for Apple ID, never password)
3. **Environment variables** (for CI/CD)
4. **Interactive prompt** (masked input, one-time)

This gives you maximum flexibility while encouraging security!

