#!/usr/bin/env python3
"""
HandMouse - Python Alternative Implementation
Tracks hand movements and gestures via webcam using OpenCV & MediaPipe,
controlling macOS mouse cursor via Quartz CoreGraphics.

Gestures:
1. Pointing index finger towards camera: Moves mouse pointer
2. Pinch (thumb + index): Left Click
3. Pinch and move: Moving Window / Dragging (Holding Left Click Down)
4. Peace sign (2 fingers): Moving hand up scrolls up, moving hand down scrolls down
5. Close fist (✊) OR Thumb + Middle Pinch (👌): Right Click
"""

import cv2
import time
import math
import sys

try:
    import mediapipe as mp
except ImportError:
    print("MediaPipe not found. Run: pip install -r requirements.txt")
    sys.exit(1)

try:
    import Quartz.CoreGraphics as CG
except ImportError:
    print("Quartz not found. Run: pip install pyobjc-framework-Quartz")
    sys.exit(1)


class MacMouse:
    def __init__(self):
        main_display = CG.CGMainDisplayID()
        bounds = CG.CGDisplayBounds(main_display)
        self.screen_w = bounds.size.width
        self.screen_h = bounds.size.height
        self.is_left_down = False
        self.is_right_down = False

    def get_pos(self):
        event = CG.CGEventCreate(None)
        cur = CG.CGEventGetLocation(event)
        return cur.x, cur.y

    def move(self, x, y):
        x = max(0, min(self.screen_w - 1, x))
        y = max(0, min(self.screen_h - 1, y))
        pt = CG.CGPoint(x, y)
        CG.CGWarpMouseCursorPosition(pt)
        event = CG.CGEventCreateMouseEvent(None, CG.kCGEventMouseMoved, pt, CG.kCGMouseButtonLeft)
        CG.CGEventPost(CG.kCGHIDEventTap, event)

    def left_click(self, x, y):
        pt = CG.CGPoint(x, y)
        down = CG.CGEventCreateMouseEvent(None, CG.kCGEventLeftMouseDown, pt, CG.kCGMouseButtonLeft)
        up = CG.CGEventCreateMouseEvent(None, CG.kCGEventLeftMouseUp, pt, CG.kCGMouseButtonLeft)
        CG.CGEventPost(CG.kCGHIDEventTap, down)
        time.sleep(0.02)
        CG.CGEventPost(CG.kCGHIDEventTap, up)

    def right_click(self, x, y):
        pt = CG.CGPoint(x, y)
        down = CG.CGEventCreateMouseEvent(None, CG.kCGEventRightMouseDown, pt, CG.kCGMouseButtonRight)
        up = CG.CGEventCreateMouseEvent(None, CG.kCGEventRightMouseUp, pt, CG.kCGMouseButtonRight)
        CG.CGEventPost(CG.kCGHIDEventTap, down)
        time.sleep(0.02)
        CG.CGEventPost(CG.kCGHIDEventTap, up)

    def start_left_drag(self, x, y):
        if not self.is_left_down:
            pt = CG.CGPoint(x, y)
            down = CG.CGEventCreateMouseEvent(None, CG.kCGEventLeftMouseDown, pt, CG.kCGMouseButtonLeft)
            CG.CGEventPost(CG.kCGHIDEventTap, down)
            self.is_left_down = True

    def update_left_drag(self, x, y):
        pt = CG.CGPoint(x, y)
        CG.CGWarpMouseCursorPosition(pt)
        drag = CG.CGEventCreateMouseEvent(None, CG.kCGEventLeftMouseDragged, pt, CG.kCGMouseButtonLeft)
        CG.CGEventPost(CG.kCGHIDEventTap, drag)

    def end_left_drag(self, x, y):
        if self.is_left_down:
            pt = CG.CGPoint(x, y)
            up = CG.CGEventCreateMouseEvent(None, CG.kCGEventLeftMouseUp, pt, CG.kCGMouseButtonLeft)
            CG.CGEventPost(CG.kCGHIDEventTap, up)
            self.is_left_down = False

    def scroll(self, delta_y):
        event = CG.CGEventCreateScrollWheelEvent2(None, CG.kCGScrollEventUnitPixel, 1, int(delta_y), 0, 0)
        CG.CGEventPost(CG.kCGHIDEventTap, event)


def dist(p1, p2):
    return math.hypot(p1[0] - p2[0], p1[1] - p2[1])


def main():
    cap = cv2.VideoCapture(0)
    if not cap.isOpened():
        print("Error: Could not open webcam.")
        return

    mp_hands = mp.solutions.hands
    mp_draw = mp.solutions.drawing_utils
    hands = mp_hands.Hands(max_num_hands=1, min_detection_confidence=0.7, min_tracking_confidence=0.6)

    mouse = MacMouse()

    smooth_x, smooth_y = mouse.screen_w / 2, mouse.screen_h / 2
    alpha = 0.25
    margin = 0.18

    is_pinching = False
    pinch_start_time = 0
    pinch_start_pos = (0, 0)
    in_drag = False
    last_pinch_click_time = 0
    has_fired_right = False
    last_right_time = 0

    last_peace_y = None

    print("\nHandMouse Running! Press 'q' in camera window to quit.")
    print("1. Point Index: Move Pointer")
    print("2. Quick Pinch: Left Click")
    print("3. Pinch & Move: Move Windows / Drag (Left Drag)")
    print("4. Peace Sign (✌️): Move Up = Scroll Up, Move Down = Scroll Down")
    print("5. Close Fist (✊) OR Thumb + Middle Pinch (👌): Right Click\n")

    while True:
        ret, frame = cap.read()
        if not ret:
            break

        frame = cv2.flip(frame, 1)
        h, w, _ = frame.shape
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        results = hands.process(rgb)

        current_time = time.time()
        gesture_text = "Idle"
        gesture_color = (200, 200, 200)

        if results.multi_hand_landmarks:
            for hand_lms in results.multi_hand_landmarks:
                mp_draw.draw_landmarks(frame, hand_lms, mp_hands.HAND_CONNECTIONS)
                lm = [(p.x, p.y) for p in hand_lms.landmark]

                wrist = lm[0]
                thumb_tip = lm[4]
                index_mcp = lm[5]
                index_pip = lm[6]
                index_tip = lm[8]
                middle_mcp = lm[9]
                middle_pip = lm[10]
                middle_tip = lm[12]
                ring_mcp = lm[13]
                ring_tip = lm[16]
                pinky_mcp = lm[17]
                pinky_tip = lm[20]

                palm_scale = max(dist(wrist, middle_mcp), 0.05)

                def is_ext(tip, mcp, pip):
                    return dist(wrist, tip) > dist(wrist, mcp) * 1.35 and dist(mcp, tip) > dist(mcp, pip) * 1.15

                def is_curled(tip, mcp):
                    return dist(wrist, tip) < dist(wrist, mcp) * 1.25 or (dist(tip, mcp) / palm_scale < 0.65)

                index_extended = is_ext(index_tip, index_mcp, index_pip)
                middle_extended = is_ext(middle_tip, middle_mcp, middle_pip)
                index_curled = is_curled(index_tip, index_mcp)
                middle_curled = is_curled(middle_tip, middle_mcp)
                ring_curled = is_curled(ring_tip, ring_mcp)
                pinky_curled = is_curled(pinky_tip, pinky_mcp)

                is_fist = (not index_extended) and (not middle_extended) and (index_curled or dist(index_tip, index_mcp)/palm_scale < 0.45)
                pinch_d = dist(thumb_tip, index_tip) / palm_scale
                middle_pinch_d = dist(thumb_tip, middle_tip) / palm_scale

                norm_x = (index_tip[0] - margin) / max(1.0 - 2 * margin, 0.1)
                norm_y = (index_tip[1] - margin) / max(1.0 - 2 * margin, 0.1)
                norm_x = max(0.0, min(1.0, norm_x))
                norm_y = max(0.0, min(1.0, norm_y))

                target_x = norm_x * mouse.screen_w
                target_y = norm_y * mouse.screen_h
                smooth_x = alpha * target_x + (1 - alpha) * smooth_x
                smooth_y = alpha * target_y + (1 - alpha) * smooth_y

                # 1. RIGHT CLICK: Touching Middle Finger and Thumb (👌)
                if middle_pinch_d < 0.28 and middle_pinch_d < pinch_d:
                    if in_drag:
                        mouse.end_left_drag(smooth_x, smooth_y)
                        in_drag = False
                        is_pinching = False

                    if not has_fired_right:
                        if current_time - last_right_time > 0.25:
                            has_fired_right = True
                            last_right_time = current_time
                            mouse.right_click(smooth_x, smooth_y)
                            gesture_text = "Right Click (Middle + Thumb 👌)"
                            gesture_color = (255, 0, 255)
                    else:
                        gesture_text = "Right Click Active (👌)"
                        gesture_color = (200, 0, 200)
                elif middle_pinch_d > 0.38:
                    has_fired_right = False

                # 2. PINCH LOGIC: Left Click & Window Dragging
                elif pinch_d < 0.28 and not is_pinching:
                    has_fired_right = False
                    is_pinching = True
                    pinch_start_time = current_time
                    pinch_start_pos = (smooth_x, smooth_y)
                    in_drag = False
                elif pinch_d > 0.38 and is_pinching:
                    is_pinching = False
                    if in_drag:
                        mouse.end_left_drag(smooth_x, smooth_y)
                        in_drag = False
                        gesture_text = "Window Dropped"
                    else:
                        if (current_time - pinch_start_time) < 0.55 and (current_time - last_pinch_click_time > 0.20):
                            last_pinch_click_time = current_time
                            mouse.left_click(pinch_start_pos[0], pinch_start_pos[1])
                            gesture_text = "Left Click (Pinch 🤏)"
                            gesture_color = (0, 165, 255)

                if is_pinching:
                    moved = math.hypot(smooth_x - pinch_start_pos[0], smooth_y - pinch_start_pos[1])
                    pinch_duration = current_time - pinch_start_time
                    if not in_drag and pinch_duration >= 0.32 and moved > 20:
                        in_drag = True
                        mouse.start_left_drag(smooth_x, smooth_y)

                    if in_drag:
                        mouse.update_left_drag(smooth_x, smooth_y)
                        gesture_text = "Moving Window (Left Drag ✊)"
                        gesture_color = (0, 0, 255)
                    else:
                        gesture_text = "Pinch (Hold to Drag 🤏)"
                        gesture_color = (0, 165, 255)

                # 3. PEACE SIGN SCROLL
                elif index_extended and middle_extended and ring_curled and pinky_curled and (dist(index_tip, middle_tip) / palm_scale > 0.16):
                    has_fired_right = False
                    hand_y = (index_mcp[1] + middle_mcp[1]) / 2.0
                    if last_peace_y is not None:
                        delta_y = last_peace_y - hand_y
                        if delta_y > 0.002:
                            mouse.scroll(delta_y * 1800)
                            gesture_text = "Scrolling Up ⬆️"
                            gesture_color = (255, 255, 0)
                        elif delta_y < -0.002:
                            mouse.scroll(delta_y * 1800)
                            gesture_text = "Scrolling Down ⬇️"
                            gesture_color = (255, 255, 0)
                        else:
                            gesture_text = "Peace Sign ✌️ (Scroll Ready)"
                            gesture_color = (200, 200, 0)
                    last_peace_y = hand_y

                # 4. POINTING INDEX MOVE
                elif (index_extended or dist(wrist, index_tip) > dist(wrist, middle_tip) * 1.15) and middle_curled and (ring_curled or pinky_curled):
                    has_fired_right = False
                    last_peace_y = None
                    mouse.move(smooth_x, smooth_y)
                    gesture_text = "Pointing (Moving Pointer)"
                    gesture_color = (0, 255, 0)
                    cx, cy = int(index_tip[0] * w), int(index_tip[1] * h)
                    cv2.circle(frame, (cx, cy), 14, (0, 255, 0), 2)
                    cv2.line(frame, (cx - 18, cy), (cx + 18, cy), (0, 255, 0), 2)
                    cv2.line(frame, (cx, cy - 18), (cx, cy + 18), (0, 255, 0), 2)
                else:
                    has_fired_right = False
                    last_peace_y = None
                    gesture_text = "Neutral Hand"
                    gesture_color = (180, 180, 180)

        cv2.rectangle(frame, (10, 10), (w - 10, 50), (20, 20, 20), -1)
        cv2.putText(frame, f"Gesture: {gesture_text}", (20, 38), cv2.FONT_HERSHEY_SIMPLEX, 0.75, gesture_color, 2)

        cv2.imshow("HandMouse (Press 'q' to quit)", frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break

    cap.release()
    cv2.destroyAllWindows()


if __name__ == "__main__":
    main()
