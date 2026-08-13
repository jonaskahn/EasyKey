@testable import EasyKey
import XCTest

@MainActor
private final class GatedClipboardLifecycle: ClipboardLifecycleManaging {
    private(set) var startCalls = 0
    private(set) var stopCalls = 0
    private var startWaiters: [CheckedContinuation<Void, Never>] = []
    private var stopWaiters: [CheckedContinuation<Void, Never>] = []

    func start(loadPersisted _: Bool) async {
        startCalls += 1
        await withCheckedContinuation { startWaiters.append($0) }
    }

    func stop() async {
        stopCalls += 1
        await withCheckedContinuation { stopWaiters.append($0) }
    }

    var pendingStarts: Int {
        startWaiters.count
    }

    var pendingStops: Int {
        stopWaiters.count
    }

    func releaseStart() {
        startWaiters.removeFirst().resume()
    }

    func releaseStop() {
        stopWaiters.removeFirst().resume()
    }
}

@MainActor
final class AppCoordinatorConcurrencyTests: XCTestCase {
    func testAppCoordinatorInitialization_OnMainActor() {
        let coordinator = AppCoordinator.makeDefault()
        XCTAssertNotNil(coordinator.settingsStore)
    }

    func testNewStartAwaitsPrecedingStop() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppCoordinatorConcurrencyTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let lifecycle = GatedClipboardLifecycle()
        let coordinator = AppCoordinator(
            settingsStore: SettingsStore(fileURL: tempURL.appendingPathComponent("settings.json")),
            clipboardLifecycle: lifecycle
        )

        coordinator.start()
        await waitUntil { lifecycle.pendingStarts == 1 }
        lifecycle.releaseStart()
        await waitUntil { lifecycle.startCalls == 1 }

        coordinator.stop()
        await waitUntil { lifecycle.pendingStops == 1 }
        XCTAssertEqual(lifecycle.stopCalls, 1)

        coordinator.start()
        await waitForMainActorDrain()
        XCTAssertEqual(lifecycle.startCalls, 1, "Restart must wait for the preceding stop")
        XCTAssertEqual(lifecycle.pendingStarts, 0)

        lifecycle.releaseStop()
        await waitUntil { lifecycle.pendingStarts == 1 && lifecycle.startCalls == 2 }
        lifecycle.releaseStart()
        await coordinator.awaitShutdown()
        XCTAssertEqual(lifecycle.stopCalls, 1)
        XCTAssertEqual(lifecycle.startCalls, 2)
    }

    func testCanceledStopCannotStopClipboardAfterRestart() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppCoordinatorConcurrencyTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let lifecycle = GatedClipboardLifecycle()
        let coordinator = AppCoordinator(
            settingsStore: SettingsStore(fileURL: tempURL.appendingPathComponent("settings.json")),
            clipboardLifecycle: lifecycle
        )

        coordinator.start()
        await waitUntil { lifecycle.pendingStarts == 1 }

        coordinator.stop()
        await waitUntil { lifecycle.pendingStops == 0 && lifecycle.stopCalls == 0 }

        coordinator.start()
        await waitUntil { lifecycle.pendingStarts == 1 && lifecycle.startCalls == 1 }

        lifecycle.releaseStart()
        await waitUntil { lifecycle.startCalls == 2 }
        XCTAssertEqual(lifecycle.stopCalls, 0, "A canceled stop must not stop clipboard after restart began")

        lifecycle.releaseStart()
        await coordinator.awaitShutdown()
        XCTAssertEqual(lifecycle.stopCalls, 0)
    }

    private func waitForMainActorDrain() async {
        for _ in 0 ..< 20 {
            await Task.yield()
        }
    }

    private func waitUntil(_ condition: @MainActor () -> Bool) async {
        for _ in 0 ..< 1000 {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail("Timed out waiting for condition")
    }
}
