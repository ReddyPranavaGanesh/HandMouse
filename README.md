# 🖐️ HandMouse for macOS

[![Release](https://img.shields.io/github/v/release/ReddyPranavaGanesh/HandMouse?color=blue&label=Latest%20Release)](https://github.com/ReddyPranavaGanesh/HandMouse/releases/latest)
[![Platform](https://img.shields.io/badge/Platform-macOS%2013%2B-lightgrey)](https://www.apple.com/macos/)
[![Language](https://img.shields.io/badge/Swift-6.0-orange)](https://swift.org)
[![Framework](https://img.shields.io/badge/Vision%20%2B%20Metal-Hardware%20Accelerated-green)](https://developer.apple.com/documentation/vision)

A high-performance, native macOS application that tracks hand movements and recognizes gestures using your MacBook's inbuilt webcam to seamlessly control the mouse pointer, clicks, dragging, and scrolling.

Built with Apple's **Vision Framework** (`VNDetectHumanHandPoseRequest`), **AVFoundation**, **CoreGraphics**, and **SwiftUI**, running hardware-accelerated directly on the Apple Neural Engine and Metal GPU with low latency and minimal battery consumption. Featuring an authentic **Liquid Glass** macOS aesthetic.

---

## 🎯 Supported Hand Gestures

| Gesture | Real-World Hand Movement | Mouse Action | Visual Status |
| :--- | :--- | :--- | :--- |
| **1. Move Pointer** | Point your **index finger** towards the camera and move your hand | Moves mouse cursor smoothly across the screen | 🎯 **Pointing** *(Green Reticle)* |
| **2. Left Click** | Quick **pinch** (touch thumb and index tips together and release within 0.3s) | Performs an instantaneous **Left Click** | 🤏 **Left Click** *(Orange)* |
| **3. Move Windows (Drag)** | **Pinch and hold for >0.32s**, then move your hand | **Holds Left Click down** and drags the window. Release to drop! | ✊ **Moving Window (Left Drag)** *(Red)* |
| **4. Peace Sign Scroll** | Hold **2-finger Peace Sign (✌️)** and move hand **up or down** | Moving hand **upwards** scrolls **up**; moving hand **downwards** scrolls **down** | ✌️ **Scrolling Up ⬆️ / Down ⬇️** *(Cyan)* |
| **5. Right Click** | **Touch middle fingertip and thumb tip together (👌)** | Performs a **Right Click** | 👌 **Right Click (Middle + Thumb)** *(Purple)* |

---

## 🚀 Quick Start

### Option 1: Download from GitHub Releases
Download the pre-built, signed application archive directly from **[GitHub Releases (v1.2.0)](https://github.com/ReddyPranavaGanesh/HandMouse/releases/latest)**:
1. Download `HandMouse-v1.2.0-macOS.zip`.
2. Unzip and drag `HandMouse.app` to your `/Applications` folder.
3. Open `HandMouse.app`.

### Option 2: Launch Locally
Double-click `HandMouse.app` in Finder, or run in Terminal:
```bash
open HandMouse.app
```
*(Or run `./run_handmouse.sh`)*

### Option 3: Run directly from command line
```bash
./HandMouse.app/Contents/MacOS/HandMouse
```

---

## 🛠️ Requirements & macOS Permissions

To allow HandMouse to see your hand and control the cursor, macOS will request two standard permissions:

1. **Camera Access** (`NSCameraUsageDescription`):
   - HandMouse needs webcam access to capture frames for hand landmark tracking.
   - When prompted, click **Allow** (or enable in **System Settings → Privacy & Security → Camera → HandMouse**).

2. **Accessibility Access** (`CGEventPost`):
   - Required by macOS for any application synthesizing synthetic mouse clicks and movements.
   - HandMouse includes a built-in status badge and button to open **System Settings → Privacy & Security → Accessibility** to grant permission.

---

## ✨ Features & Capabilities

- **Liquid Glass macOS Design**:
  - Beautiful translucent frosted glass styling (`.ultraThinMaterial`), subtle glowing borders, and native vibrancy for an authentic modern Mac look.
- **Persistent User Settings**:
  - Dedicated **Save Settings** and **Reset Defaults** buttons with animated confirmation toasts. Settings (sensitivity, smoothing, margins, delay) automatically persist across app launches via `UserDefaults.standard`.
- **Adaptive Jitter Filter (One Euro Filter)**:
  - Eliminates micro-tremors and shaky keypoint jitter when your hand is stationary, locking the cursor steady for precise button clicking.
  - Dynamically lowers filtering at higher velocities for zero-latency flick motions.
- **Natural Mirroring**:
  - Mirrored camera view so moving your right hand to your right moves the cursor to your right, matching human muscle memory.
- **Active Reachability Zone**:
  - Configurable inner boundary margin (default 18%) ensures you can reach all four corners of your screen without stretching your arm to the edges of the webcam frame.
- **Live Skeleton Overlay**:
  - Real-time rendering of all 21 hand joints and bones with glowing target crosshairs, pinch connection lines, and gesture badges (`👌`, `🤏`, `✌️`).
- **macOS Menu Bar Extra**:
  - Menu bar icon (🖐️) lets you quickly pause/resume tracking, view recognized gestures, or bring the dashboard forward without interrupting your workflow.
- **Audio Feedback**:
  - Native macOS sounds (`Pop`, `Tink`, `Blow`) provide instant confirmation when clicking, dragging, and releasing.
- **Configurable Settings**:
  - Pointer Sensitivity slider (0.5x – 3.0x).
  - Smoothing filter tuning (Smooth vs. Responsive).
  - Pinch Sensitivity, Hold Delay, and Scroll Multipliers.
  - Optional Instant Left Click mode.

---

## 🐍 Python Alternative (Optional)

A complete standalone Python script using OpenCV, MediaPipe, and PyObjC Quartz is also included in `hand_mouse_python/`:

```bash
cd hand_mouse_python
pip install -r requirements.txt
python3 hand_mouse.py
```

---

## 📂 Project Architecture

```
Mouse Buttons/
├── HandMouse.app/               # Compiled, codesigned macOS Application Bundle
├── run_handmouse.sh             # Quick launch script
├── Package.swift                # Swift package configuration
├── Sources/
│   ├── Main.swift               # App entry point & NSApplication delegate
│   ├── AppState.swift           # Observable state, persistence & engine bindings
│   ├── CameraManager.swift      # 60fps AVCaptureSession camera pipeline
│   ├── HandPoseDetector.swift   # Apple Vision VNDetectHumanHandPoseRequest
│   ├── GestureRecognizer.swift  # 5-gesture state machine & action dispatcher
│   ├── MouseController.swift    # CoreGraphics CGEvent synthesis & audio
│   ├── OneEuroFilter.swift      # Adaptive low-pass jitter filter
│   ├── StatusItemController.swift # macOS Menu Bar extra (🖐️)
│   └── Views/
│       ├── ContentView.swift    # Main dashboard split view
│       ├── CameraPreviewView.swift # Metal preview with skeleton overlay & HUD
│       ├── GestureGuideView.swift  # Interactive visual gesture cheatsheet
│       ├── SettingsView.swift   # Speed, smoothing, sensitivity & persistence
│       └── LiquidGlassStyles.swift # Translucent frosted materials & button styles
├── Resources/
│   ├── Info.plist               # App metadata & camera usage description
│   └── AppIcon.icns             # High-resolution Retina app icon
└── hand_mouse_python/
    ├── hand_mouse.py            # Standalone OpenCV + MediaPipe script
    └── requirements.txt
```
