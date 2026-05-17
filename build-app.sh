#!/bin/bash
set -euo pipefail

APP_NAME="DeepSeekMenubar"
BUILD_DIR=".build/release"
SOURCE_DIR="Sources/$APP_NAME"

# 1. Build release binary
swift build -c release --disable-sandbox

# 2. Create .app bundle structure
APP_BUNDLE="$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy binary
cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"

# 4. Copy Info.plist
cp "$SOURCE_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# 5. Copy icon
cp "$SOURCE_DIR/Resources/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"

echo "✅ Created $APP_BUNDLE"
echo "   Drag to Applications folder or run:"
echo "   open $APP_BUNDLE"
