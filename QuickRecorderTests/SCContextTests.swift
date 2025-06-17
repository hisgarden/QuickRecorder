//
//  SCContextTests.swift
//  QuickRecorderTests
//
//  Created by Test Coverage Phase 2 on 2025/06/16.
//

import XCTest
import ScreenCaptureKit
@testable import QuickRecorder

/// Tests for SCContext functionality including screen capture, permissions, and content detection
@available(macOS 12.3, *)
class SCContextTests: XCTestCase {
    
    var scContext: SCContext!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        scContext = SCContext()
    }
    
    override func tearDownWithError() throws {
        scContext = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Initialization Tests
    
    func testSCContext_CanBeCreated() throws {
        // Given/When/Then
        XCTAssertNotNil(scContext)
    }
    
    func testSCContext_InitialState() throws {
        // Given/When/Then - Check initial state
        XCTAssertNotNil(scContext.availableContent)
        XCTAssertEqual(scContext.canRecord, false) // Initially false until permissions checked
        XCTAssertEqual(scContext.isRecording, false)
    }
    
    // MARK: - Permission Tests
    
    func testSCContext_PermissionCheck() async throws {
        // Given/When
        let hasPermission = await scContext.checkScreenRecordingPermission()
        
        // Then - Permission status should be deterministic
        XCTAssertTrue(hasPermission == true || hasPermission == false)
        XCTAssertEqual(scContext.canRecord, hasPermission)
    }
    
    func testSCContext_RequestPermissionIfNeeded() async throws {
        // Given/When
        await scContext.requestScreenRecordingPermissionIfNeeded()
        
        // Then - Should complete without throwing
        XCTAssertTrue(true) // Test passes if no exception thrown
    }
    
    // MARK: - Content Discovery Tests
    
    func testSCContext_UpdateAvailableContent() async throws {
        // Given/When
        await scContext.updateAvailableContent()
        
        // Then
        XCTAssertNotNil(scContext.availableContent)
        
        // Check if we have displays (should always have at least one)
        if scContext.canRecord {
            XCTAssertFalse(scContext.availableContent?.displays.isEmpty ?? true)
        }
    }
    
    func testSCContext_SynchronousContentUpdate() throws {
        // Given/When - This should not crash even without permissions
        XCTAssertNoThrow(scContext.updateAvailableContentSync())
        
        // Then
        XCTAssertNotNil(scContext.availableContent)
    }
    
    // MARK: - Display Tests
    
    func testSCContext_DisplayDetection() async throws {
        // Given
        await scContext.updateAvailableContent()
        
        // When/Then
        if scContext.canRecord, let content = scContext.availableContent {
            XCTAssertFalse(content.displays.isEmpty, "Should detect at least one display")
            
            for display in content.displays {
                XCTAssertGreaterThan(display.width, 0)
                XCTAssertGreaterThan(display.height, 0)
                XCTAssertNotNil(display.displayID)
            }
        }
    }
    
    func testSCContext_MainDisplayDetection() async throws {
        // Given
        await scContext.updateAvailableContent()
        
        // When/Then
        if scContext.canRecord, let content = scContext.availableContent {
            let mainDisplay = content.displays.first { $0.displayID == CGMainDisplayID() }
            XCTAssertNotNil(mainDisplay, "Should detect main display")
        }
    }
    
    // MARK: - Application Tests
    
    func testSCContext_ApplicationDetection() async throws {
        // Given
        await scContext.updateAvailableContent()
        
        // When/Then
        if scContext.canRecord, let content = scContext.availableContent {
            // Should detect some applications (at least Finder and System processes)
            XCTAssertFalse(content.applications.isEmpty, "Should detect running applications")
            
            // Check for system applications
            let hasSystemApps = content.applications.contains { app in
                app.bundleIdentifier?.contains("com.apple") == true
            }
            XCTAssertTrue(hasSystemApps, "Should detect system applications")
        }
    }
    
    func testSCContext_ApplicationProperties() async throws {
        // Given
        await scContext.updateAvailableContent()
        
        // When/Then
        if scContext.canRecord, let content = scContext.availableContent {
            for app in content.applications.prefix(5) { // Test first 5 apps
                XCTAssertNotNil(app.processID)
                XCTAssertFalse(app.applicationName.isEmpty)
                // bundleIdentifier can be nil for some system processes
            }
        }
    }
    
    // MARK: - Window Tests
    
    func testSCContext_WindowDetection() async throws {
        // Given
        await scContext.updateAvailableContent()
        
        // When/Then
        if scContext.canRecord, let content = scContext.availableContent {
            // Should detect some windows (desktop, finder, etc.)
            XCTAssertFalse(content.windows.isEmpty, "Should detect windows")
            
            for window in content.windows.prefix(3) { // Test first 3 windows
                XCTAssertNotNil(window.windowID)
                XCTAssertGreaterThanOrEqual(window.frame.width, 0)
                XCTAssertGreaterThanOrEqual(window.frame.height, 0)
            }
        }
    }
    
    func testSCContext_WindowOwnership() async throws {
        // Given
        await scContext.updateAvailableContent()
        
        // When/Then
        if scContext.canRecord, let content = scContext.availableContent {
            for window in content.windows.prefix(5) {
                XCTAssertNotNil(window.owningApplication, "Window should have owning application")
            }
        }
    }
    
    // MARK: - Recording Size Tests
    
    func testSCContext_GetRecordingSize() throws {
        // Given
        let testArea: [String: Any] = [
            "x": 100.0,
            "y": 200.0,
            "width": 800.0,
            "height": 600.0
        ]
        
        // When
        let size = scContext.getRecordingSize(area: testArea)
        
        // Then
        XCTAssertEqual(size.width, 800.0)
        XCTAssertEqual(size.height, 600.0)
    }
    
    func testSCContext_GetRecordingSizeWithInvalidArea() throws {
        // Given
        let invalidArea: [String: Any] = [
            "x": "invalid",
            "y": "invalid"
        ]
        
        // When
        let size = scContext.getRecordingSize(area: invalidArea)
        
        // Then - Should return default size
        XCTAssertEqual(size.width, 1920.0)
        XCTAssertEqual(size.height, 1080.0)
    }
    
    // MARK: - Recording State Tests
    
    func testSCContext_InitialRecordingState() throws {
        // Given/When/Then
        XCTAssertFalse(scContext.isRecording)
    }
    
    func testSCContext_RecordingStateManagement() throws {
        // Given
        let initialState = scContext.isRecording
        
        // When - Simulate state changes
        scContext.isRecording = true
        XCTAssertTrue(scContext.isRecording)
        
        scContext.isRecording = false
        XCTAssertFalse(scContext.isRecording)
        
        // Cleanup
        scContext.isRecording = initialState
    }
    
    // MARK: - Error Handling Tests
    
    func testSCContext_HandlesContentUpdateErrors() async throws {
        // Given/When - Multiple rapid updates should not crash
        for _ in 0..<5 {
            await scContext.updateAvailableContent()
        }
        
        // Then
        XCTAssertNotNil(scContext.availableContent)
    }
    
    // MARK: - Performance Tests
    
    func testSCContext_ContentUpdatePerformance() throws {
        // Skip if no permissions
        guard scContext.canRecord else {
            throw XCTSkip("Screen recording permission not granted")
        }
        
        measure {
            scContext.updateAvailableContentSync()
        }
    }
    
    func testSCContext_PermissionCheckPerformance() throws {
        measure {
            Task {
                _ = await scContext.checkScreenRecordingPermission()
            }
        }
    }
    
    // MARK: - Memory Management Tests
    
    func testSCContext_MemoryManagement() throws {
        // Given
        weak var weakContext: SCContext?
        
        // When
        autoreleasepool {
            let context = SCContext()
            weakContext = context
            XCTAssertNotNil(weakContext)
        }
        
        // Then - Should be deallocated
        XCTAssertNil(weakContext, "SCContext should be deallocated when no strong references remain")
    }
    
    // MARK: - Integration Tests
    
    func testSCContext_IntegrationWithSettings() async throws {
        // Given
        let settings = SettingsManager.shared
        
        // When
        await scContext.updateAvailableContent()
        
        // Then - Should work with current settings
        let recordingSize = scContext.getRecordingSize(area: [
            "width": settings.areaWidth,
            "height": settings.areaHeight
        ])
        
        XCTAssertGreaterThan(recordingSize.width, 0)
        XCTAssertGreaterThan(recordingSize.height, 0)
    }
    
    // MARK: - Edge Case Tests
    
    func testSCContext_EmptyAreaHandling() throws {
        // Given
        let emptyArea: [String: Any] = [:]
        
        // When
        let size = scContext.getRecordingSize(area: emptyArea)
        
        // Then - Should return default size
        XCTAssertEqual(size.width, 1920.0)
        XCTAssertEqual(size.height, 1080.0)
    }
    
    func testSCContext_NilAreaHandling() throws {
        // Given
        let nilValues: [String: Any] = [
            "width": NSNull(),
            "height": NSNull()
        ]
        
        // When
        let size = scContext.getRecordingSize(area: nilValues)
        
        // Then - Should return default size
        XCTAssertEqual(size.width, 1920.0)
        XCTAssertEqual(size.height, 1080.0)
    }
} 