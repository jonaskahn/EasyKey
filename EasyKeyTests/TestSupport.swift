import EasyEngineCore
@testable import EasyKey
import EasyKeyKit
import Foundation

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
            updateService: UpdateService(bundle: .main)
        )
        return (coordinator, tempDirectory)
    }
}
