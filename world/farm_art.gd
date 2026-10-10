class_name FarmArt
## Farm looks per upgrade tier (0..4):
##   0  split-rail fence, plain soil
##   1  dry-stone wall, furrowed beds, gate lanterns
##   2  stone wall with a timber rail, a scarecrow or a feeder, a tool shed
##   3  whitewashed wall with terracotta coping, a water tower, irrigation
##   4  brick wall with brass caps, a windmill and a brass arch over the gate

const GATE := 1.3


## How many crops and in how many columns.
static func crop_layout(ing: String, t: int) -> Array:
	match ing:
		"wheat", "sugar", "oats":
			return [[9, 12, 12, 16, 16][t], [3, 4, 4, 4, 4][t]]
		"berry":
			return [[6, 8, 9, 12, 12][t], [3, 4, 3, 4, 4][t]]
		"egg":
			return [[3, 4, 5, 6, 6][t], [3, 4, 5, 3, 3][t]]
		"milk":
			return [[2, 3, 4, 4, 5][t], [2, 3, 4, 4, 5][t]]
		"honey":
			return [[3, 4, 5, 6, 8][t], [3, 4, 5, 3, 4][t]]
		"vanilla":
			return [[4, 6, 6, 8, 8][t], [4, 3, 3, 4, 4][t]]
	# trees
	return [[3, 4, 5, 6, 6][t], [3, 4, 5, 3, 3][t]]


static func bed(ing: String, w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var col := Pal.SOIL
	match ing:
		"egg": col = Color(0.78, 0.7, 0.55)
		"milk": col = Color(0.5, 0.6, 0.38)
		"honey": col = Color(0.56, 0.64, 0.4)
		"cocoa", "hazelnut", "orange", "cinnamon": col = Color(0.44, 0.52, 0.32)
		"vanilla": col = Color(0.62, 0.6, 0.56)
	k.rbox(Vector3(w, 0.14, d), 0.07, col, MeshKit.at(0, 0.0, 0))
	if ing in ["wheat", "sugar", "oats", "berry"] and t >= 1:
		for r in 4:
			k.rbox(Vector3(w - 0.5, 0.08, 0.45), 0.04, col.darkened(0.1), MeshKit.at(0, 0.07, -d * 0.5 + 0.65 + r * (d - 1.2) / 3.0))
	if t >= 2:
		# edging boards
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(w - 0.2, 0.06, 0.08), 0.02, Pal.WOOD, MeshKit.at(0, 0.09, sz * (d * 0.5 - 0.12)))
	if t >= 3:
		# irrigation channel along the back with water
		k.rbox(Vector3(w - 0.4, 0.05, 0.22), 0.02, Pal.STONE_DARK, MeshKit.at(0, 0.09, -d * 0.5 + 0.2))
		k.rbox(Vector3(w - 0.5, 0.02, 0.14), 0.01, Color(0.42, 0.62, 0.68, 0.8), MeshKit.at(0, 0.12, -d * 0.5 + 0.2))
	if ing == "honey":
		for i in 14:
			var a := i * 2.4
			var p := Vector3(cos(a) * (0.6 + i * 0.12), 0.08, sin(a) * 0.8)
			k.sphere(0.05, [Color(0.95, 0.85, 0.4), Color(0.85, 0.6, 0.75), Color(0.98, 0.98, 0.95)][i % 3], MeshKit.at(clampf(p.x, -w * 0.45, w * 0.45), 0.12, p.z), 5, 3)
	return k.commit()


static func wall(w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = 99 + t
	var edges := [[Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5)],
		[Vector2(w * 0.5, -d * 0.5), Vector2(w * 0.5, d * 0.5)],
		[Vector2(-w * 0.5, d * 0.5), Vector2(-w * 0.5, -d * 0.5)],
		[Vector2(w * 0.5, d * 0.5), Vector2(GATE * 0.5, d * 0.5)],
		[Vector2(-GATE * 0.5, d * 0.5), Vector2(-w * 0.5, d * 0.5)]]
	var h: float = [0.0, 0.32, 0.34, 0.4, 0.46][t]
	for e in edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var len := a.distance_to(b)
		var dir := (b - a).normalized()
		var ang := rad_to_deg(atan2(dir.y, dir.x))
		var mid := (a + b) * 0.5
		match t:
			0:
				# split-rail wooden fence
				var n := maxi(1, int(round(len / 1.0)))
				for i in n + 1:
					var q := a.lerp(b, float(i) / n)
					k.rbox(Vector3(0.08, 0.5, 0.08), 0.02, Pal.WOOD_DARK, MeshKit.at(q.x, 0.25, q.y))
				for y in [0.2, 0.4]:
					k.rbox(Vector3(len, 0.05, 0.05), 0.02, Pal.WOOD, MeshKit.xf(Vector3(mid.x, y, mid.y), Vector3(0, -ang, 0)))
			1, 2:
				for course in 2:
					var tt := 0.0 if course == 0 else 0.17
					while tt < len - 0.05:
						var sl := minf(rng.randf_range(0.26, 0.42), len - tt)
						var p := a + dir * (tt + sl * 0.5)
						var tone := Pal.STONE.lerp(Pal.STONE_DARK, rng.randf() * 0.6)
						k.rbox(Vector3(sl - 0.03, h * 0.5, 0.26), 0.05, tone, MeshKit.xf(Vector3(p.x, h * 0.25 + course * h * 0.5, p.y), Vector3(0, -ang + rng.randf_range(-3, 3), 0)))
						tt += sl
				if t == 2:
					k.rbox(Vector3(len, 0.06, 0.08), 0.02, Pal.WOOD, MeshKit.xf(Vector3(mid.x, h + 0.28, mid.y), Vector3(0, -ang, 0)))
					var n2 := maxi(1, int(round(len / 1.1)))
					for i in n2 + 1:
						var q2 := a.lerp(b, float(i) / n2)
						k.rbox(Vector3(0.07, 0.34, 0.07), 0.02, Pal.WOOD_DARK, MeshKit.at(q2.x, h + 0.14, q2.y))
			3:
				k.rbox(Vector3(len, h, 0.24), 0.05, Color(0.93, 0.91, 0.86), MeshKit.xf(Vector3(mid.x, h * 0.5, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len + 0.04, 0.07, 0.3), 0.03, Pal.TERRACOTTA, MeshKit.xf(Vector3(mid.x, h + 0.03, mid.y), Vector3(0, -ang, 0)))
			4:
				# brick courses
				for course in 4:
					var tt2 := 0.0 if course % 2 == 0 else 0.12
					while tt2 < len - 0.05:
						var sl2 := minf(0.24, len - tt2)
						var p2 := a + dir * (tt2 + sl2 * 0.5)
						var c := Pal.BRICK if (int(tt2 * 10) + course) % 3 != 0 else Pal.BRICK_DARK
						k.rbox(Vector3(sl2 - 0.02, h / 4.0 - 0.015, 0.24), 0.015, c, MeshKit.xf(Vector3(p2.x, h / 8.0 + course * h / 4.0, p2.y), Vector3(0, -ang, 0)))
						tt2 += sl2
				k.rbox(Vector3(len + 0.04, 0.06, 0.3), 0.02, Pal.STONE, MeshKit.xf(Vector3(mid.x, h + 0.03, mid.y), Vector3(0, -ang, 0)))
				var n3 := maxi(1, int(round(len / 1.4)))
				for i in n3 + 1:
					var q3 := a.lerp(b, float(i) / n3)
					k.rbox(Vector3(0.22, h + 0.12, 0.3), 0.03, Pal.BRICK_DARK, MeshKit.at(q3.x, (h + 0.12) * 0.5, q3.y))
					k.sphere(0.07, Pal.BRASS, MeshKit.at(q3.x, h + 0.19, q3.y), 8, 5)
	# gate posts
	var ph := maxf(0.5, h + 0.32)
	for sx in [-1.0, 1.0]:
		var gp := Vector3(sx * GATE * 0.5, 0, d * 0.5)
		var pc := Pal.WOOD_DARK if t == 0 else (Pal.BRICK_DARK if t == 4 else Pal.STONE_DARK)
		k.rbox(Vector3(0.18, ph, 0.18), 0.03, pc, MeshKit.at(gp.x, ph * 0.5, gp.z))
		if t >= 1:
			k.cyl(0.02, 0.25, Pal.STEEL_DARK, MeshKit.at(gp.x, ph, gp.z), 6)
			k.rbox(Vector3(0.1, 0.13, 0.1), 0.02, Color(1.0, 0.86, 0.6, 0.4), MeshKit.at(gp.x, ph + 0.3, gp.z))
	if t >= 4:
		# a brass arch over the gate
		k.torus(GATE * 0.5, 0.035, Pal.BRASS, MeshKit.xf(Vector3(0, ph + 0.05, d * 0.5), Vector3(0, 0, 0), Vector3(1, 0.6, 1)), 16, 5, PI)
	return k.commit()


## Props that make a farm read richer as it levels up.
static func extras(ing: String, w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var back := -d * 0.5
	var field: bool = ing in ["wheat", "sugar", "oats", "berry"]
	if ing == "egg":
		_coop(k, Vector3(w * 0.5 - 0.85, 0.07, back + 0.65), t)
	if ing == "milk":
		_barn(k, Vector3(w * 0.5 - 0.95, 0.07, back + 0.7), t)
		k.add_mesh(MeshKit.cached("trough", Crops.trough), MeshKit.at(-w * 0.5 + 0.8, 0.07, back + 0.5))
	if ing == "vanilla":
		_glasshouse(k, w - 0.4, d - 0.4, t)
	if t >= 1:
		# a barrel and a sack by the gate
		k.cyl(0.18, 0.4, Pal.WOOD, MeshKit.at(-GATE * 0.5 - 0.45, 0.07, d * 0.5 - 0.35), 10, 0.04)
		k.torus(0.18, 0.02, Pal.STEEL_DARK, MeshKit.at(-GATE * 0.5 - 0.45, 0.32, d * 0.5 - 0.35), 10, 3)
	if t >= 2:
		if field:
			_scarecrow(k, Vector3(0.0, 0.07, back + d * 0.45))
		elif not ing in ["egg", "milk", "vanilla"]:
			# a ladder against a tree, a basket of harvest
			k.rbox(Vector3(0.4, 0.22, 0.3), 0.05, Color(0.78, 0.62, 0.4), MeshKit.at(GATE * 0.5 + 0.5, 0.18, d * 0.5 - 0.35))
	if t >= 3:
		# a wooden water tower in the back-left corner
		var p := Vector3(-w * 0.5 + 0.35, 0, back + 0.35)
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 1.3, 0.06), 0.015, Pal.WOOD_DARK, MeshKit.at(p.x + sx * 0.22, 0.65, p.z + sz * 0.22))
		k.cyl(0.36, 0.55, Pal.WOOD, MeshKit.at(p.x, 1.3, p.z), 12, 0.03)
		for y in [1.4, 1.7]:
			k.torus(0.365, 0.02, Pal.STEEL_DARK, MeshKit.at(p.x, y, p.z), 12, 3)
		k.cone(0.42, 0.3, Pal.TERRACOTTA, MeshKit.at(p.x, 1.85, p.z), 12)
	if t >= 4:
		# a little windmill in the back-right corner
		var q := Vector3(w * 0.5 - 0.35, 0, back + 0.35)
		if ing in ["egg", "milk"]:
			q = Vector3(-w * 0.5 + 1.25, 0, back + 0.35)
		k.cyl(0.32, 1.7, Color(0.94, 0.92, 0.86), MeshKit.at(q.x, 0, q.z), 10, 0.03, 0.22)
		k.cone(0.34, 0.4, Pal.TERRACOTTA, MeshKit.at(q.x, 1.7, q.z), 10)
		for i in 4:
			k.rbox(Vector3(0.12, 0.9, 0.02), 0.01, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(q.x, 1.55, q.z + 0.3), Vector3(0, 0, 45 + i * 90)) * MeshKit.at(0, 0.45, 0))
		k.sphere(0.06, Pal.BRASS, MeshKit.at(q.x, 1.55, q.z + 0.32), 6, 4)
	return k.commit()


static func _scarecrow(k: MeshKit, p: Vector3) -> void:
	k.cyl(0.03, 1.1, Pal.WOOD_DARK, MeshKit.at(p.x, p.y, p.z), 5)
	k.rbox(Vector3(0.7, 0.05, 0.05), 0.02, Pal.WOOD_DARK, MeshKit.at(p.x, p.y + 0.8, p.z))
	k.rbox(Vector3(0.36, 0.38, 0.16), 0.06, Color(0.62, 0.36, 0.3), MeshKit.at(p.x, p.y + 0.72, p.z))
	k.sphere(0.14, Color(0.9, 0.84, 0.66), MeshKit.at(p.x, p.y + 1.05, p.z), 8, 6)
	k.cyl(0.24, 0.03, Color(0.86, 0.74, 0.46), MeshKit.at(p.x, p.y + 1.13, p.z), 10)
	k.cyl(0.12, 0.12, Color(0.86, 0.74, 0.46), MeshKit.at(p.x, p.y + 1.14, p.z), 8)


static func _coop(k: MeshKit, p: Vector3, t: int) -> void:
	var wall := Color(0.92, 0.89, 0.82) if t < 3 else Color(0.86, 0.8, 0.7)
	var s := 1.0 + t * 0.08
	k.rbox(Vector3(1.1, 0.75, 0.8) * s, 0.08, wall, MeshKit.at(p.x, p.y + 0.4 * s, p.z))
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(0.68, 0.07, 0.95) * s, 0.03, Pal.TERRACOTTA, MeshKit.xf(Vector3(p.x + sd * 0.27 * s, p.y + 0.95 * s, p.z), Vector3(0, 0, -sd * 33)))
	k.rbox(Vector3(0.32, 0.36, 0.06), 0.1, Color(0.3, 0.18, 0.12), MeshKit.at(p.x, p.y + 0.25, p.z + 0.4 * s))
	k.rbox(Vector3(0.34, 0.05, 0.4), 0.02, Pal.WOOD, MeshKit.xf(Vector3(p.x, p.y + 0.1, p.z + 0.55 * s), Vector3(-25, 0, 0)))
	if t >= 2:
		k.rbox(Vector3(0.2, 0.2, 0.04), 0.03, Color(0.7, 0.8, 0.85, 0.7), MeshKit.at(p.x + 0.35 * s, p.y + 0.55 * s, p.z + 0.41 * s))


static func _barn(k: MeshKit, p: Vector3, t: int) -> void:
	var red := Color(0.62, 0.3, 0.26) if t < 3 else Color(0.56, 0.26, 0.22)
	k.rbox(Vector3(1.3, 0.9, 1.0), 0.06, red, MeshKit.at(p.x, p.y + 0.45, p.z))
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(0.8, 0.07, 1.1), 0.03, Pal.STEEL_DARK, MeshKit.xf(Vector3(p.x + sd * 0.32, p.y + 1.08, p.z), Vector3(0, 0, -sd * 35)))
	k.rbox(Vector3(0.5, 0.6, 0.04), 0.03, Pal.CREAM, MeshKit.at(p.x, p.y + 0.3, p.z + 0.5))
	k.rbox(Vector3(0.5, 0.04, 0.05), 0.01, Pal.CREAM, MeshKit.xf(Vector3(p.x, p.y + 0.3, p.z + 0.53), Vector3(0, 0, 50)))
	if t >= 2:
		k.cyl(0.25, 1.4, Color(0.8, 0.8, 0.78), MeshKit.at(p.x - 0.85, p.y, p.z - 0.2), 10, 0.02)
		k.sphere(0.25, Pal.STEEL, MeshKit.at(p.x - 0.85, p.y + 1.4, p.z - 0.2), 10, 5)


static func _glasshouse(k: MeshKit, w: float, d: float, t: int) -> void:
	var frame := Pal.WOOD_DARK if t < 3 else Color(0.94, 0.94, 0.92)
	var h := 1.3 + t * 0.12
	var nx := 5
	for i in nx + 1:
		var x := -w * 0.5 + w * i / nx
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.05, h, 0.05), 0.01, frame, MeshKit.at(x, h * 0.5, sz * d * 0.5))
		k.rbox(Vector3(0.05, 0.05, d * 0.56), 0.01, frame, MeshKit.xf(Vector3(x, h + 0.25, -d * 0.25), Vector3(-25, 0, 0)))
		k.rbox(Vector3(0.05, 0.05, d * 0.56), 0.01, frame, MeshKit.xf(Vector3(x, h + 0.25, d * 0.25), Vector3(25, 0, 0)))
	k.rbox(Vector3(w, 0.05, 0.05), 0.01, frame, MeshKit.at(0, h + 0.5, 0))


## The glasshouse roof panes (drawn with the glass material).
static func glass_roof(w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var h := 1.3 + t * 0.12
	k.rbox(Vector3(w, 0.02, d * 0.56), 0.005, Color(1, 1, 1), MeshKit.xf(Vector3(0, h + 0.25, -d * 0.25), Vector3(-25, 0, 0)))
	k.rbox(Vector3(w, 0.02, d * 0.56), 0.005, Color(1, 1, 1), MeshKit.xf(Vector3(0, h + 0.25, d * 0.25), Vector3(25, 0, 0)))
	return k.commit()
