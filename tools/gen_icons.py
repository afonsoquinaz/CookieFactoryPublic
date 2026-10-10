#!/usr/bin/env python3
"""Generate Cookie Empire UI icons with the OpenAI Images API.

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
The old childish "Cookie Factory" sources live in tools/icon_src/old_childish/.

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
    "single centered object, refined minimalist 3D render, matte ceramic / clay material "
    "with subtle real material hints (brushed steel, wood grain, linen), muted sophisticated "
    "palette (warm cream, sage green, terracotta, walnut brown, chocolate, brushed steel, "
    "soft brass accents), soft natural studio light with gentle shadow on the object only, "
    "calm premium aesthetic like a high-end artisan bakery brand or Monument Valley, clean "
    "silhouette, NO outlines, NO cartoon faces or eyes, NO glossy candy look, NO text, "
    "transparent background. "
    "Consistent icon-set framing: three-quarter view from slightly above, the object fills "
    "about 80% of the square frame, soft key light from the upper left, isolated object "
    "with no floor, no ground plane, no cast shadow on the ground, no backdrop, no letters, "
    "no numbers, no logos"
)

ICONS = [
    ("wheat", "a tied sheaf of ripe golden wheat with a linen band; the wheat ears are warm golden-amber (not white), with fine awns, golden straw stalks"),
    ("sugar", "three cut sugar cane stalks bundled with twine; the stalks are clearly sugar cane: long, slender, segmented with visible ring-shaped nodes like bamboo, muted sage-green and straw-yellow with a few narrow leaves at the top, pale fibrous cut ends"),
    ("cocoa", "a ripe ochre-terracotta cocoa pod, one half cut open showing pale beans"),
    ("egg", "three brown and cream eggs in a small woven nest"),
    ("milk", "a simple glass milk bottle with a cream paper cap"),
    ("cookie", "one perfect golden chocolate-chip cookie, slightly realistic, matte"),
    ("dough", "a ball of pale cookie dough with a few chocolate chips"),
    ("coin", "a thick matte gold coin with a subtle embossed cookie emblem"),
    ("cash", "a neat stack of muted sage-green banknotes with a plain paper band"),
    ("gem", "a single faceted gemstone in muted rose quartz, cut like a classic brilliant, matte satin finish"),
    ("farmer", "a woven straw hat resting on a small wooden-handled hoe (object only, no person)"),
    ("gatherer", "a wicker harvest basket with a linen cloth"),
    ("feeder", "a brushed steel ingredient scoop with flour"),
    ("collector", "a dark steel baking tray with three cookies and a folded linen cloth"),
    ("loader", "a dark steel hand truck (dolly) carrying a kraft cardboard box"),
    ("worker", "a folded sage-green work apron with a brass buckle"),
    ("hire", 'a plain canvas apron hanging on a wooden peg, with a prominent round brass medallion tag pinned on the apron chest, the tag about a third of the apron width, with a bold raised plus-sign symbol (a simple cross shape) clearly visible on it'),
    ("speed", "a minimal plain cream leather running shoe with no logo and no markings on its side, with three short parallel brass speed lines floating just behind the heel, separate from the shoe, suggesting fast motion; the shoe is angled forward as if mid-stride"),
    ("backpack", "two stacked kraft cardboard boxes with twine"),
    ("truck", "a sleek cream delivery van (side 3/4 view), terracotta stripe"),
    ("oven", "a terracotta brick dome bread oven with dark iron door and warm glow"),
    ("conveyor", "a short dark steel conveyor segment with a glass cover and a cookie"),
    ("hopper", "a brushed steel funnel silo on dark steel legs"),
    ("storage", "a walnut wood shelf with glass jars and linen sacks"),
    ("star", "a matte brass eight-point star medal"),
    ("lock", "a matte brass padlock"),
    ("gear", "a matte brushed steel cog"),
    ("recipe", "an open linen-bound recipe book with a cookie beside it"),
    ("price", "a kraft paper price tag with twine and a small gold coin"),
    ("farm", "a tiny square field of golden wheat with a low dry-stone wall"),
    ("factory", "a small elegant brick bakery building with a chimney"),
    ("trophy", "a matte brass trophy cup"),
    ("clock", "a minimal brass pocket watch"),
    ("chicken", "a calm white hen (stylized, no cartoon eyes)"),
    ("cow", "a calm black-and-white dairy cow head (stylized, dignified)"),
    ("boost", "a brass lightning bolt"),
    ("shop", "a small striped canvas market awning stall"),
    # ---- v3: new ingredients
    ("oats", "a small linen sack overflowing with rolled oat flakes, a few oat stalks beside it"),
    ("berry", "three ripe red strawberries with green leafy tops in a tiny woven punnet"),
    ("hazelnut", "a small cluster of brown hazelnuts, one cracked open, with a green leafy husk"),
    ("honey", "a squat glass jar of golden honey with a wooden honey dipper resting across it"),
    ("vanilla", "a bundle of dark vanilla pods tied with twine beside a pale cream orchid flower"),
    ("cinnamon", "a small bundle of rolled cinnamon sticks tied with twine and a star anise"),
    ("orange", "a ripe orange with a glossy green leaf and one cut half showing segments"),
    ("butter", "a pale yellow block of butter on a small walnut board with a butter knife"),
    ("chocolate", "a thick bar of dark chocolate with a few squares broken off"),
    ("jam", "a small glass jar of red strawberry jam with a linen cloth lid and twine"),
    ("caramel", "a few glossy amber caramel squares stacked, with a drizzle of caramel"),
    ("praline", "a few glossy chocolate hazelnut praline bonbons in paper cups"),
    ("candied", "strips of glossy candied orange peel half dipped in dark chocolate on parchment"),
    # ---- v3: packaging
    ("box", "a closed kraft cardboard cookie box with a round cookie sticker seal and twine"),
    ("gift", "an elegant cream gift box with a terracotta satin ribbon and bow"),
    # ---- v3: buildings and machines
    ("mixer", "a large brushed steel stand mixer bowl on a cream machine base with a dough hook"),
    ("tube", "a short square glass production tube section on a dark steel frame, empty"),
    ("churn", "an old-fashioned wooden butter churn with brass bands and a plunger"),
    ("chocolatier", "a copper chocolate melting pot with a wooden paddle and dark chocolate inside"),
    ("kettle", "a large copper jam kettle on a small iron stand with red jam inside"),
    ("caramel_pot", "a heavy copper saucepan of bubbling amber caramel with a wooden spoon"),
    ("roaster", "a cast iron drum nut roaster with a crank handle and hazelnuts"),
    ("candy", "a marble candy table with a small copper pot and candied orange strips"),
    ("packer", "a compact cream cookie-box packing machine with a small conveyor and a kraft box"),
    ("wrapper", "a gift wrapping station: a ribbon spool on a small walnut stand with a gift box"),
    ("rack", "a tall walnut bakery cooling rack with trays of cookies"),
    ("pantry", "a walnut pantry cupboard with open doors showing jars and linen sacks"),
    ("train", "a small elegant cream and sage steam locomotive (side 3/4 view)"),
    ("airship", "a small elegant cream airship blimp with a walnut gondola and brass propeller"),
    ("cabin", "a small timber staff cabin with a terracotta roof and a round window"),
    ("well", "a small stone water well with a wooden roof and a bucket"),
    ("fountain", "a small round stone fountain with a gentle water jet"),
    ("statue", "a brass statue of a giant cookie on a stone plinth"),
    ("flowers", "a small raised wooden flower bed with lavender and cream daisies"),
    ("lamp", "an elegant black iron street lamp with a warm glowing lantern"),
    ("palace", "a grand elegant palace made of cookies and cream stone with brass domes"),
    ("board", "a wooden order notice board on two posts with pinned paper notes"),
    ("land", "a folded parchment land deed map with a brass pin"),
    ("research", "a brass microscope beside an open notebook and a cookie"),
    ("hammer", "a classic wooden-handled claw hammer crossed with a small brass ruler"),
    # ---- v4: town
    ("hall", "a charming small town hall building: cream timber-framed walls, a terracotta tiled gable roof with a small clock tower and a brass weathervane, an arched wooden double door with a striped awning, a round cookie emblem sign over the door"),
    ("builder", "a yellow construction hard hat resting on a wooden-handled claw hammer and a small rolled blueprint"),
    ("bakery", "a small bakery production line: a cream stand mixer on the left, a short square glass tube with a dough ball in the middle, a terracotta brick dome oven with a warm glow on the right, on a chequered tile floor"),
    ("porter", "a sage-green wooden hand cart with two big wheels carrying a kraft cookie box and a small linen flour sack"),
    ("road", "a short curved section of warm grey cobblestone path with neat stones"),
    ("move", "four brass arrows pointing outward in a cross shape (move symbol)"),
    ("rotate", "a curved brass arrow forming a three-quarter circle (rotate symbol)"),
    ("tree", "a small round sage-green tree with a walnut trunk"),
    ("hedge", "a neatly trimmed box hedge block in sage green"),
    ("bench", "a walnut and black iron park bench"),
    ("chef", "a white chef toque hat resting next to a steel whisk"),
    ("beehive", "a cream wooden beehive box with a small brass bee on top"),
    ("greenhouse", "a small glass greenhouse with a walnut frame and green plants inside"),
    ("market", "a small elegant cookie shop front with a terracotta awning and a display window"),
    ("deliver", "a kraft parcel with twine and a small brass bell"),
    ("pond", "a small round garden pond with lily pads, a few reeds and a stone rim"),
    ("gazebo", "a small elegant white wooden garden gazebo with a terracotta roof"),
    ("topiary", "a neat round topiary bush in a terracotta pot"),
    ("banner", "a tall cream and terracotta fabric banner on a wooden pole with a small cookie emblem"),
    ("picnic", "a small walnut picnic table with a checked cloth and a plate of cookies"),
    ("windmill", "a small cream stone windmill with wooden sails and a terracotta cap"),
    # ---- v3: cookies (one per recipe)
    ("ck_shortbread", "one pale golden rectangular shortbread biscuit with fork pricks"),
    ("ck_sugar", "one round sugar cookie sparkling with coarse sugar crystals"),
    ("ck_cocoa", "one round cocoa crinkle cookie, dark brown with white powdered sugar cracks"),
    ("ck_milk", "one round pale milk biscuit with a stamped flower pattern"),
    ("ck_butter", "one Danish butter cookie ring with a ridged piped swirl"),
    ("ck_choc", "one golden chocolate chip cookie with big chocolate chunks"),
    ("ck_oat", "one rustic oatmeal cookie with visible oat flakes"),
    ("ck_double", "one dark double chocolate cookie with white and dark chunks"),
    ("ck_jam", "one round thumbprint cookie with a glossy red jam centre"),
    ("ck_honey", "one honey oat cookie with a glossy golden honey glaze"),
    ("ck_hazel", "one cookie topped with chopped hazelnuts and a chocolate drizzle"),
    ("ck_caramel", "one thin caramel stroopwafel cookie with a waffle grid pattern"),
    ("ck_vanilla", "one round vanilla sable cookie with dark vanilla seed specks and a sugar rim"),
    ("ck_praline", "one cookie topped with a glossy chocolate praline swirl and a hazelnut"),
    ("ck_cinnamon", "one cinnamon swirl cookie with a spiral of cinnamon and white icing drizzle"),
    ("ck_florentine", "one lacy florentine cookie with candied orange and a chocolate underside"),
    ("ck_royal", "one luxurious royal cookie with ivory icing, gold leaf flecks and a tiny crown pattern"),
]

APP_ICON_PROMPT = (
    "premium mobile app icon for 'Cookie Empire': one perfect chocolate chip cookie, matte "
    "stylized-realistic 3D, centered, resting on a deep chocolate-brown background with a "
    "very subtle thin brass laurel ring around it, soft studio light, elegant and minimal, "
    "no text, no letters, no words. Full-bleed square artwork filling the whole canvas edge "
    "to edge, square corners, no rounded corners, no border, no frame"
)

EMBLEM_PROMPT = (
    "an elegant emblem: a perfect chocolate chip cookie inside a thin brass laurel wreath, "
    "matte refined 3D, minimal, no text, no letters, transparent background, isolated, "
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
