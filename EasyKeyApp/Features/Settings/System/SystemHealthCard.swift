import AppKit
import EasyEngineCore
import EasyKeyKit
import SwiftUI

struct SystemHealthCard: View {
    @ObservedObject var coordinator: AppCoordinator
    @ObservedObject private var localization = LocalizationStore.shared

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(color)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(color)
                Text(detail)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.bottom, 6)

                if coordinator.keyboardHealth == .requestingPermission {
                    Button(localization.string(.onboardingGrantAccessibility)) { coordinator.requestAccessibilityPermission() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else if coordinator.keyboardPaused {
                    Button(localization.string(.healthResumeService)) { coordinator.keyboardService.togglePause() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                } else if coordinator.keyboardHealth == .failed || coordinator.keyboardHealth == .degraded {
                    Button(localization.string(.healthRestartService)) { coordinator.restartKeyboardService() }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.08), in: RoundedRectangle(cornerRadius: DesignScale.radiusMD))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(detail)")
    }

    private var title: String {
        if coordinator.keyboardPaused {
            return localization.string(.healthPaused)
        }
        switch coordinator.keyboardHealth {
        case .active: return localization.string(.healthActive)
        case .requestingPermission: return localization.string(.healthPermissionNeeded)
        case .degraded: return localization.string(.healthNeedsAttention)
        case .failed: return localization.string(.healthFailed)
        case .stopped: return localization.string(.healthStopped)
        }
    }

    private var detail: String {
        if coordinator.keyboardPaused {
            return localization.string(.healthPausedDetail)
        }
        if coordinator.keyboardHealth == .active {
            if let latencyNanos = coordinator.keyboardService.medianCallbackLatencyNanoseconds() {
                let ms = Double(latencyNanos) / 1_000_000.0
                return "\(localization.string(.healthActiveDetail)) (\(String(format: "%.2f", ms)) ms)"
            }
            return localization.string(.healthActiveDetail)
        }
        return localization.string(.healthProblemDetail)
    }

    private var symbol: String {
        coordinator.keyboardHealth == .active && !coordinator.keyboardPaused ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
    }

    private var color: Color {
        coordinator.keyboardHealth == .active && !coordinator.keyboardPaused ? .green : (coordinator.keyboardPaused ? .orange : .red)
    }
}
