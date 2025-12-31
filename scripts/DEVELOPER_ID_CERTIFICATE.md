# Getting Developer ID Application Certificate

To notarize your macOS app, you need a **Developer ID Application certificate**, not a regular Apple Development certificate.

## Current Status Check

Run this to see what you have:

```bash
security find-identity -v -p codesigning
```

### You Have Apple Development ❌
```
1) 8C486D55... "Apple Development: Your Name (XXXXX)"
```

This is for App Store builds, NOT for notarization.

### You Need Developer ID Application ✅
```
1) 8C486D55... "Developer ID Application: Your Name (TEAMID)"
```

This is specifically for code-signing apps distributed outside the App Store.

## Step-by-Step: Get Developer ID Certificate

### 1. Go to Apple Developer Portal

Open: https://developer.apple.com/account/resources/certificates

Sign in with your Apple Developer Account

### 2. Create New Certificate

Click **+ Create a Certificat**e

### 3. Select Certificate Type

Find and select: **Developer ID Application**

Click **Continue**

### 4. Follow CSR Instructions

Follow the on-screen instructions:
- Open Keychain Access
- Go to **Keychain Access → Certificate Assistant → Request a Certificate**
- Enter your email and name
- Save to disk
- Go back to browser and upload the CSR file

### 5. Download Certificate

Click **Download** to save the certificate file (usually `DeveloperIDApplication.cer`)

### 6. Install in Keychain

Double-click the `.cer` file to install it in your login Keychain

### 7. Verify Installation

Run:
```bash
security find-identity -v -p codesigning
```

You should now see:
```
1) 8C486D55... "Developer ID Application: Your Name (TEAMID)"
```

The `TEAMID` (e.g., `NSDC3EDS2G`) is what goes in `project.yml` as `DEVELOPMENT_TEAM`

## Troubleshooting

### Certificate Not Showing Up

1. **Keychain Access might not be updated**
   ```bash
   # Restart Keychain
   killall -9 security-agent
   ```

2. **Wrong Keychain location**
   - Ensure certificate is in "login" keychain
   - Open Keychain Access → Select "login" in left sidebar

3. **Certificate format issue**
   - Try importing again by double-clicking the `.cer` file

### Multiple Certificates

If you have multiple Developer ID certificates:

1. Check which one is valid:
   ```bash
   security find-identity -v -p codesigning | grep "Developer ID"
   ```

2. The newest one is usually the active one
3. If unsure, create a new one (old ones can be revoked later)

## After Getting Certificate

1. **Note your Team ID**
   - It's in the certificate name: `Developer ID Application: Name (TEAMID)`

2. **Update project.yml**
   ```yaml
   DEVELOPMENT_TEAM: "TEAMID"  # e.g., NSDC3EDS2G
   ```

3. **Regenerate Xcode project**
   ```bash
   xcodegen generate
   ```

4. **Try notarization**
   ```bash
   just notarize
   ```

## Certificate Validity

- **Valid for**: 3 years
- **Revocation**: Can be revoked in Apple Developer Portal anytime
- **Multiple certificates**: You can have multiple, system picks the most recent

## Common Questions

### Q: Can I use Apple Development certificate?
**A:** No. Apple Development is only for App Store and TestFlight. Developer ID is required for notarization.

### Q: Do I need to pay?
**A:** Yes, Apple Developer Program membership ($99/year). But you get access to all certificates and notarization service.

### Q: What if my certificate expires?
**A:** Create a new one in Developer Portal. Old apps remain notarized, you just can't sign new builds with it.

### Q: Can I use my personal Developer ID?
**A:** Yes! If you're an individual developer, your Developer ID is your personal ID. If you're part of an organization, you use the org's Team ID.

## Next Steps

1. ✅ Get Developer ID Application certificate
2. ✅ Install in Keychain
3. ✅ Note your Team ID
4. ✅ Update `project.yml` with Team ID
5. ✅ Run `just notarize`

## Resources

- [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates)
- [Create CSR in Keychain](https://support.apple.com/en-us/HT211241)
- [Notarizing macOS Apps](https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution)
- [Developer ID FAQs](https://developer.apple.com/support/developer-id/)

---

**Still stuck?** Make sure you have:
1. Apple Developer Account (paid)
2. Developer ID Application certificate (not Apple Development)
3. Certificate installed in login Keychain
4. Team ID in `project.yml`
5. `CODE_SIGN_STYLE: Manual` in `project.yml`

