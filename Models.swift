import SwiftUI
import UniformTypeIdentifiers

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
}

// MARK: - Task Status
enum TaskStatus: String, Codable, CaseIterable {
    case queued = "Queued"
    case analyzing = "Analyzing"
    case transcribing = "Transcribing"
    case translating = "Translating"
    case dubbing = "Dubbing"
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
        case .dubbing, .lipSyncing: return .purple
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
    var targetLanguage: String = "English"
    var enableDubbing: Bool = true
    var enableLipSync: Bool = true
    var enableSubtitles: Bool = true
    var subtitleMode: SubtitleMode = .softEmbedded
    var enableUpscaling: Bool = false
    var upscaleTarget: UpscaleTarget = .k4
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