import os, re
os.chdir('/Users/sgkrishna/MasterBase/Mediatron')

c = open('Views.swift').read()

# 1. Add Z-depth shadows to SX tokens
c = c.replace(
    'static let rPanel: CGFloat = 0',
    'static let rPanel: CGFloat = 0\n    static let shadowSm = Color.black.opacity(0.08)\n    static let shadowMd = Color.black.opacity(0.12)'
)

# 2. Add liquid gradient to Welcome
old_welcome = 'GX.canvas.ignoresSafeArea()'
new_welcome = '''// Liquid animated gradient
            TimelineView(.animation) {{ timeline in
                let t = timeline.date.timeIntervalSince1970
                EllipticalGradient(
                    colors: [SX.accent.opacity(0.06), Color.blue.opacity(0.04), Color.white],
                    center: UnitPoint(x: 0.5 + sin(t*0.3)*0.15, y: 0.4 + cos(t*0.25)*0.1)
                ).ignoresSafeArea()
            }}'''
c = c.replace(old_welcome, new_welcome)

# 3. Add Z-depth shadow to CommandPalette
old_palette = '.background(GX.elevated).cornerRadius(GX.rPanel)'
new_palette = '.background(SX.elevated).cornerRadius(SX.rPanel).shadow(color: SX.shadowMd, radius: 16, x: 0, y: 8)'
c = c.replace(old_palette, new_palette)

# 4. Add accessibility label to process button
old_process = 'Button { Task {{ await manager.startProcessing() }} }}'
old_process2 = 'Button {{ Task {{ await manager.startProcessing() }} }}'
# Use regex for the process button
c = re.sub(
    r'(Button \{ Task \{ await manager\.startProcessing\(\) \} \} label: \{ HStack)',
    r'\1.accessibilityLabel("Start processing all queued files").accessibilityHint("Begins batch media processing")',
    c
)

open('Views.swift','w').write(c)
print('Views upgraded:', len(c), 'chars')
