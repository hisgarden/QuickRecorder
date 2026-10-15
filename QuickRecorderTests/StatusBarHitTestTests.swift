//
//  StatusBarHitTestTests.swift
//  QuickRecorderTests
//
//  On macOS 27 SwiftUI buttons hosted in the NSStatusItem button never fire,
//  so menu bar clicks are routed by pointer x through StatusBarHitTest.
//

import XCTest
@testable import QuickRecorder

final class StatusBarHitTestTests: XCTestCase {

    private var hitTest: StatusBarHitTest!

    override func setUp() {
        super.setUp()
        hitTest = StatusBarHitTest.shared
        hitTest.reset()
    }

    override func tearDown() {
        hitTest.reset()
        hitTest = nil
        super.tearDown()
    }

    private func frame(_ minX: CGFloat, _ maxX: CGFloat) -> CGRect {
        CGRect(x: minX, y: 0, width: maxX - minX, height: 16)
    }

    func testMenuBarClick_OnStopControl_StopsRecording() {
        var fired = [String]()
        hitTest.register(id: "stop", frame: frame(4, 20), generation: hitTest.generation) { fired.append("stop") }
        hitTest.register(id: "pause", frame: frame(24, 40), generation: hitTest.generation) { fired.append("pause") }

        hitTest.handleClick(atX: 12)

        XCTAssertEqual(fired, ["stop"])
    }

    func testMenuBarClick_OnPauseControl_FiresPauseOnly() {
        var fired = [String]()
        hitTest.register(id: "stop", frame: frame(4, 20), generation: hitTest.generation) { fired.append("stop") }
        hitTest.register(id: "pause", frame: frame(24, 40), generation: hitTest.generation) { fired.append("pause") }

        hitTest.handleClick(atX: 30)

        XCTAssertEqual(fired, ["pause"])
    }

    func testMenuBarClick_OutsideAnyControl_FiresNothing() {
        var fired = [String]()
        hitTest.register(id: "stop", frame: frame(4, 20), generation: hitTest.generation) { fired.append("stop") }

        hitTest.handleClick(atX: 100)

        XCTAssertTrue(fired.isEmpty)
    }

    func testMenuBarClick_ZeroWidthControl_IsNotRegistered() {
        var fired = [String]()
        hitTest.register(id: "stop", frame: frame(10, 10), generation: hitTest.generation) { fired.append("stop") }

        hitTest.handleClick(atX: 10)

        XCTAssertTrue(fired.isEmpty)
    }

    func testMenuBarClick_DuplicateSendForOneClick_PauseDoesNotToggleTwice() {
        var pauseCount = 0
        hitTest.register(id: "pause", frame: frame(24, 40), generation: hitTest.generation) { pauseCount += 1 }

        hitTest.handleClick(atX: 30)
        hitTest.handleClick(atX: 30)

        XCTAssertEqual(pauseCount, 1)
    }

    func testMenuBarClick_DifferentControlsInQuickSuccession_BothFire() {
        var fired = [String]()
        hitTest.register(id: "stop", frame: frame(4, 20), generation: hitTest.generation) { fired.append("stop") }
        hitTest.register(id: "pause", frame: frame(24, 40), generation: hitTest.generation) { fired.append("pause") }

        hitTest.handleClick(atX: 30)
        hitTest.handleClick(atX: 12)

        XCTAssertEqual(fired, ["pause", "stop"])
    }

    func testMenuBarRebuild_StaleRegistration_IsIgnored() {
        var fired = [String]()
        let staleGeneration = hitTest.generation
        hitTest.reset()

        hitTest.register(id: "stop", frame: frame(4, 20), generation: staleGeneration) { fired.append("stale") }
        hitTest.handleClick(atX: 12)

        XCTAssertTrue(fired.isEmpty)
    }

    func testMenuBarRebuild_LateTeardownOfOldView_KeepsNewRegistration() {
        var fired = [String]()
        let oldGeneration = hitTest.generation
        hitTest.reset()
        hitTest.register(id: "stop", frame: frame(4, 20), generation: hitTest.generation) { fired.append("stop") }

        hitTest.unregister(id: "stop", generation: oldGeneration)
        hitTest.handleClick(atX: 12)

        XCTAssertEqual(fired, ["stop"])
    }

    func testMenuBarUnregister_CurrentGeneration_RemovesControl() {
        var fired = [String]()
        hitTest.register(id: "stop", frame: frame(4, 20), generation: hitTest.generation) { fired.append("stop") }

        hitTest.unregister(id: "stop", generation: hitTest.generation)
        hitTest.handleClick(atX: 12)

        XCTAssertTrue(fired.isEmpty)
    }
}
