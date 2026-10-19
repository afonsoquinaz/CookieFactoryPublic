extends Node3D
## ArchKit pieces in all five tiers (rows), to check the kit.
##   RES=1600x1200 tools/shot.sh res://dev/kitbench.tscn out.png


func _ready() -> void:
	Env.build(self)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = Mats.flat(Color(0.5, 0.6, 0.4))
	add_child(ground)
	for t in 5:
		var k := MeshKit.new()
		ArchKit.lot(k, 34.0, 5.0, t)
		var top := ArchKit.block(k, Vector3(-14, 0.1, 0), Vector3(4, 2.6 + t * 0.6, 3), t, "fl", 1 + t / 2)
		ArchKit.roof_kit(k, Rect2(-15.8, -1.3, 3.6, 2.6), top + 0.03, t, t)
		ArchKit.door(k, MeshKit.at(-13, 0.1, 1.5), t)
		ArchKit.rollup(k, MeshKit.at(-10, 0.1, 0.5), 1.6, 1.8, ArchKit.c(t, "wall2"), 0.3)
		ArchKit.ac_unit(k, MeshKit.at(-8, 0.1, 0), t)
		ArchKit.chiller(k, MeshKit.at(-5.5, 0.1, 0), 2.6, t)
		ArchKit.cooling_tower(k, MeshKit.at(-2.5, 0.1, 0), 0.9, 2.4, t)
		ArchKit.tank(k, MeshKit.at(-0.6, 0.1, 0), 0.45, 1.6, Color(0.9, 0.9, 0.88), t)
		ArchKit.generator(k, MeshKit.at(1.8, 0.1, 0), t)
		ArchKit.transformer(k, MeshKit.at(4.2, 0.1, 0), t)
		ArchKit.solar(k, MeshKit.at(6.6, 0.1, 0), 2, t)
		ArchKit.fence(k, Vector3(8.2, 0.1, -1.5), Vector3(8.2, 0.1, 1.5), t)
		ArchKit.stairs(k, MeshKit.at(9.4, 0.1, 1.2), 0.8, 1.6, t)
		ArchKit.catwalk(k, Vector3(10.6, 1.6, -1.5), Vector3(10.6, 1.6, 1.5), 0.7, t)
		ArchKit.vehicle(k, MeshKit.at(12.2, 0.1, 0), t)
		ArchKit.planter(k, Vector3(13.6, 0.1, 0), t, 0.8, t % 2 == 0)
		ArchKit.lamp(k, Vector3(14.6, 0.1, 0), t)
		ArchKit.pipe_rack(k, MeshKit.at(16, 0.1, 0), 2.0, 1.4, t)
		ArchKit.sign(k, MeshKit.at(-14, top, 1.6), 2.0, 0.5, t)
		if t == 0:
			ArchKit.clutter(k, Vector3(-11, 0.1, -1.6), t, 1)
			ArchKit.string_lights(k, Vector3(-16, 2.4, 2.2), Vector3(-11, 2.4, 2.2))
		if t >= 3:
			ArchKit.fins(k, MeshKit.at(-14, 0.1, 1.55), 3.6, 2.0, 6, t)
		var mi := Mats.inst(k.commit(), self)
		mi.position = Vector3(0, 0, t * 7.0)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = 30
	add_child(cam)
	var c := Vector3(0, 1, 14)
	cam.position = c + Vector3(0, sin(deg_to_rad(48)), cos(deg_to_rad(48))) * 40.0
	cam.look_at(c)
	cam.far = 200
	cam.current = true
	Shot.attach(self)
