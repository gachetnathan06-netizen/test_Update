import math
from PIL import Image, ImageDraw, ImageFilter, ImageChops

K = 3                      # supersampling
W = 1024 * K
def P(v): return int(v * K)

def lerp(a, b, t): return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(3))
def hexc(h): return ((h >> 16) & 255, (h >> 8) & 255, h & 255)

# ---------- Fond : encre profonde, lumière douce derrière BOB
bg = Image.new("RGB", (W, W))
px = ImageDraw.Draw(bg)
top, bot = hexc(0x14122B), hexc(0x2B1F52)
for y in range(W):
    px.line([(0, y), (W, y)], fill=lerp(top, bot, y / W))
halo = Image.new("L", (W, W), 0)
ImageDraw.Draw(halo).ellipse([P(180), P(250), P(844), P(914)], fill=150)
halo = halo.filter(ImageFilter.GaussianBlur(P(120)))
bg.paste(Image.new("RGB", (W, W), hexc(0x5B3FA0)), (0, 0), halo.point(lambda v: int(v * 0.55)))

# ---------- Silhouette de blob (dôme + base large et aplatie)
cx, cy = 512, 585
rx, ry = 296, 300
pts = []
N = 900
for i in range(N):
    t = 2 * math.pi * i / N
    c, s_ = math.cos(t), math.sin(t)
    f = 0.78 - 0.22 * math.tanh(5 * s_)          # dôme en haut, base aplatie, sans cassure
    wide = 1 + 0.07 * (0.5 + 0.5 * math.tanh(5 * s_))
    x = cx + rx * wide * c
    y = cy + ry * s_ * f
    pts.append((P(x), P(y)))

body_mask = Image.new("L", (W, W), 0)
ImageDraw.Draw(body_mask).polygon(pts, fill=255)

# ---------- Ombre au sol
sh = Image.new("L", (W, W), 0)
ImageDraw.Draw(sh).ellipse([P(200), P(742), P(824), P(822)], fill=200)
sh = sh.filter(ImageFilter.GaussianBlur(P(26)))
bg.paste(Image.new("RGB", (W, W), hexc(0x0B0A1F)), (0, 0), sh.point(lambda v: int(v * 0.75)))

# ---------- Corps : dégradé menthe
body = Image.new("RGB", (W, W))
bd = ImageDraw.Draw(body)
c1, c2 = hexc(0xA6F3DA), hexc(0x2FA88A)
y0, y1 = P(cy - ry), P(cy + ry * 0.60)
for y in range(W):
    t = min(1, max(0, (y - y0) / (y1 - y0)))
    bd.line([(0, y), (W, y)], fill=lerp(c1, c2, t ** 0.9))
# reflet de lumière ambiante en bas (rebond), pour du volume
rim = ImageChops.subtract(body_mask, body_mask.filter(ImageFilter.GaussianBlur(P(14))).point(lambda v: min(255, int(v * 1.0))))
bg.paste(body, (0, 0), body_mask)

# ombre intérieure basse (donne du poids)
inner = Image.new("L", (W, W), 0)
ImageDraw.Draw(inner).ellipse([P(150), P(630), P(874), P(990)], fill=255)
inner = inner.filter(ImageFilter.GaussianBlur(P(60)))
under = ImageChops.multiply(inner, body_mask)
bg.paste(Image.new("RGB", (W, W), hexc(0x1E7F69)), (0, 0), under.point(lambda v: int(v * 0.55)))

# ---------- Reflets
hl = Image.new("L", (W, W), 0)
ImageDraw.Draw(hl).ellipse([P(300), P(350), P(520), P(450)], fill=255)
hl = hl.rotate(22, center=(P(410), P(400))).filter(ImageFilter.GaussianBlur(P(10)))
bg.paste(Image.new("RGB", (W, W), (255, 255, 255)), (0, 0), ImageChops.multiply(hl, body_mask).point(lambda v: int(v * 0.55)))
sp = Image.new("L", (W, W), 0)
ImageDraw.Draw(sp).ellipse([P(560), P(372), P(590), P(400)], fill=255)
sp = sp.filter(ImageFilter.GaussianBlur(P(2)))
bg.paste(Image.new("RGB", (W, W), (255, 255, 255)), (0, 0), ImageChops.multiply(sp, body_mask).point(lambda v: int(v * 0.8)))

d = ImageDraw.Draw(bg)
ink = hexc(0x1B1530)

# ---------- Joues
ch = Image.new("L", (W, W), 0)
cd = ImageDraw.Draw(ch)
cd.ellipse([P(268), P(598), P(358), P(654)], fill=255)
cd.ellipse([P(666), P(598), P(756), P(654)], fill=255)
ch = ch.filter(ImageFilter.GaussianBlur(P(8)))
bg.paste(Image.new("RGB", (W, W), hexc(0xFF8FA3)), (0, 0), ch.point(lambda v: int(v * 0.8)))

# ---------- Yeux (grands, lisibles à 60 px)
def eye(ex, ey):
    d.ellipse([P(ex - 44), P(ey - 62), P(ex + 44), P(ey + 62)], fill=ink)
    d.ellipse([P(ex - 6), P(ey - 48), P(ex + 28), P(ey - 14)], fill=(255, 255, 255))
    d.ellipse([P(ex - 24), P(ey + 14), P(ex - 8), P(ey + 30)], fill=(255, 255, 255))
eye(398, 548)
eye(626, 548)

# ---------- Sourire
sm = [(P(512 + 58 * math.cos(a)), P(608 + 40 * math.sin(a))) for a in [math.radians(v) for v in range(20, 161, 4)]]
d.line(sm, fill=ink, width=P(16), joint="curve")
for q in (sm[0], sm[-1]):
    d.ellipse([q[0] - P(8), q[1] - P(8), q[0] + P(8), q[1] + P(8)], fill=ink)

# ---------- Étincelle ambre (clin d'œil à la boutique / aux pièces)
def sparkle(x, y, r, col):
    pts = []
    for i in range(8):
        a = math.pi / 4 * i - math.pi / 2
        rad = r if i % 2 == 0 else r * 0.30
        pts.append((P(x + rad * math.cos(a)), P(y + rad * math.sin(a))))
    d.polygon(pts, fill=col)
gl = Image.new("L", (W, W), 0)
ImageDraw.Draw(gl).ellipse([P(770), P(190), P(890), P(310)], fill=255)
gl = gl.filter(ImageFilter.GaussianBlur(P(28)))
bg.paste(Image.new("RGB", (W, W), hexc(0xFFB547)), (0, 0), gl.point(lambda v: int(v * 0.55)))
sparkle(830, 250, 62, hexc(0xFFC766))
sparkle(742, 168, 24, hexc(0xFFE2A3))

icon = bg.resize((1024, 1024), Image.LANCZOS)
icon.save("icon.png", optimize=True)
icon.resize((60, 60), Image.LANCZOS).resize((240, 240), Image.NEAREST).save("preview_small.png")
print(icon.size, icon.mode)
