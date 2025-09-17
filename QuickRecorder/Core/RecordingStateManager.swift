//
//  RecordingStateManager.swift
//  QuickRecorder
//
//  Created by Refactoring on 2025/09/16.
//

import Foundation
import AVFoundation

/// Manages recording state, timing, and file operations
/// 
/// This class handles all recording state management including:
/// - Recording session lifecycle (start, pause, resume, stop)
/// - Time tracking and duration calculation
/// - File path management and generation
/// - Frame processing state (skip, save)
/// - Auto-stop functionality
/// - Trimming list management
/// 
/// The class provides a centralized interface for all recording state operations,
/// ensuring consistent state management and validation.
/// 
/// Key responsibilities:
/// - Recording session state management
/// - Time tracking and formatting
/// - File path generation and validation
/// - Frame processing control
/// - Auto-stop timer management
/// - State validation and cleanup
/// 
/// Usage:
/// ```swift
/// // Start recording
/// RecordingStateManager.startRecording()
/// 
/// // Get formatted duration
/// let duration = RecordingStateManager.getFormattedDuration()
/// 
/// // Generate file path
/// let path = RecordingStateManager.generateFilePath(baseDirectory: dir, fileName: "recording", extension: "mp4")
/// ```
class RecordingStateManager {
    
    // MARK: - Properties
    
    /// Recording start time
    static var startTime: Date?
    
    /// Time passed during recording
    static var timePassed: TimeInterval = 0
    
    /// Whether recording is currently paused
    static var isPaused = false
    
    /// Whether recording is resuming
    static var isResume = false
    
    /// Whether to skip current frame
    static var isSkipFrame = false
    
    /// Auto-stop counter
    static var autoStop = 0
    
    /// Whether to save current frame
    static var saveFrame = false
    
    /// Primary file path for recording
    static var filePath: String?
    
    /// Secondary file path for recording
    static var filePath1: String?
    
    /// Tertiary file path for recording
    static var filePath2: String?
    
    /// List of files for trimming
    static var trimmingList = [URL]()
    
    // MARK: - Recording State Management
    
    /// Starts recording session
    static func startRecording() {
        startTime = Date()
        timePassed = 0
        isPaused = false
        isResume = false
        isSkipFrame = false
        autoStop = 0
        saveFrame = false
    }
    
    /// Pauses recording
    static func pauseRecording() {
        isPaused = true
        isResume = false
    }
    
    /// Resumes recording
    static func resumeRecording() {
        isPaused = false
        isResume = true
    }
    
    /// Stops recording
    static func stopRecording() {
        isPaused = false
        isResume = false
        isSkipFrame = false
        startTime = nil
        timePassed = 0
    }
    
    /// Updates recording time
    static func updateRecordingTime() {
        guard let startTime = startTime else { return }
        timePassed = Date().timeIntervalSince(startTime)
    }
    
    /// Gets current recording duration
    /// - Returns: Recording duration in seconds
    static func getRecordingDuration() -> TimeInterval {
        return timePassed
    }
    
    /// Gets formatted recording duration
    /// - Returns: Formatted duration string (HH:MM:SS)
    static func getFormattedDuration() -> String {
        let duration = getRecordingDuration()
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    // MARK: - File Path Management
    
    /// Sets primary file path
    /// - Parameter path: File path to set
    static func setFilePath(_ path: String) {
        filePath = path
    }
    
    /// Sets secondary file path
    /// - Parameter path: File path to set
    static func setFilePath1(_ path: String) {
        filePath1 = path
    }
    
    /// Sets tertiary file path
    /// - Parameter path: File path to set
    static func setFilePath2(_ path: String) {
        filePath2 = path
    }
    
    /// Gets primary file path
    /// - Returns: Primary file path or nil
    static func getFilePath() -> String? {
        return filePath
    }
    
    /// Gets secondary file path
    /// - Returns: Secondary file path or nil
    static func getFilePath1() -> String? {
        return filePath1
    }
    
    /// Gets tertiary file path
    /// - Returns: Tertiary file path or nil
    static func getFilePath2() -> String? {
        return filePath2
    }
    
    /// Generates file path for recording
    /// - Parameters:
    ///   - baseDirectory: Base directory for the file
    ///   - fileName: File name
    ///   - extension: File extension
    /// - Returns: Generated file path or nil if generation failed
    static func generateFilePath(baseDirectory: String, fileName: String, extension: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let fullFileName = "\(fileName)_\(timestamp).\(extension)"
        let filePath = "\(baseDirectory)/\(fullFileName)"
        
        return filePath
    }
    
    // MARK: - Trimming Management
    
    /// Adds file to trimming list
    /// - Parameter url: File URL to add
    static func addToTrimmingList(_ url: URL) {
        trimmingList.append(url)
    }
    
    /// Removes file from trimming list
    /// - Parameter url: File URL to remove
    static func removeFromTrimmingList(_ url: URL) {
        trimmingList.removeAll { $0 == url }
    }
    
    /// Clears trimming list
    static func clearTrimmingList() {
        trimmingList.removeAll()
    }
    
    /// Gets trimming list
    /// - Returns: Array of file URLs for trimming
    static func getTrimmingList() -> [URL] {
        return trimmingList
    }
    
    // MARK: - Frame Management
    
    /// Sets frame skip flag
    /// - Parameter skip: Whether to skip frame
    static func setSkipFrame(_ skip: Bool) {
        isSkipFrame = skip
    }
    
    /// Sets save frame flag
    /// - Parameter save: Whether to save frame
    static func setSaveFrame(_ save: Bool) {
        saveFrame = save
    }
    
    /// Gets frame skip flag
    /// - Returns: Whether to skip frame
    static func shouldSkipFrame() -> Bool {
        return isSkipFrame
    }
    
    /// Gets save frame flag
    /// - Returns: Whether to save frame
    static func shouldSaveFrame() -> Bool {
        return saveFrame
    }
    
    // MARK: - Auto-stop Management
    
    /// Sets auto-stop counter
    /// - Parameter count: Auto-stop count
    static func setAutoStop(_ count: Int) {
        autoStop = count
    }
    
    /// Gets auto-stop counter
    /// - Returns: Auto-stop count
    static func getAutoStop() -> Int {
        return autoStop
    }
    
    /// Decrements auto-stop counter
    static func decrementAutoStop() {
        if autoStop > 0 {
            autoStop -= 1
        }
    }
    
    /// Checks if auto-stop should trigger
    /// - Returns: True if auto-stop should trigger
    static func shouldAutoStop() -> Bool {
        return autoStop <= 0 && autoStop != -1
    }
    
    // MARK: - State Validation
    
    /// Validates recording state
    /// - Returns: True if state is valid, false otherwise
    static func validateRecordingState() -> Bool {
        // Check if we have a valid start time when recording
        if !isPaused && startTime == nil {
            print("Warning: Recording is active but start time is nil")
            return false
        }
        
        // Check if we have file paths when recording
        if !isPaused && filePath == nil {
            print("Warning: Recording is active but file path is nil")
            return false
        }
        
        return true
    }
    
    /// Resets all recording state
    static func resetState() {
        startTime = nil
        timePassed = 0
        isPaused = false
        isResume = false
        isSkipFrame = false
        autoStop = 0
        saveFrame = false
        filePath = nil
        filePath1 = nil
        filePath2 = nil
        trimmingList.removeAll()
    }
}
