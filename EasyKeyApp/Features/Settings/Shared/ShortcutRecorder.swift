import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct ShortcutRecorder: View {
    let label: String
    var description: String?
    @Binding var shortcut: Shortcut
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var recording = false

    var body: some View {
        LabeledContent {
            HStack(spacing: 8) {
                Text(localization.shortcutLabel(shortcut))
                    .monospaced()
                    .foregroundStyle(shortcut.isActive ? .primary : .secondary)
                    .padding(.horizontal, 8)
                    .frame(minHeight: 22)
                    .frame(minWidth: 95, alignment: .leading)
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: DesignScale.radiusSM))

                Group {
                    if recording {
                        Button(localization.string(.commonRecording)) { recording = true }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.large)
                    } else {
                        Button(localization.string(.commonRecord)) { recording = true }
                            .buttonStyle(.bordered)
                            .controlSize(.large)
                    }
                }
                .accessibilityLabel(localization.format(.a11yRecordShortcut, label))

                if shortcut.isActive {
                    Button(localization.string(.commonClear), role: .destructive) { shortcut = .none }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                        .accessibilityLabel(localization.format(.a11yClearShortcut, label))
                }
            }
            .fixedSize(horizontal: true, vertical: false)
            .background(ShortcutKeyCapture(isRecording: $recording, shortcut: $shortcut))
        } label: {
            SettingsControlLabel(title: label, description: description)
        }
    }
}

struct SettingsControlLabel: View {
    let title: String
    let description: String?

    init(title: String, description: String? = nil) {
        self.title = title
        self.description = description
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            if let description {
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
