# Task: TASK_001_Restore_Views_Swift

## Description
Views.swift was corrupted during a minification attempt. The file contains all SwiftUI views for Mediatron including: Welcome screen, Sidebar, Task cards, Command palette, Settings, and the Swiss International Style (SX) design tokens. This task restores the file to a compilable state with all features intact.

## Dependencies
- Depends On: None
- Blocks: All future compiles

## Acceptance Criteria
- [ ] Views.swift compiles without errors with `swiftc`
- [ ] All views render: Welcome, Sidebar, MainArea, TaskCard, CommandPalette, Settings
- [ ] SX design tokens present (Swiss International Style: white bg, black text, #FF3000 accent)
- [ ] Liquid spring physics animations (response 0.25-0.6s, damping 0.65-0.9)
- [ ] MenuBarExtra scene compiles
- [ ] Output folder visible in toolbar
- [ ] Clickable output files on completed tasks
- [ ] Keyboard shortcuts: ⌘K palette, ⌘O open, ⌘↩ process

## Implementation Plan

### 1. Restore SX Design Tokens
- White canvas, black text, Swiss Red accent
- Spring physics animations
- Z-depth shadows

### 2. Rebuild Core Views
- WelcomeView with liquid gradient + drop zone
- SidebarView with preset picker, toggles
- MainAreaView with toolbar, task list
- TaskCard with progress, codec info, output path
- CommandPalette (⌘K)
- StatusStrip + LogSheet
- SettingsView with engine deps

### 3. Compile & Verify
```bash
swiftc -O -sdk $(xcrun --show-sdk-path --sdk macosx) -target arm64-apple-macosx14.0 -framework SwiftUI -framework AppKit -framework Foundation -framework Combine -framework AVFoundation -framework UniformTypeIdentifiers -o MediatronBinary Models.swift Engine.swift Views.swift App.swift LiquidWindow.swift
```

## Testing Checklist
- [ ] Compiles with 0 errors
- [ ] App launches and shows Welcome view
- [ ] Drag-drop media files works
- [ ] Sidebar toggles function
- [ ] ⌘K opens command palette
- [ ] Process button starts pipeline
- [ ] Completed tasks show clickable output path
- [ ] MenuBarExtra shows in menu bar

## Code References
- `Views.swift` - Primary file to restore
- `Models.swift` - Data models (unchanged)
- `Engine.swift` - Processing pipeline (unchanged)
- `App.swift` - App entry point with SX references
- `LiquidWindow.swift` - Custom NSWindow

## Risk Assessment
- **Syntax Risk**: Minified Swift can break parser. Mitigation: Write fully formatted code.
- **Token Mismatch**: SX tokens must match App.swift references. Mitigation: Use typealias GX = SX.

## Future Considerations
- Migrate to Xcode project for better tooling
- Add XcodeBuildMCP for CI/CD pipeline

## Resources
- Apple HIG: developer.apple.com/design/human-interface-guidelines
- Swiss International Style: Design philosophy document in project root
