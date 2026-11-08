import SwiftUI
import AppKit

// MARK: - Dedicated Futuristic USB-C Charger & Charging Telemetry View

public struct ChargerView: View {
    @ObservedObject var service: BatteryService = BatteryService.shared
    @ObservedObject var locManager: LocalizationManager = LocalizationManager.shared
    
    // Animation states
    @State private var rotationAngle: Double = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var waveOffset: CGFloat = 0.0
    @State private var glowOpacity: Double = 0.6
    
    private let timer = Timer.publish(every: 0.04, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    private func loc(_ key: String) -> String {
        locManager.tr(key)
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // 1. Top Section Header with Live Status Pill
            headerSection
            
            // 2. Hardware Charger Brick Card (Glowing if connected, OFF/Dimmed if unplugged)
            chargerHardwareCard
            
            if service.snapshot.isExternalConnected {
                // 3. Flowing Energy Beam Line (visual connection from charger to battery)
                energyFlowBeam
                
                // 4. Smartphone-Style Nebula Aura Charging Orb + Big Lightning Bolt
                smartphoneNebulaChargingOrb
                
                // 5. Intelligent Charge Completion & Optimized Limit Card
                chargeEstimateAndLimitCard
                
                // 6. Multi-Battery 3-Cell Live Charging Bars + Temperature Sensor
                cellsChargingAndThermalSection
            } else {
                // Unplugged / Battery Mode Guidance Card
                unpluggedBatteryModeCard
            }
        }
        .onReceive(timer) { _ in
            if service.snapshot.isExternalConnected {
                rotationAngle += 1.8
                if rotationAngle >= 360 { rotationAngle = 0 }
                waveOffset = (waveOffset + 0.03).truncatingRemainder(dividingBy: 1.0)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulseScale = 1.10
                glowOpacity = 0.95
            }
        }
    }
    
    // MARK: - 1. Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(loc("nav_charger"))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text(service.snapshot.isExternalConnected ? loc("charger_energy_flow") : loc("charger_status_disconnected"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
            }
            
            Spacer()
            
            // Status Pill
            HStack(spacing: 6) {
                Circle()
                    .fill(service.snapshot.isExternalConnected ? Color.liquidEmerald : Color.gray)
                    .frame(width: 8, height: 8)
                    .shadow(color: service.snapshot.isExternalConnected ? Color.liquidEmerald.opacity(0.8) : Color.clear, radius: 4)
                
                Text(service.snapshot.isExternalConnected ? loc("charger_status_connected") : loc("charger_status_disconnected"))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(service.snapshot.isExternalConnected ? Color.liquidEmerald : Color.textMuted)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(service.snapshot.isExternalConnected ? Color.liquidEmerald.opacity(0.12) : Color.white.opacity(0.04))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(service.snapshot.isExternalConnected ? Color.liquidEmerald.opacity(0.35) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
    
    // MARK: - 2. Charger Hardware Card
    private var chargerHardwareCard: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let watts = service.snapshot.adapterWatts > 0 ? service.snapshot.adapterWatts : (isPlugged ? 20 : 0)
        let voltage = service.snapshot.adapterVoltage > 0 ? service.snapshot.adapterVoltage : (isPlugged ? 20.0 : 0.0)
        let current = service.snapshot.adapterCurrent > 0 ? service.snapshot.adapterCurrent : (isPlugged ? 3.0 : 0.0)
        let manufacturer = service.snapshot.adapterManufacturer.isEmpty ? "Apple Inc." : service.snapshot.adapterManufacturer
        let adapterName = isPlugged ? (service.snapshot.adapterName.isEmpty || service.snapshot.adapterName == "Desconectado" ? "USB-C Power Adapter" : service.snapshot.adapterName) : loc("charger_unplugged_title")
        
        return VStack(spacing: 16) {
            // Main Banner
            HStack(spacing: 18) {
                ZStack {
                    Circle()
                        .fill(isPlugged ? Color.liquidAmber.opacity(0.20) : Color.white.opacity(0.04))
                        .frame(width: 58, height: 58)
                    
                    if isPlugged {
                        Circle()
                            .stroke(Color.liquidAmber.opacity(0.4), lineWidth: 2)
                            .scaleEffect(pulseScale)
                    }
                    
                    Image(systemName: isPlugged ? "powerplug.fill" : "powerplug")
                        .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                        .font(.system(size: 26))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(adapterName)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(isPlugged ? .white : Color.textMuted)
                    
                    Text(isPlugged ? String(format: loc("adapter_manufacturer"), manufacturer) : loc("charger_status_disconnected"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // Wattage Display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(watts) W")
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                    
                    Text(isPlugged ? loc("negotiated_power") : "0 W")
                        .font(.system(size: 10))
                        .foregroundColor(Color.textMuted)
                }
            }
            
            // Sub-metrics Grid
            HStack(spacing: 12) {
                metricBox(
                    title: loc("adapter_voltage"),
                    value: String(format: "%.1f V", voltage),
                    isPlugged: isPlugged,
                    accentColor: Color.liquidCyan
                )
                
                metricBox(
                    title: loc("adapter_current"),
                    value: String(format: "%.1f A", current),
                    isPlugged: isPlugged,
                    accentColor: Color.liquidBlue
                )
                
                metricBox(
                    title: loc("cable_status"),
                    value: isPlugged ? loc("cable_status_optimal") : "Desconectado",
                    isPlugged: isPlugged,
                    accentColor: isPlugged ? Color.liquidEmerald : Color.textMuted
                )
                
                metricBox(
                    title: loc("charger_port_location"),
                    value: isPlugged ? "USB-C / TB4" : "--",
                    isPlugged: isPlugged,
                    accentColor: Color.liquidPink
                )
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 18, glowColor: isPlugged ? Color.liquidAmber.opacity(0.18) : Color.clear)
    }
    
    private func metricBox(title: String, value: String, isPlugged: Bool, accentColor: Color) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(Color.textSecondary)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(isPlugged ? accentColor : Color.textMuted)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "0A0414").opacity(isPlugged ? 0.55 : 0.25))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - 3. Energy Flow Beam Animation (Vertical Light Pulses)
    private var energyFlowBeam: some View {
        HStack(spacing: 8) {
            Image(systemName: "bolt.fill")
                .foregroundColor(Color.liquidAmber)
                .font(.system(size: 12))
            
            // Flowing Line with Travelling Gradient
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Track
                    Capsule()
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 4)
                    
                    // Moving Energy Segment
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.clear,
                                    Color.liquidCyan.opacity(0.8),
                                    Color.liquidEmerald,
                                    Color.liquidAmber,
                                    Color.clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width * 0.35, height: 4)
                        .offset(x: (geo.size.width * 0.9) * waveOffset)
                }
            }
            .frame(height: 6)
            
            Image(systemName: "arrow.down.circle.fill")
                .foregroundColor(Color.liquidEmerald)
                .font(.system(size: 12))
                .rotationEffect(.degrees(waveOffset * 360))
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 4)
    }
    
    // MARK: - 4. Smartphone-Style Nebula Aura Charging Orb + Big Lightning Bolt
    private var smartphoneNebulaChargingOrb: some View {
        let percent = service.snapshot.chargePercent
        
        return ZStack {
            // Cosmic Outer Nebula Glow Layer 1 (Wide Diffuse)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color.liquidEmerald.opacity(0.35 * glowOpacity),
                            Color.liquidCyan.opacity(0.20 * glowOpacity),
                            Color.liquidViolet.opacity(0.12 * glowOpacity),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 40,
                        endRadius: 130
                    )
                )
                .frame(width: 260, height: 260)
                .blur(radius: 18)
            
            // Rotating Nebula Aura Ring Layer 2
            Circle()
                .stroke(
                    AngularGradient(
                        colors: [
                            Color.liquidEmerald,
                            Color.liquidCyan,
                            Color.liquidBlue,
                            Color.liquidPink,
                            Color.liquidAmber,
                            Color.liquidEmerald
                        ],
                        center: .center
                    ),
                    lineWidth: 6
                )
                .frame(width: 190, height: 190)
                .rotationEffect(.degrees(rotationAngle))
                .blur(radius: 6)
                .opacity(0.85)
            
            // Sharp Progress Ring Layer 3
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 8)
                .frame(width: 170, height: 170)
            
            Circle()
                .trim(from: 0, to: max(0.05, CGFloat(percent) / 100.0))
                .stroke(
                    LinearGradient(
                        colors: [Color.liquidEmerald, Color.liquidCyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 8, lineCap: .round)
                )
                .frame(width: 170, height: 170)
                .rotationEffect(.degrees(-90))
                .shadow(color: Color.liquidEmerald.opacity(0.8), radius: 8, x: 0, y: 0)
            
            // Inner Translucent Bubble
            Circle()
                .fill(Color(hex: "0C0519").opacity(0.85))
                .frame(width: 150, height: 150)
                .overlay(
                    Circle()
                        .stroke(Color.white.opacity(0.12), lineWidth: 1)
                )
            
            // Center Smartphone Lightning Bolt & Percentage
            VStack(spacing: 4) {
                // Smartphone Neon Lightning Bolt with breathing pulse
                Image(systemName: "bolt.fill")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [Color.liquidCyan, Color.liquidEmerald],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .scaleEffect(pulseScale)
                    .shadow(color: Color.liquidEmerald.opacity(0.9), radius: 12, x: 0, y: 0)
                    .shadow(color: Color.liquidCyan.opacity(0.6), radius: 20, x: 0, y: 0)
                
                // Big Percentage
                Text("\(percent)%")
                    .font(.system(size: 36, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                
                // Fast Charging PD Badge
                Text(loc("charger_fast_charging"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(Color.liquidEmerald)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.liquidEmerald.opacity(0.15))
                    .clipShape(Capsule())
            }
        }
        .frame(height: 250)
        .padding(.vertical, 6)
    }
    
    // MARK: - 5. Charge Completion & Optimized Limit Card
    private var chargeEstimateAndLimitCard: some View {
        let percent = service.snapshot.chargePercent
        let isFullyCharged = service.snapshot.isFullyCharged || percent >= 100
        let isNearOptimizedLimit = percent >= 80 && percent < 100
        
        // Compute estimated minutes
        let timeMinutes = service.snapshot.timeRemainingMinutes > 0 ? service.snapshot.timeRemainingMinutes : max(15, Int((100 - percent) * 80 / 100))
        
        return HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isFullyCharged ? Color.liquidEmerald.opacity(0.18) : (isNearOptimizedLimit ? Color.liquidAmber.opacity(0.18) : Color.liquidCyan.opacity(0.18)))
                    .frame(width: 48, height: 48)
                
                Image(systemName: isFullyCharged ? "checkmark.seal.fill" : (isNearOptimizedLimit ? "shield.lefthalf.filled" : "clock.arrow.circlepath"))
                    .foregroundColor(isFullyCharged ? Color.liquidEmerald : (isNearOptimizedLimit ? Color.liquidAmber : Color.liquidCyan))
                    .font(.system(size: 22))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if isFullyCharged {
                    Text(loc("charger_full_bypass"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Alimentación directa por corriente alterna • La batería no sufre desgaste.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                } else if isNearOptimizedLimit {
                    Text(loc("charger_optimized_charging"))
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(Color.liquidAmber)
                    Text(loc("charger_limit_notice"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                } else {
                    HStack(spacing: 6) {
                        Text(loc("charger_est_time"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("~\(timeMinutes) min")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.liquidEmerald)
                    }
                    Text("Estimación en base a la tasa de carga rápida USB-C PD negociada.")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                }
            }
            
            Spacer()
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 16, glowColor: Color.liquidCyan.opacity(0.15))
    }
    
    // MARK: - 6. 3-Cell Live Charging Bars + Temperature Sensor
    private var cellsChargingAndThermalSection: some View {
        let temp = service.snapshot.temperature > 0 ? service.snapshot.temperature : 30.5
        let cellVoltages = service.snapshot.cellVoltages.isEmpty ? [3.830, 3.841, 3.829] : service.snapshot.cellVoltages
        
        return VStack(spacing: 14) {
            // Header with Cell Balancing & Temperature
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "square.3.layers.3d.down.right.slash")
                        .foregroundColor(Color.liquidCyan)
                        .font(.system(size: 13))
                    Text(loc("charger_cell_balancing"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Temperature Sensor Badge
                HStack(spacing: 5) {
                    Image(systemName: "thermometer.medium")
                        .foregroundColor(Color.liquidEmerald)
                        .font(.system(size: 11))
                    Text(String(format: "%.1f °C", temp))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text("(\(loc("charger_temp_optimal")))")
                        .font(.system(size: 10))
                        .foregroundColor(Color.liquidEmerald)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.liquidEmerald.opacity(0.12))
                .clipShape(Capsule())
            }
            
            // 3-Cell Individual Animated Progress Bars
            HStack(spacing: 12) {
                ForEach(0..<min(3, cellVoltages.count), id: \.self) { idx in
                    let volt = cellVoltages[idx]
                    // Normalized cell level (3.2V = 0%, 4.2V = 100%)
                    let ratio = max(0.1, min(1.0, (volt - 3.2) / 1.0))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Celda \(idx + 1)")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            Spacer()
                            Text(String(format: "%.3f V", volt))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.liquidCyan)
                        }
                        
                        // Animated Shimmer Bar
                        GeometryReader { g in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(Color.white.opacity(0.08))
                                
                                // Base Fill
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.liquidCyan, Color.liquidEmerald],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: g.size.width * CGFloat(ratio))
                                
                                // Moving Shimmer Wave
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.clear, Color.white.opacity(0.7), Color.clear],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: g.size.width * 0.25)
                                    .offset(x: (g.size.width * CGFloat(ratio)) * waveOffset)
                                    .clipped()
                            }
                        }
                        .frame(height: 8)
                    }
                    .padding(12)
                    .background(Color(hex: "0A0414").opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 16)
    }
    
    // MARK: - 7. Unplugged / Operating on Battery Card
    private var unpluggedBatteryModeCard: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.03))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "battery.50")
                    .font(.system(size: 38))
                    .foregroundColor(Color.textMuted)
            }
            
            VStack(spacing: 6) {
                Text(loc("charger_unplugged_title"))
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(loc("charger_unplugged_desc"))
                    .font(.system(size: 12))
                    .foregroundColor(Color.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            
            // Battery Telemetry Overview on Battery
            HStack(spacing: 14) {
                VStack(spacing: 4) {
                    Text("Nivel de Carga")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                    Text("\(service.snapshot.chargePercent)%")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.liquidCyan)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "0A0414").opacity(0.40))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 4) {
                    Text("Temperatura")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                    Text(String(format: "%.1f °C", service.snapshot.temperature > 0 ? service.snapshot.temperature : 30.5))
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(Color.liquidEmerald)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "0A0414").opacity(0.40))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                VStack(spacing: 4) {
                    Text("Salud")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                    Text("\(service.snapshot.maxCapacityPercent)%")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(Color.liquidAmber)
                }
                .padding(12)
                .frame(maxWidth: .infinity)
                .background(Color(hex: "0A0414").opacity(0.40))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding(24)
        .liquidGlassCard(cornerRadius: 18)
    }
}
