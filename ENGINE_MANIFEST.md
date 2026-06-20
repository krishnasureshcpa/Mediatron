# ENGINE_MANIFEST.md — Mediatron Core Media Framework Dependency Matrix

## 1. High-Performance Open-Source Core Dependencies

Mediatron achieves 100% data privacy and raw processing speed on Apple Silicon (M1–M4) by vendoring and wrapping these command-line tools and native library dependencies.

### 1.1 Video Demuxing, Decoding & Remuxing
- **Core Tool:** `FFmpeg` (Static Build v7.x+)
- **Compilation:** Target `darwin-arm64` with Apple Hardware Acceleration:
  ```bash
  ./configure --enable-audiotoolbox --enable-videotoolbox --enable-metal --enable-neon --enable-hwaccel=h264_videotoolbox --enable-hwaccel=hevc_videotoolbox
  ```
- **Purpose:** Frame-accurate extraction, low-overhead stream splitting, OTT soft-subtitles (`mov_text`), alpha-channel composite blending.

### 1.2 On-Device Speech Recognition
- **Core Tool:** `whisper.cpp` (Native C/C++ port of OpenAI Whisper)
- **Acceleration:** Apple Neural Engine (ANE) via Core ML backend, or Accelerate.framework (BLAS/AppleAMX)
- **Purpose:** Sub-minute language ID and frame-accurate word-level timestamp generation
- **Model:** Quantized `large-v3` or `medium` as `.bin` resource

### 1.3 Machine Translation (LLM)
- **Core Tool:** `llama.cpp` or Native Swift `MLX` Framework
- **Model:** `Llama-3-8B-Instruct-Q4_K_M` or `Phi-3-medium-128k-instruct`
- **Purpose:** High-context dialogue translation preserving script length and dramatic intent

### 1.4 Studio-Grade Audio & Voice Cloning
- **Core Tool:** `Bark.cpp`, `Coqui TTS` (CoreML/MPS Port)
- **Purpose:** Voice cloning analyzing structural frequency curves for humanlike English dialogue

### 1.5 Hollywood-Class Lip-Sync
- **Core Tool:** `Wav2Lip` / `SyncNet` (CoreML/ANE port via `coremltools`)
- **Purpose:** Frame-by-frame mouth region analysis with spatial warp matrices
- **Hardware:** Apple Silicon GPU via Metal Performance Shaders (MPS)

### 1.6 8K AI Tensor Upscaling
- **Core Tool:** `Real-ESRGAN-Mac` (CoreML models, ANE-optimized)
- **Purpose:** Multi-pass super-resolution reconstructing degraded textures into clean 8K

---

## 2. Native Apple Ecosystem Frameworks

- **VideoToolbox & AudioToolbox:** Direct hardware decoder/encoder interaction
- **Metal & MetalPerformanceShaders (MPS):** Custom compute kernels for frame blending, person isolation masks, noise reduction
- **CoreML / Apple Neural Engine API:** Localized model execution on dedicated silicon
- **AVFoundation (AVPlayer, AVAsset):** Playback with real-time multi-track subtitle switching

---

## 3. Processing Architecture

```
[Input: 3-Hour Foreign Video]
        │
        ▼
┌──────────────────────────────┐
│ 1. Hardware Chunk Demuxer    │  ← FFmpeg (VideoToolbox)
│    Parallel 1-min blocks     │
└─────────────┬────────────────┘
              │
    ┌─────────┴─────────┐
    ▼                   ▼
┌────────────┐    ┌────────────┐
│ 2. Whisper │    │ 5. Face    │
│    ANE     │    │    Parse   │  ← Metal/MPS
└─────┬──────┘    └─────┬──────┘
      ▼                 ▼
┌────────────┐    ┌────────────┐
│ 3. LLM     │    │ 6. 8K      │
│    MLX/    │    │    ESRGAN  │  ← CoreML/ANE
│    Llama   │    │            │
└─────┬──────┘    └─────┬──────┘
      ▼                 ▼
┌────────────┐    ┌────────────┐
│ 4. TTS     │    │ 7. LipSync │  ← Metal Neural
│    Bark/   │    │    Wav2Lip │
│    Coqui   │    │            │
└─────┬──────┘    └─────┬──────┘
      └────────┬────────┘
               ▼
┌──────────────────────────────┐
│ 8. Atomic Remux              │  ← FFmpeg
│    Output: Master .MP4/.MKV  │
└──────────────────────────────┘
```

---

## 4. Self-Healing Dependency Installer

On first launch, Mediatron:
1. Checks for Homebrew
2. Installs ffmpeg, whisper-cpp via brew
3. Downloads ML models to `~/.mediatron/models/`
4. Verifies all binaries

All processing stays on-device. No telemetry. No cloud uploads.
