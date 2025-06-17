//
//  SmokeTests.swift
//  QuickRecorderTests
//
//  Created by Test Coverage Phase 1 on 2025/06/16.
//

import XCTest
@testable import QuickRecorder

/// Basic smoke tests to verify critical app functionality
class SmokeTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    // MARK: - App Launch Tests
    
    func testAppCanLaunch() throws {
        // Given/When/Then - Basic app components can be instantiated
        XCTAssertNoThrow(SettingsManager.shared)
        XCTAssertNoThrow(ErrorHandler.shared)
    }
    
    func testSettingsManagerBasicFunctionality() throws {
        // Given
        let settings = SettingsManager.shared
        
        // When/Then - Basic properties can be accessed
        XCTAssertNotNil(settings.frameRate)
        XCTAssertNotNil(settings.videoQuality)
        XCTAssertNotNil(settings.audioFormat)
        XCTAssertNotNil(settings.videoFormat)
        XCTAssertNotNil(settings.encoder)
    }
    
    func testErrorHandlerBasicFunctionality() throws {
        // Given
        let errorHandler = ErrorHandler.shared
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.txt")
        
        // When/Then - Basic error handling works
        XCTAssertNoThrow(errorHandler.createDirectory(at: tempURL.path))
        
        // Cleanup
        try? FileManager.default.removeItem(at: tempURL)
    }
    
    // MARK: - Critical Path Tests
    
    func testRecordingErrorTypes() throws {
        // Given/When/Then - All recording error types have descriptions
        let errors: [RecordingError] = [
            .audioFileCreationFailed("test"),
            .audioEngineStartFailed("test"),
            .videoWriterCreationFailed("test"),
            .directoryCreationFailed("test"),
            .audioFormatUnsupported("test"),
            .fileSizeCastFailed,
            .savedAreaCastFailed,
            .screenCaptureSetupFailed("test"),
            .exportFailed("test")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testAudioVideoEnums() throws {
        // Given/When/Then - Enums have valid raw values
        XCTAssertEqual(AudioFormat.aac.rawValue, "aac")
        XCTAssertEqual(AudioFormat.mp3.rawValue, "mp3")
        
        XCTAssertEqual(VideoFormat.mp4.rawValue, "mp4")
        XCTAssertEqual(VideoFormat.mov.rawValue, "mov")
        
        XCTAssertEqual(Encoder.h264.rawValue, "h264")
        XCTAssertEqual(Encoder.h265.rawValue, "h265")
    }
    
    func testSettingsValidation() throws {
        // Given
        let settings = SettingsManager.shared
        let originalFrameRate = settings.frameRate
        let originalVideoQuality = settings.videoQuality
        
        // When - Set invalid values
        settings.frameRate = -10
        settings.videoQuality = -0.5
        settings.validateSettings()
        
        // Then - Values should be corrected
        XCTAssertEqual(settings.frameRate, 60)
        XCTAssertEqual(settings.videoQuality, 1.0)
        
        // Cleanup
        settings.frameRate = originalFrameRate
        settings.videoQuality = originalVideoQuality
    }
    
    func testDirectoryCreation() throws {
        // Given
        let errorHandler = ErrorHandler.shared
        let testDir = FileManager.default.temporaryDirectory.appendingPathComponent("QuickRecorderTest-\(UUID().uuidString)")
        
        // When
        let result = errorHandler.createDirectory(at: testDir.path)
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(FileManager.default.fileExists(atPath: testDir.path))
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
        
        // Cleanup
        try? FileManager.default.removeItem(at: testDir)
    }
    
    // MARK: - Performance Smoke Tests
    
    func testSettingsPerformance() throws {
        let settings = SettingsManager.shared
        
        measure {
            for _ in 0..<1000 {
                _ = settings.frameRate
                _ = settings.videoQuality
                _ = settings.audioFormat
                _ = settings.getSaveDirectory()
            }
        }
    }
    
    func testErrorHandlerPerformance() throws {
        let errorHandler = ErrorHandler.shared
        
        measure {
            for _ in 0..<100 {
                let testArea: [String: Any] = ["x": 100.0, "y": 200.0]
                _ = errorHandler.getCGFloatFromArea(testArea, key: "x")
                _ = errorHandler.getCGFloatFromArea(testArea, key: "y")
            }
        }
    }
} 