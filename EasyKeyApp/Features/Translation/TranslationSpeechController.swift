import AVFoundation
import Combine
import EasyEngineCore
import Foundation

enum TranslationSpeechField: Equatable {
    case source
    case result
}

enum TranslationSpeechAvailability: Equatable {
    case available
    case emptyText
    case sourceLanguageNotDetected
    case voiceUnavailable(languageIdentifier: String)
}

enum TranslationSpeechEngineEvent: Equatable {
    case completed
    case cancelled
    case failed
}

@MainActor
protocol TranslationSpeechEngine: AnyObject {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)? { get set }
    func voiceIdentifier(for languageIdentifier: String) -> String?
    func speak(_ text: String, voiceIdentifier: String, requestID: UUID) -> Bool
    func stopSpeaking()
}

@MainActor
final class SystemTranslationSpeechEngine: NSObject, TranslationSpeechEngine, AVSpeechSynthesizerDelegate {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?

    private let synthesizer: AVSpeechSynthesizer
    private var requestIDs: [ObjectIdentifier: UUID] = [:]

    init(synthesizer: AVSpeechSynthesizer = AVSpeechSynthesizer()) {
        self.synthesizer = synthesizer
        super.init()
        synthesizer.delegate = self
    }

    func voiceIdentifier(for languageIdentifier: String) -> String? {
        AVSpeechSynthesisVoice(language: languageIdentifier)?.identifier
    }

    func speak(_ text: String, voiceIdentifier: String, requestID: UUID) -> Bool {
        guard let voice = AVSpeechSynthesisVoice(identifier: voiceIdentifier) else { return false }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = voice
        requestIDs[ObjectIdentifier(utterance)] = requestID
        synthesizer.speak(utterance)
        return true
    }

    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        finishOnMainActor(utterance, event: .completed)
    }

    nonisolated func speechSynthesizer(_: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        finishOnMainActor(utterance, event: .cancelled)
    }

    private nonisolated func finishOnMainActor(
        _ utterance: AVSpeechUtterance,
        event: TranslationSpeechEngineEvent
    ) {
        let utteranceIdentifier = ObjectIdentifier(utterance)
        Task { @MainActor [weak self] in
            self?.finish(utteranceIdentifier, event: event)
        }
    }

    private func finish(_ utteranceIdentifier: ObjectIdentifier, event: TranslationSpeechEngineEvent) {
        guard let requestID = requestIDs.removeValue(forKey: utteranceIdentifier) else { return }
        eventHandler?(requestID, event)
    }
}

@MainActor
final class TranslationSpeechController: ObservableObject, TranslationSpeechStopping {
    @Published private(set) var speakingField: TranslationSpeechField?

    private let engine: TranslationSpeechEngine
    private var activeRequestID: UUID?

    init(engine: TranslationSpeechEngine? = nil) {
        let engine = engine ?? SystemTranslationSpeechEngine()
        self.engine = engine
        engine.eventHandler = { [weak self] requestID, event in
            self?.handle(event, requestID: requestID)
        }
    }

    func sourceAvailability(
        for text: String,
        selectedLanguage: TranslationLanguage?,
        detectedLanguage: TranslationLanguage?
    ) -> TranslationSpeechAvailability {
        resolve(text: text, language: selectedLanguage ?? detectedLanguage).availability
    }

    func resultAvailability(
        for text: String,
        targetLanguage: TranslationLanguage
    ) -> TranslationSpeechAvailability {
        resolve(text: text, language: targetLanguage).availability
    }

    @discardableResult
    func speakSource(
        _ text: String,
        selectedLanguage: TranslationLanguage?,
        detectedLanguage: TranslationLanguage?
    ) -> TranslationSpeechAvailability {
        speak(text, field: .source, language: selectedLanguage ?? detectedLanguage)
    }

    @discardableResult
    func speakResult(
        _ text: String,
        targetLanguage: TranslationLanguage
    ) -> TranslationSpeechAvailability {
        speak(text, field: .result, language: targetLanguage)
    }

    func stopSpeaking() {
        activeRequestID = nil
        speakingField = nil
        engine.stopSpeaking()
    }

    private func speak(
        _ text: String,
        field: TranslationSpeechField,
        language: TranslationLanguage?
    ) -> TranslationSpeechAvailability {
        let resolution = resolve(text: text, language: language)
        guard let voiceIdentifier = resolution.voiceIdentifier else { return resolution.availability }

        if activeRequestID != nil {
            activeRequestID = nil
            speakingField = nil
            engine.stopSpeaking()
        }

        let requestID = UUID()
        activeRequestID = requestID
        speakingField = field
        guard engine.speak(text, voiceIdentifier: voiceIdentifier, requestID: requestID) else {
            activeRequestID = nil
            speakingField = nil
            return .voiceUnavailable(languageIdentifier: language?.identifier ?? "")
        }
        return .available
    }

    private func resolve(
        text: String,
        language: TranslationLanguage?
    ) -> (availability: TranslationSpeechAvailability, voiceIdentifier: String?) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return (.emptyText, nil)
        }
        guard let language else {
            return (.sourceLanguageNotDetected, nil)
        }
        guard let voiceIdentifier = engine.voiceIdentifier(for: language.identifier) else {
            return (.voiceUnavailable(languageIdentifier: language.identifier), nil)
        }
        return (.available, voiceIdentifier)
    }

    private func handle(_: TranslationSpeechEngineEvent, requestID: UUID) {
        guard requestID == activeRequestID else { return }
        activeRequestID = nil
        speakingField = nil
    }
}
