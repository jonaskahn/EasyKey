@testable import EasyKey
import XCTest

@MainActor
final class AppCoordinatorLifecycleTests: XCTestCase {
    func testRapidStartStopStartSequence_DoesNotCrash() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppCoordinatorLifecycleTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let settingsStore = SettingsStore(fileURL: tempURL.appendingPathComponent("settings.json"))
        let coordinator = AppCoordinator(settingsStore: settingsStore)

        coordinator.start()
        coordinator.stop()
        coordinator.start()
        coordinator.stop()
        await coordinator.awaitShutdown()
    }

    func testAwaitShutdown_FlushesSave() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppCoordinatorLifecycleTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempURL, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let settingsStore = SettingsStore(fileURL: tempURL.appendingPathComponent("settings.json"))
        let coordinator = AppCoordinator(settingsStore: settingsStore)

        coordinator.start()
        coordinator.stop()
        await coordinator.awaitShutdown()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.appendingPathComponent("settings.json").path))
    }
}
