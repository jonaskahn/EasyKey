import EasyEngineCore
@testable import EasyKey
import Security
import XCTest

/// Deterministic `SecItem` stand-in. Only ever driven synchronously from a
/// single test method, so `@unchecked Sendable` carries no real concurrency risk.
private final class FakeSecItemAccess: SecItemAccessing, @unchecked Sendable {
    var copyMatchingResult: (status: OSStatus, result: CFTypeRef?) = (errSecItemNotFound, nil)
    var addStatus: OSStatus = errSecSuccess
    var updateStatus: OSStatus = errSecSuccess
    var deleteStatus: OSStatus = errSecSuccess

    func copyMatching(_: [String: Any]) -> (status: OSStatus, result: CFTypeRef?) {
        copyMatchingResult
    }

    func add(_: [String: Any]) -> OSStatus {
        addStatus
    }

    func update(_: [String: Any], attributesToUpdate _: [String: Any]) -> OSStatus {
        updateStatus
    }

    func delete(_: [String: Any]) -> OSStatus {
        deleteStatus
    }
}

final class TranslationCredentialStoreTests: XCTestCase {
    private func assertContract(_ store: TranslationCredentialStoring) throws {
        XCTAssertFalse(try store.hasCredential(for: .deepL))
        XCTAssertNil(try store.credential(for: .deepL))

        try store.save("secret-key-1", for: .deepL)
        XCTAssertTrue(try store.hasCredential(for: .deepL))
        XCTAssertEqual(try store.credential(for: .deepL), "secret-key-1")

        try store.save("secret-key-2", for: .google)
        XCTAssertEqual(try store.credential(for: .deepL), "secret-key-1", "Saving google must not overwrite deepL")
        XCTAssertEqual(try store.credential(for: .google), "secret-key-2")

        try store.save("secret-key-1-updated", for: .deepL)
        XCTAssertEqual(try store.credential(for: .deepL), "secret-key-1-updated")
        XCTAssertEqual(try store.credential(for: .google), "secret-key-2", "Updating deepL must not affect google")

        try store.deleteCredential(for: .deepL)
        XCTAssertFalse(try store.hasCredential(for: .deepL))
        XCTAssertNil(try store.credential(for: .deepL))
        XCTAssertTrue(try store.hasCredential(for: .google), "Deleting deepL must not remove google")

        try store.deleteCredential(for: .google)
        XCTAssertFalse(try store.hasCredential(for: .google))
    }

    func testInMemoryStore_SatisfiesContract() throws {
        try assertContract(InMemoryTranslationCredentialStore())
    }

    func testInMemoryStore_RejectsBlankCredential() {
        let store = InMemoryTranslationCredentialStore()
        XCTAssertThrowsError(try store.save("", for: .openAI)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .blankCredential)
        }
        XCTAssertThrowsError(try store.save("   ", for: .openAI)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .blankCredential)
        }
    }

    func testInMemoryStore_TrimsWhitespaceAroundSavedCredential() throws {
        let store = InMemoryTranslationCredentialStore()
        try store.save("  key-value  ", for: .anthropic)
        XCTAssertEqual(try store.credential(for: .anthropic), "key-value")
    }

    func testInMemoryStore_DeleteForMissingProvider_DoesNotThrow() {
        let store = InMemoryTranslationCredentialStore()
        XCTAssertNoThrow(try store.deleteCredential(for: .deepL))
    }

    func testInMemoryStore_InitialCredentialsSeedLookups() throws {
        let store = InMemoryTranslationCredentialStore(credentials: [.gemini: "seeded"])
        XCTAssertEqual(try store.credential(for: .gemini), "seeded")
    }

    func testStatus_ReflectsPresenceOnly() throws {
        let store = InMemoryTranslationCredentialStore()
        XCTAssertEqual(try store.status(for: .gemini), .missing)
        try store.save("key", for: .gemini)
        XCTAssertEqual(try store.status(for: .gemini), .saved)
    }

    func testKeychainStore_SatisfiesContract() throws {
        let store = KeychainTranslationCredentialStore(service: "one.ifelse.easykey.translation.tests")
        defer {
            try? store.deleteCredential(for: .deepL)
            try? store.deleteCredential(for: .google)
        }
        do {
            try assertContract(store)
        } catch TranslationCredentialError.unexpectedStatus {
            throw XCTSkip("Keychain access unavailable in this test environment")
        }
    }

    func testKeychainStore_RejectsBlankCredential() {
        let store = KeychainTranslationCredentialStore(service: "one.ifelse.easykey.translation.tests")
        XCTAssertThrowsError(try store.save("  ", for: .openAI)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .blankCredential)
        }
    }

    func testKeychainStore_DeleteForMissingProvider_DoesNotThrow() throws {
        let store = KeychainTranslationCredentialStore(service: "one.ifelse.easykey.translation.tests")
        do {
            try store.deleteCredential(for: .anthropic)
        } catch TranslationCredentialError.unexpectedStatus {
            throw XCTSkip("Keychain access unavailable in this test environment")
        }
    }

    func testHasCredential_UnexpectedStatus_Throws() {
        let access = FakeSecItemAccess()
        access.copyMatchingResult = (errSecParam, nil)
        let store = KeychainTranslationCredentialStore(access: access)

        XCTAssertThrowsError(try store.hasCredential(for: .deepL)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .unexpectedStatus(errSecParam))
        }
    }

    func testCredential_UnexpectedStatus_Throws() {
        let access = FakeSecItemAccess()
        access.copyMatchingResult = (errSecParam, nil)
        let store = KeychainTranslationCredentialStore(access: access)

        XCTAssertThrowsError(try store.credential(for: .deepL)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .unexpectedStatus(errSecParam))
        }
    }

    func testCredential_WithNonDecodableStoredValue_ThrowsInvalidStoredData() {
        let access = FakeSecItemAccess()
        access.copyMatchingResult = (errSecSuccess, NSNumber(value: 1))
        let store = KeychainTranslationCredentialStore(access: access)

        XCTAssertThrowsError(try store.credential(for: .deepL)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .invalidStoredData)
        }
    }

    func testSave_WhenAddFails_ThrowsUnexpectedStatus() {
        let access = FakeSecItemAccess()
        access.copyMatchingResult = (errSecItemNotFound, nil)
        access.addStatus = errSecParam
        let store = KeychainTranslationCredentialStore(access: access)

        XCTAssertThrowsError(try store.save("key", for: .deepL)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .unexpectedStatus(errSecParam))
        }
    }

    func testSave_WhenUpdateFails_ThrowsUnexpectedStatus() {
        let access = FakeSecItemAccess()
        access.copyMatchingResult = (errSecSuccess, nil)
        access.updateStatus = errSecParam
        let store = KeychainTranslationCredentialStore(access: access)

        XCTAssertThrowsError(try store.save("key", for: .deepL)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .unexpectedStatus(errSecParam))
        }
    }

    func testDeleteCredential_UnexpectedStatus_Throws() {
        let access = FakeSecItemAccess()
        access.deleteStatus = errSecParam
        let store = KeychainTranslationCredentialStore(access: access)

        XCTAssertThrowsError(try store.deleteCredential(for: .deepL)) {
            XCTAssertEqual($0 as? TranslationCredentialError, .unexpectedStatus(errSecParam))
        }
    }
}
