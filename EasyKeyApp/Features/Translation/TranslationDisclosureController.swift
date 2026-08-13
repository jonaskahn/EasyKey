import AppKit
import EasyEngineCore
import SwiftUI

@MainActor
protocol TranslationActivationCapturing: AnyObject {
    var previousApplication: NSRunningApplication? { get }
    func capture() -> SelectedTextCaptureResult
}

extension SelectedTextCaptureCoordinator: TranslationActivationCapturing {}

@MainActor
final class TranslationDisclosureController {
    typealias Prompt = @MainActor (TranslationDisclosureIdentity) -> Bool

    private let settingsStore: SettingsStore
    private let prompt: Prompt
    private var acknowledgedEndpointIdentities: Set<TranslationDisclosureIdentity> = []

    init(
        settingsStore: SettingsStore,
        localization: LocalizationStore,
        prompt: Prompt? = nil
    ) {
        self.settingsStore = settingsStore
        self.prompt = prompt ?? { identity in Self.presentPrompt(for: identity, localization: localization) }
    }

    func request(for identity: TranslationDisclosureIdentity) -> Bool {
        let provider = identity.providerID
        guard TranslationProviderResolver.cloudProviderOrder.contains(provider) else { return true }
        if identity.endpointOrigin != nil {
            guard !acknowledgedEndpointIdentities.contains(identity) else { return true }
            guard prompt(identity) else { return false }
            acknowledgedEndpointIdentities.insert(identity)
            return true
        }
        guard !settingsStore.settings.translation.acknowledgedCloudDisclosureProviders.contains(provider) else {
            return true
        }
        guard prompt(identity) else { return false }
        settingsStore.update {
            $0.translation.acknowledgedCloudDisclosureProviders.insert(provider)
        }
        return true
    }

    private static func presentPrompt(
        for identity: TranslationDisclosureIdentity,
        localization: LocalizationStore
    ) -> Bool {
        let provider = identity.providerID
        let disclosedName = identity.endpointOrigin.map { "\(provider.displayName) (\($0))" } ?? provider.displayName
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = localization.string(.translationSettingsPrivacy)
        alert.informativeText = localization.format(
            .translationCloudDisclosureFirstUse,
            disclosedName,
            disclosedName
        )
        let disclosureURL = identity.endpointOrigin.flatMap(URL.init(string:)) ?? provider.privacyURL
        if let disclosureURL {
            let link = Link(
                localization.format(.translationSettingsProviderDataHandling, provider.displayName),
                destination: disclosureURL
            )
            .fixedSize()
            alert.accessoryView = NSHostingView(rootView: link)
        }
        alert.addButton(withTitle: localization.string(.commonContinue))
        alert.addButton(withTitle: localization.string(.commonCancel))
        return alert.runModal() == .alertFirstButtonReturn
    }
}
