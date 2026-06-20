# Mediatron — Apple Silicon Native Media Processing Studio

Hollywood-grade video processing entirely offline. Built with FFmpeg, whisper.cpp, and VideoToolbox hardware acceleration.

[![Apple Silicon](https://img.shields.io/badge/Apple%20Silicon-arm64-blue)]() [![Swift](https://img.shields.io/badge/Swift-6.3-FA7343)]() [![macOS](https://img.shields.io/badge/macOS-14+-000000)]()

---

## Features

- **Real ffmpeg/whisper pipeline** — analyze, transcribe, render, validate
- **VideoToolbox HEVC** — hardware encode at 8K (7680×4320)
- **Sequential processing** — one file at a time with per-file progress
- **Swiss International Style** — white canvas, black text, #FF3000 accent
- **Interactive springs** — Framer Motion-equivalent fluid animations
- **MenuBarExtra** — compact panel with live progress
- **⌘K Command Palette** — keyboard-driven, no animation
- **100% offline** — no cloud, no telemetry, no analytics

## Quick Start

```bash
git clone https://github.com/krishnasureshcpa/Mediatron.git
cd Mediatron && bash quickbuild.sh
open Mediatron.app
```

Or download `Mediatron.dmg` from [Releases](https://github.com/krishnasureshcpa/Mediatron/releases).

Requires macOS 14+ on Apple Silicon.

## Pipeline

```
Input → ffprobe → whisper.cpp → ffmpeg + VideoToolbox → integrity check → Output
```

## Architecture

| File | Purpose |
|------|--------|
| `App.swift` | Entry, MenuBarExtra, ContentView |
| `Engine.swift` | Processing pipeline, ShellRunner, DependencyBootstrapper |
| `Views.swift` | All UI with SX Swiss tokens |
| `Models.swift` | MediaTask, ProcessingOptions, Presets |
| `LiquidWindow.swift` | Custom NSWindow with radius + materials |

## Design System

SX tokens: `canvas` #FFF, `surface` #F2F2F2, `textPrimary` #000, `accent` #FF3000.
Animations: `.spring(response:0.25-0.6, dampingFraction:0.65-0.9)` + `.interactiveSpring`.

## Keyboard Shortcuts

⌘O open files · ⌘⇧O import folder · ⌘K palette · ⌘↩ process · ⌘, preferences

## Spec-Kit

`.specify/memory/constitution.md` · `.specify/specs/001-apple-macos-standard/`