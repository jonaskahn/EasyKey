import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct HealthPill: View {
    let health: KeyboardService.Health
    let paused: Bool
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        Label(text, systemImage: health == .active && !paused ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
            .font(.callout)
            .foregroundStyle(health == .active && !paused ? .green : .orange)
            .padding(.horizontal, 10)
            .accessibilityLabel(text)
    }

    private var text: String {
        if paused {
            return localization.string(.healthPillPaused)
        }
        return health == .active
            ? localization.string(.healthPillActive)
            : localization.string(.healthPillPermission)
    }
}
