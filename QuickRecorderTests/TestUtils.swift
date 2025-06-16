//
//  TestUtils.swift
//  QuickRecorderTests
//
//  Created by TDD on 2024/12/19.
//

import XCTest
import Foundation
@testable import QuickRecorder

// MARK: - Test Utilities

/// Utility class containing helper methods for testing
class TestUtils {
    
    /// Creates a temporary directory for testing
    static func createTempDirectory(withPrefix prefix: String = "QuickRecorderTest") -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let uniqueDir = tempDir.appendingPathComponent("\(prefix)-\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(at: uniqueDir, withIntermediateDirectories: true)
            return uniqueDir
        } catch {
            XCTFail("Failed to create temporary directory: \(error)")
            return tempDir
        }
    }
    
    /// Safely removes a directory and all its contents
    static func removeTempDirectory(_ directory: URL) {
        do {
            if FileManager.default.fileExists(atPath: directory.path) {
                try FileManager.default.removeItem(at: directory)
            }
        } catch {
            print("Warning: Failed to remove temporary directory: \(error)")
        }
    }
    
    /// Creates a test file with specified content
    static func createTestFile(at url: URL, content: String = "Test content") throws {
        try content.write(to: url, atomically: true, encoding: .utf8)
    }
    
    /// Waits for an async operation to complete
    static func waitForAsync(timeout: TimeInterval = 1.0, operation: @escaping (@escaping () -> Void) -> Void) {
        let expectation = XCTestExpectation(description: "Async operation")
        
        operation {
            expectation.fulfill()
        }
        
        _ = XCTWaiter.wait(for: [expectation], timeout: timeout)
    }
}

// MARK: - Mock Classes

/// Mock implementation of RecordingError for testing
enum MockRecordingError: Error, LocalizedError {
    case testError(String)
    
    var errorDescription: String? {
        switch self {
        case .testError(let message):
            return "Test Error: \(message)"
        }
    }
}

/// Test double for testing error scenarios
class MockErrorHandler {
    var shouldFail = false
    var failureError: RecordingError = .exportFailed("Mock failure")
    
    func createAudioFile(url: URL, settings: [String: Any]) -> Result<MockAudioFile, RecordingError> {
        if shouldFail {
            return .failure(failureError)
        }
        return .success(MockAudioFile(url: url))
    }
    
    func createDirectory(at path: String) -> Result<Void, RecordingError> {
        if shouldFail {
            return .failure(failureError)
        }
        return .success(())
    }
}

/// Mock audio file for testing
class MockAudioFile {
    let url: URL
    
    init(url: URL) {
        self.url = url
    }
}

/// Test configuration provider
class TestConfiguration {
    static let defaultAudioSettings: [String: Any] = [
        "AVFormatIDKey": 1633772320, // kAudioFormatMPEG4AAC
        "AVSampleRateKey": 44100,
        "AVNumberOfChannelsKey": 2
    ]
    
    static let highQualityAudioSettings: [String: Any] = [
        "AVFormatIDKey": 1633772320, // kAudioFormatMPEG4AAC
        "AVSampleRateKey": 48000,
        "AVNumberOfChannelsKey": 2
    ]
    
    static let testVideoSettings = [
        "frameRate": 30,
        "quality": 1,
        "format": 0
    ]
}

// MARK: - Assertions

/// Custom assertions for testing QuickRecorder components
extension XCTestCase {
    
    /// Asserts that a Result is successful and returns the value
    func assertSuccess<T, E>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> T? {
        switch result {
        case .success(let value):
            return value
        case .failure(let error):
            XCTFail("Expected success but got failure: \(error)", file: file, line: line)
            return nil
        }
    }
    
    /// Asserts that a Result is a failure and returns the error
    func assertFailure<T, E>(_ result: Result<T, E>, file: StaticString = #file, line: UInt = #line) -> E? {
        switch result {
        case .success(let value):
            XCTFail("Expected failure but got success: \(value)", file: file, line: line)
            return nil
        case .failure(let error):
            return error
        }
    }
    
    /// Asserts that a RecordingError is of the expected type
    func assertErrorType(_ error: RecordingError, expectedType: RecordingError, file: StaticString = #file, line: UInt = #line) {
        switch (error, expectedType) {
        case (.audioFileCreationFailed, .audioFileCreationFailed),
             (.audioEngineStartFailed, .audioEngineStartFailed),
             (.videoWriterCreationFailed, .videoWriterCreationFailed),
             (.directoryCreationFailed, .directoryCreationFailed),
             (.audioFormatUnsupported, .audioFormatUnsupported),
             (.fileSizeCastFailed, .fileSizeCastFailed),
             (.savedAreaCastFailed, .savedAreaCastFailed),
             (.screenCaptureSetupFailed, .screenCaptureSetupFailed),
             (.exportFailed, .exportFailed):
            // Types match
            break
        default:
            XCTFail("Expected error type \(expectedType) but got \(error)", file: file, line: line)
        }
    }
    
    /// Asserts that settings values are within valid ranges
    func assertSettingsInValidRange(_ settingsManager: SettingsManager, file: StaticString = #file, line: UInt = #line) {
        XCTAssertGreaterThanOrEqual(settingsManager.frameRate, 1, "Frame rate should be at least 1", file: file, line: line)
        XCTAssertLessThanOrEqual(settingsManager.frameRate, 120, "Frame rate should not exceed 120", file: file, line: line)
        
        XCTAssertGreaterThanOrEqual(settingsManager.videoQuality, 0, "Video quality should be at least 0", file: file, line: line)
        XCTAssertLessThanOrEqual(settingsManager.videoQuality, 4, "Video quality should not exceed 4", file: file, line: line)
        
        XCTAssertGreaterThanOrEqual(settingsManager.audioQuality, 0, "Audio quality should be at least 0", file: file, line: line)
        XCTAssertLessThanOrEqual(settingsManager.audioQuality, 2, "Audio quality should not exceed 2", file: file, line: line)
        
        XCTAssertGreaterThanOrEqual(settingsManager.micVolume, 0.0, "Mic volume should be at least 0.0", file: file, line: line)
        XCTAssertLessThanOrEqual(settingsManager.micVolume, 1.0, "Mic volume should not exceed 1.0", file: file, line: line)
        
        XCTAssertGreaterThanOrEqual(settingsManager.systemAudioVolume, 0.0, "System audio volume should be at least 0.0", file: file, line: line)
        XCTAssertLessThanOrEqual(settingsManager.systemAudioVolume, 1.0, "System audio volume should not exceed 1.0", file: file, line: line)
    }
}

// MARK: - Test Data Generators

/// Generates test data for various testing scenarios
class TestDataGenerator {
    
    /// Generates random valid settings configuration
    static func randomValidSettings() -> (frameRate: Int, videoQuality: Int, audioQuality: Int, micVolume: Float, systemVolume: Float) {
        let frameRates = [24, 30, 60, 120]
        let videoQualities = [0, 1, 2, 3, 4]
        let audioQualities = [0, 1, 2]
        
        return (
            frameRate: frameRates.randomElement()!,
            videoQuality: videoQualities.randomElement()!,
            audioQuality: audioQualities.randomElement()!,
            micVolume: Float.random(in: 0.0...1.0),
            systemVolume: Float.random(in: 0.0...1.0)
        )
    }
    
    /// Generates test audio settings for different quality levels
    static func audioSettings(for quality: Int) -> [String: Any] {
        switch quality {
        case 0: // Low
            return [
                "AVFormatIDKey": 1633772320,
                "AVSampleRateKey": 22050,
                "AVNumberOfChannelsKey": 1
            ]
        case 1: // Medium
            return TestConfiguration.defaultAudioSettings
        case 2: // High
            return TestConfiguration.highQualityAudioSettings
        default:
            return TestConfiguration.defaultAudioSettings
        }
    }
    
    /// Generates test file names with proper extensions
    static func testFileName(for format: Int) -> String {
        let timestamp = Int(Date().timeIntervalSince1970)
        switch format {
        case 0: return "test-recording-\(timestamp).mov"
        case 1: return "test-recording-\(timestamp).mp4"
        case 2: return "test-recording-\(timestamp).m4v"
        default: return "test-recording-\(timestamp).mov"
        }
    }
} 