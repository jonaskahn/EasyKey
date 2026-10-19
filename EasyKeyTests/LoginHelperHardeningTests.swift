@testable import EasyKey
import Foundation
import XCTest

final class LoginHelperHardeningTests: XCTestCase {
    func testLoginHelperEntitlements_HasSandboxEnabled() throws {
        // Anchor to source so DerivedData may live outside the checkout.
        let projectRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let url = projectRoot.appendingPathComponent("EasyKeyLoginHelper/EasyKeyLoginHelper.entitlements")

        let data = try Data(contentsOf: url)
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]

        XCTAssertNotNil(propertyList, "Entitlements property list should parse successfully")
        XCTAssertEqual(propertyList?["com.apple.security.app-sandbox"] as? Bool, true, "com.apple.security.app-sandbox must be true")
        XCTAssertEqual(
            propertyList?["com.apple.security.files.user-selected.read-only"] as? Bool,
            true,
            "com.apple.security.files.user-selected.read-only must be true"
        )
    }
}
