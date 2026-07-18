import Foundation

/// User-configurable clipboard-manager policy. Framework-free so `EasyEngineCore`
/// owns product rules while the app layer owns pasteboard, keychain, and UI.
public struct ClipboardOptions: Codable, Equatable, Sendable {
    public var isCaptureEnabled: Bool
    public var shortcut: Shortcut
    public var selectionAction: ClipboardSelectionAction
    public var maximumEntryCount: Int
    public var retentionDays: Int
    public var persistsHistory: Bool
    public var capturedKinds: Set<ClipboardContentKind>
    public var ignoredApplicationBundleIdentifiers: [String]

    public init(
        isCaptureEnabled: Bool = false,
        shortcut: Shortcut = Shortcut(keyCode: 9, modifiers: [.option]),
        selectionAction: ClipboardSelectionAction = .pasteImmediately,
        maximumEntryCount: Int = 100,
        retentionDays: Int = 7,
        persistsHistory: Bool = false,
        capturedKinds: Set<ClipboardContentKind> = ClipboardContentKind.capturable,
        ignoredApplicationBundleIdentifiers: [String] = []
    ) {
        self.isCaptureEnabled = isCaptureEnabled
        self.shortcut = shortcut
        self.selectionAction = selectionAction
        self.maximumEntryCount = maximumEntryCount
        self.retentionDays = retentionDays
        self.persistsHistory = persistsHistory
        self.capturedKinds = capturedKinds
        self.ignoredApplicationBundleIdentifiers = ignoredApplicationBundleIdentifiers
    }

    /// Whether the supplied kind is permitted by the current content filter.
    public func captures(_ kind: ClipboardContentKind) -> Bool {
        switch kind {
        case .mixed:
            true
        default:
            capturedKinds.contains(kind)
        }
    }
}

public enum ClipboardSelectionAction: String, Codable, Equatable, Sendable, CaseIterable {
    case pasteImmediately
    case copyOnly
}
