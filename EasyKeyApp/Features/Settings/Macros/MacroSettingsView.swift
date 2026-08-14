import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct MacroSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var search = ""
    @State private var editing: Macro?
    @State private var creating = false
    @State private var message: String?

    var body: some View {
        let _ = coordinator.macroRevision
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                TextField(localization.string(.macrosSearch), text: $search)
                    .textFieldStyle(.roundedBorder)

                Button { creating = true } label: { Label(localization.string(.commonAdd), systemImage: "plus") }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                Button(localization.string(.commonImport)) { importMacros() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Button(localization.string(.commonExport)) { exportMacros() }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                Menu {
                    Button(localization.string(.languageEnglish)) { addSamples([.english]) }
                    Button(localization.string(.languageVietnamese)) { addSamples([.vietnamese]) }
                    Button(localization.string(.languageNineX)) { addSamples([.nineX]) }
                    Button(localization.string(.languageGenZ)) { addSamples([.genZ]) }
                    Divider()
                    Button(localization.string(.macrosAddAllSamples)) { addSamples(MacroSamplePack.allCases) }
                } label: {
                    Label(localization.string(.macrosAddSamples), systemImage: "text.badge.plus")
                }
                .menuStyle(.button)
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding()

            Form {
                Section {
                    settingToggle(.macrosEnable, description: .macrosEnableDescription, isOn: setting(\.macro.enabled))
                    settingToggle(
                        .macrosAutoCapitalize,
                        description: .macrosAutoCapitalizeDescription,
                        isOn: setting(\.macro.autoCapitalize)
                    )
                    .disabled(!settingsStore.settings.macro.enabled)
                } header: {
                    Text(localization.string(.macrosExpansion))
                } footer: {
                    if !settingsStore.settings.macro.enabled {
                        Text(localization.string(.macrosEnableHint))
                    }
                }
                .toggleStyle(.switch)

                Section {
                    if filteredMacros.isEmpty {
                        ContentUnavailableView {
                            Label(localization.string(.macrosEmptyTitle), systemImage: "text.badge.plus")
                        } description: {
                            Text(localization.string(.macrosEmptyBody))
                        }
                    } else {
                        ForEach(filteredMacros) { macro in
                            HStack {
                                Toggle("", isOn: enabledBinding(for: macro))
                                    .labelsHidden()
                                    .accessibilityLabel(localization.format(.macrosEnableTrigger, macro.trigger))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(macro.trigger)
                                        .fontWeight(.semibold)
                                    Text(macro.expansion)
                                        .font(.callout.monospaced())
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                                Spacer()
                                Menu {
                                    Button(localization.string(.languageVietnamese)) { setCategory(.vietnamese, for: macro) }
                                    Button(localization.string(.languageEnglish)) { setCategory(.english, for: macro) }
                                    Button(localization.string(.languageBoth)) { setCategory(.both, for: macro) }
                                } label: {
                                    Text(categoryTitle(macro.category))
                                        .font(.callout)
                                        .foregroundStyle(.secondary)
                                }
                                .menuStyle(.borderlessButton)
                                .fixedSize()
                                Button(localization.string(.commonEdit)) { editing = macro }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                            }
                        }
                    }
                } header: {
                    Text(localization.string(.macrosRegistry))
                }
            }
            .formStyle(.grouped)
        }
        .sheet(isPresented: $creating) { MacroEditorSheet(macro: nil, coordinator: coordinator) }
        .sheet(item: $editing) { macro in MacroEditorSheet(macro: macro, coordinator: coordinator) }
        .alert(localization.string(.macrosAlertTitle), isPresented: Binding(get: { message != nil }, set: {
            if !$0 {
                message = nil
            }
        })) {
            Button(localization.string(.commonOk), role: .cancel) {}
        } message: { Text(message ?? "") }
    }

    private var filteredMacros: [Macro] {
        coordinator.macroStore.search(search)
    }

    func enabledBinding(for macro: Macro) -> Binding<Bool> {
        Binding(get: { macro.isEnabled }, set: { enabled in
            do {
                _ = try coordinator.macroStore.edit(id: macro.id, trigger: macro.trigger, expansion: macro.expansion, isEnabled: enabled)
                coordinator.refreshMacros()
            } catch { message = localization.errorMessage(error) }
        })
    }

    func setCategory(_ category: MacroCategory, for macro: Macro) {
        do {
            _ = try coordinator.macroStore.edit(
                id: macro.id,
                trigger: macro.trigger,
                expansion: macro.expansion,
                isEnabled: macro.isEnabled,
                category: category
            )
            coordinator.refreshMacros()
        } catch {
            message = localization.errorMessage(error)
        }
    }

    func categoryTitle(_ category: MacroCategory) -> String {
        switch category {
        case .vietnamese: localization.string(.languageVietnamese)
        case .english: localization.string(.languageEnglish)
        case .nineX: localization.string(.languageNineX)
        case .genZ: localization.string(.languageGenZ)
        case .both: localization.string(.languageBoth)
        }
    }

    func addSamples(_ packs: [MacroSamplePack]) {
        do {
            let added = try coordinator.macroStore.insertSamples(packs.flatMap(\.macros))
            coordinator.refreshMacros()
            message = added > 0
                ? localization.format(.macrosSamplesAdded, added)
                : localization.string(.macrosSamplesNone)
        } catch {
            message = localization.errorMessage(error)
        }
    }

    private func exportMacros() {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = localization.string(.macrosExportFilename)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try coordinator.macroStore.export(to: url)
            message = localization.string(.macrosExported)
        } catch {
            message = localization.errorMessage(error)
        }
    }

    private func importMacros() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.tabSeparatedText, .plainText]
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let preview = try coordinator.macroStore.previewImport(from: url)
            try coordinator.macroStore.apply(preview, resolving: [:])
            coordinator.refreshMacros()
            message = localization.format(.macrosImported, preview.additions.count)
        } catch {
            message = localization.errorMessage(error)
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
