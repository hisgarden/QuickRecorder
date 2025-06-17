//
//  EndToEndIntegrationTests.swift
//  QuickRecorderTests
//
//  Created by TDD Architecture Phase 3 on 2025/06/16.
//

import XCTest
import ScreenCaptureKit
import AVFoundation
import Combine
@testable import QuickRecorder

/// End-to-end integration tests for complete application workflows
/// Phase 3 TDD: Testing complete user journeys and system integration
@MainActor
class EndToEndIntegrationTests: XCTestCase {
    
    var appCoordinator: AppCoordinator!
    var integrationTestManager: IntegrationTestManager!
    var mockDependencies: MockDependencyContainer!
    var cancellables: Set<AnyCancellable>!
    var tempTestDirectory: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Create temp directory for test outputs
        tempTestDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("EndToEndTests")
            .appendingPathComponent(UUID().uuidString)
        
        try FileManager.default.createDirectory(
            at: tempTestDirectory,
            withIntermediateDirectories: true
        )
        
        // Set up mock dependencies
        mockDependencies = MockDependencyContainer()
        
        // Initialize integration test components
        integrationTestManager = IntegrationTestManager(
            testDirectory: tempTestDirectory,
            dependencies: mockDependencies
        )
        
        appCoordinator = AppCoordinator(dependencies: mockDependencies)
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDown() async throws {
        // Clean up test files
        try? FileManager.default.removeItem(at: tempTestDirectory)
        
        cancellables?.removeAll()
        appCoordinator = nil
        integrationTestManager = nil
        mockDependencies = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Complete Recording Workflow Tests
    
    func testCompleteScreenRecordingWorkflow() async throws {
        // Test complete screen recording workflow from start to finish
        
        // 1. App initialization
        await appCoordinator.initialize()
        XCTAssertTrue(appCoordinator.isInitialized)
        
        // 2. Check permissions
        let hasPermissions = await appCoordinator.checkPermissions()
        if !hasPermissions {
            // Skip test if no permissions in CI environment
            try XCTSkipIf(true, "Screen recording permissions required")
        }
        
        // 3. Select recording type
        appCoordinator.selectRecordingType(.screen)
        XCTAssertEqual(appCoordinator.currentRecordingType, .screen)
        
        // 4. Configure recording settings
        let configuration = RecordingConfiguration(
            videoFormat: .mp4,
            audioQuality: .normal,
            frameRate: 30,
            resolution: CGSize(width: 1920, height: 1080),
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: tempTestDirectory,
            fileName: "end_to_end_test"
        )
        
        try await appCoordinator.configureRecording(configuration)
        XCTAssertNotNil(appCoordinator.currentConfiguration)
        
        // 5. Start recording
        try await appCoordinator.startRecording()
        XCTAssertTrue(appCoordinator.isRecording)
        
        // 6. Let recording run briefly
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // 7. Stop recording
        let outputURL = try await appCoordinator.stopRecording()
        XCTAssertFalse(appCoordinator.isRecording)
        XCTAssertNotNil(outputURL)
        
        // 8. Verify output file
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
        
        // 9. Clean up
        try? FileManager.default.removeItem(at: outputURL)
    }
    
    func testCompleteAreaRecordingWorkflow() async throws {
        // Test complete area recording workflow
        
        await appCoordinator.initialize()
        
        // Select area recording
        appCoordinator.selectRecordingType(.screenArea)
        
        // Define recording area
        let recordingArea = CGRect(x: 100, y: 100, width: 800, height: 600)
        appCoordinator.setRecordingArea(recordingArea)
        
        XCTAssertEqual(appCoordinator.selectedArea, recordingArea)
        
        // Configure and start recording
        let configuration = RecordingConfiguration(
            videoFormat: .mov,
            audioQuality: .good,
            frameRate: 60,
            resolution: recordingArea.size,
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: tempTestDirectory,
            fileName: "area_recording_test"
        )
        
        try await appCoordinator.configureRecording(configuration)
        try await appCoordinator.startRecording()
        
        // Brief recording
        try await Task.sleep(nanoseconds: 300_000_000) // 0.3 seconds
        
        let outputURL = try await appCoordinator.stopRecording()
        
        // Verify area recording
        XCTAssertNotNil(outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }
    
    func testCompleteWindowRecordingWorkflow() async throws {
        // Test complete window recording workflow
        
        await appCoordinator.initialize()
        
        // Get available windows
        let availableWindows = try await appCoordinator.getAvailableWindows()
        
        if availableWindows.isEmpty {
            try XCTSkipIf(true, "No windows available for testing")
        }
        
        // Select window recording
        appCoordinator.selectRecordingType(.window)
        
        // Select specific window
        let selectedWindow = availableWindows.first!
        appCoordinator.selectWindow(selectedWindow)
        
        XCTAssertEqual(appCoordinator.selectedWindow, selectedWindow)
        
        // Configure and record
        let configuration = RecordingConfiguration(
            videoFormat: .mp4,
            audioQuality: .normal,
            frameRate: 30,
            resolution: CGSize(width: 1280, height: 720),
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: tempTestDirectory,
            fileName: "window_recording_test"
        )
        
        try await appCoordinator.configureRecording(configuration)
        try await appCoordinator.startRecording()
        
        try await Task.sleep(nanoseconds: 400_000_000) // 0.4 seconds
        
        let outputURL = try await appCoordinator.stopRecording()
        
        XCTAssertNotNil(outputURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: outputURL.path))
    }
    
    // MARK: - Settings Integration Tests
    
    func testCompleteSettingsWorkflow() async throws {
        // Test complete settings management workflow
        
        await appCoordinator.initialize()
        
        // Get current settings
        let initialSettings = appCoordinator.getCurrentSettings()
        XCTAssertNotNil(initialSettings)
        
        // Modify settings
        var newSettings = initialSettings
        newSettings.videoFormat = .mp4
        newSettings.audioQuality = .high
        newSettings.frameRate = 60
        newSettings.includeSystemAudio = true
        newSettings.includeMicrophone = true
        
        // Apply settings
        appCoordinator.updateSettings(newSettings)
        
        // Verify settings were applied
        let updatedSettings = appCoordinator.getCurrentSettings()
        XCTAssertEqual(updatedSettings.videoFormat, .mp4)
        XCTAssertEqual(updatedSettings.audioQuality, .high)
        XCTAssertEqual(updatedSettings.frameRate, 60)
        XCTAssertTrue(updatedSettings.includeSystemAudio)
        XCTAssertTrue(updatedSettings.includeMicrophone)
        
        // Test settings persistence
        let newCoordinator = AppCoordinator(dependencies: mockDependencies)
        await newCoordinator.initialize()
        
        let persistedSettings = newCoordinator.getCurrentSettings()
        XCTAssertEqual(persistedSettings.videoFormat, .mp4)
        XCTAssertEqual(persistedSettings.frameRate, 60)
    }
    
    func testSettingsValidationWorkflow() throws {
        // Test settings validation workflow
        
        var settings = AppSettings.default
        
        // Test valid settings
        settings.frameRate = 30
        settings.videoQuality = 0.8
        XCTAssertTrue(appCoordinator.validateSettings(settings))
        
        // Test invalid frame rate
        settings.frameRate = -1
        XCTAssertFalse(appCoordinator.validateSettings(settings))
        
        // Test invalid video quality
        settings.frameRate = 30
        settings.videoQuality = 1.5
        XCTAssertFalse(appCoordinator.validateSettings(settings))
        
        // Test edge cases
        settings.videoQuality = 0.0
        XCTAssertTrue(appCoordinator.validateSettings(settings))
        
        settings.videoQuality = 1.0
        XCTAssertTrue(appCoordinator.validateSettings(settings))
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testErrorRecoveryWorkflow() async throws {
        // Test error handling and recovery workflow
        
        await appCoordinator.initialize()
        
        // Simulate permission error
        mockDependencies.recordingManager.shouldFailPermissions = true
        
        do {
            try await appCoordinator.startRecording()
            XCTFail("Should have thrown permission error")
        } catch {
            XCTAssertTrue(error is ErrorHandler.RecordingError)
            XCTAssertEqual(appCoordinator.lastError as? ErrorHandler.RecordingError, .permissionDenied)
        }
        
        // Recover from error
        mockDependencies.recordingManager.shouldFailPermissions = false
        appCoordinator.clearError()
        
        XCTAssertNil(appCoordinator.lastError)
        
        // Should be able to record after recovery
        try await appCoordinator.configureRecording(RecordingConfiguration(
            videoFormat: .mp4,
            audioQuality: .normal,
            frameRate: 30,
            resolution: CGSize(width: 1280, height: 720),
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: tempTestDirectory,
            fileName: "recovery_test"
        ))
        
        try await appCoordinator.startRecording()
        XCTAssertTrue(appCoordinator.isRecording)
        
        let outputURL = try await appCoordinator.stopRecording()
        XCTAssertNotNil(outputURL)
    }
    
    func testInterruptionHandlingWorkflow() async throws {
        // Test recording interruption handling
        
        await appCoordinator.initialize()
        
        let configuration = RecordingConfiguration(
            videoFormat: .mp4,
            audioQuality: .normal,
            frameRate: 30,
            resolution: CGSize(width: 1280, height: 720),
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: tempTestDirectory,
            fileName: "interruption_test"
        )
        
        try await appCoordinator.configureRecording(configuration)
        try await appCoordinator.startRecording()
        
        XCTAssertTrue(appCoordinator.isRecording)
        
        // Simulate interruption
        appCoordinator.handleRecordingInterruption()
        
        // Should handle interruption gracefully
        XCTAssertFalse(appCoordinator.isRecording)
        XCTAssertEqual(appCoordinator.recordingState, .idle)
        
        // Should be able to start new recording
        try await appCoordinator.startRecording()
        XCTAssertTrue(appCoordinator.isRecording)
        
        let outputURL = try await appCoordinator.stopRecording()
        XCTAssertNotNil(outputURL)
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceUnderLoad() async throws {
        // Test application performance under load
        
        await appCoordinator.initialize()
        
        let startTime = Date()
        var completedRecordings: [URL] = []
        
        // Perform multiple recording cycles
        for i in 0..<3 {
            let configuration = RecordingConfiguration(
                videoFormat: .mp4,
                audioQuality: .normal,
                frameRate: 30,
                resolution: CGSize(width: 1280, height: 720),
                includeAudio: false,
                includeMicrophone: false,
                outputDirectory: tempTestDirectory,
                fileName: "performance_test_\(i)"
            )
            
            try await appCoordinator.configureRecording(configuration)
            try await appCoordinator.startRecording()
            
            // Brief recording
            try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
            
            let outputURL = try await appCoordinator.stopRecording()
            completedRecordings.append(outputURL)
            
            // Brief pause between recordings
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        let totalTime = Date().timeIntervalSince(startTime)
        
        // Should complete all recordings within reasonable time
        XCTAssertLessThan(totalTime, 5.0, "Performance test took too long: \(totalTime)s")
        
        // All recordings should be created
        XCTAssertEqual(completedRecordings.count, 3)
        
        for url in completedRecordings {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        }
    }
    
    func testMemoryStabilityDuringExtendedUse() async throws {
        // Test memory stability during extended use
        
        await appCoordinator.initialize()
        
        let initialMemory = getCurrentMemoryUsage()
        
        // Perform extended recording cycles
        for i in 0..<10 {
            let configuration = RecordingConfiguration(
                videoFormat: .mp4,
                audioQuality: .normal,
                frameRate: 30,
                resolution: CGSize(width: 800, height: 600),
                includeAudio: false,
                includeMicrophone: false,
                outputDirectory: tempTestDirectory,
                fileName: "memory_test_\(i)"
            )
            
            try await appCoordinator.configureRecording(configuration)
            try await appCoordinator.startRecording()
            
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
            
            let outputURL = try await appCoordinator.stopRecording()
            
            // Clean up immediately to test memory management
            try? FileManager.default.removeItem(at: outputURL)
            
            // Force cleanup
            if i % 3 == 0 {
                autoreleasepool {
                    _ = Array(0..<1000).map { $0 }
                }
            }
        }
        
        let finalMemory = getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be minimal
        XCTAssertLessThan(memoryIncrease, 100 * 1024 * 1024, "Excessive memory growth: \(memoryIncrease) bytes")
    }
    
    // MARK: - Multi-Component Integration Tests
    
    func testUIAndRecordingIntegration() async throws {
        // Test UI and recording system integration
        
        await appCoordinator.initialize()
        
        // Create UI ViewModels
        let contentViewModel = ContentViewViewModel(
            appStateManager: mockDependencies.appStateManager,
            settingsManager: mockDependencies.settingsManager,
            recordingManager: mockDependencies.recordingManager
        )
        
        let screenSelectorViewModel = ScreenSelectorViewModel(
            appStateManager: mockDependencies.appStateManager,
            contentProvider: mockDependencies.contentProvider
        )
        
        // Test UI state synchronization
        await screenSelectorViewModel.loadAvailableScreens()
        let firstScreen = screenSelectorViewModel.availableScreens.first
        
        if let screen = firstScreen {
            screenSelectorViewModel.selectScreen(screen)
            
            // UI change should reflect in app coordinator
            XCTAssertEqual(appCoordinator.selectedScreen, screen)
        }
        
        // Test recording through UI
        contentViewModel.selectRecordingType(.screen)
        XCTAssertEqual(appCoordinator.currentRecordingType, .screen)
        
        // Start recording through UI
        await contentViewModel.startRecording()
        XCTAssertTrue(appCoordinator.isRecording)
        XCTAssertTrue(contentViewModel.isRecording)
        
        // Stop recording through UI
        await contentViewModel.stopRecording()
        XCTAssertFalse(appCoordinator.isRecording)
        XCTAssertFalse(contentViewModel.isRecording)
    }
    
    func testCrossComponentCommunication() async throws {
        // Test communication between different components
        
        await appCoordinator.initialize()
        
        var stateUpdates: [String] = []
        
        // Monitor state changes
        appCoordinator.statePublisher
            .sink { state in
                stateUpdates.append(state.description)
            }
            .store(in: &cancellables)
        
        // Trigger state changes through different components
        appCoordinator.selectRecordingType(.window)
        appCoordinator.selectRecordingType(.screenArea)
        
        let configuration = RecordingConfiguration(
            videoFormat: .mp4,
            audioQuality: .normal,
            frameRate: 30,
            resolution: CGSize(width: 1280, height: 720),
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: tempTestDirectory,
            fileName: "communication_test"
        )
        
        try await appCoordinator.configureRecording(configuration)
        try await appCoordinator.startRecording()
        
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let _ = try await appCoordinator.stopRecording()
        
        // Should have received multiple state updates
        XCTAssertGreaterThan(stateUpdates.count, 3)
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        return result == KERN_SUCCESS ? Int64(info.resident_size) : 0
    }
}

// MARK: - Integration Test Infrastructure

/// Application coordinator for managing complete workflows
@MainActor
class AppCoordinator: ObservableObject {
    @Published private(set) var isInitialized: Bool = false
    @Published private(set) var isRecording: Bool = false
    @Published private(set) var currentRecordingType: RecordingType = .screen
    @Published private(set) var recordingState: RecordingState = .idle
    @Published private(set) var selectedScreen: NSScreen?
    @Published private(set) var selectedWindow: SCWindow?
    @Published private(set) var selectedArea: CGRect = .zero
    @Published private(set) var lastError: Error?
    
    private(set) var currentConfiguration: RecordingConfiguration?
    
    let statePublisher = PassthroughSubject<AppState, Never>()
    
    private let dependencies: MockDependencyContainer
    
    init(dependencies: MockDependencyContainer) {
        self.dependencies = dependencies
    }
    
    func initialize() async {
        isInitialized = true
        statePublisher.send(AppState.initialized)
    }
    
    func checkPermissions() async -> Bool {
        return await dependencies.recordingManager.checkScreenCapturePermissions()
    }
    
    func selectRecordingType(_ type: RecordingType) {
        currentRecordingType = type
        dependencies.appStateManager.setRecordingType(type)
        statePublisher.send(AppState.recordingTypeChanged(type))
    }
    
    func setRecordingArea(_ area: CGRect) {
        selectedArea = area
    }
    
    func selectWindow(_ window: SCWindow) {
        selectedWindow = window
        dependencies.appStateManager.setSelectedWindow(window)
    }
    
    func getAvailableWindows() async throws -> [SCWindow] {
        let content = try await dependencies.contentProvider.getShareableContent()
        return content.windows
    }
    
    func configureRecording(_ configuration: RecordingConfiguration) async throws {
        currentConfiguration = configuration
        try await dependencies.recordingManager.prepareRecording(
            type: currentRecordingType,
            configuration: configuration
        )
    }
    
    func startRecording() async throws {
        try await dependencies.recordingManager.startRecording()
        isRecording = true
        recordingState = .recording(startTime: Date())
        statePublisher.send(AppState.recordingStarted)
    }
    
    func stopRecording() async throws -> URL {
        let outputURL = try await dependencies.recordingManager.stopRecording()
        isRecording = false
        recordingState = .idle
        statePublisher.send(AppState.recordingStopped)
        return outputURL
    }
    
    func handleRecordingInterruption() {
        dependencies.recordingManager.handleRecordingInterruption()
        isRecording = false
        recordingState = .idle
        statePublisher.send(AppState.recordingInterrupted)
    }
    
    func getCurrentSettings() -> AppSettings {
        return AppSettings(
            videoFormat: dependencies.settingsManager.getVideoFormat(),
            audioQuality: dependencies.settingsManager.getAudioQuality(),
            frameRate: dependencies.settingsManager.getFrameRate(),
            videoQuality: dependencies.settingsManager.getVideoQuality(),
            includeSystemAudio: dependencies.settingsManager.getIncludeSystemAudio(),
            includeMicrophone: dependencies.settingsManager.getIncludeMicrophone()
        )
    }
    
    func updateSettings(_ settings: AppSettings) {
        dependencies.settingsManager.setVideoFormat(settings.videoFormat)
        dependencies.settingsManager.setAudioQuality(settings.audioQuality)
        dependencies.settingsManager.setFrameRate(settings.frameRate)
        dependencies.settingsManager.setVideoQuality(settings.videoQuality)
        dependencies.settingsManager.setIncludeSystemAudio(settings.includeSystemAudio)
        dependencies.settingsManager.setIncludeMicrophone(settings.includeMicrophone)
    }
    
    func validateSettings(_ settings: AppSettings) -> Bool {
        return settings.frameRate > 0 && 
               settings.frameRate <= 120 &&
               settings.videoQuality >= 0.0 &&
               settings.videoQuality <= 1.0
    }
    
    func clearError() {
        lastError = nil
    }
}

/// Integration test manager
class IntegrationTestManager {
    let testDirectory: URL
    let dependencies: MockDependencyContainer
    
    init(testDirectory: URL, dependencies: MockDependencyContainer) {
        self.testDirectory = testDirectory
        self.dependencies = dependencies
    }
    
    func createTestConfiguration(fileName: String) -> RecordingConfiguration {
        return RecordingConfiguration(
            videoFormat: .mp4,
            audioQuality: .normal,
            frameRate: 30,
            resolution: CGSize(width: 1280, height: 720),
            includeAudio: false,
            includeMicrophone: false,
            outputDirectory: testDirectory,
            fileName: fileName
        )
    }
}

/// Mock dependency container
class MockDependencyContainer {
    let appStateManager: MockAppStateManager
    let settingsManager: MockSettingsManager
    let recordingManager: MockRecordingManager
    let contentProvider: MockContentProvider
    
    init() {
        self.appStateManager = MockAppStateManager()
        self.settingsManager = MockSettingsManager()
        self.recordingManager = MockRecordingManager()
        self.contentProvider = MockContentProvider()
    }
}

/// Application state representation
enum AppState: CustomStringConvertible {
    case initialized
    case recordingTypeChanged(RecordingType)
    case recordingStarted
    case recordingStopped
    case recordingInterrupted
    
    var description: String {
        switch self {
        case .initialized: return "initialized"
        case .recordingTypeChanged(let type): return "recordingTypeChanged(\(type))"
        case .recordingStarted: return "recordingStarted"
        case .recordingStopped: return "recordingStopped"
        case .recordingInterrupted: return "recordingInterrupted"
        }
    }
}

/// Application settings structure
struct AppSettings {
    var videoFormat: VideoFormat
    var audioQuality: AudioQuality
    var frameRate: Int
    var videoQuality: Double
    var includeSystemAudio: Bool
    var includeMicrophone: Bool
    
    static let `default` = AppSettings(
        videoFormat: .mov,
        audioQuality: .normal,
        frameRate: 30,
        videoQuality: 0.8,
        includeSystemAudio: false,
        includeMicrophone: false
    )
}

// MARK: - Mock Extensions for End-to-End Testing

extension MockRecordingManager {
    var shouldFailPermissions: Bool = false
    
    override func checkScreenCapturePermissions() async -> Bool {
        return !shouldFailPermissions
    }
    
    override func prepareRecording(type: RecordingType, configuration: RecordingConfiguration) async throws {
        if shouldFailPermissions {
            throw ErrorHandler.RecordingError.permissionDenied
        }
        try await super.prepareRecording(type: type, configuration: configuration)
    }
}

extension MockAppStateManager {
    func setSelectedWindow(_ window: SCWindow) {
        selectedWindow = window
    }
} 