import AppKit
import EasyEngineCore
import SwiftUI

enum TranslationSettingsAccessibility {
    static let enableToggle = "TranslationEnableToggle"
    static let providerPicker = "TranslationDefaultProviderPicker"
    static let sourcePicker = "TranslationSourcePreferencePicker"
    static let deepLPlanPicker = "TranslationDeepLPlanPicker"
    static let shortcutStatus = "TranslationShortcutStatus"
    static let disclosureReset = "TranslationDisclosureReset"
    static let appleLanguageSettings = "TranslationAppleLanguageSettings"

    static func credentialField(_ provider: TranslationProviderID) -> String {
        "TranslationCredential-\(provider.rawValue)"
    }
}

struct TranslationSettingsView: View {
    @ObservedObject var model: TranslationSettingsModel
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var showDisclosureResetConfirmation = false

    var body: some View {
        Form {
            Section {
                Toggle(localization.string(.translationEnableTranslation), isOn: enableBinding)
                    .accessibilityIdentifier(TranslationSettingsAccessibility.enableToggle)

                Toggle(localization.string(.translationMenuPopoverVisibility), isOn: menuPopoverBinding)
                    .accessibilityIdentifier("TranslationMenuPopoverToggle")

                Picker(localization.string(.translationSettingsDefaultProvider), selection: preferredProviderBinding) {
                    ForEach(model.selectableProviders, id: \.self) { provider in
                        Text(providerName(provider)).tag(provider)
                    }
                }
                .accessibilityLabel(localization.string(.translationSettingsDefaultProvider))
                .accessibilityIdentifier(TranslationSettingsAccessibility.providerPicker)

                Picker(localization.string(.translationSettingsSourcePreference), selection: sourceLanguageBinding) {
                    Text(localization.string(.translationDetectLanguage)).tag(nil as TranslationLanguage?)
                    ForEach(SupportedLanguages.all, id: \.self) { language in
                        Text(languageName(language)).tag(Optional(language))
                    }
                }
                .accessibilityLabel(localization.string(.translationSettingsSourcePreference))
                .accessibilityIdentifier(TranslationSettingsAccessibility.sourcePicker)

                Text(localization.string(.translationSettingsOppositeTarget))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Picker(localization.string(.translationSettingsAutoTranslateDelay), selection: autoTranslateDelayBinding) {
                    ForEach(TranslationOptions.AutoTranslateDelayPreset.allCases, id: \.self) { preset in
                        Text(delayLabel(preset)).tag(preset.rawValue)
                    }
                }
                .accessibilityLabel(localization.string(.translationSettingsAutoTranslateDelay))
                .accessibilityIdentifier("TranslationAutoTranslateDelayPicker")

                ShortcutRecorder(
                    label: localization.string(.translationSettingsShortcut),
                    description: localization.string(.translationSettingsShortcutDescription),
                    shortcut: shortcutBinding
                )
                shortcutStatus
            } header: {
                Text(localization.string(.translationSettingsGeneral))
            }

            Section {
                ForEach(model.visibleProviderCards, id: \.self) { provider in
                    if provider == .apple {
                        AppleTranslationSettingsCard(providerName: providerName(provider))
                    } else {
                        CloudTranslationSettingsCard(
                            provider: provider,
                            providerName: providerName(provider),
                            model: model
                        )
                    }
                }
            } header: {
                Text(localization.string(.translationSettingsProviders))
            } footer: {
                Text(localization.string(.translationSettingsCloudCosts))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Section {
                Button(localization.string(.translationSettingsResetDisclosures), role: .destructive) {
                    showDisclosureResetConfirmation = true
                }
                .disabled(model.acknowledgedDisclosureProviders.isEmpty)
                .accessibilityIdentifier(TranslationSettingsAccessibility.disclosureReset)
            } header: {
                Text(localization.string(.translationSettingsPrivacy))
            } footer: {
                Text(localization.string(.translationSettingsResetDisclosuresDescription))
            }
        }
        .formStyle(.grouped)
        .alert(localization.string(.translationSettingsResetDisclosuresConfirmTitle), isPresented: $showDisclosureResetConfirmation) {
            Button(localization.string(.commonCancel), role: .cancel) {}
            Button(localization.string(.commonReset), role: .destructive) { model.resetCloudDisclosures() }
        } message: {
            Text(localization.string(.translationSettingsResetDisclosuresConfirmMessage))
        }
    }

    private var shortcutStatus: some View {
        Group {
            switch model.shortcutRegistrationState {
            case .unregistered:
                Label(localization.string(.translationSettingsShortcutOff), systemImage: "minus.circle")
                    .foregroundStyle(.secondary)
            case .registered:
                Label(localization.string(.translationSettingsShortcutReady), systemImage: "checkmark.circle.fill")
                    .foregroundStyle(.secondary)
            case .conflict:
                Label(localization.string(.translationSettingsShortcutConflict), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityIdentifier(TranslationSettingsAccessibility.shortcutStatus)
    }

    private var preferredProviderBinding: Binding<TranslationProviderID> {
        Binding(get: { model.preferredProvider }, set: model.setPreferredProvider)
    }

    private var enableBinding: Binding<Bool> {
        Binding(get: { model.isEnabled }, set: model.setIsEnabled)
    }

    private var sourceLanguageBinding: Binding<TranslationLanguage?> {
        Binding(get: { model.defaultSourceLanguage }, set: model.setDefaultSourceLanguage)
    }

    private var menuPopoverBinding: Binding<Bool> {
        Binding(get: { model.showInMenuPopover }, set: model.setShowInMenuPopover)
    }

    private var autoTranslateDelayBinding: Binding<Int> {
        Binding(get: { model.autoTranslateDelayMs }, set: model.setAutoTranslateDelayMs)
    }

    private var shortcutBinding: Binding<Shortcut> {
        Binding(get: { model.shortcut }, set: model.setShortcut)
    }

    private func providerName(_ provider: TranslationProviderID) -> String {
        provider == .automatic ? localization.string(.translationProviderAutomatic) : provider.displayName
    }

    private func languageName(_ language: TranslationLanguage) -> String {
        localization.locale.localizedString(forIdentifier: language.identifier) ?? language.identifier
    }

    private func delayLabel(_ preset: TranslationOptions.AutoTranslateDelayPreset) -> String {
        let ms = preset.rawValue
        if ms >= 1000 {
            let seconds = Double(ms) / 1000.0
            let formatted = seconds.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", seconds)
                : String(format: "%.1f", seconds)
            return localization.format(.translationSettingsDelaySeconds, formatted)
        }
        return localization.format(.translationSettingsDelayMilliseconds, String(ms))
    }
}

private struct AppleTranslationSettingsCard: View {
    let providerName: String
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TranslationProviderIcon(provider: .apple, size: 18)
                Text(providerName).font(.headline)
            }
            Text(localization.string(.translationSettingsAppleLocal))
                .font(.caption)
                .foregroundStyle(.secondary)
            Button {
                openLanguageSettings()
            } label: {
                Label(localization.string(.translationSettingsManageAppleLanguages), systemImage: "arrow.up.forward.app")
            }
            .accessibilityIdentifier(TranslationSettingsAccessibility.appleLanguageSettings)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 4)
    }

    private func openLanguageSettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.Localization-Settings.extension") else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct CloudTranslationSettingsCard: View {
    let provider: TranslationProviderID
    let providerName: String
    @ObservedObject var model: TranslationSettingsModel
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var credential = ""
    @State private var modelIdentifier = ""
    @State private var modelIdentifierIsInvalid = false
    @State private var endpointURL = ""
    @State private var showDeleteConfirmation = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                TranslationProviderIcon(provider: provider, size: 18)
                Text(providerName).font(.headline)
                Spacer()
                statusLabel
            }

            Text(localization.format(.translationSettingsCloudProviderWarning, providerName))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let privacyURL = provider.privacyURL {
                Link(localization.format(.translationSettingsProviderDataHandling, providerName), destination: privacyURL)
                    .font(.caption)
                    .accessibilityIdentifier("TranslationProviderPrivacy-\(provider.rawValue)")
            }

            if provider == .deepL {
                Picker(localization.string(.translationSettingsDeepLPlan), selection: deepLEndpointBinding) {
                    Text(localization.string(.translationSettingsDeepLFree)).tag(TranslationOptions.DeepLEndpoint.free)
                    Text(localization.string(.translationSettingsDeepLPro)).tag(TranslationOptions.DeepLEndpoint.pro)
                }
                .accessibilityLabel(localization.string(.translationSettingsDeepLPlan))
                .accessibilityIdentifier(TranslationSettingsAccessibility.deepLPlanPicker)
            }

            if model.modelIdentifier(for: provider) != nil {
                TextField(localization.string(.translationSettingsModel), text: $modelIdentifier)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveModelIdentifier)
                    .accessibilityLabel("\(providerName): \(localization.string(.translationSettingsModel))")
                    .accessibilityHint(localization.string(.translationSettingsModelHint))
                if modelIdentifierIsInvalid {
                    Text(localization.string(.translationSettingsModelInvalid))
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }

            if provider == .openAICompatible || provider == .anthropicCompatible {
                TextField(localization.string(.translationSettingsEndpoint), text: $endpointURL)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit(saveEndpoint)
                    .accessibilityLabel("\(providerName): \(localization.string(.translationSettingsEndpoint))")
                    .accessibilityHint(localization.string(.translationSettingsEndpointHint))
            }

            SecureField(localization.string(.translationSettingsApiKey), text: $credential)
                .textFieldStyle(.roundedBorder)
                .onSubmit(saveCredential)
                .accessibilityLabel(localization.format(.translationSettingsApiKeyA11y, providerName))
                .accessibilityIdentifier(TranslationSettingsAccessibility.credentialField(provider))

            HStack {
                Button(localization.string(.commonSave), action: saveCredential)
                    .buttonStyle(.borderedProminent)
                    .disabled(credential.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .accessibilityLabel(credentialActionLabel(.commonSave))
                Button(localization.string(.translationSettingsValidate)) {
                    Task {
                        if await model.validateCredential(credential, for: provider) {
                            credential = ""
                        }
                    }
                }
                .disabled(credential.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || status == .validating)
                .accessibilityLabel(credentialActionLabel(.translationSettingsValidate))
                if model.storedCredentialProviders.contains(provider) {
                    Button(localization.string(.translationSettingsDeleteKey), role: .destructive) {
                        showDeleteConfirmation = true
                    }
                    .accessibilityLabel(credentialActionLabel(.translationSettingsDeleteKey))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 6)
        .onAppear {
            modelIdentifier = model.modelIdentifier(for: provider) ?? ""
            endpointURL = endpointValue()
        }
        .alert(localization.format(.translationSettingsDeleteKeyConfirmTitle, providerName), isPresented: $showDeleteConfirmation) {
            Button(localization.string(.commonCancel), role: .cancel) {}
            Button(localization.string(.translationSettingsDeleteKey), role: .destructive) {
                model.deleteCredential(for: provider)
                credential = ""
            }
        } message: {
            Text(localization.string(.translationSettingsDeleteKeyConfirmMessage))
        }
    }

    private var status: TranslationCredentialStatus {
        model.credentialStatuses[provider] ?? .missing
    }

    private var statusLabel: some View {
        let text: String
        let symbol: String
        switch status {
        case .missing:
            text = localization.string(.translationSettingsStatusMissing)
            symbol = "circle"
        case .saved:
            text = localization.string(.translationSettingsStatusSaved)
            symbol = "key.fill"
        case .validating:
            text = localization.string(.translationSettingsStatusValidating)
            symbol = "clock"
        case .ready:
            text = localization.string(.translationSettingsStatusReady)
            symbol = "checkmark.circle.fill"
        case .invalid:
            text = localization.string(.translationSettingsStatusInvalid)
            symbol = "exclamationmark.circle.fill"
        }
        return Label(text, systemImage: symbol)
            .font(.caption)
            .foregroundStyle(.secondary)
            .accessibilityElement(children: .combine)
            .accessibilityLabel(providerName)
            .accessibilityValue(text)
    }

    private var deepLEndpointBinding: Binding<TranslationOptions.DeepLEndpoint> {
        Binding(get: { model.deepLEndpoint }, set: model.setDeepLEndpoint)
    }

    private func endpointValue() -> String {
        switch provider {
        case .openAICompatible: model.openAICompatibleEndpoint()
        case .anthropicCompatible: model.anthropicCompatibleEndpoint()
        default: ""
        }
    }

    private func saveEndpoint() {
        switch provider {
        case .openAICompatible: model.setOpenAICompatibleEndpoint(endpointURL)
        case .anthropicCompatible: model.setAnthropicCompatibleEndpoint(endpointURL)
        default: break
        }
    }

    private func saveCredential() {
        if model.saveCredential(credential, for: provider) {
            credential = ""
        }
    }

    private func credentialActionLabel(_ action: L10nKey) -> String {
        "\(providerName): \(localization.string(action))"
    }

    private func saveModelIdentifier() {
        modelIdentifierIsInvalid = !model.setModelIdentifier(modelIdentifier, for: provider)
        if !modelIdentifierIsInvalid {
            modelIdentifier = model.modelIdentifier(for: provider) ?? ""
        }
    }
}
