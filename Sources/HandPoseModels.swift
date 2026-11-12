import Foundation
import CoreGraphics
import Vision

/// Recognized hand landmark joints mapped from Apple's Vision framework
public struct HandLandmarks {
    public var points: [VNHumanHandPoseObservation.JointName: CGPoint]
    public var confidences: [VNHumanHandPoseObservation.JointName: Float]
    
    public init(points: [VNHumanHandPoseObservation.JointName: CGPoint],
                confidences: [VNHumanHandPoseObservation.JointName: Float]) {
        self.points = points
        self.confidences = confidences
    }
    
    public func point(_ joint: VNHumanHandPoseObservation.JointName) -> CGPoint? {
        return points[joint]
    }
    
    public func confidence(_ joint: VNHumanHandPoseObservation.JointName) -> Float {
        return confidences[joint] ?? 0.0
    }
    
    public var wrist: CGPoint? { point(.wrist) }
    
    public var thumbTip: CGPoint? { point(.thumbTip) }
    public var thumbIP: CGPoint? { point(.thumbIP) }
    public var thumbMP: CGPoint? { point(.thumbMP) }
    public var thumbCMC: CGPoint? { point(.thumbCMC) }
    
    public var indexTip: CGPoint? { point(.indexTip) }
    public var indexDIP: CGPoint? { point(.indexDIP) }
    public var indexPIP: CGPoint? { point(.indexPIP) }
    public var indexMCP: CGPoint? { point(.indexMCP) }
    
    public var middleTip: CGPoint? { point(.middleTip) }
    public var middleDIP: CGPoint? { point(.middleDIP) }
    public var middlePIP: CGPoint? { point(.middlePIP) }
    public var middleMCP: CGPoint? { point(.middleMCP) }
    
    public var ringTip: CGPoint? { point(.ringTip) }
    public var ringDIP: CGPoint? { point(.ringDIP) }
    public var ringPIP: CGPoint? { point(.ringPIP) }
    public var ringMCP: CGPoint? { point(.ringMCP) }
    
    public var littleTip: CGPoint? { point(.littleTip) }
    public var littleDIP: CGPoint? { point(.littleDIP) }
    public var littlePIP: CGPoint? { point(.littlePIP) }
    public var littleMCP: CGPoint? { point(.littleMCP) }
    
    /// Palm scale calculated from wrist to middle MCP joint distance.
    /// Used to normalize distances so gestures are invariant to camera distance.
    public var palmScale: CGFloat {
        guard let w = wrist, let mMCP = middleMCP else { return 0.2 }
        let d = distance(w, mMCP)
        return max(d, 0.05)
    }
    
    public static func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        let dx = a.x - b.x
        let dy = a.y - b.y
        return sqrt(dx * dx + dy * dy)
    }
    
    public func distance(_ a: CGPoint, _ b: CGPoint) -> CGFloat {
        return HandLandmarks.distance(a, b)
    }
    
    /// Normalized distance between thumb tip and index tip relative to palm scale
    public var pinchDistance: CGFloat? {
        guard let t = thumbTip, let i = indexTip else { return nil }
        return distance(t, i) / palmScale
    }
    
    /// Normalized distance between thumb tip and middle finger tip (Middle Pinch for Right Click)
    public var middlePinchDistance: CGFloat? {
        guard let t = thumbTip, let m = middleTip else { return nil }
        return distance(t, m) / palmScale
    }
    
    /// Checks if a finger is extended relative to the palm
    public func isFingerExtended(tip: CGPoint?, mcp: CGPoint?, pip: CGPoint?) -> Bool {
        guard let w = wrist, let t = tip, let m = mcp else { return false }
        let wristToTip = distance(w, t)
        let wristToMCP = distance(w, m)
        guard wristToMCP > 0.01 else { return false }
        let ratio = wristToTip / wristToMCP
        
        // Also verify tip is further from MCP than PIP is
        if let p = pip {
            let mcpToTip = distance(m, t)
            let mcpToPIP = distance(m, p)
            return ratio > 1.35 && mcpToTip > mcpToPIP * 1.2
        }
        return ratio > 1.35
    }
    
    /// Checks if a finger is curled into the palm
    public func isFingerCurled(tip: CGPoint?, mcp: CGPoint?) -> Bool {
        guard let w = wrist, let t = tip, let m = mcp else { return true }
        let wristToTip = distance(w, t)
        let wristToMCP = distance(w, m)
        guard wristToMCP > 0.01 else { return true }
        let ratio = wristToTip / wristToMCP
        let tipToMCP = distance(t, m) / palmScale
        return ratio < 1.25 || tipToMCP < 0.65
    }
    
    public var isIndexExtended: Bool {
        isFingerExtended(tip: indexTip, mcp: indexMCP, pip: indexPIP)
    }
    
    public var isMiddleExtended: Bool {
        isFingerExtended(tip: middleTip, mcp: middleMCP, pip: middlePIP)
    }
    
    public var isRingExtended: Bool {
        isFingerExtended(tip: ringTip, mcp: ringMCP, pip: ringPIP)
    }
    
    public var isLittleExtended: Bool {
        isFingerExtended(tip: littleTip, mcp: littleMCP, pip: littlePIP)
    }
    
    public var isIndexCurled: Bool {
        isFingerCurled(tip: indexTip, mcp: indexMCP)
    }
    
    public var isMiddleCurled: Bool {
        isFingerCurled(tip: middleTip, mcp: middleMCP)
    }
    
    public var isRingCurled: Bool {
        isFingerCurled(tip: ringTip, mcp: ringMCP)
    }
    
    public var isLittleCurled: Bool {
        isFingerCurled(tip: littleTip, mcp: littleMCP)
    }
    
    /// Fist: Index finger is closed/curled down into palm
    public var isFist: Bool {
        guard !isIndexExtended && !isMiddleExtended else { return false }
        let indexCurled = isIndexCurled || (indexTip != nil && indexMCP != nil && distance(indexTip!, indexMCP!) / palmScale < 0.45)
        let middleCurled = isMiddleCurled || (middleTip != nil && middleMCP != nil && distance(middleTip!, middleMCP!) / palmScale < 0.45)
        return indexCurled && middleCurled
    }
    
    /// Index finger pointing: Index is extended (or pointing forward), while middle, ring, and pinky are curled.
    public var isIndexPointing: Bool {
        guard let iTip = indexTip, let w = wrist else { return false }
        let middleIsCurled = isMiddleCurled
        let ringIsCurled = isRingCurled
        let littleIsCurled = isLittleCurled
        
        // When pointing towards the camera or up:
        // Index is distinctly more extended than middle finger
        let indexDist = distance(w, iTip)
        let middleDist = middleTip != nil ? distance(w, middleTip!) : 0
        let isExtendedOutward = (indexDist > middleDist * 1.15) || isIndexExtended
        
        return isExtendedOutward && middleIsCurled && (ringIsCurled || littleIsCurled)
    }
    
    /// Peace sign (V-sign): Index AND Middle are extended; Ring AND Little are curled.
    public var isPeaceSign: Bool {
        guard let iTip = indexTip, let mTip = middleTip else { return false }
        let indexExt = isIndexExtended
        let middleExt = isMiddleExtended
        let ringCurled = isRingCurled
        let littleCurled = isLittleCurled
        
        // Check V-shape separation between index and middle tips
        let tipSeparation = distance(iTip, mTip) / palmScale
        
        return indexExt && middleExt && ringCurled && littleCurled && tipSeparation > 0.18
    }
    
    /// Predefined skeleton bone segments for visual rendering
    public static let boneConnections: [(VNHumanHandPoseObservation.JointName, VNHumanHandPoseObservation.JointName)] = [
        // Thumb
        (.wrist, .thumbCMC),
        (.thumbCMC, .thumbMP),
        (.thumbMP, .thumbIP),
        (.thumbIP, .thumbTip),
        
        // Index
        (.wrist, .indexMCP),
        (.indexMCP, .indexPIP),
        (.indexPIP, .indexDIP),
        (.indexDIP, .indexTip),
        
        // Middle
        (.wrist, .middleMCP),
        (.middleMCP, .middlePIP),
        (.middlePIP, .middleDIP),
        (.middleDIP, .middleTip),
        
        // Ring
        (.wrist, .ringMCP),
        (.ringMCP, .ringPIP),
        (.ringPIP, .ringDIP),
        (.ringDIP, .ringTip),
        
        // Little
        (.wrist, .littleMCP),
        (.littleMCP, .littlePIP),
        (.littlePIP, .littleDIP),
        (.littleDIP, .littleTip),
        
        // Knuckles line (palm arch)
        (.thumbCMC, .indexMCP),
        (.indexMCP, .middleMCP),
        (.middleMCP, .ringMCP),
        (.ringMCP, .littleMCP)
    ]
}
