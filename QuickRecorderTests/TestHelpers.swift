//
//  TestHelpers.swift
//  QuickRecorderTests
//
//  Test utilities and helpers
//

import XCTest
import AVFoundation
import ScreenCaptureKit
@testable import QuickRecorder

/// Helper class for creating test fixtures
final class TestHelpers {
    
    // MARK: - UserDefaults Helpers
    
    static func createTestUserDefaults() -> UserDefaults {
        let suiteName = "test.quickrecorder.\(UUID().uuidString)"
        let testDefaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        testDefaults.removePersistentDomain(forName: suiteName)
        return testDefaults
    }
    
    static func setupDefaultSettings(in defaults: UserDefaults) {
        let userDesktop = (NSSearchPathForDirectoriesInDomains(.desktopDirectory, .userDomainMask, true) as [String]).first!
        
        defaults.set(AudioFormat.aac.rawValue, forKey: "audioFormat")
        defaults.set(AudioQuality.high.rawValue, forKey: "audioQuality")
        defaults.set(BackgroundType.wallpaper.rawValue, forKey: "background")
        defaults.set(60, forKey: "frameRate")
        defaults.set(2, forKey: "highRes")
        defaults.set(true, forKey: "hideSelf")
        defaults.set(false, forKey: "highlightMouse")
        defaults.set(false, forKey: "hideDesktopFiles")
        defaults.set(true, forKey: "includeMenuBar")
        defaults.set(1.0, forKey: "videoQuality")
        defaults.set(0, forKey: "countdown")
        defaults.set(VideoFormat.mp4.rawValue, forKey: "videoFormat")
        defaults.set(PixFormat.delault.rawValue, forKey: "pixelFormat")
        defaults.set(Encoder.h264.rawValue, forKey: "encoder")
        defaults.set(1, forKey: "poSafeDelay")
        defaults.set(userDesktop, forKey: "saveDirectory")
        defaults.set(true, forKey: "showMouse")
        defaults.set(false, forKey: "recordMic")
        defaults.set(true, forKey: "remuxAudio")
        defaults.set(true, forKey: "recordWinSound")
        defaults.set(false, forKey: "trimAfterRecord")
        defaults.set(true, forKey: "showOnDock")
        defaults.set(false, forKey: "showMenubar")
        defaults.set(false, forKey: "enableAEC")
        defaults.set(false, forKey: "recordHDR")
        defaults.set(true, forKey: "preventSleep")
        defaults.set(true, forKey: "showPreview")
    }
    
    // MARK: - Sample Buffer Helpers
    
    static func createVideoSampleBuffer(width: Int32 = 1920, height: Int32 = 1080) -> CMSampleBuffer? {
        var formatDescription: CMFormatDescription?
        var sampleBuffer: CMSampleBuffer?
        
        let status = CMVideoFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            codecType: kCMVideoCodecType_H264,
            width: width,
            height: height,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let formatDesc = formatDescription else {
            return nil
        }
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: 30),
            presentationTimeStamp: CMTime(value: 0, timescale: 30),
            decodeTimeStamp: CMTime(value: 0, timescale: 30)
        )
        
        let sampleStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr else {
            return nil
        }
        
        return sampleBuffer
    }
    
    static func createAudioSampleBuffer(sampleRate: Double = 48000.0) -> CMSampleBuffer? {
        var formatDescription: CMAudioFormatDescription?
        var sampleBuffer: CMSampleBuffer?
        
        var asbd = AudioStreamBasicDescription(
            mSampleRate: sampleRate,
            mFormatID: kAudioFormatLinearPCM,
            mFormatFlags: kAudioFormatFlagIsFloat | kAudioFormatFlagIsPacked,
            mBytesPerPacket: 8,
            mFramesPerPacket: 1,
            mBytesPerFrame: 8,
            mChannelsPerFrame: 2,
            mBitsPerChannel: 32,
            mReserved: 0
        )
        
        let status = CMAudioFormatDescriptionCreate(
            allocator: kCFAllocatorDefault,
            asbd: &asbd,
            layoutSize: 0,
            layout: nil,
            magicCookieSize: 0,
            magicCookie: nil,
            extensions: nil,
            formatDescriptionOut: &formatDescription
        )
        
        guard status == noErr, let formatDesc = formatDescription else {
            return nil
        }
        
        var timingInfo = CMSampleTimingInfo(
            duration: CMTime(value: 1, timescale: Int32(sampleRate)),
            presentationTimeStamp: CMTime(value: 0, timescale: Int32(sampleRate)),
            decodeTimeStamp: CMTime(value: 0, timescale: Int32(sampleRate))
        )
        
        let sampleStatus = CMSampleBufferCreate(
            allocator: kCFAllocatorDefault,
            dataBuffer: nil,
            dataReady: false,
            makeDataReadyCallback: nil,
            refcon: nil,
            formatDescription: formatDesc,
            sampleCount: 1,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleSizeEntryCount: 0,
            sampleSizeArray: nil,
            sampleBufferOut: &sampleBuffer
        )
        
        guard sampleStatus == noErr else {
            return nil
        }
        
        return sampleBuffer
    }
    
    // MARK: - File System Helpers
    
    static func createTempDirectory() -> String {
        let tempDir = NSTemporaryDirectory()
        let dirName = "QuickRecorderTests_\(UUID().uuidString)"
        let fullPath = (tempDir as NSString).appendingPathComponent(dirName)
        
        try? FileManager.default.createDirectory(
            atPath: fullPath,
            withIntermediateDirectories: true,
            attributes: nil
        )
        
        return fullPath
    }
    
    static func createTempFile(extension ext: String = "txt", in directory: String? = nil) -> String {
        let dir = directory ?? NSTemporaryDirectory()
        let fileName = "test_file_\(UUID().uuidString).\(ext)"
        let filePath = (dir as NSString).appendingPathComponent(fileName)
        
        FileManager.default.createFile(
            atPath: filePath,
            contents: "test content".data(using: .utf8),
            attributes: nil
        )
        
        return filePath
    }
    
    static func cleanupTempDirectory(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
    
    // MARK: - Time Helpers
    
    static func createCMTime(seconds: Double, timescale: Int32 = 600) -> CMTime {
        return CMTime(seconds: seconds, preferredTimescale: timescale)
    }
    
    // MARK: - Assertion Helpers
    
    static func assertTimeEqual(_ time1: CMTime, _ time2: CMTime, accuracy: Double = 0.001, file: StaticString = #file, line: UInt = #line) {
        let diff = abs(CMTimeGetSeconds(time1) - CMTimeGetSeconds(time2))
        XCTAssertLessThan(diff, accuracy, "Times differ by \(diff) seconds", file: file, line: line)
    }
    
    // MARK: - SCContext State Cleanup Helper
    
    static func cleanupSCContextState() {
        SCContext.streamType = nil
        SCContext.stream = nil
        SCContext.screen = nil
        SCContext.window = nil
        SCContext.application = nil
        SCContext.vW = nil
        SCContext.vwInput = nil
        SCContext.awInput = nil
        SCContext.micInput = nil
        SCContext.audioFile = nil
        SCContext.audioFile2 = nil
        SCContext.filePath = nil
        SCContext.filePath1 = nil
        SCContext.filePath2 = nil
        SCContext.startTime = nil
        SCContext.isPaused = false
        SCContext.isResume = false
        SCContext.timePassed = 0
        SCContext.filter = nil
    }
}

/// Extension to XCTestCase for common test setup
extension XCTestCase {

    func withTestUserDefaults(_ block: (UserDefaults) throws -> Void) rethrows {
        let suiteName = "test.quickrecorder.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? UserDefaults.standard
        defaults.removePersistentDomain(forName: suiteName)
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }
        try block(defaults)
    }
    
    func withTempDirectory(_ block: (String) throws -> Void) rethrows {
        let dir = TestHelpers.createTempDirectory()
        defer {
            TestHelpers.cleanupTempDirectory(dir)
        }
        try block(dir)
    }
}
