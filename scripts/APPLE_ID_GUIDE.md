# Apple ID & Password Authentication Guide

## The Confusion: Apple ID Password vs App-Specific Password

### What You Need

**For Notarization: App-Specific Password** ✅
- Format: `xxxx-xxxx-xxxx-xxxx` (16 characters)
- NOT your Apple ID password
- Generated at [appleid.apple.com](https://appleid.apple.com/account/manage)
- Can be different for each app/service

**NOT: Your Apple ID Password** ❌
- Your regular Apple ID password
- Used to sign into Apple.com
- DO NOT USE for notarization
- Will cause: "Invalid credentials" errors

## Getting App-Specific Password

### Step 1: Go to Apple ID Settings
1. Open [appleid.apple.com](https://appleid.apple.com/account/manage)
2. Sign in with your Apple ID
3. Go to **Security** → **App-specific passwords**

### Step 2: Create New Password
1. Click **Generate password**
2. Select: **QuickRecorder** (or create app label)
3. Click **Generate**
4. Copy the 16-character password: `xxxx-xxxx-xxxx-xxxx`

### Step 3: Store Securely
**Option A: Keychain (Recommended)**
```bash
./buildRelease.sh --setup-keychain
# When prompted:
# - Enter your Apple ID email
# - Enter the app-specific password (NOT your Apple ID password)
```

**Option B: Environment Variable**
```bash
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
just notarize
```

**Option C: Interactive Prompt**
```bash
just notarize
# When prompted, enter: xxxx-xxxx-xxxx-xxxx
```

## Password Storage Options

### 1. Keychain (Most Secure) ⭐

**Pros:**
- Uses Touch ID/Apple Watch
- Never stored in files
- System-level encryption
- Works offline

**Setup:**
```bash
./buildRelease.sh --setup-keychain
```

**Usage:**
```bash
just notarize
# Prompted for Touch ID/Apple Watch
```

### 2. Environment Variable (For CI/CD)

**Pros:**
- Good for automated builds
- Can be managed by CI/CD platform secrets

**Setup:**
```bash
export APPLE_ID="your@email.com"
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

**Usage:**
```bash
just notarize
```

### 3. Interactive Prompt (One-time)

**Pros:**
- No storage needed
- Clear what you're entering

**Usage:**
```bash
export APPLE_ID="your@email.com"
just notarize
# Prompted: Enter app-specific password: ***
```

## Common Errors

### ❌ Error: "Invalid credentials. Username or password is incorrect"

**Cause:** Using wrong password type

**Solutions:**
```bash
# ✅ CORRECT: App-specific password from appleid.apple.com
xxxx-xxxx-xxxx-xxxx

# ❌ WRONG: Your Apple ID password
YourAppleIDPassword123

# ❌ WRONG: Random password
abc123xyz789
```

### ❌ Error: "403 Forbidden" when checking status

**Cause:** Command didn't get the password

**Fix:**
```bash
# ❌ This fails (no password)
xcrun notarytool log SUBMISSION_ID \
    --apple-id your@email.com \
    --team-id TEAMID

# ✅ This works (password provided)
xcrun notarytool log SUBMISSION_ID \
    --apple-id your@email.com \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --team-id TEAMID

# ✅ Or use environment variable
export APPLE_ID_PASSWORD="xxxx-xxxx-xxxx-xxxx"
xcrun notarytool log SUBMISSION_ID \
    --apple-id your@email.com \
    --team-id TEAMID
```

### ❌ Error: "The operation couldn't be completed"

**Cause:** Multiple issues possible

**Debug:**
```bash
# Check your credentials work
xcrun notarytool history \
    --apple-id your@email.com \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --team-id TEAMID

# If that works, try notarizing again
just notarize
```

## Notarization Status Guide

### Status: "Accepted" ✅
Your app is approved! Automatically staples and ready to distribute.

### Status: "Invalid" ❌
Apple rejected your submission. View detailed errors:

```bash
xcrun notarytool log SUBMISSION_ID \
    --apple-id your@email.com \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --team-id TEAMID
```

Common rejection reasons:
- Binary not signed
- Missing hardened runtime
- Unsigned frameworks
- No timestamp on signature

### Status: "In Progress" ⏳
Apple is still processing. Usually takes 1-2 minutes.

Check again:
```bash
xcrun notarytool log SUBMISSION_ID \
    --apple-id your@email.com \
    --password "xxxx-xxxx-xxxx-xxxx" \
    --team-id TEAMID
```

## Security Best Practices

1. **Never hardcode passwords** in scripts
2. **Use Keychain** for local development
3. **Use CI/CD secrets** for automation
4. **Regenerate app-specific passwords** periodically
5. **Revoke old passwords** if compromised
6. **Don't share passwords** via email/chat
7. **Use `.env` only for development** (git-ignored)

## Quick Reference

| Task | Command |
|------|---------|
| Setup Keychain | `./buildRelease.sh --setup-keychain` |
| Notarize (Keychain) | `just notarize` |
| Notarize (env var) | `export APPLE_ID_PASSWORD=xxxx-xxxx-xxxx-xxxx && just notarize` |
| Check status | `xcrun notarytool log ID --apple-id EMAIL --password PWD --team-id TEAM` |
| View history | `xcrun notarytool history --apple-id EMAIL --password PWD --team-id TEAM` |

## Getting Help

**Apple ID Issues:**
- [appleid.apple.com](https://appleid.apple.com)
- [Apple ID Support](https://support.apple.com/account)

**App-Specific Passwords:**
- [Create App-Specific Password](https://support.apple.com/en-us/HT204915)

**Notarization Issues:**
- [Apple Notarization Docs](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Troubleshooting Guide](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution/resolving_common_notarization_issues)

## Summary

- **Use**: App-Specific Password (not Apple ID password)
- **Get it from**: [appleid.apple.com/account/manage](https://appleid.apple.com/account/manage)
- **Store securely**: Keychain (recommended) or environment variables
- **Never commit**: Passwords to git or version control
- **Format**: `xxxx-xxxx-xxxx-xxxx` (16 characters)

That's it! You're ready to notarize! 🚀

