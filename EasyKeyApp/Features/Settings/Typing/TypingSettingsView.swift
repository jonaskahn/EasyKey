import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct TypingSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        Form {
            Section {
                Picker(selection: setting(\.input.language)) {
                    ForEach(InputLanguage.allCases, id: \.self) { language in
                        Text(localization.displayName(for: language)).tag(language)
                    }
                } label: {
                    SettingsControlLabel(
                        title: localization.string(.typingLanguage),
                        description: localization.string(.typingLanguageDescription)
                    )
                }
                Picker(selection: setting(\.input.inputMethod)) {
                    ForEach(InputMethod.allCases, id: \.self) { method in
                        Text(localization.displayName(for: method)).tag(method)
                    }
                } label: {
                    SettingsControlLabel(
                        title: localization.string(.typingInputMethod),
                        description: localization.string(.typingInputMethodDescription)
                    )
                }
                ShortcutRecorder(
                    label: localization.string(.typingSwitchLanguage),
                    description: localization.string(.typingSwitchLanguageDescription),
                    shortcut: setting(\.input.switchShortcut)
                )
            } header: {
                Text(localization.string(.typingActiveInput))
            }

            Section {
                settingToggle(
                    .typingSpellingModernization,
                    description: .typingSpellingModernizationDescription,
                    isOn: setting(\.typing.spellingModernization)
                )
                settingToggle(
                    .typingRestoreInvalidWord,
                    description: .typingRestoreInvalidWordDescription,
                    isOn: setting(\.typing.restoreInvalidWord)
                )
                settingToggle(
                    .typingFreeToneMarking,
                    description: .typingFreeToneMarkingDescription,
                    isOn: setting(\.typing.freeToneMarking)
                )
                settingToggle(.typingQuickTelex, description: .typingQuickTelexDescription, isOn: setting(\.typing.quickTelex))
                settingToggle(.typingAllowZFWJ, description: .typingAllowZFWJDescription, isOn: setting(\.typing.allowZFWJ))
                settingToggle(
                    .typingUppercaseFirstCharacter,
                    description: .typingUppercaseFirstCharacterDescription,
                    isOn: setting(\.typing.uppercaseFirstCharacter)
                )
            } header: {
                Text(localization.string(.typingTypingOptions))
            }
            .toggleStyle(.switch)

            Section {
                settingToggle(
                    .typingQuickStartEndConsonant,
                    description: .typingQuickStartEndConsonantDescription,
                    isOn: setting(\.typing.quickStartEndConsonant)
                )
                .toggleStyle(.switch)
                ShortcutRecorder(
                    label: localization.string(.typingTemporarySpellToggle),
                    description: localization.string(.typingTemporarySpellToggleDescription),
                    shortcut: setting(\.typing.temporarySpellToggle)
                )
                ShortcutRecorder(
                    label: localization.string(.typingTemporaryEngineToggle),
                    description: localization.string(.typingTemporaryEngineToggleDescription),
                    shortcut: setting(\.typing.temporaryEngineToggle)
                )
            } header: {
                Text(localization.string(.typingAdvancedOptions))
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
