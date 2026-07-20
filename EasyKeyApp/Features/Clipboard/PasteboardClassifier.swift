import CryptoKit
import EasyEngineCore
import Foundation

/// A classified clipboard event plus the binary payloads its representations
/// reference. Payloads are keyed by opaque reference strings that Core stores
/// verbatim.
struct ClassifiedClipboard: Equatable {
    let entry: ClipboardEntry
    let payloads: [String: Data]
}

/// Translates an immutable pasteboard snapshot into a framework-free
/// `ClipboardEntry`, computing a stable SHA-256 fingerprint over canonical
/// ordered representations. Owns the accepted-type list; never reads arbitrary types.
struct PasteboardClassifier {
    static let plainText = "public.utf8-plain-text"
    static let html = "public.html"
    static let rtf = "public.rtf"
    static let webURL = "public.url"
    static let fileURL = "public.file-url"
    static let png = "public.png"
    static let tiff = "public.tiff"

    static let acceptedTypes: [String] = [fileURL, webURL, png, tiff, rtf, html, plainText]

    private static let videoExtensions: Set<String> = ["mp4", "mov", "m4v", "avi", "mkv", "webm", "mpg", "mpeg", "wmv", "flv"]

    /// Requests the accepted identifiers present in each descriptor item.
    func selection(for descriptor: PasteboardDescriptor) -> [[String]] {
        descriptor.items.map { item in
            Self.acceptedTypes.filter { item.typeIdentifiers.contains($0) }
        }
    }

    /// Returns `nil` when nothing supported remains. Assumes the caller already
    /// rejected sensitive-marker events and validated the change count.
    func classify(_ snapshot: PasteboardSnapshot, source: ClipboardSource?, now: Date) -> ClassifiedClipboard? {
        var items: [ClassifiedItem] = []
        for (index, itemSnapshot) in snapshot.items.enumerated() {
            var map: [String: Data] = [:]
            for representation in itemSnapshot.representations {
                map[representation.typeIdentifier] = representation.data
            }
            if let classified = classifyItem(map, itemIndex: index) {
                items.append(classified)
            }
        }
        guard !items.isEmpty else { return nil }

        let eventBytes = items.reduce(0) { $0 + $1.canonicalByteCount }
        guard eventBytes <= ClipboardLimits.maximumEventBytes else { return nil }

        let fingerprint = Self.fingerprint(of: items)
        var payloads: [String: Data] = [:]
        var entryItems: [ClipboardItem] = []
        for (index, item) in items.enumerated() {
            var representations: [ClipboardRepresentation] = []
            for pending in item.representations {
                switch pending {
                case let .string(typeIdentifier, value):
                    representations.append(.string(typeIdentifier: typeIdentifier, value: value))
                case let .fileURL(url):
                    representations.append(.fileURL(url))
                case let .data(typeIdentifier, data):
                    let reference = "\(fingerprint).\(index).\(Self.sanitize(typeIdentifier))"
                    payloads[reference] = data
                    representations.append(.data(typeIdentifier: typeIdentifier, payloadReference: reference))
                }
            }
            entryItems.append(ClipboardItem(kind: item.kind, preview: item.preview, representations: representations))
        }

        let entry = ClipboardEntry(
            fingerprint: fingerprint,
            capturedAt: now,
            source: source,
            items: entryItems
        )
        return ClassifiedClipboard(entry: entry, payloads: payloads)
    }

    private func classifyItem(_ map: [String: Data], itemIndex _: Int) -> ClassifiedItem? {
        if let data = map[Self.fileURL], let url = Self.decodeURL(data) {
            let name = url.lastPathComponent
            let ext = url.pathExtension.lowercased()
            let isVideo = Self.videoExtensions.contains(ext)
            let preview = ClipboardItemPreview(
                primaryText: name,
                secondaryText: url.deletingLastPathComponent().path,
                fileName: name,
                typeLabel: ext.isEmpty ? nil : ext.uppercased()
            )
            return ClassifiedItem(kind: isVideo ? .video : .file, preview: preview, representations: [.fileURL(url)])
        }

        if let data = map[Self.webURL], let string = Self.decodeString(data) {
            let host = URLComponents(string: string)?.host
            let preview = ClipboardItemPreview(primaryText: string, secondaryText: host)
            return ClassifiedItem(kind: .url, preview: preview, representations: [.string(Self.webURL, string)])
        }

        if let png = map[Self.png] {
            return imageItem(typeIdentifier: Self.png, data: png, label: "PNG")
        }
        if let tiff = map[Self.tiff] {
            return imageItem(typeIdentifier: Self.tiff, data: tiff, label: "TIFF")
        }

        if let data = map[Self.plainText], let text = Self.decodeString(data) {
            var representations: [PendingRepresentation] = [.string(Self.plainText, text)]
            if let htmlData = map[Self.html], let htmlString = Self.decodeString(htmlData) {
                representations.append(.string(Self.html, htmlString))
            }
            if let rtfData = map[Self.rtf] {
                representations.append(.data(Self.rtf, rtfData))
            }
            let preview = ClipboardItemPreview(primaryText: text)
            return ClassifiedItem(kind: .text, preview: preview, representations: representations)
        }

        return nil
    }

    private func imageItem(typeIdentifier: String, data: Data, label: String) -> ClassifiedItem {
        let preview = ClipboardItemPreview(primaryText: label + " image", typeLabel: label, byteCount: data.count)
        return ClassifiedItem(kind: .image, preview: preview, representations: [.data(typeIdentifier, data)])
    }

    static func fingerprint(of items: [ClassifiedItem]) -> String {
        var hasher = SHA256()
        for item in items {
            hasher.update(data: Data([0x1E]))
            for representation in item.canonicalRepresentations {
                hasher.update(data: Data(representation.typeIdentifier.utf8))
                hasher.update(data: Data([0x1F]))
                hasher.update(data: representation.bytes)
                hasher.update(data: Data([0x1F]))
            }
        }
        return hasher.finalize().map { String(format: "%02x", $0) }.joined()
    }

    private static func sanitize(_ identifier: String) -> String {
        identifier.replacingOccurrences(of: "/", with: "_").replacingOccurrences(of: ".", with: "-")
    }

    private static func decodeString(_ data: Data) -> String? {
        String(data: data, encoding: .utf8)
    }

    private static func decodeURL(_ data: Data) -> URL? {
        guard let string = decodeString(data), !string.isEmpty else { return nil }
        if let url = URL(string: string), url.isFileURL {
            return url
        }
        return URL(fileURLWithPath: string)
    }
}

/// Intermediate classification carrying canonical bytes for fingerprinting.
struct ClassifiedItem: Equatable {
    let kind: ClipboardContentKind
    let preview: ClipboardItemPreview
    let representations: [PendingRepresentation]

    var canonicalRepresentations: [CanonicalRepresentation] {
        representations
            .map(\.canonical)
            .sorted { lhs, rhs in
                if lhs.priority != rhs.priority {
                    return lhs.priority < rhs.priority
                }
                return lhs.typeIdentifier < rhs.typeIdentifier
            }
    }

    var canonicalByteCount: Int {
        canonicalRepresentations.reduce(0) { $0 + $1.bytes.count }
    }
}

enum PendingRepresentation: Equatable {
    case string(String, String)
    case data(String, Data)
    case fileURL(URL)

    var canonical: CanonicalRepresentation {
        switch self {
        case let .string(typeIdentifier, value):
            CanonicalRepresentation(typeIdentifier: typeIdentifier, bytes: Data(value.utf8))
        case let .data(typeIdentifier, data):
            CanonicalRepresentation(typeIdentifier: typeIdentifier, bytes: data)
        case let .fileURL(url):
            CanonicalRepresentation(typeIdentifier: PasteboardClassifier.fileURL, bytes: Data(url.absoluteString.utf8))
        }
    }
}

struct CanonicalRepresentation: Equatable {
    let typeIdentifier: String
    let bytes: Data

    var priority: Int {
        PasteboardClassifier.acceptedTypes.firstIndex(of: typeIdentifier) ?? Int.max
    }
}
