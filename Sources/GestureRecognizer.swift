import Foundation
import CoreGraphics
import AppKit

public enum GestureType: String, CaseIterable {
    case none = "No Hand"
    case idle = "Neutral Hand"
    case pointing = "Pointing Index"
    case pinch = "Left Click (Pinch)"
    case pinchAndMove = "Moving Window (Drag)"
    case peaceScroll = "Peace Sign (Scroll)"
    case peaceScrollUp = "Scrolling Up"
    case peaceScrollDown = "Scrolling Down"
    case fistRightClick = "Right Click"
    
    public var icon: String {
        switch self {
        case .none: return "hand.raised.slash"
        case .idle: return "hand.raised"
        case .pointing: return "hand.point.up.left.fill"
        case .pinch: return "hand.pinch"
        case .pinchAndMove: return "hand.draw.fill"
        case .peaceScroll, .peaceScrollUp, .peaceScrollDown: return "v.circle.fill"
        case .fistRightClick: return "hand.raised.fill"
        }
    }
    
    public var emoji: String {
        switch self {
        case .none: return "❌"
        case .idle: return "✋"
        case .pointing: return "☝️"
        case .pinch: return "🤏"
        case .pinchAndMove: return "✊"
        case .peaceScroll, .peaceScrollUp, .peaceScrollDown: return "✌️"
        case .fistRightClick: return "👌"
        }
    }
}

public protocol GestureRecognizerDelegate: AnyObject {
    func gestureRecognizer(_ recognizer: GestureRecognizer, didUpdateGesture gesture: GestureType, description: String)
    func gestureRecognizer(_ recognizer: GestureRecognizer, didUpdatePointerPosition position: CGPoint)
}

public class GestureRecognizer {
    public weak var delegate: GestureRecognizerDelegate?
    
    // Sensitivity and Configuration Settings
    public var pointerSpeedMultiplier: Double = 1.2
    public var reachabilityMargin: Double = 0.18
    public var pinchThreshold: CGFloat = 0.28
    public var pinchReleaseThreshold: CGFloat = 0.38
    public var pinchDragDelay: Double = 0.32
    public var dragThresholdPoints: CGFloat = 20.0
    public var scrollSensitivityMultiplier: Double = 1.8
    public var isCameraMirrored: Bool = true
    
    // Filter
    public let pointFilter = Point2DFilter(minCutoff: 1.2, beta: 0.015)
    
    // Internal State Machine
    public private(set) var currentGesture: GestureType = .none
    public private(set) var currentDescription: String = "No Hand Detected"
    
    // Pinch / Drag tracking
    private var isPinching: Bool = false
    private var pinchStartTime: Double = 0
    private var pinchStartCursorPos: CGPoint = .zero
    private var pinchStartHandPos: CGPoint = .zero
    private var isInPinchAndMove: Bool = false
    private var lastPinchClickTime: Double = 0
    
    // Right Click (Fist or Middle Pinch) tracking
    private var hasFiredRightClick: Bool = false
    private var lastRightClickTime: Double = 0
    
    // Peace sign scrolling tracking
    private var lastPeaceSignHandY: CGFloat?
    
    public init() {}
    
    public func updateFilterParameters(minCutoff: Double, beta: Double) {
        pointFilter.updateCoefficients(minCutoff: minCutoff, beta: beta)
    }
    
    public func reset() {
        if isInPinchAndMove {
            MouseController.shared.endLeftDrag()
        }
        isPinching = false
        isInPinchAndMove = false
        hasFiredRightClick = false
        lastPinchClickTime = 0
        lastPeaceSignHandY = nil
        pointFilter.reset()
        MouseController.shared.reset()
        updateState(.none, description: "Tracking Stopped")
    }
    
    /// Processes landmarks from a new video frame
    public func process(landmarks: HandLandmarks?, timestamp: Double) {
        guard let landmarks = landmarks else {
            if currentGesture != .none {
                if isInPinchAndMove {
                    MouseController.shared.endLeftDrag()
                    isInPinchAndMove = false
                }
                isPinching = false
                hasFiredRightClick = false
                pointFilter.reset()
                updateState(.none, description: "No Hand Detected")
            }
            return
        }
        
        let screenBounds = MouseController.shared.screenBounds
        let currentPos = MouseController.shared.currentPosition
        
        // -----------------------------------------------------------------
        // 1. RIGHT CLICK: Fist Clench (✊) OR Middle Pinch (Thumb+Middle)
        // -----------------------------------------------------------------
        let isMiddlePinch = (landmarks.middlePinchDistance ?? 1.0) < pinchThreshold
        let isFistClench = landmarks.isFist
        
        if isFistClench || isMiddlePinch {
            if isInPinchAndMove {
                MouseController.shared.endLeftDrag(at: currentPos)
                isInPinchAndMove = false
                isPinching = false
            }
            
            if !hasFiredRightClick {
                if timestamp - lastRightClickTime > 0.35 {
                    hasFiredRightClick = true
                    lastRightClickTime = timestamp
                    
                    MouseController.shared.rightClick(at: currentPos)
                    let reason = isFistClench ? "✊ Right Click (Fist)" : "👌 Right Click (Middle Pinch)"
                    updateState(.fistRightClick, description: reason)
                }
            } else {
                updateState(.fistRightClick, description: "Right Click Active")
            }
            return
        } else {
            hasFiredRightClick = false
        }
        
        // -----------------------------------------------------------------
        // 2. PINCH & MOVE (WINDOW DRAGGING) & LEFT CLICK
        // -----------------------------------------------------------------
        if let pinchDist = landmarks.pinchDistance {
            if !isPinching && pinchDist < pinchThreshold {
                // Pinch began
                isPinching = true
                pinchStartTime = timestamp
                pinchStartCursorPos = currentPos
                pinchStartHandPos = landmarks.indexTip ?? .zero
                isInPinchAndMove = false
            } else if isPinching && pinchDist > pinchReleaseThreshold {
                // Pinch released
                isPinching = false
                
                if isInPinchAndMove {
                    // Release window / dropped item
                    MouseController.shared.endLeftDrag(at: currentPos)
                    isInPinchAndMove = false
                    updateState(.pointing, description: "Window Dropped / Released")
                } else {
                    // Quick pinch release without moving -> PURE LEFT CLICK!
                    if timestamp - lastPinchClickTime > 0.15 {
                        lastPinchClickTime = timestamp
                        MouseController.shared.leftClick(at: pinchStartCursorPos)
                        updateState(.pinch, description: "🤏 Left Click")
                    }
                }
            }
        }
        
        // While pinch is held: check for Window Moving (Left Click Drag)
        if isPinching {
            let currentHandTip = landmarks.indexTip ?? .zero
            let dx = currentHandTip.x - pinchStartHandPos.x
            let dy = currentHandTip.y - pinchStartHandPos.y
            let distMoved = sqrt(dx * dx + dy * dy) * screenBounds.width
            let pinchHeldDuration = timestamp - pinchStartTime
            
            // Only enter drag mode if held long enough (>= pinchDragDelay) AND moved deliberately (> dragThresholdPoints)
            if !isInPinchAndMove && pinchHeldDuration >= pinchDragDelay && distMoved > dragThresholdPoints {
                isInPinchAndMove = true
                MouseController.shared.beginLeftDrag(at: pinchStartCursorPos)
                updateState(.pinchAndMove, description: "✊ Moving Window (Left Drag)")
            }
            
            if isInPinchAndMove {
                // Drag cursor while holding left mouse button down (moves window)
                if let iTip = landmarks.indexTip {
                    let targetScreen = mapToScreen(normPoint: iTip, bounds: screenBounds)
                    let filtered = pointFilter.filter(point: targetScreen, timestamp: timestamp)
                    MouseController.shared.updateLeftDrag(to: filtered)
                    delegate?.gestureRecognizer(self, didUpdatePointerPosition: filtered)
                }
                updateState(.pinchAndMove, description: "✊ Moving Window (Left Drag)")
                return
            } else {
                updateState(.pinch, description: "🤏 Pinch (Hold & Move to Drag)")
                return
            }
        }
        
        // -----------------------------------------------------------------
        // 3. PEACE SIGN SCROLLING LOGIC (2 fingers up, hand up = scroll up, down = scroll down)
        // -----------------------------------------------------------------
        if landmarks.isPeaceSign {
            let handY = landmarks.middleMCP?.y ?? (landmarks.wrist?.y ?? 0.5)
            
            if let lastY = lastPeaceSignHandY {
                let deltaY = handY - lastY
                let scrollDeadzone: CGFloat = 0.002
                
                if deltaY > scrollDeadzone {
                    let scrollSpeed = deltaY * CGFloat(scrollSensitivityMultiplier) * 1200.0
                    MouseController.shared.scroll(deltaY: scrollSpeed)
                    updateState(.peaceScrollUp, description: "✌️ Scrolling Up ⬆️")
                } else if deltaY < -scrollDeadzone {
                    let scrollSpeed = deltaY * CGFloat(scrollSensitivityMultiplier) * 1200.0
                    MouseController.shared.scroll(deltaY: scrollSpeed)
                    updateState(.peaceScrollDown, description: "✌️ Scrolling Down ⬇️")
                } else {
                    updateState(.peaceScroll, description: "✌️ Peace Sign (Scroll Ready)")
                }
            } else {
                updateState(.peaceScroll, description: "✌️ Peace Sign Active")
            }
            lastPeaceSignHandY = handY
            return
        } else {
            lastPeaceSignHandY = nil
        }
        
        // -----------------------------------------------------------------
        // 4. POINTING INDEX FINGER MOUSE MOVEMENT
        // -----------------------------------------------------------------
        if landmarks.isIndexPointing {
            guard let iTip = landmarks.indexTip else { return }
            
            let targetScreen = mapToScreen(normPoint: iTip, bounds: screenBounds)
            let filtered = pointFilter.filter(point: targetScreen, timestamp: timestamp)
            
            MouseController.shared.moveCursor(to: filtered)
            delegate?.gestureRecognizer(self, didUpdatePointerPosition: filtered)
            updateState(.pointing, description: "🎯 Pointing (Moving Cursor)")
            return
        }
        
        // -----------------------------------------------------------------
        // 5. NEUTRAL HAND
        // -----------------------------------------------------------------
        updateState(.idle, description: "✋ Hand Detected (Idle)")
    }
    
    /// Maps normalized Vision coordinates (0...1) to macOS display coordinates with reachability margins
    private func mapToScreen(normPoint: CGPoint, bounds: CGRect) -> CGPoint {
        let mirroredX = isCameraMirrored ? (1.0 - normPoint.x) : normPoint.x
        let screenNormY = 1.0 - normPoint.y
        
        let margin = CGFloat(reachabilityMargin)
        let usableRangeX = max(1.0 - 2.0 * margin, 0.2)
        let usableRangeY = max(1.0 - 2.0 * margin, 0.2)
        
        let clampedX = max(0.0, min(1.0, (mirroredX - margin) / usableRangeX))
        let clampedY = max(0.0, min(1.0, (screenNormY - margin) / usableRangeY))
        
        let targetX = bounds.minX + clampedX * bounds.width
        let targetY = bounds.minY + clampedY * bounds.height
        
        return CGPoint(x: targetX, y: targetY)
    }
    
    private func updateState(_ state: GestureType, description: String) {
        if currentGesture != state || currentDescription != description {
            currentGesture = state
            currentDescription = description
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.delegate?.gestureRecognizer(self, didUpdateGesture: state, description: description)
            }
        }
    }
}
