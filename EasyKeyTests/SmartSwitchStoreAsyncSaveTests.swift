@testable import EasyEngineCore
import XCTest

final class SmartSwitchStoreAsyncSaveTests: XCTestCase {
    func testFlush_WritesPendingStateToDisk() throws {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SmartSwitchStoreAsyncSaveTests-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let store = SmartSwitchStore(fileURL: tempURL)
        let app = ApplicationIdentity(bundleIdentifier: "com.apple.Safari", name: "Safari")
        let choice = SmartSwitchChoice(language: .english)

        _ = try store.handleAppFocus(app, currentChoice: choice)
        store.flush()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
    }
}
