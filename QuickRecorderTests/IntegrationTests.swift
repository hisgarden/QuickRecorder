//
//  IntegrationTests.swift
//  QuickRecorderTests
//
//  Created by TDD on 2024/12/19.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

class IntegrationTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    var settingsManager: SettingsManager!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        errorHandler = ErrorHandler.shared
        settingsManager = SettingsManager.shared
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("QuickRecorderIntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        errorHandler = nil
        settingsManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Integration Tests
    
    func testErrorHandlerWithSettingsManager_SaveDirectoryCreation() throws {
        // Given
        let customSaveDirectory = tempDirectory.appendingPathComponent("custom-save-dir").path
        settingsManager.saveDirectory = customSaveDirectory
        
        // When
        let directoryCreationResult = errorHandler.createDirectory(at: customSaveDirectory)
        let retrievedSaveDirectory = settingsManager.getSaveDirectory()
        
        // Then
        switch directoryCreationResult {
        case .success:
            XCTAssertEqual(retrievedSaveDirectory, customSaveDirectory)
            XCTAssertTrue(FileManager.default.fileExists(atPath: customSaveDirectory))
        case .failure(let error):
            XCTFail("Expected directory creation to succeed: \(error)")
        }
    }
    
    func testErrorHandlerWithSettingsManager_AudioFileWithUserSettings() throws {
        // Given - Configure audio settings
        settingsManager.audioQuality = 2 // High quality
        settingsManager.recordWASAPI = true
        settingsManager.recordMic = true
        settingsManager.micVolume = 0.8
        settingsManager.systemAudioVolume = 0.9
        
        let audioFileURL = tempDirectory.appendingPathComponent("test-recording.m4a")
        
        // Configure audio settings based on user preferences
        var audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVNumberOfChannelsKey: settingsManager.recordMic ? 2 : 1,
            AVSampleRateKey: settingsManager.audioQuality == 2 ? 48000 : 44100
        ]
        
        // When
        let audioFileResult = errorHandler.createAudioFile(url: audioFileURL, settings: audioSettings)
        
        // Then
        switch audioFileResult {
        case .success(let audioFile):
            XCTAssertNotNil(audioFile)
            XCTAssertEqual(audioFile.url, audioFileURL)
            
            // Verify audio settings match user preferences
            XCTAssertTrue(settingsManager.recordWASAPI)
            XCTAssertTrue(settingsManager.recordMic)
            XCTAssertEqual(settingsManager.micVolume, 0.8, accuracy: 0.001)
            XCTAssertEqual(settingsManager.systemAudioVolume, 0.9, accuracy: 0.001)
            
        case .failure(let error):
            XCTFail("Expected audio file creation to succeed: \(error)")
        }
    }
    
    func testErrorHandlerWithSettingsManager_VideoSettingsValidation() throws {
        // Given - Set video recording preferences
        settingsManager.videoFormat = 1 // MP4
        settingsManager.videoQuality = 2 // High
        settingsManager.frameRate = 60
        settingsManager.encoder = true
        settingsManager.showBorder = true
        settingsManager.borderWidth = 3.0
        
        // When - Validate that all settings are consistently applied
        let videoFormat = settingsManager.videoFormat
        let videoQuality = settingsManager.videoQuality
        let frameRate = settingsManager.frameRate
        let useEncoder = settingsManager.encoder
        let showBorder = settingsManager.showBorder
        let borderWidth = settingsManager.borderWidth
        
        // Then - All settings should be as configured
        XCTAssertEqual(videoFormat, 1)
        XCTAssertEqual(videoQuality, 2)
        XCTAssertEqual(frameRate, 60)
        XCTAssertTrue(useEncoder)
        XCTAssertTrue(showBorder)
        XCTAssertEqual(borderWidth, 3.0, accuracy: 0.001)
    }
    
    func testErrorHandlerWithSettingsManager_FailureRecovery() throws {
        // Given - Set invalid save directory
        let invalidSaveDirectory = "/invalid/path/that/does/not/exist"
        settingsManager.saveDirectory = invalidSaveDirectory
        
        // When - Try to create directory and get save directory
        let directoryCreationResult = errorHandler.createDirectory(at: invalidSaveDirectory)
        let fallbackSaveDirectory = settingsManager.getSaveDirectory()
        
        // Then - Should handle failure gracefully
        switch directoryCreationResult {
        case .success:
            XCTFail("Expected directory creation to fail for invalid path")
        case .failure(let error):
            // Verify error is properly handled
            if case .directoryCreationFailed(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected directoryCreationFailed error")
            }
        }
        
        // Settings manager should fall back to Desktop
        XCTAssertTrue(fallbackSaveDirectory.hasSuffix("Desktop"))
        XCTAssertNotEqual(fallbackSaveDirectory, invalidSaveDirectory)
    }
    
    func testErrorHandlerWithSettingsManager_CompleteRecordingWorkflow() throws {
        // Given - Set up complete recording configuration
        settingsManager.hasLaunchedBefore = true
        settingsManager.autoSave = true
        settingsManager.showPreview = false
        settingsManager.frameRate = 30
        settingsManager.videoFormat = 0 // MOV
        settingsManager.videoQuality = 1 // Medium
        settingsManager.recordWASAPI = true
        settingsManager.recordMic = false
        settingsManager.audioQuality = 1 // Medium
        settingsManager.systemAudioVolume = 0.7
        settingsManager.showMouse = true
        settingsManager.recordMouse = false
        settingsManager.showBorder = false
        
        let saveDirectory = tempDirectory.appendingPathComponent("recordings").path
        settingsManager.saveDirectory = saveDirectory
        
        // When - Execute recording workflow steps
        
        // Step 1: Create save directory
        let directoryResult = errorHandler.createDirectory(at: saveDirectory)
        
        // Step 2: Create audio file if audio recording is enabled
        var audioFileResult: Result<AVAudioFile?, RecordingError> = .success(nil)
        if settingsManager.recordWASAPI || settingsManager.recordMic {
            let audioURL = URL(fileURLWithPath: saveDirectory).appendingPathComponent("recording.m4a")
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: settingsManager.audioQuality == 2 ? 48000 : 44100,
                AVNumberOfChannelsKey: settingsManager.recordMic ? 2 : 1
            ]
            audioFileResult = errorHandler.createAudioFile(url: audioURL, settings: audioSettings)
        }
        
        // Step 3: Verify all settings are properly configured
        let finalSaveDirectory = settingsManager.getSaveDirectory()
        
        // Then - Verify complete workflow
        
        // Directory creation should succeed
        switch directoryResult {
        case .success:
            XCTAssertTrue(FileManager.default.fileExists(atPath: saveDirectory))
        case .failure(let error):
            XCTFail("Directory creation failed: \(error)")
        }
        
        // Audio file creation should succeed if audio is enabled
        switch audioFileResult {
        case .success(let audioFile):
            if settingsManager.recordWASAPI || settingsManager.recordMic {
                XCTAssertNotNil(audioFile)
            } else {
                XCTAssertNil(audioFile)
            }
        case .failure(let error):
            XCTFail("Audio file creation failed: \(error)")
        }
        
        // Settings should be consistent
        XCTAssertEqual(finalSaveDirectory, saveDirectory)
        XCTAssertTrue(settingsManager.hasLaunchedBefore)
        XCTAssertTrue(settingsManager.autoSave)
        XCTAssertFalse(settingsManager.showPreview)
        XCTAssertEqual(settingsManager.frameRate, 30)
        XCTAssertEqual(settingsManager.videoFormat, 0)
        XCTAssertEqual(settingsManager.videoQuality, 1)
        XCTAssertTrue(settingsManager.recordWASAPI)
        XCTAssertFalse(settingsManager.recordMic)
        XCTAssertEqual(settingsManager.audioQuality, 1)
        XCTAssertEqual(settingsManager.systemAudioVolume, 0.7, accuracy: 0.001)
        XCTAssertTrue(settingsManager.showMouse)
        XCTAssertFalse(settingsManager.recordMouse)
        XCTAssertFalse(settingsManager.showBorder)
    }
    
    func testErrorHandlerWithSettingsManager_ThreadSafety() throws {
        // Given - Concurrent access to both managers
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 10
        
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // When - Perform concurrent operations
        for i in 0..<10 {
            queue.async {
                // Simulate concurrent settings access
                self.settingsManager.frameRate = i % 2 == 0 ? 30 : 60
                self.settingsManager.videoQuality = i % 3
                self.settingsManager.audioQuality = i % 2
                
                // Simulate concurrent error handler operations
                let testDir = self.tempDirectory.appendingPathComponent("test-\(i)").path
                let _ = self.errorHandler.createDirectory(at: testDir)
                
                expectation.fulfill()
            }
        }
        
        // Then - All operations should complete without crashes
        wait(for: [expectation], timeout: 5.0)
        
        // Verify final state is consistent
        XCTAssertTrue([30, 60].contains(settingsManager.frameRate))
        XCTAssertTrue([0, 1, 2].contains(settingsManager.videoQuality))
        XCTAssertTrue([0, 1].contains(settingsManager.audioQuality))
    }
    
    func testErrorHandlerWithSettingsManager_MemoryManagement() throws {
        // Given - Create multiple instances and references
        weak var weakErrorHandler: ErrorHandler?
        weak var weakSettingsManager: SettingsManager?
        
        autoreleasepool {
            let localErrorHandler = ErrorHandler.shared
            let localSettingsManager = SettingsManager.shared
            
            weakErrorHandler = localErrorHandler
            weakSettingsManager = localSettingsManager
            
            // Perform operations
            localSettingsManager.frameRate = 60
            let _ = localErrorHandler.createDirectory(at: self.tempDirectory.appendingPathComponent("memory-test").path)
        }
        
        // Then - Singletons should still exist (not deallocated)
        XCTAssertNotNil(weakErrorHandler)
        XCTAssertNotNil(weakSettingsManager)
        
        // Verify they're still the same instances
        XCTAssertTrue(ErrorHandler.shared === weakErrorHandler)
        XCTAssertTrue(SettingsManager.shared === weakSettingsManager)
    }
    
    func testErrorHandlerWithSettingsManager_ErrorStateConsistency() throws {
        // Given - Set up a scenario that might cause errors
        settingsManager.saveDirectory = tempDirectory.path
        
        // Create a file where we want to create a directory
        let conflictPath = tempDirectory.appendingPathComponent("conflict").path
        try "test content".write(toFile: conflictPath, atomically: true, encoding: .utf8)
        
        // When - Try to create directory at existing file location
        let result = errorHandler.createDirectory(at: conflictPath)
        
        // Then - Error should be handled without affecting settings consistency
        switch result {
        case .success:
            XCTFail("Expected directory creation to fail when file already exists")
        case .failure(let error):
            // Verify error is properly typed
            if case .directoryCreationFailed(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected directoryCreationFailed error")
            }
        }
        
        // Settings should remain unchanged after error
        XCTAssertEqual(settingsManager.getSaveDirectory(), tempDirectory.path)
    }
}

// MARK: - Performance Integration Tests

extension IntegrationTests {
    
    func testCombinedPerformance() throws {
        // This test ensures that using both managers together is performant
        measure {
            for _ in 0..<100 {
                // Simulate typical usage pattern
                _ = settingsManager.frameRate
                _ = settingsManager.videoQuality
                _ = settingsManager.audioQuality
                _ = settingsManager.getSaveDirectory()
                
                let testPath = tempDirectory.appendingPathComponent("perf-test").path
                let _ = errorHandler.createDirectory(at: testPath)
            }
        }
    }
} 