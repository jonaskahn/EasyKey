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

struct MenuPopoverView: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var settingsStore: SettingsStore
    @ObservedObject private var localization = LocalizationStore.shared

    init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        settingsStore = coordinator.settingsStore
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: stateSymbol)
                    .font(.title2)
                    .foregroundStyle(stateColor)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text(coordinator.menuBarStateTitle)
                        .font(.headline)
                    Text(localization.format(
                        .menuCurrentAppStatus,
                        coordinator.currentApplicationName,
                        coordinator.currentAppSmartSwitchStatus
                    ))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
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
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(stateColor.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignScale.radiusMD))

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

            Divider()

            HStack(spacing: 12) {
                Button(localization.string(.settingsSectionClipboard)) { coordinator.showSettings(section: .clipboard) }
                    .buttonStyle(.bordered)
                Spacer()
                Button(localization.string(.menuSettingsShort)) { coordinator.showSettings() }
                    .buttonStyle(.bordered)
                    .keyboardShortcut(",", modifiers: .command)
                    .accessibilityLabel(localization.string(.a11yOpenSettings))
                Button(localization.string(.menuQuitShort)) {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.bordered)
                .keyboardShortcut("q", modifiers: .command)
                .accessibilityLabel(localization.string(.a11yQuit))
            }
        }
        .padding(16)
        .frame(width: 380)
        .easyKeyButtonShape()
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

    private var languageBinding: Binding<InputLanguage> {
        Binding(
            get: { settingsStore.settings.input.language },
            set: coordinator.setLanguage
        )
    }

    private var inputMethodBinding: Binding<InputMethod> {
        Binding(
            get: { settingsStore.settings.input.inputMethod },
            set: coordinator.setInputMethod
        )
    }

    private var encodingBinding: Binding<EncodingTable> {
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
