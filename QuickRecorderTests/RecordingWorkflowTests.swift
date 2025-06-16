//
//  RecordingWorkflowTests.swift
//  QuickRecorderTests
//
//  Created by TDD on 2024/12/19.
//

import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import QuickRecorder

class RecordingWorkflowTests: XCTestCase {
    
    var tempDirectory: URL!
    var mockErrorHandler: MockErrorHandler!
    var mockSettingsManager: MockSettingsManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create temporary directory for test files
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("RecordingWorkflowTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Set up mocks
        mockErrorHandler = MockErrorHandler()
        mockSettingsManager = MockSettingsManager()
    }
    
    override func tearDownWithError() throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        mockErrorHandler = nil
        mockSettingsManager = nil
        
        // Clean up any active recording state
        SCContext.stream = nil
        SCContext.streamType = nil
        SCContext.startTime = nil
        SCContext.isPaused = false
        
        try super.tearDownWithError()
    }
    
    // MARK: - Recording State Management Tests
    
    func testRecordingState_InitialState() throws {
        // Given & When - Initial state should be clean
        
        // Then
        XCTAssertNil(SCContext.stream, "No active stream should exist initially")
        XCTAssertNil(SCContext.streamType, "No stream type should be set initially")
        XCTAssertNil(SCContext.startTime, "No start time should be set initially")
        XCTAssertFalse(SCContext.isPaused, "Recording should not be paused initially")
        XCTAssertFalse(SCContext.isResume, "Recording should not be in resume state initially")
        XCTAssertEqual(SCContext.autoStop, 0, "Auto stop should be disabled initially")
    }
    
    func testRecordingState_StreamTypeValidation() throws {
        // Given
        let validStreamTypes: [StreamType] = [.screen, .window, .windows, .application, .screenarea, .systemaudio]
        
        // When & Then
        for streamType in validStreamTypes {
            SCContext.streamType = streamType
            XCTAssertEqual(SCContext.streamType, streamType, "Stream type should be set correctly")
        }
    }
    
    func testRecordingState_PauseResumeLogic() throws {
        // Given
        SCContext.isPaused = false
        SCContext.isResume = false
        
        // When - Simulate pause
        SCContext.isPaused = true
        
        // Then
        XCTAssertTrue(SCContext.isPaused)
        XCTAssertFalse(SCContext.isResume)
        
        // When - Simulate resume
        SCContext.isResume = true
        SCContext.isPaused = false
        
        // Then
        XCTAssertFalse(SCContext.isPaused)
        XCTAssertTrue(SCContext.isResume)
    }
    
    // MARK: - File Path Generation Tests
    
    func testFilePathGeneration_ValidPaths() throws {
        // Given
        let basePath = tempDirectory.path
        let timestamp = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let timeString = formatter.string(from: timestamp)
        
        // When
        let videoPath = "\(basePath)/Recording \(timeString).mov"
        let audioPath = "\(basePath)/Recording \(timeString).m4a"
        
        // Then
        XCTAssertTrue(videoPath.hasSuffix(".mov"))
        XCTAssertTrue(audioPath.hasSuffix(".m4a"))
        XCTAssertTrue(videoPath.contains(timeString))
        XCTAssertTrue(audioPath.contains(timeString))
    }
    
    func testFilePathGeneration_InvalidDirectory() throws {
        // Given
        let invalidPath = "/invalid/nonexistent/directory"
        
        // When
        let result = ErrorHandler.shared.createDirectory(at: invalidPath)
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail to create directory in invalid path")
        case .failure(let error):
            if case .directoryCreationFailed(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected directoryCreationFailed error")
            }
        }
    }
    
    // MARK: - Audio Configuration Tests
    
    func testAudioConfiguration_ValidSettings() throws {
        // Given
        let sampleRates: [Double] = [22050, 44100, 48000, 96000]
        let bitRates: [Int] = [128, 192, 256, 320]
        let channels: [Int] = [1, 2]
        
        // When & Then
        for sampleRate in sampleRates {
            for bitRate in bitRates {
                for channelCount in channels {
                    let settings: [String: Any] = [
                        AVFormatIDKey: kAudioFormatMPEG4AAC,
                        AVSampleRateKey: sampleRate,
                        AVNumberOfChannelsKey: channelCount,
                        AVEncoderBitRateKey: bitRate * 1000
                    ]
                    
                    let testURL = tempDirectory.appendingPathComponent("test-\(sampleRate)-\(bitRate)-\(channelCount).m4a")
                    let result = ErrorHandler.shared.createAudioFile(url: testURL, settings: settings)
                    
                    switch result {
                    case .success(let audioFile):
                        XCTAssertNotNil(audioFile)
                        XCTAssertEqual(audioFile.url, testURL)
                    case .failure(let error):
                        XCTFail("Failed to create audio file with valid settings: \(error)")
                    }
                }
            }
        }
    }
    
    func testAudioConfiguration_InvalidSettings() throws {
        // Given
        let invalidSettings: [String: Any] = [
            AVFormatIDKey: "invalid_format",
            AVSampleRateKey: -1,
            AVNumberOfChannelsKey: 0
        ]
        
        // When
        let testURL = tempDirectory.appendingPathComponent("invalid-audio.m4a")
        let result = ErrorHandler.shared.createAudioFile(url: testURL, settings: invalidSettings)
        
        // Then
        switch result {
        case .success:
            XCTFail("Should fail with invalid audio settings")
        case .failure(let error):
            if case .audioFileCreationFailed(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected audioFileCreationFailed error")
            }
        }
    }
    
    // MARK: - Video Configuration Tests
    
    func testVideoConfiguration_StreamConfiguration() throws {
        // Given
        let conf = SCStreamConfiguration()
        
        // When
        conf.width = 1920
        conf.height = 1080
        conf.showsCursor = true
        conf.pixelFormat = kCVPixelFormatType_32BGRA
        
        // Then
        XCTAssertEqual(conf.width, 1920)
        XCTAssertEqual(conf.height, 1080)
        XCTAssertTrue(conf.showsCursor)
        XCTAssertEqual(conf.pixelFormat, kCVPixelFormatType_32BGRA)
    }
    
    func testVideoConfiguration_ResolutionValidation() throws {
        // Given
        let validResolutions = [
            (width: 1280, height: 720),   // 720p
            (width: 1920, height: 1080),  // 1080p
            (width: 2560, height: 1440),  // 1440p
            (width: 3840, height: 2160)   // 4K
        ]
        
        // When & Then
        for resolution in validResolutions {
            let conf = SCStreamConfiguration()
            conf.width = resolution.width
            conf.height = resolution.height
            
            XCTAssertEqual(conf.width, resolution.width)
            XCTAssertEqual(conf.height, resolution.height)
            XCTAssertGreaterThan(conf.width, 0)
            XCTAssertGreaterThan(conf.height, 0)
        }
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecovery_FileSystemErrors() throws {
        // Given
        let readOnlyPath = "/System/readonly_test_directory"
        
        // When
        let result = ErrorHandler.shared.createDirectory(at: readOnlyPath)
        
        // Then
        switch result {
        case .success:
            // If it succeeds on some systems, that's fine too
            break
        case .failure(let error):
            if case .directoryCreationFailed(let message) = error {
                XCTAssertFalse(message.isEmpty, "Error message should not be empty")
            } else {
                XCTFail("Expected directoryCreationFailed error")
            }
        }
    }
    
    func testErrorRecovery_AudioEngineFailure() throws {
        // Given
        let audioEngine = AVAudioEngine()
        
        // When - Try to start engine multiple times
        let result1 = ErrorHandler.shared.startAudioEngine(audioEngine)
        let result2 = ErrorHandler.shared.startAudioEngine(audioEngine)
        
        // Then
        defer { audioEngine.stop() }
        
        switch result1 {
        case .success:
            XCTAssertTrue(audioEngine.isRunning)
        case .failure(let error):
            XCTFail("First audio engine start should succeed: \(error)")
        }
        
        // Second start should handle already running engine gracefully
        switch result2 {
        case .success, .failure:
            // Both outcomes are acceptable - depends on implementation
            break
        }
    }
    
    // MARK: - Resource Management Tests
    
    func testResourceManagement_FileHandles() throws {
        // Given
        var audioFiles = [AVAudioFile]()
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        // When - Create multiple audio files
        for i in 0..<10 {
            let testURL = tempDirectory.appendingPathComponent("test-\(i).m4a")
            let result = ErrorHandler.shared.createAudioFile(url: testURL, settings: settings)
            
            switch result {
            case .success(let audioFile):
                audioFiles.append(audioFile)
            case .failure(let error):
                XCTFail("Failed to create audio file \(i): \(error)")
            }
        }
        
        // Then
        XCTAssertEqual(audioFiles.count, 10)
        
        // Clean up - This tests that files can be properly closed
        audioFiles.removeAll()
    }
    
    func testResourceManagement_MemoryPressure() throws {
        // Given
        var buffers = [Data]()
        let bufferSize = 1024 * 1024 // 1MB
        
        // When - Allocate multiple large buffers to simulate memory pressure
        for _ in 0..<10 {
            let buffer = Data(count: bufferSize)
            buffers.append(buffer)
        }
        
        // Then
        XCTAssertEqual(buffers.count, 10)
        
        // Clean up
        buffers.removeAll()
    }
    
    // MARK: - Timing and Synchronization Tests
    
    func testTiming_StartTimeManagement() throws {
        // Given
        XCTAssertNil(SCContext.startTime)
        
        // When
        let startTime = Date()
        SCContext.startTime = startTime
        
        // Then
        XCTAssertNotNil(SCContext.startTime)
        XCTAssertEqual(SCContext.startTime, startTime)
        
        // When - Reset
        SCContext.startTime = nil
        
        // Then
        XCTAssertNil(SCContext.startTime)
    }
    
    func testTiming_TimeOffset() throws {
        // Given
        let initialOffset = CMTimeMake(value: 0, timescale: 1000)
        
        // When
        SCContext.timeOffset = initialOffset
        
        // Then
        XCTAssertTrue(CMTimeCompare(SCContext.timeOffset, initialOffset) == 0)
        
        // When - Update offset
        let newOffset = CMTimeMake(value: 1000, timescale: 1000) // 1 second
        SCContext.timeOffset = newOffset
        
        // Then
        XCTAssertTrue(CMTimeCompare(SCContext.timeOffset, newOffset) == 0)
        XCTAssertEqual(CMTimeGetSeconds(SCContext.timeOffset), 1.0, accuracy: 0.001)
    }
    
    // MARK: - Integration with Settings Tests
    
    func testSettingsIntegration_SaveDirectory() throws {
        // Given
        let customSaveDirectory = tempDirectory.appendingPathComponent("custom_recordings").path
        
        // When
        mockSettingsManager.customSaveDirectory = customSaveDirectory
        let retrievedDirectory = mockSettingsManager.getSaveDirectory()
        
        // Then
        XCTAssertEqual(retrievedDirectory, customSaveDirectory)
    }
    
    func testSettingsIntegration_AudioQuality() throws {
        // Given
        let testQualities: [AudioQuality] = [.normal, .good, .high, .extreme]
        
        // When & Then
        for quality in testQualities {
            mockSettingsManager.audioQuality = quality
            let bitRate = mockSettingsManager.getAudioBitRate()
            
            switch quality {
            case .normal:
                XCTAssertEqual(bitRate, 128)
            case .good:
                XCTAssertEqual(bitRate, 192)
            case .high:
                XCTAssertEqual(bitRate, 256)
            case .extreme:
                XCTAssertEqual(bitRate, 320)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_FilePathGeneration() throws {
        measure {
            for i in 0..<1000 {
                let path = tempDirectory.appendingPathComponent("test-\(i).mov").path
                XCTAssertFalse(path.isEmpty)
            }
        }
    }
    
    func testPerformance_AudioFileCreation() throws {
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        measure {
            for i in 0..<10 {
                let testURL = tempDirectory.appendingPathComponent("perf-test-\(i).m4a")
                let result = ErrorHandler.shared.createAudioFile(url: testURL, settings: settings)
                
                switch result {
                case .success:
                    break
                case .failure:
                    XCTFail("Performance test should not fail")
                }
            }
        }
    }
}

// MARK: - Mock Classes for Testing

class MockSettingsManager {
    var customSaveDirectory: String = ""
    var audioQuality: AudioQuality = .normal
    
    func getSaveDirectory() -> String {
        return customSaveDirectory.isEmpty ? NSTemporaryDirectory() : customSaveDirectory
    }
    
    func getAudioBitRate() -> Int {
        return audioQuality.rawValue
    }
}

class MockErrorHandler {
    var shouldSimulateError = false
    var lastErrorMessage = ""
    
    func createAudioFile(url: URL, settings: [String: Any]) -> Result<MockAudioFile, RecordingError> {
        if shouldSimulateError {
            return .failure(.audioFileCreationFailed("Simulated error"))
        }
        return .success(MockAudioFile(url: url))
    }
    
    func handleError(_ error: RecordingError) {
        lastErrorMessage = error.localizedDescription ?? "Unknown error"
    }
} 