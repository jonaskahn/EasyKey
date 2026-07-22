import Foundation

/// A validated request to translate text with a specific provider.
/// Construction enforces every domain invariant so downstream code never
/// has to re-check for blank text, oversized text, or an equal explicit
/// source/target pair.
public struct TranslationRequest: Equatable, Sendable {
    public static let maximumSourceTextLength = 5000

    public let sourceText: String
    public let sourceLanguage: TranslationLanguage?
    public let targetLanguage: TranslationLanguage
    public let providerID: TranslationProviderID

    /// Returns `nil` when `sourceText` is blank or exceeds
    /// `maximumSourceTextLength`, or when `sourceLanguage` is explicit and
    /// equal to `targetLanguage`.
    public init?(
        sourceText: String,
        sourceLanguage: TranslationLanguage?,
        targetLanguage: TranslationLanguage,
        providerID: TranslationProviderID
    ) {
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        guard sourceText.count <= Self.maximumSourceTextLength else { return nil }
        guard providerID != .automatic else { return nil }
        if let sourceLanguage, sourceLanguage == targetLanguage {
            return nil
        }

        self.sourceText = sourceText
        self.sourceLanguage = sourceLanguage
        self.targetLanguage = targetLanguage
        self.providerID = providerID
    }
}
