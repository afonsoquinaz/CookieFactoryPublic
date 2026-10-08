#!/usr/bin/env python3
"""Generate Cookie Factory UI icons with the OpenAI Images API.

Usage:
    python3 tools/gen_icons.py                 # generate everything missing
    python3 tools/gen_icons.py cookie gem      # only these names (missing only)
    python3 tools/gen_icons.py --force cookie  # regenerate these names
    python3 tools/gen_icons.py --post-only     # re-run post-processing on existing sources
    python3 tools/gen_icons.py --contact       # rebuild the contact sheet only

Reads the API key from env var OPENAI_APIKEY (never printed).
Raw 1024px sources -> tools/icon_src/<name>.png (gitignored)
Processed 256px    -> assets/icons/<name>.png
Also: assets/app_icon.png (1024 opaque) and assets/logo.png (transparent wordmark).

Dependencies: python3 stdlib + Pillow + numpy.
"""
import argparse
import base64
import concurrent.futures as cf
import json
import os
import ssl
import sys
import threading
import time
import urllib.error
import urllib.request

import numpy as np
from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC_DIR = os.path.join(ROOT, "tools", "icon_src")
ICON_DIR = os.path.join(ROOT, "assets", "icons")
ASSET_DIR = os.path.join(ROOT, "assets")
META_PATH = os.path.join(SRC_DIR, "meta.json")

API_URL = "https://api.openai.com/v1/images/generations"
MODELS = ["gpt-image-2", "gpt-image-1.5", "gpt-image-1"]
CA_BUNDLE = "/root/.ccr/ca-bundle.crt"

ICON_SIZE = 256
MARGIN = 0.06
WORKERS = 4

STYLE = (
    "single centered object, cute stylized 3D game icon, soft clay/plastic render, "
    "chunky rounded shapes, vibrant saturated colors, soft studio lighting with gentle "
    "glossy highlight, subtle dark warm-brown outline, no text, no letters, no numbers, "
    "no background, no ground shadow, no floor, transparent background, isolated object, "
    "Supercell-style mobile game UI icon"
)

CHAR_STYLE = (
    "same cute chibi mascot design: round peach-skinned face, big glossy dark eyes, "
    "rosy cheeks, small happy smile"
)

ICONS = [
    ("wheat", "a bundle of golden wheat stalks tied with a red ribbon"),
    ("sugar", "a small bundle of three fresh green-and-yellow segmented sugar cane stalks with long leaves, cut ends visible, tied with twine, with two white sugar cubes in front"),
    ("cocoa", "a ripe orange-brown cocoa pod, one half cut open showing creamy cocoa beans inside"),
    ("egg", "two cute fresh cream-white eggs sitting in a little golden straw nest"),
    ("milk", "a cute rounded glass milk bottle full of white milk with a blue cap"),
    ("cookie", "a perfect golden-brown chocolate-chip cookie with chunky dark chocolate chips"),
    ("dough", "a soft round ball of raw pale cookie dough studded with chocolate chips"),
    ("coin", "a shiny thick gold coin with a cookie emblem embossed on its face"),
    ("cash", "a small neat stack of green cash bills held by a paper band"),
    ("gem", "a pink candy-colored faceted gemstone"),
    ("farmer", f"head-and-shoulders portrait of a cute tiny character wearing a straw hat and a green shirt, holding a garden hoe; {CHAR_STYLE}"),
    ("gatherer", f"head-and-shoulders portrait of a cute tiny character wearing a blue cap with a woven basket on their back; {CHAR_STYLE}"),
    ("feeder", f"head-and-shoulders portrait of a cute tiny character wearing an orange hard hat, holding a big metal scoop; {CHAR_STYLE}"),
    ("collector", f"head-and-shoulders portrait of a cute tiny character wearing a white chef hat, holding a tray of cookies; {CHAR_STYLE}"),
    ("loader", f"a cute tiny character wearing a red cap pushing a hand truck carrying a cardboard box; {CHAR_STYLE}"),
    ("worker", f"a cute tiny generic factory worker character in purple overalls, waving hello; {CHAR_STYLE}"),
    ("hire", f"head-and-shoulders portrait of a cute tiny character with a round green badge with a white plus sign next to them (hiring); {CHAR_STYLE}"),
    ("speed", "a winged running sneaker with little white wings and speed swooshes"),
    ("backpack", "a chunky stacked pile of three wooden crates and cardboard boxes"),
    ("truck", "a cute rounded delivery truck, pastel red and cream, with a round cookie logo on the side, three-quarter view"),
    ("oven", "a cute rounded industrial cookie oven with a glowing orange window, metal body"),
    ("conveyor", "a short conveyor belt segment on rollers with a single cookie on it"),
    ("hopper", "a funnel-shaped metal ingredient hopper dropper standing on four legs"),
    ("storage", "a small wooden shelf with glass jars and burlap sacks on it"),
    ("star", "a chunky glossy golden star"),
    ("lock", "a chunky golden padlock"),
    ("gear", "a chunky rounded settings cog gear, light grey-blue"),
    ("recipe", "an open recipe book with a cookie and a chocolate drop on its pages"),
    ("price", "a paper price tag on a string with a gold coin attached"),
    ("farm", "a tiny farm plot island with a red barn and a green crop field"),
    ("factory", "a cute tiny cookie factory building with a chimney puffing a cookie-shaped cloud"),
    ("trophy", "a chunky golden trophy cup with two handles"),
    ("clock", "a chunky round orange alarm clock with two bells on top, a cream clock face with two dark clock hands and small tick marks"),
    ("chicken", "a cute round plump white chicken with a red comb"),
    ("cow", "a cute round black-and-white cow head with little horns and a pink nose"),
    ("boost", "a glowing yellow lightning bolt with a soft glow"),
    ("shop", "a little market shop stall with a red and white striped awning"),
]

APP_ICON_PROMPT = (
    "mobile app icon, a joyful giant chocolate chip cookie with a cute tiny factory chimney "
    "puffing steam behind it, warm cream and chocolate brown with a pop of pastel pink and "
    "mint background gradient, rounded chunky 3D clay style, Supercell-quality, no text, "
    "simple bold centered composition that reads clearly at small sizes: the big smiling "
    "cookie fills the center, the little factory chimney peeks out behind it at the upper "
    "right, soft smooth gradient background without scenery clutter, "
    "full-bleed square artwork filling the whole canvas edge to edge, square corners, "
    "no rounded corners, no border, no frame"
)

LOGO_PROMPT = (
    'game title wordmark logo that reads exactly "Cookie Factory" (two words: C-O-O-K-I-E '
    "F-A-C-T-O-R-Y), on two lines or one line, chunky bubbly 3D cartoon letters, chocolate "
    "brown letters with a thick cream-colored outline and glossy highlights, a small "
    'chocolate chip cookie replacing the first letter "o" in "Cookie", playful mobile game '
    "logo, Supercell-style, correct spelling, no other text, transparent background, isolated"
)

SPECIAL = {
    # name: (prompt, size, transparent, out_path)
    "app_icon": (APP_ICON_PROMPT, "1024x1024", False, os.path.join(ASSET_DIR, "app_icon.png")),
    "logo": (LOGO_PROMPT, "1536x1024", True, os.path.join(ASSET_DIR, "logo.png")),
}

_print_lock = threading.Lock()
_meta_lock = threading.Lock()
_no_transparent = set()  # models that rejected background=transparent


def log(*a):
    with _print_lock:
        print(*a, flush=True)


def _ssl_ctx():
    ctx = ssl.create_default_context()
    if os.path.exists(CA_BUNDLE):
        try:
            ctx.load_verify_locations(CA_BUNDLE)
        except Exception:
            pass
    return ctx


SSL_CTX = _ssl_ctx()


def load_meta():
    if os.path.exists(META_PATH):
        try:
            with open(META_PATH) as f:
                return json.load(f)
        except Exception:
            pass
    return {}


def save_meta_entry(name, entry):
    with _meta_lock:
        meta = load_meta()
        meta[name] = entry
        with open(META_PATH, "w") as f:
            json.dump(meta, f, indent=2, sort_keys=True)


class ApiError(Exception):
    def __init__(self, status, message):
        super().__init__(f"HTTP {status}: {message}")
        self.status = status
        self.message = message


def call_api(model, prompt, size, transparent, quality):
    key = os.environ.get("OPENAI_APIKEY") or os.environ.get("OPENAI_API_KEY")
    if not key:
        raise SystemExit("OPENAI_APIKEY is not set")
    body = {
        "model": model,
        "prompt": prompt,
        "size": size,
        "quality": quality,
        "output_format": "png",
        "n": 1,
    }
    body["background"] = "transparent" if transparent else "opaque"
    req = urllib.request.Request(
        API_URL,
        data=json.dumps(body).encode(),
        headers={"Authorization": "Bearer " + key, "Content-Type": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req, timeout=600, context=SSL_CTX) as r:
            j = json.loads(r.read())
    except urllib.error.HTTPError as e:
        try:
            msg = json.loads(e.read()).get("error", {}).get("message", "")
        except Exception:
            msg = str(e)
        raise ApiError(e.code, msg)
    return base64.b64decode(j["data"][0]["b64_json"])


def generate(name, prompt, size, transparent, quality):
    """Try models in order with retries; return (png_bytes, model)."""
    last = None
    for model in MODELS:
        if transparent and model in _no_transparent:
            continue
        for attempt in range(4):
            try:
                t0 = time.time()
                data = call_api(model, prompt, size, transparent, quality)
                log(f"  [{name}] {model} ok in {time.time() - t0:.0f}s")
                return data, model
            except ApiError as e:
                last = e
                msg = e.message.lower()
                if e.status == 400 and "transparent" in msg:
                    _no_transparent.add(model)
                    break  # next model
                if e.status in (400, 403, 404) and ("model" in msg or "size" in msg or "not supported" in msg or "invalid" in msg):
                    log(f"  [{name}] {model} rejected: {e.message[:160]}")
                    break  # next model
                if e.status == 400 and ("safety" in msg or "moderation" in msg):
                    log(f"  [{name}] {model} moderation: {e.message[:160]}")
                    break
                wait = 5 * (attempt + 1) * (3 if e.status == 429 else 1)
                log(f"  [{name}] {model} HTTP {e.status} ({e.message[:100]}), retry in {wait}s")
                time.sleep(wait)
            except Exception as e:  # network / timeout
                last = e
                wait = 5 * (attempt + 1)
                log(f"  [{name}] {model} error {type(e).__name__}: {str(e)[:100]}, retry in {wait}s")
                time.sleep(wait)
    raise RuntimeError(f"[{name}] all models failed: {last}")


# ---------------------------------------------------------------- image utils

def is_opaque_bg(im):
    """True if the image looks like it has an opaque background (corners opaque)."""
    a = np.asarray(im.convert("RGBA"))[:, :, 3]
    h, w = a.shape
    p = max(8, min(h, w) // 40)
    corners = [a[:p, :p], a[:p, -p:], a[-p:, :p], a[-p:, -p:]]
    opaque_corners = sum(1 for c in corners if c.mean() > 128)
    return opaque_corners >= 2


def remove_flat_background(im, tol=28):
    """Fallback: flood-fill from the border to remove a flat opaque background."""
    from collections import deque
    arr = np.asarray(im.convert("RGBA")).astype(np.int16)
    h, w = arr.shape[:2]
    rgb = arr[:, :, :3]
    border = np.concatenate([rgb[0], rgb[-1], rgb[:, 0], rgb[:, -1]])
    bg = np.median(border, axis=0)
    close = np.abs(rgb - bg).max(axis=2) <= tol
    mask = np.zeros((h, w), bool)
    dq = deque()
    for x in range(w):
        for y in (0, h - 1):
            if close[y, x] and not mask[y, x]:
                mask[y, x] = True
                dq.append((y, x))
    for y in range(h):
        for x in (0, w - 1):
            if close[y, x] and not mask[y, x]:
                mask[y, x] = True
                dq.append((y, x))
    while dq:
        y, x = dq.popleft()
        for ny, nx in ((y + 1, x), (y - 1, x), (y, x + 1), (y, x - 1)):
            if 0 <= ny < h and 0 <= nx < w and close[ny, nx] and not mask[ny, nx]:
                mask[ny, nx] = True
                dq.append((ny, nx))
    out = arr.astype(np.uint8).copy()
    out[mask, 3] = 0
    return Image.fromarray(out, "RGBA")


def clean_alpha(im):
    """Kill faint alpha noise and bleed edge colours into transparent pixels
    (prevents white/black halos when the texture is filtered or mipmapped)."""
    arr = np.asarray(im.convert("RGBA")).astype(np.float32)
    a = arr[:, :, 3]
    a[a < 10] = 0
    arr[:, :, 3] = a
    # alpha bleed: fill RGB of transparent pixels with average of nearby opaque ones
    rgb = arr[:, :, :3]
    known = a > 0
    filled_rgb = rgb * known[:, :, None]
    weight = known.astype(np.float32)
    for _ in range(6):
        if weight.min() > 0:
            break
        s = np.zeros_like(filled_rgb)
        c = np.zeros_like(weight)
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            s += np.roll(np.roll(filled_rgb * (weight > 0)[:, :, None], dy, 0), dx, 1)
            c += np.roll(np.roll((weight > 0).astype(np.float32), dy, 0), dx, 1)
        newly = (weight == 0) & (c > 0)
        filled_rgb[newly] = s[newly] / c[newly][:, None]
        weight[newly] = 1
    out = np.dstack([np.where(known[:, :, None], rgb, filled_rgb), a])
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGBA")


def trim_and_square(im, margin=MARGIN, square=True):
    a = np.asarray(im)[:, :, 3]
    ys, xs = np.where(a > 24)
    if len(xs) == 0:
        return im
    box = (xs.min(), ys.min(), xs.max() + 1, ys.max() + 1)
    im = im.crop(box)
    w, h = im.size
    if square:
        side = max(w, h)
        side_p = int(round(side / (1 - 2 * margin)))
        canvas = Image.new("RGBA", (side_p, side_p), (0, 0, 0, 0))
        canvas.paste(im, ((side_p - w) // 2, (side_p - h) // 2))
    else:
        m = int(round(max(w, h) * margin / 2))
        canvas = Image.new("RGBA", (w + 2 * m, h + 2 * m), (0, 0, 0, 0))
        canvas.paste(im, (m, m))
    return canvas


def postprocess_icon(name):
    src = os.path.join(SRC_DIR, name + ".png")
    im = Image.open(src).convert("RGBA")
    if is_opaque_bg(im):
        log(f"  [{name}] WARNING: source has opaque background, flood-filling it out")
        im = remove_flat_background(im)
    im = trim_and_square(clean_alpha(im))
    im = im.resize((ICON_SIZE, ICON_SIZE), Image.LANCZOS)  # Pillow premultiplies RGBA
    im = clean_alpha(im)
    im.save(os.path.join(ICON_DIR, name + ".png"), optimize=True)


def postprocess_logo():
    im = Image.open(os.path.join(SRC_DIR, "logo.png")).convert("RGBA")
    if is_opaque_bg(im):
        im = remove_flat_background(im)
    im = trim_and_square(clean_alpha(im), margin=0.04, square=False)
    if im.width > 1024:
        im = im.resize((1024, round(im.height * 1024 / im.width)), Image.LANCZOS)
    clean_alpha(im).save(SPECIAL["logo"][3], optimize=True)


def postprocess_app_icon():
    im = Image.open(os.path.join(SRC_DIR, "app_icon.png")).convert("RGB")
    if im.size != (1024, 1024):
        im = im.resize((1024, 1024), Image.LANCZOS)
    im.save(SPECIAL["app_icon"][3], optimize=True)


def postprocess(name):
    if name == "logo":
        postprocess_logo()
    elif name == "app_icon":
        postprocess_app_icon()
    else:
        postprocess_icon(name)


# ---------------------------------------------------------------- jobs

def job_spec(name):
    if name in SPECIAL:
        prompt, size, transparent, _ = SPECIAL[name]
        return prompt, size, transparent
    subj = dict(ICONS)[name]
    return f"{subj}. {STYLE}", "1024x1024", True


def run_job(name, quality, force):
    src = os.path.join(SRC_DIR, name + ".png")
    if os.path.exists(src) and not force:
        postprocess(name)
        return name, "skipped"
    prompt, size, transparent = job_spec(name)
    log(f"[{name}] generating ({size}, transparent={transparent})")
    tries = 2 if transparent else 1  # retry once if background came back opaque
    for t in range(tries):
        data, model = generate(name, prompt, size, transparent, quality)
        tmp = src + ".tmp"
        with open(tmp, "wb") as f:
            f.write(data)
        im = Image.open(tmp)
        if transparent and is_opaque_bg(im) and t < tries - 1:
            log(f"  [{name}] opaque background returned, retrying once")
            continue
        break
    os.replace(tmp, src)
    save_meta_entry(name, {"model": model, "prompt": prompt, "size": size,
                           "quality": quality, "time": time.strftime("%Y-%m-%d %H:%M:%S")})
    postprocess(name)
    return name, model


def contact_sheet(path=os.path.join(SRC_DIR, "contact.png"), cols=8, cell=200, bg=(128, 128, 128)):
    from PIL import ImageDraw
    names = [n for n, _ in ICONS if os.path.exists(os.path.join(ICON_DIR, n + ".png"))]
    rows = (len(names) + cols - 1) // cols
    label_h = 22
    sheet = Image.new("RGB", (cols * cell, rows * (cell + label_h)), bg)
    d = ImageDraw.Draw(sheet)
    for i, n in enumerate(names):
        im = Image.open(os.path.join(ICON_DIR, n + ".png")).convert("RGBA").resize((cell - 16, cell - 16), Image.LANCZOS)
        x, y = (i % cols) * cell, (i // cols) * (cell + label_h)
        sheet.paste(im, (x + 8, y + 8), im)
        d.text((x + 8, y + cell), n, fill=(255, 255, 255))
    sheet.save(path)
    return path


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*", help="subset of icon names (also app_icon, logo)")
    ap.add_argument("--force", action="store_true", help="regenerate even if source exists")
    ap.add_argument("--quality", default="high", choices=["low", "medium", "high"])
    ap.add_argument("--post-only", action="store_true")
    ap.add_argument("--contact", action="store_true", help="only rebuild contact sheet")
    ap.add_argument("--workers", type=int, default=WORKERS)
    args = ap.parse_args()

    os.makedirs(SRC_DIR, exist_ok=True)
    os.makedirs(ICON_DIR, exist_ok=True)

    all_names = [n for n, _ in ICONS] + list(SPECIAL)
    names = args.names or all_names
    bad = [n for n in names if n not in all_names]
    if bad:
        raise SystemExit(f"unknown names: {bad}")

    if args.contact:
        print(contact_sheet())
        return
    if args.post_only:
        for n in names:
            if os.path.exists(os.path.join(SRC_DIR, n + ".png")):
                postprocess(n)
        print(contact_sheet())
        return

    failed = []
    with cf.ThreadPoolExecutor(max_workers=args.workers) as ex:
        futs = {ex.submit(run_job, n, args.quality, args.force): n for n in names}
        for f in cf.as_completed(futs):
            n = futs[f]
            try:
                _, how = f.result()
                if how != "skipped":
                    log(f"[{n}] done ({how})")
            except Exception as e:
                failed.append(n)
                log(f"[{n}] FAILED: {e}")
    print("contact sheet:", contact_sheet())
    if failed:
        print("FAILED:", " ".join(failed))
        sys.exit(1)


if __name__ == "__main__":
    main()
