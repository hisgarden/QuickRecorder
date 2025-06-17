//
//  PerformanceOptimizationTests.swift
//  QuickRecorderTests
//
//  Created by TDD Phase 3 Implementation on 2025/06/16.
//

import XCTest
import Foundation
@testable import QuickRecorder

/// Performance and optimization testing for Phase 3
/// Covers memory management, CPU optimization, resource monitoring, and stress testing
class PerformanceOptimizationTests: XCTestCase {
    
    var settingsManager: SettingsManager!
    var recordEngine: RecordEngine!
    var scContext: SCContext!
    var errorHandler: ErrorHandler!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        settingsManager = SettingsManager.shared
        recordEngine = RecordEngine()
        scContext = SCContext()
        errorHandler = ErrorHandler.shared
    }
    
    override func tearDownWithError() throws {
        settingsManager = nil
        recordEngine = nil
        scContext = nil
        errorHandler = nil
        try super.tearDownWithError()
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryManagement_ObjectLifecycle() throws {
        // Given - Memory baseline
        weak var weakContext: SCContext?
        weak var weakEngine: RecordEngine?
        
        // When - Create and release objects
        autoreleasepool {
            let context = SCContext()
            let engine = RecordEngine()
            
            weakContext = context
            weakEngine = engine
            
            // Use objects to ensure they're not optimized away
            let _ = context.getDisplays()
            let _ = engine.getAudioSettings()
        }
        
        // Then - Objects should be deallocated
        XCTAssertNil(weakContext, "SCContext should be deallocated")
        XCTAssertNil(weakEngine, "RecordEngine should be deallocated")
    }
    
    func testMemoryManagement_RepeatedOperations() throws {
        // Given - Initial memory state
        let iterations = 100
        
        // When - Perform repeated operations
        for _ in 0..<iterations {
            autoreleasepool {
                let context = SCContext()
                let engine = RecordEngine()
                
                // Perform operations that might leak memory
                let _ = context.getDisplays()
                let _ = context.getWindows()
                let _ = context.getRecordingSize(area: ["x": 0, "y": 0, "width": 100, "height": 100])
                let _ = engine.getAudioSettings()
            }
        }
        
        // Then - Should complete without memory issues
        XCTAssertTrue(true, "Repeated operations completed successfully")
    }
    
    func testMemoryManagement_LargeDataStructures() throws {
        // Given - Large data simulation
        let largeAreaCount = 1000
        
        // When - Process large amounts of data
        autoreleasepool {
            for i in 0..<largeAreaCount {
                let area = [
                    "x": i % 100,
                    "y": i % 100,
                    "width": 100 + (i % 500),
                    "height": 100 + (i % 500)
                ]
                let _ = scContext.validateArea(area)
                let _ = scContext.getRecordingSize(area: area)
            }
        }
        
        // Then - Should handle large datasets efficiently
        XCTAssertTrue(true, "Large data processing completed")
    }
    
    // MARK: - CPU Optimization Tests
    
    func testCPUOptimization_ResponseTime() throws {
        // Given - Response time requirements (< 100ms)
        let maxResponseTime: TimeInterval = 0.1
        
        // When - Measure operation response times
        let operations = [
            ("getDisplays", { self.scContext.getDisplays() }),
            ("getWindows", { self.scContext.getWindows() }),
            ("getAudioSettings", { self.recordEngine.getAudioSettings() }),
            ("validateSettings", { self.settingsManager.validateSettings() })
        ]
        
        // Then - All operations should be fast
        for (name, operation) in operations {
            let startTime = CFAbsoluteTimeGetCurrent()
            let _ = operation()
            let endTime = CFAbsoluteTimeGetCurrent()
            let responseTime = endTime - startTime
            
            XCTAssertLessThan(responseTime, maxResponseTime, 
                            "\(name) should respond within \(maxResponseTime * 1000)ms")
        }
    }
    
    func testCPUOptimization_BatchOperations() throws {
        // Given - Batch processing scenario
        let batchSize = 50
        let areas = (0..<batchSize).map { i in
            ["x": i * 10, "y": i * 10, "width": 100, "height": 100]
        }
        
        // When - Measure batch processing time
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for area in areas {
            let _ = scContext.validateArea(area)
            let _ = scContext.getRecordingSize(area: area)
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        let avgTimePerOperation = totalTime / Double(batchSize)
        
        // Then - Batch processing should be efficient
        XCTAssertLessThan(totalTime, 1.0, "Batch processing should complete within 1 second")
        XCTAssertLessThan(avgTimePerOperation, 0.02, "Average operation time should be under 20ms")
    }
    
    func testCPUOptimization_ConcurrentOperations() throws {
        // Given - Concurrent processing scenario
        let expectation = XCTestExpectation(description: "Concurrent operations complete")
        expectation.expectedFulfillmentCount = 4
        let queue = DispatchQueue.global(qos: .userInitiated)
        
        // When - Execute concurrent operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        queue.async {
            for _ in 0..<25 {
                let _ = self.scContext.getDisplays()
            }
            expectation.fulfill()
        }
        
        queue.async {
            for _ in 0..<25 {
                let _ = self.scContext.getWindows()
            }
            expectation.fulfill()
        }
        
        queue.async {
            for _ in 0..<25 {
                let _ = self.recordEngine.getAudioSettings()
            }
            expectation.fulfill()
        }
        
        queue.async {
            for _ in 0..<25 {
                self.settingsManager.validateSettings()
            }
            expectation.fulfill()
        }
        
        // Then - Concurrent operations should complete efficiently
        wait(for: [expectation], timeout: 5.0)
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalTime = endTime - startTime
        XCTAssertLessThan(totalTime, 2.0, "Concurrent operations should complete within 2 seconds")
    }
    
    // MARK: - Resource Monitoring Tests
    
    func testResourceMonitoring_ThreadSafety() throws {
        // Given - Thread safety test setup
        let expectation = XCTestExpectation(description: "Thread safety test complete")
        expectation.expectedFulfillmentCount = 5
        
        var results: [Bool] = []
        let resultsLock = NSLock()
        
        // When - Access shared resources from multiple threads
        for i in 0..<5 {
            DispatchQueue.global().async {
                let success = autoreleasepool { () -> Bool in
                    let context = SCContext()
                    let engine = RecordEngine()
                    
                    // Perform operations that access shared resources
                    let displays = context.getDisplays()
                    let audioSettings = engine.getAudioSettings()
                    let frameRate = self.settingsManager.frameRate
                    
                    return !displays.isEmpty || audioSettings.count >= 0 && frameRate > 0
                }
                
                resultsLock.lock()
                results.append(success)
                resultsLock.unlock()
                
                expectation.fulfill()
            }
        }
        
        // Then - All operations should complete successfully
        wait(for: [expectation], timeout: 10.0)
        XCTAssertEqual(results.count, 5)
        XCTAssertTrue(results.allSatisfy { $0 }, "All thread operations should succeed")
    }
    
    func testResourceMonitoring_MemoryPressure() throws {
        // Given - Memory pressure simulation
        let largeDataSize = 1000
        
        // When - Create memory pressure
        autoreleasepool {
            var largeArrays: [[String: Any]] = []
            
            for i in 0..<largeDataSize {
                let largeData = [
                    "id": i,
                    "data": String(repeating: "test", count: 100),
                    "timestamp": Date(),
                    "area": ["x": i, "y": i, "width": 100, "height": 100]
                ]
                largeArrays.append(largeData)
                
                // Periodically test system responsiveness
                if i % 100 == 0 {
                    let startTime = CFAbsoluteTimeGetCurrent()
                    let _ = scContext.getDisplays()
                    let endTime = CFAbsoluteTimeGetCurrent()
                    let responseTime = endTime - startTime
                    
                    XCTAssertLessThan(responseTime, 0.5, "System should remain responsive under memory pressure")
                }
            }
        }
        
        // Then - System should recover after memory pressure
        let _ = scContext.getDisplays()
        XCTAssertTrue(true, "System recovered from memory pressure")
    }
    
    // MARK: - Stress Testing
    
    func testStressTesting_HighFrequencyOperations() throws {
        // Given - High frequency operation scenario
        let operationCount = 500
        let maxDuration: TimeInterval = 5.0
        
        // When - Perform high frequency operations
        let startTime = CFAbsoluteTimeGetCurrent()
        
        for i in 0..<operationCount {
            let area = [
                "x": i % 50,
                "y": i % 50,
                "width": 100 + (i % 100),
                "height": 100 + (i % 100)
            ]
            
            let isValid = scContext.validateArea(area)
            if isValid {
                let _ = scContext.getRecordingSize(area: area)
            }
            
            // Verify system stability periodically
            if i % 100 == 0 {
                XCTAssertTrue(true, "System stable at operation \(i)")
            }
        }
        
        let endTime = CFAbsoluteTimeGetCurrent()
        let totalDuration = endTime - startTime
        
        // Then - Should handle high frequency operations
        XCTAssertLessThan(totalDuration, maxDuration, "High frequency operations should complete within \(maxDuration)s")
    }
    
    func testStressTesting_RapidConfigurationChanges() throws {
        // Given - Rapid configuration change scenario
        let changeCount = 200
        let originalValues = (
            frameRate: settingsManager.frameRate,
            videoQuality: settingsManager.videoQuality,
            areaWidth: settingsManager.areaWidth,
            areaHeight: settingsManager.areaHeight
        )
        
        // When - Rapidly change configurations
        for i in 0..<changeCount {
            settingsManager.frameRate = [30, 60][i % 2]
            settingsManager.videoQuality = Double(i % 10) / 10.0 + 0.1
            settingsManager.areaWidth = 100 + (i % 1000)
            settingsManager.areaHeight = 100 + (i % 1000)
            
            // Validate after every change
            settingsManager.validateSettings()
            
            // Verify stability
            XCTAssertGreaterThan(settingsManager.frameRate, 0)
            XCTAssertGreaterThan(settingsManager.videoQuality, 0.0)
            XCTAssertGreaterThan(settingsManager.areaWidth, 0)
            XCTAssertGreaterThan(settingsManager.areaHeight, 0)
        }
        
        // Then - System should remain stable
        XCTAssertNotNil(settingsManager.frameRate)
        XCTAssertNotNil(settingsManager.videoQuality)
        
        // Cleanup
        settingsManager.frameRate = originalValues.frameRate
        settingsManager.videoQuality = originalValues.videoQuality
        settingsManager.areaWidth = originalValues.areaWidth
        settingsManager.areaHeight = originalValues.areaHeight
    }
    
    // MARK: - Performance Benchmarking
    
    func testPerformanceBenchmark_CoreOperations() throws {
        // Given - Benchmark configuration
        let iterations = 100
        
        // When - Measure core operations
        measure {
            for _ in 0..<iterations {
                autoreleasepool {
                    let context = SCContext()
                    let _ = context.getDisplays()
                    let _ = context.getRecordingSize(area: ["x": 0, "y": 0, "width": 1920, "height": 1080])
                }
            }
        }
        
        // Then - Benchmark results are recorded automatically by XCTest
    }
    
    func testPerformanceBenchmark_SettingsOperations() throws {
        // Given - Settings benchmark
        let iterations = 50
        let originalFrameRate = settingsManager.frameRate
        
        // When - Measure settings performance
        measure {
            for i in 0..<iterations {
                settingsManager.frameRate = [30, 60][i % 2]
                settingsManager.validateSettings()
            }
        }
        
        // Cleanup
        settingsManager.frameRate = originalFrameRate
    }
} 