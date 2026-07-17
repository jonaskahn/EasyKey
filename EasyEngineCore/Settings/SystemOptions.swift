import Foundation

public struct SystemOptions: Codable, Equatable, Sendable {
    public var launchAtLogin: Bool
    public var showDockIcon: Bool
    public var grayMenuIcon: Bool
    public var showSettingsAtLaunch: Bool
    public var checkForUpdates: Bool

    public init(
        launchAtLogin: Bool = false,
        showDockIcon: Bool = false,
        grayMenuIcon: Bool = false,
        showSettingsAtLaunch: Bool = false,
        checkForUpdates: Bool = true
    ) {
        self.launchAtLogin = launchAtLogin
        self.showDockIcon = showDockIcon
        self.grayMenuIcon = grayMenuIcon
        self.showSettingsAtLaunch = showSettingsAtLaunch
        self.checkForUpdates = checkForUpdates
    }
}
