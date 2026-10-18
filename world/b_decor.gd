class_name DecorB
extends Building
## Decorations with gentle area effects: planters, smart lamps, trees,
## hedges, benches, bike racks, flags and robot statues (the Chat Café
## nearby gets more visitors; Rare Earth Mines dig faster), substations,
## battery banks and wind turbines (sources nearby work faster), the coffee
## cart (staff move faster) and the Golden GPU (+5% on every sale).

var _steam: Node3D
var _blades: Node3D
var _head: Node3D


func solid_rects() -> Array[Rect2]:
	var s := size_m()
	var m := 0.45 if size().x == 1 else 0.6
	return [Rect2(-s.x * 0.5 + m, -s.y * 0.5 + m, s.x - m * 2.0, s.y - m * 2.0)]


func _visual(root: Node3D, _t: int) -> void:
	Mats.inst(MeshKit.cached("decor_" + kind, func(): return DecorB.mesh(kind)), root)
	match kind:
		"coffee":
			_steam = Node3D.new()
			_steam.position = Vector3(0.55, 1.55, 0.2)
			root.add_child(_steam)
			var mi := Mats.inst(MeshKit.cached("coffee_steam", func():
				var k := MeshKit.new()
				k.sphere(0.12, Color(0.96, 0.96, 0.96, 0.7), MeshKit.at(0, 0.1, 0), 8, 5)
				k.sphere(0.09, Color(0.96, 0.96, 0.96, 0.7), MeshKit.at(0.06, 0.28, 0.02), 8, 5)
				k.sphere(0.06, Color(0.96, 0.96, 0.96, 0.7), MeshKit.at(-0.02, 0.42, 0), 6, 4)
				return k.commit()), _steam, Transform3D.IDENTITY, false)
			mi.material_override = Mats.glow()
		"turbine":
			_blades = Node3D.new()
			_blades.position = Vector3(0, 3.6, 0.32)
			root.add_child(_blades)
			Mats.inst(MeshKit.cached("turbine_blades", func():
				var k := MeshKit.new()
				for i in 3:
					var b := Basis(Vector3.BACK, i * TAU / 3.0)
					k.rbox(Vector3(0.16, 1.7, 0.05), 0.04, Color(0.96, 0.97, 0.98), Transform3D(b, b * Vector3(0.04, 0.9, 0.0)))
				k.sphere(0.14, Color(0.9, 0.92, 0.94), MeshKit.at(0, 0, 0.04), 10, 6)
				return k.commit()), _blades)
		"robot":
			_head = Node3D.new()
			_head.position = Vector3(0, 1.22, 0)
			root.add_child(_head)
			Mats.inst(MeshKit.cached("robot_head", func():
				var k := MeshKit.new()
				k.rbox(Vector3(0.42, 0.32, 0.36), 0.1, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.16, 0))
				k.rbox(Vector3(0.32, 0.16, 0.02), 0.06, Color(0.14, 0.15, 0.18), MeshKit.at(0, 0.17, 0.18))
				for sx in [-0.07, 0.07]:
					k.rbox(Vector3(0.05, 0.06, 0.01), 0.02, Color(0.5, 0.95, 1.0, 0.4), MeshKit.at(sx, 0.18, 0.192))
				k.cyl(0.015, 0.12, Pal.STEEL_DARK, MeshKit.at(0, 0.32, 0), 5)
				k.sphere(0.04, Color(1.0, 0.5, 0.4, 0.45), MeshKit.at(0, 0.46, 0), 6, 4)
				return k.commit()), _head)
		"lamp":
			var l := OmniLight3D.new()
			l.light_color = Color(0.85, 0.95, 1.0)
			l.light_energy = 0.4
			l.omni_range = 3.0
			l.position = Vector3(0, 2.2, 0)
			root.add_child(l)


func _process(dt: float) -> void:
	super(dt)
	if _blades:
		_blades.rotation.z += dt * 1.1
	if _steam:
		_steam.position.y = 1.55 + fmod(_t * 0.4, 0.3)
		_steam.scale = Vector3.ONE * (1.0 + sin(_t * 3.0) * 0.12)
	if _head:
		_head.rotation.y = sin(_t * 0.7) * 0.7


func status() -> String:
	var a: Dictionary = def.get("aura", {})
	match a.get("what", ""):
		"charm": return "Cafés within %d tiles get %d%% more visitors." % [int(a["r"]), roundi(float(a["v"]) * 100)]
		"source": return "Sources within %d tiles work %d%% faster." % [int(a["r"]), roundi(float(a["v"]) * 100)]
		"walk": return "Staff within %d tiles move %d%% faster." % [int(a["r"]), roundi(float(a["v"]) * 100)]
		"global_price": return "Every token sells for 5% more."
	return ""


static func mesh(k_: String) -> Mesh:
	var k := MeshKit.new()
	var lit := func(c: Color) -> Color: return Color(c.r, c.g, c.b, 0.45)
	match k_:
		"planter":
			k.rbox(Vector3(1.3, 0.4, 1.3), 0.08, Color(0.9, 0.91, 0.92), MeshKit.at(0, 0.2, 0))
			k.rbox(Vector3(1.32, 0.05, 1.32), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(0, 0.36, 0))
			k.rbox(Vector3(1.15, 0.05, 1.15), 0.03, Pal.SOIL, MeshKit.at(0, 0.4, 0))
			for i in 9:
				var p := Vector3(-0.38 + (i % 3) * 0.38, 0.42, -0.38 + (i / 3) * 0.38)
				if i % 2 == 0:
					k.sphere(0.2, Pal.LEAF.lightened(0.05 * (i % 3)), MeshKit.at(p.x, p.y + 0.16, p.z), 8, 6)
				else:
					k.cyl(0.015, 0.22, Pal.LEAF, MeshKit.at(p.x, p.y, p.z), 4)
					k.sphere(0.07, [Color(0.58, 0.52, 0.72), Color(0.96, 0.94, 0.88), Color(0.92, 0.7, 0.4)][i % 3], MeshKit.at(p.x, p.y + 0.24, p.z), 6, 4)
		"lamp":
			k.rbox(Vector3(0.4, 0.15, 0.4), 0.04, Pal.STEEL_DARK, MeshKit.at(0, 0.07, 0))
			k.cyl(0.05, 2.1, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.1, 0), 8)
			k.rbox(Vector3(0.7, 0.08, 0.16), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0.25, 2.2, 0))
			k.rbox(Vector3(0.5, 0.03, 0.12), 0.01, lit.call(Color(0.86, 0.96, 1.0)), MeshKit.at(0.3, 2.15, 0))
			k.rbox(Vector3(0.12, 0.2, 0.02), 0.02, lit.call(Color(0.4, 0.9, 1.0)), MeshKit.at(0, 1.2, 0.06))
		"tree":
			k.add_mesh(Terrain.decor_mesh("oak"), MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(0.8, 0.8, 0.8)))
			k.cyl(0.6, 0.12, Color(0.86, 0.87, 0.88), MeshKit.at(0, 0, 0), 12, 0.03)
		"hedge":
			k.rbox(Vector3(1.6, 0.8, 1.6), 0.25, Color(0.36, 0.48, 0.3), MeshKit.at(0, 0.42, 0))
			k.rbox(Vector3(1.5, 0.1, 1.5), 0.05, Color(0.42, 0.54, 0.34), MeshKit.at(0, 0.84, 0))
		"bench":
			k.rbox(Vector3(1.4, 0.08, 0.45), 0.03, Pal.WOOD, MeshKit.at(0, 0.42, 0))
			k.rbox(Vector3(1.4, 0.4, 0.06), 0.03, Pal.WOOD, MeshKit.xf(Vector3(0, 0.7, -0.22), Vector3(-10, 0, 0)))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 0.42, 0.45), 0.02, Pal.STEEL_DARK, MeshKit.at(sx * 0.6, 0.21, 0))
			k.rbox(Vector3(0.2, 0.06, 0.12), 0.02, Color(0.24, 0.25, 0.28), MeshKit.at(0.45, 0.49, 0.05))
		"substation":
			# a fenced transformer with insulators and a warning sign
			k.rbox(Vector3(1.4, 0.12, 1.4), 0.03, Color(0.6, 0.6, 0.58), MeshKit.at(0, 0.06, 0))
			k.rbox(Vector3(0.7, 0.8, 0.6), 0.04, Color(0.56, 0.62, 0.58), MeshKit.at(0, 0.52, -0.05))
			for i in 5:
				k.rbox(Vector3(0.72, 0.03, 0.04), 0.01, Color(0.46, 0.52, 0.48), MeshKit.at(0, 0.25 + i * 0.12, 0.26))
			for sx in [-0.22, 0.0, 0.22]:
				k.cyl(0.04, 0.3, Color(0.86, 0.5, 0.3), MeshKit.at(sx, 0.92, -0.05), 6)
				for j in 3:
					k.cyl(0.07, 0.03, Color(0.82, 0.48, 0.3), MeshKit.at(sx, 0.96 + j * 0.08, -0.05), 8)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.cyl(0.025, 0.7, Color(0.62, 0.64, 0.66), MeshKit.at(sx * 0.62, 0.1, sz * 0.62), 5)
			k.rbox(Vector3(0.2, 0.18, 0.02), 0.01, Color(0.96, 0.8, 0.26), MeshKit.at(0, 0.6, 0.27))
		"bikes":
			k.rbox(Vector3(1.4, 0.05, 0.6), 0.02, Color(0.6, 0.6, 0.58), MeshKit.at(0, 0.025, 0))
			for i in 3:
				var x := -0.45 + i * 0.45
				var col: Color = [Color(0.3, 0.6, 0.86), Color(0.96, 0.6, 0.3), Color(0.3, 0.66, 0.68)][i]
				for sz in [-0.3, 0.3]:
					k.torus(0.2, 0.02, Pal.RUBBER, MeshKit.xf(Vector3(x, 0.22, sz), Vector3(0, 90, 90)), 14, 4)
				k.rbox(Vector3(0.03, 0.03, 0.6), 0.01, col, MeshKit.at(x, 0.32, 0))
				k.rbox(Vector3(0.03, 0.3, 0.03), 0.01, col, MeshKit.xf(Vector3(x, 0.38, -0.12), Vector3(-15, 0, 0)))
				k.rbox(Vector3(0.06, 0.03, 0.12), 0.01, Color(0.2, 0.2, 0.22), MeshKit.at(x, 0.54, -0.15))
				k.rbox(Vector3(0.24, 0.025, 0.025), 0.01, Color(0.2, 0.2, 0.22), MeshKit.at(x, 0.55, 0.28))
		"flag":
			k.cyl(0.18, 0.12, Color(0.86, 0.87, 0.88), MeshKit.at(0, 0, 0), 10, 0.02)
			k.cyl(0.04, 2.6, Color(0.86, 0.87, 0.88), MeshKit.at(0, 0, 0), 8)
			k.sphere(0.07, Pal.BRASS, MeshKit.at(0, 2.62, 0), 8, 5)
			k.rbox(Vector3(0.9, 0.56, 0.03), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(0.48, 2.25, 0))
			Items.token_into(k, "frontier", 0.14, 0.03, MeshKit.xf(Vector3(0.48, 2.25, 0.03), Vector3(90, 0, 0)))
		"robot":
			# a friendly robot on a plinth (its head turns: see _visual)
			k.rbox(Vector3(0.7, 0.3, 0.7), 0.06, Color(0.86, 0.87, 0.88), MeshKit.at(0, 0.15, 0))
			k.rbox(Vector3(0.36, 0.5, 0.28), 0.1, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.62, 0))
			k.rbox(Vector3(0.2, 0.12, 0.02), 0.04, lit.call(Color(0.5, 0.95, 1.0)), MeshKit.at(0, 0.68, 0.142))
			for sx in [-1.0, 1.0]:
				k.capsule(0.06, 0.38, Color(0.95, 0.95, 0.94), MeshKit.xf(Vector3(sx * 0.24, 0.85, 0), Vector3(0, 0, sx * 160)), 8, 3)
				k.cyl(0.06, 0.18, Pal.STEEL_DARK, MeshKit.at(sx * 0.1, 0.3, 0), 8)
			k.cyl(0.05, 0.12, Pal.STEEL_DARK, MeshKit.at(0, 1.1, 0), 8)
		"battery":
			# a bank of battery cabinets with charge lights
			k.rbox(Vector3(2.6, 0.12, 2.6), 0.03, Color(0.6, 0.6, 0.58), MeshKit.at(0, 0.06, 0))
			for i in 3:
				var x := -0.8 + i * 0.8
				k.rbox(Vector3(0.7, 1.3, 1.2), 0.06, Color(0.94, 0.95, 0.96), MeshKit.at(x, 0.75, -0.2))
				for j in 4:
					k.rbox(Vector3(0.1, 0.06, 0.01), 0.01, lit.call(Color(0.5, 1.0, 0.6) if j < 3 - (i % 2) else Color(0.4, 0.42, 0.46)), MeshKit.at(x - 0.15 + j * 0.1, 1.2, 0.41))
				k.rbox(Vector3(0.72, 0.06, 1.22), 0.02, Color(0.46, 0.82, 0.52), MeshKit.at(x, 1.42, -0.2))
		"foodtruck":
			# a food truck with an open hatch, an awning and a menu
			k.rbox(Vector3(2.2, 0.2, 1.1), 0.04, Pal.STEEL_DARK, MeshKit.at(0, 0.32, 0))
			k.rbox(Vector3(2.2, 1.2, 1.1), 0.18, Color(0.96, 0.6, 0.3), MeshKit.at(0, 1.0, 0))
			k.rbox(Vector3(1.2, 0.5, 0.04), 0.04, Color(0.14, 0.15, 0.18), MeshKit.at(-0.2, 1.15, 0.56))
			k.rbox(Vector3(1.4, 0.05, 0.6), 0.02, Color(0.96, 0.96, 0.95), MeshKit.xf(Vector3(-0.2, 1.48, 0.8), Vector3(-15, 0, 0)))
			k.rbox(Vector3(1.3, 0.05, 0.3), 0.02, Color(0.96, 0.96, 0.95), MeshKit.at(-0.2, 0.9, 0.7))
			k.rbox(Vector3(0.36, 0.5, 0.04), 0.03, Color(0.14, 0.15, 0.18), MeshKit.at(0.85, 1.05, 0.56))
			for sx in [-0.7, 0.7]:
				for sz in [-0.5, 0.5]:
					k.cyl(0.18, 0.12, Pal.RUBBER, MeshKit.xf(Vector3(sx, 0.18, sz), Vector3(90, 0, 0)) * MeshKit.at(0, -0.06, 0), 10)
			k.cyl(0.04, 0.7, Pal.STEEL_DARK, MeshKit.at(1.4, 0, 0.7), 6)
			k.cyl(0.35, 0.05, Color(0.3, 0.66, 0.68), MeshKit.at(1.4, 0.7, 0.7), 12)
		"coffee":
			# a coffee cart with a big cup sign (steam: see _visual)
			k.rbox(Vector3(1.6, 0.9, 0.9), 0.1, Color(0.36, 0.26, 0.2), MeshKit.at(0, 0.6, 0))
			k.rbox(Vector3(1.7, 0.06, 1.0), 0.02, Color(0.94, 0.9, 0.82), MeshKit.at(0, 1.07, 0))
			k.rbox(Vector3(0.5, 0.5, 0.4), 0.06, Pal.STEEL, MeshKit.at(0.45, 1.35, -0.1))
			k.cyl(0.07, 0.12, Color(0.96, 0.96, 0.95), MeshKit.at(0.55, 1.1, 0.2), 8, 0.0, 0.08)
			for sx in [-1.0, 1.0]:
				k.cyl(0.18, 0.08, Pal.RUBBER, MeshKit.xf(Vector3(sx * 0.6, 0.18, 0.46), Vector3(90, 0, 0)), 10)
			k.cyl(0.03, 1.0, Pal.STEEL_DARK, MeshKit.at(-0.6, 1.1, 0), 6)
			k.cyl(0.2, 0.3, Color(0.96, 0.96, 0.95), MeshKit.at(-0.6, 2.1, 0), 12, 0.03, 0.24)
			k.cyl(0.25, 0.04, Color(0.36, 0.26, 0.2), MeshKit.at(-0.6, 2.4, 0), 12)
		"turbine":
			# a slim wind turbine (blades: see _visual)
			k.cyl(0.5, 0.15, Color(0.7, 0.7, 0.68), MeshKit.at(0, 0, 0), 14, 0.03)
			k.cyl(0.14, 3.6, Color(0.96, 0.97, 0.98), MeshKit.at(0, 0, 0), 10, 0.0, 0.08)
			k.rbox(Vector3(0.26, 0.26, 0.6), 0.1, Color(0.96, 0.97, 0.98), MeshKit.at(0, 3.6, 0.0))
		"gpu_statue":
			# a golden graphics card on a plinth
			k.rbox(Vector3(1.4, 0.6, 1.0), 0.08, Color(0.9, 0.91, 0.92), MeshKit.at(0, 0.3, 0))
			k.rbox(Vector3(1.44, 0.06, 1.04), 0.02, Pal.BRASS, MeshKit.at(0, 0.6, 0))
			var g := Color(0.92, 0.74, 0.32)
			var cd := MeshKit.xf(Vector3(0, 1.45, 0), Vector3(0, 0, 0))
			k.rbox(Vector3(1.8, 1.0, 0.24), 0.08, g, cd)
			for sx in [-0.45, 0.45]:
				k.cyl(0.36, 0.06, g.darkened(0.15), cd * MeshKit.xf(Vector3(sx, 0, 0.12), Vector3(90, 0, 0)), 20)
				k.cyl(0.12, 0.08, g.lightened(0.15), cd * MeshKit.xf(Vector3(sx, 0, 0.14), Vector3(90, 0, 0)), 12)
			k.rbox(Vector3(0.14, 1.0, 0.3), 0.03, g.darkened(0.1), cd * MeshKit.at(-0.94, 0, 0))
			k.rbox(Vector3(1.4, 0.08, 0.05), 0.02, lit.call(Color(1.0, 0.9, 0.6)), cd * MeshKit.at(0, -0.42, 0.13))
	return k.commit()
