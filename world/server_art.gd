class_name ServerArt
## Looks for the inference server. Five tiers, five different buildings
## around the same serving stack (router -> glass request bus under the GPU
## trays -> GPU core, power dock and coolant bench in front):
##   0 garage        a plywood garage, roll-up door rolled up, a lean-to
##                   tin roof, workbench, pegboard, fridge, a giant gaming PC
##                   on pallets, string lights, a bike and pizza boxes
##   1 server closet a prefab steel shed with a shipping-container office on
##                   top, raised floor, chain-link cage, racks, UPS, split AC
##   2 server room   a white two-storey clean room: glass upper floor, teal
##                   bands, white racks, suppression tanks, CRAC units,
##                   screened roof plant, planters, a logo sign
##   3 data hall     a tall steel hall: trusses, louvred walls, a stair tower,
##                   catwalk, roof chillers, pipe racks, generator and
##                   transformer yard, blue LEDs, a security fence
##   4 hyperscale    a graphite and brass tower: glowing fins, liquid-cooling
##                   loops up to rooftop dry coolers, a cantilevered crown
##                   floor, sky bridge, drone pad, beacons, a hologram
## Layout (building local, front = +Z, lot 10 x 6 m): the stack runs along
## z = -1.3; the front-centre stays open (couriers throw in from the road,
## engineers walk up to the trays). Big volumes keep behind z = -2.2 at the
## ground and behind z = -1.7 above 3.6 m, so the 58-degree camera always sees
## the stack and the labels over the core.

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


static func at(x: float, y: float, z: float) -> Transform3D:
	return MeshKit.at(x, y, z)


static func xf(p: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return MeshKit.xf(p, rot, scl)


# ---------------------------------------------------------------- helpers

## A sharp box at p (rotation in degrees).
static func _b(k: MeshKit, s: Vector3, c: Color, p: Vector3, r := Vector3.ZERO) -> void:
	k.box(s, c, xf(p, r))


## A box beam from a to b with cross-section th (width, height).
static func _beam(k: MeshKit, a: Vector3, b: Vector3, th: Vector2, c: Color) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.01:
		return
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var pitch := -rad_to_deg(asin(clampf(d.y / len, -1.0, 1.0)))
	k.box(Vector3(th.x, th.y, len), c, xf((a + b) * 0.5, Vector3(pitch, yaw, 0)))


## A round tube through points (cheap: few sides, joint knuckles optional).
static func _tube(k: MeshKit, pts: Array, r: float, c: Color, segs := 6, joints := true) -> void:
	for i in pts.size() - 1:
		var a: Vector3 = pts[i]
		var b: Vector3 = pts[i + 1]
		var d := b - a
		var len := d.length()
		if len < 0.01:
			continue
		var n := d / len
		var basis := Basis(Quaternion(Vector3.UP, n)) if absf(n.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if n.y > 0 else Basis(Vector3.RIGHT, PI))
		k.cyl(r, len, c, Transform3D(basis, a), segs, 0.0, -1.0, false)
		if joints and i > 0:
			k.box(Vector3.ONE * r * 2.1, c, at(a.x, a.y, a.z))


## Horizontal boards along x (a wall facing z), from y = y0, h tall.
static func _boards_x(k: MeshKit, x0: float, x1: float, z: float, y0: float, h: float, c: Color, th := 0.05, bh := 0.2) -> void:
	var n := maxi(1, int(ceil(h / bh)))
	for j in n:
		var sh := c.darkened(0.045 * ((j * 7) % 3))
		k.box(Vector3(x1 - x0, h / n - 0.018, th), sh, at((x0 + x1) * 0.5, y0 + (j + 0.5) * h / n, z))


## Horizontal boards along z (a wall facing x).
static func _boards_z(k: MeshKit, z0: float, z1: float, x: float, y0: float, h: float, c: Color, th := 0.05, bh := 0.2) -> void:
	var n := maxi(1, int(ceil(h / bh)))
	for j in n:
		var sh := c.darkened(0.045 * ((j * 5) % 3))
		k.box(Vector3(th, h / n - 0.018, z1 - z0), sh, at(x, y0 + (j + 0.5) * h / n, (z0 + z1) * 0.5))


## Vertical ribs (corrugated sheet) on a wall facing +z or -z (dir), x0..x1.
static func _ribs_x(k: MeshKit, x0: float, x1: float, z: float, y0: float, h: float, c: Color, dir := 1.0, pitch := 0.2) -> void:
	k.box(Vector3(x1 - x0, h, 0.04), c, at((x0 + x1) * 0.5, y0 + h * 0.5, z))
	var n := maxi(1, int((x1 - x0) / pitch))
	for i in n:
		k.box(Vector3(0.05, h, 0.03), c.darkened(0.1), at(x0 + (i + 0.5) * (x1 - x0) / n, y0 + h * 0.5, z + dir * 0.03))


## Vertical ribs on a wall facing +x or -x (dir), z0..z1.
static func _ribs_z(k: MeshKit, z0: float, z1: float, x: float, y0: float, h: float, c: Color, dir := 1.0, pitch := 0.2) -> void:
	k.box(Vector3(0.04, h, z1 - z0), c, at(x, y0 + h * 0.5, (z0 + z1) * 0.5))
	var n := maxi(1, int((z1 - z0) / pitch))
	for i in n:
		k.box(Vector3(0.03, h, 0.05), c.darkened(0.1), at(x + dir * 0.03, y0 + h * 0.5, z0 + (i + 0.5) * (z1 - z0) / n))


## A row of tiny status LEDs (blinking ports) on a face facing +z.
static func _leds(k: MeshKit, x0: float, y: float, z: float, n: int, gap: float, cols: Array, seed := 0) -> void:
	for i in n:
		var c: Color = cols[(i * 7 + seed * 3) % cols.size()]
		k.box(Vector3(0.035, 0.025, 0.012), lit(c, 0.4), at(x0 + i * gap, y, z))


## A 19-inch rack cabinet (front facing +z) of height h at p (base centre):
## a frame, a perforated door look, servers with status lights.
static func _rack(k: MeshKit, p: Vector3, h: float, body: Color, face: Color, led: Array, w := 0.6, d := 0.6, seed := 0, units := 7) -> void:
	k.box(Vector3(w, h, d), body, at(p.x, p.y + h * 0.5, p.z))
	k.box(Vector3(w + 0.02, 0.05, d + 0.02), body.darkened(0.25), at(p.x, p.y + h - 0.025, p.z))
	k.box(Vector3(w + 0.02, 0.06, d + 0.02), body.darkened(0.3), at(p.x, p.y + 0.03, p.z))
	var fz := p.z + d * 0.5
	var uh := (h - 0.2) / units
	for i in units:
		var y := p.y + 0.12 + (i + 0.5) * uh
		k.box(Vector3(w - 0.08, uh - 0.025, 0.02), face if (i + seed) % 3 != 0 else face.lightened(0.12), at(p.x, y, fz + 0.005))
		_leds(k, p.x - w * 0.5 + 0.08, y + uh * 0.2, fz + 0.02, 4, 0.05, led, seed + i)
		k.box(Vector3(w * 0.4, 0.012, 0.01), face.darkened(0.3), at(p.x + w * 0.12, y - uh * 0.15, fz + 0.02))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.025, h - 0.1, 0.03), body.lightened(0.15), at(p.x + sx * (w * 0.5 - 0.0125), p.y + h * 0.5, fz + 0.01))


## A tall cardboard/plastic box stack (seeded), standing on y0.
static func _boxes(k: MeshKit, p: Vector3, n: int, cols: Array, seed := 0, s := 0.3) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 977 * (seed + 5)
	var y := p.y
	for i in n:
		var sz := Vector3(r.randf_range(0.7, 1.0) * s, r.randf_range(0.5, 0.8) * s, r.randf_range(0.7, 1.0) * s)
		var c: Color = cols[r.randi_range(0, cols.size() - 1)]
		k.box(sz, c, xf(Vector3(p.x + r.randf_range(-0.03, 0.03), y + sz.y * 0.5, p.z + r.randf_range(-0.03, 0.03)), Vector3(0, r.randf_range(-14, 14), 0)))
		k.box(Vector3(sz.x + 0.004, 0.03, 0.05), c.darkened(0.2), at(p.x, y + sz.y - 0.02, p.z))
		y += sz.y


## A small potted shrub (cheap).
static func _shrub(k: MeshKit, p: Vector3, r: float, c := Color(0.42, 0.6, 0.36)) -> void:
	k.sphere(r, c, xf(p + Vector3(0, r * 0.8, 0), Vector3.ZERO, Vector3(1, 0.85, 1)), 7, 4)
	k.sphere(r * 0.6, c.lightened(0.08), at(p.x + r * 0.4, p.y + r * 1.25, p.z + r * 0.2), 6, 3)


## A bicycle along x (wheels in the xy plane), base at p.
static func _bike(k: MeshKit, p: Vector3, c: Color, yaw := 0.0) -> void:
	var b := xf(p, Vector3(0, yaw, 0))
	var tyre := Color(0.12, 0.12, 0.13)
	for sx in [-0.42, 0.42]:
		k.torus(0.3, 0.03, tyre, b * xf(Vector3(sx, 0.33, 0), Vector3(90, 0, 0)), 14, 4)
		k.box(Vector3(0.04, 0.04, 0.06), Color(0.7, 0.72, 0.74), b * at(sx, 0.33, 0))
	k.box(Vector3(0.6, 0.035, 0.035), c, b * xf(Vector3(0.0, 0.55, 0), Vector3(0, 0, -8)))
	k.box(Vector3(0.5, 0.035, 0.035), c, b * xf(Vector3(-0.08, 0.42, 0), Vector3(0, 0, 32)))
	k.box(Vector3(0.035, 0.42, 0.035), c, b * xf(Vector3(-0.2, 0.48, 0), Vector3(0, 0, 12)))
	k.box(Vector3(0.035, 0.44, 0.035), c, b * xf(Vector3(0.32, 0.5, 0), Vector3(0, 0, -18)))
	k.box(Vector3(0.48, 0.03, 0.03), c, b * xf(Vector3(-0.24, 0.36, 0), Vector3(0, 0, -15)))
	k.box(Vector3(0.22, 0.05, 0.1), Color(0.15, 0.15, 0.16), b * at(-0.24, 0.72, 0))
	k.box(Vector3(0.04, 0.03, 0.46), Color(0.2, 0.2, 0.22), b * at(0.36, 0.76, 0))
	k.cyl(0.06, 0.03, Color(0.4, 0.42, 0.44), b * xf(Vector3(-0.05, 0.33, 0), Vector3(90, 0, 0)), 8)


# ---------------------------------------------------------------- frame

## Rack frame under a bus segment of length len (centred on x).
static func frame(len: float) -> Mesh:
	var k := MeshKit.new()
	var steel := Color(0.22, 0.23, 0.26)
	var n := maxi(2, int(round(len / 1.0)) + 1)
	for i in n:
		var x := -len * 0.5 + 0.18 + (len - 0.36) * i / (n - 1)
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.1, Y - 0.45, 0.1), steel, at(x, (Y - 0.45) * 0.5, sz * 0.55))
			k.box(Vector3(0.22, 0.04, 0.22), steel, at(x, 0.02, sz * 0.55))
			k.box(Vector3(0.08, 1.0, 0.06), steel, at(x, Y, sz * 0.54))
			k.box(Vector3(0.05, 0.05, 0.02), lit(Color(0.4, 0.9, 1.0), 0.4), at(x, Y + 0.48, sz * 0.56))
		for sy in [-1.0, 1.0]:
			k.box(Vector3(0.08, 0.06, 1.14), steel, at(x, Y + sy * 0.48, 0))
		k.box(Vector3(0.04, 0.04, 1.2), steel.lightened(0.1), xf(Vector3(x, (Y - 0.45) * 0.5, 0), Vector3(-33, 0, 0)))
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(len, 0.04, 0.04), steel, at(0, Y + sy * 0.48, sz * 0.54))
	k.box(Vector3(len, 0.08, 1.04), steel, at(0, Y - 0.5, 0))
	k.box(Vector3(len - 0.1, 0.03, 0.03), lit(Color(0.36, 0.86, 0.96), 0.4), at(0, Y - 0.45, 0.56))
	k.box(Vector3(len, 0.04, 1.7), Color(0.5, 0.52, 0.56), at(0, 0.02, 0.0))
	# cables under the bus
	for i in 3:
		k.box(Vector3(len - 0.2, 0.05, 0.05), [Color(0.3, 0.5, 0.86), Color(0.94, 0.7, 0.3), Color(0.24, 0.24, 0.28)][i], at(0, 0.14 + i * 0.03, -0.2 + i * 0.09))
	return k.commit()


# ---------------------------------------------------------------- router

## The request router behind the start of the bus (local origin = module
## centre, bus at z = TZ). Requests come out of its port into the bus.
static func router(t: int) -> Mesh:
	var k := MeshKit.new()
	match t:
		0: _router0(k)
		1: _router1(k)
		2: _router2(k)
		3: _router3(k)
		_: _router4(k)
	# the port where requests drop into the bus
	k.box(Vector3(0.5, 0.2, 0.5), Color(0.22, 0.23, 0.26), at(0.55, Y + 0.45, TZ))
	k.box(Vector3(0.3, 0.04, 0.3), lit(Color(0.4, 0.9, 1.0), 0.4), at(0.55, Y + 0.56, TZ))
	return k.commit()


## Garage: a plywood desk with two monitors, a consumer Wi-Fi router with
## antennas on a milk-crate stack, a gaming chair, cans and a ceiling fan rod.
static func _router0(k: MeshKit) -> void:
	var z := TZ
	var ply := Color(0.8, 0.66, 0.46)
	var dark := Color(0.13, 0.13, 0.15)
	# trestle desk
	k.box(Vector3(1.25, 0.05, 0.8), ply, at(-0.05, 0.76, z - 0.05))
	k.box(Vector3(1.25, 0.012, 0.8), ply.darkened(0.1), at(-0.05, 0.734, z - 0.05))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.05, 0.76, 0.05), Pal.WOOD_DARK, xf(Vector3(-0.05 + sx * 0.52, 0.37, z - 0.05 + sz * 0.28), Vector3(sz * 8, 0, 0)))
		k.box(Vector3(0.05, 0.05, 0.6), Pal.WOOD_DARK, at(-0.05 + sx * 0.52, 0.3, z - 0.05))
	k.box(Vector3(1.04, 0.05, 0.05), Pal.WOOD_DARK, at(-0.05, 0.3, z - 0.05))
	# two monitors with glowing screens
	for m in 2:
		var mx := -0.4 + m * 0.5
		var w := 0.56 if m == 0 else 0.44
		var yaw := 10.0 if m == 0 else -14.0
		var base := xf(Vector3(mx, 0.79, z - 0.22), Vector3(0, yaw, 0))
		k.box(Vector3(0.2, 0.02, 0.14), dark, base * at(0, 0.01, 0))
		k.box(Vector3(0.04, 0.24, 0.03), dark, base * at(0, 0.13, -0.02))
		k.box(Vector3(w, w * 0.6, 0.04), dark, base * at(0, 0.24 + w * 0.3, 0))
		k.box(Vector3(w - 0.05, w * 0.6 - 0.05, 0.01), lit(Color(0.42, 0.72, 1.0) if m == 0 else Color(0.6, 1.0, 0.7), 0.5), base * at(0, 0.24 + w * 0.3, 0.022))
		for i in 4:
			k.box(Vector3(w * (0.5 - i * 0.08), 0.015, 0.005), Color(0.9, 0.95, 1.0), base * at(-w * 0.15, 0.3 + w * 0.42 - i * 0.05, 0.03))
		k.box(Vector3(0.07, 0.07, 0.005), Color(0.98, 0.9, 0.4), base * xf(Vector3(w * 0.5 - 0.02, 0.27, 0.03), Vector3(0, 0, 8)))
	# keyboard with an RGB strip, mouse, pad, cans, mug, headset
	k.box(Vector3(0.44, 0.025, 0.14), dark, at(-0.2, 0.8, z + 0.12))
	k.box(Vector3(0.42, 0.006, 0.02), lit(Color(1.0, 0.4, 0.8), 0.45), at(-0.2, 0.815, z + 0.18))
	for i in 4:
		k.box(Vector3(0.4, 0.006, 0.018), Color(0.26, 0.26, 0.3), at(-0.2, 0.815, z + 0.07 + i * 0.026))
	k.box(Vector3(0.24, 0.006, 0.2), Color(0.2, 0.22, 0.4), at(0.2, 0.788, z + 0.12))
	k.box(Vector3(0.05, 0.03, 0.08), dark, at(0.2, 0.8, z + 0.12))
	for i in 3:
		k.cyl(0.03, 0.12, [Color(0.3, 0.8, 0.3), Color(0.25, 0.3, 0.9), Color(0.3, 0.8, 0.3)][i], at(0.42 + i * 0.07, 0.785, z + 0.22 - i * 0.05), 6)
	k.cyl(0.04, 0.09, Color(0.92, 0.9, 0.86), at(-0.52, 0.785, z + 0.15), 6)
	k.torus(0.1, 0.02, Color(0.15, 0.15, 0.17), xf(Vector3(0.38, 0.9, z - 0.25), Vector3(90, 0, 0)), 10, 4, PI)
	k.box(Vector3(0.03, 0.12, 0.03), dark, at(0.38, 0.84, z - 0.25))
	# pizza box on the desk corner
	k.box(Vector3(0.36, 0.05, 0.36), Color(0.86, 0.74, 0.54), xf(Vector3(-0.45, 0.81, z + 0.12), Vector3(0, 12, 0)))
	k.box(Vector3(0.2, 0.006, 0.12), Color(0.8, 0.3, 0.24), xf(Vector3(-0.45, 0.836, z + 0.12), Vector3(0, 12, 0)))
	# under the desk: a subwoofer, a power strip, a cable tangle
	k.box(Vector3(0.3, 0.32, 0.3), dark, at(-0.35, 0.16, z - 0.15))
	k.cyl(0.09, 0.02, Color(0.3, 0.3, 0.32), xf(Vector3(-0.35, 0.18, z), Vector3(90, 0, 0)), 8)
	k.box(Vector3(0.4, 0.04, 0.07), Color(0.92, 0.92, 0.9), at(0.1, 0.03, z + 0.1))
	for i in 4:
		k.box(Vector3(0.03, 0.02, 0.03), Color(0.95, 0.5, 0.2) if i % 2 == 0 else dark, at(-0.05 + i * 0.1, 0.06, z + 0.1))
	_tube(k, [Vector3(0.1, 0.05, z + 0.1), Vector3(0.1, 0.05, z - 0.2), Vector3(-0.1, 0.4, z - 0.4), Vector3(-0.1, 0.78, z - 0.4)], 0.015, dark, 4, false)
	# milk crates up to the port, a consumer Wi-Fi router and a modem on top
	for i in 3:
		var y := 0.0 + i * 0.32
		var cc: Color = [Color(0.86, 0.3, 0.26), Color(0.26, 0.44, 0.8), Color(0.95, 0.75, 0.25)][i]
		k.box(Vector3(0.4, 0.3, 0.38), cc, at(0.55, y + 0.15 + (0.79 if i > 0 else 0.0) * 0.0, z + 0.3))
		for j in 3:
			k.box(Vector3(0.41, 0.03, 0.39), cc.darkened(0.25), at(0.55, y + 0.05 + j * 0.1, z + 0.3))
	k.box(Vector3(0.36, 0.06, 0.24), Color(0.95, 0.95, 0.96), at(0.55, 1.0, z + 0.3))
	for i in 4:
		k.box(Vector3(0.02, 0.32, 0.02), Color(0.9, 0.9, 0.92), xf(Vector3(0.4 + i * 0.1, 1.17, z + 0.22), Vector3(-10 + i * 7, 0, -12 + i * 8)))
	_leds(k, 0.45, 1.0, z + 0.425, 5, 0.05, [Color(0.4, 1.0, 0.5), Color(0.4, 0.8, 1.0)])
	k.box(Vector3(0.08, 0.3, 0.2), Color(0.18, 0.18, 0.2), at(0.3, 0.94, z + 0.3))
	# the port: a little switch on a bracket
	k.box(Vector3(0.05, 0.5, 0.05), Pal.STEEL_DARK, at(0.55, 1.36, z - 0.05))
	# gaming chair in front of the desk
	var red := Color(0.8, 0.22, 0.24)
	var cz := z + 0.85
	for i in 5:
		var a := TAU * i / 5.0
		k.box(Vector3(0.03, 0.03, 0.3), dark, xf(Vector3(-0.15 + sin(a) * 0.13, 0.05, cz + cos(a) * 0.13), Vector3(0, rad_to_deg(a), 0)))
	k.cyl(0.03, 0.4, Color(0.5, 0.52, 0.55), at(-0.15, 0.05, cz), 6)
	k.box(Vector3(0.5, 0.09, 0.48), dark, at(-0.15, 0.47, cz))
	k.box(Vector3(0.36, 0.02, 0.4), red, at(-0.15, 0.52, cz))
	k.box(Vector3(0.5, 0.8, 0.09), dark, xf(Vector3(-0.15, 0.9, cz + 0.26), Vector3(-10, 0, 0)))
	k.box(Vector3(0.12, 0.7, 0.02), red, xf(Vector3(-0.15, 0.9, cz + 0.21), Vector3(-10, 0, 0)))
	k.box(Vector3(0.3, 0.12, 0.08), red, xf(Vector3(-0.15, 1.18, cz + 0.2), Vector3(-10, 0, 0)))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.2, 0.3), dark, at(-0.15 + sx * 0.26, 0.6, cz))
	# the ceiling fan's down-rod and box
	k.cyl(0.02, 0.3, Color(0.3, 0.3, 0.32), at(0, 2.5, z), 6)
	k.box(Vector3(0.12, 0.04, 0.12), Color(0.3, 0.3, 0.32), at(0, 2.8, z))


## Height of the router's spinning fan for a tier (local y).
static func fan_y(t: int) -> float:
	return fan_pos(t).y


## Where the router's fan spins, relative to (ROUTER_X, 0, BUS_Z).
static func fan_pos(t: int) -> Vector3:
	match t:
		0: return Vector3(0, 2.5, 0)
		1: return Vector3(0, 2.32, 0)
		2: return Vector3(0, 2.36, 0)
		3: return Vector3(0, 2.62, 0)
	return Vector3(0, 2.8, 0)


## The router's cooling fan (spins while routing).
static func fan() -> Mesh:
	return fan_mesh(1)


## The spinning fan for a tier: a garage ceiling fan, then rack fans.
static func fan_mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	if t == 0:
		k.cyl(0.11, 0.14, Color(0.5, 0.36, 0.22), at(0, -0.1, 0), 10)
		k.cyl(0.06, 0.06, Color(0.42, 0.3, 0.2), at(0, 0.04, 0), 8)
		for i in 5:
			var b := xf(Vector3.ZERO, Vector3(0, i * 72, 0))
			k.box(Vector3(0.03, 0.02, 0.16), Color(0.3, 0.3, 0.32), b * at(0, -0.04, 0.14))
			k.box(Vector3(0.13, 0.015, 0.46), Color(0.62, 0.44, 0.28), b * xf(Vector3(0, -0.04, 0.42), Vector3(0, 0, 8)))
		k.sphere(0.08, lit(Color(1.0, 0.86, 0.6), 0.4), at(0, -0.16, 0), 8, 4)
		return k.commit()
	k.cyl(0.24, 0.04, Color(0.26, 0.27, 0.3), at(0, -0.02, 0), 16)
	for i in 5:
		k.box(Vector3(0.06, 0.02, 0.2), Color(0.82, 0.84, 0.88), xf(Vector3.ZERO, Vector3(0, i * 72, 12)) * at(0, 0.03, 0.11))
	k.cyl(0.05, 0.05, lit(Color(0.4, 0.9, 1.0), 0.4), at(0, 0.02, 0), 8)
	return k.commit()


# ---------------------------------------------------------------- module bays

## A module bay over the bus, fed with one resource (its colour band says
## which; "" = an empty bay, grey).
static func module(ing: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var c: Color = Defs.ITEMS[ing]["color"] if Defs.ITEMS.has(ing) else Color(0.46, 0.48, 0.52)
	match t:
		0:
			k.cyl(0.1, 0.18, Pal.STEEL_DARK, at(0, 0, 0), 10, 0.02)
			k.rbox(Vector3(0.8, 0.5, 0.7), 0.06, Color(0.86, 0.88, 0.9), at(0, 0.5, 0))
			k.box(Vector3(0.82, 0.1, 0.72), c, at(0, 0.62, 0))
			k.box(Vector3(0.84, 0.05, 0.74), Color(0.3, 0.32, 0.36), at(0, 0.77, 0))
		1:
			k.cyl(0.12, 0.18, Pal.STEEL_DARK, at(0, 0, 0), 12, 0.02)
			k.rbox(Vector3(0.82, 0.9, 0.78), 0.05, Color(0.78, 0.8, 0.84), at(0, 0.62, 0))
			k.box(Vector3(0.84, 0.12, 0.8), c, at(0, 0.9, 0))
			k.box(Vector3(0.6, 0.05, 0.01), lit(c.lightened(0.3), 0.4), at(0, 0.5, 0.395))
			for i in 4:
				k.box(Vector3(0.6, 0.02, 0.01), Color(0.5, 0.52, 0.56), at(0, 0.35 + i * 0.06, 0.393))
		_:
			var shell: Color = [Color(0.94, 0.95, 0.96), Color(0.94, 0.95, 0.96), Color(0.62, 0.66, 0.72), Color(0.18, 0.19, 0.22)][t - 1]
			var band: Color = Pal.BRASS if t == 4 else Color(0.3, 0.32, 0.36)
			k.cyl(0.12, 0.18, Pal.STEEL_DARK, at(0, 0, 0), 12, 0.02)
			k.rbox(Vector3(0.84, 1.5, 0.8), 0.08, shell, at(0, 0.92, 0))
			k.box(Vector3(0.86, 0.18, 0.82), c, at(0, 1.2, 0))
			for y in [0.26, 1.66]:
				k.box(Vector3(0.88, 0.05, 0.84), band, at(0, y, 0))
			k.box(Vector3(0.08, 0.8, 0.01), lit(c.lightened(0.25), 0.4), at(-0.28, 0.7, 0.405))
			for i in 6:
				k.box(Vector3(0.4, 0.025, 0.012), shell.darkened(0.2), at(0.12, 0.4 + i * 0.1, 0.402))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.03, 1.3, 0.03), Pal.STEEL_DARK, at(0.44, 0.95, sx * 0.12))
			for i in 6:
				k.box(Vector3(0.03, 0.02, 0.24), Pal.STEEL_DARK, at(0.45, 0.4 + i * 0.2, 0))
	return k.commit()


## A GPU tray over the bus holding n of 3 accelerator boards (n = 0: an
## empty slot, waiting for a courier to bring a GPU). Dead boards (failed,
## waiting for a replacement) show dark with a red light.
static func gpu_tray(n: int, dead: int, t: int) -> Mesh:
	var k := MeshKit.new()
	var shell: Color = [Pal.WOOD, Color(0.62, 0.64, 0.68), Color(0.9, 0.91, 0.93), Color(0.42, 0.45, 0.5), Color(0.18, 0.19, 0.22)][t]
	var trim: Color = Pal.BRASS if t == 4 else Color(0.3, 0.32, 0.36)
	var glow: Color = [Color(0.5, 1.0, 0.6), Color(0.5, 1.0, 0.6), Color(0.42, 0.96, 0.9), Color(0.45, 0.75, 1.0), Color(1.0, 0.86, 0.5)][t]
	k.cyl(0.1, 0.14, Pal.STEEL_DARK, at(0, 0, 0), 8)
	k.box(Vector3(0.84, 0.06, 0.78), trim, at(0, 0.16, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.86, 0.78), shell, at(sx * 0.41, 0.58, 0))
		for i in 3:
			k.box(Vector3(0.012, 0.02, 0.7), shell.darkened(0.2), at(sx * 0.44, 0.34 + i * 0.25, 0))
	k.box(Vector3(0.84, 0.05, 0.78), trim, at(0, 1.02, 0))
	k.box(Vector3(0.6, 0.012, 0.012), lit(glow, 0.45), at(0, 1.05, 0.39))
	for i in 3:
		var y := 0.3 + i * 0.25
		if i < n:
			var ok := i >= dead
			k.box(Vector3(0.74, 0.18, 0.7), Color(0.16, 0.17, 0.2), at(0, y, 0))
			k.box(Vector3(0.6, 0.02, 0.72), Color(0.3, 0.62, 0.42) if ok else Color(0.3, 0.3, 0.32), at(0, y + 0.1, 0))
			for fx in [-0.18, 0.18]:
				k.cyl(0.08, 0.02, Color(0.3, 0.32, 0.36), xf(Vector3(fx, y, 0.355), Vector3(90, 0, 0)), 8)
				k.box(Vector3(0.12, 0.012, 0.01), Color(0.5, 0.52, 0.56), at(fx, y, 0.37))
			k.box(Vector3(0.66, 0.025, 0.01), lit(Color(0.5, 1.0, 0.6), 0.35) if ok else lit(Color(1.0, 0.3, 0.25), 0.4), at(0, y - 0.06, 0.356))
		else:
			k.box(Vector3(0.7, 0.02, 0.66), shell.darkened(0.25), at(0, y - 0.08, 0))
	return k.commit()


## HBM stacks on a shelf (n of `slots` filled).
static func hbm_shelf(n: int, slots: int, t: int) -> Mesh:
	var k := MeshKit.new()
	var c: Color = [Pal.WOOD, Color(0.62, 0.64, 0.68), Color(0.9, 0.91, 0.93), Color(0.42, 0.45, 0.5), Color(0.18, 0.19, 0.22)][t]
	var rows := maxi(2, ceili(slots / 4.0))
	k.box(Vector3(1.3, 0.06, 0.06 + rows * 0.22), c, at(0, 0.0, (rows - 2) * 0.11))
	for i in slots:
		var x := -0.54 + (i % 4) * 0.36
		var z := -0.1 + (i / 4) * 0.22
		if i < n:
			k.box(Vector3(0.26, 0.22, 0.14), Defs.ITEMS["hbm"]["color"], at(x, 0.14, z))
			k.box(Vector3(0.2, 0.02, 0.01), lit(Color(0.5, 0.86, 1.0), 0.35), at(x, 0.2, z + 0.072))
		else:
			k.box(Vector3(0.26, 0.015, 0.14), c.darkened(0.3), at(x, 0.04, z))
	return k.commit()


## Height of the top of a module for a tier (where its sign floats).
static func module_top(t: int) -> float:
	return [0.85, 1.0, 1.75, 1.75, 1.75][t]


# ---------------------------------------------------------------- GPU core

## The GPU core. Local origin = core module centre; the bus enters on -X at
## z = TZ and requests disappear into it. Tokens come out of its vent.
static func core(t: int) -> Mesh:
	var k := MeshKit.new()
	match t:
		0: _core0(k)
		1: _core1(k)
		2: _core2(k)
		3: _core3(k)
		_: _core4(k)
	# bus inlet on the west side
	k.box(Vector3(0.3, 1.0, 1.1), Color(0.22, 0.23, 0.26), at(-1.85, Y, TZ))
	k.box(Vector3(0.32, 0.06, 1.12), lit(Color(0.4, 0.9, 1.0), 0.4), at(-1.85, Y + 0.45, TZ))
	return k.commit()


## Garage: a giant gaming tower on two pallets, side open to its RGB guts,
## top exhaust fans (the vent), a cat asleep on it, a desk fan aimed at it.
static func _core0(k: MeshKit) -> void:
	var z := TZ
	var cx := -0.25
	var pine := Color(0.78, 0.64, 0.44)
	# two pallets
	for p in 2:
		var px := cx - 0.66 + p * 1.32
		for i in 3:
			k.box(Vector3(1.26, 0.1, 0.1), pine.darkened(0.15), at(px, 0.05, z - 0.42 + i * 0.42))
		for i in 6:
			k.box(Vector3(0.18, 0.025, 0.96), pine if i % 2 == 0 else pine.darkened(0.06), at(px - 0.55 + i * 0.22, 0.112, z))
		for i in 3:
			k.box(Vector3(0.1, 0.06, 0.1), pine.darkened(0.2), at(px - 0.55 + i * 0.55, 0.09, z + 0.42))
	var y0 := 0.125
	var case_c := Color(0.1, 0.1, 0.12)
	var w := 1.9
	var h := 1.85
	var d := 0.9
	var c := Vector3(cx + 0.05, y0 + h * 0.5, z + 0.02)
	k.box(Vector3(w, h, d - 0.04), case_c, at(c.x, c.y, c.z - 0.02))
	# the open side: a frame, a reflection, the guts behind it
	var fz := c.z + d * 0.5
	for sy in [-1.0, 1.0]:
		k.box(Vector3(w, 0.06, 0.04), case_c.lightened(0.1), at(c.x, c.y + sy * (h * 0.5 - 0.03), fz))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, h, 0.04), case_c.lightened(0.1), at(c.x + sx * (w * 0.5 - 0.03), c.y, fz))
	k.box(Vector3(w - 0.12, h - 0.12, 0.01), Color(0.16, 0.16, 0.2), at(c.x, c.y, fz - 0.06))
	# motherboard, PSU shroud, the GPU, the CPU cooler, RAM, cables
	k.box(Vector3(1.2, 1.1, 0.02), Color(0.14, 0.2, 0.16), at(c.x + 0.15, c.y + 0.25, fz - 0.05))
	for i in 6:
		k.box(Vector3(0.12, 0.08, 0.02), Color(0.5, 0.52, 0.56), at(c.x - 0.25 + (i % 3) * 0.3, c.y + 0.55 - (i / 3) * 0.5, fz - 0.03))
	k.box(Vector3(w - 0.14, 0.38, 0.5), Color(0.14, 0.14, 0.16), at(c.x, y0 + 0.25, fz - 0.27))
	k.box(Vector3(0.5, 0.06, 0.01), Color(0.85, 0.85, 0.88), at(c.x + 0.4, y0 + 0.3, fz - 0.015))
	var gy := c.y - 0.1
	k.box(Vector3(1.25, 0.16, 0.42), Color(0.2, 0.2, 0.23), at(c.x - 0.05, gy, fz - 0.24))
	k.box(Vector3(1.2, 0.03, 0.01), lit(Color(0.5, 1.0, 0.6), 0.45), at(c.x - 0.05, gy + 0.04, fz - 0.025))
	k.box(Vector3(0.36, 0.05, 0.01), Color(0.85, 0.86, 0.9), at(c.x - 0.3, gy - 0.03, fz - 0.025))
	for i in 3:
		k.torus(0.13, 0.018, lit(Color(1.0, 0.4, 0.8), 0.45), xf(Vector3(c.x - 0.45 + i * 0.4, gy - 0.1, fz - 0.24), Vector3(0, 0, 0)), 10, 3)
	k.cyl(0.16, 0.08, Color(0.2, 0.2, 0.24), xf(Vector3(c.x + 0.25, c.y + 0.45, fz - 0.1), Vector3(90, 0, 0)), 10)
	k.torus(0.15, 0.02, lit(Color(0.4, 0.85, 1.0), 0.45), xf(Vector3(c.x + 0.25, c.y + 0.45, fz - 0.02), Vector3(90, 0, 0)), 12, 3)
	for i in 4:
		k.box(Vector3(0.04, 0.4, 0.06), Color(0.2, 0.2, 0.24), at(c.x + 0.55 + i * 0.07, c.y + 0.4, fz - 0.07))
		k.box(Vector3(0.04, 0.05, 0.065), lit([Color(1.0, 0.4, 0.8), Color(0.4, 0.85, 1.0), Color(0.7, 0.5, 1.0), Color(0.5, 1.0, 0.6)][i], 0.45), at(c.x + 0.55 + i * 0.07, c.y + 0.62, fz - 0.07))
	_tube(k, [Vector3(c.x + 0.25, c.y + 0.45, fz - 0.05), Vector3(c.x - 0.2, c.y + 0.75, fz - 0.05), Vector3(c.x - 0.75, c.y + 0.75, fz - 0.05)], 0.025, Color(0.16, 0.16, 0.18), 5)
	k.box(Vector3(0.12, 0.7, 0.04), Color(0.2, 0.2, 0.24), at(c.x - 0.8, c.y + 0.35, fz - 0.06))
	for i in 3:
		_tube(k, [Vector3(c.x + 0.6, y0 + 0.45, fz - 0.06), Vector3(c.x + 0.6 - i * 0.05, c.y - 0.3, fz - 0.04), Vector3(c.x + 0.3 - i * 0.1, c.y + 0.0, fz - 0.04)], 0.012, [Color(0.9, 0.3, 0.6), Color(0.3, 0.6, 0.95), Color(0.9, 0.9, 0.92)][i], 4, false)
	# front intake fans (the bus side) and the radiator stack
	for i in 3:
		k.torus(0.2, 0.025, lit([Color(1.0, 0.4, 0.8), Color(0.4, 0.85, 1.0), Color(0.7, 0.5, 1.0)][i], 0.45), xf(Vector3(c.x - w * 0.5 - 0.01, c.y + 0.55 - i * 0.48, c.z), Vector3(0, 0, 90)), 12, 3)
		k.box(Vector3(0.02, 0.06, 0.3), Color(0.3, 0.3, 0.34), at(c.x - w * 0.5 - 0.01, c.y + 0.55 - i * 0.48, c.z))
	# top: two exhaust fans in a mesh, a cat asleep at the back corner
	k.box(Vector3(w - 0.1, 0.02, d - 0.1), Color(0.18, 0.18, 0.2), at(c.x, y0 + h + 0.01, c.z))
	for i in 2:
		k.torus(0.2, 0.025, lit(Color(0.7, 0.5, 1.0), 0.45), at(c.x - 0.5 + i * 0.5, y0 + h + 0.025, c.z), 12, 3)
		k.cyl(0.05, 0.03, Color(0.3, 0.3, 0.34), at(c.x - 0.5 + i * 0.5, y0 + h, c.z), 6)
	var cat := Color(0.94, 0.6, 0.3)
	var cp := Vector3(c.x + 0.62, y0 + h, c.z - 0.12)
	k.sphere(0.2, cat, xf(cp + Vector3(0, 0.1, 0), Vector3(0, 20, 0), Vector3(1.3, 0.6, 0.9)), 8, 4)
	k.sphere(0.1, cat, at(cp.x - 0.24, cp.y + 0.13, cp.z + 0.08), 7, 4)
	for sx in [-1.0, 1.0]:
		k.cone(0.035, 0.07, cat.darkened(0.2), at(cp.x - 0.24 + sx * 0.05, cp.y + 0.2, cp.z + 0.08), 4)
	_tube(k, [cp + Vector3(0.22, 0.05, 0.05), cp + Vector3(0.3, 0.04, 0.2), cp + Vector3(0.18, 0.03, 0.3)], 0.03, cat.darkened(0.1), 5)
	for i in 3:
		k.box(Vector3(0.03, 0.04, 0.16), cat.darkened(0.3), xf(cp + Vector3(-0.05 + i * 0.1, 0.17, 0), Vector3(0, 20, 0)))
	# stickers on the case
	k.box(Vector3(0.18, 0.12, 0.01), Color(0.98, 0.86, 0.3), xf(Vector3(c.x + 0.75, c.y - 0.55, fz + 0.025), Vector3(0, 0, 8)))
	k.box(Vector3(0.14, 0.14, 0.01), Color(0.4, 0.75, 1.0), xf(Vector3(c.x + 0.55, c.y - 0.62, fz + 0.025), Vector3(0, 0, -10)))
	# feet, a flexible duct from the bus inlet into the front intake
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.1, 0.04, 0.1), Color(0.3, 0.3, 0.32), at(c.x + sx * 0.8, y0 + 0.02, c.z + sz * 0.35))
	for i in 5:
		k.cyl(0.33 - (i % 2) * 0.02, 0.07, Color(0.72, 0.74, 0.76) if i % 2 == 0 else Color(0.6, 0.62, 0.64), xf(Vector3(-1.72 + i * 0.075, Y - 0.05, z), Vector3(0, 0, -90)), 8)
	# a desk fan on the pallet aimed at it, a little token counter display
	var fp := Vector3(cx + 1.15, y0, z + 0.62)
	k.box(Vector3(0.22, 0.03, 0.18), Color(0.92, 0.92, 0.9), at(fp.x, fp.y + 0.015, fp.z))
	k.box(Vector3(0.03, 0.3, 0.03), Color(0.92, 0.92, 0.9), at(fp.x, fp.y + 0.16, fp.z))
	k.cyl(0.16, 0.05, Color(0.9, 0.9, 0.88), xf(Vector3(fp.x, fp.y + 0.36, fp.z), Vector3(0, 0, 90), Vector3.ONE), 10)
	k.torus(0.16, 0.012, Color(0.6, 0.62, 0.66), xf(Vector3(fp.x - 0.04, fp.y + 0.36, fp.z), Vector3(0, 0, 90)), 10, 3)
	var dp := Vector3(cx - 0.9, y0, z + 0.7)
	k.box(Vector3(0.5, 0.26, 0.08), Color(0.12, 0.12, 0.14), at(dp.x, dp.y + 0.2, dp.z))
	k.box(Vector3(0.44, 0.18, 0.01), lit(Color(1.0, 0.7, 0.3), 0.45), at(dp.x, dp.y + 0.2, dp.z + 0.045))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.03, 0.08, 0.1), Color(0.3, 0.3, 0.32), at(dp.x + sx * 0.18, dp.y + 0.04, dp.z))


## The exhaust vent (where tokens stream out) for each tier, local.
static func vent_top(t: int) -> Vector3:
	var z := TZ
	match t:
		0: return Vector3(-0.45, 2.05, z + 0.02)
		1: return Vector3(-0.25, 2.45, z + 0.1)
		2: return Vector3(-0.55, 2.3, z + 0.45)
		3: return Vector3(-0.7, 2.72, z + 0.6)
	return Vector3(-0.45, 2.34, z + 0.35)


# ---------------------------------------------------------------- bench and dock

## The coolant bench at the front right of the core where coolant lands
## (holder at y 0.78).
static func bench(t: int) -> Mesh:
	var k := MeshKit.new()
	match t:
		0: _bench0(k)
		1: _bench1(k)
		2: _bench2(k)
		3: _bench3(k)
		_: _bench4(k)
	return k.commit()


## Garage: an old door on two sawhorses, a cooler and water jugs under it.
static func _bench0(k: MeshKit) -> void:
	var pine := Color(0.78, 0.64, 0.44)
	var door := Color(0.9, 0.88, 0.82)
	k.box(Vector3(1.42, 0.045, 0.86), door, at(0, 0.745, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.5, 0.01, 0.3), door.darkened(0.08), at(sx * 0.35, 0.772, -0.18))
		k.box(Vector3(0.5, 0.01, 0.3), door.darkened(0.08), at(sx * 0.35, 0.772, 0.18))
	k.cyl(0.035, 0.02, Color(0.3, 0.3, 0.32), at(0.62, 0.77, 0), 6)
	for sx in [-1.0, 1.0]:
		var x: float = sx * 0.5
		k.box(Vector3(0.08, 0.08, 0.9), pine.darkened(0.1), at(x, 0.68, 0))
		for sz in [-1.0, 1.0]:
			for side in [-1.0, 1.0]:
				k.box(Vector3(0.05, 0.72, 0.05), pine, xf(Vector3(x + side * 0.08, 0.34, sz * 0.36), Vector3(0, 0, side * 12)))
		k.box(Vector3(0.3, 0.04, 0.04), pine.darkened(0.15), at(x, 0.3, 0.36))
		k.box(Vector3(0.3, 0.04, 0.04), pine.darkened(0.15), at(x, 0.3, -0.36))
	# a styrofoam cooler, water jugs, a bucket
	k.box(Vector3(0.5, 0.32, 0.34), Color(0.94, 0.95, 0.96), at(-0.05, 0.16, 0.05))
	k.box(Vector3(0.52, 0.06, 0.36), Color(0.3, 0.55, 0.85), at(-0.05, 0.34, 0.05))
	for i in 2:
		k.cyl(0.11, 0.3, Color(0.55, 0.75, 0.92), at(0.4 + i * 0.0, 0.0, -0.2 + i * 0.3), 8)
		k.cyl(0.04, 0.06, Color(0.3, 0.5, 0.86), at(0.4, 0.3, -0.2 + i * 0.3), 6)
	k.cyl(0.13, 0.26, Color(0.95, 0.6, 0.2), at(-0.48, 0.0, -0.15), 8, 0.0, 0.15)


## The power dock by the router where couriers drop power cells (holder at
## y 0.82).
static func power_dock(t: int) -> Mesh:
	var k := MeshKit.new()
	match t:
		0: _dock0(k)
		1: _dock1(k)
		2: _dock2(k)
		3: _dock3(k)
		_: _dock4(k)
	return k.commit()


## Garage: a slatted crate on two pallets, a power strip, a car battery and
## an orange extension-cord reel.
static func _dock0(k: MeshKit) -> void:
	var pine := Color(0.78, 0.64, 0.44)
	for p in 2:
		var y := p * 0.15
		for i in 3:
			k.box(Vector3(1.24, 0.08, 0.08), pine.darkened(0.15), at(0, y + 0.04, -0.38 + i * 0.38))
		for i in 6:
			k.box(Vector3(0.17, 0.025, 0.9), pine if i % 2 == 0 else pine.darkened(0.07), at(-0.53 + i * 0.212, y + 0.1, 0))
	k.box(Vector3(1.16, 0.42, 0.82), pine.darkened(0.25), at(0, 0.55, 0))
	for i in 4:
		k.box(Vector3(1.2, 0.08, 0.86), pine if i % 2 == 0 else pine.darkened(0.06), at(0, 0.38 + i * 0.12, 0))
	for sx in [-1.0, 0.0, 1.0]:
		k.box(Vector3(0.07, 0.46, 0.88), pine.darkened(0.12), at(sx * 0.55, 0.55, 0))
	k.box(Vector3(1.1, 0.02, 0.78), Color(0.84, 0.74, 0.56), at(0, 0.77, 0))
	k.box(Vector3(0.5, 0.05, 0.08), Color(0.94, 0.94, 0.92), at(0.1, 0.5, 0.47))
	for i in 4:
		k.box(Vector3(0.04, 0.03, 0.02), Color(0.2, 0.2, 0.22), at(-0.08 + i * 0.12, 0.5, 0.515))
	k.box(Vector3(0.06, 0.02, 0.01), lit(Color(1.0, 0.4, 0.3), 0.4), at(0.3, 0.52, 0.515))
	k.box(Vector3(0.3, 0.2, 0.18), Color(0.12, 0.12, 0.13), at(0.72, 0.1, 0.32))
	k.cyl(0.025, 0.04, Color(0.86, 0.24, 0.2), at(0.64, 0.2, 0.32), 6)
	k.cyl(0.025, 0.04, Color(0.2, 0.2, 0.22), at(0.8, 0.2, 0.32), 6)
	k.cyl(0.16, 0.18, Color(0.95, 0.5, 0.15), xf(Vector3(-0.72, 0.18, 0.3), Vector3(0, 0, 90)), 10)
	k.cyl(0.1, 0.2, Color(0.2, 0.2, 0.22), xf(Vector3(-0.71, 0.18, 0.3), Vector3(0, 0, 90)), 8)
	_tube(k, [Vector3(-0.72, 0.05, 0.42), Vector3(-0.4, 0.02, 0.6), Vector3(0.0, 0.02, 0.6), Vector3(0.1, 0.48, 0.5)], 0.02, Color(0.95, 0.5, 0.15), 4, false)
	_tube(k, [Vector3(0.1, 0.5, -0.45), Vector3(0.1, 0.03, -0.6), Vector3(0.3, 0.03, -1.1), Vector3(0.6, 0.03, -1.6)], 0.022, Color(0.95, 0.5, 0.15), 4, false)


# ---------------------------------------------------------------- the house

## The building around the stack, for tier t (w x d metres, centred).
static func house(t: int, w: float, d: float) -> Mesh:
	var k := MeshKit.new()
	_house_body(k, t)
	# nothing may poke out of the lot (sub-centimetre overhangs of trims)
	var hx := w * 0.5 - 0.1
	var hz := d * 0.5 - 0.1
	for i in k._v.size():
		var v := k._v[i]
		if absf(v.x) > hx or absf(v.z) > hz:
			k._v[i] = Vector3(clampf(v.x, -hx, hx), v.y, clampf(v.z, -hz, hz))
	return k.commit()


static func _house_body(k: MeshKit, t: int) -> void:
	match t:
		0: _garage(k)
		1: _closet(k)
		2:
			_campus(k)
			_campus_more(k)
			_campus_more2(k)
		3:
			_hall(k)
			_hall_more(k)
			_hall_more2(k)
		_:
			_hyper(k)
			_hyper_more(k)
			_hyper_more2(k)
			_hyper_more3(k)


## Tier 0: a plywood garage with a lean-to tin roof over the back, rafters
## open over the stack, the roll-up door rolled up, a driveway, a lawn.
static func _garage(k: MeshKit) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 4242
	var plank := Color(0.8, 0.65, 0.45)
	var stud := Color(0.64, 0.49, 0.33)
	var trim := Color(0.42, 0.3, 0.2)
	var conc := Color(0.7, 0.69, 0.66)
	var tin := Color(0.7, 0.72, 0.74)
	var fz := 0.3                 # the door line
	var hf := 2.5                 # header top (the roof runs down to it)
	var hb := 3.0                 # back wall top
	var roof_y := func(z: float) -> float: return hb + (z + 2.9) / (fz + 2.9) * (hf - hb)
	# ------------------------------------------------ ground
	k.box(Vector3(9.8, 0.06, 3.2), conc, at(0, 0.03, -1.3))
	for i in 3:
		k.box(Vector3(0.025, 0.01, 3.2), conc.darkened(0.14), at(-2.45 + i * 2.45, 0.065, -1.3))
	k.box(Vector3(9.8, 0.01, 0.025), conc.darkened(0.14), at(0, 0.065, -1.3))
	for p in [Vector3(-1.4, 0, -0.3), Vector3(0.7, 0, -0.1), Vector3(-2.9, 0, -2.3), Vector3(2.2, 0, -0.05), Vector3(-0.2, 0, -2.4)]:
		k.cyl(0.16, 0.004, conc.darkened(0.16), xf(p + Vector3(0, 0.061, 0), Vector3(0, r.randf() * 180, 0), Vector3(1.5, 1, 1)), 7)
	var drv := Color(0.76, 0.75, 0.71)
	k.box(Vector3(5.4, 0.05, 2.6), drv, at(-0.4, 0.025, 1.6))
	for i in 3:
		k.box(Vector3(5.4, 0.008, 0.02), drv.darkened(0.12), at(-0.4, 0.052, 0.95 + i * 0.75))
	for i in 7:
		k.box(Vector3(r.randf_range(0.3, 0.7), 0.006, 0.02), drv.darkened(0.25), xf(Vector3(r.randf_range(-2.8, 2.0), 0.054, r.randf_range(0.5, 2.8)), Vector3(0, r.randf_range(0, 180), 0)))
	for i in 10:
		k.box(Vector3(0.06, 0.07, 0.04), Color(0.4, 0.6, 0.32), xf(Vector3(r.randf_range(-3.0, 2.2), 0.04, r.randf_range(0.4, 2.85)), Vector3(0, r.randf() * 90, 20)))
	k.box(Vector3(1.8, 0.04, 2.6), Color(0.6, 0.56, 0.5), at(-4.0, 0.02, 1.6))
	for i in 26:
		k.box(Vector3(0.05, 0.03, 0.05), Color(0.52, 0.48, 0.42) if i % 2 == 0 else Color(0.68, 0.64, 0.58), xf(Vector3(r.randf_range(-4.85, -3.15), 0.045, r.randf_range(0.4, 2.85)), Vector3(0, r.randf() * 90, 0)))
	k.box(Vector3(2.6, 0.05, 2.6), Color(0.46, 0.63, 0.36), at(3.6, 0.025, 1.6))
	for i in 34:
		k.box(Vector3(0.03, 0.1, 0.03), Color(0.38, 0.56, 0.3) if i % 3 else Color(0.52, 0.7, 0.4), xf(Vector3(r.randf_range(2.35, 4.85), 0.08, r.randf_range(0.4, 2.85)), Vector3(r.randf_range(-20, 20), 0, r.randf_range(-20, 20))))
	for i in 4:
		k.cyl(0.17, 0.03, Color(0.66, 0.64, 0.6), at(2.7 + i * 0.12, 0.03, 2.6 - i * 0.5), 7)
	# ------------------------------------------------ walls: boards outside, studs inside
	_boards_x(k, -4.9, 4.9, -2.875, 0.06, hb - 0.06, plank)
	for i in 17:
		k.box(Vector3(0.05, hb - 0.06, 0.09), stud, at(-4.8 + i * 0.6, hb * 0.5 + 0.03, -2.805))
	k.box(Vector3(9.8, 0.08, 0.14), stud, at(0, hb - 0.04, -2.82))
	k.box(Vector3(9.8, 0.06, 0.12), stud.darkened(0.1), at(0, 0.09, -2.8))
	for s in [-1.0, 1.0]:
		var x: float = s * 4.875
		_boards_z(k, -2.9, fz + 0.08, x, 0.06, hf - 0.06, plank)
		var tri := PackedVector2Array([Vector2(-2.9, hf), Vector2(fz + 0.08, hf), Vector2(-2.9, hb)])
		k.prism(tri, 0.05, plank.darkened(0.05), Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3(x - 0.025, 0, 0)))
		for i in 6:
			var zz := -2.6 + i * 0.55
			k.box(Vector3(0.09, roof_y.call(zz), 0.05), stud, at(s * 4.805, roof_y.call(zz) * 0.5, zz))
		_beam(k, Vector3(s * 4.82, hb, -2.9), Vector3(s * 4.82, hf, fz), Vector2(0.12, 0.08), stud)
		# a window in each side wall
		var wz := -1.5
		var wx: float = s * 4.83
		k.box(Vector3(0.14, 0.72, 0.92), trim, at(wx, 1.65, wz))
		k.box(Vector3(0.15, 0.6, 0.8), Color(0.66, 0.78, 0.84, 0.75), at(wx, 1.65, wz))
		k.box(Vector3(0.14, 0.04, 0.8), trim, at(wx, 1.65, wz))
		k.box(Vector3(0.14, 0.6, 0.04), trim, at(wx, 1.65, wz))
		k.box(Vector3(0.24, 0.05, 1.0), trim, at(s * 4.78, 1.3, wz))
	# a downpipe and gutter at the back
	k.box(Vector3(9.8, 0.06, 0.06), Color(0.6, 0.62, 0.64), at(0, hb + 0.2, -2.87))
	k.box(Vector3(0.08, hf, 0.08), Color(0.6, 0.62, 0.64), at(4.72, hf * 0.5, fz + 0.16))
	# ------------------------------------------------ front: posts, a low header, the door rolled up
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.16, hf, 0.16), trim, at(s * 4.81, hf * 0.5, fz))
		k.box(Vector3(0.06, hf - 0.3, 0.08), Color(0.56, 0.58, 0.6), at(s * 4.68, (hf - 0.3) * 0.5, fz - 0.08))
	k.box(Vector3(9.78, 0.3, 0.14), stud, at(0, hf - 0.15, fz))
	k.box(Vector3(9.8, 0.05, 0.2), trim, at(0, hf + 0.025, fz + 0.02))
	k.box(Vector3(9.8, 0.04, 0.03), trim, at(0, hf - 0.3, fz + 0.075))
	k.box(Vector3(9.8, 0.1, 0.1), Color(0.6, 0.62, 0.64), at(0, hf + 0.08, fz + 0.14))
	var dcol := Color(0.93, 0.91, 0.85)
	k.box(Vector3(9.3, 0.3, 0.26), dcol.darkened(0.2), at(0, hf - 0.15, fz - 0.22))
	k.box(Vector3(9.3, 0.07, 0.05), dcol, at(0, hf - 0.33, fz - 0.1))
	k.box(Vector3(9.3, 0.03, 0.06), Color(0.3, 0.3, 0.32), at(0, hf - 0.37, fz - 0.1))
	for x in [-2.5, 2.5]:
		k.box(Vector3(0.18, 0.04, 0.05), Color(0.4, 0.42, 0.44), at(x, hf - 0.33, fz - 0.06))
	k.box(Vector3(0.01, 0.55, 0.01), Color(0.9, 0.9, 0.86), at(1.4, hf - 0.65, fz - 0.08))
	k.box(Vector3(0.05, 0.06, 0.05), Color(0.86, 0.3, 0.26), at(1.4, hf - 0.93, fz - 0.08))
	# porch lights either side, a house number on the header
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.12, 0.2, 0.08), Color(0.2, 0.2, 0.22), at(s * 4.55, hf - 0.6, fz + 0.12))
		k.box(Vector3(0.08, 0.12, 0.06), lit(Color(1.0, 0.82, 0.5), 0.35), at(s * 4.55, hf - 0.62, fz + 0.17))
	for i in 2:
		k.box(Vector3(0.1, 0.14, 0.02), Color(0.95, 0.9, 0.7), at(-0.08 + i * 0.13, hf - 0.15, fz + 0.08))
	# ------------------------------------------------ roof: rafters, tin over the back, a tarp
	for i in 17:
		var x := -4.8 + i * 0.6
		_beam(k, Vector3(x, hb + 0.07, -2.84), Vector3(x, hf + 0.07, fz + 0.05), Vector2(0.05, 0.14), stud)
	_beam(k, Vector3(-4.85, roof_y.call(-2.1) + 0.17, -2.1), Vector3(4.85, roof_y.call(-2.1) + 0.17, -2.1), Vector2(0.08, 0.06), stud)
	var tz0 := -2.9
	var tz1 := -2.35
	var tm := (tz0 + tz1) * 0.5
	var a := -rad_to_deg(atan((hf - hb) / (fz + 2.9)))
	var rb := xf(Vector3(0, roof_y.call(tm) + 0.215, tm), Vector3(a, 0, 0))
	k.box(Vector3(9.8, 0.02, tz1 - tz0), tin, rb)
	for i in 49:
		k.box(Vector3(0.035, 0.03, tz1 - tz0), tin.darkened(0.1), rb * at(-4.8 + i * 0.2, 0.02, 0))
	k.box(Vector3(9.8, 0.04, 0.05), tin.darkened(0.2), rb * at(0, 0.02, (tz1 - tz0) * 0.5))
	for i in 6:
		k.box(Vector3(r.randf_range(0.2, 0.5), 0.034, r.randf_range(0.15, 0.4)), Color(0.66, 0.44, 0.3), rb * at(r.randf_range(-4.5, 4.5), 0.02, r.randf_range(-0.15, 0.15)))
	k.box(Vector3(0.9, 0.034, 0.5), Color(0.84, 0.86, 0.74), rb * at(0.9, 0.02, 0))
	# a blue tarp over a leak, weighed down with two tyres
	k.box(Vector3(1.4, 0.04, 0.46), Color(0.26, 0.46, 0.78), rb * xf(Vector3(-2.9, 0.05, 0.02), Vector3(0, 6, 2)))
	for i in 2:
		k.torus(0.16, 0.06, Color(0.14, 0.14, 0.15), rb * at(-3.3 + i * 0.8, 0.1, -0.05 + i * 0.1), 10, 4)
	# ------------------------------------------------ ceiling: string lights, a bulb, a tube light
	for i in 3:
		var x0 := -3.6 + i * 3.0
		ArchKit.string_lights(k, Vector3(x0, hf - 0.05, fz - 0.4), Vector3(x0 + 1.4, roof_y.call(-2.7) - 0.05, -2.7), 8)
	ArchKit.string_lights(k, Vector3(-4.7, hf + 0.02, fz + 0.16), Vector3(4.7, hf + 0.02, fz + 0.16), 22)
	k.box(Vector3(1.2, 0.06, 0.14), Color(0.92, 0.92, 0.9), at(1.3, 2.35, -2.4))
	k.box(Vector3(1.1, 0.03, 0.05), lit(Color(0.92, 0.98, 1.0), 0.4), at(1.3, 2.31, -2.4))
	for x in [0.8, 1.8]:
		k.box(Vector3(0.01, roof_y.call(-2.4) - 2.35, 0.01), Color(0.2, 0.2, 0.2), at(x, (roof_y.call(-2.4) + 2.35) * 0.5, -2.4))
	k.box(Vector3(0.01, 0.4, 0.01), Color(0.15, 0.15, 0.15), at(2.2, roof_y.call(-2.0) - 0.2, -2.0))
	k.sphere(0.06, lit(Color(1.0, 0.82, 0.5), 0.3), at(2.2, roof_y.call(-2.0) - 0.44, -2.0), 6, 4)
	# ------------------------------------------------ back strip: shelving, workbench, pegboard, fridge
	var sh := Vector3(-2.8, 0.06, -2.5)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.035, 1.9, 0.035), Color(0.55, 0.57, 0.6), at(sh.x + sx * 0.52, sh.y + 0.95, sh.z + sz * 0.2))
	for j in 4:
		var yy := sh.y + 0.15 + j * 0.55
		k.box(Vector3(1.08, 0.025, 0.44), Color(0.6, 0.62, 0.64), at(sh.x, yy, sh.z))
		_boxes(k, Vector3(sh.x - 0.3, yy + 0.012, sh.z), 1 + (j % 2), [Color(0.72, 0.56, 0.38), Color(0.66, 0.5, 0.34)], j, 0.34)
		k.box(Vector3(0.26, 0.2, 0.3), [Color(0.3, 0.46, 0.7), Color(0.86, 0.3, 0.26), Color(0.95, 0.8, 0.3), Color(0.3, 0.6, 0.4)][j], at(sh.x + 0.15, yy + 0.11, sh.z))
		for c in 2:
			k.cyl(0.07, 0.13, [Color(0.8, 0.8, 0.82), Color(0.9, 0.5, 0.3)][c], at(sh.x + 0.4, yy + 0.012, sh.z - 0.08 + c * 0.16), 6)
	# workbench
	var wb := Vector3(-1.0, 0.06, -2.5)
	k.box(Vector3(2.2, 0.07, 0.6), Color(0.7, 0.55, 0.36), at(wb.x, wb.y + 0.86, wb.z))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.08, 0.86, 0.08), stud, at(wb.x + sx * 1.0, wb.y + 0.43, wb.z + sz * 0.24))
	k.box(Vector3(2.1, 0.04, 0.52), stud, at(wb.x, wb.y + 0.25, wb.z))
	_boxes(k, Vector3(wb.x - 0.6, wb.y + 0.27, wb.z), 2, [Color(0.72, 0.56, 0.38)], 9, 0.3)
	k.cyl(0.14, 0.35, Color(0.3, 0.5, 0.86), at(wb.x + 0.5, wb.y + 0.27, wb.z), 8)
	# vice, toolbox, drill, radio, parts drawers, a lamp
	var top := wb.y + 0.895
	k.box(Vector3(0.14, 0.12, 0.2), Color(0.28, 0.42, 0.62), at(wb.x - 0.95, top + 0.06, wb.z + 0.2))
	k.box(Vector3(0.18, 0.02, 0.02), Color(0.6, 0.62, 0.64), at(wb.x - 0.95, top + 0.08, wb.z + 0.33))
	k.box(Vector3(0.45, 0.2, 0.22), Color(0.82, 0.24, 0.22), at(wb.x - 0.5, top + 0.1, wb.z - 0.1))
	k.box(Vector3(0.3, 0.03, 0.04), Color(0.2, 0.2, 0.22), at(wb.x - 0.5, top + 0.22, wb.z - 0.1))
	k.box(Vector3(0.08, 0.16, 0.18), Color(0.96, 0.78, 0.2), at(wb.x - 0.1, top + 0.08, wb.z + 0.12))
	k.box(Vector3(0.05, 0.05, 0.14), Color(0.2, 0.2, 0.22), at(wb.x - 0.1, top + 0.14, wb.z + 0.25))
	k.box(Vector3(0.34, 0.2, 0.12), Color(0.2, 0.22, 0.24), at(wb.x + 0.35, top + 0.1, wb.z - 0.18))
	k.cyl(0.06, 0.01, Color(0.4, 0.4, 0.42), xf(Vector3(wb.x + 0.27, top + 0.1, wb.z - 0.12), Vector3(90, 0, 0)), 8)
	k.box(Vector3(0.08, 0.04, 0.01), lit(Color(1.0, 0.6, 0.3), 0.45), at(wb.x + 0.42, top + 0.14, wb.z - 0.115))
	for i in 12:
		k.box(Vector3(0.09, 0.05, 0.02), [Color(0.3, 0.46, 0.7), Color(0.86, 0.3, 0.26), Color(0.95, 0.8, 0.3)][i % 3], at(wb.x + 0.7 + (i % 4) * 0.1, top + 0.04 + (i / 4) * 0.065, wb.z - 0.11))
	k.box(Vector3(0.44, 0.22, 0.16), Color(0.6, 0.62, 0.64), at(wb.x + 0.85, top + 0.11, wb.z - 0.2))
	k.box(Vector3(0.1, 0.03, 0.12), Color(0.2, 0.2, 0.22), at(wb.x + 0.2, top + 0.015, wb.z + 0.15))
	k.box(Vector3(0.02, 0.4, 0.02), Color(0.2, 0.2, 0.22), xf(Vector3(wb.x + 0.2, top + 0.2, wb.z + 0.1), Vector3(-20, 0, 0)))
	k.box(Vector3(0.02, 0.3, 0.02), Color(0.2, 0.2, 0.22), xf(Vector3(wb.x + 0.2, top + 0.45, wb.z + 0.12), Vector3(50, 0, 0)))
	k.cone(0.07, 0.1, Color(0.3, 0.55, 0.86), xf(Vector3(wb.x + 0.2, top + 0.55, wb.z + 0.28), Vector3(150, 0, 0)), 8)
	# pegboard and tools
	var pz := -2.74
	k.box(Vector3(2.1, 0.8, 0.02), Color(0.82, 0.72, 0.54), at(wb.x, 1.45, pz))
	for i in 9:
		for j in 4:
			k.box(Vector3(0.012, 0.012, 0.005), Color(0.5, 0.42, 0.3), at(wb.x - 0.95 + i * 0.24, 1.15 + j * 0.2, pz + 0.012))
	var tools := [[0.05, 0.36, Color(0.6, 0.62, 0.66), -8], [0.04, 0.3, Color(0.86, 0.3, 0.26), 0], [0.05, 0.42, Color(0.6, 0.62, 0.66), 10], [0.04, 0.28, Color(0.95, 0.78, 0.25), 0],
		[0.03, 0.26, Color(0.3, 0.5, 0.86), 0], [0.06, 0.32, Color(0.2, 0.2, 0.22), -15], [0.2, 0.12, Color(0.6, 0.62, 0.66), 0], [0.04, 0.34, Color(0.86, 0.3, 0.26), 6]]
	for i in tools.size():
		var tl: Array = tools[i]
		k.box(Vector3(tl[0], tl[1], 0.03), tl[2], xf(Vector3(wb.x - 0.85 + i * 0.24, 1.45, pz + 0.03), Vector3(0, 0, tl[3])))
	k.box(Vector3(0.28, 0.1, 0.03), Color(0.62, 0.64, 0.66), at(wb.x + 0.75, 1.7, pz + 0.03))
	k.torus(0.12, 0.02, Color(0.95, 0.5, 0.15), xf(Vector3(wb.x + 0.75, 1.25, pz + 0.04), Vector3(90, 0, 0)), 10, 3)
	# fridge with magnets and pizza boxes on top
	var fr := Vector3(0.65, 0.06, -2.5)
	k.box(Vector3(0.62, 1.42, 0.56), Color(0.94, 0.93, 0.88), at(fr.x, fr.y + 0.71, fr.z))
	k.box(Vector3(0.6, 0.012, 0.02), Color(0.7, 0.7, 0.68), at(fr.x, fr.y + 1.0, fr.z + 0.285))
	k.box(Vector3(0.03, 0.3, 0.04), Color(0.7, 0.72, 0.74), at(fr.x - 0.24, fr.y + 0.75, fr.z + 0.3))
	k.box(Vector3(0.03, 0.18, 0.04), Color(0.7, 0.72, 0.74), at(fr.x - 0.24, fr.y + 1.2, fr.z + 0.3))
	for i in 5:
		k.box(Vector3(0.06, 0.06, 0.012), [Color(0.86, 0.3, 0.26), Color(0.3, 0.5, 0.86), Color(0.95, 0.8, 0.3), Color(0.4, 0.75, 0.4), Color(0.95, 0.95, 0.95)][i], at(fr.x - 0.05 + (i % 3) * 0.12, fr.y + 0.5 + (i / 3) * 0.6, fr.z + 0.29))
	for i in 3:
		k.box(Vector3(0.42, 0.05, 0.42), Color(0.86, 0.74, 0.54), xf(Vector3(fr.x, fr.y + 1.45 + i * 0.055, fr.z), Vector3(0, i * 9 - 9, 0)))
	# behind the core: shelves with jars and cans, posters, a dartboard, a clock
	for j in 2:
		var yy := 2.0 + j * 0.38
		k.box(Vector3(2.8, 0.03, 0.22), Color(0.7, 0.55, 0.36), at(3.3, yy, -2.72))
		for i in 9:
			var px := 2.05 + i * 0.3
			if (i + j) % 3 == 0:
				k.cyl(0.06, 0.14, Color(0.7, 0.8, 0.86, 1.0), at(px, yy + 0.015, -2.72), 6)
			elif (i + j) % 3 == 1:
				k.box(Vector3(0.18, 0.2, 0.15), Color(0.72, 0.56, 0.38), at(px, yy + 0.115, -2.72))
			else:
				k.cyl(0.07, 0.12, [Color(0.86, 0.3, 0.26), Color(0.3, 0.5, 0.86)][i % 2], at(px, yy + 0.015, -2.72), 6)
	for i in 3:
		var pc: Color = [Color(0.3, 0.4, 0.75), Color(0.9, 0.5, 0.3), Color(0.2, 0.2, 0.24)][i]
		var px2: float = [-4.0, -3.35, 1.5][i]
		k.box(Vector3(0.5, 0.7, 0.01), pc, xf(Vector3(px2, 1.85 if i < 2 else 1.5, -2.745), Vector3(0, 0, [2.0, -3.0, 1.0][i])))
		k.box(Vector3(0.3, 0.08, 0.012), Color(0.96, 0.92, 0.8), xf(Vector3(px2, 2.05 if i < 2 else 1.7, -2.74), Vector3(0, 0, [2.0, -3.0, 1.0][i])))
		k.box(Vector3(0.2, 0.2, 0.012), Color(0.96, 0.92, 0.8, 1.0).darkened(0.1 * i), at(px2, 1.75 if i < 2 else 1.4, -2.738))
	k.cyl(0.2, 0.03, Color(0.15, 0.15, 0.15), xf(Vector3(4.5, 1.6, -2.75), Vector3(90, 0, 0)), 12)
	k.cyl(0.14, 0.035, Color(0.86, 0.3, 0.26), xf(Vector3(4.5, 1.6, -2.75), Vector3(90, 0, 0)), 10)
	k.cyl(0.05, 0.04, Color(0.3, 0.6, 0.3), xf(Vector3(4.5, 1.6, -2.75), Vector3(90, 0, 0)), 6)
	k.cyl(0.13, 0.03, Color(0.95, 0.95, 0.92), xf(Vector3(0.0, 2.25, -2.75), Vector3(90, 0, 0)), 10)
	k.box(Vector3(0.015, 0.09, 0.01), Color(0.1, 0.1, 0.1), at(0.0, 2.29, -2.73))
	# left: a water heater with pipes, a ladder on hooks, a broom
	k.cyl(0.26, 1.6, Color(0.92, 0.92, 0.9), at(-4.45, 0.06, -2.48), 10)
	k.cyl(0.27, 0.06, Color(0.6, 0.62, 0.64), at(-4.45, 1.66, -2.48), 10)
	for sx in [-1.0, 1.0]:
		_tube(k, [Vector3(-4.45 + sx * 0.1, 1.7, -2.48), Vector3(-4.45 + sx * 0.1, hb, -2.48)], 0.025, Color(0.75, 0.5, 0.3), 5)
	k.box(Vector3(0.1, 0.06, 0.03), Color(0.86, 0.3, 0.26), at(-4.45, 0.5, -2.22))
	for sy in [0.0, 0.32]:
		k.box(Vector3(0.04, 0.04, 2.0), Color(0.62, 0.64, 0.66), at(-4.76, 2.1 + sy, -0.9))
	for i in 7:
		k.box(Vector3(0.03, 0.32, 0.03), Color(0.62, 0.64, 0.66), at(-4.76, 2.26, -1.8 + i * 0.3))
	k.box(Vector3(0.03, 1.3, 0.03), Color(0.7, 0.55, 0.36), xf(Vector3(-3.4, 0.7, -2.72), Vector3(10, 0, 8)))
	k.box(Vector3(0.24, 0.12, 0.06), Color(0.95, 0.78, 0.25), at(-3.3, 0.1, -2.68))
	# right wall: a hose reel, a rake and a shovel
	k.torus(0.2, 0.05, Color(0.3, 0.6, 0.3), xf(Vector3(4.75, 1.4, 0.0), Vector3(0, 0, 90)), 12, 4)
	for i in 2:
		k.box(Vector3(0.03, 1.4, 0.03), Color(0.7, 0.55, 0.36), xf(Vector3(4.74, 0.8, -0.4 - i * 0.18), Vector3(0, 0, -8)))
	# ------------------------------------------------ extension cords along the floor
	_tube(k, [Vector3(-4.7, 0.4, -2.75), Vector3(-4.7, 0.07, -2.3), Vector3(-4.0, 0.07, -0.5), Vector3(-3.6, 0.07, 0.6)], 0.02, Color(0.95, 0.5, 0.15), 4, false)
	_tube(k, [Vector3(4.7, 0.4, -2.75), Vector3(4.72, 0.07, -2.0), Vector3(4.72, 0.07, -0.3), Vector3(4.4, 0.07, 0.2)], 0.02, Color(0.95, 0.5, 0.15), 4, false)
	# ------------------------------------------------ the yard: picket fence, mailbox, bins, bike, pizza, a box fan
	for s in [-1.0, 1.0]:
		var xa: float = -4.85 if s < 0 else 2.3
		var xb: float = -3.2 if s < 0 else 4.85
		var n := int((xb - xa) / 0.16)
		for i in n + 1:
			var px := xa + i * (xb - xa) / n
			k.box(Vector3(0.07, 0.62, 0.025), Color(0.96, 0.95, 0.92), at(px, 0.31, 2.86))
			k.box(Vector3(0.05, 0.05, 0.027), Color(0.96, 0.95, 0.92), xf(Vector3(px, 0.63, 2.86), Vector3(0, 0, 45)))
		for yy in [0.2, 0.48]:
			k.box(Vector3(xb - xa, 0.05, 0.03), Color(0.9, 0.89, 0.86), at((xa + xb) * 0.5, yy, 2.84))
		k.box(Vector3(0.1, 1.9, 0.1), Color(0.5, 0.36, 0.24), at(s * 4.8, 0.95, 2.84))
		ArchKit.string_lights(k, Vector3(s * 4.8, 1.88, 2.84), Vector3(s * 4.6, hf - 0.1, fz + 0.14), 7)
	ArchKit.string_lights(k, Vector3(-4.8, 1.88, 2.84), Vector3(4.8, 1.88, 2.84), 20)
	k.box(Vector3(0.08, 1.0, 0.08), Color(0.5, 0.36, 0.24), at(-3.0, 0.5, 2.55))
	k.rbox(Vector3(0.22, 0.24, 0.45), 0.08, Color(0.3, 0.42, 0.66), at(-3.0, 1.1, 2.55), 1)
	k.box(Vector3(0.02, 0.16, 0.06), Color(0.86, 0.3, 0.26), at(-2.88, 1.25, 2.45))
	for i in 2:
		var bp := Vector3(4.45, 0.0, 1.8 + i * 0.62)
		k.box(Vector3(0.52, 0.86, 0.5), [Color(0.26, 0.42, 0.3), Color(0.3, 0.42, 0.66)][i], at(bp.x, bp.y + 0.45, bp.z))
		k.box(Vector3(0.56, 0.06, 0.54), [Color(0.2, 0.34, 0.24), Color(0.24, 0.34, 0.56)][i], xf(Vector3(bp.x, bp.y + 0.91, bp.z), Vector3(0, 0, 4)))
		k.cyl(0.07, 0.05, Color(0.1, 0.1, 0.1), xf(Vector3(bp.x + 0.2, 0.07, bp.z - 0.2), Vector3(0, 0, 90)), 6)
	_bike(k, Vector3(3.3, 0.04, 2.45), Color(0.2, 0.6, 0.86), 6.0)
	for i in 4:
		k.box(Vector3(0.42, 0.05, 0.42), Color(0.86, 0.74, 0.54), xf(Vector3(2.25, 0.06 + i * 0.052, 1.95), Vector3(0, i * 11 - 15, 0)))
	k.box(Vector3(0.24, 0.006, 0.14), Color(0.8, 0.3, 0.24), xf(Vector3(2.25, 0.27, 1.95), Vector3(0, 18, 0)))
	var bf := Vector3(4.42, 0.06, 0.15)
	k.box(Vector3(0.12, 0.5, 0.5), Color(0.9, 0.9, 0.88), at(bf.x, bf.y + 0.25, bf.z))
	k.cyl(0.2, 0.13, Color(0.5, 0.52, 0.56), xf(Vector3(bf.x - 0.065, bf.y + 0.25, bf.z), Vector3(0, 0, 90)), 10)
	for i in 3:
		k.box(Vector3(0.14, 0.02, 0.44), Color(0.6, 0.62, 0.64), at(bf.x - 0.07, bf.y + 0.1 + i * 0.15, bf.z))
	k.cyl(0.18, 0.12, Color(0.95, 0.5, 0.15), xf(Vector3(-2.75, 0.2, 1.95), Vector3(0, 0, 90)), 10)
	k.box(Vector3(0.14, 0.3, 0.04), Color(0.3, 0.3, 0.32), at(-2.75, 0.17, 1.95))


# ================================================================ tier 1: server closet

## A chain-link fence panel from x0 to x1 at z, h tall (diamond wires).
static func _chainlink(k: MeshKit, x0: float, x1: float, z: float, h: float, post: Color, wire: Color, gap := 0.32) -> void:
	var n := maxi(1, int((x1 - x0) / 1.6))
	for i in n + 1:
		k.cyl(0.035, h + 0.05, post, at(x0 + i * (x1 - x0) / n, 0, z), 6)
	k.box(Vector3(x1 - x0, 0.045, 0.045), post, at((x0 + x1) * 0.5, h, z))
	k.box(Vector3(x1 - x0, 0.02, 0.02), post, at((x0 + x1) * 0.5, 0.08, z))
	for dir in [-1.0, 1.0]:
		var a := x0 - h
		while a < x1:
			# wire from (a, 0) to (a + h, h) (dir 1) or mirrored
			var sx := a
			var ex := a + h
			var sy := 0.0
			var ey := h
			if sx < x0:
				sy = x0 - sx
				sx = x0
			if ex > x1:
				ey = h - (ex - x1)
				ex = x1
			if ey - sy > 0.05:
				var pa := Vector3(sx, sy + 0.08, z)
				var pb := Vector3(ex, ey + 0.08 - 0.08 * (ey / h), z)
				if dir < 0:
					pa.x = x0 + x1 - pa.x
					pb.x = x0 + x1 - pb.x
				_beam(k, pa, pb, Vector2(0.012, 0.012), wire)
			a += gap


## Tier 1: a corrugated steel shed with a raised floor and a chain-link cage
## front; a blue shipping-container office sits on its back, cantilevered
## over the stack, reached by a caged ladder and a railed roof walk.
static func _closet(k: MeshKit) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 1717
	var steel := Color(0.8, 0.82, 0.85)
	var trim := Color(0.34, 0.36, 0.4)
	var yel := Color(0.96, 0.76, 0.2)
	var box_c := Color(0.24, 0.42, 0.62)
	var fz := 0.42
	var hh := 3.4
	# ------------------------------------------------ ground: yard concrete, raised floor inside
	var conc := Color(0.7, 0.7, 0.68)
	k.box(Vector3(9.8, 0.05, 2.5), conc, at(0, 0.025, 1.65))
	for i in 5:
		k.box(Vector3(9.8, 0.008, 0.02), conc.darkened(0.1), at(0, 0.052, 0.65 + i * 0.5))
	for x in [-2.6, 2.1]:
		k.box(Vector3(0.08, 0.01, 2.3), yel, at(x, 0.055, 1.7))
	k.box(Vector3(9.8, 0.012, 0.1), yel, at(0, 0.056, fz + 0.12))
	for i in 9:
		k.box(Vector3(0.2, 0.013, 0.1), Color(0.15, 0.15, 0.16), at(-4.6 + i * 1.15, 0.057, fz + 0.12))
	for i in 4:
		k.box(Vector3(0.18, 0.006, 1.6), conc.darkened(0.2), xf(Vector3(-1.0 + i * 0.5, 0.054, 1.9), Vector3(0, 8 - i * 5, 0)))
	k.box(Vector3(0.5, 0.012, 0.3), Color(0.3, 0.3, 0.32), at(0.6, 0.056, 2.6))
	for i in 5:
		k.box(Vector3(0.02, 0.014, 0.28), Color(0.5, 0.5, 0.52), at(0.42 + i * 0.09, 0.06, 2.6))
	var tile := Color(0.74, 0.75, 0.76)
	k.box(Vector3(9.8, 0.08, 3.3), Color(0.32, 0.33, 0.36), at(0, 0.04, -1.25))
	for i in 16:
		for j in 6:
			var tz := -2.6 + j * 0.6
			if tz > fz - 0.2:
				continue
			var perf := (i * 5 + j * 3) % 7 == 0
			var tx := -4.5 + i * 0.6
			k.box(Vector3(0.58, 0.02, 0.58), tile.darkened(0.12) if perf else (tile if (i + j) % 2 == 0 else tile.darkened(0.04)), at(tx, 0.09, tz))
			if perf:
				for q in 9:
					k.box(Vector3(0.05, 0.004, 0.05), Color(0.35, 0.36, 0.38), at(tx - 0.18 + (q % 3) * 0.18, 0.1, tz - 0.18 + (q / 3) * 0.18))
	k.box(Vector3(9.8, 0.1, 0.06), yel, at(0, 0.05, fz - 0.02))
	# ------------------------------------------------ walls: corrugated steel, ribs inside
	_ribs_x(k, -4.9, 4.9, -2.88, 0.08, hh - 0.08, steel, 1.0)
	for s in [-1.0, 1.0]:
		_ribs_z(k, -2.9, fz, s * 4.88, 0.08, hh - 0.08, steel, -s)
		k.box(Vector3(0.14, hh + 0.1, 0.14), trim, at(s * 4.83, (hh + 0.1) * 0.5, fz))
		k.box(Vector3(0.14, hh + 0.1, 0.14), trim, at(s * 4.83, (hh + 0.1) * 0.5, -2.83))
		k.box(Vector3(0.14, 0.12, 3.25), trim, at(s * 4.83, hh, -1.22))
		# a sliding window and a wall AC box in each side
		k.box(Vector3(0.12, 0.66, 1.06), trim, at(s * 4.83, 1.75, -0.6))
		k.box(Vector3(0.13, 0.54, 0.94), Color(0.6, 0.76, 0.86, 0.7), at(s * 4.83, 1.75, -0.6))
		k.box(Vector3(0.13, 0.54, 0.04), trim, at(s * 4.83, 1.75, -0.6))
		k.box(Vector3(0.2, 0.05, 1.1), trim, at(s * 4.79, 1.4, -0.6))
	k.box(Vector3(9.8, 0.14, 0.16), trim, at(0, hh, -2.83))
	# ------------------------------------------------ roof deck over the back strip, ladder, railings
	k.box(Vector3(9.8, 0.12, 0.72), trim, at(0, hh + 0.06, -2.54))
	k.box(Vector3(9.8, 0.02, 0.7), Color(0.5, 0.52, 0.55), at(0, hh + 0.13, -2.54))
	for i in 30:
		k.box(Vector3(0.02, 0.015, 0.66), Color(0.4, 0.42, 0.45), at(-4.8 + i * 0.16, hh + 0.145, -2.54))
	ArchKit.railing(k, Vector3(-4.85, hh + 0.14, -2.2), Vector3(-1.0, hh + 0.14, -2.2), 0.95, yel, 0.6)
	ArchKit.railing(k, Vector3(-4.85, hh + 0.14, -2.86), Vector3(-1.0, hh + 0.14, -2.86), 0.95, yel, 0.6)
	ArchKit.railing(k, Vector3(-4.85, hh + 0.14, -2.86), Vector3(-4.85, hh + 0.14, -2.2), 0.95, yel, 0.6)
	ArchKit.ladder(k, at(-4.3, 0.08, -2.84), hh + 1.0, yel, true)
	# split AC condenser on the roof deck, its pipe down to the indoor unit
	var cd := Vector3(-2.3, hh + 0.14, -2.6)
	k.box(Vector3(0.9, 0.62, 0.36), Color(0.92, 0.92, 0.9), at(cd.x, cd.y + 0.31, cd.z))
	k.cyl(0.22, 0.02, Color(0.25, 0.26, 0.28), xf(Vector3(cd.x - 0.12, cd.y + 0.32, cd.z + 0.18), Vector3(90, 0, 0)), 10)
	for i in 3:
		k.box(Vector3(0.42, 0.015, 0.012), Color(0.6, 0.62, 0.64), at(cd.x - 0.12, cd.y + 0.2 + i * 0.12, cd.z + 0.195))
	for i in 5:
		k.box(Vector3(0.012, 0.5, 0.02), Color(0.7, 0.7, 0.68), at(cd.x + 0.24 + i * 0.04, cd.y + 0.32, cd.z + 0.185))
	_tube(k, [Vector3(cd.x + 0.4, cd.y + 0.2, cd.z), Vector3(-0.3, cd.y + 0.05, cd.z), Vector3(-0.3, 2.85, -2.7)], 0.03, Color(0.95, 0.95, 0.93), 5)
	# ------------------------------------------------ the shipping-container office on top
	var c0 := -0.9
	var c1 := 4.9
	var cy0 := hh + 0.13
	var ch := 2.5
	var cz0 := -2.9
	var cz1 := -1.7
	var cx := (c0 + c1) * 0.5
	var cmz := (cz0 + cz1) * 0.5
	k.box(Vector3(c1 - c0, ch, cz1 - cz0), box_c, at(cx, cy0 + ch * 0.5, cmz))
	_ribs_x(k, c0 + 0.15, c1 - 0.15, cz1 + 0.01, cy0 + 0.12, ch - 0.24, box_c, 1.0, 0.14)
	for yy in [cy0 + 0.06, cy0 + ch - 0.06]:
		k.box(Vector3(c1 - c0, 0.12, 0.08), box_c.darkened(0.2), at(cx, yy, cz1 + 0.03))
		k.box(Vector3(c1 - c0, 0.12, 0.08), box_c.darkened(0.2), at(cx, yy, cz0 + 0.04))
	for x in [c0 + 0.09, c1 - 0.09]:
		for z in [cz0 + 0.09, cz1 - 0.09]:
			k.box(Vector3(0.13, ch, 0.13), box_c.darkened(0.25), at(x, cy0 + ch * 0.5, z))
			for yy in [cy0 + 0.08, cy0 + ch - 0.08]:
				k.box(Vector3(0.17, 0.16, 0.17), Color(0.2, 0.2, 0.22), at(x, yy, z))
	# roof of the container: corrugation, a hatch, vents
	for i in 20:
		k.box(Vector3(0.12, 0.03, cz1 - cz0 - 0.1), box_c.darkened(0.08), at(c0 + 0.2 + i * 0.29, cy0 + ch + 0.015, cmz))
	# door end (facing the roof walk): two leaves, locking bars, one ajar
	var dx := c0 - 0.01
	k.box(Vector3(0.04, ch - 0.2, 0.55), box_c.darkened(0.1), at(dx, cy0 + ch * 0.5, cz0 + 0.33))
	k.box(Vector3(0.04, ch - 0.2, 0.55), box_c.darkened(0.1), xf(Vector3(dx - 0.22, cy0 + ch * 0.5, cz1 - 0.1), Vector3(0, 60, 0)))
	k.box(Vector3(0.03, ch - 0.25, 0.5), Color(1.0, 0.92, 0.6, 0.6), at(dx + 0.02, cy0 + ch * 0.5, cz1 - 0.33))
	for i in 2:
		k.box(Vector3(0.05, ch - 0.15, 0.03), Color(0.6, 0.62, 0.64), at(dx - 0.04, cy0 + ch * 0.5, cz0 + 0.2 + i * 0.25))
		k.box(Vector3(0.06, 0.04, 0.12), Color(0.6, 0.62, 0.64), at(dx - 0.06, cy0 + 1.1, cz0 + 0.24 + i * 0.25))
	k.box(Vector3(0.04, 0.14, 0.1), Color(0.2, 0.2, 0.22), at(dx - 0.03, cy0 + 1.3, cz1 - 0.05))
	k.box(Vector3(0.02, 0.06, 0.06), lit(Color(0.6, 1.0, 0.62), 0.4), at(dx - 0.055, cy0 + 1.33, cz1 - 0.05))
	# front side: two windows, a split AC on brackets, a bulkhead lamp, stencils, a logo plate
	for wx in [0.4, 2.2]:
		k.box(Vector3(1.1, 0.8, 0.08), trim, at(wx, cy0 + 1.45, cz1 + 0.06))
		k.box(Vector3(0.98, 0.68, 0.08), Color(0.6, 0.76, 0.86, 0.7), at(wx, cy0 + 1.45, cz1 + 0.07))
		k.box(Vector3(0.04, 0.68, 0.1), trim, at(wx, cy0 + 1.45, cz1 + 0.08))
		k.box(Vector3(1.2, 0.06, 0.18), trim, at(wx, cy0 + 1.02, cz1 + 0.1))
		for i in 4:
			k.box(Vector3(0.98, 0.03, 0.03), Color(0.85, 0.86, 0.88), at(wx, cy0 + 1.2 + i * 0.16, cz1 + 0.11))
	k.box(Vector3(0.85, 0.32, 0.24), Color(0.95, 0.95, 0.94), at(3.8, cy0 + 1.8, cz1 + 0.16))
	k.box(Vector3(0.75, 0.04, 0.02), Color(0.7, 0.72, 0.74), at(3.8, cy0 + 1.68, cz1 + 0.285))
	k.box(Vector3(0.08, 0.02, 0.01), lit(Color(0.6, 1.0, 0.62), 0.4), at(4.1, cy0 + 1.88, cz1 + 0.285))
	for i in 6:
		k.box(Vector3(0.16, 0.08, 0.012), Color(0.95, 0.95, 0.92), at(3.2 + i * 0.22, cy0 + 2.2, cz1 + 0.08))
	k.box(Vector3(0.4, 0.4, 0.03), yel, at(1.3, cy0 + 1.45, cz1 + 0.08))
	k.box(Vector3(0.22, 0.22, 0.034), Color(0.16, 0.17, 0.2), at(1.3, cy0 + 1.45, cz1 + 0.09))
	k.box(Vector3(0.26, 0.12, 0.12), Color(0.2, 0.2, 0.22), at(1.3, cy0 + 2.2, cz1 + 0.1))
	k.box(Vector3(0.2, 0.06, 0.04), lit(Color(1.0, 0.9, 0.6), 0.35), at(1.3, cy0 + 2.16, cz1 + 0.17))
	# knee braces under the overhang
	for x in [-0.6, 1.0, 2.6, 4.5]:
		_beam(k, Vector3(x, 2.5, -2.82), Vector3(x, cy0 - 0.02, cz1 + 0.12), Vector2(0.08, 0.1), trim)
		k.box(Vector3(0.1, 0.1, cz1 - cz0 - 0.05), trim, at(x, cy0 - 0.05, cmz + 0.02))
	# ------------------------------------------------ cable trays overhead
	ArchKit.cable_tray(k, Vector3(-4.6, 3.05, -2.62), Vector3(4.6, 3.05, -2.62), 1)
	ArchKit.cable_tray(k, Vector3(-4.0, 2.75, -2.5), Vector3(-4.0, 2.75, -1.6), 1)
	ArchKit.cable_tray(k, Vector3(3.2, 2.95, -2.5), Vector3(3.2, 2.95, -1.95), 1)
	for x in [-3.0, -2.38, -1.76]:
		k.box(Vector3(0.012, 3.0 - 2.15, 0.012), Color(0.15, 0.15, 0.16), at(x - 0.1, (3.0 + 2.15) * 0.5, -2.62))
		k.box(Vector3(0.1, 3.0 - 2.15, 0.04), Color(0.25, 0.42, 0.78), at(x + 0.12, (3.0 + 2.15) * 0.5, -2.62))
	for i in 4:
		k.box(Vector3(0.012, 0.3, 0.012), Color(0.15, 0.15, 0.16), at(-4.3 + i * 1.3, 3.35, -2.62))
	# ------------------------------------------------ the back strip: racks, UPS, panel, extinguisher
	var led := [Color(0.5, 1.0, 0.6), Color(1.0, 0.8, 0.3), Color(0.5, 1.0, 0.6), Color(0.4, 0.8, 1.0)]
	for i in 3:
		_rack(k, Vector3(-3.0 + i * 0.62, 0.1, -2.52), 2.05, Color(0.18, 0.19, 0.21), Color(0.28, 0.3, 0.33), led, 0.6, 0.6, i, 8)
	var ups := Vector3(-0.95, 0.1, -2.5)
	k.box(Vector3(0.48, 0.95, 0.62), Color(0.2, 0.21, 0.23), at(ups.x, ups.y + 0.475, ups.z))
	k.box(Vector3(0.2, 0.1, 0.01), lit(Color(0.5, 0.9, 1.0), 0.45), at(ups.x, ups.y + 0.78, ups.z + 0.315))
	for i in 6:
		k.box(Vector3(0.36, 0.02, 0.01), Color(0.32, 0.33, 0.36), at(ups.x, ups.y + 0.2 + i * 0.07, ups.z + 0.315))
	k.box(Vector3(0.48, 0.5, 0.6), Color(0.24, 0.25, 0.27), at(ups.x, ups.y + 1.2, ups.z))
	k.box(Vector3(0.06, 0.03, 0.01), lit(Color(0.5, 1.0, 0.6), 0.4), at(ups.x - 0.15, ups.y + 1.3, ups.z + 0.305))
	# steel parts cabinet, electrical panel with conduits, extinguisher, emergency light, signs
	k.box(Vector3(0.62, 1.8, 0.5), Color(0.6, 0.63, 0.67), at(-0.25, 0.1 + 0.9, -2.58))
	k.box(Vector3(0.01, 1.7, 0.01), Color(0.3, 0.32, 0.36), at(-0.25, 1.0, -2.33))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.02, 0.12, 0.03), Color(0.3, 0.32, 0.36), at(-0.25 + sx * 0.06, 1.0, -2.32))
	k.box(Vector3(0.5, 0.7, 0.14), Color(0.66, 0.68, 0.7), at(0.45, 1.5, -2.79))
	k.box(Vector3(0.46, 0.66, 0.01), Color(0.6, 0.62, 0.64), at(0.45, 1.5, -2.715))
	k.box(Vector3(0.12, 0.12, 0.012), yel, at(0.45, 1.68, -2.71))
	for i in 3:
		k.box(Vector3(0.04, 3.0 - 1.85, 0.04), Color(0.6, 0.62, 0.64), at(0.3 + i * 0.15, (3.0 + 1.85) * 0.5, -2.8))
	k.cyl(0.08, 0.42, Color(0.86, 0.18, 0.16), at(1.05, 0.5, -2.75), 8)
	k.box(Vector3(0.06, 0.08, 0.06), Color(0.15, 0.15, 0.16), at(1.05, 0.96, -2.75))
	k.box(Vector3(0.24, 0.24, 0.01), Color(0.86, 0.18, 0.16), at(1.05, 1.25, -2.81))
	k.box(Vector3(0.38, 0.12, 0.1), Color(0.92, 0.92, 0.9), at(1.3, 2.25, -2.79))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.08, 0.06, 0.06), lit(Color(1.0, 0.95, 0.8), 0.4), at(1.3 + sx * 0.12, 2.2, -2.72))
	k.box(Vector3(0.3, 0.2, 0.01), Color(0.2, 0.62, 0.3), at(-1.5, 2.3, -2.81))
	k.box(Vector3(0.2, 0.06, 0.012), Color(0.95, 0.95, 0.95), at(-1.5, 2.3, -2.805))
	# split AC indoor unit
	k.box(Vector3(1.0, 0.32, 0.24), Color(0.96, 0.96, 0.95), at(-0.3, 2.62, -2.74))
	k.box(Vector3(0.9, 0.04, 0.05), Color(0.8, 0.82, 0.84), xf(Vector3(-0.3, 2.47, -2.62), Vector3(30, 0, 0)))
	k.box(Vector3(0.05, 0.02, 0.01), lit(Color(0.4, 0.9, 1.0), 0.4), at(0.1, 2.68, -2.615))
	# behind the core: spare cables on hooks, parts bins on a shelf
	k.box(Vector3(2.9, 0.03, 0.3), Color(0.6, 0.63, 0.67), at(3.35, 1.95, -2.7))
	for i in 8:
		k.box(Vector3(0.28, 0.16, 0.24), [Color(0.3, 0.5, 0.86), Color(0.86, 0.3, 0.26), yel, Color(0.4, 0.42, 0.46)][i % 4], at(2.05 + i * 0.36, 2.05, -2.7))
	for i in 4:
		k.torus(0.13, 0.025, [Color(0.3, 0.5, 0.86), Color(0.95, 0.7, 0.3), Color(0.9, 0.9, 0.9), Color(0.3, 0.75, 0.4)][i], xf(Vector3(2.2 + i * 0.75, 1.55, -2.8), Vector3(90, 0, 0)), 10, 3)
	# left: a wall network box, a crash cart in the corner
	k.box(Vector3(0.55, 0.5, 0.3), Color(0.22, 0.23, 0.26), at(-3.7, 1.9, -2.72))
	_leds(k, -3.9, 1.75, -2.565, 8, 0.05, led, 3)
	var cc := Vector3(-4.2, 0.1, -0.15)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.03, 0.95, 0.03), Color(0.6, 0.62, 0.64), at(cc.x + sx * 0.25, cc.y + 0.5, cc.z + sz * 0.2))
			k.cyl(0.04, 0.04, Color(0.15, 0.15, 0.15), xf(Vector3(cc.x + sx * 0.25, cc.y + 0.04, cc.z + sz * 0.2), Vector3(0, 0, 90)), 6)
	for yy in [0.3, 0.95]:
		k.box(Vector3(0.56, 0.03, 0.46), Color(0.55, 0.57, 0.6), at(cc.x, cc.y + yy, cc.z))
	k.box(Vector3(0.4, 0.28, 0.04), Color(0.15, 0.15, 0.17), xf(Vector3(cc.x, cc.y + 1.25, cc.z - 0.1), Vector3(-8, 0, 0)))
	k.box(Vector3(0.35, 0.22, 0.01), lit(Color(0.5, 0.9, 1.0), 0.45), xf(Vector3(cc.x, cc.y + 1.25, cc.z - 0.077), Vector3(-8, 0, 0)))
	k.box(Vector3(0.4, 0.02, 0.15), Color(0.2, 0.2, 0.22), at(cc.x, cc.y + 0.97, cc.z + 0.1))
	k.box(Vector3(0.3, 0.2, 0.3), Color(0.72, 0.56, 0.38), at(cc.x, cc.y + 0.43, cc.z))
	# a wet-floor sign in the right corner
	k.box(Vector3(0.3, 0.5, 0.02), yel, xf(Vector3(4.45, 0.33, 0.1), Vector3(14, -30, 0)))
	k.box(Vector3(0.3, 0.5, 0.02), yel, xf(Vector3(4.45, 0.33, 0.2), Vector3(-14, -30, 0)))
	# ------------------------------------------------ the chain-link cage front with its gate open
	var wire := Color(0.62, 0.64, 0.67)
	_chainlink(k, -4.8, -1.0, fz, 2.3, Color(0.55, 0.57, 0.6), wire)
	_chainlink(k, 1.0, 4.8, fz, 2.3, Color(0.55, 0.57, 0.6), wire)
	for s in [-1.0, 1.0]:
		var hinge := Vector3(s * 1.0, 0, fz)
		var leaf := xf(hinge, Vector3(0, s * 72.0, 0))
		k.box(Vector3(0.04, 2.1, 0.04), wire.darkened(0.2), leaf * at(-s * 0.02, 1.15, 0))
		k.box(Vector3(0.04, 2.1, 0.04), wire.darkened(0.2), leaf * at(-s * 0.95, 1.15, 0))
		k.box(Vector3(0.95, 0.04, 0.04), wire.darkened(0.2), leaf * at(-s * 0.48, 2.18, 0))
		k.box(Vector3(0.95, 0.04, 0.04), wire.darkened(0.2), leaf * at(-s * 0.48, 0.12, 0))
		_beam(k, leaf * Vector3(-s * 0.05, 0.15, 0), leaf * Vector3(-s * 0.93, 2.15, 0), Vector2(0.02, 0.02), wire)
		_beam(k, leaf * Vector3(-s * 0.93, 0.15, 0), leaf * Vector3(-s * 0.05, 2.15, 0), Vector2(0.02, 0.02), wire)
		k.box(Vector3(0.5, 0.3, 0.02), yel, at(s * 1.8, 1.45, fz + 0.03))
		k.box(Vector3(0.44, 0.06, 0.022), Color(0.15, 0.15, 0.16), at(s * 1.8, 1.5, fz + 0.035))
		k.box(Vector3(0.3, 0.04, 0.022), Color(0.15, 0.15, 0.16), at(s * 1.8, 1.4, fz + 0.035))
	# CCTV on the left post, a floodlight pole at the right corner
	k.box(Vector3(0.1, 0.1, 0.26), Color(0.92, 0.92, 0.9), xf(Vector3(-4.7, hh - 0.2, fz + 0.15), Vector3(20, 25, 0)))
	k.box(Vector3(0.06, 0.06, 0.02), Color(0.1, 0.1, 0.12), xf(Vector3(-4.66, hh - 0.25, fz + 0.28), Vector3(20, 25, 0)))
	k.cyl(0.05, 3.2, Color(0.4, 0.42, 0.46), at(4.65, 0.05, 2.75), 6)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.24, 0.2, 0.12), Color(0.24, 0.25, 0.28), xf(Vector3(4.65 + sx * 0.13, 3.2, 2.7), Vector3(35, 0, 0)))
		k.box(Vector3(0.2, 0.14, 0.02), lit(Color(0.95, 1.0, 0.9), 0.35), xf(Vector3(4.65 + sx * 0.13, 3.17, 2.63), Vector3(35, 0, 0)))
	# ------------------------------------------------ the yard: a pallet of boxed GPUs, a pallet jack, drums
	var pp := Vector3(2.85, 0.05, 2.4)
	for i in 3:
		k.box(Vector3(1.0, 0.1, 0.1), Color(0.72, 0.58, 0.4), at(pp.x, pp.y + 0.05, pp.z - 0.4 + i * 0.4))
	k.box(Vector3(1.0, 0.03, 0.9), Color(0.76, 0.62, 0.44), at(pp.x, pp.y + 0.115, pp.z))
	for i in 6:
		var bx := pp.x - 0.25 + (i % 2) * 0.5
		var bz := pp.z - 0.27 + (i / 2) * 0.27
		k.box(Vector3(0.46, 0.34, 0.25), Color(0.18, 0.19, 0.21), at(bx, pp.y + 0.3, bz))
		k.box(Vector3(0.3, 0.03, 0.01), Color(0.5, 0.86, 0.4), at(bx, pp.y + 0.36, bz + 0.13))
	k.box(Vector3(0.96, 0.36, 0.84), Color(0.85, 0.9, 0.95, 1.0), at(pp.x, pp.y + 0.66, pp.z))
	k.box(Vector3(0.97, 0.02, 0.85), Color(0.7, 0.75, 0.8), at(pp.x, pp.y + 0.6, pp.z))
	var pj := Vector3(2.75, 0.05, 1.75)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.12, 0.06, 0.9), Color(0.86, 0.2, 0.2), at(pj.x + sx * 0.18, pj.y + 0.06, pj.z + 0.05))
	k.box(Vector3(0.5, 0.25, 0.16), Color(0.86, 0.2, 0.2), at(pj.x, pj.y + 0.16, pj.z - 0.45))
	_beam(k, Vector3(pj.x, pj.y + 0.25, pj.z - 0.5), Vector3(pj.x, pj.y + 1.0, pj.z - 0.85), Vector2(0.04, 0.04), Color(0.2, 0.2, 0.22))
	k.box(Vector3(0.24, 0.05, 0.05), Color(0.2, 0.2, 0.22), at(pj.x, pj.y + 1.02, pj.z - 0.87))
	for i in 2:
		k.cyl(0.18, 0.6, Color(0.24, 0.42, 0.7), at(4.55, 0.05, 0.0 + i * 0.0 - 0.1 + i * 0.0), 10)
	k.cyl(0.19, 0.03, Color(0.2, 0.36, 0.6), at(4.55, 0.35, -0.1), 10)


## Server closet: a 2-post open rack with patch panels, a switch with
## blinking ports, rainbow patch cords and a little UPS at its feet.
static func _router1(k: MeshKit) -> void:
	var z := TZ
	var post := Color(0.2, 0.21, 0.24)
	k.box(Vector3(0.9, 0.06, 0.7), post, at(0, 0.11, z))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.07, 2.1, 0.12), post, at(sx * 0.32, 1.13, z))
		for i in 30:
			k.box(Vector3(0.02, 0.012, 0.13), post.lightened(0.2), at(sx * 0.32, 0.25 + i * 0.065, z))
		# vertical cable managers full of cords
		k.box(Vector3(0.14, 1.9, 0.2), Color(0.12, 0.12, 0.14), at(sx * 0.45, 1.1, z))
		for c in 3:
			k.box(Vector3(0.03, 1.8, 0.03), [Color(0.3, 0.55, 0.95), Color(0.95, 0.75, 0.25), Color(0.9, 0.35, 0.4)][c], at(sx * 0.45 - 0.04 + c * 0.04, 1.1, z + 0.08))
	k.box(Vector3(0.78, 0.06, 0.14), post, at(0, 2.2, z))
	var cords := [Color(0.3, 0.55, 0.95), Color(0.95, 0.75, 0.25), Color(0.9, 0.35, 0.4), Color(0.4, 0.8, 0.45), Color(0.95, 0.95, 0.95)]
	for u in 9:
		var y := 0.42 + u * 0.19
		var kind := u % 3
		k.box(Vector3(0.6, 0.15, 0.3), Color(0.14, 0.15, 0.17) if kind != 1 else Color(0.82, 0.84, 0.86), at(0, y, z - 0.05))
		if kind == 1:
			_leds(k, -0.26, y + 0.03, z + 0.105, 11, 0.05, [Color(0.5, 1.0, 0.6), Color(1.0, 0.8, 0.3)], u)
		else:
			for j in 8:
				k.box(Vector3(0.04, 0.035, 0.02), Color(0.3, 0.32, 0.34), at(-0.24 + j * 0.068, y, z + 0.105))
				k.box(Vector3(0.022, 0.022, 0.14), cords[(u + j) % cords.size()], at(-0.24 + j * 0.068, y - 0.01, z + 0.18))
			k.box(Vector3(0.55, 0.025, 0.04), cords[u % cords.size()], at(0, y - 0.07, z + 0.24))
	k.box(Vector3(0.5, 0.3, 0.42), Color(0.2, 0.21, 0.23), at(0, 0.28, z))
	k.box(Vector3(0.14, 0.05, 0.01), lit(Color(0.5, 0.9, 1.0), 0.45), at(0.1, 0.36, z + 0.215))
	k.box(Vector3(0.36, 0.06, 0.36), Color(0.2, 0.21, 0.24), at(0, 2.26, z))


## Server closet: three rack cabinets: one open on its GPU servers, one with a
## perforated door, one with a glass door; exhaust fans on top (the vent).
static func _core1(k: MeshKit) -> void:
	var z := TZ
	var cx := -0.25
	var body := Color(0.16, 0.17, 0.19)
	k.box(Vector3(2.75, 0.1, 1.25), Color(0.3, 0.32, 0.36), at(cx, 0.05, z))
	var h := 2.15
	var rz := z
	for i in 3:
		var x := cx - 0.9 + i * 0.9
		k.box(Vector3(0.86, h, 1.1), body, at(x, 0.1 + h * 0.5, rz))
		k.box(Vector3(0.88, 0.06, 1.12), body.darkened(0.3), at(x, 0.1 + h - 0.03, rz))
		var fz := rz + 0.555
		match i:
			0:
				# door open: GPU servers with glowing fan rows
				k.box(Vector3(0.04, h - 0.1, 0.8), body.lightened(0.08), xf(Vector3(x - 0.43 - 0.3, 0.1 + h * 0.5, fz + 0.28), Vector3(0, -70, 0)))
				for u in 6:
					var y := 0.32 + u * 0.3
					k.box(Vector3(0.76, 0.26, 0.02), Color(0.24, 0.25, 0.28), at(x, y, fz - 0.03))
					for f in 4:
						k.cyl(0.05, 0.02, Color(0.32, 0.34, 0.38), xf(Vector3(x - 0.27 + f * 0.18, y + 0.02, fz - 0.02), Vector3(90, 0, 0)), 6)
						k.box(Vector3(0.04, 0.012, 0.01), lit(Color(0.5, 1.0, 0.6), 0.45), at(x - 0.27 + f * 0.18, y - 0.1, fz - 0.015))
			1:
				k.box(Vector3(0.78, h - 0.12, 0.02), Color(0.26, 0.27, 0.3), at(x, 0.1 + h * 0.5, fz))
				for row in 18:
					for col in 6:
						k.box(Vector3(0.05, 0.03, 0.005), Color(0.12, 0.12, 0.14), at(x - 0.3 + col * 0.12, 0.25 + row * 0.105, fz + 0.012))
				k.box(Vector3(0.03, 0.2, 0.04), Color(0.6, 0.62, 0.64), at(x + 0.33, 1.1, fz + 0.03))
				_leds(k, x - 0.3, 0.1 + h - 0.15, fz + 0.015, 5, 0.06, [Color(0.5, 1.0, 0.6)], 1)
			_:
				k.box(Vector3(0.78, h - 0.12, 0.02), Color(0.4, 0.6, 0.78, 0.7), at(x, 0.1 + h * 0.5, fz))
				for u in 8:
					k.box(Vector3(0.7, 0.02, 0.01), Color(0.15, 0.15, 0.18), at(x, 0.3 + u * 0.24, fz + 0.012))
				k.box(Vector3(0.03, 0.2, 0.04), Color(0.6, 0.62, 0.64), at(x + 0.33, 1.1, fz + 0.03))
		# side cable bundles
		k.box(Vector3(0.05, h - 0.3, 0.05), [Color(0.3, 0.55, 0.95), Color(0.95, 0.75, 0.25), Color(0.9, 0.35, 0.4)][i], at(x + 0.4, 0.1 + h * 0.5, rz - 0.5))
	# top: exhaust fan boxes (the vent), a cable ladder running up
	for i in 3:
		var x := cx - 0.9 + i * 0.9
		k.box(Vector3(0.7, 0.16, 0.7), Color(0.22, 0.23, 0.26), at(x, 0.1 + h + 0.08, rz + 0.1))
		k.cyl(0.25, 0.02, Color(0.12, 0.12, 0.14), at(x, 0.1 + h + 0.16, rz + 0.1), 10)
		for b in 3:
			k.box(Vector3(0.44, 0.012, 0.05), Color(0.5, 0.52, 0.56), xf(Vector3(x, 0.1 + h + 0.18, rz + 0.1), Vector3(0, b * 60, 0)))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 0.6, 0.04), Color(0.5, 0.52, 0.56), at(cx + 0.9 + sx * 0.15, 0.1 + h + 0.3, rz - 0.4))
	for i in 4:
		k.box(Vector3(0.3, 0.025, 0.04), Color(0.5, 0.52, 0.56), at(cx + 0.9, 0.1 + h + 0.1 + i * 0.15, rz - 0.4))
	k.box(Vector3(0.6, 0.2, 0.05), Color(0.94, 0.95, 0.96), at(cx, 0.1 + h - 0.25, rz + 0.58))
	k.box(Vector3(0.4, 0.05, 0.01), Color(0.15, 0.16, 0.2), at(cx, 0.1 + h - 0.25, rz + 0.61))


## Server closet: a steel workbench with a yellow frame and a red tool chest.
static func _bench1(k: MeshKit) -> void:
	var yel := Color(0.96, 0.76, 0.2)
	k.box(Vector3(1.42, 0.05, 0.92), Color(0.62, 0.64, 0.68), at(0, 0.745, 0))
	k.box(Vector3(1.44, 0.03, 0.94), Color(0.4, 0.42, 0.46), at(0, 0.71, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.06, 0.7, 0.06), yel, at(sx * 0.66, 0.35, sz * 0.42))
		k.box(Vector3(0.06, 0.05, 0.84), yel, at(sx * 0.66, 0.15, 0))
	k.box(Vector3(1.3, 0.05, 0.06), yel, at(0, 0.15, -0.42))
	k.box(Vector3(0.55, 0.5, 0.45), Color(0.82, 0.2, 0.18), at(-0.3, 0.3, 0.05))
	for i in 4:
		k.box(Vector3(0.5, 0.01, 0.01), Color(0.3, 0.3, 0.32), at(-0.3, 0.12 + i * 0.11, 0.28))
		k.box(Vector3(0.14, 0.02, 0.02), Color(0.7, 0.72, 0.74), at(-0.3, 0.16 + i * 0.11, 0.29))
	for i in 3:
		k.cyl(0.07, 0.3, Color(0.4, 0.6, 0.86), at(0.3 + i * 0.16, 0.05, 0.0), 6)


## Server closet: a grey UPS battery cabinet with louvres, a status screen
## and hazard stripes; the cells sit in its top tray.
static func _dock1(k: MeshKit) -> void:
	var body := Color(0.72, 0.74, 0.78)
	k.box(Vector3(1.3, 0.08, 0.95), Color(0.3, 0.32, 0.36), at(0, 0.04, 0))
	k.box(Vector3(1.24, 0.66, 0.88), body, at(0, 0.41, 0))
	k.box(Vector3(1.3, 0.06, 0.94), Color(0.34, 0.36, 0.4), at(0, 0.77, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 0.12, 0.94), Color(0.34, 0.36, 0.4), at(sx * 0.63, 0.86, 0))
	for i in 7:
		k.box(Vector3(0.5, 0.025, 0.02), body.darkened(0.25), at(-0.28, 0.18 + i * 0.065, 0.45))
	k.box(Vector3(0.3, 0.16, 0.01), Color(0.15, 0.16, 0.18), at(0.3, 0.55, 0.445))
	k.box(Vector3(0.26, 0.11, 0.012), lit(Color(0.5, 1.0, 0.6), 0.45), at(0.3, 0.55, 0.45))
	for i in 3:
		k.box(Vector3(0.05, 0.05, 0.012), lit([Color(0.5, 1.0, 0.6), Color(1.0, 0.8, 0.3), Color(0.5, 1.0, 0.6)][i], 0.4), at(0.2 + i * 0.1, 0.38, 0.45))
	for i in 6:
		k.box(Vector3(0.12, 0.06, 0.012), Color(0.96, 0.76, 0.2) if i % 2 == 0 else Color(0.15, 0.15, 0.16), xf(Vector3(-0.5 + i * 0.2, 0.12, 0.45), Vector3(0, 0, 30)))
	_tube(k, [Vector3(-0.4, 0.5, -0.45), Vector3(-0.4, 0.1, -0.6), Vector3(-0.2, 0.1, -1.4), Vector3(-0.1, 0.1, -1.75)], 0.04, Color(0.15, 0.15, 0.16), 5)
	_tube(k, [Vector3(-0.25, 0.5, -0.45), Vector3(-0.25, 0.12, -0.6), Vector3(-0.05, 0.12, -1.4), Vector3(0.05, 0.12, -1.75)], 0.04, Color(0.86, 0.2, 0.18), 5)

# ================================================================ tier 2: white server room

## Tier 2: a white two-storey clean room. The ground floor holds the stack
## between white panel walls, a front portal and a low glass balustrade; a
## glazed first floor cantilevers over the back; a glass stair core rises at
## the left; the roof carries screened plant and a logo.
static func _campus(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var white2 := Color(0.86, 0.88, 0.9)
	var teal := Color(0.3, 0.66, 0.68)
	var pane := Color(0.66, 0.8, 0.88)
	var pane_lit := Color(0.58, 0.84, 0.92, 0.66)
	var fz := 0.45
	var g1 := 3.3              # first floor level
	var top := 6.3             # main roof
	# ------------------------------------------------ ground: pavers outside, white raised floor inside
	var pav := Color(0.84, 0.84, 0.82)
	k.box(Vector3(9.8, 0.05, 2.45), pav, at(0, 0.025, 1.68))
	for i in 20:
		k.box(Vector3(0.012, 0.006, 2.45), pav.darkened(0.12), at(-4.75 + i * 0.5, 0.052, 1.68))
	for j in 5:
		k.box(Vector3(9.8, 0.006, 0.012), pav.darkened(0.12), at(0, 0.052, 0.7 + j * 0.5))
	k.box(Vector3(9.8, 0.12, 0.14), Color(0.92, 0.92, 0.9), at(0, 0.06, 2.83))
	k.box(Vector3(2.6, 0.03, 2.45), Color(0.9, 0.9, 0.88), at(-0.3, 0.06, 1.68))
	for i in 6:
		k.box(Vector3(2.4, 0.004, 0.06), teal.lightened(0.3), at(-0.3, 0.078, 0.75 + i * 0.4))
	var tile := Color(0.9, 0.91, 0.92)
	k.box(Vector3(9.8, 0.08, 3.35), Color(0.7, 0.72, 0.74), at(0, 0.04, -1.22))
	for i in 16:
		for j in 6:
			var tz := -2.6 + j * 0.6
			if tz > fz - 0.2:
				continue
			var tx := -4.5 + i * 0.6
			var perf := (i * 3 + j * 5) % 6 == 0
			k.box(Vector3(0.58, 0.02, 0.58), tile.darkened(0.08) if perf else tile, at(tx, 0.09, tz))
			if perf:
				for q in 4:
					k.box(Vector3(0.4, 0.004, 0.03), teal.lightened(0.2), at(tx, 0.101, tz - 0.15 + q * 0.1))
	k.box(Vector3(9.8, 0.02, 0.05), teal, at(0, 0.1, fz - 0.05))
	# ------------------------------------------------ ground floor walls: white panels, a teal band
	k.box(Vector3(9.8, g1, 0.12), white, at(0, g1 * 0.5, -2.84))
	for s in [-1.0, 1.0]:
		var x: float = s * 4.86
		k.box(Vector3(0.1, g1, 3.3), white, at(x, g1 * 0.5, -1.22))
		for i in 5:
			k.box(Vector3(0.12, g1 - 0.1, 0.015), white2, at(x, g1 * 0.5, -2.4 + i * 0.66))
		k.box(Vector3(0.12, 0.12, 3.3), teal, at(x, 1.0, -1.22))
		k.box(Vector3(0.12, 0.08, 3.3), white2, at(x, 0.04 + 0.08, -1.22))
	# a white door with a card reader in the right wall
	k.box(Vector3(0.13, 2.1, 0.95), Color(0.8, 0.82, 0.84), at(4.82, 1.05, -0.35))
	k.box(Vector3(0.14, 1.9, 0.8), white, at(4.82, 1.0, -0.35))
	k.box(Vector3(0.15, 0.04, 0.2), Color(0.6, 0.62, 0.64), at(4.8, 1.05, -0.62))
	k.box(Vector3(0.15, 0.14, 0.09), Color(0.2, 0.22, 0.26), at(4.8, 1.35, -0.92))
	k.box(Vector3(0.16, 0.04, 0.04), lit(Color(0.42, 0.96, 0.9), 0.4), at(4.79, 1.4, -0.92))
	# ------------------------------------------------ a full-height portal frame and a low glass balustrade
	var ph := top + 0.3
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.2, ph, 0.2), white, at(s * 4.8, ph * 0.5, fz))
		k.box(Vector3(0.22, 0.1, 0.22), teal, at(s * 4.8, 1.0, fz))
		k.box(Vector3(0.2, 0.22, -1.7 - fz - 0.1), white, at(s * 4.8, ph - 0.11, (fz - 1.7) * 0.5))
		k.box(Vector3(0.21, 0.05, -1.7 - fz - 0.1), teal, at(s * 4.8, ph - 0.25, (fz - 1.7) * 0.5))
		k.box(Vector3(0.1, 0.4, 0.04), lit(Color(0.9, 1.0, 1.0), 0.35), at(s * 4.8, 2.6, fz + 0.11))
	k.box(Vector3(9.8, 0.2, 0.2), white, at(0, ph - 0.1, fz))
	k.box(Vector3(9.82, 0.05, 0.22), teal, at(0, ph - 0.22, fz))
	for s in [-1.0, 1.0]:
		var xa: float = s * 1.25
		var xb: float = s * 4.68
		k.box(Vector3(absf(xb - xa), 0.9, 0.03), pane, at((xa + xb) * 0.5, 0.55, fz))
		k.box(Vector3(absf(xb - xa), 0.05, 0.07), teal, at((xa + xb) * 0.5, 1.02, fz))
		for i in 5:
			k.box(Vector3(0.04, 0.95, 0.05), white, at(xa + (xb - xa) * i / 4.0, 0.55, fz))
	# ------------------------------------------------ the glass stair core (left)
	var sx0 := -4.9
	var sx1 := -3.5
	var sz0 := -2.9
	var sz1 := -1.95
	var sh := 6.9
	var scx := (sx0 + sx1) * 0.5
	var scz := (sz0 + sz1) * 0.5
	k.box(Vector3(sx1 - sx0, sh, sz1 - sz0), white, at(scx, sh * 0.5, scz))
	k.box(Vector3(0.9, sh - 0.8, 0.04), pane, at(scx + 0.1, sh * 0.5, sz1 + 0.01))
	for i in 5:
		k.box(Vector3(0.9, 0.04, 0.06), white, at(scx + 0.1, 0.4 + i * (sh - 0.8) / 4.0, sz1 + 0.02))
	for f in 4:
		var y0 := 0.5 + f * 1.55
		var dirx := 1.0 if f % 2 == 0 else -1.0
		_beam(k, Vector3(scx + 0.1 - dirx * 0.38, y0, sz1 + 0.05), Vector3(scx + 0.1 + dirx * 0.38, y0 + 1.5, sz1 + 0.05), Vector2(0.05, 0.06), teal)
		for st in 6:
			k.box(Vector3(0.06, 0.02, 0.04), white2, at(scx + 0.1 - dirx * 0.33 + dirx * st * 0.13, y0 + 0.13 + st * 0.25, sz1 + 0.06))
	k.box(Vector3(sx1 - sx0 + 0.04, 0.12, sz1 - sz0 + 0.04), teal, at(scx, sh - 0.06, scz))
	k.box(Vector3(sx1 - sx0 - 0.1, 0.03, sz1 - sz0 - 0.1), Color(0.8, 0.82, 0.84), at(scx, sh + 0.015, scz))
	# a vertical blade sign on the stair core's corner
	k.box(Vector3(0.08, 2.6, 0.5), white, at(sx0 + 0.06, 4.6, sz1 + 0.18))
	k.box(Vector3(0.1, 2.4, 0.06), teal, at(sx0 + 0.06, 4.6, sz1 + 0.42))
	for i in 4:
		k.box(Vector3(0.09, 0.3, 0.32), teal if i == 0 else Color(0.26, 0.29, 0.33), at(sx0 + 0.06, 5.6 - i * 0.5 - (0.0 if i == 0 else 0.1), sz1 + 0.18))
	# ------------------------------------------------ the first floor, cantilevered over the stack
	var fx0 := sx1
	var fx1 := 4.9
	var fzf := -1.7
	var fmx := (fx0 + fx1) * 0.5
	var fmz := (-2.9 + fzf) * 0.5
	k.box(Vector3(fx1 - fx0, top - g1, 1.2), white, at(fmx, (g1 + top) * 0.5, fmz))
	# slab edge, teal floor band, spandrel (wall gear hangs here), the curtain, the top band
	k.box(Vector3(fx1 - fx0, 0.22, 0.06), white2, at(fmx, g1 + 0.11, fzf + 0.03))
	k.box(Vector3(fx1 - fx0, 0.07, 0.07), teal, at(fmx, g1 + 0.25, fzf + 0.04))
	var cw0 := 3.95
	var cw1 := 5.85
	k.box(Vector3(fx1 - fx0 - 0.1, cw1 - cw0, 0.04), pane, at(fmx, (cw0 + cw1) * 0.5, fzf + 0.02))
	var ncol := 14
	for i in ncol:
		var px := fx0 + 0.05 + (i + 0.5) * (fx1 - fx0 - 0.1) / ncol
		if (i * 7) % 5 == 1:
			k.box(Vector3((fx1 - fx0) / ncol - 0.06, cw1 - cw0 - 0.08, 0.02), pane_lit, at(px, (cw0 + cw1) * 0.5, fzf + 0.045))
	for i in ncol + 1:
		k.box(Vector3(0.05, cw1 - cw0, 0.07), white, at(fx0 + 0.05 + i * (fx1 - fx0 - 0.1) / ncol, (cw0 + cw1) * 0.5, fzf + 0.04))
	for y in [cw0, 4.7, cw1]:
		k.box(Vector3(fx1 - fx0, 0.05, 0.08), white, at(fmx, y, fzf + 0.04))
	# sunshade fins
	for i in 7:
		k.box(Vector3(0.06, cw1 - cw0 + 0.3, 0.3), white, at(fx0 + 0.6 + i * 1.25, (cw0 + cw1) * 0.5, fzf + 0.15))
	# the logo on the top band: a teal token mark and lettering
	k.box(Vector3(3.0, 0.36, 0.05), white, at(1.9, 6.08, fzf + 0.03))
	k.cyl(0.2, 0.05, teal, xf(Vector3(0.65, 6.08, fzf + 0.04), Vector3(90, 0, 0)), 10)
	k.cyl(0.1, 0.06, white, xf(Vector3(0.65, 6.08, fzf + 0.045), Vector3(90, 0, 0)), 8)
	for i in 5:
		k.box(Vector3(0.28 - (i % 2) * 0.06, 0.16, 0.04), Color(0.26, 0.29, 0.33), at(1.1 + i * 0.36, 6.08, fzf + 0.06))
	# window band on the right end and the back
	k.box(Vector3(0.04, 1.2, 0.9), pane, at(fx1 - 0.03, 4.9, fmz))
	k.box(Vector3(fx1 - fx0 - 0.4, 1.2, 0.04), pane, at(fmx, 4.9, -2.9))
	# parapet with teal coping
	ArchKit.parapet(k, Vector3(fmx, top, fmz), fx1 - fx0, 1.2, 2)
	k.box(Vector3(fx1 - fx0 + 0.02, 0.04, 0.12), teal, at(fmx, top + 0.32, fzf + 0.05))
	# the soffit under the cantilever: downlights
	for i in 10:
		k.box(Vector3(0.14, 0.02, 0.14), lit(Color(0.9, 1.0, 1.0), 0.35), at(fx0 + 0.6 + i * 0.85, g1 - 0.01, -1.85))
	# ------------------------------------------------ roof: screened plant, a hatch
	var rz := -2.3
	var scr0 := 2.25
	var scr1 := 4.7
	for i in 2:
		ArchKit.ac_unit(k, at(scr0 + 0.65 + i * 1.15, top + 0.03, rz), 2, 1.0)
	for i in 14:
		k.box(Vector3(scr1 - scr0, 0.04, 0.12), white, xf(Vector3((scr0 + scr1) * 0.5, top + 0.12 + i * 0.075, fzf - 0.12), Vector3(-35, 0, 0)))
	for x in [scr0, (scr0 + scr1) * 0.5, scr1]:
		k.box(Vector3(0.06, 1.15, 0.06), white2, at(x, top + 0.58, fzf - 0.12))
	k.box(Vector3(scr1 - scr0, 0.05, 0.08), teal, at((scr0 + scr1) * 0.5, top + 1.17, fzf - 0.12))
	k.box(Vector3(0.6, 0.18, 0.6), white2, at(-3.0, top + 0.12, -2.55))
	_tube(k, [Vector3(scr0 + 0.4, top + 0.25, -2.75), Vector3(-0.4, top + 0.25, -2.75), Vector3(-0.4, top + 0.1, -2.75)], 0.06, Color(0.8, 0.82, 0.84), 6)
	# ------------------------------------------------ the back strip: white racks with teal lights
	var led := [Color(0.42, 0.96, 0.9), Color(0.42, 0.96, 0.9), Color(0.5, 0.7, 1.0)]
	for i in 8:
		_rack(k, Vector3(-3.15 + i * 0.6, 0.1, -2.5), 2.2, white, Color(0.86, 0.88, 0.9), led, 0.58, 0.58, i, 8)
		k.box(Vector3(0.5, 0.04, 0.02), lit(teal.lightened(0.2), 0.45), at(-3.15 + i * 0.6, 2.22, -2.2))
	k.box(Vector3(4.8, 0.08, 0.6), Color(0.8, 0.82, 0.84), at(-1.05, 2.36, -2.5))
	for c in 4:
		k.box(Vector3(4.7, 0.05, 0.05), [Color(0.3, 0.55, 0.95), Color(0.95, 0.75, 0.25), teal, Color(0.95, 0.95, 0.95)][c], at(-1.05, 2.43, -2.65 + c * 0.1))
	# fire suppression tanks behind the core, a manifold and a control panel
	for i in 6:
		var tx := 2.05 + i * 0.46
		k.cyl(0.16, 1.45, Color(0.86, 0.18, 0.16), at(tx, 0.1, -2.66), 10, 0.03)
		k.sphere(0.16, Color(0.86, 0.18, 0.16), xf(Vector3(tx, 1.55, -2.66), Vector3.ZERO, Vector3(1, 0.5, 1)), 8, 4)
		k.cyl(0.05, 0.12, Color(0.3, 0.3, 0.32), at(tx, 1.6, -2.66), 6)
		k.cyl(0.05, 0.02, Color(0.95, 0.95, 0.94), xf(Vector3(tx, 1.1, -2.5), Vector3(90, 0, 0)), 6)
	_tube(k, [Vector3(1.95, 1.78, -2.66), Vector3(4.6, 1.78, -2.66), Vector3(4.6, 3.2, -2.66)], 0.045, Color(0.86, 0.18, 0.16), 6)
	# CRAC units in the front corners
	for s in [-1.0, 1.0]:
		var cx: float = -4.15 if s < 0 else 4.45
		var cw: float = 1.2 if s < 0 else 0.7
		var cp := Vector3(cx, 0.1, -0.02 if s < 0 else 0.15)
		k.box(Vector3(cw, 1.95, 0.6), white, at(cp.x, cp.y + 0.975, cp.z))
		k.box(Vector3(cw + 0.02, 0.08, 0.62), white2, at(cp.x, cp.y + 1.95, cp.z))
		for i in 10:
			k.box(Vector3(cw - 0.12, 0.025, 0.03), white2, at(cp.x, cp.y + 0.2 + i * 0.1, cp.z + 0.31))
		k.box(Vector3(0.24, 0.14, 0.01), Color(0.2, 0.22, 0.26), at(cp.x, cp.y + 1.55, cp.z + 0.305))
		k.box(Vector3(0.2, 0.1, 0.012), lit(Color(0.42, 0.96, 0.9), 0.45), at(cp.x, cp.y + 1.55, cp.z + 0.31))
		k.box(Vector3(cw, 0.06, 0.05), teal, at(cp.x, cp.y + 1.75, cp.z + 0.31))
	# containment end frames around the bus (cold aisle)
	for x in [-3.15, 1.47]:
		for z in [-2.05, -0.58]:
			k.box(Vector3(0.08, 2.65, 0.08), white, at(x, 1.375, z))
		k.box(Vector3(0.1, 0.12, 1.55), white, at(x, 2.66, -1.31))
		k.box(Vector3(0.11, 0.04, 1.4), lit(Color(0.42, 0.96, 0.9), 0.45), at(x, 2.58, -1.31))
		k.box(Vector3(0.04, 0.2, 0.5), Color(0.26, 0.29, 0.33), at(x, 2.87, -1.31))
		k.box(Vector3(0.045, 0.06, 0.4), teal, at(x, 2.87, -1.31))
	# ------------------------------------------------ the forecourt: planters flank the way in, bollard lights
	for s in [-1.0, 1.0]:
		var pp := Vector3(s * 1.6, 0.05, 2.55)
		k.box(Vector3(0.9, 0.45, 0.45), white, at(pp.x, pp.y + 0.225, pp.z))
		k.box(Vector3(0.92, 0.04, 0.47), teal, at(pp.x, pp.y + 0.45, pp.z))
		k.box(Vector3(0.82, 0.04, 0.38), Color(0.36, 0.28, 0.2), at(pp.x, pp.y + 0.43, pp.z))
		for i in 3:
			_shrub(k, Vector3(pp.x - 0.27 + i * 0.27, pp.y + 0.43, pp.z), 0.17, Color(0.4, 0.62, 0.36) if i % 2 else Color(0.34, 0.54, 0.32))
	for x in [-2.75, 2.1, -1.05, 0.55]:
		k.cyl(0.07, 0.65, white, at(x, 0.05, 0.75), 8)
		k.cyl(0.075, 0.08, lit(Color(0.9, 1.0, 1.0), 0.35), at(x, 0.6, 0.75), 8)


## Server room: a white network cabinet behind a glass door, patch panels
## with teal lights, a cable waterfall into a ladder tray overhead.
static func _router2(k: MeshKit) -> void:
	var z := TZ
	var white := Color(0.95, 0.95, 0.96)
	var teal := Color(0.3, 0.66, 0.68)
	k.box(Vector3(1.06, 2.1, 0.92), white, at(0, 1.15, z))
	k.box(Vector3(1.1, 0.08, 0.96), Color(0.82, 0.84, 0.86), at(0, 2.22, z))
	k.box(Vector3(1.1, 0.1, 0.96), Color(0.7, 0.72, 0.74), at(0, 0.05, z))
	var fz := z + 0.47
	k.box(Vector3(0.9, 1.9, 0.02), Color(0.2, 0.22, 0.26), at(0, 1.15, fz - 0.01))
	for u in 12:
		var y := 0.32 + u * 0.15
		k.box(Vector3(0.82, 0.11, 0.015), Color(0.16, 0.17, 0.2) if u % 3 else Color(0.85, 0.86, 0.88), at(0, y, fz))
		_leds(k, -0.36, y, fz + 0.012, 12, 0.065, [Color(0.42, 0.96, 0.9), Color(0.42, 0.96, 0.9), Color(0.5, 0.7, 1.0)], u)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 1.95, 0.04), white, at(sx * 0.48, 1.15, fz + 0.01))
	k.box(Vector3(0.04, 0.3, 0.05), Color(0.6, 0.62, 0.64), at(0.4, 1.15, fz + 0.04))
	k.box(Vector3(1.0, 0.06, 0.04), lit(Color(0.42, 0.96, 0.9), 0.45), at(0, 2.12, fz + 0.01))
	# cable waterfall off the back into a ladder tray
	for i in 6:
		var c: Color = [Color(0.3, 0.55, 0.95), Color(0.95, 0.75, 0.25), teal, Color(0.95, 0.95, 0.95), Color(0.9, 0.35, 0.4), Color(0.4, 0.8, 0.45)][i]
		_tube(k, [Vector3(-0.35 + i * 0.14, 2.26, z - 0.3), Vector3(-0.35 + i * 0.14, 2.5, z - 0.42), Vector3(-0.35 + i * 0.14, 2.6, z - 0.7)], 0.02, c, 4, false)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 0.05, 0.9), Color(0.75, 0.77, 0.8), at(sx * 0.45, 2.62, z - 0.75))
	for i in 5:
		k.box(Vector3(0.9, 0.03, 0.03), Color(0.75, 0.77, 0.8), at(0, 2.62, z - 0.4 - i * 0.17))
	k.box(Vector3(0.36, 0.06, 0.36), Color(0.82, 0.84, 0.86), at(0, 2.29, z))


## Server room: a white DGX-style pod with a gold honeycomb front, teal edge
## lights, a status screen and two exhaust chimneys up into the building.
static func _core2(k: MeshKit) -> void:
	var z := TZ
	var cx := -0.25
	var white := Color(0.95, 0.95, 0.96)
	var teal := Color(0.3, 0.66, 0.68)
	k.box(Vector3(2.9, 0.12, 2.25), Color(0.7, 0.72, 0.74), at(cx, 0.06, z))
	var h := 2.0
	k.box(Vector3(2.7, h, 2.05), white, at(cx, 0.12 + h * 0.5, z))
	var fz := z + 1.03
	k.box(Vector3(2.5, 1.2, 0.03), Color(0.62, 0.5, 0.3), at(cx, 1.38, fz))
	for i in 10:
		for j in 6:
			k.box(Vector3(0.21, 0.16, 0.03), Color(0.88, 0.74, 0.46) if (i + j) % 2 == 0 else Color(0.8, 0.66, 0.4), at(cx - 1.1 + i * 0.245 + (j % 2) * 0.06, 0.9 + j * 0.19, fz + 0.02))
	k.box(Vector3(1.1, 0.5, 0.06), Color(0.2, 0.22, 0.26), at(cx, 0.48, fz + 0.01))
	k.box(Vector3(0.95, 0.36, 0.02), lit(Color(0.5, 0.9, 1.0), 0.45), at(cx, 0.48, fz + 0.045))
	for i in 5:
		k.box(Vector3(0.1, 0.05 + i * 0.05, 0.01), Color(1.0, 1.0, 1.0, 0.5), at(cx - 0.3 + i * 0.15, 0.36 + i * 0.025, fz + 0.06))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, h, 0.04), lit(Color(0.42, 0.96, 0.9), 0.45), at(cx + sx * 1.36, 0.12 + h * 0.5, fz))
	k.box(Vector3(2.72, 0.04, 0.04), lit(Color(0.42, 0.96, 0.9), 0.45), at(cx, 0.12 + h, fz))
	# side vents
	for i in 8:
		k.box(Vector3(0.02, 0.05, 1.6), Color(0.8, 0.82, 0.84), at(cx + 1.36, 0.6 + i * 0.15, z))
	# top: a front exhaust grille (the vent), chimneys to the back into the floor above
	k.box(Vector3(1.2, 0.12, 0.6), Color(0.82, 0.84, 0.86), at(cx - 0.3, 0.12 + h + 0.06, z + 0.45))
	for i in 5:
		k.box(Vector3(1.1, 0.02, 0.05), Color(0.3, 0.32, 0.36), at(cx - 0.3, 0.12 + h + 0.13, z + 0.25 + i * 0.1))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.5, 3.25 - h - 0.12, 0.5), white, at(cx + 0.3 + sx * 0.6, 0.12 + h + (3.25 - h - 0.12) * 0.5, z - 0.6))
		k.box(Vector3(0.54, 0.06, 0.54), teal, at(cx + 0.3 + sx * 0.6, 0.12 + h + 0.25, z - 0.6))
	for i in 3:
		k.cyl(0.04, 1.0, [Color(0.3, 0.55, 0.95), teal, Color(0.95, 0.95, 0.95)][i], at(cx - 1.1 + i * 0.12, 0.12 + h, z - 0.8), 6)


## Server room: a white lab bench with a teal edge and drawers.
static func _bench2(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var teal := Color(0.3, 0.66, 0.68)
	k.box(Vector3(1.42, 0.05, 0.94), white, at(0, 0.745, 0))
	k.box(Vector3(1.44, 0.03, 0.96), teal, at(0, 0.71, 0))
	k.box(Vector3(0.5, 0.66, 0.86), white, at(-0.45, 0.36, 0))
	for i in 3:
		k.box(Vector3(0.46, 0.18, 0.01), Color(0.86, 0.88, 0.9), at(-0.45, 0.17 + i * 0.21, 0.435))
		k.box(Vector3(0.16, 0.02, 0.02), teal, at(-0.45, 0.22 + i * 0.21, 0.445))
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.7, 0.05), Color(0.8, 0.82, 0.84), at(0.66, 0.35, sz * 0.42))
	k.box(Vector3(0.05, 0.05, 0.84), Color(0.8, 0.82, 0.84), at(0.66, 0.12, 0))
	for i in 3:
		k.cyl(0.07, 0.3, Color(0.5, 0.86, 0.92), at(0.2 + i * 0.16, 0.05, 0.05), 6)


## Server room: a white battery cabinet with teal stripes and a charge bar.
static func _dock2(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var teal := Color(0.3, 0.66, 0.68)
	k.box(Vector3(1.32, 0.1, 0.96), Color(0.7, 0.72, 0.74), at(0, 0.05, 0))
	k.box(Vector3(1.26, 0.66, 0.9), white, at(0, 0.43, 0))
	k.box(Vector3(1.3, 0.05, 0.94), teal, at(0, 0.785, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.03, 0.1, 0.94), white, at(sx * 0.63, 0.85, 0))
	for i in 2:
		k.box(Vector3(0.6, 0.5, 0.01), Color(0.88, 0.9, 0.92), at(-0.3 + i * 0.6, 0.43, 0.455))
	for i in 5:
		k.box(Vector3(0.07, 0.24, 0.012), lit(Color(0.42, 0.96, 0.9), 0.45) if i < 4 else Color(0.7, 0.72, 0.74), at(-0.25 + i * 0.1, 0.45, 0.46))
	k.box(Vector3(1.26, 0.04, 0.012), teal, at(0, 0.2, 0.46))
	_tube(k, [Vector3(-0.4, 0.4, -0.46), Vector3(-0.4, 0.12, -0.6), Vector3(-0.2, 0.12, -1.75)], 0.04, Color(0.85, 0.86, 0.88), 5)

# ================================================================ tier 3: steel data hall

## Tier 3: a tall steel-and-glass hall: portal frames and roof trusses over
## the stack, a gantry crane, a louvred back block with a recessed catwalk
## gallery, an open stair tower, roof chillers and a pipe riser, a generator
## and a transformer behind steel fences in the yard.
static func _hall(k: MeshKit) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 3131
	var steel := Color(0.5, 0.54, 0.6)
	var steel2 := Color(0.38, 0.41, 0.47)
	var dark := Color(0.22, 0.24, 0.28)
	var yel := Color(0.98, 0.8, 0.22)
	var blue := Color(0.45, 0.75, 1.0)
	var glass := Color(0.42, 0.56, 0.7)
	var fz := 0.5
	var top := 7.6
	var gal := 3.6               # catwalk gallery level
	# ------------------------------------------------ ground: slab with yellow lines, steel edge
	var slab := Color(0.56, 0.58, 0.62)
	k.box(Vector3(9.8, 0.06, 5.8), slab, at(0, 0.03, 0))
	for i in 10:
		k.box(Vector3(0.012, 0.006, 5.8), slab.darkened(0.12), at(-4.5 + i * 1.0, 0.062, 0))
	for j in 6:
		k.box(Vector3(9.8, 0.006, 0.012), slab.darkened(0.12), at(0, 0.062, -2.4 + j * 1.0))
	for x in [-2.9, 1.95]:
		k.box(Vector3(0.08, 0.008, 3.5), yel, at(x, 0.066, -0.9 + 1.75))
	k.box(Vector3(9.8, 0.01, 0.1), yel, at(0, 0.066, fz + 0.05))
	k.box(Vector3(4.6, 0.01, 0.6), Color(0.3, 0.55, 0.9).darkened(0.2), at(-0.6, 0.066, -0.45))
	for i in 12:
		k.box(Vector3(0.2, 0.012, 0.6), Color(0.45, 0.75, 1.0).darkened(0.35), at(-2.8 + i * 0.4, 0.068, -0.45))
	k.box(Vector3(9.8, 0.08, 0.12), Color(0.3, 0.32, 0.36), at(0, 0.04, 2.84))
	# ------------------------------------------------ portal frames: columns, roof trusses, side girts
	var frames := [-2.78, -1.2, fz]
	for fzz in frames:
		for s in [-1.0, 1.0]:
			k.box(Vector3(0.22, top, 0.22), steel2, at(s * 4.78, top * 0.5, fzz))
			k.box(Vector3(0.08, top - 0.5, 0.25), steel2.darkened(0.15), at(s * 4.78, top * 0.5, fzz))
			k.box(Vector3(0.24, 0.1, 0.24), dark, at(s * 4.78, 0.05, fzz))
		if fzz > -2.0:
			ArchKit.truss(k, Vector3(-4.7, top - 0.3, fzz), Vector3(4.7, top - 0.3, fzz), 0.5, steel2)
	for s in [-1.0, 1.0]:
		var x: float = s * 4.78
		ArchKit.truss(k, Vector3(x - s * 0.1, top - 0.3, -2.6), Vector3(x - s * 0.1, top - 0.3, fz), 0.4, steel2)
		k.box(Vector3(0.06, 0.04, 3.3), blue.darkened(0.1), at(x - s * 0.12, top - 0.6, -1.17))
		k.box(Vector3(0.03, 0.03, 3.3), lit(blue, 0.45), at(x - s * 0.16, top - 0.6, -1.17))
	# side walls: louvred steel cladding below, a glass clerestory band above, girts
	for s in [-1.0, 1.0]:
		var x: float = s * 4.87
		_ribs_z(k, -2.85, fz, x, 0.06, 3.0, steel, -s, 0.18)
		ArchKit.louvres(k, xf(Vector3(x - s * 0.03, 1.0, -1.6), Vector3(0, -90 * s, 0)), 1.4, 1.2, steel.darkened(0.08), 10)
		ArchKit.louvres(k, xf(Vector3(x - s * 0.03, 1.0, -0.1), Vector3(0, -90 * s, 0)), 0.9, 1.2, steel.darkened(0.08), 10)
		k.box(Vector3(0.05, 2.2, 3.3), glass, at(x, 4.3, -1.17))
		for i in 6:
			k.box(Vector3(0.07, 2.2, 0.05), dark, at(x, 4.3, -2.75 + i * 0.65))
		for y in [3.1, 5.4, 6.4]:
			k.box(Vector3(0.1, 0.12, 3.4), steel2, at(x, y, -1.17))
		k.box(Vector3(0.05, 0.9, 3.3), steel.darkened(0.1), at(x, 5.95, -1.17))
	# the gantry crane: runway beams, a girder across, a hoist over the bus
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.2, 0.3, 3.4), yel.darkened(0.1), at(s * 4.6, 6.75, -1.15))
	var cgz := -1.1
	k.box(Vector3(9.1, 0.26, 0.2), yel, at(0, 7.02, cgz))
	k.box(Vector3(9.1, 0.04, 0.3), yel.darkened(0.2), at(0, 6.88, cgz))
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.5, 0.3, 0.6), dark, at(s * 4.4, 6.95, cgz))
	k.box(Vector3(0.5, 0.36, 0.5), dark, at(-1.9, 6.55, cgz))
	k.box(Vector3(0.03, 2.4, 0.03), Color(0.2, 0.2, 0.22), at(-1.95, 5.2, cgz))
	k.box(Vector3(0.03, 2.4, 0.03), Color(0.2, 0.2, 0.22), at(-1.85, 5.2, cgz))
	k.box(Vector3(0.26, 0.22, 0.16), yel, at(-1.9, 3.95, cgz))
	k.torus(0.08, 0.025, Color(0.3, 0.3, 0.32), xf(Vector3(-1.9, 3.75, cgz), Vector3(90, 0, 0)), 8, 3, PI * 1.4)
	# ------------------------------------------------ the back block: recessed gallery, louvred upper floors
	var bx0 := -3.5
	var bx1 := 4.9
	var bmx := (bx0 + bx1) * 0.5
	k.box(Vector3(9.8, gal, 0.12), steel, at(0, gal * 0.5, -2.84))
	k.box(Vector3(bx1 - bx0, 1.15, 0.6), steel2, at(bmx, gal + 0.575, -2.6))
	k.box(Vector3(bx1 - bx0, top - gal - 1.1, 1.2), steel, at(bmx, (gal + 1.1 + top) * 0.5, -2.3))
	var uf := -1.7
	# gallery: a grating deck, railings, a blue strip, doors into the block
	k.box(Vector3(bx1 - bx0 + 1.4, 0.1, 0.55), dark, at(bmx - 0.7, gal, -2.0))
	for i in 46:
		k.box(Vector3(0.025, 0.02, 0.53), steel2, at(-4.8 + i * 0.21, gal + 0.06, -2.0))
	ArchKit.railing(k, Vector3(-4.8, gal + 0.05, -1.74), Vector3(4.7, gal + 0.05, -1.74), 1.0, yel, 0.7)
	k.box(Vector3(9.6, 0.03, 0.03), lit(blue, 0.45), at(-0.05, gal - 0.07, -1.72))
	for x in [-1.8, 1.0, 3.6]:
		k.box(Vector3(0.9, 1.0, 0.05), dark, at(x, gal + 0.55, -2.29))
		k.box(Vector3(0.8, 0.12, 0.06), lit(blue, 0.4), at(x, gal + 1.1, -2.28))
	for x in [-0.4, 2.3]:
		k.box(Vector3(1.6, 0.6, 0.04), glass, at(x, gal + 0.6, -2.29))
		k.box(Vector3(0.04, 0.6, 0.06), dark, at(x, gal + 0.6, -2.28))
	# upper front face: a spandrel for wall gear, a louvre band, a strip of windows, floor lines with blue LEDs
	var uy0 := gal + 1.1
	for y in [uy0 + 0.06, 6.31]:
		k.box(Vector3(bx1 - bx0, 0.12, 0.1), steel2, at(bmx, y, uf + 0.05))
		k.box(Vector3(bx1 - bx0 - 0.1, 0.03, 0.03), lit(blue, 0.45), at(bmx, y - 0.07, uf + 0.1))
	ArchKit.louvres(k, xf(Vector3(bmx, 5.45, uf + 0.02)), bx1 - bx0 - 0.3, 0.76, steel.darkened(0.06), 8)
	var wy := 6.78
	k.box(Vector3(bx1 - bx0 - 0.3, 0.6, 0.04), glass, at(bmx, wy, uf + 0.02))
	for i in 15:
		var px := bx0 + 0.15 + (i + 0.5) * (bx1 - bx0 - 0.3) / 15
		if (i * 3) % 7 == 2:
			k.box(Vector3(0.48, 0.52, 0.02), lit(blue.lightened(0.2), 0.55), at(px, wy, uf + 0.04))
		k.box(Vector3(0.05, 0.64, 0.06), dark, at(bx0 + 0.15 + i * (bx1 - bx0 - 0.3) / 15, wy, uf + 0.04))
	k.box(Vector3(bx1 - bx0, 0.06, 0.12), steel2, at(bmx, wy + 0.34, uf + 0.06))
	# a sign: DATA HALL 01 in blue on a dark board
	k.box(Vector3(2.6, 0.4, 0.08), dark, at(1.9, 7.36, uf + 0.12))
	k.box(Vector3(0.3, 0.3, 0.04), lit(blue, 0.4), at(0.85, 7.36, uf + 0.17))
	for i in 6:
		k.box(Vector3(0.22, 0.18, 0.03), lit(Color(0.85, 0.95, 1.0), 0.45), at(1.3 + i * 0.3, 7.36, uf + 0.17))
	# parapet with a blue strip
	ArchKit.parapet(k, Vector3(bmx, top, -2.3), bx1 - bx0, 1.2, 3)
	# ------------------------------------------------ the open stair tower (left)
	var tx0 := -4.9
	var tx1 := -3.5
	var tz0 := -2.9
	var tz1 := -1.95
	var th := top + 1.0
	for x in [tx0 + 0.07, tx1 - 0.07]:
		for z in [tz0 + 0.07, tz1 - 0.07]:
			k.box(Vector3(0.12, th, 0.12), steel2, at(x, th * 0.5, z))
	for f in 6:
		var y0 := 0.1 + f * 1.4
		var dirx := 1.0 if f % 2 == 0 else -1.0
		var a := Vector3((tx0 + tx1) * 0.5 - dirx * 0.45, y0, (tz0 + tz1) * 0.5 + 0.1)
		var b := Vector3((tx0 + tx1) * 0.5 + dirx * 0.45, y0 + 1.4, (tz0 + tz1) * 0.5 + 0.1)
		_beam(k, a, b, Vector2(0.55, 0.06), steel.darkened(0.1))
		_beam(k, a + Vector3(0, 0.9, 0.3), b + Vector3(0, 0.9, 0.3), Vector2(0.04, 0.04), yel)
		k.box(Vector3(tx1 - tx0, 0.06, tz1 - tz0), dark, at((tx0 + tx1) * 0.5, y0 + 1.4, (tz0 + tz1) * 0.5))
		k.box(Vector3(tx1 - tx0, 0.05, 0.05), yel, at((tx0 + tx1) * 0.5, y0 + 2.3, tz1 - 0.05))
		k.box(Vector3(tx1 - tx0, 0.12, 0.04), steel2, at((tx0 + tx1) * 0.5, y0 + 0.1, tz1 - 0.05))
		_beam(k, Vector3(tx0 + 0.07, y0 + 0.1, tz1 - 0.04), Vector3(tx1 - 0.07, y0 + 1.4, tz1 - 0.04), Vector2(0.04, 0.04), steel2)
	k.box(Vector3(tx1 - tx0 + 0.1, 0.12, tz1 - tz0 + 0.08), dark, at((tx0 + tx1) * 0.5 + 0.05, th, (tz0 + tz1) * 0.5 + 0.04))
	k.box(Vector3(tx1 - tx0 + 0.1, 0.03, 0.03), lit(blue, 0.45), at((tx0 + tx1) * 0.5 + 0.05, th - 0.07, tz1 + 0.08))
	ArchKit.beacon(k, Vector3(tx0 + 0.25, th + 0.06, tz0 + 0.25), 0.6)
	# ------------------------------------------------ roof: a chiller, a pipe rack, the riser down the side
	ArchKit.chiller(k, at(3.45, top + 0.03, -2.25), 2.6, 3, 3)
	var pc := [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84)]
	for i in 2:
		var zz := -2.75 + i * 0.22
		_tube(k, [Vector3(2.0, top + 0.5, zz), Vector3(-3.3, top + 0.5, zz)], 0.08, pc[i], 8)
		_tube(k, [Vector3(4.75, top + 0.5, zz), Vector3(4.75, top + 0.5, zz), Vector3(4.72, 2.6, zz)], 0.11, pc[i], 8)
	for x in [-3.0, -1.5, 0.0, 1.5]:
		k.box(Vector3(0.08, 0.5, 0.5), steel2, at(x, top + 0.25, -2.64))
	for y in [2.0, 3.4, 5.0, 6.6]:
		k.box(Vector3(0.12, 0.08, 0.5), steel2, at(4.75, y, -2.62))
	# ------------------------------------------------ the back strip: black racks, blue lights, busway
	var led := [Color(0.45, 0.75, 1.0), Color(0.45, 0.75, 1.0), Color(0.5, 1.0, 0.6)]
	for i in 8:
		_rack(k, Vector3(-3.15 + i * 0.6, 0.06, -2.52), 2.3, Color(0.16, 0.17, 0.2), Color(0.24, 0.26, 0.3), led, 0.58, 0.58, i, 9)
		k.box(Vector3(0.5, 0.03, 0.02), lit(blue, 0.45), at(-3.15 + i * 0.6, 2.33, -2.22))
	k.box(Vector3(9.4, 0.18, 0.2), Color(0.3, 0.32, 0.36), at(0, 3.1, -2.6))
	for i in 9:
		k.box(Vector3(0.18, 0.3, 0.18), Color(0.3, 0.32, 0.36), at(-4.0 + i * 1.0, 2.9, -2.6))
		k.box(Vector3(0.04, 0.04, 0.01), lit(Color(0.5, 1.0, 0.6), 0.4), at(-4.0 + i * 1.0, 2.9, -2.505))
	ArchKit.cable_tray(k, Vector3(-4.6, 3.35, -2.45), Vector3(4.6, 3.35, -2.45), 3)
	# behind the core: a coolant distribution manifold with blue pipes
	for i in 3:
		_tube(k, [Vector3(2.0, 0.4 + i * 0.45, -2.72), Vector3(4.55, 0.4 + i * 0.45, -2.72)], 0.07, pc[i % 2], 8)
	for x in [2.4, 3.2, 4.0]:
		k.box(Vector3(0.14, 1.4, 0.14), dark, at(x, 0.8, -2.7))
		k.cyl(0.1, 0.06, Color(0.86, 0.2, 0.18), xf(Vector3(x, 1.05, -2.62), Vector3(90, 0, 0)), 8)
	# ------------------------------------------------ the yard: generator and transformer behind steel fences
	ArchKit.generator(k, at(-3.75, 0.06, 2.3), 3)
	ArchKit.transformer(k, at(4.15, 0.06, 2.3), 3)
	ArchKit.fence(k, Vector3(-4.85, 0.06, 2.85), Vector3(-2.6, 0.06, 2.85), 3, 1.3)
	ArchKit.fence(k, Vector3(-2.6, 0.06, 2.85), Vector3(-2.6, 0.06, 1.75), 3, 1.3)
	ArchKit.fence(k, Vector3(3.4, 0.06, 2.85), Vector3(4.85, 0.06, 2.85), 3, 1.3)
	ArchKit.fence(k, Vector3(3.4, 0.06, 1.75), Vector3(3.4, 0.06, 2.85), 3, 1.3)
	for p in [Vector3(-2.6, 0, 2.0), Vector3(3.4, 0, 2.0)]:
		k.box(Vector3(0.3, 0.3, 0.02), yel, at(p.x + (0.03 if p.x > 0 else -0.03) * -1.0, 0.85, p.z + 0.5))
		k.box(Vector3(0.12, 0.16, 0.022), Color(0.15, 0.15, 0.16), at(p.x, 0.85, p.z + 0.505))
	for p in [Vector3(-2.6, 0.06, 1.75), Vector3(3.4, 0.06, 1.75)]:
		ArchKit.lamp(k, p, 3, 2.6)
	# bollards and a blue-lit kerb along the front of the hall
	for x in [-3.0, 2.25]:
		k.cyl(0.08, 0.9, yel, at(x, 0.06, 0.62), 8)
		k.cyl(0.085, 0.06, Color(0.15, 0.15, 0.16), at(x, 0.65, 0.62), 8)


## Data hall: a steel rack cabinet behind a glass door, cold-aisle blue light
## bars, a fan shroud on top, conduit up to the ceiling.
static func _router3(k: MeshKit) -> void:
	var z := TZ
	var steel := Color(0.42, 0.45, 0.5)
	var blue := Color(0.45, 0.75, 1.0)
	k.box(Vector3(1.25, 2.4, 1.05), steel, at(0, 1.26, z))
	k.box(Vector3(1.3, 0.1, 1.1), Color(0.22, 0.24, 0.28), at(0, 0.05, z))
	var fz := z + 0.53
	k.box(Vector3(1.08, 2.1, 0.03), Color(0.14, 0.15, 0.18), at(0, 1.25, fz))
	for i in 12:
		var y := 0.35 + i * 0.165
		k.box(Vector3(0.94, 0.11, 0.02), Color(0.2, 0.22, 0.26), at(0, y, fz + 0.01))
		k.box(Vector3(0.9, 0.03, 0.01), lit(blue, 0.5 if i % 3 else 0.35), at(0, y + 0.03, fz + 0.025))
		_leds(k, -0.4, y - 0.025, fz + 0.025, 8, 0.1, [Color(0.5, 1.0, 0.6), blue], i)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 2.2, 0.06), Color(0.24, 0.26, 0.3), at(sx * 0.57, 1.25, fz + 0.02))
	k.box(Vector3(0.04, 0.4, 0.06), Color(0.7, 0.72, 0.76), at(0.48, 1.25, fz + 0.05))
	k.box(Vector3(1.3, 0.12, 1.12), Color(0.22, 0.24, 0.28), at(0, 2.52, z))
	k.cyl(0.32, 0.1, Color(0.22, 0.24, 0.28), at(0, 2.55, z), 12)
	for i in 3:
		k.box(Vector3(0.06, 1.0, 0.06), [Color(0.36, 0.6, 0.86), Color(0.98, 0.8, 0.22), Color(0.2, 0.2, 0.22)][i], at(-0.4 + i * 0.1, 3.05, z - 0.4))
	k.box(Vector3(0.2, 0.3, 0.12), Color(0.98, 0.8, 0.22), at(-0.5, 1.6, z + 0.6))
	k.box(Vector3(0.14, 0.2, 0.01), Color(0.15, 0.15, 0.16), at(-0.5, 1.6, z + 0.665))


## Data hall: a steel GPU pod: three glowing decks behind a grille, a cooling
## hood, blue coolant pipes into the manifold behind it.
static func _core3(k: MeshKit) -> void:
	var z := TZ
	var cx := -0.25
	var steel := Color(0.58, 0.62, 0.68)
	var dark := Color(0.22, 0.24, 0.28)
	var blue := Color(0.45, 0.75, 1.0)
	k.box(Vector3(2.9, 0.25, 2.2), dark, at(cx, 0.125, z))
	k.box(Vector3(2.8, 1.95, 2.05), steel, at(cx, 0.25 + 0.975, z))
	var fz := z + 1.03
	for d in 3:
		var y := 0.62 + d * 0.58
		k.box(Vector3(2.1, 0.42, 0.06), dark, at(cx - 0.25, y, fz))
		k.box(Vector3(1.9, 0.28, 0.04), lit(Color(0.36, 0.8, 1.0), 0.45), at(cx - 0.25, y, fz + 0.03))
		for i in 8:
			k.box(Vector3(0.03, 0.28, 0.06), dark, at(cx - 1.1 + i * 0.24 + 0.12, y, fz + 0.05))
		for i in 2:
			k.cyl(0.06, 0.04, lit(Color(0.5, 1.0, 0.6), 0.4), xf(Vector3(cx + 1.0, y + (i - 0.5) * 0.18, fz + 0.02), Vector3(90, 0, 0)), 8)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 1.9, 0.05), lit(blue, 0.45), at(cx + sx * 1.38, 1.22, fz))
	for i in 10:
		k.box(Vector3(0.02, 0.06, 1.7), dark, at(cx + 1.41, 0.5 + i * 0.15, z))
	# hood with an exhaust grille at the front (the vent), pipes into the back
	k.box(Vector3(3.0, 0.3, 2.25), dark, at(cx, 2.35, z))
	k.box(Vector3(1.4, 0.18, 0.7), Color(0.3, 0.32, 0.36), at(cx - 0.45, 2.59, z + 0.55))
	for i in 6:
		k.box(Vector3(1.3, 0.02, 0.05), Color(0.12, 0.13, 0.15), at(cx - 0.45, 2.69, z + 0.3 + i * 0.1))
	k.box(Vector3(1.4, 0.03, 0.03), lit(blue, 0.45), at(cx - 0.45, 2.69, z + 0.92))
	for i in 3:
		_tube(k, [Vector3(cx - 1.0 + i * 0.5, 2.5, z - 0.6), Vector3(cx - 1.0 + i * 0.5, 2.95, z - 0.6), Vector3(cx - 1.0 + i * 0.5, 2.95, z - 1.35), Vector3(cx - 1.0 + i * 0.5, 2.2, z - 1.4)], 0.07, [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84), Color(0.36, 0.6, 0.86)][i], 8)
	k.box(Vector3(0.6, 0.3, 0.6), Color(0.3, 0.32, 0.36), at(cx + 0.8, 2.65, z - 0.3))
	for i in 3:
		k.box(Vector3(0.5, 0.02, 0.5), dark, at(cx + 0.8, 2.82 + i * 0.0, z - 0.3))
	# a ladder up the pod's side, a warning plate
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.03, 2.3, 0.03), Color(0.98, 0.8, 0.22), at(cx + 1.48, 1.3, z + 0.3 + sz * 0.18))
	for i in 7:
		k.box(Vector3(0.03, 0.025, 0.36), Color(0.98, 0.8, 0.22), at(cx + 1.48, 0.45 + i * 0.3, z + 0.3))
	k.box(Vector3(0.3, 0.2, 0.01), Color(0.98, 0.8, 0.22), at(cx + 0.9, 0.3, fz + 0.01))


## Data hall: a steel cart with blue-lit edges and a coolant rack.
static func _bench3(k: MeshKit) -> void:
	var steel := Color(0.7, 0.74, 0.8)
	var dark := Color(0.22, 0.24, 0.28)
	k.box(Vector3(1.42, 0.05, 0.94), steel, at(0, 0.745, 0))
	k.box(Vector3(1.44, 0.04, 0.96), dark, at(0, 0.7, 0))
	k.box(Vector3(1.4, 0.02, 0.02), lit(Color(0.45, 0.75, 1.0), 0.45), at(0, 0.7, 0.485))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.05, 0.62, 0.05), dark, at(sx * 0.65, 0.4, sz * 0.42))
			k.cyl(0.05, 0.04, Color(0.12, 0.12, 0.13), xf(Vector3(sx * 0.65, 0.06, sz * 0.42), Vector3(0, 0, 90)), 6)
	k.box(Vector3(1.3, 0.04, 0.86), dark, at(0, 0.3, 0))
	for i in 4:
		k.cyl(0.08, 0.32, Color(0.36, 0.6, 0.86), at(-0.45 + i * 0.3, 0.32, 0.0), 8)
		k.cyl(0.04, 0.05, Color(0.86, 0.86, 0.84), at(-0.45 + i * 0.3, 0.64, 0.0), 6)


## Data hall: a steel switchgear base with breakers and a blue gauge.
static func _dock3(k: MeshKit) -> void:
	var steel := Color(0.62, 0.66, 0.72)
	var dark := Color(0.22, 0.24, 0.28)
	k.box(Vector3(1.34, 0.12, 0.98), dark, at(0, 0.06, 0))
	k.box(Vector3(1.26, 0.64, 0.9), steel, at(0, 0.44, 0))
	k.box(Vector3(1.32, 0.06, 0.96), dark, at(0, 0.79, 0))
	for i in 3:
		k.box(Vector3(0.38, 0.5, 0.012), steel.darkened(0.1), at(-0.42 + i * 0.42, 0.44, 0.455))
		k.box(Vector3(0.08, 0.14, 0.02), Color(0.15, 0.15, 0.16), at(-0.42 + i * 0.42, 0.5, 0.465))
		k.box(Vector3(0.05, 0.05, 0.02), lit(Color(0.45, 0.75, 1.0), 0.45), at(-0.42 + i * 0.42, 0.68, 0.465))
	k.box(Vector3(1.26, 0.05, 0.012), Color(0.98, 0.8, 0.22), at(0, 0.18, 0.46))
	_tube(k, [Vector3(-0.4, 0.4, -0.46), Vector3(-0.4, 0.12, -0.6), Vector3(-0.2, 0.12, -1.75)], 0.05, dark, 6)
	_tube(k, [Vector3(-0.2, 0.4, -0.46), Vector3(-0.2, 0.14, -0.6), Vector3(0.0, 0.14, -1.75)], 0.05, Color(0.98, 0.8, 0.22), 6)

# ================================================================ tier 4: hyperscale

## Tier 4: a graphite and brass tower. Glowing fins run up its face, liquid-
## cooling loops climb from the core to dry coolers on the roof, a crown floor
## cantilevers over the whole stack on two brass-capped columns, a sky bridge
## stub leaves its side, a hologram floats in front, a drone pad, beacons and
## a brass crown top it off.
static func _hyper(k: MeshKit) -> void:
	var g := Color(0.17, 0.18, 0.21)
	var g2 := Color(0.24, 0.25, 0.29)
	var g3 := Color(0.11, 0.11, 0.13)
	var brass := Color(0.78, 0.63, 0.38)
	var glow := Color(1.0, 0.86, 0.5)
	var cool := Color(0.42, 0.9, 1.0)
	var glass := Color(0.26, 0.36, 0.48)
	var fz := 0.45
	var gal := 3.6
	var ct := 8.4                # underside of the crown floor
	var top := 9.9               # roof
	# ------------------------------------------------ ground: dark tiles with glowing seams, a brass kerb
	k.box(Vector3(9.8, 0.06, 5.8), Color(0.2, 0.21, 0.24), at(0, 0.03, 0))
	for i in 11:
		k.box(Vector3(0.02, 0.008, 5.8), lit(cool, 0.5) if i % 2 == 0 else g2, at(-4.9 + i * 0.98, 0.064, 0))
	for j in 7:
		k.box(Vector3(9.8, 0.008, 0.02), g2, at(0, 0.064, -2.9 + j * 0.97))
	k.box(Vector3(9.8, 0.08, 0.1), brass, at(0, 0.04, 2.85))
	k.box(Vector3(2.4, 0.012, 2.4), g3, at(-0.4, 0.07, 1.7))
	for i in 5:
		k.box(Vector3(2.2, 0.006, 0.04), lit(glow, 0.5), at(-0.4, 0.078, 0.7 + i * 0.5))
	# ------------------------------------------------ the tower (back), its ground floor and gallery
	var bx0 := -3.6
	var bx1 := 4.9
	var bmx := (bx0 + bx1) * 0.5
	var uf := -1.7
	k.box(Vector3(9.8, gal, 0.12), g, at(0, gal * 0.5, -2.84))
	k.box(Vector3(bx1 - bx0, ct - gal, 1.2), g, at(bmx, (gal + ct) * 0.5, -2.3))
	# brass floor lines, glowing fins, dark glass between
	k.box(Vector3(bx1 - bx0 - 0.1, ct - gal - 0.4, 0.04), glass, at(bmx, (gal + ct) * 0.5, uf + 0.02))
	for y in [gal + 0.05, 4.8, 6.0, 7.2, ct - 0.05]:
		k.box(Vector3(bx1 - bx0 + 0.02, 0.1, 0.12), brass, at(bmx, y, uf + 0.06))
	for i in 15:
		var px := bx0 + 0.3 + i * (bx1 - bx0 - 0.6) / 14.0
		k.box(Vector3(0.1, ct - gal - 0.2, 0.32), g2, at(px, (gal + ct) * 0.5, uf + 0.16))
		k.box(Vector3(0.03, ct - gal - 0.5, 0.03), lit(glow, 0.4) if i % 3 != 1 else lit(cool, 0.45), at(px, (gal + ct) * 0.5, uf + 0.33))
	# wall gear spandrel: a plain brass-edged band at 4.0-4.6
	k.box(Vector3(bx1 - bx0 - 0.2, 0.62, 0.06), g2, at(bmx, 4.3, uf + 0.33))
	k.box(Vector3(bx1 - bx0 - 0.2, 0.03, 0.08), brass, at(bmx, 4.62, uf + 0.34))
	k.box(Vector3(bx1 - bx0 - 0.2, 0.03, 0.08), brass, at(bmx, 3.98, uf + 0.34))
	# ------------------------------------------------ the crown floor, cantilevered over the stack
	var cz0 := -2.9
	var cz1 := fz - 0.1
	var cmz := (cz0 + cz1) * 0.5
	k.box(Vector3(9.8, top - ct, cz1 - cz0), g, at(0, (ct + top) * 0.5, cmz))
	k.box(Vector3(9.82, 0.12, cz1 - cz0 + 0.02), brass, at(0, ct + 0.06, cmz))
	k.box(Vector3(9.82, 0.1, 0.1), brass, at(0, top - 0.05, cz1 - 0.04))
	k.box(Vector3(9.82, 0.1, 0.1), brass, at(0, top - 0.05, cz0 + 0.05))
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.1, 0.1, cz1 - cz0), brass, at(s * 4.86, top - 0.05, cmz))
	k.box(Vector3(9.6, 0.02, cz1 - cz0 - 0.2), Color(0.14, 0.15, 0.17), at(0, top + 0.01, cmz))
	for i in 12:
		k.box(Vector3(0.02, 0.01, cz1 - cz0 - 0.2), g2, at(-4.4 + i * 0.8, top + 0.025, cmz))
	# its face: a band of glowing fins over dark glass, a brass sign rail
	k.box(Vector3(9.6, top - ct - 0.4, 0.04), glass, at(0, (ct + top) * 0.5, cz1 + 0.02))
	for i in 25:
		var px := -4.7 + i * 0.39
		k.box(Vector3(0.07, top - ct - 0.3, 0.26), g2, at(px, (ct + top) * 0.5, cz1 + 0.13))
		k.box(Vector3(0.025, top - ct - 0.5, 0.025), lit(glow, 0.4), at(px, (ct + top) * 0.5, cz1 + 0.27))
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.04, top - ct, cz1 - cz0 - 0.4), glass, at(s * 4.9 - s * 0.02, (ct + top) * 0.5, cmz))
		for i in 6:
			k.box(Vector3(0.1, top - ct - 0.3, 0.06), g2, at(s * 4.86, (ct + top) * 0.5, cz0 + 0.3 + i * 0.55))
	# underside lights along the cantilever edge (seen from the street)
	k.box(Vector3(9.6, 0.03, 0.03), lit(cool, 0.45), at(0, ct - 0.02, cz1 - 0.05))
	# the two columns that carry the crown: graphite, brass capitals, glow lines
	for s in [-1.0, 1.0]:
		var x: float = s * 4.72
		k.box(Vector3(0.32, ct, 0.32), g, at(x, ct * 0.5, fz - 0.25))
		k.box(Vector3(0.36, 0.3, 0.36), brass, at(x, ct - 0.15, fz - 0.25))
		k.box(Vector3(0.38, 0.16, 0.38), brass, at(x, 0.08, fz - 0.25))
		k.box(Vector3(0.03, ct - 0.6, 0.03), lit(glow, 0.4), at(x - s * 0.17, ct * 0.5, fz - 0.08))
		_beam(k, Vector3(x, ct - 1.6, fz - 0.25), Vector3(x, ct - 0.1, -1.6), Vector2(0.12, 0.12), brass)
	# ------------------------------------------------ the sky bridge stub (left), the stair and lift shaft
	var lx0 := -4.9
	var lx1 := bx0
	k.box(Vector3(lx1 - lx0, ct, 0.4), g2, at((lx0 + lx1) * 0.5, ct * 0.5, -2.7))
	k.box(Vector3(0.5, ct - 1.0, 0.04), lit(glow, 0.4), at(-4.25, ct * 0.5 + 0.3, -2.48))
	for i in 8:
		k.box(Vector3(0.6, 0.05, 0.06), brass, at(-4.25, 0.9 + i * 0.95, -2.47))
	var by := 5.6
	k.box(Vector3(lx1 - lx0, 1.2, 0.85), glass, at((lx0 + lx1) * 0.5, by + 0.6, -2.05))
	for i in 5:
		k.box(Vector3(0.06, 1.24, 0.89), brass, at(lx0 + 0.03 + i * (lx1 - lx0 - 0.06) / 4.0, by + 0.6, -2.05))
	k.box(Vector3(lx1 - lx0, 0.1, 0.91), brass, at((lx0 + lx1) * 0.5, by, -2.05))
	k.box(Vector3(lx1 - lx0, 0.1, 0.91), brass, at((lx0 + lx1) * 0.5, by + 1.2, -2.05))
	k.box(Vector3(lx1 - lx0, 0.03, 0.03), lit(cool, 0.45), at((lx0 + lx1) * 0.5, by + 0.08, -1.6))
	k.box(Vector3(0.1, 1.4, 1.0), brass, at(lx0 + 0.05, by + 0.6, -2.05))
	# ------------------------------------------------ roof: dry coolers, a drone pad, beacons, the crown
	var ry := top
	for i in 3:
		var cx := -3.6 + i * 1.25
		var cz := -2.25
		k.box(Vector3(1.1, 0.7, 0.9), g2, at(cx, ry + 0.35, cz))
		k.box(Vector3(1.14, 0.06, 0.94), brass, at(cx, ry + 0.7, cz))
		for f in 2:
			k.cyl(0.24, 0.05, g3, at(cx - 0.26 + f * 0.52, ry + 0.72, cz), 10)
			k.torus(0.24, 0.02, lit(cool, 0.45), at(cx - 0.26 + f * 0.52, ry + 0.76, cz), 10, 3)
		for j in 5:
			k.box(Vector3(1.0, 0.03, 0.02), g3, at(cx, ry + 0.12 + j * 0.1, cz + 0.46))
	ArchKit.drone_pad(k, Vector3(2.9, ry + 0.02, -1.35), 1.2, 4)
	for p in [Vector3(-4.7, ry, -2.75), Vector3(4.7, ry, -2.75), Vector3(-4.7, ry, 0.15), Vector3(4.7, ry, 0.15)]:
		ArchKit.beacon(k, p, 0.7)
	# the crown: a stepped brass base, a glowing halo, a spire
	var cp := Vector3(-0.3, ry, -0.4)
	k.box(Vector3(1.6, 0.25, 1.6), g2, at(cp.x, cp.y + 0.125, cp.z))
	k.box(Vector3(1.3, 0.25, 1.3), brass, at(cp.x, cp.y + 0.375, cp.z))
	k.box(Vector3(0.9, 0.3, 0.9), g, at(cp.x, cp.y + 0.65, cp.z))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		_beam(k, cp + Vector3(cos(a) * 0.4, 0.8, sin(a) * 0.4), cp + Vector3(cos(a) * 0.75, 1.9, sin(a) * 0.75), Vector2(0.06, 0.06), brass)
	k.torus(0.78, 0.06, brass, at(cp.x, cp.y + 1.95, cp.z), 20, 4)
	k.torus(0.6, 0.04, lit(glow, 0.35), at(cp.x, cp.y + 1.95, cp.z), 20, 4)
	k.cyl(0.1, 0.4, brass, at(cp.x, cp.y + 0.8, cp.z), 8)
	k.cone(0.12, 1.6, brass, at(cp.x, cp.y + 1.2, cp.z), 8)
	k.sphere(0.14, lit(cool, 0.35), at(cp.x, cp.y + 2.9, cp.z), 8, 5)
	k.box(Vector3(9.82, 0.25, 0.1), g2, at(0, ry + 0.12, cz1 - 0.05))
	k.box(Vector3(9.82, 0.03, 0.12), lit(glow, 0.45), at(0, ry + 0.26, cz1 - 0.05))
	# ------------------------------------------------ liquid-cooling loops: glowing pipes up the face to the roof
	for i in 2:
		var px := 4.35 + i * 0.22
		var pcol := lit(cool, 0.45) if i == 0 else lit(Color(1.0, 0.6, 0.4), 0.45)
		_tube(k, [Vector3(px, 2.6, -2.2), Vector3(px, 2.6, -1.42), Vector3(px, ct - 0.2, -1.42)], 0.08, pcol, 8)
		k.box(Vector3(0.24, 0.1, 0.24), brass, at(px, 5.0, -1.42))
		k.box(Vector3(0.24, 0.1, 0.24), brass, at(px, 7.0, -1.42))
	for i in 2:
		var px2 := -3.3 + i * 0.22
		_tube(k, [Vector3(px2, top - 0.6, -2.6), Vector3(px2, top + 0.35, -2.6), Vector3(-1.4, top + 0.35, -2.6)], 0.07, lit(cool, 0.45) if i == 0 else lit(Color(1.0, 0.6, 0.4), 0.45), 8)
	_tube(k, [Vector3(4.35, top + 0.3, -1.0), Vector3(4.35, top + 0.3, -2.0), Vector3(-1.4, top + 0.3, -2.0)], 0.07, lit(cool, 0.45), 8)
	# ------------------------------------------------ the hologram over the stack
	var hp := Vector3(0.7, 5.3, -1.4)
	k.box(Vector3(1.9, 0.95, 0.02), Color(0.42, 0.9, 1.0, 0.25), at(hp.x, hp.y, hp.z))
	k.box(Vector3(1.94, 0.03, 0.03), lit(cool, 0.4), at(hp.x, hp.y + 0.48, hp.z))
	k.box(Vector3(1.94, 0.03, 0.03), lit(cool, 0.4), at(hp.x, hp.y - 0.48, hp.z))
	k.cyl(0.26, 0.03, lit(glow, 0.35), xf(Vector3(hp.x - 0.55, hp.y, hp.z + 0.02), Vector3(90, 0, 0)), 12)
	k.cyl(0.14, 0.04, Color(0.42, 0.9, 1.0, 0.3), xf(Vector3(hp.x - 0.55, hp.y, hp.z + 0.03), Vector3(90, 0, 0)), 10)
	for i in 4:
		k.box(Vector3(0.8 - i * 0.12, 0.08, 0.02), lit(Color(0.85, 1.0, 1.0), 0.35), at(hp.x + 0.35 - i * 0.05, hp.y + 0.24 - i * 0.16, hp.z + 0.02))
	for i in 3:
		_beam(k, Vector3(hp.x, gal + 0.16, -1.95), Vector3(hp.x - 0.9 + i * 0.9, hp.y - 0.48, hp.z), Vector2(0.015, 0.015), lit(cool, 0.3))
	k.box(Vector3(0.5, 0.12, 0.3), g2, at(hp.x, gal + 0.08, -1.95))
	k.box(Vector3(0.3, 0.05, 0.12), lit(cool, 0.4), at(hp.x, gal + 0.16, -1.95))
	# ------------------------------------------------ gallery at 3.6: a brass rail
	k.box(Vector3(bx1 - bx0 + 1.3, 0.12, 0.5), g2, at(bmx - 0.65, gal, -1.95))
	k.box(Vector3(9.7, 0.05, 0.05), brass, at(-0.05, gal + 0.95, -1.72))
	k.box(Vector3(9.7, 0.9, 0.025), Color(0.32, 0.5, 0.7, 0.55), at(-0.05, gal + 0.5, -1.72))
	k.box(Vector3(9.7, 0.03, 0.03), lit(glow, 0.45), at(-0.05, gal - 0.07, -1.72))
	# ------------------------------------------------ the hall: liquid-cooled racks, CDUs, a glass-and-brass front
	for i in 8:
		var rx := -3.15 + i * 0.6
		_rack(k, Vector3(rx, 0.06, -2.52), 2.4, g3, g2, [glow, cool, glow], 0.58, 0.58, i, 9)
		k.box(Vector3(0.04, 2.3, 0.04), lit(cool, 0.45), at(rx + 0.24, 1.25, -2.21))
		k.box(Vector3(0.6, 0.05, 0.62), brass, at(rx, 2.48, -2.52))
	for i in 2:
		_tube(k, [Vector3(-3.4, 2.7 + i * 0.18, -2.7), Vector3(1.6, 2.7 + i * 0.18, -2.7)], 0.07, lit(cool, 0.45) if i == 0 else lit(Color(1.0, 0.6, 0.4), 0.45), 8)
	for i in 5:
		var tx := 2.05 + i * 0.6
		k.box(Vector3(0.5, 1.6, 0.4), g2, at(tx, 0.86, -2.68))
		k.box(Vector3(0.52, 0.05, 0.42), brass, at(tx, 1.68, -2.68))
		k.cyl(0.09, 0.03, lit(cool, 0.45), xf(Vector3(tx, 1.2, -2.47), Vector3(90, 0, 0)), 10)
	for s in [-1.0, 1.0]:
		var xa: float = s * 1.25
		var xb: float = s * 4.5
		k.box(Vector3(absf(xb - xa), 0.95, 0.03), Color(0.32, 0.5, 0.7, 0.55), at((xa + xb) * 0.5, 0.56, fz + 0.1))
		k.box(Vector3(absf(xb - xa), 0.05, 0.08), brass, at((xa + xb) * 0.5, 1.06, fz + 0.1))
		for i in 4:
			k.box(Vector3(0.05, 1.0, 0.06), brass, at(xa + (xb - xa) * i / 3.0, 0.56, fz + 0.1))
	# side walls: dark glass between graphite fins
	for s in [-1.0, 1.0]:
		var x: float = s * 4.88
		k.box(Vector3(0.04, gal - 0.2, 3.3), glass, at(x, gal * 0.5, -1.2))
		for i in 6:
			k.box(Vector3(0.1, gal, 0.1), g2, at(s * 4.84, gal * 0.5, -2.8 + i * 0.6))
		k.box(Vector3(0.12, 0.1, 3.3), brass, at(s * 4.83, gal, -1.2))
	# ------------------------------------------------ the plaza: brass bollards, planters, lamp posts
	for x in [-2.7, -1.4, 0.6, 1.9]:
		k.cyl(0.07, 0.75, g, at(x, 0.06, 2.75), 8)
		k.cyl(0.075, 0.06, brass, at(x, 0.8, 2.75), 8)
		k.cyl(0.072, 0.03, lit(glow, 0.4), at(x, 0.7, 2.75), 8)
	for s in [-1.0, 1.0]:
		ArchKit.lamp(k, Vector3(s * 3.1, 0.06, 0.75), 4, 3.0)


## Hyperscale: a graphite network monolith with brass edges, a glowing face
## and a halo.
static func _router4(k: MeshKit) -> void:
	var z := TZ
	var g := Color(0.16, 0.17, 0.2)
	var brass := Color(0.78, 0.63, 0.38)
	k.box(Vector3(1.32, 2.6, 1.12), g, at(0, 1.36, z))
	k.box(Vector3(1.4, 0.1, 1.2), brass, at(0, 0.05, z))
	k.box(Vector3(1.4, 0.08, 1.2), brass, at(0, 2.68, z))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 2.6, 0.05), brass, at(sx * 0.64, 1.36, z + 0.55))
	k.box(Vector3(0.95, 2.0, 0.03), lit(Color(0.3, 0.8, 0.86), 0.6), at(0, 1.35, z + 0.57))
	for i in 14:
		k.box(Vector3(0.8, 0.02, 0.01), Color(0.1, 0.1, 0.12), at(0, 0.45 + i * 0.13, z + 0.59))
		_leds(k, -0.38, 0.5 + i * 0.13, z + 0.59, 6, 0.15, [Color(1.0, 0.86, 0.5), Color(0.42, 0.9, 1.0)], i)
	k.torus(0.48, 0.04, lit(Color(1.0, 0.86, 0.5), 0.4), at(0, 3.12, z), 20, 5)
	for i in 3:
		k.box(Vector3(0.03, 0.4, 0.03), brass, xf(Vector3(cos(TAU * i / 3.0) * 0.4, 2.92, z + sin(TAU * i / 3.0) * 0.4), Vector3(0, 0, 0)))
	k.box(Vector3(0.06, 1.6, 0.06), lit(Color(0.42, 0.9, 1.0), 0.45), at(-0.6, 1.4, z - 0.56))


## Hyperscale: a graphite monolith core with brass bands, a glowing ring,
## glowing coolant manifolds and the loop risers behind it.
static func _core4(k: MeshKit) -> void:
	var z := TZ
	var cx := -0.25
	var g := Color(0.16, 0.17, 0.2)
	var brass := Color(0.78, 0.63, 0.38)
	var cool := Color(0.42, 0.9, 1.0)
	k.box(Vector3(3.0, 0.35, 2.3), Color(0.12, 0.12, 0.14), at(cx, 0.17, z))
	k.box(Vector3(3.04, 0.04, 2.34), brass, at(cx, 0.36, z))
	var prof := PackedVector2Array([Vector2(1.15, 0.35), Vector2(1.15, 1.4), Vector2(1.05, 1.95), Vector2(0.7, 2.3), Vector2(0.0, 2.4)])
	k.lathe(prof, g, xf(Vector3(cx, 0, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 8)
	for y in [0.6, 1.3]:
		k.torus(1.17, 0.04, brass, xf(Vector3(cx, y, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 8, 4)
	k.torus(0.9, 0.06, lit(cool, 0.4), xf(Vector3(cx, 1.9, z), Vector3.ZERO, Vector3(1.2, 1, 0.95)), 16, 4)
	for i in 3:
		var a := -0.7 + i * 0.7
		k.box(Vector3(0.3, 0.6, 0.08), lit(Color(1.0, 0.86, 0.5), 0.4), xf(Vector3(cx + sin(a) * 1.36, 1.0, z + cos(a) * 1.1), Vector3(0, rad_to_deg(a), 0)))
	k.box(Vector3(0.9, 0.8, 0.3), g.darkened(0.2), at(cx, 0.85, z + 1.08))
	k.box(Vector3(0.7, 0.6, 0.3), lit(cool, 0.4), at(cx, 0.83, z + 1.13))
	# the vent: a brass oculus at the front of the dome
	k.torus(0.3, 0.05, brass, at(cx - 0.2, 2.32, z + 0.35), 12, 4)
	k.cyl(0.26, 0.04, lit(Color(1.0, 0.9, 0.6), 0.35), at(cx - 0.2, 2.3, z + 0.35), 10)
	# coolant manifolds: brass collars, glowing pipes up the back
	for i in 2:
		var px := cx + 0.9 + i * 0.22
		_tube(k, [Vector3(px, 0.6, z - 0.9), Vector3(px, 2.6, z - 0.9), Vector3(px + 0.3, 2.6, z - 1.2)], 0.08, lit(cool, 0.45) if i == 0 else lit(Color(1.0, 0.6, 0.4), 0.45), 8)
		k.box(Vector3(0.22, 0.12, 0.22), brass, at(px, 1.6, z - 0.9))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.36, 1.4, 0.36), g, at(cx + sx * 1.25, 1.05, z - 0.85))
		k.box(Vector3(0.4, 0.06, 0.4), brass, at(cx + sx * 1.25, 1.78, z - 0.85))
		k.box(Vector3(0.04, 1.2, 0.04), lit(cool, 0.45), at(cx + sx * 1.25, 1.05, z - 0.66))


## Hyperscale: a graphite bench on brass legs with a glowing edge.
static func _bench4(k: MeshKit) -> void:
	var g := Color(0.2, 0.21, 0.24)
	var brass := Color(0.78, 0.63, 0.38)
	k.box(Vector3(1.42, 0.06, 0.96), g, at(0, 0.74, 0))
	k.box(Vector3(1.44, 0.025, 0.98), brass, at(0, 0.705, 0))
	k.box(Vector3(1.4, 0.02, 0.02), lit(Color(1.0, 0.86, 0.5), 0.4), at(0, 0.7, 0.49))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.05, 0.7, 0.05), brass, xf(Vector3(sx * 0.6, 0.35, sz * 0.4), Vector3(sz * 6, 0, -sx * 6)))
	k.box(Vector3(1.0, 0.3, 0.6), g, at(0, 0.2, 0))
	k.box(Vector3(0.8, 0.04, 0.02), lit(Color(0.42, 0.9, 1.0), 0.45), at(0, 0.25, 0.31))


## Hyperscale: a graphite power vault with brass trim and a glowing bay.
static func _dock4(k: MeshKit) -> void:
	var g := Color(0.18, 0.19, 0.22)
	var brass := Color(0.78, 0.63, 0.38)
	k.box(Vector3(1.36, 0.1, 1.0), Color(0.12, 0.12, 0.14), at(0, 0.05, 0))
	k.box(Vector3(1.28, 0.66, 0.92), g, at(0, 0.43, 0))
	k.box(Vector3(1.32, 0.06, 0.96), brass, at(0, 0.79, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.66, 0.05), brass, at(sx * 0.64, 0.43, 0.46))
	k.box(Vector3(1.0, 0.4, 0.02), lit(Color(1.0, 0.86, 0.5), 0.4), at(0, 0.45, 0.465))
	for i in 6:
		k.box(Vector3(0.02, 0.36, 0.025), g, at(-0.42 + i * 0.17, 0.45, 0.47))
	_tube(k, [Vector3(-0.4, 0.4, -0.47), Vector3(-0.4, 0.12, -0.6), Vector3(-0.2, 0.12, -1.75)], 0.05, lit(Color(1.0, 0.86, 0.5), 0.45), 6)


# ================================================================ extra detail passes

## Tier 2 extras: an entrance canopy, roof seams and skylights, overhead
## cable ladders, a bike rack, benches and wall signage.
static func _campus_more(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var white2 := Color(0.86, 0.88, 0.9)
	var teal := Color(0.3, 0.66, 0.68)
	var top := 6.3
	# roof: membrane seams, drains, two skylights, a lightning rod
	for i in 16:
		k.box(Vector3(0.02, 0.012, 1.0), white2, at(-3.3 + i * 0.52, top + 0.035, -2.3))
	for x in [-2.6, 1.0]:
		k.box(Vector3(0.12, 0.02, 0.12), Color(0.4, 0.42, 0.44), at(x, top + 0.04, -2.75))
	for x in [-3.3, 1.95]:
		k.box(Vector3(0.6, 0.12, 0.4), white2, at(x, top + 0.09, -2.65))
		k.box(Vector3(0.5, 0.04, 0.3), Color(0.6, 0.8, 0.9), xf(Vector3(x, top + 0.17, -2.65), Vector3(12, 0, 0)))
	k.cyl(0.015, 1.1, Color(0.6, 0.62, 0.64), at(4.7, top + 0.3, -2.8), 4)
	# the stair core: a door, an exit sign, a roof access ladder
	k.box(Vector3(0.75, 2.05, 0.05), white2, at(-4.05, 1.07, -1.93))
	k.box(Vector3(0.66, 1.96, 0.04), Color(0.6, 0.8, 0.9), at(-4.05, 1.05, -1.91))
	k.box(Vector3(0.3, 0.12, 0.04), Color(0.2, 0.62, 0.3), at(-4.05, 2.25, -1.91))
	ArchKit.ladder(k, xf(Vector3(-3.6, top + 0.03, -2.7), Vector3(0, 180, 0)), 0.65, white2)
	# overhead cable ladders along the side walls inside
	for s in [-1.0, 1.0]:
		var x: float = s * 4.55
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.03, 0.06, 2.9), white2, at(x + sz * 0.15, 2.9, -1.0))
		for i in 10:
			k.box(Vector3(0.3, 0.025, 0.03), white2, at(x, 2.9, -2.35 + i * 0.3))
		for c in 3:
			k.box(Vector3(0.05, 0.04, 2.9), [Color(0.3, 0.55, 0.95), teal, Color(0.95, 0.75, 0.25)][c], at(x - 0.08 + c * 0.08, 2.94, -1.0))
		for i in 3:
			k.box(Vector3(0.01, 0.4, 0.01), Color(0.5, 0.52, 0.56), at(x, 3.1, -2.2 + i * 1.2))
	# wall signs: a room plate, a no-food sign, a fire panel, a clock
	k.box(Vector3(0.5, 0.18, 0.02), teal, at(-2.0, 2.0, -2.77))
	k.box(Vector3(0.4, 0.06, 0.022), white, at(-2.0, 2.0, -2.765))
	k.box(Vector3(0.1, 0.4, 0.3), Color(0.86, 0.18, 0.16), at(4.78, 1.6, -1.6))
	k.box(Vector3(0.02, 0.1, 0.1), lit(Color(1.0, 0.4, 0.3), 0.4), at(4.72, 1.7, -1.6))
	k.cyl(0.12, 0.03, white, xf(Vector3(4.79, 2.6, -1.0), Vector3(0, 0, 90)), 10)
	# a bench by the planters
	k.box(Vector3(0.9, 0.06, 0.35), Color(0.72, 0.56, 0.4), at(1.75, 0.45, 2.0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 0.4, 0.3), white2, at(1.75 + sx * 0.38, 0.25, 2.0))


## Tier 3 extras: roof catwalks, a second chiller bank, conduit, signs,
## CCTV, cable ladders across the hall, a guard booth light, column LEDs.
static func _hall_more(k: MeshKit) -> void:
	var steel := Color(0.5, 0.54, 0.6)
	var steel2 := Color(0.38, 0.41, 0.47)
	var dark := Color(0.22, 0.24, 0.28)
	var yel := Color(0.98, 0.8, 0.22)
	var blue := Color(0.45, 0.75, 1.0)
	var top := 7.6
	# roof: a railed walkway on the front edge, an exhaust stack, a mast
	ArchKit.railing(k, Vector3(-3.4, top + 0.34, -1.78), Vector3(4.8, top + 0.34, -1.78), 0.9, yel, 0.8)
	# cable ladders across the hall under the trusses, with drops to the racks
	for z in [-1.45]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(9.3, 0.06, 0.03), yel.darkened(0.15), at(0, 5.9, z + sz * 0.2))
		for i in 24:
			k.box(Vector3(0.03, 0.025, 0.4), yel.darkened(0.15), at(-4.6 + i * 0.4, 5.9, z))
		for c in 3:
			k.box(Vector3(9.3, 0.05, 0.05), [blue.darkened(0.2), Color(0.2, 0.2, 0.22), yel][c], at(0, 5.94, z - 0.1 + c * 0.1))
		for x in [-4.0, -1.5, 1.0, 3.5]:
			k.box(Vector3(0.015, 7.3 - 5.9, 0.015), dark, at(x, (7.3 + 5.9) * 0.5, z))
	# blue LED strips up the front columns, column plates, CCTV, signs
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.03, 6.8, 0.03), lit(blue, 0.45), at(s * 4.66, 3.6, 0.62))
		k.box(Vector3(0.16, 0.24, 0.16), Color(0.92, 0.92, 0.9), xf(Vector3(s * 4.6, 6.2, 0.62), Vector3(20, s * -30, 0)))
		k.box(Vector3(0.4, 0.4, 0.02), yel, at(s * 4.66, 2.0, 0.63))
		k.box(Vector3(0.2, 0.2, 0.025), Color(0.15, 0.15, 0.16), at(s * 4.66, 2.0, 0.635))
	# louvred intake hoods at the bottom of the side walls
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.3, 0.6, 1.2), steel2, at(s * 4.75, 3.3, -0.6))
		for i in 5:
			k.box(Vector3(0.32, 0.03, 1.15), dark, at(s * 4.75, 3.08 + i * 0.1, -0.6))
	# a pipe rack in the yard, from the transformer to the hall
	for x in [3.5, 4.6]:
		k.box(Vector3(0.08, 2.4, 0.08), steel2, at(x, 1.2, 1.65))
	k.box(Vector3(1.2, 0.08, 0.3), steel2, at(4.05, 2.4, 1.65))
	_tube(k, [Vector3(4.6, 2.5, 2.2), Vector3(4.6, 2.5, 1.55), Vector3(4.6, 2.5, 0.6), Vector3(4.6, 3.3, 0.6)], 0.06, Color(0.2, 0.2, 0.22), 6)
	_tube(k, [Vector3(4.4, 2.5, 2.2), Vector3(4.4, 2.5, 1.55), Vector3(4.4, 2.5, 0.6), Vector3(4.4, 3.3, 0.6)], 0.06, yel, 6)


## Tier 4 extras: facade mullions and vents, the tower's end fins, a louvred
## screen round the coolers, more cooling loops, a parked drone, plaza
## planters with trees, benches, a glowing reflecting pool, a satellite dish.
static func _hyper_more(k: MeshKit) -> void:
	var g := Color(0.17, 0.18, 0.21)
	var g2 := Color(0.24, 0.25, 0.29)
	var g3 := Color(0.11, 0.11, 0.13)
	var brass := Color(0.78, 0.63, 0.38)
	var glow := Color(1.0, 0.86, 0.5)
	var cool := Color(0.42, 0.9, 1.0)
	var ct := 8.4
	var top := 9.9
	# facade: brass mullions between the fins at every floor, vents at the base
	for y in [5.4, 6.6, 7.8]:
		for i in 14:
			k.box(Vector3(0.44, 0.03, 0.05), brass.darkened(0.2), at(-3.018 + i * 0.564, y, -1.62))
	for i in 14:
		k.box(Vector3(0.4, 0.2, 0.04), g3, at(-3.018 + i * 0.564, 4.85, -1.62))
		for j in 3:
			k.box(Vector3(0.36, 0.02, 0.05), g2, at(-3.018 + i * 0.564, 4.79 + j * 0.06, -1.6))
	# the tower's right end: fins and a glow line
	for i in 4:
		k.box(Vector3(0.28, ct - 3.8, 0.08), g2, at(4.92 - 0.14, (3.6 + ct) * 0.5, -2.75 + i * 0.32))
		k.box(Vector3(0.03, ct - 4.2, 0.03), lit(glow, 0.4), at(4.92 - 0.02, (3.6 + ct) * 0.5, -2.75 + i * 0.32 + 0.05))
	# the crown floor's corners: brass blades and lights
	for s in [-1.0, 1.0]:
		k.box(Vector3(0.12, top - ct + 0.4, 0.12), brass, at(s * 4.84, (ct + top) * 0.5, 0.29))
		k.sphere(0.07, lit(glow, 0.35), at(s * 4.84, top + 0.3, 0.29), 6, 4)
	for i in 12:
		k.box(Vector3(0.6, 0.04, 0.05), brass.darkened(0.15), at(-4.4 + i * 0.8, ct + 0.75, 0.47))
	# a louvred screen in front of the dry coolers, a satellite dish, a parked drone
	for i in 4:
		k.box(Vector3(3.6, 0.04, 0.1), g2, xf(Vector3(-2.35, top + 0.15 + i * 0.12, -1.72), Vector3(-30, 0, 0)))
	for x in [-4.15, -2.35, -0.55]:
		k.box(Vector3(0.06, 0.8, 0.06), brass, at(x, top + 0.42, -1.72))
	var dp := Vector3(1.3, top, -0.2)
	k.cyl(0.08, 0.5, g2, at(dp.x, dp.y, dp.z), 6)
	k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(0.25, 0.04), Vector2(0.5, 0.18), Vector2(0.47, 0.19), Vector2(0.24, 0.07), Vector2(0.0, 0.03)]), Color(0.86, 0.86, 0.84), xf(dp + Vector3(0, 0.55, 0), Vector3(-40, 30, 0)), 12)
	k.sphere(0.04, lit(Color(1.0, 0.35, 0.3), 0.3), at(dp.x + 0.1, dp.y + 0.95, dp.z + 0.15), 5, 3)
	var dr := Vector3(2.9, top + 0.1, -1.35)
	k.box(Vector3(0.36, 0.1, 0.36), g3, at(dr.x, dr.y + 0.08, dr.z))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		k.box(Vector3(0.36, 0.03, 0.04), g2, xf(Vector3(dr.x + cos(a) * 0.18, dr.y + 0.12, dr.z + sin(a) * 0.18), Vector3(0, -rad_to_deg(a), 0)))
		k.torus(0.13, 0.015, lit(cool, 0.4), at(dr.x + cos(a) * 0.36, dr.y + 0.14, dr.z + sin(a) * 0.36), 8, 3)
	k.box(Vector3(0.2, 0.04, 0.02), lit(glow, 0.4), at(dr.x, dr.y + 0.1, dr.z + 0.19))
	# more cooling loops: along the gallery soffit and down to the racks
	for i in 2:
		var pc := lit(cool, 0.45) if i == 0 else lit(Color(1.0, 0.6, 0.4), 0.45)
		_tube(k, [Vector3(-3.4, 3.35 - i * 0.18, -2.15), Vector3(4.1, 3.35 - i * 0.18, -2.15), Vector3(4.35 + i * 0.22, 3.35 - i * 0.18, -2.15), Vector3(4.35 + i * 0.22, 2.6, -2.15)], 0.06, pc, 8)
		for x in [-2.5, -0.5, 1.5]:
			k.box(Vector3(0.16, 0.06, 0.16), brass, at(x, 3.35 - i * 0.18, -2.15))
	for i in 8:
		var rx := -3.15 + i * 0.6
		_tube(k, [Vector3(rx + 0.1, 3.17, -2.15), Vector3(rx + 0.1, 2.5, -2.3)], 0.025, lit(cool, 0.45), 5, false)
	# plaza: graphite planters with trees, benches, a glowing reflecting pool
	for p in [Vector3(-2.1, 0.06, 2.2), Vector3(1.45, 0.06, 2.2)]:
		k.box(Vector3(0.7, 0.45, 0.7), g, at(p.x, p.y + 0.225, p.z))
		k.box(Vector3(0.74, 0.04, 0.74), brass, at(p.x, p.y + 0.45, p.z))
		k.box(Vector3(0.62, 0.03, 0.62), Color(0.22, 0.18, 0.14), at(p.x, p.y + 0.44, p.z))
		k.cyl(0.05, 0.9, Color(0.32, 0.26, 0.2), at(p.x, p.y + 0.45, p.z), 5)
		k.sphere(0.38, Color(0.3, 0.5, 0.32), xf(Vector3(p.x, p.y + 1.55, p.z), Vector3.ZERO, Vector3(1, 0.9, 1)), 8, 5)
		k.sphere(0.24, Color(0.36, 0.58, 0.36), at(p.x + 0.15, p.y + 1.8, p.z + 0.1), 7, 4)

## Tier 3, more: high-bay lamps under the trusses, a gas cylinder cage and
## cable drums in the generator yard, a roll-up loading door on the side.
static func _hall_more2(k: MeshKit) -> void:
	var steel2 := Color(0.38, 0.41, 0.47)
	var dark := Color(0.22, 0.24, 0.28)
	var yel := Color(0.98, 0.8, 0.22)
	var blue := Color(0.45, 0.75, 1.0)
	for z in [0.5]:
		for x in [-3.6, -2.0, -0.4, 1.2]:
			k.box(Vector3(0.015, 0.6, 0.015), dark, at(x, 6.75, z))
			k.cone(0.26, 0.22, Color(0.3, 0.32, 0.36), xf(Vector3(x, 6.48, z), Vector3(180, 0, 0)), 8)
			k.cyl(0.18, 0.03, lit(Color(0.92, 0.96, 1.0), 0.35), at(x, 6.24, z), 8)
	# side loading door (right wall, behind the core) and its canopy
	ArchKit.rollup(k, xf(Vector3(4.7, 0.06, -1.9), Vector3(0, 90, 0)), 1.4, 2.4, Color(0.6, 0.64, 0.7))
	# gas cylinders in a cage by the generator, cable drums
	var gp := Vector3(-4.45, 0.06, 1.0)
	for i in 4:
		k.cyl(0.08, 0.9, [Color(0.3, 0.5, 0.8), Color(0.86, 0.3, 0.26), Color(0.3, 0.5, 0.8), Color(0.3, 0.62, 0.36)][i], at(gp.x + (i % 2) * 0.18, gp.y, gp.z - 0.55 - (i / 2) * 0.18), 8)
		k.sphere(0.08, Color(0.5, 0.52, 0.56), at(gp.x + (i % 2) * 0.18, gp.y + 0.92, gp.z - 0.55 - (i / 2) * 0.18), 6, 3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.03, 1.1, 0.03), steel2, at(gp.x + 0.09 + sx * 0.22, gp.y + 0.55, gp.z - 0.64 + sz * 0.22))
	k.box(Vector3(0.5, 0.03, 0.5), steel2, at(gp.x + 0.09, gp.y + 1.1, gp.z - 0.64))
	# gallery lights and a blue line under the stair landings
	for x in [-3.0, -1.0, 1.0, 3.0]:
		k.box(Vector3(0.3, 0.06, 0.12), dark, at(x, 4.62, -2.0))
		k.box(Vector3(0.26, 0.02, 0.1), lit(blue, 0.4), at(x, 4.59, -2.0))
	k.box(Vector3(0.6, 0.18, 0.04), yel, at(-4.2, 2.3, -1.9))
	k.box(Vector3(0.4, 0.08, 0.045), dark, at(-4.2, 2.3, -1.88))


## Tier 4, more: a glowing token logo on the crown, coolant distribution
## units in the hall corners, brass cable trays, column rings, plaza inlays.
static func _hyper_more2(k: MeshKit) -> void:
	var g := Color(0.17, 0.18, 0.21)
	var g2 := Color(0.24, 0.25, 0.29)
	var g3 := Color(0.11, 0.11, 0.13)
	var brass := Color(0.78, 0.63, 0.38)
	var glow := Color(1.0, 0.86, 0.5)
	var cool := Color(0.42, 0.9, 1.0)
	var ct := 8.4
	var top := 9.9
	# the logo on the crown face: a brass ring, a glowing token, lettering
	var lp := Vector3(-2.6, (ct + top) * 0.5, 0.66)
	k.box(Vector3(3.6, 0.9, 0.06), g3, at(lp.x + 1.0, lp.y, lp.z))
	k.torus(0.36, 0.05, brass, xf(lp, Vector3(90, 0, 0)), 16, 4)
	k.cyl(0.3, 0.04, lit(glow, 0.35), xf(lp + Vector3(0, 0, 0.01), Vector3(90, 0, 0)), 14)
	k.cyl(0.14, 0.05, lit(cool, 0.35), xf(lp + Vector3(0, 0, 0.02), Vector3(90, 0, 0)), 6)
	for i in 6:
		k.box(Vector3(0.3, 0.32, 0.03), lit(Color(1.0, 0.95, 0.85), 0.4), at(lp.x + 0.65 + i * 0.4, lp.y, lp.z + 0.04))
	k.box(Vector3(3.6, 0.03, 0.08), brass, at(lp.x + 1.0, lp.y - 0.47, lp.z))
	k.box(Vector3(3.6, 0.03, 0.08), brass, at(lp.x + 1.0, lp.y + 0.47, lp.z))
	# coolant distribution units in the front corners of the hall
	for s in [-1.0]:
		var cw := 0.8
		var cp := Vector3(-4.15, 0.06, -0.15)
		k.box(Vector3(cw, 1.8, 0.6), g, at(cp.x, cp.y + 0.9, cp.z))
		k.box(Vector3(cw + 0.04, 0.06, 0.64), brass, at(cp.x, cp.y + 1.8, cp.z))
		for i in 2:
			k.cyl(0.08, 0.03, lit(cool, 0.4), xf(Vector3(cp.x - cw * 0.2 + i * cw * 0.4, cp.y + 1.3, cp.z + 0.3), Vector3(90, 0, 0)), 10)
			k.torus(0.09, 0.015, brass, xf(Vector3(cp.x - cw * 0.2 + i * cw * 0.4, cp.y + 1.3, cp.z + 0.32), Vector3(90, 0, 0)), 10, 3)
		for j in 6:
			k.box(Vector3(cw - 0.12, 0.025, 0.02), g2, at(cp.x, cp.y + 0.25 + j * 0.12, cp.z + 0.31))
		k.box(Vector3(0.2, 0.1, 0.01), lit(glow, 0.45), at(cp.x, cp.y + 1.55, cp.z + 0.305))
		_tube(k, [Vector3(cp.x, cp.y + 1.8, cp.z - 0.1), Vector3(cp.x, 3.45, cp.z - 0.1), Vector3(cp.x, 3.45, -2.0)], 0.05, lit(cool, 0.45), 6)
	# brass cable trays across the hall, glowing bundles
	for z in [-1.45, 0.45]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(9.0, 0.05, 0.03), brass, at(0, 6.2, z + sz * 0.18))
		for i in 18:
			k.box(Vector3(0.03, 0.02, 0.36), brass.darkened(0.2), at(-4.25 + i * 0.5, 6.2, z))
		k.box(Vector3(9.0, 0.04, 0.12), g3, at(0, 6.23, z))
		k.box(Vector3(9.0, 0.02, 0.03), lit(cool, 0.45), at(0, 6.26, z))
	# brass rings up the crown columns
	for s in [-1.0, 1.0]:
		for i in 7:
			k.box(Vector3(0.36, 0.05, 0.36), brass.darkened(0.1), at(s * 4.72, 1.0 + i * 1.05, 0.2))
	# plaza: a glowing medallion in the walkway, brass inlays, a robot courier dock
	k.cyl(0.6, 0.012, g3, at(-0.4, 0.075, 1.7), 16)
	k.torus(0.55, 0.025, brass, at(-0.4, 0.085, 1.7), 16, 3)
	k.torus(0.3, 0.02, lit(glow, 0.4), at(-0.4, 0.085, 1.7), 14, 3)
	for i in 8:
		var a := TAU * i / 8.0
		k.box(Vector3(0.18, 0.012, 0.03), lit(cool, 0.45), xf(Vector3(-0.4 + cos(a) * 0.42, 0.088, 1.7 + sin(a) * 0.42), Vector3(0, -rad_to_deg(a), 0)))
	for x in [-4.6, 4.6]:
		k.box(Vector3(0.04, 0.012, 2.2), brass, at(x, 0.075, 1.7))

## Tier 2, more: a slatted screen fence on the kerb, containment rails over
## the cold aisle, floor guide lights, a flag and wall-washer lights.
static func _campus_more2(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var white2 := Color(0.86, 0.88, 0.9)
	var teal := Color(0.3, 0.66, 0.68)
	for s in [-1.0, 1.0]:
		var xa: float = -4.85 if s < 0 else 2.15
		var xb: float = -2.15 if s < 0 else 4.85
		var n := int((xb - xa) / 0.12)
		for i in n + 1:
			k.box(Vector3(0.05, 0.62, 0.04), white if i % 2 == 0 else white2, at(xa + i * (xb - xa) / n, 0.43, 2.84))
		k.box(Vector3(xb - xa, 0.04, 0.06), teal, at((xa + xb) * 0.5, 0.76, 2.84))
	for z in [-2.05, -0.58]:
		k.box(Vector3(4.62, 0.05, 0.05), white, at(-0.84, 2.62, z))
		k.box(Vector3(4.62, 0.02, 0.02), lit(Color(0.42, 0.96, 0.9), 0.45), at(-0.84, 2.58, z))
	for i in 10:
		k.box(Vector3(0.22, 0.012, 0.05), lit(Color(0.42, 0.96, 0.9), 0.45), at(-3.0 + i * 0.5, 0.105, -0.5))


## Tier 4, more: the sky bridge's floor and lights, glowing data runs from
## the router up to the gallery, brass grilles at the plaza edge.
static func _hyper_more3(k: MeshKit) -> void:
	var g2 := Color(0.24, 0.25, 0.29)
	var g3 := Color(0.11, 0.11, 0.13)
	var brass := Color(0.78, 0.63, 0.38)
	var glow := Color(1.0, 0.86, 0.5)
	var cool := Color(0.42, 0.9, 1.0)
	var by := 5.6
	for i in 6:
		k.box(Vector3(0.2, 0.02, 0.7), g3, at(-4.75 + i * 0.22, by + 0.07, -2.05))
		k.box(Vector3(0.08, 0.02, 0.08), lit(glow, 0.35), at(-4.75 + i * 0.22, by + 1.13, -2.05))
	for i in 3:
		k.box(Vector3(0.12, 0.5, 0.12), Color(0.16, 0.16, 0.18), at(-4.6 + i * 0.4, by + 0.35, -2.2 + (i % 2) * 0.25))
		k.sphere(0.07, Color(0.16, 0.16, 0.18), at(-4.6 + i * 0.4, by + 0.67, -2.2 + (i % 2) * 0.25), 6, 3)
	for i in 3:
		_tube(k, [Vector3(-4.3 + i * 0.12, 2.9, -1.75), Vector3(-4.3 + i * 0.12, 3.5, -1.85)], 0.025, lit([cool, glow, cool][i], 0.45), 5, false)
	for i in 20:
		k.box(Vector3(0.04, 0.02, 0.3), brass.darkened(0.2), at(-4.75 + i * 0.5, 0.075, 2.68))
	for s in [-1.0, 1.0]:
		for i in 4:
			k.box(Vector3(0.05, 0.12, 0.05), brass, at(s * 4.84, 4.2 + i * 1.05, -1.75))
			k.box(Vector3(0.03, 0.06, 0.03), lit(cool, 0.45), at(s * 4.84, 4.2 + i * 1.05, -1.71))

# ---------------------------------------------------------------- growth slots

## The parts the server gathers level by level, in the order they arrive.
const SLOT_PARTS := ["screen", "ac", "cabinet", "panel", "dish_s", "plant", "neon", "ac",
	"battery", "ledbar", "antenna", "kiosk", "solar_s", "chiller", "vent", "crates"]


## Where each growth part sits on tier t (see Growth): wall gear on the
## facade the camera sees, roof gear on that tier's roof, floor gear in yard
## spots the building keeps clear. [{p, yaw, part}] in SLOT_PARTS order.
static func slots(t: int) -> Array:
	var wall: Array          # screen, panel, neon, ledbar: x, at height wy on the face at wz
	var wz := 0.0
	var wy := 0.0
	var roof: Array          # ac, dish_s, ac, antenna, solar_s, vent
	var ground: Dictionary   # cabinet, plant, battery, kiosk, chiller, crates: [position, yaw]
	match t:
		0:
			wall = [-0.9, 0.4, -2.2, 1.7]
			wz = -2.75
			wy = 2.2
			var ry := 3.2
			roof = [Vector3(2.6, ry, -2.62), Vector3(-2.6, ry, -2.62), Vector3(3.75, ry, -2.62), Vector3(-3.75, ry, -2.62), Vector3(-1.45, ry, -2.62), Vector3(1.45, ry, -2.62)]
			ground = {"cabinet": [Vector3(-4.25, 0, 2.2), 0.0], "plant": [Vector3(4.3, 0, 2.35), 0.0], "battery": [Vector3(-3.3, 0, 2.3), 0.0],
				"kiosk": [Vector3(2.4, 0, 2.5), 0.0], "chiller": [Vector3(-4.25, 0, -0.25), 90.0], "crates": [Vector3(4.4, 0, 0.2), -90.0]}
		1:
			wall = [0.4, 2.2, 1.3, 3.6]
			wz = -1.63
			wy = 3.97
			var ry := 6.06
			roof = [Vector3(2.3, ry, -2.3), Vector3(-0.4, ry, -2.3), Vector3(3.2, ry, -2.3), Vector3(4.15, ry, -2.3), Vector3(0.5, ry, -2.3), Vector3(1.4, ry, -2.3)]
			ground = {"cabinet": [Vector3(-4.25, 0, 2.2), 0.0], "plant": [Vector3(4.3, 0, 2.35), 0.0], "battery": [Vector3(-3.3, 0, 2.35), 0.0],
				"kiosk": [Vector3(2.0, 0, 2.6), 0.0], "chiller": [Vector3(-3.4, 3.55, -2.6), 0.0], "crates": [Vector3(3.6, 0, 1.95), 0.0]}
		2:
			wall = [-0.9, 0.4, -2.2, 1.7]
			wz = -1.66
			wy = 3.76
			var ry := 6.33
			roof = [Vector3(-0.35, ry, -2.2), Vector3(-2.15, ry, -2.2), Vector3(0.55, ry, -2.2), Vector3(-3.05, ry, -2.2), Vector3(-1.25, ry, -2.2), Vector3(1.45, ry, -2.2)]
			ground = {"cabinet": [Vector3(-4.25, 0, 2.2), 0.0], "plant": [Vector3(4.3, 0, 2.35), 0.0], "battery": [Vector3(-3.25, 0, 2.35), 0.0],
				"kiosk": [Vector3(2.45, 0, 2.45), 0.0], "chiller": [Vector3(-4.2, 6.93, -2.42), 0.0], "crates": [Vector3(3.35, 0, 2.45), 0.0]}
		3:
			wall = [-0.9, 0.4, -2.2, 1.7]
			wz = -1.66
			wy = 5.13
			var ry := 7.63
			roof = [Vector3(-0.35, ry, -2.05), Vector3(-2.15, ry, -2.05), Vector3(0.55, ry, -2.05), Vector3(-3.05, ry, -2.05), Vector3(-1.25, ry, -2.05), Vector3(1.45, ry, -2.05)]
			ground = {"cabinet": [Vector3(-4.3, 0, -0.15), 0.0], "plant": [Vector3(-2.1, 0, 2.5), 0.0], "battery": [Vector3(4.45, 0, 0.2), -90.0],
				"kiosk": [Vector3(2.3, 0, 1.95), 0.0], "chiller": [Vector3(-4.1, 8.66, -2.42), 0.0], "crates": [Vector3(2.75, 0, 2.5), 0.0]}
		_:
			wall = [-0.9, 0.4, -2.2, 1.7]
			wz = -1.33
			wy = 4.3
			var ry := 9.94
			roof = [Vector3(-3.45, ry, -1.35), Vector3(-4.35, ry, -1.35), Vector3(-2.55, ry, -1.35), Vector3(-4.35, ry, -0.35), Vector3(-3.45, ry, -0.35), Vector3(-2.55, ry, -0.35)]
			ground = {"cabinet": [Vector3(-4.3, 0, 2.3), 0.0], "plant": [Vector3(4.3, 0, 2.35), 0.0], "battery": [Vector3(-3.3, 0, 2.35), 0.0],
				"kiosk": [Vector3(2.5, 0, 2.4), 0.0], "chiller": [Vector3(1.0, ry, -2.4), 0.0], "crates": [Vector3(3.4, 0, 2.4), 0.0]}
	var wi := {"screen": 0, "panel": 1, "neon": 2, "ledbar": 3}
	var ri := 0
	var out := []
	for part in SLOT_PARTS:
		if wi.has(part):
			out.append({"p": Vector3(wall[wi[part]], wy, wz), "yaw": 0.0, "part": part})
		elif part in ["ac", "dish_s", "antenna", "solar_s", "vent"]:
			out.append({"p": roof[ri], "yaw": 0.0, "part": part})
			ri += 1
		else:
			var gd: Array = ground[part]
			out.append({"p": gd[0], "yaw": gd[1], "part": part})
	return out
