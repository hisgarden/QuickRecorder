//
//  UIComponentTests.swift
//  QuickRecorderTests
//
//  Created by TDD Architecture Phase 3 on 2025/06/16.
//

import XCTest
import SwiftUI
import Combine
@testable import QuickRecorder

/// Comprehensive UI component tests for SwiftUI Views and ViewModels
/// Phase 3 TDD: Testing UI components, state management, and user interactions
@MainActor
class UIComponentTests: XCTestCase {
    
    var contentViewModel: ContentViewViewModel!
    var screenSelectorViewModel: ScreenSelectorViewModel!
    var areaSelectorViewModel: AreaSelectorViewModel!
    var settingsViewModel: SettingsViewViewModel!
    var mockAppStateManager: MockAppStateManager!
    var mockSettingsManager: MockSettingsManager!
    var mockRecordingManager: MockRecordingManager!
    var cancellables: Set<AnyCancellable>!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up mock dependencies
        mockAppStateManager = MockAppStateManager()
        mockSettingsManager = MockSettingsManager()
        mockRecordingManager = MockRecordingManager()
        cancellables = Set<AnyCancellable>()
        
        // Initialize ViewModels with dependency injection
        contentViewModel = ContentViewViewModel(
            appStateManager: mockAppStateManager,
            settingsManager: mockSettingsManager,
            recordingManager: mockRecordingManager
        )
        
        screenSelectorViewModel = ScreenSelectorViewModel(
            appStateManager: mockAppStateManager,
            contentProvider: MockContentProvider()
        )
        
        areaSelectorViewModel = AreaSelectorViewModel(
            appStateManager: mockAppStateManager
        )
        
        settingsViewModel = SettingsViewViewModel(
            settingsManager: mockSettingsManager
        )
    }
    
    override func tearDown() async throws {
        cancellables?.removeAll()
        contentViewModel = nil
        screenSelectorViewModel = nil
        areaSelectorViewModel = nil
        settingsViewModel = nil
        mockAppStateManager = nil
        mockSettingsManager = nil
        mockRecordingManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - ContentView ViewModel Tests
    
    func testContentViewInitialState() throws {
        // Test initial state of ContentView ViewModel
        XCTAssertFalse(contentViewModel.isRecording)
        XCTAssertEqual(contentViewModel.recordingType, .screen)
        XCTAssertNil(contentViewModel.selectedScreen)
        XCTAssertNil(contentViewModel.selectedWindow)
        XCTAssertFalse(contentViewModel.showingSettings)
        XCTAssertFalse(contentViewModel.showingError)
        XCTAssertNil(contentViewModel.errorMessage)
    }
    
    func testContentViewRecordingStateManagement() async throws {
        // Test recording state management through ViewModel
        
        // Start recording
        await contentViewModel.startRecording()
        
        XCTAssertTrue(contentViewModel.isRecording)
        XCTAssertTrue(mockRecordingManager.startRecordingCalled)
        XCTAssertTrue(mockAppStateManager.isRecording)
        
        // Stop recording
        await contentViewModel.stopRecording()
        
        XCTAssertFalse(contentViewModel.isRecording)
        XCTAssertTrue(mockRecordingManager.stopRecordingCalled)
        XCTAssertFalse(mockAppStateManager.isRecording)
    }
    
    func testContentViewRecordingTypeSelection() throws {
        // Test recording type selection
        contentViewModel.selectRecordingType(.window)
        
        XCTAssertEqual(contentViewModel.recordingType, .window)
        XCTAssertEqual(mockAppStateManager.currentRecordingType, .window)
        
        contentViewModel.selectRecordingType(.screenArea)
        
        XCTAssertEqual(contentViewModel.recordingType, .screenArea)
        XCTAssertEqual(mockAppStateManager.currentRecordingType, .screenArea)
    }
    
    func testContentViewErrorHandling() async throws {
        // Test error handling in ContentView ViewModel
        mockRecordingManager.shouldFailStart = true
        
        await contentViewModel.startRecording()
        
        XCTAssertTrue(contentViewModel.showingError)
        XCTAssertNotNil(contentViewModel.errorMessage)
        XCTAssertFalse(contentViewModel.isRecording)
        
        // Clear error
        contentViewModel.clearError()
        
        XCTAssertFalse(contentViewModel.showingError)
        XCTAssertNil(contentViewModel.errorMessage)
    }
    
    func testContentViewSettingsPresentation() throws {
        // Test settings view presentation
        XCTAssertFalse(contentViewModel.showingSettings)
        
        contentViewModel.showSettings()
        XCTAssertTrue(contentViewModel.showingSettings)
        
        contentViewModel.hideSettings()
        XCTAssertFalse(contentViewModel.showingSettings)
    }
    
    // MARK: - ScreenSelector ViewModel Tests
    
    func testScreenSelectorInitialState() throws {
        // Test initial state of ScreenSelector ViewModel
        XCTAssertTrue(screenSelectorViewModel.availableScreens.isEmpty)
        XCTAssertNil(screenSelectorViewModel.selectedScreen)
        XCTAssertFalse(screenSelectorViewModel.isLoading)
    }
    
    func testScreenSelectorScreenLoading() async throws {
        // Test screen loading functionality
        await screenSelectorViewModel.loadAvailableScreens()
        
        XCTAssertFalse(screenSelectorViewModel.isLoading)
        XCTAssertFalse(screenSelectorViewModel.availableScreens.isEmpty)
        XCTAssertNotNil(screenSelectorViewModel.selectedScreen)
    }
    
    func testScreenSelectorScreenSelection() async throws {
        // Test screen selection
        await screenSelectorViewModel.loadAvailableScreens()
        
        let firstScreen = screenSelectorViewModel.availableScreens.first!
        screenSelectorViewModel.selectScreen(firstScreen)
        
        XCTAssertEqual(screenSelectorViewModel.selectedScreen, firstScreen)
        XCTAssertEqual(mockAppStateManager.selectedScreen, firstScreen)
    }
    
    func testScreenSelectorRefresh() async throws {
        // Test screen list refresh functionality
        await screenSelectorViewModel.loadAvailableScreens()
        let initialCount = screenSelectorViewModel.availableScreens.count
        
        await screenSelectorViewModel.refreshScreens()
        
        // Should reload screens (in mock, same count expected)
        XCTAssertEqual(screenSelectorViewModel.availableScreens.count, initialCount)
    }
    
    // MARK: - AreaSelector ViewModel Tests
    
    func testAreaSelectorInitialState() throws {
        // Test initial state of AreaSelector ViewModel
        XCTAssertEqual(areaSelectorViewModel.selectionArea, .zero)
        XCTAssertFalse(areaSelectorViewModel.isSelecting)
        XCTAssertFalse(areaSelectorViewModel.hasValidSelection)
    }
    
    func testAreaSelectorAreaSelection() throws {
        // Test area selection functionality
        let testArea = CGRect(x: 100, y: 100, width: 500, height: 300)
        
        areaSelectorViewModel.startAreaSelection()
        XCTAssertTrue(areaSelectorViewModel.isSelecting)
        
        areaSelectorViewModel.updateSelectionArea(testArea)
        XCTAssertEqual(areaSelectorViewModel.selectionArea, testArea)
        
        areaSelectorViewModel.finishAreaSelection()
        XCTAssertFalse(areaSelectorViewModel.isSelecting)
        XCTAssertTrue(areaSelectorViewModel.hasValidSelection)
    }
    
    func testAreaSelectorAreaValidation() throws {
        // Test area validation logic
        
        // Invalid area (too small)
        let tooSmallArea = CGRect(x: 0, y: 0, width: 10, height: 10)
        areaSelectorViewModel.updateSelectionArea(tooSmallArea)
        XCTAssertFalse(areaSelectorViewModel.hasValidSelection)
        
        // Valid area
        let validArea = CGRect(x: 0, y: 0, width: 200, height: 150)
        areaSelectorViewModel.updateSelectionArea(validArea)
        XCTAssertTrue(areaSelectorViewModel.hasValidSelection)
    }
    
    func testAreaSelectorReset() throws {
        // Test area selection reset
        let testArea = CGRect(x: 100, y: 100, width: 500, height: 300)
        areaSelectorViewModel.updateSelectionArea(testArea)
        
        areaSelectorViewModel.resetSelection()
        
        XCTAssertEqual(areaSelectorViewModel.selectionArea, .zero)
        XCTAssertFalse(areaSelectorViewModel.hasValidSelection)
        XCTAssertFalse(areaSelectorViewModel.isSelecting)
    }
    
    // MARK: - Settings ViewModel Tests
    
    func testSettingsViewModelInitialState() throws {
        // Test initial state of Settings ViewModel
        XCTAssertEqual(settingsViewModel.videoFormat, mockSettingsManager.videoFormat)
        XCTAssertEqual(settingsViewModel.audioQuality, mockSettingsManager.audioQuality)
        XCTAssertEqual(settingsViewModel.frameRate, mockSettingsManager.frameRate)
        XCTAssertFalse(settingsViewModel.hasUnsavedChanges)
    }
    
    func testSettingsViewModelValueUpdates() throws {
        // Test settings value updates
        settingsViewModel.updateVideoFormat(.mp4)
        XCTAssertEqual(settingsViewModel.videoFormat, .mp4)
        XCTAssertTrue(settingsViewModel.hasUnsavedChanges)
        
        settingsViewModel.updateAudioQuality(.high)
        XCTAssertEqual(settingsViewModel.audioQuality, .high)
        XCTAssertTrue(settingsViewModel.hasUnsavedChanges)
        
        settingsViewModel.updateFrameRate(60)
        XCTAssertEqual(settingsViewModel.frameRate, 60)
        XCTAssertTrue(settingsViewModel.hasUnsavedChanges)
    }
    
    func testSettingsViewModelSaveAndLoad() throws {
        // Test settings save and load functionality
        settingsViewModel.updateVideoFormat(.mp4)
        settingsViewModel.updateFrameRate(60)
        
        settingsViewModel.saveSettings()
        
        XCTAssertFalse(settingsViewModel.hasUnsavedChanges)
        XCTAssertEqual(mockSettingsManager.videoFormat, .mp4)
        XCTAssertEqual(mockSettingsManager.frameRate, 60)
        
        // Test load settings
        mockSettingsManager.videoFormat = .mov
        settingsViewModel.loadSettings()
        
        XCTAssertEqual(settingsViewModel.videoFormat, .mov)
    }
    
    func testSettingsViewModelValidation() throws {
        // Test settings validation
        
        // Invalid frame rate
        settingsViewModel.updateFrameRate(-1)
        XCTAssertFalse(settingsViewModel.isValidConfiguration)
        
        // Valid frame rate
        settingsViewModel.updateFrameRate(30)
        XCTAssertTrue(settingsViewModel.isValidConfiguration)
    }
    
    func testSettingsViewModelResetToDefaults() throws {
        // Test reset to defaults functionality
        settingsViewModel.updateVideoFormat(.mp4)
        settingsViewModel.updateFrameRate(60)
        
        settingsViewModel.resetToDefaults()
        
        XCTAssertEqual(settingsViewModel.videoFormat, .mov) // Default
        XCTAssertEqual(settingsViewModel.frameRate, 30) // Default
        XCTAssertTrue(settingsViewModel.hasUnsavedChanges)
    }
    
    // MARK: - UI State Management Integration Tests
    
    func testViewModelStateBinding() async throws {
        // Test that ViewModels properly bind to app state
        var stateUpdateReceived = false
        
        mockAppStateManager.$isRecording
            .sink { isRecording in
                stateUpdateReceived = true
            }
            .store(in: &cancellables)
        
        await contentViewModel.startRecording()
        
        // Allow for async update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        XCTAssertTrue(stateUpdateReceived)
        XCTAssertTrue(contentViewModel.isRecording)
    }
    
    func testCrossTalkBetweenViewModels() throws {
        // Test that changes in one ViewModel affect others appropriately
        let testScreen = NSScreen.main!
        
        screenSelectorViewModel.selectScreen(testScreen)
        
        // ContentViewModel should reflect the change
        XCTAssertEqual(contentViewModel.selectedScreen, testScreen)
        XCTAssertEqual(mockAppStateManager.selectedScreen, testScreen)
    }
    
    func testViewModelErrorPropagation() async throws {
        // Test that errors propagate correctly between ViewModels
        mockRecordingManager.shouldFailStart = true
        
        await contentViewModel.startRecording()
        
        XCTAssertTrue(contentViewModel.showingError)
        XCTAssertNotNil(contentViewModel.errorMessage)
        
        // Other ViewModels should be aware of error state
        XCTAssertFalse(screenSelectorViewModel.canSelectScreen)
        XCTAssertFalse(areaSelectorViewModel.canStartSelection)
    }
    
    // MARK: - Performance Tests
    
    func testViewModelMemoryUsage() throws {
        // Test that ViewModels don't cause memory leaks
        weak var weakContentViewModel: ContentViewViewModel?
        weak var weakScreenSelectorViewModel: ScreenSelectorViewModel?
        
        autoreleasepool {
            let tempContentViewModel = ContentViewViewModel(
                appStateManager: mockAppStateManager,
                settingsManager: mockSettingsManager,
                recordingManager: mockRecordingManager
            )
            
            let tempScreenSelectorViewModel = ScreenSelectorViewModel(
                appStateManager: mockAppStateManager,
                contentProvider: MockContentProvider()
            )
            
            weakContentViewModel = tempContentViewModel
            weakScreenSelectorViewModel = tempScreenSelectorViewModel
        }
        
        // ViewModels should be deallocated
        XCTAssertNil(weakContentViewModel)
        XCTAssertNil(weakScreenSelectorViewModel)
    }
    
    func testViewModelResponseTime() async throws {
        // Test that ViewModel operations complete within reasonable time
        let startTime = Date()
        
        await screenSelectorViewModel.loadAvailableScreens()
        
        let endTime = Date()
        let executionTime = endTime.timeIntervalSince(startTime)
        
        // Should complete within 100ms
        XCTAssertLessThan(executionTime, 0.1)
    }
}

// MARK: - ViewModel Implementations (to be created in GREEN phase)

/// ContentView ViewModel managing main application state
@MainActor
class ContentViewViewModel: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var recordingType: RecordingType = .screen
    @Published var selectedScreen: NSScreen?
    @Published var selectedWindow: SCWindow?
    @Published var showingSettings: Bool = false
    @Published var showingError: Bool = false
    @Published var errorMessage: String?
    
    private let appStateManager: AppStateManaging
    private let settingsManager: SettingsManaging
    private let recordingManager: RecordingManaging
    private var cancellables = Set<AnyCancellable>()
    
    init(appStateManager: AppStateManaging, settingsManager: SettingsManaging, recordingManager: RecordingManaging) {
        self.appStateManager = appStateManager
        self.settingsManager = settingsManager
        self.recordingManager = recordingManager
        
        // Bind to app state
        bindToAppState()
    }
    
    func startRecording() async {
        // Implementation to be added in GREEN phase
        do {
            try await recordingManager.startRecording()
            isRecording = true
            appStateManager.updateRecordingState(true)
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func stopRecording() async {
        // Implementation to be added in GREEN phase
        do {
            let _ = try await recordingManager.stopRecording()
            isRecording = false
            appStateManager.updateRecordingState(false)
        } catch {
            showError(error.localizedDescription)
        }
    }
    
    func selectRecordingType(_ type: RecordingType) {
        recordingType = type
        appStateManager.setRecordingType(type)
    }
    
    func showSettings() { showingSettings = true }
    func hideSettings() { showingSettings = false }
    
    func showError(_ message: String) {
        errorMessage = message
        showingError = true
    }
    
    func clearError() {
        errorMessage = nil
        showingError = false
    }
    
    private func bindToAppState() {
        // Bind to app state changes
        // Implementation to be added in GREEN phase
    }
}

/// ScreenSelector ViewModel managing display selection
@MainActor
class ScreenSelectorViewModel: ObservableObject {
    @Published var availableScreens: [NSScreen] = []
    @Published var selectedScreen: NSScreen?
    @Published var isLoading: Bool = false
    @Published var canSelectScreen: Bool = true
    
    private let appStateManager: AppStateManaging
    private let contentProvider: ContentProviding
    
    init(appStateManager: AppStateManaging, contentProvider: ContentProviding) {
        self.appStateManager = appStateManager
        self.contentProvider = contentProvider
    }
    
    func loadAvailableScreens() async {
        // Implementation to be added in GREEN phase
        isLoading = true
        availableScreens = contentProvider.getAvailableDisplays()
        selectedScreen = availableScreens.first
        isLoading = false
    }
    
    func selectScreen(_ screen: NSScreen) {
        selectedScreen = screen
        appStateManager.setSelectedDisplay(screen)
    }
    
    func refreshScreens() async {
        await loadAvailableScreens()
    }
}

/// AreaSelector ViewModel managing screen area selection
@MainActor
class AreaSelectorViewModel: ObservableObject {
    @Published var selectionArea: CGRect = .zero
    @Published var isSelecting: Bool = false
    @Published var hasValidSelection: Bool = false
    @Published var canStartSelection: Bool = true
    
    private let appStateManager: AppStateManaging
    private let minimumAreaSize: CGSize = CGSize(width: 50, height: 50)
    
    init(appStateManager: AppStateManaging) {
        self.appStateManager = appStateManager
    }
    
    func startAreaSelection() {
        isSelecting = true
        selectionArea = .zero
        hasValidSelection = false
    }
    
    func updateSelectionArea(_ area: CGRect) {
        selectionArea = area
        hasValidSelection = isValidArea(area)
    }
    
    func finishAreaSelection() {
        isSelecting = false
    }
    
    func resetSelection() {
        selectionArea = .zero
        isSelecting = false
        hasValidSelection = false
    }
    
    private func isValidArea(_ area: CGRect) -> Bool {
        return area.width >= minimumAreaSize.width && area.height >= minimumAreaSize.height
    }
}

/// Settings ViewModel managing application settings
@MainActor
class SettingsViewViewModel: ObservableObject {
    @Published var videoFormat: VideoFormat = .mov
    @Published var audioQuality: AudioQuality = .normal
    @Published var frameRate: Int = 30
    @Published var hasUnsavedChanges: Bool = false
    @Published var isValidConfiguration: Bool = true
    
    private let settingsManager: SettingsManaging
    
    init(settingsManager: SettingsManaging) {
        self.settingsManager = settingsManager
        loadSettings()
    }
    
    func updateVideoFormat(_ format: VideoFormat) {
        videoFormat = format
        hasUnsavedChanges = true
        validateConfiguration()
    }
    
    func updateAudioQuality(_ quality: AudioQuality) {
        audioQuality = quality
        hasUnsavedChanges = true
        validateConfiguration()
    }
    
    func updateFrameRate(_ rate: Int) {
        frameRate = rate
        hasUnsavedChanges = true
        validateConfiguration()
    }
    
    func saveSettings() {
        // Implementation to be added in GREEN phase
        settingsManager.setVideoFormat(videoFormat)
        settingsManager.setAudioQuality(audioQuality)
        settingsManager.setFrameRate(frameRate)
        hasUnsavedChanges = false
    }
    
    func loadSettings() {
        videoFormat = settingsManager.getVideoFormat()
        audioQuality = settingsManager.getAudioQuality()
        frameRate = settingsManager.getFrameRate()
        hasUnsavedChanges = false
        validateConfiguration()
    }
    
    func resetToDefaults() {
        videoFormat = .mov
        audioQuality = .normal
        frameRate = 30
        hasUnsavedChanges = true
        validateConfiguration()
    }
    
    private func validateConfiguration() {
        isValidConfiguration = frameRate > 0 && frameRate <= 120
    }
}

// MARK: - Mock Classes for UI Testing

class MockRecordingManager: RecordingManaging {
    var isRecording: Bool = false
    var recordingState: RecordingState = .idle
    var recordingDuration: TimeInterval = 0
    
    var startRecordingCalled = false
    var stopRecordingCalled = false
    var shouldFailStart = false
    
    func prepareRecording(type: RecordingType, configuration: RecordingConfiguration) async throws {
        // Mock implementation
    }
    
    func startRecording() async throws {
        startRecordingCalled = true
        if shouldFailStart {
            throw ErrorHandler.RecordingError.permissionDenied
        }
        isRecording = true
        recordingState = .recording(startTime: Date())
    }
    
    func stopRecording() async throws -> URL {
        stopRecordingCalled = true
        isRecording = false
        recordingState = .idle
        return URL(fileURLWithPath: "/tmp/test.mov")
    }
    
    func pauseRecording() async {}
    func resumeRecording() async {}
    func resetRecording() {}
    func handleRecordingInterruption() {}
    
    func checkScreenCapturePermissions() async -> Bool { return true }
    func getShareableContent() async throws -> SCShareableContent {
        return try await SCShareableContent.current
    }
}

class MockContentProvider: ContentProviding {
    func getAvailableDisplays() -> [NSScreen] {
        return NSScreen.screens
    }
    
    func getShareableContent() async throws -> SCShareableContent {
        return try await SCShareableContent.current
    }
    
    func getWindows() -> [SCWindow] { return [] }
    func getWindows(for application: SCRunningApplication) -> [SCWindow] { return [] }
    func getApplications() -> [SCRunningApplication] { return [] }
    
    func createStreamConfiguration(for type: RecordingType) -> SCStreamConfiguration {
        return SCStreamConfiguration()
    }
} 