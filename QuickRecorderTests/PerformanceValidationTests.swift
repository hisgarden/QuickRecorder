//
//  PerformanceValidationTests.swift
//  QuickRecorderTests
//
//  Created by Refactoring on 2025/09/16.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

/// Performance validation tests to ensure refactored code maintains performance
class PerformanceValidationTests: XCTestCase {
    
    var tempDirectory: URL!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        // Create temporary directory for testing
        tempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent("PerformanceValidationTests-\(UUID().uuidString)")
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
    
    // MARK: - Audio Manager Performance Tests
    
    func testAudioFileCreationPerformance() throws {
        // Given
        let audioFileURL = tempDirectory.appendingPathComponent("perf_audio.aac")
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        
        // When - Measure audio file creation performance
        let creationTime = measureTime {
            let result = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
            if case .success(let audioFile) = result {
                AudioManager.audioFile = audioFile
            }
        }
        
        // Then - Should complete quickly (less than 100ms)
        XCTAssertLessThan(creationTime, 0.1, "Audio file creation should complete in less than 100ms")
        print("Audio file creation time: \(creationTime * 1000)ms")
    }
    
    func testAudioEngineStartupPerformance() throws {
        // Given
        let engine = AudioManager.audioEngine
        
        // When - Measure audio engine startup performance
        let startupTime = measureTime {
            let result = AudioManager.startAudioEngine()
            // Clean up immediately
            if engine.isRunning {
                AudioManager.stopAudioEngine()
            }
        }
        
        // Then - Should complete quickly (less than 500ms)
        XCTAssertLessThan(startupTime, 0.5, "Audio engine startup should complete in less than 500ms")
        print("Audio engine startup time: \(startupTime * 1000)ms")
    }
    
    func testAudioFormatRetrievalPerformance() throws {
        // Given/When - Measure format retrieval performance
        let formatTime = measureTime {
            _ = AudioManager.getCurrentInputFormat()
            _ = AudioManager.getCurrentOutputFormat()
        }
        
        // Then - Should complete very quickly (less than 10ms)
        XCTAssertLessThan(formatTime, 0.01, "Audio format retrieval should complete in less than 10ms")
        print("Audio format retrieval time: \(formatTime * 1000)ms")
    }
    
    // MARK: - Video Manager Performance Tests
    
    func testVideoAssetWriterCreationPerformance() throws {
        // Given
        let videoFileURL = tempDirectory.appendingPathComponent("perf_video.mp4")
        
        // When - Measure video writer creation performance
        let creationTime = measureTime {
            let result = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
            if case .success(let writer) = result {
                VideoManager.assetWriter = writer
            }
        }
        
        // Then - Should complete quickly (less than 100ms)
        XCTAssertLessThan(creationTime, 0.1, "Video asset writer creation should complete in less than 100ms")
        print("Video asset writer creation time: \(creationTime * 1000)ms")
    }
    
    func testVideoInputCreationPerformance() throws {
        // Given
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        
        // When - Measure video input creation performance
        let creationTime = measureTime {
            _ = VideoManager.createVideoInput(settings: videoSettings)
        }
        
        // Then - Should complete very quickly (less than 10ms)
        XCTAssertLessThan(creationTime, 0.01, "Video input creation should complete in less than 10ms")
        print("Video input creation time: \(creationTime * 1000)ms")
    }
    
    func testVideoFrameProcessingPerformance() throws {
        // Given
        let sampleBuffer = try createTestSampleBuffer()
        
        // When - Measure frame processing performance
        let processingTime = measureTime {
            _ = VideoManager.processVideoFrame(sampleBuffer)
        }
        
        // Then - Should complete very quickly (less than 1ms)
        XCTAssertLessThan(processingTime, 0.001, "Video frame processing should complete in less than 1ms")
        print("Video frame processing time: \(processingTime * 1000)ms")
    }
    
    // MARK: - Recording State Manager Performance Tests
    
    func testRecordingStateManagementPerformance() throws {
        // Given/When - Measure state management operations
        let stateTime = measureTime {
            // Start recording
            RecordingStateManager.startRecording()
            
            // Set file paths
            RecordingStateManager.setFilePath("/test/audio.aac")
            RecordingStateManager.setFilePath1("/test/video.mp4")
            RecordingStateManager.setFilePath2("/test/audio2.aac")
            
            // Update time
            RecordingStateManager.updateRecordingTime()
            
            // Pause and resume
            RecordingStateManager.pauseRecording()
            RecordingStateManager.resumeRecording()
            
            // Add to trimming list
            RecordingStateManager.addToTrimmingList(URL(fileURLWithPath: "/test/trimming.mp4"))
            
            // Get formatted duration
            _ = RecordingStateManager.getFormattedDuration()
            
            // Stop recording
            RecordingStateManager.stopRecording()
        }
        
        // Then - Should complete very quickly (less than 10ms)
        XCTAssertLessThan(stateTime, 0.01, "Recording state management should complete in less than 10ms")
        print("Recording state management time: \(stateTime * 1000)ms")
    }
    
    func testFilePathGenerationPerformance() throws {
        // Given/When - Measure file path generation performance
        let generationTime = measureTime {
            for i in 0..<100 {
                _ = RecordingStateManager.generateFilePath(
                    baseDirectory: "/test/directory",
                    fileName: "recording_\(i)",
                    extension: "mp4"
                )
            }
        }
        
        // Then - Should complete quickly (less than 100ms for 100 generations)
        XCTAssertLessThan(generationTime, 0.1, "File path generation should complete in less than 100ms for 100 generations")
        print("File path generation time for 100 paths: \(generationTime * 1000)ms")
    }
    
    func testTrimmingListOperationsPerformance() throws {
        // Given
        let testURLs = (0..<1000).map { URL(fileURLWithPath: "/test/trimming/file_\($0).mp4") }
        
        // When - Measure trimming list operations
        let operationsTime = measureTime {
            // Add all URLs
            for url in testURLs {
                RecordingStateManager.addToTrimmingList(url)
            }
            
            // Remove half of them
            for i in 0..<500 {
                RecordingStateManager.removeFromTrimmingList(testURLs[i])
            }
            
            // Get list
            _ = RecordingStateManager.getTrimmingList()
            
            // Clear list
            RecordingStateManager.clearTrimmingList()
        }
        
        // Then - Should complete quickly (less than 50ms for 1000 operations)
        XCTAssertLessThan(operationsTime, 0.05, "Trimming list operations should complete in less than 50ms for 1000 operations")
        print("Trimming list operations time for 1000 operations: \(operationsTime * 1000)ms")
    }
    
    // MARK: - Screen Capture Manager Performance Tests
    
    func testScreenCaptureContentRetrievalPerformance() throws {
        // Given
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When - Measure content retrieval performance
        let retrievalTime = measureTime {
            _ = ScreenCaptureManager.getWindows()
            _ = ScreenCaptureManager.getDisplays()
            _ = ScreenCaptureManager.getApplications()
            _ = ScreenCaptureManager.getSelf()
            _ = ScreenCaptureManager.getSelfWindows()
        }
        
        // Then - Should complete quickly (less than 10ms)
        XCTAssertLessThan(retrievalTime, 0.01, "Screen capture content retrieval should complete in less than 10ms")
        print("Screen capture content retrieval time: \(retrievalTime * 1000)ms")
    }
    
    func testScreenCaptureFilteringPerformance() throws {
        // Given
        let mockContent = createMockShareableContentWithManyWindows()
        ScreenCaptureManager.availableContent = mockContent
        
        // When - Measure filtering performance
        let filteringTime = measureTime {
            _ = ScreenCaptureManager.getWindows(isOnScreen: true, hideSelf: true)
            _ = ScreenCaptureManager.getWindows(isOnScreen: false, hideSelf: false)
            _ = ScreenCaptureManager.getApplications()
        }
        
        // Then - Should complete quickly (less than 20ms)
        XCTAssertLessThan(filteringTime, 0.02, "Screen capture filtering should complete in less than 20ms")
        print("Screen capture filtering time: \(filteringTime * 1000)ms")
    }
    
    // MARK: - Integration Performance Tests
    
    func testCompleteRecordingSetupPerformance() throws {
        // Given
        let audioFileURL = tempDirectory.appendingPathComponent("setup_audio.aac")
        let videoFileURL = tempDirectory.appendingPathComponent("setup_video.mp4")
        
        // When - Measure complete recording setup performance
        let setupTime = measureTime {
            // Setup recording state
            RecordingStateManager.startRecording()
            RecordingStateManager.setFilePath(audioFileURL.path)
            RecordingStateManager.setFilePath1(videoFileURL.path)
            
            // Setup audio
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
            if case .success(let audioFile) = audioResult {
                AudioManager.audioFile = audioFile
            }
            
            // Setup video
            let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
            if case .success(let videoWriter) = videoResult {
                VideoManager.assetWriter = videoWriter
            }
            
            let videoSettings: [String: Any] = [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1920,
                AVVideoHeightKey: 1080
            ]
            let videoInput = VideoManager.createVideoInput(settings: videoSettings)
            if let writer = VideoManager.assetWriter {
                VideoManager.addVideoInput(videoInput, to: writer)
            }
        }
        
        // Then - Should complete quickly (less than 200ms)
        XCTAssertLessThan(setupTime, 0.2, "Complete recording setup should complete in less than 200ms")
        print("Complete recording setup time: \(setupTime * 1000)ms")
    }
    
    func testRecordingWorkflowPerformance() throws {
        // Given
        let audioFileURL = tempDirectory.appendingPathComponent("workflow_audio.aac")
        let videoFileURL = tempDirectory.appendingPathComponent("workflow_video.mp4")
        
        // Setup recording
        RecordingStateManager.startRecording()
        RecordingStateManager.setFilePath(audioFileURL.path)
        RecordingStateManager.setFilePath1(videoFileURL.path)
        
        let audioSettings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 2
        ]
        let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
        if case .success(let audioFile) = audioResult {
            AudioManager.audioFile = audioFile
        }
        
        let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
        if case .success(let videoWriter) = videoResult {
            VideoManager.assetWriter = videoWriter
        }
        
        let videoSettings: [String: Any] = [
            AVVideoCodecKey: AVVideoCodecType.h264,
            AVVideoWidthKey: 1920,
            AVVideoHeightKey: 1080
        ]
        let videoInput = VideoManager.createVideoInput(settings: videoSettings)
        if let writer = VideoManager.assetWriter {
            VideoManager.addVideoInput(videoInput, to: writer)
        }
        
        // When - Measure recording workflow performance
        let workflowTime = measureTime {
            // Start recording
            _ = AudioManager.startAudioEngine()
            _ = VideoManager.startAssetWriter()
            
            // Simulate recording operations
            for _ in 0..<10 {
                RecordingStateManager.updateRecordingTime()
                let sampleBuffer = try? createTestSampleBuffer()
                if let buffer = sampleBuffer {
                    _ = VideoManager.processVideoFrame(buffer)
                }
            }
            
            // Pause and resume
            RecordingStateManager.pauseRecording()
            RecordingStateManager.resumeRecording()
            
            // Stop recording
            RecordingStateManager.stopRecording()
            AudioManager.stopAudioEngine()
            VideoManager.finishAssetWriter()
        }
        
        // Then - Should complete quickly (less than 500ms)
        XCTAssertLessThan(workflowTime, 0.5, "Recording workflow should complete in less than 500ms")
        print("Recording workflow time: \(workflowTime * 1000)ms")
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageDuringOperations() throws {
        // Given
        let initialMemory = getCurrentMemoryUsage()
        
        // When - Perform memory-intensive operations
        var audioFiles: [AVAudioFile] = []
        var videoWriters: [AVAssetWriter] = []
        
        for i in 0..<10 {
            let audioFileURL = tempDirectory.appendingPathComponent("memory_audio_\(i).aac")
            let videoFileURL = tempDirectory.appendingPathComponent("memory_video_\(i).mp4")
            
            let audioSettings: [String: Any] = [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVSampleRateKey: 44100,
                AVNumberOfChannelsKey: 2
            ]
            let audioResult = AudioManager.createAudioFile(url: audioFileURL, settings: audioSettings)
            if case .success(let audioFile) = audioResult {
                audioFiles.append(audioFile)
            }
            
            let videoResult = VideoManager.createAssetWriter(url: videoFileURL, fileType: .mp4)
            if case .success(let videoWriter) = videoResult {
                videoWriters.append(videoWriter)
            }
        }
        
        let peakMemory = getCurrentMemoryUsage()
        
        // Clean up
        audioFiles.removeAll()
        videoWriters.removeAll()
        AudioManager.cleanupAudioFiles()
        VideoManager.cleanup()
        
        let finalMemory = getCurrentMemoryUsage()
        
        // Then - Memory should be reasonable and cleaned up
        let memoryIncrease = peakMemory - initialMemory
        let memoryCleanup = peakMemory - finalMemory
        
        XCTAssertLessThan(memoryIncrease, 50 * 1024 * 1024, "Memory increase should be less than 50MB") // 50MB
        XCTAssertGreaterThan(memoryCleanup, 0, "Memory should be cleaned up after operations")
        
        print("Initial memory: \(initialMemory / 1024 / 1024)MB")
        print("Peak memory: \(peakMemory / 1024 / 1024)MB")
        print("Final memory: \(finalMemory / 1024 / 1024)MB")
        print("Memory increase: \(memoryIncrease / 1024 / 1024)MB")
        print("Memory cleanup: \(memoryCleanup / 1024 / 1024)MB")
    }
    
    // MARK: - Helper Methods
    
    private func resetAllManagers() {
        RecordingStateManager.resetState()
        AudioManager.cleanupAudioFiles()
        VideoManager.cleanup()
        ScreenCaptureManager.availableContent = nil
    }
    
    private func cleanupAllManagers() {
        AudioManager.cleanupAudioFiles()
        AudioManager.stopAudioEngine()
        AudioManager.resetAudioEngine()
        VideoManager.cleanup()
        RecordingStateManager.resetState()
    }
    
    private func createMockShareableContent() -> SCShareableContent {
        let mockDisplay = MockSCDisplay()
        let mockWindow1 = MockSCWindow(bundleIdentifier: "com.example.app1")
        let mockWindow2 = MockSCWindow(bundleIdentifier: "com.example.app2")
        let mockApp = MockSCRunningApplication(bundleIdentifier: "com.example.app1")
        
        return MockSCShareableContent(displays: [mockDisplay], windows: [mockWindow1, mockWindow2], applications: [mockApp])
    }
    
    private func createMockShareableContentWithManyWindows() -> SCShareableContent {
        let mockDisplay = MockSCDisplay()
        var windows: [SCWindow] = []
        var applications: [SCRunningApplication] = []
        
        // Create many windows and applications
        for i in 0..<100 {
            let bundleID = "com.example.app\(i)"
            windows.append(MockSCWindow(bundleIdentifier: bundleID))
            applications.append(MockSCRunningApplication(bundleIdentifier: bundleID))
        }
        
        return MockSCShareableContent(displays: [mockDisplay], windows: windows, applications: applications)
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
            throw NSError(domain: "PerformanceValidationTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create format description"])
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
            throw NSError(domain: "PerformanceValidationTests", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create sample buffer"])
        }
        
        return buffer
    }
    
    private func measureTime(_ operation: () -> Void) -> TimeInterval {
        let startTime = CFAbsoluteTimeGetCurrent()
        operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return timeElapsed
    }
    
    private func getCurrentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return info.resident_size
        } else {
            return 0
        }
    }
}
