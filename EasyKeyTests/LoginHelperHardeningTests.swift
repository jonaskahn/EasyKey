@testable import EasyKey
import XCTest
import Foundation

final class LoginHelperHardeningTests: XCTestCase {
    func testLoginHelperEntitlements_HasSandboxEnabled() throws {
        let bundle = Bundle(for: type(of: self))
        // Navigate up to find EasyKeyLoginHelper.entitlements in project source
        var dirURL = bundle.bundleURL
        var entitlementsURL: URL? = nil
        
        for _ in 0..<10 {
            let candidate = dirURL.appendingPathComponent("EasyKeyLoginHelper/EasyKeyLoginHelper.entitlements")
            if FileManager.default.fileExists(atPath: candidate.path) {
                entitlementsURL = candidate
                break
            }
            dirURL = dirURL.deletingLastPathComponent()
        }
        
        guard let url = entitlementsURL else {
            XCTFail("Could not locate EasyKeyLoginHelper.entitlements")
            return
        }
        
        let data = try Data(contentsOf: url)
        let propertyList = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any]
        
        XCTAssertNotNil(propertyList, "Entitlements property list should parse successfully")
        XCTAssertEqual(propertyList?["com.apple.security.app-sandbox"] as? Bool, true, "com.apple.security.app-sandbox must be true")
        XCTAssertEqual(propertyList?["com.apple.security.files.user-selected.read-only"] as? Bool, true, "com.apple.security.files.user-selected.read-only must be true")
    }
}
