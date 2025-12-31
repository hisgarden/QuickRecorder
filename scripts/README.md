# QuickRecorder Development Scripts

This folder contains all development and build scripts for QuickRecorder. These scripts are used by the `Justfile` and are not tracked in version control.

## 📁 Script Categories

### Build Scripts
- `build.sh` - Debug build with logging
- `buildDebug.sh` - Debug build configuration
- `buildRelease.sh` - Release build configuration
- `release-export.sh` - Export release build

### Setup Scripts
- `setup.sh` - Project setup and XcodeGen generation
- `setup_tests.sh` - Test environment setup

### Distribution Scripts
- `notarize.sh` - Build, sign, and notarize for distribution
- `staple.sh` - Staple notarization ticket to app
- `check-notarization.sh` - Check notarization status
- `generate-appcast.sh` - Generate Sparkle appcast for updates

### Utility Scripts
- `credentials.sh` - Secure credential management for Apple ID
- `release-export.sh` - Export app from archive

## 🚀 Quick Start

### Full Setup
```bash
./setup.sh
```

### Build & Notarize
```bash
./notarize.sh
```

### Generate Appcast
```bash
./generate-appcast.sh 1.7.0 archive/QuickRecorder-*.zip
```

## 📖 Documentation

See individual documentation files:
- `NOTARIZATION_SETUP.md` - Notarization workflow
- `STAPLING_GUIDE.md` - Stapling tickets
- `APPCAST_SETUP.md` - Sparkle updates
- `CODE_SIGNING_GUIDE.md` - Code signing
- `DEVELOPER_ID_CERTIFICATE.md` - Certificates

## 🔧 Usage with Just

The `Justfile` provides convenient aliases:

| Command | Script | Description |
|---------|--------|-------------|
| `just setup` | `setup.sh` | Full setup |
| `just notarize` | `notarize.sh` | Build & notarize |
| `just staple` | `staple.sh` | Staple ticket |
| `just appcast` | `generate-appcast.sh` | Generate appcast |

## 📝 Notes

- All scripts are executable (chmod +x)
- Scripts may require XcodeGen and Xcode Command Line Tools
- Credentials are managed securely via Keychain
- Build logs are stored in `../logs/`
- Archives are stored in `../archive/`

## 🔒 Security

- Apple ID credentials are stored in Keychain
- App-specific passwords are recommended
- Biometric authentication (Touch ID/Watch) can be configured
- See `credentials.sh` for secure credential retrieval





