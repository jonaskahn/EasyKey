import SwiftUI

struct CloudTranslationSettingsCard: View {
    let provider: TranslationProviderID
    let providerName: String
    @ObservedObject var model: TranslationSettingsModel
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var credential = ""
    @State private var modelIdentifier = ""
    @State private var modelIdentifierIsInvalid = false
    @State private var endpointURL = ""
    @State private var showDeleteConfirmation = false
    @State private var showModelPicker = false
    @State private var modelSearchText = ""
    @State private var modelSelectionState: ModelSelectionState = .idle
    @State private var modelSelectionTask: Task<Void, Never>?

    private enum ModelSelectionState {
        case idle
        case processing
        case saved
    }

    private var usesOfficialModelCatalog: Bool {
        provider.isOfficialAIModelProvider
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
                Picker(selection: deepLEndpointBinding) {
                    Text(localization.string(.translationSettingsDeepLFree)).tag(TranslationOptions.DeepLEndpoint.free)
                    Text(localization.string(.translationSettingsDeepLPro)).tag(TranslationOptions.DeepLEndpoint.pro)
                } label: {
                    SettingsControlLabel(title: localization.string(.translationSettingsDeepLPlan))
                }
                .accessibilityLabel(localization.string(.translationSettingsDeepLPlan))
                .accessibilityIdentifier(TranslationSettingsAccessibility.deepLPlanPicker)
            }

            if provider == .openAICompatible || provider == .anthropicCompatible {
                LabeledContent {
                    TextField(localization.string(.translationSettingsEndpoint), text: $endpointURL)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .onSubmit(saveEndpoint)
                        .accessibilityLabel("\(providerName): \(localization.string(.translationSettingsEndpoint))")
                        .accessibilityHint(localization.string(.translationSettingsEndpointHint))
                } label: {
                    SettingsControlLabel(title: localization.string(.translationSettingsEndpoint))
                }
            }

            credentialAndModelBlock

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
            if model.canManageModels(for: provider) {
                model.loadModelCatalog(for: provider)
            }
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

    private var credentialAndModelBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            LabeledContent {
                PasteableSecureField(
                    text: $credential,
                    placeholder: localization.string(.translationSettingsApiKey),
                    accessibilityLabel: localization.format(.translationSettingsApiKeyA11y, providerName),
                    accessibilityIdentifier: TranslationSettingsAccessibility.credentialField(provider),
                    onSubmit: saveCredential
                )
                .frame(maxWidth: .infinity, minHeight: 22)
            } label: {
                SettingsControlLabel(title: localization.string(.translationSettingsApiKey))
            }

            if model.modelIdentifier(for: provider) != nil {
                modelRow
            }
        }
    }

    private var canManageModels: Bool {
        model.canManageModels(for: provider)
    }

    private var modelLabel: some View {
        HStack(spacing: 6) {
            SettingsControlLabel(title: localization.string(.translationSettingsModels))
            selectionStatusView
        }
    }

    @ViewBuilder
    private var modelRow: some View {
        if usesOfficialModelCatalog {
            LabeledContent {
                officialModelPicker
            } label: {
                modelLabel
            }
            .disabled(!canManageModels)
        } else {
            VStack(alignment: .leading, spacing: 4) {
                LabeledContent {
                    TextField(localization.string(.translationSettingsModel), text: $modelIdentifier)
                        .textFieldStyle(.roundedBorder)
                        .labelsHidden()
                        .disabled(!canManageModels)
                        .onSubmit(saveModelIdentifier)
                        .accessibilityLabel("\(providerName): \(localization.string(.translationSettingsModel))")
                        .accessibilityHint(
                            canManageModels
                                ? localization.string(.translationSettingsModelHint)
                                : localization.string(.translationSettingsModelNeedsApiKey)
                        )
                } label: {
                    SettingsControlLabel(title: localization.string(.translationSettingsModel))
                }
                if modelIdentifierIsInvalid {
                    Text(localization.string(.translationSettingsModelInvalid))
                        .font(.caption)
                        .foregroundStyle(.primary)
                }
            }
        }
    }

    private var officialModelPicker: some View {
        Button {
            guard canManageModels else { return }
            modelSearchText = ""
            showModelPicker = true
            model.loadModelCatalog(for: provider)
        } label: {
            HStack {
                Text(modelIdentifier.nonEmptyForDisplay(
                    fallback: model.modelIdentifier(for: provider) ?? provider.displayName
                ))
                .lineLimit(2)
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity, minHeight: 22, alignment: .leading)
            .background(.quaternary, in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))
        }
        .buttonStyle(.plain)
        .disabled(!canManageModels)
        .accessibilityLabel("\(providerName): \(localization.string(.translationSettingsModels))")
        .accessibilityHint(
            canManageModels
                ? localization.string(.translationSettingsModelSearch)
                : localization.string(.translationSettingsModelNeedsApiKey)
        )
        .popover(isPresented: $showModelPicker) {
            modelPickerPopover
        }
    }

    private var modelPickerPopover: some View {
        VStack(spacing: 0) {
            TextField(localization.string(.translationSettingsModelSearch), text: $modelSearchText)
                .textFieldStyle(.roundedBorder)
                .padding(8)
                .accessibilityLabel(localization.string(.translationSettingsModelSearch))

            switch model.modelCatalogStates[provider] ?? .idle {
            case .idle, .loading:
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(localization.string(.translationSettingsModelLoading))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(width: 260)
            case .failed:
                VStack(spacing: 8) {
                    Text(localization.string(.translationSettingsModelLoadFailed))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button(localization.string(.translationSettingsModelRetry)) {
                        model.loadModelCatalog(for: provider)
                    }
                }
                .padding(20)
                .frame(width: 260)
            case let .loaded(entries):
                let filtered = filteredEntries(entries)
                if filtered.isEmpty {
                    Text(localization.string(.translationSettingsModelNoResults))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(20)
                        .frame(width: 260)
                } else {
                    List(filtered, id: \.identifier) { entry in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.displayName)
                                .lineLimit(2)
                            if entry.displayName != entry.identifier {
                                Text(entry.identifier)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        .padding(.vertical, 2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectModelEntry(entry)
                        }
                    }
                    .frame(width: 280, height: 280)
                }
            }
        }
    }

    private func filteredEntries(_ entries: [TranslationModelCatalogEntry]) -> [TranslationModelCatalogEntry] {
        let trimmed = modelSearchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entries }
        return entries.filter {
            $0.identifier.localizedCaseInsensitiveContains(trimmed)
                || $0.displayName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func selectModelEntry(_ entry: TranslationModelCatalogEntry) {
        guard model.setModelIdentifier(entry.identifier, for: provider) else {
            modelIdentifier = model.modelIdentifier(for: provider) ?? ""
            showModelPicker = false
            return
        }
        modelIdentifier = entry.identifier
        showModelPicker = false
        triggerModelSelectionFeedback()
    }

    private var selectionStatusView: some View {
        Group {
            switch modelSelectionState {
            case .idle:
                EmptyView()
            case .processing:
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 16, height: 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            case .saved:
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.green)
                    .frame(width: 16, height: 16)
                    .transition(.opacity.combined(with: .scale(scale: 0.8)))
            }
        }
        .accessibilityLabel(selectionStatusAccessibilityLabel)
    }

    private var selectionStatusAccessibilityLabel: String {
        switch modelSelectionState {
        case .idle:
            return ""
        case .processing:
            return localization.string(.translationSettingsModelSavingA11y)
        case .saved:
            return "\(providerName): \(localization.string(.translationSettingsModelSavedA11y))"
        }
    }

    private func triggerModelSelectionFeedback() {
        modelSelectionTask?.cancel()
        modelSelectionState = .processing
        modelSelectionTask = Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.25)) {
                modelSelectionState = .saved
            }
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 0.3)) {
                modelSelectionState = .idle
            }
        }
    }

    private var status: TranslationCredentialStatus {
        model.credentialStatuses[provider] ?? .missing
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

private extension String {
    func nonEmptyForDisplay(fallback: String) -> String {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? fallback : trimmed
    }
}
