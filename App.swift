import SwiftUI
import AppKit
import UniformTypeIdentifiers

// MARK: - App Delegate
final class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        
        // Liquid UI window engineering
        DispatchQueue.main.async {
            for window in NSApp.windows {
                window.titlebarAppearsTransparent = true
                window.isMovableByWindowBackground = true
                window.backgroundColor = .white
                window.hasShadow = true
            }
        }
        
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "waveform.circle.fill", accessibilityDescription: "Mediatron")
            button.title = ""
            button.action = #selector(statusItemClicked)
            button.target = self
        }
        
        buildMainMenu()
    }
    
    @objc func statusItemClicked() {
        NSApp.activate(ignoringOtherApps: true)
        for window in NSApp.windows {
            window.makeKeyAndOrderFront(nil)
        }
    }
    
    func buildMainMenu() {
        let mainMenu = NSMenu()
        
        // App menu
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About Mediatron", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Preferences...", action: nil, keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide Mediatron", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        
        let appMenuItem = NSMenuItem()
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        
        // File menu
        let fileMenu = NSMenu(title: "File")
        fileMenu.addItem(NSMenuItem(title: "Open Media...", action: nil, keyEquivalent: "o"))
        fileMenu.addItem(NSMenuItem(title: "Open Folder...", action: nil, keyEquivalent: "o").withModifier(.command.union(.shift)) as! NSMenuItem)
        fileMenu.addItem(.separator())
        fileMenu.addItem(NSMenuItem(title: "Clear Queue", action: nil, keyEquivalent: ""))
        
        let fileMenuItem = NSMenuItem()
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)
        
        // Process menu
        let processMenu = NSMenu(title: "Process")
        processMenu.addItem(NSMenuItem(title: "Start Processing", action: nil, keyEquivalent: "\r"))
        processMenu.addItem(NSMenuItem(title: "Stop", action: nil, keyEquivalent: "."))
        
        let processMenuItem = NSMenuItem()
        processMenuItem.submenu = processMenu
        mainMenu.addItem(processMenuItem)
        
        NSApp.mainMenu = mainMenu
    }
}

extension NSMenuItem {
    func withModifier(_ modifier: NSEvent.ModifierFlags) -> NSMenuItem {
        self.keyEquivalentModifierMask = modifier
        return self
    }
}

// MARK: - App Entry Point
@main
struct MediatronApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var manager = MediaProcessingManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(manager)
                .frame(minWidth: 1100, idealWidth: 1280, minHeight: 720, idealHeight: 860)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands { CommandGroup(replacing: .newItem) {} }
        
        // MenuBarExtra — dynamic mini-utility
        MenuBarExtra("Mediatron", systemImage: "waveform.circle.fill") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Mediatron").font(.headline)
                    Spacer()
                    Circle().fill(manager.isProcessing ? SX.accent : Color.green).frame(width: 6, height: 6)
                }
                if manager.isProcessing {
                    ProgressView(value: manager.overallProgress).progressViewStyle(.linear)
                    Text("\(manager.activeTasks) active · \(manager.completedTasks) done").font(.caption).foregroundStyle(.secondary)
                } else if manager.tasks.isEmpty {
                    Text("No active jobs").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("\(manager.tasks.count) queued").font(.caption).foregroundStyle(.secondary)
                }
                Divider()
                Button("Open Mediatron") { NSApp.activate(ignoringOtherApps: true) }
                Button("Quit") { NSApp.terminate(nil) }.keyboardShortcut("q")
            }
            .padding(12)
            .frame(width: 220)
        }
        .menuBarExtraStyle(.window)
        
        Settings {
            SettingsView()
                .environmentObject(manager)
                .frame(width: 560, height: 480)
        }
    }
}

// MARK: - Root Content View
struct ContentView: View {
    @EnvironmentObject var manager: MediaProcessingManager
    @State private var showPalette = false
    @State private var sidebarWidth: CGFloat = 280
    @AppStorage("bgTheme") private var bgThemeRaw = BackgroundTheme.mesh.rawValue

    var body: some View {
        let currentTheme = BackgroundTheme(rawValue: bgThemeRaw) ?? .mesh

        ZStack {
            // App-wide animated background
            Group {
                if manager.phase == .welcome {
                    WelcomeView(backgroundTheme: currentTheme, onCycleTheme: cycleTheme)
                } else {
                    HSplitView {
                        SidebarView()
                            .frame(minWidth: 240, idealWidth: 270, maxWidth: 320)

                        MainAreaView(backgroundTheme: currentTheme)
                            .frame(minWidth: 700)
                    }
                }
            }

            // ⌘K Command Palette
            if showPalette {
                Color.black.opacity(0.4).ignoresSafeArea().onTapGesture { showPalette = false }
                CommandPalette(isPresented: $showPalette)
                    .environmentObject(manager)
                    .frame(width: 380, height: 300)
            }
        }
        .background(SX.canvas)
        .background(Material.ultraThin)
        .preferredColorScheme(.light)
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                if event.modifierFlags.contains(.command) && event.keyCode == 40 { // K
                    showPalette.toggle()
                    return nil
                }
                if event.modifierFlags.contains(.command) && event.keyCode == 47 { // /
                    cycleTheme()
                    return nil
                }
                return event
            }
        }
    }

    private func cycleTheme() {
        let all = BackgroundTheme.allCases
        let current = BackgroundTheme(rawValue: bgThemeRaw) ?? .mesh
        let idx = all.firstIndex(of: current) ?? 0
        let next = all[(idx + 1) % all.count]
        withAnimation(SX.spStandard) { bgThemeRaw = next.rawValue }
    }
}