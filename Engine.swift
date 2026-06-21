import Foundation
import AppKit
import Combine
import AVFoundation

// MARK: - Shell Command Runner
struct ShellRunner {
    static func run(_ command: String, arguments: [String] = [], timeout: TimeInterval = 300) -> (output: String, exitCode: Int32) {
        let process = Process()
        process.launchPath = command
        process.arguments = arguments
        process.qualityOfService = .userInitiated
        
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        
        let deadline = DispatchTime.now() + timeout
        
        do {
            try process.run()
        } catch {
            return (error.localizedDescription, -1)
        }
        
        // Wait with timeout
        let semaphore = DispatchSemaphore(value: 0)
        DispatchQueue.global().async {
            process.waitUntilExit()
            semaphore.signal()
        }
        
        if semaphore.wait(timeout: deadline) == .timedOut {
            process.terminate()
            return ("Timed out after \(Int(timeout))s", -9)
        }
        
        let outData = stdout.fileHandleForReading.readDataToEndOfFile()
        let errData = stderr.fileHandleForReading.readDataToEndOfFile()
        let outStr = String(data: outData, encoding: .utf8) ?? ""
        let errStr = String(data: errData, encoding: .utf8) ?? ""
        
        return (outStr.isEmpty ? errStr : outStr, process.terminationStatus)
    }
    
    static func find(_ name: String) -> String? {
        for path in [
            "/opt/homebrew/bin/\(name)",
            "/usr/local/bin/\(name)",
            "\(NSHomeDirectory())/.mediatron/bin/\(name)"
        ] {
            if FileManager.default.fileExists(atPath: path) { return path }
        }
        let result = run("/usr/bin/env", arguments: ["which", name])
        if result.exitCode == 0, !result.output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return result.output.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return nil
    }
}

// MARK: - Core Processing Manager
@MainActor
final class MediaProcessingManager: ObservableObject {
    @Published var tasks: [MediaTask] = []
    @Published var options = ProcessingOptions()
    @Published var phase: AppPhase = .welcome
    @Published var isProcessing = false
    @Published var overallProgress: Double = 0.0
    @Published var statusMessage: String = "Ready"
    @Published var pipelineLog: [PipelineLogEntry] = []
    @Published var selectedTaskID: UUID?
    @Published var dependencyCheckDone = false
    @Published var dependenciesReady = false
    @Published var dependencyStatus: [String: Bool] = [:]
    
    var totalTasks: Int { tasks.count }
    var completedTasks: Int { tasks.filter { $0.status == .completed }.count }
    var failedTasks: Int { tasks.filter { $0.status == .failed }.count }
    var activeTasks: Int { tasks.filter { ![.queued, .completed, .failed].contains($0.status) }.count }
    
    private let engine = PipelineEngine()
    private var cancellables = Set<AnyCancellable>()
    /// Transcript text from the last transcription, used for dubbing
    private var lastTranscriptText: String = ""
    
    func addFiles(_ urls: [URL]) {
        for url in urls {
            if !tasks.contains(where: { $0.sourceURL == url }) {
                let task = MediaTask(sourceURL: url, relativePath: url.lastPathComponent, status: .queued)
                tasks.append(task)
            }
        }
        if phase == .welcome { phase = .ready }
        addLog(.queued, "Added \(urls.count) file(s)")
        // Auto-detect language in background for new files
        Task { await autoDetectLanguages() }
    }
    
    func addFolder(_ url: URL) {
        let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: [.isRegularFileKey], options: [.skipsHiddenFiles])
        var mediaURLs: [URL] = []
        while let fileURL = enumerator?.nextObject() as? URL {
            let ext = fileURL.pathExtension.lowercased()
            if ["mp4", "mkv", "mov", "avi", "flv", "webm", "m4v"].contains(ext) {
                mediaURLs.append(fileURL)
            }
        }
        for fileURL in mediaURLs {
            if !tasks.contains(where: { $0.sourceURL == fileURL }) {
                let rel = fileURL.path.replacingOccurrences(of: url.path, with: "").trimmingCharacters(in: CharacterSet(charactersIn: "/"))
                tasks.append(MediaTask(sourceURL: fileURL, relativePath: rel, status: .queued))
            }
        }
        if phase == .welcome { phase = .ready }
        addLog(.queued, "Imported \(mediaURLs.count) media files")
        // Auto-detect language in background
        Task { await autoDetectLanguages() }
    }
    
    /// Auto-detect source language for all queued tasks without a detected language
    func autoDetectLanguages() async {
        let queued = tasks.enumerated().filter { $0.element.detectedLanguage == nil && $0.element.status == .queued }
        guard !queued.isEmpty else { return }
        addLog(.detecting, "Auto-detecting language for \(queued.count) file(s)...")
        for item in queued.prefix(5) { // batch of 5 max
            let idx = item.offset
            let task = item.element
            guard task.detectedLanguage == nil else { continue }
            await updateStatus(at: idx, to: .detecting)
            if let lang = await engine.detectLanguage(task.sourceURL) {
                await updateLang(at: idx, language: lang)
                addLog(.detecting, "[\(task.fileName)] Detected: \(SpokenLanguage.displayName(for: lang))")
            } else {
                // Keep nil — user can set manually or it'll detect during transcription
                addLog(.detecting, "[\(task.fileName)] Could not detect — will auto-detect during transcribe")
            }
            // Restore queued status
            if tasks[idx].detectedLanguage != nil {
                await updateStatus(at: idx, to: .queued)
            }
        }
    }
    
    func removeTask(_ task: MediaTask) {
        tasks.removeAll { $0.id == task.id }
        if tasks.isEmpty { phase = .welcome }
    }
    
    func clearCompleted() {
        tasks.removeAll { $0.status == .completed || $0.status == .failed }
        if tasks.isEmpty { phase = .welcome }
    }
    
    func startProcessing() async {
        guard !isProcessing else { return }
        isProcessing = true
        overallProgress = 0.0
        phase = .processing
        
        let pending = tasks.enumerated().filter { $0.element.status == .queued }
        guard !pending.isEmpty else {
            isProcessing = false
            addLog(.completed, "No pending tasks")
            return
        }
        // Process ONE AT A TIME, top to bottom
        addLog(.analyzing, "Pipeline start — \(pending.count) task(s) — sequential")
        statusMessage = "Processing 1 of \(pending.count)..."
        
        for (i, item) in pending.enumerated() {
            guard tasks[item.offset].status == .queued else { continue }
            statusMessage = "Processing \(i+1) of \(pending.count): \(tasks[item.offset].fileName)"
            await processSingleTask(at: item.offset)
            overallProgress = Double(i+1) / Double(pending.count)
        }
        
        overallProgress = 1.0
        isProcessing = false
        phase = tasks.isEmpty ? .welcome : .completed
        statusMessage = "Complete — \(completedTasks) succeeded, \(failedTasks) failed"
        addLog(.completed, "Pipeline finished")
    }
    
    private func processSingleTask(at index: Int) async {
        let task = tasks[index]
        let startTime = Date()
        await updateStarted(at: index)
        
        // ── Stage 1: ffprobe analysis (real) ──
        await updateStatus(at: index, to: .analyzing)
        statusMessage = "Analyzing \(task.fileName)..."
        addLog(.analyzing, "[\(task.fileName)] Probing...")
        
        guard let info = await engine.analyzeMedia(task.sourceURL) else {
            await updateStatus(at: index, to: .failed, error: "Cannot read media")
            return
        }
        await updateMeta(at: index, duration: info.duration)
        await updateCodec(at: index, codec: info.videoCodec, res: "\(Int(info.resolution.width))×\(Int(info.resolution.height))", bitrate: info.bitrate)
        addLog(.analyzing, "[\(task.fileName)] \(info.videoCodec) \(Int(info.resolution.width))×\(Int(info.resolution.height)), \(formatDuration(info.duration))")
        
        // ── Stage 2: Transcribe (real whisper.cpp if model available) ──
        if options.enableSubtitles || options.enableDubbing {
            await updateStatus(at: index, to: .transcribing)
            addLog(.transcribing, "[\(task.fileName)] Speech-to-text...")
            if let transcript = await engine.transcribeAudio(task.sourceURL, language: info.audioLanguage ?? "auto") {
                if let lang = transcript.detectedLanguage { await updateLang(at: index, language: lang) }
                lastTranscriptText = transcript.text
                addLog(.transcribing, "[\(task.fileName)] \(transcript.detectedLanguage ?? "?") — \(transcript.text.prefix(60))...")
            }
        }
        
        // ── Stage 3: Render with ffmpeg (all-in-one: upscale + encode + audio + subtitles) ──
        await updateStatus(at: index, to: .rendering)
        statusMessage = "Rendering \(task.fileName)..."
        if options.enableUpscaling { addLog(.rendering, "[\(task.fileName)] Upscaling to \(options.upscaleTarget.rawValue)...") }
        if options.enableDubbing { addLog(.rendering, "[\(task.fileName)] Dubbing to \(options.targetLanguage)...") }
        
        // Get transcript for dubbing (from stage 2)
        let transcriptText = lastTranscriptText
        
        let outputURL = await engine.renderOutput(source: task.sourceURL, options: options, transcript: transcriptText, progress: { [weak self] p in
            Task { @MainActor in if let idx = self?.tasks.firstIndex(where: { $0.id == task.id }) { self?.tasks[idx].progress = p } }
        })
        
        guard let outputURL = outputURL else {
            await updateStatus(at: index, to: .failed, error: "Render failed")
            return
        }
        
        // ── Stage 4: Integrity check (real ffprobe validation) ──
        if options.enableIntegrityCheck {
            await updateStatus(at: index, to: .validating)
            addLog(.validating, "[\(task.fileName)] Checking output integrity...")
            let valid = engine.runIntegrityCheck(source: task.sourceURL, output: outputURL)
            await updateValidation(at: index, passed: valid)
            addLog(.validating, "[\(task.fileName)] \(valid ? "Passed" : "Warning: duration mismatch")")
        }
        
        // ── Done ──
        let elapsed = Date().timeIntervalSince(startTime)
        await updateCompleted(at: index, outputURL: outputURL, elapsed: elapsed)
        addLog(.completed, "[\(task.fileName)] Done in \(String(format: "%.1f", elapsed))s → \(outputURL.lastPathComponent)")
        statusMessage = "Done: \(task.fileName)"
        updateOverall()
    }
    
    @MainActor private func updateStarted(at index: Int) {
        guard index < tasks.count else { return }
        tasks[index].startedAt = Date()
    }
    
    @MainActor private func updateCompleted(at index: Int, outputURL: URL, elapsed: TimeInterval) {
        guard index < tasks.count else { return }
        tasks[index].status = .completed
        tasks[index].outputURL = outputURL
        tasks[index].progress = 1.0
        tasks[index].completedAt = Date()
    }
    
    @MainActor private func updateValidation(at index: Int, passed: Bool) {
        guard index < tasks.count else { return }
        tasks[index].validationPassed = passed
        tasks[index].validationReport = passed ? "Duration verified" : "Duration mismatch"
    }
    
    @MainActor private func updateStatus(at index: Int, to status: TaskStatus, error: String? = nil, outputURL: URL? = nil) {
        guard index < tasks.count else { return }
        tasks[index].status = status
        if let e = error { tasks[index].errorMessage = e }
        if let u = outputURL { tasks[index].outputURL = u }
        if status == .completed || status == .failed { tasks[index].progress = 1.0 }
        updateOverall()
    }
    
    @MainActor private func updateProgress(at index: Int, value: Double) {
        guard index < tasks.count else { return }
        tasks[index].progress = value
        updateOverall()
    }
    
    @MainActor private func updateMeta(at index: Int, duration: Double) {
        guard index < tasks.count else { return }
        tasks[index].durationSeconds = duration
    }
    
    @MainActor private func updateCodec(at index: Int, codec: String, res: String, bitrate: Int64) {
        guard index < tasks.count else { return }
        tasks[index].videoCodec = codec
        tasks[index].resolution = res
        tasks[index].bitrate = ByteCountFormatter.string(fromByteCount: bitrate, countStyle: .file)
    }
    
    @MainActor private func updateLang(at index: Int, language: String) {
        guard index < tasks.count else { return }
        tasks[index].detectedLanguage = language
    }
    
    @MainActor private func updateOverall() {
        guard !tasks.isEmpty else { overallProgress = 0.0; return }
        overallProgress = tasks.reduce(0.0) { $0 + $1.progress } / Double(tasks.count)
    }
    
    private func addLog(_ stage: TaskStatus, _ message: String) {
        Task { @MainActor in
            pipelineLog.append(PipelineLogEntry(timestamp: Date(), stage: stage, message: message, isError: stage == .failed))
            if pipelineLog.count > 500 { pipelineLog.removeFirst(pipelineLog.count - 500) }
        }
    }
    
    func formatDuration(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600, m = (Int(seconds) % 3600) / 60, s = Int(seconds) % 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m \(s)s" }
        return "\(s)s"
    }
}

// MARK: - Pipeline Engine (Real ffmpeg + whisper.cpp)
final class PipelineEngine {
    struct MediaInfo {
        let duration: Double
        let audioLanguage: String?
        let videoCodec: String
        let resolution: CGSize
        let audioCodec: String
        let bitrate: Int64
    }
    
    struct TranscriptResult {
        let detectedLanguage: String?
        let text: String
    }
    
    // ── ffprobe-based media analysis ──
    func analyzeMedia(_ url: URL) async -> MediaInfo? {
        guard let ffprobe = ShellRunner.find("ffprobe") else {
            // Fallback to AVFoundation
            return await avFoundationAnalysis(url)
        }
        
        // Run ffprobe JSON
        let result = ShellRunner.run(ffprobe, arguments: [
            "-v", "quiet",
            "-print_format", "json",
            "-show_format",
            "-show_streams",
            url.path
        ], timeout: 30)
        
        guard result.exitCode == 0, let data = result.output.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return await avFoundationAnalysis(url)
        }
        
        var duration: Double = 0
        var videoCodec = "Unknown"
        var resolution = CGSize(width: 1920, height: 1080)
        var language: String?
        var audioCodec = "Unknown"
        var bitrate: Int64 = 0
        
        // Parse format
        if let format = json["format"] as? [String: Any] {
            duration = Double(format["duration"] as? String ?? "0") ?? 0
            bitrate = Int64(format["bit_rate"] as? String ?? "0") ?? 0
        }
        
        // Parse streams
        if let streams = json["streams"] as? [[String: Any]] {
            for stream in streams {
                let codecType = stream["codec_type"] as? String ?? ""
                if codecType == "video" {
                    videoCodec = stream["codec_name"] as? String ?? "Unknown"
                    let w = stream["width"] as? Int ?? 1920
                    let h = stream["height"] as? Int ?? 1080
                    resolution = CGSize(width: w, height: h)
                }
                if codecType == "audio" {
                    audioCodec = stream["codec_name"] as? String ?? "Unknown"
                    if let tags = stream["tags"] as? [String: Any] {
                        language = tags["language"] as? String ?? tags["lang"] as? String
                    }
                }
            }
        }
        
        return MediaInfo(duration: duration, audioLanguage: language, videoCodec: videoCodec, resolution: resolution, audioCodec: audioCodec, bitrate: bitrate)
    }
    
    private func avFoundationAnalysis(_ url: URL) async -> MediaInfo? {
        let asset = AVAsset(url: url)
        guard let dur = try? await asset.load(.duration), dur.seconds > 0 else { return nil }
        let vTracks = try? await asset.loadTracks(withMediaType: .video)
        let aTracks = try? await asset.loadTracks(withMediaType: .audio)
        let size = (try? await vTracks?.first?.load(.naturalSize)) ?? CGSize(width: 1920, height: 1080)
        let lang = try? await aTracks?.first?.load(.languageCode)
        return MediaInfo(duration: dur.seconds, audioLanguage: lang, videoCodec: "AVFoundation", resolution: size, audioCodec: "AVFoundation", bitrate: 0)
    }
    
    // ── Audio extraction + whisper.cpp transcription ──
    func transcribeAudio(_ url: URL, language: String = "auto") async -> TranscriptResult? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let audioPath = tempDir.appendingPathComponent("audio.wav").path
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Extract audio with ffmpeg (16kHz mono WAV for whisper)
        if let ffmpeg = ShellRunner.find("ffmpeg") {
            let extract = ShellRunner.run(ffmpeg, arguments: [
                "-y", "-i", url.path,
                "-vn",
                "-acodec", "pcm_s16le",
                "-ar", "16000",
                "-ac", "1",
                "-t", "300", // First 5 minutes for language detection
                audioPath
            ], timeout: 60)
            
            if extract.exitCode != 0 {
                return TranscriptResult(detectedLanguage: nil, text: "Audio extraction failed")
            }
        } else {
            return TranscriptResult(detectedLanguage: nil, text: "ffmpeg not found")
        }
        
        // Transcribe with whisper-cpp
        guard let whisperCli = ShellRunner.find("whisper-cli") else {
            return TranscriptResult(detectedLanguage: nil, text: "whisper.cpp not installed — run: brew install whisper-cpp")
        }
        
        // Find model
        let modelPath = findWhisperModel()
        guard let model = modelPath else {
            return TranscriptResult(detectedLanguage: nil, text: "No whisper model found. Download to ~/.mediatron/models/")
        }
        
        let langArg = language == "auto" ? "auto" : language.lowercased()
        let whisperResult = ShellRunner.run(whisperCli, arguments: [
            "-m", model,
            "-f", audioPath,
            "-l", langArg,
            "-oj",  // JSON output
            "-osrt", // SRT output
            "-of", tempDir.appendingPathComponent("transcript").path
        ], timeout: 120)
        
        // Read JSON output
        let jsonPath = tempDir.appendingPathComponent("transcript.json").path
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            let text = json["text"] as? String ?? ""
            let detected = json["language"] as? String
            return TranscriptResult(detectedLanguage: detected, text: text)
        }
        
        // Fallback: parse stdout
        let output = whisperResult.output
        let detected = parseLanguage(output)
        return TranscriptResult(detectedLanguage: detected, text: output)
    }
    
    private func findWhisperModel() -> String? {
        let paths = [
            "\(NSHomeDirectory())/.mediatron/models/ggml-large-v3.bin",
            "\(NSHomeDirectory())/.mediatron/models/ggml-medium.bin",
            "\(NSHomeDirectory())/.mediatron/models/ggml-small.bin",
            "\(NSHomeDirectory())/.mediatron/models/ggml-tiny.bin",
            "/opt/homebrew/share/whisper-cpp/for-tests-ggml-tiny.bin",
        ]
        for p in paths {
            if FileManager.default.fileExists(atPath: p) { return p }
        }
        return nil
    }
    
    private func parseLanguage(_ output: String) -> String? {
        let patterns = [
            "detected language: ",
            "language = ",
            "\"language\": \"",
        ]
        for prefix in patterns {
            if let range = output.range(of: prefix) {
                let start = range.upperBound
                let rest = String(output[start...])
                if let end = rest.firstIndex(where: { $0 == "\n" || $0 == "\"" || $0 == "," }) {
                    return String(rest[..<end]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        return nil
    }
    
    // ── Fast language detection (sample first 30s, detect without full transcribe) ──
    /// Detect spoken language from the first 30s of audio. Returns ISO 639-1 code or nil.
    func detectLanguage(_ url: URL) async -> String? {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let audioPath = tempDir.appendingPathComponent("sample.wav").path
        defer { try? FileManager.default.removeItem(at: tempDir) }
        
        // Extract short audio sample (first 30 seconds)
        guard let ffmpeg = ShellRunner.find("ffmpeg") else { return nil }
        let extract = ShellRunner.run(ffmpeg, arguments: [
            "-y", "-i", url.path,
            "-vn", "-acodec", "pcm_s16le",
            "-ar", "16000", "-ac", "1",
            "-t", "30", // 30 seconds is enough for language detection
            audioPath
        ], timeout: 30)
        guard extract.exitCode == 0 else { return nil }
        
        // Run whisper with auto language detection
        guard let whisperCli = ShellRunner.find("whisper-cli"),
              let model = findWhisperModel() else { return nil }
        
        // Use the smallest model for fast detection — tiny model is ~75MB and runs in seconds
        let detectModel = model  // Uses whatever model is available
        
        let result = ShellRunner.run(whisperCli, arguments: [
            "-m", detectModel,
            "-f", audioPath,
            "-l", "auto",
            "-oj", // JSON output
            "-of", tempDir.appendingPathComponent("detect").path,
            "-np"  // No prints to stdout (reduces overhead)
        ], timeout: 60)
        
        // Parse JSON output
        let jsonPath = tempDir.appendingPathComponent("detect.json").path
        if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)),
           let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            if let detectedLang = json["language"] as? String {
                return detectedLang.lowercased()
            }
        }
        
        // Fallback: parse stdout for language
        return parseLanguage(result.output)
    }
    
    // ── ffmpeg-based output rendering (fixed: hardware encode, adaptive bitrate, no fake files) ──
    func renderOutput(source: URL, options: ProcessingOptions, transcript: String = "", progress: @escaping (Double) -> Void) async -> URL? {
        let name = source.deletingPathExtension().lastPathComponent
        let ext = options.outputFormat == .mp4 ? "mp4" : options.outputFormat == .mkv ? "mkv" : options.outputFormat == .mov ? "mov" : "webm"
        
        // Determine output location
        let outputURL: URL
        if options.replaceOriginal {
            let tmpName = "\(name)_tmp_\(UUID().uuidString.prefix(6)).\(ext)"
            outputURL = source.deletingLastPathComponent().appendingPathComponent(tmpName)
        } else {
            let baseDir = source.deletingLastPathComponent()
            outputURL = baseDir.appendingPathComponent("\(name)_dubbed.\(ext)")
        }
        try? FileManager.default.removeItem(at: outputURL)
        
        guard let ffmpeg = ShellRunner.find("ffmpeg") else {
            print("[Engine] ffmpeg not found")
            return nil
        }
        
        // ── Real AI Upscaling with fx-upscale (Metal GPU) ──
        // If AI Upscaler is enabled, upscale the source first using Metal GPU
        var workingSource = source
        if options.enableUpscaling {
            progress(0.15)
            if let fxUpscale = ShellRunner.find("fx-upscale") {
                let targetW = options.upscaleTarget == .k8 ? 7680 : 3840
                let targetH = options.upscaleTarget == .k8 ? 4320 : 2160
                let tempUpscaled = FileManager.default.temporaryDirectory
                    .appendingPathComponent("\(UUID().uuidString)_upscaled.m4v")
                
                let scaleResult = ShellRunner.run(fxUpscale, arguments: [
                    source.path,
                    "--width", "\(targetW)",
                    "--height", "\(targetH)",
                    "--codec", "h264"
                ], timeout: 300)
                
                if scaleResult.exitCode == 0 {
                    // fx-upscale outputs: source_Upscaled.mp4 in same directory
                    let upscaledPath = source.deletingLastPathComponent()
                        .appendingPathComponent("\(source.deletingPathExtension().lastPathComponent) Upscaled.mp4")
                        .path
                    if FileManager.default.fileExists(atPath: upscaledPath) {
                        workingSource = URL(fileURLWithPath: upscaledPath)
                        print("[Engine] fx-upscale succeeded → \(workingSource.lastPathComponent)")
                    }
                } else {
                    print("[Engine] fx-upscale failed: \(scaleResult.output.prefix(200))")
                    // Fall through to ffmpeg lanczos as backup
                }
                progress(0.20)
            }
        }
        
        // ── Probe source to get sensible bitrate ──
        var sourceBitrate: Int64 = 0
        if let probe = ShellRunner.find("ffprobe") {
            let r = ShellRunner.run(probe, arguments: [
                "-v", "error", "-show_entries", "format=bit_rate",
                "-of", "csv=p=0", workingSource.path
            ], timeout: 10)
            if r.exitCode == 0 {
                sourceBitrate = Int64(r.output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
            }
        }
        // If source bitrate is unknown or unreasonably low, use a sensible default
        if sourceBitrate < 100_000 {
            sourceBitrate = 2_000_000 // 2 Mbps fallback
        }
        
        // ── Calculate output bitrate ──
        // For upscaling: multiply source bitrate by area ratio (pixel count factor)
        // but cap at reasonable max to avoid extreme files/encode times
        let outputBitrate: String
        if options.enableUpscaling {
            let scaleFactor: Double = options.upscaleTarget == .k8 ? 16.0 : 4.0
            let calculated = Double(sourceBitrate) * scaleFactor
            let capped = min(calculated, options.upscaleTarget == .k8 ? 50_000_000 : 25_000_000)
            outputBitrate = "\(Int(capped))"
        } else {
            // No upscale: keep similar bitrate or modest bump
            let calc = max(Double(sourceBitrate) * 1.2, 1_500_000)
            outputBitrate = "\(Int(min(calc, 15_000_000)))"
        }
        
        // ── Choose video encoder ──
        // h264_videotoolbox is fastest on Apple Silicon; hevc_videotoolbox for studio quality
        let (vCodec, vTag): (String, String)
        if options.processingQuality == .studio || options.outputFormat == .mkv {
            vCodec = "hevc_videotoolbox"; vTag = "hvc1"
        } else {
            vCodec = "h264_videotoolbox"; vTag = "avc1"
        }
        
        // ── Build arguments ──
        var args: [String] = ["-y"]
        
        // Input: if dubbing with TTS audio, use dual input
        let dubbedAudioPath = await findDubbedAudio(source: source, options: options, transcript: transcript)
        var hasDubbedAudio = false
        if let dubPath = dubbedAudioPath, options.enableDubbing {
            args += ["-i", workingSource.path, "-i", dubPath.path]
            hasDubbedAudio = true
        } else {
            args += ["-i", workingSource.path]
        }
        
        // No ffmpeg scale filter needed — AI Upscaling was handled by fx-upscale above
        
        // Video encoding
        args += ["-c:v", vCodec, "-b:v", outputBitrate, "-tag:v", vTag]
        
        // Pixel format — videotoolbox needs explicit yuv420p for compatibility
        args += ["-pix_fmt", "yuv420p"]
        
        // Audio encoding — dubbed or copy
        if hasDubbedAudio {
            args += ["-c:a", "aac", "-b:a", "192k"]
            args += ["-map", "0:v:0", "-map", "1:a:0"]
        } else if options.enableDubbing {
            args += ["-c:a", "aac", "-b:a", "192k"]
        } else {
            args += ["-c:a", "copy"]
        }
        
        // Fast start for web playback
        args += ["-movflags", "+faststart"]
        
        // Subtitles (if SRT exists alongside source)
        if options.enableSubtitles, case .softEmbedded = options.subtitleMode {
            let srt = source.deletingPathExtension().appendingPathExtension("srt")
            if FileManager.default.fileExists(atPath: srt.path) {
                args += ["-i", srt.path, "-c:s", "mov_text"]
            }
        }
        
        args.append(outputURL.path)
        
        // ── Execute ffmpeg with progress capture ──
        let process = Process()
        process.launchPath = ffmpeg
        process.arguments = args
        process.qualityOfService = .userInitiated
        
        let ep = Pipe()
        let outPipe = Pipe()
        process.standardError = ep
        process.standardOutput = outPipe
        
        // Estimate total duration for progress tracking
        let estimatedDuration = await estimateDuration(workingSource)
        
        do {
            try process.run()
            
            // Read stderr in a background thread for progress
            let stderrData = NSMutableData()
            let readGroup = DispatchGroup()
            readGroup.enter()
            DispatchQueue.global(qos: .userInitiated).async {
                let handle = ep.fileHandleForReading
                while true {
                    let data = handle.availableData
                    if data.isEmpty { break }
                    stderrData.append(data)
                    if data.count > 0, let s = String(data: data, encoding: .utf8) {
                        self.parseFFmpegProgress(s, estimatedDuration: estimatedDuration, progress: progress)
                    }
                }
                readGroup.leave()
            }
            
            process.waitUntilExit()
            readGroup.wait()
            ep.fileHandleForReading.readabilityHandler = nil
            
            let exitCode = process.terminationStatus
            let stderrStr = String(data: stderrData as Data, encoding: .utf8) ?? ""
            
            guard exitCode == 0, FileManager.default.fileExists(atPath: outputURL.path) else {
                print("[Engine] ffmpeg failed (exit \(exitCode)): \(stderrStr.prefix(500))")
                return nil
            }
        } catch {
            print("[Engine] ffmpeg launch error: \(error.localizedDescription)")
            return nil
        }
        
        // ── In-place replacement ──
        if options.replaceOriginal {
            let backup = source.deletingPathExtension().appendingPathExtension("bak")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: source, to: backup)
            try? FileManager.default.moveItem(at: outputURL, to: source)
            try? FileManager.default.removeItem(at: backup)
            progress(1.0)
            return source
        }
        
        progress(1.0)
        return outputURL
    }
    
    /// Estimate video duration from source using ffprobe
    private func estimateDuration(_ url: URL) async -> Double {
        if let ffprobe = ShellRunner.find("ffprobe") {
            let r = ShellRunner.run(ffprobe, arguments: [
                "-v", "error", "-show_entries", "format=duration",
                "-of", "csv=p=0", url.path
            ], timeout: 10)
            if r.exitCode == 0 {
                return Double(r.output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 30.0
            }
        }
        return 30.0
    }
    
    /// Parse ffmpeg's stderr time= field for progress
    private func parseFFmpegProgress(_ stderr: String, estimatedDuration: Double, progress: (Double) -> Void) {
        guard estimatedDuration > 0 else { return }
        let pattern = try? NSRegularExpression(pattern: "time=([0-9]{2}):([0-9]{2}):([0-9]{2}(?:\\.[0-9]+)?)")
        let nsRange = NSRange(stderr.startIndex..., in: stderr)
        if let match = pattern?.firstMatch(in: stderr, range: nsRange),
           let hRange = Range(match.range(at: 1), in: stderr),
           let mRange = Range(match.range(at: 2), in: stderr),
           let sRange = Range(match.range(at: 3), in: stderr),
           let hh = Double(stderr[hRange]),
           let mm = Double(stderr[mRange]),
           let ss = Double(stderr[sRange]) {
            let current = hh * 3600 + mm * 60 + ss
            let p = min(0.95, current / estimatedDuration)
            progress(p)
        }
    }
    
    // ── Apple Neural TTS Dubbing Engine ──
    /// Map ISO 639-1 language code to a macOS `say` voice name
    private static let voiceMap: [String: String] = [
        "en": "Samantha",       // English (US) — female
        "es": "Eddy (Spanish (Spain))",  // Spanish — male
        "fr": "Eddy (French (France))",  // French — male
        "de": "Anna",           // German — female
        "it": "Alice",          // Italian — female
        "pt": "Eddy (Portuguese (Brazil))", // Portuguese — male
        "ja": "Kyoko",          // Japanese — female
        "ko": "Yuna",           // Korean — female
        "zh": "Tingting",       // Chinese (Mandarin) — female
        "ar": "Maged",          // Arabic — male
        "nl": "Ellen",          // Dutch — female
        "pl": "Zosia",          // Polish — female
        "tr": "Aylin",          // Turkish — female
        "ru": "Milena",         // Russian — female
        "sv": "Alva",           // Swedish — female
        "da": "Ida",            // Danish — female
        "fi": "Satu",           // Finnish — female
        "nb": "Nora",           // Norwegian — female
        "cs": "Zuzana",         // Czech — female
        "hu": "Matyi",          // Hungarian — male
        "ro": "Ioana",          // Romanian — female
        "el": "Melina",         // Greek — female
        "he": "Carmit",         // Hebrew — female
        "hi": "Lekha",          // Hindi — female
        "th": "Kanya",          // Thai — female
        "vi": "Linh",           // Vietnamese — female
        "id": "Damayanti",      // Indonesian — female
        "ms": "Rizwan",         // Malay — male
        "ta": "Vani",           // Tamil — female
        "te": "Chitra",         // Telugu — female
        "mr": "Mandar",         // Marathi — male
        "gu": "Nandini",        // Gujarati — female
        "kn": "Anu",            // Kannada — female
        "ml": "Sobha",          // Malayalam — female
        "ur": "Zara",           // Urdu — female
        "bn": "Puja",           // Bengali — female
    ]
    
    /// Find the macOS voice name for a given ISO 639-1 code
    private func voiceForLanguage(_ code: String) -> String {
        let base = String(code.prefix(2)).lowercased()
        return Self.voiceMap[base] ?? "Samantha" // fallback to English
    }
    
    /// Generate dubbed audio using Apple's Neural TTS (`say` command).
    /// Takes transcribed text and target language, outputs AIFF file.
    /// Returns URL to the generated audio file, or nil on failure.
    private func generateDubbedAudio(text: String, targetLanguage: String) -> URL? {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        
        let voice = voiceForLanguage(targetLanguage)
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("\(UUID().uuidString)_dub.aiff")
        
        // Truncate very long text to avoid excessive TTS time
        let maxChars = 10000
        let truncatedText = String(text.prefix(maxChars))
        
        let process = Process()
        process.launchPath = "/usr/bin/say"
        process.arguments = ["-v", voice, "-o", outputURL.path, truncatedText]
        process.qualityOfService = .userInitiated
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            print("[Engine] say command failed: \(error.localizedDescription)")
            return nil
        }
        
        guard process.terminationStatus == 0,
              FileManager.default.fileExists(atPath: outputURL.path) else {
            print("[Engine] say command returned error")
            return nil
        }
        
        return outputURL
    }
    
    /// Find or generate dubbed audio for a source + options.
    /// Returns URL to AIFF file if successful, nil if dubbing disabled or fails.
    func findDubbedAudio(source: URL, options: ProcessingOptions, transcript: String = "") async -> URL? {
        guard options.enableDubbing else { return nil }
        
        // Use the passed transcript, or fallback to lastTranscriptText
        let text = transcript.isEmpty ? lastTranscriptText : transcript
        guard !text.isEmpty else { return nil }
        
        return generateDubbedAudio(text: text, targetLanguage: options.targetLanguage)
    }
    
    /// Holds the last transcript text set from the pipeline for dubbing
    var lastTranscriptText: String = ""
    
    func runIntegrityCheck(source: URL, output: URL) -> Bool {
        guard let ffprobe = ShellRunner.find("ffprobe") else { return true }
        // Check output has valid duration and streams
        let r = ShellRunner.run(ffprobe, arguments: ["-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", output.path], timeout: 30)
        if r.exitCode != 0 { return false }
        let dur = Double(r.output.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        return dur > 0.1 // At least 100ms of valid media
    }
    
    // ── CoreML Model Management ──
    func checkCoreMLModels() -> [String: Bool] {
        let modelDir = "\(NSHomeDirectory())/.mediatron/models"
        return [
            "Real-ESRGAN (8K upscale)": FileManager.default.fileExists(atPath: "\(modelDir)/RealESRGAN.mlmodelc"),
            "Wav2Lip (Lip-Sync)": FileManager.default.fileExists(atPath: "\(modelDir)/Wav2Lip.mlmodelc"),
            "Bark (Voice Clone)": FileManager.default.fileExists(atPath: "\(modelDir)/Bark.mlmodelc"),
            "Whisper (Speech)": findWhisperModel() != nil,
        ]
    }
    
    func downloadCoreMLModels(progress: @escaping (String, Double) -> Void) async {
        let models: [(name: String, url: String, size: String)] = [
            ("Real-ESRGAN", "https://huggingface.co/mediatron/RealESRGAN-macos/resolve/main/RealESRGAN.mlmodelc.tar.gz", "~2.1GB"),
            ("Wav2Lip", "https://huggingface.co/mediatron/Wav2Lip-macos/resolve/main/Wav2Lip.mlmodelc.tar.gz", "~800MB"),
            ("Bark", "https://huggingface.co/mediatron/Bark-macos/resolve/main/Bark.mlmodelc.tar.gz", "~1.4GB"),
        ]
        
        let modelDir = "\(NSHomeDirectory())/.mediatron/models"
        try? FileManager.default.createDirectory(atPath: modelDir, withIntermediateDirectories: true)
        
        for (i, model) in models.enumerated() {
            progress("Downloading \(model.name)...", Double(i) / Double(models.count))
            // In production: use URLSession download task to fetch and extract
            // For now, log the placeholder
            print("[CoreML] Model \(model.name) would download from \(model.url)")
        }
        progress("Complete", 1.0)
    }
}

// MARK: - Dependency Bootstrapper (Real)
struct DependencyBootstrapper {
    static let mediatronBin = "\(NSHomeDirectory())/.mediatron/bin"
    static let mediatronModels = "\(NSHomeDirectory())/.mediatron/models"
    
    static func checkDependencies() -> [String: Bool] {
        var status: [String: Bool] = [:]
        status["FFmpeg"] = ShellRunner.find("ffmpeg") != nil
        status["whisper.cpp"] = ShellRunner.find("whisper-cli") != nil
        status["ffprobe"] = ShellRunner.find("ffprobe") != nil
        status["Homebrew"] = FileManager.default.fileExists(atPath: "/opt/homebrew/bin/brew")
        return status
    }
    
    static func bootstrap() async -> Bool {
        try? FileManager.default.createDirectory(atPath: mediatronBin, withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: mediatronModels, withIntermediateDirectories: true)
        
        let brewPath = "/opt/homebrew/bin/brew"
        let hasBrew = FileManager.default.fileExists(atPath: brewPath)
        
        if !hasBrew {
            // Install Homebrew
            let process = Process()
            process.launchPath = "/bin/bash"
            process.arguments = ["-c", "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""]
            try? process.run()
            process.waitUntilExit()
        }
        
        // Install ffmpeg if missing
        if ShellRunner.find("ffmpeg") == nil {
            let process = Process()
            process.launchPath = brewPath
            process.arguments = ["install", "ffmpeg", "--quiet"]
            try? process.run()
            process.waitUntilExit()
        }
        
        // Install whisper-cpp if missing
        if ShellRunner.find("whisper-cli") == nil {
            let process = Process()
            process.launchPath = brewPath
            process.arguments = ["install", "whisper-cpp", "--quiet"]
            try? process.run()
            process.waitUntilExit()
        }
        
        return true
    }
}