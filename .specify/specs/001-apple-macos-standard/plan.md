# Implementation Plan: Apple macOS Standard Perfection

## Technology Stack

### Frontend
- **SwiftUI**: All views, leveraging @Observable for state
- **AppKit bridging**: NSWindow customization, NSMenu, NSStatusItem
- **Swift Concurrency**: async/await with @MainActor isolation

### Backend
- **FFmpeg**: VideoToolbox HW encode via Process calls
- **whisper.cpp**: Speech transcription via Process calls
- **ffprobe**: Media analysis and integrity validation

## Architecture

```
App.swift (Entry + Scenes)
├── ContentView (Root)
│   ├── WelcomeView (Empty state)
│   ├── SidebarView (Controls)
│   └── MainAreaView
│       ├── ToolbarView (Header)
│       ├── TaskListView (Queue)
│       │   └── TaskCard (Per-file)
│       └── StatusStrip (Footer)
├── CommandPalette (⌘K)
├── MenuBarExtra (Compact)
└── SettingsView

Engine.swift
├── MediaProcessingManager (@Observable)
│   ├── Sequential processing loop
│   ├── Real-time status updates
│   └── Progress tracking
└── PipelineEngine
    ├── analyzeMedia (ffprobe)
    ├── transcribeAudio (whisper-cli)
    ├── renderOutput (ffmpeg VideoToolbox)
    └── runIntegrityCheck (ffprobe)
```

## Design Patterns

- **MVVM**: Views observe MediaProcessingManager via @EnvironmentObject
- **Sequential Queue**: Simple for-loop, one task at a time
- **Process Management**: ShellRunner wraps Process with timeout

## Security

- All processing local via Process calls
- No network access
- File access limited to user-selected paths

## Performance Strategy

- VideoToolbox hardware encode for all video output
- ffprobe for fast media analysis
- Sequential processing avoids resource contention

## Key Files

| File | Purpose |
|------|---------|
| App.swift | App entry, MenuBarExtra, ContentView |
| Views.swift | All UI views with SX tokens |
| Engine.swift | Processing pipeline and state |
| Models.swift | Data models, presets, options |
| LiquidWindow.swift | Custom NSWindow subclass |
