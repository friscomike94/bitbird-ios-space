"""
Space/SF Theme Sprite Transformer
Transforms Rocket Jump game atlases into space theme:
- Orange/yellow flames → cyan/blue thrusters
- Backgrounds → starfield
- Character → space suit tint + helmet
- Obstacles → asteroid appearance
"""

from PIL import Image, ImageDraw, ImageFilter
import numpy as np
import random
import colorsys
import os
import shutil

BASE = os.path.dirname(os.path.abspath(__file__))
ATLAS_DIR = os.path.join(BASE, "atlases")


def backup(path):
    bak = path + ".bak"
    if not os.path.exists(bak):
        shutil.copy2(path, bak)


def img_to_hsv(arr):
    """RGBA uint8 array → HSV float array (H 0-360, S 0-1, V 0-1), alpha unchanged"""
    rgb = arr[:, :, :3].astype(np.float32) / 255.0
    h = np.zeros(rgb.shape[:2], dtype=np.float32)
    s = np.zeros_like(h)
    v = np.zeros_like(h)
    for y in range(rgb.shape[0]):
        for x in range(rgb.shape[1]):
            hh, ss, vv = colorsys.rgb_to_hsv(*rgb[y, x])
            h[y, x] = hh * 360.0
            s[y, x] = ss
            v[y, x] = vv
    return h, s, v


def hsv_to_img(h, s, v, alpha):
    """HSV float arrays + alpha → RGBA uint8 array"""
    result = np.zeros((*h.shape, 4), dtype=np.uint8)
    for y in range(h.shape[0]):
        for x in range(h.shape[1]):
            r, g, b = colorsys.hsv_to_rgb(h[y, x] / 360.0, s[y, x], v[y, x])
            result[y, x] = [int(r * 255), int(g * 255), int(b * 255), alpha[y, x]]
    return result


def shift_hue_range_numpy(arr, min_hue, max_hue, new_hue, sat_boost=1.0):
    """
    Shift pixels whose hue falls in [min_hue, max_hue] to new_hue.
    arr: RGBA uint8 numpy array
    All hues in degrees 0-360.
    """
    rgb = arr[:, :, :3].astype(np.float32) / 255.0
    alpha = arr[:, :, 3]
    out = arr.copy()

    r, g, b = rgb[:, :, 0], rgb[:, :, 1], rgb[:, :, 2]
    maxc = np.max(rgb, axis=2)
    minc = np.min(rgb, axis=2)
    delta = maxc - minc

    # Value
    v = maxc

    # Saturation
    s = np.where(maxc > 0, delta / maxc, 0.0)

    # Hue
    h = np.zeros_like(v)
    mask_r = (maxc == r) & (delta > 0)
    mask_g = (maxc == g) & (delta > 0)
    mask_b = (maxc == b) & (delta > 0)
    h[mask_r] = (60.0 * ((g[mask_r] - b[mask_r]) / delta[mask_r])) % 360.0
    h[mask_g] = (60.0 * ((b[mask_g] - r[mask_g]) / delta[mask_g]) + 120.0) % 360.0
    h[mask_b] = (60.0 * ((r[mask_b] - g[mask_b]) / delta[mask_b]) + 240.0) % 360.0

    # Identify pixels in hue range with enough saturation
    in_range = (h >= min_hue) & (h <= max_hue) & (s > 0.25) & (v > 0.05) & (alpha > 20)
    new_h = np.where(in_range, new_hue, h)
    new_s = np.where(in_range, np.minimum(s * sat_boost, 1.0), s)

    # Convert back to RGB
    new_h_norm = new_h / 360.0
    hi = (new_h_norm * 6.0).astype(int) % 6
    f = new_h_norm * 6.0 - (new_h_norm * 6.0).astype(int)
    p = v * (1.0 - new_s)
    q = v * (1.0 - f * new_s)
    t = v * (1.0 - (1.0 - f) * new_s)

    new_r = np.select([hi == 0, hi == 1, hi == 2, hi == 3, hi == 4, hi == 5], [v, q, p, p, t, v])
    new_g = np.select([hi == 0, hi == 1, hi == 2, hi == 3, hi == 4, hi == 5], [t, v, v, q, p, p])
    new_b = np.select([hi == 0, hi == 1, hi == 2, hi == 3, hi == 4, hi == 5], [p, p, t, v, v, q])

    # Only modify pixels in range
    result = out.astype(np.float32)
    result[:, :, 0] = np.where(in_range, new_r * 255, result[:, :, 0])
    result[:, :, 1] = np.where(in_range, new_g * 255, result[:, :, 1])
    result[:, :, 2] = np.where(in_range, new_b * 255, result[:, :, 2])
    return result.astype(np.uint8)


def draw_starfield(draw, x0, y0, x1, y1, seed=42):
    """Draw a starfield into a rectangle on a PIL ImageDraw."""
    rng = random.Random(seed)
    w, h = x1 - x0, y1 - y0
    area = w * h

    # Fill with near-black deep space
    draw.rectangle([x0, y0, x1, y1], fill=(2, 2, 12, 255))

    # Nebula clouds (soft color patches)
    for _ in range(6):
        nx = x0 + rng.randint(0, w)
        ny = y0 + rng.randint(0, h)
        nr = rng.randint(40, 120)
        ncol = rng.choice([
            (20, 5, 60, 60),    # purple
            (5, 15, 50, 50),    # deep blue
            (0, 40, 60, 45),    # teal
            (30, 5, 40, 40),    # indigo
        ])
        draw.ellipse([nx - nr, ny - nr, nx + nr, ny + nr], fill=ncol)

    # Stars: many small dots
    num_stars = area // 120
    for _ in range(num_stars):
        sx = x0 + rng.randint(0, w - 1)
        sy = y0 + rng.randint(0, h - 1)
        brightness = rng.randint(160, 255)
        # Slight color tint
        tint = rng.choice([
            (brightness, brightness, brightness),
            (brightness, brightness - 20, brightness - 40),  # warm
            (brightness - 30, brightness - 20, brightness),  # cool blue
            (brightness - 10, brightness, brightness),       # cyan
        ])
        size = rng.choices([0, 1, 2], weights=[70, 25, 5])[0]
        if size == 0:
            draw.point((sx, sy), fill=(*tint, 255))
        elif size == 1:
            draw.ellipse([sx - 1, sy - 1, sx + 1, sy + 1], fill=(*tint, 200))
        else:
            # Bright star with cross-flare
            draw.ellipse([sx - 1, sy - 1, sx + 1, sy + 1], fill=(*tint, 255))
            draw.line([sx - 3, sy, sx + 3, sy], fill=(*tint, 100), width=1)
            draw.line([sx, sy - 3, sx, sy + 3], fill=(*tint, 100), width=1)


def make_asteroid_tint(arr, region_x, region_y, region_w, region_h):
    """Desaturate and darken a region to look like an asteroid/rock."""
    x0, y0 = region_x, region_y
    x1, y1 = x0 + region_w, y0 + region_h
    region = arr[y0:y1, x0:x1].astype(np.float32)

    rgb = region[:, :, :3]
    alpha = region[:, :, 3]

    # Convert to grayscale luminance
    lum = 0.2126 * rgb[:, :, 0] + 0.7152 * rgb[:, :, 1] + 0.0722 * rgb[:, :, 2]

    # Mix with rocky brown-grey
    rocky_r = lum * 0.55 + 30
    rocky_g = lum * 0.50 + 25
    rocky_b = lum * 0.45 + 20

    region[:, :, 0] = np.clip(rocky_r, 0, 255)
    region[:, :, 1] = np.clip(rocky_g, 0, 255)
    region[:, :, 2] = np.clip(rocky_b, 0, 255)
    region[:, :, 3] = alpha

    arr[y0:y1, x0:x1] = region.astype(np.uint8)
    return arr


def add_space_helmet(arr, char_x, char_y, char_w, char_h):
    """Overlay a simple space helmet on a character sprite region."""
    # Work on a PIL image
    tmp = Image.fromarray(arr, 'RGBA')
    draw = ImageDraw.Draw(tmp, 'RGBA')

    cx = char_x + char_w // 2
    helmet_top = char_y + int(char_h * 0.05)
    helmet_bottom = char_y + int(char_h * 0.55)
    hr = char_w // 2 - 2
    hh = (helmet_bottom - helmet_top) // 2
    hy = (helmet_top + helmet_bottom) // 2

    # White helmet outline
    draw.ellipse([cx - hr, hy - hh, cx + hr, hy + hh],
                 outline=(220, 230, 255, 230), width=3)
    # Visor: cyan-tinted rectangle
    visor_x0 = cx - int(hr * 0.55)
    visor_x1 = cx + int(hr * 0.55)
    visor_y0 = hy - int(hh * 0.35)
    visor_y1 = hy + int(hh * 0.25)
    draw.rectangle([visor_x0, visor_y0, visor_x1, visor_y1],
                   fill=(80, 200, 255, 120),
                   outline=(150, 230, 255, 200), width=1)
    return np.array(tmp)


# ─────────────────────────────────────────────────────────────
# Atlas 522: Jetpack game sprites
# Main changes: background → starfield, flames → cyan
# ─────────────────────────────────────────────────────────────
def transform_atlas_522():
    path = os.path.join(ATLAS_DIR, "atlas_ID522.png")
    backup(path)
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    W, H = img.size
    print(f"atlas_ID522: {W}x{H}")

    # 1. Flames: orange/yellow (hue 15-55°) → cyan (185°)
    arr = shift_hue_range_numpy(arr, 15, 55, 185, sat_boost=1.2)
    # Also shift yellow-green fire tips (55-75°) → blue-cyan (200°)
    arr = shift_hue_range_numpy(arr, 55, 75, 200, sat_boost=1.1)

    # 2. Background gradient (top-left quadrant) → starfield
    # The gradient occupies roughly top-left ~370x420 area
    bg_w = int(W * 0.37)
    bg_h = int(H * 0.42)
    tmp_img = Image.fromarray(arr, 'RGBA')
    draw = ImageDraw.Draw(tmp_img, 'RGBA')
    draw_starfield(draw, 0, 0, bg_w, bg_h, seed=7)
    arr = np.array(tmp_img)

    # 3. Tint the overall image slightly cooler
    arr[:, :, 0] = np.clip(arr[:, :, 0].astype(np.int32) - 8, 0, 255).astype(np.uint8)
    arr[:, :, 2] = np.clip(arr[:, :, 2].astype(np.int32) + 5, 0, 255).astype(np.uint8)

    result = Image.fromarray(arr, 'RGBA')
    result.save(path)
    print("  → saved atlas_ID522.png")


# ─────────────────────────────────────────────────────────────
# Atlas 2541: Title screen sprites (Rocket Jump title, cubes, fire)
# ─────────────────────────────────────────────────────────────
def transform_atlas_2541():
    path = os.path.join(ATLAS_DIR, "atlas_ID2541.png")
    backup(path)
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    W, H = img.size
    print(f"atlas_ID2541: {W}x{H}")

    # 1. Flames → cyan/blue
    arr = shift_hue_range_numpy(arr, 15, 55, 185, sat_boost=1.2)
    arr = shift_hue_range_numpy(arr, 55, 75, 200, sat_boost=1.1)

    # 2. Pink/warm-colored cubes (top area) → asteroid rocky grey
    # They appear in roughly top 25% of atlas, left half
    make_asteroid_tint(arr, 0, 0, W // 2, H // 4)

    # 3. Star background behind title area (black areas → deep space)
    # Replace large black sections with subtle starfield
    tmp_img = Image.fromarray(arr, 'RGBA')
    draw = ImageDraw.Draw(tmp_img, 'RGBA')

    # The black region left of title text (bottom-left quadrant)
    draw_starfield(draw, 0, H // 2, W // 2, H, seed=13)
    arr = np.array(tmp_img)

    # 4. Title text: "Rocket Jump" red → cyan/blue (hue 0-15 & 345-360 → 195)
    arr = shift_hue_range_numpy(arr, 345, 360, 195, sat_boost=0.9)
    arr = shift_hue_range_numpy(arr, 0, 15, 195, sat_boost=0.9)

    result = Image.fromarray(arr, 'RGBA')
    result.save(path)
    print("  → saved atlas_ID2541.png")


# ─────────────────────────────────────────────────────────────
# Atlas 13542: Game sprites (character, obstacles, collectibles)
# ─────────────────────────────────────────────────────────────
def transform_atlas_13542():
    path = os.path.join(ATLAS_DIR, "atlas_ID13542.png")
    backup(path)
    img = Image.open(path).convert("RGBA")
    arr = np.array(img)
    W, H = img.size
    print(f"atlas_ID13542: {W}x{H}")

    # 1. Flame/fire sprites → cyan
    arr = shift_hue_range_numpy(arr, 15, 55, 185, sat_boost=1.2)
    arr = shift_hue_range_numpy(arr, 55, 75, 200, sat_boost=1.1)

    # 2. Red/orange obstacle cubes → asteroid grey (hue 0-35)
    arr = shift_hue_range_numpy(arr, 0, 35, 210, sat_boost=0.25)

    # 3. Green character (duck/creeper) → tint blue-green (space suit)
    # Green hue is around 95-140°, shift to blue-teal (200-210°)
    arr = shift_hue_range_numpy(arr, 95, 150, 205, sat_boost=0.8)

    # 4. Brown character parts → darker metallic
    arr = shift_hue_range_numpy(arr, 20, 45, 220, sat_boost=0.5)

    # 5. Add space helmet to character sprites
    # Characters appear in top-left of atlas (~first 200x200 area)
    # Two characters visible side by side
    char_size = W // 8
    # Left character
    arr = add_space_helmet(arr,
                           char_x=0, char_y=0,
                           char_w=char_size, char_h=char_size)
    # Right character (slightly offset)
    arr = add_space_helmet(arr,
                           char_x=char_size + 4, char_y=0,
                           char_w=char_size, char_h=char_size)

    # 6. "Game Over" text: red → cyan
    arr = shift_hue_range_numpy(arr, 345, 360, 190, sat_boost=0.8)
    arr = shift_hue_range_numpy(arr, 0, 12, 190, sat_boost=0.8)

    # 7. Screw/bolt collectibles → golden star color (keep warm but brighter)
    # Already a warm color, keep as-is or tint slightly

    # 8. Black background areas → deep space
    tmp_img = Image.fromarray(arr, 'RGBA')
    draw = ImageDraw.Draw(tmp_img, 'RGBA')
    # Bottom half tends to be empty/black
    draw_starfield(draw, 0, H // 2, W, H, seed=21)
    arr = np.array(tmp_img)

    result = Image.fromarray(arr, 'RGBA')
    result.save(path)
    print("  → saved atlas_ID13542.png")


if __name__ == "__main__":
    print("=== Space/SF Theme Sprite Transformation ===")
    transform_atlas_522()
    transform_atlas_2541()
    transform_atlas_13542()
    print("\nDone! All atlases transformed to space theme.")
    print("Backups saved as *.bak files.")
