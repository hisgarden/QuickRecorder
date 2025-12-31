# Sparkle Appcast Setup Guide

This guide explains how to set up automatic updates for QuickRecorder using Sparkle.

## Overview

Sparkle is a software update framework for macOS that allows users to check for and download updates automatically. This document covers the appcast setup and release workflow.

## Files

- `appcast.xml` - The Sparkle feed containing update information
- `generate-appcast.sh` - Script to generate and update the appcast
- `sign-update.sh` - Script to sign updates for security

## Quick Start

### 1. Build and Notarize Release

```bash
# Build and notarize the release
just notarize

# This creates:
# - archive/export-YYYYMMDD-HHMM/QuickRecorder.app
# - archive/QuickRecorder-YYYYMMDD-HHMM.zip
```

### 2. Create GitHub Release

1. Go to: https://github.com/hisgarden/QuickRecorder/releases/new
2. Create a new tag: `v1.2.1`
3. Release title: `Version 1.2.1`
4. Upload the `.zip` file from `archive/`
5. Publish the release

### 3. Generate Appcast

```bash
# Method 1: Using the script (recommended)
./generate-appcast.sh 1.2.1 archive/QuickRecorder-20251229-1527.zip

# Method 2: Auto-detect version and file
./generate-appcast.sh

# Method 3: With signing key
./generate-appcast.sh --signing-key keys/dsa_priv.pem 1.2.1 archive/QuickRecorder-1.2.1.zip
```

### 4. Commit Appcast to GitHub

```bash
git add appcast.xml
git commit -m "Add appcast for version 1.2.1"
git push origin main
```

### 5. Test Updates

Run QuickRecorder and check for updates:
- Menu: QuickRecorder → Check for Updates…
- Or wait for automatic check (if enabled)

## Appcast Structure

The appcast.xml file follows the Sparkle RSS format:

```xml
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle">
  <channel>
    <title>QuickRecorder Changelog</title>
    <item>
      <title>Version 1.2.1</title>
      <description><![CDATA[Release notes here]]></description>
      <enclosure url="https://github.com/.../QuickRecorder-1.2.1.zip"
                 sparkle:version="1.2.1"
                 sparkle:shortVersionString="1.2.1"
                 sparkle:dsaSignature="..."
                 length="1234567"
                 type="application/octet-stream"/>
    </item>
  </channel>
</rss>
```

## Release Checklist

### Before Release

- [ ] Update version in `project.yml` (`MARKETING_VERSION` and `CURRENT_PROJECT_VERSION`)
- [ ] Update release notes in `scripts/generate-appcast.sh`
- [ ] Test the build locally: `just build-plus`
- [ ] Run tests: `just test`

### Release Process

- [ ] Build and notarize: `just notarize`
- [ ] Download the `.zip` file from `archive/`
- [ ] Create GitHub release with the `.zip` file
- [ ] Generate appcast: `./generate-appcast.sh VERSION ZIP_PATH`
- [ ] Commit appcast to GitHub
- [ ] Verify Sparkle can check for updates

### After Release

- [ ] Test update flow on a clean machine
- [ ] Verify notarization status
- [ ] Monitor for any user reports

## Security: Signing Updates

Sparkle supports two signature methods:

### DSA (Recommended for compatibility)

1. Generate a DSA key pair:
```bash
openssl genrsa -out keys/dsa_priv.pem 2048
openssl rsa -in keys/dsa_priv.pem -pubout -out keys/dsa_pub.pem
```

2. Sign updates:
```bash
./generate-appcast.sh --signing-key keys/dsa_priv.pem 1.2.1 QuickRecorder-1.2.1.zip
```

3. Add public key to Info.plist:
```xml
<key>SUPublicDSAKey</key>
<base64encodedpublickey>...</base64encodedpublickey>
```

### ED25519 (Modern, recommended)

1. Generate an ED25519 key pair:
```bash
sodium -g -k keys/ed_priv.key -p keys/ed_pub.key
```

2. Sign updates:
```bash
./generate-appcast.sh --signing-key keys/ed_priv.key 1.2.1 QuickRecorder-1.2.1.zip
```

3. Add public key to Info.plist:
```xml
<key>SUEnableED25519Signature</key>
<true/>
<key>SUPublicDSAKey</key>
<base64encodedpublickey>...</base64encodedpublickey>
```

## Troubleshooting

### "Unable to Check For Updates" Error

**Cause**: Appcast URL is incorrect or file doesn't exist

**Solution**:
1. Verify appcast.xml exists in the repository
2. Check SUFeedURL in Info.plist matches the raw GitHub URL:
   ```
   https://raw.githubusercontent.com/hisgarden/QuickRecorder/main/appcast.xml
   ```
3. Ensure the file is committed and pushed to GitHub

### Update Not Appearing

**Cause**: Version number mismatch

**Solution**:
1. Check that sparkle:version matches the actual version
2. Verify the release file URL is accessible
3. Clear Sparkle cache:
   ```bash
   rm ~/Library/Caches/org.sparkle-project.Sparkle/FeedCache/*
   ```

### Signature Verification Failed

**Cause**: Incorrect or missing signature

**Solution**:
1. Regenerate the appcast with the signing key
2. Verify the public key is in Info.plist
3. Check that the file hasn't been modified after signing

## Best Practices

1. **Version Numbering**: Use semantic versioning (MAJOR.MINOR.PATCH)
2. **Release Notes**: Include meaningful changes for users
3. **Testing**: Always test updates before releasing to users
4. **Signing**: Sign updates for security (prevents man-in-the-middle attacks)
5. **Backup**: Keep signing keys secure and backed up

## Resources

- [Sparkle Documentation](https://sparkle-project.org/documentation/)
- [Appcast Format](https://sparkle-project.org/documentation/publishing/)
- [Security Best Practices](https://sparkle-project.org/documentation/security/)
- [GitHub Releases](https://docs.github.com/en/repositories/releasing-projects-on-github/about-releases)

## Automation

### Adding to CI/CD

```yaml
# .github/workflows/release.yml
name: Release

on:
  release:
    types: [published]

jobs:
  release:
    runs-on: macOS
    steps:
      - uses: actions/checkout@v3

      - name: Build and Notarize
        run: just notarize

      - name: Download Artifact
        uses: actions/download-artifact@v3
        with:
          name: QuickRecorder.zip
          path: archive/

      - name: Generate Appcast
        run: ./generate-appcast.sh ${{ github.event_name }} archive/QuickRecorder.zip

      - name: Commit Appcast
        run.release.tag: |
          git add appcast.xml
          git commit -m "Add appcast for ${{ github.event.release.tag_name }}"
          git push
```

## Support

For issues with:
- Sparkle: Visit [Sparkle Discussions](https://github.com/sparkle-project/Sparkle/discussions)
- This setup: Check existing issues or open a new one

