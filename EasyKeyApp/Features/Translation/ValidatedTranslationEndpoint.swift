import EasyEngineCore
import Foundation

struct ValidatedTranslationEndpoint: Equatable, Sendable {
    let url: URL
    let origin: String

    init?(_ url: URL) {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              components.scheme?.lowercased() == "https",
              let host = components.host?.lowercased(),
              !host.isEmpty,
              components.user == nil,
              components.password == nil,
              HostSafety.validate(host: host)
        else { return nil }

        components.scheme = "https"
        components.host = host
        if components.port == 443 {
            components.port = nil
        }
        guard let normalizedURL = components.url else { return nil }

        var originComponents = URLComponents()
        originComponents.scheme = "https"
        originComponents.host = host
        originComponents.port = components.port
        guard let normalizedOrigin = originComponents.url?.absoluteString else { return nil }

        self.url = normalizedURL
        origin = normalizedOrigin
    }

    init?(_ value: String) {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let url = URL(string: trimmed) else { return nil }
        self.init(url)
    }
}

func validatedURL(_ string: String, file: StaticString = #file, line: UInt = #line) -> URL {
    guard let url = URL(string: string) else {
        preconditionFailure("Invalid URL constant at \(file):\(line): \(string)", file: file, line: line)
    }
    return url
}
