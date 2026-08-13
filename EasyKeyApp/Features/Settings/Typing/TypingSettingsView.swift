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
                Picker(selection: setting(\.typing.toneStyle)) {
                    ForEach(ToneStyle.allCases, id: \.self) { style in
                        Text(localization.displayName(for: style)).tag(style)
                    }
                } label: {
                    SettingsControlLabel(
                        title: localization.string(.typingToneStyle),
                        description: localization.string(.typingToneStyleDescription)
                    )
                }
                settingToggle(
                    .typingSpellCheck,
                    description: .typingSpellCheckDescription,
                    isOn: setting(\.typing.spellCheck)
                )
                settingToggle(
                    .typingLiveConfidenceScoring,
                    description: .typingLiveConfidenceScoringDescription,
                    isOn: setting(\.typing.liveConfidenceScoring)
                )
                settingToggle(
                    .typingIOSUniKeyLikeMode,
                    description: .typingIOSUniKeyLikeModeDescription,
                    isOn: setting(\.typing.iosUniKeyLikeMode)
                )
                settingToggle(
                    .typingRestoreInvalidWord,
                    description: .typingRestoreInvalidWordDescription,
                    isOn: setting(\.typing.restoreInvalidWord)
                )
                settingToggle(
                    .typingQuickTelexConsonants,
                    description: .typingQuickTelexConsonantsDescription,
                    isOn: setting(\.typing.quickTelexConsonants)
                )
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
                    .typingStandaloneW,
                    description: .typingStandaloneWDescription,
                    isOn: setting(\.typing.standaloneWShortcut)
                )
                settingToggle(
                    .typingBracketShortcuts,
                    description: .typingBracketShortcutsDescription,
                    isOn: setting(\.typing.bracketShortcuts)
                )
                ShortcutRecorder(
                    label: localization.string(.typingRestoreWordShortcut),
                    description: localization.string(.typingRestoreWordShortcutDescription),
                    shortcut: setting(\.typing.restoreWordShortcut)
                )
            }
            .toggleStyle(.switch)
        }
        .formStyle(.grouped)
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
