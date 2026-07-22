import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct SystemSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var confirmReset = false

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
                InterfaceLanguagePicker()
            } header: {
                Text(localization.string(.aboutInterface))
            }

            Section {
                settingToggle(
                    .systemCheckForUpdates,
                    description: .systemCheckForUpdatesDescription,
                    isOn: setting(\.system.checkForUpdates)
                )
                .toggleStyle(.switch)
                .disabled(!coordinator.canCheckForUpdates)

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

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Button(localization.string(.aboutResetSettings), role: .destructive) { confirmReset = true }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                    Text(localization.string(.aboutResetSettingsDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text(localization.string(.aboutMaintenance))
            }
        }
        .formStyle(.grouped)
        .alert(localization.string(.aboutResetConfirmTitle), isPresented: $confirmReset) {
            Button(localization.string(.commonReset), role: .destructive) { settingsStore.reset() }
            Button(localization.string(.commonCancel), role: .cancel) {}
        } message: {
            Text(localization.string(.aboutResetConfirmMessage))
        }
    }

    private func setting<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        settingsStore.binding(keyPath)
    }

    private func settingToggle(_ title: L10nKey, description: L10nKey, isOn: Binding<Bool>) -> some View {
        Toggle(isOn: isOn) {
            SettingsControlLabel(title: localization.string(title), description: localization.string(description))
        }
    }
}
