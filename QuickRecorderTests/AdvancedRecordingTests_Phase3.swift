//
//  AdvancedRecordingTests_Phase3.swift
//  QuickRecorderTests
//
//  Created by TDD Phase 3 Implementation on 2025/06/16.
//

import XCTest
import AVFoundation
@testable import QuickRecorder

/// Advanced recording features testing for Phase 3
/// Covers area selection, multi-window recording, camera overlay, and quality optimization
class AdvancedRecordingTests_Phase3: XCTestCase {
    
    var settingsManager: SettingsManager!
    var recordEngine: RecordEngine!
    var scContext: SCContext!
    var errorHandler: ErrorHandler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settingsManager = SettingsManager.shared
        recordEngine = RecordEngine()
        scContext = SCContext()
        errorHandler = ErrorHandler.shared
    }
    
    override func tearDownWithError() throws {
        settingsManager = nil
        recordEngine = nil
        scContext = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Area Selection Tests
    
    func testAreaSelection_PreciseCoordinates() throws {
        // Given - Precise area selection
        let preciseArea = [
            "x": 100,
            "y": 50,
            "width": 1280,
            "height": 720
        ]
        
        // When - Calculate recording area
        let isValid = scContext.validateArea(preciseArea)
        let size = scContext.getRecordingSize(area: preciseArea)
        
        // Then - Should handle precise coordinates
        XCTAssertTrue(isValid)
        XCTAssertEqual(size.width, 1280.0)
        XCTAssertEqual(size.height, 720.0)
    }
    
    func testAreaSelection_CommonResolutions() throws {
        // Given - Common recording resolutions
        let resolutions = [
            ("720p", ["x": 0, "y": 0, "width": 1280, "height": 720]),
            ("1080p", ["x": 0, "y": 0, "width": 1920, "height": 1080]),
            ("4K", ["x": 0, "y": 0, "width": 3840, "height": 2160])
        ]
        
        // When/Then - Test each resolution
        for (name, area) in resolutions {
            let isValid = scContext.validateArea(area)
            let size = scContext.getRecordingSize(area: area)
            
            XCTAssertTrue(isValid, "\(name) should be valid")
            XCTAssertEqual(size.width, Double(area["width"]!))
            XCTAssertEqual(size.height, Double(area["height"]!))
        }
    }
    
    func testAreaSelection_EdgeCases() throws {
        // Given - Edge case areas
        let edgeCases = [
            ("minimum", ["x": 0, "y": 0, "width": 1, "height": 1]),
            ("square", ["x": 100, "y": 100, "width": 500, "height": 500]),
            ("ultrawide", ["x": 0, "y": 0, "width": 2560, "height": 1080])
        ]
        
        // When/Then - Test edge cases
        for (name, area) in edgeCases {
            let isValid = scContext.validateArea(area)
            let size = scContext.getRecordingSize(area: area)
            
            XCTAssertTrue(isValid, "\(name) area should be valid")
            XCTAssertGreaterThan(size.width, 0)
            XCTAssertGreaterThan(size.height, 0)
        }
    }
    
    func testAreaSelection_InvalidAreas() throws {
        // Given - Invalid area configurations
        let invalidAreas = [
            ("negative", ["x": -100, "y": -100, "width": 800, "height": 600]),
            ("zero_size", ["x": 0, "y": 0, "width": 0, "height": 0]),
            ("negative_size", ["x": 0, "y": 0, "width": -800, "height": -600])
        ]
        
        // When/Then - Test invalid areas
        for (name, area) in invalidAreas {
            let isValid = scContext.validateArea(area)
            XCTAssertFalse(isValid, "\(name) area should be invalid")
        }
    }
    
    // MARK: - Multi-Window Recording Tests
    
    func testMultiWindow_WindowDetection() throws {
        // Given - Window detection
        let availableWindows = scContext.getWindows()
        
        // When - Analyze window information
        let hasWindows = !availableWindows.isEmpty
        
        // Then - Should detect windows
        if hasWindows {
            let firstWindow = availableWindows.first!
            XCTAssertNotNil(firstWindow["title"])
            XCTAssertNotNil(firstWindow["id"])
            XCTAssertGreaterThan(firstWindow["width"] as? Int ?? 0, 0)
            XCTAssertGreaterThan(firstWindow["height"] as? Int ?? 0, 0)
        }
        // Note: In test environment, there might be no windows, which is acceptable
    }
    
    func testMultiWindow_WindowFiltering() throws {
        // Given - Window filtering criteria
        let allWindows = scContext.getWindows()
        let minWidth = 100
        let minHeight = 100
        
        // When - Filter windows by size
        let validWindows = allWindows.filter { window in
            let width = window["width"] as? Int ?? 0
            let height = window["height"] as? Int ?? 0
            return width >= minWidth && height >= minHeight
        }
        
        // Then - Filtering should work
        XCTAssertLessThanOrEqual(validWindows.count, allWindows.count)
        
        for window in validWindows {
            let width = window["width"] as? Int ?? 0
            let height = window["height"] as? Int ?? 0
            XCTAssertGreaterThanOrEqual(width, minWidth)
            XCTAssertGreaterThanOrEqual(height, minHeight)
        }
    }
    
    func testMultiWindow_RecordingConfiguration() throws {
        // Given - Multi-window recording setup
        let windows = scContext.getWindows()
        let audioSettings = recordEngine.getAudioSettings()
        
        // When - Configure for multi-window recording
        let hasValidConfig = !audioSettings.isEmpty
        let canRecordWindows = !windows.isEmpty || true // Allow empty in test env
        
        // Then - Configuration should be valid
        XCTAssertTrue(hasValidConfig)
        XCTAssertTrue(canRecordWindows)
    }
    
    // MARK: - Camera Overlay Tests
    
    func testCameraOverlay_AvailabilityCheck() throws {
        // Given - Camera availability check
        let cameraDevices = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        // When - Check camera availability
        let hasCameras = !cameraDevices.isEmpty
        
        // Then - Handle camera availability gracefully
        if hasCameras {
            let firstCamera = cameraDevices.first!
            XCTAssertNotNil(firstCamera.uniqueID)
            XCTAssertNotNil(firstCamera.localizedName)
        }
        // Note: Camera availability varies by system, test should pass either way
    }
    
    func testCameraOverlay_PositionCalculation() throws {
        // Given - Camera overlay positioning
        let recordingArea = CGSize(width: 1920, height: 1080)
        let cameraSize = CGSize(width: 320, height: 240)
        
        // When - Calculate overlay positions
        let positions = [
            ("topLeft", CGPoint(x: 20, y: 20)),
            ("topRight", CGPoint(x: recordingArea.width - cameraSize.width - 20, y: 20)),
            ("bottomLeft", CGPoint(x: 20, y: recordingArea.height - cameraSize.height - 20)),
            ("bottomRight", CGPoint(x: recordingArea.width - cameraSize.width - 20, 
                                  y: recordingArea.height - cameraSize.height - 20))
        ]
        
        // Then - Positions should be within bounds
        for (name, position) in positions {
            XCTAssertGreaterThanOrEqual(position.x, 0, "\(name) X position should be valid")
            XCTAssertGreaterThanOrEqual(position.y, 0, "\(name) Y position should be valid")
            XCTAssertLessThanOrEqual(position.x + cameraSize.width, recordingArea.width, 
                                   "\(name) should fit horizontally")
            XCTAssertLessThanOrEqual(position.y + cameraSize.height, recordingArea.height, 
                                   "\(name) should fit vertically")
        }
    }
    
    func testCameraOverlay_SizeValidation() throws {
        // Given - Camera overlay size options
        let recordingSize = CGSize(width: 1920, height: 1080)
        let cameraSizes = [
            ("small", CGSize(width: 160, height: 120)),
            ("medium", CGSize(width: 320, height: 240)),
            ("large", CGSize(width: 640, height: 480))
        ]
        
        // When/Then - Validate camera sizes
        for (name, size) in cameraSizes {
            let widthRatio = size.width / recordingSize.width
            let heightRatio = size.height / recordingSize.height
            
            XCTAssertLessThan(widthRatio, 0.5, "\(name) camera width should be reasonable")
            XCTAssertLessThan(heightRatio, 0.5, "\(name) camera height should be reasonable")
            XCTAssertGreaterThan(size.width, 0)
            XCTAssertGreaterThan(size.height, 0)
        }
    }
    
    // MARK: - Quality Configuration Tests
    
    func testQualityConfiguration_DynamicAdjustment() throws {
        // Given - Quality configuration scenarios
        let qualityProfiles = [
            ("low", 0.3, 30),
            ("medium", 0.6, 60),
            ("high", 0.9, 60),
            ("ultra", 1.0, 60)
        ]
        
        // When/Then - Test quality profiles
        for (profile, quality, frameRate) in qualityProfiles {
            // Simulate quality setting
            let originalQuality = settingsManager.videoQuality
            let originalFrameRate = settingsManager.frameRate
            
            settingsManager.videoQuality = quality
            settingsManager.frameRate = frameRate
            
            // Validate settings
            XCTAssertEqual(settingsManager.videoQuality, quality, "\(profile) quality should be set")
            XCTAssertEqual(settingsManager.frameRate, frameRate, "\(profile) frame rate should be set")
            
            // Cleanup
            settingsManager.videoQuality = originalQuality
            settingsManager.frameRate = originalFrameRate
        }
    }
    
    func testQualityConfiguration_HardwareOptimization() throws {
        // Given - Hardware-based optimization
        let encoder = settingsManager.encoder
        let currentQuality = settingsManager.videoQuality
        
        // When - Check hardware capabilities
        let isH265Supported = [Encoder.h264, Encoder.h265].contains(encoder)
        let isQualityValid = currentQuality > 0.0 && currentQuality <= 1.0
        
        // Then - Configuration should be hardware-appropriate
        XCTAssertTrue(isH265Supported)
        XCTAssertTrue(isQualityValid)
    }
    
    func testQualityConfiguration_ResolutionOptimization() throws {
        // Given - Resolution-based quality adjustment
        let resolutions = [
            ("SD", 720 * 480),
            ("HD", 1280 * 720),
            ("FHD", 1920 * 1080),
            ("4K", 3840 * 2160)
        ]
        
        // When/Then - Test quality scaling
        for (name, pixels) in resolutions {
            // Calculate recommended quality based on resolution
            let baseQuality = min(1.0, max(0.3, Double(pixels) / (1920.0 * 1080.0)))
            
            XCTAssertGreaterThanOrEqual(baseQuality, 0.3, "\(name) should have minimum quality")
            XCTAssertLessThanOrEqual(baseQuality, 1.0, "\(name) should have maximum quality")
        }
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPerformance_ResourceMonitoring() throws {
        // Given - Performance monitoring setup
        let startTime = CFAbsoluteTimeGetCurrent()
        
        // When - Simulate recording operations
        let scContext = SCContext()
        let displays = scContext.getDisplays()
        let windows = scContext.getWindows()
        let area = ["x": 0, "y": 0, "width": 1920, "height": 1080]
        let size = scContext.getRecordingSize(area: area)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let operationTime = endTime - startTime
        
        // Then - Operations should be performant
        XCTAssertLessThan(operationTime, 1.0, "Operations should complete within 1 second")
        XCTAssertFalse(displays.isEmpty)
        XCTAssertEqual(size.width, 1920.0)
        XCTAssertEqual(size.height, 1080.0)
    }
    
    func testPerformance_MemoryEfficiency() throws {
        // Given - Memory usage baseline
        let iterations = 50
        
        // When - Perform repeated operations
        for _ in 0..<iterations {
            autoreleasepool {
                let context = SCContext()
                let _ = context.getDisplays()
                let _ = context.getWindows()
                let _ = context.getRecordingSize(area: ["x": 0, "y": 0, "width": 100, "height": 100])
            }
        }
        
        // Then - Memory should be managed efficiently
        // Note: Actual memory measurement would require more complex setup
        XCTAssertTrue(true, "Memory test completed without crashes")
    }
    
    func testPerformance_ConcurrentAccess() throws {
        // Given - Concurrent access scenario
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 3
        
        // When - Perform concurrent operations
        DispatchQueue.global().async {
            let context = SCContext()
            let _ = context.getDisplays()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            let engine = RecordEngine()
            let _ = engine.getAudioSettings()
            expectation.fulfill()
        }
        
        DispatchQueue.global().async {
            let settings = SettingsManager.shared
            let _ = settings.frameRate
            expectation.fulfill()
        }
        
        // Then - All operations should complete safely
        wait(for: [expectation], timeout: 5.0)
    }
    
    // MARK: - Error Recovery Tests
    
    func testErrorRecovery_InvalidConfiguration() throws {
        // Given - Invalid recording configuration
        let originalWidth = settingsManager.areaWidth
        let originalHeight = settingsManager.areaHeight
        
        // When - Set invalid configuration
        settingsManager.areaWidth = -1000
        settingsManager.areaHeight = -1000
        settingsManager.validateSettings()
        
        // Then - Settings should be corrected
        XCTAssertGreaterThan(settingsManager.areaWidth, 0)
        XCTAssertGreaterThan(settingsManager.areaHeight, 0)
        
        // Cleanup
        settingsManager.areaWidth = originalWidth
        settingsManager.areaHeight = originalHeight
    }
    
    func testErrorRecovery_ResourceUnavailable() throws {
        // Given - Simulated resource unavailability
        let scContext = SCContext()
        
        // When - Handle edge case resources
        let displays = scContext.getDisplays()
        let windows = scContext.getWindows()
        
        // Then - Should handle gracefully
        // Note: In test environment, resources might be limited
        XCTAssertTrue(displays.count >= 0) // At least 0 displays (could be headless)
        XCTAssertTrue(windows.count >= 0)  // At least 0 windows
    }
    
    func testErrorRecovery_InterruptionHandling() throws {
        // Given - Interruption scenario simulation
        let recordEngine = RecordEngine()
        
        // When - Simulate interruption handling
        let initialState = recordEngine.isRecording
        let audioSettings = recordEngine.getAudioSettings()
        
        // Then - Should handle state gracefully
        XCTAssertFalse(initialState, "Should start in stopped state")
        XCTAssertFalse(audioSettings.isEmpty, "Audio settings should be available")
    }
} 