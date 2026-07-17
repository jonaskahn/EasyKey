import SwiftUI

struct UpdateAvailableView: View {
    let currentVersion: String
    let latestVersion: String
    let releaseNotes: String?
    let downloadURL: String
    let onDismiss: () -> Void
    let onDownload: () -> Void

    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.down.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.tint)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string(.updateAvailableTitle))
                        .font(.headline)

                    Text(String(format: localization.string(.updateAvailableVersion), latestVersion))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let releaseNotes {
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.string(.updateReleaseNotes))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Text(releaseNotes)
                        .lineLimit(3)
                }
            }

            HStack {
                Text(String(format: localization.string(.updateCurrentVersion), currentVersion))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)

                Spacer()
            }

            HStack {
                Spacer()
                Button(localization.string(.commonCancel)) {
                    onDismiss()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .keyboardShortcut(.cancelAction)

                Button(localization.string(.updateDownloadButton)) {
                    onDownload()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 400)
        .easyKeyButtonShape()
    }
}

struct UpToDateView: View {
    let currentVersion: String
    let onDismiss: () -> Void

    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string(.updateUpToDateTitle))
                        .font(.headline)

                    Text(String(format: localization.string(.updateUpToDateMessage), currentVersion))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Button(localization.string(.commonOk)) {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
        .easyKeyButtonShape()
    }
}

struct UpdateCheckErrorView: View {
    let onDismiss: () -> Void

    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.orange)

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.string(.updateErrorTitle))
                        .font(.headline)

                    Text(localization.string(.updateErrorMessage))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            HStack {
                Spacer()
                Button(localization.string(.commonOk)) {
                    onDismiss()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 350)
        .easyKeyButtonShape()
    }
}
