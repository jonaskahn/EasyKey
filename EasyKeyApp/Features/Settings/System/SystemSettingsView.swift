import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct SystemSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        Form {
            Section {
                SystemHealthCard(coordinator: coordinator)
            } header: {
                Text(localization.string(.systemHealth))
            } footer: {
                Text(localization.string(.helpSystemHealth))
            }

            Section {
                Toggle(isOn: Binding(get: { settingsStore.settings.system.launchAtLogin }, set: coordinator.setLaunchAtLogin)) {
                    SettingsControlLabel(
                        title: localization.string(.systemLaunchAtLogin),
                        description: localization.string(.systemLaunchAtLoginDescription)
                    )
                }

                if coordinator.loginItemStatus == .unsupported || coordinator.loginItemStatus == .failed {
                    Text(coordinator.loginItemStatus.localizedTitle(using: coordinator.localization))
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                settingToggle(.systemShowDockIcon, description: .systemShowDockIconDescription, isOn: setting(\.system.showDockIcon))
                settingToggle(.systemGrayMenuIcon, description: .systemGrayMenuIconDescription, isOn: setting(\.system.grayMenuIcon))
                settingToggle(
                    .systemOpenSettingsAtLaunch,
                    description: .systemOpenSettingsAtLaunchDescription,
                    isOn: setting(\.system.showSettingsAtLaunch)
                )

                Picker(localization.string(.systemMenuPopoverWidth), selection: setting(\.system.menuPopoverWidth)) {
                    Text(localization.string(.systemMenuPopoverWidthCompact)).tag(SystemOptions.MenuPopoverWidth.compact)
                    Text(localization.string(.systemMenuPopoverWidthSmall)).tag(SystemOptions.MenuPopoverWidth.small)
                    Text(localization.string(.systemMenuPopoverWidthMedium)).tag(SystemOptions.MenuPopoverWidth.medium)
                    Text(localization.string(.systemMenuPopoverWidthLarge)).tag(SystemOptions.MenuPopoverWidth.large)
                    Text(localization.string(.systemMenuPopoverWidthExtraLarge)).tag(SystemOptions.MenuPopoverWidth.extraLarge)
                }
            } header: {
                Text(localization.string(.systemStartupMenuBar))
            }
            .toggleStyle(.switch)

            Section {
                settingToggle(
                    .systemCheckForUpdates,
                    description: .systemCheckForUpdatesDescription,
                    isOn: setting(\.system.checkForUpdates)
                )
                .toggleStyle(.switch)

                Button(localization.string(.systemCheckNow)) {
                    coordinator.checkForUpdates()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!coordinator.canCheckForUpdates)

                if !coordinator.canCheckForUpdates {
                    Text(localization.string(.systemUpdatesUnavailable))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text(localization.string(.systemUpdates))
            }
        }
        .formStyle(.grouped)
    }

    private func setting<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        Binding(get: { settingsStore.settings[keyPath: keyPath] }, set: { value in settingsStore.update { $0[keyPath: keyPath] = value } })
    }

    private func settingToggle(_ title: L10nKey, description: L10nKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            SettingsControlLabel(title: localization.string(title), description: localization.string(description))
        }
    }
}
