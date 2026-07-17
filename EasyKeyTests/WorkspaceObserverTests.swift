import AppKit
@testable import EasyKey
import XCTest

@MainActor
final class WorkspaceObserverTests: XCTestCase {
    func testStart_ThenStop_DoesNotCrash() {
        let observer = WorkspaceObserver()
        observer.start()
        observer.stop()
    }

    func testStart_CalledTwice_ReplacesObserversWithoutCrashing() {
        let observer = WorkspaceObserver()
        observer.start()
        observer.start()
        observer.stop()
    }

    func testStop_WithoutStart_DoesNotCrash() {
        let observer = WorkspaceObserver()
        observer.stop()
    }

    func testOnApplicationActivated_InvokedManually() {
        let observer = WorkspaceObserver()
        let expectation = expectation(description: "activated")
        observer.onApplicationActivated = { application in
            XCTAssertNil(application)
            expectation.fulfill()
        }
        observer.onApplicationActivated?(nil)
        wait(for: [expectation], timeout: 1.0)
    }

    func testOnResetSessionAndOnWake_InvokedManually() {
        let observer = WorkspaceObserver()
        var resetCount = 0
        var wakeCount = 0
        observer.onResetSession = { resetCount += 1 }
        observer.onWake = { wakeCount += 1 }
        observer.onResetSession?()
        observer.onWake?()
        XCTAssertEqual(resetCount, 1)
        XCTAssertEqual(wakeCount, 1)
    }

    func testStart_PostingWorkspaceNotifications_TriggersCallbacks() async {
        let observer = WorkspaceObserver()
        observer.start()
        defer { observer.stop() }

        let resetExpectation = expectation(description: "reset session on space change")
        observer.onResetSession = { resetExpectation.fulfill() }
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        await fulfillment(of: [resetExpectation], timeout: 0.5)

        let wakeExpectation = expectation(description: "wake notification")
        observer.onWake = { wakeExpectation.fulfill() }
        NSWorkspace.shared.notificationCenter.post(
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
        await fulfillment(of: [wakeExpectation], timeout: 0.5)
    }
}
