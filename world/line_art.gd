class_name LineArt
## Looks for the production line: tube frames, mixers, hopper silos, ovens
## and output trays. Every machine has five tiers that read at a glance:
##   0 rustic (wood, brick, cream enamel)
##   1 workshop (steel bands, bigger)
##   2 bakery (tiles, twin chimneys, stone)
##   3 industrial (stainless steel, windows, dials)
##   4 royal (copper, brass and gold trim, glowing windows)

const Y := LineModule.TUBE_Y

static var _belt: ShaderMaterial


static func belt_material() -> ShaderMaterial:
	if _belt == null:
		_belt = ShaderMaterial.new()
		_belt.shader = preload("res://render/belt.gdshader")
	return _belt


## Dark steel frame under a tube segment of length len (centred on x).
static func frame(len: float) -> Mesh:
	var k := MeshKit.new()
	var steel := Pal.STEEL_DARK
	var n := maxi(2, int(round(len / 2.0)) + 1)
	for i in n:
		var x := -len * 0.5 + 0.18 + (len - 0.36) * i / (n - 1)
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.1, Y - 0.45, 0.1), 0.02, steel, MeshKit.at(x, (Y - 0.45) * 0.5, sz * 0.55))
			k.rbox(Vector3(0.22, 0.04, 0.22), 0.015, steel, MeshKit.at(x, 0.02, sz * 0.55))
		for sy in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.06, 1.14), 0.015, steel, MeshKit.at(x, Y + sy * 0.48, 0))
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 1.0, 0.06), 0.015, steel, MeshKit.at(x, Y, sz * 0.54))
			k.sphere(0.025, Pal.BRASS, MeshKit.at(x, Y + 0.48, sz * 0.56), 5, 3)
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(len, 0.04, 0.04), 0.012, steel, MeshKit.at(0, Y + sy * 0.48, sz * 0.54))
	k.rbox(Vector3(len, 0.08, 1.04), 0.02, steel, MeshKit.at(0, Y - 0.5, 0))
	# a floor plate under the module so a line reads as one machine
	k.rbox(Vector3(len, 0.05, 1.7), 0.02, Color(0.62, 0.6, 0.57), MeshKit.at(0, 0.02, 0.0))
	return k.commit()


## End cap with a terracotta warning stripe (the tube isn't connected here).
static func cap() -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.12, 1.04, 1.14), 0.03, Pal.STEEL_DARK, MeshKit.at(0.0, Y, 0))
	k.rbox(Vector3(0.13, 0.12, 1.15), 0.02, Pal.TERRACOTTA, MeshKit.at(0.0, Y + 0.25, 0))
	k.rbox(Vector3(0.13, 0.12, 1.15), 0.02, Pal.TERRACOTTA, MeshKit.at(0.0, Y - 0.15, 0))
	return k.commit()


# ---------------------------------------------------------------- mixer

## A dough mixer standing behind the start of the tube (local origin = module
## centre, tube at z = TUBE_Z).
static func mixer(t: int) -> Mesh:
	var k := MeshKit.new()
	var z := LineModule.TUBE_Z
	var base_c: Color = [Color(0.93, 0.9, 0.82), Color(0.9, 0.88, 0.84), Color(0.55, 0.62, 0.52), Pal.STEEL, Color(0.72, 0.42, 0.28)][t]
	var trim: Color = [Pal.WOOD, Pal.STEEL_DARK, Pal.CREAM, Pal.STEEL_DARK, Pal.BRASS][t]
	var bowl: Color = [Color(0.92, 0.9, 0.86), Pal.STEEL, Pal.STEEL, Pal.STEEL.lightened(0.08), Color(0.8, 0.5, 0.32)][t]
	var s := 1.0 + t * 0.06
	# pedestal
	if t == 0:
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.1, 0.9, 0.1), 0.02, Pal.WOOD_DARK, MeshKit.at(sx * 0.55, 0.45, z + sz * 0.5))
		k.rbox(Vector3(1.3, 0.1, 1.2), 0.03, Pal.WOOD, MeshKit.at(0, 0.92, z))
	else:
		k.rbox(Vector3(1.4, 0.9, 1.3) * Vector3(1, 1, 1), 0.12, base_c, MeshKit.at(0, 0.45, z))
		k.rbox(Vector3(1.44, 0.08, 1.34), 0.03, trim, MeshKit.at(0, 0.92, z))
		if t >= 3:
			# dials and a little window
			for i in 3:
				k.cyl(0.07, 0.03, Color(0.95, 0.94, 0.9), MeshKit.xf(Vector3(-0.4 + i * 0.4, 0.6, z + 0.66), Vector3(90, 0, 0)), 10)
				k.rbox(Vector3(0.01, 0.05, 0.01), 0.002, Pal.TERRACOTTA, MeshKit.xf(Vector3(-0.4 + i * 0.4, 0.62, z + 0.68), Vector3(0, 0, 30 * i)))
	# bowl
	var prof := PackedVector2Array([Vector2(0, 0), Vector2(0.3, 0.0), Vector2(0.55, 0.15), Vector2(0.62, 0.45), Vector2(0.64, 0.62), Vector2(0.6, 0.64), Vector2(0.56, 0.5), Vector2(0.0, 0.5)])
	for i in prof.size():
		prof[i] *= s
	k.lathe(prof, bowl, MeshKit.at(0, 0.97, z), 20)
	k.cyl(0.5 * s, 0.04, Color(0.95, 0.88, 0.7), MeshKit.at(0, 0.97 + 0.48 * s, z), 16)
	# the arm over the bowl
	var arm: Color = [Color(0.93, 0.9, 0.82), Color(0.9, 0.88, 0.84), Color(0.55, 0.62, 0.52), Pal.STEEL, Color(0.8, 0.5, 0.32)][t]
	k.rbox(Vector3(0.3, 1.1 * s, 0.3), 0.1, arm, MeshKit.at(-0.55 * s, 0.97 + 0.55 * s, z - 0.3))
	k.rbox(Vector3(1.0 * s, 0.3, 0.36), 0.12, arm, MeshKit.at(-0.15 * s, 1.95 * s + 0.1, z - 0.3))
	k.rbox(Vector3(0.36, 0.32, 0.4), 0.1, arm, MeshKit.at(0.0, 1.85 * s + 0.1, z))
	if t >= 2:
		k.rbox(Vector3(1.04 * s, 0.05, 0.4), 0.02, trim, MeshKit.at(-0.15 * s, 1.95 * s - 0.04, z - 0.3))
	if t == 4:
		k.sphere(0.12, Pal.BRASS, MeshKit.at(-0.55 * s, 2.15 * s, z - 0.3), 8, 6)
	if t >= 2:
		# a flour funnel feeding the bowl
		k.cyl(0.06, 0.6, Pal.STEEL_DARK, MeshKit.xf(Vector3(0.45, 1.75 * s, z - 0.45), Vector3(0, 0, 35)), 8)
		k.cone(0.32, 0.5, trim if t != 2 else Pal.STEEL, MeshKit.xf(Vector3(0.75, 2.45 * s, z - 0.45), Vector3(180, 0, 0)), 12)
		k.cyl(0.33, 0.35, trim if t != 2 else Pal.STEEL, MeshKit.at(0.75, 2.45 * s, z - 0.45), 12, 0.02)
	if t >= 3:
		# a control panel with lights
		k.rbox(Vector3(0.5, 0.7, 0.12), 0.04, Pal.STEEL_DARK, MeshKit.at(-0.55, 1.45, z + 0.55))
		for i in 3:
			k.sphere(0.05, [Color(0.5, 0.9, 0.5, 0.4), Color(1.0, 0.8, 0.3, 0.4), Color(0.95, 0.4, 0.3, 0.4)][i], MeshKit.at(-0.7 + i * 0.15, 1.6, z + 0.62), 6, 4)
		k.cyl(0.07, 0.04, Color(0.95, 0.94, 0.9), MeshKit.xf(Vector3(-0.55, 1.3, z + 0.62), Vector3(90, 0, 0)), 10)
	if t == 4:
		# a royal crest on the arm and gold trim on the bowl rim
		k.torus(0.64 * s, 0.035, Pal.GOLD, MeshKit.at(0, 0.97 + 0.64 * s, z), 20, 4)
		Items.cookie_into(k, "royal", 0.16, 0.04, MeshKit.xf(Vector3(-0.15 * s, 1.95 * s + 0.1, z - 0.1), Vector3(90, 0, 0)))
	# chute from the bowl into the tube
	k.rbox(Vector3(0.5, 0.2, 0.5), 0.05, Pal.STEEL_DARK, MeshKit.at(0.55, Y + 0.45, z))
	return k.commit()


## The rotating dough hook (spins while mixing).
static func hook() -> Mesh:
	var k := MeshKit.new()
	k.cyl(0.04, 0.5, Pal.STEEL, MeshKit.at(0, -0.5, 0), 6)
	k.torus(0.12, 0.03, Pal.STEEL, MeshKit.xf(Vector3(0.0, -0.5, 0), Vector3(90, 0, 0)), 10, 4, PI * 1.4)
	return k.commit()


# ---------------------------------------------------------------- hopper

static func silo(ing: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var c: Color = Defs.ITEMS[ing]["color"]
	match t:
		0:
			# wooden funnel bin
			k.cyl(0.1, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 10, 0.02)
			k.cyl(0.12, 0.42, Pal.WOOD_DARK, MeshKit.at(0, 0.16, 0), 8, 0.0, 0.42, false)
			k.rbox(Vector3(0.86, 0.6, 0.86), 0.05, Pal.WOOD, MeshKit.at(0, 0.88, 0))
			for y in [0.66, 1.1]:
				k.rbox(Vector3(0.9, 0.06, 0.9), 0.02, Pal.WOOD_DARK, MeshKit.at(0, y, 0))
			k.rbox(Vector3(0.9, 0.1, 0.9), 0.02, c, MeshKit.at(0, 0.88, 0))
		1:
			k.cyl(0.12, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 12, 0.02)
			k.cyl(0.13, 0.45, Pal.STEEL.darkened(0.08), MeshKit.at(0, 0.16, 0), 18, 0.0, 0.44, false)
			k.cyl(0.44, 0.8, Pal.STEEL, MeshKit.at(0, 0.6, 0), 22, 0.03)
			k.cyl(0.448, 0.1, c, MeshKit.at(0, 0.9, 0), 22, 0.0)
			k.ellipsoid(Vector3(0.44, 0.16, 0.44), Pal.STEEL.lightened(0.05), MeshKit.at(0, 1.4, 0), 18, 6)
			k.cyl(0.07, 0.1, Pal.BRASS, MeshKit.at(0, 1.52, 0), 10, 0.02)
			for a in 4:
				var ang := TAU * a / 4.0 + PI * 0.25
				k.rbox(Vector3(0.04, 0.5, 0.04), 0.01, Pal.STEEL_DARK, MeshKit.at(cos(ang) * 0.4, 0.3, sin(ang) * 0.4))
			k.rbox(Vector3(0.12, 0.6, 0.03), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 0.98, 0.43))
		_:
			var steel: Color = Pal.STEEL if t < 4 else Color(0.82, 0.55, 0.36)
			var band: Color = Pal.BRASS if t >= 3 else Pal.STEEL_DARK
			k.cyl(0.12, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 12, 0.02)
			k.cyl(0.14, 0.5, steel.darkened(0.08), MeshKit.at(0, 0.16, 0), 18, 0.0, 0.5, false)
			k.cyl(0.5, 1.3, steel, MeshKit.at(0, 0.64, 0), 22, 0.03)
			for y in [0.8, 1.3, 1.8]:
				k.cyl(0.505, 0.05, band, MeshKit.at(0, y, 0), 22)
			k.cyl(0.508, 0.14, c, MeshKit.at(0, 1.05, 0), 22)
			k.ellipsoid(Vector3(0.5, 0.2, 0.5), steel.lightened(0.05), MeshKit.at(0, 1.94, 0), 18, 6)
			k.cyl(0.08, 0.14, Pal.BRASS, MeshKit.at(0, 2.1, 0), 10, 0.02)
			# ladder up the side
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.03, 1.5, 0.03), 0.01, Pal.STEEL_DARK, MeshKit.at(0.52, 1.1, sx * 0.12))
			for i in 7:
				k.rbox(Vector3(0.03, 0.02, 0.24), 0.005, Pal.STEEL_DARK, MeshKit.at(0.53, 0.5 + i * 0.2, 0))
			k.rbox(Vector3(0.12, 0.8, 0.03), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 1.2, 0.49))
	return k.commit()


# ---------------------------------------------------------------- oven

## Oven body. Local origin = oven module centre; the tube enters on -X at
## z = TUBE_Z and the oven dome sits over the tube end.
static func oven(t: int) -> Mesh:
	var k := MeshKit.new()
	var z := LineModule.TUBE_Z
	var cx := -0.25
	match t:
		0, 1:
			var stone := Pal.STONE
			k.rbox(Vector3(2.6, 0.4, 2.0), 0.06, stone, MeshKit.at(cx, 0.2, z))
			k.rbox(Vector3(2.7, 0.06, 2.1), 0.03, Pal.STONE_DARK, MeshKit.at(cx, 0.41, z))
			var prof := PackedVector2Array()
			var cols := []
			var courses := 11
			var rr := 1.0 + t * 0.08
			for i in courses + 1:
				var a := PI * 0.5 * float(i) / courses
				prof.append(Vector2(cos(a) * rr, 0.44 + sin(a) * 1.5))
				prof.append(Vector2(cos(a) * rr, 0.44 + sin(a) * 1.5))
				var c: Color = Pal.BRICK if i % 2 == 0 else Pal.BRICK.lerp(Pal.BRICK_DARK, 0.45)
				cols.append(c)
				cols.append(c)
			prof[prof.size() - 1] = Vector2(0, 1.94)
			prof[prof.size() - 2] = Vector2(0, 1.94)
			k.lathe(prof, cols, MeshKit.at(cx, 0, z), 28)
			if t == 1:
				for y in [0.9, 1.4]:
					k.torus(rr * cos(asin(clampf((y - 0.44) / 1.5, 0.0, 1.0))) + 0.02, 0.03, Pal.STEEL_DARK, MeshKit.at(cx, y, z), 28, 4)
			# arched iron mouth facing the camera
			k.rbox(Vector3(0.95, 0.85, 0.4), 0.28, Pal.STEEL_DARK, MeshKit.at(cx, 0.9, z + 0.85))
			k.rbox(Vector3(0.74, 0.66, 0.4), 0.22, Color(1.0, 0.5, 0.2, 0.45), MeshKit.at(cx, 0.88, z + 0.9))
			# chimney
			var ch := 1.35 + t * 0.3
			k.cyl(0.24, 0.5, Pal.BRICK_DARK, MeshKit.at(cx - 0.35, 1.55, z - 0.35), 12, 0.02)
			k.cyl(0.16, ch, Pal.STEEL_DARK, MeshKit.at(cx - 0.35, 2.0, z - 0.35), 12, 0.02)
			k.cyl(0.2, 0.08, Pal.BRASS, MeshKit.at(cx - 0.35, 2.0 + ch, z - 0.35), 12, 0.02)
		2:
			# a tiled bakery oven: square body, cream tiles, twin chimneys
			k.rbox(Vector3(2.8, 0.35, 2.2), 0.05, Pal.STONE_DARK, MeshKit.at(cx, 0.17, z))
			k.rbox(Vector3(2.6, 1.6, 2.0), 0.12, Color(0.94, 0.9, 0.82), MeshKit.at(cx, 1.15, z))
			for i in 6:
				for j in 4:
					if (i + j) % 2 == 0:
						k.rbox(Vector3(0.4, 0.36, 0.02), 0.03, Color(0.86, 0.8, 0.7), MeshKit.at(cx - 1.0 + i * 0.4, 0.55 + j * 0.38, z + 1.01))
			k.rbox(Vector3(2.8, 0.14, 2.2), 0.04, Pal.TERRACOTTA, MeshKit.at(cx, 2.0, z))
			k.rbox(Vector3(1.1, 0.8, 0.12), 0.06, Pal.STEEL_DARK, MeshKit.at(cx, 1.0, z + 1.04))
			k.rbox(Vector3(0.9, 0.55, 0.1), 0.05, Color(1.0, 0.55, 0.22, 0.4), MeshKit.at(cx, 1.0, z + 1.1))
			k.rbox(Vector3(1.0, 0.05, 0.15), 0.02, Pal.BRASS, MeshKit.at(cx, 1.45, z + 1.1))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.4, 1.4, 0.4), 0.05, Pal.BRICK, MeshKit.at(cx + sx * 0.85, 2.7, z - 0.5))
				k.rbox(Vector3(0.48, 0.1, 0.48), 0.02, Pal.BRICK_DARK, MeshKit.at(cx + sx * 0.85, 3.42, z - 0.5))
		3:
			# stainless deck oven: three glass decks with dials, a steel hood
			k.rbox(Vector3(2.9, 0.3, 2.2), 0.05, Pal.STEEL_DARK, MeshKit.at(cx, 0.15, z))
			k.rbox(Vector3(2.8, 1.9, 2.1), 0.08, Pal.STEEL, MeshKit.at(cx, 1.25, z))
			for d in 3:
				var y := 0.62 + d * 0.55
				k.rbox(Vector3(2.0, 0.38, 0.06), 0.04, Pal.STEEL_DARK, MeshKit.at(cx - 0.2, y, z + 1.06))
				k.rbox(Vector3(1.8, 0.24, 0.05), 0.03, Color(1.0, 0.6, 0.25, 0.45), MeshKit.at(cx - 0.2, y, z + 1.09))
				k.rbox(Vector3(1.6, 0.04, 0.06), 0.015, Pal.STEEL.lightened(0.1), MeshKit.at(cx - 0.2, y + 0.23, z + 1.1))
				for i in 2:
					k.cyl(0.07, 0.04, Color(0.95, 0.94, 0.9), MeshKit.xf(Vector3(cx + 1.0, y + (i - 0.5) * 0.18, z + 1.08), Vector3(90, 0, 0)), 10)
			k.rbox(Vector3(3.0, 0.3, 2.3), 0.06, Pal.STEEL_DARK, MeshKit.at(cx, 2.3, z))
			k.cyl(0.25, 1.0, Pal.STEEL, MeshKit.at(cx - 0.7, 2.4, z - 0.4), 14, 0.02)
			k.cyl(0.3, 0.12, Pal.STEEL_DARK, MeshKit.at(cx - 0.7, 3.4, z - 0.4), 14, 0.02)
		_:
			# royal tunnel oven: copper body, brass bands, glowing windows, a crown
			var copper := Color(0.78, 0.48, 0.3)
			k.rbox(Vector3(3.0, 0.35, 2.3), 0.06, Color(0.3, 0.22, 0.18), MeshKit.at(cx, 0.17, z))
			var prof2 := PackedVector2Array([Vector2(1.15, 0.35), Vector2(1.15, 1.3), Vector2(1.0, 1.85), Vector2(0.6, 2.2), Vector2(0.0, 2.32)])
			k.lathe(prof2, copper, MeshKit.xf(Vector3(cx, 0, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 24)
			for y in [0.6, 1.2, 1.8]:
				k.torus(1.16 if y < 1.5 else 0.92, 0.04, Pal.BRASS, MeshKit.xf(Vector3(cx, y, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 24, 4)
			for i in 3:
				var a := -0.7 + i * 0.7
				k.rbox(Vector3(0.36, 0.5, 0.08), 0.12, Color(1.0, 0.7, 0.3, 0.35), MeshKit.xf(Vector3(cx + sin(a) * 1.35, 1.0, z + cos(a) * 1.1), Vector3(0, rad_to_deg(a), 0)))
			k.rbox(Vector3(0.9, 0.8, 0.3), 0.28, Color(0.3, 0.2, 0.15), MeshKit.at(cx, 0.85, z + 1.08))
			k.rbox(Vector3(0.7, 0.6, 0.3), 0.22, Color(1.0, 0.55, 0.2, 0.35), MeshKit.at(cx, 0.83, z + 1.13))
			for i in 5:
				var a2 := TAU * i / 5.0
				k.cone(0.07, 0.25, Pal.GOLD, MeshKit.at(cx + cos(a2) * 0.28, 2.38, z + sin(a2) * 0.28), 6)
			k.torus(0.3, 0.05, Pal.GOLD, MeshKit.at(cx, 2.36, z), 14, 4)
			k.cyl(0.18, 1.2, copper, MeshKit.at(cx + 0.8, 1.9, z - 0.55), 12, 0.02)
			k.cyl(0.24, 0.1, Pal.BRASS, MeshKit.at(cx + 0.8, 3.1, z - 0.55), 12, 0.02)
	# tube inlet on the west side
	k.rbox(Vector3(0.3, 1.0, 1.1), 0.04, Pal.STEEL_DARK, MeshKit.at(-1.85, Y, z))
	return k.commit()


## The chimney top (where smoke puffs) for each tier, local.
static func chimney_top(t: int) -> Vector3:
	var z := LineModule.TUBE_Z
	match t:
		0: return Vector3(-0.6, 3.5, z - 0.35)
		1: return Vector3(-0.6, 3.8, z - 0.35)
		2: return Vector3(0.6, 3.55, z - 0.5)
		3: return Vector3(-0.95, 3.6, z - 0.4)
	return Vector3(0.55, 3.3, z - 0.55)


## Output bench at the front right of the oven where cookies land.
static func tray(t: int) -> Mesh:
	var k := MeshKit.new()
	var top: Color = [Pal.WOOD_LIGHT, Pal.STEEL, Pal.STEEL, Pal.STEEL.lightened(0.08), Color(0.94, 0.92, 0.86)][t]
	var leg: Color = [Pal.WOOD_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.BRASS][t]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.72, 0.08), 0.02, leg, MeshKit.at(sx * 0.62, 0.36, sz * 0.42))
	k.rbox(Vector3(1.4, 0.06, 1.0), 0.02, leg, MeshKit.at(0, 0.72, 0))
	k.rbox(Vector3(1.3, 0.03, 0.9), 0.01, top, MeshKit.at(0, 0.765, 0))
	k.rbox(Vector3(1.3, 0.06, 0.06), 0.01, Pal.WOOD, MeshKit.at(0, 0.36, 0))
	return k.commit()
