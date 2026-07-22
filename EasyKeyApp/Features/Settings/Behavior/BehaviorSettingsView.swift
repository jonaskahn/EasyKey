import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI
import UniformTypeIdentifiers

struct BehaviorSettingsView: View {
    enum ApplicationList {
        case compatibilityMode
        case ignored
    }

    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var applicationError = ""
    @State private var showsApplicationError = false
    @State private var compatibilityDropTargeted = false
    @State private var ignoredDropTargeted = false

    var body: some View {
        Form {
            Section {
                Toggle(isOn: setting(\.compatibility.otherLanguageSupport)) {
                    SettingsControlLabel(
                        title: localization.string(.behaviorOtherLanguageSupport),
                        description: localization.string(.behaviorOtherLanguageSupportDescription)
                    )
                }
                .toggleStyle(.switch)
            } header: {
                Text(localization.string(.behaviorAppCompatibility))
            }

            Section {
                Text(localization.string(.behaviorCompatibilityModeHint))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                applicationRegistry(
                    bundleIdentifiers: settingsStore.settings.compatibility.compatibilityModeApplicationBundleIdentifiers,
                    emptyMessage: localization.string(.behaviorCompatibilityModeEmpty),
                    list: .compatibilityMode,
                    isDropTargeted: $compatibilityDropTargeted
                )
            } header: {
                Text(localization.string(.behaviorCompatibilityMode))
            }

            Section {
                Text(localization.string(.behaviorIgnoredApplicationsHint))
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                applicationRegistry(
                    bundleIdentifiers: settingsStore.settings.compatibility.ignoredApplicationBundleIdentifiers,
                    emptyMessage: localization.string(.behaviorIgnoredApplicationsEmpty),
                    list: .ignored,
                    isDropTargeted: $ignoredDropTargeted
                )
            } header: {
                Text(localization.string(.behaviorIgnoredApplications))
            }
        }
        .formStyle(.grouped)
        .alert(localization.string(.behaviorApplicationInvalid), isPresented: $showsApplicationError) {
            Button(localization.string(.commonOk), role: .cancel) {}
        } message: {
            Text(applicationError)
        }
    }

    @ViewBuilder
    private func applicationRegistry(
        bundleIdentifiers: [String],
        emptyMessage: String,
        list: ApplicationList,
        isDropTargeted: Binding<Bool>
    ) -> some View {
        if bundleIdentifiers.isEmpty {
            Text(emptyMessage)
                .foregroundStyle(.secondary)
        } else {
            ForEach(bundleIdentifiers, id: \.self) { bundleIdentifier in
                applicationRow(applicationInfo(for: bundleIdentifier)) {
                    forget(bundleIdentifier, from: list)
                }
            }
        }

        HStack(spacing: 12) {
            Button(localization.string(.behaviorAddApplications)) {
                chooseApplications(for: list)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)

            Text(localization.string(.behaviorDropApplications))
                .font(.caption.weight(.semibold))
                .foregroundStyle(isDropTargeted.wrappedValue ? Color.accentColor : .secondary)
                .frame(maxWidth: .infinity, minHeight: 30)
                .overlay {
                    RoundedRectangle(cornerRadius: DesignScale.radiusSM)
                        .strokeBorder(
                            isDropTargeted.wrappedValue ? Color.accentColor : Color(NSColor.separatorColor),
                            style: StrokeStyle(lineWidth: 1, dash: [5, 4])
                        )
                }
                .onDrop(of: [UTType.fileURL.identifier], isTargeted: isDropTargeted) { providers in
                    acceptDrop(providers, into: list)
                }
        }
    }

    private func applicationRow(_ application: ApplicationInfo, forget: @escaping () -> Void) -> some View {
        HStack(spacing: 10) {
            applicationLabel(application)
            Spacer()
            Button(localization.string(.commonRemove), role: .destructive, action: forget)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("\(localization.string(.commonRemove)) \(application.name)")
        }
    }

    private func applicationLabel(_ application: ApplicationInfo) -> some View {
        HStack(spacing: 10) {
            if let icon = application.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 24, height: 24)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(application.name)
                Text(application.id)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func applicationInfo(for bundleIdentifier: String) -> ApplicationInfo {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) else {
            return ApplicationInfo(id: bundleIdentifier, name: bundleIdentifier, icon: nil)
        }
        let bundle = Bundle(url: url)
        let name = bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle?.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? url.deletingPathExtension().lastPathComponent
        return ApplicationInfo(
            id: bundleIdentifier,
            name: name,
            icon: NSWorkspace.shared.icon(forFile: url.path)
        )
    }

    private func chooseApplications(for list: ApplicationList) {
        let panel = NSOpenPanel()
        panel.title = localization.string(.behaviorAddApplications)
        panel.directoryURL = URL(fileURLWithPath: "/Applications", isDirectory: true)
        panel.allowedContentTypes = [.applicationBundle]
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        addApplications(at: panel.urls, to: list)
    }

    func acceptDrop(_ providers: [NSItemProvider], into list: ApplicationList) -> Bool {
        let matchingProviders = providers.filter { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }
        guard !matchingProviders.isEmpty else { return false }

        let group = DispatchGroup()
        let lock = NSLock()
        var loadedURLs = [URL?](repeating: nil, count: matchingProviders.count)
        for (index, provider) in matchingProviders.enumerated() {
            group.enter()
            provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
                defer { group.leave() }
                let url: URL? = if let data = item as? Data {
                    URL(dataRepresentation: data, relativeTo: nil)
                } else if let value = item as? URL {
                    value
                } else if let value = item as? NSURL {
                    value as URL
                } else {
                    nil
                }
                lock.lock()
                loadedURLs[index] = url
                lock.unlock()
            }
        }
        group.notify(queue: .main) {
            addApplications(at: loadedURLs.compactMap(\.self), to: list)
        }
        return true
    }

    func addApplications(at urls: [URL], to list: ApplicationList) {
        var bundleIdentifiers: [String] = []
        var invalidNames: [String] = []
        for url in urls {
            guard let bundleIdentifier = ApplicationBundleSelection.bundleIdentifier(at: url) else {
                invalidNames.append(url.lastPathComponent)
                continue
            }
            if !bundleIdentifiers.contains(bundleIdentifier) {
                bundleIdentifiers.append(bundleIdentifier)
            }
        }

        if !bundleIdentifiers.isEmpty {
            settingsStore.update { settings in
                switch list {
                case .compatibilityMode:
                    appendUnique(bundleIdentifiers, to: &settings.compatibility.compatibilityModeApplicationBundleIdentifiers)
                case .ignored:
                    appendUnique(bundleIdentifiers, to: &settings.compatibility.ignoredApplicationBundleIdentifiers)
                }
            }
        }
        if !invalidNames.isEmpty {
            applicationError = invalidNames.joined(separator: ", ")
            showsApplicationError = true
        }
    }

    func appendUnique(_ additions: [String], to values: inout [String]) {
        for value in additions where !values.contains(value) {
            values.append(value)
        }
    }

    func forget(_ bundleIdentifier: String, from list: ApplicationList) {
        settingsStore.update { settings in
            switch list {
            case .compatibilityMode:
                settings.compatibility.compatibilityModeApplicationBundleIdentifiers.removeAll { $0 == bundleIdentifier }
            case .ignored:
                settings.compatibility.ignoredApplicationBundleIdentifiers.removeAll { $0 == bundleIdentifier }
            }
        }
    }

    func setting<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        settingsStore.binding(keyPath)
    }
}

private struct ApplicationInfo: Identifiable {
    let id: String
    let name: String
    let icon: NSImage?
}

enum ApplicationBundleSelection {
    static func bundleIdentifier(at url: URL) -> String? {
        guard url.pathExtension.localizedCaseInsensitiveCompare("app") == .orderedSame,
              let bundle = Bundle(url: url),
              bundle.object(forInfoDictionaryKey: "CFBundlePackageType") as? String == "APPL",
              bundle.executableURL != nil,
              let bundleIdentifier = bundle.bundleIdentifier,
              !bundleIdentifier.isEmpty
        else {
            return nil
        }
        return bundleIdentifier
    }
}
