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

enum MenuPopoverSection: Equatable {
    case translation
    case inputControls
    case inputStatus
    case footer
}

enum MenuPopoverLayout {
    static func sectionOrder(hasTranslation: Bool) -> [MenuPopoverSection] {
        hasTranslation
            ? [.translation, .inputControls, .inputStatus, .footer]
            : [.inputControls, .inputStatus, .footer]
    }
}

struct MenuPopoverTranslationPresentation: Equatable {
    let resultText: String
    let error: TranslationError?
    let isTranslating: Bool
    let canTranslate: Bool
    let setupRequired: Bool
    let disclosure: TranslationPanelPresentation.Disclosure

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
        disclosure = providerID.map(availableProviders.contains) == true ? presentation.disclosure : .none
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
    static let disclosure = "MenuPopoverTranslationDisclosure"
}

struct MenuPopoverTranslationView: View {
    @ObservedObject var model: TranslationModel
    let availableProviders: [TranslationProviderID]
    @ObservedObject var localization: LocalizationStore
    let actions: MenuPopoverTranslationActions

    @FocusState private var sourceFocused: Bool
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
        VStack(alignment: .leading, spacing: 10) {
            Label(localization.string(.translationTitle), systemImage: "character.bubble")
                .font(.headline)
            controls
            editors
            status
            actionRow
        }
        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.section)
        .onAppear { sourceFocused = true }
        .onChange(of: presentation.resultText) { _, result in
            guard !result.isEmpty else { return }
            actions.announceResult(localization.string(.translationResultAnnouncement))
        }
    }

    @ViewBuilder
    private var editors: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 10) { editorSections }
        } else {
            HStack(alignment: .top, spacing: 10) { editorSections }
        }
    }

    @ViewBuilder private var editorSections: some View {
        editorCard(title: localization.string(.translationSourceText)) {
            TextEditor(text: sourceTextBinding)
                .font(.body)
                .scrollContentBackground(.hidden)
                .focused($sourceFocused)
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

    private var actionRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            disclosure
            HStack(alignment: .center, spacing: 10) {
                Text(localization.string(.translationPopoverInstructions))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 8)
                Button(localization.string(.translationTranslate), action: model.translate)
                    .keyboardShortcut(.return, modifiers: .command)
                    .buttonStyle(.borderedProminent)
                    .easyKeyButtonShape()
                    .disabled(!presentation.canTranslate)
                    .accessibilityHint(localization.string(.translationTranslateHint))
                    .accessibilityIdentifier(MenuPopoverTranslationAccessibility.translateButton)
            }
        }
    }

    private var controls: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 8) {
                    providerPicker
                    languageControls
                }
            } else {
                HStack(spacing: 8) {
                    providerPicker
                    languageControls
                }
            }
        }
        .disabled(presentation.isTranslating)
    }

    private var providerPicker: some View {
        Picker(localization.string(.translationProvider), selection: providerBinding) {
            Text(localization.string(.translationChooseProvider)).tag(nil as TranslationProviderID?)
            ForEach(availableProviders, id: \.self) { provider in
                Text(providerName(provider)).tag(provider as TranslationProviderID?)
            }
        }
        .labelsHidden()
        .frame(minWidth: 130, maxWidth: dynamicTypeSize.isAccessibilitySize ? .infinity : nil)
        .accessibilityLabel(localization.string(.translationProvider))
        .accessibilityIdentifier(MenuPopoverTranslationAccessibility.providerPicker)
    }

    private var languageControls: some View {
        HStack(spacing: 8) {
            Picker(localization.string(.translationSourceLanguage), selection: sourceLanguageBinding) {
                Text(localization.string(.translationDetectLanguage)).tag(nil as TranslationLanguage?)
                ForEach(SupportedLanguages.all, id: \.self) { language in
                    Text(languageName(language)).tag(language as TranslationLanguage?)
                }
            }
            .labelsHidden()
            .frame(minWidth: 150)
            .accessibilityLabel(localization.string(.translationSourceLanguage))
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.sourceLanguagePicker)

            Button(action: model.swapLanguages) {
                Image(systemName: "arrow.left.arrow.right")
                    .frame(width: 24, height: 24)
            }
            .buttonStyle(.borderless)
            .disabled(presentation.isTranslating)
            .help(localization.string(.translationSwapLanguages))
            .accessibilityLabel(localization.string(.translationSwapLanguages))
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.swapButton)

            Picker(localization.string(.translationTargetLanguage), selection: targetLanguageBinding) {
                ForEach(SupportedLanguages.all, id: \.self) { language in
                    Text(languageName(language)).tag(language)
                }
            }
            .labelsHidden()
            .frame(minWidth: 150)
            .accessibilityLabel(localization.string(.translationTargetLanguage))
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.targetLanguagePicker)
        }
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
        } else if presentation.isTranslating {
            HStack(spacing: 8) {
                ProgressView().controlSize(.small)
                Text(localization.string(.translationInProgress))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(localization.string(.translationInProgress))
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.status)
        }
    }

    @ViewBuilder private var disclosure: some View {
        switch presentation.disclosure {
        case .none:
            EmptyView()
        case .local:
            Label(localization.string(.translationLocalDisclosure), systemImage: "lock.shield")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier(MenuPopoverTranslationAccessibility.disclosure)
        case let .cloud(provider):
            Label(
                localization.format(.translationCloudDisclosure, providerName(provider)),
                systemImage: "cloud"
            )
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier(MenuPopoverTranslationAccessibility.disclosure)
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
        Binding(get: { model.sourceText }, set: model.setSourceText)
    }

    private var providerBinding: Binding<TranslationProviderID?> {
        Binding(
            get: {
                guard let providerID = model.providerID, availableProviders.contains(providerID) else { return nil }
                return providerID
            },
            set: model.setProviderID
        )
    }

    private var sourceLanguageBinding: Binding<TranslationLanguage?> {
        Binding(get: { model.sourceLanguage }, set: model.setSourceLanguage)
    }

    private var targetLanguageBinding: Binding<TranslationLanguage> {
        Binding(get: { model.targetLanguage }, set: model.setTargetLanguage)
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
