@testable import EasyKey
import Security
import XCTest

private final class RecordingSecItemAccess: SecItemAccessing, @unchecked Sendable {
    var lastUpdateAttributes: [String: Any]?
    var lastBaseQuery: [String: Any]?
    var hasCredential = true

    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, result: CFTypeRef?) {
        lastBaseQuery = query
        if hasCredential {
            return (errSecSuccess, kCFBooleanTrue)
        }
        return (errSecItemNotFound, nil)
    }

    func add(_ query: [String: Any]) -> OSStatus {
        lastBaseQuery = query
        return errSecSuccess
    }

    func update(_ query: [String: Any], attributesToUpdate: [String: Any]) -> OSStatus {
        lastBaseQuery = query
        lastUpdateAttributes = attributesToUpdate
        return errSecSuccess
    }

    func delete(_ query: [String: Any]) -> OSStatus {
        lastBaseQuery = query
        return errSecSuccess
    }
}

final class KeychainAccessibilityMigrationTests: XCTestCase {
    func testSave_OnUpdate_ReAssertsAccessibilityAttribute() throws {
        let access = RecordingSecItemAccess()
        let store = TranslationCredentialStore(service: "test-service", access: access)
        
        try store.save("new-secret", for: .google)
        
        XCTAssertNotNil(access.lastUpdateAttributes)
        XCTAssertEqual(
            access.lastUpdateAttributes?[kSecAttrAccessible as String] as? String,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly as String,
            "Keychain update query must re-assert kSecAttrAccessibleWhenUnlockedThisDeviceOnly"
        )
    }

    func testBaseQuery_IncludesDataProtectionKeychainFlag() throws {
        let access = RecordingSecItemAccess()
        let store = TranslationCredentialStore(service: "test-service", access: access)
        
        _ = try store.credential(for: .google)
        
        XCTAssertNotNil(access.lastBaseQuery)
        XCTAssertEqual(
            access.lastBaseQuery?[kSecUseDataProtectionKeychain as String] as? Bool,
            true,
            "Keychain query must set kSecUseDataProtectionKeychain to true"
        )
    }
}
