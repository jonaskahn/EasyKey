import AppKit
import EasyEngineCore
import SwiftUI

struct ClipboardSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared

    @State private var showClearAllConfirm = false
    @State private var showPersistOffConfirm = false

    private let countOptions = [50, 100, 200, 500]
    private let ageOptions = [1, 7, 14, 30]

    var body: some View {
        Form {
            captureSection
            accessSection
            contentSection
            retentionSection
            privacySection
            dataSection
        }
        .formStyle(.grouped)
        .alert(localization.string(.clipboardConfirmClearAllTitle), isPresented: $showClearAllConfirm) {
            Button(localization.string(.commonCancel), role: .cancel) {}
            Button(localization.string(.clipboardConfirmClear), role: .destructive) {
                Task { await coordinator.clipboardClearAll() }
            }
        } message: {
            Text(localization.string(.clipboardConfirmClearAllMessage))
        }
        .alert(localization.string(.clipboardConfirmPersistOffTitle), isPresented: $showPersistOffConfirm) {
            Button(localization.string(.commonCancel), role: .cancel) {}
            Button(localization.string(.clipboardConfirmTurnOff), role: .destructive) {
                confirmDisablePersistence()
            }
        } message: {
            Text(localization.string(.clipboardConfirmPersistOffMessage))
        }
    }

    private var captureSection: some View {
        Section {
            Toggle(localization.string(.clipboardCaptureEnable), isOn: setting(\.clipboard.isCaptureEnabled))
                .accessibilityIdentifier("ClipboardCaptureToggle")
        } header: {
            Text(localization.string(.clipboardCaptureTitle))
        } footer: {
            Text(localization.string(.clipboardCaptureDescription))
        }
    }

    private var accessSection: some View {
        Section {
            ShortcutRecorder(
                label: localization.string(.clipboardAccessShortcut),
                description: localization.string(.clipboardAccessShortcutDescription),
                shortcut: setting(\.clipboard.shortcut)
            )
            Picker(selection: setting(\.clipboard.selectionAction)) {
                Text(localization.string(.clipboardSelectionActionPaste)).tag(ClipboardSelectionAction.pasteImmediately)
                Text(localization.string(.clipboardSelectionActionCopy)).tag(ClipboardSelectionAction.copyOnly)
            } label: {
                Text(localization.string(.clipboardSelectionAction))
            }
        } header: {
            Text(localization.string(.clipboardAccessTitle))
        }
    }

    private var contentSection: some View {
        Section {
            Toggle(localization.string(.clipboardContentText), isOn: kindBinding(.text))
            Toggle(localization.string(.clipboardContentUrls), isOn: kindBinding(.url))
            Toggle(localization.string(.clipboardContentImages), isOn: kindBinding(.image))
            Toggle(localization.string(.clipboardContentFiles), isOn: filesBinding)
        } header: {
            Text(localization.string(.clipboardContentTitle))
        }
    }

    private var retentionSection: some View {
        Section {
            Picker(localization.string(.clipboardRetentionCount), selection: setting(\.clipboard.maximumEntryCount)) {
                ForEach(countOptions, id: \.self) { Text("\($0)").tag($0) }
            }
            Picker(localization.string(.clipboardRetentionAge), selection: setting(\.clipboard.retentionDays)) {
                ForEach(ageOptions, id: \.self) { Text("\($0)").tag($0) }
            }
        } header: {
            Text(localization.string(.clipboardRetentionTitle))
        } footer: {
            Text(localization.string(.clipboardRetentionPinNote))
        }
    }

    private var privacySection: some View {
        Section {
            Toggle(localization.string(.clipboardPrivacyPersist), isOn: persistBinding)
            ignoredApplications
        } header: {
            Text(localization.string(.clipboardPrivacyTitle))
        } footer: {
            Text(localization.string(.clipboardPrivacyPersistDescription) + "\n" + localization.string(.clipboardPrivacyIgnoredAppsHint))
        }
    }

    private var ignoredApplications: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(localization.string(.clipboardPrivacyIgnoredApps))
                Spacer()
                Button(localization.string(.behaviorAddApplications)) { addIgnoredApplication() }
                    .buttonStyle(.bordered)
            }
            ForEach(settingsStore.settings.clipboard.ignoredApplicationBundleIdentifiers, id: \.self) { identifier in
                HStack {
                    Text(identifier).font(.callout).foregroundStyle(.secondary)
                    Spacer()
                    Button(localization.string(.commonRemove)) { removeIgnoredApplication(identifier) }
                        .buttonStyle(.borderless)
                }
            }
        }
    }

    private var dataSection: some View {
        Section {
            LabeledContent(localization.string(.clipboardDataEntries), value: "\(coordinator.clipboard.model.entryCount)")
            LabeledContent(
                localization.string(.clipboardDataStorage),
                value: ClipboardRowPresenter.formattedBytes(coordinator.clipboard.model.retainedByteCount)
            )
            Button(localization.string(.clipboardDataClearUnpinned)) { coordinator.clipboardClearUnpinned() }
            Button(localization.string(.clipboardDataClearAll), role: .destructive) { showClearAllConfirm = true }
                .accessibilityIdentifier("ClipboardClearAllButton")
        } header: {
            Text(localization.string(.clipboardDataTitle))
        } footer: {
            Text(localization.string(.clipboardDataLimits))
        }
    }

    // MARK: - Bindings

    var persistBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.clipboard.persistsHistory },
            set: { newValue in
                if newValue {
                    settingsStore.update { $0.clipboard.persistsHistory = true }
                } else {
                    showPersistOffConfirm = true
                }
            }
        )
    }

    func confirmDisablePersistence() {
        settingsStore.update { $0.clipboard.persistsHistory = false }
    }

    private func kindBinding(_ kind: ClipboardContentKind) -> Binding<Bool> {
        Binding(
            get: { settingsStore.settings.clipboard.capturedKinds.contains(kind) },
            set: { isOn in
                settingsStore.update {
                    if isOn {
                        $0.clipboard.capturedKinds.insert(kind)
                    } else {
                        $0.clipboard.capturedKinds.remove(kind)
                    }
                }
            }
        )
    }

    private var filesBinding: Binding<Bool> {
        Binding(
            get: { settingsStore.settings.clipboard.capturedKinds.contains(.file) },
            set: { isOn in
                settingsStore.update {
                    if isOn {
                        $0.clipboard.capturedKinds.insert(.file)
                        $0.clipboard.capturedKinds.insert(.video)
                    } else {
                        $0.clipboard.capturedKinds.remove(.file)
                        $0.clipboard.capturedKinds.remove(.video)
                    }
                }
            }
        )
    }

    private func addIgnoredApplication() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.applicationBundle]
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        guard panel.runModal() == .OK, let url = panel.url,
              let bundle = Bundle(url: url), let identifier = bundle.bundleIdentifier
        else { return }
        settingsStore.update {
            if !$0.clipboard.ignoredApplicationBundleIdentifiers.contains(identifier) {
                $0.clipboard.ignoredApplicationBundleIdentifiers.append(identifier)
            }
        }
    }

    private func removeIgnoredApplication(_ identifier: String) {
        settingsStore.update {
            $0.clipboard.ignoredApplicationBundleIdentifiers.removeAll { $0 == identifier }
        }
    }

    private func setting<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        Binding(get: { settingsStore.settings[keyPath: keyPath] }, set: { value in settingsStore.update { $0[keyPath: keyPath] = value } })
    }
}
