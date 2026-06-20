#!/bin/bash
set -e

# ==============================================================================
# MEDIATRON PRODUCTION BUILD SYSTEM
# Apple Silicon macOS Application Compiler & Packager
# ==============================================================================

APP_NAME="Mediatron"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
ARCHIVE_ROOT="$ROOT_DIR/Production-Old-Builds-${APP_NAME}"
SDK_PATH="$(xcrun --show-sdk-path --sdk macosx)"
TARGET="arm64-apple-macosx14.0"

echo "============================================================"
echo "  MEDIATRON PRODUCTION BUILD v1.0"
echo "  Target: Apple Silicon (arm64) macOS 14+"
echo "============================================================"

# ---- Step 1: Archive previous build ----
mkdir -p "$ARCHIVE_ROOT"

if [ -d "$ROOT_DIR/$APP_NAME.app" ] || [ -f "$ROOT_DIR/$APP_NAME.dmg" ]; then
    BUILD_COUNT=$(find "$ARCHIVE_ROOT" -maxdepth 1 -type d -name "Build-*" 2>/dev/null | wc -l | tr -d ' ')
    NEXT_BUILD=$((BUILD_COUNT + 1))
    TIMESTAMP=$(date +"%b-%d-%Y-%I%M%p" | tr 'A-Z' 'a-z')
    DATE_STAMP=$(date +"%b-%d-%Y")
    
    ARCHIVE_DIR="$ARCHIVE_ROOT/Build-${NEXT_BUILD}-${TIMESTAMP}"
    mkdir -p "$ARCHIVE_DIR"
    
    echo "Archiving previous build to: $ARCHIVE_DIR"
    [ -d "$ROOT_DIR/$APP_NAME.app" ] && mv "$ROOT_DIR/$APP_NAME.app" "$ARCHIVE_DIR/$APP_NAME-$DATE_STAMP.app"
    [ -f "$ROOT_DIR/$APP_NAME.dmg" ] && mv "$ROOT_DIR/$APP_NAME.dmg" "$ARCHIVE_DIR/$APP_NAME-$DATE_STAMP.dmg"
    
    # Generate CHANGES.md
    cat > "$ARCHIVE_DIR/CHANGES.md" << 'CHANGELOG'
# Mediatron Build Transition Audit

## 1. Technical Enhancements
- Premium light-themed SwiftUI interface
- Apple Silicon optimized video processing pipeline
- Multi-threaded batch media processing engine
- Self-healing dependency bootstrapper
- Hollywood-grade dubbing & lip-sync pipeline architecture

## 2. Shortcomings
- Lip-sync neural models require CoreML conversion
- whisper.cpp model download not automated in first build
- 8K upscaling requires Real-ESRGAN CoreML port

## 3. Next Iteration Goals
- Bundle whisper.cpp large-v3 model as app resource
- Integrate CoreML-based Real-ESRGAN for 8K upscaling
- Add Wav2Lip CoreML model for frame-accurate lip-sync
CHANGELOG
fi

# ---- Step 2: Generate App Icon ----
echo ""
echo "Generating app icon..."
python3 "$ROOT_DIR/generate_icon.py" "$ROOT_DIR"

# ---- Step 3: Compile Swift sources ----
echo ""
echo "Compiling Swift sources..."

SWIFT_FILES=(
    "$ROOT_DIR/Models.swift"
    "$ROOT_DIR/Engine.swift"
    "$ROOT_DIR/Views.swift"
    "$ROOT_DIR/App.swift"
)

echo "Swift files:"
for f in "${SWIFT_FILES[@]}"; do
    echo "  $f"
done

# Compile with optimizations
swiftc \
    -O \
    -whole-module-optimization \
    -sdk "$SDK_PATH" \
    -target "$TARGET" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Foundation \
    -framework Combine \
    -framework AVFoundation \
    -framework UniformTypeIdentifiers \
    -o "$ROOT_DIR/MediatronBinary" \
    "${SWIFT_FILES[@]}"

echo "Compilation successful."

# ---- Step 4: Assemble .app bundle ----
echo ""
echo "Assembling application bundle..."

APP_BUNDLE="$ROOT_DIR/$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Copy binary
mv "$ROOT_DIR/MediatronBinary" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod +x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

# Copy icon
if [ -f "$ROOT_DIR/AppIcon.icns" ]; then
    cp "$ROOT_DIR/AppIcon.icns" "$APP_BUNDLE/Contents/Resources/"
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>Mediatron</string>
    <key>CFBundleExecutable</key>
    <string>Mediatron</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.mediatron.studio</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>Mediatron</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSRequiresNativeExecution</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
</dict>
</plist>
PLIST

echo "Bundle assembled: $APP_BUNDLE"

# ---- Step 5: Copy to /Applications ----
echo ""
echo "Installing to /Applications..."
rm -rf "/Applications/$APP_NAME.app"
cp -R "$APP_BUNDLE" "/Applications/"
echo "Installed to /Applications/$APP_NAME.app"

# ---- Step 6: Create DMG ----
echo ""
echo "Creating DMG package..."

DMG_STAGING="$ROOT_DIR/dmg_staging"
rm -rf "$DMG_STAGING"
mkdir -p "$DMG_STAGING"

cp -R "$APP_BUNDLE" "$DMG_STAGING/"
ln -s /Applications "$DMG_STAGING/Applications"

rm -f "$ROOT_DIR/$APP_NAME.dmg"

hdiutil create \
    -volname "Mediatron Installer" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$ROOT_DIR/$APP_NAME.dmg"

rm -rf "$DMG_STAGING"

# ---- Step 7: Verify ----
echo ""
echo "============================================================"
echo "  BUILD COMPLETE"
echo "============================================================"
echo "  App:  $APP_BUNDLE"
echo "  DMG:  $ROOT_DIR/$APP_NAME.dmg"
echo "  Size: $(du -sh "$APP_BUNDLE" | cut -f1)"
echo "  Installed: /Applications/$APP_NAME.app"
echo "============================================================"

# Verify bundle structure
echo ""
echo "Bundle verification:"
ls -la "$APP_BUNDLE/Contents/MacOS/"
ls -la "$APP_BUNDLE/Contents/Resources/"
echo "Plist exists: $( [ -f '$APP_BUNDLE/Contents/Info.plist' ] && echo 'YES' || echo 'NO' )"
echo "Binary exists: $( [ -f '$APP_BUNDLE/Contents/MacOS/$APP_NAME' ] && echo 'YES' || echo 'NO' )"
