class_name Stations
## Work stations inside the sources (a solar panel, a crawler dish, a chiller,
## a crystal puller, an ore heap, a dev desk...) plus the streamed trees,
## shrubs and rocks of the landscape.
##
## A station stands at its spot's origin, facing +Z (where its technician
## stands). What it makes grows on it at product_at(res) until it's
## collected; some have a moving part (spinner) that turns while they work.

## Where the product sits on a station (local), and how big it grows.
static func product_at(res: String) -> Vector3:
	match res:
		"power": return Vector3(0, 0.08, 0.32)
		"data": return Vector3(0, 0.62, 0.0)
		"coolant": return Vector3(0.0, 0.08, 0.34)
		"silicon": return Vector3(0, 0.5, 0.05)
		"copper": return Vector3(0.0, 0.42, 0.0)
		"code", "labels", "experts": return Vector3(0.18, 0.62, 0.05)
		"feedback": return Vector3(0, 1.05, 0.08)
		"rare": return Vector3(0, 0.55, 0.0)
		"papers": return Vector3(-0.2, 0.08, 0.3)
		"fiber": return Vector3(0, 0.08, 0.34)
	return Vector3(0, 0.1, 0.3)


static func product_scale(res: String) -> float:
	match res:
		"code", "labels", "experts": return 0.55
		"data", "rare": return 0.75
	return 0.8


## A moving part (local pivot) or Vector3.INF for none.
static func spinner_at(res: String) -> Vector3:
	match res:
		"data": return Vector3(0, 0.55, -0.05)
		"coolant": return Vector3(0, 0.62, -0.1)
		"fiber": return Vector3(0, 0.42, -0.05)
	return Vector3.INF


static func station(res: String) -> Mesh:
	var k := MeshKit.new()
	match res:
		"power": _solar(k)
		"data": _crawler(k)
		"coolant": _chiller(k)
		"silicon": _puller(k)
		"copper": _ore(k, Color(0.84, 0.5, 0.3))
		"code": _desk(k, Color(0.5, 0.42, 0.78))
		"labels": _label_table(k)
		"feedback": _booth(k)
		"rare": _crystals(k)
		"papers": _whiteboard(k)
		"fiber": _spool_frame(k)
		"experts": _armchair(k)
	return k.commit()


static func spinner(res: String) -> Mesh:
	var k := MeshKit.new()
	match res:
		"data":
			# the dish itself: a shallow bowl tipped up, a feed horn
			var dish := Color(0.92, 0.93, 0.94)
			var b := MeshKit.xf(Vector3.ZERO, Vector3(-35, 0, 0))
			k.lathe(PackedVector2Array([Vector2(0, -0.02), Vector2(0.18, 0.0), Vector2(0.32, 0.08), Vector2(0.33, 0.1), Vector2(0.3, 0.1), Vector2(0.17, 0.03), Vector2(0, 0.01)]), dish, b, 16)
			k.cyl(0.012, 0.28, Pal.STEEL_DARK, b * MeshKit.at(0, 0.0, 0), 5)
			k.sphere(0.035, Items.lit(Color(0.4, 0.8, 1.0), 0.5), b * MeshKit.at(0, 0.3, 0), 8, 5)
		"coolant":
			for i in 4:
				k.rbox(Vector3(0.05, 0.02, 0.22), 0.01, Color(0.28, 0.3, 0.34), MeshKit.xf(Vector3.ZERO, Vector3(0, i * 90 + 45, 0)) * MeshKit.at(0, 0, 0.12))
			k.cyl(0.04, 0.03, Color(0.6, 0.62, 0.66), MeshKit.at(0, -0.01, 0), 8)
		"fiber":
			k.cyl(0.24, 0.04, Color(0.3, 0.32, 0.38), MeshKit.xf(Vector3(-0.2, 0, 0), Vector3(0, 0, -90)), 16)
			k.cyl(0.24, 0.04, Color(0.3, 0.32, 0.38), MeshKit.xf(Vector3(0.16, 0, 0), Vector3(0, 0, -90)), 16)
			k.cyl(0.17, 0.32, Items.lit(Color(0.98, 0.62, 0.86), 0.6), MeshKit.xf(Vector3(-0.16, 0, 0), Vector3(0, 0, -90)), 16)
			for i in 3:
				k.rbox(Vector3(0.36, 0.02, 0.02), 0.005, Color(1, 0.86, 0.95, 0.4), MeshKit.xf(Vector3.ZERO, Vector3(i * 60, 0, 0)) * MeshKit.at(0, 0.175, 0))
	return k.commit()


# ---------------------------------------------------------------- stations

static func _pad(k: MeshKit, w := 0.42, col := Color(0.34, 0.36, 0.4), p := Vector3(0, 0, 0.32)) -> void:
	k.rbox(Vector3(w, 0.06, w * 0.8), 0.02, col, MeshKit.at(p.x, 0.03, p.z))
	k.rbox(Vector3(w * 0.7, 0.012, 0.03), 0.005, Items.lit(Color(0.5, 0.95, 0.6), 0.5), MeshKit.at(p.x, 0.062, p.z + w * 0.33))


static func _solar(k: MeshKit) -> void:
	var frame := Color(0.82, 0.84, 0.86)
	k.cyl(0.04, 0.55, Pal.STEEL_DARK, MeshKit.at(0, 0, -0.1), 6)
	var t := MeshKit.xf(Vector3(0, 0.62, -0.1), Vector3(-28, 0, 0))
	k.rbox(Vector3(1.0, 0.04, 0.62), 0.015, frame, t)
	for i in 4:
		for j in 2:
			k.rbox(Vector3(0.22, 0.012, 0.27), 0.004, Color(0.18, 0.26, 0.44), t * MeshKit.at(-0.36 + i * 0.24, 0.022, -0.14 + j * 0.29))
	k.rbox(Vector3(0.98, 0.006, 0.01), 0.002, Color(0.6, 0.72, 0.9, 0.6), t * MeshKit.at(0, 0.03, 0.0))
	_pad(k, 0.38)


static func _crawler(k: MeshKit) -> void:
	# a pedestal with a status light; the dish turns on top (spinner)
	k.rbox(Vector3(0.42, 0.42, 0.42), 0.05, Color(0.88, 0.89, 0.9), MeshKit.at(0, 0.21, -0.05))
	k.rbox(Vector3(0.3, 0.1, 0.01), 0.02, Color(0.16, 0.18, 0.22), MeshKit.at(0, 0.3, 0.165))
	for i in 3:
		k.rbox(Vector3(0.04, 0.04, 0.012), 0.01, Items.lit([Color(0.4, 0.9, 1.0), Color(0.5, 1.0, 0.6), Color(1.0, 0.8, 0.4)][i], 0.4), MeshKit.at(-0.08 + i * 0.08, 0.3, 0.172))
	k.cyl(0.05, 0.12, Pal.STEEL_DARK, MeshKit.at(0, 0.42, -0.05), 8)


static func _chiller(k: MeshKit) -> void:
	# a chiller cabinet with louvres, a fan on top (spinner) and pipes
	var body := Color(0.86, 0.9, 0.94)
	k.rbox(Vector3(0.62, 0.56, 0.42), 0.04, body, MeshKit.at(0, 0.28, -0.1))
	for i in 5:
		k.rbox(Vector3(0.5, 0.025, 0.01), 0.005, Color(0.6, 0.66, 0.72), MeshKit.at(0, 0.12 + i * 0.07, 0.115))
	k.cyl(0.17, 0.05, Color(0.5, 0.56, 0.62), MeshKit.at(0, 0.56, -0.1), 14, 0.01)
	k.torus(0.17, 0.015, Color(0.36, 0.4, 0.46), MeshKit.at(0, 0.62, -0.1), 14, 4)
	for sx in [-1.0, 1.0]:
		k.cyl(0.035, 0.32, Color(0.36, 0.6, 0.86), MeshKit.xf(Vector3(sx * 0.31, 0.15, -0.1), Vector3(0, 0, sx * -90)), 8)
	k.rbox(Vector3(0.12, 0.06, 0.012), 0.01, Items.lit(Color(0.5, 0.8, 1.0), 0.4), MeshKit.at(0.2, 0.48, 0.115))
	_pad(k, 0.34, Color(0.34, 0.36, 0.4), Vector3(0, 0, 0.34))


static func _puller(k: MeshKit) -> void:
	# a crystal puller: a furnace with a glowing crucible window, a tall mast
	var shell := Color(0.84, 0.86, 0.9)
	k.cyl(0.26, 0.42, shell, MeshKit.at(0, 0, -0.05), 14, 0.04)
	k.rbox(Vector3(0.16, 0.12, 0.05), 0.03, Items.lit(Color(1.0, 0.6, 0.3), 0.35), MeshKit.at(0, 0.22, 0.2))
	k.cyl(0.2, 0.05, Color(0.5, 0.54, 0.6), MeshKit.at(0, 0.42, -0.05), 14)
	k.cyl(0.025, 0.95, Pal.STEEL_DARK, MeshKit.at(0.0, 0.45, -0.05), 6)
	k.rbox(Vector3(0.12, 0.08, 0.12), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 1.4, -0.05))
	k.rbox(Vector3(0.18, 0.5, 0.14), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0.34, 0.25, -0.1))
	k.rbox(Vector3(0.1, 0.06, 0.012), 0.01, Items.lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.at(0.34, 0.4, -0.025))


static func _ore(k: MeshKit, vein: Color) -> void:
	# a rocky ore heap with veins, a pickaxe stuck in it, a little cart
	var rock := Color(0.52, 0.5, 0.48)
	k.ellipsoid(Vector3(0.42, 0.28, 0.36), rock, MeshKit.at(0, 0.1, -0.08), 10, 6)
	k.ellipsoid(Vector3(0.24, 0.18, 0.22), rock.lightened(0.06), MeshKit.at(0.26, 0.06, 0.08), 8, 5)
	for i in 5:
		var a := TAU * i / 5.0 + 0.4
		k.ellipsoid(Vector3(0.06, 0.03, 0.05), vein, MeshKit.xf(Vector3(cos(a) * 0.3, 0.18 + (i % 2) * 0.1, sin(a) * 0.25 - 0.08), Vector3(0, a * 57.3, 20)), 6, 4)
	k.cyl(0.018, 0.42, Pal.WOOD, MeshKit.xf(Vector3(-0.22, 0.2, 0.05), Vector3(0, 0, 35)), 5)
	k.rbox(Vector3(0.22, 0.04, 0.04), 0.01, Pal.STEEL_DARK, MeshKit.xf(Vector3(-0.33, 0.37, 0.05), Vector3(0, 0, 35)))


static func _desk(k: MeshKit, accent: Color) -> void:
	# a dev desk: monitor with glowing code, keyboard, mug
	var top := Color(0.92, 0.9, 0.86)
	k.rbox(Vector3(0.82, 0.05, 0.46), 0.02, top, MeshKit.at(0, 0.56, -0.02))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.04, 0.54, 0.4), 0.01, Color(0.3, 0.32, 0.36), MeshKit.at(sx * 0.37, 0.27, -0.02))
	k.rbox(Vector3(0.46, 0.3, 0.03), 0.02, Color(0.14, 0.15, 0.18), MeshKit.at(-0.08, 0.82, -0.18))
	k.rbox(Vector3(0.42, 0.26, 0.01), 0.015, Color(0.16, 0.16, 0.22, 0.75), MeshKit.at(-0.08, 0.82, -0.163))
	for i in 4:
		k.rbox(Vector3(0.08 + (i % 3) * 0.06, 0.02, 0.008), 0.004, Items.lit(accent.lightened(0.2 + 0.1 * (i % 2)), 0.45), MeshKit.at(-0.22 + (0.04 + (i % 3) * 0.03), 0.9 - i * 0.05, -0.155))
	k.cyl(0.02, 0.1, Pal.STEEL_DARK, MeshKit.at(-0.08, 0.58, -0.2), 6)
	k.rbox(Vector3(0.3, 0.015, 0.1), 0.006, Color(0.24, 0.25, 0.28), MeshKit.at(-0.08, 0.59, 0.08))
	k.cyl(0.035, 0.07, accent, MeshKit.at(0.3, 0.585, 0.0), 8)


static func _label_table(k: MeshKit) -> void:
	# a standing table with a tablet and a tray of cards
	var top := Color(0.96, 0.84, 0.5)
	k.cyl(0.05, 0.56, Pal.STEEL_DARK, MeshKit.at(0, 0, -0.04), 8)
	k.cyl(0.2, 0.03, Pal.STEEL_DARK, MeshKit.at(0, 0, -0.04), 12)
	k.rbox(Vector3(0.7, 0.05, 0.42), 0.02, top, MeshKit.at(0, 0.58, -0.04))
	k.rbox(Vector3(0.28, 0.02, 0.2), 0.02, Color(0.14, 0.15, 0.18), MeshKit.xf(Vector3(-0.12, 0.62, -0.04), Vector3(-12, 0, 0)))
	k.rbox(Vector3(0.24, 0.01, 0.16), 0.015, Items.lit(Color(0.9, 0.95, 1.0), 0.55), MeshKit.xf(Vector3(-0.12, 0.632, -0.038), Vector3(-12, 0, 0)))
	for i in 3:
		k.rbox(Vector3(0.06, 0.012, 0.03), 0.004, [Color(0.3, 0.7, 0.42), Color(0.92, 0.5, 0.5), Color(0.3, 0.7, 0.42)][i], MeshKit.xf(Vector3(-0.12, 0.645, -0.08 + i * 0.04), Vector3(-12, 0, 0)))


static func _booth(k: MeshKit) -> void:
	# a rating kiosk: a tall screen with thumbs up / down buttons
	var shell := Color(0.96, 0.92, 0.9)
	k.rbox(Vector3(0.5, 0.06, 0.4), 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.03, -0.05))
	k.rbox(Vector3(0.42, 0.9, 0.18), 0.06, shell, MeshKit.at(0, 0.5, -0.1))
	k.rbox(Vector3(0.34, 0.42, 0.02), 0.03, Color(0.16, 0.17, 0.2, 0.8), MeshKit.at(0, 0.66, 0.0))
	k.rbox(Vector3(0.2, 0.05, 0.01), 0.01, Items.lit(Color(1.0, 0.6, 0.64), 0.45), MeshKit.at(0, 0.76, 0.012))
	k.rbox(Vector3(0.14, 0.04, 0.01), 0.01, Items.lit(Color(0.7, 0.9, 1.0), 0.5), MeshKit.at(-0.03, 0.66, 0.012))
	for sx in [-1.0, 1.0]:
		k.cyl(0.05, 0.03, Color(0.4, 0.78, 0.5) if sx < 0 else Color(0.9, 0.44, 0.44), MeshKit.xf(Vector3(sx * 0.09, 0.36, 0.0), Vector3(90, 0, 0)), 10)


static func _crystals(k: MeshKit) -> void:
	# a cluster of rare-earth crystals growing out of rock
	k.ellipsoid(Vector3(0.4, 0.14, 0.34), Color(0.46, 0.44, 0.46), MeshKit.at(0, 0.02, -0.05), 10, 5)
	var cs := [Color(0.76, 0.48, 0.86), Color(0.5, 0.82, 0.78), Color(0.94, 0.56, 0.72), Color(0.62, 0.4, 0.88)]
	for i in 6:
		var a := TAU * i / 6.0 + 0.3
		var r := 0.12 + (i % 2) * 0.1
		k.cone(0.07 + (i % 3) * 0.02, 0.35 + (i % 3) * 0.15, Items.lit(cs[i % 4], 0.78), MeshKit.xf(Vector3(cos(a) * r, 0.05, sin(a) * r * 0.8 - 0.05), Vector3(sin(a) * 18, 0, cos(a) * 18)), 6)
	k.cone(0.1, 0.62, Items.lit(cs[0], 0.7), MeshKit.at(0, 0.05, -0.08), 6)


static func _whiteboard(k: MeshKit) -> void:
	# a whiteboard on a stand, covered in equations, a stool
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.04, 1.2, 0.04), 0.01, Pal.STEEL_DARK, MeshKit.at(sx * 0.4, 0.6, -0.12))
		k.rbox(Vector3(0.04, 0.03, 0.4), 0.01, Pal.STEEL_DARK, MeshKit.at(sx * 0.4, 0.02, -0.12))
	k.rbox(Vector3(0.9, 0.62, 0.04), 0.02, Color(0.96, 0.97, 0.98), MeshKit.at(0, 0.9, -0.12))
	k.rbox(Vector3(0.94, 0.66, 0.03), 0.02, Color(0.7, 0.72, 0.76), MeshKit.at(0, 0.9, -0.14))
	var ink := [Color(0.3, 0.4, 0.8), Color(0.82, 0.3, 0.3), Color(0.2, 0.22, 0.26)]
	for i in 6:
		k.rbox(Vector3(0.12 + (i * 37 % 5) * 0.04, 0.02, 0.01), 0.005, ink[i % 3], MeshKit.at(-0.3 + (i % 2) * 0.32 + (i * 13 % 3) * 0.03, 1.1 - (i / 2) * 0.12, -0.097))
	k.torus(0.06, 0.008, ink[1], MeshKit.xf(Vector3(0.28, 0.75, -0.097), Vector3(90, 0, 0)), 10, 3)
	k.rbox(Vector3(0.6, 0.03, 0.06), 0.01, Color(0.7, 0.72, 0.76), MeshKit.at(0, 0.58, -0.08))
	_pad(k, 0.32, Color(0.4, 0.42, 0.46), Vector3(-0.2, 0, 0.3))


static func _spool_frame(k: MeshKit) -> void:
	# an A-frame holding a fibre spool (spinner), a little winder
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.05, 0.5, 0.05), 0.01, Pal.STEEL_DARK, MeshKit.xf(Vector3(sx * 0.27, 0.22, -0.15), Vector3(-12, 0, 0)))
		k.rbox(Vector3(0.05, 0.5, 0.05), 0.01, Pal.STEEL_DARK, MeshKit.xf(Vector3(sx * 0.27, 0.22, 0.05), Vector3(12, 0, 0)))
	k.rbox(Vector3(0.62, 0.05, 0.42), 0.02, Color(0.32, 0.34, 0.4), MeshKit.at(0, 0.025, -0.05))
	k.cyl(0.02, 0.6, Pal.STEEL, MeshKit.xf(Vector3(-0.3, 0.42, -0.05), Vector3(0, 0, -90)), 6)
	_pad(k, 0.32, Color(0.32, 0.34, 0.4), Vector3(0, 0, 0.34))


static func _armchair(k: MeshKit) -> void:
	# an expert's corner: armchair, side table with a lamp, a mini bookshelf
	var fabric := Color(0.4, 0.3, 0.46)
	k.rbox(Vector3(0.5, 0.2, 0.46), 0.08, fabric, MeshKit.at(-0.1, 0.2, -0.08))
	k.rbox(Vector3(0.5, 0.45, 0.12), 0.06, fabric.darkened(0.08), MeshKit.at(-0.1, 0.42, -0.28))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.1, 0.3, 0.44), 0.05, fabric.darkened(0.04), MeshKit.at(-0.1 + sx * 0.25, 0.28, -0.08))
	k.rbox(Vector3(0.26, 0.04, 0.26), 0.02, Pal.WOOD, MeshKit.at(0.25, 0.58, 0.02))
	k.cyl(0.03, 0.58, Pal.WOOD_DARK, MeshKit.at(0.25, 0, 0.02), 6)
	k.cyl(0.015, 0.25, Pal.BRASS, MeshKit.at(0.32, 0.6, -0.04), 5)
	k.cyl(0.08, 0.1, Items.lit(Color(1.0, 0.86, 0.6), 0.5), MeshKit.at(0.32, 0.85, -0.04), 10, 0.0, 0.05)
	k.rbox(Vector3(0.3, 0.7, 0.16), 0.02, Pal.WOOD, MeshKit.at(0.32, 0.35, -0.3))
	for j in 3:
		for i in 4:
			k.rbox(Vector3(0.05, 0.16, 0.12), 0.01, [Color(0.6, 0.3, 0.3), Color(0.3, 0.4, 0.6), Color(0.86, 0.68, 0.32), Color(0.36, 0.5, 0.38)][(i + j) % 4], MeshKit.at(0.21 + i * 0.07, 0.12 + j * 0.22, -0.28))


# ---------------------------------------------------------------- landscape

static func tree(kind: int) -> Mesh:
	var k := MeshKit.new()
	match kind:
		0:
			# olive-like round tree
			k.cyl(0.09, 0.9, Pal.WOOD_DARK, MeshKit.xf(Vector3.ZERO, Vector3(0, 0, 6)), 7, 0.02, 0.06)
			k.ellipsoid(Vector3(0.75, 0.5, 0.7), Color(0.44, 0.52, 0.36), MeshKit.at(0.05, 1.25, 0), 12, 7)
			k.ellipsoid(Vector3(0.5, 0.36, 0.5), Color(0.5, 0.58, 0.4), MeshKit.at(-0.3, 1.5, 0.15), 10, 6)
			k.ellipsoid(Vector3(0.45, 0.32, 0.45), Color(0.38, 0.46, 0.32), MeshKit.at(0.35, 1.05, -0.2), 10, 6)
		1:
			# tall cypress
			k.cyl(0.08, 0.35, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 6)
			var prof := PackedVector2Array([Vector2(0, 0.25), Vector2(0.3, 0.35), Vector2(0.42, 0.9), Vector2(0.4, 1.6), Vector2(0.3, 2.3), Vector2(0.14, 2.8), Vector2(0, 3.05)])
			k.lathe(prof, Pal.CYPRESS, Transform3D.IDENTITY, 10)
		2:
			# low shrub
			k.sphere(0.42, Color(0.4, 0.5, 0.33), MeshKit.at(0, 0.28, 0), 10, 6)
			k.sphere(0.32, Color(0.46, 0.55, 0.37), MeshKit.at(0.3, 0.22, 0.1), 9, 6)
			k.sphere(0.28, Color(0.36, 0.45, 0.3), MeshKit.at(-0.28, 0.2, -0.05), 9, 6)
		3:
			# rock
			k.ellipsoid(Vector3(0.5, 0.32, 0.42), Pal.STONE, MeshKit.xf(Vector3(0, 0.15, 0), Vector3(0, 20, 8)), 8, 5)
			k.ellipsoid(Vector3(0.28, 0.2, 0.26), Pal.STONE_DARK, MeshKit.at(0.42, 0.08, 0.15), 7, 4)
		4:
			# lavender tuft
			for i in 6:
				var a := TAU * i / 6.0
				var p := Vector3(cos(a) * 0.16, 0, sin(a) * 0.14)
				k.cyl(0.012, 0.28, Color(0.45, 0.52, 0.38), MeshKit.xf(p, Vector3(sin(a) * 10, 0, cos(a) * 10)), 4)
				k.ellipsoid(Vector3(0.035, 0.07, 0.035), Color(0.58, 0.52, 0.7), MeshKit.at(p.x * 1.2, 0.3, p.z * 1.2), 5, 3)
	return k.commit()
