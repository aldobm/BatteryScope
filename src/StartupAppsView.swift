import SwiftUI
import AppKit

public struct StartupAppsView: View {
    @ObservedObject var service = StartupAppsService.shared
    @State private var selectedFilter: StartupFilter = .all
    @State private var expandedItemId: String? = nil
    
    public enum StartupFilter: String, CaseIterable, Identifiable {
        case all = "Todas"
        case highImpact = "Alto impacto"
        case active = "Activas"
        case disabled = "Desactivadas"
        
        public var id: String { rawValue }
    }
    
    public init() {}
    
    public var filteredItems: [StartupAppItem] {
        switch selectedFilter {
        case .all:
            return service.items
        case .highImpact:
            return service.items.filter { $0.impact == .high }
        case .active:
            return service.items.filter { $0.isEnabled }
        case .disabled:
            return service.items.filter { !$0.isEnabled }
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            // MARK: - Header Info
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Apps de Arranque")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                    Text("Revisa qué aplicaciones se inician al encender tu Mac, cuánto retrasan el arranque y desactiva las innecesarias.")
                        .font(.system(size: 12))
                        .foregroundColor(Color.textSecondary)
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation(.spring(response: 0.3)) {
                        service.scanStartupItems()
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 11, weight: .bold))
                            .rotationEffect(.degrees(service.isLoading ? 360 : 0))
                            .animation(service.isLoading ? Animation.linear(duration: 1).repeatForever(autoreverses: false) : .default, value: service.isLoading)
                        Text(service.isLoading ? "Analizando..." : "Escanear de nuevo")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(Color.liquidCyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.white.opacity(0.08))
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(Color.liquidCyan.opacity(0.3), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            
            // MARK: - Status Toast (if any)
            if let msg = service.statusMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color.liquidCyan)
                        .font(.system(size: 13))
                    Text(msg)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white)
                    Spacer()
                    Button(action: { service.statusMessage = nil }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(Color.textMuted)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.liquidCyan.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.liquidCyan.opacity(0.3), lineWidth: 1))
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // MARK: - 3 Hero Impact Cards
            HStack(spacing: 16) {
                StartupMetricCard(
                    title: "Retraso en el Arranque",
                    value: String(format: "+%.1f s", service.totalEstimatedDelay),
                    subtitle: "\(service.totalActiveCount) apps activas al inicio",
                    accentColor: service.totalEstimatedDelay > 8.0 ? Color(hex: "FF453A") : Color.liquidAmber,
                    icon: "clock.badge.exclamationmark.fill",
                    badgeText: service.totalEstimatedDelay > 8.0 ? "Arranque Pesado" : "Arranque Moderado"
                )
                
                StartupMetricCard(
                    title: "Apps de Alto Impacto",
                    value: "\(service.highImpactCount)",
                    subtitle: "Causan demoras de disco y red",
                    accentColor: service.highImpactCount > 0 ? Color(hex: "FF375F") : Color.liquidCyan,
                    icon: "flame.fill",
                    badgeText: service.highImpactCount > 0 ? "Requiere Atención" : "Limpio"
                )
                
                StartupSavingsCard(
                    potentialSavings: service.potentialDelaySavings,
                    onOptimize: {
                        withAnimation(.spring(response: 0.3)) {
                            service.disableAllHighImpact()
                        }
                    }
                )
            }
            
            // MARK: - Filter Pills
            HStack(spacing: 8) {
                ForEach(StartupFilter.allCases) { filter in
                    StartupFilterPill(
                        filter: filter,
                        count: countFor(filter: filter),
                        isSelected: selectedFilter == filter,
                        action: {
                            withAnimation(.spring(response: 0.25)) {
                                selectedFilter = filter
                            }
                        }
                    )
                }
                
                Spacer()
            }
            
            // MARK: - Startup Apps List
            VStack(spacing: 12) {
                if filteredItems.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.system(size: 40))
                            .foregroundColor(Color.liquidCyan.opacity(0.8))
                            .padding(.top, 24)
                        Text("No hay aplicaciones en esta categoría")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Tu Mac no tiene elementos de inicio pendientes en este filtro.")
                            .font(.system(size: 12))
                            .foregroundColor(Color.textMuted)
                            .padding(.bottom, 24)
                    }
                    .frame(maxWidth: .infinity)
                    .liquidGlassCard(cornerRadius: 16)
                } else {
                    ForEach(filteredItems) { item in
                        StartupItemRowView(
                            item: item,
                            isExpanded: expandedItemId == item.id,
                            onToggleExpand: {
                                withAnimation(.spring(response: 0.28)) {
                                    if expandedItemId == item.id {
                                        expandedItemId = nil
                                    } else {
                                        expandedItemId = item.id
                                    }
                                }
                            },
                            onToggleState: {
                                service.toggleItem(item)
                            },
                            onOpenFinder: {
                                service.openInFinder(path: item.path)
                            }
                        )
                    }
                }
            }
        }
    }
    
    private func countFor(filter: StartupFilter) -> Int {
        switch filter {
        case .all: return service.items.count
        case .highImpact: return service.items.filter { $0.impact == .high }.count
        case .active: return service.items.filter { $0.isEnabled }.count
        case .disabled: return service.items.filter { !$0.isEnabled }.count
        }
    }
}

// MARK: - Filter Pill Subview
private struct StartupFilterPill: View {
    let filter: StartupAppsView.StartupFilter
    let count: Int
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(filter.rawValue)
                    .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                Text("\(count)")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.06))
                    .clipShape(Capsule())
            }
            .foregroundColor(isSelected ? .white : Color.textSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(isSelected ? Color.liquidPurple.opacity(0.85) : Color.white.opacity(0.04))
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(
                    isSelected ? Color.liquidCyan.opacity(0.5) : Color.white.opacity(0.08),
                    lineWidth: 1
                )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Metric Cards
private struct StartupMetricCard: View {
    let title: String
    let value: String
    let subtitle: String
    let accentColor: Color
    let icon: String
    let badgeText: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(accentColor)
                    Text(title)
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
                Text(badgeText)
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(accentColor)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(accentColor.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            Text(value)
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundColor(.white)
            
            Text(subtitle)
                .font(.system(size: 11))
                .foregroundColor(Color.textMuted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 16)
    }
}

private struct StartupSavingsCard: View {
    let potentialSavings: Double
    let onOptimize: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "bolt.badge.clock.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Color.liquidCyan)
                    Text("Ahorro Potencial")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(Color.textSecondary)
                }
                Spacer()
                Text("Optimizable")
                    .font(.system(size: 9, weight: .bold, design: .rounded))
                    .foregroundColor(Color.liquidCyan)
                    .padding(.horizontal, 7)
                    .padding(.vertical, 3)
                    .background(Color.liquidCyan.opacity(0.15))
                    .clipShape(Capsule())
            }
            
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "-%.1f s", potentialSavings))
                    .font(.system(size: 26, weight: .heavy, design: .rounded))
                    .foregroundColor(Color.liquidCyan)
                Spacer()
                if potentialSavings > 0.5 {
                    Button(action: onOptimize) {
                        Text("Acelerar Mac")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(LinearGradient(colors: [Color.liquidPink, Color.liquidPurple], startPoint: .leading, endPoint: .trailing))
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            
            Text(potentialSavings > 0.5 ? "Desactivando apps pesadas de sincronización" : "Arranque ya optimizado al máximo")
                .font(.system(size: 11))
                .foregroundColor(Color.textMuted)
                .lineLimit(1)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .liquidGlassCard(cornerRadius: 16)
    }
}

// MARK: - Startup Item Row View
private struct StartupItemRowView: View {
    let item: StartupAppItem
    let isExpanded: Bool
    let onToggleExpand: () -> Void
    let onToggleState: () -> Void
    let onOpenFinder: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Main Top Bar
            HStack(spacing: 14) {
                // App Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)
                    
                    if let icon = item.icon {
                        Image(nsImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 32, height: 32)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                    } else {
                        Image(systemName: "app.dashed")
                            .font(.system(size: 20))
                            .foregroundColor(Color.textMuted)
                    }
                }
                
                // Name & Metadata
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 8) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(item.isEnabled ? .white : Color.textSecondary)
                        
                        // Impact Badge
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.impact.badgeColor)
                                .frame(width: 6, height: 6)
                            Text("\(item.impact.rawValue) (\(item.formattedDelay))")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(item.impact.badgeColor)
                        }
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2.5)
                        .background(item.impact.badgeColor.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    HStack(spacing: 10) {
                        Text(item.sourceType.rawValue)
                            .font(.system(size: 11))
                            .foregroundColor(Color.textSecondary)
                        
                        Text("•")
                            .font(.system(size: 10))
                            .foregroundColor(Color.textMuted)
                        
                        Text(item.formattedMemory)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(item.isRunningNow ? Color.liquidCyan : Color.textMuted)
                        
                        if item.isRunningNow {
                            Text("En ejecución")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                                .foregroundColor(Color.liquidCyan)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 1)
                                .background(Color.liquidCyan.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                Spacer()
                
                // Switch / Toggle Button
                HStack(spacing: 12) {
                    Button(action: onToggleState) {
                        HStack(spacing: 7) {
                            Circle()
                                .fill(item.isEnabled ? Color.liquidCyan : Color.gray.opacity(0.5))
                                .frame(width: 8, height: 8)
                                .shadow(color: item.isEnabled ? Color.liquidCyan : Color.clear, radius: 4)
                            Text(item.isEnabled ? "Inicia al arrancar" : "Desactivado")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(item.isEnabled ? Color.liquidCyan : Color.textMuted)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(item.isEnabled ? Color.liquidCyan.opacity(0.14) : Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().strokeBorder(
                                item.isEnabled ? Color.liquidCyan.opacity(0.4) : Color.white.opacity(0.1),
                                lineWidth: 1
                            )
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Expand/Collapse Chevron
                    Button(action: onToggleExpand) {
                        Image(systemName: isExpanded ? "chevron.up.circle.fill" : "chevron.down.circle")
                            .font(.system(size: 16))
                            .foregroundColor(isExpanded ? Color.liquidCyan : Color.textMuted)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(14)
            .contentShape(Rectangle())
            .onTapGesture {
                onToggleExpand()
            }
            
            // Expanded Detailed Drawer
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.horizontal, 14)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        // Why it slows down
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(item.impact.badgeColor)
                                .font(.system(size: 12))
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("¿Por qué ralentiza el arranque?")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(item.whySlowsDown)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // Expert recommendation
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(Color.liquidAmber)
                                .font(.system(size: 12))
                                .padding(.top, 2)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Recomendación de BatteryPulse")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(item.recommendation)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color.textSecondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        
                        // Path and actions
                        HStack {
                            VStack(alignment: .leading, spacing: 1) {
                                Text("Ubicación en disco:")
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(Color.textMuted)
                                Text(item.path)
                                    .font(.system(size: 10, design: .monospaced))
                                    .foregroundColor(Color.textSecondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            
                            Spacer()
                            
                            Button(action: onOpenFinder) {
                                HStack(spacing: 5) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 10))
                                    Text("Ver en Finder")
                                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                                }
                                .foregroundColor(Color.textSecondary)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.white.opacity(0.06))
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }
                .transition(.opacity)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(hex: "130A24").opacity(0.7))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(
                    item.isEnabled ?
                    Color.white.opacity(0.10) :
                    Color.white.opacity(0.04),
                    lineWidth: 1
                )
        )
    }
}
