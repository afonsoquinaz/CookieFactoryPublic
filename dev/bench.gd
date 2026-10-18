extends Node3D
## Art bench: buildings in rows, their five tiers left to right.
##   tools/shot.sh res://dev/bench.tscn out.png -- --kinds=server,fab --spacing=9
##   --tiers=0,4   only these tiers      --pitch=40  camera pitch (degrees)


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
		var lv: PackedStringArray = str(a.get("levels", "")).split(",", false)
		var tiers: Array = Array(str(a.get("tiers", "0,1,2,3,4")).split(",")).map(func(x): return int(x))
		for ti in tiers.size():
			var t: int = tiers[ti]
			var tier := t
			var mi: MeshInstance3D
			if lv.size() == 5:
				# --levels=2,4,12,30,50: that level's look plus its props
				var l := int(lv[t])
				tier = Bal.tier(parts[0], l)
				var an := LevelArt.anchors_for(parts[0])
				var pk := MeshKit.new()
				pk.add_mesh(Previews.mesh(parts[0], "", tier))
				pk.add_mesh(LevelArt.props(an, LevelArt.count(an.size(), l, Bal.max_level(parts[0])), tier))
				mi = Mats.inst(pk.commit(), self)
			else:
				mi = Mats.inst(Previews.mesh(parts[0], parts[1] if parts.size() > 1 else "", t), self)
			mi.position = Vector3(ti * sp, 0, row * sp)
		row += 1
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var w: float = str(a.get("tiers", "0,1,2,3,4")).split(",").size() * sp
	var h := kinds.size() * sp
	var vs := get_viewport().get_visible_rect().size
	cam.size = maxf(w * vs.y / vs.x, h * 0.85) * 1.05
	var c := Vector3(w * 0.5 - sp * 0.5, 1.0, (h - sp) * 0.5)
	add_child(cam)
	var pitch := deg_to_rad(float(a.get("pitch", "51")))
	cam.position = c + Vector3(0, sin(pitch), cos(pitch)) * 38.0
	cam.look_at(c)
	cam.far = 200
	cam.current = true
	Shot.attach(self)
