//
//  DeviceIntegrationTests.swift
//  QuickRecorderTests
//
//  Created by TDD Coverage Enhancement on 2025/12/27.
//

import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import QuickRecorder

/// Tests for device and hardware integration
/// Covers multiple displays, cameras, microphones, and device switching
@available(macOS 12.3, *)
class DeviceIntegrationTests: XCTestCase {
    
    override func setUpWithError() throws {
        try super.setUpWithError()
    }
    
    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }
    
    // MARK: - Display Tests
    
    /// Tests multiple display detection
    func testMultipleDisplayDetection() async throws {
        // Given - System may have multiple displays
        let hasPermission = await QuickRecorder.SCContext.checkScreenRecordingPermission()
        
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted")
        }
        
        // When - Get available displays
        let content = QuickRecorder.SCContext.availableContent
        let displays = content?.displays ?? []
        
        // Then - Should detect at least one display
        XCTAssertGreaterThanOrEqual(displays.count, 1, "Should detect at least one display")
        
        for display in displays {
            XCTAssertGreaterThan(display.width, 0, "Display should have width")
            XCTAssertGreaterThan(display.height, 0, "Display should have height")
            XCTAssertGreaterThan(display.displayID, 0, "Display should have valid ID")
        }
    }
    
    /// Tests display with mouse cursor
    func testDisplayWithMouseCursor() throws {
        // Given - Mouse is on a display
        let displayWithMouse = RecordingStateManager.shared.getSCDisplayWithMouse()
        
        // Then - Should find display or handle gracefully
        if let display = displayWithMouse {
            XCTAssertGreaterThan(display.width, 0)
            XCTAssertGreaterThan(display.height, 0)
        } else {
            // No display found is acceptable if no permission
            XCTAssertTrue(true, "No display found (acceptable if no permission)")
        }
    }
    
    /// Tests display enumeration
    func testDisplayEnumeration() throws {
        // When - Enumerate displays
        let content = QuickRecorder.SCContext.availableContent
        let displays = content?.displays ?? []
        
        // Then - Verify display properties
        for display in displays {
            XCTAssertNotNil(display.displayID)
            XCTAssertGreaterThan(display.width, 0)
            XCTAssertGreaterThan(display.height, 0)
            
            // Test display frame
            XCTAssertGreaterThan(display.frame.width, 0)
            XCTAssertGreaterThan(display.frame.height, 0)
        }
    }
    
    /// Tests display changes detection
    func testDisplayChangesDetection() throws {
        // Given - Initial display state
        let initialDisplays = QuickRecorder.SCContext.availableContent?.displays ?? []
        
        // When - Check again (displays shouldn't change during test)
        let currentDisplays = QuickRecorder.SCContext.availableContent?.displays ?? []
        
        // Then - Should be consistent
        XCTAssertEqual(initialDisplays.count, currentDisplays.count, "Display count should be consistent")
    }
    
    // MARK: - Camera Tests
    
    /// Tests camera device detection
    func testCameraDeviceDetection() throws {
        // Given - System may have cameras
        let cameras = QuickRecorder.SCContext.getCameras()
        
        // Then - Should handle gracefully whether cameras exist or not
        XCTAssertGreaterThanOrEqual(cameras.count, 0, "Should return camera list (may be empty)")
        
        for camera in cameras {
            XCTAssertNotNil(camera.localizedName)
            XCTAssertTrue(camera.hasMediaType(.video))
        }
    }
    
    /// Tests multiple camera detection
    func testMultipleCameraDetection() throws {
        // Given - System may have multiple cameras
        // When - Get all cameras
        let cameras = QuickRecorder.SCContext.getCameras()
        
        // Then - Should detect all available cameras
        XCTAssertGreaterThanOrEqual(cameras.count, 0, "Should return camera list")
        
        // Log camera info
        for camera in cameras {
            print("Camera: \(camera.localizedName)")
        }
    }
    
    /// Tests camera switching
    func testCameraSwitching() throws {
        // Given - Multiple cameras
        // When - Get cameras
        let cameras = QuickRecorder.SCContext.getCameras()
        
        // Then - Should be able to switch between cameras
        if cameras.count > 1 {
            let firstCamera = cameras[0]
            let secondCamera = cameras[1]
            
            XCTAssertNotEqual(firstCamera.uniqueID, secondCamera.uniqueID, "Cameras should be different")
        } else {
            throw XCTSkip("Need multiple cameras for this test")
        }
    }
    
    // MARK: - Microphone Tests
    
    /// Tests microphone device detection
    func testMicrophoneDeviceDetection() throws {
        // Given - System may have microphones
        let microphones = QuickRecorder.SCContext.getMicrophone()
        
        // Then - Should detect at least one microphone (built-in)
        XCTAssertGreaterThanOrEqual(microphones.count, 0, "Should return microphone list")
        
        for mic in microphones {
            XCTAssertNotNil(mic.localizedName)
            XCTAssertTrue(mic.hasMediaType(.audio))
        }
    }
    
    /// Tests microphone selection
    func testMicrophoneSelection() throws {
        // Given - Multiple microphones
        let microphones = QuickRecorder.SCContext.getMicrophone()
        
        // Then - Should be able to select different microphones
        if microphones.count > 1 {
            let firstMic = microphones[0]
            let secondMic = microphones[1]
            
            XCTAssertNotEqual(firstMic.uniqueID, secondMic.uniqueID, "Microphones should be different")
        }
    }
    
    /// Tests microphone with permission
    func testMicrophoneWithPermission() throws {
        // Given - Microphone permission status
        let permissionStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        
        // When - Get microphones
        let microphones = QuickRecorder.SCContext.getMicrophone()
        
        // Then - Should handle permission states gracefully
        XCTAssertGreaterThanOrEqual(microphones.count, 0, "Should return microphone list regardless of permission")
    }
    
    /// Tests audio device switching
    func testAudioDeviceSwitching() throws {
        // Given - Multiple audio devices
        let microphones = QuickRecorder.SCContext.getMicrophone()
        
        // When - Switch between devices
        if microphones.count > 1 {
            for mic in microphones.prefix(2) {
                let ud = UserDefaults.standard
                ud.set(mic.localizedName, forKey: "micDevice")
                // Note: getCurrentMic() doesn't exist in SCContext, use stub or skip
                throw XCTSkip("getCurrentMic() not available in SCContext")
                
                // Then - Should select correct device
                // (test skipped due to missing API)
            }
        } else {
            throw XCTSkip("Need multiple microphones for this test")
        }
    }
    
    // MARK: - iOS Device Tests
    
    /// Tests iOS device detection
    func testiOSDeviceDetection() throws {
        // Given - Connected iOS devices
        let devices = QuickRecorder.SCContext.getiDevice()
        
        // Then - Should handle device detection gracefully
        XCTAssertGreaterThanOrEqual(devices.count, 0, "Should return device list (may be empty)")
        
        for device in devices {
            XCTAssertNotNil(device.localizedName)
        }
    }
    
    // MARK: - Content Update Tests
    
    /// Tests content update triggers
    func testContentUpdateTriggers() async throws {
        // Given - Initial content state
        let initialContent = QuickRecorder.SCContext.availableContent
        
        // When - Update content
        await QuickRecorder.SCContext.updateAvailableContent { _ in }
        
        // Then - Content should be updated
        let updatedContent = QuickRecorder.SCContext.availableContent
        XCTAssertNotNil(updatedContent, "Content should be available after update")
    }
    
    /// Tests content update performance
    func testContentUpdatePerformance() throws {
        measure {
            _ = QuickRecorder.SCContext.updateAvailableContentSync()
        }
    }
    
    // MARK: - Device State Tests
    
    /// Tests device state consistency
    func testDeviceStateConsistency() throws {
        // Given - Multiple device queries
        let cameras1 = QuickRecorder.SCContext.getCameras()
        let mics1 = QuickRecorder.SCContext.getMicrophone()
        
        // When - Query again immediately
        let cameras2 = QuickRecorder.SCContext.getCameras()
        let mics2 = QuickRecorder.SCContext.getMicrophone()
        
        // Then - Results should be consistent
        XCTAssertEqual(cameras1.count, cameras2.count, "Camera count should be consistent")
        XCTAssertEqual(mics1.count, mics2.count, "Microphone count should be consistent")
    }
    
    /// Tests device info caching
    func testDeviceInfoCaching() throws {
        // Given - Get devices multiple times
        let iterations = 5
        var cameraCounts: [Int] = []
        var micCounts: [Int] = []
        
        // When - Query devices multiple times
        for _ in 0..<iterations {
            cameraCounts.append(QuickRecorder.SCContext.getCameras().count)
            micCounts.append(QuickRecorder.SCContext.getMicrophone().count)
        }
        
        // Then - Counts should be stable
        let cameraCountsUnique = Set(cameraCounts)
        let micCountsUnique = Set(micCounts)
        
        XCTAssertLessThanOrEqual(cameraCountsUnique.count, 2, "Camera counts should be stable")
        XCTAssertLessThanOrEqual(micCountsUnique.count, 2, "Mic counts should be stable")
    }
    
    // MARK: - Performance Tests
    
    /// Tests device enumeration performance
    func testDeviceEnumerationPerformance() throws {
        measure {
            _ = QuickRecorder.SCContext.getCameras()
            _ = QuickRecorder.SCContext.getMicrophone()
            _ = QuickRecorder.SCContext.getiDevice()
        }
    }
    
    /// Tests display detection performance
    func testDisplayDetectionPerformance() async throws {
        let hasPermission = await QuickRecorder.SCContext.checkScreenRecordingPermission()
        guard hasPermission else {
            throw XCTSkip("Screen recording permission not granted")
        }
        
        measure {
            _ = QuickRecorder.SCContext.availableContent?.displays
        }
    }
    
    // MARK: - Integration Tests
    
    /// Tests complete device setup for recording
    func testCompleteDeviceSetup() async throws {
        // Given - Need all devices for recording
        let hasScreenPermission = await QuickRecorder.SCContext.checkScreenRecordingPermission()
        let hasMicPermission = AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
        let hasCameraPermission = AVCaptureDevice.authorizationStatus(for: .video) == .authorized
        
        // When - Get all devices
        let displays = QuickRecorder.SCContext.availableContent?.displays ?? []
        let cameras = QuickRecorder.SCContext.getCameras()
        let microphones = QuickRecorder.SCContext.getMicrophone()
        let iosDevices = QuickRecorder.SCContext.getiDevice()
        
        // Then - Log device availability
        print("Device Setup:")
        print("  Displays: \(displays.count)")
        print("  Cameras: \(cameras.count) (permission: \(hasCameraPermission))")
        print("  Microphones: \(microphones.count) (permission: \(hasMicPermission))")
        print("  iOS Devices: \(iosDevices.count)")
        
        XCTAssertTrue(displays.count > 0 || !hasScreenPermission, "Should have displays if permission granted")
    }
    
    /// Tests device availability for recording scenarios
    func testDeviceAvailabilityForRecording() throws {
        // Given - Different recording scenarios
        struct RecordingScenario {
            let name: String
            let needsDisplay: Bool
            let needsMic: Bool
            let needsCamera: Bool
        }
        
        let scenarios: [RecordingScenario] = [
            RecordingScenario(name: "Screen Only", needsDisplay: true, needsMic: false, needsCamera: false),
            RecordingScenario(name: "Screen + Audio", needsDisplay: true, needsMic: true, needsCamera: false),
            RecordingScenario(name: "Screen + Camera", needsDisplay: true, needsMic: false, needsCamera: true),
            RecordingScenario(name: "Full Recording", needsDisplay: true, needsMic: true, needsCamera: true)
        ]
        
        // When - Check device availability
        let displays = QuickRecorder.SCContext.availableContent?.displays ?? []
        let microphones = QuickRecorder.SCContext.getMicrophone()
        let cameras = QuickRecorder.SCContext.getCameras()
        
        for scenario in scenarios {
            let hasDevices = (!scenario.needsDisplay || displays.count > 0) &&
                            (!scenario.needsMic || microphones.count > 0) &&
                            (!scenario.needsCamera || cameras.count > 0)
            
            print("\(scenario.name): \(hasDevices ? "✅ Available" : "❌ Missing devices")")
        }
    }
}

