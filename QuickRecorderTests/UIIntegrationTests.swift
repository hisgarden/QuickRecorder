//
//  UIIntegrationTests.swift
//  QuickRecorderTests
//
//  Created by Test Coverage Phase 2 on 2025/06/16.
//

import XCTest
import SwiftUI
@testable import QuickRecorder

/// Integration tests for UI components and their interaction with recording system
class UIIntegrationTests: XCTestCase {
    
    var settingsManager: SettingsManager!
    var errorHandler: ErrorHandler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settingsManager = SettingsManager.shared
        errorHandler = ErrorHandler.shared
    }
    
    override func tearDownWithError() throws {
        settingsManager = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Settings Integration Tests
    
    func testUI_SettingsManagerIntegration() throws {
        // Given
        let originalFrameRate = settingsManager.frameRate
        let originalVideoQuality = settingsManager.videoQuality
        
        // When - Simulate UI changes
        settingsManager.frameRate = 60
        settingsManager.videoQuality = 0.8
        
        // Then - Changes should persist
        XCTAssertEqual(settingsManager.frameRate, 60)
        XCTAssertEqual(settingsManager.videoQuality, 0.8)
        
        // Cleanup
        settingsManager.frameRate = originalFrameRate
        settingsManager.videoQuality = originalVideoQuality
    }
    
    func testUI_VideoFormatSelection() throws {
        // Given
        let originalFormat = settingsManager.videoFormat
        
        // When - Test all video formats
        for format in [VideoFormat.mp4, VideoFormat.mov] {
            settingsManager.videoFormat = format
            
            // Then
            XCTAssertEqual(settingsManager.videoFormat, format)
            XCTAssertEqual(settingsManager.videoFormat.rawValue, format.rawValue)
        }
        
        // Cleanup
        settingsManager.videoFormat = originalFormat
    }
    
    func testUI_AudioFormatSelection() throws {
        // Given
        let originalFormat = settingsManager.audioFormat
        
        // When - Test all audio formats
        for format in [AudioFormat.aac, AudioFormat.mp3] {
            settingsManager.audioFormat = format
            
            // Then
            XCTAssertEqual(settingsManager.audioFormat, format)
            XCTAssertEqual(settingsManager.audioFormat.rawValue, format.rawValue)
        }
        
        // Cleanup
        settingsManager.audioFormat = originalFormat
    }
    
    func testUI_EncoderSelection() throws {
        // Given
        let originalEncoder = settingsManager.encoder
        
        // When - Test all encoders
        for encoder in [Encoder.h264, Encoder.h265] {
            settingsManager.encoder = encoder
            
            // Then
            XCTAssertEqual(settingsManager.encoder, encoder)
            XCTAssertEqual(settingsManager.encoder.rawValue, encoder.rawValue)
        }
        
        // Cleanup
        settingsManager.encoder = originalEncoder
    }
    
    // MARK: - Recording Area Tests
    
    func testUI_RecordingAreaConfiguration() throws {
        // Given
        let originalWidth = settingsManager.areaWidth
        let originalHeight = settingsManager.areaHeight
        
        // When - Simulate UI area selection
        settingsManager.areaWidth = 1280
        settingsManager.areaHeight = 720
        
        // Then
        XCTAssertEqual(settingsManager.areaWidth, 1280)
        XCTAssertEqual(settingsManager.areaHeight, 720)
        
        // Verify area calculations
        let scContext = SCContext()
        let size = scContext.getRecordingSize(area: [
            "width": settingsManager.areaWidth,
            "height": settingsManager.areaHeight
        ])
        
        XCTAssertEqual(size.width, 1280.0)
        XCTAssertEqual(size.height, 720.0)
        
        // Cleanup
        settingsManager.areaWidth = originalWidth
        settingsManager.areaHeight = originalHeight
    }
    
    func testUI_CommonRecordingResolutions() throws {
        // Given
        let commonResolutions = [
            (1920, 1080), // 1080p
            (1280, 720),  // 720p
            (3840, 2160), // 4K
            (2560, 1440)  // 1440p
        ]
        
        let scContext = SCContext()
        
        // When/Then - Test each resolution
        for (width, height) in commonResolutions {
            let size = scContext.getRecordingSize(area: [
                "width": width,
                "height": height
            ])
            
            XCTAssertEqual(size.width, CGFloat(width))
            XCTAssertEqual(size.height, CGFloat(height))
        }
    }
    
    // MARK: - File Management Integration Tests
    
    func testUI_SaveDirectoryIntegration() throws {
        // Given/When
        let saveDirectory = settingsManager.getSaveDirectory()
        
        // Then
        XCTAssertFalse(saveDirectory.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveDirectory))
        
        // Test directory creation
        let result = errorHandler.createDirectory(at: saveDirectory)
        switch result {
        case .success:
            XCTAssertTrue(true) // Directory exists or was created
        case .failure(let error):
            XCTFail("Failed to access save directory: \(error)")
        }
    }
    
    func testUI_FileNamingIntegration() throws {
        // Given
        let testFormats: [VideoFormat] = [.mp4, .mov]
        
        // When/Then - Test file naming for different formats
        for format in testFormats {
            let fileName = TestUtils.testFileName(for: format)
            
            XCTAssertTrue(fileName.hasSuffix(".\(format.rawValue)"))
            XCTAssertTrue(fileName.contains("test-recording-"))
            XCTAssertFalse(fileName.isEmpty)
        }
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testUI_ErrorHandlingIntegration() throws {
        // Given
        var capturedError: RecordingError?
        
        // When - Simulate various error conditions
        let errorTypes: [RecordingError] = [
            .audioFileCreationFailed("Test error"),
            .videoWriterCreationFailed("Test error"),
            .directoryCreationFailed("Test error"),
            .screenCaptureSetupFailed("Test error")
        ]
        
        // Then - All errors should have descriptions
        for error in errorTypes {
            capturedError = error
            XCTAssertNotNil(capturedError?.errorDescription)
            XCTAssertFalse(capturedError?.errorDescription?.isEmpty ?? true)
        }
    }
    
    func testUI_InvalidInputHandling() throws {
        // Given
        let scContext = SCContext()
        
        // When - Test with invalid UI inputs
        let invalidInputs: [[String: Any]] = [
            ["width": -100, "height": -100],
            ["width": "invalid", "height": "invalid"],
            ["x": Double.infinity, "y": Double.nan],
            [:]
        ]
        
        // Then - Should handle gracefully with defaults
        for invalidInput in invalidInputs {
            let size = scContext.getRecordingSize(area: invalidInput)
            XCTAssertEqual(size.width, 1920.0) // Default width
            XCTAssertEqual(size.height, 1080.0) // Default height
        }
    }
    
    // MARK: - Settings Validation Integration Tests
    
    func testUI_SettingsValidationIntegration() throws {
        // Given
        let originalFrameRate = settingsManager.frameRate
        let originalVideoQuality = settingsManager.videoQuality
        
        // When - Set invalid values that UI might accidentally send
        settingsManager.frameRate = -5
        settingsManager.videoQuality = 2.5 // Above max
        
        settingsManager.validateSettings()
        
        // Then - Should be corrected
        XCTAssertEqual(settingsManager.frameRate, 60) // Default
        XCTAssertEqual(settingsManager.videoQuality, 1.0) // Max allowed
        
        // Cleanup
        settingsManager.frameRate = originalFrameRate
        settingsManager.videoQuality = originalVideoQuality
    }
    
    func testUI_FrameRateValidation() throws {
        // Given
        let validFrameRates = [24, 30, 60, 120]
        let originalFrameRate = settingsManager.frameRate
        
        // When/Then - Test valid frame rates
        for frameRate in validFrameRates {
            settingsManager.frameRate = frameRate
            settingsManager.validateSettings()
            XCTAssertEqual(settingsManager.frameRate, frameRate)
        }
        
        // Test invalid frame rates
        let invalidFrameRates = [0, -10, 500]
        for invalidFrameRate in invalidFrameRates {
            settingsManager.frameRate = invalidFrameRate
            settingsManager.validateSettings()
            XCTAssertEqual(settingsManager.frameRate, 60) // Should default to 60
        }
        
        // Cleanup
        settingsManager.frameRate = originalFrameRate
    }
    
    // MARK: - Component Interaction Tests
    
    func testUI_SettingsToRecordEngineIntegration() throws {
        // Given
        let recordEngine = RecordEngine()
        let originalAudioFormat = settingsManager.audioFormat
        
        // When - Change audio format in settings
        settingsManager.audioFormat = .mp3
        let mp3Settings = recordEngine.getAudioSettings()
        
        settingsManager.audioFormat = .aac
        let aacSettings = recordEngine.getAudioSettings()
        
        // Then - RecordEngine should reflect settings changes
        XCTAssertNotEqual(mp3Settings["AVFormatIDKey"] as? UInt32, aacSettings["AVFormatIDKey"] as? UInt32)
        
        // Cleanup
        settingsManager.audioFormat = originalAudioFormat
    }
    
    func testUI_SettingsToSCContextIntegration() async throws {
        // Given
        let scContext = SCContext()
        
        // When - Use settings for recording area
        let size = scContext.getRecordingSize(area: [
            "width": settingsManager.areaWidth,
            "height": settingsManager.areaHeight
        ])
        
        // Then - Should use settings values
        XCTAssertEqual(size.width, CGFloat(settingsManager.areaWidth))
        XCTAssertEqual(size.height, CGFloat(settingsManager.areaHeight))
    }
    
    // MARK: - Performance Integration Tests
    
    func testUI_SettingsPerformanceWithMultipleChanges() throws {
        // Given
        let originalValues = (
            frameRate: settingsManager.frameRate,
            videoQuality: settingsManager.videoQuality,
            audioFormat: settingsManager.audioFormat,
            videoFormat: settingsManager.videoFormat
        )
        
        // When - Simulate rapid UI changes
        measure {
            for i in 0..<100 {
                settingsManager.frameRate = i % 2 == 0 ? 30 : 60
                settingsManager.videoQuality = i % 2 == 0 ? 0.5 : 1.0
                settingsManager.audioFormat = i % 2 == 0 ? .aac : .mp3
                settingsManager.videoFormat = i % 2 == 0 ? .mp4 : .mov
            }
        }
        
        // Cleanup
        settingsManager.frameRate = originalValues.frameRate
        settingsManager.videoQuality = originalValues.videoQuality
        settingsManager.audioFormat = originalValues.audioFormat
        settingsManager.videoFormat = originalValues.videoFormat
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testUI_TypicalUserWorkflow() throws {
        // Given - Simulate a typical user session
        let originalSettings = (
            frameRate: settingsManager.frameRate,
            videoQuality: settingsManager.videoQuality,
            audioFormat: settingsManager.audioFormat,
            videoFormat: settingsManager.videoFormat,
            areaWidth: settingsManager.areaWidth,
            areaHeight: settingsManager.areaHeight
        )
        
        // When - User changes settings for recording
        settingsManager.frameRate = 60
        settingsManager.videoQuality = 0.8
        settingsManager.audioFormat = .aac
        settingsManager.videoFormat = .mp4
        settingsManager.areaWidth = 1920
        settingsManager.areaHeight = 1080
        
        // Validate settings
        settingsManager.validateSettings()
        
        // Create recording components
        let recordEngine = RecordEngine()
        let scContext = SCContext()
        
        // Then - All components should work together
        let audioSettings = recordEngine.getAudioSettings()
        let recordingSize = scContext.getRecordingSize(area: [
            "width": settingsManager.areaWidth,
            "height": settingsManager.areaHeight
        ])
        
        XCTAssertFalse(audioSettings.isEmpty)
        XCTAssertEqual(recordingSize.width, 1920.0)
        XCTAssertEqual(recordingSize.height, 1080.0)
        XCTAssertEqual(settingsManager.frameRate, 60)
        XCTAssertEqual(settingsManager.videoQuality, 0.8)
        
        // Cleanup
        settingsManager.frameRate = originalSettings.frameRate
        settingsManager.videoQuality = originalSettings.videoQuality
        settingsManager.audioFormat = originalSettings.audioFormat
        settingsManager.videoFormat = originalSettings.videoFormat
        settingsManager.areaWidth = originalSettings.areaWidth
        settingsManager.areaHeight = originalSettings.areaHeight
    }
} 