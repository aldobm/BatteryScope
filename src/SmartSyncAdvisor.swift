import SwiftUI
import AppKit

// MARK: - Smart Cloud Sync & Developer Projects Advisor

public struct SyncDaemonInfo: Identifiable {
    public let id = UUID()
    public let name: String
    public let friendlyTitle: String
    public let pid: Int32
    public let cpuPercent: Double
    public let watts: Double
    public let iconName: String
    public let isPaused: Bool
}

public struct SmartDeveloperSyncState {
    public var hasSyncDaemons: Bool = false
    public var daemons: [SyncDaemonInfo] = []
    public var totalWatts: Double = 0.0
    public var totalCpuPercent: Double = 0.0
    public var hasDevToolsRunning: Bool = false
    public var devToolsFound: [String] = []
    
    public var severityTitle: String {
        if totalWatts > 2.5 || totalCpuPercent > 20.0 {
            return "Consumo Crítico por Sincronización en Segundo Plano"
        } else {
            return "Sincronizadores Activos en Carpetas de Desarrollo"
        }
    }
}

public class SmartSyncAdvisor {
    public static let shared = SmartSyncAdvisor()
    
    private init() {}
    
    public func analyze(apps: [AppEnergyUsage]) -> SmartDeveloperSyncState {
        var state = SmartDeveloperSyncState()
        let service = BatteryService.shared
        
        let syncNames = [
            "cloud-drive-daemon", "cloud-drive-eventd", "cloud-drive-daem", "SynologyDrive", "Synology Drive",
            "Google Drive", "GoogleDriveFS", "Google Drive File Provider",
            "fileproviderd", "Dropbox", "OneDrive"
        ]
        
        var detected: [SyncDaemonInfo] = []
        var sumWatts = 0.0
        var sumCpu = 0.0
        
        for app in apps {
            let lower = app.processName.lowercased()
            let lowerApp = app.appName.lowercased()
            
            if syncNames.contains(where: { lower.contains($0.lowercased()) || lowerApp.contains($0.lowercased()) }) {
                let friendly: String
                let icon: String
                if lower.contains("cloud-drive") || lower.contains("synology") {
                    friendly = "Synology Drive"
                    icon = "externaldrive.badge.icloud"
                } else if lower.contains("google") {
                    friendly = "Google Drive"
                    icon = "arrow.triangle.2.circlepath.circle.fill"
                } else if lower.contains("fileprovider") {
                    friendly = "macOS FileProvider"
                    icon = "folder.badge.gearshape"
                } else if lower.contains("dropbox") {
                    friendly = "Dropbox"
                    icon = "shippingbox.fill"
                } else if lower.contains("onedrive") {
                    friendly = "OneDrive"
                    icon = "cloud.fill"
                } else {
                    friendly = app.appName
                    icon = "arrow.triangle.2.circlepath"
                }
                
                let isP = service.isProcessPaused(pid: app.pid)
                detected.append(SyncDaemonInfo(
                    name: app.processName,
                    friendlyTitle: friendly,
                    pid: app.pid,
                    cpuPercent: app.cpuPercent,
                    watts: app.instantWatts,
                    iconName: icon,
                    isPaused: isP
                ))
                
                sumWatts += app.instantWatts
                sumCpu += app.cpuPercent
            }
        }
        
        state.hasSyncDaemons = !detected.isEmpty
        state.daemons = detected
        state.totalWatts = sumWatts
        state.totalCpuPercent = sumCpu
        
        // Detect Developer Activity
        let devIdentifiers = ["git", "node", "npm", "python", "swift", "cargo", "code", "cursor", "antigravity", "xcode", "clang"]
        var devFound: [String] = []
        for app in apps {
            let pName = app.processName.lowercased()
            for dev in devIdentifiers {
                if pName.contains(dev) && !devFound.contains(dev) {
                    devFound.append(dev)
                }
            }
        }
        state.hasDevToolsRunning = !devFound.isEmpty
        state.devToolsFound = devFound
        
        return state
    }
}

// MARK: - Smart Sync Advisor Interactive UI Card

public struct SmartSyncAdvisorCardView: View {
    @ObservedObject var service = BatteryService.shared
    @State private var showExclusionRules = false
    @State private var showArchitectureAdvice = false
    @State private var showOtherProcessesAdvice = false
    @State private var actionMessage: String? = nil
    
    private var state: SmartDeveloperSyncState {
        SmartSyncAdvisor.shared.analyze(apps: service.topApps)
    }
    
    public var body: some View {
        if state.hasSyncDaemons {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(
                                LinearGradient(
                                    colors: [Color.liquidAmber, Color.liquidPink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 32, height: 32)
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 15))
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("DIAGNÓSTICO INTELIGENTE • CONFLICTO DE BATERÍA")
                                .font(.system(size: 10, weight: .heavy, design: .rounded))
                                .foregroundColor(Color.liquidAmber)
                            
                            if state.hasDevToolsRunning {
                                Text("DESARROLLO DETECTADO")
                                    .font(.system(size: 9, weight: .bold))
                                    .foregroundColor(Color.liquidCyan)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.liquidCyan.opacity(0.18))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        Text(state.severityTitle)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Text(String(format: "%.1f W", state.totalWatts))
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(Color.liquidPink)
                        Text(String(format: "• %.1f%% CPU", state.totalCpuPercent))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(Color.textSecondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.black.opacity(0.4))
                    .clipShape(Capsule())
                }
                
                // Explanatory diagnosis tailored to User Request
                VStack(alignment: .leading, spacing: 6) {
                    Text("¿Por qué Synology Drive y Google Drive drenan tanta batería?")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(Color(hex: "F3E8FF"))
                    
                    Text("Cuando trabajas en directorios de proyectos de código, cada guardado, instalación de dependencias ('node_modules', virtualenvs) o compilación genera **miles de microarchivos temporales** en segundos. Synology Drive, Google Drive y 'fileproviderd' detectan estos eventos de disco continuos (FSEvents), recalculan hashes criptográficos y sincronizan sin descanso, **impidiendo que el chip entre en reposo profundo** y consumiendo entre 2W y 5W adicionales de batería de forma ininterrumpida.")
                        .font(.system(size: 11.5))
                        .foregroundColor(Color(hex: "D1C4E9"))
                        .lineSpacing(2.5)
                }
                .padding(12)
                .background(Color(hex: "1F0F38").opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 1))
                
                // Running Daemons Badges
                HStack(spacing: 8) {
                    ForEach(state.daemons) { daemon in
                        HStack(spacing: 6) {
                            Image(systemName: daemon.iconName)
                                .foregroundColor(daemon.isPaused ? Color.liquidEmerald : Color.liquidAmber)
                                .font(.system(size: 11))
                            Text(daemon.friendlyTitle)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                            Text(daemon.isPaused ? "PAUSADO" : String(format: "%.1f W", daemon.watts))
                                .font(.system(size: 10, weight: .heavy, design: .monospaced))
                                .foregroundColor(daemon.isPaused ? Color.liquidEmerald : Color.liquidPink)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(daemon.isPaused ? Color.liquidEmerald.opacity(0.15) : Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(daemon.isPaused ? Color.liquidEmerald.opacity(0.4) : Color.white.opacity(0.12), lineWidth: 1))
                    }
                }
                
                // Action Buttons
                HStack(spacing: 10) {
                    let unpausedDaemons = state.daemons.filter { !$0.isPaused }
                    
                    if !unpausedDaemons.isEmpty {
                        Button(action: {
                            pauseAllSyncDaemons()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pause.fill")
                                Text("Pausar Sincronizadores en Batería")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(Color.liquidAmber)
                            .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Sincronizadores congelados (0.0% CPU / 0 W)")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(Color.liquidEmerald)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.liquidEmerald.opacity(0.18))
                        .clipShape(Capsule())
                    }
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.25)) {
                            showExclusionRules.toggle()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "slider.horizontal.3")
                            Text(showExclusionRules ? "Ocultar Reglas" : "Reglas de Exclusión")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color.liquidCyan)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.liquidCyan.opacity(0.12))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.liquidCyan.opacity(0.3), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.25)) {
                            showArchitectureAdvice.toggle()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "folder.badge.questionmark")
                            Text("Mejor Práctica de Carpetas")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "C4B5E0"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.25)) {
                            showOtherProcessesAdvice.toggle()
                        }
                    }) {
                        HStack(spacing: 5) {
                            Image(systemName: "cpu")
                            Text("Otros Procesos")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(Color(hex: "C4B5E0"))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.white.opacity(0.06))
                        .clipShape(Capsule())
                        .overlay(Capsule().strokeBorder(Color.white.opacity(0.15), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                }
                
                // Feedback Banner
                if let msg = actionMessage {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.seal.fill").foregroundColor(Color.liquidEmerald)
                        Text(msg).font(.system(size: 11, weight: .bold)).foregroundColor(.white)
                    }
                    .padding(.horizontal, 10).padding(.vertical, 5)
                    .background(Color.liquidEmerald.opacity(0.25)).clipShape(RoundedRectangle(cornerRadius: 6))
                }
                
                // SECTION 1: Exclusion Rules Sheet
                if showExclusionRules {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reglas de Exclusión recomendadas para Synology Drive y Google Drive:")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(Color.liquidCyan)
                        
                        Text("Agrega estas carpetas a la lista negra en Preferencias > Reglas de sincronización:")
                            .font(.system(size: 10.5))
                            .foregroundColor(Color.textSecondary)
                        
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                            exclusionPill("**/node_modules/**", desc: "Dependencias de Node.js / NPM")
                            exclusionPill("**/.git/**", desc: "Historial y ramas locales de Git")
                            exclusionPill("**/build/** & **/dist/**", desc: "Archivos de compilación temporal")
                            exclusionPill("**/.venv/** & **/__pycache__/**", desc: "Entornos virtuales de Python")
                            exclusionPill("**/DerivedData/**", desc: "Cachés de compilación de Xcode")
                            exclusionPill("**/target/**", desc: "Compilaciones de Rust / Cargo")
                        }
                    }
                    .padding(12)
                    .background(Color(hex: "100624"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.liquidCyan.opacity(0.25), lineWidth: 1))
                }
                
                // SECTION 2: Architecture Recommendation
                if showArchitectureAdvice {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill").foregroundColor(Color.liquidAmber)
                            Text("Estrategia de Almacenamiento Profesional:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("1. **Código fuente en ruta local:** Mueve tus proyectos a `~/Developer` o `~/Proyectos_Local` fuera de la sincronización en la nube.\n2. **Usa Git para el respaldo de proyectos:** GitHub, GitLab o Bitbucket sincronizan deltas limpios sólo cuando haces 'git push', sin mantener hilos despiertos en segundo plano.\n3. **Reserva Google Drive / Synology para estáticos:** Sincroniza únicamente PDFs, fotos, documentos de texto y entregables finales que no cambien miles de veces por minuto.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "E0D4F7"))
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(Color(hex: "100624"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.liquidAmber.opacity(0.25), lineWidth: 1))
                }
                
                // SECTION 3: Other impacted daemons
                if showOtherProcessesAdvice {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "gearshape.2.fill").foregroundColor(Color.liquidPink)
                            Text("Otros procesos que comen batería con carpetas de proyectos:")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        }
                        Text("• **mds y mds_stores (Spotlight):** Indexa cada archivo de 'node_modules'. Solución: Añade tu carpeta de proyectos a 'Privacidad de Spotlight' en Ajustes de macOS.\n• **fileproviderd:** Coordinador de Apple que se atasca si hay más de 50,000 microarchivos. Pausarlo con Battery Scope restablece el reposo del sistema.\n• **Docker Desktop:** Si tiene montadas carpetas de sincronización compartidas, multiplica el consumo por 3. Mantenlo apagado cuando no lo uses.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(hex: "E0D4F7"))
                            .lineSpacing(2)
                    }
                    .padding(12)
                    .background(Color(hex: "100624"))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.liquidPink.opacity(0.25), lineWidth: 1))
                }
            }
            .padding(16)
            .liquidGlassCard(cornerRadius: 16)
        }
    }
    
    private func exclusionPill(_ rule: String, desc: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "nosign")
                .foregroundColor(Color.liquidPink)
                .font(.system(size: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text(rule)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                Text(desc)
                    .font(.system(size: 9))
                    .foregroundColor(Color.textSecondary)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(Color.white.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }
    
    private func pauseAllSyncDaemons() {
        var count = 0
        for daemon in state.daemons where !daemon.isPaused {
            if let appUsage = service.topApps.first(where: { $0.pid == daemon.pid }) {
                service.pauseProcess(app: appUsage)
                count += 1
            }
        }
        actionMessage = "¡Se pausaron \(count) procesos de sincronización! Batería protegida."
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            actionMessage = nil
        }
    }
}
