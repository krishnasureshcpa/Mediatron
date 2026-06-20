#!/usr/bin/env python3
"""Generate a premium Apple-style app icon for Mediatron."""
import os, sys, subprocess, struct, math

def create_icon_set(output_dir):
    """Generate all required icon sizes using CoreGraphics via PyObjC or raw pixel art."""
    iconset = os.path.join(output_dir, "AppIcon.iconset")
    os.makedirs(iconset, exist_ok=True)
    
    # Try to use PIL/Pillow for icon generation
    try:
        from PIL import Image, ImageDraw, ImageFilter, ImageFont
    except ImportError:
        subprocess.run([sys.executable, "-m", "pip", "install", "Pillow", "--quiet"], check=True)
        from PIL import Image, ImageDraw, ImageFilter, ImageFont
    
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

def squircle_mask(size):
    """Create a squircle (G2 curvature continuous) mask."""
    from PIL import Image, ImageDraw
    
    mask = Image.new('L', (size, size), 0)
    draw = ImageDraw.Draw(mask)
    
    # Squircle approximation: use a large corner radius with slight adjustment
    r = int(size * 0.225)  # Apple's standard corner radius ratio
    
    # Draw filled rounded rectangle with very large radius
    draw.rounded_rectangle([0, 0, size-1, size-1], radius=r, fill=255)
    
    return mask

def make_icon(size):
    """Generate a premium gradient icon."""
    from PIL import Image, ImageDraw, ImageFont
    import colorsys
    
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Background: light gradient
    for y in range(size):
        t = y / size
        # Light cream to soft blue gradient
        r = int(245 + t * 5)
        g = int(240 + t * 8)
        b = int(250 + t * 5)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # Center icon area: rounded square with gradient
    margin = int(size * 0.18)
    icon_size = size - 2 * margin
    x0, y0 = margin, margin
    x1, y1 = margin + icon_size, margin + icon_size
    
    # Draw the rounded rect with gradient
    for y in range(y0, y1):
        t = (y - y0) / icon_size
        # Blue-purple gradient: #3B5FE0 -> #6C3FDB
        r = int(59 + t * 49)
        g = int(95 - t * 32)
        b = int(224 - t * 5)
        
        # Only draw within rounded rect bounds (simple circle mask for speed)
        cy = y0 + icon_size // 2
        cx = x0 + icon_size // 2
        radius = icon_size // 2
        
        half_width = int(math.sqrt(max(0, radius**2 - (y - cy)**2)))
        
        if half_width > 0:
            left = max(x0, cx - half_width)
            right = min(x1, cx + half_width)
            if right > left:
                draw.line([(left, y), (right, y)], fill=(r, g, b, 255))
    
    # Draw waveform symbol (simplified as bars)
    bar_color = (255, 255, 255, 240)
    center_x = size // 2
    center_y = size // 2
    
    if size >= 64:
        bar_count = 5
        bar_width = max(2, int(icon_size * 0.06))
        bar_gap = max(1, int(icon_size * 0.04))
        total_width = bar_count * bar_width + (bar_count - 1) * bar_gap
        start_x = center_x - total_width // 2
        
        bar_heights = [0.5, 0.8, 1.0, 0.7, 0.45]
        
        for i, h_ratio in enumerate(bar_heights):
            bar_h = int(icon_size * 0.3 * h_ratio)
            bx = start_x + i * (bar_width + bar_gap)
            by = center_y - bar_h // 2
            
            # Rounded bars
            draw.rounded_rectangle(
                [bx, by, bx + bar_width - 1, by + bar_h - 1],
                radius=bar_width // 2,
                fill=bar_color
            )
    
    # Apply squircle mask for larger sizes
    if size >= 128:
        mask = squircle_mask(size)
        img.putalpha(mask)
    
    return img

if __name__ == "__main__":
    output_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    iconset = create_icon_set(output_dir)
    
    icns_path = os.path.join(output_dir, "AppIcon.icns")
    subprocess.run(["iconutil", "-c", "icns", iconset, "-o", icns_path], check=True)
    
    # Clean up iconset folder
    import shutil
    shutil.rmtree(iconset)
    
    print(f"Icon generated: {icns_path}")
