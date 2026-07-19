import EasyEngineCore
import Foundation
import Translation

/// Apple on-device translation adapter. Only ever constructed inside a
/// macOS 15 runtime-availability guard; never registered on macOS 14.
///
/// Deliberately does not import SwiftUI: `ApplicationServices` (pulled in
/// transitively by SwiftUI/AppKit) declares a legacy `Translation` class
/// that shadows the `Translation` module name in qualified lookups such as
/// `Translation.TranslationError`. Keeping this file SwiftUI-free is what
/// lets `Translation.TranslationError` resolve to the framework, not the
/// Carbon-era `ApplicationServices.Translation`.
/// Alias for Apple's `Translation.TranslationError`, defined in this
/// SwiftUI-free file so callers (including tests, which pull in
/// `ApplicationServices` transitively through `XCTest`) never have to write
/// the colliding `Translation.TranslationError` qualification themselves.
@available(macOS 15.0, *)
typealias AppleTranslationError = Translation.TranslationError

@available(macOS 15.0, *)
final class AppleTranslationProvider: TranslationProviding {
    private let bridge: AppleTranslationSessionBridging
    private let languageAvailability: AppleLanguageAvailabilityChecking

    init(
        bridge: AppleTranslationSessionBridging,
        languageAvailability: AppleLanguageAvailabilityChecking = SystemLanguageAvailability()
    ) {
        self.bridge = bridge
        self.languageAvailability = languageAvailability
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        let targetLocale = Locale.Language(identifier: request.targetLanguage.identifier)
        let sourceLocale = request.sourceLanguage.map { Locale.Language(identifier: $0.identifier) }

        if let sourceLocale, let explicitSource = request.sourceLanguage {
            try await checkAvailability(
                source: sourceLocale,
                target: targetLocale,
                domainSource: explicitSource,
                domainTarget: request.targetLanguage
            )
        }

        do {
            let response = try await bridge.translate(text: request.sourceText, source: sourceLocale, target: targetLocale)
            let detectedSource = TranslationLanguage(bcp47: response.sourceLanguage.minimalIdentifier)
            return TranslationResponse(
                translatedText: response.targetText,
                detectedSourceLanguage: detectedSource,
                providerID: .apple
            )
        } catch {
            throw Self.mapAppleError(error, source: request.sourceLanguage, target: request.targetLanguage)
        }
    }

    private func checkAvailability(
        source sourceLocale: Locale.Language,
        target targetLocale: Locale.Language,
        domainSource: TranslationLanguage,
        domainTarget: TranslationLanguage
    ) async throws {
        let availability = await languageAvailability.status(from: sourceLocale, to: targetLocale)
        switch availability {
        case .installed:
            return
        case .supported:
            throw EasyEngineCore.TranslationError.appleLanguageDownloadRequired
        case .unsupported:
            throw EasyEngineCore.TranslationError.unsupportedLanguagePair(source: domainSource, target: domainTarget)
        @unknown default:
            return
        }
    }

    private static func mapAppleError(
        _ error: Error,
        source: TranslationLanguage?,
        target: TranslationLanguage
    ) -> EasyEngineCore.TranslationError {
        if error is CancellationError {
            return .cancelled
        }
        switch error {
        case AppleTranslationError.unsupportedSourceLanguage,
             AppleTranslationError.unsupportedTargetLanguage,
             AppleTranslationError.unsupportedLanguagePairing:
            return .unsupportedLanguagePair(source: source ?? target, target: target)
        default:
            return .providerUnavailable(provider: .apple, httpStatus: nil)
        }
    }
}
