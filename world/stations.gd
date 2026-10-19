class_name Stations
## Work stations inside the sources, one design per resource and per tier
## (the same five eras as the buildings, see ArchKit):
##   0 garage: second-hand gear on crates, folding tables, plywood
##   1 workshop: steel frames, racks, yellow safety bits
##   2 campus: white casings, teal bands, tidy pads
##   3 industrial: dark steel, blue LEDs, gauges and cable ladders
##   4 hyperscale: graphite and brass, glowing cores
## plus the streamed trees, shrubs and rocks of the landscape.
##
## A station stands at its spot's origin, facing +Z (where its technician
## stands, about z = 0.34 here). What it makes grows on it at product_at(res)
## until it's collected; some have a moving part (spinner) that turns while
## they work.

## Where the product sits on a station (local), and how big it grows.
static func product_at(res: String, _t := 0) -> Vector3:
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
static func spinner_at(res: String, _t := 0) -> Vector3:
	match res:
		"data": return Vector3(0, 0.55, -0.05)
		"coolant": return Vector3(0, 0.62, -0.1)
		"fiber": return Vector3(0, 0.42, -0.05)
	return Vector3.INF


static func station(res: String, t := 0) -> Mesh:
	var k := MeshKit.new()
	t = clampi(t, 0, 4)
	match res:
		"power": _power(k, t)
		"data": _data(k, t)
		"coolant": _coolant(k, t)
		"silicon": _silicon(k, t)
		"copper": _copper(k, t)
		"code": _code(k, t)
		"labels": _labels(k, t)
		"feedback": _feedback(k, t)
		"rare": _rare(k, t)
		"papers": _papers(k, t)
		"fiber": _fiber(k, t)
		"experts": _experts(k, t)
	return k.commit()


static func spinner(res: String, t := 0) -> Mesh:
	var k := MeshKit.new()
	t = clampi(t, 0, 4)
	match res:
		"data":
			var b := MeshKit.xf(Vector3.ZERO, Vector3(-35, 0, 0))
			if t == 0:
				# a tin-can antenna on a stick
				k.cyl(0.012, 0.12, Pal.STEEL_DARK, MeshKit.at(0, -0.04, 0), 5)
				k.cyl(0.05, 0.2, Color(0.78, 0.8, 0.82), MeshKit.xf(Vector3(0, 0.1, 0.1), Vector3(90, 0, 0)), 8)
				k.cyl(0.052, 0.02, Color(0.86, 0.3, 0.26), MeshKit.xf(Vector3(0, 0.1, 0.0), Vector3(90, 0, 0)), 8)
				k.box(Vector3(0.012, 0.012, 0.08), Color(0.9, 0.7, 0.3), MeshKit.at(0, 0.1, 0.0))
				return k.commit()
			var dish: Color = [Color(0.92, 0.93, 0.94), Color(0.8, 0.82, 0.84), Color(0.96, 0.97, 0.98), Color(0.34, 0.36, 0.4), Pal.BRASS][t]
			var r := 0.24 + t * 0.03
			k.lathe(PackedVector2Array([Vector2(0, -0.02), Vector2(r * 0.55, 0.0), Vector2(r, r * 0.28), Vector2(r * 1.03, r * 0.3), Vector2(r * 0.94, r * 0.3), Vector2(r * 0.52, r * 0.08), Vector2(0, 0.01)]), dish, b, 12)
			k.cyl(0.012, 0.28, Pal.STEEL_DARK, b * MeshKit.at(0, 0.0, 0), 5)
			for i in 3:
				var a := TAU * i / 3.0
				SourceArt.ln(k, b * Vector3(cos(a) * r * 0.9, r * 0.28, sin(a) * r * 0.9), b * Vector3(0, 0.28, 0), 0.01, Pal.STEEL_DARK)
			var tip: Color = [Color(0.4, 0.8, 1.0), Color(0.6, 1.0, 0.62), Color(0.42, 0.96, 0.9), Color(0.45, 0.75, 1.0), Color(1.0, 0.86, 0.5)][t]
			k.sphere(0.035, Items.lit(tip, 0.45), b * MeshKit.at(0, 0.3, 0), 8, 4)
			if t >= 3:
				k.torus(r * 0.98, 0.01, Items.lit(tip, 0.5), b * MeshKit.at(0, r * 0.3, 0), 14, 3)
		"coolant":
			var blade: Color = [Color(0.92, 0.92, 0.94), Color(0.3, 0.32, 0.36), Color(0.28, 0.3, 0.34), Color(0.2, 0.22, 0.26), Pal.BRASS][t]
			var n := 3 if t == 0 else (4 if t < 3 else 6)
			var len := 0.2 + (0.02 if t >= 3 else 0.0)
			for i in n:
				k.box(Vector3(0.06, 0.012, len), blade, MeshKit.xf(Vector3.ZERO, Vector3(0, i * 360.0 / n + 20, 14)) * MeshKit.at(0, 0, len * 0.55))
			k.cyl(0.04, 0.04, Color(0.6, 0.62, 0.66) if t < 4 else Color(0.12, 0.13, 0.15), MeshKit.at(0, -0.02, 0), 8)
			if t == 4:
				k.cyl(0.02, 0.05, Items.lit(Color(0.42, 0.9, 1.0), 0.4), MeshKit.at(0, 0.0, 0), 6)
		"fiber":
			var fl: Color = [Pal.WOOD, Color(0.3, 0.32, 0.38), Color(0.94, 0.95, 0.96), Color(0.22, 0.24, 0.28), Color(0.16, 0.17, 0.2)][t]
			var core: Color = [Color(0.95, 0.55, 0.25), Color(0.98, 0.62, 0.86), Color(0.98, 0.62, 0.86), Items.lit(Color(0.98, 0.62, 0.86), 0.6), Items.lit(Color(1.0, 0.7, 0.9), 0.45)][t]
			var r := 0.24 if t > 0 else 0.22
			k.cyl(r, 0.04, fl, MeshKit.xf(Vector3(-0.2, 0, 0), Vector3(0, 0, -90)), 12)
			k.cyl(r, 0.04, fl, MeshKit.xf(Vector3(0.16, 0, 0), Vector3(0, 0, -90)), 12)
			k.cyl(r * 0.7, 0.32, core, MeshKit.xf(Vector3(-0.16, 0, 0), Vector3(0, 0, -90)), 12)
			for i in 3:
				k.box(Vector3(0.38, 0.02, 0.02), fl.darkened(0.2) if t < 3 else Items.lit(Color(1, 0.86, 0.95), 0.4), MeshKit.xf(Vector3.ZERO, Vector3(i * 60, 0, 0)) * MeshKit.at(0, r * 0.72, 0))
			if t == 4:
				for sx in [-0.22, 0.18]:
					k.torus(r, 0.012, Pal.BRASS, MeshKit.xf(Vector3(sx, 0, 0), Vector3(0, 0, 90)), 14, 3)
			if t == 0:
				# the crank handle
				k.box(Vector3(0.03, 0.14, 0.03), Pal.WOOD_DARK, MeshKit.at(0.2, 0.07, 0))
	return k.commit()


# ---------------------------------------------------------------- helpers

static func _b(k: MeshKit, s: Vector3, col: Color, p: Vector3, r := Vector3.ZERO) -> void:
	k.box(s, col, MeshKit.xf(p, r))


static func _c(t: int, key: String) -> Color:
	return ArchKit.c(t, key)


static func _lit(c: Color, a := 0.45) -> Color:
	return Color(c.r, c.g, c.b, a)


## A solar-style panel (frame and a grid of cells) on transform tf.
static func _panel(k: MeshKit, tf: Transform3D, w: float, d: float, nx: int, nz: int, frame: Color, cell: Color, th := 0.03) -> void:
	k.box(Vector3(w, th, d), frame, tf)
	var cw := (w - 0.03) / nx
	var cd := (d - 0.03) / nz
	for i in nx:
		for j in nz:
			k.box(Vector3(cw - 0.012, 0.008, cd - 0.012), cell, tf * MeshKit.at(-w * 0.5 + 0.015 + (i + 0.5) * cw, th * 0.5 + 0.002, -d * 0.5 + 0.015 + (j + 0.5) * cd))


## A wooden crate with slats.
static func _crate(k: MeshKit, p: Vector3, s: Vector3, col: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(s, col, tf * MeshKit.at(0, s.y * 0.5, 0))
	for y in [0.2, 0.8]:
		k.box(Vector3(s.x + 0.012, s.y * 0.12, s.z + 0.012), col.darkened(0.18), tf * MeshKit.at(0, s.y * y, 0))
	k.box(Vector3(s.x * 0.12, s.y, s.z + 0.014), col.darkened(0.12), tf * MeshKit.at(0, s.y * 0.5, 0))


## A pad the technician stands on, with a status strip.
static func _pad(k: MeshKit, t: int, w := 0.42, p := Vector3(0, 0, 0.32)) -> void:
	var col: Color = [Color(0.5, 0.46, 0.4), Color(0.6, 0.6, 0.58), Color(0.9, 0.9, 0.9), Color(0.3, 0.32, 0.36), Color(0.14, 0.15, 0.17)][t]
	k.box(Vector3(w, 0.04, w * 0.8), col, MeshKit.at(p.x, 0.02, p.z))
	match t:
		1:
			for i in 4:
				k.box(Vector3(w * 0.18, 0.006, 0.05), Color(0.96, 0.76, 0.2) if i % 2 == 0 else Color(0.16, 0.16, 0.18), MeshKit.xf(Vector3(p.x - w * 0.33 + i * w * 0.22, 0.042, p.z + w * 0.34), Vector3(0, 30, 0)))
		2:
			k.box(Vector3(w * 0.8, 0.006, 0.03), _c(2, "accent"), MeshKit.at(p.x, 0.042, p.z + w * 0.34))
		3:
			k.box(Vector3(w * 0.8, 0.006, 0.025), _lit(Color(0.45, 0.75, 1.0), 0.5), MeshKit.at(p.x, 0.042, p.z + w * 0.35))
			k.box(Vector3(w + 0.01, 0.01, 0.02), Color(0.98, 0.8, 0.22), MeshKit.at(p.x, 0.035, p.z - w * 0.4))
		4:
			k.box(Vector3(w + 0.01, 0.012, 0.02), Pal.BRASS, MeshKit.at(p.x, 0.04, p.z + w * 0.4))
			k.box(Vector3(w + 0.01, 0.012, 0.02), Pal.BRASS, MeshKit.at(p.x, 0.04, p.z - w * 0.4))
			k.box(Vector3(w * 0.7, 0.006, 0.02), _lit(Color(1.0, 0.86, 0.5), 0.45), MeshKit.at(p.x, 0.044, p.z))


## A little office chair (seat height ~0.3), facing -z.
static func _chair(k: MeshKit, p: Vector3, seat: Color, frame: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.22, 0.04, 0.2), seat, tf * MeshKit.at(0, 0.3, 0))
	k.box(Vector3(0.22, 0.24, 0.035), seat.darkened(0.08), tf * MeshKit.at(0, 0.45, 0.1))
	k.box(Vector3(0.03, 0.28, 0.03), frame, tf * MeshKit.at(0, 0.15, 0))
	for i in 5:
		var a := TAU * i / 5.0
		k.box(Vector3(0.025, 0.02, 0.13), frame, tf * MeshKit.xf(Vector3(cos(a) * 0.06, 0.015, sin(a) * 0.06), Vector3(0, -rad_to_deg(a) + 90, 0)))


## A monitor (bottom centre at p), screen showing lines of code.
static func _monitor(k: MeshKit, p: Vector3, w: float, h: float, case_col: Color, glow: Color, yaw := 0.0) -> void:
	var tf := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.03, 0.08, 0.03), case_col, tf * MeshKit.at(0, 0.04, 0))
	k.box(Vector3(0.12, 0.01, 0.08), case_col, tf * MeshKit.at(0, 0.005, 0))
	k.box(Vector3(w, h, 0.025), case_col, tf * MeshKit.at(0, 0.08 + h * 0.5, 0))
	k.box(Vector3(w - 0.03, h - 0.03, 0.006), Color(0.1, 0.11, 0.14), tf * MeshKit.at(0, 0.08 + h * 0.5, 0.013))
	var n := maxi(2, int(h / 0.04))
	for i in n:
		var lw := (w - 0.06) * (0.35 + 0.5 * fposmod(i * 0.37, 1.0))
		k.box(Vector3(lw, 0.01, 0.004), _lit(glow, 0.5), tf * MeshKit.at(-(w - 0.06) * 0.5 + lw * 0.5 + 0.02 * (i % 3), 0.08 + h - 0.03 - i * (h - 0.04) / n, 0.017))


## Stacks of books.
static func _books(k: MeshKit, p: Vector3, n: int, seed := 0) -> void:
	var cs := [Color(0.6, 0.3, 0.3), Color(0.3, 0.4, 0.6), Color(0.86, 0.68, 0.32), Color(0.36, 0.5, 0.38), Color(0.9, 0.88, 0.82)]
	for i in n:
		k.box(Vector3(0.16 - (i % 2) * 0.02, 0.035, 0.12), cs[(i + seed) % cs.size()], MeshKit.xf(p + Vector3(0, 0.0175 + i * 0.036, 0), Vector3(0, (i * 23 + seed * 7) % 30 - 15, 0)))


# ---------------------------------------------------------------- power

static func _power(k: MeshKit, t: int) -> void:
	var cell := Color(0.16, 0.24, 0.46)
	match t:
		0:
			# a second-hand panel propped on two crates, a car battery, jumper leads
			for sx in [-1.0, 1.0]:
				_crate(k, Vector3(sx * 0.28, 0, -0.2), Vector3(0.22, 0.26, 0.2), Pal.WOOD_LIGHT, sx * 8.0)
			var pt := MeshKit.xf(Vector3(0, 0.33, -0.08), Vector3(26, 4, 2))
			_panel(k, pt, 0.84, 0.52, 4, 2, Color(0.72, 0.74, 0.76), cell)
			k.box(Vector3(0.18, 0.009, 0.2), Color(0.42, 0.52, 0.7), pt * MeshKit.at(0.2, 0.021, 0.1))
			_b(k, Vector3(0.14, 0.07, 0.07), Pal.BRICK, Vector3(-0.18, 0.035, 0.14), Vector3(0, 12, 0))
			_b(k, Vector3(0.14, 0.07, 0.07), Pal.BRICK_DARK, Vector3(0.16, 0.035, 0.14), Vector3(0, -8, 0))
			# car battery and leads
			_b(k, Vector3(0.18, 0.13, 0.11), Color(0.12, 0.12, 0.13), Vector3(0.3, 0.065, 0.24), Vector3(0, -14, 0))
			_b(k, Vector3(0.16, 0.02, 0.09), Color(0.24, 0.36, 0.7), Vector3(0.3, 0.135, 0.24), Vector3(0, -14, 0))
			_b(k, Vector3(0.025, 0.03, 0.025), Color(0.85, 0.2, 0.18), Vector3(0.25, 0.15, 0.25))
			_b(k, Vector3(0.025, 0.03, 0.025), Color(0.15, 0.15, 0.15), Vector3(0.35, 0.15, 0.22))
			SourceArt.ln(k, Vector3(0.25, 0.16, 0.25), Vector3(0.12, 0.2, 0.08), 0.014, Color(0.85, 0.2, 0.18))
			SourceArt.ln(k, Vector3(0.35, 0.16, 0.22), Vector3(0.2, 0.22, 0.05), 0.014, Color(0.15, 0.15, 0.15))
			# cardboard under the product, a cord trailing off
			_b(k, Vector3(0.3, 0.01, 0.26), Color(0.72, 0.6, 0.42), Vector3(-0.02, 0.005, 0.32), Vector3(0, 8, 0))
			SourceArt.ln(k, Vector3(-0.3, 0.012, -0.05), Vector3(-0.4, 0.012, 0.3), 0.016, Color(0.92, 0.5, 0.2))
			_b(k, Vector3(0.06, 0.04, 0.04), Color(0.92, 0.5, 0.2), Vector3(-0.3, 0.02, -0.05))
		1:
			# a galvanised A-frame rack with two panels on concrete footings
			var steel := Color(0.7, 0.72, 0.75)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.1, 0.06, 0.1), Color(0.66, 0.65, 0.62), Vector3(sx * 0.36, 0.03, -0.26))
				_b(k, Vector3(0.1, 0.06, 0.1), Color(0.66, 0.65, 0.62), Vector3(sx * 0.36, 0.03, 0.1))
				_b(k, Vector3(0.035, 0.62, 0.035), steel, Vector3(sx * 0.36, 0.33, -0.26))
				_b(k, Vector3(0.035, 0.3, 0.035), steel, Vector3(sx * 0.36, 0.17, 0.1))
				SourceArt.ln(k, Vector3(sx * 0.36, 0.06, -0.26), Vector3(sx * 0.36, 0.3, 0.1), 0.025, steel)
			_b(k, Vector3(0.78, 0.03, 0.03), steel, Vector3(0, 0.25, -0.08))
			var pt := MeshKit.xf(Vector3(0, 0.47, -0.08), Vector3(32, 0, 0))
			for sx in [-1.0, 1.0]:
				_panel(k, pt * MeshKit.at(sx * 0.215, 0, 0), 0.41, 0.66, 2, 3, Color(0.78, 0.8, 0.82), cell)
			# junction box, conduit, warning sticker
			_b(k, Vector3(0.14, 0.12, 0.06), Color(0.82, 0.84, 0.86), Vector3(0.2, 0.2, -0.18))
			_b(k, Vector3(0.05, 0.05, 0.005), Color(0.98, 0.84, 0.3), Vector3(0.2, 0.22, -0.148))
			SourceArt.ln(k, Vector3(0.2, 0.14, -0.18), Vector3(0.2, 0.01, -0.18), 0.02, Color(0.3, 0.32, 0.36))
			SourceArt.ln(k, Vector3(0.2, 0.01, -0.18), Vector3(0.42, 0.01, -0.3), 0.02, Color(0.3, 0.32, 0.36))
			_pad(k, 1, 0.38)
		2:
			# a single-axis tracker: white post, torque tube, three panels, motor
			var white := Color(0.94, 0.95, 0.96)
			_b(k, Vector3(0.2, 0.06, 0.2), Color(0.86, 0.86, 0.86), Vector3(0, 0.03, -0.08))
			k.cyl(0.04, 0.5, white, MeshKit.at(0, 0.06, -0.08), 8)
			k.cyl(0.03, 0.9, Color(0.8, 0.82, 0.84), MeshKit.xf(Vector3(-0.45, 0.58, -0.08), Vector3(0, 0, -90)), 8)
			_b(k, Vector3(0.12, 0.12, 0.1), white, Vector3(0, 0.52, -0.02))
			_b(k, Vector3(0.122, 0.025, 0.102), _c(2, "accent"), Vector3(0, 0.5, -0.02))
			_b(k, Vector3(0.03, 0.02, 0.005), _lit(Color(0.42, 0.96, 0.9)), Vector3(0.03, 0.55, 0.032))
			var pt := MeshKit.xf(Vector3(0, 0.62, -0.08), Vector3(22, 0, 0))
			for i in 3:
				_panel(k, pt * MeshKit.at(-0.3 + i * 0.3, 0, 0), 0.29, 0.6, 2, 4, white, cell, 0.025)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.02, 0.02, 0.4), Color(0.8, 0.82, 0.84), Vector3(sx * 0.3, 0.6, -0.08), Vector3(22, 0, 0))
			_pad(k, 2, 0.38)
		3:
			# a bifacial table on galvanised piles, combiner box, cable tray
			var gal := Color(0.62, 0.65, 0.7)
			for sx in [-0.36, 0.0, 0.36]:
				_b(k, Vector3(0.04, 0.42, 0.06), gal, Vector3(sx, 0.21, -0.18))
				_b(k, Vector3(0.04, 0.24, 0.06), gal, Vector3(sx, 0.12, 0.12))
				_b(k, Vector3(0.06, 0.02, 0.08), Color(0.98, 0.8, 0.22), Vector3(sx, 0.01, -0.18))
				SourceArt.ln(k, Vector3(sx, 0.42, -0.18), Vector3(sx, 0.24, 0.12), 0.03, gal)
			for z in [-0.12, 0.06]:
				_b(k, Vector3(0.9, 0.03, 0.04), gal, Vector3(0, 0.36 - (z + 0.12) * 0.55, z - 0.02), Vector3(28, 0, 0))
			var pt := MeshKit.xf(Vector3(0, 0.4, -0.03), Vector3(28, 0, 0))
			for i in 4:
				for j in 2:
					_panel(k, pt * MeshKit.at(-0.345 + i * 0.23, 0, -0.19 + j * 0.38), 0.22, 0.36, 2, 3, Color(0.3, 0.32, 0.36), Color(0.12, 0.18, 0.36), 0.02)
			_b(k, Vector3(0.9, 0.008, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.5), Vector3(0, 0.5, -0.24), Vector3(28, 0, 0))
			_b(k, Vector3(0.16, 0.2, 0.08), Color(0.36, 0.4, 0.46), Vector3(-0.2, 0.1, 0.02))
			_b(k, Vector3(0.06, 0.02, 0.005), _lit(Color(0.45, 0.75, 1.0), 0.4), Vector3(-0.2, 0.16, 0.062))
			_b(k, Vector3(0.84, 0.03, 0.1), Color(0.5, 0.52, 0.56), Vector3(0, 0.015, -0.32))
			_pad(k, 3, 0.36)
		4:
			# a heliostat: brass-framed mirror facets on a graphite pedestal,
			# tipped up to the tower behind
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.36, 0.06, 0.36), gr, Vector3(0, 0.03, -0.06))
			for sz in [-1.0, 1.0]:
				_b(k, Vector3(0.38, 0.015, 0.02), Pal.BRASS, Vector3(0, 0.06, -0.06 + sz * 0.18))
				_b(k, Vector3(0.02, 0.015, 0.38), Pal.BRASS, Vector3(sz * 0.18, 0.06, -0.06))
			k.cyl(0.06, 0.5, gr, MeshKit.at(0, 0.06, -0.06), 8, 0.0, 0.045)
			k.cyl(0.07, 0.03, Pal.BRASS, MeshKit.at(0, 0.3, -0.06), 8)
			k.cyl(0.064, 0.02, _lit(Color(1.0, 0.86, 0.5), 0.4), MeshKit.at(0, 0.12, -0.06), 8)
			# yoke
			_b(k, Vector3(0.26, 0.04, 0.06), Pal.BRASS, Vector3(0, 0.56, -0.06))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.03, 0.14, 0.05), Pal.BRASS, Vector3(sx * 0.12, 0.62, -0.06))
			var pt := MeshKit.xf(Vector3(0, 0.68, -0.06), Vector3(-24, 0, 0))
			k.box(Vector3(0.84, 0.035, 0.7), gr, pt)
			for i in 3:
				for j in 3:
					k.box(Vector3(0.26, 0.012, 0.215), Color(0.66, 0.82, 0.94, 0.6), pt * MeshKit.at(-0.28 + i * 0.28, 0.022, -0.23 + j * 0.23))
			for i in 4:
				k.box(Vector3(0.012, 0.02, 0.7), Pal.BRASS, pt * MeshKit.at(-0.42 + i * 0.28, 0.022, 0))
			for j in 2:
				k.box(Vector3(0.84, 0.02, 0.012), Pal.BRASS, pt * MeshKit.at(0, 0.022, -0.115 + j * 0.23))
			k.box(Vector3(0.6, 0.03, 0.03), gr, pt * MeshKit.at(0, -0.035, 0))
			_pad(k, 4, 0.36)


# ---------------------------------------------------------------- data

static func _data(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a laptop on a folding table, a home router, a mug
			var top := Color(0.86, 0.84, 0.78)
			_b(k, Vector3(0.6, 0.025, 0.4), top, Vector3(0, 0.46, -0.05))
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(sx * 0.24, 0.0, -0.22), Vector3(sx * 0.24, 0.45, 0.12), 0.02, Color(0.3, 0.32, 0.34))
				SourceArt.ln(k, Vector3(sx * 0.24, 0.0, 0.12), Vector3(sx * 0.24, 0.45, -0.22), 0.02, Color(0.3, 0.32, 0.34))
			# laptop
			_b(k, Vector3(0.24, 0.014, 0.16), Color(0.7, 0.72, 0.74), Vector3(0.12, 0.48, 0.05))
			_b(k, Vector3(0.24, 0.16, 0.01), Color(0.7, 0.72, 0.74), Vector3(0.12, 0.555, -0.035), Vector3(-12, 0, 0))
			_b(k, Vector3(0.21, 0.13, 0.004), _lit(Color(0.4, 0.8, 1.0), 0.55), Vector3(0.12, 0.555, -0.028), Vector3(-12, 0, 0))
			# router with two antennas (the cantenna spins at the back)
			_b(k, Vector3(0.16, 0.035, 0.1), Color(0.14, 0.14, 0.16), Vector3(-0.16, 0.49, -0.05))
			for i in 4:
				_b(k, Vector3(0.012, 0.008, 0.004), _lit(Color(0.5, 1.0, 0.6), 0.4), Vector3(-0.21 + i * 0.03, 0.495, 0.002))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.012, 0.14, 0.012), Color(0.14, 0.14, 0.16), Vector3(-0.16 + sx * 0.07, 0.57, -0.09), Vector3(0, 0, sx * 10))
			k.cyl(0.03, 0.07, Color(0.9, 0.42, 0.3), MeshKit.at(-0.22, 0.47, 0.08), 8)
			_b(k, Vector3(0.1, 0.004, 0.12), Color(0.95, 0.95, 0.9), Vector3(-0.05, 0.474, 0.08), Vector3(0, 20, 0))
			SourceArt.ln(k, Vector3(0.26, 0.47, -0.2), Vector3(0.3, 0.01, -0.3), 0.012, Color(0.15, 0.15, 0.16))
			_crate(k, Vector3(-0.26, 0, 0.08), Vector3(0.16, 0.14, 0.16), Color(0.72, 0.6, 0.42))
		1:
			# an open steel rack with a few servers, a small dish on top
			var steel := Color(0.4, 0.42, 0.46)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.035, 0.48, 0.035), steel, Vector3(sx * 0.18, 0.24, -0.05 + sz * 0.17))
			_b(k, Vector3(0.4, 0.03, 0.38), steel, Vector3(0, 0.48, -0.05))
			_b(k, Vector3(0.4, 0.03, 0.38), steel, Vector3(0, 0.03, -0.05))
			for i in 4:
				var y := 0.1 + i * 0.09
				_b(k, Vector3(0.34, 0.065, 0.3), Color(0.18, 0.19, 0.22), Vector3(0, y, -0.06))
				for j in 3:
					_b(k, Vector3(0.025, 0.012, 0.004), _lit([Color(0.6, 1.0, 0.62), Color(1.0, 0.8, 0.4), Color(0.4, 0.9, 1.0)][(i + j) % 3], 0.4), Vector3(-0.12 + j * 0.04, y, 0.092))
				_b(k, Vector3(0.1, 0.03, 0.004), Color(0.5, 0.52, 0.56), Vector3(0.1, y, 0.092))
			_b(k, Vector3(0.04, 0.48, 0.03), Color(0.96, 0.76, 0.2), Vector3(0.21, 0.24, 0.12))
			k.cyl(0.05, 0.08, steel, MeshKit.at(0, 0.48, -0.05), 8)
			SourceArt.ln(k, Vector3(-0.18, 0.4, -0.22), Vector3(-0.3, 0.01, -0.34), 0.02, Color(0.2, 0.4, 0.8))
			SourceArt.ln(k, Vector3(-0.16, 0.36, -0.22), Vector3(-0.22, 0.01, -0.36), 0.02, Color(0.9, 0.6, 0.2))
			_pad(k, 1, 0.34, Vector3(0, 0, 0.3))
		2:
			# a white kiosk tower with a teal band and a glass server window
			var white := Color(0.95, 0.95, 0.96)
			_b(k, Vector3(0.44, 0.44, 0.4), white, Vector3(0, 0.22, -0.05))
			_b(k, Vector3(0.46, 0.05, 0.42), _c(2, "accent"), Vector3(0, 0.36, -0.05))
			_b(k, Vector3(0.48, 0.04, 0.44), Color(0.86, 0.88, 0.9), Vector3(0, 0.46, -0.05))
			_b(k, Vector3(0.3, 0.24, 0.01), Color(0.58, 0.8, 0.92, 0.7), Vector3(0, 0.18, 0.152))
			for i in 4:
				_b(k, Vector3(0.24, 0.035, 0.008), Color(0.26, 0.29, 0.33), Vector3(0, 0.09 + i * 0.055, 0.145))
				_b(k, Vector3(0.02, 0.01, 0.006), _lit(Color(0.42, 0.96, 0.9)), Vector3(0.09, 0.09 + i * 0.055, 0.15))
			for sx in [-1.0, 1.0]:
				for j in 4:
					_b(k, Vector3(0.006, 0.02, 0.3), Color(0.8, 0.82, 0.84), Vector3(sx * 0.222, 0.1 + j * 0.05, -0.05))
			k.cyl(0.05, 0.1, Color(0.82, 0.84, 0.86), MeshKit.at(0, 0.46, -0.05), 8)
			_pad(k, 2, 0.34, Vector3(0, 0, 0.32))
		3:
			# a dark steel cabinet, blue LEDs, a cable ladder up to a radar dish
			var dk := Color(0.26, 0.28, 0.32)
			_b(k, Vector3(0.42, 0.46, 0.38), dk, Vector3(0, 0.23, -0.06))
			_b(k, Vector3(0.44, 0.03, 0.4), Color(0.18, 0.19, 0.22), Vector3(0, 0.47, -0.06))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.012, 0.36, 0.006), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(sx * 0.17, 0.24, 0.132))
			for i in 6:
				_b(k, Vector3(0.26, 0.02, 0.006), Color(0.14, 0.15, 0.18), Vector3(0, 0.08 + i * 0.06, 0.132))
				_b(k, Vector3(0.02, 0.01, 0.004), _lit(Color(0.45, 0.75, 1.0), 0.4), Vector3(0.1, 0.08 + i * 0.06, 0.136))
			for j in 5:
				_b(k, Vector3(0.006, 0.03, 0.3), Color(0.4, 0.42, 0.46), Vector3(0.214, 0.1 + j * 0.07, -0.06))
			# cable ladder at the back
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.02, 0.6, 0.02), Color(0.5, 0.52, 0.56), Vector3(sx * 0.08, 0.3, -0.27))
			for i in 6:
				_b(k, Vector3(0.16, 0.012, 0.02), Color(0.5, 0.52, 0.56), Vector3(0, 0.06 + i * 0.1, -0.27))
			_b(k, Vector3(0.04, 0.5, 0.03), Color(0.2, 0.4, 0.8), Vector3(0.0, 0.27, -0.29))
			k.cyl(0.05, 0.08, Color(0.36, 0.38, 0.42), MeshKit.at(0, 0.48, -0.05), 8)
			_b(k, Vector3(0.06, 0.06, 0.04), Color(0.98, 0.8, 0.22), Vector3(-0.15, 0.4, 0.13))
			_pad(k, 3, 0.34, Vector3(0, 0, 0.32))
		4:
			# a graphite obelisk with brass edges, glowing fins and an orbit ring
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.46, 0.06, 0.46), Color(0.12, 0.13, 0.15), Vector3(0, 0.03, -0.05))
			_b(k, Vector3(0.38, 0.22, 0.38), gr, Vector3(0, 0.17, -0.05))
			_b(k, Vector3(0.3, 0.2, 0.3), gr.lightened(0.05), Vector3(0, 0.38, -0.05))
			for y in [0.06, 0.28, 0.48]:
				_b(k, Vector3(0.4 if y < 0.3 else 0.32, 0.015, 0.4 if y < 0.3 else 0.32), Pal.BRASS, Vector3(0, y, -0.05))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.02, 0.42, 0.02), Pal.BRASS, Vector3(sx * 0.19, 0.27, -0.05 + sz * 0.19))
			for i in 3:
				_b(k, Vector3(0.012, 0.3, 0.012), _lit(Color(1.0, 0.86, 0.5), 0.4), Vector3(-0.08 + i * 0.08, 0.26, 0.145))
				_b(k, Vector3(0.012, 0.3, 0.012), _lit(Color(0.42, 0.9, 1.0), 0.45), Vector3(0.195, 0.26, -0.13 + i * 0.08))
			k.torus(0.32, 0.012, _lit(Color(0.42, 0.9, 1.0), 0.45), MeshKit.xf(Vector3(0, 0.3, -0.05), Vector3(8, 0, 6)), 16, 3)
			k.cyl(0.05, 0.08, Pal.BRASS, MeshKit.at(0, 0.48, -0.05), 8)
			_pad(k, 4, 0.34, Vector3(0, 0, 0.34))


# ---------------------------------------------------------------- coolant

static func _coolant(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a blue water barrel with a desk fan clamped on top, a hose, ice
			k.cyl(0.2, 0.52, Color(0.22, 0.42, 0.72), MeshKit.at(0, 0, -0.1), 10)
			for y in [0.12, 0.4]:
				k.cyl(0.205, 0.03, Color(0.18, 0.36, 0.62), MeshKit.at(0, y, -0.1), 10, 0.0, -1.0, false)
			k.cyl(0.06, 0.04, Color(0.86, 0.86, 0.84), MeshKit.at(0, 0.52, -0.1), 8)
			k.cyl(0.015, 0.06, Color(0.86, 0.86, 0.84), MeshKit.at(0, 0.56, -0.1), 5)
			k.torus(0.15, 0.008, Color(0.86, 0.86, 0.84), MeshKit.at(0, 0.62, -0.1), 12, 3)
			for i in 4:
				SourceArt.ln(k, Vector3(0, 0.6, -0.1), Vector3(cos(i * PI * 0.5) * 0.15, 0.62, -0.1 + sin(i * PI * 0.5) * 0.15), 0.006, Color(0.86, 0.86, 0.84))
			# garden hose, a cooler box, an ice bag
			for i in 5:
				var a0 := i * 1.2
				SourceArt.ln(k, Vector3(0.28 + cos(a0) * 0.08, 0.015, 0.1 + sin(a0) * 0.08), Vector3(0.28 + cos(a0 + 1.2) * 0.08, 0.015, 0.1 + sin(a0 + 1.2) * 0.08), 0.02, Color(0.3, 0.62, 0.32))
			SourceArt.ln(k, Vector3(0.2, 0.015, 0.1), Vector3(0.15, 0.45, -0.1), 0.02, Color(0.3, 0.62, 0.32))
			_b(k, Vector3(0.24, 0.16, 0.16), Color(0.92, 0.3, 0.26), Vector3(-0.28, 0.08, 0.06), Vector3(0, 14, 0))
			_b(k, Vector3(0.25, 0.04, 0.17), Color(0.95, 0.95, 0.92), Vector3(-0.28, 0.18, 0.06), Vector3(0, 14, 0))
			_b(k, Vector3(0.12, 0.08, 0.1), Color(0.82, 0.9, 0.96), Vector3(-0.08, 0.04, 0.16), Vector3(0, -20, 0))
		1:
			# a steel condenser unit: coil grilles, fan grille on top, copper lines
			var body := Color(0.72, 0.74, 0.77)
			_b(k, Vector3(0.62, 0.06, 0.46), Color(0.6, 0.6, 0.58), Vector3(0, 0.03, -0.1))
			_b(k, Vector3(0.58, 0.48, 0.42), body, Vector3(0, 0.3, -0.1))
			for i in 8:
				_b(k, Vector3(0.012, 0.38, 0.43), body.darkened(0.25), Vector3(-0.24 + i * 0.068, 0.3, -0.1))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.02, 0.5, 0.02), Color(0.96, 0.76, 0.2), Vector3(sx * 0.3, 0.3, 0.12))
			k.cyl(0.17, 0.06, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.54, -0.1), 12)
			_b(k, Vector3(0.36, 0.012, 0.02), Color(0.5, 0.52, 0.56), Vector3(0, 0.62, -0.1))
			_b(k, Vector3(0.02, 0.012, 0.36), Color(0.5, 0.52, 0.56), Vector3(0, 0.62, -0.1))
			for i in 2:
				SourceArt.ln(k, Vector3(0.3, 0.12 + i * 0.07, -0.02), Vector3(0.4, 0.12 + i * 0.07, 0.1), 0.025, Color(0.78, 0.5, 0.3))
				SourceArt.ln(k, Vector3(0.4, 0.12 + i * 0.07, 0.1), Vector3(0.4, 0.01, 0.1), 0.025, Color(0.78, 0.5, 0.3))
			_b(k, Vector3(0.14, 0.1, 0.01), Color(0.96, 0.76, 0.2), Vector3(-0.16, 0.42, 0.115))
			_pad(k, 1, 0.34, Vector3(0, 0, 0.34))
		2:
			# a white chiller module, teal band, blue pipes, a little screen
			var body := Color(0.94, 0.95, 0.96)
			_b(k, Vector3(0.64, 0.56, 0.44), body, Vector3(0, 0.28, -0.1))
			_b(k, Vector3(0.66, 0.06, 0.46), _c(2, "accent"), Vector3(0, 0.08, -0.1))
			for i in 6:
				_b(k, Vector3(0.5, 0.02, 0.012), Color(0.72, 0.76, 0.8), Vector3(0, 0.18 + i * 0.055, 0.125))
			k.cyl(0.19, 0.05, Color(0.82, 0.84, 0.86), MeshKit.at(0, 0.56, -0.1), 12)
			k.cyl(0.16, 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.6, -0.1), 12)
			for sx in [-1.0, 1.0]:
				k.cyl(0.035, 0.18, Color(0.36, 0.6, 0.86), MeshKit.xf(Vector3(sx * 0.32, 0.18, -0.1), Vector3(0, 0, sx * -90)), 8)
				k.cyl(0.035, 0.18, Color(0.36, 0.6, 0.86), MeshKit.at(sx * 0.5, 0.0, -0.1), 8)
			_b(k, Vector3(0.14, 0.08, 0.012), Color(0.2, 0.22, 0.26), Vector3(0.18, 0.46, 0.125))
			_b(k, Vector3(0.1, 0.04, 0.004), _lit(Color(0.42, 0.96, 0.9)), Vector3(0.18, 0.46, 0.132))
			_pad(k, 2, 0.34, Vector3(0, 0, 0.34))
		3:
			# a dark steel fan cell: big shroud, louvres, gauges, blue LEDs
			var dk := Color(0.32, 0.35, 0.4)
			_b(k, Vector3(0.66, 0.06, 0.5), Color(0.2, 0.21, 0.24), Vector3(0, 0.03, -0.1))
			_b(k, Vector3(0.62, 0.5, 0.46), dk, Vector3(0, 0.31, -0.1))
			for i in 7:
				_b(k, Vector3(0.56, 0.02, 0.05), dk.darkened(0.25), Vector3(0, 0.12 + i * 0.055, 0.14), Vector3(-30, 0, 0))
			k.cyl(0.24, 0.1, dk.darkened(0.1), MeshKit.at(0, 0.56, -0.1), 12, 0.0, 0.22)
			k.cyl(0.2, 0.012, Color(0.12, 0.13, 0.15), MeshKit.at(0, 0.6, -0.1), 12)
			_b(k, Vector3(0.62, 0.015, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0, 0.5, 0.132))
			for sx in [-1.0, 1.0]:
				k.cyl(0.045, 0.16, Color(0.36, 0.6, 0.86), MeshKit.xf(Vector3(sx * 0.31, 0.2, -0.1), Vector3(0, 0, sx * -90)), 8)
				k.cyl(0.065, 0.025, Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(sx * 0.4, 0.2, -0.1), Vector3(0, 0, sx * -90)), 8)
			k.cyl(0.04, 0.02, Color(0.95, 0.95, 0.92), MeshKit.xf(Vector3(-0.2, 0.44, 0.13), Vector3(90, 0, 0)), 8)
			_b(k, Vector3(0.12, 0.08, 0.02), Color(0.98, 0.8, 0.22), Vector3(0.2, 0.44, 0.135))
			_pad(k, 3, 0.34, Vector3(0, 0, 0.36))
		4:
			# a graphite module, brass fan ring, glowing coolant loops
			var gr := Color(0.17, 0.18, 0.21)
			var cool := _lit(Color(0.42, 0.9, 1.0), 0.4)
			_b(k, Vector3(0.62, 0.52, 0.44), gr, Vector3(0, 0.26, -0.1))
			for y in [0.04, 0.5]:
				_b(k, Vector3(0.64, 0.02, 0.46), Pal.BRASS, Vector3(0, y, -0.1))
			for i in 5:
				_b(k, Vector3(0.04, 0.38, 0.03), Color(0.24, 0.25, 0.29), Vector3(-0.2 + i * 0.1, 0.27, 0.13))
				_b(k, Vector3(0.012, 0.34, 0.012), cool, Vector3(-0.2 + i * 0.1, 0.27, 0.148))
			k.torus(0.21, 0.02, Pal.BRASS, MeshKit.at(0, 0.58, -0.1), 14, 3)
			k.cyl(0.2, 0.06, Color(0.12, 0.13, 0.15), MeshKit.at(0, 0.52, -0.1), 12)
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(sx * 0.31, 0.12, -0.2), Vector3(sx * 0.4, 0.12, -0.2), 0.04, cool)
				SourceArt.ln(k, Vector3(sx * 0.4, 0.12, -0.2), Vector3(sx * 0.4, 0.42, -0.2), 0.04, cool)
				SourceArt.ln(k, Vector3(sx * 0.4, 0.42, -0.2), Vector3(sx * 0.31, 0.42, -0.2), 0.04, cool)
				_b(k, Vector3(0.06, 0.06, 0.06), Pal.BRASS, Vector3(sx * 0.4, 0.12, -0.2))
				_b(k, Vector3(0.06, 0.06, 0.06), Pal.BRASS, Vector3(sx * 0.4, 0.42, -0.2))
			_pad(k, 4, 0.34, Vector3(0, 0, 0.36))


# ---------------------------------------------------------------- silicon

static func _silicon(k: MeshKit, t: int) -> void:
	var hot := _lit(Color(1.0, 0.6, 0.3), 0.35)
	match t:
		0:
			# a backyard brick kiln with a glowing mouth and a stove pipe
			for j in 4:
				for i in 3:
					var off := 0.06 if j % 2 else 0.0
					_b(k, Vector3(0.15, 0.09, 0.4), Pal.BRICK if (i + j) % 2 else Pal.BRICK_DARK, Vector3(-0.15 + i * 0.15 + off - 0.03, 0.045 + j * 0.095, -0.08))
			_b(k, Vector3(0.48, 0.04, 0.42), Color(0.5, 0.48, 0.46), Vector3(0, 0.4, -0.08))
			_b(k, Vector3(0.16, 0.12, 0.02), hot, Vector3(0, 0.14, 0.13))
			_b(k, Vector3(0.2, 0.03, 0.04), Color(0.3, 0.3, 0.32), Vector3(0, 0.22, 0.14))
			k.cyl(0.05, 0.6, Color(0.36, 0.36, 0.38), MeshKit.at(0.14, 0.42, -0.16), 8)
			k.cyl(0.07, 0.03, Color(0.3, 0.3, 0.32), MeshKit.at(0.14, 1.0, -0.16), 8)
			# sand bucket, tongs, firewood
			k.cyl(0.08, 0.14, Color(0.86, 0.5, 0.2), MeshKit.at(-0.3, 0, 0.12), 8)
			k.sphere(0.07, Color(0.88, 0.8, 0.58), MeshKit.xf(Vector3(-0.3, 0.14, 0.12), Vector3.ZERO, Vector3(1, 0.4, 1)), 8, 3)
			SourceArt.ln(k, Vector3(0.3, 0.0, 0.1), Vector3(0.26, 0.35, -0.02), 0.015, Pal.STEEL_DARK)
			SourceArt.ln(k, Vector3(0.33, 0.0, 0.1), Vector3(0.27, 0.35, -0.02), 0.015, Pal.STEEL_DARK)
			for i in 3:
				k.cyl(0.03, 0.26, Pal.WOOD, MeshKit.xf(Vector3(-0.2, 0.03 + (i % 2) * 0.05, -0.24 + i * 0.05), Vector3(0, 0, 90)), 6)
		1:
			# a steel drum furnace on a stand, an A-frame hoist with a chain
			var steel := Color(0.62, 0.64, 0.68)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.03, 0.12, 0.03), Pal.STEEL_DARK, Vector3(sx * 0.16, 0.06, -0.06 + sz * 0.16))
			k.cyl(0.24, 0.32, steel, MeshKit.at(0, 0.12, -0.06), 12)
			for y in [0.16, 0.4]:
				k.cyl(0.245, 0.02, steel.darkened(0.25), MeshKit.at(0, y, -0.06), 12, 0.0, -1.0, false)
			k.cyl(0.2, 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.44, -0.06), 12)
			_b(k, Vector3(0.12, 0.08, 0.02), hot, Vector3(0, 0.28, 0.18))
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(sx * 0.36, 0, 0.0), Vector3(sx * 0.3, 1.2, -0.06), 0.035, Color(0.96, 0.76, 0.2))
				SourceArt.ln(k, Vector3(sx * 0.36, 0, -0.14), Vector3(sx * 0.3, 1.2, -0.06), 0.035, Color(0.96, 0.76, 0.2))
			_b(k, Vector3(0.66, 0.05, 0.05), Color(0.96, 0.76, 0.2), Vector3(0, 1.2, -0.06))
			_b(k, Vector3(0.1, 0.08, 0.08), Pal.STEEL_DARK, Vector3(0, 1.14, -0.06))
			_b(k, Vector3(0.012, 0.6, 0.012), Color(0.4, 0.4, 0.42), Vector3(0, 0.8, -0.06))
			_b(k, Vector3(0.18, 0.4, 0.12), Color(0.3, 0.32, 0.36), Vector3(-0.36, 0.2, 0.06))
			_b(k, Vector3(0.12, 0.05, 0.005), _lit(Color(0.6, 1.0, 0.62)), Vector3(-0.36, 0.32, 0.122))
			_b(k, Vector3(0.04, 0.04, 0.005), Color(0.9, 0.2, 0.2), Vector3(-0.36, 0.22, 0.122))
			_pad(k, 1, 0.3, Vector3(0.1, 0, 0.32))
		2:
			# a white puller: chamber with a teal band and a glowing port, tall mast
			var shell := Color(0.94, 0.95, 0.96)
			k.cyl(0.27, 0.42, shell, MeshKit.at(0, 0, -0.06), 12, 0.03)
			k.cyl(0.275, 0.05, _c(2, "accent"), MeshKit.at(0, 0.3, -0.06), 12, 0.0, -1.0, false)
			_b(k, Vector3(0.16, 0.12, 0.05), hot, Vector3(0, 0.18, 0.2))
			k.cyl(0.21, 0.06, Color(0.82, 0.84, 0.86), MeshKit.at(0, 0.42, -0.06), 12)
			k.cyl(0.03, 0.95, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0.48, -0.06), 8)
			_b(k, Vector3(0.16, 0.12, 0.16), shell, Vector3(0, 1.42, -0.06))
			_b(k, Vector3(0.165, 0.03, 0.165), _c(2, "accent"), Vector3(0, 1.38, -0.06))
			_b(k, Vector3(0.2, 0.52, 0.16), shell, Vector3(0.36, 0.26, -0.1))
			_b(k, Vector3(0.14, 0.1, 0.008), Color(0.2, 0.22, 0.26), Vector3(0.36, 0.42, -0.018))
			_b(k, Vector3(0.1, 0.05, 0.004), _lit(Color(0.42, 0.96, 0.9)), Vector3(0.36, 0.42, -0.012))
			# cleanroom curtain strips behind
			for i in 6:
				_b(k, Vector3(0.07, 0.6, 0.01), Color(0.86, 0.92, 0.96, 0.85), Vector3(-0.3 + i * 0.075, 0.3, -0.36))
			_b(k, Vector3(0.5, 0.03, 0.03), Color(0.86, 0.88, 0.9), Vector3(-0.11, 0.61, -0.36))
			_pad(k, 2, 0.3, Vector3(0.0, 0, 0.34))
		3:
			# a dark twin-chamber puller with a service platform and gas lines
			var dk := Color(0.34, 0.37, 0.42)
			k.cyl(0.26, 0.44, dk, MeshKit.at(0, 0, -0.06), 12)
			k.cyl(0.18, 0.3, dk.lightened(0.1), MeshKit.at(0, 0.44, -0.06), 12)
			k.cyl(0.265, 0.02, _lit(Color(0.45, 0.75, 1.0), 0.45), MeshKit.at(0, 0.36, -0.06), 12, 0.0, -1.0, false)
			_b(k, Vector3(0.14, 0.1, 0.05), hot, Vector3(0, 0.2, 0.19))
			k.cyl(0.035, 0.7, Color(0.5, 0.52, 0.56), MeshKit.at(0, 0.74, -0.06), 8)
			_b(k, Vector3(0.18, 0.16, 0.18), dk, Vector3(0, 1.46, -0.06))
			_b(k, Vector3(0.012, 0.12, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.4), Vector3(0.09, 1.46, 0.035))
			# service platform with rail and ladder on the left
			_b(k, Vector3(0.24, 0.025, 0.3), Color(0.4, 0.42, 0.46), Vector3(-0.38, 0.5, -0.1))
			SourceArt.ln(k, Vector3(-0.5, 0.78, -0.25), Vector3(-0.5, 0.78, 0.05), 0.02, Color(0.98, 0.8, 0.22))
			SourceArt.ln(k, Vector3(-0.5, 0.5, 0.05), Vector3(-0.5, 0.78, 0.05), 0.02, Color(0.98, 0.8, 0.22))
			SourceArt.ln(k, Vector3(-0.5, 0.5, -0.25), Vector3(-0.5, 0.78, -0.25), 0.02, Color(0.98, 0.8, 0.22))
			for i in 4:
				_b(k, Vector3(0.14, 0.015, 0.015), Color(0.5, 0.52, 0.56), Vector3(-0.38, 0.1 + i * 0.12, 0.06))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.015, 0.5, 0.015), Color(0.5, 0.52, 0.56), Vector3(-0.38 + sx * 0.07, 0.25, 0.06))
			# gas lines and a cabinet
			for i in 2:
				SourceArt.ln(k, Vector3(0.24, 0.2 + i * 0.1, -0.06), Vector3(0.4, 0.2 + i * 0.1, -0.2), 0.025, [Color(0.86, 0.86, 0.84), Color(0.36, 0.6, 0.86)][i])
			_b(k, Vector3(0.14, 0.56, 0.14), Color(0.24, 0.26, 0.3), Vector3(0.4, 0.28, -0.24))
			_b(k, Vector3(0.08, 0.04, 0.005), _lit(Color(0.45, 0.75, 1.0), 0.4), Vector3(0.4, 0.46, -0.168))
			_pad(k, 3, 0.3, Vector3(0.05, 0, 0.34))
		4:
			# graphite puller with brass rings and a glowing glass crucible
			var gr := Color(0.17, 0.18, 0.21)
			k.cyl(0.28, 0.12, gr, MeshKit.at(0, 0, -0.06), 12)
			k.cyl(0.24, 0.2, Color(1.0, 0.62, 0.3, 0.45), MeshKit.at(0, 0.12, -0.06), 12)
			k.cyl(0.28, 0.12, gr, MeshKit.at(0, 0.32, -0.06), 12)
			for y in [0.12, 0.32, 0.44]:
				k.torus(0.28, 0.014, Pal.BRASS, MeshKit.at(0, y, -0.06), 14, 3)
			for i in 6:
				var a := TAU * i / 6.0
				_b(k, Vector3(0.03, 0.2, 0.03), Pal.BRASS, Vector3(cos(a) * 0.26, 0.22, -0.06 + sin(a) * 0.26))
			k.cyl(0.03, 0.9, Pal.BRASS, MeshKit.at(0, 0.44, -0.06), 8)
			k.cyl(0.012, 0.86, _lit(Color(1.0, 0.86, 0.5), 0.35), MeshKit.at(0.0, 0.46, 0.0), 5)
			_b(k, Vector3(0.2, 0.1, 0.2), gr, Vector3(0, 1.38, -0.06))
			k.torus(0.13, 0.012, _lit(Color(1.0, 0.86, 0.5), 0.4), MeshKit.at(0, 1.44, -0.06), 12, 3)
			_b(k, Vector3(0.21, 0.015, 0.21), Pal.BRASS, Vector3(0, 1.33, -0.06))
			_pad(k, 4, 0.3, Vector3(0.0, 0, 0.36))


# ---------------------------------------------------------------- copper / rare

static func _rock(k: MeshKit, p: Vector3, s: Vector3, col: Color, yaw := 0.0) -> void:
	k.ellipsoid(s, col, MeshKit.xf(p, Vector3(0, yaw, 0)), 7, 4)


static func _copper(k: MeshKit, t: int) -> void:
	var ore := Color(0.84, 0.5, 0.3)
	var rock := Color(0.52, 0.5, 0.48)
	match t:
		0:
			# a hand-dug dirt mound, a pickaxe, a bucket of ore, a gold pan
			k.ellipsoid(Vector3(0.42, 0.3, 0.36), Pal.DIRT, MeshKit.at(0, 0.08, -0.08), 9, 5)
			_rock(k, Vector3(0.24, 0.05, 0.1), Vector3(0.14, 0.1, 0.12), rock)
			_rock(k, Vector3(-0.28, 0.04, 0.08), Vector3(0.1, 0.08, 0.1), rock.darkened(0.1))
			for i in 4:
				var a := TAU * i / 4.0 + 0.4
				_b(k, Vector3(0.07, 0.04, 0.06), ore, Vector3(cos(a) * 0.26, 0.24 + (i % 2) * 0.06, sin(a) * 0.2 - 0.08), Vector3(0, a * 57.3, 20))
			SourceArt.ln(k, Vector3(-0.2, 0.15, 0.0), Vector3(-0.36, 0.52, 0.0), 0.022, Pal.WOOD)
			_b(k, Vector3(0.24, 0.035, 0.035), Pal.STEEL_DARK, Vector3(-0.37, 0.52, 0.0), Vector3(0, 0, 20))
			k.cyl(0.08, 0.13, Color(0.6, 0.62, 0.64), MeshKit.at(0.32, 0, -0.22), 8, 0.0, 0.09)
			k.sphere(0.07, ore, MeshKit.xf(Vector3(0.32, 0.13, -0.22), Vector3.ZERO, Vector3(1, 0.5, 1)), 7, 3)
			k.cyl(0.1, 0.02, Color(0.4, 0.42, 0.44), MeshKit.at(-0.2, 0, 0.24), 10, 0.0, 0.13)
		1:
			# a timber-lined ore bin, a wheelbarrow, a shovel
			for sx in [-1.0, 1.0]:
				ArchKit.planks(k, MeshKit.xf(Vector3(sx * 0.3, 0, -0.08), Vector3(0, sx * 90, 0)), 0.5, 0.3, Pal.WOOD_LIGHT)
			ArchKit.planks(k, MeshKit.at(0, 0, -0.33), 0.62, 0.36, Pal.WOOD)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.05, 0.4, 0.05), Pal.WOOD_DARK, Vector3(sx * 0.3, 0.2, -0.33))
				_b(k, Vector3(0.05, 0.32, 0.05), Pal.WOOD_DARK, Vector3(sx * 0.3, 0.16, 0.17))
			k.ellipsoid(Vector3(0.28, 0.3, 0.24), rock, MeshKit.at(0, 0.06, -0.1), 9, 5)
			for i in 5:
				var a := TAU * i / 5.0
				_b(k, Vector3(0.06, 0.04, 0.05), ore, Vector3(cos(a) * 0.18, 0.26 + (i % 2) * 0.06, sin(a) * 0.14 - 0.1), Vector3(0, a * 57.3, 15))
			# wheelbarrow
			_b(k, Vector3(0.18, 0.1, 0.24), Color(0.3, 0.5, 0.36), Vector3(0.42, 0.18, 0.08), Vector3(10, 0, 0))
			k.cyl(0.05, 0.03, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(0.405, 0.05, 0.22), Vector3(0, 0, 90)), 8)
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(0.42 + sx * 0.07, 0.15, 0.0), Vector3(0.42 + sx * 0.08, 0.2, -0.18), 0.018, Pal.WOOD_DARK)
			SourceArt.ln(k, Vector3(-0.4, 0.0, 0.14), Vector3(-0.36, 0.5, -0.04), 0.02, Pal.WOOD)
			_b(k, Vector3(0.1, 0.12, 0.02), Pal.STEEL_DARK, Vector3(-0.405, 0.04, 0.16), Vector3(-20, 0, 0))
		2:
			# a white concrete ore bunker with a teal rim and a conveyor stub
			var white := Color(0.9, 0.9, 0.9)
			_b(k, Vector3(0.66, 0.24, 0.06), white, Vector3(0, 0.12, -0.36))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.06, 0.24, 0.44), white, Vector3(sx * 0.3, 0.12, -0.14))
				_b(k, Vector3(0.07, 0.03, 0.45), _c(2, "accent"), Vector3(sx * 0.3, 0.25, -0.14))
			_b(k, Vector3(0.67, 0.03, 0.07), _c(2, "accent"), Vector3(0, 0.25, -0.36))
			k.ellipsoid(Vector3(0.26, 0.3, 0.22), rock, MeshKit.at(0, 0.08, -0.14), 9, 5)
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				_b(k, Vector3(0.06, 0.04, 0.05), ore, Vector3(cos(a) * 0.16, 0.28 + (i % 2) * 0.06, sin(a) * 0.12 - 0.14), Vector3(0, a * 57.3, 15))
			# conveyor stub feeding in from the side
			_b(k, Vector3(0.12, 0.03, 0.5), Color(0.2, 0.21, 0.24), Vector3(0.44, 0.3, -0.2), Vector3(-18, 0, 0))
			for sz in [-1.0, 1.0]:
				_b(k, Vector3(0.03, 0.3, 0.03), Color(0.82, 0.84, 0.86), Vector3(0.44, 0.15, -0.2 + sz * 0.2))
			# a hard hat on a post
			_b(k, Vector3(0.03, 0.42, 0.03), Color(0.82, 0.84, 0.86), Vector3(-0.42, 0.21, 0.1))
			k.sphere(0.06, Color(0.98, 0.98, 0.98), MeshKit.xf(Vector3(-0.42, 0.44, 0.1), Vector3.ZERO, Vector3(1, 0.7, 1)), 8, 4)
			_pad(k, 2, 0.32, Vector3(0, 0, 0.32))
		3:
			# a steel ore hopper with grizzly bars, a jaw crusher, a chute
			var dk := Color(0.36, 0.39, 0.44)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.04, 0.3, 0.04), Color(0.98, 0.8, 0.22), Vector3(sx * 0.26, 0.15, -0.12 + sz * 0.2))
			k.cyl(0.36, 0.24, dk, MeshKit.xf(Vector3(0, 0.3, -0.12), Vector3(0, 45, 0)), 4, 0.0, 0.2)
			k.cyl(0.36, 0.02, dk.darkened(0.2), MeshKit.xf(Vector3(0, 0.52, -0.12), Vector3(0, 45, 0)), 4)
			k.ellipsoid(Vector3(0.22, 0.12, 0.2), rock, MeshKit.at(0, 0.5, -0.12), 8, 4)
			for i in 6:
				_b(k, Vector3(0.012, 0.02, 0.48), Color(0.6, 0.62, 0.66), Vector3(-0.15 + i * 0.06, 0.55, -0.12))
			_b(k, Vector3(0.22, 0.16, 0.2), Color(0.24, 0.26, 0.3), Vector3(0, 0.14, -0.12))
			_b(k, Vector3(0.18, 0.02, 0.24), Color(0.5, 0.52, 0.56), Vector3(0, 0.12, 0.08), Vector3(-25, 0, 0))
			_b(k, Vector3(0.22, 0.015, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0, 0.2, -0.016))
			for i in 4:
				_b(k, Vector3(0.05, 0.03, 0.04), ore, Vector3(-0.08 + i * 0.05, 0.6, -0.12 + (i % 2) * 0.06))
			_pad(k, 3, 0.32, Vector3(0, 0, 0.34))
		4:
			# a graphite ring frame holding a rock with glowing veins, a laser arm
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.6, 0.08, 0.5), gr, Vector3(0, 0.04, -0.1))
			_b(k, Vector3(0.62, 0.015, 0.52), Pal.BRASS, Vector3(0, 0.085, -0.1))
			k.ellipsoid(Vector3(0.22, 0.24, 0.2), Color(0.3, 0.28, 0.27), MeshKit.at(0, 0.2, -0.1), 8, 5)
			for i in 7:
				var a := TAU * i / 7.0
				_b(k, Vector3(0.05, 0.11, 0.025), _lit(ore.lightened(0.15), 0.4), Vector3(cos(a) * 0.19, 0.22 + (i % 3) * 0.06, -0.1 + sin(a) * 0.17), Vector3(0, -a * 57.3, 25))
			k.torus(0.32, 0.02, Pal.BRASS, MeshKit.xf(Vector3(0, 0.32, -0.1), Vector3(90, 0, 0)), 16, 3)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.04, 0.3, 0.06), gr, Vector3(sx * 0.32, 0.18, -0.1))
			# laser arm
			_b(k, Vector3(0.05, 0.6, 0.05), gr, Vector3(0.34, 0.38, -0.32))
			SourceArt.ln(k, Vector3(0.34, 0.68, -0.32), Vector3(0.1, 0.6, -0.16), 0.04, gr)
			_b(k, Vector3(0.05, 0.05, 0.05), Pal.BRASS, Vector3(0.1, 0.6, -0.16))
			SourceArt.ln(k, Vector3(0.1, 0.58, -0.16), Vector3(0.04, 0.42, -0.1), 0.012, _lit(Color(1.0, 0.5, 0.3), 0.3))
			_pad(k, 4, 0.32, Vector3(0, 0, 0.34))


static func _rare(k: MeshKit, t: int) -> void:
	var cs := [Color(0.76, 0.48, 0.86), Color(0.5, 0.82, 0.78), Color(0.94, 0.56, 0.72), Color(0.62, 0.4, 0.88)]
	var rock := Color(0.46, 0.44, 0.46)
	var glow := 0.85 - t * 0.1
	match t:
		0:
			# crystals poking out of a rock, a lantern, a sieve
			k.ellipsoid(Vector3(0.4, 0.16, 0.34), rock, MeshKit.at(0, 0.02, -0.05), 8, 4)
			_rock(k, Vector3(0.28, 0.04, 0.14), Vector3(0.12, 0.1, 0.1), rock.lightened(0.05))
			for i in 4:
				var a := TAU * i / 4.0 + 0.3
				k.cone(0.06, 0.24 + (i % 2) * 0.1, Items.lit(cs[i % 4], glow), MeshKit.xf(Vector3(cos(a) * 0.14, 0.08, sin(a) * 0.12 - 0.05), Vector3(sin(a) * 22, 0, cos(a) * 22)), 5)
			k.cone(0.08, 0.42, Items.lit(cs[0], glow), MeshKit.at(0, 0.08, -0.08), 5)
			_b(k, Vector3(0.08, 0.1, 0.08), Color(0.3, 0.3, 0.32), Vector3(-0.32, 0.05, 0.14))
			_b(k, Vector3(0.06, 0.06, 0.06), _lit(Color(1.0, 0.82, 0.5), 0.4), Vector3(-0.32, 0.13, 0.14))
			k.cyl(0.12, 0.04, Pal.WOOD, MeshKit.at(0.26, 0, -0.26), 10)
			_b(k, Vector3(0.18, 0.005, 0.18), Color(0.5, 0.52, 0.54), Vector3(0.26, 0.035, -0.26))
		1:
			# a crystal rock in a steel tray, a sieve frame, a magnifier lamp
			var steel := Color(0.62, 0.64, 0.68)
			_b(k, Vector3(0.6, 0.04, 0.46), steel, Vector3(0, 0.25, -0.08))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.03, 0.25, 0.03), Pal.STEEL_DARK, Vector3(sx * 0.27, 0.125, -0.08 + sz * 0.2))
			for sz in [-1.0, 1.0]:
				_b(k, Vector3(0.6, 0.06, 0.02), steel, Vector3(0, 0.3, -0.08 + sz * 0.22))
			k.ellipsoid(Vector3(0.24, 0.1, 0.18), rock, MeshKit.at(0, 0.27, -0.08), 8, 4)
			for i in 5:
				var a := TAU * i / 5.0
				k.cone(0.05, 0.18 + (i % 2) * 0.08, Items.lit(cs[i % 4], glow), MeshKit.xf(Vector3(cos(a) * 0.1, 0.3, sin(a) * 0.08 - 0.08), Vector3(sin(a) * 20, 0, cos(a) * 20)), 5)
			k.cone(0.06, 0.3, Items.lit(cs[3], glow), MeshKit.at(0, 0.3, -0.08), 5)
			_b(k, Vector3(0.04, 0.5, 0.04), Pal.STEEL_DARK, Vector3(0.32, 0.25, -0.28))
			SourceArt.ln(k, Vector3(0.32, 0.5, -0.28), Vector3(0.18, 0.6, -0.12), 0.025, Pal.STEEL_DARK)
			k.torus(0.06, 0.012, Color(0.96, 0.76, 0.2), MeshKit.xf(Vector3(0.18, 0.58, -0.12), Vector3(20, 0, 0)), 10, 3)
			_b(k, Vector3(0.3, 0.12, 0.2), Color(0.96, 0.76, 0.2), Vector3(-0.3, 0.06, 0.16), Vector3(0, 10, 0))
			_pad(k, 1, 0.3, Vector3(0.05, 0, 0.34))
		2:
			# a white lab bench with a glass bell jar of crystals
			var white := Color(0.94, 0.95, 0.96)
			_b(k, Vector3(0.66, 0.36, 0.44), white, Vector3(0, 0.18, -0.08))
			_b(k, Vector3(0.68, 0.04, 0.46), _c(2, "accent"), Vector3(0, 0.38, -0.08))
			for i in 2:
				_b(k, Vector3(0.28, 0.24, 0.008), white.darkened(0.06), Vector3(-0.16 + i * 0.32, 0.17, 0.142))
				_b(k, Vector3(0.08, 0.015, 0.012), Color(0.6, 0.62, 0.66), Vector3(-0.16 + i * 0.32, 0.25, 0.15))
			k.ellipsoid(Vector3(0.16, 0.05, 0.13), rock, MeshKit.at(0, 0.4, -0.08), 8, 3)
			for i in 5:
				var a := TAU * i / 5.0
				k.cone(0.04, 0.14 + (i % 2) * 0.06, Items.lit(cs[i % 4], glow), MeshKit.xf(Vector3(cos(a) * 0.07, 0.42, sin(a) * 0.06 - 0.08), Vector3(sin(a) * 18, 0, cos(a) * 18)), 5)
			k.cyl(0.18, 0.3, Color(0.7, 0.88, 0.94, 0.8), MeshKit.at(0, 0.4, -0.08), 12, 0.0, 0.16)
			k.sphere(0.16, Color(0.7, 0.88, 0.94, 0.8), MeshKit.xf(Vector3(0, 0.7, -0.08), Vector3.ZERO, Vector3(1, 0.5, 1)), 12, 4)
			_b(k, Vector3(0.1, 0.12, 0.08), white, Vector3(0.24, 0.46, -0.16))
			_b(k, Vector3(0.06, 0.04, 0.004), _lit(Color(0.42, 0.96, 0.9)), Vector3(0.24, 0.48, -0.118))
			_pad(k, 2, 0.32, Vector3(0, 0, 0.34))
		3:
			# crystals in a solvent tank in a dark frame, pipes, a drill
			var dk := Color(0.32, 0.35, 0.4)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.04, 0.62, 0.04), dk, Vector3(sx * 0.28, 0.31, -0.1 + sz * 0.2))
			_b(k, Vector3(0.6, 0.04, 0.44), dk, Vector3(0, 0.62, -0.1))
			_b(k, Vector3(0.6, 0.04, 0.44), dk, Vector3(0, 0.04, -0.1))
			_b(k, Vector3(0.48, 0.28, 0.34), Color(0.6, 0.4, 0.86, 0.6), Vector3(0, 0.2, -0.1))
			for i in 5:
				var a := TAU * i / 5.0
				k.cone(0.04, 0.2 + (i % 2) * 0.08, Items.lit(cs[i % 4], glow), MeshKit.xf(Vector3(cos(a) * 0.12, 0.34, sin(a) * 0.08 - 0.1), Vector3(sin(a) * 18, 0, cos(a) * 18)), 5)
			_b(k, Vector3(0.6, 0.015, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0, 0.6, 0.12))
			_b(k, Vector3(0.06, 0.18, 0.06), Color(0.98, 0.8, 0.22), Vector3(0, 0.5, -0.1))
			k.cone(0.03, 0.08, Color(0.6, 0.62, 0.66), MeshKit.xf(Vector3(0, 0.41, -0.1), Vector3(180, 0, 0)), 6)
			for i in 2:
				SourceArt.ln(k, Vector3(-0.24, 0.3 + i * 0.1, -0.3), Vector3(-0.4, 0.3 + i * 0.1, -0.3), 0.03, [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84)][i])
				SourceArt.ln(k, Vector3(-0.4, 0.3 + i * 0.1, -0.3), Vector3(-0.4, 0.0, -0.3), 0.03, [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84)][i])
			_pad(k, 3, 0.32, Vector3(0, 0, 0.34))
		4:
			# a floating crystal cluster over a graphite plinth with a brass halo
			var gr := Color(0.17, 0.18, 0.21)
			k.cyl(0.26, 0.12, gr, MeshKit.at(0, 0, -0.08), 8)
			k.cyl(0.2, 0.08, gr.lightened(0.05), MeshKit.at(0, 0.12, -0.08), 8)
			k.cyl(0.265, 0.015, Pal.BRASS, MeshKit.at(0, 0.12, -0.08), 8)
			k.cyl(0.18, 0.015, _lit(Color(0.76, 0.48, 0.86), 0.4), MeshKit.at(0, 0.2, -0.08), 8)
			for i in 6:
				var a := TAU * i / 6.0 + 0.3
				var r := 0.08 + (i % 2) * 0.06
				k.cone(0.05, 0.22 + (i % 3) * 0.08, Items.lit(cs[i % 4], 0.5), MeshKit.xf(Vector3(cos(a) * r, 0.3, sin(a) * r * 0.8 - 0.08), Vector3(sin(a) * 22, 0, cos(a) * 22)), 5)
			k.cone(0.07, 0.42, Items.lit(cs[0], 0.5), MeshKit.at(0, 0.3, -0.08), 5)
			k.cone(0.07, 0.12, Items.lit(cs[0], 0.5), MeshKit.xf(Vector3(0, 0.3, -0.08), Vector3(180, 0, 0)), 5)
			k.torus(0.3, 0.015, Pal.BRASS, MeshKit.xf(Vector3(0, 0.45, -0.08), Vector3(14, 0, 8)), 16, 3)
			for i in 3:
				var a := TAU * i / 3.0
				_b(k, Vector3(0.025, 0.36, 0.025), Pal.BRASS, Vector3(cos(a) * 0.24, 0.27, -0.08 + sin(a) * 0.24))
			_pad(k, 4, 0.32, Vector3(0, 0, 0.36))


# ---------------------------------------------------------------- desks

static func _code(k: MeshKit, t: int) -> void:
	var acc := Color(0.5, 0.42, 0.78)
	match t:
		0:
			# an old door on two sawhorses, a laptop, a lamp, a crate for a stool
			_b(k, Vector3(0.84, 0.04, 0.44), Color(0.74, 0.6, 0.44), Vector3(0, 0.54, -0.04), Vector3(0, 0, 1))
			_b(k, Vector3(0.04, 0.012, 0.06), Pal.BRASS, Vector3(-0.38, 0.565, 0.1))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.06, 0.05, 0.4), Pal.WOOD, Vector3(sx * 0.3, 0.495, -0.04))
				for sz in [-1.0, 1.0]:
					SourceArt.ln(k, Vector3(sx * 0.3, 0.48, -0.04), Vector3(sx * 0.3 + sz * 0.06, 0.0, -0.04 + sz * 0.16), 0.03, Pal.WOOD)
			_b(k, Vector3(0.28, 0.015, 0.18), Color(0.3, 0.3, 0.32), Vector3(-0.06, 0.567, 0.04))
			_b(k, Vector3(0.28, 0.18, 0.012), Color(0.3, 0.3, 0.32), Vector3(-0.06, 0.66, -0.06), Vector3(-14, 0, 0))
			for i in 4:
				_b(k, Vector3(0.08 + (i % 3) * 0.04, 0.012, 0.004), _lit(acc.lightened(0.3), 0.5), Vector3(-0.14 + (i % 3) * 0.02, 0.71 - i * 0.03, -0.05), Vector3(-14, 0, 0))
			# desk lamp
			_b(k, Vector3(0.08, 0.015, 0.08), Color(0.2, 0.2, 0.22), Vector3(-0.32, 0.567, -0.16))
			SourceArt.ln(k, Vector3(-0.32, 0.57, -0.16), Vector3(-0.3, 0.76, -0.12), 0.015, Color(0.2, 0.2, 0.22))
			SourceArt.ln(k, Vector3(-0.3, 0.76, -0.12), Vector3(-0.22, 0.72, -0.04), 0.015, Color(0.2, 0.2, 0.22))
			k.cyl(0.04, 0.05, Color(0.86, 0.3, 0.26), MeshKit.xf(Vector3(-0.22, 0.72, -0.04), Vector3(160, 0, 0)), 8)
			# cans and a crate stool
			for i in 3:
				k.cyl(0.018, 0.06, [Color(0.3, 0.8, 0.4), Color(0.9, 0.3, 0.3), Color(0.3, 0.5, 0.9)][i], MeshKit.at(0.3 - i * 0.04, 0.56, -0.12 + (i % 2) * 0.04), 6)
			_crate(k, Vector3(0, 0, 0.32), Vector3(0.22, 0.26, 0.2), Color(0.72, 0.6, 0.42))
			SourceArt.ln(k, Vector3(0.1, 0.56, -0.2), Vector3(0.2, 0.01, -0.3), 0.012, Color(0.92, 0.5, 0.2))
		1:
			# a steel workbench with a pegboard, dual monitors, a mesh chair
			var steel := Color(0.42, 0.44, 0.48)
			_b(k, Vector3(0.86, 0.06, 0.46), Color(0.62, 0.5, 0.36), Vector3(0, 0.55, -0.04))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.04, 0.52, 0.04), steel, Vector3(sx * 0.4, 0.26, -0.04 + sz * 0.2))
			_b(k, Vector3(0.8, 0.03, 0.4), steel, Vector3(0, 0.14, -0.04))
			_b(k, Vector3(0.86, 0.5, 0.025), Color(0.82, 0.74, 0.6), Vector3(0, 0.83, -0.28))
			for i in 7:
				for j in 4:
					_b(k, Vector3(0.012, 0.012, 0.005), Color(0.5, 0.42, 0.32), Vector3(-0.36 + i * 0.12, 0.64 + j * 0.12, -0.265))
			_b(k, Vector3(0.03, 0.14, 0.02), Color(0.86, 0.3, 0.26), Vector3(0.34, 0.86, -0.26), Vector3(0, 0, 20))
			_b(k, Vector3(0.12, 0.03, 0.02), Pal.STEEL_DARK, Vector3(0.28, 0.98, -0.26))
			_monitor(k, Vector3(-0.17, 0.58, -0.12), 0.3, 0.2, Color(0.16, 0.17, 0.2), acc.lightened(0.3), 10)
			_monitor(k, Vector3(0.15, 0.58, -0.12), 0.3, 0.2, Color(0.16, 0.17, 0.2), Color(0.6, 1.0, 0.62), -10)
			_b(k, Vector3(0.3, 0.015, 0.1), Color(0.24, 0.25, 0.28), Vector3(-0.04, 0.587, 0.08))
			_b(k, Vector3(0.1, 0.012, 0.06), Color(0.98, 0.84, 0.3), Vector3(0.3, 0.586, 0.06))
			_chair(k, Vector3(-0.36, 0, 0.3), Color(0.26, 0.27, 0.3), steel, 35)
		2:
			# a white desk with a teal edge, a big monitor, a plant
			var white := Color(0.95, 0.95, 0.96)
			_b(k, Vector3(0.86, 0.04, 0.46), white, Vector3(0, 0.56, -0.04))
			_b(k, Vector3(0.87, 0.015, 0.47), _c(2, "accent"), Vector3(0, 0.535, -0.04))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.04, 0.52, 0.42), white.darkened(0.04), Vector3(sx * 0.39, 0.26, -0.04))
			_b(k, Vector3(0.74, 0.22, 0.02), white.darkened(0.06), Vector3(0, 0.38, -0.24))
			_monitor(k, Vector3(-0.04, 0.58, -0.14), 0.5, 0.28, Color(0.86, 0.88, 0.9), acc.lightened(0.3))
			_b(k, Vector3(0.32, 0.012, 0.1), Color(0.92, 0.93, 0.94), Vector3(-0.04, 0.586, 0.08))
			k.cyl(0.05, 0.1, Color(0.92, 0.93, 0.94), MeshKit.at(0.34, 0.58, -0.16), 8)
			k.sphere(0.08, Color(0.42, 0.6, 0.36), MeshKit.xf(Vector3(0.34, 0.72, -0.16), Vector3.ZERO, Vector3(1, 1.2, 1)), 8, 4)
			k.cyl(0.03, 0.08, _c(2, "accent"), MeshKit.at(0.26, 0.58, 0.04), 8)
			_chair(k, Vector3(-0.36, 0, 0.3), Color(0.94, 0.95, 0.96), _c(2, "accent"), 35)
		3:
			# a dark standing desk, three monitors of glowing code, LED underglow
			var dk := Color(0.22, 0.24, 0.28)
			_b(k, Vector3(0.88, 0.04, 0.46), dk, Vector3(0, 0.6, -0.04))
			_b(k, Vector3(0.88, 0.012, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.4), Vector3(0, 0.575, 0.19))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.06, 0.58, 0.06), Color(0.3, 0.32, 0.36), Vector3(sx * 0.34, 0.29, -0.04))
				_b(k, Vector3(0.08, 0.03, 0.42), Color(0.3, 0.32, 0.36), Vector3(sx * 0.34, 0.015, -0.04))
			_b(k, Vector3(0.04, 0.5, 0.04), Color(0.3, 0.32, 0.36), Vector3(0, 0.33, -0.24))
			_monitor(k, Vector3(0, 0.62, -0.16), 0.32, 0.22, Color(0.12, 0.13, 0.15), Color(0.45, 0.75, 1.0))
			_monitor(k, Vector3(-0.32, 0.62, -0.1), 0.28, 0.22, Color(0.12, 0.13, 0.15), acc.lightened(0.3), 25)
			_monitor(k, Vector3(0.32, 0.62, -0.1), 0.28, 0.22, Color(0.12, 0.13, 0.15), Color(0.6, 1.0, 0.62), -25)
			_b(k, Vector3(0.34, 0.015, 0.11), Color(0.12, 0.13, 0.15), Vector3(0, 0.627, 0.08))
			_b(k, Vector3(0.3, 0.004, 0.08), _lit(acc.lightened(0.2), 0.6), Vector3(0, 0.636, 0.08))
			_b(k, Vector3(0.1, 0.1, 0.1), Color(0.14, 0.15, 0.18), Vector3(-0.3, 0.05, -0.16))
			_b(k, Vector3(0.012, 0.08, 0.004), _lit(Color(0.45, 0.75, 1.0), 0.4), Vector3(-0.3, 0.05, -0.108))
		4:
			# a graphite desk with brass edges and a curved glowing holo screen
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.86, 0.05, 0.44), gr, Vector3(0, 0.56, -0.04))
			_b(k, Vector3(0.87, 0.015, 0.45), Pal.BRASS, Vector3(0, 0.59, -0.04))
			_b(k, Vector3(0.5, 0.5, 0.3), gr.lightened(0.04), Vector3(0, 0.27, -0.1))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.015, 0.5, 0.31), Pal.BRASS, Vector3(sx * 0.25, 0.27, -0.1))
			for i in 3:
				var a := (i - 1) * 28.0
				var tf := MeshKit.xf(Vector3(sin(deg_to_rad(a)) * 0.34, 0.8, -0.04 - cos(deg_to_rad(a)) * 0.24), Vector3(0, -a, 0))
				k.box(Vector3(0.26, 0.24, 0.008), Color(0.42, 0.9, 1.0, 0.5), tf)
				k.box(Vector3(0.27, 0.012, 0.012), Pal.BRASS, tf * MeshKit.at(0, -0.125, 0))
				for j in 4:
					k.box(Vector3(0.08 + (j % 3) * 0.04, 0.012, 0.004), Color(1.0, 0.86, 0.5, 0.4), tf * MeshKit.at(-0.06 + (j % 2) * 0.03, 0.08 - j * 0.045, 0.008))
			_b(k, Vector3(0.012, 0.16, 0.012), Pal.BRASS, Vector3(0, 0.66, -0.26))
			_b(k, Vector3(0.3, 0.008, 0.1), _lit(Color(0.42, 0.9, 1.0), 0.55), Vector3(0, 0.6, 0.08))
			k.cyl(0.1, 0.3, gr, MeshKit.at(-0.34, 0, 0.3), 8)
			k.cyl(0.105, 0.015, Pal.BRASS, MeshKit.at(-0.34, 0.3, 0.3), 8)


static func _labels(k: MeshKit, t: int) -> void:
	var tags := [Color(0.98, 0.88, 0.4), Color(0.6, 0.86, 0.96), Color(0.98, 0.7, 0.7), Color(0.7, 0.92, 0.66)]
	match t:
		0:
			# a folding table of photos and sticky notes, a stool, a lamp
			_b(k, Vector3(0.76, 0.03, 0.44), Color(0.86, 0.84, 0.78), Vector3(0, 0.55, -0.04))
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(sx * 0.3, 0.0, -0.22), Vector3(sx * 0.3, 0.54, 0.14), 0.02, Color(0.3, 0.32, 0.34))
				SourceArt.ln(k, Vector3(sx * 0.3, 0.0, 0.14), Vector3(sx * 0.3, 0.54, -0.22), 0.02, Color(0.3, 0.32, 0.34))
			for i in 6:
				_b(k, Vector3(0.1, 0.006 + (i % 3) * 0.01, 0.08), Color(0.95, 0.95, 0.92) if i % 2 else Color(0.5, 0.6, 0.7), Vector3(-0.3 + i * 0.1, 0.57, -0.14 + (i % 2) * 0.08), Vector3(0, i * 17 % 30 - 15, 0))
			for i in 8:
				_b(k, Vector3(0.05, 0.004, 0.05), tags[i % 4], Vector3(-0.32 + i * 0.07, 0.568, 0.1 - (i % 3) * 0.03), Vector3(0, i * 23 % 40 - 20, 0))
			_b(k, Vector3(0.16, 0.12, 0.12), Color(0.72, 0.6, 0.42), Vector3(0.3, 0.63, -0.12))
			k.cyl(0.11, 0.3, Pal.WOOD, MeshKit.at(0.34, 0, 0.3), 6)
			_b(k, Vector3(0.012, 0.25, 0.012), Color(0.2, 0.2, 0.22), Vector3(-0.32, 0.69, -0.2))
			k.cyl(0.05, 0.05, _lit(Color(1.0, 0.82, 0.5), 0.4), MeshKit.xf(Vector3(-0.3, 0.8, -0.14), Vector3(150, 0, 0)), 8)
		1:
			# a steel table with a tablet on a stand, bins of tagged items, a printer
			var steel := Color(0.62, 0.64, 0.68)
			_b(k, Vector3(0.8, 0.04, 0.44), steel, Vector3(0, 0.55, -0.04))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.035, 0.54, 0.035), Pal.STEEL_DARK, Vector3(sx * 0.37, 0.27, -0.04 + sz * 0.19))
			for i in 3:
				_b(k, Vector3(0.22, 0.12, 0.3), [Color(0.26, 0.46, 0.78), Color(0.96, 0.76, 0.2), Color(0.78, 0.3, 0.26)][i], Vector3(-0.26 + i * 0.26, 0.2, -0.04))
				_b(k, Vector3(0.06, 0.04, 0.005), Color(0.95, 0.95, 0.92), Vector3(-0.26 + i * 0.26, 0.22, 0.112))
			_b(k, Vector3(0.03, 0.18, 0.03), Pal.STEEL_DARK, Vector3(-0.12, 0.66, -0.14))
			_b(k, Vector3(0.24, 0.17, 0.015), Color(0.14, 0.15, 0.18), Vector3(-0.12, 0.76, -0.12), Vector3(-18, 0, 0))
			_b(k, Vector3(0.21, 0.14, 0.004), _lit(Color(0.9, 0.95, 1.0), 0.55), Vector3(-0.12, 0.76, -0.11), Vector3(-18, 0, 0))
			_b(k, Vector3(0.16, 0.08, 0.12), Color(0.9, 0.9, 0.88), Vector3(0.24, 0.61, -0.12))
			_b(k, Vector3(0.1, 0.004, 0.08), Color(0.98, 0.98, 0.96), Vector3(0.24, 0.6, -0.03), Vector3(-10, 0, 0))
			_chair(k, Vector3(0.36, 0, 0.3), Color(0.26, 0.27, 0.3), Pal.STEEL_DARK, -35)
		2:
			# a white annotation pod: curved teal partition, tablet, plant
			var white := Color(0.95, 0.95, 0.96)
			_b(k, Vector3(0.8, 0.04, 0.42), white, Vector3(0, 0.56, -0.04))
			k.cyl(0.05, 0.54, white, MeshKit.at(0, 0, -0.04), 8)
			_b(k, Vector3(0.4, 0.02, 0.3), white.darkened(0.04), Vector3(0, 0.01, -0.04))
			for i in 5:
				var a := (i - 2) * 22.0
				_b(k, Vector3(0.2, 0.62, 0.03), _c(2, "accent") if i % 2 == 0 else white.darkened(0.05), Vector3(sin(deg_to_rad(a)) * 0.4, 0.31 + 0.3, -0.04 - cos(deg_to_rad(a)) * 0.28), Vector3(0, -a, 0))
			for i in 6:
				_b(k, Vector3(0.05, 0.05, 0.004), tags[i % 4], Vector3(-0.2 + i * 0.08, 0.86 - (i % 2) * 0.08, -0.305))
			_b(k, Vector3(0.26, 0.012, 0.18), Color(0.86, 0.88, 0.9), Vector3(-0.12, 0.586, -0.04), Vector3(-10, 0, 0))
			_b(k, Vector3(0.23, 0.004, 0.15), _lit(Color(0.42, 0.96, 0.9), 0.55), Vector3(-0.12, 0.594, -0.04), Vector3(-10, 0, 0))
			k.cyl(0.05, 0.1, white, MeshKit.at(0.32, 0.58, -0.14), 8)
			k.sphere(0.07, Color(0.42, 0.6, 0.36), MeshKit.xf(Vector3(0.32, 0.72, -0.14), Vector3.ZERO, Vector3(1, 1.3, 1)), 8, 4)
			_chair(k, Vector3(-0.36, 0, 0.3), Color(0.94, 0.95, 0.96), _c(2, "accent"), 35)
		3:
			# a conveyor workstation: boxes passing under a scanner arch
			var dk := Color(0.26, 0.28, 0.32)
			_b(k, Vector3(0.9, 0.06, 0.3), dk, Vector3(0, 0.5, -0.08))
			_b(k, Vector3(0.88, 0.012, 0.24), Color(0.12, 0.12, 0.14), Vector3(0, 0.536, -0.08))
			for i in 8:
				_b(k, Vector3(0.012, 0.02, 0.26), Color(0.4, 0.42, 0.46), Vector3(-0.42 + i * 0.12, 0.53, -0.08))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					_b(k, Vector3(0.04, 0.48, 0.04), Color(0.98, 0.8, 0.22), Vector3(sx * 0.38, 0.24, -0.08 + sz * 0.12))
			for i in 3:
				_b(k, Vector3(0.12, 0.1, 0.12), Color(0.72, 0.6, 0.42), Vector3(-0.3 + i * 0.3, 0.6, -0.08))
				_b(k, Vector3(0.05, 0.04, 0.004), tags[i], Vector3(-0.3 + i * 0.3, 0.6, -0.018))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.04, 0.36, 0.04), dk, Vector3(sx * 0.18, 0.7, -0.08))
			_b(k, Vector3(0.4, 0.06, 0.08), dk, Vector3(0, 0.88, -0.08))
			_b(k, Vector3(0.3, 0.012, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.35), Vector3(0, 0.85, -0.03))
			_b(k, Vector3(0.012, 0.3, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(-0.155, 0.68, -0.03))
			_b(k, Vector3(0.012, 0.3, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0.155, 0.68, -0.03))
			_monitor(k, Vector3(0.3, 0.53, 0.1), 0.2, 0.14, Color(0.12, 0.13, 0.15), Color(0.45, 0.75, 1.0), -20)
		4:
			# a graphite station with a glowing tag cloud and a brass scanner ring
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.8, 0.05, 0.42), gr, Vector3(0, 0.56, -0.04))
			_b(k, Vector3(0.81, 0.015, 0.43), Pal.BRASS, Vector3(0, 0.59, -0.04))
			_b(k, Vector3(0.6, 0.52, 0.2), gr.lightened(0.04), Vector3(0, 0.27, -0.12))
			k.torus(0.18, 0.018, Pal.BRASS, MeshKit.xf(Vector3(-0.1, 0.8, -0.1), Vector3(90, 0, 0)), 14, 3)
			k.torus(0.16, 0.008, _lit(Color(1.0, 0.86, 0.5), 0.4), MeshKit.xf(Vector3(-0.1, 0.8, -0.1), Vector3(90, 0, 0)), 14, 3)
			for i in 14:
				var a := i * 2.4
				var r := 0.12 + fposmod(i * 0.37, 1.0) * 0.22
				_b(k, Vector3(0.06, 0.04, 0.006), Items.lit(tags[i % 4], 0.45), Vector3(-0.1 + cos(a) * r, 0.8 + sin(a) * r * 0.6, -0.1 + fposmod(i * 0.21, 0.1)))
			_b(k, Vector3(0.012, 0.18, 0.012), Pal.BRASS, Vector3(-0.1, 0.68, -0.1))


static func _feedback(k: MeshKit, t: int) -> void:
	var up := Color(0.4, 0.78, 0.5)
	var down := Color(0.9, 0.44, 0.44)
	match t:
		0:
			# a cardboard suggestion box on a stool, a hand-painted smiley sign
			k.cyl(0.14, 0.4, Pal.WOOD, MeshKit.at(0, 0, -0.06), 6)
			_b(k, Vector3(0.26, 0.2, 0.22), Color(0.72, 0.6, 0.42), Vector3(0, 0.5, -0.06))
			_b(k, Vector3(0.12, 0.012, 0.03), Color(0.2, 0.18, 0.16), Vector3(0, 0.6, -0.06))
			_b(k, Vector3(0.16, 0.06, 0.004), Color(0.95, 0.95, 0.92), Vector3(0, 0.5, 0.052))
			_b(k, Vector3(0.025, 0.95, 0.025), Pal.WOOD_DARK, Vector3(-0.26, 0.475, -0.2))
			_b(k, Vector3(0.3, 0.24, 0.02), Color(0.94, 0.92, 0.86), Vector3(-0.26, 0.82, -0.18), Vector3(0, 10, 3))
			k.cyl(0.07, 0.006, Color(0.98, 0.84, 0.3), MeshKit.xf(Vector3(-0.26, 0.82, -0.165), Vector3(90, 10, 0)), 10)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.014, 0.014, 0.004), Color(0.2, 0.18, 0.16), Vector3(-0.26 + sx * 0.025, 0.84, -0.16))
			_b(k, Vector3(0.05, 0.01, 0.004), Color(0.2, 0.18, 0.16), Vector3(-0.26, 0.8, -0.16))
			for i in 4:
				_b(k, Vector3(0.05, 0.004, 0.04), Color(0.98, 0.88, 0.4) if i % 2 else Color(0.98, 0.7, 0.7), Vector3(0.2 + i * 0.04, 0.005, 0.1 - i * 0.05), Vector3(0, i * 30, 0))
			# the product sits up on a little shelf post
			_b(k, Vector3(0.025, 0.96, 0.025), Pal.WOOD_DARK, Vector3(0, 0.48, -0.2))
			_b(k, Vector3(0.18, 0.02, 0.18), Pal.WOOD, Vector3(0, 0.96, -0.08))
		1:
			# a steel kiosk post with a tablet and big thumbs buttons
			var steel := Color(0.62, 0.64, 0.68)
			_b(k, Vector3(0.4, 0.04, 0.34), steel, Vector3(0, 0.02, -0.06))
			_b(k, Vector3(0.12, 0.86, 0.1), Color(0.96, 0.76, 0.2), Vector3(0, 0.47, -0.1))
			_b(k, Vector3(0.38, 0.28, 0.06), Pal.STEEL_DARK, Vector3(0, 0.78, -0.04), Vector3(-15, 0, 0))
			_b(k, Vector3(0.32, 0.22, 0.01), _lit(Color(0.7, 0.9, 1.0), 0.55), Vector3(0, 0.78, -0.005), Vector3(-15, 0, 0))
			_b(k, Vector3(0.16, 0.03, 0.004), Color(0.2, 0.2, 0.22), Vector3(0, 0.82, 0.003), Vector3(-15, 0, 0))
			for sx in [-1.0, 1.0]:
				k.cyl(0.055, 0.04, up if sx < 0 else down, MeshKit.xf(Vector3(sx * 0.1, 0.5, -0.04), Vector3(90, 0, 0)), 10)
			_b(k, Vector3(0.1, 0.06, 0.06), Color(0.86, 0.86, 0.84), Vector3(0, 0.32, -0.03))
			_b(k, Vector3(0.06, 0.004, 0.08), Color(0.98, 0.98, 0.96), Vector3(0, 0.29, 0.02))
			_b(k, Vector3(0.24, 0.02, 0.2), steel, Vector3(0, 0.95, -0.08))
			_pad(k, 1, 0.3, Vector3(0, 0, 0.3))
		2:
			# a white rounded kiosk with a teal screen
			var shell := Color(0.96, 0.95, 0.94)
			_b(k, Vector3(0.5, 0.05, 0.4), Color(0.86, 0.88, 0.9), Vector3(0, 0.025, -0.05))
			k.rbox(Vector3(0.42, 0.9, 0.18), 0.06, shell, MeshKit.at(0, 0.5, -0.1))
			_b(k, Vector3(0.43, 0.04, 0.19), _c(2, "accent"), Vector3(0, 0.2, -0.1))
			_b(k, Vector3(0.34, 0.42, 0.02), Color(0.16, 0.17, 0.2), Vector3(0, 0.66, 0.0))
			_b(k, Vector3(0.2, 0.05, 0.01), _lit(Color(1.0, 0.6, 0.64), 0.45), Vector3(0, 0.78, 0.012))
			_b(k, Vector3(0.14, 0.04, 0.01), _lit(Color(0.42, 0.96, 0.9), 0.5), Vector3(-0.03, 0.66, 0.012))
			for i in 5:
				_b(k, Vector3(0.04, 0.04, 0.01), Color(0.98, 0.84, 0.3) if i < 4 else Color(0.5, 0.52, 0.56), Vector3(-0.1 + i * 0.05, 0.58, 0.012))
			for sx in [-1.0, 1.0]:
				k.cyl(0.05, 0.03, up if sx < 0 else down, MeshKit.xf(Vector3(sx * 0.09, 0.36, 0.0), Vector3(90, 0, 0)), 10)
			_b(k, Vector3(0.24, 0.02, 0.2), shell, Vector3(0, 0.96, -0.06))
			_pad(k, 2, 0.3, Vector3(0, 0, 0.3))
		3:
			# a dark screen totem with an emoji strip and blue LEDs
			var dk := Color(0.22, 0.24, 0.28)
			_b(k, Vector3(0.5, 0.06, 0.36), Color(0.16, 0.17, 0.2), Vector3(0, 0.03, -0.08))
			_b(k, Vector3(0.44, 0.94, 0.16), dk, Vector3(0, 0.5, -0.1))
			_b(k, Vector3(0.38, 0.58, 0.01), Color(0.1, 0.11, 0.14), Vector3(0, 0.6, -0.018))
			for i in 4:
				var w: float = [0.3, 0.2, 0.26, 0.14][i]
				_b(k, Vector3(w, 0.05, 0.006), _lit([up, Color(0.98, 0.84, 0.3), Color(0.45, 0.75, 1.0), down][i], 0.45), Vector3(-0.15 + w * 0.5, 0.8 - i * 0.1, -0.01))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.015, 0.94, 0.015), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(sx * 0.225, 0.5, -0.02))
			for sx in [-1.0, 1.0]:
				k.cyl(0.055, 0.03, up if sx < 0 else down, MeshKit.xf(Vector3(sx * 0.1, 0.24, -0.02), Vector3(90, 0, 0)), 10)
			_b(k, Vector3(0.28, 0.02, 0.22), dk, Vector3(0, 0.97, -0.06))
			_pad(k, 3, 0.3, Vector3(0, 0, 0.3))
		4:
			# a graphite totem with brass and a glowing heart ring on top
			var gr := Color(0.17, 0.18, 0.21)
			k.cyl(0.24, 0.08, gr, MeshKit.at(0, 0, -0.08), 8)
			k.cyl(0.245, 0.015, Pal.BRASS, MeshKit.at(0, 0.08, -0.08), 8)
			_b(k, Vector3(0.22, 0.8, 0.14), gr, Vector3(0, 0.48, -0.1))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.015, 0.8, 0.15), Pal.BRASS, Vector3(sx * 0.11, 0.48, -0.1))
			_b(k, Vector3(0.18, 0.5, 0.006), Color(1.0, 0.6, 0.64, 0.5), Vector3(0, 0.5, -0.028))
			for i in 4:
				_b(k, Vector3(0.12, 0.012, 0.004), Color(1.0, 0.86, 0.5, 0.4), Vector3(0, 0.36 + i * 0.09, -0.024))
			k.torus(0.16, 0.014, _lit(Color(1.0, 0.6, 0.64), 0.4), MeshKit.xf(Vector3(0, 1.05, 0.08), Vector3(90, 0, 0)), 16, 3)
			k.torus(0.18, 0.01, Pal.BRASS, MeshKit.xf(Vector3(0, 1.05, 0.08), Vector3(90, 0, 0)), 16, 3)
			_b(k, Vector3(0.012, 0.15, 0.012), Pal.BRASS, Vector3(0, 0.9, 0.0))
			_pad(k, 4, 0.3, Vector3(0, 0, 0.3))


static func _papers(k: MeshKit, t: int) -> void:
	var ink := [Color(0.3, 0.4, 0.8), Color(0.82, 0.3, 0.3), Color(0.2, 0.22, 0.26)]
	match t:
		0:
			# a chalkboard on a wooden easel, a crate of books, a stool
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(sx * 0.4, 0.0, -0.04), Vector3(sx * 0.34, 1.2, -0.16), 0.035, Pal.WOOD)
			SourceArt.ln(k, Vector3(0, 0.0, -0.44), Vector3(0, 1.18, -0.18), 0.03, Pal.WOOD)
			_b(k, Vector3(0.84, 0.58, 0.03), Color(0.2, 0.26, 0.22), Vector3(0, 0.88, -0.12), Vector3(-10, 0, 0))
			_b(k, Vector3(0.9, 0.04, 0.05), Pal.WOOD, Vector3(0, 0.57, -0.07))
			for i in 6:
				_b(k, Vector3(0.12 + (i * 37 % 5) * 0.04, 0.015, 0.006), Color(0.94, 0.94, 0.9), Vector3(-0.28 + (i % 2) * 0.3, 1.06 - (i / 2) * 0.11, -0.09), Vector3(-10, 0, 0))
			k.torus(0.05, 0.007, Color(0.94, 0.94, 0.9), MeshKit.xf(Vector3(0.28, 0.72, -0.075), Vector3(80, 0, 0)), 10, 3)
			_crate(k, Vector3(0.3, 0, 0.12), Vector3(0.24, 0.18, 0.2), Pal.WOOD_LIGHT)
			_books(k, Vector3(0.3, 0.18, 0.12), 3)
			k.cyl(0.1, 0.3, Pal.WOOD, MeshKit.at(-0.3, 0, 0.14), 6)
		1:
			# a rolling steel-framed whiteboard and a small filing cabinet
			var steel := Color(0.62, 0.64, 0.68)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.04, 1.24, 0.04), steel, Vector3(sx * 0.42, 0.66, -0.14))
				_b(k, Vector3(0.05, 0.03, 0.4), steel, Vector3(sx * 0.42, 0.06, -0.14))
				for sz in [-1.0, 1.0]:
					k.cyl(0.03, 0.04, Color(0.15, 0.15, 0.16), MeshKit.xf(Vector3(sx * 0.42 - 0.02, 0.03, -0.14 + sz * 0.17), Vector3(0, 0, 90)), 6)
			_b(k, Vector3(0.84, 0.6, 0.03), Color(0.96, 0.97, 0.98), Vector3(0, 0.94, -0.14))
			_b(k, Vector3(0.88, 0.64, 0.02), steel, Vector3(0, 0.94, -0.16))
			for i in 7:
				_b(k, Vector3(0.12 + (i * 37 % 5) * 0.04, 0.02, 0.008), ink[i % 3], Vector3(-0.28 + (i % 2) * 0.3, 1.14 - (i / 2) * 0.1, -0.122))
			k.torus(0.06, 0.008, ink[1], MeshKit.xf(Vector3(0.28, 0.78, -0.122), Vector3(90, 0, 0)), 10, 3)
			_b(k, Vector3(0.6, 0.03, 0.06), steel, Vector3(0, 0.63, -0.1))
			_b(k, Vector3(0.26, 0.5, 0.3), Color(0.5, 0.52, 0.56), Vector3(0.3, 0.25, 0.12))
			for j in 3:
				_b(k, Vector3(0.24, 0.005, 0.005), Color(0.36, 0.38, 0.42), Vector3(0.3, 0.12 + j * 0.15, 0.272))
				_b(k, Vector3(0.06, 0.015, 0.01), Color(0.8, 0.82, 0.84), Vector3(0.3, 0.17 + j * 0.15, 0.275))
			_books(k, Vector3(0.3, 0.5, 0.12), 2, 1)
		2:
			# a glass board with a teal frame and a white lectern
			var white := Color(0.95, 0.95, 0.96)
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.05, 1.3, 0.05), white, Vector3(sx * 0.44, 0.65, -0.14))
			_b(k, Vector3(0.84, 0.66, 0.02), Color(0.7, 0.88, 0.94, 0.8), Vector3(0, 0.95, -0.14))
			_b(k, Vector3(0.9, 0.04, 0.05), _c(2, "accent"), Vector3(0, 1.3, -0.14))
			_b(k, Vector3(0.9, 0.04, 0.05), _c(2, "accent"), Vector3(0, 0.6, -0.14))
			for i in 7:
				_b(k, Vector3(0.12 + (i * 37 % 5) * 0.04, 0.02, 0.006), ink[i % 3], Vector3(-0.28 + (i % 2) * 0.3, 1.16 - (i / 2) * 0.1, -0.125))
			_b(k, Vector3(0.22, 0.6, 0.18), white, Vector3(0.3, 0.3, 0.1))
			_b(k, Vector3(0.26, 0.03, 0.22), _c(2, "accent"), Vector3(0.3, 0.62, 0.1), Vector3(-15, 0, 0))
			_b(k, Vector3(0.12, 0.004, 0.16), Color(0.98, 0.98, 0.96), Vector3(0.3, 0.64, 0.1), Vector3(-15, 0, 0))
			k.cyl(0.05, 0.1, white, MeshKit.at(-0.34, 0, 0.16), 8)
			k.sphere(0.08, Color(0.42, 0.6, 0.36), MeshKit.at(-0.34, 0.16, 0.16), 8, 4)
		3:
			# a lab bench with a microscope under a dark LED screen board
			var dk := Color(0.22, 0.24, 0.28)
			_b(k, Vector3(0.86, 0.05, 0.36), Color(0.3, 0.32, 0.36), Vector3(0, 0.55, -0.12))
			_b(k, Vector3(0.82, 0.5, 0.32), dk, Vector3(0, 0.27, -0.12))
			for i in 3:
				_b(k, Vector3(0.24, 0.4, 0.005), dk.lightened(0.06), Vector3(-0.27 + i * 0.27, 0.27, 0.042))
			_b(k, Vector3(0.86, 0.52, 0.04), Color(0.12, 0.13, 0.15), Vector3(0, 1.06, -0.3))
			for i in 6:
				_b(k, Vector3(0.14 + (i * 37 % 5) * 0.04, 0.02, 0.006), _lit([Color(0.45, 0.75, 1.0), Color(0.98, 0.8, 0.22), Color(0.9, 0.95, 1.0)][i % 3], 0.45), Vector3(-0.24 + (i % 2) * 0.3, 1.22 - (i / 2) * 0.1, -0.278))
			_b(k, Vector3(0.88, 0.015, 0.015), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0, 0.79, -0.28))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.04, 0.5, 0.04), Color(0.3, 0.32, 0.36), Vector3(sx * 0.4, 0.82, -0.32))
			# microscope and flasks
			_b(k, Vector3(0.1, 0.03, 0.12), Color(0.9, 0.9, 0.88), Vector3(-0.2, 0.59, -0.1))
			SourceArt.ln(k, Vector3(-0.2, 0.6, -0.15), Vector3(-0.2, 0.76, -0.12), 0.03, Color(0.9, 0.9, 0.88))
			SourceArt.ln(k, Vector3(-0.2, 0.76, -0.12), Vector3(-0.2, 0.7, -0.06), 0.035, Color(0.24, 0.25, 0.28))
			for i in 3:
				k.cyl(0.03, 0.08, Color([0.42, 0.98, 0.5][i], 0.8, [0.98, 0.4, 0.6][i], 0.6), MeshKit.at(0.1 + i * 0.08, 0.575, -0.14), 6, 0.0, 0.012)
		4:
			# a graphite holo-board: glowing equations floating in a brass frame
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.9, 0.08, 0.3), gr, Vector3(0, 0.04, -0.14))
			_b(k, Vector3(0.91, 0.015, 0.31), Pal.BRASS, Vector3(0, 0.085, -0.14))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.05, 1.3, 0.06), gr, Vector3(sx * 0.44, 0.69, -0.14))
				_b(k, Vector3(0.015, 1.3, 0.065), Pal.BRASS, Vector3(sx * 0.42, 0.69, -0.14))
			_b(k, Vector3(0.9, 0.05, 0.06), Pal.BRASS, Vector3(0, 1.34, -0.14))
			_b(k, Vector3(0.8, 0.66, 0.006), Color(0.42, 0.9, 1.0, 0.75), Vector3(0, 0.96, -0.14))
			for i in 8:
				_b(k, Vector3(0.12 + (i * 37 % 5) * 0.04, 0.02, 0.006), Color(1.0, 0.86, 0.5, 0.4), Vector3(-0.26 + (i % 2) * 0.3, 1.2 - (i / 2) * 0.08, -0.13 + (i % 3) * 0.02))
			k.torus(0.07, 0.008, Color(1.0, 0.86, 0.5, 0.4), MeshKit.xf(Vector3(0.28, 0.72, -0.12), Vector3(90, 0, 0)), 12, 3)
			k.cyl(0.08, 0.5, gr, MeshKit.at(0.32, 0, 0.12), 8)
			k.cyl(0.1, 0.02, Pal.BRASS, MeshKit.at(0.32, 0.5, 0.12), 8)


static func _fiber(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a wooden cable drum on two sawhorses (the drum turns), a crank
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.05, 0.04, 0.42), Pal.WOOD, Vector3(sx * 0.27, 0.42, -0.05))
				for sz in [-1.0, 1.0]:
					SourceArt.ln(k, Vector3(sx * 0.27, 0.41, -0.05 + sz * 0.12), Vector3(sx * 0.33, 0.0, -0.05 + sz * 0.18), 0.03, Pal.WOOD)
			_b(k, Vector3(0.7, 0.012, 0.012), Pal.STEEL_DARK, Vector3(0, 0.42, -0.05))
			SourceArt.ln(k, Vector3(-0.04, 0.2, -0.05), Vector3(0.0, 0.015, 0.2), 0.02, Color(0.95, 0.55, 0.25))
			for i in 4:
				var a := i * 1.5
				SourceArt.ln(k, Vector3(cos(a) * 0.12, 0.015, 0.24 + sin(a) * 0.08), Vector3(cos(a + 1.5) * 0.12, 0.015, 0.24 + sin(a + 1.5) * 0.08), 0.02, Color(0.95, 0.55, 0.25))
			_b(k, Vector3(0.12, 0.08, 0.08), Color(0.8, 0.22, 0.2), Vector3(-0.34, 0.04, 0.16))
			_b(k, Vector3(0.18, 0.05, 0.03), Color(0.86, 0.6, 0.2), Vector3(0.34, 0.02, 0.2), Vector3(0, 30, 0))
		1:
			# a steel A-frame spool stand with a tensioner
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.05, 0.5, 0.05), Pal.STEEL_DARK, Vector3(sx * 0.27, 0.22, -0.15), Vector3(-12, 0, 0))
				_b(k, Vector3(0.05, 0.5, 0.05), Pal.STEEL_DARK, Vector3(sx * 0.27, 0.22, 0.05), Vector3(12, 0, 0))
				_b(k, Vector3(0.05, 0.05, 0.3), Color(0.96, 0.76, 0.2), Vector3(sx * 0.27, 0.12, -0.05))
			_b(k, Vector3(0.62, 0.05, 0.42), Color(0.32, 0.34, 0.4), Vector3(0, 0.025, -0.05))
			k.cyl(0.02, 0.6, Pal.STEEL, MeshKit.xf(Vector3(-0.3, 0.42, -0.05), Vector3(0, 0, -90)), 6)
			_b(k, Vector3(0.06, 0.3, 0.06), Color(0.3, 0.32, 0.36), Vector3(0.36, 0.15, 0.16))
			k.cyl(0.04, 0.08, Color(0.6, 0.62, 0.66), MeshKit.xf(Vector3(0.32, 0.3, 0.16), Vector3(0, 0, -90)), 8)
			SourceArt.ln(k, Vector3(0.0, 0.2, -0.05), Vector3(0.32, 0.3, 0.16), 0.01, Color(0.98, 0.62, 0.86))
			_pad(k, 1, 0.32, Vector3(0, 0, 0.34))
		2:
			# a white winder with a teal housing and a guide arm
			var white := Color(0.95, 0.95, 0.96)
			_b(k, Vector3(0.66, 0.06, 0.46), Color(0.88, 0.88, 0.88), Vector3(0, 0.03, -0.05))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.06, 0.48, 0.3), white, Vector3(sx * 0.3, 0.27, -0.05))
				_b(k, Vector3(0.065, 0.05, 0.305), _c(2, "accent"), Vector3(sx * 0.3, 0.12, -0.05))
			_b(k, Vector3(0.2, 0.36, 0.22), white, Vector3(0.0, 0.18, -0.3))
			_b(k, Vector3(0.14, 0.08, 0.004), Color(0.2, 0.22, 0.26), Vector3(0, 0.28, -0.188))
			_b(k, Vector3(0.1, 0.04, 0.004), _lit(Color(0.42, 0.96, 0.9)), Vector3(0, 0.28, -0.185))
			SourceArt.ln(k, Vector3(0.3, 0.5, -0.05), Vector3(0.3, 0.62, 0.15), 0.025, white)
			k.cyl(0.03, 0.06, _c(2, "accent"), MeshKit.xf(Vector3(0.27, 0.62, 0.15), Vector3(0, 0, -90)), 8)
			_pad(k, 2, 0.32, Vector3(0, 0, 0.36))
		3:
			# a dark spool machine with guide rollers, counter display, LEDs
			var dk := Color(0.26, 0.28, 0.32)
			_b(k, Vector3(0.7, 0.1, 0.5), dk, Vector3(0, 0.05, -0.05))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.07, 0.5, 0.34), dk.lightened(0.06), Vector3(sx * 0.31, 0.3, -0.05))
				_b(k, Vector3(0.012, 0.4, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(sx * 0.35, 0.3, 0.12))
			_b(k, Vector3(0.7, 0.012, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0, 0.1, 0.2))
			for i in 3:
				k.cyl(0.03, 0.14, Color(0.6, 0.62, 0.66), MeshKit.xf(Vector3(-0.07, 0.72 - i * 0.04, -0.3 + i * 0.12), Vector3(0, 0, -90)), 8)
			_b(k, Vector3(0.04, 0.72, 0.04), dk, Vector3(0.0, 0.36, -0.36))
			_b(k, Vector3(0.18, 0.1, 0.06), Color(0.12, 0.13, 0.15), Vector3(0.0, 0.66, -0.36))
			_b(k, Vector3(0.14, 0.05, 0.004), _lit(Color(0.98, 0.62, 0.86), 0.45), Vector3(0.0, 0.66, -0.328))
			_pad(k, 3, 0.32, Vector3(0, 0, 0.36))
		4:
			# a graphite frame with brass and a glowing spool
			var gr := Color(0.17, 0.18, 0.21)
			_b(k, Vector3(0.7, 0.08, 0.48), gr, Vector3(0, 0.04, -0.05))
			_b(k, Vector3(0.71, 0.015, 0.49), Pal.BRASS, Vector3(0, 0.085, -0.05))
			for sx in [-1.0, 1.0]:
				k.cyl(0.05, 0.42, gr, MeshKit.at(sx * 0.31, 0.08, -0.05), 8)
				k.sphere(0.07, Pal.BRASS, MeshKit.at(sx * 0.31, 0.42, -0.05), 8, 4)
				_b(k, Vector3(0.012, 0.3, 0.012), _lit(Color(0.98, 0.62, 0.86), 0.4), Vector3(sx * 0.31, 0.25, 0.0))
			k.torus(0.36, 0.012, Pal.BRASS, MeshKit.xf(Vector3(0, 0.42, -0.05), Vector3(0, 0, 90)), 18, 3)
			_pad(k, 4, 0.32, Vector3(0, 0, 0.36))


static func _experts(k: MeshKit, t: int) -> void:
	match t:
		0:
			# a camping chair, a cooler for a table, a lantern
			var fab := Color(0.26, 0.5, 0.36)
			for sx in [-1.0, 1.0]:
				SourceArt.ln(k, Vector3(-0.1 + sx * 0.2, 0.0, -0.24), Vector3(-0.1 + sx * 0.2, 0.3, 0.08), 0.02, Color(0.6, 0.62, 0.64))
				SourceArt.ln(k, Vector3(-0.1 + sx * 0.2, 0.0, 0.08), Vector3(-0.1 + sx * 0.2, 0.62, -0.26), 0.02, Color(0.6, 0.62, 0.64))
			_b(k, Vector3(0.4, 0.03, 0.3), fab, Vector3(-0.1, 0.24, -0.08), Vector3(-6, 0, 0))
			_b(k, Vector3(0.4, 0.34, 0.03), fab, Vector3(-0.1, 0.44, -0.24), Vector3(-12, 0, 0))
			k.cyl(0.03, 0.08, Color(0.9, 0.3, 0.26), MeshKit.at(-0.28, 0.3, 0.02), 6)
			_b(k, Vector3(0.28, 0.2, 0.2), Color(0.26, 0.46, 0.78), Vector3(0.24, 0.1, 0.0))
			_b(k, Vector3(0.29, 0.06, 0.21), Color(0.95, 0.95, 0.92), Vector3(0.24, 0.23, 0.0))
			_b(k, Vector3(0.2, 0.3, 0.2), Color(0.72, 0.6, 0.42), Vector3(0.24, 0.41, 0.0))
			_b(k, Vector3(0.06, 0.12, 0.06), Color(0.3, 0.3, 0.32), Vector3(0.3, 0.62, -0.06))
			_b(k, Vector3(0.05, 0.07, 0.05), _lit(Color(1.0, 0.82, 0.5), 0.35), Vector3(0.3, 0.63, -0.06))
			_books(k, Vector3(0.36, 0.0, -0.26), 4, 2)
		1:
			# an office chair, a steel side cabinet, a headset and a desk phone
			var steel := Color(0.62, 0.64, 0.68)
			_chair(k, Vector3(-0.12, 0, -0.06), Color(0.26, 0.27, 0.3), Pal.STEEL_DARK, 180)
			_b(k, Vector3(0.28, 0.56, 0.3), steel, Vector3(0.24, 0.28, -0.04))
			for j in 3:
				_b(k, Vector3(0.26, 0.005, 0.005), Color(0.4, 0.42, 0.46), Vector3(0.24, 0.12 + j * 0.16, 0.112))
				_b(k, Vector3(0.08, 0.015, 0.012), Color(0.86, 0.86, 0.84), Vector3(0.24, 0.18 + j * 0.16, 0.115))
			_b(k, Vector3(0.14, 0.04, 0.1), Color(0.16, 0.17, 0.2), Vector3(0.26, 0.58, -0.1))
			k.torus(0.06, 0.012, Color(0.16, 0.17, 0.2), MeshKit.xf(Vector3(0.14, 0.62, -0.08), Vector3(90, 0, 0)), 10, 3, PI)
			_b(k, Vector3(0.06, 0.012, 0.004), _lit(Color(0.6, 1.0, 0.62)), Vector3(0.26, 0.6, -0.048))
			_b(k, Vector3(0.12, 0.3, 0.24), Color(0.96, 0.76, 0.2), Vector3(-0.38, 0.15, -0.24))
		2:
			# a white lounge chair with a teal cushion, a round side table, a plant
			var white := Color(0.95, 0.95, 0.96)
			var cush := _c(2, "accent")
			_b(k, Vector3(0.5, 0.2, 0.46), white, Vector3(-0.1, 0.12, -0.08))
			_b(k, Vector3(0.44, 0.08, 0.4), cush, Vector3(-0.1, 0.26, -0.06))
			_b(k, Vector3(0.5, 0.42, 0.1), white, Vector3(-0.1, 0.36, -0.28), Vector3(-8, 0, 0))
			_b(k, Vector3(0.42, 0.3, 0.06), cush.lightened(0.1), Vector3(-0.1, 0.4, -0.22), Vector3(-8, 0, 0))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.06, 0.18, 0.44), white, Vector3(-0.1 + sx * 0.25, 0.28, -0.08))
			k.cyl(0.14, 0.03, white, MeshKit.at(0.26, 0.55, 0.02), 10)
			k.cyl(0.02, 0.55, _c(2, "accent"), MeshKit.at(0.26, 0, 0.02), 6)
			k.cyl(0.1, 0.02, white, MeshKit.at(0.26, 0, 0.02), 10)
			k.cyl(0.08, 0.16, white, MeshKit.at(0.32, 0, -0.3), 8)
			k.sphere(0.12, Color(0.42, 0.6, 0.36), MeshKit.xf(Vector3(0.32, 0.3, -0.3), Vector3.ZERO, Vector3(1, 1.3, 1)), 8, 4)
		3:
			# a leather club chair in a dark booth, a lit bookshelf
			var lea := Color(0.5, 0.3, 0.2)
			_b(k, Vector3(0.5, 0.22, 0.46), lea, Vector3(-0.1, 0.17, -0.08))
			_b(k, Vector3(0.5, 0.46, 0.12), lea.darkened(0.08), Vector3(-0.1, 0.42, -0.28))
			for sx in [-1.0, 1.0]:
				_b(k, Vector3(0.1, 0.32, 0.46), lea.darkened(0.04), Vector3(-0.1 + sx * 0.25, 0.26, -0.08))
				for i in 3:
					_b(k, Vector3(0.012, 0.012, 0.012), Pal.BRASS, Vector3(-0.1 + sx * 0.3, 0.38, -0.24 + i * 0.12))
			_b(k, Vector3(0.24, 0.04, 0.24), Color(0.2, 0.21, 0.24), Vector3(0.24, 0.58, 0.02))
			_b(k, Vector3(0.04, 0.56, 0.04), Color(0.2, 0.21, 0.24), Vector3(0.24, 0.28, 0.02))
			_b(k, Vector3(0.32, 0.86, 0.16), Color(0.2, 0.21, 0.24), Vector3(0.3, 0.43, -0.32))
			for j in 3:
				_b(k, Vector3(0.3, 0.012, 0.012), _lit(Color(0.45, 0.75, 1.0), 0.45), Vector3(0.3, 0.2 + j * 0.25, -0.24))
				for i in 4:
					_b(k, Vector3(0.05, 0.16, 0.12), [Color(0.6, 0.3, 0.3), Color(0.3, 0.4, 0.6), Color(0.86, 0.68, 0.32), Color(0.36, 0.5, 0.38)][(i + j) % 4], Vector3(0.2 + i * 0.07, 0.29 + j * 0.25, -0.32))
		4:
			# a graphite pod chair with a brass rim and a glowing halo lamp
			var gr := Color(0.17, 0.18, 0.21)
			k.cyl(0.26, 0.12, gr, MeshKit.at(-0.1, 0, -0.08), 10)
			k.cyl(0.265, 0.015, Pal.BRASS, MeshKit.at(-0.1, 0.12, -0.08), 10)
			_b(k, Vector3(0.44, 0.1, 0.4), Color(0.36, 0.3, 0.42), Vector3(-0.1, 0.18, -0.06))
			k.sphere(0.3, gr, MeshKit.xf(Vector3(-0.1, 0.44, -0.18), Vector3(-10, 0, 0), Vector3(1, 1.15, 0.6)), 10, 5)
			k.torus(0.3, 0.012, Pal.BRASS, MeshKit.xf(Vector3(-0.1, 0.44, -0.04), Vector3(80, 0, 0)), 14, 3)
			k.cyl(0.03, 0.9, Pal.BRASS, MeshKit.at(0.3, 0, -0.2), 6)
			k.torus(0.12, 0.015, _lit(Color(1.0, 0.86, 0.5), 0.35), MeshKit.at(0.2, 0.88, -0.1), 14, 3)
			k.cyl(0.13, 0.03, gr, MeshKit.at(0.26, 0.55, 0.02), 8)
			k.cyl(0.135, 0.012, Pal.BRASS, MeshKit.at(0.26, 0.58, 0.02), 8)
			k.cyl(0.03, 0.55, gr, MeshKit.at(0.26, 0, 0.02), 6)


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
