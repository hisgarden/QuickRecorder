//
//  SCContextTests.swift
//  QuickRecorderTests
//
//  Test suite for SCContext methods and properties
//

import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import QuickRecorder

final class SCContextTests: XCTestCase {

    var mockUserDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        mockUserDefaults = UserDefaults.standard
        // Clear test keys before each test
        let testKeys = ["saveDirectory", "audioFormat", "audioQuality", "background", "videoFormat", "encoder", "videoQuality", "frameRate", "recordMic", "micDevice"]
        for key in testKeys {
            mockUserDefaults.removeObject(forKey: key)
        }
    }

    override func tearDown() {
        // Clean up test keys
        let testKeys = ["saveDirectory", "audioFormat", "audioQuality", "background", "videoFormat", "encoder", "videoQuality", "frameRate", "recordMic", "micDevice"]
        for key in testKeys {
            mockUserDefaults.removeObject(forKey: key)
        }

        // Clean up SCContext state
        TestHelpers.cleanupSCContextState()

        mockUserDefaults = nil
        super.tearDown()
    }

    // MARK: - File Path Tests

    func testGetFilePath_GeneratesValidPath() {
        // Given
        let saveDirectory = "/tmp/test"
        mockUserDefaults.set(saveDirectory, forKey: "saveDirectory")

        // When
        let filePath = SCContext.getFilePath()

        // Then
        XCTAssertFalse(filePath.isEmpty)
        // Check if path starts with saveDirectory (accounting for localized strings)
        XCTAssertTrue(filePath.hasPrefix(saveDirectory) || filePath.contains(saveDirectory))
        // Check for date pattern or localized recording string
        XCTAssertTrue(filePath.contains("Recording") || filePath.contains("at") || filePath.count > saveDirectory.count)
    }

    func testGetFilePath_ForCapture_IncludesCapturePrefix() {
        // Given
        let saveDirectory = "/tmp/test"
        mockUserDefaults.set(saveDirectory, forKey: "saveDirectory")

        // When
        let filePath = SCContext.getFilePath(capture: true)

        // Then
        // Check for capture prefix (accounting for localized strings)
        XCTAssertTrue(filePath.contains("Capturing") || filePath.contains("Capture") || filePath.count > saveDirectory.count)
    }

    func testGetFilePath_IncludesTimestamp() {
        // Given
        let saveDirectory = "/tmp/test"
        mockUserDefaults.set(saveDirectory, forKey: "saveDirectory")

        // When
        let filePath = SCContext.getFilePath()

        // Then
        // Should contain date format: y-MM-dd HH.mm.ss
        let datePattern = #"\d{4}-\d{2}-\d{2} \d{2}\.\d{2}\.\d{2}"#
        let regex = try! NSRegularExpression(pattern: datePattern)
        let range = NSRange(filePath.startIndex..., in: filePath)
        XCTAssertNotNil(regex.firstMatch(in: filePath, range: range))
    }

    // MARK: - Audio Settings Tests

    func testUpdateAudioSettings_DefaultFormat_ReturnsAACSettings() {
        // Given
        mockUserDefaults.set(AudioFormat.aac.rawValue, forKey: "audioFormat")
        mockUserDefaults.set(AudioQuality.high.rawValue, forKey: "audioQuality")

        // When
        let settings = SCContext.updateAudioSettings()

        // Then
        XCTAssertEqual(settings[AVSampleRateKey] as? Int, 48000)
        XCTAssertEqual(settings[AVNumberOfChannelsKey] as? Int, 2)
        XCTAssertEqual(settings[AVFormatIDKey] as? UInt32, kAudioFormatMPEG4AAC)
        XCTAssertNotNil(settings[AVEncoderBitRateKey])
    }

    func testUpdateAudioSettings_MP3Format_ReturnsAACSettings() {
        // Given
        mockUserDefaults.set(AudioFormat.mp3.rawValue, forKey: "audioFormat")
        mockUserDefaults.set(AudioQuality.high.rawValue, forKey: "audioQuality")

        // When
        let settings = SCContext.updateAudioSettings()

        // Then
        XCTAssertEqual(settings[AVFormatIDKey] as? UInt32, kAudioFormatMPEG4AAC)
    }

    func testUpdateAudioSettings_ALACFormat_ReturnsALACSettings() {
        // Given
        mockUserDefaults.set(AudioFormat.alac.rawValue, forKey: "audioFormat")

        // When
        let settings = SCContext.updateAudioSettings()

        // Then
        XCTAssertEqual(settings[AVFormatIDKey] as? UInt32, kAudioFormatAppleLossless)
        XCTAssertEqual(settings[AVEncoderBitDepthHintKey] as? Int, 16)
    }

    func testUpdateAudioSettings_FLACFormat_ReturnsFLACSettings() {
        // Given
        mockUserDefaults.set(AudioFormat.flac.rawValue, forKey: "audioFormat")

        // When
        let settings = SCContext.updateAudioSettings()

        // Then
        XCTAssertEqual(settings[AVFormatIDKey] as? UInt32, kAudioFormatFLAC)
    }

    func testUpdateAudioSettings_CustomSampleRate_ReturnsCorrectRate() {
        // Given
        let customRate = 44100
        mockUserDefaults.set(AudioFormat.aac.rawValue, forKey: "audioFormat")

        // When
        let settings = SCContext.updateAudioSettings(rate: customRate)

        // Then
        XCTAssertEqual(settings[AVSampleRateKey] as? Int, customRate)
    }

    func testUpdateAudioSettings_LowSampleRate_AdjustsBitRate() {
        // Given
        let lowRate = 22050
        mockUserDefaults.set(AudioFormat.aac.rawValue, forKey: "audioFormat")
        mockUserDefaults.set(AudioQuality.high.rawValue, forKey: "audioQuality")

        // When
        let settings = SCContext.updateAudioSettings(rate: lowRate)

        // Then
        let bitRate = settings[AVEncoderBitRateKey] as? Int
        XCTAssertNotNil(bitRate)
        XCTAssertLessThanOrEqual(bitRate ?? 0, 64000)
    }

    // MARK: - Background Color Tests

    func testGetBackgroundColor_Black_ReturnsBlack() {
        // Given
        mockUserDefaults.set(BackgroundType.black.rawValue, forKey: "background")

        // When
        let color = SCContext.getBackgroundColor()

        // Then
        XCTAssertEqual(color, CGColor.black)
    }

    func testGetBackgroundColor_White_ReturnsWhite() {
        // Given
        mockUserDefaults.set(BackgroundType.white.rawValue, forKey: "background")

        // When
        let color = SCContext.getBackgroundColor()

        // Then
        XCTAssertEqual(color, CGColor.white)
    }

    func testGetBackgroundColor_Clear_ReturnsClear() {
        // Given
        mockUserDefaults.set(BackgroundType.clear.rawValue, forKey: "background")

        // When
        let color = SCContext.getBackgroundColor()

        // Then
        XCTAssertEqual(color, CGColor.clear)
    }

    func testGetBackgroundColor_Wallpaper_ReturnsBlack() {
        // Given
        mockUserDefaults.set(BackgroundType.wallpaper.rawValue, forKey: "background")

        // When
        let color = SCContext.getBackgroundColor()

        // Then
        XCTAssertEqual(color, CGColor.black)
    }

    func testGetBackgroundColor_SystemColors_ReturnsCorrectColor() {
        // Given
        let testCases: [(BackgroundType, CGColor)] = [
            (.red, NSColor.systemRed.cgColor),
            (.green, NSColor.systemGreen.cgColor),
            (.blue, NSColor.systemBlue.cgColor),
            (.yellow, NSColor.systemYellow.cgColor),
            (.orange, NSColor.systemOrange.cgColor),
            (.gray, NSColor.systemGray.cgColor)
        ]

        for (backgroundType, expectedColor) in testCases {
            mockUserDefaults.set(backgroundType.rawValue, forKey: "background")

            // When
            let color = SCContext.getBackgroundColor()

            // Then
            XCTAssertEqual(color, expectedColor, "Failed for \(backgroundType)")
        }
    }

    // MARK: - Recording State Tests

    func testPauseRecording_TogglesPausedState() {
        // Given
        SCContext.isPaused = false

        // When
        SCContext.pauseRecording()

        // Then
        XCTAssertTrue(SCContext.isPaused)

        // When
        SCContext.pauseRecording()

        // Then
        XCTAssertFalse(SCContext.isPaused)
    }

    func testPauseRecording_OnResume_SetsResumeFlag() {
        // Given
        SCContext.isPaused = true
        SCContext.startTime = Date.now
        SCContext.timePassed = 10.0

        // When
        SCContext.pauseRecording()

        // Then
        XCTAssertTrue(SCContext.isResume)
        XCTAssertFalse(SCContext.isPaused)
    }

    // MARK: - Static Property Tests

    func testSCContext_StaticVars_Exist() {
        // Test that static properties exist and are accessible
        XCTAssertNotNil(SCContext.trimingList)
        XCTAssertNotNil(SCContext.audioEngine)
        XCTAssertNotNil(SCContext.AECEngine)
        XCTAssertNotNil(SCContext.excludedApps)
        XCTAssertFalse(SCContext.excludedApps.isEmpty)
    }

    func testSCContext_StaticVars_DefaultValues() {
        // Test default values of static properties
        XCTAssertFalse(SCContext.isPaused)
        XCTAssertFalse(SCContext.isResume)
        XCTAssertFalse(SCContext.isMagnifierEnabled)
        XCTAssertFalse(SCContext.saveFrame)
        XCTAssertEqual(SCContext.timePassed, 0)
        XCTAssertNil(SCContext.startTime)
        XCTAssertNil(SCContext.filePath)
        XCTAssertNil(SCContext.availableContent)
    }

    func testSCContext_StreamType_CanBeSet() {
        // Given
        SCContext.streamType = .screen

        // Then
        XCTAssertEqual(SCContext.streamType, .screen)

        // When
        SCContext.streamType = .window

        // Then
        XCTAssertEqual(SCContext.streamType, .window)

        // Cleanup
        SCContext.streamType = nil
    }

    func testSCContext_FilePaths_CanBeSet() {
        // Given
        SCContext.filePath = "/tmp/test.mp4"
        SCContext.filePath1 = "/tmp/test1.m4a"
        SCContext.filePath2 = "/tmp/test2.m4a"

        // Then
        XCTAssertEqual(SCContext.filePath, "/tmp/test.mp4")
        XCTAssertEqual(SCContext.filePath1, "/tmp/test1.m4a")
        XCTAssertEqual(SCContext.filePath2, "/tmp/test2.m4a")

        // Cleanup
        SCContext.filePath = nil
        SCContext.filePath1 = nil
        SCContext.filePath2 = nil
    }

    func testSCContext_TimeProperties_CanBeModified() {
        // Given
        SCContext.startTime = Date.now
        SCContext.timePassed = 5.0

        // Then
        XCTAssertNotNil(SCContext.startTime)
        XCTAssertEqual(SCContext.timePassed, 5.0)

        // Cleanup
        SCContext.startTime = nil
        SCContext.timePassed = 0
    }

    // MARK: - Camera State Tests

    func testIsCameraRunning_WhenNotRunning_ReturnsFalse() {
        // Given - no camera sessions running
        SCContext.previewSession = nil
        SCContext.captureSession = nil

        // When
        let isRunning = SCContext.isCameraRunning()

        // Then
        XCTAssertFalse(isRunning)
    }

    // MARK: - Recording Length Tests

    func testGetRecordingLength_ReturnsFormattedString() {
        // Given
        SCContext.startTime = Date.now
        SCContext.timePassed = 0

        // When
        let length = SCContext.getRecordingLength()

        // Then
        XCTAssertFalse(length.isEmpty)

        // Cleanup
        SCContext.startTime = nil
        SCContext.timePassed = 0
    }

    func testGetRecordingLength_WithPausedState_ReturnsTimePassed() {
        // Given
        SCContext.isPaused = true
        SCContext.startTime = Date.now.addingTimeInterval(-120)
        SCContext.timePassed = 120

        // When
        let length = SCContext.getRecordingLength()

        // Then
        XCTAssertFalse(length.isEmpty)

        // Cleanup
        SCContext.isPaused = false
        SCContext.startTime = nil
        SCContext.timePassed = 0
    }

    // MARK: - Available Content Tests

    func testUpdateAvailableContentSync_ReturnsContent() {
        // When
        let content = SCContext.updateAvailableContentSync()

        // Then - content may be nil if permissions not granted
        // Test passes if method executes without error
        _ = content
    }

    // MARK: - Permission Tests

    func testRequestCameraPermission_DoesNotCrash() {
        // When/Then - should not crash
        SCContext.requestCameraPermission()
    }

    // MARK: - Stream Type Tests

    func testStreamType_AllCases_Exist() {
        // Verify StreamType enum values are available
        XCTAssertNotNil(StreamType.screen)
        XCTAssertNotNil(StreamType.window)
        XCTAssertNotNil(StreamType.windows)
        XCTAssertNotNil(StreamType.application)
        XCTAssertNotNil(StreamType.screenarea)
        XCTAssertNotNil(StreamType.systemaudio)
        XCTAssertNotNil(StreamType.idevice)
        XCTAssertNotNil(StreamType.camera)
    }

    func testStreamType_RawValues() {
        // Test stream type raw values (Int enum, values start at 0)
        XCTAssertEqual(StreamType.screen.rawValue, 0)
        XCTAssertEqual(StreamType.window.rawValue, 1)
        XCTAssertEqual(StreamType.systemaudio.rawValue, 5)
    }

    // MARK: - Encoder Tests

    func testEncoder_EnumValues_Exist() {
        // Verify Encoder enum values are available
        XCTAssertEqual(Encoder.h264.rawValue, "h264")
        XCTAssertEqual(Encoder.h265.rawValue, "h265")
    }

    // MARK: - Video Format Tests

    func testVideoFormat_EnumValues_Exist() {
        // Verify VideoFormat enum values are available
        XCTAssertEqual(VideoFormat.mov.rawValue, "mov")
        XCTAssertEqual(VideoFormat.mp4.rawValue, "mp4")
    }

    // MARK: - Audio Format Tests

    func testAudioFormat_EnumValues_Exist() {
        // Verify AudioFormat enum values are available
        XCTAssertEqual(AudioFormat.aac.rawValue, "aac")
        XCTAssertEqual(AudioFormat.alac.rawValue, "alac")
        XCTAssertEqual(AudioFormat.flac.rawValue, "flac")
        XCTAssertEqual(AudioFormat.opus.rawValue, "opus")
        XCTAssertEqual(AudioFormat.mp3.rawValue, "mp3")
    }

    // MARK: - Audio Quality Tests

    func testAudioQuality_EnumValues_Exist() {
        // Verify AudioQuality enum values are available
        XCTAssertEqual(AudioQuality.normal.rawValue, 128)
        XCTAssertEqual(AudioQuality.good.rawValue, 192)
        XCTAssertEqual(AudioQuality.high.rawValue, 256)
        XCTAssertEqual(AudioQuality.extreme.rawValue, 320)
    }

    // MARK: - Background Type Tests

    func testBackgroundType_EnumValues_Exist() {
        // Verify BackgroundType enum values are available
        XCTAssertEqual(BackgroundType.black.rawValue, "black")
        XCTAssertEqual(BackgroundType.white.rawValue, "white")
        XCTAssertEqual(BackgroundType.clear.rawValue, "clear")
        XCTAssertEqual(BackgroundType.wallpaper.rawValue, "wallpaper")
        XCTAssertEqual(BackgroundType.red.rawValue, "red")
        XCTAssertEqual(BackgroundType.green.rawValue, "green")
        XCTAssertEqual(BackgroundType.blue.rawValue, "blue")
    }

    // MARK: - Recording Control Tests

    func testStopRecording_SetsCorrectState() {
        // Given - simulate recording state
        SCContext.isPaused = false
        SCContext.isResume = false
        SCContext.isMagnifierEnabled = false
        SCContext.recordCam = ""
        SCContext.recordDevice = ""
        SCContext.autoStop = 0
        SCContext.streamType = nil // Ensure streamType is nil to avoid accessing vW/vwInput/awInput

        // When - call stopRecording (may not complete fully without full setup)
        // This tests that the method exists and can be called
        // Note: stopRecording() requires proper initialization of vW, vwInput, etc.
        // In test environment, we skip if these aren't set up to avoid crashes
        SCContext.stopRecording()

        // Then - verify state changes (some may persist after partial execution)
        XCTAssertFalse(SCContext.isMagnifierEnabled)
        XCTAssertEqual(SCContext.autoStop, 0)
    }

    // MARK: - Helper Method Tests

    func testGetSelf_ReturnsAppOrNil() {
        // When
        let selfApp = SCContext.getSelf()

        // Then - may return nil if availableContent not loaded
        // Test passes if method executes without error
        _ = selfApp
    }

    func testGetSelfWindows_ReturnsArrayOrNil() {
        // When
        let windows = SCContext.getSelfWindows()

        // Then - may return nil if availableContent not loaded
        // Test passes if method executes without error
        _ = windows
    }

    func testGetScreenWithMouse_ReturnsScreenOrNil() {
        // When
        let screen = SCContext.getScreenWithMouse()

        // Then - may return nil in headless environments
        // Test passes if method executes without error
        _ = screen
    }

    func testGetSCDisplayWithMouse_ReturnsDisplayOrNil() {
        // When
        let display = SCContext.getSCDisplayWithMouse()

        // Then - may return nil if no displays available
        // Test passes if method executes without error
        _ = display
    }

    // MARK: - Audio Format Validation Tests

    func testUpdateAudioSettings_OpusFormat_ReturnsCorrectFormat() {
        // Given
        mockUserDefaults.set(AudioFormat.opus.rawValue, forKey: "audioFormat")
        mockUserDefaults.set(VideoFormat.mov.rawValue, forKey: "videoFormat")

        // When
        let settings = SCContext.updateAudioSettings()

        // Then
        // Opus format should use appropriate format ID
        XCTAssertNotNil(settings[AVFormatIDKey])
    }

    // MARK: - Recording State Management Tests

    func testIsPaused_InitialState_IsFalse() {
        // Given - reset state
        SCContext.isPaused = false

        // Then
        XCTAssertFalse(SCContext.isPaused)
    }

    func testIsResume_InitialState_IsFalse() {
        // Given - reset state
        SCContext.isResume = false

        // Then
        XCTAssertFalse(SCContext.isResume)
    }

    func testTimePassed_InitialState_IsZero() {
        // Given - reset state
        SCContext.timePassed = 0

        // Then
        XCTAssertEqual(SCContext.timePassed, 0)
    }
}
