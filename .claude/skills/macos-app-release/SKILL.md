---
name: macos-app-release
description: Expert workflow for building, code signing, notarizing macOS applications with Developer ID certificates, and publishing releases to GitHub. Use this when the user asks to release a macOS app, create a DMG, notarize an app, or prepare for distribution outside the Mac App Store.
tags:
  - macos
  - xcode
  - codesigning
  - notarization
  - github-release
  - distribution
---

# macOS App Release Skill

## Overview
You are an expert macOS developer specialized in the complete release workflow for macOS applications distributed outside the Mac App Store. This skill guides you through building, code signing with Developer ID certificates, Apple notarization, packaging, and publishing to GitHub releases.

## When to Use This Skill
Activate this skill when the user requests:
- "Release the macOS app"
- "Notarize this application"
- "Create a signed DMG for distribution"
- "Publish to GitHub releases"
- "Sign with Developer ID"
- "Prepare for macOS distribution"

## Prerequisites Check
Before starting, verify these requirements:

1. **Apple Developer Account**
   - Active Apple Developer Program membership ($99/year)
   - Developer ID Application certificate installed
   - Check: `security find-identity -v -p codesigning | grep "Developer ID Application"`

2. **Notarization Credentials**
   - Apple ID email
   - Team ID (from developer.apple.com)
   - App-specific password (from appleid.apple.com)
   - Stored in Keychain: `xcrun notarytool store-credentials notary-profile --validate`

3. **Tools Available**
   - Xcode or xcodebuild
   - codesign, security, xcrun, notarytool, stapler
   - Optional: gh (GitHub CLI), hdiutil

## Core Workflow

### Phase 1: Build the Application

#### Option A: Using xcodebuild (Preferred for automation)
```bash
# Clean previous builds
xcodebuild clean -project PROJECT_NAME.xcodeproj -scheme SCHEME_NAME

# Build for release
xcodebuild -project PROJECT_NAME.xcodeproj \
  -scheme SCHEME_NAME \
  -configuration Release \
  -derivedDataPath ./build \
  build

# Copy .app bundle to project root
cp -R ./build/Build/Products/Release/APP_NAME.app .
```

#### Option B: Using Xcode GUI
Instruct user to:
1. Open Xcode → Product → Archive
2. Organizer → Distribute App → Copy App
3. Save to project directory

**Verification:**
```bash
ls -lh APP_NAME.app
open APP_NAME.app  # Test launch
```

### Phase 2: Code Signing with Developer ID

**Critical Principle:** Sign from inside-out (deepest components first, main bundle last).

#### Step 1: Get Signing Identity
```bash
# List available identities
security find-identity -v -p codesigning

# Should show: "Developer ID Application: Name (TEAM_ID)"
```

#### Step 2: Remove Existing Signatures
```bash
# Remove all existing signatures (deepest first)
find "APP_NAME.app" -type d \( -name "*.app" -or -name "*.framework" -or -name "*.xpc" \) | \
  sort -r | while read bundle; do
    codesign --remove-signature "$bundle" 2>/dev/null || true
done
```

#### Step 3: Sign Nested Components
Sign in this order:
1. **Dynamic Libraries & Executables**
   ```bash
   find "APP_NAME.app" -type f \( -name "*.dylib" -o -perm +111 \) | while read binary; do
       if file "$binary" | grep -q "Mach-O"; then
           codesign --force --sign "CERT_IDENTITY" --options runtime --timestamp "$binary"
       fi
   done
   ```

2. **XPC Services**
   ```bash
   find "APP_NAME.app" -name "*.xpc" | while read xpc; do
       codesign --force --sign "CERT_IDENTITY" --options runtime --timestamp "$xpc"
   done
   ```

3. **Nested Applications** (like Sparkle's Updater.app)
   ```bash
   find "APP_NAME.app" -name "*.app" -not -path "APP_NAME.app" | sort -r | while read nested; do
       codesign --force --sign "CERT_IDENTITY" --options runtime --timestamp "$nested"
   done
   ```

4. **Frameworks**
   ```bash
   find "APP_NAME.app" -name "*.framework" | while read framework; do
       codesign --force --sign "CERT_IDENTITY" --options runtime --timestamp "$framework"
   done
   ```

5. **Main App Bundle** (LAST)
   ```bash
   codesign --force --sign "CERT_IDENTITY" \
     --options runtime \
     --timestamp \
     --entitlements "PATH/TO/ENTITLEMENTS.entitlements" \
     "APP_NAME.app"
   ```

#### Step 4: Verify Signature
```bash
codesign --verify --deep --strict --verbose=2 "APP_NAME.app"
# Should output: "satisfies its Designated Requirement"
```

**Critical Flags:**
- `--options runtime`: Enable Hardened Runtime (REQUIRED for notarization)
- `--timestamp`: Add secure timestamp (REQUIRED for notarization)
- `--force`: Replace existing signatures
- `--entitlements`: Apply app entitlements
- `--deep`: Only use on final main bundle

### Phase 3: Notarization

Notarization submits the app to Apple for automated security scanning, eliminating Gatekeeper warnings.

#### Step 1: Verify/Setup Credentials (One-time)
If not already set up:
```bash
# Interactive mode (most secure)
xcrun notarytool store-credentials notary-profile \
  --apple-id "your-email@example.com" \
  --team-id YOUR_TEAM_ID
# You'll be prompted for app-specific password

# Validate stored credentials
xcrun notarytool store-credentials notary-profile --validate
```

**Credential Sources:**
- **Apple ID**: Your developer account email
- **Team ID**: developer.apple.com → Account → Membership
- **App-Specific Password**: appleid.apple.com → Security → App-Specific Passwords

#### Step 2: Create Submission Archive
```bash
# Use ditto to preserve metadata
ditto -c -k --keepParent "APP_NAME.app" "APP_NAME.zip"
```

#### Step 3: Submit for Notarization
```bash
xcrun notarytool submit "APP_NAME.zip" \
  --keychain-profile notary-profile \
  --wait

# --wait flag waits for Apple's response (typically 2-5 minutes)
```

**Success Response:**
```
Submission ID: xxxx-xxxx-xxxx-xxxx
  status: Accepted
```

**Failure Response:**
```
Submission ID: xxxx-xxxx-xxxx-xxxx
  status: Invalid
```

#### Step 4: Get Detailed Logs (if rejected)
```bash
xcrun notarytool log SUBMISSION_ID --keychain-profile notary-profile
```

Common rejection reasons:
- Missing `--options runtime` on components
- Missing `--timestamp` flag
- Unsigned nested components
- Invalid entitlements

#### Step 5: Staple Notarization Ticket
After successful notarization:
```bash
xcrun stapler staple "APP_NAME.app"
```

This embeds the approval into the app bundle for offline verification.

#### Step 6: Verify Gatekeeper Acceptance
```bash
spctl -a -vv "APP_NAME.app"
```

**Expected Output:**
```
APP_NAME.app: accepted
source=Notarized Developer ID
```

### Phase 4: Create Distribution Package

#### Option 1: DMG (Recommended for downloads)
```bash
# Create disk image
hdiutil create -volname "APP_NAME" \
  -srcfolder "APP_NAME.app" \
  -ov -format UDZO \
  "APP_NAME_vVERSION.dmg"

# Optional: Notarize the DMG itself
xcrun notarytool submit "APP_NAME_vVERSION.dmg" \
  --keychain-profile notary-profile \
  --wait

xcrun stapler staple "APP_NAME_vVERSION.dmg"
```

#### Option 2: Zip Archive
```bash
ditto -c -k --keepParent "APP_NAME.app" "APP_NAME_vVERSION.zip"
```

#### Generate Checksums
```bash
shasum -a 256 "APP_NAME_vVERSION.dmg" > "APP_NAME_vVERSION_SHA256.txt"
shasum -a 256 "APP_NAME_vVERSION.zip" >> "APP_NAME_vVERSION_SHA256.txt"
```

### Phase 5: Git Operations

#### Commit Changes
```bash
git add .
git commit -m "Release vVERSION: Brief description

- Change 1
- Change 2
- Change 3

Co-Authored-By: Warp <agent@warp.dev>"
```

#### Create Annotated Tag
```bash
git tag -a vVERSION -m "Release vVERSION

- Change 1
- Change 2

Co-Authored-By: Warp <agent@warp.dev>"

# Verify tag
git tag -n9 vVERSION
```

#### Push to GitHub
```bash
git push origin main
git push origin vVERSION
```

### Phase 6: Create GitHub Release

#### Option A: Using GitHub CLI (Preferred)
```bash
# Ensure gh is installed and authenticated
gh auth status || gh auth login

# Create release with assets
gh release create vVERSION \
  "APP_NAME_vVERSION.dmg" \
  "APP_NAME_vVERSION.zip" \
  "APP_NAME_vVERSION_SHA256.txt" \
  --title "APP_NAME vVERSION" \
  --notes-file RELEASE_NOTES.md

# Or generate notes automatically
gh release create vVERSION --generate-notes
```

#### Option B: Manual (GitHub Web Interface)
Instruct user to:
1. Go to: `https://github.com/USERNAME/REPO/releases/new`
2. Choose tag: `vVERSION`
3. Fill release title: `APP_NAME vVERSION`
4. Add release notes (use template below)
5. Attach files: DMG, ZIP, SHA256.txt
6. Check "Set as latest release"
7. Publish

## Release Notes Template

Create a `RELEASE_NOTES.md` file:

```markdown
## 🎉 APP_NAME vVERSION

### ✨ New Features
- Feature description

### 🐛 Bug Fixes
- Bug fix description

### 🔧 Improvements
- Improvement description

### 📦 Installation

**macOS 12.3 and later:**
1. Download `APP_NAME_vVERSION.dmg`
2. Open the DMG
3. Drag **APP_NAME.app** to **Applications** folder
4. Right-click app → **Open** (first time only)

### ✅ Security & Code Signing
- ✅ Signed with **Developer ID Application** certificate
- ✅ **Notarized** by Apple (passes Gatekeeper)
- ✅ **Hardened Runtime** enabled

### 📝 Checksums (SHA256)
See `APP_NAME_vVERSION_SHA256.txt` for file verification.

---

**Full Changelog**: https://github.com/USERNAME/REPO/compare/vPREV_VERSION...vVERSION
```

## Execution Strategy

When the user requests a release, follow this order:

1. **Assess Current State**
   - Check if .app exists
   - Verify certificate availability
   - Confirm notarization credentials

2. **Interactive vs. Automated**
   - If user wants full automation: Execute all phases
   - If user wants step-by-step: Ask for confirmation between phases

3. **Error Handling**
   - If any step fails, stop and report the issue
   - Provide troubleshooting steps from the Troubleshooting section below

4. **Verification at Each Step**
   - After signing: verify signature
   - After notarization: check spctl
   - After release: test download link

## Troubleshooting Guide

### Issue: "Developer ID Application certificate not found"
**Check:**
```bash
security find-identity -v -p codesigning
```
**Solution:** Download certificate from https://developer.apple.com/account/resources/certificates/list

### Issue: "Notarization failed - Invalid signature"
**Root Causes:**
- Missing `--options runtime` flag
- Missing `--timestamp` flag
- Unsigned nested components
- Incorrect signing order

**Solution:** Re-sign following inside-out order strictly.

### Issue: "stapler: The staple and validate action failed"
**Check:**
```bash
xcrun notarytool info SUBMISSION_ID --keychain-profile notary-profile
```
**Note:** You can only staple `.app` bundles and `.dmg` files, not `.zip` archives.

### Issue: "spctl: rejected"
**Detailed Check:**
```bash
spctl -a -vv -t execute "APP_NAME.app"
xcrun stapler validate "APP_NAME.app"
```
**Solution:** Ensure notarization was successful and ticket was stapled.

## Output Style

When executing this skill:
1. **Be Explicit:** Show commands before running them
2. **Explain Critical Steps:** Briefly explain why each major step is necessary
3. **Progressive Updates:** Provide status updates between phases
4. **Verification:** Always verify each phase completed successfully
5. **Final Summary:** Provide release URL and next steps

## Constraints

- **NEVER** commit changes unless explicitly requested
- **ALWAYS** include co-author attribution: `Co-Authored-By: Warp <agent@warp.dev>`
- **ALWAYS** verify signatures before notarization
- **NEVER** skip the stapling step
- **ALWAYS** test Gatekeeper acceptance with `spctl`

## Supporting Scripts

If automation scripts exist in the project:
- Check for `sign_with_developer_id.sh`, `sign_for_distribution.sh`
- Use existing scripts if they follow best practices
- Verify script behavior before execution

## Context Awareness

Adapt to the specific project:
- Extract app name from `.xcodeproj` or existing `.app`
- Detect existing version from git tags or files
- Use project-specific entitlements file
- Check for existing notarization credentials
- Respect existing release workflow if present

## Success Criteria

A successful release includes:
- ✅ App builds without errors
- ✅ All components properly signed (verified)
- ✅ Notarization accepted by Apple
- ✅ Ticket stapled to app
- ✅ Gatekeeper accepts app (`spctl` shows "accepted")
- ✅ DMG/ZIP created
- ✅ Git tag created and pushed
- ✅ GitHub release published with assets
- ✅ Download link accessible

## References

- **Apple Docs:** https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- **Notarization Guide:** https://developer.apple.com/documentation/security/customizing_the_notarization_workflow
- **Code Signing:** https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/
