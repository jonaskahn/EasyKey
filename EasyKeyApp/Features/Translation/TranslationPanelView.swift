import AppKit
import EasyEngineCore
import SwiftUI

struct TranslationPanelActions {
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

enum TranslationPanelKeyboardAction: Equatable {
    case translate

    static func resolve(keyCode: UInt16, modifiers: Shortcut.ModifierFlags) -> Self? {
        guard keyCode == 36, modifiers == [.command] else { return nil }
        return .translate
    }
}

enum TranslationPanelAccessibility {
    static let providerPicker = "TranslationProviderPicker"
    static let sourceLanguagePicker = "TranslationSourceLanguagePicker"
    static let swapButton = "TranslationSwapButton"
    static let targetLanguagePicker = "TranslationTargetLanguagePicker"
    static let sourceEditor = "TranslationSourceEditor"
    static let sourceSpeechButton = "TranslationSourceSpeechButton"
    static let resultEditor = "TranslationResultEditor"
    static let resultSpeechButton = "TranslationResultSpeechButton"
    static let translateButton = "TranslationTranslateButton"
    static let settingsButton = "TranslationSettingsButton"
    static let status = "TranslationStatus"
}

struct TranslationPanelPresentation: Equatable {
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
        switch status {
        case .idle, .translating, .failed:
            resultText = ""
        case let .succeeded(response):
            resultText = response.translatedText
        }
        if case let .failed(error) = status {
            self.error = error
        } else {
            error = nil
        }
        isTranslating = status == .translating
        setupRequired = availableProviders.isEmpty || error == .noProviderConfigured
        let trimmed = sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
        canTranslate = providerID.map(availableProviders.contains) == true
            && !trimmed.isEmpty
            && trimmed.count <= TranslationRequest.maximumSourceTextLength
            && sourceLanguage != targetLanguage
            && !isTranslating

    }
}

struct TranslationPanelView: View {
    @ObservedObject var model: TranslationModel
    @ObservedObject var speech: TranslationSpeechController
    @ObservedObject var localization: LocalizationStore
    let availableProviders: [TranslationProviderID]
    let shortcut: Shortcut
    let actions: TranslationPanelActions

    @FocusState private var focusedField: FocusedField?

    private enum FocusedField: Hashable {
        case source
    }

    private var presentation: TranslationPanelPresentation {
        TranslationPanelPresentation(
            sourceText: model.sourceText,
            sourceLanguage: model.sourceLanguage,
            targetLanguage: model.targetLanguage,
            providerID: model.providerID,
            availableProviders: availableProviders,
            status: model.status
        )
    }

    private var response: TranslationResponse? {
        guard case let .succeeded(response) = model.status else { return nil }
        return response
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    header
                    sourceSection
                    resultSection
                    statusSection
                }
                .padding(16)
            }
            Divider()
            footer
        }
        .frame(minWidth: 420, minHeight: 500)
        .background(Color(nsColor: .windowBackgroundColor))
        .environment(\.locale, localization.locale)
        .onAppear { focusedField = .source }
        .onChange(of: presentation.resultText) { _, result in
            guard !result.isEmpty else { return }
            actions.announceResult(localization.string(.translationResultAnnouncement))
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 8) {
                Label(localization.string(.translationTitle), systemImage: "character.bubble")
                    .font(.headline)
                if presentation.isTranslating {
                    ProgressView().controlSize(.small)
                }
                Spacer(minLength: 8)
                providerControl
            }
            HStack(spacing: 8) {
                sourceLanguagePicker
                    .frame(maxWidth: .infinity)
                Button(action: model.swapLanguages) {
                    Image(systemName: "arrow.left.arrow.right")
                        .frame(width: 24, height: 24)
                }
                .buttonStyle(.borderless)
                .disabled(presentation.isTranslating)
                .help(localization.string(.translationSwapLanguages))
                .accessibilityLabel(localization.string(.translationSwapLanguages))
                .accessibilityIdentifier(TranslationPanelAccessibility.swapButton)
                targetLanguagePicker
                    .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var providerControl: some View {
        TranslationProviderPickerButton(
            selection: model.providerID,
            availableProviders: availableProviders,
            chooseTitle: localization.string(.translationChooseProvider),
            providerLabel: providerName,
            accessibilityLabel: providerAccessibilityLabel,
            accessibilityIdentifier: TranslationPanelAccessibility.providerPicker,
            onSelect: model.setProviderID
        )
    }

    private var providerAccessibilityLabel: String {
        guard let providerID = model.providerID, availableProviders.contains(providerID) else {
            return localization.string(.translationChooseProvider)
        }
        return "\(localization.string(.translationProvider)): \(providerName(providerID))"
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
        .accessibilityIdentifier(TranslationPanelAccessibility.sourceLanguagePicker)
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
        .accessibilityIdentifier(TranslationPanelAccessibility.targetLanguagePicker)
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

    private var sourceSection: some View {
        editorCard(title: localization.string(.translationSourceText)) {
            TextEditor(text: sourceTextBinding)
                .font(.body)
                .scrollContentBackground(.hidden)
                .focused($focusedField, equals: .source)
                .accessibilityLabel(localization.string(.translationSourceText))
                .accessibilityIdentifier(TranslationPanelAccessibility.sourceEditor)
        } footer: {
            HStack {
                Text(localization.format(
                    .translationCharacterCount,
                    model.sourceText.count,
                    TranslationRequest.maximumSourceTextLength
                ))
                Spacer()
                speechControl(field: .source)
            }
        }
    }

    private var resultSection: some View {
        editorCard(title: localization.string(.translationResult)) {
            ScrollView {
                Text(presentation.resultText.isEmpty ? localization.string(.translationResultPlaceholder) : presentation.resultText)
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
            .accessibilityIdentifier(TranslationPanelAccessibility.resultEditor)
        } footer: {
            HStack {
                if let detected = response?.detectedSourceLanguage, model.sourceLanguage == nil {
                    Text(localization.format(.translationDetectedLanguage, languageName(detected)))
                }
                Spacer()
                speechControl(field: .result)
            }
        }
    }

    @ViewBuilder private var statusSection: some View {
        if presentation.setupRequired {
            messageCard(
                icon: "gear.badge",
                title: localization.string(.translationSetupTitle),
                message: localization.string(.translationSetupMessage),
                tint: .orange
            ) {
                Button(localization.string(.translationOpenSettings), action: actions.openSettings)
                    .accessibilityIdentifier(TranslationPanelAccessibility.settingsButton)
            }
        } else if let error = presentation.error, error != .cancelled {
            messageCard(
                icon: "exclamationmark.triangle.fill",
                title: localization.string(.translationErrorTitle),
                message: errorMessage(error),
                tint: .red
            ) {
                if errorNeedsSettings(error) {
                    Button(localization.string(.translationOpenSettings), action: actions.openSettings)
                        .accessibilityIdentifier(TranslationPanelAccessibility.settingsButton)
                }
            }
        }
    }

    private var footer: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(localization.string(.translationEditorInstructions))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 8)
            Button(localization.string(.translationTranslate)) { model.translate() }
                .keyboardShortcut(.return, modifiers: .command)
                .buttonStyle(.borderedProminent)
                .easyKeyButtonShape()
                .disabled(!presentation.canTranslate)
                .accessibilityHint(localization.string(.translationTranslateHint))
                .accessibilityIdentifier(TranslationPanelAccessibility.translateButton)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func editorCard<Content: View, Footer: View>(
        title: String,
        @ViewBuilder content: () -> Content,
        @ViewBuilder footer: () -> Footer
    ) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.subheadline.weight(.semibold))
            content()
                .frame(minHeight: 92, idealHeight: 112, maxHeight: 150)
                .padding(6)
                .background(Color(nsColor: .textBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: DesignScale.radiusSM))
                .overlay {
                    RoundedRectangle(cornerRadius: DesignScale.radiusSM)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                }
            footer()
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func messageCard<Action: View>(
        icon: String,
        title: String,
        message: String,
        tint: Color,
        @ViewBuilder action: () -> Action
    ) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon).foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(message).foregroundStyle(.secondary)
                action()
            }
            Spacer()
        }
        .font(.caption)
        .padding(10)
        .background(tint.opacity(0.09), in: RoundedRectangle(cornerRadius: DesignScale.radiusMD))
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier(TranslationPanelAccessibility.status)
    }

    @ViewBuilder private func speechControl(field: TranslationSpeechField) -> some View {
        if pronunciationSupported {
            let availability = speechAvailability(field)
            let subject = field == .source
                ? localization.string(.translationSourceText)
                : localization.string(.translationResult)
            let speechLabel = localization.format(.translationPronounceSubject, subject)
            if speech.speakingField == field {
                Button(localization.string(.translationStopSpeaking)) { speech.stopSpeaking() }
                    .buttonStyle(.borderless)
                    .accessibilityLabel("\(localization.string(.translationStopSpeaking)): \(subject)")
                    .accessibilityIdentifier(speechIdentifier(field))
            } else {
                Button {
                    speak(field)
                } label: {
                    Label(localization.string(.translationPronounce), systemImage: "speaker.wave.2")
                }
                .buttonStyle(.borderless)
                .disabled(availability != .available)
                .help(speechAvailabilityMessage(availability))
                .accessibilityLabel(speechLabel)
                .accessibilityHint(speechAvailabilityMessage(availability))
                .accessibilityIdentifier(speechIdentifier(field))
            }
        }
    }

    private var pronunciationSupported: Bool {
        guard let providerID = model.providerID else { return false }
        return TranslationPronunciationPolicy.supports(providerID)
    }

    private var sourceTextBinding: Binding<String> {
        Binding(get: { model.sourceText }, set: model.setSourceTextFromUserInput)
    }

    private var sourceLanguageBinding: Binding<TranslationLanguage?> {
        Binding(get: { model.sourceLanguage }, set: model.setSourceLanguage)
    }

    private var targetLanguageBinding: Binding<TranslationLanguage> {
        Binding(get: { model.targetLanguage }, set: model.setTargetLanguage)
    }

    private func speechAvailability(_ field: TranslationSpeechField) -> TranslationSpeechAvailability {
        switch field {
        case .source:
            return speech.sourceAvailability(
                for: model.sourceText,
                selectedLanguage: model.sourceLanguage,
                detectedLanguage: response?.detectedSourceLanguage
            )
        case .result:
            return speech.resultAvailability(for: presentation.resultText, targetLanguage: model.targetLanguage)
        }
    }

    private func speak(_ field: TranslationSpeechField) {
        switch field {
        case .source:
            speech.speakSource(
                model.sourceText,
                selectedLanguage: model.sourceLanguage,
                detectedLanguage: response?.detectedSourceLanguage
            )
        case .result:
            speech.speakResult(presentation.resultText, targetLanguage: model.targetLanguage)
        }
    }

    private func speechIdentifier(_ field: TranslationSpeechField) -> String {
        field == .source
            ? TranslationPanelAccessibility.sourceSpeechButton
            : TranslationPanelAccessibility.resultSpeechButton
    }

    private func speechAvailabilityMessage(_ availability: TranslationSpeechAvailability) -> String {
        switch availability {
        case .available:
            return localization.string(.translationPronounceHint)
        case .emptyText:
            return localization.string(.translationSpeechEmpty)
        case .sourceLanguageNotDetected:
            return localization.string(.translationSpeechNeedsLanguage)
        case let .voiceUnavailable(identifier):
            return localization.format(.translationSpeechVoiceUnavailable, identifier)
        }
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
