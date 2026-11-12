import Foundation
import CoreGraphics

/// OneEuroFilter provides low-latency, adaptive jitter filtering for interactive pointing.
/// Casiez, G., Roussel, N. and Vogel, D. (2012). 1 € Filter: A Simple Speed-based Low-pass Filter for Noisy Input in Human-Computer Interaction.
public class OneEuroFilter {
    public var minCutoff: Double
    public var beta: Double
    public var dCutoff: Double
    
    private var xPrev: Double?
    private var dxPrev: Double = 0.0
    private var tPrev: Double?
    
    public init(minCutoff: Double = 1.2, beta: Double = 0.015, dCutoff: Double = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
    }
    
    private func alpha(rate: Double, cutoff: Double) -> Double {
        let tau = 1.0 / (2.0 * Double.pi * cutoff)
        let te = 1.0 / rate
        return 1.0 / (1.0 + tau / te)
    }
    
    public func filter(x: Double, timestamp: Double) -> Double {
        guard let xPrev = xPrev, let tPrev = tPrev else {
            self.xPrev = x
            self.tPrev = timestamp
            return x
        }
        
        let dt = max(timestamp - tPrev, 1e-4)
        let rate = 1.0 / dt
        self.tPrev = timestamp
        
        let dx = (x - xPrev) * rate
        let edx = (dxPrev == 0.0) ? dx : (dxPrev + alpha(rate: rate, cutoff: dCutoff) * (dx - dxPrev))
        self.dxPrev = edx
        
        let cutoff = minCutoff + beta * abs(edx)
        let a = alpha(rate: rate, cutoff: cutoff)
        let xFiltered = xPrev + a * (x - xPrev)
        self.xPrev = xFiltered
        return xFiltered
    }
    
    public func reset() {
        xPrev = nil
        dxPrev = 0.0
        tPrev = nil
    }
}

/// Point2DFilter filters 2D coordinates (CGPoint) using two independent OneEuroFilters.
public class Point2DFilter {
    private let filterX: OneEuroFilter
    private let filterY: OneEuroFilter
    
    public init(minCutoff: Double = 1.2, beta: Double = 0.015) {
        self.filterX = OneEuroFilter(minCutoff: minCutoff, beta: beta)
        self.filterY = OneEuroFilter(minCutoff: minCutoff, beta: beta)
    }
    
    public func updateCoefficients(minCutoff: Double, beta: Double) {
        filterX.minCutoff = minCutoff
        filterX.beta = beta
        filterY.minCutoff = minCutoff
        filterY.beta = beta
    }
    
    public func filter(point: CGPoint, timestamp: Double) -> CGPoint {
        let x = filterX.filter(x: Double(point.x), timestamp: timestamp)
        let y = filterY.filter(x: Double(point.y), timestamp: timestamp)
        return CGPoint(x: x, y: y)
    }
    
    public func reset() {
        filterX.reset()
        filterY.reset()
    }
}
