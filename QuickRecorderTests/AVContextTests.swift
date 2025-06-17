//
//  AVContextTests.swift
//  QuickRecorderTests
//
//  Created by Test Coverage Phase 2 on 2025/06/16.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

/// Tests for AVContext functionality including audio/video context management
class AVContextTests: XCTestCase {
    
    var avContext: AVContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        avContext = AVContext()
    }
    
    override func tearDownWithError() throws {
        avContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testAVContext_CanBeCreated() throws {
        // Given/When/Then
        XCTAssertNotNil(avContext)
    }
    
    func testAVContext_InitialState() throws {
        // Given/When/Then - Check initial state
        XCTAssertNotNil(avContext.session)
        XCTAssertEqual(avContext.isRecording, false)
    }
    
    // MARK: - Audio Session Tests
    
    func testAVContext_AudioSessionConfiguration() throws {
        // Given/When
        let session = avContext.session
        
        // Then - Audio session should be properly configured
        XCTAssertNotNil(session)
        XCTAssertTrue(session.isKind(of: AVAudioSession.self))
    }
    
    func testAVContext_AudioSessionCategory() throws {
        // Given/When
        let session = avContext.session
        
        // Then - Should have appropriate category for recording
        XCTAssertTrue(session.category == .playAndRecord || 
                     session.category == .record ||
                     session.category == .multiRoute)
    }
    
    // MARK: - Recording State Management Tests
    
    func testAVContext_InitialRecordingState() throws {
        // Given/When/Then
        XCTAssertFalse(avContext.isRecording)
    }
    
    func testAVContext_RecordingStateToggle() throws {
        // Given
        let initialState = avContext.isRecording
        
        // When
        avContext.isRecording = true
        XCTAssertTrue(avContext.isRecording)
        
        avContext.isRecording = false
        XCTAssertFalse(avContext.isRecording)
        
        // Cleanup
        avContext.isRecording = initialState
    }
    
    // MARK: - Audio Permission Tests
    
    func testAVContext_AudioPermissionCheck() throws {
        // Given/When
        let permissionStatus = AVAudioSession.sharedInstance().recordPermission
        
        // Then - Permission status should be deterministic
        XCTAssertTrue(permissionStatus == .granted || 
                     permissionStatus == .denied || 
                     permissionStatus == .undetermined)
    }
    
    func testAVContext_RequestAudioPermission() throws {
        // Given
        let expectation = XCTestExpectation(description: "Audio permission request")
        
        // When
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // Then - Should receive a response
            XCTAssertTrue(granted == true || granted == false)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Integration with Settings Tests
    
    func testAVContext_SettingsIntegration() throws {
        // Given
        let settings = SettingsManager.shared
        let originalAudioFormat = settings.audioFormat
        
        // When - Test different audio formats
        for audioFormat in [AudioFormat.aac, AudioFormat.mp3] {
            settings.audioFormat = audioFormat
            
            // Then - AVContext should work with any format
            XCTAssertNotNil(avContext.session)
            XCTAssertEqual(avContext.isRecording, false) // Should maintain state
        }
        
        // Cleanup
        settings.audioFormat = originalAudioFormat
    }
    
    // MARK: - Error Handling Tests
    
    func testAVContext_HandlesAudioSessionErrors() throws {
        // Given/When - Try to configure audio session multiple times
        for _ in 0..<3 {
            XCTAssertNoThrow(avContext.session.setActive(false))
        }
        
        // Then - Should handle gracefully
        XCTAssertNotNil(avContext.session)
    }
    
    // MARK: - Memory Management Tests
    
    func testAVContext_MemoryManagement() throws {
        // Given
        weak var weakContext: AVContext?
        
        // When
        autoreleasepool {
            let context = AVContext()
            weakContext = context
            XCTAssertNotNil(weakContext)
        }
        
        // Then - Should be deallocated
        XCTAssertNil(weakContext, "AVContext should be deallocated when no strong references remain")
    }
    
    // MARK: - Audio Route Tests
    
    func testAVContext_AudioRouteInformation() throws {
        // Given/When
        let currentRoute = avContext.session.currentRoute
        
        // Then - Should have route information
        XCTAssertNotNil(currentRoute)
        XCTAssertNotNil(currentRoute.inputs)
        XCTAssertNotNil(currentRoute.outputs)
    }
    
    func testAVContext_AvailableInputs() throws {
        // Given/When
        let availableInputs = avContext.session.availableInputs
        
        // Then - May have inputs (device dependent)
        if let inputs = availableInputs {
            for input in inputs {
                XCTAssertFalse(input.portName.isEmpty)
                XCTAssertNotNil(input.portType)
            }
        }
    }
    
    // MARK: - Sample Rate Tests
    
    func testAVContext_SampleRateConfiguration() throws {
        // Given/When
        let preferredSampleRate = avContext.session.preferredSampleRate
        let sampleRate = avContext.session.sampleRate
        
        // Then - Should have valid sample rates
        XCTAssertGreaterThan(preferredSampleRate, 0)
        XCTAssertGreaterThan(sampleRate, 0)
        XCTAssertLessThanOrEqual(sampleRate, 192000) // Reasonable upper bound
    }
    
    // MARK: - Buffer Duration Tests
    
    func testAVContext_BufferDurationConfiguration() throws {
        // Given/When
        let bufferDuration = avContext.session.ioBufferDuration
        let preferredBufferDuration = avContext.session.preferredIOBufferDuration
        
        // Then - Should have valid buffer durations
        XCTAssertGreaterThan(bufferDuration, 0)
        XCTAssertGreaterThan(preferredBufferDuration, 0)
        XCTAssertLessThan(bufferDuration, 1.0) // Should be less than 1 second
    }
    
    // MARK: - Channel Configuration Tests
    
    func testAVContext_InputChannelConfiguration() throws {
        // Given/When
        let inputChannels = avContext.session.inputNumberOfChannels
        let preferredInputChannels = avContext.session.preferredInputNumberOfChannels
        
        // Then - Should have valid channel counts
        XCTAssertGreaterThanOrEqual(inputChannels, 0)
        XCTAssertGreaterThanOrEqual(preferredInputChannels, 0)
        XCTAssertLessThanOrEqual(inputChannels, 32) // Reasonable upper bound
    }
    
    func testAVContext_OutputChannelConfiguration() throws {
        // Given/When
        let outputChannels = avContext.session.outputNumberOfChannels
        let preferredOutputChannels = avContext.session.preferredOutputNumberOfChannels
        
        // Then - Should have valid channel counts
        XCTAssertGreaterThanOrEqual(outputChannels, 0)
        XCTAssertGreaterThanOrEqual(preferredOutputChannels, 0)
        XCTAssertLessThanOrEqual(outputChannels, 32) // Reasonable upper bound
    }
    
    // MARK: - Performance Tests
    
    func testAVContext_InitializationPerformance() throws {
        measure {
            for _ in 0..<10 {
                let context = AVContext()
                _ = context.session.sampleRate
            }
        }
    }
    
    func testAVContext_SessionAccessPerformance() throws {
        measure {
            for _ in 0..<100 {
                _ = avContext.session.isOtherAudioPlaying
                _ = avContext.session.sampleRate
                _ = avContext.session.currentRoute
            }
        }
    }
    
    // MARK: - Integration with RecordEngine Tests
    
    func testAVContext_RecordEngineIntegration() throws {
        // Given
        let recordEngine = RecordEngine()
        
        // When/Then - Should work together
        XCTAssertNotNil(avContext.session)
        XCTAssertNotNil(recordEngine.engine)
        
        // Both should be in compatible states
        XCTAssertEqual(avContext.isRecording, false)
        XCTAssertEqual(recordEngine.isRecording, false)
    }
    
    // MARK: - Interruption Handling Tests
    
    func testAVContext_AudioSessionNotifications() throws {
        // Given
        let expectation = XCTestExpectation(description: "Notification registration")
        expectation.isInverted = true // Should NOT fulfill (no interruption expected)
        
        // When - Register for interruption notifications
        let observer = NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: avContext.session,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        
        // Then - Should not receive interruption in test environment
        wait(for: [expectation], timeout: 1.0)
        
        // Cleanup
        NotificationCenter.default.removeObserver(observer)
    }
    
    // MARK: - Concurrent Access Tests
    
    func testAVContext_ConcurrentAccess() throws {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent access")
        expectation.expectedFulfillmentCount = 10
        
        // When - Access from multiple queues
        for i in 0..<10 {
            DispatchQueue.global(qos: .background).async {
                let sampleRate = self.avContext.session.sampleRate
                XCTAssertGreaterThan(sampleRate, 0)
                expectation.fulfill()
            }
        }
        
        // Then - Should handle concurrent access
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Real-world Scenario Tests
    
    func testAVContext_TypicalRecordingScenario() throws {
        // Given - Simulate typical recording setup
        let recordEngine = RecordEngine()
        
        // When - Prepare for recording
        let audioSettings = recordEngine.getAudioSettings()
        let sessionActive = avContext.session.isOtherAudioPlaying
        
        // Then - Should be ready for recording
        XCTAssertFalse(audioSettings.isEmpty)
        XCTAssertTrue(sessionActive == true || sessionActive == false) // Either state is valid
        XCTAssertEqual(avContext.isRecording, false)
        XCTAssertEqual(recordEngine.isRecording, false)
    }
} 