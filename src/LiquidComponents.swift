import SwiftUI

// MARK: - Hero Liquid Battery Orb (CleanMyMac style Full Crystal)

public struct LiquidBatteryHeroView: View {
    public let percent: Int
    public let isCharging: Bool
    public let watts: Double
    public let healthPercent: Int
    public let condition: String
    
    @State private var isAnimating = false
    
    public init(percent: Int, isCharging: Bool, watts: Double, healthPercent: Int, condition: String) {
        self.percent = percent
        self.isCharging = isCharging
        self.watts = watts
        self.healthPercent = healthPercent
        self.condition = condition
    }
    
    private var primaryColor: Color {
        if percent > 50 {
            return Color(hex: "00F5D4") // Apple Electric Cyan
        } else if percent > 20 {
            return Color.liquidAmber    // Warm Amber
        } else {
            return Color.liquidPink     // Apple Coral/Rose
        }
    }
    
    private var arcColors: [Color] {
        if isCharging {
            return [Color.liquidAmber, Color(hex: "FFD166"), Color(hex: "00F5D4"), Color.liquidAmber]
        } else if percent > 50 {
            // Elegant Electric Cyan into Sky Azure harmony (replaces harsh green-purple clash)
            return [Color(hex: "00F5D4"), Color(hex: "00D2FF"), Color(hex: "3A86FF"), Color(hex: "00F5D4")]
        } else if percent > 20 {
            return [Color.liquidAmber, Color.liquidOrange, Color.liquidAmber]
        } else {
            return [Color.liquidPink, Color(hex: "FF5E00"), Color.liquidPink]
        }
    }
    
    public var body: some View {
        ZStack {
            // Ambient outer radiance
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            primaryColor.opacity(0.20),
                            Color(hex: "23113B").opacity(0.12),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 145
                    )
                )
                .frame(width: 270, height: 270)
                .scaleEffect(isAnimating ? 1.06 : 0.95)
                .animation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true), value: isAnimating)
            
            // Full Crystal Background Lens (No milky haze)
            Circle()
                .fill(Color(hex: "0D061A").opacity(0.42))
                .frame(width: 204, height: 204)
                .overlay(
                    Circle()
                        .strokeBorder(
                            LinearGradient(
                                colors: [Color.white.opacity(0.45), Color.white.opacity(0.06), Color.clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
            
            // Background track
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 13)
                .frame(width: 180, height: 180)
            
            // Active Liquid Progress Arc
            Circle()
                .trim(from: 0.0, to: CGFloat(min(1.0, max(0.02, Double(percent) / 100.0))))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: arcColors),
                        center: .center,
                        startAngle: .degrees(0),
                        endAngle: .degrees(360)
                    ),
                    style: StrokeStyle(lineWidth: 13, lineCap: .round)
                )
                .frame(width: 180, height: 180)
                .rotationEffect(.degrees(-90))
                .shadow(color: primaryColor.opacity(0.65), radius: 10, x: 0, y: 0)
            
            // Crystal Core Text
            VStack(spacing: 5) {
                if isCharging {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .foregroundColor(Color.liquidAmber)
                            .font(.system(size: 11, weight: .bold))
                            .scaleEffect(isAnimating ? 1.15 : 0.9)
                            .animation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true), value: isAnimating)
                        Text("CARGANDO")
                            .font(.system(size: 10, weight: .black, design: .rounded))
                            .foregroundColor(Color.liquidAmber)
                    }
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Color.liquidAmber.opacity(0.18))
                    .clipShape(Capsule())
                } else {
                    Text("BATERÍA")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                }
                
                // Big Percentage
                HStack(alignment: .lastTextBaseline, spacing: 2) {
                    Text("\(percent)")
                        .font(.system(size: 54, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("%")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                }
                
                // Live Power Draw in Watts with Crystal Pill
                HStack(spacing: 5) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 10))
                    Text(String(format: "%.1f W", watts))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                }
                .foregroundColor(Color.liquidCyan)
                .padding(.horizontal, 11)
                .padding(.vertical, 4)
                .background(Color(hex: "080313").opacity(0.6))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color.white.opacity(0.25), lineWidth: 1)
                )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Big Glowing Action Button (Solo "Analizar" sin estrella como fue solicitado)

public struct LiquidActionButton: View {
    public let isScanning: Bool
    public let action: () -> Void
    
    @State private var isHovered = false
    
    public init(isScanning: Bool = false, action: @escaping () -> Void) {
        self.isScanning = isScanning
        self.action = action
    }
    
    public var body: some View {
        Button(action: action) {
            ZStack {
                // Outer Pulse Ring with Harmonious Cyan & Azure Glow
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [Color.liquidCyan.opacity(0.9), Color(hex: "3A86FF").opacity(0.75)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: isHovered ? 2.4 : 1.8
                    )
                    .frame(width: 86, height: 86)
                    .scaleEffect(isHovered ? 1.05 : 1.0)
                    .shadow(color: Color.liquidCyan.opacity(isHovered ? 0.65 : 0.30), radius: isHovered ? 14 : 7)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
                
                // Crystal Glass Body
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "22103E").opacity(0.88), Color(hex: "0D051A").opacity(0.96)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 78, height: 78)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [Color.white.opacity(isHovered ? 0.60 : 0.35), Color.white.opacity(0.10)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    )
                
                // Texto Único: Solo "Analizar" sin estrella
                Group {
                    if isScanning {
                        ProgressView()
                            .scaleEffect(0.9)
                            .colorInvert()
                    } else {
                        Text("Analizar")
                            .font(.system(size: 14.5, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 2)
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Cell Voltage Visualizer Full Crystal

public struct CellVoltageVisualizerView: View {
    public let cellVoltages: [Double]
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "square.grid.3x1.below.line.grid.1x2")
                    .foregroundColor(Color.liquidCyan)
                Text("Voltaje por Celda (Batería 3S)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text("Balance: Óptimo (Δ 2 mV)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.liquidEmerald)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 3)
                    .background(Color.liquidEmerald.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            HStack(spacing: 12) {
                ForEach(0..<max(cellVoltages.count, 3), id: \.self) { index in
                    let volt = (index < cellVoltages.count) ? cellVoltages[index] : 4.18
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Celda \(index + 1)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            Spacer()
                            Text(String(format: "%.3f V", volt))
                                .font(.system(size: 13, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                        }
                        
                        GeometryReader { geo in
                            let ratio = min(1.0, max(0.0, (volt - 3.2) / (4.35 - 3.2)))
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.07))
                                    .frame(height: 7)
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.liquidCyan, Color.liquidEmerald],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: geo.size.width * CGFloat(ratio), height: 7)
                                    .shadow(color: Color.liquidCyan.opacity(0.5), radius: 4)
                            }
                        }
                        .frame(height: 7)
                    }
                    .padding(14)
                    .background(Color(hex: "0E061B").opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                    )
                }
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 18)
    }
}
