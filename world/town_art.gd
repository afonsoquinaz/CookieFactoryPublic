class_name TownArt
## Looks for the campus: shared pieces (roofs, windows, flags, lamps,
## crates), the Builder's Hut, construction scaffolding and the obstacles on
## new land.
##
## Local frame: building centre at the origin, front facing +Z, metres.


## A gable roof sitting on walls whose top is at `base` (centre), w along the
## ridge, d across it, rising `rise`. along_x = ridge runs along X.
static func gable(k: MeshKit, base: Vector3, w: float, d: float, rise: float, col: Color, end_col: Color, along_x := true, over := 0.3, tiles := true) -> void:
	var half := d * 0.5
	var ang := rad_to_deg(atan2(rise, half))
	var slope := sqrt(half * half + rise * rise) + over
	var ry := 0.0 if along_x else 90.0
	var rot := Basis.from_euler(Vector3(0, deg_to_rad(ry), 0))
	for sd in [-1.0, 1.0]:
		var c := base + rot * Vector3(0, rise * 0.5, sd * (half * 0.5 + over * 0.25))
		var t := Transform3D(rot * Basis.from_euler(Vector3(deg_to_rad(sd * ang), 0, 0)), c)
		k.rbox(Vector3(w + over * 2.0, 0.14, slope), 0.05, col, t)
		if tiles:
			var rows := maxi(2, int(slope / 0.42))
			for r in rows:
				var off := -slope * 0.5 + (r + 0.6) * slope / rows
				k.rbox(Vector3(w + over * 2.0 + 0.02, 0.06, 0.08), 0.03, col.darkened(0.14), t * MeshKit.at(0, 0.08, off))
	# ridge cap
	k.cyl(0.1, w + over * 2.0, col.darkened(0.2), Transform3D(rot * Basis.from_euler(Vector3(0, 0, deg_to_rad(90))), base + Vector3(0, rise + 0.02, 0) + rot * Vector3(w * 0.5 + over, 0, 0)), 8, 0.02)
	# gable ends
	# poly x -> across the ridge, poly y -> up, extrusion -> along the ridge
	var end_basis := rot * Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0))
	var tri := PackedVector2Array([Vector2(-half, 0), Vector2(0, rise), Vector2(half, 0)])
	for sd in [-1.0, 1.0]:
		var x0 := w * 0.5 - 0.12 if sd > 0.0 else -w * 0.5 + 0.02
		k.prism(tri, 0.1, end_col, Transform3D(end_basis, base + rot * Vector3(x0, 0, 0)))


## A window with a frame, sill and optional flower box, facing +Z at p.
static func window(k: MeshKit, p: Vector3, w: float, h: float, frame: Color, glass := Color(0.6, 0.72, 0.78), flowers := false, arch := false) -> void:
	k.rbox(Vector3(w + 0.14, h + 0.14, 0.08), 0.06 if not arch else w * 0.5, frame, MeshKit.at(p.x, p.y, p.z))
	k.rbox(Vector3(w, h, 0.09), 0.04 if not arch else w * 0.45, glass, MeshKit.at(p.x, p.y, p.z + 0.01))
	k.rbox(Vector3(0.04, h, 0.1), 0.01, frame, MeshKit.at(p.x, p.y, p.z + 0.02))
	k.rbox(Vector3(w, 0.04, 0.1), 0.01, frame, MeshKit.at(p.x, p.y + h * 0.1, p.z + 0.02))
	k.rbox(Vector3(w + 0.24, 0.06, 0.18), 0.02, frame.lightened(0.2), MeshKit.at(p.x, p.y - h * 0.5 - 0.06, p.z + 0.06))
	if flowers:
		k.rbox(Vector3(w + 0.1, 0.16, 0.2), 0.04, Pal.WOOD, MeshKit.at(p.x, p.y - h * 0.5 - 0.17, p.z + 0.12))
		for i in 5:
			var c: Color = [Color(0.86, 0.5, 0.52), Color(0.96, 0.92, 0.84), Color(0.9, 0.68, 0.36), Color(0.6, 0.52, 0.72), Pal.LEAF][i]
			k.sphere(0.075, c, MeshKit.at(p.x - w * 0.4 + i * w * 0.2, p.y - h * 0.5 - 0.05, p.z + 0.14), 6, 4)


## A small pennant flag on a pole standing at p.
static func flag(k: MeshKit, p: Vector3, h: float, col: Color, pole := Pal.WOOD_DARK) -> void:
	k.cyl(0.035, h, pole, MeshKit.at(p.x, p.y, p.z), 6)
	k.sphere(0.06, Pal.BRASS, MeshKit.at(p.x, p.y + h + 0.02, p.z), 6, 4)
	k.prism(PackedVector2Array([Vector2(0, 0), Vector2(0.62, 0.17), Vector2(0, 0.34)]), 0.03, col, MeshKit.xf(Vector3(p.x, p.y + h - 0.4, p.z - 0.015), Vector3(-90, 0, 0)))


static func lamp_post(k: MeshKit, p: Vector3, h := 2.2) -> void:
	k.cyl(0.18, 0.18, Pal.STONE_DARK, MeshKit.at(p.x, 0, p.z), 8, 0.03)
	k.cyl(0.05, h, Pal.STEEL_DARK, MeshKit.at(p.x, 0.1, p.z), 8)
	k.rbox(Vector3(0.28, 0.34, 0.28), 0.05, Color(1.0, 0.86, 0.56, 0.45), MeshKit.at(p.x, h + 0.25, p.z))
	k.cone(0.22, 0.2, Pal.STEEL_DARK, MeshKit.at(p.x, h + 0.42, p.z), 8)


static func bench(k: MeshKit, p: Vector3, len := 1.5, rot_y := 0.0) -> void:
	var b := MeshKit.xf(p, Vector3(0, rot_y, 0))
	k.rbox(Vector3(len, 0.08, 0.42), 0.03, Pal.WOOD, b * MeshKit.at(0, 0.42, 0))
	k.rbox(Vector3(len, 0.34, 0.06), 0.03, Pal.WOOD, b * MeshKit.xf(Vector3(0, 0.7, -0.2), Vector3(-10, 0, 0)))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.06, 0.42, 0.4), 0.02, Pal.STEEL_DARK, b * MeshKit.at(sx * (len * 0.5 - 0.12), 0.21, 0))


static func sacks(k: MeshKit, p: Vector3, n := 3) -> void:
	for i in n:
		var q := p + Vector3((i % 2) * 0.48 - 0.24, (i / 2) * 0.38, (i % 3) * 0.08)
		k.ellipsoid(Vector3(0.26, 0.22, 0.2), Color(0.9, 0.85, 0.74), MeshKit.at(q.x, q.y + 0.2, q.z), 9, 6)
		k.cyl(0.07, 0.08, Color(0.72, 0.6, 0.42), MeshKit.at(q.x, q.y + 0.38, q.z), 6)


static func crate(k: MeshKit, p: Vector3, s := 0.55, rot_y := 0.0) -> void:
	var t := MeshKit.xf(p + Vector3(0, s * 0.5, 0), Vector3(0, rot_y, 0))
	k.rbox(Vector3(s, s, s), 0.03, Pal.WOOD_LIGHT, t)
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(s + 0.02, 0.07, s + 0.02), 0.01, Pal.WOOD, t * MeshKit.at(0, sd * s * 0.32, 0))
	k.rbox(Vector3(s * 1.2, 0.05, 0.06), 0.01, Pal.WOOD, t * MeshKit.xf(Vector3(0, 0, s * 0.51), Vector3(0, 0, 40)))


# ---------------------------------------------------------------- kit helpers
# Small cheap pieces shared by the campus buildings (café, housing, hut,
# desk, megacluster). Sharp boxes are 12 triangles: use them for detail.

## A box stretched from a to b with a square (or s x s2) section.
static func beam(k: MeshKit, a: Vector3, b: Vector3, s: float, col: Color, s2 := -1.0) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var z := d / l
	var up := Vector3.UP if absf(z.y) < 0.99 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	k.box(Vector3(s, s2 if s2 > 0.0 else s, l), col, Transform3D(Basis(x, y, z), (a + b) * 0.5))


## A cylinder rod from a to b.
static func rod(k: MeshKit, a: Vector3, b: Vector3, r: float, col: Color, segs := 6) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var n := d / l
	var basis := Basis(Quaternion(Vector3.UP, n)) if absf(n.y) < 0.999 else (Basis.IDENTITY if n.y > 0 else Basis(Vector3.RIGHT, PI))
	k.cyl(r, l, col, Transform3D(basis, a), segs, 0.0, -1.0, false)


## A square lattice mast or boom from a to b (section s): four chords,
## zigzag bracing on two faces (and the other two when all_faces).
static func lattice(k: MeshKit, a: Vector3, b: Vector3, s: float, col: Color, all_faces := false) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.01:
		return
	var z := d / l
	var up := Vector3.UP if absf(z.y) < 0.99 else Vector3.RIGHT
	var x := up.cross(z).normalized() * s * 0.5
	var y := z.cross(x.normalized()) * s * 0.5
	var corners := [x + y, x - y, -x - y, -x + y]
	for c in corners:
		beam(k, a + c, b + c, 0.045, col)
	var n := maxi(1, int(l / s))
	var faces := 4 if all_faces else 2
	for i in n:
		var p0 := a + d * float(i) / n
		var p1 := a + d * float(i + 1) / n
		for f in faces:
			var c0: Vector3 = corners[f]
			var c1: Vector3 = corners[(f + 1) % 4]
			if i % 2 == 0:
				beam(k, p0 + c0, p1 + c1, 0.025, col)
			else:
				beam(k, p0 + c1, p1 + c0, 0.025, col)
		if i % 3 == 0:
			for f in 4:
				beam(k, p0 + corners[f], p0 + corners[(f + 1) % 4], 0.025, col)


## A straight stair from a (bottom of the first step) to b (top landing
## edge), width w, with stringers and optional handrails.
static func stair(k: MeshKit, a: Vector3, b: Vector3, w: float, tread: Color, side: Color, rail := Color.TRANSPARENT) -> void:
	var d := b - a
	var flat := Vector3(d.x, 0, d.z)
	var run := flat.length()
	if run < 0.05:
		return
	var yaw := rad_to_deg(atan2(flat.x, flat.z))
	var n := maxi(3, int(d.y / 0.19))
	var dir := flat / run
	var sideways := Vector3(dir.z, 0, -dir.x) * w * 0.5
	for i in n:
		var q := a + dir * run * (i + 0.5) / n + Vector3(0, d.y * (i + 1) / n - 0.02, 0)
		k.box(Vector3(w, 0.04, run / n + 0.03), tread, MeshKit.xf(q, Vector3(0, yaw, 0)))
	for sd in [-1.0, 1.0]:
		beam(k, a + sideways * sd + Vector3(0, 0.05, 0), b + sideways * sd + Vector3(0, -0.05, 0), 0.05, side, 0.14)
		if rail.a > 0.0:
			beam(k, a + sideways * sd + Vector3(0, 0.9, 0), b + sideways * sd + Vector3(0, 0.9, 0), 0.035, rail)
			beam(k, a + sideways * sd, a + sideways * sd + Vector3(0, 0.9, 0), 0.035, rail)
			beam(k, b + sideways * sd, b + sideways * sd + Vector3(0, 0.9, 0), 0.035, rail)
			var m: Vector3 = (a + b) * 0.5 + sideways * sd
			beam(k, m, m + Vector3(0, 0.9, 0), 0.03, rail)


## A patio umbrella: pole, eight alternating panels, a valance.
static func umbrella(k: MeshKit, p: Vector3, h: float, r: float, c1: Color, c2: Color, pole := Color(0.85, 0.86, 0.88)) -> void:
	k.cyl(0.025, h + 0.12, pole, MeshKit.at(p.x, p.y, p.z), 6)
	var prof := PackedVector2Array([Vector2(r, 0.0), Vector2(0.0, r * 0.32)])
	for i in 8:
		k.lathe(prof, c1 if i % 2 == 0 else c2, MeshKit.xf(Vector3(p.x, p.y + h, p.z), Vector3(0, i * 45.0, 0)), 2, TAU / 8.0)
		var a := TAU * (i + 0.5) / 8.0
		k.box(Vector3(r * 0.76, 0.1, 0.012), c2 if i % 2 == 0 else c1, MeshKit.xf(Vector3(p.x + cos(a) * r * 0.93, p.y + h - 0.05, p.z - sin(a) * r * 0.93), Vector3(0, rad_to_deg(a) + 90.0, 0)))
	k.sphere(0.04, pole, MeshKit.at(p.x, p.y + h + r * 0.32 + 0.02, p.z), 6, 3)


## A tree: trunk and a few leaf balls.
static func tree(k: MeshKit, p: Vector3, h := 2.0, leaf := Pal.LEAF, seed := 0) -> void:
	k.cyl(0.06 * h / 2.0, h * 0.55, Pal.WOOD_DARK, MeshKit.at(p.x, p.y, p.z), 6)
	var r := RandomNumberGenerator.new()
	r.seed = 31 + seed * 977
	k.sphere(h * 0.24, leaf, MeshKit.at(p.x, p.y + h * 0.66, p.z), 8, 5)
	for i in 3:
		var a := TAU * i / 3.0 + r.randf() * 0.6
		k.sphere(h * 0.16, leaf.lightened(0.08) if i % 2 == 0 else leaf.darkened(0.1), MeshKit.at(p.x + cos(a) * h * 0.17, p.y + h * (0.6 + r.randf() * 0.18), p.z + sin(a) * h * 0.17), 7, 4)


## A traffic cone.
static func cone_traffic(k: MeshKit, p: Vector3, s := 1.0) -> void:
	k.box(Vector3(0.3, 0.03, 0.3) * s, Color(0.9, 0.42, 0.18), MeshKit.at(p.x, p.y + 0.015 * s, p.z))
	k.cone(0.11 * s, 0.42 * s, Color(0.93, 0.48, 0.2), MeshKit.at(p.x, p.y + 0.03 * s, p.z), 8)
	k.cyl(0.075 * s, 0.06 * s, Color(0.96, 0.96, 0.94), MeshKit.at(p.x, p.y + 0.2 * s, p.z), 8, 0.0, 0.06 * s, false)


## A hard hat (brim and dome) at p.
static func hard_hat(k: MeshKit, p: Vector3, col: Color, yaw := 0.0) -> void:
	k.cyl(0.12, 0.015, col.darkened(0.1), MeshKit.xf(p, Vector3(0, yaw, 0)), 8)
	k.ellipsoid(Vector3(0.1, 0.08, 0.11), col, MeshKit.at(p.x, p.y + 0.01, p.z), 8, 4)
	k.box(Vector3(0.02, 0.03, 0.2), col.lightened(0.15), MeshKit.xf(p + Vector3(0, 0.08, 0), Vector3(0, yaw, 0)))


## A wooden pallet with an optional load of bricks / sacks / blocks.
static func pallet(k: MeshKit, base: Transform3D, load := "", col := Color.TRANSPARENT) -> void:
	for j in 5:
		k.box(Vector3(0.8, 0.025, 0.12), Pal.WOOD_LIGHT.darkened(0.04 * (j % 2)), base * MeshKit.at(0, 0.135, -0.48 + j * 0.24))
	for i in 3:
		k.box(Vector3(0.1, 0.1, 1.08), Pal.WOOD, base * MeshKit.at(-0.35 + i * 0.35, 0.06, 0))
	match load:
		"bricks":
			var bc: Color = col if col.a > 0.0 else Pal.BRICK
			for y in 3:
				for i in 3:
					k.box(Vector3(0.7, 0.13, 0.28), bc.darkened(0.05 * ((i + y) % 2)), base * MeshKit.at(0, 0.215 + y * 0.135, -0.33 + i * 0.33))
			k.box(Vector3(0.72, 0.43, 0.02), Color(0.86, 0.88, 0.9, 1.0), base * MeshKit.at(0, 0.36, 0.0))
		"sacks":
			for y in 2:
				for i in 3:
					k.rbox(Vector3(0.36, 0.13, 0.32), 0.05, (col if col.a > 0.0 else Color(0.88, 0.84, 0.74)).darkened(0.04 * ((i + y) % 3)), base * MeshKit.at(-0.18 + ((i + y) % 2) * 0.36, 0.22 + y * 0.14, -0.33 + i * 0.33), 1)
		"blocks":
			for y in 2:
				for i in 4:
					k.box(Vector3(0.38, 0.18, 0.22), Color(0.72, 0.72, 0.7), base * MeshKit.at(-0.2 + (i % 2) * 0.4, 0.24 + y * 0.19, -0.25 + (i / 2) * 0.5))


## A floodlight head on a bracket (facing local +z).
static func floodlight(k: MeshKit, base: Transform3D, col := Color(0.24, 0.25, 0.27)) -> void:
	k.box(Vector3(0.26, 0.2, 0.08), col, base * MeshKit.xf(Vector3(0, 0, 0.04), Vector3(-25, 0, 0)))
	k.box(Vector3(0.22, 0.16, 0.02), Color(1.0, 0.95, 0.8, 0.35), base * MeshKit.xf(Vector3(0, -0.01, 0.09), Vector3(-25, 0, 0)))
	k.box(Vector3(0.04, 0.04, 0.1), col, base * MeshKit.at(0, 0, -0.03))


## A tower crane: lattice mast, slewing deck and cab, a jib toward local +x
## and a counter-jib with weights, pennant ties, a trolley and hook.
static func tower_crane(k: MeshKit, base: Transform3D, h: float, jib: float, counter: float, col := Color(0.95, 0.76, 0.2), s := 0.42, hook_drop := 2.0) -> void:
	var dark := Color(0.24, 0.25, 0.27)
	k.box(Vector3(s * 2.2, 0.25, s * 2.2), Color(0.66, 0.66, 0.64), base * MeshKit.at(0, 0.125, 0))
	lattice(k, base * Vector3(0, 0.25, 0), base * Vector3(0, h, 0), s, col, true)
	k.box(Vector3(s + 0.12, 0.16, s + 0.12), dark, base * MeshKit.at(0, h + 0.08, 0))
	k.box(Vector3(s * 0.9, 0.42, s * 0.8), Color(0.94, 0.94, 0.92), base * MeshKit.at(s * 0.2, h + 0.38, s * 0.65))
	k.box(Vector3(s * 0.86, 0.22, 0.02), Color(0.4, 0.6, 0.76, 0.75), base * MeshKit.at(s * 0.2, h + 0.44, s * 1.06))
	# apex
	var apex := base * Vector3(0, h + 1.5, 0)
	lattice(k, base * Vector3(0, h + 0.16, 0), apex, s * 0.6, col)
	# jib and counter-jib
	var j0 := base * Vector3(0, h + 0.36, 0)
	var j1 := base * Vector3(jib, h + 0.36, 0)
	var c1 := base * Vector3(-counter, h + 0.36, 0)
	lattice(k, j0, j1, s * 0.7, col)
	beam(k, j0, c1, 0.12, col, 0.18)
	for i in 3:
		k.box(Vector3(0.24, 0.5, s * 0.9), Color(0.74, 0.74, 0.72), base * MeshKit.at(-counter + 0.2 + i * 0.27, h + 0.06, 0))
	k.box(Vector3(0.3, 0.26, 0.3), dark, base * MeshKit.at(-counter * 0.45, h + 0.58, 0))
	# pennant ties
	beam(k, apex, base * Vector3(jib * 0.66, h + 0.62, 0), 0.025, dark)
	beam(k, apex, base * Vector3(jib * 0.33, h + 0.62, 0), 0.025, dark)
	beam(k, apex, base * Vector3(-counter + 0.05, h + 0.45, 0), 0.025, dark)
	# trolley, cables, hook block
	var tx := jib * 0.62
	k.box(Vector3(0.24, 0.1, s * 0.8), dark, base * MeshKit.at(tx, h + 0.06, 0))
	for sz in [-0.05, 0.05]:
		beam(k, base * Vector3(tx, h, sz), base * Vector3(tx, h - hook_drop, sz), 0.012, dark)
	k.box(Vector3(0.16, 0.2, 0.12), Color(0.96, 0.66, 0.2), base * MeshKit.at(tx, h - hook_drop - 0.1, 0))
	k.torus(0.06, 0.02, dark, base * MeshKit.xf(Vector3(tx, h - hook_drop - 0.26, 0), Vector3(90, 0, 0)), 8, 3, PI * 1.5)
	# a red light on the tip and the apex
	k.sphere(0.05, Color(1.0, 0.3, 0.25, 0.3), Transform3D(Basis.IDENTITY, j1 + Vector3(0, 0.25, 0)), 6, 3)
	k.sphere(0.05, Color(1.0, 0.3, 0.25, 0.3), Transform3D(Basis.IDENTITY, apex + Vector3(0, 0.06, 0)), 6, 3)


## Stroke letters for signs: each glyph is a list of strokes [x0, y0, x1, y1]
## in a box 0.6 wide and 1 tall (baseline at 0).
const GLYPHS := {
	"A": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 1, 0.6, 1], [0, 0.5, 0.6, 0.5]],
	"B": [[0, 0, 0, 1], [0, 1, 0.45, 1], [0.45, 1, 0.6, 0.85], [0.6, 0.85, 0.6, 0.62], [0, 0.52, 0.6, 0.52], [0.6, 0.52, 0.6, 0], [0, 0, 0.6, 0]],
	"C": [[0, 0, 0, 1], [0, 1, 0.6, 1], [0, 0, 0.6, 0]],
	"D": [[0, 0, 0, 1], [0, 1, 0.4, 1], [0.4, 1, 0.6, 0.8], [0.6, 0.8, 0.6, 0.2], [0.6, 0.2, 0.4, 0], [0.4, 0, 0, 0]],
	"E": [[0, 0, 0, 1], [0, 1, 0.6, 1], [0, 0.5, 0.45, 0.5], [0, 0, 0.6, 0]],
	"F": [[0, 0, 0, 1], [0, 1, 0.6, 1], [0, 0.5, 0.45, 0.5]],
	"G": [[0, 0, 0, 1], [0, 1, 0.6, 1], [0, 0, 0.6, 0], [0.6, 0, 0.6, 0.5], [0.3, 0.5, 0.6, 0.5]],
	"H": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 0.5, 0.6, 0.5]],
	"I": [[0.3, 0, 0.3, 1], [0.1, 1, 0.5, 1], [0.1, 0, 0.5, 0]],
	"K": [[0, 0, 0, 1], [0, 0.45, 0.6, 1], [0.18, 0.6, 0.6, 0]],
	"L": [[0, 0, 0, 1], [0, 0, 0.6, 0]],
	"M": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 1, 0.3, 0.5], [0.3, 0.5, 0.6, 1]],
	"N": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 1, 0.6, 0]],
	"O": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 1, 0.6, 1], [0, 0, 0.6, 0]],
	"P": [[0, 0, 0, 1], [0, 1, 0.6, 1], [0.6, 1, 0.6, 0.5], [0, 0.5, 0.6, 0.5]],
	"R": [[0, 0, 0, 1], [0, 1, 0.6, 1], [0.6, 1, 0.6, 0.5], [0, 0.5, 0.6, 0.5], [0.2, 0.5, 0.6, 0]],
	"S": [[0, 1, 0.6, 1], [0, 1, 0, 0.5], [0, 0.5, 0.6, 0.5], [0.6, 0.5, 0.6, 0], [0, 0, 0.6, 0]],
	"T": [[0.3, 0, 0.3, 1], [0, 1, 0.6, 1]],
	"U": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 0, 0.6, 0]],
	"W": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 0, 0.3, 0.5], [0.3, 0.5, 0.6, 0]],
	"Y": [[0.3, 0, 0.3, 0.5], [0.3, 0.5, 0, 1], [0.3, 0.5, 0.6, 1]],
	"a": [[0, 0, 0.45, 0], [0.45, 0, 0.45, 0.6], [0, 0.6, 0.45, 0.6], [0, 0, 0, 0.3], [0, 0.3, 0.45, 0.3]],
	"h": [[0, 0, 0, 1], [0, 0.6, 0.45, 0.6], [0.45, 0.6, 0.45, 0]],
	"t": [[0.15, 0, 0.15, 0.9], [0, 0.6, 0.4, 0.6], [0.15, 0, 0.4, 0]],
	"0": [[0, 0, 0, 1], [0.6, 0, 0.6, 1], [0, 1, 0.6, 1], [0, 0, 0.6, 0]],
	"1": [[0.3, 0, 0.3, 1], [0.1, 0.8, 0.3, 1]],
}


## Text of stroke letters (local face frame: centred on x, baseline at y=0,
## facing +z), h tall. Returns its width.
static func word(k: MeshKit, face: Transform3D, text: String, h: float, col: Color, thick := 0.1, depth := 0.03) -> float:
	var adv := h * 0.85
	var w := 0.0
	for ch in text:
		w += adv if ch != " " else adv * 0.6
	w -= h * 0.25
	var x := -w * 0.5
	for ch in text:
		if ch == " ":
			x += adv * 0.6
			continue
		var strokes: Array = GLYPHS.get(ch, [])
		for s in strokes:
			var a := Vector3(x + float(s[0]) * h, float(s[1]) * h, 0)
			var b := Vector3(x + float(s[2]) * h, float(s[3]) * h, 0)
			var d := (b - a)
			var l := d.length()
			var rot := rad_to_deg(atan2(d.y, d.x))
			k.box(Vector3(l + thick * h, thick * h, depth), col, face * MeshKit.xf((a + b) * 0.5, Vector3(0, 0, rot)))
		x += adv
	return w


# ---------------------------------------------------------------- builder's hut

## The Builder's Hut: a site office trailer on blocks with its door steps,
## barred windows, a hard-hat rack and vests; scaffolding at its side, a
## little tower crane, a cement mixer, a blueprint table, cones, pallets,
## a sawhorse where the builder rests, a portable toilet and a light mast.
static func hut() -> Mesh:
	var k := MeshKit.new()
	var shell := Color(0.93, 0.93, 0.91)
	var orange := Color(0.96, 0.6, 0.24)
	var dark := Pal.STEEL_DARK
	var grey := Color(0.62, 0.62, 0.6)
	# ground: compacted gravel, darker patches, tyre ruts, a plank path
	k.box(Vector3(3.8, 0.03, 3.8), Color(0.66, 0.63, 0.57), MeshKit.at(0, 0.015, 0))
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	for i in 14:
		k.box(Vector3(r.randf_range(0.2, 0.6), 0.012, r.randf_range(0.15, 0.4)), Color(0.58, 0.55, 0.5) if i % 2 else Color(0.72, 0.69, 0.62), MeshKit.xf(Vector3(r.randf_range(-1.7, 1.7), 0.033, r.randf_range(-1.7, 1.7)), Vector3(0, r.randf_range(0, 180), 0)))
	for sx in [-0.35, 0.35]:
		k.box(Vector3(0.18, 0.012, 1.9), Color(0.55, 0.5, 0.44), MeshKit.at(sx - 0.1, 0.033, 0.9))
	for i in 6:
		k.box(Vector3(0.62, 0.04, 0.22), Pal.WOOD_LIGHT.darkened(0.05 * (i % 3)), MeshKit.xf(Vector3(0.55 + (i % 2) * 0.03, 0.05, 0.2 + i * 0.27), Vector3(0, (i * 7) % 11 - 5, 0)))
	# ---- the site office trailer, on cribbing blocks
	var tx0 := -1.05
	var tx1 := 1.2
	var tz0 := -1.85
	var tz1 := -0.4
	var fy := 0.4
	var top := 2.35
	var cx := (tx0 + tx1) * 0.5
	var cz := (tz0 + tz1) * 0.5
	var tw := tx1 - tx0
	var td := tz1 - tz0
	for x in [tx0 + 0.25, cx, tx1 - 0.25]:
		for z in [tz0 + 0.25, tz1 - 0.25]:
			for j in 3:
				k.box(Vector3(0.3, 0.12, 0.14), Pal.WOOD.darkened(0.06 * j), MeshKit.xf(Vector3(x, 0.09 + j * 0.12, z), Vector3(0, 90 * (j % 2), 0)))
	k.box(Vector3(tw + 0.04, 0.12, td + 0.04), dark, MeshKit.at(cx, fy + 0.04, cz))
	k.box(Vector3(tw, top - fy - 0.1, td), shell, MeshKit.at(cx, (top + fy) * 0.5, cz))
	# ribs on the front, back and ends
	for i in int(tw / 0.22):
		var x := tx0 + 0.11 + i * 0.22
		if x > 0.3 and x < 0.85:
			continue
		k.box(Vector3(0.05, top - fy - 0.14, 0.03), shell.darkened(0.08), MeshKit.at(x, (top + fy) * 0.5, tz1 + 0.01))
		k.box(Vector3(0.05, top - fy - 0.14, 0.03), shell.darkened(0.08), MeshKit.at(x, (top + fy) * 0.5, tz0 - 0.01))
	for i in int(td / 0.22):
		for sx in [tx0 - 0.01, tx1 + 0.01]:
			k.box(Vector3(0.03, top - fy - 0.14, 0.05), shell.darkened(0.08), MeshKit.at(sx, (top + fy) * 0.5, tz0 + 0.11 + i * 0.22))
	# corner posts, orange band, roof with a drip edge
	for x in [tx0, tx1]:
		for z in [tz0, tz1]:
			k.box(Vector3(0.09, top - fy, 0.09), Color(0.8, 0.8, 0.78), MeshKit.at(x, (top + fy) * 0.5, z))
	k.box(Vector3(tw + 0.06, 0.16, td + 0.06), orange, MeshKit.at(cx, top - 0.3, cz))
	k.box(Vector3(tw + 0.06, 0.03, td + 0.06), Color(0.96, 0.96, 0.94), MeshKit.at(cx, top - 0.2, cz))
	k.box(Vector3(tw + 0.14, 0.1, td + 0.14), Color(0.5, 0.52, 0.55), MeshKit.at(cx, top + 0.02, cz))
	k.box(Vector3(tw - 0.1, 0.03, td - 0.1), Color(0.42, 0.44, 0.47), MeshKit.at(cx, top + 0.08, cz))
	# the door, a window either side with security bars, a sign
	var dx := 0.57
	k.box(Vector3(0.62, 1.55, 0.05), Color(0.56, 0.58, 0.62), MeshKit.at(dx, fy + 0.85, tz1 + 0.02))
	k.box(Vector3(0.52, 1.45, 0.05), Color(0.36, 0.4, 0.46), MeshKit.at(dx, fy + 0.8, tz1 + 0.04))
	k.box(Vector3(0.3, 0.32, 0.03), Color(0.6, 0.78, 0.88, 0.8), MeshKit.at(dx, fy + 1.2, tz1 + 0.07))
	k.box(Vector3(0.08, 0.03, 0.05), Pal.BRASS, MeshKit.at(dx + 0.18, fy + 0.78, tz1 + 0.09))
	k.box(Vector3(0.8, 0.05, 0.36), dark, MeshKit.at(dx, fy + 1.72, tz1 + 0.18))
	k.sphere(0.07, Color(1.0, 0.8, 0.5, 0.35), MeshKit.at(dx, fy + 1.64, tz1 + 0.26), 6, 3)
	for wx in [tx0 + 0.42, tx0 + 1.05]:
		k.box(Vector3(0.56, 0.5, 0.04), Color(0.4, 0.42, 0.46), MeshKit.at(wx, fy + 1.25, tz1 + 0.02))
		k.box(Vector3(0.48, 0.42, 0.04), Color(0.62, 0.78, 0.86, 0.8), MeshKit.at(wx, fy + 1.25, tz1 + 0.035))
		for i in 5:
			k.box(Vector3(0.02, 0.48, 0.02), dark, MeshKit.at(wx - 0.2 + i * 0.1, fy + 1.25, tz1 + 0.07))
		k.box(Vector3(0.56, 0.03, 0.03), dark, MeshKit.at(wx, fy + 1.05, tz1 + 0.07))
		k.box(Vector3(0.56, 0.03, 0.03), dark, MeshKit.at(wx, fy + 1.45, tz1 + 0.07))
		k.box(Vector3(0.6, 0.04, 0.1), Color(0.8, 0.8, 0.78), MeshKit.at(wx, fy + 0.98, tz1 + 0.06))
	# side windows on the ends and the back
	for z in [cz]:
		k.box(Vector3(0.04, 0.4, 0.6), Color(0.62, 0.78, 0.86, 0.8), MeshKit.at(tx1 + 0.02, fy + 1.25, z))
		k.box(Vector3(0.04, 0.4, 0.6), Color(0.62, 0.78, 0.86, 0.8), MeshKit.at(tx0 - 0.02, fy + 1.25, z))
	for wx in [tx0 + 0.5, tx1 - 0.5]:
		k.box(Vector3(0.6, 0.36, 0.04), Color(0.62, 0.78, 0.86, 0.8), MeshKit.at(wx, fy + 1.3, tz0 - 0.02))
	# the "SITE OFFICE" board and safety signs
	k.box(Vector3(0.9, 0.26, 0.03), Color(0.97, 0.97, 0.95), MeshKit.at(tx0 + 0.73, top - 0.52, tz1 + 0.03))
	for i in 2:
		k.box(Vector3(0.7 - i * 0.2, 0.04, 0.01), Color(0.2, 0.3, 0.6), MeshKit.at(tx0 + 0.73, top - 0.47 - i * 0.09, tz1 + 0.05))
	k.cyl(0.08, 0.01, Color(0.2, 0.4, 0.8), MeshKit.xf(Vector3(dx - 0.42, fy + 1.45, tz1 + 0.04), Vector3(90, 0, 0)), 8)
	k.cyl(0.04, 0.012, Color(0.96, 0.96, 0.96), MeshKit.xf(Vector3(dx - 0.42, fy + 1.45, tz1 + 0.045), Vector3(90, 0, 0)), 6)
	k.prism(PackedVector2Array([Vector2(-0.09, 0), Vector2(0.09, 0), Vector2(0, 0.16)]), 0.01, Color(0.98, 0.84, 0.2), MeshKit.xf(Vector3(dx - 0.42, fy + 1.2, tz1 + 0.04), Vector3(90, 0, 0)))
	# hard-hat rack and hi-vis vests beside the door
	k.box(Vector3(0.62, 0.04, 0.12), dark, MeshKit.at(tx0 + 0.75, fy + 0.68, tz1 + 0.06))
	var hats := [Color(0.97, 0.82, 0.22), Color(0.96, 0.96, 0.94), orange, Color(0.3, 0.5, 0.86)]
	for i in 4:
		k.box(Vector3(0.02, 0.06, 0.08), dark, MeshKit.at(tx0 + 0.53 + i * 0.15, fy + 0.72, tz1 + 0.08))
		hard_hat(k, Vector3(tx0 + 0.53 + i * 0.15, fy + 0.74, tz1 + 0.13), hats[i])
	for i in 2:
		var vx := tx1 - 0.12 - i * 0.16
		k.box(Vector3(0.14, 0.34, 0.03), Color(0.98, 0.56, 0.18) if i == 0 else Color(0.84, 0.94, 0.3), MeshKit.at(vx, fy + 1.15, tz1 + 0.05))
		k.box(Vector3(0.14, 0.03, 0.035), Color(0.9, 0.92, 0.94), MeshKit.at(vx, fy + 1.1, tz1 + 0.06))
		k.box(Vector3(0.14, 0.03, 0.035), Color(0.9, 0.92, 0.94), MeshKit.at(vx, fy + 1.2, tz1 + 0.06))
	# steel steps up to the door with a handrail
	for i in 3:
		k.box(Vector3(0.66, 0.03, 0.16), Color(0.56, 0.58, 0.6), MeshKit.at(dx, 0.11 + i * 0.12, tz1 + 0.42 - i * 0.14))
	for sx in [-0.34, 0.34]:
		beam(k, Vector3(dx + sx, 0.03, tz1 + 0.52), Vector3(dx + sx, fy, tz1 + 0.06), 0.03, dark, 0.1)
		beam(k, Vector3(dx + sx, 0.95, tz1 + 0.5), Vector3(dx + sx, fy + 0.95, tz1 + 0.08), 0.03, Color(0.96, 0.78, 0.2))
		beam(k, Vector3(dx + sx, 0.03, tz1 + 0.5), Vector3(dx + sx, 0.95, tz1 + 0.5), 0.03, Color(0.96, 0.78, 0.2))
	# roof: an AC unit, a vent, an amber beacon, an antenna, a tarp bundle
	ArchKit.ac_unit(k, MeshKit.at(tx0 + 0.55, top + 0.08, cz - 0.1), 1, 0.7)
	k.cyl(0.06, 0.3, grey, MeshKit.at(cx + 0.4, top + 0.08, cz - 0.3), 6)
	k.cone(0.1, 0.08, grey.darkened(0.2), MeshKit.at(cx + 0.4, top + 0.38, cz - 0.3), 6)
	k.cyl(0.05, 0.08, dark, MeshKit.at(tx1 - 0.2, top + 0.08, tz1 - 0.15), 6)
	k.sphere(0.07, Color(1.0, 0.6, 0.2, 0.3), MeshKit.at(tx1 - 0.2, top + 0.2, tz1 - 0.15), 6, 3)
	k.cyl(0.012, 0.9, Color(0.8, 0.8, 0.82), MeshKit.at(tx0 + 0.15, top + 0.08, tz0 + 0.15), 4)
	k.rbox(Vector3(0.5, 0.16, 0.3), 0.06, Color(0.26, 0.46, 0.78), MeshKit.xf(Vector3(cx + 0.1, top + 0.17, cz + 0.25), Vector3(0, 12, 0)), 1)
	# a cable from the roof to the light mast
	ArchKit.pipes(k, [Vector3(tx1, top - 0.1, tz1 - 0.1), Vector3(1.5, 1.9, -0.25), Vector3(1.62, 2.6, -0.2)], 0.012, Color(0.15, 0.15, 0.16))
	# ---- scaffolding bay against the trailer's left end
	var sx0 := -1.83
	var sx1 := -1.15
	var sz0 := -1.82
	var sz1 := -0.62
	var pole := Color(0.66, 0.66, 0.64)
	for x in [sx0, sx1]:
		for z in [sz0, sz1]:
			k.cyl(0.03, 3.3, pole, MeshKit.at(x, 0.03, z), 5)
			k.box(Vector3(0.16, 0.03, 0.16), dark, MeshKit.at(x, 0.045, z))
	for lv in 3:
		var y := 1.0 + lv * 1.0
		k.box(Vector3(sx1 - sx0, 0.04, sz1 - sz0), Pal.WOOD_LIGHT.darkened(0.05 * lv), MeshKit.at((sx0 + sx1) * 0.5, y, (sz0 + sz1) * 0.5))
		for j in 3:
			k.box(Vector3(sx1 - sx0 - 0.04, 0.01, 0.02), Pal.WOOD.darkened(0.1), MeshKit.at((sx0 + sx1) * 0.5, y + 0.025, sz0 + 0.3 + j * 0.3))
		k.box(Vector3(0.02, 0.12, sz1 - sz0), Pal.WOOD, MeshKit.at(sx0, y + 0.08, (sz0 + sz1) * 0.5))
		beam(k, Vector3(sx0, y + 0.5, sz0), Vector3(sx0, y + 0.5, sz1), 0.03, pole)
		beam(k, Vector3(sx0, y + 0.95, sz0), Vector3(sx0, y + 0.95, sz1), 0.03, pole)
		beam(k, Vector3(sx0, y + 0.95, sz1), Vector3(sx1, y + 0.95, sz1), 0.03, pole)
		beam(k, Vector3(sx0, y - 0.95, sz0 if lv % 2 == 0 else sz1), Vector3(sx0, y, sz1 if lv % 2 == 0 else sz0), 0.03, pole)
	beam(k, Vector3(sx0, 0.1, sz1), Vector3(sx1, 1.0, sz1), 0.03, pole)
	ArchKit.ladder(k, MeshKit.xf(Vector3(sx1 - 0.25, 0.03, sz1 + 0.02), Vector3(0, 180, 0)), 3.0, pole)
	# a gin wheel and rope with a bucket at the top
	beam(k, Vector3(sx0 + 0.1, 3.3, sz1 - 0.1), Vector3(sx0 + 0.1, 3.3, sz1 + 0.35), 0.04, pole)
	k.torus(0.08, 0.02, dark, MeshKit.xf(Vector3(sx0 + 0.1, 3.22, sz1 + 0.3), Vector3(0, 0, 90)), 8, 3)
	beam(k, Vector3(sx0 + 0.1, 3.15, sz1 + 0.3), Vector3(sx0 + 0.1, 1.2, sz1 + 0.3), 0.012, Color(0.86, 0.8, 0.6))
	k.cyl(0.09, 0.18, Color(0.3, 0.32, 0.36), MeshKit.at(sx0 + 0.1, 1.0, sz1 + 0.3), 8, 0.0, 0.11)
	# ---- a little tower crane behind the trailer's right end
	tower_crane(k, MeshKit.xf(Vector3(1.55, 0.03, -1.55), Vector3(0, -135, 0)), 4.8, 4.3, 0.42, Color(0.96, 0.76, 0.2), 0.36, 1.4)
	# a bundle of rebar hanging from the hook
	var hook := MeshKit.xf(Vector3(1.55, 0.03, -1.55), Vector3(0, -135, 0)) * Vector3(4.3 * 0.62, 4.8 - 1.4 - 0.45, 0)
	for i in 5:
		k.box(Vector3(0.03, 0.03, 1.0), Color(0.48, 0.32, 0.26), MeshKit.xf(hook + Vector3(-0.08 + i * 0.04, -0.15, 0), Vector3(0, 45, 0)))
	beam(k, hook + Vector3(0, 0.15, 0), hook + Vector3(-0.25, -0.13, -0.25), 0.012, Color(0.15, 0.15, 0.16))
	beam(k, hook + Vector3(0, 0.15, 0), hook + Vector3(0.25, -0.13, 0.25), 0.012, Color(0.15, 0.15, 0.16))
	# ---- a light mast at the front right corner of the trailer
	k.box(Vector3(0.3, 0.12, 0.3), Color(0.92, 0.72, 0.2), MeshKit.at(1.62, 0.09, -0.2))
	k.cyl(0.03, 2.6, Color(0.7, 0.72, 0.74), MeshKit.at(1.62, 0.15, -0.2), 5)
	k.box(Vector3(0.5, 0.04, 0.04), Color(0.7, 0.72, 0.74), MeshKit.at(1.62, 2.72, -0.2))
	for sx in [-0.18, 0.18]:
		floodlight(k, MeshKit.xf(Vector3(1.62 + sx, 2.78, -0.17), Vector3(0, -20, 0)))
	# ---- portable toilet in front of the scaffold
	var wc := MeshKit.at(-1.55, 0.03, -0.22)
	k.box(Vector3(0.56, 1.3, 0.56), Color(0.3, 0.52, 0.8), wc * MeshKit.at(0, 0.68, 0))
	k.box(Vector3(0.6, 0.06, 0.6), Color(0.94, 0.94, 0.92), wc * MeshKit.at(0, 1.36, 0))
	k.box(Vector3(0.4, 1.1, 0.02), Color(0.26, 0.46, 0.72), wc * MeshKit.at(0.02, 0.65, 0.29))
	k.box(Vector3(0.1, 0.04, 0.02), Color(0.86, 0.3, 0.26), wc * MeshKit.at(0.12, 0.9, 0.305))
	k.box(Vector3(0.56, 0.05, 0.56), Color(0.25, 0.28, 0.32), wc * MeshKit.at(0, 0.05, 0))
	# ---- front yard: cement mixer, wheelbarrow, pallets, beams, cones
	var mx := MeshKit.xf(Vector3(-1.35, 0.03, 0.75), Vector3(0, 30, 0))
	for sx in [-0.22, 0.22]:
		beam(k, mx * Vector3(sx, 0.0, -0.2), mx * Vector3(sx, 0.5, 0.0), 0.04, Color(0.3, 0.32, 0.36))
		beam(k, mx * Vector3(sx, 0.0, 0.2), mx * Vector3(sx, 0.5, 0.0), 0.04, Color(0.3, 0.32, 0.36))
	for sx in [-0.3, 0.3]:
		k.cyl(0.13, 0.06, Pal.RUBBER, mx * MeshKit.xf(Vector3(sx, 0.13, -0.32), Vector3(0, 0, 90)), 8)
	beam(k, mx * Vector3(-0.3, 0.13, -0.32), mx * Vector3(0.3, 0.13, -0.32), 0.03, dark)
	k.box(Vector3(0.3, 0.22, 0.24), Color(0.3, 0.52, 0.34), mx * MeshKit.at(0.0, 0.32, -0.3))
	var drum := mx * MeshKit.xf(Vector3(0, 0.62, 0.05), Vector3(-55, 0, 0))
	k.cyl(0.3, 0.28, orange, drum * MeshKit.at(0, -0.2, 0), 10, 0.0, 0.3)
	k.cyl(0.3, 0.26, orange, drum * MeshKit.at(0, 0.08, 0), 10, 0.0, 0.17)
	k.cyl(0.17, 0.04, Color(0.2, 0.2, 0.22), drum * MeshKit.at(0, 0.34, 0), 10)
	k.torus(0.3, 0.025, orange.darkened(0.2), drum * MeshKit.at(0, 0.08, 0), 12, 3)
	beam(k, mx * Vector3(0.0, 0.5, 0.0), mx * Vector3(0.0, 0.7, -0.55), 0.03, dark)
	k.box(Vector3(0.26, 0.04, 0.04), dark, mx * MeshKit.at(0, 0.7, -0.55))
	# wheelbarrow with sand
	var wb := MeshKit.xf(Vector3(-0.95, 0.03, 1.55), Vector3(0, -60, 0))
	k.cyl(0.11, 0.05, Pal.RUBBER, wb * MeshKit.xf(Vector3(0, 0.11, 0.35), Vector3(0, 0, 90)), 8)
	k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.18, 0.0), Vector2(0.28, 0.2), Vector2(0.25, 0.2)]), Color(0.3, 0.52, 0.34), wb * MeshKit.xf(Vector3(0, 0.22, 0.05), Vector3.ZERO, Vector3(1.0, 1.0, 1.35)), 8)
	k.ellipsoid(Vector3(0.22, 0.06, 0.3), Color(0.86, 0.78, 0.56), wb * MeshKit.at(0, 0.4, 0.05), 8, 3)
	for sx in [-0.16, 0.16]:
		beam(k, wb * Vector3(sx * 0.6, 0.12, 0.35), wb * Vector3(sx, 0.4, -0.45), 0.03, dark)
		beam(k, wb * Vector3(sx, 0.22, -0.1), wb * Vector3(sx, 0.02, -0.15), 0.025, dark)
	# a pallet of bricks, a pallet of cement sacks, a stack of steel beams
	pallet(k, MeshKit.xf(Vector3(-1.45, 0.03, 1.55), Vector3(0, 90, 0)), "bricks")
	pallet(k, MeshKit.xf(Vector3(-0.15, 0.03, -0.17), Vector3(0, 90, 0)) * MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(0.7, 1, 0.7)), "sacks")
	for i in 5:
		k.box(Vector3(1.3, 0.1, 0.12), Color(0.38, 0.42, 0.48) if i < 3 else Color(0.6, 0.28, 0.22), MeshKit.xf(Vector3(-0.6, 0.09 + (i / 3) * 0.11, 1.0 - (i % 3) * 0.15), Vector3(0, 90, 0)))
	for i in 3:
		k.box(Vector3(0.08, 0.06, 0.5), Pal.WOOD, MeshKit.at(-0.6 + (i - 1) * 0.5, 0.05, 0.85))
	# the blueprint table with a canopy, the sawhorse where the builder rests
	var bt := MeshKit.xf(Vector3(1.32, 0.03, 1.3), Vector3(0, -12, 0))
	for sx in [-0.42, 0.42]:
		beam(k, bt * Vector3(sx, 0.0, -0.25), bt * Vector3(sx, 0.78, 0.0), 0.035, Pal.WOOD)
		beam(k, bt * Vector3(sx, 0.0, 0.25), bt * Vector3(sx, 0.78, 0.0), 0.035, Pal.WOOD)
	k.box(Vector3(1.0, 0.04, 0.62), Pal.WOOD_LIGHT, bt * MeshKit.at(0, 0.8, 0))
	k.box(Vector3(0.62, 0.012, 0.44), Color(0.3, 0.46, 0.72), bt * MeshKit.xf(Vector3(-0.1, 0.826, 0.02), Vector3(0, 6, 0)))
	for i in 5:
		k.box(Vector3(0.5 - (i % 3) * 0.1, 0.004, 0.012), Color(0.9, 0.94, 1.0), bt * MeshKit.xf(Vector3(-0.12, 0.834, -0.14 + i * 0.07), Vector3(0, 6, 0)))
	for i in 3:
		k.box(Vector3(0.012, 0.004, 0.3), Color(0.9, 0.94, 1.0), bt * MeshKit.xf(Vector3(-0.3 + i * 0.18, 0.834, 0.02), Vector3(0, 6, 0)))
	k.cyl(0.04, 0.5, Color(0.86, 0.9, 0.96), bt * MeshKit.xf(Vector3(0.3, 0.86, -0.15), Vector3(0, 0, 90)), 6)
	k.cyl(0.035, 0.08, Color(0.9, 0.9, 0.88), bt * MeshKit.at(0.32, 0.82, 0.18), 6)
	hard_hat(k, bt * Vector3(0.3, 0.82, 0.05), Color(0.96, 0.96, 0.94), 20.0)
	k.box(Vector3(0.12, 0.02, 0.06), Color(0.96, 0.8, 0.2), bt * MeshKit.at(-0.4, 0.83, -0.2))
	# sawhorse with a plank by the rest spot
	var sh := MeshKit.xf(Vector3(1.55, 0.03, 0.38), Vector3(0, 80, 0))
	for sz in [-0.25, 0.25]:
		for sx in [-0.14, 0.14]:
			beam(k, sh * Vector3(sx, 0.0, sz), sh * Vector3(0, 0.5, sz), 0.035, Pal.WOOD_LIGHT)
	k.box(Vector3(0.08, 0.06, 0.7), Pal.WOOD, sh * MeshKit.at(0, 0.52, 0))
	k.box(Vector3(0.2, 0.03, 0.9), Pal.WOOD_LIGHT, sh * MeshKit.xf(Vector3(0.05, 0.57, 0.05), Vector3(0, 8, 0)))
	k.box(Vector3(0.05, 0.03, 0.22), Color(0.86, 0.3, 0.26), sh * MeshKit.at(-0.02, 0.6, -0.25))
	k.box(Vector3(0.14, 0.04, 0.03), Color(0.7, 0.72, 0.74), sh * MeshKit.at(0.0, 0.6, -0.12))
	# a toolbox and gas bottles by the trailer
	k.box(Vector3(0.4, 0.18, 0.2), Color(0.82, 0.24, 0.22), MeshKit.at(1.15, 0.12, -0.2))
	k.box(Vector3(0.3, 0.03, 0.04), dark, MeshKit.at(1.15, 0.24, -0.2))
	for i in 2:
		k.cyl(0.09, 0.62, [Color(0.3, 0.5, 0.86), Color(0.86, 0.3, 0.26)][i], MeshKit.at(-0.82 + i * 0.2, 0.03, -0.25), 8, 0.03)
		k.cyl(0.03, 0.08, dark, MeshKit.at(-0.82 + i * 0.2, 0.65, -0.25), 5)
	# traffic cones and a barrier along the left of the yard
	for p in [Vector3(-0.8, 0.03, 1.85), Vector3(-1.7, 0.03, 0.15), Vector3(1.75, 0.03, 1.8), Vector3(0.95, 0.03, 1.8)]:
		cone_traffic(k, p)
	for i in 2:
		var bz := 0.35 + i * 0.55
		for sz in [-0.22, 0.22]:
			k.box(Vector3(0.08, 0.06, 0.3), Color(0.28, 0.3, 0.32), MeshKit.at(-1.82, 0.06, bz + sz))
			k.box(Vector3(0.03, 0.75, 0.03), Color(0.9, 0.9, 0.88), MeshKit.at(-1.82, 0.42, bz + sz))
		for j in 2:
			k.box(Vector3(0.025, 0.12, 0.5), Color(0.96, 0.4, 0.22) if j == 0 else Color(0.96, 0.96, 0.94), MeshKit.at(-1.82, 0.62 - j * 0.14, bz))
	# a site flag on the trailer roof
	flag(k, Vector3(tx1 - 0.45, top + 0.08, tz0 + 0.2), 1.0, orange, dark)
	return k.commit()


# ---------------------------------------------------------------- construction

## Scaffolding around a footprint (w x d metres) up to height h.
static func scaffold(w: float, d: float, h: float) -> Mesh:
	var k := MeshKit.new()
	var pole := Color(0.62, 0.6, 0.56)
	var plank := Pal.WOOD_LIGHT
	var hw := w * 0.5 - 0.15
	var hd := d * 0.5 - 0.15
	var nx := maxi(2, int(w / 2.2) + 1)
	var nz := maxi(2, int(d / 2.2) + 1)
	for i in nx:
		var x := -hw + 2.0 * hw * i / (nx - 1)
		for z in [-hd, hd]:
			k.cyl(0.05, h, pole, MeshKit.at(x, 0, z), 6)
	for j in nz:
		var z2 := -hd + 2.0 * hd * j / (nz - 1)
		for x2 in [-hw, hw]:
			k.cyl(0.05, h, pole, MeshKit.at(x2, 0, z2), 6)
	var levels := maxi(1, int(h / 1.3))
	for l in levels:
		var y := 1.1 + l * 1.3
		if y > h - 0.1:
			break
		for z in [-hd, hd]:
			k.rbox(Vector3(w - 0.2, 0.06, 0.34), 0.02, plank, MeshKit.at(0, y, z))
			k.rbox(Vector3(w - 0.2, 0.04, 0.04), 0.01, pole, MeshKit.at(0, y + 0.5, z + signf(z) * 0.15))
		for x in [-hw, hw]:
			k.rbox(Vector3(0.34, 0.06, d - 0.2), 0.02, plank, MeshKit.at(x, y, 0))
	# cross braces on the front
	for i in nx - 1:
		var x0 := -hw + 2.0 * hw * i / (nx - 1)
		var x1 := -hw + 2.0 * hw * (i + 1) / (nx - 1)
		var len := Vector2(x1 - x0, minf(h, 2.4)).length()
		var ang := rad_to_deg(atan2(minf(h, 2.4), x1 - x0))
		k.cyl(0.03, len, pole, MeshKit.xf(Vector3(x0, 0.1, hd + 0.05), Vector3(0, 0, -(90 - ang))), 5)
	return k.commit()


## A construction site's ground: a dirt pad with stacked timber and bricks.
static func site_ground(w: float, d: float) -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(w - 0.1, 0.1, d - 0.1), 0.04, Color(0.62, 0.52, 0.4), MeshKit.at(0, 0.05, 0))
	k.rbox(Vector3(w - 0.5, 0.06, d - 0.5), 0.03, Color(0.7, 0.66, 0.6), MeshKit.at(0, 0.11, 0))
	# timber and bricks by the front corner
	for i in 3:
		k.rbox(Vector3(1.1, 0.1, 0.14), 0.02, Pal.WOOD_LIGHT, MeshKit.at(w * 0.5 - 0.8, 0.2 + i * 0.1, d * 0.5 - 0.35 - (i % 2) * 0.16))
	for i in 4:
		k.rbox(Vector3(0.3, 0.14, 0.18), 0.02, Pal.BRICK, MeshKit.at(-w * 0.5 + 0.5 + (i % 2) * 0.32, 0.2 + (i / 2) * 0.14, d * 0.5 - 0.4))
	return k.commit()


# ---------------------------------------------------------------- obstacles

static func obstacle(kind: String) -> Mesh:
	var k := MeshKit.new()
	match kind:
		"bush":
			k.sphere(0.6, Color(0.4, 0.5, 0.3), MeshKit.at(0, 0.45, 0), 12, 8)
			k.sphere(0.45, Color(0.46, 0.56, 0.34), MeshKit.at(0.35, 0.55, 0.2), 10, 7)
			k.sphere(0.4, Color(0.36, 0.46, 0.28), MeshKit.at(-0.35, 0.4, -0.2), 10, 7)
			for i in 6:
				var a := TAU * i / 6.0
				k.sphere(0.06, Color(0.62, 0.24, 0.3), MeshKit.at(cos(a) * 0.5, 0.6 + sin(a * 2.0) * 0.15, sin(a) * 0.5), 6, 4)
		"rock":
			k.ellipsoid(Vector3(0.75, 0.55, 0.65), Color(0.6, 0.58, 0.55), MeshKit.xf(Vector3(0, 0.35, 0), Vector3(0, 20, 8)), 9, 6)
			k.ellipsoid(Vector3(0.4, 0.3, 0.35), Color(0.54, 0.52, 0.5), MeshKit.at(0.55, 0.15, 0.35), 8, 5)
			k.ellipsoid(Vector3(0.5, 0.08, 0.4), Color(0.48, 0.58, 0.36), MeshKit.at(-0.1, 0.78, -0.05), 8, 4)
		"ewaste":
			# a heap of old monitors, keyboards and tangled cables
			k.ellipsoid(Vector3(0.55, 0.2, 0.5), Color(0.42, 0.4, 0.38), MeshKit.at(0, 0.08, 0), 10, 5)
			k.rbox(Vector3(0.5, 0.4, 0.4), 0.06, Color(0.86, 0.84, 0.76), MeshKit.xf(Vector3(-0.1, 0.35, -0.05), Vector3(10, 20, -12)))
			k.rbox(Vector3(0.36, 0.26, 0.02), 0.03, Color(0.2, 0.24, 0.24), MeshKit.xf(Vector3(-0.06, 0.38, 0.16), Vector3(10, 20, -12)))
			k.rbox(Vector3(0.5, 0.04, 0.18), 0.01, Color(0.3, 0.3, 0.32), MeshKit.xf(Vector3(0.25, 0.22, 0.25), Vector3(0, -30, 15)))
			k.rbox(Vector3(0.3, 0.12, 0.3), 0.03, Color(0.24, 0.24, 0.26), MeshKit.xf(Vector3(0.3, 0.12, -0.25), Vector3(0, 40, 0)))
			for i in 4:
				var a2 := TAU * i / 4.0 + 0.3
				k.torus(0.14, 0.015, [Color(0.86, 0.3, 0.26), Color(0.3, 0.5, 0.86), Color(0.94, 0.8, 0.3), Color(0.2, 0.2, 0.22)][i], MeshKit.xf(Vector3(cos(a2) * 0.35, 0.18, sin(a2) * 0.3), Vector3(60, a2 * 57.3, 0)), 10, 3)
		"oak":
			k.add_mesh(Terrain.decor_mesh("oak"), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(1.5, 1.5, 1.5)))
			k.ellipsoid(Vector3(1.3, 0.06, 1.2), Color(0.36, 0.44, 0.28), MeshKit.at(0, 0.02, 0), 12, 3)
		"pine":
			k.add_mesh(Terrain.decor_mesh("pine"), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.15, 1.0)))
		"container":
			# a rusty old shipping container, tipped and overgrown
			var rust := Color(0.66, 0.36, 0.26)
			var c := MeshKit.xf(Vector3(0, 0.62, 0), Vector3(0, 30, 4))
			k.rbox(Vector3(2.6, 1.2, 1.2), 0.04, rust, c)
			for i in 12:
				k.rbox(Vector3(0.05, 1.1, 1.22), 0.01, rust.darkened(0.15), c * MeshKit.at(-1.2 + i * 0.22, 0, 0))
			k.rbox(Vector3(0.05, 1.2, 1.2), 0.02, Color(0.5, 0.28, 0.2), c * MeshKit.at(1.31, 0, 0))
			k.ellipsoid(Vector3(0.9, 0.1, 0.6), Color(0.42, 0.52, 0.32), MeshKit.at(-0.4, 1.22, -0.1), 8, 4)
			k.sphere(0.35, Color(0.4, 0.5, 0.33), MeshKit.at(1.1, 0.25, 0.6), 8, 5)
	return k.commit()
