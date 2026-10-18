class_name LabArt
## The labs, the Batcher and the Agent Studio, five tiers each:
##   0 garage (plywood bench, a desk lamp)   1 steel workshop
##   2 white lab with a teal band           3 steel and glass, deck lights
##   4 graphite and brass, glowing edges
## Each has a moving part: the fab's wafer stage, the refinery's filter
## ring, the tune lab's dial, the HBM press, the gym's robot arm, the synth
## lab's reactor ring, the batcher's conveyor, the studio's assembly arm.

const Z := -0.85


static func lit(c: Color, a := 0.45) -> Color:
	return Color(c.r, c.g, c.b, a)


static func _shell(t: int) -> Color:
	return [Pal.WOOD_LIGHT, Color(0.72, 0.74, 0.78), Color(0.95, 0.95, 0.96), Color(0.62, 0.66, 0.72), Color(0.17, 0.18, 0.21)][t]


static func _trim(t: int) -> Color:
	return [Pal.WOOD_DARK, Pal.STEEL_DARK, Color(0.3, 0.62, 0.66), Pal.STEEL_DARK, Pal.BRASS][t]


static func bench(t: int) -> Mesh:
	var k := MeshKit.new()
	var top: Color = [Pal.WOOD_LIGHT, Color(0.78, 0.8, 0.84), Color(0.95, 0.95, 0.96), Color(0.7, 0.74, 0.8), Color(0.2, 0.21, 0.24)][t]
	var leg: Color = [Pal.WOOD_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.BRASS][t]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.72, 0.08), 0.02, leg, MeshKit.at(sx * 0.62, 0.36, sz * 0.36))
	k.rbox(Vector3(1.4, 0.06, 0.86), 0.02, top, MeshKit.at(0, 0.74, 0))
	return k.commit()


## Base under every machine, then the machine itself.
static func machine(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var sh := _shell(t)
	var trim := _trim(t)
	var col: Color = _accent(kind)
	# base
	match t:
		0:
			k.rbox(Vector3(2.4, 0.3, 1.6), 0.04, Color(0.62, 0.62, 0.6), MeshKit.at(0, 0.15, Z))
		1:
			k.rbox(Vector3(2.4, 0.3, 1.6), 0.05, Color(0.4, 0.42, 0.46), MeshKit.at(0, 0.15, Z))
		2:
			k.rbox(Vector3(2.4, 0.5, 1.6), 0.06, Color(0.9, 0.91, 0.92), MeshKit.at(0, 0.25, Z))
			k.rbox(Vector3(2.42, 0.08, 1.62), 0.02, trim, MeshKit.at(0, 0.38, Z))
		3:
			k.rbox(Vector3(2.5, 0.5, 1.7), 0.05, Pal.STEEL_DARK, MeshKit.at(0, 0.25, Z))
			k.rbox(Vector3(2.3, 0.03, 0.03), 0.01, lit(Color(0.4, 0.8, 1.0)), MeshKit.at(0, 0.4, Z + 0.86))
		4:
			k.rbox(Vector3(2.5, 0.45, 1.7), 0.08, Color(0.12, 0.12, 0.14), MeshKit.at(0, 0.22, Z))
			k.rbox(Vector3(2.54, 0.05, 1.74), 0.02, Pal.BRASS, MeshKit.at(0, 0.45, Z))
	var by: float = [0.3, 0.3, 0.5, 0.5, 0.48][t]
	var s := 1.0 + t * 0.06
	match kind:
		"fab":
			# a cleanroom box with a window onto a lithography stage
			k.rbox(Vector3(1.8 * s, 1.3 * s, 1.3), 0.08, sh if t != 0 else Color(0.92, 0.93, 0.94), MeshKit.at(0, by + 0.65 * s, Z))
			k.rbox(Vector3(1.2 * s, 0.6 * s, 0.04), 0.04, Color(0.6, 0.8, 0.9, 0.8), MeshKit.at(0, by + 0.62 * s, Z + 0.66))
			k.rbox(Vector3(1.86 * s, 0.08, 1.36), 0.02, trim, MeshKit.at(0, by + 1.3 * s, Z))
			k.cyl(0.18, 0.5, sh.darkened(0.1), MeshKit.at(0.0, by + 1.3 * s, Z - 0.1), 12, 0.02, 0.12)
			k.rbox(Vector3(0.12, 0.08, 0.02), 0.01, lit(Color(1.0, 0.86, 0.4)), MeshKit.at(0.7 * s, by + 1.1 * s, Z + 0.66))
			if t >= 2:
				k.rbox(Vector3(0.5, 1.1, 0.4), 0.05, sh.darkened(0.05), MeshKit.at(-1.05 * s, by + 0.55, Z - 0.3))
				k.rbox(Vector3(0.3, 0.1, 0.02), 0.01, lit(Color(0.5, 1.0, 0.6)), MeshKit.at(-1.05 * s, by + 0.9, Z - 0.09))
		"refinery":
			# distillation columns of glowing data, linked by pipes
			for i in 3:
				var x := (i - 1) * 0.55
				var h := (1.2 + (i % 2) * 0.35) * s
				k.cyl(0.22, h, Color(0.5, 0.78, 0.96, 0.75), MeshKit.at(x, by, Z), 14, 0.04)
				k.cyl(0.24, 0.08, trim, MeshKit.at(x, by, Z), 14)
				k.cyl(0.24, 0.08, trim, MeshKit.at(x, by + h - 0.08, Z), 14)
				k.cyl(0.04, 0.3, Pal.STEEL, MeshKit.at(x, by + h, Z), 6)
			k.cyl(0.05, 1.2, Pal.STEEL, MeshKit.xf(Vector3(-0.6, by + 1.15 * s, Z), Vector3(0, 0, -90)), 6)
			k.rbox(Vector3(0.6, 0.5, 0.3), 0.04, sh, MeshKit.at(0.9, by + 0.25, Z + 0.3))
			k.rbox(Vector3(0.4, 0.2, 0.02), 0.02, lit(col), MeshKit.at(0.9, by + 0.32, Z + 0.46))
		"tune_lab":
			# a tuning console: a sloped desk of sliders and a big dial
			k.rbox(Vector3(1.9, 0.8, 1.1), 0.08, sh, MeshKit.at(0, by + 0.4, Z))
			k.rbox(Vector3(1.9, 0.08, 1.0), 0.03, trim, MeshKit.xf(Vector3(0, by + 0.85, Z + 0.05), Vector3(-15, 0, 0)))
			for i in 6:
				k.rbox(Vector3(0.05, 0.03, 0.4), 0.01, Color(0.24, 0.25, 0.28), MeshKit.xf(Vector3(-0.8 + i * 0.16, by + 0.9, Z + 0.1), Vector3(-15, 0, 0)))
				k.rbox(Vector3(0.1, 0.06, 0.06), 0.02, lit([col, Color(0.5, 0.9, 1.0)][i % 2]), MeshKit.xf(Vector3(-0.8 + i * 0.16, by + 0.93, Z + 0.1 - 0.1 + (i * 37 % 5) * 0.05), Vector3(-15, 0, 0)))
			k.rbox(Vector3(1.2, 0.7, 0.06), 0.04, Color(0.14, 0.15, 0.18), MeshKit.at(0, by + 1.4 * s, Z - 0.45))
			for i in 6:
				k.rbox(Vector3(0.12, 0.08 + absf(sin(i * 1.7)) * 0.3, 0.02), 0.01, lit(col.lightened(0.2)), MeshKit.at(-0.4 + i * 0.16, by + 1.25 * s + absf(sin(i * 1.7)) * 0.15, Z - 0.41))
			k.cyl(0.3, 0.06, Color(0.24, 0.25, 0.28), MeshKit.xf(Vector3(0.62, by + 0.95, Z + 0.25), Vector3(-15 + 90, 0, 0)), 16)
		"hbm_works":
			# a stacking press: a frame, a platen and a stack of dies
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.14, 1.6 * s, 0.14), 0.03, trim, MeshKit.at(sx * 0.7, by + 0.8 * s, Z))
			k.rbox(Vector3(1.6, 0.18, 0.6), 0.04, sh, MeshKit.at(0, by + 1.6 * s, Z))
			k.rbox(Vector3(1.0, 0.25, 0.8), 0.04, sh, MeshKit.at(0, by + 0.12, Z))
			for i in 4:
				k.rbox(Vector3(0.5, 0.06, 0.4), 0.01, Color(0.18, 0.18, 0.2) if i % 2 == 0 else col, MeshKit.at(0, by + 0.28 + i * 0.065, Z))
			k.rbox(Vector3(0.5, 0.012, 0.02), 0.004, Pal.BRASS, MeshKit.at(0, by + 0.28, Z + 0.21))
			k.rbox(Vector3(0.5, 0.6, 0.3), 0.04, sh.darkened(0.06), MeshKit.at(1.05, by + 0.3, Z - 0.3))
			k.rbox(Vector3(0.3, 0.08, 0.02), 0.01, lit(Color(1.0, 0.7, 0.4)), MeshKit.at(1.05, by + 0.45, Z - 0.14))
		"rlhf_gym":
			# a robot arm on a pedestal over a training mat with a reward light
			k.rbox(Vector3(1.9, 0.08, 1.3), 0.02, Color(0.3, 0.6, 0.5) if t < 4 else Color(0.2, 0.3, 0.3), MeshKit.at(0, by + 0.04, Z))
			for i in 3:
				k.rbox(Vector3(1.9, 0.01, 0.04), 0.005, Color(0.95, 0.95, 0.9), MeshKit.at(0, by + 0.085, Z - 0.4 + i * 0.4))
			k.cyl(0.3, 0.5, sh, MeshKit.at(-0.5, by, Z), 14, 0.04)
			k.star(0.22, 0.1, 5, 0.06, lit(col, 0.5), MeshKit.at(0.55, by + 0.1, Z + 0.1))
			k.cyl(0.06, 1.2, trim, MeshKit.at(0.8, by, Z - 0.5), 6)
			k.sphere(0.1, lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.at(0.8, by + 1.25, Z - 0.5), 8, 5)
		"synth_lab":
			# a glowing reactor sphere held in a frame
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.12, 1.5 * s, 0.12), 0.03, trim, MeshKit.at(sx * 0.75, by + 0.75 * s, Z))
			k.rbox(Vector3(1.6, 0.12, 0.4), 0.03, sh, MeshKit.at(0, by + 1.5 * s, Z))
			k.cyl(0.5, 0.2, sh, MeshKit.at(0, by, Z), 16, 0.04)
			k.sphere(0.38, lit(col, 0.5), MeshKit.at(0, by + 0.8 * s, Z), 16, 10)
			k.sphere(0.2, lit(Color(1, 1, 1), 0.3), MeshKit.at(0, by + 0.8 * s, Z), 10, 6)
		"batcher":
			# a sorter cabinet feeding a roller conveyor
			k.rbox(Vector3(1.0, 1.4, 1.1), 0.1, sh, MeshKit.at(-0.55, by + 0.7, Z))
			k.rbox(Vector3(0.5, 0.35, 0.05), 0.05, Color(0.6, 0.8, 0.9, 0.7), MeshKit.at(-0.55, by + 0.95, Z + 0.56))
			k.rbox(Vector3(1.6, 0.08, 0.5), 0.02, Pal.STEEL_DARK, MeshKit.at(0.45, by + 0.5, Z + 0.1))
			for i in 5:
				k.cyl(0.05, 0.5, Pal.STEEL, MeshKit.xf(Vector3(-0.2 + i * 0.32, by + 0.56, Z + 0.1), Vector3(90, 0, 0)), 8)
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 0.5, 0.06), 0.02, Pal.STEEL_DARK, MeshKit.at(0.45 + sx * 0.7, by + 0.25, Z + 0.1))
			k.cyl(0.24, 0.3, Color(0.5, 0.78, 0.96, 0.75), MeshKit.at(-0.55, by + 1.4, Z), 12, 0.03, 0.12)
			k.rbox(Vector3(0.12, 0.06, 0.02), 0.01, lit(Color(0.5, 1.0, 0.6)), MeshKit.at(-0.25, by + 1.25, Z + 0.56))
		"agent_studio":
			# an assembly table where agent bots are put together, an arm overhead
			k.rbox(Vector3(2.0, 0.9, 1.1), 0.08, sh, MeshKit.at(0, by + 0.45, Z))
			k.rbox(Vector3(2.04, 0.05, 1.14), 0.02, trim, MeshKit.at(0, by + 0.92, Z))
			for i in 3:
				k.rbox(Vector3(0.28, 0.22, 0.26), 0.05, Color(0.95, 0.95, 0.94), MeshKit.at(0.3 + i * 0.32, by + 1.06, Z + 0.1))
				k.rbox(Vector3(0.16, 0.06, 0.01), 0.02, lit(Color(0.5, 0.95, 1.0), 0.4), MeshKit.at(0.3 + i * 0.32, by + 1.1, Z + 0.235))
			k.cyl(0.08, 0.9, trim, MeshKit.at(-0.55, by + 0.92, Z - 0.3), 8)
	return k.commit()


static func _accent(kind: String) -> Color:
	match kind:
		"fab": return Color(0.5, 0.9, 0.6)
		"refinery": return Color(0.4, 0.78, 0.98)
		"tune_lab": return Color(0.98, 0.64, 0.32)
		"hbm_works": return Color(0.36, 0.5, 0.78)
		"rlhf_gym": return Color(0.98, 0.8, 0.32)
		"synth_lab": return Color(0.72, 0.46, 0.98)
	return Color(0.5, 0.9, 1.0)


## Where the moving part pivots (local).
static func anim_pivot(kind: String, t: int) -> Vector3:
	var by: float = [0.3, 0.3, 0.5, 0.5, 0.48][t]
	var s := 1.0 + t * 0.06
	match kind:
		"fab": return Vector3(0, by + 0.45 * s, Z + 0.25)
		"refinery": return Vector3(0, by + 0.5 * s, Z)
		"tune_lab": return Vector3(0.62, by + 0.98, Z + 0.28)
		"hbm_works": return Vector3(0, by + 1.4 * s, Z)
		"rlhf_gym": return Vector3(-0.5, by + 0.5, Z)
		"synth_lab": return Vector3(0, by + 0.8 * s, Z)
		"batcher": return Vector3(-0.1, by + 0.62, Z + 0.1)
		"agent_studio": return Vector3(-0.55, by + 1.82, Z - 0.3)
	return Vector3(0, 1, Z)


static func part(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var col := _accent(kind)
	match kind:
		"fab":
			# a wafer on its stage, glowing with dies
			k.cyl(0.32, 0.03, Color(0.6, 0.64, 0.72), MeshKit.at(0, 0, 0), 20)
			for i in 5:
				for j in 5:
					var p := Vector2(-0.2 + i * 0.1, -0.2 + j * 0.1)
					if p.length() < 0.27:
						k.rbox(Vector3(0.08, 0.012, 0.08), 0.004, lit(col, 0.6) if (i + j) % 2 == 0 else Color(0.5, 0.56, 0.7), MeshKit.at(p.x, 0.035, p.y))
		"refinery":
			k.torus(0.92, 0.04, lit(col, 0.4), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(1.0, 1.0, 0.45)), 24, 4)
		"tune_lab":
			k.rbox(Vector3(0.05, 0.03, 0.24), 0.01, lit(Color(1, 1, 1), 0.4), MeshKit.at(0, 0.05, 0.08))
			k.cyl(0.08, 0.06, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0.0, 0), 10)
		"hbm_works":
			k.rbox(Vector3(0.7, 0.2, 0.5), 0.04, Pal.STEEL, MeshKit.at(0, -0.3, 0))
			k.cyl(0.08, 0.4, Pal.STEEL_DARK, MeshKit.at(0, -0.2, 0), 8)
		"rlhf_gym":
			# a two-segment robot arm with a gripper
			var a := Color(0.96, 0.6, 0.24) if t < 4 else Pal.BRASS
			k.cyl(0.12, 0.2, a, MeshKit.at(0, 0, 0), 12, 0.03)
			k.rbox(Vector3(0.14, 0.7, 0.14), 0.05, a, MeshKit.xf(Vector3(0.15, 0.4, 0), Vector3(0, 0, -25)))
			k.rbox(Vector3(0.6, 0.12, 0.12), 0.05, a, MeshKit.at(0.55, 0.72, 0))
			k.sphere(0.09, Pal.STEEL_DARK, MeshKit.at(0.3, 0.72, 0), 8, 5)
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.04, 0.14, 0.03), 0.01, Pal.STEEL_DARK, MeshKit.at(0.86, 0.64, sz * 0.05))
		"synth_lab":
			k.torus(0.55, 0.04, lit(col, 0.4), MeshKit.xf(Vector3.ZERO, Vector3(90, 0, 0)), 24, 4)
			k.torus(0.6, 0.025, Pal.BRASS, MeshKit.xf(Vector3.ZERO, Vector3(90, 0, 60)), 24, 4)
		"batcher":
			# a batch case riding the conveyor
			k.rbox(Vector3(0.3, 0.2, 0.26), 0.04, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0.12, 0))
			k.rbox(Vector3(0.31, 0.03, 0.27), 0.01, lit(Color(0.5, 0.9, 1.0), 0.5), MeshKit.at(0, 0.15, 0))
		"agent_studio":
			# an assembly arm with a robot head in its grip
			k.rbox(Vector3(0.9, 0.08, 0.08), 0.03, Pal.STEEL_DARK, MeshKit.at(0.45, 0, 0))
			k.cyl(0.03, 0.3, Pal.STEEL, MeshKit.at(0.85, -0.3, 0), 6)
			k.rbox(Vector3(0.2, 0.16, 0.18), 0.05, Color(0.95, 0.95, 0.94), MeshKit.at(0.85, -0.38, 0))
			k.rbox(Vector3(0.12, 0.04, 0.01), 0.015, lit(Color(0.5, 0.95, 1.0), 0.4), MeshKit.at(0.85, -0.37, 0.095))
	return k.commit()


static func animate(kind: String, n: Node3D, t: float, busy: bool) -> void:
	var sp := 1.0 if busy else 0.0
	match kind:
		"fab", "synth_lab":
			n.rotation.y += 0.05 * (0.2 + sp * 1.6)
			if kind == "synth_lab":
				n.rotation.x += 0.02 * (0.2 + sp)
		"refinery":
			if not n.has_meta("y0"):
				n.set_meta("y0", n.position.y)
			n.position.y = float(n.get_meta("y0")) + (fmod(t * 0.6, 1.0) * 0.9 if busy else 0.0)
		"tune_lab":
			n.rotation.y = sin(t * 2.0) * 1.2 * sp
		"hbm_works":
			if not n.has_meta("y0"):
				n.set_meta("y0", n.position.y)
			n.position.y = float(n.get_meta("y0")) - absf(sin(t * 3.0)) * 0.35 * sp
		"rlhf_gym":
			n.rotation.y = sin(t * 1.6) * 1.4 * sp
		"batcher":
			if not n.has_meta("x0"):
				n.set_meta("x0", n.position.x)
			n.position.x = float(n.get_meta("x0")) + (fmod(t * 0.6, 1.0) * 1.2 if busy else 0.0)
			n.visible = busy
		"agent_studio":
			n.rotation.y = -0.4 + sin(t * 1.4) * 0.9 * sp
