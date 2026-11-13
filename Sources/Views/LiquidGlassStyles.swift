import SwiftUI

// MARK: - Liquid Glass View Modifiers and Styles

public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 16
    var isGlowing: Bool = false
    var glowColor: Color = .cyan
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.10),
                                    Color.white.opacity(0.02)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isGlowing ? glowColor.opacity(0.8) : Color.white.opacity(0.35),
                                isGlowing ? glowColor.opacity(0.3) : Color.white.opacity(0.08)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isGlowing ? 1.5 : 1.0
                    )
            )
            .shadow(
                color: isGlowing ? glowColor.opacity(0.3) : Color.black.opacity(0.18),
                radius: isGlowing ? 16 : 10,
                x: 0,
                y: isGlowing ? 2 : 5
            )
    }
}

public struct LiquidGlassButtonStyle: ButtonStyle {
    var gradientColors: [Color] = [Color.cyan, Color.blue]
    var isPrimary: Bool = true
    
    public init(gradientColors: [Color] = [Color.cyan, Color.blue], isPrimary: Bool = true) {
        self.gradientColors = gradientColors
        self.isPrimary = isPrimary
    }
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isPrimary {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: gradientColors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .opacity(configuration.isPressed ? 0.75 : 0.9)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .opacity(configuration.isPressed ? 0.6 : 1.0)
                    }
                    
                    // Glossy Specular Overlay
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.35),
                                    Color.white.opacity(0.0)
                                ],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.6),
                                Color.white.opacity(0.15)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(
                color: isPrimary ? gradientColors.first?.opacity(0.3) ?? Color.clear : Color.black.opacity(0.15),
                radius: 8,
                x: 0,
                y: 3
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct LiquidGlassBackground: View {
    public init() {}
    
    public var body: some View {
        ZStack {
            // Dark macOS base
            Color(NSColor.windowBackgroundColor)
            
            // Ambient Colorful Liquid Orbs (Apple Vision Pro / macOS Sonoma style)
            Circle()
                .fill(Color.blue.opacity(0.18))
                .frame(width: 420, height: 420)
                .blur(radius: 80)
                .offset(x: -200, y: -160)
            
            Circle()
                .fill(Color.purple.opacity(0.16))
                .frame(width: 480, height: 480)
                .blur(radius: 90)
                .offset(x: 220, y: 140)
            
            Circle()
                .fill(Color.cyan.opacity(0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 70)
                .offset(x: 100, y: -180)
        }
        .ignoresSafeArea()
    }
}

extension View {
    public func liquidGlassCard(cornerRadius: CGFloat = 16, isGlowing: Bool = false, glowColor: Color = .cyan) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, isGlowing: isGlowing, glowColor: glowColor))
    }
}
