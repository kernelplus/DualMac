#!/bin/bash
set -euo pipefail

# DualMac Packaging Script
# Creates both an installable macOS Disk Image (.dmg) and an Apple Installer Package (.pkg)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "==> Step 1: Building DualMac release bundle..."
./build.sh release

APP_PATH="$SCRIPT_DIR/build/DualMac.app"
BUILD_DIR="$SCRIPT_DIR/build"
VERSION="1.0.0"

if [ ! -d "$APP_PATH" ]; then
    echo "Error: $APP_PATH does not exist!" >&2
    exit 1
fi

echo "==> Step 2: Creating installable DMG (DualMac.dmg)..."
DMG_ROOT="/tmp/DualMac_dmg_stage_$$"
rm -rf "$DMG_ROOT"
mkdir -p "$DMG_ROOT"

# Copy DualMac.app
cp -R "$APP_PATH" "$DMG_ROOT/"

# Create /Applications symlink for drag-and-drop install
ln -s /Applications "$DMG_ROOT/Applications"

# Set custom volume icon on the DMG
if [ -f "Sources/DualMac/Resources/AppIcon.icns" ]; then
    cp "Sources/DualMac/Resources/AppIcon.icns" "$DMG_ROOT/.VolumeIcon.icns"
    if command -v SetFile &>/dev/null; then
        SetFile -a C "$DMG_ROOT" 2>/dev/null || true
    fi
fi

DMG_PATH="$BUILD_DIR/DualMac.dmg"
rm -f "$DMG_PATH"

hdiutil create -volname "DualMac" \
               -srcfolder "$DMG_ROOT" \
               -ov -format UDZO \
               "$DMG_PATH"

rm -rf "$DMG_ROOT"
echo "==> DMG successfully created: $DMG_PATH"

echo "==> Step 3: Creating Apple Installer Package (DualMac-$VERSION.pkg)..."
PKG_PATH="$BUILD_DIR/DualMac-$VERSION.pkg"
rm -f "$PKG_PATH"

PKG_STAGE="/tmp/pkg_stage_$$"
rm -rf "$PKG_STAGE"
mkdir -p "$PKG_STAGE"
cp -R "$APP_PATH" "$PKG_STAGE/"

pkgbuild --root "$PKG_STAGE" \
         --identifier "com.dualmac.DualMac" \
         --version "$VERSION" \
         --install-location "/Applications" \
         "$PKG_PATH"

rm -rf "$PKG_STAGE"

echo "==> PKG successfully created: $PKG_PATH"
echo ""
echo "========================================================"
echo " Packaging Complete!"
echo " 1. Drag & Drop Installer: $DMG_PATH"
echo " 2. Apple Installer PKG:   $PKG_PATH"
echo "========================================================"
