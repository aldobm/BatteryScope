import Foundation
import AppKit
import SwiftUI

public enum StartupImpact: String, CaseIterable, Codable {
    case high = "Alto impacto"
    case medium = "Medio impacto"
    case low = "Bajo impacto"
    
    public var badgeColor: Color {
        switch self {
        case .high: return Color(hex: "FF3B30")
        case .medium: return Color(hex: "FF9F0A")
        case .low: return Color(hex: "00F5D4")
        }
    }
    
    public var iconName: String {
        switch self {
        case .high: return "flame.fill"
        case .medium: return "gauge.medium"
        case .low: return "bolt.shield.fill"
        }
    }
}

public enum StartupSourceType: String, CaseIterable, Codable {
    case loginItem = "Ítem de Inicio de Sesión"
    case userLaunchAgent = "Agente de Usuario"
    case systemLaunchAgent = "Agente del Sistema"
    
    public var description: String {
        switch self {
        case .loginItem: return "Se abre automáticamente al iniciar sesión en tu cuenta"
        case .userLaunchAgent: return "Servicio en segundo plano configurado en ~/Library/LaunchAgents"
        case .systemLaunchAgent: return "Servicio del sistema configurado en /Library/LaunchAgents"
        }
    }
}

public struct StartupAppItem: Identifiable {
    public let id: String
    public let name: String
    public let path: String
    public let bundleId: String
    public let sourceType: StartupSourceType
    public var isEnabled: Bool
    public let impact: StartupImpact
    public let estimatedDelaySeconds: Double
    public var memoryMB: Double
    public let descriptionText: String
    public let whySlowsDown: String
    public let recommendation: String
    public let isSafeToDisable: Bool
    public var icon: NSImage?
    public var isRunningNow: Bool
    public let plistFiles: [String]
    
    public var formattedDelay: String {
        String(format: "+%.1f s", estimatedDelaySeconds)
    }
    
    public var formattedMemory: String {
        if memoryMB > 0 {
            return String(format: "%.0f MB RAM", memoryMB)
        }
        return "En reposo"
    }
}

public class StartupAppsService: ObservableObject {
    public static let shared = StartupAppsService()
    
    @Published public var items: [StartupAppItem] = []
    @Published public var isLoading: Bool = false
    @Published public var lastScanDate: Date = Date()
    @Published public var statusMessage: String? = nil
    
    // Summary metrics
    @Published public var totalActiveCount: Int = 0
    @Published public var totalEstimatedDelay: Double = 0.0
    @Published public var potentialDelaySavings: Double = 0.0
    @Published public var highImpactCount: Int = 0
    
    private let disabledCacheURL: URL = {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("BatteryPulse", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("disabled_startup_items.json")
    }()
    
    public init() {
        scanStartupItems()
    }
    
    // MARK: - Scanning Logic
    public func scanStartupItems() {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async { self.isLoading = true }
            
            let disabledCache = self.loadDisabledCache()
            var detectedItems: [StartupAppItem] = []
            let processMemoryMap = self.fetchProcessMemoryMap()
            
            // 1. Scan Login Items via AppleScript
            let loginItems = self.fetchLoginItems()
            for (name, path) in loginItems {
                let isCachedDisabled = disabledCache.contains(where: { $0.name == name && $0.type == "loginItem" })
                let isEnabled = !isCachedDisabled
                let memory = processMemoryMap[name.lowercased()] ?? self.findMemoryByKeywords(name, map: processMemoryMap)
                let item = self.createStartupItem(
                    name: name,
                    path: path,
                    sourceType: .loginItem,
                    isEnabled: isEnabled,
                    memoryMB: memory,
                    plistFiles: []
                )
                detectedItems.append(item)
            }
            
            // Add any previously disabled login items from cache if not currently in System Events
            for cached in disabledCache where cached.type == "loginItem" {
                if !detectedItems.contains(where: { $0.name == cached.name }) {
                    let memory = processMemoryMap[cached.name.lowercased()] ?? 0.0
                    let item = self.createStartupItem(
                        name: cached.name,
                        path: cached.path,
                        sourceType: .loginItem,
                        isEnabled: false,
                        memoryMB: memory,
                        plistFiles: []
                    )
                    detectedItems.append(item)
                }
            }
            
            // 2. Scan User LaunchAgents (~/Library/LaunchAgents)
            let userAgents = self.scanLaunchAgentsDirectory(
                path: NSHomeDirectory() + "/Library/LaunchAgents",
                sourceType: .userLaunchAgent,
                disabledCache: disabledCache,
                processMemoryMap: processMemoryMap
            )
            detectedItems.append(contentsOf: userAgents)
            
            // 3. Scan System LaunchAgents (/Library/LaunchAgents)
            let systemAgents = self.scanLaunchAgentsDirectory(
                path: "/Library/LaunchAgents",
                sourceType: .systemLaunchAgent,
                disabledCache: disabledCache,
                processMemoryMap: processMemoryMap
            )
            detectedItems.append(contentsOf: systemAgents)
            
            // Deduplicate items with similar names (e.g. grouped services)
            let consolidated = self.consolidateItems(detectedItems)
            
            // Sort by impact (high -> medium -> low), then by enabled status
            let sorted = consolidated.sorted { (a, b) -> Bool in
                if a.isEnabled != b.isEnabled {
                    return a.isEnabled && !b.isEnabled
                }
                if a.impact != b.impact {
                    let rank: (StartupImpact) -> Int = {
                        switch $0 {
                        case .high: return 3
                        case .medium: return 2
                        case .low: return 1
                        }
                    }
                    return rank(a.impact) > rank(b.impact)
                }
                return a.estimatedDelaySeconds > b.estimatedDelaySeconds
            }
            
            let activeItems = sorted.filter { $0.isEnabled }
            let totalDelay = activeItems.reduce(0.0) { $0 + $1.estimatedDelaySeconds }
            let highCount = activeItems.filter { $0.impact == .high }.count
            let savable = activeItems.filter { $0.impact == .high || $0.impact == .medium }
                .reduce(0.0) { $0 + $1.estimatedDelaySeconds }
            
            DispatchQueue.main.async {
                self.items = sorted
                self.totalActiveCount = activeItems.count
                self.totalEstimatedDelay = totalDelay
                self.highImpactCount = highCount
                self.potentialDelaySavings = savable
                self.lastScanDate = Date()
                self.isLoading = false
            }
        }
    }
    
    // MARK: - Toggle Enable / Disable
    public func toggleItem(_ item: StartupAppItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        let newStatus = !item.isEnabled
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            switch item.sourceType {
            case .loginItem:
                if newStatus {
                    // Enable Login Item
                    _ = self.addLoginItem(name: item.name, path: item.path)
                    self.removeFromDisabledCache(name: item.name, type: "loginItem")
                } else {
                    // Disable Login Item
                    _ = self.removeLoginItem(name: item.name)
                    self.addToDisabledCache(name: item.name, path: item.path, type: "loginItem")
                }
                
            case .userLaunchAgent, .systemLaunchAgent:
                if newStatus {
                    _ = self.toggleLaunchAgentFiles(item: item, enable: true)
                    self.removeFromDisabledCache(name: item.name, type: "launchAgent")
                } else {
                    _ = self.toggleLaunchAgentFiles(item: item, enable: false)
                    self.addToDisabledCache(name: item.name, path: item.path, type: "launchAgent")
                }
            }
            
            DispatchQueue.main.async {
                self.items[index].isEnabled = newStatus
                self.recomputeMetrics()
                let action = newStatus ? "activada" : "desactivada"
                self.statusMessage = "\(item.name) \(action) al inicio"
            }
        }
    }
    
    public func disableAllHighImpact() {
        for item in items where item.isEnabled && item.impact == .high && item.isSafeToDisable {
            toggleItem(item)
        }
    }
    
    public func openInFinder(path: String) {
        let fileManager = FileManager.default
        var targetPath = path
        if !fileManager.fileExists(atPath: targetPath) {
            if let parent = URL(string: targetPath)?.deletingLastPathComponent().path,
               fileManager.fileExists(atPath: parent) {
                targetPath = parent
            }
        }
        NSWorkspace.shared.selectFile(targetPath, inFileViewerRootedAtPath: "")
    }
    
    // MARK: - Helper Methods
    private func recomputeMetrics() {
        let activeItems = items.filter { $0.isEnabled }
        totalActiveCount = activeItems.count
        totalEstimatedDelay = activeItems.reduce(0.0) { $0 + $1.estimatedDelaySeconds }
        highImpactCount = activeItems.filter { $0.impact == .high }.count
        potentialDelaySavings = activeItems.filter { $0.impact == .high || $0.impact == .medium }
            .reduce(0.0) { $0 + $1.estimatedDelaySeconds }
    }
    
    private func fetchLoginItems() -> [(String, String)] {
        let script = """
        tell application "System Events"
            set outText to ""
            try
                repeat with anItem in login items
                    set n to name of anItem
                    set p to path of anItem
                    set outText to outText & n & "|||" & p & linefeed
                end repeat
            end try
            return outText
        end tell
        """
        var result: [(String, String)] = []
        if let scriptObj = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            let output = scriptObj.executeAndReturnError(&errorInfo)
            if let text = output.stringValue {
                let lines = text.components(separatedBy: .newlines)
                for line in lines where line.contains("|||") {
                    let parts = line.components(separatedBy: "|||")
                    if parts.count >= 2 {
                        let name = parts[0].trimmingCharacters(in: .whitespaces)
                        let path = parts[1].trimmingCharacters(in: .whitespaces)
                        if !name.isEmpty {
                            result.append((name, path))
                        }
                    }
                }
            }
        }
        return result
    }
    
    private func addLoginItem(name: String, path: String) -> Bool {
        let cleanPath = path.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "System Events"
            make new login item at end with properties {path:"\(cleanPath)", hidden:false}
        end tell
        """
        if let scriptObj = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            scriptObj.executeAndReturnError(&errorInfo)
            return errorInfo == nil
        }
        return false
    }
    
    private func removeLoginItem(name: String) -> Bool {
        let cleanName = name.replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "System Events"
            delete login item "\(cleanName)"
        end tell
        """
        if let scriptObj = NSAppleScript(source: script) {
            var errorInfo: NSDictionary?
            scriptObj.executeAndReturnError(&errorInfo)
            return errorInfo == nil
        }
        return false
    }
    
    private func toggleLaunchAgentFiles(item: StartupAppItem, enable: Bool) -> Bool {
        let fileManager = FileManager.default
        let uid = getuid()
        
        // 1. Tell launchctl to disable/enable the service for this user session
        if enable {
            _ = runShell("launchctl enable gui/\(uid)/\(item.bundleId) 2>/dev/null")
        } else {
            _ = runShell("launchctl disable gui/\(uid)/\(item.bundleId) 2>/dev/null")
            _ = runShell("launchctl bootout gui/\(uid)/\(item.bundleId) 2>/dev/null")
        }
        
        // 2. Rename any writable plist files (e.g. in ~/Library/LaunchAgents)
        for file in item.plistFiles {
            let activePath = file.hasSuffix(".disabled") ? String(file.dropLast(9)) : file
            let disabledPath = activePath + ".disabled"
            
            let src = enable ? disabledPath : activePath
            let dst = enable ? activePath : disabledPath
            
            if fileManager.fileExists(atPath: src) {
                if fileManager.isWritableFile(atPath: src) || fileManager.isWritableFile(atPath: (src as NSString).deletingLastPathComponent) {
                    do {
                        try fileManager.moveItem(atPath: src, toPath: dst)
                        if enable {
                            _ = runShell("launchctl bootstrap gui/\(uid) '\(dst)' 2>/dev/null || launchctl load '\(dst)' 2>/dev/null")
                        } else {
                            _ = runShell("launchctl bootout gui/\(uid) '\(src)' 2>/dev/null || launchctl unload '\(src)' 2>/dev/null")
                        }
                    } catch {}
                }
            }
        }
        return true
    }
    
    private func scanLaunchAgentsDirectory(
        path: String,
        sourceType: StartupSourceType,
        disabledCache: [DisabledItemCache],
        processMemoryMap: [String: Double]
    ) -> [StartupAppItem] {
        let fm = FileManager.default
        guard let files = try? fm.contentsOfDirectory(atPath: path) else { return [] }
        
        var result: [StartupAppItem] = []
        
        for file in files {
            guard file.hasSuffix(".plist") || file.hasSuffix(".plist.disabled") else { continue }
            let fullPath = (path as NSString).appendingPathComponent(file)
            let isCurrentlyDisabled = file.hasSuffix(".disabled")
            
            // Read plist dictionary
            guard let dict = NSDictionary(contentsOfFile: fullPath) as? [String: Any] else {
                continue
            }
            
            // Skip empty plists (like empty keystone stubs with no keys or programs)
            if dict.isEmpty { continue }
            
            let label = dict["Label"] as? String ?? file
            
            // Skip core Apple internal launch agents
            if label.starts(with: "com.apple.") { continue }
            
            // Extract program or arguments
            var targetAppPath = ""
            if let prog = dict["Program"] as? String {
                targetAppPath = prog
            } else if let args = dict["ProgramArguments"] as? [String], let first = args.first {
                if first == "/usr/bin/open" && args.count > 1 {
                    targetAppPath = args[1]
                } else {
                    targetAppPath = first
                }
            }
            
            let friendlyName = self.friendlyNameFor(label: label, appPath: targetAppPath)
            let memory = processMemoryMap[friendlyName.lowercased()] ?? self.findMemoryByKeywords(friendlyName, map: processMemoryMap)
            
            let isCachedDisabled = disabledCache.contains(where: {
                $0.name.lowercased() == friendlyName.lowercased() ||
                $0.path.lowercased() == fullPath.lowercased()
            })
            
            let item = self.createStartupItem(
                name: friendlyName,
                path: targetAppPath.isEmpty ? fullPath : targetAppPath,
                sourceType: sourceType,
                isEnabled: !isCurrentlyDisabled && !isCachedDisabled,
                memoryMB: memory,
                plistFiles: [fullPath],
                customBundleId: label
            )
            result.append(item)
        }
        
        return result
    }
    
    private func consolidateItems(_ items: [StartupAppItem]) -> [StartupAppItem] {
        var map: [String: StartupAppItem] = [:]
        
        for item in items {
            let key = item.name.lowercased()
            if let existing = map[key] {
                // Merge plist files
                var mergedPlists = existing.plistFiles
                for p in item.plistFiles where !mergedPlists.contains(p) {
                    mergedPlists.append(p)
                }
                // Highest delay & memory
                let newDelay = max(existing.estimatedDelaySeconds, item.estimatedDelaySeconds)
                let newMem = max(existing.memoryMB, item.memoryMB)
                // If either has been disabled, keep it disabled
                let isEnabled = existing.isEnabled && item.isEnabled
                
                map[key] = StartupAppItem(
                    id: existing.id,
                    name: existing.name,
                    path: existing.path,
                    bundleId: existing.bundleId,
                    sourceType: existing.sourceType,
                    isEnabled: isEnabled,
                    impact: existing.impact,
                    estimatedDelaySeconds: newDelay,
                    memoryMB: newMem,
                    descriptionText: existing.descriptionText,
                    whySlowsDown: existing.whySlowsDown,
                    recommendation: existing.recommendation,
                    isSafeToDisable: existing.isSafeToDisable,
                    icon: existing.icon ?? item.icon,
                    isRunningNow: existing.isRunningNow || item.isRunningNow,
                    plistFiles: mergedPlists
                )
            } else {
                map[key] = item
            }
        }
        
        return Array(map.values)
    }
    
    private func friendlyNameFor(label: String, appPath: String) -> String {
        let lower = label.lowercased()
        if lower.contains("synologydrive") || lower.contains("synology.drive") {
            return "Synology Drive Client"
        }
        if lower.contains("synologyimageassistant") {
            return "Synology Image Assistant"
        }
        if lower.contains("forti") {
            return "FortiClient Agent (VPN)"
        }
        if lower.contains("onedrive") || lower.contains("syncreporter") {
            return "Microsoft OneDrive"
        }
        if lower.contains("microsoft.update") || lower.contains("mau") {
            return "Microsoft AutoUpdate"
        }
        if lower.contains("cleanmymac") {
            return "CleanMyMac X Updater"
        }
        if lower.contains("googleupdater") || lower.contains("keystone") {
            return "Google Updater"
        }
        if lower.contains("teamviewer") {
            return "TeamViewer"
        }
        if lower.contains("tuxera") {
            return "Tuxera NTFS Agent"
        }
        if lower.contains("termius") {
            return "Termius Helper"
        }
        if lower.contains("spotify") {
            return "Spotify"
        }
        if lower.contains("discord") {
            return "Discord"
        }
        if lower.contains("docker") {
            return "Docker Desktop"
        }
        if lower.contains("steam") {
            return "Steam"
        }
        
        // Extract from bundle path
        if appPath.contains(".app") {
            let components = appPath.components(separatedBy: "/")
            for comp in components.reversed() where comp.hasSuffix(".app") {
                return String(comp.dropLast(4))
            }
        }
        
        // Fallback to cleaner label
        let parts = label.components(separatedBy: ".")
        if let last = parts.last, !last.isEmpty {
            return last.capitalized
        }
        return label
    }
    
    private func createStartupItem(
        name: String,
        path: String,
        sourceType: StartupSourceType,
        isEnabled: Bool,
        memoryMB: Double,
        plistFiles: [String],
        customBundleId: String? = nil
    ) -> StartupAppItem {
        let lower = name.lowercased()
        
        var impact: StartupImpact = .medium
        var delay: Double = 1.0
        var desc = "Aplicación configurada para iniciar automáticamente con tu Mac."
        var why = "Consume ciclos de CPU y lectura de disco al encender el Mac, compitiendo con el escritorio."
        var reco = "Puedes desactivarla al inicio para un encendido más rápido y abrirla solo cuando la uses."
        var safe = true
        var bundleId = customBundleId ?? "com.unknown.\(name.lowercased().replacingOccurrences(of: " ", with: ""))"
        
        if lower.contains("synology drive") {
            impact = .high
            delay = 2.8
            desc = "Cliente de sincronización de carpetas de tu servidor NAS Synology."
            why = "Inicia 4 demonios en segundo plano, realiza un escaneo masivo del disco y mantiene conexiones de red activas desde el primer segundo."
            reco = "Altamente recomendable desactivar al inicio si no necesitas sincronizar archivos inmediatamente al encender el Mac. Ahorra casi 3 segundos de arranque."
            safe = true
            bundleId = "com.synology.SynologyDrive"
        } else if lower.contains("google drive") {
            impact = .high
            delay = 2.6
            desc = "Unidad virtual y sincronizador en la nube de Google Workspace."
            why = "Carga su entorno en segundo plano, monta el volumen virtual de disco y verifica tokens de seguridad en red, retrasando la fluidez del escritorio."
            reco = "Seguro de desactivar al inicio. Puedes abrir Google Drive desde Spotlight o Aplicaciones cuando vayas a trabajar con tus documentos."
            safe = true
            bundleId = "com.google.drivefs"
        } else if lower.contains("forticlient") || lower.contains("forti") {
            impact = .high
            delay = 2.4
            desc = "Suite de seguridad corporativa y cliente VPN de Fortinet."
            why = "Inicializa controladores de red, servicio de túnel y monitores de credenciales en el arranque de sesión."
            reco = "Si solo usas la VPN para conectarte ocasionalmente a la oficina, puedes desactivar su arranque automático y abrirlo cuando necesites la VPN."
            safe = true
            bundleId = "com.fortinet.forticlient"
        } else if lower.contains("onedrive") {
            impact = .high
            delay = 2.1
            desc = "Cliente de almacenamiento en la nube de Microsoft."
            why = "Verifica carpetas locales contra OneDrive e inicializa extensiones de Finder que cargan librerías al inicio."
            reco = "Seguro de desactivar si no necesitas sincronización inmediata al arrancar. Puedes abrir OneDrive cuando lo desees."
            safe = true
            bundleId = "com.microsoft.OneDrive"
        } else if lower.contains("teamviewer") {
            impact = .high
            delay = 1.8
            desc = "Herramienta de soporte y control remoto en red."
            why = "Levanta un servicio de escucha de red continuo y consume memoria reservada en segundo plano."
            reco = "Recomendable desactivar si no requieres que otras personas se conecten a tu Mac sin que tú estés presente."
            safe = true
            bundleId = "com.teamviewer.TeamViewer"
        } else if lower.contains("tuxera") {
            impact = .medium
            delay = 0.8
            desc = "Controlador para lectura y escritura en discos NTFS de Windows."
            why = "Carga un menú en la barra superior para supervisar volúmenes NTFS montados."
            reco = "Si usas discos externos NTFS a diario puedes dejarlo activo; si es esporádico, desactivarlo agiliza el inicio."
            safe = true
            bundleId = "com.tuxera.ntfs"
        } else if lower.contains("synology image assistant") {
            impact = .medium
            delay = 1.1
            desc = "Asistente de generación y conversión de miniaturas multimedia para Synology Photos."
            why = "Ejecuta un script al inicio para detectar bibliotecas de fotos."
            reco = "Seguro de desactivar. Solo se requiere al importar fotografías pesadas hacia el NAS."
            safe = true
            bundleId = "com.synology.SynologyImageAssistant"
        } else if lower.contains("microsoft autoupdate") || lower.contains("mau") {
            impact = .medium
            delay = 0.7
            desc = "Buscador de actualizaciones para Microsoft 365 / Office."
            why = "Consulta los servidores de Microsoft periódicamente y tras el inicio."
            reco = "Puedes desactivarlo al inicio. Word y Excel se pueden actualizar manualmente desde su menú Ayuda > Buscar actualizaciones."
            safe = true
            bundleId = "com.microsoft.autoupdate"
        } else if lower.contains("cleanmymac") {
            impact = .low
            delay = 0.4
            desc = "Actualizador y monitor de mantenimiento en segundo plano."
            why = "Comprueba el estado de la aplicación CleanMyMac X."
            reco = "Bajo impacto. Seguro de mantener o desactivar si prefieres actualizar manualmente."
            safe = true
            bundleId = "com.macpaw.CleanMyMac4"
        } else if lower.contains("google updater") || lower.contains("keystone") {
            impact = .low
            delay = 0.4
            desc = "Servicio de actualización silenciosa de Google Chrome y componentes."
            why = "Verifica periódicamente firmas y versiones de navegadores Google."
            reco = "Bajo impacto en tiempo. Seguro de mantener o desactivar."
            safe = true
            bundleId = "com.google.keystone"
        } else if lower.contains("app tamer") {
            impact = .low
            delay = 0.3
            desc = "Optimizador de CPU que frena apps ociosas para ahorrar batería."
            why = "Utilidad muy liviana optimizada en código nativo para macOS."
            reco = "Es útil mantenerlo activo si te ayuda a controlar el consumo de batería del Mac."
            safe = false
            bundleId = "com.stclairsoft.AppTamer"
        }
        
        let icon = self.findAppIcon(name: name, path: path)
        let isRunning = (memoryMB > 0)
        
        return StartupAppItem(
            id: "\(name)_\(sourceType.rawValue)",
            name: name,
            path: path,
            bundleId: bundleId,
            sourceType: sourceType,
            isEnabled: isEnabled,
            impact: impact,
            estimatedDelaySeconds: delay,
            memoryMB: memoryMB,
            descriptionText: desc,
            whySlowsDown: why,
            recommendation: reco,
            isSafeToDisable: safe,
            icon: icon,
            isRunningNow: isRunning,
            plistFiles: plistFiles
        )
    }
    
    private func findAppIcon(name: String, path: String) -> NSImage? {
        let fileManager = FileManager.default
        
        let lowerName = name.lowercased()
        if lowerName.contains("google updater") || lowerName.contains("google") {
            let chromeApp = "/Applications/Google Chrome.app"
            if fileManager.fileExists(atPath: chromeApp) {
                return NSWorkspace.shared.icon(forFile: chromeApp)
            }
        }
        
        // 1. Direct path exists and is an app or file
        if !path.isEmpty && fileManager.fileExists(atPath: path) {
            if path.contains(".app") {
                let components = path.components(separatedBy: "/")
                var appPathAcc = ""
                for part in components {
                    if !part.isEmpty {
                        appPathAcc += "/" + part
                    }
                    if part.hasSuffix(".app") {
                        return NSWorkspace.shared.icon(forFile: appPathAcc)
                    }
                }
            }
            return NSWorkspace.shared.icon(forFile: path)
        }
        
        // 2. Check in /Applications or ~/Applications by name
        let candidateApps = [
            "/Applications/\(name).app",
            "/Applications/\(name) Client.app",
            "/Applications/\(name) Desktop.app",
            "\(NSHomeDirectory())/Applications/\(name).app",
            "/Applications/Google Drive.app",
            "/Applications/Synology Drive Client.app",
            "/Applications/FortiClient.app",
            "/Applications/OneDrive.app",
            "/Applications/TeamViewer.app",
            "/Applications/App Tamer.app"
        ]
        
        for cand in candidateApps {
            if fileManager.fileExists(atPath: cand) {
                let candLower = cand.lowercased()
                let nameLower = name.lowercased()
                if candLower.contains("synology") && nameLower.contains("synology") {
                    return NSWorkspace.shared.icon(forFile: cand)
                }
                if candLower.contains("google drive") && nameLower.contains("google") {
                    return NSWorkspace.shared.icon(forFile: cand)
                }
                if candLower.contains("forti") && nameLower.contains("forti") {
                    return NSWorkspace.shared.icon(forFile: cand)
                }
                if candLower.contains("onedrive") && nameLower.contains("onedrive") {
                    return NSWorkspace.shared.icon(forFile: cand)
                }
                if candLower.contains("teamviewer") && nameLower.contains("teamviewer") {
                    return NSWorkspace.shared.icon(forFile: cand)
                }
                if candLower.contains("app tamer") && nameLower.contains("app tamer") {
                    return NSWorkspace.shared.icon(forFile: cand)
                }
            }
        }
        
        // 3. System generic app icon fallback
        let defaultApp = "/System/Applications/Utilities/Terminal.app"
        if fileManager.fileExists(atPath: defaultApp) {
            return NSWorkspace.shared.icon(forFile: defaultApp)
        }
        return nil
    }
    
    private func fetchProcessMemoryMap() -> [String: Double] {
        var map: [String: Double] = [:]
        let output = runShell("ps -eo rss,comm")
        let lines = output.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            let parts = trimmed.split(separator: " ", maxSplits: 1, omittingEmptySubsequences: true)
            if parts.count == 2, let rssKB = Double(parts[0]) {
                let fullComm = String(parts[1])
                let comm = (fullComm as NSString).lastPathComponent.lowercased()
                let mb = rssKB / 1024.0
                map[comm] = (map[comm] ?? 0.0) + mb
                
                // Also map full path keywords
                let fullLower = fullComm.lowercased()
                if fullLower.contains("synology") {
                    map["synology drive client"] = (map["synology drive client"] ?? 0.0) + mb
                } else if fullLower.contains("google drive") {
                    map["google drive"] = (map["google drive"] ?? 0.0) + mb
                } else if fullLower.contains("forti") {
                    map["forticlient agent (vpn)"] = (map["forticlient agent (vpn)"] ?? 0.0) + mb
                } else if fullLower.contains("onedrive") {
                    map["microsoft onedrive"] = (map["microsoft onedrive"] ?? 0.0) + mb
                } else if fullLower.contains("app tamer") {
                    map["app tamer"] = (map["app tamer"] ?? 0.0) + mb
                }
            }
        }
        return map
    }
    
    private func findMemoryByKeywords(_ name: String, map: [String: Double]) -> Double {
        let lower = name.lowercased()
        for (key, val) in map {
            if lower.contains(key) || key.contains(lower) {
                return val
            }
        }
        return 0.0
    }
    
    // MARK: - Local Cache of Disabled Items
    private struct DisabledItemCache: Codable {
        let name: String
        let path: String
        let type: String
    }
    
    private func loadDisabledCache() -> [DisabledItemCache] {
        guard let data = try? Data(contentsOf: disabledCacheURL),
              let list = try? JSONDecoder().decode([DisabledItemCache].self, from: data) else {
            return []
        }
        return list
    }
    
    private func addToDisabledCache(name: String, path: String, type: String) {
        var current = loadDisabledCache()
        current.removeAll(where: { $0.name == name && $0.type == type })
        current.append(DisabledItemCache(name: name, path: path, type: type))
        if let data = try? JSONEncoder().encode(current) {
            try? data.write(to: disabledCacheURL)
        }
    }
    
    private func removeFromDisabledCache(name: String, type: String) {
        var current = loadDisabledCache()
        current.removeAll(where: { $0.name == name && $0.type == type })
        if let data = try? JSONEncoder().encode(current) {
            try? data.write(to: disabledCacheURL)
        }
    }
    
    private func runShell(_ command: String) -> String {
        let task = Process()
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        do {
            try task.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            task.waitUntilExit()
            return String(data: data, encoding: .utf8) ?? ""
        } catch {
            return ""
        }
    }
}
