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

    private func makeTranslatingModel() async -> TranslationModel {
        let provider = FakeTranslationProvider(behavior: .hang)
        let model = makeModel(provider: provider)
        model.setSourceText("hello")
        model.translate()
        await waitUntil { model.status == .translating }
        return model
    }

    func testInit_SeedsTargetFromOppositeOfInputLanguage() {
        let vietnameseInput = makeModel(inputLanguage: .vietnamese, provider: nil)
        XCTAssertEqual(vietnameseInput.targetLanguage, .english)

        let englishInput = makeModel(inputLanguage: .english, provider: nil)
        XCTAssertEqual(englishInput.targetLanguage, .vietnamese)
    }

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

    func testRequestDefiningMutationsInvalidateActiveRequest() async {
        let sourceTextModel = await makeTranslatingModel()
        sourceTextModel.setSourceText("changed")
        XCTAssertEqual(sourceTextModel.status, .idle)

        let sourceLanguageModel = await makeTranslatingModel()
        sourceLanguageModel.setSourceLanguage(.vietnamese)
        XCTAssertEqual(sourceLanguageModel.status, .idle)

        let targetLanguageModel = await makeTranslatingModel()
        targetLanguageModel.setTargetLanguage(.vietnamese)
        XCTAssertEqual(targetLanguageModel.status, .idle)
        targetLanguageModel.cancelScheduledAutoTranslate()

        let providerModel = await makeTranslatingModel()
        providerModel.setProviderID(.google)
        XCTAssertEqual(providerModel.status, .idle)

        let swapModel = await makeTranslatingModel()
        swapModel.swapLanguages()
        XCTAssertEqual(swapModel.status, .idle)
        swapModel.cancelScheduledAutoTranslate()
    }

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

    func testSetProviderID_NeverSchedulesRetranslateEvenWithSourceText() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .google)
        ))
        let model = TranslationModel(
            inputLanguage: .vietnamese,
            providerID: .deepL,
            providerLookup: { requestedID in requestedID == .google ? provider : nil }
        )
        model.setAutoTranslateDelay(0.05)
        model.setSourceText("hello")

        model.setProviderID(.google)
        try? await Task.sleep(nanoseconds: 150_000_000)

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(model.status, .idle)
    }

    func testSelectSourceLanguage_WithNonEmptySourceText_SchedulesRetranslate() async {
        let response = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.05)
        model.setSourceText("hello")

        // Target defaults to English (opposite of Vietnamese input); select a
        // different source so the pair isn't the equal-language no-op guard.
        model.selectSourceLanguage(.vietnamese)
        await waitUntil { model.status != .idle }
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .succeeded(response))
    }

    func testSetSourceLanguage_NeverSchedulesRetranslateEvenWithSourceText() async {
        let provider = FakeTranslationProvider(behavior: .success(
            TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        ))
        let model = makeModel(provider: provider)
        model.setAutoTranslateDelay(0.05)
        model.setSourceText("hello")

        model.setSourceLanguage(.english)
        try? await Task.sleep(nanoseconds: 150_000_000)

        let callCount = await provider.callCount
        XCTAssertEqual(callCount, 0)
        XCTAssertEqual(model.status, .idle)
    }

    func testSetTargetLanguage_WithNonEmptySourceText_SchedulesRetranslate() async {
        let response = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(inputLanguage: .vietnamese, provider: provider)
        model.setAutoTranslateDelay(0.05)
        model.setSourceText("hello")

        model.setTargetLanguage(.vietnamese)
        await waitUntil { model.status != .idle }
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .succeeded(response))
    }

    func testSwapLanguages_WithNonEmptySourceText_SchedulesRetranslate() async {
        let response = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(inputLanguage: .vietnamese, provider: provider)
        model.setAutoTranslateDelay(0.05)
        model.setSourceText("hello")

        // Source stays automatic (nil) and target defaults to English;
        // `swapped` is a no-op when source is nil, so the pair after
        // swapping is still (nil, English) — non-blocking, unlike the equal
        // explicit pair `testSwapLanguages_ExchangesExplicitSourceAndTarget`
        // sets up (that test never calls translate(), so it never hits the
        // equal-pair no-op guard in `TranslationRequest.init`).
        model.swapLanguages()
        await waitUntil { model.status != .idle }
        await waitUntil { model.status != .translating }

        XCTAssertEqual(model.status, .succeeded(response))
    }

    func testClearSession_EmptiesSourceTextAndResetsStatus() async {
        let response = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .deepL)
        let provider = FakeTranslationProvider(behavior: .success(response))
        let model = makeModel(provider: provider)
        model.setSourceText("hello")
        model.translate()
        await waitUntil { model.status != .translating }
        XCTAssertEqual(model.status, .succeeded(response))

        model.clearSession()

        XCTAssertEqual(model.sourceText, "")
        XCTAssertEqual(model.status, .idle)
    }

    func testClearSession_KeepsProviderAndLanguageSelections() {
        let model = makeModel(inputLanguage: .vietnamese, providerID: .deepL, provider: nil)
        model.setSourceLanguage(.english)
        model.setTargetLanguage(.english)

        model.clearSession()

        XCTAssertEqual(model.providerID, .deepL)
        XCTAssertEqual(model.sourceLanguage, .english)
        XCTAssertEqual(model.targetLanguage, .english)
    }
}
