//
//  SettingsManagerTests.swift
//  QuickRecorderTests
//
//  Created by TDD on 2025/06/16.
//

import XCTest
import Foundation
@testable import QuickRecorder

class SettingsManagerTests: XCTestCase {
    
    var settingsManager: SettingsManager!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settingsManager = SettingsManager.shared
    }
    
    override func tearDownWithError() throws {
        settingsManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Singleton Tests
    
    func testSettingsManager_Singleton() throws {
        // Given/When
        let instance1 = SettingsManager.shared
        let instance2 = SettingsManager.shared
        
        // Then
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - UI Settings Tests
    
    func testUISettings_DefaultValues() throws {
        // Given/When/Then
        XCTAssertFalse(settingsManager.hasLaunchedBefore)
        XCTAssertTrue(settingsManager.launchAtLogin)
        XCTAssertTrue(settingsManager.hideMenubarIcon)
        XCTAssertFalse(settingsManager.showDockIcon)
        XCTAssertTrue(settingsManager.autoHidePanel)
        XCTAssertFalse(settingsManager.pinPanel)
        XCTAssertFalse(settingsManager.hideControlsInRecord)
        XCTAssertTrue(settingsManager.showMouse)
        XCTAssertFalse(settingsManager.highlightMouse)
        XCTAssertTrue(settingsManager.autoShowMagnifier)
        XCTAssertEqual(settingsManager.magnifierSize, 160)
    }
    
    func testUISettings_SetAndGet() throws {
        // Given
        settingsManager.hasLaunchedBefore = true
        settingsManager.launchAtLogin = false
        settingsManager.hideMenubarIcon = false
        settingsManager.showDockIcon = true
        settingsManager.autoHidePanel = false
        settingsManager.pinPanel = true
        settingsManager.hideControlsInRecord = true
        settingsManager.showMouse = false
        settingsManager.highlightMouse = true
        settingsManager.autoShowMagnifier = false
        settingsManager.magnifierSize = 200
        
        // Then
        XCTAssertTrue(settingsManager.hasLaunchedBefore)
        XCTAssertFalse(settingsManager.launchAtLogin)
        XCTAssertFalse(settingsManager.hideMenubarIcon)
        XCTAssertTrue(settingsManager.showDockIcon)
        XCTAssertFalse(settingsManager.autoHidePanel)
        XCTAssertTrue(settingsManager.pinPanel)
        XCTAssertTrue(settingsManager.hideControlsInRecord)
        XCTAssertFalse(settingsManager.showMouse)
        XCTAssertTrue(settingsManager.highlightMouse)
        XCTAssertFalse(settingsManager.autoShowMagnifier)
        XCTAssertEqual(settingsManager.magnifierSize, 200)
    }
    
    // MARK: - Recording Settings Tests
    
    func testRecordingSettings_DefaultValues() throws {
        // Given/When/Then
        XCTAssertTrue(settingsManager.showPreview)
        XCTAssertTrue(settingsManager.autoSave)
        XCTAssertFalse(settingsManager.showRecTimer)
        XCTAssertEqual(settingsManager.timerPos, 0)
        XCTAssertFalse(settingsManager.countDown)
        XCTAssertEqual(settingsManager.countDownNum, 3)
        XCTAssertFalse(settingsManager.recordMouse)
        XCTAssertEqual(settingsManager.mouseSizeSlider, 0.6)
        XCTAssertEqual(settingsManager.mouseHighlightColor, 0)
        XCTAssertEqual(settingsManager.frameRate, 60)
        XCTAssertFalse(settingsManager.showBorder)
        XCTAssertEqual(settingsManager.borderWidth, 5.0)
    }
    
    // MARK: - Audio Settings Tests
    
    func testAudioSettings_DefaultValues() throws {
        // Given/When/Then
        XCTAssertTrue(settingsManager.recordWASAPI)
        XCTAssertTrue(settingsManager.recordMic)
        XCTAssertFalse(settingsManager.seperateTrack)
        XCTAssertEqual(settingsManager.audioQuality, 1)
        XCTAssertEqual(settingsManager.micVolume, 1.0)
        XCTAssertEqual(settingsManager.systemAudioVolume, 1.0)
        XCTAssertFalse(settingsManager.allowAppleScript)
    }
    
    // MARK: - Video Settings Tests
    
    func testVideoSettings_DefaultValues() throws {
        // Given/When/Then
        XCTAssertEqual(settingsManager.videoFormat, 0)
        XCTAssertEqual(settingsManager.videoQuality, 1)
        XCTAssertFalse(settingsManager.backgroundRecord)
        XCTAssertFalse(settingsManager.isHEVCSupported)
        XCTAssertFalse(settingsManager.encoder)
        XCTAssertEqual(settingsManager.retinaCap, 0)
        XCTAssertEqual(settingsManager.retinaRes, 0)
        XCTAssertFalse(settingsManager.showSCRecorder)
        XCTAssertFalse(settingsManager.isFirstCapture)
        XCTAssertTrue(settingsManager.saveVideoOnly)
        XCTAssertFalse(settingsManager.hiddenSelf)
        XCTAssertFalse(settingsManager.recordExcludeApps)
        XCTAssertFalse(settingsManager.includeMenuBar)
    }
    
    // MARK: - Utility Methods Tests
    
    func testGetSaveDirectory_DefaultPath() throws {
        // Given/When
        let saveDirectory = settingsManager.getSaveDirectory()
        
        // Then
        XCTAssertTrue(saveDirectory.hasSuffix("Desktop"))
        XCTAssertTrue(FileManager.default.fileExists(atPath: saveDirectory))
    }
    
    func testGetSaveDirectory_CustomPath() throws {
        // Given
        let customPath = FileManager.default.temporaryDirectory.path
        settingsManager.saveDirectory = customPath
        
        // When
        let saveDirectory = settingsManager.getSaveDirectory()
        
        // Then
        XCTAssertEqual(saveDirectory, customPath)
    }
    
    func testGetSaveDirectory_InvalidPath() throws {
        // Given
        let invalidPath = "/non/existent/directory"
        settingsManager.saveDirectory = invalidPath
        
        // When
        let saveDirectory = settingsManager.getSaveDirectory()
        
        // Then - Should fall back to Desktop
        XCTAssertTrue(saveDirectory.hasSuffix("Desktop"))
        XCTAssertNotEqual(saveDirectory, invalidPath)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteSettingsFlow() throws {
        // Given - Set up a complete recording configuration
        settingsManager.hasLaunchedBefore = true
        settingsManager.autoSave = true
        settingsManager.showPreview = false
        settingsManager.frameRate = 60
        settingsManager.videoQuality = 2
        settingsManager.videoFormat = 1
        settingsManager.recordWASAPI = true
        settingsManager.recordMic = true
        settingsManager.seperateTrack = false
        settingsManager.audioQuality = 1
        settingsManager.micVolume = 0.8
        settingsManager.systemAudioVolume = 0.9
        settingsManager.areaRecord = true
        settingsManager.showMouse = true
        settingsManager.recordMouse = true
        settingsManager.mouseSizeSlider = 0.7
        settingsManager.showBorder = true
        settingsManager.borderWidth = 3.0
        
        // When - Verify all settings are correctly stored and retrieved
        let saveDir = settingsManager.getSaveDirectory()
        
        // Then - All settings should be consistent
        XCTAssertTrue(settingsManager.hasLaunchedBefore)
        XCTAssertTrue(settingsManager.autoSave)
        XCTAssertFalse(settingsManager.showPreview)
        XCTAssertEqual(settingsManager.frameRate, 60)
        XCTAssertEqual(settingsManager.videoQuality, 2)
        XCTAssertEqual(settingsManager.videoFormat, 1)
        XCTAssertTrue(settingsManager.recordWASAPI)
        XCTAssertTrue(settingsManager.recordMic)
        XCTAssertFalse(settingsManager.seperateTrack)
        XCTAssertEqual(settingsManager.audioQuality, 1)
        XCTAssertEqual(settingsManager.micVolume, 0.8, accuracy: 0.001)
        XCTAssertEqual(settingsManager.systemAudioVolume, 0.9, accuracy: 0.001)
        XCTAssertTrue(settingsManager.areaRecord)
        XCTAssertTrue(settingsManager.showMouse)
        XCTAssertTrue(settingsManager.recordMouse)
        XCTAssertEqual(settingsManager.mouseSizeSlider, 0.7, accuracy: 0.001)
        XCTAssertTrue(settingsManager.showBorder)
        XCTAssertEqual(settingsManager.borderWidth, 3.0, accuracy: 0.001)
        XCTAssertFalse(saveDir.isEmpty)
    }
    
    // MARK: - Performance Tests
    
    func testSettingsPerformance() throws {
        // This test ensures settings access is fast enough for real-time use
        measure {
            for _ in 0..<1000 {
                _ = settingsManager.frameRate
                _ = settingsManager.videoQuality
                _ = settingsManager.audioQuality
                _ = settingsManager.micVolume
                _ = settingsManager.systemAudioVolume
                _ = settingsManager.getSaveDirectory()
            }
        }
    }
} 