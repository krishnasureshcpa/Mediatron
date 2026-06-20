import SwiftUI
import AppKit

final class LiquidWindow: NSWindow {
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView], backing: backingStoreType, defer: flag)
        self.titlebarAppearsTransparent = true
        self.isMovableByWindowBackground = true
        self.backgroundColor = .clear
        self.isOpaque = false
        self.hasShadow = true
        self.contentView?.wantsLayer = true
        self.contentView?.layer?.cornerRadius = 16
        self.contentView?.layer?.masksToBounds = true
        self.contentView?.layer?.borderWidth = 0.5
        self.contentView?.layer?.borderColor = NSColor.black.withAlphaComponent(0.1).cgColor
    }
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}