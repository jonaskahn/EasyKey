import EasyEngineCore
@testable import EasyKey
import XCTest

private struct SpokenRequest {
    let text: String
    let voiceIdentifier: String
    let requestID: UUID
}

@MainActor
private final class FakeTranslationSpeechEngine: TranslationSpeechEngine {
    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?
    private(set) var stopped = false
    private(set) var spokenRequests: [SpokenRequest] = []
    var nextResult = true
    var nextVoiceIdentifier: String? = "fake-voice"

    func voiceIdentifier(for _: String) -> String? {
        nextVoiceIdentifier
    }

    func speak(_ text: String, voiceIdentifier: String, requestID: UUID) -> Bool {
        spokenRequests.append(SpokenRequest(text: text, voiceIdentifier: voiceIdentifier, requestID: requestID))
        return nextResult
    }

    func stopSpeaking() {
        stopped = true
    }

    func finish(requestID: UUID, event: TranslationSpeechEngineEvent) {
        eventHandler?(requestID, event)
    }
}

@MainActor
final class TranslationSpeechControllerTests: XCTestCase {
    private var engine: FakeTranslationSpeechEngine!
    private var controller: TranslationSpeechController!

    override func setUp() {
        engine = FakeTranslationSpeechEngine()
        controller = TranslationSpeechController(engine: engine)
    }

    func testSourceAvailability_EmptyText_ReturnsEmpty() {
        let result = controller.sourceAvailability(for: "   ", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertEqual(result, .emptyText)
    }

    func testSourceAvailability_NoLanguage_ReturnsNotDetected() {
        let result = controller.sourceAvailability(for: "hello", selectedLanguage: nil, detectedLanguage: nil)
        XCTAssertEqual(result, .sourceLanguageNotDetected)
    }

    func testSourceAvailability_NoVoice_ReturnsUnavailable() {
        engine.nextVoiceIdentifier = nil
        let result = controller.sourceAvailability(for: "hello", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertEqual(result, .voiceUnavailable(languageIdentifier: "en"))
    }

    func testSourceAvailability_Available_ReturnsAvailable() {
        let result = controller.sourceAvailability(for: "hello", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertEqual(result, .available)
    }

    func testResultAvailability_EmptyText_ReturnsEmpty() {
        let result = controller.resultAvailability(for: "   ", targetLanguage: .vietnamese)
        XCTAssertEqual(result, .emptyText)
    }

    func testResultAvailability_NoVoice_ReturnsUnavailable() {
        engine.nextVoiceIdentifier = nil
        let result = controller.resultAvailability(for: "xin chào", targetLanguage: .vietnamese)
        XCTAssertEqual(result, .voiceUnavailable(languageIdentifier: "vi"))
    }

    func testSpeakSource_Success_SetsSpeakingField() {
        let result = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertEqual(result, .available)
        XCTAssertEqual(controller.speakingField, .source)
    }

    func testSpeakResult_Success_SetsSpeakingField() {
        let result = controller.speakResult("xin chào", targetLanguage: .vietnamese)
        XCTAssertEqual(result, .available)
        XCTAssertEqual(controller.speakingField, .result)
    }

    func testSpeak_WhenAlreadySpeaking_StopsPreviousAndStartsNew() {
        _ = controller.speakSource("first", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertFalse(engine.stopped)
        let result = controller.speakResult("second", targetLanguage: .vietnamese)
        XCTAssertEqual(result, .available)
        XCTAssertTrue(engine.stopped)
        XCTAssertEqual(engine.spokenRequests.count, 2)
    }

    func testSpeak_EngineReturnsFalse_ClearsState() {
        engine.nextResult = false
        let result = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertEqual(result, .voiceUnavailable(languageIdentifier: "en"))
        XCTAssertNil(controller.speakingField)
    }

    func testStopSpeaking_ClearsState() {
        _ = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        controller.stopSpeaking()
        XCTAssertTrue(engine.stopped)
        XCTAssertNil(controller.speakingField)
    }

    func testHandleEvent_WhenMatchingRequestID_ClearsState() throws {
        _ = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        XCTAssertNotNil(controller.speakingField)
        let requestID = try XCTUnwrap(engine.spokenRequests.last?.requestID)
        engine.finish(requestID: requestID, event: .completed)
        XCTAssertNil(controller.speakingField)
    }

    func testHandleEvent_WhenMismatchedRequestID_Ignores() {
        _ = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        engine.finish(requestID: UUID(), event: .completed)
        XCTAssertEqual(controller.speakingField, .source)
    }

    func testHandleEvent_Cancelled_ClearsState() throws {
        _ = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        let requestID = try XCTUnwrap(engine.spokenRequests.last?.requestID)
        engine.finish(requestID: requestID, event: .cancelled)
        XCTAssertNil(controller.speakingField)
    }

    func testHandleEvent_Failed_ClearsState() throws {
        _ = controller.speakSource("hello", selectedLanguage: .english, detectedLanguage: nil)
        let requestID = try XCTUnwrap(engine.spokenRequests.last?.requestID)
        engine.finish(requestID: requestID, event: .failed)
        XCTAssertNil(controller.speakingField)
    }

    func testDefaultEngine() {
        let controller = TranslationSpeechController()
        XCTAssertNotNil(controller)
    }
}
