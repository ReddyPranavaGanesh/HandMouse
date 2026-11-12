import Foundation
import CoreGraphics
import AppKit
import ApplicationServices

/// MouseController handles macOS CGEvent synthesis for pointer movement, clicks, dragging, and scrolling.
public class MouseController {
    public static let shared = MouseController()
    
    public private(set) var isLeftButtonDown: Bool = false
    public private(set) var isRightButtonDown: Bool = false
    public var enableSoundFeedback: Bool = true
    
    private let popSound = NSSound(named: "Pop")
    private let tinkSound = NSSound(named: "Tink")
    private let dragSound = NSSound(named: "Blow")
    
    public init() {}
    
    /// Checks if the process has Accessibility permissions to simulate user input
    public static var isAccessibilityTrusted: Bool {
        return AXIsProcessTrusted()
    }
    
    /// Requests Accessibility permissions from macOS if not already granted
    public static func requestAccessibilityPermissions() {
        let checkOptPrompt = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
        let options = [checkOptPrompt: true] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }
    
    /// Current main screen dimensions
    public var screenBounds: CGRect {
        return CGDisplayBounds(CGMainDisplayID())
    }
    
    /// Clamps point within current screen bounds
    public func clampToScreen(_ point: CGPoint) -> CGPoint {
        let bounds = screenBounds
        let clampedX = max(bounds.minX, min(point.x, bounds.maxX - 1))
        let clampedY = max(bounds.minY, min(point.y, bounds.maxY - 1))
        return CGPoint(x: clampedX, y: clampedY)
    }
    
    /// Get current cursor location
    public var currentPosition: CGPoint {
        if let event = CGEvent(source: nil) {
            return event.location
        }
        return CGPoint(x: screenBounds.midX, y: screenBounds.midY)
    }
    
    /// Moves the mouse pointer to a screen coordinate
    public func moveCursor(to targetPoint: CGPoint) {
        let pt = clampToScreen(targetPoint)
        CGWarpMouseCursorPosition(pt)
        if let moveEvent = CGEvent(mouseEventSource: nil, mouseType: .mouseMoved, mouseCursorPosition: pt, mouseButton: .left) {
            moveEvent.post(tap: .cghidEventTap)
        }
    }
    
    /// Simulates a Left Click (press and release)
    public func leftClick(at position: CGPoint? = nil) {
        let pos = clampToScreen(position ?? currentPosition)
        if enableSoundFeedback { popSound?.play() }
        
        let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: pos, mouseButton: .left)
        let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: pos, mouseButton: .left)
        
        down?.post(tap: .cghidEventTap)
        usleep(25_000) // 25ms click duration for reliable macOS app registration
        up?.post(tap: .cghidEventTap)
    }
    
    /// Simulates a Right Click (press and release)
    public func rightClick(at position: CGPoint? = nil) {
        let pos = clampToScreen(position ?? currentPosition)
        if enableSoundFeedback { tinkSound?.play() }
        
        let down = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: pos, mouseButton: .right)
        let up = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: pos, mouseButton: .right)
        
        down?.post(tap: .cghidEventTap)
        usleep(25_000)
        up?.post(tap: .cghidEventTap)
    }
    
    /// Begins holding the Left Mouse button down for window moving and dragging
    public func beginLeftDrag(at position: CGPoint? = nil) {
        guard !isLeftButtonDown else { return }
        let pos = clampToScreen(position ?? currentPosition)
        if enableSoundFeedback { dragSound?.play() }
        
        let down = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: pos, mouseButton: .left)
        down?.post(tap: .cghidEventTap)
        isLeftButtonDown = true
    }
    
    /// Updates position while left mouse button is held down (moves windows, selects, drags)
    public func updateLeftDrag(to targetPoint: CGPoint) {
        let pos = clampToScreen(targetPoint)
        CGWarpMouseCursorPosition(pos)
        
        if isLeftButtonDown {
            let drag = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDragged, mouseCursorPosition: pos, mouseButton: .left)
            drag?.post(tap: .cghidEventTap)
        } else {
            beginLeftDrag(at: pos)
        }
    }
    
    /// Releases the Left Mouse button
    public func endLeftDrag(at position: CGPoint? = nil) {
        guard isLeftButtonDown else { return }
        let pos = clampToScreen(position ?? currentPosition)
        
        let up = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: pos, mouseButton: .left)
        up?.post(tap: .cghidEventTap)
        isLeftButtonDown = false
        if enableSoundFeedback { popSound?.play() }
    }
    
    /// Begins holding the Right Mouse button down
    public func beginRightDrag(at position: CGPoint? = nil) {
        guard !isRightButtonDown else { return }
        let pos = clampToScreen(position ?? currentPosition)
        if enableSoundFeedback { dragSound?.play() }
        
        let down = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDown, mouseCursorPosition: pos, mouseButton: .right)
        down?.post(tap: .cghidEventTap)
        isRightButtonDown = true
    }
    
    /// Updates position while right mouse button is held down
    public func updateRightDrag(to targetPoint: CGPoint) {
        let pos = clampToScreen(targetPoint)
        CGWarpMouseCursorPosition(pos)
        
        if isRightButtonDown {
            let drag = CGEvent(mouseEventSource: nil, mouseType: .rightMouseDragged, mouseCursorPosition: pos, mouseButton: .right)
            drag?.post(tap: .cghidEventTap)
        } else {
            beginRightDrag(at: pos)
        }
    }
    
    /// Releases the Right Mouse button
    public func endRightDrag(at position: CGPoint? = nil) {
        guard isRightButtonDown else { return }
        let pos = clampToScreen(position ?? currentPosition)
        
        let up = CGEvent(mouseEventSource: nil, mouseType: .rightMouseUp, mouseCursorPosition: pos, mouseButton: .right)
        up?.post(tap: .cghidEventTap)
        isRightButtonDown = false
        if enableSoundFeedback { popSound?.play() }
    }
    
    /// Scrolls vertically by specified pixel delta
    public func scroll(deltaY: CGFloat) {
        guard abs(deltaY) > 0.5 else { return }
        let pixels = Int32(deltaY)
        if let scrollEvent = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: pixels, wheel2: 0, wheel3: 0) {
            scrollEvent.post(tap: .cghidEventTap)
        }
    }
    
    /// Safely releases any held buttons on reset or tracking stop
    public func reset() {
        if isLeftButtonDown {
            endLeftDrag()
        }
        if isRightButtonDown {
            endRightDrag()
        }
    }
}
