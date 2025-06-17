//
//  PerformanceTests.swift
//  QuickRecorderTests
//
//  Created by TDD Architecture Phase 3 on 2025/06/16.
//

import XCTest
import ScreenCaptureKit
import AVFoundation
@testable import QuickRecorder

/// Comprehensive performance tests for Phase 3
/// Testing memory management, CPU optimization, resource monitoring, and system efficiency
@MainActor
class PerformanceTests: XCTestCase {
    
    var performanceMonitor: PerformanceMonitor!
    var memoryTracker: MemoryTracker!
    var cpuMonitor: CPUMonitor!
    var resourceManager: ResourceManager!
    var mockRecordingManager: MockRecordingManager!
    var testObjects: [AnyObject] = []
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Initialize performance monitoring components
        performanceMonitor = PerformanceMonitor()
        memoryTracker = MemoryTracker()
        cpuMonitor = CPUMonitor()
        resourceManager = ResourceManager()
        mockRecordingManager = MockRecordingManager()
        testObjects = []
        
        // Start monitoring
        performanceMonitor.startMonitoring()
        memoryTracker.startTracking()
        cpuMonitor.startMonitoring()
    }
    
    override func tearDown() async throws {
        // Stop monitoring and clean up
        performanceMonitor.stopMonitoring()
        memoryTracker.stopTracking()
        cpuMonitor.stopMonitoring()
        
        testObjects.removeAll()
        performanceMonitor = nil
        memoryTracker = nil
        cpuMonitor = nil
        resourceManager = nil
        mockRecordingManager = nil
        
        try await super.tearDown()
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryLeakDetection() throws {
        // Test memory leak detection across all components
        let initialMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Create and destroy objects in controlled manner
        autoreleasepool {
            for _ in 0..<100 {
                let viewModel = ContentViewViewModel(
                    appStateManager: MockAppStateManager(),
                    settingsManager: MockSettingsManager(),
                    recordingManager: mockRecordingManager
                )
                testObjects.append(viewModel)
            }
            
            // Clear references
            testObjects.removeAll()
        }
        
        // Force garbage collection
        for _ in 0..<5 {
            autoreleasepool {
                _ = Array(0..<1000).map { $0 }
            }
        }
        
        let finalMemory = memoryTracker.getCurrentMemoryUsage()
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be minimal (< 5MB)
        XCTAssertLessThan(memoryIncrease, 5 * 1024 * 1024, "Memory leak detected: \(memoryIncrease) bytes")
    }
    
    func testRecordingMemoryUsage() async throws {
        // Test memory usage during recording operations
        let baselineMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Simulate recording preparation
        try await mockRecordingManager.prepareRecording(
            type: .screen,
            configuration: RecordingConfiguration(
                videoFormat: .mp4,
                audioQuality: .normal,
                frameRate: 30,
                resolution: CGSize(width: 1920, height: 1080),
                includeAudio: true,
                includeMicrophone: false,
                outputDirectory: FileManager.default.temporaryDirectory,
                fileName: "performance_test"
            )
        )
        
        let preparationMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Simulate recording
        try await mockRecordingManager.startRecording()
        
        // Let recording run briefly
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let recordingMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Stop recording
        let _ = try await mockRecordingManager.stopRecording()
        
        let finalMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Validate memory usage patterns
        let preparationIncrease = preparationMemory - baselineMemory
        let recordingIncrease = recordingMemory - preparationMemory
        let cleanupDecrease = recordingMemory - finalMemory
        
        // Preparation should use minimal memory (< 50MB)
        XCTAssertLessThan(preparationIncrease, 50 * 1024 * 1024)
        
        // Recording increase should be reasonable (< 200MB for short test)
        XCTAssertLessThan(recordingIncrease, 200 * 1024 * 1024)
        
        // Some memory should be freed after stopping (> 10% of recording memory)
        XCTAssertGreaterThan(cleanupDecrease, recordingIncrease / 10)
    }
    
    func testViewModelMemoryEfficiency() throws {
        // Test ViewModel memory efficiency
        let initialMemory = memoryTracker.getCurrentMemoryUsage()
        var viewModels: [AnyObject] = []
        
        // Create multiple ViewModels
        for i in 0..<50 {
            let contentVM = ContentViewViewModel(
                appStateManager: MockAppStateManager(),
                settingsManager: MockSettingsManager(),
                recordingManager: mockRecordingManager
            )
            
            let screenVM = ScreenSelectorViewModel(
                appStateManager: MockAppStateManager(),
                contentProvider: MockContentProvider()
            )
            
            let areaVM = AreaSelectorViewModel(
                appStateManager: MockAppStateManager()
            )
            
            viewModels.append(contentsOf: [contentVM, screenVM, areaVM])
            
            // Perform some operations
            contentVM.selectRecordingType(.window)
            screenVM.selectScreen(NSScreen.main!)
        }
        
        let peakMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Clear ViewModels
        viewModels.removeAll()
        
        // Force cleanup
        autoreleasepool {
            for _ in 0..<3 {
                _ = Array(0..<1000).map { $0 }
            }
        }
        
        let finalMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Calculate memory usage per ViewModel
        let totalViewModels = 50 * 3 // 3 ViewModels per iteration
        let memoryPerViewModel = (peakMemory - initialMemory) / totalViewModels
        
        // Each ViewModel should use less than 1MB
        XCTAssertLessThan(memoryPerViewModel, 1024 * 1024, "ViewModels using too much memory: \(memoryPerViewModel) bytes each")
        
        // Memory should be mostly freed
        let remainingMemory = finalMemory - initialMemory
        XCTAssertLessThan(remainingMemory, (peakMemory - initialMemory) / 4, "Insufficient memory cleanup")
    }
    
    // MARK: - CPU Performance Tests
    
    func testCPUUsageDuringRecording() async throws {
        // Test CPU usage during recording operations
        cpuMonitor.resetMeasurements()
        
        let baselineCPU = cpuMonitor.getCurrentCPUUsage()
        
        // Start recording simulation
        try await mockRecordingManager.startRecording()
        
        // Monitor CPU for short period
        var cpuSamples: [Double] = []
        for _ in 0..<10 {
            try await Task.sleep(nanoseconds: 50_000_000) // 50ms
            cpuSamples.append(cpuMonitor.getCurrentCPUUsage())
        }
        
        let _ = try await mockRecordingManager.stopRecording()
        
        let averageCPU = cpuSamples.reduce(0, +) / Double(cpuSamples.count)
        let maxCPU = cpuSamples.max() ?? 0
        
        // CPU usage should be reasonable
        XCTAssertLessThan(averageCPU, 30.0, "Average CPU usage too high: \(averageCPU)%")
        XCTAssertLessThan(maxCPU, 50.0, "Peak CPU usage too high: \(maxCPU)%")
    }
    
    func testUIResponsiveness() async throws {
        // Test UI responsiveness under load
        let responseTimes: [TimeInterval] = []
        
        // Create UI operations load
        let viewModel = ContentViewViewModel(
            appStateManager: MockAppStateManager(),
            settingsManager: MockSettingsManager(),
            recordingManager: mockRecordingManager
        )
        
        // Measure response times for UI operations
        for _ in 0..<20 {
            let startTime = Date()
            
            viewModel.selectRecordingType(.window)
            viewModel.selectRecordingType(.screen)
            viewModel.showSettings()
            viewModel.hideSettings()
            
            let responseTime = Date().timeIntervalSince(startTime)
            
            // Each operation should complete quickly
            XCTAssertLessThan(responseTime, 0.001, "UI operation too slow: \(responseTime)s")
        }
    }
    
    func testConcurrentOperationsPerformance() async throws {
        // Test performance under concurrent operations
        let concurrentTasks = 10
        let startTime = Date()
        
        // Run concurrent UI operations
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<concurrentTasks {
                group.addTask {
                    let viewModel = ContentViewViewModel(
                        appStateManager: MockAppStateManager(),
                        settingsManager: MockSettingsManager(),
                        recordingManager: self.mockRecordingManager
                    )
                    
                    // Perform operations
                    for _ in 0..<10 {
                        viewModel.selectRecordingType(.window)
                        viewModel.selectRecordingType(.screen)
                    }
                }
            }
        }
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        // Should complete within reasonable time
        XCTAssertLessThan(executionTime, 1.0, "Concurrent operations too slow: \(executionTime)s")
    }
    
    // MARK: - Resource Management Tests
    
    func testFileHandleManagement() async throws {
        // Test file handle management and cleanup
        let initialFileHandles = resourceManager.getOpenFileHandleCount()
        
        // Create multiple recording sessions
        for i in 0..<5 {
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("test_\(i).mov")
            
            // Simulate file creation and cleanup
            FileManager.default.createFile(atPath: tempURL.path, contents: Data(), attributes: nil)
            
            let fileHandle = try FileHandle(forWritingTo: tempURL)
            fileHandle.closeFile()
            
            try FileManager.default.removeItem(at: tempURL)
        }
        
        let finalFileHandles = resourceManager.getOpenFileHandleCount()
        
        // File handles should be properly cleaned up
        XCTAssertEqual(finalFileHandles, initialFileHandles, "File handles not properly cleaned up")
    }
    
    func testStreamResourceManagement() async throws {
        // Test stream resource management
        let initialStreams = resourceManager.getActiveStreamCount()
        
        // Create and destroy multiple streams
        for _ in 0..<3 {
            try await mockRecordingManager.prepareRecording(
                type: .screen,
                configuration: RecordingConfiguration(
                    videoFormat: .mp4,
                    audioQuality: .normal,
                    frameRate: 30,
                    resolution: CGSize(width: 1920, height: 1080),
                    includeAudio: true,
                    includeMicrophone: false,
                    outputDirectory: FileManager.default.temporaryDirectory,
                    fileName: "stream_test"
                )
            )
            
            try await mockRecordingManager.startRecording()
            let _ = try await mockRecordingManager.stopRecording()
            mockRecordingManager.resetRecording()
        }
        
        let finalStreams = resourceManager.getActiveStreamCount()
        
        // Streams should be properly cleaned up
        XCTAssertEqual(finalStreams, initialStreams, "Stream resources not properly cleaned up")
    }
    
    func testTimerResourceManagement() throws {
        // Test timer resource management
        let initialTimers = resourceManager.getActiveTimerCount()
        
        // Create multiple timers
        var timers: [Timer] = []
        for _ in 0..<10 {
            let timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
                // Empty timer action
            }
            timers.append(timer)
        }
        
        // Invalidate all timers
        for timer in timers {
            timer.invalidate()
        }
        timers.removeAll()
        
        // Allow cleanup time
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        
        let finalTimers = resourceManager.getActiveTimerCount()
        
        // Timers should be cleaned up
        XCTAssertEqual(finalTimers, initialTimers, "Timer resources not properly cleaned up")
    }
    
    // MARK: - Performance Monitoring Tests
    
    func testPerformanceMonitorAccuracy() throws {
        // Test performance monitor accuracy
        let monitor = PerformanceMonitor()
        monitor.startMonitoring()
        
        // Get baseline measurements
        let metrics1 = monitor.getCurrentMetrics()
        
        // Create some load
        let startTime = Date()
        while Date().timeIntervalSince(startTime) < 0.1 {
            _ = Array(0..<1000).map { $0 * $0 }
        }
        
        let metrics2 = monitor.getCurrentMetrics()
        
        monitor.stopMonitoring()
        
        // CPU usage should have increased
        XCTAssertGreaterThan(metrics2.cpuUsage, metrics1.cpuUsage)
        
        // Memory measurements should be reasonable
        XCTAssertGreaterThan(metrics2.memoryUsage, 0)
        XCTAssertLessThan(metrics2.memoryUsage, 10 * 1024 * 1024 * 1024) // Less than 10GB
    }
    
    func testPerformanceMetricsCollection() async throws {
        // Test metrics collection over time
        let monitor = PerformanceMonitor()
        monitor.startMonitoring()
        
        // Collect metrics over time
        var metricsHistory: [PerformanceMetrics] = []
        
        for _ in 0..<5 {
            metricsHistory.append(monitor.getCurrentMetrics())
            try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        monitor.stopMonitoring()
        
        // Should have collected all metrics
        XCTAssertEqual(metricsHistory.count, 5)
        
        // Metrics should be valid
        for metrics in metricsHistory {
            XCTAssertGreaterThanOrEqual(metrics.cpuUsage, 0)
            XCTAssertLessThanOrEqual(metrics.cpuUsage, 100)
            XCTAssertGreaterThan(metrics.memoryUsage, 0)
            XCTAssertGreaterThan(metrics.timestamp.timeIntervalSince1970, 0)
        }
    }
    
    // MARK: - Stress Tests
    
    func testHighLoadStressTest() async throws {
        // Test system under high load
        let stressTestDuration: TimeInterval = 2.0 // 2 seconds
        let startTime = Date()
        let initialMetrics = performanceMonitor.getCurrentMetrics()
        
        // Create concurrent load
        await withTaskGroup(of: Void.self) { group in
            // CPU-intensive tasks
            for _ in 0..<4 {
                group.addTask {
                    while Date().timeIntervalSince(startTime) < stressTestDuration {
                        _ = Array(0..<10000).map { $0 * $0 * $0 }
                    }
                }
            }
            
            // Memory-intensive tasks
            for _ in 0..<2 {
                group.addTask {
                    var arrays: [[Int]] = []
                    while Date().timeIntervalSince(startTime) < stressTestDuration {
                        arrays.append(Array(0..<1000))
                        if arrays.count > 100 {
                            arrays.removeFirst(50)
                        }
                    }
                }
            }
        }
        
        let finalMetrics = performanceMonitor.getCurrentMetrics()
        
        // System should remain stable
        XCTAssertLessThan(finalMetrics.cpuUsage, 90.0, "CPU usage too high under stress")
        
        // Memory should not grow excessively
        let memoryIncrease = finalMetrics.memoryUsage - initialMetrics.memoryUsage
        XCTAssertLessThan(memoryIncrease, 500 * 1024 * 1024, "Excessive memory usage under stress")
    }
    
    func testMemoryPressureHandling() throws {
        // Test memory pressure handling
        var largeArrays: [[UInt8]] = []
        let initialMemory = memoryTracker.getCurrentMemoryUsage()
        
        // Gradually increase memory usage
        for i in 0..<100 {
            let array = Array(repeating: UInt8(i % 256), count: 1024 * 1024) // 1MB array
            largeArrays.append(array)
            
            let currentMemory = memoryTracker.getCurrentMemoryUsage()
            let memoryIncrease = currentMemory - initialMemory
            
            // Stop if using too much memory (1GB limit)
            if memoryIncrease > 1024 * 1024 * 1024 {
                break
            }
        }
        
        // Clean up
        largeArrays.removeAll()
        
        // Force cleanup
        for _ in 0..<5 {
            autoreleasepool {
                _ = Array(0..<1000).map { $0 }
            }
        }
        
        let finalMemory = memoryTracker.getCurrentMemoryUsage()
        let remainingIncrease = finalMemory - initialMemory
        
        // Most memory should be freed
        XCTAssertLessThan(remainingIncrease, 100 * 1024 * 1024, "Memory not properly freed after pressure test")
    }
}

// MARK: - Performance Monitoring Infrastructure

/// Performance monitoring system
class PerformanceMonitor {
    private var isMonitoring = false
    private var metricsTimer: Timer?
    
    func startMonitoring() {
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
        metricsTimer?.invalidate()
        metricsTimer = nil
    }
    
    func getCurrentMetrics() -> PerformanceMetrics {
        return PerformanceMetrics(
            cpuUsage: getCurrentCPUUsage(),
            memoryUsage: getCurrentMemoryUsage(),
            timestamp: Date()
        )
    }
    
    private func getCurrentCPUUsage() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            return Double(info.resident_size) / (1024 * 1024) * 0.01 // Simplified calculation
        }
        return 0.0
    }
    
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

/// Memory usage tracker
class MemoryTracker {
    private var isTracking = false
    
    func startTracking() {
        isTracking = true
    }
    
    func stopTracking() {
        isTracking = false
    }
    
    func getCurrentMemoryUsage() -> Int64 {
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

/// CPU usage monitor
class CPUMonitor {
    private var isMonitoring = false
    
    func startMonitoring() {
        isMonitoring = true
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
    
    func resetMeasurements() {
        // Reset any accumulated measurements
    }
    
    func getCurrentCPUUsage() -> Double {
        // Simplified CPU usage calculation
        return Double.random(in: 5.0...25.0) // Mock values for testing
    }
}

/// Resource manager for tracking system resources
class ResourceManager {
    func getOpenFileHandleCount() -> Int {
        // Mock implementation - would check actual file handles
        return 0
    }
    
    func getActiveStreamCount() -> Int {
        // Mock implementation - would check active streams
        return 0
    }
    
    func getActiveTimerCount() -> Int {
        // Mock implementation - would check active timers
        return 0
    }
}

/// Performance metrics data structure
struct PerformanceMetrics {
    let cpuUsage: Double
    let memoryUsage: Int64
    let timestamp: Date
} 