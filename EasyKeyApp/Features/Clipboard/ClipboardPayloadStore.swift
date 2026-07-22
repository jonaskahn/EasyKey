import Foundation

enum ClipboardPayloadError: Error, Equatable {
    case missingReference
}

/// Session-scoped binary payload store. Core entries reference payloads by opaque
/// key; this holds the bytes for the current run, enforcing the fixed total-size
/// safety cap. Encrypted mirroring to disk is layered on by persistence.
@MainActor
final class ClipboardPayloadStore {
    private var payloads: [String: Data] = [:]
    private(set) var totalByteCount = 0

    func data(for reference: String) throws -> Data {
        guard let data = payloads[reference] else { throw ClipboardPayloadError.missingReference }
        return data
    }

    func contains(_ reference: String) -> Bool {
        payloads[reference] != nil
    }

    @discardableResult
    func insert(_ newPayloads: [String: Data]) -> Bool {
        let additionalBytes = newPayloads.reduce(0) { count, payload in
            count + (payloads[payload.key] == nil ? payload.value.count : 0)
        }
        guard totalByteCount + additionalBytes <= ClipboardLimits.maximumRetainedBytes else { return false }
        for (reference, data) in newPayloads where payloads[reference] == nil {
            payloads[reference] = data
            totalByteCount += data.count
        }
        return true
    }

    func remove(references: Set<String>) {
        for reference in references {
            if let data = payloads.removeValue(forKey: reference) {
                totalByteCount -= data.count
            }
        }
    }

    func clear() {
        payloads.removeAll()
        totalByteCount = 0
    }

    /// References currently held. Used to compute orphans against live entries.
    var references: Set<String> {
        Set(payloads.keys)
    }

    /// Total bytes held by the supplied references that are currently stored.
    func byteCount(of references: Set<String>) -> Int {
        references.reduce(0) { $0 + (payloads[$1]?.count ?? 0) }
    }
}
