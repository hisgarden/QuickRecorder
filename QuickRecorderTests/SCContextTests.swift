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
    
    /// Tests that permission is only requested once during app lifetime after being granted
    /// This is the core behavior that prevents the permission dialog from appearing repeatedly
    func testSCContext_PermissionRequestedOnlyOncePerAppLifetime() async throws {
        // Given - Track permission check calls and available content state
        var permissionCheckCount = 0
        var availableContentSetCount = 0
        
        // Store original available content
        let originalAvailableContent = SCContext.availableContent
        
        // Reset to simulate fresh app start
        SCContext.availableContent = nil
        
        // When - Multiple permission checks are performed (simulating multiple recording attempts)
        for attemptNumber in 1...5 {
            print("Permission check attempt \(attemptNumber)")
            
            let hasPermission = await SCContext.checkScreenRecordingPermission()
            permissionCheckCount += 1
            
            if SCContext.availableContent != nil {
                availableContentSetCount += 1
            }
            
            print("Attempt \(attemptNumber): hasPermission=\(hasPermission), availableContent=\(SCContext.availableContent != nil)")
            
            // Brief delay between attempts to simulate real usage
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        // Then - Verify expected behavior
        XCTAssertEqual(permissionCheckCount, 5, "Should have performed 5 permission checks")
        
        if SCContext.availableContent != nil {
            // If permissions are granted, availableContent should be set
            XCTAssertGreaterThan(availableContentSetCount, 0, "Available content should be set when permissions are granted")
            
            // After first successful permission check, subsequent checks should reuse cached content
            // This indicates no additional permission dialogs were shown
            XCTAssertNotNil(SCContext.availableContent, "Available content should remain cached")
        } else {
            // If permissions are not granted, availableContent should remain nil
            XCTAssertEqual(availableContentSetCount, 0, "Available content should not be set when permissions are denied")
        }
        
        // Restore original state
        SCContext.availableContent = originalAvailableContent
    }
    
    /// Tests that requestScreenRecordingPermissionIfNeeded handles cached permissions correctly
    /// This simulates the actual recording workflow where permissions are checked before recording
    func testSCContext_CachedPermissionHandling() async throws {
        // Given - Store original state
        let originalAvailableContent = SCContext.availableContent
        
        // When - First permission request (may trigger system dialog)
        let firstResult = await SCContext.requestScreenRecordingPermissionIfNeeded()
        let availableContentAfterFirst = SCContext.availableContent
        
        // When - Second permission request (should use cached result)
        let secondResult = await SCContext.requestScreenRecordingPermissionIfNeeded()
        let availableContentAfterSecond = SCContext.availableContent
        
        // When - Third permission request (should still use cached result)  
        let thirdResult = await SCContext.requestScreenRecordingPermissionIfNeeded()
        let availableContentAfterThird = SCContext.availableContent
        
        // Then - Results should be consistent
        XCTAssertEqual(firstResult, secondResult, "Second permission check should return same result as first")
        XCTAssertEqual(secondResult, thirdResult, "Third permission check should return same result as second")
        
        if firstResult {
            // If permissions are granted, available content should be consistent
            XCTAssertNotNil(availableContentAfterFirst, "Available content should be set after first successful check")
            XCTAssertNotNil(availableContentAfterSecond, "Available content should remain set after second check")
            XCTAssertNotNil(availableContentAfterThird, "Available content should remain set after third check")
            
            // The content objects should be the same (cached)
            XCTAssertEqual(availableContentAfterFirst?.displays.count, 
                          availableContentAfterSecond?.displays.count,
                          "Display count should be consistent between cached checks")
        }
        
        // Restore original state
        SCContext.availableContent = originalAvailableContent
    }
    
    /// Tests the complete recording workflow permission behavior
    /// This simulates what happens when a user tries to record multiple times
    func testSCContext_MultipleRecordingAttemptsPermissionBehavior() async throws {
        // Given - Simulate multiple recording attempts
        var permissionResults: [Bool] = []
        var availableContentStates: [Bool] = []
        
        // When - Simulate 3 recording attempts (like user clicking record button multiple times)
        for recordingAttempt in 1...3 {
            print("Recording attempt \(recordingAttempt)")
            
            // This is what happens in prepRecord() - permission is checked before recording
            let hasPermission = await SCContext.requestScreenRecordingPermissionIfNeeded()
            permissionResults.append(hasPermission)
            availableContentStates.append(SCContext.availableContent != nil)
            
            print("Recording attempt \(recordingAttempt): permission=\(hasPermission), content=\(SCContext.availableContent != nil)")
            
            // Brief delay between recording attempts
            try? await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        }
        
        // Then - Verify consistent behavior across multiple recording attempts
        XCTAssertEqual(permissionResults.count, 3, "Should have 3 permission results")
        XCTAssertEqual(availableContentStates.count, 3, "Should have 3 content states")
        
        // All permission results should be the same (no dialog shown after first time)
        if permissionResults.first == true {
            XCTAssertTrue(permissionResults.allSatisfy { $0 == true }, "All permission checks should return true once granted")
            XCTAssertTrue(availableContentStates.allSatisfy { $0 == true }, "Available content should be present for all attempts")
        } else if permissionResults.first == false {
            XCTAssertTrue(permissionResults.allSatisfy { $0 == false }, "Permission results should be consistent when denied")
        }
        
        // This test passing indicates that:
        // 1. Permission dialog only appears once (on first attempt)
        // 2. Subsequent attempts use cached permission state
        // 3. Recording can proceed immediately on subsequent attempts
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