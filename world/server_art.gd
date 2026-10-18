class_name ServerArt
## Looks for the inference server's serving stack: the rack frame under the
## glass request bus, the request router, module bays, the GPU core and the
## token bench. Every machine has five tiers that read at a glance:
##   0 garage rig   (a desktop PC, plywood, a desk lamp, RGB)
##   1 server closet (a small rack, steel, blinking ports)
##   2 server room  (white racks, cable bundles, a DGX-style cube)
##   3 data hall    (steel and glass, cold-aisle blue, deck lights)
##   4 hyperscale   (graphite monolith, brass trim, a glowing core ring)

const Y := 1.25
const TZ := -1.0

static var _belt: ShaderMaterial


static func belt_material() -> ShaderMaterial:
	if _belt == null:
		_belt = ShaderMaterial.new()
		_belt.shader = preload("res://render/belt.gdshader")
	return _belt


static func lit(c: Color, a := 0.45) -> Color:
	return Color(c.r, c.g, c.b, a)


## Rack frame under a bus segment of length len (centred on x).
static func frame(len: float) -> Mesh:
	var k := MeshKit.new()
	var steel := Color(0.22, 0.23, 0.26)
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
			k.sphere(0.03, lit(Color(0.4, 0.9, 1.0), 0.4), MeshKit.at(x, Y + 0.48, sz * 0.56), 5, 3)
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(len, 0.04, 0.04), 0.012, steel, MeshKit.at(0, Y + sy * 0.48, sz * 0.54))
	k.rbox(Vector3(len, 0.08, 1.04), 0.02, steel, MeshKit.at(0, Y - 0.5, 0))
	# a light strip along the front of the bus
	k.rbox(Vector3(len - 0.1, 0.03, 0.03), 0.01, lit(Color(0.36, 0.86, 0.96), 0.4), MeshKit.at(0, Y - 0.45, 0.56))
	# a floor plate so the line reads as one machine
	k.rbox(Vector3(len, 0.05, 1.7), 0.02, Color(0.5, 0.52, 0.56), MeshKit.at(0, 0.02, 0.0))
	# cables under the bus
	for i in 3:
		k.cyl(0.04, len - 0.2, [Color(0.3, 0.5, 0.86), Color(0.94, 0.7, 0.3), Color(0.24, 0.24, 0.28)][i], MeshKit.xf(Vector3(-len * 0.5 + 0.1, 0.12 + i * 0.03, -0.2 + i * 0.09), Vector3(0, 0, -90)), 6)
	return k.commit()


# ---------------------------------------------------------------- router

## The request router behind the start of the bus (local origin = module
## centre, bus at z = TZ). Requests come out of its port into the bus.
static func router(t: int) -> Mesh:
	var k := MeshKit.new()
	var z := TZ
	match t:
		0:
			# a gaming PC on a plywood desk, a desk lamp, sticky notes
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.rbox(Vector3(0.08, 0.85, 0.08), 0.02, Pal.WOOD_DARK, MeshKit.at(sx * 0.6, 0.42, z + sz * 0.5))
			k.rbox(Vector3(1.4, 0.08, 1.2), 0.03, Pal.WOOD_LIGHT, MeshKit.at(0, 0.88, z))
			k.rbox(Vector3(0.5, 0.95, 0.9), 0.04, Color(0.12, 0.12, 0.14), MeshKit.at(-0.2, 1.4, z - 0.05))
			k.rbox(Vector3(0.02, 0.8, 0.75), 0.02, lit(Color(0.7, 0.4, 0.95), 0.6), MeshKit.at(0.06, 1.4, z - 0.05))
			for i in 3:
				k.cyl(0.1, 0.02, lit([Color(1, 0.4, 0.6), Color(0.4, 0.8, 1), Color(0.5, 1, 0.6)][i], 0.5), MeshKit.xf(Vector3(0.07, 1.65 - i * 0.25, z + 0.1), Vector3(0, 0, 90)), 10)
			k.cyl(0.02, 0.5, Pal.STEEL_DARK, MeshKit.xf(Vector3(0.45, 0.92, z - 0.3), Vector3(0, 0, -15)), 6)
			k.cone(0.12, 0.14, Color(0.9, 0.4, 0.3), MeshKit.xf(Vector3(0.55, 1.45, z - 0.3), Vector3(0, 0, 150)), 10)
			k.rbox(Vector3(0.12, 0.12, 0.01), 0.01, Color(0.98, 0.9, 0.4), MeshKit.at(-0.55, 1.6, z + 0.41))
		1:
			# a small open rack with a switch, blinking ports
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					k.rbox(Vector3(0.08, 2.0, 0.08), 0.02, Color(0.26, 0.27, 0.3), MeshKit.at(sx * 0.55, 1.0, z + sz * 0.45))
			for i in 5:
				var y := 0.35 + i * 0.36
				k.rbox(Vector3(1.05, 0.26, 0.86), 0.03, Color(0.86, 0.87, 0.88) if i % 2 == 0 else Color(0.3, 0.32, 0.36), MeshKit.at(0, y, z))
				for j in 6:
					k.rbox(Vector3(0.06, 0.05, 0.01), 0.01, lit([Color(0.5, 1, 0.6), Color(1, 0.8, 0.3)][(i + j) % 2], 0.45), MeshKit.at(-0.4 + j * 0.12, y, z + 0.44))
			k.rbox(Vector3(1.2, 0.08, 1.0), 0.02, Color(0.26, 0.27, 0.3), MeshKit.at(0, 2.02, z))
		2:
			# a white rack with a front panel of ports and a cable waterfall
			k.rbox(Vector3(1.2, 2.1, 1.0), 0.08, Color(0.94, 0.95, 0.96), MeshKit.at(0, 1.05, z))
			k.rbox(Vector3(1.0, 1.8, 0.04), 0.04, Color(0.18, 0.2, 0.24), MeshKit.at(0, 1.05, z + 0.5))
			for i in 8:
				for j in 8:
					k.rbox(Vector3(0.07, 0.05, 0.01), 0.01, lit([Color(0.4, 0.9, 1), Color(0.5, 1, 0.6), Color(0.3, 0.6, 1)][(i * 3 + j) % 3], 0.45), MeshKit.at(-0.4 + j * 0.115, 0.3 + i * 0.2, z + 0.53))
			for i in 4:
				k.cyl(0.035, 1.2, [Color(0.3, 0.5, 0.86), Color(0.94, 0.7, 0.3), Color(0.4, 0.8, 0.5), Color(0.9, 0.4, 0.5)][i], MeshKit.at(0.65, 0.9, z - 0.3 + i * 0.12), 6)
		3:
			# a steel rack behind glass, cold-aisle blue light
			k.rbox(Vector3(1.25, 2.3, 1.05), 0.06, Color(0.42, 0.45, 0.5), MeshKit.at(0, 1.15, z))
			k.rbox(Vector3(1.05, 2.0, 0.04), 0.03, Color(0.5, 0.72, 0.9, 0.85), MeshKit.at(0, 1.15, z + 0.53))
			for i in 10:
				k.rbox(Vector3(0.9, 0.08, 0.02), 0.01, lit(Color(0.4, 0.75, 1.0), 0.5 if i % 3 else 0.35), MeshKit.at(0, 0.3 + i * 0.18, z + 0.5))
			k.rbox(Vector3(1.35, 0.12, 1.15), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0, 2.36, z))
			k.rbox(Vector3(0.5, 0.14, 0.6), 0.03, Color(0.3, 0.32, 0.36), MeshKit.at(0, 2.5, z - 0.1))
		_:
			# a graphite monolith with brass edges and a halo
			var g := Color(0.16, 0.17, 0.2)
			k.rbox(Vector3(1.3, 2.5, 1.1), 0.1, g, MeshKit.at(0, 1.25, z))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.05, 2.5, 0.05), 0.02, Pal.BRASS, MeshKit.at(sx * 0.63, 1.25, z + 0.54))
			k.rbox(Vector3(0.9, 1.8, 0.03), 0.04, lit(Color(0.3, 0.8, 0.86), 0.65), MeshKit.at(0, 1.25, z + 0.55))
			k.torus(0.45, 0.04, lit(Color(1.0, 0.86, 0.5), 0.4), MeshKit.xf(Vector3(0, 2.75, z), Vector3(0, 0, 0)), 20, 5)
	# the port where requests drop into the bus
	k.rbox(Vector3(0.5, 0.2, 0.5), 0.05, Color(0.22, 0.23, 0.26), MeshKit.at(0.55, Y + 0.45, z))
	k.rbox(Vector3(0.3, 0.04, 0.3), 0.02, lit(Color(0.4, 0.9, 1.0), 0.4), MeshKit.at(0.55, Y + 0.56, z))
	return k.commit()


## Height of the router's spinning fan for a tier (local y).
static func fan_y(t: int) -> float:
	return [1.9, 2.15, 2.25, 2.6, 2.9][t]


## The router's cooling fan (spins while routing).
static func fan() -> Mesh:
	var k := MeshKit.new()
	k.cyl(0.24, 0.04, Color(0.26, 0.27, 0.3), MeshKit.at(0, -0.02, 0), 16)
	for i in 5:
		k.rbox(Vector3(0.06, 0.02, 0.2), 0.01, Color(0.82, 0.84, 0.88), MeshKit.xf(Vector3.ZERO, Vector3(0, i * 72, 12)) * MeshKit.at(0, 0.03, 0.11))
	k.cyl(0.05, 0.05, lit(Color(0.4, 0.9, 1.0), 0.4), MeshKit.at(0, 0.02, 0), 8)
	return k.commit()


# ---------------------------------------------------------------- module bays

## A module bay over the bus, fed with one resource (its colour band says
## which; "" = an empty bay, grey).
static func module(ing: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var c: Color = Defs.ITEMS[ing]["color"] if Defs.ITEMS.has(ing) else Color(0.46, 0.48, 0.52)
	match t:
		0:
			# a plastic tote on a shelf bracket
			k.cyl(0.1, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 10, 0.02)
			k.rbox(Vector3(0.8, 0.5, 0.7), 0.06, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0.5, 0))
			k.rbox(Vector3(0.82, 0.1, 0.72), 0.03, c, MeshKit.at(0, 0.62, 0))
			k.rbox(Vector3(0.84, 0.05, 0.74), 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.77, 0))
		1:
			# a metal case with a status light
			k.cyl(0.12, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 12, 0.02)
			k.rbox(Vector3(0.82, 0.9, 0.78), 0.05, Color(0.78, 0.8, 0.84), MeshKit.at(0, 0.62, 0))
			k.rbox(Vector3(0.84, 0.12, 0.8), 0.02, c, MeshKit.at(0, 0.9, 0))
			k.rbox(Vector3(0.6, 0.05, 0.01), 0.01, lit(c.lightened(0.3), 0.4), MeshKit.at(0, 0.5, 0.395))
			for i in 4:
				k.rbox(Vector3(0.6, 0.02, 0.01), 0.005, Color(0.5, 0.52, 0.56), MeshKit.at(0, 0.35 + i * 0.06, 0.393))
		_:
			# a tall module tower: banded, a light column, cooling ribs
			var shell: Color = [Color(0.94, 0.95, 0.96), Color(0.94, 0.95, 0.96), Color(0.62, 0.66, 0.72), Color(0.18, 0.19, 0.22)][t - 1]
			var band: Color = Pal.BRASS if t == 4 else Color(0.3, 0.32, 0.36)
			k.cyl(0.12, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 12, 0.02)
			k.rbox(Vector3(0.84, 1.5, 0.8), 0.08, shell, MeshKit.at(0, 0.92, 0))
			k.rbox(Vector3(0.86, 0.18, 0.82), 0.03, c, MeshKit.at(0, 1.2, 0))
			for y in [0.26, 1.66]:
				k.rbox(Vector3(0.88, 0.05, 0.84), 0.02, band, MeshKit.at(0, y, 0))
			k.rbox(Vector3(0.08, 0.8, 0.01), 0.02, lit(c.lightened(0.25), 0.4), MeshKit.at(-0.28, 0.7, 0.405))
			for i in 6:
				k.rbox(Vector3(0.4, 0.025, 0.012), 0.005, shell.darkened(0.2), MeshKit.at(0.12, 0.4 + i * 0.1, 0.402))
			# a ladder up the side
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.03, 1.3, 0.03), 0.01, Pal.STEEL_DARK, MeshKit.at(0.44, 0.95, sx * 0.12))
			for i in 6:
				k.rbox(Vector3(0.03, 0.02, 0.24), 0.005, Pal.STEEL_DARK, MeshKit.at(0.45, 0.4 + i * 0.2, 0))
	return k.commit()


## Height of the top of a module for a tier (where its sign floats).
static func module_top(t: int) -> float:
	return [0.85, 1.0, 1.75, 1.75, 1.75][t]


# ---------------------------------------------------------------- GPU core

## The GPU core. Local origin = core module centre; the bus enters on -X at
## z = TZ and requests disappear into it. Tokens come out of its front.
static func core(t: int) -> Mesh:
	var k := MeshKit.new()
	var z := TZ
	var cx := -0.25
	match t:
		0:
			# a big glass-sided gaming tower with RGB fans and a GPU inside
			k.rbox(Vector3(2.4, 0.3, 1.8), 0.05, Pal.WOOD_LIGHT, MeshKit.at(cx, 0.15, z))
			k.rbox(Vector3(1.6, 1.9, 1.3), 0.08, Color(0.12, 0.12, 0.14), MeshKit.at(cx, 1.25, z))
			k.rbox(Vector3(1.4, 1.65, 0.04), 0.05, Color(0.3, 0.32, 0.4, 0.8), MeshKit.at(cx, 1.25, z + 0.66))
			k.rbox(Vector3(1.0, 0.18, 0.5), 0.03, Color(0.2, 0.46, 0.3), MeshKit.at(cx, 1.0, z + 0.3))
			k.rbox(Vector3(0.9, 0.03, 0.02), 0.01, lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.at(cx, 1.0, z + 0.56))
			for i in 3:
				k.torus(0.16, 0.025, lit([Color(1, 0.4, 0.7), Color(0.4, 0.8, 1), Color(0.7, 0.5, 1)][i], 0.45), MeshKit.xf(Vector3(cx - 0.5 + i * 0.5, 1.8, z + 0.67), Vector3(90, 0, 0)), 12, 4)
			k.rbox(Vector3(0.95, 0.75, 0.3), 0.08, Color(0.12, 0.12, 0.14), MeshKit.at(cx, 0.75, z + 0.85))
			k.rbox(Vector3(0.75, 0.55, 0.3), 0.06, lit(Color(0.5, 0.86, 1.0), 0.45), MeshKit.at(cx, 0.73, z + 0.9))
		1:
			# a 4U server on a stand, a row of fans across the front
			k.rbox(Vector3(2.6, 0.35, 2.0), 0.05, Color(0.3, 0.32, 0.36), MeshKit.at(cx, 0.17, z))
			k.rbox(Vector3(2.4, 1.6, 1.8), 0.06, Color(0.82, 0.84, 0.86), MeshKit.at(cx, 1.15, z))
			for i in 4:
				k.cyl(0.22, 0.04, Color(0.24, 0.25, 0.28), MeshKit.xf(Vector3(cx - 0.8 + i * 0.53, 1.45, z + 0.9), Vector3(90, 0, 0)), 14)
				k.cyl(0.07, 0.05, lit(Color(0.4, 0.9, 1.0), 0.45), MeshKit.xf(Vector3(cx - 0.8 + i * 0.53, 1.45, z + 0.91), Vector3(90, 0, 0)), 8)
			k.rbox(Vector3(1.0, 0.65, 0.12), 0.06, Color(0.24, 0.25, 0.28), MeshKit.at(cx, 0.75, z + 0.92))
			k.rbox(Vector3(0.82, 0.48, 0.1), 0.05, lit(Color(0.5, 0.86, 1.0), 0.45), MeshKit.at(cx, 0.75, z + 0.96))
			k.cyl(0.16, 0.8, Color(0.6, 0.62, 0.66), MeshKit.at(cx - 0.6, 1.95, z - 0.4), 12, 0.02)
		2:
			# a white DGX-style cube with a gold grille front
			k.rbox(Vector3(2.8, 0.35, 2.2), 0.05, Color(0.3, 0.32, 0.36), MeshKit.at(cx, 0.17, z))
			k.rbox(Vector3(2.6, 1.8, 2.0), 0.12, Color(0.95, 0.95, 0.96), MeshKit.at(cx, 1.25, z))
			for i in 9:
				for j in 5:
					k.rbox(Vector3(0.22, 0.2, 0.03), 0.04, Color(0.86, 0.72, 0.44) if (i + j) % 2 == 0 else Color(0.78, 0.64, 0.38), MeshKit.at(cx - 1.0 + i * 0.25, 1.2 + j * 0.15, z + 1.01))
			k.rbox(Vector3(1.1, 0.6, 0.12), 0.06, Color(0.2, 0.22, 0.26), MeshKit.at(cx, 0.72, z + 1.04))
			k.rbox(Vector3(0.9, 0.42, 0.1), 0.05, lit(Color(0.5, 0.9, 1.0), 0.4), MeshKit.at(cx, 0.72, z + 1.1))
			for sx in [-1.0, 1.0]:
				k.rbox(Vector3(0.4, 1.0, 0.4), 0.05, Color(0.88, 0.9, 0.92), MeshKit.at(cx + sx * 0.85, 2.6, z - 0.5))
				k.rbox(Vector3(0.44, 0.08, 0.44), 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(cx + sx * 0.85, 3.12, z - 0.5))
		3:
			# a steel GPU pod: three glowing decks, a cooling hood, blue pipes
			k.rbox(Vector3(2.9, 0.3, 2.2), 0.05, Color(0.24, 0.25, 0.28), MeshKit.at(cx, 0.15, z))
			k.rbox(Vector3(2.8, 1.9, 2.1), 0.08, Color(0.62, 0.66, 0.72), MeshKit.at(cx, 1.25, z))
			for d in 3:
				var y := 0.62 + d * 0.55
				k.rbox(Vector3(2.0, 0.38, 0.06), 0.04, Color(0.24, 0.25, 0.28), MeshKit.at(cx - 0.2, y, z + 1.06))
				k.rbox(Vector3(1.8, 0.24, 0.05), 0.03, lit(Color(0.36, 0.8, 1.0), 0.45), MeshKit.at(cx - 0.2, y, z + 1.09))
				for i in 2:
					k.cyl(0.06, 0.04, lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.xf(Vector3(cx + 1.0, y + (i - 0.5) * 0.18, z + 1.08), Vector3(90, 0, 0)), 8)
			k.rbox(Vector3(3.0, 0.3, 2.3), 0.06, Color(0.24, 0.25, 0.28), MeshKit.at(cx, 2.3, z))
			for i in 3:
				k.cyl(0.08, 2.4, Color(0.36, 0.6, 0.86), MeshKit.xf(Vector3(cx - 1.2, 2.5, z - 0.6 + i * 0.3), Vector3(0, 0, -90)), 8)
			k.cyl(0.25, 1.0, Color(0.62, 0.66, 0.72), MeshKit.at(cx - 0.7, 2.4, z - 0.4), 14, 0.02)
			k.cyl(0.3, 0.12, Color(0.24, 0.25, 0.28), MeshKit.at(cx - 0.7, 3.4, z - 0.4), 14, 0.02)
		_:
			# a graphite monolith core with brass bands and a glowing ring
			var g := Color(0.16, 0.17, 0.2)
			k.rbox(Vector3(3.0, 0.35, 2.3), 0.06, Color(0.12, 0.12, 0.14), MeshKit.at(cx, 0.17, z))
			var prof := PackedVector2Array([Vector2(1.15, 0.35), Vector2(1.15, 1.4), Vector2(1.05, 1.95), Vector2(0.7, 2.3), Vector2(0.0, 2.4)])
			k.lathe(prof, g, MeshKit.xf(Vector3(cx, 0, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 8)
			for y in [0.6, 1.3]:
				k.torus(1.17, 0.04, Pal.BRASS, MeshKit.xf(Vector3(cx, y, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 8, 4)
			k.torus(0.9, 0.06, lit(Color(0.4, 0.95, 0.95), 0.4), MeshKit.xf(Vector3(cx, 1.9, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 24, 5)
			for i in 3:
				var a := -0.7 + i * 0.7
				k.rbox(Vector3(0.3, 0.6, 0.08), 0.06, lit(Color(1.0, 0.86, 0.5), 0.4), MeshKit.xf(Vector3(cx + sin(a) * 1.36, 1.0, z + cos(a) * 1.1), Vector3(0, rad_to_deg(a), 0)))
			k.rbox(Vector3(0.9, 0.8, 0.3), 0.2, g.darkened(0.2), MeshKit.at(cx, 0.85, z + 1.08))
			k.rbox(Vector3(0.7, 0.6, 0.3), 0.16, lit(Color(0.4, 0.95, 0.95), 0.4), MeshKit.at(cx, 0.83, z + 1.13))
			k.sphere(0.22, lit(Color(1.0, 0.9, 0.6), 0.35), MeshKit.at(cx, 2.55, z), 12, 8)
			k.cyl(0.18, 1.2, g, MeshKit.at(cx + 0.8, 1.9, z - 0.55), 8, 0.02)
			k.cyl(0.24, 0.1, Pal.BRASS, MeshKit.at(cx + 0.8, 3.1, z - 0.55), 8, 0.02)
	# bus inlet on the west side
	k.rbox(Vector3(0.3, 1.0, 1.1), 0.04, Color(0.22, 0.23, 0.26), MeshKit.at(-1.85, Y, z))
	return k.commit()


## The exhaust vent (where warm air puffs out) for each tier, local.
static func vent_top(t: int) -> Vector3:
	var z := TZ
	match t:
		0: return Vector3(-0.25, 2.3, z)
		1: return Vector3(-0.85, 2.85, z - 0.4)
		2: return Vector3(0.6, 3.25, z - 0.5)
		3: return Vector3(-0.95, 3.6, z - 0.4)
	return Vector3(0.55, 3.3, z - 0.55)


## The token bench at the front right of the core where tokens land.
static func bench(t: int) -> Mesh:
	var k := MeshKit.new()
	var top: Color = [Pal.WOOD_LIGHT, Color(0.78, 0.8, 0.84), Color(0.94, 0.95, 0.96), Color(0.7, 0.74, 0.8), Color(0.2, 0.21, 0.24)][t]
	var leg: Color = [Pal.WOOD_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.STEEL_DARK, Pal.BRASS][t]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.72, 0.08), 0.02, leg, MeshKit.at(sx * 0.62, 0.36, sz * 0.42))
	k.rbox(Vector3(1.4, 0.06, 1.0), 0.02, leg, MeshKit.at(0, 0.72, 0))
	k.rbox(Vector3(1.3, 0.03, 0.9), 0.01, top, MeshKit.at(0, 0.765, 0))
	k.rbox(Vector3(1.3, 0.02, 0.04), 0.01, lit(Color(0.4, 0.9, 1.0), 0.4), MeshKit.at(0, 0.75, 0.48))
	return k.commit()


## The power dock by the router where couriers drop power cells.
static func power_dock(t: int) -> Mesh:
	var k := MeshKit.new()
	var c: Color = [Pal.WOOD, Color(0.78, 0.8, 0.84), Color(0.94, 0.95, 0.96), Color(0.62, 0.66, 0.72), Color(0.18, 0.19, 0.22)][t]
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.5, 0.08), 0.02, Pal.STEEL_DARK, MeshKit.at(sx * 0.55, 0.25, sz * 0.38))
	k.rbox(Vector3(1.3, 0.4, 0.95), 0.05, c, MeshKit.at(0, 0.62, 0))
	k.rbox(Vector3(1.2, 0.05, 0.85), 0.02, Color(0.24, 0.25, 0.28), MeshKit.at(0, 0.8, 0))
	k.rbox(Vector3(1.0, 0.04, 0.02), 0.01, lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.at(0, 0.55, 0.48))
	# a fat cable to the router
	k.cyl(0.05, 0.9, Color(0.2, 0.2, 0.22), MeshKit.xf(Vector3(0, 0.45, -0.45), Vector3(90, 0, 0)), 6)
	return k.commit()


## The server's floor and back wall (the stack itself is drawn on top). The
## floor covers the whole footprint (w x d metres); the wall runs along the back.
static func house(t: int, w: float, d: float) -> Mesh:
	var k := MeshKit.new()
	var floor_a: Color = [Color(0.66, 0.66, 0.64), Color(0.76, 0.76, 0.74), Color(0.88, 0.89, 0.9), Color(0.7, 0.74, 0.78), Color(0.24, 0.25, 0.28)][t]
	var floor_b: Color = floor_a.darkened(0.08)
	var wall: Color = [Color(0.8, 0.66, 0.46), Color(0.84, 0.82, 0.78), Color(0.95, 0.95, 0.96), Color(0.6, 0.64, 0.7), Color(0.94, 0.94, 0.92)][t]
	var trim: Color = [Pal.WOOD_DARK, Color(0.4, 0.42, 0.46), Color(0.3, 0.6, 0.66), Color(0.24, 0.25, 0.28), Pal.BRASS][t]
	# floor: concrete, then raised-floor tiles
	k.rbox(Vector3(w - 0.1, 0.12, d - 0.1), 0.05, trim, MeshKit.at(0, 0.06, 0))
	var nx := int(w / 1.0)
	var nz := int((d - 0.4) / 1.0)
	for i in nx:
		for j in nz:
			var c := floor_a if (i + j) % 2 == 0 or t == 0 else floor_b
			k.rbox(Vector3(0.96, 0.03, 0.96), 0.03 if t > 0 else 0.005, c, MeshKit.at(-w * 0.5 + 0.5 + i * (w - 0.2) / nx + 0.05, 0.13, -d * 0.5 + 0.7 + j * 1.0))
			if t >= 2 and (i * 3 + j) % 4 == 0:
				for q in 3:
					k.rbox(Vector3(0.6, 0.012, 0.04), 0.004, floor_a.darkened(0.18), MeshKit.at(-w * 0.5 + 0.55 + i * (w - 0.2) / nx, 0.146, -d * 0.5 + 0.55 + j * 1.0 + q * 0.12))
	# back wall
	var h := 2.6 + t * 0.3
	k.rbox(Vector3(w, h, 0.35), 0.06, wall, MeshKit.at(0, h * 0.5 + 0.1, -d * 0.5 + 0.2))
	match t:
		0:
			# plywood sheets, a pegboard with tools, a roll-up garage door
			for i in int(w / 1.2):
				k.rbox(Vector3(0.02, h, 0.37), 0.005, wall.darkened(0.18), MeshKit.at(-w * 0.5 + 1.2 * (i + 1), h * 0.5 + 0.1, -d * 0.5 + 0.2))
			k.rbox(Vector3(1.6, 0.9, 0.04), 0.02, Color(0.82, 0.72, 0.54), MeshKit.at(-w * 0.5 + 1.4, 1.6, -d * 0.5 + 0.39))
			for i in 4:
				k.rbox(Vector3(0.05, 0.3, 0.04), 0.01, [Pal.STEEL, Color(0.86, 0.3, 0.26), Pal.STEEL_DARK, Color(0.96, 0.78, 0.26)][i], MeshKit.xf(Vector3(-w * 0.5 + 0.9 + i * 0.32, 1.6, -d * 0.5 + 0.43), Vector3(0, 0, -10 + i * 8)))
			k.rbox(Vector3(2.2, 2.0, 0.06), 0.03, Color(0.86, 0.86, 0.84), MeshKit.at(w * 0.5 - 1.6, 1.1, -d * 0.5 + 0.4))
			for i in 8:
				k.rbox(Vector3(2.2, 0.02, 0.07), 0.005, Color(0.7, 0.7, 0.68), MeshKit.at(w * 0.5 - 1.6, 0.2 + i * 0.24, -d * 0.5 + 0.41))
		1:
			# painted drywall with a cable tray along the top
			k.rbox(Vector3(w - 0.4, 0.12, 0.3), 0.02, Color(0.4, 0.42, 0.46), MeshKit.at(0, h - 0.2, -d * 0.5 + 0.5))
			for i in 3:
				k.cyl(0.03, w - 0.5, [Color(0.3, 0.5, 0.86), Color(0.94, 0.7, 0.3), Color(0.24, 0.24, 0.28)][i], MeshKit.xf(Vector3(-w * 0.5 + 0.25, h - 0.12, -d * 0.5 + 0.42 + i * 0.07), Vector3(0, 0, -90)), 6)
		2:
			# white panels with a teal band
			for i in int(w / 0.8):
				k.rbox(Vector3(0.02, h - 0.2, 0.37), 0.005, wall.darkened(0.08), MeshKit.at(-w * 0.5 + 0.8 * (i + 1), h * 0.5, -d * 0.5 + 0.2))
			k.rbox(Vector3(w + 0.02, 0.14, 0.37), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(0, 1.0, -d * 0.5 + 0.2))
		3:
			# steel wall with cable trays and blue strip lights
			for r in 2:
				k.rbox(Vector3(w - 0.4, 0.1, 0.34), 0.02, Color(0.3, 0.32, 0.36), MeshKit.at(0, h - 0.3 - r * 0.7, -d * 0.5 + 0.5))
				k.rbox(Vector3(w - 0.5, 0.03, 0.03), 0.01, lit(Color(0.4, 0.75, 1.0), 0.45), MeshKit.at(0, h - 0.38 - r * 0.7, -d * 0.5 + 0.66))
		4:
			# white stone with glass windows and brass fins
			for i in int(w / 1.0):
				k.rbox(Vector3(0.06, h, 0.42), 0.02, Pal.BRASS, MeshKit.at(-w * 0.5 + 1.0 * (i + 0.5), h * 0.5 + 0.1, -d * 0.5 + 0.25))
	k.rbox(Vector3(w + 0.2, 0.18, 0.55), 0.04, trim, MeshKit.at(0, h + 0.15, -d * 0.5 + 0.25))
	for x in [-w * 0.5 + 0.9, w * 0.5 - 0.9]:
		if t == 0 and x > 0.0:
			continue
		TownArt.window(k, Vector3(x, h * 0.62, -d * 0.5 + 0.4), 0.8, 0.9, trim, Color(0.6, 0.86, 0.96, 0.6) if t >= 3 else Color(0.6, 0.72, 0.78))
	# a sign with the lab's logo: a glowing token mark
	k.rbox(Vector3(2.2, 0.75, 0.12), 0.2, trim, MeshKit.at(0, h + 0.75, -d * 0.5 + 0.25))
	k.rbox(Vector3(2.0, 0.6, 0.13), 0.16, Color(0.14, 0.15, 0.18) if t != 0 else Color(0.96, 0.95, 0.92), MeshKit.at(0, h + 0.75, -d * 0.5 + 0.26))
	Items.token_into(k, ["pico", "chat7", "wiki13", "align70", "frontier"][t], 0.22, 0.05, MeshKit.xf(Vector3(-0.6, h + 0.75, -d * 0.5 + 0.34), Vector3(90, 0, 0)))
	for i in 3:
		k.rbox(Vector3(0.7 - i * 0.18, 0.06, 0.02), 0.02, lit(Color(0.5, 0.9, 1.0), 0.45) if t != 0 else Color(0.3, 0.32, 0.36), MeshKit.at(0.35, h + 0.92 - i * 0.14, -d * 0.5 + 0.335))
	# side posts and a low front rail with a gap in the middle
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.22, h + 0.3, 0.22), 0.04, trim, MeshKit.at(sx * (w * 0.5 - 0.15), (h + 0.3) * 0.5, -d * 0.5 + 0.3))
		k.rbox(Vector3(w * 0.5 - 1.4, 0.08, 0.08), 0.02, trim, MeshKit.at(sx * (w * 0.25 + 0.6), 0.75, d * 0.5 - 0.15))
		for i in 4:
			k.rbox(Vector3(0.08, 0.7, 0.08), 0.02, trim, MeshKit.at(sx * (1.3 + i * (w * 0.5 - 1.5) / 3.0), 0.4, d * 0.5 - 0.15))
	if t >= 3:
		for sx in [-1.0, 1.0]:
			TownArt.lamp_post(k, Vector3(sx * (w * 0.5 - 0.35), 0, d * 0.5 - 0.35), 2.0)
	if t >= 4:
		k.cone(0.5, 0.8, Pal.BRASS, MeshKit.at(0, h + 1.15, -d * 0.5 + 0.25), 12)
		k.sphere(0.16, lit(Color(0.5, 0.95, 0.95), 0.4), MeshKit.at(0, h + 2.0, -d * 0.5 + 0.25), 10, 6)
	return k.commit()
