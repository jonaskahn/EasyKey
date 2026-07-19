import AppKit
import EasyEngineCore
@testable import EasyKey
import EasyKeyKit
import Foundation

@MainActor
final class TestTranslationCapture: TranslationActivationCapturing {
    var previousApplication: NSRunningApplication?
    var result = SelectedTextCaptureResult(text: "", source: .blank, accessibilityResult: .absent)
    var onCapture: (() -> Void)?

    func capture() -> SelectedTextCaptureResult {
        onCapture?()
        return result
    }
}

final class TestTranslationHotKeyRegistrar: TranslationHotKeyRegistering {
    var shouldRegister = true
    private(set) var registerCount = 0
    private(set) var unregisterCount = 0
    private(set) var shutdownCount = 0
    private(set) var handler: (@MainActor () -> Void)?

    func register(
        keyCode _: UInt32,
        modifiers _: UInt32,
        identity _: TranslationHotKeyIdentity,
        handler: @escaping @MainActor () -> Void
    ) -> Bool {
        registerCount += 1
        guard shouldRegister else { return false }
        self.handler = handler
        return true
    }

    func unregister(identity _: TranslationHotKeyIdentity) {
        unregisterCount += 1
        handler = nil
    }

    func shutdown() {
        shutdownCount += 1
        handler = nil
    }
}

@MainActor
enum TestCoordinatorFactory {
    static func make() -> (coordinator: AppCoordinator, tempDirectory: URL) {
        let tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppCoordinatorTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)

        let settingsStore = ObservableSettingsStore(fileURL: tempDirectory.appendingPathComponent("settings.json"))
        let macroStore = MacroStore(fileURL: tempDirectory.appendingPathComponent("macros.json"))
        let smartSwitchStore = SmartSwitchStore(fileURL: tempDirectory.appendingPathComponent("smart-switch.json"))
        let localizationSuiteName = "one.ifelse.easykey.coordinator-tests.\(UUID().uuidString)"
        let localizationDefaults = UserDefaults(suiteName: localizationSuiteName)!
        localizationDefaults.removePersistentDomain(forName: localizationSuiteName)
        let localization = LocalizationStore(defaults: localizationDefaults, bundle: .main)
        let translationDependencies = AppTranslationRuntime.Dependencies(
            credentialStore: InMemoryTranslationCredentialStore(),
            platformCapability: TranslationPlatformCapability(supportsAppleTranslation: false),
            capture: TestTranslationCapture(),
            hotKeyRegistrar: TestTranslationHotKeyRegistrar(),
            disclosurePrompt: { _ in true },
            panelPresenter: nil,
            speech: nil
        )
        let clipboard = ClipboardServices(
            options: settingsStore.settings.clipboard,
            applicationSupportDirectory: tempDirectory,
            localization: localization,
            keyProvider: InMemoryClipboardKeyStore()
        )

        let coordinator = AppCoordinator(
            settingsStore: settingsStore,
            localization: localization,
            keyboardService: KeyboardService(settings: settingsStore.settings),
            macroStore: macroStore,
            smartSwitchStore: smartSwitchStore,
            statusItemController: StatusItemController(localization: localization),
            settingsWindowPresenter: SettingsWindowPresenter(localization: localization),
            loginItemController: LoginItemController(),
            workspaceObserver: WorkspaceObserver(),
            updateService: UpdateService(bundle: .main),
            clipboardServices: clipboard,
            translationDependencies: translationDependencies
        )
        return (coordinator, tempDirectory)
    }
}
