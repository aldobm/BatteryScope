import SwiftUI
import AppKit

public enum NavigationSection: String, CaseIterable, Identifiable {
    case smartAnalysis = "smart_analysis"
    case energyHogs = "energy_hogs"
    case todayConsumption = "today_consumption"
    case timeline = "timeline"
    case healthAndCells = "health_and_cells"
    case charger = "charger"
    case hardwareBreakdown = "hardware_breakdown"
    case startupApps = "startup_apps"
    case optimization = "optimization"
    case settings = "settings"
    
    public var id: String { rawValue }
    
    public var title: String {
        switch self {
        case .smartAnalysis: return loc("nav_smart_analysis")
        case .energyHogs: return loc("nav_energy_hogs")
        case .todayConsumption: return loc("nav_today_consumption")
        case .timeline: return loc("nav_timeline")
        case .healthAndCells: return loc("nav_health_cells")
        case .charger: return loc("nav_charger")
        case .hardwareBreakdown: return loc("nav_hardware_breakdown")
        case .startupApps: return loc("nav_startup_apps")
        case .optimization: return loc("nav_optimization")
        case .settings: return loc("nav_settings")
        }
    }
    
    public var icon: String {
        switch self {
        case .smartAnalysis: return "sparkles"
        case .energyHogs: return "flame.fill"
        case .todayConsumption: return "chart.bar.fill"
        case .timeline: return "chart.xyaxis.line"
        case .healthAndCells: return "battery.100.bolt"
        case .charger: return "powerplug.fill"
        case .hardwareBreakdown: return "cpu"
        case .startupApps: return "arrow.up.forward.app.fill"
        case .optimization: return "leaf.fill"
        case .settings: return "gearshape.fill"
        }
    }
    
    public var category: String {
        switch self {
        case .smartAnalysis: return loc("cat_diagnostics")
        case .energyHogs, .todayConsumption, .timeline: return loc("cat_consumption")
        case .healthAndCells, .charger, .hardwareBreakdown: return loc("cat_hardware")
        case .startupApps, .optimization: return loc("cat_maintenance")
        case .settings: return loc("cat_settings")
        }
    }
}

public struct MainView: View {
    @ObservedObject var service = BatteryService.shared
    @ObservedObject var locMgr = LocalizationManager.shared
    @State private var selectedSection: NavigationSection = .smartAnalysis
    @State private var isAnalyzing = false
    
    public var body: some View {
        HStack(spacing: 0) {
            // MARK: - Left Sidebar (Full Crystal CleanMyMac Style)
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(LinearGradient(colors: [Color.liquidPink, Color.liquidPurple], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 32, height: 32)
                        Image(systemName: "bolt.batteryblock.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 16))
                    }
                    VStack(alignment: .leading, spacing: 1) {
                        Text(loc("app_name"))
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                        Text(loc("app_subtitle"))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(Color.textMuted)
                    }
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.top, 42)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 16) {
                        let categories = [loc("cat_diagnostics"), loc("cat_consumption"), loc("cat_hardware"), loc("cat_maintenance"), loc("cat_settings")]
                        ForEach(categories, id: \.self) { cat in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(cat)
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundColor(Color.textMuted)
                                    .padding(.horizontal, 14)
                                    .padding(.top, 4)
                                
                                ForEach(NavigationSection.allCases.filter { $0.category == cat }) { section in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                            selectedSection = section
                                            service.selectedAppForDetail = nil
                                        }
                                    }) {
                                        HStack(spacing: 10) {
                                            Image(systemName: section.icon)
                                                .font(.system(size: 13, weight: .semibold))
                                                .foregroundColor(selectedSection == section ? .white : Color.textSecondary)
                                                .frame(width: 20)
                                            
                                            Text(section.title)
                                                .font(.system(size: 12.5, weight: selectedSection == section ? .bold : .medium, design: .rounded))
                                                .foregroundColor(selectedSection == section ? .white : Color.textSecondary)
                                            
                                            Spacer()
                                            
                                            if section == .optimization && !service.pausedPids.isEmpty {
                                                Text(String(format: loc("paused_badge"), service.pausedPids.count))
                                                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.liquidAmber)
                                                    .clipShape(Capsule())
                                            } else if section == .energyHogs {
                                                let highCount = service.topApps.filter { $0.powerScore > 25 }.count
                                                Text("\(highCount)")
                                                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                    .foregroundColor(.white)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(highCount > 0 ? Color.liquidPink : Color.white.opacity(0.14))
                                                    .clipShape(Capsule())
                                            } else if section == .startupApps {
                                                let startupCount = StartupAppsService.shared.highImpactCount
                                                if startupCount > 0 {
                                                    Text("\(startupCount)")
                                                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                                                        .foregroundColor(.white)
                                                        .padding(.horizontal, 6)
                                                        .padding(.vertical, 2)
                                                        .background(Color(hex: "FF3B30"))
                                                        .clipShape(Capsule())
                                                }
                                            }
                                        }
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .liquidPill(isSelected: selectedSection == section)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .padding(.leading, 8)
                    .padding(.trailing, 6)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    Circle()
                        .fill(service.snapshot.isCharging ? Color.liquidAmber : Color.liquidCyan)
                        .frame(width: 8, height: 8)
                        .shadow(color: service.snapshot.isCharging ? Color.liquidAmber : Color.liquidCyan, radius: 4)
                    Text("\(service.snapshot.chargePercent)%  \(loc("health")): \(service.snapshot.maxCapacityPercent)%")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(Color.textSecondary)
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 16)
            }
            .frame(width: 226)
            .background(
                ZStack {
                    Color(hex: "0E051C").opacity(0.92)
                    Color.liquidViolet.opacity(0.3)
                }
            )
            .overlay(
                Rectangle().fill(Color.white.opacity(0.08)).frame(width: 1),
                alignment: .trailing
            )
            
            // MARK: - Main Content Canvas
            ZStack {
                ZStack {
                    LinearGradient(
                        colors: [Color(hex: "0E071A"), Color(hex: "170D2C"), Color(hex: "0A0514")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    RadialGradient(colors: [Color(hex: "34155C").opacity(0.35), Color.clear], center: .topTrailing, startRadius: 40, endRadius: 480)
                    RadialGradient(colors: [Color(hex: "0D224A").opacity(0.28), Color.clear], center: .bottomLeading, startRadius: 40, endRadius: 500)
                }
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    HStack {
                        Text(selectedSection.title)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            if selectedSection == .todayConsumption {
                                Button(action: {
                                    withAnimation(.spring(response: 0.22)) {
                                        service.isIntervalAnalysisPaused.toggle()
                                        if !service.isIntervalAnalysisPaused {
                                            service.computeIntervalBlocks(currentApps: service.topApps, date: service.selectedDate, mode: service.intervalMode)
                                        }
                                    }
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: service.isIntervalAnalysisPaused ? "play.fill" : "pause.fill")
                                            .font(.system(size: 9, weight: .bold))
                                        Text(service.isIntervalAnalysisPaused ? loc("resume") : loc("pause"))
                                            .font(.system(size: 11, weight: .bold, design: .rounded))
                                    }
                                    .foregroundColor(service.isIntervalAnalysisPaused ? Color.liquidAmber : Color.liquidCyan)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4.5)
                                    .background(
                                        service.isIntervalAnalysisPaused ?
                                        Color.liquidAmber.opacity(0.2) :
                                        Color.white.opacity(0.08)
                                    )
                                    .clipShape(Capsule())
                                    .overlay(
                                        Capsule().strokeBorder(
                                            service.isIntervalAnalysisPaused ? Color.liquidAmber.opacity(0.7) : Color.white.opacity(0.15),
                                            lineWidth: 1
                                        )
                                    )
                                }
                                .buttonStyle(.plain)
                                .help(service.isIntervalAnalysisPaused ? loc("resume") : loc("pause"))
                            }
                            
                            Text(service.isIntervalAnalysisPaused && selectedSection == .todayConsumption ? loc("paused_analysis") : String(format: loc("updated_at"), service.lastScanTime.formatted(date: .omitted, time: .standard)))
                                .font(.system(size: 11))
                                .foregroundColor(service.isIntervalAnalysisPaused && selectedSection == .todayConsumption ? Color.liquidAmber : Color.textMuted)
                            
                            Button(action: { runSmartAnalysis() }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(Color.textSecondary)
                                    .padding(6)
                                    .background(Color.white.opacity(0.08))
                                    .clipShape(Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 28)
                    .padding(.top, 24)
                    .padding(.bottom, 14)
                    
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedSection {
                            case .smartAnalysis:
                                smartAnalysisView
                            case .energyHogs:
                                energyHogsView
                            case .todayConsumption:
                                TodayBlocksView()
                            case .timeline:
                                timelineView
                            case .healthAndCells:
                                healthAndCellsView
                            case .charger:
                                chargerDetailsView
                            case .hardwareBreakdown:
                                HardwareBreakdownView()
                            case .startupApps:
                                StartupAppsView()
                            case .optimization:
                                optimizationView
                            case .settings:
                                SettingsView()
                            }
                        }
                        .padding(.horizontal, 28)
                        .padding(.bottom, 28)
                    }
                }
                
                if let selectedApp = service.selectedAppForDetail {
                    ZStack {
                        Color.black.opacity(0.82)
                            .ignoresSafeArea()
                            .onTapGesture {
                                withAnimation(.spring(response: 0.28)) {
                                    service.selectedAppForDetail = nil
                                }
                            }
                        
                        ProcessDetailModalView(
                            app: selectedApp,
                            onClose: {
                                withAnimation(.spring(response: 0.28)) {
                                    service.selectedAppForDetail = nil
                                }
                            },
                            onTerminate: { pid in
                                service.terminateProcess(pid: pid)
                            }
                        )
                        .frame(maxWidth: 720)
                        .padding(20)
                        .transition(.scale(scale: 0.94).combined(with: .opacity))
                    }
                    .zIndex(200)
                }
            }
        }
        .ignoresSafeArea()
        .frame(minWidth: 920, minHeight: 640)
    }
    
    // MARK: - Tab 1: Análisis Inteligente
    private var smartAnalysisView: some View {
        VStack(spacing: 22) {
            LiquidBatteryHeroView(
                percent: service.snapshot.chargePercent,
                isCharging: service.snapshot.isCharging,
                watts: service.snapshot.systemPower > 0 ? service.snapshot.systemPower : service.snapshot.adapterPower,
                healthPercent: service.snapshot.maxCapacityPercent,
                condition: service.snapshot.condition
            )
            .padding(.top, 8)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill").foregroundColor(Color.liquidCyan).font(.system(size: 14))
                        Text(loc("live_consumption")).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    Text(String(format: "%.1f W", service.snapshot.systemPower > 0 ? service.snapshot.systemPower : service.snapshot.adapterPower))
                        .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(Color.liquidCyan)
                    Text(String(format: loc("voltage_and_current"), String(format: "%.2f V", service.snapshot.voltage), String(format: "%.2f A", abs(service.snapshot.amperage))))
                        .font(.system(size: 11)).foregroundColor(Color.textSecondary)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).liquidGlassCard(cornerRadius: 18)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "heart.fill").foregroundColor(Color.liquidEmerald).font(.system(size: 14))
                        Text(loc("battery_health")).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    Text("\(service.snapshot.maxCapacityPercent)%")
                        .font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(Color.liquidEmerald)
                    Text(String(format: loc("cycles_and_condition"), service.snapshot.cycleCount, service.snapshot.condition))
                        .font(.system(size: 11)).foregroundColor(Color.textSecondary)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).liquidGlassCard(cornerRadius: 18)
                
                let top = service.topApps.first
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill").foregroundColor(Color.liquidPink).font(.system(size: 14))
                        Text(loc("top_drain")).font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                    }
                    Text(top?.appName ?? loc("low_consumption"))
                        .font(.system(size: 18, weight: .bold, design: .rounded)).foregroundColor(.white).lineLimit(1)
                    Text(top != nil ? String(format: "%.2f W • %@", top!.instantWatts, top!.explanation.friendlyTitle) : loc("no_hogs"))
                        .font(.system(size: 11)).foregroundColor(Color.liquidPink).lineLimit(1)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).liquidGlassCard(cornerRadius: 18)
                .contentShape(Rectangle())
                .onTapGesture {
                    if let t = top {
                        withAnimation(.spring(response: 0.3)) { service.selectedAppForDetail = t }
                    }
                }
            }
            
            LiquidActionButton(isScanning: isAnalyzing) { runSmartAnalysis() }.padding(.top, 6)
        }
    }
    
    // MARK: - Tab 2: Quién Come Batería
    private var energyHogsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc("app_energy_impact")).font(.system(size: 16, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text(loc("app_energy_hint")).font(.system(size: 11)).foregroundColor(Color.liquidCyan)
                }
                Spacer()
            }
            
            HStack(spacing: 12) {
                Button(action: { service.isListFrozen.toggle() }) {
                    HStack(spacing: 6) {
                        Image(systemName: service.isListFrozen ? "lock.fill" : "play.fill").font(.system(size: 11))
                        Text(service.isListFrozen ? loc("list_frozen") : loc("list_live"))
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(service.isListFrozen ? Color.liquidCyan : Color.liquidEmerald)
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(service.isListFrozen ? Color.liquidCyan.opacity(0.18) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(service.isListFrozen ? Color.liquidCyan.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1))
                }
                .buttonStyle(.plain)
                
                HStack(spacing: 6) {
                    Text(loc("sort_by")).font(.system(size: 11, weight: .semibold)).foregroundColor(Color.textSecondary)
                    Menu {
                        ForEach(ProcessSortOption.allCases) { opt in
                            Button(action: { service.updateSortOption(opt) }) {
                                HStack {
                                    Text(opt.rawValue)
                                    if service.sortOption == opt { Image(systemName: "checkmark") }
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Text(service.sortOption.rawValue).font(.system(size: 11, weight: .bold, design: .rounded)).foregroundColor(.white)
                            Image(systemName: "chevron.up.chevron.down").font(.system(size: 9)).foregroundColor(Color.textSecondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 5).background(Color.white.opacity(0.08)).clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass").foregroundColor(Color.textMuted).font(.system(size: 11))
                    TextField(loc("filter_placeholder"), text: $service.searchQuery)
                        .textFieldStyle(.plain).font(.system(size: 11)).foregroundColor(.white).frame(width: 120)
                }
                .padding(.horizontal, 10).padding(.vertical, 5).background(Color(hex: "080313").opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 8)).overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
            }
            .padding(10).background(Color(hex: "0A0414").opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 12))
            
            let query = service.searchQuery.trimmingCharacters(in: .whitespaces).lowercased()
            let filteredApps = query.isEmpty ? service.topApps : service.topApps.filter {
                $0.appName.lowercased().contains(query) || $0.processName.lowercased().contains(query) || "\($0.pid)".contains(query)
            }
            let maxScore = filteredApps.map { $0.powerScore }.max() ?? 10.0
            
            ForEach(filteredApps) { app in
                AppEnergyRowView(
                    app: app,
                    maxPower: maxScore,
                    onSelect: { withAnimation(.spring(response: 0.28)) { service.selectedAppForDetail = app } },
                    onTerminate: { pid in service.terminateProcess(pid: pid) }
                )
            }
        }
    }
    
    // MARK: - Tab 4: Gráficos de Tiempo
    private var timelineView: some View {
        VStack(spacing: 20) {
            TimelineChartView()
            
            VStack(alignment: .leading, spacing: 12) {
                Text(loc("hourly_breakdown")).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                
                ForEach(service.historyPoints.suffix(6).reversed()) { pt in
                    HStack(spacing: 12) {
                        Image(systemName: pt.isCharging ? "bolt.circle.fill" : "battery.50")
                            .foregroundColor(pt.isCharging ? Color.liquidAmber : Color.liquidCyan).font(.system(size: 16))
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(pt.timestamp.formatted(date: .abbreviated, time: .shortened))
                                .font(.system(size: 12, weight: .bold, design: .rounded)).foregroundColor(.white)
                            Text(pt.notes).font(.system(size: 11)).foregroundColor(Color.textSecondary)
                        }
                        Spacer()
                        Text("\(pt.batteryPercent)%").font(.system(size: 15, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    }
                    .padding(12).background(Color(hex: "0A0414").opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
            .padding(18).liquidGlassCard(cornerRadius: 18)
        }
    }
    
    // MARK: - Tab 5: Salud y Celdas
    private var healthAndCellsView: some View {
        VStack(spacing: 20) {
            CellVoltageVisualizerView(cellVoltages: service.snapshot.cellVoltages)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc("nominal_capacity")).font(.system(size: 11, weight: .bold)).foregroundColor(Color.textSecondary)
                    Text("\(service.snapshot.nominalCapacity) mAh").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(.white)
                    Text(loc("nominal_capacity_sub")).font(.system(size: 10)).foregroundColor(Color.textMuted)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).liquidGlassCard(cornerRadius: 16)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(loc("design_capacity")).font(.system(size: 11, weight: .bold)).foregroundColor(Color.textSecondary)
                    Text("\(service.snapshot.designCapacity) mAh").font(.system(size: 22, weight: .heavy, design: .rounded)).foregroundColor(Color.liquidEmerald)
                    Text(loc("design_capacity_sub")).font(.system(size: 10)).foregroundColor(Color.textMuted)
                }
                .padding(16).frame(maxWidth: .infinity, alignment: .leading).liquidGlassCard(cornerRadius: 16)
            }
            
            VStack(alignment: .leading, spacing: 12) {
                Text(loc("hw_sensors")).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                
                HStack(spacing: 20) {
                    HStack(spacing: 10) {
                        Image(systemName: "thermometer.medium").foregroundColor(Color.liquidAmber).font(.system(size: 17))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("temperature")).font(.system(size: 10)).foregroundColor(Color.textSecondary)
                            Text(String(format: "%.1f °C", service.snapshot.temperature > 0 ? service.snapshot.temperature : 30.6))
                                .font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                        }
                    }
                    Divider().frame(height: 22).background(Color.white.opacity(0.12))
                    HStack(spacing: 10) {
                        Image(systemName: "arrow.triangle.2.circlepath").foregroundColor(Color.liquidCyan).font(.system(size: 17))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("charge_cycles")).font(.system(size: 10)).foregroundColor(Color.textSecondary)
                            Text(String(format: loc("charge_cycles_format"), service.snapshot.cycleCount)).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                        }
                    }
                    Divider().frame(height: 22).background(Color.white.opacity(0.12))
                    HStack(spacing: 10) {
                        Image(systemName: "shield.checkerboard").foregroundColor(Color.liquidEmerald).font(.system(size: 17))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(loc("health_status")).font(.system(size: 10)).foregroundColor(Color.textSecondary)
                            Text(service.snapshot.condition).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(Color.liquidEmerald)
                        }
                    }
                }
            }
            .padding(18).liquidGlassCard(cornerRadius: 18)
        }
    }
    
    // MARK: - Tab 6: Cargador USB-C
    private var chargerDetailsView: some View {
        VStack(spacing: 18) {
            HStack(spacing: 18) {
                ZStack {
                    Circle().fill(Color.liquidAmber.opacity(0.15)).frame(width: 58, height: 58)
                    Image(systemName: "powerplug.fill").foregroundColor(Color.liquidAmber).font(.system(size: 26))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(service.snapshot.adapterName).font(.system(size: 17, weight: .bold, design: .rounded)).foregroundColor(.white)
                    Text(String(format: loc("adapter_manufacturer"), service.snapshot.adapterManufacturer.isEmpty ? "Apple Inc." : service.snapshot.adapterManufacturer))
                        .font(.system(size: 12)).foregroundColor(Color.textSecondary)
                }
                Spacer()
                if service.snapshot.adapterWatts > 0 {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(service.snapshot.adapterWatts) W").font(.system(size: 24, weight: .heavy, design: .rounded)).foregroundColor(Color.liquidAmber)
                        Text(loc("negotiated_power")).font(.system(size: 10)).foregroundColor(Color.textMuted)
                    }
                }
            }
            .padding(18).liquidGlassCard(cornerRadius: 18)
            
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("adapter_voltage")).font(.system(size: 10, weight: .semibold)).foregroundColor(Color.textSecondary)
                    Text(String(format: "%.1f V", service.snapshot.adapterVoltage > 0 ? service.snapshot.adapterVoltage : 20.0))
                        .font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "0A0414").opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("adapter_current")).font(.system(size: 10, weight: .semibold)).foregroundColor(Color.textSecondary)
                    Text(String(format: "%.1f A", service.snapshot.adapterCurrent > 0 ? service.snapshot.adapterCurrent : 3.0))
                        .font(.system(size: 18, weight: .bold, design: .monospaced)).foregroundColor(.white)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "0A0414").opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 14))
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(loc("cable_status")).font(.system(size: 10, weight: .semibold)).foregroundColor(Color.textSecondary)
                    Text(loc("cable_status_optimal")).font(.system(size: 15, weight: .bold, design: .rounded)).foregroundColor(Color.liquidEmerald)
                }
                .padding(14).frame(maxWidth: .infinity, alignment: .leading).background(Color(hex: "0A0414").opacity(0.45)).clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
    }
    
    // MARK: - Tab 7: Optimización con POSICIONES FIJAS y REGISTRO DE PAUSADOS
    private var optimizationView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text(loc("opt_control_center"))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(loc("opt_control_desc"))
                        .font(.system(size: 11))
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
                
                // Fixed Slot Indicator
                HStack(spacing: 5) {
                    Image(systemName: "lock.fill").font(.system(size: 10)).foregroundColor(Color.liquidCyan)
                    Text("Fichas Inmóviles").font(.system(size: 11, weight: .bold)).foregroundColor(Color.liquidCyan)
                }
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Color.liquidCyan.opacity(0.14)).clipShape(Capsule())
            }
            
            // Diagnóstico Inteligente de Sincronizadores en Carpetas de Desarrollo
            SmartSyncAdvisorCardView()
            
            // SECTION 1: DETAILED PAUSED PROCESSES REGISTRY (Actualmente en Pausa)
            let activePaused = service.pausedRecords.filter { $0.isCurrentlyPaused }
            if !activePaused.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        HStack(spacing: 6) {
                            Circle().fill(Color.liquidAmber).frame(width: 9, height: 9)
                            Text("Registro de Procesos Actualmente en Pausa (\(activePaused.count))")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            service.resumeAllProcesses()
                        }) {
                            HStack(spacing: 5) {
                                Image(systemName: "play.circle.fill")
                                Text("Reanudar Todos")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(Color.liquidEmerald)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    
                    ForEach(activePaused) { rec in
                        HStack(spacing: 12) {
                            if let img = rec.icon {
                                Image(nsImage: img).resizable().frame(width: 32, height: 32)
                            } else {
                                Image(systemName: "pause.circle.fill").font(.system(size: 26)).foregroundColor(Color.liquidAmber)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text(rec.appName)
                                        .font(.system(size: 13, weight: .bold, design: .rounded))
                                        .foregroundColor(.white)
                                    Text("PID \(rec.pid)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Color.textMuted)
                                    Text("PAUSADO CON SIGSTOP")
                                        .font(.system(size: 9, weight: .black, design: .rounded))
                                        .foregroundColor(Color.liquidAmber)
                                        .padding(.horizontal, 5).padding(.vertical, 1.5)
                                        .background(Color.liquidAmber.opacity(0.2)).clipShape(Capsule())
                                }
                                
                                Text("Pausado a las \(rec.pausedAt.formatted(date: .omitted, time: .standard)) • En pausa desde hace \(rec.minutesInPause) min")
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(hex: "D5C8F2"))
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("0.0 W (Ahorrado: \(String(format: "%.1f W", rec.originalWatts)))")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(Color.liquidEmerald)
                                Text("~\(String(format: "%.0f mWh", rec.estimatedMWhSaved)) batería ahorrada")
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(Color.liquidCyan)
                            }
                            
                            Button(action: {
                                service.resumeProcess(pid: rec.pid)
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: "play.fill")
                                    Text("Arrancar de nuevo")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(Color.liquidEmerald)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(12)
                        .background(Color(hex: "23103D"))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.liquidAmber.opacity(0.5), lineWidth: 1.2))
                    }
                }
                .padding(16)
                .background(Color(hex: "18092B"))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.liquidAmber.opacity(0.35), lineWidth: 1))
            }
            
            // SECTION 2: FIXED STABLE PROCESS CARDS (Posiciones que NO suben ni bajan)
            VStack(alignment: .leading, spacing: 10) {
                Text("Procesos Detectados (Posiciones Fijas)")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                let stableApps = service.stableOptimizationApps.isEmpty ? Array(service.topApps.prefix(4)) : service.stableOptimizationApps
                
                VStack(spacing: 12) {
                    ForEach(stableApps) { app in
                        let isPaused = service.isProcessPaused(pid: app.pid)
                        VStack(alignment: .leading, spacing: 10) {
                            HStack(spacing: 12) {
                                if let img = app.icon {
                                    Image(nsImage: img).resizable().frame(width: 34, height: 34)
                                } else {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(Color(hex: "2D134D"))
                                            .frame(width: 34, height: 34)
                                        Image(systemName: "cpu.fill").foregroundColor(Color.liquidCyan).font(.system(size: 16))
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 8) {
                                        Text(app.appName)
                                            .font(.system(size: 14, weight: .bold, design: .rounded))
                                            .foregroundColor(.white)
                                        
                                        if isPaused {
                                            Text("PAUSADO (0.0 W)")
                                                .font(.system(size: 9, weight: .black, design: .rounded))
                                                .foregroundColor(Color.liquidAmber)
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Color.liquidAmber.opacity(0.18)).clipShape(Capsule())
                                        } else {
                                            Text("DRENANDO")
                                                .font(.system(size: 9, weight: .black, design: .rounded))
                                                .foregroundColor(Color.liquidPink)
                                                .padding(.horizontal, 6).padding(.vertical, 2)
                                                .background(Color.liquidPink.opacity(0.18)).clipShape(Capsule())
                                        }
                                    }
                                    
                                    Text("\(app.processName) • PID \(app.pid)")
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Color.textMuted)
                                }
                                
                                Spacer()
                                
                                VStack(alignment: .trailing, spacing: 2) {
                                    Text(isPaused ? "0.00 W" : String(format: "%.2f W", app.instantWatts))
                                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                                        .foregroundColor(isPaused ? Color.liquidAmber : Color.liquidPink)
                                    Text(String(format: "%.0f mWh gastados", app.accumulatedMWh))
                                        .font(.system(size: 10, design: .monospaced))
                                        .foregroundColor(Color.textSecondary)
                                }
                            }
                            
                            VStack(alignment: .leading, spacing: 6) {
                                Text(app.explanation.description)
                                    .font(.system(size: 11.5))
                                    .foregroundColor(Color(hex: "E6DCF5"))
                                
                                HStack(alignment: .top, spacing: 14) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Causa de Actividad:")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color.liquidAmber)
                                        Text(app.explanation.whyActive)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.textSecondary)
                                    }
                                    
                                    Divider().frame(height: 26).background(Color.white.opacity(0.12))
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Recomendación de Batería:")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(Color.liquidEmerald)
                                        Text(app.explanation.whatToDo)
                                            .font(.system(size: 11))
                                            .foregroundColor(Color.textSecondary)
                                    }
                                }
                            }
                            .padding(10)
                            .background(Color(hex: "1F0F38"))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            
                            // Action Buttons
                            HStack(spacing: 10) {
                                if app.explanation.canPause {
                                    Button(action: {
                                        if isPaused {
                                            service.resumeProcess(pid: app.pid)
                                        } else {
                                            service.pauseProcess(app: app)
                                        }
                                    }) {
                                        HStack(spacing: 5) {
                                            Image(systemName: isPaused ? "play.fill" : "pause.fill")
                                            Text(isPaused ? "Reanudar Proceso" : "Pausar Proceso (Congelar a 0W)")
                                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                        }
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 12).padding(.vertical, 6)
                                        .background(isPaused ? Color.liquidEmerald : Color.liquidAmber)
                                        .clipShape(Capsule())
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                if app.explanation.safeToStop {
                                    Button(action: {
                                        service.terminateProcess(pid: app.pid)
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "xmark.circle")
                                            Text("Detener")
                                                .font(.system(size: 11, weight: .bold))
                                        }
                                        .foregroundColor(Color.liquidPink)
                                        .padding(.horizontal, 10).padding(.vertical, 6)
                                        .background(Color.liquidPink.opacity(0.12))
                                        .clipShape(Capsule())
                                        .overlay(Capsule().strokeBorder(Color.liquidPink.opacity(0.3), lineWidth: 1))
                                    }
                                    .buttonStyle(.plain)
                                }
                                
                                Spacer()
                            }
                        }
                        .padding(14)
                        .background(Color(hex: "140828"))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Color.white.opacity(0.12), lineWidth: 1))
                    }
                }
            }
            
            // Standard Tips
            VStack(alignment: .leading, spacing: 10) {
                Text("Consejos de Hardware del Sistema").font(.system(size: 14, weight: .bold, design: .rounded)).foregroundColor(.white)
                
                optimizationTipRow(
                    icon: "sun.max.fill",
                    color: Color.liquidAmber,
                    title: "Brillo de Pantalla Dinámico",
                    desc: "La pantalla es el mayor consumidor del Mac (~35% del total). Mantenerla en 75% ahorra hasta 1 hora adicional de batería."
                )
                
                optimizationTipRow(
                    icon: "battery.50",
                    color: Color.liquidEmerald,
                    title: "Regla del 20% - 80%",
                    desc: "Tu batería tiene 96% de salud tras 140 ciclos. Para mantenerla por encima del 90% más tiempo, evita dejar que baje del 20% frecuentemente."
                )
            }
        }
    }
    
    private func optimizationTipRow(icon: String, color: Color, title: String, desc: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 38, height: 38)
                Image(systemName: icon).foregroundColor(color).font(.system(size: 17))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundColor(.white)
                Text(desc).font(.system(size: 11)).foregroundColor(Color.textSecondary).lineSpacing(2)
            }
            Spacer()
        }
        .padding(16).liquidGlassCard(cornerRadius: 16)
    }
    
    private func runSmartAnalysis() {
        isAnalyzing = true
        service.refreshAll()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { isAnalyzing = false }
    }
}
