import SwiftUI

public struct ContentView: View {
    @ObservedObject var appState: AppState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Ambient Liquid Glass Background (Soft colored orbs beneath frosted materials)
            LiquidGlassBackground()
            
            VStack(spacing: 0) {
                // TOP HEADER BAR (Frosted Liquid Glass Top Bar)
                HStack(spacing: 16) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.cyan, Color.blue, Color.purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 34, height: 34)
                                .shadow(color: Color.blue.opacity(0.4), radius: 8, x: 0, y: 2)
                            
                            Image(systemName: "hand.point.up.left.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("HandMouse")
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("AI Gesture Pointer Control")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.cyan.opacity(0.85))
                        }
                    }
                    
                    Spacer()
                    
                    // Master Tracking Toggle with glowing glass pill
                    Toggle(isOn: $appState.isTrackingEnabled) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(appState.isTrackingEnabled ? Color.green : Color.gray)
                                .frame(width: 8, height: 8)
                                .shadow(color: appState.isTrackingEnabled ? Color.green : Color.clear, radius: 4)
                            Text(appState.isTrackingEnabled ? "Tracking Active" : "Paused")
                                .font(.system(size: 12, weight: .semibold, design: .rounded))
                                .foregroundColor(.white)
                        }
                    }
                    .toggleStyle(.switch)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .liquidGlassCard(cornerRadius: 20)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1),
                    alignment: .bottom
                )
                
                // MAIN BODY: Camera permanently mounted on Left, Tabs on Right
                HStack(spacing: 16) {
                    // Left: Live Camera View in Liquid Glass Frame
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            HStack(spacing: 6) {
                                Image(systemName: "video.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.cyan)
                                Text("Camera Stream")
                                    .font(.system(size: 12, weight: .bold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                            
                            Spacer()
                            
                            if !appState.isCameraAuthorized {
                                Button("Grant Camera Access") {
                                    appState.requestCameraAccess()
                                }
                                .font(.system(size: 11, weight: .semibold))
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        
                        CameraPreviewWithSkeletonView(appState: appState)
                            .frame(minWidth: 440, minHeight: 340)
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        LinearGradient(
                                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: Color.black.opacity(0.25), radius: 12, x: 0, y: 6)
                    }
                    .frame(maxWidth: .infinity)
                    
                    // Right: Liquid Glass Tab Panel (Gesture Guide vs Settings)
                    VStack(alignment: .leading, spacing: 10) {
                        Picker("", selection: $appState.selectedTab) {
                            Text("Gestures Guide").tag(0)
                            Text("Settings & Tuning").tag(1)
                        }
                        .pickerStyle(.segmented)
                        .padding(2)
                        .liquidGlassCard(cornerRadius: 10)
                        
                        if appState.selectedTab == 0 {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 12) {
                                    GestureGuideView(currentGesture: appState.currentGesture)
                                    
                                    Spacer(minLength: 10)
                                    
                                    // Quick Tip Card
                                    HStack(alignment: .top, spacing: 10) {
                                        Image(systemName: "lightbulb.fill")
                                            .foregroundColor(.yellow)
                                            .font(.system(size: 14))
                                            .padding(.top, 2)
                                        Text("Tip: To move a window, pinch on its title bar, hold for >0.3s, and move your hand. Release to drop!")
                                            .font(.system(size: 11))
                                            .foregroundColor(.secondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                    .padding(12)
                                    .liquidGlassCard(cornerRadius: 12)
                                }
                            }
                        } else {
                            SettingsView(appState: appState)
                        }
                    }
                    .frame(width: 370)
                }
                .padding(16)
                
                // BOTTOM STATUS FOOTER (Frosted Glass)
                HStack(spacing: 16) {
                    HStack(spacing: 6) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.cyan)
                        Text(appState.activeCameraName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                    
                    Divider()
                        .frame(height: 12)
                        .background(Color.white.opacity(0.15))
                    
                    HStack(spacing: 6) {
                        Image(systemName: appState.isAccessibilityAuthorized ? "hand.tap.fill" : "exclamationmark.triangle.fill")
                            .font(.system(size: 10))
                            .foregroundColor(appState.isAccessibilityAuthorized ? .green : .yellow)
                        Text(appState.isAccessibilityAuthorized ? "Accessibility Enabled" : "Accessibility Needed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(appState.isAccessibilityAuthorized ? .white.opacity(0.75) : .yellow)
                    }
                    
                    Spacer()
                    
                    if appState.pointerPosition != .zero {
                        Text(String(format: "Cursor: (%.0f, %.0f)", appState.pointerPosition.x, appState.pointerPosition.y))
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundColor(.cyan.opacity(0.85))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.cyan.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 1),
                    alignment: .top
                )
            }
        }
        .frame(minWidth: 860, minHeight: 520)
    }
}
