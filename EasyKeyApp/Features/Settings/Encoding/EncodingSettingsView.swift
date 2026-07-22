import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct EncodingSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var input = ""

    var body: some View {
        Form {
            Section {
                Picker(selection: setting(\.input.encoding)) {
                    ForEach(EncodingTable.allCases, id: \.self) { table in
                        Text(localization.displayName(for: table)).tag(table)
                    }
                } label: {
                    SettingsControlLabel(
                        title: localization.string(.encodingDefaultEncoding),
                        description: localization.string(.encodingDefaultEncodingDescription)
                    )
                }
            } header: {
                Text(localization.string(.encodingOutput))
            }

            Section {
                Picker(selection: setting(\.converter.sourceEncoding)) {
                    ForEach(EncodingTable.allCases, id: \.self) { table in
                        Text(localization.displayName(for: table)).tag(table)
                    }
                } label: {
                    SettingsControlLabel(
                        title: localization.string(.encodingFrom),
                        description: localization.string(.encodingFromDescription)
                    )
                }
                Picker(selection: setting(\.converter.destinationEncoding)) {
                    ForEach(EncodingTable.allCases, id: \.self) { table in
                        Text(localization.displayName(for: table)).tag(table)
                    }
                } label: {
                    SettingsControlLabel(
                        title: localization.string(.encodingTo),
                        description: localization.string(.encodingToDescription)
                    )
                }

                TextEditor(text: $input)
                    .font(.body.monospaced())
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 100)
                    .padding(4)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))
                    .accessibilityLabel(localization.string(.encodingSourceText))

                VStack(alignment: .leading, spacing: 6) {
                    Text(localization.string(.encodingPreview))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    Text(preview)
                        .font(.body.monospaced())
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, minHeight: 48, alignment: .topLeading)
                        .padding(8)
                        .background(.quaternary, in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))
                }

                HStack(spacing: 12) {
                    Button(localization.string(.encodingCopyTransformed)) { copyPreview() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    Button(localization.string(.encodingTransformClipboard)) { coordinator.convertClipboard() }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                }
            } header: {
                Text(localization.string(.encodingTextConverter))
            }
        }
        .formStyle(.grouped)
    }

    var preview: String {
        Converter.preview(input: input, configuration: .init(
            sourceEncoding: settingsStore.settings.converter.sourceEncoding,
            destinationEncoding: settingsStore.settings.converter.destinationEncoding
        ))
    }

    func copyPreview() {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(preview, forType: .string)
    }

    private func setting<T>(_ keyPath: WritableKeyPath<EasyKeySettings, T>) -> Binding<T> {
        settingsStore.binding(keyPath)
    }
}
