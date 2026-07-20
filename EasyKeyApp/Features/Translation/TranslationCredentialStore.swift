import EasyEngineCore
import Foundation
import Security

/// Presentable credential state for a single cloud provider. Never carries
/// the credential value itself. `.validating` and `.ready`/`.invalid` are
/// assigned by the caller that performs live key verification; the store
/// itself only ever distinguishes missing from saved.
enum TranslationCredentialStatus: Equatable, Sendable {
    case missing
    case saved
    case validating
    case ready
    case invalid
}

enum TranslationCredentialError: Error, Equatable, Sendable {
    case blankCredential
    case unexpectedStatus(OSStatus)
    case invalidStoredData
}

/// Stores and retrieves one API key per cloud translation provider. A narrow
/// seam so tests and previews never touch the user Keychain, and so no
/// caller above this layer needs Security framework knowledge.
protocol TranslationCredentialStoring: Sendable {
    func hasCredential(for provider: TranslationProviderID) throws -> Bool
    func credential(for provider: TranslationProviderID) throws -> String?
    func save(_ apiKey: String, for provider: TranslationProviderID) throws
    func deleteCredential(for provider: TranslationProviderID) throws
}

extension TranslationCredentialStoring {
    /// Presence-only status derivable from storage alone. Callers that
    /// perform live key verification layer `.validating`, `.ready`, and
    /// `.invalid` on top of this.
    func status(for provider: TranslationProviderID) throws -> TranslationCredentialStatus {
        try hasCredential(for: provider) ? .saved : .missing
    }
}

/// Seam over the four `SecItem` calls the store needs, so tests can inject
/// arbitrary `OSStatus` failures without depending on genuine Security
/// framework error conditions.
protocol SecItemAccessing: Sendable {
    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, result: CFTypeRef?)
    func add(_ attributes: [String: Any]) -> OSStatus
    func update(_ query: [String: Any], attributesToUpdate: [String: Any]) -> OSStatus
    func delete(_ query: [String: Any]) -> OSStatus
}

struct SystemSecItemAccess: SecItemAccessing {
    func copyMatching(_ query: [String: Any]) -> (status: OSStatus, result: CFTypeRef?) {
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        return (status, result)
    }

    func add(_ attributes: [String: Any]) -> OSStatus {
        SecItemAdd(attributes as CFDictionary, nil)
    }

    func update(_ query: [String: Any], attributesToUpdate: [String: Any]) -> OSStatus {
        SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
    }

    func delete(_ query: [String: Any]) -> OSStatus {
        SecItemDelete(query as CFDictionary)
    }
}

/// Keychain-backed credential store. Each provider gets its own account
/// under one translation-specific service, unlocked-this-device-only and
/// never synchronized, so keys cannot leave the device or collide across
/// providers.
struct KeychainTranslationCredentialStore: TranslationCredentialStoring {
    let service: String
    private let access: SecItemAccessing

    init(service: String = "one.ifelse.easykey.translation", access: SecItemAccessing = SystemSecItemAccess()) {
        self.service = service
        self.access = access
    }

    func hasCredential(for provider: TranslationProviderID) throws -> Bool {
        var query = baseQuery(for: provider)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let (status, _) = access.copyMatching(query)
        switch status {
        case errSecSuccess:
            return true
        case errSecItemNotFound:
            return false
        default:
            throw TranslationCredentialError.unexpectedStatus(status)
        }
    }

    func credential(for provider: TranslationProviderID) throws -> String? {
        var query = baseQuery(for: provider)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        let (status, result) = access.copyMatching(query)
        switch status {
        case errSecSuccess:
            guard let data = result as? Data, let value = String(data: data, encoding: .utf8) else {
                throw TranslationCredentialError.invalidStoredData
            }
            return value
        case errSecItemNotFound:
            return nil
        default:
            throw TranslationCredentialError.unexpectedStatus(status)
        }
    }

    func save(_ apiKey: String, for provider: TranslationProviderID) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationCredentialError.blankCredential }
        let data = Data(trimmed.utf8)

        if try hasCredential(for: provider) {
            let status = access.update(baseQuery(for: provider), attributesToUpdate: [kSecValueData as String: data])
            guard status == errSecSuccess else { throw TranslationCredentialError.unexpectedStatus(status) }
            return
        }

        var attributes = baseQuery(for: provider)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        let status = access.add(attributes)
        guard status == errSecSuccess else { throw TranslationCredentialError.unexpectedStatus(status) }
    }

    func deleteCredential(for provider: TranslationProviderID) throws {
        let status = access.delete(baseQuery(for: provider))
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw TranslationCredentialError.unexpectedStatus(status)
        }
    }

    private func baseQuery(for provider: TranslationProviderID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: provider.rawValue,
            kSecAttrSynchronizable as String: false,
        ]
    }
}

/// In-memory credential store for tests and previews. Never persists to disk
/// or the Keychain. All mutable state is guarded by `lock`, making cross-actor
/// access safe.
final class InMemoryTranslationCredentialStore: TranslationCredentialStoring, @unchecked Sendable {
    private let lock = NSLock()
    private var credentials: [TranslationProviderID: String] = [:]

    init(credentials: [TranslationProviderID: String] = [:]) {
        self.credentials = credentials
    }

    func hasCredential(for provider: TranslationProviderID) throws -> Bool {
        lock.lock(); defer { lock.unlock() }
        return credentials[provider] != nil
    }

    func credential(for provider: TranslationProviderID) throws -> String? {
        lock.lock(); defer { lock.unlock() }
        return credentials[provider]
    }

    func save(_ apiKey: String, for provider: TranslationProviderID) throws {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { throw TranslationCredentialError.blankCredential }
        lock.lock(); defer { lock.unlock() }
        credentials[provider] = trimmed
    }

    func deleteCredential(for provider: TranslationProviderID) throws {
        lock.lock(); defer { lock.unlock() }
        credentials.removeValue(forKey: provider)
    }
}
