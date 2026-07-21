import AppKit
import EasyEngineCore
import Foundation

struct GitHubRelease: Decodable {
    let tagName: String
    let name: String?
    let htmlUrl: String
    let publishedAt: String?

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case htmlUrl = "html_url"
        case publishedAt = "published_at"
    }

    var version: String {
        tagName.hasPrefix("v") ? String(tagName.dropFirst()) : tagName
    }
}

@MainActor
final class GitHubUpdateChecker {
    static let shared = GitHubUpdateChecker()

    static let allowedDownloadHost = "github.com"
    static let allowedDownloadPathPrefix = "/jonaskahn/EasyKey/"

    private let repositoryURL: URL
    private let session: URLSession
    private let maxResponseBytes = 1_048_576

    init(
        repositoryURL: URL? = nil,
        session: URLSession = .shared
    ) {
        if let repositoryURL {
            self.repositoryURL = repositoryURL
        } else if let defaultURL = URL(string: "https://api.github.com/repos/jonaskahn/EasyKey/releases/latest") {
            self.repositoryURL = defaultURL
        } else {
            AppLog.error(.update, "Failed to construct GitHub releases URL")
            self.repositoryURL = URL(fileURLWithPath: "/dev/null")
        }
        self.session = session
    }

    func checkForUpdates() async -> UpdateCheckResult {
        guard repositoryURL.scheme == "https" else {
            AppLog.error(.update, "Update check aborted: repository URL is not HTTPS")
            return .failure(.networkError)
        }

        do {
            var request = URLRequest(url: repositoryURL)
            request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
            request.setValue("EasyKey-App", forHTTPHeaderField: "User-Agent")
            request.timeoutInterval = 20

            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                AppLog.error(.update, "Update check failed: non-HTTP response")
                return .failure(.networkError)
            }
            guard httpResponse.statusCode == 200 else {
                AppLog.error(.update, "Update check failed: HTTP \(httpResponse.statusCode)")
                return .failure(.networkError)
            }
            guard data.count <= maxResponseBytes else {
                AppLog.error(.update, "Update check failed: response exceeds \(maxResponseBytes) bytes")
                return .failure(.networkError)
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            guard Self.isTrustedDownloadURL(release.htmlUrl) else {
                AppLog.error(.update, "Update check rejected untrusted download URL host/path")
                return .failure(.networkError)
            }

            let currentVersion = currentAppVersion()
            if isNewerVersion(release.version, than: currentVersion) {
                AppLog.info(.update, "Update available \(currentVersion) → \(release.version)")
                return .updateAvailable(
                    currentVersion: currentVersion,
                    latestVersion: release.version,
                    releaseNotes: release.name,
                    downloadURL: release.htmlUrl
                )
            } else {
                AppLog.info(.update, "Up to date at \(currentVersion)")
                return .upToDate(currentVersion: currentVersion)
            }
        } catch {
            AppLog.error(.update, "Update check failed: \(error.localizedDescription)")
            return .failure(.networkError)
        }
    }

    static func isTrustedDownloadURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString),
              url.scheme?.lowercased() == "https",
              url.host?.lowercased() == allowedDownloadHost
        else {
            return false
        }
        return url.path.hasPrefix(allowedDownloadPathPrefix)
    }

    private func currentAppVersion() -> String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.6"
    }

    func isNewerVersion(_ new: String, than current: String) -> Bool {
        let newParts = new.split(separator: ".").compactMap { Int($0) }
        let currentParts = current.split(separator: ".").compactMap { Int($0) }

        let maxCount = max(newParts.count, currentParts.count)
        let paddedNew = newParts + Array(repeating: 0, count: maxCount - newParts.count)
        let paddedCurrent = currentParts + Array(repeating: 0, count: maxCount - currentParts.count)

        for i in 0 ..< maxCount {
            if paddedNew[i] > paddedCurrent[i] {
                return true
            } else if paddedNew[i] < paddedCurrent[i] {
                return false
            }
        }
        return false
    }
}

enum UpdateCheckResult {
    case updateAvailable(currentVersion: String, latestVersion: String, releaseNotes: String?, downloadURL: String)
    case upToDate(currentVersion: String)
    case failure(UpdateCheckError)
}

enum UpdateCheckError {
    case networkError
}
