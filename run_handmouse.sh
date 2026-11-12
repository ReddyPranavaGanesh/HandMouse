#!/bin/bash
# HandMouse Launcher Script

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_PATH="$DIR/HandMouse.app"

if [ ! -d "$APP_PATH" ]; then
    echo "HandMouse.app not found. Building now..."
    cd "$DIR"
    swift build -c release
    mkdir -p HandMouse.app/Contents/MacOS HandMouse.app/Contents/Resources
    cp .build/out/Products/Release/HandMouse HandMouse.app/Contents/MacOS/HandMouse
    chmod +x HandMouse.app/Contents/MacOS/HandMouse
    cp Resources/Info.plist HandMouse.app/Contents/Info.plist
    cp Resources/AppIcon.icns HandMouse.app/Contents/Resources/AppIcon.icns
    codesign --force --deep -s - HandMouse.app
fi

echo "Launching HandMouse..."
open "$APP_PATH"
