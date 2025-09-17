//
//  ScreenCaptureManager.swift
//  QuickRecorder
//
//  Created by Refactoring on 2025/09/16.
//

import Foundation
import ScreenCaptureKit
import SwiftUI

/// Manages screen capture content, permissions, and filtering
/// 
/// This class handles all aspects of screen capture functionality including:
/// - Fetching available displays, windows, and applications
/// - Managing screen recording permissions
/// - Filtering content based on user preferences
/// - Providing safe access to ScreenCaptureKit APIs
/// 
/// The class uses static methods and properties to maintain global state
/// while providing a clean, organized interface for screen capture operations.
/// 
/// Key responsibilities:
/// - Content discovery and management
/// - Permission handling and validation
/// - Application filtering and exclusion
/// - Safe error handling for capture operations
/// 
/// Usage:
/// ```swift
/// // Get available windows
/// let windows = ScreenCaptureManager.getWindows()
/// 
/// // Check permissions
/// let hasPermission = await ScreenCaptureManager.requestScreenRecordingPermissionIfNeeded()
/// 
/// // Update content
/// ScreenCaptureManager.updateAvailableContent { 
///     // Content updated
/// }
/// ```
class ScreenCaptureManager {
    
    // MARK: - Properties
    
    /// Currently available shareable content (displays, windows, applications)
    static var availableContent: SCShareableContent?
    
    /// Current content filter for recording
    static var filter: SCContentFilter?
    
    /// Current stream for screen capture
    static var stream: SCStream?
    
    /// Current display being recorded
    static var screen: SCDisplay?
    
    /// Current windows being recorded
    static var window: [SCWindow]?
    
    /// Current applications being recorded
    static var application: [SCRunningApplication]?
    
    /// Current stream type
    static var streamType: StreamType?
    
    /// Screen area for area recording
    static var screenArea: NSRect?
    
    /// Background color for recording
    static var backgroundColor: CGColor = CGColor.black
    
    /// List of excluded applications from recording
    static let excludedApps = [
        "", "com.apple.dock", "com.apple.screencaptureui", 
        "com.apple.controlcenter", "com.apple.notificationcenterui", 
        "com.apple.systemuiserver", "com.apple.WindowManager", 
        "dev.mnpn.Azayaka", "com.gaosun.eul", "com.pointum.hazeover", 
        "net.matthewpalmer.Vanilla", "com.dwarvesv.minimalbar", 
        "com.bjango.istatmenus.status"
    ]
    
    // MARK: - Content Management
    
    /// Synchronously updates available content
    /// - Returns: Available shareable content or nil if failed
    static func updateAvailableContentSync() -> SCShareableContent? {
        let semaphore = DispatchSemaphore(value: 0)
        var result: SCShareableContent? = nil

        updateAvailableContent { content in
            result = content
            semaphore.signal()
        }

        semaphore.wait()
        return result
    }
    
    /// Updates available content asynchronously
    /// - Parameter completion: Completion handler called when content is updated
    private static func updateAvailableContent(completion: @escaping (SCShareableContent?) -> Void) {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
            if let error = error {
                switch error {
                case SCStreamError.userDeclined:
                    // Don't retry infinitely - this causes the permission dialog to keep appearing
                    // Instead, gracefully handle the permission decline and return nil
                    print("Screen recording permission declined by user")
                    completion(nil)
                default:
                    print("Error: failed to fetch available content: ".local, error.localizedDescription)
                    completion(nil)
                }
                return
            }

            availableContent = content
            if let displays = content?.displays, !displays.isEmpty {
                completion(content) // Return successfully fetched content
            } else {
                print("There needs to be at least one display connected!".local)
                completion(nil) // Return nil if no displays are connected
            }
        }
    }
    
    /// Updates available content with completion handler
    /// - Parameter completion: Completion handler called when content is updated
    static func updateAvailableContent(completion: @escaping () -> Void) {
        SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: false) { content, error in
            if let error = error {
                switch error {
                case SCStreamError.userDeclined: 
                    print("Screen recording permission declined by user")
                    // Don't call requestPermissions() directly - let the proper permission flow handle this
                    completion()
                    return
                default:
                    print("Error: failed to fetch available content: ".local, error.localizedDescription)
                    completion()
                    return
                }
            }

            availableContent = content
            completion()
        }
    }
    
    // MARK: - Permission Management
    
    /// Requests screen recording permission if needed
    /// - Returns: True if permission is granted, false otherwise
    static func requestScreenRecordingPermissionIfNeeded() async -> Bool {
        return await withCheckedContinuation { continuation in
            SCShareableContent.getExcludingDesktopWindows(false, onScreenWindowsOnly: true) { content, error in
                if let error = error {
                    switch error {
                    case SCStreamError.userDeclined:
                        print("Screen recording permission declined by user")
                        continuation.resume(returning: false)
                    default:
                        print("Error checking screen recording permission: \(error.localizedDescription)")
                        continuation.resume(returning: false)
                    }
                } else {
                    availableContent = content
                    continuation.resume(returning: true)
                }
            }
        }
    }
    
    // MARK: - Content Filtering
    
    /// Gets available windows for recording
    /// - Parameters:
    ///   - isOnScreen: Whether to include only on-screen windows
    ///   - hideSelf: Whether to hide the QuickRecorder app itself
    /// - Returns: Array of available windows
    static func getWindows(isOnScreen: Bool = true, hideSelf: Bool = true) -> [SCWindow] {
        guard let availableContent = availableContent else {
            print("Warning: availableContent is nil, attempting to update synchronously")
            if let content = updateAvailableContentSync() {
                availableContent = content
            } else {
                print("Error: Failed to get available content")
                return []
            }
        }
        
        var windows = availableContent.windows
        
        // Filter out excluded applications
        windows = windows.filter { window in
            guard let app = window.owningApplication else { return true }
            return !excludedApps.contains(app.bundleIdentifier)
        }
        
        // Filter on-screen windows if requested
        if isOnScreen {
            windows = windows.filter { window in
                window.isOnScreen
            }
        }
        
        // Hide self if requested
        if hideSelf {
            windows = windows.filter { window in
                window.owningApplication?.bundleIdentifier != Bundle.main.bundleIdentifier
            }
        }
        
        return windows
    }
    
    /// Gets the QuickRecorder app window
    /// - Returns: QuickRecorder window or nil if not found
    static func getSelf() -> SCWindow? {
        guard let availableContent = availableContent else {
            print("Warning: availableContent is nil")
            return nil
        }
        
        return availableContent.windows.first { window in
            window.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
        }
    }
    
    /// Gets all QuickRecorder app windows
    /// - Returns: Array of QuickRecorder windows
    static func getSelfWindows() -> [SCWindow] {
        guard let availableContent = availableContent else {
            print("Warning: availableContent is nil")
            return []
        }
        
        return availableContent.windows.filter { window in
            window.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier
        }
    }
    
    /// Gets available displays
    /// - Returns: Array of available displays
    static func getDisplays() -> [SCDisplay] {
        guard let availableContent = availableContent else {
            print("Warning: availableContent is nil")
            return []
        }
        
        return availableContent.displays
    }
    
    /// Gets available applications
    /// - Returns: Array of available applications
    static func getApplications() -> [SCRunningApplication] {
        guard let availableContent = availableContent else {
            print("Warning: availableContent is nil")
            return []
        }
        
        return availableContent.applications.filter { app in
            !excludedApps.contains(app.bundleIdentifier)
        }
    }
}
