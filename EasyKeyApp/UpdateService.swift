import EasyEngineCore
import Foundation
import Sparkle

@MainActor
final class UpdateService {
    private let updaterController: SPUStandardUpdaterController?

    var isConfigured: Bool {
        updaterController != nil
    }

    init(
        bundle: Bundle = .main,
        isTesting: Bool = ProcessInfo.processInfo.arguments.contains("--uitesting") || ProcessInfo.processInfo
            .environment["XCTestConfigurationFilePath"] != nil
    ) {
        let isCustomTestBundle = bundle != .main && bundle.bundleIdentifier != Bundle.main.bundleIdentifier
        guard !isTesting || isCustomTestBundle, Self.hasReleaseConfiguration(in: bundle) else {
            AppLog.info(.update, "Sparkle disabled: testing mode, missing HTTPS feed, or EdDSA public key")
            updaterController = nil
            return
        }

        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        AppLog.info(.update, "Sparkle updater configured")
    }

    func start() {
        guard updaterController != nil else { return }
        AppLog.debug(.update, "Starting Sparkle updater")
        updaterController?.startUpdater()
    }

    func checkForUpdates() {
        AppLog.info(.update, "Sparkle checkForUpdates invoked")
        updaterController?.checkForUpdates(nil)
    }

    private static func hasReleaseConfiguration(in bundle: Bundle) -> Bool {
        guard let feedURL = bundle.object(forInfoDictionaryKey: "SUFeedURL") as? String,
              URL(string: feedURL)?.scheme == "https",
              let publicKey = bundle.object(forInfoDictionaryKey: "SUPublicEDKey") as? String
        else {
            return false
        }
        return !feedURL.contains("$(") && !publicKey.isEmpty && !publicKey.contains("$(")
    }
}
