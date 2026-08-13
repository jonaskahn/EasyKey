import AppKit
import SwiftUI

@main
struct EasyKeyAppMain: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    init() {
        UITestingLaunchConfiguration.configureDefaultsIfNeeded()
    }

    var body: some Scene {
        Settings {
            if let coordinator = appDelegate.coordinator {
                ContentView(
                    settingsStore: coordinator.settingsStore,
                    coordinator: coordinator
                )
            }
        }
    }
}
