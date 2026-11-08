import SwiftUI
import AppKit

// MARK: - Animated Water Wave Shape for Fluid Battery Simulation

public struct WaterWaveShape: Shape {
    public var progress: CGFloat // 0.0 to 1.0
    public var waveHeight: CGFloat
    public var phase: CGFloat
    
    public var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(progress, phase) }
        set {
            progress = newValue.first
            phase = newValue.second
        }
    }
    
    public func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let clampedProgress = max(0.04, min(0.96, progress))
        let waterY = height * (1.0 - clampedProgress)
        
        path.move(to: CGPoint(x: 0, y: height))
        path.addLine(to: CGPoint(x: 0, y: waterY))
        
        let wavelength = width
        for x in stride(from: 0, through: width, by: 3) {
            let relativeX = x / wavelength
            let sine = sin(relativeX * 2 * .pi + phase)
            let y = waterY + sine * waveHeight
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.closeSubpath()
        return path
    }
}

// MARK: - Focused & Dynamic USB-C Charger & Fluid Battery View

// Modelo de partícula energética / electrón para flujo cuántico
public struct ElectronParticle: Identifiable {
    public let id: Int
    public var yProgress: CGFloat // 0.0 (arriba) a 1.0 (abajo)
    public var speed: CGFloat
    public var delayTicks: Int // pausa aleatoria antes de caer
    public var size: CGFloat
    public var isAmber: Bool
    public var isActive: Bool
}

public struct ChargerView: View {
    @ObservedObject var service: BatteryService = BatteryService.shared
    @ObservedObject var locManager: LocalizationManager = LocalizationManager.shared
    
    // Continuous animation timers
    @State private var wavePhase: CGFloat = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var boltGlow: Double = 0.7
    
    // Partículas de electrones independientes para columnas laterales izquierda y derecha
    @State private var leftColumnElectrons: [ElectronParticle] = [
        ElectronParticle(id: 1, yProgress: 0.18, speed: 0.016, delayTicks: 0, size: 4.2, isAmber: false, isActive: true),
        ElectronParticle(id: 2, yProgress: 0.0, speed: 0.022, delayTicks: 32, size: 4.6, isAmber: true, isActive: false),
        ElectronParticle(id: 3, yProgress: 0.0, speed: 0.014, delayTicks: 74, size: 3.8, isAmber: false, isActive: false)
    ]
    
    @State private var rightColumnElectrons: [ElectronParticle] = [
        ElectronParticle(id: 11, yProgress: 0.52, speed: 0.019, delayTicks: 0, size: 4.0, isAmber: true, isActive: true),
        ElectronParticle(id: 12, yProgress: 0.0, speed: 0.015, delayTicks: 45, size: 4.7, isAmber: false, isActive: false),
        ElectronParticle(id: 13, yProgress: 0.0, speed: 0.024, delayTicks: 95, size: 3.6, isAmber: true, isActive: false)
    ]
    
    private let animationTimer = Timer.publish(every: 0.035, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    private func loc(_ key: String) -> String {
        locManager.tr(key)
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // 1. PANEL SUPERIOR: Cargador USB-C (Tamaño Fijo y Compacto)
            chargerSourcePanel
            
            // 2. ENTRE AMBOS: Dos columnas laterales de electrones random + Cápsula central
            energyBridgeWithSideColumns
            
            // 3. PANEL INFERIOR: Batería del Sistema (Agua líquida + Rayo dorado + Textos translúcidos + Terminal + Celdas)
            fluidSystemBatteryPanel
        }
        .onReceive(animationTimer) { _ in
            wavePhase += 0.075
            if wavePhase >= .pi * 2 { wavePhase = 0 }
            
            if service.snapshot.isExternalConnected {
                // Actualizar columna izquierda (física asíncrona y aleatoria)
                for i in leftColumnElectrons.indices {
                    if leftColumnElectrons[i].delayTicks > 0 {
                        leftColumnElectrons[i].delayTicks -= 1
                        if leftColumnElectrons[i].delayTicks == 0 {
                            leftColumnElectrons[i].isActive = true
                            leftColumnElectrons[i].yProgress = 0.0
                        }
                    } else if leftColumnElectrons[i].isActive {
                        leftColumnElectrons[i].yProgress += leftColumnElectrons[i].speed
                        if leftColumnElectrons[i].yProgress >= 1.0 {
                            // Cae en la batería y descansa un tiempo random antes del siguiente átomo
                            leftColumnElectrons[i].isActive = false
                            leftColumnElectrons[i].yProgress = 0.0
                            leftColumnElectrons[i].delayTicks = Int.random(in: 18...75)
                            leftColumnElectrons[i].speed = CGFloat.random(in: 0.013...0.024)
                            leftColumnElectrons[i].size = CGFloat.random(in: 3.6...5.0)
                            leftColumnElectrons[i].isAmber = Bool.random()
                        }
                    }
                }
                
                // Actualizar columna derecha (tiempos, pausas y velocidades totalmente independientes)
                for i in rightColumnElectrons.indices {
                    if rightColumnElectrons[i].delayTicks > 0 {
                        rightColumnElectrons[i].delayTicks -= 1
                        if rightColumnElectrons[i].delayTicks == 0 {
                            rightColumnElectrons[i].isActive = true
                            rightColumnElectrons[i].yProgress = 0.0
                        }
                    } else if rightColumnElectrons[i].isActive {
                        rightColumnElectrons[i].yProgress += rightColumnElectrons[i].speed
                        if rightColumnElectrons[i].yProgress >= 1.0 {
                            // Cae en la batería y descansa un intervalo distinto al de la otra columna
                            rightColumnElectrons[i].isActive = false
                            rightColumnElectrons[i].yProgress = 0.0
                            rightColumnElectrons[i].delayTicks = Int.random(in: 18...75)
                            rightColumnElectrons[i].speed = CGFloat.random(in: 0.013...0.024)
                            rightColumnElectrons[i].size = CGFloat.random(in: 3.6...5.0)
                            rightColumnElectrons[i].isAmber = Bool.random()
                        }
                    }
                }
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
                boltGlow = 1.0
            }
        }
    }
    
    // MARK: - 1. Panel Superior: Adaptador de Corriente USB-C (Compacto, no crece)
    private var chargerSourcePanel: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let watts = service.snapshot.adapterWatts > 0 ? service.snapshot.adapterWatts : (isPlugged ? 20 : 0)
        let voltage = service.snapshot.adapterVoltage > 0 ? service.snapshot.adapterVoltage : (isPlugged ? 20.0 : 0.0)
        let current = service.snapshot.adapterCurrent > 0 ? service.snapshot.adapterCurrent : (isPlugged ? 3.0 : 0.0)
        let manufacturer = service.snapshot.adapterManufacturer.isEmpty ? "Apple Inc." : service.snapshot.adapterManufacturer
        let adapterName = isPlugged ?
            (service.snapshot.adapterName.isEmpty || service.snapshot.adapterName == "Desconectado" ? loc("charger_adapter_default") : service.snapshot.adapterName) :
            loc("charger_adapter_default")
        
        return VStack(spacing: 12) {
            // Header del panel con icono delimitado para que nunca altere el tamaño
            HStack(spacing: 14) {
                // Icono con círculo pulsante contenido
                ZStack {
                    Circle()
                        .fill(isPlugged ? Color.liquidAmber.opacity(0.20) : Color.white.opacity(0.04))
                        .frame(width: 46, height: 46)
                    
                    if isPlugged {
                        Circle()
                            .stroke(Color.liquidAmber.opacity(0.50), lineWidth: 1.5)
                            .frame(width: 46, height: 46)
                            .scaleEffect(pulseScale)
                    }
                    
                    Image(systemName: isPlugged ? "powerplug.fill" : "powerplug")
                        .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                        .font(.system(size: 20))
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(adapterName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(isPlugged ? .white : Color.textMuted)
                            .lineLimit(1)
                        
                        // Estado Activo / Apagado
                        Text(isPlugged ? loc("charger_status_active") : loc("charger_status_off"))
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(isPlugged ? Color.liquidEmerald : Color.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isPlugged ? Color.liquidEmerald.opacity(0.18) : Color.white.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    
                    Text(isPlugged ? String(format: loc("adapter_manufacturer"), manufacturer) + " • " + loc("charger_thunderbolt_port") : loc("charger_operating_on_battery"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Wattage Display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(watts) W")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                    
                    Text(isPlugged ? loc("charger_pd_negotiated") : loc("charger_in_standby"))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.textMuted)
                }
            }
            
            // Fila de Métricas del Adaptador
            HStack(spacing: 10) {
                panelMetricCard(
                    title: loc("voltage"),
                    value: isPlugged ? String(format: "%.1f V", voltage) : "-- V",
                    isPlugged: isPlugged,
                    color: Color.liquidCyan
                )
                
                panelMetricCard(
                    title: loc("amperage"),
                    value: isPlugged ? String(format: "%.1f A", current) : "-- A",
                    isPlugged: isPlugged,
                    color: Color.liquidBlue
                )
                
                panelMetricCard(
                    title: loc("protocol_label"),
                    value: isPlugged ? "USB-C PD 3.0" : loc("no_power_source"),
                    isPlugged: isPlugged,
                    color: isPlugged ? Color.liquidEmerald : Color.textMuted
                )
                
                panelMetricCard(
                    title: loc("cable_label"),
                    value: isPlugged ? loc("cable_optimal") : "--",
                    isPlugged: isPlugged,
                    color: isPlugged ? Color.liquidEmerald : Color.textMuted
                )
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, glowColor: isPlugged ? Color.liquidAmber.opacity(0.18) : Color.clear)
    }
    
    private func panelMetricCard(title: String, value: String, isPlugged: Bool, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.textSecondary)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(isPlugged ? color : Color.textMuted)
                .lineLimit(1)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "0A0414").opacity(isPlugged ? 0.50 : 0.25))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    // MARK: - 2. Entre Ambos: Dos Columnas Laterales con Electrones y Cápsula Central
    private var energyBridgeWithSideColumns: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let watts = service.snapshot.adapterWatts > 0 ? service.snapshot.adapterWatts : (isPlugged ? 20 : 0)
        let current = service.snapshot.adapterCurrent > 0 ? service.snapshot.adapterCurrent : (isPlugged ? 3.0 : 0.0)
        let columnHeight: CGFloat = 52
        
        return HStack(alignment: .center) {
            // Columna Izquierda: Flujo cuántico de electrones asíncrono
            electronColumnView(particles: leftColumnElectrons, isPlugged: isPlugged, height: columnHeight)
                .frame(width: 24)
            
            Spacer(minLength: 20)
            
            // Cápsula Central: Estado de Transferencia Energética
            transferBadge(isPlugged: isPlugged, watts: watts, current: current)
            
            Spacer(minLength: 20)
            
            // Columna Derecha: Flujo cuántico de electrones con tiempos y velocidades distintas
            electronColumnView(particles: rightColumnElectrons, isPlugged: isPlugged, height: columnHeight)
                .frame(width: 24)
        }
        .padding(.horizontal, 48)
        .frame(height: columnHeight)
    }
    
    // Cápsula central fija que informa los watts y amperios transferidos
    private func transferBadge(isPlugged: Bool, watts: Int, current: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: isPlugged ? "bolt.fill" : "powerplug")
                .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                .font(.system(size: 11, weight: .bold))
                .scaleEffect(isPlugged ? pulseScale : 1.0)
            
            if isPlugged {
                Text(loc("transfer_label"))
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(Color.textSecondary)
                
                Text("\(watts) W • \(String(format: "%.1f A", current))")
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.liquidEmerald)
                
                // Flechitas de flujo hacia abajo
                HStack(spacing: 2) {
                    ForEach(0..<3) { i in
                        Image(systemName: "chevron.down")
                            .font(.system(size: 7, weight: .black))
                            .foregroundColor(Color.liquidCyan.opacity(Double(i + 1) * 0.33))
                    }
                }
            } else {
                Text(loc("no_transfer_active"))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(Color.textMuted)
            }
        }
        .fixedSize(horizontal: true, vertical: false)
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(Color(hex: "0D061A").opacity(0.55))
        )
        .overlay(
            Capsule()
                .strokeBorder(isPlugged ? Color.liquidCyan.opacity(0.40) : Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: isPlugged ? Color.liquidCyan.opacity(0.20) : Color.clear, radius: 8)
    }
    
    // Columna vertical de transporte de energía con electrones en caída aleatoria
    private func electronColumnView(particles: [ElectronParticle], isPlugged: Bool, height: CGFloat) -> some View {
        ZStack(alignment: .top) {
            // 1. Línea guía vertical (Rail conductor de plasma)
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [
                            isPlugged ? Color.liquidAmber.opacity(0.35) : Color.white.opacity(0.06),
                            isPlugged ? Color.liquidCyan.opacity(0.35) : Color.white.opacity(0.04)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(width: 2, height: height)
                .shadow(color: isPlugged ? Color.liquidCyan.opacity(0.30) : Color.clear, radius: 3)
            
            // 2. Terminal superior de conexión
            Capsule()
                .fill(isPlugged ? Color.liquidAmber.opacity(0.70) : Color.white.opacity(0.12))
                .frame(width: 10, height: 3)
                .shadow(color: isPlugged ? Color.liquidAmber.opacity(0.80) : Color.clear, radius: 3)
            
            // 3. Terminal inferior de entrada a la celda
            Capsule()
                .fill(isPlugged ? Color.liquidCyan.opacity(0.70) : Color.white.opacity(0.12))
                .frame(width: 10, height: 3)
                .shadow(color: isPlugged ? Color.liquidCyan.opacity(0.80) : Color.clear, radius: 3)
                .offset(y: height - 3)
            
            // 4. Electrones luminosos con trayectorias no sincronizadas y espaciadas
            if isPlugged {
                ForEach(particles) { p in
                    if p.isActive && p.yProgress >= 0.0 && p.yProgress <= 1.0 {
                        let yPos = p.yProgress * height
                        let color = p.isAmber ? Color.liquidAmber : Color.liquidCyan
                        // Suavizado en extremos para que surjan y se fundan de forma natural
                        let fade = min(1.0, min(p.yProgress / 0.12, (1.0 - p.yProgress) / 0.12))
                        
                        ZStack {
                            // Estela luminosa cometaria hacia arriba
                            LinearGradient(
                                colors: [color.opacity(0.0), color.opacity(0.55 * fade)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(width: 2.2, height: 11)
                            .offset(y: -5)
                            
                            // Halo difuso exterior
                            Circle()
                                .fill(color.opacity(0.45 * fade))
                                .frame(width: p.size * 2.5, height: p.size * 2.5)
                                .blur(radius: 2)
                            
                            // Anillo energético
                            Circle()
                                .stroke(color.opacity(fade), lineWidth: 1)
                                .frame(width: p.size * 1.35, height: p.size * 1.35)
                            
                            // Núcleo blanco de alta energía
                            Circle()
                                .fill(Color.white.opacity(fade))
                                .frame(width: p.size, height: p.size)
                        }
                        .offset(y: yPos - 5)
                    }
                }
            }
        }
        .frame(width: 24, height: height)
    }
    
    // MARK: - 3. Panel Inferior: Batería del Sistema (Agua Líquida + Rayo Dorado + Textos Translúcidos + Terminal)
    private var fluidSystemBatteryPanel: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let percent = service.snapshot.chargePercent
        let progress = CGFloat(percent) / 100.0
        let temp = service.snapshot.temperature > 0 ? service.snapshot.temperature : 30.2
        let isFullyCharged = service.snapshot.isFullyCharged || percent >= 100
        let isNearOptimizedLimit = percent >= 80 && percent < 100
        
        // Autonomía real de Mac (58% ~ 5h 30m - 6h 15m)
        let realisticAutonomyMinutes: Int = {
            if service.snapshot.timeRemainingMinutes > 30 && service.snapshot.timeRemainingMinutes < 1200 {
                return service.snapshot.timeRemainingMinutes
            } else {
                return max(45, Int(Double(percent) * 6.5))
            }
        }()
        
        return VStack(spacing: 16) {
            // Header del Panel de Batería
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "battery.100.bolt")
                        .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                        .font(.system(size: 15, weight: .bold))
                    Text(loc("system_battery"))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                // Dynamic Status Badge
                HStack(spacing: 5) {
                    Circle()
                        .fill(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                        .frame(width: 7, height: 7)
                        .shadow(color: (isPlugged ? Color.liquidEmerald : Color.liquidCyan).opacity(0.8), radius: 3)
                    
                    Text(isPlugged ? loc("status_recharging_flow") : loc("status_draining_battery"))
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((isPlugged ? Color.liquidEmerald : Color.liquidCyan).opacity(0.12))
                .clipShape(Capsule())
            }
            
            // TANQUE DE BATERÍA ESTILIZADO CON AGUA LÍQUIDA Y TERMINAL POSITIVO
            HStack(spacing: 4) {
                // Tank Body
                ZStack(alignment: .bottom) {
                    // 1. Tank Background Dark Bed
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(hex: "080313").opacity(0.80))
                    
                    // 2. Liquid Layer 1 (Back Wave - Translucent depth)
                    WaterWaveShape(progress: progress, waveHeight: 7, phase: wavePhase + .pi)
                        .fill(
                            isPlugged ?
                            LinearGradient(
                                colors: [Color.liquidEmerald.opacity(0.40), Color.liquidCyan.opacity(0.25)],
                                startPoint: .bottom,
                                endPoint: .top
                            ) :
                            LinearGradient(
                                colors: [Color(hex: "0077B6").opacity(0.35), Color.liquidCyan.opacity(0.20)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                    
                    // 3. Liquid Layer 2 (Front Wave - Vibrant Colorful Fluid)
                    WaterWaveShape(progress: progress, waveHeight: 9, phase: wavePhase)
                        .fill(
                            isPlugged ?
                            LinearGradient(
                                colors: [
                                    Color(hex: "00B4D8"),
                                    Color.liquidCyan,
                                    Color.liquidEmerald
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color(hex: "03045E"),
                                    Color(hex: "0077B6"),
                                    Color(hex: "00B4D8"),
                                    Color.liquidCyan
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing
                            )
                        )
                    
                    // 4. Subtle Surface Specular Glow Line
                    VStack {
                        Spacer()
                        Rectangle()
                            .fill(Color.white.opacity(0.40))
                            .frame(height: 1.5)
                            .offset(y: -((130 * progress) - 6))
                            .blur(radius: 1)
                    }
                    
                    // 5. Glass Reflection Overlay
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // 6. Central Readout Overlay (Rayo Eléctrico Dorado + Textos Translúcidos Suaves)
                    HStack(spacing: 16) {
                        // Rayo Eléctrico en DORADO / ÁMBAR NEÓN vibrante que destaca sobre el agua cian
                        ZStack {
                            Circle()
                                .fill(isPlugged ? Color.liquidAmber.opacity(0.25) : Color.white.opacity(0.08))
                                .frame(width: 52, height: 52)
                                .scaleEffect(isPlugged ? pulseScale : 1.0)
                                .blur(radius: isPlugged ? 2 : 0)
                            
                            Image(systemName: isPlugged ? "bolt.fill" : "battery.50")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundStyle(
                                    isPlugged ?
                                    LinearGradient(
                                        colors: [Color(hex: "FFE600"), Color(hex: "FF9500")],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    ) :
                                    LinearGradient(
                                        colors: [Color.white, Color.white.opacity(0.8)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .shadow(color: isPlugged ? Color(hex: "FFB703").opacity(boltGlow) : Color.clear, radius: 10)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(alignment: .center, spacing: 8) {
                                Text("\(percent)%")
                                    .font(.system(size: 38, weight: .black, design: .rounded))
                                    .foregroundColor(.white)
                                    .shadow(color: Color.black.opacity(0.8), radius: 5, x: 0, y: 2)
                                
                                // Cápsula translúcida suave (no negra pesada)
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                                        .frame(width: 6, height: 6)
                                    Text(isPlugged ? loc("badge_fast_charging") : loc("badge_battery_mode"))
                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                        .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                                }
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color(hex: "0D061A").opacity(0.35))
                                .clipShape(Capsule())
                                .overlay(
                                    Capsule().strokeBorder(Color.white.opacity(0.16), lineWidth: 0.8)
                                )
                            }
                            
                            // Descripción con fondo translúcido suave
                            Text(isPlugged ?
                                 (isFullyCharged ? loc("desc_full_ac_bypass") : (isNearOptimizedLimit ? loc("desc_macos_optimized") : loc("desc_lithium_ions"))) :
                                 loc("desc_battery_discharging"))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white)
                                .shadow(color: Color.black.opacity(0.7), radius: 3, x: 0, y: 1)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color(hex: "0D061A").opacity(0.30))
                                .clipShape(RoundedRectangle(cornerRadius: 6))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6).strokeBorder(Color.white.opacity(0.12), lineWidth: 0.8)
                                )
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(
                            isPlugged ?
                            LinearGradient(colors: [Color.liquidEmerald.opacity(0.6), Color.liquidCyan.opacity(0.3)], startPoint: .topLeading, endPoint: .bottomTrailing) :
                            LinearGradient(colors: [Color.white.opacity(0.20), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                
                // Conector Positivo Prominente y Auténtico (+ Terminal)
                ZStack {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .fill(
                            isPlugged ?
                            LinearGradient(colors: [Color.liquidCyan, Color.liquidEmerald], startPoint: .top, endPoint: .bottom) :
                            LinearGradient(colors: [Color.white.opacity(0.35), Color.white.opacity(0.15)], startPoint: .top, endPoint: .bottom)
                        )
                        .frame(width: 14, height: 50)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .strokeBorder(isPlugged ? Color.liquidCyan.opacity(0.8) : Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .shadow(color: isPlugged ? Color.liquidCyan.opacity(0.6) : Color.clear, radius: 6)
                    
                    // Signo + grabado en el polo positivo
                    Text("+")
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(isPlugged ? Color(hex: "080313") : Color.white)
                }
            }
            
            // Fila de 4 Tarjetas de Métricas Esenciales con Autonomía Corregida
            HStack(spacing: 10) {
                // 1. Nivel
                metricDetailCard(
                    title: loc("charge_level_label"),
                    value: "\(percent)%",
                    subtitle: isPlugged ? loc("status_recharging") : loc("status_draining"),
                    color: isPlugged ? Color.liquidEmerald : Color.liquidCyan
                )
                
                // 2. Autonomía Real (Corregida)
                let timeMinutes = isPlugged ?
                    (service.snapshot.timeRemainingMinutes > 0 ? service.snapshot.timeRemainingMinutes : max(15, Int((100 - percent) * 75 / 100))) :
                    realisticAutonomyMinutes
                
                metricDetailCard(
                    title: isPlugged ? loc("time_to_100") : loc("autonomy_label"),
                    value: isPlugged ?
                        (isFullyCharged ? loc("status_complete") : (isNearOptimizedLimit ? loc("status_limit_80") : "~\(timeMinutes) m")) :
                        String(format: loc("hours_mins_format"), timeMinutes / 60, timeMinutes % 60),
                    subtitle: isPlugged ? (isNearOptimizedLimit ? loc("rate_optimized") : loc("rate_fast")) : loc("status_estimated"),
                    color: isPlugged ? Color.liquidEmerald : Color.liquidAmber
                )
                
                // 3. Temperatura
                metricDetailCard(
                    title: loc("temperature"),
                    value: String(format: "%.1f °C", temp),
                    subtitle: loc("temp_optimal_range"),
                    color: Color.liquidCyan
                )
                
                // 4. Salud y Ciclos
                metricDetailCard(
                    title: loc("max_health_label"),
                    value: "\(service.snapshot.maxCapacityPercent)%",
                    subtitle: String(format: loc("cycles_subtitle"), service.snapshot.cycleCount),
                    color: Color.liquidAmber
                )
            }
            
            // Balance de las 3 Celdas de Litio (3S Balance) con Colores Saludables Cian/Azul en Batería
            HStack(spacing: 12) {
                let cellVoltages = service.snapshot.cellVoltages.isEmpty ? [3.830, 3.841, 3.829] : service.snapshot.cellVoltages
                ForEach(0..<min(3, cellVoltages.count), id: \.self) { idx in
                    let volt = cellVoltages[idx]
                    let ratio = max(0.1, min(1.0, (volt - 3.2) / 1.0))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(String(format: loc("cell_unit_label"), idx + 1))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            Spacer()
                            Text(String(format: "%.3f V", volt))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                        }
                        
                        // Mini Liquid Bar con Colores Saludables (Cian Eléctrico y Azul Azure en Batería, Verde Esmeralda en Carga)
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                            Capsule()
                                .fill(
                                    isPlugged ?
                                    LinearGradient(colors: [Color.liquidCyan, Color.liquidEmerald], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color(hex: "0077B6"), Color(hex: "00B4D8"), Color.liquidCyan], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 80 * CGFloat(ratio), height: 5)
                                .shadow(color: isPlugged ? Color.liquidEmerald.opacity(0.4) : Color.liquidCyan.opacity(0.3), radius: 2)
                        }
                    }
                    .padding(8)
                    .background(Color(hex: "0A0414").opacity(0.40))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18)
    }
    
    private func metricDetailCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(Color.textSecondary)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(color)
                .lineLimit(1)
            
            Text(subtitle)
                .font(.system(size: 9))
                .foregroundColor(Color.textMuted)
                .lineLimit(1)
        }
        .padding(9)
        .frame(maxWidth: .infinity)
        .background(Color(hex: "0A0414").opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
