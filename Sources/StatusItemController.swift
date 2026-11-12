import AppKit

@MainActor
public class StatusItemController: NSObject {
    private var statusItem: NSStatusItem?
    private weak var appState: AppState?
    
    public init(appState: AppState) {
        self.appState = appState
        super.init()
        setupStatusItem()
    }
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.title = "🖐️"
            button.toolTip = "HandMouse - Gesture Pointer"
        }
        
        updateMenu()
    }
    
    public func updateMenu() {
        let menu = NSMenu()
        
        let statusTitle = appState?.isTrackingEnabled == true ? "Status: Tracking Active" : "Status: Paused"
        let statusItem = NSMenuItem(title: statusTitle, action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        let gestureTitle = "Gesture: \(appState?.gestureDescription ?? "Idle")"
        let gestureItem = NSMenuItem(title: gestureTitle, action: nil, keyEquivalent: "")
        gestureItem.isEnabled = false
        menu.addItem(gestureItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let toggleTitle = appState?.isTrackingEnabled == true ? "Pause Tracking" : "Resume Tracking"
        let toggleItem = NSMenuItem(title: toggleTitle, action: #selector(toggleTracking), keyEquivalent: "t")
        toggleItem.target = self
        menu.addItem(toggleItem)
        
        let openWindowItem = NSMenuItem(title: "Show HandMouse Window", action: #selector(showWindow), keyEquivalent: "o")
        openWindowItem.target = self
        menu.addItem(openWindowItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let quitItem = NSMenuItem(title: "Quit HandMouse", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    @objc private func toggleTracking() {
        appState?.toggleTracking()
        updateMenu()
    }
    
    @objc private func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
}
