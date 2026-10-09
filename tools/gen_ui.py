#!/usr/bin/env python3
"""Draws the game UI skin (9-patch textures) for Cookie Empire with PIL.

    python3 tools/gen_ui.py      # writes assets/ui/*.png

Everything is drawn at 4x and downsampled, so edges are smooth: wood-framed
parchment panels, glossy beveled buttons with a darker lip, framed HUD
counters, ribbon banners, tabs and bars.
"""
import os
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "ui")
S = 4


def rgb(c, a=255):
    return (int(c[0] * 255), int(c[1] * 255), int(c[2] * 255), a)


def mix(a, b, t):
    return tuple(a[i] + (b[i] - a[i]) * t for i in range(3))


def rr(d, box, r, fill=None, outline=None, width=0):
    d.rounded_rectangle([v * S for v in box], radius=r * S, fill=fill, outline=outline, width=width * S)


def vgrad(w, h, top, bottom, r, inset=0):
    """Vertical gradient clipped to a rounded rect, as an RGBA image (4x)."""
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    grad = Image.new("RGBA", (w * S, h * S))
    gd = ImageDraw.Draw(grad)
    for y in range(h * S):
        t = y / max(1, h * S - 1)
        gd.line([(0, y), (w * S, y)], fill=rgb(mix(top, bottom, t)))
    mask = Image.new("L", (w * S, h * S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([inset * S, inset * S, (w - inset) * S - 1, (h - inset) * S - 1], radius=r * S, fill=255)
    img.paste(grad, (0, 0), mask)
    return img


def save(img, name):
    img = img.resize((img.width // S, img.height // S), Image.LANCZOS)
    img.save(os.path.join(OUT, name))
    print("wrote", name, img.size)


def shadow(w, h, box, r, blur=6, alpha=90, dy=4):
    sh = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(sh)
    b = [box[0], box[1] + dy, box[2], box[3] + dy]
    rr(d, b, r, fill=(40, 22, 12, alpha))
    return sh.filter(ImageFilter.GaussianBlur(blur * S))


def panel():
    w, h = 200, 200
    img = shadow(w, h, (10, 10, w - 10, h - 10), 40, 7, 110, 6)
    d = ImageDraw.Draw(img)
    wood_dark = (0.29, 0.17, 0.1)
    wood = (0.47, 0.29, 0.17)
    # wood frame with a lighter top edge
    rr(d, (10, 10, w - 10, h - 10), 40, fill=rgb(wood_dark))
    img.alpha_composite(vgrad(w, h, mix(wood, (1, 1, 1), 0.12), wood, 37, 13))
    d = ImageDraw.Draw(img)
    # brass inner line
    rr(d, (22, 22, w - 22, h - 22), 30, outline=rgb((0.88, 0.7, 0.38)), width=3)
    # parchment
    img.alpha_composite(vgrad(w, h, (0.99, 0.96, 0.89), (0.95, 0.88, 0.75), 26, 26))
    d = ImageDraw.Draw(img)
    rr(d, (26, 26, w - 26, h - 26), 26, outline=rgb((0.78, 0.62, 0.42), 120), width=2)
    save(img, "panel.png")


def card(name, face_top, face_bot, border, lip):
    w, h = 120, 120
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rr(d, (4, 6, w - 4, h - 2), 22, fill=rgb(lip))
    img.alpha_composite(vgrad(w, h - 6, face_top, face_bot, 22, 4).crop((0, 0, w * S, (h - 6) * S)).resize((w * S, (h - 6) * S)), (0, 0))
    d = ImageDraw.Draw(img)
    rr(d, (4, 4, w - 4, h - 8), 22, outline=rgb(border), width=3)
    save(img, name)


def button(name, base, pressed=False):
    w, h = 140, 120
    lip_h = 4 if pressed else 11
    top_off = 7 if pressed else 0
    outline = (0.2, 0.12, 0.07)
    lip = mix(base, (0, 0, 0), 0.38)
    img = shadow(w, h, (8, 8 + top_off, w - 8, h - 6), 30, 3, 70, 3)
    d = ImageDraw.Draw(img)
    rr(d, (8, 8 + top_off, w - 8, h - 6), 30, fill=rgb(outline))
    rr(d, (12, 12 + top_off, w - 12, h - 10), 26, fill=rgb(lip))
    face = vgrad(w, h, mix(base, (1, 1, 1), 0.28), mix(base, (0, 0, 0), 0.05), 26, 0)
    mask = Image.new("L", (w * S, h * S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([12 * S, (12 + top_off) * S, (w - 12) * S, (h - 10 - lip_h) * S], radius=26 * S, fill=255)
    img.paste(face, (0, 0), mask)
    d = ImageDraw.Draw(img)
    # glossy top band
    gloss = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    gd = ImageDraw.Draw(gloss)
    gd.rounded_rectangle([20 * S, (17 + top_off) * S, (w - 20) * S, (44 + top_off) * S], radius=14 * S, fill=(255, 255, 255, 70))
    img.alpha_composite(gloss)
    save(img, name)


def bar():
    w, h = 160, 80
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rr(d, (4, 6, w - 4, h - 4), 34, fill=rgb((0.12, 0.07, 0.04), 110))
    rr(d, (4, 4, w - 4, h - 8), 34, fill=rgb((0.2, 0.12, 0.07), 225))
    rr(d, (4, 4, w - 4, h - 8), 34, outline=rgb((0.86, 0.68, 0.36)), width=3)
    rr(d, (10, 10, w - 10, 30), 14, fill=(255, 255, 255, 22))
    save(img, "bar.png")


def ribbon():
    w, h = 560, 130
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    red = (0.76, 0.3, 0.22)
    red_dk = (0.5, 0.17, 0.12)
    out = (0.24, 0.1, 0.07)
    # tails
    for sx in (1, -1):
        x0 = 6 if sx == 1 else w - 6
        pts = [(x0, 36), (x0 + sx * 78, 36), (x0 + sx * 78, 112), (x0, 112), (x0 + sx * 26, 74)]
        d.polygon([(x * S, y * S) for x, y in pts], fill=rgb(out))
        pts2 = [(x0 + sx * 5, 42), (x0 + sx * 74, 42), (x0 + sx * 74, 106), (x0 + sx * 5, 106), (x0 + sx * 30, 74)]
        d.polygon([(x * S, y * S) for x, y in pts2], fill=rgb(red_dk))
    # main band
    rr(d, (52, 10, w - 52, 104), 16, fill=rgb(out))
    band = vgrad(w, h, mix(red, (1, 1, 1), 0.18), mix(red, (0, 0, 0), 0.1), 12, 0)
    mask = Image.new("L", (w * S, h * S), 0)
    ImageDraw.Draw(mask).rounded_rectangle([57 * S, 15 * S, (w - 57) * S, 99 * S], radius=12 * S, fill=255)
    img.paste(band, (0, 0), mask)
    d = ImageDraw.Draw(img)
    rr(d, (64, 22, w - 64, 92), 9, outline=rgb((0.94, 0.72, 0.4), 200), width=2)
    save(img, "ribbon.png")


def tab(name, top, bot):
    w, h = 120, 90
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rr(d, (4, 4, w - 4, h - 2), 22, fill=rgb((0.22, 0.13, 0.08)))
    img.alpha_composite(vgrad(w, h, top, bot, 19, 8))
    save(img, name)


def track(name, col, alpha=255):
    w, h = 80, 40
    img = Image.new("RGBA", (w * S, h * S), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    rr(d, (2, 2, w - 2, h - 2), 18, fill=rgb((0.18, 0.1, 0.06), alpha))
    if col:
        img.alpha_composite(vgrad(w, h, mix(col, (1, 1, 1), 0.3), col, 14, 6))
    save(img, name)


if __name__ == "__main__":
    os.makedirs(OUT, exist_ok=True)
    panel()
    card("card.png", (1.0, 0.98, 0.93), (0.98, 0.93, 0.83), (0.8, 0.66, 0.46), (0.74, 0.6, 0.42))
    card("card_dark.png", (0.36, 0.23, 0.15), (0.3, 0.19, 0.12), (0.2, 0.12, 0.07), (0.16, 0.09, 0.05))
    for n, c in [("green", (0.44, 0.7, 0.26)), ("gold", (0.98, 0.72, 0.22)), ("red", (0.84, 0.34, 0.25)),
                 ("blue", (0.28, 0.54, 0.78)), ("wood", (0.56, 0.36, 0.22)), ("cream", (0.97, 0.9, 0.76)), ("grey", (0.6, 0.58, 0.56))]:
        button("btn_%s.png" % n, c)
        button("btn_%s_down.png" % n, c, True)
    bar()
    ribbon()
    tab("tab_on.png", (0.98, 0.76, 0.3), (0.86, 0.58, 0.18))
    tab("tab_off.png", (0.6, 0.42, 0.28), (0.48, 0.32, 0.2))
    track("track.png", None, 200)
    track("fill_gold.png", (0.98, 0.74, 0.24))
    track("fill_green.png", (0.48, 0.76, 0.3))
