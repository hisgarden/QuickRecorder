//
//  ViewModelTests.swift
//  QuickRecorderTests
//
//  Created by TDD on 2025/06/16.
//

import XCTest
import SwiftUI
import Combine
@testable import QuickRecorder

class ViewModelTests: XCTestCase {
    
    var cancellables: Set<AnyCancellable>!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        cancellables = Set<AnyCancellable>()
    }
    
    override func tearDownWithError() throws {
        cancellables?.removeAll()
        cancellables = nil
        try super.tearDownWithError()
    }
    
    // MARK: - PopoverState Tests
    
    func testPopoverState_InitialState() throws {
        // Given & When
        let popoverState = PopoverState()
        
        // Then
        XCTAssertFalse(popoverState.isPopoverOpen)
        XCTAssertFalse(popoverState.showStatus)
    }
    
    func testPopoverState_TogglePopover() throws {
        // Given
        let popoverState = PopoverState()
        var stateChanges = [Bool]()
        
        // When
        popoverState.$isPopoverOpen
            .sink { stateChanges.append($0) }
            .store(in: &cancellables)
        
        popoverState.isPopoverOpen = true
        
        // Then
        XCTAssertTrue(popoverState.isPopoverOpen)
        XCTAssertEqual(stateChanges.last, true)
    }
    
    func testPopoverState_StatusVisibility() throws {
        // Given
        let popoverState = PopoverState()
        let expectation = XCTestExpectation(description: "Status change")
        
        // When
        popoverState.$showStatus
            .dropFirst() // Skip initial value
            .sink { showStatus in
                XCTAssertTrue(showStatus)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        popoverState.showStatus = true
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(popoverState.showStatus)
    }
    
    // MARK: - AppSelectorViewModel Tests
    
    func testAppSelectorViewModel_InitialState() throws {
        // Given & When
        let viewModel = AppSelectorViewModel()
        
        // Then
        XCTAssertTrue(viewModel.allApps.isEmpty)
        XCTAssertFalse(viewModel.isReady)
    }
    
    func testAppSelectorViewModel_UpdateAppList_MockData() throws {
        // Given
        let viewModel = AppSelectorViewModel()
        let expectation = XCTestExpectation(description: "App list updated")
        
        // When
        viewModel.$isReady
            .dropFirst() // Skip initial false value
            .sink { isReady in
                if isReady {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        // Simulate app list update (this would normally call SCContext.updateAvailableContent)
        DispatchQueue.main.async {
            viewModel.isReady = true
        }
        
        // Then
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(viewModel.isReady)
    }
    
    func testAppSelectorViewModel_StateConsistency() throws {
        // Given
        let viewModel = AppSelectorViewModel()
        var readyStates = [Bool]()
        var appCounts = [Int]()
        
        // When
        viewModel.$isReady
            .sink { readyStates.append($0) }
            .store(in: &cancellables)
        
        viewModel.$allApps
            .sink { appCounts.append($0.count) }
            .store(in: &cancellables)
        
        // Simulate state changes
        DispatchQueue.main.async {
            viewModel.isReady = true
        }
        
        // Then
        let readyExpectation = expectation(description: "Ready state changed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(readyStates, [false, true])
            readyExpectation.fulfill()
        }
        
        wait(for: [readyExpectation], timeout: 1.0)
    }
    
    // MARK: - AudioPlayerManager Tests
    
    func testAudioPlayerManager_InitialState() throws {
        // Given & When
        let audioManager = AudioPlayerManager()
        
        // Then
        XCTAssertNil(audioManager.audioPlayer)
        XCTAssertFalse(audioManager.isPlaying)
        XCTAssertEqual(audioManager.currentTime, 0.0)
        XCTAssertEqual(audioManager.duration, 0.0)
        XCTAssertEqual(audioManager.volume, 1.0)
    }
    
    func testAudioPlayerManager_VolumeControl() throws {
        // Given
        let audioManager = AudioPlayerManager()
        var volumeChanges = [Float]()
        
        // When
        audioManager.$volume
            .sink { volumeChanges.append($0) }
            .store(in: &cancellables)
        
        audioManager.volume = 0.5
        audioManager.volume = 0.0
        audioManager.volume = 1.0
        
        // Then
        XCTAssertEqual(audioManager.volume, 1.0)
        XCTAssertEqual(volumeChanges.last, 1.0)
        XCTAssertGreaterThanOrEqual(volumeChanges.count, 2)
    }
    
    func testAudioPlayerManager_PlaybackState() throws {
        // Given
        let audioManager = AudioPlayerManager()
        let expectation = XCTestExpectation(description: "Playback state changed")
        
        // When
        audioManager.$isPlaying
            .dropFirst() // Skip initial value
            .sink { isPlaying in
                XCTAssertTrue(isPlaying)
                expectation.fulfill()
            }
            .store(in: &cancellables)
        
        // Simulate playback start
        audioManager.isPlaying = true
        
        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertTrue(audioManager.isPlaying)
    }
    
    func testAudioPlayerManager_TimeTracking() throws {
        // Given
        let audioManager = AudioPlayerManager()
        var timeUpdates = [TimeInterval]()
        
        // When
        audioManager.$currentTime
            .sink { timeUpdates.append($0) }
            .store(in: &cancellables)
        
        audioManager.currentTime = 30.0
        audioManager.currentTime = 60.0
        audioManager.currentTime = 120.0
        
        // Then
        XCTAssertEqual(audioManager.currentTime, 120.0)
        XCTAssertTrue(timeUpdates.contains(0.0)) // Initial value
        XCTAssertTrue(timeUpdates.contains(120.0)) // Final value
    }
    
    func testAudioPlayerManager_DurationSetting() throws {
        // Given
        let audioManager = AudioPlayerManager()
        let testDuration: TimeInterval = 180.0
        
        // When
        audioManager.duration = testDuration
        
        // Then
        XCTAssertEqual(audioManager.duration, testDuration)
    }
    
    // MARK: - Memory Management Tests
    
    func testViewModels_MemoryManagement() throws {
        // Given
        var popoverState: PopoverState? = PopoverState()
        var appSelector: AppSelectorViewModel? = AppSelectorViewModel()
        var audioManager: AudioPlayerManager? = AudioPlayerManager()
        
        weak var weakPopover = popoverState
        weak var weakAppSelector = appSelector
        weak var weakAudioManager = audioManager
        
        // When
        popoverState = nil
        appSelector = nil
        audioManager = nil
        
        // Then
        XCTAssertNil(weakPopover, "PopoverState should be deallocated")
        XCTAssertNil(weakAppSelector, "AppSelectorViewModel should be deallocated")
        XCTAssertNil(weakAudioManager, "AudioPlayerManager should be deallocated")
    }
    
    // MARK: - Concurrent Access Tests
    
    func testViewModels_ConcurrentAccess() throws {
        // Given
        let popoverState = PopoverState()
        let expectation = XCTestExpectation(description: "Concurrent access completed")
        expectation.expectedFulfillmentCount = 100
        
        // When
        for i in 0..<100 {
            DispatchQueue.global(qos: .background).async {
                popoverState.isPopoverOpen = (i % 2 == 0)
                popoverState.showStatus = (i % 3 == 0)
                DispatchQueue.main.async {
                    expectation.fulfill()
                }
            }
        }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        // Test passes if no crashes occur during concurrent access
    }
    
    // MARK: - Performance Tests
    
    func testAppSelectorViewModel_Performance() throws {
        // Given
        let viewModel = AppSelectorViewModel()
        
        // When & Then
        measure {
            for _ in 0..<1000 {
                viewModel.isReady = !viewModel.isReady
            }
        }
    }
    
    func testAudioPlayerManager_VolumePerformance() throws {
        // Given
        let audioManager = AudioPlayerManager()
        
        // When & Then
        measure {
            for i in 0..<1000 {
                audioManager.volume = Float(i % 100) / 100.0
            }
        }
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    /// Wait for multiple published value changes
    func waitForPublishedChanges<T>(
        on publisher: Published<T>.Publisher,
        expectedCount: Int,
        timeout: TimeInterval = 1.0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let expectation = XCTestExpectation(description: "Published value changes")
        expectation.expectedFulfillmentCount = expectedCount
        
        let cancellable = publisher
            .sink { _ in expectation.fulfill() }
        
        wait(for: [expectation], timeout: timeout)
        cancellable.cancel()
    }
} 