import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared
    let finish: () -> Void
    @State private var step = 0

    init(
        settingsStore: SettingsStore,
        coordinator: AppCoordinator,
        finish: @escaping () -> Void,
        initialStep: Int = 0
    ) {
        self.settingsStore = settingsStore
        self.coordinator = coordinator
        self.finish = finish
        _step = State(initialValue: initialStep)
    }

    private var title: String {
        let titles: [L10nKey] = [
            .onboardingWelcome, .onboardingAccessibility, .onboardingTypingMethod, .onboardingReady,
        ]
        return localization.string(titles[step])
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                HStack(spacing: 8) {
                    if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                       let nsImage = NSImage(contentsOfFile: path) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 24, height: 24)
                    } else {
                        Image(systemName: "keyboard")
                    }
                    Text(localization.string(.brandName))
                        .font(.headline)
                }
                Spacer()
                InterfaceLanguageMenu()
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 8)

            ProgressView(value: Double(step + 1), total: 4)
                .tint(.accentColor)
                .padding(.horizontal, 24)
                .accessibilityHidden(true)

            Spacer(minLength: 16)
            VStack(alignment: .leading, spacing: 12) {
                if let path = Bundle.main.path(forResource: "AppIcon", ofType: "icns"),
                   let nsImage = NSImage(contentsOfFile: path) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 48, height: 48)
                        .clipShape(RoundedRectangle(cornerRadius: DesignScale.radiusMD))
                } else {
                    Image(systemName: symbol)
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(.tint)
                        .accessibilityHidden(true)
                }
                Text(title)
                    .font(.largeTitle.weight(.semibold))
                    .accessibilityLabel(title)
                    .accessibilityIdentifier(onboardingTitleIdentifier)
                stepContent
            }
            .frame(maxWidth: 540, alignment: .leading)
            .padding(.horizontal, 32)
            .accessibilityElement(children: .contain)
            Spacer(minLength: 16)

            HStack {
                if step > 0 {
                    Button(localization.string(.commonBack)) { step -= 1 }
                        .buttonStyle(.bordered)
                        .accessibilityIdentifier("Back")
                }
                Spacer()
                Button(step == 3 ? localization.string(.onboardingFinish) : localization.string(.commonContinue)) {
                    if step == 3 {
                        finish()
                    } else {
                        step += 1
                    }
                }
                .keyboardShortcut(.defaultAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityIdentifier("OnboardingPrimary")
                .accessibilityLabel(step == 3 ? localization.string(.onboardingFinish) : localization.string(.commonContinue))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var stepContent: some View {
        OnboardingStepContent(step: step, coordinator: coordinator, settingsStore: settingsStore)
    }

    private var onboardingTitleIdentifier: String {
        ["Welcome", "Accessibility", "Typing method", "Ready"][step]
    }

    private var symbol: String {
        ["sparkles", "hand.raised", "keyboard", "checkmark.circle"][step]
    }
}

struct OnboardingStepContent: View {
    let step: Int
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject var settingsStore: SettingsStore
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        switch step {
        case 0:
            Text(localization.string(.onboardingWelcomeBody))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        case 1:
            VStack(alignment: .leading, spacing: 12) {
                Text(localization.string(.onboardingAccessibilityBody))
                    .fixedSize(horizontal: false, vertical: true)
                HealthPill(health: coordinator.keyboardHealth, paused: coordinator.keyboardPaused)
                if coordinator.keyboardHealth != .active {
                    Button(localization.string(.onboardingGrantAccessibility)) {
                        coordinator.requestAccessibilityPermission()
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("Grant Accessibility Access")
                }
            }
        case 2:
            Form {
                Picker(localization.string(.onboardingInputMethod), selection: Binding(
                    get: { settingsStore.settings.input.inputMethod },
                    set: { value in settingsStore.update { $0.input.inputMethod = value } }
                )) {
                    ForEach(InputMethod.allCases, id: \.self) { method in
                        Text(localization.displayName(for: method)).tag(method)
                    }
                }
                .accessibilityLabel(localization.string(.onboardingInputMethod))

                Picker(localization.string(.onboardingEncoding), selection: Binding(
                    get: { settingsStore.settings.input.encoding },
                    set: { value in settingsStore.update { $0.input.encoding = value } }
                )) {
                    ForEach(EncodingTable.allCases, id: \.self) { table in
                        Text(localization.displayName(for: table)).tag(table)
                    }
                }
                .accessibilityLabel(localization.string(.onboardingEncoding))
            }
            .formStyle(.grouped)
            .scrollDisabled(true)
            .frame(height: 120)
        default:
            VStack(alignment: .leading, spacing: 12) {
                Form {
                    Toggle(localization.string(.onboardingLaunchAtLogin), isOn: Binding(
                        get: { settingsStore.settings.system.launchAtLogin },
                        set: coordinator.setLaunchAtLogin
                    ))
                }
                .formStyle(.grouped)
                .scrollDisabled(true)

                HealthPill(health: coordinator.keyboardHealth, paused: coordinator.keyboardPaused)
                Text(localization.string(.onboardingReadyBody))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
