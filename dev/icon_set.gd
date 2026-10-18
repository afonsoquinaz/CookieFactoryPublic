class_name IconSet
## What every UI icon shows (dev/icons.gd renders them). Most icons are the
## game's own models: resources, tokens, buildings, people. UI symbols (coin,
## spark, lock, gear, arrows...) get small models of their own here.
## A node can carry "yaw" / "pitch" metas to change the camera angle.

const UI := ["coin", "cash", "gem", "star", "trophy", "lock", "gear", "clock", "boost", "speed", "price",
	"recipe", "research", "hammer", "land", "move", "rotate", "storage", "bay", "deliver", "hire", "worker",
	"builder", "token", "batch", "agent", "courier", "tech", "engineer", "brand"]


static func names() -> Array[String]:
	var out: Array[String] = []
	for t in Defs.ITEMS:
		out.append(t)
	for r in Defs.RECIPES:
		out.append("tk_" + r["id"])
	for k in Defs.BUILDINGS:
		var ic: String = Defs.BUILDINGS[k]["icon"]
		if not out.has(ic):
			out.append(ic)
	for n in UI:
		if not out.has(n):
			out.append(n)
	return out


static func _mi(mesh: Mesh, parent: Node3D, t := Transform3D.IDENTITY) -> MeshInstance3D:
	return Mats.inst(mesh, parent, t)


static func build(name: String) -> Node3D:
	var root := Node3D.new()
	if Defs.ITEMS.has(name):
		_mi(Items.mesh(name), root)
		root.set_meta("pitch", 34.0)
		return root
	if name.begins_with("tk_"):
		_token(root, name.substr(3))
		return root
	if Defs.BUILDINGS.has(name):
		_building(root, name)
		return root
	_ui(root, name)
	return root


## A token standing up a little so its face reads, with a second one behind.
static func _token(root: Node3D, id: String) -> void:
	var k := MeshKit.new()
	Items.token_into(k, id, 0.19, Defs.TOKEN_H)
	var m := k.commit()
	_mi(m, root, MeshKit.xf(Vector3(0, 0.2, 0), Vector3(62, 0, 0)))
	root.set_meta("yaw", -18.0)
	root.set_meta("pitch", 18.0)


static func _building(root: Node3D, kind: String) -> void:
	var d: Dictionary = Defs.BUILDINGS[kind]
	match d["cat"]:
		"source":
			# three stations with what they make, on a little pad
			var res: String = d["res"]
			var k := MeshKit.new()
			k.rbox(Vector3(2.9, 0.12, 1.4), 0.05, Color(0.62, 0.6, 0.56).lerp(Defs.ITEMS[res]["color"], 0.15), MeshKit.at(0, 0.0, 0))
			for i in 3:
				var p := Vector3(-0.95 + i * 0.95, 0.06, -0.1 + (i % 2) * 0.2)
				k.add_mesh(Stations.station(res), MeshKit.xf(p, Vector3.ZERO, Vector3.ONE * 1.1))
				var sp := Stations.spinner_at(res)
				if sp != Vector3.INF:
					k.add_mesh(Stations.spinner(res), MeshKit.xf(p + sp * 1.1, Vector3.ZERO, Vector3.ONE * 1.1))
				var pp := Stations.product_at(res) * 1.1
				k.add_mesh(Items.mesh(res), MeshKit.xf(p + pp, Vector3.ZERO, Vector3.ONE * Stations.product_scale(res) * 1.1))
			_mi(k.commit(), root)
			root.set_meta("pitch", 34.0)
		"server":
			_mi(Previews.mesh("server", "data", 2), root)
			root.set_meta("pitch", 40.0)
			root.set_meta("yaw", -20.0)
		"lab":
			_mi(LabArt.machine(kind, 2), root)
			_mi(LabArt.part(kind, 2), root, Transform3D(Basis.IDENTITY, LabArt.anim_pivot(kind, 2)))
		"pack":
			if kind == "depot" or kind == "cache":
				_mi(StorageB.mesh(kind, 2), root)
			else:
				_mi(LabArt.machine(kind, 2), root)
				_mi(LabArt.part(kind, 2), root, Transform3D(Basis.IDENTITY, LabArt.anim_pivot(kind, 2) + Vector3(0.4, 0, 0)))
		"sell":
			match kind:
				"van": _mi(SalesArt.van(1), root, MeshKit.xf(Vector3.ZERO, Vector3(0, -90, 0)))
				"hyperloop": _mi(SalesArt.train(2), root, MeshKit.xf(Vector3.ZERO, Vector3(0, 90, 0)))
				"droneport":
					_mi(SalesArt.airship(1), root)
					root.set_meta("pitch", 22.0)
				"cafe": _mi(CafeB.mesh(2), root)
				"desk": _mi(DeskB.mesh(), root)
		"staff":
			if kind == "hut":
				_ui(root, "builder")
			else:
				_mi(DormB.mesh(2), root)
		"wonder":
			_mi(MegaB.mesh(4), root)
			root.set_meta("pitch", 24.0)
		"decor":
			_mi(DecorB.mesh(kind), root)
			match kind:
				"turbine":
					var k2 := MeshKit.new()
					for i in 3:
						var b := Basis(Vector3.BACK, i * TAU / 3.0 + 0.3)
						k2.rbox(Vector3(0.16, 1.7, 0.05), 0.04, Color(0.96, 0.97, 0.98), Transform3D(b, b * Vector3(0.04, 0.9, 0.0)))
					k2.sphere(0.14, Color(0.9, 0.92, 0.94), MeshKit.at(0, 0, 0.04), 10, 6)
					_mi(k2.commit(), root, MeshKit.at(0, 3.6, 0.32))
					root.set_meta("yaw", -12.0)
				"robot":
					var k3 := MeshKit.new()
					k3.rbox(Vector3(0.42, 0.32, 0.36), 0.1, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.16, 0))
					k3.rbox(Vector3(0.32, 0.16, 0.02), 0.06, Color(0.14, 0.15, 0.18), MeshKit.at(0, 0.17, 0.18))
					for sx in [-0.07, 0.07]:
						k3.rbox(Vector3(0.05, 0.06, 0.01), 0.02, Color(0.5, 0.95, 1.0, 0.4), MeshKit.at(sx, 0.18, 0.192))
					k3.cyl(0.015, 0.12, Pal.STEEL_DARK, MeshKit.at(0, 0.32, 0), 5)
					k3.sphere(0.04, Color(1.0, 0.5, 0.4, 0.45), MeshKit.at(0, 0.46, 0), 6, 4)
					_mi(k3.commit(), root, MeshKit.at(0, 1.22, 0))
					root.set_meta("yaw", -18.0)


static func _person(root: Node3D, look: String) -> void:
	var ch := Character.new()
	root.add_child(ch)
	ch.setup(look, 11)
	ch.rotation.y = deg_to_rad(10.0)
	root.set_meta("pitch", 12.0)
	root.set_meta("yaw", -22.0)


static func _ui(root: Node3D, name: String) -> void:
	var k := MeshKit.new()
	var lit := func(c: Color, a := 0.45) -> Color: return Color(c.r, c.g, c.b, a)
	var teal := Color(0.24, 0.66, 0.7)
	match name:
		"courier": _person(root, "courier"); return
		"tech": _person(root, "tech"); return
		"engineer": _person(root, "engineer"); return
		"worker":
			_person(root, "courier"); return
		"brand":
			# the Token Empire mark: a teal hex token with a glowing core, face on
			var tf := MeshKit.xf(Vector3(0, 0.5, 0), Vector3(90, 30, 0))
			k.cyl(0.6, 0.16, [Color(0.1, 0.36, 0.42), Color(0.2, 0.62, 0.68)], tf, 6, 0.05)
			k.cyl(0.46, 0.17, Color(0.12, 0.2, 0.28), tf, 6, 0.03)
			k.torus(0.44, 0.03, Color(0.5, 0.95, 1.0, 0.4), tf * MeshKit.at(0, 0.17, 0), 6, 4)
			k.cyl(0.22, 0.2, Color(0.55, 0.96, 1.0, 0.35), tf, 6, 0.04)
			k.sphere(0.1, Color(1, 1, 1, 0.3), tf * MeshKit.at(0, 0.24, 0), 10, 6)
			for i in 6:
				var a := TAU * i / 6.0
				k.sphere(0.035, Color(1.0, 0.86, 0.5, 0.4), tf * MeshKit.at(cos(a) * 0.34, 0.18, sin(a) * 0.34), 6, 4)
			root.set_meta("yaw", 0.0)
			root.set_meta("pitch", 0.0)
		"token":
			Items.token_into(k, "chat13", 0.19, Defs.TOKEN_H, MeshKit.xf(Vector3(0, 0.2, 0), Vector3(62, 0, 0)))
			root.set_meta("yaw", -18.0)
			root.set_meta("pitch", 18.0)
		"batch":
			k.add_mesh(Items.mesh("b:chat7"))
			root.set_meta("pitch", 30.0)
		"agent":
			k.add_mesh(Items.mesh("a:chat7"))
			root.set_meta("pitch", 18.0)
		"coin":
			var gold := Color(0.92, 0.74, 0.32)
			k.cyl(0.5, 0.14, [gold.darkened(0.15), gold], MeshKit.xf(Vector3(0, 0.5, -0.07), Vector3(80, 0, 0)), 28, 0.05)
			k.cyl(0.36, 0.16, gold.lightened(0.12), MeshKit.xf(Vector3(0, 0.5, -0.075), Vector3(80, 0, 0)), 6, 0.03)
			k.cyl(0.24, 0.17, lit.call(Color(1.0, 0.94, 0.6), 0.6), MeshKit.xf(Vector3(0, 0.5, -0.08), Vector3(80, 0, 0)), 6)
			root.set_meta("yaw", -15.0)
			root.set_meta("pitch", 12.0)
		"cash":
			for i in 4:
				k.rbox(Vector3(1.2, 0.08, 0.6), 0.03, Color(0.5, 0.72, 0.56).darkened(0.04 * (i % 2)), MeshKit.xf(Vector3(0, 0.04 + i * 0.085, 0), Vector3(0, i * 4 - 6, 0)))
			k.rbox(Vector3(0.22, 0.38, 0.64), 0.02, Color(0.96, 0.94, 0.88), MeshKit.at(0, 0.18, 0))
			k.cyl(0.12, 0.05, Color(0.92, 0.74, 0.32), MeshKit.at(0.32, 0.36, 0.0), 14)
		"gem":
			# a spark: a faceted glowing crystal
			var c := Color(0.42, 0.88, 0.98)
			k.cone(0.5, 0.36, lit.call(c.lightened(0.15), 0.62), MeshKit.at(0, 0.62, 0), 8)
			k.cone(0.5, 0.62, lit.call(c, 0.62), MeshKit.xf(Vector3(0, 0.62, 0), Vector3(180, 22.5, 0)), 8)
			k.cyl(0.5, 0.02, lit.call(c.lightened(0.4), 0.4), MeshKit.at(0, 0.61, 0), 8)
			root.set_meta("pitch", 16.0)
		"star":
			k.star(0.5, 0.24, 8, 0.12, Color(0.86, 0.68, 0.36), MeshKit.xf(Vector3(0, 0.5, -0.06), Vector3(90, 0, 0)))
			k.cyl(0.16, 0.16, Color(0.95, 0.82, 0.5), MeshKit.xf(Vector3(0, 0.5, -0.08), Vector3(90, 0, 0)), 14)
			root.set_meta("yaw", -15.0)
			root.set_meta("pitch", 10.0)
		"trophy":
			var b := Color(0.86, 0.68, 0.36)
			k.rbox(Vector3(0.6, 0.18, 0.6), 0.04, Color(0.24, 0.25, 0.28), MeshKit.at(0, 0.09, 0))
			k.cyl(0.07, 0.3, b, MeshKit.at(0, 0.18, 0), 10)
			k.lathe(PackedVector2Array([Vector2(0, 0.48), Vector2(0.12, 0.48), Vector2(0.3, 0.62), Vector2(0.38, 0.9), Vector2(0.4, 1.05), Vector2(0.36, 1.05), Vector2(0, 0.9)]), b, Transform3D.IDENTITY, 20)
			for sx in [-1.0, 1.0]:
				k.torus(0.13, 0.03, b, MeshKit.xf(Vector3(sx * 0.42, 0.82, 0), Vector3(90, 0, 0)), 12, 5)
		"lock":
			k.rbox(Vector3(0.7, 0.56, 0.3), 0.08, Color(0.78, 0.8, 0.84), MeshKit.at(0, 0.28, 0))
			k.torus(0.22, 0.06, Color(0.62, 0.64, 0.68), MeshKit.xf(Vector3(0, 0.6, 0), Vector3(90, 0, 0)), 18, 6, PI)
			for sx in [-1.0, 1.0]:
				k.cyl(0.06, 0.12, Color(0.62, 0.64, 0.68), MeshKit.at(sx * 0.22, 0.5, 0), 8)
			k.cyl(0.06, 0.04, Color(0.2, 0.22, 0.26), MeshKit.xf(Vector3(0, 0.3, 0.15), Vector3(90, 0, 0)), 10)
			root.set_meta("pitch", 14.0)
		"gear":
			var poly := PackedVector2Array()
			for i in 48:
				var a := TAU * i / 48.0
				var r := 0.5 if (i / 3) % 2 == 0 else 0.4
				poly.append(Vector2(cos(a) * r, sin(a) * r))
			k.prism(poly, 0.16, Color(0.66, 0.7, 0.76), MeshKit.xf(Vector3(0, 0.5, -0.08), Vector3(90, 0, 0)))
			k.cyl(0.16, 0.18, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(0, 0.5, -0.09), Vector3(90, 0, 0)), 14)
			root.set_meta("yaw", -18.0)
			root.set_meta("pitch", 14.0)
		"clock":
			var al := Color(0.8, 0.82, 0.86)
			k.cyl(0.45, 0.16, al, MeshKit.xf(Vector3(0, 0.5, -0.08), Vector3(90, 0, 0)), 24, 0.05)
			k.cyl(0.38, 0.17, Color(0.97, 0.97, 0.96), MeshKit.xf(Vector3(0, 0.5, -0.085), Vector3(90, 0, 0)), 24)
			k.rbox(Vector3(0.04, 0.26, 0.02), 0.01, Color(0.2, 0.22, 0.26), MeshKit.at(0, 0.6, 0.095))
			k.rbox(Vector3(0.2, 0.04, 0.02), 0.01, teal, MeshKit.xf(Vector3(0.08, 0.5, 0.095), Vector3(0, 0, -20)))
			k.cyl(0.07, 0.12, al, MeshKit.at(0, 0.94, 0), 10)
			k.cyl(0.1, 0.05, al.darkened(0.2), MeshKit.at(0, 1.05, 0), 10)
			root.set_meta("yaw", -15.0)
			root.set_meta("pitch", 10.0)
		"boost":
			k.prism(PackedVector2Array([Vector2(0.1, 0.6), Vector2(-0.3, -0.05), Vector2(-0.02, -0.05), Vector2(-0.15, -0.6), Vector2(0.3, 0.08), Vector2(0.02, 0.08)]), 0.16, lit.call(Color(0.4, 0.9, 1.0), 0.55), MeshKit.xf(Vector3(0, 0.6, -0.08), Vector3(90, 0, 0)))
			root.set_meta("yaw", -15.0)
			root.set_meta("pitch", 10.0)
		"speed":
			# an e-scooter with speed lines
			k.rbox(Vector3(1.0, 0.06, 0.24), 0.03, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.18, 0))
			k.cyl(0.03, 0.9, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(0.45, 0.18, 0), Vector3(0, 0, 12)), 6)
			k.rbox(Vector3(0.05, 0.05, 0.5), 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0.36, 1.08, 0))
			for sx in [-0.42, 0.48]:
				k.cyl(0.13, 0.08, Pal.RUBBER, MeshKit.xf(Vector3(sx, 0.13, 0), Vector3(90, 0, 0)) * MeshKit.at(0, -0.04, 0), 14)
			for i in 3:
				k.rbox(Vector3(0.36 - i * 0.08, 0.04, 0.04), 0.02, lit.call(teal), MeshKit.at(-0.75 - i * 0.05, 0.35 + i * 0.16, 0))
			root.set_meta("yaw", -8.0)
			root.set_meta("pitch", 14.0)
		"price":
			k.prism(PackedVector2Array([Vector2(-0.4, -0.25), Vector2(0.25, -0.25), Vector2(0.45, 0), Vector2(0.25, 0.25), Vector2(-0.4, 0.25)]), 0.06, Color(0.97, 0.97, 0.96), MeshKit.xf(Vector3(0, 0.5, 0), Vector3(90, 0, 0)))
			k.cyl(0.05, 0.08, teal, MeshKit.xf(Vector3(0.28, 0.5, -0.01), Vector3(90, 0, 0)), 10)
			k.cyl(0.16, 0.06, Color(0.92, 0.74, 0.32), MeshKit.xf(Vector3(-0.1, 0.5, 0.04), Vector3(90, 0, 0)), 16)
			root.set_meta("yaw", -12.0)
			root.set_meta("pitch", 12.0)
		"recipe":
			# a little neural network on a slab: models
			k.rbox(Vector3(1.2, 0.08, 0.9), 0.04, Color(0.16, 0.17, 0.2), MeshKit.at(0, 0.04, 0))
			var cols := [[-0.4, 3], [0.0, 4], [0.4, 2]]
			var pts := []
			for c in cols:
				var col := []
				for j in int(c[1]):
					col.append(Vector3(float(c[0]), 0.16, -0.27 + j * 0.54 / maxf(1.0, float(c[1]) - 1.0) if int(c[1]) > 1 else 0.0))
				pts.append(col)
			for l in 2:
				for a in pts[l]:
					for b in pts[l + 1]:
						var mid: Vector3 = (a + b) * 0.5
						var len: float = (b - a).length()
						var ang := rad_to_deg(atan2((b - a).z, (b - a).x))
						k.rbox(Vector3(len, 0.012, 0.012), 0.004, lit.call(Color(0.5, 0.9, 1.0), 0.5), MeshKit.xf(mid, Vector3(0, -ang, 0)))
			for col in pts:
				for p in col:
					k.sphere(0.075, Color(0.96, 0.97, 0.98), MeshKit.at(p.x, p.y, p.z), 10, 6)
			root.set_meta("pitch", 42.0)
		"research":
			# a flask with glowing liquid and a little chart
			k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.38, 0.0), Vector2(0.42, 0.06), Vector2(0.14, 0.62), Vector2(0.14, 0.95), Vector2(0.18, 1.0), Vector2(0.12, 1.0)]), Color(0.75, 0.88, 0.95, 0.85), Transform3D.IDENTITY, 18)
			k.lathe(PackedVector2Array([Vector2(0, 0.03), Vector2(0.36, 0.03), Vector2(0.24, 0.32), Vector2(0, 0.32)]), lit.call(Color(0.5, 0.9, 1.0), 0.5), Transform3D.IDENTITY, 18)
			for i in 3:
				k.sphere(0.04, Color(0.9, 0.98, 1.0, 0.5), MeshKit.at(-0.05 + i * 0.06, 0.4 + i * 0.12, 0.02), 6, 4)
			k.cyl(0.13, 0.12, Pal.WOOD_LIGHT, MeshKit.at(0, 0.98, 0), 10)
			root.set_meta("pitch", 16.0)
		"hammer":
			k.cyl(0.05, 1.1, Pal.WOOD, MeshKit.xf(Vector3(0, 0.0, 0), Vector3(0, 0, -35)), 8, 0.02)
			k.rbox(Vector3(0.18, 0.18, 0.5), 0.04, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(0.62, 0.9, 0), Vector3(0, 90, -35)))
			k.rbox(Vector3(1.0, 0.03, 0.12), 0.01, Color(0.8, 0.82, 0.86), MeshKit.xf(Vector3(0.25, 0.3, 0.12), Vector3(0, 0, 35)))
			root.set_meta("yaw", 0.0)
			root.set_meta("pitch", 20.0)
		"land":
			k.rbox(Vector3(1.2, 0.03, 0.9), 0.01, Color(0.36, 0.56, 0.78), MeshKit.at(0, 0.02, 0))
			for i in 4:
				k.rbox(Vector3(1.1, 0.032, 0.012), 0.004, Color(0.86, 0.94, 1.0), MeshKit.at(0, 0.035, -0.3 + i * 0.2))
				k.rbox(Vector3(0.012, 0.032, 0.8), 0.004, Color(0.86, 0.94, 1.0), MeshKit.at(-0.45 + i * 0.3, 0.035, 0))
			k.rbox(Vector3(0.28, 0.036, 0.18), 0.01, lit.call(Color(0.5, 1.0, 0.7), 0.5), MeshKit.at(0.15, 0.04, 0.1))
			k.cone(0.07, 0.3, teal, MeshKit.xf(Vector3(0.15, 0.04, 0.1), Vector3(180, 0, 0)) * MeshKit.at(0, -0.3, 0), 10)
			k.sphere(0.1, teal, MeshKit.at(0.15, 0.4, 0.1), 10, 6)
			root.set_meta("pitch", 46.0)
		"move":
			for i in 4:
				var b := Basis(Vector3.UP, i * PI * 0.5)
				k.rbox(Vector3(0.1, 0.1, 0.34), 0.03, teal, Transform3D(b, b * Vector3(0, 0.1, 0.24)))
				k.cone(0.15, 0.2, teal, Transform3D(b * Basis.from_euler(Vector3(PI * 0.5, 0, 0)), b * Vector3(0, 0.1, 0.4)), 4)
			k.sphere(0.1, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.1, 0), 10, 6)
			root.set_meta("pitch", 55.0)
		"rotate":
			k.torus(0.4, 0.07, teal, MeshKit.xf(Vector3(0, 0.5, 0), Vector3(90, 0, 0)), 24, 8, PI * 1.5)
			k.cone(0.16, 0.24, teal, MeshKit.xf(Vector3(0.4, 0.5, 0.0), Vector3(0, 0, 180)), 8)
			root.set_meta("yaw", -10.0)
			root.set_meta("pitch", 8.0)
		"storage":
			k.add_mesh(StorageB.mesh("depot", 2))
		"bay":
			k.add_mesh(ServerArt.module("data", 3))
			root.set_meta("pitch", 18.0)
		"deliver":
			k.add_mesh(Items.mesh("b:assist70"))
			k.sphere(0.06, Pal.BRASS, MeshKit.at(0, 0.32, 0), 8, 5)
			root.set_meta("pitch", 30.0)
		"hire", "builder":
			if name == "builder":
				var o := Color(0.97, 0.78, 0.26)
				k.ellipsoid(Vector3(0.42, 0.26, 0.4), o, MeshKit.at(0, 0.32, 0), 18, 8)
				k.cyl(0.5, 0.04, o.darkened(0.08), MeshKit.at(0, 0.3, 0.04), 20)
				k.rbox(Vector3(0.08, 0.08, 0.66), 0.03, o.lightened(0.15), MeshKit.at(0, 0.56, 0))
				k.cyl(0.04, 0.8, Pal.WOOD, MeshKit.xf(Vector3(-0.1, 0.05, 0.42), Vector3(0, 70, 85)), 8)
				k.rbox(Vector3(0.12, 0.12, 0.34), 0.03, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(0.5, 0.08, 0.6), Vector3(0, 70, 0)))
				k.cyl(0.08, 0.7, Color(0.36, 0.56, 0.86), MeshKit.xf(Vector3(-0.45, 0.08, -0.2), Vector3(0, 30, 90)), 12)
			else:
				# an ID badge on a lanyard with a plus
				k.torus(0.32, 0.03, teal, MeshKit.xf(Vector3(0, 0.95, -0.02), Vector3(90, 0, 0)), 20, 4, PI)
				k.rbox(Vector3(0.5, 0.66, 0.05), 0.06, Color(0.97, 0.97, 0.96), MeshKit.at(0, 0.45, 0))
				k.rbox(Vector3(0.36, 0.2, 0.02), 0.04, Color(0.84, 0.88, 0.92), MeshKit.at(0, 0.58, 0.03))
				k.rbox(Vector3(0.24, 0.07, 0.03), 0.02, Color(0.36, 0.76, 0.48), MeshKit.at(0, 0.32, 0.035))
				k.rbox(Vector3(0.07, 0.24, 0.03), 0.02, Color(0.36, 0.76, 0.48), MeshKit.at(0, 0.32, 0.035))
				root.set_meta("yaw", -12.0)
				root.set_meta("pitch", 8.0)
	_mi(k.commit(), root)
