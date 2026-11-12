import Foundation
import SwiftUI
import Combine
import AVFoundation

@MainActor
public class AppState: ObservableObject, CameraManagerDelegate, GestureRecognizerDelegate {
    public static let shared = AppState()
    
    // Core Engines (nonisolated so background video capture threads can call them directly)
    public nonisolated let cameraManager = CameraManager()
    public nonisolated let handPoseDetector = HandPoseDetector()
    public nonisolated let gestureRecognizer = GestureRecognizer()
    
    // UI Navigation State
    @Published public var selectedTab: Int = 0
    
    // Published State for SwiftUI Views
    @Published public var isTrackingEnabled: Bool = true {
        didSet {
            if isTrackingEnabled {
                cameraManager.start()
            } else {
                cameraManager.stop()
                gestureRecognizer.reset()
            }
        }
    }
    
    @Published public var currentGesture: GestureType = .none
    @Published public var gestureDescription: String = "Starting camera..."
    @Published public var pointerPosition: CGPoint = .zero
    @Published public var handLandmarks: HandLandmarks? = nil
    @Published public var fps: Double = 0.0
    
    // Permissions
    @Published public var isCameraAuthorized: Bool = false
    @Published public var isAccessibilityAuthorized: Bool = false
    
    // Tuning & Settings
    @Published public var pointerSpeed: Double = 1.2 {
        didSet { gestureRecognizer.pointerSpeedMultiplier = pointerSpeed }
    }
    @Published public var smoothingBeta: Double = 0.015 {
        didSet { gestureRecognizer.updateFilterParameters(minCutoff: smoothingMinCutoff, beta: smoothingBeta) }
    }
    @Published public var smoothingMinCutoff: Double = 1.2 {
        didSet { gestureRecognizer.updateFilterParameters(minCutoff: smoothingMinCutoff, beta: smoothingBeta) }
    }
    @Published public var reachabilityMargin: Double = 0.18 {
        didSet { gestureRecognizer.reachabilityMargin = reachabilityMargin }
    }
    @Published public var pinchThreshold: Double = 0.28 {
        didSet { gestureRecognizer.pinchThreshold = CGFloat(pinchThreshold) }
    }
    @Published public var pinchDragDelay: Double = 0.32 {
        didSet { gestureRecognizer.pinchDragDelay = pinchDragDelay }
    }
    @Published public var scrollSpeed: Double = 1.8 {
        didSet { gestureRecognizer.scrollSensitivityMultiplier = scrollSpeed }
    }
    @Published public var isCameraMirrored: Bool = true {
        didSet { gestureRecognizer.isCameraMirrored = isCameraMirrored }
    }
    @Published public var showSkeleton: Bool = true
    @Published public var enableSoundFeedback: Bool = true {
        didSet { MouseController.shared.enableSoundFeedback = enableSoundFeedback }
    }
    
    @Published public var activeCameraName: String = "Inbuilt Webcam"
    
    public init() {
        setupBindings()
        checkPermissions()
        cameraManager.setup()
        if isTrackingEnabled {
            cameraManager.start()
        }
    }
    
    private func setupBindings() {
        cameraManager.delegate = self
        gestureRecognizer.delegate = self
        
        handPoseDetector.onHandDetected = { [weak self] landmarks, timestamp in
            guard let self = self else { return }
            
            // Deliver to gesture recognizer if tracking enabled
            Task { @MainActor in
                if self.isTrackingEnabled {
                    self.gestureRecognizer.process(landmarks: landmarks, timestamp: timestamp)
                }
                self.handLandmarks = landmarks
            }
        }
    }
    
    public func checkPermissions() {
        let camStatus = CameraManager.cameraAuthorizationStatus
        isCameraAuthorized = (camStatus == .authorized)
        isAccessibilityAuthorized = MouseController.isAccessibilityTrusted
        
        if let dev = cameraManager.currentDevice {
            activeCameraName = dev.localizedName
        }
    }
    
    public func requestCameraAccess() {
        CameraManager.requestCameraPermission { [weak self] granted in
            self?.isCameraAuthorized = granted
            if granted {
                self?.cameraManager.setup()
                self?.cameraManager.start()
            }
        }
    }
    
    public func requestAccessibilityAccess() {
        MouseController.requestAccessibilityPermissions()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            self?.isAccessibilityAuthorized = MouseController.isAccessibilityTrusted
        }
    }
    
    public func toggleTracking() {
        isTrackingEnabled.toggle()
    }
    
    // MARK: - CameraManagerDelegate
    nonisolated public func cameraManager(_ manager: CameraManager, didOutputSampleBuffer sampleBuffer: CMSampleBuffer) {
        handPoseDetector.process(sampleBuffer: sampleBuffer)
    }
    
    nonisolated public func cameraManager(_ manager: CameraManager, didUpdateFPS fps: Double) {
        Task { @MainActor in
            self.fps = fps
        }
    }
    
    // MARK: - GestureRecognizerDelegate
    nonisolated public func gestureRecognizer(_ recognizer: GestureRecognizer, didUpdateGesture gesture: GestureType, description: String) {
        Task { @MainActor in
            self.currentGesture = gesture
            self.gestureDescription = description
        }
    }
    
    nonisolated public func gestureRecognizer(_ recognizer: GestureRecognizer, didUpdatePointerPosition position: CGPoint) {
        Task { @MainActor in
            self.pointerPosition = position
        }
    }
}
