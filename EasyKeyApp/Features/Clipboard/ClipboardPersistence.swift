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
    private static let sealedOverheadBytes = 64
    private static let maximumManifestBytes = ClipboardLimits.maximumEventBytes

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
        guard isValid(entries),
              referencedPayloads(in: entries) == Set(payloads.keys),
              payloads.values.reduce(0, { $0 + $1.count }) <= ClipboardLimits.maximumRetainedBytes,
              payloads.values.allSatisfy({ $0.count <= ClipboardLimits.maximumEventBytes })
        else {
            throw ClipboardPersistenceError.malformedDocument
        }
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
        guard encoded.count <= Self.maximumManifestBytes else {
            throw ClipboardPersistenceError.malformedDocument
        }
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
        let sealedManifest = try boundedData(
            at: manifestURL,
            maximumBytes: Self.maximumManifestBytes + Self.sealedOverheadBytes
        )
        let manifestData = try open(sealedManifest, using: key)
        let document: ClipboardPersistenceDocument
        do {
            document = try JSONDecoder().decode(ClipboardPersistenceDocument.self, from: manifestData)
        } catch {
            throw ClipboardPersistenceError.malformedDocument
        }
        guard document.schemaVersion == ClipboardPersistenceDocument.currentSchemaVersion else {
            throw ClipboardPersistenceError.unsupportedSchema
        }
        guard isValid(document.entries) else {
            throw ClipboardPersistenceError.malformedDocument
        }

        var payloads: [String: Data] = [:]
        var loadedByteCount = 0
        for reference in referencedPayloads(in: document.entries) {
            let url = payloadURL(for: reference)
            let sealed = try boundedData(
                at: url,
                maximumBytes: ClipboardLimits.maximumEventBytes + Self.sealedOverheadBytes
            )
            let payload = try open(sealed, using: key)
            loadedByteCount += payload.count
            guard loadedByteCount <= ClipboardLimits.maximumRetainedBytes else {
                throw ClipboardPersistenceError.malformedDocument
            }
            payloads[reference] = payload
        }
        return ClipboardPersistedState(entries: document.entries, payloads: payloads)
    }

    func deleteAll() throws {
        try Task.checkCancellation()
        if FileManager.default.fileExists(atPath: directory.path) {
            try FileManager.default.removeItem(at: directory)
        }
        try keyProvider.deleteKey()
    }

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

    private func isValid(_ entries: [ClipboardEntry]) -> Bool {
        let allowedReferenceCharacters = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_."))
        return entries.allSatisfy { entry in
            guard !entry.fingerprint.isEmpty,
                  !entry.items.isEmpty,
                  entry.isPinned == (entry.pinnedAt != nil)
            else { return false }
            return entry.items.allSatisfy { item in
                ClipboardContentKind.capturable.contains(item.kind) && !item.representations.isEmpty &&
                    item.representations.allSatisfy { representation in
                        guard case let .data(_, reference) = representation else { return true }
                        return !reference.isEmpty && reference.unicodeScalars.allSatisfy {
                            allowedReferenceCharacters.contains($0)
                        }
                    }
            }
        }
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
        try data.write(to: url, options: .atomic)
    }

    private func boundedData(at url: URL, maximumBytes: Int) throws -> Data {
        let values: URLResourceValues
        do {
            values = try url.resourceValues(forKeys: [.fileSizeKey, .isRegularFileKey])
        } catch {
            throw ClipboardPersistenceError.malformedDocument
        }
        guard values.isRegularFile == true,
              let fileSize = values.fileSize,
              fileSize <= maximumBytes
        else {
            throw ClipboardPersistenceError.malformedDocument
        }
        do {
            let data = try Data(contentsOf: url, options: .mappedIfSafe)
            guard data.count <= maximumBytes else {
                throw ClipboardPersistenceError.malformedDocument
            }
            return data
        } catch let error as ClipboardPersistenceError {
            throw error
        } catch {
            throw ClipboardPersistenceError.malformedDocument
        }
    }
}
