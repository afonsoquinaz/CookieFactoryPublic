class_name Items
## Meshes for every carriable item. Each sits on y = 0, fits a ~0.42 m
## footprint and stacks cleanly (height = Defs.item_height(t)).
## Cookies look like their recipe; boxes and gifts carry a sticker in the
## recipe's colour so you can tell them apart in a stack.

static func mesh(t: String) -> Mesh:
	return MeshKit.cached("item_" + t, func(): return _build(t))


static func height(t: String) -> float:
	return Defs.item_height(t)


static func node(t: String) -> MeshInstance3D:
	var mi := Mats.inst(mesh(t))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func _build(t: String) -> Mesh:
	var k := MeshKit.new()
	match Defs.cat(t):
		"cookie":
			cookie_into(k, Defs.recipe_of(t), 0.19, Defs.COOKIE_H)
			return k.commit()
		"box":
			_box(k, Defs.recipe_of(t))
			return k.commit()
		"gift":
			_gift(k, Defs.recipe_of(t))
			return k.commit()
	match t:
		"wheat":
			var gold := Color(0.9, 0.75, 0.44)
			var gold_dk := Color(0.8, 0.63, 0.36)
			for i in 5:
				var a := TAU * i / 5.0
				var o := Vector3(0, 0.1 + sin(a) * 0.045, cos(a) * 0.05)
				k.cyl(0.03, 0.42, gold_dk, MeshKit.xf(o + Vector3(-0.2, 0, 0), Vector3(0, 0, -90 + sin(a) * 6)), 6)
				k.ellipsoid(Vector3(0.09, 0.04, 0.04), gold, MeshKit.xf(o + Vector3(0.27, sin(a) * 0.02, cos(a) * 0.02), Vector3(0, 0, sin(a) * 10)), 6, 4)
			k.cyl(0.085, 0.07, Color(0.88, 0.84, 0.74), MeshKit.xf(Vector3(-0.05, 0.1, 0), Vector3(0, 0, 90)), 12, 0.02)
		"sugar":
			var cane := Color(0.64, 0.72, 0.46)
			var joint := Color(0.5, 0.58, 0.36)
			for o in [Vector3(0, 0.055, -0.07), Vector3(0, 0.055, 0.07), Vector3(0, 0.13, 0)]:
				k.cyl(0.055, 0.46, cane, MeshKit.xf(o + Vector3(-0.23, 0, 0), Vector3(0, 0, -90)), 8)
				for j in 3:
					k.torus(0.055, 0.012, joint, MeshKit.xf(o + Vector3(-0.15 + j * 0.15, 0, 0), Vector3(0, 0, 90)), 8, 3)
				k.cyl(0.045, 0.004, Color(0.95, 0.97, 0.85), MeshKit.xf(o + Vector3(0.231, 0, 0), Vector3(0, 0, -90)), 10)
			k.ellipsoid(Vector3(0.16, 0.012, 0.05), Pal.LEAF, MeshKit.xf(Vector3(-0.28, 0.17, 0.03), Vector3(0, 20, 25)), 8, 4)
			k.cyl(0.13, 0.05, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(0.02, 0.07, 0), Vector3(0, 0, 90)), 12, 0.01)
		"cocoa":
			var pod := Color(0.72, 0.42, 0.24)
			var rib := Color(0.8, 0.52, 0.3)
			k.ellipsoid(Vector3(0.21, 0.1, 0.1), pod, MeshKit.at(0, 0.1, 0), 12, 8)
			for i in 5:
				var a := TAU * i / 5.0 + 0.3
				k.ellipsoid(Vector3(0.2, 0.025, 0.025), rib, MeshKit.xf(Vector3(0, 0.1 + sin(a) * 0.085, cos(a) * 0.085), Vector3(a * 57.3, 0, 0)), 8, 3)
			k.cyl(0.02, 0.06, Pal.LEAF_DARK, MeshKit.xf(Vector3(-0.2, 0.1, 0), Vector3(0, 0, 90)), 6)
		"egg":
			k.rbox(Vector3(0.4, 0.08, 0.4), 0.02, Color(0.72, 0.6, 0.46), MeshKit.at(0, 0.04, 0))
			for x in [-0.095, 0.095]:
				for z in [-0.095, 0.095]:
					k.ellipsoid(Vector3(0.075, 0.1, 0.075), Color(1.0, 0.95, 0.84), MeshKit.at(x, 0.1, z), 10, 7)
		"milk":
			k.rbox(Vector3(0.38, 0.14, 0.38), 0.015, Pal.WOOD, MeshKit.at(0, 0.07, 0))
			for x in [-0.085, 0.085]:
				for z in [-0.085, 0.085]:
					k.cyl(0.06, 0.2, Color(0.95, 0.94, 0.9), MeshKit.at(x, 0.05, z), 10, 0.02, 0.05)
					k.cyl(0.03, 0.06, Color(0.95, 0.94, 0.9), MeshKit.at(x, 0.24, z), 8)
					k.cyl(0.034, 0.025, Pal.SLATE, MeshKit.at(x, 0.29, z), 8)
		"oats":
			# a linen sack, top rolled, oat flakes peeking out
			k.cyl(0.17, 0.2, Color(0.86, 0.8, 0.66), MeshKit.at(0, 0, 0), 12, 0.06, 0.15)
			k.torus(0.15, 0.03, Color(0.8, 0.74, 0.6), MeshKit.at(0, 0.2, 0), 12, 5)
			k.cyl(0.13, 0.02, Color(0.9, 0.82, 0.6), MeshKit.at(0, 0.19, 0), 12)
			for i in 6:
				var a := TAU * i / 6.0
				k.ellipsoid(Vector3(0.03, 0.01, 0.025), Color(0.95, 0.88, 0.68), MeshKit.xf(Vector3(cos(a) * 0.07, 0.215, sin(a) * 0.07), Vector3(0, a * 57.3, 10)), 5, 3)
			k.cyl(0.175, 0.025, Pal.TERRACOTTA, MeshKit.at(0, 0.08, 0), 12)
		"berry":
			# a little woven punnet of strawberries
			k.cyl(0.19, 0.1, Color(0.82, 0.72, 0.52), MeshKit.at(0, 0, 0), 4, 0.02, 0.16)
			for i in 5:
				var a := TAU * i / 5.0 + 0.4
				var p := Vector3(cos(a) * 0.08, 0.13, sin(a) * 0.08)
				k.ellipsoid(Vector3(0.05, 0.06, 0.05), Color(0.84, 0.24, 0.24), MeshKit.xf(p, Vector3(160, 0, 0)), 7, 5)
				k.cone(0.035, 0.03, Pal.LEAF, MeshKit.at(p.x, p.y + 0.045, p.z), 5)
			k.ellipsoid(Vector3(0.05, 0.06, 0.05), Color(0.9, 0.3, 0.28), MeshKit.xf(Vector3(0, 0.17, 0), Vector3(160, 0, 0)), 7, 5)
		"hazelnut":
			k.rbox(Vector3(0.36, 0.05, 0.3), 0.02, Pal.WOOD_LIGHT, MeshKit.at(0, 0.025, 0))
			for p in [Vector3(-0.08, 0.1, -0.04), Vector3(0.07, 0.1, -0.05), Vector3(0.0, 0.1, 0.07), Vector3(0.0, 0.17, 0.0)]:
				k.sphere(0.065, Color(0.6, 0.4, 0.24), MeshKit.at(p.x, p.y, p.z), 8, 6)
				k.cyl(0.045, 0.02, Color(0.82, 0.68, 0.48), MeshKit.at(p.x, p.y + 0.05, p.z), 7)
			k.ellipsoid(Vector3(0.1, 0.012, 0.05), Pal.LEAF, MeshKit.xf(Vector3(0.13, 0.08, 0.08), Vector3(0, 30, 10)), 7, 3)
		"honey":
			k.cyl(0.13, 0.2, Color(0.92, 0.64, 0.2, 0.75), MeshKit.at(0, 0, 0), 12, 0.04)
			k.cyl(0.14, 0.04, Pal.WOOD_LIGHT, MeshKit.at(0, 0.2, 0), 12, 0.01)
			k.cyl(0.08, 0.02, Pal.CREAM, MeshKit.at(0, 0.24, 0), 10)
			k.cyl(0.015, 0.3, Pal.WOOD, MeshKit.xf(Vector3(-0.12, 0.25, 0), Vector3(0, 0, -70)), 5)
			k.sphere(0.035, Pal.WOOD, MeshKit.at(0.15, 0.27, 0), 6, 4)
		"vanilla":
			for i in 5:
				k.cyl(0.018, 0.4, Color(0.3, 0.2, 0.15), MeshKit.xf(Vector3(-0.2, 0.04 + (i % 2) * 0.03, -0.06 + i * 0.03), Vector3(0, 0, -90 + i * 2)), 5)
			k.cyl(0.06, 0.04, Pal.WOOD_LIGHT, MeshKit.xf(Vector3(0, 0.055, 0), Vector3(0, 0, 90)), 8)
			for i in 5:
				var a := TAU * i / 5.0
				k.ellipsoid(Vector3(0.05, 0.01, 0.03), Color(0.96, 0.94, 0.84), MeshKit.xf(Vector3(0.12 + cos(a) * 0.04, 0.11, sin(a) * 0.04), Vector3(0, -a * 57.3, 15)), 5, 3)
			k.sphere(0.02, Color(0.92, 0.8, 0.4), MeshKit.at(0.12, 0.12, 0), 5, 3)
		"cinnamon":
			for i in 5:
				var o := Vector3(0, 0.04 + (i / 3) * 0.06, -0.06 + (i % 3) * 0.06)
				k.cyl(0.03, 0.38, Color(0.62, 0.36, 0.2), MeshKit.xf(o + Vector3(-0.19, 0, 0), Vector3(0, 0, -90)), 7)
				k.cyl(0.018, 0.385, Color(0.46, 0.25, 0.14), MeshKit.xf(o + Vector3(-0.192, 0, 0), Vector3(0, 0, -90)), 6)
			k.cyl(0.11, 0.04, Pal.CREAM, MeshKit.xf(Vector3(0, 0.07, 0), Vector3(0, 0, 90)), 10)
		"orange":
			k.sphere(0.15, Color(0.94, 0.56, 0.2), MeshKit.at(0, 0.15, 0), 12, 8)
			k.cyl(0.015, 0.03, Pal.WOOD_DARK, MeshKit.at(0, 0.29, 0), 5)
			k.ellipsoid(Vector3(0.09, 0.01, 0.04), Pal.LEAF, MeshKit.xf(Vector3(0.06, 0.3, 0), Vector3(0, 20, 20)), 7, 3)
		"butter":
			k.rbox(Vector3(0.38, 0.04, 0.28), 0.015, Pal.WOOD, MeshKit.at(0, 0.02, 0))
			k.rbox(Vector3(0.3, 0.11, 0.17), 0.025, Color(0.98, 0.9, 0.56), MeshKit.at(0, 0.095, 0))
			k.rbox(Vector3(0.12, 0.112, 0.172), 0.02, Color(0.96, 0.95, 0.9), MeshKit.at(-0.08, 0.096, 0))
		"chocolate":
			k.rbox(Vector3(0.36, 0.06, 0.24), 0.015, Color(0.32, 0.19, 0.13), MeshKit.at(0, 0.03, 0))
			for x in 4:
				for z in 2:
					k.rbox(Vector3(0.075, 0.03, 0.095), 0.012, Color(0.38, 0.24, 0.16), MeshKit.at(-0.13 + x * 0.087, 0.07, -0.055 + z * 0.11))
			k.rbox(Vector3(0.36, 0.02, 0.24), 0.01, Pal.BRASS, MeshKit.at(0.05, 0.015, 0))
		"jam":
			k.cyl(0.12, 0.2, Color(0.66, 0.12, 0.18, 0.85), MeshKit.at(0, 0, 0), 12, 0.03)
			k.cyl(0.15, 0.04, Pal.CREAM, MeshKit.at(0, 0.2, 0), 12, 0.02)
			k.torus(0.125, 0.012, Pal.WOOD_LIGHT, MeshKit.at(0, 0.19, 0), 12, 3)
		"caramel":
			for i in 4:
				k.rbox(Vector3(0.13, 0.065, 0.13), 0.025, Color(0.84, 0.54, 0.22), MeshKit.xf(Vector3(-0.07 + (i % 2) * 0.14, 0.035 + (i / 2) * 0.068, -0.03 + (i % 3) * 0.03), Vector3(0, i * 17, 0)))
			k.rbox(Vector3(0.3, 0.012, 0.03), 0.006, Color(0.94, 0.7, 0.36), MeshKit.xf(Vector3(0, 0.145, 0), Vector3(0, 30, 0)))
		"praline":
			for p in [Vector2(-0.08, -0.06), Vector2(0.08, -0.06), Vector2(-0.08, 0.08), Vector2(0.08, 0.08)]:
				k.cyl(0.07, 0.05, Pal.CREAM, MeshKit.at(p.x, 0, p.y), 9, 0.01, 0.06)
				k.sphere(0.06, Color(0.4, 0.25, 0.16), MeshKit.at(p.x, 0.07, p.y), 8, 6)
				k.sphere(0.015, Color(0.8, 0.6, 0.4), MeshKit.at(p.x, 0.125, p.y), 5, 3)
		"candied":
			k.rbox(Vector3(0.38, 0.015, 0.3), 0.005, Color(0.96, 0.94, 0.88), MeshKit.at(0, 0.008, 0))
			for i in 4:
				var z := -0.09 + i * 0.06
				k.rbox(Vector3(0.24, 0.03, 0.04), 0.012, Color(0.95, 0.58, 0.22, 0.85), MeshKit.xf(Vector3(0.03, 0.03, z), Vector3(0, -8 + i * 5, 0)))
				k.rbox(Vector3(0.08, 0.034, 0.044), 0.012, Color(0.3, 0.18, 0.12), MeshKit.xf(Vector3(-0.12, 0.03, z), Vector3(0, -8 + i * 5, 0)))
		"coin":
			k.cyl(0.16, 0.05, Pal.GOLD, MeshKit.xf(Vector3(0, 0.16, -0.025), Vector3(90, 0, 0)), 18, 0.015)
			k.cyl(0.11, 0.06, Color(1.0, 0.88, 0.4), MeshKit.xf(Vector3(0, 0.16, -0.03), Vector3(90, 0, 0)), 18, 0.01)
		_:
			k.rbox(Vector3(0.3, 0.2, 0.3), 0.05, Pal.PINK, MeshKit.at(0, 0.1, 0))
	return k.commit()


## A cookie of recipe `rid` (radius r, height h) into k at t.
static func cookie_into(k: MeshKit, rid: String, r: float, h: float, t := Transform3D.IDENTITY) -> void:
	var look: Dictionary = Defs.COOKIE_LOOK.get(rid, Defs.COOKIE_LOOK["choc"])
	var base: Color = look["base"]
	var top := base.lightened(0.1)
	var side := base.darkened(0.14)
	var s := r / 0.19
	match look["shape"]:
		"square":
			k.rbox(Vector3(r * 1.75, h, r * 1.3), h * 0.4, base, t * MeshKit.at(0, h * 0.5, 0))
		"ring":
			k.torus(r * 0.68, r * 0.32, base, t * MeshKit.at(0, h * 0.55, 0), 14, 6)
			for i in 10:
				var a := TAU * i / 10.0
				k.ellipsoid(Vector3(0.03, 0.02, 0.05) * s, top, t * MeshKit.xf(Vector3(cos(a) * r * 0.68, h * 0.95, sin(a) * r * 0.68), Vector3(0, -a * 57.3, 0)), 5, 3)
		"flat":
			k.cyl(r * 1.05, h * 0.6, [side, top], t, 14, h * 0.25)
		"rustic":
			k.cyl(r, h * 1.1, [side, top], t, 9, h * 0.5)
		_:
			k.cyl(r, h, [side, top], t, 12, h * 0.45)
	var y := h
	match look["deco"]:
		"pricks":
			for i in 6:
				k.sphere(0.012 * s, base.darkened(0.2), t * MeshKit.at(-0.1 * s + (i % 3) * 0.1 * s, y - 0.003, -0.05 * s + (i / 3) * 0.1 * s), 4, 3)
		"sparkle":
			for i in 9:
				var a := TAU * i / 9.0 + 0.3
				var rr := (0.04 + (i % 3) * 0.04) * s
				k.rbox(Vector3(0.025, 0.012, 0.025) * s, 0.005, Color(0.99, 0.97, 0.92), t * MeshKit.xf(Vector3(cos(a) * rr, y, sin(a) * rr), Vector3(0, i * 40, 0)))
		"crinkle":
			for i in 7:
				var a := TAU * i / 7.0 + 0.2
				k.ellipsoid(Vector3(0.05, 0.008, 0.02) * s, Color(0.97, 0.96, 0.94), t * MeshKit.xf(Vector3(cos(a) * 0.09 * s, y, sin(a) * 0.09 * s), Vector3(0, -a * 57.3, 0)), 5, 3)
		"flower":
			for i in 6:
				var a := TAU * i / 6.0
				k.ellipsoid(Vector3(0.035, 0.008, 0.02) * s, base.darkened(0.12), t * MeshKit.xf(Vector3(cos(a) * 0.05 * s, y, sin(a) * 0.05 * s), Vector3(0, -a * 57.3, 0)), 5, 3)
			k.sphere(0.02 * s, base.darkened(0.18), t * MeshKit.at(0, y, 0), 5, 3)
		"chips", "white_chips":
			var chip := Pal.CHOCO if look["deco"] == "chips" else Color(0.96, 0.93, 0.86)
			for c in [Vector2(0.08, 0.04), Vector2(-0.06, 0.09), Vector2(-0.09, -0.05), Vector2(0.03, -0.1), Vector2(0.11, -0.06), Vector2(-0.01, 0.01)]:
				k.ellipsoid(Vector3(0.032, 0.024, 0.032) * s, chip, t * MeshKit.at(c.x * s, y - 0.004, c.y * s), 5, 3)
		"oats":
			for i in 8:
				var a := TAU * i / 8.0 + 0.5
				k.ellipsoid(Vector3(0.03, 0.01, 0.02) * s, Color(0.94, 0.87, 0.68), t * MeshKit.xf(Vector3(cos(a) * 0.1 * s, y + 0.004, sin(a) * 0.09 * s), Vector3(0, a * 70, 0)), 4, 3)
		"jam":
			k.cyl(0.07 * s, 0.025, Color(0.72, 0.12, 0.18), t * MeshKit.at(0, y - 0.01, 0), 10, 0.01)
		"nuts":
			for c in [Vector2(0.06, 0.03), Vector2(-0.07, 0.06), Vector2(-0.04, -0.07), Vector2(0.07, -0.06)]:
				k.sphere(0.03 * s, Color(0.62, 0.42, 0.24), t * MeshKit.at(c.x * s, y + 0.01, c.y * s), 5, 4)
			k.rbox(Vector3(0.28, 0.01, 0.02) * s, 0.005, Pal.CHOCO, t * MeshKit.xf(Vector3(0, y + 0.006, 0), Vector3(0, 30, 0)))
		"glaze":
			k.cyl(r * 0.85, 0.012, Color(0.95, 0.7, 0.28, 0.85), t * MeshKit.at(0, y - 0.002, 0), 12)
		"waffle":
			for i in 4:
				k.rbox(Vector3(r * 1.8, 0.01, 0.012), 0.004, side, t * MeshKit.xf(Vector3(0, h * 0.6, -0.09 * s + i * 0.06 * s), Vector3(0, 45, 0)))
				k.rbox(Vector3(r * 1.8, 0.01, 0.012), 0.004, side, t * MeshKit.xf(Vector3(0, h * 0.6, -0.09 * s + i * 0.06 * s), Vector3(0, -45, 0)))
		"specks":
			for i in 10:
				var a := TAU * i / 10.0 + 0.7
				k.sphere(0.008 * s, Color(0.2, 0.14, 0.1), t * MeshKit.at(cos(a) * (0.03 + (i % 3) * 0.04) * s, y, sin(a) * (0.03 + (i % 3) * 0.04) * s), 3, 2)
			k.torus(r * 0.93, 0.012, Color(0.99, 0.97, 0.9), t * MeshKit.at(0, y - 0.01, 0), 14, 3)
		"swirl":
			k.cyl(0.08 * s, 0.03, Color(0.36, 0.22, 0.14), t * MeshKit.at(0, y, 0), 10, 0.015, 0.03 * s)
			k.sphere(0.03 * s, Color(0.62, 0.42, 0.24), t * MeshKit.at(0, y + 0.04, 0), 6, 4)
		"spiral":
			for i in 14:
				var a := i * 0.9
				var rr := (0.02 + i * 0.008) * s
				k.sphere(0.012 * s, Color(0.55, 0.3, 0.16), t * MeshKit.at(cos(a) * rr, y, sin(a) * rr), 4, 3)
			k.rbox(Vector3(0.26, 0.01, 0.015) * s, 0.005, Color(0.98, 0.97, 0.94), t * MeshKit.xf(Vector3(0, y + 0.008, 0.02), Vector3(0, 20, 0)))
		"lace":
			for i in 5:
				var a := TAU * i / 5.0
				k.rbox(Vector3(0.05, 0.012, 0.025) * s, 0.008, Color(0.96, 0.6, 0.24), t * MeshKit.xf(Vector3(cos(a) * 0.09 * s, y - 0.01, sin(a) * 0.09 * s), Vector3(0, a * 57.3, 0)))
			k.cyl(r * 1.0, 0.012, Pal.CHOCO, t * MeshKit.at(0, -0.004, 0), 14)
		"royal":
			k.cyl(r * 0.88, 0.016, Color(0.99, 0.98, 0.95), t * MeshKit.at(0, y - 0.004, 0), 14)
			for i in 3:
				k.cone(0.02 * s, 0.05 * s, Pal.BRASS, t * MeshKit.at((i - 1) * 0.045 * s, y + 0.012, 0), 5)
			k.rbox(Vector3(0.14, 0.012, 0.025) * s, 0.006, Pal.BRASS, t * MeshKit.at(0, y + 0.012, 0.02 * s))
			k.torus(r * 0.9, 0.01, Pal.BRASS, t * MeshKit.at(0, y + 0.004, 0), 14, 3)


static func _box(k: MeshKit, rid: String) -> void:
	var kraft := Color(0.78, 0.62, 0.44)
	var look: Dictionary = Defs.COOKIE_LOOK.get(rid, Defs.COOKIE_LOOK["choc"])
	k.rbox(Vector3(0.4, 0.24, 0.34), 0.025, kraft, MeshKit.at(0, 0.12, 0))
	k.rbox(Vector3(0.41, 0.03, 0.35), 0.012, kraft.darkened(0.1), MeshKit.at(0, 0.23, 0))
	# twine + a round sticker showing the cookie inside
	k.rbox(Vector3(0.412, 0.012, 0.03), 0.004, Pal.CREAM, MeshKit.at(0, 0.245, 0))
	k.rbox(Vector3(0.03, 0.012, 0.352), 0.004, Pal.CREAM, MeshKit.at(0, 0.245, 0))
	cookie_into(k, rid, 0.085, 0.03, MeshKit.at(0.0, 0.25, 0.0))
	k.cyl(0.07, 0.01, look["base"], MeshKit.xf(Vector3(0.0, 0.12, 0.172), Vector3(90, 0, 0)), 12)
	k.cyl(0.075, 0.008, Pal.CREAM, MeshKit.xf(Vector3(0.0, 0.12, 0.171), Vector3(90, 0, 0)), 12)


static func _gift(k: MeshKit, rid: String) -> void:
	var look: Dictionary = Defs.COOKIE_LOOK.get(rid, Defs.COOKIE_LOOK["choc"])
	var paper := Color(0.95, 0.92, 0.86)
	var ribbon := Pal.TERRACOTTA
	k.rbox(Vector3(0.38, 0.26, 0.36), 0.03, paper, MeshKit.at(0, 0.13, 0))
	k.rbox(Vector3(0.4, 0.06, 0.38), 0.02, paper.darkened(0.04), MeshKit.at(0, 0.25, 0))
	k.rbox(Vector3(0.405, 0.27, 0.06), 0.01, ribbon, MeshKit.at(0, 0.14, 0))
	k.rbox(Vector3(0.06, 0.27, 0.385), 0.01, ribbon, MeshKit.at(0, 0.14, 0))
	for sx in [-1.0, 1.0]:
		k.ellipsoid(Vector3(0.08, 0.045, 0.04), ribbon, MeshKit.xf(Vector3(sx * 0.07, 0.3, 0), Vector3(0, 0, sx * 25)), 8, 5)
	k.sphere(0.035, ribbon.darkened(0.1), MeshKit.at(0, 0.3, 0), 6, 4)
	k.cyl(0.05, 0.01, look["base"], MeshKit.xf(Vector3(0.11, 0.13, 0.182), Vector3(90, 0, 0)), 10)
