import Foundation

/// A BCP-47 language identifier shared across translation providers.
/// Provider-specific language code mapping stays in each provider adapter;
/// this value carries only the generic identifier.
public struct TranslationLanguage: Equatable, Hashable, Sendable {
    public let identifier: String

    private init(validated identifier: String) {
        self.identifier = identifier
    }

    /// Creates a language value from a BCP-47 identifier, trimming
    /// surrounding whitespace. Returns `nil` when the trimmed identifier is
    /// empty, since an empty identifier cannot represent a real language.
    public init?(bcp47 identifier: String) {
        let trimmed = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        self.init(validated: Locale.canonicalLanguageIdentifier(from: trimmed))
    }

    public static let english = TranslationLanguage(validated: "en")
    public static let vietnamese = TranslationLanguage(validated: "vi")
}

extension TranslationLanguage: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        guard let value = TranslationLanguage(bcp47: raw) else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Translation language identifier must not be empty."
            )
        }
        self = value
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(identifier)
    }
}
