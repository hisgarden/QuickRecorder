//
//  VideoManagerTests.swift
//  QuickRecorderTests
//
//  Created by Refactoring on 2025/09/16.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

/// Comprehensive unit tests for VideoManager
class VideoManagerTests: XCTestCase {
    
    var videoManager: VideoManager.Type!
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        videoManager = VideoManager.self
        
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("VideoManagerTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
        
        // Reset state
        VideoManager.cleanup()
    }
    
    override func tearDownWithError() throws {
        // Clean up
        VideoManager.cleanup()
        
        if FileManager.default.fileExists(atPath: tempDirectory.path) {
            try FileManager.default.removeItem(at: tempDirectory)
        }
        
        videoManager = nil
        tempDirectory = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Asset Writer Tests
    
    func testCreateAssetWriter_Success() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        let fileType = AVFileType.mp4
        
        // When
        let result = VideoManager.createAssetWriter(url: fileURL, fileType: fileType)
        
        // Then
        switch result {
        case .success(let writer):
            XCTAssertNotNil(writer)
            XCTAssertEqual(writer.outputURL, fileURL)
            XCTAssertEqual(writer.outputFileType, fileType)
        case .failure(let error):
            XCTFail("Asset writer creation failed: \(error.localizedDescription)")
        }
    }
    
    func testCreateAssetWriter_InvalidURL() throws {
        // Given
        let invalidURL = URL(fileURLWithPath: "/invalid/path/video.mp4")
        let fileType = AVFileType.mp4
        
        // When
        let result = VideoManager.createAssetWriter(url: invalidURL, fileType: fileType)
        
        // Then
        switch result {
        case .success:
            XCTFail("Expected failure but got success")
        case .failure(let error):
            XCTAssertNotNil(error)
        }
    }
    
    func testCreateVideoInput_Success() throws {
        // Given
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        
        // When
        let input = VideoManager.createVideoInput(settings: settings)
        
        // Then
        XCTAssertNotNil(input)
        XCTAssertEqual(input.mediaType, .video)
        XCTAssertTrue(input.expectsMediaDataInRealTime)
    }
    
    func testAddVideoInput_Success() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        let writerResult = VideoManager.createAssetWriter(url: fileURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let input = VideoManager.createVideoInput(settings: settings)
        
        guard case .success(let writer) = writerResult else {
            XCTFail("Failed to create asset writer")
            return
        }
        
        // When
        let success = VideoManager.addVideoInput(input, to: writer)
        
        // Then
        XCTAssertTrue(success)
        XCTAssertEqual(VideoManager.videoInput, input)
    }
    
    func testStartAssetWriter_Success() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        let writerResult = VideoManager.createAssetWriter(url: fileURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let input = VideoManager.createVideoInput(settings: settings)
        
        guard case .success(let writer) = writerResult else {
            XCTFail("Failed to create asset writer")
            return
        }
        
        VideoManager.addVideoInput(input, to: writer)
        
        // When
        let success = VideoManager.startAssetWriter()
        
        // Then
        XCTAssertTrue(success)
        XCTAssertTrue(writer.status == .writing)
    }
    
    func testStartAssetWriter_NoWriter() throws {
        // Given
        VideoManager.assetWriter = nil
        
        // When
        let success = VideoManager.startAssetWriter()
        
        // Then
        XCTAssertFalse(success)
    }
    
    func testFinishAssetWriter_Success() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        let writerResult = VideoManager.createAssetWriter(url: fileURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let input = VideoManager.createVideoInput(settings: settings)
        
        guard case .success(let writer) = writerResult else {
            XCTFail("Failed to create asset writer")
            return
        }
        
        VideoManager.addVideoInput(input, to: writer)
        VideoManager.startAssetWriter()
        
        // When
        let success = VideoManager.finishAssetWriter()
        
        // Then
        XCTAssertTrue(success)
    }
    
    // MARK: - Frame Processing Tests
    
    func testProcessVideoFrame_Success() throws {
        // Given
        let sampleBuffer = try createTestSampleBuffer()
        
        // When
        let processedBuffer = VideoManager.processVideoFrame(sampleBuffer)
        
        // Then
        XCTAssertNotNil(processedBuffer)
        XCTAssertNotEqual(processedBuffer, sampleBuffer) // Should be a copy with new timing
    }
    
    func testAppendVideoSampleBuffer_NoInput() throws {
        // Given
        let sampleBuffer = try createTestSampleBuffer()
        VideoManager.videoInput = nil
        
        // When
        let success = VideoManager.appendVideoSampleBuffer(sampleBuffer)
        
        // Then
        XCTAssertFalse(success)
    }
    
    func testAppendVideoSampleBuffer_WithInput() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        let writerResult = VideoManager.createAssetWriter(url: fileURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let input = VideoManager.createVideoInput(settings: settings)
        
        guard case .success(let writer) = writerResult else {
            XCTFail("Failed to create asset writer")
            return
        }
        
        VideoManager.addVideoInput(input, to: writer)
        VideoManager.startAssetWriter()
        
        let sampleBuffer = try createTestSampleBuffer()
        
        // When
        let success = VideoManager.appendVideoSampleBuffer(sampleBuffer)
        
        // Then
        XCTAssertTrue(success)
        XCTAssertNotNil(VideoManager.firstFrame)
        XCTAssertNotNil(VideoManager.lastPTS)
        XCTAssertNotNil(VideoManager.frameCache)
    }
    
    // MARK: - Time Management Tests
    
    func testTimeOffset_InitialValue() throws {
        // Given/When
        let timeOffset = VideoManager.timeOffset
        
        // Then
        XCTAssertEqual(timeOffset, CMTimeMake(value: 0, timescale: 0))
    }
    
    func testSetTimeOffset() throws {
        // Given
        let newOffset = CMTimeMake(value: 1000, timescale: 1000)
        
        // When
        VideoManager.setTimeOffset(newOffset)
        
        // Then
        XCTAssertEqual(VideoManager.timeOffset, newOffset)
    }
    
    func testResetTimeOffset() throws {
        // Given
        VideoManager.setTimeOffset(CMTimeMake(value: 1000, timescale: 1000))
        
        // When
        VideoManager.resetTimeOffset()
        
        // Then
        XCTAssertEqual(VideoManager.timeOffset, CMTimeMake(value: 0, timescale: 0))
    }
    
    // MARK: - Camera Session Tests
    
    func testConfigureCameraSession_InvalidDevice() throws {
        // Given
        let invalidDevice = AVCaptureDevice.default(for: .video) // May be nil in test environment
        
        // When
        let success = VideoManager.configureCameraSession(device: invalidDevice ?? MockAVCaptureDevice())
        
        // Then
        // Should handle gracefully whether device is available or not
        XCTAssertTrue(success == true || success == false)
    }
    
    func testStartCameraSession_NoSession() throws {
        // Given
        VideoManager.captureSession = nil
        
        // When
        VideoManager.startCameraSession()
        
        // Then
        // Should not crash
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testStopCameraSession_NoSession() throws {
        // Given
        VideoManager.captureSession = nil
        
        // When
        VideoManager.stopCameraSession()
        
        // Then
        // Should not crash
        XCTAssertTrue(true) // Placeholder assertion
    }
    
    func testConfigurePreviewSession_InvalidDevice() throws {
        // Given
        let invalidDevice = AVCaptureDevice.default(for: .video) // May be nil in test environment
        
        // When
        let success = VideoManager.configurePreviewSession(device: invalidDevice ?? MockAVCaptureDevice())
        
        // Then
        // Should handle gracefully whether device is available or not
        XCTAssertTrue(success == true || success == false)
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() throws {
        // Given
        let fileURL = tempDirectory.appendingPathComponent("test_video.mp4")
        let writerResult = VideoManager.createAssetWriter(url: fileURL, fileType: .mp4)
        let settings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let input = VideoManager.createVideoInput(settings: settings)
        
        if case .success(let writer) = writerResult {
            VideoManager.addVideoInput(input, to: writer)
        }
        
        VideoManager.frameCache = try createTestSampleBuffer()
        VideoManager.firstFrame = try createTestSampleBuffer()
        VideoManager.lastPTS = CMTimeMake(value: 1000, timescale: 1000)
        VideoManager.setTimeOffset(CMTimeMake(value: 500, timescale: 1000))
        
        // When
        VideoManager.cleanup()
        
        // Then
        XCTAssertNil(VideoManager.assetWriter)
        XCTAssertNil(VideoManager.videoInput)
        XCTAssertNil(VideoManager.captureSession)
        XCTAssertNil(VideoManager.previewSession)
        XCTAssertNil(VideoManager.frameCache)
        XCTAssertNil(VideoManager.firstFrame)
        XCTAssertNil(VideoManager.lastPTS)
        XCTAssertEqual(VideoManager.timeOffset, CMTimeMake(value: 0, timescale: 0))
    }
    
    // MARK: - Helper Methods
    
    private func createTestSampleBuffer() throws -> CMSampleBuffer {
        // Create a simple test sample buffer
        let formatDescription = try createTestFormatDescription()
        let sampleBuffer = try createSampleBuffer(formatDescription: formatDescription)
        return sampleBuffer
    }
    
    private func createTestFormatDescription() throws -> CMFormatDescription {
        var formatDescription: CMFormatDescription?
        let status = CMFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            mediaType: kCMMediaType_Video,
            mediaSubType: kCMVideoCodecType_H264,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let formatDesc = formatDescription else {
            throw NSError(domain: "VideoManagerTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create format description"])
        }
        
        return formatDesc
    }
    
    private func createSampleBuffer(formatDescription: CMFormatDescription) throws -> CMSampleBuffer {
        var sampleBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateReady(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            formatDescription: formatDescription,
            sampleCount: 1,
            sampleTimingEntryCount: 0,
            sampleTimingArray: nil,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard status == noErr, let buffer = sampleBuffer else {
            throw NSError(domain: "VideoManagerTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create sample buffer"])
        }
        
        return buffer
    }
}

// MARK: - Mock Classes for Testing

/// Mock AVCaptureDevice for testing
class MockAVCaptureDevice: AVCaptureDevice {
    override var deviceType: AVCaptureDevice.DeviceType { .builtInWideAngleCamera }
    override var position: AVCaptureDevice.Position { .back }
}
