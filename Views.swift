import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - Swiss International Style Tokens
enum SX {
    static let canvas = Color.white
    static let surface = Color(red: 0.96, green: 0.96, blue: 0.97)
    static let elevated = Color.white
    static let glass = Color.white.opacity(0.72)
    static let glassStrong = Color.white.opacity(0.85)
    static let textPrimary = Color.black
    static let textSecondary = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let textTertiary = Color(red: 0.5, green: 0.5, blue: 0.5)
    static let accent = Color(red: 1.0, green: 0.188, blue: 0.0)
    static let accentBg = Color(red: 1.0, green: 0.188, blue: 0.0).opacity(0.06)
    static let accentMuted = Color(red: 1.0, green: 0.188, blue: 0.0).opacity(0.03)
    static let cardHover = Color.black.opacity(0.02)
    static let success = Color.green
    static let danger = Color(red: 1.0, green: 0.188, blue: 0.0)
    static let border = Color.black.opacity(0.15)
    static let borderStrong = Color.black
    static let rControl: CGFloat = 8
    static let rCard: CGFloat = 10
    static let rPanel: CGFloat = 18  // premium continuous radius
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
    static let accentGlow = SX.accent.opacity(0.12)

    // MARK: - Framer-style premium layer (glassmorphism + bento)
    // Three glass opacity tiers (translucent white panel layers)
    static let glassSoft   = Color.white.opacity(0.55)
    static let glassMid    = Color.white.opacity(0.78)
    static let glassHard   = Color.white.opacity(0.94)
    // Subtle inner highlight + outer ring for premium edges
    static let glassEdge   = Color.white.opacity(0.9)
    static let glassBorder = Color.black.opacity(0.06)
    static let glassInk    = Color.white.opacity(0.5)
    // Mesh gradient anchors (used by AnimatedGradientBg)
    static let meshA = Color(red: 1.00, green: 0.95, blue: 0.92) // warm white
    static let meshB = Color(red: 0.94, green: 0.97, blue: 1.00) // cool white
    static let meshC = Color(red: 1.00, green: 0.92, blue: 0.94) // pink whisper
    static let meshD = Color(red: 0.96, green: 1.00, blue: 0.94) // mint whisper
    // Premium radii — micro-rounded for Swiss-with-softness hybrid
    static let rPill:  CGFloat = 999
    static let rTile:  CGFloat = 14
    // Glow shadow for hover-lift — accent bleed
    static let glowRed  = SX.accent.opacity(0.20)
    static let glowSoft = Color.black.opacity(0.08)
    // Premium springs tuned for Framer-style micro-interactions
    static let spLift   = Animation.interactiveSpring(response: 0.42, dampingFraction: 0.78, blendDuration: 0)
    static let spGlow   = Animation.easeOut(duration: 0.35)
    static let spMesh   = Animation.linear(duration: 12).repeatForever(autoreverses: true)
}
typealias GX = SX

// MARK: - Premium Visual Components (Framer-style)
/// Animated mesh-gradient background — slowly drifting radial blobs.
/// Used under the welcome view and main canvas for ambient depth.
struct MeshBackground: View {
    var intensity: Double = 1.0
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince1970
            ZStack {
                // Base wash
                SX.canvas.ignoresSafeArea()
                // Drifting blob A — accent
                RadialGradient(
                    colors: [SX.accent.opacity(0.10 * intensity), Color.clear],
                    center: UnitPoint(x: 0.5 + sin(t * 0.20) * 0.25,
                                      y: 0.4 + cos(t * 0.15) * 0.20),
                    startRadius: 20, endRadius: 380
                ).ignoresSafeArea().blendMode(.normal)
                // Drifting blob B — cool
                RadialGradient(
                    colors: [SX.meshB.opacity(0.55 * intensity), Color.clear],
                    center: UnitPoint(x: 0.2 + sin(t * 0.13 + 1.2) * 0.20,
                                      y: 0.8 + cos(t * 0.17 + 0.6) * 0.15),
                    startRadius: 30, endRadius: 420
                ).ignoresSafeArea().blendMode(.normal)
                // Drifting blob C — warm whisper
                RadialGradient(
                    colors: [SX.meshC.opacity(0.45 * intensity), Color.clear],
                    center: UnitPoint(x: 0.85 + cos(t * 0.11 + 2.4) * 0.18,
                                      y: 0.15 + sin(t * 0.19 + 1.1) * 0.18),
                    startRadius: 25, endRadius: 360
                ).ignoresSafeArea().blendMode(.normal)
                // Subtle grain — fractal noise overlaid at 4% alpha for tactile feel
                Rectangle().fill(.ultraThinMaterial).opacity(0.15 * intensity).ignoresSafeArea()
            }
        }
    }
}

/// Glass panel — translucent layered background with inner highlight + outer border.
/// Framer's signature frosted-surface effect, tuned for SwiftUI.
struct GlassPanel<Content: View>: View {
    var tint: Color = .white
    var radius: CGFloat = SX.rPanel
    var padding: CGFloat = 0
    @ViewBuilder var content: Content
    var body: some View {
        content
            .padding(padding)
            .background(
                ZStack {
                    // Soft backdrop blur, then layered translucent whites
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .fill(tint.opacity(0.55))
                    // Inner highlight (top edge)
                    RoundedRectangle(cornerRadius: radius, style: .continuous)
                        .stroke(
                            LinearGradient(
                                colors: [SX.glassEdge, Color.white.opacity(0.0)],
                                startPoint: .top, endPoint: .center
                            ),
                            lineWidth: 1
                        )
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(SX.glassBorder, lineWidth: 1)
            )
            .shadow(color: SX.glowSoft, radius: 12, x: 0, y: 6)
    }
}

/// Hover-lift card wrapper — accent-glow shadow on hover, smooth spring.
/// Pair with `.hoverGlow($hover)` modifier on any tappable surface.
struct HoverLift<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var hover = false
    var body: some View {
        content
            .scaleEffect(hover ? 1.015 : 1.0)
            .shadow(color: hover ? SX.glowRed : Color.clear, radius: hover ? 18 : 0, x: 0, y: hover ? 6 : 0)
            .shadow(color: SX.glowSoft, radius: 4, x: 0, y: 2)
            .animation(SX.spLift, value: hover)
            .onHover { hover = $0 }
    }
}

/// Reusable Framer-style status pill — glass capsule with icon + token label.
struct StatusPill: View {
    let icon: String; let text: String; let color: Color
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon).font(.system(size: 9, weight: .semibold))
            Text(text).font(.system(size: 9, weight: .semibold)).tracking(0.5)
        }
        .foregroundStyle(color)
        .padding(.horizontal, 8).padding(.vertical, 3)
        .background(Capsule().fill(color.opacity(0.10)))
        .overlay(Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1))
    }
}

// MARK: - Language Picker (100+ languages, searchable)
struct LanguagePicker: View {
    @Binding var selection: String
    var showAuto: Bool = false
    var autoLabel: String = "Auto"
    var compact: Bool = false
    
    @State private var searchText = ""
    
    var filteredLanguages: [SpokenLanguage] {
        let allLanguages = showAuto ? [SpokenLanguage.auto] + SpokenLanguage.all : SpokenLanguage.all
        guard !searchText.isEmpty else { return allLanguages }
        return allLanguages.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.id.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        Menu {
            // Search field
            if !compact {
                TextField("Search language…", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 11))
                    .padding(4)
            }
            
            ForEach(filteredLanguages) { lang in
                Button {
                    selection = lang.id
                    searchText = ""
                } label: {
                    HStack {
                        Text(lang.name).font(.system(size: 11))
                        Spacer()
                        if lang.id == selection {
                            Image(systemName: "checkmark").font(.system(size: 9)).foregroundStyle(SX.accent)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 3) {
                Text(currentLabel).font(.system(size: compact ? 10 : 11, weight: .medium))
                    .lineLimit(1)
                Image(systemName: "chevron.up.chevron.down").font(.system(size: 7)).foregroundStyle(SX.textTertiary)
            }
            .foregroundStyle(SX.textPrimary)
            .padding(.horizontal, 6).padding(.vertical, 2)
            .background(Capsule().fill(SX.surface))
            .overlay(Capsule().strokeBorder(SX.border, lineWidth: 1))
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .fixedSize()
    }
    
    var currentLabel: String {
        if selection == "auto" { return autoLabel }
        return SpokenLanguage.displayName(for: selection)
    }
}

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

// MARK: - Premium Welcome View (Cinematic Entrance)
struct WelcomeView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var phase = 0
    @State private var logoY: CGFloat = -200
    @State private var logoRotation: Double = -30
    @State private var glowPulse: Double = 0
    var backgroundTheme: BackgroundTheme = .mesh
    var onCycleTheme: () -> Void = {}
    
    var body: some View {
        ZStack {
            ThemeBackground(theme: backgroundTheme).ignoresSafeArea()
            
            // Light veil for dark themes so text stays readable
            if backgroundTheme.isDark {
                Color.white.opacity(0.06).ignoresSafeArea().allowsHitTesting(false)
            }
            
            // Particle glow orbs (only on light themes)
            if !backgroundTheme.isDark {
                ForEach(0..<8) { i in
                    let angle = Double(i) * .pi / 4 + glowPulse
                    let radius: CGFloat = 120 + sin(glowPulse + Double(i)) * 30
                    Circle()
                        .fill(SX.accent.opacity(0.06))
                        .frame(width: 12, height: 12)
                        .offset(x: cos(angle) * radius, y: sin(angle) * radius - 60)
                        .blur(radius: 4)
                        .opacity(phase >= 1 ? 0.8 : 0)
                        .animation(.easeOut(duration: 0.8).delay(0.1 + Double(i) * 0.08), value: phase)
                }
            }
            
            VStack(spacing: 0) {
                Spacer()
                
                // LogoPreloader — cinematic pulsing brand mark
                LogoPreloader(accent: SX.accent, size: 82)
                    .offset(y: logoY)
                    .rotationEffect(.degrees(logoRotation))
                
                Spacer().frame(height: 28)
                
                // SplitTextReveal — character-by-character title reveal
                SplitTextReveal(
                    text: "MEDIATRON",
                    font: .system(size: 46, weight: .black),
                    color: backgroundTheme.isDark ? .white : SX.textPrimary,
                    tracking: 6,
                    trigger: phase >= 1
                )
                
                // Subtitle
                Text("Hollywood-Class Media Processing Studio")
                    .font(.system(size: 15, weight: .medium))
                    .tracking(1)
                    .foregroundStyle(backgroundTheme.isDark ? Color.white.opacity(0.7) : SX.textSecondary)
                    .opacity(phase >= 1 ? 1 : 0)
                    .offset(y: phase >= 1 ? 0 : 15)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.45), value: phase)
                
                // Privacy badge
                HStack(spacing: 6) {
                    Image(systemName: "lock.shield.fill").font(.system(size: 10))
                    Text("100% Offline & Private")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                }
                .foregroundStyle(SX.accent)
                .padding(.horizontal, 14).padding(.vertical, 6)
                .background(Rectangle().fill(SX.accentBg).overlay(Rectangle().strokeBorder(SX.accent.opacity(0.3))))
                .opacity(phase >= 1 ? 1 : 0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.6), value: phase)
                .padding(.top, 12)
                
                Spacer().frame(height: 36)
                
                // Drop zone
                DropTargetView()
                    .opacity(phase >= 1 ? 1 : 0)
                    .scaleEffect(phase >= 1 ? 1 : 0.95)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.7), value: phase)
                
                Spacer().frame(height: 16)
                
                // Action buttons
                HStack(spacing: 12) {
                    Button { let p = NSOpenPanel(); p.allowedContentTypes = [.mpeg4Movie, .quickTimeMovie, .movie]; p.allowsMultipleSelection = true; if p.runModal() == .OK { manager.addFiles(p.urls) } }
                        label: { Label("Open Files", systemImage: "doc.badge.plus").font(.system(size: 13, weight: .medium)).padding(.horizontal, 18).padding(.vertical, 9) }
                        .buttonStyle(.bordered).tint(SX.textSecondary).controlSize(.large).accessibilityLabel("Open media files")
                    Button { let p = NSOpenPanel(); p.canChooseDirectories = true; if p.runModal() == .OK, let u = p.url { manager.addFolder(u) } }
                        label: { Label("Import Folder", systemImage: "folder.badge.plus").font(.system(size: 13, weight: .semibold)).padding(.horizontal, 18).padding(.vertical, 9) }
                        .buttonStyle(.borderedProminent).tint(SX.accent).controlSize(.large).accessibilityLabel("Import folder")
                }
                .opacity(phase >= 1 ? 1 : 0)
                .offset(y: phase >= 1 ? 0 : 8)
                .animation(.spring(response: 0.5, dampingFraction: 0.7).delay(0.8), value: phase)
                
                Spacer()
            }.padding(40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.55)) {
                logoY = 0
                logoRotation = 0
                phase = 1
            }
            // Continuous glow pulse
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                glowPulse = .pi * 2
            }
        }
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
            // Glass header
            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(SX.accent)
                    .frame(width: 22, height: 22)
                    .overlay(Image(systemName: "waveform").font(.system(size: 11, weight: .bold)).foregroundColor(.white))
                    .shadow(color: SX.glowRed, radius: 8, x: 0, y: 2)
                Text("MEDIATRON").font(.system(size: 11, weight: .bold)).foregroundStyle(SX.textPrimary).tracking(2)
                Spacer()
            }
            .padding(.horizontal, 14).padding(.vertical, 10)
            .background(SX.glassMid)
            .overlay(Rectangle().fill(SX.glassBorder).frame(height: 1), alignment: .bottom)

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
                                        }
                                        .frame(width: 58, height: 42)
                                        .background(RoundedRectangle(cornerRadius: SX.rTile, style: .continuous).fill(SX.glassSoft))
                                        .overlay(RoundedRectangle(cornerRadius: SX.rTile, style: .continuous).strokeBorder(SX.glassBorder, lineWidth: 1))
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
                        Tog("Auto-Dub", $manager.options.enableDubbing)
                        if manager.options.enableDubbing {
                            // Source language — auto-detected or manual override
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Source Language").font(.system(size: 8)).foregroundStyle(SX.textTertiary).tracking(0.5)
                                HStack(spacing: 4) {
                                    Image(systemName: "waveform.badge.mic").font(.system(size: 8)).foregroundStyle(SX.accent)
                                    LanguagePicker(
                                        selection: $manager.options.sourceLanguage,
                                        showAuto: true,
                                        autoLabel: "Auto-Detect",
                                        compact: true
                                    )
                                    .font(.system(size: 10))
                                }
                            }
                            .padding(.vertical, 2)
                            
                            // Target language
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Dub To").font(.system(size: 8)).foregroundStyle(SX.textTertiary).tracking(0.5)
                                HStack(spacing: 4) {
                                    Image(systemName: "globe").font(.system(size: 8)).foregroundStyle(SX.accent)
                                    LanguagePicker(
                                        selection: $manager.options.targetLanguage,
                                        showAuto: false,
                                        compact: true
                                    )
                                    .font(.system(size: 10))
                                }
                            }
                            .padding(.vertical, 2)
                            
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

            Rectangle().fill(SX.glassBorder).frame(height: 1)

            // Premium footer — process action glass button
            VStack(spacing: 6) {
                Button {
                    Task { await manager.startProcessing() }
                } label: {
                    HStack {
                        Spacer()
                        Image(systemName: "play.fill").font(.system(size: 10))
                        Text("PROCESS QUEUE").font(.system(size: 11, weight: .bold)).tracking(1)
                        Spacer()
                    }
                    .padding(.vertical, 9)
                    .background(
                        ZStack {
                            RoundedRectangle(cornerRadius: SX.rTile, style: .continuous).fill(SX.accent)
                            RoundedRectangle(cornerRadius: SX.rTile, style: .continuous)
                                .stroke(LinearGradient(colors: [Color.white.opacity(0.6), Color.white.opacity(0)], startPoint: .top, endPoint: .center), lineWidth: 1)
                        }
                    )
                    .foregroundColor(.white)
                    .shadow(color: SX.glowRed, radius: 10, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(manager.isProcessing || manager.tasks.isEmpty)
                .keyboardShortcut(.return, modifiers: [])
                .accessibilityLabel("Start processing")
                .opacity((manager.isProcessing || manager.tasks.isEmpty) ? 0.5 : 1.0)
                .animation(SX.spLift, value: manager.tasks.count)
                
                HStack {
                    Button("Clear") { manager.clearCompleted() }.font(.system(size: 10)).foregroundStyle(SX.textSecondary).buttonStyle(.plain)
                    Spacer()
                    Text("\(manager.tasks.count) files").font(.system(size: 9)).foregroundStyle(SX.textTertiary)
                }
            }.padding(.horizontal, 12).padding(.vertical, 10).background(SX.glassMid)
        }
        .frame(minWidth: 248)
        .background(SX.canvas)
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
    var backgroundTheme: BackgroundTheme = .mesh
    var body: some View {
        ZStack {
            ThemeBackground(theme: backgroundTheme).ignoresSafeArea()
            // Light veil for dark themes
            if backgroundTheme.isDark {
                Color.white.opacity(0.04).ignoresSafeArea().allowsHitTesting(false)
            }
            VStack(spacing: 0) {
                ToolbarView(accent: backgroundTheme.isDark ? .white : SX.textPrimary)
                Rectangle().fill(SX.glassBorder).frame(height: 1)
                Group {
                    if manager.tasks.isEmpty { EmptyState(accent: backgroundTheme.isDark ? .white : SX.textPrimary) }
                    else { TaskListView(selected: $selected) }
                }
                Rectangle().fill(SX.glassBorder).frame(height: 1)
                StatusStrip()
            }
        }
    }
}

struct ToolbarView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    var accent: Color = SX.textPrimary
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 0) {
                Text("PROCESSING QUEUE").font(.system(size: 11, weight: .bold)).tracking(2).foregroundStyle(accent)
                Text("\(manager.tasks.count) files").font(.system(size: 10)).foregroundStyle(accent.opacity(0.6))
            }
            Spacer()
            if let u = manager.tasks.first?.sourceURL {
                Button { NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: u.deletingLastPathComponent().path) } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill").font(.system(size: 8))
                        Text("Output").font(.system(size: 9, weight: .medium))
                    }
                    .foregroundStyle(SX.accent)
                    .padding(.horizontal, 7).padding(.vertical, 3)
                    .background(Capsule().fill(SX.accentBg))
                    .overlay(Capsule().strokeBorder(SX.accent.opacity(0.2), lineWidth: 1))
                }.buttonStyle(.plain).help("Reveal output folder")
            }
            if manager.isProcessing {
                HStack(spacing: 4) {
                    ProgressView(value: manager.overallProgress).progressViewStyle(.linear).frame(width: 80)
                    Text("\(Int(manager.overallProgress * 100))%").font(.system(size: 10, weight: .semibold, design: .monospaced)).foregroundStyle(SX.accent)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(SX.accentBg))
                .overlay(Capsule().strokeBorder(SX.accent.opacity(0.2), lineWidth: 1))
            }
            Menu {
                Button { let p = NSOpenPanel(); p.allowedContentTypes = [.mpeg4Movie]; p.allowsMultipleSelection = true; if p.runModal() == .OK { manager.addFiles(p.urls) } } label: { Label("Add Files", systemImage: "doc.badge.plus") }.keyboardShortcut("o")
                Button { let p = NSOpenPanel(); p.canChooseDirectories = true; if p.runModal() == .OK, let u = p.url { manager.addFolder(u) } } label: { Label("Add Folder", systemImage: "folder.badge.plus") }.keyboardShortcut("o", modifiers: [.command, .shift])
                Divider()
                Button { manager.clearCompleted() } label: { Label("Clear", systemImage: "trash") }
            } label: { Label("Add", systemImage: "plus.circle.fill").font(.system(size: 11)) }
                .buttonStyle(.bordered).tint(accent.opacity(0.8)).menuIndicator(.hidden).fixedSize()
        }
        .padding(.horizontal, 16).padding(.vertical, 8)
        .background(SX.glassMid)
    }
}

struct EmptyState: View {
    @State private var pulse = false
    var accent: Color = SX.textPrimary
    var body: some View {
        VStack(spacing: 16) {
            GlassPanel(radius: 20, padding: 20) {
                VStack(spacing: 12) {
                    Image(systemName: "film.stack")
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(accent.opacity(0.6))
                        .symbolEffect(.pulse, options: .repeating, value: pulse)
                    Text("No media in queue")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(accent)
                    Text("⌘O to open files  ·  Drag & drop to import")
                        .font(.system(size: 11))
                        .foregroundStyle(accent.opacity(0.55))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear { pulse.toggle() }
    }
}

struct StatusStrip: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var showLog = false
    @AppStorage("bgTheme") private var bgThemeRaw = BackgroundTheme.mesh.rawValue

    var body: some View {
        let currentTheme = Binding<BackgroundTheme>(
            get: { BackgroundTheme(rawValue: bgThemeRaw) ?? .mesh },
            set: { newValue in bgThemeRaw = newValue.rawValue }
        )

        HStack(spacing: 10) {
            if manager.isProcessing {
                HourglassLoader(size: 13, color: SX.accent)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 9)).foregroundStyle(SX.success)
            }
            Text(manager.statusMessage).font(.system(size: 9)).foregroundStyle(SX.textSecondary).lineLimit(1)
            if manager.isProcessing {
                AnimatedCounter(value: manager.overallProgress * 100,
                                format: { v in String(format: "%d%%", Int(v)) },
                                font: .system(size: 9, weight: .semibold, design: .monospaced),
                                color: SX.accent)
            }
            Spacer()
            Button { showLog.toggle() } label: { Text("LOG").font(.system(size: 8, weight: .bold)).tracking(1).foregroundStyle(showLog ? SX.accent : SX.textTertiary) }.buttonStyle(.plain)
            ThemePickerChip(theme: currentTheme)
            Text("M-Series")
                .font(.system(size: 7))
                .foregroundStyle(SX.textTertiary)
                .padding(.horizontal, 5).padding(.vertical, 1)
                .background(Capsule().fill(SX.glassSoft))
                .overlay(Capsule().strokeBorder(SX.glassBorder, lineWidth: 1))
        }
        .padding(.horizontal, 12).padding(.vertical, 5)
        .background(SX.glassMid)
        .sheet(isPresented: $showLog) { LogSheet() }
    }
}

struct TaskListView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @Binding var selected: UUID?
    private let columns = [
        GridItem(.adaptive(minimum: 280, maximum: 420), spacing: 10)
    ]
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 10) {
                ForEach(manager.tasks) { task in
                    TaskCard(task: task, isSelected: selected == task.id)
                        .onTapGesture { selected = task.id }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .animation(SX.spLift, value: manager.tasks)
        }
        .contextMenu(forSelectionType: UUID.self) { items in
            ForEach(Array(items), id: \.self) { id in
                if let t = manager.tasks.first(where: { $0.id == id }) {
                    Button { manager.removeTask(t) } label: { Label("Remove", systemImage: "trash") }
                }
            }
        }
    }
}

struct TaskCard: View {
    let task: MediaTask
    let isSelected: Bool
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var hover = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Top row: icon + name + status pill
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(task.status.color.opacity(0.14))
                        .frame(width: 32, height: 32)
                    Image(systemName: task.status.icon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(task.status.color)
                        .symbolEffect(.bounce, options: .repeating,
                                     value: [.transcribing, .dubbing, .rendering].contains(task.status))
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(task.fileName)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SX.textPrimary)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(task.fileSizeFormatted).font(.system(size: 8)).foregroundStyle(SX.textSecondary)
                        if let res = task.resolution {
                            Text(res).font(.system(size: 8, weight: .medium)).foregroundStyle(SX.textSecondary)
                        }
                        if task.durationSeconds > 0 {
                            Text(fd(task.durationSeconds)).font(.system(size: 8)).foregroundStyle(SX.textTertiary)
                        }
                    }
                }
                Spacer()
                StatusPill(icon: task.status.icon, text: task.status.rawValue, color: task.status.color)
            }

            // Meta row
            HStack(spacing: 4) {
                if let lang = task.detectedLanguage {
                    HStack(spacing: 2) {
                        Image(systemName: "waveform").font(.system(size: 7))
                        Text(SpokenLanguage.displayName(for: lang))
                    }
                    .font(.system(size: 8, weight: .semibold))
                    .padding(.horizontal, 5).padding(.vertical, 2)
                    .background(Capsule().fill(SX.accentBg))
                    .foregroundStyle(SX.accent)
                }
                Text(task.targetLanguageDisplay)
                    .font(.system(size: 8))
                    .foregroundStyle(SX.textSecondary)
                if let codec = task.videoCodec, !codec.isEmpty {
                    Text(codec)
                        .font(.system(size: 8)).foregroundStyle(SX.textTertiary)
                }
                Spacer()
                if [.queued, .completed, .failed].contains(task.status) {
                    Button { manager.removeTask(task) } label: {
                        Image(systemName: "xmark.circle.fill").font(.system(size: 11))
                    }.buttonStyle(.plain).foregroundStyle(SX.textTertiary)
                        .opacity(hover ? 1 : 0.4)
                }
            }

            // Output link for completed
            if let outURL = task.outputURL, task.status == .completed {
                Button {
                    NSWorkspace.shared.activateFileViewerSelecting([outURL])
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "folder.fill").font(.system(size: 7))
                        Text(outURL.deletingLastPathComponent().lastPathComponent).font(.system(size: 8, weight: .medium))
                        Image(systemName: "arrow.right.circle.fill").font(.system(size: 9))
                    }
                    .foregroundStyle(SX.accent)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(SX.accentBg))
                    .overlay(Capsule().strokeBorder(SX.accent.opacity(0.2), lineWidth: 1))
                }.buttonStyle(.plain)
            }

            // Progress bar
            if task.status.isRunning {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(SX.border.opacity(0.4))
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(LinearGradient(
                                colors: [SX.accent, SX.accent.opacity(0.7)],
                                startPoint: .leading, endPoint: .trailing))
                            .frame(width: max(4, geo.size.width * CGFloat(task.progress)), height: 4)
                            .animation(.easeInOut(duration: 0.25), value: task.progress)
                            .shadow(color: SX.accent.opacity(0.3), radius: 3)
                    }
                }.frame(height: 4)
            }
        }
        .padding(12)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: SX.rTile, style: .continuous)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: SX.rTile, style: .continuous)
                    .fill(Color.white.opacity(hover ? 0.75 : 0.55))
                RoundedRectangle(cornerRadius: SX.rTile, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                isSelected ? SX.accent.opacity(0.5) : SX.glassEdge,
                                Color.white.opacity(0.0)
                            ],
                            startPoint: .top, endPoint: .bottom),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: SX.rTile, style: .continuous)
                .strokeBorder(isSelected ? SX.accent.opacity(0.6) : SX.glassBorder, lineWidth: 1)
        )
        .scaleEffect(hover ? 1.015 : 1.0)
        .shadow(color: hover ? SX.glowRed : Color.clear, radius: hover ? 16 : 0, x: 0, y: hover ? 6 : 0)
        .shadow(color: SX.glowSoft, radius: 4, x: 0, y: 2)
        .onHover { hover = $0 }
        .animation(SX.spLift, value: hover)
        .contextMenu {
            if task.status == .completed, let out = task.outputURL {
                Button { NSWorkspace.shared.activateFileViewerSelecting([out]) } label: {
                    Label("Show in Finder", systemImage: "folder") }
            }
            Button { manager.removeTask(task) } label: {
                Label("Remove", systemImage: "trash") }
        }
    }

    func fd(_ s: Double) -> String {
        let h = Int(s) / 3600, m = (Int(s) % 3600) / 60, sec = Int(s) % 60
        if h > 0 { return "\(h)h \(m)m" }; if m > 0 { return "\(m)m \(sec)s" }; return "\(sec)s"
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