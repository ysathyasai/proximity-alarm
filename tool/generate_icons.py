import os
import math
import struct
import zlib

def make_png(w, h, rgba_func):
    raw = bytearray()
    for y in range(h):
        raw.append(0)  # filter None
        for x in range(w):
            r, g, b, a = rgba_func(x, y, w, h)
            raw.extend([
                max(0, min(255, int(r))),
                max(0, min(255, int(g))),
                max(0, min(255, int(b))),
                max(0, min(255, int(a)))
            ])
    
    compressed = zlib.compress(bytes(raw), 9)
    
    def chunk(tag, data):
        c = tag + data
        crc = struct.pack('>I', zlib.crc32(c) & 0xffffffff)
        return struct.pack('>I', len(data)) + c + crc
    
    png = b'\x89PNG\r\n\x1a\n'
    ihdr_data = struct.pack('>IIBBBBB', w, h, 8, 6, 0, 0, 0)
    png += chunk(b'IHDR', ihdr_data)
    png += chunk(b'IDAT', compressed)
    png += chunk(b'IEND', b'')
    return png

def render_proximity_alarm_icon(x, y, w, h):
    # Normalized coords: -1 to 1, origin at center
    nx = (x + 0.5 - w / 2) / (w / 2)
    ny = (y + 0.5 - h / 2) / (h / 2)
    
    # 1. Base Squircle / Rounded Container
    # Superellipse distance: |nx|^p + |ny|^p <= 1, p=3.8 (Samsung One UI style squircle)
    p = 3.6
    squircle_dist = (abs(nx) ** p + abs(ny) ** p) ** (1.0 / p)
    
    if squircle_dist > 0.96:
        # Anti-aliased outer edge
        edge_alpha = max(0.0, min(1.0, (1.0 - squircle_dist) / 0.04))
        if edge_alpha <= 0.0:
            return (0, 0, 0, 0)
    else:
        edge_alpha = 1.0

    # Gradient background: Midnight Obsidian (#0B0F19) to Deep Indigo (#1E1B4B)
    grad_t = (ny + 1.0) / 2.0  # 0 at top, 1 at bottom
    bg_r = 11 + grad_t * (30 - 11)
    bg_g = 15 + grad_t * (27 - 15)
    bg_b = 25 + grad_t * (75 - 25)
    
    # Subtle inner border glow
    if squircle_dist > 0.88:
        border_glow = (squircle_dist - 0.88) / 0.08
        bg_r += border_glow * 40
        bg_g += border_glow * 60
        bg_b += border_glow * 110

    # 2. Concentric Radar Rings (Radar / Sonar Proximity Sonar)
    dist_from_center = math.hypot(nx, ny)
    
    # Ring 1 (Radius 0.72)
    ring1 = abs(dist_from_center - 0.72)
    ring1_alpha = max(0.0, 1.0 - ring1 / 0.045) * 0.45
    
    # Ring 2 (Radius 0.54)
    ring2 = abs(dist_from_center - 0.54)
    ring2_alpha = max(0.0, 1.0 - ring2 / 0.045) * 0.70
    
    # Ring 3 (Radius 0.36)
    ring3 = abs(dist_from_center - 0.36)
    ring3_alpha = max(0.0, 1.0 - ring3 / 0.045) * 0.85
    
    radar_cyan = (6, 182, 212) # #06B6D4
    radar_alpha = max(ring1_alpha, max(ring2_alpha, ring3_alpha))
    
    cur_r = bg_r * (1 - radar_alpha) + radar_cyan[0] * radar_alpha
    cur_g = bg_g * (1 - radar_alpha) + radar_cyan[1] * radar_alpha
    cur_b = bg_b * (1 - radar_alpha) + radar_cyan[2] * radar_alpha

    # 3. Centerpiece: Stylized Glowing Alarm Bell + Geofence Pin
    # Pin shape: Top circular head at (0, -0.08) radius 0.26, tapering to needle at (0, 0.40)
    pin_center_y = -0.05
    d_pin_head = math.hypot(nx, ny - pin_center_y)
    
    # Needle triangle below pin head
    in_needle = False
    needle_t = (ny - pin_center_y) / 0.48
    if 0.0 <= needle_t <= 1.0:
        half_w = (1.0 - needle_t) * 0.22
        if abs(nx) <= half_w:
            in_needle = True
    
    is_pin = (d_pin_head <= 0.25) or in_needle
    
    # Top alarm clock bells (Left clapper at (-0.30, -0.32), Right clapper at (0.30, -0.32))
    d_bell_l = math.hypot(nx + 0.26, ny + 0.30)
    d_bell_r = math.hypot(nx - 0.26, ny + 0.30)
    is_bell = (d_bell_l <= 0.11) or (d_bell_r <= 0.11)
    
    # Center core pulse dot (Radar bullseye)
    d_center_dot = math.hypot(nx, ny - pin_center_y)
    is_center_dot = (d_center_dot <= 0.09)
    
    # Render Bell clappers in Amber Gold (#F59E0B)
    if is_bell:
        bell_alpha = min(1.0, max(0.0, (0.11 - min(d_bell_l, d_bell_r)) / 0.02))
        cur_r = cur_r * (1 - bell_alpha) + 245 * bell_alpha
        cur_g = cur_g * (1 - bell_alpha) + 158 * bell_alpha
        cur_b = cur_b * (1 - bell_alpha) + 11 * bell_alpha
    
    # Render Pin Body in Vibrant Electric Indigo & Amber (#4F46E5 / #DC2626)
    if is_pin:
        # Radial gradient on pin
        pin_grad = min(1.0, max(0.0, (ny + 0.25) / 0.65))
        pin_r = 79 * (1 - pin_grad) + 239 * pin_grad
        pin_g = 70 * (1 - pin_grad) + 68 * pin_grad
        pin_b = 229 * (1 - pin_grad) + 68 * pin_grad
        
        cur_r = pin_r
        cur_g = pin_g
        cur_b = pin_b
    
    # Render Center Bullseye Dot in Glowing Pure White & Amber
    if is_center_dot:
        dot_alpha = min(1.0, max(0.0, (0.09 - d_center_dot) / 0.02))
        cur_r = cur_r * (1 - dot_alpha) + 255 * dot_alpha
        cur_g = cur_g * (1 - dot_alpha) + 255 * dot_alpha
        cur_b = cur_b * (1 - dot_alpha) + 255 * dot_alpha

    return (cur_r, cur_g, cur_b, edge_alpha * 255)

def main():
    sizes = [
        ('android/app/src/main/res/mipmap-mdpi/ic_launcher.png', 48),
        ('android/app/src/main/res/mipmap-hdpi/ic_launcher.png', 72),
        ('android/app/src/main/res/mipmap-xhdpi/ic_launcher.png', 96),
        ('android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png', 144),
        ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192),
        ('assets/icons/app_logo.png', 512),
    ]
    
    os.makedirs('assets/icons', exist_ok=True)
    
    for path, size in sizes:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        print(f'Generating {path} ({size}x{size})...')
        png_bytes = make_png(size, size, render_proximity_alarm_icon)
        with open(path, 'wb') as f:
            f.write(png_bytes)
        print(f'  Saved {len(png_bytes)} bytes.')

if __name__ == '__main__':
    main()
