extends Node3D
## Growth bench: one building at many levels, to check that every upgrade
## shows (the tier look plus everything Growth adds).
##   RES=1280x1280 tools/shot.sh res://dev/growth.tscn out.png -- --kind=server --levels=1,2,3,5,8,12
##   --cols=3   --pitch=50   --kinds=a,b (one row each, same levels)


func _ready() -> void:
	var a := Shot.args()
	Env.build(self)
	if a.has("parts"):
		_parts(a)
		return
	var kinds: Array = Array(str(a.get("kinds", a.get("kind", "server"))).split(","))
	var lv: Array = Array(str(a.get("levels", "1,2,3,4,5,6,8,10,12")).split(",")).map(func(x): return int(x))
	var cols := int(a.get("cols", str(lv.size() if kinds.size() > 1 else 3)))
	var sz := Vector2.ZERO
	for k in kinds:
		var s: Vector2i = Defs.BUILDINGS[k]["size"]
		sz = sz.max(Vector2(s) * Grid.CELL)
	var sp := sz + Vector2(1.6, 4.5)
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(600, 600)
	ground.mesh = pm
	ground.material_override = Mats.flat(Color(0.5, 0.6, 0.4))
	add_child(ground)
	var n := 0
	var rows := 0
	for k in kinds:
		for i in lv.size():
			var l: int = mini(lv[i], Bal.max_level(k))
			var t := Bal.tier(k, l)
			var col := n % cols
			var row := n / cols
			rows = row + 1
			var p := Vector3(col * sp.x, 0, row * sp.y)
			var pad := Mats.inst(MeshKit.cached("bench_pad", func():
				var mk := MeshKit.new()
				mk.rbox(Vector3(1, 0.02, 1), 0.0, Color(0.56, 0.64, 0.46), MeshKit.at(0, 0.0, 0))
				return mk.commit()), self)
			pad.position = p
			pad.scale = Vector3(sz.x + 0.6, 1, sz.y + 0.6)
			Mats.inst(Previews.mesh(k, "", t, l), self).position = p
			Mats.inst(Growth.mesh(k, l, t), self).position = p
			var lab := Label3D.new()
			lab.text = "%s  L%d" % [Defs.BUILDINGS[k]["name"], l] if kinds.size() > 1 else "L%d" % l
			lab.font_size = 96
			lab.pixel_size = 0.01
			lab.outline_size = 18
			lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			lab.position = p + Vector3(-sz.x * 0.5 + 0.6, 0.3, sz.y * 0.5 + 0.7)
			add_child(lab)
			n += 1
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var w := cols * sp.x
	var h := rows * sp.y
	var vs := get_viewport().get_visible_rect().size
	var pitch := deg_to_rad(float(a.get("pitch", "50")))
	cam.size = maxf(w * vs.y / vs.x, h * sin(pitch) + 4.0) * 1.02
	var c := Vector3(w * 0.5 - sp.x * 0.5, 1.0, (h - sp.y) * 0.5)
	add_child(cam)
	cam.position = c + Vector3(0, sin(pitch), cos(pitch)) * 60.0
	cam.look_at(c)
	cam.far = 300
	cam.current = true
	Shot.attach(self)


## --parts=floor|top|wall [--tier=2]: every part in its four grades.
func _parts(a: Dictionary) -> void:
	var names: Array = {"floor": GrowthParts.FLOOR, "top": GrowthParts.TOP, "wall": GrowthParts.WALL}[str(a["parts"])]
	var t := int(a.get("tier", "2"))
	var ground := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(200, 200)
	ground.mesh = pm
	ground.material_override = Mats.flat(Color(0.5, 0.6, 0.4))
	add_child(ground)
	var cols := 8
	var sp := Vector2(1.6, 1.8)
	var n := 0
	for nm in names:
		for g in 4:
			var col := n % cols
			var row := n / cols
			var k := MeshKit.new()
			if str(a["parts"]) == "wall":
				k.rbox(Vector3(1.3, 1.1, 0.1), 0.0, Color(0.9, 0.9, 0.88), MeshKit.at(0, 0.8, -0.05))
				GrowthParts.draw(k, nm, g, t, MeshKit.at(0, 0.95, 0))
			else:
				GrowthParts.draw(k, nm, g, t, Transform3D.IDENTITY)
			Mats.inst(k.commit(), self).position = Vector3(col * sp.x, 0, row * sp.y)
			n += 1
	var rows := (n + cols - 1) / cols
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var w := cols * sp.x
	var h := rows * sp.y
	var vs := get_viewport().get_visible_rect().size
	cam.size = maxf(w * vs.y / vs.x, h * 0.8 + 2.0)
	var c := Vector3(w * 0.5 - sp.x * 0.5, 0.5, (h - sp.y) * 0.5)
	add_child(cam)
	cam.position = c + Vector3(0, sin(0.7), cos(0.7)) * 40.0
	cam.look_at(c)
	cam.far = 200
	cam.current = true
	Shot.attach(self)
