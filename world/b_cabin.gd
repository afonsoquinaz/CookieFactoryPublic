class_name CabinB
extends Building
## A staff cabin: houses workers. Resting workers sit on the bench in front.


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("cabin_%d" % t, func(): return CabinB.mesh(t)), root, MeshKit.at(0.3, 0, -0.65))


func solid_rects() -> Array[Rect2]:
	return [Rect2(-1.7, -2.0, 3.4, 2.6)]


## Where resting worker i sits (world space).
func seat(i: int) -> Vector3:
	var col := i % 4
	var row := (i / 4) % 2
	return to_world(-1.2 + col * 0.75, 0.75 + row * 0.85)


func info() -> Array:
	return [["hire", "Houses %d workers" % Bal.cabin_cap(level)], ["worker", "%d hired in total" % Game.workers.size()]]


func upgrade_info() -> Array:
	return [["Houses", str(Bal.cabin_cap(level)), str(Bal.cabin_cap(level + 1))]]


static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var sc := 1.0 + t * 0.05
	k.add_mesh(MeshKit.cached("cabin", CabinB.base_mesh), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(sc, sc, sc)))
	if t >= 2:
		# a side annex with its own roof
		var wall := Color(0.92, 0.89, 0.82) if t < 4 else Color(0.96, 0.93, 0.86)
		k.rbox(Vector3(1.1, 1.2, 1.6), 0.08, wall, MeshKit.at(-1.95, 0.7, -0.5))
		for sd in [-1.0, 1.0]:
			k.rbox(Vector3(0.75, 0.1, 1.8), 0.04, Pal.TERRACOTTA if t < 4 else Pal.CHOCO, MeshKit.xf(Vector3(-1.95 + sd * 0.33, 1.5, -0.5), Vector3(0, 0, -sd * 32)))
		k.rbox(Vector3(0.4, 0.4, 0.06), 0.06, Color(0.6, 0.85, 1.0, 0.75), MeshKit.at(-1.95, 0.9, 0.31))
	if t >= 3:
		# an upper floor with a balcony
		k.rbox(Vector3(1.8, 0.7, 1.5), 0.08, Color(0.9, 0.87, 0.8), MeshKit.at(-0.3, 2.35 * sc, -0.6))
		k.rbox(Vector3(2.0, 0.06, 0.5), 0.02, Pal.WOOD, MeshKit.at(-0.3, 2.05 * sc, 0.35))
		for i in 6:
			k.rbox(Vector3(0.04, 0.3, 0.04), 0.01, Pal.WOOD_DARK, MeshKit.at(-1.2 + i * 0.36, 2.2 * sc, 0.58))
	if t >= 1:
		k.cyl(0.03, 0.4, Pal.STEEL_DARK, MeshKit.at(0.55, 1.6, 0.58), 6)
		k.sphere(0.1, Color(1.0, 0.9, 0.6, 0.4), MeshKit.at(0.55, 1.55, 0.62), 8, 5)
	if t >= 2:
		# picket fence and a flower bed
		for i in 9:
			k.rbox(Vector3(0.06, 0.4, 0.04), 0.02, Pal.CREAM, MeshKit.at(-1.9, 0.2, -1.4 + i * 0.3))
		k.rbox(Vector3(0.05, 0.05, 2.5), 0.02, Pal.CREAM, MeshKit.at(-1.9, 0.3, -0.2))
	if t >= 3:
		k.rbox(Vector3(1.0, 0.06, 0.6), 0.02, Pal.STEEL_DARK, MeshKit.xf(Vector3(-0.9, 2.45, -0.5), Vector3(0, 0, 32)))
		k.rbox(Vector3(0.9, 0.04, 0.5), 0.01, Color(0.3, 0.4, 0.55), MeshKit.xf(Vector3(-0.9, 2.48, -0.5), Vector3(0, 0, 32)))
	if t >= 4:
		k.cyl(0.02, 0.5, Pal.GOLD, MeshKit.at(-0.3, 2.65, -0.5), 6)
		Items.cookie_into(k, "royal", 0.12, 0.03, MeshKit.xf(Vector3(-0.3, 3.2, -0.5), Vector3(90, 0, 0)))
	return k.commit()


static func base_mesh() -> Mesh:
	var k := MeshKit.new()
	var wall := Color(0.92, 0.89, 0.82)
	var beam := Pal.WOOD_DARK
	var roof := Pal.TERRACOTTA
	var roof2 := Pal.BRICK_DARK
	var cx := -0.3
	var cz := -0.5
	# stone footing + walls with corner beams
	k.rbox(Vector3(2.8, 0.25, 2.3), 0.08, Color(0.78, 0.76, 0.82), MeshKit.at(cx, 0.12, cz))
	k.rbox(Vector3(2.5, 1.5, 2.0), 0.1, wall, MeshKit.at(cx, 1.0, cz))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.16, 1.55, 0.16), 0.05, beam, MeshKit.at(cx + sx * 1.22, 1.0, cz + sz * 0.97))
	# gable ends
	for sz in [-1.0, 1.0]:
		k.prism(PackedVector2Array([Vector2(-1.25, 0), Vector2(0, 0.8), Vector2(1.25, 0)]), 0.1, wall,
			MeshKit.xf(Vector3(cx, 1.75, cz + sz * 0.95 - 0.05), Vector3(-90, 0, 0)))
	# roof: two slopes with tile rows and a ridge
	for sd in [-1.0, 1.0]:
		var rt := MeshKit.xf(Vector3(cx + sd * 0.68, 2.15, cz), Vector3(0, 0, -sd * 32))
		k.rbox(Vector3(1.62, 0.12, 2.5), 0.05, roof, rt)
		for r in 4:
			k.rbox(Vector3(0.12, 0.06, 2.52), 0.03, roof2, rt * MeshKit.at(-0.6 + r * 0.4, 0.07, 0))
	k.cyl(0.08, 2.56, Pal.BRICK_DARK, MeshKit.xf(Vector3(cx, 2.6, cz - 1.28), Vector3(90, 0, 0)), 10, 0.02)
	# chimney
	k.rbox(Vector3(0.3, 0.7, 0.3), 0.05, Color(0.8, 0.5, 0.42), MeshKit.at(cx + 0.6, 2.6, cz - 0.4))
	# door, windows with flower boxes (front = +z)
	k.rbox(Vector3(0.6, 1.0, 0.08), 0.12, beam, MeshKit.at(cx + 0.55, 0.75, cz + 1.02))
	k.sphere(0.05, Pal.GOLD, MeshKit.at(cx + 0.74, 0.75, cz + 1.07), 6, 4)
	k.rbox(Vector3(0.6, 0.5, 0.08), 0.1, Color(0.6, 0.85, 1.0, 0.75), MeshKit.at(cx - 0.55, 1.15, cz + 1.02))
	k.rbox(Vector3(0.7, 0.14, 0.18), 0.05, Pal.WOOD, MeshKit.at(cx - 0.55, 0.82, cz + 1.1))
	for i in 3:
		k.sphere(0.07, [Pal.LEAF, Color(0.58, 0.52, 0.7), Pal.LEAF][i], MeshKit.at(cx - 0.75 + i * 0.2, 0.93, cz + 1.12), 6, 4)
	# two benches out front
	for bz in [1.25, 2.15]:
		k.rbox(Vector3(3.2, 0.1, 0.45), 0.04, Pal.WOOD, MeshKit.at(-0.1, 0.32, bz))
		for sx in [-1.4, 1.2]:
			k.rbox(Vector3(0.1, 0.32, 0.4), 0.03, Pal.WOOD_DARK, MeshKit.at(sx, 0.16, bz))
	return k.commit()
