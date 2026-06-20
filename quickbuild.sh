#!/bin/bash
cd /Users/sgkrishna/MasterBase/Mediatron

# Ensure .app bundle structure exists with icon and plist
mkdir -p Mediatron.app/Contents/MacOS Mediatron.app/Contents/Resources
cp AppIcon.icns Mediatron.app/Contents/Resources/ 2>/dev/null

# Write Info.plist (always fresh)
cat > Mediatron.app/Contents/Info.plist << 'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>Mediatron</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.krishnasureshcpa.Mediatron</string>
    <key>CFBundleName</key>
    <string>Mediatron</string>
    <key>CFBundleVersion</key>
    <string>1.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST
cp Mediatron.entitlements Mediatron.app/Contents/ 2>/dev/null

rm -f MediatronBinary
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI -framework AppKit -framework Foundation \
  -framework Combine -framework AVFoundation -framework UniformTypeIdentifiers \
  -o MediatronBinary \
  Models.swift Engine.swift FramerComponents.swift Views.swift App.swift LiquidWindow.swift
EC=$?
if [ -f MediatronBinary ]; then
  mv MediatronBinary Mediatron.app/Contents/MacOS/Mediatron
  echo "OK: $(file Mediatron.app/Contents/MacOS/Mediatron | cut -d: -f2)"
  echo "SIZE: $(du -h Mediatron.app/Contents/MacOS/Mediatron | cut -f1)"
  echo "DEPLOYED to .app bundle (icon + plist + binary)"
else
  echo "FAIL: binary not created, exit=$EC"
fi