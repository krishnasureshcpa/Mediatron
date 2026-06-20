import SwiftUI

// MARK: - Background Themes
/// User-selectable background styles — addressing the request for variety beyond Swiss white.
enum BackgroundTheme: String, CaseIterable, Identifiable {
    case mesh        = "Mesh"
    case cyber       = "Cyber"
    case retro       = "Retro"
    case fractal     = "Fractal"
    case liquid      = "Liquid"
    case aurora      = "Aurora"

    var id: String { rawValue }
    var isDark: Bool {
        switch self {
        case .cyber, .aurora: return true
        case .mesh, .retro, .fractal, .liquid: return false
        }
    }
    var icon: String {
        switch self {
        case .mesh:    return "sparkles"
        case .cyber:   return "grid"
        case .retro:   return "square.grid.3x3"
        case .fractal: return "function"
        case .liquid:  return "drop.fill"
        case .aurora:  return "cloud.fog.fill"
        }
    }
    @ViewBuilder
    func view() -> some View {
        switch self {
        case .mesh:    MeshBackground()
        case .cyber:   CyberGridBackground()
        case .retro:   RetroGridBackground()
        case .fractal: FractalGlassBackground()
        case .liquid:  LiquidMetalBackground()
        case .aurora:  AuroraBackground()
        }
    }
}

// MARK: - ThemeBackground
/// Convenience view — wraps theme.view() with consistent sizing.
struct ThemeBackground: View {
    var theme: BackgroundTheme
    var body: some View {
        theme.view().ignoresSafeArea()
    }
}

// MARK: - ThemePickerChip
/// Small pill button that shows current theme + cycles on tap.
struct ThemePickerChip: View {
    @Binding var theme: BackgroundTheme
    var body: some View {
        Button {
            let all = BackgroundTheme.allCases
            let idx = all.firstIndex(of: theme) ?? 0
            withAnimation(SX.spLift) { theme = all[(idx + 1) % all.count] }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: theme.icon).font(.system(size: 8))
                Text(theme.rawValue.uppercased()).font(.system(size: 8, weight: .bold)).tracking(1)
            }
            .foregroundStyle(SX.accent)
            .padding(.horizontal, 7).padding(.vertical, 3)
            .background(Capsule().fill(SX.accentBg))
            .overlay(Capsule().strokeBorder(SX.accent.opacity(0.25), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help("Cycle background theme (⌘/)")
    }
}

// MARK: - CyberGrid (Retro 80s Perspective Grid)
/// Animated horizon-line grid with neon accent bleed — synthwave aesthetic.
/// Inspired by tron/framer Cyber Grid.
struct CyberGridBackground: View {
    var lineColor: Color = SX.accent
    var intensity: Double = 1.0
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { tl in
                let t = tl.date.timeIntervalSince1970
                ZStack {
                    LinearGradient(
                        colors: [Color(red: 0.08, green: 0.04, blue: 0.14),
                                 Color(red: 0.02, green: 0.01, blue: 0.06)],
                        startPoint: .top, endPoint: .bottom
                    ).ignoresSafeArea()

                    // Horizontal perspective lines (ground plane)
                    let horizonY = geo.size.height * 0.55
                    Canvas { ctx, size in
                        let groundPath = Path { p in
                            p.move(to: CGPoint(x: 0, y: horizonY))
                            p.addLine(to: CGPoint(x: size.width, y: horizonY))
                        }
                        ctx.stroke(groundPath,
                                   with: .color(lineColor.opacity(0.8 * intensity)),
                                   lineWidth: 1.5)

                        // Horizontal stripes (perspective-spaced)
                        for i in 0..<18 {
                            let depth = Double(i) / 18.0
                            let y = horizonY + pow(depth, 1.6) * (size.height - horizonY)
                            // scrolling with time
                            let scroll = (t * 0.08).truncatingRemainder(dividingBy: 1.0/18.0)
                            let offset = scroll * (size.height - horizonY) * 0.15
                            let alpha = (0.4 - depth * 0.3) * intensity
                            var path = Path()
                            path.move(to: CGPoint(x: 0, y: y + offset))
                            path.addLine(to: CGPoint(x: size.width, y: y + offset))
                            ctx.stroke(path, with: .color(lineColor.opacity(alpha)), lineWidth: 1)
                        }

                        // Vertical vanishing lines
                        let cx = size.width / 2
                        let count = 20
                        for i in -count/2...count/2 {
                            let spacing = 40.0
                            let targetX = cx + Double(i) * spacing
                            var path = Path()
                            path.move(to: CGPoint(x: cx, y: horizonY))
                            path.addLine(to: CGPoint(x: targetX, y: size.height))
                            ctx.stroke(path,
                                       with: .color(lineColor.opacity(0.4 * intensity)),
                                       lineWidth: 1)
                        }

                        // Sun glow at horizon
                        let sunRect = CGRect(
                            x: cx - 90, y: horizonY - 90,
                            width: 180, height: 90
                        )
                        ctx.fill(Path(ellipseIn: sunRect),
                                 with: .radialGradient(
                                    Gradient(colors: [
                                        Color(hue: 0.08, saturation: 0.9, brightness: 1.0),
                                        Color(hue: 0.95, saturation: 0.7, brightness: 0.5).opacity(0)
                                    ]),
                                    center: CGPoint(x: cx, y: horizonY),
                                    startRadius: 0, endRadius: 90))
                    }
                }
            }
        }
    }
}

// MARK: - Retro Grid (Cutting Mat Wallpaper)
/// Diamond-cut grid pattern — green-on-white cutting mat aesthetic.
struct RetroGridBackground: View {
    var spacing: CGFloat = 24
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Color.white
                Canvas { ctx, size in
                    // Light green base tint
                    ctx.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .color(Color(red: 0.95, green: 0.98, blue: 0.95)))
                    // Fine grid
                    let fine = spacing / 4
                    var x: CGFloat = 0
                    while x < size.width {
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                        ctx.stroke(p,
                                   with: .color(Color(red: 0.75, green: 0.88, blue: 0.78).opacity(0.5)),
                                   lineWidth: 0.5)
                        x += fine
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(p,
                                   with: .color(Color(red: 0.75, green: 0.88, blue: 0.78).opacity(0.5)),
                                   lineWidth: 0.5)
                        y += fine
                    }
                    // Major grid
                    x = 0
                    while x < size.width {
                        var p = Path()
                        p.move(to: CGPoint(x: x, y: 0))
                        p.addLine(to: CGPoint(x: x, y: size.height))
                        ctx.stroke(p,
                                   with: .color(Color(red: 0.4, green: 0.75, blue: 0.5)),
                                   lineWidth: 0.8)
                        x += spacing
                    }
                    y = 0
                    while y < size.height {
                        var p = Path()
                        p.move(to: CGPoint(x: 0, y: y))
                        p.addLine(to: CGPoint(x: size.width, y: y))
                        ctx.stroke(p,
                                   with: .color(Color(red: 0.4, green: 0.75, blue: 0.5)),
                                   lineWidth: 0.8)
                        y += spacing
                    }
                }
            }
        }
    }
}

// MARK: - Fractal Glass Background
/// Noise-based fractal glass effect using TimelineView + Canvas.
/// Slow-drifting color fields with subtle noise overlay.
struct FractalGlassBackground: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince1970
            ZStack {
                // Slowly morphing color blobs
                ForEach(0..<5, id: \.self) { i in
                    let angle = Double(i) * .pi * 2 / 5 + t * 0.04
                    let radius: CGFloat = 180
                    let cx = 0.5 + cos(angle) * 0.25
                    let cy = 0.5 + sin(angle) * 0.25
                    RadialGradient(
                        colors: [
                            Color(hue: Double(i) / 5, saturation: 0.5, brightness: 0.85).opacity(0.35),
                            Color.clear
                        ],
                        center: UnitPoint(x: cx, y: cy),
                        startRadius: 0, endRadius: radius
                    ).blur(radius: 40)
                }
                // Tinted white overlay for glass feel
                Color.white.opacity(0.55)
                // Fine noise dot pattern
                Canvas { ctx, size in
                    for row in stride(from: 0, to: size.height, by: 6) {
                        for col in stride(from: 0, to: size.width, by: 6) {
                            let jitterX = sin(row * 0.1 + col * 0.05 + t) * 0.5 + 0.5
                            if jitterX > 0.85 {
                                let dot = CGRect(x: col, y: row, width: 1, height: 1)
                                ctx.fill(Path(ellipseIn: dot),
                                         with: .color(Color.black.opacity(0.08)))
                            }
                        }
                    }
                }
                .blur(radius: 0.5)
                .ignoresSafeArea()
            }
        }
    }
}

// MARK: - Liquid Metal Background
/// Flowing metallic sheen using radial gradients + blend.
/// A stand-in for the Framer LiquidMetal component without needing a .metal shader.
struct LiquidMetalBackground: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince1970
            ZStack {
                // Metal-toned base
                LinearGradient(
                    colors: [
                        Color(red: 0.88, green: 0.90, blue: 0.95),
                        Color(red: 0.70, green: 0.74, blue: 0.82),
                        Color(red: 0.90, green: 0.88, blue: 0.95),
                        Color(red: 0.78, green: 0.80, blue: 0.88)
                    ],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ).ignoresSafeArea()
                // Drifting highlight blobs (simulated metal sheen)
                ForEach(0..<4, id: \.self) { i in
                    Ellipse()
                        .fill(LinearGradient(
                            colors: [Color.white.opacity(0.6), Color.white.opacity(0.0)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: 500, height: 240)
                        .rotationEffect(.degrees(Double(i) * 45 + t * 4))
                        .offset(
                            x: cos(t * 0.15 + Double(i)) * 200,
                            y: sin(t * 0.12 + Double(i) * 1.3) * 150
                        )
                        .blendMode(.overlay)
                }
            }
        }
    }
}

// MARK: - Aurora Background
/// Soft northern-lights style waves.
struct AuroraBackground: View {
    var body: some View {
        TimelineView(.animation) { tl in
            let t = tl.date.timeIntervalSince1970
            ZStack {
                LinearGradient(
                    colors: [Color(red: 0.06, green: 0.12, blue: 0.18),
                             Color(red: 0.02, green: 0.04, blue: 0.08)],
                    startPoint: .top, endPoint: .bottom)
                    .ignoresSafeArea()
                ForEach(0..<3, id: \.self) { i in
                    LinearGradient(
                        colors: [
                            Color(hue: 0.55 + Double(i) * 0.08, saturation: 0.8, brightness: 0.9).opacity(0.4),
                            Color(hue: 0.62 + Double(i) * 0.07, saturation: 0.7, brightness: 0.7).opacity(0.0)
                        ],
                        startPoint: .top, endPoint: .bottom)
                    .mask(
                        GeometryReader { geo in
                            Path { path in
                                let midX = geo.size.width / 2
                                path.move(to: CGPoint(x: 0, y: geo.size.height * 0.4))
                                for x in stride(from: 0, through: geo.size.width, by: 8) {
                                    let wave = sin((Double(x) * 0.01) + t * 0.3 + Double(i) * 1.2) * 60
                                    path.addLine(to: CGPoint(x: x, y: geo.size.height * 0.4 + wave))
                                }
                                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height))
                                path.addLine(to: CGPoint(x: 0, y: geo.size.height))
                                path.closeSubpath()
                            }
                        }
                    )
                    .blendMode(.screen)
                }
            }
        }
    }
}

// MARK: - Split Text Reveal
/// Reveals text character-by-character with staggered spring animation.
struct SplitTextReveal: View {
    let text: String
    var font: Font = .system(size: 42, weight: .black)
    var color: Color = SX.textPrimary
    var tracking: CGFloat = 4
    var trigger: Bool = true

    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(text.enumerated()), id: \.offset) { idx, ch in
                Text(String(ch))
                    .font(font)
                    .tracking(tracking)
                    .foregroundStyle(color)
                    .opacity(trigger ? 1 : 0)
                    .offset(y: trigger ? 0 : 14)
                    .animation(
                        .spring(response: 0.5, dampingFraction: 0.65)
                        .delay(Double(idx) * 0.035),
                        value: trigger
                    )
            }
        }
    }
}

// MARK: - Arc Text
/// Renders text along a circular arc.
struct ArcText: View {
    let text: String
    var radius: CGFloat = 90
    var font: Font = .system(size: 11, weight: .semibold)
    var color: Color = SX.textSecondary
    var tracking: CGFloat = 2
    var startAngle: Double = -90
    var endAngle: Double = 90

    var body: some View {
        ZStack {
            ForEach(Array(text.enumerated()), id: \.offset) { idx, ch in
                let chars = text.count
                let angle = startAngle + (endAngle - startAngle) *
                    (Double(idx) / Double(max(chars - 1, 1)))
                let rad = angle * .pi / 180
                Text(String(ch))
                    .font(font)
                    .foregroundStyle(color)
                    .offset(x: radius * cos(rad), y: radius * sin(rad))
                    .rotationEffect(.degrees(angle + 90))
                    .tracking(tracking)
            }
        }
    }
}

// MARK: - Animated Counter
/// A number that smoothly counts to target value using timeline animation.
struct AnimatedCounter: View {
    var value: Double
    var format: (Double) -> String = { String(Int($0)) }
    var font: Font = .system(size: 28, weight: .bold, design: .rounded)
    var color: Color = SX.textPrimary

    @State private var displayed: Double = 0
    @State private var startAnimation: Bool = false

    var body: some View {
        Text(format(displayed))
            .font(font)
            .foregroundStyle(color)
            .monospacedDigit()
            .onChange(of: value) { _, new in
                withAnimation(.easeOut(duration: 0.6)) {
                    displayed = new
                }
            }
            .onAppear { displayed = value }
    }
}

// MARK: - Hourglass Loader
/// Animated hourglass that flips between rotations. Indicates "working".
struct HourglassLoader: View {
    var size: CGFloat = 24
    var color: Color = SX.accent
    @State private var rotate = false

    var body: some View {
        Image(systemName: "hourglass")
            .font(.system(size: size, weight: .semibold))
            .foregroundStyle(color)
            .rotationEffect(.degrees(rotate ? 180 : 0))
            .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false), value: rotate)
            .symbolEffect(.pulse, options: .repeating)
            .onAppear { rotate = true }
    }
}

// MARK: - Logo Preloader
/// Logo that scales/pulses for a cinematic pre-launch feel.
struct LogoPreloader: View {
    var accent: Color = SX.accent
    var size: CGFloat = 72
    var pulse: Bool = true

    @State private var scale: CGFloat = 0.9
    @State private var haloScale: CGFloat = 0.6
    @State private var haloOpacity: Double = 0.7

    var body: some View {
        ZStack {
            // Pulsing halo ring
            Circle()
                .stroke(accent.opacity(0.35), lineWidth: 2)
                .frame(width: size + 30, height: size + 30)
                .scaleEffect(haloScale)
                .opacity(haloOpacity)
                .animation(
                    pulse ? .easeOut(duration: 1.2).repeatForever(autoreverses: true)
                          : .linear(duration: 0),
                    value: haloScale
                )

            // Logo square with rounded corners + gradient
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(LinearGradient(
                    colors: [accent, accent.opacity(0.75)],
                    startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: size, height: size)
                .overlay(
                    Image(systemName: "waveform")
                        .font(.system(size: size * 0.36, weight: .bold))
                        .foregroundColor(.white)
                )
                .shadow(color: accent.opacity(0.4), radius: 24, y: 8)
                .scaleEffect(scale)
                .animation(
                    pulse ? .spring(response: 0.9, dampingFraction: 0.5)
                        .repeatForever(autoreverses: true)
                          : .linear(duration: 0),
                    value: scale
                )
        }
        .onAppear {
            scale = 1.0
            haloScale = 1.3
            haloOpacity = 0
        }
    }
}

// MARK: - Kinetic Nav
/// Tab-style nav with an accent-colored sliding indicator.
struct KineticNav<Item: Hashable>: View {
    let items: [Item]
    @Binding var selection: Item
    var icon: (Item) -> String
    var label: (Item) -> String

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                Button {
                    withAnimation(SX.spLift) { selection = item }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: icon(item)).font(.system(size: 10, weight: .semibold))
                        Text(label(item))
                            .font(.system(size: 11, weight: .semibold))
                            .tracking(1)
                    }
                    .foregroundStyle(selection == item ? SX.accent : SX.textSecondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(selection == item ? SX.accent.opacity(0.12) : Color.clear)
                    )
                    .overlay(
                        Capsule()
                            .strokeBorder(selection == item ? SX.accent.opacity(0.3) : Color.clear, lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Capsule().fill(SX.glassSoft))
        .overlay(Capsule().strokeBorder(SX.glassBorder, lineWidth: 1))
    }
}

// MARK: - Scroll Progress Indicator
/// Thin bar at top of scrollable area showing progress.
struct ScrollProgressIndicator: View {
    var progress: Double  // 0.0 ... 1.0
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Rectangle().fill(SX.glassSoft).frame(height: 3)
                Rectangle()
                    .fill(LinearGradient(
                        colors: [SX.accent, SX.accent.opacity(0.6)],
                        startPoint: .leading, endPoint: .trailing))
                    .frame(width: max(3, geo.size.width * CGFloat(progress)), height: 3)
                    .animation(.easeOut(duration: 0.2), value: progress)
                    .shadow(color: SX.accent.opacity(0.3), radius: 4, x: 0, y: 0)
            }
        }.frame(height: 3)
    }
}

// MARK: - LiquidMetalView (SwiftUI-only shimmer)
/// A shimmer overlay that slides light across surfaces.
struct LiquidMetalView<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var shimmer = false

    var body: some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.0),
                            Color.white.opacity(0.35),
                            Color.white.opacity(0.0)
                        ],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.5)
                    .offset(x: shimmer ? geo.size.width : -geo.size.width * 0.5)
                    .blendMode(.overlay)
                }
            )
            .clipped()
            .onAppear {
                withAnimation(.easeInOut(duration: 2.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
    }
}
