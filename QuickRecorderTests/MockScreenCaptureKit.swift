//
//  MockScreenCaptureKit.swift
//  QuickRecorderTests
//
//  Mock types for ScreenCaptureKit testing
//  Created: 2025/12/27
//

import Foundation
import ScreenCaptureKit

/// Mock SCDisplay for testing
class MockSCDisplay: SCDisplay {
    private let _displayID: CGDirectDisplayID
    private let _frame: CGRect
    private let _contentRect: CGRect
    
    init(displayID: CGDirectDisplayID = 1, frame: CGRect = CGRect(x: 0, y: 0, width: 1920, height: 1080), contentRect: CGRect? = nil) {
        self._displayID = displayID
        self._frame = frame
        self._contentRect = contentRect ?? frame
        super.init(displayID: displayID, frame: frame, contentRectangle: contentRect ?? frame)
    }
    
    override var displayID: CGDirectDisplayID {
        return _displayID
    }
    
    override var frame: CGRect {
        return _frame
    }
    
    override var contentRectangle: CGRect {
        return _contentRect
    }
}

/// Mock SCWindow for testing
class MockSCWindow: SCWindow {
    private let _bundleIdentifier: String
    private let _windowID: CGWindowID
    private let _frame: CGRect
    
    init(bundleIdentifier: String, windowID: CGWindowID = 1, frame: CGRect = CGRect(x: 0, y: 0, width: 800, height: 600)) {
        self._bundleIdentifier = bundleIdentifier
        self._windowID = windowID
        self._frame = frame
        super.init(windowID: windowID, frame: frame, owningApplication: nil, contentRect: frame)
    }
    
    override var bundleIdentifier: String? {
        return _bundleIdentifier
    }
    
    override var windowID: CGWindowID {
        return _windowID
    }
    
    override var frame: CGRect {
        return _frame
    }
}

/// Mock SCRunningApplication for testing
class MockSCRunningApplication: SCRunningApplication {
    private let _bundleIdentifier: String
    private let _processID: pid_t
    
    init(bundleIdentifier: String, processID: pid_t = 1) {
        self._bundleIdentifier = bundleIdentifier
        self._processID = processID
        super.init(bundleIdentifier: bundleIdentifier, processID: processID)
    }
    
    override var bundleIdentifier: String {
        return _bundleIdentifier
    }
    
    override var processID: pid_t {
        return _processID
    }
}

/// Mock SCShareableContent for testing
class MockSCShareableContent: SCShareableContent {
    private let _displays: [SCDisplay]
    private let _windows: [SCWindow]
    private let _applications: [SCRunningApplication]
    
    init(displays: [SCDisplay], windows: [SCWindow], applications: [SCRunningApplication]) {
        self._displays = displays
        self._windows = windows
        self._applications = applications
        super.init(displays: displays, windows: windows, applications: applications)
    }
    
    override var displays: [SCDisplay] {
        return _displays
    }
    
    override var windows: [SCWindow] {
        return _windows
    }
    
    override var applications: [SCRunningApplication] {
        return _applications
    }
}

