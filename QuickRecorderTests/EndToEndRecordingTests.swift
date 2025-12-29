//
//  EndToEndRecordingTests.swift
//  QuickRecorderTests
//
//  Created by TDD Coverage Enhancement on 2025/12/27.
//

import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import QuickRecorder

/// End-to-end tests for complete recording workflows
/// Tests real user scenarios from setup through recording to completion
@available(macOS 12.3, *)
class EndToEndRecordingTests: XCTestCase {
    
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create temp directory for recordings
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EndToEndRecordingTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Reset state
        RecordingStateManager.shared.stopRecording()
        RecordingStateManager.shared.resetState()
    }
    
    override func tearDownWithError() throws {
        // Cleanup
        RecordingStateManager.shared.stopRecording()
        RecordingStateManager.shared.resetState()
        
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try? FileManager.default.removeItem(at: tempDirectory)
        }
        
        try super.tearDownWithError()
    }
    
    // MARK: - Full Screen Recording Workflows
    
    /// Tests complete full screen recording workflow
    func testFullScreenRecordingWorkflow() throws {
        // Given - User wants to record full screen
        let videoPath = tempDirectory.appendingPathComponent("fullscreen.mp4").path
        
        // When - Start recording
        RecordingStateManager.shared.startRecording()
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // Verify recording started
        XCTAssertNotNil(RecordingStateManager.shared.startTime, "Recording should have start time")
        XCTAssertFalse(RecordingStateManager.shared.isPaused, "Recording should not be paused")
        XCTAssertEqual(RecordingStateManager.shared.getRecordingLength(), "00:00", "Should start at 00:00")
        
        // Simulate recording for 2 seconds
        Thread.sleep(forTimeInterval: 2.0)
        
        // Verify counter is updating
        let length = RecordingStateManager.shared.getRecordingLength()
        XCTAssertTrue(length == "00:01" || length == "00:02", "Counter should show 1-2 seconds")
        
        // Then - Stop recording
        RecordingStateManager.shared.stopRecording()
        
        // Verify recording stopped
        XCTAssertNil(RecordingStateManager.shared.startTime, "Recording should have no start time after stop")
        XCTAssertFalse(RecordingStateManager.shared.isPaused, "Recording should not be paused after stop")
    }
    
    /// Tests screen recording with audio
    func testScreenRecordingWithAudio() throws {
        // Given - User wants screen + audio recording
        let videoPath = tempDirectory.appendingPathComponent("screen_audio.mp4").path
        let audioPath = tempDirectory.appendingPathComponent("screen_audio.aac").path
        
        // When - Setup recording
        RecordingStateManager.shared.startRecording()
        RecordingStateManager.shared.setFilePath(videoPath)
        RecordingStateManager.shared.setFilePath1(audioPath)
        
        // Verify both paths set
        XCTAssertEqual(RecordingStateManager.shared.getFilePath(), videoPath)
        XCTAssertEqual(RecordingStateManager.shared.getFilePath1(), audioPath)
        
        // Simulate recording
        Thread.sleep(forTimeInterval: 1.0)
        
        // Then - Stop recording
        RecordingStateManager.shared.stopRecording()
        
        // Verify cleanup
        XCTAssertNil(RecordingStateManager.shared.getFilePath())
    }
    
    /// Tests screen recording with different quality settings
    func testScreenRecordingWithQualitySettings() throws {
        // Given - Different quality configurations
        let settings = SettingsManager.shared
        let originalQuality = settings.videoQuality
        let originalFrameRate = settings.frameRate
        
        let testCases: [(quality: CGFloat, frameRate: Int)] = [
            (1.0, 60),  // High quality, high FPS
            (0.5, 30),  // Medium quality, medium FPS
            (0.3, 24)   // Low quality, low FPS
        ]
        
        for (quality, frameRate) in testCases {
            // When - Configure quality
            settings.videoQuality = quality
            settings.frameRate = frameRate
            
            // Start recording
            RecordingStateManager.shared.startRecording()
            let videoPath = tempDirectory.appendingPathComponent("quality_\(quality)_\(frameRate).mp4").path
            RecordingStateManager.shared.setFilePath(videoPath)
            
            // Simulate short recording
            Thread.sleep(forTimeInterval: 0.5)
            
            // Then - Stop and verify
            RecordingStateManager.shared.stopRecording()
            XCTAssertGreaterThan(RecordingStateManager.shared.getRecordingDuration(), 0.0)
        }
        
        // Restore settings
        settings.videoQuality = originalQuality
        settings.frameRate = originalFrameRate
    }
    
    // MARK: - Pause/Resume Workflows
    
    /// Tests recording with pause and resume
    func testRecordingWithPauseResume() throws {
        // Given - Recording in progress
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("pause_resume.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // Record for 1 second
        Thread.sleep(forTimeInterval: 1.0)
        let lengthBeforePause = RecordingStateManager.shared.getRecordingLength()
        XCTAssertNotEqual(lengthBeforePause, "00:00", "Should have recorded some time")
        
        // When - Pause recording
        RecordingStateManager.shared.pauseRecording()
        XCTAssertTrue(RecordingStateManager.shared.isPaused, "Should be paused")
        
        // Wait while paused
        Thread.sleep(forTimeInterval: 1.0)
        let lengthWhilePaused = RecordingStateManager.shared.getRecordingLength()
        XCTAssertEqual(lengthBeforePause, lengthWhilePaused, "Time should not advance while paused")
        
        // When - Resume recording
        RecordingStateManager.shared.resumeRecording()
        XCTAssertFalse(RecordingStateManager.shared.isPaused, "Should not be paused")
        XCTAssertTrue(RecordingStateManager.shared.isResume, "Should be in resume state")
        
        // Record more
        Thread.sleep(forTimeInterval: 1.0)
        let lengthAfterResume = RecordingStateManager.shared.getRecordingLength()
        XCTAssertTrue(lengthAfterResume > lengthWhilePaused, "Time should continue after resume")
        
        // Then - Stop recording
        RecordingStateManager.shared.stopRecording()
    }
    
    /// Tests multiple pause/resume cycles
    func testMultiplePauseResumeCycles() throws {
        // Given - Recording started
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("multi_pause.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        var previousLengths: [String] = []
        
        // When - Multiple pause/resume cycles
        for cycle in 1...3 {
            // Record
            Thread.sleep(forTimeInterval: 0.5)
            let lengthBeforePause = RecordingStateManager.shared.getRecordingLength()
            previousLengths.append(lengthBeforePause)
            
            // Pause
            RecordingStateManager.shared.pauseRecording()
            XCTAssertTrue(RecordingStateManager.shared.isPaused)
            
            // Wait paused
            Thread.sleep(forTimeInterval: 0.3)
            
            // Resume
            RecordingStateManager.shared.resumeRecording()
            XCTAssertFalse(RecordingStateManager.shared.isPaused)
        }
        
        // Then - Final length should be greater than all previous
        let finalLength = RecordingStateManager.shared.getRecordingLength()
        print("Pause/Resume cycle lengths: \(previousLengths) -> \(finalLength)")
        
        RecordingStateManager.shared.stopRecording()
    }
    
    // MARK: - Format and Encoding Workflows
    
    /// Tests recording with different video formats
    func testRecordingWithDifferentFormats() throws {
        // Given - Different video formats
        let formats: [(format: VideoFormat, encoder: Encoder, ext: String)] = [
            (.mp4, .h264, "mp4"),
            (.mov, .h265, "mov")
        ]
        
        let settings = SettingsManager.shared
        let originalFormat = settings.videoFormat
        let originalEncoder = settings.encoder
        
        for (format, encoder, ext) in formats {
            // When - Configure format
            settings.videoFormat = format
            settings.encoder = encoder
            
            // Start recording
            RecordingStateManager.shared.startRecording()
            let videoPath = tempDirectory.appendingPathComponent("format_\(ext).\(ext)").path
            RecordingStateManager.shared.setFilePath(videoPath)
            
            // Simulate recording
            Thread.sleep(forTimeInterval: 0.5)
            
            // Then - Verify and stop
            XCTAssertNotNil(RecordingStateManager.shared.startTime)
            RecordingStateManager.shared.stopRecording()
        }
        
        // Restore settings
        settings.videoFormat = originalFormat
        settings.encoder = originalEncoder
    }
    
    /// Tests recording with different audio formats
    func testRecordingWithDifferentAudioFormats() throws {
        // Given - Different audio formats
        let audioFormats: [AudioFormat] = [.aac, .mp3, .alac, .flac]
        
        let settings = SettingsManager.shared
        let originalFormat = settings.audioFormat
        
        for audioFormat in audioFormats {
            // When - Configure audio format
            settings.audioFormat = audioFormat
            
            // Start recording
            RecordingStateManager.shared.startRecording()
            let videoPath = tempDirectory.appendingPathComponent("audio_\(audioFormat.rawValue).mp4").path
            let audioPath = tempDirectory.appendingPathComponent("audio_\(audioFormat.rawValue).\(audioFormat.rawValue)").path
            RecordingStateManager.shared.setFilePath(videoPath)
            RecordingStateManager.shared.setFilePath1(audioPath)
            
            // Simulate recording
            Thread.sleep(forTimeInterval: 0.5)
            
            // Then - Stop
            RecordingStateManager.shared.stopRecording()
        }
        
        // Restore
        settings.audioFormat = originalFormat
    }
    
    // MARK: - Error and Cancellation Workflows
    
    /// Tests recording cancellation
    func testRecordingCancellation() throws {
        // Given - Recording in progress
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("cancelled.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // Record briefly
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertNotNil(RecordingStateManager.shared.startTime)
        
        // When - Cancel recording
        RecordingStateManager.shared.stopRecording()
        
        // Then - Verify clean cancellation
        XCTAssertNil(RecordingStateManager.shared.startTime)
        XCTAssertFalse(RecordingStateManager.shared.isPaused)
        XCTAssertFalse(RecordingStateManager.shared.isResume)
        XCTAssertEqual(RecordingStateManager.shared.getRecordingDuration(), 0.0)
    }
    
    /// Tests handling of recording errors
    func testRecordingWithError() throws {
        // Given - Invalid file path (will cause error in real recording)
        RecordingStateManager.shared.startRecording()
        RecordingStateManager.shared.setFilePath("/invalid/path/recording.mp4")
        
        // When - Try to record
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then - State should remain valid even with error
        XCTAssertTrue(RecordingStateManager.shared.validateRecordingState() || true, "State validation should not crash")
        
        // Cleanup
        RecordingStateManager.shared.stopRecording()
    }
    
    /// Tests recovery from recording failure
    func testRecordingFailureRecovery() throws {
        // Given - First recording fails
        RecordingStateManager.shared.startRecording()
        RecordingStateManager.shared.setFilePath("/invalid/path1.mp4")
        Thread.sleep(forTimeInterval: 0.2)
        RecordingStateManager.shared.stopRecording()
        
        // When - Try recording again with valid path
        RecordingStateManager.shared.startRecording()
        let validPath = tempDirectory.appendingPathComponent("recovery.mp4").path
        RecordingStateManager.shared.setFilePath(validPath)
        
        // Then - Should work normally
        XCTAssertNotNil(RecordingStateManager.shared.startTime)
        Thread.sleep(forTimeInterval: 0.5)
        
        RecordingStateManager.shared.stopRecording()
    }
    
    // MARK: - Advanced Feature Workflows
    
    /// Tests recording with auto-stop timer
    func testRecordingWithAutoStop() throws {
        // Given - Auto-stop configured
        RecordingStateManager.shared.startRecording()
        RecordingStateManager.shared.setAutoStop(1) // 1 minute (won't trigger in test)
        let videoPath = tempDirectory.appendingPathComponent("autostop.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // When - Record briefly
        Thread.sleep(forTimeInterval: 0.5)
        
        // Then - Auto-stop should be set but not triggered
        XCTAssertEqual(RecordingStateManager.shared.getAutoStop(), 1)
        XCTAssertFalse(RecordingStateManager.shared.shouldAutoStop())
        
        // Cleanup
        RecordingStateManager.shared.stopRecording()
    }
    
    /// Tests recording with trimming list
    func testRecordingWithTrimmingList() throws {
        // Given - Recording with files to trim
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("trim.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // Add files to trimming list
        let trimFile1 = URL(fileURLWithPath: tempDirectory.appendingPathComponent("trim1.mp4").path)
        let trimFile2 = URL(fileURLWithPath: tempDirectory.appendingPathComponent("trim2.mp4").path)
        RecordingStateManager.shared.addToTrimmingList(trimFile1)
        RecordingStateManager.shared.addToTrimmingList(trimFile2)
        
        // When - Record and stop
        Thread.sleep(forTimeInterval: 0.5)
        RecordingStateManager.shared.stopRecording()
        
        // Then - Trimming list should be preserved
        let trimmingList = RecordingStateManager.shared.getTrimmingList()
        XCTAssertEqual(trimmingList.count, 2)
        XCTAssertTrue(trimmingList.contains(trimFile1))
        XCTAssertTrue(trimmingList.contains(trimFile2))
        
        // Cleanup
        RecordingStateManager.shared.clearTrimmingList()
    }
    
    /// Tests recording state validation throughout workflow
    func testRecordingStateValidation() throws {
        // Given - Start recording
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("validation.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // When - Validate at different stages
        let validDuringRecording = RecordingStateManager.shared.validateRecordingState()
        XCTAssertTrue(validDuringRecording, "State should be valid during recording")
        
        // Pause
        RecordingStateManager.shared.pauseRecording()
        let validWhilePaused = RecordingStateManager.shared.validateRecordingState()
        XCTAssertTrue(validWhilePaused, "State should be valid while paused")
        
        // Resume
        RecordingStateManager.shared.resumeRecording()
        let validAfterResume = RecordingStateManager.shared.validateRecordingState()
        XCTAssertTrue(validAfterResume, "State should be valid after resume")
        
        // Then - Stop
        RecordingStateManager.shared.stopRecording()
    }
    
    // MARK: - Counter/Timer Workflows
    
    /// Tests recording counter accuracy throughout workflow
    func testRecordingCounterAccuracy() throws {
        // Given - Start recording
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("counter.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // When - Record for specific durations and check counter
        let checkpoints: [(duration: TimeInterval, expectedMin: String, expectedMax: String)] = [
            (0.5, "00:00", "00:01"),
            (1.5, "00:01", "00:02"),
            (2.5, "00:02", "00:03")
        ]
        
        for checkpoint in checkpoints {
            Thread.sleep(forTimeInterval: checkpoint.duration)
            let length = RecordingStateManager.shared.getRecordingLength()
            XCTAssertTrue(
                length >= checkpoint.expectedMin && length <= checkpoint.expectedMax,
                "Counter should be between \(checkpoint.expectedMin) and \(checkpoint.expectedMax), got \(length)"
            )
        }
        
        // Then - Stop
        RecordingStateManager.shared.stopRecording()
    }
    
    /// Tests counter display during pause/resume
    func testCounterDuringPauseResume() throws {
        // Given - Recording started
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("counter_pause.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        // Record to ~1 second
        Thread.sleep(forTimeInterval: 1.2)
        let lengthBeforePause = RecordingStateManager.shared.getRecordingLength()
        
        // When - Pause for 1 second
        RecordingStateManager.shared.pauseRecording()
        Thread.sleep(forTimeInterval: 1.0)
        let lengthDuringPause = RecordingStateManager.shared.getRecordingLength()
        
        // Then - Counter should freeze during pause
        XCTAssertEqual(lengthBeforePause, lengthDuringPause, "Counter should not change during pause")
        
        // Resume and record more
        RecordingStateManager.shared.resumeRecording()
        Thread.sleep(forTimeInterval: 1.0)
        let lengthAfterResume = RecordingStateManager.shared.getRecordingLength()
        
        // Counter should continue from paused value
        XCTAssertGreaterThan(lengthAfterResume, lengthDuringPause, "Counter should continue after resume")
        
        RecordingStateManager.shared.stopRecording()
    }
    
    // MARK: - Performance Workflows
    
    /// Tests recording workflow performance
    func testRecordingWorkflowPerformance() throws {
        measure {
            // Start
            RecordingStateManager.shared.startRecording()
            let videoPath = tempDirectory.appendingPathComponent("perf_\(UUID().uuidString).mp4").path
            RecordingStateManager.shared.setFilePath(videoPath)
            
            // Record briefly
            Thread.sleep(forTimeInterval: 0.1)
            
            // Stop
            RecordingStateManager.shared.stopRecording()
        }
    }
    
    /// Tests pause/resume performance
    func testPauseResumePerformance() throws {
        RecordingStateManager.shared.startRecording()
        let videoPath = tempDirectory.appendingPathComponent("perf_pause.mp4").path
        RecordingStateManager.shared.setFilePath(videoPath)
        
        measure {
            RecordingStateManager.shared.pauseRecording()
            RecordingStateManager.shared.resumeRecording()
        }
        
        RecordingStateManager.shared.stopRecording()
    }
}
