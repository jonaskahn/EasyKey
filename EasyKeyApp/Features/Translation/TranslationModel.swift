import Combine
import EasyEngineCore
import Foundation

enum TranslationPronunciationPolicy {
    static func supports(_ providerID: TranslationProviderID) -> Bool {
        providerID == .apple || providerID == .google
    }
}

/// Owns shared quick/full translation state: source text, languages,
/// provider selection, in-flight request, and result. Views render this
/// state and send intent; this type owns no window, panel, or pasteboard
/// behavior.
@MainActor
final class TranslationModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case translating
        case succeeded(TranslationResponse)
        case failed(TranslationError)
    }

    @Published private(set) var sourceText: String = ""
    @Published private(set) var sourceLanguage: TranslationLanguage?
    @Published private(set) var targetLanguage: TranslationLanguage
    @Published private(set) var providerID: TranslationProviderID?
    @Published private(set) var status: Status = .idle

    private let providerLookup: TranslationProviderLookup
    private let requestsDisclosure: TranslationDisclosureDecision
    private let onPronunciationUnsupportedProvider: () -> Void
    private var generation = 0
    private var activeTask: Task<Void, Never>?
    private var autoTranslateTask: Task<Void, Never>?
    private var autoTranslateDelay: TimeInterval = TranslationOptions.AutoTranslateDelayPreset.ms500.timeInterval

    /// Notified after a user-initiated provider selection from the panel or
    /// popover picker. Programmatic changes (`setProviderID`) never fire this,
    /// so callers can safely persist the user's choice here without capturing
    /// fallback resolution.
    var onProviderSelected: ((TranslationProviderID) -> Void)?

    /// `targetLanguage` seeds once from `inputLanguage` via the
    /// opposite-input default-target rule. After that, manual swaps and
    /// target changes persist for the rest of the session; nothing
    /// re-derives it from input mode again.
    init(
        inputLanguage: InputLanguage,
        providerID: TranslationProviderID?,
        providerLookup: @escaping TranslationProviderLookup,
        requestsDisclosure: @escaping TranslationDisclosureDecision = { _ in true },
        onPronunciationUnsupportedProvider: @escaping () -> Void = {}
    ) {
        self.providerID = providerID
        self.providerLookup = providerLookup
        self.requestsDisclosure = requestsDisclosure
        self.onPronunciationUnsupportedProvider = onPronunciationUnsupportedProvider
        targetLanguage = TranslationLanguagePolicy.defaultTarget(forInput: inputLanguage)
    }

    func setSourceText(_ text: String) {
        guard text != sourceText else { return }
        invalidateRequest()
        sourceText = text
        clearStaleResultIfNeeded()
    }

    func setSourceTextFromUserInput(_ text: String) {
        guard text != sourceText else { return }
        invalidateRequest()
        sourceText = text
        clearStaleResultIfNeeded()
        if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            scheduleAutoTranslate()
        }
    }

    /// Programmatic source-language change (settings apply, startup). Never
    /// re-triggers translation; use `selectSourceLanguage` for the user-facing
    /// picker.
    func setSourceLanguage(_ language: TranslationLanguage?) {
        guard language != sourceLanguage else { return }
        invalidateRequest()
        sourceLanguage = language
        clearStaleResultIfNeeded()
    }

    /// User-initiated source-language change from the panel or popover picker.
    /// Re-triggers translation when source text is already present, since the
    /// user is explicitly asking to see it translated from the new language.
    func selectSourceLanguage(_ language: TranslationLanguage?) {
        setSourceLanguage(language)
        guard language == sourceLanguage else { return }
        retranslateIfNeeded()
    }

    /// Target language has no programmatic caller today — every change comes
    /// from the user-facing picker — so it always re-triggers translation.
    func setTargetLanguage(_ language: TranslationLanguage) {
        guard language != targetLanguage else { return }
        invalidateRequest()
        targetLanguage = language
        clearStaleResultIfNeeded()
        retranslateIfNeeded()
    }

    /// Programmatic provider change from settings, credential updates, or startup resolution.
    /// Never re-triggers translation; use `selectProvider` for the user-facing picker.
    func setProviderID(_ providerID: TranslationProviderID?) {
        guard providerID != self.providerID else { return }
        invalidateRequest()
        self.providerID = providerID
        clearStaleResultIfNeeded()
        if let providerID, !TranslationPronunciationPolicy.supports(providerID) {
            onPronunciationUnsupportedProvider()
        }
    }

    /// User-initiated provider change from the panel or popover picker. Unlike
    /// `setProviderID`, this re-triggers translation when source text is already
    /// present, since the user is explicitly asking to see it in a new provider.
    /// Internal provider-refresh paths (credential changes, startup) must keep
    /// calling `setProviderID` directly so they never fire a background
    /// translation or cloud-disclosure prompt while the panel is hidden.
    func selectProvider(_ providerID: TranslationProviderID?) {
        let previous = self.providerID
        setProviderID(providerID)
        guard let providerID, providerID == self.providerID else { return }
        if providerID != previous {
            onProviderSelected?(providerID)
        }
        retranslateIfNeeded()
    }

    /// Swapping languages has no programmatic caller today — every call comes
    /// from the user-facing swap button — so it always re-triggers translation.
    func swapLanguages() {
        invalidateRequest()
        let swapped = TranslationLanguagePolicy.swapped(source: sourceLanguage, target: targetLanguage)
        sourceLanguage = swapped.source
        targetLanguage = swapped.target
        clearStaleResultIfNeeded()
        retranslateIfNeeded()
    }

    /// Explicit translate intent. Text changes never call this on their own.
    /// User-facing language and provider selection call this indirectly via
    /// `retranslateIfNeeded()`; their programmatic counterparts
    /// (`setSourceLanguage`, `setProviderID`) never do. Invalid input (blank,
    /// oversized, or an equal explicit source/target pair) is a silent no-op —
    /// callers disable the translate affordance for those states instead of
    /// surfacing an error.
    func translate() {
        cancelScheduledAutoTranslate()

        guard let providerID, let provider = providerLookup(providerID) else {
            status = .failed(.noProviderConfigured)
            return
        }
        guard let request = TranslationRequest(
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            providerID: providerID
        )
        else {
            return
        }

        activeTask?.cancel()
        generation &+= 1
        let requestGeneration = generation
        let requestProviderID = providerID
        let disclosureIdentity = (provider as? TranslationEndpointDisclosing)?.disclosureIdentity
            ?? TranslationDisclosureIdentity(providerID: providerID)
        status = .translating

        activeTask = Task { [weak self] in
            guard let self else { return }
            let proceed = await self.requestsDisclosure(disclosureIdentity)
            if Task.isCancelled {
                return
            }
            guard proceed else {
                self.finish(
                    generation: requestGeneration,
                    providerID: requestProviderID,
                    result: .failure(TranslationError.cancelled)
                )
                return
            }
            do {
                let response = try await provider.translate(request)
                self.finish(generation: requestGeneration, providerID: requestProviderID, result: .success(response))
            } catch {
                self.finish(generation: requestGeneration, providerID: requestProviderID, result: .failure(error))
            }
        }
    }

    /// Cancels any in-flight request. Callers invoke this when the feature
    /// closes (panel dismissed, popover collapsed) or the app is stopping.
    func cancelActiveTranslation() {
        cancelScheduledAutoTranslate()
        activeTask?.cancel()
        activeTask = nil
        generation &+= 1
        if status == .translating {
            status = .idle
        }
    }

    /// Clears source text and any result/error, keeping provider and language
    /// selections. Callers invoke this on panel/popover close when the user has
    /// opted out of keeping translation session state until app restart.
    func clearSession() {
        cancelActiveTranslation()
        sourceText = ""
        status = .idle
    }

    func setAutoTranslateDelay(_ delay: TimeInterval) {
        autoTranslateDelay = delay
    }

    func scheduleAutoTranslate() {
        cancelScheduledAutoTranslate()
        let delay = autoTranslateDelay
        autoTranslateTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            guard !Task.isCancelled, let self else { return }
            await MainActor.run { self.translate() }
        }
    }

    func cancelScheduledAutoTranslate() {
        autoTranslateTask?.cancel()
        autoTranslateTask = nil
    }

    private func cancelActiveInFlightTranslation() {
        activeTask?.cancel()
        activeTask = nil
        generation &+= 1
        if status == .translating {
            status = .idle
        }
    }

    private func invalidateRequest() {
        cancelScheduledAutoTranslate()
        cancelActiveInFlightTranslation()
    }

    private func retranslateIfNeeded() {
        guard !sourceText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        scheduleAutoTranslate()
    }

    private func finish(
        generation requestGeneration: Int,
        providerID: TranslationProviderID,
        result: Result<TranslationResponse, Error>
    ) {
        guard requestGeneration == generation else { return }
        switch result {
        case let .success(response):
            status = .succeeded(response)
        case let .failure(error):
            status = .failed(Self.normalize(error, providerID: providerID))
        }
    }

    private func clearStaleResultIfNeeded() {
        switch status {
        case .succeeded, .failed:
            status = .idle
        case .idle, .translating:
            break
        }
    }

    private static func normalize(_ error: Error, providerID: TranslationProviderID) -> TranslationError {
        if let translationError = error as? TranslationError {
            return translationError
        }
        if error is CancellationError {
            return .cancelled
        }
        return .providerUnavailable(provider: providerID, httpStatus: nil)
    }
}
