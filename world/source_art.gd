class_name SourceArt
## Source looks per upgrade tier (0..4):
##   0  a garage-startup lot: gravel, a low timber fence, a hand-painted sign
##   1  chain-link fence on steel posts, gate lights
##   2  a low concrete wall with a hazard-striped gate, a control box
##   3  white panel walls with a teal band, LED gate posts, a utility shed
##   4  glass and steel with brass caps, a glowing arch over the gate
## plus each source's own props (an inverter for the solar farm, a mast for
## the crawler, a cooling tower, a conveyor for the mine...).

const GATE := 1.3


## How many stations a source has at level l: three to start, one more
## every other level until the lot is full (the papers lot has big ones).
static func station_count(res: String, l: int) -> int:
	match res:
		"power": return clampi(3 + (l - 1) / 2, 3, 8)
		"papers": return clampi(2 + (l - 1) / 3, 2, 4)
	return clampi(3 + (l - 1) / 2, 3, 6)


## Where the stations stand (local to the lot's frame, like SourceB): one
## row of up to three, then two rows.
static func station_spots(res: String, l: int, w: float, d: float, cz: float) -> Array[Vector3]:
	var count := station_count(res, l)
	var cols := count if count <= 3 else (count + 1) / 2
	var rows := int(ceil(float(count) / cols))
	var area := Vector2(w - 1.0, d - 1.1)
	var out: Array[Vector3] = []
	for i in count:
		var cx: int = i % cols
		var r: int = i / cols
		var in_row := cols if r < rows - 1 else count - cols * (rows - 1)
		var x := -area.x * 0.5 + area.x * (cx + 0.5) / cols
		if in_row < cols:
			# a shorter last row sits centred
			x = -area.x * 0.5 + area.x * (cx + 0.5 + (cols - in_row) * 0.5) / cols
		var z := cz - area.y * 0.5 + area.y * (r + 0.5) / rows - 0.15
		out.append(Vector3(x, 0.07, z))
	return out


## The ground of the lot.
static func bed(res: String, w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var col := Color(0.62, 0.6, 0.56)         # gravel
	match res:
		"code", "labels", "feedback", "experts", "papers":
			col = [Color(0.66, 0.6, 0.52), Color(0.72, 0.7, 0.66), Color(0.78, 0.76, 0.72), Color(0.84, 0.84, 0.82), Color(0.9, 0.88, 0.84)][t]
		"copper", "rare":
			col = Color(0.56, 0.48, 0.4)
		"power":
			col = Color(0.62, 0.62, 0.6)
	col = col.lerp(Defs.ITEMS[res]["color"], 0.12)
	k.rbox(Vector3(w, 0.14, d), 0.07, col, MeshKit.at(0, 0.0, 0))
	if res in ["code", "labels", "feedback", "experts", "papers"] and t >= 1:
		# a floor of tiles under the desks
		var nx := int(w / 0.9)
		var nz := int(d / 0.9)
		for i in nx:
			for j in nz:
				if (i + j) % 2 == 0:
					k.rbox(Vector3(0.86, 0.02, 0.86), 0.02, col.darkened(0.06), MeshKit.at(-w * 0.5 + 0.45 + i * w / nx, 0.075, -d * 0.5 + 0.45 + j * d / nz))
	elif t >= 1:
		# gravel paths between the stations
		for r in 2:
			k.rbox(Vector3(w - 0.5, 0.04, 0.32), 0.02, col.lightened(0.08), MeshKit.at(0, 0.07, -d * 0.5 + 1.0 + r * (d - 1.6)))
	if t >= 2:
		# kerbs
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(w - 0.2, 0.06, 0.08), 0.02, Pal.STONE_DARK, MeshKit.at(0, 0.09, sz * (d * 0.5 - 0.12)))
	if t >= 3:
		# a cable trench along the back, lit
		k.rbox(Vector3(w - 0.4, 0.05, 0.22), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 0.09, -d * 0.5 + 0.2))
		k.rbox(Vector3(w - 0.5, 0.02, 0.05), 0.01, Items.lit(Color(0.36, 0.86, 0.86), 0.5), MeshKit.at(0, 0.12, -d * 0.5 + 0.2))
	return k.commit()


static func wall(w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var edges := [[Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5)],
		[Vector2(w * 0.5, -d * 0.5), Vector2(w * 0.5, d * 0.5)],
		[Vector2(-w * 0.5, d * 0.5), Vector2(-w * 0.5, -d * 0.5)],
		[Vector2(w * 0.5, d * 0.5), Vector2(GATE * 0.5, d * 0.5)],
		[Vector2(-GATE * 0.5, d * 0.5), Vector2(-w * 0.5, d * 0.5)]]
	var h: float = [0.0, 0.0, 0.34, 0.42, 0.46][t]
	for e in edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var len := a.distance_to(b)
		var dir := (b - a).normalized()
		var ang := rad_to_deg(atan2(dir.y, dir.x))
		var mid := (a + b) * 0.5
		match t:
			0:
				# a low timber fence
				var n := maxi(1, int(round(len / 1.0)))
				for i in n + 1:
					var q := a.lerp(b, float(i) / n)
					k.rbox(Vector3(0.08, 0.45, 0.08), 0.02, Pal.WOOD_DARK, MeshKit.at(q.x, 0.22, q.y))
				k.rbox(Vector3(len, 0.05, 0.05), 0.02, Pal.WOOD, MeshKit.xf(Vector3(mid.x, 0.34, mid.y), Vector3(0, -ang, 0)))
			1:
				# chain-link: steel posts and a see-through mesh band
				var n1 := maxi(1, int(round(len / 1.1)))
				for i in n1 + 1:
					var q1 := a.lerp(b, float(i) / n1)
					k.cyl(0.035, 0.7, Color(0.62, 0.64, 0.66), MeshKit.at(q1.x, 0.0, q1.y), 6)
				k.rbox(Vector3(len, 0.03, 0.03), 0.01, Color(0.62, 0.64, 0.66), MeshKit.xf(Vector3(mid.x, 0.68, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len, 0.5, 0.012), 0.004, Color(0.72, 0.76, 0.78, 0.92), MeshKit.xf(Vector3(mid.x, 0.38, mid.y), Vector3(0, -ang, 0)))
				for i in int(len / 0.18):
					var q2 := a + dir * (i * 0.18 + 0.09)
					k.rbox(Vector3(0.01, 0.48, 0.014), 0.003, Color(0.56, 0.58, 0.6), MeshKit.xf(Vector3(q2.x, 0.38, q2.y), Vector3(0, -ang, 30)))
			2:
				k.rbox(Vector3(len, h, 0.22), 0.04, Color(0.74, 0.74, 0.72), MeshKit.xf(Vector3(mid.x, h * 0.5, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len + 0.02, 0.05, 0.26), 0.02, Color(0.64, 0.64, 0.62), MeshKit.xf(Vector3(mid.x, h + 0.02, mid.y), Vector3(0, -ang, 0)))
			3:
				k.rbox(Vector3(len, h, 0.22), 0.05, Color(0.94, 0.95, 0.96), MeshKit.xf(Vector3(mid.x, h * 0.5, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len + 0.01, 0.07, 0.235), 0.02, Color(0.3, 0.66, 0.68), MeshKit.xf(Vector3(mid.x, h * 0.62, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len + 0.04, 0.05, 0.28), 0.02, Color(0.82, 0.84, 0.86), MeshKit.xf(Vector3(mid.x, h + 0.02, mid.y), Vector3(0, -ang, 0)))
			4:
				k.rbox(Vector3(len, 0.2, 0.24), 0.04, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(mid.x, 0.1, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len, 0.34, 0.04), 0.01, Color(0.7, 0.86, 0.92, 0.85), MeshKit.xf(Vector3(mid.x, 0.37, mid.y), Vector3(0, -ang, 0)))
				k.rbox(Vector3(len + 0.02, 0.04, 0.1), 0.015, Pal.BRASS, MeshKit.xf(Vector3(mid.x, 0.56, mid.y), Vector3(0, -ang, 0)))
				var n3 := maxi(1, int(round(len / 1.4)))
				for i in n3 + 1:
					var q3 := a.lerp(b, float(i) / n3)
					k.rbox(Vector3(0.12, 0.62, 0.12), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(q3.x, 0.31, q3.y))
					k.sphere(0.06, Pal.BRASS, MeshKit.at(q3.x, 0.66, q3.y), 8, 5)
	# gate posts
	var ph: float = [0.55, 0.8, 0.62, 0.7, 0.8][t]
	for sx in [-1.0, 1.0]:
		var gp := Vector3(sx * GATE * 0.5, 0, d * 0.5)
		var pc: Color = [Pal.WOOD_DARK, Color(0.62, 0.64, 0.66), Color(0.66, 0.66, 0.64), Color(0.94, 0.95, 0.96), Color(0.3, 0.32, 0.36)][t]
		k.rbox(Vector3(0.18, ph, 0.18), 0.03, pc, MeshKit.at(gp.x, ph * 0.5, gp.z))
		if t == 2:
			for i in 3:
				k.rbox(Vector3(0.185, 0.07, 0.185), 0.01, Color(0.96, 0.8, 0.26) if i % 2 == 0 else Color(0.18, 0.18, 0.2), MeshKit.at(gp.x, 0.15 + i * 0.14, gp.z))
		if t >= 1:
			k.rbox(Vector3(0.1, 0.1, 0.1), 0.03, Items.lit(Color(0.5, 0.95, 0.85) if t >= 3 else Color(1.0, 0.86, 0.6), 0.4), MeshKit.at(gp.x, ph + 0.06, gp.z))
	if t >= 4:
		# a glowing arch over the gate
		k.torus(GATE * 0.5, 0.035, Items.lit(Color(0.5, 0.9, 0.9), 0.5), MeshKit.xf(Vector3(0, ph + 0.05, d * 0.5), Vector3(0, 0, 0), Vector3(1, 0.6, 1)), 16, 5, PI)
	return k.commit()


## Props that make a source read richer as it levels up.
static func extras(res: String, w: float, d: float, t: int) -> Mesh:
	var k := MeshKit.new()
	var back := -d * 0.5
	var col: Color = Defs.ITEMS[res]["color"]
	# a sign by the gate in the resource's colour
	var sp := Vector3(GATE * 0.5 + 0.55, 0, d * 0.5 - 0.25)
	k.cyl(0.03, 0.55, Pal.STEEL_DARK, MeshKit.at(sp.x - 0.2, 0, sp.z), 5)
	k.cyl(0.03, 0.55, Pal.STEEL_DARK, MeshKit.at(sp.x + 0.2, 0, sp.z), 5)
	k.rbox(Vector3(0.56, 0.26, 0.04), 0.04, Pal.WOOD if t == 0 else Color(0.96, 0.96, 0.95), MeshKit.at(sp.x, 0.62, sp.z))
	k.rbox(Vector3(0.18, 0.18, 0.02), 0.05, col if t < 3 else Items.lit(col, 0.6), MeshKit.at(sp.x - 0.14, 0.62, sp.z + 0.025))
	for i in 2:
		k.rbox(Vector3(0.22 - i * 0.06, 0.03, 0.01), 0.005, Color(0.3, 0.32, 0.36), MeshKit.at(sp.x + 0.08, 0.66 - i * 0.07, sp.z + 0.025))
	match res:
		"power":
			# an inverter cabinet, bigger with each tier
			_cabinet(k, Vector3(-w * 0.5 + 0.45, 0, back + 0.4), 0.5 + t * 0.06, Color(0.86, 0.88, 0.9), Color(0.5, 0.95, 0.6))
		"data":
			# a lattice mast with blinking tips
			_mast(k, Vector3(w * 0.5 - 0.4, 0, back + 0.4), 1.6 + t * 0.35)
		"coolant":
			# a small hyperboloid cooling tower
			var q := Vector3(-w * 0.5 + 0.6, 0, back + 0.6)
			var s := 1.0 + t * 0.12
			k.lathe(PackedVector2Array([Vector2(0.45 * s, 0), Vector2(0.34 * s, 0.6 * s), Vector2(0.3 * s, 0.9 * s), Vector2(0.36 * s, 1.25 * s), Vector2(0.3 * s, 1.25 * s), Vector2(0.24 * s, 0.9 * s), Vector2(0.28 * s, 0.6 * s), Vector2(0.38 * s, 0.02)]), Color(0.86, 0.86, 0.84), MeshKit.at(q.x, 0, q.z), 16)
			k.torus(0.33 * s, 0.02, Color(0.36, 0.6, 0.86), MeshKit.at(q.x, 0.3 * s, q.z), 16, 4)
		"silicon":
			# a sand hopper with a chute
			var q2 := Vector3(w * 0.5 - 0.5, 0, back + 0.5)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.rbox(Vector3(0.05, 0.7, 0.05), 0.01, Pal.STEEL_DARK, MeshKit.at(q2.x + sx * 0.22, 0.35, q2.z + sz * 0.22))
			k.cyl(0.32, 0.4, Color(0.84, 0.76, 0.56), MeshKit.at(q2.x, 0.7, q2.z), 4, 0.02, 0.4)
			k.cone(0.3, 0.3, Color(0.9, 0.82, 0.6), MeshKit.xf(Vector3(q2.x, 0.72, q2.z), Vector3(180, 45, 0)), 4)
			k.ellipsoid(Vector3(0.36, 0.1, 0.3), Color(0.9, 0.82, 0.6), MeshKit.at(q2.x, 1.1, q2.z), 8, 4)
		"copper", "rare":
			# a mine entrance with timber props and a rail
			var q3 := Vector3(w * 0.5 - 0.7, 0, back + 0.35)
			k.ellipsoid(Vector3(0.8, 0.7, 0.4), Color(0.48, 0.44, 0.4), MeshKit.at(q3.x, 0.0, q3.z), 10, 6)
			k.rbox(Vector3(0.6, 0.55, 0.1), 0.04, Color(0.16, 0.14, 0.13), MeshKit.at(q3.x, 0.3, q3.z + 0.3))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.08, 0.62, 0.08), 0.02, Pal.WOOD, MeshKit.at(q3.x + sx * 0.32, 0.31, q3.z + 0.36))
			k.rbox(Vector3(0.74, 0.08, 0.08), 0.02, Pal.WOOD, MeshKit.at(q3.x, 0.62, q3.z + 0.36))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.03, 0.03, 1.2), 0.01, Pal.STEEL, MeshKit.at(q3.x + sx * 0.14, 0.09, q3.z + 0.9))
			if t >= 2:
				k.rbox(Vector3(0.36, 0.22, 0.42), 0.03, Color(0.42, 0.44, 0.48), MeshKit.at(q3.x, 0.24, q3.z + 1.1))
				k.ellipsoid(Vector3(0.16, 0.08, 0.18), col, MeshKit.at(q3.x, 0.36, q3.z + 1.1), 8, 4)
		"code", "labels", "experts", "feedback":
			# a whiteboard wall at the back and a coffee machine
			k.rbox(Vector3(w * 0.5, 0.9, 0.06), 0.02, Color(0.94, 0.95, 0.96), MeshKit.at(-w * 0.2, 0.55, back + 0.12))
			k.rbox(Vector3(w * 0.5 + 0.06, 0.06, 0.08), 0.02, col, MeshKit.at(-w * 0.2, 1.02, back + 0.12))
			for i in 4:
				k.rbox(Vector3(0.18, 0.12, 0.012), 0.02, [Color(0.98, 0.88, 0.4), Color(0.6, 0.86, 0.96), Color(0.98, 0.7, 0.7), Color(0.7, 0.92, 0.66)][i], MeshKit.at(-w * 0.4 + i * 0.32, 0.6 + (i % 2) * 0.18, back + 0.16))
			k.rbox(Vector3(0.3, 0.42, 0.26), 0.04, Color(0.24, 0.24, 0.26), MeshKit.at(w * 0.5 - 0.4, 0.21, back + 0.3))
			k.rbox(Vector3(0.08, 0.04, 0.012), 0.01, Items.lit(Color(1.0, 0.6, 0.4), 0.4), MeshKit.at(w * 0.5 - 0.4, 0.34, back + 0.435))
		"papers":
			# a little glass lecture pavilion frame at the back
			for i in 4:
				k.rbox(Vector3(0.06, 1.3, 0.06), 0.01, Color(0.94, 0.95, 0.96), MeshKit.at(-w * 0.5 + 0.4 + i * (w - 0.8) / 3.0, 0.65, back + 0.25))
			k.rbox(Vector3(w - 0.6, 0.08, 0.5), 0.02, Color(0.94, 0.95, 0.96), MeshKit.at(0, 1.32, back + 0.35))
			k.rbox(Vector3(w - 0.8, 0.9, 0.03), 0.01, Color(0.7, 0.86, 0.92, 0.85), MeshKit.at(0, 0.75, back + 0.2))
		"fiber":
			# a junction cabinet and a cable reel on the ground
			_cabinet(k, Vector3(-w * 0.5 + 0.45, 0, back + 0.4), 0.55, Color(0.94, 0.95, 0.96), Color(0.98, 0.62, 0.86))
			k.cyl(0.32, 0.1, Pal.WOOD, MeshKit.xf(Vector3(w * 0.5 - 0.5, 0.32, back + 0.4), Vector3(90, 0, 0)), 14)
			k.cyl(0.24, 0.3, Color(0.98, 0.62, 0.86), MeshKit.xf(Vector3(w * 0.5 - 0.5, 0.32, back + 0.25), Vector3(90, 0, 0)), 14)
	if t >= 2:
		# a control box by the gate
		_cabinet(k, Vector3(-GATE * 0.5 - 0.5, 0, d * 0.5 - 0.35), 0.4, Color(0.7, 0.72, 0.76), Color(0.5, 0.9, 1.0))
	if t >= 3:
		# a utility shed with a solar roof in the back corner
		var p := Vector3(w * 0.5 - 0.4, 0, back + 0.4) if not res in ["data", "silicon", "copper", "rare", "fiber"] else Vector3(-w * 0.5 + 0.4, 0, back + 0.4)
		if res in ["power", "coolant", "fiber"]:
			p = Vector3(w * 0.5 - 0.4, 0, back + 0.4)
		k.rbox(Vector3(0.6, 0.6, 0.6), 0.04, Color(0.94, 0.95, 0.96), MeshKit.at(p.x, 0.3, p.z))
		k.rbox(Vector3(0.66, 0.04, 0.66), 0.01, Color(0.18, 0.26, 0.44), MeshKit.xf(Vector3(p.x, 0.63, p.z), Vector3(-10, 0, 0)))
		k.rbox(Vector3(0.2, 0.36, 0.02), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(p.x, 0.2, p.z + 0.31))
	if t >= 4:
		# a slim wind turbine
		var q := Vector3(-w * 0.5 + 0.3, 0, d * 0.5 - 0.3)
		k.cyl(0.07, 2.4, Color(0.96, 0.97, 0.98), MeshKit.at(q.x, 0, q.z), 8, 0.0, 0.04)
		k.rbox(Vector3(0.12, 0.12, 0.24), 0.04, Color(0.96, 0.97, 0.98), MeshKit.at(q.x, 2.4, q.z))
		for i in 3:
			k.rbox(Vector3(0.06, 0.8, 0.02), 0.01, Color(0.96, 0.97, 0.98), MeshKit.xf(Vector3(q.x, 2.4, q.z + 0.14), Vector3(0, 0, i * 120 + 15)) * MeshKit.at(0, 0.4, 0))
	return k.commit()


static func _cabinet(k: MeshKit, p: Vector3, h: float, body: Color, led: Color) -> void:
	k.rbox(Vector3(0.42, h, 0.3), 0.03, body, MeshKit.at(p.x, h * 0.5, p.z))
	k.rbox(Vector3(0.36, 0.02, 0.32), 0.01, body.darkened(0.15), MeshKit.at(p.x, h * 0.66, p.z))
	k.rbox(Vector3(0.06, 0.04, 0.012), 0.01, Items.lit(led, 0.4), MeshKit.at(p.x + 0.12, h * 0.85, p.z + 0.155))
	k.rbox(Vector3(0.06, 0.04, 0.012), 0.01, Items.lit(led, 0.4), MeshKit.at(p.x + 0.03, h * 0.85, p.z + 0.155))


static func _mast(k: MeshKit, p: Vector3, h: float) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.025, h, Color(0.86, 0.3, 0.26), MeshKit.xf(Vector3(p.x + sx * 0.18, 0, p.z + sz * 0.18), Vector3(-sz * 3.5, 0, sx * 3.5)), 5)
	var n := int(h / 0.35)
	for i in n:
		var y := 0.2 + i * 0.35
		var r := 0.18 * (1.0 - y / h * 0.6)
		k.rbox(Vector3(r * 2.0, 0.02, 0.02), 0.005, Color(0.94, 0.94, 0.92), MeshKit.at(p.x, y, p.z + r))
		k.rbox(Vector3(r * 2.0, 0.02, 0.02), 0.005, Color(0.94, 0.94, 0.92), MeshKit.at(p.x, y, p.z - r))
	k.cyl(0.03, 0.4, Pal.STEEL, MeshKit.at(p.x, h, p.z), 5)
	k.sphere(0.06, Items.lit(Color(1.0, 0.3, 0.3), 0.4), MeshKit.at(p.x, h + 0.42, p.z), 6, 4)
	k.cyl(0.1, 0.18, Color(0.94, 0.94, 0.92), MeshKit.xf(Vector3(p.x + 0.12, h * 0.75, p.z), Vector3(0, 0, -90)), 8)
