class_name DecorB
extends Building
## Decorations with gentle area effects: flower beds, lamps, trees, hedges,
## benches (shops nearby get more customers; Bee Meadows make more honey),
## wells (farms nearby work faster), fountains (workers walk faster) and the
## Golden Cookie Statue (+5% on every sale).

var _water: Node3D
var _sails: Node3D


func solid_rects() -> Array[Rect2]:
	var s := size_m()
	var m := 0.45 if size().x == 1 else 0.6
	return [Rect2(-s.x * 0.5 + m, -s.y * 0.5 + m, s.x - m * 2.0, s.y - m * 2.0)]


func _visual(root: Node3D, _t: int) -> void:
	Mats.inst(MeshKit.cached("decor_" + kind, func(): return DecorB.mesh(kind)), root)
	if kind == "fountain":
		_water = Node3D.new()
		_water.position = Vector3(0, 1.25, 0)
		root.add_child(_water)
		var mi := Mats.inst(MeshKit.cached("fountain_jet", func():
			var k := MeshKit.new()
			k.cyl(0.06, 0.6, Color(0.7, 0.86, 0.95, 0.6), MeshKit.at(0, 0, 0), 8, 0.02, 0.02)
			k.sphere(0.12, Color(0.7, 0.86, 0.95, 0.6), MeshKit.at(0, 0.62, 0), 8, 5)
			return k.commit()), _water, Transform3D.IDENTITY, false)
		mi.material_override = Mats.glow()
	if kind == "windmill":
		_sails = Node3D.new()
		_sails.position = Vector3(0, 3.2, 0.9)
		root.add_child(_sails)
		Mats.inst(MeshKit.cached("windmill_sails", func():
			var k := MeshKit.new()
			for i in 4:
				var b := Basis(Vector3.BACK, i * PI * 0.5)
				k.rbox(Vector3(0.08, 1.6, 0.04), 0.01, Pal.WOOD_DARK, Transform3D(b, b * Vector3(0, 0.85, 0.05)))
				k.rbox(Vector3(0.4, 1.3, 0.02), 0.01, Pal.CREAM, Transform3D(b, b * Vector3(0.22, 0.95, 0.06)))
			return k.commit()), _sails)
	if kind == "lamp":
		var l := OmniLight3D.new()
		l.light_color = Color(1.0, 0.85, 0.6)
		l.light_energy = 0.4
		l.omni_range = 3.0
		l.position = Vector3(0, 2.2, 0)
		root.add_child(l)


func _process(dt: float) -> void:
	super(dt)
	if _sails:
		_sails.rotation.z += dt * 0.8
	if _water:
		_water.scale = Vector3(1, 1.0 + sin(_t * 4.0) * 0.12, 1)


func status() -> String:
	var a: Dictionary = def.get("aura", {})
	match a.get("what", ""):
		"charm": return "Shops within %d tiles get %d%% more customers." % [int(a["r"]), roundi(float(a["v"]) * 100)]
		"farm": return "Farms within %d tiles work %d%% faster." % [int(a["r"]), roundi(float(a["v"]) * 100)]
		"walk": return "Workers within %d tiles walk %d%% faster." % [int(a["r"]), roundi(float(a["v"]) * 100)]
		"global_price": return "Every cookie sells for 5% more."
	return ""


static func mesh(k_: String) -> Mesh:
	var k := MeshKit.new()
	match k_:
		"flowers":
			k.rbox(Vector3(1.4, 0.3, 1.4), 0.06, Pal.WOOD, MeshKit.at(0, 0.15, 0))
			k.rbox(Vector3(1.25, 0.06, 1.25), 0.03, Pal.SOIL, MeshKit.at(0, 0.3, 0))
			for i in 16:
				var p := Vector3(-0.45 + (i % 4) * 0.3, 0.32, -0.45 + (i / 4) * 0.3)
				var c: Color = [Color(0.58, 0.52, 0.72), Color(0.96, 0.94, 0.88), Color(0.92, 0.7, 0.4), Color(0.85, 0.5, 0.55)][(i * 7) % 4]
				k.cyl(0.015, 0.22, Pal.LEAF, MeshKit.at(p.x, p.y, p.z), 4)
				k.sphere(0.07, c, MeshKit.at(p.x, p.y + 0.24, p.z), 6, 4)
		"lamp":
			k.rbox(Vector3(0.4, 0.15, 0.4), 0.04, Pal.STEEL_DARK, MeshKit.at(0, 0.07, 0))
			k.cyl(0.05, 2.0, Pal.STEEL_DARK, MeshKit.at(0, 0.1, 0), 8)
			k.rbox(Vector3(0.3, 0.38, 0.3), 0.05, Color(1.0, 0.88, 0.6, 0.4), MeshKit.at(0, 2.25, 0))
			k.cone(0.24, 0.2, Pal.STEEL_DARK, MeshKit.at(0, 2.45, 0), 8)
		"tree":
			k.add_mesh(Terrain.decor_mesh("oak"), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(0.8, 0.8, 0.8)))
			k.cyl(0.6, 0.12, Pal.STONE, MeshKit.at(0, 0, 0), 12, 0.03)
		"hedge":
			k.rbox(Vector3(1.6, 0.8, 1.6), 0.25, Color(0.36, 0.48, 0.3), MeshKit.at(0, 0.42, 0))
			k.rbox(Vector3(1.5, 0.1, 1.5), 0.05, Color(0.42, 0.54, 0.34), MeshKit.at(0, 0.84, 0))
		"bench":
			k.rbox(Vector3(1.4, 0.08, 0.45), 0.03, Pal.WOOD, MeshKit.at(0, 0.42, 0))
			k.rbox(Vector3(1.4, 0.4, 0.06), 0.03, Pal.WOOD, MeshKit.xf(Vector3(0, 0.7, -0.22), Vector3(-10, 0, 0)))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 0.42, 0.45), 0.02, Pal.STEEL_DARK, MeshKit.at(sx * 0.6, 0.21, 0))
		"well":
			k.cyl(0.6, 0.6, Pal.STONE, MeshKit.at(0, 0, 0), 14, 0.06)
			k.cyl(0.48, 0.05, Color(0.3, 0.5, 0.6), MeshKit.at(0, 0.56, 0), 14)
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.1, 1.4, 0.1), 0.02, Pal.WOOD_DARK, MeshKit.at(sx * 0.55, 0.7, 0))
			for sd in [-1.0, 1.0]:
				k.rbox(Vector3(0.75, 0.06, 1.0), 0.02, Pal.TERRACOTTA, MeshKit.xf(Vector3(sd * 0.3, 1.55, 0), Vector3(0, 0, -sd * 35)))
			k.cyl(0.04, 1.0, Pal.WOOD, MeshKit.xf(Vector3(-0.5, 1.15, 0), Vector3(0, 0, 90)), 6)
			k.cyl(0.12, 0.18, Pal.WOOD, MeshKit.at(0.15, 0.85, 0), 8, 0.02)
		"fountain":
			k.cyl(1.6, 0.4, Pal.STONE, MeshKit.at(0, 0, 0), 20, 0.06)
			k.cyl(1.4, 0.05, Color(0.4, 0.6, 0.7), MeshKit.at(0, 0.36, 0), 20)
			k.cyl(0.25, 0.9, Pal.STONE_DARK, MeshKit.at(0, 0.3, 0), 10, 0.03)
			k.cyl(0.6, 0.12, Pal.STONE, MeshKit.at(0, 1.1, 0), 14, 0.03)
			k.cyl(0.5, 0.04, Color(0.45, 0.65, 0.75), MeshKit.at(0, 1.2, 0), 14)
		"picnic":
			k.rbox(Vector3(1.3, 0.07, 0.7), 0.02, Pal.WOOD, MeshKit.at(0, 0.62, 0))
			k.rbox(Vector3(1.32, 0.02, 0.72), 0.01, Color(0.92, 0.88, 0.84), MeshKit.at(0, 0.665, 0))
			for i in 4:
				if i % 2 == 0:
					k.rbox(Vector3(0.33, 0.021, 0.72), 0.005, Pal.TERRACOTTA, MeshKit.at(-0.495 + i * 0.33, 0.668, 0))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.07, 0.6, 0.6), 0.02, Pal.WOOD_DARK, MeshKit.at(sx * 0.5, 0.3, 0))
				k.rbox(Vector3(1.3, 0.05, 0.25), 0.02, Pal.WOOD, MeshKit.at(0, 0.36, sx * 0.55))
			k.cyl(0.14, 0.02, Pal.CREAM, MeshKit.at(0.2, 0.68, 0), 10)
			Items.cookie_into(k, "choc", 0.05, 0.02, MeshKit.at(0.18, 0.7, 0.02))
			Items.cookie_into(k, "sugar", 0.05, 0.02, MeshKit.at(0.24, 0.7, -0.03))
		"banner":
			k.rbox(Vector3(0.4, 0.12, 0.4), 0.03, Pal.STONE_DARK, MeshKit.at(0, 0.06, 0))
			k.cyl(0.04, 2.6, Pal.WOOD_DARK, MeshKit.at(0, 0, 0), 6)
			k.sphere(0.07, Pal.BRASS, MeshKit.at(0, 2.62, 0), 6, 4)
			k.rbox(Vector3(0.7, 0.05, 0.04), 0.01, Pal.WOOD_DARK, MeshKit.at(0.32, 2.45, 0))
			k.rbox(Vector3(0.62, 1.2, 0.03), 0.02, Pal.CREAM, MeshKit.at(0.34, 1.82, 0))
			k.rbox(Vector3(0.62, 0.18, 0.035), 0.01, Pal.TERRACOTTA, MeshKit.at(0.34, 2.32, 0))
			k.rbox(Vector3(0.62, 0.18, 0.035), 0.01, Pal.TERRACOTTA, MeshKit.at(0.34, 1.32, 0))
			Items.cookie_into(k, "choc", 0.16, 0.03, MeshKit.xf(Vector3(0.34, 1.82, 0.02), Vector3(90, 0, 0)))
		"topiary":
			k.cyl(0.32, 0.45, Pal.TERRACOTTA, MeshKit.at(0, 0, 0), 12, 0.04, 0.4)
			k.cyl(0.38, 0.06, Pal.BRICK_DARK, MeshKit.at(0, 0.42, 0), 12)
			k.cyl(0.05, 0.4, Pal.WOOD_DARK, MeshKit.at(0, 0.45, 0), 6)
			k.sphere(0.5, Color(0.34, 0.48, 0.3), MeshKit.at(0, 1.25, 0), 14, 9)
			k.sphere(0.3, Color(0.4, 0.54, 0.34), MeshKit.at(0, 1.95, 0), 12, 7)
		"pond":
			k.cyl(1.6, 0.18, Pal.STONE, MeshKit.at(0, 0, 0), 20, 0.05)
			k.cyl(1.4, 0.04, Color(0.32, 0.52, 0.6), MeshKit.at(0, 0.16, 0), 20)
			for i in 5:
				var a := TAU * i / 5.0 + 0.4
				k.cyl(0.22, 0.02, Color(0.4, 0.6, 0.36), MeshKit.at(cos(a) * 0.8, 0.2, sin(a) * 0.7), 10)
				if i % 2 == 0:
					k.sphere(0.06, Color(0.98, 0.88, 0.9), MeshKit.at(cos(a) * 0.8, 0.24, sin(a) * 0.7), 6, 4)
			for i in 6:
				k.cyl(0.015, 0.8, Color(0.46, 0.56, 0.34), MeshKit.xf(Vector3(1.25 + (i % 3) * 0.08, 0.1, -0.6 + i * 0.08), Vector3(0, 0, (i - 3) * 4)), 4)
		"gazebo":
			k.cyl(1.5, 0.25, Pal.STONE, MeshKit.at(0, 0, 0), 8, 0.04)
			for i in 6:
				var a2 := TAU * i / 6.0
				k.cyl(0.07, 1.9, Color(0.96, 0.95, 0.92), MeshKit.at(cos(a2) * 1.25, 0.25, sin(a2) * 1.25), 8)
			k.cyl(1.45, 0.12, Color(0.96, 0.95, 0.92), MeshKit.at(0, 2.15, 0), 8, 0.03)
			k.cone(1.65, 1.0, Pal.TERRACOTTA, MeshKit.at(0, 2.27, 0), 8)
			k.sphere(0.1, Pal.BRASS, MeshKit.at(0, 3.3, 0), 8, 5)
			k.rbox(Vector3(1.6, 0.08, 0.4), 0.03, Pal.WOOD, MeshKit.at(0, 0.6, -0.8))
		"windmill":
			k.cyl(1.0, 3.6, Color(0.94, 0.92, 0.86), MeshKit.at(0, 0, 0), 14, 0.04, 0.7)
			for y in [1.0, 2.2]:
				k.rbox(Vector3(0.36, 0.5, 0.05), 0.05, Color(0.3, 0.4, 0.5, 0.8), MeshKit.at(0, y, 0.92 - y * 0.06))
			k.rbox(Vector3(0.6, 0.9, 0.06), 0.15, Pal.WOOD_DARK, MeshKit.at(0, 0.45, 1.0))
			k.cone(0.85, 1.0, Pal.TERRACOTTA, MeshKit.at(0, 3.6, 0), 14)
			k.sphere(0.12, Pal.BRASS, MeshKit.at(0, 3.2, 0.82), 8, 5)
		"statue":
			k.rbox(Vector3(2.4, 0.5, 2.4), 0.06, Pal.STONE, MeshKit.at(0, 0.25, 0))
			k.rbox(Vector3(1.6, 1.0, 1.6), 0.05, Pal.STONE_DARK, MeshKit.at(0, 1.0, 0))
			k.rbox(Vector3(1.7, 0.1, 1.7), 0.03, Pal.GOLD, MeshKit.at(0, 1.52, 0))
			Items.cookie_into(k, "royal", 1.0, 0.35, MeshKit.xf(Vector3(0, 2.55, 0), Vector3(90, 0, 0)))
			k.torus(1.02, 0.06, Pal.GOLD, MeshKit.xf(Vector3(0, 2.55, 0.17), Vector3(90, 0, 0)), 24, 5)
	return k.commit()
