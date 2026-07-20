@testable import EasyEngineCore
import XCTest

final class TranslationProviderResolverTests: XCTestCase {
    private let macOS14 = TranslationPlatformCapability(supportsAppleTranslation: false)
    private let macOS15 = TranslationPlatformCapability(supportsAppleTranslation: true)

    func testAvailableProviders_OnMacOS14_NeverIncludesApple() {
        let providers = TranslationProviderResolver.availableProviders(
            platformCapability: macOS14,
            configuredCloudProviders: [.deepL, .google, .openAI, .anthropic, .gemini]
        )
        XCTAssertFalse(providers.contains(.apple))
        XCTAssertEqual(providers, [.deepL, .google, .openAI, .anthropic, .gemini])
    }

    func testAvailableProviders_OnMacOS15_IncludesAppleFirst() {
        let providers = TranslationProviderResolver.availableProviders(
            platformCapability: macOS15,
            configuredCloudProviders: [.deepL]
        )
        XCTAssertEqual(providers, [.apple, .deepL])
    }

    func testAvailableProviders_UsesStableCloudOrderRegardlessOfConfigurationOrder() {
        let providers = TranslationProviderResolver.availableProviders(
            platformCapability: macOS14,
            configuredCloudProviders: [.gemini, .deepL, .anthropic]
        )
        XCTAssertEqual(providers, [.deepL, .anthropic, .gemini])
    }

    func testAvailableProviders_WithNoConfiguredProvidersAndNoAppleSupport_IsEmpty() {
        let providers = TranslationProviderResolver.availableProviders(
            platformCapability: macOS14,
            configuredCloudProviders: []
        )
        XCTAssertTrue(providers.isEmpty)
    }

    func testAvailability_AppleOnMacOS14_IsUnsupportedOnPlatform() {
        XCTAssertEqual(
            TranslationProviderResolver.availability(
                of: .apple,
                platformCapability: macOS14,
                configuredCloudProviders: []
            ),
            .unsupportedOnPlatform
        )
    }

    func testAvailability_AppleOnMacOS15_IsAvailable() {
        XCTAssertEqual(
            TranslationProviderResolver.availability(
                of: .apple,
                platformCapability: macOS15,
                configuredCloudProviders: []
            ),
            .available
        )
    }

    func testAvailability_ConfiguredCloudProvider_IsAvailable() {
        XCTAssertEqual(
            TranslationProviderResolver.availability(
                of: .deepL,
                platformCapability: macOS14,
                configuredCloudProviders: [.deepL]
            ),
            .available
        )
    }

    func testAvailability_UnconfiguredCloudProvider_IsMissingCredentials() {
        XCTAssertEqual(
            TranslationProviderResolver.availability(
                of: .openAI,
                platformCapability: macOS14,
                configuredCloudProviders: []
            ),
            .missingCredentials
        )
    }

    func testAvailability_Automatic_IsAlwaysAvailableAsAPreferenceValue() {
        XCTAssertEqual(
            TranslationProviderResolver.availability(
                of: .automatic,
                platformCapability: macOS14,
                configuredCloudProviders: []
            ),
            .available
        )
    }

    func testResolve_AutomaticOnMacOS15_ResolvesToApple() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: nil,
            platformCapability: macOS15,
            configuredCloudProviders: [.deepL]
        )
        XCTAssertEqual(resolution, .resolved(.apple))
    }

    func testResolve_AutomaticOnMacOS14_ResolvesToFirstConfiguredCloudProviderInStableOrder() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: nil,
            platformCapability: macOS14,
            configuredCloudProviders: [.gemini, .google]
        )
        XCTAssertEqual(resolution, .resolved(.google))
    }

    func testResolve_ExplicitAutomaticProviderID_BehavesLikeNilPreference() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .automatic,
            platformCapability: macOS15,
            configuredCloudProviders: []
        )
        XCTAssertEqual(resolution, .resolved(.apple))
    }

    func testResolve_NoUsableProviderAnywhere_ReturnsSetupRequired() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: nil,
            platformCapability: macOS14,
            configuredCloudProviders: []
        )
        XCTAssertEqual(resolution, .setupRequired)
    }

    func testResolve_ExplicitAvailablePreference_IsUsedDirectly() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .anthropic,
            platformCapability: macOS15,
            configuredCloudProviders: [.anthropic, .deepL]
        )
        XCTAssertEqual(resolution, .resolved(.anthropic))
    }

    func testResolve_SavedApplePreferenceOnMacOS14_FallsBackToFirstConfiguredCloudProvider() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .apple,
            platformCapability: macOS14,
            configuredCloudProviders: [.google]
        )
        XCTAssertEqual(resolution, .resolved(.google))
    }

    func testResolve_SavedApplePreferenceRestoredOnMacOS15_ResolvesToAppleAgain() {
        // Simulates the same saved preference across an OS upgrade: the
        // resolver never mutates the preference, so passing the identical
        // preferredProviderID with macOS 15 capability alone restores Apple.
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .apple,
            platformCapability: macOS15,
            configuredCloudProviders: [.google]
        )
        XCTAssertEqual(resolution, .resolved(.apple))
    }

    func testResolve_ExplicitCloudPreferenceMissingCredentials_FallsBackRatherThanSetupRequired() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .openAI,
            platformCapability: macOS14,
            configuredCloudProviders: [.deepL]
        )
        XCTAssertEqual(resolution, .resolved(.deepL))
    }

    func testResolve_ExplicitUnavailablePreferenceWithNoFallback_ReturnsSetupRequired() {
        let resolution = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .openAI,
            platformCapability: macOS14,
            configuredCloudProviders: []
        )
        XCTAssertEqual(resolution, .setupRequired)
    }

    func testResolve_IsDeterministic_SameInputsProduceSameOutput() {
        let first = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .deepL,
            platformCapability: macOS15,
            configuredCloudProviders: [.deepL]
        )
        let second = TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: .deepL,
            platformCapability: macOS15,
            configuredCloudProviders: [.deepL]
        )
        XCTAssertEqual(first, second)
    }
}
