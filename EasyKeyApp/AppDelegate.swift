import AppKit
import SwiftUI

@main
struct EasyKeyAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        configureUITestingDefaultsIfNeeded()
    }

    var body: some Scene {
        Settings {
            ContentView(
                settingsStore: AppCoordinator.shared.settingsStore,
                coordinator: AppCoordinator.shared
            )
            .localized()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var coordinator: AppCoordinator?

    func applicationDidFinishLaunching(_: Notification) {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] == nil else { return }
        let isUITesting = ProcessInfo.processInfo.arguments.contains("--uitesting")
        guard isUITesting || AppCoordinator.isOnlyInstanceForCurrentUser() else {
            NSApp.terminate(nil)
            return
        }
        // Accessory apps cannot reliably become key/frontmost on headless CI runners,
        // which breaks XCUITest hit-testing. Run as a regular app while UI testing so
        // the settings window can become key and receive clicks.
        NSApp.setActivationPolicy(isUITesting ? .regular : .accessory)
        // Accessory apps lack a system Edit menu; without it Cmd+V never reaches text fields.
        AppMainMenuInstaller.installIfNeeded()
        let coordinator = AppCoordinator.shared
        self.coordinator = coordinator
        if isUITesting,
           let sectionIndex = ProcessInfo.processInfo.arguments.firstIndex(of: "--ui-settings-section"),
           ProcessInfo.processInfo.arguments.indices.contains(sectionIndex + 1),
           let section = SettingsSection(rawValue: ProcessInfo.processInfo.arguments[sectionIndex + 1]) {
            coordinator.selectedSettingsSection = section
        }
        coordinator.start()
        if isUITesting {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                coordinator.showSettings()
            }
        }
    }

    func applicationWillTerminate(_: Notification) {
        coordinator?.stop()
    }
}

private func configureUITestingDefaultsIfNeeded() {
    let arguments = ProcessInfo.processInfo.arguments
    guard arguments.contains("--uitesting") else { return }

    UserDefaults.standard.set(arguments.contains("--ui-skip-onboarding"), forKey: "hasCompletedOnboarding")

    if let languageIndex = arguments.firstIndex(of: "--ui-language"),
       arguments.indices.contains(languageIndex + 1) {
        let code = arguments[languageIndex + 1]
        if AppLanguage(rawValue: code) != nil || code == "system" {
            UserDefaults.standard.set(code, forKey: AppLanguage.storageKey)
            return
        }
    }

    UserDefaults.standard.set(AppLanguage.english.rawValue, forKey: AppLanguage.storageKey)
}
