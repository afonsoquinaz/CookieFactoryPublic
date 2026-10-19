class_name ArchKit
## Shared architecture for building looks: a five-tier design language and a
## kit of detailed but cheap pieces (sharp boxes are 12 triangles; keep
## rounded shapes for the big forms). Every building evolves through the
## same five eras, so the campus reads as one place:
##   0 GARAGE      plywood, corrugated tin, tarps, crates, extension cords,
##                 string lights, a folding table; low and improvised
##   1 WORKSHOP    prefab steel sheds, shipping containers, roll-up doors,
##                 steel stairs, yellow safety rails, rooftop AC, chain-link
##   2 CAMPUS      white panels, glass curtain walls, teal bands, planters,
##                 solar canopies, logo signs, screened roof plant; 2 storeys
##   3 INDUSTRIAL  big steel-and-glass halls, catwalks, stair towers, chiller
##                 arrays, cooling towers, pipe racks, generators, blue LEDs
##   4 HYPERSCALE  graphite monoliths with brass trim, glowing fins, liquid-
##                 cooling loops, cantilevers, sky bridges, drone pads, a crown
## Colours with alpha < 1 glow (toon shader). Local frame: building centre on
## the ground, front (entrance side) facing +Z.

const GARAGE := 0
const WORKSHOP := 1
const CAMPUS := 2
const INDUSTRIAL := 3
const HYPERSCALE := 4

## Per-tier palette.
const PAL := [
	{"wall": Color(0.78, 0.64, 0.46), "wall2": Color(0.66, 0.52, 0.36), "trim": Color(0.36, 0.25, 0.18), "roof": Color(0.62, 0.64, 0.66),
		"floor": Color(0.62, 0.58, 0.52), "glass": Color(0.66, 0.78, 0.84, 0.75), "metal": Color(0.6, 0.62, 0.64), "dark": Color(0.22, 0.2, 0.19),
		"accent": Color(0.26, 0.46, 0.78), "accent2": Color(0.92, 0.52, 0.22), "glow": Color(1.0, 0.82, 0.5), "frame": Color(0.36, 0.25, 0.18)},
	{"wall": Color(0.78, 0.8, 0.83), "wall2": Color(0.62, 0.65, 0.7), "trim": Color(0.34, 0.36, 0.4), "roof": Color(0.5, 0.53, 0.57),
		"floor": Color(0.7, 0.7, 0.68), "glass": Color(0.6, 0.76, 0.86, 0.7), "metal": Color(0.7, 0.72, 0.75), "dark": Color(0.2, 0.21, 0.24),
		"accent": Color(0.96, 0.76, 0.2), "accent2": Color(0.78, 0.3, 0.26), "glow": Color(0.6, 1.0, 0.62), "frame": Color(0.3, 0.32, 0.36)},
	{"wall": Color(0.95, 0.95, 0.96), "wall2": Color(0.86, 0.88, 0.9), "trim": Color(0.3, 0.66, 0.68), "roof": Color(0.8, 0.82, 0.84),
		"floor": Color(0.84, 0.85, 0.86), "glass": Color(0.58, 0.8, 0.92, 0.66), "metal": Color(0.82, 0.84, 0.86), "dark": Color(0.26, 0.29, 0.33),
		"accent": Color(0.3, 0.66, 0.68), "accent2": Color(0.98, 0.7, 0.3), "glow": Color(0.42, 0.96, 0.9), "frame": Color(0.7, 0.73, 0.76)},
	{"wall": Color(0.5, 0.54, 0.6), "wall2": Color(0.38, 0.41, 0.47), "trim": Color(0.22, 0.24, 0.28), "roof": Color(0.34, 0.36, 0.4),
		"floor": Color(0.5, 0.53, 0.58), "glass": Color(0.42, 0.62, 0.82, 0.62), "metal": Color(0.62, 0.65, 0.7), "dark": Color(0.14, 0.15, 0.18),
		"accent": Color(0.98, 0.8, 0.22), "accent2": Color(0.3, 0.55, 0.9), "glow": Color(0.45, 0.75, 1.0), "frame": Color(0.24, 0.26, 0.3)},
	{"wall": Color(0.17, 0.18, 0.21), "wall2": Color(0.24, 0.25, 0.29), "trim": Color(0.78, 0.63, 0.38), "roof": Color(0.12, 0.13, 0.15),
		"floor": Color(0.2, 0.21, 0.24), "glass": Color(0.32, 0.5, 0.7, 0.55), "metal": Color(0.36, 0.38, 0.42), "dark": Color(0.08, 0.08, 0.1),
		"accent": Color(0.78, 0.63, 0.38), "accent2": Color(0.42, 0.9, 1.0), "glow": Color(1.0, 0.86, 0.5), "frame": Color(0.78, 0.63, 0.38)},
]


static func pal(t: int) -> Dictionary:
	return PAL[clampi(t, 0, 4)]


static func c(t: int, key: String) -> Color:
	return PAL[clampi(t, 0, 4)][key]


static func lit(col: Color, a := 0.4) -> Color:
	return Color(col.r, col.g, col.b, a)


static func at(x: float, y: float, z: float) -> Transform3D:
	return MeshKit.at(x, y, z)


static func xf(p: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return MeshKit.xf(p, rot, scl)


# ---------------------------------------------------------------- ground

## The lot surface: dirt and gravel (0), concrete with tyre marks (1), paved
## with kerbs and grass strips (2), steel-edged slab with yellow lines (3),
## dark tiles with glowing seams (4). Covers w x d centred at (0, z).
static func lot(k: MeshKit, w: float, d: float, t: int, z := 0.0) -> void:
	var p := pal(t)
	k.box(Vector3(w, 0.1, d), p["floor"], at(0, 0.05, z))
	match t:
		0:
			for i in 9:
				var x := -w * 0.4 + fposmod(i * 0.37 * w, w * 0.8)
				var zz := z - d * 0.4 + fposmod(i * 0.53 * d, d * 0.8)
				k.box(Vector3(0.5, 0.02, 0.36), Color(0.55, 0.5, 0.44), xf(Vector3(x, 0.11, zz), Vector3(0, i * 37.0, 0)))
		1:
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.12, 0.012, d * 0.7), Color(0.6, 0.6, 0.58), at(sx * w * 0.18, 0.106, z))
			k.box(Vector3(w, 0.03, 0.08), Color(0.96, 0.76, 0.2), at(0, 0.11, z + d * 0.5 - 0.06))
		2:
			k.box(Vector3(w, 0.06, 0.18), Color(0.9, 0.9, 0.9), at(0, 0.13, z + d * 0.5 - 0.09))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.3, 0.05, d * 0.9), Color(0.48, 0.62, 0.38), at(sx * (w * 0.5 - 0.2), 0.12, z))
		3:
			k.box(Vector3(w, 0.05, 0.12), Color(0.3, 0.32, 0.36), at(0, 0.12, z + d * 0.5 - 0.06))
			for i in 4:
				k.box(Vector3(0.08, 0.012, d * 0.8), Color(0.98, 0.8, 0.22), at(-w * 0.35 + i * w * 0.233, 0.106, z))
		4:
			var n := int(w / 1.0)
			for i in n + 1:
				k.box(Vector3(0.025, 0.012, d), lit(c(t, "accent2"), 0.5), at(-w * 0.5 + i * w / n, 0.106, z))
			k.box(Vector3(w, 0.04, 0.06), lit(c(t, "trim"), 0.5), at(0, 0.12, z + d * 0.5 - 0.03))


# ---------------------------------------------------------------- volumes

## A building block on the ground (or at y0): walls, a parapet or roof edge,
## window rows on the faces listed in `faces` ("f" front +z, "b", "l", "r"),
## floors marked every 3 m. Returns the roof height.
static func block(k: MeshKit, center: Vector3, size: Vector3, t: int, faces := "f", floors := 1, wall_key := "wall") -> float:
	var p := pal(t)
	var wc: Color = p[wall_key]
	k.rbox(size, 0.04 if t >= 2 else 0.02, wc, at(center.x, center.y + size.y * 0.5, center.z), 1)
	var top := center.y + size.y
	# roof edge
	match t:
		0:
			k.box(Vector3(size.x + 0.3, 0.06, size.z + 0.3), p["roof"], at(center.x, top + 0.03, center.z))
			for i in int(size.x / 0.3):
				k.box(Vector3(0.03, 0.03, size.z + 0.3), p["roof"].darkened(0.12), at(center.x - size.x * 0.5 + 0.15 + i * 0.3, top + 0.07, center.z))
		1:
			k.box(Vector3(size.x + 0.1, 0.12, size.z + 0.1), p["trim"], at(center.x, top + 0.06, center.z))
		_:
			parapet(k, Vector3(center.x, top, center.z), size.x, size.z, t)
	# storey lines
	if floors > 1:
		for f in range(1, floors):
			var y := center.y + size.y * f / floors
			k.box(Vector3(size.x + 0.03, 0.06, size.z + 0.03), p["trim"] if t != 2 else p["wall2"], at(center.x, y, center.z))
	# windows
	var fh := size.y / floors
	for f in floors:
		var wy := center.y + fh * f + fh * 0.55
		var wh := fh * 0.42
		for face in faces:
			match face:
				"f": window_row(k, xf(Vector3(center.x, wy, center.z + size.z * 0.5)), size.x - 0.5, wh, t)
				"b": window_row(k, xf(Vector3(center.x, wy, center.z - size.z * 0.5), Vector3(0, 180, 0)), size.x - 0.5, wh, t)
				"l": window_row(k, xf(Vector3(center.x - size.x * 0.5, wy, center.z), Vector3(0, -90, 0)), size.z - 0.5, wh, t)
				"r": window_row(k, xf(Vector3(center.x + size.x * 0.5, wy, center.z), Vector3(0, 90, 0)), size.z - 0.5, wh, t)
	return top


## A parapet around a flat roof at height y (and a roof membrane).
static func parapet(k: MeshKit, p: Vector3, w: float, d: float, t: int) -> void:
	var col := c(t, "trim") if t != 2 else c(t, "wall2")
	var h := 0.22 + 0.04 * t
	k.box(Vector3(w - 0.1, 0.03, d - 0.1), c(t, "roof"), at(p.x, p.y + 0.015, p.z))
	k.box(Vector3(w, h, 0.1), col, at(p.x, p.y + h * 0.5, p.z + d * 0.5 - 0.05))
	k.box(Vector3(w, h, 0.1), col, at(p.x, p.y + h * 0.5, p.z - d * 0.5 + 0.05))
	k.box(Vector3(0.1, h, d), col, at(p.x - w * 0.5 + 0.05, p.y + h * 0.5, p.z))
	k.box(Vector3(0.1, h, d), col, at(p.x + w * 0.5 - 0.05, p.y + h * 0.5, p.z))
	if t >= 3:
		k.box(Vector3(w + 0.02, 0.03, 0.03), lit(c(t, "glow" if t == 4 else "accent2"), 0.45), at(p.x, p.y + h, p.z + d * 0.5))


## A row of windows centred on a face (local frame: face at z=0, facing +z).
static func window_row(k: MeshKit, face: Transform3D, w: float, h: float, t: int) -> void:
	var p := pal(t)
	if w <= 0.3:
		return
	match t:
		0:
			var n := maxi(1, int(w / 1.4))
			for i in n:
				var x := -w * 0.5 + (i + 0.5) * w / n
				k.box(Vector3(0.62, h * 0.8 + 0.1, 0.05), p["frame"], face * at(x, 0, 0.02))
				k.box(Vector3(0.52, h * 0.8, 0.05), p["glass"], face * at(x, 0, 0.04))
				k.box(Vector3(0.03, h * 0.8, 0.06), p["frame"], face * at(x, 0, 0.05))
		1:
			var n2 := maxi(1, int(w / 1.0))
			for i in n2:
				var x2 := -w * 0.5 + (i + 0.5) * w / n2
				k.box(Vector3(0.7, h * 0.6, 0.04), p["glass"], face * at(x2, 0, 0.03))
				k.box(Vector3(0.78, 0.05, 0.08), p["trim"], face * at(x2, -h * 0.3 - 0.02, 0.05))
		2:
			k.box(Vector3(w, h, 0.04), p["glass"], face * at(0, 0, 0.03))
			var n3 := maxi(2, int(w / 0.7))
			for i in n3 + 1:
				k.box(Vector3(0.04, h + 0.04, 0.06), p["frame"], face * at(-w * 0.5 + i * w / n3, 0, 0.05))
			k.box(Vector3(w + 0.06, 0.05, 0.08), p["trim"], face * at(0, h * 0.5 + 0.02, 0.05))
		3:
			k.box(Vector3(w, h * 0.7, 0.04), p["glass"], face * at(0, 0, 0.03))
			var n4 := maxi(2, int(w / 0.5))
			for i in n4 + 1:
				k.box(Vector3(0.05, h * 0.7 + 0.04, 0.07), p["frame"], face * at(-w * 0.5 + i * w / n4, 0, 0.05))
			# louvred sunshades
			for j in 2:
				k.box(Vector3(w, 0.03, 0.18), p["metal"], face * at(0, h * 0.4 + j * 0.08, 0.12))
		4:
			k.box(Vector3(w, h, 0.04), p["glass"], face * at(0, 0, 0.03))
			var n5 := maxi(2, int(w / 0.45))
			for i in n5 + 1:
				k.box(Vector3(0.06, h + 0.2, 0.14), p["wall2"], face * at(-w * 0.5 + i * w / n5, 0, 0.08))
			k.box(Vector3(w + 0.1, 0.03, 0.05), lit(p["glow"], 0.45), face * at(0, -h * 0.5 - 0.06, 0.08))


## A glass curtain wall with mullions (local face frame, size w x h, bottom at y=0).
static func curtain(k: MeshKit, face: Transform3D, w: float, h: float, t: int, cols := 0, rows := 0) -> void:
	var p := pal(t)
	cols = cols if cols > 0 else maxi(2, int(w / 0.6))
	rows = rows if rows > 0 else maxi(1, int(h / 0.9))
	k.box(Vector3(w, h, 0.04), p["glass"], face * at(0, h * 0.5, 0.02))
	for i in cols + 1:
		k.box(Vector3(0.05, h, 0.07), p["frame"], face * at(-w * 0.5 + i * w / cols, h * 0.5, 0.04))
	for j in rows + 1:
		k.box(Vector3(w, 0.05, 0.07), p["frame"], face * at(0, j * h / rows, 0.04))


## Corrugated cladding: ribs over a panel (local face frame, bottom at y=0).
static func corrugated(k: MeshKit, face: Transform3D, w: float, h: float, col: Color, pitch := 0.16) -> void:
	k.box(Vector3(w, h, 0.03), col, face * at(0, h * 0.5, 0.015))
	var n := int(w / pitch)
	for i in n:
		k.box(Vector3(0.04, h, 0.03), col.darkened(0.12), face * at(-w * 0.5 + (i + 0.5) * w / n, h * 0.5, 0.04))


## Plank cladding (garage): horizontal boards with gaps.
static func planks(k: MeshKit, face: Transform3D, w: float, h: float, col: Color) -> void:
	var n := maxi(2, int(h / 0.2))
	for j in n:
		var shade := col.darkened(0.06 * (j % 3))
		k.box(Vector3(w, h / n - 0.02, 0.04), shade, face * at(0, (j + 0.5) * h / n, 0.02))


## A roll-up door (local face frame, bottom at y=0).
static func rollup(k: MeshKit, face: Transform3D, w: float, h: float, col: Color, open := 0.0) -> void:
	var shut := h * (1.0 - open)
	k.box(Vector3(w + 0.16, 0.22, 0.2), col.darkened(0.2), face * at(0, h + 0.11, 0.1))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.07, h, 0.1), col.darkened(0.25), face * at(sx * (w * 0.5 + 0.035), h * 0.5, 0.05))
	var n := maxi(1, int(shut / 0.14))
	for j in n:
		k.box(Vector3(w, shut / n - 0.015, 0.04), col if j % 2 == 0 else col.darkened(0.06), face * at(0, h - (j + 0.5) * shut / n, 0.04))
	if open > 0.0:
		k.box(Vector3(w, h - shut, 0.02), Color(0.1, 0.1, 0.12), face * at(0, (h - shut) * 0.5, 0.01))


## A plain door with frame (local face frame).
static func door(k: MeshKit, face: Transform3D, t: int, w := 0.8, h := 1.9) -> void:
	var p := pal(t)
	k.box(Vector3(w + 0.12, h + 0.08, 0.06), p["frame"], face * at(0, (h + 0.08) * 0.5, 0.03))
	if t >= 2:
		k.box(Vector3(w, h, 0.05), p["glass"], face * at(0, h * 0.5, 0.05))
		k.box(Vector3(0.03, h, 0.07), p["frame"], face * at(0, h * 0.5, 0.06))
	else:
		k.box(Vector3(w, h, 0.05), p["wall2"].darkened(0.2), face * at(0, h * 0.5, 0.05))
		k.box(Vector3(0.05, 0.12, 0.05), p["metal"], face * at(w * 0.35, h * 0.5, 0.09))
	if t >= 1:
		k.box(Vector3(w + 0.5, 0.06, 0.6), p["trim"], face * at(0, h + 0.25, 0.3))
	if t >= 3:
		k.box(Vector3(w, 0.03, 0.03), lit(p["glow"], 0.4), face * at(0, h + 0.2, 0.6))


## Louvred vent panel (local face frame).
static func louvres(k: MeshKit, face: Transform3D, w: float, h: float, col: Color, n := 0) -> void:
	n = n if n > 0 else maxi(2, int(h / 0.1))
	k.box(Vector3(w + 0.06, h + 0.06, 0.04), col.darkened(0.2), face * at(0, h * 0.5, 0.02))
	for j in n:
		k.box(Vector3(w, 0.03, 0.08), col, xf(Vector3.ZERO) * face * xf(Vector3(0, (j + 0.5) * h / n, 0.06), Vector3(-30, 0, 0)))


# ---------------------------------------------------------------- circulation

## Railing from a to b (posts and two rails) at height h.
static func railing(k: MeshKit, a: Vector3, b: Vector3, h: float, col: Color, post_gap := 0.8) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.05:
		return
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var mid := (a + b) * 0.5
	k.box(Vector3(0.04, 0.04, len), col, xf(mid + Vector3(0, h, 0), Vector3(0, yaw, 0)))
	k.box(Vector3(0.03, 0.03, len), col, xf(mid + Vector3(0, h * 0.5, 0), Vector3(0, yaw, 0)))
	var n := maxi(1, int(len / post_gap))
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		k.box(Vector3(0.04, h, 0.04), col, at(q.x, q.y + h * 0.5, q.z))


## A straight stair from p (bottom front) rising `rise` along local -z, width w.
static func stairs(k: MeshKit, base: Transform3D, w: float, rise: float, t: int, rail := true) -> void:
	var p := pal(t)
	var n := maxi(3, int(rise / 0.2))
	var run := rise * 1.1
	for i in n:
		k.box(Vector3(w, 0.05, run / n + 0.02), p["metal"] if t != 0 else p["trim"], base * at(0, (i + 1) * rise / n - 0.025, -(i + 0.5) * run / n))
	var ang := rad_to_deg(atan2(rise, run))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.12, sqrt(rise * rise + run * run)), p["trim"], base * xf(Vector3(sx * w * 0.5, rise * 0.5, -run * 0.5), Vector3(ang, 0, 0)))
		if rail:
			k.box(Vector3(0.04, 0.04, sqrt(rise * rise + run * run)), c(t, "accent") if t == 1 or t == 3 else p["metal"], base * xf(Vector3(sx * w * 0.5, rise * 0.5 + 0.9, -run * 0.5), Vector3(ang, 0, 0)))
			k.box(Vector3(0.04, 0.9, 0.04), p["metal"], base * at(sx * w * 0.5, 0.45, 0))
			k.box(Vector3(0.04, 0.9, 0.04), p["metal"], base * at(sx * w * 0.5, rise + 0.45, -run))


## A ladder up a wall (base on the ground, against local -z), cage from 2 m.
static func ladder(k: MeshKit, base: Transform3D, h: float, col: Color, cage := false) -> void:
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, h, 0.04), col, base * at(sx * 0.2, h * 0.5, 0.12))
	for i in int(h / 0.3):
		k.box(Vector3(0.4, 0.03, 0.03), col, base * at(0, 0.25 + i * 0.3, 0.12))
	if cage and h > 2.2:
		for i in int((h - 2.0) / 0.6) + 1:
			k.torus(0.3, 0.015, col, base * xf(Vector3(0, 2.0 + i * 0.6, 0.38), Vector3.ZERO, Vector3(1, 1, 1)), 10, 3, PI)


## A catwalk (grating deck with railings) from a to b at height y, width w.
static func catwalk(k: MeshKit, a: Vector3, b: Vector3, w: float, t: int, supports := true) -> void:
	var d := b - a
	var len := d.length()
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var mid := (a + b) * 0.5
	var p := pal(t)
	k.box(Vector3(w, 0.05, len), p["metal"].darkened(0.15), xf(mid, Vector3(0, yaw, 0)))
	for i in int(len / 0.25):
		k.box(Vector3(w, 0.02, 0.03), p["metal"].darkened(0.3), xf(mid, Vector3(0, yaw, 0)) * at(0, 0.03, -len * 0.5 + (i + 0.5) * 0.25))
	var side := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw))) * w * 0.5
	var rc: Color = p["accent"] if t == 1 or t == 3 else p["metal"]
	railing(k, a + side, b + side, 0.9, rc)
	railing(k, a - side, b - side, 0.9, rc)
	if supports and a.y > 0.3:
		var n := maxi(1, int(len / 2.5))
		for i in n + 1:
			var q := a.lerp(b, float(i) / n)
			k.box(Vector3(0.08, q.y, 0.08), p["trim"], at(q.x, q.y * 0.5, q.z))


## A steel truss beam from a to b (square section s).
static func truss(k: MeshKit, a: Vector3, b: Vector3, s: float, col: Color) -> void:
	var d := b - a
	var len := d.length()
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var pitch := -rad_to_deg(asin(clampf(d.y / maxf(len, 0.001), -1.0, 1.0)))
	var base := xf((a + b) * 0.5, Vector3(pitch, yaw, 0))
	for sx in [-1.0, 1.0]:
		for sy in [-1.0, 1.0]:
			k.box(Vector3(0.035, 0.035, len), col, base * at(sx * s * 0.5, sy * s * 0.5, 0))
	var n := maxi(1, int(len / s))
	for i in n:
		var z := -len * 0.5 + (i + 0.5) * len / n
		k.box(Vector3(s, 0.025, 0.025), col, base * xf(Vector3(0, 0, z), Vector3(0, 0, 45 if i % 2 else -45)))


# ---------------------------------------------------------------- plant

## A rooftop AC unit (base at origin): casing, a fan grille, side louvres.
static func ac_unit(k: MeshKit, base: Transform3D, t: int, s := 1.0) -> void:
	var p := pal(t)
	var col: Color = Color(0.86, 0.87, 0.88) if t < 4 else p["wall2"]
	k.box(Vector3(0.9, 0.55, 0.7) * s, col, base * at(0, 0.275 * s, 0))
	k.cyl(0.26 * s, 0.03, Color(0.2, 0.21, 0.24), base * at(0, 0.55 * s, 0), 10)
	k.box(Vector3(0.5, 0.02, 0.04) * s, Color(0.5, 0.52, 0.56), base * at(0, 0.58 * s, 0))
	k.box(Vector3(0.04, 0.02, 0.5) * s, Color(0.5, 0.52, 0.56), base * at(0, 0.58 * s, 0))
	for j in 4:
		k.box(Vector3(0.02, 0.04, 0.6) * s, col.darkened(0.2), base * at(0.455 * s, (0.1 + j * 0.1) * s, 0))
	if t >= 3:
		k.box(Vector3(0.2, 0.04, 0.02) * s, lit(p["glow"]), base * at(-0.2 * s, 0.45 * s, 0.355 * s))


## A chiller: a long casing with a row of fans on top (len along local x).
static func chiller(k: MeshKit, base: Transform3D, len: float, t: int, fans := 0) -> void:
	var p := pal(t)
	var col: Color = Color(0.9, 0.91, 0.92) if t < 4 else p["wall2"]
	fans = fans if fans > 0 else maxi(1, int(len / 0.9))
	k.box(Vector3(len, 0.9, 1.0), col, base * at(0, 0.5, 0))
	k.box(Vector3(len + 0.06, 0.1, 1.06), p["trim"], base * at(0, 0.05, 0))
	for i in fans:
		var x := -len * 0.5 + (i + 0.5) * len / fans
		k.cyl(0.36, 0.08, Color(0.22, 0.23, 0.26), base * at(x, 0.95, 0), 12)
		k.box(Vector3(0.66, 0.02, 0.04), Color(0.55, 0.57, 0.6), base * at(x, 1.0, 0))
	for sz in [-1.0, 1.0]:
		louvres(k, base * xf(Vector3(0, 0.12, sz * 0.5), Vector3(0, 0 if sz > 0 else 180, 0)), len - 0.2, 0.6, col.darkened(0.08), 5)
	if t >= 3:
		k.box(Vector3(len - 0.1, 0.03, 0.02), lit(p["glow"] if t == 4 else p["accent2"], 0.45), base * at(0, 0.88, 0.51))


## A hyperbolic cooling tower (base on the ground).
static func cooling_tower(k: MeshKit, base: Transform3D, r: float, h: float, t: int) -> void:
	var col: Color = Color(0.86, 0.86, 0.84) if t < 4 else Color(0.28, 0.29, 0.33)
	k.lathe(PackedVector2Array([Vector2(r, 0), Vector2(r * 0.86, h * 0.35), Vector2(r * 0.66, h * 0.75), Vector2(r * 0.7, h), Vector2(r * 0.64, h)]), col, base, 16)
	k.cyl(r * 0.62, 0.05, Color(0.3, 0.32, 0.34), base * at(0, h - 0.06, 0), 14)
	for i in 6:
		var a := TAU * i / 6.0
		k.box(Vector3(0.08, 0.5, 0.08), col.darkened(0.2), base * at(cos(a) * r * 0.97, 0.25, sin(a) * r * 0.97))
	if t >= 3:
		k.torus(r * 0.69, 0.03, lit(c(t, "glow")), base * at(0, h * 0.98, 0), 18, 4)


## A vertical tank with a domed top (base on the ground).
static func tank(k: MeshKit, base: Transform3D, r: float, h: float, col: Color, t := 2) -> void:
	k.cyl(r, h, col, base, 14, 0.04)
	k.sphere(r, col, base * xf(Vector3(0, h, 0), Vector3.ZERO, Vector3(1, 0.4, 1)), 14, 5)
	for i in 3:
		k.cyl(r + 0.015, 0.04, col.darkened(0.15), base * at(0, h * (0.25 + i * 0.25), 0), 14, 0.0, -1.0, false)
	k.box(Vector3(0.05, h, 0.05), Color(0.4, 0.42, 0.46), base * at(r + 0.04, h * 0.5, 0))
	if t >= 3:
		k.box(Vector3(0.04, h * 0.6, 0.02), lit(c(t, "glow")), base * at(0, h * 0.5, r + 0.01))


## A horizontal tank on saddles (len along local x).
static func hz_tank(k: MeshKit, base: Transform3D, r: float, len: float, col: Color) -> void:
	# the capsule grows along +y from its base: rotated onto -x, so start it at +len/2
	k.capsule(r, len, col, base * xf(Vector3(len * 0.5, r + 0.25, 0), Vector3(0, 0, 90)), 12, 3)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.2, r + 0.25, r * 1.4), Color(0.35, 0.36, 0.4), base * at(sx * len * 0.3, (r + 0.25) * 0.5, 0))


## A generator set in its enclosure, exhaust stack and fuel tank under it.
static func generator(k: MeshKit, base: Transform3D, t: int) -> void:
	var col: Color = [Color(0.36, 0.56, 0.38), Color(0.92, 0.72, 0.2), Color(0.92, 0.93, 0.94), Color(0.36, 0.4, 0.46), Color(0.2, 0.21, 0.24)][clampi(t, 0, 4)]
	k.box(Vector3(2.2, 0.25, 1.0), Color(0.25, 0.26, 0.28), base * at(0, 0.125, 0))
	k.rbox(Vector3(2.1, 1.1, 0.95), 0.04, col, base * at(0, 0.8, 0), 1)
	louvres(k, base * at(-0.6, 0.45, 0.48), 0.6, 0.6, col.darkened(0.1), 6)
	louvres(k, base * at(0.6, 0.45, 0.48), 0.6, 0.6, col.darkened(0.1), 6)
	k.cyl(0.07, 0.9, Color(0.34, 0.34, 0.36), base * at(0.8, 1.35, -0.2), 8)
	k.cyl(0.09, 0.08, Color(0.2, 0.2, 0.22), base * at(0.8, 2.25, -0.2), 8)
	k.box(Vector3(0.3, 0.2, 0.02), Color(0.98, 0.84, 0.3), base * at(-0.8, 1.05, 0.48))


## A pad-mounted transformer with fins and an insulator top.
static func transformer(k: MeshKit, base: Transform3D, t: int) -> void:
	var col := Color(0.56, 0.6, 0.5) if t < 3 else Color(0.4, 0.44, 0.5)
	k.box(Vector3(1.2, 0.15, 1.0), Color(0.6, 0.6, 0.58), base * at(0, 0.075, 0))
	k.box(Vector3(0.8, 1.0, 0.6), col, base * at(0, 0.65, 0))
	for i in 6:
		k.box(Vector3(0.03, 0.8, 0.22), col.darkened(0.15), base * at(-0.36 + i * 0.144, 0.6, 0.41))
		k.box(Vector3(0.03, 0.8, 0.22), col.darkened(0.15), base * at(-0.36 + i * 0.144, 0.6, -0.41))
	for i in 3:
		k.cyl(0.05, 0.3, Color(0.86, 0.6, 0.4), base * at(-0.25 + i * 0.25, 1.15, 0), 6)
		k.sphere(0.06, Color(0.86, 0.6, 0.4), base * at(-0.25 + i * 0.25, 1.47, 0), 6, 4)
	k.box(Vector3(0.18, 0.18, 0.01), Color(0.98, 0.84, 0.3), base * at(0, 0.7, 0.305))


## A row of solar panels on a tilted frame (n panels along local x).
static func solar(k: MeshKit, base: Transform3D, n: int, t: int, tilt := 25.0, h := 0.5) -> void:
	var frame: Color = Color(0.6, 0.62, 0.64) if t < 4 else c(t, "trim")
	for i in n:
		var x := (i - (n - 1) * 0.5) * 0.92
		k.box(Vector3(0.88, 0.04, 0.6), Color(0.16, 0.24, 0.44), base * xf(Vector3(x, h, 0), Vector3(-tilt, 0, 0)))
		k.box(Vector3(0.02, 0.045, 0.6), Color(0.6, 0.64, 0.7), base * xf(Vector3(x, h + 0.003, 0), Vector3(-tilt, 0, 0)))
		k.box(Vector3(0.04, h + 0.1, 0.04), frame, base * at(x, h * 0.5, -0.2))
		k.box(Vector3(0.04, h - 0.1, 0.04), frame, base * at(x, (h - 0.1) * 0.5, 0.2))


## A run of pipe through points (elbow spheres at the joints).
static func pipes(k: MeshKit, pts: Array, r: float, col: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := b - a
		var len := d.length()
		if len < 0.01:
			continue
		var up := Vector3.UP
		var basis := Basis(Quaternion(up, d.normalized())) if absf(d.normalized().dot(up)) < 0.999 else (Basis.IDENTITY if d.y > 0 else Basis(Vector3.RIGHT, PI))
		k.cyl(r, len, col, Transform3D(basis, a), 8)
		if i > 0:
			k.sphere(r * 1.15, col, at(a.x, a.y, a.z), 8, 5)


## A pipe rack: frames along local x with n pipes on top.
static func pipe_rack(k: MeshKit, base: Transform3D, len: float, h: float, t: int, n := 3) -> void:
	var p := pal(t)
	var frames := maxi(2, int(len / 1.5) + 1)
	for i in frames:
		var x := -len * 0.5 + i * len / (frames - 1)
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.08, h, 0.08), p["trim"], base * at(x, h * 0.5, sz * 0.35))
		k.box(Vector3(0.08, 0.08, 0.86), p["trim"], base * at(x, h, 0))
	var cols := [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84), Color(0.9, 0.5, 0.3), Color(0.5, 0.78, 0.5)]
	for j in n:
		var pc: Color = cols[j % cols.size()] if t < 4 else (lit(p["accent2"], 0.5) if j == 0 else p["metal"])
		k.cyl(0.07, len, pc, base * xf(Vector3(-len * 0.5, h + 0.1, -0.25 + j * 0.5 / maxf(1, n - 1)), Vector3(0, 0, -90)), 8)


## A cable tray from a to b (open channel with cable bundles).
static func cable_tray(k: MeshKit, a: Vector3, b: Vector3, t: int) -> void:
	var d := b - a
	var len := d.length()
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var base := xf((a + b) * 0.5, Vector3(0, yaw, 0))
	k.box(Vector3(0.3, 0.02, len), Color(0.6, 0.62, 0.64), base)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.02, 0.08, len), Color(0.6, 0.62, 0.64), base * at(sx * 0.15, 0.04, 0))
	var cc := [Color(0.2, 0.4, 0.8), Color(0.9, 0.6, 0.2), Color(0.25, 0.25, 0.27)]
	for i in 3:
		k.box(Vector3(0.06, 0.05, len), cc[i] if t < 4 else lit(c(t, "accent2"), 0.5) if i == 0 else cc[i], base * at(-0.08 + i * 0.08, 0.04, 0))


# ---------------------------------------------------------------- site

## A fence from a to b: chain-link (0-1), panel (2), steel bars (3), glass and brass (4).
static func fence(k: MeshKit, a: Vector3, b: Vector3, t: int, h := 1.1) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.05:
		return
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var base := xf((a + b) * 0.5, Vector3(0, yaw, 0))
	var n := maxi(1, int(len / 1.6))
	match t:
		0:
			for i in n + 1:
				k.box(Vector3(0.08, h, 0.08), c(t, "trim"), base * at(0, h * 0.5, -len * 0.5 + i * len / n))
			for j in 2:
				k.box(Vector3(0.03, 0.08, len), c(t, "wall2"), base * at(0, 0.35 + j * 0.45, 0))
		1:
			for i in n + 1:
				k.cyl(0.03, h, Color(0.6, 0.62, 0.64), base * at(0, 0, -len * 0.5 + i * len / n), 6)
			k.box(Vector3(0.01, h * 0.9, len), Color(0.62, 0.64, 0.66, 1.0).darkened(0.25), base * at(0, h * 0.47, 0))
			k.box(Vector3(0.04, 0.04, len), Color(0.6, 0.62, 0.64), base * at(0, h, 0))
		2:
			for i in n + 1:
				k.box(Vector3(0.06, h, 0.06), c(t, "trim"), base * at(0, h * 0.5, -len * 0.5 + i * len / n))
			k.box(Vector3(0.03, h * 0.6, len), c(t, "wall2"), base * at(0, h * 0.4, 0))
		3:
			for i in int(len / 0.15) + 1:
				k.box(Vector3(0.03, h, 0.03), c(t, "trim"), base * at(0, h * 0.5, -len * 0.5 + i * 0.15))
			k.box(Vector3(0.05, 0.05, len), c(t, "trim"), base * at(0, h, 0))
			k.box(Vector3(0.05, 0.05, len), c(t, "trim"), base * at(0, 0.1, 0))
		4:
			k.box(Vector3(0.03, h, len), c(t, "glass"), base * at(0, h * 0.5, 0))
			k.box(Vector3(0.06, 0.05, len), c(t, "trim"), base * at(0, h, 0))
			for i in n + 1:
				k.box(Vector3(0.07, h, 0.07), c(t, "trim"), base * at(0, h * 0.5, -len * 0.5 + i * len / n))


## A lamp post with its head (base on the ground).
static func lamp(k: MeshKit, p: Vector3, t: int, h := 2.4) -> void:
	var p_ := pal(t)
	k.cyl(0.04, h, p_["dark"] if t != 2 else Color(0.85, 0.86, 0.88), at(p.x, p.y, p.z), 6)
	k.box(Vector3(0.36, 0.05, 0.1), p_["dark"] if t != 2 else Color(0.85, 0.86, 0.88), at(p.x + 0.14, p.y + h, p.z))
	k.box(Vector3(0.22, 0.03, 0.08), lit(p_["glow"], 0.35), at(p.x + 0.2, p.y + h - 0.03, p.z))


## Clutter for scrappy tiers: crates, a pallet, barrels, a tarp pile (seeded).
static func clutter(k: MeshKit, p: Vector3, t: int, seed := 0) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 7919 * (seed + 1)
	for i in 3 + r.randi_range(0, 3):
		var o := Vector3(r.randf_range(-0.5, 0.5), 0, r.randf_range(-0.4, 0.4))
		match r.randi_range(0, 3):
			0:
				k.box(Vector3(0.36, 0.3, 0.36), Color(0.72, 0.56, 0.38) if t == 0 else Color(0.36, 0.5, 0.36), xf(p + o + Vector3(0, 0.15, 0), Vector3(0, r.randf_range(-20, 20), 0)))
			1:
				k.cyl(0.16, 0.48, [Color(0.3, 0.46, 0.7), Color(0.78, 0.3, 0.26), Color(0.2, 0.5, 0.3)][r.randi_range(0, 2)], at(p.x + o.x, p.y, p.z + o.z), 10, 0.02)
			2:
				for j in 3:
					k.box(Vector3(0.7, 0.04, 0.1), Color(0.66, 0.52, 0.36), at(p.x + o.x, p.y + 0.02, p.z + o.z - 0.25 + j * 0.25))
				k.box(Vector3(0.1, 0.06, 0.6), Color(0.6, 0.46, 0.3), at(p.x + o.x, p.y + 0.07, p.z + o.z))
			3:
				k.rbox(Vector3(0.6, 0.25, 0.45), 0.1, Color(0.26, 0.46, 0.78) if t == 0 else Color(0.5, 0.52, 0.56), xf(p + o + Vector3(0, 0.12, 0), Vector3(0, r.randf_range(-30, 30), 0)), 1)


## A string of glowing bulbs sagging from a to b.
static func string_lights(k: MeshKit, a: Vector3, b: Vector3, n := 8, col := Color(1.0, 0.82, 0.5)) -> void:
	for i in n + 1:
		var f := float(i) / n
		var q := a.lerp(b, f) - Vector3(0, sin(f * PI) * 0.25, 0)
		k.sphere(0.04, lit(col, 0.3), at(q.x, q.y, q.z), 6, 4)
	pipes(k, [a, a.lerp(b, 0.5) - Vector3(0, 0.25, 0), b], 0.008, Color(0.15, 0.15, 0.16))


## A sign board on two posts or mounted (local face frame, bottom at y=0).
static func sign(k: MeshKit, face: Transform3D, w: float, h: float, t: int, posts := 0.0) -> void:
	var p := pal(t)
	if posts > 0.0:
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.06, posts, 0.06), p["trim"], face * at(sx * w * 0.4, posts * 0.5, 0))
	var y := posts + h * 0.5
	match t:
		0:
			k.box(Vector3(w, h, 0.05), Color(0.94, 0.92, 0.86), face * xf(Vector3(0, y, 0.03), Vector3(0, 0, 2)))
			k.box(Vector3(w * 0.7, h * 0.3, 0.02), p["accent"], face * xf(Vector3(0, y, 0.065), Vector3(0, 0, 2)))
		1:
			k.box(Vector3(w, h, 0.05), p["accent"], face * at(0, y, 0.03))
			k.box(Vector3(w * 0.8, h * 0.35, 0.02), p["dark"], face * at(0, y, 0.065))
		2:
			k.box(Vector3(w, h, 0.08), Color(0.97, 0.97, 0.98), face * at(0, y, 0.04))
			k.box(Vector3(h * 0.6, h * 0.6, 0.02), p["accent"], face * at(-w * 0.35, y, 0.09))
			k.box(Vector3(w * 0.5, h * 0.18, 0.02), p["dark"], face * at(w * 0.08, y, 0.09))
		3:
			k.box(Vector3(w, h, 0.08), p["dark"], face * at(0, y, 0.04))
			k.box(Vector3(w * 0.8, h * 0.3, 0.02), lit(p["glow"], 0.4), face * at(0, y, 0.09))
		4:
			k.box(Vector3(w, h, 0.06), p["dark"], face * at(0, y, 0.03))
			k.box(Vector3(w + 0.06, 0.03, 0.08), p["trim"], face * at(0, y + h * 0.5, 0.04))
			k.box(Vector3(w + 0.06, 0.03, 0.08), p["trim"], face * at(0, y - h * 0.5, 0.04))
			k.box(Vector3(w * 0.85, h * 0.4, 0.02), lit(p["accent2"], 0.4), face * at(0, y, 0.07))


## Glowing vertical fins (hyperscale): n fins across w (local face frame).
static func fins(k: MeshKit, face: Transform3D, w: float, h: float, n: int, t := 4) -> void:
	for i in n:
		var x := -w * 0.5 + (i + 0.5) * w / n
		k.box(Vector3(0.08, h, 0.3), c(t, "wall2"), face * at(x, h * 0.5, 0.15))
		k.box(Vector3(0.02, h * 0.9, 0.02), lit(c(t, "glow"), 0.4), face * at(x, h * 0.5, 0.31))


## A blinking-red aviation beacon on a short mast.
static func beacon(k: MeshKit, p: Vector3, h := 0.5) -> void:
	k.cyl(0.02, h, Color(0.4, 0.42, 0.46), at(p.x, p.y, p.z), 5)
	k.sphere(0.06, lit(Color(1.0, 0.3, 0.25), 0.3), at(p.x, p.y + h, p.z), 6, 4)


## A drone pad (hyperscale roofs): disc, H marking, edge lights.
static func drone_pad(k: MeshKit, p: Vector3, r: float, t := 4) -> void:
	k.cyl(r, 0.06, c(t, "dark"), at(p.x, p.y, p.z), 16)
	k.box(Vector3(r * 0.12, 0.02, r * 0.9), c(t, "trim"), at(p.x - r * 0.25, p.y + 0.065, p.z))
	k.box(Vector3(r * 0.12, 0.02, r * 0.9), c(t, "trim"), at(p.x + r * 0.25, p.y + 0.065, p.z))
	k.box(Vector3(r * 0.5, 0.02, r * 0.12), c(t, "trim"), at(p.x, p.y + 0.065, p.z))
	for i in 8:
		var a := TAU * i / 8.0
		k.sphere(0.04, lit(c(t, "glow"), 0.3), at(p.x + cos(a) * r * 0.92, p.y + 0.08, p.z + sin(a) * r * 0.92), 5, 3)


## A planter box with a shrub or small tree.
static func planter(k: MeshKit, p: Vector3, t: int, w := 0.8, tree := false) -> void:
	var box_c: Color = [Color(0.6, 0.45, 0.3), Color(0.5, 0.52, 0.56), Color(0.92, 0.93, 0.94), Color(0.36, 0.38, 0.42), Color(0.2, 0.21, 0.24)][clampi(t, 0, 4)]
	k.box(Vector3(w, 0.4, w * 0.6), box_c, at(p.x, p.y + 0.2, p.z))
	if t == 4:
		k.box(Vector3(w + 0.02, 0.03, w * 0.6 + 0.02), c(t, "trim"), at(p.x, p.y + 0.4, p.z))
	if tree:
		k.cyl(0.04, 0.9, Color(0.4, 0.3, 0.22), at(p.x, p.y + 0.4, p.z), 5)
		k.sphere(0.35, Color(0.4, 0.58, 0.34), at(p.x, p.y + 1.45, p.z), 8, 5)
	else:
		k.sphere(w * 0.32, Color(0.42, 0.6, 0.36), xf(Vector3(p.x, p.y + 0.45, p.z), Vector3.ZERO, Vector3(1.3, 0.7, 0.9)), 8, 4)


## A parked vehicle for the lot: hatchback (0), van (1), sedan (2), SUV (3), pod (4).
static func vehicle(k: MeshKit, base: Transform3D, t: int, col := Color.TRANSPARENT) -> void:
	var body: Color = col if col.a > 0.0 else [Color(0.7, 0.32, 0.26), Color(0.94, 0.94, 0.92), Color(0.3, 0.46, 0.66), Color(0.24, 0.25, 0.28), Color(0.12, 0.12, 0.14)][clampi(t, 0, 4)]
	var l: float = [1.5, 1.9, 1.7, 1.8, 1.4][clampi(t, 0, 4)]
	var h: float = [0.5, 0.8, 0.42, 0.55, 0.4][clampi(t, 0, 4)]
	k.rbox(Vector3(0.8, 0.32, l), 0.08, body, base * at(0, 0.3, 0), 1)
	k.rbox(Vector3(0.72, h, l * (0.6 if t != 1 else 0.85)), 0.08, body, base * at(0, 0.46 + h * 0.5, -l * (0.08 if t != 1 else 0.05)), 1)
	k.box(Vector3(0.74, h * 0.6, l * 0.5), Color(0.3, 0.4, 0.5) if t < 4 else lit(c(t, "accent2"), 0.5), base * at(0, 0.5 + h * 0.5, -l * 0.08))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.13, 0.1, Color(0.12, 0.12, 0.13), base * xf(Vector3(sx * 0.4, 0.13, sz * l * 0.32), Vector3(0, 0, 90)), 8)
	if t == 4:
		k.box(Vector3(0.82, 0.02, l), lit(c(t, "glow"), 0.4), base * at(0, 0.2, 0))


## Roof equipment filling a rectangle at height y: vents, AC units, a hatch,
## solar on campus roofs, chillers and pipes on industrial ones, fins and a
## drone pad on hyperscale ones. Seeded so the same roof always looks the same.
static func roof_kit(k: MeshKit, rect: Rect2, y: float, t: int, seed := 0) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 104729 * (seed + 3)
	var cx := rect.get_center().x
	var cz := rect.get_center().y
	var w := rect.size.x
	var d := rect.size.y
	# a roof hatch and some vent stacks on every tier
	k.box(Vector3(0.6, 0.18, 0.6), c(t, "trim"), at(rect.position.x + 0.5, y + 0.09, rect.position.y + 0.5))
	for i in 2 + int(w * d / 8.0):
		var p := Vector3(r.randf_range(rect.position.x + 0.3, rect.end.x - 0.3), y, r.randf_range(rect.position.y + 0.3, rect.end.y - 0.3))
		k.cyl(0.07, 0.35, Color(0.62, 0.64, 0.66), at(p.x, p.y, p.z), 6)
		k.cyl(0.11, 0.05, Color(0.5, 0.52, 0.54), at(p.x, p.y + 0.35, p.z), 6)
	match t:
		0:
			k.box(Vector3(minf(1.4, w * 0.5), 0.05, minf(1.0, d * 0.5)), Color(0.26, 0.46, 0.78), xf(Vector3(cx + w * 0.15, y + 0.08, cz), Vector3(0, 8, 3)))
			for i in 4:
				k.box(Vector3(0.18, 0.1, 0.12), Color(0.66, 0.6, 0.52), at(cx - w * 0.3 + i * 0.25, y + 0.05, cz + d * 0.3))
		1:
			for i in mini(3, int(w / 1.2)):
				ac_unit(k, at(rect.position.x + 0.8 + i * 1.1, y, cz), t, 0.9)
			cable_tray(k, Vector3(rect.position.x + 0.4, y + 0.15, rect.end.y - 0.4), Vector3(rect.end.x - 0.4, y + 0.15, rect.end.y - 0.4), t)
		2:
			var n := maxi(1, int((w - 1.0) / 0.95))
			solar(k, at(cx, y, cz - d * 0.2), n, t, 22.0, 0.35)
			if d > 2.0:
				solar(k, at(cx, y, cz + d * 0.15), n, t, 22.0, 0.35)
			ac_unit(k, at(rect.end.x - 0.6, y, rect.end.y - 0.5), t, 0.8)
		3:
			if w > 2.4:
				chiller(k, at(cx, y, cz - d * 0.15), minf(w - 0.6, 3.6), t)
			else:
				ac_unit(k, at(cx, y, cz - d * 0.15), t)
			pipes(k, [Vector3(rect.position.x + 0.3, y + 0.3, rect.end.y - 0.3), Vector3(rect.end.x - 0.3, y + 0.3, rect.end.y - 0.3)], 0.06, Color(0.36, 0.6, 0.86))
			pipes(k, [Vector3(rect.position.x + 0.3, y + 0.45, rect.end.y - 0.45), Vector3(rect.end.x - 0.3, y + 0.45, rect.end.y - 0.45)], 0.05, Color(0.86, 0.86, 0.84))
			beacon(k, Vector3(rect.end.x - 0.25, y, rect.position.y + 0.25))
		4:
			if w > 2.0 and d > 2.0:
				drone_pad(k, Vector3(cx + w * 0.18, y + 0.02, cz + d * 0.1), minf(w, d) * 0.28)
			for i in maxi(2, int(w / 0.5)):
				k.box(Vector3(0.06, 0.5, 0.5), c(t, "wall2"), at(rect.position.x + 0.3 + i * 0.5, y + 0.25, rect.position.y + 0.4))
				k.box(Vector3(0.02, 0.45, 0.02), lit(c(t, "glow"), 0.4), at(rect.position.x + 0.3 + i * 0.5, y + 0.25, rect.position.y + 0.66))
			beacon(k, Vector3(rect.end.x - 0.25, y, rect.position.y + 0.25), 0.8)
