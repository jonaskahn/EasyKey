import AppKit
import EasyEngineCore
import SwiftUI

enum TranslationSettingsAccessibility {
    static let enableToggle = "TranslationEnableToggle"
    static let sourcePicker = "TranslationSourcePreferencePicker"
    static let deepLPlanPicker = "TranslationDeepLPlanPicker"
    static let shortcutStatus = "TranslationShortcutStatus"
    static let disclosureReset = "TranslationDisclosureReset"
    static let appleLanguageSettings = "TranslationAppleLanguageSettings"
    static let panelSizePicker = "TranslationPanelSizePicker"
    static let sessionPersistencePicker = "TranslationSessionPersistencePicker"
    static let autoCaptureToggle = "TranslationAutoCaptureSelectedTextToggle"

    static func credentialField(_ provider: TranslationProviderID) -> String {
        "TranslationCredential-\(provider.rawValue)"
    }

    static func providerRow(_ provider: TranslationProviderID) -> String {
        "TranslationProvider-\(provider.rawValue)"
    }

    static func providerSelection(_ provider: TranslationProviderID) -> String {
        "TranslationProviderSelection-\(provider.rawValue)"
    }

    static func providerDisclosure(_ provider: TranslationProviderID) -> String {
        "TranslationProviderDisclosure-\(provider.rawValue)"
    }
}

struct TranslationSettingsView: View {
    @ObservedObject var model: TranslationSettingsModel
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var showDisclosureResetConfirmation = false
    @State private var expandedProvider: TranslationProviderID?

    init(model: TranslationSettingsModel) {
        self.model = model
        _expandedProvider = State(initialValue: nil)
    }

    var body: some View {
        Form {
            Section {
                Toggle(localization.string(.translationEnableTranslation), isOn: enableBinding)
                    .accessibilityIdentifier(TranslationSettingsAccessibility.enableToggle)

                Toggle(localization.string(.translationSettingsAutoCaptureSelectedText), isOn: autoCaptureSelectedTextBinding)
                    .accessibilityIdentifier(TranslationSettingsAccessibility.autoCaptureToggle)

                Text(localization.string(.translationSettingsAutoCaptureSelectedTextDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Toggle(localization.string(.translationMenuPopoverVisibility), isOn: menuPopoverBinding)
                    .accessibilityIdentifier("TranslationMenuPopoverToggle")

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
                Picker(localization.string(.translationSettingsPanelSize), selection: panelSizeBinding) {
                    ForEach(TranslationOptions.PanelSize.allCases, id: \.self) { size in
                        Text(panelSizeLabel(size)).tag(size)
                    }
                }
                .accessibilityLabel(localization.string(.translationSettingsPanelSize))
                .accessibilityIdentifier(TranslationSettingsAccessibility.panelSizePicker)

                Picker(localization.string(.translationSettingsSessionBehavior), selection: sessionPersistenceBinding) {
                    Text(localization.string(.translationSettingsSessionClearOnClose))
                        .tag(TranslationOptions.SessionPersistence.clearOnClose)
                    Text(localization.string(.translationSettingsSessionKeepUntilRestart))
                        .tag(TranslationOptions.SessionPersistence.keepUntilRestart)
                }
                .accessibilityLabel(localization.string(.translationSettingsSessionBehavior))
                .accessibilityIdentifier(TranslationSettingsAccessibility.sessionPersistencePicker)
            } header: {
                Text(localization.string(.translationSettingsDisplaySection))
            }

            Section {
                TranslationProviderSettings(
                    model: model,
                    expandedProvider: $expandedProvider,
                    providerName: providerName
                )
            } header: {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(localization.string(.translationSettingsProviders))
                        Spacer()
                        Text(localization.format(
                            .translationSettingsActiveProvider,
                            activeProviderName
                        ))
                        .foregroundStyle(.secondary)
                    }
                    Text(localization.string(.translationSettingsProvidersDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
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

    private var activeProviderName: String {
        guard let provider = model.effectiveProvider else {
            return localization.string(.translationChooseProvider)
        }
        return providerName(provider)
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

    private var autoCaptureSelectedTextBinding: Binding<Bool> {
        Binding(get: { model.autoCaptureSelectedText }, set: model.setAutoCaptureSelectedText)
    }

    private var autoTranslateDelayBinding: Binding<Int> {
        Binding(get: { model.autoTranslateDelayMs }, set: model.setAutoTranslateDelayMs)
    }

    private var panelSizeBinding: Binding<TranslationOptions.PanelSize> {
        Binding(get: { model.panelSize }, set: model.setPanelSize)
    }

    private var sessionPersistenceBinding: Binding<TranslationOptions.SessionPersistence> {
        Binding(get: { model.sessionPersistence }, set: model.setSessionPersistence)
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

    private func panelSizeLabel(_ size: TranslationOptions.PanelSize) -> String {
        switch size {
        case .compact: localization.string(.systemMenuPopoverWidthCompact)
        case .small: localization.string(.systemMenuPopoverWidthSmall)
        case .medium: localization.string(.systemMenuPopoverWidthMedium)
        case .large: localization.string(.systemMenuPopoverWidthLarge)
        case .extraLarge: localization.string(.systemMenuPopoverWidthExtraLarge)
        }
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

private struct TranslationProviderSettings: View {
    @ObservedObject var model: TranslationSettingsModel
    @Binding var expandedProvider: TranslationProviderID?
    let providerName: (TranslationProviderID) -> String
    @ObservedObject private var localization = LocalizationStore.shared

    private var cloudProviders: [TranslationProviderID] {
        model.visibleProviderCards.filter { $0 != .apple }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(spacing: 0) {
                ProviderSelectionRow(
                    provider: .automatic,
                    providerName: providerName(.automatic),
                    isSelected: model.preferredProvider == .automatic,
                    isExpanded: false,
                    status: nil,
                    onSelect: { model.setPreferredProvider(.automatic) },
                    onToggle: {}
                )
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignScale.radiusMD)
                    .strokeBorder(Color(nsColor: .separatorColor))
            }

            if model.visibleProviderCards.contains(.apple) {
                providerGroup(
                    title: localization.string(.translationSettingsOnDeviceProviders),
                    providers: [.apple]
                )
            }

            providerGroup(
                title: localization.string(.translationSettingsAPIProviders),
                providers: cloudProviders
            )
        }
    }

    private func providerGroup(title: String, providers: [TranslationProviderID]) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(spacing: 0) {
                ForEach(providers, id: \.self) { provider in
                    providerRow(provider)
                    if provider != providers.last {
                        Divider()
                    }
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: DesignScale.radiusMD)
                    .strokeBorder(Color(nsColor: .separatorColor))
            }
        }
    }

    private func providerRow(_ provider: TranslationProviderID) -> some View {
        let isExpanded = expandedProvider == provider
        return VStack(spacing: 0) {
            ProviderSelectionRow(
                provider: provider,
                providerName: providerName(provider),
                isSelected: model.preferredProvider == provider,
                isExpanded: isExpanded,
                status: ProviderStatus(provider: provider, status: model.credentialStatuses[provider]),
                onSelect: { model.setPreferredProvider(provider) },
                onToggle: {
                    expandedProvider = isExpanded ? nil : provider
                }
            )

            Divider()
                .frame(height: isExpanded ? nil : 0)
                .opacity(isExpanded ? 1 : 0)

            providerBody(provider)
                .padding(.leading, 42)
                .padding(.trailing, 14)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity, maxHeight: isExpanded ? nil : 0, alignment: .topLeading)
                .opacity(isExpanded ? 1 : 0)
                .clipped()
                .accessibilityHidden(!isExpanded)
        }
    }

    @ViewBuilder
    private func providerBody(_ provider: TranslationProviderID) -> some View {
        if provider == .apple {
            AppleTranslationSettingsCard()
        } else {
            CloudTranslationSettingsCard(
                provider: provider,
                providerName: providerName(provider),
                model: model
            )
        }
    }
}

private struct ProviderSelectionRow: View {
    let provider: TranslationProviderID
    let providerName: String
    let isSelected: Bool
    let isExpanded: Bool
    let status: ProviderStatus?
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button(action: onSelect) {
                Image(systemName: isSelected ? "circle.inset.filled" : "circle")
                    .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    .frame(width: 16, height: 16)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(providerName)
            .accessibilityValue(isSelected ? "Selected" : "Not selected")
            .accessibilityIdentifier(TranslationSettingsAccessibility.providerSelection(provider))

            TranslationProviderIcon(provider: provider, size: 18)

            Button(action: onToggle) {
                HStack(spacing: 8) {
                    Text(providerName)
                        .fontWeight(.medium)
                    Spacer(minLength: 8)
                    if let status {
                        ProviderStatusBadge(status: status)
                    }
                    if status != nil {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .rotationEffect(.degrees(isExpanded ? 180 : 0))
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(status == nil)
            .accessibilityLabel(providerName)
            .accessibilityHint(status == nil ? "" : "Show provider settings")
            .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
            .accessibilityIdentifier(
                status == nil
                    ? TranslationSettingsAccessibility.providerRow(provider)
                    : TranslationSettingsAccessibility.providerDisclosure(provider)
            )
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

private struct ProviderStatus {
    let provider: TranslationProviderID
    let status: TranslationCredentialStatus?
}

private struct ProviderStatusBadge: View {
    let status: ProviderStatus
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        Text(text)
            .font(.caption2.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.12), in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))
            .accessibilityLabel(text)
    }

    private var text: String {
        if status.provider == .apple {
            return localization.string(.translationSettingsStatusOnDevice)
        }
        switch status.status ?? .missing {
        case .missing: return localization.string(.translationSettingsStatusMissing)
        case .saved: return localization.string(.translationSettingsStatusSaved)
        case .validating: return localization.string(.translationSettingsStatusValidating)
        case .ready: return localization.string(.translationSettingsStatusReady)
        case .invalid: return localization.string(.translationSettingsStatusInvalid)
        }
    }

    private var color: Color {
        if status.provider == .apple {
            return .green
        }
        switch status.status ?? .missing {
        case .ready: return .green
        case .saved, .validating: return .orange
        case .invalid: return .red
        case .missing: return .secondary
        }
    }
}

private struct AppleTranslationSettingsCard: View {
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
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
