# Mediatron v1 — Comprehensive Technical Spec Sheet

> **Application:** Mediatron.app  
> **Version:** v1.0 (build 6787768)  
> **Platform:** macOS 14.0+ (Sonoma), arm64 (Apple Silicon)  
> **Architecture:** Native SwiftUI + AppKit hybrid, compiled via swiftc  
> **Repository:** github.com/krishnasureshcpa/Mediatron  
> **Last Updated:** 2026-06-20  

---

## 1. Application Architecture Overview

### 1.1 Source Code Layout

| File | Lines | Role |
|------|-------|------|
| `App.swift` | 195 | App entry point, AppDelegate, MenuBarExtra, ContentView, Command Palette |
| `Models.swift` | 165 | Data models: MediaTask, TaskStatus, ProcessingOptions, ProcessingPreset, PipelineLogEntry |
| `Engine.swift` | 776 | Core processing engine: ShellRunner, MediaProcessingManager, PipelineEngine, DependencyBootstrapper |
| `Views.swift` | 917 | All UI views: Sidebar, TaskCards, Settings, StatusStrip, WelcomeView, DropTarget |
| `FramerComponents.swift` | 580 | Design system: SX tokens, MeshBackground, GlassPanel, HoverLift, backgrounds, LogoPreloader |
| `LiquidWindow.swift` | 19 | Custom NSWindow subclass with rounded corners and transparent title bar |
| `LiquidShader.metal` | — | Metal shader for liquid background effect (Framer-style) |

**Build:** `bash quickbuild.sh` — single swiftc invocation, no Xcode project  
**Ship:** `bash ship.sh` — build → copy to /Applications + ~/Applications → create .dmg → MD5 verify

### 1.2 Application Flow

```
[Launch] → WelcomeView (cinematic entrance)
              ↓ (user drops/opens files)
         ContentView (HSplitView)
              ↓ (user clicks Process)
         Sequential Pipeline (one file at a time)
              ├─ Stage 1: ffprobe / AVFoundation Analysis
              ├─ Stage 2: Whisper.cpp Transcription (optional)
              ├─ Stage 3: fx-upscale Metal GPU (optional AI Upscaler)
              ├─ Stage 4: ffmpeg VideoToolbox Render
              └─ Stage 5: ffprobe Integrity Validation
              ↓
         [Output: _dubbed.mp4 next to source]
```

### 1.3 Pipeline Stages (Current Implementation)

> **Note:** Stages marked [PLANNED] exist as toggles in the UI but have no backend implementation yet.

| # | Stage | Toggle | Status | Time (5s clip) |
|---|-------|--------|--------|----------------|
| 1 | Media Analysis | Always on | ✅ Real (ffprobe + AVFoundation fallback) | < 1s |
| 2 | Speech Recognition | enableSubtitles / enableDubbing | ✅ Real (whisper.cpp) | 3-30s (depends on model size) |
| 3 | AI Upscaling | enableUpscaling | ✅ Real (fx-upscale Metal GPU) | 0-2s |
| 4 | Video Encoding | Always on | ✅ Real (ffmpeg + VideoToolbox) | 0.3-2s |
| 5 | Integrity Check | enableIntegrityCheck | ✅ Real (ffprobe duration validation) | < 1s |
| 6 | Dubbing | enableDubbing | ❌ [PLANNED] — Backend not implemented | — |
| 7 | Lip-Sync | enableLipSync | ❌ [PLANNED] — Backend not implemented | — |
| 8 | Voice Cloning | enableVoiceCloning | ❌ [PLANNED] — Backend not implemented | — |

---

## 2. Build System & Compilation

### 2.1 Build Command

```bash
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) \
  -target arm64-apple-macosx14.0 \
  -framework SwiftUI -framework AppKit -framework Foundation \
  -framework Combine -framework AVFoundation -framework UniformTypeIdentifiers \
  -o MediatronBinary \
  Models.swift Engine.swift FramerComponents.swift Views.swift App.swift LiquidWindow.swift
```

**Goal:** [Single-step compilation without Xcode project — enables rapid iteration, CI/CD integration, and reproducible builds. No Swift Package Manager dependencies — purely Apple SDKs to minimize build failures and external dependency risk.]

### 2.2 Flags & Optimizations

| Flag | Value | Purpose |
|------|-------|---------|
| `-O` | Optimize | Compiler optimization for speed |
| `-target` | `arm64-apple-macosx14.0` | Apple Silicon only, minimum macOS 14 |
| Frameworks | SwiftUI, AppKit, Foundation, Combine, AVFoundation, UTType | Full Apple SDK stack |

**Goal:** [Minimal dependencies = maximum portability. No SPM/CocoaPods means any macOS machine with Xcode CLI tools can build. Trade-off: cannot use third-party Swift libraries (e.g., SwiftyJSON, Alamofire) — all parsing and networking uses Foundation stdlib.]

### 2.3 Binary Properties

| Property | Value |
|----------|-------|
| Architecture | arm64 (Apple Silicon M1-M4) |
| Binary Size | ~2.0 MB |
| App Bundle Size | ~2.0 MB (includes AppIcon.icns, Info.plist, entitlements) |
| Linkage | Static — no dylib dependencies beyond system SDK |
| Launch Time | < 0.5s (cold start) |

---

## 3. UI Framework & Design System

### 3.1 Framework Stack

| Framework | Usage |
|-----------|-------|
| **SwiftUI** | Primary UI — ContentView, Sidebar, TaskCards, Settings, WelcomeView |
| **AppKit** | NSApplicationDelegate, NSMenuItem, NSWorkspace, NSStatusBar, NSOpenPanel |
| **UniformTypeIdentifiers** | File type filtering for open panels and drag-drop |

**Goal:** [SwiftUI for rapid UI development with live previews; AppKit interop for macOS-native features (menu bar, file dialogs, Finder integration). Pure SwiftUI would lose menu bar and system integration. Pure AppKit would be 3x slower to develop.]

### 3.2 Design Tokens — `SX` Enum (FramerComponents.swift)

The design system is defined as a single `SX` enum with typealias `GX = SX` for gpu shorthand. This is the single source of truth for all visual properties.

| Token Category | Examples | Value |
|----------------|----------|-------|
| **Canvas** | `SX.canvas` | `Color.white` |
| **Surfaces** | `SX.surface`, `SX.elevated`, `SX.glass` | 0.96 white / pure white / 0.72 opacity white |
| **Accent** | `SX.accent`, `SX.accentBg`, `SX.accentMuted` | `#FF3000` (Swiss Red) — **NOT** purple `#6E5BFF` |
| **Text** | `SX.textPrimary`, `SX.textSecondary`, `SX.textTertiary` | Black / 30% gray / 50% gray |
| **Glass** | `SX.glassSoft`, `SX.glassMid`, `SX.glassHard` | 55% / 78% / 94% white opacity |
| **Radii** | `SX.rControl`, `SX.rCard`, `SX.rPanel` | 8 / 10 / 18 continuous |
| **Shadows** | `SX.shadowSm`, `SX.shadowMd`, `SX.glowRed` | 8% black / 12% black / 20% accent opacity |
| **Springs** | `SX.spStandard`, `SX.spLift`, `SX.spBouncy` | response 0.35 damp 0.75 / interactiveSpring 0.42 damp 0.78 |

**Goal:** [Single-source design tokens prevent color/dimension drift across the 917-line Views.swift. Framer-style interactive springs (matching Framer Motion's interactiveSpring) give iOS/macOS-native feel. Glassmorphism layers replicate Framer's frosted-glass components without needing a design tool.]

### 3.3 Key UI Components

| Component | File | Description |
|-----------|------|-------------|
| `MeshBackground` | FramerComponents.swift:72 | TimelineView-animated radial gradient blobs — 4 drifting color sources with sine/cosine trajectories |
| `GlassPanel` | FramerComponents.swift:110 | UltraThinMaterial + white opacity tiers + inner highlight gradient + border stroke |
| `HoverLift` | FramerComponents.swift:146 | Scale 1.015x + shadow(on hover) with accent red glow at 18px radius |
| `SplitTextReveal` | FramerComponents.swift:338 | Character-by-character staggered spring reveal — each char delayed by 35ms |
| `LogoPreloader` | FramerComponents.swift:438 | Pulsing halo ring + waveform icon with 0.9s spring loop |
| `KineticNav` | FramerComponents.swift:491 | Tab nav with accent sliding indicator |

**Goal:** [All components are built from Apple SDK primitives (Path, Canvas, TimelineView, Material) — no third-party UI libraries. This gives full control over animation timing and prevents SDK compatibility breaks on macOS updates.]

### 3.4 Background Themes

| Theme | Type | Implementation | GPU Cost |
|-------|------|----------------|----------|
| Mesh (default) | Light | 4 drifting RadialGradient blobs + ultraThinMaterial | Low — TimelineView redraws at 60fps |
| Cyber | Dark | Canvas-based perspective grid with vanishing lines + sun glow | Medium — Canvas redraws per frame |
| Retro | Light | Diamond-cut green cutting-mat grid | Low — Canvas, geometric only |
| Fractal | Light | 5 drifting color blobs + noise dot pattern overlay | Medium — Canvas + ForEach RadialGradients |
| Liquid | Light | Metallic sheen with 4 rotating highlight ellipses | Low — simple ZStack + rotations |
| Aurora | Dark | 3 sine-wave masks with screen-blended gradients | Medium — Path-based waveform rendering |

**Goal:** [6 themes give user variety without needing external assets. All use TimelineView + Canvas — zero image assets. The Mesh theme is default (lowest GPU cost, matches Framer portfolio aesthetic).]

---

## 4. Processing Pipeline — Detailed Stage Specs

---

### Stage 1: Media Analysis (`analyzeMedia`)

**Method:** `PipelineEngine.analyzeMedia(_:)` — Engine.swift:304

**Primary Tool:** `ffprobe` (from FFmpeg package)

**Technical Specs:**
- Command: `ffprobe -v quiet -print_format json -show_format -show_streams <path>`
- Timeout: 30 seconds
- Parse: JSON → Swift `[String: Any]` via `JSONSerialization`

**Fields Extracted:**

| Field | Source | Type | Example |
|-------|--------|------|---------|
| Duration | `format.duration` | Double (seconds) | 4.9049 |
| Bitrate | `format.bit_rate` | Int64 (bps) | 164597 |
| Video Codec | `streams[].codec_name` | String | h264 |
| Resolution | `streams[].width x .height` | CGSize | 854×480 |
| Audio Codec | `streams[].codec_name` | String | aac |
| Language | `streams[].tags.language` | String? | und, spa, eng |

**Fallback:** `AVFoundation` (`AVAsset.load(.duration)`) — Engine.swift:359  
**When:** ffprobe not found OR ffprobe JSON parsing fails

**Goal:** [ffprobe provides richer metadata than AVFoundation (bitrate, codec strings, container info). AVFoundation fallback ensures analysis works even without ffmpeg installed — graceful degradation. Future: add stream index detection, chapter markers, HDR metadata parsing.]

---

### Stage 2: Speech Recognition (`transcribeAudio`)

**Method:** `PipelineEngine.transcribeAudio(_:language:)` — Engine.swift:370

**Primary Tool:** `whisper-cli` (from Homebrew `whisper-cpp` formula)

**Technical Specs:**

**Audio Extraction (ffmpeg):**
```
ffmpeg -y -i <source> -vn -acodec pcm_s16le -ar 16000 -ac 1 -t 300 <temp/audio.wav>
```
- Format: 16-bit PCM, 16kHz, mono
- Max duration: 300 seconds (5 minutes) for language detection
- Timeout: 60 seconds

**Whisper.cpp Transcription:**
```
whisper-cli -m <model> -f <audio.wav> -l <lang|auto> -oj -osrt -of <temp/transcript>
```
- Output: JSON (`transcript.json`) + SRT (`transcript.srt`)
- Timeout: 120 seconds
- Language: auto-detect or explicit (e.g., `es`, `en`)

**Model Lookup Order:**
1. `~/.mediatron/models/ggml-large-v3.bin` (~3GB)
2. `~/.mediatron/models/ggml-medium.bin` (~1.5GB)
3. `~/.mediatron/models/ggml-small.bin` (~500MB)
4. `~/.mediatron/models/ggml-tiny.bin` (~150MB)
5. `/opt/homebrew/share/whisper-cpp/for-tests-ggml-tiny.bin` (~75MB, test model from brew)

**Available Engine Acceleration:**
```
whisper-cli loads:
  - BLAS backend (Accelerate.framework)
  - Metal backend (Apple GPU via ggml_metal)
  - CPU backend (Apple AMX via apple_m1 optimizations)
```
On M1 Max (tested): GPU `MTLGPUFamilyApple7`, unified memory, bfloat16 support.

**Goal:** [whisper.cpp is the fastest on-device ASR for Apple Silicon — ~10x faster than Python whisper via GPU acceleration. Progressive model fallback ensures it works on any Mac regardless of disk space. Future: add WhisperX for word-level timestamps + speaker diarization (tinydiarize integration via `--tinydiarize --tdrz <model>`).]

---

### Stage 3: AI Upscaling (`fx-upscale` integration)

**Method:** `PipelineEngine.renderOutput()` upscale block — Engine.swift:484-517

**Primary Tool:** `fx-upscale` v1.2.6 (Homebrew `fx-upscale` formula)

**Technical Specs:**
```
fx-upscale <source> --width <3840|7680> --height <2160|4320> --codec h264
```

| Flag | Value | Purpose |
|------|-------|---------|
| `--width` | 3840 (4K) / 7680 (8K) | Target horizontal resolution |
| `--height` | 2160 (4K) / 4320 (8K) | Target vertical resolution |
| `--codec` | h264 | Output codec (avc1) |

**Backend:** Metal Performance Shaders (MPS) — Apple GPU  
**Output naming:** `<source> Upscaled.mp4` (in same directory)  
**Timeout:** 300 seconds

**Fallback:** ffmpeg lanczos `scale=3840:-2:flags=lanczos` — only if fx-upscale not found

**Performance (tested on M1 Max, 854×480 source → 3840×2160):**

| Metric | Value |
|--------|-------|
| Real time | 2.09s |
| User CPU | 0.244s |
| System CPU | 0.298s |
| Output size | 6.5 MB |
| Output resolution | 3840×2160 (verified via ffprobe) |

**Goal:** [fx-upscale uses Apple Metal GPU for neural-style upscaling — not the bilinear/lanczos interpolation that the old "AI Upscaler" toggle was using. This produces genuinely sharper output with better edge reconstruction. Future targets: Replace with CoreML Real-ESRGAN model for true neural super-resolution — see ENGINE_MANIFEST.md §1.6.]

---

### Stage 4: Video Encoding (`renderOutput` ffmpeg)

**Method:** `PipelineEngine.renderOutput()` main block — Engine.swift:463-653

**Primary Tool:** `ffmpeg` (Homebrew `ffmpeg` formula, VideoToolbox-enabled)

**Encoder Selection:**

| ProcessingQuality | OutputFormat | Codec | Tag | Bitrate Strategy |
|-------------------|-------------|-------|-----|------------------|
| `.fast` or `.balanced` | Any | `h264_videotoolbox` | `avc1` | Source × 1.2, max 15Mbps |
| `.studio` | Any | `hevc_videotoolbox` | `hvc1` | Source × scale factor, max 25Mbps |
| Any | `.mkv` | `hevc_videotoolbox` | `hvc1` | (MKV typically HEVC) |

**Bitrate Calculation:**

```
sourceBitrate = ffprobe format.bit_rate (fallback 2 Mbps if < 100 Kbps)

if upscaling:
    scaleFactor = (upscaleTarget == .k8 ? 16.0 : 4.0)
    outputBitrate = min(sourceBitrate * scaleFactor, 25Mbps / 50Mbps)
else:
    outputBitrate = min(max(sourceBitrate * 1.2, 1.5Mbps), 15Mbps)
```

**Full ffmpeg Argument Template:**
```
ffmpeg -y -i <workingSource>
  -c:v <h264_videotoolbox|hevc_videotoolbox>
  -b:v <calculatedBitrate>
  -tag:v <avc1|hvc1>
  -pix_fmt yuv420p
  -c:a <aac 192k|copy>    // copy when dubbing OFF, re-encode when ON
  -movflags +faststart      // web-optimized (moov atom at front)
  [-i <srt> -c:s mov_text]  // soft subs if SRT exists
  <outputPath>
```

**Progress Tracking:**
- `parseFFmpegProgress()` — NSRegularExpression `time=(\d{2}):(\d{2}):(\d{2}(?:\.\d+)?)` on stderr
- Estimated duration from ffprobe (fallback 30s)
- Progress capped at 0.95 (last 5% for muxing completion)

**Performance (854×480, 5s clip):**

| Mode | Codec | Time | Speed |
|------|-------|------|-------|
| No upscale | h264_videotoolbox | 0.33s | 14.6x |
| No upscale | hevc_videotoolbox | 0.44s | 10.9x |
| 4K upscale (no fx) | h264_videotoolbox | 1.85s | 2.63x |
| 4K upscale (fx-upscale) | h264_videotoolbox | 0.5s (fx) + 0.3s (encode) | combined ~2s |

**Goal:** [h264_videotoolbox by default — fastest hardware encoder with best playback compatibility. hevc_videotoolbox reserved for Studio quality where file size matters. Adaptive bitrate prevents the old bug of encoding a 182KB source at 40Mbps, which both bloated the output and wasted encoding time. `-pix_fmt yuv420p` ensures VideoToolbox compatibility (common failure point). `movflags +faststart` makes output web-ready without a second pass.]

---

### Stage 5: Integrity Validation

**Method:** `PipelineEngine.runIntegrityCheck(source:output:)` — Engine.swift:687

**Tool:** `ffprobe`

```
ffprobe -v error -show_entries format=duration -of csv=p=0 <output>
```
- Checks: output file has duration > 0.1 seconds
- Returns: Bool (pass/fail)
- Stored in: `task.validationPassed`, `task.validationReport`

**Goal:** [Simple sanity check ensures ffmpeg produced valid media. If output is corrupt or empty, the task is marked as warning — user still gets the file but knows it may be broken.]

---

## 5. External Dependencies

### 5.1 Required Tools (Installed via Homebrew)

| Tool | Homebrew Formula | Version (tested) | Size | Purpose |
|------|-----------------|-------------------|------|---------|
| **FFmpeg** | `ffmpeg` | 8.1.1 | ~50MB | Decode, encode, remux, filter video/audio |
| **whisper.cpp** | `whisper-cpp` | 1.8.x | ~15MB (binary, models extra) | On-device speech-to-text |
| **fx-upscale** | `fx-upscale` | 1.2.6 | 1.7MB | Metal GPU video upscaling |

**Automatic Installer:** `DependencyBootstrapper.bootstrap()` — Engine.swift:741  
Checks for Homebrew first, installs if missing, then installs all three formulas.

**Goal:** [100% on-device, no cloud. All tools are macOS-native (ARM64) with Apple Silicon optimizations (VideoToolbox, Metal, ANE). Homebrew provides a standardized install path that self-heals on first launch.]

### 5.2 Model Downloads (First Launch)

| Model | Size | Source | Location |
|-------|------|--------|----------|
| whisper (tiny/medium/large-v3) | 75MB-3GB | HuggingFace / GitHub | `~/.mediatron/models/ggml-*.bin` |
| tinydiarize (planned) | 150MB | GitHub whisper.cpp repo | `~/.mediatron/models/ggml-*-tdrz.bin` |
| Real-ESRGAN CoreML (planned) | ~2.1GB | HuggingFace | `~/.mediatron/models/RealESRGAN.mlmodelc` |
| Wav2Lip CoreML (planned) | ~800MB | HuggingFace | `~/.mediatron/models/Wav2Lip.mlmodelc` |
| Bark TTS CoreML (planned) | ~1.4GB | HuggingFace | `~/.mediatron/models/Bark.mlmodelc` |

**Goal:** [Models download on first enable of the relevant feature. Whisper models are progressive (start with tiny for fast results, upgrade to large-v3 for accuracy). CoreML models are planned but not yet implemented — the download stubs exist at Engine.swift:707-724.]

---

## 6. Security & Sandbox

### 6.1 Entitlements (`Mediatron.entitlements`)

```xml
<key>com.apple.security.app-sandbox</key>
<false/>                          <!-- NOT sandboxed — needed to spawn subprocesses -->
<key>com.apple.security.cs.allow-unsigned-executable-memory</key>
<true/>                          <!-- JIT for ffmpeg/whisper subprocess execution -->
<key>com.apple.security.cs.disable-library-validation</key>
<true/>                          <!-- DYLD_INSERT_LIBRARIES for tool interop -->
<key>com.apple.security.files.user-selected.read-write</key>
<true/>                          <!-- Read/write files the user picks -->
<key>com.apple.security.network.client</key>
<true/>                          <!-- Download models from HuggingFace/GitHub -->
<key>com.apple.security.device.audio-input</key>
<true/>                          <!-- Microphone for direct recording -->
```

**Why NOT sandboxed:** [The app spawns child processes (ffmpeg, whisper-cli, fx-upscale) via `Process()` — macOS sandbox blocks subprocess execution. Removing sandbox is required for the CLI-tool-based pipeline architecture. Future: if all pipeline stages are replaced with in-process libraries (CoreML, MLX), sandbox can be re-enabled.]

### 6.2 Data Privacy

- **100% on-device** — no network calls during processing
- Network client only used for model downloads (user-initiated)
- No telemetry, no analytics, no crash reporting
- All temp files cleaned up via `defer` blocks
- Audio is extracted to temp dir and deleted after transcription

---

## 7. Sequential Processing Model

**Design Decision:** One file at a time, top-to-bottom, serial.

```swift
for (i, item) in pending.enumerated() {
    guard tasks[item.offset].status == .queued else { continue }
    await processSingleTask(at: item.offset)
    overallProgress = Double(i+1) / Double(pending.count)
}
```

**Why sequential:**
1. ffmpeg and whisper.cpp are CPU/GPU-intensive — parallel runs contend for the same VideoToolbox encoder and ANE
2. Progress tracking is linear and predictable (1 of N, 2 of N...)
3. Error isolation — one failed task doesn't corrupt others
4. User can see per-file progress updates in the task card

**Trade-off:** [Slower total throughput for batch processing. Future: add concurrent task limit (configurable via `maxConcurrentTasks`) when processing short clips that won't saturate GPU.]

---

## 8. Output Format & Location

### 8.1 Output Path Rules

| Option | Behavior |
|--------|----------|
| Default (no replace) | `<source_dir>/<name>_dubbed.mp4` |
| Replace Original | `<source_dir>/_tmp_<uuid>.mp4` → rename over original → delete backup `.bak` |

### 8.2 Output Codec by Format

| Format | Video Codec | Audio Codec | Container |
|--------|-------------|-------------|-----------|
| `.mp4` (default) | h264_videotoolbox / hevc_videotoolbox | AAC 192kbps / copy | MPEG-4 Part 14 |
| `.mkv` | hevc_videotoolbox | AAC 192kbps / copy | Matroska |
| `.mov` | h264_videotoolbox / hevc_videotoolbox | AAC 192kbps / copy | QuickTime |
| `.webm` | h264_videotoolbox / hevc_videotoolbox | AAC 192kbps / copy | WebM |

### 8.3 Output File Sizing Guide (5s 854×480 source)

| Mode | Codec | Bitrate | Size |
|------|-------|---------|------|
| No upscale | h264_videotoolbox | 2.4 Mbps | 1.3 MB |
| No upscale | hevc_videotoolbox | 2.4 Mbps | 3.4 MB |
| 4K upscale | h264_videotoolbox | 8 Mbps | 2.5 MB |
| 4K upscale (fx-upscale via Metal) | h264 | ~10 Mbps | 6.5 MB |

---

## 9. Planned Pipeline Enhancements (ENGINE_MANIFEST.md)

These stages are defined in `ENGINE_MANIFEST.md` but not yet implemented. They represent the full 8-stage vision.

### 9.1 Speaker Diarization (WhisperX / tinydiarize)

**Status:** [PLANNED]  
**Current state:** whisper.cpp has `--tinydiarize --tdrz <model>` flags. The `ggml-tiny.en-tdrz.bin` model (292KB) is downloaded to `~/.mediatron/models/`.  
**Integration needed:** Add `-tdrz` and `--tdrz` args to the whisper-cli call in `transcribeAudio()`. Parse speaker labels from JSON output. Store in `MediaTask.detectedLanguage` or new field.
**Goal:** [Detect Speaker A vs Speaker B in multi-person videos. Required for proper dubbing attribution — "Speaker A says X → Speaker B says Y". Without this, dubbed audio is a single monotone voice.]

### 9.2 Deep-Context Translation (Local LLM)

**Status:** [PLANNED]  
**Tool candidates:**
- `llama.cpp` `llama-cli` with Llama-3-8B-Instruct Q4_K_M
- Apple `MLX` framework (Swift-native, optimized for Apple Silicon)
- **Goal:** [Translate transcribed dialogue while preserving context (names, tone, dramatic timing). A simple dictionary replacement (like current whisper translation) loses meaning. An LLM can do literary translation — e.g., keeping idioms natural in target language.]

### 9.3 TTS Voice Cloning

**Status:** [PLANNED]  
**Tool candidates:**
- `Bark.cpp` (Suno Bark port — macOS command line)
- `Coqui TTS` (Python, XTTS-v2 model with voice cloning)
- Apple `AVSpeechSynthesizer` (built-in, no model download needed — but no cloning)
- **Goal:** [Clone the original speaker's voice from 3-5s of audio, generate new speech in target language with same vocal characteristics. Without cloning, dubbed audio sounds like a generic text-to-speech robot.]

### 9.4 Wav2Lip Neural Lip-Sync

**Status:** [PLANNED]  
**Tool candidates:**
- `Wav2Lip` CoreML port (CoreML model via coremltools conversion)
- `SyncNet` for face detection + temporal alignment
- Apple `Vision` framework for face mesh detection
- **Goal:** [Synchronize mouth movements to dubbed audio. Without this, the video shows the original speaker's mouth moving out of sync with the new audio — instantly breaks immersion. This is the difference between "YouTube auto-translate" and "Hollywood class dub".]

### 9.5 Real-ESRGAN Neural Super-Resolution

**Status:** [PHASE 1 DONE — Metal GPU via fx-upscale]  
**Next target:** [Replace `fx-upscale` with actual Real-ESRGAN CoreML model for genuine neural upscaling (vs fx-upscale's Metal interpolation-based approach). Real-ESRGAN reconstructs detail from noise — it can upscale grainy 480p footage to clean 4K, which simple interpolation cannot. Model size: ~2.1GB.]

| Approach | Source → Target | Quality | Speed (5s clip) |
|----------|----------------|---------|-----------------|
| ffmpeg lanczos (OLD) | 854×480 → 3840×2160 | Poor (blurry) | 0.3s |
| fx-upscale Metal (CURRENT) | 854×480 → 3840×2160 | Good (sharp edges) | 2s |
| Real-ESRGAN CoreML (PLANNED) | 854×480 → 3840×2160 | Excellent (detail reconstruction) | ~10-30s (estimated) |

---

## 10. Deployment & Distribution

### 10.1 Build Pipeline

```bash
# Build only
bash quickbuild.sh

# Build + ship (all destinations)
bash ship.sh
```

### 10.2 Ship Destinations

| Destination | Path | Method |
|-------------|------|--------|
| Local .app bundle | `./Mediatron.app/Contents/MacOS/Mediatron` | Binary copy to bundle |
| System Applications | `/Applications/Mediatron.app` | `cp -R` |
| User Applications | `~/Applications/Mediatron.app` | `cp -R` |
| Disk Image | `./Mediatron.dmg` | `hdiutil create -format UDZO` |

### 10.3 Post-Ship Verification

```
MD5 (Mediatron.app/Contents/MacOS/Mediatron) = e9120b99c3046be2d531836651fabdb6
MD5 (/Applications/Mediatron.app/Contents/MacOS/Mediatron) = e9120b99c3046be2d531836651fabdb6
MD5 (~/Applications/Mediatron.app/Contents/MacOS/Mediatron) = e9120b99c3046be2d531836651fabdb6
```

All three copies must have identical MD5 hashes. If not, the build is corrupted and ship fails.

### 10.4 Versioning

Git tags follow `v<major>.<minor>` pattern. Current: `v1.0` (build 6787768).  
`Info.plist` is generated at build time from git describe.

---

## 11. Known Limitations & Technical Debt

| Issue | Severity | Impact | Fix Plan |
|-------|----------|--------|----------|
| `DispatchGroup.wait()` in async context | Warning | Will become error in Swift 6 | Replace with `withTaskGroup` or `AsyncStream` |
| `NSMutableData` capture in `@Sendable` closure | Warning | Thread safety concern in Swift 6 | Use `os_unfair_lock` or `actor`-isolated buffer |
| `NSMenuItem` forced cast | Warning | No-op cast, harmless | Remove `as! NSMenuItem` |
| No actual dubbing backend | Missing Feature | "Dubbing" toggle does nothing | Implement TTS + Wav2Lip pipeline |
| No actual lip-sync backend | Missing Feature | "Lip-Sync" toggle does nothing | Implement Wav2Lip integration |
| No whisper tinydiarize integration | Missing Feature | No speaker labels | Add `--tdrz` flag to whisper-cli call |
| CoreML model downloads are stubs | Missing Feature | Models listed but never downloaded | Implement URLSession download + extraction |
| fx-upscale output path is fragile | Medium | Assumes `<source> Upscaled.mp4` naming | Use `--output` flag (not yet supported by fx-upscale) |
| No GPU memory management | Medium | Long videos may OOM on 8GB M1 | Implement tiling/chunked processing |
| Single-threaded sequential processing | Performance | N files = N × single-file time | Add configurable concurrency limit |

---

## 12. Performance Benchmarks (M1 Max, 64GB)

### 12.1 Small File (182KB, 5s, 854×480, h.264 + AAC)

| Pipeline Config | Total Time | Output Size | Notes |
|----------------|------------|-------------|-------|
| Default | 0.33s | 1.3 MB | No upscale, no transcribe |
| Default + upscale 4K | 2.09s | 6.5 MB | fx-upscale + h264 encode |
| Default + transcribe | ~3.5s | 1.3 MB | Includes audio extract + whisper tiny |
| All features maxed | ~5.5s | 6.5 MB | Transcribe + upscale + encode |

### 12.2 Medium File (10MB, ~2min, 1080p, h.264)

| Pipeline Config | Estimated Time | Bottleneck |
|----------------|---------------|------------|
| Default | ~3s | Encoding |
| + Upscale 4K | ~30s | fx-upscale frame-by-frame |
| + Transcribe | ~60s | whisper tiny: 30s, medium: 60s |
| + Both | ~90s | Combined |
| All features maxed (old code) | 12-16 MINUTES | Fixed now — was 40Mbps hevc |

### 12.3 Large File (1GB, ~20min, 4K)

| Pipeline Config | Estimated Time | Notes |
|----------------|---------------|-------|
| Default (copy audio) | ~30s | Just VideoToolbox encode |
| + Transcribe (whisper tiny) | ~10 min | 20min audio → 10min whisper tiny |
| + Transcribe (whisper large) | ~60 min | Accuracy vs speed trade-off |

**Goal:** [The current bottleneck for long videos is whisper.cpp — it processes audio in real-time or slower depending on model size. For "3-hour video in minutes" the user wants, we need parallel chunked processing: split audio into 30s chunks, transcribe in parallel on GPU, merge results. This is the next major architectural upgrade.]

---

## 13. Architecture Decision Records

### ADR-1: Subprocess Pipeline vs In-Process Libraries

**Decision:** Subprocess pipeline (ffmpeg, whisper-cli via Process)

**Rationale:** [Starting with CLI tools lets us iterate on pipeline logic without building native ML model runners. The shell-runner abstraction (`ShellRunner`) wraps Process execution with timeout and output capture. Once the pipeline is proven, individual stages can be replaced with in-process CoreML models for performance and sandbox compliance.]

**Trade-off:** [Subprocess = no sandbox. Model downloads needed for each tool. Serialization overhead from shell pipes.]

### ADR-2: Sequential vs Parallel Processing

**Decision:** Sequential (one file at a time)

**Rationale:** [Simpler code, predictable resource usage, linear progress reporting. VideoToolbox encoder is a shared resource — parallel encodes compete and can cause failures.]

**Trade-off:** [Slower for batch processing. Revisit when adding concurrent task configuration.]

### ADR-3: swiftc vs Xcode Build

**Decision:** swiftc command-line compilation

**Rationale:** [Zero IDE dependency, reproducible builds, CI-friendly, faster iteration (no project file to manage). All Apple frameworks are available via SDK flags.]

**Trade-off:** [No SwiftUI Previews (need Xcode for that). No SPM support. Manual framework management.]

---

*End of Mediatron v1 Spec Sheet — 2026-06-20*