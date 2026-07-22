import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct AboutSettingsView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject private var localization = LocalizationStore.shared
    @State private var showsThirdPartyNotices = false

    private static let author = "jonaskahn"
    private static let githubDisplay = "Github"
    private static let githubURL = URL(string: "https://jonaskahn.github.io/EasyKey/")
        ?? URL(fileURLWithPath: "/")

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
                Text(localization.string(.aboutTrademarksDescription))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } header: {
                Text(localization.string(.aboutTrademarks))
            }

            Section {
                Button(localization.string(.aboutOpenSourceLicenses)) {
                    showsThirdPartyNotices = true
                }
                .accessibilityIdentifier("OpenSourceLicenses")
            } header: {
                Text(localization.string(.aboutLegal))
            }
        }
        .formStyle(.grouped)
        .sheet(isPresented: $showsThirdPartyNotices) {
            ThirdPartyNoticesSheet()
        }
    }

    private var appVersion: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.6"
    }
}

struct ThirdPartyNoticesSheet: View {
    @ObservedObject private var localization = LocalizationStore.shared
    @Environment(\.dismiss) private var dismiss

    private var notices: String {
        guard let url = Bundle.main.url(forResource: "THIRD_PARTY_NOTICES", withExtension: "md"),
              let contents = try? String(contentsOf: url, encoding: .utf8)
        else {
            return localization.string(.aboutNoticesUnavailable)
        }
        return contents
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(localization.string(.aboutThirdPartyNotices))
                .font(.title2.weight(.semibold))

            ScrollView {
                Text(notices)
                    .font(.body.monospaced())
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .textSelection(.enabled)
                    .accessibilityIdentifier("ThirdPartyNoticesText")
            }

            HStack {
                Spacer()
                Button(localization.string(.commonDone)) { dismiss() }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("ThirdPartyNoticesDone")
            }
        }
        .padding(24)
        .frame(minWidth: 640, idealWidth: 720, minHeight: 480, idealHeight: 600)
    }
}
