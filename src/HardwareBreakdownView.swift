import SwiftUI
import AppKit

public struct HardwareBreakdownView: View {
    @ObservedObject var service = HardwareBreakdownService.shared
    @ObservedObject var locMgr = LocalizationManager.shared
    @State private var timeRange: HardwareTimeRange = .live
    @State private var selectedComponentFilter: HardwareComponentType? = nil
    @State private var hoveredPoint: HardwareTimePoint? = nil
    
    public enum HardwareTimeRange: String, CaseIterable, Identifiable {
        case live = "live"
        case day = "day"
        
        public var id: String { rawValue }
        
        public var label: String {
            switch self {
            case .live: return loc("time_live")
            case .day: return loc("time_day")
            }
        }
    }
    
    public init() {}
    
    private var chartPoints: [HardwareTimePoint] {
        switch timeRange {
        case .live:
            return service.liveHistory
        case .day:
            return service.dayHistory
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // MARK: - Header
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc("hw_breakdown_title"))
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text(loc("hw_breakdown_subtitle"))
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        service.updateHardwareMetrics()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.badge.clock.fill")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.liquidCyan)
                        Text(loc("refresh"))
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(Color.liquidCyan)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.liquidCyan.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            
            // MARK: - 3 Hero Metrics
            HStack(spacing: 16) {
                HardwareHeroCard(
                    title: loc("total_hw_power"),
                    value: String(format: "%.1f W", service.totalSystemWatts),
                    subtitle: loc("total_hw_subtitle"),
                    accentColor: Color.liquidCyan,
                    icon: "bolt.fill"
                )
                
                HardwareHeroCard(
                    title: loc("top_consumer"),
                    value: service.topComponent.title,
                    subtitle: loc("top_consumer_share"),
                    accentColor: Color(hex: service.topComponent.colorHex),
                    icon: service.topComponent.icon
                )
                
                HardwareHeroCard(
                    title: loc("architecture"),
                    value: "Apple M1",
                    subtitle: loc("soc_specs"),
                    accentColor: Color.liquidPurple,
                    icon: "cpu.fill"
                )
            }
            
            // MARK: - Interactive Hardware Timeline Chart
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(loc("hw_chart_title"))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(selectedComponentFilter != nil ?
                             locFormat("hw_chart_subtitle_single", selectedComponentFilter!.title) :
                             loc("hw_chart_subtitle_all"))
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                    }
                    
                    Spacer()
                    
                    // Time Range Selector
                    HStack(spacing: 4) {
                        ForEach(HardwareTimeRange.allCases) { range in
                            Button(action: {
                                withAnimation(.spring(response: 0.25)) {
                                    timeRange = range
                                }
                            }) {
                                Text(range.label)
                                    .font(.system(size: 11, weight: timeRange == range ? .bold : .medium, design: .rounded))
                                    .foregroundColor(timeRange == range ? .white : Color.textSecondary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(timeRange == range ? Color.liquidCyan.opacity(0.25) : Color.white.opacity(0.04))
                                    .clipShape(Capsule())
                                    .overlay(Capsule().strokeBorder(timeRange == range ? Color.liquidCyan.opacity(0.6) : Color.clear, lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Filter chips by component
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        Button(action: {
                            withAnimation(.spring(response: 0.25)) {
                                selectedComponentFilter = nil
                            }
                        }) {
                            HStack(spacing: 5) {
                                Circle().fill(selectedComponentFilter == nil ? Color.liquidCyan : Color.gray).frame(width: 6, height: 6)
                                Text(loc("all_components"))
                                    .font(.system(size: 11, weight: selectedComponentFilter == nil ? .bold : .medium, design: .rounded))
                            }
                            .foregroundColor(selectedComponentFilter == nil ? .white : Color.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4.5)
                            .background(selectedComponentFilter == nil ? Color.liquidCyan.opacity(0.18) : Color.white.opacity(0.04))
                            .clipShape(Capsule())
                            .overlay(Capsule().strokeBorder(selectedComponentFilter == nil ? Color.liquidCyan.opacity(0.4) : Color.white.opacity(0.08), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                        
                        ForEach(HardwareComponentType.allCases) { comp in
                            Button(action: {
                                withAnimation(.spring(response: 0.25)) {
                                    if selectedComponentFilter == comp {
                                        selectedComponentFilter = nil
                                    } else {
                                        selectedComponentFilter = comp
                                    }
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: comp.icon)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(Color(hex: comp.colorHex))
                                    Text(comp.title)
                                        .font(.system(size: 11.5, weight: selectedComponentFilter == comp ? .bold : .medium, design: .rounded))
                                }
                                .foregroundColor(selectedComponentFilter == comp ? .white : Color.textSecondary)
                                .padding(.horizontal, 11)
                                .padding(.vertical, 6)
                                .background(selectedComponentFilter == comp ? Color(hex: comp.colorHex).opacity(0.24) : Color.white.opacity(0.04))
                                .clipShape(Capsule())
                                .overlay(Capsule().strokeBorder(selectedComponentFilter == comp ? Color(hex: comp.colorHex).opacity(0.7) : Color.white.opacity(0.1), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                
                // Chart Canvas
                HardwareChartCanvas(
                    points: chartPoints,
                    selectedComponent: selectedComponentFilter,
                    hoveredPoint: $hoveredPoint
                )
                .frame(height: 180)
                
                // Tooltip info bar
                if let pt = hoveredPoint {
                    HStack(spacing: 12) {
                        Text(pt.timeLabel)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.white)
                        
                        Text("•")
                            .foregroundColor(Color.textMuted)
                        
                        if let comp = selectedComponentFilter {
                            HStack(spacing: 4) {
                                Circle().fill(Color(hex: comp.colorHex)).frame(width: 6, height: 6)
                                Text("\(comp.rawValue): \(String(format: "%.2f W", pt.watts(for: comp)))")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(Color(hex: comp.colorHex))
                            }
                        } else {
                            Text("Total: \(String(format: "%.1f W", pt.totalWatts))")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color.liquidCyan)
                            
                            Text("Pantalla: \(String(format: "%.1f W", pt.displayWatts))")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "00F5D4"))
                            
                            Text("CPU/GPU: \(String(format: "%.1f W", pt.cpuGpuWatts))")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "3A86FF"))
                            
                            Text("RAM: \(String(format: "%.1f W", pt.ramWatts))")
                                .font(.system(size: 10))
                                .foregroundColor(Color(hex: "9D4EDD"))
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(18)
            .liquidGlassCard(cornerRadius: 18)
            
            // MARK: - Hardware Components Grid / List
            VStack(alignment: .leading, spacing: 12) {
                Text(loc("hw_subsystems_title"))
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                VStack(spacing: 10) {
                    ForEach(service.components) { item in
                        HardwareComponentCard(item: item)
                    }
                }
            }
        }
    }
}

// MARK: - Subcomponents
private struct HardwareHeroCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    let icon: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(Color.textSecondary)
                
                Text(value)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                
                Text(subtitle)
                    .font(.system(size: 11))
                    .foregroundColor(Color.textMuted)
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(accentColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(accentColor)
            }
            .shadow(color: accentColor.opacity(0.35), radius: 6)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 16)
    }
}

private struct HardwareComponentCard: View {
    let item: HardwareLiveComponent
    
    var body: some View {
        HStack(spacing: 16) {
            // Big prominent Icon Pill
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color(hex: item.type.colorHex).opacity(0.20))
                    .frame(width: 52, height: 52)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(Color(hex: item.type.colorHex).opacity(0.40), lineWidth: 1)
                    )
                
                Image(systemName: item.type.icon)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(hex: item.type.colorHex))
            }
            .shadow(color: Color(hex: item.type.colorHex).opacity(0.28), radius: 8, x: 0, y: 3)
            
            // Info Column
            VStack(alignment: .leading, spacing: 5) {
                HStack {
                    Text(item.type.title)
                        .font(.system(size: 14.5, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Text(item.formattedWatts)
                        .font(.system(size: 14.5, weight: .heavy, design: .rounded))
                        .foregroundColor(Color(hex: item.type.colorHex))
                    
                    Text("(\(item.formattedPercentage))")
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.textMuted)
                }
                
                // Progress Bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 7)
                        
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [Color(hex: item.type.colorHex), Color(hex: item.type.colorHex).opacity(0.65)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(8, geo.size.width * CGFloat(min(1.0, item.percentageOfTotal / 100.0))), height: 7)
                    }
                }
                .frame(height: 7)
                
                // Subtitles
                HStack {
                    Text(item.type.technicalSubtitle)
                        .font(.system(size: 10.5))
                        .foregroundColor(Color.textSecondary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    Text("Total: \(item.formattedMWh)")
                        .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                        .foregroundColor(Color.liquidCyan)
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(hex: "120822").opacity(0.75))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct HardwareChartCanvas: View {
    let points: [HardwareTimePoint]
    let selectedComponent: HardwareComponentType?
    @Binding var hoveredPoint: HardwareTimePoint?
    
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            
            if points.count >= 2 {
                let maxWatts = max(8.0, (points.map { pt in
                    selectedComponent != nil ? pt.watts(for: selectedComponent!) : pt.totalWatts
                }.max() ?? 10.0) * 1.25)
                
                let stepX = w / CGFloat(max(points.count - 1, 1))
                
                ZStack(alignment: .topLeading) {
                    // Background grid lines
                    VStack {
                        ForEach([10, 5, 0], id: \.self) { val in
                            HStack {
                                Text("\(val) W")
                                    .font(.system(size: 9, design: .monospaced))
                                    .foregroundColor(Color.textMuted.opacity(0.6))
                                    .frame(width: 30, alignment: .trailing)
                                Rectangle().fill(Color.white.opacity(0.05)).frame(height: 1)
                            }
                            if val > 0 { Spacer() }
                        }
                    }
                    .frame(height: h)
                    
                    // Chart Area Path
                    let color = selectedComponent != nil ? Color(hex: selectedComponent!.colorHex) : Color.liquidCyan
                    
                    Path { path in
                        for (i, pt) in points.enumerated() {
                            let val = selectedComponent != nil ? pt.watts(for: selectedComponent!) : pt.totalWatts
                            let x = CGFloat(i) * stepX
                            let y = h - (CGFloat(val / maxWatts) * h)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                        path.addLine(to: CGPoint(x: CGFloat(points.count - 1) * stepX, y: h))
                        path.addLine(to: CGPoint(x: 0, y: h))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [color.opacity(0.35), color.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Line Stroke
                    Path { path in
                        for (i, pt) in points.enumerated() {
                            let val = selectedComponent != nil ? pt.watts(for: selectedComponent!) : pt.totalWatts
                            let x = CGFloat(i) * stepX
                            let y = h - (CGFloat(val / maxWatts) * h)
                            if i == 0 { path.move(to: CGPoint(x: x, y: y)) }
                            else { path.addLine(to: CGPoint(x: x, y: y)) }
                        }
                    }
                    .stroke(
                        LinearGradient(colors: [color, color.opacity(0.7)], startPoint: .leading, endPoint: .trailing),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round)
                    )
                    
                    // Data Dots & Hover Detection
                    HStack(spacing: 0) {
                        ForEach(Array(points.enumerated()), id: \.offset) { idx, pt in
                            Color.clear
                                .frame(width: stepX)
                                .contentShape(Rectangle())
                                .onHover { hov in
                                    if hov {
                                        hoveredPoint = pt
                                    }
                                }
                        }
                    }
                }
            } else {
                Text("Recopilando métricas de hardware...")
                    .font(.system(size: 12))
                    .foregroundColor(Color.textMuted)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
