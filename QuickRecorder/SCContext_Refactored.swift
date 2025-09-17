//
//  SCContext_Refactored.swift
//  QuickRecorder
//
//  Created by Refactoring on 2025/09/16.
//

import AVFAudio
import AVFoundation
import Foundation
import ScreenCaptureKit
import UserNotifications
import SwiftLAME
import SwiftUI
import AECAudioStream

/// Refactored SCContext that delegates to focused manager classes
/// 
/// This class maintains backward compatibility with the original SCContext while
/// delegating functionality to focused manager classes. It serves as a facade
/// that provides the same API as the original SCContext but with improved
/// architecture and maintainability.
/// 
/// The refactored architecture separates concerns into focused managers:
/// - ScreenCaptureManager: Handles screen capture content and permissions
/// - AudioManager: Manages audio recording and processing
/// - VideoManager: Handles video recording and asset writing
/// - RecordingStateManager: Manages recording state and timing
/// 
/// Key benefits:
/// - Maintains backward compatibility with existing code
/// - Improved separation of concerns
/// - Better testability and maintainability
/// - Cleaner, more focused code organization
/// - Easier to extend and modify individual components
/// 
/// Usage:
/// ```swift
/// // All existing SCContext usage continues to work
/// SCContext.startRecording()
/// SCContext.audioEngine.start()
/// let windows = SCContext.getWindows()
/// ```
class SCContext {
    
    // MARK: - Backward Compatibility Properties
    
    // Screen Capture Properties
    static var availableContent: SCShareableContent? {
        get { ScreenCaptureManager.availableContent }
        set { ScreenCaptureManager.availableContent = newValue }
    }
    
    static var filter: SCContentFilter? {
        get { ScreenCaptureManager.filter }
        set { ScreenCaptureManager.filter = newValue }
    }
    
    static var stream: SCStream? {
        get { ScreenCaptureManager.stream }
        set { ScreenCaptureManager.stream = newValue }
    }
    
    static var screen: SCDisplay? {
        get { ScreenCaptureManager.screen }
        set { ScreenCaptureManager.screen = newValue }
    }
    
    static var window: [SCWindow]? {
        get { ScreenCaptureManager.window }
        set { ScreenCaptureManager.window = newValue }
    }
    
    static var application: [SCRunningApplication]? {
        get { ScreenCaptureManager.application }
        set { ScreenCaptureManager.application = newValue }
    }
    
    static var streamType: StreamType? {
        get { ScreenCaptureManager.streamType }
        set { ScreenCaptureManager.streamType = newValue }
    }
    
    static var screenArea: NSRect? {
        get { ScreenCaptureManager.screenArea }
        set { ScreenCaptureManager.screenArea = newValue }
    }
    
    static var backgroundColor: CGColor {
        get { ScreenCaptureManager.backgroundColor }
        set { ScreenCaptureManager.backgroundColor = newValue }
    }
    
    // Audio Properties
    static var audioEngine: AVAudioEngine {
        return AudioManager.audioEngine
    }
    
    static var AECEngine: AECAudioStream {
        return AudioManager.AECEngine
    }
    
    static var audioFile: AVAudioFile? {
        get { AudioManager.audioFile }
        set { AudioManager.audioFile = newValue }
    }
    
    static var audioFile2: AVAudioFile? {
        get { AudioManager.audioFile2 }
        set { AudioManager.audioFile2 = newValue }
    }
    
    static var awInput: AVAssetWriterInput? {
        get { AudioManager.awInput }
        set { AudioManager.awInput = newValue }
    }
    
    static var micInput: AVAssetWriterInput? {
        get { AudioManager.micInput }
        set { AudioManager.micInput = newValue }
    }
    
    static var recordDevice: String {
        get { AudioManager.recordDevice }
        set { AudioManager.recordDevice = newValue }
    }
    
    static var recordCam: String {
        get { AudioManager.recordCam }
        set { AudioManager.recordCam = newValue }
    }
    
    // Video Properties
    static var vW: AVAssetWriter? {
        get { VideoManager.assetWriter }
        set { VideoManager.assetWriter = newValue }
    }
    
    static var vwInput: AVAssetWriterInput? {
        get { VideoManager.videoInput }
        set { VideoManager.videoInput = newValue }
    }
    
    static var captureSession: AVCaptureSession? {
        get { VideoManager.captureSession }
        set { VideoManager.captureSession = newValue }
    }
    
    static var previewSession: AVCaptureSession? {
        get { VideoManager.previewSession }
        set { VideoManager.previewSession = newValue }
    }
    
    static var frameCache: CMSampleBuffer? {
        get { VideoManager.frameCache }
        set { VideoManager.frameCache = newValue }
    }
    
    static var firstFrame: CMSampleBuffer? {
        get { VideoManager.firstFrame }
        set { VideoManager.firstFrame = newValue }
    }
    
    static var lastPTS: CMTime? {
        get { VideoManager.lastPTS }
        set { VideoManager.lastPTS = newValue }
    }
    
    static var timeOffset: CMTime {
        get { VideoManager.timeOffset }
        set { VideoManager.timeOffset = newValue }
    }
    
    // Recording State Properties
    static var startTime: Date? {
        get { RecordingStateManager.startTime }
        set { RecordingStateManager.startTime = newValue }
    }
    
    static var timePassed: TimeInterval {
        get { RecordingStateManager.timePassed }
        set { RecordingStateManager.timePassed = newValue }
    }
    
    static var isPaused: Bool {
        get { RecordingStateManager.isPaused }
        set { RecordingStateManager.isPaused = newValue }
    }
    
    static var isResume: Bool {
        get { RecordingStateManager.isResume }
        set { RecordingStateManager.isResume = newValue }
    }
    
    static var isSkipFrame: Bool {
        get { RecordingStateManager.isSkipFrame }
        set { RecordingStateManager.isSkipFrame = newValue }
    }
    
    static var autoStop: Int {
        get { RecordingStateManager.autoStop }
        set { RecordingStateManager.autoStop = newValue }
    }
    
    static var saveFrame: Bool {
        get { RecordingStateManager.saveFrame }
        set { RecordingStateManager.saveFrame = newValue }
    }
    
    static var filePath: String? {
        get { RecordingStateManager.filePath }
        set { RecordingStateManager.filePath = newValue }
    }
    
    static var filePath1: String? {
        get { RecordingStateManager.filePath1 }
        set { RecordingStateManager.filePath1 = newValue }
    }
    
    static var filePath2: String? {
        get { RecordingStateManager.filePath2 }
        set { RecordingStateManager.filePath2 = newValue }
    }
    
    static var trimingList: [URL] {
        get { RecordingStateManager.trimmingList }
        set { RecordingStateManager.trimmingList = newValue }
    }
    
    // UI State Properties (keeping these in SCContext for now)
    static var isMagnifierEnabled = false
    static let excludedApps = ScreenCaptureManager.excludedApps
    
    // MARK: - Screen Capture Methods
    
    static func updateAvailableContentSync() -> SCShareableContent? {
        return ScreenCaptureManager.updateAvailableContentSync()
    }
    
    static func updateAvailableContent(completion: @escaping () -> Void) {
        ScreenCaptureManager.updateAvailableContent(completion: completion)
    }
    
    static func requestScreenRecordingPermissionIfNeeded() async -> Bool {
        return await ScreenCaptureManager.requestScreenRecordingPermissionIfNeeded()
    }
    
    static func getWindows(isOnScreen: Bool = true, hideSelf: Bool = true) -> [SCWindow] {
        return ScreenCaptureManager.getWindows(isOnScreen: isOnScreen, hideSelf: hideSelf)
    }
    
    static func getSelf() -> SCWindow? {
        return ScreenCaptureManager.getSelf()
    }
    
    static func getSelfWindows() -> [SCWindow] {
        return ScreenCaptureManager.getSelfWindows()
    }
    
    static func getDisplays() -> [SCDisplay] {
        return ScreenCaptureManager.getDisplays()
    }
    
    static func getApplications() -> [SCRunningApplication] {
        return ScreenCaptureManager.getApplications()
    }
    
    // MARK: - Audio Methods
    
    static func startAudioEngine() -> Result<Void, Error> {
        return AudioManager.startAudioEngine()
    }
    
    static func stopAudioEngine() {
        AudioManager.stopAudioEngine()
    }
    
    static func resetAudioEngine() {
        AudioManager.resetAudioEngine()
    }
    
    static func createAudioFile(url: URL, settings: [String: Any]) -> Result<AVAudioFile, Error> {
        return AudioManager.createAudioFile(url: url, settings: settings)
    }
    
    static func cleanupAudioFiles() {
        AudioManager.cleanupAudioFiles()
    }
    
    // MARK: - Video Methods
    
    static func createAssetWriter(url: URL, fileType: AVFileType) -> Result<AVAssetWriter, Error> {
        return VideoManager.createAssetWriter(url: url, fileType: fileType)
    }
    
    static func startAssetWriter() -> Bool {
        return VideoManager.startAssetWriter()
    }
    
    static func finishAssetWriter() -> Bool {
        return VideoManager.finishAssetWriter()
    }
    
    static func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Bool {
        return VideoManager.appendVideoSampleBuffer(sampleBuffer)
    }
    
    static func processVideoFrame(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        return VideoManager.processVideoFrame(sampleBuffer)
    }
    
    // MARK: - Recording State Methods
    
    static func startRecording() {
        RecordingStateManager.startRecording()
    }
    
    static func pauseRecording() {
        RecordingStateManager.pauseRecording()
    }
    
    static func resumeRecording() {
        RecordingStateManager.resumeRecording()
    }
    
    static func stopRecording() {
        RecordingStateManager.stopRecording()
    }
    
    static func updateRecordingTime() {
        RecordingStateManager.updateRecordingTime()
    }
    
    static func getRecordingDuration() -> TimeInterval {
        return RecordingStateManager.getRecordingDuration()
    }
    
    static func getFormattedDuration() -> String {
        return RecordingStateManager.getFormattedDuration()
    }
    
    static func generateFilePath(baseDirectory: String, fileName: String, extension: String) -> String? {
        return RecordingStateManager.generateFilePath(baseDirectory: baseDirectory, fileName: fileName, extension: extension)
    }
    
    // MARK: - File Path Methods (Legacy Compatibility)
    
    static func getSaveDirectory() -> String {
        return SettingsManager.shared.getSaveDirectory()
    }
    
    // MARK: - Cleanup Methods
    
    static func cleanup() {
        AudioManager.cleanupAudioFiles()
        VideoManager.cleanup()
        RecordingStateManager.resetState()
    }
    
    static func resetState() {
        RecordingStateManager.resetState()
    }
}
