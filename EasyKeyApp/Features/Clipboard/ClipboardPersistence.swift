import CryptoKit
import EasyEngineCore
import Foundation

enum ClipboardPersistenceError: Error, Equatable {
    case keyUnavailable
    case decryptionFailed
    case malformedDocument
    case unsupportedSchema
}

/// Versioned on-disk document. Kept separate from the Core model so persistence
/// format can evolve independently.
struct ClipboardPersistenceDocument: Codable, Equatable {
    static let currentSchemaVersion = 1

    let schemaVersion: Int
    let savedAt: Date
    let entries: [ClipboardEntry]
}

/// The loaded plaintext state: entries plus their decrypted binary payloads.
struct ClipboardPersistedState: Equatable {
    let entries: [ClipboardEntry]
    let payloads: [String: Data]

    static let empty = ClipboardPersistedState(entries: [], payloads: [:])
}

/// Serializes every clipboard persistence operation and keeps CryptoKit, the
/// Keychain, and the filesystem out of Core. History is AES-GCM sealed; image and
/// RTF payloads are sealed in separate files addressed by their reference.
actor ClipboardPersistence {
    private let directory: URL
    private let keyProvider: ClipboardKeyProviding

    init(directory: URL, keyProvider: ClipboardKeyProviding) {
        self.directory = directory
        self.keyProvider = keyProvider
    }

    private var manifestURL: URL {
        directory.appendingPathComponent("manifest.ekc")
    }

    private var payloadDirectory: URL {
        directory.appendingPathComponent("payloads", isDirectory: true)
    }

    func save(entries: [ClipboardEntry], payloads: [String: Data]) throws {
        let key = try keyProvider.existingKey() ?? keyProvider.createKey()
        try FileManager.default.createDirectory(at: payloadDirectory, withIntermediateDirectories: true)

        let referenced = Set(payloads.keys)
        for (reference, data) in payloads {
            let url = payloadURL(for: reference)
            guard !FileManager.default.fileExists(atPath: url.path) else { continue }
            let sealed = try AES.GCM.seal(data, using: key).combined ?? Data()
            try writeAtomically(sealed, to: url)
        }

        let document = ClipboardPersistenceDocument(
            schemaVersion: ClipboardPersistenceDocument.currentSchemaVersion,
            savedAt: Date(),
            entries: entries
        )
        let encoded = try JSONEncoder().encode(document)
        let sealedManifest = try AES.GCM.seal(encoded, using: key).combined ?? Data()
        try writeAtomically(sealedManifest, to: manifestURL)

        removeOrphanPayloads(keeping: referenced)
    }

    func load() throws -> ClipboardPersistedState {
        guard FileManager.default.fileExists(atPath: manifestURL.path) else {
            return .empty
        }
        guard let key = try keyProvider.existingKey() else {
            throw ClipboardPersistenceError.keyUnavailable
        }
        let sealedManifest = try Data(contentsOf: manifestURL)
        let manifestData = try open(sealedManifest, using: key)
        let document: ClipboardPersistenceDocument
        do {
            document = try JSONDecoder().decode(ClipboardPersistenceDocument.self, from: manifestData)
        } catch {
            throw ClipboardPersistenceError.malformedDocument
        }
        guard document.schemaVersion <= ClipboardPersistenceDocument.currentSchemaVersion else {
            throw ClipboardPersistenceError.unsupportedSchema
        }

        var payloads: [String: Data] = [:]
        for reference in referencedPayloads(in: document.entries) {
            let url = payloadURL(for: reference)
            guard let sealed = try? Data(contentsOf: url) else { continue }
            payloads[reference] = try open(sealed, using: key)
        }
        return ClipboardPersistedState(entries: document.entries, payloads: payloads)
    }

    func deleteAll() throws {
        try? FileManager.default.removeItem(at: directory)
        try keyProvider.deleteKey()
    }

    // MARK: - Helpers

    private func open(_ sealed: Data, using key: SymmetricKey) throws -> Data {
        do {
            let box = try AES.GCM.SealedBox(combined: sealed)
            return try AES.GCM.open(box, using: key)
        } catch {
            throw ClipboardPersistenceError.decryptionFailed
        }
    }

    private func referencedPayloads(in entries: [ClipboardEntry]) -> Set<String> {
        var references: Set<String> = []
        for entry in entries {
            for item in entry.items {
                for representation in item.representations {
                    if case let .data(_, payloadReference) = representation {
                        references.insert(payloadReference)
                    }
                }
            }
        }
        return references
    }

    private func removeOrphanPayloads(keeping referenced: Set<String>) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: payloadDirectory,
            includingPropertiesForKeys: nil
        )
        else { return }
        let keep = Set(referenced.map { payloadURL(for: $0).lastPathComponent })
        for file in files where !keep.contains(file.lastPathComponent) {
            try? FileManager.default.removeItem(at: file)
        }
    }

    private func payloadURL(for reference: String) -> URL {
        let name = reference
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: ".", with: "_")
        return payloadDirectory.appendingPathComponent(name).appendingPathExtension("ekp")
    }

    private func writeAtomically(_ data: Data, to url: URL) throws {
        let temp = url.appendingPathExtension("tmp")
        try data.write(to: temp, options: .atomic)
        _ = try? FileManager.default.removeItem(at: url)
        try FileManager.default.moveItem(at: temp, to: url)
    }
}
