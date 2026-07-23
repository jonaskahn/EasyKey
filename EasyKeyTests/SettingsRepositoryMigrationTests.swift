@testable import EasyEngineCore
import XCTest

final class SettingsRepositoryMigrationTests: XCTestCase {
    func testSettingsMigration_BumpsSchemaVersion() throws {
        let json: [String: Any] = ["schemaVersion": 1]
        let data = try JSONSerialization.data(withJSONObject: json)

        let migratedData = SettingsMigration.migrate(data)
        let migratedJSON = try XCTUnwrap(try JSONSerialization.jsonObject(with: migratedData) as? [String: Any])

        XCTAssertEqual(migratedJSON["schemaVersion"] as? Int, EasyKeySettings.currentSchemaVersion)
    }
}
