#!/usr/bin/env python3
"""Generate Token Empire UI icons with the OpenAI Images API.

Usage:
    python3 tools/gen_icons.py                 # generate everything missing
    python3 tools/gen_icons.py cookie coin     # only these names (missing only)
    python3 tools/gen_icons.py --force cookie  # regenerate these names
    python3 tools/gen_icons.py --post-only     # re-run post-processing on existing sources
    python3 tools/gen_icons.py --contact       # rebuild the contact sheet only

Reads the API key from env var OPENAI_APIKEY (never printed).
Raw 1024px sources -> tools/icon_src/<name>.png (gitignored)
Processed 256px    -> assets/icons/<name>.png
Also: assets/app_icon.png (1024 opaque) and assets/emblem.png (512 transparent).

Models: transparent icons use gpt-image-1.5 (gpt-image-2 has no transparent
background support); the opaque app icon uses gpt-image-2.

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
MODELS_TRANSPARENT = ["gpt-image-1.5", "gpt-image-1"]
MODELS_OPAQUE = ["gpt-image-2", "gpt-image-1.5"]
CA_BUNDLE = "/root/.ccr/ca-bundle.crt"

ICON_SIZE = 256
EMBLEM_SIZE = 512
MARGIN = 0.06
WORKERS = 4

STYLE = (
    "single centered object, refined minimalist 3D render, soft matte clay / ceramic material "
    "with subtle real material hints (brushed aluminium, frosted glass, white plastic, graphite, "
    "a little walnut), clean modern tech palette (warm white, light grey, graphite, teal, soft "
    "cyan glow accents, small touches of amber and brass), soft studio light, emissive parts "
    "glow gently, calm premium aesthetic like a high-end tech product render or Monument Valley, "
    "clean silhouette, NO outlines, NO cartoon faces or eyes, NO glossy candy look, NO text, "
    "transparent background. "
    "Consistent icon-set framing: three-quarter view from slightly above, the object fills "
    "about 80% of the square frame, soft key light from the upper left, isolated object "
    "with no floor, no ground plane, no cast shadow on the ground, no backdrop, no letters, "
    "no numbers, no logos"
)

ICONS = [
    # ---- resources
    ("power", "a chunky dark graphite battery cell with a glowing green charge window and brass terminals"),
    ("data", "a translucent glowing cyan data cube sitting on a small dark base, thin lines of light inside it"),
    ("coolant", "a blue plastic coolant jerrycan with a white cap and a white band with a simple snowflake shape"),
    ("silicon", "a polished grey silicon crystal ingot (a boule) lying on a small walnut cradle, one thin shiny wafer disc leaning beside it"),
    ("copper", "three bright copper ingots stacked, with a coil of copper wire beside them"),
    ("code", "a slim dark rounded slab like a code editor window, with colourful horizontal bars of different lengths like lines of code (no letters)"),
    ("labels", "a small stack of white index cards with coloured tab tags and a green check mark shape on top"),
    ("feedback", "two small speech bubbles: a white one with a pink thumbs-up shape and a pink one with a gold star"),
    ("rare", "a small wooden crate filled with glittering purple, teal and pink crystals"),
    ("papers", "a neat stack of white research papers with a softly glowing warm light bulb resting on top"),
    ("fiber", "a spool of glowing pink fibre-optic cable with dark grey flanges"),
    ("experts", "a purple leather-bound book with gold page edges and a black graduation mortarboard resting on it"),
    ("gpu", "a modern graphics card with a black shroud, two round fans and a green circuit board edge with a thin glowing green strip"),
    ("dataset", "a classic database symbol: three stacked rounded blue discs with softly glowing cyan rims"),
    ("finetune", "an orange cartridge module with a small dark dial knob and a row of gold contacts"),
    ("hbm", "a blue memory module stick with black chips and a row of gold pins"),
    ("reward", "a golden five-point star trophy on a small dark plinth"),
    ("synth", "a glowing violet cube held inside a brushed steel cage frame"),
    # ---- products
    ("token", "one glowing coin token: a hexagonal teal coin with a softly glowing rim and a small bright dot in the centre"),
    ("batch", "a slim light-grey hard carry case with a glowing cyan seam and a small coin token on top"),
    ("agent", "a small white cube-shaped robot parcel with a dark face screen showing two glowing cyan eyes and a short antenna with a glowing tip"),
    ("tk_pico", "one small round mint-green coin token with a softly glowing rim and a single white dot in the centre"),
    ("tk_mini", "one round sky-blue coin token with a glowing rim and three white dots in a row"),
    ("tk_chat7", "one round blue coin token with a glowing rim and a white speech bubble shape"),
    ("tk_chat13", "one hexagonal indigo coin token with a glowing rim and a white speech bubble shape with three dots"),
    ("tk_wiki13", "one hexagonal ivory coin token with a small open blue book on its face"),
    ("tk_code13", "one rounded square violet coin token with white curly code brackets on its face"),
    ("tk_tool30", "one hexagonal amber coin token with a white gear on its face"),
    ("tk_vision70", "one round teal coin token with a white eye shape on its face"),
    ("tk_assist70", "one hexagonal soft orange coin token with a white five-point star on its face"),
    ("tk_code70", "one rounded square deep indigo coin token with white code brackets and a slash on its face"),
    ("tk_align70", "one round rose-pink coin token with a white heart on its face"),
    ("tk_long120", "one wide rounded rectangular navy coin token with white bars like a sound wave on its face"),
    ("tk_reason200", "one hexagonal lavender coin token with three white ascending steps on its face"),
    ("tk_sage400", "one round golden coin token with a small medal and star on its face"),
    ("tk_omni400", "one hexagonal magenta coin token with a white prism splitting a tiny rainbow on its face"),
    ("tk_moe", "one rounded square deep purple coin token with three small white cubes on its face"),
    ("tk_frontier", "one eight-point star-shaped ivory coin token with a small brass crown and a glowing golden rim"),
    # ---- sources
    ("src_power", "a small solar farm: a few dark blue solar panels on stands on a light gravel pad"),
    ("src_data", "a white web crawler station: a small satellite dish on a white pedestal with blinking lights and a tiny six-legged crawler robot beside it"),
    ("src_coolant", "a small white hyperboloid cooling tower with a blue pipe ring and a soft wisp of steam"),
    ("src_silicon", "a silicon crystal puller furnace: a white cylinder with a glowing orange window and a tall steel rod above it"),
    ("src_copper", "a small copper mine: a grey rocky ore heap with bright copper veins, a pickaxe stuck in it and a little ore cart"),
    ("src_code", "a developer desk with a monitor glowing with purple lines of code, a keyboard and a mug"),
    ("src_labels", "a standing table with a tablet and small stacks of coloured label cards"),
    ("src_feedback", "a white rating kiosk with a dark screen and a green thumbs-up button and a red thumbs-down button"),
    ("src_rare", "a cluster of glowing purple, pink and teal rare-earth crystals growing from a grey rock"),
    ("src_papers", "a whiteboard on a stand covered in coloured equation scribbles (no letters), with a glowing light bulb beside it"),
    ("src_fiber", "a fibre hub: a steel A-frame holding a glowing pink fibre-optic cable spool"),
    ("src_experts", "a cosy expert corner: a purple armchair, a side table with a warm lamp and a small bookshelf"),
    # ---- compute + labs
    ("server", "a compact AI inference server: a glass request tube on a dark rack with small module towers above it and a big glowing GPU core block at one end"),
    ("fab", "a small white cleanroom chip fab machine with a round window showing a glowing silicon wafer"),
    ("refinery", "three glass distillation columns full of glowing blue data liquid with steel caps and connecting pipes"),
    ("tune_lab", "a sloped tuning console with sliders and a big dial, and a small screen with orange bar charts"),
    ("hbm_works", "a stacking press machine with a stack of black and blue memory dies under its platen"),
    ("rlhf_gym", "an orange robot arm on a pedestal over a green training mat with a glowing gold star"),
    ("synth_lab", "a glowing violet reactor sphere held in a steel frame with a brass ring around it"),
    # ---- storage + packing
    ("depot", "a modern supply depot shelf unit with crates, a blue coolant can and a battery cell"),
    ("cache", "a dark storage rack of glowing storage blades with a few coin tokens on a shelf"),
    ("batcher", "a white sorter machine feeding a short roller conveyor carrying a light grey case"),
    ("agent_studio", "an assembly table with small white cube robots and an overhead robot arm"),
    # ---- sales
    ("van", "a sleek white electric delivery van with a teal stripe and a small roof antenna (side three-quarter view)"),
    ("cafe", "a small modern café front with a glass window showing glowing chat screens and a speech-bubble sign above"),
    ("desk", "an enterprise reception desk in front of a big dark screen showing contract cards"),
    ("hyperloop", "a white hyperloop pod capsule on a glowing maglev guideway entering a round tube portal"),
    ("droneport", "a large white quadcopter cargo drone with a cargo basket, hovering over a round landing pad"),
    # ---- campus
    ("builder", "a yellow construction hard hat resting on a claw hammer and a small rolled blueprint"),
    ("dorm", "a small modern modular house with white walls, wood cladding on one end and solar panels on a flat roof"),
    ("mega", "a futuristic AI megacluster: long white halls with four cooling towers and a glowing cyan sphere core on top inside a brass ring"),
    # ---- decor
    ("planter", "a white square planter box with green plants and small flowers, a teal rim"),
    ("tree", "a small round sage-green tree with a walnut trunk in a round concrete ring"),
    ("hedge", "a neatly trimmed box hedge block in sage green"),
    ("lamp", "a sleek modern smart street lamp with a slim graphite pole and a cool white LED light bar"),
    ("substation", "a small electrical substation transformer with copper-orange insulators and a yellow warning sign"),
    ("bench", "a walnut and graphite park bench"),
    ("bikes", "a bike rack with three colourful city bikes"),
    ("flag", "a tall white flagpole with a teal flag bearing a round coin emblem"),
    ("robot", "a friendly small white robot statue standing on a plinth, with a dark face screen with two cyan eyes"),
    ("battery", "a battery bank of three white cabinets with green charge lights"),
    ("foodtruck", "a cheerful orange food truck with an open serving hatch and a white awning"),
    ("coffee", "a dark brown coffee cart with an espresso machine and a big coffee cup sign with steam"),
    ("turbine", "a slim white wind turbine with three blades"),
    ("gpu_statue", "a golden graphics card statue standing on a white plinth"),
    # ---- staff
    ("courier", "a navy blue courier cap resting on a steel hand truck carrying a light grey case"),
    ("tech", "a white safety helmet with a blue stripe resting on an orange hi-vis vest with a wrench"),
    ("engineer", "a neatly folded purple hoodie with black over-ear headphones resting on it"),
    ("hire", "a white staff ID badge on a teal lanyard with a bold plus sign shape on the badge"),
    ("worker", "a white staff ID badge on a teal lanyard"),
    # ---- ui
    ("coin", "a thick matte gold coin with a subtle embossed hexagon emblem"),
    ("cash", "a neat stack of muted green banknotes with a plain paper band"),
    ("gem", "a single glowing faceted cyan spark crystal, cut like a classic brilliant gem, with a soft inner light"),
    ("star", "a matte brass eight-point star medal"),
    ("trophy", "a matte brass trophy cup"),
    ("lock", "a matte brushed aluminium padlock"),
    ("gear", "a matte brushed steel cog"),
    ("clock", "a minimal brushed aluminium stopwatch"),
    ("boost", "a glowing cyan lightning bolt"),
    ("speed", "a sleek white electric scooter with three short speed lines behind it"),
    ("price", "a white price tag with a teal string and a small gold coin"),
    ("recipe", "a small glowing neural network diagram: white circles connected by thin cyan lines, on a dark rounded slab"),
    ("research", "a brass microscope beside a glowing tablet showing a rising chart"),
    ("hammer", "a classic wooden-handled claw hammer crossed with a small steel ruler"),
    ("land", "a folded blueprint map of land plots with a teal map pin"),
    ("move", "four teal arrows pointing outward in a cross shape (move symbol)"),
    ("rotate", "a curved teal arrow forming a three-quarter circle (rotate symbol)"),
    ("storage", "a light grey shelving unit with crates and a battery cell"),
    ("bay", "a single white server module tower with a teal band and a glowing light column"),
    ("deliver", "a light grey parcel case with a glowing teal seam and a small brass bell"),
]

APP_ICON_PROMPT = (
    "premium mobile app icon for an AI tycoon game called Token Empire: one glowing hexagonal "
    "token coin with a soft cyan rim and a bright core, matte stylized-realistic 3D, centered, on a "
    "deep midnight-navy background with a very subtle thin brass circuit ring around it, soft studio "
    "light, elegant and minimal, no text, no letters, no words. Full-bleed square artwork filling the "
    "whole canvas edge to edge, square corners, no rounded corners, no border, no frame"
)

EMBLEM_PROMPT = (
    "an elegant emblem: a glowing hexagonal token coin with a cyan rim inside a thin brass circuit "
    "laurel ring, matte refined 3D, minimal, no text, no letters, transparent background, isolated, "
    "front view, no floor, no backdrop, no cast shadow"
)

SPECIAL = {
    # name: (prompt, size, transparent, out_path)
    "app_icon": (APP_ICON_PROMPT, "1024x1024", False, os.path.join(ASSET_DIR, "app_icon.png")),
    "emblem": (EMBLEM_PROMPT, "1024x1024", True, os.path.join(ASSET_DIR, "emblem.png")),
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
    for model in (MODELS_TRANSPARENT if transparent else MODELS_OPAQUE):
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


def postprocess_emblem():
    im = Image.open(os.path.join(SRC_DIR, "emblem.png")).convert("RGBA")
    if is_opaque_bg(im):
        log("  [emblem] WARNING: source has opaque background, flood-filling it out")
        im = remove_flat_background(im)
    im = trim_and_square(clean_alpha(im), margin=0.04)
    im = im.resize((EMBLEM_SIZE, EMBLEM_SIZE), Image.LANCZOS)
    clean_alpha(im).save(SPECIAL["emblem"][3], optimize=True)


def postprocess_app_icon():
    im = Image.open(os.path.join(SRC_DIR, "app_icon.png")).convert("RGB")
    if im.size != (1024, 1024):
        im = im.resize((1024, 1024), Image.LANCZOS)
    im.save(SPECIAL["app_icon"][3], optimize=True)


def postprocess(name):
    if name == "emblem":
        postprocess_emblem()
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


def contact_sheet(path=os.path.join(SRC_DIR, "contact.png"), cols=8, cell=200, bg=(48, 48, 50)):
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
    ap.add_argument("names", nargs="*", help="subset of icon names (also app_icon, emblem)")
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
