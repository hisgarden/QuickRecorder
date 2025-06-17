//
//  AdvancedRecordingTests.swift
//  QuickRecorderTests
//
//  Created by TDD Architecture Phase 3 on 2025/06/16.
//

import XCTest
import ScreenCaptureKit
import AVFoundation
@testable import QuickRecorder

/// Advanced recording feature tests for Phase 3
/// Testing area selection, multi-window recording, camera overlay, and advanced configurations
@MainActor
class AdvancedRecordingTests: XCTestCase {
    
    var advancedRecordingManager: AdvancedRecordingManager!
    var areaSelector: AreaSelector!
    var cameraOverlay: CameraOverlay!
    var multiWindowRecorder: MultiWindowRecorder!
    var mockAppStateManager: MockAppStateManager!
    var mockSettingsManager: MockSettingsManager!
    var tempDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create temp directory for test outputs
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AdvancedRecordingTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(
            at: tempDirectory,
            withIntermediateDirectories: true
        )
        
        // Set up dependencies
        mockAppStateManager = MockAppStateManager()
        mockSettingsManager = MockSettingsManager()
        
        // Initialize advanced recording components
        advancedRecordingManager = AdvancedRecordingManager(
            appStateManager: mockAppStateManager,
            settingsManager: mockSettingsManager
        )
        
        areaSelector = AreaSelector()
        cameraOverlay = CameraOverlay()
        multiWindowRecorder = MultiWindowRecorder()
    }
    
    override func tearDown() async throws {
        // Clean up test files
        try? FileManager.default.removeItem(at: tempDirectory)
        
        advancedRecordingManager = nil
        areaSelector = nil
        cameraOverlay = nil
        multiWindowRecorder = nil
        mockAppStateManager = nil
        mockSettingsManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Area Selection Tests
    
    func testAreaSelectorInitialization() throws {
        // Test area selector initial state
        XCTAssertEqual(areaSelector.selectionState, .idle)
        XCTAssertEqual(areaSelector.selectedArea, .zero)
        XCTAssertFalse(areaSelector.isSelecting)
        XCTAssertNil(areaSelector.selectionDelegate)
    }
    
    func testAreaSelectionWorkflow() async throws {
        // Test complete area selection workflow
        
        // Start selection
        areaSelector.startAreaSelection()
        XCTAssertEqual(areaSelector.selectionState, .active)
        XCTAssertTrue(areaSelector.isSelecting)
        
        // Update selection area
        let testArea = CGRect(x: 100, y: 100, width: 500, height: 400)
        areaSelector.updateSelectionArea(testArea)
        XCTAssertEqual(areaSelector.selectedArea, testArea)
        
        // Finish selection
        areaSelector.finishAreaSelection()
        XCTAssertEqual(areaSelector.selectionState, .completed)
        XCTAssertFalse(areaSelector.isSelecting)
        XCTAssertEqual(areaSelector.selectedArea, testArea)
    }
    
    func testAreaSelectionValidation() throws {
        // Test area selection validation logic
        
        // Too small area
        let tooSmallArea = CGRect(x: 0, y: 0, width: 10, height: 10)
        XCTAssertFalse(areaSelector.isValidSelectionArea(tooSmallArea))
        
        // Valid area
        let validArea = CGRect(x: 0, y: 0, width: 200, height: 150)
        XCTAssertTrue(areaSelector.isValidSelectionArea(validArea))
        
        // Negative coordinates
        let negativeArea = CGRect(x: -50, y: -50, width: 200, height: 150)
        XCTAssertFalse(areaSelector.isValidSelectionArea(negativeArea))
    }
    
    func testAreaSelectionCoordinateTransformation() throws {
        // Test coordinate transformation for different screen configurations
        
        let mockScreen = NSScreen.main!
        let screenBounds = mockScreen.frame
        
        // Test relative to absolute coordinate conversion
        let relativeArea = CGRect(x: 0.1, y: 0.1, width: 0.5, height: 0.5)
        let absoluteArea = areaSelector.convertRelativeToAbsolute(relativeArea, screenBounds: screenBounds)
        
        let expectedArea = CGRect(
            x: screenBounds.width * 0.1,
            y: screenBounds.height * 0.1,
            width: screenBounds.width * 0.5,
            height: screenBounds.height * 0.5
        )
        
        XCTAssertEqual(absoluteArea, expectedArea)
    }
    
    func testAreaSelectionCancellation() throws {
        // Test area selection cancellation
        areaSelector.startAreaSelection()
        let testArea = CGRect(x: 100, y: 100, width: 500, height: 400)
        areaSelector.updateSelectionArea(testArea)
        
        areaSelector.cancelAreaSelection()
        
        XCTAssertEqual(areaSelector.selectionState, .cancelled)
        XCTAssertEqual(areaSelector.selectedArea, .zero)
        XCTAssertFalse(areaSelector.isSelecting)
    }
    
    // MARK: - Multi-Window Recording Tests
    
    func testMultiWindowRecorderInitialization() throws {
        // Test multi-window recorder initial state
        XCTAssertTrue(multiWindowRecorder.selectedWindows.isEmpty)
        XCTAssertFalse(multiWindowRecorder.isRecording)
        XCTAssertEqual(multiWindowRecorder.recordingMode, .individual)
    }
    
    func testMultiWindowSelection() async throws {
        // Test multi-window selection
        let mockWindows = await getMockWindows()
        
        // Select multiple windows
        multiWindowRecorder.selectWindow(mockWindows[0])
        multiWindowRecorder.selectWindow(mockWindows[1])
        
        XCTAssertEqual(multiWindowRecorder.selectedWindows.count, 2)
        XCTAssertTrue(multiWindowRecorder.selectedWindows.contains(mockWindows[0]))
        XCTAssertTrue(multiWindowRecorder.selectedWindows.contains(mockWindows[1]))
    }
    
    func testMultiWindowDeselection() async throws {
        // Test window deselection
        let mockWindows = await getMockWindows()
        
        multiWindowRecorder.selectWindow(mockWindows[0])
        multiWindowRecorder.selectWindow(mockWindows[1])
        
        multiWindowRecorder.deselectWindow(mockWindows[0])
        
        XCTAssertEqual(multiWindowRecorder.selectedWindows.count, 1)
        XCTAssertFalse(multiWindowRecorder.selectedWindows.contains(mockWindows[0]))
        XCTAssertTrue(multiWindowRecorder.selectedWindows.contains(mockWindows[1]))
    }
    
    func testMultiWindowRecordingModes() throws {
        // Test different multi-window recording modes
        
        // Individual mode
        multiWindowRecorder.setRecordingMode(.individual)
        XCTAssertEqual(multiWindowRecorder.recordingMode, .individual)
        
        // Combined mode
        multiWindowRecorder.setRecordingMode(.combined)
        XCTAssertEqual(multiWindowRecorder.recordingMode, .combined)
        
        // Composite mode
        multiWindowRecorder.setRecordingMode(.composite)
        XCTAssertEqual(multiWindowRecorder.recordingMode, .composite)
    }
    
    func testMultiWindowFilteringByApplication() async throws {
        // Test filtering windows by application
        let mockWindows = await getMockWindows()
        
        // Filter by specific application
        let filteredWindows = multiWindowRecorder.filterWindowsByApplication("Safari", from: mockWindows)
        
        // Should only return Safari windows
        for window in filteredWindows {
            XCTAssertEqual(window.owningApplication?.applicationName, "Safari")
        }
    }
    
    // MARK: - Camera Overlay Tests
    
    func testCameraOverlayInitialization() throws {
        // Test camera overlay initial state
        XCTAssertFalse(cameraOverlay.isActive)
        XCTAssertNil(cameraOverlay.cameraDevice)
        XCTAssertEqual(cameraOverlay.overlayPosition, .bottomRight)
        XCTAssertEqual(cameraOverlay.overlaySize, CameraOverlay.defaultSize)
    }
    
    func testCameraOverlayDeviceSelection() async throws {
        // Test camera device selection
        let availableDevices = await cameraOverlay.getAvailableCameraDevices()
        
        if !availableDevices.isEmpty {
            let firstDevice = availableDevices.first!
            try await cameraOverlay.selectCameraDevice(firstDevice)
            
            XCTAssertEqual(cameraOverlay.cameraDevice, firstDevice)
            XCTAssertTrue(cameraOverlay.isDeviceConnected)
        } else {
            // No camera devices available in test environment
            XCTAssertTrue(availableDevices.isEmpty)
        }
    }
    
    func testCameraOverlayPositioning() throws {
        // Test camera overlay positioning
        
        // Test all position options
        let positions: [CameraOverlay.Position] = [.topLeft, .topRight, .bottomLeft, .bottomRight, .center]
        
        for position in positions {
            cameraOverlay.setOverlayPosition(position)
            XCTAssertEqual(cameraOverlay.overlayPosition, position)
        }
    }
    
    func testCameraOverlaySizing() throws {
        // Test camera overlay sizing
        let customSize = CGSize(width: 200, height: 150)
        cameraOverlay.setOverlaySize(customSize)
        
        XCTAssertEqual(cameraOverlay.overlaySize, customSize)
        
        // Test size validation
        let tooSmallSize = CGSize(width: 10, height: 10)
        cameraOverlay.setOverlaySize(tooSmallSize)
        
        // Should use minimum size
        XCTAssertGreaterThanOrEqual(cameraOverlay.overlaySize.width, CameraOverlay.minimumSize.width)
        XCTAssertGreaterThanOrEqual(cameraOverlay.overlaySize.height, CameraOverlay.minimumSize.height)
    }
    
    func testCameraOverlayActivation() async throws {
        // Test camera overlay activation/deactivation
        
        // Activate overlay
        try await cameraOverlay.activate()
        XCTAssertTrue(cameraOverlay.isActive)
        
        // Deactivate overlay
        await cameraOverlay.deactivate()
        XCTAssertFalse(cameraOverlay.isActive)
    }
    
    // MARK: - Advanced Recording Manager Tests
    
    func testAdvancedRecordingManagerInitialization() throws {
        // Test advanced recording manager initialization
        XCTAssertNotNil(advancedRecordingManager.areaSelector)
        XCTAssertNotNil(advancedRecordingManager.cameraOverlay)
        XCTAssertNotNil(advancedRecordingManager.multiWindowRecorder)
        XCTAssertFalse(advancedRecordingManager.isRecording)
    }
    
    func testAdvancedAreaRecording() async throws {
        // Test area-based recording
        let testArea = CGRect(x: 100, y: 100, width: 800, height: 600)
        
        try await advancedRecordingManager.prepareAreaRecording(area: testArea)
        XCTAssertEqual(advancedRecordingManager.recordingType, .screenArea)
        XCTAssertEqual(advancedRecordingManager.selectedArea, testArea)
        
        // Start recording
        try await advancedRecordingManager.startRecording()
        XCTAssertTrue(advancedRecordingManager.isRecording)
        
        // Stop and get output
        let outputURL = try await advancedRecordingManager.stopRecording()
        XCTAssertFalse(advancedRecordingManager.isRecording)
        XCTAssertNotNil(outputURL)
    }
    
    func testAdvancedMultiWindowRecording() async throws {
        // Test multi-window recording
        let mockWindows = await getMockWindows()
        let selectedWindows = Array(mockWindows.prefix(2))
        
        try await advancedRecordingManager.prepareMultiWindowRecording(windows: selectedWindows)
        XCTAssertEqual(advancedRecordingManager.recordingType, .windows)
        XCTAssertEqual(advancedRecordingManager.selectedWindows.count, 2)
        
        // Test different composition modes
        advancedRecordingManager.setWindowCompositionMode(.grid)
        XCTAssertEqual(advancedRecordingManager.windowCompositionMode, .grid)
    }
    
    func testAdvancedRecordingWithCameraOverlay() async throws {
        // Test recording with camera overlay
        mockSettingsManager.enableCameraOverlay = true
        
        try await advancedRecordingManager.prepareCameraOverlayRecording()
        XCTAssertTrue(advancedRecordingManager.isCameraOverlayEnabled)
        
        // Configure overlay
        advancedRecordingManager.configureCameraOverlay(
            position: .bottomRight,
            size: CGSize(width: 200, height: 150)
        )
        
        XCTAssertEqual(advancedRecordingManager.cameraOverlayPosition, .bottomRight)
        XCTAssertEqual(advancedRecordingManager.cameraOverlaySize, CGSize(width: 200, height: 150))
    }
    
    func testAdvancedRecordingQualitySettings() throws {
        // Test advanced quality settings
        let qualityConfig = AdvancedQualityConfiguration(
            resolution: .fourK,
            frameRate: 60,
            bitrate: .variable(target: 10000),
            encoder: .h265
        )
        
        advancedRecordingManager.setQualityConfiguration(qualityConfig)
        XCTAssertEqual(advancedRecordingManager.qualityConfiguration.resolution, .fourK)
        XCTAssertEqual(advancedRecordingManager.qualityConfiguration.frameRate, 60)
    }
    
    // MARK: - Performance Tests
    
    func testAreaSelectionPerformance() throws {
        // Test area selection performance
        let startTime = Date()
        
        for _ in 0..<100 {
            let randomArea = CGRect(
                x: Double.random(in: 0...1000),
                y: Double.random(in: 0...1000),
                width: Double.random(in: 100...800),
                height: Double.random(in: 100...600)
            )
            areaSelector.updateSelectionArea(randomArea)
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 0.1) // Should complete in under 100ms
    }
    
    func testMultiWindowSelectionPerformance() async throws {
        // Test multi-window selection performance
        let mockWindows = await getMockWindows()
        let startTime = Date()
        
        // Select and deselect windows rapidly
        for window in mockWindows {
            multiWindowRecorder.selectWindow(window)
        }
        
        for window in mockWindows {
            multiWindowRecorder.deselectWindow(window)
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 0.1) // Should complete quickly
    }
    
    func testCameraOverlayRenderingPerformance() async throws {
        // Test camera overlay rendering performance
        try await cameraOverlay.activate()
        
        let startTime = Date()
        
        // Simulate rapid position/size changes
        for _ in 0..<50 {
            cameraOverlay.setOverlayPosition(.topLeft)
            cameraOverlay.setOverlayPosition(.bottomRight)
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        XCTAssertLessThan(executionTime, 0.2) // Should handle rapid changes
        
        await cameraOverlay.deactivate()
    }
    
    // MARK: - Helper Methods
    
    private func getMockWindows() async -> [SCWindow] {
        // Get mock windows for testing
        do {
            let content = try await SCShareableContent.current
            return Array(content.windows.prefix(5)) // Return first 5 windows
        } catch {
            // Return empty array if unable to get real windows
            return []
        }
    }
}

// MARK: - Advanced Recording Components (to be implemented in GREEN phase)

/// Advanced recording manager with extended capabilities
class AdvancedRecordingManager {
    let areaSelector: AreaSelector
    let cameraOverlay: CameraOverlay
    let multiWindowRecorder: MultiWindowRecorder
    
    private(set) var isRecording: Bool = false
    private(set) var recordingType: RecordingType = .screen
    private(set) var selectedArea: CGRect = .zero
    private(set) var selectedWindows: [SCWindow] = []
    private(set) var isCameraOverlayEnabled: Bool = false
    private(set) var cameraOverlayPosition: CameraOverlay.Position = .bottomRight
    private(set) var cameraOverlaySize: CGSize = CameraOverlay.defaultSize
    private(set) var windowCompositionMode: WindowCompositionMode = .individual
    private(set) var qualityConfiguration: AdvancedQualityConfiguration = .default
    
    private let appStateManager: AppStateManaging
    private let settingsManager: SettingsManaging
    
    init(appStateManager: AppStateManaging, settingsManager: SettingsManaging) {
        self.appStateManager = appStateManager
        self.settingsManager = settingsManager
        self.areaSelector = AreaSelector()
        self.cameraOverlay = CameraOverlay()
        self.multiWindowRecorder = MultiWindowRecorder()
    }
    
    func prepareAreaRecording(area: CGRect) async throws {
        recordingType = .screenArea
        selectedArea = area
    }
    
    func prepareMultiWindowRecording(windows: [SCWindow]) async throws {
        recordingType = .windows
        selectedWindows = windows
    }
    
    func prepareCameraOverlayRecording() async throws {
        isCameraOverlayEnabled = settingsManager.getBoolValue(for: "enableCameraOverlay") ?? false
    }
    
    func startRecording() async throws {
        isRecording = true
    }
    
    func stopRecording() async throws -> URL {
        isRecording = false
        return URL(fileURLWithPath: "/tmp/advanced_recording.mov")
    }
    
    func setWindowCompositionMode(_ mode: WindowCompositionMode) {
        windowCompositionMode = mode
    }
    
    func configureCameraOverlay(position: CameraOverlay.Position, size: CGSize) {
        cameraOverlayPosition = position
        cameraOverlaySize = size
    }
    
    func setQualityConfiguration(_ config: AdvancedQualityConfiguration) {
        qualityConfiguration = config
    }
}

/// Area selector for screen region selection
class AreaSelector {
    enum SelectionState {
        case idle
        case active
        case completed
        case cancelled
    }
    
    private(set) var selectionState: SelectionState = .idle
    private(set) var selectedArea: CGRect = .zero
    private(set) var isSelecting: Bool = false
    
    weak var selectionDelegate: AreaSelectionDelegate?
    
    func startAreaSelection() {
        selectionState = .active
        isSelecting = true
        selectedArea = .zero
    }
    
    func updateSelectionArea(_ area: CGRect) {
        selectedArea = area
    }
    
    func finishAreaSelection() {
        selectionState = .completed
        isSelecting = false
    }
    
    func cancelAreaSelection() {
        selectionState = .cancelled
        isSelecting = false
        selectedArea = .zero
    }
    
    func isValidSelectionArea(_ area: CGRect) -> Bool {
        return area.width >= 50 && area.height >= 50 && area.minX >= 0 && area.minY >= 0
    }
    
    func convertRelativeToAbsolute(_ relativeArea: CGRect, screenBounds: CGRect) -> CGRect {
        return CGRect(
            x: screenBounds.width * relativeArea.minX,
            y: screenBounds.height * relativeArea.minY,
            width: screenBounds.width * relativeArea.width,
            height: screenBounds.height * relativeArea.height
        )
    }
}

/// Camera overlay for recording with camera feed
class CameraOverlay {
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight, center
    }
    
    static let defaultSize = CGSize(width: 150, height: 100)
    static let minimumSize = CGSize(width: 50, height: 50)
    
    private(set) var isActive: Bool = false
    private(set) var cameraDevice: AVCaptureDevice?
    private(set) var overlayPosition: Position = .bottomRight
    private(set) var overlaySize: CGSize = defaultSize
    private(set) var isDeviceConnected: Bool = false
    
    func getAvailableCameraDevices() async -> [AVCaptureDevice] {
        return AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
    }
    
    func selectCameraDevice(_ device: AVCaptureDevice) async throws {
        cameraDevice = device
        isDeviceConnected = true
    }
    
    func setOverlayPosition(_ position: Position) {
        overlayPosition = position
    }
    
    func setOverlaySize(_ size: CGSize) {
        overlaySize = CGSize(
            width: max(size.width, Self.minimumSize.width),
            height: max(size.height, Self.minimumSize.height)
        )
    }
    
    func activate() async throws {
        isActive = true
    }
    
    func deactivate() async {
        isActive = false
    }
}

/// Multi-window recorder for recording multiple windows
class MultiWindowRecorder {
    private(set) var selectedWindows: [SCWindow] = []
    private(set) var isRecording: Bool = false
    private(set) var recordingMode: WindowRecordingMode = .individual
    
    func selectWindow(_ window: SCWindow) {
        if !selectedWindows.contains(window) {
            selectedWindows.append(window)
        }
    }
    
    func deselectWindow(_ window: SCWindow) {
        selectedWindows.removeAll { $0 == window }
    }
    
    func setRecordingMode(_ mode: WindowRecordingMode) {
        recordingMode = mode
    }
    
    func filterWindowsByApplication(_ applicationName: String, from windows: [SCWindow]) -> [SCWindow] {
        return windows.filter { window in
            window.owningApplication?.applicationName == applicationName
        }
    }
}

// MARK: - Supporting Types

enum WindowRecordingMode {
    case individual
    case combined
    case composite
}

enum WindowCompositionMode {
    case individual
    case grid
    case overlay
}

struct AdvancedQualityConfiguration {
    enum Resolution {
        case fullHD
        case fourK
        case eightK
        case custom(CGSize)
    }
    
    enum Bitrate {
        case constant(Int)
        case variable(target: Int)
    }
    
    enum Encoder {
        case h264
        case h265
        case av1
    }
    
    let resolution: Resolution
    let frameRate: Int
    let bitrate: Bitrate
    let encoder: Encoder
    
    static let `default` = AdvancedQualityConfiguration(
        resolution: .fullHD,
        frameRate: 30,
        bitrate: .variable(target: 5000),
        encoder: .h264
    )
}

protocol AreaSelectionDelegate: AnyObject {
    func areaSelectionDidStart()
    func areaSelectionDidUpdate(_ area: CGRect)
    func areaSelectionDidComplete(_ area: CGRect)
    func areaSelectionDidCancel()
}

// MARK: - Mock Extensions

extension MockSettingsManager {
    var enableCameraOverlay: Bool {
        get { return getBoolValue(for: "enableCameraOverlay") ?? false }
        set { setBoolValue(newValue, for: "enableCameraOverlay") }
    }
    
    func getBoolValue(for key: String) -> Bool? {
        // Mock implementation
        return false
    }
    
    func setBoolValue(_ value: Bool, for key: String) {
        // Mock implementation
    }
} 