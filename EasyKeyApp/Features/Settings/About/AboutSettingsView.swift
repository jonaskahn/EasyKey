import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct AboutSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var confirmReset = false

    private static let author = "jonaskahn"
    private static let githubDisplay = "Github"
    private static let githubURL = URL(string: "https://jonaskahn.github.io/EasyKey/")!

    var body: some View {
        Form {
            Section {
                HStack(spacing: 16) {
                    if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                       let nsImage = NSImage(contentsOfFile: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: DesignScale.radiusMD))
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.string(.brandName))
                            .font(.headline)
                        Text(localization.string(.aboutTagline))
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent(localization.string(.commonVersion), value: appVersion)
                    .textSelection(.enabled)
                LabeledContent(localization.string(.aboutAuthor), value: Self.author)
                    .textSelection(.enabled)
                LabeledContent(localization.string(.aboutGithub)) {
                    Link(Self.githubDisplay, destination: Self.githubURL)
                }
            } header: {
                Text(localization.string(.brandEasykey))
            } footer: {
                Text(localization.string(.helpAboutEasyKey))
            }

            Section {
                InterfaceLanguagePicker()
            } header: {
                Text(localization.string(.aboutInterface))
            }

            Section {
                Text(localization.string(.aboutTrademarksDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(localization.string(.aboutTrademarks))
            }

            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Button(localization.string(.aboutResetSettings), role: .destructive) { confirmReset = true }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                        .tint(.red)
                    Text(localization.string(.aboutResetSettingsDescription))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } header: {
                Text(localization.string(.aboutMaintenance))
            }
        }
        .formStyle(.grouped)
        .alert(localization.string(.aboutResetConfirmTitle), isPresented: $confirmReset) {
            Button(localization.string(.commonReset), role: .destructive) { settingsStore.reset() }
            Button(localization.string(.commonCancel), role: .cancel) {}
        } message: {
            Text(localization.string(.aboutResetConfirmMessage))
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.2"
    }
}
