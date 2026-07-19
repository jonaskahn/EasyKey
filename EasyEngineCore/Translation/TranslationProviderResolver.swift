import Foundation

/// Why a given provider is or is not currently usable.
public enum TranslationProviderAvailability: Equatable, Sendable {
    case available
    case unsupportedOnPlatform
    case missingCredentials
}

/// Outcome of resolving a provider preference into a provider EasyKey can
/// actually use right now.
public enum TranslationProviderResolution: Equatable, Sendable {
    case resolved(TranslationProviderID)
    case setupRequired
}

/// Deterministic, side-effect-free provider selection. Every OS and
/// configuration fact is passed in explicitly; nothing here reads
/// `ProcessInfo`, Keychain, or settings storage.
public enum TranslationProviderResolver {
    /// Stable fallback order for Automatic resolution among cloud providers.
    public static let cloudProviderOrder: [TranslationProviderID] = [
        .deepL, .google, .openAI, .anthropic, .gemini,
    ]

    /// The availability of a single provider given platform capability and
    /// which cloud providers currently have usable credentials. `.automatic`
    /// is always `.available` as a preference value; its concrete target is
    /// determined by `resolveEffectiveProvider`.
    public static func availability(
        of providerID: TranslationProviderID,
        platformCapability: TranslationPlatformCapability,
        configuredCloudProviders: Set<TranslationProviderID>
    ) -> TranslationProviderAvailability {
        switch providerID {
        case .automatic:
            return .available
        case .apple:
            return platformCapability.supportsAppleTranslation ? .available : .unsupportedOnPlatform
        case .deepL, .google, .openAI, .anthropic, .gemini:
            return configuredCloudProviders.contains(providerID) ? .available : .missingCredentials
        }
    }

    /// Providers selectable right now, in stable display order: Apple first
    /// when the platform supports it, then configured cloud providers in
    /// `cloudProviderOrder`. Never includes Apple on an unsupporting platform.
    public static func availableProviders(
        platformCapability: TranslationPlatformCapability,
        configuredCloudProviders: Set<TranslationProviderID>
    ) -> [TranslationProviderID] {
        var providers: [TranslationProviderID] = []
        if platformCapability.supportsAppleTranslation {
            providers.append(.apple)
        }
        providers.append(contentsOf: cloudProviderOrder.filter(configuredCloudProviders.contains))
        return providers
    }

    /// Resolves a saved preference to a concrete usable provider.
    ///
    /// An explicit, currently available preference wins outright. Automatic
    /// (`nil`) and an explicit preference that is temporarily unavailable —
    /// such as a saved Apple preference on macOS 14 — both fall back to the
    /// same rule: Apple when the platform supports it, otherwise the first
    /// configured cloud provider in `cloudProviderOrder`. The caller's saved
    /// preference is never read from or written to here, so a temporarily
    /// unavailable preference is preserved untouched for when it becomes
    /// available again.
    public static func resolveEffectiveProvider(
        preferredProviderID: TranslationProviderID?,
        platformCapability: TranslationPlatformCapability,
        configuredCloudProviders: Set<TranslationProviderID>
    ) -> TranslationProviderResolution {
        let available = availableProviders(
            platformCapability: platformCapability,
            configuredCloudProviders: configuredCloudProviders
        )

        if let preferredProviderID, preferredProviderID != .automatic, available.contains(preferredProviderID) {
            return .resolved(preferredProviderID)
        }

        if platformCapability.supportsAppleTranslation {
            return .resolved(.apple)
        }
        if let fallbackCloudProvider = cloudProviderOrder.first(where: configuredCloudProviders.contains) {
            return .resolved(fallbackCloudProvider)
        }
        return .setupRequired
    }
}
