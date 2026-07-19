import AppKit
import EasyEngineCore
import SwiftUI

struct BorderlessPickerMenu<Item: Hashable>: View {
    let items: [Item]
    let titleForItem: (Item) -> String
    @Binding var selection: Item

    var body: some View {
        Menu {
            ForEach(items, id: \.self) { item in
                Button {
                    selection = item
                } label: {
                    if item == selection {
                        Label(titleForItem(item), systemImage: "checkmark")
                    } else {
                        Text(titleForItem(item))
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Spacer(minLength: 4)
                Text(titleForItem(selection))
                    .lineLimit(1)
                Image(systemName: "chevron.down.circle")
                    .foregroundStyle(.secondary)
                    .accessibilityHidden(true)
            }
            .contentShape(Rectangle())
        }
        .menuIndicator(.hidden)
        .buttonStyle(.plain)
    }
}

struct MenuPopoverActions {
    var openClipboard: () -> Void
    var openSettings: () -> Void
    var quit: () -> Void
}

struct MenuPopoverView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var settingsStore: SettingsStore
    @ObservedObject private var localization: LocalizationStore
    let translation: MenuPopoverTranslationConfiguration?
    let actions: MenuPopoverActions

    init(
        coordinator: AppCoordinator,
        translation: MenuPopoverTranslationConfiguration? = nil,
        localization: LocalizationStore? = nil,
        actions: MenuPopoverActions? = nil
    ) {
        self.coordinator = coordinator
        settingsStore = coordinator.settingsStore
        self.translation = translation
        self.localization = localization ?? .shared
        self.actions = actions ?? MenuPopoverActions(
            openClipboard: { [weak coordinator] in coordinator?.showSettings(section: .clipboard) },
            openSettings: { [weak coordinator] in coordinator?.showSettings() },
            quit: { NSApp.terminate(nil) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let translation {
                MenuPopoverTranslationView(
                    model: translation.model,
                    availableProviders: translation.availableProviders,
                    localization: localization,
                    actions: translation.actions
                )
                .background(translation.sessionHost)

                Divider()
            }

            VStack(spacing: 0) {
                pickerRow(label: localization.string(.menuLanguage)) {
                    BorderlessPickerMenu(
                        items: InputLanguage.allCases,
                        titleForItem: localization.displayName(for:),
                        selection: languageBinding
                    )
                    .accessibilityLabel(localization.string(.a11yInputLanguage))
                }

                pickerRow(label: localization.string(.menuMethod)) {
                    BorderlessPickerMenu(
                        items: InputMethod.allCases,
                        titleForItem: localization.displayName(for:),
                        selection: inputMethodBinding
                    )
                    .accessibilityLabel(localization.string(.menuMethod))
                }

                pickerRow(label: localization.string(.menuEncodingLabel)) {
                    BorderlessPickerMenu(
                        items: EncodingTable.allCases,
                        titleForItem: localization.displayName(for:),
                        selection: encodingBinding
                    )
                    .accessibilityLabel(localization.string(.menuEncodingLabel))
                }
            }
            .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: DesignScale.radiusMD))
            .frame(maxWidth: .infinity, alignment: .leading)

            inputStatus

            Divider()

            HStack(spacing: 12) {
                Button(localization.string(.settingsSectionClipboard), action: actions.openClipboard)
                    .buttonStyle(.bordered)
                Spacer()
                Button(localization.string(.menuSettingsShort), action: actions.openSettings)
                    .buttonStyle(.bordered)
                    .keyboardShortcut(",", modifiers: .command)
                    .accessibilityLabel(localization.string(.a11yOpenSettings))
                Button(localization.string(.menuQuitShort), action: actions.quit)
                    .buttonStyle(.bordered)
                    .keyboardShortcut("q", modifiers: .command)
                    .accessibilityLabel(localization.string(.a11yQuit))
            }
        }
        .padding(16)
        .frame(width: translation == nil ? 380 : 640)
        .easyKeyButtonShape()
    }

    private var inputStatus: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: stateSymbol)
                .foregroundStyle(stateColor)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 1) {
                Text(coordinator.menuBarStateTitle)
                    .font(.subheadline.weight(.semibold))
                Text(localization.format(
                    .menuCurrentAppStatus,
                    coordinator.currentApplicationName,
                    coordinator.currentAppSmartSwitchStatus
                ))
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(localization.format(
            .a11yPopoverStatus,
            coordinator.menuBarStateTitle,
            coordinator.currentApplicationName,
            coordinator.currentAppSmartSwitchStatus
        ))
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(stateColor.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignScale.radiusMD))
    }

    private func pickerRow(label: String, @ViewBuilder control: () -> some View) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .frame(width: 90, alignment: .leading)
            control()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    var languageBinding: Binding<InputLanguage> {
        Binding(
            get: { settingsStore.settings.input.language },
            set: coordinator.setLanguage
        )
    }

    var inputMethodBinding: Binding<InputMethod> {
        Binding(
            get: { settingsStore.settings.input.inputMethod },
            set: coordinator.setInputMethod
        )
    }

    var encodingBinding: Binding<EncodingTable> {
        Binding(
            get: { settingsStore.settings.input.encoding },
            set: coordinator.setEncoding
        )
    }

    private var stateSymbol: String {
        if coordinator.keyboardPaused {
            return "pause.circle.fill"
        }
        return coordinator.keyboardHealth == .active ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var stateColor: Color {
        if coordinator.keyboardPaused {
            return .orange
        }
        return coordinator.keyboardHealth == .active ? .green : .red
    }
}
