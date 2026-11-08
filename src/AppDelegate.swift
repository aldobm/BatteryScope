import Cocoa
import SwiftUI

public class AppDelegate: NSObject, NSApplicationDelegate {
    public static var shared: AppDelegate!
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var mainWindow: NSWindow?
    private var timer: Timer?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self
        
        // Set dynamic high-res application icon
        if let iconImage = NSImage(contentsOfFile: "/tmp/master_app_icon.png") ?? NSImage(named: "AppIcon") {
            NSApplication.shared.applicationIconImage = iconImage
        }
        
        // 1. Setup Status Bar Menu Item
        setupStatusBarItem()
        
        // 2. Setup Main Window (CleanMyMac Liquid Glass style)
        setupMainWindow()
        
        // 3. Periodic update for status bar icon text
        timer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { [weak self] _ in
            self?.updateStatusItemTitle()
        }
        updateStatusItemTitle()
        
        // Bring app to foreground initially
        NSApp.activate(ignoringOtherApps: true)
        mainWindow?.makeKeyAndOrderFront(nil)
    }
    
    private func setupStatusBarItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "⚡️ --%"
            button.target = self
            button.action = #selector(togglePopover)
        }
        
        let pop = NSPopover()
        pop.contentSize = NSSize(width: 320, height: 350)
        pop.behavior = .transient
        pop.contentViewController = NSHostingController(
            rootView: MenuBarView(
                onOpenMainWindow: { [weak self] in
                    self?.popover?.performClose(nil)
                    self?.openMainWindow()
                },
                onQuit: {
                    NSApp.terminate(nil)
                }
            )
        )
        self.popover = pop
    }
    
    @objc private func togglePopover() {
        guard let button = statusItem?.button, let pop = popover else { return }
        if pop.isShown {
            pop.performClose(nil)
        } else {
            BatteryService.shared.refreshAll()
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }
    
    private func updateStatusItemTitle() {
        let snap = BatteryService.shared.snapshot
        let icon = snap.isCharging ? "⚡️" : "🔋"
        let pct = snap.chargePercent > 0 ? "\(snap.chargePercent)%" : "90%"
        statusItem?.button?.title = "\(icon) \(pct)"
    }
    
    private func setupMainWindow() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1040, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.center()
        window.setFrameAutosaveName("BatteryPulseMainWindow")
        window.isReleasedWhenClosed = false
        window.title = "BatteryPulse - Analizador de Batería"
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.backgroundColor = NSColor(srgbRed: 0.055, green: 0.027, blue: 0.11, alpha: 1.0)
        window.isOpaque = true
        window.hasShadow = true
        window.minSize = NSSize(width: 960, height: 640)
        
        let hosting = NSHostingController(rootView: MainView())
        window.contentViewController = hosting
        
        self.mainWindow = window
    }
    
    public func openMainWindow() {
        if mainWindow == nil {
            setupMainWindow()
        }
        mainWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            openMainWindow()
        }
        return true
    }
}
