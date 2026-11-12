import SwiftUI

public struct ContentView: View {
    @ObservedObject var appState: AppState = AppState.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 0) {
            // TOP HEADER BAR
            HStack(spacing: 16) {
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "hand.point.up.left.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("HandMouse")
                            .font(.system(size: 15, weight: .bold))
                        Text("Webcam Hand Tracking Pointer")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Master Tracking Toggle
                Toggle(isOn: $appState.isTrackingEnabled) {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(appState.isTrackingEnabled ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(appState.isTrackingEnabled ? "Tracking Active" : "Paused")
                            .font(.system(size: 12, weight: .semibold))
                    }
                }
                .toggleStyle(.switch)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // MAIN BODY: Camera permanently mounted on Left, Tabs on Right
            HStack(spacing: 16) {
                // Left: Live Camera View
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Label("Camera Feed", systemImage: "video.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.secondary)
                        Spacer()
                        if !appState.isCameraAuthorized {
                            Button("Grant Camera Access") {
                                appState.requestCameraAccess()
                            }
                            .font(.system(size: 11))
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                    
                    CameraPreviewWithSkeletonView(appState: appState)
                        .frame(minWidth: 440, minHeight: 340)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                        )
                }
                .frame(maxWidth: .infinity)
                
                // Right: Tab Panel (Gesture Guide vs Settings)
                VStack(alignment: .leading, spacing: 10) {
                    Picker("", selection: $appState.selectedTab) {
                        Text("Gestures Guide").tag(0)
                        Text("Settings & Tuning").tag(1)
                    }
                    .pickerStyle(.segmented)
                    
                    if appState.selectedTab == 0 {
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                GestureGuideView(currentGesture: appState.currentGesture)
                                
                                Spacer(minLength: 10)
                                
                                // Quick Tip Card
                                HStack(spacing: 8) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                        .font(.system(size: 14))
                                    Text("Tip: To move a window, pinch on its title bar and move your hand. Release to drop!")
                                        .font(.system(size: 11))
                                        .foregroundColor(.secondary)
                                }
                                .padding(10)
                                .background(Color.yellow.opacity(0.08))
                                .cornerRadius(8)
                            }
                        }
                    } else {
                        SettingsView(appState: appState)
                    }
                }
                .frame(width: 360)
            }
            .padding(16)
            
            Divider()
            
            // BOTTOM STATUS FOOTER
            HStack(spacing: 16) {
                HStack(spacing: 6) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                    Text(appState.activeCameraName)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Divider()
                    .frame(height: 12)
                
                HStack(spacing: 6) {
                    Image(systemName: appState.isAccessibilityAuthorized ? "hand.tap.fill" : "exclamationmark.triangle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(appState.isAccessibilityAuthorized ? .green : .yellow)
                    Text(appState.isAccessibilityAuthorized ? "Accessibility Enabled" : "Accessibility Needed")
                        .font(.system(size: 11))
                        .foregroundColor(appState.isAccessibilityAuthorized ? .secondary : .yellow)
                }
                
                Spacer()
                
                if appState.pointerPosition != .zero {
                    Text(String(format: "Cursor: (%.0f, %.0f)", appState.pointerPosition.x, appState.pointerPosition.y))
                        .font(.system(size: 11, design: .monospaced))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 840, minHeight: 480)
    }
}
