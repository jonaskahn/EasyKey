import AppKit
@testable import EasyKeyKit
import XCTest

@MainActor
final class KeyboardServiceSleepWakeTests: XCTestCase {
    private func postSleep() {
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.willSleepNotification, object: nil)
    }

    private func postWake() {
        NSWorkspace.shared.notificationCenter.post(name: NSWorkspace.didWakeNotification, object: nil)
    }

    func testStoppedService_SleepWake_StaysStopped() {
        let service = KeyboardService(settings: .defaults)
        service.start()
        service.stop()
        XCTAssertEqual(service.health, .stopped)

        postSleep()
        XCTAssertEqual(service.health, .stopped, "Sleep must not degrade a stopped service")

        postWake()
        XCTAssertEqual(service.health, .stopped, "Wake must not restart a stopped service")
    }

    func testPausedService_SleepWake_StaysStopped() {
        let service = KeyboardService(settings: .defaults)
        service.start()
        service.setPaused(true)
        XCTAssertEqual(service.health, .stopped)

        postSleep()
        XCTAssertEqual(service.health, .stopped, "Sleep must not degrade a paused service")

        postWake()
        XCTAssertEqual(service.health, .stopped, "Wake must not restart a paused service")
    }

    func testRunningService_SleepDegradesThenWakeRecovers() {
        let service = KeyboardService(settings: .defaults)
        service.start()

        let degraded = expectation(description: "degraded on sleep")
        let recovered = expectation(description: "recovery on wake")
        var sawDegraded = false
        service.healthHandler = { health in
            if health == .degraded {
                sawDegraded = true
                degraded.fulfill()
            } else if sawDegraded {
                recovered.fulfill()
            }
        }

        postSleep()
        wait(for: [degraded], timeout: 2)
        XCTAssertTrue(sawDegraded)

        postWake()
        wait(for: [recovered], timeout: 2)
        XCTAssertNotEqual(service.health, .degraded)
    }
}
