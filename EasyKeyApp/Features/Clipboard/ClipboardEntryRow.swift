import EasyEngineCore
import SwiftUI

struct ClipboardEntryRow: View {
    let entry: ClipboardEntry
    @ObservedObject var thumbnailLoader: ClipboardThumbnailLoader
    @ObservedObject var localization: LocalizationStore
    var togglePin: () -> Void = {}

    private var isUnavailable: Bool {
        ClipboardRowPresenter.isUnavailable(entry)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            leading
            VStack(alignment: .leading, spacing: 4) {
                Text(ClipboardRowPresenter.primaryText(for: entry))
                    .lineLimit(2)
                    .font(.body)
                    .foregroundStyle(isUnavailable ? .secondary : .primary)
                HStack(spacing: 4) {
                    if isUnavailable {
                        Text(localization.string(.clipboardUnavailable))
                            .foregroundStyle(.red)
                    }
                    Text(ClipboardRowPresenter.metadata(for: entry, now: Date()))
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            }
            Spacer(minLength: 0)
            Button(action: togglePin) {
                Image(systemName: entry.isPinned ? "pin.fill" : "pin")
                    .font(.title3)
                    .foregroundStyle(entry.isPinned ? Color.accentColor : .secondary)
                    .frame(width: 28, height: 28)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.borderless)
            .help(entry.isPinned ? localization.string(.clipboardActionUnpin) : localization.string(.clipboardActionPin))
            .accessibilityLabel(entry.isPinned ? localization.string(.clipboardActionUnpin) : localization.string(.clipboardActionPin))
        }
        .padding(.vertical, 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder private var leading: some View {
        if let reference = imageReference, let thumbnail = thumbnailLoader.thumbnail(for: reference) {
            Image(nsImage: thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .clipShape(RoundedRectangle(cornerRadius: DesignScale.radiusSM))
        } else {
            Image(systemName: ClipboardRowPresenter.symbolName(for: entry.kind))
                .frame(width: 24, height: 24)
                .foregroundStyle(.secondary)
        }
    }

    private var imageReference: String? {
        for item in entry.items where item.kind == .image {
            for representation in item.representations {
                if case let .data(_, payloadReference) = representation {
                    return payloadReference
                }
            }
        }
        return nil
    }

    private var accessibilityLabel: String {
        var parts = [ClipboardRowPresenter.primaryText(for: entry), ClipboardRowPresenter.metadata(for: entry, now: Date())]
        if entry.isPinned {
            parts.append(localization.string(.clipboardActionPin))
        }
        return parts.joined(separator: ", ")
    }
}
