import EasyEngineCore
import SwiftUI

/// A provider selector that renders live `TranslationProviderIcon` rows in a popover.
///
/// `Menu` on macOS is backed by `NSMenu`, which flattens custom SwiftUI views in
/// item labels to text + a single template image — so the vector provider icons
/// never show up in the list. A popover hosts a real SwiftUI hierarchy, letting
/// each row draw its full-color icon.
struct TranslationProviderPickerButton: View {
    let selection: TranslationProviderID?
    let availableProviders: [TranslationProviderID]
    let providerLabel: (TranslationProviderID) -> String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let onSelect: (TranslationProviderID) -> Void

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            TranslationProviderIcon(provider: selection ?? .apple, size: 18)
                .frame(width: 34, height: 24)
                .contentShape(Rectangle())
        }
        .buttonStyle(TranslationProviderTriggerButtonStyle())
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            providerList
        }
    }

    private var providerList: some View {
        VStack(alignment: .leading, spacing: 2) {
            ForEach(availableProviders, id: \.self) { provider in
                row(provider: provider, isSelected: provider == selection)
            }
        }
        .padding(6)
        .frame(minWidth: 200)
    }

    private func row(provider: TranslationProviderID, isSelected: Bool) -> some View {
        Button {
            onSelect(provider)
            isPresented = false
        } label: {
            HStack(spacing: 8) {
                TranslationProviderIcon(provider: provider, size: 20)
                Text(providerLabel(provider))
                    .lineLimit(1)
                Spacer(minLength: 12)
                Image(systemName: "checkmark")
                    .font(.system(size: 11, weight: .semibold))
                    .opacity(isSelected ? 1 : 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .contentShape(Rectangle())
        }
        .buttonStyle(TranslationProviderRowButtonStyle())
    }
}

private struct TranslationProviderTriggerButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovering || configuration.isPressed ? Color.primary.opacity(0.08) : .clear)
            )
            .onHover { isHovering = $0 }
    }
}

private struct TranslationProviderRowButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(highlightFill(isPressed: configuration.isPressed))
            )
            .onHover { isHovering = $0 }
    }

    private func highlightFill(isPressed: Bool) -> Color {
        if isPressed {
            return Color.accentColor.opacity(0.28)
        }
        return isHovering ? Color.accentColor.opacity(0.16) : .clear
    }
}

struct TranslationProviderIcon: View {
    let provider: TranslationProviderID
    var size: CGFloat = 16

    init(provider: TranslationProviderID, size: CGFloat = 16) {
        self.provider = provider
        self.size = size
    }

    var body: some View {
        Group {
            switch provider {
            case .automatic: automaticIcon
            case .apple: appleIcon
            case .deepL: deepLIcon
            case .google: googleIcon
            case .openAI: openAIIcon
            case .anthropic: anthropicIcon
            case .gemini: geminiIcon
            case .openRouter: openRouterIcon
            case .groq: groqIcon
            case .openAICompatible: compatibleIcon(label: "O", color: .openAI)
            case .anthropicCompatible: compatibleIcon(label: "A", color: .anthropic)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private var automaticIcon: some View {
        symbolBadge("wand.and.stars", background: .automatic)
    }

    private var appleIcon: some View {
        symbolBadge("apple.logo", background: .apple)
    }

    private var deepLIcon: some View {
        symbolBadge("bubble.left.and.bubble.right.fill", background: .deepL)
    }

    private var googleIcon: some View {
        letterBadge("G", background: .google)
    }

    private var openAIIcon: some View {
        symbolBadge("hexagon", background: .openAI)
    }

    private var anthropicIcon: some View {
        letterBadge("A", background: .anthropic)
    }

    private var geminiIcon: some View {
        symbolBadge("sparkle", background: .gemini)
    }

    private var openRouterIcon: some View {
        symbolBadge("arrow.triangle.branch", background: .openRouter)
    }

    private var groqIcon: some View {
        letterBadge("g", background: .groq)
    }

    private func compatibleIcon(label: String, color: Color) -> some View {
        ZStack {
            letterBadge(label, background: color)
            Image(systemName: "link")
                .font(.system(size: size * 0.28, weight: .bold))
                .foregroundStyle(color)
                .padding(size * 0.09)
                .background(Circle().fill(.white))
                .offset(x: size * 0.30, y: size * 0.30)
        }
    }

    private func symbolBadge(_ symbol: String, background: Color) -> some View {
        badge(background: background) {
            Image(systemName: symbol)
                .font(.system(size: size * 0.54, weight: .semibold))
        }
    }

    private func letterBadge(_ letter: String, background: Color) -> some View {
        badge(background: background) {
            Text(letter)
                .font(.system(size: size * 0.58, weight: .bold, design: .rounded))
        }
    }

    private func badge<Content: View>(
        background: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.24, style: .continuous)
                .fill(background)
            content()
                .foregroundStyle(.white)
        }
    }
}

private extension Color {
    static let automatic = Color(red: 0.15, green: 0.48, blue: 0.92)
    static let apple = Color(red: 0.18, green: 0.18, blue: 0.20)
    static let deepL = Color(red: 0.06, green: 0.17, blue: 0.27)
    static let google = Color(red: 0.26, green: 0.52, blue: 0.96)
    static let openAI = Color(red: 0.06, green: 0.42, blue: 0.35)
    static let anthropic = Color(red: 0.73, green: 0.42, blue: 0.27)
    static let gemini = Color(red: 0.47, green: 0.40, blue: 0.82)
    static let openRouter = Color(red: 0.36, green: 0.42, blue: 0.51)
    static let groq = Color(red: 0.96, green: 0.31, blue: 0.21)
}
