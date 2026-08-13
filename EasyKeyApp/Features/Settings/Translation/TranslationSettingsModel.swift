import Combine
import EasyEngineCore
import Foundation

@MainActor
final class TranslationSettingsModel: ObservableObject {
    typealias ShortcutApplier = @MainActor (Shortcut) -> TranslationHotKeyRegistrationState

    static let cloudProviders = TranslationProviderResolver.cloudProviderOrder
    static let maximumModelIdentifierLength = 100

    enum ModelCatalogState: Equatable {
        case idle
        case loading
        case loaded([TranslationModelCatalogEntry])
        case failed
    }

    @Published private(set) var credentialStatuses: [TranslationProviderID: TranslationCredentialStatus] = [:]
    @Published private(set) var storedCredentialProviders: Set<TranslationProviderID> = []
    @Published private(set) var shortcutRegistrationState: TranslationHotKeyRegistrationState
    @Published private(set) var lastCredentialErrorProvider: TranslationProviderID?
    @Published private(set) var modelCatalogStates: [TranslationProviderID: ModelCatalogState] = [:]

    let platformCapability: TranslationPlatformCapability
    private let settingsStore: SettingsStore
    private let credentialStore: TranslationCredentialStoring
    private let credentialValidator: TranslationCredentialValidating
    let modelCatalog: TranslationModelCatalogProviding
    private var catalogGenerations: [TranslationProviderID: UInt64] = [:]
    private var catalogTasks: [TranslationProviderID: Task<Void, Never>] = [:]
    private var validationTask: Task<Void, Never>?
    private var validationGeneration: UInt64 = 0
    var shortcutApplier: ShortcutApplier?
    var onCredentialsChange: (() -> Void)?
    var onEnabledChange: (() -> Void)?
    var onCmdCDoublePressChanged: (() -> Void)?

    init(
        settingsStore: SettingsStore,
        platformCapability: TranslationPlatformCapability,
        credentialStore: TranslationCredentialStoring = KeychainTranslationCredentialStore(),
        credentialValidator: TranslationCredentialValidating? = nil,
        modelCatalog: TranslationModelCatalogProviding? = nil,
        shortcutRegistrationState: TranslationHotKeyRegistrationState? = nil,
        shortcutApplier: ShortcutApplier? = nil
    ) {
        self.settingsStore = settingsStore
        self.platformCapability = platformCapability
        self.credentialStore = credentialStore
        self.credentialValidator = credentialValidator ?? LiveTranslationCredentialValidator()
        self.modelCatalog = modelCatalog ?? LiveTranslationModelCatalog(credentialStore: credentialStore)
        self.shortcutApplier = shortcutApplier
        self.shortcutRegistrationState = shortcutRegistrationState
            ?? (settingsStore.settings.translation.shortcut.isActive
                ? .registered(settingsStore.settings.translation.shortcut)
                : .unregistered)
        refreshCredentialStatuses()
    }

    convenience init(settingsStore: SettingsStore) {
        let capability: TranslationPlatformCapability
        if #available(macOS 15.0, *) {
            capability = TranslationPlatformCapability(supportsAppleTranslation: true)
        } else {
            capability = TranslationPlatformCapability(supportsAppleTranslation: false)
        }
        self.init(settingsStore: settingsStore, platformCapability: capability)
    }

    var selectableProviders: [TranslationProviderID] {
        var providers: [TranslationProviderID] = []
        if platformCapability.supportsAppleTranslation {
            providers.append(.apple)
        }
        providers.append(contentsOf: Self.cloudProviders)
        return providers
    }

    var visibleProviderCards: [TranslationProviderID] {
        var providers: [TranslationProviderID] = []
        if platformCapability.supportsAppleTranslation {
            providers.append(.apple)
        }
        providers.append(contentsOf: Self.cloudProviders)
        return providers
    }

    var preferredProvider: TranslationProviderID {
        let saved = settingsStore.settings.translation.preferredProviderID ?? .apple
        return selectableProviders.contains(saved) ? saved : .apple
    }

    var effectiveProvider: TranslationProviderID? {
        switch TranslationProviderResolver.resolveEffectiveProvider(
            preferredProviderID: settingsStore.settings.translation.preferredProviderID,
            platformCapability: platformCapability,
            configuredCloudProviders: storedCredentialProviders
        ) {
        case let .resolved(provider): provider
        case .setupRequired: nil
        }
    }

    var defaultSourceLanguage: TranslationLanguage? {
        settingsStore.settings.translation.defaultSourceLanguage
    }

    var shortcut: Shortcut {
        settingsStore.settings.translation.shortcut
    }

    var deepLEndpoint: TranslationOptions.DeepLEndpoint {
        settingsStore.settings.translation.deepLEndpoint
    }

    var isEnabled: Bool {
        settingsStore.settings.translation.isEnabled
    }

    var showInMenuPopover: Bool {
        settingsStore.settings.translation.showInMenuPopover
    }

    var cmdCDoublePressEnabled: Bool {
        settingsStore.settings.translation.cmdCDoublePressEnabled
    }

    var cmdCDoublePressWindowMs: Int {
        settingsStore.settings.translation.cmdCDoublePressWindowMs
    }

    var autoTranslateDelayMs: Int {
        settingsStore.settings.translation.autoTranslateDelayMs
    }

    var panelSize: TranslationOptions.PanelSize {
        settingsStore.settings.translation.panelSize
    }

    var sessionPersistence: TranslationOptions.SessionPersistence {
        settingsStore.settings.translation.sessionPersistence
    }

    var acknowledgedDisclosureProviders: Set<TranslationProviderID> {
        settingsStore.settings.translation.acknowledgedCloudDisclosureProviders
    }

    func modelIdentifier(for provider: TranslationProviderID) -> String? {
        switch provider {
        case .openAI: settingsStore.settings.translation.openAIModelIdentifier
        case .anthropic: settingsStore.settings.translation.anthropicModelIdentifier
        case .gemini: settingsStore.settings.translation.geminiModelIdentifier
        case .openRouter: settingsStore.settings.translation.openRouterModelIdentifier
        case .groq: settingsStore.settings.translation.groqModelIdentifier
        case .openAICompatible: settingsStore.settings.translation.openAICompatibleModelIdentifier
        case .anthropicCompatible: settingsStore.settings.translation.anthropicCompatibleModelIdentifier
        case .automatic, .apple, .deepL, .google: nil
        }
    }

    func availability(of provider: TranslationProviderID) -> TranslationProviderAvailability {
        TranslationProviderResolver.availability(
            of: provider,
            platformCapability: platformCapability,
            configuredCloudProviders: storedCredentialProviders
        )
    }

    func setPreferredProvider(_ provider: TranslationProviderID) {
        guard selectableProviders.contains(provider) else { return }
        settingsStore.update { $0.translation.preferredProviderID = provider }
        objectWillChange.send()
    }

    func setDefaultSourceLanguage(_ language: TranslationLanguage?) {
        guard language == nil || language.map(SupportedLanguages.contains) == true else { return }
        settingsStore.update { $0.translation.defaultSourceLanguage = language }
        objectWillChange.send()
    }

    func setShortcut(_ shortcut: Shortcut) {
        settingsStore.update { $0.translation.shortcut = shortcut }
        shortcutRegistrationState = shortcutApplier?(shortcut)
            ?? (shortcut.isActive ? .registered(shortcut) : .unregistered)
    }

    func publishRegistrationState(_ state: TranslationHotKeyRegistrationState) {
        shortcutRegistrationState = state
        objectWillChange.send()
    }

    func setDeepLEndpoint(_ endpoint: TranslationOptions.DeepLEndpoint) {
        settingsStore.update { $0.translation.deepLEndpoint = endpoint }
        if credentialStatuses[.deepL] == .ready {
            credentialStatuses[.deepL] = .saved
        }
        objectWillChange.send()
    }

    func setIsEnabled(_ value: Bool) {
        settingsStore.update { $0.translation.isEnabled = value }
        objectWillChange.send()
        onEnabledChange?()
    }

    func setShowInMenuPopover(_ value: Bool) {
        settingsStore.update { $0.translation.showInMenuPopover = value }
        objectWillChange.send()
    }

    func setCmdCDoublePressEnabled(_ value: Bool) {
        settingsStore.update { $0.translation.cmdCDoublePressEnabled = value }
        objectWillChange.send()
        onCmdCDoublePressChanged?()
    }

    func setCmdCDoublePressWindowMs(_ value: Int) {
        settingsStore.update { $0.translation.cmdCDoublePressWindowMs = value }
        objectWillChange.send()
        onCmdCDoublePressChanged?()
    }

    func setAutoTranslateDelayMs(_ value: Int) {
        guard TranslationOptions.AutoTranslateDelayPreset(rawValue: value) != nil else { return }
        settingsStore.update { $0.translation.autoTranslateDelayMs = value }
        objectWillChange.send()
    }

    func setPanelSize(_ value: TranslationOptions.PanelSize) {
        settingsStore.update { $0.translation.panelSize = value }
        objectWillChange.send()
    }

    func setSessionPersistence(_ value: TranslationOptions.SessionPersistence) {
        settingsStore.update { $0.translation.sessionPersistence = value }
        objectWillChange.send()
    }

    func openAICompatibleEndpoint() -> String {
        settingsStore.settings.translation.openAICompatibleEndpoint
    }

    func setOpenAICompatibleEndpoint(_ value: String) {
        settingsStore.update { $0.translation.openAICompatibleEndpoint = value.trimmingCharacters(in: .whitespacesAndNewlines) }
        objectWillChange.send()
    }

    func anthropicCompatibleEndpoint() -> String {
        settingsStore.settings.translation.anthropicCompatibleEndpoint
    }

    func setAnthropicCompatibleEndpoint(_ value: String) {
        settingsStore.update { $0.translation.anthropicCompatibleEndpoint = value.trimmingCharacters(in: .whitespacesAndNewlines) }
        objectWillChange.send()
    }

    func canManageModels(for provider: TranslationProviderID) -> Bool {
        switch credentialStatuses[provider] {
        case .saved, .ready: return true
        default: return provider == .openRouter
        }
    }

    @discardableResult
    func setModelIdentifier(_ value: String, for provider: TranslationProviderID) -> Bool {
        guard canManageModels(for: provider) else { return false }
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard Self.isValidModelIdentifier(trimmed, for: provider) else { return false }
        settingsStore.update {
            switch provider {
            case .openAI: $0.translation.openAIModelIdentifier = trimmed
            case .anthropic: $0.translation.anthropicModelIdentifier = trimmed
            case .gemini: $0.translation.geminiModelIdentifier = trimmed
            case .openRouter: $0.translation.openRouterModelIdentifier = trimmed
            case .groq: $0.translation.groqModelIdentifier = trimmed
            case .openAICompatible: $0.translation.openAICompatibleModelIdentifier = trimmed
            case .anthropicCompatible: $0.translation.anthropicCompatibleModelIdentifier = trimmed
            case .automatic, .apple, .deepL, .google: return
            }
        }
        objectWillChange.send()
        return true
    }

    /// Paste often leaves BOM / zero-width / trailing newlines that make API auth fail.
    static func sanitizedCredential(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\u{FEFF}", with: "")
            .replacingOccurrences(of: "\u{200B}", with: "")
            .replacingOccurrences(of: "\u{200C}", with: "")
            .replacingOccurrences(of: "\u{200D}", with: "")
            .replacingOccurrences(of: "\u{2060}", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    @discardableResult
    func saveCredential(_ credential: String, for provider: TranslationProviderID) -> Bool {
        guard Self.cloudProviders.contains(provider) else { return false }
        let sanitized = Self.sanitizedCredential(credential)
        guard !sanitized.isEmpty else {
            lastCredentialErrorProvider = provider
            return false
        }
        do {
            try credentialStore.save(sanitized, for: provider)
            storedCredentialProviders.insert(provider)
            credentialStatuses[provider] = .saved
            lastCredentialErrorProvider = nil
            onCredentialsChange?()
            loadModelCatalog(for: provider)
            return true
        } catch {
            AppLog.error(.translation, "Failed to save credential for \(provider.rawValue): \(error)")
            lastCredentialErrorProvider = provider
            return false
        }
    }

    @discardableResult
    func validateCredential(_ credential: String, for provider: TranslationProviderID) async -> Bool {
        guard Self.cloudProviders.contains(provider) else { return false }
        let trimmed = Self.sanitizedCredential(credential)
        guard !trimmed.isEmpty else {
            lastCredentialErrorProvider = provider
            return false
        }
        credentialStatuses[provider] = .validating
        do {
            let valid = try await credentialValidator.validate(
                trimmed,
                for: provider,
                options: settingsStore.settings.translation
            )
            guard valid else {
                credentialStatuses[provider] = .invalid
                lastCredentialErrorProvider = provider
                return false
            }
            try credentialStore.save(trimmed, for: provider)
            storedCredentialProviders.insert(provider)
            credentialStatuses[provider] = .ready
            lastCredentialErrorProvider = nil
            onCredentialsChange?()
            loadModelCatalog(for: provider)
            return true
        } catch {
            AppLog.error(.translation, "Failed to validate credential for \(provider.rawValue): \(error)")
            credentialStatuses[provider] = .invalid
            lastCredentialErrorProvider = provider
            return false
        }
    }

    func deleteCredential(for provider: TranslationProviderID) {
        do {
            try credentialStore.deleteCredential(for: provider)
            storedCredentialProviders.remove(provider)
            credentialStatuses[provider] = .missing
            lastCredentialErrorProvider = nil
            modelCatalogStates[provider] = .idle
            onCredentialsChange?()
        } catch {
            AppLog.error(.translation, "Failed to delete credential for \(provider.rawValue): \(error)")
            lastCredentialErrorProvider = provider
        }
    }

    func resetCloudDisclosures() {
        settingsStore.update { $0.translation.acknowledgedCloudDisclosureProviders.removeAll() }
        objectWillChange.send()
    }

    func refreshCredentialStatuses() {
        for provider in Self.cloudProviders {
            do {
                credentialStatuses[provider] = try credentialStore.status(for: provider)
                if credentialStatuses[provider] == .saved {
                    storedCredentialProviders.insert(provider)
                } else {
                    storedCredentialProviders.remove(provider)
                }
            } catch {
                AppLog.error(.translation, "Failed to read credential status for \(provider.rawValue): \(error)")
                credentialStatuses[provider] = .invalid
                lastCredentialErrorProvider = provider
            }
        }
    }

    func loadModelCatalog(for provider: TranslationProviderID) {
        guard provider.isOfficialAIModelProvider,
              credentialStatuses[provider] == .saved || credentialStatuses[provider] == .ready || provider == .openRouter
        else { return }
        cancelModelCatalogLoad(for: provider)
        modelCatalogStates[provider] = .loading
        let catalog = modelCatalog
        catalogTasks[provider] = Task { [weak self] in
            let entries: [TranslationModelCatalogEntry]
            do {
                entries = try await catalog.fetchModels(for: provider)
            } catch {
                await MainActor.run {
                    self?.modelCatalogStates[provider] = .failed
                }
                return
            }
            let currentID = self?.modelIdentifier(for: provider)
            var merged = entries
            if let currentID,
               !merged.contains(where: { $0.identifier == currentID }) {
                merged.append(TranslationModelCatalogEntry(identifier: currentID, displayName: currentID))
            }
            await MainActor.run {
                self?.modelCatalogStates[provider] = .loaded(merged)
            }
        }
    }

    static func isValidModelIdentifier(_ identifier: String, for provider: TranslationProviderID) -> Bool {
        let length = identifier.utf8.count
        guard (1 ... maximumModelIdentifierLength).contains(length) else { return false }
        var allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-._"))
        if provider.allowsPathSeparatorInModelID {
            allowed.insert(charactersIn: "/:")
        }
        return identifier.unicodeScalars.allSatisfy(allowed.contains)
    }

    func cancelModelCatalogLoad(for provider: TranslationProviderID) {
        catalogTasks[provider]?.cancel()
        catalogTasks[provider] = nil
        catalogGenerations[provider] = (catalogGenerations[provider] ?? 0) &+ 1
    }
}

extension TranslationProviderID {
    var allowsPathSeparatorInModelID: Bool {
        switch self {
        case .openRouter, .groq, .openAICompatible, .anthropicCompatible: true
        default: false
        }
    }

    var isOfficialAIModelProvider: Bool {
        switch self {
        case .openAI, .anthropic, .gemini, .openRouter, .groq: true
        default: false
        }
    }
}
