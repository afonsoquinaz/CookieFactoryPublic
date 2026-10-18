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


static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var sc := 1.0 + t * 0.05
	k.add_mesh(MeshKit.cached("dorm", DormB.base_mesh), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(sc, sc, sc)))
	var lit := Color(1.0, 0.9, 0.6, 0.4)
	if t >= 1:
		k.cyl(0.03, 0.4, Pal.STEEL_DARK, MeshKit.at(0.55, 1.6, 0.58), 6)
		k.sphere(0.1, lit, MeshKit.at(0.55, 1.55, 0.62), 8, 5)
	if t >= 2:
		# a side module with its own window
		k.rbox(Vector3(1.1, 1.3, 1.6), 0.08, Color(0.94, 0.95, 0.96), MeshKit.at(-1.95, 0.75, -0.5))
		k.rbox(Vector3(1.14, 0.08, 1.64), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(-1.95, 1.42, -0.5))
		k.rbox(Vector3(0.5, 0.4, 0.06), 0.06, Color(0.6, 0.85, 1.0, 0.75), MeshKit.at(-1.95, 0.9, 0.31))
		for i in 9:
			k.rbox(Vector3(0.06, 0.4, 0.04), 0.02, Pal.WOOD_LIGHT, MeshKit.at(-2.65, 0.2, -1.4 + i * 0.3))
	if t >= 3:
		# a stacked upper module with a balcony
		k.rbox(Vector3(1.9, 0.8, 1.5), 0.08, Pal.WOOD_LIGHT, MeshKit.at(-0.3, 2.3 * sc, -0.6))
		k.rbox(Vector3(1.2, 0.4, 0.04), 0.04, Color(0.6, 0.85, 1.0, 0.75), MeshKit.at(-0.3, 2.35 * sc, 0.16))
		k.rbox(Vector3(2.0, 0.06, 0.5), 0.02, Pal.STEEL_DARK, MeshKit.at(-0.3, 1.95 * sc, 0.35))
		k.rbox(Vector3(2.0, 0.3, 0.02), 0.01, Color(0.7, 0.86, 0.92, 0.8), MeshKit.at(-0.3, 2.12 * sc, 0.6))
	if t >= 4:
		k.torus(0.3, 0.04, Color(0.5, 0.95, 0.95, 0.4), MeshKit.at(-0.3, 3.1 * sc, -0.6), 16, 4)
		k.cyl(0.03, 0.35, Pal.BRASS, MeshKit.at(-0.3, 2.7 * sc, -0.6), 6)
	return k.commit()


static func base_mesh() -> Mesh:
	var k := MeshKit.new()
	var wall := Color(0.95, 0.95, 0.94)
	var wood := Pal.WOOD_LIGHT
	var cx := -0.3
	var cz := -0.5
	# a concrete pad, a white module with wood cladding on one end
	k.rbox(Vector3(2.8, 0.25, 2.3), 0.08, Color(0.72, 0.72, 0.72), MeshKit.at(cx, 0.12, cz))
	k.rbox(Vector3(2.5, 1.6, 2.0), 0.1, wall, MeshKit.at(cx, 1.05, cz))
	k.rbox(Vector3(0.9, 1.6, 2.02), 0.08, wood, MeshKit.at(cx + 0.82, 1.05, cz))
	for i in 7:
		k.rbox(Vector3(0.9, 0.02, 2.04), 0.005, wood.darkened(0.15), MeshKit.at(cx + 0.82, 0.4 + i * 0.22, cz))
	# a flat roof with solar panels
	k.rbox(Vector3(2.7, 0.14, 2.2), 0.04, Color(0.4, 0.42, 0.46), MeshKit.at(cx, 1.92, cz))
	for i in 3:
		k.rbox(Vector3(0.7, 0.04, 1.6), 0.01, Color(0.18, 0.26, 0.44), MeshKit.xf(Vector3(cx - 0.8 + i * 0.8, 2.05, cz), Vector3(-12, 0, 0)))
	# door and a big window (front = +z)
	k.rbox(Vector3(0.6, 1.1, 0.08), 0.06, Color(0.24, 0.25, 0.28), MeshKit.at(cx + 0.55, 0.8, cz + 1.02))
	k.rbox(Vector3(0.05, 0.3, 0.04), 0.01, Pal.BRASS, MeshKit.at(cx + 0.74, 0.8, cz + 1.07))
	k.rbox(Vector3(0.9, 0.6, 0.08), 0.06, Color(0.6, 0.85, 1.0, 0.75), MeshKit.at(cx - 0.5, 1.15, cz + 1.02))
	k.rbox(Vector3(0.96, 0.06, 0.12), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(cx - 0.5, 0.82, cz + 1.06))
	# two benches out front
	for bz in [1.25, 2.15]:
		k.rbox(Vector3(3.2, 0.1, 0.45), 0.04, Pal.WOOD, MeshKit.at(-0.1, 0.32, bz))
		for sx in [-1.4, 1.2]:
			k.rbox(Vector3(0.1, 0.32, 0.4), 0.03, Pal.STEEL_DARK, MeshKit.at(sx, 0.16, bz))
	return k.commit()
