# Mediatron  
Hollywood-Grade Media Processing Studio for Apple Silicon  
[![macOS 14+](https://img.shields.io/badge/macOS-14+-000000?logo=apple)]() [![Swift 6](https://img.shields.io/badge/Swift-6.3-FA7343?logo=swift)]() [![arm64](https://img.shields.io/badge/arch-arm64-blue)]() [![License](https://img.shields.io/badge/license-MIT-green)]()  
**100% Offline. 100% Private. Native Apple Silicon.**
---
## About
Mediatron is a native macOS application that processes video files using the full power of Apple Silicon — FFmpeg with VideoToolbox hardware encode, whisper.cpp for neural transcription, and ffprobe for integrity validation. No cloud uploads. No telemetry. No analytics. Your media stays on your Mac.

Designed in the Swiss International Style with Framer Motion-equivalent spring physics, LiquidUI window engineering, and complete keyboard accessibility.

### Performance Benchmarks
| Input | Output | Time |
|-------|--------|------|
| 831KB 640x360 H.264 | 45MB 7680x4320 HEVC (8K) | 6.7s |
| 10MB 1080p H.264 | ~50MB 4K HEVC | ~4s |

### Design Awards Target
Built to Apple macOS HIG standards with: interactive spring physics, .ultraThin material, custom NSWindow radius, Swiss typography, and ⌘K command palette.

---
## Table of Contents
- Installation
- Usage
- Pipeline Architecture
- Design System
- Keyboard Shortcuts
- Development
- Spec-Kit
- License

---
## Installation

### Download
Download Mediatron.dmg from Releases. Drag Mediatron.app to /Applications.

### Requirements
macOS 14+ (Sonoma), Apple Silicon (M1/M2/M3/M4)

### Build from Source
```bash
git clone https://github.com/krishnasureshcpa/Mediatron.git
cd Mediatron
bash quickbuild.sh
open Mediatron.app
```

### Dependencies
FFmpeg v8+ and whisper.cpp auto-installed via Settings > Engines > Install Engines.

---
## Usage
1. Launch Mediatron
2. Drag video files or folders onto the drop zone, or use CmdO / CmdShiftO
3. Select a preset: Web Optimized, Cinema Dub 4K, Transcribe Only, 8K Master
4. Toggle options: dubbing, lip-sync, voice cloning, upscaling, subtitles
5. Press CmdEnter or click PROCESS QUEUE
6. Files process one at a time with live progress
7. Completed files show clickable output paths

### Output Location
Processed files save next to the source file as filename_dubbed.mp4. Enable Replace Original to swap the processed file over the source with a backup.

---
## Pipeline Architecture
```
Input File  
  -> Stage 1: ffprobe (duration, codec, resolution, bitrate)  
  -> Stage 2: whisper.cpp (language detection, SRT generation)  
  -> Stage 3: ffmpeg + VideoToolbox (upscale, encode, audio, subtitles)  
  -> Stage 4: ffprobe integrity check (duration validation)  
  -> Output: clickable file that opens in Finder
```

---
## Design System

### SX Tokens (Swiss International Style)
| Token | Value | Purpose |
|-------|-------|--------|
| SX.canvas | #FFFFFF | App background |
| SX.surface | #F2F2F2 | Cards, panels |
| SX.textPrimary | #000000 | Headlines |
| SX.accent | #FF3000 | Swiss Red CTAs |
| SX.border | black 15% | Rectangular borders |

### Animation Spring Physics
| Preset | Response | Damping | Use |
|--------|----------|---------|-----|
| spSnap | 0.25 | 0.9 | Toggles |
| spStandard | 0.35 | 0.75 | UI changes |
| spGentle | 0.5 | 0.8 | Panels |
| spDramatic | 0.6 | 0.65 | Hero entrances |
| spInteractive | 0.35 | 0.86 | Gesture-driven |

---
## Keyboard Shortcuts
| Shortcut | Action |
|----------|--------|
| CmdO | Open media files |
| CmdShiftO | Import folder |
| CmdK | Command palette |
| CmdEnter | Start processing |
| Cmd, | Preferences |
| CmdQ | Quit |

---
## Development

### File Structure
App.swift - Entry point, AppDelegate, MenuBarExtra, ContentView
Engine.swift - MediaProcessingManager, PipelineEngine, ShellRunner, DependencyBootstrapper
Views.swift - All UI views, SX design tokens, CommandPalette
Models.swift - MediaTask, ProcessingOptions, ProcessingPreset
LiquidWindow.swift - Custom NSWindow subclass
LiquidShader.metal - Metal shader for liquid gradient background

### Building
```bash
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) -target arm64-apple-macosx14.0 -framework SwiftUI -framework AppKit -framework Foundation -framework Combine -framework AVFoundation -framework UniformTypeIdentifiers -o MediatronBinary Models.swift Engine.swift Views.swift App.swift LiquidWindow.swift
```

### Icon Generation
```bash
python3.13 generate_icon.py .
```
Requires Pillow: pip install Pillow

### Code Signing
```bash
bash sign_and_notarize.sh
```

---
## Spec-Kit Documentation
Constitution: .specify/memory/constitution.md
Specification: .specify/specs/001-apple-macos-standard/spec.md
Implementation Plan: .specify/specs/001-apple-macos-standard/plan.md

---
## License
MIT  