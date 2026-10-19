class_name SourceArt
## Source looks per upgrade tier (0..4), in the five eras of ArchKit:
##   0  a garage-startup lot: dirt, a scrappy timber fence patched with tin,
##      second-hand gear, plywood lean-tos, extension cords, string lights
##   1  a workshop yard: concrete, chain-link with barbed wire, shipping
##      containers, steel racks, yellow rails, floodlights
##   2  a campus: paving and grass, a white wall with a teal band, white
##      two-storey pavilions with glass, planters, logo signs
##   3  industrial: a steel-edged slab, palisade fencing, big steel-and-glass
##      halls, catwalks, pipe racks, transformers, blue LEDs
##   4  hyperscale: dark tiles with glowing seams, glass-and-brass fencing,
##      graphite towers with brass trim, glowing cores and a crown
## Every resource has its own place in each era (a solar field that ends as a
## heliostat tower, a crawler that ends as a glowing spire, a cooling yard
## that ends as a graphite hyperbolic tower...). The big pieces stand along
## the back fence and the back half of the side fences (the "wings"), above
## head height, or are the stations themselves; the plot between the
## stations stays clear for the technicians, the front yard is for Growth.
##
## bed / wall / extras are drawn in the plot's frame (centred on the plot,
## see SourceB) but laid out here in the building's frame (CZ shift).

const GATE := 1.3
const CZ := -0.9             # the plot's centre z (SourceB.PLOT)
const BACK := -2.8           # inside of the back fence
const BACK_F := -2.18        # front of the back strip (behind the stations)
const WING := 2.26           # inside x of the side wings
const WING_F := -0.95        # front end of the wings
const FENCE_X := 2.85
const FENCE_B := -2.85
const FENCE_F := 1.08
const WARM := Color(1.0, 0.82, 0.5)
const LED3 := Color(0.45, 0.75, 1.0)
const GRAPH := Color(0.17, 0.18, 0.21)
const GRAPH2 := Color(0.24, 0.25, 0.29)
## The glow of the hyperscale fins, one per resource (set by extras).
const FIN := {"power": Color(1.0, 0.82, 0.45), "data": Color(0.42, 0.9, 1.0), "coolant": Color(0.5, 0.8, 1.0),
	"silicon": Color(1.0, 0.62, 0.32), "copper": Color(1.0, 0.56, 0.36), "code": Color(0.7, 0.6, 1.0),
	"labels": Color(0.98, 0.88, 0.4), "feedback": Color(1.0, 0.6, 0.66), "rare": Color(0.8, 0.5, 1.0),
	"papers": Color(1.0, 0.9, 0.62), "fiber": Color(1.0, 0.62, 0.88), "experts": Color(0.72, 0.56, 1.0)}
static var _fin := WARM


## How many stations a source has at level l: three to start, one more
## every other level until the lot is full (the papers lot has big ones).
static func station_count(res: String, l: int) -> int:
	match res:
		"power": return clampi(3 + (l - 1) / 2, 3, 8)
		"papers": return clampi(2 + (l - 1) / 3, 2, 4)
	return clampi(3 + (l - 1) / 2, 3, 6)


## Where the stations stand (local to the lot's frame, like SourceB): one
## row of up to three, then two rows.
static func station_spots(res: String, l: int, w: float, d: float, cz: float) -> Array[Vector3]:
	var count := station_count(res, l)
	var cols := count if count <= 3 else (count + 1) / 2
	var rows := int(ceil(float(count) / cols))
	var area := Vector2(w - 1.0, d - 1.1)
	var out: Array[Vector3] = []
	for i in count:
		var cx: int = i % cols
		var r: int = i / cols
		var in_row := cols if r < rows - 1 else count - cols * (rows - 1)
		var x := -area.x * 0.5 + area.x * (cx + 0.5) / cols
		if in_row < cols:
			# a shorter last row sits centred
			x = -area.x * 0.5 + area.x * (cx + 0.5 + (cols - in_row) * 0.5) / cols
		var z := cz - area.y * 0.5 + area.y * (r + 0.5) / rows - 0.15
		out.append(Vector3(x, 0.07, z))
	return out


static func _office(res: String) -> bool:
	return res in ["code", "labels", "feedback", "experts", "papers"]


static func _mine(res: String) -> bool:
	return res in ["copper", "rare", "silicon"]


# ---------------------------------------------------------------- helpers

## A box spanning corners a..b.
static func bx(k: MeshKit, a: Vector3, b: Vector3, col: Color) -> void:
	k.box((b - a).abs(), col, MeshKit.at((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, (a.z + b.z) * 0.5))


## A box of size s at p turned yaw degrees.
static func bo(k: MeshKit, s: Vector3, col: Color, p: Vector3, yaw := 0.0, pitch := 0.0, roll := 0.0) -> void:
	k.box(s, col, MeshKit.xf(p, Vector3(pitch, yaw, roll)))


## A thin square bar from a to b (cables, braces, rails, cords).
static func ln(k: MeshKit, a: Vector3, b: Vector3, th: float, col: Color) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var up := Vector3.UP if absf(d.y / l) < 0.95 else Vector3.RIGHT
	k.box(Vector3(th, th, l), col, Transform3D(Basis.looking_at(d, up), (a + b) * 0.5))


static func _lit(c: Color, a := 0.45) -> Color:
	return Color(c.r, c.g, c.b, a)


static func _c(t: int, key: String) -> Color:
	return ArchKit.c(t, key)


## A polyline lying on the ground (extension cords, hoses).
static func cord(k: MeshKit, pts: Array, col: Color, th := 0.025) -> void:
	for i in pts.size() - 1:
		ln(k, pts[i], pts[i + 1], th, col)


## A string of glowing bulbs sagging from a to b.
static func bulbs(k: MeshKit, a: Vector3, b: Vector3, n := 7, col := WARM) -> void:
	var prev := a
	for i in n + 1:
		var f := float(i) / n
		var q := a.lerp(b, f) - Vector3(0, sin(f * PI) * 0.2, 0)
		ln(k, prev, q, 0.01, Color(0.15, 0.15, 0.16))
		if i > 0 and i < n:
			k.box(Vector3(0.05, 0.06, 0.05), _lit(col, 0.3), MeshKit.at(q.x, q.y - 0.04, q.z))
		prev = q


static func barrel(k: MeshKit, p: Vector3, col: Color, r := 0.14, h := 0.42) -> void:
	k.cyl(r, h, col, MeshKit.at(p.x, p.y, p.z), 8)
	for y in [0.25, 0.75]:
		k.cyl(r + 0.01, 0.03, col.darkened(0.2), MeshKit.at(p.x, p.y + h * y, p.z), 8, 0.0, -1.0, false)


static func crate(k: MeshKit, p: Vector3, s: Vector3, col: Color, yaw := 0.0) -> void:
	Stations._crate(k, p, s, col, yaw)


## A pile of crates and boxes.
static func crates(k: MeshKit, p: Vector3, n: int, seed := 0, col := Color(0.72, 0.56, 0.38)) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed * 131 + 7
	var y := 0.0
	for i in n:
		var s := Vector3(r.randf_range(0.26, 0.36), r.randf_range(0.2, 0.3), r.randf_range(0.24, 0.32))
		var o := Vector3(r.randf_range(-0.06, 0.06), y, r.randf_range(-0.05, 0.05)) if i % 3 != 0 else Vector3((i / 3) * 0.36, 0, 0)
		if i % 3 == 0:
			y = 0.0
			o.y = 0.0
		crate(k, p + o, s, col.darkened(r.randf_range(0.0, 0.15)), r.randf_range(-15, 15))
		y = o.y + s.y


## A wooden pallet.
static func pallet(k: MeshKit, p: Vector3, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	for j in 3:
		k.box(Vector3(0.6, 0.06, 0.08), Pal.WOOD_LIGHT.darkened(0.08), tf * MeshKit.at(0, 0.03, -0.22 + j * 0.22))
	for i in 5:
		k.box(Vector3(0.1, 0.025, 0.56), Pal.WOOD_LIGHT, tf * MeshKit.at(-0.25 + i * 0.125, 0.075, 0))


## A 10 ft shipping container (length along local x, doors at +x).
static func container(k: MeshKit, tf: Transform3D, len: float, col: Color, h := 0.82, w := 0.66) -> void:
	k.box(Vector3(len, h, w), col, tf * MeshKit.at(0, h * 0.5, 0))
	var n := int(len / 0.13)
	for i in n:
		var x := -len * 0.5 + (i + 0.5) * len / n
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.05, h - 0.12, 0.02), col.darkened(0.12), tf * MeshKit.at(x, h * 0.5, sz * (w * 0.5 + 0.01)))
	for sz in [-1.0, 1.0]:
		for y in [0.04, h - 0.04]:
			k.box(Vector3(len + 0.02, 0.07, 0.05), col.darkened(0.3), tf * MeshKit.at(0, y, sz * w * 0.5))
	for i in 4:
		k.box(Vector3(0.025, h - 0.1, 0.025), Color(0.55, 0.56, 0.58), tf * MeshKit.at(len * 0.5 + 0.012, h * 0.5, -w * 0.36 + i * w * 0.24))
	k.box(Vector3(0.01, h - 0.08, 0.012), col.darkened(0.35), tf * MeshKit.at(len * 0.5 + 0.006, h * 0.5, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.08, 0.08, 0.08), col.darkened(0.4), tf * MeshKit.at(sx * (len * 0.5 - 0.03), h - 0.03, sz * (w * 0.5 - 0.03)))


## A plywood lean-to, open at the front (+z), tin roof sloping back.
static func ply_shed(k: MeshKit, x0: float, x1: float, z0: float, z1: float, hb: float, hf: float) -> void:
	var ply := Color(0.78, 0.64, 0.46)
	var tin := Color(0.62, 0.64, 0.66)
	var w := x1 - x0
	ArchKit.planks(k, MeshKit.at((x0 + x1) * 0.5, 0, z0 + 0.03), w, hb, ply)
	for sx in [x0 + 0.03, x1 - 0.03]:
		ArchKit.corrugated(k, MeshKit.xf(Vector3(sx, 0, (z0 + z1) * 0.5), Vector3(0, 90 if sx < (x0 + x1) * 0.5 else -90, 0)), z1 - z0, hf * 0.9, Color(0.66, 0.6, 0.52), 0.14)
	for x in [x0 + 0.04, x1 - 0.04]:
		for z in [z0 + 0.04, z1 - 0.04]:
			bx(k, Vector3(x - 0.04, 0, z - 0.04), Vector3(x + 0.04, hb if z < (z0 + z1) * 0.5 else hf, z + 0.04), Color(0.36, 0.25, 0.18))
	var d := z1 - z0 + 0.2
	var ang := rad_to_deg(atan2(hb - hf, d))
	var n := int((w + 0.2) / 0.5) + 1
	for i in n:
		var x := x0 - 0.1 + (i + 0.5) * (w + 0.2) / n
		var c := tin if i % 3 != 1 else Color(0.6, 0.44, 0.32)
		k.box(Vector3((w + 0.2) / n + 0.03, 0.025, d + 0.06), c, MeshKit.xf(Vector3(x, (hb + hf) * 0.5 + 0.03, (z0 + z1) * 0.5), Vector3(ang, 0, 0)))
		for j in 3:
			k.box(Vector3(0.02, 0.02, d + 0.06), c.darkened(0.15), MeshKit.xf(Vector3(x - 0.12 + j * 0.12, (hb + hf) * 0.5 + 0.05, (z0 + z1) * 0.5), Vector3(ang, 0, 0)))


## A flat canopy on posts (corrugated / slatted).
static func canopy(k: MeshKit, x0: float, x1: float, z0: float, z1: float, h: float, col: Color, post: Color) -> void:
	for x in [x0 + 0.05, x1 - 0.05]:
		for z in [z0 + 0.05, z1 - 0.05]:
			bx(k, Vector3(x - 0.03, 0, z - 0.03), Vector3(x + 0.03, h, z + 0.03), post)
	bx(k, Vector3(x0, h, z0), Vector3(x1, h + 0.04, z1), col)
	var n := int((x1 - x0) / 0.15)
	for i in n:
		bx(k, Vector3(x0 + (i + 0.3) * (x1 - x0) / n, h + 0.04, z0), Vector3(x0 + (i + 0.6) * (x1 - x0) / n, h + 0.065, z1), col.darkened(0.1))


## A tapering lattice mast (square, legs of colour col).
static func lattice(k: MeshKit, p: Vector3, h: float, w: float, col: Color, top := 0.35) -> void:
	var levels := maxi(2, int(h / 0.45))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			ln(k, p + Vector3(sx * w * 0.5, 0, sz * w * 0.5), p + Vector3(sx * w * top * 0.5, h, sz * w * top * 0.5), 0.035, col)
	for i in levels:
		var f0 := float(i) / levels
		var f1 := float(i + 1) / levels
		var w0 := w * lerpf(1.0, top, f0) * 0.5
		var w1 := w * lerpf(1.0, top, f1) * 0.5
		var y0 := h * f0
		var y1 := h * f1
		for s in [-1.0, 1.0]:
			ln(k, p + Vector3(-w0, y0, s * w0), p + Vector3(w1, y1, s * w1), 0.02, col)
			ln(k, p + Vector3(s * w0, y0, -w0), p + Vector3(s * w1, y1, w1), 0.02, col)
		k.box(Vector3(w1 * 2.0, 0.025, w1 * 2.0), col, MeshKit.at(p.x, p.y + y1, p.z))


## A floodlight on a pole, aimed into the plot.
static func flood(k: MeshKit, p: Vector3, h: float, t: int, yaw := 0.0) -> void:
	var col: Color = [Color(0.36, 0.25, 0.18), Color(0.6, 0.62, 0.64), Color(0.9, 0.91, 0.92), Color(0.3, 0.32, 0.36), GRAPH][t]
	k.cyl(0.035, h, col, MeshKit.at(p.x, p.y, p.z), 6)
	var tf := MeshKit.xf(p + Vector3(0, h, 0), Vector3(0, yaw, 0))
	k.box(Vector3(0.36, 0.04, 0.04), col, tf)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.14, 0.1, 0.08), Color(0.24, 0.25, 0.28) if t < 4 else GRAPH2, tf * MeshKit.xf(Vector3(sx * 0.12, 0.0, 0.06), Vector3(-30, 0, 0)))
		k.box(Vector3(0.11, 0.07, 0.02), _lit(WARM if t < 3 else Color(0.9, 0.95, 1.0), 0.3), tf * MeshKit.xf(Vector3(sx * 0.12, -0.02, 0.1), Vector3(-30, 0, 0)))


## An outdoor cabinet (base at p, front +z after yaw).
static func cabinet(k: MeshKit, p: Vector3, s: Vector3, body: Color, led: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(s, body, tf * MeshKit.at(0, s.y * 0.5, 0))
	k.box(Vector3(s.x + 0.04, 0.03, s.z + 0.04), body.darkened(0.2), tf * MeshKit.at(0, s.y + 0.015, 0))
	k.box(Vector3(0.012, s.y * 0.8, 0.01), body.darkened(0.25), tf * MeshKit.at(0, s.y * 0.5, s.z * 0.5 + 0.005))
	for i in 3:
		k.box(Vector3(s.x * 0.3, 0.012, 0.01), body.darkened(0.2), tf * MeshKit.at(-s.x * 0.22, s.y * (0.25 + i * 0.08), s.z * 0.5 + 0.005))
	k.box(Vector3(0.05, 0.03, 0.01), _lit(led, 0.4), tf * MeshKit.at(s.x * 0.25, s.y * 0.85, s.z * 0.5 + 0.006))
	k.box(Vector3(0.05, 0.03, 0.01), _lit(led, 0.4), tf * MeshKit.at(s.x * 0.25 - 0.08, s.y * 0.85, s.z * 0.5 + 0.006))


## A white campus pavilion: ArchKit block plus a teal band and a cornice.
static func pavilion(k: MeshKit, a: Vector3, b: Vector3, floors: int, faces: String, t := 2) -> float:
	var top := ArchKit.block(k, Vector3((a.x + b.x) * 0.5, a.y, (a.z + b.z) * 0.5), Vector3(b.x - a.x, b.y - a.y, b.z - a.z), t, faces, floors)
	if t == 2:
		bx(k, Vector3(a.x - 0.02, a.y + 0.3, a.z - 0.02), Vector3(b.x + 0.02, a.y + 0.38, b.z + 0.02), _c(2, "accent"))
	return top


## A graphite monolith with brass bands and glowing fins on the faces in
## `faces` ("f" +z, "l" -x, "r" +x). Returns its top.
static func monolith(k: MeshKit, a: Vector3, b: Vector3, faces := "f", fin_gap := 0.32) -> float:
	var h := b.y - a.y
	bx(k, a, b, GRAPH)
	var bands := maxi(1, int(h / 1.1))
	for i in bands + 1:
		var y := a.y + h * float(i) / bands
		bx(k, Vector3(a.x - 0.02, y - 0.03, a.z - 0.02), Vector3(b.x + 0.02, y + 0.01, b.z + 0.02), Pal.BRASS)
	for f in faces:
		var len := (b.x - a.x) if f == "f" else (b.z - a.z)
		var n := maxi(1, int(len / fin_gap))
		for i in n:
			var u := (i + 0.5) / n
			match f:
				"f":
					var x := lerpf(a.x, b.x, u)
					bx(k, Vector3(x - 0.035, a.y + 0.1, b.z), Vector3(x + 0.035, b.y - 0.1, b.z + 0.12), GRAPH2)
					bx(k, Vector3(x - 0.01, a.y + 0.2, b.z + 0.12), Vector3(x + 0.01, b.y - 0.2, b.z + 0.14), _lit(_fin, 0.4))
				"l":
					var z := lerpf(a.z, b.z, u)
					bx(k, Vector3(a.x - 0.12, a.y + 0.1, z - 0.035), Vector3(a.x, b.y - 0.1, z + 0.035), GRAPH2)
					bx(k, Vector3(a.x - 0.14, a.y + 0.2, z - 0.01), Vector3(a.x - 0.12, b.y - 0.2, z + 0.01), _lit(_fin, 0.4))
				"r":
					var z2 := lerpf(a.z, b.z, u)
					bx(k, Vector3(b.x, a.y + 0.1, z2 - 0.035), Vector3(b.x + 0.12, b.y - 0.1, z2 + 0.035), GRAPH2)
					bx(k, Vector3(b.x + 0.12, a.y + 0.2, z2 - 0.01), Vector3(b.x + 0.14, b.y - 0.2, z2 + 0.01), _lit(_fin, 0.4))
	return b.y


## A steel-and-glass hall: dark frame, glass bays, a louvred band and
## rooftop plant. Returns its top.
static func hall(k: MeshKit, a: Vector3, b: Vector3, faces := "f") -> float:
	var t := 3
	var h := b.y - a.y
	bx(k, a, b, _c(t, "wall2"))
	bx(k, Vector3(a.x - 0.02, b.y - 0.12, a.z - 0.02), Vector3(b.x + 0.02, b.y + 0.05, b.z + 0.02), _c(t, "trim"))
	for f in faces:
		var len := (b.x - a.x) if f == "f" else (b.z - a.z)
		var face: Transform3D
		match f:
			"f": face = MeshKit.at((a.x + b.x) * 0.5, a.y + 0.08, b.z)
			"l": face = MeshKit.xf(Vector3(a.x, a.y + 0.08, (a.z + b.z) * 0.5), Vector3(0, -90, 0))
			"r": face = MeshKit.xf(Vector3(b.x, a.y + 0.08, (a.z + b.z) * 0.5), Vector3(0, 90, 0))
		ArchKit.curtain(k, face, len - 0.16, h * 0.62, t, maxi(2, int(len / 0.45)), maxi(1, int(h * 0.62 / 0.7)))
		ArchKit.louvres(k, face * MeshKit.at(0, h * 0.68, 0), len - 0.2, h * 0.16, _c(t, "metal"), 4)
		k.box(Vector3(len - 0.1, 0.03, 0.03), _lit(LED3, 0.45), face * MeshKit.at(0, h * 0.66 - 0.04, 0.06))
	ArchKit.parapet(k, Vector3((a.x + b.x) * 0.5, b.y + 0.05, (a.z + b.z) * 0.5), b.x - a.x, b.z - a.z, t)
	return b.y + 0.05


## Industrial roof plant on a shallow roof strip x0..x1 centred on z: slim
## chillers, a pipe pair, vents and a beacon.
static func roof3(k: MeshKit, x0: float, x1: float, z: float, y: float) -> void:
	var w := x1 - x0
	var n := maxi(1, int(w / 1.6))
	for i in n:
		var cx := x0 + (i + 0.5) * w / n
		ArchKit.chiller(k, MeshKit.xf(Vector3(cx, y, z), Vector3.ZERO, Vector3(1, 0.55, 0.42)), minf(1.3, w / n - 0.2), 3)
	pipe(k, [Vector3(x0 + 0.1, y + 0.62, z + 0.12), Vector3(x1 - 0.1, y + 0.62, z + 0.12)], 0.05, Color(0.36, 0.6, 0.86))
	pipe(k, [Vector3(x0 + 0.1, y + 0.62, z - 0.12), Vector3(x1 - 0.1, y + 0.62, z - 0.12)], 0.05, Color(0.86, 0.86, 0.84))
	for i in 3:
		k.cyl(0.05, 0.3, Color(0.62, 0.64, 0.66), MeshKit.at(lerpf(x0 + 0.2, x1 - 0.2, i * 0.5), y, z - 0.2), 6)
	ArchKit.beacon(k, Vector3(x1 - 0.15, y, z), 0.6)


## A row of planters with shrubs or trees.
static func planters(k: MeshKit, a: Vector3, b: Vector3, n: int, t: int, trees := false) -> void:
	for i in n:
		var p := a.lerp(b, (i + 0.5) / n)
		ArchKit.planter(k, p, t, 0.42, trees and i % 2 == 0)


## A lit window/screen panel on a face.
static func screen(k: MeshKit, p: Vector3, w: float, h: float, col: Color, yaw := 0.0, bars := 4) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(w + 0.04, h + 0.04, 0.03), Color(0.12, 0.13, 0.15), tf)
	for i in bars:
		var bw := w * (0.3 + 0.6 * fposmod(i * 0.41 + 0.2, 1.0))
		k.box(Vector3(bw, h / bars * 0.5, 0.01), _lit(col, 0.45), tf * MeshKit.at(-w * 0.5 + bw * 0.5 + 0.02, h * 0.5 - (i + 0.5) * h / bars, 0.02))


# ---------------------------------------------------------------- ground

## The ground of the lot: the plot's bed plus a front yard surface.
static func bed(res: String, w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var b := MeshKit.new()
	_bed(b, res, w, d, t)
	k.merge(b, MeshKit.at(0, 0, -CZ))
	return k.commit()


static func _bed(k: MeshKit, res: String, w: float, d: float, t: int) -> void:
	var hx := w * 0.5
	var z0 := CZ - d * 0.5
	var z1 := CZ + d * 0.5
	var tint: Color = Defs.ITEMS[res]["color"]
	var col: Color
	if _office(res):
		col = [Color(0.7, 0.6, 0.46), Color(0.66, 0.67, 0.68), Color(0.82, 0.74, 0.62), Color(0.36, 0.38, 0.42), Color(0.3, 0.31, 0.35)][t]
	elif _mine(res):
		col = [Color(0.56, 0.46, 0.36), Color(0.6, 0.56, 0.5), Color(0.72, 0.7, 0.66), Color(0.46, 0.48, 0.52), Color(0.32, 0.31, 0.33)][t]
	else:
		col = [Color(0.6, 0.56, 0.48), Color(0.66, 0.66, 0.64), Color(0.78, 0.78, 0.76), Color(0.48, 0.5, 0.55), Color(0.3, 0.31, 0.35)][t]
	if t < 3:
		col = col.lerp(tint, 0.08)
	k.box(Vector3(w, 0.14, d), col, MeshKit.at(0, 0.0, CZ))
	var top := 0.071
	var r := RandomNumberGenerator.new()
	r.seed = hash(res) + t
	match t:
		0:
			# dirt and gravel patches, tyre ruts, a puddle, plank walkways
			for i in 16:
				var p := Vector3(r.randf_range(-hx + 0.3, hx - 0.3), top, r.randf_range(z0 + 0.3, z1 - 0.3))
				k.box(Vector3(r.randf_range(0.2, 0.6), 0.012, r.randf_range(0.15, 0.4)), col.darkened(r.randf_range(-0.08, 0.12)), MeshKit.xf(p, Vector3(0, r.randf_range(0, 180), 0)))
			for i in 24:
				var p2 := Vector3(r.randf_range(-hx + 0.2, hx - 0.2), top + 0.01, r.randf_range(z0 + 0.2, z1 - 0.2))
				k.box(Vector3(0.06, 0.04, 0.05), Pal.STONE_DARK.lerp(Pal.STONE, r.randf()), MeshKit.xf(p2, Vector3(0, r.randf_range(0, 90), 0)))
			k.box(Vector3(0.5, 0.012, 0.3), Color(0.36, 0.48, 0.56), MeshKit.xf(Vector3(1.2, top + 0.004, 0.55), Vector3(0, 20, 0)))
			if _office(res):
				# a deck of salvaged boards under the desks
				var nb := int(d / 0.2)
				for i in nb:
					var off := r.randf_range(-0.3, 0.3)
					k.box(Vector3(w * 0.5 - 0.06 + off, 0.02, 0.18), Color(0.7, 0.56, 0.4).darkened(r.randf_range(0.0, 0.14)), MeshKit.at(-w * 0.25 + off * 0.5, top + 0.01, z0 + 0.1 + i * 0.2))
					k.box(Vector3(w * 0.5 - 0.06 - off, 0.02, 0.18), Color(0.7, 0.56, 0.4).darkened(r.randf_range(0.0, 0.14)), MeshKit.at(w * 0.25 + off * 0.5, top + 0.01, z0 + 0.1 + i * 0.2))
			for i in 5:
				k.box(Vector3(0.26, 0.025, 0.5), Color(0.62, 0.48, 0.32).darkened(0.05 * (i % 2)), MeshKit.xf(Vector3(r.randf_range(-0.1, 0.1), top + 0.012, 0.75 - i * 0.55), Vector3(0, r.randf_range(-8, 8), 0)))
		1:
			# poured concrete with joints, a painted walkway, a drain
			for i in 6:
				k.box(Vector3(0.02, 0.006, d - 0.1), col.darkened(0.18), MeshKit.at(-hx + (i + 1) * w / 7.0, top, CZ))
			for j in 3:
				k.box(Vector3(w - 0.1, 0.006, 0.02), col.darkened(0.18), MeshKit.at(0, top, z0 + (j + 1) * d / 4.0))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.06, 0.008, d - 0.3), Color(0.96, 0.76, 0.2), MeshKit.at(sx * 0.62, top + 0.001, CZ + 0.1))
			for i in 4:
				k.box(Vector3(0.12, 0.006, 0.9), col.darkened(0.08), MeshKit.xf(Vector3(r.randf_range(-2.0, 2.0), top + 0.002, r.randf_range(-2.0, 0.2)), Vector3(0, r.randf_range(-30, 30), 0)))
			k.box(Vector3(0.4, 0.01, 0.16), Color(0.3, 0.31, 0.33), MeshKit.at(0, top + 0.002, 0.7))
			for i in 6:
				k.box(Vector3(0.02, 0.012, 0.14), Color(0.5, 0.52, 0.54), MeshKit.at(-0.15 + i * 0.06, top + 0.006, 0.7))
		2:
			# pavers, grass strips and kerbs along the sides
			for i in 9:
				for j in 6:
					if (i + j) % 2 == 0:
						k.box(Vector3(w / 9.0 - 0.04, 0.008, d / 6.0 - 0.04), col.darkened(0.05), MeshKit.at(-hx + (i + 0.5) * w / 9.0, top, z0 + (j + 0.5) * d / 6.0))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.12, 0.05, d - 0.2), Color(0.88, 0.88, 0.88), MeshKit.at(sx * (hx - 0.62), top + 0.02, CZ - 0.2))
			k.box(Vector3(w - 0.1, 0.05, 0.1), Color(0.88, 0.88, 0.88), MeshKit.at(0, top + 0.02, z1 - 0.1))
		3:
			# a steel-edged slab, yellow lines, a lit cable trench, grating
			for i in 5:
				k.box(Vector3(0.05, 0.008, d - 0.2), Color(0.98, 0.8, 0.22), MeshKit.at(-hx + 0.55 + i * (w - 1.1) / 4.0, top, CZ))
			for sz in [z0 + 0.06, z1 - 0.06]:
				k.box(Vector3(w, 0.03, 0.08), Color(0.3, 0.32, 0.36), MeshKit.at(0, top + 0.01, sz))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.08, 0.03, d), Color(0.3, 0.32, 0.36), MeshKit.at(sx * (hx - 0.04), top + 0.01, CZ))
			k.box(Vector3(w - 0.4, 0.012, 0.22), Pal.STEEL_DARK, MeshKit.at(0, top + 0.002, 0.65))
			k.box(Vector3(w - 0.5, 0.012, 0.04), _lit(LED3, 0.5), MeshKit.at(0, top + 0.006, 0.65))
			for i in 7:
				k.box(Vector3(0.12, 0.006, 0.6), Color(0.98, 0.8, 0.22) if i % 2 == 0 else Color(0.16, 0.16, 0.18), MeshKit.xf(Vector3(-0.36 + i * 0.12, top + 0.004, 0.75), Vector3(0, 35, 0)))
		4:
			# dark tiles with glowing seams and brass inlays
			var n := 9
			for i in n + 1:
				k.box(Vector3(0.02, 0.006, d), _lit(Color(0.42, 0.9, 1.0), 0.6), MeshKit.at(-hx + i * w / n, top, CZ))
			for j in 7:
				k.box(Vector3(w, 0.006, 0.02), _lit(Color(0.42, 0.9, 1.0), 0.6), MeshKit.at(0, top, z0 + j * d / 6.0))
			for sz in [z0 + 0.05, z1 - 0.05]:
				k.box(Vector3(w, 0.02, 0.04), Pal.BRASS, MeshKit.at(0, top + 0.01, sz))
			k.box(Vector3(0.9, 0.008, 0.9), Color(0.12, 0.13, 0.15), MeshKit.xf(Vector3(0, top + 0.003, 0.55), Vector3(0, 45, 0)))
			k.box(Vector3(0.6, 0.01, 0.6), _lit(Pal.BRASS, 0.7), MeshKit.xf(Vector3(0, top + 0.004, 0.55), Vector3(0, 45, 0)))
	# the front yard outside the gate
	var fz0 := FENCE_F + 0.04
	var fz1 := 2.9
	var fy: Color = [Color(0.6, 0.55, 0.46), Color(0.66, 0.66, 0.64), Color(0.84, 0.84, 0.82), Color(0.42, 0.44, 0.48), Color(0.3, 0.31, 0.35)][t]
	k.box(Vector3(5.8, 0.03, fz1 - fz0), fy, MeshKit.at(0, 0.015, (fz0 + fz1) * 0.5))
	match t:
		0:
			for i in 10:
				k.box(Vector3(0.3, 0.012, 0.2), fy.darkened(r.randf_range(0.0, 0.12)), MeshKit.xf(Vector3(r.randf_range(-2.6, 2.6), 0.032, r.randf_range(fz0 + 0.2, fz1 - 0.2)), Vector3(0, r.randf_range(0, 180), 0)))
		1:
			for i in 5:
				k.box(Vector3(0.02, 0.006, fz1 - fz0), fy.darkened(0.15), MeshKit.at(-2.3 + i * 1.15, 0.032, (fz0 + fz1) * 0.5))
			k.box(Vector3(5.8, 0.008, 0.06), Color(0.96, 0.76, 0.2), MeshKit.at(0, 0.034, fz1 - 0.05))
		2:
			k.box(Vector3(5.8, 0.05, 0.1), Color(0.92, 0.92, 0.92), MeshKit.at(0, 0.04, fz1 - 0.05))
			k.box(Vector3(1.4, 0.006, fz1 - fz0 - 0.1), Color(0.76, 0.74, 0.7), MeshKit.at(0, 0.033, (fz0 + fz1) * 0.5))
		3:
			k.box(Vector3(5.8, 0.04, 0.08), Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.035, fz1 - 0.04))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.06, 0.006, fz1 - fz0), Color(0.98, 0.8, 0.22), MeshKit.at(sx * 0.85, 0.033, (fz0 + fz1) * 0.5))
		4:
			k.box(Vector3(5.8, 0.03, 0.04), Pal.BRASS, MeshKit.at(0, 0.035, fz1 - 0.03))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.025, 0.006, fz1 - fz0), _lit(Color(0.42, 0.9, 1.0), 0.5), MeshKit.at(sx * 0.85, 0.033, (fz0 + fz1) * 0.5))


# ---------------------------------------------------------------- fence

static func wall(w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var b := MeshKit.new()
	_fence(b, t)
	k.merge(b, MeshKit.at(0, 0, -CZ))
	return k.commit()


static func _fence(k: MeshKit, t: int) -> void:
	var g := GATE * 0.5
	var runs := [[Vector3(-FENCE_X, 0, FENCE_B), Vector3(FENCE_X, 0, FENCE_B)],
		[Vector3(FENCE_X, 0, FENCE_B), Vector3(FENCE_X, 0, FENCE_F)],
		[Vector3(-FENCE_X, 0, FENCE_F), Vector3(-FENCE_X, 0, FENCE_B)],
		[Vector3(FENCE_X, 0, FENCE_F), Vector3(g, 0, FENCE_F)],
		[Vector3(-g, 0, FENCE_F), Vector3(-FENCE_X, 0, FENCE_F)]]
	var ri := 0
	for e in runs:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var len := a.distance_to(b)
		var dir := (b - a) / len
		var yaw := rad_to_deg(atan2(dir.x, dir.z))
		match t:
			0:
				# leaning timber posts, two rails, patched with tin and a tarp
				var n := maxi(1, int(round(len / 0.9)))
				for i in n + 1:
					var q := a.lerp(b, float(i) / n)
					k.box(Vector3(0.08, 0.62, 0.08), Pal.WOOD_DARK, MeshKit.xf(q + Vector3(0, 0.3, 0), Vector3(0, i * 17.0, (i % 3 - 1) * 4.0)))
				for y in [0.22, 0.5]:
					ln(k, a + Vector3(0, y, 0), b + Vector3(0, y + 0.02, 0), 0.05, Pal.WOOD)
				if ri == 0:
					# a blue tarp hung on the back fence, tin sheets
					k.box(Vector3(1.6, 0.5, 0.02), Color(0.26, 0.46, 0.78), MeshKit.xf(Vector3(-1.4, 0.32, FENCE_B + 0.04), Vector3(0, 0, 2)))
					for i in 3:
						k.box(Vector3(0.6, 0.54, 0.02), Color(0.62, 0.64, 0.66).darkened(0.08 * i), MeshKit.xf(Vector3(0.8 + i * 0.62, 0.3, FENCE_B + 0.03), Vector3(0, 0, (i - 1) * 3.0)))
				elif ri <= 2:
					for i in 2:
						var q2 := a.lerp(b, 0.25 + i * 0.4)
						k.box(Vector3(0.02, 0.48, 0.7), Color(0.62, 0.64, 0.66).darkened(0.06 * i), MeshKit.xf(q2 + Vector3(0, 0.3, 0), Vector3(0, 0, (i * 2 - 1) * 3.0)))
			1:
				# chain-link on steel posts with barbed wire arms
				var n1 := maxi(1, int(round(len / 1.2)))
				for i in n1 + 1:
					var q1 := a.lerp(b, float(i) / n1)
					k.cyl(0.03, 0.9, Color(0.62, 0.64, 0.66), MeshKit.at(q1.x, 0.0, q1.z), 6)
					k.box(Vector3(0.025, 0.2, 0.025), Color(0.62, 0.64, 0.66), MeshKit.xf(q1 + Vector3(0, 0.96, 0), Vector3(0, yaw, 0)) * MeshKit.xf(Vector3(0, 0, 0), Vector3(0, 90, 30)))
				var mid := (a + b) * 0.5
				k.box(Vector3(0.012, 0.76, len), Color(0.5, 0.52, 0.54), MeshKit.xf(mid + Vector3(0, 0.44, 0), Vector3(0, yaw, 0)))
				for i in int(len / 0.3):
					var q3 := a + dir * (i * 0.3 + 0.15)
					k.box(Vector3(0.016, 0.76, 0.012), Color(0.66, 0.68, 0.7), MeshKit.xf(q3 + Vector3(0, 0.44, 0), Vector3(0, yaw, 0)) * MeshKit.xf(Vector3.ZERO, Vector3(20, 0, 0)))
				ln(k, a + Vector3(0, 0.86, 0), b + Vector3(0, 0.86, 0), 0.035, Color(0.62, 0.64, 0.66))
				var side := Vector3(dir.z, 0, -dir.x) * 0.0
				for j in 3:
					ln(k, a + Vector3(0, 0.92 + j * 0.05, 0) + side, b + Vector3(0, 0.92 + j * 0.05, 0) + side, 0.012, Color(0.45, 0.46, 0.48))
			2:
				# a low white wall with a teal band, pilasters and caps
				var h2 := 0.5
				var mid2 := (a + b) * 0.5
				k.box(Vector3(0.18, h2, len), Color(0.94, 0.94, 0.94), MeshKit.xf(mid2 + Vector3(0, h2 * 0.5, 0), Vector3(0, yaw, 0)))
				k.box(Vector3(0.19, 0.06, len), _c(2, "accent"), MeshKit.xf(mid2 + Vector3(0, h2 * 0.62, 0), Vector3(0, yaw, 0)))
				k.box(Vector3(0.24, 0.04, len + 0.04), Color(0.84, 0.86, 0.88), MeshKit.xf(mid2 + Vector3(0, h2 + 0.02, 0), Vector3(0, yaw, 0)))
				var n2 := maxi(1, int(round(len / 1.3)))
				for i in n2 + 1:
					var q4 := a.lerp(b, float(i) / n2)
					if (ri == 1 or ri == 2) and q4.z > -0.85 and q4.z < 1.0:
						continue    # Growth's corner slots stand here
					k.box(Vector3(0.22, h2 + 0.12, 0.22), Color(0.97, 0.97, 0.97), MeshKit.at(q4.x, (h2 + 0.12) * 0.5, q4.z))
					k.box(Vector3(0.26, 0.04, 0.26), Color(0.84, 0.86, 0.88), MeshKit.at(q4.x, h2 + 0.14, q4.z))
			3:
				# a steel palisade on a concrete plinth with a blue LED rail
				var mid3 := (a + b) * 0.5
				k.box(Vector3(0.2, 0.16, len), Color(0.62, 0.62, 0.6), MeshKit.xf(mid3 + Vector3(0, 0.08, 0), Vector3(0, yaw, 0)))
				for i in int(len / 0.16) + 1:
					var q5 := a + dir * minf(i * 0.16, len)
					k.box(Vector3(0.03, 0.82, 0.03), Color(0.3, 0.32, 0.36), MeshKit.at(q5.x, 0.16 + 0.41, q5.z))
				for y in [0.3, 0.9]:
					k.box(Vector3(0.05, 0.05, len), Color(0.24, 0.26, 0.3), MeshKit.xf(mid3 + Vector3(0, y, 0), Vector3(0, yaw, 0)))
				k.box(Vector3(0.02, 0.02, len), _lit(LED3, 0.45), MeshKit.xf(mid3 + Vector3(0, 0.94, 0), Vector3(0, yaw, 0)))
				var n3 := maxi(1, int(round(len / 1.6)))
				for i in n3 + 1:
					var q6 := a.lerp(b, float(i) / n3)
					k.box(Vector3(0.1, 1.05, 0.1), Color(0.98, 0.8, 0.22), MeshKit.at(q6.x, 0.52, q6.z))
			4:
				# a graphite plinth, glass panes, brass rail, glowing post caps
				var mid4 := (a + b) * 0.5
				k.box(Vector3(0.24, 0.22, len), GRAPH2, MeshKit.xf(mid4 + Vector3(0, 0.11, 0), Vector3(0, yaw, 0)))
				k.box(Vector3(0.04, 0.6, len), Color(0.5, 0.7, 0.86, 0.75), MeshKit.xf(mid4 + Vector3(0, 0.52, 0), Vector3(0, yaw, 0)))
				k.box(Vector3(0.08, 0.04, len + 0.04), Pal.BRASS, MeshKit.xf(mid4 + Vector3(0, 0.84, 0), Vector3(0, yaw, 0)))
				k.box(Vector3(0.25, 0.02, len), _lit(Color(0.42, 0.9, 1.0), 0.5), MeshKit.xf(mid4 + Vector3(0, 0.225, 0), Vector3(0, yaw, 0)))
				var n4 := maxi(1, int(round(len / 1.2)))
				for i in n4 + 1:
					var q7 := a.lerp(b, float(i) / n4)
					k.box(Vector3(0.14, 0.92, 0.14), GRAPH, MeshKit.at(q7.x, 0.46, q7.z))
					k.box(Vector3(0.16, 0.03, 0.16), Pal.BRASS, MeshKit.at(q7.x, 0.93, q7.z))
					k.box(Vector3(0.08, 0.06, 0.08), _lit(WARM, 0.35), MeshKit.at(q7.x, 0.97, q7.z))
		ri += 1
	# the gate
	for sx in [-1.0, 1.0]:
		var gp := Vector3(sx * g, 0, FENCE_F - 0.05)
		match t:
			0:
				k.box(Vector3(0.12, 1.1, 0.12), Pal.WOOD_DARK, MeshKit.xf(gp + Vector3(0, 0.55, 0), Vector3(0, 0, sx * -2)))
				k.box(Vector3(0.06, 0.06, 0.06), _lit(WARM, 0.3), MeshKit.at(gp.x, 1.14, gp.z))
			1:
				k.box(Vector3(0.12, 1.2, 0.12), Color(0.96, 0.76, 0.2), MeshKit.at(gp.x, 0.6, gp.z))
				for i in 4:
					k.box(Vector3(0.125, 0.08, 0.125), Color(0.16, 0.16, 0.18), MeshKit.at(gp.x, 0.2 + i * 0.26, gp.z))
				k.box(Vector3(0.1, 0.1, 0.1), _lit(Color(1.0, 0.6, 0.2), 0.35), MeshKit.at(gp.x, 1.26, gp.z))
			2:
				k.box(Vector3(0.3, 0.9, 0.22), Color(0.97, 0.97, 0.97), MeshKit.at(gp.x, 0.45, gp.z))
				k.box(Vector3(0.31, 0.08, 0.23), _c(2, "accent"), MeshKit.at(gp.x, 0.62, gp.z))
				k.box(Vector3(0.12, 0.08, 0.02), _lit(Color(0.42, 0.96, 0.9), 0.4), MeshKit.at(gp.x, 0.78, gp.z + 0.12))
			3:
				k.box(Vector3(0.22, 1.3, 0.22), Color(0.3, 0.32, 0.36), MeshKit.at(gp.x, 0.65, gp.z))
				k.box(Vector3(0.04, 1.1, 0.02), _lit(LED3, 0.45), MeshKit.at(gp.x, 0.65, gp.z + 0.12))
				k.box(Vector3(0.16, 0.1, 0.1), _lit(Color(1.0, 0.3, 0.25), 0.4), MeshKit.at(gp.x, 1.36, gp.z))
			4:
				k.box(Vector3(0.24, 1.7, 0.22), GRAPH, MeshKit.at(gp.x, 0.85, gp.z))
				k.box(Vector3(0.26, 0.03, 0.24), Pal.BRASS, MeshKit.at(gp.x, 1.7, gp.z))
				k.box(Vector3(0.03, 1.5, 0.02), _lit(WARM, 0.35), MeshKit.at(gp.x - sx * 0.08, 0.85, gp.z + 0.12))
	match t:
		0:
			# a plank across the gate with hand-painted letters, string lights
			k.box(Vector3(GATE + 0.3, 0.2, 0.04), Color(0.86, 0.8, 0.66), MeshKit.xf(Vector3(0, 1.0, FENCE_F + 0.07), Vector3(0, 0, 2)))
			for i in 5:
				k.box(Vector3(0.12, 0.1, 0.01), [Color(0.8, 0.3, 0.26), Color(0.26, 0.46, 0.78)][i % 2], MeshKit.at(-0.4 + i * 0.2, 1.0, FENCE_F + 0.095))
			bulbs(k, Vector3(-FENCE_X, 0.62, FENCE_F), Vector3(-g, 1.1, FENCE_F), 6)
			bulbs(k, Vector3(g, 1.1, FENCE_F), Vector3(FENCE_X, 0.62, FENCE_F), 6)
		1:
			# warning signs on the gate posts
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.3, 0.22, 0.02), Color(0.96, 0.76, 0.2), MeshKit.at(sx * (g + 0.3), 0.6, FENCE_F + 0.03))
				k.box(Vector3(0.2, 0.05, 0.01), Color(0.16, 0.16, 0.18), MeshKit.at(sx * (g + 0.3), 0.62, FENCE_F + 0.045))
		2:
			pass
		3:
			# a boom barrier, raised
			k.box(Vector3(0.24, 0.6, 0.24), Color(0.96, 0.96, 0.96), MeshKit.at(-g - 0.29, 0.3, FENCE_F + 0.25))
			for i in 6:
				k.box(Vector3(0.06, 0.24, 0.06), Color(0.9, 0.22, 0.2) if i % 2 == 0 else Color(0.96, 0.96, 0.96), MeshKit.xf(Vector3(-g - 0.29 + 0.03, 0.75 + i * 0.22, FENCE_F + 0.25), Vector3(0, 0, -6)))
		4:
			# a graphite portal over the gate with a glowing ring
			k.box(Vector3(GATE + 0.24, 0.22, 0.3), GRAPH, MeshKit.at(0, 1.81, FENCE_F))
			k.box(Vector3(GATE + 0.26, 0.03, 0.32), Pal.BRASS, MeshKit.at(0, 1.93, FENCE_F))
			k.box(Vector3(GATE - 0.1, 0.03, 0.02), _lit(WARM, 0.35), MeshKit.at(0, 1.74, FENCE_F + 0.16))
			k.torus(0.2, 0.025, _lit(Color(0.42, 0.9, 1.0), 0.4), MeshKit.xf(Vector3(0, 1.81, FENCE_F + 0.17), Vector3(90, 0, 0)), 14, 3)


# ---------------------------------------------------------------- extras

## Everything that makes a source its own place at tier t.
static func extras(res: String, w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var b := MeshKit.new()
	t = clampi(t, 0, 4)
	_fin = FIN.get(res, WARM)
	_sign(b, res, t)
	match res:
		"power": _power(b, t)
		"data": _data(b, t)
		"coolant": _coolant(b, t)
		"silicon": _silicon(b, t)
		"copper": _copper(b, t)
		"rare": _rare(b, t)
		"code": _code(b, t)
		"labels": _labels(b, t)
		"feedback": _feedback(b, t)
		"papers": _papers(b, t)
		"fiber": _fiber(b, t)
		"experts": _experts(b, t)
	k.merge(b, MeshKit.at(0, 0, -CZ))
	return k.commit()


## The source's sign on the front fence, in its colour.
static func _sign(k: MeshKit, res: String, t: int) -> void:
	var col: Color = Defs.ITEMS[res]["color"]
	var p := Vector3(-1.25, 0, FENCE_F + 0.02)
	match t:
		0:
			k.box(Vector3(0.62, 0.32, 0.03), Color(0.92, 0.88, 0.78), MeshKit.xf(p + Vector3(0, 0.52, 0.03), Vector3(0, 0, -4)))
			k.box(Vector3(0.2, 0.2, 0.01), col, MeshKit.xf(p + Vector3(-0.16, 0.53, 0.05), Vector3(0, 0, -4)))
			for i in 3:
				k.box(Vector3(0.24 - i * 0.05, 0.035, 0.01), Color(0.3, 0.24, 0.2), MeshKit.xf(p + Vector3(0.1, 0.6 - i * 0.07, 0.05), Vector3(0, 0, -4)))
		1:
			k.box(Vector3(0.7, 0.34, 0.03), Color(0.2, 0.21, 0.24), MeshKit.at(p.x, 0.58, p.z + 0.03))
			k.box(Vector3(0.66, 0.06, 0.01), Color(0.96, 0.76, 0.2), MeshKit.at(p.x, 0.44, p.z + 0.05))
			k.box(Vector3(0.2, 0.2, 0.01), col, MeshKit.at(p.x - 0.2, 0.62, p.z + 0.05))
			k.box(Vector3(0.3, 0.04, 0.01), Color(0.9, 0.9, 0.9), MeshKit.at(p.x + 0.12, 0.64, p.z + 0.05))
		2:
			k.box(Vector3(0.8, 0.3, 0.06), Color(0.98, 0.98, 0.98), MeshKit.at(p.x, 0.68, p.z + 0.03))
			k.box(Vector3(0.22, 0.22, 0.02), col, MeshKit.at(p.x - 0.24, 0.68, p.z + 0.07))
			k.box(Vector3(0.36, 0.05, 0.02), _c(2, "dark"), MeshKit.at(p.x + 0.12, 0.7, p.z + 0.07))
			k.box(Vector3(0.82, 0.04, 0.07), _c(2, "accent"), MeshKit.at(p.x, 0.52, p.z + 0.03))
		3:
			k.box(Vector3(0.86, 0.34, 0.06), Color(0.14, 0.15, 0.18), MeshKit.at(p.x, 1.12, p.z))
			k.box(Vector3(0.24, 0.24, 0.02), _lit(col, 0.5), MeshKit.at(p.x - 0.26, 1.12, p.z + 0.04))
			k.box(Vector3(0.4, 0.06, 0.02), _lit(Color(0.9, 0.95, 1.0), 0.45), MeshKit.at(p.x + 0.14, 1.14, p.z + 0.04))
			k.box(Vector3(0.86, 0.02, 0.02), _lit(LED3, 0.45), MeshKit.at(p.x, 0.94, p.z + 0.04))
		4:
			k.box(Vector3(0.9, 0.3, 0.1), GRAPH, MeshKit.at(p.x, 1.2, p.z))
			k.box(Vector3(0.92, 0.03, 0.12), Pal.BRASS, MeshKit.at(p.x, 1.36, p.z))
			k.box(Vector3(0.92, 0.03, 0.12), Pal.BRASS, MeshKit.at(p.x, 1.04, p.z))
			k.box(Vector3(0.24, 0.24, 0.02), _lit(col, 0.4), MeshKit.at(p.x - 0.28, 1.2, p.z + 0.06))
			k.box(Vector3(0.44, 0.06, 0.02), _lit(WARM, 0.4), MeshKit.at(p.x + 0.14, 1.2, p.z + 0.06))


# ---------------------------------------------------------------- shared props

## A dish antenna (bowl facing local +z after yaw/pitch) at p.
static func dish(k: MeshKit, p: Vector3, r: float, col: Color, yaw := 0.0, pitch := 20.0) -> void:
	var tf := MeshKit.xf(p, Vector3(90 - pitch, yaw, 0))
	k.lathe(PackedVector2Array([Vector2(0, -0.01), Vector2(r * 0.5, 0.0), Vector2(r, r * 0.3), Vector2(r * 0.92, r * 0.3), Vector2(0, 0.02)]), col, tf, 10)
	ln(k, tf * Vector3(0, 0, 0), tf * Vector3(0, r * 0.8, 0), 0.015, Pal.STEEL_DARK)
	k.box(Vector3(0.05, 0.05, 0.05), col.darkened(0.3), tf * MeshKit.at(0, r * 0.8, 0))


## A horizontal tank on saddles, centred on p, its length along local x.
static func htank(k: MeshKit, p: Vector3, r: float, len: float, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.capsule(r, len, col, tf * MeshKit.xf(Vector3(len * 0.5, r + 0.2, 0), Vector3(0, 0, 90)), 10, 3)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.12, r + 0.2, r * 1.4), Color(0.35, 0.36, 0.4), tf * MeshKit.at(sx * len * 0.3, (r + 0.2) * 0.5, 0))
	for sx in [-1.0, 1.0]:
		k.cyl(r + 0.01, 0.03, col.darkened(0.15), tf * MeshKit.xf(Vector3(sx * len * 0.2, r + 0.2, 0), Vector3(0, 0, 90)), 10, 0.0, -1.0, false)


## A graphite tank with brass bands and a glowing level strip.
static func gtank(k: MeshKit, p: Vector3, r: float, h: float) -> void:
	k.cyl(r, h, GRAPH, MeshKit.at(p.x, p.y, p.z), 10)
	k.cyl(r * 0.9, r * 0.35, GRAPH2, MeshKit.at(p.x, p.y + h, p.z), 10, 0.0, r * 0.3)
	for i in 3:
		k.cyl(r + 0.012, 0.03, Pal.BRASS, MeshKit.at(p.x, p.y + h * (0.15 + i * 0.35), p.z), 10, 0.0, -1.0, false)
	k.box(Vector3(0.04, h * 0.6, 0.02), _lit(Color(0.42, 0.9, 1.0), 0.4), MeshKit.at(p.x, p.y + h * 0.5, p.z + r))


## A glowing pipe run (hyperscale coolant) through points.
static func glow_pipe(k: MeshKit, pts: Array, th := 0.06, col := Color(0.42, 0.9, 1.0, 0.4)) -> void:
	for i in pts.size() - 1:
		ln(k, pts[i], pts[i + 1], th, col)
	for i in range(1, pts.size() - 1):
		var q: Vector3 = pts[i]
		k.box(Vector3(th * 1.5, th * 1.5, th * 1.5), Pal.BRASS, MeshKit.at(q.x, q.y, q.z))


## An industrial pipe run (steel colours) through points, with flanges.
static func pipe(k: MeshKit, pts: Array, th: float, col: Color) -> void:
	for i in pts.size() - 1:
		ln(k, pts[i], pts[i + 1], th, col)
	for i in pts.size():
		var q: Vector3 = pts[i]
		k.box(Vector3(th * 1.4, th * 1.4, th * 1.4), col.darkened(0.2), MeshKit.at(q.x, q.y, q.z))


## A simple wooden pole with a cross arm.
static func pole(k: MeshKit, p: Vector3, h: float, col := Color(0.42, 0.3, 0.2)) -> void:
	k.cyl(0.05, h, col, MeshKit.at(p.x, p.y, p.z), 6)
	k.box(Vector3(0.6, 0.05, 0.06), col, MeshKit.at(p.x, p.y + h - 0.2, p.z))
	for sx in [-0.25, 0.0, 0.25]:
		k.cyl(0.02, 0.06, Color(0.9, 0.9, 0.88), MeshKit.at(p.x + sx, p.y + h - 0.17, p.z), 5)


## A parasol.
static func parasol(k: MeshKit, p: Vector3, col: Color) -> void:
	k.cyl(0.02, 1.2, Color(0.8, 0.8, 0.78), MeshKit.at(p.x, p.y, p.z), 5)
	k.cone(0.5, 0.2, col, MeshKit.at(p.x, p.y + 1.05, p.z), 8)


## Car / AGM batteries in a row.
static func batteries(k: MeshKit, p: Vector3, n: int, col := Color(0.12, 0.12, 0.13)) -> void:
	for i in n:
		var q := p + Vector3(i * 0.2, 0, 0)
		k.box(Vector3(0.17, 0.13, 0.11), col, MeshKit.at(q.x, q.y + 0.065, q.z))
		k.box(Vector3(0.025, 0.025, 0.025), Color(0.85, 0.2, 0.18), MeshKit.at(q.x - 0.05, q.y + 0.14, q.z))
		k.box(Vector3(0.025, 0.025, 0.025), Color(0.2, 0.2, 0.2), MeshKit.at(q.x + 0.05, q.y + 0.14, q.z))


## A camping / garden chair facing +z.
static func lawn_chair(k: MeshKit, p: Vector3, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.3, 0.04, 0.28), col, tf * MeshKit.at(0, 0.28, 0))
	k.box(Vector3(0.3, 0.3, 0.04), col, tf * MeshKit.xf(Vector3(0, 0.44, -0.14), Vector3(-15, 0, 0)))
	for sx in [-1.0, 1.0]:
		ln(k, tf * Vector3(sx * 0.14, 0, 0.12), tf * Vector3(sx * 0.14, 0.6, -0.16), 0.02, Color(0.6, 0.62, 0.64))
		ln(k, tf * Vector3(sx * 0.14, 0, -0.14), tf * Vector3(sx * 0.14, 0.3, 0.12), 0.02, Color(0.6, 0.62, 0.64))


# ---------------------------------------------------------------- power

static func _power(k: MeshKit, t: int) -> void:
	var cell := Color(0.16, 0.24, 0.46)
	match t:
		0:
			# a plywood lean-to full of car batteries, salvaged panels on the
			# back fence, cords everywhere, a parasol and a camping chair
			ply_shed(k, -2.8, -1.45, -2.8, -2.2, 1.35, 1.1)
			bx(k, Vector3(-2.72, 0.42, -2.76), Vector3(-1.55, 0.46, -2.46), Pal.WOOD)
			batteries(k, Vector3(-2.6, 0.46, -2.6), 5)
			batteries(k, Vector3(-2.55, 0.0, -2.58), 4, Color(0.2, 0.22, 0.26))
			bx(k, Vector3(-2.2, 0.7, -2.78), Vector3(-1.9, 0.92, -2.74), Color(0.86, 0.86, 0.84))
			k.box(Vector3(0.08, 0.04, 0.01), _lit(Color(0.6, 1.0, 0.62), 0.4), MeshKit.at(-2.05, 0.86, -2.735))
			cord(k, [Vector3(-2.05, 0.7, -2.74), Vector3(-1.8, 0.09, -2.3), Vector3(-1.0, 0.085, -2.1), Vector3(-0.3, 0.085, -1.5), Vector3(0.0, 0.085, -0.8)], Color(0.92, 0.5, 0.2), 0.022)
			cord(k, [Vector3(-1.6, 0.085, -2.25), Vector3(-1.9, 0.085, -1.3), Vector3(-1.6, 0.085, -0.4)], Color(0.2, 0.4, 0.8), 0.022)
			for i in 3:
				Stations._panel(k, MeshKit.xf(Vector3(-0.85 + i * 0.86, 0.48, -2.64), Vector3(68, (i - 1) * 6.0, (i - 1) * 3.0)), 0.8, 0.96, 3, 5, Color(0.72, 0.74, 0.76), cell if i != 1 else cell.lightened(0.1))
			for i in 4:
				k.box(Vector3(0.2, 0.08, 0.1), Pal.BRICK, MeshKit.at(-0.95 + i * 0.6, 0.04, -2.36))
			# right wing: parasol, chair, cooler, a pallet of more panels
			parasol(k, Vector3(2.52, 0, -1.5), Color(0.92, 0.42, 0.3))
			lawn_chair(k, Vector3(2.5, 0, -1.3), Color(0.26, 0.5, 0.36), -60)
			k.box(Vector3(0.3, 0.2, 0.2), Color(0.86, 0.3, 0.26), MeshKit.at(2.5, 0.1, -1.85))
			k.box(Vector3(0.31, 0.04, 0.21), Color(0.95, 0.95, 0.92), MeshKit.at(2.5, 0.22, -1.85))
			pallet(k, Vector3(2.5, 0, -2.45), 90)
			for i in 4:
				k.box(Vector3(0.5, 0.035, 0.42), Color(0.7, 0.72, 0.74) if i % 2 == 0 else cell, MeshKit.xf(Vector3(2.5, 0.12 + i * 0.04, -2.45), Vector3(0, 90 + i * 4.0, 0)))
			# left wing: jerry can, toolbox, wheelbarrow
			k.box(Vector3(0.16, 0.24, 0.1), Color(0.8, 0.22, 0.2), MeshKit.at(-2.55, 0.12, -1.85))
			k.box(Vector3(0.3, 0.14, 0.16), Color(0.86, 0.3, 0.26), MeshKit.at(-2.5, 0.07, -1.4))
			k.box(Vector3(0.3, 0.02, 0.04), Color(0.2, 0.2, 0.22), MeshKit.at(-2.5, 0.15, -1.4))
			Stations._b(k, Vector3(0.26, 0.14, 0.4), Color(0.3, 0.5, 0.36), Vector3(-2.52, 0.24, -1.05), Vector3(8, 0, 0))
			k.cyl(0.07, 0.04, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(-2.54, 0.07, -0.86), Vector3(0, 0, 90)), 8)
			# string lights from the shed to a pole
			pole(k, Vector3(2.62, 0, -2.0), 1.6)
			bulbs(k, Vector3(-1.45, 1.1, -2.2), Vector3(2.62, 1.45, -2.0), 12)
		1:
			# an inverter container with a roll-up door and AC, a battery rack
			# under a tin canopy, cable trays, a weather mast, floodlights
			container(k, MeshKit.at(-1.75, 0, -2.47), 2.0, Color(0.86, 0.87, 0.88))
			ArchKit.rollup(k, MeshKit.at(-1.95, 0, -2.13), 0.7, 0.62, Color(0.96, 0.76, 0.2), 0.35)
			k.box(Vector3(0.22, 0.18, 0.02), Color(0.96, 0.76, 0.2), MeshKit.at(-1.2, 0.5, -2.13))
			k.box(Vector3(0.1, 0.1, 0.01), Color(0.16, 0.16, 0.18), MeshKit.xf(Vector3(-1.2, 0.5, -2.118), Vector3(0, 0, 45)))
			ArchKit.ac_unit(k, MeshKit.at(-2.35, 0.82, -2.5), 1, 0.65)
			ArchKit.louvres(k, MeshKit.at(-0.95, 0.2, -2.13), 0.3, 0.4, Color(0.7, 0.72, 0.74), 5)
			k.cyl(0.08, 0.3, Color(0.7, 0.72, 0.75), MeshKit.at(-1.4, 0.82, -2.5), 8)
			# battery rack
			var steel := Color(0.6, 0.62, 0.66)
			for x in [0.25, 1.05, 1.85]:
				for z in [-2.76, -2.3]:
					bx(k, Vector3(x - 0.025, 0, z - 0.025), Vector3(x + 0.025, 1.0, z + 0.025), steel)
			for j in 3:
				bx(k, Vector3(0.22, 0.1 + j * 0.3, -2.78), Vector3(1.88, 0.13 + j * 0.3, -2.28), steel.darkened(0.15))
				for i in 7:
					k.box(Vector3(0.18, 0.16, 0.3), Color(0.3, 0.32, 0.36), MeshKit.at(0.36 + i * 0.22, 0.21 + j * 0.3, -2.53))
					k.box(Vector3(0.04, 0.02, 0.01), _lit(Color(0.6, 1.0, 0.62), 0.4), MeshKit.at(0.36 + i * 0.22, 0.25 + j * 0.3, -2.375))
			canopy(k, 0.15, 1.95, -2.82, -2.22, 1.3, Color(0.66, 0.68, 0.7), steel)
			ArchKit.cable_tray(k, Vector3(-0.75, 0.62, -2.72), Vector3(2.3, 0.62, -2.72), 1)
			ArchKit.cable_tray(k, Vector3(2.5, 0.62, -2.7), Vector3(2.5, 0.62, -1.1), 1)
			for x in [0.1, 2.1]:
				bx(k, Vector3(x - 0.02, 0, -2.74), Vector3(x + 0.02, 0.6, -2.7), steel)
			# weather mast in the right wing
			lattice(k, Vector3(2.52, 0, -1.6), 2.6, 0.3, Color(0.7, 0.72, 0.75), 0.5)
			k.box(Vector3(0.5, 0.02, 0.02), Color(0.4, 0.42, 0.46), MeshKit.at(2.52, 2.55, -1.6))
			for i in 3:
				var a := TAU * i / 3.0
				ln(k, Vector3(2.32, 2.6, -1.6), Vector3(2.32 + cos(a) * 0.1, 2.6, -1.6 + sin(a) * 0.1), 0.01, Color(0.3, 0.32, 0.36))
				k.sphere(0.03, Color(0.3, 0.32, 0.36), MeshKit.at(2.32 + cos(a) * 0.1, 2.6, -1.6 + sin(a) * 0.1), 5, 3)
			k.box(Vector3(0.02, 0.06, 0.2), Color(0.9, 0.3, 0.26), MeshKit.at(2.72, 2.6, -1.6))
			Stations._panel(k, MeshKit.xf(Vector3(2.52, 1.4, -1.45), Vector3(40, 0, 0)), 0.3, 0.24, 2, 2, steel, cell)
			k.box(Vector3(0.14, 0.18, 0.08), Color(0.86, 0.87, 0.88), MeshKit.at(2.52, 1.0, -1.5))
			# pallets of panels in the left wing, bollards, a floodlight
			for z in [-1.85, -1.25]:
				pallet(k, Vector3(-2.52, 0, z), 90)
				for i in 5:
					k.box(Vector3(0.5, 0.04, 0.4), cell if i % 2 else Color(0.78, 0.8, 0.82), MeshKit.xf(Vector3(-2.52, 0.12 + i * 0.045, z), Vector3(0, 90, 0)))
				k.box(Vector3(0.02, 0.24, 0.42), Color(0.96, 0.76, 0.2), MeshKit.at(-2.52, 0.2, z))
			for p in [Vector3(-2.6, 0, -0.98), Vector3(2.6, 0, -0.98)]:
				k.cyl(0.05, 0.42, Color(0.96, 0.76, 0.2), MeshKit.at(p.x, 0, p.z), 6)
				k.cyl(0.052, 0.06, Color(0.16, 0.16, 0.18), MeshKit.at(p.x, 0.3, p.z), 6, 0.0, -1.0, false)
			flood(k, Vector3(-2.62, 0, -2.0), 2.2, 1, 120)
		2:
			# a white two-storey control building with a solar roof and a
			# sun logo, white battery cabinets, planters, a slim met mast
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(-0.15, 2.6, -2.2), 2, "f")
			ArchKit.door(k, MeshKit.at(-0.7, 0, -2.2), 2, 0.6, 1.0)
			ArchKit.solar(k, MeshKit.at(-1.9, top, -2.55), 3, 2, 20.0, 0.3)
			ArchKit.solar(k, MeshKit.at(-0.75, top, -2.55), 1, 2, 20.0, 0.3)
			# sun logo on the parapet
			k.box(Vector3(0.9, 0.42, 0.06), Color(0.98, 0.98, 0.98), MeshKit.at(-1.45, top + 0.42, -2.16))
			k.cyl(0.13, 0.03, Color(0.98, 0.76, 0.24), MeshKit.xf(Vector3(-1.7, top + 0.42, -2.12), Vector3(90, 0, 0)), 10)
			for i in 8:
				var a := TAU * i / 8.0
				k.box(Vector3(0.04, 0.1, 0.02), Color(0.98, 0.76, 0.24), MeshKit.xf(Vector3(-1.7 + cos(a) * 0.19, top + 0.42 + sin(a) * 0.19, -2.12), Vector3(0, 0, rad_to_deg(a) - 90)))
			k.box(Vector3(0.4, 0.08, 0.02), _c(2, "dark"), MeshKit.at(-1.25, top + 0.45, -2.12))
			k.box(Vector3(0.3, 0.05, 0.02), _c(2, "accent"), MeshKit.at(-1.3, top + 0.33, -2.12))
			# white battery cabinets under a slab
			for i in 5:
				var x := 0.3 + i * 0.5
				k.box(Vector3(0.44, 1.1, 0.5), Color(0.95, 0.95, 0.96), MeshKit.at(x, 0.55, -2.52))
				k.box(Vector3(0.45, 0.08, 0.51), _c(2, "accent"), MeshKit.at(x, 0.9, -2.52))
				k.box(Vector3(0.012, 0.9, 0.01), Color(0.8, 0.82, 0.84), MeshKit.at(x, 0.5, -2.265))
				k.box(Vector3(0.06, 0.03, 0.01), _lit(Color(0.42, 0.96, 0.9), 0.4), MeshKit.at(x + 0.12, 0.75, -2.265))
				for j in 3:
					k.box(Vector3(0.3, 0.02, 0.01), Color(0.8, 0.82, 0.84), MeshKit.at(x, 0.2 + j * 0.08, -2.265))
			k.box(Vector3(2.5, 0.06, 0.6), Color(0.86, 0.86, 0.86), MeshKit.at(1.3, 1.13, -2.52))
			# left wing planters, right wing met mast and a kiosk
			planters(k, Vector3(-2.52, 0, -2.1), Vector3(-2.52, 0, -0.95), 3, 2, true)
			k.cyl(0.035, 3.2, Color(0.94, 0.95, 0.96), MeshKit.at(2.55, 0, -1.7), 8, 0.0, 0.02)
			for y in [1.6, 2.4, 3.1]:
				k.box(Vector3(0.5, 0.02, 0.02), Color(0.86, 0.88, 0.9), MeshKit.at(2.45, y, -1.7))
				k.cyl(0.03, 0.06, _c(2, "accent"), MeshKit.at(2.22, y, -1.7), 6)
			for i in 3:
				ln(k, Vector3(2.55, 2.4, -1.7), Vector3(2.55 + [0.2, -0.25, 0.1][i], 0.0, -1.7 + [0.3, 0.1, -0.35][i]), 0.008, Color(0.7, 0.72, 0.74))
			cabinet(k, Vector3(2.52, 0, -1.15), Vector3(0.36, 0.7, 0.3), Color(0.95, 0.95, 0.96), Color(0.42, 0.96, 0.9), -90)
			k.box(Vector3(0.37, 0.05, 0.31), _c(2, "accent"), MeshKit.xf(Vector3(2.52, 0.55, -1.15), Vector3(0, -90, 0)))
			ArchKit.planter(k, Vector3(2.52, 0, -2.45), 2, 0.42, true)
		3:
			# battery-storage containers with a catwalk on top, an overhead
			# cable gantry, a transformer yard and a pylon carrying the line out
			var dk := Color(0.32, 0.35, 0.4)
			for i in 3:
				var x := -2.1 + i * 1.22
				container(k, MeshKit.at(x, 0, -2.5), 1.18, dk, 0.84, 0.6)
				ArchKit.louvres(k, MeshKit.at(x - 0.3, 0.15, -2.2), 0.3, 0.5, dk.darkened(0.1), 5)
				k.box(Vector3(0.02, 0.5, 0.01), _lit(LED3, 0.45), MeshKit.at(x + 0.2, 0.42, -2.195))
				k.box(Vector3(0.02, 0.5, 0.01), _lit(LED3, 0.45), MeshKit.at(x + 0.3, 0.42, -2.195))
				ArchKit.ac_unit(k, MeshKit.at(x + 0.25, 0.84, -2.55), 3, 0.5)
			ArchKit.catwalk(k, Vector3(-2.7, 0.86, -2.3), Vector3(0.9, 0.86, -2.3), 0.3, 3, false)
			# transformer yard behind its own palisade
			ArchKit.transformer(k, MeshKit.xf(Vector3(1.75, 0, -2.5), Vector3.ZERO, Vector3(0.62, 0.7, 0.62)), 3)
			for x in [1.25, 2.25]:
				bx(k, Vector3(x - 0.02, 0, -2.18), Vector3(x + 0.02, 0.7, -2.14), Color(0.98, 0.8, 0.22))
			for i in 7:
				bx(k, Vector3(1.28 + i * 0.14, 0, -2.17), Vector3(1.3 + i * 0.14, 0.62, -2.15), Color(0.3, 0.32, 0.36))
			# H gantry over the yard and the pylon in the right wing
			lattice(k, Vector3(1.3, 0, -2.55), 2.6, 0.22, Color(0.5, 0.52, 0.56), 0.7)
			lattice(k, Vector3(2.5, 0, -2.55), 2.6, 0.22, Color(0.5, 0.52, 0.56), 0.7)
			bx(k, Vector3(1.2, 2.55, -2.6), Vector3(2.6, 2.65, -2.5), Color(0.5, 0.52, 0.56))
			lattice(k, Vector3(2.52, 0, -1.45), 4.2, 0.42, Color(0.56, 0.58, 0.62), 0.25)
			for y in [3.2, 3.8]:
				bx(k, Vector3(2.0, y, -1.5), Vector3(2.82, y + 0.06, -1.4), Color(0.56, 0.58, 0.62))
				for x in [2.06, 2.78]:
					k.cyl(0.025, 0.18, Color(0.86, 0.6, 0.4), MeshKit.at(x, y - 0.18, -1.45), 5)
			for i in 3:
				var x2 := 1.45 + i * 0.5
				k.cyl(0.025, 0.2, Color(0.86, 0.6, 0.4), MeshKit.at(x2, 2.35, -2.55), 5)
				ln(k, Vector3(x2, 2.35, -2.55), Vector3(2.06 if i < 2 else 2.78, 3.0 + (i % 2) * 0.6, -1.45), 0.012, Color(0.2, 0.2, 0.22))
			for x3 in [2.06, 2.78]:
				for y in [3.02, 3.62]:
					ln(k, Vector3(x3, y, -1.45), Vector3(x3, y - 0.2, -0.95), 0.012, Color(0.2, 0.2, 0.22))
			# overhead cable tray along the back at head height
			for x4 in [-2.75, 1.1]:
				bx(k, Vector3(x4 - 0.04, 0, -2.84), Vector3(x4 + 0.04, 2.3, -2.76), Color(0.3, 0.32, 0.36))
			ArchKit.cable_tray(k, Vector3(-2.75, 2.3, -2.8), Vector3(1.1, 2.3, -2.8), 3)
			# inverter skids in the left wing
			for z in [-1.95, -1.4]:
				cabinet(k, Vector3(-2.52, 0, z), Vector3(0.45, 0.9, 0.42), dk, LED3, 90)
				ArchKit.louvres(k, MeshKit.xf(Vector3(-2.29, 0.15, z), Vector3(0, 90, 0)), 0.3, 0.4, dk.darkened(0.15), 5)
			flood(k, Vector3(-2.62, 0, -1.0), 2.6, 3, 140)
			flood(k, Vector3(2.62, 0, -1.0), 2.6, 3, -140)
		4:
			# a graphite heliostat tower with a glowing receiver and a crown,
			# turbine halls either side, molten-salt tanks in the wings
			var zc := -2.5
			var segs := [[0.0, 1.6, 0.72, 0.6], [1.6, 3.3, 0.6, 0.52], [3.3, 4.7, 0.5, 0.44]]
			for s in segs:
				var y0: float = s[0]
				var y1: float = s[1]
				var sw: float = s[2]
				var sd: float = s[3]
				bx(k, Vector3(-sw * 0.5, y0, zc - sd * 0.5), Vector3(sw * 0.5, y1, zc + sd * 0.5), GRAPH)
				bx(k, Vector3(-sw * 0.5 - 0.03, y1 - 0.06, zc - sd * 0.5 - 0.03), Vector3(sw * 0.5 + 0.03, y1, zc + sd * 0.5 + 0.03), Pal.BRASS)
				for sx in [-1.0, 1.0]:
					bx(k, Vector3(sx * sw * 0.5 - 0.025, y0, zc + sd * 0.5 - 0.02), Vector3(sx * sw * 0.5 + 0.025, y1, zc + sd * 0.5 + 0.03), Pal.BRASS)
				bx(k, Vector3(-0.015, y0 + 0.1, zc + sd * 0.5), Vector3(0.015, y1 - 0.1, zc + sd * 0.5 + 0.02), _lit(WARM, 0.35))
			# receiver
			bx(k, Vector3(-0.38, 4.7, zc - 0.34), Vector3(0.38, 5.5, zc + 0.34), GRAPH2)
			for sx in [-1.0, 1.0]:
				bx(k, Vector3(-0.3, 4.78, zc + sx * 0.34 - 0.02), Vector3(0.3, 5.42, zc + sx * 0.34 + 0.02), Color(1.0, 0.82, 0.45, 0.3))
				bx(k, Vector3(sx * 0.38 - 0.02, 4.78, zc - 0.26), Vector3(sx * 0.38 + 0.02, 5.42, zc + 0.26), Color(1.0, 0.82, 0.45, 0.3))
			for i in 8:
				var a := TAU * i / 8.0 + PI / 8.0
				k.box(Vector3(0.04, 0.9, 0.16), Pal.BRASS, MeshKit.xf(Vector3(cos(a) * 0.48, 5.1, zc + sin(a) * 0.4), Vector3(0, -rad_to_deg(a), 0)))
			bx(k, Vector3(-0.42, 5.5, zc - 0.36), Vector3(0.42, 5.58, zc + 0.36), Pal.BRASS)
			k.torus(0.36, 0.03, _lit(WARM, 0.3), MeshKit.at(0, 5.75, zc), 16, 3)
			k.cyl(0.05, 0.9, GRAPH, MeshKit.at(0, 5.58, zc), 6, 0.0, 0.02)
			ArchKit.beacon(k, Vector3(0, 6.45, zc), 0.25)
			# turbine halls
			var lt := monolith(k, Vector3(-2.8, 0, -2.8), Vector3(-0.5, 1.4, -2.2), "f", 0.36)
			var rt := monolith(k, Vector3(0.5, 0, -2.8), Vector3(2.8, 1.4, -2.2), "f", 0.36)
			ArchKit.drone_pad(k, Vector3(-1.65, lt + 0.02, -2.5), 0.28)
			for i in 4:
				bx(k, Vector3(0.75 + i * 0.5, rt, -2.7), Vector3(0.95 + i * 0.5, rt + 0.3, -2.3), GRAPH2)
				bx(k, Vector3(0.8 + i * 0.5, rt + 0.3, -2.65), Vector3(0.9 + i * 0.5, rt + 0.32, -2.35), _lit(WARM, 0.4))
			# molten-salt tanks in the wings, glowing loops to the tower
			for sx in [-1.0, 1.0]:
				for z in [-1.85, -1.25]:
					gtank(k, Vector3(sx * 2.53, 0, z), 0.24, 1.6)
				glow_pipe(k, [Vector3(sx * 2.53, 1.3, -1.55), Vector3(sx * 2.53, 1.7, -1.55), Vector3(sx * 2.53, 1.7, -2.3), Vector3(sx * 0.4, 1.7, -2.3), Vector3(sx * 0.4, 3.0, -2.3)], 0.06)
				glow_pipe(k, [Vector3(sx * 2.4, 0.3, -1.55), Vector3(sx * 2.4, 0.3, -2.15)], 0.05)


# ---------------------------------------------------------------- data

static func _data(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a hacker den along the back fence: CRTs on a door-desk, a tower
			# PC, a sofa, pizza boxes, and a home-made wifi mast with a yagi
			var top := Color(0.74, 0.6, 0.44)
			bx(k, Vector3(-2.75, 0.5, -2.8), Vector3(-1.25, 0.55, -2.32), top)
			for x in [-2.65, -1.35]:
				for z in [-2.74, -2.38]:
					ln(k, Vector3(x, 0.0, z), Vector3(x, 0.5, z), 0.04, Pal.WOOD)
			for i in 2:
				var x2 := -2.4 + i * 0.6
				k.box(Vector3(0.36, 0.32, 0.3), Color(0.82, 0.8, 0.74), MeshKit.at(x2, 0.72, -2.62))
				k.box(Vector3(0.28, 0.22, 0.02), _lit(Color(0.4, 1.0, 0.6) if i == 0 else Color(0.4, 0.8, 1.0), 0.45), MeshKit.at(x2, 0.74, -2.465))
				k.box(Vector3(0.3, 0.02, 0.1), Color(0.8, 0.78, 0.72), MeshKit.at(x2, 0.56, -2.4))
			k.box(Vector3(0.16, 0.42, 0.4), Color(0.2, 0.2, 0.22), MeshKit.at(-1.45, 0.21, -2.55))
			k.box(Vector3(0.02, 0.04, 0.01), _lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.at(-1.45, 0.36, -2.348))
			Stations._chair(k, Vector3(-2.1, 0, -2.05), Color(0.2, 0.2, 0.22), Color(0.3, 0.3, 0.32))
			cord(k, [Vector3(-1.5, 0.5, -2.35), Vector3(-1.3, 0.085, -2.15), Vector3(-0.6, 0.085, -2.05), Vector3(0.2, 0.085, -1.3)], Color(0.2, 0.4, 0.8), 0.02)
			cord(k, [Vector3(-1.4, 0.5, -2.35), Vector3(-1.1, 0.085, -2.2), Vector3(0.9, 0.085, -2.15), Vector3(1.4, 0.085, -1.3)], Color(0.92, 0.82, 0.3), 0.02)
			# an old sofa and a stack of pizza boxes
			bx(k, Vector3(0.1, 0, -2.78), Vector3(1.5, 0.3, -2.3), Color(0.5, 0.36, 0.5))
			bx(k, Vector3(0.1, 0.3, -2.78), Vector3(1.5, 0.62, -2.62), Color(0.46, 0.32, 0.46))
			for x3 in [0.05, 1.55]:
				bx(k, Vector3(x3 - 0.08, 0, -2.78), Vector3(x3 + 0.08, 0.44, -2.3), Color(0.44, 0.3, 0.44))
			for i in 3:
				k.box(Vector3(0.42, 0.06, 0.4), Color(0.58, 0.42, 0.56), MeshKit.at(0.35 + i * 0.45, 0.33, -2.52))
			for i in 4:
				k.box(Vector3(0.32, 0.04, 0.32), Color(0.9, 0.86, 0.76), MeshKit.xf(Vector3(1.9, 0.02 + i * 0.045, -2.5), Vector3(0, i * 9.0, 0)))
			k.box(Vector3(0.14, 0.04, 0.02), Color(0.8, 0.26, 0.22), MeshKit.at(1.9, 0.19, -2.33))
			# the mast: a pole with a yagi, an old TV dish, guy ropes
			pole(k, Vector3(2.55, 0, -2.4), 2.6)
			bx(k, Vector3(2.53, 2.2, -2.4), Vector3(2.57, 2.24, -1.7), Color(0.6, 0.62, 0.64))
			for i in 6:
				k.box(Vector3(0.3 - i * 0.02, 0.015, 0.015), Color(0.7, 0.72, 0.74), MeshKit.at(2.55, 2.22, -2.35 + i * 0.12))
			dish(k, Vector3(2.5, 1.5, -2.25), 0.22, Color(0.86, 0.86, 0.84), 0, 25)
			for p in [Vector3(2.3, 0, -1.4), Vector3(2.8, 0, -1.6), Vector3(2.3, 0, -2.8)]:
				ln(k, Vector3(2.55, 2.0, -2.4), p, 0.008, Color(0.8, 0.8, 0.76))
			k.box(Vector3(0.18, 0.04, 0.12), Color(0.14, 0.14, 0.16), MeshKit.at(2.55, 0.9, -2.3))
			for i in 3:
				k.box(Vector3(0.012, 0.008, 0.004), _lit(Color(0.5, 1.0, 0.6), 0.35), MeshKit.at(2.5 + i * 0.03, 0.92, -2.24))
			bulbs(k, Vector3(-1.3, 0.9, -2.35), Vector3(2.55, 1.4, -2.3), 11)
			crates(k, Vector3(-2.5, 0, -1.6), 3, 4, Color(0.72, 0.6, 0.42))
			for i in 3:
				k.cyl(0.03, 0.09, [Color(0.3, 0.8, 0.4), Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9)][i], MeshKit.at(-2.6 + i * 0.08, 0.0, -1.1), 6)
		1:
			# a NOC container with windows, AC and a door, cable trays out to
			# a red-and-white lattice mast with microwave dishes, a tripod dish
			var blue := Color(0.32, 0.42, 0.58)
			container(k, MeshKit.at(-1.6, 0, -2.47), 2.3, blue)
			for i in 3:
				k.box(Vector3(0.36, 0.26, 0.04), Color(0.2, 0.21, 0.24), MeshKit.at(-2.35 + i * 0.5, 0.52, -2.13))
				k.box(Vector3(0.3, 0.2, 0.02), Color(0.6, 0.76, 0.86, 0.7), MeshKit.at(-2.35 + i * 0.5, 0.52, -2.11))
			ArchKit.door(k, MeshKit.at(-0.75, 0, -2.13), 1, 0.36, 0.7)
			ArchKit.ac_unit(k, MeshKit.at(-2.2, 0.82, -2.5), 1, 0.6)
			ArchKit.ac_unit(k, MeshKit.at(-1.4, 0.82, -2.5), 1, 0.6)
			k.box(Vector3(0.5, 0.12, 0.02), Color(0.96, 0.76, 0.2), MeshKit.at(-1.6, 0.74, -2.13))
			# the mast
			var red := Color(0.86, 0.3, 0.26)
			for i in 4:
				lattice(k, Vector3(2.4, i * 0.85, -2.45), 0.85, 0.42 - i * 0.07, red if i % 2 == 0 else Color(0.94, 0.94, 0.92), (0.42 - (i + 1) * 0.07) / (0.42 - i * 0.07))
			k.cyl(0.02, 0.6, Color(0.6, 0.62, 0.64), MeshKit.at(2.4, 3.4, -2.45), 5)
			ArchKit.beacon(k, Vector3(2.4, 4.0, -2.45), 0.1)
			for i in 2:
				var y := 1.6 + i * 1.0
				k.cyl(0.14, 0.08, Color(0.9, 0.9, 0.88), MeshKit.xf(Vector3(2.4 - 0.18, y, -2.3), Vector3(90, -30, 0)), 10)
			for i in 3:
				k.box(Vector3(0.05, 0.35, 0.03), Color(0.9, 0.9, 0.88), MeshKit.xf(Vector3(2.4, 3.1, -2.45), Vector3(0, i * 120, 0)) * MeshKit.at(0, 0, 0.12))
			# trays
			for x in [-0.4, 1.0]:
				bx(k, Vector3(x - 0.02, 0, -2.74), Vector3(x + 0.02, 0.9, -2.7), Color(0.6, 0.62, 0.64))
			ArchKit.cable_tray(k, Vector3(-0.45, 0.9, -2.72), Vector3(2.2, 0.9, -2.72), 1)
			ArchKit.cable_tray(k, Vector3(2.5, 0.4, -2.2), Vector3(2.5, 0.4, -1.0), 1)
			# a tripod dish and a cable drum
			for i in 3:
				var a := TAU * i / 3.0
				ln(k, Vector3(0.5, 0.6, -2.5), Vector3(0.5 + cos(a) * 0.3, 0, -2.5 + sin(a) * 0.25), 0.025, Color(0.6, 0.62, 0.64))
			dish(k, Vector3(0.5, 0.75, -2.5), 0.38, Color(0.86, 0.87, 0.88), 15, 35)
			k.cyl(0.25, 0.3, Pal.WOOD, MeshKit.xf(Vector3(1.4, 0.25, -2.65), Vector3(0, 0, 90)), 10)
			k.cyl(0.18, 0.31, Color(0.2, 0.4, 0.8), MeshKit.xf(Vector3(1.4, 0.25, -2.65), Vector3(0, 0, 90)), 10)
			# left wing: a rack of spares and a floodlight
			for j in 3:
				bx(k, Vector3(-2.75, 0.1 + j * 0.35, -1.9), Vector3(-2.3, 0.13 + j * 0.35, -1.1), Color(0.6, 0.62, 0.66))
				for i in 3:
					k.box(Vector3(0.36, 0.14, 0.2), Color(0.2, 0.21, 0.24) if (i + j) % 2 else Color(0.72, 0.6, 0.42), MeshKit.at(-2.52, 0.2 + j * 0.35, -1.75 + i * 0.26))
			for z in [-1.9, -1.1]:
				for x2 in [-2.75, -2.3]:
					bx(k, Vector3(x2 - 0.02, 0, z - 0.02), Vector3(x2 + 0.02, 1.0, z + 0.02), Color(0.6, 0.62, 0.66))
			flood(k, Vector3(-2.6, 0, -2.3), 2.2, 1, 140)
		2:
			# a white two-storey office with a web logo and rooftop antennas,
			# a white monopole with sector antennas, planters
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(0.7, 2.7, -2.2), 2, "f")
			ArchKit.door(k, MeshKit.at(-1.05, 0, -2.2), 2, 0.6, 1.0)
			k.box(Vector3(1.3, 0.5, 0.06), Color(0.98, 0.98, 0.98), MeshKit.at(-1.05, top + 0.45, -2.17))
			for i in 3:
				var r := 0.06 + i * 0.06
				for s in 6:
					var a := TAU * s / 6.0
					ln(k, Vector3(-1.45 + cos(a) * r, top + 0.45 + sin(a) * r, -2.13), Vector3(-1.45 + cos(a + TAU / 6.0) * r, top + 0.45 + sin(a + TAU / 6.0) * r, -2.13), 0.015, _c(2, "accent"))
			for s in 3:
				var a2 := PI * s / 3.0
				ln(k, Vector3(-1.45 - cos(a2) * 0.2, top + 0.45 - sin(a2) * 0.2, -2.13), Vector3(-1.45 + cos(a2) * 0.2, top + 0.45 + sin(a2) * 0.2, -2.13), 0.012, _c(2, "accent"))
			k.box(Vector3(0.6, 0.1, 0.02), _c(2, "dark"), MeshKit.at(-0.85, top + 0.48, -2.13))
			k.box(Vector3(0.4, 0.05, 0.02), _c(2, "accent"), MeshKit.at(-0.9, top + 0.36, -2.13))
			for i in 3:
				k.cyl(0.02, 0.8, Color(0.86, 0.88, 0.9), MeshKit.at(-2.4 + i * 0.7, top, -2.6), 5)
				dish(k, Vector3(-2.4 + i * 0.7, top + 0.55, -2.55), 0.14, Color(0.96, 0.96, 0.96), i * 30.0, 30)
			ArchKit.ac_unit(k, MeshKit.at(0.2, top, -2.55), 2, 0.7)
			# monopole
			k.cyl(0.08, 3.8, Color(0.94, 0.95, 0.96), MeshKit.at(2.3, 0, -2.5), 8, 0.0, 0.05)
			for y in [3.0, 3.6]:
				for i in 3:
					k.box(Vector3(0.12, 0.42, 0.05), Color(0.96, 0.96, 0.96), MeshKit.xf(Vector3(2.3, y, -2.5), Vector3(0, i * 120.0, 0)) * MeshKit.at(0, 0, 0.16))
				k.box(Vector3(0.4, 0.03, 0.4), _c(2, "accent"), MeshKit.at(2.3, y - 0.24, -2.5))
			cabinet(k, Vector3(1.5, 0, -2.5), Vector3(0.5, 0.9, 0.4), Color(0.95, 0.95, 0.96), Color(0.42, 0.96, 0.9))
			k.box(Vector3(0.51, 0.06, 0.41), _c(2, "accent"), MeshKit.at(1.5, 0.7, -2.5))
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -0.95), 3, 2, true)
			planters(k, Vector3(2.52, 0, -2.05), Vector3(2.52, 0, -0.95), 3, 2, false)
		3:
			# a steel-and-glass data hall with chillers on the roof, a tall
			# lattice tower of microwave dishes, generators, cable gantry
			var top := hall(k, Vector3(-2.8, 0, -2.8), Vector3(0.9, 2.4, -2.2), "f")
			roof3(k, -2.7, 0.8, -2.5, top)
			ArchKit.door(k, MeshKit.at(-0.4, 0, -2.2), 3, 0.5, 0.9)
			for x in [-2.5, 0.6]:
				ArchKit.beacon(k, Vector3(x, top + 1.0, -2.3), 0.15)
			# tower
			lattice(k, Vector3(2.35, 0, -2.45), 4.8, 0.6, Color(0.5, 0.52, 0.56), 0.25)
			for i in 4:
				var y := 1.8 + i * 0.7
				k.cyl(0.16 - i * 0.015, 0.1, Color(0.9, 0.9, 0.88), MeshKit.xf(Vector3(2.35 + [-0.2, 0.15, -0.12, 0.1][i], y, -2.3), Vector3(90, [-20.0, 30.0, -50.0, 10.0][i], 0)), 10)
			ArchKit.beacon(k, Vector3(2.35, 4.8, -2.45), 0.3)
			# generators in the right wing (turned along the fence)
			for z in [-1.7, -1.1]:
				ArchKit.generator(k, MeshKit.xf(Vector3(2.53, 0, z), Vector3(0, -90, 0), Vector3(0.24, 0.6, 0.5)), 3)
			# cooling cabinets in the left wing, a cable gantry overhead
			for z in [-1.9, -1.4]:
				cabinet(k, Vector3(-2.52, 0, z), Vector3(0.42, 0.85, 0.42), Color(0.32, 0.35, 0.4), LED3, 90)
			pipe(k, [Vector3(-2.28, 0.5, -1.0), Vector3(-2.28, 0.5, -2.1)], 0.06, Color(0.36, 0.6, 0.86))
			pipe(k, [Vector3(-2.28, 0.3, -1.0), Vector3(-2.28, 0.3, -2.1)], 0.06, Color(0.86, 0.86, 0.84))
			bx(k, Vector3(1.0, 0, -2.8), Vector3(1.08, 2.25, -2.72), Color(0.3, 0.32, 0.36))
			ArchKit.cable_tray(k, Vector3(0.9, 2.25, -2.76), Vector3(2.2, 2.25, -2.76), 3)
		4:
			# the crawler spire: a graphite needle with brass ribs and glowing
			# rings, graphite server pods, wings with glowing fins
			var zc := -2.5
			var levels := 8
			for i in levels:
				var f0 := float(i) / levels
				var f1 := float(i + 1) / levels
				var w0 := lerpf(0.74, 0.16, f0)
				var y0 := f0 * 6.0
				var y1 := f1 * 6.0
				var d0 := minf(w0, 0.6)
				bx(k, Vector3(-w0 * 0.5, y0, zc - d0 * 0.5), Vector3(w0 * 0.5, y1, zc + d0 * 0.5), GRAPH if i % 2 == 0 else GRAPH2)
				bx(k, Vector3(-w0 * 0.5 - 0.02, y1 - 0.05, zc - d0 * 0.5 - 0.02), Vector3(w0 * 0.5 + 0.02, y1, zc + d0 * 0.5 + 0.02), Pal.BRASS)
				bx(k, Vector3(-0.012, y0 + 0.08, zc + d0 * 0.5), Vector3(0.012, y1 - 0.08, zc + d0 * 0.5 + 0.02), _lit(Color(0.42, 0.9, 1.0), 0.4))
				if i % 2 == 1:
					k.torus(w0 * 0.75, 0.02, _lit(Color(0.42, 0.9, 1.0), 0.35), MeshKit.xf(Vector3(0, y1 - 0.2, zc), Vector3(0, 0, 0), Vector3(1, 1, 0.8)), 14, 3)
			k.sphere(0.12, _lit(WARM, 0.3), MeshKit.at(0, 6.15, zc), 8, 4)
			k.cyl(0.02, 0.6, Pal.BRASS, MeshKit.at(0, 6.2, zc), 5)
			ArchKit.beacon(k, Vector3(0, 6.8, zc), 0.1)
			# server pods either side of the spire
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.55
				var xb: float = sx * 2.2
				var a := Vector3(minf(xa, xb), 0, -2.8)
				var b := Vector3(maxf(xa, xb), 1.0, -2.2)
				monolith(k, a, b, "f", 0.3)
				for i in 3:
					var x := lerpf(a.x, b.x, (i + 0.5) / 3.0)
					bx(k, Vector3(x - 0.2, b.y, -2.7), Vector3(x + 0.2, b.y + 0.12, -2.3), GRAPH2)
					bx(k, Vector3(x - 0.16, b.y + 0.12, -2.66), Vector3(x + 0.16, b.y + 0.135, -2.34), _lit(Color(0.42, 0.9, 1.0), 0.45))
			# wings: tall graphite blocks with fins facing the plot
			monolith(k, Vector3(-2.8, 0, -2.8), Vector3(-2.3, 2.2, -1.0), "r", 0.3)
			monolith(k, Vector3(2.3, 0, -2.8), Vector3(2.8, 2.2, -1.0), "l", 0.3)
			ArchKit.drone_pad(k, Vector3(2.55, 2.22, -1.6), 0.24)
			ArchKit.beacon(k, Vector3(-2.55, 2.2, -2.6), 0.4)
			for sx in [-1.0, 1.0]:
				glow_pipe(k, [Vector3(sx * 2.15, 0.09, -1.2), Vector3(sx * 2.15, 0.09, -2.1), Vector3(sx * 0.45, 0.09, -2.1)], 0.04, _lit(Color(0.42, 0.9, 1.0), 0.4))


# ---------------------------------------------------------------- coolant

static func _coolant(k: MeshKit, t: int) -> void:
	var blue := Color(0.36, 0.6, 0.86)
	match t:
		0:
			# a kiddie pool with a box fan, water jugs, a hose, an IBC tote
			var pc := Vector3(-2.33, 0, -2.42)
			k.cyl(0.42, 0.2, Color(0.3, 0.6, 0.9), MeshKit.at(pc.x, 0, pc.z), 12)
			k.cyl(0.37, 0.02, Color(0.5, 0.78, 0.92), MeshKit.at(pc.x, 0.17, pc.z), 12)
			k.torus(0.4, 0.04, Color(0.96, 0.9, 0.3), MeshKit.at(pc.x, 0.2, pc.z), 12, 4)
			k.torus(0.12, 0.04, Color(0.96, 0.5, 0.6), MeshKit.at(pc.x + 0.1, 0.21, pc.z + 0.05), 10, 4)
			crate(k, Vector3(-1.75, 0, -2.6), Vector3(0.28, 0.24, 0.26), Pal.WOOD_LIGHT)
			k.box(Vector3(0.36, 0.36, 0.1), Color(0.9, 0.9, 0.88), MeshKit.xf(Vector3(-1.75, 0.44, -2.6), Vector3(0, -60, 0)))
			k.cyl(0.15, 0.02, Color(0.4, 0.42, 0.46), MeshKit.xf(Vector3(-1.75, 0.44, -2.6), Vector3(90, -60, 0)), 10)
			for i in 6:
				var q := Vector3(-1.3 + (i % 3) * 0.2, (i / 3) * 0.3, -2.7)
				k.cyl(0.08, 0.28, Color(0.5, 0.7, 0.95, 0.85), MeshKit.at(q.x, q.y, q.z), 8)
				k.cyl(0.03, 0.04, Color(0.2, 0.4, 0.8), MeshKit.at(q.x, q.y + 0.28, q.z), 6)
			cord(k, [Vector3(-2.0, 0.2, -2.3), Vector3(-1.6, 0.085, -2.1), Vector3(-0.8, 0.085, -2.15), Vector3(-0.2, 0.085, -1.5), Vector3(0.4, 0.085, -1.4)], Color(0.3, 0.62, 0.32), 0.025)
			# IBC tote in its cage with a tap
			var tc := Vector3(0.7, 0, -2.5)
			k.box(Vector3(0.56, 0.08, 0.56), Pal.WOOD_LIGHT, MeshKit.at(tc.x, 0.04, tc.z))
			k.box(Vector3(0.52, 0.5, 0.52), Color(0.92, 0.94, 0.92, 0.9), MeshKit.at(tc.x, 0.33, tc.z))
			for i in 4:
				k.box(Vector3(0.54, 0.02, 0.54), Color(0.6, 0.62, 0.64), MeshKit.at(tc.x, 0.1 + i * 0.15, tc.z))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.box(Vector3(0.025, 0.52, 0.025), Color(0.6, 0.62, 0.64), MeshKit.at(tc.x + sx * 0.27, 0.33, tc.z + sz * 0.27))
			k.box(Vector3(0.08, 0.08, 0.06), Color(0.2, 0.2, 0.22), MeshKit.at(tc.x, 0.14, tc.z + 0.29))
			# umbrella, cooler, a bucket, a garden chair in the right wing
			parasol(k, Vector3(2.5, 0, -1.6), Color(0.3, 0.7, 0.9))
			k.box(Vector3(0.3, 0.2, 0.2), Color(0.26, 0.46, 0.78), MeshKit.at(2.5, 0.1, -2.1))
			k.box(Vector3(0.31, 0.04, 0.21), Color(0.95, 0.95, 0.92), MeshKit.at(2.5, 0.22, -2.1))
			k.cyl(0.1, 0.2, Color(0.9, 0.5, 0.2), MeshKit.at(2.5, 0, -2.5), 8, 0.0, 0.12)
			lawn_chair(k, Vector3(2.5, 0, -1.2), Color(0.94, 0.94, 0.92), -70)
			for i in 4:
				k.box(Vector3(0.12, 0.1, 0.1), Color(0.82, 0.9, 0.96), MeshKit.xf(Vector3(-2.5, 0.05, -1.6 + i * 0.16), Vector3(0, i * 20.0, 0)))
			bulbs(k, Vector3(-2.8, 0.62, -1.9), Vector3(-1.5, 1.0, -2.8), 6)
			bulbs(k, Vector3(1.2, 0.62, -2.85), Vector3(2.85, 0.62, -1.6), 7)
		1:
			# an elevated water tank on a braced steel stand, a pump skid,
			# a pump-room container, IBC totes, blue pipes on the fence
			var steel := Color(0.6, 0.62, 0.66)
			var tp := Vector3(2.45, 0, -2.42)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					ln(k, tp + Vector3(sx * 0.28, 0, sz * 0.28), tp + Vector3(sx * 0.22, 1.8, sz * 0.22), 0.05, steel)
			for i in 3:
				var y0 := i * 0.6
				for s in [-1.0, 1.0]:
					ln(k, tp + Vector3(-0.27, y0, s * 0.27), tp + Vector3(0.25, y0 + 0.6, s * 0.25), 0.025, steel)
					ln(k, tp + Vector3(s * 0.27, y0, -0.27), tp + Vector3(s * 0.25, y0 + 0.6, 0.25), 0.025, steel)
			k.box(Vector3(0.62, 0.05, 0.62), steel.darkened(0.2), MeshKit.at(tp.x, 1.82, tp.z))
			k.cyl(0.34, 0.7, Color(0.78, 0.8, 0.82), MeshKit.at(tp.x, 1.85, tp.z), 12)
			for y in [0.15, 0.4, 0.62]:
				k.cyl(0.345, 0.03, Color(0.6, 0.62, 0.66), MeshKit.at(tp.x, 1.85 + y, tp.z), 12, 0.0, -1.0, false)
			k.cone(0.36, 0.22, Color(0.66, 0.68, 0.7), MeshKit.at(tp.x, 2.55, tp.z), 12)
			k.box(Vector3(0.3, 0.18, 0.02), Color(0.96, 0.76, 0.2), MeshKit.at(tp.x, 2.2, tp.z + 0.34))
			ArchKit.ladder(k, MeshKit.at(tp.x - 0.3, 0, tp.z + 0.25), 2.5, Color(0.96, 0.76, 0.2))
			pipe(k, [tp + Vector3(0, 1.85, 0), tp + Vector3(0, 0.25, 0.32), Vector3(1.5, 0.25, -2.1), Vector3(-0.6, 0.25, -2.1)], 0.07, blue)
			# pump room container and the skid
			container(k, MeshKit.at(-0.2, 0, -2.47), 2.0, Color(0.38, 0.56, 0.72))
			ArchKit.rollup(k, MeshKit.at(0.1, 0, -2.13), 0.7, 0.62, Color(0.86, 0.87, 0.88), 0.4)
			ArchKit.louvres(k, MeshKit.at(-0.7, 0.3, -2.13), 0.4, 0.35, Color(0.7, 0.72, 0.74), 5)
			ArchKit.ac_unit(k, MeshKit.at(-0.8, 0.82, -2.5), 1, 0.6)
			bx(k, Vector3(-2.75, 0, -2.78), Vector3(-1.35, 0.1, -2.2), Color(0.3, 0.32, 0.36))
			for i in 2:
				var x := -2.4 + i * 0.7
				k.cyl(0.13, 0.36, blue, MeshKit.xf(Vector3(x - 0.18, 0.28, -2.5), Vector3(0, 0, -90)), 10)
				k.box(Vector3(0.26, 0.24, 0.24), Color(0.3, 0.5, 0.36), MeshKit.at(x + 0.12, 0.25, -2.5))
				pipe(k, [Vector3(x - 0.18, 0.28, -2.5), Vector3(x - 0.18, 0.7, -2.5), Vector3(x - 0.18, 0.7, -2.25)], 0.06, blue)
			pipe(k, [Vector3(-2.58, 0.7, -2.25), Vector3(-1.2, 0.7, -2.25)], 0.06, blue)
			bx(k, Vector3(-2.75, 0.85, -2.78), Vector3(-1.35, 0.88, -2.74), Color(0.96, 0.76, 0.2))
			for x2 in [-2.7, -2.05, -1.4]:
				bx(k, Vector3(x2 - 0.02, 0.1, -2.78), Vector3(x2 + 0.02, 0.88, -2.74), Color(0.96, 0.76, 0.2))
			# IBC totes in the left wing
			for z in [-1.9, -1.3]:
				k.box(Vector3(0.5, 0.08, 0.5), Pal.WOOD_LIGHT, MeshKit.at(-2.52, 0.04, z))
				k.box(Vector3(0.46, 0.46, 0.46), Color(0.92, 0.94, 0.92, 0.9), MeshKit.at(-2.52, 0.31, z))
				for i in 3:
					k.box(Vector3(0.48, 0.02, 0.48), steel, MeshKit.at(-2.52, 0.12 + i * 0.16, z))
			flood(k, Vector3(2.62, 0, -1.2), 2.2, 1, -130)
		2:
			# two slim white cooling towers in the back corners, a white pump
			# house with screened rooftop plant between them, planters
			for sx in [-1.0, 1.0]:
				var c := Vector3(sx * 2.42, 0, -2.42)
				k.lathe(PackedVector2Array([Vector2(0.38, 0), Vector2(0.3, 0.9), Vector2(0.26, 1.7), Vector2(0.3, 2.4), Vector2(0.27, 2.4)]), Color(0.95, 0.95, 0.96), MeshKit.at(c.x, 0, c.z), 12)
				k.cyl(0.29, 0.1, _c(2, "accent"), MeshKit.at(c.x, 2.0, c.z), 12, 0.0, 0.3, false)
				k.cyl(0.25, 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(c.x, 2.34, c.z), 12)
				for i in 6:
					var a := TAU * i / 6.0
					k.box(Vector3(0.05, 0.3, 0.05), Color(0.86, 0.88, 0.9), MeshKit.at(c.x + cos(a) * 0.36, 0.15, c.z + sin(a) * 0.36))
				pipe(k, [c + Vector3(-sx * 0.3, 0.4, 0.15), Vector3(sx * 1.85, 0.4, -2.27)], 0.06, Color(0.86, 0.88, 0.9))
			var top := pavilion(k, Vector3(-1.85, 0, -2.8), Vector3(1.85, 1.5, -2.22), 1, "f")
			ArchKit.door(k, MeshKit.at(0.9, 0, -2.22), 2, 0.5, 0.95)
			bx(k, Vector3(-1.4, top, -2.72), Vector3(0.6, top + 0.5, -2.3), Color(0.86, 0.88, 0.9))
			ArchKit.louvres(k, MeshKit.at(-0.4, top + 0.05, -2.29), 1.9, 0.4, Color(0.92, 0.93, 0.94), 6)
			k.cyl(0.18, 0.5, Color(0.95, 0.95, 0.96), MeshKit.at(1.2, top, -2.5), 10)
			k.box(Vector3(0.9, 0.3, 0.05), Color(0.98, 0.98, 0.98), MeshKit.at(-0.9, top + 0.75, -2.3))
			k.sphere(0.09, blue, MeshKit.at(-1.18, top + 0.75, -2.26), 8, 4)
			k.box(Vector3(0.4, 0.06, 0.02), _c(2, "dark"), MeshKit.at(-0.75, top + 0.78, -2.26))
			for i in 2:
				k.box(Vector3(0.05, 0.4, 0.05), Color(0.86, 0.88, 0.9), MeshKit.at(-1.25 + i * 0.7, top + 0.4, -2.3))
			planters(k, Vector3(-2.52, 0, -1.95), Vector3(-2.52, 0, -0.95), 2, 2, true)
			planters(k, Vector3(2.52, 0, -1.95), Vector3(2.52, 0, -0.95), 2, 2, true)
		3:
			# a rectangular cooling tower bank with fan stacks and a stair,
			# a pipe rack down the right wing, dosing tanks in the left wing
			var dk := Color(0.36, 0.4, 0.46)
			var x0 := -2.8
			var x1 := 1.5
			bx(k, Vector3(x0, 0, -2.8), Vector3(x1, 0.3, -2.2), Color(0.3, 0.32, 0.36))
			bx(k, Vector3(x0 + 0.05, 0.3, -2.78), Vector3(x1 - 0.05, 2.0, -2.22), dk)
			for i in 12:
				bx(k, Vector3(x0 + 0.1, 0.4 + i * 0.13, -2.22), Vector3(x1 - 0.1, 0.43 + i * 0.13, -2.15), dk.darkened(0.25))
			for i in 4:
				var x := lerpf(x0, x1, (i + 0.5) / 4.0)
				bx(k, Vector3(x - 0.03, 0.3, -2.23), Vector3(x + 0.03, 2.0, -2.13), Color(0.24, 0.26, 0.3))
			bx(k, Vector3(x0, 2.0, -2.82), Vector3(x1, 2.08, -2.18), Color(0.26, 0.28, 0.32))
			for i in 3:
				var x2 := lerpf(x0, x1, (i + 0.5) / 3.0)
				k.cyl(0.28, 0.45, dk.lightened(0.08), MeshKit.at(x2, 2.08, -2.5), 12, 0.0, 0.3)
				k.cyl(0.26, 0.02, Color(0.12, 0.13, 0.15), MeshKit.at(x2, 2.45, -2.5), 12)
				for s in 4:
					k.box(Vector3(0.48, 0.015, 0.06), Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(x2, 2.48, -2.5), Vector3(0, s * 45.0, 0)))
				k.torus(0.29, 0.015, _lit(LED3, 0.45), MeshKit.at(x2, 2.5, -2.5), 12, 3)
			ArchKit.railing(k, Vector3(x0 + 0.05, 2.08, -2.2), Vector3(x1 - 0.05, 2.08, -2.2), 0.5, Color(0.98, 0.8, 0.22))
			bx(k, Vector3(x0, 1.3, -2.15), Vector3(x1, 1.33, -2.13), _lit(LED3, 0.45))
			# stair tower at the end
			var sx0 := 1.6
			for x3 in [sx0, sx0 + 0.6]:
				for z in [-2.78, -2.22]:
					bx(k, Vector3(x3 - 0.03, 0, z - 0.03), Vector3(x3 + 0.03, 2.4, z + 0.03), Color(0.98, 0.8, 0.22))
			for i in 4:
				k.box(Vector3(0.6, 0.04, 0.3), Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(sx0 + 0.3, 0.3 + i * 0.5, -2.5), Vector3(0, 0, 18 if i % 2 else -18)))
			bx(k, Vector3(sx0 - 0.05, 2.0, -2.82), Vector3(sx0 + 0.65, 2.05, -2.18), Color(0.5, 0.52, 0.56))
			# pipe rack down the right wing with pumps
			ArchKit.pipe_rack(k, MeshKit.xf(Vector3(2.53, 0, -1.65), Vector3(0, 90, 0)), 1.3, 1.5, 3, 3)
			for z in [-1.2, -1.75]:
				k.cyl(0.1, 0.28, blue, MeshKit.xf(Vector3(2.4, 0.18, z), Vector3(0, 0, -90)), 10)
				k.box(Vector3(0.22, 0.22, 0.2), dk, MeshKit.at(2.6, 0.12, z))
			pipe(k, [Vector3(1.5, 1.2, -2.3), Vector3(2.3, 1.2, -2.3), Vector3(2.3, 1.6, -2.3)], 0.07, blue)
			# dosing tanks and a treatment cabinet in the left wing
			for z in [-1.95, -1.45]:
				ArchKit.tank(k, MeshKit.at(-2.52, 0, z), 0.2, 0.8, Color(0.86, 0.88, 0.9), 3)
			cabinet(k, Vector3(-2.52, 0, -1.05), Vector3(0.4, 0.7, 0.3), dk, LED3, 90)
			flood(k, Vector3(-2.62, 0, -2.6), 2.8, 3, 140)
		4:
			# a graphite hyperbolic tower ringed with glowing bands, graphite
			# heat-exchanger wings looped with glowing coolant, pump halls
			var c := Vector3(0, 0, -2.47)
			var prof := PackedVector2Array([Vector2(0.37, 0), Vector2(0.33, 1.2), Vector2(0.3, 2.4), Vector2(0.36, 3.6), Vector2(0.5, 4.6), Vector2(0.46, 4.6)])
			k.lathe(prof, GRAPH, MeshKit.at(c.x, 0, c.z), 14)
			var radii := [0.35, 0.31, 0.32, 0.43]
			for i in 4:
				k.torus(float(radii[i]) + 0.02, 0.03, _lit(Color(0.42, 0.9, 1.0), 0.35), MeshKit.at(c.x, 0.8 + i * 1.0, c.z), 16, 3)
			k.torus(0.5, 0.035, Pal.BRASS, MeshKit.at(c.x, 4.6, c.z), 16, 3)
			for i in 6:
				var a := TAU * i / 6.0
				k.box(Vector3(0.07, 0.5, 0.07), Pal.BRASS, MeshKit.at(c.x + cos(a) * 0.36, 0.25, c.z + sin(a) * 0.36))
			for i in 3:
				k.sphere(0.22 - i * 0.04, Color(0.9, 0.94, 0.98), MeshKit.at(c.x + (i - 1) * 0.12, 4.75 + i * 0.22, c.z + 0.05 * i), 8, 4)
			ArchKit.beacon(k, Vector3(c.x + 0.45, 4.6, c.z), 0.2)
			# pump halls either side
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.6
				var xb: float = sx * 2.2
				monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.1, -2.22), "f", 0.32)
				glow_pipe(k, [Vector3(sx * 1.4, 1.1, -2.5), Vector3(sx * 1.4, 1.5, -2.5), Vector3(sx * 0.35, 1.5, -2.5)], 0.07)
			# heat exchangers in the wings
			for sx in [-1.0, 1.0]:
				var x: float = sx * 2.53
				bx(k, Vector3(x - 0.26, 0, -2.8), Vector3(x + 0.26, 1.5, -1.0), GRAPH2)
				for i in 6:
					var z := -2.65 + i * 0.3
					k.torus(0.16, 0.025, _lit(Color(0.42, 0.9, 1.0), 0.4), MeshKit.xf(Vector3(x - sx * 0.27, 0.9, z), Vector3(0, 0, 90)), 10, 3, PI)
					bx(k, Vector3(x - 0.27, 0.05, z - 0.02), Vector3(x + 0.27, 1.45, z + 0.02), Pal.BRASS)
				bx(k, Vector3(x - 0.28, 1.5, -2.82), Vector3(x + 0.28, 1.56, -0.98), Pal.BRASS)
				for i in 3:
					k.cyl(0.12, 0.14, GRAPH, MeshKit.at(x, 1.56, -2.4 + i * 0.6), 8)
					k.cyl(0.1, 0.01, _lit(WARM, 0.4), MeshKit.at(x, 1.7, -2.4 + i * 0.6), 8)


# ---------------------------------------------------------------- silicon

## A silo (base on the ground, legs, a cone hopper, a body, a cone roof).
static func silo(k: MeshKit, p: Vector3, r: float, h: float, col: Color, legs := 0.5, band := Color.TRANSPARENT) -> void:
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		k.box(Vector3(0.05, legs + 0.1, 0.05), Pal.STEEL_DARK, MeshKit.at(p.x + cos(a) * r * 0.8, (legs + 0.1) * 0.5, p.z + sin(a) * r * 0.8))
	k.cone(r, -0.01, col, MeshKit.at(p.x, legs, p.z), 10)
	k.cyl(r * 0.25, legs * 0.6, col.darkened(0.2), MeshKit.at(p.x, legs * 0.2, p.z), 6)
	k.lathe(PackedVector2Array([Vector2(r * 0.2, legs - 0.05), Vector2(r, legs + r * 0.6), Vector2(r, h), Vector2(r * 0.15, h + r * 0.5)]), col, MeshKit.at(p.x, 0, p.z), 10)
	for i in 3:
		k.cyl(r + 0.012, 0.03, col.darkened(0.15), MeshKit.at(p.x, legs + r * 0.6 + (h - legs - r * 0.6) * (i + 1) / 4.0, p.z), 10, 0.0, -1.0, false)
	if band.a > 0.0:
		k.cyl(r + 0.015, 0.12, band, MeshKit.at(p.x, h - 0.4, p.z), 10, 0.0, -1.0, false)
	ArchKit.ladder(k, MeshKit.at(p.x, legs, p.z + r - 0.08), h - legs, Pal.STEEL_DARK)


static func _silicon(k: MeshKit, t: int) -> void:
	var sand := Color(0.88, 0.8, 0.58)
	var hot := Color(1.0, 0.6, 0.3, 0.35)
	match t:
		0:
			# a sand heap with a shovel, a home-built brick furnace with a
			# smoking chimney, firewood, sandbags, a tarp over more sand
			k.ellipsoid(Vector3(0.75, 0.45, 0.38), sand, MeshKit.at(-2.0, 0.0, -2.48), 10, 5)
			k.ellipsoid(Vector3(0.4, 0.3, 0.3), sand.darkened(0.06), MeshKit.at(-2.55, 0.0, -2.1), 8, 4)
			ln(k, Vector3(-1.8, 0.3, -2.4), Vector3(-1.6, 0.9, -2.3), 0.03, Pal.WOOD)
			k.box(Vector3(0.16, 0.2, 0.03), Pal.STEEL_DARK, MeshKit.xf(Vector3(-1.84, 0.22, -2.42), Vector3(-20, 0, 15)))
			# furnace
			var fx := 0.1
			for j in 6:
				for i in 6:
					var off := 0.08 if j % 2 else 0.0
					k.box(Vector3(0.16, 0.1, 0.56), Pal.BRICK if (i + j) % 3 else Pal.BRICK_DARK, MeshKit.at(fx - 0.45 + i * 0.17 + off, 0.05 + j * 0.105, -2.5))
			k.box(Vector3(1.1, 0.06, 0.62), Color(0.5, 0.48, 0.46), MeshKit.at(fx, 0.66, -2.5))
			k.box(Vector3(0.3, 0.22, 0.04), hot, MeshKit.at(fx - 0.15, 0.22, -2.2))
			k.box(Vector3(0.36, 0.04, 0.06), Color(0.3, 0.3, 0.32), MeshKit.at(fx - 0.15, 0.36, -2.2))
			k.cyl(0.09, 1.3, Color(0.36, 0.36, 0.38), MeshKit.at(fx + 0.3, 0.68, -2.55), 8)
			k.cyl(0.12, 0.05, Color(0.3, 0.3, 0.32), MeshKit.at(fx + 0.3, 1.98, -2.55), 8)
			for i in 3:
				k.sphere(0.12 + i * 0.04, Color(0.86, 0.86, 0.84), MeshKit.at(fx + 0.3 + i * 0.08, 2.15 + i * 0.22, -2.55 + i * 0.05), 7, 4)
			# firewood stack
			for j in 3:
				for i in 5 - j:
					k.cyl(0.05, 0.5, Pal.WOOD if i % 2 else Pal.WOOD_DARK, MeshKit.xf(Vector3(1.0 + i * 0.1 + j * 0.05, 0.05 + j * 0.09, -2.55), Vector3(90, 0, 0)) * MeshKit.at(0, -0.25, 0), 6)
			# sandbags and a tarp heap in the right wing
			for j in 3:
				for i in 3 - j:
					k.box(Vector3(0.3, 0.12, 0.2), Color(0.76, 0.66, 0.46), MeshKit.xf(Vector3(2.52, 0.06 + j * 0.12, -2.6 + i * 0.22 + j * 0.11), Vector3(0, 90 + i * 7.0, 0)))
			k.ellipsoid(Vector3(0.3, 0.3, 0.42), Color(0.26, 0.46, 0.78), MeshKit.at(2.52, 0.0, -1.6), 8, 4)
			k.box(Vector3(0.2, 0.2, 0.2), Color(0.62, 0.64, 0.66), MeshKit.at(2.5, 0.1, -1.05))
			# sieve on sawhorses, buckets in the left wing
			for z in [-1.8, -1.3]:
				ln(k, Vector3(-2.65, 0, z), Vector3(-2.52, 0.45, z), 0.03, Pal.WOOD)
				ln(k, Vector3(-2.39, 0, z), Vector3(-2.52, 0.45, z), 0.03, Pal.WOOD)
			k.box(Vector3(0.44, 0.06, 0.7), Pal.WOOD_LIGHT, MeshKit.at(-2.52, 0.48, -1.55))
			k.box(Vector3(0.36, 0.01, 0.6), Color(0.5, 0.52, 0.54), MeshKit.at(-2.52, 0.51, -1.55))
			for z in [-1.15, -0.98]:
				k.cyl(0.08, 0.16, Color(0.86, 0.5, 0.2), MeshKit.at(-2.55, 0, z), 8, 0.0, 0.09)
			bulbs(k, Vector3(-2.85, 0.62, -1.0), Vector3(0.3, 1.2, -2.85), 10)
		1:
			# a sand hopper on steel legs feeding a conveyor, a container lab,
			# a caged rack of argon cylinders, pallets of sand sacks
			var steel := Color(0.6, 0.62, 0.66)
			var hp := Vector3(2.4, 0, -2.42)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					bx(k, Vector3(hp.x + sx * 0.3 - 0.03, 0, hp.z + sz * 0.3 - 0.03), Vector3(hp.x + sx * 0.3 + 0.03, 1.3, hp.z + sz * 0.3 + 0.03), Color(0.96, 0.76, 0.2))
				ln(k, hp + Vector3(sx * 0.3, 0.1, -0.3), hp + Vector3(-sx * 0.3, 1.0, -0.3), 0.025, Color(0.96, 0.76, 0.2))
			k.cyl(0.4, 0.5, steel, MeshKit.xf(hp + Vector3(0, 1.6, 0), Vector3(180, 45, 0)), 4, 0.0, 0.08)
			bx(k, hp + Vector3(-0.38, 1.6, -0.38), hp + Vector3(0.38, 2.1, 0.38), steel)
			k.ellipsoid(Vector3(0.34, 0.12, 0.34), sand, MeshKit.at(hp.x, 2.1, hp.z), 8, 3)
			ArchKit.ladder(k, MeshKit.xf(hp + Vector3(-0.3, 0, 0.32), Vector3(0, 0, 0)), 2.1, Color(0.96, 0.76, 0.2))
			# conveyor along the back from the hopper
			var c0 := Vector3(2.1, 0.75, -2.55)
			var c1 := Vector3(0.6, 0.45, -2.55)
			ln(k, c0, c1, 0.06, Color(0.2, 0.21, 0.24))
			for i in 6:
				var q := c0.lerp(c1, (i + 0.5) / 6.0)
				bx(k, Vector3(q.x - 0.02, 0, q.z - 0.18), Vector3(q.x + 0.02, q.y, q.z - 0.14), steel)
				bx(k, Vector3(q.x - 0.02, 0, q.z + 0.14), Vector3(q.x + 0.02, q.y, q.z + 0.18), steel)
				k.ellipsoid(Vector3(0.08, 0.03, 0.08), sand, MeshKit.at(q.x, q.y + 0.04, q.z), 6, 3)
			for sz in [-1.0, 1.0]:
				ln(k, c0 + Vector3(0, 0.04, sz * 0.16), c1 + Vector3(0, 0.04, sz * 0.16), 0.03, Color(0.96, 0.76, 0.2))
			# container lab
			container(k, MeshKit.at(-1.75, 0, -2.47), 2.0, Color(0.92, 0.92, 0.9))
			for i in 2:
				k.box(Vector3(0.4, 0.26, 0.04), Color(0.3, 0.32, 0.36), MeshKit.at(-2.3 + i * 0.6, 0.52, -2.13))
				k.box(Vector3(0.34, 0.2, 0.02), Color(0.6, 0.78, 0.88, 0.7), MeshKit.at(-2.3 + i * 0.6, 0.52, -2.11))
			ArchKit.door(k, MeshKit.at(-1.05, 0, -2.13), 1, 0.36, 0.7)
			ArchKit.ac_unit(k, MeshKit.at(-2.3, 0.82, -2.5), 1, 0.6)
			k.box(Vector3(0.5, 0.14, 0.03), Color(0.26, 0.46, 0.78), MeshKit.at(-1.75, 0.98, -2.2))
			# argon cylinders in a cage
			for i in 6:
				var cx := -0.45 + (i % 3) * 0.16
				var cz := -2.7 + (i / 3) * 0.18
				k.cyl(0.06, 0.62, [Color(0.3, 0.6, 0.36), Color(0.62, 0.64, 0.66)][i % 2], MeshKit.at(cx, 0, cz), 8)
				k.sphere(0.06, [Color(0.3, 0.6, 0.36), Color(0.62, 0.64, 0.66)][i % 2], MeshKit.at(cx, 0.62, cz), 6, 3)
			bx(k, Vector3(-0.58, 0, -2.82), Vector3(-0.54, 0.7, -2.5), steel)
			bx(k, Vector3(-0.12, 0, -2.82), Vector3(-0.08, 0.7, -2.5), steel)
			bx(k, Vector3(-0.58, 0.45, -2.5), Vector3(-0.08, 0.47, -2.48), Color(0.96, 0.76, 0.2))
			# sand sacks on pallets in the left wing
			for z in [-1.9, -1.3]:
				pallet(k, Vector3(-2.52, 0, z), 90)
				for j in 3:
					for i in 2:
						k.box(Vector3(0.24, 0.12, 0.42), Color(0.86, 0.82, 0.72), MeshKit.xf(Vector3(-2.64 + i * 0.25, 0.15 + j * 0.12, z), Vector3(0, j * 5.0, 0)))
			flood(k, Vector3(2.62, 0, -1.2), 2.2, 1, -130)
		2:
			# a white cleanroom building with an air-shower entrance and
			# screened HVAC, a white silo with a teal band, a nitrogen tank
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(1.0, 2.4, -2.22), 2, "f")
			bx(k, Vector3(-1.2, 0, -2.22), Vector3(-0.5, 1.2, -1.95), Color(0.95, 0.95, 0.96))
			ArchKit.curtain(k, MeshKit.at(-0.85, 0.1, -1.95), 0.6, 1.0, 2, 2, 1)
			k.box(Vector3(0.72, 0.06, 0.3), _c(2, "accent"), MeshKit.at(-0.85, 1.22, -2.08))
			bx(k, Vector3(-2.4, top, -2.72), Vector3(-0.2, top + 0.55, -2.3), Color(0.88, 0.9, 0.92))
			ArchKit.louvres(k, MeshKit.at(-1.3, top + 0.05, -2.29), 2.1, 0.45, Color(0.92, 0.93, 0.94), 6)
			for i in 3:
				k.cyl(0.08, 0.4, Color(0.86, 0.88, 0.9), MeshKit.at(0.1 + i * 0.3, top, -2.5), 8)
				k.cyl(0.11, 0.04, Color(0.8, 0.82, 0.84), MeshKit.at(0.1 + i * 0.3, top + 0.4, -2.5), 8)
			k.box(Vector3(1.0, 0.3, 0.05), Color(0.98, 0.98, 0.98), MeshKit.at(-1.8, top + 0.75, -2.3))
			for i in 3:
				k.box(Vector3(0.08, 0.08, 0.02), [Color(0.4, 0.42, 0.5), Color(0.5, 0.52, 0.6), Color(0.6, 0.62, 0.7)][i], MeshKit.xf(Vector3(-2.15 + i * 0.07, top + 0.75, -2.27), Vector3(0, 0, 45)))
			k.box(Vector3(0.45, 0.06, 0.02), _c(2, "dark"), MeshKit.at(-1.6, top + 0.78, -2.27))
			for i in 2:
				k.box(Vector3(0.05, 0.4, 0.05), Color(0.86, 0.88, 0.9), MeshKit.at(-2.15 + i * 0.7, top + 0.4, -2.3))
			silo(k, Vector3(2.4, 0, -2.45), 0.32, 2.9, Color(0.95, 0.95, 0.96), 0.5, _c(2, "accent"))
			pipe(k, [Vector3(2.4, 2.6, -2.45), Vector3(1.6, 2.6, -2.45), Vector3(1.0, 2.2, -2.45)], 0.05, Color(0.86, 0.88, 0.9))
			# nitrogen tank on saddles in the right wing
			htank(k, Vector3(2.53, 0, -1.55), 0.2, 0.9, Color(0.95, 0.95, 0.96), 90)
			k.box(Vector3(0.02, 0.1, 0.5), _c(2, "accent"), MeshKit.at(2.31, 0.45, -1.55))
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -0.95), 3, 2, true)
			ArchKit.planter(k, Vector3(2.52, 0, -1.05), 2, 0.42, false)
		3:
			# two tall sand silos with a catwalk, an inclined conveyor truss to
			# the furnace hall, an argon tank, a stair tower
			var gr := Color(0.62, 0.65, 0.7)
			silo(k, Vector3(-2.42, 0, -2.45), 0.34, 3.6, gr, 0.7, LED3)
			silo(k, Vector3(-1.68, 0, -2.5), 0.3, 3.2, gr.darkened(0.08), 0.7)
			ArchKit.catwalk(k, Vector3(-2.42, 3.62, -2.2), Vector3(-1.68, 3.3, -2.2), 0.25, 3, false)
			var top := hall(k, Vector3(-1.2, 0, -2.8), Vector3(1.7, 2.1, -2.22), "f")
			var a := Vector3(-1.68, 3.2, -2.5)
			var b := Vector3(0.3, top + 0.2, -2.5)
			ArchKit.truss(k, a, b, 0.22, Color(0.98, 0.8, 0.22))
			ln(k, a + Vector3(0, 0.14, 0), b + Vector3(0, 0.14, 0), 0.08, Color(0.2, 0.21, 0.24))
			for i in 2:
				k.cyl(0.14, 0.9, Color(0.3, 0.32, 0.36), MeshKit.at(0.8 + i * 0.5, top, -2.5), 8)
				k.torus(0.14, 0.02, Color(1.0, 0.6, 0.3, 0.4), MeshKit.at(0.8 + i * 0.5, top + 0.9, -2.5), 10, 3)
			ArchKit.door(k, MeshKit.at(0.2, 0, -2.22), 3, 0.5, 0.9)
			k.box(Vector3(1.4, 0.06, 0.02), Color(1.0, 0.6, 0.3, 0.4), MeshKit.at(0.25, 0.25, -2.2))
			# argon tank and stair tower in the right wing
			htank(k, Vector3(2.53, 0, -1.45), 0.22, 0.9, Color(0.86, 0.88, 0.9), 90)
			pipe(k, [Vector3(2.53, 0.7, -1.9), Vector3(2.53, 1.4, -1.9), Vector3(1.7, 1.4, -2.3)], 0.05, Color(0.3, 0.6, 0.36))
			for x in [2.2, 2.8]:
				for z in [-2.8, -2.25]:
					bx(k, Vector3(x - 0.03, 0, z - 0.03), Vector3(x + 0.03, 2.5, z + 0.03), Color(0.98, 0.8, 0.22))
			for i in 5:
				k.box(Vector3(0.56, 0.04, 0.26), Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(2.5, 0.25 + i * 0.5, -2.52), Vector3(0, 0, 20 if i % 2 else -20)))
			bx(k, Vector3(2.15, 2.5, -2.85), Vector3(2.85, 2.55, -2.2), Color(0.5, 0.52, 0.56))
			ArchKit.beacon(k, Vector3(2.5, 2.55, -2.5), 0.3)
			# sand sacks and a cabinet in the left wing
			cabinet(k, Vector3(-2.52, 0, -1.25), Vector3(0.42, 0.9, 0.36), Color(0.32, 0.35, 0.4), LED3, 90)
			for j in 2:
				k.box(Vector3(0.42, 0.14, 0.3), Color(0.86, 0.82, 0.72), MeshKit.at(-2.52, 0.07 + j * 0.14, -1.8))
		4:
			# a graphite foundry with glowing brass chimneys, a giant glowing
			# boule in a brass frame, wing towers joined by a glowing bridge
			var top := monolith(k, Vector3(-2.2, 0, -2.8), Vector3(2.2, 1.5, -2.2), "f", 0.34)
			for x in [-1.6, 1.6]:
				k.cyl(0.13, 3.4, Pal.BRASS, MeshKit.at(x, top, -2.5), 8, 0.0, 0.1)
				k.torus(0.12, 0.03, Color(1.0, 0.6, 0.3, 0.3), MeshKit.at(x, top + 3.4, -2.5), 10, 3)
				for i in 3:
					k.cyl(0.14, 0.04, GRAPH, MeshKit.at(x, top + 0.8 + i * 0.9, -2.5), 8, 0.0, -1.0, false)
			# the boule
			for i in 6:
				var a := TAU * i / 6.0
				k.box(Vector3(0.04, 1.8, 0.04), Pal.BRASS, MeshKit.at(cos(a) * 0.32, top + 0.9, -2.5 + sin(a) * 0.26))
			k.torus(0.33, 0.03, Pal.BRASS, MeshKit.at(0, top + 0.05, -2.5), 14, 3)
			k.torus(0.33, 0.03, Pal.BRASS, MeshKit.at(0, top + 1.8, -2.5), 14, 3)
			k.capsule(0.2, 1.4, Color(1.0, 0.72, 0.42, 0.35), MeshKit.at(0, top + 0.2, -2.5), 10, 3)
			k.cone(0.06, 0.4, Pal.BRASS, MeshKit.at(0, top + 1.8, -2.5), 6)
			ArchKit.beacon(k, Vector3(0, top + 2.2, -2.5), 0.2)
			# wing towers and the bridge carrying glowing wafers
			monolith(k, Vector3(-2.8, 0, -2.8), Vector3(-2.26, 2.6, -1.0), "r", 0.32)
			monolith(k, Vector3(2.26, 0, -2.8), Vector3(2.8, 2.6, -1.0), "l", 0.32)
			bx(k, Vector3(-2.3, 2.3, -2.8), Vector3(2.3, 2.42, -2.6), GRAPH2)
			bx(k, Vector3(-2.3, 2.42, -2.82), Vector3(2.3, 2.45, -2.58), Pal.BRASS)
			for i in 12:
				k.box(Vector3(0.14, 0.02, 0.14), Color(0.6, 0.62, 0.9, 0.45), MeshKit.xf(Vector3(-2.1 + i * 0.38, 2.47, -2.7), Vector3(0, 45, 0)))
			ArchKit.drone_pad(k, Vector3(2.53, 2.62, -1.8), 0.24)
			ArchKit.beacon(k, Vector3(-2.53, 2.6, -1.2), 0.4)
			for sx in [-1.0, 1.0]:
				glow_pipe(k, [Vector3(sx * 2.2, 0.09, -1.1), Vector3(sx * 2.2, 0.09, -2.15)], 0.04, Color(1.0, 0.7, 0.4, 0.4))


# ---------------------------------------------------------------- copper

## Rails with sleepers from a to b, at ground level.
static func rails(k: MeshKit, a: Vector3, b: Vector3, steel := Color(0.5, 0.5, 0.52)) -> void:
	var d := (b - a)
	var side := Vector3(d.z, 0, -d.x).normalized() * 0.12
	var n := int(d.length() / 0.18)
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		ln(k, q - side * 1.5 + Vector3(0, 0.08, 0), q + side * 1.5 + Vector3(0, 0.08, 0), 0.035, Pal.WOOD_DARK)
	for s in [-1.0, 1.0]:
		ln(k, a + side * s + Vector3(0, 0.11, 0), b + side * s + Vector3(0, 0.11, 0), 0.025, steel)


## A little ore cart on rails at p.
static func ore_cart(k: MeshKit, p: Vector3, yaw: float, ore: Color, col := Color(0.4, 0.42, 0.46)) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.3, 0.18, 0.42), col, tf * MeshKit.at(0, 0.24, 0))
	k.box(Vector3(0.32, 0.03, 0.44), col.darkened(0.2), tf * MeshKit.at(0, 0.33, 0))
	k.ellipsoid(Vector3(0.13, 0.08, 0.18), ore, tf * MeshKit.at(0, 0.34, 0), 7, 3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.05, 0.03, Color(0.15, 0.15, 0.16), tf * MeshKit.xf(Vector3(sx * 0.13, 0.13, sz * 0.13), Vector3(0, 0, 90)), 8)


## A sheave wheel standing in the plane given by yaw.
static func sheave(k: MeshKit, p: Vector3, r: float, col: Color, yaw := 0.0) -> void:
	k.torus(r, r * 0.08, col, MeshKit.xf(p, Vector3(90, yaw, 0)), 14, 3)
	for i in 4:
		k.box(Vector3(r * 2.0, 0.03, 0.03), col, MeshKit.xf(p, Vector3(0, yaw, i * 45.0)))
	k.cyl(r * 0.15, 0.08, col.darkened(0.2), MeshKit.xf(p, Vector3(90, yaw, 0)) * MeshKit.at(0, -0.04, 0), 6)


static func _copper(k: MeshKit, t: int) -> void:
	var ore := Color(0.84, 0.5, 0.3)
	var rock := Color(0.5, 0.47, 0.44)
	match t:
		0:
			# a hand-dug mine in a rock mound with timber props, rails and a
			# cart, a windlass over a shaft, a tent with a campfire
			k.ellipsoid(Vector3(1.0, 1.0, 0.6), rock, MeshKit.at(1.9, 0.0, -2.75), 10, 6)
			k.ellipsoid(Vector3(0.5, 0.6, 0.4), rock.lightened(0.05), MeshKit.at(2.55, 0.0, -2.3), 8, 4)
			bx(k, Vector3(1.65, 0, -2.25), Vector3(2.15, 0.62, -2.2), Color(0.12, 0.1, 0.09))
			for sx in [-1.0, 1.0]:
				bx(k, Vector3(1.9 + sx * 0.3 - 0.05, 0, -2.2), Vector3(1.9 + sx * 0.3 + 0.05, 0.72, -2.1), Pal.WOOD)
			bx(k, Vector3(1.52, 0.68, -2.22), Vector3(2.28, 0.78, -2.08), Pal.WOOD)
			k.box(Vector3(0.06, 0.08, 0.06), _lit(WARM, 0.3), MeshKit.at(2.1, 0.6, -2.05))
			rails(k, Vector3(2.25, 0, -2.1), Vector3(2.5, 0, -1.0))
			ore_cart(k, Vector3(2.38, 0.0, -1.55), 13, ore)
			for i in 5:
				_rock(k, Vector3(1.3 + i * 0.1, 0.0, -2.35 + (i % 2) * 0.1), 0.1, rock.darkened(0.1 * (i % 2)))
			# windlass over the shaft
			bx(k, Vector3(-0.3, 0, -2.75), Vector3(0.5, 0.12, -2.25), Pal.WOOD_DARK)
			bx(k, Vector3(-0.2, 0.0, -2.65), Vector3(0.4, 0.13, -2.35), Color(0.1, 0.09, 0.08))
			for x in [-0.25, 0.45]:
				bx(k, Vector3(x - 0.04, 0, -2.54), Vector3(x + 0.04, 0.7, -2.46), Pal.WOOD)
			k.cyl(0.06, 0.66, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(-0.28, 0.66, -2.5), Vector3(0, 0, -90)), 8)
			ln(k, Vector3(0.45, 0.66, -2.5), Vector3(0.6, 0.55, -2.5), 0.03, Pal.WOOD_DARK)
			ln(k, Vector3(0.1, 0.62, -2.5), Vector3(0.1, 0.3, -2.5), 0.012, Color(0.8, 0.74, 0.6))
			k.cyl(0.08, 0.12, Color(0.6, 0.62, 0.64), MeshKit.at(0.1, 0.18, -2.5), 8, 0.0, 0.09)
			# tent and campfire on the left
			var tc := Vector3(-2.15, 0, -2.5)
			for s in [-1.0, 1.0]:
				k.box(Vector3(1.0, 0.03, 0.46), Color(0.42, 0.56, 0.36), MeshKit.xf(tc + Vector3(0, 0.3, s * 0.15), Vector3(s * 52.0, 0, 0)))
			k.box(Vector3(0.04, 0.6, 0.04), Pal.WOOD, MeshKit.at(tc.x + 0.5, 0.3, tc.z))
			for i in 4:
				k.cyl(0.03, 0.3, Pal.WOOD_DARK, MeshKit.xf(Vector3(-1.35, 0.05, -2.3), Vector3(90, i * 45.0, 0)) * MeshKit.at(0, -0.15, 0), 5)
			k.cone(0.1, 0.22, Color(1.0, 0.6, 0.2, 0.3), MeshKit.at(-1.35, 0.06, -2.3), 6)
			for i in 6:
				var a := TAU * i / 6.0
				_rock(k, Vector3(-1.35 + cos(a) * 0.18, 0, -2.3 + sin(a) * 0.18), 0.06, Pal.STONE_DARK)
			# picks, buckets and ore in the left wing
			for i in 2:
				ln(k, Vector3(-2.75, 0, -1.7 + i * 0.2), Vector3(-2.7, 0.6, -1.75 + i * 0.2), 0.025, Pal.WOOD)
				k.box(Vector3(0.03, 0.03, 0.26), Pal.STEEL_DARK, MeshKit.at(-2.7, 0.6, -1.75 + i * 0.2))
			k.ellipsoid(Vector3(0.24, 0.16, 0.3), ore.darkened(0.2), MeshKit.at(-2.5, 0.0, -1.2), 8, 4)
			bulbs(k, Vector3(-1.6, 0.6, -2.5), Vector3(1.5, 0.9, -2.2), 10)
		1:
			# a timber-and-steel headframe over the shaft, a winch container
			# paying cable to its sheave, rails to an ore bin, a compressor
			var hp := Vector3(0.2, 0, -2.5)
			for sx in [-1.0, 1.0]:
				ln(k, hp + Vector3(sx * 0.45, 0, 0.22), hp + Vector3(sx * 0.12, 2.5, 0), 0.07, Pal.WOOD)
				ln(k, hp + Vector3(sx * 0.45, 0, -0.26), hp + Vector3(sx * 0.12, 2.5, 0), 0.07, Pal.WOOD)
				for i in 3:
					var y := 0.5 + i * 0.6
					ln(k, hp + Vector3(sx * (0.45 - y * 0.13), y, 0.22 - y * 0.08), hp + Vector3(sx * (0.45 - (y + 0.6) * 0.13), y + 0.6, -0.26 + (y + 0.6) * 0.1), 0.03, Pal.WOOD_DARK)
			bx(k, hp + Vector3(-0.2, 2.45, -0.1), hp + Vector3(0.2, 2.55, 0.1), Pal.STEEL_DARK)
			sheave(k, hp + Vector3(0, 2.7, 0), 0.24, Color(0.86, 0.3, 0.26), 90)
			bx(k, hp + Vector3(-0.3, 0, -0.3), hp + Vector3(0.3, 0.14, 0.3), Color(0.5, 0.48, 0.46))
			bx(k, hp + Vector3(-0.16, 0.2, -0.12), hp + Vector3(0.16, 0.5, 0.12), Color(0.96, 0.76, 0.2))
			ln(k, hp + Vector3(0, 2.7, 0), hp + Vector3(0, 0.5, 0), 0.015, Color(0.2, 0.2, 0.22))
			# winch container
			container(k, MeshKit.at(-1.85, 0, -2.47), 1.8, Color(0.36, 0.5, 0.38))
			k.cyl(0.18, 0.4, Color(0.2, 0.21, 0.24), MeshKit.xf(Vector3(-0.95, 0.4, -2.47), Vector3(0, 0, 90)), 10)
			ln(k, Vector3(-1.0, 0.55, -2.47), hp + Vector3(0, 2.92, 0), 0.015, Color(0.2, 0.2, 0.22))
			ArchKit.rollup(k, MeshKit.at(-2.1, 0, -2.13), 0.6, 0.62, Color(0.86, 0.87, 0.88), 0.3)
			# rails to an ore bin in the right corner
			rails(k, hp + Vector3(0.3, 0, 0.15), Vector3(2.0, 0, -2.3))
			ore_cart(k, Vector3(1.2, 0, -2.4), 78, ore)
			ArchKit.planks(k, MeshKit.at(2.45, 0, -2.75), 0.7, 0.6, Pal.WOOD_LIGHT)
			for sx in [-1.0, 1.0]:
				ArchKit.planks(k, MeshKit.xf(Vector3(2.45 + sx * 0.35, 0, -2.45), Vector3(0, sx * 90, 0)), 0.6, 0.6, Pal.WOOD)
			k.ellipsoid(Vector3(0.3, 0.4, 0.26), ore, MeshKit.at(2.45, 0.2, -2.45), 8, 4)
			# compressor and drill rods in the left wing
			k.box(Vector3(0.36, 0.3, 0.6), Color(0.96, 0.76, 0.2), MeshKit.at(-2.52, 0.25, -1.55))
			for sz in [-1.0, 1.0]:
				k.cyl(0.08, 0.06, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(-2.33, 0.09, -1.55 + sz * 0.2), Vector3(0, 0, 90)), 8)
			k.cyl(0.04, 0.2, Color(0.3, 0.3, 0.32), MeshKit.at(-2.45, 0.4, -1.4), 6)
			for i in 5:
				ln(k, Vector3(-2.75 + i * 0.05, 0.0, -1.05), Vector3(-2.72 + i * 0.05, 1.0, -1.15), 0.025, Pal.STEEL_DARK)
			flood(k, Vector3(2.62, 0, -1.5), 2.2, 1, -130)
		2:
			# a white steel headframe with a teal sheave, an inclined conveyor
			# into a white processing building, white ore bins, planters
			var hp := Vector3(-1.3, 0, -2.5)
			lattice(k, hp + Vector3(-0.35, 0, 0), 2.8, 0.26, Color(0.94, 0.95, 0.96), 0.7)
			lattice(k, hp + Vector3(0.35, 0, 0), 2.8, 0.26, Color(0.94, 0.95, 0.96), 0.7)
			bx(k, hp + Vector3(-0.5, 2.75, -0.12), hp + Vector3(0.5, 2.85, 0.12), Color(0.94, 0.95, 0.96))
			sheave(k, hp + Vector3(0, 3.1, 0), 0.26, _c(2, "accent"), 90)
			ln(k, hp + Vector3(-0.35, 0, 0.5), hp + Vector3(0, 2.8, 0), 0.06, Color(0.94, 0.95, 0.96))
			bx(k, hp + Vector3(-0.3, 0, -0.3), hp + Vector3(0.3, 0.2, 0.3), Color(0.9, 0.9, 0.9))
			var top := pavilion(k, Vector3(0.3, 0, -2.8), Vector3(2.8, 2.3, -2.22), 2, "f")
			ArchKit.truss(k, hp + Vector3(0.4, 2.0, 0), Vector3(0.4, top - 0.4, -2.5), 0.2, Color(0.94, 0.95, 0.96))
			ArchKit.door(k, MeshKit.at(2.2, 0, -2.22), 2, 0.5, 0.95)
			k.box(Vector3(1.0, 0.3, 0.05), Color(0.98, 0.98, 0.98), MeshKit.at(1.5, top + 0.4, -2.26))
			k.cyl(0.1, 0.03, ore, MeshKit.xf(Vector3(1.15, top + 0.4, -2.22), Vector3(90, 0, 0)), 8)
			k.box(Vector3(0.5, 0.06, 0.02), _c(2, "dark"), MeshKit.at(1.6, top + 0.42, -2.22))
			ArchKit.ac_unit(k, MeshKit.at(0.8, top, -2.55), 2, 0.7)
			ArchKit.solar(k, MeshKit.at(2.0, top, -2.55), 2, 2, 20.0, 0.3)
			# ore bins in the left corner
			for i in 2:
				var bxp := Vector3(-2.55, 0, -2.6 + i * 0.6)
				bx(k, bxp + Vector3(-0.25, 0, -0.25), bxp + Vector3(0.25, 0.5, 0.25), Color(0.92, 0.92, 0.92))
				bx(k, bxp + Vector3(-0.26, 0.42, -0.26), bxp + Vector3(0.26, 0.48, 0.26), _c(2, "accent"))
				k.ellipsoid(Vector3(0.2, 0.12, 0.2), ore, MeshKit.at(bxp.x, 0.5, bxp.z), 8, 3)
			planters(k, Vector3(-2.52, 0, -1.4), Vector3(-2.52, 0, -0.95), 1, 2, true)
			planters(k, Vector3(2.52, 0, -2.05), Vector3(2.52, 0, -0.95), 2, 2, true)
		3:
			# a big steel headframe with twin sheaves and a back-stay, a winder
			# hall, a conveyor gantry to ore bins, a stair tower
			var hp := Vector3(-2.2, 0, -2.5)
			var steel := Color(0.4, 0.43, 0.48)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					bx(k, hp + Vector3(sx * 0.3 - 0.04, 0, sz * 0.25 - 0.04), hp + Vector3(sx * 0.3 + 0.04, 3.8, sz * 0.25 + 0.04), steel)
			for i in 6:
				var y := 0.3 + i * 0.6
				for sz in [-1.0, 1.0]:
					ln(k, hp + Vector3(-0.3, y, sz * 0.25), hp + Vector3(0.3, y + 0.6, sz * 0.25), 0.03, steel)
				bx(k, hp + Vector3(-0.34, y, -0.29), hp + Vector3(0.34, y + 0.04, 0.29), steel)
			ln(k, hp + Vector3(0.3, 3.6, 0), Vector3(-0.6, 0, -2.5), 0.08, steel)
			bx(k, hp + Vector3(-0.4, 3.8, -0.32), hp + Vector3(0.4, 3.9, 0.32), steel.darkened(0.2))
			sheave(k, hp + Vector3(0, 4.15, -0.12), 0.32, Color(0.98, 0.8, 0.22), 90)
			sheave(k, hp + Vector3(0, 4.15, 0.12), 0.32, Color(0.98, 0.8, 0.22), 90)
			ArchKit.beacon(k, hp + Vector3(0, 4.5, 0), 0.2)
			var top := hall(k, Vector3(-1.5, 0, -2.8), Vector3(0.9, 1.9, -2.22), "f")
			ln(k, hp + Vector3(0, 4.15, 0), Vector3(-0.6, top + 0.2, -2.5), 0.02, Color(0.2, 0.2, 0.22))
			k.cyl(0.25, 0.5, Color(0.2, 0.21, 0.24), MeshKit.xf(Vector3(-0.85, top + 0.2, -2.5), Vector3(0, 0, 90)), 10)
			# ore bins in the right corner and the gantry
			for i in 2:
				var bp := Vector3(1.5 + i * 0.75, 0, -2.5)
				for sx in [-1.0, 1.0]:
					bx(k, bp + Vector3(sx * 0.25 - 0.03, 0, -0.03), bp + Vector3(sx * 0.25 + 0.03, 1.0, 0.03), Color(0.98, 0.8, 0.22))
				k.cyl(0.32, 0.4, steel, MeshKit.xf(bp + Vector3(0, 1.4, 0), Vector3(180, 45, 0)), 4, 0.0, 0.08)
				bx(k, bp + Vector3(-0.3, 1.4, -0.3), bp + Vector3(0.3, 1.9, 0.3), steel)
				k.box(Vector3(0.62, 0.02, 0.02), _lit(LED3, 0.45), MeshKit.at(bp.x, 1.7, bp.z + 0.31))
			ArchKit.truss(k, Vector3(0.9, top - 0.2, -2.5), Vector3(1.5, 2.0, -2.5), 0.2, Color(0.98, 0.8, 0.22))
			bx(k, Vector3(1.2, 1.9, -2.62), Vector3(2.6, 1.98, -2.38), Color(0.2, 0.21, 0.24))
			# right wing: a crusher and a pile
			bx(k, Vector3(2.3, 0, -1.9), Vector3(2.8, 0.7, -1.3), steel)
			ArchKit.louvres(k, MeshKit.xf(Vector3(2.29, 0.1, -1.6), Vector3(0, -90, 0)), 0.4, 0.4, steel.darkened(0.15), 5)
			k.ellipsoid(Vector3(0.24, 0.2, 0.3), ore.darkened(0.15), MeshKit.at(2.53, 0, -1.05), 8, 4)
			cabinet(k, Vector3(-2.52, 0, -1.3), Vector3(0.42, 0.9, 0.36), steel, LED3, 90)
			flood(k, Vector3(-2.62, 0, -1.8), 2.8, 3, 140)
		4:
			# a graphite headframe tower with brass sheaves and glowing cables,
			# halls with glowing fins, stacks of glowing copper ingots
			var zc := -2.5
			monolith(k, Vector3(-0.42, 0, zc - 0.3), Vector3(0.42, 4.6, zc + 0.3), "f", 0.2)
			bx(k, Vector3(-0.55, 4.6, zc - 0.32), Vector3(0.55, 4.75, zc + 0.32), GRAPH2)
			for sx in [-1.0, 1.0]:
				sheave(k, Vector3(sx * 0.25, 5.15, zc), 0.38, Pal.BRASS, 0)
				ln(k, Vector3(sx * 0.25, 4.8, zc + 0.05), Vector3(sx * 0.25, 0.4, zc + 0.36), 0.02, Color(1.0, 0.6, 0.3, 0.35))
			k.torus(0.5, 0.03, _lit(WARM, 0.3), MeshKit.at(0, 5.7, zc), 16, 3)
			ArchKit.beacon(k, Vector3(0, 5.6, zc), 0.4)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.6
				var xb: float = sx * 2.8
				var tp := monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.3, -2.22), "f", 0.34)
				for i in 3:
					var x: float = sx * (1.0 + i * 0.6)
					for j in 3:
						for m in 3:
							k.box(Vector3(0.22 if j % 2 == 0 else 0.08, 0.06, 0.08 if j % 2 == 0 else 0.22), Color(0.95, 0.56, 0.32, 0.6 if j < 2 else 0.4), MeshKit.at(x + (0.0 if j % 2 == 0 else (m - 1) * 0.07), tp + 0.03 + j * 0.06, -2.5 + ((m - 1) * 0.07 if j % 2 == 0 else 0.0)))
			# glowing ingot pallets in the wings
			for sx in [-1.0, 1.0]:
				for z in [-1.9, -1.3]:
					bx(k, Vector3(sx * 2.53 - 0.24, 0, z - 0.24), Vector3(sx * 2.53 + 0.24, 0.08, z + 0.24), Pal.BRASS)
					for j in 4:
						for m in 3:
							var along := j % 2 == 0
							k.box(Vector3(0.4 if along else 0.1, 0.07, 0.1 if along else 0.4), Color(0.95, 0.56, 0.32, 0.55 if j == 3 else 1.0), MeshKit.at(sx * 2.53 + (0.0 if along else (m - 1) * 0.13), 0.12 + j * 0.075, z + ((m - 1) * 0.13 if along else 0.0)))
				gtank(k, Vector3(sx * 2.53, 0, -2.5), 0.24, 1.5)


# ---------------------------------------------------------------- rare earth

static func _rock(k: MeshKit, p: Vector3, r: float, col: Color) -> void:
	k.ellipsoid(Vector3(r, r * 0.7, r * 0.9), col, MeshKit.at(p.x, p.y + r * 0.3, p.z), 6, 3)


static func _crystal(k: MeshKit, p: Vector3, h: float, col: Color, tilt := Vector3.ZERO) -> void:
	k.cone(h * 0.22, h, col, MeshKit.xf(p, tilt), 5)


static func _rare(k: MeshKit, t: int) -> void:
	var cs := [Color(0.76, 0.48, 0.86, 0.7), Color(0.5, 0.82, 0.78, 0.7), Color(0.94, 0.56, 0.72, 0.7), Color(0.62, 0.4, 0.88, 0.7)]
	var rock := Color(0.46, 0.44, 0.46)
	match t:
		0:
			# a rock outcrop bristling with crystals and a glowing cave mouth,
			# a prospector's tent, a sieve on sawhorses, crates of rocks
			for i in 6:
				var p := Vector3(-2.5 + i * 0.36, 0, -2.6 + (i % 2) * 0.12)
				k.ellipsoid(Vector3(0.36, 0.5 + (i % 3) * 0.2, 0.32), rock.darkened(0.04 * (i % 3)), MeshKit.at(p.x, 0, p.z), 8, 4)
			bx(k, Vector3(-1.75, 0, -2.3), Vector3(-1.3, 0.42, -2.26), Color(0.16, 0.1, 0.2))
			k.box(Vector3(0.36, 0.3, 0.02), Color(0.62, 0.4, 0.88, 0.4), MeshKit.at(-1.52, 0.2, -2.25))
			for i in 10:
				var a := i * 2.1
				_crystal(k, Vector3(-2.4 + fposmod(i * 0.43, 1.9), 0.25 + fposmod(i * 0.31, 0.4), -2.4 + fposmod(i * 0.17, 0.2)), 0.25 + fposmod(i * 0.29, 0.3), cs[i % 4], Vector3(sin(a) * 25, 0, cos(a) * 25))
			# tent
			var tc := Vector3(1.6, 0, -2.5)
			for s in [-1.0, 1.0]:
				k.box(Vector3(0.9, 0.03, 0.46), Color(0.82, 0.62, 0.36), MeshKit.xf(tc + Vector3(0, 0.3, s * 0.15), Vector3(s * 52.0, 0, 0)))
			k.box(Vector3(0.04, 0.6, 0.04), Pal.WOOD, MeshKit.at(tc.x - 0.45, 0.3, tc.z))
			k.box(Vector3(0.08, 0.1, 0.08), Color(0.3, 0.3, 0.32), MeshKit.at(0.9, 0.05, -2.4))
			k.box(Vector3(0.06, 0.06, 0.06), _lit(WARM, 0.3), MeshKit.at(0.9, 0.13, -2.4))
			# sieve and crates in the right wing
			for z in [-1.9, -1.4]:
				ln(k, Vector3(2.38, 0, z), Vector3(2.52, 0.45, z), 0.03, Pal.WOOD)
				ln(k, Vector3(2.66, 0, z), Vector3(2.52, 0.45, z), 0.03, Pal.WOOD)
			k.box(Vector3(0.44, 0.06, 0.7), Pal.WOOD_LIGHT, MeshKit.at(2.52, 0.48, -1.65))
			for i in 4:
				_crystal(k, Vector3(2.45 + (i % 2) * 0.12, 0.51, -1.85 + i * 0.12), 0.1, cs[i % 4])
			crates(k, Vector3(2.5, 0, -2.5), 3, 9, Color(0.72, 0.56, 0.38))
			crates(k, Vector3(-2.5, 0, -1.4), 2, 3, Color(0.66, 0.52, 0.36))
			bulbs(k, Vector3(-1.3, 0.9, -2.3), Vector3(2.85, 0.62, -1.2), 10, Color(0.85, 0.7, 1.0))
		1:
			# a settling pond, a row of IBC leach totes with hoses, a container
			# lab along the right fence, drums
			bx(k, Vector3(-2.8, 0, -2.82), Vector3(-0.6, 0.2, -2.22), Color(0.66, 0.65, 0.62))
			bx(k, Vector3(-2.7, 0.2, -2.72), Vector3(-0.7, 0.21, -2.32), Color(0.4, 0.62, 0.6))
			for i in 3:
				k.box(Vector3(0.1, 0.012, 0.3), Color(0.5, 0.74, 0.7), MeshKit.xf(Vector3(-2.3 + i * 0.6, 0.215, -2.52), Vector3(0, 30, 0)))
			k.box(Vector3(0.24, 0.24, 0.24), Color(0.3, 0.5, 0.36), MeshKit.at(-0.45, 0.12, -2.5))
			pipe(k, [Vector3(-0.45, 0.24, -2.5), Vector3(-0.45, 0.4, -2.5), Vector3(-1.0, 0.4, -2.5), Vector3(-1.0, 0.22, -2.5)], 0.04, Color(0.2, 0.2, 0.22))
			var steel := Color(0.6, 0.62, 0.66)
			for i in 3:
				var tc := Vector3(-0.0 + i * 0.6, 0, -2.5)
				k.box(Vector3(0.54, 0.08, 0.54), Pal.WOOD_LIGHT, MeshKit.at(tc.x, 0.04, tc.z))
				k.box(Vector3(0.5, 0.5, 0.5), Color(0.86, 0.9, 0.92, 0.9), MeshKit.at(tc.x, 0.33, tc.z))
				k.box(Vector3(0.44, 0.3, 0.44), Color(0.62, 0.4, 0.8), MeshKit.at(tc.x, 0.24, tc.z))
				for j in 4:
					k.box(Vector3(0.52, 0.02, 0.52), steel, MeshKit.at(tc.x, 0.1 + j * 0.15, tc.z))
				ln(k, Vector3(tc.x, 0.6, tc.z), Vector3(tc.x + 0.3, 0.75, tc.z - 0.2), 0.025, Color(0.2, 0.2, 0.22))
			ln(k, Vector3(0.3, 0.75, -2.7), Vector3(1.5, 0.75, -2.7), 0.025, Color(0.2, 0.2, 0.22))
			container(k, MeshKit.xf(Vector3(2.5, 0, -1.85), Vector3(0, 90, 0)), 1.7, Color(0.86, 0.87, 0.88))
			for i in 2:
				k.box(Vector3(0.04, 0.24, 0.36), Color(0.3, 0.32, 0.36), MeshKit.at(2.17, 0.52, -2.2 + i * 0.6))
				k.box(Vector3(0.02, 0.2, 0.3), Color(0.6, 0.78, 0.88, 0.7), MeshKit.at(2.15, 0.52, -2.2 + i * 0.6))
			ArchKit.ac_unit(k, MeshKit.xf(Vector3(2.5, 0.82, -1.5), Vector3(0, 90, 0)), 1, 0.55)
			k.box(Vector3(0.03, 0.12, 0.4), Color(0.62, 0.4, 0.88), MeshKit.at(2.16, 0.74, -1.85))
			for i in 4:
				barrel(k, Vector3(-2.6 + (i % 2) * 0.3, 0, -1.9 + (i / 2) * 0.32), [Color(0.62, 0.4, 0.8), Color(0.3, 0.46, 0.7)][i % 2], 0.13, 0.4)
			flood(k, Vector3(-2.62, 0, -1.1), 2.2, 1, 120)
		2:
			# a row of white mixer-settler tanks with teal lids and stirrers, a
			# white lab pavilion, planters
			for i in 5:
				var x := -2.5 + i * 0.6
				bx(k, Vector3(x - 0.26, 0, -2.78), Vector3(x + 0.26, 0.62, -2.26), Color(0.95, 0.95, 0.96))
				bx(k, Vector3(x - 0.28, 0.62, -2.8), Vector3(x + 0.28, 0.67, -2.24), _c(2, "accent"))
				k.cyl(0.07, 0.2, Color(0.86, 0.88, 0.9), MeshKit.at(x, 0.67, -2.52), 8)
				k.cyl(0.05, 0.1, Color(0.3, 0.32, 0.36), MeshKit.at(x, 0.87, -2.52), 8)
				k.box(Vector3(0.3, 0.2, 0.01), Color(0.6, 0.42, 0.86, 0.6), MeshKit.at(x, 0.35, -2.255))
				if i < 4:
					pipe(k, [Vector3(x + 0.26, 0.45, -2.4), Vector3(x + 0.34, 0.45, -2.4)], 0.04, Color(0.86, 0.88, 0.9))
			var top := pavilion(k, Vector3(0.7, 0, -2.8), Vector3(2.8, 2.2, -2.22), 2, "f")
			ArchKit.door(k, MeshKit.at(1.1, 0, -2.22), 2, 0.5, 0.95)
			k.box(Vector3(0.9, 0.3, 0.05), Color(0.98, 0.98, 0.98), MeshKit.at(1.8, top + 0.4, -2.26))
			for i in 3:
				_crystal(k, Vector3(1.48 + i * 0.07, top + 0.3, -2.22), 0.18, cs[i])
			k.box(Vector3(0.4, 0.06, 0.02), _c(2, "dark"), MeshKit.at(1.95, top + 0.42, -2.22))
			ArchKit.ac_unit(k, MeshKit.at(2.3, top, -2.55), 2, 0.7)
			k.cyl(0.04, 0.6, Color(0.86, 0.88, 0.9), MeshKit.at(1.0, top, -2.5), 6)
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -0.95), 3, 2, true)
			planters(k, Vector3(2.52, 0, -2.05), Vector3(2.52, 0, -0.95), 2, 2, false)
		3:
			# tall solvent-extraction columns with ladders and platforms, a dark
			# hall, pipe racks and tanks in the wings
			var steel := Color(0.62, 0.65, 0.7)
			for i in 4:
				var x := -2.45 + i * 0.6
				var h := 3.0 + (i % 2) * 0.7
				k.cyl(0.2, h, steel, MeshKit.at(x, 0, -2.5), 10)
				k.sphere(0.2, steel, MeshKit.xf(Vector3(x, h, -2.5), Vector3.ZERO, Vector3(1, 0.5, 1)), 10, 4)
				for j in 3:
					k.cyl(0.215, 0.04, steel.darkened(0.2), MeshKit.at(x, 0.8 + j * 0.9, -2.5), 10, 0.0, -1.0, false)
				k.cyl(0.21, 0.03, Color(0.7, 0.45, 1.0, 0.4), MeshKit.at(x, h - 0.4, -2.5), 10, 0.0, -1.0, false)
				ArchKit.ladder(k, MeshKit.at(x, 0, -2.3), h, Color(0.98, 0.8, 0.22), true)
			ArchKit.catwalk(k, Vector3(-2.7, 2.2, -2.2), Vector3(-0.4, 2.2, -2.2), 0.24, 3, false)
			var top := hall(k, Vector3(0.0, 0, -2.8), Vector3(2.0, 2.0, -2.22), "f")
			roof3(k, 0.1, 1.9, -2.5, top)
			ArchKit.pipe_rack(k, MeshKit.xf(Vector3(2.53, 0, -1.6), Vector3(0, 90, 0)), 1.2, 1.4, 3, 3)
			ArchKit.tank(k, MeshKit.at(2.52, 0, -2.5), 0.24, 1.2, Color(0.86, 0.88, 0.9), 3)
			for z in [-1.9, -1.35]:
				ArchKit.tank(k, MeshKit.at(-2.52, 0, z), 0.2, 0.8, Color(0.5, 0.4, 0.62), 3)
			pipe(k, [Vector3(-2.52, 0.9, -1.35), Vector3(-2.52, 1.2, -1.35), Vector3(-2.52, 1.2, -2.2)], 0.05, Color(0.62, 0.4, 0.88))
			flood(k, Vector3(-2.62, 0, -1.0), 2.8, 3, 140)
		4:
			# a giant floating crystal in a brass cage on a graphite plinth,
			# graphite halls and wing towers, purple conduits
			var zc := -2.5
			k.cyl(0.36, 0.5, GRAPH, MeshKit.at(0, 0, zc), 8)
			k.cyl(0.3, 0.3, GRAPH2, MeshKit.at(0, 0.5, zc), 8)
			k.cyl(0.37, 0.03, Pal.BRASS, MeshKit.at(0, 0.5, zc), 8)
			k.cyl(0.26, 0.03, Color(0.76, 0.48, 0.86, 0.35), MeshKit.at(0, 0.8, zc), 8)
			k.cone(0.26, 1.8, Color(0.76, 0.48, 0.86, 0.45), MeshKit.at(0, 1.6, zc), 6)
			k.cone(0.26, 0.55, Color(0.76, 0.48, 0.86, 0.45), MeshKit.xf(Vector3(0, 1.6, zc), Vector3(180, 0, 0)), 6)
			for i in 4:
				var a := TAU * i / 4.0 + 0.4
				_crystal(k, Vector3(cos(a) * 0.22, 1.3, zc + sin(a) * 0.18), 0.6, cs[i % 4], Vector3(sin(a) * 30, 0, cos(a) * 30))
			for i in 8:
				var a2 := TAU * i / 8.0
				k.box(Vector3(0.03, 3.4, 0.03), Pal.BRASS, MeshKit.at(cos(a2) * 0.4, 2.2, zc + sin(a2) * 0.32))
			for y in [0.8, 2.2, 3.9]:
				k.torus(0.41, 0.025, Pal.BRASS, MeshKit.xf(Vector3(0, y, zc), Vector3.ZERO, Vector3(1, 1, 0.8)), 14, 3)
			k.torus(0.5, 0.02, Color(0.76, 0.48, 0.86, 0.35), MeshKit.xf(Vector3(0, 2.4, zc), Vector3(20, 0, 10), Vector3(1, 1, 0.7)), 16, 3)
			ArchKit.beacon(k, Vector3(0, 3.9, zc), 0.3)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.6
				var xb: float = sx * 2.25
				monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.2, -2.22), "f", 0.34)
				glow_pipe(k, [Vector3(sx * 0.6, 0.6, -2.5), Vector3(sx * 0.4, 0.6, -2.5)], 0.06, Color(0.76, 0.48, 0.86, 0.4))
			monolith(k, Vector3(-2.8, 0, -2.8), Vector3(-2.26, 2.4, -1.0), "r", 0.32)
			monolith(k, Vector3(2.26, 0, -2.8), Vector3(2.8, 2.4, -1.0), "l", 0.32)
			for sx in [-1.0, 1.0]:
				for i in 3:
					_crystal(k, Vector3(sx * 2.53 + (i - 1) * 0.1, 2.4, -1.8 + (i % 2) * 0.2), 0.3 + i * 0.1, cs[i])
				glow_pipe(k, [Vector3(sx * 2.15, 0.09, -1.1), Vector3(sx * 2.15, 0.09, -2.15)], 0.04, Color(0.76, 0.48, 0.86, 0.4))
			ArchKit.drone_pad(k, Vector3(-1.4, 1.22, -2.5), 0.26)


# ---------------------------------------------------------------- offices

## A bookshelf (back against -z at p), filled with books.
static func bookshelf(k: MeshKit, p: Vector3, w: float, h: float, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	var bc := [Color(0.6, 0.3, 0.3), Color(0.3, 0.4, 0.6), Color(0.86, 0.68, 0.32), Color(0.36, 0.5, 0.38), Color(0.9, 0.88, 0.82), Color(0.5, 0.36, 0.5)]
	k.box(Vector3(w, h, 0.04), col.darkened(0.15), tf * MeshKit.at(0, h * 0.5, -0.12))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, h, 0.26), col, tf * MeshKit.at(sx * w * 0.5, h * 0.5, 0))
	var rows := maxi(2, int(h / 0.3))
	for j in rows + 1:
		k.box(Vector3(w, 0.03, 0.26), col, tf * MeshKit.at(0, j * h / rows, 0))
	for j in rows:
		var n := int((w - 0.1) / 0.07)
		var x := -w * 0.5 + 0.06
		for i in n:
			var bh := h / rows * (0.6 + 0.3 * fposmod(i * 0.37 + j * 0.21, 1.0))
			k.box(Vector3(0.055, bh, 0.18), bc[(i * 7 + j * 3) % bc.size()], tf * MeshKit.at(x, j * h / rows + 0.015 + bh * 0.5, 0.02))
			x += 0.07


## A sofa facing +z (after yaw).
static func sofa(k: MeshKit, p: Vector3, w: float, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(w, 0.22, 0.46), col, tf * MeshKit.at(0, 0.15, 0))
	k.box(Vector3(w, 0.36, 0.14), col.darkened(0.06), tf * MeshKit.at(0, 0.38, -0.17))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.12, 0.32, 0.46), col.darkened(0.03), tf * MeshKit.at(sx * (w * 0.5 - 0.06), 0.24, 0))
	var n := maxi(1, int((w - 0.24) / 0.4))
	for i in n:
		k.box(Vector3((w - 0.24) / n - 0.02, 0.06, 0.36), col.lightened(0.08), tf * MeshKit.at(-(w - 0.24) * 0.5 + (i + 0.5) * (w - 0.24) / n, 0.29, 0.03))


## A rug.
static func rug(k: MeshKit, p: Vector3, s: Vector2, col: Color, yaw := 0.0) -> void:
	k.box(Vector3(s.x, 0.012, s.y), col, MeshKit.xf(p + Vector3(0, 0.077, 0), Vector3(0, yaw, 0)))
	k.box(Vector3(s.x - 0.12, 0.014, s.y - 0.12), col.lightened(0.12), MeshKit.xf(p + Vector3(0, 0.078, 0), Vector3(0, yaw, 0)))


## A floor lamp.
static func floor_lamp(k: MeshKit, p: Vector3, col := Color(0.3, 0.3, 0.32)) -> void:
	k.cyl(0.1, 0.02, col, MeshKit.at(p.x, p.y, p.z), 8)
	k.cyl(0.015, 1.2, col, MeshKit.at(p.x, p.y, p.z), 5)
	k.cyl(0.12, 0.16, _lit(WARM, 0.35), MeshKit.at(p.x, p.y + 1.15, p.z), 8, 0.0, 0.07)


## Bean bag.
static func beanbag(k: MeshKit, p: Vector3, col: Color) -> void:
	k.ellipsoid(Vector3(0.24, 0.18, 0.22), col, MeshKit.at(p.x, p.y + 0.12, p.z), 8, 4)


## A plastic / steel chair.
static func side_chair(k: MeshKit, p: Vector3, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.26, 0.03, 0.26), col, tf * MeshKit.at(0, 0.28, 0))
	k.box(Vector3(0.26, 0.26, 0.03), col, tf * MeshKit.at(0, 0.42, -0.12))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.025, 0.28, 0.025), col.darkened(0.2), tf * MeshKit.at(sx * 0.11, 0.14, sz * 0.11))


## A bicycle, side on (along local x).
static func bike(k: MeshKit, p: Vector3, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	for sx in [-1.0, 1.0]:
		k.torus(0.15, 0.015, Color(0.15, 0.15, 0.16), tf * MeshKit.xf(Vector3(sx * 0.26, 0.16, 0), Vector3(90, 0, 0)), 10, 3)
	ln(k, tf * Vector3(-0.26, 0.16, 0), tf * Vector3(0.0, 0.34, 0), 0.025, col)
	ln(k, tf * Vector3(0.26, 0.16, 0), tf * Vector3(0.0, 0.34, 0), 0.025, col)
	ln(k, tf * Vector3(-0.26, 0.16, 0), tf * Vector3(-0.08, 0.16, 0), 0.025, col)
	ln(k, tf * Vector3(-0.08, 0.16, 0), tf * Vector3(0.0, 0.34, 0), 0.025, col)
	ln(k, tf * Vector3(0.0, 0.34, 0), tf * Vector3(0.22, 0.42, 0), 0.025, col)
	k.box(Vector3(0.1, 0.03, 0.05), Color(0.15, 0.15, 0.16), tf * MeshKit.at(-0.06, 0.38, 0))


## A sawtooth factory roof over x0..x1 at y (teeth face +z with glass).
static func sawtooth(k: MeshKit, x0: float, x1: float, z0: float, z1: float, y: float, n: int, roof: Color, glass: Color) -> void:
	var d := (z1 - z0) / n
	for i in n:
		var za := z0 + i * d
		k.box(Vector3(x1 - x0, 0.04, d * 1.08), roof, MeshKit.xf(Vector3((x0 + x1) * 0.5, y + 0.18, za + d * 0.5), Vector3(-28, 0, 0)))
		k.box(Vector3(x1 - x0, 0.36, 0.03), glass, MeshKit.at((x0 + x1) * 0.5, y + 0.18, za + d - 0.015))


static func _code(k: MeshKit, t: int) -> void:
	var acc := Color(0.5, 0.42, 0.78)
	match t:
		0:
			# the garage: a plywood lean-to with a sofa, a fridge and a shelf
			# of old computers, a whiteboard, bean bags, a bike, a banner
			ply_shed(k, -2.8, 0.2, -2.8, -2.2, 1.4, 1.15)
			sofa(k, Vector3(-1.9, 0, -2.5), 1.1, Color(0.36, 0.5, 0.62))
			k.box(Vector3(0.36, 0.7, 0.34), Color(0.94, 0.94, 0.92), MeshKit.at(-0.95, 0.35, -2.58))
			k.box(Vector3(0.02, 0.2, 0.02), Color(0.6, 0.62, 0.64), MeshKit.at(-1.08, 0.5, -2.4))
			bx(k, Vector3(-0.7, 0.0, -2.76), Vector3(0.1, 0.9, -2.5), Pal.WOOD_LIGHT)
			for j in 2:
				bx(k, Vector3(-0.68, 0.3 + j * 0.3, -2.76), Vector3(0.08, 0.32 + j * 0.3, -2.5), Pal.WOOD)
				for i in 3:
					k.box(Vector3(0.2, 0.18, 0.2), Color(0.82, 0.8, 0.74), MeshKit.at(-0.55 + i * 0.26, 0.42 + j * 0.3, -2.64))
					k.box(Vector3(0.15, 0.12, 0.01), _lit(acc.lightened(0.3), 0.5), MeshKit.at(-0.55 + i * 0.26, 0.43 + j * 0.3, -2.535))
			# a banner across the shed
			k.box(Vector3(1.6, 0.24, 0.02), Color(0.94, 0.92, 0.86), MeshKit.xf(Vector3(-1.3, 1.05, -2.17), Vector3(0, 0, 1)))
			for i in 4:
				k.box(Vector3(0.22, 0.14, 0.01), acc if i % 2 == 0 else Color(0.86, 0.3, 0.26), MeshKit.at(-1.75 + i * 0.3, 1.05, -2.155))
			# whiteboard on an easel, bean bags
			for sx in [-1.0, 1.0]:
				ln(k, Vector3(0.9 + sx * 0.35, 0, -2.5), Vector3(0.9 + sx * 0.3, 1.2, -2.6), 0.03, Pal.WOOD)
			k.box(Vector3(0.8, 0.55, 0.03), Color(0.96, 0.97, 0.98), MeshKit.xf(Vector3(0.9, 0.85, -2.56), Vector3(-6, 0, 0)))
			for i in 5:
				k.box(Vector3(0.18 + (i % 3) * 0.08, 0.02, 0.01), [Color(0.3, 0.4, 0.8), Color(0.82, 0.3, 0.3)][i % 2], MeshKit.xf(Vector3(0.75 + (i % 2) * 0.2, 1.02 - i * 0.08, -2.54), Vector3(-6, 0, 0)))
			beanbag(k, Vector3(1.7, 0, -2.5), Color(0.9, 0.5, 0.3))
			beanbag(k, Vector3(2.3, 0, -2.55), acc)
			beanbag(k, Vector3(2.5, 0, -1.9), Color(0.3, 0.7, 0.5))
			bike(k, Vector3(2.55, 0, -1.3), Color(0.86, 0.3, 0.26), 90)
			# left wing: stacked monitor boxes, pizza, a lamp
			crates(k, Vector3(-2.5, 0, -1.8), 4, 11, Color(0.74, 0.62, 0.46))
			for i in 3:
				k.box(Vector3(0.3, 0.04, 0.3), Color(0.9, 0.86, 0.76), MeshKit.xf(Vector3(-2.5, 0.02 + i * 0.045, -1.15), Vector3(0, i * 12.0, 0)))
			bulbs(k, Vector3(0.2, 1.15, -2.2), Vector3(2.85, 0.62, -1.5), 9)
			bulbs(k, Vector3(-2.85, 0.62, -1.4), Vector3(-1.5, 1.15, -2.2), 6)
		1:
			# two stacked containers with windows, steel stairs and a HACK sign,
			# a prefab steel shed with a half-open roll-up, cable trays
			var c1 := Color(0.86, 0.5, 0.26)
			var c2 := Color(0.3, 0.44, 0.6)
			container(k, MeshKit.at(-1.75, 0, -2.47), 2.0, c1)
			container(k, MeshKit.at(-1.75, 0.82, -2.47), 2.0, c2)
			for row in 2:
				for i in 3:
					var x := -2.4 + i * 0.6
					k.box(Vector3(0.38, 0.26, 0.04), Color(0.2, 0.21, 0.24), MeshKit.at(x, 0.5 + row * 0.82, -2.13))
					k.box(Vector3(0.32, 0.2, 0.02), Color(0.6, 0.76, 0.86, 0.7), MeshKit.at(x, 0.5 + row * 0.82, -2.11))
			ArchKit.stairs(k, MeshKit.at(-2.52, 0, -0.98), 0.34, 0.82, 1)
			bx(k, Vector3(-2.72, 0.8, -2.12), Vector3(-2.32, 0.84, -1.88), Color(0.6, 0.62, 0.66))
			ArchKit.railing(k, Vector3(-2.72, 1.64, -2.12), Vector3(-0.8, 1.64, -2.12), 0.5, Color(0.96, 0.76, 0.2))
			bx(k, Vector3(-2.3, 1.7, -2.16), Vector3(-1.1, 2.0, -2.12), Color(0.96, 0.76, 0.2))
			for i in 4:
				k.box(Vector3(0.2, 0.2, 0.01), Color(0.16, 0.16, 0.18), MeshKit.at(-2.15 + i * 0.3, 1.85, -2.11))
			ArchKit.ac_unit(k, MeshKit.at(-1.0, 1.64, -2.5), 1, 0.6)
			# prefab shed on the right
			var sw := Color(0.72, 0.74, 0.77)
			ArchKit.corrugated(k, MeshKit.at(1.6, 0, -2.79), 2.4, 1.6, sw)
			for sx in [0.42, 2.78]:
				ArchKit.corrugated(k, MeshKit.xf(Vector3(sx, 0, -2.5), Vector3(0, 90 if sx < 1.0 else -90, 0)), 0.6, 1.6, sw)
			bx(k, Vector3(0.38, 1.6, -2.84), Vector3(2.82, 1.68, -2.16), Color(0.5, 0.53, 0.57))
			bx(k, Vector3(0.42, 0, -2.22), Vector3(0.9, 1.6, -2.18), sw)
			bx(k, Vector3(2.3, 0, -2.22), Vector3(2.78, 1.6, -2.18), sw)
			ArchKit.rollup(k, MeshKit.at(1.6, 0, -2.18), 1.3, 1.3, Color(0.86, 0.87, 0.88), 0.55)
			bx(k, Vector3(1.0, 0.0, -2.75), Vector3(2.2, 0.5, -2.45), Color(0.62, 0.5, 0.36))
			for i in 3:
				k.box(Vector3(0.28, 0.2, 0.02), _lit(acc.lightened(0.3), 0.5), MeshKit.at(1.2 + i * 0.4, 0.66, -2.72))
			ArchKit.cable_tray(k, Vector3(0.4, 1.72, -2.5), Vector3(-0.7, 1.72, -2.5), 1)
			# bikes and a planter tub in the right wing
			for i in 2:
				bike(k, Vector3(2.55, 0, -1.8 + i * 0.5), [Color(0.3, 0.6, 0.86), Color(0.96, 0.76, 0.2)][i], 90)
			ArchKit.planter(k, Vector3(2.55, 0, -1.2), 1, 0.4, true)
			flood(k, Vector3(2.62, 0, -2.0), 2.2, 1, -130)
		2:
			# a white coworking pavilion with a roof terrace, a white pergola
			# shading the desks, planters and a bike rack
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(2.8, 2.6, -2.2), 2, "f")
			ArchKit.door(k, MeshKit.at(0.0, 0, -2.2), 2, 0.7, 1.05)
			for i in 3:
				ArchKit.planter(k, Vector3(-2.2 + i * 1.6, top, -2.5), 2, 0.4, i == 1)
			for i in 2:
				parasol(k, Vector3(-1.4 + i * 1.6, top, -2.55), _c(2, "accent"))
			ArchKit.railing(k, Vector3(-2.7, top, -2.25), Vector3(2.7, top, -2.25), 0.4, Color(0.86, 0.88, 0.9))
			k.box(Vector3(1.1, 0.34, 0.06), Color(0.98, 0.98, 0.98), MeshKit.at(1.9, 2.0, -2.15))
			k.box(Vector3(0.14, 0.14, 0.02), acc, MeshKit.xf(Vector3(1.55, 2.0, -2.11), Vector3(0, 0, 45)))
			k.box(Vector3(0.5, 0.07, 0.02), _c(2, "dark"), MeshKit.at(2.0, 2.03, -2.11))
			# the pergola
			for p in [Vector3(-2.52, 0, -1.0), Vector3(2.52, 0, -1.0)]:
				k.box(Vector3(0.1, 2.4, 0.1), Color(0.96, 0.96, 0.96), MeshKit.at(p.x, 1.2, p.z))
			bx(k, Vector3(-2.6, 2.4, -1.05), Vector3(2.6, 2.5, -0.95), Color(0.96, 0.96, 0.96))
			for x in [-2.52, 2.52]:
				bx(k, Vector3(x - 0.05, 2.4, -2.2), Vector3(x + 0.05, 2.5, -1.0), Color(0.96, 0.96, 0.96))
			for i in 18:
				var x2 := -2.4 + i * (4.8 / 17.0)
				bx(k, Vector3(x2 - 0.025, 2.5, -2.2), Vector3(x2 + 0.025, 2.56, -0.95), Color(0.94, 0.94, 0.94))
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -1.2), 2, 2, true)
			for i in 3:
				bike(k, Vector3(2.55, 0, -2.0 + i * 0.32), [_c(2, "accent"), Color(0.96, 0.96, 0.96), Color(0.98, 0.7, 0.3)][i], 90)
			bx(k, Vector3(2.4, 0, -2.15), Vector3(2.7, 0.3, -2.1), Color(0.8, 0.82, 0.84))
		3:
			# an industrial loft hall with a sawtooth roof and a giant screen
			# of code, a catwalk, server racks, AC stacks
			var dk := Color(0.38, 0.41, 0.47)
			bx(k, Vector3(-2.8, 0, -2.8), Vector3(1.5, 2.2, -2.2), dk)
			ArchKit.curtain(k, MeshKit.at(-0.65, 0.1, -2.2), 4.1, 1.0, 3, 8, 1)
			sawtooth(k, -2.8, 1.5, -2.8, -2.2, 2.2, 2, Color(0.3, 0.32, 0.36), Color(0.42, 0.62, 0.82, 0.62))
			screen(k, Vector3(-0.65, 1.62, -2.17), 3.2, 0.62, acc.lightened(0.3), 0.0, 6)
			for i in 6:
				var w := 0.6 + fposmod(i * 0.37, 1.0) * 1.2
				k.box(Vector3(w, 0.04, 0.01), _lit(Color(0.6, 1.0, 0.62) if i % 3 == 0 else LED3, 0.45), MeshKit.at(-2.0 + w * 0.5 + (i % 2) * 0.2, 1.88 - i * 0.09, -2.145))
			ArchKit.catwalk(k, Vector3(-2.7, 1.15, -2.08), Vector3(1.4, 1.15, -2.08), 0.22, 3, false)
			# server racks on the right
			for i in 3:
				var x := 1.8 + i * 0.34
				bx(k, Vector3(x - 0.15, 0, -2.75), Vector3(x + 0.15, 1.5, -2.3), Color(0.16, 0.17, 0.2))
				for j in 8:
					k.box(Vector3(0.22, 0.02, 0.01), _lit(LED3 if j % 3 else Color(0.6, 1.0, 0.62), 0.45), MeshKit.at(x, 0.2 + j * 0.15, -2.295))
			bx(k, Vector3(1.6, 1.5, -2.8), Vector3(2.8, 1.58, -2.25), Color(0.3, 0.32, 0.36))
			ArchKit.cable_tray(k, Vector3(1.6, 1.65, -2.5), Vector3(2.75, 1.65, -2.5), 3)
			for z in [-1.9, -1.4]:
				ArchKit.ac_unit(k, MeshKit.xf(Vector3(-2.5, 0, z), Vector3(0, 90, 0)), 3, 0.55)
				ArchKit.ac_unit(k, MeshKit.xf(Vector3(-2.5, 0.32, z), Vector3(0, 90, 0)), 3, 0.55)
			for i in 2:
				bike(k, Vector3(2.55, 0, -1.8 + i * 0.5), [Color(0.2, 0.22, 0.26), Color(0.98, 0.8, 0.22)][i], 90)
		4:
			# a graphite tower with glowing code fins, a cantilevered glass pod,
			# a drone pad, a lower code block, brass planters
			var top := monolith(k, Vector3(-2.8, 0, -2.8), Vector3(-1.0, 4.0, -2.2), "f", 0.3)
			ArchKit.drone_pad(k, Vector3(-1.9, top + 0.02, -2.5), 0.3)
			ArchKit.beacon(k, Vector3(-2.7, top, -2.7), 0.5)
			# the pod
			bx(k, Vector3(-1.0, 2.4, -2.82), Vector3(1.2, 3.3, -2.18), GRAPH2)
			bx(k, Vector3(-0.95, 2.5, -2.18), Vector3(1.15, 3.2, -2.16), Color(0.42, 0.9, 1.0, 0.5))
			for i in 6:
				k.box(Vector3(0.03, 0.72, 0.04), Pal.BRASS, MeshKit.at(-0.9 + i * 0.4, 2.85, -2.15))
			for y in [2.4, 3.3]:
				bx(k, Vector3(-1.0, y - 0.03, -2.84), Vector3(1.22, y + 0.03, -2.16), Pal.BRASS)
			ln(k, Vector3(1.2, 2.4, -2.5), Vector3(0.0, 1.2, -2.5), 0.08, Pal.BRASS)
			# lower code block
			var t2 := monolith(k, Vector3(1.3, 0, -2.8), Vector3(2.8, 1.8, -2.2), "", 0.3)
			screen(k, Vector3(2.05, 1.0, -2.18), 1.3, 1.2, Color(0.42, 0.9, 1.0), 0.0, 9)
			k.box(Vector3(1.0, 0.25, 0.4), GRAPH2, MeshKit.at(2.05, t2 + 0.12, -2.5))
			for i in 4:
				k.box(Vector3(0.04, 0.2, 0.36), Pal.BRASS, MeshKit.at(1.7 + i * 0.24, t2 + 0.26, -2.5))
			# hyperscale planters in the wings
			for sx in [-1.0, 1.0]:
				for z in [-1.9, -1.2]:
					ArchKit.planter(k, Vector3(sx * 2.53, 0, z), 4, 0.44, true)
				glow_pipe(k, [Vector3(sx * 2.2, 0.09, -1.0), Vector3(sx * 2.2, 0.09, -2.15)], 0.03, Color(0.6, 0.5, 1.0, 0.4))


static func _labels(k: MeshKit, t: int) -> void:
	var tags := [Color(0.98, 0.88, 0.4), Color(0.6, 0.86, 0.96), Color(0.98, 0.7, 0.7), Color(0.7, 0.92, 0.66)]
	match t:
		0:
			# a tarp canopy over folding tables of photos, clotheslines of
			# pinned pictures, boxes, stacked plastic chairs
			for x in [-2.6, -0.4]:
				for z in [-2.75, -2.2]:
					bx(k, Vector3(x - 0.03, 0, z - 0.03), Vector3(x + 0.03, 1.25 if z < -2.5 else 1.05, z + 0.03), Pal.WOOD)
			k.box(Vector3(2.4, 0.02, 0.75), Color(0.26, 0.46, 0.78), MeshKit.xf(Vector3(-1.5, 1.17, -2.48), Vector3(-15, 0, 1)))
			for sx in [-1.0, 1.0]:
				ln(k, Vector3(-1.5 + sx * 1.2, 1.12, -2.12), Vector3(-1.5 + sx * 1.35, 0.0, -1.95), 0.008, Color(0.86, 0.86, 0.8))
			for i in 2:
				var x2 := -2.1 + i * 1.1
				bx(k, Vector3(x2 - 0.4, 0.5, -2.72), Vector3(x2 + 0.4, 0.53, -2.32), Color(0.86, 0.84, 0.78))
				for sx in [-1.0, 1.0]:
					ln(k, Vector3(x2 + sx * 0.35, 0, -2.7), Vector3(x2 + sx * 0.35, 0.5, -2.34), 0.02, Color(0.3, 0.32, 0.34))
				for j in 6:
					k.box(Vector3(0.12, 0.01 + (j % 3) * 0.015, 0.09), Color(0.95, 0.95, 0.92) if j % 2 else tags[j % 4], MeshKit.xf(Vector3(x2 - 0.3 + j * 0.12, 0.54, -2.52 + (j % 2) * 0.08), Vector3(0, j * 17 % 30 - 15, 0)))
			# clotheslines with photos
			for z in [-2.85, -2.3]:
				var a := Vector3(0.0, 1.15, z)
				var b := Vector3(2.8, 1.15, z)
				ln(k, a, b, 0.008, Color(0.86, 0.86, 0.8))
				for i in 9:
					var q := a.lerp(b, (i + 0.5) / 9.0)
					k.box(Vector3(0.14, 0.18, 0.01), Color(0.95, 0.95, 0.92), MeshKit.xf(q + Vector3(0, -0.11, 0), Vector3(0, 0, (i % 3 - 1) * 6.0)))
					k.box(Vector3(0.11, 0.11, 0.012), [Color(0.5, 0.6, 0.7), Color(0.6, 0.5, 0.42), Color(0.42, 0.6, 0.46)][i % 3], MeshKit.xf(q + Vector3(0, -0.09, 0), Vector3(0, 0, (i % 3 - 1) * 6.0)))
					k.box(Vector3(0.02, 0.04, 0.02), tags[i % 4], MeshKit.at(q.x, q.y - 0.01, q.z))
			for x3 in [0.0, 2.8]:
				bx(k, Vector3(x3 - 0.03, 0, -2.88), Vector3(x3 + 0.03, 1.2, -2.27), Pal.WOOD)
			crates(k, Vector3(0.6, 0, -2.6), 4, 5, Color(0.74, 0.62, 0.46))
			for i in 4:
				side_chair(k, Vector3(2.52, i * 0.06, -1.6), Color(0.3, 0.6, 0.86) if i % 2 else Color(0.96, 0.96, 0.94), -90)
			crates(k, Vector3(-2.5, 0, -1.7), 3, 8, Color(0.74, 0.62, 0.46))
			bulbs(k, Vector3(-2.85, 0.62, -1.0), Vector3(-0.4, 1.05, -2.2), 8)
		1:
			# a studio container with its doors open on shelves, steel shelving
			# of coloured bins, a conveyor down the right wing, yellow rails
			container(k, MeshKit.at(-1.75, 0, -2.47), 2.0, Color(0.92, 0.74, 0.3))
			bx(k, Vector3(-2.5, 0.06, -2.15), Vector3(-1.0, 0.76, -2.12), Color(0.16, 0.16, 0.18))
			for j in 2:
				bx(k, Vector3(-2.45, 0.3 + j * 0.25, -2.4), Vector3(-1.05, 0.32 + j * 0.25, -2.12), Color(0.6, 0.62, 0.66))
				for i in 5:
					k.box(Vector3(0.22, 0.14, 0.2), tags[(i + j) % 4], MeshKit.at(-2.3 + i * 0.3, 0.4 + j * 0.25, -2.24))
			var steel := Color(0.6, 0.62, 0.66)
			for u in 2:
				var x0 := 0.0 + u * 1.4
				for x in [x0, x0 + 1.2]:
					for z in [-2.8, -2.35]:
						bx(k, Vector3(x - 0.02, 0, z - 0.02), Vector3(x + 0.02, 1.5, z + 0.02), steel)
				for j in 4:
					bx(k, Vector3(x0, 0.1 + j * 0.45, -2.8), Vector3(x0 + 1.2, 0.13 + j * 0.45, -2.35), steel.darkened(0.15))
					if j < 3:
						for i in 4:
							k.box(Vector3(0.26, 0.2, 0.36), [Color(0.26, 0.46, 0.78), Color(0.96, 0.76, 0.2), Color(0.78, 0.3, 0.26), Color(0.36, 0.6, 0.4)][(i + j + u) % 4], MeshKit.at(x0 + 0.16 + i * 0.29, 0.23 + j * 0.45, -2.57))
							k.box(Vector3(0.08, 0.05, 0.01), Color(0.96, 0.96, 0.94), MeshKit.at(x0 + 0.16 + i * 0.29, 0.25 + j * 0.45, -2.385))
			# conveyor down the right wing
			var a := Vector3(2.53, 0.5, -2.2)
			var b := Vector3(2.53, 0.5, -1.0)
			bx(k, Vector3(2.35, 0.44, -2.2), Vector3(2.71, 0.5, -1.0), Color(0.2, 0.21, 0.24))
			for i in 7:
				var q := a.lerp(b, (i + 0.5) / 7.0)
				bx(k, Vector3(2.37, 0, q.z - 0.02), Vector3(2.4, 0.44, q.z + 0.02), steel)
				bx(k, Vector3(2.66, 0, q.z - 0.02), Vector3(2.69, 0.44, q.z + 0.02), steel)
			for i in 3:
				crate(k, Vector3(2.53, 0.5, -2.0 + i * 0.4), Vector3(0.24, 0.18, 0.24), Color(0.74, 0.62, 0.46), i * 8.0)
				k.box(Vector3(0.08, 0.06, 0.01), tags[i], MeshKit.at(2.4, 0.6, -2.0 + i * 0.4))
			for x2 in [2.33, 2.73]:
				ln(k, Vector3(x2, 0.62, -2.2), Vector3(x2, 0.62, -1.0), 0.025, Color(0.96, 0.76, 0.2))
			bx(k, Vector3(2.3, 0.0, -1.0), Vector3(2.76, 1.0, -0.96), Color(0.96, 0.76, 0.2))
			for i in 3:
				barrel(k, Vector3(-2.55, 0, -1.9 + i * 0.32), [Color(0.26, 0.46, 0.78), Color(0.78, 0.3, 0.26), Color(0.36, 0.6, 0.4)][i], 0.13, 0.4)
			flood(k, Vector3(-2.62, 0, -1.05), 2.2, 1, 120)
		2:
			# a white studio with a sticky-note mosaic on its glass, a giant
			# white tag sculpture, planters and benches
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(1.3, 2.5, -2.2), 2, "f")
			ArchKit.door(k, MeshKit.at(0.6, 0, -2.2), 2, 0.6, 1.0)
			for i in 16:
				for j in 4:
					if (i * 3 + j * 5) % 7 != 0:
						k.box(Vector3(0.16, 0.16, 0.012), tags[(i + j * 2) % 4], MeshKit.xf(Vector3(-2.5 + i * 0.22, 1.55 + j * 0.2, -2.14), Vector3(0, 0, ((i + j) % 3 - 1) * 4.0)))
			ArchKit.ac_unit(k, MeshKit.at(-2.2, top, -2.55), 2, 0.7)
			ArchKit.solar(k, MeshKit.at(-0.4, top, -2.55), 3, 2, 20.0, 0.3)
			# the tag sculpture
			var tp := Vector3(2.1, 0, -2.5)
			k.box(Vector3(0.1, 1.4, 0.1), Color(0.86, 0.88, 0.9), MeshKit.at(tp.x, 0.7, tp.z))
			k.box(Vector3(0.9, 0.55, 0.08), Color(0.98, 0.98, 0.98), MeshKit.xf(tp + Vector3(0, 1.7, 0), Vector3(0, 0, 18)))
			k.prism(PackedVector2Array([Vector2(-0.45, -0.275), Vector2(-0.7, 0.0), Vector2(-0.45, 0.275)]), 0.08, Color(0.98, 0.98, 0.98), MeshKit.xf(tp + Vector3(0, 1.7, 0.04), Vector3(90, 0, 18)))
			k.cyl(0.07, 0.1, _c(2, "accent"), MeshKit.xf(tp + Vector3(-0.47, 1.55, 0.0), Vector3(90, 0, 0)), 8)
			k.box(Vector3(0.5, 0.08, 0.02), _c(2, "accent"), MeshKit.xf(tp + Vector3(0.05, 1.72, 0.05), Vector3(0, 0, 18)))
			ln(k, tp + Vector3(-0.47, 1.6, 0.0), tp + Vector3(-0.8, 2.0, 0.0), 0.012, Color(0.3, 0.32, 0.36))
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -0.95), 3, 2, true)
			planters(k, Vector3(2.52, 0, -1.8), Vector3(2.52, 0, -0.95), 2, 2, false)
		3:
			# a sorting hall with a U of overhead conveyor along the wings,
			# scanner gantries with blue LEDs, bins of tagged parcels
			var top := hall(k, Vector3(-2.8, 0, -2.8), Vector3(2.0, 2.2, -2.2), "f")
			roof3(k, -2.7, 1.9, -2.5, top)
			var y := 2.0
			var steel := Color(0.3, 0.32, 0.36)
			var path := [Vector3(-2.53, y, -1.0), Vector3(-2.53, y, -2.0), Vector3(2.53, y, -2.0), Vector3(2.53, y, -1.0)]
			for i in 3:
				var a: Vector3 = path[i]
				var b: Vector3 = path[i + 1]
				var len := a.distance_to(b)
				var dir := (b - a) / len
				var mid := (a + b) * 0.5
				var yaw := rad_to_deg(atan2(dir.x, dir.z))
				k.box(Vector3(0.34, 0.08, len + 0.34), Color(0.2, 0.21, 0.24), MeshKit.xf(mid, Vector3(0, yaw, 0)))
				for s in [-1.0, 1.0]:
					k.box(Vector3(0.03, 0.08, len + 0.34), Color(0.98, 0.8, 0.22), MeshKit.xf(mid + Vector3(dir.z, 0, -dir.x) * 0.17 * s + Vector3(0, 0.06, 0), Vector3(0, yaw, 0)))
				var n := int(len / 0.45)
				for j in n:
					var q := a.lerp(b, (j + 0.5) / n)
					crate(k, q + Vector3(0, 0.04, 0), Vector3(0.2, 0.14, 0.2), Color(0.74, 0.62, 0.46), j * 13.0)
					k.box(Vector3(0.06, 0.05, 0.01), tags[j % 4], MeshKit.xf(q + Vector3(0, 0.12, 0), Vector3(0, yaw, 0)) * MeshKit.at(0, 0, 0.1))
			for p in [Vector3(-2.53, 0, -1.0), Vector3(2.53, 0, -1.0), Vector3(-2.53, 0, -2.0), Vector3(2.53, 0, -2.0)]:
				k.box(Vector3(0.08, y, 0.08), steel, MeshKit.at(p.x, y * 0.5, p.z))
			for sx in [-1.0, 1.0]:
				var gz := -1.5
				for d in [-1.0, 1.0]:
					k.box(Vector3(0.05, 0.5, 0.05), steel, MeshKit.at(sx * 2.53 + d * 0.22, y + 0.25, gz))
				k.box(Vector3(0.5, 0.08, 0.1), steel, MeshKit.at(sx * 2.53, y + 0.5, gz))
				k.box(Vector3(0.4, 0.02, 0.02), _lit(LED3, 0.35), MeshKit.at(sx * 2.53, y + 0.45, gz + 0.06))
			ArchKit.beacon(k, Vector3(2.53, y + 0.55, -1.5), 0.2)
		4:
			# a graphite tower with a billboard grid of glowing tags, wing
			# towers with tag clouds floating over them, a drone pad
			var top := monolith(k, Vector3(-1.3, 0, -2.8), Vector3(1.3, 3.8, -2.2), "", 0.3)
			bx(k, Vector3(-1.25, 1.2, -2.2), Vector3(1.25, 3.6, -2.16), GRAPH2)
			for i in 8:
				for j in 7:
					if (i * 5 + j * 3) % 6 != 0:
						k.box(Vector3(0.24, 0.26, 0.02), Color(tags[(i + j) % 4].r, tags[(i + j) % 4].g, tags[(i + j) % 4].b, 0.5), MeshKit.at(-1.05 + i * 0.3, 1.38 + j * 0.32, -2.15))
			for y2 in [1.2, 3.6]:
				bx(k, Vector3(-1.3, y2 - 0.03, -2.18), Vector3(1.3, y2 + 0.03, -2.14), Pal.BRASS)
			ArchKit.drone_pad(k, Vector3(0, top + 0.02, -2.5), 0.32)
			ArchKit.beacon(k, Vector3(1.2, top, -2.7), 0.5)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 1.4
				var xb: float = sx * 2.8
				monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.3, -2.2), "f", 0.3)
				var wt := monolith(k, Vector3(sx * 2.53 - 0.27, 0, -2.0), Vector3(sx * 2.53 + 0.27, 2.2, -1.0), "l" if sx > 0 else "r", 0.3)
				for i in 10:
					var a := i * 2.4
					var r := 0.15 + fposmod(i * 0.37, 1.0) * 0.2
					k.box(Vector3(0.1, 0.07, 0.02), Color(tags[i % 4].r, tags[i % 4].g, tags[i % 4].b, 0.45), MeshKit.xf(Vector3(sx * 2.53 + cos(a) * r, wt + 0.3 + fposmod(i * 0.29, 0.6), -1.5 + sin(a) * r), Vector3(0, a * 30.0, 0)))
				k.torus(0.3, 0.015, Pal.BRASS, MeshKit.at(sx * 2.53, wt + 0.25, -1.5), 14, 3)


static func _feedback(k: MeshKit, t: int) -> void:
	var up := Color(0.4, 0.78, 0.5)
	var down := Color(0.9, 0.44, 0.44)
	var pink := Color(1.0, 0.6, 0.64)
	match t:
		0:
			# a living room in the yard: a rug, an old couch, a floor lamp, a TV
			# on crates, a plant, string lights, a hand-painted RATE US board
			rug(k, Vector3(-1.4, 0, -2.45), Vector2(2.4, 0.75), Color(0.72, 0.36, 0.3))
			sofa(k, Vector3(-1.9, 0.08, -2.55), 1.3, Color(0.44, 0.58, 0.42))
			floor_lamp(k, Vector3(-2.68, 0.08, -2.6))
			crate(k, Vector3(-0.55, 0.08, -2.6), Vector3(0.36, 0.3, 0.3), Pal.WOOD_LIGHT)
			k.box(Vector3(0.46, 0.34, 0.1), Color(0.16, 0.16, 0.18), MeshKit.at(-0.55, 0.57, -2.62))
			k.box(Vector3(0.4, 0.28, 0.01), _lit(Color(0.6, 0.8, 1.0), 0.5), MeshKit.at(-0.55, 0.57, -2.565))
			k.cyl(0.12, 0.2, Pal.TERRACOTTA, MeshKit.at(0.1, 0.0, -2.6), 8, 0.0, 0.1)
			k.sphere(0.22, Color(0.4, 0.58, 0.34), MeshKit.xf(Vector3(0.1, 0.42, -2.6), Vector3.ZERO, Vector3(1, 1.3, 1)), 8, 4)
			# a board of hand-drawn ratings
			for sx in [-1.0, 1.0]:
				ln(k, Vector3(1.2 + sx * 0.4, 0, -2.55), Vector3(1.2 + sx * 0.36, 1.25, -2.62), 0.03, Pal.WOOD)
			k.box(Vector3(0.9, 0.6, 0.03), Color(0.2, 0.26, 0.22), MeshKit.xf(Vector3(1.2, 0.9, -2.6), Vector3(-5, 0, 0)))
			for i in 4:
				for j in 5:
					if j <= 4 - i % 3:
						k.box(Vector3(0.06, 0.06, 0.01), Color(0.98, 0.84, 0.3), MeshKit.xf(Vector3(0.95 + j * 0.1, 1.1 - i * 0.12, -2.58), Vector3(-5, 0, 45)))
			# suggestion boxes and a cooler in the right wing
			for i in 3:
				k.box(Vector3(0.3, 0.24, 0.26), Color(0.72, 0.6, 0.42), MeshKit.xf(Vector3(2.52, 0.12 + i * 0.24, -2.3), Vector3(0, i * 9.0, 0)))
				k.box(Vector3(0.14, 0.012, 0.03), Color(0.2, 0.18, 0.16), MeshKit.at(2.52, 0.245 + i * 0.24, -2.3))
			lawn_chair(k, Vector3(2.5, 0, -1.5), Color(0.86, 0.5, 0.6), -70)
			k.box(Vector3(0.3, 0.2, 0.2), Color(0.86, 0.3, 0.26), MeshKit.at(2.5, 0.1, -1.05))
			lawn_chair(k, Vector3(-2.5, 0, -1.5), Color(0.3, 0.6, 0.86), 70)
			bulbs(k, Vector3(-2.85, 0.62, -1.2), Vector3(0.0, 1.2, -2.85), 9)
			bulbs(k, Vector3(0.0, 1.2, -2.85), Vector3(2.85, 0.62, -1.2), 9)
		1:
			# a food-truck container with its serving hatch up under a striped
			# awning, a menu board, a picnic table and a parasol
			container(k, MeshKit.at(-1.6, 0, -2.47), 2.2, Color(0.9, 0.42, 0.4))
			bx(k, Vector3(-2.3, 0.4, -2.15), Vector3(-0.9, 0.72, -2.12), Color(0.16, 0.16, 0.18))
			bx(k, Vector3(-2.35, 0.36, -2.14), Vector3(-0.85, 0.4, -1.98), Color(0.86, 0.87, 0.88))
			for i in 7:
				k.box(Vector3(0.22, 0.02, 0.4), Color(0.96, 0.96, 0.94) if i % 2 else Color(0.9, 0.42, 0.4), MeshKit.xf(Vector3(-2.3 + i * 0.22, 0.85, -2.0), Vector3(-20, 0, 0)))
			for i in 4:
				k.box(Vector3(0.12, 0.14, 0.1), [Color(0.96, 0.9, 0.8), Color(0.6, 0.4, 0.3)][i % 2], MeshKit.at(-2.15 + i * 0.35, 0.47, -2.2))
			k.box(Vector3(0.36, 0.5, 0.03), Color(0.2, 0.26, 0.22), MeshKit.xf(Vector3(-0.55, 0.3, -2.1), Vector3(-12, 0, 0)))
			for i in 4:
				k.box(Vector3(0.24, 0.02, 0.01), Color(0.95, 0.95, 0.9), MeshKit.xf(Vector3(-0.55, 0.45 - i * 0.08, -2.08), Vector3(-12, 0, 0)))
			ArchKit.ac_unit(k, MeshKit.at(-2.3, 0.82, -2.5), 1, 0.55)
			k.box(Vector3(0.9, 0.22, 0.04), Color(0.96, 0.76, 0.2), MeshKit.at(-1.3, 1.0, -2.47))
			k.cyl(0.07, 0.03, up, MeshKit.xf(Vector3(-1.62, 1.0, -2.44), Vector3(90, 0, 0)), 8)
			# picnic table and parasol
			var pt := Vector3(1.4, 0, -2.5)
			bx(k, pt + Vector3(-0.5, 0.4, -0.2), pt + Vector3(0.5, 0.44, 0.2), Pal.WOOD_LIGHT)
			for sz in [-1.0, 1.0]:
				bx(k, pt + Vector3(-0.5, 0.22, sz * 0.32 - 0.07), pt + Vector3(0.5, 0.25, sz * 0.32 + 0.07), Pal.WOOD_LIGHT)
			for sx in [-1.0, 1.0]:
				ln(k, pt + Vector3(sx * 0.4, 0, -0.35), pt + Vector3(sx * 0.4, 0.42, 0.15), 0.035, Pal.WOOD)
				ln(k, pt + Vector3(sx * 0.4, 0, 0.35), pt + Vector3(sx * 0.4, 0.42, -0.15), 0.035, Pal.WOOD)
			parasol(k, pt, Color(0.9, 0.42, 0.4))
			for i in 3:
				k.cyl(0.03, 0.08, [Color(0.9, 0.9, 0.86), Color(0.3, 0.2, 0.15), Color(0.96, 0.76, 0.2)][i], MeshKit.at(pt.x - 0.2 + i * 0.2, 0.44, pt.z), 6)
			for i in 3:
				side_chair(k, Vector3(2.52, 0, -2.0 + i * 0.4), [Color(0.96, 0.76, 0.2), Color(0.3, 0.6, 0.86), Color(0.9, 0.42, 0.4)][i], -90)
			flood(k, Vector3(-2.62, 0, -1.2), 2.2, 1, 120)
			bulbs(k, Vector3(-0.5, 1.0, -2.2), Vector3(2.85, 0.9, -2.85), 8)
		2:
			# a white lounge pavilion with a speech-bubble sign, an outdoor
			# lounge of white sofas with teal cushions, planters
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(0.6, 2.1, -2.2), 1, "f")
			ArchKit.door(k, MeshKit.at(0.0, 0, -2.2), 2, 0.6, 1.0)
			k.rbox(Vector3(1.2, 0.6, 0.12), 0.1, Color(0.98, 0.98, 0.98), MeshKit.at(-1.2, top + 0.6, -2.4))
			k.prism(PackedVector2Array([Vector2(-0.15, 0.0), Vector2(0.1, 0.0), Vector2(-0.2, 0.25)]), 0.12, Color(0.98, 0.98, 0.98), MeshKit.xf(Vector3(-1.5, top + 0.3, -2.34), Vector3(90, 0, 0)))
			for i in 3:
				k.sphere(0.06, _c(2, "accent"), MeshKit.at(-1.45 + i * 0.25, top + 0.6, -2.33), 8, 4)
			for i in 2:
				k.box(Vector3(0.05, 0.4, 0.05), Color(0.86, 0.88, 0.9), MeshKit.at(-1.6 + i * 0.8, top + 0.2, -2.42))
			# outdoor lounge
			rug(k, Vector3(1.7, 0, -2.45), Vector2(2.0, 0.7), Color(0.84, 0.86, 0.86))
			sofa(k, Vector3(1.7, 0.08, -2.62), 1.2, Color(0.96, 0.96, 0.96))
			for i in 3:
				k.box(Vector3(0.32, 0.06, 0.3), _c(2, "accent"), MeshKit.at(1.3 + i * 0.4, 0.45, -2.58))
			k.cyl(0.18, 0.04, Color(0.96, 0.96, 0.96), MeshKit.at(1.7, 0.3, -2.25), 10)
			k.cyl(0.03, 0.22, _c(2, "accent"), MeshKit.at(1.7, 0.08, -2.25), 6)
			parasol(k, Vector3(2.6, 0, -2.6), _c(2, "accent"))
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -0.95), 3, 2, true)
			planters(k, Vector3(2.52, 0, -2.0), Vector3(2.52, 0, -0.95), 2, 2, true)
		3:
			# a focus-group hall with a giant LED wall of ratings, stepped
			# bleacher seating in the left wing, a catwalk, speakers
			var top := hall(k, Vector3(-2.8, 0, -2.8), Vector3(2.8, 1.6, -2.2), "f")
			bx(k, Vector3(-2.2, top, -2.4), Vector3(2.2, top + 1.2, -2.3), Color(0.12, 0.13, 0.15))
			for x in [-2.1, 2.1]:
				bx(k, Vector3(x - 0.05, top, -2.6), Vector3(x + 0.05, top + 1.25, -2.5), Color(0.3, 0.32, 0.36))
			var cols := [up, Color(0.98, 0.84, 0.3), LED3, down, pink]
			for i in 5:
				var w := 3.6 * (0.85 - i * 0.14)
				k.box(Vector3(w, 0.14, 0.02), _lit(cols[i], 0.45), MeshKit.at(-1.9 + w * 0.5, top + 1.05 - i * 0.2, -2.29))
				k.box(Vector3(0.12, 0.12, 0.02), _lit(Color(0.98, 0.98, 0.96), 0.5), MeshKit.at(-2.05, top + 1.05 - i * 0.2, -2.29))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.2, 0.3, 0.2), Color(0.16, 0.17, 0.2), MeshKit.at(sx * 2.4, top + 1.1, -2.5))
			# bleachers in the left wing (facing the plot)
			for j in 4:
				bx(k, Vector3(-2.8, 0, -2.1), Vector3(-2.26 - j * 0.13, 0.18 * (j + 1), -1.0), Color(0.3, 0.32, 0.36).lightened(0.04 * j))
				for i in 4:
					k.box(Vector3(0.1, 0.05, 0.2), [up, LED3, pink, Color(0.98, 0.84, 0.3)][(i + j) % 4], MeshKit.at(-2.33 - j * 0.13, 0.18 * (j + 1) + 0.025, -1.9 + i * 0.26))
			# right wing: speakers and a camera on a tripod
			for z in [-1.9, -1.3]:
				k.box(Vector3(0.3, 0.6, 0.3), Color(0.16, 0.17, 0.2), MeshKit.at(2.53, 0.3, z))
				k.cyl(0.1, 0.02, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(2.37, 0.4, z), Vector3(0, 0, 90)), 10)
			for i in 3:
				var a := TAU * i / 3.0
				ln(k, Vector3(2.5, 0.9, -1.0), Vector3(2.5 + cos(a) * 0.2, 0, -1.0 + sin(a) * 0.15), 0.02, Color(0.3, 0.32, 0.36))
			k.box(Vector3(0.14, 0.12, 0.22), Color(0.16, 0.17, 0.2), MeshKit.at(2.5, 0.98, -1.0))
			k.box(Vector3(0.03, 0.03, 0.02), _lit(Color(1.0, 0.3, 0.25), 0.3), MeshKit.at(2.45, 1.02, -0.88))
		4:
			# a graphite tower crowned by a giant glowing speech bubble with a
			# heart, halls with fins, glowing thumbs on the wing towers
			var top := monolith(k, Vector3(-0.9, 0, -2.8), Vector3(0.9, 2.8, -2.2), "f", 0.3)
			k.rbox(Vector3(1.7, 1.0, 0.22), 0.25, Color(1.0, 0.6, 0.64, 0.45), MeshKit.at(0, top + 0.85, -2.5))
			k.rbox(Vector3(1.78, 1.08, 0.12), 0.27, Pal.BRASS, MeshKit.at(0, top + 0.85, -2.56))
			k.prism(PackedVector2Array([Vector2(-0.4, 0.0), Vector2(0.0, 0.0), Vector2(-0.5, 0.35)]), 0.2, Color(1.0, 0.6, 0.64, 0.45), MeshKit.xf(Vector3(0, top + 0.37, -2.4), Vector3(90, 0, 0)))
			for sx in [-1.0, 1.0]:
				k.sphere(0.13, Color(1.0, 0.95, 0.95, 0.4), MeshKit.at(sx * 0.1, top + 0.95, -2.37), 8, 4)
			k.cone(0.18, 0.22, Color(1.0, 0.95, 0.95, 0.4), MeshKit.xf(Vector3(0, top + 0.95, -2.37), Vector3(180, 0, 0)), 8)
			k.cyl(0.05, 0.4, GRAPH, MeshKit.at(0, top, -2.5), 6)
			ArchKit.beacon(k, Vector3(0, top + 1.45, -2.5), 0.3)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 1.0
				var xb: float = sx * 2.25
				monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.4, -2.2), "f", 0.3)
				var wt := monolith(k, Vector3(sx * 2.53 - 0.27, 0, -2.8), Vector3(sx * 2.53 + 0.27, 2.3, -1.0), "l" if sx > 0 else "r", 0.3)
				k.cyl(0.18, 0.06, Color(0.4, 0.78, 0.5, 0.4) if sx < 0 else Color(1.0, 0.6, 0.64, 0.4), MeshKit.xf(Vector3(sx * 2.53, wt + 0.35, -1.6), Vector3(90, 0, 0)), 12)
				k.torus(0.2, 0.02, Pal.BRASS, MeshKit.xf(Vector3(sx * 2.53, wt + 0.35, -1.6), Vector3(90, 0, 0)), 12, 3)
				k.box(Vector3(0.04, 0.3, 0.04), Pal.BRASS, MeshKit.at(sx * 2.53, wt + 0.08, -1.6))
			ArchKit.drone_pad(k, Vector3(-1.6, 1.42, -2.5), 0.26)


# ---------------------------------------------------------------- papers

## An observatory dome on a drum (base at p).
static func observatory(k: MeshKit, p: Vector3, r: float, drum: Color, dome: Color) -> void:
	k.cyl(r, r * 0.5, drum, MeshKit.at(p.x, p.y, p.z), 12)
	k.sphere(r * 0.98, dome, MeshKit.xf(Vector3(p.x, p.y + r * 0.5, p.z), Vector3.ZERO, Vector3(1, 0.9, 1)), 12, 6)
	k.box(Vector3(r * 0.36, r * 0.7, r * 0.3), Color(0.16, 0.17, 0.2), MeshKit.xf(Vector3(p.x, p.y + r * 1.05, p.z + r * 0.72), Vector3(-35, 0, 0)))
	k.cyl(r * 0.12, r * 0.9, Color(0.86, 0.86, 0.84), MeshKit.xf(Vector3(p.x, p.y + r * 0.8, p.z + r * 0.3), Vector3(55, 0, 0)), 8)


static func _papers(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a garage library: plank shelves crammed with books, an armchair, a
			# reading lamp, a globe, piles of paper, a hand-made sign
			for i in 3:
				bookshelf(k, Vector3(-2.35 + i * 0.95, 0, -2.66), 0.88, 1.2, Pal.WOOD_LIGHT.darkened(0.05 * i))
			sofa(k, Vector3(0.95, 0, -2.55), 0.62, Color(0.6, 0.36, 0.3))
			floor_lamp(k, Vector3(1.45, 0, -2.65))
			k.cyl(0.03, 0.4, Pal.WOOD_DARK, MeshKit.at(1.9, 0, -2.5), 6)
			k.sphere(0.16, Color(0.36, 0.56, 0.78), MeshKit.at(1.9, 0.55, -2.5), 10, 6)
			k.box(Vector3(0.1, 0.06, 0.12), Color(0.42, 0.62, 0.38), MeshKit.xf(Vector3(1.85, 0.62, -2.38), Vector3(0, 30, 20)))
			k.torus(0.18, 0.012, Pal.BRASS, MeshKit.xf(Vector3(1.9, 0.55, -2.5), Vector3(70, 0, 0)), 10, 3)
			for i in 5:
				Stations._books(k, Vector3(2.35 + (i % 2) * 0.22, 0, -2.7 + (i / 2) * 0.3), 3 + i % 3, i)
			for i in 6:
				k.box(Vector3(0.2, 0.06 + (i % 3) * 0.03, 0.26), Color(0.96, 0.95, 0.9), MeshKit.xf(Vector3(-2.5, 0.03 + (i % 3) * 0.015, -1.9 + i * 0.16), Vector3(0, i * 23.0, 0)))
			crates(k, Vector3(2.5, 0, -1.6), 3, 13, Pal.WOOD_LIGHT)
			for i in 3:
				Stations._books(k, Vector3(2.5, 0.27, -1.6 + i * 0.0), 2, i + 2)
			bulbs(k, Vector3(-2.85, 1.3, -2.7), Vector3(2.85, 1.0, -2.6), 14)
		1:
			# a portakabin lab with windows, a telescope on a tripod, steel
			# shelving of binders, a whiteboard trailer
			container(k, MeshKit.at(-1.6, 0, -2.47), 2.3, Color(0.94, 0.94, 0.92), 0.9)
			for i in 4:
				k.box(Vector3(0.32, 0.3, 0.04), Color(0.3, 0.32, 0.36), MeshKit.at(-2.5 + i * 0.5, 0.55, -2.13))
				k.box(Vector3(0.26, 0.24, 0.02), Color(0.6, 0.78, 0.88, 0.7), MeshKit.at(-2.5 + i * 0.5, 0.55, -2.11))
			ArchKit.door(k, MeshKit.at(-0.65, 0, -2.13), 1, 0.36, 0.78)
			ArchKit.stairs(k, MeshKit.xf(Vector3(-0.65, 0, -1.9), Vector3(0, 180, 0)), 0.36, 0.12, 1, false)
			ArchKit.ac_unit(k, MeshKit.at(-2.2, 0.9, -2.5), 1, 0.6)
			k.box(Vector3(0.7, 0.16, 0.03), Color(0.26, 0.46, 0.78), MeshKit.at(-1.4, 1.02, -2.2))
			# telescope on a tripod
			var tp := Vector3(0.6, 0, -2.5)
			for i in 3:
				var a := TAU * i / 3.0
				ln(k, tp + Vector3(0, 0.75, 0), tp + Vector3(cos(a) * 0.3, 0, sin(a) * 0.25), 0.025, Color(0.6, 0.62, 0.64))
			k.cyl(0.07, 0.8, Color(0.94, 0.94, 0.92), MeshKit.xf(tp + Vector3(-0.2, 0.7, 0.15), Vector3(-50, 0, -30)), 8)
			k.cyl(0.08, 0.06, Color(0.2, 0.2, 0.22), MeshKit.xf(tp + Vector3(-0.2, 0.7, 0.15), Vector3(-50, 0, -30)), 8)
			# steel shelving with binders
			var steel := Color(0.6, 0.62, 0.66)
			for x in [1.3, 2.7]:
				for z in [-2.8, -2.4]:
					bx(k, Vector3(x - 0.02, 0, z - 0.02), Vector3(x + 0.02, 1.4, z + 0.02), steel)
			for j in 4:
				bx(k, Vector3(1.3, 0.1 + j * 0.42, -2.8), Vector3(2.7, 0.13 + j * 0.42, -2.4), steel.darkened(0.12))
				if j < 3:
					for i in 14:
						k.box(Vector3(0.07, 0.3, 0.3), [Color(0.26, 0.46, 0.78), Color(0.78, 0.3, 0.26), Color(0.96, 0.76, 0.2), Color(0.36, 0.6, 0.4)][(i + j) % 4], MeshKit.at(1.38 + i * 0.095, 0.28 + j * 0.42, -2.6))
			# whiteboard trailer in the right wing
			bx(k, Vector3(2.5, 0.3, -2.0), Vector3(2.54, 1.0, -1.1), Color(0.96, 0.97, 0.98))
			bx(k, Vector3(2.48, 0.28, -2.02), Vector3(2.56, 1.02, -1.08), steel)
			for i in 5:
				k.box(Vector3(0.01, 0.02, 0.2 + (i % 3) * 0.1), [Color(0.3, 0.4, 0.8), Color(0.82, 0.3, 0.3)][i % 2], MeshKit.at(2.48, 0.9 - i * 0.1, -1.6 + (i % 2) * 0.1))
			for z in [-1.9, -1.2]:
				ln(k, Vector3(2.52, 0.3, z), Vector3(2.52, 0, z), 0.03, steel)
				k.cyl(0.04, 0.03, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(2.52, 0.04, z), Vector3(0, 0, 90)), 6)
			crates(k, Vector3(-2.5, 0, -1.6), 3, 21, Color(0.86, 0.84, 0.78))
			flood(k, Vector3(-2.62, 0, -1.0), 2.2, 1, 120)
		2:
			# a white university hall with a columned portico, a clock tower
			# and a pediment, benches and trees
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(2.8, 2.4, -2.3), 2, "")
			for i in 8:
				var x := -2.45 + i * 0.7
				k.cyl(0.07, 2.2, Color(0.97, 0.97, 0.97), MeshKit.at(x, 0, -2.17), 8)
				k.box(Vector3(0.18, 0.06, 0.18), Color(0.9, 0.9, 0.9), MeshKit.at(x, 2.2, -2.17))
			ArchKit.curtain(k, MeshKit.at(0, 0.1, -2.3), 5.4, 2.1, 2, 10, 2)
			bx(k, Vector3(-2.85, 2.25, -2.32), Vector3(2.85, 2.4, -2.05), Color(0.97, 0.97, 0.97))
			k.prism(PackedVector2Array([Vector2(-1.2, 0.0), Vector2(1.2, 0.0), Vector2(0.0, 0.5)]), 0.12, Color(0.97, 0.97, 0.97), MeshKit.xf(Vector3(0, 2.4, -2.08), Vector3(90, 0, 0)))
			k.prism(PackedVector2Array([Vector2(-0.9, 0.06), Vector2(0.9, 0.06), Vector2(0.0, 0.4)]), 0.02, _c(2, "accent"), MeshKit.xf(Vector3(0, 2.4, -2.07), Vector3(90, 0, 0)))
			# clock tower
			bx(k, Vector3(1.6, top, -2.75), Vector3(2.3, top + 1.5, -2.35), Color(0.97, 0.97, 0.97))
			k.cyl(0.22, 0.03, Color(0.98, 0.98, 0.96), MeshKit.xf(Vector3(1.95, top + 1.05, -2.33), Vector3(90, 0, 0)), 12)
			k.cyl(0.24, 0.02, _c(2, "accent"), MeshKit.xf(Vector3(1.95, top + 1.05, -2.34), Vector3(90, 0, 0)), 12)
			k.box(Vector3(0.02, 0.16, 0.02), _c(2, "dark"), MeshKit.xf(Vector3(1.95, top + 1.1, -2.3), Vector3(0, 0, 0)))
			k.box(Vector3(0.12, 0.02, 0.02), _c(2, "dark"), MeshKit.at(2.0, top + 1.05, -2.3))
			k.cone(0.45, 0.6, _c(2, "accent"), MeshKit.xf(Vector3(1.95, top + 1.5, -2.55), Vector3(0, 45, 0)), 4)
			ArchKit.solar(k, MeshKit.at(-1.0, top, -2.6), 4, 2, 18.0, 0.25)
			planters(k, Vector3(-2.52, 0, -1.95), Vector3(-2.52, 0, -0.95), 2, 2, true)
			planters(k, Vector3(2.52, 0, -1.95), Vector3(2.52, 0, -0.95), 2, 2, true)
		3:
			# a steel-and-glass research hall with an observatory dome and
			# fume-hood stacks, a cryo tank, a radio dish in the wing
			var top := hall(k, Vector3(-2.8, 0, -2.8), Vector3(2.8, 2.3, -2.2), "f")
			observatory(k, Vector3(-1.6, top, -2.5), 0.42, Color(0.36, 0.4, 0.46), Color(0.82, 0.84, 0.86))
			for i in 4:
				k.cyl(0.07, 0.7, Color(0.62, 0.65, 0.7), MeshKit.at(0.2 + i * 0.4, top, -2.6), 8)
				k.cyl(0.1, 0.06, Color(0.3, 0.32, 0.36), MeshKit.at(0.2 + i * 0.4, top + 0.7, -2.6), 8)
			ArchKit.beacon(k, Vector3(2.6, top, -2.6), 0.4)
			ArchKit.door(k, MeshKit.at(0.0, 0, -2.2), 3, 0.6, 1.0)
			ArchKit.tank(k, MeshKit.at(2.52, 0, -1.9), 0.22, 1.2, Color(0.86, 0.88, 0.9), 3)
			for i in 3:
				var a := TAU * i / 3.0
				ln(k, Vector3(2.52, 1.0, -1.25), Vector3(2.52 + cos(a) * 0.22, 0, -1.25 + sin(a) * 0.2), 0.03, Color(0.4, 0.42, 0.46))
			dish(k, Vector3(2.52, 1.1, -1.25), 0.32, Color(0.9, 0.9, 0.88), -60, 50)
			for z in [-1.9, -1.3]:
				cabinet(k, Vector3(-2.52, 0, z), Vector3(0.4, 0.9, 0.36), Color(0.32, 0.35, 0.4), LED3, 90)
		4:
			# a graphite library spire with brass ribs, an orbiting ring of
			# glowing pages, an observatory crown; reading halls either side
			var zc := -2.5
			for i in 5:
				var w := 0.9 - i * 0.14
				var y0 := i * 1.0
				bx(k, Vector3(-w * 0.5, y0, zc - 0.3), Vector3(w * 0.5, y0 + 1.0, zc + 0.3), GRAPH if i % 2 == 0 else GRAPH2)
				bx(k, Vector3(-w * 0.5 - 0.03, y0 + 0.95, zc - 0.33), Vector3(w * 0.5 + 0.03, y0 + 1.0, zc + 0.33), Pal.BRASS)
				for j in 3:
					k.box(Vector3(w * 0.22, 0.6, 0.02), Color(1.0, 0.86, 0.5, 0.45), MeshKit.at(-w * 0.3 + j * w * 0.3, y0 + 0.5, zc + 0.31))
			observatory(k, Vector3(0, 5.0, zc), 0.3, GRAPH2, Pal.BRASS)
			for i in 12:
				var a := TAU * i / 12.0
				k.box(Vector3(0.14, 0.18, 0.01), Color(1.0, 0.95, 0.85, 0.45), MeshKit.xf(Vector3(cos(a) * 0.85, 3.2 + sin(a * 2.0) * 0.1, zc + sin(a) * 0.35), Vector3(0, -rad_to_deg(a) + 90, 0)))
			k.torus(0.85, 0.015, Pal.BRASS, MeshKit.xf(Vector3(0, 3.2, zc), Vector3.ZERO, Vector3(1, 1, 0.42)), 18, 3)
			ArchKit.beacon(k, Vector3(0, 5.55, zc), 0.25)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.75
				var xb: float = sx * 2.8
				var tp := monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.6, -2.2), "f", 0.3)
				for i in 3:
					k.box(Vector3(0.36, 0.3, 0.5), GRAPH2, MeshKit.at(sx * (1.15 + i * 0.55), tp + 0.15, -2.5))
					k.box(Vector3(0.3, 0.02, 0.44), Color(1.0, 0.86, 0.5, 0.45), MeshKit.at(sx * (1.15 + i * 0.55), tp + 0.31, -2.5))
				for z in [-1.85, -1.2]:
					ArchKit.planter(k, Vector3(sx * 2.53, 0, z), 4, 0.44, true)


# ---------------------------------------------------------------- fiber

## A cable drum (axis along x) standing on the ground at p.
static func drum(k: MeshKit, p: Vector3, r: float, w: float, flange: Color, cable: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p + Vector3(0, r, 0), Vector3(0, yaw, 0))
	for sx in [-1.0, 1.0]:
		k.cyl(r, 0.04, flange, tf * MeshKit.xf(Vector3(sx * w * 0.5, 0, 0), Vector3(0, 0, -90)) * MeshKit.at(0, -0.02, 0), 10)
	k.cyl(r * 0.75, w, cable, tf * MeshKit.xf(Vector3(-w * 0.5, 0, 0), Vector3(0, 0, -90)), 10)


static func _fiber(k: MeshKit, t: int) -> void:
	var pink := Color(0.98, 0.62, 0.86)
	match t:
		0:
			# a heap of cable drums, a wooden telephone pole with splice boxes
			# and sagging cables, a ladder, a hand cart
			drum(k, Vector3(-2.3, 0, -2.5), 0.32, 0.4, Pal.WOOD, Color(0.95, 0.55, 0.25), 90)
			drum(k, Vector3(-1.6, 0, -2.55), 0.26, 0.34, Pal.WOOD_LIGHT, Color(0.2, 0.2, 0.22), 80)
			drum(k, Vector3(-1.95, 0.62, -2.5), 0.22, 0.3, Pal.WOOD, pink, 100)
			drum(k, Vector3(2.52, 0, -2.0), 0.24, 0.36, Pal.WOOD_LIGHT, Color(0.3, 0.6, 0.86), 0)
			pole(k, Vector3(0.6, 0, -2.6), 2.8)
			for i in 2:
				k.box(Vector3(0.16, 0.22, 0.1), Color(0.3, 0.3, 0.32), MeshKit.at(0.6, 1.6 + i * 0.4, -2.52))
			for x in [-2.85, 2.85]:
				for j in 3:
					var a := Vector3(0.35 + j * 0.25, 2.62, -2.6)
					var b := Vector3(x, 1.6 + j * 0.1, -2.85)
					var m := (a + b) * 0.5 - Vector3(0, 0.25, 0)
					cord(k, [a, m, b], Color(0.15, 0.15, 0.16), 0.012)
			cord(k, [Vector3(0.6, 1.6, -2.52), Vector3(0.3, 0.6, -2.3), Vector3(-0.2, 0.085, -2.0), Vector3(0.0, 0.085, -1.2)], pink, 0.02)
			# a ladder leaning on the pole
			for sx in [-1.0, 1.0]:
				ln(k, Vector3(0.6 + sx * 0.14, 0, -2.0), Vector3(0.6 + sx * 0.14, 2.0, -2.5), 0.03, Pal.WOOD_LIGHT)
			for i in 7:
				var q := Vector3(0.6, 0.0, -2.0).lerp(Vector3(0.6, 2.0, -2.5), (i + 0.5) / 7.0)
				k.box(Vector3(0.28, 0.025, 0.025), Pal.WOOD_LIGHT, MeshKit.at(q.x, q.y, q.z))
			# hand cart and tool crates
			ln(k, Vector3(1.6, 0.1, -2.5), Vector3(1.75, 1.0, -2.7), 0.03, Color(0.86, 0.3, 0.26))
			ln(k, Vector3(1.9, 0.1, -2.5), Vector3(2.05, 1.0, -2.7), 0.03, Color(0.86, 0.3, 0.26))
			k.box(Vector3(0.36, 0.03, 0.2), Color(0.86, 0.3, 0.26), MeshKit.at(1.75, 0.05, -2.45))
			k.cyl(0.07, 0.04, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(1.55, 0.07, -2.55), Vector3(0, 0, 90)), 8)
			k.cyl(0.07, 0.04, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(1.95, 0.07, -2.55), Vector3(0, 0, 90)), 8)
			drum(k, Vector3(1.75, 0.07, -2.5), 0.15, 0.24, Pal.WOOD, pink, 0)
			crates(k, Vector3(-2.5, 0, -1.6), 3, 17, Color(0.74, 0.62, 0.46))
			bulbs(k, Vector3(0.6, 2.3, -2.6), Vector3(2.85, 0.62, -1.3), 9)
		1:
			# a steel scaffold draw tower with a furnace at the top and a fibre
			# running down to a capstan, a container, cable trays, coil racks
			var steel := Color(0.6, 0.62, 0.66)
			var tp := Vector3(2.35, 0, -2.45)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					bx(k, tp + Vector3(sx * 0.3 - 0.025, 0, sz * 0.3 - 0.025), tp + Vector3(sx * 0.3 + 0.025, 3.2, sz * 0.3 + 0.025), steel)
			for i in 4:
				var y := 0.8 + i * 0.8
				bx(k, tp + Vector3(-0.34, y - 0.03, -0.34), tp + Vector3(0.34, y, 0.34), Color(0.5, 0.52, 0.56))
				for sz in [-1.0, 1.0]:
					ln(k, tp + Vector3(-0.3, y - 0.8, sz * 0.3), tp + Vector3(0.3, y, sz * 0.3), 0.02, steel)
				ArchKit.railing(k, tp + Vector3(-0.34, y, 0.34), tp + Vector3(0.34, y, 0.34), 0.4, Color(0.96, 0.76, 0.2))
			k.cyl(0.18, 0.5, Color(0.3, 0.32, 0.36), MeshKit.at(tp.x, 2.5, tp.z), 10)
			k.cyl(0.19, 0.06, Color(1.0, 0.6, 0.3, 0.4), MeshKit.at(tp.x, 2.7, tp.z), 10, 0.0, -1.0, false)
			ln(k, tp + Vector3(0, 2.5, 0), tp + Vector3(0, 0.4, 0), 0.012, pink)
			k.cyl(0.14, 0.12, Color(0.86, 0.87, 0.88), MeshKit.xf(tp + Vector3(-0.06, 0.3, 0), Vector3(0, 0, -90)), 10)
			ArchKit.ladder(k, MeshKit.at(tp.x - 0.3, 0, tp.z + 0.36), 3.2, Color(0.96, 0.76, 0.2), true)
			# container
			container(k, MeshKit.at(-1.6, 0, -2.47), 2.3, Color(0.42, 0.36, 0.56))
			ArchKit.rollup(k, MeshKit.at(-1.9, 0, -2.13), 0.8, 0.62, Color(0.86, 0.87, 0.88), 0.4)
			k.box(Vector3(0.5, 0.14, 0.02), pink, MeshKit.at(-0.9, 0.6, -2.13))
			ArchKit.ac_unit(k, MeshKit.at(-2.3, 0.82, -2.5), 1, 0.55)
			ArchKit.cable_tray(k, Vector3(-0.45, 0.9, -2.72), Vector3(2.0, 0.9, -2.72), 1)
			for x in [-0.4, 1.0]:
				bx(k, Vector3(x - 0.02, 0, -2.74), Vector3(x + 0.02, 0.9, -2.7), steel)
			# coil racks in the left wing
			for z in [-1.9, -1.35]:
				bx(k, Vector3(-2.75, 0.5, z - 0.02), Vector3(-2.3, 0.53, z + 0.02), steel)
				for x in [-2.7, -2.35]:
					bx(k, Vector3(x - 0.02, 0, z - 0.02), Vector3(x + 0.02, 0.55, z + 0.02), steel)
				drum(k, Vector3(-2.52, 0.0, z), 0.2, 0.3, Color(0.3, 0.32, 0.38), pink, 0)
			drum(k, Vector3(0.6, 0, -2.5), 0.25, 0.32, Color(0.3, 0.32, 0.38), Color(0.96, 0.76, 0.2), 90)
			flood(k, Vector3(-2.62, 0, -1.0), 2.2, 1, 120)
		2:
			# a slender white draw tower with a glass slot, a white two-storey
			# lab with a fibre-optic sign, planters
			var tp := Vector3(2.35, 0, -2.5)
			bx(k, tp + Vector3(-0.42, 0, -0.32), tp + Vector3(0.42, 4.0, 0.32), Color(0.96, 0.96, 0.97))
			bx(k, tp + Vector3(-0.1, 0.3, 0.32), tp + Vector3(0.1, 3.7, 0.34), Color(0.58, 0.8, 0.92, 0.66))
			ln(k, tp + Vector3(0, 3.6, 0.34), tp + Vector3(0, 0.3, 0.34), 0.015, Color(pink.r, pink.g, pink.b, 0.4))
			for y in [1.3, 2.6]:
				bx(k, tp + Vector3(-0.44, y, -0.34), tp + Vector3(0.44, y + 0.08, 0.36), _c(2, "accent"))
			bx(k, tp + Vector3(-0.46, 4.0, -0.36), tp + Vector3(0.46, 4.1, 0.36), Color(0.86, 0.88, 0.9))
			ArchKit.ac_unit(k, MeshKit.at(tp.x, 4.1, tp.z), 2, 0.6)
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(1.8, 2.3, -2.22), 2, "f")
			ArchKit.door(k, MeshKit.at(0.9, 0, -2.22), 2, 0.6, 1.0)
			k.box(Vector3(1.2, 0.3, 0.05), Color(0.98, 0.98, 0.98), MeshKit.at(-1.4, top + 0.4, -2.26))
			for i in 5:
				ln(k, Vector3(-1.9, top + 0.3, -2.22), Vector3(-1.75 + i * 0.03, top + 0.48, -2.22), 0.012, Color(pink.r, pink.g, pink.b, 0.5))
			k.box(Vector3(0.6, 0.06, 0.02), _c(2, "dark"), MeshKit.at(-1.2, top + 0.42, -2.22))
			ArchKit.solar(k, MeshKit.at(-0.5, top, -2.55), 4, 2, 20.0, 0.3)
			planters(k, Vector3(-2.52, 0, -2.05), Vector3(-2.52, 0, -0.95), 3, 2, true)
			planters(k, Vector3(2.52, 0, -1.9), Vector3(2.52, 0, -0.95), 2, 2, false)
		3:
			# twin industrial draw towers with platforms at every level, a
			# catwalk between them, coil racks and an overhead tray
			var steel := Color(0.36, 0.39, 0.44)
			for sx in [-1.0, 1.0]:
				var tp := Vector3(sx * 2.25, 0, -2.45)
				bx(k, tp + Vector3(-0.32, 0, -0.32), tp + Vector3(0.32, 4.4, 0.32), steel)
				for i in 5:
					var y := 0.85 + i * 0.85
					bx(k, tp + Vector3(-0.42, y, -0.38), tp + Vector3(0.42, y + 0.04, 0.42), Color(0.5, 0.52, 0.56))
					ArchKit.railing(k, tp + Vector3(-0.42, y, 0.42), tp + Vector3(0.42, y, 0.42), 0.35, Color(0.98, 0.8, 0.22))
					k.box(Vector3(0.5, 0.02, 0.02), _lit(LED3, 0.45), MeshKit.at(tp.x, y - 0.2, tp.z + 0.33))
				bx(k, tp + Vector3(-0.08, 0.3, 0.32), tp + Vector3(0.08, 4.2, 0.34), Color(0.42, 0.62, 0.82, 0.62))
				ln(k, tp + Vector3(0, 4.1, 0.35), tp + Vector3(0, 0.3, 0.35), 0.015, Color(pink.r, pink.g, pink.b, 0.4))
				k.cyl(0.2, 0.4, Color(0.24, 0.26, 0.3), MeshKit.at(tp.x, 4.4, tp.z), 10)
				k.cyl(0.21, 0.05, Color(1.0, 0.6, 0.3, 0.4), MeshKit.at(tp.x, 4.6, tp.z), 10, 0.0, -1.0, false)
				ArchKit.beacon(k, tp + Vector3(0, 4.8, 0), 0.2)
			ArchKit.catwalk(k, Vector3(-1.85, 2.55, -2.45), Vector3(1.85, 2.55, -2.45), 0.32, 3, false)
			var top := hall(k, Vector3(-1.7, 0, -2.8), Vector3(1.7, 1.7, -2.22), "f")
			for i in 3:
				drum(k, Vector3(-1.0 + i * 1.0, top, -2.5), 0.22, 0.3, Color(0.22, 0.24, 0.28), pink, 90)
			for sx in [-1.0, 1.0]:
				for z in [-1.7, -1.2]:
					drum(k, Vector3(sx * 2.53, 0, z), 0.22, 0.32, Color(0.22, 0.24, 0.28), [pink, LED3][int(z > -1.5)], 0)
		4:
			# a graphite draw spire shedding glowing fibres into a brass ring,
			# graphite halls, glowing spools on the wing towers
			var zc := -2.5
			for i in 6:
				var w := 0.7 - i * 0.07
				bx(k, Vector3(-w * 0.5, i * 0.95, zc - w * 0.42), Vector3(w * 0.5, (i + 1) * 0.95, zc + w * 0.42), GRAPH if i % 2 == 0 else GRAPH2)
				bx(k, Vector3(-w * 0.5 - 0.03, (i + 1) * 0.95 - 0.05, zc - w * 0.42 - 0.03), Vector3(w * 0.5 + 0.03, (i + 1) * 0.95, zc + w * 0.42 + 0.03), Pal.BRASS)
			for i in 7:
				var x := -0.24 + i * 0.08
				ln(k, Vector3(x, 5.4, zc + 0.32), Vector3(x * 1.6, 0.5, zc + 0.36), 0.012, Color(pink.r, pink.g, pink.b, 0.35))
			k.torus(0.42, 0.03, Pal.BRASS, MeshKit.at(0, 0.5, zc + 0.1), 14, 3)
			k.torus(0.38, 0.02, Color(1.0, 0.7, 0.9, 0.4), MeshKit.at(0, 0.55, zc + 0.1), 14, 3)
			k.sphere(0.16, Color(1.0, 0.7, 0.9, 0.35), MeshKit.at(0, 5.85, zc), 8, 4)
			ArchKit.beacon(k, Vector3(0, 6.0, zc), 0.3)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.65
				var xb: float = sx * 2.25
				monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.3, -2.22), "f", 0.3)
				var wt := monolith(k, Vector3(sx * 2.53 - 0.27, 0, -2.8), Vector3(sx * 2.53 + 0.27, 2.2, -1.0), "l" if sx > 0 else "r", 0.3)
				for z in [-2.3, -1.4]:
					drum(k, Vector3(sx * 2.53, wt, z), 0.22, 0.3, GRAPH2, Color(1.0, 0.7, 0.9, 0.45), 0)


# ---------------------------------------------------------------- experts

## A sound booth with an ON AIR light (front +z).
static func booth(k: MeshKit, p: Vector3, w: float, h: float, body: Color) -> void:
	bx(k, p + Vector3(-w * 0.5, 0, -0.28), p + Vector3(w * 0.5, h, 0.28), body)
	bx(k, p + Vector3(-w * 0.4, 0.3, 0.28), p + Vector3(w * 0.4, h - 0.2, 0.3), Color(0.42, 0.62, 0.82, 0.62))
	k.box(Vector3(0.2, 0.08, 0.04), _lit(Color(1.0, 0.3, 0.25), 0.3), MeshKit.at(p.x, p.y + h - 0.08, p.z + 0.31))
	k.box(Vector3(0.12, 0.12, 0.1), Color(0.2, 0.2, 0.22), MeshKit.at(p.x - w * 0.15, p.y + 0.62, p.z + 0.1))
	k.cyl(0.015, 0.25, Color(0.2, 0.2, 0.22), MeshKit.at(p.x + w * 0.15, p.y + 0.4, p.z + 0.1), 5)


static func _experts(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a den: bookshelves of planks, a rug, a wingback chair by a floor
			# lamp, a rotary phone on a crate, a plywood phone booth
			bookshelf(k, Vector3(-2.3, 0, -2.66), 0.9, 1.25, Pal.WOOD)
			bookshelf(k, Vector3(-1.35, 0, -2.66), 0.9, 1.0, Pal.WOOD_LIGHT)
			rug(k, Vector3(0.2, 0, -2.45), Vector2(1.6, 0.7), Color(0.56, 0.3, 0.36))
			sofa(k, Vector3(-0.2, 0.08, -2.55), 0.6, Color(0.42, 0.3, 0.46))
			floor_lamp(k, Vector3(0.3, 0.08, -2.65))
			crate(k, Vector3(0.75, 0.08, -2.55), Vector3(0.3, 0.3, 0.3), Pal.WOOD_LIGHT)
			k.box(Vector3(0.18, 0.08, 0.14), Color(0.16, 0.16, 0.18), MeshKit.at(0.75, 0.42, -2.55))
			k.box(Vector3(0.2, 0.04, 0.04), Color(0.16, 0.16, 0.18), MeshKit.at(0.75, 0.49, -2.55))
			# plywood phone booth with a little window
			var pb := Vector3(1.8, 0, -2.5)
			ArchKit.planks(k, MeshKit.at(pb.x, 0, pb.z - 0.3), 0.7, 1.6, Color(0.78, 0.64, 0.46))
			for sx in [-1.0, 1.0]:
				ArchKit.planks(k, MeshKit.xf(Vector3(pb.x + sx * 0.35, 0, pb.z), Vector3(0, sx * 90, 0)), 0.6, 1.6, Color(0.72, 0.58, 0.4))
			bx(k, pb + Vector3(-0.4, 1.6, -0.34), pb + Vector3(0.4, 1.66, 0.34), Color(0.62, 0.64, 0.66))
			k.box(Vector3(0.5, 0.12, 0.02), Color(0.86, 0.3, 0.26), MeshKit.at(pb.x, 1.45, pb.z + 0.3))
			k.box(Vector3(0.1, 0.16, 0.08), Color(0.16, 0.16, 0.18), MeshKit.at(pb.x, 0.9, pb.z - 0.24))
			# wing clutter
			Stations._books(k, Vector3(2.5, 0, -1.7), 5, 3)
			Stations._books(k, Vector3(2.5, 0, -1.35), 3, 1)
			lawn_chair(k, Vector3(-2.5, 0, -1.6), Color(0.6, 0.36, 0.3), 70)
			crates(k, Vector3(-2.5, 0, -1.1), 2, 23, Pal.WOOD_LIGHT)
			bulbs(k, Vector3(-2.85, 1.3, -2.7), Vector3(1.4, 1.4, -2.85), 11)
		1:
			# a call-centre container with headset sign, cubicles under a tin
			# canopy, a water cooler, filing cabinets
			container(k, MeshKit.at(-1.75, 0, -2.47), 2.0, Color(0.36, 0.5, 0.62))
			for i in 3:
				k.box(Vector3(0.38, 0.26, 0.04), Color(0.2, 0.21, 0.24), MeshKit.at(-2.4 + i * 0.6, 0.52, -2.13))
				k.box(Vector3(0.32, 0.2, 0.02), Color(0.6, 0.76, 0.86, 0.7), MeshKit.at(-2.4 + i * 0.6, 0.52, -2.11))
			ArchKit.ac_unit(k, MeshKit.at(-2.2, 0.82, -2.5), 1, 0.6)
			bx(k, Vector3(-1.4, 0.95, -2.5), Vector3(-0.8, 1.35, -2.46), Color(0.96, 0.76, 0.2))
			k.torus(0.12, 0.02, Color(0.16, 0.16, 0.18), MeshKit.xf(Vector3(-1.1, 1.13, -2.44), Vector3(90, 0, 0)), 10, 3, PI)
			k.box(Vector3(0.04, 0.06, 0.03), Color(0.16, 0.16, 0.18), MeshKit.at(-1.22, 1.1, -2.44))
			k.box(Vector3(0.04, 0.06, 0.03), Color(0.16, 0.16, 0.18), MeshKit.at(-0.98, 1.1, -2.44))
			# cubicles
			canopy(k, -0.6, 2.8, -2.82, -2.2, 1.35, Color(0.66, 0.68, 0.7), Color(0.6, 0.62, 0.66))
			for i in 4:
				var x := -0.3 + i * 0.8
				bx(k, Vector3(x - 0.02, 0, -2.78), Vector3(x + 0.02, 0.7, -2.25), Color(0.5, 0.56, 0.66))
				bx(k, Vector3(x + 0.05, 0.42, -2.75), Vector3(x + 0.7, 0.45, -2.45), Color(0.82, 0.8, 0.76))
				Stations._monitor(k, Vector3(x + 0.38, 0.45, -2.68), 0.22, 0.14, Color(0.16, 0.17, 0.2), Color(0.6, 1.0, 0.62))
				Stations._chair(k, Vector3(x + 0.38, 0, -2.3), Color(0.26, 0.27, 0.3), Pal.STEEL_DARK)
			bx(k, Vector3(-0.6, 0.7, -2.8), Vector3(2.8, 0.74, -2.76), Color(0.5, 0.56, 0.66))
			# water cooler and filing cabinets in the wings
			k.box(Vector3(0.24, 0.6, 0.24), Color(0.94, 0.94, 0.92), MeshKit.at(2.52, 0.3, -1.8))
			k.cyl(0.1, 0.3, Color(0.5, 0.7, 0.95, 0.8), MeshKit.at(2.52, 0.6, -1.8), 8)
			for z in [-1.9, -1.5]:
				k.box(Vector3(0.36, 0.8, 0.36), Color(0.6, 0.62, 0.66), MeshKit.at(-2.52, 0.4, z))
				for j in 3:
					k.box(Vector3(0.01, 0.015, 0.1), Color(0.86, 0.86, 0.84), MeshKit.at(-2.33, 0.2 + j * 0.24, z))
			flood(k, Vector3(2.62, 0, -1.1), 2.2, 1, -130)
		2:
			# a white villa with a library window wall, a teal awning, a terrace
			# with loungers, cypress planters
			var top := pavilion(k, Vector3(-2.8, 0, -2.8), Vector3(1.0, 2.5, -2.2), 2, "")
			ArchKit.curtain(k, MeshKit.at(-0.9, 0.1, -2.2), 3.6, 2.2, 2, 6, 2)
			for i in 6:
				bookshelf(k, Vector3(-2.4 + i * 0.6, 1.25, -2.36), 0.55, 1.0, Color(0.92, 0.9, 0.86))
			for i in 7:
				k.box(Vector3(0.3, 0.02, 0.36), Color(0.96, 0.96, 0.94) if i % 2 else _c(2, "accent"), MeshKit.xf(Vector3(-2.5 + i * 0.3, 1.18, -2.06), Vector3(-15, 0, 0)))
			ArchKit.door(k, MeshKit.at(0.4, 0, -2.2), 2, 0.6, 1.0)
			ArchKit.solar(k, MeshKit.at(-1.0, top, -2.55), 3, 2, 20.0, 0.3)
			k.box(Vector3(0.9, 0.3, 0.05), Color(0.98, 0.98, 0.98), MeshKit.at(-2.1, top + 0.45, -2.26))
			k.sphere(0.08, Color(0.6, 0.4, 0.86), MeshKit.at(-2.38, top + 0.45, -2.22), 8, 4)
			k.box(Vector3(0.4, 0.06, 0.02), _c(2, "dark"), MeshKit.at(-1.95, top + 0.48, -2.22))
			# terrace
			for i in 2:
				var lp := Vector3(1.55 + i * 0.7, 0, -2.5)
				k.box(Vector3(0.3, 0.12, 0.6), Color(0.96, 0.96, 0.96), MeshKit.at(lp.x, 0.16, lp.z))
				k.box(Vector3(0.28, 0.05, 0.4), _c(2, "accent"), MeshKit.at(lp.x, 0.24, lp.z + 0.08))
				k.box(Vector3(0.28, 0.24, 0.05), _c(2, "accent"), MeshKit.xf(Vector3(lp.x, 0.34, lp.z - 0.22), Vector3(-30, 0, 0)))
			parasol(k, Vector3(1.9, 0, -2.75), Color(0.96, 0.96, 0.96))
			for sx in [-1.0, 1.0]:
				for z in [-1.9, -1.2]:
					ArchKit.planter(k, Vector3(sx * 2.53, 0, z), 2, 0.4, false)
					k.lathe(PackedVector2Array([Vector2(0, 0.4), Vector2(0.14, 0.55), Vector2(0.12, 1.2), Vector2(0, 1.5)]), Pal.CYPRESS, MeshKit.at(sx * 2.53, 0, z), 8)
		3:
			# a studio block of podcast booths with ON AIR lights, a satellite
			# uplink dish, a catwalk, a control room
			var top := hall(k, Vector3(-2.8, 0, -2.8), Vector3(0.8, 2.6, -2.5), "")
			for i in 4:
				booth(k, Vector3(-2.35 + i * 0.85, 0, -2.25), 0.7, 1.2, Color(0.3, 0.32, 0.36))
				booth(k, Vector3(-2.35 + i * 0.85, 1.25, -2.25), 0.7, 1.2, Color(0.34, 0.36, 0.42))
			ArchKit.railing(k, Vector3(-2.75, 1.25, -1.98), Vector3(0.75, 1.25, -1.98), 0.5, Color(0.98, 0.8, 0.22))
			roof3(k, -2.7, 0.7, -2.65, top)
			# control room and uplink dish on the right
			var top2 := hall(k, Vector3(1.0, 0, -2.8), Vector3(2.8, 1.6, -2.22), "f")
			k.cyl(0.08, 0.6, Color(0.4, 0.42, 0.46), MeshKit.at(1.9, top2, -2.5), 8)
			dish(k, Vector3(1.9, top2 + 0.8, -2.5), 0.55, Color(0.9, 0.9, 0.88), 0, 40)
			ArchKit.beacon(k, Vector3(2.7, top2, -2.7), 0.4)
			for z in [-1.9, -1.4]:
				ArchKit.ac_unit(k, MeshKit.xf(Vector3(2.5, 0, z), Vector3(0, -90, 0)), 3, 0.55)
				cabinet(k, Vector3(-2.52, 0, z), Vector3(0.4, 0.8, 0.34), Color(0.32, 0.35, 0.4), LED3, 90)
		4:
			# a graphite tower of stacked glowing booths, a crown globe, halls,
			# hyperscale planters
			var zc := -2.5
			var top := monolith(k, Vector3(-0.8, 0, zc - 0.3), Vector3(0.8, 4.4, zc + 0.3), "", 0.3)
			for i in 4:
				var y := 0.5 + i * 1.0
				for j in 2:
					var x := -0.38 + j * 0.76
					bx(k, Vector3(x - 0.32, y, zc + 0.3), Vector3(x + 0.32, y + 0.7, zc + 0.42), GRAPH2)
					bx(k, Vector3(x - 0.27, y + 0.08, zc + 0.42), Vector3(x + 0.27, y + 0.62, zc + 0.44), Color(1.0, 0.82, 0.55, 0.45))
					k.box(Vector3(0.12, 0.05, 0.02), _lit(Color(1.0, 0.3, 0.25), 0.3), MeshKit.at(x, y + 0.66, zc + 0.45))
			k.cyl(0.08, 0.4, Pal.BRASS, MeshKit.at(0, top, zc), 6)
			k.sphere(0.42, Color(0.6, 0.4, 0.86, 0.45), MeshKit.at(0, top + 0.82, zc), 12, 6)
			for i in 3:
				k.torus(0.46, 0.015, Pal.BRASS, MeshKit.xf(Vector3(0, top + 0.82, zc), Vector3(0, i * 60.0, 90)), 16, 3)
			k.torus(0.46, 0.015, Pal.BRASS, MeshKit.at(0, top + 0.82, zc), 16, 3)
			ArchKit.beacon(k, Vector3(0, top + 1.25, zc), 0.25)
			for sx in [-1.0, 1.0]:
				var xa: float = sx * 0.9
				var xb: float = sx * 2.8
				var tp := monolith(k, Vector3(minf(xa, xb), 0, -2.8), Vector3(maxf(xa, xb), 1.5, -2.2), "f", 0.3)
				for z in [-1.85, -1.2]:
					ArchKit.planter(k, Vector3(sx * 2.53, 0, z), 4, 0.44, true)
			ArchKit.drone_pad(k, Vector3(1.85, 1.52, -2.5), 0.28)
