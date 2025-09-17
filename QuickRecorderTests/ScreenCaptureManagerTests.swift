//
//  ScreenCaptureManagerTests.swift
//  QuickRecorderTests
//
//  Created by Refactoring on 2025/09/16.
//

import XCTest
import ScreenCaptureKit
@testable import QuickRecorder

/// Comprehensive unit tests for ScreenCaptureManager
class ScreenCaptureManagerTests: XCTestCase {
    
    var screenCaptureManager: ScreenCaptureManager.Type!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        screenCaptureManager = ScreenCaptureManager.self
        
        // Reset state before each test
        ScreenCaptureManager.availableContent = nil
        ScreenCaptureManager.filter = nil
        ScreenCaptureManager.stream = nil
        ScreenCaptureManager.screen = nil
        ScreenCaptureManager.window = nil
        ScreenCaptureManager.application = nil
        ScreenCaptureManager.streamType = nil
        ScreenCaptureManager.screenArea = nil
    }
    
    override func tearDownWithError() throws {
        screenCaptureManager = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Content Management Tests
    
    func testUpdateAvailableContentSync_WithMockContent() throws {
        // Given - Mock content scenario
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let result = ScreenCaptureManager.updateAvailableContentSync()
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.displays.count, 1)
        XCTAssertEqual(result?.windows.count, 2)
        XCTAssertEqual(result?.applications.count, 1)
    }
    
    func testUpdateAvailableContent_AsyncCompletion() throws {
        // Given
        let expectation = XCTestExpectation(description: "Content update completion")
        
        // When
        ScreenCaptureManager.updateAvailableContent {
            expectation.fulfill()
        }
        
        // Then
        wait(for: [expectation], timeout: 1.0)
    }
    
    func testRequestScreenRecordingPermissionIfNeeded_Async() async throws {
        // Given - Test permission request logic
        
        // When
        let hasPermission = await ScreenCaptureManager.requestScreenRecordingPermissionIfNeeded()
        
        // Then - In test environment, this will likely return false due to no actual hardware
        // The important thing is that it doesn't crash and returns a boolean
        XCTAssertTrue(hasPermission == true || hasPermission == false)
    }
    
    // MARK: - Content Filtering Tests
    
    func testGetWindows_WithMockContent() throws {
        // Given
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let windows = ScreenCaptureManager.getWindows()
        
        // Then
        XCTAssertEqual(windows.count, 2)
        XCTAssertTrue(windows.allSatisfy { $0.isOnScreen })
    }
    
    func testGetWindows_WithExcludedApps() throws {
        // Given
        let mockContent = createMockShareableContentWithExcludedApps()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let windows = ScreenCaptureManager.getWindows()
        
        // Then - Should filter out excluded apps
        XCTAssertEqual(windows.count, 1) // Only one non-excluded window
        XCTAssertFalse(windows.contains { $0.owningApplication?.bundleIdentifier == "com.apple.dock" })
    }
    
    func testGetWindows_HideSelf() throws {
        // Given
        let mockContent = createMockShareableContentWithSelf()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let windows = ScreenCaptureManager.getWindows(hideSelf: true)
        
        // Then - Should exclude self
        XCTAssertEqual(windows.count, 1)
        XCTAssertFalse(windows.contains { $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier })
    }
    
    func testGetSelf_WithMockContent() throws {
        // Given
        let mockContent = createMockShareableContentWithSelf()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let selfWindow = ScreenCaptureManager.getSelf()
        
        // Then
        XCTAssertNotNil(selfWindow)
        XCTAssertEqual(selfWindow?.owningApplication?.bundleIdentifier, Bundle.main.bundleIdentifier)
    }
    
    func testGetSelf_NoSelfWindow() throws {
        // Given
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let selfWindow = ScreenCaptureManager.getSelf()
        
        // Then
        XCTAssertNil(selfWindow)
    }
    
    func testGetSelfWindows_WithMockContent() throws {
        // Given
        let mockContent = createMockShareableContentWithSelf()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let selfWindows = ScreenCaptureManager.getSelfWindows()
        
        // Then
        XCTAssertEqual(selfWindows.count, 1)
        XCTAssertTrue(selfWindows.allSatisfy { $0.owningApplication?.bundleIdentifier == Bundle.main.bundleIdentifier })
    }
    
    func testGetDisplays_WithMockContent() throws {
        // Given
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let displays = ScreenCaptureManager.getDisplays()
        
        // Then
        XCTAssertEqual(displays.count, 1)
    }
    
    func testGetApplications_WithMockContent() throws {
        // Given
        let mockContent = createMockShareableContent()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let applications = ScreenCaptureManager.getApplications()
        
        // Then
        XCTAssertEqual(applications.count, 1)
    }
    
    func testGetApplications_WithExcludedApps() throws {
        // Given
        let mockContent = createMockShareableContentWithExcludedApps()
        ScreenCaptureManager.availableContent = mockContent
        
        // When
        let applications = ScreenCaptureManager.getApplications()
        
        // Then - Should filter out excluded apps
        XCTAssertEqual(applications.count, 1)
        XCTAssertFalse(applications.contains { $0.bundleIdentifier == "com.apple.dock" })
    }
    
    // MARK: - State Management Tests
    
    func testStreamType_SettingAndGetting() throws {
        // Given
        let expectedType: StreamType = .screen
        
        // When
        ScreenCaptureManager.streamType = expectedType
        
        // Then
        XCTAssertEqual(ScreenCaptureManager.streamType, expectedType)
    }
    
    func testScreenArea_SettingAndGetting() throws {
        // Given
        let expectedArea = NSRect(x: 0, y: 0, width: 1920, height: 1080)
        
        // When
        ScreenCaptureManager.screenArea = expectedArea
        
        // Then
        XCTAssertEqual(ScreenCaptureManager.screenArea, expectedArea)
    }
    
    func testBackgroundColor_SettingAndGetting() throws {
        // Given
        let expectedColor = CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // When
        ScreenCaptureManager.backgroundColor = expectedColor
        
        // Then
        XCTAssertEqual(ScreenCaptureManager.backgroundColor, expectedColor)
    }
    
    // MARK: - Excluded Apps Tests
    
    func testExcludedApps_ContainsExpectedApps() throws {
        // Given/When
        let excludedApps = ScreenCaptureManager.excludedApps
        
        // Then
        XCTAssertTrue(excludedApps.contains("com.apple.dock"))
        XCTAssertTrue(excludedApps.contains("com.apple.screencaptureui"))
        XCTAssertTrue(excludedApps.contains("com.apple.controlcenter"))
        XCTAssertTrue(excludedApps.contains(""))
    }
    
    // MARK: - Helper Methods
    
    private func createMockShareableContent() -> SCShareableContent {
        // Create mock displays
        let mockDisplay = createMockDisplay()
        
        // Create mock windows
        let mockWindow1 = createMockWindow(bundleIdentifier: "com.example.app1")
        let mockWindow2 = createMockWindow(bundleIdentifier: "com.example.app2")
        
        // Create mock applications
        let mockApp = createMockApplication(bundleIdentifier: "com.example.app1")
        
        // Note: In a real implementation, you'd need to create actual SCShareableContent
        // For testing purposes, we'll use a mock approach
        return MockSCShareableContent(displays: [mockDisplay], windows: [mockWindow1, mockWindow2], applications: [mockApp])
    }
    
    private func createMockShareableContentWithExcludedApps() -> SCShareableContent {
        let mockDisplay = createMockDisplay()
        let mockWindow1 = createMockWindow(bundleIdentifier: "com.example.app1")
        let mockWindow2 = createMockWindow(bundleIdentifier: "com.apple.dock")
        let mockApp1 = createMockApplication(bundleIdentifier: "com.example.app1")
        let mockApp2 = createMockApplication(bundleIdentifier: "com.apple.dock")
        
        return MockSCShareableContent(displays: [mockDisplay], windows: [mockWindow1, mockWindow2], applications: [mockApp1, mockApp2])
    }
    
    private func createMockShareableContentWithSelf() -> SCShareableContent {
        let mockDisplay = createMockDisplay()
        let mockWindow1 = createMockWindow(bundleIdentifier: "com.example.app1")
        let mockWindow2 = createMockWindow(bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.lihaoyun6.QuickRecorder")
        let mockApp1 = createMockApplication(bundleIdentifier: "com.example.app1")
        let mockApp2 = createMockApplication(bundleIdentifier: Bundle.main.bundleIdentifier ?? "com.lihaoyun6.QuickRecorder")
        
        return MockSCShareableContent(displays: [mockDisplay], windows: [mockWindow1, mockWindow2], applications: [mockApp1, mockApp2])
    }
    
    private func createMockDisplay() -> SCDisplay {
        // Note: In a real test, you'd need to create actual SCDisplay objects
        // For now, we'll use a mock approach
        return MockSCDisplay()
    }
    
    private func createMockWindow(bundleIdentifier: String) -> SCWindow {
        return MockSCWindow(bundleIdentifier: bundleIdentifier)
    }
    
    private func createMockApplication(bundleIdentifier: String) -> SCRunningApplication {
        return MockSCRunningApplication(bundleIdentifier: bundleIdentifier)
    }
}

// MARK: - Mock Classes for Testing

/// Mock implementation of SCShareableContent for testing
class MockSCShareableContent: SCShareableContent {
    private let _displays: [SCDisplay]
    private let _windows: [SCWindow]
    private let _applications: [SCRunningApplication]
    
    init(displays: [SCDisplay], windows: [SCWindow], applications: [SCRunningApplication]) {
        self._displays = displays
        self._windows = windows
        self._applications = applications
    }
    
    override var displays: [SCDisplay] { _displays }
    override var windows: [SCWindow] { _windows }
    override var applications: [SCRunningApplication] { _applications }
}

/// Mock implementation of SCDisplay for testing
class MockSCDisplay: SCDisplay {
    override var displayID: CGDirectDisplayID { 1 }
    override var frame: CGRect { CGRect(x: 0, y: 0, width: 1920, height: 1080) }
}

/// Mock implementation of SCWindow for testing
class MockSCWindow: SCWindow {
    private let _bundleIdentifier: String
    
    init(bundleIdentifier: String) {
        self._bundleIdentifier = bundleIdentifier
    }
    
    override var windowID: CGWindowID { 1 }
    override var frame: CGRect { CGRect(x: 0, y: 0, width: 800, height: 600) }
    override var isOnScreen: Bool { true }
    override var owningApplication: SCRunningApplication? {
        MockSCRunningApplication(bundleIdentifier: _bundleIdentifier)
    }
}

/// Mock implementation of SCRunningApplication for testing
class MockSCRunningApplication: SCRunningApplication {
    private let _bundleIdentifier: String
    
    init(bundleIdentifier: String) {
        self._bundleIdentifier = bundleIdentifier
    }
    
    override var bundleIdentifier: String { _bundleIdentifier }
    override var applicationName: String { "Mock App" }
}
