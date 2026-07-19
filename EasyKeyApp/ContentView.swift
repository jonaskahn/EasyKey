import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct ContentView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        Group {
            if hasCompletedOnboarding {
                SettingsShell(
                    settingsStore: settingsStore,
                    coordinator: coordinator,
                    translationSettingsModel: coordinator.translation.settingsModel
                )
            } else {
                OnboardingView(
                    settingsStore: settingsStore,
                    coordinator: coordinator,
                    finish: { hasCompletedOnboarding = true }
                )
            }
        }
        .frame(minWidth: 700, minHeight: 440)
        .easyKeyButtonShape()
        .localized()
    }
}
