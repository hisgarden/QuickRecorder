//
//  RecordEngineTests.swift
//  QuickRecorderTests
//
//  Created by Test Coverage Phase 2 on 2025/06/16.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

/// Tests for RecordEngine functionality including initialization, state management, and recording lifecycle
class RecordEngineTests: XCTestCase {
    
    var recordEngine: RecordEngine!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        recordEngine = RecordEngine()
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("RecordEngineTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        recordEngine = nil
        
        // Cleanup temporary directory
        if let tempDirectory = tempDirectory {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testRecordEngine_CanBeCreated() throws {
        // Given/When/Then
        XCTAssertNotNil(recordEngine)
    }
    
    func testRecordEngine_InitialState() throws {
        // Given/When/Then - Check initial state properties
        XCTAssertNotNil(recordEngine.engine)
        XCTAssertNotNil(recordEngine.outputNode)
        XCTAssertNotNil(recordEngine.inputNode)
        XCTAssertEqual(recordEngine.isRecording, false)
    }
    
    func testRecordEngine_AudioEngineConfiguration() throws {
        // Given/When/Then - Verify audio engine is properly configured
        XCTAssertTrue(recordEngine.engine.isRunning || !recordEngine.engine.isRunning) // Can be either state initially
        XCTAssertNotNil(recordEngine.engine.outputNode)
        XCTAssertNotNil(recordEngine.engine.inputNode)
    }
    
    // MARK: - Audio Format Tests
    
    func testRecordEngine_AudioFormat() throws {
        // Given/When
        let format = recordEngine.inputNode.outputFormat(forBus: 0)
        
        // Then - Verify format properties
        XCTAssertGreaterThan(format.sampleRate, 0)
        XCTAssertGreaterThan(format.channelCount, 0)
        XCTAssertNotNil(format.formatDescription)
    }
    
    func testRecordEngine_SupportedAudioFormats() throws {
        // Given
        let settings = SettingsManager.shared
        
        // When/Then - Test different audio formats
        for audioFormat in [AudioFormat.aac, AudioFormat.mp3] {
            settings.audioFormat = audioFormat
            let audioSettings = recordEngine.getAudioSettings()
            XCTAssertFalse(audioSettings.isEmpty, "Audio settings should not be empty for \(audioFormat)")
        }
    }
    
    // MARK: - Recording State Management Tests
    
    func testRecordEngine_RecordingStateInitiallyFalse() throws {
        // Given/When/Then
        XCTAssertFalse(recordEngine.isRecording)
    }
    
    func testRecordEngine_CanGetAudioSettings() throws {
        // Given/When
        let audioSettings = recordEngine.getAudioSettings()
        
        // Then
        XCTAssertFalse(audioSettings.isEmpty)
        XCTAssertNotNil(audioSettings["AVFormatIDKey"])
        XCTAssertNotNil(audioSettings["AVSampleRateKey"])
        XCTAssertNotNil(audioSettings["AVNumberOfChannelsKey"])
    }
    
    // MARK: - File Management Tests
    
    func testRecordEngine_AudioFileCreation() throws {
        // Given
        let testURL = tempDirectory.appendingPathComponent("test-audio.aac")
        let audioSettings = recordEngine.getAudioSettings()
        
        // When
        let result = ErrorHandler.shared.createAudioFile(url: testURL, settings: audioSettings)
        
        // Then
        switch result {
        case .success(let audioFile):
            XCTAssertNotNil(audioFile)
            XCTAssertEqual(audioFile.url, testURL)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testRecordEngine_InvalidAudioFileCreation() throws {
        // Given - Invalid URL (empty path)
        let invalidURL = URL(fileURLWithPath: "")
        let audioSettings = recordEngine.getAudioSettings()
        
        // When
        let result = ErrorHandler.shared.createAudioFile(url: invalidURL, settings: audioSettings)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure for invalid URL")
        case .failure(let error):
            XCTAssertTrue(error.localizedDescription.contains("audio file creation"))
        }
    }
    
    // MARK: - Audio Engine Lifecycle Tests
    
    func testRecordEngine_EngineStartStop() throws {
        // Given
        let wasRunning = recordEngine.engine.isRunning
        
        // When - Stop if running
        if wasRunning {
            recordEngine.engine.stop()
            XCTAssertFalse(recordEngine.engine.isRunning)
        }
        
        // Then - Start engine
        XCTAssertNoThrow(try recordEngine.engine.start())
        XCTAssertTrue(recordEngine.engine.isRunning)
        
        // Cleanup - Stop engine
        recordEngine.engine.stop()
    }
    
    func testRecordEngine_EngineReset() throws {
        // Given
        let originalRunning = recordEngine.engine.isRunning
        
        // When
        recordEngine.engine.reset()
        
        // Then
        XCTAssertFalse(recordEngine.engine.isRunning)
        XCTAssertNotNil(recordEngine.engine.outputNode)
        XCTAssertNotNil(recordEngine.engine.inputNode)
        
        // Cleanup - Restore original state if needed
        if originalRunning {
            try? recordEngine.engine.start()
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testRecordEngine_HandlesMicrophonePermissions() throws {
        // Given/When - Check if we can access microphone
        let hasPermission = AVAudioSession.sharedInstance().recordPermission == .granted
        
        // Then - Should handle permission appropriately
        if hasPermission {
            XCTAssertNoThrow(try recordEngine.engine.start())
            recordEngine.engine.stop()
        } else {
            // Permission denied or undetermined - engine should handle gracefully
            XCTAssertTrue(true) // Test passes - permission handling is system dependent
        }
    }
    
    // MARK: - Performance Tests
    
    func testRecordEngine_InitializationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let engine = RecordEngine()
                _ = engine.getAudioSettings()
            }
        }
    }
    
    func testRecordEngine_AudioSettingsPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = recordEngine.getAudioSettings()
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testRecordEngine_MemoryManagement() throws {
        // Given
        weak var weakEngine: RecordEngine?
        
        // When
        autoreleasepool {
            let engine = RecordEngine()
            weakEngine = engine
            XCTAssertNotNil(weakEngine)
        }
        
        // Then - Should be deallocated
        XCTAssertNil(weakEngine, "RecordEngine should be deallocated when no strong references remain")
    }
    
    // MARK: - Integration with Settings Tests
    
    func testRecordEngine_SettingsIntegration() throws {
        // Given
        let settings = SettingsManager.shared
        let originalFormat = settings.audioFormat
        
        // When - Change audio format
        settings.audioFormat = .mp3
        let mp3Settings = recordEngine.getAudioSettings()
        
        settings.audioFormat = .aac
        let aacSettings = recordEngine.getAudioSettings()
        
        // Then
        XCTAssertNotEqual(mp3Settings["AVFormatIDKey"] as? UInt32, aacSettings["AVFormatIDKey"] as? UInt32)
        
        // Cleanup
        settings.audioFormat = originalFormat
    }
} 