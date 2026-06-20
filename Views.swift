import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Swiss International Style Tokens
enum SX {
    static let canvas = Color.white
    static let surface = Color(red: 0.949, green: 0.949, blue: 0.949)
    static let elevated = Color.white
    static let textPrimary = Color.black
    static let textSecondary = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let textTertiary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let accent = Color(red: 1.0, green: 0.188, blue: 0.0)
    static let accentBg = Color(red: 1.0, green: 0.188, blue: 0.0).opacity(0.08)
    static let success = Color.green
    static let danger = Color(red: 1.0, green: 0.188, blue: 0.0)
    static let border = Color.black.opacity(0.15)
    static let borderStrong = Color.black
    static let rControl: CGFloat = 0
    static let rCard: CGFloat = 0
    static let rPanel: CGFloat = 0
    static let shadowSm = Color.black.opacity(0.08)
    static let shadowMd = Color.black.opacity(0.12)
    static let animSnap = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let animStandard = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let spSnap = Animation.spring(response: 0.25, dampingFraction: 0.9)
    static let spStandard = Animation.spring(response: 0.35, dampingFraction: 0.75)
    static let spGentle = Animation.spring(response: 0.5, dampingFraction: 0.8)
    static let spDramatic = Animation.spring(response: 0.6, dampingFraction: 0.65)
    // Framer Motion-equivalent interactive springs (gesture-driven)
    static let spInteractive = Animation.interactiveSpring(response: 0.35, dampingFraction: 0.86, blendDuration: 0)
    static let spBouncy = Animation.interactiveSpring(response: 0.5, dampingFraction: 0.6, blendDuration: 0)
    static let spFluid = Animation.interactiveSpring(response: 0.3, dampingFraction: 0.82, blendDuration: 0)
    static let amber = Color.orange
    static let teal = Color(red: 0.2, green: 0.6, blue: 0.6)
    static let glass = Color.white.opacity(0.5)
    static let glassStrong = Color.white.opacity(0.7)
    static let accentGlow = SX.accent.opacity(0.12)
}
typealias GX = SX

// MARK: - Command Palette
struct CommandPalette: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @Binding var isPresented: Bool
    @State private var query = ""
    @FocusState private var focused: Bool
    
    enum Cmd: String, CaseIterable { case open, folder, process, clear }
    
    var filtered: [Cmd] { query.isEmpty ? Cmd.allCases : Cmd.allCases.filter { $0.rawValue.contains(query.lowercased()) } }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass").foregroundStyle(SX.textSecondary)
                TextField("Command...", text: $query).textFieldStyle(.plain).focused($focused).font(.system(size: 14))
                Text("esc").font(.system(size: 10, design: .monospaced)).foregroundStyle(SX.textTertiary)
                    .padding(.horizontal, 6).padding(.vertical, 2).background(Rectangle().fill(SX.surface))
            }.padding(14)
            Divider()
            ForEach(filtered, id: \.self) { cmd in
                Button { handle(cmd) } label: {
                    HStack {
                        Image(systemName: icon(cmd)).frame(width: 22)
                        Text(label(cmd)).font(.system(size: 13))
                        Spacer()
                        Text(shortcut(cmd)).font(.system(size: 10, design: .monospaced)).foregroundStyle(SX.textTertiary)
                    }.padding(.horizontal, 14).padding(.vertical, 8)
                }.buttonStyle(.plain)
            }
        }
        .frame(width: 380, height: 280)
        .background(SX.elevated)
        .shadow(color: SX.shadowMd, radius: 16, x: 0, y: 8)
        .onAppear { focused = true; query = "" }
    }
    
    func icon(_ c: Cmd) -> String {
        switch c { case .open: "doc.badge.plus"; case .folder: "folder.badge.plus"; case .process: "play.fill"; case .clear: "trash" }
    }
    func label(_ c: Cmd) -> String {
        switch c { case .open: "Open Media Files"; case .folder: "Import Folder"; case .process: "Start Processing"; case .clear: "Clear Queue" }
    }
    func shortcut(_ c: Cmd) -> String {
        switch c { case .open: "CmdO"; case .folder: "CmdShiftO"; case .process: "CmdEnter"; case .clear: "CmdDelete" }
    }
    func handle(_ c: Cmd) {
        isPresented = false
        switch c {
        case .open:
            let p = NSOpenPanel(); p.allowedContentTypes = [.mpeg4Movie]; p.allowsMultipleSelection = true
            if p.runModal() == .OK { manager.addFiles(p.urls) }
        case .folder:
            let p = NSOpenPanel(); p.canChooseDirectories = true
            if p.runModal() == .OK, let u = p.url { manager.addFolder(u) }
        case .process: Task { await manager.startProcessing() }
        case .clear: manager.clearCompleted()
        }
    }
}

// MARK: - Welcome View
struct WelcomeView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var phase = 0
    
    var body: some View {
        ZStack {
            SX.canvas.ignoresSafeArea()
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSince1970
                EllipticalGradient(
                    colors: [SX.accent.opacity(0.06), Color.blue.opacity(0.04), Color.white],
                    center: UnitPoint(x: 0.5 + sin(t * 0.3) * 0.15, y: 0.4 + cos(t * 0.25) * 0.1)
                ).ignoresSafeArea()
            }
            VStack(spacing: 0) {
                Spacer()
                Rectangle().fill(SX.accent).frame(width: 64, height: 64)
                    .shadow(color: SX.accentGlow, radius: 30, y: 6)
                    .overlay(Image(systemName: "waveform").font(.system(size: 24, weight: .bold)).foregroundColor(.white))
                    .scaleEffect(phase >= 1 ? 1 : 0.5).opacity(phase >= 1 ? 1 : 0)
                    .animation(SX.spDramatic.delay(0.1), value: phase)
                Spacer().frame(height: 20)
                Text("Mediatron").font(.system(size: 34, weight: .bold, design: .rounded)).foregroundStyle(SX.textPrimary)
                    .opacity(phase >= 1 ? 1 : 0).offset(y: phase >= 1 ? 0 : 8)
                    .animation(SX.spStandard.delay(0.2), value: phase)
                Text("Hollywood-grade media processing, 100% offline.").font(.system(size: 14)).foregroundStyle(SX.textSecondary)
                    .opacity(phase >= 1 ? 1 : 0).offset(y: phase >= 1 ? 0 : 6)
                    .animation(SX.spStandard.delay(0.3), value: phase)
                Spacer().frame(height: 32)
                DropTargetView().opacity(phase >= 1 ? 1 : 0).animation(SX.spStandard.delay(0.35), value: phase)
                Spacer().frame(height: 16)
                HStack(spacing: 10) {
                    Button { let p = NSOpenPanel(); p.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]; p.allowsMultipleSelection = true; if p.runModal() == .OK { manager.addFiles(p.urls) } }
                        label: { Label("Open Files", systemImage: "doc.badge.plus").font(.system(size: 13, weight: .medium)).padding(.horizontal, 18).padding(.vertical, 9) }
                        .buttonStyle(.bordered).tint(SX.textSecondary).controlSize(.large).accessibilityLabel("Open media files")
                    Button { let p = NSOpenPanel(); p.canChooseDirectories = true; if p.runModal() == .OK, let u = p.url { manager.addFolder(u) } }
                        label: { Label("Import Folder", systemImage: "folder.badge.plus").font(.system(size: 13, weight: .semibold)).padding(.horizontal, 18).padding(.vertical, 9) }
                        .buttonStyle(.borderedProminent).tint(SX.accent).controlSize(.large).accessibilityLabel("Import folder")
                }.opacity(phase >= 1 ? 1 : 0).animation(SX.spStandard.delay(0.42), value: phase)
                Spacer().frame(height: 10)
                HStack(spacing: 6) {
                    Pill(icon: "lock.shield.fill", text: "Offline & Private"); Pill(icon: "cpu.fill", text: "Apple Silicon"); Pill(icon: "sparkles", text: "AI Pipeline")
                }.opacity(phase >= 1 ? 1 : 0).animation(SX.spStandard.delay(0.5), value: phase)
                Spacer()
            }.padding(40)
        }
        .onAppear { withAnimation { phase = 1 } }
        .onDrop(of: [.fileURL], isTargeted: .constant(false)) { providers in
            for p in providers {
                _ = p.loadObject(ofClass: URL.self) { url, _ in
                    guard let url = url else { return }
                    var isDir: ObjCBool = false
                    if FileManager.default.fileExists(atPath: url.path, isDirectory: &isDir), isDir.boolValue {
                        DispatchQueue.main.async { manager.addFolder(url) }
                    } else { DispatchQueue.main.async { manager.addFiles([url]) } }
                }
            }
            return true
        }
    }
}

struct Pill: View {
    let icon: String; let text: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 9)); Text(text).font(.system(size: 9, weight: .medium))
        }.foregroundStyle(SX.textTertiary).padding(.horizontal, 9).padding(.vertical, 4)
            .background(Rectangle().fill(SX.surface).overlay(Rectangle().strokeBorder(SX.border, lineWidth: 2)))
    }
}

struct DropTargetView: View {
    @State private var targeted = false
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.down.doc.fill").font(.system(size: 36, weight: .light))
                .foregroundStyle(targeted ? SX.accent : SX.textTertiary).symbolEffect(.bounce, value: targeted)
            Text("Drop media files here").font(.system(size: 13, weight: .medium))
                .foregroundStyle(targeted ? SX.accent : SX.textSecondary)
            Text("MP4, MKV, MOV, AVI, WebM — up to 8K").font(.system(size: 10)).foregroundStyle(SX.textTertiary)
        }.frame(maxWidth: 400, minHeight: 110)
            .background(Rectangle().fill(targeted ? SX.accentBg : SX.surface)
                .overlay(Rectangle().strokeBorder(targeted ? SX.accent : SX.border, style: StrokeStyle(lineWidth: targeted ? 3 : 2, dash: targeted ? [] : [5, 4]))))
            .scaleEffect(targeted ? 1.02 : 1).animation(SX.animSnap, value: targeted)
            .onDrop(of: [.fileURL], isTargeted: $targeted) { _ in true }
    }
}

// MARK: - Sidebar
struct SidebarView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Rectangle().fill(SX.accent).frame(width: 22, height: 22)
                    .overlay(Image(systemName: "waveform").font(.system(size: 11, weight: .bold)).foregroundColor(.white))
                Text("MEDIATRON").font(.system(size: 11, weight: .bold)).foregroundStyle(SX.textPrimary).tracking(2)
                Spacer()
            }.padding(.horizontal, 14).padding(.vertical, 10).background(SX.surface)
            Divider()
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    SideSec(title: "PRESETS", icon: "square.grid.2x2") {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 5) {
                                ForEach(ProcessingPreset.builtIn) { preset in
                                    Button { manager.options = preset.options } label: {
                                        VStack(spacing: 2) {
                                            Image(systemName: preset.icon).font(.system(size: 13))
                                            Text(preset.name).font(.system(size: 8, weight: .medium)).lineLimit(1)
                                        }.frame(width: 58, height: 42).background(Rectangle().fill(SX.surface).overlay(Rectangle().strokeBorder(SX.border)))
                                    }.buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    SideSec(title: "OUTPUT", icon: "film") {
                        VStack(spacing: 4) {
                            Text("Format").font(.system(size: 9)).foregroundStyle(SX.textSecondary)
                            Picker("", selection: $manager.options.outputFormat) {
                                ForEach(ProcessingOptions.OutputFormat.allCases, id: \.self) { f in Text(f.rawValue).tag(f).font(.system(size: 11)) }
                            }.pickerStyle(.segmented).labelsHidden()
                        }
                        VStack(spacing: 4) {
                            Text("Quality").font(.system(size: 9)).foregroundStyle(SX.textSecondary)
                            Picker("", selection: $manager.options.processingQuality) {
                                ForEach(ProcessingOptions.ProcessingQuality.allCases, id: \.self) { q in Text(q.rawValue).tag(q).font(.system(size: 10)) }
                            }.pickerStyle(.segmented).labelsHidden()
                        }
                    }
                    SideSec(title: "DUBBING", icon: "mic.fill") {
                        Tog("Auto-Dub to English", $manager.options.enableDubbing)
                        if manager.options.enableDubbing {
                            Tog("Hollywood Lip-Sync", $manager.options.enableLipSync, sub: "Frame-by-frame morphing")
                            Tog("Voice Cloning", $manager.options.enableVoiceCloning, sub: "Preserve speaker tone")
                        }
                    }
                    SideSec(title: "SUBTITLES", icon: "captions.bubble") {
                        Tog("Generate Subtitles", $manager.options.enableSubtitles)
                        if manager.options.enableSubtitles {
                            Picker("", selection: $manager.options.subtitleMode) {
                                ForEach(ProcessingOptions.SubtitleMode.allCases, id: \.self) { m in Text(m.rawValue).tag(m).font(.system(size: 10)) }
                            }.pickerStyle(.radioGroup).labelsHidden()
                        }
                    }
                    SideSec(title: "ENHANCE", icon: "sparkles") {
                        Tog("AI Upscaling", $manager.options.enableUpscaling)
                        if manager.options.enableUpscaling {
                            Picker("", selection: $manager.options.upscaleTarget) {
                                ForEach(ProcessingOptions.UpscaleTarget.allCases, id: \.self) { t in Text(t.rawValue).tag(t).font(.system(size: 10)) }
                            }.pickerStyle(.radioGroup).labelsHidden()
                        }
                        Tog("Noise Reduction", $manager.options.enableNoiseReduction)
                        Tog("Replace Original", $manager.options.replaceOriginal, sub: "Overwrite source file")
                        Tog("Integrity Check", $manager.options.enableIntegrityCheck, sub: "Validate output")
                    }
                }.padding(12)
            }
            Divider()
            VStack(spacing: 4) {
                Button {
                    Task { await manager.startProcessing() }
                } label: {
                    HStack {
                        Spacer(); Image(systemName: "play.fill").font(.system(size: 10))
                        Text("PROCESS QUEUE").font(.system(size: 11, weight: .bold)).tracking(1); Spacer()
                    }.padding(.vertical, 8)
                }.buttonStyle(.borderedProminent).tint(SX.accent)
                    .disabled(manager.isProcessing || manager.tasks.isEmpty)
                    .keyboardShortcut(.return, modifiers: []).accessibilityLabel("Start processing")
                HStack {
                    Button("Clear") { manager.clearCompleted() }.font(.system(size: 10)).foregroundStyle(SX.textSecondary).buttonStyle(.plain)
                    Spacer()
                    Text("\(manager.tasks.count) files").font(.system(size: 9)).foregroundStyle(SX.textTertiary)
                }
            }.padding(.horizontal, 12).padding(.vertical, 8).background(SX.surface)
        }.frame(minWidth: 240).background(SX.canvas)
    }
}

struct SideSec<C: View>: View {
    let title: String; let icon: String; @ViewBuilder let content: C
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(title, systemImage: icon).font(.system(size: 9, weight: .bold)).foregroundStyle(SX.textSecondary).tracking(2)
            content
        }
    }
}

struct Tog: View {
    let label: String; @Binding var isOn: Bool; var sub: String?
    init(_ l: String, _ on: Binding<Bool>, sub: String? = nil) { self.label = l; self._isOn = on; self.sub = sub }
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 1) {
                Text(label).font(.system(size: 11))
                if let s = sub { Text(s).font(.system(size: 8)).foregroundStyle(SX.textTertiary) }
            }
        }.toggleStyle(.switch).tint(SX.accent)
    }
}

// MARK: - Main Area
struct MainAreaView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var selected: UUID?
    var body: some View {
        VStack(spacing: 0) {
            ToolbarView(); Divider()
            if manager.tasks.isEmpty { EmptyState() } else { TaskListView(selected: $selected) }
            Divider(); StatusStrip()
        }.background(SX.canvas)
    }
}

struct ToolbarView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("PROCESSING QUEUE").font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(SX.textPrimary)
                Text("\(manager.tasks.count) files").font(.system(size: 10)).foregroundStyle(SX.textSecondary)
            }
            Spacer()
            if let u = manager.tasks.first?.sourceURL {
                Button { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: u.deletingLastPathComponent().path) } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill").font(.system(size: 8))
                        Text("Output").font(.system(size: 9, weight: .medium))
                    }.foregroundStyle(SX.accent).padding(.horizontal, 7).padding(.vertical, 3).background(Rectangle().fill(SX.accentBg))
                }.buttonStyle(.plain).help("Reveal output folder")
            }
            if manager.isProcessing {
                HStack(spacing: 4) {
                    ProgressView(value: manager.overallProgress).progressViewStyle(.linear).frame(width: 80)
                    Text("\(Int(manager.overallProgress * 100))%").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(SX.accent)
                }.padding(.horizontal, 8).padding(.vertical, 4).background(Rectangle().fill(SX.accentBg))
            }
            Menu {
                Button { let p = NSOpenPanel(); p.allowedContentTypes = [.mpeg4Movie]; p.allowsMultipleSelection = true; if p.runModal() == .OK { manager.addFiles(p.urls) } } label: { Label("Add Files", systemImage: "doc.badge.plus") }.keyboardShortcut("o")
                Button { let p = NSOpenPanel(); p.canChooseDirectories = true; if p.runModal() == .OK, let u = p.url { manager.addFolder(u) } } label: { Label("Add Folder", systemImage: "folder.badge.plus") }.keyboardShortcut("o", modifiers: [.command, .shift])
                Divider()
                Button { manager.clearCompleted() } label: { Label("Clear", systemImage: "trash") }
            } label: { Label("Add", systemImage: "plus.circle.fill").font(.system(size: 11)) }
                .buttonStyle(.bordered).tint(SX.textSecondary).menuIndicator(.hidden).fixedSize()
        }.padding(.horizontal, 16).padding(.vertical, 8).background(SX.surface)
    }
}

struct EmptyState: View {
    @State private var pulse = false
    var body: some View {
        VStack(spacing: 12) {
            Rectangle().fill(SX.surface).frame(width: 64, height: 64)
                .overlay(Image(systemName: "film.stack").font(.system(size: 24, weight: .light)).foregroundStyle(SX.textTertiary))
                .scaleEffect(pulse ? 1.03 : 1.0)
                .animation(.easeInOut(duration: 2.5).repeatForever(autoreverses: true), value: pulse)
                .onAppear { pulse = true }
            Text("No media in queue").font(.system(size: 14, weight: .medium)).foregroundStyle(SX.textSecondary)
            Text("CmdO to open files").font(.system(size: 10)).foregroundStyle(SX.textTertiary)
        }.frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct TaskListView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @Binding var selected: UUID?
    var body: some View {
        List(selection: $selected) {
            ForEach(manager.tasks) { task in
                TaskCard(task: task).listRowSeparator(.hidden).listRowInsets(EdgeInsets(top: 2, leading: 10, bottom: 2, trailing: 10))
            }.onDelete { idx in for i in idx { manager.removeTask(manager.tasks[i]) } }
        }.listStyle(.plain).scrollContentBackground(.hidden)
    }
}

struct TaskCard: View {
    let task: MediaTask
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var hover = false
    
    var body: some View {
        HStack(spacing: 10) {
            Rectangle().fill(task.status.color.opacity(0.12)).frame(width: 34, height: 34)
                .overlay(Image(systemName: task.status.icon).font(.system(size: 13, weight: .medium)).foregroundStyle(task.status.color)
                    .symbolEffect(.bounce, options: .repeating, value: [.transcribing, .dubbing, .rendering].contains(task.status)))
            VStack(alignment: .leading, spacing: 2) {
                Text(task.fileName).font(.system(size: 12, weight: .medium)).foregroundStyle(SX.textPrimary).lineLimit(1)
                HStack(spacing: 4) {
                    Text(task.fileSizeFormatted).font(.system(size: 9)).foregroundStyle(SX.textSecondary)
                    if let res = task.resolution { Text(res).font(.system(size: 8, weight: .medium)).foregroundStyle(SX.textSecondary) }
                    if let codec = task.videoCodec, !codec.isEmpty { Text(codec).font(.system(size: 8)).foregroundStyle(SX.textTertiary) }
                    if let lang = task.detectedLanguage { Text(lang).font(.system(size: 8)).padding(.horizontal, 4).padding(.vertical, 1).background(Rectangle().fill(SX.accentBg)).foregroundStyle(SX.accent) }
                    if task.durationSeconds > 0 { Text(fd(task.durationSeconds)).font(.system(size: 9)).foregroundStyle(SX.textSecondary) }
                }
                if let outURL = task.outputURL, task.status == .completed {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill").font(.system(size: 7)).foregroundStyle(SX.accent)
                        Text(outURL.lastPathComponent).font(.system(size: 8, weight: .medium)).foregroundStyle(SX.accent).lineLimit(1)
                        Button { NSWorkspace.shared.activateFileViewerSelecting([outURL]) } label: {
                            Image(systemName: "arrow.right.circle.fill").font(.system(size: 10))
                        }.buttonStyle(.plain).foregroundStyle(SX.accent)
                    }
                }
                if task.status.isRunning {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Rectangle().fill(SX.border).frame(height: 3)
                            Rectangle().fill(SX.accent).frame(width: max(3, geo.size.width * task.progress), height: 3)
                                .animation(.easeInOut(duration: 0.25), value: task.progress)
                        }
                    }.frame(height: 3)
                }
            }
            Spacer()
            HStack(spacing: 2) {
                Circle().fill(task.status.color).frame(width: 4, height: 4)
                Text(task.status.rawValue).font(.system(size: 9, weight: .medium)).foregroundStyle(task.status.color)
            }.padding(.horizontal, 7).padding(.vertical, 2).background(Rectangle().fill(task.status.color.opacity(0.1)))
            if [.queued, .completed, .failed].contains(task.status) {
                Button { manager.removeTask(task) } label: { Image(systemName: "xmark.circle.fill").font(.system(size: 11)) }
                    .buttonStyle(.plain).foregroundStyle(SX.textTertiary).opacity(hover ? 1 : 0)
            }
        }.padding(.vertical, 5).padding(.horizontal, 10)
            .background(Rectangle().fill(SX.surface).overlay(Rectangle().strokeBorder(hover ? SX.borderStrong : SX.border, lineWidth: hover ? 3 : 2)))
            .onHover { hover = $0 }
            .contextMenu {
                if task.status == .completed, let out = task.outputURL { Button { NSWorkspace.shared.activateFileViewerSelecting([out]) } label: { Label("Show in Finder", systemImage: "folder") } }
                Button { manager.removeTask(task) } label: { Label("Remove", systemImage: "trash") }
            }.animation(SX.animSnap, value: hover)
    }
    
    func fd(_ s: Double) -> String {
        let h = Int(s) / 3600, m = (Int(s) % 3600) / 60, sec = Int(s) % 60
        if h > 0 { return "\(h)h \(m)m" }; if m > 0 { return "\(m)m \(sec)s" }; return "\(sec)s"
    }
}

struct StatusStrip: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var showLog = false
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: manager.isProcessing ? "gearshape.2.fill" : "checkmark.circle.fill")
                .font(.system(size: 9)).foregroundStyle(manager.isProcessing ? SX.accent : SX.success)
                .symbolEffect(.pulse, options: .repeating, value: manager.isProcessing)
            Text(manager.statusMessage).font(.system(size: 9)).foregroundStyle(SX.textSecondary).lineLimit(1)
            Spacer()
            Button { showLog.toggle() } label: { Text("LOG").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(showLog ? SX.accent : SX.textTertiary) }.buttonStyle(.plain)
            Text("M-Series").font(.system(size: 7)).foregroundStyle(SX.textTertiary).padding(.horizontal, 5).padding(.vertical, 1).background(Rectangle().fill(SX.surface))
        }.padding(.horizontal, 12).padding(.vertical, 5).background(SX.surface)
            .sheet(isPresented: $showLog) { LogSheet() }
    }
}

struct LogSheet: View {
    @EnvironmentObject var manager: MediaProcessingManager
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("PIPELINE LOG").font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(SX.textPrimary)
                Spacer()
                Button("Clear") { manager.pipelineLog.removeAll() }.font(.system(size: 10)).buttonStyle(.plain).foregroundStyle(SX.textSecondary)
            }.padding(12).background(SX.surface)
            Divider()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(manager.pipelineLog.reversed()) { entry in
                        HStack(spacing: 4) {
                            Circle().fill(entry.stage.color).frame(width: 4, height: 4)
                            Text(entry.timestamp, style: .time).font(.system(size: 8, design: .monospaced)).foregroundStyle(SX.textTertiary)
                            Text(entry.message).font(.system(size: 9)).foregroundStyle(entry.isError ? SX.danger : SX.textSecondary)
                        }
                    }
                }.padding(10)
            }
        }.frame(width: 460, height: 300).background(SX.canvas)
    }
}

// MARK: - Settings
struct SettingsView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var checking = false
    var body: some View {
        TabView {
            VStack(alignment: .leading, spacing: 16) {
                Text("OUTPUT").font(.system(size: 16, weight: .bold)).tracking(2).foregroundStyle(SX.textPrimary)
                Text("Files are saved next to your source media.").font(.system(size: 11)).foregroundStyle(SX.textSecondary)
                Spacer()
            }.padding(20).tabItem { Label("General", systemImage: "gearshape") }
            
            VStack(alignment: .leading, spacing: 14) {
                Text("ENGINES").font(.system(size: 16, weight: .bold)).tracking(2).foregroundStyle(SX.textPrimary)
                Text("100% on-device. No cloud.").font(.system(size: 10)).foregroundStyle(SX.textSecondary)
                VStack(spacing: 6) {
                    DRow(name: "FFmpeg v8.1", desc: "Video decode/encode", ok: manager.dependencyStatus["FFmpeg"] ?? false)
                    DRow(name: "whisper.cpp v1.8", desc: "Speech-to-text", ok: manager.dependencyStatus["whisper.cpp"] ?? false)
                    DRow(name: "ffprobe", desc: "Stream analysis", ok: manager.dependencyStatus["ffprobe"] ?? false)
                }
                Button {
                    checking = true
                    Task { _ = await DependencyBootstrapper.bootstrap(); manager.dependencyStatus = DependencyBootstrapper.checkDependencies(); checking = false }
                } label: {
                    HStack { if checking { ProgressView().scaleEffect(0.6) }; Text("INSTALL ENGINES").font(.system(size: 11, weight: .bold)).tracking(1) }
                }.buttonStyle(.borderedProminent).tint(SX.accent).disabled(checking)
                Spacer()
            }.padding(20).tabItem { Label("Engines", systemImage: "cpu") }
            .onAppear { manager.dependencyStatus = DependencyBootstrapper.checkDependencies() }
            
            VStack(spacing: 10) {
                Rectangle().fill(SX.accent).frame(width: 44, height: 44)
                    .overlay(Image(systemName: "waveform").font(.system(size: 17, weight: .bold)).foregroundColor(.white))
                Text("MEDIATRON v1.0").font(.system(size: 18, weight: .bold)).tracking(2).foregroundStyle(SX.textPrimary)
                Text("Hollywood-grade media processing for Apple Silicon.").font(.system(size: 10)).foregroundStyle(SX.textSecondary).multilineTextAlignment(.center)
                Spacer()
            }.padding(20).tabItem { Label("About", systemImage: "info.circle") }
        }.background(SX.canvas)
    }
}

struct DRow: View {
    let name: String; let desc: String; let ok: Bool
    var body: some View {
        HStack {
            Image(systemName: ok ? "checkmark.circle.fill" : "circle").foregroundStyle(ok ? SX.success : SX.textTertiary).font(.system(size: 11))
            VStack(alignment: .leading) { Text(name).font(.system(size: 11, weight: .medium)).foregroundStyle(SX.textPrimary); Text(desc).font(.system(size: 9)).foregroundStyle(SX.textSecondary) }
            Spacer()
            Text(ok ? "READY" : "MISSING").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(ok ? SX.success : SX.danger)
        }
    }
}
