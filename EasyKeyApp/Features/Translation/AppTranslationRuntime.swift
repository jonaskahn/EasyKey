import AppKit
import EasyEngineCore
import SwiftUI

@MainActor
final class AppTranslationRuntime {
    struct Dependencies {
        var credentialStore: TranslationCredentialStoring
        var platformCapability: TranslationPlatformCapability
        var capture: TranslationActivationCapturing
        var hotKeyRegistrar: TranslationHotKeyRegistering
        var disclosurePrompt: TranslationDisclosureController.Prompt?
        var panelPresenter: ((TranslationModel, TranslationSpeechController) -> TranslationPanelPresenter)?
        var speech: TranslationSpeechController?

        @MainActor static var production: Dependencies {
            let capability: TranslationPlatformCapability
            if #available(macOS 15.0, *) {
                capability = TranslationPlatformCapability(supportsAppleTranslation: true)
            } else {
                capability = TranslationPlatformCapability(supportsAppleTranslation: false)
            }
            return Dependencies(
                credentialStore: KeychainTranslationCredentialStore(),
                platformCapability: capability,
                capture: SelectedTextCaptureCoordinator(),
                hotKeyRegistrar: CarbonTranslationHotKeyRegistrar(),
                disclosurePrompt: nil,
                panelPresenter: nil,
                speech: nil
            )
        }
    }

    let credentialStore: TranslationCredentialStoring
    let platformCapability: TranslationPlatformCapability
    let model: TranslationModel
    let speech: TranslationSpeechController
    let settingsModel: TranslationSettingsModel

    private let settingsStore: SettingsStore
    private let localization: LocalizationStore
    private let registry = TranslationProviderRegistry()
    private let capture: TranslationActivationCapturing
    private let disclosure: TranslationDisclosureController
    private let hotKeyRegistrar: TranslationHotKeyRegistering
    private let panelPresenterFactory: ((TranslationModel, TranslationSpeechController) -> TranslationPanelPresenter)?
    private let appleProvider: TranslationProviding?
    private let appleSessionHost: AnyView?
    private var isStarted = false
    private(set) var providerRevision = 0
    var onConfigurationChange: (() -> Void)?
    /// Invoked right before the shortcut opens the floating panel. The
    /// coordinator uses this to dismiss the menu-bar popover first, since the
    /// two surfaces are never meant to be visible at the same time.
    var onWillActivate: (() -> Void)?

    private lazy var hotKeyController = TranslationHotKeyController(
        registrar: hotKeyRegistrar,
        onActivate: { [weak self] in self?.activateFromShortcut() }
    )

    private lazy var panelPresenter: TranslationPanelPresenter = {
        let presenter = panelPresenterFactory?(model, speech)
            ?? TranslationPanelPresenter(translation: model, speech: speech, localization: localization)
        presenter.makeContent = { [weak self] in
            guard let self else { return AnyView(EmptyView()) }
            return panelContent()
        }
        presenter.panelSizeProvider = { [weak self] in
            self?.settingsStore.settings.translation.panelSize.cgSize ?? TranslationPanelPresenter.panelSize
        }
        presenter.onClose = { [weak self] in self?.handleSurfaceClosed() }
        return presenter
    }()

    init(
        settingsStore: SettingsStore,
        localization: LocalizationStore,
        dependencies: Dependencies? = nil
    ) {
        let dependencies = dependencies ?? .production
        self.settingsStore = settingsStore
        self.localization = localization
        credentialStore = dependencies.credentialStore
        platformCapability = dependencies.platformCapability
        capture = dependencies.capture
        hotKeyRegistrar = dependencies.hotKeyRegistrar
        panelPresenterFactory = dependencies.panelPresenter
        disclosure = TranslationDisclosureController(
            settingsStore: settingsStore,
            localization: localization,
            prompt: dependencies.disclosurePrompt
        )
        let speech = dependencies.speech ?? TranslationSpeechController()
        self.speech = speech

        let appleComponents = Self.makeAppleComponents(platformCapability: dependencies.platformCapability)
        appleProvider = appleComponents.provider
        appleSessionHost = appleComponents.sessionHost
        var initialProviders = Self.makeCloudProviders(
            options: settingsStore.settings.translation,
            credentialStore: dependencies.credentialStore
        )
        initialProviders[.apple] = appleComponents.provider
        registry.replace(with: initialProviders)
        let configured = Self.configuredCloudProviders(in: dependencies.credentialStore)
        let providerID = Self.resolveProvider(
            options: settingsStore.settings.translation,
            platformCapability: dependencies.platformCapability,
            configuredCloudProviders: configured
        )
        let registry = registry
        let disclosure = disclosure
        model = TranslationModel(
            inputLanguage: settingsStore.settings.input.language,
            providerID: providerID,
            providerLookup: { registry.provider(for: $0) },
            requestsDisclosure: { disclosure.request(for: $0) },
            onPronunciationUnsupportedProvider: { speech.stopSpeaking() }
        )
        model.setSourceLanguage(settingsStore.settings.translation.defaultSourceLanguage)

        settingsModel = TranslationSettingsModel(
            settingsStore: settingsStore,
            platformCapability: dependencies.platformCapability,
            credentialStore: dependencies.credentialStore,
            shortcutRegistrationState: .unregistered,
            shortcutApplier: { _ in .unregistered }
        )
        settingsModel.onCredentialsChange = { [weak self] in self?.refreshProviders() }
        settingsModel.shortcutApplier = { [weak self] shortcut in
            self?.applyShortcut(shortcut) ?? .unregistered
        }
        settingsModel.onEnabledChange = { [weak self] in
            guard let self else { return }
            applyEnabledState(settingsStore.settings.translation)
            onConfigurationChange?()
        }
    }

    var availableProviders: [TranslationProviderID] {
        TranslationProviderResolver.availableProviders(
            platformCapability: platformCapability,
            configuredCloudProviders: Self.configuredCloudProviders(in: credentialStore)
        )
    }

    var hotKeyRegistrationState: TranslationHotKeyRegistrationState {
        hotKeyController.registrationState
    }

    func start() {
        guard !isStarted else { return }
        isStarted = true
        apply(settingsStore.settings)
    }

    func stop() {
        guard isStarted else { return }
        isStarted = false
        model.cancelActiveTranslation()
        speech.stopSpeaking()
        panelPresenter.close()
        hotKeyController.unregister()
        settingsModel.publishRegistrationState(.unregistered)
    }

    func apply(_ settings: EasyKeySettings) {
        refreshProviders(options: settings.translation)
        model.setAutoTranslateDelay(TimeInterval(settings.translation.autoTranslateDelayMs) / 1000.0)
        model.setSourceLanguage(settings.translation.defaultSourceLanguage)
        applyEnabledState(settings.translation)
        applyDoubleCmdCState(settings.translation)
    }

    func applyActivationSettings(_ options: TranslationOptions) {
        applyEnabledState(options)
        applyDoubleCmdCState(options)
    }

    private func applyDoubleCmdCState(_ options: TranslationOptions) {
        setDoubleCmdCEnabled(
            windowMs: options.cmdCDoublePressWindowMs,
            enabled: options.isEnabled && options.cmdCDoublePressEnabled
        )
    }

    func makePopoverConfiguration(openSettings: @escaping () -> Void) -> MenuPopoverTranslationConfiguration? {
        makePopoverConfiguration(
            options: settingsStore.settings.translation,
            openSettings: openSettings
        )
    }

    func makePopoverConfiguration(options: TranslationOptions, openSettings: @escaping () -> Void) -> MenuPopoverTranslationConfiguration? {
        guard options.isEnabled,
              options.showInMenuPopover
        else { return nil }
        return MenuPopoverTranslationConfiguration(
            model: model,
            availableProviders: availableProviders,
            platformCapability: platformCapability,
            sessionHost: appleSessionHost,
            actions: MenuPopoverTranslationActions(openSettings: openSettings)
        )
    }

    /// Invoked by the coordinator when the menu-bar popover closes. Applies the
    /// same session-persistence policy as the floating panel's own close.
    func handleMenuPopoverClosed() {
        handleSurfaceClosed()
    }

    private func handleSurfaceClosed() {
        guard settingsStore.settings.translation.sessionPersistence == .clearOnClose else { return }
        model.clearSession()
    }

    private func applyShortcut(_ shortcut: Shortcut) -> TranslationHotKeyRegistrationState {
        guard isStarted, settingsStore.settings.translation.isEnabled else { return .unregistered }
        _ = hotKeyController.apply(shortcut)
        return hotKeyController.registrationState
    }

    private func activateFromShortcut() {
        activate()
    }

    func activateFromDoubleCmdC() {
        activate()
    }

    private func activate() {
        guard settingsStore.settings.translation.isEnabled else { return }
        onWillActivate?()
        model.setAutoTranslateDelay(
            TimeInterval(settingsStore.settings.translation.autoTranslateDelayMs) / 1000.0
        )
        let captured = capture.capture()
        model.setSourceText(captured.text)
        model.scheduleAutoTranslate()
        panelPresenter.show(previousApplication: capture.previousApplication)
    }

    func setDoubleCmdCEnabled(windowMs: Int, enabled: Bool) {
        onDoubleCmdCChange?(windowMs, enabled)
    }

    var onDoubleCmdCChange: ((_ windowMs: Int, _ enabled: Bool) -> Void)?

    private func applyEnabledState(_ options: TranslationOptions) {
        guard isStarted else {
            settingsModel.publishRegistrationState(.unregistered)
            return
        }
        guard options.isEnabled else {
            hotKeyController.unregister()
            model.cancelActiveTranslation()
            speech.stopSpeaking()
            panelPresenter.close()
            settingsModel.publishRegistrationState(.unregistered)
            return
        }
        _ = hotKeyController.apply(options.shortcut)
        settingsModel.publishRegistrationState(hotKeyController.registrationState)
    }

    private func refreshProviders() {
        refreshProviders(options: settingsStore.settings.translation)
        settingsModel.refreshCredentialStatuses()
    }

    private func refreshProviders(options: TranslationOptions) {
        var providers = Self.makeCloudProviders(
            options: options,
            credentialStore: credentialStore
        )
        providers[.apple] = appleProvider
        registry.replace(with: providers)
        providerRevision &+= 1
        let resolvedProvider = Self.resolveProvider(
            options: options,
            platformCapability: platformCapability,
            configuredCloudProviders: Self.configuredCloudProviders(in: credentialStore)
        )
        if resolvedProvider == model.providerID,
           let resolvedProvider,
           !TranslationPronunciationPolicy.supports(resolvedProvider) {
            speech.stopSpeaking()
        }
        model.setProviderID(resolvedProvider)
        onConfigurationChange?()
    }

    private func panelContent() -> AnyView {
        AnyView(
            ZStack {
                TranslationPanelView(
                    model: model,
                    speech: speech,
                    localization: localization,
                    availableProviders: availableProviders,
                    shortcut: settingsStore.settings.translation.shortcut,
                    actions: TranslationPanelActions(openSettings: { [weak self] in
                        self?.panelPresenter.close()
                        self?.onOpenSettings?()
                    })
                )
                appleSessionHost
            }
        )
    }

    var onOpenSettings: (() -> Void)?

    private static func configuredCloudProviders(
        in credentialStore: TranslationCredentialStoring
    ) -> Set<TranslationProviderID> {
        Set(TranslationProviderResolver.cloudProviderOrder.filter {
            (try? credentialStore.hasCredential(for: $0)) == true
        })
    }

    private static func resolveProvider(
        options: TranslationOptions,
        platformCapability: TranslationPlatformCapability,
        configuredCloudProviders: Set<TranslationProviderID>
    ) -> TranslationProviderID? {
        switch TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: options.preferredProviderID,
            platformCapability: platformCapability,
            configuredCloudProviders: configuredCloudProviders
        ) {
        case let .resolved(provider): provider
        case .setupRequired: nil
        }
    }

    private static func makeCloudProviders(
        options: TranslationOptions,
        credentialStore: TranslationCredentialStoring
    ) -> [TranslationProviderID: TranslationProviding] {
        var providers: [TranslationProviderID: TranslationProviding] = [
            .deepL: DeepLTranslationProvider(endpoint: options.deepLEndpoint, credentialStore: credentialStore),
            .google: GoogleTranslationProvider(credentialStore: credentialStore),
            .openAI: OpenAITranslationProvider(options: options, credentialStore: credentialStore),
            .anthropic: AnthropicTranslationProvider(options: options, credentialStore: credentialStore),
            .gemini: GeminiTranslationProvider(options: options, credentialStore: credentialStore),
        ]
        if let openRouterURL = URL(string: "https://openrouter.ai/api/v1/chat/completions") {
            providers[.openRouter] = OpenAICompatibleTranslationProvider(
                endpoint: openRouterURL,
                providerID: .openRouter,
                modelIdentifier: options.openRouterModelIdentifier,
                credentialStore: credentialStore
            )
        }
        if let groqURL = URL(string: "https://api.groq.com/openai/v1/chat/completions") {
            providers[.groq] = OpenAICompatibleTranslationProvider(
                endpoint: groqURL,
                providerID: .groq,
                modelIdentifier: options.groqModelIdentifier,
                credentialStore: credentialStore
            )
        }
        if let compatibleEndpoint = ValidatedTranslationEndpoint(options.openAICompatibleEndpoint) {
            providers[.openAICompatible] = OpenAICompatibleTranslationProvider(
                endpoint: compatibleEndpoint.url,
                providerID: .openAICompatible,
                modelIdentifier: options.openAICompatibleModelIdentifier,
                credentialStore: credentialStore
            )
        }
        if let compatibleEndpoint = ValidatedTranslationEndpoint(options.anthropicCompatibleEndpoint) {
            providers[.anthropicCompatible] = AnthropicCompatibleTranslationProvider(
                endpoint: compatibleEndpoint.url,
                providerID: .anthropicCompatible,
                modelIdentifier: options.anthropicCompatibleModelIdentifier,
                credentialStore: credentialStore
            )
        }
        return providers
    }

    private static func makeAppleComponents(
        platformCapability: TranslationPlatformCapability
    ) -> (provider: TranslationProviding?, sessionHost: AnyView?) {
        if platformCapability.supportsAppleTranslation {
            if #available(macOS 15.0, *) {
                let bridge = AppleTranslationSessionBridge()
                return (
                    AppleTranslationProvider(bridge: bridge),
                    AnyView(AppleTranslationSessionHostView(bridge: bridge))
                )
            }
        }
        return (nil, nil)
    }
}
