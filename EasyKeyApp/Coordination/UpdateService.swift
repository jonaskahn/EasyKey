import EasyEngineCore
import Foundation
import Sparkle

@MainActor
final class UpdateService {
    private let updaterController: SPUStandardUpdaterController?
    private let isTesting: Bool
    private let configured: Bool

    /// Whether the bundle carries a usable Sparkle release configuration
    /// (HTTPS feed + EdDSA key). Independent of whether a live updater exists
    /// in this process — see `hasLiveUpdater`.
    var isConfigured: Bool {
        configured
    }

    /// True when a real Sparkle updater exists in this process. Always false
    /// during testing: Sparkle must never be instantiated or started from a
    /// test process, because it performs live network checks and shows a modal
    /// "Update failed" alert that blocks the run until a human clicks OK.
    var hasLiveUpdater: Bool {
        updaterController != nil
    }

    init(
        bundle: Bundle = .main,
        isTesting: Bool = ProcessInfo.processInfo.arguments.contains("--uitesting") || ProcessInfo.processInfo
            .environment["XCTestConfigurationFilePath"] != nil
    ) {
        self.isTesting = isTesting
        let isCustomTestBundle = bundle != .main && bundle.bundleIdentifier != Bundle.main.bundleIdentifier
        let validConfig = Self.hasReleaseConfiguration(in: bundle)
        let canConfigure = (!isTesting || isCustomTestBundle) && validConfig
        configured = canConfigure
        guard canConfigure else {
            AppLog.info(.update, "Sparkle disabled: testing mode, missing HTTPS feed, or EdDSA public key")
            updaterController = nil
            return
        }
        guard !isTesting else {
            AppLog.info(.update, "Sparkle config present but suppressed in testing mode")
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
        guard !isTesting, updaterController != nil else { return }
        AppLog.debug(.update, "Starting Sparkle updater")
        updaterController?.startUpdater()
    }

    func checkForUpdates() {
        guard !isTesting, updaterController != nil else { return }
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
