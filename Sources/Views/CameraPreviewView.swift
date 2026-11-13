import SwiftUI
import AVFoundation
import AppKit
import Vision

public class VideoLayerContainerView: NSView {
    public var previewLayer: AVCaptureVideoPreviewLayer?
    
    public override func layout() {
        super.layout()
        guard let layer = previewLayer else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer.frame = bounds
        CATransaction.commit()
    }
}

public struct CameraPreviewLayerRepresentable: NSViewRepresentable {
    public let session: AVCaptureSession
    
    public func makeNSView(context: Context) -> VideoLayerContainerView {
        let view = VideoLayerContainerView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let layer = AVCaptureVideoPreviewLayer(session: session)
        layer.videoGravity = .resizeAspectFill
        view.previewLayer = layer
        view.layer?.addSublayer(layer)
        return view
    }
    
    public func updateNSView(_ nsView: VideoLayerContainerView, context: Context) {
        if let layer = nsView.previewLayer, layer.session != session {
            layer.session = session
        }
    }
    
    public static func dismantleNSView(_ nsView: VideoLayerContainerView, coordinator: ()) {
        nsView.previewLayer?.removeFromSuperlayer()
        nsView.previewLayer = nil
    }
}

public struct CameraPreviewWithSkeletonView: View {
    @ObservedObject var appState: AppState
    
    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background Video Layer (Safely mirrored via SwiftUI scaleEffect)
                CameraPreviewLayerRepresentable(session: appState.cameraManager.captureSession)
                    .scaleEffect(x: appState.isCameraMirrored ? -1 : 1, y: 1)
                    .cornerRadius(12)
                
                // Real-time Hand Skeleton Overlay
                if appState.showSkeleton, let landmarks = appState.handLandmarks {
                    SkeletonCanvas(
                        landmarks: landmarks,
                        isMirrored: appState.isCameraMirrored,
                        currentGesture: appState.currentGesture,
                        size: geometry.size
                    )
                }
                
                // Active Boundary Guide (Subtle border for active reachability area)
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.white.opacity(0.15), style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                    .padding(geometry.size.width * CGFloat(appState.reachabilityMargin))
                
                // Dark Gradient at Bottom for HUD overlay readability
                VStack {
                    Spacer()
                    LinearGradient(
                        colors: [Color.black.opacity(0.7), Color.clear],
                        startPoint: .bottom,
                        endPoint: .top
                    )
                    .frame(height: 70)
                    .cornerRadius(12)
                }
                
                // Floating Gesture Status Pill at Bottom of Camera (Liquid Glass Pill)
                VStack {
                    Spacer()
                    HStack(spacing: 8) {
                        Text(appState.currentGesture.emoji)
                            .font(.system(size: 16))
                        
                        Image(systemName: appState.currentGesture.icon)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(gestureColor(appState.currentGesture))
                        
                        Text(appState.gestureDescription)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Spacer()
                        
                        Text("\(Int(appState.fps)) FPS")
                            .font(.system(size: 10, weight: .semibold, design: .monospaced))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Color.white.opacity(0.12))
                            .cornerRadius(6)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .liquidGlassCard(
                        cornerRadius: 14,
                        isGlowing: appState.currentGesture != .none && appState.currentGesture != .idle,
                        glowColor: gestureColor(appState.currentGesture)
                    )
                    .padding(12)
                }
            }
        }
    }
    
    private func gestureColor(_ gesture: GestureType) -> Color {
        switch gesture {
        case .none: return .gray
        case .idle: return .blue
        case .pointing: return .green
        case .pinch: return .orange
        case .pinchAndMove: return .red
        case .peaceScroll, .peaceScrollUp, .peaceScrollDown: return .cyan
        case .fistRightClick: return .purple
        }
    }
}

public struct SkeletonCanvas: View {
    let landmarks: HandLandmarks
    let isMirrored: Bool
    let currentGesture: GestureType
    let size: CGSize
    
    public var body: some View {
        Canvas { context, canvasSize in
            // Transform Vision point (0..1, origin bottom-left) to Canvas coordinates (origin top-left)
            func toCanvasPoint(_ p: CGPoint) -> CGPoint {
                let x = isMirrored ? (1.0 - p.x) * canvasSize.width : p.x * canvasSize.width
                let y = (1.0 - p.y) * canvasSize.height
                return CGPoint(x: x, y: y)
            }
            
            // 1. Draw Bones
            for (jointA, jointB) in HandLandmarks.boneConnections {
                if let pA = landmarks.point(jointA), let pB = landmarks.point(jointB) {
                    var path = Path()
                    path.move(to: toCanvasPoint(pA))
                    path.addLine(to: toCanvasPoint(pB))
                    
                    let thumbJoints: Set<VNHumanHandPoseObservation.JointName> = [.thumbCMC, .thumbMP, .thumbIP, .thumbTip]
                    let isThumbBone = thumbJoints.contains(jointA) || thumbJoints.contains(jointB)
                    let boneColor: Color = isThumbBone ? Color.orange.opacity(0.8) : Color.cyan.opacity(0.8)
                    
                    context.stroke(path, with: .color(boneColor), lineWidth: 3.5)
                }
            }
            
            // 2. Draw Pinch Highlight Line
            if let tTip = landmarks.thumbTip, let iTip = landmarks.indexTip {
                let ptThumb = toCanvasPoint(tTip)
                let ptIndex = toCanvasPoint(iTip)
                let dist = landmarks.pinchDistance ?? 1.0
                
                if dist < 0.38 {
                    var pinchPath = Path()
                    pinchPath.move(to: ptThumb)
                    pinchPath.addLine(to: ptIndex)
                    let pinchColor = dist < 0.28 ? Color.yellow : Color.orange.opacity(0.6)
                    context.stroke(pinchPath, with: .color(pinchColor), lineWidth: 4.5)
                }
            }
            
            // 3. Draw Joints
            for (_, p) in landmarks.points {
                let pt = toCanvasPoint(p)
                let jointRect = CGRect(x: pt.x - 4, y: pt.y - 4, width: 8, height: 8)
                context.fill(Path(ellipseIn: jointRect), with: .color(.white))
                context.stroke(Path(ellipseIn: jointRect), with: .color(.black.opacity(0.5)), lineWidth: 1)
            }
            
            // 4. Highlight Active Point (Index Tip for Pointing)
            if let iTip = landmarks.indexTip {
                let pt = toCanvasPoint(iTip)
                
                if landmarks.isIndexPointing {
                    let targetCircle = CGRect(x: pt.x - 12, y: pt.y - 12, width: 24, height: 24)
                    context.stroke(Path(ellipseIn: targetCircle), with: .color(.green), lineWidth: 2.5)
                    
                    var crosshair = Path()
                    crosshair.move(to: CGPoint(x: pt.x - 16, y: pt.y))
                    crosshair.addLine(to: CGPoint(x: pt.x + 16, y: pt.y))
                    crosshair.move(to: CGPoint(x: pt.x, y: pt.y - 16))
                    crosshair.addLine(to: CGPoint(x: pt.x, y: pt.y + 16))
                    context.stroke(crosshair, with: .color(.green.opacity(0.8)), lineWidth: 1.5)
                }
            }
            
            // 5. Highlight Peace Sign with Scroll direction
            if landmarks.isPeaceSign, let iTip = landmarks.indexTip, let mTip = landmarks.middleTip {
                let p1 = toCanvasPoint(iTip)
                let p2 = toCanvasPoint(mTip)
                let midX = (p1.x + p2.x) / 2
                let midY = min(p1.y, p2.y) - 26
                
                let peaceRect = CGRect(x: midX - 16, y: midY - 16, width: 32, height: 32)
                context.fill(Path(ellipseIn: peaceRect), with: .color(Color.cyan.opacity(0.85)))
                context.stroke(Path(ellipseIn: peaceRect), with: .color(.white), lineWidth: 2)
                let peaceText = Text("✌️").font(.system(size: 18))
                context.draw(peaceText, at: CGPoint(x: midX, y: midY))
            }
            
            // 6. Highlight Fist (Right Click)
            if landmarks.isFist, let wrist = landmarks.wrist {
                let pW = toCanvasPoint(wrist)
                let midX = pW.x
                let midY = pW.y - 35
                let fistRect = CGRect(x: midX - 18, y: midY - 18, width: 36, height: 36)
                context.fill(Path(ellipseIn: fistRect), with: .color(Color.purple.opacity(0.85)))
                context.stroke(Path(ellipseIn: fistRect), with: .color(.white), lineWidth: 2)
                let fistText = Text("✊").font(.system(size: 20))
                context.draw(fistText, at: CGPoint(x: midX, y: midY))
            }
        }
    }
}
