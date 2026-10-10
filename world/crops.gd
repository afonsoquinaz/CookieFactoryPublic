class_name Crops
## Meshes for farm crops, nests, coops and props.

static func wheat() -> Mesh:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var stalk := Color(0.8, 0.64, 0.36)
	var ear := Color(0.9, 0.75, 0.45)
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf() * 0.4
		var r := 0.06 + rng.randf() * 0.1
		var h := 0.55 + rng.randf() * 0.2
		var lean := Vector3(cos(a) * 9, 0, sin(a) * 9)
		var base := Vector3(cos(a) * r, 0, sin(a) * r)
		var t := MeshKit.xf(base, Vector3(lean.z, 0, -lean.x))
		k.cyl(0.018, h, stalk, t, 5)
		k.ellipsoid(Vector3(0.045, 0.12, 0.045), ear, t * MeshKit.at(0, h + 0.07, 0), 8, 6)
	k.ellipsoid(Vector3(0.2, 0.06, 0.2), Color(0.62, 0.58, 0.36), MeshKit.at(0, 0.02, 0), 10, 4)
	return k.commit()


static func sugar() -> Mesh:
	var k := MeshKit.new()
	var cane := Color(0.62, 0.7, 0.44)
	var joint := Color(0.48, 0.56, 0.34)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		var base := Vector3(cos(a) * 0.1, 0, sin(a) * 0.1)
		var h := 1.0 + rng.randf() * 0.3
		var t := MeshKit.xf(base, Vector3(sin(a) * 5, 0, -cos(a) * 5))
		k.cyl(0.045, h, cane, t, 8, 0.01)
		var nj := int(h / 0.26)
		for j in nj:
			k.torus(0.046, 0.012, joint, t * MeshKit.at(0, 0.22 + j * 0.26, 0), 8, 4)
		# leaves at the top
		for l in 3:
			var la := TAU * l / 3.0 + a
			k.ellipsoid(Vector3(0.24, 0.015, 0.06), Pal.LEAF, t * MeshKit.xf(Vector3(cos(la) * 0.13, h - 0.02, sin(la) * 0.13), Vector3(0, -rad_to_deg(la), -30)), 8, 4)
	return k.commit()


static func cocoa() -> Mesh:
	var k := MeshKit.new()
	k.cyl(0.08, 0.75, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 8, 0.02, 0.06)
	var leaf := Color(0.32, 0.45, 0.29)
	k.sphere(0.42, leaf, MeshKit.at(0, 1.0, 0), 14, 9)
	k.sphere(0.28, leaf.lightened(0.12), MeshKit.at(0.26, 1.14, 0.12), 12, 8)
	k.sphere(0.26, leaf.darkened(0.08), MeshKit.at(-0.25, 0.92, -0.1), 12, 8)
	k.sphere(0.24, leaf.lightened(0.06), MeshKit.at(-0.08, 1.28, 0.16), 12, 8)
	for i in 5:
		var a := TAU * i / 5.0
		var p := Vector3(cos(a) * 0.32, 0.72 + (i % 2) * 0.12, sin(a) * 0.32)
		k.ellipsoid(Vector3(0.07, 0.12, 0.07), Color(0.72, 0.42, 0.24) if i % 2 == 0 else Color(0.82, 0.6, 0.3), MeshKit.at(p.x, p.y, p.z), 8, 6)
	return k.commit()


static func nest() -> Mesh:
	var k := MeshKit.new()
	var straw := Color(0.8, 0.68, 0.45)
	k.torus(0.2, 0.07, straw, MeshKit.at(0, 0.06, 0), 14, 6)
	k.cyl(0.18, 0.05, straw.darkened(0.12), MeshKit.at(0, 0.0, 0), 12)
	k.ellipsoid(Vector3(0.07, 0.09, 0.07), Color(1.0, 0.95, 0.84), MeshKit.at(-0.05, 0.1, 0.02), 10, 6)
	k.ellipsoid(Vector3(0.07, 0.09, 0.07), Color(0.98, 0.86, 0.7), MeshKit.at(0.06, 0.1, -0.03), 10, 6)
	return k.commit()


static func milk_can() -> Mesh:
	var k := MeshKit.new()
	var p := PackedVector2Array([Vector2(0, 0), Vector2(0.15, 0), Vector2(0.17, 0.04), Vector2(0.17, 0.32),
		Vector2(0.17, 0.32), Vector2(0.1, 0.42), Vector2(0.08, 0.5), Vector2(0.11, 0.53), Vector2(0, 0.55)])
	k.lathe(p, Pal.METAL, Transform3D.IDENTITY, 14)
	k.cyl(0.175, 0.07, Pal.SLATE, MeshKit.at(0, 0.16, 0), 14, 0.02)
	return k.commit()


static func trough() -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.9, 0.25, 0.4), 0.06, Pal.WOOD, MeshKit.at(0, 0.13, 0))
	k.rbox(Vector3(0.78, 0.04, 0.28), 0.02, Color(0.72, 0.66, 0.42), MeshKit.at(0, 0.26, 0))
	return k.commit()


static func coop(level: int) -> Mesh:
	var k := MeshKit.new()
	var wall := Color(0.92, 0.89, 0.82) if level < 2 else Color(0.86, 0.8, 0.7)
	var roof := Pal.TERRACOTTA
	k.rbox(Vector3(1.1, 0.75, 0.8), 0.08, wall, MeshKit.at(0, 0.45, 0))
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(0.68, 0.07, 0.95), 0.03, roof, MeshKit.xf(Vector3(sd * 0.27, 0.98, 0), Vector3(0, 0, -sd * 33)))
	k.rbox(Vector3(0.32, 0.36, 0.06), 0.1, Color(0.3, 0.18, 0.12), MeshKit.at(0, 0.3, 0.4))
	k.rbox(Vector3(0.34, 0.05, 0.4), 0.02, Pal.WOOD, MeshKit.xf(Vector3(0, 0.12, 0.55), Vector3(-25, 0, 0)))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.1, 0.12, 0.8), 0.03, Pal.WOOD_DARK, MeshKit.at(sx * 0.48, 0.06, 0))
	return k.commit()


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
			# tall Italian cypress
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


## The crop mesh for any farm ingredient.
static func crop(ing: String) -> Mesh:
	match ing:
		"wheat": return wheat()
		"sugar": return sugar()
		"cocoa": return cocoa()
		"egg": return nest()
		"milk": return milk_can()
		"oats": return oats()
		"berry": return berry()
		"hazelnut": return fruit_tree(Color(0.4, 0.52, 0.3), Color(0.62, 0.42, 0.24), 0.055, 0.85)
		"honey": return hive()
		"vanilla": return vanilla()
		"cinnamon": return cinnamon()
		"orange": return fruit_tree(Color(0.32, 0.5, 0.3), Color(0.95, 0.58, 0.2), 0.075, 1.0)
	return wheat()


static func oats() -> Mesh:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 23
	var stalk := Color(0.72, 0.7, 0.46)
	var grain := Color(0.9, 0.86, 0.66)
	for i in 8:
		var a := TAU * i / 8.0 + rng.randf() * 0.4
		var r := 0.05 + rng.randf() * 0.1
		var h := 0.5 + rng.randf() * 0.2
		var base := Vector3(cos(a) * r, 0, sin(a) * r)
		var t := MeshKit.xf(base, Vector3(sin(a) * 8, 0, -cos(a) * 8))
		k.cyl(0.015, h, stalk, t, 5)
		# drooping panicle: little grains hanging off the top
		for g in 5:
			var ga := TAU * g / 5.0
			k.ellipsoid(Vector3(0.022, 0.04, 0.022), grain, t * MeshKit.xf(Vector3(cos(ga) * 0.05, h - 0.02 - g * 0.035, sin(ga) * 0.05), Vector3(0, 0, 25)), 5, 3)
	k.ellipsoid(Vector3(0.2, 0.05, 0.2), Color(0.58, 0.58, 0.38), MeshKit.at(0, 0.02, 0), 10, 4)
	return k.commit()


static func berry() -> Mesh:
	var k := MeshKit.new()
	# a low strawberry plant on a straw bed
	k.ellipsoid(Vector3(0.3, 0.035, 0.26), Color(0.86, 0.76, 0.5), MeshKit.at(0, 0.01, 0), 10, 4)
	for i in 7:
		var a := TAU * i / 7.0
		k.ellipsoid(Vector3(0.12, 0.03, 0.08), Color(0.32, 0.5, 0.3) if i % 2 == 0 else Color(0.4, 0.56, 0.34),
			MeshKit.xf(Vector3(cos(a) * 0.12, 0.12, sin(a) * 0.12), Vector3(0, -rad_to_deg(a), -20)), 7, 3)
	k.sphere(0.1, Color(0.36, 0.52, 0.32), MeshKit.at(0, 0.12, 0), 8, 5)
	for i in 5:
		var a := TAU * i / 5.0 + 0.3
		var p := Vector3(cos(a) * 0.2, 0.06, sin(a) * 0.2)
		k.ellipsoid(Vector3(0.045, 0.055, 0.045), Color(0.86, 0.24, 0.24), MeshKit.xf(p, Vector3(170, 0, 0)), 7, 5)
		k.cone(0.03, 0.025, Pal.LEAF, MeshKit.at(p.x, p.y + 0.045, p.z), 5)
	return k.commit()


static func fruit_tree(leaf: Color, fruit: Color, fr: float, h: float) -> Mesh:
	var k := MeshKit.new()
	k.cyl(0.07, 0.7 * h, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 7, 0.02, 0.05)
	k.sphere(0.42, leaf, MeshKit.at(0, 0.95 * h, 0), 12, 8)
	k.sphere(0.3, leaf.lightened(0.1), MeshKit.at(0.24, 1.08 * h, 0.1), 10, 7)
	k.sphere(0.27, leaf.darkened(0.08), MeshKit.at(-0.24, 0.88 * h, -0.1), 10, 7)
	for i in 7:
		var a := TAU * i / 7.0 + 0.2
		k.sphere(fr, fruit if i % 3 != 0 else fruit.lightened(0.15), MeshKit.at(cos(a) * 0.38, 0.82 * h + (i % 3) * 0.12, sin(a) * 0.38), 7, 5)
	return k.commit()


static func hive() -> Mesh:
	var k := MeshKit.new()
	var wood := Color(0.94, 0.9, 0.8)
	k.rbox(Vector3(0.5, 0.08, 0.42), 0.02, Pal.WOOD_DARK, MeshKit.at(0, 0.18, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.05, 0.18, 0.05), 0.01, Pal.WOOD_DARK, MeshKit.at(sx * 0.2, 0.09, sz * 0.16))
	for i in 3:
		k.rbox(Vector3(0.44, 0.17, 0.38), 0.025, wood if i % 2 == 0 else wood.darkened(0.06), MeshKit.at(0, 0.31 + i * 0.17, 0))
	k.rbox(Vector3(0.5, 0.06, 0.44), 0.02, Pal.TERRACOTTA, MeshKit.at(0, 0.82, 0))
	k.rbox(Vector3(0.16, 0.03, 0.02), 0.01, Pal.CHOCO, MeshKit.at(0, 0.26, 0.19))
	return k.commit()


static func vanilla() -> Mesh:
	var k := MeshKit.new()
	# a vanilla orchid vine climbing a stake, pale flowers and pods
	k.rbox(Vector3(0.32, 0.12, 0.32), 0.04, Pal.TERRACOTTA, MeshKit.at(0, 0.06, 0))
	k.cyl(0.025, 1.0, Pal.WOOD, MeshKit.at(0, 0.1, 0), 5)
	for i in 6:
		var a := i * 1.3
		var y := 0.25 + i * 0.13
		k.ellipsoid(Vector3(0.1, 0.02, 0.05), Color(0.3, 0.5, 0.3), MeshKit.xf(Vector3(cos(a) * 0.08, y, sin(a) * 0.08), Vector3(0, -a * 57.3, -15)), 6, 3)
	for i in 3:
		var a2 := i * 2.1 + 0.5
		k.sphere(0.045, Color(0.96, 0.94, 0.82), MeshKit.at(cos(a2) * 0.12, 0.6 + i * 0.12, sin(a2) * 0.12), 6, 4)
		k.cyl(0.012, 0.16, Color(0.36, 0.42, 0.24), MeshKit.xf(Vector3(cos(a2) * 0.1, 0.42 + i * 0.1, sin(a2) * 0.1), Vector3(0, 0, 160)), 4)
	return k.commit()


static func cinnamon() -> Mesh:
	var k := MeshKit.new()
	var bark := Color(0.62, 0.34, 0.2)
	k.cyl(0.08, 0.8, bark, MeshKit.at(0, 0, 0), 7, 0.02, 0.06)
	k.cyl(0.04, 0.4, bark, MeshKit.xf(Vector3(0, 0.55, 0), Vector3(0, 0, 35)), 5)
	var leaf := Color(0.34, 0.5, 0.3)
	k.ellipsoid(Vector3(0.45, 0.32, 0.4), leaf, MeshKit.at(0, 1.05, 0), 12, 7)
	k.ellipsoid(Vector3(0.3, 0.22, 0.3), Color(0.62, 0.36, 0.26), MeshKit.at(0.2, 1.22, 0.1), 10, 6)
	k.ellipsoid(Vector3(0.28, 0.2, 0.28), leaf.lightened(0.1), MeshKit.at(-0.25, 0.95, -0.12), 10, 6)
	return k.commit()
