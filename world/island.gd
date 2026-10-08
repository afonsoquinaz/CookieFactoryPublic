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
	ck.rbox(Vector3(size.x + 2.2, 3.0, size.y + 2.2), 1.4, Color(0.98, 0.86, 0.62), MeshKit.at(center.x, -1.9, center.y), 3)
	ck.rbox(Vector3(size.x + 0.9, 2.4, size.y + 0.9), 0.8, Color(0.86, 0.68, 0.5), MeshKit.at(center.x, -1.4, center.y), 3)
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
	# flower patches inside the island
	for i in 26:
		var p2 := Vector3(rng.randf_range(mn.x + 1, mx.x - 3), 0, rng.randf_range(mn.y + 1, mx.y - 1))
		if _blocked(p2):
			continue
		var mi2 := Mats.inst(MeshKit.cached("deco_4", func(): return Crops.tree(4)), region, Transform3D.IDENTITY, false)
		mi2.position = p2
		mi2.rotation.y = rng.randf() * TAU


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
		var cols := int((x1 - x0) / 1.0)
		k.rbox(Vector3(x1 - x0 + 0.3, 0.06, 5.0), 0.03, Color(0.8, 0.76, 0.9), MeshKit.at((x0 + x1) * 0.5, 0.0, 0.0))
		for cx in cols:
			for cz in 4:
				var c := Color(0.95, 0.93, 0.98) if (cx + cz) % 2 == 0 else Color(0.9, 0.88, 0.97)
				k.rbox(Vector3(0.94, 0.06, 1.14), 0.05, c, MeshKit.at(x0 + 0.5 + cx * 1.0 + 0.15, 0.02, -1.8 + cz * 1.2), 1)
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
		k.rbox(Vector3(0.3, 0.5, 2.6), 0.1, Color(1.0, 0.85, 0.3), MeshKit.at(x0 + 0.6, 0.25, 0))
		k.cyl(0.06, 2.2, Pal.METAL_DARK, MeshKit.at(x0 + 0.2, 0, 1.75), 8)
		k.sphere(0.2, Color(1.0, 0.95, 0.7, 0.3), MeshKit.at(x0 + 0.2, 2.3, 1.75), 10, 7)
		return k.commit()), region, Transform3D.IDENTITY, false)
	mi.position = Vector3(0, 0, z)
