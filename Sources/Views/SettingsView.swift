import SwiftUI
import AVFoundation

public struct SettingsView: View {
    @ObservedObject var appState: AppState
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Toast notification when settings are saved
                if appState.showSavedToast {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 14, weight: .bold))
                        Text("Settings saved to Mac successfully!")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .liquidGlassCard(cornerRadius: 12, isGlowing: true, glowColor: .green)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
                
                // 1. Pointer & Movement Card
                glassSection(
                    title: "Pointer & Movement",
                    icon: "cursorarrow.motionlines",
                    iconColor: .cyan
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        sliderRow(
                            title: "Pointer Sensitivity",
                            valueText: String(format: "%.1fx", appState.pointerSpeed),
                            value: $appState.pointerSpeed,
                            range: 0.5...3.0,
                            step: 0.1,
                            hint: "Controls how fast the cursor travels relative to hand movement."
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        sliderRow(
                            title: "Jitter Smoothing (One-Euro Filter)",
                            valueText: smoothingLabel(appState.smoothingMinCutoff),
                            value: $appState.smoothingMinCutoff,
                            range: 0.5...3.0,
                            step: 0.1,
                            hint: "Lower values filter out hand shaking when still; higher values give faster reaction."
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        sliderRow(
                            title: "Active Reachability Area",
                            valueText: "\(Int(appState.reachabilityMargin * 100))% margin",
                            value: $appState.reachabilityMargin,
                            range: 0.05...0.30,
                            step: 0.01,
                            hint: "Inner margin so you can reach all screen corners without stretching your arm."
                        )
                    }
                }
                
                // 2. Gesture Tuning Card
                glassSection(
                    title: "Gesture Tuning",
                    icon: "hand.raised.fingers.spread",
                    iconColor: .orange
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        sliderRow(
                            title: "Pinch Sensitivity",
                            valueText: String(format: "%.2f", appState.pinchThreshold),
                            value: $appState.pinchThreshold,
                            range: 0.15...0.40,
                            step: 0.01,
                            hint: "Distance threshold between thumb and index to detect a pinch."
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        sliderRow(
                            title: "Hold Pinch to Drag Delay",
                            valueText: String(format: "%.2fs", appState.pinchDragDelay),
                            value: $appState.pinchDragDelay,
                            range: 0.20...0.60,
                            step: 0.02,
                            hint: "Hold pinch longer than this to move windows; release before to click."
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        sliderRow(
                            title: "Scroll Speed Multiplier",
                            valueText: String(format: "%.1fx", appState.scrollSpeed),
                            value: $appState.scrollSpeed,
                            range: 0.5...4.0,
                            step: 0.1,
                            hint: "Vertical scrolling speed when holding the Peace Sign (✌️)."
                        )
                    }
                }
                
                // 3. Display & Audio Feedback Card
                glassSection(
                    title: "Display & Audio Feedback",
                    icon: "tv.and.mediabox",
                    iconColor: .purple
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        toggleRow(
                            title: "Mirror Camera Feed (Natural Mirror)",
                            description: "Flips camera horizontally like looking in a mirror.",
                            isOn: $appState.isCameraMirrored
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        toggleRow(
                            title: "Show Hand Skeleton Overlay",
                            description: "Draws colored joints, bone links, and gesture reticles.",
                            isOn: $appState.showSkeleton
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        toggleRow(
                            title: "Sound Effects on Click & Drag",
                            description: "Plays subtle macOS click sounds on actions.",
                            isOn: $appState.enableSoundFeedback
                        )
                    }
                }
                
                // 4. System Permissions Card
                glassSection(
                    title: "Permissions Status",
                    icon: "lock.shield.fill",
                    iconColor: .green
                ) {
                    VStack(spacing: 10) {
                        permissionRow(
                            title: "Camera Access",
                            isAuthorized: appState.isCameraAuthorized,
                            actionTitle: "Request Access",
                            action: { appState.requestCameraAccess() }
                        )
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        permissionRow(
                            title: "Accessibility (Mouse Control)",
                            isAuthorized: appState.isAccessibilityAuthorized,
                            actionTitle: "Open Settings",
                            action: { appState.requestAccessibilityAccess() }
                        )
                    }
                }
                
                // 5. Liquid Glass Persistence Actions (Save & Reset)
                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        Button(action: { appState.saveSettings() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "square.and.arrow.down.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Save Settings")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                        }
                        .buttonStyle(LiquidGlassButtonStyle(gradientColors: [Color.cyan, Color.blue], isPrimary: true))
                        
                        Button(action: { appState.resetToDefaults() }) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Reset Defaults")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                            }
                        }
                        .buttonStyle(LiquidGlassButtonStyle(isPrimary: false))
                        
                        Spacer()
                    }
                    
                    Text("Settings are saved locally on your Mac and automatically restored every time HandMouse opens.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(.top, 4)
            }
            .padding(14)
        }
    }
    
    // MARK: - Helper UI Builders
    
    private func glassSection<Content: View>(
        title: String,
        icon: String,
        iconColor: Color,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.2))
                        .frame(width: 24, height: 24)
                    Image(systemName: icon)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(iconColor)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
            
            content()
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 14)
    }
    
    private func sliderRow(
        title: String,
        valueText: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        hint: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Spacer()
                Text(valueText)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.15))
                    .cornerRadius(6)
            }
            
            Slider(value: value, in: range, step: step)
                .accentColor(.cyan)
            
            Text(hint)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
    }
    
    private func toggleRow(title: String, description: String, isOn: Binding<Bool>) -> some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                Text(description)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .toggleStyle(.switch)
                .labelsHidden()
        }
    }
    
    private func permissionRow(title: String, isAuthorized: Bool, actionTitle: String, action: @escaping () -> Void) -> some View {
        HStack {
            Image(systemName: isAuthorized ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundColor(isAuthorized ? .green : .yellow)
                .font(.system(size: 14))
            
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
            
            Spacer()
            
            if isAuthorized {
                Text("Authorized")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.15))
                    .cornerRadius(6)
            } else {
                Button(actionTitle) {
                    action()
                }
                .font(.system(size: 11, weight: .semibold))
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
    }
    
    private func smoothingLabel(_ val: Double) -> String {
        if val < 0.9 { return "Max Smooth" }
        if val < 1.6 { return "Balanced" }
        return "Fast Response"
    }
}
