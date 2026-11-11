#!/usr/bin/env python3
"""
Generates original, handcrafted, tactile HUD art assets for SAKURA BLITZ:
- Warm Walnut Wood + Brushed Gunmetal + Brass Rivets + Crimson Lacquer Seal aesthetic
  (Cozy Japanese Sakura Village x Call of Duty Black Ops Tactical Dogtag/Tape aesthetic).
- 4x Supersampled PIL rendering into C:/Users/Editora Vélos/SAKURA_BLITZ/assets/ui/
- Also copies a bold condensed display font from Windows Fonts to assets/ui/hud_font.ttf
  so Godot never uses the generic default fallback font.
"""

import math
import os
import shutil
from PIL import Image, ImageDraw, ImageFilter, ImageFont

OUT_DIR = r"C:\Users\Editora Vélos\SAKURA_BLITZ\assets\ui"
os.makedirs(OUT_DIR, exist_ok=True)


def get_font(size: int, bold: bool = True):
    candidates = [
        r"C:\Windows\Fonts\impact.ttf",
        r"C:\Windows\Fonts\bahnschrift.ttf",
        r"C:\Windows\Fonts\arialbd.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
    ]
    for c in candidates:
        if os.path.exists(c):
            try:
                return ImageFont.truetype(c, size)
            except Exception:
                pass
    return ImageFont.load_default()


def copy_hud_font():
    # Copy a real bold display font into the Godot project so HUD numbers/titles look authentic
    for src in [
        r"C:\Windows\Fonts\bahnschrift.ttf",
        r"C:\Windows\Fonts\impact.ttf",
        r"C:\Windows\Fonts\segoeuib.ttf",
    ]:
        if os.path.exists(src):
            shutil.copyfile(src, os.path.join(OUT_DIR, "hud_font.ttf"))
            print(f"Copied {src} -> assets/ui/hud_font.ttf")
            break


def draw_rivet(draw: ImageDraw.ImageDraw, cx: float, cy: float, r: float):
    draw.ellipse([cx - r - 2, cy - r - 2, cx + r + 2, cy + r + 2], fill=(22, 18, 16, 220))
    draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(212, 168, 84, 255), outline=(92, 64, 24, 255), width=2)
    draw.ellipse([cx - r * 0.45, cy - r * 0.55, cx + r * 0.15, cy - r * 0.1], fill=(255, 235, 180, 220))
    draw.line([cx - r * 0.5, cy + r * 0.3, cx + r * 0.5, cy - r * 0.3], fill=(92, 64, 24, 230), width=2)


def build_vitality_frame():
    """
    Bottom-Left Tactile HUD Frame (380x132 -> rendered at 1520x528):
    - Left circular brass & crimson lacquer bezel with a painted Samurai/Tactical Mask emblem
    - Center brushed gunmetal & warm walnut wood casing with recessed slots for HP & Armor bars
    - Right circular mechanical Tachometer / Speedometer dial face (0..400 u/s) with tick marks & redline
    """
    W, H = 1520, 528
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Drop shadow
    body_pts = [
        (180, 56), (1240, 56), (1480, 120), (1496, 488), (180, 488)
    ]
    sh_pts = [(x + 12, y + 16) for (x, y) in body_pts]
    d.polygon(sh_pts, fill=(0, 0, 0, 135))

    # Outer Walnut Wood + Brass Trim Casing
    d.polygon(body_pts, fill=(58, 38, 26, 245), outline=(218, 172, 86, 255), width=8)

    # Inner Brushed Gunmetal Plate
    inner_pts = [
        (200, 76), (1230, 76), (1460, 134), (1474, 468), (200, 468)
    ]
    d.polygon(inner_pts, fill=(32, 35, 42, 248), outline=(88, 72, 54, 255), width=4)

    # Subtle diagonal brushed-metal texture lines
    for x in range(250, 1220, 28):
        d.line([(x, 80), (x - 50, 464)], fill=(42, 46, 55, 110), width=4)

    # Top crimson lacquer accent strip
    d.polygon([(230, 76), (980, 76), (964, 102), (230, 102)], fill=(186, 44, 52, 255))

    # Recessed Armor Slot (top bar groove)
    d.rounded_rectangle([268, 224, 988, 268], radius=10, fill=(16, 18, 22, 255), outline=(72, 78, 92, 255), width=4)
    # Recessed Health Slot (main thick bar groove)
    d.rounded_rectangle([268, 286, 988, 368], radius=14, fill=(16, 18, 22, 255), outline=(96, 82, 64, 255), width=5)

    # Bottom masking-tape / brass label strip for stance
    d.rounded_rectangle([268, 390, 920, 448], radius=8, fill=(236, 224, 198, 245), outline=(140, 116, 82, 255), width=3)

    # Corner brass rivets
    for rx, ry in [(240, 124), (960, 124), (240, 440), (960, 440)]:
        draw_rivet(d, rx, ry, 11)

    # --- LEFT EMBLEM: Circular Brass & Crimson Lacquer Medallion with Tactical Oni/Operator Mask ---
    cx, cy, cr = 164, 276, 144
    d.ellipse([cx - cr + 8, cy - cr + 14, cx + cr + 8, cy + cr + 14], fill=(0, 0, 0, 140))
    # Outer brass ring
    d.ellipse([cx - cr, cy - cr, cx + cr, cy + cr], fill=(214, 168, 82, 255), outline=(78, 52, 20, 255), width=8)
    # Crimson lacquer inner ring
    d.ellipse([cx - cr + 18, cy - cr + 18, cx + cr - 18, cy + cr - 18], fill=(154, 34, 42, 255), outline=(242, 204, 120, 255), width=4)
    # Dark inner portrait background
    d.ellipse([cx - cr + 34, cy - cr + 34, cx + cr - 34, cy + cr - 34], fill=(24, 26, 34, 255))

    # Stylized Tactical Operator Helmet + Visor + Samurai Mask inside medallion
    # Helmet dome
    d.chord([cx - 78, cy - 88, cx + 78, cy + 40], start=180, end=360, fill=(52, 60, 74, 255), outline=(18, 20, 26, 255), width=5)
    # Helmet forehead crest (gold)
    d.polygon([(cx, cy - 92), (cx - 28, cy - 52), (cx - 10, cy - 52), (cx, cy - 72), (cx + 10, cy - 52), (cx + 28, cy - 52)], fill=(245, 198, 84, 255))
    # Glowing tactical visor goggles
    d.polygon([(cx - 64, cy - 34), (cx - 8, cy - 24), (cx - 14, cy + 2), (cx - 58, cy - 6)], fill=(255, 214, 102, 255), outline=(255, 120, 40, 255), width=3)
    d.polygon([(cx + 64, cy - 34), (cx + 8, cy - 24), (cx + 14, cy + 2), (cx + 58, cy - 6)], fill=(255, 214, 102, 255), outline=(255, 120, 40, 255), width=3)
    # Lower face respirator / samurai mempo mask
    d.polygon([(cx - 54, cy + 8), (cx, cy - 4), (cx + 54, cy + 8), (cx + 38, cy + 68), (cx, cy + 82), (cx - 38, cy + 68)], fill=(198, 48, 58, 255), outline=(24, 18, 20, 255), width=5)
    # Mask vents / tusks
    d.polygon([(cx - 34, cy + 36), (cx - 18, cy + 20), (cx - 12, cy + 44)], fill=(248, 240, 225, 255))
    d.polygon([(cx + 34, cy + 36), (cx + 18, cy + 20), (cx + 12, cy + 44)], fill=(248, 240, 225, 255))

    # --- RIGHT DIAL: Mechanical Analog Speedometer / Tachometer Face ---
    gx, gy, gr = 1236, 276, 176
    d.ellipse([gx - gr, gy - gr, gx + gr, gy + gr], fill=(214, 168, 82, 255), outline=(72, 48, 20, 255), width=7)
    d.ellipse([gx - gr + 16, gy - gr + 16, gx + gr - 16, gy + gr - 16], fill=(22, 24, 30, 255), outline=(110, 118, 134, 255), width=4)

    # Tachometer tick marks (from 135 deg to 405 deg)
    for step in range(28):
        u = step / 27.0
        ang = math.radians(135.0 + u * 270.0)
        r_out = gr - 26
        r_in = r_out - (26 if step % 3 == 0 else 14)
        col = (235, 64, 72, 255) if u > 0.72 else ((245, 198, 84, 255) if u > 0.45 else (230, 224, 210, 235))
        w = 6 if step % 3 == 0 else 3
        x1 = gx + math.cos(ang) * r_in
        y1 = gy + math.sin(ang) * r_in
        x2 = gx + math.cos(ang) * r_out
        y2 = gy + math.sin(ang) * r_out
        d.line([(x1, y1), (x2, y2)], fill=col, width=w)

    # Center brass cap placeholder
    d.ellipse([gx - 22, gy - 22, gx + 22, gy + 22], fill=(64, 70, 82, 255), outline=(214, 168, 82, 255), width=4)

    out = img.resize((380, 132), Image.Resampling.LANCZOS)
    out.save(os.path.join(OUT_DIR, "hud_vitality_frame.png"))
    print("Saved hud_vitality_frame.png")


def build_weapon_frame():
    """
    Bottom-Right Tactile Arsenal Frame (400x132 -> rendered at 1600x528):
    - Warm walnut wood + brushed gunmetal casing with brass rivets
    - Left recessed weapon display bay (with blueprint grid)
    - Right stamped ammo counter bay + 4 physical keycap slots at bottom
    """
    W, H = 1600, 528
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    body_pts = [
        (104, 120), (340, 56), (1568, 56), (1568, 488), (24, 488)
    ]
    sh_pts = [(x + 12, y + 16) for (x, y) in body_pts]
    d.polygon(sh_pts, fill=(0, 0, 0, 135))

    # Walnut Wood + Brass Outer Frame
    d.polygon(body_pts, fill=(58, 38, 26, 245), outline=(218, 172, 86, 255), width=8)

    # Inner Gunmetal Plate
    inner_pts = [
        (122, 136), (348, 76), (1548, 76), (1548, 468), (46, 468)
    ]
    d.polygon(inner_pts, fill=(32, 35, 42, 248), outline=(88, 72, 54, 255), width=4)

    # Top crimson seal stripe
    d.polygon([(354, 76), (1548, 76), (1548, 102), (338, 102)], fill=(186, 44, 52, 255))

    # Left Recessed Weapon Silhouette Showcase Bay
    d.rounded_rectangle([136, 128, 740, 356], radius=16, fill=(20, 23, 29, 255), outline=(142, 114, 68, 255), width=5)
    # Subtle tactical grid inside weapon bay
    for gx in range(168, 720, 48):
        d.line([(gx, 134), (gx, 350)], fill=(34, 40, 50, 140), width=2)
    for gy in range(160, 340, 48):
        d.line([(142, gy), (734, gy)], fill=(34, 40, 50, 140), width=2)

    # Right Stamped Paper / Parchment Tag for Weapon Name & Skin
    d.rounded_rectangle([768, 124, 1516, 212], radius=10, fill=(238, 226, 200, 248), outline=(138, 108, 68, 255), width=4)
    # Red Japanese Hanko Stamp mark on right of tag
    d.rounded_rectangle([1436, 138, 1496, 198], radius=6, outline=(196, 42, 48, 220), width=5)
    d.ellipse([1452, 154, 1480, 182], fill=(196, 42, 48, 200))

    # Bottom 4 Mechanical Keycap Bays ([1] [2] [3] [4])
    for i in range(4):
        kx = 120 + i * 352
        ky = 376
        d.rounded_rectangle([kx, ky, kx + 332, ky + 76], radius=12, fill=(20, 22, 28, 255), outline=(92, 82, 68, 255), width=4)

    for rx, ry in [(368, 116), (1520, 116), (84, 440), (1520, 440)]:
        draw_rivet(d, rx, ry, 11)

    out = img.resize((400, 132), Image.Resampling.LANCZOS)
    out.save(os.path.join(OUT_DIR, "hud_weapon_frame.png"))
    print("Saved hud_weapon_frame.png")


def build_top_scoreboard():
    """
    Top-Center Torii-Arch & Brass Score Clapperboard (480x82 -> rendered at 1920x328):
    - Inspired by traditional wooden/brass tournament plaques + Black Ops tally bars
    - Left Teal/Blue Seal (CT), Center Dark Wood & Brass Stage/Timer Plaque, Right Crimson Seal (TR)
    """
    W, H = 1920, 328
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    # Top Curved Torii Lintel Bar across the whole scoreboard
    d.polygon([
        (120, 12), (1800, 12), (1848, 44), (72, 44)
    ], fill=(178, 38, 46, 255), outline=(68, 22, 24, 255), width=5)
    d.rectangle([220, 38, 1700, 54], fill=(218, 172, 84, 255))

    # Left Team Seal Wing (CT - Deep Indigo/Teal Lacquer)
    ct_pts = [(160, 52), (620, 52), (656, 192), (208, 192)]
    d.polygon([(x + 8, y + 12) for (x, y) in ct_pts], fill=(0, 0, 0, 130))
    d.polygon(ct_pts, fill=(24, 78, 104, 248), outline=(218, 172, 84, 255), width=6)
    d.polygon([(184, 68), (330, 68), (344, 176), (220, 176)], fill=(16, 52, 72, 255))

    # Right Team Seal Wing (TR - Deep Crimson Lacquer)
    tr_pts = [(1300, 52), (1760, 52), (1712, 192), (1264, 192)]
    d.polygon([(x + 8, y + 12) for (x, y) in tr_pts], fill=(0, 0, 0, 130))
    d.polygon(tr_pts, fill=(142, 32, 42, 248), outline=(218, 172, 84, 255), width=6)
    d.polygon([(1590, 68), (1736, 68), (1700, 176), (1576, 176)], fill=(96, 20, 28, 255))

    # Center Walnut & Brass Match Plaque
    mid_pts = [(604, 44), (1316, 44), (1280, 208), (640, 208)]
    d.polygon([(x + 8, y + 12) for (x, y) in mid_pts], fill=(0, 0, 0, 140))
    d.polygon(mid_pts, fill=(44, 30, 22, 252), outline=(224, 178, 88, 255), width=7)
    d.rounded_rectangle([668, 66, 1252, 184], radius=12, fill=(24, 22, 26, 255), outline=(128, 98, 56, 255), width=4)

    # 4 Tactile Stage Tabs hung underneath ([F1] [F2] [F3] [F4])
    for i in range(4):
        tx = 280 + i * 344
        ty = 218
        d.rounded_rectangle([tx, ty, tx + 324, ty + 88], radius=12, fill=(38, 28, 22, 242), outline=(188, 146, 74, 255), width=5)

    for rx, ry in [(642, 68), (1278, 68), (662, 186), (1258, 186)]:
        draw_rivet(d, rx, ry, 9)

    out = img.resize((480, 82), Image.Resampling.LANCZOS)
    out.save(os.path.join(OUT_DIR, "hud_top_scoreboard.png"))
    print("Saved hud_top_scoreboard.png")


def build_wallet_and_kill_tapes():
    """
    1) hud_wallet_badge.png (290x54): Top-Left Warm Parchment & Brass Dogtag/Coin Pouch Strip
       with painted Gold Coin stack and Ruby Gem (ZERO Unicode emojis!)
    2) hud_kill_tape.png (310x28): Top-Right Torn Masking-Tape / Brush-Stroke Killfeed Strip
       with painted Crimson Skull-Crosshair stamp
    """
    # --- 1. Wallet & Dogtag Badge (1160x216 -> 290x54) ---
    W, H = 1160, 216
    img = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)

    pts = [(24, 20), (1136, 20), (1104, 192), (24, 192)]
    d.polygon([(x + 8, y + 12) for (x, y) in pts], fill=(0, 0, 0, 125))
    d.polygon(pts, fill=(46, 32, 24, 246), outline=(218, 172, 84, 255), width=7)
    d.rounded_rectangle([44, 38, 1084, 174], radius=12, fill=(28, 26, 32, 255), outline=(112, 88, 54, 255), width=4)

    # Painted Rank Shield Crest on Left (x = 96, y = 106)
    sx, sy = 104, 106
    shield = [
        (sx, sy - 54), (sx + 50, sy - 38), (sx + 42, sy + 22), (sx, sy + 58), (sx - 42, sy + 22), (sx - 50, sy - 38)
    ]
    d.polygon(shield, fill=(186, 42, 50, 255), outline=(245, 202, 96, 255), width=6)
    # Gold chevron inside shield
    d.polygon([(sx, sy - 24), (sx + 26, sy + 4), (sx + 16, sy + 16), (sx, sy - 2), (sx - 16, sy + 16), (sx - 26, sy + 4)], fill=(250, 212, 106, 255))

    # Painted Gold Coin Icon at x = 620, y = 106
    cx, cy = 628, 106
    d.ellipse([cx - 32, cy - 32, cx + 32, cy + 32], fill=(245, 192, 62, 255), outline=(124, 78, 18, 255), width=5)
    d.ellipse([cx - 22, cy - 22, cx + 22, cy + 22], fill=(255, 222, 112, 255))
    d.rectangle([cx - 8, cy - 8, cx + 8, cy + 8], fill=(46, 32, 24, 255)) # Traditional square-hole Japanese/arcade coin!

    # Painted Faceted Diamond/Gem Icon at x = 880, y = 106
    gx, gy = 888, 106
    gem = [(gx, gy - 32), (gx + 28, gy - 8), (gx, gy + 34), (gx - 28, gy - 8)]
    d.polygon(gem, fill=(56, 216, 235, 255), outline=(18, 92, 118, 255), width=5)
    d.polygon([(gx, gy - 26), (gx + 14, gy - 8), (gx, gy + 12), (gx - 14, gy - 8)], fill=(190, 250, 255, 255))

    out = img.resize((290, 54), Image.Resampling.LANCZOS)
    out.save(os.path.join(OUT_DIR, "hud_wallet_badge.png"))
    print("Saved hud_wallet_badge.png")

    # --- 2. Torn Masking-Tape Killfeed Strip (1240x112 -> 310x28) ---
    W2, H2 = 1240, 112
    img2 = Image.new("RGBA", (W2, H2), (0, 0, 0, 0))
    d2 = ImageDraw.Draw(img2)
    tape_pts = [
        (36, 12), (1220, 8), (1208, 38), (1224, 68), (1204, 100), (20, 102), (34, 66), (16, 38)
    ]
    d2.polygon([(x + 6, y + 8) for (x, y) in tape_pts], fill=(0, 0, 0, 120))
    d2.polygon(tape_pts, fill=(238, 226, 202, 242), outline=(146, 118, 82, 255), width=4)
    # Left Crimson Brush Seal on the tape
    d2.polygon([(36, 12), (144, 12), (128, 100), (20, 102)], fill=(188, 38, 48, 255))
    # Painted white skull/crosshair inside the crimson seal
    kx, ky = 82, 56
    d2.ellipse([kx - 22, ky - 22, kx + 22, ky + 22], outline=(255, 245, 230, 255), width=5)
    d2.line([(kx - 32, ky), (kx + 32, ky)], fill=(255, 245, 230, 255), width=4)
    d2.line([(kx, ky - 32), (kx, ky + 32)], fill=(255, 245, 230, 255), width=4)

    out2 = img2.resize((310, 28), Image.Resampling.LANCZOS)
    out2.save(os.path.join(OUT_DIR, "hud_kill_tape.png"))
    print("Saved hud_kill_tape.png")


def build_weapon_sprites():
    """
    Generates 4 detailed, 4x supersampled side-profile Weapon Sprites for the HUD Arsenal Bay:
    - hud_gun_0.png (AK-47 Commando)
    - hud_gun_1.png (AWP L96A1 Sniper)
    - hud_gun_2.png (Desert Eagle .50)
    - hud_gun_3.png (Karambit Curved Claw Knife)
    Size: 600x220 -> 150x55
    """
    W, H = 600, 220

    # 0: AK-47 Commando
    im0 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im0)
    # Wood stock
    d.polygon([(34, 96), (176, 84), (176, 128), (44, 158)], fill=(168, 92, 44, 255), outline=(42, 24, 14, 255), width=5)
    # Receiver & dust cover
    d.rounded_rectangle([170, 74, 370, 128], radius=8, fill=(68, 74, 86, 255), outline=(22, 24, 30, 255), width=5)
    d.rectangle([182, 92, 356, 104], fill=(238, 186, 72, 255))
    # Banana magazine
    d.polygon([(284, 126), (334, 126), (368, 204), (314, 208)], fill=(214, 142, 48, 255), outline=(32, 22, 14, 255), width=5)
    # Pistol grip
    d.polygon([(192, 126), (232, 126), (214, 184), (174, 184)], fill=(142, 74, 34, 255), outline=(32, 20, 12, 255), width=5)
    # Handguard & barrel + front sight
    d.rounded_rectangle([366, 82, 466, 118], radius=6, fill=(168, 92, 44, 255), outline=(38, 22, 14, 255), width=5)
    d.rectangle([466, 90, 566, 104], fill=(54, 60, 70, 255), outline=(20, 22, 28, 255), width=4)
    d.polygon([(534, 62), (552, 62), (558, 92), (534, 92)], fill=(54, 60, 70, 255), outline=(20, 22, 28, 255), width=4)
    # Red dot sight on top rail
    d.rounded_rectangle([226, 42, 298, 74], radius=6, fill=(40, 44, 54, 255), outline=(218, 172, 84, 255), width=4)
    d.ellipse([254, 50, 270, 66], fill=(255, 64, 78, 255))
    im0.resize((150, 55), Image.Resampling.LANCZOS).save(os.path.join(OUT_DIR, "hud_gun_0.png"))

    # 1: AWP Sniper
    im1 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im1)
    # Green/Gold thumbhole chassis
    d.polygon([(24, 92), (390, 82), (390, 128), (190, 134), (168, 176), (132, 176), (144, 132), (30, 152)], fill=(58, 108, 74, 255), outline=(20, 28, 22, 255), width=5)
    # Long fluted barrel + muzzle brake
    d.rectangle([388, 86, 576, 102], fill=(64, 70, 82, 255), outline=(20, 22, 28, 255), width=4)
    d.rectangle([558, 80, 586, 108], fill=(218, 172, 84, 255), outline=(40, 30, 14, 255), width=4)
    # Large telescopic sniper scope
    d.polygon([(190, 38), (376, 32), (376, 68), (190, 62)], fill=(38, 42, 52, 255), outline=(218, 172, 84, 255), width=4)
    d.rectangle([232, 62, 252, 84], fill=(48, 52, 62, 255))
    d.rectangle([318, 62, 338, 84], fill=(48, 52, 62, 255))
    im1.resize((150, 55), Image.Resampling.LANCZOS).save(os.path.join(OUT_DIR, "hud_gun_1.png"))

    # 2: Desert Eagle .50
    im2 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im2)
    # Heavy silver/gold triangular slide
    d.polygon([(156, 54), (456, 54), (442, 116), (156, 116)], fill=(224, 184, 88, 255), outline=(36, 28, 16, 255), width=6)
    d.rectangle([186, 74, 412, 88], fill=(255, 232, 156, 255))
    # Grip
    d.polygon([(172, 114), (254, 114), (226, 198), (146, 194)], fill=(44, 46, 54, 255), outline=(20, 22, 26, 255), width=6)
    im2.resize((150, 55), Image.Resampling.LANCZOS).save(os.path.join(OUT_DIR, "hud_gun_2.png"))

    # 3: Karambit Curved Claw Knife
    im3 = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(im3)
    # Finger ring
    d.ellipse([116, 102, 188, 174], outline=(224, 178, 84, 255), width=12)
    # Ergonomic handle
    d.polygon([(176, 114), (294, 86), (306, 128), (186, 152)], fill=(48, 34, 28, 255), outline=(218, 172, 84, 255), width=5)
    # Curved claw blade (crimson/gold gradient look)
    d.polygon([(294, 86), (484, 36), (442, 116), (306, 128)], fill=(228, 52, 68, 255), outline=(255, 214, 102, 255), width=5)
    im3.resize((150, 55), Image.Resampling.LANCZOS).save(os.path.join(OUT_DIR, "hud_gun_3.png"))
    print("Saved hud_gun_0..3.png")


if __name__ == "__main__":
    copy_hud_font()
    build_vitality_frame()
    build_weapon_frame()
    build_top_scoreboard()
    build_wallet_and_kill_tapes()
    build_weapon_sprites()
    print("All handcrafted HUD art assets generated successfully!")
