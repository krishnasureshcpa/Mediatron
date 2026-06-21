#!/bin/bash
# ==============================================================================
# MEDIATRON ENGINE SETUP — installs the real, on-device processing dependencies.
# Idempotent: safe to re-run. Installs into ~/.mediatron (bin + models + venv).
#
# Engines installed:
#   - FFmpeg + whisper.cpp        (Homebrew)        video + speech-to-text/translate
#   - whisper large-v3 model      (HuggingFace)     ~3GB, to ~/.mediatron/models
#   - Demucs (+ soundfile)        (pip venv)        dialogue / music+SFX separation
#   - Real-ESRGAN ncnn-vulkan     (GitHub release)  ML frame upscaling
# ==============================================================================
set -uo pipefail

BIN="$HOME/.mediatron/bin"
MODELS="$HOME/.mediatron/models"
VENV="$HOME/.mediatron/demucs-venv"
mkdir -p "$BIN" "$MODELS" "$MODELS/realesrgan"

log() { echo "[mediatron-setup] $*"; }

# ── Homebrew (only if missing; uses the REAL installer URL) ──
BREW="/opt/homebrew/bin/brew"
if [ ! -x "$BREW" ]; then
  log "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── FFmpeg + whisper.cpp ──
command -v ffmpeg     >/dev/null 2>&1 || { log "Installing ffmpeg...";      "$BREW" install ffmpeg; }
command -v whisper-cli >/dev/null 2>&1 || { log "Installing whisper-cpp..."; "$BREW" install whisper-cpp; }

# ── whisper large-v3 model (skip if a real ~3GB file already exists) ──
WMODEL="$MODELS/ggml-large-v3.bin"
if [ ! -f "$WMODEL" ] || [ "$(stat -f%z "$WMODEL" 2>/dev/null || echo 0)" -lt 1000000000 ]; then
  log "Downloading whisper large-v3 (~3GB)..."
  curl -fL --retry 3 -o "$WMODEL.part" \
    "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-large-v3.bin?download=true" \
    && mv "$WMODEL.part" "$WMODEL" && log "whisper model ready"
else
  log "whisper large-v3 already present"
fi

# ── Demucs in an isolated venv (system python3 has a working pip; brew pythons may not) ──
if [ ! -x "$VENV/bin/demucs" ]; then
  log "Creating demucs venv + installing demucs..."
  /usr/bin/python3 -m venv "$VENV"
  "$VENV/bin/python" -m pip install --upgrade pip >/dev/null
  "$VENV/bin/python" -m pip install demucs soundfile   # soundfile is REQUIRED so demucs can write stems
fi
ln -sf "$VENV/bin/demucs" "$BIN/demucs"
# Ensure soundfile is present even on pre-existing venvs (fixes "no backend to write" error)
"$VENV/bin/python" -c "import soundfile" 2>/dev/null || "$VENV/bin/python" -m pip install soundfile

# ── Real-ESRGAN ncnn-vulkan binary + real models ──
if [ ! -x "$BIN/realesrgan-ncnn-vulkan" ]; then
  log "Downloading Real-ESRGAN..."
  TMP="$(mktemp -d)"
  curl -fL --retry 3 -o "$TMP/re.zip" \
    "https://github.com/xinntao/Real-ESRGAN/releases/download/v0.2.5.0/realesrgan-ncnn-vulkan-20220424-macos.zip"
  unzip -o "$TMP/re.zip" -d "$TMP/re" >/dev/null
  cp "$TMP/re/realesrgan-ncnn-vulkan" "$BIN/"
  chmod +x "$BIN/realesrgan-ncnn-vulkan"
  cp "$TMP/re/models/"* "$MODELS/realesrgan/"
  xattr -dr com.apple.quarantine "$BIN/realesrgan-ncnn-vulkan" 2>/dev/null
  codesign --force -s - "$BIN/realesrgan-ncnn-vulkan" 2>/dev/null
  rm -rf "$TMP"
fi

log "Done. Engines installed under ~/.mediatron"
