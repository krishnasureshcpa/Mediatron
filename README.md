# Mediatron
**Hollywood-Grade Media Processing Studio for Apple Silicon**

[![macOS 14+](https://img.shields.io/badge/macOS-14+-000000?logo=apple)]() [![Swift 6](https://img.shields.io/badge/Swift-6.3-FA7343?logo=swift)]() [![arm64](https://img.shields.io/badge/arch-arm64-blue)]() [![License](https://img.shields.io/badge/license-MIT-green)]()

**100% Offline · 100% Private · Native Apple Silicon**

---

## About

Mediatron is a native macOS application that processes video files using the full power of Apple Silicon — FFmpeg with VideoToolbox hardware encode, whisper.cpp for neural transcription, and ffprobe for integrity validation. No cloud uploads. No telemetry. No analytics. Your media stays on your Mac.

### Visual Language

**Swiss International Style × Framer Premium UX**

Built on a hybrid design system: Swiss minimalism structure (white canvas, #FF3000 accent, uppercase labels, tracking-2) layered with Framer-style premium surfaces and rich backgrounds:

| Feature | Implementation |
|---------|----------------|
| Animated Backgrounds | 6 selectable themes: **Mesh** (drifting gradient blobs), **Cyber** (80s perspective neon grid + sun glow), **Retro** (cutting-mat green grid), **Fractal** (noise-based color morph), **Liquid** (metallic sheen), **Aurora** (northern lights waves) |
| Theme Switching | `ThemePickerChip` in status strip, or **⌘/** to cycle, persisted via `@AppStorage("bgTheme")` |
| Logo Preloader | `LogoPreloader` — cinematic pulsing brand mark with animated halo ring |
| Split Text Reveal | `SplitTextReveal` — character-by-character staggered spring animation |
| Hourglass Loader | `HourglassLoader` — rotating hourglass with symbol pulse, shown during processing |
| Animated Counter | `AnimatedCounter` — smoothly interpolating number display for progress |
| Glass Morphism Panels | `GlassPanel` component: `.ultraThinMaterial` + translucent white layers + inner highlight gradient + outer border |
| Bento-Style Grid | `LazyVGrid` with adaptive columns (280–420px), 10px spacing |
| Hover-Lift Cards | 1.015x scale + accent-glow shadow + `spLift` spring (0.42/0.78) |
| Status Pills | `StatusPill`: capsule-shaped with icon + status color (border + tint) |
| Gradient Progress Bars | Linear gradient fill + accent glow shadow |
| Micro-Rounded Surfaces | `rControl: 8`, `rCard: 10`, `rPanel: 18`, `rTile: 14`, `rPill: 999` |
| Command Palette | ⌘K fuzzy-search with monospaced shortcut hints |
| Fixed Window Constraints | Min 1100×720, ideal 1280×860 (prevents overflow) |
| Dark-Theme Adaptation | Automatic light veil for dark backgrounds (cyber, aurora) keeps text readable |

### Premium Components

| Component | Purpose |
|-----------|---------|
| `MeshBackground` | Animated drifting radial gradients with `.ultraThinMaterial` overlay |
| `CyberGridBackground` | Retro 80s perspective grid with neon lines + sun glow at horizon |
| `RetroGridBackground` | Cutting mat wallpaper (green grid on white) |
| `FractalGlassBackground` | Slowly morphing color blobs + fine noise dots |
| `LiquidMetalBackground` | Flowing metallic sheen (gradient + highlight blobs, blends) |
| `AuroraBackground` | Northern lights — soft animated wave bands with screen blend |
| `GlassPanel<Content>` | Translucent panel with inner highlight gradient + outer border |
| `HoverLift<Content>` | Wrapper that adds scale + glow shadow on hover |
| `StatusPill` | Capsule with icon + text + color |
| `SplitTextReveal` | Staggered character-by-character text reveal |
| `ArcText` | Text arranged along circular arc |
| `AnimatedCounter` | Smoothly interpolating number display |
| `HourglassLoader` | Rotating hourglass animation |
| `LogoPreloader` | Cinematic pulsing brand mark with halo |
| `KineticNav` | Animated active-tab indicator nav |
| `ScrollProgressIndicator` | Thin gradient scroll-progress bar |
| `LiquidMetalView` | Shimmer overlay for surfaces |
| `ThemePickerChip` | One-tap theme cycle pill |

### Performance Benchmarks
| Input | Output | Time |
|-------|--------|------|
| 831KB 640×360 H.264 | 45MB 7680×4320 HEVC (8K) | 6.7s |
| 10MB 1080p H.264 | ~50MB 4K HEVC | ~4s |

### Design Awards Target
Built to Apple macOS HIG standards with: interactive spring physics, `.ultraThinMaterial`, custom NSWindow radius, Swiss typography, and ⌘K command palette.

---

## Table of Contents
- [Installation](#installation)
- [Usage](#usage)
- [Pipeline Architecture](#pipeline-architecture)
- [Design System](#design-system)
- [Keyboard Shortcuts](#keyboard-shortcuts)
- [Development](#development)
- [License](#license)

---

## Installation

### Download
Download `Mediatron.dmg` from [Releases](https://github.com/krishnasureshcpa/Mediatron/releases). Drag `Mediatron.app` to `/Applications`.

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
FFmpeg v8+ and whisper.cpp auto-installed via Settings → Engines → Install Engines.

---

## Usage
1. Launch Mediatron
2. Drag video files or folders onto the drop zone, or use **⌘O** / **⌘⇧O**
3. Select a preset: **Web Optimized**, **Cinema Dub 4K**, **Transcribe Only**, **8K Master**
4. Toggle options: dubbing, lip-sync, voice cloning, upscaling, subtitles
5. Press **⌘Enter** or click **PROCESS QUEUE**
6. Files process **one at a time** (sequential) with live progress
7. Completed files show clickable output paths with Finder reveal

### Output Location
Processed files save next to the source file as `filename_dubbed.mp4`. Enable **Replace Original** to swap the processed file over the source with a backup.

---

## Pipeline Architecture
```
Input File
  → Stage 1: ffprobe (duration, codec, resolution, bitrate)
  → Stage 2: whisper.cpp (language detection, SRT generation)
  → Stage 3: ffmpeg + VideoToolbox (upscale, encode, audio, subtitles)
  → Stage 4: ffprobe integrity check (duration validation)
  → Output: clickable file that opens in Finder
```

Processing is **sequential**: one file fully completes all active stages before the next starts. This prevents resource contention on Apple Silicon.

---

## Design System

### SX Tokens (Swiss × Framer Hybrid)

| Token | Value | Purpose |
|-------|-------|---------|
| `SX.canvas` | `#FFFFFF` | App background |
| `SX.accent` | `#FF3000` | Swiss Red CTAs, accent glows |
| `SX.textPrimary` | `#000000` | Headlines |
| `SX.textSecondary` | `#4D4D4D` | Body text |
| `SX.border` | `black.opacity(0.15)` | Rectangular borders |
| `SX.glassSoft` | `white.opacity(0.55)` | Translucent card layer |
| `SX.glassMid` | `white.opacity(0.78)` | Toolbar / strip layer |
| `SX.glassHard` | `white.opacity(0.94)` | Near-opaque panel |
| `SX.glowRed` | `#FF3000.opacity(0.20)` | Accent hover-glow shadow |
| `SX.glowSoft` | `black.opacity(0.08)` | Soft ambient shadow |
| `SX.glassEdge` | `white.opacity(0.9)` | Inner highlight gradient |
| `SX.glassBorder` | `black.opacity(0.06)` | Outer border tint |

### Mesh Gradient Anchors

| Token | Value | Purpose |
|-------|-------|---------|
| `SX.meshA` | `#FFF2EA` | Warm white gradient blob (accent tint) |
| `SX.meshB` | `#F1F8FF` | Cool white gradient blob (blue tint) |
| `SX.meshC` | `#FFEAEE` | Pink whisper gradient blob |
| `SX.meshD` | `#F5FFF1` | Mint whisper gradient blob |

### Animation Spring Physics

| Preset | Response | Damping | Use |
|--------|----------|---------|-----|
| `spSnap` | 0.25 | 0.9 | Toggles, quick snaps |
| `spStandard` | 0.35 | 0.75 | UI changes |
| `spLift` | 0.42 | 0.78 | Hover-lift cards (Framer-style) |
| `spGentle` | 0.5 | 0.8 | Panel reveals |
| `spDramatic` | 0.6 | 0.65 | Hero entrances |
| `spInteractive` | 0.35 | 0.86 | Gesture-driven |
| `spBouncy` | 0.5 | 0.6 | Spring overshoot |
| `spFluid` | 0.3 | 0.82 | Flow transitions |

### Micro-Rounded Radii

| Token | Value | Use |
|-------|-------|-----|
| `SX.rPill` | `999` | Pill/capsule shapes |
| `SX.rTile` | `14` | Bento cards, preset tiles |
| `SX.rPanel` | `18` | Glass panels, main surfaces |
| `SX.rCard` | `10` | Task cards, secondary panels |
| `SX.rControl` | `8` | Buttons, inputs, small controls |

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| **⌘O** | Open media files |
| **⌘⇧O** | Import folder |
| **⌘K** | Command palette |
| **⌘/** | Cycle background theme |
| **⌘Enter** | Start processing |
| **⌘,** | Preferences |
| **⌘Q** | Quit |

---

## Development

### File Structure
```
App.swift              — Entry point, AppDelegate, MenuBarExtra, ContentView
Engine.swift           — MediaProcessingManager, PipelineEngine, ShellRunner, DependencyBootstrapper
Views.swift            — Main UI views, SX design tokens, premium card components
FramerComponents.swift — Background themes, Framer-style components (LogoPreloader, SplitTextReveal, HourglassLoader, AnimatedCounter, ArcText, KineticNav, etc.)
Models.swift           — MediaTask, ProcessingOptions, ProcessingPreset
LiquidWindow.swift     — Custom NSWindow subclass (corner radius, transparency)
LiquidShader.metal     — Metal shader for liquid gradient background
```

### Building
```bash
swiftc -O \
  -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI -framework AppKit -framework Foundation \
  -framework Combine -framework AVFoundation -framework UniformTypeIdentifiers \
  -o MediatronBinary \
  Models.swift Engine.swift FramerComponents.swift Views.swift App.swift LiquidWindow.swift
```

Or use the quickbuild script:
```bash
bash quickbuild.sh
```

### Ship (Deploy + Package)
```bash
bash ship.sh
```
This:
- Runs `quickbuild.sh`
- Copies `Mediatron.app` to `/Applications/` and `~/Applications/`
- Creates `Mediatron.dmg`
- Launches the app
- Prints MD5 checksums for all three locations

### Icon Generation
```bash
python3.13 generate_icon.py .
```
Requires Pillow: `pip install Pillow`

### Code Signing & Notarization
```bash
bash sign_and_notarize.sh
```

---

## Architecture

- **Sequential processing** — one file completes all stages before the next starts (prevents M-series thermal throttling)
- **Real FFmpeg/whisper pipeline** — actual media encoding and neural transcription, not simulation
- **Output to source directory** — processed files land next to source files (not a hidden folder)
- **Finder reveal on every completed item** — direct link to output + toolbar "Output" button to reveal the folder

---

## Screenshots

### Welcome (cinematic entrance)
- Flying logo with halo ring animation (pulsing spring)
- Split text "MEDIATRON" reveals character-by-character
- Staggered particle orb reveals around the logo
- Background adapts to chosen theme (Mesh default)

### Queue (bento grid)
- Adaptive grid of glass cards (280–420px wide)
- Hover-lift on every card with accent glow shadow
- Capsule status pills + gradient progress bars + folder reveal chips

### Processing
- Rotating HourglassLoader in status strip
- Animated percentage counter that smoothly tracks overall progress
- Live status pills with status-color bounce symbols

### Background Themes (press ⌘/ to cycle)
| Theme | Vibe |
|-------|------|
| **Mesh** | Soft drifting gradient blobs — calm, premium |
| **Cyber** | Retro 80s neon horizon grid with sun glow |
| **Retro** | Green cutting-mat wallpaper |
| **Fractal** | Slowly morphing color blobs with fine-noise grain |
| **Liquid** | Flowing metallic sheen |
| **Aurora** | Northern lights wave bands |

---

## Credits

- **Icon**: generated with `generate_icon.py` (Pillow)
- **Fonts**: system Helvetica Neue (macOS)
- **Design language**: Swiss International Style × Framer Premium UX
- **Build system**: `swiftc` direct compilation (no Xcode required)

---

## License

MIT
