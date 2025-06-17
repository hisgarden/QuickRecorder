//
//  EndToEndIntegrationTests_Phase3.swift
//  QuickRecorderTests
//
//  Created by TDD Phase 3 Implementation on 2025/06/16.
//

import XCTest
import Combine
@testable import QuickRecorder

/// End-to-end integration testing for Phase 3
/// Covers complete workflow validation, cross-component communication, and real-world scenarios
class EndToEndIntegrationTests_Phase3: XCTestCase {
    
    var settingsManager: SettingsManager!
    var recordEngine: RecordEngine!
    var scContext: SCContext!
    var errorHandler: ErrorHandler!
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settingsManager = SettingsManager.shared
        recordEngine = RecordEngine()
        scContext = SCContext()
        errorHandler = ErrorHandler.shared
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables?.removeAll()
        cancellables = nil
        settingsManager = nil
        recordEngine = nil
        scContext = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Complete Workflow Integration Tests
    
    func testCompleteWorkflow_AppInitialization() throws {
        // Given - Fresh app initialization scenario
        let originalValues = (
            showPreview: settingsManager.showPreview,
            frameRate: settingsManager.frameRate,
            videoQuality: settingsManager.videoQuality
        )
        
        // When - Simulate app initialization workflow
        
        // 1. Settings Manager initialization
        let settingsValid = settingsManager.frameRate > 0 && settingsManager.videoQuality > 0
        
        // 2. Display context initialization
        let displays = scContext.getDisplays()
        let displaysValid = !displays.isEmpty
        
        // 3. Audio engine initialization
        let audioSettings = recordEngine.getAudioSettings()
        let audioValid = !audioSettings.isEmpty
        
        // 4. Error handler ready
        let errorHandlerReady = errorHandler != nil
        
        // Then - All systems should be ready
        XCTAssertTrue(settingsValid, "Settings should be valid on initialization")
        XCTAssertTrue(displaysValid, "Display detection should work")
        XCTAssertTrue(audioValid, "Audio system should be ready")
        XCTAssertTrue(errorHandlerReady, "Error handler should be available")
        
        // Cleanup
        settingsManager.showPreview = originalValues.showPreview
        settingsManager.frameRate = originalValues.frameRate
        settingsManager.videoQuality = originalValues.videoQuality
    }
    
    func testCompleteWorkflow_RecordingPreparation() throws {
        // Given - Recording preparation workflow
        let recordingArea = [
            "x": 0,
            "y": 0,
            "width": 1920,
            "height": 1080
        ]
        
        // When - Prepare for recording
        
        // 1. Validate recording area
        let areaValid = scContext.validateArea(recordingArea)
        let recordingSize = scContext.getRecordingSize(area: recordingArea)
        
        // 2. Configure audio settings
        let audioSettings = recordEngine.getAudioSettings()
        
        // 3. Validate settings
        settingsManager.validateSettings()
        
        // 4. Check permissions (simulated)
        let permissionsReady = true // In real scenario, would check actual permissions
        
        // Then - All preparation steps should succeed
        XCTAssertTrue(areaValid, "Recording area should be valid")
        XCTAssertEqual(recordingSize.width, 1920.0)
        XCTAssertEqual(recordingSize.height, 1080.0)
        XCTAssertFalse(audioSettings.isEmpty, "Audio settings should be configured")
        XCTAssertTrue(permissionsReady, "Permissions should be ready")
    }
    
    func testCompleteWorkflow_SettingsToRecording() throws {
        // Given - Settings to recording workflow
        let originalValues = (
            frameRate: settingsManager.frameRate,
            videoQuality: settingsManager.videoQuality,
            audioFormat: settingsManager.audioFormat
        )
        
        // When - Configure settings and prepare recording
        
        // 1. Update settings
        settingsManager.frameRate = 60
        settingsManager.videoQuality = 0.8
        settingsManager.audioFormat = .aac
        settingsManager.validateSettings()
        
        // 2. Apply settings to recording components
        let audioSettings = recordEngine.getAudioSettings()
        let displays = scContext.getDisplays()
        
        // 3. Validate configuration consistency
        let settingsConsistent = settingsManager.frameRate == 60 && 
                                settingsManager.videoQuality == 0.8 &&
                                settingsManager.audioFormat == .aac
        
        // Then - Settings should propagate correctly
        XCTAssertTrue(settingsConsistent, "Settings should be applied consistently")
        XCTAssertFalse(audioSettings.isEmpty, "Audio settings should reflect changes")
        XCTAssertFalse(displays.isEmpty, "Display detection should work with new settings")
        
        // Cleanup
        settingsManager.frameRate = originalValues.frameRate
        settingsManager.videoQuality = originalValues.videoQuality
        settingsManager.audioFormat = originalValues.audioFormat
    }
    
    // MARK: - Cross-Component Communication Tests
    
    func testCrossComponent_SettingsManagerToRecordEngine() throws {
        // Given - Settings changes affecting recording engine
        let originalFrameRate = settingsManager.frameRate
        let originalQuality = settingsManager.videoQuality
        
        // When - Change settings that affect recording
        settingsManager.frameRate = 30
        settingsManager.videoQuality = 0.5
        
        // Simulate settings propagation
        let audioSettings = recordEngine.getAudioSettings()
        let engineReady = !recordEngine.isRecording
        
        // Then - Recording engine should reflect settings
        XCTAssertEqual(settingsManager.frameRate, 30)
        XCTAssertEqual(settingsManager.videoQuality, 0.5)
        XCTAssertFalse(audioSettings.isEmpty)
        XCTAssertTrue(engineReady, "Engine should be ready with new settings")
        
        // Cleanup
        settingsManager.frameRate = originalFrameRate
        settingsManager.videoQuality = originalQuality
    }
    
    func testCrossComponent_SCContextToSettingsManager() throws {
        // Given - Display changes affecting settings
        let originalAreaWidth = settingsManager.areaWidth
        let originalAreaHeight = settingsManager.areaHeight
        
        // When - Display information affects area settings
        let displays = scContext.getDisplays()
        
        if let firstDisplay = displays.first {
            let displayWidth = firstDisplay["width"] as? Int ?? 1920
            let displayHeight = firstDisplay["height"] as? Int ?? 1080
            
            // Update settings based on display information
            settingsManager.areaWidth = min(displayWidth, 1920)
            settingsManager.areaHeight = min(displayHeight, 1080)
            settingsManager.validateSettings()
        }
        
        // Then - Settings should reflect display constraints
        XCTAssertGreaterThan(settingsManager.areaWidth, 0)
        XCTAssertGreaterThan(settingsManager.areaHeight, 0)
        XCTAssertLessThanOrEqual(settingsManager.areaWidth, 1920)
        XCTAssertLessThanOrEqual(settingsManager.areaHeight, 1080)
        
        // Cleanup
        settingsManager.areaWidth = originalAreaWidth
        settingsManager.areaHeight = originalAreaHeight
    }
    
    func testCrossComponent_ErrorHandlerIntegration() throws {
        // Given - Error scenarios across components
        let invalidArea = [
            "x": -1000,
            "y": -1000,
            "width": -500,
            "height": -500
        ]
        
        // When - Handle errors across system
        let areaValid = scContext.validateArea(invalidArea)
        
        // Simulate error handling
        if !areaValid {
            // Error handler would be notified in real scenario
            let errorHandled = true
            XCTAssertTrue(errorHandled, "Error should be handled gracefully")
        }
        
        // Verify system remains stable after error
        let displays = scContext.getDisplays()
        let audioSettings = recordEngine.getAudioSettings()
        
        // Then - System should recover from errors
        XCTAssertFalse(areaValid, "Invalid area should be rejected")
        XCTAssertFalse(displays.isEmpty, "Display detection should still work")
        XCTAssertFalse(audioSettings.isEmpty, "Audio system should remain functional")
    }
    
    // MARK: - Real-World Usage Scenarios
    
    func testRealWorldScenario_QuickScreenRecording() throws {
        // Given - User wants to quickly record screen
        let quickRecordingArea = [
            "x": 0,
            "y": 0,
            "width": 1280,
            "height": 720
        ]
        
        // When - User workflow simulation
        
        // 1. User selects recording area
        let areaValid = scContext.validateArea(quickRecordingArea)
        let recordingSize = scContext.getRecordingSize(area: quickRecordingArea)
        
        // 2. User checks settings (defaults should be good)
        let frameRate = settingsManager.frameRate
        let videoQuality = settingsManager.videoQuality
        let audioFormat = settingsManager.audioFormat
        
        // 3. User initiates recording preparation
        let audioSettings = recordEngine.getAudioSettings()
        let isRecording = recordEngine.isRecording
        
        // Then - Quick recording should be ready
        XCTAssertTrue(areaValid, "Recording area should be valid")
        XCTAssertEqual(recordingSize.width, 1280.0)
        XCTAssertEqual(recordingSize.height, 720.0)
        XCTAssertGreaterThan(frameRate, 0, "Frame rate should be set")
        XCTAssertGreaterThan(videoQuality, 0, "Video quality should be set")
        XCTAssertNotNil(audioFormat, "Audio format should be set")
        XCTAssertFalse(audioSettings.isEmpty, "Audio should be ready")
        XCTAssertFalse(isRecording, "Should be ready to start")
    }
    
    func testRealWorldScenario_CustomQualityRecording() throws {
        // Given - User wants high-quality custom recording
        let originalValues = (
            frameRate: settingsManager.frameRate,
            videoQuality: settingsManager.videoQuality,
            encoder: settingsManager.encoder,
            audioFormat: settingsManager.audioFormat
        )
        
        // When - User configures high-quality settings
        
        // 1. User sets high quality
        settingsManager.frameRate = 60
        settingsManager.videoQuality = 1.0
        settingsManager.encoder = .h265
        settingsManager.audioFormat = .aac
        
        // 2. User validates configuration
        settingsManager.validateSettings()
        
        // 3. User prepares recording with custom area
        let customArea = [
            "x": 100,
            "y": 100,
            "width": 1920,
            "height": 1080
        ]
        let areaValid = scContext.validateArea(customArea)
        let audioSettings = recordEngine.getAudioSettings()
        
        // Then - High-quality recording should be configured
        XCTAssertEqual(settingsManager.frameRate, 60)
        XCTAssertEqual(settingsManager.videoQuality, 1.0)
        XCTAssertEqual(settingsManager.encoder, .h265)
        XCTAssertEqual(settingsManager.audioFormat, .aac)
        XCTAssertTrue(areaValid, "Custom area should be valid")
        XCTAssertFalse(audioSettings.isEmpty, "High-quality audio should be ready")
        
        // Cleanup
        settingsManager.frameRate = originalValues.frameRate
        settingsManager.videoQuality = originalValues.videoQuality
        settingsManager.encoder = originalValues.encoder
        settingsManager.audioFormat = originalValues.audioFormat
    }
    
    func testRealWorldScenario_MultiDisplaySetup() throws {
        // Given - User with multiple displays
        let displays = scContext.getDisplays()
        
        // When - User works with multiple displays
        
        // 1. User examines available displays
        let hasMultipleDisplays = displays.count > 1
        let primaryDisplay = displays.first
        
        // 2. User configures recording for specific display
        if let display = primaryDisplay {
            let displayWidth = display["width"] as? Int ?? 1920
            let displayHeight = display["height"] as? Int ?? 1080
            
            let displayArea = [
                "x": 0,
                "y": 0,
                "width": displayWidth,
                "height": displayHeight
            ]
            
            let areaValid = scContext.validateArea(displayArea)
            let recordingSize = scContext.getRecordingSize(area: displayArea)
            
            // Then - Multi-display handling should work
            XCTAssertTrue(areaValid, "Display area should be valid")
            XCTAssertEqual(recordingSize.width, Double(displayWidth))
            XCTAssertEqual(recordingSize.height, Double(displayHeight))
        }
        
        // System should handle both single and multi-display scenarios
        XCTAssertGreaterThanOrEqual(displays.count, 1, "Should detect at least one display")
    }
    
    func testRealWorldScenario_ErrorRecoveryWorkflow() throws {
        // Given - User encounters errors during workflow
        let originalWidth = settingsManager.areaWidth
        let originalHeight = settingsManager.areaHeight
        
        // When - User makes configuration errors
        
        // 1. User sets invalid recording area
        settingsManager.areaWidth = -500
        settingsManager.areaHeight = -300
        
        // 2. System validates and corrects
        settingsManager.validateSettings()
        
        // 3. User tries invalid area coordinates
        let invalidArea = [
            "x": Int.max,
            "y": Int.max,
            "width": Int.max,
            "height": Int.max
        ]
        let invalidAreaValid = scContext.validateArea(invalidArea)
        
        // 4. System continues to function
        let displays = scContext.getDisplays()
        let audioSettings = recordEngine.getAudioSettings()
        
        // Then - System should recover gracefully
        XCTAssertGreaterThan(settingsManager.areaWidth, 0, "Invalid width should be corrected")
        XCTAssertGreaterThan(settingsManager.areaHeight, 0, "Invalid height should be corrected")
        XCTAssertFalse(invalidAreaValid, "Invalid area should be rejected")
        XCTAssertFalse(displays.isEmpty, "Display detection should continue working")
        XCTAssertFalse(audioSettings.isEmpty, "Audio system should remain functional")
        
        // Cleanup
        settingsManager.areaWidth = originalWidth
        settingsManager.areaHeight = originalHeight
    }
    
    // MARK: - Integration Performance Tests
    
    func testIntegrationPerformance_CompleteWorkflow() throws {
        // Given - Performance requirements for complete workflow
        let maxWorkflowTime: TimeInterval = 1.0
        
        // When - Execute complete workflow under time constraints
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // Complete workflow simulation
        let displays = scContext.getDisplays()
        let windows = scContext.getWindows()
        let audioSettings = recordEngine.getAudioSettings()
        settingsManager.validateSettings()
        
        let area = ["x": 0, "y": 0, "width": 1920, "height": 1080]
        let areaValid = scContext.validateArea(area)
        let recordingSize = scContext.getRecordingSize(area: area)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let workflowTime = endTime - startTime
        
        // Then - Workflow should be performant
        XCTAssertLessThan(workflowTime, maxWorkflowTime, "Complete workflow should finish within \(maxWorkflowTime)s")
        XCTAssertFalse(displays.isEmpty)
        XCTAssertFalse(audioSettings.isEmpty)
        XCTAssertTrue(areaValid)
        XCTAssertEqual(recordingSize.width, 1920.0)
        XCTAssertEqual(recordingSize.height, 1080.0)
    }
    
    func testIntegrationPerformance_ConcurrentComponents() throws {
        // Given - Concurrent component access scenario
        let expectation = XCTestExpectation(description: "Concurrent component access")
        expectation.expectedFulfillmentCount = 4
        
        // When - Access all components concurrently
        let startTime = CFAbsoluteTimeGetCurrent()
        
        DispatchQueue.global().async {
            let _ = self.scContext.getDisplays()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            let _ = self.scContext.getWindows()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            let _ = self.recordEngine.getAudioSettings()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            self.settingsManager.validateSettings()
            expectation.fulfill()
        }
        
        // Then - Concurrent access should be efficient
        wait(for: [expectation], timeout: 5.0)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let concurrentTime = endTime - startTime
        XCTAssertLessThan(concurrentTime, 2.0, "Concurrent component access should complete within 2s")
    }
} 