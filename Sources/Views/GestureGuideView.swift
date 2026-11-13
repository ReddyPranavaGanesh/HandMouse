import SwiftUI

public struct GestureGuideView: View {
    let currentGesture: GestureType
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Gesture Controls")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.8))
                Spacer()
                Text("Live Feedback")
                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.cyan.opacity(0.12))
                    .cornerRadius(4)
            }
            
            VStack(spacing: 9) {
                gestureCard(
                    number: "1",
                    emoji: "☝️",
                    icon: "hand.point.up.left.fill",
                    title: "Point Index Finger",
                    subtitle: "Moves Mouse Pointer",
                    description: "Point your index finger towards the camera and move your hand to steer the cursor.",
                    color: .green,
                    isActive: currentGesture == .pointing
                )
                
                gestureCard(
                    number: "2",
                    emoji: "🤏",
                    icon: "hand.pinch",
                    title: "Quick Pinch",
                    subtitle: "Left Click",
                    description: "Touch thumb and index finger together briefly and release to perform a Left Click.",
                    color: .orange,
                    isActive: currentGesture == .pinch
                )
                
                gestureCard(
                    number: "3",
                    emoji: "✊",
                    icon: "hand.draw.fill",
                    title: "Pinch & Move",
                    subtitle: "Move Windows / Drag",
                    description: "Pinch on a window title bar, hold for >0.3s, and move your hand. Release to drop!",
                    color: .red,
                    isActive: currentGesture == .pinchAndMove
                )
                
                gestureCard(
                    number: "4",
                    emoji: "✌️",
                    icon: "v.circle.fill",
                    title: "Peace Sign (2 Fingers)",
                    subtitle: "Scroll Up / Down",
                    description: "Hold peace sign. Move hand upwards to scroll up, downwards to scroll down.",
                    color: .cyan,
                    isActive: currentGesture == .peaceScroll || currentGesture == .peaceScrollUp || currentGesture == .peaceScrollDown
                )
                
                gestureCard(
                    number: "5",
                    emoji: "👌",
                    icon: "hand.pinch.fill",
                    title: "Middle Finger & Thumb",
                    subtitle: "Right Click",
                    description: "Touch your middle fingertip and thumb tip together to perform a Right Click.",
                    color: .purple,
                    isActive: currentGesture == .rightClick
                )
            }
        }
    }
    
    private func gestureCard(number: String, emoji: String, icon: String, title: String, subtitle: String, description: String, color: Color, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Number & Icon Badge
            ZStack {
                Circle()
                    .fill(isActive ? color.opacity(0.35) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)
                
                Circle()
                    .stroke(isActive ? color : Color.white.opacity(0.15), lineWidth: 1)
                    .frame(width: 36, height: 36)
                
                Text(emoji)
                    .font(.system(size: 17))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(number). \(title)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isActive ? color : .white)
                    
                    Spacer()
                    
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold, design: .rounded))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(
                                LinearGradient(
                                    colors: [color, color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(4)
                            .shadow(color: color.opacity(0.5), radius: 6, x: 0, y: 1)
                    }
                }
                
                Text(subtitle)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(color)
                
                Text(description)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(10)
        .liquidGlassCard(cornerRadius: 14, isGlowing: isActive, glowColor: color)
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
