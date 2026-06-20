#!/usr/bin/env python3
"""Generate a premium Mediatron app icon — Swiss Red #FF3000 on white squircle."""

import os, sys, subprocess, math, shutil

def create_icon_set(output_dir):
    iconset = os.path.join(output_dir, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)
    
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "Pillow", "--quiet"], check=True)
        from PIL import Image, ImageDraw
    
    sizes = {
        "icon_16x16.png": 16,
        "icon_16x16@2x.png": 32,
        "icon_32x32.png": 32,
        "icon_32x32@2x.png": 64,
        "icon_128x128.png": 128,
        "icon_128x128@2x.png": 256,
        "icon_256x256.png": 256,
        "icon_256x256@2x.png": 512,
        "icon_512x512.png": 512,
        "icon_512x512@2x.png": 1024,
    }
    
    for filename, size in sizes.items():
        img = make_icon(size)
        img.save(os.path.join(iconset, filename))
    
    return iconset


ACCENT_RED = (255, 48, 0)       # #FF3000
ACCENT_DARK = (200, 38, 0)      # darker red for gradient base
WHITE = (255, 255, 255, 255)
NEAR_WHITE = (250, 250, 252)   # barely off-white canvas


def squircle_mask(size):
    """Apple-style G2 continuous squircle mask."""
    from PIL import Image, ImageDraw
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    r = int(size * 0.225)
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=255)
    return mask


def make_icon(size):
    from PIL import Image, ImageDraw
    import math
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # ── Background: white canvas with whisper-thin accent tint gradient ──
    for y in range(size):
        t = y / size
        r = int(NEAR_WHITE[0] - t * 3)
        g = int(NEAR_WHITE[1] - t * 2)
        b = int(NEAR_WHITE[2] + t * 3)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # ── Center accent square: rounded rect with red gradient ──
    margin = int(size * 0.20)
    icon_size = size - 2 * margin
    x0, y0 = margin, margin
    x1, y1 = margin + icon_size, margin + icon_size
    cx = x0 + icon_size // 2
    cy = y0 + icon_size // 2
    radius_val = icon_size // 2
    
    # Draw the rounded rect as horizontal line slices
    for y in range(y0, y1):
        t = (y - y0) / icon_size
        r = int(ACCENT_RED[0] - t * 55)
        g = int(ACCENT_RED[1] - t * 10)
        b = int(ACCENT_RED[2])
        
        half_w = int(math.sqrt(max(0, radius_val**2 - (y - cy)**2)))
        if half_w > 0:
            left = max(x0, cx - half_w)
            right = min(x1, cx + half_w)
            if right > left:
                draw.line([(left, y), (right, y)], fill=(r, g, b, 255))
    
    # ── Waveform bars (white) ──
    if size >= 64:
        bar_color = (255, 255, 255, 245)
        bar_count = 5
        bar_width = max(3, int(icon_size * 0.07))
        bar_gap = max(2, int(icon_size * 0.045))
        total_w = bar_count * bar_width + (bar_count - 1) * bar_gap
        start_x = cx - total_w // 2
        
        bar_heights = [0.45, 0.75, 1.0, 0.65, 0.40]
        max_h = int(icon_size * 0.32)
        
        for i, h_ratio in enumerate(bar_heights):
            bar_h = max(4, int(max_h * h_ratio))
            bx = start_x + i * (bar_width + bar_gap)
            by = cy - bar_h // 2
            draw.rounded_rectangle(
                [bx, by, bx + bar_width - 1, by + bar_h - 1],
                radius=bar_width // 2,
                fill=bar_color
            )
    
    # ── Subtle glow halo behind icon square ──
    glow_size = icon_size + int(size * 0.08)
    glow_x0 = cx - glow_size // 2
    glow_y0 = cy - glow_size // 2
    glow_x1 = glow_x0 + glow_size
    glow_y1 = glow_y0 + glow_size
    draw.rounded_rectangle(
        [glow_x0, glow_y0, glow_x1, glow_y1],
        radius=int(glow_size * 0.22),
        fill=ACCENT_RED + (25,)  # very faint red glow
    )
    
    # ── Apply squircle mask (Apple-style) ──
    if size >= 128:
        mask = squircle_mask(size)
        img.putalpha(mask)
    
    return img


if __name__ == "__main__":
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    iconset = create_icon_set(output_dir)
    icns_path = os.path.join(output_dir, "AppIcon.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", icns_path], check=True)
    shutil.rmtree(iconset)
    print(f"Mediatron icon generated: {icns_path}")