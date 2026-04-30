"""
Generates assets/icon.png — CricByAli app icon
Cricket stumps + red ball impact, dark stadium background
"""
from PIL import Image, ImageDraw, ImageFilter
import math, os

SIZE = 1024
img = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
draw = ImageDraw.Draw(img)

# ── Background ────────────────────────────────────────────────────────────────
bg = Image.new('RGBA', (SIZE, SIZE))
bg_draw = ImageDraw.Draw(bg)
for y in range(SIZE):
    t = y / SIZE
    r = int(6 + t * 4)
    g = int(15 + t * 6)
    b = int(30 + t * 14)
    bg_draw.line([(0, y), (SIZE, y)], fill=(r, g, b, 255))

# Round the background into a circle (app icon shape)
mask = Image.new('L', (SIZE, SIZE), 0)
mask_draw = ImageDraw.Draw(mask)
mask_draw.ellipse([0, 0, SIZE - 1, SIZE - 1], fill=255)
img.paste(bg, (0, 0), mask)

draw = ImageDraw.Draw(img)

# ── Stumps ────────────────────────────────────────────────────────────────────
STUMP_W = 58
STUMP_H = 510
STUMP_BOTTOM = 820
STUMP_TOP = STUMP_BOTTOM - STUMP_H
CX = 540          # slightly right of centre (ball comes from left)
GAP = 100
stump_xs = [CX - GAP, CX, CX + GAP]

WOOD_BASE  = (195, 160, 100)
WOOD_LIGHT = (225, 195, 130)
WOOD_DARK  = (150, 118, 65)

for sx in stump_xs:
    x0, x1 = sx - STUMP_W // 2, sx + STUMP_W // 2
    y0, y1 = STUMP_TOP, STUMP_BOTTOM
    r = 14  # corner radius

    # Shadow behind stump
    for s in range(8, 0, -1):
        alpha = int(120 * s / 8)
        draw.rounded_rectangle(
            [x0 + s, y0 + s, x1 + s, y1 + s],
            radius=r, fill=(0, 0, 0, alpha))

    # Main stump body
    draw.rounded_rectangle([x0, y0, x1, y1], radius=r, fill=WOOD_BASE)

    # Left highlight strip
    draw.rounded_rectangle([x0, y0, x0 + 14, y1], radius=r, fill=WOOD_LIGHT)

    # Right shadow strip
    draw.rounded_rectangle([x1 - 14, y0, x1, y1], radius=r, fill=WOOD_DARK)

    # Grain lines
    for gy in range(y0 + 60, y1 - 20, 55):
        draw.line([(x0 + 8, gy), (x1 - 6, gy + 12)],
                  fill=(170, 135, 80, 90), width=2)

# ── Bail caps on top of each stump ───────────────────────────────────────────
BAIL_COLOR = (230, 200, 140)
for sx in stump_xs:
    draw.rounded_rectangle(
        [sx - STUMP_W // 2 - 4, STUMP_TOP - 18,
         sx + STUMP_W // 2 + 4, STUMP_TOP + 10],
        radius=6, fill=BAIL_COLOR)

# ── Flying bails (broken off, mid-air) ───────────────────────────────────────
def draw_bail(cx, cy, angle_deg, length=105, thick=20):
    angle = math.radians(angle_deg)
    dx = math.cos(angle) * length / 2
    dy = math.sin(angle) * length / 2
    # Thick rounded line = ellipse
    pts = [
        (cx - dx - thick * math.sin(angle), cy - dy + thick * math.cos(angle)),
        (cx + dx - thick * math.sin(angle), cy + dy + thick * math.cos(angle)),
        (cx + dx + thick * math.sin(angle), cy + dy - thick * math.cos(angle)),
        (cx - dx + thick * math.sin(angle), cy - dy - thick * math.cos(angle)),
    ]
    draw.polygon(pts, fill=BAIL_COLOR)

# Left bail — flying upper-left
draw_bail(cx=420, cy=STUMP_TOP - 90, angle_deg=-35, length=110, thick=16)
# Right bail — flying upper-right, more rotation
draw_bail(cx=610, cy=STUMP_TOP - 120, angle_deg=20,  length=105, thick=16)

# ── Ball glow (diffuse red light) ─────────────────────────────────────────────
BALL_CX, BALL_CY = 285, STUMP_TOP + 210
BALL_R = 118

glow_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow_layer)
for gi in range(7, 0, -1):
    gr = BALL_R + gi * 22
    alpha = int(55 * gi / 7)
    gd.ellipse([BALL_CX - gr, BALL_CY - gr, BALL_CX + gr, BALL_CY + gr],
               fill=(200, 30, 30, alpha))
glow_layer = glow_layer.filter(ImageFilter.GaussianBlur(radius=18))
img = Image.alpha_composite(img, glow_layer)
draw = ImageDraw.Draw(img)

# ── Ball body ─────────────────────────────────────────────────────────────────
BALL_RED   = (185, 28, 28)
BALL_DARK  = (130, 18, 18)
BALL_SHINE = (220, 70, 70)

# Main sphere
draw.ellipse(
    [BALL_CX - BALL_R, BALL_CY - BALL_R, BALL_CX + BALL_R, BALL_CY + BALL_R],
    fill=BALL_RED)

# Dark shading (lower-right)
shadow_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow_layer)
sd.ellipse(
    [BALL_CX - BALL_R + 30, BALL_CY - BALL_R + 30,
     BALL_CX + BALL_R + 20, BALL_CY + BALL_R + 20],
    fill=(100, 10, 10, 130))
shadow_layer = shadow_layer.filter(ImageFilter.GaussianBlur(radius=30))
img = Image.alpha_composite(img, shadow_layer)
draw = ImageDraw.Draw(img)

# Highlight (upper-left shine)
shine_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
shd = ImageDraw.Draw(shine_layer)
shd.ellipse(
    [BALL_CX - BALL_R + 12, BALL_CY - BALL_R + 12,
     BALL_CX - BALL_R + 12 + 80, BALL_CY - BALL_R + 12 + 80],
    fill=(255, 120, 120, 160))
shine_layer = shine_layer.filter(ImageFilter.GaussianBlur(radius=18))
img = Image.alpha_composite(img, shine_layer)
draw = ImageDraw.Draw(img)

# ── Seam lines ────────────────────────────────────────────────────────────────
SEAM = (255, 255, 255)
SEAM2 = (240, 200, 200)

def arc_points(cx, cy, rx, ry, start_deg, end_deg, steps=40):
    pts = []
    for i in range(steps + 1):
        t = math.radians(start_deg + (end_deg - start_deg) * i / steps)
        pts.append((cx + rx * math.cos(t), cy + ry * math.sin(t)))
    return pts

# Vertical seam curve
vpts = arc_points(BALL_CX + 25, BALL_CY, BALL_R - 20, BALL_R - 10, -70, 70, 30)
for i in range(len(vpts) - 1):
    draw.line([vpts[i], vpts[i + 1]], fill=SEAM, width=5)

# Horizontal seam curve
hpts = arc_points(BALL_CX, BALL_CY + 10, BALL_R - 12, BALL_R - 25, 190, 350, 30)
for i in range(len(hpts) - 1):
    draw.line([hpts[i], hpts[i + 1]], fill=SEAM, width=5)

# Seam stitch marks
for ang in range(-65, 70, 18):
    rad = math.radians(ang)
    mx = BALL_CX + 25 + (BALL_R - 20) * math.cos(rad)
    my = BALL_CY + (BALL_R - 10) * math.sin(rad)
    perp = math.radians(ang + 90)
    draw.line([
        (mx + 8 * math.cos(perp), my + 8 * math.sin(perp)),
        (mx - 8 * math.cos(perp), my - 8 * math.sin(perp))
    ], fill=SEAM2, width=3)

# ── Motion trail behind ball ──────────────────────────────────────────────────
trail_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
td = ImageDraw.Draw(trail_layer)
for ti in range(5):
    tx = BALL_CX - BALL_R - 20 - ti * 45
    alpha = int(70 - ti * 12)
    td.ellipse(
        [tx - (BALL_R - ti * 18), BALL_CY - (BALL_R - ti * 14),
         tx + (BALL_R - ti * 18), BALL_CY + (BALL_R - ti * 14)],
        fill=(180, 25, 25, alpha))
trail_layer = trail_layer.filter(ImageFilter.GaussianBlur(radius=14))
img = Image.alpha_composite(img, trail_layer)
draw = ImageDraw.Draw(img)

# ── Ground shadow ─────────────────────────────────────────────────────────────
for gi in range(5):
    alpha = int(80 - gi * 14)
    draw.ellipse(
        [CX - GAP - STUMP_W - 30 + gi * 10,
         STUMP_BOTTOM + gi * 6,
         CX + GAP + STUMP_W + 30 - gi * 10,
         STUMP_BOTTOM + 22 + gi * 6],
        fill=(0, 0, 0, alpha))

# ── Circular border glow ──────────────────────────────────────────────────────
border_layer = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
bd = ImageDraw.Draw(border_layer)
for bi in range(4):
    bd.ellipse(
        [bi * 3, bi * 3, SIZE - bi * 3 - 1, SIZE - bi * 3 - 1],
        outline=(0, 109, 91, int(180 - bi * 40)), width=4)
img = Image.alpha_composite(img, border_layer)

# ── Final crop to circle ──────────────────────────────────────────────────────
final = Image.new('RGBA', (SIZE, SIZE), (0, 0, 0, 0))
circle_mask = Image.new('L', (SIZE, SIZE), 0)
Image.Draw = ImageDraw.Draw
md = ImageDraw.Draw(circle_mask)
md.ellipse([0, 0, SIZE - 1, SIZE - 1], fill=255)
final.paste(img, (0, 0), circle_mask)

os.makedirs('assets', exist_ok=True)
final.save('assets/icon.png')
print("✅ icon.png generated successfully")
