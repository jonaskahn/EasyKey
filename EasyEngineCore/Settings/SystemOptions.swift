import Foundation

public struct SystemOptions: Codable, Equatable, Sendable {
    public enum MenuPopoverWidth: Int, Equatable, Sendable, CaseIterable {
        case compact = 280
        case small = 360
        case medium = 440
        case large = 520
        case extraLarge = 640
    }

    public var launchAtLogin: Bool
    public var showDockIcon: Bool
    public var grayMenuIcon: Bool
    public var showSettingsAtLaunch: Bool
    public var checkForUpdates: Bool
    public var menuPopoverWidth: MenuPopoverWidth

    public init(
        launchAtLogin: Bool = false,
        showDockIcon: Bool = false,
        grayMenuIcon: Bool = false,
        showSettingsAtLaunch: Bool = false,
        checkForUpdates: Bool = true,
        menuPopoverWidth: MenuPopoverWidth = .small
    ) {
        self.launchAtLogin = launchAtLogin
        self.showDockIcon = showDockIcon
        self.grayMenuIcon = grayMenuIcon
        self.showSettingsAtLaunch = showSettingsAtLaunch
        self.checkForUpdates = checkForUpdates
        self.menuPopoverWidth = menuPopoverWidth
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        launchAtLogin = try container.decodeIfPresent(Bool.self, forKey: .launchAtLogin) ?? false
        showDockIcon = try container.decodeIfPresent(Bool.self, forKey: .showDockIcon) ?? false
        grayMenuIcon = try container.decodeIfPresent(Bool.self, forKey: .grayMenuIcon) ?? false
        showSettingsAtLaunch = try container.decodeIfPresent(Bool.self, forKey: .showSettingsAtLaunch) ?? false
        checkForUpdates = try container.decodeIfPresent(Bool.self, forKey: .checkForUpdates) ?? true
        menuPopoverWidth = try container.decodeIfPresent(MenuPopoverWidth.self, forKey: .menuPopoverWidth) ?? .small
    }

    private enum CodingKeys: String, CodingKey {
        case launchAtLogin
        case showDockIcon
        case grayMenuIcon
        case showSettingsAtLaunch
        case checkForUpdates
        case menuPopoverWidth
    }
}

extension SystemOptions.MenuPopoverWidth: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(Int.self)
        switch rawValue {
        case 280: self = .compact
        case 360: self = .small
        case 420, 440: self = .medium
        case 520: self = .large
        case 640: self = .extraLarge
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid MenuPopoverWidth raw value: \(rawValue)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
