import EasyEngineCore
@testable import EasyKey
import XCTest

@MainActor
private final class FakeTranslationSpeechEngine: TranslationSpeechEngine {
    struct Start: Equatable {
        let text: String
        let voiceIdentifier: String
        let requestID: UUID
    }

    var eventHandler: ((UUID, TranslationSpeechEngineEvent) -> Void)?
    var voices: [String: String] = [:]
    var acceptsStart = true
    private(set) var starts: [Start] = []
    private(set) var events: [String] = []
    private(set) var stopCount = 0
    private(set) var activeRequestIDs: Set<UUID> = []
    private(set) var maximumActiveCount = 0

    func voiceIdentifier(for languageIdentifier: String) -> String? {
        voices[languageIdentifier]
    }

    func speak(_ text: String, voiceIdentifier: String, requestID: UUID) -> Bool {
        events.append("start")
        guard acceptsStart else { return false }
        starts.append(Start(text: text, voiceIdentifier: voiceIdentifier, requestID: requestID))
        activeRequestIDs.insert(requestID)
        maximumActiveCount = max(maximumActiveCount, activeRequestIDs.count)
        return true
    }

    func stopSpeaking() {
        events.append("stop")
        stopCount += 1
        activeRequestIDs.removeAll()
    }

    func send(_ event: TranslationSpeechEngineEvent, for requestID: UUID) {
        activeRequestIDs.remove(requestID)
        eventHandler?(requestID, event)
    }
}

@MainActor
final class TranslationSpeechControllerTests: XCTestCase {
    private var engine: FakeTranslationSpeechEngine!
    private var controller: TranslationSpeechController!

    override func setUp() {
        engine = FakeTranslationSpeechEngine()
        engine.voices = ["en": "voice.en", "vi": "voice.vi"]
        controller = TranslationSpeechController(engine: engine)
    }

    override func tearDown() {
        controller.stopSpeaking()
        controller = nil
        engine = nil
    }

    func testBlankTextIsUnavailableAndSpeakIsNoOp() {
        XCTAssertEqual(
            controller.sourceAvailability(
                for: " \n ",
                selectedLanguage: .english,
                detectedLanguage: nil
            ),
            .emptyText
        )

        XCTAssertEqual(
            controller.speakSource(" \n ", selectedLanguage: .english, detectedLanguage: nil),
            .emptyText
        )
        XCTAssertTrue(engine.starts.isEmpty)
        XCTAssertNil(controller.speakingField)
    }

    func testAutomaticSourceRequiresDetectedLanguage() {
        XCTAssertEqual(
            controller.sourceAvailability(for: "Hello", selectedLanguage: nil, detectedLanguage: nil),
            .sourceLanguageNotDetected
        )
        XCTAssertEqual(
            controller.speakSource("Hello", selectedLanguage: nil, detectedLanguage: nil),
            .sourceLanguageNotDetected
        )
        XCTAssertTrue(engine.starts.isEmpty)
    }

    func testUnavailableVoiceIncludesLanguageForActionableState() throws {
        let language = try XCTUnwrap(TranslationLanguage(bcp47: "fr-CA"))

        XCTAssertEqual(
            controller.resultAvailability(for: "Bonjour", targetLanguage: language),
            .voiceUnavailable(languageIdentifier: "fr-CA")
        )
        XCTAssertEqual(
            controller.speakResult("Bonjour", targetLanguage: language),
            .voiceUnavailable(languageIdentifier: "fr-CA")
        )
        XCTAssertTrue(engine.starts.isEmpty)
    }

    func testAutomaticSourceUsesDetectedLanguageVoice() throws {
        XCTAssertEqual(
            controller.speakSource("Xin chao", selectedLanguage: nil, detectedLanguage: .vietnamese),
            .available
        )

        let start = try XCTUnwrap(engine.starts.first)
        XCTAssertEqual(start.voiceIdentifier, "voice.vi")
        XCTAssertEqual(controller.speakingField, .source)
    }

    func testExplicitSourceLanguageTakesPriorityOverDetectedLanguage() throws {
        controller.speakSource("Hello", selectedLanguage: .english, detectedLanguage: .vietnamese)

        XCTAssertEqual(try XCTUnwrap(engine.starts.first).voiceIdentifier, "voice.en")
    }

    func testResultUsesTargetLanguageVoice() throws {
        XCTAssertEqual(controller.speakResult("Hello", targetLanguage: .english), .available)

        XCTAssertEqual(try XCTUnwrap(engine.starts.first).voiceIdentifier, "voice.en")
        XCTAssertEqual(controller.speakingField, .result)
    }

    func testStartingSecondUtteranceStopsFirstBeforeStartingReplacement() {
        controller.speakSource("Hello", selectedLanguage: .english, detectedLanguage: nil)
        controller.speakResult("Xin chao", targetLanguage: .vietnamese)

        XCTAssertEqual(engine.events, ["start", "stop", "start"])
        XCTAssertEqual(engine.stopCount, 1)
        XCTAssertEqual(engine.maximumActiveCount, 1)
        XCTAssertEqual(controller.speakingField, .result)
    }

    func testExplicitStopCancelsEngineAndReturnsToIdle() {
        controller.speakResult("Hello", targetLanguage: .english)

        controller.stopSpeaking()

        XCTAssertEqual(engine.stopCount, 1)
        XCTAssertNil(controller.speakingField)
    }

    func testCompletionReturnsToIdle() throws {
        controller.speakResult("Hello", targetLanguage: .english)

        try engine.send(.completed, for: XCTUnwrap(engine.starts.first).requestID)

        XCTAssertNil(controller.speakingField)
    }

    func testFailureReturnsToIdle() throws {
        controller.speakResult("Hello", targetLanguage: .english)

        try engine.send(.failed, for: XCTUnwrap(engine.starts.first).requestID)

        XCTAssertNil(controller.speakingField)
    }

    func testCancellationReturnsToIdle() throws {
        controller.speakResult("Hello", targetLanguage: .english)

        try engine.send(.cancelled, for: XCTUnwrap(engine.starts.first).requestID)

        XCTAssertNil(controller.speakingField)
    }

    func testLateCompletionFromReplacedSpeechDoesNotClearReplacement() throws {
        controller.speakSource("Hello", selectedLanguage: .english, detectedLanguage: nil)
        let firstRequestID = try XCTUnwrap(engine.starts.first).requestID
        controller.speakResult("Xin chao", targetLanguage: .vietnamese)

        engine.send(.cancelled, for: firstRequestID)

        XCTAssertEqual(controller.speakingField, .result)
    }

    func testRejectedEngineStartReturnsUnavailableAndIdle() {
        engine.acceptsStart = false

        XCTAssertEqual(
            controller.speakResult("Hello", targetLanguage: .english),
            .voiceUnavailable(languageIdentifier: "en")
        )
        XCTAssertNil(controller.speakingField)
    }

    func testAppStopUsesSameCancellationBoundary() {
        controller.speakResult("Hello", targetLanguage: .english)

        let appStopper: TranslationSpeechStopping = controller
        appStopper.stopSpeaking()

        XCTAssertEqual(engine.stopCount, 1)
        XCTAssertNil(controller.speakingField)
    }
}
