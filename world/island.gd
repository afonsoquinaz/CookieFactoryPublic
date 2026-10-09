class_name Island
## The island: grass top, sandy cliffs, the sea, paths, factory floors, the
## east pier and a ring of trees, bushes, rocks and flowers.

static func build(world: Node3D, region: Node3D) -> void:
	var mn := Lay.ISLAND_MIN
	var mx := Lay.ISLAND_MAX
	var size := mx - mn
	var center := (mn + mx) * 0.5
	# grass top
	var gk := MeshKit.new()
	gk.rbox(Vector3(size.x, 1.0, size.y), 0.45, Color(1, 1, 1), MeshKit.at(center.x, -0.5, center.y), 3)
	var grass := MeshInstance3D.new()
	grass.mesh = gk.commit()
	grass.material_override = Mats.ground()
	region.add_child(grass)
	# sandy cliff skirt + beach
	var ck := MeshKit.new()
	ck.rbox(Vector3(size.x + 1.6, 3.0, size.y + 1.6), 0.9, Pal.STONE_DARK, MeshKit.at(center.x, -1.75, center.y), 3)
	ck.rbox(Vector3(size.x + 0.7, 2.4, size.y + 0.7), 0.5, Pal.STONE, MeshKit.at(center.x, -1.3, center.y), 3)
	Mats.inst(ck.commit(), region, Transform3D.IDENTITY, false)
	# sea
	var sea := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(240, 240)
	pm.subdivide_width = 1
	pm.subdivide_depth = 1
	sea.mesh = pm
	var sm := ShaderMaterial.new()
	sm.shader = preload("res://render/sea.gdshader")
	sm.set_shader_parameter("island_min", mn - Vector2(1.1, 1.1))
	sm.set_shader_parameter("island_max", mx + Vector2(1.1, 1.1))
	sea.material_override = sm
	sea.position = Vector3(center.x, -0.75, center.y)
	sea.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(sea)
	# ground collider + invisible walls at the edge (navmesh is baked from these)
	var body := StaticBody3D.new()
	region.add_child(body)
	_box(body, Vector3(center.x, -0.5, center.y), Vector3(size.x, 1.0, size.y))
	for wall in [[Vector3(center.x, 1, mn.y - 0.2), Vector3(size.x, 2, 0.4)], [Vector3(center.x, 1, mx.y + 0.2), Vector3(size.x, 2, 0.4)],
			[Vector3(mn.x - 0.2, 1, center.y), Vector3(0.4, 2, size.y)], [Vector3(mx.x + 0.2, 1, center.y), Vector3(0.4, 2, size.y)]]:
		_box(body, wall[0], wall[1], false)
	# paths
	var pk := MeshKit.new()
	_path(pk, Vector3(0, 0, -8.0), Vector2(21.0, 2.0))          # in front of the farms
	_path(pk, Vector3(-12.2, 0, -1.5), Vector2(2.2, 16.0))      # west lane (pantry, cabin)
	_path(pk, Vector3(14.2, 0, 5.0), Vector2(2.4, 22.0))        # east lane (trays, shelf, docks)
	_path(pk, Vector3(0.0, 0, 16.6), Vector2(26.0, 1.8))        # south lane
	Mats.inst(pk.commit(), region, Transform3D.IDENTITY, false)
	# decorations around the edge
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var spots := []
	for i in 70:
		var side := rng.randi() % 4
		var p := Vector3.ZERO
		match side:
			0: p = Vector3(rng.randf_range(mn.x + 0.8, mx.x - 0.8), 0, rng.randf_range(mn.y + 0.5, mn.y + 2.0))
			1: p = Vector3(rng.randf_range(mn.x + 0.8, mx.x - 3.5), 0, rng.randf_range(mx.y - 1.2, mx.y - 0.4))
			2: p = Vector3(rng.randf_range(mn.x + 0.4, mn.x + 1.6), 0, rng.randf_range(mn.y + 1, mx.y - 1))
			3: p = Vector3(rng.randf_range(mx.x - 1.0, mx.x - 0.4), 0, rng.randf_range(mn.y + 1, -5.0))
		var ok := true
		for q in spots:
			if p.distance_to(q) < 1.3:
				ok = false
		if not ok:
			continue
		spots.append(p)
		var kind := rng.randi() % 5
		var mi := Mats.inst(MeshKit.cached("deco_%d" % kind, func(): return Crops.tree(kind)), region)
		mi.position = p
		mi.rotation.y = rng.randf() * TAU
		var s := rng.randf_range(0.85, 1.2)
		mi.scale = Vector3(s, s, s)
	scatter(region)
	# flower patches inside the island
	for i in 26:
		var p2 := Vector3(rng.randf_range(mn.x + 1, mx.x - 3), 0, rng.randf_range(mn.y + 1, mx.y - 1))
		if _blocked(p2):
			continue
		var mi2 := Mats.inst(MeshKit.cached("deco_4", func(): return Crops.tree(4)), region, Transform3D.IDENTITY, false)
		mi2.position = p2
		mi2.rotation.y = rng.randf() * TAU


## Grass tufts, daisies and pebbles over the open grass: three MultiMeshes,
## so hundreds of little details cost three draw calls.
static func scatter(region: Node3D) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var mn := Lay.ISLAND_MIN + Vector2(0.6, 0.6)
	var mx := Lay.ISLAND_MAX - Vector2(0.6, 0.6)
	var kinds := {
		"tuft": [420, func():
			var k := MeshKit.new()
			for i in 4:
				var a := TAU * i / 4.0 + 0.3
				k.cone(0.045, 0.22 + (i % 2) * 0.08, Color(0.4, 0.5, 0.3) if i % 2 == 0 else Color(0.5, 0.58, 0.36),
					MeshKit.xf(Vector3(cos(a) * 0.05, 0, sin(a) * 0.05), Vector3(sin(a) * 18, 0, cos(a) * 18)), 5)
			return k.commit()],
		"daisy": [90, func():
			var k := MeshKit.new()
			k.cyl(0.012, 0.14, Pal.LEAF_DARK, MeshKit.at(0, 0, 0), 4)
			for i in 5:
				var a := TAU * i / 5.0
				k.ellipsoid(Vector3(0.045, 0.012, 0.025), Color(1, 1, 1), MeshKit.xf(Vector3(cos(a) * 0.04, 0.15, sin(a) * 0.04), Vector3(0, -rad_to_deg(a), 0)), 5, 3)
			k.sphere(0.025, Color(1.0, 0.82, 0.25), MeshKit.at(0, 0.16, 0), 5, 3)
			return k.commit()],
		"pebble": [45, func():
			var k := MeshKit.new()
			k.ellipsoid(Vector3(0.12, 0.05, 0.09), Color(0.62, 0.6, 0.57), MeshKit.at(0, 0.0, 0), 6, 4)
			k.ellipsoid(Vector3(0.07, 0.035, 0.06), Color(0.55, 0.53, 0.5), MeshKit.at(0.13, 0.0, 0.05), 6, 3)
			return k.commit()],
	}
	for name in kinds:
		var n: int = kinds[name][0]
		var xs := []
		var tries := 0
		while xs.size() < n and tries < n * 20:
			tries += 1
			var p := Vector3(rng.randf_range(mn.x, mx.x), 0.0, rng.randf_range(mn.y, mx.y))
			if _on_path(p):
				continue
			var s := rng.randf_range(0.8, 1.4)
			xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), p))
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = MeshKit.cached("scatter_" + name, kinds[name][1])
		mm.instance_count = xs.size()
		for i in xs.size():
			mm.set_instance_transform(i, xs[i])
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Mats.toon()
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		region.add_child(mmi)


static func _on_path(p: Vector3) -> bool:
	var paths := [[Vector3(0, 0, -8.0), Vector2(21.0, 2.0)], [Vector3(-12.2, 0, -1.5), Vector2(2.2, 16.0)],
		[Vector3(14.2, 0, 5.0), Vector2(2.4, 22.0)], [Vector3(0.0, 0, 16.6), Vector2(26.0, 1.8)]]
	for q in paths:
		var c: Vector3 = q[0]
		var s: Vector2 = q[1]
		if absf(p.x - c.x) < s.x * 0.5 + 0.3 and absf(p.z - c.z) < s.y * 0.5 + 0.3:
			return true
	# farms, line floors and the pier area stay clean
	if p.z < -6.8 and p.z > -15.2 and absf(p.x) < 10.4:
		return true
	for i in 3:
		if absf(p.z - Lay.LINE_Z[i]) < 2.8 and p.x > Lay.TUBE_X0 - 1.0 and p.x < Lay.TRAY_X + 1.6:
			return true
	if p.x > 15.0:
		return true
	return false


## Keeps decorations off the busy areas.
static func _blocked(p: Vector3) -> bool:
	if p.z < -6.5 and p.z > -15.5 and absf(p.x) < 11.0:
		return true
	if p.z > -7.5 and p.z < 15.0 and p.x > -12.0 and p.x < 16.0:
		return true
	if p.x < -10.5 and p.z > -8.0 and p.z < 9.0:
		return true
	return false


static func _box(body: StaticBody3D, pos: Vector3, size: Vector3, _nav := true) -> void:
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	cs.position = pos
	body.add_child(cs)


static func _path(k: MeshKit, c: Vector3, s: Vector2) -> void:
	k.rbox(Vector3(s.x + 0.2, 0.06, s.y + 0.2), 0.03, Pal.PATH_EDGE, MeshKit.at(c.x, 0.0, c.z))
	k.rbox(Vector3(s.x, 0.07, s.y), 0.03, Pal.PATH, MeshKit.at(c.x, 0.012, c.z))


## Tiled floor under assembly line i.
static func factory_floor(region: Node3D, i: int) -> void:
	var z := Lay.LINE_Z[i]
	var mi := Mats.inst(MeshKit.cached("floor", func():
		var k := MeshKit.new()
		var x0 := Lay.TUBE_X0 - 0.8
		var x1 := Lay.TRAY_X + 1.2
		var cols := int((x1 - x0) / 2.0)
		k.rbox(Vector3(x1 - x0 + 0.3, 0.06, 5.0), 0.03, Color(0.6, 0.57, 0.53), MeshKit.at((x0 + x1) * 0.5, 0.0, 0.0))
		for cx in cols:
			for cz in 2:
				var c := Color(0.8, 0.77, 0.72) if (cx + cz) % 2 == 0 else Color(0.76, 0.73, 0.68)
				k.rbox(Vector3(1.86, 0.07, 2.26), 0.07, c, MeshKit.at(x0 + 1.0 + cx * 2.0 + 0.15, 0.025, -1.2 + cz * 2.4), 1)
		return k.commit()), region, Transform3D.IDENTITY, false)
	mi.position = Vector3(0, 0, z)


## Wooden pier + road east of dock i.
static func pier(region: Node3D, i: int) -> void:
	var z := Lay.DOCK_Z[i]
	var mi := Mats.inst(MeshKit.cached("pier", func():
		var k := MeshKit.new()
		var x0 := Lay.ISLAND_MAX.x - 1.2
		for p in 30:
			var c := Pal.WOOD if p % 2 == 0 else Pal.WOOD_LIGHT
			k.rbox(Vector3(0.62, 0.12, 3.0), 0.04, c, MeshKit.at(x0 + p * 0.64, 0.02, 0), 1)
		for p in 9:
			for sz in [-1.0, 1.0]:
				k.cyl(0.14, 1.6, Pal.WOOD_DARK, MeshKit.at(x0 + 0.5 + p * 2.2, -1.5, sz * 1.45), 8, 0.03)
		# striped bumper + lamp
		k.rbox(Vector3(0.24, 0.42, 2.6), 0.04, Pal.WOOD_DARK, MeshKit.at(x0 + 0.6, 0.21, 0))
		k.cyl(0.06, 2.2, Pal.METAL_DARK, MeshKit.at(x0 + 0.2, 0, 1.75), 8)
		k.sphere(0.2, Color(1.0, 0.95, 0.7, 0.3), MeshKit.at(x0 + 0.2, 2.3, 1.75), 10, 7)
		return k.commit()), region, Transform3D.IDENTITY, false)
	mi.position = Vector3(0, 0, z)
