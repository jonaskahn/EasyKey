import EasyEngineCore
import Foundation

/// Google Cloud Translation Basic (v2) adapter. URLs are fixed here and never
/// derived from settings or credential content.
struct GoogleTranslationProvider: TranslationProviding {
    private enum Endpoint {
        static let translate = validatedURL("https://translation.googleapis.com/language/translate/v2")
        static let languages = validatedURL("https://translation.googleapis.com/language/translate/v2/languages")
    }

    private static let requestTimeout: TimeInterval = 20
    private static let maxRequestBytes = 100_000
    private static let maxResponseBytes = 1_048_576

    private let credentialStore: TranslationCredentialStoring
    private let session: URLSession

    init(
        credentialStore: TranslationCredentialStoring,
        session: URLSession = TranslationNetworkSession.ephemeral
    ) {
        self.credentialStore = credentialStore
        self.session = session
    }

    nonisolated func translate(_ request: TranslationRequest) async throws -> TranslationResponse {
        let apiKey = try resolveCredential()
        let urlRequest = try Self.makeTranslateRequest(apiKey: apiKey, request: request)
        let (data, response) = try await perform(urlRequest)
        try Self.validate(response: response, data: data)

        let decoded: GoogleTranslateResponse
        do {
            decoded = try JSONDecoder().decode(GoogleTranslateResponse.self, from: data)
        } catch {
            AppLog.error(.translation, "Google response decoding failed")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }

        guard decoded.data.translations.count == 1,
              let translation = decoded.data.translations.first
        else {
            AppLog.error(.translation, "Google response contained an unexpected translation count")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }

        let translatedText = Self.decodeHTMLEntities(in: translation.translatedText)
        guard !translatedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            AppLog.error(.translation, "Google response translated text was empty")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }

        let detectedSourceLanguage: TranslationLanguage?
        if let identifier = translation.detectedSourceLanguage {
            guard let language = TranslationLanguage(bcp47: identifier) else {
                AppLog.error(.translation, "Google response detected source language was empty")
                throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
            }
            detectedSourceLanguage = language
        } else {
            detectedSourceLanguage = nil
        }

        return TranslationResponse(
            translatedText: translatedText,
            detectedSourceLanguage: detectedSourceLanguage,
            providerID: .google
        )
    }

    /// Uses Google's languages listing rather than a translation, avoiding
    /// billable source characters while still authenticating the candidate key.
    nonisolated func validateCredential(_ apiKey: String) async throws -> Bool {
        let trimmed = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }

        var urlRequest = URLRequest(url: Self.authenticatedURL(endpoint: Endpoint.languages, target: "en"))
        urlRequest.httpMethod = "GET"
        urlRequest.timeoutInterval = Self.requestTimeout
        urlRequest.setValue(trimmed, forHTTPHeaderField: "x-goog-api-key")

        let (data, response) = try await perform(urlRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }
        guard data.count <= Self.maxResponseBytes else {
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }

        switch httpResponse.statusCode {
        case 200:
            return true
        case 400, 401:
            return false
        case 403:
            if Self.googleErrorIsQuotaRelated(data) {
                throw EasyEngineCore.TranslationError.rateLimitExceeded(provider: .google)
            }
            return false
        default:
            throw Self.mapHTTPError(status: httpResponse.statusCode, data: data)
        }
    }

    private nonisolated func resolveCredential() throws -> String {
        let stored = try credentialStore.credential(for: .google)
        guard let stored else {
            throw EasyEngineCore.TranslationError.missingCredentials(provider: .google)
        }
        let trimmed = stored.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw EasyEngineCore.TranslationError.missingCredentials(provider: .google)
        }
        return trimmed
    }

    private nonisolated func perform(_ urlRequest: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: urlRequest)
        } catch is CancellationError {
            throw EasyEngineCore.TranslationError.cancelled
        } catch let error as URLError {
            throw Self.map(urlError: error)
        } catch {
            throw EasyEngineCore.TranslationError.providerUnavailable(provider: .google, httpStatus: nil)
        }
    }

    private static func makeTranslateRequest(apiKey: String, request: TranslationRequest) throws -> URLRequest {
        var urlRequest = URLRequest(url: authenticatedURL(endpoint: Endpoint.translate))
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = requestTimeout
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
        urlRequest.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")

        let body = GoogleTranslateRequestBody(
            query: request.sourceText,
            target: googleCode(for: request.targetLanguage),
            source: request.sourceLanguage.map(googleCode(for:)),
            format: "html"
        )
        let encoded = try JSONEncoder().encode(body)
        guard encoded.count <= maxRequestBytes else {
            throw EasyEngineCore.TranslationError.requestTooLarge
        }
        urlRequest.httpBody = encoded
        return urlRequest
    }

    /// `endpoint` is always one of the fixed literal `Endpoint` URLs above.
    private static func authenticatedURL(endpoint: URL, target: String? = nil) -> URL {
        guard let target else { return endpoint }
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "target", value: target)]
        return components.url!
    }

    /// Google Basic accepts lowercase ISO/BCP-47 language identifiers. Mapping
    /// remains private so provider wire conventions do not enter domain types.
    private static func googleCode(for language: TranslationLanguage) -> String {
        language.identifier.lowercased()
    }

    private static func validate(response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }
        guard data.count <= maxResponseBytes else {
            AppLog.error(.translation, "Google response exceeded byte limit")
            throw EasyEngineCore.TranslationError.invalidResponse(provider: .google)
        }
        guard httpResponse.statusCode == 200 else {
            throw mapHTTPError(status: httpResponse.statusCode, data: data)
        }
    }

    private static func mapHTTPError(status: Int, data: Data) -> EasyEngineCore.TranslationError {
        switch status {
        case 400:
            return googleErrorIsAuthenticationRelated(data)
                ? .missingCredentials(provider: .google)
                : .providerUnavailable(provider: .google, httpStatus: status)
        case 401:
            return .missingCredentials(provider: .google)
        case 403:
            return googleErrorIsQuotaRelated(data)
                ? .rateLimitExceeded(provider: .google)
                : .missingCredentials(provider: .google)
        case 413, 414:
            return .requestTooLarge
        case 429:
            return .rateLimitExceeded(provider: .google)
        default:
            return .providerUnavailable(provider: .google, httpStatus: status)
        }
    }

    private static func googleErrorIsQuotaRelated(_ data: Data) -> Bool {
        guard let response = try? JSONDecoder().decode(GoogleErrorResponse.self, from: data) else { return false }
        let quotaReasons: Set = [
            "dailyLimitExceeded",
            "quotaExceeded",
            "rateLimitExceeded",
            "userRateLimitExceeded",
        ]
        return response.error.reasons.contains { quotaReasons.contains($0) }
    }

    private static func googleErrorIsAuthenticationRelated(_ data: Data) -> Bool {
        guard let response = try? JSONDecoder().decode(GoogleErrorResponse.self, from: data) else { return false }
        let authenticationReasons: Set = ["API_KEY_INVALID", "keyInvalid"]
        return response.error.status == "UNAUTHENTICATED"
            || response.error.reasons.contains { authenticationReasons.contains($0) }
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
            return .providerUnavailable(provider: .google, httpStatus: nil)
        }
    }

    /// Decodes one API-provided HTML-entity layer without parsing markup or
    /// round-tripping through a lossy text encoding.
    private static func decodeHTMLEntities(in value: String) -> String {
        var result = ""
        var cursor = value.startIndex

        while let ampersand = value[cursor...].firstIndex(of: "&") {
            result.append(contentsOf: value[cursor ..< ampersand])
            guard let semicolon = value[ampersand...].firstIndex(of: ";") else {
                result.append(contentsOf: value[ampersand...])
                return result
            }

            let entityStart = value.index(after: ampersand)
            let entity = String(value[entityStart ..< semicolon])
            guard entity.count <= 32, let decoded = decodeEntity(entity) else {
                result.append(contentsOf: value[ampersand ... semicolon])
                cursor = value.index(after: semicolon)
                continue
            }
            result.append(decoded)
            cursor = value.index(after: semicolon)
        }

        result.append(contentsOf: value[cursor...])
        return result
    }

    private static func decodeEntity(_ entity: String) -> Character? {
        let named: [String: Character] = [
            "amp": "&",
            "apos": "'",
            "gt": ">",
            "lt": "<",
            "nbsp": "\u{00A0}",
            "quot": "\"",
        ]
        if let character = named[entity] {
            return character
        }

        let number: UInt32?
        if entity.hasPrefix("#x") || entity.hasPrefix("#X") {
            number = UInt32(entity.dropFirst(2), radix: 16)
        } else if entity.hasPrefix("#") {
            number = UInt32(entity.dropFirst())
        } else {
            number = nil
        }
        guard let number, let scalar = UnicodeScalar(number) else { return nil }
        return Character(scalar)
    }
}

private struct GoogleTranslateRequestBody: Encodable {
    let query: String
    let target: String
    let source: String?
    let format: String

    enum CodingKeys: String, CodingKey {
        case query = "q"
        case target
        case source
        case format
    }
}

private struct GoogleTranslateResponse: Decodable {
    struct ResponseData: Decodable {
        let translations: [Translation]
    }

    struct Translation: Decodable {
        let translatedText: String
        let detectedSourceLanguage: String?
    }

    let data: ResponseData
}

private struct GoogleErrorResponse: Decodable {
    struct ErrorBody: Decodable {
        let errors: [ErrorDetail]?
        let details: [ErrorDetail]?
        let status: String?

        var reasons: [String] {
            (errors ?? []).compactMap(\.reason) + (details ?? []).compactMap(\.reason)
        }
    }

    struct ErrorDetail: Decodable {
        let reason: String?
    }

    let error: ErrorBody
}
