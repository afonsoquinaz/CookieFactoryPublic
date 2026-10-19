class_name DormB
extends Building
## Staff Housing: a modular co-living house for your staff. Resting workers
## sit on the benches out front.


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("cabin_%d" % t, func(): return DormB.mesh(t)), root, MeshKit.at(0.3, 0, -0.65))


func solid_rects() -> Array[Rect2]:
	return [Rect2(-1.7, -2.0, 3.4, 2.6)]


## Where resting worker i sits (world space).
func seat(i: int) -> Vector3:
	var col := i % 4
	var row := (i / 4) % 2
	return to_world(-1.2 + col * 0.75, 0.75 + row * 0.85)


func info() -> Array:
	return [["hire", "Houses %d workers" % Bal.dorm_cap(level)], ["worker", "%d hired in total" % Game.workers.size()]]


func upgrade_info() -> Array:
	return [["Houses", str(Bal.dorm_cap(level)), str(Bal.dorm_cap(level + 1))]]


## The look for era t, built in the building's frame and shifted into the
## old mesh frame (the visual node and Previews place it at (0.3, 0, -0.65)).
## A tent and a camper van (0), a stacked bunk container with a steel stair
## (1), a white townhouse with balconies (2), a steel-and-glass deck-access
## block (3), a graphite residence tower with a sky garden (4). Resting
## workers sit on the two benches out front (see seat()).
static func mesh(t: int) -> Mesh:
	var b := MeshKit.new()
	match t:
		0: _camp(b)
		1: _bunks(b)
		2: _townhouse(b)
		3: _deck_block(b)
		_: _tower(b)
	_benches(b, t)
	var k := MeshKit.new()
	k.merge(b, MeshKit.at(-0.3, 0, 0.65))
	return k.commit()


static func _bx(k: MeshKit, size: Vector3, col: Color, x: float, y: float, z: float) -> void:
	k.box(size, col, MeshKit.at(x, y, z))


## The two benches where resting workers sit (rows at z 0.75 and 1.6,
## seats from x -1.2 to 1.05), in each era's style.
static func _benches(k: MeshKit, t: int) -> void:
	for row in 2:
		var z := 0.75 + row * 0.85
		match t:
			0:
				# a log on two stumps
				for sx in [-1.25, 1.1]:
					k.cyl(0.14, 0.3, Pal.WOOD_DARK, MeshKit.at(sx, 0.0, z - 0.02), 7)
				k.cyl(0.13, 2.8, Pal.WOOD, MeshKit.xf(Vector3(-1.48, 0.37, z - 0.02), Vector3(0, 0, -90)), 7)
				k.cyl(0.12, 0.02, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(-1.485, 0.37, z - 0.02), Vector3(0, 0, -90)), 7)
				k.cyl(0.12, 0.02, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(1.33, 0.37, z - 0.02), Vector3(0, 0, -90)), 7)
			1:
				# pallets stacked into a bench with cushions
				for j in 2:
					for i in 4:
						_bx(k, Vector3(0.7, 0.03, 0.4), Pal.WOOD_LIGHT.darkened(0.05 * ((i + j) % 2)), -1.12 + i * 0.73, 0.12 + j * 0.15, z)
						for sx in [-0.3, 0.0, 0.3]:
							_bx(k, Vector3(0.08, 0.1, 0.4), Pal.WOOD, -1.12 + i * 0.73 + sx, 0.05 + j * 0.15, z)
				for i in 4:
					k.rbox(Vector3(0.62, 0.08, 0.36), 0.03, [Color(0.3, 0.5, 0.8), Color(0.96, 0.76, 0.2), Color(0.78, 0.3, 0.26), Color(0.4, 0.6, 0.4)][(i + row) % 4], MeshKit.at(-1.12 + i * 0.73, 0.38, z), 1)
			2:
				# a slatted timber bench with planter ends
				for j in 4:
					_bx(k, Vector3(2.5, 0.03, 0.07), Pal.WOOD_LIGHT, -0.08, 0.42, z - 0.12 + j * 0.08)
				for j in 3:
					k.box(Vector3(2.5, 0.07, 0.025), Pal.WOOD_LIGHT, MeshKit.xf(Vector3(-0.08, 0.55 + j * 0.1, z - 0.2), Vector3(-8, 0, 0)))
				for sx in [-1.55, 1.38]:
					_bx(k, Vector3(0.38, 0.5, 0.42), Color(0.92, 0.93, 0.94), sx, 0.25, z)
					_bx(k, Vector3(0.4, 0.03, 0.44), Color(0.3, 0.66, 0.68), sx, 0.5, z)
					k.sphere(0.2, Pal.LEAF, MeshKit.xf(Vector3(sx, 0.62, z), Vector3.ZERO, Vector3(1, 0.8, 1)), 7, 4)
				for sx in [-0.6, 0.5]:
					_bx(k, Vector3(0.05, 0.4, 0.3), Pal.STEEL_DARK, sx, 0.2, z)
			3:
				# a perforated steel bench on a concrete plinth
				_bx(k, Vector3(2.7, 0.18, 0.4), Color(0.56, 0.58, 0.6), -0.08, 0.09, z)
				_bx(k, Vector3(2.6, 0.04, 0.36), Color(0.3, 0.32, 0.36), -0.08, 0.42, z)
				for i in 12:
					_bx(k, Vector3(0.04, 0.24, 0.02), Color(0.3, 0.32, 0.36), -1.35 + i * 0.23, 0.3, z + 0.15)
				k.box(Vector3(2.6, 0.3, 0.03), Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(-0.08, 0.62, z - 0.18), Vector3(-10, 0, 0)))
				_bx(k, Vector3(2.62, 0.02, 0.02), Color(0.45, 0.75, 1.0, 0.45), -0.08, 0.2, z + 0.2)
			_:
				# a graphite bench with brass arms and a glowing underline
				k.rbox(Vector3(2.7, 0.14, 0.4), 0.04, Color(0.22, 0.23, 0.27), MeshKit.at(-0.08, 0.36, z), 1)
				k.box(Vector3(2.7, 0.32, 0.06), Color(0.2, 0.21, 0.24), MeshKit.xf(Vector3(-0.08, 0.6, z - 0.18), Vector3(-10, 0, 0)))
				for sx in [-1.45, 1.29]:
					_bx(k, Vector3(0.06, 0.32, 0.4), Pal.BRASS, sx, 0.46, z)
				_bx(k, Vector3(2.2, 0.28, 0.3), Color(0.14, 0.14, 0.16), -0.08, 0.14, z)
				_bx(k, Vector3(2.7, 0.02, 0.02), Color(1.0, 0.86, 0.5, 0.4), -0.08, 0.04, z + 0.2)


# ---------------------------------------------------------------- 0 camp

static func _camp(k: MeshKit) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 11
	# ground: grass worn to dirt, a tarp under the tent, a few tufts
	_bx(k, Vector3(3.8, 0.02, 3.8), Color(0.5, 0.56, 0.38), 0, 0.01, 0)
	for i in 14:
		k.box(Vector3(r.randf_range(0.2, 0.6), 0.008, r.randf_range(0.15, 0.4)), Color(0.6, 0.52, 0.4) if i % 3 else Color(0.44, 0.5, 0.32), MeshKit.xf(Vector3(r.randf_range(-1.8, 1.8), 0.022, r.randf_range(-1.8, 1.8)), Vector3(0, r.randf_range(0, 180), 0)))
	for i in 10:
		k.cone(0.05, 0.14, Pal.GRASS_DARK, MeshKit.at(r.randf_range(-1.8, 1.8), 0.02, r.randf_range(1.85, 1.85) if i % 2 else r.randf_range(-1.85, -1.5)), 4)
	# ---- the camper van along the back (cab toward -x)
	var vz := -1.33
	var vx0 := -1.8
	var vx1 := 1.35
	var vl := vx1 - vx0
	var vcx := (vx0 + vx1) * 0.5
	var vw := 0.98
	var teal := Color(0.36, 0.62, 0.62)
	var cream := Color(0.94, 0.9, 0.8)
	k.rbox(Vector3(vl, 0.8, vw), 0.12, teal, MeshKit.at(vcx, 0.62, vz), 1)
	k.rbox(Vector3(vl - 0.02, 0.98, vw - 0.02), 0.12, cream, MeshKit.at(vcx, 1.4, vz), 1)
	_bx(k, Vector3(vl - 0.3, 0.06, vw - 0.2), cream.darkened(0.06), vcx + 0.1, 1.92, vz)
	# a band, the windows, the cab glass
	_bx(k, Vector3(vl + 0.01, 0.06, vw + 0.01), Color(0.86, 0.5, 0.3), vcx, 1.02, vz)
	for i in 3:
		_bx(k, Vector3(0.52, 0.4, 0.02), Color(0.36, 0.46, 0.54), vx0 + 1.05 + i * 0.66, 1.42, vz + vw * 0.5)
		_bx(k, Vector3(0.52, 0.4, 0.02), Color(0.36, 0.46, 0.54), vx0 + 1.05 + i * 0.66, 1.42, vz - vw * 0.5)
	k.box(Vector3(0.04, 0.5, vw - 0.2), Color(0.36, 0.46, 0.54), MeshKit.xf(Vector3(vx0 + 0.02, 1.42, vz), Vector3(0, 0, -12)))
	_bx(k, Vector3(0.5, 0.42, 0.02), Color(0.36, 0.46, 0.54), vx0 + 0.36, 1.42, vz + vw * 0.5)
	# the open sliding door with a dark interior and a step
	_bx(k, Vector3(0.62, 1.4, 0.02), Color(0.16, 0.14, 0.13), vx0 + 1.05, 0.98, vz + vw * 0.5 + 0.005)
	_bx(k, Vector3(0.62, 1.4, 0.04), teal.darkened(0.1), vx0 + 1.68, 0.98, vz + vw * 0.5 + 0.04)
	_bx(k, Vector3(0.5, 0.05, 0.22), Color(0.4, 0.42, 0.44), vx0 + 1.05, 0.22, vz + vw * 0.5 + 0.1)
	_bx(k, Vector3(0.4, 0.2, 0.3), Color(0.72, 0.56, 0.38), vx0 + 1.05, 0.55, vz + 0.2)
	# bumpers, lights, a spare wheel, wheels
	for sx in [vx0 - 0.02, vx1 + 0.02]:
		_bx(k, Vector3(0.08, 0.12, vw + 0.06), Color(0.82, 0.83, 0.84), sx, 0.36, vz)
	for sz in [-0.32, 0.32]:
		k.cyl(0.07, 0.02, Color(1.0, 0.95, 0.8, 0.45), MeshKit.xf(Vector3(vx0 - 0.01, 0.62, vz + sz), Vector3(0, 0, 90)), 8)
		_bx(k, Vector3(0.02, 0.1, 0.1), Color(0.86, 0.3, 0.26), vx1 + 0.01, 0.7, vz + sz)
	k.cyl(0.24, 0.12, Pal.RUBBER, MeshKit.xf(Vector3(vx1 + 0.06, 0.85, vz), Vector3(0, 0, 90)), 10)
	k.cyl(0.13, 0.13, cream, MeshKit.xf(Vector3(vx1 + 0.06, 0.85, vz), Vector3(0, 0, 90)), 8)
	for wx in [vx0 + 0.55, vx1 - 0.55]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.22, 0.12, Pal.RUBBER, MeshKit.xf(Vector3(wx, 0.24, vz + sz * (vw * 0.5 - 0.02)), Vector3(90, 0, 0)), 10)
			k.cyl(0.11, 0.13, Color(0.82, 0.83, 0.84), MeshKit.xf(Vector3(wx, 0.24, vz + sz * (vw * 0.5 - 0.02)), Vector3(90, 0, 0)), 8)
	# a roof rack over the cab with a surfboard and a box (patches stay flat)
	for sx in [vx0 + 0.25, vx0 + 0.95]:
		_bx(k, Vector3(0.04, 0.08, vw - 0.1), Color(0.3, 0.32, 0.36), sx, 1.97, vz)
	k.rbox(Vector3(0.95, 0.06, 0.32), 0.03, Color(0.98, 0.7, 0.3), MeshKit.at(vx0 + 0.62, 2.05, vz + 0.15), 1)
	k.rbox(Vector3(0.6, 0.22, 0.34), 0.06, Color(0.3, 0.32, 0.36), MeshKit.at(vx0 + 0.6, 2.13, vz - 0.22), 1)
	# the striped awning wound out from the van to two poles
	var ay := 1.82
	for i in 7:
		k.box(Vector3(0.3, 0.025, 0.72), Color(0.86, 0.5, 0.3) if i % 2 == 0 else cream, MeshKit.xf(Vector3(vx0 + 1.0 + i * 0.3, ay - 0.1, vz + vw * 0.5 + 0.34), Vector3(-12, 0, 0)))
	for i in 7:
		_bx(k, Vector3(0.3, 0.1, 0.02), Color(0.86, 0.5, 0.3) if i % 2 == 1 else cream, vx0 + 1.0 + i * 0.3, ay - 0.27, vz + vw * 0.5 + 0.7)
	for sx in [vx0 + 0.88, vx0 + 3.0]:
		k.cyl(0.02, ay - 0.2, Color(0.7, 0.72, 0.74), MeshKit.at(sx, 0.0, vz + vw * 0.5 + 0.7), 5)
		TownArt.beam(k, Vector3(sx, ay - 0.22, vz + vw * 0.5 + 0.7), Vector3(sx, 0.02, vz + vw * 0.5 + 1.1), 0.01, Color(0.86, 0.84, 0.8))
	ArchKit.string_lights(k, Vector3(vx0 + 0.9, ay - 0.3, vz + vw * 0.5 + 0.72), Vector3(vx0 + 3.0, ay - 0.3, vz + vw * 0.5 + 0.72), 6)
	# ---- a ridge tent on the left with guy ropes and an open flap
	var tc := Vector3(-1.3, 0.0, -0.2)
	var orange := Color(0.92, 0.5, 0.22)
	_bx(k, Vector3(1.0, 0.012, 1.2), Color(0.3, 0.42, 0.66), tc.x, 0.025, tc.z)
	for sd in [-1.0, 1.0]:
		k.box(Vector3(0.94, 0.025, 1.16), orange.darkened(0.05 if sd > 0 else 0.15), MeshKit.xf(Vector3(tc.x + sd * 0.225, 0.42, tc.z), Vector3(0, 0, -sd * 60.6)))
	k.prism(PackedVector2Array([Vector2(-0.43, 0), Vector2(0.43, 0), Vector2(0, 0.8)]), 0.03, orange, Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(tc.x, 0.02, tc.z - 0.56)))
	k.prism(PackedVector2Array([Vector2(-0.3, 0), Vector2(0.3, 0), Vector2(0, 0.6)]), 0.02, Color(0.24, 0.2, 0.18), Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), Vector3(tc.x, 0.02, tc.z + 0.57)))
	k.box(Vector3(0.36, 0.7, 0.02), orange.lightened(0.1), MeshKit.xf(Vector3(tc.x + 0.3, 0.32, tc.z + 0.66), Vector3(0, -40, -30)))
	_bx(k, Vector3(0.04, 0.04, 1.2), Color(0.3, 0.32, 0.36), tc.x, 0.8, tc.z)
	for sz in [-0.6, 0.6]:
		k.cyl(0.015, 0.84, Color(0.3, 0.32, 0.36), MeshKit.at(tc.x, 0.0, tc.z + sz), 4)
		TownArt.beam(k, Vector3(tc.x, 0.82, tc.z + sz), Vector3(tc.x, 0.02, tc.z + sz * 1.55), 0.01, Color(0.9, 0.88, 0.8))
	for sd in [-1.0, 1.0]:
		for sz in [-0.35, 0.35]:
			TownArt.beam(k, Vector3(tc.x + sd * 0.4, 0.35, tc.z + sz), Vector3(tc.x + sd * 0.58, 0.02, tc.z + sz), 0.008, Color(0.9, 0.88, 0.8))
	# a sleeping bag and a backpack by the tent
	k.capsule(0.1, 0.6, Color(0.3, 0.5, 0.78), MeshKit.xf(Vector3(-0.55, 0.12, 0.25), Vector3(0, 30, 90)), 8, 2)
	k.rbox(Vector3(0.24, 0.36, 0.16), 0.05, Color(0.4, 0.5, 0.3), MeshKit.xf(Vector3(-0.68, 0.2, -0.45), Vector3(0, 20, -8)), 1)
	# ---- the camp kitchen: a folding table, stove, kettle, cooler, jerrycan
	var ct := Vector3(0.65, 0, -0.32)
	_bx(k, Vector3(0.8, 0.03, 0.42), Color(0.86, 0.86, 0.84), ct.x, 0.66, ct.z)
	for sx in [-0.36, 0.36]:
		TownArt.beam(k, ct + Vector3(sx, 0, -0.16), ct + Vector3(sx, 0.65, 0.16), 0.02, Color(0.5, 0.52, 0.54))
		TownArt.beam(k, ct + Vector3(sx, 0, 0.16), ct + Vector3(sx, 0.65, -0.16), 0.02, Color(0.5, 0.52, 0.54))
	_bx(k, Vector3(0.34, 0.07, 0.22), Color(0.3, 0.32, 0.36), ct.x - 0.15, 0.71, ct.z)
	k.cyl(0.07, 0.11, Color(0.8, 0.3, 0.26), MeshKit.at(ct.x - 0.22, 0.745, ct.z), 8)
	k.cyl(0.08, 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(ct.x - 0.06, 0.745, ct.z), 8)
	k.cyl(0.04, 0.12, Color(0.95, 0.95, 0.94), MeshKit.at(ct.x + 0.2, 0.675, ct.z + 0.08), 6)
	k.cyl(0.04, 0.12, Color(0.3, 0.5, 0.8), MeshKit.at(ct.x + 0.3, 0.675, ct.z - 0.05), 6)
	k.rbox(Vector3(0.46, 0.32, 0.3), 0.05, Color(0.86, 0.32, 0.26), MeshKit.at(ct.x + 0.05, 0.17, ct.z + 0.02), 1)
	_bx(k, Vector3(0.48, 0.06, 0.32), Color(0.95, 0.95, 0.94), ct.x + 0.05, 0.33, ct.z + 0.02)
	_bx(k, Vector3(0.2, 0.32, 0.12), Color(0.36, 0.5, 0.36), 1.2, 0.18, -0.15)
	_bx(k, Vector3(0.06, 0.06, 0.04), Color(0.2, 0.2, 0.22), 1.2, 0.37, -0.15)
	# a fire pit: a ring of stones, logs, glowing embers
	var fp := Vector3(0.1, 0, 0.1)
	for i in 9:
		var a := TAU * i / 9.0
		k.sphere(0.07, Color(0.56, 0.54, 0.5).darkened(0.05 * (i % 3)), MeshKit.xf(fp + Vector3(cos(a) * 0.24, 0.04, sin(a) * 0.24), Vector3.ZERO, Vector3(1.2, 0.8, 1.0)), 5, 3)
	for i in 3:
		k.cyl(0.03, 0.3, Pal.WOOD_DARK, MeshKit.xf(fp + Vector3(0, 0.05, 0), Vector3(70, i * 60.0, 0)) * MeshKit.at(0, -0.15, 0), 5)
	k.sphere(0.1, Color(1.0, 0.55, 0.2, 0.3), MeshKit.xf(fp + Vector3(0, 0.08, 0), Vector3.ZERO, Vector3(1, 0.6, 1)), 6, 3)
	k.cone(0.06, 0.2, Color(1.0, 0.8, 0.3, 0.3), MeshKit.at(fp.x, 0.08, fp.z), 5)
	# a clothes line from the van mirror to a pole, with laundry
	k.cyl(0.02, 1.5, Pal.WOOD, MeshKit.at(1.62, 0.0, 0.2), 5)
	TownArt.beam(k, Vector3(1.35, 1.45, vz + 0.5), Vector3(1.62, 1.45, 0.2), 0.008, Color(0.9, 0.88, 0.8))
	for i in 3:
		var q := Vector3(1.35, 1.45, vz + 0.5).lerp(Vector3(1.62, 1.45, 0.2), 0.25 + i * 0.25)
		_bx(k, Vector3(0.03, 0.26, 0.2), [Color(0.86, 0.36, 0.3), Color(0.96, 0.96, 0.94), Color(0.3, 0.5, 0.8)][i], q.x, q.y - 0.14, q.z)
	# a lantern on a pole, a bike leaning on the van
	k.cyl(0.015, 1.1, Color(0.3, 0.32, 0.36), MeshKit.at(-0.55, 0.0, 0.42), 4)
	_bx(k, Vector3(0.2, 0.02, 0.02), Color(0.3, 0.32, 0.36), -0.47, 1.1, 0.42)
	k.cyl(0.05, 0.12, Color(1.0, 0.85, 0.55, 0.3), MeshKit.at(-0.4, 0.95, 0.42), 6)
	var bk := MeshKit.xf(Vector3(1.6, 0, -0.75), Vector3(0, 90, 8))
	for sz in [-0.3, 0.3]:
		k.torus(0.2, 0.02, Pal.RUBBER, bk * MeshKit.xf(Vector3(0, 0.22, sz), Vector3(0, 0, 90)), 10, 3)
	TownArt.beam(k, bk * Vector3(0, 0.22, -0.3), bk * Vector3(0, 0.5, 0.1), 0.025, Color(0.86, 0.3, 0.26))
	TownArt.beam(k, bk * Vector3(0, 0.22, 0.3), bk * Vector3(0, 0.55, 0.15), 0.025, Color(0.86, 0.3, 0.26))
	TownArt.beam(k, bk * Vector3(0, 0.5, -0.12), bk * Vector3(0, 0.55, 0.2), 0.025, Color(0.86, 0.3, 0.26))


# ---------------------------------------------------------------- 1 bunks

static func _bunks(k: MeshKit) -> void:
	var green := Color(0.34, 0.5, 0.42)
	var blue := Color(0.36, 0.48, 0.62)
	var yel := Color(0.96, 0.76, 0.2)
	var steel := Color(0.36, 0.38, 0.42)
	var glass := Color(0.6, 0.76, 0.86, 0.7)
	# ground: gravel with a concrete pad and stepping slabs
	_bx(k, Vector3(3.8, 0.02, 3.8), Color(0.66, 0.65, 0.62), 0, 0.01, 0)
	_bx(k, Vector3(3.5, 0.05, 1.7), Color(0.74, 0.74, 0.72), -0.2, 0.03, -1.12)
	for i in 4:
		_bx(k, Vector3(0.36, 0.03, 0.26), Color(0.76, 0.76, 0.74), 1.6, 0.025, -0.1 + i * 0.5)
	var z0 := -1.85
	var z1 := -0.55
	var cz := (z0 + z1) * 0.5
	var h := 2.15
	# the lower container (green) and the upper one (blue), shifted left
	CafeB._container(k, Vector3(-0.22, 0.06, cz), 3.25, h, z1 - z0, green, false)
	CafeB._container(k, Vector3(-0.38, h + 0.06, cz), 3.0, h, z1 - z0, blue, false)
	for c in [[-0.22, 0.06, 3.25, green], [-0.38, h + 0.06, 3.0, blue]]:
		var cx: float = c[0]
		var y0: float = c[1]
		var l: float = c[2]
		var col: Color = c[3]
		for i in int(l / 0.18):
			var x := cx - l * 0.5 + 0.12 + i * 0.18
			_bx(k, Vector3(0.07, h - 0.24, 0.03), col.darkened(0.12), x, y0 + h * 0.5, z1 + 0.012)
		# two windows with frames and an AC box, a door
		for wx in [cx - l * 0.32, cx + l * 0.05]:
			_bx(k, Vector3(0.62, 0.5, 0.05), Color(0.92, 0.92, 0.9), wx, y0 + 1.35, z1 + 0.03)
			_bx(k, Vector3(0.54, 0.42, 0.04), glass, wx, y0 + 1.35, z1 + 0.05)
			_bx(k, Vector3(0.03, 0.42, 0.05), Color(0.92, 0.92, 0.9), wx, y0 + 1.35, z1 + 0.06)
		_bx(k, Vector3(0.66, 1.8, 0.05), Color(0.92, 0.92, 0.9), cx + l * 0.36, y0 + 0.95, z1 + 0.03)
		_bx(k, Vector3(0.56, 1.72, 0.04), col.darkened(0.25), cx + l * 0.36, y0 + 0.92, z1 + 0.05)
		_bx(k, Vector3(0.05, 0.12, 0.04), Color(0.8, 0.8, 0.8), cx + l * 0.36 + 0.2, y0 + 0.92, z1 + 0.09)
		_bx(k, Vector3(0.3, 0.12, 0.02), Color(0.96, 0.96, 0.94), cx + l * 0.36, y0 + 1.95, z1 + 0.05)
		k.sphere(0.05, Color(1.0, 0.9, 0.6, 0.35), MeshKit.at(cx + l * 0.36 + 0.42, y0 + 1.75, z1 + 0.1), 6, 3)
		# split AC boxes on the wall
		_bx(k, Vector3(0.48, 0.18, 0.14), Color(0.92, 0.92, 0.9), cx - l * 0.32, y0 + 1.82, z1 + 0.08)
	# window boxes with flowers on the upper floor, laundry on the rail
	for wx in [-0.38 - 3.0 * 0.32, -0.38 + 3.0 * 0.05]:
		_bx(k, Vector3(0.6, 0.12, 0.14), Pal.WOOD, wx, h + 0.06 + 1.04, z1 + 0.12)
		for i in 4:
			k.sphere(0.05, [Color(0.86, 0.4, 0.4), Color(0.96, 0.86, 0.4), Pal.LEAF, Color(0.6, 0.5, 0.8)][i], MeshKit.at(wx - 0.2 + i * 0.13, h + 1.18, z1 + 0.12), 5, 3)
	# ---- the walkway along the upper floor and the steel stair up to it
	var wy := h + 0.06
	_bx(k, Vector3(2.0, 0.06, 0.5), Color(0.56, 0.58, 0.6), 0.45, wy, z1 + 0.26)
	for i in 10:
		_bx(k, Vector3(0.02, 0.02, 0.48), Color(0.4, 0.42, 0.44), -0.5 + i * 0.2, wy + 0.04, z1 + 0.26)
	ArchKit.railing(k, Vector3(-0.55, wy, z1 + 0.5), Vector3(1.43, wy, z1 + 0.5), 0.95, yel, 0.5)
	ArchKit.railing(k, Vector3(1.43, wy, z1 + 0.5), Vector3(1.43, wy, z1 + 0.02), 0.95, yel, 0.5)
	for x in [-0.5, 1.4]:
		_bx(k, Vector3(0.07, wy, 0.07), steel, x, wy * 0.5, z1 + 0.48)
	TownArt.stair(k, Vector3(-1.8, 0.04, z1 + 0.32), Vector3(-0.5, wy, z1 + 0.32), 0.42, Color(0.56, 0.58, 0.6), steel, yel)
	_bx(k, Vector3(0.06, wy * 0.5, 0.06), steel, -1.15, wy * 0.25, z1 + 0.32)
	# pot plants and a chair on the walkway, laundry hanging on the rail
	for i in 2:
		k.cyl(0.08, 0.16, Color(0.74, 0.44, 0.32), MeshKit.at(0.1 + i * 0.75, wy + 0.03, z1 + 0.12), 7, 0.02, 0.06)
		k.sphere(0.1, Pal.LEAF, MeshKit.at(0.1 + i * 0.75, wy + 0.28, z1 + 0.12), 6, 3)
	for i in 3:
		_bx(k, Vector3(0.22, 0.3, 0.02), [Color(0.86, 0.36, 0.3), Color(0.3, 0.5, 0.8), Color(0.96, 0.96, 0.94)][i], 0.3 + i * 0.28, wy + 0.8, z1 + 0.52)
	k.cyl(0.13, 0.03, Color(0.3, 0.5, 0.8), MeshKit.at(1.15, wy + 0.4, z1 + 0.25), 8)
	k.cyl(0.02, 0.4, steel, MeshKit.at(1.15, wy, z1 + 0.25), 4)
	# ---- the door end: locking bars on the ends of both boxes
	# roof of the upper box: a water tank and an antenna (clear of the slots)
	var ry := 2.0 * h + 0.06
	k.cyl(0.22, 0.5, Color(0.2, 0.22, 0.26), MeshKit.at(-1.45, ry, -1.0), 10)
	k.cyl(0.24, 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(-1.45, ry + 0.5, -1.0), 10)
	k.cyl(0.012, 1.1, Color(0.8, 0.8, 0.82), MeshKit.at(0.95, ry, -0.8), 4)
	for j in 3:
		_bx(k, Vector3(0.3 - j * 0.08, 0.012, 0.012), Color(0.8, 0.8, 0.82), 0.95, ry + 0.6 + j * 0.15, -0.8)
	ArchKit.cable_tray(k, Vector3(-1.7, ry + 0.02, -0.7), Vector3(0.75, ry + 0.02, -0.7), 1)
	# ---- the yard: bikes under the stair, bins, a mailbox, a light
	for i in 2:
		var bk := MeshKit.xf(Vector3(-1.3 + i * 0.3, 0, -0.08), Vector3(0, 90, 0))
		for sz in [-0.28, 0.28]:
			k.torus(0.18, 0.02, Pal.RUBBER, bk * MeshKit.xf(Vector3(0, 0.2, sz), Vector3(0, 0, 90)), 10, 3)
		TownArt.beam(k, bk * Vector3(0, 0.2, -0.28), bk * Vector3(0, 0.46, 0.1), 0.025, [yel, Color(0.3, 0.5, 0.8)][i])
		TownArt.beam(k, bk * Vector3(0, 0.2, 0.28), bk * Vector3(0, 0.5, 0.12), 0.025, [yel, Color(0.3, 0.5, 0.8)][i])
	_bx(k, Vector3(0.05, 1.0, 0.05), steel, 1.15, 0.5, 0.2)
	_bx(k, Vector3(0.3, 0.22, 0.18), Color(0.86, 0.3, 0.26), 1.15, 1.05, 0.2)
	_bx(k, Vector3(0.2, 0.02, 0.01), Color(0.2, 0.2, 0.22), 1.15, 1.1, 0.295)
	TownArt.floodlight(k, MeshKit.xf(Vector3(1.3, 2.0, z1 + 0.05), Vector3(0, 0, 0)))
	TownArt.floodlight(k, MeshKit.xf(Vector3(-1.5, 2.0, z1 + 0.05), Vector3(0, 0, 0)))
	# a shoe rack and doormat by the lower door
	_bx(k, Vector3(0.6, 0.012, 0.36), Color(0.36, 0.3, 0.26), -0.22 + 3.25 * 0.36, 0.07, z1 + 0.25)
	_bx(k, Vector3(0.5, 0.3, 0.2), Pal.WOOD_LIGHT, -0.22 + 3.25 * 0.36 - 0.6, 0.2, z1 + 0.16)


# ---------------------------------------------------------------- 2 townhouse

static func _townhouse(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var white2 := Color(0.86, 0.88, 0.9)
	var teal := Color(0.3, 0.66, 0.68)
	var glass := Color(0.58, 0.8, 0.92, 0.66)
	var wood := Color(0.72, 0.56, 0.4)
	var frame := Color(0.3, 0.34, 0.38)
	# ground: a lawn, a paved path to the door, a low hedge
	_bx(k, Vector3(3.8, 0.02, 3.8), Color(0.5, 0.62, 0.38), 0, 0.01, 0)
	_bx(k, Vector3(3.5, 0.03, 0.4), Color(0.84, 0.82, 0.78), -0.2, 0.02, -0.15)
	var z0 := -1.85
	var z1 := -0.35
	var cz := (z0 + z1) * 0.5
	var x0 := -1.85
	var x1 := 1.42
	var cx := (x0 + x1) * 0.5
	var h := 4.5
	_bx(k, Vector3(x1 - x0, h, z1 - z0), white, cx, h * 0.5 + 0.02, cz)
	_bx(k, Vector3(x1 - x0 + 0.04, 0.3, z1 - z0 + 0.04), Color(0.6, 0.6, 0.6), cx, 0.15, cz)
	# a timber-clad bay on the right, full height
	var tx0 := 0.35
	_bx(k, Vector3(x1 - tx0, h - 0.3, 0.06), wood, (tx0 + x1) * 0.5, h * 0.5 + 0.15, z1 + 0.03)
	for i in int((x1 - tx0) / 0.09):
		_bx(k, Vector3(0.025, h - 0.3, 0.03), wood.darkened(0.18), tx0 + 0.045 + i * 0.09, h * 0.5 + 0.15, z1 + 0.065)
	# storey line and parapet
	_bx(k, Vector3(x1 - x0 + 0.04, 0.08, z1 - z0 + 0.04), white2, cx, 2.3, cz)
	ArchKit.parapet(k, Vector3(cx, h + 0.02, cz), x1 - x0, z1 - z0, 2)
	# ground floor: the door with a canopy and lamp, a big window
	var dx := 0.88
	_bx(k, Vector3(0.7, 1.95, 0.06), frame, dx, 1.0, z1 + 0.08)
	_bx(k, Vector3(0.6, 1.85, 0.04), teal, dx, 0.96, z1 + 0.11)
	_bx(k, Vector3(0.14, 1.5, 0.02), glass, dx - 0.14, 1.0, z1 + 0.135)
	_bx(k, Vector3(0.04, 0.3, 0.05), Pal.BRASS, dx + 0.2, 1.0, z1 + 0.14)
	_bx(k, Vector3(1.0, 0.07, 0.5), white2, dx, 2.05, z1 + 0.25)
	for sx in [-0.46, 0.46]:
		TownArt.beam(k, Vector3(dx + sx, 1.7, z1 + 0.06), Vector3(dx + sx, 2.02, z1 + 0.45), 0.025, frame)
	_bx(k, Vector3(0.12, 0.2, 0.08), frame, dx - 0.5, 1.6, z1 + 0.1)
	k.sphere(0.05, Color(1.0, 0.9, 0.6, 0.35), MeshKit.at(dx - 0.5, 1.56, z1 + 0.16), 6, 3)
	_bx(k, Vector3(0.18, 0.12, 0.02), Pal.BRASS, dx + 0.52, 1.5, z1 + 0.08)
	_bx(k, Vector3(0.6, 0.06, 0.3), Color(0.7, 0.7, 0.7), dx, 0.06, z1 + 0.2)
	_bx(k, Vector3(1.5, 1.3, 0.06), frame, -0.75, 1.15, z1 + 0.03)
	_bx(k, Vector3(1.42, 1.22, 0.04), glass, -0.75, 1.15, z1 + 0.05)
	for i in 2:
		_bx(k, Vector3(0.03, 1.22, 0.05), frame, -1.22 + i * 0.94, 1.15, z1 + 0.07)
	_bx(k, Vector3(1.6, 0.05, 0.16), white2, -0.75, 0.48, z1 + 0.08)
	# a window box under it with flowers
	_bx(k, Vector3(1.4, 0.16, 0.16), wood, -0.75, 0.38, z1 + 0.14)
	for i in 8:
		k.sphere(0.06, [Color(0.86, 0.4, 0.42), Color(0.96, 0.92, 0.84), Color(0.92, 0.7, 0.36), Pal.LEAF][i % 4], MeshKit.at(-1.38 + i * 0.18, 0.5, z1 + 0.14), 5, 3)
	# ---- first floor: two balconies with French doors and glass rails
	for b in 2:
		var bx: float = [-0.95, 0.88][b]
		var bw: float = [1.5, 1.0][b]
		var fy := 2.36
		_bx(k, Vector3(bw - 0.3, 1.75, 0.06), frame, bx, fy + 0.9, z1 + 0.03)
		_bx(k, Vector3(bw - 0.4, 1.65, 0.04), glass, bx, fy + 0.86, z1 + 0.05)
		_bx(k, Vector3(0.03, 1.65, 0.05), frame, bx, fy + 0.86, z1 + 0.07)
		_bx(k, Vector3(bw, 0.1, 0.62), white2, bx, fy - 0.03, z1 + 0.31)
		_bx(k, Vector3(bw, 0.8, 0.02), Color(0.7, 0.86, 0.92, 0.75), bx, fy + 0.42, z1 + 0.6)
		_bx(k, Vector3(bw + 0.02, 0.04, 0.05), frame, bx, fy + 0.84, z1 + 0.6)
		for sx in [-1.0, 1.0]:
			_bx(k, Vector3(0.02, 0.8, 0.6), Color(0.7, 0.86, 0.92, 0.75), bx + sx * bw * 0.5, fy + 0.42, z1 + 0.31)
			_bx(k, Vector3(0.04, 0.04, 0.6), frame, bx + sx * bw * 0.5, fy + 0.84, z1 + 0.31)
		# a chair, a pot plant
		k.cyl(0.1, 0.18, white2, MeshKit.at(bx - bw * 0.35, fy + 0.02, z1 + 0.42), 7, 0.02, 0.08)
		k.sphere(0.12, Pal.LEAF, MeshKit.at(bx - bw * 0.35, fy + 0.3, z1 + 0.42), 6, 3)
		_bx(k, Vector3(0.28, 0.04, 0.26), teal, bx + bw * 0.25, fy + 0.4, z1 + 0.35)
		_bx(k, Vector3(0.28, 0.3, 0.04), teal, bx + bw * 0.25, fy + 0.55, z1 + 0.22)
	# a teal fascia band, a roof terrace pergola on the left, solar on the right
	_bx(k, Vector3(x1 - x0 + 0.06, 0.12, 0.06), teal, cx, h - 0.15, z1 + 0.04)
	var ry := h + 0.05
	for p in [Vector3(-1.75, 0, -1.75), Vector3(-1.75, 0, -0.5), Vector3(-0.85, 0, -0.5)]:
		_bx(k, Vector3(0.06, 1.1, 0.06), wood, p.x, ry + 0.55, p.z)
	for i in 6:
		_bx(k, Vector3(0.04, 0.06, 1.3), wood, -1.78 + i * 0.18, ry + 1.12, -1.12)
	_bx(k, Vector3(1.0, 0.06, 0.06), wood, -1.3, ry + 1.08, -0.5)
	_bx(k, Vector3(0.6, 0.3, 0.3), white2, -1.5, ry + 0.15, -0.65)
	k.sphere(0.22, Pal.LEAF, MeshKit.at(-1.5, ry + 0.45, -0.65), 7, 4)
	k.cyl(0.18, 0.03, white, MeshKit.at(-1.25, ry + 0.4, -1.3), 8)
	k.cyl(0.02, 0.4, frame, MeshKit.at(-1.25, ry, -1.3), 4)
	# downpipes and a side window
	for sx in [x0 + 0.05, x1 - 0.05]:
		k.cyl(0.035, h, white2, MeshKit.at(sx, 0.0, z1 - 0.05), 6)
	_bx(k, Vector3(0.04, 0.8, 0.6), glass, x0 - 0.02, 3.2, cz)
	_bx(k, Vector3(0.04, 0.8, 0.6), glass, x1 + 0.02, 3.2, cz)
	# a striped awning over the big window, bay trees by the door, steps
	for i in 8:
		k.box(Vector3(0.2, 0.025, 0.42), teal if i % 2 == 0 else white, MeshKit.xf(Vector3(-1.45 + i * 0.2, 1.95, z1 + 0.2), Vector3(-25, 0, 0)))
		_bx(k, Vector3(0.2, 0.1, 0.02), teal if i % 2 == 1 else white, -1.45 + i * 0.2, 1.81, z1 + 0.4)
	for sx in [-0.45, 0.45]:
		k.cyl(0.13, 0.3, Color(0.3, 0.32, 0.36), MeshKit.at(dx + sx, 0.02, z1 + 0.28), 8, 0.02, 0.1)
		k.cyl(0.02, 0.45, Pal.WOOD_DARK, MeshKit.at(dx + sx, 0.3, z1 + 0.28), 4)
		k.sphere(0.17, Pal.LEAF_DARK, MeshKit.at(dx + sx, 0.85, z1 + 0.28), 7, 4)
	for i in 2:
		_bx(k, Vector3(0.74, 0.08, 0.2), Color(0.78, 0.78, 0.76), dx, 0.04 + i * 0.08, z1 + 0.42 - i * 0.12)
	# intercom, house number, a wall lamp upstairs
	_bx(k, Vector3(0.1, 0.16, 0.03), Color(0.3, 0.32, 0.36), dx + 0.48, 1.15, z1 + 0.08)
	k.sphere(0.05, Color(1.0, 0.9, 0.6, 0.35), MeshKit.at(0.2, 3.9, z1 + 0.08), 6, 3)
	# a low hedge between the house and the benches, gap for the path
	for i in 7:
		k.sphere(0.17, Pal.LEAF_DARK if i % 2 else Pal.LEAF, MeshKit.xf(Vector3(-1.7 + i * 0.3, 0.17, 0.3), Vector3.ZERO, Vector3(1.0, 0.9, 0.8)), 7, 4)
	_bx(k, Vector3(2.05, 0.12, 0.3), white2, -0.8, 0.06, 0.3)
	# roof: a steel flue, a hatch, string lights on the pergola
	k.cyl(0.07, 0.8, Color(0.62, 0.64, 0.66), MeshKit.at(1.1, ry, -1.65), 6)
	k.cone(0.12, 0.1, Color(0.5, 0.52, 0.54), MeshKit.at(1.1, ry + 0.8, -1.65), 6)
	_bx(k, Vector3(0.5, 0.15, 0.5), white2, 1.05, ry + 0.07, -0.75)
	ArchKit.string_lights(k, Vector3(-1.75, ry + 1.05, -0.5), Vector3(-0.85, ry + 1.05, -0.5), 4)
	ArchKit.string_lights(k, Vector3(-1.75, ry + 1.05, -1.75), Vector3(-1.75, ry + 1.05, -0.5), 4)
	# a bin store
	_bx(k, Vector3(0.7, 0.6, 0.42), wood, -1.45, 0.32, 0.12)
	for i in 2:
		_bx(k, Vector3(0.3, 0.02, 0.38), [Color(0.3, 0.5, 0.36), Color(0.3, 0.42, 0.66)][i], -1.6 + i * 0.32, 0.63, 0.12)


# ---------------------------------------------------------------- 3 deck block

static func _deck_block(k: MeshKit) -> void:
	var grey := Color(0.5, 0.54, 0.6)
	var dark := Color(0.22, 0.24, 0.28)
	var steel := Color(0.62, 0.65, 0.7)
	var glass := Color(0.42, 0.62, 0.82, 0.62)
	var blue := Color(0.45, 0.75, 1.0, 0.45)
	var yel := Color(0.98, 0.8, 0.22)
	# ground: a dark slab, yellow lines, gravel strips
	_bx(k, Vector3(3.8, 0.02, 3.8), Color(0.46, 0.48, 0.52), 0, 0.01, 0)
	for i in 3:
		_bx(k, Vector3(0.06, 0.006, 1.6), yel, -1.2 + i * 1.2, 0.022, 1.1)
	var x0 := -1.85
	var x1 := 1.42
	var cx := (x0 + x1) * 0.5
	var z0 := -1.85
	var z1 := -0.85
	var cz := (z0 + z1) * 0.5
	var fh := 2.0
	var floors := 3
	var h := fh * floors
	_bx(k, Vector3(x1 - x0, h, z1 - z0), grey, cx, h * 0.5 + 0.02, cz)
	# each floor: three flats with glass doors, a window, spandrel panels
	for f in floors:
		var y0 := f * fh + 0.02
		_bx(k, Vector3(x1 - x0 + 0.04, 0.2, z1 - z0 + 0.04), dark, cx, y0 + fh - 0.1, cz)
		for u in 3:
			var ux := x0 + 0.55 + u * 1.09
			_bx(k, Vector3(0.5, 1.55, 0.05), dark, ux - 0.12, y0 + 0.8, z1 + 0.02)
			_bx(k, Vector3(0.42, 1.48, 0.04), glass if (u + f) % 3 else Color(1.0, 0.86, 0.6, 0.5), ux - 0.12, y0 + 0.78, z1 + 0.04)
			_bx(k, Vector3(0.36, 0.9, 0.05), dark, ux + 0.32, y0 + 1.05, z1 + 0.02)
			_bx(k, Vector3(0.3, 0.84, 0.04), glass, ux + 0.32, y0 + 1.05, z1 + 0.04)
			_bx(k, Vector3(0.12, 0.1, 0.02), Color(0.95, 0.95, 0.94), ux - 0.12, y0 + 1.65, z1 + 0.05)
			_bx(k, Vector3(0.34, 0.16, 0.14), Color(0.86, 0.87, 0.88), ux + 0.32, y0 + 1.68, z1 + 0.08)
	# the open stair tower on the left, steel frame and flights
	var sx0 := x0
	var sx1 := x0 + 0.62
	var sz0 := z1
	var sz1 := z1 + 0.95
	for x in [sx0 + 0.04, sx1 - 0.04]:
		for z in [sz0 + 0.04, sz1 - 0.04]:
			_bx(k, Vector3(0.08, h + 0.6, 0.08), dark, x, (h + 0.6) * 0.5, z)
	for f in floors:
		var y := (f + 1) * fh
		_bx(k, Vector3(sx1 - sx0, 0.06, 0.4), steel.darkened(0.2), (sx0 + sx1) * 0.5, y, sz0 + 0.24)
		var up := f % 2 == 0
		TownArt.stair(k, Vector3((sx0 + sx1) * 0.5, y - fh + 0.02, sz1 - 0.1 if up else sz0 + 0.5), Vector3((sx0 + sx1) * 0.5, y, sz0 + 0.45 if up else sz1 - 0.1), 0.5, steel.darkened(0.15), dark)
	for f in floors + 1:
		_bx(k, Vector3(sx1 - sx0, 0.05, 0.05), yel, (sx0 + sx1) * 0.5, f * fh + 0.95, sz1 - 0.04)
		_bx(k, Vector3(0.05, 0.05, sz1 - sz0), yel, sx0 + 0.04, f * fh + 0.95, (sz0 + sz1) * 0.5)
	_bx(k, Vector3(sx1 - sx0 + 0.1, 0.08, sz1 - sz0 + 0.1), dark, (sx0 + sx1) * 0.5, h + 0.6, (sz0 + sz1) * 0.5)
	# deck-access walkways on each upper floor with LED strips and planters
	for f in range(1, floors):
		var y := f * fh + 0.02
		_bx(k, Vector3(x1 - sx1, 0.1, 0.55), steel.darkened(0.1), (sx1 + x1) * 0.5, y, z1 + 0.28)
		_bx(k, Vector3(x1 - sx1, 0.02, 0.02), blue, (sx1 + x1) * 0.5, y - 0.06, z1 + 0.54)
		ArchKit.railing(k, Vector3(sx1, y + 0.05, z1 + 0.54), Vector3(x1 - 0.02, y + 0.05, z1 + 0.54), 0.95, dark, 0.3)
		ArchKit.railing(k, Vector3(x1 - 0.02, y + 0.05, z1 + 0.54), Vector3(x1 - 0.02, y + 0.05, z1 + 0.02), 0.95, dark, 0.3)
		for u in 3:
			var ux := x0 + 0.55 + u * 1.09
			k.box(Vector3(0.36, 0.22, 0.2), Color(0.36, 0.38, 0.42), MeshKit.at(ux + 0.32, y + 0.16, z1 + 0.22))
			k.sphere(0.13, Pal.LEAF if u % 2 else Pal.LEAF_DARK, MeshKit.at(ux + 0.32, y + 0.38, z1 + 0.22), 6, 3)
		for i in 3:
			_bx(k, Vector3(0.2, 0.28, 0.02), [Color(0.86, 0.36, 0.3), Color(0.96, 0.96, 0.94), Color(0.3, 0.5, 0.8)][(i + f) % 3], -0.3 + i * 0.26 + f * 0.2, y + 0.82, z1 + 0.56)
	# walkway columns down to the ground
	for x in [sx1 + 0.04, 0.0, x1 - 0.06]:
		_bx(k, Vector3(0.1, h - fh * 0.0 - 2.0 + 2.0, 0.1), dark, x, (h) * 0.5, z1 + 0.5)
	# ground floor: a lobby with a canopy and a lit sign, mailboxes,
	# parcel lockers, a bike rack with bikes, privacy screens upstairs
	var lx := 0.85
	_bx(k, Vector3(0.9, 1.9, 0.06), dark, lx, 0.97, z1 + 0.06)
	for sx in [-0.2, 0.2]:
		_bx(k, Vector3(0.38, 1.8, 0.04), Color(0.6, 0.78, 0.9, 0.6), lx + sx, 0.93, z1 + 0.1)
	_bx(k, Vector3(1.2, 0.08, 0.6), dark, lx, 1.85, z1 + 0.32)
	TownArt.word(k, MeshKit.at(lx, 1.95, z1 + 0.62), "HOME", 0.16, blue, 0.18, 0.03)
	for i in 4:
		for j in 3:
			_bx(k, Vector3(0.16, 0.12, 0.03), Color(0.7, 0.72, 0.76), -0.5 + i * 0.18, 0.95 + j * 0.14, z1 + 0.03)
			_bx(k, Vector3(0.08, 0.015, 0.01), dark, -0.5 + i * 0.18, 0.99 + j * 0.14, z1 + 0.05)
	for i in 3:
		for j in 4:
			_bx(k, Vector3(0.2, 0.26, 0.04), Color(0.95, 0.75, 0.2) if (i + j) % 5 else Color(0.86, 0.87, 0.88), -1.2 + i * 0.22, 0.25 + j * 0.28, z1 + 0.03)
			_bx(k, Vector3(0.025, 0.025, 0.01), Color(0.5, 1.0, 0.6, 0.4) if (i + j) % 3 else Color(1.0, 0.4, 0.35, 0.4), -1.15 + i * 0.22, 0.3 + j * 0.28, z1 + 0.055)
	for i in 3:
		var bk := MeshKit.xf(Vector3(-0.15 + i * 0.32, 0, -0.25), Vector3(0, 0, 0))
		_bx(k, Vector3(0.03, 0.4, 0.3), dark, -0.15 + i * 0.32 + 0.12, 0.2, -0.25)
		for sz in [-0.26, 0.26]:
			k.torus(0.17, 0.018, Pal.RUBBER, bk * MeshKit.xf(Vector3(0, 0.19, sz), Vector3(0, 0, 90)), 10, 3)
		TownArt.beam(k, bk * Vector3(0, 0.19, -0.26), bk * Vector3(0, 0.45, 0.08), 0.022, [yel, Color(0.3, 0.5, 0.86), Color(0.86, 0.3, 0.26)][i])
		TownArt.beam(k, bk * Vector3(0, 0.19, 0.26), bk * Vector3(0, 0.48, 0.1), 0.022, [yel, Color(0.3, 0.5, 0.86), Color(0.86, 0.3, 0.26)][i])
	for f in range(1, floors):
		for u in range(1, 3):
			_bx(k, Vector3(0.04, 0.85, 0.48), Color(0.8, 0.88, 0.94, 0.8), x0 + 0.02 + u * 1.09, f * fh + 0.5, z1 + 0.27)
	# accent stripes on the right end
	for j in floors:
		_bx(k, Vector3(0.03, fh - 0.3, 0.3), yel if j % 2 == 0 else Color(0.3, 0.66, 0.68), x1 + 0.015, j * fh + fh * 0.5, z0 + 0.3)
	_bx(k, Vector3(x1 - x0 + 0.04, 0.03, 0.03), blue, cx, 0.1, z1 + 0.03)
	# roof: a parapet with a blue LED, a plant room, a beacon (clear of slots)
	ArchKit.parapet(k, Vector3(cx, h + 0.02, cz), x1 - x0, z1 - z0, 3)
	ArchKit.louvres(k, MeshKit.at(1.05, h + 0.02, z1 - 0.06), 0.55, 0.6, steel, 5)
	ArchKit.beacon(k, Vector3(x1 - 0.15, h + 0.02, z0 + 0.15), 0.6)
	ArchKit.ac_unit(k, MeshKit.at(-1.25, h + 0.02, -1.35), 3, 0.7)


# ---------------------------------------------------------------- 4 tower

static func _tower(k: MeshKit) -> void:
	var g := Color(0.17, 0.18, 0.21)
	var g2 := Color(0.24, 0.25, 0.29)
	var brass := Color(0.78, 0.63, 0.38)
	var glass := Color(0.32, 0.5, 0.7, 0.55)
	var gold := Color(1.0, 0.86, 0.5, 0.4)
	var cyan := Color(0.42, 0.9, 1.0, 0.45)
	# ground: dark tiles with glowing seams, a brass edge
	_bx(k, Vector3(3.8, 0.02, 3.8), Color(0.2, 0.21, 0.24), 0, 0.01, 0)
	for i in 8:
		_bx(k, Vector3(0.02, 0.006, 3.8), Color(0.42, 0.9, 1.0, 0.5), -1.75 + i * 0.5, 0.023, 0)
	_bx(k, Vector3(3.8, 0.03, 0.04), brass, 0, 0.03, 1.87)
	var x0 := -1.6
	var x1 := 1.3
	var cx := (x0 + x1) * 0.5
	var z0 := -1.85
	var z1 := -0.45
	var cz := (z0 + z1) * 0.5
	var fh := 1.7
	# lobby: double height glass under a brass canopy
	var lh := 2.6
	_bx(k, Vector3(x1 - x0, lh, z1 - z0), g, cx, lh * 0.5, cz)
	_bx(k, Vector3(x1 - x0 - 0.3, lh - 0.3, 0.04), glass, cx, lh * 0.5, z1 + 0.02)
	for i in 8:
		_bx(k, Vector3(0.06, lh, 0.16), g2, x0 + 0.1 + i * 0.4, lh * 0.5, z1 + 0.08)
	_bx(k, Vector3(1.4, 0.1, 0.8), brass, 0.2, lh - 0.2, z1 + 0.4)
	_bx(k, Vector3(1.4, 0.02, 0.02), gold, 0.2, lh - 0.26, z1 + 0.8)
	_bx(k, Vector3(0.7, 2.0, 0.06), brass, 0.2, 1.0, z1 + 0.1)
	_bx(k, Vector3(0.56, 1.9, 0.07), Color(0.42, 0.62, 0.8, 0.6), 0.2, 0.96, z1 + 0.11)
	for sx in [-0.55, 0.95]:
		_bx(k, Vector3(0.3, 0.5, 0.3), g2, sx, 0.25, z1 + 0.3)
		k.sphere(0.2, Pal.CYPRESS, MeshKit.at(sx, 0.62, z1 + 0.3), 7, 4)
		k.sphere(0.13, Pal.CYPRESS.lightened(0.1), MeshKit.at(sx, 0.92, z1 + 0.3), 6, 3)
	# the shaft: floors of glass with graphite fins and brass balconies
	var floors := 4
	var top := lh
	for f in floors:
		var y0 := lh + f * fh
		var sky := f == 2
		if sky:
			# the sky garden: an open loggia with trees between columns
			_bx(k, Vector3(x1 - x0, 0.15, z1 - z0), g2, cx, y0 + 0.075, cz)
			_bx(k, Vector3(x1 - x0 - 0.2, fh, 0.6), g, cx, y0 + fh * 0.5, z0 + 0.3)
			_bx(k, Vector3(x1 - x0 - 0.3, fh - 0.4, 0.04), glass, cx, y0 + fh * 0.5, z0 + 0.62)
			for x in [x0 + 0.08, cx, x1 - 0.08]:
				_bx(k, Vector3(0.14, fh, 0.14), g2, x, y0 + fh * 0.5, z1 - 0.08)
			for i in 3:
				var tx := x0 + 0.6 + i * 0.9
				_bx(k, Vector3(0.5, 0.25, 0.4), g2, tx, y0 + 0.27, cz + 0.15)
				_bx(k, Vector3(0.52, 0.02, 0.42), brass, tx, y0 + 0.4, cz + 0.15)
				TownArt.tree(k, Vector3(tx, y0 + 0.4, cz + 0.15), 1.25, Pal.LEAF if i % 2 else Pal.LEAF_DARK, i + 7)
			_bx(k, Vector3(x1 - x0, 0.03, 0.03), gold, cx, y0 + 0.16, z1 - 0.01)
			_bx(k, Vector3(x1 - x0, 0.7, 0.02), Color(0.6, 0.8, 0.92, 0.7), cx, y0 + 0.5, z1 - 0.01)
			_bx(k, Vector3(x1 - x0, 0.04, 0.05), brass, cx, y0 + 0.86, z1 - 0.01)
		else:
			_bx(k, Vector3(x1 - x0, fh, z1 - z0), g, cx, y0 + fh * 0.5, cz)
			_bx(k, Vector3(x1 - x0 - 0.2, fh - 0.45, 0.04), glass, cx, y0 + fh * 0.5 + 0.05, z1 + 0.02)
			for i in 6:
				_bx(k, Vector3(0.05, fh - 0.2, 0.18), g2, x0 + 0.25 + i * 0.48, y0 + fh * 0.5, z1 + 0.09)
			_bx(k, Vector3(x1 - x0 + 0.04, 0.12, z1 - z0 + 0.04), g2, cx, y0 + 0.06, cz)
			# a brass balcony, alternating sides
			var bx := cx - 0.65 if f % 2 == 0 else cx + 0.65
			_bx(k, Vector3(1.3, 0.1, 0.45), g2, bx, y0 + 0.1, z1 + 0.22)
			_bx(k, Vector3(1.32, 0.05, 0.47), brass, bx, y0 + 0.17, z1 + 0.22)
			_bx(k, Vector3(1.3, 0.5, 0.02), Color(0.6, 0.8, 0.92, 0.7), bx, y0 + 0.45, z1 + 0.45)
			_bx(k, Vector3(1.32, 0.04, 0.05), brass, bx, y0 + 0.72, z1 + 0.45)
			for sx in [-0.65, 0.65]:
				_bx(k, Vector3(0.04, 0.55, 0.45), brass, bx + sx, y0 + 0.45, z1 + 0.22)
			_bx(k, Vector3(1.3, 0.02, 0.02), gold, bx, y0 + 0.04, z1 + 0.45)
			k.sphere(0.1, Pal.LEAF, MeshKit.at(bx + 0.45, y0 + 0.32, z1 + 0.25), 6, 3)
		top = y0 + fh
	# glowing vertical fins on the corners
	for sx in [x0 - 0.04, x1 + 0.04]:
		_bx(k, Vector3(0.1, top - lh, 0.2), g2, sx, (lh + top) * 0.5, z1 - 0.05)
		_bx(k, Vector3(0.02, top - lh - 0.4, 0.02), cyan, sx, (lh + top) * 0.5, z1 + 0.06)
	# the crown: a flat roof (the slots), brass fins at the front, a halo
	_bx(k, Vector3(x1 - x0 + 0.1, 0.15, z1 - z0 + 0.1), brass, cx, top + 0.07, cz)
	_bx(k, Vector3(x1 - x0 - 0.1, 0.03, z1 - z0 - 0.1), Color(0.12, 0.13, 0.15), cx, top + 0.16, cz)
	for i in 7:
		var fx := x0 + 0.1 + i * (x1 - x0 - 0.2) / 6.0
		var fhh := 1.0 + absf(3 - i) * -0.2 + 0.6
		_bx(k, Vector3(0.06, fhh, 0.25), brass, fx, top + 0.15 + fhh * 0.5, z1 - 0.15)
		_bx(k, Vector3(0.02, fhh - 0.1, 0.02), gold, fx, top + 0.15 + fhh * 0.5, z1 - 0.01)
	k.torus(0.55, 0.05, brass, MeshKit.xf(Vector3(cx, top + 2.0, z1 - 0.15), Vector3(90, 0, 0)), 18, 4)
	k.torus(0.45, 0.03, gold, MeshKit.xf(Vector3(cx, top + 2.0, z1 - 0.15), Vector3(90, 0, 0)), 18, 4)
	ArchKit.beacon(k, Vector3(x0 + 0.15, top + 0.17, z0 + 0.15), 0.9)
	ArchKit.beacon(k, Vector3(x1 - 0.15, top + 0.17, z0 + 0.15), 0.9)
	# a glowing RESIDENCE sign on the canopy, brass lamps, loungers
	TownArt.word(k, MeshKit.at(0.2, lh - 0.28, z1 + 0.81), "RESIDENCE", 0.12, gold, 0.16, 0.02)
	for sx in [-1.3, 1.1]:
		k.cyl(0.04, 1.4, brass, MeshKit.at(sx, 0.02, 0.15), 6)
		k.sphere(0.09, gold, MeshKit.at(sx, 1.48, 0.15), 6, 3)
	for f in floors:
		if f == 2:
			continue
		var y0 := lh + f * fh
		var bx := cx - 0.65 if f % 2 == 0 else cx + 0.65
		k.box(Vector3(0.24, 0.06, 0.34), Color(0.86, 0.84, 0.8), MeshKit.xf(Vector3(bx - 0.3, y0 + 0.24, z1 + 0.24), Vector3(0, 0, 0)))
		k.box(Vector3(0.24, 0.16, 0.04), Color(0.86, 0.84, 0.8), MeshKit.xf(Vector3(bx - 0.3, y0 + 0.3, z1 + 0.08), Vector3(-25, 0, 0)))
		_bx(k, Vector3(x1 - x0 + 0.02, 0.02, 0.02), gold, cx, y0 + fh - 0.02, z1 + 0.19)
	# a rooftop pool at the front with glowing water
	_bx(k, Vector3(1.8, 0.2, 0.46), g2, cx - 0.1, top + 0.25, z1 - 0.56)
	_bx(k, Vector3(1.7, 0.02, 0.36), Color(0.42, 0.9, 1.0, 0.45), cx - 0.1, top + 0.355, z1 - 0.56)
	# glowing coolant risers up the right side
	ArchKit.pipes(k, [Vector3(x1 + 0.12, 0.05, z0 + 0.3), Vector3(x1 + 0.12, top, z0 + 0.3)], 0.045, cyan)
	ArchKit.pipes(k, [Vector3(x1 + 0.12, 0.05, z0 + 0.55), Vector3(x1 + 0.12, top, z0 + 0.55)], 0.045, Color(1.0, 0.6, 0.35, 0.45))
