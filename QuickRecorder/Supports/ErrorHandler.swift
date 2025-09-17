//
//  ErrorHandler.swift
//  QuickRecorder
//
//  Created by Code Inspector on 2025/06/16.
//

import Foundation
import AVFoundation
import UserNotifications

/// Comprehensive error handling utility for QuickRecorder
/// 
/// This enum defines all possible errors that can occur during recording operations.
/// Each error case includes contextual information to help with debugging and user feedback.
/// All errors conform to LocalizedError for proper user-facing error messages.
enum RecordingError: LocalizedError {
    /// Audio file creation failed with specific error details
    case audioFileCreationFailed(String)
    
    /// Audio engine startup failed with specific error details
    case audioEngineStartFailed(String)
    
    /// Video asset writer creation failed with specific error details
    case videoWriterCreationFailed(String)
    
    /// Directory creation failed with specific error details
    case directoryCreationFailed(String)
    
    /// Unsupported audio format was requested
    case audioFormatUnsupported(String)
    
    /// File size information could not be retrieved
    case fileSizeCastFailed
    
    /// Saved area coordinates could not be parsed
    case savedAreaCastFailed
    
    /// Screen capture setup failed with specific error details
    case screenCaptureSetupFailed(String)
    
    /// Export operation failed with specific error details
    case exportFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .audioFileCreationFailed(let details):
            return "Failed to create audio file: \(details)"
        case .audioEngineStartFailed(let details):
            return "Failed to start audio engine: \(details)"
        case .videoWriterCreationFailed(let details):
            return "Failed to create video writer: \(details)"
        case .directoryCreationFailed(let details):
            return "Failed to create directory: \(details)"
        case .audioFormatUnsupported(let format):
            return "Unsupported audio format: \(format)"
        case .fileSizeCastFailed:
            return "Failed to get file size information"
        case .savedAreaCastFailed:
            return "Failed to parse saved area coordinates"
        case .screenCaptureSetupFailed(let details):
            return "Failed to setup screen capture: \(details)"
        case .exportFailed(let details):
            return "Export operation failed: \(details)"
        }
    }
}

/// Error handler for safe operations throughout QuickRecorder
/// 
/// This singleton class provides centralized error handling and safe operation wrappers
/// for all critical operations in the application. It eliminates dangerous force unwraps
/// and provides consistent error handling patterns.
/// 
/// Key features:
/// - Safe audio file creation with proper error handling
/// - Safe audio engine startup with fallback mechanisms
/// - Safe video writer creation with validation
/// - Safe directory operations with user-friendly error messages
/// - Type-safe casting operations with fallback values
/// - Automatic error reporting and user notification
class ErrorHandler {
    /// Shared singleton instance for global error handling
    static let shared = ErrorHandler()
    
    private init() {}
    
    // MARK: - Audio File Operations
    
    /// Safely create an AVAudioFile
    func createAudioFile(url: URL, settings: [String: Any]) -> Result<AVAudioFile, RecordingError> {
        do {
            let audioFile = try AVAudioFile(forWriting: url, settings: settings, commonFormat: .pcmFormatFloat32, interleaved: false)
            return .success(audioFile)
        } catch {
            return .failure(.audioFileCreationFailed(error.localizedDescription))
        }
    }
    
    /// Safely start audio engine
    func startAudioEngine(_ engine: AVAudioEngine) -> Result<Void, RecordingError> {
        do {
            try engine.start()
            return .success(())
        } catch {
            return .failure(.audioEngineStartFailed(error.localizedDescription))
        }
    }
    
    // MARK: - Video Writer Operations
    
    /// Safely create an AVAssetWriter
    func createAssetWriter(url: URL, fileType: AVFileType) -> Result<AVAssetWriter, RecordingError> {
        do {
            let writer = try AVAssetWriter(outputURL: url, fileType: fileType)
            return .success(writer)
        } catch {
            return .failure(.videoWriterCreationFailed(error.localizedDescription))
        }
    }
    
    // MARK: - File System Operations
    
    /// Safely create directory
    func createDirectory(at path: String) -> Result<Void, RecordingError> {
        do {
            try FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: true, attributes: nil)
            return .success(())
        } catch {
            return .failure(.directoryCreationFailed(error.localizedDescription))
        }
    }
    
    /// Safely get file size
    func getFileSize(at path: String) -> Result<Int64, RecordingError> {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            guard let size = attributes[FileAttributeKey.size] as? Int64 else {
                return .failure(.fileSizeCastFailed)
            }
            return .success(size)
        } catch {
            return .failure(.fileSizeCastFailed)
        }
    }
    
    // MARK: - Type Casting Operations
    
    /// Safely cast saved area dictionary
    func parseSavedArea(from object: Any?) -> Result<[String: [String: CGFloat]], RecordingError> {
        guard let savedArea = object as? [String: [String: CGFloat]] else {
            return .failure(.savedAreaCastFailed)
        }
        return .success(savedArea)
    }
    
    /// Safely get CGFloat values from area dictionary  
    func getCGFloatFromArea(_ area: [String: Any], key: String) -> CGFloat {
        if let value = area[key] as? CGFloat {
            return value
        } else if let value = area[key] as? Double {
            return CGFloat(value)
        } else if let value = area[key] as? Int {
            return CGFloat(value)
        } else if let value = area[key] as? Float {
            return CGFloat(value)
        }
        return 0.0
    }
    
    // MARK: - Error Notification
    
    /// Show error notification to user
    func showError(_ error: RecordingError, title: String = "Recording Error") {
        let errorMessage = error.localizedDescription
        DispatchQueue.main.async {
            SCContext.showNotification(title: title, body: errorMessage, id: "quickrecorder.error.\(UUID().uuidString)")
        }
    }
    
    /// Handle error with logging and optional user notification
    func handleError(_ error: RecordingError, showToUser: Bool = true, context: String = "") {
        let logMessage = context.isEmpty ? error.localizedDescription : "\(context): \(error.localizedDescription)"
        print("🚨 QuickRecorder Error: \(logMessage)")
        
        if showToUser {
            showError(error)
        }
    }
    
    // MARK: - Result Helpers
    
    /// Execute a throwing operation safely
    func safeExecute<T>(_ operation: () throws -> T, errorTransform: (Error) -> RecordingError) -> Result<T, RecordingError> {
        do {
            let result = try operation()
            return .success(result)
        } catch {
            return .failure(errorTransform(error))
        }
    }
    
    /// Execute an async throwing operation safely
    func safeExecuteAsync<T>(_ operation: () async throws -> T, errorTransform: (Error) -> RecordingError) async -> Result<T, RecordingError> {
        do {
            let result = try await operation()
            return .success(result)
        } catch {
            return .failure(errorTransform(error))
        }
    }
}

// MARK: - Convenience Extensions

extension Result where Failure == RecordingError {
    /// Handle result with automatic error reporting
    func handleWithErrorReporting(context: String = "", showToUser: Bool = true) -> Success? {
        switch self {
        case .success(let value):
            return value
        case .failure(let error):
            ErrorHandler.shared.handleError(error, showToUser: showToUser, context: context)
            return nil
        }
    }
} 