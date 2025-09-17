//
//  VideoManager.swift
//  QuickRecorder
//
//  Created by Refactoring on 2025/09/16.
//

import Foundation
import AVFoundation
import ScreenCaptureKit

/// Manages video recording, asset writing, and stream operations
/// 
/// This class handles all video-related functionality including:
/// - Video asset writer creation and management
/// - Video input configuration and processing
/// - Frame processing and synchronization
/// - Camera session management
/// - Time offset and synchronization handling
/// 
/// The class provides a centralized interface for all video operations,
/// ensuring proper resource management and error handling.
/// 
/// Key responsibilities:
/// - Asset writer lifecycle management
/// - Video input configuration and validation
/// - Frame processing and time synchronization
/// - Camera session setup and teardown
/// - Video format validation and conversion
/// 
/// Usage:
/// ```swift
/// // Create asset writer
/// let writerResult = VideoManager.createAssetWriter(url: fileURL, fileType: .mp4)
/// 
/// // Process video frame
/// let processedFrame = VideoManager.processVideoFrame(sampleBuffer)
/// 
/// // Start camera session
/// VideoManager.startCameraSession()
/// ```
class VideoManager {
    
    // MARK: - Properties
    
    /// Main video asset writer
    static var assetWriter: AVAssetWriter?
    
    /// Video writer input
    static var videoInput: AVAssetWriterInput?
    
    /// Current capture session for camera
    static var captureSession: AVCaptureSession?
    
    /// Preview session for camera
    static var previewSession: AVCaptureSession?
    
    /// Cached frame for processing
    static var frameCache: CMSampleBuffer?
    
    /// First frame of recording
    static var firstFrame: CMSampleBuffer?
    
    /// Last presentation timestamp
    static var lastPTS: CMTime?
    
    /// Time offset for synchronization
    static var timeOffset = CMTimeMake(value: 0, timescale: 0)
    
    // MARK: - Asset Writer Management
    
    /// Creates an asset writer for video recording
    /// - Parameters:
    ///   - url: Output file URL
    ///   - fileType: Output file type
    /// - Returns: Result containing the asset writer or error
    static func createAssetWriter(url: URL, fileType: AVFileType) -> Result<AVAssetWriter, Error> {
        do {
            let writer = try AVAssetWriter(outputURL: url, fileType: fileType)
            return .success(writer)
        } catch {
            return .failure(error)
        }
    }
    
    /// Creates video input for asset writer
    /// - Parameters:
    ///   - settings: Video settings
    ///   - sourceFormatHint: Source format hint
    /// - Returns: Configured video input
    static func createVideoInput(settings: [String: Any], sourceFormatHint: CMFormatDescription? = nil) -> AVAssetWriterInput {
        let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings, sourceFormatHint: sourceFormatHint)
        input.expectsMediaDataInRealTime = true
        return input
    }
    
    /// Adds video input to asset writer
    /// - Parameters:
    ///   - input: Video input to add
    ///   - writer: Asset writer to add input to
    /// - Returns: True if successful, false otherwise
    static func addVideoInput(_ input: AVAssetWriterInput, to writer: AVAssetWriter) -> Bool {
        guard writer.canAdd(input) else {
            print("Cannot add video input to asset writer")
            return false
        }
        
        writer.add(input)
        videoInput = input
        return true
    }
    
    /// Starts the asset writer
    /// - Returns: True if successful, false otherwise
    static func startAssetWriter() -> Bool {
        guard let writer = assetWriter else {
            print("Asset writer is nil")
            return false
        }
        
        guard writer.startWriting() else {
            print("Failed to start asset writer: \(writer.error?.localizedDescription ?? "Unknown error")")
            return false
        }
        
        return true
    }
    
    /// Finishes the asset writer
    /// - Returns: True if successful, false otherwise
    static func finishAssetWriter() -> Bool {
        guard let writer = assetWriter else {
            print("Asset writer is nil")
            return false
        }
        
        writer.finishWriting { [weak writer] in
            if let error = writer?.error {
                print("Error finishing asset writer: \(error.localizedDescription)")
            } else {
                print("Asset writer finished successfully")
            }
        }
        
        return true
    }
    
    // MARK: - Frame Processing
    
    /// Appends a video sample buffer to the asset writer
    /// - Parameter sampleBuffer: Video sample buffer to append
    /// - Returns: True if successful, false otherwise
    static func appendVideoSampleBuffer(_ sampleBuffer: CMSampleBuffer) -> Bool {
        guard let input = videoInput, input.isReadyForMoreMediaData else {
            return false
        }
        
        // Cache first frame
        if firstFrame == nil {
            firstFrame = sampleBuffer
        }
        
        // Update last PTS
        lastPTS = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        
        // Cache frame
        frameCache = sampleBuffer
        
        return input.append(sampleBuffer)
    }
    
    /// Processes a video frame with time synchronization
    /// - Parameter sampleBuffer: Video sample buffer to process
    /// - Returns: Processed sample buffer or nil if processing failed
    static func processVideoFrame(_ sampleBuffer: CMSampleBuffer) -> CMSampleBuffer? {
        let presentationTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
        let adjustedTime = CMTimeAdd(presentationTime, timeOffset)
        
        var timingInfo = CMSampleTimingInfo()
        timingInfo.presentationTimeStamp = adjustedTime
        timingInfo.decodeTimeStamp = kCMTimeInvalid
        timingInfo.duration = CMSampleBufferGetDuration(sampleBuffer)
        
        var processedBuffer: CMSampleBuffer?
        let status = CMSampleBufferCreateCopyWithNewTiming(
            allocator: kCFAllocatorDefault,
            sampleBuffer: sampleBuffer,
            sampleTimingEntryCount: 1,
            sampleTimingArray: &timingInfo,
            sampleBufferOut: &processedBuffer
        )
        
        return status == noErr ? processedBuffer : nil
    }
    
    // MARK: - Camera Management
    
    /// Configures camera capture session
    /// - Parameter device: Camera device to use
    /// - Returns: True if successful, false otherwise
    static func configureCameraSession(device: AVCaptureDevice) -> Bool {
        let session = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("Cannot add camera input to session")
                return false
            }
        } catch {
            print("Error creating camera input: \(error.localizedDescription)")
            return false
        }
        
        captureSession = session
        return true
    }
    
    /// Starts camera capture session
    static func startCameraSession() {
        guard let session = captureSession else {
            print("No capture session available")
            return
        }
        
        if !session.isRunning {
            session.startRunning()
        }
    }
    
    /// Stops camera capture session
    static func stopCameraSession() {
        guard let session = captureSession else {
            return
        }
        
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    /// Configures preview session
    /// - Parameter device: Camera device for preview
    /// - Returns: True if successful, false otherwise
    static func configurePreviewSession(device: AVCaptureDevice) -> Bool {
        let session = AVCaptureSession()
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            if session.canAddInput(input) {
                session.addInput(input)
            } else {
                print("Cannot add preview input to session")
                return false
            }
        } catch {
            print("Error creating preview input: \(error.localizedDescription)")
            return false
        }
        
        previewSession = session
        return true
    }
    
    // MARK: - Cleanup
    
    /// Cleans up video resources
    static func cleanup() {
        assetWriter = nil
        videoInput = nil
        captureSession = nil
        previewSession = nil
        frameCache = nil
        firstFrame = nil
        lastPTS = nil
        timeOffset = CMTimeMake(value: 0, timescale: 0)
    }
    
    /// Resets time offset
    static func resetTimeOffset() {
        timeOffset = CMTimeMake(value: 0, timescale: 0)
    }
    
    /// Sets time offset for synchronization
    /// - Parameter offset: Time offset to set
    static func setTimeOffset(_ offset: CMTime) {
        timeOffset = offset
    }
}
