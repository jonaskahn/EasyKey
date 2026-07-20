import EasyEngineCore
import SwiftUI

/// Commands the panel issues. Views invoke these; they never mutate history or
/// the pasteboard directly.
struct ClipboardPanelActions {
    var primary: (ClipboardEntry) -> Void
    var copy: (ClipboardEntry) -> Void
    var togglePin: (ClipboardEntry) -> Void
    var delete: (ClipboardEntry) -> Void
    var reveal: (ClipboardEntry) -> Void
    var clearUnpinned: () -> Void
    var openSettings: () -> Void
}

struct ClipboardPanelView: View {
    @ObservedObject var model: ClipboardHistoryModel
    @ObservedObject var thumbnailLoader: ClipboardThumbnailLoader
    @ObservedObject var localization: LocalizationStore
    let actions: ClipboardPanelActions

    @State private var query = ""
    @State private var selection: UUID?

    init(
        model: ClipboardHistoryModel,
        thumbnailLoader: ClipboardThumbnailLoader,
        localization: LocalizationStore,
        actions: ClipboardPanelActions
    ) {
        self.model = model
        self.thumbnailLoader = thumbnailLoader
        self.localization = localization
        self.actions = actions
    }

    private var results: [ClipboardEntry] {
        model.history.entries(matching: query)
    }

    private var pinned: [ClipboardEntry] {
        results.filter(\.isPinned)
    }

    private var recent: [ClipboardEntry] {
        results.filter { !$0.isPinned }
    }

    var body: some View {
        VStack(spacing: 0) {
            searchField
            Divider()
            content
            Divider()
            footer
        }
        .frame(minWidth: 380, minHeight: 440)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
            TextField(localization.string(.clipboardSearchPlaceholder), text: $query)
                .textFieldStyle(.plain)
                .accessibilityIdentifier("ClipboardSearchField")
        }
        .padding(12)
    }

    @ViewBuilder private var content: some View {
        if results.isEmpty {
            emptyState
        } else {
            List(selection: $selection) {
                if !pinned.isEmpty {
                    Section(localization.string(.clipboardSectionPinned)) {
                        ForEach(pinned) { row(for: $0) }
                    }
                }
                if !recent.isEmpty {
                    Section(localization.string(.clipboardSectionRecent)) {
                        ForEach(recent) { row(for: $0) }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    private func row(for entry: ClipboardEntry) -> some View {
        ClipboardEntryRow(
            entry: entry,
            thumbnailLoader: thumbnailLoader,
            localization: localization,
            togglePin: { actions.togglePin(entry) }
        )
        .tag(entry.id)
        .contentShape(Rectangle())
        .onTapGesture { actions.primary(entry) }
        .contextMenu { contextMenu(for: entry) }
    }

    @ViewBuilder private func contextMenu(for entry: ClipboardEntry) -> some View {
        Button(localization.string(.clipboardActionPaste)) { actions.primary(entry) }
        Button(localization.string(.clipboardActionCopy)) { actions.copy(entry) }
        Button(entry.isPinned ? localization.string(.clipboardActionUnpin) : localization.string(.clipboardActionPin)) {
            actions.togglePin(entry)
        }
        if canReveal(entry) {
            Button(localization.string(.clipboardActionReveal)) { actions.reveal(entry) }
        }
        Divider()
        Button(localization.string(.clipboardActionDelete), role: .destructive) { actions.delete(entry) }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "doc.on.clipboard").font(.system(size: 32)).foregroundStyle(.secondary)
            Text(query.isEmpty ? localization.string(.clipboardEmpty) : localization.string(.clipboardNoResults))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var footer: some View {
        HStack {
            Text(localization.string(.clipboardHint))
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            Button(localization.string(.clipboardActionSettings)) { actions.openSettings() }
                .buttonStyle(.link)
            Button(localization.string(.clipboardDataClearUnpinned)) { actions.clearUnpinned() }
                .buttonStyle(.link)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private func canReveal(_ entry: ClipboardEntry) -> Bool {
        entry.items.contains { item in
            item.representations.contains {
                if case .fileURL = $0 {
                    true
                } else {
                    false
                }
            }
        }
    }
}
