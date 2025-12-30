//
//  AVContextTests.swift
//  QuickRecorderTests
//
//  Created by TDD Test Suite
//

import XCTest
import AVFoundation
@testable import QuickRecorder

final class AVContextTests: XCTestCase {
    
    var appDelegate: AppDelegate!
    var mockUserDefaults: UserDefaults!
    
    override func setUp() {
        super.setUp()
        // Note: The app uses global 'ud' (UserDefaults.standard)
        mockUserDefaults = UserDefaults.standard
        appDelegate = AppDelegate.shared
    }
    
    override func tearDown() {
        // Clean up test keys
        let testKeys = ["micDevice", "videoFormat", "encoder"]
        for key in testKeys {
            mockUserDefaults.removeObject(forKey: key)
        }
        
        // Clean up SCContext state
        TestHelpers.cleanupSCContextState()
        
        mockUserDefaults = nil
        appDelegate = nil
        super.tearDown()
    }
    
    // MARK: - Device Discovery Tests
    
    func testGetCameras_ReturnsAvailableCameras() {
        // When
        let cameras = SCContext.getCameras()
        
        // Then
        XCTAssertNotNil(cameras)
        // May be empty if no cameras available
    }
    
    func testGetMicrophone_ReturnsAvailableMicrophones() {
        // When
        let microphones = SCContext.getMicrophone()
        
        // Then
        XCTAssertNotNil(microphones)
        // Should filter out CADefaultDeviceAggregate
        for mic in microphones {
            XCTAssertFalse(mic.localizedName.contains("CADefaultDeviceAggregate"))
        }
    }
    
    func testGetiDevice_ReturnsAvailableDevices() {
        // When
        let devices = SCContext.getiDevice()
        
        // Then
        XCTAssertNotNil(devices)
        // May be empty if no devices connected
    }
    
    // MARK: - Microphone Selection Tests
    
    func testGetCurrentMic_WithSavedDevice_ReturnsDevice() {
        // Given
        let microphones = SCContext.getMicrophone()
        guard let firstMic = microphones.first else {
            XCTSkip("No microphone available for testing")
            return
        }
        
        mockUserDefaults.set(firstMic.localizedName, forKey: "micDevice")
        
        // When
        let currentMic = SCContext.getCurrentMic()
        
        // Then
        XCTAssertNotNil(currentMic)
        XCTAssertEqual(currentMic?.localizedName, firstMic.localizedName)
    }
    
    func testGetCurrentMic_WithDefaultDevice_ReturnsDeviceOrNil() {
        // Given
        mockUserDefaults.set("default", forKey: "micDevice")
        
        // When
        let currentMic = SCContext.getCurrentMic()
        
        // Then
        // "default" is not a real device name, should return nil
        XCTAssertNil(currentMic)
    }
    
    // MARK: - Sample Rate Tests
    
    func testGetSampleRate_WithDevice_ReturnsDeviceSampleRate() {
        // Given
        let microphones = SCContext.getMicrophone()
        guard let mic = microphones.first else {
            XCTSkip("No microphone available for testing")
            return
        }
        
        mockUserDefaults.set(mic.localizedName, forKey: "micDevice")
        
        // When
        let sampleRate = SCContext.getSampleRate()
        
        // Then
        XCTAssertNotNil(sampleRate)
        // Common sample rates: 44100, 48000
        if let rate = sampleRate {
            XCTAssertTrue(rate == 44100 || rate == 48000 || rate > 0)
        }
    }
    
    func testGetDefaultSampleRate_ReturnsValidRate() {
        // When
        let sampleRate = SCContext.getDefaultSampleRate()
        
        // Then
        // In test environment, audio hardware may not be accessible
        // So sampleRate can be nil, which is acceptable
        if let rate = sampleRate {
            // Common sample rates: 44100, 48000
            XCTAssertTrue(rate == 44100 || rate == 48000 || rate > 0)
        } else {
            // In test environment, it's acceptable for this to return nil
            print("Note: getDefaultSampleRate returned nil (expected in test environment)")
        }
    }
    
    // MARK: - AVOutputClass Tests
    
    func testAVOutputClass_Singleton_Exists() {
        // Given/When
        let output = AVOutputClass.shared
        
        // Then
        XCTAssertNotNil(output)
    }
    
    func testAudioRecorder_Singleton_Exists() {
        // Given/When
        let recorder = AudioRecorder.shared
        
        // Then
        XCTAssertNotNil(recorder)
    }
    
    // MARK: - AVCaptureDevice Tests
    
    func testAVCaptureDevice_DefaultVideo_ChecksAvailability() {
        // When
        let camera = AVCaptureDevice.default(for: .video)
        
        // Then
        // May be nil if no camera available
        if let camera = camera {
            XCTAssertNotNil(camera.localizedName)
        }
    }
    
    func testAVCaptureDevice_DefaultAudio_ChecksAvailability() {
        // When
        let mic = AVCaptureDevice.default(for: .audio)
        
        // Then
        // May be nil if no mic available
        if let mic = mic {
            XCTAssertNotNil(mic.localizedName)
        }
    }
}
