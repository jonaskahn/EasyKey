import CryptoKit
import Foundation
import Security

enum ClipboardKeyError: Error, Equatable {
    case unexpectedStatus(OSStatus)
    case invalidKeyData
}

/// Supplies the symmetric key used to seal clipboard persistence. A narrow seam
/// so tests can substitute an in-memory key and never touch the user Keychain.
protocol ClipboardKeyProviding: Sendable {
    func existingKey() throws -> SymmetricKey?
    func createKey() throws -> SymmetricKey
    func deleteKey() throws
}

/// Stores a 256-bit key in the Keychain, unlocked-this-device-only and never
/// synchronized, so persisted clipboard history cannot leave the device.
struct KeychainClipboardKeyStore: ClipboardKeyProviding {
    let service: String
    let account: String

    init(service: String = "one.ifelse.easykey.clipboard", account: String = "history-key") {
        self.service = service
        self.account = account
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
        ]
    }

    func existingKey() throws -> SymmetricKey? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data else { throw ClipboardKeyError.invalidKeyData }
            return SymmetricKey(data: data)
        case errSecItemNotFound:
            return nil
        default:
            throw ClipboardKeyError.unexpectedStatus(status)
        }
    }

    func createKey() throws -> SymmetricKey {
        let key = SymmetricKey(size: .bits256)
        let data = key.withUnsafeBytes { Data($0) }
        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else { throw ClipboardKeyError.unexpectedStatus(status) }
        return key
    }

    func deleteKey() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw ClipboardKeyError.unexpectedStatus(status)
        }
    }
}

/// In-memory key provider for tests and previews.
final class InMemoryClipboardKeyStore: ClipboardKeyProviding, @unchecked Sendable {
    private let lock = NSLock()
    private var key: SymmetricKey?

    init(key: SymmetricKey? = nil) {
        self.key = key
    }

    func existingKey() throws -> SymmetricKey? {
        lock.lock(); defer { lock.unlock() }
        return key
    }

    func createKey() throws -> SymmetricKey {
        lock.lock(); defer { lock.unlock() }
        if let key {
            return key
        }
        let created = SymmetricKey(size: .bits256)
        key = created
        return created
    }

    func deleteKey() throws {
        lock.lock(); defer { lock.unlock() }
        key = nil
    }
}
