import SwiftUI
import UniformTypeIdentifiers

// MARK: - Language Support (whisper.cpp 99 languages + extended)
struct SpokenLanguage: Identifiable, Hashable, Codable {
    let id: String       // ISO 639-1 code (e.g., "es", "en", "zh")
    let name: String     // Display name (e.g., "Spanish", "English", "Chinese")
    
    static let auto = SpokenLanguage(id: "auto", name: "Auto-Detect")
    
    static let all: [SpokenLanguage] = [
        SpokenLanguage(id: "en", name: "English"),
        SpokenLanguage(id: "es", name: "Spanish"),
        SpokenLanguage(id: "fr", name: "French"),
        SpokenLanguage(id: "de", name: "German"),
        SpokenLanguage(id: "it", name: "Italian"),
        SpokenLanguage(id: "pt", name: "Portuguese"),
        SpokenLanguage(id: "ru", name: "Russian"),
        SpokenLanguage(id: "zh", name: "Chinese"),
        SpokenLanguage(id: "ja", name: "Japanese"),
        SpokenLanguage(id: "ko", name: "Korean"),
        SpokenLanguage(id: "ar", name: "Arabic"),
        SpokenLanguage(id: "hi", name: "Hindi"),
        SpokenLanguage(id: "bn", name: "Bengali"),
        SpokenLanguage(id: "nl", name: "Dutch"),
        SpokenLanguage(id: "pl", name: "Polish"),
        SpokenLanguage(id: "tr", name: "Turkish"),
        SpokenLanguage(id: "vi", name: "Vietnamese"),
        SpokenLanguage(id: "th", name: "Thai"),
        SpokenLanguage(id: "sv", name: "Swedish"),
        SpokenLanguage(id: "da", name: "Danish"),
        SpokenLanguage(id: "fi", name: "Finnish"),
        SpokenLanguage(id: "nb", name: "Norwegian"),
        SpokenLanguage(id: "cs", name: "Czech"),
        SpokenLanguage(id: "hu", name: "Hungarian"),
        SpokenLanguage(id: "ro", name: "Romanian"),
        SpokenLanguage(id: "uk", name: "Ukrainian"),
        SpokenLanguage(id: "el", name: "Greek"),
        SpokenLanguage(id: "he", name: "Hebrew"),
        SpokenLanguage(id: "id", name: "Indonesian"),
        SpokenLanguage(id: "ms", name: "Malay"),
        SpokenLanguage(id: "tl", name: "Filipino"),
        SpokenLanguage(id: "ta", name: "Tamil"),
        SpokenLanguage(id: "te", name: "Telugu"),
        SpokenLanguage(id: "mr", name: "Marathi"),
        SpokenLanguage(id: "gu", name: "Gujarati"),
        SpokenLanguage(id: "kn", name: "Kannada"),
        SpokenLanguage(id: "ml", name: "Malayalam"),
        SpokenLanguage(id: "pa", name: "Punjabi"),
        SpokenLanguage(id: "ur", name: "Urdu"),
        SpokenLanguage(id: "fa", name: "Persian"),
        SpokenLanguage(id: "ps", name: "Pashto"),
        SpokenLanguage(id: "ku", name: "Kurdish"),
        SpokenLanguage(id: "ne", name: "Nepali"),
        SpokenLanguage(id: "si", name: "Sinhala"),
        SpokenLanguage(id: "km", name: "Khmer"),
        SpokenLanguage(id: "my", name: "Burmese"),
        SpokenLanguage(id: "lo", name: "Lao"),
        SpokenLanguage(id: "mn", name: "Mongolian"),
        SpokenLanguage(id: "bo", name: "Tibetan"),
        SpokenLanguage(id: "dz", name: "Dzongkha"),
        SpokenLanguage(id: "ca", name: "Catalan"),
        SpokenLanguage(id: "gl", name: "Galician"),
        SpokenLanguage(id: "eu", name: "Basque"),
        SpokenLanguage(id: "cy", name: "Welsh"),
        SpokenLanguage(id: "ga", name: "Irish"),
        SpokenLanguage(id: "gd", name: "Scottish Gaelic"),
        SpokenLanguage(id: "mt", name: "Maltese"),
        SpokenLanguage(id: "sq", name: "Albanian"),
        SpokenLanguage(id: "mk", name: "Macedonian"),
        SpokenLanguage(id: "bs", name: "Bosnian"),
        SpokenLanguage(id: "hr", name: "Croatian"),
        SpokenLanguage(id: "sr", name: "Serbian"),
        SpokenLanguage(id: "sl", name: "Slovenian"),
        SpokenLanguage(id: "sk", name: "Slovak"),
        SpokenLanguage(id: "lv", name: "Latvian"),
        SpokenLanguage(id: "lt", name: "Lithuanian"),
        SpokenLanguage(id: "et", name: "Estonian"),
        SpokenLanguage(id: "is", name: "Icelandic"),
        SpokenLanguage(id: "fo", name: "Faroese"),
        SpokenLanguage(id: "hy", name: "Armenian"),
        SpokenLanguage(id: "ka", name: "Georgian"),
        SpokenLanguage(id: "az", name: "Azerbaijani"),
        SpokenLanguage(id: "kk", name: "Kazakh"),
        SpokenLanguage(id: "ky", name: "Kyrgyz"),
        SpokenLanguage(id: "tk", name: "Turkmen"),
        SpokenLanguage(id: "uz", name: "Uzbek"),
        SpokenLanguage(id: "tg", name: "Tajik"),
        SpokenLanguage(id: "af", name: "Afrikaans"),
        SpokenLanguage(id: "sw", name: "Swahili"),
        SpokenLanguage(id: "ha", name: "Hausa"),
        SpokenLanguage(id: "yo", name: "Yoruba"),
        SpokenLanguage(id: "ig", name: "Igbo"),
        SpokenLanguage(id: "zu", name: "Zulu"),
        SpokenLanguage(id: "xh", name: "Xhosa"),
        SpokenLanguage(id: "st", name: "Sesotho"),
        SpokenLanguage(id: "tn", name: "Tswana"),
        SpokenLanguage(id: "rw", name: "Kinyarwanda"),
        SpokenLanguage(id: "rn", name: "Kirundi"),
        SpokenLanguage(id: "am", name: "Amharic"),
        SpokenLanguage(id: "so", name: "Somali"),
        SpokenLanguage(id: "om", name: "Oromo"),
        SpokenLanguage(id: "ti", name: "Tigrinya"),
        SpokenLanguage(id: "mg", name: "Malagasy"),
        SpokenLanguage(id: "jv", name: "Javanese"),
        SpokenLanguage(id: "su", name: "Sundanese"),
        SpokenLanguage(id: "ceb", name: "Cebuano"),
        SpokenLanguage(id: "hmn", name: "Hmong"),
        SpokenLanguage(id: "haw", name: "Hawaiian"),
        SpokenLanguage(id: "sm", name: "Samoan"),
        SpokenLanguage(id: "mi", name: "Maori"),
        SpokenLanguage(id: "ny", name: "Chichewa"),
    ]
    
    /// Find language by ISO code, returning nil for unknown codes
    static func find(by code: String) -> SpokenLanguage? {
        all.first { $0.id == code.lowercased() }
    }
    
    /// Find language by ISO code, returning the raw code name for unknown codes
    static func displayName(for code: String) -> String {
        guard code != "auto" else { return "Auto-Detect" }
        return find(by: code)?.name ?? code.uppercased()
    }
}

// MARK: - Task Model
struct MediaTask: Identifiable, Equatable, Codable {
    let id: UUID
    let sourceURL: URL
    let relativePath: String
    let fileName: String
    let fileExtension: String
    let fileSize: Int64
    var status: TaskStatus
    var progress: Double
    var outputURL: URL?
    var durationSeconds: Double
    var detectedLanguage: String?
    var targetLanguage: String
    var errorMessage: String?
    var videoCodec: String?
    var audioCodec: String?
    var resolution: String?
    var bitrate: String?
    var validationPassed: Bool?
    var validationReport: String?
    var startedAt: Date?
    var completedAt: Date?
    var isPaused: Bool = false
    
    init(id: UUID = UUID(), sourceURL: URL, relativePath: String = "", status: TaskStatus = .queued) {
        self.id = id
        self.sourceURL = sourceURL
        self.relativePath = relativePath.isEmpty ? sourceURL.lastPathComponent : relativePath
        self.fileName = sourceURL.deletingPathExtension().lastPathComponent
        self.fileExtension = sourceURL.pathExtension.lowercased()
        self.fileSize = (try? sourceURL.resourceValues(forKeys: [.fileSizeKey]).fileSize.map(Int64.init)) ?? 0
        self.status = status
        self.progress = 0.0
        self.outputURL = nil
        self.durationSeconds = 0.0
        self.detectedLanguage = nil
        self.targetLanguage = "en"
        self.errorMessage = nil
    }
    
    var fileSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
    
    var totalElapsed: String {
        guard let start = startedAt else { return "" }
        let end = completedAt ?? Date()
        let secs = Int(end.timeIntervalSince(start))
        let h = secs/3600, m = (secs%3600)/60, s = secs%60
        return h > 0 ? "\(h)h \(m)m" : m > 0 ? "\(m)m \(s)s" : "\(s)s"
    }
    
    /// Human-readable source language name
    var sourceLanguageDisplay: String {
        guard let lang = detectedLanguage, !lang.isEmpty else { return "Detecting…" }
        return SpokenLanguage.displayName(for: lang)
    }
    
    /// Human-readable target language name
    var targetLanguageDisplay: String {
        SpokenLanguage.displayName(for: targetLanguage)
    }
}

// MARK: - Task Status
enum TaskStatus: String, Codable, CaseIterable {
    case queued = "Queued"
    case analyzing = "Analyzing"
    case transcribing = "Transcribing"
    case translating = "Translating"
    case dubbing = "Dubbing"
    case detecting = "Detecting Language"
    case separating = "Separating Stems"
    case stabilizing = "Stabilizing"
    case denoising = "Denoising"
    case lipSyncing = "Lip-Syncing"
    case upscaling = "Upscaling"
    case rendering = "Rendering"
    case validating = "Validating"
    case completed = "Completed"
    case failed = "Failed"
    case paused = "Paused"
    
    var icon: String {
        switch self {
        case .queued: return "circle"
        case .analyzing: return "magnifyingglass"
        case .transcribing: return "waveform"
        case .translating: return "globe"
        case .dubbing: return "mic.fill"
        case .detecting: return "text.bubble.fill"
        case .separating: return "waveform.path.ecg"
        case .stabilizing: return "camera.metering.center.weighted"
        case .denoising: return "wand.and.stars.inverse"
        case .lipSyncing: return "mouth.fill"
        case .upscaling: return "sparkles"
        case .rendering: return "gearshape.2.fill"
        case .validating: return "checkmark.shield"
        case .completed: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .paused: return "pause.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .queued: return .secondary
        case .analyzing, .transcribing, .translating: return .blue
        case .dubbing, .lipSyncing, .detecting, .separating: return .purple
        case .stabilizing, .denoising: return .cyan
        case .upscaling: return .orange
        case .rendering: return .indigo
        case .validating: return .teal
        case .completed: return .green
        case .failed: return .red
        case .paused: return .yellow
        }
    }
    
    var isRunning: Bool {
        ![.queued, .completed, .failed, .paused].contains(self)
    }
}

// MARK: - Processing Options
struct ProcessingOptions: Equatable {
    var sourceLanguage: String = "auto"     // ISO code or "auto" for auto-detect
    var targetLanguage: String = "en"       // ISO code — default English
    var enableDubbing: Bool = true
    var enableLipSync: Bool = true
    var enableSubtitles: Bool = true
    var subtitleMode: SubtitleMode = .softEmbedded
    var enableUpscaling: Bool = false
    var upscaleTarget: UpscaleTarget = .k4
    var upscaleEngine: UpscaleEngine = .metalFX  // metalFX = fast Metal GPU; realESRGAN = slow per-frame ML, higher quality
    var enableStabilization: Bool = false        // ffmpeg deshake — reduce camera shake/gate weave
    var enableDenoise: Bool = false              // ffmpeg hqdn3d/nlmeans — remove grain/sensor noise
    var enableStemSeparation: Bool = false       // Demucs — keep original music/SFX, replace only dialogue
    var outputFormat: OutputFormat = .mp4
    var preserveSourceDirectory: Bool = true
    var enableVoiceCloning: Bool = true
    var enableNoiseReduction: Bool = true
    var processingQuality: ProcessingQuality = .balanced
    var maxConcurrentTasks: Int = ProcessInfo.processInfo.activeProcessorCount
    var enableQualityValidation: Bool = true
    var enableNotifications: Bool = true
    var enableWatchFolder: Bool = false
    var watchFolderURL: URL?
    var replaceOriginal: Bool = false
    var enableIntegrityCheck: Bool = true
    
    enum SubtitleMode: String, CaseIterable { case softEmbedded, hardBurned, externalSRT, none }
    enum UpscaleTarget: String, CaseIterable { case k4, k8 }
    enum UpscaleEngine: String, CaseIterable {
        case metalFX, realESRGAN
        var label: String { self == .metalFX ? "MetalFX (fast)" : "Real-ESRGAN (slow)" }
    }
    enum OutputFormat: String, CaseIterable { case mp4, mkv, mov, webm }
    enum ProcessingQuality: String, CaseIterable { case fast, balanced, studio }
}

// MARK: - Presets
struct ProcessingPreset: Identifiable, Equatable {
    let id: UUID; var name: String; var description: String; var icon: String
    var isBuiltIn: Bool; var options: ProcessingOptions
    init(name: String, desc: String = "", icon: String = "sparkles", builtIn: Bool = false, opts: ProcessingOptions) {
        id = UUID(); self.name = name; self.description = desc; self.icon = icon
        self.isBuiltIn = builtIn; self.options = opts
    }
    static let builtIn: [ProcessingPreset] = {
        var f = ProcessingOptions(); f.outputFormat = .mp4; f.processingQuality = .fast
        f.enableDubbing = false; f.enableUpscaling = false; f.enableLipSync = false
        var c = ProcessingOptions(); c.outputFormat = .mp4; c.processingQuality = .studio
        c.enableDubbing = true; c.enableLipSync = true; c.enableVoiceCloning = true; c.enableUpscaling = true
        var s = ProcessingOptions(); s.enableDubbing = false; s.enableLipSync = false
        s.enableUpscaling = false; s.enableSubtitles = true; s.subtitleMode = .externalSRT
        var m = ProcessingOptions(); m.outputFormat = .mov; m.processingQuality = .studio
        m.enableDubbing = true; m.enableLipSync = true; m.enableUpscaling = true; m.upscaleTarget = .k8
        return [
            ProcessingPreset(name: "Web Optimized", desc: "Fast H.265 encode", icon: "globe", builtIn: true, opts: f),
            ProcessingPreset(name: "Cinema Dub 4K", desc: "Full dub + lip-sync at 4K", icon: "theatermasks.fill", builtIn: true, opts: c),
            ProcessingPreset(name: "Transcribe Only", desc: "Extract subtitles only", icon: "captions.bubble", builtIn: true, opts: s),
            ProcessingPreset(name: "8K Master", desc: "Studio upscale to 8K", icon: "sparkles.tv", builtIn: true, opts: m),
        ]
    }()
}

// MARK: - Log
struct PipelineLogEntry: Identifiable {
    let id = UUID(); let timestamp: Date; let stage: TaskStatus; let message: String; let isError: Bool
}

enum AppPhase { case welcome, ready, processing, completed }