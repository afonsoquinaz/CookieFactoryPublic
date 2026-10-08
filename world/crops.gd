class_name Crops
## Meshes for farm crops, nests, coops and props.

static func wheat() -> Mesh:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var stalk := Color(0.95, 0.74, 0.3)
	var ear := Color(1.0, 0.84, 0.36)
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf() * 0.4
		var r := 0.06 + rng.randf() * 0.1
		var h := 0.55 + rng.randf() * 0.2
		var lean := Vector3(cos(a) * 9, 0, sin(a) * 9)
		var base := Vector3(cos(a) * r, 0, sin(a) * r)
		var t := MeshKit.xf(base, Vector3(lean.z, 0, -lean.x))
		k.cyl(0.018, h, stalk, t, 5)
		k.ellipsoid(Vector3(0.045, 0.12, 0.045), ear, t * MeshKit.at(0, h + 0.07, 0), 8, 6)
	k.ellipsoid(Vector3(0.2, 0.06, 0.2), Pal.LEAF, MeshKit.at(0, 0.02, 0), 10, 4)
	return k.commit()


static func sugar() -> Mesh:
	var k := MeshKit.new()
	var cane := Color(0.62, 0.86, 0.36)
	var joint := Color(0.46, 0.7, 0.28)
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
	var leaf := Color(0.3, 0.7, 0.32)
	k.sphere(0.42, leaf, MeshKit.at(0, 1.0, 0), 14, 9)
	k.sphere(0.28, leaf.lightened(0.12), MeshKit.at(0.26, 1.14, 0.12), 12, 8)
	k.sphere(0.26, leaf.darkened(0.08), MeshKit.at(-0.25, 0.92, -0.1), 12, 8)
	k.sphere(0.24, leaf.lightened(0.06), MeshKit.at(-0.08, 1.28, 0.16), 12, 8)
	for i in 5:
		var a := TAU * i / 5.0
		var p := Vector3(cos(a) * 0.32, 0.72 + (i % 2) * 0.12, sin(a) * 0.32)
		k.ellipsoid(Vector3(0.07, 0.12, 0.07), Color(0.95, 0.55, 0.18) if i % 2 == 0 else Color(0.98, 0.72, 0.2), MeshKit.at(p.x, p.y, p.z), 8, 6)
	return k.commit()


static func nest() -> Mesh:
	var k := MeshKit.new()
	var straw := Color(0.95, 0.78, 0.4)
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
	k.cyl(0.175, 0.07, Color(0.38, 0.62, 0.98), MeshKit.at(0, 0.16, 0), 14, 0.02)
	return k.commit()


static func trough() -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.9, 0.25, 0.4), 0.06, Pal.WOOD, MeshKit.at(0, 0.13, 0))
	k.rbox(Vector3(0.78, 0.04, 0.28), 0.02, Color(0.82, 0.88, 0.45), MeshKit.at(0, 0.26, 0))
	return k.commit()


static func coop(level: int) -> Mesh:
	var k := MeshKit.new()
	var wall := Color(0.95, 0.38, 0.35) if level < 2 else Color(0.98, 0.62, 0.4)
	var roof := Color(0.98, 0.95, 0.88)
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
			# round puffy tree
			k.cyl(0.12, 0.8, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 8, 0.03, 0.09)
			k.sphere(0.65, Color(0.36, 0.72, 0.3), MeshKit.at(0, 1.25, 0), 14, 9)
			k.sphere(0.45, Color(0.44, 0.8, 0.34), MeshKit.at(0.32, 1.5, 0.2), 12, 8)
			k.sphere(0.4, Color(0.3, 0.64, 0.28), MeshKit.at(-0.35, 1.1, -0.15), 12, 8)
		1:
			# stacked cone pine
			k.cyl(0.1, 0.5, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 8, 0.03)
			for i in 3:
				var r := 0.7 - i * 0.18
				k.cyl(r, 0.65, Color(0.24, 0.62, 0.4).lightened(i * 0.06), MeshKit.at(0, 0.4 + i * 0.45, 0), 12, 0.08, 0.06)
		2:
			# bush
			k.sphere(0.42, Color(0.38, 0.74, 0.32), MeshKit.at(0, 0.3, 0), 12, 8)
			k.sphere(0.32, Color(0.46, 0.82, 0.36), MeshKit.at(0.3, 0.25, 0.1), 10, 7)
			k.sphere(0.28, Color(0.34, 0.68, 0.3), MeshKit.at(-0.28, 0.22, -0.05), 10, 7)
			for i in 4:
				var a := TAU * i / 4.0
				k.sphere(0.05, [Pal.PINK, Pal.WHITE, Pal.YELLOW, Pal.PINK][i], MeshKit.at(cos(a) * 0.35, 0.45 + (i % 2) * 0.1, sin(a) * 0.3 + 0.12), 6, 4)
		3:
			# rock
			k.ellipsoid(Vector3(0.5, 0.32, 0.42), Color(0.78, 0.78, 0.84), MeshKit.xf(Vector3(0, 0.15, 0), Vector3(0, 20, 8)), 9, 6)
			k.ellipsoid(Vector3(0.28, 0.2, 0.26), Color(0.7, 0.71, 0.78), MeshKit.at(0.42, 0.08, 0.15), 8, 5)
		4:
			# flowers
			for i in 5:
				var a := TAU * i / 5.0
				var p := Vector3(cos(a) * 0.22, 0, sin(a) * 0.2)
				k.cyl(0.012, 0.2, Pal.LEAF_DARK, MeshKit.at(p.x, 0, p.z), 4)
				k.sphere(0.06, [Pal.PINK, Pal.YELLOW, Pal.WHITE, Color(0.7, 0.6, 1.0), Pal.ORANGE][i], MeshKit.at(p.x, 0.22, p.z), 8, 5)
	return k.commit()
