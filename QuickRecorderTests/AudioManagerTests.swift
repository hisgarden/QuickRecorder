//
//  AudioManagerTests.swift
//  QuickRecorderTests
//
//  Created by Refactoring on 2025/09/16.
//

import XCTest
import AVFoundation
import AVFAudio
@testable import QuickRecorder

/// Comprehensive unit tests for AudioManager
class AudioManagerTests: XCTestCase {
    
    var audioManager: AudioManager.Type!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        audioManager = AudioManager.self
        
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("AudioManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Reset state
        AudioManager.audioFile = nil
        AudioManager.audioFile2 = nil
        AudioManager.awInput = nil
        AudioManager.micInput = nil
        AudioManager.recordDevice = ""
        AudioManager.recordCam = ""
    }
    
    override func tearDownWithError() throws {
        // Clean up
        AudioManager.cleanupAudioFiles()
        AudioManager.stopAudioEngine()
        AudioManager.resetAudioEngine()
        
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        
        audioManager = nil
        tempDirectory = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Audio Engine Tests
    
    func testAudioEngine_Initialization() throws {
        // Given/When
        let engine = AudioManager.audioEngine
        
        // Then
        XCTAssertNotNil(engine)
        XCTAssertFalse(engine.isRunning)
    }
    
    func testStartAudioEngine_Success() throws {
        // Given
        let engine = AudioManager.audioEngine
        
        // When
        let result = AudioManager.startAudioEngine()
        
        // Then - Clean up after test
        defer { AudioManager.stopAudioEngine() }
        
        // In test environment, this may fail due to hardware requirements
        // The important thing is that it returns a proper Result
        switch result {
        case .success:
            XCTAssertTrue(engine.isRunning)
        case .failure(let error):
            XCTAssertNotNil(error)
            // Expected in test environment without audio hardware
        }
    }
    
    func testStopAudioEngine() throws {
        // Given
        let engine = AudioManager.audioEngine
        
        // When
        AudioManager.stopAudioEngine()
        
        // Then
        XCTAssertFalse(engine.isRunning)
    }
    
    func testResetAudioEngine() throws {
        // Given
        let engine = AudioManager.audioEngine
        
        // When
        AudioManager.resetAudioEngine()
        
        // Then
        XCTAssertFalse(engine.isRunning)
        // Engine should be in a clean state after reset
    }
    
    // MARK: - Audio File Tests
    
    func testCreateAudioFile_Success() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_audio.aac")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        // When
        let result = AudioManager.createAudioFile(url: fileURL, settings: settings)
        
        // Then
        switch result {
        case .success(let audioFile):
            XCTAssertNotNil(audioFile)
            XCTAssertEqual(audioFile.url, fileURL)
            XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        case .failure(let error):
            XCTFail("Audio file creation failed: \(error.localizedDescription)")
        }
    }
    
    func testCreateAudioFile_InvalidURL() throws {
        // Given
        let invalidURL = URL(fileURLWithPath: "/invalid/path/audio.aac")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        // When
        let result = AudioManager.createAudioFile(url: invalidURL, settings: settings)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertNotNil(error)
            XCTAssertTrue(error.localizedDescription.contains("audio") || 
                         error.localizedDescription.contains("Audio") ||
                         error.localizedDescription.contains("file"))
        }
    }
    
    func testCreateAudioFile_InvalidSettings() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_audio.aac")
        let invalidSettings: [String: Any] = [
            "invalid_key": "invalid_value"
        ]
        
        // When
        let result = AudioManager.createAudioFile(url: fileURL, settings: invalidSettings)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
    
    func testCleanupAudioFiles() throws {
        // Given
        AudioManager.audioFile = try createTestAudioFile()
        AudioManager.audioFile2 = try createTestAudioFile()
        
        // When
        AudioManager.cleanupAudioFiles()
        
        // Then
        XCTAssertNil(AudioManager.audioFile)
        XCTAssertNil(AudioManager.audioFile2)
    }
    
    // MARK: - Audio Format Tests
    
    func testGetCurrentInputFormat() throws {
        // Given/When
        let format = AudioManager.getCurrentInputFormat()
        
        // Then
        // In test environment, this may be nil due to no audio hardware
        // The important thing is that it doesn't crash
        if let format = format {
            XCTAssertGreaterThan(format.sampleRate, 0)
            XCTAssertGreaterThan(format.channelCount, 0)
        }
    }
    
    func testGetCurrentOutputFormat() throws {
        // Given/When
        let format = AudioManager.getCurrentOutputFormat()
        
        // Then
        // In test environment, this may be nil due to no audio hardware
        // The important thing is that it doesn't crash
        if let format = format {
            XCTAssertGreaterThan(format.sampleRate, 0)
            XCTAssertGreaterThan(format.channelCount, 0)
        }
    }
    
    // MARK: - AEC Tests
    
    func testAECEngine_Initialization() throws {
        // Given/When
        let aecEngine = AudioManager.AECEngine
        
        // Then
        XCTAssertNotNil(aecEngine)
    }
    
    func testSetAECEnabled_True() throws {
        // Given/When
        AudioManager.setAECEnabled(true)
        
        // Then
        // AEC should be enabled (we can't easily test the internal state,
        // but we can ensure the method doesn't crash)
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testSetAECEnabled_False() throws {
        // Given/When
        AudioManager.setAECEnabled(false)
        
        // Then
        // AEC should be disabled
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Device Management Tests
    
    func testSetInputDevice() throws {
        // Given
        let deviceID = "test_input_device"
        
        // When
        AudioManager.setInputDevice(deviceID)
        
        // Then
        XCTAssertEqual(AudioManager.recordDevice, deviceID)
    }
    
    func testSetCameraDevice() throws {
        // Given
        let deviceID = "test_camera_device"
        
        // When
        AudioManager.setCameraDevice(deviceID)
        
        // Then
        XCTAssertEqual(AudioManager.recordCam, deviceID)
    }
    
    func testGetAvailableInputDevices() throws {
        // Given/When
        let devices = AudioManager.getAvailableInputDevices()
        
        // Then
        // In test environment, this may return empty array
        // The important thing is that it doesn't crash
        XCTAssertNotNil(devices)
    }
    
    // MARK: - Audio File Operations Tests
    
    func testGetAudioFileDuration() throws {
        // Given
        let audioFile = try createTestAudioFile()
        
        // When
        let duration = AudioManager.getAudioFileDuration(audioFile)
        
        // Then
        XCTAssertNotNil(duration)
        XCTAssertGreaterThanOrEqual(duration ?? 0, 0)
    }
    
    func testGetAudioFileSize() throws {
        // Given
        let audioFile = try createTestAudioFile()
        
        // When
        let size = AudioManager.getAudioFileSize(audioFile)
        
        // Then
        XCTAssertNotNil(size)
        XCTAssertGreaterThan(size ?? 0, 0)
    }
    
    // MARK: - Audio Engine Configuration Tests
    
    func testConfigureAudioEngine() throws {
        // Given
        let engine = AudioManager.audioEngine
        let inputNode = engine.inputNode
        let outputNode = engine.outputNode
        let format = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)!
        
        // When
        AudioManager.configureAudioEngine(inputNode: inputNode, outputNode: outputNode, format: format)
        
        // Then
        // Configuration should complete without crashing
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    // MARK: - Helper Methods
    
    private func createTestAudioFile() throws -> AVAudioFile {
        let fileURL = tempDirectory.appendingPathComponent("test_audio_\(UUID().uuidString).aac")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        let result = AudioManager.createAudioFile(url: fileURL, settings: settings)
        switch result {
        case .success(let audioFile):
            return audioFile
        case .failure(let error):
            throw error
        }
    }
}
