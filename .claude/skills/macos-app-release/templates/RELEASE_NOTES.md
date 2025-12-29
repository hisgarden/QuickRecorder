## 🎉 {{APP_NAME}} v{{VERSION}}

### ✨ New Features
- {{NEW_FEATURE_1}}
- {{NEW_FEATURE_2}}

### 🐛 Bug Fixes
- {{BUG_FIX_1}}
- {{BUG_FIX_2}}

### 🔧 Improvements
- {{IMPROVEMENT_1}}
- {{IMPROVEMENT_2}}

### 📦 Installation

**macOS {{MIN_OS_VERSION}} and later:**

1. Download `{{APP_NAME}}_v{{VERSION}}.dmg`
2. Open the DMG file
3. Drag **{{APP_NAME}}.app** to **Applications** folder
4. Right-click the app → **Open** (first time only to bypass Gatekeeper)

**Alternative: Homebrew Installation** (if available)
```bash
brew install {{HOMEBREW_TAP}}
```

### ✅ Security & Code Signing

- ✅ Signed with **Developer ID Application** certificate
- ✅ **Notarized** by Apple (passes Gatekeeper checks)
- ✅ **Hardened Runtime** enabled for enhanced security
- ✅ All components signed with secure timestamps

**First Launch:** macOS may show a security dialog on first launch. Simply:
1. **Right-click** on the app
2. Select **"Open"**
3. Click **"Open"** in the dialog

After the first launch, the app will open normally.

### 📝 Checksums (SHA256)

For security verification, see `{{APP_NAME}}_v{{VERSION}}_SHA256.txt` in the release assets.

To verify:
```bash
shasum -a 256 {{APP_NAME}}_v{{VERSION}}.dmg
# Compare with checksum in SHA256.txt file
```

### 🔗 Links

- **Documentation:** {{DOCS_URL}}
- **Report Issues:** {{ISSUES_URL}}
- **Source Code:** {{REPO_URL}}

---

**Full Changelog**: {{REPO_URL}}/compare/v{{PREV_VERSION}}...v{{VERSION}}

### 💝 Support the Project

If you find {{APP_NAME}} useful, please consider:
- ⭐ Starring the repository
- 🐛 Reporting bugs or suggesting features
- 💬 Sharing with others who might benefit

---

**Release Date:** {{RELEASE_DATE}}
**Build:** {{BUILD_NUMBER}}
