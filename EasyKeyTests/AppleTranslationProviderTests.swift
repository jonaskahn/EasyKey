import EasyEngineCore
@testable import EasyKey
import Foundation
import Translation
import XCTest

@available(macOS 15.0, *)
private final class FakeAppleTranslationSessionBridge: AppleTranslationSessionBridging, @unchecked Sendable {
    enum Behavior {
        case success(sourceLanguage: Locale.Language, targetText: String)
        case failure(Error)
    }

    var behavior: Behavior = .success(sourceLanguage: Locale.Language(identifier: "en"), targetText: "translated")
    private(set) var capturedText: String?
    private(set) var capturedSource: Locale.Language?
    private(set) var capturedTarget: Locale.Language?

    func translate(text: String, source: Locale.Language?, target: Locale.Language) async throws -> TranslationSession.Response {
        capturedText = text
        capturedSource = source
        capturedTarget = target
        switch behavior {
        case let .success(sourceLanguage, targetText):
            return TranslationSession.Response(
                sourceLanguage: sourceLanguage,
                targetLanguage: target,
                sourceText: text,
                targetText: targetText
            )
        case let .failure(error):
            throw error
        }
    }
}

@available(macOS 15.0, *)
private final class FakeAppleLanguageAvailabilityChecking: AppleLanguageAvailabilityChecking, @unchecked Sendable {
    var status: LanguageAvailability.Status = .installed
    private(set) var wasCalled = false
    private(set) var capturedSource: Locale.Language?
    private(set) var capturedTarget: Locale.Language?

    func status(from source: Locale.Language, to target: Locale.Language?) async -> LanguageAvailability.Status {
        wasCalled = true
        capturedSource = source
        capturedTarget = target
        return status
    }
}

@available(macOS 15.0, *)
final class AppleTranslationProviderTests: XCTestCase {
    private func makeRequest(
        sourceText: String = "hello",
        sourceLanguage: TranslationLanguage? = .english,
        targetLanguage: TranslationLanguage = .vietnamese
    ) throws -> TranslationRequest {
        try XCTUnwrap(TranslationRequest(
            sourceText: sourceText,
            sourceLanguage: sourceLanguage,
            targetLanguage: targetLanguage,
            providerID: .apple
        ))
    }

    func testTranslate_WithInstalledLanguagePair_ReturnsMappedResponse() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .success(sourceLanguage: Locale.Language(identifier: "en"), targetText: "xin chào")
        let availability = FakeAppleLanguageAvailabilityChecking()
        availability.status = .installed
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: availability)

        let response = try await provider.translate(makeRequest())

        XCTAssertEqual(response.translatedText, "xin chào")
        XCTAssertEqual(response.providerID, .apple)
        XCTAssertEqual(response.detectedSourceLanguage?.identifier, "en")
        XCTAssertTrue(availability.wasCalled)
        XCTAssertEqual(bridge.capturedText, "hello")
    }

    func testTranslate_WithAutoDetectSource_SkipsAvailabilityCheck() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .success(sourceLanguage: Locale.Language(identifier: "en"), targetText: "translated")
        let availability = FakeAppleLanguageAvailabilityChecking()
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: availability)

        let request = try makeRequest(sourceLanguage: nil)
        _ = try await provider.translate(request)

        XCTAssertFalse(availability.wasCalled)
        XCTAssertNil(bridge.capturedSource)
    }

    func testTranslate_WhenLanguageSupportedButNotInstalled_ThrowsDownloadRequired() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        let availability = FakeAppleLanguageAvailabilityChecking()
        availability.status = .supported
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: availability)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected appleLanguageDownloadRequired")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .appleLanguageDownloadRequired)
        }
        XCTAssertNil(bridge.capturedText, "Bridge must not be called when a download is required")
    }

    func testTranslate_WhenLanguagePairUnsupported_ThrowsUnsupportedLanguagePair() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        let availability = FakeAppleLanguageAvailabilityChecking()
        availability.status = .unsupported
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: availability)

        do {
            _ = try await provider.translate(makeRequest())
            XCTFail("Expected unsupportedLanguagePair")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .unsupportedLanguagePair(source: .english, target: .vietnamese))
        }
        XCTAssertNil(bridge.capturedText, "Bridge must not be called for an unsupported pair")
    }

    func testTranslate_WhenBridgeThrowsUnsupportedSourceLanguage_MapsToUnsupportedLanguagePair() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .failure(AppleTranslationError.unsupportedSourceLanguage)
        let availability = FakeAppleLanguageAvailabilityChecking()
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: availability)

        do {
            _ = try await provider.translate(makeRequest(sourceLanguage: nil))
            XCTFail("Expected unsupportedLanguagePair")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .unsupportedLanguagePair(source: .vietnamese, target: .vietnamese))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testTranslate_WhenBridgeThrowsUnsupportedTargetLanguage_MapsToUnsupportedLanguagePair() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .failure(AppleTranslationError.unsupportedTargetLanguage)
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: FakeAppleLanguageAvailabilityChecking())

        do {
            _ = try await provider.translate(makeRequest(sourceLanguage: nil))
            XCTFail("Expected unsupportedLanguagePair")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .unsupportedLanguagePair(source: .vietnamese, target: .vietnamese))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testTranslate_WhenBridgeThrowsUnsupportedLanguagePairing_MapsToUnsupportedLanguagePair() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .failure(AppleTranslationError.unsupportedLanguagePairing)
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: FakeAppleLanguageAvailabilityChecking())

        do {
            _ = try await provider.translate(makeRequest(sourceLanguage: nil))
            XCTFail("Expected unsupportedLanguagePair")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .unsupportedLanguagePair(source: .vietnamese, target: .vietnamese))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testTranslate_WhenBridgeThrowsCancellationError_MapsToCancelled() async throws {
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .failure(CancellationError())
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: FakeAppleLanguageAvailabilityChecking())

        do {
            _ = try await provider.translate(makeRequest(sourceLanguage: nil))
            XCTFail("Expected cancelled")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .cancelled)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testTranslate_WhenBridgeThrowsUnrecognizedError_MapsToProviderUnavailable() async throws {
        struct OtherError: Error {}
        let bridge = FakeAppleTranslationSessionBridge()
        bridge.behavior = .failure(OtherError())
        let provider = AppleTranslationProvider(bridge: bridge, languageAvailability: FakeAppleLanguageAvailabilityChecking())

        do {
            _ = try await provider.translate(makeRequest(sourceLanguage: nil))
            XCTFail("Expected providerUnavailable")
        } catch let error as EasyEngineCore.TranslationError {
            XCTAssertEqual(error, .providerUnavailable(provider: .apple, httpStatus: nil))
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testSystemLanguageAvailability_DelegatesToLanguageAvailability() async {
        let checker = SystemLanguageAvailability()
        let status = await checker.status(from: Locale.Language(identifier: "en"), to: Locale.Language(identifier: "vi"))
        XCTAssertTrue([.installed, .supported, .unsupported].contains(status))
    }
}
