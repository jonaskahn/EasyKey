import EasyEngineCore
import Foundation

/// Narrow contract every translation provider adapter implements: submit a
/// validated request, return a response, or throw a `TranslationError`.
/// Networking, Keychain, and platform frameworks stay behind the concrete
/// adapter; `TranslationModel` only ever sees this seam.
protocol TranslationProviding: Sendable {
    func translate(_ request: TranslationRequest) async throws -> TranslationResponse
}

protocol TranslationEndpointDisclosing: Sendable {
    var disclosureIdentity: TranslationDisclosureIdentity { get }
}

/// Resolves a provider identifier to a live adapter, or `nil` when the
/// provider is not currently constructible (e.g. missing credentials).
typealias TranslationProviderLookup = @Sendable (TranslationProviderID) -> TranslationProviding?

/// Asks whether a cloud request to `providerID` may proceed. Returns `false`
/// when the user declines or cancels a disclosure prompt. Non-cloud
/// providers may resolve immediately with `true`.
typealias TranslationDisclosureDecision = @MainActor @Sendable (TranslationDisclosureIdentity) async -> Bool

struct TranslationDisclosureIdentity: Hashable, Sendable {
    let providerID: TranslationProviderID
    let endpointOrigin: String?

    init(providerID: TranslationProviderID, endpointOrigin: String? = nil) {
        self.providerID = providerID
        self.endpointOrigin = endpointOrigin
    }
}
