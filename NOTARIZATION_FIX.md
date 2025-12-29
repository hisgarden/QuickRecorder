# Notarization Fix - Certificate Issue Resolved

## Problem Identified

The notarization is failing because the app is signed with **"Apple Distribution"** certificate, but Apple's notarization service **requires "Developer ID Application"** certificate for apps distributed outside the App Store.

### Certificate Types:
- **Apple Distribution**: For App Store distribution only
- **Developer ID Application**: For direct distribution outside App Store (requires notarization)
- **Apple Development**: For development/testing only

## Solution: Create Developer ID Application Certificate

### Step 1: Create the Certificate

1. Go to https://developer.apple.com/account/resources/certificates/list
2. Click the **"+"** button to create a new certificate
3. Select **"Developer ID Application"** 
4. Follow the prompts to create a Certificate Signing Request (CSR):
   - Open **Keychain Access** app
   - Menu: Keychain Access → Certificate Assistant → Request a Certificate from a Certificate Authority
   - Enter your email: `hisgarden@pm.me`
   - Common Name: `Jin Wen`
   - Select "Saved to disk"
   - Continue and save the CSR file
5. Upload the CSR file to Apple Developer portal
6. Download the certificate when ready
7. Double-click the downloaded certificate to install it in Keychain Access

### Step 2: Verify Certificate Installation

```bash
security find-identity -v -p codesigning | grep "Developer ID Application"
```

You should see:
```
X) XXXXXXXX... "Developer ID Application: Jin Wen (NSDC3EDS2G)"
```

### Step 3: Sign the App with Developer ID

Once you have the Developer ID Application certificate:

```bash
cd /Users/hisgarden/workspace/util/QuickRecorder

# Copy fresh build
rm -rf QuickRecorder_Distribution.app
cp -R build/export/QuickRecorder.app QuickRecorder_Distribution.app

# Sign with Developer ID (update the script first)
./sign_with_developer_id.sh
```

### Step 4: Submit for Notarization

```bash
# Create zip
ditto -c -k --keepParent QuickRecorder_Distribution.app QuickRecorder_Distribution.zip

# Submit
xcrun notarytool submit QuickRecorder_Distribution.zip \
  --keychain-profile notary-profile \
  --wait

# If successful, staple the ticket
xcrun stapler staple QuickRecorder_Distribution.app

# Verify
spctl -a -vv QuickRecorder_Distribution.app
# Should show: "accepted" and "notarized"
```

## Current Workaround (For Testing Only)

Until you create the Developer ID certificate, users can bypass Gatekeeper:

1. **Right-click** on QuickRecorder.app
2. Select **"Open"**  
3. Click **"Open"** in the security dialog

This creates a permanent exception for the app on that Mac.

## Why This Matters

- **Apple Distribution** certificates are for App Store submission only
- **Developer ID Application** certificates are specifically designed for:
  - Direct distribution (DMG, ZIP, etc.)
  - Notarization
  - Gatekeeper approval
  
Without the correct certificate type, notarization will always fail, regardless of how the app is signed.

## Summary

**Current Status:**
- ✅ App builds successfully
- ✅ Signing process works correctly  
- ✅ Notarization credentials configured
- ❌ **Wrong certificate type** (Apple Distribution instead of Developer ID Application)

**Action Required:**
1. Create "Developer ID Application" certificate at https://developer.apple.com/account
2. Install the certificate in Keychain Access
3. Re-sign the app with the new certificate
4. Submit for notarization

**Estimated Time:** 10-15 minutes to create and install the certificate, then notarization takes 2-5 minutes.
