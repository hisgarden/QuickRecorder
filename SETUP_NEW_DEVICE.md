# QuickRecorder - Setup on New Device

This guide explains how to set up QuickRecorder on a new device for development and building.

## Prerequisites

- macOS 12.3 or later
- Xcode 15+ with Command Line Tools
- Homebrew (optional, for installing dependencies)

## Quick Setup (Basic Build Only)

If you only need to build the app without notarization:

```sh
# 1. Clone the repository
git clone https://github.com/hisgarden/QuickRecorder.git
cd QuickRecorder

# 2. Install XcodeGen
brew install xcodegen

# 3. Run setup script
bash scripts/setup.sh

# 4. Build the app
xcodebuild build \
  -project QuickRecorder.xcodeproj \
  -scheme QuickRecorder \
  -destination 'platform=macOS' \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

Or using Just (recommended):

```sh
# Install just
brew install just

# Run setup
just setup

# Build
just build
```

## Full Setup (Including Notarization)

For distribution builds with notarization:

### Step 1: Basic Setup

Follow the Quick Setup steps above.

### Step 2: Configure Credentials

The `credentials.sh` file is **not tracked in git** for security. You need to create it:

```sh
# Copy the example template
cp scripts/credentials.sh.example scripts/credentials.sh

# Edit the file and update "your-service-name" to your own identifier
# Example: "quickrecorder-dev" or your GitHub username
```

### Step 3: Store Credentials in Keychain

Store your Apple ID and app-specific password securely:

```sh
# Store Apple ID
security add-internet-password \
  -s "your-service-name" \
  -a "appleid" \
  -w "your@apple.com"

# Store App-Specific Password
# Get this from: https://appleid.apple.com/account/manage
security add-internet-password \
  -s "your-service-name" \
  -a "notarize" \
  -w "xxxx-xxxx-xxxx-xxxx"
```

### Step 4: Update Code Signing Settings

Edit `project.yml` and update the `DEVELOPMENT_TEAM`:

```yaml
settings:
  base:
    DEVELOPMENT_TEAM: "YOUR_TEAM_ID"  # Replace with your Team ID
    CODE_SIGN_IDENTITY: "Developer ID Application"
```

Find your Team ID in your Developer ID certificate name:
- Open Keychain Access
- Look for "Developer ID Application: Your Name (TEAM_ID)"

### Step 5: Regenerate Xcode Project

```sh
xcodegen generate
```

### Step 6: Build and Notarize

```sh
# Using Just
just notarize

# Or manually
bash scripts/notarize.sh
```

## What's Tracked in Git

All necessary scripts are tracked in git:

### Build Scripts (13 files)
- `build.sh` - Debug build with logging
- `buildDebug.sh` - Comprehensive debug build
- `buildRelease.sh` - Release build
- `setup.sh` - Project setup
- `setup_tests.sh` - Test setup
- `release.sh` - Release workflow
- `release-export.sh` - Export script
- `notarize.sh` - Notarization script
- `staple.sh` - Stapling script
- `check-notarization.sh` - Check status
- `generate-appcast.sh` - Appcast generation
- `create-release.sh` - GitHub release (API)
- `create-gh-release.sh` - GitHub release (CLI)

### Documentation (12 files)
- `README.md` - Scripts overview
- `SETUP_XCODEGEN.md` - XcodeGen guide
- `NOTARIZATION_SETUP.md` - Notarization guide
- `STAPLING_GUIDE.md` - Stapling guide
- `APPCAST_SETUP.md` - Sparkle updates
- `CODE_SIGNING_GUIDE.md` - Code signing
- `DEVELOPER_ID_CERTIFICATE.md` - Certificates
- `APPLE_ID_GUIDE.md` - Apple ID setup
- `NOTARIZATION_VERIFICATION.md` - Verification
- `FIXES_APPLIED.md` - Applied fixes
- `TEST_EVALUATION_REPORT.md` - Test report
- `TEST_SUITE_SUMMARY.md` - Test summary

### Template Files
- `credentials.sh.example` - Credential handler template

## What's NOT Tracked (You Must Create)

These files are in `.gitignore` and must be created locally:

1. **`scripts/credentials.sh`** - Your personal credential handler
   - Use `credentials.sh.example` as template
   - Update service name to your identifier
   - Store credentials in Keychain

2. **`scripts/build-settings.txt`** - Build artifacts (auto-generated)

3. **`.env`** (optional) - Environment variables
   - Can store `APPLE_ID` and `APPLE_TEAM_ID`
   - **NEVER** store `APP_SPECIFIC_PASSWORD` in files

## Available Commands

### Using Just (Recommended)

```sh
# Setup
just setup              # Install deps & generate project
just generate           # Generate Xcode project only

# Building
just build              # Debug build
just release            # Release build
just build-plus         # Build with full analysis

# Testing
just test               # Run all tests
just test-coverage      # Run with coverage
just watch              # Watch mode

# Distribution (requires credentials)
just notarize           # Build + notarize
just staple             # Staple notarization ticket
just appcast            # Generate appcast
just publish            # Complete release workflow

# Utilities
just clean              # Clean build artifacts
just logs               # View build logs
just errors             # Show last errors
just diagnose           # Full diagnostic
```

### Using Scripts Directly

```sh
# Setup
bash scripts/setup.sh

# Build
bash scripts/build.sh
bash scripts/buildDebug.sh
bash scripts/buildRelease.sh

# Test
bash setupTests.sh

# Distribution (requires credentials)
bash scripts/notarize.sh
bash scripts/staple.sh [path/to/app]
bash scripts/generate-appcast.sh [version] [path/to/zip]
bash scripts/release.sh [version] [path/to/app]
```

## Troubleshooting

### "xcodegen: command not found"

```sh
brew install xcodegen
```

### "xcrun: error: unable to find utility 'notarytool'"

Update Xcode to version 13 or later:
```sh
xcode-select --install
```

### "No signing identity found"

You need a Developer ID certificate for notarization:
1. Join Apple Developer Program
2. Create Developer ID Application certificate
3. Download and install in Keychain

See `scripts/DEVELOPER_ID_CERTIFICATE.md` for details.

### "credentials.sh: No such file or directory"

Create it from the template:
```sh
cp scripts/credentials.sh.example scripts/credentials.sh
# Edit and update service name
```

### Build fails with signing errors

For development builds without notarization:
```sh
xcodebuild build \
  -project QuickRecorder.xcodeproj \
  -scheme QuickRecorder \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO
```

## Security Best Practices

1. **Never commit credentials** - `credentials.sh` is in `.gitignore`
2. **Use Keychain** - Store passwords in macOS Keychain, not files
3. **App-Specific Passwords** - Use app-specific passwords, not your Apple ID password
4. **Touch ID/Watch** - Enable biometric authentication for Keychain access
5. **Review .gitignore** - Ensure sensitive files are ignored

## Minimum Requirements Summary

### For Basic Build (No Notarization)
- ✅ Xcode 15+
- ✅ XcodeGen
- ✅ Scripts tracked in git (automatically available)
- ❌ No credentials needed
- ❌ No Developer ID certificate needed

### For Notarization & Distribution
- ✅ Everything from basic build
- ✅ Apple Developer Program membership
- ✅ Developer ID Application certificate
- ✅ App-specific password
- ✅ `credentials.sh` (create from template)
- ✅ Updated `DEVELOPMENT_TEAM` in `project.yml`

## Next Steps

After setup:
1. Review `README.md` for project overview
2. Check `scripts/README.md` for script details
3. See `INSTALL.md` for user installation instructions
4. Read `QuickRecorderTests/README.md` for testing guide

## Support

For issues:
1. Check `scripts/` documentation files
2. Review build logs in `logs/` directory
3. Run `just diagnose` for system check
4. Open an issue on GitHub

