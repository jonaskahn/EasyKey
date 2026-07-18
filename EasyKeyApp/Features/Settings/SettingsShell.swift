import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct SettingsShell: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared

    private var selection: Binding<SettingsSection?> {
        Binding(
            get: { coordinator.selectedSettingsSection },
            set: { coordinator.selectedSettingsSection = $0 ?? .typing }
        )
    }

    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            List(SettingsSection.allCases, selection: selection) { section in
                Label(localization.sectionTitle(section), systemImage: section.symbol)
                    .tag(section)
                    .accessibilityIdentifier("SettingsSection-\(section.rawValue)")
            }
            .listStyle(.sidebar)
            .frame(width: 192)
            .navigationSplitViewColumnWidth(192)
            .accessibilityIdentifier("SettingsSidebar")
            .toolbar(removing: .sidebarToggle)
        } detail: {
            detail
                .navigationTitle(localization.sectionTitle(coordinator.selectedSettingsSection))
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    columnVisibility = columnVisibility == .detailOnly ? .all : .detailOnly
                } label: {
                    Label(localization.string(.settingsToggleSidebar), systemImage: "sidebar.left")
                }
                .labelStyle(.iconOnly)
                .help(localization.string(.settingsToggleSidebar))
                .accessibilityIdentifier("SettingsSidebarToggle")
            }
        }
    }

    @ViewBuilder private var detail: some View {
        switch coordinator.selectedSettingsSection {
        case .typing:
            TypingSettingsView(settingsStore: settingsStore, coordinator: coordinator)
        case .encoding:
            EncodingSettingsView(settingsStore: settingsStore, coordinator: coordinator)
        case .macros:
            MacroSettingsView(settingsStore: settingsStore, coordinator: coordinator)
        case .smartSwitch:
            SmartSwitchSettingsView(settingsStore: settingsStore, coordinator: coordinator)
        case .behavior:
            BehaviorSettingsView(settingsStore: settingsStore)
        case .system:
            SystemSettingsView(settingsStore: settingsStore, coordinator: coordinator)
        case .about:
            AboutSettingsView(settingsStore: settingsStore)
        }
    }
}
