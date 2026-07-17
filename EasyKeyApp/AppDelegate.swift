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
        NSApp.setActivationPolicy(.accessory)
        let coordinator = AppCoordinator.shared
        self.coordinator = coordinator
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
