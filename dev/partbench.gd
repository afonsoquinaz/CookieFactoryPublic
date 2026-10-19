extends Node3D
## Growth part bench: parts in every tier (rows, garage at the back) and
## grade (columns), to check that grades evolve and tiers change style.
##   RES=1280x1280 FRAMES=40 tools/shot.sh res://dev/partbench.tscn out.png -- --part=cabinet,solar
##   --set=floor|top|wall (every part of that kind)   --tiers=0,2,4   --grades=0,3
##   --yaw=30 (turn the parts)   --pitch=50
## Triangle table (no window needed):
##   godot --headless --path . res://dev/partbench.tscn -- --stats [--set=floor]


func _ready() -> void:
	var a := Shot.args()
	var names: Array = []
	if a.has("part"):
		names = Array(str(a["part"]).split(","))
	else:
		names = {"floor": GrowthParts.FLOOR, "top": GrowthParts.TOP, "wall": GrowthParts.WALL, "all": GrowthParts.FLOOR + GrowthParts.TOP + GrowthParts.WALL}[str(a.get("set", "all"))]
	var tiers: Array = Array(str(a.get("tiers", "0,1,2,3,4")).split(",")).map(func(s): return int(s))
	var grades: Array = Array(str(a.get("grades", "0,1,2,3")).split(",")).map(func(s): return int(s))
	if a.has("stats"):
		_stats(names)
		get_tree().quit()
		return
	Env.build(self)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(400, 400)
	ground.mesh = pm
	ground.material_override = Mats.flat(Color(0.5, 0.6, 0.4))
	add_child(ground)
	var sp := Vector2(1.25, float(a.get("row", "2.0")))
	var yaw := float(a.get("yaw", "0"))
	var cols := names.size() * grades.size()
	for pi in names.size():
		var nm: String = names[pi]
		var wall := GrowthParts.WALL.has(nm)
		var top := GrowthParts.TOP.has(nm)
		for ti in tiers.size():
			for gi in grades.size():
				var k := MeshKit.new()
				var p := Vector3((pi * grades.size() + gi) * sp.x + pi * 0.4, 0, ti * sp.y)
				if wall:
					k.box(Vector3(1.15, 1.2, 0.1), Color(0.86, 0.85, 0.82), MeshKit.at(0, 0.75, -0.05))
					GrowthParts.draw(k, nm, grades[gi], tiers[ti], MeshKit.xf(Vector3(0, 0.85, 0), Vector3(0, yaw, 0)), Growth.colour("src_power") if pi % 2 else Color(0.3, 0.66, 0.68))
				elif top:
					k.box(Vector3(1.0, 0.3, 0.8), Color(0.62, 0.62, 0.6), MeshKit.at(0, 0.15, 0))
					GrowthParts.draw(k, nm, grades[gi], tiers[ti], MeshKit.xf(Vector3(0, 0.3, 0), Vector3(0, yaw, 0)))
				else:
					k.box(Vector3(0.75, 0.01, 0.75), Color(0.46, 0.55, 0.37), MeshKit.at(0, 0.005, 0))
					GrowthParts.draw(k, nm, grades[gi], tiers[ti], MeshKit.xf(Vector3.ZERO, Vector3(0, yaw, 0)), Growth.colour("src_silicon") if pi % 2 else Growth.colour("src_power"))
				Mats.inst(k.commit(), self).position = p
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var w := cols * sp.x + names.size() * 0.4
	var h := tiers.size() * sp.y
	var vs := get_viewport().get_visible_rect().size
	var pitch := deg_to_rad(float(a.get("pitch", "55")))
	cam.size = maxf(w * vs.y / vs.x, h * sin(pitch) + 1.6) * 1.02
	var c := Vector3(w * 0.5 - sp.x * 0.5 - 0.2, 0.6, (h - sp.y) * 0.5)
	add_child(cam)
	cam.position = c + Vector3(0, sin(pitch), cos(pitch)) * 40.0
	cam.look_at(c)
	cam.far = 200
	cam.current = true
	Shot.attach(self)


## Triangles per part, tier and grade; parts that leave their footprint
## (floor 0.75 x 0.75 m, top 0.7 x 0.5 m, wall 0.25 m out) are listed after.
func _stats(names: Array) -> void:
	var worst := 0
	var out := []
	for nm in names:
		var line := "%-9s" % nm
		for t in 5:
			line += "  t%d" % t
			for g in 4:
				var k := MeshKit.new()
				GrowthParts.draw(k, nm, g, t, Transform3D.IDENTITY, Color(0.3, 0.66, 0.68))
				var m := k.commit()
				var tris := 0
				if m.get_surface_count() > 0:
					tris = m.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3
					var bb := m.get_aabb()
					var lim := Vector3(0.4, 9.0, 0.4)
					if GrowthParts.TOP.has(nm):
						lim = Vector3(0.38, 9.0, 0.28)
					elif GrowthParts.WALL.has(nm):
						lim = Vector3(0.52, 9.0, 9.0)
					var far := Vector3(maxf(-bb.position.x, bb.end.x), bb.end.y, maxf(-bb.position.z, bb.end.z))
					if far.x > lim.x or far.z > lim.z or (GrowthParts.WALL.has(nm) and (bb.end.z > 0.26 or bb.position.z < -0.01)):
						out.append("%s g%d t%d: x %.2f..%.2f z %.2f..%.2f h %.2f" % [nm, g, t, bb.position.x, bb.end.x, bb.position.z, bb.end.z, bb.end.y])
				worst = maxi(worst, tris)
				line += " %4d" % tris
		print(line)
	print("worst %d" % worst)
	for o in out:
		print("  out of bounds: ", o)
