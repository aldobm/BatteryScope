import Foundation

public enum ExplanationField {
    case friendlyTitle
    case description
    case whyActive
    case whatToDo
    case category
}

public struct ProcessExplanation: Equatable {
    public let name: String
    public let isSystem: Bool
    public let safeToStop: Bool
    public let canPause: Bool
    
    public let rawFriendlyTitle: String
    public let rawDescription: String
    public let rawWhyActive: String
    public let rawWhatToDo: String
    public let rawCategory: String
    
    public init(
        name: String,
        friendlyTitle: String,
        description: String,
        whyActive: String,
        whatToDo: String,
        category: String,
        isSystem: Bool,
        safeToStop: Bool,
        canPause: Bool
    ) {
        self.name = name
        self.rawFriendlyTitle = friendlyTitle
        self.rawDescription = description
        self.rawWhyActive = whyActive
        self.rawWhatToDo = whatToDo
        self.rawCategory = category
        self.isSystem = isSystem
        self.safeToStop = safeToStop
        self.canPause = canPause
    }
    
    public var friendlyTitle: String {
        ProcessDatabase.shared.getLocalizedField(process: name, field: .friendlyTitle, fallback: rawFriendlyTitle)
    }
    
    public var description: String {
        ProcessDatabase.shared.getLocalizedField(process: name, field: .description, fallback: rawDescription)
    }
    
    public var whyActive: String {
        ProcessDatabase.shared.getLocalizedField(process: name, field: .whyActive, fallback: rawWhyActive)
    }
    
    public var whatToDo: String {
        ProcessDatabase.shared.getLocalizedField(process: name, field: .whatToDo, fallback: rawWhatToDo)
    }
    
    public var category: String {
        ProcessDatabase.shared.getLocalizedField(process: name, field: .category, fallback: rawCategory)
    }
}

public class ProcessDatabase {
    public static let shared = ProcessDatabase()
    
    // MARK: - English Translations Dictionary
    private let englishTranslations: [String: [ExplanationField: String]] = [
        "fileproviderd": [
            .friendlyTitle: "Cloud FileProvider Engine",
            .description: "macOS core service coordinating file sync operations for Google Drive, Synology, Dropbox, iCloud, and OneDrive.",
            .whyActive: "Detects continuous disk events (FSEvents). Heavy build folders ('node_modules', '.git') cause it to parse thousands of temporary files.",
            .whatToDo: "Exclude code repositories in your cloud sync clients or move projects to a local path (~/Developer). You can pause this process on battery.",
            .category: "Cloud Storage"
        ],
        "mDNSResponder": [
            .friendlyTitle: "Bonjour Network Service",
            .description: "Core macOS network daemon maintaining active Wi-Fi connection and resolving local Bonjour network names.",
            .whyActive: "Periodically activates during system sleep (DarkWake) to transmit maintenance packets and avoid network disconnections.",
            .whatToDo: "Essential Apple network process. To minimize nighttime wakeups, disable 'Wake for network access' in Battery Settings.",
            .category: "System Network"
        ],
        "apsd": [
            .friendlyTitle: "Apple Push Notifications (Power Nap)",
            .description: "Apple Push Notification service daemon for iCloud, Mail, Messages, and system alerts.",
            .whyActive: "Awakens the Mac during sleep to check for incoming emails, messages, or calendar alerts without powering on the screen.",
            .whatToDo: "Safe Apple service. To prevent battery drain overnight, turn on Focus / Do Not Disturb or disable Power Nap.",
            .category: "Push Notifications"
        ],
        "AddressBookSourceSync": [
            .friendlyTitle: "Contacts & Accounts Sync",
            .description: "macOS service synchronizing address books, contacts, and calendars across iCloud, Google, or Exchange accounts.",
            .whyActive: "Checks for changes in remote address books during maintenance sleep cycles.",
            .whatToDo: "Normal synchronization process. Requires no action unless you have accounts experiencing authentication errors.",
            .category: "Cloud Sync"
        ],
        "dasd": [
            .friendlyTitle: "Duet Activity Scheduler",
            .description: "Intelligent macOS scheduler that organizes background tasks during low-power periods.",
            .whyActive: "Evaluates idle sleep periods to execute system stability diagnostics, telemetry, and photo library caches.",
            .whatToDo: "Vital macOS kernel process designed to optimize battery life. Do not terminate.",
            .category: "macOS Kernel"
        ],
        "studentd": [
            .friendlyTitle: "Apple Education / Student Daemon",
            .description: "Support service for Apple Classroom and educational configuration profiles.",
            .whyActive: "Periodically checks device profiles and network certificates in the background.",
            .whatToDo: "If you do not use Apple Classroom or school profiles, it consumes negligible power outside brief checks.",
            .category: "macOS Services"
        ],
        "powerd": [
            .friendlyTitle: "macOS Power Manager",
            .description: "Core macOS service controlling system sleep, screen wakeup, DarkWake, and low-power timers.",
            .whyActive: "Monitors battery health, schedules periodic wakeups (Power Nap), and manages sleep state energy distribution.",
            .whatToDo: "Vital Apple process for power management and battery longevity. Cannot and should not be paused.",
            .category: "macOS Kernel"
        ],
        "cloudd": [
            .friendlyTitle: "iCloud Sync Daemon",
            .description: "Central sync engine for Apple iCloud Drive, Photos, Notes, Keychain, and Documents.",
            .whyActive: "Syncs files and metadata with Apple Cloud servers upon system wakeup or when local changes are detected.",
            .whatToDo: "Standard Apple service. If consuming continuously, check Finder to ensure no large files are stuck syncing in a loop.",
            .category: "Cloud Sync"
        ],
        "WindowServer": [
            .friendlyTitle: "Display Graphics Engine",
            .description: "Central graphics compositor for macOS. Draws all windows, 'Liquid' glass effects, visual animations, and external displays.",
            .whyActive: "High window density, active video streams, or high-refresh external monitors increase its GPU workload.",
            .whatToDo: "Minimize unused windows, close high-animation browser tabs, and slightly reduce screen brightness.",
            .category: "macOS Graphics"
        ],
        "cloud-drive-daemon": [
            .friendlyTitle: "Synology Drive Client Daemon",
            .description: "Continuous synchronization service for your local or remote Synology NAS.",
            .whyActive: "Scans and uploads disk changes. In folders containing repositories or development builds, it surges due to micro-files.",
            .whatToDo: "Pause Synology Drive with the 'Pause Process' button while on battery, and add 'node_modules' and '.git' to exclusion rules.",
            .category: "Cloud Sync"
        ],
        "cloud-drive-eventd": [
            .friendlyTitle: "Synology Drive Event Watcher",
            .description: "File system event monitor (FSEvents) for Synology Drive Client.",
            .whyActive: "Monitors file creation and edits in real-time across your workspace folders.",
            .whatToDo: "Pause this process while on battery to avoid waking the CPU on every code auto-save.",
            .category: "Cloud Sync"
        ],
        "cloud-drive-daem": [
            .friendlyTitle: "Synology Drive Subprocess",
            .description: "Disk analysis helper for Synology Drive Client.",
            .whyActive: "Scanning recent changes across synchronized folders.",
            .whatToDo: "Pause the process with the 'Pause' button to save between 1W and 3W of battery draw.",
            .category: "Cloud Sync"
        ],
        "SynologyDrive": [
            .friendlyTitle: "Synology Drive Client",
            .description: "File synchronization and backup application for Synology NAS.",
            .whyActive: "Maintaining active upload and download queues with the NAS server.",
            .whatToDo: "Pause synchronization while on battery or when working on projects with thousands of temporary files.",
            .category: "Cloud Storage"
        ],
        "Google Drive": [
            .friendlyTitle: "Google Drive App",
            .description: "Cloud streaming and mirroring client for Google Drive.",
            .whyActive: "Comparing local file hashes against Google Cloud. High drain when syncing developer folders.",
            .whatToDo: "Pause synchronization using the 'Pause Process' button or exclude build folders.",
            .category: "Cloud Storage"
        ],
        "GoogleDriveFS": [
            .friendlyTitle: "Google Drive File System Core",
            .description: "Low-level virtual file system driver for Google Drive.",
            .whyActive: "Transferring file metadata and caching directory changes.",
            .whatToDo: "Pause Google Drive while compiling code or executing automated test suites.",
            .category: "Cloud Storage"
        ],
        "firefox": [
            .friendlyTitle: "Mozilla Firefox Browser",
            .description: "Open source web browser.",
            .whyActive: "Active tabs running scripts, media playback, or active browser extensions.",
            .whatToDo: "Close inactive tabs running media or enable the browser tab power saving mode.",
            .category: "Web Browsing"
        ],
        "Firefox GPU Help": [
            .friendlyTitle: "Firefox GPU Acceleration",
            .description: "Subprocess handling WebGL and hardware-accelerated video on the Mac GPU.",
            .whyActive: "One or more tabs are rendering heavy media (YouTube, video streams, or 3D animations).",
            .whatToDo: "Close or hibernate tabs with background videos.",
            .category: "GPU Acceleration"
        ],
        "plugin-container": [
            .friendlyTitle: "Firefox Isolated Web Tab",
            .description: "Sandboxes individual Firefox tabs and extensions in separate processes.",
            .whyActive: "Continuous execution of scripts on complex web applications.",
            .whatToDo: "Identify high-drain tabs in the Firefox Task Manager and close them.",
            .category: "Web Browsing"
        ],
        "Safari": [
            .friendlyTitle: "Apple Safari Browser",
            .description: "Official Apple web browser optimized with energy-efficient WebKit architecture.",
            .whyActive: "Web pages open in active or background tabs.",
            .whatToDo: "Safari is highly energy efficient; close tabs that perform aggressive auto-refreshing.",
            .category: "Web Browsing"
        ],
        "com.apple.WebKit.WebContent": [
            .friendlyTitle: "Safari Web Tab Renderer",
            .description: "Rendering and execution engine for a specific Safari web tab.",
            .whyActive: "Web page executing JavaScript code or interactive media content.",
            .whatToDo: "Close the corresponding tab if you are no longer actively using it.",
            .category: "Web Browsing"
        ],
        "CleanMyMac X": [
            .friendlyTitle: "CleanMyMac X",
            .description: "System maintenance and optimization utility by MacPaw.",
            .whyActive: "Real-time resource monitoring and scheduled system scans.",
            .whatToDo: "To maximize battery lifespan, you can disable background scanning in its preferences.",
            .category: "Maintenance"
        ],
        "CleanMyMac X HealthMonitor": [
            .friendlyTitle: "CleanMyMac Monitor Agent",
            .description: "Resident agent monitoring system temperature, RAM, and disk health.",
            .whyActive: "Sampling Mac hardware sensors periodically in the background.",
            .whatToDo: "Pause or exit if you need to squeeze out every minute of battery runtime.",
            .category: "Maintenance"
        ],
        "Antigravity Help": [
            .friendlyTitle: "Antigravity Assistant Helper",
            .description: "Technical assistance and project compilation helper process.",
            .whyActive: "Compiling source code, processing data, or running local diagnostics.",
            .whatToDo: "Pause during breaks if you are not running resource-intensive builds.",
            .category: "Development"
        ],
        "Antigravity": [
            .friendlyTitle: "Antigravity Environment",
            .description: "Interactive coding and automation development environment.",
            .whyActive: "Active developer workspace session and live code analysis.",
            .whatToDo: "Allow to continue, or pause if you are away from your power adapter.",
            .category: "Development"
        ],
        "kernel_task": [
            .friendlyTitle: "macOS XNU Kernel",
            .description: "The core of macOS. Manages RAM memory, CPU dispatching, and thermal regulation.",
            .whyActive: "Regulating Apple Silicon chip temperature to preserve battery cell life.",
            .whatToDo: "Cannot be closed. Place your Mac on a hard, flat surface to aid passive heat dissipation.",
            .category: "System Kernel"
        ],
        "mds": [
            .friendlyTitle: "Spotlight Metadata Indexer",
            .description: "Background search indexer for fast file and email lookup across macOS.",
            .whyActive: "Analyzing newly downloaded or modified files to add them to Spotlight.",
            .whatToDo: "Wait for indexing to complete, or exclude bulky download folders in System Settings > Spotlight.",
            .category: "Search Indexing"
        ],
        "mds_stores": [
            .friendlyTitle: "Spotlight Index Store",
            .description: "Stores and optimizes searchable Spotlight index databases.",
            .whyActive: "Writing updated indices to SSD storage.",
            .whatToDo: "Allow it to finish writing for responsive subsequent searches.",
            .category: "Search Indexing"
        ],
        "corespotlightd": [
            .friendlyTitle: "CoreSpotlight Daemon",
            .description: "Indexes in-app contents such as Mail messages, Notes, and Contacts.",
            .whyActive: "Indexing new items after receiving emails or creating notes.",
            .whatToDo: "Typically subsides after a couple minutes of background indexing.",
            .category: "Search Indexing"
        ],
        "trustd": [
            .friendlyTitle: "SSL Certificate Validator",
            .description: "Validates code signatures of applications and establishes secure HTTPS connections.",
            .whyActive: "Verifying secure connections made by active apps.",
            .whatToDo: "Essential for macOS system security; no user action required.",
            .category: "Security"
        ],
        "syspolicyd": [
            .friendlyTitle: "Apple Gatekeeper Security",
            .description: "Analyzes application binaries before execution to block malware and unauthorized code.",
            .whyActive: "Verifying newly launched applications.",
            .whatToDo: "Essential for system integrity and malware protection.",
            .category: "Security"
        ],
        "coreaudiod": [
            .friendlyTitle: "macOS Core Audio Server",
            .description: "Controls internal speakers, AirPods, microphones, and audio hardware interfaces.",
            .whyActive: "An application has an active audio channel or microphone stream open.",
            .whatToDo: "Close conference apps (Zoom, Teams, Meet) after finishing calls to release audio hardware.",
            .category: "Multimedia"
        ],
        "bluetoothd": [
            .friendlyTitle: "Bluetooth Manager",
            .description: "Manages the Bluetooth controller and wireless links with keyboards, mice, and headphones.",
            .whyActive: "Maintaining low-latency wireless connection with paired peripheral devices.",
            .whatToDo: "If not using external wireless accessories on low battery, toggle Bluetooth off.",
            .category: "Connectivity"
        ],
        "bird": [
            .friendlyTitle: "iCloud Drive Document Daemon",
            .description: "Synchronizes Desktop and Documents folders with Apple iCloud cloud storage.",
            .whyActive: "Uploading or syncing photos and newly saved documents with iCloud servers.",
            .whatToDo: "You can pause iCloud Drive temporarily or pause this process while running on battery.",
            .category: "iCloud"
        ],
        "FortiClient": [
            .friendlyTitle: "FortiClient VPN",
            .description: "Enterprise VPN connection client providing encrypted network tunneling.",
            .whyActive: "Maintaining active encrypted tunnel to corporate servers.",
            .whatToDo: "Disconnect VPN when not needed to reduce Wi-Fi chip power consumption.",
            .category: "Security / VPN"
        ],
        "Termius": [
            .friendlyTitle: "Termius SSH Terminal",
            .description: "SSH client and remote server connection manager.",
            .whyActive: "Active SSH session sending keep-alive maintenance packets.",
            .whatToDo: "Close idle remote sessions when disconnecting from wall power.",
            .category: "Network Tools"
        ]
    ]
    
    // MARK: - Spanish Base Database
    private let db: [String: ProcessExplanation] = [
        "fileproviderd": ProcessExplanation(
            name: "fileproviderd",
            friendlyTitle: "Subflujo Cloud FileProvider",
            description: "Servicio del núcleo de macOS que coordina las operaciones de archivos para Google Drive, Synology Drive, Dropbox, iCloud y OneDrive.",
            whyActive: "Detecta continuos eventos de disco (FSEvents). Si tienes proyectos con 'node_modules', '.git' o compilaciones en la nube, se queda atascado procesando miles de archivos temporales.",
            whatToDo: "Excluye carpetas de código en tus apps de nube o mueve los proyectos a una ruta local (~/Developer). Puedes pausar este proceso en batería.",
            category: "Almacenamiento Cloud",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "mDNSResponder": ProcessExplanation(
            name: "mDNSResponder",
            friendlyTitle: "Mantenimiento de Red (Bonjour)",
            description: "Servicio central de red de macOS que mantiene la conexión WiFi viva y resuelve nombres de red Bonjour.",
            whyActive: "Se activa periódicamente durante la noche en reposo (DarkWake) para enviar paquetes de mantenimiento de red y evitar desconexiones.",
            whatToDo: "Es un proceso esencial de red de Apple. Si quieres reducir sus despertares nocturnos, puedes desactivar 'Activar para el acceso a la red' en Ajustes de Batería.",
            category: "Red del Sistema",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "apsd": ProcessExplanation(
            name: "apsd",
            friendlyTitle: "Apple Push Notifications (Power Nap)",
            description: "Daemon del servicio de notificaciones push de Apple para iCloud, Mail, iMessage y aplicaciones del sistema.",
            whyActive: "Despierta el Mac durante la noche para comprobar si has recibido correos, mensajes o alertas importantes sin encender la pantalla.",
            whatToDo: "Es un servicio seguro de Apple. Para evitar que despierte la batería de noche, puedes activar el modo 'Concentración / No molestar' o apagar Power Nap.",
            category: "Notificaciones y Push",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "AddressBookSourceSync": ProcessExplanation(
            name: "AddressBookSourceSync",
            friendlyTitle: "Sincronizador de Contactos y Cuentas",
            description: "Servicio de macOS que sincroniza la libreta de direcciones, contactos y calendarios de iCloud, Google o Exchange.",
            whyActive: "Comprueba cambios en tus libretas de direcciones remotas durante los ciclos de mantenimiento de reposo.",
            whatToDo: "Proceso normal de sincronización. No requiere acción a menos que tengas cuentas de correo con errores de autenticación.",
            category: "Sincronización Cloud",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "dasd": ProcessExplanation(
            name: "dasd",
            friendlyTitle: "Duet Activity Scheduler",
            description: "Planificador inteligente de macOS que organiza la ejecución de tareas de fondo en momentos de bajo consumo.",
            whyActive: "Evalúa los periodos de inactividad nocturna para ejecutar análisis de estabilidad, telemetría y cachés de fotos.",
            whatToDo: "Proceso vital del kernel de macOS para optimizar la batería. No se debe detener.",
            category: "Núcleo de macOS",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "studentd": ProcessExplanation(
            name: "studentd",
            friendlyTitle: "Apple Education / Student Daemon",
            description: "Servicio de soporte para Apple Classroom y perfiles de configuración de educación.",
            whyActive: "Comprueba periódicamente perfiles de dispositivo y certificados de red en segundo plano.",
            whatToDo: "Si no utilizas Apple Classroom ni perfiles educativos, no consume energía perceptible salvo en breves verificaciones.",
            category: "Servicios de macOS",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "powerd": ProcessExplanation(
            name: "powerd",
            friendlyTitle: "Gestor de Energía del Mac",
            description: "Servicio del núcleo de macOS que controla el reposo, despertar de pantalla, DarkWake y temporizadores de bajo consumo.",
            whyActive: "Supervisa los estados de batería, programa los despertares periódicos (Power Nap) y administra la energía en reposo.",
            whatToDo: "Proceso vital de Apple para la administración de energía y salud de la batería. No se debe pausar.",
            category: "Núcleo de macOS",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "cloudd": ProcessExplanation(
            name: "cloudd",
            friendlyTitle: "Sincronizador iCloud",
            description: "Daemon central de sincronización de iCloud Drive, Fotos, Notas, Llavero y Documentos de Apple.",
            whyActive: "Sincroniza archivos y metadatos con la nube de Apple al despertar el Mac o detectar cambios en tus carpetas de iCloud.",
            whatToDo: "Proceso estándar de Apple. Si consume constantemente, verifica en Finder que no haya archivos grandes sincronizándose en bucle en iCloud Drive.",
            category: "Sincronización Cloud",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "WindowServer": ProcessExplanation(
            name: "WindowServer",
            friendlyTitle: "Servidor Gráfico de Pantalla",
            description: "Es el motor gráfico central de macOS. Dibuja las ventanas, transparencias 'Liquid', efectos visuales, animaciones y monitores externos.",
            whyActive: "Muchas ventanas abiertas, vídeos reproduciéndose o monitores de alta resolución con brillo alto incrementan su consumo.",
            whatToDo: "Minimiza ventanas no utilizadas, cierra pestañas con animaciones pesadas y reduce levemente el brillo de la pantalla.",
            category: "Gráficos de macOS",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "cloud-drive-daemon": ProcessExplanation(
            name: "cloud-drive-daemon",
            friendlyTitle: "Synology Drive Client Daemon",
            description: "Servicio de sincronización continua de Synology Drive para tu NAS local o remoto.",
            whyActive: "Escanea y sube cambios de disco. En carpetas con repositorios o proyectos de desarrollo se dispara por los microarchivos generados al compilar.",
            whatToDo: "Pausa Synology Drive con el botón 'Pausar Proceso' mientras programas con batería, y agrega 'node_modules', '.git' y 'build' a las reglas de exclusión de Synology.",
            category: "Sincronización Cloud",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "cloud-drive-eventd": ProcessExplanation(
            name: "cloud-drive-eventd",
            friendlyTitle: "Synology Drive Event Watcher",
            description: "Monitor de eventos del sistema de archivos (FSEvents) de Synology Drive.",
            whyActive: "Monitorea en tiempo real cada archivo creado o modificado en tus carpetas de trabajo.",
            whatToDo: "Pausa temporalmente el proceso para evitar que despierte la CPU con cada auto-guardado de tu editor.",
            category: "Sincronización Cloud",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "cloud-drive-daem": ProcessExplanation(
            name: "cloud-drive-daem",
            friendlyTitle: "Synology Drive Daemon",
            description: "Subproceso de análisis de disco de Synology Drive Client.",
            whyActive: "Escaneando cambios recientes en directorios sincronizados.",
            whatToDo: "Pausa el proceso con el botón 'Pausar' para ahorrar entre 1W y 3W de energía continua en batería.",
            category: "Sincronización Cloud",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "SynologyDrive": ProcessExplanation(
            name: "SynologyDrive",
            friendlyTitle: "Synology Drive Client",
            description: "Aplicación de sincronización y respaldo de archivos Synology Drive.",
            whyActive: "Manteniendo la cola de subidas y descargas activa con el servidor NAS.",
            whatToDo: "Pausa la sincronización mientras estés en batería o trabajando en proyectos con miles de archivos temporales.",
            category: "Almacenamiento Cloud",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "Google Drive": ProcessExplanation(
            name: "Google Drive",
            friendlyTitle: "App Google Drive",
            description: "Aplicación de sincronización en streaming y en espejo de Google Drive.",
            whyActive: "Comprobando hash de archivos locales contra Google Cloud. Sufre un alto drenaje si sincroniza proyectos de desarrollo con 'node_modules' o '.git'.",
            whatToDo: "Pausa la sincronización desde el botón 'Pausar Proceso' o añade tus carpetas de proyectos a la lista de omisión.",
            category: "Almacenamiento Cloud",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "GoogleDriveFS": ProcessExplanation(
            name: "GoogleDriveFS",
            friendlyTitle: "Google Drive File System Core",
            description: "Motor de bajo nivel del sistema de archivos virtual de Google Drive.",
            whyActive: "Transfiriendo metadatos de archivos y cachés de sincronización continua.",
            whatToDo: "Pausa Google Drive mientras compilas o ejecutas scripts locales en directorios sincronizados.",
            category: "Almacenamiento Cloud",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "firefox": ProcessExplanation(
            name: "firefox",
            friendlyTitle: "Navegador Mozilla Firefox",
            description: "Navegador web de código abierto.",
            whyActive: "Pestañas abiertas con scripts en ejecución, vídeos o múltiples extensiones activas.",
            whatToDo: "Cierra pestañas inactivas que reproduzcan audio/video o usa el modo de ahorro de energía en pestañas.",
            category: "Navegación Web",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "Firefox GPU Help": ProcessExplanation(
            name: "Firefox GPU Help",
            friendlyTitle: "Aceleración Gráfica de Firefox",
            description: "Subproceso que procesa vídeo y WebGL usando la tarjeta gráfica integrada del Mac.",
            whyActive: "Una o más pestañas están renderizando contenido multimedia pesado (YouTube, streaming o animaciones 3D).",
            whatToDo: "Cierra o suspende pestañas con vídeos en segundo plano.",
            category: "Aceleración Gráfica",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "plugin-container": ProcessExplanation(
            name: "plugin-container",
            friendlyTitle: "Pestaña Aislada de Firefox",
            description: "Aísla pestañas y extensiones de Firefox en procesos separados.",
            whyActive: "Ejecución continua de scripts de páginas web complejas.",
            whatToDo: "Identifica la pestaña que más consume en el administrador de tareas de Firefox y ciérrala.",
            category: "Navegación Web",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "Safari": ProcessExplanation(
            name: "Safari",
            friendlyTitle: "Navegador Apple Safari",
            description: "Navegador oficial optimizado con tecnología WebKit de Apple.",
            whyActive: "Páginas web abiertas en segundo plano.",
            whatToDo: "Safari es muy eficiente; suspende pestañas de páginas con recargas automáticas frecuentes.",
            category: "Navegación Web",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "com.apple.WebKit.WebContent": ProcessExplanation(
            name: "com.apple.WebKit.WebContent",
            friendlyTitle: "Pestaña Web de Safari",
            description: "Motor de renderizado de contenido de una pestaña de Safari.",
            whyActive: "Página web ejecutando código JavaScript o contenido interactivo.",
            whatToDo: "Cierra la pestaña correspondiente si no la estás utilizando.",
            category: "Navegación Web",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "CleanMyMac X": ProcessExplanation(
            name: "CleanMyMac X",
            friendlyTitle: "CleanMyMac X",
            description: "Utilidad de optimización y limpieza del sistema de MacPaw.",
            whyActive: "Monitoreo en tiempo real de recursos y análisis programado.",
            whatToDo: "Si necesitas ahorrar batería, puedes desactivar el escaneo en segundo plano desde sus ajustes.",
            category: "Mantenimiento",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "CleanMyMac X HealthMonitor": ProcessExplanation(
            name: "CleanMyMac X HealthMonitor",
            friendlyTitle: "Monitor CleanMyMac",
            description: "Agente residente de CleanMyMac que vigila la temperatura, memoria y discos.",
            whyActive: "Muestreando sensores del Mac en segundo plano periódicamente.",
            whatToDo: "Pausar o cerrar si buscas maximizar hasta el último minuto de autonomía.",
            category: "Mantenimiento",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "Antigravity Help": ProcessExplanation(
            name: "Antigravity Help",
            friendlyTitle: "Antigravity Assistant Helper",
            description: "Proceso de asistencia técnica y compilación de proyectos de desarrollo.",
            whyActive: "Compilando código fuente, procesando datos o ejecutando diagnósticos.",
            whatToDo: "Pausar durante descansos si no estás compilando proyectos pesados.",
            category: "Desarrollo",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "Antigravity": ProcessExplanation(
            name: "Antigravity",
            friendlyTitle: "Entorno Antigravity",
            description: "Entorno interactivo de asistencia de programación y automatización.",
            whyActive: "Sesión activa de desarrollo y análisis de código.",
            whatToDo: "Permitir continuar o pausar si estás lejos de tu cargador.",
            category: "Desarrollo",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "kernel_task": ProcessExplanation(
            name: "kernel_task",
            friendlyTitle: "Núcleo XNU de macOS",
            description: "El núcleo del sistema operativo. Gestiona la memoria, CPU y refrigera el Mac.",
            whyActive: "Regulando la temperatura del chip de Apple para proteger la vida útil de la batería.",
            whatToDo: "No se puede cerrar. Coloca tu Mac sobre una superficie dura y despejada para que se enfríe.",
            category: "Núcleo del Sistema",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "mds": ProcessExplanation(
            name: "mds",
            friendlyTitle: "Indexador de Spotlight",
            description: "Servidor de metadatos de búsqueda rápida de archivos y correos de macOS.",
            whyActive: "Analizando archivos recién descargados o modificados para agregarlos a Spotlight.",
            whatToDo: "Espera a que termine la indexación o excluye carpetas de descargas masivas en Ajustes > Spotlight.",
            category: "Indexación",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "mds_stores": ProcessExplanation(
            name: "mds_stores",
            friendlyTitle: "Base de Datos Spotlight",
            description: "Guarda y optimiza los índices de búsqueda de Spotlight.",
            whyActive: "Escribiendo nuevos índices en disco.",
            whatToDo: "Permitir que finalice su proceso para búsquedas rápidas posteriores.",
            category: "Indexación",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "corespotlightd": ProcessExplanation(
            name: "corespotlightd",
            friendlyTitle: "Daemon de CoreSpotlight",
            description: "Indexa contenidos internos de aplicaciones (Correos de Mail, Notas, Contactos).",
            whyActive: "Indexando contenido tras recibir correos o crear notas nuevas.",
            whatToDo: "Suele calmarse tras un par de minutos de actividad.",
            category: "Indexación",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "trustd": ProcessExplanation(
            name: "trustd",
            friendlyTitle: "Verificador de Certificados SSL",
            description: "Valida la autenticidad de firmas digitales de apps y conexiones cifradas HTTPS.",
            whyActive: "Verificando conexiones seguras de aplicaciones activas.",
            whatToDo: "Esencial para la seguridad del sistema; no requiere acción del usuario.",
            category: "Seguridad",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "syspolicyd": ProcessExplanation(
            name: "syspolicyd",
            friendlyTitle: "Apple Gatekeeper Security",
            description: "Analiza binarios de aplicaciones antes de ejecutarse para bloquear malware.",
            whyActive: "Verificando aplicaciones recién abiertas.",
            whatToDo: "Esencial para la protección de macOS.",
            category: "Seguridad",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "coreaudiod": ProcessExplanation(
            name: "coreaudiod",
            friendlyTitle: "Servidor de Audio de macOS",
            description: "Gestiona altavoces internos, auriculares AirPods, micrófonos e instrumentos.",
            whyActive: "Alguna app tiene abierto un canal de audio o micrófono.",
            whatToDo: "Cierra aplicaciones de conferencias (Zoom, Teams, Meet) al terminar llamadas.",
            category: "Multimedia",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "bluetoothd": ProcessExplanation(
            name: "bluetoothd",
            friendlyTitle: "Gestor Bluetooth",
            description: "Controla la antena Bluetooth y la conexión con teclados, ratones y auriculares.",
            whyActive: "Manteniendo el enlace inalámbrico con dispositivos periféricos.",
            whatToDo: "Si no usas accesorios externos con batería baja, puedes apagar el Bluetooth.",
            category: "Conectividad",
            isSystem: true,
            safeToStop: false,
            canPause: false
        ),
        "bird": ProcessExplanation(
            name: "bird",
            friendlyTitle: "Sincronizador iCloud Drive",
            description: "Sube y descarga carpetas del Escritorio y Documentos a tu nube de iCloud.",
            whyActive: "Sincronizando fotos o archivos recién guardados con iCloud.",
            whatToDo: "Puedes pausar iCloud Drive temporalmente o pausar este proceso mientras usas batería.",
            category: "iCloud",
            isSystem: true,
            safeToStop: false,
            canPause: true
        ),
        "FortiClient": ProcessExplanation(
            name: "FortiClient",
            friendlyTitle: "VPN FortiClient",
            description: "Cliente de conexión VPN corporativa y cifrado de túnel de red.",
            whyActive: "Manteniendo el túnel cifrado hacia la red corporativa.",
            whatToDo: "Desconecta la VPN cuando no la necesites para reducir el consumo del chip Wi-Fi.",
            category: "Seguridad / VPN",
            isSystem: false,
            safeToStop: true,
            canPause: true
        ),
        "Termius": ProcessExplanation(
            name: "Termius",
            friendlyTitle: "Terminal SSH Termius",
            description: "Cliente SSH y gestor de conexiones a servidores remotos.",
            whyActive: "Sesión SSH abierta manteniendo paquetes keep-alive.",
            whatToDo: "Cierra sesiones remotas inactivas al desconectarte de la corriente.",
            category: "Herramientas de Red",
            isSystem: false,
            safeToStop: true,
            canPause: true
        )
    ]
    
    public func getLocalizedField(process: String, field: ExplanationField, fallback: String) -> String {
        let currentLang = LocalizationManager.shared.currentLanguage
        if currentLang == .spanish {
            return fallback
        }
        
        // Find in English
        if let dict = englishTranslations[process], let val = dict[field] {
            return val
        }
        
        // Generic matching
        for (key, dict) in englishTranslations {
            if process.lowercased().contains(key.lowercased()) {
                if let val = dict[field] { return val }
            }
        }
        
        return fallback
    }
    
    public func explain(processName: String, appName: String) -> ProcessExplanation {
        if let direct = db[processName] { return direct }
        if let byApp = db[appName] { return byApp }
        for (key, val) in db {
            if processName.lowercased().contains(key.lowercased()) || appName.lowercased().contains(key.lowercased()) {
                return val
            }
        }
        
        let isSys = processName.hasSuffix("d") || processName.starts(with: "com.apple.")
        let isEnglish = LocalizationManager.shared.currentLanguage != .spanish
        
        let title = appName.isEmpty ? processName : appName
        let desc = isEnglish ?
            (isSys ? "Native macOS background daemon or service for core system maintenance." : "User-installed application or background helper process.") :
            (isSys ? "Servicio o daemon en segundo plano nativo de macOS para tareas y mantenimiento del sistema." : "Aplicación o proceso en ejecución instalado por el usuario.")
        let why = isEnglish ?
            "Executing scheduled background tasks or active user application requests." :
            "Ejecutando tareas programadas o solicitudes de las aplicaciones abiertas."
        let action = isEnglish ?
            (isSys ? "Core system process; recommended to allow it to continue." : "You can pause or force quit this application if not in use to extend battery life.") :
            (isSys ? "Proceso del sistema; se recomienda dejarlo continuar." : "Puedes pausar o cerrar esta app si no la estás utilizando para ahorrar batería.")
        let cat = isEnglish ?
            (isSys ? "macOS System" : "User Application") :
            (isSys ? "Sistema macOS" : "Aplicación de Usuario")
        
        return ProcessExplanation(
            name: processName,
            friendlyTitle: title,
            description: desc,
            whyActive: why,
            whatToDo: action,
            category: cat,
            isSystem: isSys,
            safeToStop: !isSys,
            canPause: !isSys
        )
    }
}
