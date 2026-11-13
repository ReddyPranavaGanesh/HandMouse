import Foundation
import SwiftUI
import Combine
import AVFoundation

private enum SettingsKeys {
    static let pointerSpeed = "HandMouse_pointerSpeed"
    static let smoothingMinCutoff = "HandMouse_smoothingMinCutoff"
    static let smoothingBeta = "HandMouse_smoothingBeta"
    static let reachabilityMargin = "HandMouse_reachabilityMargin"
    static let pinchThreshold = "HandMouse_pinchThreshold"
    static let pinchDragDelay = "HandMouse_pinchDragDelay"
    static let scrollSpeed = "HandMouse_scrollSpeed"
    static let isCameraMirrored = "HandMouse_isCameraMirrored"
    static let showSkeleton = "HandMouse_showSkeleton"
    static let enableSoundFeedback = "HandMouse_enableSoundFeedback"
}

@MainActor
public class AppState: ObservableObject, CameraManagerDelegate, GestureRecognizerDelegate {
    public static let shared = AppState()
    
    // Core Engines (nonisolated so background video capture threads can call them directly)
    public nonisolated let cameraManager = CameraManager()
    public nonisolated let handPoseDetector = HandPoseDetector()
    public nonisolated let gestureRecognizer = GestureRecognizer()
    
    // UI Navigation State
    @Published public var selectedTab: Int = 0
    @Published public var showSavedToast: Bool = false
    
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
    
    // Tuning & Settings (Persisted via UserDefaults)
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
        loadSavedSettings()
        setupBindings()
        checkPermissions()
        cameraManager.setup()
        if isTrackingEnabled {
            cameraManager.start()
        }
    }
    
    // MARK: - Persistence (UserDefaults)
    public func loadSavedSettings() {
        let defaults = UserDefaults.standard
        
        if defaults.object(forKey: SettingsKeys.pointerSpeed) != nil {
            self.pointerSpeed = defaults.double(forKey: SettingsKeys.pointerSpeed)
        }
        if defaults.object(forKey: SettingsKeys.smoothingMinCutoff) != nil {
            self.smoothingMinCutoff = defaults.double(forKey: SettingsKeys.smoothingMinCutoff)
        }
        if defaults.object(forKey: SettingsKeys.smoothingBeta) != nil {
            self.smoothingBeta = defaults.double(forKey: SettingsKeys.smoothingBeta)
        }
        if defaults.object(forKey: SettingsKeys.reachabilityMargin) != nil {
            self.reachabilityMargin = defaults.double(forKey: SettingsKeys.reachabilityMargin)
        }
        if defaults.object(forKey: SettingsKeys.pinchThreshold) != nil {
            self.pinchThreshold = defaults.double(forKey: SettingsKeys.pinchThreshold)
        }
        if defaults.object(forKey: SettingsKeys.pinchDragDelay) != nil {
            self.pinchDragDelay = defaults.double(forKey: SettingsKeys.pinchDragDelay)
        }
        if defaults.object(forKey: SettingsKeys.scrollSpeed) != nil {
            self.scrollSpeed = defaults.double(forKey: SettingsKeys.scrollSpeed)
        }
        if defaults.object(forKey: SettingsKeys.isCameraMirrored) != nil {
            self.isCameraMirrored = defaults.bool(forKey: SettingsKeys.isCameraMirrored)
        }
        if defaults.object(forKey: SettingsKeys.showSkeleton) != nil {
            self.showSkeleton = defaults.bool(forKey: SettingsKeys.showSkeleton)
        }
        if defaults.object(forKey: SettingsKeys.enableSoundFeedback) != nil {
            self.enableSoundFeedback = defaults.bool(forKey: SettingsKeys.enableSoundFeedback)
        }
        
        // Sync engines with loaded settings
        gestureRecognizer.pointerSpeedMultiplier = pointerSpeed
        gestureRecognizer.updateFilterParameters(minCutoff: smoothingMinCutoff, beta: smoothingBeta)
        gestureRecognizer.reachabilityMargin = reachabilityMargin
        gestureRecognizer.pinchThreshold = CGFloat(pinchThreshold)
        gestureRecognizer.pinchDragDelay = pinchDragDelay
        gestureRecognizer.scrollSensitivityMultiplier = scrollSpeed
        gestureRecognizer.isCameraMirrored = isCameraMirrored
        MouseController.shared.enableSoundFeedback = enableSoundFeedback
    }
    
    public func saveSettings() {
        let defaults = UserDefaults.standard
        defaults.set(pointerSpeed, forKey: SettingsKeys.pointerSpeed)
        defaults.set(smoothingMinCutoff, forKey: SettingsKeys.smoothingMinCutoff)
        defaults.set(smoothingBeta, forKey: SettingsKeys.smoothingBeta)
        defaults.set(reachabilityMargin, forKey: SettingsKeys.reachabilityMargin)
        defaults.set(pinchThreshold, forKey: SettingsKeys.pinchThreshold)
        defaults.set(pinchDragDelay, forKey: SettingsKeys.pinchDragDelay)
        defaults.set(scrollSpeed, forKey: SettingsKeys.scrollSpeed)
        defaults.set(isCameraMirrored, forKey: SettingsKeys.isCameraMirrored)
        defaults.set(showSkeleton, forKey: SettingsKeys.showSkeleton)
        defaults.set(enableSoundFeedback, forKey: SettingsKeys.enableSoundFeedback)
        defaults.synchronize()
        
        // Audio confirmation
        if enableSoundFeedback {
            NSSound(named: "Pop")?.play()
        }
        
        // Show confirmation toast
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            showSavedToast = true
        }
        
        // Auto-hide after 2.5 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) { [weak self] in
            withAnimation(.easeInOut(duration: 0.3)) {
                self?.showSavedToast = false
            }
        }
    }
    
    public func resetToDefaults() {
        pointerSpeed = 1.2
        smoothingMinCutoff = 1.2
        smoothingBeta = 0.015
        reachabilityMargin = 0.18
        pinchThreshold = 0.28
        pinchDragDelay = 0.32
        scrollSpeed = 1.8
        isCameraMirrored = true
        showSkeleton = true
        enableSoundFeedback = true
        
        saveSettings()
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
