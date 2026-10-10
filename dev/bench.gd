extends Node3D
## Art bench: buildings in rows, their five tiers left to right.
##   tools/shot.sh res://dev/bench.tscn out.png -- --kinds=oven,mixer --spacing=9


func _ready() -> void:
	var a := Shot.args()
	Env.build(self)
	var kinds: PackedStringArray = str(a.get("kinds", "oven")).split(",")
	var sp := float(a.get("spacing", "8"))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = Mats.flat(Color(0.5, 0.6, 0.4))
	add_child(ground)
	var row := 0
	for k in kinds:
		var parts := k.split(":")
		for t in 5:
			var mi := Mats.inst(Previews.mesh(parts[0], parts[1] if parts.size() > 1 else "", t), self)
			mi.position = Vector3(t * sp, 0, row * sp)
		row += 1
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var w := 5 * sp
	var h := kinds.size() * sp
	var vs := get_viewport().get_visible_rect().size
	cam.size = maxf(w * vs.y / vs.x, h * 0.85) * 1.05
	var c := Vector3(w * 0.5 - sp * 0.5, 1.0, (h - sp) * 0.5)
	add_child(cam)
	cam.position = c + Vector3(0, 30, 24)
	cam.look_at(c)
	cam.far = 200
	cam.current = true
	Shot.attach(self)
