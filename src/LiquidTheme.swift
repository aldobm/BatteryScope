import SwiftUI
import AppKit

// MARK: - Color Palette & Liquid Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    // CleanMyMac + Apple Liquid Glass Aesthetic - Harmonious Cosmic Palette
    public static let liquidDarkBg = Color(hex: "0D0718")
    public static let liquidViolet = Color(hex: "23113B")
    public static let liquidPurple = Color(hex: "56227E")
    public static let liquidPink = Color(hex: "FF3B80")
    public static let liquidCyan = Color(hex: "00F5D4")
    public static let liquidEmerald = Color(hex: "00E5C8") // Refined Apple Aqua-Teal (replaces harsh lime green)
    public static let liquidAmber = Color(hex: "FFB703")
    public static let liquidOrange = Color(hex: "FB8500")
    public static let liquidBlue = Color(hex: "3A86FF")
    
    public static let textPrimary = Color.white
    public static let textSecondary = Color(hex: "D5C8F2")
    public static let textMuted = Color(hex: "9585B5")
}

// MARK: - Full Crystal Liquid Glass Modifiers (Zero Milky/White Haze)

public struct LiquidGlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 20
    var glowColor: Color = Color.liquidPurple.opacity(0.25)
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // 1. Crystal Clear Translucent Tint (No milky material)
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(Color(hex: "0D061A").opacity(0.38))
                    
                    // 2. Liquid Specular Light Sheen
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.01),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 3. Crisp Liquid Glass Refractive Edge
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.40),
                                    Color.white.opacity(0.10),
                                    Color.clear,
                                    Color.white.opacity(0.16)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .shadow(color: Color.black.opacity(0.3), radius: 14, x: 0, y: 8)
            .shadow(color: glowColor, radius: 22, x: 0, y: 2)
    }
}

public struct LiquidPillModifier: ViewModifier {
    var isSelected: Bool = false
    
    public func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: "8B24C7").opacity(0.55), Color(hex: "D90088").opacity(0.42)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .strokeBorder(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.55), Color.white.opacity(0.18)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color(hex: "D90088").opacity(0.4), radius: 10, x: 0, y: 2)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .fill(Color.clear)
                    }
                }
            )
    }
}

extension View {
    public func liquidGlassCard(cornerRadius: CGFloat = 20, glowColor: Color = Color.liquidPurple.opacity(0.2)) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius, glowColor: glowColor))
    }
    
    public func liquidPill(isSelected: Bool) -> some View {
        self.modifier(LiquidPillModifier(isSelected: isSelected))
    }
}
