# macOS App Release Skill

A comprehensive Claude Skill for automating the complete macOS application release workflow, including building, code signing with Developer ID certificates, Apple notarization, packaging, and GitHub release creation.

## Description

This skill provides expert guidance through the entire macOS app distribution process for applications distributed outside the Mac App Store. It handles:

- **Building** - Xcode project compilation
- **Code Signing** - Developer ID certificate signing with proper inside-out order
- **Notarization** - Apple notarization submission and verification
- **Packaging** - DMG and ZIP archive creation
- **Git Operations** - Commits and tags with proper attribution
- **GitHub Releases** - Automated release creation with assets

## When to Use

Claude will automatically activate this skill when you ask for:

- "Release the macOS app"
- "Notarize this application"
- "Create a signed DMG for distribution"
- "Publish to GitHub releases"
- "Sign with Developer ID"
- "Prepare for macOS distribution"

## Prerequisites

### 1. Apple Developer Account
- Active Apple Developer Program membership ($99/year)
- Developer ID Application certificate installed
- Verify: `security find-identity -v -p codesigning | grep "Developer ID Application"`

### 2. Notarization Credentials
Set up once using:
```bash
xcrun notarytool store-credentials notary-profile \
  --apple-id "your-email@example.com" \
  --team-id YOUR_TEAM_ID
```

You'll need:
- **Apple ID**: Your developer account email
- **Team ID**: From developer.apple.com → Account → Membership
- **App-Specific Password**: From appleid.apple.com → Security → App-Specific Passwords

### 3. Tools
- Xcode or xcodebuild CLI
- Standard macOS signing tools (codesign, security, xcrun)
- Optional: GitHub CLI (`gh`) for automated releases

## Skill Contents

### SKILL.md
The main instruction file that Claude reads. Contains:
- Complete workflow phases (Build → Sign → Notarize → Package → Release)
- Troubleshooting guides
- Best practices and constraints
- Success criteria

### scripts/release.sh
Automated bash script for the complete release process.

**Usage:**
```bash
./scripts/release.sh \
  --version 1.7.3 \
  --app-name QuickRecorder \
  --cert "Developer ID Application: Your Name (TEAM_ID)" \
  --entitlements QuickRecorder/QuickRecorder.entitlements
```

**Options:**
- `--version`: Release version number (required)
- `--app-name`: Application name without .app extension (required)
- `--cert`: Code signing identity (optional, skips signing if not provided)
- `--entitlements`: Path to entitlements file (optional)
- `--skip-build`: Skip build phase (use existing .app)
- `--skip-notarize`: Skip notarization phase
- `--skip-release`: Skip GitHub release creation
- `--help`: Show usage information

### templates/RELEASE_NOTES.md
Template for GitHub release notes with placeholders for:
- App name and version
- New features, bug fixes, improvements
- Installation instructions
- Security information
- Checksums and verification

## Workflow Phases

### Phase 1: Build
- Clean previous builds
- Compile with Release configuration
- Copy .app bundle to project root

### Phase 2: Code Signing
- Verify Developer ID certificate exists
- Remove existing signatures
- Sign from inside-out:
  1. Dynamic libraries and executables
  2. XPC services
  3. Nested applications (e.g., Sparkle Updater.app)
  4. Frameworks
  5. Main app bundle (with entitlements)
- Verify signature

### Phase 3: Notarization
- Create zip archive
- Submit to Apple for notarization
- Wait for acceptance (typically 2-5 minutes)
- Staple notarization ticket to app
- Verify Gatekeeper acceptance with `spctl`

### Phase 4: Distribution Packages
- Create DMG disk image
- Create ZIP archive
- Generate SHA256 checksums

### Phase 5: Git Operations
- Commit changes with co-author attribution
- Create annotated git tag
- Push to remote repository

### Phase 6: GitHub Release
- Create release on GitHub
- Upload DMG, ZIP, and checksums
- Add release notes

## Key Features

### ✅ Inside-Out Signing
Properly signs nested components before the main bundle, following Apple's requirements.

### ✅ Hardened Runtime
Enables Hardened Runtime with `--options runtime` flag (required for notarization).

### ✅ Secure Timestamps
Adds secure timestamps to all signatures (required for notarization).

### ✅ Gatekeeper Verification
Verifies the app passes Gatekeeper checks using `spctl`.

### ✅ Co-Author Attribution
All commits and tags include: `Co-Authored-By: Warp <agent@warp.dev>`

### ✅ Error Handling
Stops on errors and provides troubleshooting guidance.

## Example Usage

### Full Automated Release
```bash
# Let Claude handle everything
"Release QuickRecorder version 1.7.3"
```

### Using the Script Directly
```bash
# Get your signing identity
CERT=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | sed 's/^.*"\(.*\)"$/\1/')

# Run release script
./.claude/skills/macos-app-release/scripts/release.sh \
  --version 1.7.3 \
  --app-name QuickRecorder \
  --cert "$CERT" \
  --entitlements QuickRecorder/QuickRecorder.entitlements
```

### Step-by-Step with Claude
```
User: "I want to release the app step by step"
Claude: [Executes each phase with confirmation]
```

## Troubleshooting

### Certificate Not Found
```bash
# Check available certificates
security find-identity -v -p codesigning

# If missing, download from:
# https://developer.apple.com/account/resources/certificates/list
```

### Notarization Failed
```bash
# Get detailed logs
xcrun notarytool log SUBMISSION_ID --keychain-profile notary-profile

# Common issues:
# - Missing --options runtime flag
# - Missing --timestamp flag
# - Unsigned nested components
```

### Gatekeeper Rejected
```bash
# Detailed verification
spctl -a -vv -t execute AppName.app
xcrun stapler validate AppName.app
```

## Best Practices

1. **Always verify signatures** before notarization
2. **Always staple tickets** after successful notarization
3. **Test Gatekeeper** acceptance with `spctl`
4. **Generate checksums** for all distribution files
5. **Use annotated tags** for releases
6. **Include co-author attribution** in commits

## File Structure

```
.claude/skills/macos-app-release/
├── SKILL.md                    # Main skill instructions (required)
├── README.md                   # This file
├── scripts/
│   └── release.sh             # Automated release script
└── templates/
    └── RELEASE_NOTES.md       # Release notes template
```

## Security Notes

- Never commit certificates or passwords to git
- Use Keychain to store notarization credentials securely
- Verify code signature before distribution
- Always notarize apps to avoid Gatekeeper warnings
- Include checksums for integrity verification

## References

- [Apple: Notarizing macOS Software](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Apple: Code Signing Guide](https://developer.apple.com/library/archive/documentation/Security/Conceptual/CodeSigningGuide/)
- [Apple: Customizing Notarization Workflow](https://developer.apple.com/documentation/security/customizing_the_notarization_workflow)

## Support

For issues or questions about this skill:
1. Check the troubleshooting section in SKILL.md
2. Verify prerequisites are met
3. Review Apple's official documentation
4. Check macOS Console.app for signing/notarization errors

## License

This skill is part of the QuickRecorder project. See project LICENSE for details.
