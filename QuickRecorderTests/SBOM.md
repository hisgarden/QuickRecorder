# QuickRecorder Software Bill of Materials (SBOM)

## Overview

This document serves as the official Software Bill of Materials for QuickRecorder, a lightweight and high-performance screen recorder for macOS. The SBOM is integrated into the test suite and can be validated by running the unit tests.

## SBOM Format

- **Format**: SPDX-like JSON
- **Standard**: Compatible with CycloneDX and SPDX 2.3
- **Validation**: Via `SBOMTests.swift` in the test suite

---

## Project Metadata

| Field | Value |
|-------|-------|
| **Name** | QuickRecorder |
| **Version** | See `CFBundleShortVersionString` in Info.plist |
| **Description** | A lightweight and high-performance screen recorder for macOS |
| **Author** | haiyun (hisgarden) |
| **License** | See LICENSE file |
| **Target Platform** | macOS 12.3+ |
| **Repository** | https://github.com/hisgarden/QuickRecorder |

---

## Swift Package Manager (SPM) Dependencies

### Direct Dependencies

| Package | Version | Repository | License | Purpose |
|---------|---------|------------|---------|---------|
| **AECAudioStream** | main (0eab971c1dd0420ee84646c71172dd66fa59117c) | https://github.com/lihaoyun6/AECAudioStream.git | MIT | Acoustic Echo Cancellation for audio recording |
| **KeyboardShortcuts** | 2.2.4 (7ecc38bb6edf7d087d30e737057b8d8a9b7f51eb) | https://github.com/sindresorhus/KeyboardShortcuts.git | MIT | Global keyboard shortcut handling |
| **Sparkle** | 2.6.0 (0a4caaf7a81eea2cece651ef4b17331fa0634dff) | https://github.com/sparkle-project/Sparkle | MIT | Software update framework |

### Total SPM Dependencies: 3

---

## System Frameworks

### Apple System Frameworks

| Framework | Purpose | Min macOS Version |
|-----------|---------|-------------------|
| **AppKit** | macOS application UI | 10.0 |
| **SwiftUI** | Modern declarative UI | 10.15 |
| **AVFoundation** | Audio/video recording and playback | 10.7 |
| **AVFAudio** | Advanced audio processing | 10.9 |
| **ScreenCaptureKit** | Screen capture functionality | 13.0 |
| **UserNotifications** | Notification handling | 10.14 |
| **ServiceManagement** | Launch daemon management | 10.10 |
| **CoreMediaIO** | Core Media I/O | 10.8 |
| **VideoToolbox** | Video encoding/decoding | 10.8 |
| **IOKit** | Hardware access (sleep prevention) | 10.0 |
| **Combine** | Reactive programming | 10.15 |
| **Quartz** | Core Graphics services | 10.0 |
| **UniformTypeIdentifiers** | File type identification | 11.0 |

### Total System Frameworks: 13

---

## Dependency Graph

```
QuickRecorder (Main Target)
├── AECAudioStream (SPM)
│   └── AVFoundation (System)
├── KeyboardShortcuts (SPM)
│   └── SwiftUI (System)
└── Sparkle (SPM)
    └── AppKit (System)

QuickRecorderTests (Test Target)
├── XCTest (System)
├── QuickRecorder (Main Target)
│   └── [All dependencies above]
└── [Test-specific frameworks]
```

---

## Security & Vulnerability Information

### Known Dependencies with Potential Security Considerations

| Dependency | Notes |
|------------|-------|
| **Sparkle** | Uses secure HTTPS for updates; verify signatures |
| **KeyboardShortcuts** | Uses secure input monitoring APIs |
| **AECAudioStream** | Handles audio processing; uses system audio APIs securely |

---

## Build Configuration

### Xcode Project

- **Project File**: `QuickRecorder.xcodeproj/project.pbxproj`
- **Scheme**: `QuickRecorder`
- **Minimum Deployment Target**: macOS 12.3

### Package Manager

- **Type**: Swift Package Manager (SPM)
- **Resolved File**: `QuickRecorder.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- **Version**: 3 (modern format)

---

## Test Suite Integration

The SBOM is validated through the following test classes:

### SBOMTests
Tests SPM dependencies and system frameworks are available:
- `testSPMDependencies_*` - Verifies each SPM package
- `testSystemFrameworks_*` - Verifies each system framework
- `testSBOMData_*` - Validates project metadata

### SBOMMetadataTests
Tests metadata and versioning:
- `testSBOMMetadata_*` - Validates version, license, author info

### SBOMDependencyGraphTests
Tests dependency graph integrity:
- `testDependencyGraph_*` - Verifies imports and relationships

### SBOMExportTests
Tests SBOM generation:
- `testSBOMExport_*` - Generates and validates SBOM data

### SBOMComplianceTests
Tests compliance with SBOM standards:
- `testCompliance_*` - Validates SPDX and CycloneDX compliance

---

## Running SBOM Tests

```bash
# In Xcode
⌘ + U (Product → Test)

# Or run specific SBOM tests
xcodebuild test -scheme QuickRecorder -only-testing:QuickRecorderTests/SBOMTests
```

---

## License Information

QuickRecorder is licensed under the terms specified in the LICENSE file. All dependencies use MIT-licensed code, which is permissive and allows commercial use, modification, and distribution.

---

## Updating the SBOM

When updating dependencies:

1. Update `Package.resolved` with new versions
2. Run SBOM tests to verify integration
3. Update this document with new version numbers
4. Document any breaking changes

---

## SBOM Version

- **SBOM Version**: 1.0.0
- **Last Updated**: 2025-12-29
- **Format Version**: SPDX 2.3 / CycloneDX 1.5

---

## Export Format

The SBOM can be exported in JSON format:

```json
{
  "name": "QuickRecorder",
  "version": "x.x.x",
  "SPDXID": "SPDXRef-QuickRecorder",
  "dataLicense": "CC0-1.0",
  "documentNamespace": "https://github.com/hisgarden/QuickRecorder/sbom",
  "creationInfo": {
    "created": "2025-12-29T00:00:00Z",
    "creator": "Tool: SBOMTests.swift"
  },
  "packages": [...],
  "relationships": [...]
}
```

---

## References

- [SPDX Specification](https://spdx.github.io/spdx-spec/)
- [CycloneDX Specification](https://cyclonedx.org/specification/)
- [Swift Package Manager](https://swift.org/package-manager/)
- [QuickRecorder GitHub](https://github.com/hisgarden/QuickRecorder)









