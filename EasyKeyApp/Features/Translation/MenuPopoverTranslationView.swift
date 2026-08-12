import AppKit
import EasyEngineCore
import SwiftUI

struct MenuPopoverTranslationActions {
    var openSettings: () -> Void
    var announceResult: (String) -> Void = { result in
        NSAccessibility.post(
            element: NSApp as Any,
            notification: .announcementRequested,
            userInfo: [
                .announcement: result,
                .priority: NSAccessibilityPriorityLevel.medium.rawValue,
            ]
        )
    }
}

struct MenuPopoverTranslationConfiguration {
    let model: TranslationModel
    let availableProviders: [TranslationProviderID]
    let sessionHost: AnyView?
    let actions: MenuPopoverTranslationActions

    init(
        model: TranslationModel,
        availableProviders: [TranslationProviderID],
        platformCapability: TranslationPlatformCapability,
        sessionHost: AnyView? = nil,
        actions: MenuPopoverTranslationActions
    ) {
        self.model = model
        let configuredCloudProviders = Set(availableProviders.filter {
            TranslationProviderResolver.cloudProviderOrder.contains($0)
        })
        self.availableProviders = TranslationProviderResolver.availableProviders(
            platformCapability: platformCapability,
            configuredCloudProviders: configuredCloudProviders
        )
        self.sessionHost = sessionHost
        self.actions = actions
    }
}

enum MenuPopoverTranslationLayout {
    static func usesSideBySideEditors(width: CGFloat, accessibilityText: Bool) -> Bool {
        width >= CGFloat(SystemOptions.MenuPopoverWidth.extraLarge.rawValue) && !accessibilityText
    }
}

struct MenuPopoverTranslationPresentation: Equatable {
    let resultText: String
    let error: TranslationError?
    let isTranslating: Bool
    let canTranslate: Bool
    let setupRequired: Bool

    init(
        sourceText: String,
        sourceLanguage: TranslationLanguage?,
        targetLanguage: TranslationLanguage,
        providerID: TranslationProviderID?,
        availableProviders: [TranslationProviderID],
        status: TranslationModel.Status
    ) {
        let presentation = TranslationPanelPresentation(
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            providerID: providerID,
            availableProviders: availableProviders,
            status: status
        )
        resultText = presentation.resultText
        error = presentation.error
        isTranslating = presentation.isTranslating
        canTranslate = presentation.canTranslate
        setupRequired = presentation.setupRequired
    }
}

enum MenuPopoverTranslationAccessibility {
    static let section = "MenuPopoverTranslationSection"
    static let providerPicker = "MenuPopoverTranslationProviderPicker"
    static let sourceLanguagePicker = "MenuPopoverTranslationSourceLanguagePicker"
    static let swapButton = "MenuPopoverTranslationSwapButton"
    static let targetLanguagePicker = "MenuPopoverTranslationTargetLanguagePicker"
    static let sourceEditor = "MenuPopoverTranslationSourceEditor"
    static let result = "MenuPopoverTranslationResult"
    static let translateButton = "MenuPopoverTranslationTranslateButton"
    static let settingsButton = "MenuPopoverTranslationSettingsButton"
    static let status = "MenuPopoverTranslationStatus"
}

struct MenuPopoverTranslationView: View {
    @ObservedObject var model: TranslationModel
    let availableProviders: [TranslationProviderID]
    @ObservedObject var localization: LocalizationStore
    let actions: MenuPopoverTranslationActions
    let width: CGFloat

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var presentation: MenuPopoverTranslationPresentation {
        MenuPopoverTranslationPresentation(
            sourceText: model.sourceText,
            sourceLanguage: model.sourceLanguage,
            targetLanguage: model.targetLanguage,
            providerID: model.providerID,
            availableProviders: availableProviders,
            status: model.status
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            editors
            status
            footer
        }
        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.section)
        .onChange(of: presentation.resultText) { _, result in
            guard !result.isEmpty else { return }
            actions.announceResult(localization.string(.translationResultAnnouncement))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Label(localization.string(.translationTitle), systemImage: "character.bubble")
                    .font(.headline)
                if presentation.isTranslating {
                    ProgressView().controlSize(.small)
                }
                Spacer(minLength: 8)
                providerControl
            }
            languageRow
        }
        .disabled(presentation.isTranslating)
    }

    private var providerControl: some View {
        compactProvider
    }

    private var compactProvider: some View {
        TranslationProviderPickerButton(
            selection: model.providerID,
            availableProviders: availableProviders,
            providerLabel: providerName,
            accessibilityLabel: providerAccessibilityLabel,
            accessibilityIdentifier: MenuPopoverTranslationAccessibility.providerPicker,
            onSelect: model.selectProvider
        )
    }

    private var languageRow: some View {
        HStack(spacing: 8) {
            sourceLanguagePicker
                .frame(maxWidth: .infinity)
            swapButton
            targetLanguagePicker
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .disabled(presentation.isTranslating)
    }

    private var sourceLanguagePicker: some View {
        Menu {
            Button {
                sourceLanguageBinding.wrappedValue = nil
            } label: {
                if sourceLanguageBinding.wrappedValue == nil {
                    Label(localization.string(.translationDetectLanguage), systemImage: "checkmark")
                } else {
                    Text(localization.string(.translationDetectLanguage))
                }
            }
            ForEach(SupportedLanguages.all, id: \.self) { language in
                Button {
                    sourceLanguageBinding.wrappedValue = language
                } label: {
                    if sourceLanguageBinding.wrappedValue == language {
                        Label(languageName(language), systemImage: "checkmark")
                    } else {
                        Text(languageName(language))
                    }
                }
            }
        } label: {
            languageMenuLabel(
                sourceLanguageBinding.wrappedValue.map(languageName)
                    ?? localization.string(.translationDetectLanguage)
            )
        }
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .accessibilityLabel(localization.string(.translationSourceLanguage))
        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.sourceLanguagePicker)
    }

    private var targetLanguagePicker: some View {
        Menu {
            ForEach(SupportedLanguages.all, id: \.self) { language in
                Button {
                    targetLanguageBinding.wrappedValue = language
                } label: {
                    if targetLanguageBinding.wrappedValue == language {
                        Label(languageName(language), systemImage: "checkmark")
                    } else {
                        Text(languageName(language))
                    }
                }
            }
        } label: {
            languageMenuLabel(languageName(targetLanguageBinding.wrappedValue))
        }
        .menuIndicator(.hidden)
        .menuStyle(.borderlessButton)
        .accessibilityLabel(localization.string(.translationTargetLanguage))
        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.targetLanguagePicker)
    }

    private func languageMenuLabel(_ title: String) -> some View {
        HStack(spacing: 4) {
            Text(title)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            Image(systemName: "chevron.up.chevron.down")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 22)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 5))
        .overlay {
            RoundedRectangle(cornerRadius: 5)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
        }
    }

    @ViewBuilder private var editors: some View {
        if MenuPopoverTranslationLayout.usesSideBySideEditors(
            width: width,
            accessibilityText: dynamicTypeSize.isAccessibilitySize
        ) {
            HStack(alignment: .top, spacing: 8) { editorSections }
        } else {
            VStack(alignment: .leading, spacing: 8) { editorSections }
        }
    }

    @ViewBuilder private var editorSections: some View {
        editorCard(title: localization.string(.translationSourceText)) {
            TranslationTextEditor(
                text: sourceTextBinding,
                isFocused: true,
                onTranslateTriggered: { model.translate() }
            )
            .accessibilityLabel(localization.string(.translationSourceText))
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.sourceEditor)
        }

        editorCard(title: localization.string(.translationResult)) {
            ScrollView {
                Text(presentation.resultText.isEmpty
                    ? localization.string(.translationResultPlaceholder)
                    : presentation.resultText)
                    .font(.body)
                    .foregroundStyle(presentation.resultText.isEmpty ? .secondary : .primary)
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(4)
            }
            .accessibilityLabel(localization.string(.translationResult))
            .accessibilityValue(presentation.resultText.isEmpty
                ? localization.string(.translationResultPlaceholder)
                : presentation.resultText)
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.result)
        }
    }

    private var footer: some View {
        Text(localization.string(.translationEditorInstructions))
            .font(.caption)
            .foregroundStyle(.secondary)
    }

    private var swapButton: some View {
        Button(action: model.swapLanguages) {
            Image(systemName: "arrow.left.arrow.right")
                .frame(width: 24, height: 24)
        }
        .buttonStyle(.borderless)
        .disabled(presentation.isTranslating)
        .help(localization.string(.translationSwapLanguages))
        .accessibilityLabel(localization.string(.translationSwapLanguages))
        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.swapButton)
    }

    @ViewBuilder private var status: some View {
        if presentation.setupRequired {
            HStack(spacing: 8) {
                Label(localization.string(.translationSetupMessage), systemImage: "gear.badge")
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                Button(localization.string(.translationOpenSettings), action: actions.openSettings)
                    .accessibilityIdentifier(MenuPopoverTranslationAccessibility.settingsButton)
            }
            .foregroundStyle(.secondary)
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.status)
        } else if let error = presentation.error, error != .cancelled {
            HStack(spacing: 8) {
                Label(errorMessage(error), systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer(minLength: 8)
                if errorNeedsSettings(error) {
                    Button(localization.string(.translationOpenSettings), action: actions.openSettings)
                        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.settingsButton)
                }
            }
            .font(.caption)
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.status)
        }
    }

    private func editorCard<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.caption.weight(.semibold))
            content()
                .frame(minHeight: 84, idealHeight: 96, maxHeight: 112)
                .padding(5)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: DesignScale.radiusSM))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignScale.radiusSM)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                }
        }
        .frame(maxWidth: .infinity)
    }

    private var sourceTextBinding: Binding<String> {
        Binding(get: { model.sourceText }, set: model.setSourceTextFromUserInput)
    }

    private var sourceLanguageBinding: Binding<TranslationLanguage?> {
        Binding(get: { model.sourceLanguage }, set: model.selectSourceLanguage)
    }

    private var targetLanguageBinding: Binding<TranslationLanguage> {
        Binding(get: { model.targetLanguage }, set: model.setTargetLanguage)
    }

    private var providerAccessibilityLabel: String {
        guard let providerID = model.providerID, availableProviders.contains(providerID) else {
            return "\(localization.string(.translationProvider)): \(providerName(.apple))"
        }
        return "\(localization.string(.translationProvider)): \(providerName(providerID))"
    }

    private func providerName(_ provider: TranslationProviderID) -> String {
        provider == .automatic ? localization.string(.translationProviderAutomatic) : provider.displayName
    }

    private func languageName(_ language: TranslationLanguage) -> String {
        Locale(identifier: localization.resolvedCode)
            .localizedString(forIdentifier: language.identifier)?
            .capitalized(with: localization.locale) ?? language.identifier
    }

    private func errorMessage(_ error: TranslationError) -> String {
        switch error {
        case .noProviderConfigured: localization.string(.translationSetupMessage)
        case let .missingCredentials(provider):
            localization.format(.translationErrorMissingCredentials, providerName(provider))
        case .unsupportedLanguagePair: localization.string(.translationErrorUnsupportedPair)
        case .appleLanguageDownloadRequired: localization.string(.translationErrorDownloadRequired)
        case .networkUnavailable: localization.string(.translationErrorNetwork)
        case .requestTimedOut: localization.string(.translationErrorTimeout)
        case .rateLimitExceeded: localization.string(.translationErrorRateLimit)
        case .requestTooLarge: localization.string(.translationErrorTooLarge)
        case .providerUnavailable: localization.string(.translationErrorProviderUnavailable)
        case .invalidResponse: localization.string(.translationErrorInvalidResponse)
        case .cancelled: localization.string(.translationErrorCancelled)
        }
    }

    private func errorNeedsSettings(_ error: TranslationError) -> Bool {
        switch error {
        case .noProviderConfigured, .missingCredentials, .appleLanguageDownloadRequired:
            true
        default:
            false
        }
    }
}
