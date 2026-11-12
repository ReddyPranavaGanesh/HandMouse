import SwiftUI

public struct GestureGuideView: View {
    let currentGesture: GestureType
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Gesture Controls")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            VStack(spacing: 8) {
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
                    description: "Pinch thumb and index on a window title bar and move your hand. Release to drop!",
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
                    icon: "hand.raised.fill",
                    title: "Close Fist or Middle Pinch",
                    subtitle: "Right Click",
                    description: "Close index finger into a fist (✊) OR pinch thumb and middle finger (👌) for a Right Click.",
                    color: .purple,
                    isActive: currentGesture == .fistRightClick
                )
            }
        }
    }
    
    private func gestureCard(number: String, emoji: String, icon: String, title: String, subtitle: String, description: String, color: Color, isActive: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            // Number & Icon Badge
            ZStack {
                Circle()
                    .fill(isActive ? color : Color.secondary.opacity(0.15))
                    .frame(width: 34, height: 34)
                
                Text(emoji)
                    .font(.system(size: 16))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("\(number). \(title)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(isActive ? color : .primary)
                    
                    Spacer()
                    
                    if isActive {
                        Text("ACTIVE")
                            .font(.system(size: 9, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(color)
                            .foregroundColor(.white)
                            .cornerRadius(4)
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
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isActive ? color.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isActive ? color : Color.clear, lineWidth: 1.5)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}
