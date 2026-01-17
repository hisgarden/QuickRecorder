# SBOM (Software Bill of Materials) Test Suite

## Overview

The SBOM test suite validates all dependencies, frameworks, and components used in QuickRecorder. This is part of a comprehensive testing strategy to ensure dependency compliance and security.

## Test Files

### SBOMTests.swift
Main SBOM validation tests:

| Test | Purpose | Status |
|------|---------|--------|
| `testSPMDependencies_AECAudioStream_Exists` | Verifies AECAudioStream import | ✅ |
| `testSPMDependencies_KeyboardShortcuts_Exists` | Verifies KeyboardShortcuts import | ✅ |
| `testSPMDependencies_Sparkle_Exists` | Verifies Sparkle import | ✅ |
| `testSystemFrameworks_AppKit_Available` | Tests AppKit availability | ✅ |
| `testSystemFrameworks_SwiftUI_Available` | Tests SwiftUI availability | ✅ |
| `testSystemFrameworks_AVFoundation_Available` | Tests AVFoundation availability | ✅ |
| `testSystemFrameworks_AVFAudio_Available` | Tests AVFAudio availability | ✅ |
| `testSystemFrameworks_ScreenCaptureKit_Available` | Tests ScreenCaptureKit availability | ✅ |
| `testSystemFrameworks_UserNotifications_Available` | Tests UserNotifications availability | ✅ |
| `testSystemFrameworks_ServiceManagement_Available` | Tests ServiceManagement availability | ✅ |
| `testSystemFrameworks_CoreMediaIO_Available` | Tests CoreMediaIO availability | ✅ |
| `testSystemFrameworks_VideoToolbox_Available` | Tests VideoToolbox availability | ✅ |
| `testSystemFrameworks_IOKit_Available` | Tests IOKit availability | ✅ |
| `testSystemFrameworks_Combine_Available` | Tests Combine availability | ✅ |
| `testSystemFrameworks_Quartz_Available` | Tests Quartz availability | ✅ |
| `testSystemFrameworks_UniformTypeIdentifiers_Available` | Tests UniformTypeIdentifiers availability | ✅ |
| `testSystemFrameworks_AppKit_CustomColor_Available` | Tests NSColor availability | ✅ |
| `testSBOMData_ProjectInfo_Available` | Validates project metadata | ✅ |
| `testSBOMData_MinimumMacOSVersion_Valid` | Checks macOS version | ✅ |
| `testSBOMData_Entitlements_Configured` | Verifies entitlements | ✅ |
| `testSBOMVersions_SPM_PinsExist` | Checks SPM versions | ✅ |
| `testSBOMVersions_MacOS_Compatibility` | Validates macOS compatibility | ✅ |

### SBOMMetadataTests.swift
Metadata validation:

| Test | Purpose |
|------|---------|
| `testSBOMMetadata_Author_Defined` | Verifies author info |
| `testSBOMMetadata_Version_Available` | Checks version strings |
| `testSBOMMetadata_License_Defined` | Verifies license file |

### SBOMDependencyGraphTests.swift
Dependency graph validation:

| Test | Purpose |
|------|---------|
| `testDependencyGraph_Core_DirectImports` | Tests core imports |
| `testDependencyGraph_ViewModels_Importable` | Tests ViewModel imports |
| `testDependencyGraph_Supports_Importable` | Tests support class imports |
| `testDependencyGraph_NoMissingImports` | Verifies all imports available |

### SBOMExportTests.swift
SBOM export functionality:

| Test | Purpose |
|------|---------|
| `testSBOMExport_JSON_Format` | Generates JSON SBOM |
| `testSBOMExport_SPMSummary` | Counts SPM deps |
| `testSBOMExport_FrameworkSummary` | Counts system frameworks |

### SBOMComplianceTests.swift
Standards compliance:

| Test | Purpose |
|------|---------|
| `testCompliance_SPEX_Structure` | SPDX structure validation |
| `testCompliance_CycloneDX_Format` | CycloneDX format validation |
| `testCompliance_VersionFormat` | Semantic versioning check |
| `testCompliance_LicenseIdentifiers` | SPDX license format |
| `testCompliance_UniqueIdentifiers` | Unique component IDs |

## Total Test Count: 32+ tests

## Running SBOM Tests

### In Xcode
1. Open QuickRecorder.xcodeproj
2. Go to Test Navigator (⌘ + 6)
3. Search for "SBOM"
4. Run all SBOM tests (⌘ + U)

### From Command Line
```bash
# Run all SBOM tests
xcodebuild test -scheme QuickRecorder -only-testing:QuickRecorderTests/SBOMTests

# Run specific test class
xcodebuild test -scheme QuickRecorder -only-testing:QuickRecorderTests/SBOMMetadataTests

# Run with coverage
xcodebuild test -scheme QuickRecorder -enableCodeCoverage YES
```

## Expected Results

### SPM Dependencies (3)
- ✅ AECAudioStream
- ✅ KeyboardShortcuts
- ✅ Sparkle

### System Frameworks (13)
- ✅ AppKit
- ✅ SwiftUI
- ✅ AVFoundation
- ✅ AVFAudio
- ✅ ScreenCaptureKit
- ✅ UserNotifications
- ✅ ServiceManagement
- ✅ CoreMediaIO
- ✅ VideoToolbox
- ✅ IOKit
- ✅ Combine
- ✅ Quartz
- ✅ UniformTypeIdentifiers

## SBOM Output

The test suite generates an SBOM in the following format:

```json
{
  "name": "QuickRecorder",
  "version": "1.x.x",
  "description": "A lightweight and high-performance screen recorder for macOS",
  "spm_dependencies": [...],
  "system_frameworks": [...],
  "min_macos_version": "12.3",
  "target_platform": "macOS"
}
```

## Integration with CI/CD

Add to your CI pipeline:

```yaml
- name: Run SBOM Tests
  run: |
    xcodebuild test \
      -scheme QuickRecorder \
      -destination 'platform=macOS' \
      -only-testing:QuickRecorderTests/SBOMTests \
      -only-testing:QuickRecorderTests/SBOMMetadataTests \
      -only-testing:QuickRecorderTests/SBOMDependencyGraphTests \
      -only-testing:QuickRecorderTests/SBOMExportTests \
      -only-testing:QuickRecorderTests/SBOMComplianceTests
```

## Compliance Standards

The SBOM test suite validates compliance with:

- **SPDX 2.3**: Software Package Data Exchange
- **CycloneDX 1.5**: Lightweight SBOM standard
- **Semantic Versioning 2.0.0**: Version numbering
- **SPDX License List**: License identification

## Documentation

- **Full SBOM**: See `SBOM.md`
- **Test Details**: See `SBOMTests.swift`
- **Reference**: https://spdx.github.io/spdx-spec/









