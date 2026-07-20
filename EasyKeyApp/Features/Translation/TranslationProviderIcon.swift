import SwiftUI
import EasyEngineCore

// MARK: - Custom Vector Shapes for Official Logos

struct AppleBittenLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.30))
        
        // Top-right curve to the shoulder
        path.addCurve(to: CGPoint(x: w * 0.74, y: h * 0.38),
                      control1: CGPoint(x: w * 0.60, y: h * 0.23),
                      control2: CGPoint(x: w * 0.72, y: h * 0.28))
        
        // Bite on the right: concave curve inward
        path.addCurve(to: CGPoint(x: w * 0.72, y: h * 0.68),
                      control1: CGPoint(x: w * 0.60, y: h * 0.48),
                      control2: CGPoint(x: w * 0.60, y: h * 0.58))
        
        // Bottom-right curve
        path.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.86),
                      control1: CGPoint(x: w * 0.78, y: h * 0.80),
                      control2: CGPoint(x: w * 0.62, y: h * 0.86))
        
        // Bottom-left curve
        path.addCurve(to: CGPoint(x: w * 0.28, y: h * 0.68),
                      control1: CGPoint(x: w * 0.38, y: h * 0.86),
                      control2: CGPoint(x: w * 0.22, y: h * 0.80))
        
        // Left side curve to top-left shoulder
        path.addCurve(to: CGPoint(x: w * 0.26, y: h * 0.38),
                      control1: CGPoint(x: w * 0.32, y: h * 0.58),
                      control2: CGPoint(x: w * 0.22, y: h * 0.48))
        
        // Top-left shoulder to the dip
        path.addCurve(to: CGPoint(x: w * 0.50, y: h * 0.30),
                      control1: CGPoint(x: w * 0.28, y: h * 0.28),
                      control2: CGPoint(x: w * 0.40, y: h * 0.23))
        
        path.closeSubpath()
        return path
    }
}

struct AppleLeafShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.28))
        path.addQuadCurve(to: CGPoint(x: w * 0.68, y: h * 0.10), control: CGPoint(x: w * 0.64, y: h * 0.28))
        path.addQuadCurve(to: CGPoint(x: w * 0.50, y: h * 0.28), control: CGPoint(x: w * 0.48, y: h * 0.10))
        path.closeSubpath()
        return path
    }
}

struct OpenAISpiralShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5
        let cy = h * 0.5
        
        // A single curved spoke/loop of the OpenAI logo
        path.move(to: CGPoint(x: cx, y: cy - h * 0.05))
        path.addLine(to: CGPoint(x: cx, y: cy - h * 0.26))
        path.addCurve(to: CGPoint(x: cx + w * 0.18, y: cy - h * 0.15),
                      control1: CGPoint(x: cx + w * 0.14, y: cy - h * 0.33),
                      control2: CGPoint(x: cx + w * 0.25, y: cy - h * 0.22))
        path.addCurve(to: CGPoint(x: cx + w * 0.05, y: cy),
                      control1: CGPoint(x: cx + w * 0.12, y: cy - h * 0.08),
                      control2: CGPoint(x: cx + w * 0.08, y: cy - h * 0.02))
        return path
    }
}

struct AnthropicLogoShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        
        // Distressed geometric 'A'
        path.move(to: CGPoint(x: w * 0.20, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.18))
        path.addLine(to: CGPoint(x: w * 0.80, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.65, y: h * 0.82))
        path.addLine(to: CGPoint(x: w * 0.58, y: h * 0.60))
        path.addLine(to: CGPoint(x: w * 0.42, y: h * 0.60))
        path.addLine(to: CGPoint(x: w * 0.35, y: h * 0.82))
        path.closeSubpath()
        
        // Inner triangle cutout
        path.move(to: CGPoint(x: w * 0.50, y: h * 0.34))
        path.addLine(to: CGPoint(x: w * 0.55, y: h * 0.50))
        path.addLine(to: CGPoint(x: w * 0.45, y: h * 0.50))
        path.closeSubpath()
        
        return path
    }
}

struct GeminiSparkleShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = w * 0.5
        let cy = h * 0.5
        
        path.move(to: CGPoint(x: cx, y: cy - h * 0.42))
        // Top to right
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.42, y: cy), control: CGPoint(x: cx, y: cy))
        // Right to bottom
        path.addQuadCurve(to: CGPoint(x: cx, y: cy + h * 0.42), control: CGPoint(x: cx, y: cy))
        // Bottom to left
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.42, y: cy), control: CGPoint(x: cx, y: cy))
        // Left to top
        path.addQuadCurve(to: CGPoint(x: cx, y: cy - h * 0.42), control: CGPoint(x: cx, y: cy))
        path.closeSubpath()
        return path
    }
}

// MARK: - TranslationProviderPickerButton

/// A provider selector that renders live `TranslationProviderIcon` rows in a popover.
///
/// `Menu` on macOS is backed by `NSMenu`, which flattens custom SwiftUI views in
/// item labels to text + a single template image — so the vector provider icons
/// never show up in the list. A popover hosts a real SwiftUI hierarchy, letting
/// each row draw its full-color icon.
struct TranslationProviderPickerButton: View {
    let selection: TranslationProviderID?
    let availableProviders: [TranslationProviderID]
    let chooseTitle: String
    let providerLabel: (TranslationProviderID) -> String
    let accessibilityLabel: String
    let accessibilityIdentifier: String
    let onSelect: (TranslationProviderID?) -> Void

    @State private var isPresented = false

    var body: some View {
        Button {
            isPresented.toggle()
        } label: {
            TranslationProviderIcon(provider: selection ?? .automatic, size: 14)
                .frame(width: 28, height: 22)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .help(accessibilityLabel)
        .accessibilityIdentifier(accessibilityIdentifier)
        .popover(isPresented: $isPresented, arrowEdge: .bottom) {
            providerList
        }
    }

    private var providerList: some View {
        VStack(alignment: .leading, spacing: 2) {
            row(provider: nil, title: chooseTitle, isSelected: selection == nil)
            if !availableProviders.isEmpty {
                Divider().padding(.vertical, 2)
            }
            ForEach(availableProviders, id: \.self) { provider in
                row(provider: provider, title: providerLabel(provider), isSelected: provider == selection)
            }
        }
        .padding(6)
        .frame(minWidth: 200)
    }

    private func row(provider: TranslationProviderID?, title: String, isSelected: Bool) -> some View {
        Button {
            onSelect(provider)
            isPresented = false
        } label: {
            HStack(spacing: 8) {
                TranslationProviderIcon(provider: provider ?? .automatic, size: 16)
                Text(title)
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

private struct TranslationProviderRowButtonStyle: ButtonStyle {
    @State private var isHovering = false

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(.primary)
            .background(
                RoundedRectangle(cornerRadius: 5)
                    .fill(isHovering ? Color(nsColor: .selectedContentBackgroundColor).opacity(0.22) : .clear)
            )
            .onHover { isHovering = $0 }
    }
}

// MARK: - TranslationProviderIcon

public struct TranslationProviderIcon: View {
    public let provider: TranslationProviderID
    public var size: CGFloat = 16

    public init(provider: TranslationProviderID, size: CGFloat = 16) {
        self.provider = provider
        self.size = size
    }

    public var body: some View {
        ZStack {
            switch provider {
            case .automatic:
                automaticIcon
            case .apple:
                appleIcon
            case .deepL:
                deepLIcon
            case .google:
                googleIcon
            case .openAI:
                openAIIcon
            case .anthropic:
                anthropicIcon
            case .gemini:
                geminiIcon
            case .openRouter:
                openRouterIcon
            case .groq:
                groqIcon
            case .openAICompatible:
                openAICompatibleIcon
            case .anthropicCompatible:
                anthropicCompatibleIcon
            }
        }
        .frame(width: size, height: size)
    }

    // MARK: - Provider Icons

    private var automaticIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.15, green: 0.55, blue: 0.9), Color(red: 0.1, green: 0.3, blue: 0.75)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let stroke = w * 0.08
                
                // Globe outline
                Circle()
                    .stroke(Color.white.opacity(0.85), lineWidth: stroke)
                    .frame(width: w * 0.6, height: h * 0.6)
                    .position(x: w * 0.5, y: h * 0.5)

                Ellipse()
                    .stroke(Color.white.opacity(0.7), lineWidth: stroke)
                    .frame(width: w * 0.3, height: h * 0.6)
                    .position(x: w * 0.5, y: h * 0.5)
                
                Path { path in
                    path.move(to: CGPoint(x: w * 0.2, y: h * 0.5))
                    path.addLine(to: CGPoint(x: w * 0.8, y: h * 0.5))
                }
                .stroke(Color.white.opacity(0.7), lineWidth: stroke)
            }
        }
    }

    private var appleIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(white: 0.92), Color(white: 0.62)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Official Bitten Apple shape and leaf
                AppleBittenLogoShape()
                    .fill(Color.white)
                
                AppleLeafShape()
                    .fill(Color.white)
            }
        }
    }

    private var deepLIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(red: 0.0, green: 0.41, blue: 0.45)) // DeepL Signature Teal
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Lowercase white "d"
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.38, height: h * 0.38)
                    .position(x: w * 0.42, y: h * 0.58)

                Capsule()
                    .fill(Color.white)
                    .frame(width: w * 0.10, height: h * 0.48)
                    .position(x: w * 0.61, y: h * 0.48)

                // Plus symbol "+" inside the loop
                Path { path in
                    let plusSize = w * 0.16
                    let cx = w * 0.42
                    let cy = h * 0.58
                    
                    path.move(to: CGPoint(x: cx - plusSize/2, y: cy))
                    path.addLine(to: CGPoint(x: cx + plusSize/2, y: cy))
                    
                    path.move(to: CGPoint(x: cx, y: cy - plusSize/2))
                    path.addLine(to: CGPoint(x: cx, y: cy + plusSize/2))
                }
                .stroke(Color(red: 0.0, green: 0.41, blue: 0.45), style: StrokeStyle(lineWidth: w * 0.06, lineCap: .round))
            }
        }
    }

    private var googleIcon: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            // Official Google Translate overlapping blue & white cards
            ZStack {
                // White card (Right-bottom)
                RoundedRectangle(cornerRadius: w * 0.12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.18), radius: w * 0.06, x: w * 0.02, y: w * 0.04)
                    .frame(width: w * 0.58, height: h * 0.58)
                    .position(x: w * 0.65, y: h * 0.62)

                // Front blue card (Left-top)
                RoundedRectangle(cornerRadius: w * 0.12)
                    .fill(Color(red: 0.26, green: 0.52, blue: 0.96)) // Google Translate Blue
                    .frame(width: w * 0.58, height: h * 0.58)
                    .position(x: w * 0.38, y: h * 0.42)

                // White "G" in blue card
                Text("G")
                    .font(.system(size: w * 0.32, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
                    .position(x: w * 0.38, y: h * 0.42)

                // Blue/Grey "文" in white card
                Text("文")
                    .font(.system(size: w * 0.32, weight: .semibold, design: .rounded))
                    .foregroundColor(Color(red: 0.26, green: 0.52, blue: 0.96))
                    .position(x: w * 0.65, y: h * 0.62)
            }
        }
    }

    private var openAIIcon: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.06, green: 0.64, blue: 0.5)) // OpenAI Emerald Green
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Spiral rosette of 6 curves
                ForEach(0..<6) { i in
                    OpenAISpiralShape()
                        .stroke(Color.white, style: StrokeStyle(lineWidth: w * 0.045, lineCap: .round, lineJoin: .round))
                        .rotationEffect(.degrees(Double(i) * 60.0), anchor: .center)
                }
            }
        }
    }

    private var anthropicIcon: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.98, green: 0.95, blue: 0.91)) // Warm Clay background
            
            GeometryReader { geo in
                // Stylized distressed A
                AnthropicLogoShape()
                    .fill(Color(red: 0.15, green: 0.14, blue: 0.12)) // Charcoal/Brown
            }
        }
    }

    private var geminiIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.35, green: 0.6, blue: 0.98), Color(red: 0.6, green: 0.3, blue: 0.92)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Primary Sparkle
                GeminiSparkleShape()
                    .fill(Color.white)
                    .frame(width: w * 0.7, height: h * 0.7)
                    .position(x: w * 0.44, y: h * 0.56)

                // Secondary Sparkle
                GeminiSparkleShape()
                    .fill(Color.white.opacity(0.85))
                    .frame(width: w * 0.35, height: h * 0.35)
                    .position(x: w * 0.72, y: h * 0.28)
            }
        }
    }

    private var openRouterIcon: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.22)
                .fill(Color(red: 0.08, green: 0.08, blue: 0.08)) // Dark Mode Black
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let strokeWidth = w * 0.085
                
                // Bauhaus OR logo in white
                
                // Left Circle (O)
                Circle()
                    .stroke(Color.white, lineWidth: strokeWidth)
                    .frame(width: w * 0.35, height: h * 0.35)
                    .position(x: w * 0.32, y: h * 0.5)

                // Right vertical bar of R
                Capsule()
                    .fill(Color.white)
                    .frame(width: strokeWidth, height: h * 0.42)
                    .position(x: w * 0.58, y: h * 0.5)

                // Right loop of R
                Path { path in
                    path.addArc(
                        center: CGPoint(x: w * 0.58, y: h * 0.39),
                        radius: w * 0.11,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(90),
                        clockwise: false
                    )
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))

                // Right diagonal leg of R
                Path { path in
                    path.move(to: CGPoint(x: w * 0.58, y: h * 0.5))
                    path.addLine(to: CGPoint(x: w * 0.71, y: h * 0.71))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round))
            }
        }
    }

    private var groqIcon: some View {
        ZStack {
            Circle()
                .fill(Color(red: 0.96, green: 0.31, blue: 0.21)) // Groq Orange
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Stylized lowercase g in white
                Circle()
                    .stroke(Color.white, lineWidth: w * 0.085)
                    .frame(width: w * 0.26, height: h * 0.26)
                    .position(x: w * 0.5, y: h * 0.42)

                Capsule()
                    .fill(Color.white)
                    .frame(width: w * 0.085, height: h * 0.32)
                    .position(x: w * 0.63, y: h * 0.48)

                Path { path in
                    path.addArc(
                        center: CGPoint(x: w * 0.5, y: h * 0.64),
                        radius: w * 0.13,
                        startAngle: .degrees(0),
                        endAngle: .degrees(180),
                        clockwise: false
                    )
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: w * 0.085, lineCap: .round))
            }
        }
    }

    private var openAICompatibleIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.62, green: 0.2, blue: 0.8), Color(red: 0.4, green: 0.1, blue: 0.65)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Faded OpenAI spiral in background
                ForEach(0..<6) { i in
                    OpenAISpiralShape()
                        .stroke(Color.white.opacity(0.35), style: StrokeStyle(lineWidth: w * 0.04, lineCap: .round))
                        .rotationEffect(.degrees(Double(i) * 60.0), anchor: .center)
                }
                
                // White plug/link symbol in center
                Path { path in
                    path.move(to: CGPoint(x: w * 0.3, y: h * 0.5))
                    path.addLine(to: CGPoint(x: w * 0.7, y: h * 0.5))
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: w * 0.09, lineCap: .round))
                
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.15, height: h * 0.15)
                    .position(x: w * 0.32, y: h * 0.5)

                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.15, height: h * 0.15)
                    .position(x: w * 0.68, y: h * 0.5)
            }
        }
    }

    private var anthropicCompatibleIcon: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.85, green: 0.45, blue: 0.2), Color(red: 0.65, green: 0.28, blue: 0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                // Faded Anthropic A in background
                AnthropicLogoShape()
                    .fill(Color.white.opacity(0.35))
                
                // White network hub dots/connection overlay
                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.14, height: h * 0.14)
                    .position(x: w * 0.5, y: h * 0.2)

                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.14, height: h * 0.14)
                    .position(x: w * 0.22, y: h * 0.7)

                Circle()
                    .fill(Color.white)
                    .frame(width: w * 0.14, height: h * 0.14)
                    .position(x: w * 0.78, y: h * 0.7)
                
                Path { path in
                    path.move(to: CGPoint(x: w * 0.5, y: h * 0.2))
                    path.addLine(to: CGPoint(x: w * 0.22, y: h * 0.7))
                    path.addLine(to: CGPoint(x: w * 0.78, y: h * 0.7))
                    path.closeSubpath()
                }
                .stroke(Color.white, style: StrokeStyle(lineWidth: w * 0.05, lineJoin: .round))
            }
        }
    }
}
