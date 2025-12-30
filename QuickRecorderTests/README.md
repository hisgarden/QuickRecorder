# QuickRecorder Test Suite

This directory contains a comprehensive Test-Driven Development (TDD) test suite for the QuickRecorder application.

## Test Structure

The test suite is organized into the following test files:

### Core Tests

- **SCContextTests.swift** - Tests for the `SCContext` class including:
  - File path generation
  - Audio settings configuration
  - Background color handling
  - Recording state management
  - Time adjustment utilities

- **RecordEngineTests.swift** - Tests for recording engine functionality:
  - Recording preparation for different types (window, display, application, area, audio)
  - File path validation
  - Video configuration (MP4, MOV, H.264, H.265)
  - Audio recording preparation

- **AVContextTests.swift** - Tests for audio/video context:
  - Camera recording
  - Device recording (iDevice)
  - Device discovery (cameras, microphones, iDevices)
  - Sample rate detection

- **UtilityTests.swift** - Tests for utility functions and extensions:
  - String extensions (localization, path manipulation)
  - NSImage extensions (screenshot, save, trim)
  - CMSampleBuffer extensions
  - FixedLengthArray data structure

### Test Helpers

- **TestHelpers.swift** - Utility functions for test setup:
  - UserDefaults test fixtures
  - Sample buffer creation
  - File system helpers
  - Time manipulation helpers
  - Custom assertion helpers

## Setup Instructions

### 1. Add Test Target in Xcode

1. Open `QuickRecorder.xcodeproj` in Xcode
2. Go to **File** → **New** → **Target**
3. Select **Unit Testing Bundle** under **macOS**
4. Name it `QuickRecorderTests`
5. Ensure the target is set to test the `QuickRecorder` target
6. Click **Finish**

### 2. Configure Test Target

1. Select the `QuickRecorderTests` target in the project navigator
2. Go to **Build Settings**
3. Set **Product Name** to `QuickRecorderTests`
4. Set **Bundle Identifier** to `dev.hisgarden.QuickRecorderTests`
5. Under **General** → **Frameworks, Libraries, and Embedded Content**, ensure all required frameworks are linked:
   - AVFoundation
   - AVFAudio
   - ScreenCaptureKit
   - AppKit
   - Foundation

### 3. Add Test Files to Target

1. Select all test files in `QuickRecorderTests/` directory
2. In the **File Inspector** (right panel), check the `QuickRecorderTests` target under **Target Membership**

### 4. Configure Test Target Dependencies

1. Select the `QuickRecorderTests` target
2. Go to **Build Phases**
3. Expand **Dependencies**
4. Add `QuickRecorder` as a dependency
5. Expand **Link Binary With Libraries** and ensure all required frameworks are present

### 5. Enable Testability

1. Select the `QuickRecorder` target (not the test target)
2. Go to **Build Settings**
3. Search for **Enable Testability**
4. Set it to **Yes** for both Debug and Release configurations

### 6. Import Statement

Ensure all test files use:
```swift
@testable import QuickRecorder
```

This allows access to internal types and methods for testing.

## Running Tests

### In Xcode

1. Press `⌘ + U` to run all tests
2. Or click the diamond icon next to any test method to run individual tests
3. Use the Test Navigator (`⌘ + 6`) to see all tests and their status

### From Command Line

```bash
# Run all tests
xcodebuild test -scheme QuickRecorder -destination 'platform=macOS'

# Run specific test class
xcodebuild test -scheme QuickRecorder -destination 'platform=macOS' -only-testing:QuickRecorderTests/SCContextTests
```

## Test Coverage

To enable test coverage:

1. Go to **Edit Scheme** (⌘ + <)
2. Select **Test** in the left sidebar
3. Check **Gather coverage data**
4. Run tests
5. View coverage in the Report Navigator (`⌘ + 9`)

## Writing New Tests

### TDD Workflow

1. **Red**: Write a failing test
2. **Green**: Write minimal code to make it pass
3. **Refactor**: Improve code while keeping tests green

### Test Naming Convention

- Test methods should start with `test`
- Use descriptive names: `testFunctionName_Scenario_ExpectedResult`
- Example: `testGetFilePath_GeneratesValidPath()`

### Test Structure

```swift
func testExample() {
    // Given - Set up test data and conditions
    let input = "test"
    
    // When - Execute the code under test
    let result = functionUnderTest(input)
    
    // Then - Assert the expected outcome
    XCTAssertEqual(result, expectedValue)
}
```

## Mocking and Test Doubles

For tests that require external dependencies:

1. **UserDefaults**: Use test suite-specific UserDefaults (see `TestHelpers.createTestUserDefaults()`)
2. **File System**: Use temporary directories (see `TestHelpers.createTempDirectory()`)
3. **Hardware**: Some tests may skip if hardware is unavailable (use `XCTSkip`)

## Known Limitations

Some tests may require:
- Screen recording permissions
- Camera permissions
- Microphone permissions
- Actual hardware (cameras, microphones, iDevices)

These tests use `XCTSkip` when hardware/permissions are unavailable.

## Continuous Integration

To run tests in CI:

```yaml
# Example GitHub Actions workflow
- name: Run Tests
  run: |
    xcodebuild test \
      -scheme QuickRecorder \
      -destination 'platform=macOS' \
      -enableCodeCoverage YES
```

## Troubleshooting

### Tests Not Found
- Ensure test files are added to the `QuickRecorderTests` target
- Check that test classes inherit from `XCTestCase`
- Verify test methods start with `test`

### Import Errors
- Ensure `@testable import QuickRecorder` is used
- Check that **Enable Testability** is set to **Yes** for the main target
- Verify the test target depends on the main target

### Permission Errors
- Some tests require system permissions
- Use `XCTSkip` for tests that can't run without permissions
- Consider using dependency injection for better testability

## Contributing

When adding new functionality:

1. Write tests first (TDD)
2. Ensure all tests pass
3. Maintain or improve test coverage
4. Update this README if adding new test categories

