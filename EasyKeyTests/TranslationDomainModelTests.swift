@testable import EasyEngineCore
import XCTest

final class TranslationDomainModelTests: XCTestCase {
    // MARK: - TranslationLanguage

    func testBcp47_TrimsWhitespaceAndStoresIdentifier() {
        let language = TranslationLanguage(bcp47: "  fr  ")
        XCTAssertEqual(language?.identifier, "fr")
    }

    func testBcp47_RejectsEmptyIdentifier() {
        XCTAssertNil(TranslationLanguage(bcp47: ""))
        XCTAssertNil(TranslationLanguage(bcp47: "   "))
    }

    func testWellKnownLanguages_HaveExpectedIdentifiers() {
        XCTAssertEqual(TranslationLanguage.english.identifier, "en")
        XCTAssertEqual(TranslationLanguage.vietnamese.identifier, "vi")
    }

    func testLanguage_EqualityIsByIdentifier() {
        XCTAssertEqual(TranslationLanguage(bcp47: "en"), TranslationLanguage.english)
        XCTAssertNotEqual(TranslationLanguage.english, TranslationLanguage.vietnamese)
    }

    func testLanguage_CodingRoundTripsAsPlainString() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let encoded = try encoder.encode(TranslationLanguage.vietnamese)
        XCTAssertEqual(String(data: encoded, encoding: .utf8), "\"vi\"")
        let decoded = try decoder.decode(TranslationLanguage.self, from: encoded)
        XCTAssertEqual(decoded, .vietnamese)
    }

    func testLanguage_DecodingRejectsEmptyIdentifier() {
        let decoder = JSONDecoder()
        let data = Data("\"\"".utf8)
        XCTAssertThrowsError(try decoder.decode(TranslationLanguage.self, from: data))
    }

    func testLanguage_DecodingAcceptsUnicodeRegionSubtag() throws {
        let decoder = JSONDecoder()
        let data = Data("\"zh-Hans\"".utf8)
        let decoded = try decoder.decode(TranslationLanguage.self, from: data)
        XCTAssertEqual(decoded.identifier, "zh-Hans")
    }

    // MARK: - SupportedLanguages

    func testSupportedLanguages_ContainsEnglishAndVietnamese() {
        XCTAssertTrue(SupportedLanguages.contains(.english))
        XCTAssertTrue(SupportedLanguages.contains(.vietnamese))
    }

    func testSupportedLanguages_ExcludesUnlistedLanguage() throws {
        let unlisted = TranslationLanguage(bcp47: "xx-not-real")
        XCTAssertNotNil(unlisted)
        XCTAssertFalse(try SupportedLanguages.contains(XCTUnwrap(unlisted)))
    }

    func testSupportedLanguages_HasNoDuplicates() {
        let identifiers = SupportedLanguages.all.map(\.identifier)
        XCTAssertEqual(identifiers.count, Set(identifiers).count)
    }

    // MARK: - TranslationLanguagePolicy swap

    func testSwapped_WithExplicitSource_ExchangesLanguages() {
        let result = TranslationLanguagePolicy.swapped(source: .english, target: .vietnamese)
        XCTAssertEqual(result.source, .vietnamese)
        XCTAssertEqual(result.target, .english)
    }

    func testSwapped_WithAutomaticSource_ReturnsUnchanged() {
        let result = TranslationLanguagePolicy.swapped(source: nil, target: .vietnamese)
        XCTAssertNil(result.source)
        XCTAssertEqual(result.target, .vietnamese)
    }

    // MARK: - TranslationLanguagePolicy default target

    func testDefaultTarget_ForVietnameseInput_IsEnglish() {
        XCTAssertEqual(TranslationLanguagePolicy.defaultTarget(forInput: .vietnamese), .english)
    }

    func testDefaultTarget_ForEnglishInput_IsVietnamese() {
        XCTAssertEqual(TranslationLanguagePolicy.defaultTarget(forInput: .english), .vietnamese)
    }

    // MARK: - TranslationRequest validation

    func testRequestInit_WithValidInputs_Succeeds() {
        let request = TranslationRequest(
            sourceText: "hello",
            sourceLanguage: nil,
            targetLanguage: .vietnamese,
            providerID: .automatic
        )
        XCTAssertNotNil(request)
        XCTAssertEqual(request?.sourceText, "hello")
    }

    func testRequestInit_TrimsSourceText() {
        let request = TranslationRequest(
            sourceText: "  hello world  ",
            sourceLanguage: nil,
            targetLanguage: .vietnamese,
            providerID: .automatic
        )
        XCTAssertEqual(request?.sourceText, "hello world")
    }

    func testRequestInit_RejectsBlankText() {
        let request = TranslationRequest(
            sourceText: "   ",
            sourceLanguage: nil,
            targetLanguage: .vietnamese,
            providerID: .automatic
        )
        XCTAssertNil(request)
    }

    func testRequestInit_RejectsEmptyText() {
        let request = TranslationRequest(
            sourceText: "",
            sourceLanguage: nil,
            targetLanguage: .vietnamese,
            providerID: .automatic
        )
        XCTAssertNil(request)
    }

    func testRequestInit_RejectsOversizedText() {
        let oversized = String(repeating: "a", count: TranslationRequest.maximumSourceTextLength + 1)
        let request = TranslationRequest(
            sourceText: oversized,
            sourceLanguage: nil,
            targetLanguage: .vietnamese,
            providerID: .automatic
        )
        XCTAssertNil(request)
    }

    func testRequestInit_AcceptsTextAtMaximumLength() {
        let maximal = String(repeating: "a", count: TranslationRequest.maximumSourceTextLength)
        let request = TranslationRequest(
            sourceText: maximal,
            sourceLanguage: nil,
            targetLanguage: .vietnamese,
            providerID: .automatic
        )
        XCTAssertNotNil(request)
    }

    func testRequestInit_RejectsEqualExplicitSourceAndTarget() {
        let request = TranslationRequest(
            sourceText: "hello",
            sourceLanguage: .english,
            targetLanguage: .english,
            providerID: .automatic
        )
        XCTAssertNil(request)
    }

    func testRequestInit_AllowsAutomaticSourceEqualToTargetIdentifier() {
        // Automatic detection (nil source) never collides with an explicit target,
        // even when the eventual detected language could match the target.
        let request = TranslationRequest(
            sourceText: "hello",
            sourceLanguage: nil,
            targetLanguage: .english,
            providerID: .automatic
        )
        XCTAssertNotNil(request)
    }

    func testRequestInit_AcceptsUnicodeSourceText() {
        let request = TranslationRequest(
            sourceText: "Xin chào 👋 thế giới",
            sourceLanguage: nil,
            targetLanguage: .english,
            providerID: .automatic
        )
        XCTAssertEqual(request?.sourceText, "Xin chào 👋 thế giới")
    }

    // MARK: - TranslationResponse

    func testResponse_StoresProvidedValues() {
        let response = TranslationResponse(
            translatedText: "hello",
            detectedSourceLanguage: .vietnamese,
            providerID: .deepL
        )
        XCTAssertEqual(response.translatedText, "hello")
        XCTAssertEqual(response.detectedSourceLanguage, .vietnamese)
        XCTAssertEqual(response.providerID, .deepL)
    }

    func testResponse_Equality() {
        let first = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .google)
        let second = TranslationResponse(translatedText: "hi", detectedSourceLanguage: nil, providerID: .google)
        XCTAssertEqual(first, second)
    }

    // MARK: - TranslationError

    func testError_EqualityComparesAssociatedValues() {
        XCTAssertEqual(
            TranslationError.missingCredentials(provider: .deepL),
            TranslationError.missingCredentials(provider: .deepL)
        )
        XCTAssertNotEqual(
            TranslationError.missingCredentials(provider: .deepL),
            TranslationError.missingCredentials(provider: .google)
        )
    }

    func testError_ProviderUnavailableCarriesOptionalHTTPStatus() {
        let withStatus = TranslationError.providerUnavailable(provider: .openAI, httpStatus: 503)
        let withoutStatus = TranslationError.providerUnavailable(provider: .openAI, httpStatus: nil)
        XCTAssertNotEqual(withStatus, withoutStatus)
    }

    // MARK: - TranslationProviderID

    func testProviderID_AllCasesAreCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        for provider in TranslationProviderID.allCases {
            let encoded = try encoder.encode(provider)
            let decoded = try decoder.decode(TranslationProviderID.self, from: encoded)
            XCTAssertEqual(decoded, provider)
        }
    }
}
