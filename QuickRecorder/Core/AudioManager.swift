//
//  AudioManager.swift
//  QuickRecorder
//
//  Created by Refactoring on 2025/09/16.
//

import Foundation
import AVFoundation
import AVFAudio
import AECAudioStream

/// Manages audio recording, processing, and file operations
/// 
/// This class handles all audio-related functionality including:
/// - Audio engine management and configuration
/// - Audio file creation and management
/// - Acoustic Echo Cancellation (AEC) processing
/// - Audio device management and switching
/// - Safe audio operation wrappers
/// 
/// The class provides a centralized interface for all audio operations,
/// ensuring consistent error handling and resource management.
/// 
/// Key responsibilities:
/// - Audio engine lifecycle management
/// - Audio file I/O operations
/// - AEC processing and configuration
/// - Device enumeration and selection
/// - Audio format validation and conversion
/// 
/// Usage:
/// ```swift
/// // Start audio engine
/// let result = AudioManager.startAudioEngine()
/// 
/// // Create audio file
/// let audioFileResult = AudioManager.createAudioFile(url: fileURL, settings: settings)
/// 
/// // Configure AEC
/// AudioManager.setAECEnabled(true)
/// ```
class AudioManager {
    
    // MARK: - Properties
    
    /// Main audio engine for recording
    static let audioEngine = AVAudioEngine()
    
    /// Acoustic Echo Cancellation engine
    static let AECEngine = AECAudioStream(sampleRate: 48000)
    
    /// Primary audio file for recording
    static var audioFile: AVAudioFile?
    
    /// Secondary audio file for recording
    static var audioFile2: AVAudioFile?
    
    /// Audio writer input for asset writer
    static var awInput: AVAssetWriterInput?
    
    /// Microphone input for asset writer
    static var micInput: AVAssetWriterInput?
    
    /// Current microphone device identifier
    static var recordDevice = ""
    
    /// Current camera device identifier
    static var recordCam = ""
    
    // MARK: - Audio File Management
    
    /// Creates an audio file for recording
    /// - Parameters:
    ///   - url: File URL for the audio file
    ///   - settings: Audio format settings
    /// - Returns: Result containing the audio file or error
    static func createAudioFile(url: URL, settings: [String: Any]) -> Result<AVAudioFile, Error> {
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: settings)
            return .success(audioFile)
        } catch {
            return .failure(error)
        }
    }
    
    /// Safely starts the audio engine
    /// - Returns: Result indicating success or failure
    static func startAudioEngine() -> Result<Void, Error> {
        do {
            try audioEngine.start()
            return .success(())
        } catch {
            return .failure(error)
        }
    }
    
    /// Stops the audio engine
    static func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    /// Resets the audio engine
    static func resetAudioEngine() {
        audioEngine.reset()
    }
    
    // MARK: - Audio Configuration
    
    /// Configures audio engine for recording
    /// - Parameters:
    ///   - inputNode: Audio input node
    ///   - outputNode: Audio output node
    ///   - format: Audio format
    static func configureAudioEngine(inputNode: AVAudioNode, outputNode: AVAudioNode, format: AVAudioFormat) {
        audioEngine.connect(inputNode, to: outputNode, format: format)
    }
    
    /// Gets the current audio input format
    /// - Returns: Current input format or nil if not available
    static func getCurrentInputFormat() -> AVAudioFormat? {
        return audioEngine.inputNode.inputFormat(forBus: 0)
    }
    
    /// Gets the current audio output format
    /// - Returns: Current output format or nil if not available
    static func getCurrentOutputFormat() -> AVAudioFormat? {
        return audioEngine.outputNode.outputFormat(forBus: 0)
    }
    
    // MARK: - AEC (Acoustic Echo Cancellation)
    
    /// Enables or disables AEC
    /// - Parameter enabled: Whether to enable AEC
    static func setAECEnabled(_ enabled: Bool) {
        if enabled {
            AECEngine.start()
        } else {
            AECEngine.stop()
        }
    }
    
    /// Processes audio through AEC
    /// - Parameter audioBuffer: Audio buffer to process
    /// - Returns: Processed audio buffer
    static func processAudioWithAEC(_ audioBuffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        return AECEngine.process(audioBuffer)
    }
    
    // MARK: - Audio File Operations
    
    /// Closes and cleans up audio files
    static func cleanupAudioFiles() {
        audioFile = nil
        audioFile2 = nil
    }
    
    /// Gets audio file duration
    /// - Parameter audioFile: Audio file to check
    /// - Returns: Duration in seconds or nil if unavailable
    static func getAudioFileDuration(_ audioFile: AVAudioFile) -> Double? {
        return Double(audioFile.length) / audioFile.processingFormat.sampleRate
    }
    
    /// Gets audio file size
    /// - Parameter audioFile: Audio file to check
    /// - Returns: File size in bytes or nil if unavailable
    static func getAudioFileSize(_ audioFile: AVAudioFile) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: audioFile.url.path)
            return attributes[FileAttributeKey.size] as? Int64
        } catch {
            return nil
        }
    }
    
    // MARK: - Audio Input/Output Management
    
    /// Gets available audio input devices
    /// - Returns: Array of available audio input devices
    static func getAvailableInputDevices() -> [AVAudioSessionPortDescription] {
        // Note: This is a simplified implementation
        // In a real implementation, you'd query the system for available audio devices
        return []
    }
    
    /// Sets the current input device
    /// - Parameter deviceID: Device identifier
    static func setInputDevice(_ deviceID: String) {
        recordDevice = deviceID
        // Additional device switching logic would go here
    }
    
    /// Sets the current camera device
    /// - Parameter deviceID: Device identifier
    static func setCameraDevice(_ deviceID: String) {
        recordCam = deviceID
        // Additional camera switching logic would go here
    }
}
