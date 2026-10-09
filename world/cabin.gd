class_name Cabin
extends Node3D
## The staff cabin: a cosy hut with a bench where unassigned workers wait.

func _ready() -> void:
	position = Lay.CABIN_POS
	Mats.inst(MeshKit.cached("cabin", Cabin.mesh), self)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.6, 2.4, 2.4)
	cs.shape = sh
	cs.position = Vector3(-0.3, 1.2, -0.5)
	body.add_child(cs)
	add_child(body)
	var ic := UI3D.icon("worker", 0.003)
	ic.position = Vector3(-0.3, 3.6, 0)
	add_child(ic)


## Where idle worker i sits.
func seat(i: int) -> Vector3:
	var row := i / 4
	var col := i % 4
	return global_position + Vector3(-1.2 + col * 0.75, 0, 1.4 + row * 0.9)


static func mesh() -> Mesh:
	var k := MeshKit.new()
	var wall := Color(1.0, 0.92, 0.76)
	var beam := Pal.WOOD_DARK
	var roof := Color(0.95, 0.42, 0.38)
	var roof2 := Color(0.86, 0.34, 0.32)
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
	k.cyl(0.1, 2.56, Color(1.0, 0.85, 0.4), MeshKit.xf(Vector3(cx, 2.6, cz - 1.28), Vector3(90, 0, 0)), 10, 0.04)
	# chimney
	k.rbox(Vector3(0.3, 0.7, 0.3), 0.05, Color(0.8, 0.5, 0.42), MeshKit.at(cx + 0.6, 2.6, cz - 0.4))
	# door, windows with flower boxes (front = +z)
	k.rbox(Vector3(0.6, 1.0, 0.08), 0.12, beam, MeshKit.at(cx + 0.55, 0.75, cz + 1.02))
	k.sphere(0.05, Pal.GOLD, MeshKit.at(cx + 0.74, 0.75, cz + 1.07), 6, 4)
	k.rbox(Vector3(0.6, 0.5, 0.08), 0.1, Color(0.6, 0.85, 1.0, 0.75), MeshKit.at(cx - 0.55, 1.15, cz + 1.02))
	k.rbox(Vector3(0.7, 0.14, 0.18), 0.05, Pal.WOOD, MeshKit.at(cx - 0.55, 0.82, cz + 1.1))
	for i in 3:
		k.sphere(0.07, [Pal.PINK, Pal.YELLOW, Pal.PINK][i], MeshKit.at(cx - 0.75 + i * 0.2, 0.93, cz + 1.12), 6, 4)
	# two benches out front
	for bz in [1.25, 2.15]:
		k.rbox(Vector3(3.2, 0.1, 0.45), 0.04, Pal.WOOD, MeshKit.at(-0.1, 0.32, bz))
		for sx in [-1.4, 1.2]:
			k.rbox(Vector3(0.1, 0.32, 0.4), 0.03, Pal.WOOD_DARK, MeshKit.at(sx, 0.16, bz))
	return k.commit()
