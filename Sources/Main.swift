import SwiftUI
import AppKit

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    public var statusItemController: StatusItemController?
    
    public func applicationDidFinishLaunching(_ notification: Notification) {
        let state = AppState.shared
        statusItemController = StatusItemController(appState: state)
        NSApp.setActivationPolicy(.regular)
    }
    
    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // App stays alive in Menu Bar even if main window is closed
        return false
    }
}

@main
public struct HandMouseApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 820, height: 520)
    }
}
