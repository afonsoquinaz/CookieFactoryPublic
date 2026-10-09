class_name Items
## Meshes for every carriable item. Each sits on y = 0, fits a ~0.42 m
## footprint and stacks cleanly (height = Defs.ITEMS[t].h).

static func mesh(t: String) -> Mesh:
	return MeshKit.cached("item_" + t, func(): return _build(t))


static func height(t: String) -> float:
	return float(Defs.ITEMS[t]["h"]) if Defs.ITEMS.has(t) else 0.2


static func node(t: String) -> MeshInstance3D:
	var mi := Mats.inst(mesh(t))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _build(t: String) -> Mesh:
	var k := MeshKit.new()
	match t:
		"wheat":
			# a tied sheaf lying on its side: stalks + ears + red ribbon
			var gold := Color(1.0, 0.8, 0.32)
			var gold_dk := Color(0.92, 0.66, 0.2)
			for i in 5:
				var a := TAU * i / 5.0
				var o := Vector3(0, 0.1 + sin(a) * 0.045, cos(a) * 0.05)
				k.cyl(0.03, 0.42, gold_dk, MeshKit.xf(o + Vector3(-0.2, 0, 0), Vector3(0, 0, -90 + sin(a) * 6)), 6)
				k.ellipsoid(Vector3(0.09, 0.04, 0.04), gold, MeshKit.xf(o + Vector3(0.27, sin(a) * 0.02, cos(a) * 0.02), Vector3(0, 0, sin(a) * 10)), 6, 4)
			k.cyl(0.085, 0.07, Pal.RED, MeshKit.xf(Vector3(-0.05, 0.1, 0), Vector3(0, 0, 90)), 12, 0.02)
		"sugar":
			# three cut canes with joints, tied, a few leaves
			var cane := Color(0.62, 0.86, 0.36)
			var joint := Color(0.48, 0.72, 0.28)
			var offs := [Vector3(0, 0.055, -0.07), Vector3(0, 0.055, 0.07), Vector3(0, 0.13, 0)]
			for o in offs:
				k.cyl(0.055, 0.46, cane, MeshKit.xf(o + Vector3(-0.23, 0, 0), Vector3(0, 0, -90)), 8)
				for j in 3:
					k.torus(0.055, 0.012, joint, MeshKit.xf(o + Vector3(-0.15 + j * 0.15, 0, 0), Vector3(0, 0, 90)), 8, 3)
				k.cyl(0.045, 0.004, Color(0.95, 0.97, 0.85), MeshKit.xf(o + Vector3(0.231, 0, 0), Vector3(0, 0, -90)), 10)
			k.ellipsoid(Vector3(0.16, 0.012, 0.05), Pal.LEAF, MeshKit.xf(Vector3(-0.28, 0.17, 0.03), Vector3(0, 20, 25)), 8, 4)
			k.cyl(0.13, 0.05, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(0.02, 0.07, 0), Vector3(0, 0, 90)), 12, 0.01)
		"cocoa":
			# ribbed pod lying down
			var pod := Color(0.92, 0.5, 0.18)
			var rib := Color(0.98, 0.62, 0.24)
			k.ellipsoid(Vector3(0.21, 0.1, 0.1), pod, MeshKit.at(0, 0.1, 0), 12, 8)
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				k.ellipsoid(Vector3(0.2, 0.025, 0.025), rib, MeshKit.xf(Vector3(0, 0.1 + sin(a) * 0.085, cos(a) * 0.085), Vector3(a * 57.3, 0, 0)), 8, 3)
			k.cyl(0.02, 0.06, Pal.LEAF_DARK, MeshKit.xf(Vector3(-0.2, 0.1, 0), Vector3(0, 0, 90)), 6)
		"egg":
			# a little tray with four eggs
			k.rbox(Vector3(0.4, 0.08, 0.4), 0.035, Color(0.96, 0.74, 0.55), MeshKit.at(0, 0.04, 0))
			for x in [-0.095, 0.095]:
				for z in [-0.095, 0.095]:
					k.ellipsoid(Vector3(0.075, 0.1, 0.075), Color(1.0, 0.95, 0.84), MeshKit.at(x, 0.1, z), 10, 7)
		"milk":
			# a milk carton: white body, blue band and gable top
			k.rbox(Vector3(0.28, 0.24, 0.28), 0.04, Pal.WHITE, MeshKit.at(0, 0.12, 0))
			k.rbox(Vector3(0.285, 0.08, 0.285), 0.035, Color(0.38, 0.62, 0.98), MeshKit.at(0, 0.1, 0))
			for sd in [-1.0, 1.0]:
				k.rbox(Vector3(0.17, 0.03, 0.27), 0.012, Color(0.38, 0.62, 0.98), MeshKit.xf(Vector3(sd * 0.068, 0.27, 0), Vector3(0, 0, -sd * 32)))
			k.rbox(Vector3(0.03, 0.07, 0.25), 0.01, Pal.WHITE, MeshKit.at(0, 0.32, 0))
			k.ellipsoid(Vector3(0.05, 0.035, 0.012), Pal.WHITE, MeshKit.at(0, 0.13, 0.142), 8, 5)
		"cookie":
			_cookie(k, 0.19, 0.085)
		"dough":
			k.sphere(0.2, Pal.DOUGH, MeshKit.at(0, 0.2, 0), 14, 10)
			for i in 6:
				var a := TAU * i / 6.0
				k.ellipsoid(Vector3(0.04, 0.03, 0.04), Pal.CHOCO, MeshKit.at(cos(a) * 0.15, 0.25 + sin(a * 2.0) * 0.06, sin(a) * 0.15), 6, 4)
		"coin":
			k.cyl(0.16, 0.05, Pal.GOLD, MeshKit.xf(Vector3(0, 0.16, -0.025), Vector3(90, 0, 0)), 18, 0.015)
			k.cyl(0.11, 0.06, Color(1.0, 0.88, 0.4), MeshKit.xf(Vector3(0, 0.16, -0.03), Vector3(90, 0, 0)), 18, 0.01)
		_:
			k.rbox(Vector3(0.3, 0.2, 0.3), 0.05, Pal.PINK, MeshKit.at(0, 0.1, 0))
	return k.commit()


static func _cookie(k: MeshKit, r: float, h: float, t := Transform3D.IDENTITY) -> void:
	k.cyl(r, h, [Pal.COOKIE_DARK, Pal.COOKIE], t, 12, h * 0.45)
	var chips := [Vector2(0.08, 0.04), Vector2(-0.06, 0.09), Vector2(-0.09, -0.05), Vector2(0.03, -0.1), Vector2(0.11, -0.06)]
	for c in chips:
		var cc: Vector2 = c * (r / 0.19)
		k.ellipsoid(Vector3(0.032, 0.024, 0.032) * (r / 0.19), Pal.CHOCO, t * MeshKit.at(cc.x, h - 0.004, cc.y), 5, 3)


## Cookie mesh at any size (used on the oven tray, signs and the truck logo).
static func cookie_into(k: MeshKit, r: float, h: float, t := Transform3D.IDENTITY) -> void:
	_cookie(k, r, h, t)
