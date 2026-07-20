import EasyEngineCore
@testable import EasyKey
import XCTest

private actor FakeTranslationProvider: TranslationProviding {
    enum Behavior {
        case success(TranslationResponse)
        case failure(Error)
        case hang
    }

    private(set) var callCount = 0
    private(set) var lastRequest: TranslationRequest?
    private let behavior: Behavior

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        callCount += 1
        lastRequest = request
        switch behavior {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        case .hang:
            try await Task.sleep(nanoseconds: 3_600_000_000_000)
            throw CancellationError()
        }
    }
}

@MainActor
final class TranslationModelTests: XCTestCase {
    private func makeModel(
        inputLanguage: InputLanguage = .vietnamese,
        providerID: TranslationProviderID? = .deepL,
        provider: FakeTranslationProvider?,
        requestsDisclosure: @escaping TranslationDisclosureDecision = { _ in true }
    ) -> TranslationModel {
        TranslationModel(
            inputLanguage: inputLanguage,
            providerID: providerID,
            providerLookup: { [provider] requestedID in
                requestedID == providerID ? provider : nil
            },
            requestsDisclosure: requestsDisclosure
        )
    }

    private func waitUntil(
        _ condition: @escaping () -> Bool,
        timeout: TimeInterval = 2.0,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        XCTAssertTrue(condition(), "Condition not met before timeout", file: file, line: line)
    }

    // MARK: - Initialization

    func testInit_SeedsTargetFromOppositeOfInputLanguage() {
        let vietnameseInput = makeModel(inputLanguage: .vietnamese, provider: nil)
        XCTAssertEqual(vietnameseInput.targetLanguage, .english)

        let englishInput = makeModel(inputLanguage: .english, provider: nil)
        XCTAssertEqual(englishInput.targetLanguage, .vietnamese)
    }

    // MARK: - No automatic requests

    func testSettingSourceText_NeverInvokesProvider() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)

        model.setSourceText("a")
        model.setSourceText("ab")
        model.setSourceText("abc")

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(model.status, .idle)
    }

    // MARK: - Validation no-ops

    func testTranslate_WithBlankInput_IsNoOp() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)
        model.setSourceText("   ")

        model.translate()

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(model.status, .idle)
    }

    func testTranslate_WithEqualExplicitSourceAndTarget_IsNoOp() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)
        model.setSourceText("hello")
        model.setSourceLanguage(.english)
        model.setTargetLanguage(.english)

        model.translate()

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(model.status, .idle)
    }

    // MARK: - Provider setup state

    func testTranslate_WithNoProviderID_FailsWithNoProviderConfigured() {
        let model = makeModel(providerID: nil, provider: nil)
        model.setSourceText("hello")

        model.translate()

        XCTAssertEqual(model.status, .failed(.noProviderConfigured))
    }

    func testTranslate_WhenProviderLookupReturnsNil_FailsWithNoProviderConfigured() {
        // providerID is set, but the lookup cannot construct an adapter (e.g. removed credentials).
        let model = TranslationModel(
            inputLanguage: .vietnamese,
            providerID: .deepL,
            providerLookup: { _ in nil }
        )
        model.setSourceText("hello")

        model.translate()

        XCTAssertEqual(model.status, .failed(.noProviderConfigured))
    }

    // MARK: - Disclosure

    func testTranslate_WhenDisclosureDeclined_FailsWithCancelledAndNeverCallsProvider() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider, requestsDisclosure: { _ in false })
        model.setSourceText("hello")

        model.translate()
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .failed(.cancelled))
        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
    }

    // MARK: - Success and provider error propagation

    func testTranslate_OnSuccess_PublishesSucceededStatus() async {
        let response = TranslationResponse(translatedText: "xin chào", detectedSourceLanguage: .english, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setSourceText("hello")

        model.translate()
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .succeeded(response))
    }

    func testTranslate_OnUnsupportedLanguagePair_PublishesFailedStatusWithProviderError() async {
        let provider = FakeTranslationProvider(
            behavior: .failure(TranslationError.unsupportedLanguagePair(source: .english, target: .vietnamese))
        )
        let model = makeModel(provider: provider)
        model.setSourceText("hello")

        model.translate()
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .failed(.unsupportedLanguagePair(source: .english, target: .vietnamese)))
    }

    func testTranslate_OnUnknownThrownError_NormalizesToProviderUnavailable() async {
        struct OpaqueError: Error {}
        let provider = FakeTranslationProvider(behavior: .failure(OpaqueError()))
        let model = makeModel(providerID: .google, provider: provider)
        model.setSourceText("hello")

        model.translate()
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .failed(.providerUnavailable(provider: .google, httpStatus: nil)))
    }

    func testTranslate_OnCancellationErrorFromProvider_NormalizesToCancelled() async {
        let provider = FakeTranslationProvider(behavior: .failure(CancellationError()))
        let model = makeModel(provider: provider)
        model.setSourceText("hello")

        model.translate()
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .failed(.cancelled))
    }

    // MARK: - Cancellation and stale-response rejection

    func testTranslate_CancelsPriorRequestWhenNewOneStarts() async {
        let freshResponse = TranslationResponse(translatedText: "fresh", detectedSourceLanguage: nil, providerID: .google)
        let hangingProvider = FakeTranslationProvider(behavior: .hang)
        let freshProvider = FakeTranslationProvider(behavior: .success(freshResponse))

        let model = TranslationModel(
            inputLanguage: .vietnamese,
            providerID: .deepL,
            providerLookup: { requestedID in
                switch requestedID {
                case .deepL: return hangingProvider
                case .google: return freshProvider
                default: return nil
                }
            }
        )
        model.setSourceText("hello")
        model.translate()
        await waitUntil { model.status == .translating }

        model.setProviderID(.google)
        model.translate()
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .succeeded(freshResponse))
    }

    func testCancelActiveTranslation_ResetsTranslatingStatusToIdle() async {
        let provider = FakeTranslationProvider(behavior: .hang)
        let model = makeModel(provider: provider)
        model.setSourceText("hello")

        model.translate()
        await waitUntil { model.status == .translating }
        model.cancelActiveTranslation()

        XCTAssertEqual(model.status, .idle)
    }

    func testCancelActiveTranslation_PreventsLateResponseFromApplying() async {
        let response = TranslationResponse(translatedText: "late", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setSourceText("hello")

        model.translate()
        model.cancelActiveTranslation()
        // Give the already-scheduled task a chance to run to completion.
        try? await Task.sleep(nanoseconds: 20_000_000)

        XCTAssertEqual(model.status, .idle)
    }

    // MARK: - Swap and manual target persistence

    func testSwapLanguages_ExchangesExplicitSourceAndTarget() {
        let model = makeModel(inputLanguage: .vietnamese, provider: nil)
        model.setSourceLanguage(.english)
        XCTAssertEqual(model.targetLanguage, .english)

        model.swapLanguages()

        XCTAssertEqual(model.sourceLanguage, .english)
        XCTAssertEqual(model.targetLanguage, .english)
    }

    func testManualTargetSelection_PersistsAcrossUnrelatedTextChanges() {
        let model = makeModel(inputLanguage: .vietnamese, provider: nil)
        XCTAssertEqual(model.targetLanguage, .english)

        model.setTargetLanguage(.vietnamese)
        model.setSourceText("a")
        model.setSourceText("ab")

        XCTAssertEqual(model.targetLanguage, .vietnamese)
    }

    // MARK: - Stale result clearing

    func testMeaningfulTextChange_ClearsSucceededResult() async {
        let response = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setSourceText("hello")
        model.translate()
        await waitUntil { model.status != .translating }
        XCTAssertEqual(model.status, .succeeded(response))

        model.setSourceText("hello again")

        XCTAssertEqual(model.status, .idle)
    }

    func testProviderChange_ClearsFailedResult() async {
        let provider = FakeTranslationProvider(behavior: .failure(TranslationError.requestTooLarge))
        let model = makeModel(providerID: .deepL, provider: provider)
        model.setSourceText("hello")
        model.translate()
        await waitUntil { model.status != .translating }
        XCTAssertEqual(model.status, .failed(.requestTooLarge))

        model.setProviderID(.google)

        XCTAssertEqual(model.status, .idle)
    }

    func testUnsupportedProviderChangeRequestsSpeechStop() {
        var stopCount = 0
        let model = TranslationModel(
            inputLanguage: .english,
            providerID: .apple,
            providerLookup: { _ in nil },
            onPronunciationUnsupportedProvider: { stopCount += 1 }
        )

        model.setProviderID(.deepL)
        model.setProviderID(.openAI)
        model.setProviderID(.google)

        XCTAssertEqual(stopCount, 2)
    }

    // MARK: - User-input auto-translate

    func testUserInput_AutoTranslatesAfterConfiguredDelay() async {
        let response = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.05)

        model.setSourceTextFromUserInput("hello")
        await waitUntil { model.status != .idle }
        await waitUntil { model.status != .translating }

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 1)
        let lastRequest = await provider.lastRequest
        XCTAssertEqual(lastRequest?.sourceText, "hello")
    }

    func testUserInput_RapidEditsDebounceToLatestText() async {
        let response = TranslationResponse(translatedText: "final", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.15)

        model.setSourceTextFromUserInput("a")
        model.setSourceTextFromUserInput("ab")
        model.setSourceTextFromUserInput("abc")
        model.setSourceTextFromUserInput("final")

        await waitUntil { model.status != .idle }
        await waitUntil { model.status != .translating }

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 1)
        let lastRequest = await provider.lastRequest
        XCTAssertEqual(lastRequest?.sourceText, "final")
    }

    func testProgrammaticSetSourceText_DoesNotAutoTranslate() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.05)

        model.setSourceText("hello")
        try? await Task.sleep(nanoseconds: 150_000_000)

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(model.status, .idle)
    }

    func testImmediateTranslate_CancelsPendingDebounce() async {
        let response = TranslationResponse(translatedText: "immediate", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.3)

        model.setSourceTextFromUserInput("immediate")
        model.translate()
        await waitUntil { model.status != .translating }

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 1)
        let lastRequest = await provider.lastRequest
        XCTAssertEqual(lastRequest?.sourceText, "immediate")

        try? await Task.sleep(nanoseconds: 400_000_000)
        let finalCallCount = await provider.callCount
        XCTAssertEqual(finalCallCount, 1)
    }

    func testUserEdit_CancelsInFlightStaleTranslation() async {
        let hangingProvider = FakeTranslationProvider(behavior: .hang)
        let freshResponse = TranslationResponse(translatedText: "fresh", detectedSourceLanguage: nil, providerID: .google)
        let freshProvider = FakeTranslationProvider(behavior: .success(freshResponse))

        let model = TranslationModel(
            inputLanguage: .vietnamese,
            providerID: .deepL,
            providerLookup: { requestedID in
                switch requestedID {
                case .deepL: return hangingProvider
                case .google: return freshProvider
                default: return nil
                }
            },
            requestsDisclosure: { _ in true }
        )
        model.setAutoTranslateDelay(0.05)

        model.setSourceTextFromUserInput("stale")
        await waitUntil { model.status == .translating }

        model.setProviderID(.google)
        model.setSourceTextFromUserInput("fresh")
        await waitUntil { model.status != .idle }
        await waitUntil { model.status != .translating }

        let callCount = await freshProvider.callCount
        XCTAssertEqual(callCount, 1)
        let lastRequest = await freshProvider.lastRequest
        XCTAssertEqual(lastRequest?.sourceText, "fresh")
    }

    func testBlankUserInput_DoesNotScheduleRequest() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.05)

        model.setSourceTextFromUserInput("   ")
        try? await Task.sleep(nanoseconds: 150_000_000)

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
    }

    func testSetSourceTextFromUserInput_NoOpForIdenticalText() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.05)

        model.setSourceTextFromUserInput("same")
        model.setSourceTextFromUserInput("same")

        try? await Task.sleep(nanoseconds: 150_000_000)

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 1)
    }
}
