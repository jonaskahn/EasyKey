import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct SmartSwitchSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        let _ = coordinator.smartSwitchRevision
        Form {
            Section {
                Toggle(isOn: setting(\.smartSwitch.enabled)) {
                    SettingsControlLabel(
                        title: localization.string(.smartSwitchRememberPerApp),
                        description: localization.string(.smartSwitchRememberPerAppDescription)
                    )
                }
                Toggle(isOn: setting(\.smartSwitch.rememberEncoding)) {
                    SettingsControlLabel(
                        title: localization.string(.smartSwitchRememberEncoding),
                        description: localization.string(.smartSwitchRememberEncodingDescription)
                    )
                }
                .disabled(!settingsStore.settings.smartSwitch.enabled)
            } header: {
                Text(localization.string(.smartSwitchPerApp))
            } footer: {
                VStack(alignment: .leading, spacing: 4) {
                    if !settingsStore.settings.smartSwitch.enabled {
                        Text(localization.string(.smartSwitchEnableHint))
                    }
                }
            }
            .toggleStyle(.switch)

            Section {
                LabeledContent(localization.string(.smartSwitchApp), value: coordinator.currentApplicationName)
                LabeledContent(localization.string(.smartSwitchStatus), value: coordinator.currentAppSmartSwitchStatus)
            } header: {
                Text(localization.string(.smartSwitchCurrentApp))
            }

            Section {
                if coordinator.smartSwitchPreferences.isEmpty {
                    Text(localization.string(.smartSwitchEmpty))
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(coordinator.smartSwitchPreferences) { preference in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(preference.displayName)
                                Text(preferenceSummary(preference))
                                    .font(.caption.monospaced())
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(localization.string(.commonRemove), role: .destructive) {
                                coordinator.resetSmartSwitchPreference(preference)
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                        }
                    }

                    Button(localization.string(.smartSwitchForgetAll), role: .destructive) { coordinator.clearSmartSwitchPreferences() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            } header: {
                Text(localization.string(.smartSwitchSavedApps))
            }
        }
        .formStyle(.grouped)
    }

    private func preferenceSummary(_ preference: SmartSwitchPreference) -> String {
        let language = localization.displayName(for: preference.choice.language)
        if let encoding = preference.choice.encoding {
            return "\(language) - \(localization.displayName(for: encoding))"
        }
        return language
    }

    private func setting<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        Binding(get: { settingsStore.settings[keyPath: keyPath] }, set: { value in settingsStore.update { $0[keyPath: keyPath] = value } })
    }
}
