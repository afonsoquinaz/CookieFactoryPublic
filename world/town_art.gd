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


# ---------------------------------------------------------------- builder's hut

static func hut() -> Mesh:
	var k := MeshKit.new()
	var wall := Color(0.86, 0.66, 0.42)
	k.rbox(Vector3(3.4, 0.2, 3.0), 0.05, Pal.STONE, MeshKit.at(0, 0.1, -0.4))
	# plank shed with a lean-to roof
	k.rbox(Vector3(2.4, 2.0, 1.8), 0.06, wall, MeshKit.at(-0.3, 1.2, -0.9))
	for i in 7:
		k.rbox(Vector3(0.03, 2.0, 1.82), 0.005, wall.darkened(0.15), MeshKit.at(-1.4 + i * 0.36, 1.2, -0.9))
	var shingle := Color(0.66, 0.46, 0.3)
	var rt := MeshKit.xf(Vector3(-0.3, 2.35, -0.8), Vector3(14, 0, 0))
	k.rbox(Vector3(2.8, 0.12, 2.4), 0.04, shingle, rt)
	for r in 5:
		k.rbox(Vector3(2.82, 0.05, 0.08), 0.02, shingle.darkened(0.18), rt * MeshKit.at(0, 0.07, -1.0 + r * 0.48))
	# stovepipe and a little flag with a hammer
	k.cyl(0.09, 1.0, Pal.STEEL_DARK, MeshKit.at(0.6, 2.2, -1.4), 8)
	k.cyl(0.13, 0.1, Pal.STEEL_DARK, MeshKit.at(0.6, 3.2, -1.4), 8)
	flag(k, Vector3(-1.35, 2.2, -1.5), 1.0, Pal.OCHRE)
	k.rbox(Vector3(0.75, 1.4, 0.08), 0.06, Pal.WOOD_DARK, MeshKit.at(0.35, 0.9, 0.02))
	k.rbox(Vector3(0.5, 0.5, 0.08), 0.05, Color(0.6, 0.72, 0.78), MeshKit.at(-0.8, 1.4, 0.02))
	# hard hat on a hook, a sign with a hammer
	k.ellipsoid(Vector3(0.2, 0.12, 0.2), Color(0.97, 0.78, 0.26), MeshKit.at(-0.25, 1.75, 0.12), 10, 5)
	k.rbox(Vector3(0.9, 0.42, 0.06), 0.12, Pal.OCHRE, MeshKit.at(-0.3, 2.0, 0.04))
	k.cyl(0.03, 0.4, Pal.WOOD_DARK, MeshKit.xf(Vector3(-0.42, 2.0, 0.09), Vector3(0, 0, 60)), 6)
	k.rbox(Vector3(0.16, 0.08, 0.06), 0.02, Pal.STEEL_DARK, MeshKit.xf(Vector3(-0.2, 2.1, 0.1), Vector3(0, 0, -30)))
	# sawhorse with a plank, a stack of timber, a wheelbarrow
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.06, 0.6, 0.5), 0.02, Pal.WOOD_DARK, MeshKit.xf(Vector3(1.3 + sx * 0.35, 0.3, -0.5), Vector3(0, 0, sx * 10)))
	k.rbox(Vector3(1.2, 0.06, 0.3), 0.02, Pal.WOOD_LIGHT, MeshKit.at(1.3, 0.62, -0.5))
	for i in 4:
		k.rbox(Vector3(0.14, 0.12, 1.4), 0.02, Pal.WOOD_LIGHT.darkened(0.06 * (i % 2)), MeshKit.at(1.25 + (i % 2) * 0.16 - 0.08, 0.06 + (i / 2) * 0.12, -1.4))
	k.rbox(Vector3(0.5, 0.25, 0.7), 0.06, Pal.SAGE, MeshKit.at(-1.4, 0.4, 0.3))
	k.cyl(0.14, 0.08, Pal.RUBBER, MeshKit.xf(Vector3(-1.4, 0.15, 0.7), Vector3(0, 0, 90)) * MeshKit.at(0, -0.04, 0), 10)
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
