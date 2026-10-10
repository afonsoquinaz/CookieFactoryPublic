class_name TownArt
## Looks for the town buildings: the Cookie Hall (five looks, plus a pennant
## on the roof for every level), the Bakery house, the Builder's Hut,
## construction scaffolding and the obstacles on new land.
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


# ---------------------------------------------------------------- the Cookie Hall

## The Cookie Hall at visual tier t (0..4) and Hall level lvl (pennants).
static func hall(t: int, lvl: int) -> Mesh:
	var k := MeshKit.new()
	match t:
		0: _hall_cottage(k)
		1: _hall_townhouse(k)
		2: _hall_guild(k)
		3: _hall_grand(k)
		_: _hall_royal(k)
	# a pennant on the roof line for every Hall level
	var cols := [Pal.TERRACOTTA, Pal.SAGE, Pal.OCHRE, Pal.SLATE, Pal.CREAM]
	var n := clampi(lvl, 1, 15)
	var y: float = [3.0, 4.6, 5.0, 5.2, 5.6][t]
	var zr: float = [-3.4, -3.5, -3.5, -3.6, -3.6][t]
	for i in n:
		var x := -3.3 + 6.6 * (float(i) + 0.5) / n
		if t >= 2 and absf(x) < 1.3:
			continue
		flag(k, Vector3(x, y, zr), 0.9, cols[i % cols.size()])
	return k.commit()


static func _steps(k: MeshKit, w: float, z: float, n := 3, col := Pal.STONE) -> void:
	for i in n:
		k.rbox(Vector3(w - i * 0.3, 0.15, 0.42), 0.03, col.lightened(0.04 * i), MeshKit.at(0, 0.075 + i * 0.15, z - i * 0.3))


static func _hall_cottage(k: MeshKit) -> void:
	var wall := Color(0.95, 0.91, 0.82)
	var beam := Pal.WOOD_DARK
	# stone plinth
	k.rbox(Vector3(7.0, 0.35, 5.6), 0.08, Pal.STONE, MeshKit.at(0, 0.17, -1.0))
	k.rbox(Vector3(6.0, 2.5, 4.4), 0.1, wall, MeshKit.at(0, 1.6, -1.2))
	# timber framing
	for x in [-3.0, -1.0, 1.0, 3.0]:
		k.rbox(Vector3(0.16, 2.5, 0.12), 0.03, beam, MeshKit.at(x, 1.6, 1.04))
	k.rbox(Vector3(6.1, 0.14, 0.12), 0.03, beam, MeshKit.at(0, 1.55, 1.04))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.12, 2.5, 4.5), 0.03, beam, MeshKit.at(sx * 3.02, 1.6, -1.2))
	gable(k, Vector3(0, 2.85, -1.2), 6.0, 4.4, 1.7, Pal.TERRACOTTA, wall)
	# chimney
	k.rbox(Vector3(0.6, 1.6, 0.6), 0.05, Pal.BRICK, MeshKit.at(1.9, 3.8, -2.2))
	k.rbox(Vector3(0.7, 0.12, 0.7), 0.03, Pal.BRICK_DARK, MeshKit.at(1.9, 4.6, -2.2))
	# double door with an arch and a striped awning
	k.rbox(Vector3(1.5, 2.0, 0.1), 0.6, beam, MeshKit.at(0, 1.35, 1.0))
	k.rbox(Vector3(1.2, 1.75, 0.12), 0.5, Pal.WOOD, MeshKit.at(0, 1.25, 1.02))
	k.rbox(Vector3(0.03, 1.6, 0.13), 0.01, beam, MeshKit.at(0, 1.2, 1.04))
	for sx in [-1.0, 1.0]:
		k.sphere(0.05, Pal.BRASS, MeshKit.at(sx * 0.14, 1.2, 1.1), 6, 4)
	for i in 6:
		k.rbox(Vector3(0.36, 0.05, 0.8), 0.015, Pal.TERRACOTTA if i % 2 == 0 else Pal.CREAM, MeshKit.xf(Vector3(-0.9 + i * 0.36, 2.55, 1.35), Vector3(-22, 0, 0)))
	# sign with a cookie
	k.rbox(Vector3(1.4, 0.6, 0.1), 0.25, beam, MeshKit.at(0, 3.25, 1.05))
	Items.cookie_into(k, "choc", 0.24, 0.05, MeshKit.xf(Vector3(0, 3.25, 1.12), Vector3(90, 0, 0)))
	for sx in [-1.0, 1.0]:
		window(k, Vector3(sx * 2.0, 1.75, 1.0), 0.9, 0.9, beam, Color(0.6, 0.72, 0.78), true)
	_steps(k, 2.2, 1.6, 2)
	bench(k, Vector3(-2.3, 0, 2.3), 1.4)
	bench(k, Vector3(2.3, 0, 2.3), 1.4)
	sacks(k, Vector3(-3.6, 0, 0.6), 3)
	crate(k, Vector3(3.55, 0, 0.5), 0.55, 15)


static func _hall_townhouse(k: MeshKit) -> void:
	var wall := Color(0.95, 0.91, 0.82)
	var beam := Pal.WOOD_DARK
	k.rbox(Vector3(7.4, 0.35, 5.8), 0.08, Pal.STONE, MeshKit.at(0, 0.17, -1.0))
	# brick ground floor, timbered upper floor
	k.rbox(Vector3(6.4, 2.0, 4.6), 0.1, Pal.BRICK, MeshKit.at(0, 1.35, -1.2))
	for r in 6:
		k.rbox(Vector3(6.42, 0.03, 4.62), 0.005, Pal.BRICK_DARK, MeshKit.at(0, 0.6 + r * 0.3, -1.2))
	k.rbox(Vector3(6.7, 0.16, 4.9), 0.04, Pal.STONE_DARK, MeshKit.at(0, 2.4, -1.2))
	k.rbox(Vector3(6.4, 1.8, 4.6), 0.1, wall, MeshKit.at(0, 3.35, -1.2))
	for x in [-3.1, -1.6, 1.6, 3.1]:
		k.rbox(Vector3(0.14, 1.8, 0.1), 0.03, beam, MeshKit.at(x, 3.35, 1.13))
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(1.6, 0.1, 0.1), 0.02, beam, MeshKit.xf(Vector3(sd * 2.35, 3.35, 1.13), Vector3(0, 0, sd * 40)))
	gable(k, Vector3(0, 4.25, -1.2), 6.4, 4.6, 1.8, Pal.SLATE, wall)
	# dormers
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.9, 0.8, 0.8), 0.05, wall, MeshKit.at(sx * 1.7, 4.75, 0.25))
		window(k, Vector3(sx * 1.7, 4.75, 0.66), 0.5, 0.5, beam)
		gable(k, Vector3(sx * 1.7, 5.15, 0.25), 0.8, 0.9, 0.45, Pal.SLATE, wall, false, 0.08, false)
	for i in 2:
		k.rbox(Vector3(0.65, 1.2, 0.6), 0.05, Pal.BRICK, MeshKit.at(-2.2 + i * 4.4, 5.3, -2.3))
	# door, clock above it, windows
	k.rbox(Vector3(1.6, 2.1, 0.1), 0.7, Pal.STONE_DARK, MeshKit.at(0, 1.4, 1.1))
	k.rbox(Vector3(1.25, 1.85, 0.12), 0.55, Color(0.3, 0.42, 0.36), MeshKit.at(0, 1.3, 1.12))
	k.sphere(0.05, Pal.BRASS, MeshKit.at(0.2, 1.25, 1.2), 6, 4)
	k.cyl(0.45, 0.08, Pal.CREAM, MeshKit.xf(Vector3(0, 3.35, 1.14), Vector3(90, 0, 0)), 18)
	k.torus(0.45, 0.05, Pal.BRASS, MeshKit.xf(Vector3(0, 3.35, 1.2), Vector3(90, 0, 0)), 18, 4)
	k.rbox(Vector3(0.04, 0.3, 0.02), 0.01, Pal.INK, MeshKit.at(0, 3.45, 1.24))
	k.rbox(Vector3(0.22, 0.04, 0.02), 0.01, Pal.INK, MeshKit.at(0.1, 3.35, 1.24))
	for sx in [-1.0, 1.0]:
		window(k, Vector3(sx * 2.1, 1.5, 1.1), 0.95, 1.1, Pal.CREAM, Color(0.6, 0.72, 0.78), true, true)
		window(k, Vector3(sx * 2.4, 3.4, 1.12), 0.8, 0.9, beam, Color(0.6, 0.72, 0.78), true)
	_steps(k, 2.4, 1.6, 2)
	bench(k, Vector3(-2.4, 0, 2.4), 1.5)
	bench(k, Vector3(2.4, 0, 2.4), 1.5)
	lamp_post(k, Vector3(-3.6, 0, 2.6))
	lamp_post(k, Vector3(3.6, 0, 2.6))
	sacks(k, Vector3(-3.7, 0, 0.3), 3)


static func _hall_guild(k: MeshKit) -> void:
	var stone := Color(0.86, 0.82, 0.74)
	var trim := Color(0.74, 0.7, 0.62)
	var roof := Color(0.42, 0.56, 0.52)
	k.rbox(Vector3(7.8, 0.4, 6.2), 0.08, Pal.STONE_DARK, MeshKit.at(0, 0.2, -0.9))
	# main hall and two lower wings
	k.rbox(Vector3(4.2, 3.6, 4.6), 0.1, stone, MeshKit.at(0, 2.2, -1.3))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(1.8, 2.6, 4.0), 0.1, stone, MeshKit.at(sx * 2.95, 1.7, -1.4))
		gable(k, Vector3(sx * 2.95, 3.0, -1.4), 4.0, 1.8, 0.9, roof, stone, false, 0.2)
		for z in [0.62]:
			window(k, Vector3(sx * 2.95, 1.7, z), 0.7, 1.2, trim, Color(0.6, 0.72, 0.78), true, true)
	for r in 3:
		k.rbox(Vector3(4.24, 0.05, 4.64), 0.01, trim, MeshKit.at(0, 1.0 + r * 1.1, -1.3))
	gable(k, Vector3(0, 4.0, -1.3), 4.2, 4.6, 1.5, roof, stone)
	# clock tower over the door
	k.rbox(Vector3(1.6, 2.4, 1.6), 0.06, stone, MeshKit.at(0, 5.0, 0.2))
	k.rbox(Vector3(1.7, 0.12, 1.7), 0.03, trim, MeshKit.at(0, 6.2, 0.2))
	k.cone(1.25, 1.6, roof, MeshKit.xf(Vector3(0, 6.25, 0.2), Vector3(0, 45, 0)), 4)
	k.sphere(0.12, Pal.BRASS, MeshKit.at(0, 7.9, 0.2), 8, 5)
	k.cyl(0.5, 0.08, Pal.CREAM, MeshKit.xf(Vector3(0, 5.2, 1.0), Vector3(90, 0, 0)), 20)
	k.torus(0.5, 0.06, Pal.BRASS, MeshKit.xf(Vector3(0, 5.2, 1.06), Vector3(90, 0, 0)), 20, 4)
	k.rbox(Vector3(0.05, 0.36, 0.02), 0.01, Pal.INK, MeshKit.at(0, 5.32, 1.1))
	k.rbox(Vector3(0.26, 0.05, 0.02), 0.01, Pal.INK, MeshKit.at(0.11, 5.2, 1.1))
	# great arched door and windows
	k.rbox(Vector3(1.8, 2.6, 0.12), 0.85, trim, MeshKit.at(0, 1.65, 1.0))
	k.rbox(Vector3(1.4, 2.3, 0.14), 0.7, Color(0.36, 0.26, 0.2), MeshKit.at(0, 1.5, 1.02))
	for sx in [-1.0, 1.0]:
		window(k, Vector3(sx * 1.4, 2.8, 1.0), 0.7, 1.4, trim, Color(0.6, 0.72, 0.78), false, true)
	_steps(k, 3.0, 1.6, 3)
	bench(k, Vector3(-2.6, 0, 2.5), 1.5)
	bench(k, Vector3(2.6, 0, 2.5), 1.5)
	lamp_post(k, Vector3(-3.7, 0, 2.7), 2.4)
	lamp_post(k, Vector3(3.7, 0, 2.7), 2.4)
	for sx in [-1.0, 1.0]:
		k.cyl(0.32, 0.4, Pal.TERRACOTTA, MeshKit.at(sx * 1.6, 0.4, 1.7), 10, 0.03, 0.4)
		k.sphere(0.4, Pal.LEAF, MeshKit.at(sx * 1.6, 1.15, 1.7), 10, 7)


static func _hall_grand(k: MeshKit) -> void:
	var stone := Color(0.93, 0.9, 0.84)
	var trim := Color(0.8, 0.76, 0.68)
	var roof := Color(0.46, 0.6, 0.56)
	k.rbox(Vector3(7.9, 0.45, 6.4), 0.08, Pal.STONE_DARK, MeshKit.at(0, 0.22, -0.8))
	k.rbox(Vector3(7.4, 3.2, 4.4), 0.1, stone, MeshKit.at(0, 2.05, -1.5))
	k.rbox(Vector3(7.6, 0.25, 4.6), 0.05, trim, MeshKit.at(0, 3.75, -1.5))
	for sx in [-1.0, 1.0]:
		for i in 2:
			window(k, Vector3(sx * (2.3 + i * 1.1), 2.0, 0.72), 0.65, 1.4, trim, Color(0.6, 0.72, 0.78), true, true)
		# corner pavilions with hipped roofs and flags
		k.rbox(Vector3(1.6, 3.8, 1.6), 0.08, stone, MeshKit.at(sx * 3.1, 2.35, -1.5))
		k.cone(1.2, 1.3, roof, MeshKit.xf(Vector3(sx * 3.1, 4.25, -1.5), Vector3(0, 45, 0)), 4)
		flag(k, Vector3(sx * 3.1, 5.4, -1.5), 1.2, Pal.TERRACOTTA)
	# columned portico with a pediment
	k.rbox(Vector3(3.6, 0.3, 1.8), 0.04, trim, MeshKit.at(0, 0.6, 1.25))
	for i in 4:
		var x := -1.35 + i * 0.9
		k.cyl(0.18, 2.8, stone, MeshKit.at(x, 0.75, 1.75), 12, 0.03)
		k.rbox(Vector3(0.46, 0.14, 0.46), 0.03, trim, MeshKit.at(x, 3.6, 1.75))
	k.rbox(Vector3(3.9, 0.35, 1.9), 0.04, trim, MeshKit.at(0, 3.85, 1.3))
	k.prism(PackedVector2Array([Vector2(-2.0, 0), Vector2(0, 0.9), Vector2(2.0, 0)]), 1.9, stone, MeshKit.xf(Vector3(0, 4.02, 2.25), Vector3(-90, 0, 0)))
	Items.cookie_into(k, "choc", 0.3, 0.06, MeshKit.xf(Vector3(0, 4.35, 2.28), Vector3(90, 0, 0)))
	k.rbox(Vector3(1.4, 2.4, 0.12), 0.65, Color(0.36, 0.26, 0.2), MeshKit.at(0, 1.95, 0.75))
	# central dome with a lantern
	k.cyl(1.5, 0.9, stone, MeshKit.at(0, 3.85, -1.6), 20, 0.04)
	k.ellipsoid(Vector3(1.55, 1.4, 1.55), roof, MeshKit.at(0, 4.75, -1.6), 20, 10)
	k.cyl(0.35, 0.6, stone, MeshKit.at(0, 6.0, -1.6), 10)
	k.cone(0.45, 0.5, roof, MeshKit.at(0, 6.6, -1.6), 10)
	k.sphere(0.12, Pal.BRASS, MeshKit.at(0, 7.15, -1.6), 8, 5)
	_steps(k, 3.8, 2.6, 3)
	for sx in [-1.0, 1.0]:
		bench(k, Vector3(sx * 2.9, 0, 2.6), 1.5)
		lamp_post(k, Vector3(sx * 3.75, 0, 3.1), 2.5)
		k.cyl(0.3, 0.45, Pal.STONE, MeshKit.at(sx * 2.2, 0.45, 1.6), 10, 0.03, 0.36)
		k.sphere(0.36, Color(0.34, 0.48, 0.3), MeshKit.at(sx * 2.2, 1.2, 1.6), 12, 8)


static func _hall_royal(k: MeshKit) -> void:
	var stone := Color(0.97, 0.95, 0.9)
	var trim := Pal.GOLD
	var roof := Color(0.32, 0.36, 0.52)
	k.rbox(Vector3(8.0, 0.5, 6.6), 0.08, Color(0.8, 0.78, 0.74), MeshKit.at(0, 0.25, -0.7))
	k.rbox(Vector3(8.02, 0.06, 6.62), 0.02, trim, MeshKit.at(0, 0.5, -0.7))
	k.rbox(Vector3(7.2, 3.6, 4.4), 0.1, stone, MeshKit.at(0, 2.3, -1.5))
	k.rbox(Vector3(7.4, 0.22, 4.6), 0.05, trim, MeshKit.at(0, 4.2, -1.5))
	for sx in [-1.0, 1.0]:
		for i in 2:
			window(k, Vector3(sx * (1.9 + i * 1.0), 2.3, 0.72), 0.6, 1.6, trim, Color(0.98, 0.84, 0.55, 0.6), false, true)
		# round towers with gold cones
		k.cyl(0.95, 5.0, stone, MeshKit.at(sx * 3.3, 0.5, -1.2), 18, 0.05)
		for y in [1.8, 3.4, 5.0]:
			k.torus(0.96, 0.05, trim, MeshKit.at(sx * 3.3, y, -1.2), 18, 4)
		k.cone(1.15, 2.0, Pal.GOLD, MeshKit.at(sx * 3.3, 5.5, -1.2), 18)
		flag(k, Vector3(sx * 3.3, 7.4, -1.2), 1.0, Pal.TERRACOTTA, Pal.GOLD)
		# banners on the front
		k.rbox(Vector3(0.7, 1.8, 0.05), 0.03, Color(0.56, 0.22, 0.2), MeshKit.at(sx * 1.3, 2.9, 0.75))
		k.rbox(Vector3(0.5, 0.5, 0.06), 0.06, Pal.GOLD, MeshKit.at(sx * 1.3, 3.2, 0.78))
		k.prism(PackedVector2Array([Vector2(-0.35, 0), Vector2(0, -0.3), Vector2(0.35, 0)]), 0.05, Color(0.56, 0.22, 0.2), MeshKit.xf(Vector3(sx * 1.3, 2.0, 0.78), Vector3(-90, 0, 0)))
	# great gold dome topped by a crowned royal cookie
	k.cyl(1.8, 1.0, stone, MeshKit.at(0, 4.3, -1.6), 22, 0.04)
	k.torus(1.8, 0.07, trim, MeshKit.at(0, 5.3, -1.6), 22, 4)
	k.ellipsoid(Vector3(1.8, 1.7, 1.8), Pal.GOLD, MeshKit.at(0, 5.3, -1.6), 22, 11)
	for i in 8:
		var a := TAU * i / 8.0
		k.rbox(Vector3(0.06, 1.5, 0.06), 0.02, Pal.GOLD.darkened(0.15), MeshKit.xf(Vector3(cos(a) * 1.4, 6.1, -1.6 + sin(a) * 1.4), Vector3(0, -rad_to_deg(a), rad_to_deg(0.6))))
	Items.cookie_into(k, "royal", 0.55, 0.16, MeshKit.xf(Vector3(0, 7.6, -1.5), Vector3(90, 0, 0)))
	k.torus(0.6, 0.06, Pal.GOLD, MeshKit.xf(Vector3(0, 7.6, -1.4), Vector3(90, 0, 0)), 20, 4)
	for i in 5:
		var a2 := PI * (0.15 + 0.7 * i / 4.0)
		k.cone(0.07, 0.22, Pal.GOLD, MeshKit.at(cos(a2) * 0.6, 7.6 + sin(a2) * 0.6, -1.4), 6)
	# grand doors under an arch
	k.rbox(Vector3(1.9, 2.8, 0.14), 0.9, trim, MeshKit.at(0, 1.95, 0.72))
	k.rbox(Vector3(1.5, 2.5, 0.16), 0.75, Color(0.4, 0.18, 0.16), MeshKit.at(0, 1.8, 0.74))
	_steps(k, 4.0, 1.9, 3, Color(0.86, 0.84, 0.8))
	for sx in [-1.0, 1.0]:
		bench(k, Vector3(sx * 2.7, 0, 2.6), 1.5)
		lamp_post(k, Vector3(sx * 3.75, 0, 3.1), 2.6)
		k.cyl(0.32, 0.5, Pal.GOLD, MeshKit.at(sx * 1.9, 0.5, 1.9), 10, 0.03, 0.4)
		k.sphere(0.4, Color(0.34, 0.48, 0.3), MeshKit.at(sx * 1.9, 1.3, 1.9), 12, 8)


# ---------------------------------------------------------------- bakery house

## The Bakery's floor and back wall (the line itself is LineArt). The floor
## covers the whole footprint (w x d metres); the wall runs along the back.
static func bakery_house(t: int, w: float, d: float) -> Mesh:
	var k := MeshKit.new()
	var floor_a: Color = [Color(0.8, 0.72, 0.6), Color(0.82, 0.78, 0.72), Color(0.88, 0.84, 0.76), Color(0.78, 0.8, 0.82), Color(0.94, 0.9, 0.82)][t]
	var floor_b: Color = floor_a.darkened(0.08)
	var wall: Color = [Pal.WOOD, Pal.BRICK, Color(0.94, 0.9, 0.8), Color(0.72, 0.74, 0.76), Color(0.96, 0.94, 0.88)][t]
	var trim: Color = [Pal.WOOD_DARK, Pal.STONE_DARK, Pal.TERRACOTTA, Pal.STEEL_DARK, Pal.GOLD][t]
	# chequered floor
	k.rbox(Vector3(w - 0.1, 0.12, d - 0.1), 0.05, trim, MeshKit.at(0, 0.06, 0))
	var nx := int(w / 1.0)
	var nz := int((d - 0.4) / 1.0)
	for i in nx:
		for j in nz:
			var c := floor_a if (i + j) % 2 == 0 else floor_b
			k.rbox(Vector3(0.96, 0.03, 0.96), 0.03, c, MeshKit.at(-w * 0.5 + 0.5 + i * (w - 0.2) / nx + 0.05, 0.13, -d * 0.5 + 0.7 + j * 1.0))
	# back wall with windows and a sign
	var h := 2.6 + t * 0.3
	k.rbox(Vector3(w, h, 0.35), 0.06, wall, MeshKit.at(0, h * 0.5 + 0.1, -d * 0.5 + 0.2))
	if t == 1:
		for r in int(h / 0.32):
			k.rbox(Vector3(w + 0.02, 0.025, 0.37), 0.005, Pal.BRICK_DARK, MeshKit.at(0, 0.3 + r * 0.32, -d * 0.5 + 0.2))
	if t == 2:
		for i in int(w / 0.4):
			for j in 3:
				if (i + j) % 2 == 0:
					k.rbox(Vector3(0.36, 0.34, 0.02), 0.02, Color(0.82, 0.76, 0.66), MeshKit.at(-w * 0.5 + 0.2 + i * 0.4, 0.4 + j * 0.36, -d * 0.5 + 0.385))
	k.rbox(Vector3(w + 0.2, 0.18, 0.55), 0.04, trim, MeshKit.at(0, h + 0.15, -d * 0.5 + 0.25))
	for x in [-w * 0.5 + 0.9, w * 0.5 - 0.9]:
		window(k, Vector3(x, h * 0.62, -d * 0.5 + 0.4), 0.8, 0.9, trim, Color(0.98, 0.86, 0.6, 0.6) if t >= 3 else Color(0.6, 0.72, 0.78))
	# sign: a big cookie on a board
	k.rbox(Vector3(2.2, 0.75, 0.12), 0.2, trim, MeshKit.at(0, h + 0.75, -d * 0.5 + 0.25))
	k.rbox(Vector3(2.0, 0.6, 0.13), 0.16, Pal.CREAM, MeshKit.at(0, h + 0.75, -d * 0.5 + 0.26))
	Items.cookie_into(k, ["shortbread", "sugar", "choc", "praline", "royal"][t], 0.24, 0.05, MeshKit.xf(Vector3(-0.6, h + 0.75, -d * 0.5 + 0.34), Vector3(90, 0, 0)))
	Items.cookie_into(k, ["sugar", "choc", "jam", "caramel", "royal"][t], 0.24, 0.05, MeshKit.xf(Vector3(0.6, h + 0.75, -d * 0.5 + 0.34), Vector3(90, 0, 0)))
	# side posts and a low front rail with a gap in the middle
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.22, h + 0.3, 0.22), 0.04, trim, MeshKit.at(sx * (w * 0.5 - 0.15), (h + 0.3) * 0.5, -d * 0.5 + 0.3))
		k.rbox(Vector3(w * 0.5 - 1.4, 0.08, 0.08), 0.02, trim, MeshKit.at(sx * (w * 0.25 + 0.6), 0.75, d * 0.5 - 0.15))
		for i in 4:
			k.rbox(Vector3(0.08, 0.7, 0.08), 0.02, trim, MeshKit.at(sx * (1.3 + i * (w * 0.5 - 1.5) / 3.0), 0.4, d * 0.5 - 0.15))
	if t >= 3:
		for sx in [-1.0, 1.0]:
			lamp_post(k, Vector3(sx * (w * 0.5 - 0.35), 0, d * 0.5 - 0.35), 2.0)
	if t >= 4:
		k.cone(0.5, 0.8, Pal.GOLD, MeshKit.at(0, h + 1.15, -d * 0.5 + 0.25), 12)
		k.sphere(0.14, Pal.GOLD, MeshKit.at(0, h + 2.0, -d * 0.5 + 0.25), 8, 5)
	return k.commit()


## The wheat bin by the mixer: a wooden bin on legs.
static func flour_bin(t: int) -> Mesh:
	var k := MeshKit.new()
	var c: Color = [Pal.WOOD, Pal.WOOD, Pal.STEEL, Pal.STEEL, Color(0.78, 0.5, 0.32)][t]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.5, 0.08), 0.02, Pal.WOOD_DARK, MeshKit.at(sx * 0.55, 0.25, sz * 0.38))
	k.rbox(Vector3(1.3, 0.4, 0.95), 0.05, c, MeshKit.at(0, 0.62, 0))
	k.rbox(Vector3(1.2, 0.05, 0.85), 0.02, Color(0.86, 0.74, 0.5), MeshKit.at(0, 0.8, 0))
	return k.commit()


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
		"stump":
			k.cyl(0.42, 0.55, Pal.WOOD, MeshKit.at(0, 0, 0), 12, 0.04, 0.38)
			k.cyl(0.36, 0.03, Pal.WOOD_LIGHT, MeshKit.at(0, 0.55, 0), 12)
			k.torus(0.2, 0.02, Pal.WOOD, MeshKit.at(0, 0.58, 0), 12, 3)
			for i in 4:
				var a2 := TAU * i / 4.0 + 0.3
				k.cyl(0.1, 0.5, Pal.WOOD_DARK, MeshKit.xf(Vector3(cos(a2) * 0.35, 0.08, sin(a2) * 0.35), Vector3(0, -rad_to_deg(a2), 70)), 6, 0.0, 0.04)
			k.sphere(0.1, Color(0.85, 0.5, 0.35), MeshKit.at(0.3, 0.1, 0.3), 6, 4)
		"oak":
			k.add_mesh(Terrain.decor_mesh("oak"), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(1.5, 1.5, 1.5)))
			k.ellipsoid(Vector3(1.3, 0.06, 1.2), Color(0.36, 0.44, 0.28), MeshKit.at(0, 0.02, 0), 12, 3)
		"pine":
			k.add_mesh(Terrain.decor_mesh("pine"), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.15, 1.0)))
		"boulders":
			k.ellipsoid(Vector3(1.0, 0.8, 0.9), Color(0.6, 0.58, 0.55), MeshKit.xf(Vector3(-0.3, 0.55, -0.2), Vector3(0, 30, 6)), 10, 7)
			k.ellipsoid(Vector3(0.7, 0.55, 0.6), Color(0.56, 0.54, 0.52), MeshKit.xf(Vector3(0.7, 0.35, 0.45), Vector3(0, -10, -8)), 9, 6)
			k.ellipsoid(Vector3(0.45, 0.35, 0.4), Color(0.64, 0.62, 0.58), MeshKit.at(-0.8, 0.22, 0.7), 8, 5)
			k.ellipsoid(Vector3(0.6, 0.08, 0.5), Color(0.48, 0.58, 0.36), MeshKit.at(-0.3, 1.3, -0.2), 8, 4)
	return k.commit()
