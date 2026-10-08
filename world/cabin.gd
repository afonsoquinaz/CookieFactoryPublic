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
	var wall := Color(0.98, 0.86, 0.62)
	var roof := Color(0.45, 0.62, 0.95)
	k.rbox(Vector3(2.6, 1.7, 2.3), 0.14, wall, MeshKit.at(-0.3, 0.95, -0.5))
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(1.75, 0.14, 2.7), 0.06, roof, MeshKit.xf(Vector3(-0.3 + sd * 0.7, 2.15, -0.5), Vector3(0, 0, -sd * 32)))
	k.rbox(Vector3(0.6, 1.0, 0.1), 0.12, Pal.WOOD_DARK, MeshKit.at(0.2, 0.6, 0.66))
	k.sphere(0.05, Pal.GOLD, MeshKit.at(0.4, 0.6, 0.73), 6, 4)
	k.rbox(Vector3(0.6, 0.5, 0.08), 0.12, Color(0.7, 0.9, 1.0, 0.7), MeshKit.at(-0.85, 1.15, 0.66))
	k.rbox(Vector3(0.12, 1.1, 0.12), 0.05, Pal.WOOD_DARK, MeshKit.at(0.5, 2.3, -1.0))
	k.cyl(0.14, 0.6, Color(0.85, 0.45, 0.35), MeshKit.at(0.5, 2.0, -1.0), 10, 0.04)
	# a long bench out front
	k.rbox(Vector3(3.2, 0.1, 0.45), 0.04, Pal.WOOD, MeshKit.at(-0.1, 0.32, 1.25))
	for sx in [-1.4, 1.2]:
		k.rbox(Vector3(0.1, 0.32, 0.4), 0.03, Pal.WOOD_DARK, MeshKit.at(sx, 0.16, 1.25))
	k.rbox(Vector3(3.2, 0.1, 0.45), 0.04, Pal.WOOD, MeshKit.at(-0.1, 0.32, 2.15))
	for sx in [-1.4, 1.2]:
		k.rbox(Vector3(0.1, 0.32, 0.4), 0.03, Pal.WOOD_DARK, MeshKit.at(sx, 0.16, 2.15))
	return k.commit()
