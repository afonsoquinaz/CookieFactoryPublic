#!/usr/bin/env python3
"""Turns the raw icon renders (tools/icon_src/<name>.png, 512 px, transparent)
into UI icons: trim to the object, square with a margin, add a soft drop
shadow so light objects read on light panels, scale to 256 px, and write
assets/icons/<name>.png. Also builds the app icon, emblem and splash from the
token render.

    python3 tools/icon_post.py            # every icon
    python3 tools/icon_post.py gpu coin   # only these
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "tools", "icon_src")
OUT = os.path.join(ROOT, "assets", "icons")
ASSETS = os.path.join(ROOT, "assets")
SIZE = 256
MARGIN = 0.07


def trim_square(im, margin=MARGIN):
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 12)
    if len(xs) == 0:
        return im
    im = im.crop((xs.min(), ys.min(), xs.max() + 1, ys.max() + 1))
    w, h = im.size
    side = int(round(max(w, h) / (1 - 2 * margin)))
    canvas = Image.new("RGBA", (side, side), (0, 0, 0, 0))
    canvas.paste(im, ((side - w) // 2, (side - h) // 2))
    return canvas


def with_shadow(im):
    """A soft dark shadow under and slightly below the object."""
    a = im.split()[3]
    sh = Image.new("RGBA", im.size, (18, 24, 34, 0))
    sh.putalpha(a.point(lambda v: int(v * 0.42)))
    sh = sh.filter(ImageFilter.GaussianBlur(im.size[0] * 0.018))
    out = Image.new("RGBA", im.size, (0, 0, 0, 0))
    out.alpha_composite(sh, (0, int(im.size[1] * 0.018)))
    out.alpha_composite(im)
    return out


def bleed(im):
    """Fill the RGB of transparent pixels with nearby colour (no halos)."""
    arr = np.asarray(im).astype(np.float32)
    a = arr[:, :, 3]
    known = a > 0
    rgb = arr[:, :, :3] * known[:, :, None]
    w = known.astype(np.float32)
    for _ in range(4):
        s = np.zeros_like(rgb)
        c = np.zeros_like(w)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            s += np.roll(np.roll(rgb * w[:, :, None], dy, 0), dx, 1)
            c += np.roll(np.roll(w, dy, 0), dx, 1)
        new = (w == 0) & (c > 0)
        rgb[new] = s[new] / c[new][:, None]
        w[new] = 1
    out = np.dstack([rgb, a])
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def icon(name):
    im = Image.open(os.path.join(SRC, name + ".png")).convert("RGBA")
    im = trim_square(im)
    im = im.resize((SIZE, SIZE), Image.LANCZOS)
    im = bleed(with_shadow(im))
    im.save(os.path.join(OUT, name + ".png"))


def brand():
    """App icon (opaque navy, the token), emblem (transparent) and splash."""
    tok = os.path.join(SRC, "brand.png")
    if not os.path.exists(tok):
        return
    t = trim_square(Image.open(tok).convert("RGBA"), 0.0)
    # app icon 1024: navy radial gradient, brass ring, the token
    n = 1024
    yy, xx = np.mgrid[0:n, 0:n]
    d = np.sqrt((xx - n / 2) ** 2 + (yy - n / 2) ** 2) / (n / 2)
    c0 = np.array([0.13, 0.2, 0.32])
    c1 = np.array([0.05, 0.08, 0.14])
    g = c0[None, None, :] * (1 - d[:, :, None].clip(0, 1)) + c1[None, None, :] * d[:, :, None].clip(0, 1)
    bg = Image.fromarray((g * 255).astype(np.uint8), "RGB").convert("RGBA")
    dr = ImageDraw.Draw(bg)
    r = int(n * 0.4)
    dr.ellipse([n / 2 - r, n / 2 - r, n / 2 + r, n / 2 + r], outline=(200, 168, 100, 255), width=10)
    r2 = int(n * 0.37)
    dr.ellipse([n / 2 - r2, n / 2 - r2, n / 2 + r2, n / 2 + r2], outline=(80, 200, 220, 120), width=4)
    glow = Image.new("RGBA", (n, n), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([n * 0.28, n * 0.28, n * 0.72, n * 0.72], fill=(90, 220, 240, 110))
    bg.alpha_composite(glow.filter(ImageFilter.GaussianBlur(60)))
    ts = t.resize((int(n * 0.6), int(n * 0.6)), Image.LANCZOS)
    bg.alpha_composite(ts, ((n - ts.size[0]) // 2, (n - ts.size[1]) // 2))
    bg.convert("RGB").save(os.path.join(ASSETS, "app_icon.png"))
    bg.convert("RGB").resize((256, 256), Image.LANCZOS).save(os.path.join(ROOT, "icon.png"))
    # emblem 512: the token with a brass ring, transparent
    e = Image.new("RGBA", (512, 512), (0, 0, 0, 0))
    ed = ImageDraw.Draw(e)
    ed.ellipse([20, 20, 492, 492], outline=(200, 168, 100, 255), width=8)
    ed.ellipse([38, 38, 474, 474], outline=(80, 200, 220, 140), width=3)
    ts2 = t.resize((340, 340), Image.LANCZOS)
    e.alpha_composite(ts2, ((512 - 340) // 2, (512 - 340) // 2))
    e.save(os.path.join(ASSETS, "emblem.png"))
    e.resize((256, 256), Image.LANCZOS).save(os.path.join(ASSETS, "splash.png"))


def main():
    names = [a for a in sys.argv[1:] if not a.startswith("-")]
    if not names:
        names = sorted(f[:-4] for f in os.listdir(SRC) if f.endswith(".png"))
    os.makedirs(OUT, exist_ok=True)
    for n in names:
        if os.path.exists(os.path.join(SRC, n + ".png")):
            icon(n)
    brand()
    print("icons:", len(names))


if __name__ == "__main__":
    main()
