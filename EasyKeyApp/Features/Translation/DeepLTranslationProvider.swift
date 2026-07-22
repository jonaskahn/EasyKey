import EasyEngineCore
import Foundation

/// DeepL v2 REST adapter. Endpoint host is fixed by `TranslationOptions.DeepLEndpoint`
/// (Free or Pro) — never derived from user-supplied input — so this adapter can
/// only ever reach one of two known DeepL hosts.
struct DeepLTranslationProvider: TranslationProviding {
    private enum Host {
        static let free = URL(string: "https://api-free.deepl.com/v2/translate")!
        static let pro = URL(string: "https://api.deepl.com/v2/translate")!
        static let freeUsage = URL(string: "https://api-free.deepl.com/v2/usage")!
        static let proUsage = URL(string: "https://api.deepl.com/v2/usage")!
    }

    private static let requestTimeout: TimeInterval = 20
    private static let maxResponseBytes = 1_048_576

    private let endpoint: TranslationOptions.DeepLEndpoint
    private let credentialStore: TranslationCredentialStoring
    private let session: URLSession

    init(
        endpoint: TranslationOptions.DeepLEndpoint,
        credentialStore: TranslationCredentialStoring,
        session: URLSession = TranslationNetworkSession.ephemeral
    ) {
        self.endpoint = endpoint
        self.credentialStore = credentialStore
        self.session = session
    }

    private var translateURL: URL {
        switch endpoint {
        case .free: Host.free
        case .pro: Host.pro
        }
    }

    private var usageURL: URL {
        switch endpoint {
        case .free: Host.freeUsage
        case .pro: Host.proUsage
        }
    }

    func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        let apiKey = try resolveCredential()

        let urlRequest = Self.makeTranslateRequest(
            url: translateURL,
            apiKey: apiKey,
            request: request,
            timeout: Self.requestTimeout
        )

        let (data, response) = try await perform(urlRequest)
        try Self.validate(response: response, data: data, provider: .deepL)

        let decoded: DeepLTranslateResponse
        do {
            decoded = try JSONDecoder().decode(DeepLTranslateResponse.self, from: data)
        } catch {
            AppLog.error(.translation, "DeepL response decoding failed")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .deepL)
        }

        guard let translation = decoded.translations.first, decoded.translations.count == 1 else {
            AppLog.error(.translation, "DeepL response contained an unexpected translation count")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .deepL)
        }

        guard let detectedSource = TranslationLanguage(bcp47: translation.detectedSourceLanguage) else {
            AppLog.error(.translation, "DeepL response detected source language was empty")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .deepL)
        }
        guard !translation.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLog.error(.translation, "DeepL response translated text was empty")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .deepL)
        }

        return TranslationResponse(
            translatedText: translation.text,
            detectedSourceLanguage: detectedSource,
            providerID: .deepL
        )
    }

    /// Validates a candidate API key against DeepL's usage endpoint — a
    /// read-only, quota-free call — rather than spending a translation on
    /// verification. Accepts the key directly so a caller can validate
    /// before saving it to the credential store.
    func validateCredential(_ apiKey: String) async throws -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        var urlRequest = URLRequest(url: usageURL)
        urlRequest.httpMethod = "GET"
        urlRequest.setValue("DeepL-Auth-Key \(trimmed)", forHTTPHeaderField: "Authorization")
        urlRequest.timeoutInterval = Self.requestTimeout

        let (data, response) = try await perform(urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .deepL)
        }
        guard data.count <= Self.maxResponseBytes else {
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .deepL)
        }
        if httpResponse.statusCode == 200 {
            return true
        }
        if httpResponse.statusCode == 403 {
            return false
        }
        throw Self.mapHTTPError(status: httpResponse.statusCode, provider: .deepL)
    }

    private func resolveCredential() throws -> String {
        let stored = try credentialStore.credential(for: .deepL)
        guard let stored, !stored.isEmpty else {
            throw EasyEngineCore.TranslationError.missingCredentials(provider: .deepL)
        }
        return stored
    }

    /// `URLSession`'s async `data(for:)` surfaces Task cancellation as
    /// `URLError(.cancelled)`, not Swift's `CancellationError` — confirmed
    /// empirically, so there is no separate `CancellationError` catch here.
    private func perform(_ urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: urlRequest)
        } catch let error as URLError {
            throw Self.map(urlError: error)
        } catch {
            throw EasyEngineCore.TranslationError.providerUnavailable(provider: .deepL, httpStatus: nil)
        }
    }

    private static func makeTranslateRequest(
        url: URL,
        apiKey: String,
        request: TranslationRequest,
        timeout: TimeInterval
    ) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = timeout
        urlRequest.setValue("DeepL-Auth-Key \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body = DeepLTranslateRequestBody(
            text: [request.sourceText],
            targetLang: Self.deepLCode(for: request.targetLanguage),
            sourceLang: request.sourceLanguage.map(Self.deepLCode(for:))
        )
        urlRequest.httpBody = try? JSONEncoder().encode(body)
        return urlRequest
    }

    /// DeepL-specific language code mapping, isolated to this adapter: the
    /// shared domain model carries plain BCP-47 identifiers; DeepL expects
    /// uppercase codes on the wire.
    private static func deepLCode(for language: TranslationLanguage) -> String {
        language.identifier.uppercased()
    }

    private static func validate(response: URLResponse, data: Data, provider: TranslationProviderID) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EasyEngineCore.TranslationError.invalidResponse(provider: provider)
        }
        guard data.count <= maxResponseBytes else {
            AppLog.error(.translation, "DeepL response exceeded \(maxResponseBytes) bytes")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: provider)
        }
        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(status: httpResponse.statusCode, provider: provider)
        }
    }

    private static func mapHTTPError(status: Int, provider: TranslationProviderID) -> EasyEngineCore.TranslationError {
        switch status {
        case 403:
            return .missingCredentials(provider: provider)
        case 429, 456:
            return .rateLimitExceeded(provider: provider)
        case 413:
            return .requestTooLarge
        default:
            return .providerUnavailable(provider: provider, httpStatus: status)
        }
    }

    private static func map(urlError: URLError) -> EasyEngineCore.TranslationError {
        switch urlError.code {
        case .cancelled:
            return .cancelled
        case .timedOut:
            return .requestTimedOut
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed, .internationalRoamingOff:
            return .networkUnavailable
        default:
            return .providerUnavailable(provider: .deepL, httpStatus: nil)
        }
    }
}

private struct DeepLTranslateRequestBody: Encodable {
    let text: [String]
    let targetLang: String
    let sourceLang: String?

    enum CodingKeys: String, CodingKey {
        case text
        case targetLang = "target_lang"
        case sourceLang = "source_lang"
    }
}

private struct DeepLTranslateResponse: Decodable {
    struct Translation: Decodable {
        let detectedSourceLanguage: String
        let text: String

        enum CodingKeys: String, CodingKey {
            case detectedSourceLanguage = "detected_source_language"
            case text
        }
    }

    let translations: [Translation]
}
