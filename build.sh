#!/bin/bash
set -euo pipefail

# DualMac Build Script
# Compiles Swift sources and packages into build/DualMac.app

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

CONFIG="${1:-release}"
echo "==> Building DualMac ($CONFIG)..."

BUILD_DIR="$SCRIPT_DIR/build"
APP_DIR="$BUILD_DIR/DualMac.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
CACHE_DIR="/tmp/swift-cache"

mkdir -p "$CACHE_DIR" "$MACOS_DIR" "$RESOURCES_DIR"

SWIFT_FLAGS="-parse-as-library -module-cache-path $CACHE_DIR"
if [ "$CONFIG" = "release" ]; then
    SWIFT_FLAGS="$SWIFT_FLAGS -O"
fi

echo "==> Compiling Swift sources..."
swiftc $SWIFT_FLAGS \
    Sources/DualMac/Models/*.swift \
    Sources/DualMac/Services/*.swift \
    Sources/DualMac/Views/*.swift \
    Sources/DualMac/App/*.swift \
    -o "$MACOS_DIR/DualMac"

chmod +x "$MACOS_DIR/DualMac"

echo "==> Generating Info.plist..."
cat << 'EOF' > "$CONTENTS_DIR/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleExecutable</key>
    <string>DualMac</string>
    <key>CFBundleIdentifier</key>
    <string>com.dualmac.DualMac</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>DualMac</string>
    <key>CFBundleDisplayName</key>
    <string>DualMac</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <key>CFBundleIconFile</key>
    <string>AppIcon.icns</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

if [ -f "Sources/DualMac/Resources/AppIcon.icns" ]; then
    cp "Sources/DualMac/Resources/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
fi

if [ -f "Sources/DualMac/Resources/DualBadge.png" ]; then
    cp "Sources/DualMac/Resources/DualBadge.png" "$RESOURCES_DIR/DualBadge.png"
fi

echo "==> Signing bundle (ad-hoc)..."
xattr -cr "$APP_DIR" 2>/dev/null || true
codesign --force --deep --sign - "$APP_DIR"

if [ -f "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister" ]; then
    /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DIR" 2>/dev/null || true
fi

if [ ! -f "$SCRIPT_DIR/Sources/DualMac/Resources/apply_icon" ] && [ -f "$SCRIPT_DIR/Sources/DualMac/Resources/apply_icon.swift" ]; then
    swiftc -parse-as-library -module-cache-path /tmp/swift-cache "$SCRIPT_DIR/Sources/DualMac/Resources/apply_icon.swift" -o "$SCRIPT_DIR/Sources/DualMac/Resources/apply_icon"
fi

if [ -f "$SCRIPT_DIR/Sources/DualMac/Resources/apply_icon" ] && [ -f "$SCRIPT_DIR/Resources/AppIcon.png" ]; then
    "$SCRIPT_DIR/Sources/DualMac/Resources/apply_icon" "$SCRIPT_DIR/Resources/AppIcon.png" "$APP_DIR" 2>/dev/null || true
fi

echo "==> Build successful: $APP_DIR"
