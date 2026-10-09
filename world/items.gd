class_name Items
## Meshes for every carriable item. Each sits on y = 0, fits a ~0.42 m
## footprint and stacks cleanly (height = Defs.ITEMS[t].h).

static func mesh(t: String) -> Mesh:
	if t == "cookie":
		var tier := cookie_tier()
		return MeshKit.cached("item_cookie_%d" % tier, func(): return _cookie_mesh(tier))
	return MeshKit.cached("item_" + t, func(): return _build(t))


## Cookies follow the recipe: plain shortbread, sugar cookie, chocolate
## chip, butter chocolate chip, premium (with a chocolate drizzle).
static func cookie_tier() -> int:
	return Game.cookie_grade()


static func _cookie_mesh(tier: int) -> Mesh:
	var k := MeshKit.new()
	var r := 0.19
	var h := 0.085
	match tier:
		0:
			# pale shortbread with a ring of fork pricks
			k.cyl(r, h, [Color(0.86, 0.72, 0.5), Color(0.94, 0.84, 0.64)], Transform3D.IDENTITY, 12, h * 0.45)
			for i in 6:
				var a := TAU * i / 6.0
				k.sphere(0.012, Color(0.78, 0.63, 0.42), MeshKit.at(cos(a) * 0.09, h - 0.003, sin(a) * 0.09), 4, 3)
		1:
			# golden sugar cookie with a crackled sugar top
			k.cyl(r, h, [Color(0.82, 0.62, 0.38), Color(0.92, 0.76, 0.5)], Transform3D.IDENTITY, 12, h * 0.45)
			for i in 9:
				var a2 := TAU * i / 9.0 + 0.3
				var rr := 0.04 + (i % 3) * 0.04
				k.rbox(Vector3(0.025, 0.012, 0.025), 0.005, Color(0.98, 0.96, 0.9), MeshKit.xf(Vector3(cos(a2) * rr, h, sin(a2) * rr), Vector3(0, i * 40, 0)))
		2:
			_cookie(k, r, h)
		3:
			# richer, browner butter cookie, more chips
			k.cyl(r, h, [Color(0.66, 0.44, 0.24), Color(0.8, 0.58, 0.32)], Transform3D.IDENTITY, 12, h * 0.45)
			for c in [Vector2(0.08, 0.04), Vector2(-0.06, 0.09), Vector2(-0.09, -0.05), Vector2(0.03, -0.1), Vector2(0.11, -0.06), Vector2(-0.01, 0.02), Vector2(0.05, 0.11)]:
				k.ellipsoid(Vector3(0.032, 0.024, 0.032), Pal.CHOCO, MeshKit.at(c.x, h - 0.004, c.y), 5, 3)
		_:
			# premium: chocolate chips + a dark drizzle across the top
			_cookie(k, r, h)
			for i in 3:
				k.rbox(Vector3(0.3, 0.012, 0.022), 0.008, Pal.CHOCO_DARK, MeshKit.xf(Vector3(0, h + 0.008, -0.07 + i * 0.07), Vector3(0, 25 - i * 12, 0)))
	return k.commit()


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
			var gold := Color(0.9, 0.75, 0.44)
			var gold_dk := Color(0.8, 0.63, 0.36)
			for i in 5:
				var a := TAU * i / 5.0
				var o := Vector3(0, 0.1 + sin(a) * 0.045, cos(a) * 0.05)
				k.cyl(0.03, 0.42, gold_dk, MeshKit.xf(o + Vector3(-0.2, 0, 0), Vector3(0, 0, -90 + sin(a) * 6)), 6)
				k.ellipsoid(Vector3(0.09, 0.04, 0.04), gold, MeshKit.xf(o + Vector3(0.27, sin(a) * 0.02, cos(a) * 0.02), Vector3(0, 0, sin(a) * 10)), 6, 4)
			k.cyl(0.085, 0.07, Color(0.88, 0.84, 0.74), MeshKit.xf(Vector3(-0.05, 0.1, 0), Vector3(0, 0, 90)), 12, 0.02)
		"sugar":
			# three cut canes with joints, tied, a few leaves
			var cane := Color(0.64, 0.72, 0.46)
			var joint := Color(0.5, 0.58, 0.36)
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
			var pod := Color(0.72, 0.42, 0.24)
			var rib := Color(0.8, 0.52, 0.3)
			k.ellipsoid(Vector3(0.21, 0.1, 0.1), pod, MeshKit.at(0, 0.1, 0), 12, 8)
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				k.ellipsoid(Vector3(0.2, 0.025, 0.025), rib, MeshKit.xf(Vector3(0, 0.1 + sin(a) * 0.085, cos(a) * 0.085), Vector3(a * 57.3, 0, 0)), 8, 3)
			k.cyl(0.02, 0.06, Pal.LEAF_DARK, MeshKit.xf(Vector3(-0.2, 0.1, 0), Vector3(0, 0, 90)), 6)
		"egg":
			# a little tray with four eggs
			k.rbox(Vector3(0.4, 0.08, 0.4), 0.02, Color(0.72, 0.6, 0.46), MeshKit.at(0, 0.04, 0))
			for x in [-0.095, 0.095]:
				for z in [-0.095, 0.095]:
					k.ellipsoid(Vector3(0.075, 0.1, 0.075), Color(1.0, 0.95, 0.84), MeshKit.at(x, 0.1, z), 10, 7)
		"milk":
			# a small crate with four milk bottles
			k.rbox(Vector3(0.38, 0.14, 0.38), 0.015, Pal.WOOD, MeshKit.at(0, 0.07, 0))
			for x in [-0.085, 0.085]:
				for z in [-0.085, 0.085]:
					k.cyl(0.06, 0.2, Color(0.95, 0.94, 0.9), MeshKit.at(x, 0.05, z), 10, 0.02, 0.05)
					k.cyl(0.03, 0.06, Color(0.95, 0.94, 0.9), MeshKit.at(x, 0.24, z), 8)
					k.cyl(0.034, 0.025, Pal.SLATE, MeshKit.at(x, 0.29, z), 8)
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
