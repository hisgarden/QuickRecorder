//
//  ErrorHandlerTests.swift
//  QuickRecorderTests
//
//  Created by TDD on 2024/12/19.
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
    
    func testCreateAudioFile_InvalidURL() throws {
        // Given
        let invalidURL = URL(string: "invalid://path")!
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        // When
        let result = errorHandler.createAudioFile(url: invalidURL, settings: settings)
        
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
        
        // When
        let result = errorHandler.startAudioEngine(audioEngine)
        
        // Then - Clean stop after test
        defer { audioEngine.stop() }
        
        switch result {
        case .success:
            XCTAssertTrue(audioEngine.isRunning)
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
    
    func testGetCGFloatFromArea_InvalidType() throws {
        // Given
        let area: [String: Any] = ["x": "not a number"]
        
        // When
        let result = errorHandler.getCGFloatFromArea(area, key: "x")
        
        // Then
        XCTAssertEqual(result, 0.0)
    }
    
    // MARK: - Error Handling Tests
    
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
    
    // MARK: - Integration Tests
    
    func testErrorHandler_Singleton() throws {
        // Given/When
        let instance1 = ErrorHandler.shared
        let instance2 = ErrorHandler.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
}

// MARK: - Mock Classes for Testing

class MockAVAudioEngine: AVAudioEngine {
    var shouldFailStart = false
    
    override func start() throws {
        if shouldFailStart {
            throw NSError(domain: "MockError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Mock engine start failure"])
        }
        try super.start()
    }
} 