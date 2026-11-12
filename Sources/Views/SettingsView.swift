import SwiftUI
import AVFoundation

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Tracking Speed & Smoothing
                GroupBox(label: Label("Pointer & Movement", systemImage: "cursorarrow.motionlines")) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pointer Sensitivity")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1fx", appState.pointerSpeed))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $appState.pointerSpeed, in: 0.5...3.0, step: 0.1)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Jitter Smoothing (One-Euro Filter)")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(smoothingLabel(appState.smoothingMinCutoff))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $appState.smoothingMinCutoff, in: 0.5...3.0, step: 0.1)
                            Text("Lower values reduce jitter when still; higher values give faster reaction.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Active Reachability Area")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text("\(Int(appState.reachabilityMargin * 100))% margin")
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $appState.reachabilityMargin, in: 0.05...0.30, step: 0.01)
                            Text("Adjusts boundary so you can reach screen edges comfortably.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                }
                
                // Gesture Detection Tuning
                GroupBox(label: Label("Gesture Tuning", systemImage: "hand.raised.fingers.spread")) {
                    VStack(alignment: .leading, spacing: 14) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Pinch Sensitivity")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(String(format: "%.2f", appState.pinchThreshold))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $appState.pinchThreshold, in: 0.15...0.40, step: 0.01)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Scroll Speed Multiplier")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(String(format: "%.1fx", appState.scrollSpeed))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $appState.scrollSpeed, in: 0.5...4.0, step: 0.1)
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Hold Pinch to Drag Delay")
                                    .font(.system(size: 12, weight: .medium))
                                Spacer()
                                Text(String(format: "%.2fs", appState.pinchDragDelay))
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            Slider(value: $appState.pinchDragDelay, in: 0.20...0.60, step: 0.02)
                            Text("Hold pinch longer than this to move windows; release before to click.")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(8)
                }
                
                // Display & Audio Feedback
                GroupBox(label: Label("Display & Feedback", systemImage: "tv.and.mediabox")) {
                    VStack(alignment: .leading, spacing: 10) {
                        Toggle("Mirror Camera Feed (Natural Mirror)", isOn: $appState.isCameraMirrored)
                            .font(.system(size: 12))
                        
                        Toggle("Show Hand Skeleton Overlay", isOn: $appState.showSkeleton)
                            .font(.system(size: 12))
                        
                        Toggle("Sound Effects on Click & Drag", isOn: $appState.enableSoundFeedback)
                            .font(.system(size: 12))
                    }
                    .padding(8)
                }
                
                // System Permissions
                GroupBox(label: Label("Permissions Status", systemImage: "lock.shield")) {
                    VStack(spacing: 8) {
                        permissionRow(
                            title: "Camera Access",
                            isAuthorized: appState.isCameraAuthorized,
                            actionTitle: "Request Access",
                            action: { appState.requestCameraAccess() }
                        )
                        
                        Divider()
                        
                        permissionRow(
                            title: "Accessibility (Mouse Control)",
                            isAuthorized: appState.isAccessibilityAuthorized,
                            actionTitle: "Open Settings",
                            action: { appState.requestAccessibilityAccess() }
                        )
                    }
                    .padding(8)
                }
            }
            .padding()
        }
    }
    
    private func smoothingLabel(_ val: Double) -> String {
        if val < 0.9 { return "Maximum Smooth" }
        if val < 1.6 { return "Balanced" }
        return "Fast Response"
    }
    
    private func permissionRow(title: String, isAuthorized: Bool, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isAuthorized ? .green : .yellow)
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
            
            Spacer()
            
            if isAuthorized {
                Text("Authorized")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.green)
            } else {
                Button(actionTitle) {
                    action()
                }
                .font(.system(size: 11))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
}
