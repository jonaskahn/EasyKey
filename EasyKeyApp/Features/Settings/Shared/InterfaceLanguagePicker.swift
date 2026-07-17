import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct InterfaceLanguagePicker: View {
    @ObservedObject private var localization = LocalizationStore.shared

    private var selection: Binding<AppLanguage> {
        Binding(
            get: { localization.preference },
            set: { localization.setPreference($0) }
        )
    }

    var body: some View {
        Picker(selection: selection) {
            ForEach(AppLanguage.allCases) { language in
                Text(localization.string(language.pickerKey)).tag(language)
            }
        } label: {
            SettingsControlLabel(
                title: localization.string(.languagePicker),
                description: localization.string(.languagePickerDescription)
            )
        }
        .pickerStyle(.menu)
        .accessibilityIdentifier("InterfaceLanguagePicker")
    }
}

/// Borderless variant for toolbar/header placement, where the boxed `.menu` picker bezel reads out of place against flat surroundings.
struct InterfaceLanguageMenu: View {
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        Menu {
            ForEach(AppLanguage.allCases) { language in
                Button {
                    localization.setPreference(language)
                } label: {
                    if language == localization.preference {
                        Label(localization.string(language.pickerKey), systemImage: "checkmark")
                    } else {
                        Text(localization.string(language.pickerKey))
                    }
                }
            }
        } label: {
            Text(localization.string(localization.preference.pickerKey))
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
        .accessibilityLabel(localization.string(.languagePicker))
        .accessibilityIdentifier("InterfaceLanguagePicker")
    }
}
