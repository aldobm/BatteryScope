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
        let clampedProgress = max(0.02, min(0.98, progress))
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

public struct ChargerView: View {
    @ObservedObject var service: BatteryService = BatteryService.shared
    @ObservedObject var locManager: LocalizationManager = LocalizationManager.shared
    
    // Continuous animation timer
    @State private var wavePhase: CGFloat = 0.0
    @State private var beamOffset: CGFloat = 0.0
    @State private var pulseScale: CGFloat = 1.0
    @State private var boltGlow: Double = 0.7
    
    private let animationTimer = Timer.publish(every: 0.035, on: .main, in: .common).autoconnect()
    
    public init() {}
    
    private func loc(_ key: String) -> String {
        locManager.tr(key)
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            // 1. PANEL SUPERIOR: Cargador USB-C (Se enciende si está conectado)
            chargerSourcePanel
            
            // 2. ENTRE AMBOS: Línea animada de Transferencia Energética con Potencia y Amperaje
            energyTransferBridge
            
            // 3. PANEL INFERIOR: Batería del Sistema (Agua líquida ondulante + Métricas enfocadas)
            fluidSystemBatteryPanel
        }
        .onReceive(animationTimer) { _ in
            wavePhase += 0.08
            if wavePhase >= .pi * 2 { wavePhase = 0 }
            
            if service.snapshot.isExternalConnected {
                beamOffset = (beamOffset + 0.025).truncatingRemainder(dividingBy: 1.0)
            }
        }
        .onAppear {
            withAnimation(Animation.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                pulseScale = 1.08
                boltGlow = 1.0
            }
        }
    }
    
    // MARK: - 1. Panel Superior: Adaptador de Corriente USB-C
    private var chargerSourcePanel: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let watts = service.snapshot.adapterWatts > 0 ? service.snapshot.adapterWatts : (isPlugged ? 20 : 0)
        let voltage = service.snapshot.adapterVoltage > 0 ? service.snapshot.adapterVoltage : (isPlugged ? 20.0 : 0.0)
        let current = service.snapshot.adapterCurrent > 0 ? service.snapshot.adapterCurrent : (isPlugged ? 3.0 : 0.0)
        let manufacturer = service.snapshot.adapterManufacturer.isEmpty ? "Apple Inc." : service.snapshot.adapterManufacturer
        let adapterName = isPlugged ?
            (service.snapshot.adapterName.isEmpty || service.snapshot.adapterName == "Desconectado" ? "USB-C Power Adapter" : service.snapshot.adapterName) :
            "Adaptador de Corriente USB-C"
        
        return VStack(spacing: 14) {
            // Header del panel
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(isPlugged ? Color.liquidAmber.opacity(0.22) : Color.white.opacity(0.04))
                        .frame(width: 50, height: 50)
                    
                    if isPlugged {
                        Circle()
                            .stroke(Color.liquidAmber.opacity(0.45), lineWidth: 1.5)
                            .scaleEffect(pulseScale)
                    }
                    
                    Image(systemName: isPlugged ? "powerplug.fill" : "powerplug")
                        .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                        .font(.system(size: 22))
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(adapterName)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(isPlugged ? .white : Color.textMuted)
                        
                        // Estado Activo / Apagado
                        Text(isPlugged ? "ACTIVO" : "APAGADO")
                            .font(.system(size: 9, weight: .black, design: .rounded))
                            .foregroundColor(isPlugged ? Color.liquidEmerald : Color.textMuted)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(isPlugged ? Color.liquidEmerald.opacity(0.18) : Color.white.opacity(0.05))
                            .clipShape(Capsule())
                    }
                    
                    Text(isPlugged ? String(format: loc("adapter_manufacturer"), manufacturer) + " • Puerto Thunderbolt" : "Sin cargador conectado • Operando con batería")
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // Wattage Display
                VStack(alignment: .trailing, spacing: 2) {
                    Text("\(watts) W")
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(isPlugged ? Color.liquidAmber : Color.textMuted)
                    
                    Text(isPlugged ? "PD Negociado" : "En Reposo")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.textMuted)
                }
            }
            
            // Fila de Métricas del Adaptador
            HStack(spacing: 10) {
                panelMetricCard(
                    title: "Voltaje",
                    value: isPlugged ? String(format: "%.1f V", voltage) : "-- V",
                    isPlugged: isPlugged,
                    color: Color.liquidCyan
                )
                
                panelMetricCard(
                    title: "Amperaje",
                    value: isPlugged ? String(format: "%.1f A", current) : "-- A",
                    isPlugged: isPlugged,
                    color: Color.liquidBlue
                )
                
                panelMetricCard(
                    title: "Protocolo",
                    value: isPlugged ? "USB-C PD 3.0" : "Sin Fuente",
                    isPlugged: isPlugged,
                    color: isPlugged ? Color.liquidEmerald : Color.textMuted
                )
                
                panelMetricCard(
                    title: "Cable",
                    value: isPlugged ? "Óptimo" : "--",
                    isPlugged: isPlugged,
                    color: isPlugged ? Color.liquidEmerald : Color.textMuted
                )
            }
        }
        .padding(16)
        .liquidGlassCard(cornerRadius: 18, glowColor: isPlugged ? Color.liquidAmber.opacity(0.20) : Color.clear)
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
    
    // MARK: - 2. Entre Ambos: Línea de Transferencia de Energía
    private var energyTransferBridge: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let watts = service.snapshot.adapterWatts > 0 ? service.snapshot.adapterWatts : (isPlugged ? 20 : 0)
        let current = service.snapshot.adapterCurrent > 0 ? service.snapshot.adapterCurrent : (isPlugged ? 3.0 : 0.0)
        
        return HStack(spacing: 12) {
            // Left Connector
            HStack(spacing: 3) {
                Circle().fill(isPlugged ? Color.liquidAmber : Color.white.opacity(0.1)).frame(width: 5, height: 5)
                Rectangle().fill(isPlugged ? Color.liquidAmber.opacity(0.6) : Color.white.opacity(0.06)).frame(height: 2)
            }
            
            // Central Dynamic Pill with Voltage/Current/Wattage transfer
            HStack(spacing: 8) {
                Image(systemName: isPlugged ? "bolt.fill" : "powerplug")
                    .foregroundColor(isPlugged ? Color.liquidCyan : Color.textMuted)
                    .font(.system(size: 11, weight: .bold))
                    .scaleEffect(isPlugged ? pulseScale : 1.0)
                
                if isPlugged {
                    Text("Transferencia:")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                    
                    Text("\(watts) W • \(String(format: "%.1f A", current))")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(Color.liquidEmerald)
                    
                    // Animated Flow Arrows
                    HStack(spacing: 2) {
                        ForEach(0..<3) { i in
                            Image(systemName: "chevron.down")
                                .font(.system(size: 8, weight: .black))
                                .foregroundColor(Color.liquidCyan.opacity(Double(i + 1) * 0.33))
                        }
                    }
                } else {
                    Text("Sin transferencia eléctrica activa")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.textMuted)
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(Color(hex: "0C0519").opacity(0.85))
            )
            .overlay(
                Capsule()
                    .strokeBorder(isPlugged ? Color.liquidCyan.opacity(0.40) : Color.white.opacity(0.08), lineWidth: 1)
            )
            .shadow(color: isPlugged ? Color.liquidCyan.opacity(0.3) : Color.clear, radius: 8)
            
            // Right Connector
            HStack(spacing: 3) {
                Rectangle().fill(isPlugged ? Color.liquidCyan.opacity(0.6) : Color.white.opacity(0.06)).frame(height: 2)
                Circle().fill(isPlugged ? Color.liquidCyan : Color.white.opacity(0.1)).frame(width: 5, height: 5)
            }
        }
        .padding(.horizontal, 10)
    }
    
    // MARK: - 3. Panel Inferior: Batería del Sistema (Agua Líquida Ondulante)
    private var fluidSystemBatteryPanel: some View {
        let isPlugged = service.snapshot.isExternalConnected
        let percent = service.snapshot.chargePercent
        let progress = CGFloat(percent) / 100.0
        let temp = service.snapshot.temperature > 0 ? service.snapshot.temperature : 30.2
        let isFullyCharged = service.snapshot.isFullyCharged || percent >= 100
        let isNearOptimizedLimit = percent >= 80 && percent < 100
        
        return VStack(spacing: 16) {
            // Header del Panel de Batería
            HStack {
                HStack(spacing: 7) {
                    Image(systemName: "battery.100.bolt")
                        .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                        .font(.system(size: 15, weight: .bold))
                    Text("Batería del Sistema")
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
                    
                    Text(isPlugged ? "RECARGANDO (FLUJO ACTIVO)" : "DRENANDO (EN BATERÍA)")
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background((isPlugged ? Color.liquidEmerald : Color.liquidCyan).opacity(0.12))
                .clipShape(Capsule())
            }
            
            // TANQUE DE BATERÍA ESTILIZADO CON AGUA LÍQUIDA ONDULANTE
            ZStack(alignment: .trailing) {
                // Main Battery Crystal Tank Body
                HStack(spacing: 0) {
                    ZStack(alignment: .bottom) {
                        // 1. Tank Background Dark Bed
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(hex: "080313").opacity(0.75))
                        
                        // 2. Liquid Layer 1 (Back Wave - Translucent)
                        WaterWaveShape(progress: progress, waveHeight: 7, phase: wavePhase + .pi)
                            .fill(
                                isPlugged ?
                                LinearGradient(
                                    colors: [Color.liquidEmerald.opacity(0.40), Color.liquidCyan.opacity(0.25)],
                                    startPoint: .bottom,
                                    endPoint: .top
                                ) :
                                LinearGradient(
                                    colors: [Color.liquidPurple.opacity(0.45), Color.liquidBlue.opacity(0.30)],
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
                                        Color(hex: "560BAD"),
                                        Color(hex: "7209B7"),
                                        Color.liquidPink,
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
                                .fill(Color.white.opacity(0.35))
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
                        
                        // 6. Central Interactive Readout Overlay
                        HStack(spacing: 16) {
                            // Glowing Big Lightning Bolt (Smartphone Style)
                            ZStack {
                                Circle()
                                    .fill(isPlugged ? Color.liquidEmerald.opacity(0.25) : Color.white.opacity(0.08))
                                    .frame(width: 58, height: 58)
                                    .scaleEffect(isPlugged ? pulseScale : 1.0)
                                    .blur(radius: isPlugged ? 4 : 0)
                                
                                Image(systemName: isPlugged ? "bolt.fill" : "battery.50")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(isPlugged ? Color.liquidEmerald : Color.white)
                                    .shadow(color: isPlugged ? Color.liquidEmerald.opacity(boltGlow) : Color.clear, radius: 12)
                            }
                            
                            VStack(alignment: .leading, spacing: 3) {
                                HStack(alignment: .firstTextBaseline, spacing: 6) {
                                    Text("\(percent)%")
                                        .font(.system(size: 38, weight: .black, design: .rounded))
                                        .foregroundColor(.white)
                                        .shadow(color: Color.black.opacity(0.4), radius: 6)
                                    
                                    Text(isPlugged ? "Carga en progreso" : "Nivel de Batería")
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(Color.textSecondary)
                                }
                                
                                Text(isPlugged ?
                                     (isFullyCharged ? "Completado • Modo Bypass CA" : (isNearOptimizedLimit ? "Carga optimizada de macOS activa (Límite 80%/95%)" : "Iones de litio fluyendo hacia las 3 celdas")) :
                                     "Consumo activo del sistema • Nivel líquido descendiendo gradualmente")
                                    .font(.system(size: 11))
                                    .foregroundColor(isPlugged ? (isNearOptimizedLimit ? Color.liquidAmber : Color.textSecondary) : Color.textMuted)
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 14)
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
                    
                    // Battery Positive Terminal Nub
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isPlugged ? Color.liquidCyan.opacity(0.6) : Color.white.opacity(0.15))
                        .frame(width: 6, height: 38)
                        .offset(x: 2)
                }
            }
            
            // Fila de 4 Tarjetas de Métricas Esenciales
            HStack(spacing: 10) {
                // 1. Nivel
                metricDetailCard(
                    title: "Nivel de Carga",
                    value: "\(percent)%",
                    subtitle: isPlugged ? "Recargando" : "Drenando",
                    color: isPlugged ? Color.liquidEmerald : Color.liquidCyan
                )
                
                // 2. Tiempo Estimado / Límite
                let timeMinutes = service.snapshot.timeRemainingMinutes > 0 ? service.snapshot.timeRemainingMinutes : max(15, Int((100 - percent) * 75 / 100))
                metricDetailCard(
                    title: isPlugged ? "Tiempo al 100%" : "Autonomía",
                    value: isPlugged ?
                        (isFullyCharged ? "Completo" : (isNearOptimizedLimit ? "Límite 80%" : "~\(timeMinutes) m")) :
                        String(format: "%dh %02dm", timeMinutes / 60, timeMinutes % 60),
                    subtitle: isPlugged ? (isNearOptimizedLimit ? "Optimizado" : "Tasa Rápida") : "Estimado",
                    color: isPlugged ? Color.liquidEmerald : Color.liquidAmber
                )
                
                // 3. Temperatura
                metricDetailCard(
                    title: "Temperatura",
                    value: String(format: "%.1f °C", temp),
                    subtitle: "Rango Óptimo",
                    color: Color.liquidCyan
                )
                
                // 4. Salud y Ciclos
                metricDetailCard(
                    title: "Salud Máxima",
                    value: "\(service.snapshot.maxCapacityPercent)%",
                    subtitle: "\(service.snapshot.cycleCount) ciclos",
                    color: Color.liquidAmber
                )
            }
            
            // Balance de las 3 Celdas de Litio (3S Balance)
            HStack(spacing: 12) {
                let cellVoltages = service.snapshot.cellVoltages.isEmpty ? [3.830, 3.841, 3.829] : service.snapshot.cellVoltages
                ForEach(0..<min(3, cellVoltages.count), id: \.self) { idx in
                    let volt = cellVoltages[idx]
                    let ratio = max(0.1, min(1.0, (volt - 3.2) / 1.0))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Celda \(idx + 1)")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(Color.textSecondary)
                            Spacer()
                            Text(String(format: "%.3f V", volt))
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(isPlugged ? Color.liquidEmerald : Color.liquidCyan)
                        }
                        
                        // Mini Liquid Bar
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.white.opacity(0.08)).frame(height: 5)
                            Capsule()
                                .fill(
                                    isPlugged ?
                                    LinearGradient(colors: [Color.liquidCyan, Color.liquidEmerald], startPoint: .leading, endPoint: .trailing) :
                                    LinearGradient(colors: [Color.liquidPink, Color.liquidCyan], startPoint: .leading, endPoint: .trailing)
                                )
                                .frame(width: 80 * CGFloat(ratio), height: 5)
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
