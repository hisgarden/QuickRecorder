# QuickRecorder XcodeGen Setup Guide

This document describes how to set up and use XcodeGen for the QuickRecorder project.

## Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Development Workflow](#development-workflow)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)
- [Migration Guide](#migration-guide)

---

## Overview

XcodeGen is a command-line tool that generates Xcode projects from YAML configuration files. Instead of manually managing the `project.pbxproj` file (which is complex and causes merge conflicts in version control), you define your project in a simple `project.yml` file.

### Benefits

| Benefit | Description |
|---------|-------------|
| **Version Control Friendly** | `project.yml` is small and merge-friendly |
| **Reproducible Builds** | Same config = same project structure |
| **Easy Maintenance** | Update settings via YAML, not Xcode GUI |
| **CI/CD Integration** | Generate projects in automated pipelines |
| **Template-Based** | Create multiple configurations easily |

---

## Prerequisites

- macOS 12.3 (Monterey) or later
- Xcode 15.0 or later
- Homebrew (recommended for installation)

---

## Installation

### Option 1: Homebrew (Recommended)

```bash
# Install XcodeGen
brew install xcodegen

# Verify installation
xcodegen --version
# Should output: 2.40.0 or similar
```

### Option 2: Mint

```bash
mint install yonaskolb/XcodeGen
```

### Option 3: Direct Download

```bash
# Download latest release
curl -L https://github.com/yonaskolb/XcodeGen/releases/download/2.40.0/XcodeGen-2.40.0.pkg -o XcodeGen.pkg

# Install
sudo installer -pkg XcodeGen.pkg -target /
```

---

## Project Structure

After generating the project, your structure will look like this:

```
QuickRecorder/
├── project.yml              # ← Your source of truth (edit this!)
├── QuickRecorder.xcodeproj/ # ← Generated (don't edit!)
│   ├── project.pbxproj
│   ├── project.xcworkspace/
│   └── xcshareddata/
├── QuickRecorder/           # ← Source code
│   ├── QuickRecorderApp.swift
│   ├── SCContext.swift
│   ├── RecordEngine.swift
│   └── ViewModel/
├── QuickRecorderTests/      # ← Test code
│   ├── SCContextTests.swift
│   ├── RecordEngineTests.swift
│   └── ...
├── setup.sh                 # ← Setup script
├── setupTests.sh            # ← Test runner
└── README.md
```

---

## Quick Start

### First Time Setup

```bash
# 1. Clone the repository
git clone https://github.com/hisgarden/QuickRecorder.git
cd QuickRecorder

# 2. Run setup script (installs XcodeGen and generates project)
./setup.sh

# 3. Open in Xcode
open QuickRecorder.xcodeproj
```

### Regenerate Project

If you modify `project.yml`:

```bash
# Regenerate Xcode project
xcodegen generate

# Or use the setup script
./setup.sh --regenerate
```

### Run Tests

```bash
# Run all tests
./setupTests.sh

# Run with coverage
./setupTests.sh --coverage

# Watch mode (auto-re-run on changes)
./setupTests.sh --watch

# Run specific test class
./setupTests.sh QuickRecorderTests.SCContextTests
```

---

## Configuration

### project.yml Structure

The main configuration file is `project.yml`. Here's the key sections:

#### Project Options

```yaml
name: QuickRecorder
options:
  bundleIdPrefix: dev.hisgarden
  deployment:
    macOS: "12.3"
  xcodeVersion: "15.0"
```

#### Swift Packages

```yaml
packages:
  AECAudioStream:
    url: https://github.com/lihaoyun6/AECAudioStream.git
    from: "1.0.0"
  
  KeyboardShortcuts:
    url: https://github.com/sindresorhus/KeyboardShortcuts.git
    from: "2.0.0"
```

#### Targets

```yaml
targets:
  QuickRecorder:           # Main app target
    type: application
    platform: macOS
    sources:
      - path: QuickRecorder
    dependencies:
      - package: AECAudioStream
  
  QuickRecorderTests:      # Test target
    type: bundle.unit-test
    dependencies:
      - target: QuickRecorder
```

#### Schemes

```yaml
schemes:
  QuickRecorder:
    build:
      targets:
        QuickRecorder: all
    test:
      config: Debug
    run:
      config: Debug
```

### Common Configuration Tasks

#### Add a New Source File

Simply add the `.swift` file to the `QuickRecorder/` directory. XcodeGen will automatically include it on the next generation.

#### Add a New Dependency

```yaml
# In packages section
MyNewDependency:
  url: https://github.com/user/repo.git
  from: "1.0.0"

# In target dependencies
dependencies:
  - package: MyNewDependency
```

#### Change Build Settings

```yaml
targets:
  QuickRecorder:
    settings:
      base:
        SWIFT_OPTIMIZATION_LEVEL: "-O"  # Release optimization
```

#### Add a New Target

```yaml
targets:
  MyNewTarget:
    type: application
    platform: macOS
    sources:
      - path: MyNewTarget
```

---

## Development Workflow

### Daily Development

1. **Open Xcode**
   ```bash
   open QuickRecorder.xcodeproj
   ```

2. **Make code changes** as usual

3. **Build and test** (⌘ + B, ⌘ + U)

### When to Regenerate

Regenerate Xcode project only when:
- ✅ Adding/removing source files
- ✅ Changing build settings
- ✅ Updating dependencies
- ✅ Modifying schemes

You **don't** need to regenerate for:
- Editing `.swift` files
- Editing `.xib`/`.storyboard` files
- Editing `.swift` test files

### Git Workflow

```bash
# 1. Make code changes
edit QuickRecorder/AppDelegate.swift

# 2. Test changes
./setupTests.sh

# 3. If config changed, regenerate
# (if you modified project.yml)
xcodegen generate

# 4. Commit
git add .
git commit -m "Add new feature"

# 5. Push
git push
```

---

## Best Practices

### 1. Commit Both Files

Always commit both `project.yml` and the generated `.xcodeproj`:

```bash
git add project.yml QuickRecorder.xcodeproj/
git commit -m "Update project configuration"
```

### 2. Use .gitignore

```gitignore
# XcodeGen
*.xcodeproj/
!*.xcodeproj/project.pbxproj

# Or commit the whole project
xcodeproj/
```

### 3. Create Setup Script

Include a `setup.sh` script in your repository (see `setup.sh` in this project).

### 4. Use Version Pins

Always pin dependency versions:

```yaml
packages:
  Sparkle:
    url: https://github.com/sparkle-project/Sparkle
    from: "2.0.0"  # ← Pin to minimum version
```

### 5. Document Custom Settings

Add comments for non-obvious configurations:

```yaml
targets:
  QuickRecorder:
    settings:
      base:
        ENABLE_HARDENED_RUNTIME: YES  # Required for notarization
```

---

## Troubleshooting

### "No such module 'XCTest'"

**Solution:** Verify test target has XCTest framework:

1. Select QuickRecorderTests target
2. Build Phases → Link Binary With Libraries
3. Add XCTest.framework

### "Package Resolution Failed"

**Solution:** Resolve packages manually:

```bash
xcodebuild -resolvePackageDependencies -project QuickRecorder.xcodeproj -scheme QuickRecorder
```

### "Unable to find destination"

**Solution:** Specify destination explicitly:

```bash
xcodebuild build -project QuickRecorder.xcodeproj -scheme QuickRecorder -destination 'platform=macOS'
```

### Build Fails After Regeneration

**Solution:** Clean and rebuild:

```bash
# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/QuickRecorder-*

# Rebuild
xcodebuild clean build -project QuickRecorder.xcodeproj -scheme QuickRecorder -destination 'platform=macOS'
```

### Scheme Not Found

**Solution:** Edit scheme to include targets:

1. Product → Scheme → Edit Scheme...
2. Select Test in sidebar
3. Click "+" and add QuickRecorderTests

---

## Migration Guide

### From Manual Xcode Project

1. **Export current settings:**
   ```bash
   xcodebuild -project QuickRecorder.xcodeproj -scheme QuickRecorder -showBuildSettings > build-settings.txt
   ```

2. **Create project.yml:**
   Copy settings from Xcode and Info.plist into `project.yml`.

3. **Test generation:**
   ```bash
   xcodegen generate
   ```

4. **Compare outputs:**
   ```bash
   diff -r QuickRecorder.xcodeproj.backup QuickRecorder.xcodeproj
   ```

5. **Verify build:**
   ```bash
   xcodebuild build -project QuickRecorder.xcodeproj -scheme QuickRecorder -destination 'platform=macOS'
   ```

### From CocoaPods

1. Keep `Podfile` for dependency management (XcodeGen + CocoaPods work together)
2. Generate Xcode project first
3. Run `pod install`
4. Open `.xcworkspace` instead of `.xcodeproj`

### From Swift Package Manager

If you're already using SPM, XcodeGen can generate a project that includes SPM packages:

```yaml
packages:
  MySPMPackage:
    url: https://github.com/user/repo.git
    from: "1.0.0"

targets:
  QuickRecorder:
    dependencies:
      - package: MySPMPackage
```

---

## Additional Resources

- [XcodeGen Documentation](https://github.com/yonaskolb/XcodeGen)
- [XcodeGen Wiki](https://github.com/yonaskolb/XcodeGen/wiki)
- [SPDX License List](https://spdx.github.io/spdx-spec/license-list/)
- [Semantic Versioning](https://semver.org)

---

## Support

For issues with:
- **XcodeGen**: Check the [GitHub Issues](https://github.com/yonaskolb/XcodeGen/issues)
- **QuickRecorder**: Create an issue in this repository
- **Dependencies**: Check individual package repositories

---

**Generated for QuickRecorder v1.2.1**
**Last Updated: 2025-12-29**

