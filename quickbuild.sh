#!/bin/bash
cd /Users/sgkrishna/MasterBase/Mediatron
rm -f MediatronBinary
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI -framework AppKit -framework Foundation \
  -framework Combine -framework AVFoundation -framework UniformTypeIdentifiers \
  -o MediatronBinary \
  Models.swift Engine.swift FramerComponents.swift Views.swift App.swift LiquidWindow.swift
EC=$?
if [ -f MediatronBinary ]; then
  echo "OK: $(file MediatronBinary | cut -d: -f2)"
  echo "SIZE: $(du -h MediatronBinary | cut -f1)"
  mv MediatronBinary Mediatron.app/Contents/MacOS/Mediatron
  echo "DEPLOYED to .app bundle"
else
  echo "FAIL: binary not created, exit=$EC"
fi