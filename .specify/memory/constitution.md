# Mediatron Constitution

## Core Values

1. **Privacy**: All processing stays on-device. Zero telemetry, cloud, or analytics.
2. **Native Speed**: Apple Silicon native. No Electron, no web wrappers. 1GB per 10s target.
3. **macOS HIG First**: System materials, SF Symbols, proper menus, keyboard navigation.
4. **Verified Output**: Integrity checks on every processed file.

## Technical Principles

### Architecture
- Swift 6+ with structured concurrency (no DispatchSemaphore in async)
- MVVM with @Observable
- Modular Engine separate from UI

### Performance
- Sub-400ms cold launch
- Idle memory under 80MB
- VideoToolbox hardware encode for all processing

### Quality
- Zero compiler errors
- Ad-hoc signed
- VoiceOver + keyboard accessible
- Output to source folder, clickable results