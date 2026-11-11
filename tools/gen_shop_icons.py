"""
Sakura Blitz - High-Resolution In-Game Shop Preview Icons Generator
Generates 14 vibrant, stylized 160x100 PNG preview images for the in-game VIP shop.
Super-sampled at 640x400 (4x) and downsampled with Lanczos for razor-sharp antialiasing.
"""

import os
import math
import random
from PIL import Image, ImageDraw, ImageFont, ImageFilter

# Paths
BASE_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
UI_DIR = os.path.join(BASE_DIR, "assets", "ui")
os.makedirs(UI_DIR, exist_ok=True)

# Dimensions
CANVAS_W = 640
CANVAS_H = 400
FINAL_W = 160
FINAL_H = 100

# Fonts setup
def get_font(size: int, bold: bool = True):
    font_paths = [
        "C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf",
        "C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf",
        "C:/Windows/Fonts/consola.ttf",
    ]
    for p in font_paths:
        if os.path.exists(p):
            try:
                return ImageFont.truetype(p, size)
            except Exception:
                pass
    return ImageFont.load_default()

# ---------------------------------------------------------------------------
# Graphics Helpers
# ---------------------------------------------------------------------------

def create_gradient_img(w: int, h: int, col_top: tuple, col_bottom: tuple) -> Image.Image:
    """Create a vertical linear gradient image."""
    img = Image.new("RGBA", (w, h))
    pixels = []
    r1, g1, b1 = col_top[:3]
    r2, g2, b2 = col_bottom[:3]
    for y in range(h):
        t = y / max(1, h - 1)
        r = int(r1 + (r2 - r1) * t)
        g = int(g1 + (g2 - g1) * t)
        b = int(b1 + (b2 - b1) * t)
        row = [(r, g, b, 255)] * w
        pixels.extend(row)
    img.putdata(pixels)
    return img

def create_radial_gradient_img(w: int, h: int, cx: int, cy: int, r_max: int, col_center: tuple, col_edge: tuple) -> Image.Image:
    """Create a radial gradient image."""
    img = Image.new("RGBA", (w, h))
    pixels = []
    r1, g1, b1 = col_center[:3]
    r2, g2, b2 = col_edge[:3]
    for y in range(h):
        for x in range(w):
            dist = math.hypot(x - cx, y - cy)
            t = min(1.0, dist / max(1.0, r_max))
            # Smoothstep
            t = t * t * (3.0 - 2.0 * t)
            r = int(r1 + (r2 - r1) * t)
            g = int(g1 + (g2 - g1) * t)
            b = int(b1 + (b2 - b1) * t)
            pixels.append((r, g, b, 255))
    img.putdata(pixels)
    return img

def draw_chamfered_card(draw: ImageDraw.ImageDraw, w: int, h: int, chamfer: int, fill: tuple, outline: tuple, width: int = 3):
    """Draw a high-tech card frame with cut/chamfered corners."""
    inset = 6
    pts = [
        (chamfer + inset, inset),
        (w - chamfer - inset, inset),
        (w - inset, chamfer + inset),
        (w - inset, h - chamfer - inset),
        (w - chamfer - inset, h - inset),
        (chamfer + inset, h - inset),
        (inset, h - chamfer - inset),
        (inset, chamfer + inset)
    ]
    draw.polygon(pts, fill=fill, outline=outline, width=width)

def draw_corner_accents(draw: ImageDraw.ImageDraw, w: int, h: int, color: tuple, size: int = 24):
    """Draw tactical corner brackets and rivets."""
    # Corner brackets
    pad = 12
    t = 3
    # Top Left
    draw.line([(pad, pad), (pad + size, pad)], fill=color, width=t)
    draw.line([(pad, pad), (pad, pad + size)], fill=color, width=t)
    # Top Right
    draw.line([(w - pad, pad), (w - pad - size, pad)], fill=color, width=t)
    draw.line([(w - pad, pad), (w - pad, pad + size)], fill=color, width=t)
    # Bottom Left
    draw.line([(pad, h - pad), (pad + size, h - pad)], fill=color, width=t)
    draw.line([(pad, h - pad), (pad, h - pad - size)], fill=color, width=t)
    # Bottom Right
    draw.line([(w - pad, h - pad), (w - pad - size, h - pad)], fill=color, width=t)
    draw.line([(w - pad, h - pad), (w - pad, h - pad - size)], fill=color, width=t)
    
    # Rivets
    r_color = (220, 230, 245, 200)
    for rx, ry in [(pad + 6, pad + 6), (w - pad - 6, pad + 6), (pad + 6, h - pad - 6), (w - pad - 6, h - pad - 6)]:
        draw.ellipse([rx - 2, ry - 2, rx + 2, ry + 2], fill=r_color)

def draw_badge(draw: ImageDraw.ImageDraw, w: int, text: str, bg_color: tuple, text_color: tuple, font_size: int = 15):
    """Draw a stylish top banner / pill badge for item classification."""
    font = get_font(font_size, bold=True)
    bbox = font.getbbox(text)
    tw = bbox[2] - bbox[0]
    bw = tw + 40
    bh = 26
    by = 9
    bx1 = (w - bw) // 2
    bx2 = bx1 + bw
    
    # Angled tech trapezoid badge
    slant = 12
    pts = [
        (bx1 - slant, by),
        (bx2 + slant, by),
        (bx2, by + bh),
        (bx1, by + bh)
    ]
    draw.polygon(pts, fill=bg_color)
    draw.polygon(pts, outline=(255, 255, 255, 140), width=1)
    draw.text((w // 2, by + bh // 2), text, font=font, fill=text_color, anchor="mm")

def draw_sparkle(draw: ImageDraw.ImageDraw, cx: int, cy: int, r: int, color: tuple):
    """Draw a 4-point glittering sparkle / diamond glint."""
    # Vertical and horizontal flare needles
    draw.polygon([(cx, cy - r), (cx + 2, cy), (cx, cy + r), (cx - 2, cy)], fill=color)
    draw.polygon([(cx - r, cy), (cx, cy + 2), (cx + r, cy), (cx, cy - 2)], fill=color)
    # Diagonal tiny sparks
    d = int(r * 0.45)
    draw.line([(cx - d, cy - d), (cx + d, cy + d)], fill=(255, 255, 255, 220), width=1)
    draw.line([(cx - d, cy + d), (cx + d, cy - d)], fill=(255, 255, 255, 220), width=1)
    # Bright center dot
    draw.ellipse([cx - 2, cy - 2, cx + 2, cy + 2], fill=(255, 255, 255, 255))

def draw_star(draw: ImageDraw.ImageDraw, cx: int, cy: int, r_out: int, r_in: int, points: int, color: tuple):
    """Draw a geometric multi-point star."""
    pts = []
    step = math.pi / points
    for i in range(2 * points):
        r = r_out if i % 2 == 0 else r_in
        ang = i * step - math.pi / 2
        pts.append((cx + r * math.cos(ang), cy + r * math.sin(ang)))
    draw.polygon(pts, fill=color)

def draw_hex_grid(draw: ImageDraw.ImageDraw, w: int, h: int, col: tuple, size: int = 30):
    """Draw subtle sci-fi hex pattern."""
    h_step = size * 1.5
    v_step = size * math.sqrt(3)
    for x in range(-size, w + size * 2, int(h_step)):
        for y in range(-size, h + size * 2, int(v_step)):
            cx = x
            cy = y + (size * math.sqrt(3) / 2 if (x // int(h_step)) % 2 == 1 else 0)
            pts = []
            for a in range(6):
                ang = a * math.pi / 3
                pts.append((cx + size * 0.8 * math.cos(ang), cy + size * 0.8 * math.sin(ang)))
            draw.polygon(pts, outline=col, width=1)

# ---------------------------------------------------------------------------
# Base Card Template
# ---------------------------------------------------------------------------

def make_base_card(bg_type: str, col1: tuple, col2: tuple, border_col: tuple, accent_col: tuple, badge_txt: str, badge_bg: tuple, badge_fg: tuple) -> tuple[Image.Image, ImageDraw.ImageDraw]:
    if bg_type == "radial":
        img = create_radial_gradient_img(CANVAS_W, CANVAS_H, CANVAS_W // 2, CANVAS_H // 2, 340, col1, col2)
    else:
        img = create_gradient_img(CANVAS_W, CANVAS_H, col1, col2)
    
    draw = ImageDraw.Draw(img)
    
    # Chamfered outer frame
    draw_chamfered_card(draw, CANVAS_W, CANVAS_H, 20, fill=None, outline=border_col, width=4)
    # Inner subtle glow border
    draw_chamfered_card(draw, CANVAS_W - 8, CANVAS_H - 8, 16, fill=None, outline=(border_col[0], border_col[1], border_col[2], 60), width=1)
    
    # Corner brackets and rivets
    draw_corner_accents(draw, CANVAS_W, CANVAS_H, accent_col, 28)
    
    # Top badge
    draw_badge(draw, CANVAS_W, badge_txt, badge_bg, badge_fg, font_size=15)
    
    return img, draw

# ---------------------------------------------------------------------------
# 1. WEAPON SKINS GENERATOR
# ---------------------------------------------------------------------------

def draw_rifle_silhouette(
    img: Image.Image,
    p: dict,
    special_decorations=None
):
    """
    Renders a detailed side-profile assault rifle (AK-47 / Commando profile).
    p dictionary contains color palettes for each component.
    """
    glow_img = Image.new("RGBA", (CANVAS_W, CANVAS_H), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow_img)
    
    draw = ImageDraw.Draw(img)
    
    # Coordinates layout
    # Center y around 206
    # Stock: x: 95 to 215
    # Receiver: x: 215 to 345
    # Handguard: x: 360 to 480
    # Gas block & barrel: x: 480 to 552
    # Mag: x: 298 to 386, y: 222 to 326
    # Grip: x: 206 to 252, y: 222 to 300
    
    # 0. Glowing aura layer
    aura_col = p.get("aura_col", None)
    if aura_col:
        glow_draw.polygon([(85, 180), (555, 180), (555, 230), (390, 335), (200, 310), (85, 275)], fill=aura_col)
        glow_img = glow_img.filter(ImageFilter.GaussianBlur(radius=24))
        img.paste(glow_img, (0, 0), glow_img)
        draw = ImageDraw.Draw(img)

    # 1. Buttstock
    stock_pts = [(215, 192), (168, 194), (105, 186), (96, 264), (145, 252), (170, 222), (215, 222)]
    draw.polygon(stock_pts, fill=p["stock_fill"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    # Buttplate
    bp_pts = [(88, 183), (98, 183), (96, 267), (86, 267)]
    draw.polygon(bp_pts, fill=p.get("metal_dark", (35, 38, 48, 255)), outline=p.get("outline", (20, 20, 25, 255)), width=1)
    for by in range(195, 260, 8):
        draw.line([(88, by), (96, by)], fill=p.get("highlight", (180, 190, 210, 180)), width=1)
    # Stock comb highlight / wood grain
    if p.get("wood_grain", False):
        for sy in [198, 208, 218, 230, 242]:
            draw.line([(108, sy), (180, sy + 4)], fill=p.get("wood_line", (180, 80, 40, 140)), width=2)
    elif p.get("stock_accent", None):
        draw.line([(110, 200), (205, 202)], fill=p["stock_accent"], width=3)
    # Sling swivel
    draw.arc([114, 248, 126, 260], 0, 180, fill=p.get("metal_dark", (30, 30, 35, 255)), width=2)

    # 2. Pistol Grip
    grip_pts = [(222, 222), (252, 222), (238, 300), (205, 300)]
    draw.polygon(grip_pts, fill=p["grip_fill"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    # Grip bottom cap
    draw.ellipse([203, 296, 240, 304], fill=p.get("metal_dark", (25, 28, 35, 255)))
    # Grip checkering lines
    for gy in range(238, 292, 7):
        draw.line([(218 + (gy - 238) * 0.15, gy), (242 + (gy - 238) * 0.1, gy)], fill=p.get("grip_acc", (80, 85, 95, 120)), width=1)

    # 3. Trigger Guard & Trigger
    draw.arc([250, 220, 288, 254], 0, 180, fill=p.get("metal_mid", (70, 75, 88, 255)), width=3)
    # Trigger
    draw.line([(268, 224), (273, 242)], fill=p.get("highlight", (200, 200, 210, 255)), width=3)

    # 4. Magazine (Curved 30-round banana mag)
    mag_pts = [(298, 222), (345, 222), (386, 324), (332, 324)]
    draw.polygon(mag_pts, fill=p["mag_fill"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    # Mag floorplate
    draw.polygon([(328, 324), (388, 324), (386, 332), (326, 332)], fill=p.get("metal_dark", (20, 22, 28, 255)))
    # Mag stamped ribs
    for my in range(236, 316, 12):
        t_prog = (my - 236) / 80
        x_left = 305 + t_prog * 30
        x_right = 338 + t_prog * 40
        draw.line([(x_left, my), (x_right, my + 3)], fill=p.get("mag_accent", (90, 95, 110, 200)), width=2)

    # 5. Receiver (Upper dust cover & Lower receiver)
    # Upper dust cover
    dust_pts = [(215, 190), (228, 175), (345, 175), (345, 200), (215, 200)]
    draw.polygon(dust_pts, fill=p["receiver_upper"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    # Top reflection line
    draw.line([(229, 176), (344, 176)], fill=p.get("highlight", (220, 230, 245, 255)), width=2)
    # Stamped vertical ribs on dust cover
    for rx in range(240, 335, 18):
        draw.line([(rx, 178), (rx, 198)], fill=p.get("metal_dark", (35, 40, 50, 160)), width=1)
    
    # Lower receiver
    rec_lower_pts = [(215, 200), (345, 200), (345, 222), (215, 222)]
    draw.polygon(rec_lower_pts, fill=p["receiver_lower"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    # Selector switch lever
    draw.polygon([(232, 206), (280, 214), (280, 218), (232, 210)], fill=p.get("metal_dark", (30, 35, 45, 255)))
    draw.ellipse([230, 206, 236, 212], fill=p.get("highlight", (200, 210, 225, 255)))
    # Ejection port & bolt carrier
    draw.rectangle([268, 180, 314, 194], fill=p.get("metal_dark", (20, 22, 28, 255)))
    draw.rectangle([276, 182, 308, 192], fill=p.get("bolt_fill", (150, 155, 170, 255)))
    draw.rectangle([300, 186, 312, 191], fill=p.get("metal_dark", (40, 42, 50, 255))) # charging handle

    # Rear sight block
    draw.polygon([(345, 170), (370, 170), (370, 188), (345, 188)], fill=p.get("metal_mid", (60, 65, 78, 255)), outline=p.get("outline", (20, 20, 25, 255)))
    draw.polygon([(348, 166), (368, 169), (368, 173), (348, 170)], fill=p.get("metal_dark", (40, 45, 55, 255)))

    # 6. Gas Tube (Upper) & Handguard (Lower)
    # Upper gas tube cover
    upper_hg_pts = [(370, 180), (472, 180), (472, 198), (370, 198)]
    draw.polygon(upper_hg_pts, fill=p["handguard_fill"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    if p.get("wood_grain", False):
        draw.line([(376, 188), (466, 188)], fill=p.get("wood_line", (180, 80, 40, 140)), width=2)
    
    # Lower handguard
    lower_hg_pts = [(365, 200), (475, 200), (470, 225), (372, 225)]
    draw.polygon(lower_hg_pts, fill=p["handguard_fill"], outline=p.get("outline", (30, 35, 45, 255)), width=2)
    # Handguard metallic retaining caps
    draw.rectangle([365, 198, 372, 225], fill=p.get("metal_dark", (35, 40, 50, 255)))
    draw.rectangle([468, 198, 476, 225], fill=p.get("metal_dark", (35, 40, 50, 255)))
    # Cooling vent slots on lower handguard
    for hx in [395, 415, 435]:
        draw.line([(hx, 212), (hx + 10, 212)], fill=p.get("metal_dark", (20, 22, 28, 255)), width=3)
        draw.line([(hx, 212), (hx + 10, 212)], fill=p.get("highlight", (200, 200, 220, 160)), width=1)

    # 7. Gas Block & Front Sight Assembly
    # Gas block
    gb_pts = [(476, 182), (498, 182), (498, 210), (476, 210)]
    draw.polygon(gb_pts, fill=p.get("metal_mid", (60, 65, 78, 255)), outline=p.get("outline", (20, 20, 25, 255)))
    # Barrel tube extending forward
    draw.rectangle([498, 202, 536, 208], fill=p["barrel_fill"], outline=p.get("outline", (20, 20, 25, 255)))
    # Cleaning rod below barrel
    draw.line([(375, 214), (506, 214)], fill=p.get("metal_dark", (45, 50, 60, 255)), width=2)
    # Front sight block
    fs_pts = [(508, 174), (524, 174), (524, 210), (508, 210)]
    draw.polygon(fs_pts, fill=p.get("metal_mid", (60, 65, 78, 255)), outline=p.get("outline", (20, 20, 25, 255)))
    # Protective sight wings & center sight pin
    draw.line([(510, 162), (514, 174)], fill=p.get("metal_dark", (40, 45, 55, 255)), width=2)
    draw.line([(522, 162), (518, 174)], fill=p.get("metal_dark", (40, 45, 55, 255)), width=2)
    draw.line([(516, 164), (516, 174)], fill=p.get("highlight", (240, 240, 255, 255)), width=2)
    
    # 8. Muzzle Brake / Compensator
    mb_pts = [(536, 197), (552, 195), (554, 213), (536, 213)]
    draw.polygon(mb_pts, fill=p["muzzle_fill"], outline=p.get("outline", (20, 20, 25, 255)), width=2)
    # Gas vents in muzzle
    draw.line([(542, 198), (542, 203)], fill=(20, 22, 28, 255), width=2)
    draw.line([(547, 197), (547, 202)], fill=(20, 22, 28, 255), width=2)

    # 9. Tactical Optic (Picatinny Rail + Red Dot Sight)
    # Picatinny rail on top of dust cover
    draw.rectangle([240, 169, 332, 175], fill=p.get("metal_dark", (35, 40, 50, 255)), outline=p.get("outline", (20, 20, 25, 255)))
    for rx in range(244, 330, 6):
        draw.line([(rx, 169), (rx, 175)], fill=(20, 22, 28, 255), width=1)
    
    # Red dot sight optic
    optic_pts = [(258, 145), (312, 145), (316, 169), (254, 169)]
    draw.polygon(optic_pts, fill=p.get("optic_housing", (40, 44, 54, 255)), outline=p.get("outline", (20, 20, 25, 255)), width=2)
    # Lens glass
    lens_col = p.get("lens_col", (0, 200, 240, 160))
    draw.rounded_rectangle([266, 149, 304, 165], radius=3, fill=lens_col)
    # Bright glowing red dot reticle
    reticle_col = p.get("reticle_col", (255, 40, 40, 255))
    draw.ellipse([283, 155, 287, 159], fill=reticle_col)
    draw.point((285, 157), fill=(255, 255, 255, 255))

    # 10. Run special decal / skin decorations callback if provided
    if special_decorations:
        special_decorations(img, draw)

# -- Skin 0: Tática Black Ops
def generate_skin_0():
    img, draw = make_base_card(
        "linear",
        (16, 20, 28), (28, 34, 46),
        (200, 90, 40), (255, 159, 28),
        "TACTICAL // BLACK OPS",
        (200, 90, 40), (255, 255, 255)
    )
    # Dark carbon hex grid in background
    draw_hex_grid(draw, CANVAS_W, CANVAS_H, (35, 45, 60, 60), size=24)
    # Diagonal hazard stripes in corner
    for i in range(5):
        draw.line([(CANVAS_W - 120 + i * 16, CANVAS_H - 10), (CANVAS_W - 40 + i * 16, CANVAS_H - 90)], fill=(200, 90, 40, 60), width=4)

    palette = {
        "stock_fill": (115, 45, 24, 255),
        "wood_grain": True,
        "wood_line": (160, 68, 38, 200),
        "handguard_fill": (115, 45, 24, 255),
        "grip_fill": (95, 38, 20, 255),
        "grip_acc": (60, 25, 12, 180),
        "receiver_upper": (45, 50, 62, 255),
        "receiver_lower": (35, 40, 50, 255),
        "metal_mid": (58, 64, 78, 255),
        "metal_dark": (26, 30, 38, 255),
        "barrel_fill": (48, 54, 66, 255),
        "muzzle_fill": (55, 60, 72, 255),
        "mag_fill": (32, 36, 46, 255),
        "mag_accent": (65, 72, 88, 220),
        "highlight": (140, 155, 180, 220),
        "outline": (18, 20, 26, 255),
        "reticle_col": (255, 60, 30, 255),
        "lens_col": (20, 40, 60, 180),
        "aura_col": (200, 90, 40, 40),
    }

    def special(im, d):
        # Tactical laser guide beam from barrel
        d.line([(554, 204), (CANVAS_W - 30, 204)], fill=(255, 80, 20, 180), width=2)
        d.ellipse([CANVAS_W - 32, 202, CANVAS_W - 28, 206], fill=(255, 150, 50, 255))
        # Stamped BO2 insignia on receiver
        f = get_font(12, bold=True)
        d.text((236, 201), "SPEC-OPS", font=f, fill=(180, 190, 210, 140))

    draw_rifle_silhouette(img, palette, special)
    return img

# -- Skin 1: Ouro Imperial BO2
def generate_skin_1():
    img, draw = make_base_card(
        "radial",
        (45, 35, 10), (14, 12, 6),
        (255, 190, 11), (255, 243, 176),
        "OURO IMPERIAL // BO2 GOLD",
        (255, 190, 11), (15, 12, 5)
    )
    # Radiant gold burst lines
    cx, cy = CANVAS_W // 2, CANVAS_H // 2
    for a in range(24):
        ang = a * (math.pi / 12)
        x2 = cx + 400 * math.cos(ang)
        y2 = cy + 400 * math.sin(ang)
        draw.line([(cx, cy), (x2, y2)], fill=(255, 200, 50, 20), width=2)

    palette = {
        "stock_fill": (255, 200, 25, 255),
        "stock_accent": (255, 245, 170, 255),
        "handguard_fill": (245, 185, 15, 255),
        "grip_fill": (22, 22, 26, 255),
        "grip_acc": (255, 190, 11, 160),
        "receiver_upper": (255, 205, 35, 255),
        "receiver_lower": (225, 170, 15, 255),
        "metal_mid": (255, 190, 11, 255),
        "metal_dark": (160, 110, 5, 255),
        "barrel_fill": (255, 195, 20, 255),
        "muzzle_fill": (255, 215, 60, 255),
        "mag_fill": (24, 24, 28, 255),
        "mag_accent": (255, 190, 11, 220),
        "highlight": (255, 255, 230, 255),
        "outline": (80, 55, 5, 255),
        "reticle_col": (255, 240, 100, 255),
        "lens_col": (255, 210, 50, 140),
        "aura_col": (255, 190, 11, 80),
    }

    def special(im, d):
        # Gold Damascus engraving patterns on magazine and grip
        for my in range(240, 310, 10):
            d.arc([310, my, 350, my + 8], 0, 180, fill=(255, 210, 50, 180), width=1)
        # Lustrous star glints and sparkles!
        sparkle_coords = [
            (230, 175, 14), (344, 175, 12), (552, 196, 16),
            (472, 180, 10), (105, 186, 14), (285, 152, 10),
            (386, 324, 12), (205, 300, 10)
        ]
        for sx, sy, sr in sparkle_coords:
            draw_sparkle(d, sx, sy, sr, (255, 248, 190, 255))
        # Top Imperial laurel wreath or text
        f = get_font(12, bold=True)
        d.text((245, 202), "24K IMPERIAL", font=f, fill=(120, 80, 5, 255))

    draw_rifle_silhouette(img, palette, special)
    return img

# -- Skin 2: Neon Cyber Roblox
def generate_skin_2():
    img, draw = make_base_card(
        "linear",
        (15, 3, 30), (3, 10, 26),
        (0, 245, 212), (255, 42, 133),
        "NEON CYBER // ROBLOX VIP",
        (0, 245, 212), (10, 5, 25)
    )
    # Perspective Cyber Neon Floor Grid
    vanish_x, vanish_y = CANVAS_W // 2, 120
    for gx in range(-100, CANVAS_W + 150, 60):
        draw.line([(gx, CANVAS_H), (vanish_x, vanish_y)], fill=(0, 245, 212, 45), width=1)
    for gy in [180, 230, 280, 330, 380]:
        draw.line([(0, gy), (CANVAS_W, gy)], fill=(255, 42, 133, 40), width=1)

    palette = {
        "stock_fill": (255, 42, 133, 255),      # Hot Cyber Magenta
        "stock_accent": (114, 9, 183, 255),    # Electric Violet
        "handguard_fill": (0, 245, 212, 255),   # Electric Cyan
        "grip_fill": (114, 9, 183, 255),       # Neon Purple
        "grip_acc": (0, 245, 212, 200),
        "receiver_upper": (0, 245, 212, 255),  # Cyan
        "receiver_lower": (18, 5, 35, 255),    # Dark Cyber Violet
        "metal_mid": (0, 187, 249, 255),
        "metal_dark": (10, 2, 20, 255),
        "barrel_fill": (0, 245, 212, 255),
        "muzzle_fill": (255, 42, 133, 255),
        "mag_fill": (255, 42, 133, 255),
        "mag_accent": (0, 245, 212, 255),
        "highlight": (255, 255, 255, 255),
        "outline": (0, 0, 0, 255),
        "reticle_col": (0, 245, 212, 255),
        "lens_col": (255, 42, 133, 160),
        "aura_col": (0, 245, 212, 90),
    }

    def special(im, d):
        # Neon circuit trace lines
        d.line([(220, 195), (270, 195), (280, 185), (330, 185)], fill=(255, 255, 255, 240), width=2)
        d.ellipse([328, 183, 334, 189], fill=(0, 245, 212, 255))
        # Holographic HUD bracket over sight
        d.line([(260, 136), (275, 136)], fill=(0, 245, 212, 220), width=2)
        d.line([(260, 136), (260, 148)], fill=(0, 245, 212, 220), width=2)
        d.line([(310, 136), (295, 136)], fill=(0, 245, 212, 220), width=2)
        d.line([(310, 136), (310, 148)], fill=(0, 245, 212, 220), width=2)
        # Floating cyber voxels / pixel sparks
        rng = random.Random(42)
        for _ in range(16):
            vx = rng.randint(80, CANVAS_W - 80)
            vy = rng.randint(120, CANVAS_H - 80)
            col = (0, 245, 212, 200) if rng.random() > 0.5 else (255, 42, 133, 200)
            d.rectangle([vx, vy, vx + 4, vy + 4], fill=col)

    draw_rifle_silhouette(img, palette, special)
    return img

# -- Skin 3: Dragon Lore Lava
def generate_skin_3():
    img, draw = make_base_card(
        "radial",
        (60, 15, 10), (18, 5, 8),
        (255, 77, 41), (255, 209, 102),
        "DRAGON LORE // LAVA VIP",
        (255, 77, 41), (255, 255, 255)
    )
    # Magma crack lines in background
    draw.line([(50, 350), (140, 280), (220, 310)], fill=(255, 77, 41, 60), width=2)
    draw.line([(CANVAS_W - 60, 330), (CANVAS_W - 150, 270), (CANVAS_W - 240, 290)], fill=(255, 150, 30, 60), width=2)

    palette = {
        "stock_fill": (30, 14, 18, 255),
        "stock_accent": (255, 77, 41, 255),
        "handguard_fill": (255, 77, 41, 255),
        "grip_fill": (28, 12, 16, 255),
        "grip_acc": (255, 100, 30, 200),
        "receiver_upper": (38, 16, 20, 255),
        "receiver_lower": (26, 10, 14, 255),
        "metal_mid": (60, 25, 30, 255),
        "metal_dark": (18, 8, 10, 255),
        "barrel_fill": (35, 15, 18, 255),
        "muzzle_fill": (255, 120, 30, 255),
        "mag_fill": (28, 12, 16, 255),
        "mag_accent": (255, 77, 41, 255),
        "highlight": (255, 209, 102, 255),
        "outline": (10, 4, 6, 255),
        "reticle_col": (255, 220, 50, 255),
        "lens_col": (255, 60, 20, 160),
        "aura_col": (255, 60, 20, 90),
    }

    def special(im, d):
        # Serpentine Golden/Fiery Dragon along receiver and stock
        dragon_body = [
            (115, 230), (150, 210), (195, 215), (235, 192),
            (285, 194), (330, 188), (380, 210), (440, 212)
        ]
        # Dragon underbelly glow
        for i in range(len(dragon_body) - 1):
            d.line([dragon_body[i], dragon_body[i + 1]], fill=(255, 209, 102, 240), width=6)
            d.line([dragon_body[i], dragon_body[i + 1]], fill=(255, 77, 41, 255), width=3)
        # Dragon head near chamber / handguard
        dh_pts = [(435, 206), (465, 202), (460, 218), (435, 218)]
        d.polygon(dh_pts, fill=(255, 209, 102, 255))
        d.ellipse([450, 205, 455, 210], fill=(255, 30, 10, 255)) # ruby eye
        # Fire breath spitting from muzzle
        flame_pts = [
            (554, 204), (575, 195), (600, 200), (618, 204),
            (598, 209), (576, 213)
        ]
        d.polygon(flame_pts, fill=(255, 80, 20, 220))
        d.polygon([(554, 204), (575, 200), (590, 204), (575, 208)], fill=(255, 230, 60, 255))
        # Floating incandescent volcanic embers
        rng = random.Random(99)
        for _ in range(24):
            ex = rng.randint(100, CANVAS_W - 40)
            ey = rng.randint(80, 320)
            er = rng.randint(2, 4)
            ecol = (255, 220, 80, 220) if rng.random() > 0.5 else (255, 80, 20, 180)
            d.ellipse([ex - er, ey - er, ex + er, ey + er], fill=ecol)

    draw_rifle_silhouette(img, palette, special)
    return img

# -- Skin 4: Diamante BO2 VIP
def generate_skin_4():
    img, draw = make_base_card(
        "radial",
        (15, 35, 55), (8, 16, 28),
        (224, 251, 252), (0, 187, 249),
        "DIAMANTE BO2 // VIP MASTER",
        (224, 251, 252), (8, 25, 45)
    )
    # Icy crystalline prism rays
    cx, cy = CANVAS_W // 2, CANVAS_H // 2
    for a in range(16):
        ang = a * (math.pi / 8)
        x2 = cx + 380 * math.cos(ang)
        y2 = cy + 380 * math.sin(ang)
        draw.line([(cx, cy), (x2, y2)], fill=(0, 187, 249, 30), width=2)

    palette = {
        "stock_fill": (224, 251, 252, 255),     # Platinum
        "stock_accent": (0, 187, 249, 255),     # Turquoise
        "handguard_fill": (224, 251, 252, 255),
        "grip_fill": (0, 187, 249, 255),        # Cyan titanium
        "grip_acc": (224, 251, 252, 200),
        "receiver_upper": (235, 253, 255, 255),
        "receiver_lower": (210, 240, 248, 255),
        "metal_mid": (170, 215, 230, 255),
        "metal_dark": (30, 60, 85, 255),
        "barrel_fill": (224, 251, 252, 255),
        "muzzle_fill": (0, 187, 249, 255),
        "mag_fill": (0, 187, 249, 255),
        "mag_accent": (240, 253, 255, 255),
        "highlight": (255, 255, 255, 255),
        "outline": (20, 50, 75, 255),
        "reticle_col": (0, 245, 212, 255),
        "lens_col": (0, 187, 249, 140),
        "aura_col": (0, 245, 212, 80),
    }

    def special(im, d):
        # Diamond pavé faceted mesh overlay on receiver, handguard and stock
        for dx in range(220, 340, 10):
            for dy in range(178, 220, 10):
                # Mini diamond rhombus
                d.polygon([(dx, dy - 3), (dx + 4, dy), (dx, dy + 3), (dx - 4, dy)], fill=(255, 255, 255, 220), outline=(0, 187, 249, 140))
        for dx in range(375, 465, 10):
            for dy in range(184, 220, 10):
                d.polygon([(dx, dy - 3), (dx + 4, dy), (dx, dy + 3), (dx - 4, dy)], fill=(255, 255, 255, 220), outline=(0, 187, 249, 140))
        for dx in range(115, 195, 12):
            for dy in range(195, 245, 10):
                d.polygon([(dx, dy - 3), (dx + 4, dy), (dx, dy + 3), (dx - 4, dy)], fill=(255, 255, 255, 200), outline=(0, 187, 249, 120))

        # Brilliant diamond star glints
        diamond_flares = [
            (228, 175, 16), (344, 175, 15), (552, 196, 18),
            (472, 180, 14), (105, 186, 16), (285, 152, 14),
            (386, 324, 15), (205, 300, 12), (370, 200, 12)
        ]
        for fx, fy, fr in diamond_flares:
            draw_sparkle(d, fx, fy, fr, (255, 255, 255, 255))
            # Prismatic tint
            d.line([(fx - fr - 4, fy), (fx + fr + 4, fy)], fill=(0, 245, 212, 140), width=1)
            d.line([(fx, fy - fr - 4), (fx, fy + fr + 4)], fill=(254, 228, 64, 140), width=1)

    draw_rifle_silhouette(img, palette, special)
    return img

# ---------------------------------------------------------------------------
# 2. WEAPON UPGRADE ICON (`upgrade_gun.png`)
# ---------------------------------------------------------------------------

def generate_weapon_upgrade():
    img, draw = make_base_card(
        "radial",
        (35, 30, 8), (10, 12, 18),
        (255, 209, 102), (0, 245, 212),
        "WEAPON UPGRADE // LEVEL UP ▲",
        (255, 209, 102), (15, 15, 10)
    )
    
    # Rising energy matrix grid
    for x in range(40, CANVAS_W - 40, 40):
        draw.line([(x, 50), (x, 320)], fill=(0, 245, 212, 20), width=1)
    
    # 3 Glowing Upward Chevrons (▲ ▲ ▲)
    chevrons = [
        (230, 110, (0, 245, 212, 180), 38),
        (320, 80,  (255, 209, 102, 240), 46),
        (410, 110, (0, 245, 212, 180), 38),
    ]
    for cx, cy, col, sz in chevrons:
        pts = [
            (cx, cy - sz),
            (cx + sz, cy + sz * 0.4),
            (cx + sz * 0.65, cy + sz * 0.4),
            (cx, cy - sz * 0.35),
            (cx - sz * 0.65, cy + sz * 0.4),
            (cx - sz, cy + sz * 0.4)
        ]
        draw.polygon(pts, fill=col)
        draw.polygon(pts, outline=(255, 255, 255, 200), width=1)

    # Radiant glowing rifle silhouette angled dynamically (+12 degrees slant)
    palette = {
        "stock_fill": (255, 209, 102, 255),
        "stock_accent": (255, 255, 255, 255),
        "handguard_fill": (255, 180, 20, 255),
        "grip_fill": (20, 25, 35, 255),
        "grip_acc": (255, 209, 102, 200),
        "receiver_upper": (255, 220, 80, 255),
        "receiver_lower": (230, 165, 15, 255),
        "metal_mid": (255, 200, 50, 255),
        "metal_dark": (140, 90, 5, 255),
        "barrel_fill": (255, 210, 60, 255),
        "muzzle_fill": (255, 240, 140, 255),
        "mag_fill": (25, 30, 40, 255),
        "mag_accent": (0, 245, 212, 255),
        "highlight": (255, 255, 255, 255),
        "outline": (10, 20, 30, 255),
        "reticle_col": (0, 245, 212, 255),
        "lens_col": (0, 245, 212, 160),
        "aura_col": (255, 209, 102, 100),
    }
    
    def special(im, d):
        # Power Sparkles
        for sx, sy, sr in [(120, 190, 12), (320, 160, 16), (540, 190, 18), (280, 130, 14)]:
            draw_sparkle(d, sx, sy, sr, (255, 255, 255, 255))

    draw_rifle_silhouette(img, palette, special)

    # 5-Segmented Power Bars at bottom (HUD Stat Gauge)
    bx_start = 85
    by = 336
    cell_w = 90
    cell_h = 24
    gap = 8
    
    f_stat = get_font(13, bold=True)
    draw.text((CANVAS_W // 2, by - 12), "⚡ POWER LEVEL & STAT BOOST (+DANO / +CAPACIDADE)", font=f_stat, fill=(0, 245, 212, 240), anchor="mm")
    
    for i in range(5):
        cx = bx_start + i * (cell_w + gap)
        # 4 cells full, 5th cell flashing
        if i < 4:
            fill_c = (0, 245, 212, 255) if i % 2 == 0 else (255, 209, 102, 255)
            draw.rounded_rectangle([cx, by, cx + cell_w, by + cell_h], radius=4, fill=fill_c, outline=(255, 255, 255, 180), width=1)
            # Energy tick marks
            draw.line([(cx + 25, by + 4), (cx + 25, by + cell_h - 4)], fill=(20, 20, 25, 140), width=2)
            draw.line([(cx + 55, by + 4), (cx + 55, by + cell_h - 4)], fill=(20, 20, 25, 140), width=2)
        else:
            # 5th cell = MAX
            draw.rounded_rectangle([cx, by, cx + cell_w, by + cell_h], radius=4, fill=(255, 159, 28, 255), outline=(255, 255, 255, 255), width=2)
            f_max = get_font(13, bold=True)
            draw.text((cx + cell_w // 2, by + cell_h // 2), "UPGRADE!", font=f_max, fill=(10, 10, 15, 255), anchor="mm")

    return img

# ---------------------------------------------------------------------------
# 3. CHARACTER SKINS GENERATOR
# ---------------------------------------------------------------------------

def draw_operator_base(draw: ImageDraw.ImageDraw, vest_col: tuple, collar_col: tuple):
    """Draws shoulders, tactical collar, and plate carrier vest."""
    # Shoulders
    body_pts = [
        (160, 395), (180, 290), (245, 265), (320, 260),
        (395, 265), (460, 290), (480, 395)
    ]
    draw.polygon(body_pts, fill=vest_col, outline=(15, 18, 24, 255), width=2)
    # Tactical high collar
    collar_pts = [(265, 245), (320, 258), (375, 245), (370, 275), (270, 275)]
    draw.polygon(collar_pts, fill=collar_col, outline=(15, 18, 24, 255), width=2)
    # Chest straps / MOLLE loops
    draw.line([(220, 320), (420, 320)], fill=(collar_col[0] + 15, collar_col[1] + 15, collar_col[2] + 15, 200), width=4)
    draw.line([(220, 350), (420, 350)], fill=(collar_col[0] + 15, collar_col[1] + 15, collar_col[2] + 15, 200), width=4)

# -- Char 0: Operador Ghost BO2
def generate_char_0():
    img, draw = make_base_card(
        "linear",
        (15, 18, 24), (25, 30, 40),
        (140, 150, 170), (255, 159, 28),
        "OPERADOR // GHOST BO2",
        (140, 150, 170), (10, 12, 16)
    )
    # Tactical radar circles
    cx, cy = CANVAS_W // 2, 190
    draw.ellipse([cx - 180, cy - 180, cx + 180, cy + 180], outline=(70, 85, 110, 30), width=1)
    draw.ellipse([cx - 120, cy - 120, cx + 120, cy + 120], outline=(70, 85, 110, 40), width=1)
    draw.line([(cx - 200, cy), (cx + 200, cy)], fill=(70, 85, 110, 35), width=1)

    # Tactical Body
    draw_operator_base(draw, (35, 39, 46, 255), (26, 28, 34, 255))
    # Radio mic on shoulder
    draw.line([(210, 290), (210, 240)], fill=(15, 18, 22, 255), width=3)
    draw.ellipse([206, 236, 214, 244], fill=(255, 159, 28, 255))

    # Head / Balaclava base
    head_pts = [
        (255, 140), (265, 100), (320, 85), (375, 100),
        (385, 140), (380, 210), (355, 255), (285, 255), (260, 210)
    ]
    draw.polygon(head_pts, fill=(28, 31, 38, 255), outline=(15, 18, 22, 255), width=2)

    # Ballistic FAST Helmet
    helm_pts = [
        (248, 135), (260, 80), (320, 72), (380, 80),
        (392, 135), (380, 150), (260, 150)
    ]
    draw.polygon(helm_pts, fill=(45, 50, 60, 255), outline=(20, 22, 28, 255), width=2)
    # Helmet NVG mount & side rails
    draw.rectangle([305, 85, 335, 108], fill=(30, 33, 40, 255))
    draw.rectangle([250, 125, 268, 142], fill=(30, 33, 40, 255))
    draw.rectangle([372, 125, 390, 142], fill=(30, 33, 40, 255))

    # Tactical Comms Headset
    draw.ellipse([240, 150, 262, 195], fill=(20, 22, 28, 255)) # left ear cup
    draw.ellipse([378, 150, 400, 195], fill=(20, 22, 28, 255)) # right ear cup
    draw.line([(255, 180), (290, 215)], fill=(10, 10, 12, 255), width=3) # boom mic
    draw.ellipse([286, 211, 296, 221], fill=(40, 45, 55, 255))

    # Ballistic Dark Polarized Goggles
    gog_pts = [(268, 148), (320, 152), (372, 148), (368, 172), (320, 175), (272, 172)]
    draw.polygon(gog_pts, fill=(15, 20, 28, 255), outline=(10, 12, 16, 255), width=2)
    # Blue/amber lens reflection
    draw.line([(276, 155), (312, 155)], fill=(70, 130, 180, 160), width=3)
    draw.line([(328, 155), (364, 155)], fill=(70, 130, 180, 160), width=3)

    # Iconic Hand-Painted Ghost Skull Mask!
    # Cheekbones & Nasal Cavity
    draw.polygon([(314, 182), (326, 182), (324, 196), (316, 196)], fill=(15, 18, 22, 255)) # nose notch
    # Upper Skull bone white arc
    draw.arc([276, 174, 364, 215], 0, 180, fill=(235, 240, 245, 255), width=6)
    # Skull Teeth
    for tx in range(294, 348, 8):
        # upper teeth
        draw.rectangle([tx, 205, tx + 5, 214], fill=(235, 240, 245, 255))
        # lower teeth
        draw.rectangle([tx, 217, tx + 5, 225], fill=(235, 240, 245, 255))
    # Jawbone white contour
    jaw_pts = [(280, 205), (290, 244), (320, 250), (350, 244), (360, 205)]
    for i in range(len(jaw_pts) - 1):
        draw.line([jaw_pts[i], jaw_pts[i + 1]], fill=(235, 240, 245, 255), width=5)

    return img

# -- Char 1: Cyber Ninja Neon
def generate_char_1():
    img, draw = make_base_card(
        "linear",
        (20, 5, 35), (8, 2, 16),
        (114, 9, 183), (0, 245, 212),
        "CYBER NINJA // NEON",
        (114, 9, 183), (255, 255, 255)
    )
    # Cyber neon diagonal rain
    for rx in range(20, CANVAS_W + 100, 40):
        draw.line([(rx, 0), (rx - 80, CANVAS_H)], fill=(0, 245, 212, 25), width=1)

    # Exoskeleton Body
    draw_operator_base(draw, (35, 10, 55, 255), (20, 5, 35, 255))
    # Glowing neon cyan shoulder conduits
    draw.line([(185, 305), (250, 280)], fill=(0, 245, 212, 255), width=3)
    draw.line([(455, 305), (390, 280)], fill=(0, 245, 212, 255), width=3)
    draw.line([(220, 335), (420, 335)], fill=(255, 42, 133, 220), width=3)

    # Ninja Cowl Hood (Deep Purple Fabric)
    hood_pts = [
        (235, 150), (250, 75), (320, 55), (390, 75),
        (405, 150), (395, 250), (360, 270), (280, 270), (245, 250)
    ]
    draw.polygon(hood_pts, fill=(75, 15, 115, 255), outline=(15, 2, 25, 255), width=3)
    # Hood fold shadows
    draw.line([(320, 56), (320, 110)], fill=(45, 8, 70, 255), width=3)
    draw.line([(270, 90), (300, 120)], fill=(45, 8, 70, 255), width=2)
    draw.line([(370, 90), (340, 120)], fill=(45, 8, 70, 255), width=2)

    # Carbon Fiber Face Plate / Respirator
    mask_pts = [(272, 175), (320, 185), (368, 175), (355, 245), (320, 255), (285, 245)]
    draw.polygon(mask_pts, fill=(22, 20, 28, 255), outline=(10, 8, 15, 255), width=2)
    # Glowing neon intake vents
    draw.line([(290, 215), (310, 225)], fill=(0, 245, 212, 255), width=3)
    draw.line([(350, 215), (330, 225)], fill=(0, 245, 212, 255), width=3)
    draw.line([(295, 230), (312, 238)], fill=(0, 245, 212, 255), width=3)
    draw.line([(345, 230), (328, 238)], fill=(0, 245, 212, 255), width=3)

    # Radiant Electric Cyan Cyber Visor (Sweeping curved aerodynamic visor)
    visor_pts = [(255, 140), (320, 146), (385, 140), (378, 176), (320, 184), (262, 176)]
    draw.polygon(visor_pts, fill=(0, 245, 212, 255), outline=(255, 255, 255, 255), width=2)
    # Internal HUD target lines
    draw.line([(275, 160), (365, 160)], fill=(255, 255, 255, 255), width=2)
    draw.ellipse([314, 154, 326, 166], outline=(255, 42, 133, 255), width=2)
    draw.point((320, 160), fill=(255, 255, 255, 255))

    return img

# -- Char 2: Rei El Panadero
def generate_char_2():
    img, draw = make_base_card(
        "radial",
        (55, 25, 8), (20, 8, 4),
        (247, 127, 0), (252, 191, 73),
        "REI EL PANADERO // CHEF 🥖",
        (247, 127, 0), (255, 255, 255)
    )
    # Warm oven fire embers
    rng = random.Random(77)
    for _ in range(18):
        bx = rng.randint(40, CANVAS_W - 40)
        by = rng.randint(40, CANVAS_H - 40)
        draw.ellipse([bx - 3, by - 3, bx + 3, by + 3], fill=(252, 191, 73, 140))

    # Warm Orange Tactical Combat Jacket
    draw_operator_base(draw, (247, 127, 0, 255), (214, 40, 40, 255))
    # Chest Harness holding golden baguette emblem
    draw.ellipse([305, 325, 335, 355], fill=(252, 191, 73, 255), outline=(255, 255, 255, 200), width=2)
    f_bag = get_font(16, bold=True)
    draw.text((320, 340), "🥖", font=f_bag, fill=(30, 20, 10, 255), anchor="mm")

    # Head / Jaw with confident grin & stubble
    head_pts = [
        (265, 145), (270, 120), (320, 115), (370, 120),
        (375, 145), (370, 215), (345, 255), (295, 255), (270, 215)
    ]
    draw.polygon(head_pts, fill=(240, 185, 140, 255), outline=(140, 85, 50, 255), width=2)
    # Tactical 5 o'clock shadow / stubble
    for y_stubble in range(215, 250, 4):
        for x_stubble in range(285, 355, 5):
            if math.hypot(x_stubble - 320, y_stubble - 215) < 38:
                draw.point((x_stubble, y_stubble), fill=(160, 100, 60, 140))
    # Smirk smile
    draw.arc([305, 222, 335, 238], 0, 180, fill=(120, 60, 30, 255), width=3)
    # Golden wheat stalk in mouth
    draw.line([(326, 232), (365, 240)], fill=(252, 191, 73, 255), width=3)
    draw.ellipse([363, 237, 370, 244], fill=(255, 230, 100, 255))

    # Mirrored Aviator Sunglasses with orange sunset glow
    g_pts_l = [(276, 165), (312, 165), (310, 195), (280, 192)]
    g_pts_r = [(328, 165), (364, 165), (360, 192), (330, 195)]
    draw.polygon(g_pts_l, fill=(247, 127, 0, 255), outline=(252, 191, 73, 255), width=2)
    draw.polygon(g_pts_r, fill=(247, 127, 0, 255), outline=(252, 191, 73, 255), width=2)
    draw.line([(312, 168), (328, 168)], fill=(252, 191, 73, 255), width=3) # bridge
    # Sunset reflection flare
    draw.line([(282, 172), (306, 172)], fill=(255, 240, 150, 220), width=2)
    draw.line([(334, 172), (358, 172)], fill=(255, 240, 150, 220), width=2)

    # Towering Baker Toque Blanche (Chef Hat)
    hat_pts = [
        (265, 125), (250, 75), (280, 38), (320, 32),
        (360, 38), (390, 75), (375, 125)
    ]
    draw.polygon(hat_pts, fill=(250, 250, 248, 255), outline=(190, 185, 175, 255), width=2)
    # Chef hat vertical puff pleats
    for px in [285, 310, 330, 355]:
        draw.line([(px, 42), (px, 122)], fill=(215, 210, 200, 180), width=2)

    # Majestic 3-Point Royal Golden Crown atop chef hat band!
    crown_pts = [
        (268, 125), (268, 92), (294, 108), (320, 82),
        (346, 108), (372, 92), (372, 125)
    ]
    draw.polygon(crown_pts, fill=(255, 200, 20, 255), outline=(255, 245, 180, 255), width=2)
    # Ruby jewels on crown tips
    draw.ellipse([264, 88, 272, 96], fill=(214, 40, 40, 255))
    draw.ellipse([316, 78, 324, 86], fill=(214, 40, 40, 255))
    draw.ellipse([368, 88, 376, 96], fill=(214, 40, 40, 255))

    return img

# -- Char 3: Roblox VIP Dourado
def generate_char_3():
    img, draw = make_base_card(
        "radial",
        (55, 10, 25), (20, 4, 10),
        (255, 190, 11), (230, 57, 86),
        "ROBLOX VIP // DOURADO 👑",
        (255, 190, 11), (15, 10, 5)
    )
    # Royal red velvet & golden starburst
    cx, cy = CANVAS_W // 2, 190
    for a in range(20):
        ang = a * (math.pi / 10)
        x2 = cx + 380 * math.cos(ang)
        y2 = cy + 380 * math.sin(ang)
        draw.line([(cx, cy), (x2, y2)], fill=(255, 190, 11, 28), width=2)

    # Crimson Velvet Combat Vest with Gold Epaulettes
    draw_operator_base(draw, (180, 25, 55, 255), (120, 15, 35, 255))
    # Golden shoulder epaulettes
    draw.polygon([(160, 295), (205, 275), (235, 285), (175, 320)], fill=(255, 190, 11, 255), outline=(255, 255, 255, 200))
    draw.polygon([(480, 295), (435, 275), (405, 285), (465, 320)], fill=(255, 190, 11, 255), outline=(255, 255, 255, 200))
    # Heavy Gold VIP chain medallion
    draw.arc([270, 270, 370, 340], 0, 180, fill=(255, 190, 11, 255), width=4)
    draw.ellipse([305, 335, 335, 365], fill=(255, 190, 11, 255), outline=(255, 255, 255, 255), width=2)
    f_vip = get_font(11, bold=True)
    draw.text((320, 350), "VIP", font=f_vip, fill=(20, 10, 5, 255), anchor="mm")

    # Roblox Classic Head Base
    head_pts = [
        (268, 140), (272, 120), (320, 118), (368, 120),
        (372, 140), (368, 220), (345, 250), (295, 250), (272, 220)
    ]
    draw.polygon(head_pts, fill=(255, 220, 140, 255), outline=(180, 120, 60, 255), width=2)
    # Tactical gold shades
    draw.polygon([(276, 160), (314, 160), (312, 188), (280, 186)], fill=(30, 25, 20, 255), outline=(255, 190, 11, 255), width=2)
    draw.polygon([(326, 160), (364, 160), (360, 186), (328, 188)], fill=(30, 25, 20, 255), outline=(255, 190, 11, 255), width=2)
    draw.line([(314, 164), (326, 164)], fill=(255, 190, 11, 255), width=3)
    # Avatar confident smirk
    draw.arc([308, 210, 332, 228], 0, 180, fill=(80, 40, 15, 255), width=3)

    # Iconic Roblox Golden Domino Crown!
    # Golden base coronet band
    draw.polygon([(262, 128), (378, 128), (374, 108), (266, 108)], fill=(255, 190, 11, 255), outline=(255, 255, 255, 255), width=2)
    # Inlaid black domino tiles with golden pips
    for dox in [278, 310, 342]:
        draw.rectangle([dox, 112, dox + 20, 124], fill=(15, 15, 20, 255), outline=(255, 190, 11, 255))
        draw.ellipse([dox + 4, 116, dox + 7, 119], fill=(255, 200, 30, 255))
        draw.ellipse([dox + 13, 116, dox + 16, 119], fill=(255, 200, 30, 255))
    # Towering Golden Feather Spikes / Plumes
    plumes = [
        (275, 108, 255, 45), (295, 108, 285, 30),
        (320, 108, 320, 22), # tallest center feather!
        (345, 108, 355, 30), (365, 108, 385, 45)
    ]
    for bx, by, tx, ty in plumes:
        draw.polygon([(bx - 8, by), (tx, ty), (bx + 8, by)], fill=(255, 205, 30, 255), outline=(255, 255, 255, 200), width=1)
        draw_sparkle(draw, tx, ty, 8, (255, 255, 255, 255))

    return img

# ---------------------------------------------------------------------------
# 4. DOGTAGS GENERATOR
# ---------------------------------------------------------------------------

def draw_dogtag_plate(draw: ImageDraw.ImageDraw, cx: int, cy: int, angle_deg: float, plate_w: int, plate_h: int, fill_col: tuple, rim_col: tuple, bumper_col=None):
    """Draws a metallic rounded military dogtag in perspective angle."""
    rad = math.radians(angle_deg)
    cos_a = math.cos(rad)
    sin_a = math.sin(rad)
    
    # Corner radius
    cr = 30
    hw = plate_w / 2
    hh = plate_h / 2
    
    # Local box corners
    local_pts = [
        (-hw + cr, -hh), (hw - cr, -hh), (hw, -hh + cr),
        (hw, hh - cr), (hw - cr, hh), (-hw + cr, hh),
        (-hw, hh - cr), (-hw, -hh + cr)
    ]
    # Transform
    world_pts = []
    for lx, ly in local_pts:
        wx = cx + lx * cos_a - ly * sin_a
        wy = cy + lx * sin_a + ly * cos_a
        world_pts.append((wx, wy))
        
    draw.polygon(world_pts, fill=fill_col, outline=rim_col, width=3)
    
    # Outer rubber silencer bumper if specified
    if bumper_col:
        draw.polygon(world_pts, outline=bumper_col, width=5)
        
    # Grommet chain hole on left side
    hole_lx = -hw + 26
    hole_ly = 0
    hwx = cx + hole_lx * cos_a - hole_ly * sin_a
    hwy = cy + hole_lx * sin_a + hole_ly * cos_a
    draw.ellipse([hwx - 7, hwy - 7, hwx + 7, hwy + 7], fill=(20, 22, 28, 255), outline=(180, 190, 210, 255), width=2)
    return hwx, hwy

def draw_ball_chain(draw: ImageDraw.ImageDraw, start_x: int, start_y: int, end_x: int, end_y: int, bead_col: tuple):
    """Draws realistic spherical metallic beads along a catenary/curve."""
    steps = 28
    for i in range(steps):
        t = i / steps
        bx = start_x + (end_x - start_x) * t
        # slight parabolic sag
        sag = 22 * math.sin(t * math.pi)
        by = start_y + (end_y - start_y) * t + sag
        draw.ellipse([bx - 4, by - 4, bx + 4, by + 4], fill=bead_col, outline=(30, 30, 35, 255), width=1)
        # Specular glint
        draw.point((int(bx - 1), int(by - 1)), fill=(255, 255, 255, 255))

# -- Dogtag 1: 1-TAP GOD skull
def generate_dogtag_1():
    img, draw = make_base_card(
        "linear",
        (25, 8, 12), (10, 4, 6),
        (214, 40, 40), (255, 77, 41),
        "DOGTAG // 1-TAP GOD 💀",
        (214, 40, 40), (255, 255, 255)
    )
    # Tactical laser crosshair background
    draw.line([(0, 210), (CANVAS_W, 210)], fill=(214, 40, 40, 40), width=1)
    draw.line([(320, 0), (320, CANVAS_H)], fill=(214, 40, 40, 40), width=1)

    # Ball Chain
    draw_ball_chain(draw, 140, 0, 205, 175, (160, 170, 185, 255))

    # Rear dogtag shadow plate
    draw_dogtag_plate(draw, 345, 225, 6.0, 340, 185, (30, 34, 42, 255), (15, 18, 22, 255))
    # Front dogtag plate (Gunmetal with Red Rubber Silencer)
    hwx, hwy = draw_dogtag_plate(
        draw, 315, 205, -8.0, 340, 185,
        fill_col=(45, 50, 60, 255),
        rim_col=(85, 95, 110, 255),
        bumper_col=(214, 40, 40, 255)
    )

    # Stamped Text
    f_title = get_font(21, bold=True)
    draw.text((290, 148), "1 - T A P   G O D", font=f_title, fill=(255, 255, 255, 255), anchor="mm")
    f_sub = get_font(12, bold=True)
    draw.text((290, 172), "HEADSHOT • ONE SHOT ONE KILL", font=f_sub, fill=(214, 40, 40, 255), anchor="mm")

    # Emblem: Menacing Skull with glowing red bullseye
    scx, scy = 350, 228
    # Crossed bullets behind skull
    draw.line([(scx - 45, scy - 35), (scx + 45, scy + 35)], fill=(180, 190, 205, 200), width=6)
    draw.line([(scx + 45, scy - 35), (scx - 45, scy + 35)], fill=(180, 190, 205, 200), width=6)
    # Skull Head
    draw.ellipse([scx - 30, scy - 30, scx + 30, scy + 12], fill=(235, 240, 248, 255), outline=(20, 25, 32, 255), width=2)
    # Skull Jaw
    draw.rectangle([scx - 16, scy + 6, scx + 16, scy + 26], fill=(235, 240, 248, 255), outline=(20, 25, 32, 255), width=2)
    # Teeth
    for i in range(-12, 13, 6):
        draw.line([(scx + i, scy + 10), (scx + i, scy + 24)], fill=(20, 25, 32, 255), width=2)
    # Eye sockets
    draw.ellipse([scx - 18, scy - 12, scx - 6, scy + 4], fill=(20, 25, 32, 255))
    draw.ellipse([scx + 6, scy - 12, scx + 18, scy + 4], fill=(20, 25, 32, 255))
    # Glowing Red Bullseye Crosshair between eyes!
    draw.ellipse([scx - 12, scy - 24, scx + 12, scy], outline=(255, 30, 30, 255), width=2)
    draw.ellipse([scx - 5, scy - 17, scx + 5, scy - 7], fill=(255, 30, 30, 255))
    draw.line([(scx - 16, scy - 12), (scx + 16, scy - 12)], fill=(255, 60, 60, 255), width=2)
    draw.line([(scx, scy - 28), (scx, scy + 4)], fill=(255, 60, 60, 255), width=2)

    return img

# -- Dogtag 2: EL PANADERO golden bread/music
def generate_dogtag_2():
    img, draw = make_base_card(
        "radial",
        (55, 35, 10), (18, 12, 4),
        (255, 190, 11), (252, 191, 73),
        "DOGTAG // EL PANADERO 🥖",
        (255, 190, 11), (20, 12, 4)
    )
    # Floating golden musical notes
    draw_ball_chain(draw, 140, 0, 205, 175, (255, 200, 30, 255))

    # Rear dogtag shadow plate
    draw_dogtag_plate(draw, 345, 225, 6.0, 340, 185, (140, 95, 15, 255), (80, 50, 5, 255))
    # Front dogtag plate (24K Gold finish)
    hwx, hwy = draw_dogtag_plate(
        draw, 315, 205, -8.0, 340, 185,
        fill_col=(255, 205, 35, 255),
        rim_col=(180, 125, 10, 255),
        bumper_col=(255, 240, 150, 255)
    )

    # Stamped Text
    f_title = get_font(21, bold=True)
    draw.text((290, 148), "E L   P A N A D E R O", font=f_title, fill=(60, 35, 5, 255), anchor="mm")
    f_sub = get_font(12, bold=True)
    draw.text((290, 172), "CS 1.6 • GMOD PARKOUR • RADIO 🎵", font=f_sub, fill=(120, 70, 10, 255), anchor="mm")

    # Emblem: Golden French Baguette with Musical Notes
    bx, by = 345, 230
    # Baguette body (angled golden crust)
    bag_pts = [
        (bx - 60, by + 18), (bx - 40, by - 8), (bx + 35, by - 22),
        (bx + 65, by - 8), (bx + 55, by + 15), (bx - 20, by + 28)
    ]
    draw.polygon(bag_pts, fill=(230, 145, 30, 255), outline=(130, 70, 10, 255), width=2)
    # Crust score marks
    for sx in [-30, -5, 20, 42]:
        draw.line([(bx + sx, by - 12), (bx + sx + 8, by + 16)], fill=(255, 235, 150, 255), width=3)

    # Floating Musical Notes (♪ ♫ ♬)
    f_note = get_font(24, bold=True)
    draw.text((bx - 70, by - 25), "♪", font=f_note, fill=(100, 55, 5, 255))
    draw.text((bx + 45, by - 45), "♫", font=f_note, fill=(100, 55, 5, 255))
    draw.text((bx + 60, by + 10), "♬", font=f_note, fill=(100, 55, 5, 255))

    return img

# -- Dogtag 3: REI DO PARKOUR wings
def generate_dogtag_3():
    img, draw = make_base_card(
        "linear",
        (5, 25, 45), (2, 10, 22),
        (0, 245, 212), (0, 187, 249),
        "DOGTAG // REI DO PARKOUR 🏄",
        (0, 245, 212), (5, 20, 35)
    )
    # Speed streaks in background
    for y in range(40, CANVAS_H, 45):
        draw.line([(0, y), (CANVAS_W, y)], fill=(0, 245, 212, 30), width=2)

    draw_ball_chain(draw, 140, 0, 205, 175, (200, 230, 245, 255))

    # Rear dogtag shadow plate
    draw_dogtag_plate(draw, 345, 225, 6.0, 340, 185, (10, 45, 75, 255), (5, 25, 45, 255))
    # Front dogtag plate (Anodized Electric Cyan Titanium)
    hwx, hwy = draw_dogtag_plate(
        draw, 315, 205, -8.0, 340, 185,
        fill_col=(0, 160, 220, 255),
        rim_col=(0, 245, 212, 255),
        bumper_col=(220, 250, 255, 255)
    )

    # Stamped Text
    f_title = get_font(20, bold=True)
    draw.text((290, 148), "R E I   D O   P A R K O U R", font=f_title, fill=(255, 255, 255, 255), anchor="mm")
    f_sub = get_font(12, bold=True)
    draw.text((290, 172), "BHOP • KZ • SURF • VELOCIDADE", font=f_sub, fill=(200, 250, 255, 255), anchor="mm")

    # Emblem: Sweeping Aerodynamic Wings + Surf Ramp
    wx, wy = 345, 230
    # Left Wing
    lw_pts = [
        (wx, wy), (wx - 35, wy - 22), (wx - 80, wy - 30),
        (wx - 55, wy), (wx - 70, wy + 12), (wx - 40, wy + 16), (wx, wy + 10)
    ]
    draw.polygon(lw_pts, fill=(255, 255, 255, 255), outline=(0, 60, 110, 255), width=2)
    # Right Wing
    rw_pts = [
        (wx, wy), (wx + 35, wy - 22), (wx + 80, wy - 30),
        (wx + 55, wy), (wx + 70, wy + 12), (wx + 40, wy + 16), (wx, wy + 10)
    ]
    draw.polygon(rw_pts, fill=(255, 255, 255, 255), outline=(0, 60, 110, 255), width=2)
    # Surf Wedge / Ramp below wings
    draw.polygon([(wx - 30, wy + 26), (wx + 30, wy + 12), (wx + 30, wy + 26)], fill=(0, 245, 212, 255))

    return img

# -- Dogtag 4: TOP 1 GLOBAL crown
def generate_dogtag_4():
    img, draw = make_base_card(
        "radial",
        (55, 45, 12), (16, 12, 4),
        (255, 215, 0), (255, 248, 190),
        "DOGTAG // TOP 1 GLOBAL 👑",
        (255, 215, 0), (20, 15, 4)
    )
    # Sunburst rays in background
    cx, cy = CANVAS_W // 2, CANVAS_H // 2
    for a in range(24):
        ang = a * (math.pi / 12)
        draw.line([(cx, cy), (cx + 380 * math.cos(ang), cy + 380 * math.sin(ang))], fill=(255, 215, 0, 25), width=2)

    draw_ball_chain(draw, 140, 0, 205, 175, (255, 215, 0, 255))

    # Rear dogtag shadow plate
    draw_dogtag_plate(draw, 345, 225, 6.0, 340, 185, (160, 110, 10, 255), (80, 55, 5, 255))
    # Front dogtag plate (Mirror 24K Gold with Diamond Studs)
    hwx, hwy = draw_dogtag_plate(
        draw, 315, 205, -8.0, 340, 185,
        fill_col=(255, 215, 0, 255),
        rim_col=(180, 135, 10, 255),
        bumper_col=(255, 250, 210, 255)
    )

    # Stamped Text
    f_title = get_font(21, bold=True)
    draw.text((290, 148), "T O P   1   G L O B A L", font=f_title, fill=(80, 50, 5, 255), anchor="mm")
    f_sub = get_font(12, bold=True)
    draw.text((290, 172), "RANKED CHAMPION • #1 WORLD", font=f_sub, fill=(140, 85, 10, 255), anchor="mm")

    # Emblem: 5-Point Imperial Crown with "#1" & Laurel Wreath
    kx, ky = 345, 228
    # Laurel wreath
    draw.arc([kx - 52, ky - 35, kx + 52, ky + 35], 30, 150, fill=(160, 110, 10, 255), width=4)
    # Imperial 5-point Crown
    crown_pts = [
        (kx - 36, ky + 16), (kx - 36, ky - 10), (kx - 18, ky + 2),
        (kx, ky - 20), (kx + 18, ky + 2), (kx + 36, ky - 10), (kx + 36, ky + 16)
    ]
    draw.polygon(crown_pts, fill=(255, 245, 160, 255), outline=(130, 85, 5, 255), width=2)
    # Ruby gemstones on peaks
    for rx, ry in [(kx - 36, ky - 10), (kx, ky - 20), (kx + 36, ky - 10)]:
        draw.ellipse([rx - 3, ry - 3, rx + 3, ry + 3], fill=(214, 40, 40, 255))
    
    # Bold "#1" Engraved in Center
    f_num = get_font(18, bold=True)
    draw.text((kx, ky + 3), "#1", font=f_num, fill=(90, 55, 5, 255), anchor="mm")

    # Sparkling diamond glints around dogtag
    for sx, sy in [(180, 130), (450, 160), (420, 280), (220, 250)]:
        draw_sparkle(draw, sx, sy, 12, (255, 255, 255, 255))

    return img

# ---------------------------------------------------------------------------
# MAIN DISPATCHER
# ---------------------------------------------------------------------------

GENERATORS = {
    # 1. Weapon Skins
    "skin_0.png": generate_skin_0,
    "skin_1.png": generate_skin_1,
    "skin_2.png": generate_skin_2,
    "skin_3.png": generate_skin_3,
    "skin_4.png": generate_skin_4,
    # 2. Weapon Upgrade
    "upgrade_gun.png": generate_weapon_upgrade,
    # 3. Character Skins
    "char_0.png": generate_char_0,
    "char_1.png": generate_char_1,
    "char_2.png": generate_char_2,
    "char_3.png": generate_char_3,
    # 4. Dogtags
    "dogtag_1.png": generate_dogtag_1,
    "dogtag_2.png": generate_dogtag_2,
    "dogtag_3.png": generate_dogtag_3,
    "dogtag_4.png": generate_dogtag_4,
}

def main():
    print(f"Generating 14 shop preview icons into {UI_DIR}...")
    success_count = 0
    for filename, gen_func in GENERATORS.items():
        print(f" -> Rendering {filename}...")
        img_640 = gen_func()
        # Lanczos downsample to 160x100 for crisp, antialiased, professional finish
        img_160 = img_640.resize((FINAL_W, FINAL_H), Image.Resampling.LANCZOS)
        out_path = os.path.join(UI_DIR, filename)
        img_160.save(out_path, "PNG", optimize=True)
        assert os.path.exists(out_path), f"Failed to create {out_path}"
        assert os.path.getsize(out_path) > 0, f"File {out_path} is empty"
        success_count += 1
        print(f"    ✓ Saved {filename} (160x100, {os.path.getsize(out_path):,} bytes)")

    print(f"\n[DONE] Successfully generated all {success_count}/14 icons!")

if __name__ == "__main__":
    main()
