import SwiftUI
import AppKit

// MARK: - Advanced Interactive Timeline Graph (Overall Battery)

public struct TimelineChartView: View {
    @ObservedObject var service = BatteryService.shared
    @State private var hoveredPoint: HourlyHistoryPoint? = nil
    
    private var points: [HourlyHistoryPoint] {
        if service.historyPoints.isEmpty {
            return [
                HourlyHistoryPoint(timestamp: Date().addingTimeInterval(-7200), batteryPercent: 94, isCharging: false, topAppName: "Firefox", topAppPower: 26.0, notes: "Descargando"),
                HourlyHistoryPoint(timestamp: Date().addingTimeInterval(-3600), batteryPercent: 88, isCharging: false, topAppName: "Google Drive", topAppPower: 18.0, notes: "Sincronización"),
                HourlyHistoryPoint(timestamp: Date(), batteryPercent: 90, isCharging: true, topAppName: "Cargador USB-C", topAppPower: 0, notes: "Carga en progreso")
            ]
        }
        return service.historyPoints
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Línea de Tiempo del Consumo")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Nivel de batería y actividades registradas por hora")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
                
                HStack(spacing: 12) {
                    HStack(spacing: 6) {
                        Circle().fill(Color.liquidCyan).frame(width: 8, height: 8)
                        Text("Batería").font(.system(size: 11)).foregroundColor(Color.textSecondary)
                    }
                    HStack(spacing: 6) {
                        Circle().fill(Color.liquidAmber).frame(width: 8, height: 8)
                        Text("Cargando").font(.system(size: 11)).foregroundColor(Color.textSecondary)
                    }
                }
            }
            
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height - 24
                
                ZStack(alignment: .topLeading) {
                    VStack {
                        ForEach([100, 75, 50, 25], id: \.self) { pct in
                            HStack {
                                Text("\(pct)%")
                                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                                    .foregroundColor(Color.textMuted)
                                    .frame(width: 30, alignment: .trailing)
                                Rectangle().fill(Color.white.opacity(0.06)).frame(height: 1)
                            }
                            if pct > 25 { Spacer() }
                        }
                    }
                    .frame(height: h)
                    
                    if points.count >= 2 {
                        let stepX = (w - 40) / CGFloat(max(points.count - 1, 1))
                        
                        Path { path in
                            for (i, pt) in points.enumerated() {
                                let x = 40 + CGFloat(i) * stepX
                                let y = h - (CGFloat(pt.batteryPercent) / 100.0 * h)
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                            path.addLine(to: CGPoint(x: 40 + CGFloat(points.count - 1) * stepX, y: h))
                            path.addLine(to: CGPoint(x: 40, y: h))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [Color.liquidCyan.opacity(0.25), Color.liquidPurple.opacity(0.02), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        
                        Path { path in
                            for (i, pt) in points.enumerated() {
                                let x = 40 + CGFloat(i) * stepX
                                let y = h - (CGFloat(pt.batteryPercent) / 100.0 * h)
                                if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                                else { path.addLine(to: CGPoint(x: x, y: y)) }
                            }
                        }
                        .stroke(
                            LinearGradient(
                                colors: [Color.liquidCyan, Color.liquidEmerald, Color.liquidAmber],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                        )
                        .shadow(color: Color.liquidCyan.opacity(0.4), radius: 6)
                        
                        ForEach(Array(points.enumerated()), id: \.offset) { (i, pt) in
                            let x = 40 + CGFloat(i) * stepX
                            let y = h - (CGFloat(pt.batteryPercent) / 100.0 * h)
                            Circle()
                                .fill(pt.isCharging ? Color.liquidAmber : Color.liquidCyan)
                                .frame(width: 7, height: 7)
                                .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                                .position(x: x, y: y)
                        }
                        
                        if let selected = hoveredPoint {
                            let idx = points.firstIndex(where: { $0.id == selected.id }) ?? 0
                            let x = 40 + CGFloat(idx) * stepX
                            let y = h - (CGFloat(selected.batteryPercent) / 100.0 * h)
                            
                            Rectangle().fill(Color.white.opacity(0.5)).frame(width: 1, height: h).position(x: x, y: h / 2)
                            Circle().fill(Color.liquidPink).frame(width: 10, height: 10).overlay(Circle().stroke(Color.white, lineWidth: 1.5)).position(x: x, y: y)
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            let locX = val.location.x
                            let stepX = (w - 40) / CGFloat(max(points.count - 1, 1))
                            let rawIdx = Int(round((locX - 40) / stepX))
                            let validIdx = max(0, min(points.count - 1, rawIdx))
                            hoveredPoint = points[validIdx]
                        }
                )
            }
            .frame(height: 180)
            
            if let target = hoveredPoint ?? points.last {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Hora Registrada")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.textMuted)
                        Text(target.timestamp.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Divider().frame(height: 24).background(Color.white.opacity(0.12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Carga")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.textMuted)
                        HStack(spacing: 4) {
                            Text("\(target.batteryPercent)%")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundColor(Color.liquidCyan)
                            Image(systemName: target.isCharging ? "bolt.fill" : "battery.75")
                                .foregroundColor(target.isCharging ? Color.liquidAmber : Color.liquidCyan)
                                .font(.system(size: 11))
                        }
                    }
                    Divider().frame(height: 24).background(Color.white.opacity(0.12))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Estado del Mac")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.textMuted)
                        Text(target.topAppName)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
                .padding(12)
                .background(Color(hex: "0C0518").opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
            }
        }
        .padding(18)
        .liquidGlassCard(cornerRadius: 18)
    }
}

// MARK: - App Energy Row View

public struct AppEnergyRowView: View {
    public let app: AppEnergyUsage
    public let maxPower: Double
    public let onSelect: () -> Void
    public let onTerminate: (Int32) -> Void
    
    @State private var isHovered = false
    
    private var powerColor: Color {
        if app.instantWatts > 3.0 || app.powerScore > 30.0 {
            return Color.liquidPink
        } else if app.instantWatts > 1.2 || app.powerScore > 10.0 {
            return Color.liquidAmber
        } else {
            return Color.liquidEmerald
        }
    }
    
    public var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                Group {
                    if let nsImage = app.icon {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 36, height: 36)
                    } else {
                        ZStack {
                            RoundedRectangle(cornerRadius: 9)
                                .fill(Color.white.opacity(0.08))
                                .frame(width: 36, height: 36)
                            Image(systemName: "cpu")
                                .foregroundColor(Color.textSecondary)
                                .font(.system(size: 18))
                        }
                    }
                }
                .shadow(color: Color.black.opacity(0.25), radius: 4)
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(app.appName)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        Text("PID \(app.pid)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color.textMuted)
                        
                        if BatteryService.shared.isProcessPaused(pid: app.pid) {
                            Text("PAUSADO")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundColor(Color.liquidAmber)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.liquidAmber.opacity(0.18))
                                .clipShape(Capsule())
                        } else if app.powerScore > 25.0 {
                            Text("ALTO DRENAJE")
                                .font(.system(size: 9, weight: .black, design: .rounded))
                                .foregroundColor(Color.liquidPink)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1.5)
                                .background(Color.liquidPink.opacity(0.18))
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(app.explanation.description)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary.opacity(0.85))
                        .lineLimit(1)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 3) {
                    HStack(spacing: 4) {
                        Text(String(format: "%.2f W", app.instantWatts))
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(powerColor)
                        Text("(\(Int(app.milliWatts)) mW)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(Color.textMuted)
                    }
                    
                    HStack(spacing: 4) {
                        Text(String(format: "%.1f mWh", app.accumulatedMWh))
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(Color.liquidCyan)
                        Text("consumidos")
                            .font(.system(size: 9))
                            .foregroundColor(Color.textMuted)
                    }
                }
                .frame(width: 140, alignment: .trailing)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isHovered ? Color.liquidCyan : Color.textMuted.opacity(0.6))
                    .padding(.leading, 4)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                ZStack {
                    if isHovered {
                        Color(hex: "1F0F38").opacity(0.55)
                    } else {
                        Color(hex: "0B0516").opacity(0.35)
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(isHovered ? Color.white.opacity(0.3) : Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Process Detail Window (100% OPAQUE)

public struct ProcessDetailModalView: View {
    public let app: AppEnergyUsage
    public let onClose: () -> Void
    public let onTerminate: (Int32) -> Void
    
    @ObservedObject var service = BatteryService.shared
    @ObservedObject var locMgr = LocalizationManager.shared
    @State private var hoveredTimePoint: ProcessTimePoint? = nil
    
    private var history: [ProcessTimePoint] {
        app.historyPoints
    }
    
    public var body: some View {
        VStack(spacing: 16) {
            headerBar
            explanationBox
            metricsCards
            timelineChart
            actionButtons
        }
        .padding(22)
        .background(Color(hex: "140828"))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [Color.liquidPink, Color.liquidCyan, Color.liquidPurple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.8
                )
        )
        .shadow(color: Color.black.opacity(0.85), radius: 35, x: 0, y: 15)
        .shadow(color: Color.liquidPink.opacity(0.35), radius: 25, x: 0, y: 5)
    }
    
    private var headerBar: some View {
        HStack(spacing: 14) {
            if let img = app.icon {
                Image(nsImage: img)
                    .resizable()
                    .frame(width: 44, height: 44)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "341555"))
                        .frame(width: 44, height: 44)
                    Image(systemName: "cpu.fill")
                        .foregroundColor(Color.liquidCyan)
                        .font(.system(size: 22))
                }
            }
            
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 8) {
                    Text(app.appName)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(app.explanation.category)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundColor(Color.liquidCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2.5)
                        .background(Color.liquidCyan.opacity(0.2))
                        .clipShape(Capsule())
                }
                
                Text(String(format: loc("executable_process"), app.processName, app.pid))
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(Color.textMuted)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundColor(Color(hex: "BFA9E0"))
            }
            .buttonStyle(.plain)
        }
        .padding(.bottom, 2)
    }
    
    private var explanationBox: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "info.circle.fill")
                    .foregroundColor(Color.liquidPink)
                    .font(.system(size: 14))
                Text(loc("process_function"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            Text(app.explanation.description)
                .font(.system(size: 12))
                .foregroundColor(Color(hex: "E6DCF5"))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            
            Divider().background(Color.white.opacity(0.1))
            
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.liquidAmber)
                        Text(loc("why_active"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.liquidAmber)
                    }
                    Text(app.explanation.whyActive)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                        .lineSpacing(2.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
                
                Rectangle()
                    .fill(Color.white.opacity(0.12))
                    .frame(width: 1)
                
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.liquidEmerald)
                        Text(loc("what_to_do"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(Color.liquidEmerald)
                    }
                    Text(app.explanation.whatToDo)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                        .lineSpacing(2.5)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1F0F38"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
    }
    
    private var metricsCards: some View {
        HStack(spacing: 10) {
            metricCard(title: loc("instant_power"), value: String(format: "%.2f W", app.instantWatts), subtitle: String(format: loc("live_mW"), Int(app.milliWatts)), color: Color.liquidPink)
            metricCard(title: loc("energy_consumed"), value: String(format: "%.1f mWh", app.accumulatedMWh), subtitle: String(format: "%.2f kJ", app.accumulatedJoules / 1000.0), color: Color.liquidCyan)
            metricCard(title: loc("battery_share"), value: String(format: "%.1f%%", app.percentOfTotalPower), subtitle: loc("total_drain"), color: Color.liquidAmber)
            metricCard(title: loc("cpu_load"), value: String(format: "%.1f%%", app.cpuPercent), subtitle: loc("chip_threads"), color: Color.liquidEmerald)
        }
        .frame(maxWidth: .infinity)
    }
    
    private func metricCard(title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color.textMuted)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 19, weight: .heavy, design: .rounded))
                .monospacedDigit()
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(subtitle)
                .font(.system(size: 10))
                .monospacedDigit()
                .foregroundColor(Color(hex: "C4B5E0"))
                .lineLimit(1)
        }
        .padding(12)
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
        .frame(height: 78)
        .background(Color(hex: "1F0F38"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
    
    private var timelineChart: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(loc("temporal_chart_title"))
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Text(loc("unit_watts"))
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(Color.liquidCyan)
            }
            
            GeometryReader { geo in
                let w: CGFloat = geo.size.width
                let h: CGFloat = geo.size.height - 20
                let maxWatts: Double = max(1.0, (history.map { $0.watts }.max() ?? 2.0) * 1.25)
                
                ZStack(alignment: .topLeading) {
                    chartGrid(h: h, maxWatts: maxWatts)
                    
                    if history.count >= 2 {
                        let stepX: CGFloat = (w - 40.0) / CGFloat(history.count - 1)
                        chartPath(h: h, stepX: stepX, maxWatts: maxWatts)
                        chartPoints(h: h, stepX: stepX, maxWatts: maxWatts)
                        
                        if let hover = hoveredTimePoint,
                           let idx = history.firstIndex(where: { $0.id == hover.id }) {
                            hoverIndicator(h: h, x: 40.0 + CGFloat(idx) * stepX, y: h - (CGFloat(hover.watts / maxWatts) * h))
                        }
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { val in
                            if history.count >= 2 {
                                let stepX: CGFloat = (w - 40.0) / CGFloat(history.count - 1)
                                let idx = Int(round((val.location.x - 40.0) / stepX))
                                let valid = max(0, min(history.count - 1, idx))
                                hoveredTimePoint = history[valid]
                            }
                        }
                )
            }
            .frame(height: 120)
            
            if let pt = hoveredTimePoint ?? history.last {
                HStack(spacing: 12) {
                    Text(pt.timestamp.formatted(date: .omitted, time: .standard))
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    Text(String(format: "%@: %.2f W (%.0f mW)", loc("instant_power"), pt.watts, pt.milliWatts))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.liquidPink)
                    Spacer()
                    Text(String(format: loc("accumulated"), String(format: "%.1f mWh", pt.accumulatedMWh)))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color.liquidCyan)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.4))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(14)
        .background(Color(hex: "1F0F38"))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
    }
    
    private func chartGrid(h: CGFloat, maxWatts: Double) -> some View {
        VStack {
            ForEach([maxWatts, maxWatts * 0.66, maxWatts * 0.33], id: \.self) { val in
                HStack {
                    Text(String(format: "%.1fW", val))
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(Color.textMuted)
                        .frame(width: 32, alignment: .trailing)
                    Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1)
                }
                Spacer()
            }
        }
        .frame(height: h)
    }
    
    private func chartPath(h: CGFloat, stepX: CGFloat, maxWatts: Double) -> some View {
        ZStack {
            Path { path in
                for (i, pt) in history.enumerated() {
                    let x: CGFloat = 40.0 + CGFloat(i) * stepX
                    let y: CGFloat = h - (CGFloat(pt.watts / maxWatts) * h)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
                path.addLine(to: CGPoint(x: 40.0 + CGFloat(history.count - 1) * stepX, y: h))
                path.addLine(to: CGPoint(x: 40.0, y: h))
                path.closeSubpath()
            }
            .fill(LinearGradient(colors: [Color.liquidPink.opacity(0.4), Color.clear], startPoint: .top, endPoint: .bottom))
            
            Path { path in
                for (i, pt) in history.enumerated() {
                    let x: CGFloat = 40.0 + CGFloat(i) * stepX
                    let y: CGFloat = h - (CGFloat(pt.watts / maxWatts) * h)
                    if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                    else { path.addLine(to: CGPoint(x: x, y: y)) }
                }
            }
            .stroke(
                LinearGradient(colors: [Color.liquidPink, Color.liquidCyan], startPoint: .leading, endPoint: .trailing),
                style: StrokeStyle(lineWidth: 2.4, lineCap: .round)
            )
        }
    }
    
    private func chartPoints(h: CGFloat, stepX: CGFloat, maxWatts: Double) -> some View {
        ForEach(Array(history.enumerated()), id: \.offset) { item in
            let x: CGFloat = 40.0 + CGFloat(item.offset) * stepX
            let y: CGFloat = h - (CGFloat(item.element.watts / maxWatts) * h)
            Circle()
                .fill(Color.liquidPink)
                .frame(width: 6, height: 6)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.2))
                .position(x: x, y: y)
        }
    }
    
    private func hoverIndicator(h: CGFloat, x: CGFloat, y: CGFloat) -> some View {
        ZStack {
            Rectangle()
                .fill(Color.white.opacity(0.6))
                .frame(width: 1, height: h)
                .position(x: x, y: h / 2)
            Circle()
                .fill(Color.liquidCyan)
                .frame(width: 10, height: 10)
                .overlay(Circle().stroke(Color.white, lineWidth: 1.5))
                .position(x: x, y: y)
        }
    }
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if app.explanation.canPause {
                let isPaused = service.isProcessPaused(pid: app.pid)
                Button(action: {
                    service.togglePause(app: app)
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: isPaused ? "play.fill" : "pause.fill")
                        Text(isPaused ? loc("resume") : loc("pause_process"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(isPaused ? Color.liquidEmerald : Color.liquidAmber)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            if app.explanation.safeToStop {
                Button(action: {
                    onTerminate(app.pid)
                    onClose()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.octagon.fill")
                        Text(loc("terminate_process"))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.liquidPink)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            Spacer()
            
            Button(action: onClose) {
                Text(loc("back"))
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 8)
                    .background(Color(hex: "3A1660"))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.white.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }
}

// MARK: - Subcomponente de Columna Arquitectónica

struct BlockBarColumnView: View {
    let block: TodayHalfHourBlock
    let isSelected: Bool
    let barWidth: CGFloat
    let availableHeight: CGFloat
    let maxDrain: Double
    let onHoverShare: (AppBlockShare) -> Void
    let onSelect: () -> Void
    
    var body: some View {
        let badgeHeight: CGFloat = 20.0
        let chartAreaHeight = max(40.0, availableHeight - 22.0)
        // Hard-cap the bar so it and the badge NEVER exceed chartAreaHeight
        let maxBarHeight = max(20.0, chartAreaHeight - badgeHeight - 6.0)
        
        // El tamaño de la barra es estrictamente proporcional al nivel real de batería (0% - 100%)
        // De esta forma dos barras de 48% tienen exactamente el mismo tamaño, y 67% es mayor que 65%.
        let level = max(1.0, min(100.0, Double(block.batteryLevel)))
        let barHeightRatio = CGFloat(level / 100.0)
        let minBarHeight: CGFloat = 8.0
        let totalHeight: CGFloat = minBarHeight + (maxBarHeight - minBarHeight) * barHeightRatio
        
        VStack(spacing: 5) {
            ZStack(alignment: .bottom) {
                // Background column slot (perfectly aligned with all columns)
                RoundedRectangle(cornerRadius: 3, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .frame(width: barWidth, height: chartAreaHeight)
                
                // Architectural colored app segments
                VStack(spacing: 0) {
                    ForEach(block.topApps) { appShare in
                        let segHeight = max(1.0, totalHeight * CGFloat(appShare.percentage / 100.0))
                        Rectangle()
                            .fill(Color(hex: appShare.colorHex))
                            .frame(width: barWidth, height: segHeight)
                            .onHover { h in
                                if h { onHoverShare(appShare) }
                            }
                    }
                }
                .frame(width: barWidth, height: totalHeight, alignment: .bottom)
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .strokeBorder(isSelected ? Color.white : (block.isSleeping ? Color.white.opacity(0.1) : Color.white.opacity(0.2)), lineWidth: isSelected ? 2 : 0.6)
                )
                .shadow(color: isSelected ? Color.liquidCyan.opacity(0.85) : Color.clear, radius: 8)
                
                // TOP ENERGY LABEL: Muestra el nivel exacto de batería en ese tiempo (ej. 50%, 40%, 39%)
                HStack(spacing: 3) {
                    if block.hasMoon {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(Color(hex: "CBD5E0"))
                    } else if block.hasBolt {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color.liquidAmber)
                    } else {
                        Image(systemName: "battery.75")
                            .font(.system(size: 8.5, weight: .bold))
                            .foregroundColor(Color.liquidCyan)
                    }
                    
                    Text(block.numberText)
                        .font(.system(size: 10.5, weight: .bold, design: .rounded))
                        .foregroundColor(
                            block.isCharging ? Color.liquidAmber :
                            (block.isSleeping ? Color(hex: "CBD5E0") :
                            (isSelected ? Color.liquidCyan : Color.white))
                        )
                        .lineLimit(1)
                }
                .padding(.horizontal, 4.5)
                .padding(.vertical, 2.5)
                .background(Color.black.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 0.5)
                )
                .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                .padding(.bottom, totalHeight + 3)
            }
            .frame(height: availableHeight, alignment: .bottom)
            
            Text(block.shortHour)
                .font(.system(size: 9.5, weight: isSelected ? .bold : .medium, design: .monospaced))
                .foregroundColor(isSelected ? Color.liquidCyan : (block.isSleeping ? Color.textMuted.opacity(0.6) : Color.textSecondary))
                .frame(width: barWidth)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onSelect()
        }
    }
}

// MARK: - Subcomponente de Slider Horizontal Exclusivo y Visible

struct IntervalHorizontalSliderBar: View {
    let totalCount: Int
    let totalContentWidth: CGFloat
    let containerWidth: CGFloat
    let startHour: String
    let endHour: String
    @Binding var sliderFraction: Double
    let onTargetChanged: (Int) -> Void
    
    private func computeIndex(from fraction: Double) -> Int {
        guard totalCount > 1 else { return 0 }
        let total = Double(totalCount - 1)
        let calc = Int(round(fraction * total))
        return max(0, min(totalCount - 1, calc))
    }
    
    var body: some View {
        HStack(spacing: 10) {
            // Botón retroceder (-20% o varias franjas)
            Button(action: {
                let newFrac = max(0.0, sliderFraction - 0.20)
                sliderFraction = newFrac
                onTargetChanged(computeIndex(from: newFrac))
            }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(sliderFraction > 0.02 ? Color.liquidCyan : Color.white.opacity(0.25))
                    .frame(width: 24, height: 20)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            
            // Interactive Slider Track (Siempre visible y con thumb brillante)
            GeometryReader { geo in
                let trackWidth = geo.size.width
                let visibleRatio = max(0.15, min(1.0, Double(containerWidth / max(1.0, totalContentWidth))))
                let thumbWidth = max(38.0, trackWidth * CGFloat(visibleRatio))
                let maxTravel = max(1.0, trackWidth - thumbWidth)
                let thumbOffset = maxTravel * CGFloat(sliderFraction)
                
                ZStack(alignment: .leading) {
                    // Pista base horizontal permanente
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 7)
                    
                    // Relleno iluminado
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.liquidCyan.opacity(0.4), Color.liquidPink.opacity(0.4)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(8.0, thumbOffset + thumbWidth / 2), height: 7)
                    
                    // Deslizador / Thumb táctil visible
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.liquidCyan, Color(hex: "00B4D8")],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(width: thumbWidth, height: 11)
                        .overlay(
                            RoundedRectangle(cornerRadius: 4)
                                .strokeBorder(Color.white.opacity(0.85), lineWidth: 0.8)
                        )
                        .shadow(color: Color.liquidCyan.opacity(0.7), radius: 5)
                        .offset(x: thumbOffset)
                        .gesture(
                            DragGesture(minimumDistance: 1)
                                .onChanged { val in
                                    let newOffset = max(0.0, min(maxTravel, thumbOffset + val.translation.width))
                                    let frac = Double(newOffset / maxTravel)
                                    sliderFraction = frac
                                    onTargetChanged(computeIndex(from: frac))
                                }
                        )
                }
                .frame(height: 14)
                .contentShape(Rectangle())
                .onTapGesture { loc in
                    let frac = max(0.0, min(1.0, Double(loc.x / trackWidth)))
                    sliderFraction = frac
                    onTargetChanged(computeIndex(from: frac))
                }
            }
            .frame(height: 14)
            
            // Botón avanzar (+20% o varias franjas)
            Button(action: {
                let newFrac = min(1.0, sliderFraction + 0.20)
                sliderFraction = newFrac
                onTargetChanged(computeIndex(from: newFrac))
            }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(sliderFraction < 0.98 ? Color.liquidCyan : Color.white.opacity(0.25))
                    .frame(width: 24, height: 20)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 5))
            }
            .buttonStyle(.plain)
            
            // Indicador de franja horaria inicial y final
            HStack(spacing: 3) {
                Text(startHour)
                Text("→")
                Text(endHour)
            }
            .font(.system(size: 9, weight: .bold, design: .monospaced))
            .foregroundColor(Color.textMuted)
        }
        .padding(.horizontal, 10)
        .padding(.top, 2)
    }
}

// MARK: - UPDATED: Consumo Histórico con Calendario y Selector de Intervalo (30m, 1h, Todo el Día)

public struct TodayBlocksView: View {
    @ObservedObject var service = BatteryService.shared
    @ObservedObject private var locManager = LocalizationManager.shared
    @State private var selectedBlockId: String? = nil
    @State private var hoveredShare: AppBlockShare? = nil
    @State private var sliderFraction: Double = 1.0
    
    private var blocks: [TodayHalfHourBlock] {
        service.todayHalfHourBlocks
    }
    
    private var activeBlock: TodayHalfHourBlock? {
        if let id = selectedBlockId, let b = blocks.first(where: { $0.id == id }) {
            return b
        }
        return blocks.last
    }
    
    private var dayFormatter: DateFormatter {
        let f = DateFormatter()
        f.locale = Locale(identifier: locManager.currentLanguage.rawValue)
        f.dateStyle = .medium
        return f
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Calendar, Pause/Resume & Interval Selector
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc("interval_history_title"))
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(loc("interval_history_subtitle"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                // BOTÓN PAUSAR / REANUDAR
                Button(action: {
                    withAnimation(.spring(response: 0.22)) {
                        service.isIntervalAnalysisPaused.toggle()
                        if !service.isIntervalAnalysisPaused {
                            service.computeIntervalBlocks(currentApps: service.topApps, date: service.selectedDate, mode: service.intervalMode)
                        }
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: service.isIntervalAnalysisPaused ? "play.fill" : "pause.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(service.isIntervalAnalysisPaused ? loc("resume_analysis") : loc("pause_live"))
                            .font(.system(size: 11.5, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(service.isIntervalAnalysisPaused ? Color.liquidAmber : Color.liquidCyan)
                    .padding(.horizontal, 11)
                    .padding(.vertical, 6)
                    .background(
                        service.isIntervalAnalysisPaused ?
                        Color.liquidAmber.opacity(0.22) :
                        Color.liquidCyan.opacity(0.12)
                    )
                    .clipShape(Capsule())
                    .overlay(
                        Capsule().strokeBorder(
                            service.isIntervalAnalysisPaused ? Color.liquidAmber.opacity(0.7) : Color.liquidCyan.opacity(0.35),
                            lineWidth: 1
                        )
                    )
                    .shadow(color: service.isIntervalAnalysisPaused ? Color.liquidAmber.opacity(0.3) : Color.clear, radius: 4)
                }
                .buttonStyle(.plain)
                .help(service.isIntervalAnalysisPaused ? loc("resume_live_help") : loc("pause_live_help"))
                
                // Interval Switcher (30 Min, 1 Hora, Todo el Día)
                HStack(spacing: 4) {
                    ForEach(ConsumptionIntervalMode.allCases) { mode in
                        Button(action: {
                            service.changeIntervalMode(mode)
                        }) {
                            Text(mode.localizedName)
                                .font(.system(size: 11, weight: service.intervalMode == mode ? .bold : .medium, design: .rounded))
                                .foregroundColor(service.intervalMode == mode ? .white : Color.textSecondary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    service.intervalMode == mode ?
                                    Color.liquidPink.opacity(0.8) : Color.white.opacity(0.06)
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(3)
                .background(Color(hex: "080313").opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            
            // Calendar / Date Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "calendar")
                        .foregroundColor(Color.liquidCyan)
                        .font(.system(size: 12))
                    Text(loc("day_analyzed"))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(Color.textSecondary)
                    
                    Menu {
                        ForEach(service.availableDates, id: \.self) { d in
                            Button(action: {
                                service.changeSelectedDate(d)
                            }) {
                                HStack {
                                    Text(Calendar.current.isDateInToday(d) ? "\(loc("today_label")) (\(dayFormatter.string(from: d)))" : dayFormatter.string(from: d))
                                    if Calendar.current.isDate(d, inSameDayAs: service.selectedDate) {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 5) {
                            Text(Calendar.current.isDateInToday(service.selectedDate) ? "\(loc("today_label")) (\(dayFormatter.string(from: service.selectedDate)))" : dayFormatter.string(from: service.selectedDate))
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9))
                                .foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                // Color Legends
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.liquidPink).frame(width: 8, height: 8)
                        Text("fileproviderd").font(.system(size: 10)).foregroundColor(Color.textSecondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(Color.liquidCyan).frame(width: 8, height: 8)
                        Text("WindowServer").font(.system(size: 10)).foregroundColor(Color.textSecondary)
                    }
                    HStack(spacing: 4) {
                        Rectangle().fill(Color(hex: "4A5568")).frame(width: 8, height: 8)
                        Text(loc("lid_closed")).font(.system(size: 10)).foregroundColor(Color.textSecondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(hex: "0C0518").opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            
            // Clean Architectural Rectangular Bar Chart with Dedicated Horizontal Slider
            VStack(spacing: 8) {
                GeometryReader { geo in
                    let w = geo.size.width
                    let h = geo.size.height
                    let standardBarWidth: CGFloat = 48.0
                    let barSpacing: CGFloat = 9.0
                    let totalContentWidth = CGFloat(blocks.count) * (standardBarWidth + barSpacing) + 24.0
                    let maxDrain = max(5.0, (blocks.map { $0.batteryDrainPercent }.max() ?? 5.0) * 1.15)
                    let overflows = totalContentWidth > w
                    
                    VStack(spacing: 8) {
                        ScrollViewReader { scrollProxy in
                            // 1. Chart Bars Area (showsIndicators: false to prevent collision with time text!)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(alignment: .bottom, spacing: barSpacing) {
                                    ForEach(blocks) { block in
                                        let isCurrentSelected = (selectedBlockId != nil ? selectedBlockId == block.id : block.id == blocks.last?.id)
                                        BlockBarColumnView(
                                            block: block,
                                            isSelected: isCurrentSelected,
                                            barWidth: standardBarWidth,
                                            availableHeight: h - (overflows ? 52 : 28),
                                            maxDrain: maxDrain,
                                            onHoverShare: { share in
                                                hoveredShare = share
                                            },
                                            onSelect: {
                                                withAnimation(.spring(response: 0.22)) {
                                                    selectedBlockId = block.id
                                                    // Auto-pause live updates on click so analysis remains static and never moves!
                                                    service.isIntervalAnalysisPaused = true
                                                    if let idx = blocks.firstIndex(where: { $0.id == block.id }), blocks.count > 1 {
                                                        sliderFraction = Double(idx) / Double(blocks.count - 1)
                                                    }
                                                }
                                            }
                                        )
                                        .id(block.id)
                                    }
                                }
                                .padding(.horizontal, 12)
                                .padding(.top, 4)
                                .padding(.bottom, 8) // Generous margin so hours never collide!
                                .frame(minWidth: w - 36, alignment: overflows ? .leading : .center)
                                .frame(maxHeight: .infinity, alignment: .bottom)
                            }
                            .onAppear {
                                if let target = selectedBlockId ?? blocks.last?.id {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        scrollProxy.scrollTo(target, anchor: .trailing)
                                    }
                                }
                            }
                            .onChange(of: service.selectedDate) { _, _ in
                                sliderFraction = 1.0
                                if let target = blocks.last?.id {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        scrollProxy.scrollTo(target, anchor: .trailing)
                                    }
                                }
                            }
                            .onChange(of: service.intervalMode) { _, _ in
                                sliderFraction = 1.0
                                if let target = blocks.last?.id {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                        scrollProxy.scrollTo(target, anchor: .trailing)
                                    }
                                }
                            }
                            
                            // 2. ALWAYS-VISIBLE HORIZONTAL SLIDER (Barra inferior horizontal visible y completamente separada)
                            if overflows {
                                IntervalHorizontalSliderBar(
                                    totalCount: blocks.count,
                                    totalContentWidth: totalContentWidth,
                                    containerWidth: w,
                                    startHour: blocks.first?.shortHour ?? "",
                                    endHour: blocks.last?.shortHour ?? "",
                                    sliderFraction: $sliderFraction,
                                    onTargetChanged: { targetIdx in
                                        if targetIdx >= 0 && targetIdx < blocks.count {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                scrollProxy.scrollTo(blocks[targetIdx].id, anchor: .center)
                                            }
                                        }
                                    }
                                )
                            }
                        }
                    }
                }
                .frame(height: 245)
            }
            .padding(18)
            .liquidGlassCard(cornerRadius: 18)
            
            // Hover Tooltip Bar
            if let hShare = hoveredShare {
                HStack(spacing: 12) {
                    Circle().fill(Color(hex: hShare.colorHex)).frame(width: 9, height: 9)
                    Text(hShare.appName)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                    Text(String(format: "%.0f%% (%.0f mWh)", hShare.percentage, hShare.mWh))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(Color(hex: hShare.colorHex))
                    Spacer()
                    Text(hShare.description)
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(1)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(hex: "1F0F38"))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            }
            
            // Selected Block Detail Inspector Card
            if let target = activeBlock {
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        VStack(alignment: .leading, spacing: 3) {
                            HStack(spacing: 8) {
                                Text(target.label)
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                                
                                HStack(spacing: 4) {
                                    if target.hasBolt {
                                        Image(systemName: "bolt.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color.liquidAmber)
                                    } else if target.hasBattery {
                                        Image(systemName: "battery.75")
                                            .font(.system(size: 9.5))
                                            .foregroundColor(Color.liquidCyan)
                                    }
                                    if target.hasMoon {
                                        Image(systemName: "moon.fill")
                                            .font(.system(size: 9))
                                            .foregroundColor(Color(hex: "CBD5E0"))
                                    }
                                    Text(target.condition.shortBadge)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(target.isCharging ? Color.liquidAmber : (target.isSleeping ? Color(hex: "CBD5E0") : Color.liquidCyan))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    (target.isCharging ? Color.liquidAmber : (target.isSleeping ? Color.white.opacity(0.12) : Color.liquidCyan)).opacity(0.16)
                                )
                                .clipShape(Capsule())
                            }
                            
                            Text(target.condition.detailedDescription)
                                .font(.system(size: 11))
                                .foregroundColor(Color.textSecondary)
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 16) {
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(loc("battery_level"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.textMuted)
                                Text("\(target.batteryLevel)%")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(target.isCharging ? Color.liquidAmber : Color.liquidCyan)
                            }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(target.isCharging ? loc("power_supply") : loc("battery_drain"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.textMuted)
                                
                                if target.isCharging {
                                    Text(target.rechargePercent > 0 ? String(format: "+%.0f%%", target.rechargePercent) : "0% (CA)")
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                        .foregroundColor(Color.liquidAmber)
                                } else {
                                    Text(String(format: "%.1f%%", target.batteryDrainPercent))
                                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                                        .foregroundColor(target.isSleeping ? Color.textSecondary : Color.liquidPink)
                                }
                            }
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text(target.isCharging ? loc("grid_consumption") : loc("total_energy"))
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(Color.textMuted)
                                Text(String(format: "%.0f mWh", target.totalMWh))
                                    .font(.system(size: 16, weight: .heavy, design: .monospaced))
                                    .foregroundColor(Color.liquidCyan)
                            }
                        }
                    }
                    
                    Divider().background(Color.white.opacity(0.12))
                    
                    Text(loc("who_used_battery"))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    VStack(spacing: 8) {
                        ForEach(target.topApps) { share in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack(spacing: 10) {
                                    Circle().fill(Color(hex: share.colorHex)).frame(width: 10, height: 10)
                                    Text(share.appName)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Text(String(format: "%.0f%% %@", share.percentage, loc("of_consumption")))
                                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                                        .foregroundColor(Color(hex: share.colorHex))
                                    
                                    Text(String(format: "•  %.0f mWh", share.mWh))
                                        .font(.system(size: 11, design: .monospaced))
                                        .foregroundColor(Color.textMuted)
                                }
                                
                                Text(share.description)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "D5C8F2").opacity(0.9))
                                    .padding(.leading, 20)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(Color(hex: "1F0F38"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                        }
                    }
                }
                .padding(18)
                .liquidGlassCard(cornerRadius: 18)
            }
            
            // Diagnóstico Inteligente de Sincronizadores en Carpetas de Desarrollo
            SmartSyncAdvisorCardView()
        }
    }
}
