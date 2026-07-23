@testable import EasyEngineCore
import XCTest

@MainActor
final class SettingsStoreAsyncWriteTests: XCTestCase {
    func testSaveNow_FlushesSettingsToDisk() async {
        let tempURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("SettingsStoreAsyncWriteTests-\(UUID().uuidString).json")
        defer { try? FileManager.default.removeItem(at: tempURL) }

        let repo = SettingsRepository(fileURL: tempURL)
        repo.update { $0.typing.spellCheck = false }
        await repo.saveNow()

        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
    }
}
