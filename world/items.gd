class_name Items
## Meshes for every carriable item. Each sits on y = 0, fits a ~0.42 m
## footprint and stacks cleanly (height = Defs.item_height(t)).
## Tokens are glowing coins in their model's colour with its glyph on the
## face; batches are cases and agent runs little robot parcels, each with a
## sticker in the model's colour so you can tell them apart in a stack.
## A colour with alpha < 1 glows (LEDs, screens, data).

static func mesh(t: String) -> Mesh:
	return MeshKit.cached("item_" + t, func(): return _build(t))


static func height(t: String) -> float:
	return Defs.item_height(t)


static func node(t: String) -> MeshInstance3D:
	var mi := Mats.inst(mesh(t))
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## A glowing version of a colour (alpha < 1 marks glow in the toon shader).
static func lit(c: Color, a := 0.55) -> Color:
	return Color(c.r, c.g, c.b, a)


static func _build(t: String) -> Mesh:
	var k := MeshKit.new()
	match Defs.cat(t):
		"token":
			token_into(k, Defs.recipe_of(t), 0.19, Defs.TOKEN_H)
			return k.commit()
		"batch":
			_batch(k, Defs.recipe_of(t))
			return k.commit()
		"agent":
			_agent(k, Defs.recipe_of(t))
			return k.commit()
	resource_into(k, t)
	return k.commit()


## The mesh of a resource into k at t (also used for silo signs and props).
static func resource_into(k: MeshKit, t: String, x := Transform3D.IDENTITY) -> void:
	match t:
		"power":
			# a chunky battery cell with a glowing charge window
			k.rbox(Vector3(0.3, 0.2, 0.22), 0.05, Color(0.2, 0.24, 0.26), x * MeshKit.at(0, 0.1, 0))
			k.rbox(Vector3(0.26, 0.12, 0.012), 0.02, lit(Color(0.48, 0.92, 0.56)), x * MeshKit.at(-0.0, 0.1, 0.112))
			for i in 3:
				k.rbox(Vector3(0.05, 0.08, 0.014), 0.01, Color(0.2, 0.24, 0.26), x * MeshKit.at(-0.06 + i * 0.06, 0.1, 0.116))
			k.rbox(Vector3(0.08, 0.04, 0.08), 0.015, Pal.BRASS, x * MeshKit.at(0.08, 0.21, 0))
			k.rbox(Vector3(0.08, 0.04, 0.08), 0.015, Color(0.82, 0.3, 0.28), x * MeshKit.at(-0.08, 0.21, 0))
		"data":
			# a translucent data cube on a dark base, lines of light inside
			k.rbox(Vector3(0.32, 0.04, 0.32), 0.015, Color(0.18, 0.22, 0.28), x * MeshKit.at(0, 0.02, 0))
			k.rbox(Vector3(0.26, 0.16, 0.26), 0.04, lit(Color(0.38, 0.76, 0.96), 0.7), x * MeshKit.at(0, 0.12, 0))
			for i in 3:
				k.rbox(Vector3(0.27, 0.012, 0.03), 0.004, lit(Color(0.86, 0.97, 1.0), 0.4), x * MeshKit.at(0, 0.07 + i * 0.045, -0.06 + i * 0.06))
		"coolant":
			# a blue jerrycan with a white cap and a snowflake band
			k.rbox(Vector3(0.26, 0.24, 0.16), 0.05, Color(0.36, 0.6, 0.86), x * MeshKit.at(0, 0.12, 0))
			k.rbox(Vector3(0.27, 0.05, 0.17), 0.02, Color(0.92, 0.95, 0.98), x * MeshKit.at(0, 0.12, 0))
			k.rbox(Vector3(0.1, 0.035, 0.08), 0.015, Color(0.3, 0.5, 0.74), x * MeshKit.at(-0.06, 0.255, 0))
			k.cyl(0.035, 0.04, Color(0.95, 0.96, 0.98), x * MeshKit.at(0.08, 0.24, 0), 8)
		"silicon":
			# a silicon boule lying in a cradle
			k.rbox(Vector3(0.36, 0.05, 0.2), 0.02, Pal.WOOD_LIGHT, x * MeshKit.at(0, 0.025, 0))
			k.cyl(0.08, 0.34, Color(0.6, 0.64, 0.7), x * MeshKit.xf(Vector3(-0.17, 0.12, 0), Vector3(0, 0, -90)), 12, 0.03)
			k.cone(0.08, 0.06, Color(0.55, 0.58, 0.64), x * MeshKit.xf(Vector3(0.17, 0.12, 0), Vector3(0, 0, -90)), 12)
			k.ellipsoid(Vector3(0.1, 0.012, 0.03), Color(0.84, 0.88, 0.94), x * MeshKit.at(-0.02, 0.198, 0.02), 8, 3)
		"copper":
			# three copper bars and a coil of wire
			for i in 3:
				k.rbox(Vector3(0.32, 0.05, 0.08), 0.015, Color(0.82, 0.48, 0.28).lightened(0.05 * (i % 2)), x * MeshKit.at(0, 0.025, -0.09 + i * 0.09))
			k.torus(0.08, 0.025, Color(0.9, 0.58, 0.34), x * MeshKit.at(0.06, 0.08, 0), 14, 6)
			k.torus(0.08, 0.025, Color(0.84, 0.52, 0.3), x * MeshKit.at(0.06, 0.12, 0), 14, 6)
		"code":
			# a slim dark slab like an editor window, coloured lines of code
			k.rbox(Vector3(0.36, 0.06, 0.28), 0.02, Color(0.16, 0.16, 0.22), x * MeshKit.at(0, 0.03, 0))
			var cols := [Color(0.6, 0.5, 0.95), Color(0.46, 0.84, 0.66), Color(0.96, 0.7, 0.4), Color(0.5, 0.74, 0.96)]
			for i in 5:
				var w: float = [0.18, 0.24, 0.12, 0.2, 0.1][i]
				k.rbox(Vector3(w, 0.012, 0.025), 0.005, lit(cols[i % 4], 0.5), x * MeshKit.at(-0.13 + w * 0.5 + (i % 2) * 0.03, 0.065, -0.1 + i * 0.05))
			k.rbox(Vector3(0.36, 0.035, 0.03), 0.01, Color(0.5, 0.42, 0.78), x * MeshKit.at(0, 0.075, -0.13))
		"labels":
			# a stack of index cards with coloured tags and a tick
			for i in 3:
				k.rbox(Vector3(0.32, 0.03, 0.22), 0.01, Color(0.97, 0.96, 0.92), x * MeshKit.xf(Vector3(0, 0.02 + i * 0.035, 0), Vector3(0, -6 + i * 6, 0)))
				k.rbox(Vector3(0.06, 0.032, 0.05), 0.008, [Color(0.96, 0.74, 0.3), Color(0.5, 0.72, 0.94), Color(0.92, 0.48, 0.5)][i], x * MeshKit.xf(Vector3(0.13, 0.025 + i * 0.035, -0.07), Vector3(0, -6 + i * 6, 0)))
			k.rbox(Vector3(0.05, 0.015, 0.02), 0.005, Color(0.3, 0.66, 0.42), x * MeshKit.xf(Vector3(-0.06, 0.13, 0.02), Vector3(0, 0, 0)) * MeshKit.xf(Vector3.ZERO, Vector3(0, 40, 0)))
			k.rbox(Vector3(0.1, 0.015, 0.02), 0.005, Color(0.3, 0.66, 0.42), x * MeshKit.xf(Vector3(-0.0, 0.13, 0.0), Vector3(0, -50, 0)))
		"feedback":
			# a pair of speech bubbles: a thumbs-up and a star
			k.rbox(Vector3(0.22, 0.16, 0.1), 0.06, Color(0.98, 0.95, 0.92), x * MeshKit.at(-0.06, 0.1, 0.02))
			k.cone(0.05, 0.07, Color(0.98, 0.95, 0.92), x * MeshKit.xf(Vector3(-0.12, 0.02, 0.02), Vector3(0, 0, 160)), 5)
			k.rbox(Vector3(0.05, 0.08, 0.02), 0.02, Color(0.94, 0.52, 0.56), x * MeshKit.at(-0.08, 0.1, 0.075))
			k.rbox(Vector3(0.04, 0.04, 0.02), 0.015, Color(0.94, 0.52, 0.56), x * MeshKit.at(-0.04, 0.08, 0.075))
			k.rbox(Vector3(0.16, 0.13, 0.1), 0.05, Color(0.94, 0.52, 0.56), x * MeshKit.at(0.1, 0.12, -0.06))
			k.star(0.045, 0.02, 5, 0.02, Color(1.0, 0.92, 0.6), x * MeshKit.xf(Vector3(0.1, 0.12, -0.005), Vector3(90, 0, 0)))
		"rare":
			# a little crate of glittering crystals
			k.rbox(Vector3(0.34, 0.1, 0.28), 0.02, Pal.WOOD, x * MeshKit.at(0, 0.05, 0))
			var cs := [Color(0.76, 0.48, 0.86), Color(0.5, 0.82, 0.78), Color(0.94, 0.56, 0.72), Color(0.66, 0.42, 0.9)]
			for i in 5:
				var p := Vector3(-0.1 + (i % 3) * 0.1, 0.08, -0.05 + (i / 3) * 0.1)
				k.cone(0.045, 0.12 + (i % 2) * 0.04, lit(cs[i % 4], 0.75), x * MeshKit.xf(p, Vector3((i - 2) * 9, i * 30, (i % 2) * 14)), 6)
		"papers":
			# a stack of papers with a glowing idea bulb on top
			for i in 3:
				k.rbox(Vector3(0.3, 0.025, 0.24), 0.008, Color(0.97, 0.96, 0.92).darkened(0.03 * i), x * MeshKit.xf(Vector3(0, 0.015 + i * 0.028, 0), Vector3(0, i * 5 - 4, 0)))
			for i in 3:
				k.rbox(Vector3(0.2 - i * 0.04, 0.004, 0.012), 0.002, Color(0.5, 0.5, 0.56), x * MeshKit.at(-0.02, 0.098, -0.06 + i * 0.03))
			k.sphere(0.045, lit(Color(1.0, 0.86, 0.4), 0.5), x * MeshKit.at(0.08, 0.15, 0.04), 8, 6)
			k.cyl(0.022, 0.03, Pal.STEEL, x * MeshKit.at(0.08, 0.1, 0.04), 6)
		"fiber":
			# a spool of glowing fibre-optic cable
			k.cyl(0.15, 0.025, Color(0.32, 0.34, 0.4), x * MeshKit.at(0, 0, 0), 14)
			k.cyl(0.15, 0.025, Color(0.32, 0.34, 0.4), x * MeshKit.at(0, 0.175, 0), 14)
			k.cyl(0.11, 0.15, lit(Color(0.98, 0.62, 0.86), 0.6), x * MeshKit.at(0, 0.025, 0), 14)
			k.cyl(0.04, 0.2, Pal.STEEL, x * MeshKit.at(0, 0, 0), 8)
		"experts":
			# a gold-edged book with a mortarboard
			k.rbox(Vector3(0.32, 0.08, 0.24), 0.02, Color(0.36, 0.22, 0.42), x * MeshKit.at(0, 0.04, 0))
			k.rbox(Vector3(0.3, 0.06, 0.22), 0.01, Color(0.96, 0.92, 0.82), x * MeshKit.at(0.01, 0.04, 0))
			k.rbox(Vector3(0.33, 0.012, 0.25), 0.005, Pal.BRASS, x * MeshKit.at(0, 0.081, 0))
			k.cyl(0.06, 0.04, Color(0.16, 0.16, 0.2), x * MeshKit.at(0, 0.09, 0), 10)
			k.rbox(Vector3(0.2, 0.015, 0.2), 0.005, Color(0.16, 0.16, 0.2), x * MeshKit.xf(Vector3(0, 0.14, 0), Vector3(0, 45, 0)))
			k.cyl(0.006, 0.06, Pal.BRASS, x * MeshKit.at(0.08, 0.09, 0.03), 4)
		"gpu":
			# a graphics card: green board, black shroud, two fans
			k.rbox(Vector3(0.38, 0.03, 0.2), 0.008, Color(0.2, 0.46, 0.3), x * MeshKit.at(0, 0.015, 0))
			k.rbox(Vector3(0.36, 0.08, 0.18), 0.025, Color(0.16, 0.17, 0.19), x * MeshKit.at(0, 0.07, 0))
			for sx in [-0.09, 0.09]:
				k.cyl(0.07, 0.012, Color(0.3, 0.32, 0.36), x * MeshKit.at(sx, 0.11, 0), 14)
				k.cyl(0.025, 0.016, Color(0.6, 0.62, 0.66), x * MeshKit.at(sx, 0.11, 0), 8)
			k.rbox(Vector3(0.3, 0.012, 0.01), 0.004, lit(Color(0.46, 0.92, 0.56), 0.4), x * MeshKit.at(0, 0.07, 0.092))
			k.rbox(Vector3(0.02, 0.06, 0.2), 0.005, Pal.STEEL, x * MeshKit.at(-0.19, 0.06, 0))
		"dataset":
			# the classic database: three stacked glowing discs
			for i in 3:
				k.cyl(0.13, 0.065, Color(0.24, 0.5, 0.78), x * MeshKit.at(0, 0.005 + i * 0.078, 0), 16, 0.02)
				k.torus(0.13, 0.008, lit(Color(0.6, 0.86, 1.0), 0.5), x * MeshKit.at(0, 0.07 + i * 0.078, 0), 16, 4)
		"finetune":
			# a cartridge with a tuning dial
			k.rbox(Vector3(0.3, 0.1, 0.22), 0.03, Color(0.96, 0.62, 0.32), x * MeshKit.at(0, 0.05, 0))
			k.rbox(Vector3(0.22, 0.02, 0.14), 0.01, Color(0.98, 0.95, 0.9), x * MeshKit.at(-0.02, 0.105, 0))
			k.cyl(0.04, 0.04, Color(0.24, 0.24, 0.28), x * MeshKit.at(0.1, 0.1, 0.05), 10)
			k.rbox(Vector3(0.01, 0.01, 0.03), 0.003, lit(Color(1, 1, 1), 0.5), x * MeshKit.at(0.1, 0.142, 0.06))
			for i in 4:
				k.rbox(Vector3(0.03, 0.03, 0.012), 0.004, Pal.BRASS, x * MeshKit.at(-0.11 + i * 0.05, 0.03, -0.112))
		"hbm":
			# a memory stick: blue board, black chips, gold pins
			k.rbox(Vector3(0.38, 0.03, 0.12), 0.008, Color(0.22, 0.34, 0.56), x * MeshKit.at(0, 0.015, 0))
			for i in 4:
				k.rbox(Vector3(0.07, 0.03, 0.08), 0.008, Color(0.14, 0.14, 0.16), x * MeshKit.at(-0.13 + i * 0.087, 0.045, 0))
			k.rbox(Vector3(0.36, 0.012, 0.02), 0.003, Pal.BRASS, x * MeshKit.at(0, 0.03, 0.065))
			k.rbox(Vector3(0.05, 0.006, 0.006), 0.002, lit(Color(0.5, 0.8, 1.0), 0.4), x * MeshKit.at(0.16, 0.034, -0.05))
		"reward":
			# a golden star trophy on a plinth
			k.rbox(Vector3(0.22, 0.05, 0.18), 0.015, Color(0.22, 0.2, 0.24), x * MeshKit.at(0, 0.025, 0))
			k.cyl(0.03, 0.05, Pal.BRASS, x * MeshKit.at(0, 0.05, 0), 8)
			k.star(0.1, 0.045, 5, 0.04, Color(0.96, 0.78, 0.32), x * MeshKit.xf(Vector3(0, 0.12, -0.02), Vector3(90, 0, 0)))
		"synth":
			# a glowing violet cube held in a steel cage
			k.rbox(Vector3(0.2, 0.18, 0.2), 0.04, lit(Color(0.7, 0.46, 0.96), 0.55), x * MeshKit.at(0, 0.11, 0))
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.rbox(Vector3(0.025, 0.22, 0.025), 0.008, Pal.STEEL, x * MeshKit.at(sx * 0.12, 0.11, sz * 0.12))
			k.rbox(Vector3(0.27, 0.025, 0.27), 0.01, Pal.STEEL_DARK, x * MeshKit.at(0, 0.0125, 0))
			k.rbox(Vector3(0.27, 0.025, 0.27), 0.01, Pal.STEEL_DARK, x * MeshKit.at(0, 0.21, 0))
		"coin":
			k.cyl(0.16, 0.05, Pal.GOLD, x * MeshKit.xf(Vector3(0, 0.16, -0.025), Vector3(90, 0, 0)), 18, 0.015)
			k.cyl(0.11, 0.06, Color(1.0, 0.88, 0.4), x * MeshKit.xf(Vector3(0, 0.16, -0.03), Vector3(90, 0, 0)), 18, 0.01)
		_:
			k.rbox(Vector3(0.3, 0.2, 0.3), 0.05, Pal.PINK, x * MeshKit.at(0, 0.1, 0))


## A token of model `rid` (radius r, height h) into k at t: a coin in the
## model's colour with a glowing rim and its glyph on the face.
static func token_into(k: MeshKit, rid: String, r: float, h: float, t := Transform3D.IDENTITY) -> void:
	var look: Dictionary = Defs.MODEL_LOOK.get(rid, Defs.MODEL_LOOK["pico"])
	var base: Color = look["base"]
	var side := base.darkened(0.25)
	var face := base.lightened(0.08)
	var s := r / 0.19
	match look["shape"]:
		"hex":
			k.cyl(r, h, [side, face], t, 6, h * 0.3)
		"square":
			k.rbox(Vector3(r * 1.7, h, r * 1.7), h * 0.4, base, t * MeshKit.at(0, h * 0.5, 0))
		"wide":
			k.rbox(Vector3(r * 2.0, h, r * 1.3), h * 0.45, base, t * MeshKit.at(0, h * 0.5, 0))
		"star":
			k.star(r * 1.08, r * 0.72, 8, h, base, t)
		_:
			k.cyl(r, h, [side, face], t, 14, h * 0.4)
	# glowing inset ring
	if look["shape"] in ["round", "hex"]:
		k.torus(r * 0.78, 0.012 * s, lit(base.lightened(0.4), 0.45), t * MeshKit.at(0, h, 0), 6 if look["shape"] == "hex" else 14, 3)
	var y := h + 0.004
	var g := Color(0.99, 0.99, 1.0, 0.6)
	var dk := base.darkened(0.45)
	match look["glyph"]:
		"dot":
			k.cyl(0.04 * s, 0.012, g, t * MeshKit.at(0, y - 0.006, 0), 10)
		"dots":
			for i in 3:
				k.cyl(0.025 * s, 0.012, g, t * MeshKit.at((i - 1) * 0.06 * s, y - 0.006, 0), 8)
		"bubble", "bubble2":
			k.rbox(Vector3(0.16, 0.012, 0.11) * s, 0.04 * s, g, t * MeshKit.at(0, y, -0.01 * s))
			k.cone(0.03 * s, 0.012, g, t * MeshKit.xf(Vector3(-0.05 * s, y, 0.06 * s), Vector3(0, 0, 0)), 4)
			if look["glyph"] == "bubble2":
				for i in 3:
					k.cyl(0.012 * s, 0.014, dk, t * MeshKit.at((i - 1) * 0.04 * s, y + 0.002, -0.01 * s), 6)
		"book":
			for sd in [-1.0, 1.0]:
				k.rbox(Vector3(0.07, 0.012, 0.1) * s, 0.01 * s, Color(0.3, 0.46, 0.72, 0.7), t * MeshKit.xf(Vector3(sd * 0.04 * s, y, 0), Vector3(0, 0, sd * 8)))
		"brackets", "brackets2":
			for sd in [-1.0, 1.0]:
				k.rbox(Vector3(0.018, 0.012, 0.13) * s, 0.006, g, t * MeshKit.at(sd * 0.07 * s, y, 0))
				k.rbox(Vector3(0.04, 0.012, 0.018) * s, 0.006, g, t * MeshKit.at(sd * 0.055 * s, y, -0.056 * s))
				k.rbox(Vector3(0.04, 0.012, 0.018) * s, 0.006, g, t * MeshKit.at(sd * 0.055 * s, y, 0.056 * s))
			if look["glyph"] == "brackets2":
				k.rbox(Vector3(0.018, 0.012, 0.12) * s, 0.006, g, t * MeshKit.xf(Vector3(0, y, 0), Vector3(0, 25, 0)))
		"gear":
			k.star(0.08 * s, 0.06 * s, 8, 0.012, g, t * MeshKit.at(0, y - 0.006, 0))
			k.cyl(0.025 * s, 0.016, dk, t * MeshKit.at(0, y - 0.004, 0), 8)
		"eye":
			k.ellipsoid(Vector3(0.09, 0.008, 0.05) * s, g, t * MeshKit.at(0, y, 0), 12, 3)
			k.cyl(0.03 * s, 0.014, dk, t * MeshKit.at(0, y, 0), 10)
		"star":
			k.star(0.08 * s, 0.035 * s, 5, 0.012, g, t * MeshKit.at(0, y - 0.006, 0))
		"heart":
			for sd in [-1.0, 1.0]:
				k.cyl(0.035 * s, 0.012, g, t * MeshKit.at(sd * 0.03 * s, y - 0.006, -0.02 * s), 10)
			k.prism(_poly([Vector2(-0.062, -0.01), Vector2(0.062, -0.01), Vector2(0, 0.07)], s), 0.012, g, t * MeshKit.at(0, y - 0.006, 0))
		"wave":
			for i in 5:
				k.rbox(Vector3(0.03, 0.012, 0.02 + absf(sin(i * 1.1)) * 0.09) * s, 0.008, g, t * MeshKit.at((i - 2) * 0.045 * s, y, 0))
		"steps":
			for i in 3:
				k.rbox(Vector3(0.04, 0.012 + i * 0.012, 0.04) * s, 0.008, g, t * MeshKit.at((i - 1) * 0.05 * s, y + i * 0.006, (1 - i) * 0.04 * s))
		"medal":
			k.cyl(0.055 * s, 0.014, Color(1.0, 0.95, 0.78, 0.6), t * MeshKit.at(0, y - 0.006, 0.01 * s), 12)
			k.star(0.035 * s, 0.016 * s, 5, 0.016, dk, t * MeshKit.at(0, y - 0.004, 0.01 * s))
		"prism":
			k.prism(_poly([Vector2(-0.07, 0.05), Vector2(0.07, 0.05), Vector2(0, -0.07)], s), 0.012, g, t * MeshKit.at(0, y - 0.006, 0))
			for i in 3:
				k.rbox(Vector3(0.05, 0.012, 0.012) * s, 0.004, [Color(1, 0.5, 0.5, 0.5), Color(0.5, 1, 0.6, 0.5), Color(0.5, 0.7, 1, 0.5)][i], t * MeshKit.xf(Vector3(0.08 * s, y, (i - 1) * 0.02 * s), Vector3(0, -10 + i * 10, 0)))
		"cubes":
			for p in [Vector2(-0.04, -0.03), Vector2(0.04, -0.03), Vector2(0, 0.04)]:
				k.rbox(Vector3(0.05, 0.03, 0.05) * s, 0.01, g, t * MeshKit.at(p.x * s, y + 0.008, p.y * s))
		"crown":
			k.rbox(Vector3(0.12, 0.012, 0.05) * s, 0.008, Pal.BRASS, t * MeshKit.at(0, y, 0.02 * s))
			for i in 3:
				k.cone(0.022 * s, 0.05 * s, Pal.BRASS, t * MeshKit.at((i - 1) * 0.045 * s, y, -0.01 * s), 5)
			k.torus(r * 0.8, 0.01, lit(Color(1.0, 0.86, 0.5), 0.5), t * MeshKit.at(0, y - 0.004, 0), 14, 3)


static func _poly(pts: Array, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		out.append(p * s)
	return out


static func _sticker(k: MeshKit, rid: String, p: Vector3, r: float) -> void:
	var look: Dictionary = Defs.MODEL_LOOK.get(rid, Defs.MODEL_LOOK["pico"])
	k.cyl(r, 0.01, look["base"], MeshKit.xf(p, Vector3(90, 0, 0)), 12)
	k.cyl(r + 0.006, 0.008, Pal.WHITE, MeshKit.xf(p - Vector3(0, 0, 0.002), Vector3(90, 0, 0)), 12)


## A batch: a slim graphite case with a glowing seam and the token on top.
static func _batch(k: MeshKit, rid: String) -> void:
	var look: Dictionary = Defs.MODEL_LOOK.get(rid, Defs.MODEL_LOOK["pico"])
	var shell := Color(0.86, 0.88, 0.9)
	k.rbox(Vector3(0.4, 0.24, 0.34), 0.04, shell, MeshKit.at(0, 0.12, 0))
	k.rbox(Vector3(0.41, 0.025, 0.35), 0.012, lit(look["base"], 0.6), MeshKit.at(0, 0.15, 0))
	k.rbox(Vector3(0.1, 0.03, 0.06), 0.01, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.245, 0))
	token_into(k, rid, 0.08, 0.03, MeshKit.at(0.11, 0.24, 0.0))
	_sticker(k, rid, Vector3(0.0, 0.08, 0.172), 0.05)


## An agent run: a little robot parcel (antenna, LED eyes) in the model's colour.
static func _agent(k: MeshKit, rid: String) -> void:
	var look: Dictionary = Defs.MODEL_LOOK.get(rid, Defs.MODEL_LOOK["pico"])
	var body := Color(0.95, 0.95, 0.94)
	k.rbox(Vector3(0.36, 0.24, 0.34), 0.06, body, MeshKit.at(0, 0.12, 0))
	k.rbox(Vector3(0.37, 0.05, 0.35), 0.02, look["base"], MeshKit.at(0, 0.05, 0))
	k.rbox(Vector3(0.24, 0.1, 0.02), 0.04, Color(0.14, 0.16, 0.2), MeshKit.at(0, 0.16, 0.171))
	for sx in [-0.05, 0.05]:
		k.rbox(Vector3(0.035, 0.035, 0.01), 0.012, lit(Color(0.5, 0.95, 1.0), 0.4), MeshKit.at(sx, 0.165, 0.182))
	k.cyl(0.012, 0.08, Pal.STEEL_DARK, MeshKit.at(0, 0.24, 0), 6)
	k.sphere(0.03, lit(look["base"], 0.5), MeshKit.at(0, 0.33, 0), 8, 5)
	_sticker(k, rid, Vector3(0.12, 0.13, 0.172), 0.035)
