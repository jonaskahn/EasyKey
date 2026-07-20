import Foundation

/// A successful translation result returned by a provider adapter.
public struct TranslationResponse: Equatable, Sendable {
    public let translatedText: String
    public let detectedSourceLanguage: TranslationLanguage?
    public let providerID: TranslationProviderID

    public init(
        translatedText: String,
        detectedSourceLanguage: TranslationLanguage?,
        providerID: TranslationProviderID
    ) {
        self.translatedText = translatedText
        self.detectedSourceLanguage = detectedSourceLanguage
        self.providerID = providerID
    }
}
