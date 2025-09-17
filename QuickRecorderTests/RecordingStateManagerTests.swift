//
//  RecordingStateManagerTests.swift
//  QuickRecorderTests
//
//  Created by Refactoring on 2025/09/16.
//

import XCTest
import Foundation
@testable import QuickRecorder

/// Comprehensive unit tests for RecordingStateManager
class RecordingStateManagerTests: XCTestCase {
    
    var recordingStateManager: RecordingStateManager.Type!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        recordingStateManager = RecordingStateManager.self
        
        // Reset state before each test
        RecordingStateManager.resetState()
    }
    
    override func tearDownWithError() throws {
        recordingStateManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Recording State Management Tests
    
    func testStartRecording() throws {
        // Given
        let initialStartTime = RecordingStateManager.startTime
        let initialTimePassed = RecordingStateManager.timePassed
        let initialIsPaused = RecordingStateManager.isPaused
        let initialIsResume = RecordingStateManager.isResume
        let initialIsSkipFrame = RecordingStateManager.isSkipFrame
        let initialAutoStop = RecordingStateManager.autoStop
        let initialSaveFrame = RecordingStateManager.saveFrame
        
        // When
        RecordingStateManager.startRecording()
        
        // Then
        XCTAssertNotNil(RecordingStateManager.startTime)
        XCTAssertNotEqual(RecordingStateManager.startTime, initialStartTime)
        XCTAssertEqual(RecordingStateManager.timePassed, 0)
        XCTAssertNotEqual(RecordingStateManager.timePassed, initialTimePassed)
        XCTAssertFalse(RecordingStateManager.isPaused)
        XCTAssertNotEqual(RecordingStateManager.isPaused, initialIsPaused)
        XCTAssertFalse(RecordingStateManager.isResume)
        XCTAssertNotEqual(RecordingStateManager.isResume, initialIsResume)
        XCTAssertFalse(RecordingStateManager.isSkipFrame)
        XCTAssertNotEqual(RecordingStateManager.isSkipFrame, initialIsSkipFrame)
        XCTAssertEqual(RecordingStateManager.autoStop, 0)
        XCTAssertNotEqual(RecordingStateManager.autoStop, initialAutoStop)
        XCTAssertFalse(RecordingStateManager.saveFrame)
        XCTAssertNotEqual(RecordingStateManager.saveFrame, initialSaveFrame)
    }
    
    func testPauseRecording() throws {
        // Given
        RecordingStateManager.startRecording()
        XCTAssertFalse(RecordingStateManager.isPaused)
        
        // When
        RecordingStateManager.pauseRecording()
        
        // Then
        XCTAssertTrue(RecordingStateManager.isPaused)
        XCTAssertFalse(RecordingStateManager.isResume)
    }
    
    func testResumeRecording() throws {
        // Given
        RecordingStateManager.startRecording()
        RecordingStateManager.pauseRecording()
        XCTAssertTrue(RecordingStateManager.isPaused)
        XCTAssertFalse(RecordingStateManager.isResume)
        
        // When
        RecordingStateManager.resumeRecording()
        
        // Then
        XCTAssertFalse(RecordingStateManager.isPaused)
        XCTAssertTrue(RecordingStateManager.isResume)
    }
    
    func testStopRecording() throws {
        // Given
        RecordingStateManager.startRecording()
        RecordingStateManager.pauseRecording()
        RecordingStateManager.setSkipFrame(true)
        RecordingStateManager.setSaveFrame(true)
        RecordingStateManager.setAutoStop(5)
        
        // When
        RecordingStateManager.stopRecording()
        
        // Then
        XCTAssertNil(RecordingStateManager.startTime)
        XCTAssertEqual(RecordingStateManager.timePassed, 0)
        XCTAssertFalse(RecordingStateManager.isPaused)
        XCTAssertFalse(RecordingStateManager.isResume)
        XCTAssertFalse(RecordingStateManager.isSkipFrame)
        XCTAssertFalse(RecordingStateManager.saveFrame)
        XCTAssertEqual(RecordingStateManager.autoStop, 0)
    }
    
    // MARK: - Time Management Tests
    
    func testUpdateRecordingTime() throws {
        // Given
        RecordingStateManager.startRecording()
        let initialTime = RecordingStateManager.timePassed
        
        // When
        Thread.sleep(forTimeInterval: 0.1) // Sleep for 100ms
        RecordingStateManager.updateRecordingTime()
        
        // Then
        XCTAssertGreaterThan(RecordingStateManager.timePassed, initialTime)
        XCTAssertGreaterThanOrEqual(RecordingStateManager.timePassed, 0.1)
    }
    
    func testUpdateRecordingTime_NoStartTime() throws {
        // Given
        RecordingStateManager.startTime = nil
        let initialTime = RecordingStateManager.timePassed
        
        // When
        RecordingStateManager.updateRecordingTime()
        
        // Then
        XCTAssertEqual(RecordingStateManager.timePassed, initialTime)
    }
    
    func testGetRecordingDuration() throws {
        // Given
        RecordingStateManager.startRecording()
        RecordingStateManager.timePassed = 125.5
        
        // When
        let duration = RecordingStateManager.getRecordingDuration()
        
        // Then
        XCTAssertEqual(duration, 125.5)
    }
    
    func testGetFormattedDuration_ZeroSeconds() throws {
        // Given
        RecordingStateManager.timePassed = 0
        
        // When
        let formatted = RecordingStateManager.getFormattedDuration()
        
        // Then
        XCTAssertEqual(formatted, "00:00:00")
    }
    
    func testGetFormattedDuration_SecondsOnly() throws {
        // Given
        RecordingStateManager.timePassed = 45
        
        // When
        let formatted = RecordingStateManager.getFormattedDuration()
        
        // Then
        XCTAssertEqual(formatted, "00:00:45")
    }
    
    func testGetFormattedDuration_MinutesAndSeconds() throws {
        // Given
        RecordingStateManager.timePassed = 125 // 2 minutes 5 seconds
        
        // When
        let formatted = RecordingStateManager.getFormattedDuration()
        
        // Then
        XCTAssertEqual(formatted, "00:02:05")
    }
    
    func testGetFormattedDuration_HoursMinutesSeconds() throws {
        // Given
        RecordingStateManager.timePassed = 3665 // 1 hour 1 minute 5 seconds
        
        // When
        let formatted = RecordingStateManager.getFormattedDuration()
        
        // Then
        XCTAssertEqual(formatted, "01:01:05")
    }
    
    func testGetFormattedDuration_LargeDuration() throws {
        // Given
        RecordingStateManager.timePassed = 7325 // 2 hours 2 minutes 5 seconds
        
        // When
        let formatted = RecordingStateManager.getFormattedDuration()
        
        // Then
        XCTAssertEqual(formatted, "02:02:05")
    }
    
    // MARK: - File Path Management Tests
    
    func testSetAndGetFilePath() throws {
        // Given
        let testPath = "/test/path/recording.mp4"
        
        // When
        RecordingStateManager.setFilePath(testPath)
        
        // Then
        XCTAssertEqual(RecordingStateManager.getFilePath(), testPath)
    }
    
    func testSetAndGetFilePath1() throws {
        // Given
        let testPath = "/test/path/recording1.mp4"
        
        // When
        RecordingStateManager.setFilePath1(testPath)
        
        // Then
        XCTAssertEqual(RecordingStateManager.getFilePath1(), testPath)
    }
    
    func testSetAndGetFilePath2() throws {
        // Given
        let testPath = "/test/path/recording2.mp4"
        
        // When
        RecordingStateManager.setFilePath2(testPath)
        
        // Then
        XCTAssertEqual(RecordingStateManager.getFilePath2(), testPath)
    }
    
    func testGenerateFilePath_Success() throws {
        // Given
        let baseDirectory = "/test/directory"
        let fileName = "test_recording"
        let extension = "mp4"
        
        // When
        let generatedPath = RecordingStateManager.generateFilePath(
            baseDirectory: baseDirectory,
            fileName: fileName,
            extension: extension
        )
        
        // Then
        XCTAssertNotNil(generatedPath)
        XCTAssertTrue(generatedPath!.hasPrefix("/test/directory/test_recording_"))
        XCTAssertTrue(generatedPath!.hasSuffix(".mp4"))
        XCTAssertTrue(generatedPath!.contains("2025-")) // Should contain current year
    }
    
    func testGenerateFilePath_EmptyBaseDirectory() throws {
        // Given
        let baseDirectory = ""
        let fileName = "test_recording"
        let extension = "mp4"
        
        // When
        let generatedPath = RecordingStateManager.generateFilePath(
            baseDirectory: baseDirectory,
            fileName: fileName,
            extension: extension
        )
        
        // Then
        XCTAssertNotNil(generatedPath)
        XCTAssertTrue(generatedPath!.hasPrefix("/test_recording_"))
        XCTAssertTrue(generatedPath!.hasSuffix(".mp4"))
    }
    
    // MARK: - Trimming Management Tests
    
    func testAddToTrimmingList() throws {
        // Given
        let testURL = URL(fileURLWithPath: "/test/trimming/file.mp4")
        let initialCount = RecordingStateManager.getTrimmingList().count
        
        // When
        RecordingStateManager.addToTrimmingList(testURL)
        
        // Then
        let trimmingList = RecordingStateManager.getTrimmingList()
        XCTAssertEqual(trimmingList.count, initialCount + 1)
        XCTAssertTrue(trimmingList.contains(testURL))
    }
    
    func testRemoveFromTrimmingList() throws {
        // Given
        let testURL = URL(fileURLWithPath: "/test/trimming/file.mp4")
        RecordingStateManager.addToTrimmingList(testURL)
        let initialCount = RecordingStateManager.getTrimmingList().count
        
        // When
        RecordingStateManager.removeFromTrimmingList(testURL)
        
        // Then
        let trimmingList = RecordingStateManager.getTrimmingList()
        XCTAssertEqual(trimmingList.count, initialCount - 1)
        XCTAssertFalse(trimmingList.contains(testURL))
    }
    
    func testRemoveFromTrimmingList_NonExistentURL() throws {
        // Given
        let testURL = URL(fileURLWithPath: "/test/trimming/file.mp4")
        let nonExistentURL = URL(fileURLWithPath: "/test/trimming/nonexistent.mp4")
        RecordingStateManager.addToTrimmingList(testURL)
        let initialCount = RecordingStateManager.getTrimmingList().count
        
        // When
        RecordingStateManager.removeFromTrimmingList(nonExistentURL)
        
        // Then
        let trimmingList = RecordingStateManager.getTrimmingList()
        XCTAssertEqual(trimmingList.count, initialCount) // Should remain unchanged
        XCTAssertTrue(trimmingList.contains(testURL))
    }
    
    func testClearTrimmingList() throws {
        // Given
        let testURL1 = URL(fileURLWithPath: "/test/trimming/file1.mp4")
        let testURL2 = URL(fileURLWithPath: "/test/trimming/file2.mp4")
        RecordingStateManager.addToTrimmingList(testURL1)
        RecordingStateManager.addToTrimmingList(testURL2)
        XCTAssertEqual(RecordingStateManager.getTrimmingList().count, 2)
        
        // When
        RecordingStateManager.clearTrimmingList()
        
        // Then
        XCTAssertEqual(RecordingStateManager.getTrimmingList().count, 0)
    }
    
    // MARK: - Frame Management Tests
    
    func testSetAndGetSkipFrame() throws {
        // Given
        XCTAssertFalse(RecordingStateManager.shouldSkipFrame())
        
        // When
        RecordingStateManager.setSkipFrame(true)
        
        // Then
        XCTAssertTrue(RecordingStateManager.shouldSkipFrame())
        
        // When
        RecordingStateManager.setSkipFrame(false)
        
        // Then
        XCTAssertFalse(RecordingStateManager.shouldSkipFrame())
    }
    
    func testSetAndGetSaveFrame() throws {
        // Given
        XCTAssertFalse(RecordingStateManager.shouldSaveFrame())
        
        // When
        RecordingStateManager.setSaveFrame(true)
        
        // Then
        XCTAssertTrue(RecordingStateManager.shouldSaveFrame())
        
        // When
        RecordingStateManager.setSaveFrame(false)
        
        // Then
        XCTAssertFalse(RecordingStateManager.shouldSaveFrame())
    }
    
    // MARK: - Auto-stop Management Tests
    
    func testSetAndGetAutoStop() throws {
        // Given
        XCTAssertEqual(RecordingStateManager.getAutoStop(), 0)
        
        // When
        RecordingStateManager.setAutoStop(10)
        
        // Then
        XCTAssertEqual(RecordingStateManager.getAutoStop(), 10)
    }
    
    func testDecrementAutoStop() throws {
        // Given
        RecordingStateManager.setAutoStop(5)
        
        // When
        RecordingStateManager.decrementAutoStop()
        
        // Then
        XCTAssertEqual(RecordingStateManager.getAutoStop(), 4)
    }
    
    func testDecrementAutoStop_Zero() throws {
        // Given
        RecordingStateManager.setAutoStop(0)
        
        // When
        RecordingStateManager.decrementAutoStop()
        
        // Then
        XCTAssertEqual(RecordingStateManager.getAutoStop(), 0) // Should not go below 0
    }
    
    func testShouldAutoStop_True() throws {
        // Given
        RecordingStateManager.setAutoStop(0)
        
        // When
        let shouldStop = RecordingStateManager.shouldAutoStop()
        
        // Then
        XCTAssertTrue(shouldStop)
    }
    
    func testShouldAutoStop_False() throws {
        // Given
        RecordingStateManager.setAutoStop(5)
        
        // When
        let shouldStop = RecordingStateManager.shouldAutoStop()
        
        // Then
        XCTAssertFalse(shouldStop)
    }
    
    func testShouldAutoStop_NegativeOne() throws {
        // Given
        RecordingStateManager.setAutoStop(-1)
        
        // When
        let shouldStop = RecordingStateManager.shouldAutoStop()
        
        // Then
        XCTAssertFalse(shouldStop) // -1 means disabled
    }
    
    // MARK: - State Validation Tests
    
    func testValidateRecordingState_Valid() throws {
        // Given
        RecordingStateManager.startRecording()
        RecordingStateManager.setFilePath("/test/path/recording.mp4")
        
        // When
        let isValid = RecordingStateManager.validateRecordingState()
        
        // Then
        XCTAssertTrue(isValid)
    }
    
    func testValidateRecordingState_NoStartTime() throws {
        // Given
        RecordingStateManager.isPaused = false
        RecordingStateManager.startTime = nil
        RecordingStateManager.setFilePath("/test/path/recording.mp4")
        
        // When
        let isValid = RecordingStateManager.validateRecordingState()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testValidateRecordingState_NoFilePath() throws {
        // Given
        RecordingStateManager.startRecording()
        RecordingStateManager.filePath = nil
        
        // When
        let isValid = RecordingStateManager.validateRecordingState()
        
        // Then
        XCTAssertFalse(isValid)
    }
    
    func testValidateRecordingState_Paused() throws {
        // Given
        RecordingStateManager.isPaused = true
        RecordingStateManager.startTime = nil // Paused state doesn't need start time
        RecordingStateManager.setFilePath("/test/path/recording.mp4")
        
        // When
        let isValid = RecordingStateManager.validateRecordingState()
        
        // Then
        XCTAssertTrue(isValid) // Paused state is valid even without start time
    }
    
    // MARK: - Reset State Tests
    
    func testResetState() throws {
        // Given
        RecordingStateManager.startRecording()
        RecordingStateManager.setFilePath("/test/path/recording.mp4")
        RecordingStateManager.setFilePath1("/test/path/recording1.mp4")
        RecordingStateManager.setFilePath2("/test/path/recording2.mp4")
        RecordingStateManager.addToTrimmingList(URL(fileURLWithPath: "/test/trimming/file.mp4"))
        RecordingStateManager.setSkipFrame(true)
        RecordingStateManager.setSaveFrame(true)
        RecordingStateManager.setAutoStop(10)
        
        // When
        RecordingStateManager.resetState()
        
        // Then
        XCTAssertNil(RecordingStateManager.startTime)
        XCTAssertEqual(RecordingStateManager.timePassed, 0)
        XCTAssertFalse(RecordingStateManager.isPaused)
        XCTAssertFalse(RecordingStateManager.isResume)
        XCTAssertFalse(RecordingStateManager.isSkipFrame)
        XCTAssertEqual(RecordingStateManager.autoStop, 0)
        XCTAssertFalse(RecordingStateManager.saveFrame)
        XCTAssertNil(RecordingStateManager.filePath)
        XCTAssertNil(RecordingStateManager.filePath1)
        XCTAssertNil(RecordingStateManager.filePath2)
        XCTAssertEqual(RecordingStateManager.getTrimmingList().count, 0)
    }
}
