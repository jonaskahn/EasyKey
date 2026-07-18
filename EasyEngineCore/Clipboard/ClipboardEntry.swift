import Foundation

/// Broad classification of one captured clipboard item. `mixed` describes an
/// event whose items do not share a single primary kind.
public enum ClipboardContentKind: String, Codable, Equatable, Sendable, CaseIterable {
    case text
    case url
    case image
    case file
    case video
    case mixed

    /// Kinds a user can toggle in capture settings. `mixed` is derived, never filtered.
    public static let capturable: Set<ClipboardContentKind> = [.text, .url, .image, .file, .video]
}

/// Best-effort attribution of the application that produced a clipboard change.
/// macOS does not expose a pasteboard source, so this is advisory metadata only.
public struct ClipboardSource: Codable, Equatable, Sendable {
    public var applicationName: String?
    public var bundleIdentifier: String?

    public init(applicationName: String? = nil, bundleIdentifier: String? = nil) {
        self.applicationName = applicationName
        self.bundleIdentifier = bundleIdentifier
    }
}

/// Display-only projection of an item. Never used to restore payloads.
public struct ClipboardItemPreview: Codable, Equatable, Sendable {
    public var primaryText: String
    public var secondaryText: String?
    public var fileName: String?
    public var typeLabel: String?
    public var byteCount: Int?
    public var pixelWidth: Int?
    public var pixelHeight: Int?

    public init(
        primaryText: String,
        secondaryText: String? = nil,
        fileName: String? = nil,
        typeLabel: String? = nil,
        byteCount: Int? = nil,
        pixelWidth: Int? = nil,
        pixelHeight: Int? = nil
    ) {
        self.primaryText = primaryText
        self.secondaryText = secondaryText
        self.fileName = fileName
        self.typeLabel = typeLabel
        self.byteCount = byteCount
        self.pixelWidth = pixelWidth
        self.pixelHeight = pixelHeight
    }
}

/// One whitelisted representation needed to restore an item. Type identifiers are
/// inert strings in Core; binary payloads live in the app-layer payload store and
/// are referenced by a stable opaque key.
public enum ClipboardRepresentation: Codable, Equatable, Sendable {
    case string(typeIdentifier: String, value: String)
    case data(typeIdentifier: String, payloadReference: String)
    case fileURL(URL)

    private enum Discriminator: String, Codable {
        case string
        case data
        case fileURL
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case typeIdentifier
        case value
        case payloadReference
        case url
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Discriminator.self, forKey: .kind) {
        case .string:
            self = try .string(
                typeIdentifier: container.decode(String.self, forKey: .typeIdentifier),
                value: container.decode(String.self, forKey: .value)
            )
        case .data:
            self = try .data(
                typeIdentifier: container.decode(String.self, forKey: .typeIdentifier),
                payloadReference: container.decode(String.self, forKey: .payloadReference)
            )
        case .fileURL:
            self = try .fileURL(container.decode(URL.self, forKey: .url))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .string(typeIdentifier, value):
            try container.encode(Discriminator.string, forKey: .kind)
            try container.encode(typeIdentifier, forKey: .typeIdentifier)
            try container.encode(value, forKey: .value)
        case let .data(typeIdentifier, payloadReference):
            try container.encode(Discriminator.data, forKey: .kind)
            try container.encode(typeIdentifier, forKey: .typeIdentifier)
            try container.encode(payloadReference, forKey: .payloadReference)
        case let .fileURL(url):
            try container.encode(Discriminator.fileURL, forKey: .kind)
            try container.encode(url, forKey: .url)
        }
    }
}

/// One pasteboard item within a copy event, with its display preview and the
/// ordered representations required to restore it.
public struct ClipboardItem: Codable, Equatable, Sendable {
    public let kind: ClipboardContentKind
    public let preview: ClipboardItemPreview
    public let representations: [ClipboardRepresentation]

    public init(
        kind: ClipboardContentKind,
        preview: ClipboardItemPreview,
        representations: [ClipboardRepresentation]
    ) {
        self.kind = kind
        self.preview = preview
        self.representations = representations
    }
}

/// One clipboard change. A single event may contain multiple items.
public struct ClipboardEntry: Codable, Equatable, Identifiable, Sendable {
    public let id: UUID
    public let fingerprint: String
    public var capturedAt: Date
    public var source: ClipboardSource?
    public var isPinned: Bool
    public var pinnedAt: Date?
    public let items: [ClipboardItem]

    public init(
        id: UUID = UUID(),
        fingerprint: String,
        capturedAt: Date,
        source: ClipboardSource? = nil,
        isPinned: Bool = false,
        pinnedAt: Date? = nil,
        items: [ClipboardItem]
    ) {
        self.id = id
        self.fingerprint = fingerprint
        self.capturedAt = capturedAt
        self.source = source
        self.isPinned = isPinned
        self.pinnedAt = pinnedAt
        self.items = items
    }

    /// Overall kind for the event: the shared item kind, or `.mixed` when items differ.
    public var kind: ClipboardContentKind {
        guard let first = items.first?.kind else { return .mixed }
        return items.allSatisfy { $0.kind == first } ? first : .mixed
    }

    /// Lowercased searchable tokens drawn from previews, representations, and source.
    /// Never includes binary payloads.
    public var searchableText: String {
        var parts: [String] = []
        for item in items {
            parts.append(item.preview.primaryText)
            if let secondary = item.preview.secondaryText {
                parts.append(secondary)
            }
            if let fileName = item.preview.fileName {
                parts.append(fileName)
            }
            if let typeLabel = item.preview.typeLabel {
                parts.append(typeLabel)
            }
            for representation in item.representations {
                switch representation {
                case let .string(_, value):
                    parts.append(value)
                case let .fileURL(url):
                    parts.append(url.lastPathComponent)
                    if let host = URLComponents(url: url, resolvingAgainstBaseURL: false)?.host {
                        parts.append(host)
                    }
                case .data:
                    break
                }
            }
        }
        if let source {
            if let name = source.applicationName {
                parts.append(name)
            }
            if let bundle = source.bundleIdentifier {
                parts.append(bundle)
            }
        }
        return parts.joined(separator: "\n")
    }
}
