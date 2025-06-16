//
//  SettingsManager.swift
//  QuickRecorder
//
//  Created by Code Inspector on 2024/12/19.
//

import Foundation
import SwiftUI

/// Centralized settings manager to replace scattered @AppStorage declarations
/// and provide type-safe access to user preferences
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    private let userDefaults = UserDefaults.standard
    
    // MARK: - UI Settings
    @AppStorage("showOnDock") var showOnDock: Bool = true
    @AppStorage("showMenubar") var showMenubar: Bool = false
    @AppStorage("miniStatusBar") var miniStatusBar: Bool = false
    @AppStorage("showPreview") var showPreview: Bool = true
    @AppStorage("hideCCenter") var hideCCenter: Bool = false
    
    // MARK: - Recording Settings
    @AppStorage("recordMic") var recordMic: Bool = false
    @AppStorage("micDevice") var micDevice: String = "default"
    @AppStorage("recordWinSound") var recordWinSound: Bool = true
    @AppStorage("recordHDR") var recordHDR: Bool = false
    @AppStorage("highlightMouse") var highlightMouse: Bool = false
    @AppStorage("showMouse") var showMouse: Bool = true
    @AppStorage("includeMenuBar") var includeMenuBar: Bool = true
    @AppStorage("hideDesktopFiles") var hideDesktopFiles: Bool = false
    @AppStorage("hideSelf") var hideSelf: Bool = true
    @AppStorage("preventSleep") var preventSleep: Bool = true
    
    // MARK: - Audio Settings
    @AppStorage("enableAEC") var enableAEC: Bool = false
    @AppStorage("AECLevel") var AECLevel: String = "mid"
    @AppStorage("remuxAudio") var remuxAudio: Bool = true
    @AppStorage("audioFormat") var audioFormat: AudioFormat = .aac
    @AppStorage("audioQuality") var audioQuality: AudioQuality = .high
    
    // MARK: - Video Settings
    @AppStorage("encoder") var encoder: Encoder = .h265
    @AppStorage("highRes") var highRes: Int = 2
    @AppStorage("frameRate") var frameRate: Int = 60
    @AppStorage("videoQuality") var videoQuality: Double = 1.0
    @AppStorage("videoFormat") var videoFormat: VideoFormat = .mp4
    @AppStorage("pixelFormat") var pixelFormat: PixFormat = .delault
    @AppStorage("withAlpha") var withAlpha: Bool = false
    @AppStorage("background") var background: BackgroundType = .wallpaper
    
    // MARK: - Area Selection Settings
    @AppStorage("areaWidth") var areaWidth: Int = 600
    @AppStorage("areaHeight") var areaHeight: Int = 450
    
    // MARK: - Recording Control Settings
    @AppStorage("countdown") var countdown: Int = 0
    @AppStorage("poSafeDelay") var poSafeDelay: Int = 1
    @AppStorage("trimAfterRecord") var trimAfterRecord: Bool = false
    
    // MARK: - Directory Settings
    @AppStorage("saveDirectory") var saveDirectory: String?
    
    private init() {}
    
    // MARK: - Safe Access Methods
    
    /// Safely get save directory with fallback
    func getSaveDirectory() -> String {
        return saveDirectory ?? getDefaultSaveDirectory()
    }
    
    /// Get default save directory
    private func getDefaultSaveDirectory() -> String {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first?.path ?? ""
        return documentsPath + "/QuickRecorder"
    }
    
    /// Safely get audio format string
    func getAudioFormatString() -> String {
        return audioFormat.rawValue
    }
    
    /// Safely get video format string  
    func getVideoFormatString() -> String {
        return videoFormat.rawValue
    }
    
    /// Safely get audio quality value
    func getAudioQualityValue() -> Int {
        return audioQuality.rawValue
    }
    
    // MARK: - Validation Methods
    
    /// Validate and correct settings if needed
    func validateSettings() {
        // Ensure save directory exists
        if saveDirectory == nil {
            saveDirectory = getDefaultSaveDirectory()
        }
        
        // Validate frame rate
        if frameRate <= 0 || frameRate > 120 {
            frameRate = 60
        }
        
        // Validate video quality
        if videoQuality <= 0 || videoQuality > 1 {
            videoQuality = 1.0
        }
        
        // Validate area dimensions
        if areaWidth <= 0 { areaWidth = 600 }
        if areaHeight <= 0 { areaHeight = 450 }
    }
    
    // MARK: - Convenience Methods
    
    /// Check if microphone recording is properly configured
    var isMicrophoneConfigured: Bool {
        return recordMic && !micDevice.isEmpty
    }
    
    /// Check if AEC warning should be shown
    var shouldShowAECWarning: Bool {
        return micDevice != "default" && enableAEC && recordMic
    }
}

// MARK: - Legacy Support Extensions

extension SettingsManager {
    /// Legacy UserDefaults access for compatibility
    func legacyBool(forKey key: String) -> Bool {
        return userDefaults.bool(forKey: key)
    }
    
    func legacyString(forKey key: String) -> String? {
        return userDefaults.string(forKey: key)
    }
    
    func legacyInteger(forKey key: String) -> Int {
        return userDefaults.integer(forKey: key)
    }
    
    func legacySet(_ value: Any?, forKey key: String) {
        userDefaults.set(value, forKey: key)
    }
} 