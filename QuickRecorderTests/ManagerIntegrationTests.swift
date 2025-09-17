//
//  ManagerIntegrationTests.swift
//  QuickRecorderTests
//
//  Created by Refactoring on 2025/09/16.
//

import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import QuickRecorder

/// Integration tests to validate all manager components work together
class ManagerIntegrationTests: XCTestCase {
    
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("ManagerIntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Reset all manager states
        resetAllManagers()
    }
    
    override func tearDownWithError() throws {
        // Clean up all managers
        cleanupAllManagers()
        
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        
        tempDirectory = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Recording Workflow Integration Tests
    
    func testCompleteRecordingWorkflow() throws {
        // Given - Setup recording session
        let audioFileURL = tempDirectory.appendingPathComponent("test_audio.aac")
        let videoFileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        
        // When - Start recording workflow
        RecordingStateManager.startRecording()
        RecordingStateManager.setFilePath(audioFileURL.path)
        RecordingStateManager.setFilePath1(videoFileURL.path)
        
        // Configure audio
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
        guard case .success(let audioFile) = audioResult else {
            XCTFail("Failed to create audio file")
            return
        }
        AudioManager.audioFile = audioFile
        
        // Configure video
        let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
        guard case .success(let videoWriter) = videoResult else {
            XCTFail("Failed to create video writer")
            return
        }
        VideoManager.assetWriter = videoWriter
        
        // Configure video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let videoInput = VideoManager.createVideoInput(settings: videoSettings)
        VideoManager.addVideoInput(videoInput, to: videoWriter)
        
        // Start recording
        let audioStartResult = AudioManager.startAudioEngine()
        let videoStartResult = VideoManager.startAssetWriter()
        
        // Simulate recording for a short time
        Thread.sleep(forTimeInterval: 0.1)
        RecordingStateManager.updateRecordingTime()
        
        // Pause recording
        RecordingStateManager.pauseRecording()
        
        // Resume recording
        RecordingStateManager.resumeRecording()
        
        // Simulate more recording
        Thread.sleep(forTimeInterval: 0.1)
        RecordingStateManager.updateRecordingTime()
        
        // Stop recording
        RecordingStateManager.stopRecording()
        AudioManager.stopAudioEngine()
        VideoManager.finishAssetWriter()
        
        // Then - Validate recording state
        XCTAssertNotNil(RecordingStateManager.getRecordingDuration())
        XCTAssertGreaterThan(RecordingStateManager.getRecordingDuration(), 0.1)
        XCTAssertNotNil(RecordingStateManager.getFormattedDuration())
        XCTAssertTrue(RecordingStateManager.getFormattedDuration().hasPrefix("00:00:"))
        
        // Validate files were created
        XCTAssertTrue(FileManager.default.fileExists(atPath: audioFileURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: videoFileURL.path))
    }
    
    func testScreenCaptureIntegration() throws {
        // Given - Setup screen capture
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When - Get available content
        let windows = ScreenCaptureManager.getWindows()
        let displays = ScreenCaptureManager.getDisplays()
        let applications = ScreenCaptureManager.getApplications()
        
        // Then - Validate content
        XCTAssertEqual(windows.count, 2)
        XCTAssertEqual(displays.count, 1)
        XCTAssertEqual(applications.count, 1)
        
        // Test filtering
        let filteredWindows = ScreenCaptureManager.getWindows(hideSelf: true)
        XCTAssertLessThanOrEqual(filteredWindows.count, windows.count)
        
        // Test self detection
        let selfWindow = ScreenCaptureManager.getSelf()
        let selfWindows = ScreenCaptureManager.getSelfWindows()
        XCTAssertNotNil(selfWindow)
        XCTAssertEqual(selfWindows.count, 1)
    }
    
    func testAudioVideoSynchronization() throws {
        // Given - Setup audio and video
        let audioFileURL = tempDirectory.appendingPathComponent("sync_audio.aac")
        let videoFileURL = tempDirectory.appendingPathComponent("sync_video.mp4")
        
        // Create audio file
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
        guard case .success(let audioFile) = audioResult else {
            XCTFail("Failed to create audio file")
            return
        }
        AudioManager.audioFile = audioFile
        
        // Create video writer
        let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
        guard case .success(let videoWriter) = videoResult else {
            XCTFail("Failed to create video writer")
            return
        }
        VideoManager.assetWriter = videoWriter
        
        // Configure video input
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let videoInput = VideoManager.createVideoInput(settings: videoSettings)
        VideoManager.addVideoInput(videoInput, to: videoWriter)
        
        // When - Start both audio and video
        let audioStartResult = AudioManager.startAudioEngine()
        let videoStartResult = VideoManager.startAssetWriter()
        
        // Set time offset for synchronization
        let timeOffset = CMTimeMake(value: 1000, timescale: 1000)
        VideoManager.setTimeOffset(timeOffset)
        
        // Process a video frame
        let sampleBuffer = try createTestSampleBuffer()
        let processedFrame = VideoManager.processVideoFrame(sampleBuffer)
        
        // Then - Validate synchronization
        XCTAssertNotNil(processedFrame)
        XCTAssertEqual(VideoManager.timeOffset, timeOffset)
        
        // Clean up
        AudioManager.stopAudioEngine()
        VideoManager.finishAssetWriter()
    }
    
    func testErrorHandlingIntegration() throws {
        // Given - Setup with invalid parameters
        let invalidAudioURL = URL(fileURLWithPath: "/invalid/path/audio.aac")
        let invalidVideoURL = URL(fileURLWithPath: "/invalid/path/video.mp4")
        
        // When - Try to create files with invalid paths
        let audioResult = AudioManager.createAudioFile(url: invalidAudioURL, settings: [:])
        let videoResult = VideoManager.createAssetWriter(url: invalidVideoURL, fileType: .mp4)
        
        // Then - Validate error handling
        switch audioResult {
        case .success:
            XCTFail("Expected audio creation to fail")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
        
        switch videoResult {
        case .success:
            XCTFail("Expected video creation to fail")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
        
        // Validate state remains consistent
        XCTAssertNil(AudioManager.audioFile)
        XCTAssertNil(VideoManager.assetWriter)
    }
    
    func testStateConsistencyAcrossManagers() throws {
        // Given - Start recording
        RecordingStateManager.startRecording()
        RecordingStateManager.setFilePath("/test/audio.aac")
        RecordingStateManager.setFilePath1("/test/video.mp4")
        
        // When - Configure managers
        let audioFileURL = tempDirectory.appendingPathComponent("consistency_audio.aac")
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
        guard case .success(let audioFile) = audioResult else {
            XCTFail("Failed to create audio file")
            return
        }
        AudioManager.audioFile = audioFile
        
        let videoFileURL = tempDirectory.appendingPathComponent("consistency_video.mp4")
        let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
        guard case .success(let videoWriter) = videoResult else {
            XCTFail("Failed to create video writer")
            return
        }
        VideoManager.assetWriter = videoWriter
        
        // Then - Validate state consistency
        XCTAssertTrue(RecordingStateManager.validateRecordingState())
        XCTAssertNotNil(AudioManager.audioFile)
        XCTAssertNotNil(VideoManager.assetWriter)
        XCTAssertEqual(RecordingStateManager.getFilePath(), "/test/audio.aac")
        XCTAssertEqual(RecordingStateManager.getFilePath1(), "/test/video.mp4")
        
        // Test pause/resume consistency
        RecordingStateManager.pauseRecording()
        XCTAssertTrue(RecordingStateManager.isPaused)
        XCTAssertFalse(RecordingStateManager.isResume)
        
        RecordingStateManager.resumeRecording()
        XCTAssertFalse(RecordingStateManager.isPaused)
        XCTAssertTrue(RecordingStateManager.isResume)
    }
    
    func testCleanupIntegration() throws {
        // Given - Setup all managers with data
        RecordingStateManager.startRecording()
        RecordingStateManager.setFilePath("/test/audio.aac")
        RecordingStateManager.addToTrimmingList(URL(fileURLWithPath: "/test/trimming.mp4"))
        
        let audioFileURL = tempDirectory.appendingPathComponent("cleanup_audio.aac")
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
        if case .success(let audioFile) = audioResult {
            AudioManager.audioFile = audioFile
        }
        
        let videoFileURL = tempDirectory.appendingPathComponent("cleanup_video.mp4")
        let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
        if case .success(let videoWriter) = videoResult {
            VideoManager.assetWriter = videoWriter
        }
        
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When - Cleanup all managers
        cleanupAllManagers()
        
        // Then - Validate cleanup
        XCTAssertNil(RecordingStateManager.startTime)
        XCTAssertEqual(RecordingStateManager.getTrimmingList().count, 0)
        XCTAssertNil(AudioManager.audioFile)
        XCTAssertNil(VideoManager.assetWriter)
        XCTAssertNil(VideoManager.videoInput)
        XCTAssertNil(VideoManager.frameCache)
        XCTAssertNil(VideoManager.firstFrame)
        XCTAssertEqual(VideoManager.timeOffset, CMTimeMake(value: 0, timescale: 0))
    }
    
    func testPerformanceIntegration() throws {
        // Given - Setup for performance testing
        let audioFileURL = tempDirectory.appendingPathComponent("perf_audio.aac")
        let videoFileURL = tempDirectory.appendingPathComponent("perf_video.mp4")
        
        // When - Measure performance of key operations
        let audioCreationTime = measureTime {
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            let result = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
            if case .success(let audioFile) = result {
                AudioManager.audioFile = audioFile
            }
        }
        
        let videoCreationTime = measureTime {
            let result = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
            if case .success(let videoWriter) = result {
                VideoManager.assetWriter = videoWriter
            }
        }
        
        let stateManagementTime = measureTime {
            RecordingStateManager.startRecording()
            RecordingStateManager.setFilePath(audioFileURL.path)
            RecordingStateManager.setFilePath1(videoFileURL.path)
            RecordingStateManager.updateRecordingTime()
            RecordingStateManager.stopRecording()
        }
        
        // Then - Validate performance (operations should complete quickly)
        XCTAssertLessThan(audioCreationTime, 1.0) // Should complete in less than 1 second
        XCTAssertLessThan(videoCreationTime, 1.0) // Should complete in less than 1 second
        XCTAssertLessThan(stateManagementTime, 0.1) // Should complete in less than 100ms
    }
    
    // MARK: - Helper Methods
    
    private func resetAllManagers() {
        RecordingStateManager.resetState()
        AudioManager.cleanupAudioFiles()
        VideoManager.cleanup()
        ScreenCaptureManager.availableContent = nil
        ScreenCaptureManager.filter = nil
        ScreenCaptureManager.stream = nil
        ScreenCaptureManager.screen = nil
        ScreenCaptureManager.window = nil
        ScreenCaptureManager.application = nil
        ScreenCaptureManager.streamType = nil
        ScreenCaptureManager.screenArea = nil
    }
    
    private func cleanupAllManagers() {
        AudioManager.cleanupAudioFiles()
        AudioManager.stopAudioEngine()
        AudioManager.resetAudioEngine()
        VideoManager.cleanup()
        RecordingStateManager.resetState()
        ScreenCaptureManager.availableContent = nil
    }
    
    private func createMockShareableContent() -> SCShareableContent {
        let mockDisplay = MockSCDisplay()
        let mockWindow1 = MockSCWindow(bundleIdentifier: "com.example.app1")
        let mockWindow2 = MockSCWindow(bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.lihaoyun6.QuickRecorder")
        let mockApp = MockSCRunningApplication(bundleIdentifier: "com.example.app1")
        
        return MockSCShareableContent(displays: [mockDisplay], windows: [mockWindow1, mockWindow2], applications: [mockApp])
    }
    
    private func createTestSampleBuffer() throws -> CMSampleBuffer {
        var formatDescription: CMFormatDescription?
        let status = CMFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let formatDesc = formatDescription else {
            throw NSError(domain: "ManagerIntegrationTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create format description"])
        }
        
        var sampleBuffer: CMSampleBuffer?
        let bufferStatus = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            formatDescription: formatDesc,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard bufferStatus == noErr, let buffer = sampleBuffer else {
            throw NSError(domain: "ManagerIntegrationTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create sample buffer"])
        }
        
        return buffer
    }
    
    private func measureTime(_ operation: () -> Void) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return timeElapsed
    }
}
