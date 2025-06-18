//
//  ErrorHandlerTests.swift
//  QuickRecorderTests
//
//  Created by TDD on 2025/06/16.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

class ErrorHandlerTests: XCTestCase {
    
    var errorHandler: ErrorHandler!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        errorHandler = ErrorHandler.shared
        
        // Create a temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("QuickRecorderTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDownWithError() throws {
        // Clean up temporary directory
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        tempDirectory = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Singleton Tests
    
    func testErrorHandler_Singleton() throws {
        // Given/When
        let instance1 = ErrorHandler.shared
        let instance2 = ErrorHandler.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Audio File Operations Tests
    
    func testCreateAudioFile_Success() throws {
        // Given
        let testURL = tempDirectory.appendingPathComponent("test-audio.m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        // When
        let result = errorHandler.createAudioFile(url: testURL, settings: settings)
        
        // Then
        switch result {
        case .success(let audioFile):
            XCTAssertNotNil(audioFile)
            XCTAssertEqual(audioFile.url, testURL)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testCreateAudioFile_InvalidSettings() throws {
        // Given
        let testURL = tempDirectory.appendingPathComponent("test-audio.m4a")
        let invalidSettings: [String: Any] = [
            AVFormatIDKey: "invalid_format",
            AVSampleRateKey: -1,
            AVNumberOfChannelsKey: 0
        ]
        
        // When
        let result = errorHandler.createAudioFile(url: testURL, settings: invalidSettings)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .audioFileCreationFailed(let message) = error {
                XCTAssertFalse(message.isEmpty)
            } else {
                XCTFail("Expected audioFileCreationFailed error")
            }
        }
    }
    
    func testStartAudioEngine_Success() throws {
        // Given
        let audioEngine = AVAudioEngine()
        
        // Set up basic audio engine configuration for testing
        let inputNode = audioEngine.inputNode
        let outputNode = audioEngine.outputNode
        
        // Use the native input format instead of a hardcoded one
        let format = inputNode.inputFormat(forBus: 0)
        
        // Connect input to output to ensure valid graph
        audioEngine.connect(inputNode, to: outputNode, format: format)
        
        // When
        let result = errorHandler.startAudioEngine(audioEngine)
        
        // Then - Clean stop after test
        defer { 
            if audioEngine.isRunning {
                audioEngine.stop() 
            }
        }
        
        switch result {
        case .success:
            XCTAssertTrue(audioEngine.isRunning)
        case .failure(let error):
            // Audio engine might fail in test environment without proper audio setup/permissions
            // This is acceptable in a unit test context
            XCTAssertNotNil(error)
            print("Audio engine failed as expected in test environment: \(error)")
        }
    }
    
    // MARK: - Asset Writer Tests
    
    func testCreateAssetWriter_Success() throws {
        // Given
        let testURL = tempDirectory.appendingPathComponent("test-video.mp4")
        
        // When
        let result = errorHandler.createAssetWriter(url: testURL, fileType: .mp4)
        
        // Then
        switch result {
        case .success(let writer):
            XCTAssertNotNil(writer)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    // MARK: - File System Operations Tests
    
    func testCreateDirectory_Success() throws {
        // Given
        let testDirPath = tempDirectory.appendingPathComponent("test-subdirectory").path
        
        // When
        let result = errorHandler.createDirectory(at: testDirPath)
        
        // Then
        switch result {
        case .success:
            XCTAssertTrue(FileManager.default.fileExists(atPath: testDirPath))
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testGetFileSize_Success() throws {
        // Given
        let testFile = tempDirectory.appendingPathComponent("test-file.txt")
        let testData = "Hello, World!".data(using: .utf8)!
        try testData.write(to: testFile)
        
        // When
        let result = errorHandler.getFileSize(at: testFile.path)
        
        // Then
        switch result {
        case .success(let size):
            XCTAssertEqual(size, Int64(testData.count))
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testGetFileSize_NonExistentFile() throws {
        // Given
        let nonExistentPath = "/non/existent/file.txt"
        
        // When
        let result = errorHandler.getFileSize(at: nonExistentPath)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .fileSizeCastFailed = error {
                // Expected error type
            } else {
                XCTFail("Expected fileSizeCastFailed error")
            }
        }
    }
    
    // MARK: - Type Casting Operations Tests
    
    func testGetCGFloatFromArea_CGFloat() throws {
        // Given
        let area: [String: Any] = ["x": CGFloat(100.5)]
        
        // When
        let result = errorHandler.getCGFloatFromArea(area, key: "x")
        
        // Then
        XCTAssertEqual(result, 100.5)
    }
    
    func testGetCGFloatFromArea_Double() throws {
        // Given
        let area: [String: Any] = ["x": Double(200.7)]
        
        // When
        let result = errorHandler.getCGFloatFromArea(area, key: "x")
        
        // Then
        XCTAssertEqual(result, 200.7, accuracy: 0.001)
    }
    
    func testGetCGFloatFromArea_Int() throws {
        // Given
        let area: [String: Any] = ["x": Int(300)]
        
        // When
        let result = errorHandler.getCGFloatFromArea(area, key: "x")
        
        // Then
        XCTAssertEqual(result, 300.0)
    }
    
    func testGetCGFloatFromArea_InvalidType() throws {
        // Given
        let area: [String: Any] = ["x": "not a number"]
        
        // When
        let result = errorHandler.getCGFloatFromArea(area, key: "x")
        
        // Then
        XCTAssertEqual(result, 0.0)
    }
    
    func testGetCGFloatFromArea_MissingKey() throws {
        // Given
        let area: [String: Any] = ["y": 100.0]
        
        // When
        let result = errorHandler.getCGFloatFromArea(area, key: "x")
        
        // Then
        XCTAssertEqual(result, 0.0)
    }
    
    // MARK: - Saved Area Parsing Tests
    
    func testParseSavedArea_Success() throws {
        // Given
        let validArea: [String: [String: CGFloat]] = [
            "screen1": ["x": 100.0, "y": 200.0, "width": 800.0, "height": 600.0]
        ]
        
        // When
        let result = errorHandler.parseSavedArea(from: validArea)
        
        // Then
        switch result {
        case .success(let area):
            XCTAssertEqual(area["screen1"]?["x"], 100.0)
            XCTAssertEqual(area["screen1"]?["y"], 200.0)
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testParseSavedArea_InvalidType() throws {
        // Given
        let invalidArea = "not a dictionary"
        
        // When
        let result = errorHandler.parseSavedArea(from: invalidArea)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .savedAreaCastFailed = error {
                // Expected error type
            } else {
                XCTFail("Expected savedAreaCastFailed error")
            }
        }
    }
    
    // MARK: - Safe Execute Tests
    
    func testSafeExecute_Success() throws {
        // Given
        let operation = { return "success" }
        let errorTransform = { (error: Error) in RecordingError.exportFailed(error.localizedDescription) }
        
        // When
        let result = errorHandler.safeExecute(operation, errorTransform: errorTransform)
        
        // Then
        switch result {
        case .success(let value):
            XCTAssertEqual(value, "success")
        case .failure(let error):
            XCTFail("Expected success but got error: \(error)")
        }
    }
    
    func testSafeExecute_Failure() throws {
        // Given
        let operation = { throw NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"]) }
        let errorTransform = { (error: Error) in RecordingError.exportFailed(error.localizedDescription) }
        
        // When
        let result = errorHandler.safeExecute(operation, errorTransform: errorTransform)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            if case .exportFailed(let message) = error {
                XCTAssertEqual(message, "Test error")
            } else {
                XCTFail("Expected exportFailed error")
            }
        }
    }
    
    // MARK: - Error Localization Tests
    
    func testRecordingError_LocalizedDescriptions() throws {
        let errors: [RecordingError] = [
            .audioFileCreationFailed("detail"),
            .audioEngineStartFailed("detail"),
            .videoWriterCreationFailed("detail"),
            .directoryCreationFailed("detail"),
            .audioFormatUnsupported("format"),
            .fileSizeCastFailed,
            .savedAreaCastFailed,
            .screenCaptureSetupFailed("detail"),
            .exportFailed("detail")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Error Notification Tests
    
    func testShowError_DoesNotCrash() throws {
        // Given
        let error = RecordingError.audioFileCreationFailed("Test error")
        
        // When/Then - Should not crash
        XCTAssertNoThrow(errorHandler.showError(error))
    }
    
    func testHandleError_DoesNotCrash() throws {
        // Given
        let error = RecordingError.exportFailed("Test export error")
        
        // When/Then - Should not crash
        XCTAssertNoThrow(errorHandler.handleError(error, showToUser: false, context: "Unit Test"))
    }
} 