class_name LabArt
## The labs, each its own building that grows through the five eras of
## ArchKit (garage, workshop, campus, industrial, hyperscale):
##   fab        soldering desk + toaster reflow -> cleanroom booth -> white
##              cleanroom pod -> fab bay with a litho tool -> graphite EUV tower
##   refinery   laptop + shredder -> sorting shed with a hopper -> campus data
##              plant with columns -> distillation towers -> glowing column
##   tune_lab   desk with monitors -> console booth -> studio with a screen
##              wall -> control hall with a dish -> graphite holo dome
##   hbm_works  hand press -> hydraulic press -> stacking cell -> press hall
##              -> stacked-die monolith
##   rlhf_gym   folding chairs and a whiteboard -> feedback booths -> campus
##              gym with a robot arm -> arena -> reward-model citadel
##   synth_lab  chemistry set -> fume cabinet + flask rig -> campus lab dome
##              -> reactor hall -> glowing reactor sphere on a brass cradle
## Layout (local, front +Z): the machine fills the back two thirds (wings
## left and right with flat roofs under the Growth roof slots, the hero in
## the middle), the input/output benches sit at MachineB.IN_POS/OUT_POS and
## the front apron stays walkable. Each has a moving part (part/anim_pivot/
## animate). The Supply Depot lives here too (depot(): tarp-covered heap ->
## pallet racking under a canopy -> logistics shed -> automated high-bay ->
## robotic vault). Detail is layered in passes (_<kind>_more, _deluxe,
## _extra2..4) so the later eras end up the busiest.

## Roof slots (Growth) sit on the wings' flat roofs: x, z.
const ROOFS := [Vector2(-1.42, -1.45), Vector2(1.42, -1.45), Vector2(-1.42, -0.8), Vector2(1.42, -0.8)]
const WX := 1.0           # wings: inner edge
const WX1 := 1.8          # outer edge (attachments may reach 1.9)
const WF := -0.45         # wings and the hero's front face
const BK := -1.88         # back line


# ---------------------------------------------------------------- helpers

static func lit(c: Color, a := 0.45) -> Color:
	return Color(c.r, c.g, c.b, a)


static func at(x: float, y: float, z: float) -> Transform3D:
	return MeshKit.at(x, y, z)


static func xf(p: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return MeshKit.xf(p, rot, scl)


## Sharp box centred at p.
static func bx(k: MeshKit, size: Vector3, col: Color, p: Vector3, rot := Vector3.ZERO) -> void:
	k.box(size, col, MeshKit.xf(p, rot))


## Sharp box between two corners.
static func bb(k: MeshKit, a: Vector3, b: Vector3, col: Color) -> void:
	k.box((b - a).abs(), col, MeshKit.at((a.x + b.x) * 0.5, (a.y + b.y) * 0.5, (a.z + b.z) * 0.5))


## Upright cylinder standing at p.
static func cy(k: MeshKit, r: float, h: float, col: Color, p: Vector3, segs := 8, r2 := -1.0) -> void:
	k.cyl(r, h, col, MeshKit.at(p.x, p.y, p.z), segs, 0.0, r2)


## A square beam from a to b (cables, braces, struts).
static func seg(k: MeshKit, a: Vector3, b: Vector3, th: float, col: Color, th2 := -1.0) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return
	var z := d / len
	var up := Vector3.UP if absf(z.y) < 0.99 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	k.box(Vector3(th, th2 if th2 > 0.0 else th, len), col, Transform3D(Basis(x, y, z), (a + b) * 0.5))


## A round tube from a to b.
static func tube(k: MeshKit, a: Vector3, b: Vector3, r: float, col: Color, segs := 6) -> void:
	var d := b - a
	var len := d.length()
	if len < 0.001:
		return
	var n := d / len
	var basis := Basis(Quaternion(Vector3.UP, n)) if absf(n.dot(Vector3.UP)) < 0.999 else (Basis.IDENTITY if d.y > 0 else Basis(Vector3.RIGHT, PI))
	k.cyl(r, len, col, Transform3D(basis, a), segs, 0.0, -1.0, true)


## A run of tube through points (with small joints).
static func run(k: MeshKit, pts: Array, r: float, col: Color, segs := 6) -> void:
	for i in pts.size() - 1:
		tube(k, pts[i], pts[i + 1], r, col, segs)
		if i > 0:
			var q: Vector3 = pts[i]
			k.box(Vector3.ONE * r * 2.3, col, at(q.x, q.y, q.z))


## Horizontal cylinder centred at p, along x (or z).
static func hcy(k: MeshKit, r: float, len: float, col: Color, p: Vector3, along_x := true, segs := 8) -> void:
	if along_x:
		k.cyl(r, len, col, MeshKit.xf(p + Vector3(-len * 0.5, 0, 0), Vector3(0, 0, -90)), segs)
	else:
		k.cyl(r, len, col, MeshKit.xf(p + Vector3(0, 0, -len * 0.5), Vector3(90, 0, 0)), segs)


## A sagging cable from a to b.
static func cable(k: MeshKit, a: Vector3, b: Vector3, col: Color, sag := 0.15, th := 0.02) -> void:
	var prev := a
	for i in range(1, 5):
		var f := i / 4.0
		var q := a.lerp(b, f) - Vector3(0, sin(f * PI) * sag, 0)
		seg(k, prev, q, th, col)
		prev = q


## A flat-lying cord on the ground through xz points.
static func cord(k: MeshKit, pts: Array, col: Color) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		seg(k, Vector3(a.x, 0.045, a.y), Vector3(b.x, 0.045, b.y), 0.025, col, 0.02)


## A screen (dark bezel, glowing face) on a face frame.
static func screen(k: MeshKit, face: Transform3D, w: float, h: float, col: Color, bars := 0) -> void:
	k.box(Vector3(w + 0.04, h + 0.04, 0.03), Color(0.12, 0.12, 0.14), face * at(0, 0, 0.0))
	k.box(Vector3(w, h, 0.01), lit(col, 0.5), face * at(0, 0, 0.018))
	for i in bars:
		var bh := h * (0.25 + 0.6 * absf(sin(i * 1.9 + w * 7.0)))
		k.box(Vector3(w / bars * 0.6, bh, 0.01), lit(col.lightened(0.45), 0.35), face * at(-w * 0.5 + (i + 0.5) * w / bars, -h * 0.5 + bh * 0.5 + 0.02, 0.026))


## A stack light (green/amber/red) on a pole.
static func stack_light(k: MeshKit, p: Vector3, h := 0.4) -> void:
	cy(k, 0.012, h, Color(0.3, 0.32, 0.36), p, 5)
	var cols := [Color(0.4, 1.0, 0.5), Color(1.0, 0.75, 0.25), Color(1.0, 0.3, 0.25)]
	for i in 3:
		cy(k, 0.035, 0.06, lit(cols[i], 0.4 if i == 0 else 0.7), p + Vector3(0, h + i * 0.065, 0), 6)
	cy(k, 0.038, 0.02, Color(0.2, 0.2, 0.22), p + Vector3(0, h + 0.195, 0), 6)


## A wooden crate.
static func crate(k: MeshKit, p: Vector3, s: Vector3, yaw := 0.0, col := Color(0.72, 0.56, 0.38)) -> void:
	var b := MeshKit.xf(p + Vector3(0, s.y * 0.5, 0), Vector3(0, yaw, 0))
	k.box(s, col, b)
	for sy in [-1.0, 1.0]:
		k.box(Vector3(s.x + 0.012, 0.035, s.z + 0.012), col.darkened(0.22), b * at(0, sy * (s.y * 0.5 - 0.03), 0))
	k.box(Vector3(0.035, s.y - 0.04, s.z + 0.014), col.darkened(0.22), b * at(0, 0, 0))


## A pallet (slats on runners).
static func pallet(k: MeshKit, p: Vector3, w := 0.8, d := 0.6, col := Color(0.66, 0.52, 0.36)) -> void:
	for i in 3:
		k.box(Vector3(0.08, 0.06, d), col.darkened(0.12), at(p.x - w * 0.4 + i * w * 0.4, p.y + 0.03, p.z))
	for j in 5:
		k.box(Vector3(w, 0.025, d * 0.14), col, at(p.x, p.y + 0.072, p.z - d * 0.43 + j * d * 0.215))


## A drum or barrel.
static func drum(k: MeshKit, p: Vector3, col: Color, r := 0.13, h := 0.4) -> void:
	cy(k, r, h, col, p, 8)
	cy(k, r + 0.008, 0.025, col.darkened(0.25), p + Vector3(0, h * 0.33, 0), 8)
	cy(k, r + 0.008, 0.025, col.darkened(0.25), p + Vector3(0, h * 0.66, 0), 8)
	cy(k, 0.025, 0.02, Color(0.2, 0.2, 0.22), p + Vector3(r * 0.5, h, 0), 5)


## A gas cylinder with a valve cap.
static func gas_bottle(k: MeshKit, p: Vector3, col: Color, h := 0.8, r := 0.07) -> void:
	cy(k, r, h, col, p, 6)
	cy(k, r * 0.7, 0.06, col.darkened(0.2), p + Vector3(0, h, 0), 6, r * 0.4)
	cy(k, 0.02, 0.07, Color(0.6, 0.6, 0.62), p + Vector3(0, h + 0.06, 0), 5)


## A person-ish figure (worker in coveralls / bunny suit), standing at p.
static func figure(k: MeshKit, p: Vector3, col: Color, yaw := 0.0, head := Color(0.86, 0.68, 0.54)) -> void:
	var b := MeshKit.xf(p, Vector3(0, yaw, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.07, 0.42, 0.08), col.darkened(0.15), b * at(sx * 0.05, 0.21, 0))
	k.box(Vector3(0.22, 0.34, 0.13), col, b * at(0, 0.6, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 0.3, 0.07), col, b * xf(Vector3(sx * 0.14, 0.6, 0.02), Vector3(-15, 0, 0)))
	k.box(Vector3(0.13, 0.14, 0.13), head, b * at(0, 0.86, 0))


## A straight stair from a (bottom centre) to b (top centre), width w.
static func stair(k: MeshKit, a: Vector3, b: Vector3, w: float, col: Color, rail: Color) -> void:
	var d := b - a
	var hl := Vector2(d.x, d.z).length()
	var n := maxi(3, int(d.y / 0.17))
	var yaw := rad_to_deg(atan2(d.x, d.z))
	var side := Vector3(cos(deg_to_rad(yaw)), 0, -sin(deg_to_rad(yaw))) * w * 0.5
	for i in n:
		var q := a.lerp(b, (i + 0.5) / n)
		k.box(Vector3(w, 0.035, hl / n + 0.02), col, xf(q, Vector3(0, yaw, 0)))
	for s in [-1.0, 1.0]:
		seg(k, a + side * s, b + side * s, 0.05, col.darkened(0.25), 0.1)
		seg(k, a + side * s + Vector3(0, 0.8, 0), b + side * s + Vector3(0, 0.8, 0), 0.03, rail)
		seg(k, a + side * s, a + side * s + Vector3(0, 0.8, 0), 0.03, rail)
		seg(k, b + side * s, b + side * s + Vector3(0, 0.8, 0), 0.03, rail)


## A grating deck from a to b (min/max corners, top at b.y) with rails on
## the listed edges ("f" +z, "b" -z, "l" -x, "r" +x).
static func deck(k: MeshKit, a: Vector3, b: Vector3, col: Color, rail: Color, edges := "") -> void:
	bb(k, Vector3(a.x, b.y - 0.05, a.z), b, col)
	var n := int((b.x - a.x) / 0.18)
	for i in n:
		bb(k, Vector3(a.x + (i + 0.5) * (b.x - a.x) / n - 0.01, b.y - 0.07, a.z), Vector3(a.x + (i + 0.5) * (b.x - a.x) / n + 0.01, b.y - 0.05, b.z), col.darkened(0.3))
	for e in edges:
		match e:
			"f": ArchKit.railing(k, Vector3(a.x, b.y, b.z - 0.02), Vector3(b.x, b.y, b.z - 0.02), 0.6, rail, 0.5)
			"b": ArchKit.railing(k, Vector3(a.x, b.y, a.z + 0.02), Vector3(b.x, b.y, a.z + 0.02), 0.6, rail, 0.5)
			"l": ArchKit.railing(k, Vector3(a.x + 0.02, b.y, a.z), Vector3(a.x + 0.02, b.y, b.z), 0.6, rail, 0.5)
			"r": ArchKit.railing(k, Vector3(b.x - 0.02, b.y, a.z), Vector3(b.x - 0.02, b.y, b.z), 0.6, rail, 0.5)


## A server rack (front facing +z) with blinking lights.
static func rack(k: MeshKit, p: Vector3, h: float, t: int, yaw := 0.0) -> void:
	var b := xf(p, Vector3(0, yaw, 0))
	var body: Color = Color(0.16, 0.17, 0.2) if t != 2 else Color(0.9, 0.91, 0.92)
	k.box(Vector3(0.32, h, 0.36), body, b * at(0, h * 0.5, 0))
	k.box(Vector3(0.28, h - 0.1, 0.01), body.darkened(0.3) if t != 2 else Color(0.3, 0.32, 0.36), b * at(0, h * 0.5, 0.18))
	var lc := [Color(0.4, 1.0, 0.5), Color(0.4, 0.8, 1.0), Color(1.0, 0.75, 0.3)]
	for i in int((h - 0.15) / 0.1):
		k.box(Vector3(0.2, 0.02, 0.01), lit(lc[(i * 7 + int(p.x * 10)) % 3], 0.4), b * at(-0.02, 0.1 + i * 0.1, 0.19))


## A chain-link panel from a to b (on the ground), height h.
static func mesh_fence(k: MeshKit, a: Vector3, b: Vector3, h: float) -> void:
	var col := Color(0.62, 0.64, 0.66)
	var d := b - a
	var len := d.length()
	var n := maxi(1, int(len / 0.6))
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		cy(k, 0.02, h, col, q, 5)
	seg(k, a + Vector3(0, h, 0), b + Vector3(0, h, 0), 0.03, col)
	seg(k, a + Vector3(0, h * 0.5, 0), b + Vector3(0, h * 0.5, 0), 0.006, col.darkened(0.2), h * 0.95)


## Glowing vertical fins (n across w, depth dp) on a face frame.
static func fins(k: MeshKit, face: Transform3D, w: float, h: float, n: int, dp := 0.12, t := 4, glow := Color(0, 0, 0, 0)) -> void:
	var g: Color = glow if glow.a > 0.0 else ArchKit.c(t, "glow")
	for i in n:
		var x := -w * 0.5 + (i + 0.5) * w / n
		k.box(Vector3(0.07, h, dp), ArchKit.c(t, "wall2"), face * at(x, h * 0.5, dp * 0.5))
		k.box(Vector3(0.018, h * 0.9, 0.02), lit(g, 0.4), face * at(x, h * 0.5, dp + 0.01))


## A door with its frame and a shallow hood (local face frame, +z out).
static func door(k: MeshKit, face: Transform3D, t: int, w := 0.5, h := 1.3) -> void:
	var p := ArchKit.pal(t)
	k.box(Vector3(w + 0.1, h + 0.06, 0.04), p["frame"], face * at(0, (h + 0.06) * 0.5, 0.02))
	if t >= 2:
		k.box(Vector3(w, h, 0.03), p["glass"], face * at(0, h * 0.5, 0.04))
		k.box(Vector3(0.025, h, 0.05), p["frame"], face * at(0, h * 0.5, 0.045))
	else:
		k.box(Vector3(w, h, 0.03), p["wall2"].darkened(0.25), face * at(0, h * 0.5, 0.04))
		k.box(Vector3(0.04, 0.1, 0.04), p["metal"], face * at(w * 0.35, h * 0.5, 0.07))
	if t >= 1:
		k.box(Vector3(w + 0.2, 0.04, 0.12), p["trim"], face * at(0, h + 0.12, 0.06))
	if t >= 3:
		k.box(Vector3(w * 0.8, 0.02, 0.02), lit(p["glow"], 0.4), face * at(0, h + 0.09, 0.12))


## Panel seams on a face frame (w x h, bottom at y=0): nx vertical and ny
## horizontal lines, so big walls read as built from panels.
static func seams(k: MeshKit, face: Transform3D, w: float, h: float, nx: int, ny: int, col: Color) -> void:
	for i in range(1, nx):
		k.box(Vector3(0.014, h, 0.01), col, face * at(-w * 0.5 + i * w / nx, h * 0.5, 0.005))
	for j in range(1, ny):
		k.box(Vector3(w, 0.014, 0.01), col, face * at(0, j * h / ny, 0.005))


## A wall-mounted box (junction box, panel) with a little light.
static func jbox(k: MeshKit, face: Transform3D, col: Color, led := Color(0.4, 1.0, 0.5)) -> void:
	k.box(Vector3(0.16, 0.2, 0.06), col, face * at(0, 0, 0.03))
	k.box(Vector3(0.12, 0.012, 0.01), col.darkened(0.3), face * at(0, 0.03, 0.062))
	k.box(Vector3(0.025, 0.025, 0.01), lit(led, 0.4), face * at(0.045, 0.07, 0.062))


## A bollard light (low post with a glowing head).
static func bollard(k: MeshKit, p: Vector3, t: int) -> void:
	var c: Color = ArchKit.c(t, "dark") if t != 2 else Color(0.9, 0.91, 0.92)
	cy(k, 0.04, 0.32, c, p, 6)
	cy(k, 0.042, 0.05, lit(ArchKit.c(t, "glow"), 0.4), p + Vector3(0, 0.26, 0), 6)


## Edge detail round a wing's flat roof at height y (outside the Growth
## slot patches): coping, corner posts, a vent stack, era touches.
static func _wing_roof(k: MeshKit, t: int, side: float, y: float, sedum := false) -> void:
	var p := ArchKit.pal(t)
	var x0 := minf(side * WX, side * WX1)
	var x1 := maxf(side * WX, side * WX1)
	var cx := (x0 + x1) * 0.5
	var col: Color = p["trim"] if t != 2 else Color(0.86, 0.88, 0.9)
	bb(k, Vector3(x0, y, BK), Vector3(x1, y + 0.07, BK + 0.07), col)
	bb(k, Vector3(x0, y, WF - 0.07), Vector3(x1, y + 0.07, WF), col)
	bb(k, Vector3(x0, y, BK), Vector3(x0 + 0.07, y + 0.07, WF), col)
	bb(k, Vector3(x1 - 0.07, y, BK), Vector3(x1, y + 0.07, WF), col)
	if sedum:
		# a green roof: sedum tufts in a grid (flat enough for gear)
		bb(k, Vector3(x0 + 0.08, y, BK + 0.08), Vector3(x1 - 0.08, y + 0.02, WF - 0.08), Color(0.46, 0.6, 0.34))
		for i in 4:
			for j in 7:
				bx(k, Vector3(0.12, 0.025, 0.1), [Color(0.56, 0.68, 0.38), Color(0.66, 0.6, 0.36), Color(0.42, 0.56, 0.32)][(i + j) % 3], Vector3(x0 + 0.17 + i * 0.16, y + 0.025, BK + 0.16 + j * 0.18), Vector3(0, (i * 3 + j) * 23.0, 0))
	match t:
		3:
			bb(k, Vector3(x0, y + 0.07, WF - 0.02), Vector3(x1, y + 0.09, WF), lit(p["accent2"], 0.4))
			for j in 5:
				bb(k, Vector3(x0 + 0.07, y, BK + 0.3 + j * 0.24 - 0.006), Vector3(x1 - 0.07, y + 0.006, BK + 0.3 + j * 0.24 + 0.006), p["roof"].darkened(0.2))
			cy(k, 0.05, 0.3, p["metal"], Vector3(x1 - 0.12 if side > 0 else x0 + 0.12, y, BK + 0.14), 6)
			k.torus(0.18, 0.015, p["accent"], xf(Vector3(cx, y + 0.5, BK + 0.04), Vector3(90, 0, 0)), 8, 3, PI)
			for sx in [-0.18, 0.18]:
				bb(k, Vector3(cx + sx - 0.015, y, BK + 0.025), Vector3(cx + sx + 0.015, y + 0.5, BK + 0.055), p["accent"])
		4:
			bb(k, Vector3(x0, y + 0.07, WF - 0.02), Vector3(x1, y + 0.085, WF), lit(p["glow"], 0.4))
			bb(k, Vector3(x0, y + 0.07, BK), Vector3(x0 + 0.02, y + 0.085, WF), lit(p["accent2"], 0.45))
			bb(k, Vector3(x1 - 0.02, y + 0.07, BK), Vector3(x1, y + 0.085, WF), lit(p["accent2"], 0.45))
			for q in [Vector2(x0 + 0.035, BK + 0.035), Vector2(x1 - 0.035, BK + 0.035), Vector2(x0 + 0.035, WF - 0.035), Vector2(x1 - 0.035, WF - 0.035)]:
				bb(k, Vector3(q.x - 0.05, y, q.y - 0.05), Vector3(q.x + 0.05, y + 0.16, q.y + 0.05), p["trim"])
			for e in [[Vector3(x0 + 0.03, y + 0.07, BK + 0.03), Vector3(x1 - 0.03, y + 0.07, BK + 0.03)], [Vector3(x0 + 0.03, y + 0.07, BK + 0.03), Vector3(x0 + 0.03, y + 0.07, WF - 0.03)], [Vector3(x1 - 0.03, y + 0.07, BK + 0.03), Vector3(x1 - 0.03, y + 0.07, WF - 0.03)]]:
				ArchKit.railing(k, e[0], e[1], 0.28, p["trim"], 0.35)
			# brass inlay grid and glowing studs across the roof (flat)
			for i in 3:
				bb(k, Vector3(x0 + 0.2 + i * 0.2 - 0.008, y, BK + 0.07), Vector3(x0 + 0.2 + i * 0.2 + 0.008, y + 0.006, WF - 0.07), p["trim"])
			for j in 6:
				bb(k, Vector3(x0 + 0.07, y, BK + 0.25 + j * 0.2 - 0.008), Vector3(x1 - 0.07, y + 0.006, BK + 0.25 + j * 0.2 + 0.008), p["trim"])
			for i in 4:
				bb(k, Vector3(x0 + 0.1 + i * 0.2 - 0.015, y, WF - 0.12), Vector3(x0 + 0.1 + i * 0.2 + 0.015, y + 0.01, WF - 0.09), lit(p["accent2"], 0.4))


static func _accent(kind: String) -> Color:
	match kind:
		"fab": return Color(0.5, 0.9, 0.6)
		"refinery": return Color(0.4, 0.78, 0.98)
		"tune_lab": return Color(0.98, 0.64, 0.32)
		"hbm_works": return Color(0.45, 0.6, 0.95)
		"rlhf_gym": return Color(0.98, 0.8, 0.32)
		"synth_lab": return Color(0.72, 0.46, 0.98)
	return Color(0.5, 0.9, 1.0)


## Shipping-container colour per lab (workshop era).
static func _box_col(kind: String) -> Color:
	match kind:
		"fab": return Color(0.3, 0.52, 0.42)
		"refinery": return Color(0.26, 0.42, 0.62)
		"tune_lab": return Color(0.78, 0.44, 0.24)
		"hbm_works": return Color(0.34, 0.38, 0.56)
		"rlhf_gym": return Color(0.72, 0.3, 0.26)
		"synth_lab": return Color(0.46, 0.34, 0.58)
	return Color(0.6, 0.3, 0.26)


# ---------------------------------------------------------------- benches

## The input/output bench (top at 0.77 m, holders stack on it).
static func bench(t: int) -> Mesh:
	var k := MeshKit.new()
	var p := ArchKit.pal(t)
	match t:
		0:
			# a plywood board on two sawhorses, junk underneath
			bb(k, Vector3(-0.68, 0.72, -0.41), Vector3(0.68, 0.76, 0.41), Color(0.8, 0.66, 0.46))
			bb(k, Vector3(-0.68, 0.715, 0.39), Vector3(0.68, 0.765, 0.42), Color(0.62, 0.48, 0.32))
			for sx in [-0.48, 0.48]:
				bb(k, Vector3(sx - 0.04, 0.64, -0.38), Vector3(sx + 0.04, 0.72, 0.38), Color(0.6, 0.46, 0.3))
				for sz in [-0.3, 0.3]:
					for lx in [-1.0, 1.0]:
						seg(k, Vector3(sx, 0.66, sz), Vector3(sx + lx * 0.13, 0.0, sz * 1.18), 0.045, Color(0.56, 0.42, 0.28))
				seg(k, Vector3(sx - 0.1, 0.25, -0.33), Vector3(sx - 0.1, 0.25, 0.33), 0.03, Color(0.5, 0.38, 0.26))
			crate(k, Vector3(-0.1, 0, 0.0), Vector3(0.36, 0.28, 0.32), 12.0, Color(0.76, 0.62, 0.44))
			cy(k, 0.1, 0.22, Color(0.3, 0.5, 0.74), Vector3(0.22, 0, 0.12), 8, 0.12)
			bx(k, Vector3(0.18, 0.02, 0.14), Color(0.92, 0.9, 0.84), Vector3(0.3, 0.775, -0.2), Vector3(0, 14, 0))
			bx(k, Vector3(0.1, 0.06, 0.06), Color(0.86, 0.3, 0.24), Vector3(-0.52, 0.8, -0.3))
		1:
			# a steel workbench with a pegboard, a toolbox on the shelf
			bb(k, Vector3(-0.7, 0.72, -0.42), Vector3(0.7, 0.77, 0.42), Color(0.56, 0.58, 0.62))
			bb(k, Vector3(-0.7, 0.7, 0.4), Vector3(0.7, 0.77, 0.43), p["accent"])
			for sx in [-0.65, 0.65]:
				for sz in [-0.37, 0.37]:
					bb(k, Vector3(sx - 0.03, 0, sz - 0.03), Vector3(sx + 0.03, 0.72, sz + 0.03), p["dark"])
			bb(k, Vector3(-0.66, 0.16, -0.38), Vector3(0.66, 0.19, 0.38), Color(0.46, 0.48, 0.52))
			bb(k, Vector3(-0.5, 0.19, -0.15), Vector3(-0.1, 0.38, 0.15), Color(0.78, 0.26, 0.22))
			bb(k, Vector3(-0.48, 0.38, -0.02), Vector3(-0.12, 0.41, 0.02), Color(0.2, 0.2, 0.22))
			bb(k, Vector3(0.1, 0.19, -0.2), Vector3(0.5, 0.32, 0.25), Color(0.3, 0.4, 0.62))
			# pegboard
			bb(k, Vector3(-0.66, 0.77, -0.44), Vector3(0.66, 1.25, -0.41), Color(0.72, 0.62, 0.46))
			for i in 6:
				bx(k, Vector3(0.04, 0.16 + (i % 3) * 0.04, 0.02), [Color(0.8, 0.3, 0.25), Color(0.25, 0.3, 0.4), Color(0.9, 0.7, 0.2)][i % 3], Vector3(-0.5 + i * 0.2, 1.05, -0.4), Vector3(0, 0, (i % 2) * 20 - 10))
			stack_light(k, Vector3(0.62, 1.25, -0.43), 0.08)
		2:
			# a white counter with drawers and a teal kick strip
			bb(k, Vector3(-0.68, 0.06, -0.4), Vector3(0.68, 0.72, 0.4), Color(0.94, 0.95, 0.96))
			bb(k, Vector3(-0.66, 0.0, -0.38), Vector3(0.66, 0.08, 0.38), p["trim"])
			bb(k, Vector3(-0.72, 0.72, -0.43), Vector3(0.72, 0.77, 0.43), Color(0.82, 0.84, 0.86))
			for i in 3:
				for j in 2:
					bb(k, Vector3(-0.64 + i * 0.44, 0.14 + j * 0.28, 0.4), Vector3(-0.24 + i * 0.44, 0.38 + j * 0.28, 0.415), Color(0.88, 0.9, 0.92))
					bb(k, Vector3(-0.52 + i * 0.44, 0.33 + j * 0.28, 0.415), Vector3(-0.36 + i * 0.44, 0.35 + j * 0.28, 0.43), p["dark"])
			bb(k, Vector3(-0.72, 0.6, 0.43), Vector3(0.72, 0.63, 0.435), p["trim"])
			bx(k, Vector3(0.03, 0.4, 0.03), Color(0.7, 0.72, 0.75), Vector3(0.62, 0.97, -0.38))
			screen(k, xf(Vector3(0.62, 1.2, -0.36), Vector3(-10, -20, 0)), 0.26, 0.17, p["glow"], 4)
		3:
			# a roller conveyor on a steel frame, guard rails, stack light
			for sz in [-0.42, 0.42]:
				bb(k, Vector3(-0.7, 0.62, sz - 0.03), Vector3(0.7, 0.74, sz + 0.03), p["trim"])
				bb(k, Vector3(-0.7, 0.8, sz - 0.015), Vector3(0.7, 0.83, sz + 0.015), p["accent"])
				for sx in [-0.6, 0.0, 0.6]:
					bb(k, Vector3(sx - 0.02, 0.74, sz - 0.015), Vector3(sx + 0.02, 0.83, sz + 0.015), p["accent"])
			for i in 10:
				hcy(k, 0.032, 0.84, Color(0.72, 0.75, 0.8), Vector3(-0.63 + i * 0.14, 0.725, 0), false, 6)
			for sx in [-0.62, 0.62]:
				for sz in [-0.38, 0.38]:
					bb(k, Vector3(sx - 0.035, 0, sz - 0.035), Vector3(sx + 0.035, 0.62, sz + 0.035), p["dark"])
				seg(k, Vector3(sx, 0.1, -0.38), Vector3(sx, 0.55, 0.38), 0.03, p["trim"])
			bb(k, Vector3(-0.62, 0.2, -0.36), Vector3(0.62, 0.24, 0.36), p["metal"])
			bb(k, Vector3(-0.3, 0.24, -0.25), Vector3(0.1, 0.5, 0.2), Color(0.3, 0.33, 0.38))
			bb(k, Vector3(-0.25, 0.4, 0.2), Vector3(0.05, 0.43, 0.205), lit(p["glow"], 0.4))
			stack_light(k, Vector3(0.66, 0.83, -0.42), 0.35)
			bb(k, Vector3(-0.7, 0.66, 0.44), Vector3(0.7, 0.68, 0.45), lit(p["accent2"], 0.4))
		_:
			# a graphite dock with brass edges and a glowing under-light
			bb(k, Vector3(-0.6, 0.0, -0.34), Vector3(0.6, 0.12, 0.34), p["dark"])
			bb(k, Vector3(-0.62, 0.05, -0.36), Vector3(0.62, 0.07, 0.36), lit(p["accent2"], 0.4))
			bb(k, Vector3(-0.68, 0.12, -0.4), Vector3(0.68, 0.71, 0.4), p["wall"])
			bb(k, Vector3(-0.72, 0.71, -0.43), Vector3(0.72, 0.77, 0.43), p["wall2"])
			for sx in [-1.0, 1.0]:
				bb(k, Vector3(sx * 0.72 - 0.02, 0.71, -0.44), Vector3(sx * 0.72 + 0.02, 0.775, 0.44), p["trim"])
				bb(k, Vector3(sx * 0.69 - 0.025, 0.12, 0.38), Vector3(sx * 0.69 + 0.025, 0.71, 0.42), p["trim"])
			bb(k, Vector3(-0.72, 0.71, 0.42), Vector3(0.72, 0.775, 0.445), p["trim"])
			for i in 5:
				bb(k, Vector3(-0.5 + i * 0.25 - 0.008, 0.2, 0.4), Vector3(-0.5 + i * 0.25 + 0.008, 0.64, 0.41), lit(p["accent2"], 0.45))
			bb(k, Vector3(-0.6, 0.762, -0.43), Vector3(0.6, 0.772, -0.42), lit(p["glow"], 0.4))
	return k.commit()


# ---------------------------------------------------------------- ground

## The lot surface (thin, so Growth parts don't sink into it).
static func _lot(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var fl: Color = p["floor"]
	bb(k, Vector3(-1.9, 0.0, -1.9), Vector3(1.9, 0.03, 1.9), fl)
	match t:
		0:
			# gravel, a plank path, weeds, tyre ruts
			for i in 14:
				var x := -1.7 + fposmod(i * 1.37, 3.4)
				var z := 0.7 + fposmod(i * 0.61, 1.1)
				bx(k, Vector3(0.24 + (i % 3) * 0.08, 0.012, 0.16), fl.darkened(0.08 + (i % 2) * 0.06), Vector3(x, 0.034, z), Vector3(0, i * 41.0, 0))
			for i in 5:
				bx(k, Vector3(0.6, 0.03, 0.2), Color(0.66, 0.52, 0.36).darkened((i % 2) * 0.08), Vector3(0.02 * (i % 2), 0.045, 1.75 - i * 0.24), Vector3(0, (i % 3) * 3.0 - 3.0, 0))
			for i in 6:
				var wx: float = [-1.78, 1.78, -1.2, 1.25, -0.6, 0.7][i]
				var wz: float = [0.3, -0.2, 1.8, 1.8, 0.62, 0.66][i]
				for j in 3:
					bx(k, Vector3(0.025, 0.1 + j * 0.03, 0.025), Color(0.44, 0.56, 0.3), Vector3(wx + j * 0.03 - 0.03, 0.08, wz), Vector3(0, 0, (j - 1) * 20.0))
		1:
			# concrete with joints, a drain, an oil stain, yellow kerb line
			for i in 3:
				bb(k, Vector3(-1.9, 0.03, -1.3 + i * 1.2), Vector3(1.9, 0.034, -1.28 + i * 1.2), fl.darkened(0.15))
			bb(k, Vector3(-0.01, 0.03, -1.9), Vector3(0.01, 0.034, 1.9), fl.darkened(0.15))
			bb(k, Vector3(-1.9, 0.03, 1.8), Vector3(1.9, 0.05, 1.88), p["accent"])
			bx(k, Vector3(0.5, 0.008, 0.36), fl.darkened(0.25), Vector3(-0.7, 0.034, 1.2), Vector3(0, 20, 0))
			bb(k, Vector3(0.6, 0.03, 0.95), Vector3(0.9, 0.04, 1.05), Color(0.3, 0.31, 0.33))
			for i in 5:
				bb(k, Vector3(0.62 + i * 0.06, 0.04, 0.96), Vector3(0.64 + i * 0.06, 0.042, 1.04), Color(0.5, 0.52, 0.55))
			for sx in [-0.5, 0.5]:
				bb(k, Vector3(sx - 0.03, 0.03, 0.7), Vector3(sx + 0.03, 0.036, 1.7), p["accent"])
		2:
			# pavers, a kerb, grass strips with stepping stones
			bb(k, Vector3(-1.9, 0.03, 1.74), Vector3(1.9, 0.08, 1.9), Color(0.9, 0.9, 0.9))
			for i in 7:
				for j in 4:
					if (i + j) % 2 == 0:
						bb(k, Vector3(-1.25 + i * 0.36, 0.03, 0.72 + j * 0.25), Vector3(-0.93 + i * 0.36, 0.036, 0.94 + j * 0.25), fl.darkened(0.06))
			for sx in [-1.0, 1.0]:
				bb(k, Vector3(sx * 1.9, 0.03, -0.3), Vector3(sx * 1.4, 0.05, 1.74), Color(0.5, 0.64, 0.4))
			bb(k, Vector3(-1.9, 0.03, -0.42), Vector3(1.9, 0.045, -0.3), Color(0.74, 0.76, 0.78))
		3:
			# steel-edged slab, yellow walkways, a hatched loading box
			bb(k, Vector3(-1.9, 0.03, 1.8), Vector3(1.9, 0.07, 1.9), Color(0.3, 0.32, 0.36))
			for sx in [-0.42, 0.42]:
				bb(k, Vector3(sx - 0.03, 0.03, 0.66), Vector3(sx + 0.03, 0.036, 1.8), p["accent"])
			for i in 6:
				bx(k, Vector3(0.05, 0.006, 0.42), p["accent"], Vector3(-0.3 + i * 0.12, 0.034, 1.3), Vector3(0, 40, 0))
			bb(k, Vector3(-0.38, 0.03, 1.05), Vector3(0.38, 0.036, 1.08), p["accent"])
			bb(k, Vector3(-0.38, 0.03, 1.52), Vector3(0.38, 0.036, 1.55), p["accent"])
			for i in 8:
				bb(k, Vector3(-1.9 + i * 0.5, 0.03, -1.9), Vector3(-1.88 + i * 0.5, 0.034, 1.8), fl.darkened(0.1))
		_:
			# dark tiles with glowing seams and a brass edge
			for i in range(1, 8):
				bb(k, Vector3(-1.9 + i * 0.475 - 0.008, 0.03, 0.62), Vector3(-1.9 + i * 0.475 + 0.008, 0.036, 1.9), lit(p["accent2"], 0.55))
			for j in 3:
				bb(k, Vector3(-1.9, 0.03, 0.9 + j * 0.42 - 0.008), Vector3(1.9, 0.036, 0.9 + j * 0.42 + 0.008), lit(p["accent2"], 0.55))
			bb(k, Vector3(-1.9, 0.03, 1.84), Vector3(1.9, 0.07, 1.9), p["trim"])
			bb(k, Vector3(-1.9, 0.03, 0.6), Vector3(1.9, 0.045, 0.64), p["trim"])
			bb(k, Vector3(-0.3, 0.03, 0.66), Vector3(0.3, 0.04, 1.8), p["wall2"])


# ---------------------------------------------------------------- wings

## A side wing (side -1 left, +1 right) in the given era style: x from WX to
## WX1, z from BK to WF, with a flat roof under the Growth roof slots.
static func _wing(k: MeshKit, kind: String, t: int, side: float, style: String, h := 0.0) -> void:
	var p := ArchKit.pal(t)
	var cx := side * (WX + WX1) * 0.5
	var w := WX1 - WX
	var d := WF - BK
	var cz := (WF + BK) * 0.5
	var xi := side * WX           # inner x
	var xo := side * WX1          # outer x
	var ac := _accent(kind)
	var face_front := at(cx, 0, WF)
	var face_out := xf(Vector3(xo, 0, cz), Vector3(0, 90 * side, 0))
	var face_in := xf(Vector3(xi, 0, cz), Vector3(0, -90 * side, 0))
	match style:
		"shed":
			# plywood lean-to: posts, plank walls, a tin roof, a door
			h = h if h > 0.0 else 1.8
			var wood := Color(0.78, 0.64, 0.46)
			for q in [Vector2(xi, BK + 0.04), Vector2(xo, BK + 0.04), Vector2(xi, WF), Vector2(xo, WF)]:
				bb(k, Vector3(q.x - 0.04, 0, q.y - 0.04), Vector3(q.x + 0.04, h + 0.2, q.y + 0.04), Color(0.5, 0.36, 0.24))
			ArchKit.planks(k, face_front, w - 0.08, h, wood)
			ArchKit.planks(k, face_out, d - 0.08, h, wood.darkened(0.05))
			ArchKit.planks(k, face_in, d - 0.08, h, wood.darkened(0.08))
			ArchKit.planks(k, xf(Vector3(cx, 0, BK + 0.045), Vector3(0, 180, 0)), w - 0.08, h, wood.darkened(0.1))
			door(k, at(cx - side * 0.12, 0, WF + 0.02), 0, 0.4, 1.4)
			# a little window on the outer face
			k.box(Vector3(0.46, 0.36, 0.04), Color(0.36, 0.25, 0.18), face_out * at(0.25, 1.15, 0.04))
			k.box(Vector3(0.38, 0.28, 0.03), p["glass"], face_out * at(0.25, 1.15, 0.055))
			k.box(Vector3(0.03, 0.28, 0.03), Color(0.36, 0.25, 0.18), face_out * at(0.25, 1.15, 0.065))
			# tin roof sloping to the front, ribs, a gutter
			var ry := h + 0.18
			var roof := xf(Vector3(cx, ry, cz + 0.04), Vector3(6, 0, 0))
			k.box(Vector3(w + 0.16, 0.03, d + 0.1), Color(0.62, 0.64, 0.66), roof)
			for i in 7:
				k.box(Vector3(0.025, 0.025, d + 0.1), Color(0.52, 0.54, 0.56), roof * at(-w * 0.5 - 0.03 + (i + 0.5) * (w + 0.1) / 7.0, 0.025, 0))
			bb(k, Vector3(cx - w * 0.5 - 0.08, ry - 0.16, WF + 0.06), Vector3(cx + w * 0.5 + 0.08, ry - 0.08, WF + 0.12), Color(0.55, 0.57, 0.6))
			bb(k, Vector3(xo - side * 0.06 - 0.025, 0, WF + 0.07), Vector3(xo - side * 0.06 + 0.025, ry - 0.1, WF + 0.12), Color(0.55, 0.57, 0.6))
			# a hand-painted sign
			k.box(Vector3(0.5, 0.16, 0.03), Color(0.94, 0.92, 0.86), xf(Vector3(cx + side * 0.18, h - 0.1, WF + 0.05), Vector3(0, 0, 3)))
			k.box(Vector3(0.12, 0.1, 0.01), ac, xf(Vector3(cx + side * 0.03, h - 0.1, WF + 0.07), Vector3(0, 0, 3)))
			# a lamp over the door
			bx(k, Vector3(0.1, 0.06, 0.1), lit(p["glow"], 0.3), Vector3(cx - side * 0.12, 1.58, WF + 0.08))
		"pile":
			# a tarp-covered stack of crates on pallets, roped down
			h = h if h > 0.0 else 1.2
			pallet(k, Vector3(cx, 0, -1.55), 0.82, 0.62)
			pallet(k, Vector3(cx, 0, -0.85), 0.82, 0.62)
			var cc := [Color(0.76, 0.6, 0.4), Color(0.7, 0.54, 0.36), Color(0.36, 0.5, 0.36), Color(0.78, 0.64, 0.44)]
			for i in 2:
				for j in 2:
					crate(k, Vector3(cx - 0.2 + i * 0.4, 0.09, -1.62 + j * 0.42), Vector3(0.38, 0.5, 0.38), (i * 2 + j) * 4.0 - 6.0, cc[(i + j) % 4])
					crate(k, Vector3(cx - 0.2 + i * 0.4, 0.09, -0.98 + j * 0.42 * 0.8), Vector3(0.38, 0.5, 0.32), 0.0, cc[(i + j + 1) % 4])
			# the tarp: flat top, flaps hanging down the sides
			var tc := Color(0.26, 0.46, 0.78)
			bb(k, Vector3(cx - 0.45, h, -1.85), Vector3(cx + 0.45, h + 0.04, -0.5), tc)
			k.box(Vector3(0.03, 0.55, 1.35), tc.darkened(0.08), xf(Vector3(xo - side * 0.02, h - 0.25, cz), Vector3(0, 0, side * 6)))
			k.box(Vector3(0.9, 0.5, 0.03), tc.darkened(0.12), xf(Vector3(cx, h - 0.23, WF - 0.02), Vector3(-6, 0, 0)))
			k.box(Vector3(0.9, 0.45, 0.03), tc.darkened(0.1), xf(Vector3(cx, h - 0.22, BK + 0.02), Vector3(6, 0, 0)))
			for z in [-1.6, -1.15, -0.72]:
				bb(k, Vector3(cx - 0.47, h + 0.04, z - 0.01), Vector3(cx + 0.47, h + 0.055, z + 0.01), Color(0.86, 0.8, 0.6))
			for q in [Vector2(cx - 0.4, -1.8), Vector2(cx + 0.4, -1.8), Vector2(cx - 0.4, -0.55), Vector2(cx + 0.4, -0.55)]:
				bb(k, Vector3(q.x - 0.06, h + 0.04, q.y - 0.04), Vector3(q.x + 0.06, h + 0.1, q.y + 0.04), Color(0.66, 0.36, 0.28))
			# jerry cans by the inner side
			for i in 2:
				bb(k, Vector3(xi + side * 0.02 - 0.08, 0, -0.62 - i * 0.22 - 0.08), Vector3(xi + side * 0.02 + 0.08, 0.3, -0.62 - i * 0.22 + 0.08), [Color(0.8, 0.26, 0.22), Color(0.3, 0.5, 0.3)][i])
		"container":
			# a shipping container on sleepers, doors to the front
			h = h if h > 0.0 else 1.25
			var col := _box_col(kind)
			var hw := w * 0.5 - 0.02
			for z in [-1.7, -0.62]:
				bb(k, Vector3(cx - hw - 0.02, 0, z - 0.06), Vector3(cx + hw + 0.02, 0.08, z + 0.06), Color(0.42, 0.32, 0.22))
			bb(k, Vector3(cx - hw, 0.08, BK + 0.02), Vector3(cx + hw, h, WF - 0.02), col)
			ArchKit.corrugated(k, face_out * at(0, 0.1, -0.02), d - 0.12, h - 0.14, col, 0.12)
			ArchKit.corrugated(k, face_in * at(0, 0.1, -0.02), d - 0.12, h - 0.14, col, 0.12)
			for sx in [-1.0, 1.0]:
				for sz in [BK + 0.06, WF - 0.06]:
					for sy in [0.12, h - 0.04]:
						bb(k, Vector3(cx + sx * hw - 0.05, sy - 0.04, sz - 0.05), Vector3(cx + sx * hw + 0.05, sy + 0.04, sz + 0.05), col.darkened(0.35))
			# doors: two leaves, locking bars, handles, a stencil
			for i in 2:
				var dx := cx - hw * 0.5 + i * hw
				bb(k, Vector3(dx - hw * 0.48, 0.12, WF - 0.02), Vector3(dx + hw * 0.48, h - 0.06, WF + 0.01), col.lightened(0.05))
				for b in 2:
					var bxx := dx - hw * 0.22 + b * hw * 0.44
					bb(k, Vector3(bxx - 0.012, 0.14, WF + 0.01), Vector3(bxx + 0.012, h - 0.08, WF + 0.035), Color(0.5, 0.52, 0.55))
					bb(k, Vector3(bxx - 0.03, 0.55, WF + 0.02), Vector3(bxx + 0.03, 0.6, WF + 0.06), Color(0.5, 0.52, 0.55))
			bb(k, Vector3(cx - 0.005, 0.12, WF + 0.005), Vector3(cx + 0.005, h - 0.06, WF + 0.02), col.darkened(0.4))
			bb(k, Vector3(cx - hw * 0.8, h - 0.3, WF + 0.012), Vector3(cx - hw * 0.2, h - 0.22, WF + 0.02), Color(0.94, 0.94, 0.92))
			# roof ribs across
			for i in 6:
				bb(k, Vector3(cx - hw, h, BK + 0.12 + i * 0.26), Vector3(cx + hw, h + 0.02, BK + 0.2 + i * 0.26), col.darkened(0.12))
			# a vent and a wall lamp on the outer side
			ArchKit.louvres(k, face_out * at(-0.45, 0.5, -0.01), 0.22, 0.2, col.darkened(0.15), 4)
			bx(k, Vector3(0.08, 0.06, 0.12), lit(p["glow"], 0.3), Vector3(cx + side * 0.35, h - 0.15, WF + 0.06))
		"shed_steel":
			# a prefab steel shed: cladding, a roll-up door, a wall AC, conduit
			h = h if h > 0.0 else 1.9
			var wc: Color = p["wall"]
			bb(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, h, WF), wc)
			ArchKit.corrugated(k, face_out * at(0, 0.05, 0.0), d - 0.04, h - 0.1, p["wall2"], 0.14)
			ArchKit.corrugated(k, face_in * at(0, 0.05, 0.0), d - 0.04, h - 0.1, p["wall2"], 0.14)
			ArchKit.rollup(k, at(cx + side * 0.06, 0, WF), 0.56, 1.3, ac.lerp(Color(0.8, 0.82, 0.84), 0.55))
			bb(k, Vector3(cx - w * 0.5 - 0.05, h, BK), Vector3(cx + w * 0.5 + 0.05, h + 0.1, WF + 0.05), p["trim"])
			bb(k, Vector3(cx - w * 0.5 + 0.03, h + 0.1, BK + 0.03), Vector3(cx + w * 0.5 - 0.03, h + 0.12, WF - 0.03), p["roof"])
			# a wall-mounted AC on the outer face, a breaker box and conduit
			k.box(Vector3(0.5, 0.36, 0.08), Color(0.88, 0.89, 0.9), face_out * at(-0.2, 1.25, 0.04))
			k.cyl(0.12, 0.02, Color(0.24, 0.25, 0.28), face_out * xf(Vector3(-0.28, 1.25, 0.06), Vector3(90, 0, 0)), 8)
			k.box(Vector3(0.2, 0.26, 0.08), Color(0.6, 0.62, 0.66), face_out * at(0.35, 1.0, 0.04))
			k.box(Vector3(0.03, 0.9, 0.03), Color(0.5, 0.52, 0.55), face_out * at(0.35, 1.55, 0.04))
			bb(k, Vector3(cx - side * 0.32 - 0.12, h - 0.35, WF), Vector3(cx - side * 0.32 + 0.12, h - 0.15, WF + 0.03), p["glass"])
			bx(k, Vector3(0.12, 0.06, 0.1), lit(p["glow"], 0.3), Vector3(cx + side * 0.06, 1.62, WF + 0.12))
			bx(k, Vector3(0.6, 0.14, 0.02), p["accent"], Vector3(cx + side * 0.06, 1.85 if h > 2.0 else h - 0.12, WF + 0.015))
		"office":
			# white two-storey block: curtain glass front, teal band, parapet
			h = h if h > 0.0 else 2.9
			ArchKit.block(k, Vector3(cx, 0, cz), Vector3(w, h, d), t, "", 2)
			ArchKit.curtain(k, at(cx, h * 0.5 + 0.1, WF + 0.01), w - 0.2, h * 0.5 - 0.4, t, 3, 2)
			door(k, at(cx - side * 0.1, 0, WF), t, 0.45, 1.15)
			bb(k, Vector3(cx - w * 0.5, h * 0.5 - 0.06, WF), Vector3(cx + w * 0.5, h * 0.5 + 0.06, WF + 0.05), p["trim"])
			ArchKit.window_row(k, face_out * at(0, h * 0.75, 0), d - 0.4, 0.5, t)
			ArchKit.window_row(k, face_out * at(0, h * 0.27, 0), d - 0.4, 0.5, t)
			ArchKit.window_row(k, face_in * at(0, h * 0.75, 0), d - 0.4, 0.5, t)
			bb(k, Vector3(cx - w * 0.5 + 0.05, 0, WF), Vector3(cx + w * 0.5 - 0.05, 0.14, WF + 0.14), Color(0.86, 0.88, 0.9))
			for i in 3:
				ArchKit.planter(k, Vector3(cx - 0.3 + i * 0.3, 0, WF + 0.07), t, 0.22)
		"plant":
			# white plant room: louvres, a steel door, teal stripe, pipes
			h = h if h > 0.0 else 2.2
			ArchKit.block(k, Vector3(cx, 0, cz), Vector3(w, h, d), t, "", 1)
			ArchKit.louvres(k, at(cx + side * 0.15, 0.9, WF), 0.45, 0.8, Color(0.82, 0.84, 0.86), 7)
			door(k, at(cx - side * 0.24, 0, WF), 1, 0.28, 1.2)
			bb(k, Vector3(cx - w * 0.5, h - 0.4, WF), Vector3(cx + w * 0.5, h - 0.3, WF + 0.03), p["trim"])
			ArchKit.louvres(k, face_out * at(0.3, 0.8, 0), 0.6, 0.7, Color(0.82, 0.84, 0.86), 6)
			run(k, [Vector3(xo + side * 0.06, 0.2, -1.7), Vector3(xo + side * 0.06, h - 0.5, -1.7), Vector3(xo + side * 0.06, h - 0.5, -0.7)], 0.035, ac.lerp(Color.WHITE, 0.3))
			bx(k, Vector3(0.24, 0.24, 0.02), ac, Vector3(cx + side * 0.15, h - 0.65, WF + 0.02))
		"annex":
			# steel-and-glass annex: curtain front, louvre band, LED strip, ladder
			h = h if h > 0.0 else 3.0
			ArchKit.block(k, Vector3(cx, 0, cz), Vector3(w, h, d), t, "", 2)
			ArchKit.curtain(k, at(cx, 0.15, WF + 0.01), w - 0.16, h * 0.5 - 0.25, t, 3, 2)
			ArchKit.louvres(k, at(cx, h * 0.55, WF + 0.01), w - 0.2, h * 0.3, p["metal"], 6)
			bb(k, Vector3(cx - w * 0.5, h - 0.12, WF + 0.03), Vector3(cx + w * 0.5, h - 0.09, WF + 0.06), lit(p["accent2"], 0.4))
			ArchKit.louvres(k, face_out * at(0.35, 0.4, 0), 0.45, 0.9, p["metal"], 8)
		"canopy":
			# a steel deck on columns sheltering two tanks in a bund
			h = h if h > 0.0 else 2.6
			bb(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, 0.18, WF), Color(0.56, 0.58, 0.6))
			bb(k, Vector3(cx - w * 0.5 + 0.06, 0.18, BK + 0.06), Vector3(cx + w * 0.5 - 0.06, 0.2, WF - 0.06), Color(0.3, 0.32, 0.36))
			for q in [Vector2(xi, BK + 0.04), Vector2(xo, BK + 0.04), Vector2(xi, WF - 0.04), Vector2(xo, WF - 0.04), Vector2(xo, cz)]:
				bb(k, Vector3(q.x - 0.05, 0, q.y - 0.05), Vector3(q.x + 0.05, h, q.y + 0.05), p["trim"])
			for z in [BK + 0.04, WF - 0.04]:
				seg(k, Vector3(xi, 0.2, z), Vector3(xo, h - 0.1, z), 0.04, p["trim"])
			bb(k, Vector3(cx - w * 0.5 - 0.04, h, BK - 0.02), Vector3(cx + w * 0.5 + 0.04, h + 0.12, WF + 0.02), p["trim"])
			bb(k, Vector3(cx - w * 0.5, h + 0.12, BK), Vector3(cx + w * 0.5, h + 0.14, WF), p["roof"])
			for z in [-1.45, -0.85]:
				ArchKit.tank(k, at(cx, 0.2, z), 0.24, h - 0.75, Color(0.86, 0.88, 0.9) if kind != "synth_lab" else ac.lerp(Color.WHITE, 0.4), t)
				run(k, [Vector3(cx, 0.6, z + 0.24), Vector3(cx, 0.6, WF + 0.08), Vector3(xi, 0.6, WF + 0.08)], 0.03, Color(0.86, 0.6, 0.3))
			bx(k, Vector3(0.3, 0.2, 0.02), Color(0.98, 0.84, 0.3), Vector3(cx, 0.45, WF + 0.02))
			bb(k, Vector3(cx - w * 0.5, h - 0.1, WF + 0.02), Vector3(cx + w * 0.5, h - 0.07, WF + 0.05), lit(p["accent2"], 0.4))
		"stair":
			# an open steel stair tower with landings and a deck on top
			h = h if h > 0.0 else 3.0
			for q in [Vector2(xi, BK + 0.04), Vector2(xo, BK + 0.04), Vector2(xi, WF - 0.04), Vector2(xo, WF - 0.04)]:
				bb(k, Vector3(q.x - 0.05, 0, q.y - 0.05), Vector3(q.x + 0.05, h, q.y + 0.05), p["trim"])
			var fl := 3
			for f in fl:
				var y0 := h * f / fl
				var y1 := h * (f + 1) / fl
				var flip := f % 2 == 0
				var z0 := WF - 0.15 if flip else BK + 0.15
				var z1 := BK + 0.35 if flip else WF - 0.35
				var n := 6
				for i in n:
					var fz := lerpf(z0, z1, (i + 0.5) / n)
					bb(k, Vector3(cx - 0.34, y0 + (i + 1) * (y1 - y0) / (n + 1) - 0.02, fz - 0.08), Vector3(cx + 0.34, y0 + (i + 1) * (y1 - y0) / (n + 1) + 0.02, fz + 0.08), p["metal"])
				seg(k, Vector3(cx + 0.36, y0, z0), Vector3(cx + 0.36, y1 - (y1 - y0) / (n + 1), z1), 0.05, p["trim"])
				seg(k, Vector3(cx - 0.36, y0, z0), Vector3(cx - 0.36, y1 - (y1 - y0) / (n + 1), z1), 0.05, p["trim"])
				seg(k, Vector3(cx + 0.36, y0 + 0.8, z0), Vector3(cx + 0.36, y1 + 0.8 - (y1 - y0) / (n + 1), z1), 0.035, p["accent"])
				if f < fl - 1:
					var lz := BK + 0.18 if flip else WF - 0.18
					bb(k, Vector3(cx - w * 0.5, y1 - 0.04, lz - 0.17), Vector3(cx + w * 0.5, y1, lz + 0.17), p["metal"].darkened(0.15))
			for z in [BK + 0.04, WF - 0.04]:
				for f in fl:
					seg(k, Vector3(xo, h * f / fl, z), Vector3(xo, h * (f + 1) / fl, z + (0.5 if z < cz else -0.5)), 0.03, p["trim"])
			bb(k, Vector3(cx - w * 0.5 - 0.03, h, BK - 0.02), Vector3(cx + w * 0.5 + 0.03, h + 0.1, WF + 0.02), p["trim"])
			bb(k, Vector3(cx - w * 0.5, h + 0.1, BK), Vector3(cx + w * 0.5, h + 0.12, WF), p["metal"].darkened(0.2))
			ArchKit.railing(k, Vector3(xo - side * 0.03, h + 0.1, BK + 0.05), Vector3(xo - side * 0.03, h + 0.1, WF - 0.05), 0.5, p["accent"])
			bb(k, Vector3(cx - w * 0.5, h - 0.04, WF - 0.01), Vector3(cx + w * 0.5, h - 0.01, WF + 0.02), lit(p["accent2"], 0.4))
		"lean":
			# an open-front lean-to with shelves of junk and a ladder
			h = h if h > 0.0 else 1.7
			var wood := Color(0.74, 0.6, 0.42)
			for q in [Vector2(xi, BK + 0.04), Vector2(xo, BK + 0.04), Vector2(xi, WF), Vector2(xo, WF)]:
				bb(k, Vector3(q.x - 0.04, 0, q.y - 0.04), Vector3(q.x + 0.04, h + 0.15, q.y + 0.04), Color(0.5, 0.36, 0.24))
			ArchKit.planks(k, face_out * at(0, 0, -0.03), d - 0.08, h, wood.darkened(0.05))
			ArchKit.planks(k, xf(Vector3(cx, 0, BK + 0.045), Vector3(0, 180, 0)), w - 0.08, h, wood.darkened(0.1))
			ArchKit.planks(k, at(cx, 0, BK + 0.06), w - 0.1, h, wood.darkened(0.02))
			for s in 3:
				var sy := 0.35 + s * 0.45
				bb(k, Vector3(cx - w * 0.5 + 0.06, sy, BK + 0.08), Vector3(cx + w * 0.5 - 0.06, sy + 0.03, BK + 0.36), Color(0.62, 0.48, 0.32))
				bb(k, Vector3(xo - side * 0.06 - 0.02, sy, -1.7), Vector3(xo - side * 0.06 + 0.02, sy + 0.03, -0.6), Color(0.62, 0.48, 0.32))
				for i in 4:
					var cc: Color = [Color(0.86, 0.3, 0.24), Color(0.3, 0.5, 0.8), Color(0.92, 0.9, 0.84), Color(0.4, 0.6, 0.36)][(i + s) % 4]
					if (i + s) % 3 == 0:
						cy(k, 0.06, 0.14, cc, Vector3(cx - 0.3 + i * 0.2, sy + 0.03, BK + 0.22), 8)
					else:
						bb(k, Vector3(cx - 0.38 + i * 0.2, sy + 0.03, BK + 0.12), Vector3(cx - 0.24 + i * 0.2, sy + 0.17, BK + 0.32), cc)
			# a ladder leaning on the side wall, a broom, paint tins
			seg(k, Vector3(xi + side * 0.15, 0, -0.62), Vector3(xi + side * 0.15, 1.5, -0.9), 0.03, Color(0.86, 0.72, 0.4))
			seg(k, Vector3(xi + side * 0.4, 0, -0.62), Vector3(xi + side * 0.4, 1.5, -0.9), 0.03, Color(0.86, 0.72, 0.4))
			for i in 5:
				var f := (i + 0.5) / 5.0
				seg(k, Vector3(xi + side * 0.15, f * 1.5, -0.62 - f * 0.28), Vector3(xi + side * 0.4, f * 1.5, -0.62 - f * 0.28), 0.025, Color(0.86, 0.72, 0.4))
			seg(k, Vector3(xo - side * 0.12, 0, -0.55), Vector3(xo - side * 0.18, 1.2, -0.6), 0.025, Color(0.6, 0.46, 0.3))
			bx(k, Vector3(0.18, 0.06, 0.06), Color(0.9, 0.7, 0.2), Vector3(xo - side * 0.12, 0.05, -0.55))
			for i in 3:
				cy(k, 0.07, 0.14, [Color(0.86, 0.3, 0.24), Color(0.3, 0.5, 0.8), Color(0.92, 0.9, 0.84)][i], Vector3(cx - 0.25 + i * 0.17, 0, -0.6), 8)
			# a tin roof
			var roof := xf(Vector3(cx, h + 0.15, cz + 0.03), Vector3(5, 0, 0))
			k.box(Vector3(w + 0.14, 0.03, d + 0.08), Color(0.6, 0.62, 0.64), roof)
			for i in 7:
				k.box(Vector3(0.025, 0.025, d + 0.08), Color(0.5, 0.52, 0.54), roof * at(-w * 0.5 - 0.02 + (i + 0.5) * (w + 0.08) / 7.0, 0.025, 0))
			bb(k, Vector3(cx - w * 0.5 - 0.06, h + 0.0, WF + 0.04), Vector3(cx + w * 0.5 + 0.06, h + 0.06, WF + 0.1), Color(0.5, 0.36, 0.24))
			bx(k, Vector3(0.1, 0.07, 0.1), lit(p["glow"], 0.3), Vector3(cx, h - 0.05, WF + 0.02))
		"cage":
			# a chain-link store under a flat steel roof, shelving inside
			h = h if h > 0.0 else 1.9
			bb(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, 0.06, WF), Color(0.6, 0.6, 0.6))
			mesh_fence(k, Vector3(xi, 0.06, WF - 0.02), Vector3(xo, 0.06, WF - 0.02), h - 0.1)
			mesh_fence(k, Vector3(xi, 0.06, WF - 0.02), Vector3(xi, 0.06, BK + 0.02), h - 0.1)
			mesh_fence(k, Vector3(xo, 0.06, WF - 0.02), Vector3(xo, 0.06, BK + 0.02), h - 0.1)
			bb(k, Vector3(cx - w * 0.5, 0.06, BK), Vector3(cx + w * 0.5, h, BK + 0.04), p["wall2"])
			for q in [Vector2(xi, BK + 0.03), Vector2(xo, BK + 0.03), Vector2(xi, WF - 0.03), Vector2(xo, WF - 0.03)]:
				bb(k, Vector3(q.x - 0.04, 0, q.y - 0.04), Vector3(q.x + 0.04, h, q.y + 0.04), p["trim"])
			bb(k, Vector3(cx - w * 0.5 - 0.05, h, BK), Vector3(cx + w * 0.5 + 0.05, h + 0.08, WF + 0.08), p["trim"])
			bb(k, Vector3(cx - w * 0.5, h + 0.08, BK), Vector3(cx + w * 0.5, h + 0.1, WF), p["roof"])
			bb(k, Vector3(cx - w * 0.5 - 0.05, h - 0.06, WF + 0.06), Vector3(cx + w * 0.5 + 0.05, h, WF + 0.08), p["accent"])
			for s in 3:
				var sy := 0.3 + s * 0.5
				bb(k, Vector3(cx - 0.35, sy, BK + 0.1), Vector3(cx + 0.35, sy + 0.03, BK + 0.45), p["accent2"])
				for i in 3:
					bb(k, Vector3(cx - 0.32 + i * 0.22, sy + 0.03, BK + 0.14), Vector3(cx - 0.14 + i * 0.22, sy + 0.2, BK + 0.42), [Color(0.72, 0.58, 0.4), Color(0.3, 0.5, 0.8), Color(0.86, 0.86, 0.84)][(i + s) % 3])
			for sx in [-0.3, 0.3]:
				bb(k, Vector3(cx + sx - 0.02, 0, BK + 0.1), Vector3(cx + sx + 0.02, h - 0.2, BK + 0.14), p["accent2"])
			for i in 3:
				gas_bottle(k, Vector3(cx - 0.2 + i * 0.18, 0.06, -0.75), [Color(0.3, 0.5, 0.8), Color(0.86, 0.86, 0.84), Color(0.3, 0.6, 0.4)][i], 0.9, 0.07)
			bb(k, Vector3(cx - 0.35, 0.65, -0.68), Vector3(cx + 0.35, 0.68, -0.66), p["accent"])
			bx(k, Vector3(0.08, 0.1, 0.04), Color(0.86, 0.7, 0.2), Vector3(cx, 0.9, WF + 0.01))
			bx(k, Vector3(0.36, 0.22, 0.02), Color(0.98, 0.84, 0.3), Vector3(cx, 1.3, WF + 0.02))
		"glass":
			# a glass pavilion with a white roof slab, teal fascia, sun fins
			h = h if h > 0.0 else 2.5
			bb(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, 0.14, WF), Color(0.86, 0.88, 0.9))
			bb(k, Vector3(cx - w * 0.5 + 0.03, 0.14, BK + 0.03), Vector3(cx + w * 0.5 - 0.03, h - 0.1, WF - 0.03), p["glass"])
			ArchKit.curtain(k, at(cx, 0.14, WF - 0.02), w - 0.06, h - 0.25, t, 2, 2)
			ArchKit.curtain(k, face_out * at(0, 0.14, -0.02), d - 0.06, h - 0.25, t, 3, 2)
			ArchKit.curtain(k, face_in * at(0, 0.14, -0.02), d - 0.06, h - 0.25, t, 3, 2)
			bb(k, Vector3(cx - w * 0.5 - 0.06, h - 0.12, BK), Vector3(cx + w * 0.5 + 0.06, h + 0.04, WF + 0.1), Color(0.97, 0.97, 0.98))
			bb(k, Vector3(cx - w * 0.5 - 0.07, h - 0.06, WF + 0.1), Vector3(cx + w * 0.5 + 0.07, h - 0.0, WF + 0.12), p["trim"])
			bb(k, Vector3(cx - w * 0.5 + 0.05, h + 0.04, BK + 0.05), Vector3(cx + w * 0.5 - 0.05, h + 0.06, WF - 0.05), Color(0.5, 0.64, 0.4))
			for i in 5:
				k.box(Vector3(0.1, h - 0.3, 0.03), Color(0.95, 0.95, 0.96), face_out * xf(Vector3(-d * 0.4 + i * d * 0.2, h * 0.5, 0.05), Vector3(0, 35, 0)))
			bb(k, Vector3(cx - 0.25, 0.14, -1.3), Vector3(cx + 0.25, 0.5, -0.9), Color(0.95, 0.95, 0.96))
			ArchKit.planter(k, Vector3(cx, 0, WF + 0.08), t, 0.5)
		"fin":
			# a slim graphite tower wrapped in glowing fins, brass cap
			h = h if h > 0.0 else 3.4
			bb(k, Vector3(cx - w * 0.5 + 0.02, 0, BK + 0.02), Vector3(cx + w * 0.5 - 0.02, h, WF - 0.05), p["wall"])
			bb(k, Vector3(cx - w * 0.5 + 0.02, 0, BK), Vector3(cx + w * 0.5, 0.2, WF - 0.02), p["dark"])
			bb(k, Vector3(cx - w * 0.5 + 0.04, 0.2, WF - 0.04), Vector3(cx + w * 0.5 - 0.02, 0.23, WF - 0.02), lit(ac, 0.45))
			fins(k, at(cx, 0.35, WF - 0.05), w - 0.12, h - 0.6, 4, 0.12, 4, ac)
			for i in 6:
				k.box(Vector3(0.07, h - 0.3, 0.06), p["wall2"], face_out * at(-d * 0.42 + i * d * 0.168, h * 0.5, 0.01))
				k.box(Vector3(0.02, h - 0.5, 0.02), lit(ac.lerp(Color.WHITE, 0.3), 0.4), face_out * at(-d * 0.42 + i * d * 0.168, h * 0.5, 0.05))
			for y in [h * 0.4, h * 0.7]:
				bb(k, Vector3(cx - w * 0.5 + 0.03, y, BK), Vector3(cx + w * 0.5, y + 0.05, WF - 0.03), p["trim"])
			bb(k, Vector3(cx - w * 0.5 + 0.02, h - 0.12, BK), Vector3(cx + w * 0.5 + 0.0, h, WF - 0.03), p["trim"])
			bb(k, Vector3(cx - w * 0.5 + 0.08, h, BK + 0.05), Vector3(cx + w * 0.5 - 0.05, h + 0.02, WF - 0.08), p["roof"])
		"podium":
			# graphite block, brass trim, glowing fins, a coolant run
			h = h if h > 0.0 else 2.2
			bb(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, h, WF), p["wall"])
			bb(k, Vector3(cx - w * 0.5 - 0.02, h - 0.08, BK - 0.02), Vector3(cx + w * 0.5 + 0.02, h, WF + 0.02), p["trim"])
			bb(k, Vector3(cx - w * 0.5 - 0.02, 0, BK - 0.02), Vector3(cx + w * 0.5 + 0.02, 0.14, WF + 0.02), p["dark"])
			bb(k, Vector3(cx - w * 0.5, 0.14, WF), Vector3(cx + w * 0.5, 0.17, WF + 0.03), lit(ac, 0.45))
			fins(k, at(cx, 0.3, WF), w - 0.1, h - 0.55, 4, 0.12, 4, ac)
			for i in 5:
				k.box(Vector3(0.06, h - 0.5, 0.06), p["wall2"], face_out * at(-d * 0.4 + i * d * 0.2, h * 0.5 + 0.05, 0.03))
				k.box(Vector3(0.02, h - 0.7, 0.02), lit(ac.lerp(Color.WHITE, 0.3), 0.4), face_out * at(-d * 0.4 + i * d * 0.2, h * 0.5 + 0.05, 0.07))
			bb(k, Vector3(cx - w * 0.5, h * 0.5, WF), Vector3(cx + w * 0.5, h * 0.5 + 0.04, WF + 0.13), p["trim"])
			run(k, [Vector3(xi + side * 0.05, 0.4, WF + 0.05), Vector3(xi + side * 0.05, h - 0.3, WF + 0.05)], 0.04, lit(ac, 0.45))
			bb(k, Vector3(cx - w * 0.5 + 0.03, h, BK + 0.03), Vector3(cx + w * 0.5 - 0.03, h + 0.02, WF - 0.03), p["roof"])
		"vault":
			# a recessed plinth under a cantilevered graphite box with fins
			h = h if h > 0.0 else 2.4
			var y0 := 0.9
			var px0 := minf(xi, xo - side * 0.15)
			var px1 := maxf(xi, xo - side * 0.15)
			bb(k, Vector3(px0, 0, BK + 0.12), Vector3(px1, y0, WF - 0.18), p["dark"])
			bb(k, Vector3(px0, y0 - 0.1, WF - 0.18), Vector3(px1, y0 - 0.06, WF - 0.15), lit(ac, 0.45))
			for i in 3:
				bb(k, Vector3(cx - 0.3 + i * 0.3 - 0.01, 0.1, WF - 0.18), Vector3(cx - 0.3 + i * 0.3 + 0.01, y0 - 0.15, WF - 0.16), lit(ac.lerp(Color.WHITE, 0.3), 0.45))
			bb(k, Vector3(cx - w * 0.5, y0, BK), Vector3(cx + w * 0.5, h, WF), p["wall"])
			bb(k, Vector3(cx - w * 0.5 - 0.02, y0, BK - 0.02), Vector3(cx + w * 0.5 + 0.02, y0 + 0.06, WF + 0.02), p["trim"])
			bb(k, Vector3(cx - w * 0.5 - 0.02, h - 0.06, BK - 0.02), Vector3(cx + w * 0.5 + 0.02, h, WF + 0.02), p["trim"])
			fins(k, at(cx, y0 + 0.12, WF), w - 0.1, h - y0 - 0.3, 5, 0.12, 4, ac)
			ArchKit.louvres(k, face_out * at(0, y0 + 0.2, 0.0), d - 0.3, h - y0 - 0.5, p["wall2"], 8)
			bb(k, Vector3(cx - w * 0.5 + 0.03, h, BK + 0.03), Vector3(cx + w * 0.5 - 0.03, h + 0.02, WF - 0.03), p["roof"])

	var tops := {"shed_steel": h + 0.12, "cage": h + 0.1, "office": h + 0.03, "plant": h + 0.03, "annex": h + 0.03,
		"canopy": h + 0.14, "stair": h + 0.12, "podium": h + 0.02, "vault": h + 0.02, "glass": h + 0.06, "fin": h + 0.02}
	if tops.has(style):
		_wing_roof(k, t, side, tops[style], style in ["office", "glass"])
	_wing_extra(k, kind, t, side, style, h)


## Facade detail layered on a wing after its style (seams, boxes, lights).
static func _wing_extra(k: MeshKit, kind: String, t: int, side: float, style: String, h: float) -> void:
	var p := ArchKit.pal(t)
	var cx := side * (WX + WX1) * 0.5
	var w := WX1 - WX
	var d := WF - BK
	var cz := (WF + BK) * 0.5
	var xo := side * WX1
	var face_out := xf(Vector3(xo, 0, cz), Vector3(0, 90 * side, 0))
	match style:
		"shed_steel":
			seams(k, face_out * at(0, 0, 0.045), d - 0.1, h - 0.1, 4, 2, p["wall2"].darkened(0.25))
			jbox(k, at(cx - side * 0.33, 1.05, WF), Color(0.6, 0.62, 0.66))
			run(k, [Vector3(cx - side * 0.37, h + 0.05, WF + 0.05), Vector3(cx - side * 0.37, 0.05, WF + 0.05)], 0.025, p["trim"])
			bb(k, Vector3(cx - 0.05, 0.03, WF + 0.01), Vector3(cx + 0.05, 0.04, WF + 0.12), p["accent"])
			# a shallow awning over the roll-up door, wall lamps, a vent
			bb(k, Vector3(cx + side * 0.06 - 0.36, 1.62, WF), Vector3(cx + side * 0.06 + 0.36, 1.66, WF + 0.12), p["trim"])
			for sx in [-0.34, 0.34]:
				bx(k, Vector3(0.06, 0.08, 0.06), Color(0.2, 0.2, 0.22), Vector3(cx + side * 0.06 + sx, 1.45, WF + 0.03))
				bx(k, Vector3(0.04, 0.04, 0.01), lit(p["glow"], 0.35), Vector3(cx + side * 0.06 + sx, 1.43, WF + 0.065))
			ArchKit.louvres(k, face_out * at(0.45, 1.5, -0.01), 0.25, 0.22, p["wall2"], 4)
		"container":
			for i in 3:
				bb(k, Vector3(cx - 0.3 + i * 0.3 - 0.04, 0.0, WF + 0.02), Vector3(cx - 0.3 + i * 0.3 + 0.04, 0.12, WF + 0.1), Color(0.42, 0.32, 0.22))
			bx(k, Vector3(0.18, 0.12, 0.02), Color(0.98, 0.84, 0.3), Vector3(cx + side * 0.25, 0.75, WF + 0.04))
			# vent grilles, a data plate, stencilled code, a padlock
			for sx in [-0.25, 0.25]:
				for j in 3:
					bb(k, Vector3(cx + sx - 0.06, h - 0.2 + j * 0.03, WF + 0.012), Vector3(cx + sx + 0.06, h - 0.19 + j * 0.03, WF + 0.03), Color(0.2, 0.2, 0.22))
			bb(k, Vector3(cx + 0.06, 0.95, WF + 0.012), Vector3(cx + 0.18, 1.03, WF + 0.022), Color(0.85, 0.85, 0.82))
			for j in 2:
				bb(k, Vector3(cx - 0.33, h - 0.42 - j * 0.07, WF + 0.012), Vector3(cx - 0.12, h - 0.38 - j * 0.07, WF + 0.02), Color(0.94, 0.94, 0.92))
			bb(k, Vector3(cx - 0.04, 0.5, WF + 0.03), Vector3(cx + 0.04, 0.58, WF + 0.06), Color(0.8, 0.66, 0.3))
		"office", "plant":
			seams(k, face_out * at(0, 0.0, 0.003), d - 0.1, h, 6, 1, Color(0.84, 0.86, 0.88))
			skin(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, h, WF), t, "b", 0.45)
			for i in 2:
				bollard(k, Vector3(cx - 0.25 + i * 0.5, 0, WF + 0.11), t)
			if style == "office":
				# sun fins on the upper curtain and a teal hood over the door
				for i in 4:
					bb(k, Vector3(cx - 0.3 + i * 0.2 - 0.015, h * 0.5 + 0.1, WF + 0.06), Vector3(cx - 0.3 + i * 0.2 + 0.015, h - 0.25, WF + 0.12), Color(0.97, 0.97, 0.98))
				bb(k, Vector3(cx - side * 0.1 - 0.3, 1.25, WF), Vector3(cx - side * 0.1 + 0.3, 1.29, WF + 0.12), p["trim"])
			else:
				# wall condensers on the outer face, a louvred screen on the roof edge
				for i in 2:
					k.box(Vector3(0.36, 0.3, 0.08), Color(0.9, 0.91, 0.92), face_out * at(-0.3 + i * 0.45, 0.35, 0.04))
					k.cyl(0.1, 0.01, Color(0.24, 0.25, 0.28), face_out * xf(Vector3(-0.35 + i * 0.45, 0.35, 0.085), Vector3(90, 0, 0)), 8)
				for i in 8:
					bb(k, Vector3(cx - w * 0.5 + 0.05 + i * 0.1, h + 0.03, BK + 0.02), Vector3(cx - w * 0.5 + 0.09 + i * 0.1, h + 0.45, BK + 0.06), Color(0.86, 0.88, 0.9))
			if style == "plant":
				ArchKit.louvres(k, at(cx + side * 0.15, 0.25, WF + 0.005), 0.45, 0.5, Color(0.36, 0.4, 0.44), 5)
		"glass":
			for i in 2:
				bollard(k, Vector3(cx - 0.3 + i * 0.6, 0, WF + 0.11), t)
			for i in 3:
				bb(k, Vector3(cx - 0.25 + i * 0.25 - 0.012, 0.14, WF + 0.06), Vector3(cx - 0.25 + i * 0.25 + 0.012, 2.35, WF + 0.11), Color(0.97, 0.97, 0.98))
		"annex":
			seams(k, face_out * at(0, 0.0, 0.003), d - 0.1, h, 5, 3, p["wall2"])
			skin(k, Vector3(cx - w * 0.5, 0, BK), Vector3(cx + w * 0.5, h, WF), t, "lb")
			jbox(k, face_out * at(-0.45, 1.0, 0.0), p["metal"], p["glow"])
			jbox(k, face_out * at(-0.25, 1.0, 0.0), p["metal"])
			run(k, [Vector3(xo + side * 0.04, 0.1, -0.6), Vector3(xo + side * 0.04, h - 0.2, -0.6)], 0.035, Color(0.36, 0.6, 0.86))
			run(k, [Vector3(xo + side * 0.04, 0.1, -0.7), Vector3(xo + side * 0.04, h - 0.2, -0.7)], 0.035, Color(0.86, 0.86, 0.84))
			for y in [0.9, 1.8, 2.6]:
				bb(k, Vector3(xo - 0.02, y, -0.75), Vector3(xo + 0.02, y + 0.04, -0.55), p["trim"])
		"canopy", "stair":
			for i in 2:
				bb(k, Vector3(cx - 0.35 + i * 0.6, 0.03, WF - 0.1), Vector3(cx - 0.25 + i * 0.6, 0.04, WF), p["accent"])
			jbox(k, face_out * at(0.3, 1.1, -0.06), p["metal"], p["glow"])
		"podium", "vault", "fin":
			var y0 := 0.9 if style == "vault" else 0.2
			skin(k, Vector3(cx - w * 0.5, y0, BK), Vector3(cx + w * 0.5, h, WF), t, "lrb" if side > 0 else "rlb")
			seams(k, face_out * at(0, y0, 0.002), d - 0.06, h - y0, 7, 4, p["wall2"].lightened(0.06))
			for y in [h * 0.33, h * 0.66]:
				k.box(Vector3(d - 0.1, 0.03, 0.03), p["trim"], face_out * at(0, y, 0.015))
			for i in 3:
				k.box(Vector3(0.1, 0.05, 0.02), lit([p["accent2"], p["glow"], Color(1.0, 0.4, 0.35)][i], 0.4), face_out * at(0.15 + i * 0.13, 0.5, 0.012))

# ---------------------------------------------------------------- machine

## The whole lab at tier t (wings, hero, yard), minus benches and the
## moving part.
static func machine(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	t = clampi(t, 0, 4)
	_lot(k, t)
	match kind:
		"fab":
			_fab(k, t)
			_fab_more(k, t)
		"refinery":
			_refinery(k, t)
			_refinery_more(k, t)
		"tune_lab":
			_tune_lab(k, t)
			_tune_lab_more(k, t)
		"hbm_works":
			_hbm_works(k, t)
			_hbm_works_more(k, t)
		"rlhf_gym":
			_rlhf_gym(k, t)
			_rlhf_gym_more(k, t)
		"synth_lab":
			_synth_lab(k, t)
			_synth_lab_more(k, t)
		_: _fab(k, t)
	_deluxe(k, kind, t)
	_extra2(k, kind, t)
	_extra3(k, kind, t)
	_extra4(k, kind, t)
	return k.commit()


## How tall the lab stands (for the badge above it).
static func height(kind: String, t: int) -> float:
	t = clampi(t, 0, 4)
	match kind:
		"fab": return [2.2, 2.8, 4.5, 6.3, 7.0][t]
		"refinery": return [2.2, 2.8, 4.5, 7.4, 7.8][t]
		"tune_lab": return [2.2, 3.0, 4.6, 6.6, 4.7][t]
		"hbm_works": return [2.3, 3.2, 3.8, 4.6, 7.7][t]
		"rlhf_gym": return [2.2, 2.5, 3.2, 3.8, 5.1][t]
		"synth_lab": return [2.2, 3.4, 3.3, 4.3, 4.8][t]
	return [2.4, 2.9, 3.9, 5.5, 7.0][t]


# ---------------------------------------------------------------- chip fab

static func _fab(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("fab")
	var yel := Color(1.0, 0.82, 0.36)        # fabs work under yellow light
	match t:
		0:
			_wing(k, "fab", t, -1.0, "shed", 1.75)
			_wing(k, "fab", t, 1.0, "pile", 1.1)
			# plywood back wall with a pegboard and shelves of parts bins
			ArchKit.planks(k, at(0, 0, BK + 0.02), 1.96, 1.9, Color(0.74, 0.6, 0.42))
			bb(k, Vector3(-0.85, 0.95, BK + 0.06), Vector3(-0.05, 1.6, BK + 0.09), Color(0.82, 0.7, 0.5))
			for i in 8:
				bx(k, Vector3(0.03, 0.12 + (i % 3) * 0.05, 0.02), [Color(0.8, 0.3, 0.25), Color(0.25, 0.3, 0.4), Color(0.9, 0.7, 0.2), Color(0.3, 0.6, 0.4)][i % 4], Vector3(-0.78 + i * 0.1, 1.3, BK + 0.1), Vector3(0, 0, (i % 2) * 24 - 12))
			for s in 2:
				bb(k, Vector3(0.05, 1.05 + s * 0.4, BK + 0.04), Vector3(0.9, 1.08 + s * 0.4, BK + 0.3), Color(0.62, 0.48, 0.32))
				for i in 6:
					bb(k, Vector3(0.1 + i * 0.13, 1.08 + s * 0.4, BK + 0.08), Vector3(0.2 + i * 0.13, 1.2 + s * 0.4, BK + 0.26), [Color(0.3, 0.5, 0.8), Color(0.9, 0.8, 0.3), Color(0.8, 0.34, 0.28), Color(0.94, 0.94, 0.92)][(i + s) % 4])
			# folding table with the soldering station, magnifier lamp, laptop
			var ty := 0.74
			bb(k, Vector3(-0.9, ty - 0.03, -1.75), Vector3(0.6, ty, -1.15), Color(0.9, 0.9, 0.88))
			for q in [Vector2(-0.85, -1.7), Vector2(0.55, -1.7), Vector2(-0.85, -1.2), Vector2(0.55, -1.2)]:
				bb(k, Vector3(q.x - 0.015, 0, q.y - 0.015), Vector3(q.x + 0.015, ty - 0.03, q.y + 0.015), Color(0.3, 0.3, 0.32))
			bb(k, Vector3(-0.75, ty, -1.6), Vector3(-0.5, ty + 0.1, -1.42), Color(0.26, 0.42, 0.7))
			bb(k, Vector3(-0.72, ty + 0.06, -1.42), Vector3(-0.66, ty + 0.08, -1.41), lit(Color(1.0, 0.4, 0.3), 0.4))
			cy(k, 0.04, 0.03, Color(0.3, 0.3, 0.32), Vector3(-0.42, ty, -1.5), 6)
			seg(k, Vector3(-0.42, ty + 0.05, -1.5), Vector3(-0.3, ty + 0.12, -1.38), 0.015, Color(0.2, 0.2, 0.22))
			seg(k, Vector3(-0.5, ty + 0.06, -1.46), Vector3(-0.44, ty + 0.06, -1.48), 0.008, Color(0.3, 0.3, 0.3))
			# magnifier lamp: clamp, two arms, ring
			bb(k, Vector3(-0.2, ty - 0.08, -1.74), Vector3(-0.14, ty + 0.05, -1.68), Color(0.3, 0.32, 0.36))
			seg(k, Vector3(-0.17, ty + 0.05, -1.71), Vector3(-0.17, ty + 0.5, -1.6), 0.025, Color(0.92, 0.92, 0.9))
			seg(k, Vector3(-0.17, ty + 0.5, -1.6), Vector3(-0.1, ty + 0.38, -1.35), 0.025, Color(0.92, 0.92, 0.9))
			k.torus(0.08, 0.018, Color(0.92, 0.92, 0.9), xf(Vector3(-0.1, ty + 0.34, -1.33), Vector3(20, 0, 0)), 10, 4)
			cy(k, 0.075, 0.01, lit(Color(0.9, 1.0, 1.0), 0.5), Vector3(-0.1, ty + 0.335, -1.33), 10)
			# PCBs, a multimeter, a reel of solder
			for i in 3:
				bx(k, Vector3(0.16, 0.012, 0.11), Color(0.2, 0.52, 0.32), Vector3(0.05 + i * 0.17, ty + 0.006 + i * 0.012, -1.32), Vector3(0, i * 9.0, 0))
				bx(k, Vector3(0.04, 0.014, 0.04), Color(0.15, 0.15, 0.16), Vector3(0.05 + i * 0.17, ty + 0.02 + i * 0.012, -1.32))
			bb(k, Vector3(0.3, ty, -1.65), Vector3(0.42, ty + 0.03, -1.45), Color(0.92, 0.72, 0.2))
			bb(k, Vector3(0.32, ty + 0.03, -1.62), Vector3(0.4, ty + 0.035, -1.55), lit(Color(0.7, 1.0, 0.7), 0.5))
			hcy(k, 0.04, 0.03, Color(0.7, 0.72, 0.74), Vector3(0.48, ty + 0.04, -1.3), false, 8)
			# laptop
			bb(k, Vector3(-0.42, ty, -1.3), Vector3(-0.12, ty + 0.015, -1.18), Color(0.3, 0.31, 0.34))
			k.box(Vector3(0.3, 0.2, 0.012), Color(0.3, 0.31, 0.34), xf(Vector3(-0.27, ty + 0.1, -1.31), Vector3(-15, 0, 0)))
			k.box(Vector3(0.26, 0.16, 0.005), lit(Color(0.5, 0.9, 0.6), 0.5), xf(Vector3(-0.27, ty + 0.1, -1.302), Vector3(-15, 0, 0)))
			# stool
			cy(k, 0.12, 0.04, Color(0.8, 0.3, 0.24), Vector3(-0.3, 0.5, -0.9), 8)
			for i in 3:
				var a := TAU * i / 3.0
				seg(k, Vector3(-0.3 + cos(a) * 0.05, 0.5, -0.9 + sin(a) * 0.05), Vector3(-0.3 + cos(a) * 0.14, 0, -0.9 + sin(a) * 0.14), 0.02, Color(0.3, 0.3, 0.32))
			# the toaster-oven reflow on a crate, glowing
			crate(k, Vector3(0.62, 0, -0.75), Vector3(0.44, 0.42, 0.36), -6.0)
			bb(k, Vector3(0.43, 0.42, -0.9), Vector3(0.79, 0.66, -0.62), Color(0.78, 0.78, 0.76))
			bb(k, Vector3(0.46, 0.46, -0.62), Vector3(0.68, 0.62, -0.6), lit(Color(1.0, 0.5, 0.2), 0.35))
			for i in 2:
				cy(k, 0.02, 0.02, Color(0.15, 0.15, 0.16), Vector3(0.735, 0.58 - i * 0.07, -0.6), 6)
				hcy(k, 0.018, 0.02, Color(0.15, 0.15, 0.16), Vector3(0.735, 0.58 - i * 0.07, -0.605), false, 6)
			bb(k, Vector3(0.45, 0.66, -0.88), Vector3(0.77, 0.68, -0.64), Color(0.6, 0.6, 0.6))
			# the inspection crate at the front, turntable sits on it (part)
			crate(k, Vector3(0, 0, -0.18), Vector3(0.46, 0.5, 0.4), 0.0, Color(0.7, 0.55, 0.38))
			bb(k, Vector3(-0.14, 0.5, -0.32), Vector3(-0.06, 0.62, -0.26), Color(0.3, 0.32, 0.36))
			seg(k, Vector3(-0.1, 0.62, -0.29), Vector3(-0.03, 0.9, -0.24), 0.02, Color(0.92, 0.92, 0.9))
			seg(k, Vector3(-0.03, 0.9, -0.24), Vector3(0.02, 0.82, -0.12), 0.02, Color(0.92, 0.92, 0.9))
			cy(k, 0.06, 0.03, Color(0.92, 0.92, 0.9), Vector3(0.02, 0.78, -0.12), 8)
			cy(k, 0.05, 0.01, lit(Color(1.0, 0.95, 0.8), 0.4), Vector3(0.02, 0.775, -0.12), 8)
			# a blue tarp over the work area on poles, string lights
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.03, 0, -1.02), Vector3(sx + 0.03, 2.05, -0.96), Color(0.5, 0.36, 0.24))
			k.box(Vector3(2.0, 0.025, 0.9), Color(0.26, 0.46, 0.78), xf(Vector3(0, 2.1, -1.42), Vector3(-8, 0, 0)))
			for sx in [-1.0, 1.0]:
				seg(k, Vector3(sx * 0.95, 2.05, -0.98), Vector3(sx * 1.3, 0.0, -0.5), 0.01, Color(0.86, 0.8, 0.6))
			ArchKit.string_lights(k, Vector3(-0.95, 1.95, -0.96), Vector3(0.95, 1.95, -0.96), 9)
			ArchKit.string_lights(k, Vector3(-1.0, 1.85, WF + 0.1), Vector3(-0.95, 1.95, -0.96), 3)
			# an extension cord snaking out of the shed, a fan, a bucket
			cord(k, [Vector2(-1.0, -0.42), Vector2(-0.7, -0.35), Vector2(-0.6, -0.8), Vector2(-0.2, -1.0), Vector2(0.4, -0.95), Vector2(0.5, -0.8)], Color(0.92, 0.5, 0.18))
			bb(k, Vector3(-0.66, 0.0, -0.84), Vector3(-0.52, 0.06, -0.76), Color(0.92, 0.5, 0.18))
			cy(k, 0.1, 0.06, Color(0.86, 0.86, 0.84), Vector3(0.85, 0, -1.6), 8)
			cy(k, 0.015, 0.4, Color(0.86, 0.86, 0.84), Vector3(0.85, 0.06, -1.6), 5)
			k.cyl(0.13, 0.06, Color(0.86, 0.86, 0.84), xf(Vector3(0.85, 0.52, -1.55), Vector3(80, 0, 0)), 10)
			drum(k, Vector3(-0.75, 0, -0.75), Color(0.3, 0.5, 0.74), 0.11, 0.3)
			# copper reels + silicon sacks by the pile
			for i in 3:
				bx(k, Vector3(0.3, 0.12, 0.2), Color(0.86, 0.84, 0.78), Vector3(0.8, 0.06 + i * 0.12, -1.28), Vector3(0, i * 15.0, 0))
		1:
			_wing(k, "fab", t, -1.0, "container", 1.25)
			_wing(k, "fab", t, 1.0, "shed_steel", 1.95)
			# the cleanroom booth: steel frame, white panels, strip curtain
			var bh := 2.15
			var x0 := -0.88
			var x1 := 0.88
			var z0 := -1.82
			var z1 := -0.62
			for q in [Vector2(x0, z0), Vector2(x1, z0), Vector2(x0, z1), Vector2(x1, z1)]:
				bb(k, Vector3(q.x - 0.04, 0, q.y - 0.04), Vector3(q.x + 0.04, bh + 0.1, q.y + 0.04), p["trim"])
			bb(k, Vector3(x0, 0, z0), Vector3(x1, bh, z0 + 0.04), Color(0.92, 0.93, 0.94))
			for sx in [x0, x1]:
				bb(k, Vector3(sx - 0.02, 0, z0), Vector3(sx + 0.02, bh, z1), Color(0.92, 0.93, 0.94))
				for i in 3:
					bb(k, Vector3(sx - 0.03, 0.1, z0 + 0.1 + i * 0.4), Vector3(sx + 0.03, bh - 0.1, z0 + 0.12 + i * 0.4), Color(0.8, 0.82, 0.84))
			bb(k, Vector3(x0 - 0.05, bh, z0 - 0.05), Vector3(x1 + 0.05, bh + 0.12, z1 + 0.05), p["trim"])
			bb(k, Vector3(x0, bh - 0.25, z1 - 0.02), Vector3(x1, bh, z1 + 0.02), Color(0.92, 0.93, 0.94))
			for i in 14:
				var sx := x0 + 0.06 + i * (x1 - x0 - 0.12) / 13.0
				bb(k, Vector3(sx - 0.05, 0.05, z1 + 0.01 + (i % 2) * 0.012), Vector3(sx + 0.05, bh - 0.25, z1 + 0.02 + (i % 2) * 0.012), Color(0.72, 0.86, 0.9, 0.85))
			bb(k, Vector3(x0, 1.5, z1 + 0.04), Vector3(x1, 1.53, z1 + 0.05), lit(yel, 0.35))
			# booth roof: 2x3 fan filter units, a duct to the fume scrubber
			for i in 3:
				for j in 2:
					var fx := -0.56 + i * 0.56
					var fz := -1.5 + j * 0.56
					bb(k, Vector3(fx - 0.25, bh + 0.12, fz - 0.25), Vector3(fx + 0.25, bh + 0.26, fz + 0.25), Color(0.94, 0.95, 0.96))
					bb(k, Vector3(fx - 0.2, bh + 0.26, fz - 0.2), Vector3(fx + 0.2, bh + 0.27, fz + 0.2), Color(0.66, 0.7, 0.74))
					cy(k, 0.08, 0.1, Color(0.8, 0.82, 0.84), Vector3(fx, bh + 0.27, fz), 8)
					bx(k, Vector3(0.05, 0.03, 0.03), lit(Color(0.5, 1.0, 0.6), 0.4), Vector3(fx + 0.17, bh + 0.28, fz + 0.17))
			run(k, [Vector3(0.5, bh + 0.37, -1.5), Vector3(0.5, bh + 0.55, -1.5), Vector3(0.95, bh + 0.55, -1.5), Vector3(0.95, 2.05, -1.5)], 0.08, Color(0.78, 0.78, 0.8), 8)
			for i in 4:
				hcy(k, 0.088, 0.03, Color(0.6, 0.62, 0.66), Vector3(0.6 + i * 0.1, bh + 0.55, -1.5), true, 8)
			# gas bottles chained to the booth's side, a hazard sign
			for i in 3:
				gas_bottle(k, Vector3(-0.78 + i * 0.16, 0, -0.5), [Color(0.3, 0.5, 0.8), Color(0.86, 0.86, 0.84), Color(0.3, 0.6, 0.4)][i], 0.85, 0.06)
			bb(k, Vector3(-0.86, 0.6, -0.45), Vector3(-0.38, 0.62, -0.43), Color(0.6, 0.6, 0.62))
			bx(k, Vector3(0.2, 0.2, 0.02), Color(0.98, 0.84, 0.3), Vector3(0.55, 1.2, z1 + 0.06), Vector3(0, 0, 45))
			# the spin coater cabinet at the front (wafer spins on top)
			bb(k, Vector3(-0.3, 0, -0.42), Vector3(0.3, 0.62, 0.05), Color(0.84, 0.86, 0.88))
			bb(k, Vector3(-0.3, 0.62, -0.42), Vector3(0.3, 0.66, 0.05), p["trim"])
			cy(k, 0.2, 0.08, Color(0.6, 0.62, 0.66), Vector3(0, 0.66, -0.18), 10)
			cy(k, 0.17, 0.02, Color(0.2, 0.22, 0.26), Vector3(0, 0.735, -0.18), 10)
			bb(k, Vector3(-0.26, 0.2, 0.05), Vector3(0.26, 0.5, 0.06), Color(0.74, 0.76, 0.8))
			screen(k, xf(Vector3(0.16, 0.5, 0.07)), 0.12, 0.08, Color(0.5, 1.0, 0.6))
			for i in 3:
				bx(k, Vector3(0.03, 0.03, 0.02), [Color(0.3, 0.9, 0.4), Color(0.9, 0.8, 0.3), Color(0.9, 0.3, 0.3)][i], Vector3(-0.18 + i * 0.07, 0.48, 0.07))
			# fume extractor arm over the coater
			seg(k, Vector3(-0.25, 1.5, -0.62), Vector3(-0.2, 1.25, -0.35), 0.05, Color(0.84, 0.86, 0.88))
			seg(k, Vector3(-0.2, 1.25, -0.35), Vector3(-0.05, 1.05, -0.2), 0.05, Color(0.84, 0.86, 0.88))
			k.cyl(0.1, 0.08, Color(0.9, 0.7, 0.2), at(-0.05, 0.98, -0.2), 8, 0.0, 0.05)
			# cable tray from the container to the booth, yellow bollards
			ArchKit.cable_tray(k, Vector3(-1.0, bh + 0.0, -1.0), Vector3(-0.6, bh + 0.0, -1.0), t)
			for sx in [-0.6, 0.6]:
				cy(k, 0.05, 0.6, p["accent"], Vector3(sx, 0, 0.62), 8)
				cy(k, 0.052, 0.06, Color(0.15, 0.15, 0.16), Vector3(sx, 0.45, 0.62), 8)
			# yellow floor tape around the booth
			bb(k, Vector3(-0.95, 0.03, -0.56), Vector3(0.95, 0.036, -0.52), p["accent"])
		2:
			_wing(k, "fab", t, -1.0, "office", 2.9)
			_wing(k, "fab", t, 1.0, "plant", 2.2)
			# the white cleanroom pod
			var ph := 3.3
			ArchKit.block(k, Vector3(0, 0, -1.19), Vector3(1.96, ph, 1.38), t, "", 2)
			# yellow-lit gowning windows upstairs, a teal band, the logo
			bb(k, Vector3(-0.9, 1.95, WF - 0.05), Vector3(0.9, 2.75, WF - 0.02), Color(0.86, 0.88, 0.9))
			bb(k, Vector3(-0.84, 2.0, WF - 0.02), Vector3(0.84, 2.7, WF + 0.0), lit(yel, 0.5))
			for i in 7:
				bb(k, Vector3(-0.84 + i * 0.28 - 0.02, 2.0, WF - 0.02), Vector3(-0.84 + i * 0.28 + 0.02, 2.7, WF + 0.01), Color(0.86, 0.88, 0.9))
			for q in [Vector2(-0.5, 0.0), Vector2(0.32, 1.0)]:
				bb(k, Vector3(q.x - 0.09, 2.0, WF + 0.002), Vector3(q.x + 0.09, 2.38, WF + 0.008), Color(0.97, 0.97, 0.98))
				bb(k, Vector3(q.x - 0.06, 2.4, WF + 0.002), Vector3(q.x + 0.06, 2.55, WF + 0.008), Color(0.97, 0.97, 0.98))
				bb(k, Vector3(q.x - 0.045, 2.43, WF + 0.008), Vector3(q.x + 0.045, 2.5, WF + 0.012), Color(0.3, 0.4, 0.5))

			bb(k, Vector3(-0.98, 1.6, WF - 0.05), Vector3(0.98, 1.72, WF + 0.01), p["trim"])
			# airlock vestibule with double glass doors and an air shower
			bb(k, Vector3(-0.42, 0, -0.5), Vector3(0.42, 1.55, -0.3), Color(0.92, 0.93, 0.94))
			bb(k, Vector3(-0.46, 1.55, -0.52), Vector3(0.46, 1.62, -0.26), p["trim"])
			for sx in [-1.0, 1.0]:
				bb(k, Vector3(sx * 0.18 - 0.16, 0.0, -0.3), Vector3(sx * 0.18 + 0.16, 1.3, -0.28), p["glass"])
				bb(k, Vector3(sx * 0.02 - 0.015, 0.05, -0.29), Vector3(sx * 0.02 + 0.015, 0.7, -0.26), Color(0.7, 0.72, 0.75))
			bb(k, Vector3(-0.36, 1.3, -0.3), Vector3(0.36, 1.34, -0.27), Color(0.7, 0.72, 0.75))
			bb(k, Vector3(-0.15, 1.38, -0.29), Vector3(0.15, 1.5, -0.27), lit(Color(0.5, 1.0, 0.6), 0.45))
			# the logo: a wafer disc on a white board above the band
			bb(k, Vector3(-0.55, 2.82, WF - 0.05), Vector3(0.55, 3.18, WF + 0.01), Color(0.97, 0.97, 0.98))
			k.cyl(0.14, 0.03, Color(0.62, 0.66, 0.74), xf(Vector3(-0.35, 3.0, WF + 0.01), Vector3(90, 0, 0)), 12)
			for i in 3:
				for j in 3:
					bx(k, Vector3(0.05, 0.05, 0.01), lit(ac, 0.5) if (i + j) % 2 == 0 else Color(0.5, 0.56, 0.7), Vector3(-0.41 + i * 0.06, 2.94 + j * 0.06, WF + 0.045))
			bb(k, Vector3(-0.15, 2.95, WF + 0.01), Vector3(0.45, 3.05, WF + 0.02), p["dark"])
			# screened rooftop plant: HEPA units, a fan (part), two stacks
			var ry := ph + 0.03
			for i in 3:
				for j in 2:
					var fx := -0.55 + i * 0.4
					var fz := -1.55 + j * 0.42
					bb(k, Vector3(fx - 0.16, ry, fz - 0.17), Vector3(fx + 0.16, ry + 0.22, fz + 0.17), Color(0.92, 0.93, 0.94))
					bb(k, Vector3(fx - 0.12, ry + 0.22, fz - 0.12), Vector3(fx + 0.12, ry + 0.23, fz + 0.12), Color(0.62, 0.66, 0.7))
			bb(k, Vector3(0.3, ry, -1.2), Vector3(0.82, ry + 0.24, -0.72), Color(0.84, 0.86, 0.88))
			for z in [-1.85, -0.62]:
				for i in 12:
					bb(k, Vector3(-0.9 + i * 0.16, ry, z - 0.02), Vector3(-0.86 + i * 0.16, ry + 0.5, z + 0.02), Color(0.86, 0.88, 0.9))
				bb(k, Vector3(-0.92, ry + 0.48, z - 0.03), Vector3(0.92, ry + 0.52, z + 0.03), p["trim"])
			for sx in [-0.7, -0.45]:
				cy(k, 0.08, 1.1, Color(0.84, 0.86, 0.88), Vector3(sx, ry, -1.05), 8)
				cy(k, 0.1, 0.06, p["trim"], Vector3(sx, ry + 1.1, -1.05), 8)
			run(k, [Vector3(-0.58, ry + 0.4, -1.05), Vector3(-0.58, ry + 0.4, -1.3), Vector3(-0.15, ry + 0.4, -1.3)], 0.04, Color(0.7, 0.72, 0.75))
			# process gas lines climbing the pod's side
			for i in 3:
				run(k, [Vector3(-0.97, 0.3, -0.6 - i * 0.06), Vector3(-0.97, ph - 0.3, -0.6 - i * 0.06)], 0.02, [Color(0.86, 0.6, 0.3), Color(0.7, 0.72, 0.75), Color(0.3, 0.5, 0.8)][i])
			# planters and a bike rack out front of the wings
			ArchKit.planter(k, Vector3(-0.68, 0, -0.38), t, 0.4)
			ArchKit.planter(k, Vector3(0.68, 0, -0.38), t, 0.4)
		3:
			_wing(k, "fab", t, -1.0, "canopy", 2.6)
			_wing(k, "fab", t, 1.0, "stair", 3.0)
			# the fab bay: steel frame, corrugated base, glass above
			var hh := 3.8
			var x0 := -0.98
			var x1 := 0.98
			var z0 := BK
			var z1 := -0.58
			bb(k, Vector3(x0 + 0.04, 0, z0 + 0.04), Vector3(x1 - 0.04, hh, z1 - 0.04), p["wall"])
			ArchKit.corrugated(k, at(0, 0, z1 - 0.04), x1 - x0 - 0.1, 1.3, p["wall2"], 0.14)
			ArchKit.curtain(k, at(0, 1.4, z1 - 0.04), x1 - x0 - 0.1, hh - 1.7, t, 4, 2)
			for sx in [x0, -0.33, 0.33, x1]:
				bb(k, Vector3(sx - 0.05, 0, z1 - 0.06), Vector3(sx + 0.05, hh + 0.1, z1 + 0.02), p["trim"])
				bb(k, Vector3(sx - 0.05, 0, z0), Vector3(sx + 0.05, hh + 0.1, z0 + 0.08), p["trim"])
			bb(k, Vector3(x0 - 0.04, hh, z0), Vector3(x1 + 0.04, hh + 0.16, z1 + 0.04), p["trim"])
			bb(k, Vector3(x0, hh + 0.16, z0), Vector3(x1, hh + 0.18, z1), p["roof"])
			bb(k, Vector3(x0, hh + 0.08, z1 + 0.04), Vector3(x1, hh + 0.11, z1 + 0.06), lit(p["accent2"], 0.4))
			bb(k, Vector3(x0, 1.32, z1 - 0.02), Vector3(x1, 1.36, z1 + 0.02), lit(yel, 0.4))
			# the litho tool pushing out of the bay, load port at the front
			bb(k, Vector3(-0.36, 0, -0.58), Vector3(0.36, 1.5, -0.32), Color(0.9, 0.91, 0.92))
			bb(k, Vector3(-0.3, 0.9, -0.32), Vector3(0.3, 1.35, -0.3), lit(yel, 0.45))
			bb(k, Vector3(-0.38, 1.5, -0.6), Vector3(0.38, 1.56, -0.3), p["accent2"])
			bb(k, Vector3(-0.32, 0, -0.32), Vector3(0.32, 0.56, 0.22), Color(0.86, 0.88, 0.9))
			bb(k, Vector3(-0.32, 0.56, -0.32), Vector3(0.32, 0.6, 0.22), p["trim"])
			for i in 2:
				bb(k, Vector3(-0.28 + i * 0.36, 0.6, 0.0), Vector3(-0.08 + i * 0.36, 0.78, 0.2), Color(0.3, 0.32, 0.36))
				bb(k, Vector3(-0.26 + i * 0.36, 0.78, 0.02), Vector3(-0.1 + i * 0.36, 0.8, 0.18), lit(ac, 0.5))
			stack_light(k, Vector3(0.3, 1.56, -0.45), 0.25)
			screen(k, xf(Vector3(-0.2, 0.4, 0.23)), 0.18, 0.12, p["glow"], 3)
			# exhaust stacks, scrubber, pipe rack and catwalk on the roof
			var ry := hh + 0.18
			for sx in [-0.62, 0.62]:
				cy(k, 0.17, 2.3, Color(0.78, 0.8, 0.82), Vector3(sx, ry, -1.55), 10)
				for i in 3:
					cy(k, 0.185, 0.05, p["trim"], Vector3(sx, ry + 0.4 + i * 0.7, -1.55), 10)
				cy(k, 0.19, 0.06, Color(0.98, 0.3, 0.25), Vector3(sx, ry + 2.24, -1.55), 10)
				bb(k, Vector3(sx - 0.2, ry, -1.75), Vector3(sx + 0.2, ry + 0.3, -1.35), p["metal"])
			bb(k, Vector3(-0.35, ry, -1.75), Vector3(0.35, ry + 0.6, -1.3), p["wall2"])
			ArchKit.louvres(k, at(0, ry + 0.1, -1.3), 0.6, 0.4, p["metal"], 4)
			ArchKit.pipe_rack(k, at(0, ry, -1.0), 1.8, 0.4, t, 3)
			ArchKit.catwalk(k, Vector3(-0.9, ry + 0.02, -0.75), Vector3(0.9, ry + 0.02, -0.75), 0.3, t, false)
			# a bridge from the stair tower to the roof
			ArchKit.catwalk(k, Vector3(0.9, 3.12, -1.15), Vector3(1.05, 3.12, -1.15), 0.4, t, false)
			# chemical delivery: drums and an IBC by the canopy
			for i in 2:
				drum(k, Vector3(-0.8 + i * 0.26, 0, -0.42), Color(0.3, 0.5, 0.8), 0.11, 0.36)
		_:
			_wing(k, "fab", t, -1.0, "vault", 2.4)
			_wing(k, "fab", t, 1.0, "podium", 2.0)
			# the EUV tower: graphite with brass bands and glowing fins
			var th := 5.4
			bb(k, Vector3(-0.8, 0, -1.78), Vector3(0.8, th, -0.62), p["wall"])
			for i in 4:
				var y := 1.2 + i * 1.3
				bb(k, Vector3(-0.82, y, -1.8), Vector3(0.82, y + 0.06, -0.6), p["trim"])
			fins(k, at(0, 0.3, -0.62), 1.5, th - 0.6, 8, 0.2)
			for sx in [-1.0, 1.0]:
				bb(k, Vector3(sx * 0.8 - 0.06, 0, -0.68), Vector3(sx * 0.8 + 0.06, th + 0.2, -0.56), p["trim"])
			# a cantilevered upper box overhanging the front
			bb(k, Vector3(-0.95, 3.4, -1.86), Vector3(0.95, 4.6, -0.36), p["wall2"])
			bb(k, Vector3(-0.97, 3.36, -1.88), Vector3(0.97, 3.42, -0.34), p["trim"])
			bb(k, Vector3(-0.97, 4.58, -1.88), Vector3(0.97, 4.64, -0.34), p["trim"])
			bb(k, Vector3(-0.85, 3.6, -0.36), Vector3(0.85, 4.4, -0.34), p["glass"])
			for i in 9:
				bb(k, Vector3(-0.85 + i * 0.2125 - 0.02, 3.6, -0.34), Vector3(-0.85 + i * 0.2125 + 0.02, 4.4, -0.31), p["trim"])
			bb(k, Vector3(-0.95, 3.38, -0.37), Vector3(0.95, 3.4, -0.33), lit(p["accent2"], 0.4))
			# crown: brass posts and rings around the light source
			var cy0 := th
			bb(k, Vector3(-0.7, cy0, -1.7), Vector3(0.7, cy0 + 0.12, -0.7), p["trim"])
			for q in [Vector2(-0.55, -1.55), Vector2(0.55, -1.55), Vector2(-0.55, -0.85), Vector2(0.55, -0.85)]:
				bb(k, Vector3(q.x - 0.04, cy0, q.y - 0.04), Vector3(q.x + 0.04, cy0 + 1.2, q.y + 0.04), p["trim"])
			k.torus(0.55, 0.03, p["trim"], at(0, cy0 + 1.2, -1.2), 16, 4)
			k.sphere(0.24, lit(Color(0.8, 0.6, 1.0), 0.25), at(0, cy0 + 0.75, -1.2), 10, 6)
			cy(k, 0.12, 0.3, p["dark"], Vector3(0, cy0 + 0.12, -1.2), 8)
			ArchKit.beacon(k, Vector3(0.55, cy0 + 1.2, -1.55), 0.3)
			ArchKit.beacon(k, Vector3(-0.55, cy0 + 1.2, -0.85), 0.3)
			# brass vacuum chambers at the front with glowing ports
			for sx in [-0.18, 0.18]:
				cy(k, 0.14, 1.1, p["trim"], Vector3(sx, 0, -0.42), 10)
				for i in 3:
					cy(k, 0.16, 0.04, p["trim"].darkened(0.2), Vector3(sx, 0.2 + i * 0.35, -0.42), 10)
				k.sphere(0.14, p["trim"], xf(Vector3(sx, 1.1, -0.42), Vector3.ZERO, Vector3(1, 0.6, 1)), 10, 5)
				k.cyl(0.05, 0.02, lit(Color(0.8, 0.6, 1.0), 0.35), xf(Vector3(sx, 0.7, -0.27), Vector3(90, 0, 0)), 8)
			# glowing coolant loops climbing the tower
			for sx in [-0.7, 0.7]:
				run(k, [Vector3(sx * 1.4, 1.6, -0.5), Vector3(sx, 1.6, -0.5), Vector3(sx, 3.3, -0.5)], 0.045, lit(p["accent2"], 0.45))



# ---------------------------------------------------------------- data refinery

static func _refinery(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("refinery")
	var dat := lit(ac, 0.5)
	match t:
		0:
			_wing(k, "refinery", t, -1.0, "pile", 1.15)
			_wing(k, "refinery", t, 1.0, "shed", 1.8)
			# a corkboard of printouts and red string on a plywood wall
			ArchKit.planks(k, at(0, 0, BK + 0.02), 1.96, 1.85, Color(0.72, 0.58, 0.4))
			bb(k, Vector3(-0.8, 0.9, BK + 0.06), Vector3(0.2, 1.65, BK + 0.09), Color(0.7, 0.5, 0.32))
			for i in 9:
				var q := Vector2(-0.72 + (i % 5) * 0.2, 1.0 + (i / 5) * 0.32 + (i % 2) * 0.05)
				bx(k, Vector3(0.14, 0.18, 0.01), Color(0.96, 0.95, 0.9), Vector3(q.x, q.y + 0.1, BK + 0.1), Vector3(0, 0, (i % 3) * 6 - 6))
				bx(k, Vector3(0.025, 0.025, 0.02), Color(0.9, 0.25, 0.2), Vector3(q.x, q.y + 0.17, BK + 0.11))
			for i in 4:
				seg(k, Vector3(-0.72 + i * 0.2, 1.27, BK + 0.115), Vector3(-0.52 + i * 0.2, 1.37 - (i % 2) * 0.3, BK + 0.115), 0.008, Color(0.9, 0.2, 0.2))
			# a kitchen table: laptop, an old CRT, a tower of hard drives, a router
			var ty := 0.74
			bb(k, Vector3(-0.92, ty - 0.04, -1.75), Vector3(0.15, ty, -1.1), Color(0.86, 0.8, 0.66))
			for q in [Vector2(-0.88, -1.7), Vector2(0.11, -1.7), Vector2(-0.88, -1.15), Vector2(0.11, -1.15)]:
				bb(k, Vector3(q.x - 0.025, 0, q.y - 0.025), Vector3(q.x + 0.025, ty - 0.04, q.y + 0.025), Color(0.6, 0.46, 0.3))
			bb(k, Vector3(-0.85, ty, -1.72), Vector3(-0.45, ty + 0.34, -1.38), Color(0.86, 0.84, 0.78))
			bb(k, Vector3(-0.8, ty + 0.06, -1.38), Vector3(-0.5, ty + 0.3, -1.36), lit(Color(0.5, 0.9, 1.0), 0.45))
			bb(k, Vector3(-0.32, ty, -1.38), Vector3(-0.02, ty + 0.015, -1.2), Color(0.3, 0.31, 0.34))
			k.box(Vector3(0.3, 0.2, 0.012), Color(0.3, 0.31, 0.34), xf(Vector3(-0.17, ty + 0.1, -1.39), Vector3(-12, 0, 0)))
			k.box(Vector3(0.26, 0.16, 0.005), dat, xf(Vector3(-0.17, ty + 0.1, -1.382), Vector3(-12, 0, 0)))
			for i in 5:
				bb(k, Vector3(-0.3, ty + i * 0.05, -1.72), Vector3(-0.08, ty + i * 0.05 + 0.045, -1.52), Color(0.2, 0.21, 0.24) if i % 2 == 0 else Color(0.3, 0.32, 0.36))
				bb(k, Vector3(-0.27, ty + i * 0.05 + 0.015, -1.519), Vector3(-0.25, ty + i * 0.05 + 0.03, -1.515), lit(Color(0.4, 1.0, 0.5), 0.35))
			bb(k, Vector3(0.0, ty, -1.7), Vector3(0.12, ty + 0.04, -1.55), Color(0.92, 0.92, 0.92))
			for i in 2:
				seg(k, Vector3(0.02 + i * 0.08, ty + 0.04, -1.68), Vector3(0.0 + i * 0.12, ty + 0.25, -1.7), 0.012, Color(0.2, 0.2, 0.22))
			for i in 3:
				cy(k, 0.03, 0.08, [Color(0.9, 0.3, 0.25), Color(0.95, 0.95, 0.92), Color(0.3, 0.5, 0.8)][i], Vector3(-0.6 + i * 0.12, ty, -1.25), 6)
			cy(k, 0.12, 0.04, Color(0.3, 0.32, 0.36), Vector3(-0.3, 0.5, -0.9), 8)
			cy(k, 0.02, 0.5, Color(0.3, 0.32, 0.36), Vector3(-0.3, 0, -0.9), 5)
			bx(k, Vector3(0.22, 0.3, 0.04), Color(0.3, 0.32, 0.36), Vector3(-0.3, 0.72, -1.0), Vector3(-8, 0, 0))
			# the homebrew distiller: a water-cooler jug full of glowing data
			bb(k, Vector3(0.38, 0, -1.25), Vector3(0.72, 0.85, -0.95), Color(0.92, 0.92, 0.9))
			bb(k, Vector3(0.42, 0.45, -0.95), Vector3(0.68, 0.48, -0.93), Color(0.4, 0.42, 0.46))
			bb(k, Vector3(0.48, 0.55, -0.95), Vector3(0.52, 0.6, -0.92), Color(0.3, 0.5, 0.9))
			bb(k, Vector3(0.58, 0.55, -0.95), Vector3(0.62, 0.6, -0.92), Color(0.9, 0.3, 0.25))
			cy(k, 0.15, 0.5, Color(0.6, 0.86, 1.0, 0.7), Vector3(0.55, 0.85, -1.1), 10)
			cy(k, 0.06, 0.08, Color(0.6, 0.86, 1.0, 0.7), Vector3(0.55, 1.35, -1.1), 8)
			cy(k, 0.16, 0.03, Color(0.3, 0.5, 0.8), Vector3(0.55, 1.2, -1.1), 10)
			# a funnel on a tripod over a bucket: printouts in, datasets out
			for i in 3:
				var a := TAU * i / 3.0
				seg(k, Vector3(0.6 + cos(a) * 0.05, 0.75, -0.55 + sin(a) * 0.05), Vector3(0.6 + cos(a) * 0.24, 0, -0.55 + sin(a) * 0.24), 0.02, Color(0.5, 0.36, 0.24))
			k.cyl(0.04, 0.28, Color(0.92, 0.6, 0.24), at(0.6, 0.72, -0.55), 10, 0.0, 0.22)
			cy(k, 0.12, 0.24, Color(0.94, 0.94, 0.92), Vector3(0.6, 0, -0.55), 8, 0.14)
			cy(k, 0.12, 0.02, dat, Vector3(0.6, 0.2, -0.55), 8)
			# the shredder out front, shreds, boxes of printouts
			bb(k, Vector3(-0.2, 0, -0.35), Vector3(0.2, 0.45, -0.05), Color(0.2, 0.21, 0.24))
			bb(k, Vector3(-0.22, 0.45, -0.37), Vector3(0.22, 0.56, -0.03), Color(0.3, 0.31, 0.34))
			bb(k, Vector3(-0.15, 0.56, -0.22), Vector3(0.15, 0.565, -0.18), Color(0.05, 0.05, 0.06))
			bb(k, Vector3(0.12, 0.52, -0.03), Vector3(0.16, 0.54, -0.02), lit(Color(0.4, 1.0, 0.5), 0.4))
			for i in 7:
				bx(k, Vector3(0.012, 0.012, 0.12), Color(0.96, 0.95, 0.9), Vector3(-0.15 + i * 0.05, 0.04, 0.02 + (i % 3) * 0.02), Vector3(0, i * 25.0, 0))
			for i in 3:
				crate(k, Vector3(-0.72 + i * 0.05, i * 0.26, -0.6 + i * 0.02), Vector3(0.36, 0.26, 0.3), i * 7.0 - 7.0, Color(0.78, 0.66, 0.48))
				bb(k, Vector3(-0.85 + i * 0.05, i * 0.26 + 0.26, -0.7), Vector3(-0.6 + i * 0.05, i * 0.26 + 0.275, -0.5), Color(0.96, 0.95, 0.9))
			# a clear corrugated awning on a timber frame, string lights, cords
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.035, 0, -0.85), Vector3(sx + 0.035, 1.95, -0.78), Color(0.5, 0.36, 0.24))
			bb(k, Vector3(-0.97, 1.95, -0.85), Vector3(0.97, 2.03, -0.78), Color(0.5, 0.36, 0.24))
			var roof := xf(Vector3(0, 2.1, -1.33), Vector3(-6, 0, 0))
			k.box(Vector3(1.98, 0.02, 1.04), Color(0.84, 0.9, 0.9), roof)
			for i in 10:
				k.box(Vector3(0.02, 0.025, 1.04), Color(0.74, 0.8, 0.82), roof * at(-0.9 + i * 0.2, 0.02, 0))
			ArchKit.string_lights(k, Vector3(-0.95, 1.9, -0.8), Vector3(0.95, 1.9, -0.8), 8, Color(0.6, 0.9, 1.0))
			cord(k, [Vector2(1.0, -0.42), Vector2(0.7, -0.5), Vector2(0.3, -0.75), Vector2(-0.1, -0.85), Vector2(-0.6, -1.0)], Color(0.92, 0.5, 0.18))
			cord(k, [Vector2(0.15, -0.3), Vector2(0.3, -0.6), Vector2(0.4, -1.0)], Color(0.2, 0.2, 0.22))
		1:
			_wing(k, "refinery", t, -1.0, "shed_steel", 2.0)
			_wing(k, "refinery", t, 1.0, "container", 1.3)
			# the sorting hopper on legs over a belt, a platform with stairs
			var hy := 1.15
			for q in [Vector2(-0.45, -1.6), Vector2(0.35, -1.6), Vector2(-0.45, -0.85), Vector2(0.35, -0.85)]:
				bb(k, Vector3(q.x - 0.04, 0, q.y - 0.04), Vector3(q.x + 0.04, 2.05, q.y + 0.04), p["trim"])
			k.cyl(0.12, 0.9, Color(0.72, 0.74, 0.78), at(-0.05, hy, -1.22), 8, 0.0, 0.55)
			cy(k, 0.57, 0.1, p["metal"].darkened(0.1), Vector3(-0.05, hy + 0.9, -1.22), 8)
			cy(k, 0.5, 0.02, Color(0.94, 0.94, 0.9), Vector3(-0.05, hy + 0.98, -1.22), 8)
			for i in 8:
				var a := TAU * i / 8.0
				bx(k, Vector3(0.12, 0.012, 0.16), Color(0.96, 0.95, 0.9), Vector3(-0.05 + cos(a) * 0.25, hy + 1.0, -1.22 + sin(a) * 0.25), Vector3(0, i * 37.0, 0))
			deck(k, Vector3(-0.62, 0, -1.8), Vector3(0.55, 2.05, -1.62), p["metal"], p["accent"], "b")
			deck(k, Vector3(0.55, 0, -1.8), Vector3(0.92, 2.05, -1.3), p["metal"], p["accent"], "r")
			stair(k, Vector3(0.74, 0.0, -0.5), Vector3(0.74, 2.0, -1.3), 0.3, p["metal"], p["accent"])
			# belt under the hopper to the front
			bb(k, Vector3(-0.55, 0.42, -1.4), Vector3(0.5, 0.5, -1.05), Color(0.2, 0.21, 0.24))
			for i in 7:
				hcy(k, 0.04, 0.36, Color(0.6, 0.62, 0.66), Vector3(-0.5 + i * 0.16, 0.46, -1.22), false, 6)
			for sx in [-0.5, 0.45]:
				bb(k, Vector3(sx - 0.03, 0, -1.25), Vector3(sx + 0.03, 0.42, -1.19), p["dark"])
			k.box(Vector3(0.36, 0.06, 0.9), Color(0.2, 0.21, 0.24), xf(Vector3(0.0, 0.3, -0.62), Vector3(14, 0, 0)))
			for sx in [-0.17, 0.17]:
				k.box(Vector3(0.03, 0.12, 0.9), p["accent"], xf(Vector3(sx, 0.35, -0.62), Vector3(14, 0, 0)))
			bb(k, Vector3(-0.2, 0, -0.3), Vector3(0.2, 0.2, 0.05), p["dark"])
			bb(k, Vector3(-0.15, 0.2, -0.25), Vector3(0.15, 0.32, 0.0), Color(0.3, 0.5, 0.8))
			# a glass sight column with data bubbling up (part)
			cy(k, 0.14, 0.12, p["trim"], Vector3(-0.75, 0, -0.55), 8)
			cy(k, 0.11, 1.5, Color(0.6, 0.86, 1.0, 0.7), Vector3(-0.75, 0.12, -0.55), 10)
			cy(k, 0.14, 0.1, p["trim"], Vector3(-0.75, 1.62, -0.55), 8)
			run(k, [Vector3(-0.75, 1.72, -0.55), Vector3(-0.75, 1.9, -0.55), Vector3(-0.4, 1.9, -0.95)], 0.035, p["metal"])
			# a server rack in a chain-link cage, cable tray overhead, AC
			mesh_fence(k, Vector3(-0.95, 0, -1.85), Vector3(-0.95, 0, -0.95), 1.6)
			rack(k, Vector3(-0.78, 0, -1.6), 1.3, t, 90.0)
			ArchKit.cable_tray(k, Vector3(-1.0, 2.2, -1.0), Vector3(0.5, 2.2, -1.0), t)
			ArchKit.ac_unit(k, at(-0.25, 2.05, -1.7), t, 0.5)
			# sacks of printouts, a hazard stripe
			for i in 3:
				bx(k, Vector3(0.3, 0.2, 0.22), Color(0.92, 0.92, 0.88), Vector3(0.5 - i * 0.02, 0.1 + i * 0.18, -0.25), Vector3(0, i * 20.0, 0))
			bb(k, Vector3(-0.98, 0.03, -0.5), Vector3(0.95, 0.036, -0.46), p["accent"])
		2:
			_wing(k, "refinery", t, -1.0, "plant", 2.3)
			_wing(k, "refinery", t, 1.0, "office", 3.0)
			# a glass atrium holding three white columns that rise through it
			var ah := 2.6
			bb(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, 0.12, -0.5), Color(0.86, 0.88, 0.9))
			ArchKit.curtain(k, at(0, 0.12, -0.5), 1.9, ah - 0.12, t, 5, 2)
			ArchKit.curtain(k, at(0, 0.12, BK + 0.02), 1.9, ah - 0.12, t, 5, 2)
			bb(k, Vector3(-1.0, ah, -1.88), Vector3(1.0, ah + 0.14, -0.48), Color(0.95, 0.95, 0.96))
			bb(k, Vector3(-1.0, ah - 0.08, -0.5), Vector3(1.0, ah, -0.46), p["trim"])
			bb(k, Vector3(-0.9, ah + 0.14, -1.8), Vector3(0.9, ah + 0.16, -0.56), p["roof"])
			for i in 3:
				var x := -0.58 + i * 0.58
				var h: float = [3.6, 4.0, 3.4][i]
				var cc: Color = Color(0.95, 0.95, 0.96) if i != 1 else Color(0.6, 0.86, 1.0, 0.72)
				cy(k, 0.22, h, cc, Vector3(x, 0.12, -1.2), 12)
				for j in int(h / 0.7):
					cy(k, 0.235, 0.05, p["trim"] if i != 1 else Color(0.95, 0.95, 0.96), Vector3(x, 0.5 + j * 0.7, -1.2), 12)
				k.sphere(0.22, Color(0.95, 0.95, 0.96), xf(Vector3(x, h + 0.12, -1.2), Vector3.ZERO, Vector3(1, 0.5, 1)), 12, 5)
				cy(k, 0.03, 0.3, Color(0.7, 0.72, 0.75), Vector3(x, h + 0.2, -1.2), 6)
			for y in [1.6, 2.9]:
				run(k, [Vector3(-0.58, y, -1.0), Vector3(0.58, y, -1.0)], 0.04, Color(0.7, 0.72, 0.75))
			# the data intake: a white hopper on the atrium roof feeding a column
			k.cyl(0.08, 0.35, Color(0.95, 0.95, 0.96), at(0.6, ah + 0.16, -0.75), 8, 0.0, 0.25)
			run(k, [Vector3(0.6, ah + 0.25, -0.75), Vector3(0.6, ah + 0.25, -0.95), Vector3(0.0, ah + 0.25, -0.95)], 0.04, Color(0.85, 0.87, 0.9))
			# a logo totem, planters
			bb(k, Vector3(-0.3, 0, -0.42), Vector3(0.3, 0.12, -0.3), Color(0.86, 0.88, 0.9))
			bb(k, Vector3(-0.15, 0.12, -0.4), Vector3(0.15, 1.1, -0.32), Color(0.97, 0.97, 0.98))
			bb(k, Vector3(-0.1, 0.75, -0.32), Vector3(0.1, 0.95, -0.31), ac)
			bb(k, Vector3(-0.11, 0.5, -0.32), Vector3(0.11, 0.55, -0.31), p["dark"])
			ArchKit.planter(k, Vector3(-0.62, 0, -0.38), t, 0.4)
			ArchKit.planter(k, Vector3(0.62, 0, -0.38), t, 0.4)
		3:
			_wing(k, "refinery", t, -1.0, "stair", 3.2)
			_wing(k, "refinery", t, 1.0, "canopy", 2.7)
			# two distillation towers with platforms and caged ladders
			var towers := [[Vector3(-0.45, 0, -1.3), 0.34, 6.2], [Vector3(0.5, 0, -1.28), 0.27, 5.0]]
			for tw in towers:
				var c: Vector3 = tw[0]
				var r: float = tw[1]
				var h: float = tw[2]
				cy(k, r + 0.06, 0.3, p["dark"], c, 12)
				cy(k, r, h, Color(0.82, 0.84, 0.86), c + Vector3(0, 0.3, 0), 12)
				k.sphere(r, Color(0.82, 0.84, 0.86), xf(c + Vector3(0, h + 0.3, 0), Vector3.ZERO, Vector3(1, 0.45, 1)), 12, 5)
				for j in int(h / 0.55):
					cy(k, r + 0.015, 0.035, p["trim"], c + Vector3(0, 0.6 + j * 0.55, 0), 12)
				for j in 3:
					var py := 1.6 + j * (h - 1.6) / 3.0
					cy(k, r + 0.22, 0.04, p["metal"].darkened(0.2), Vector3(c.x, py, c.z), 10)
					for i in 8:
						var a := TAU * i / 8.0
						bb(k, Vector3(c.x + cos(a) * (r + 0.2) - 0.015, py, c.z + sin(a) * (r + 0.2) - 0.015), Vector3(c.x + cos(a) * (r + 0.2) + 0.015, py + 0.5, c.z + sin(a) * (r + 0.2) + 0.015), p["accent"])
					k.torus(r + 0.2, 0.015, p["accent"], at(c.x, py + 0.5, c.z), 12, 3)
				ArchKit.ladder(k, xf(c + Vector3(0, 0, r + 0.02)), h, p["accent"], true)
				cy(k, 0.04, 0.6, Color(0.6, 0.62, 0.66), c + Vector3(0, h + 0.4, 0), 6)
				bx(k, Vector3(0.02, h * 0.7, 0.02), lit(p["accent2"], 0.4), c + Vector3(-r * 0.7, h * 0.5, r * 0.7))
			# a glass sight column with data rising (part), a reboiler, pipes
			cy(k, 0.15, 0.15, p["trim"], Vector3(0.05, 0, -0.55), 8)
			cy(k, 0.12, 2.0, dat, Vector3(0.05, 0.15, -0.55), 10)
			cy(k, 0.15, 0.12, p["trim"], Vector3(0.05, 2.15, -0.55), 8)
			for sx in [-1.0, 1.0]:
				bb(k, Vector3(0.05 + sx * 0.22 - 0.02, 0, -0.57), Vector3(0.05 + sx * 0.22 + 0.02, 2.2, -0.53), p["trim"])
			hcy(k, 0.16, 0.9, Color(0.8, 0.82, 0.86), Vector3(0.05, 0.45, -0.98), true, 10)
			for sx in [-0.3, 0.3]:
				bb(k, Vector3(0.05 + sx - 0.06, 0, -1.08), Vector3(0.05 + sx + 0.06, 0.3, -0.88), p["dark"])
			run(k, [Vector3(-0.45, 2.8, -1.0), Vector3(-0.45, 2.8, -0.55), Vector3(0.05, 2.8, -0.55), Vector3(0.05, 2.27, -0.55)], 0.05, Color(0.36, 0.6, 0.86))
			run(k, [Vector3(0.5, 2.2, -1.03), Vector3(0.5, 2.2, -0.75), Vector3(0.15, 2.2, -0.62)], 0.04, Color(0.9, 0.5, 0.3))
			# pipe bridge across the front, above the benches' back
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.04, 0, -0.42), Vector3(sx + 0.04, 2.5, -0.34), p["trim"])
			bb(k, Vector3(-0.98, 2.5, -0.44), Vector3(0.98, 2.56, -0.32), p["trim"])
			for i in 4:
				hcy(k, 0.045, 1.96, [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84), Color(0.9, 0.5, 0.3), Color(0.5, 0.78, 0.5)][i], Vector3(0, 2.61, -0.43 + i * 0.033), true, 6)
			bb(k, Vector3(-0.98, 2.4, -0.33), Vector3(0.98, 2.43, -0.31), lit(p["accent2"], 0.45))
			# control room at the foot of the towers
			bb(k, Vector3(-0.95, 0, -0.95), Vector3(-0.2, 1.2, -0.5), p["wall"])
			bb(k, Vector3(-0.9, 0.6, -0.5), Vector3(-0.25, 1.0, -0.48), p["glass"])
			bb(k, Vector3(-0.97, 1.2, -0.97), Vector3(-0.18, 1.28, -0.48), p["trim"])
			ArchKit.ac_unit(k, at(-0.58, 1.28, -0.75), t, 0.5)
		_:
			_wing(k, "refinery", t, -1.0, "podium", 2.3)
			_wing(k, "refinery", t, 1.0, "vault", 2.6)
			# the data-distillation column: glowing glass in a graphite exoskeleton
			var ch := 6.6
			var c := Vector3(0, 0, -1.15)
			cy(k, 0.72, 0.35, p["dark"], c, 12)
			cy(k, 0.74, 0.05, p["trim"], c + Vector3(0, 0.35, 0), 12)
			cy(k, 0.5, 0.25, p["wall2"], c + Vector3(0, 0.4, 0), 12)
			cy(k, 0.42, ch - 0.6, Color(0.5, 0.82, 1.0, 0.6), c + Vector3(0, 0.6, 0), 12)
			for j in 7:
				cy(k, 0.44, 0.06, p["trim"], c + Vector3(0, 1.0 + j * 0.8, 0), 12)
			for i in 6:
				var a := TAU * i / 6.0 + 0.5
				var q := c + Vector3(cos(a) * 0.64, 0, sin(a) * 0.62)
				bb(k, Vector3(q.x - 0.07, 0.35, q.z - 0.07), Vector3(q.x + 0.07, ch - 0.2, q.z + 0.07), p["wall"])
				if i % 2 == 0:
					bb(k, Vector3(q.x - 0.015, 0.6, q.z - 0.015), Vector3(q.x + 0.015, ch - 0.4, q.z + 0.015), lit(p["glow"], 0.4))
				seg(k, q + Vector3(0, ch - 0.35, 0), c + Vector3(cos(a) * 0.44, ch - 0.35, sin(a) * 0.44), 0.04, p["trim"])
			# crown: a brass funnel collecting the web, a beacon
			k.cyl(0.42, 0.6, p["trim"], at(c.x, ch, c.z), 12, 0.0, 0.74)
			cy(k, 0.74, 0.04, lit(p["accent2"], 0.4), c + Vector3(0, ch + 0.6, 0), 12)
			cy(k, 0.66, 0.02, p["dark"], c + Vector3(0, ch + 0.63, 0), 12)
			ArchKit.beacon(k, c + Vector3(0.6, ch + 0.6, 0.0), 0.5)
			# glowing coolant loops out of the wings into the column
			for sx in [-1.0, 1.0]:
				run(k, [Vector3(sx * 1.0, 1.2, -0.6), Vector3(sx * 0.55, 1.2, -0.6), Vector3(sx * 0.4, 1.2, -0.8)], 0.05, lit(p["accent2"], 0.45))
				run(k, [Vector3(sx * 1.0, 2.0, -1.7), Vector3(sx * 0.6, 2.0, -1.7), Vector3(sx * 0.35, 2.0, -1.45)], 0.05, lit(p["glow"], 0.45))
			# a dataset dispenser at the front with a brass hood
			bb(k, Vector3(-0.3, 0, -0.5), Vector3(0.3, 0.9, -0.2), p["wall"])
			bb(k, Vector3(-0.32, 0.9, -0.52), Vector3(0.32, 0.96, -0.18), p["trim"])
			bb(k, Vector3(-0.22, 0.3, -0.2), Vector3(0.22, 0.7, -0.19), dat)
			for i in 4:
				bb(k, Vector3(-0.2 + i * 0.13, 0.32, -0.19), Vector3(-0.17 + i * 0.13, 0.68, -0.18), p["dark"])



# ---------------------------------------------------------------- fine-tune lab

static func _tune_lab(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("tune_lab")
	match t:
		0:
			_wing(k, "tune_lab", t, -1.0, "shed", 1.7)
			_wing(k, "tune_lab", t, 1.0, "lean", 1.6)
			# a plywood wall lined with acoustic foam, a whiteboard of loss curves
			ArchKit.planks(k, at(0, 0, BK + 0.02), 1.96, 1.9, Color(0.72, 0.58, 0.4))
			for i in 6:
				for j in 4:
					var fx := -0.85 + i * 0.22
					var fy := 0.85 + j * 0.24
					bb(k, Vector3(fx - 0.1, fy - 0.11, BK + 0.06), Vector3(fx + 0.1, fy + 0.11, BK + 0.1), Color(0.24, 0.24, 0.27) if (i + j) % 2 == 0 else Color(0.3, 0.3, 0.34))
					bb(k, Vector3(fx - 0.06, fy - 0.02, BK + 0.1), Vector3(fx + 0.06, fy + 0.02, BK + 0.12), Color(0.2, 0.2, 0.22))
			# the desk: two doors on trestles, three monitors, a glowing tower
			var ty := 0.74
			bb(k, Vector3(-0.92, ty - 0.04, -1.8), Vector3(0.6, ty, -1.3), Color(0.82, 0.74, 0.58))
			for sx in [-0.8, 0.45]:
				for sz in [-1.75, -1.35]:
					seg(k, Vector3(sx, ty - 0.04, sz), Vector3(sx + 0.08, 0, sz), 0.035, Color(0.56, 0.42, 0.28))
					seg(k, Vector3(sx, ty - 0.04, sz), Vector3(sx - 0.08, 0, sz), 0.035, Color(0.56, 0.42, 0.28))
			for i in 3:
				var mx := -0.5 + i * 0.36
				var yaw: float = [20.0, 0.0, -20.0][i]
				bb(k, Vector3(mx - 0.03, ty, -1.68), Vector3(mx + 0.03, ty + 0.18, -1.64), Color(0.2, 0.2, 0.22))
				screen(k, xf(Vector3(mx, ty + 0.3, -1.62), Vector3(0, yaw, 0)), 0.32, 0.2, ac if i != 1 else Color(0.5, 0.86, 1.0), 6)
			bb(k, Vector3(-0.3, ty, -1.48), Vector3(0.05, ty + 0.015, -1.38), Color(0.2, 0.2, 0.22))
			bb(k, Vector3(0.38, 0, -1.75), Vector3(0.58, 0.48, -1.35), Color(0.16, 0.16, 0.18))
			bb(k, Vector3(0.375, 0.05, -1.7), Vector3(0.38, 0.43, -1.4), lit(Color(0.9, 0.4, 1.0), 0.4))
			bb(k, Vector3(0.44, 0.1, -1.349), Vector3(0.52, 0.38, -1.345), lit(ac, 0.45))
			for sx in [-0.85, 0.5]:
				bb(k, Vector3(sx - 0.05, ty, -1.75), Vector3(sx + 0.05, ty + 0.18, -1.65), Color(0.2, 0.2, 0.22))
				cy(k, 0.03, 0.01, Color(0.4, 0.4, 0.42), Vector3(sx, ty + 0.12, -1.649) , 6)
			for i in 4:
				cy(k, 0.025, 0.09, [Color(0.3, 0.8, 0.4), Color(0.9, 0.3, 0.25), Color(0.3, 0.5, 0.9), Color(0.95, 0.8, 0.2)][i], Vector3(-0.7 + i * 0.06, ty, -1.42), 6)
			# a whiteboard on an easel, a mini fridge, pizza boxes, a rug
			for sx in [-1.0, 1.0]:
				seg(k, Vector3(0.35 + sx * 0.25, 0, -0.95), Vector3(0.35 + sx * 0.2, 1.5, -1.0), 0.03, Color(0.56, 0.42, 0.28))
			seg(k, Vector3(0.35, 0, -0.75), Vector3(0.35, 1.45, -1.0), 0.03, Color(0.56, 0.42, 0.28))
			k.box(Vector3(0.62, 0.44, 0.03), Color(0.97, 0.97, 0.96), xf(Vector3(0.35, 1.15, -0.98), Vector3(-6, 0, 0)))
			for i in 5:
				seg(k, Vector3(0.1 + i * 0.1, 1.28 - [0.0, 0.1, 0.16, 0.2, 0.21][i], -0.955), Vector3(0.2 + i * 0.1, 1.28 - [0.1, 0.16, 0.2, 0.21, 0.22][i], -0.955), 0.012, Color(0.9, 0.3, 0.25))
			bb(k, Vector3(-0.92, 0, -1.25), Vector3(-0.62, 0.55, -0.95), Color(0.92, 0.92, 0.9))
			bb(k, Vector3(-0.9, 0.3, -0.95), Vector3(-0.64, 0.31, -0.94), Color(0.6, 0.6, 0.6))
			for i in 3:
				bx(k, Vector3(0.3, 0.04, 0.3), Color(0.84, 0.74, 0.56), Vector3(-0.77, 0.57 + i * 0.045, -1.1), Vector3(0, i * 9.0, 0))
			bx(k, Vector3(1.1, 0.01, 0.75), Color(0.66, 0.3, 0.26), Vector3(-0.1, 0.035, -1.05), Vector3(0, 4, 0))
			bx(k, Vector3(0.9, 0.012, 0.55), Color(0.86, 0.6, 0.3), Vector3(-0.1, 0.037, -1.05), Vector3(0, 4, 0))
			# a timber pergola with slats (open to the sky), string lights
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.04, 0, -0.85), Vector3(sx + 0.04, 2.0, -0.77), Color(0.5, 0.36, 0.24))
			bb(k, Vector3(-0.98, 2.0, -0.86), Vector3(0.98, 2.1, -0.76), Color(0.5, 0.36, 0.24))
			bb(k, Vector3(-0.98, 2.0, BK + 0.02), Vector3(0.98, 2.1, BK + 0.12), Color(0.5, 0.36, 0.24))
			for i in 8:
				bb(k, Vector3(-0.9 + i * 0.257 - 0.025, 2.1, BK), Vector3(-0.9 + i * 0.257 + 0.025, 2.17, -0.72), Color(0.6, 0.46, 0.3))
			ArchKit.string_lights(k, Vector3(-0.95, 1.95, -0.78), Vector3(0.95, 1.95, -0.78), 9, Color(1.0, 0.7, 0.4))
			cord(k, [Vector2(-1.0, -0.42), Vector2(-0.6, -0.6), Vector2(-0.2, -0.9), Vector2(0.4, -1.3)], Color(0.92, 0.5, 0.18))
			# the speaker cabinet out front (the knob of the tuning dial is the part)
			bb(k, Vector3(-0.22, 0, -0.4), Vector3(0.22, 0.6, -0.05), Color(0.3, 0.24, 0.2))
			k.cyl(0.12, 0.02, Color(0.15, 0.15, 0.16), xf(Vector3(0, 0.32, -0.05), Vector3(90, 0, 0)), 10)
			k.cyl(0.05, 0.02, Color(0.15, 0.15, 0.16), xf(Vector3(0, 0.5, -0.05), Vector3(90, 0, 0)), 8)
			bb(k, Vector3(-0.2, 0.6, -0.38), Vector3(0.2, 0.62, -0.07), Color(0.5, 0.38, 0.28))
		1:
			_wing(k, "tune_lab", t, -1.0, "container", 1.3)
			_wing(k, "tune_lab", t, 1.0, "cage", 1.9)
			# a steel control booth: big window, monitor wall inside, AC on top
			var bh := 2.2
			bb(k, Vector3(-0.95, 0, -1.86), Vector3(0.95, bh, -0.8), p["wall"])
			ArchKit.corrugated(k, at(0, 0, BK), 1.9, bh, p["wall2"], 0.14)
			bb(k, Vector3(-0.97, bh, -1.88), Vector3(0.97, bh + 0.1, -0.78), p["trim"])
			bb(k, Vector3(-0.85, 0.85, -0.8), Vector3(0.85, 1.85, -0.78), Color(0.12, 0.12, 0.14))
			for i in 4:
				for j in 2:
					screen(k, at(-0.63 + i * 0.42, 1.1 + j * 0.48, -0.77), 0.36, 0.38, ac if (i + j) % 2 == 0 else Color(0.5, 0.86, 1.0), 5)
			bb(k, Vector3(-0.88, 0.8, -0.8), Vector3(0.88, 0.85, -0.7), p["trim"])
			bb(k, Vector3(-0.88, 1.85, -0.8), Vector3(0.88, 1.9, -0.72), p["trim"])
			for sx in [-0.88, 0.88]:
				bb(k, Vector3(sx - 0.03, 0.8, -0.8), Vector3(sx + 0.03, 1.9, -0.74), p["trim"])
			ArchKit.ac_unit(k, at(-0.45, bh + 0.1, -1.4), t, 0.8)
			ArchKit.ac_unit(k, at(0.45, bh + 0.1, -1.4), t, 0.8)
			ArchKit.cable_tray(k, Vector3(-0.9, bh + 0.15, -0.95), Vector3(0.9, bh + 0.15, -0.95), t)
			# the satellite dish bracket on the booth (dish is on the cage)
			k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.16, 0.03), Vector2(0.3, 0.1), Vector2(0.29, 0.1), Vector2(0.15, 0.04), Vector2(0, 0.015)]), Color(0.92, 0.92, 0.92), xf(Vector3(0.0, bh + 0.5, -1.45), Vector3(-55, 0, 0)), 10)
			cy(k, 0.025, 0.4, Color(0.6, 0.62, 0.66), Vector3(0.0, bh + 0.1, -1.5), 6)
			# the mixing console out front: sloped desk, faders, the big dial
			bb(k, Vector3(-0.33, 0, -0.72), Vector3(0.33, 0.62, -0.25), Color(0.3, 0.32, 0.36))
			k.box(Vector3(0.66, 0.05, 0.5), Color(0.2, 0.21, 0.24), xf(Vector3(0, 0.68, -0.48), Vector3(-18, 0, 0)))
			for i in 8:
				var fx := -0.28 + i * 0.065
				k.box(Vector3(0.012, 0.012, 0.22), Color(0.1, 0.1, 0.12), xf(Vector3(fx, 0.715, -0.55), Vector3(-18, 0, 0)))
				k.box(Vector3(0.04, 0.03, 0.03), lit(ac, 0.45) if i % 2 == 0 else Color(0.9, 0.9, 0.9), xf(Vector3(fx, 0.725, -0.6 + (i * 37 % 7) * 0.025), Vector3(-18, 0, 0)))
			for i in 6:
				k.box(Vector3(0.03, 0.03, 0.03), lit([Color(0.4, 1.0, 0.5), Color(1.0, 0.75, 0.3), Color(1.0, 0.3, 0.25)][i % 3], 0.4), xf(Vector3(-0.28 + i * 0.05, 0.76, -0.68), Vector3(-18, 0, 0)))
			screen(k, xf(Vector3(0.22, 0.88, -0.7), Vector3(-10, 0, 0)), 0.18, 0.12, ac, 4)
			cy(k, 0.025, 0.25, Color(0.3, 0.32, 0.36), Vector3(-0.2, 0.62, -0.72), 5)
			k.sphere(0.04, Color(0.2, 0.2, 0.22), at(-0.2, 0.9, -0.72), 6, 4)
			# a stool, yellow floor tape, a tool trolley
			cy(k, 0.1, 0.04, Color(0.2, 0.2, 0.22), Vector3(-0.6, 0.55, -0.45), 8)
			cy(k, 0.02, 0.55, Color(0.5, 0.52, 0.56), Vector3(-0.6, 0, -0.45), 5)
			bb(k, Vector3(-0.95, 0.03, -0.72), Vector3(0.95, 0.036, -0.68), p["accent"])
			bb(k, Vector3(0.5, 0.05, -0.75), Vector3(0.85, 0.75, -0.5), p["accent2"])
			for j in 3:
				bb(k, Vector3(0.52, 0.2 + j * 0.2, -0.5), Vector3(0.83, 0.21 + j * 0.2, -0.49), p["dark"])
		2:
			_wing(k, "tune_lab", t, -1.0, "glass", 2.5)
			_wing(k, "tune_lab", t, 1.0, "office", 3.0)
			# the studio: two storeys under a sawtooth roof, a big screen facade
			var sh := 2.9
			ArchKit.block(k, Vector3(0, 0, -1.17), Vector3(1.96, sh, 1.42), t, "", 2)
			for i in 3:
				var z0 := -1.85 + i * 0.47
				var tooth := xf(Vector3(0, sh + 0.25, z0 + 0.235), Vector3(-28, 0, 0))
				k.box(Vector3(1.9, 0.04, 0.53), Color(0.92, 0.93, 0.94), tooth)
				bb(k, Vector3(-0.95, sh, z0 - 0.01), Vector3(0.95, sh + 0.5, z0 + 0.02), p["glass"])
				for j in 6:
					bb(k, Vector3(-0.95 + j * 0.38 - 0.015, sh, z0 - 0.02), Vector3(-0.95 + j * 0.38 + 0.015, sh + 0.5, z0 + 0.03), p["frame"])
			# the screen facade, glowing with a loss curve
			bb(k, Vector3(-0.85, 1.55, WF), Vector3(0.85, 2.75, WF + 0.06), Color(0.14, 0.15, 0.18))
			bb(k, Vector3(-0.8, 1.6, WF + 0.06), Vector3(0.8, 2.7, WF + 0.07), lit(ac.darkened(0.3), 0.6))
			for i in 10:
				var y := 2.55 - 0.8 * (1.0 - exp(-i * 0.4))
				var y2 := 2.55 - 0.8 * (1.0 - exp(-(i + 1) * 0.4))
				seg(k, Vector3(-0.72 + i * 0.145, y, WF + 0.08), Vector3(-0.72 + (i + 1) * 0.145, y2, WF + 0.08), 0.03, lit(Color(1.0, 0.95, 0.85), 0.35))
			bb(k, Vector3(-0.98, 1.42, WF), Vector3(0.98, 1.5, WF + 0.1), p["trim"])
			# a glass entrance with a canopy
			bb(k, Vector3(-0.55, 0.0, WF), Vector3(0.55, 1.2, WF + 0.03), p["glass"])
			for i in 5:
				bb(k, Vector3(-0.55 + i * 0.275 - 0.015, 0, WF + 0.02), Vector3(-0.55 + i * 0.275 + 0.015, 1.2, WF + 0.05), p["frame"])
			bb(k, Vector3(-0.6, 1.25, WF), Vector3(0.6, 1.3, WF + 0.14), Color(0.95, 0.95, 0.96))
			bb(k, Vector3(-0.4, 1.31, WF + 0.05), Vector3(0.4, 1.39, WF + 0.07), ac)
			# the rooftop dish plinth (dish is the part) and plant
			bb(k, Vector3(0.35, sh + 0.55, -1.05), Vector3(0.85, sh + 0.7, -0.6), p["wall2"])
			cy(k, 0.06, 0.35, Color(0.7, 0.72, 0.75), Vector3(0.6, sh + 0.7, -0.82), 8)
			ArchKit.ac_unit(k, at(-0.55, sh + 0.55, -0.82), t, 0.6)
			for i in 2:
				ArchKit.planter(k, Vector3(-0.72 + i * 1.44, 0, -0.35), t, 0.36)
		3:
			_wing(k, "tune_lab", t, -1.0, "annex", 3.1)
			_wing(k, "tune_lab", t, 1.0, "stair", 3.3)
			# the control hall: steel frame, a glazed control room band, louvres
			var hh := 3.5
			bb(k, Vector3(-0.96, 0, -1.86), Vector3(0.96, hh, -0.6), p["wall"])
			ArchKit.louvres(k, at(0, 0.2, -0.6), 1.8, 1.2, p["metal"], 10)
			bb(k, Vector3(-0.96, 1.55, -0.6), Vector3(0.96, 2.75, -0.42), p["dark"])
			bb(k, Vector3(-0.9, 1.65, -0.42), Vector3(0.9, 2.65, -0.4), p["glass"])
			for i in 6:
				screen(k, at(-0.75 + i * 0.3, 2.0, -0.39), 0.24, 0.3, ac if i % 2 == 0 else Color(0.5, 0.86, 1.0), 4)
			for i in 7:
				bb(k, Vector3(-0.9 + i * 0.3 - 0.02, 1.6, -0.42), Vector3(-0.9 + i * 0.3 + 0.02, 2.7, -0.39), p["trim"])
			bb(k, Vector3(-0.98, 2.75, -0.62), Vector3(0.98, 2.82, -0.36), p["trim"])
			bb(k, Vector3(-0.98, 1.52, -0.44), Vector3(0.98, 1.55, -0.36), lit(p["accent2"], 0.45))
			bb(k, Vector3(-0.98, hh, -1.88), Vector3(0.98, hh + 0.15, -0.58), p["trim"])
			bb(k, Vector3(-0.92, hh + 0.15, -1.82), Vector3(0.92, hh + 0.17, -0.64), p["roof"])
			# roof trusses and a lattice mast carrying the big dish (part)
			for i in 3:
				ArchKit.truss(k, Vector3(-0.92, hh + 0.35, -1.7 + i * 0.5), Vector3(0.92, hh + 0.35, -1.7 + i * 0.5), 0.18, p["trim"])
			var mb := Vector3(0, hh + 0.17, -1.2)
			for q in [Vector2(-0.25, -0.25), Vector2(0.25, -0.25), Vector2(-0.25, 0.25), Vector2(0.25, 0.25)]:
				seg(k, mb + Vector3(q.x, 0, q.y), mb + Vector3(q.x * 0.3, 1.5, q.y * 0.3), 0.05, p["trim"])
			for j in 3:
				var f := 0.25 + j * 0.25
				var r := 0.25 * (1.0 - f * 0.7)
				bb(k, mb + Vector3(-r, f * 1.5 - 0.02, -r), mb + Vector3(r, f * 1.5 + 0.02, r), p["trim"])
			cy(k, 0.1, 0.12, p["dark"], mb + Vector3(0, 1.5, 0), 8)
			ArchKit.beacon(k, Vector3(-0.85, hh + 0.17, -0.7), 0.4)
			# generators in front of the hall's flanks
			for sx in [-0.62, 0.62]:
				bb(k, Vector3(sx - 0.25, 0, -0.58), Vector3(sx + 0.25, 0.55, -0.32), Color(0.36, 0.4, 0.46))
				ArchKit.louvres(k, at(sx, 0.08, -0.32), 0.4, 0.38, Color(0.3, 0.33, 0.38), 5)
				bx(k, Vector3(0.1, 0.06, 0.01), lit(p["glow"], 0.4), Vector3(sx + 0.15, 0.48, -0.31))
		_:
			_wing(k, "tune_lab", t, -1.0, "fin", 3.4)
			_wing(k, "tune_lab", t, 1.0, "podium", 2.2)
			# a graphite drum with brass ribs, a glowing dome, a holo ring (part)
			var c := Vector3(0, 0, -1.02)
			var dh := 2.8
			cy(k, 0.86, 0.3, p["dark"], c, 8)
			cy(k, 0.8, dh, p["wall"], c + Vector3(0, 0.3, 0), 8)
			for i in 8:
				var a := TAU * (i + 0.5) / 8.0
				var q := c + Vector3(cos(a) * 0.78, 0, sin(a) * 0.78)
				bx(k, Vector3(0.08, dh + 0.2, 0.08), p["trim"], q + Vector3(0, 0.3 + dh * 0.5, 0), Vector3(0, -rad_to_deg(a), 0))
				if sin(a) > 0.0:
					bx(k, Vector3(0.025, dh - 0.4, 0.025), lit(p["glow"], 0.4), c + Vector3(cos(a + 0.39) * 0.75, 0.3 + dh * 0.5, sin(a + 0.39) * 0.75))
			for y in [1.2, 2.2]:
				cy(k, 0.83, 0.06, p["trim"], c + Vector3(0, y, 0), 8)
			cy(k, 0.84, 0.05, lit(ac, 0.4), c + Vector3(0, 1.7, 0), 8)
			cy(k, 0.86, 0.1, p["trim"], c + Vector3(0, dh + 0.3, 0), 8)
			var dc := c + Vector3(0, dh + 0.4, 0)
			k.sphere(0.72, p["glass"], xf(dc, Vector3.ZERO, Vector3(1, 0.8, 1)), 12, 7)
			k.sphere(0.44, lit(ac, 0.35), xf(dc, Vector3.ZERO, Vector3(1, 0.9, 1)), 10, 6)
			for i in 4:
				k.torus(0.73, 0.025, p["trim"], xf(dc, Vector3(90, i * 45.0, 0), Vector3(1, 1, 0.8)), 16, 3, PI)
			for j in 2:
				k.torus(0.69 - j * 0.17, 0.018, lit(ac, 0.4), xf(dc + Vector3(0, 0.25 + j * 0.2, 0), Vector3.ZERO, Vector3(1, 1, 1)), 16, 3)
			cy(k, 0.06, 0.5, p["trim"], dc + Vector3(0, 0.62, 0), 8)
			ArchKit.beacon(k, dc + Vector3(0, 1.1, 0), 0.25)
			# an entrance tunnel at the front with brass portal
			bb(k, Vector3(-0.32, 0, -0.24), Vector3(0.32, 1.1, 0.02), p["wall2"])
			bb(k, Vector3(-0.34, 1.1, -0.26), Vector3(0.34, 1.18, 0.04), p["trim"])
			for sx in [-0.3, 0.3]:
				bb(k, Vector3(sx - 0.03, 0, -0.01), Vector3(sx + 0.03, 1.1, 0.03), p["trim"])
			bb(k, Vector3(-0.22, 0.05, 0.02), Vector3(0.22, 0.95, 0.03), lit(ac, 0.5))
			# glowing coolant loops around the drum's foot
			for sx in [-1.0, 1.0]:
				run(k, [Vector3(sx * 1.0, 0.5, -0.6), Vector3(sx * 0.7, 0.5, -0.5), Vector3(sx * 0.5, 0.5, -0.4)], 0.045, lit(p["accent2"], 0.45))



# ---------------------------------------------------------------- HBM works

static func _hbm_works(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("hbm_works")
	var chip := Color(0.16, 0.17, 0.2)
	match t:
		0:
			_wing(k, "hbm_works", t, -1.0, "lean", 1.7)
			_wing(k, "hbm_works", t, 1.0, "shed", 1.8)
			# a heavy timber bench with the arbor press, a vise and chip trays
			var ty := 0.78
			bb(k, Vector3(-0.85, ty - 0.1, -1.8), Vector3(0.75, ty, -1.15), Color(0.6, 0.44, 0.28))
			for q in [Vector2(-0.8, -1.75), Vector2(0.7, -1.75), Vector2(-0.8, -1.2), Vector2(0.7, -1.2)]:
				bb(k, Vector3(q.x - 0.05, 0, q.y - 0.05), Vector3(q.x + 0.05, ty - 0.1, q.y + 0.05), Color(0.5, 0.36, 0.24))
			bb(k, Vector3(-0.8, 0.2, -1.75), Vector3(0.7, 0.24, -1.2), Color(0.56, 0.42, 0.28))
			for i in 4:
				bb(k, Vector3(-0.7 + i * 0.32, 0.24, -1.7), Vector3(-0.45 + i * 0.32, 0.4, -1.3), [Color(0.78, 0.26, 0.22), Color(0.3, 0.32, 0.36), Color(0.72, 0.58, 0.4), Color(0.3, 0.5, 0.8)][i])
			# the arbor press: base, column, head; the ram + lever are the part
			bb(k, Vector3(-0.35, ty, -1.65), Vector3(0.05, ty + 0.08, -1.3), Color(0.26, 0.3, 0.36))
			bb(k, Vector3(-0.3, ty + 0.08, -1.65), Vector3(-0.2, ty + 0.75, -1.55), Color(0.26, 0.3, 0.36))
			bb(k, Vector3(-0.32, ty + 0.75, -1.66), Vector3(0.02, ty + 0.95, -1.4), Color(0.26, 0.3, 0.36))
			bb(k, Vector3(-0.2, ty + 0.08, -1.48), Vector3(-0.06, ty + 0.12, -1.36), Color(0.6, 0.62, 0.66))
			for i in 4:
				bb(k, Vector3(-0.17, ty + 0.12 + i * 0.012, -1.46), Vector3(-0.09, ty + 0.13 + i * 0.012, -1.38), chip if i % 2 == 0 else ac)
			bb(k, Vector3(-0.31, ty + 0.4, -1.551), Vector3(-0.21, ty + 0.46, -1.549), Color(0.98, 0.84, 0.3))
			# a vise, trays of dies, RAM sticks in a rack, a hot plate
			bb(k, Vector3(0.45, ty, -1.35), Vector3(0.68, ty + 0.12, -1.2), Color(0.3, 0.42, 0.62))
			bb(k, Vector3(0.5, ty + 0.12, -1.33), Vector3(0.63, ty + 0.2, -1.29), Color(0.3, 0.42, 0.62))
			seg(k, Vector3(0.56, ty + 0.06, -1.15), Vector3(0.56, ty + 0.06, -1.05), 0.015, Color(0.7, 0.72, 0.75))
			for i in 2:
				bb(k, Vector3(0.12 + i * 0.25, ty, -1.7), Vector3(0.32 + i * 0.25, ty + 0.02, -1.5), Color(0.2, 0.3, 0.6))
				for j in 3:
					for m in 2:
						bb(k, Vector3(0.14 + i * 0.25 + j * 0.06, ty + 0.02, -1.68 + m * 0.09), Vector3(0.18 + i * 0.25 + j * 0.06, ty + 0.035, -1.62 + m * 0.09), chip)
			for i in 8:
				bb(k, Vector3(-0.75 + i * 0.04, ty, -1.75), Vector3(-0.735 + i * 0.04, ty + 0.12, -1.6), Color(0.2, 0.5, 0.3))
				bb(k, Vector3(-0.75 + i * 0.04, ty + 0.06, -1.6), Vector3(-0.735 + i * 0.04, ty + 0.08, -1.599), Color(0.85, 0.7, 0.3))
			bb(k, Vector3(0.12, ty, -1.42), Vector3(0.34, ty + 0.05, -1.22), Color(0.86, 0.86, 0.84))
			cy(k, 0.08, 0.008, lit(Color(1.0, 0.4, 0.2), 0.4), Vector3(0.23, ty + 0.05, -1.32), 8)
			# a pegboard of spanners, a tin roof on posts
			bb(k, Vector3(-0.9, 1.0, BK + 0.02), Vector3(0.8, 1.7, BK + 0.05), Color(0.76, 0.64, 0.46))
			for i in 10:
				bx(k, Vector3(0.025, 0.12 + (i % 4) * 0.04, 0.015), Color(0.62, 0.64, 0.68), Vector3(-0.8 + i * 0.17, 1.35, BK + 0.06), Vector3(0, 0, (i % 3) * 12 - 12))
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.04, 0, -0.9), Vector3(sx + 0.04, 2.0, -0.82), Color(0.5, 0.36, 0.24))
				bb(k, Vector3(sx - 0.04, 0, BK), Vector3(sx + 0.04, 2.2, BK + 0.08), Color(0.5, 0.36, 0.24))
			var roof := xf(Vector3(0, 2.15, -1.36), Vector3(-10, 0, 0))
			k.box(Vector3(2.0, 0.03, 1.0), Color(0.62, 0.64, 0.66), roof)
			for i in 12:
				k.box(Vector3(0.025, 0.025, 1.0), Color(0.52, 0.54, 0.56), roof * at(-0.95 + i * 0.173, 0.025, 0))
			bx(k, Vector3(0.14, 0.08, 0.14), lit(p["glow"], 0.3), Vector3(0, 1.98, -0.95))
			# an oil drum, an anvil out front on a stump, a cord
			drum(k, Vector3(0.62, 0, -0.75), Color(0.3, 0.36, 0.56), 0.15, 0.48)
			cy(k, 0.17, 0.4, Color(0.56, 0.42, 0.28), Vector3(0, 0, -0.22), 8)
			bb(k, Vector3(-0.15, 0.4, -0.3), Vector3(0.15, 0.5, -0.14), Color(0.25, 0.26, 0.28))
			bb(k, Vector3(0.15, 0.44, -0.27), Vector3(0.25, 0.5, -0.17), Color(0.25, 0.26, 0.28))
			bb(k, Vector3(-0.08, 0.5, -0.27), Vector3(0.08, 0.53, -0.17), Color(0.4, 0.42, 0.44))
			cord(k, [Vector2(1.0, -0.42), Vector2(0.6, -0.55), Vector2(0.3, -0.95), Vector2(0.2, -1.15)], Color(0.92, 0.5, 0.18))
			for i in 4:
				bx(k, Vector3(0.2, 0.012, 0.12), Color(0.7, 0.72, 0.74), Vector3(-0.6 + i * 0.07, 0.04 + i * 0.012, -0.55), Vector3(0, i * 20.0, 0))
		1:
			_wing(k, "hbm_works", t, -1.0, "shed_steel", 2.1)
			_wing(k, "hbm_works", t, 1.0, "container", 1.25)
			# a yellow H-frame hydraulic press, cylinder on top (platen = part)
			var yc: Color = p["accent"]
			for sx in [-0.42, 0.42]:
				bb(k, Vector3(sx - 0.09, 0, -1.25), Vector3(sx + 0.09, 2.3, -0.95), yc)
				bb(k, Vector3(sx - 0.12, 0, -1.3), Vector3(sx + 0.12, 0.1, -0.9), yc.darkened(0.2))
				for j in 4:
					bb(k, Vector3(sx - 0.1, 0.3 + j * 0.5, -1.26), Vector3(sx + 0.1, 0.33 + j * 0.5, -0.94), yc.darkened(0.15))
			bb(k, Vector3(-0.55, 2.3, -1.3), Vector3(0.55, 2.6, -0.9), yc)
			bb(k, Vector3(-0.35, 0.1, -1.25), Vector3(0.35, 0.6, -0.95), yc.darkened(0.1))
			bb(k, Vector3(-0.3, 0.6, -1.22), Vector3(0.3, 0.66, -0.98), Color(0.5, 0.52, 0.56))
			for i in 4:
				bb(k, Vector3(-0.12, 0.66 + i * 0.03, -1.16), Vector3(0.12, 0.69 + i * 0.03, -1.04), chip if i % 2 == 0 else ac)
			cy(k, 0.16, 0.5, Color(0.6, 0.62, 0.66), Vector3(0, 2.6, -1.1), 10)
			cy(k, 0.18, 0.06, yc.darkened(0.2), Vector3(0, 3.1, -1.1), 10)
			bb(k, Vector3(-0.5, 2.4, -0.9), Vector3(0.5, 2.5, -0.89), Color(0.15, 0.15, 0.16))
			for i in 6:
				bb(k, Vector3(-0.5 + i * 0.18, 2.4, -0.889), Vector3(-0.42 + i * 0.18, 2.5, -0.885), yc)
			# the hydraulic power unit with hoses, a gauge, a guard fence
			bb(k, Vector3(-0.9, 0, -1.8), Vector3(-0.45, 0.5, -1.45), Color(0.3, 0.42, 0.62))
			hcy(k, 0.1, 0.3, Color(0.3, 0.32, 0.36), Vector3(-0.68, 0.62, -1.62), true, 8)
			cy(k, 0.05, 0.02, Color(0.95, 0.95, 0.92), Vector3(-0.55, 0.5, -1.45), 8)
			cable(k, Vector3(-0.5, 0.45, -1.5), Vector3(-0.1, 2.85, -1.2), Color(0.15, 0.15, 0.16), -0.2, 0.03)
			cable(k, Vector3(-0.55, 0.45, -1.48), Vector3(0.1, 2.7, -1.25), Color(0.15, 0.15, 0.16), -0.25, 0.03)
			mesh_fence(k, Vector3(-0.7, 0, -0.75), Vector3(-0.35, 0, -0.75), 1.2)
			mesh_fence(k, Vector3(0.35, 0, -0.75), Vector3(0.7, 0, -0.75), 1.2)
			# a gantry crane over the bay: two A-frames, a beam, a hoist
			for sx in [-0.92, 0.92]:
				seg(k, Vector3(sx, 0, -1.85), Vector3(sx, 2.9, -1.55), 0.07, yc)
				seg(k, Vector3(sx, 0, -1.25), Vector3(sx, 2.9, -1.55), 0.07, yc)
				bb(k, Vector3(sx - 0.05, 0, -1.9), Vector3(sx + 0.05, 0.08, -1.2), yc.darkened(0.2))
			bb(k, Vector3(-0.98, 2.9, -1.62), Vector3(0.98, 3.05, -1.48), yc)
			bb(k, Vector3(0.38, 2.75, -1.65), Vector3(0.58, 2.9, -1.45), Color(0.3, 0.32, 0.36))
			seg(k, Vector3(0.48, 2.75, -1.55), Vector3(0.48, 1.6, -1.55), 0.015, Color(0.2, 0.2, 0.22))
			bb(k, Vector3(0.44, 1.5, -1.58), Vector3(0.52, 1.6, -1.52), Color(0.9, 0.3, 0.2))
			# a die rack with steel blocks, the press control pendant
			for j in 3:
				bb(k, Vector3(0.5, 0.15 + j * 0.35, -0.85), Vector3(0.9, 0.18 + j * 0.35, -0.5), p["accent2"])
				for i in 3:
					bb(k, Vector3(0.54 + i * 0.12, 0.18 + j * 0.35, -0.8), Vector3(0.63 + i * 0.12, 0.28 + j * 0.35, -0.6), Color(0.56, 0.58, 0.62))
			for sx in [0.52, 0.88]:
				bb(k, Vector3(sx - 0.02, 0, -0.85), Vector3(sx + 0.02, 1.0, -0.82), p["accent2"])
			bb(k, Vector3(-0.15, 0, -0.42), Vector3(0.15, 0.95, -0.2), Color(0.86, 0.87, 0.88))
			bb(k, Vector3(-0.1, 0.65, -0.2), Vector3(0.1, 0.85, -0.19), Color(0.2, 0.2, 0.22))
			for i in 2:
				k.cyl(0.035, 0.03, [Color(0.3, 0.9, 0.4), Color(0.9, 0.25, 0.2)][i], xf(Vector3(-0.05 + i * 0.1, 0.5, -0.2), Vector3(90, 0, 0)), 6)
			bb(k, Vector3(-0.95, 0.03, -0.78), Vector3(0.95, 0.036, -0.74), yc)
		2:
			_wing(k, "hbm_works", t, -1.0, "office", 2.9)
			_wing(k, "hbm_works", t, 1.0, "glass", 2.4)
			# the stacking cell: a white block with a layered facade
			var sh := 2.7
			ArchKit.block(k, Vector3(0, 0, -1.25), Vector3(1.96, sh, 1.26), t, "", 1)
			for i in 6:
				var y := 0.3 + i * 0.38
				bb(k, Vector3(-0.98, y, -0.62), Vector3(0.98, y + 0.26, -0.58), [Color(0.86, 0.9, 0.97), Color(0.95, 0.95, 0.96), Color(0.74, 0.8, 0.9)][i % 3])
				bb(k, Vector3(-0.98, y + 0.26, -0.62), Vector3(0.98, y + 0.3, -0.57), lit(ac, 0.5) if i % 2 == 0 else p["trim"])
			# a white C-frame stacker out front: column, arm, platen (part)
			bb(k, Vector3(-0.3, 0, -0.58), Vector3(0.3, 0.2, -0.22), Color(0.9, 0.91, 0.92))
			bb(k, Vector3(-0.12, 0.2, -0.58), Vector3(0.12, 2.4, -0.46), Color(0.95, 0.95, 0.96))
			bb(k, Vector3(-0.14, 2.4, -0.6), Vector3(0.14, 2.62, -0.2), Color(0.95, 0.95, 0.96))
			bb(k, Vector3(-0.145, 2.45, -0.21), Vector3(0.145, 2.5, -0.19), p["trim"])
			cy(k, 0.1, 0.65, Color(0.94, 0.94, 0.95), Vector3(0, 0.2, -0.32), 10)
			cy(k, 0.12, 0.04, p["trim"], Vector3(0, 0.85, -0.32), 10)
			for i in 6:
				bb(k, Vector3(-0.08, 0.89 + i * 0.03, -0.38), Vector3(0.08, 0.915 + i * 0.03, -0.26), chip if i % 2 == 0 else lit(ac, 0.5))
			stack_light(k, Vector3(0.18, 0.2, -0.52), 0.6)
			# rooftop: a wafer store, a chiller, a stair hatch, logo sign
			ArchKit.chiller(k, at(-0.3, sh + 0.03, -1.3), 1.2, t, 2)
			bb(k, Vector3(0.35, sh, -1.6), Vector3(0.85, sh + 0.55, -1.1), Color(0.92, 0.93, 0.94))
			ArchKit.louvres(k, at(0.6, sh + 0.12, -1.1), 0.4, 0.3, Color(0.82, 0.84, 0.86), 4)
			bb(k, Vector3(-0.55, sh + 0.25, -0.65), Vector3(0.55, sh + 0.6, -0.6), Color(0.97, 0.97, 0.98))
			for i in 4:
				bb(k, Vector3(-0.48, sh + 0.3 + i * 0.07, -0.6), Vector3(-0.28, sh + 0.35 + i * 0.07, -0.59), chip if i % 2 == 0 else ac)
			bb(k, Vector3(-0.2, sh + 0.38, -0.6), Vector3(0.45, sh + 0.47, -0.59), p["dark"])
			for sx in [-0.45, 0.45]:
				bb(k, Vector3(sx - 0.02, sh, -0.64), Vector3(sx + 0.02, sh + 0.25, -0.61), Color(0.7, 0.72, 0.75))
			ArchKit.planter(k, Vector3(-0.68, 0, -0.38), t, 0.4)
			ArchKit.planter(k, Vector3(0.68, 0, -0.38), t, 0.4)
		3:
			_wing(k, "hbm_works", t, -1.0, "canopy", 2.7)
			_wing(k, "hbm_works", t, 1.0, "annex", 3.0)
			# the press hall: an open steel frame, crane rail, the big 4-post press
			var hh := 4.0
			for q in [Vector2(-0.95, -1.84), Vector2(0.95, -1.84), Vector2(-0.95, -0.55), Vector2(0.95, -0.55)]:
				bb(k, Vector3(q.x - 0.06, 0, q.y - 0.06), Vector3(q.x + 0.06, hh, q.y + 0.06), p["trim"])
			ArchKit.corrugated(k, at(0, 0, BK), 1.9, hh, p["wall2"], 0.14)
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.03, 2.4, -1.84), Vector3(sx + 0.03, hh, -0.55), p["glass"])
				for i in 3:
					bb(k, Vector3(sx - 0.04, 2.4, -1.8 + i * 0.6), Vector3(sx + 0.04, hh, -1.76 + i * 0.6), p["trim"])
			for z in [-1.84, -0.55]:
				bb(k, Vector3(-1.0, hh - 0.25, z - 0.06), Vector3(1.0, hh, z + 0.06), p["trim"])
			ArchKit.truss(k, Vector3(-0.95, hh - 0.05, -1.2), Vector3(0.95, hh - 0.05, -1.2), 0.2, p["trim"])
			bb(k, Vector3(-1.0, hh, -1.9), Vector3(1.0, hh + 0.08, -0.5), p["roof"])
			bb(k, Vector3(-1.0, hh - 0.3, -0.56), Vector3(1.0, hh - 0.26, -0.48), lit(p["accent2"], 0.45))
			# the press: bed, four posts, a crown with cylinders
			bb(k, Vector3(-0.6, 0, -1.55), Vector3(0.6, 0.5, -0.75), p["dark"])
			bb(k, Vector3(-0.45, 0.5, -1.4), Vector3(0.45, 0.58, -0.9), Color(0.56, 0.58, 0.62))
			for i in 8:
				bb(k, Vector3(-0.15, 0.58 + i * 0.025, -1.25), Vector3(0.15, 0.6 + i * 0.025, -1.05), chip if i % 2 == 0 else lit(ac, 0.5))
			for q in [Vector2(-0.48, -1.45), Vector2(0.48, -1.45), Vector2(-0.48, -0.85), Vector2(0.48, -0.85)]:
				cy(k, 0.07, 3.2, Color(0.82, 0.84, 0.88), Vector3(q.x, 0.5, q.y), 10)
			bb(k, Vector3(-0.65, 3.3, -1.6), Vector3(0.65, 3.85, -0.7), p["accent"])
			bb(k, Vector3(-0.66, 3.5, -0.71), Vector3(0.66, 3.6, -0.69), p["dark"])
			for i in 8:
				bb(k, Vector3(-0.6 + i * 0.16, 3.5, -0.69), Vector3(-0.52 + i * 0.16, 3.6, -0.685), p["accent"])
			for sx in [-0.25, 0.25]:
				cy(k, 0.16, 0.35, Color(0.7, 0.72, 0.76), Vector3(sx, 3.85, -1.15), 10)
				cy(k, 0.18, 0.05, p["dark"], Vector3(sx, 4.2, -1.15), 10)
			# the press control desk, die stacks, a crane hook
			bb(k, Vector3(-0.32, 0, -0.45), Vector3(0.32, 0.8, -0.2), p["wall"])
			k.box(Vector3(0.62, 0.04, 0.3), p["dark"], xf(Vector3(0, 0.85, -0.32), Vector3(-20, 0, 0)))
			screen(k, xf(Vector3(0, 1.1, -0.43), Vector3(-10, 0, 0)), 0.4, 0.22, p["glow"], 6)
			for i in 4:
				bx(k, Vector3(0.04, 0.03, 0.04), lit([Color(0.4, 1.0, 0.5), Color(1.0, 0.3, 0.25)][i % 2], 0.4), Vector3(-0.2 + i * 0.13, 0.89, -0.27))
			for sx in [-0.78, 0.78]:
				for i in 5:
					bb(k, Vector3(sx - 0.12, 0.0 + i * 0.12, -0.42), Vector3(sx + 0.12, 0.1 + i * 0.12, -0.18), chip if i % 2 == 0 else ac.darkened(0.2))
			stack_light(k, Vector3(0.6, 0.5, -0.75), 0.4)
		_:
			_wing(k, "hbm_works", t, -1.0, "vault", 2.5)
			_wing(k, "hbm_works", t, 1.0, "fin", 3.2)
			# the stacked-die monolith: slabs with glowing bond lines, TSVs
			var n := 9
			var sl := 0.5
			for i in n:
				var y := 0.25 + i * (sl + 0.07)
				var ox := 0.06 * ((i % 2) * 2 - 1)
				bb(k, Vector3(-0.82 + ox, y, -1.82), Vector3(0.82 + ox, y + sl, -0.62), p["wall"] if i % 2 == 0 else p["wall2"])
				bb(k, Vector3(-0.78, y + sl, -1.78), Vector3(0.78, y + sl + 0.07, -0.66), lit(ac, 0.45))
				bb(k, Vector3(-0.84 + ox, y + sl - 0.04, -1.84), Vector3(0.84 + ox, y + sl, -0.6), p["trim"])
			bb(k, Vector3(-0.9, 0, -1.88), Vector3(0.9, 0.25, -0.55), p["dark"])
			var top := 0.25 + n * (sl + 0.07)
			for i in 7:
				bb(k, Vector3(-0.6 + i * 0.2 - 0.012, 0.3, -0.59), Vector3(-0.6 + i * 0.2 + 0.012, top - 0.1, -0.57), lit(p["glow"], 0.4))
			for sx in [-0.95, 0.95]:
				for i in 3:
					bb(k, Vector3(sx * 0.875 - 0.012, 0.3, -1.6 + i * 0.4), Vector3(sx * 0.875 + 0.012, top - 0.1, -1.58 + i * 0.4), lit(p["glow"], 0.4))
			# the brass press head over the stack on four posts (ram = part)
			for q in [Vector2(-0.65, -1.65), Vector2(0.65, -1.65), Vector2(-0.65, -0.78), Vector2(0.65, -0.78)]:
				cy(k, 0.05, 1.5, p["trim"], Vector3(q.x, top, q.y), 8)
			bb(k, Vector3(-0.75, top + 1.5, -1.75), Vector3(0.75, top + 1.75, -0.68), p["trim"])
			bb(k, Vector3(-0.6, top + 1.75, -1.6), Vector3(0.6, top + 1.82, -0.83), p["dark"])
			ArchKit.beacon(k, Vector3(0.55, top + 1.82, -1.5), 0.4)
			k.torus(0.3, 0.03, lit(ac, 0.35), at(0, top + 1.85, -1.21), 14, 4)
			# glowing coolant manifolds on the front corners
			for sx in [-1.0, 1.0]:
				run(k, [Vector3(sx * 0.98, 0.6, -0.5), Vector3(sx * 0.98, top - 0.5, -0.5), Vector3(sx * 0.7, top - 0.5, -0.5)], 0.045, lit(p["accent2"], 0.45))
			# an output port at the front
			bb(k, Vector3(-0.3, 0, -0.55), Vector3(0.3, 0.75, -0.3), p["wall2"])
			bb(k, Vector3(-0.32, 0.75, -0.57), Vector3(0.32, 0.8, -0.28), p["trim"])
			bb(k, Vector3(-0.2, 0.2, -0.3), Vector3(0.2, 0.6, -0.29), lit(ac, 0.5))



# ---------------------------------------------------------------- RLHF gym

## A thumbs sign: up (green) or down (red), on a face frame.
static func _thumb(k: MeshKit, face: Transform3D, up: bool, s := 1.0) -> void:
	var col := Color(0.4, 0.9, 0.5) if up else Color(1.0, 0.36, 0.3)
	var g := 1.0 if up else -1.0
	k.box(Vector3(0.12, 0.1, 0.02) * s, lit(col, 0.45), face * at(0, 0, 0))
	k.box(Vector3(0.04, 0.09, 0.02) * s, lit(col, 0.45), face * at(-0.03 * s, g * 0.09 * s, 0))


static func _rlhf_gym(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("rlhf_gym")
	var good := Color(0.4, 0.9, 0.5)
	var bad := Color(1.0, 0.36, 0.3)
	match t:
		0:
			_wing(k, "rlhf_gym", t, -1.0, "pile", 1.1)
			_wing(k, "rlhf_gym", t, 1.0, "lean", 1.7)
			# a whiteboard of sticky notes, three folding chairs facing it
			ArchKit.planks(k, at(0, 0, BK + 0.02), 1.96, 1.8, Color(0.74, 0.6, 0.42))
			bb(k, Vector3(-0.7, 0.85, BK + 0.06), Vector3(0.5, 1.6, BK + 0.09), Color(0.97, 0.97, 0.96))
			bb(k, Vector3(-0.72, 0.83, BK + 0.05), Vector3(0.52, 0.86, BK + 0.12), Color(0.6, 0.62, 0.66))
			bb(k, Vector3(-0.66, 1.52, BK + 0.09), Vector3(-0.3, 1.56, BK + 0.1), good)
			bb(k, Vector3(0.0, 1.52, BK + 0.09), Vector3(0.36, 1.56, BK + 0.1), bad)
			for i in 14:
				var col: Color = good if (i * 7) % 3 != 0 else bad
				var sx := -0.65 + (i % 4) * 0.09 if col == good else 0.02 + (i % 4) * 0.09
				bx(k, Vector3(0.07, 0.07, 0.01), col.lerp(Color(1, 1, 0.8), 0.3), Vector3(sx, 1.42 - (i / 4) * 0.12, BK + 0.1), Vector3(0, 0, (i % 3) * 5 - 5))
			_thumb(k, at(0.75, 1.3, BK + 0.1), true, 1.5)
			for i in 3:
				var fx := -0.55 + i * 0.4
				var fz := -1.0 - (i % 2) * 0.1
				bb(k, Vector3(fx - 0.15, 0.42, fz - 0.14), Vector3(fx + 0.15, 0.45, fz + 0.14), Color(0.3, 0.4, 0.6))
				k.box(Vector3(0.3, 0.32, 0.03), Color(0.3, 0.4, 0.6), xf(Vector3(fx, 0.62, fz + 0.15), Vector3(10, 0, 0)))
				for sx in [-0.13, 0.13]:
					seg(k, Vector3(fx + sx, 0, fz - 0.14), Vector3(fx + sx, 0.42, fz + 0.1), 0.02, Color(0.6, 0.62, 0.66))
					seg(k, Vector3(fx + sx, 0, fz + 0.14), Vector3(fx + sx, 0.78, fz + 0.17), 0.02, Color(0.6, 0.62, 0.66))
			# an old couch, a coffee table with pizza and a laptop
			bb(k, Vector3(-0.95, 0, -1.75), Vector3(-0.15, 0.35, -1.35), Color(0.56, 0.38, 0.3))
			bb(k, Vector3(-0.95, 0.35, -1.75), Vector3(-0.15, 0.7, -1.6), Color(0.56, 0.38, 0.3))
			for sx in [-0.95, -0.25]:
				bb(k, Vector3(sx, 0.35, -1.75), Vector3(sx + 0.1, 0.5, -1.35), Color(0.5, 0.33, 0.26))
			for i in 2:
				bb(k, Vector3(-0.85 + i * 0.32, 0.35, -1.6), Vector3(-0.55 + i * 0.32, 0.42, -1.37), Color(0.62, 0.44, 0.34))
			bb(k, Vector3(0.1, 0.35, -1.65), Vector3(0.7, 0.38, -1.3), Color(0.7, 0.55, 0.38))
			for q in [Vector2(0.14, -1.62), Vector2(0.66, -1.62), Vector2(0.14, -1.33), Vector2(0.66, -1.33)]:
				bb(k, Vector3(q.x - 0.02, 0, q.y - 0.02), Vector3(q.x + 0.02, 0.35, q.y + 0.02), Color(0.5, 0.36, 0.24))
			bx(k, Vector3(0.3, 0.03, 0.3), Color(0.86, 0.76, 0.56), Vector3(0.25, 0.4, -1.48), Vector3(0, 10, 0))
			bx(k, Vector3(0.26, 0.012, 0.26), Color(0.9, 0.62, 0.3), Vector3(0.25, 0.42, -1.48), Vector3(0, 10, 0))
			bb(k, Vector3(0.42, 0.38, -1.55), Vector3(0.66, 0.39, -1.38), Color(0.3, 0.31, 0.34))
			k.box(Vector3(0.24, 0.16, 0.01), lit(ac, 0.5), xf(Vector3(0.54, 0.47, -1.56), Vector3(-12, 0, 0)))
			# the robot arm kit on a crate out front (arm = part), a reward bell
			crate(k, Vector3(0, 0, -0.2), Vector3(0.5, 0.45, 0.42), 0.0, Color(0.76, 0.62, 0.44))
			bb(k, Vector3(-0.2, 0.45, -0.38), Vector3(0.2, 0.47, -0.02), Color(0.3, 0.6, 0.5))
			cy(k, 0.05, 0.05, Color(0.95, 0.75, 0.25), Vector3(0.15, 0.47, -0.1), 8)
			k.sphere(0.04, Color(0.95, 0.75, 0.25), at(0.15, 0.53, -0.1), 6, 4)
			# a hand-drawn "THUMBS" banner between posts, string lights, tarp
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.035, 0, -0.85), Vector3(sx + 0.035, 2.0, -0.78), Color(0.5, 0.36, 0.24))
			bb(k, Vector3(-0.6, 1.62, -0.84), Vector3(0.6, 1.88, -0.82), Color(0.96, 0.92, 0.82))
			for i in 6:
				bb(k, Vector3(-0.5 + i * 0.18, 1.68, -0.82), Vector3(-0.4 + i * 0.18, 1.82, -0.815), [good, bad, ac][i % 3])
			k.box(Vector3(2.0, 0.025, 1.0), Color(0.92, 0.56, 0.26), xf(Vector3(0, 2.1, -1.35), Vector3(-7, 0, 0)))
			ArchKit.string_lights(k, Vector3(-0.95, 1.98, -0.8), Vector3(0.95, 1.98, -0.8), 9, Color(1.0, 0.85, 0.45))
			cord(k, [Vector2(-1.0, -0.45), Vector2(-0.5, -0.6), Vector2(-0.1, -0.45), Vector2(0.0, -0.4)], Color(0.92, 0.5, 0.18))
		1:
			_wing(k, "rlhf_gym", t, -1.0, "container", 1.3)
			_wing(k, "rlhf_gym", t, 1.0, "shed_steel", 2.0)
			# three feedback booths: steel frames, a chair and a screen each
			for i in 3:
				var bx0 := -0.95 + i * 0.64
				var bx1 := bx0 + 0.6
				var mx := (bx0 + bx1) * 0.5
				bb(k, Vector3(bx0, 0, -1.84), Vector3(bx1, 2.0, -1.8), p["wall2"])
				for sx in [bx0, bx1]:
					bb(k, Vector3(sx - 0.02, 0, -1.84), Vector3(sx + 0.02, 2.0, -1.0), p["wall"])
				bb(k, Vector3(bx0, 2.0, -1.86), Vector3(bx1, 2.08, -0.98), p["trim"])
				bb(k, Vector3(bx0 + 0.05, 0.72, -1.78), Vector3(bx1 - 0.05, 0.75, -1.45), Color(0.72, 0.6, 0.44))
				screen(k, at(mx, 1.0, -1.76), 0.36, 0.24, ac if i != 1 else Color(0.5, 0.86, 1.0), 3)
				bb(k, Vector3(mx - 0.12, 0.42, -1.3), Vector3(mx + 0.12, 0.46, -1.08), Color(0.2, 0.2, 0.22))
				bb(k, Vector3(mx - 0.12, 0.46, -1.1), Vector3(mx + 0.12, 0.8, -1.07), Color(0.2, 0.2, 0.22))
				cy(k, 0.02, 0.42, Color(0.5, 0.52, 0.56), Vector3(mx, 0, -1.2), 5)
				figure(k, Vector3(mx, 0.0, -1.25), [Color(0.3, 0.5, 0.7), Color(0.7, 0.4, 0.3), Color(0.4, 0.6, 0.4)][i], 180.0)
				# a light box on top: thumbs up or down
				bb(k, Vector3(mx - 0.16, 2.08, -1.1), Vector3(mx + 0.16, 2.3, -1.02), Color(0.2, 0.2, 0.22))
				_thumb(k, at(mx - 0.07, 2.19, -1.01), true)
				_thumb(k, at(mx + 0.07, 2.19, -1.01), false)
				bb(k, Vector3(bx0 + 0.04, 1.85, -1.0), Vector3(bx1 - 0.04, 1.95, -0.98), p["accent"])
			ArchKit.cable_tray(k, Vector3(-0.95, 2.35, -1.5), Vector3(0.95, 2.35, -1.5), t)
			for i in 3:
				seg(k, Vector3(-0.65 + i * 0.64, 2.35, -1.5), Vector3(-0.65 + i * 0.64, 2.08, -1.5), 0.03, Color(0.2, 0.2, 0.22))
			# the robot arm on a steel table at the front (arm = part)
			bb(k, Vector3(-0.32, 0.6, -0.72), Vector3(0.32, 0.65, -0.2), Color(0.56, 0.58, 0.62))
			for q in [Vector2(-0.28, -0.68), Vector2(0.28, -0.68), Vector2(-0.28, -0.24), Vector2(0.28, -0.24)]:
				bb(k, Vector3(q.x - 0.025, 0, q.y - 0.025), Vector3(q.x + 0.025, 0.6, q.y + 0.025), p["dark"])
			bb(k, Vector3(-0.3, 0.15, -0.7), Vector3(0.3, 0.18, -0.22), Color(0.46, 0.48, 0.52))
			bb(k, Vector3(-0.25, 0.18, -0.6), Vector3(0.0, 0.4, -0.3), Color(0.3, 0.32, 0.36))
			for i in 3:
				bb(k, Vector3(0.05 + i * 0.07, 0.65, -0.35), Vector3(0.11 + i * 0.07, 0.71, -0.29), [good, bad, ac][i])
			# a scoreboard on a post, yellow rails round the arm
			cy(k, 0.04, 2.1, p["dark"], Vector3(0.75, 0, -0.65), 6)
			bb(k, Vector3(0.45, 1.75, -0.7), Vector3(0.95, 2.15, -0.6), p["accent"])
			bb(k, Vector3(0.49, 1.79, -0.6), Vector3(0.91, 2.11, -0.59), Color(0.15, 0.15, 0.16))
			for i in 4:
				bb(k, Vector3(0.52 + i * 0.1, 1.84, -0.59), Vector3(0.59 + i * 0.1, 2.06, -0.585), lit(good if i < 3 else bad, 0.45))
			ArchKit.railing(k, Vector3(-0.4, 0, -0.8), Vector3(-0.4, 0, -0.18), 0.9, p["accent"], 0.3)
			bb(k, Vector3(-0.95, 0.03, -0.85), Vector3(0.95, 0.036, -0.82), p["accent"])
		2:
			_wing(k, "rlhf_gym", t, -1.0, "glass", 2.5)
			_wing(k, "rlhf_gym", t, 1.0, "office", 2.9)
			# the gym: a white hall under a barrel-vault roof
			var gh := 2.2
			bb(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, gh, -0.6), Color(0.95, 0.95, 0.96))
			ArchKit.curtain(k, at(0, 0.1, -0.6), 1.9, gh - 0.3, t, 5, 2)
			bb(k, Vector3(-0.98, gh - 0.12, -0.6), Vector3(0.98, gh, -0.56), p["trim"])
			var n := 9
			for i in n:
				var a0 := PI * i / n
				var a1 := PI * (i + 1) / n
				var r := 0.98
				var p0 := Vector3(-cos(a0) * r, gh + sin(a0) * 0.75, 0)
				var p1 := Vector3(-cos(a1) * r, gh + sin(a1) * 0.75, 0)
				var mid := (p0 + p1) * 0.5
				var ang := rad_to_deg(atan2(p1.y - p0.y, p1.x - p0.x))
				k.box(Vector3((p1 - p0).length() + 0.02, 0.05, 1.3), Color(0.92, 0.93, 0.94) if i % 2 == 0 else p["glass"], xf(Vector3(mid.x, mid.y, -1.23), Vector3(0, 0, ang)))
			for z in [-1.86, -0.6]:
				bb(k, Vector3(-0.98, gh, z - 0.02), Vector3(0.98, gh + 0.1, z + 0.02), Color(0.95, 0.95, 0.96))
				for i in 4:
					var x := -0.75 + i * 0.5
					bb(k, Vector3(x - 0.22, gh, z - 0.015), Vector3(x + 0.22, gh + sqrt(maxf(0.0, 1.0 - (x / 0.98) * (x / 0.98))) * 0.7, z + 0.015), Color(0.95, 0.95, 0.96) if z < -1.0 else p["glass"])
			# a scoreboard over the entrance, the thumbs-up logo
			bb(k, Vector3(-0.6, gh + 0.1, -0.6), Vector3(0.6, gh + 0.55, -0.54), Color(0.14, 0.15, 0.18))
			for i in 6:
				bb(k, Vector3(-0.52 + i * 0.18, gh + 0.18, -0.54), Vector3(-0.4 + i * 0.18, gh + 0.47, -0.53), lit(good if i % 3 != 2 else ac, 0.45))
			_thumb(k, at(0.8, 1.6, -0.55), true, 2.0)
			# a glass training cell at the front (arm = part)
			bb(k, Vector3(-0.34, 0, -0.56), Vector3(0.34, 0.5, 0.22), Color(0.92, 0.93, 0.94))
			bb(k, Vector3(-0.34, 0.5, -0.56), Vector3(0.34, 0.53, 0.22), p["trim"])
			for sx in [-0.33, 0.33]:
				for sz in [-0.55, 0.21]:
					bb(k, Vector3(sx - 0.015, 0.53, sz - 0.015), Vector3(sx + 0.015, 1.3, sz + 0.015), Color(0.86, 0.88, 0.9))
				bb(k, Vector3(sx - 0.015, 1.28, -0.56), Vector3(sx + 0.015, 1.32, 0.22), Color(0.86, 0.88, 0.9))
				bb(k, Vector3(sx - 0.005, 0.53, -0.54), Vector3(sx + 0.005, 0.8, 0.2), p["glass"])
			bb(k, Vector3(-0.34, 1.28, 0.2), Vector3(0.34, 1.32, 0.23), Color(0.86, 0.88, 0.9))
			bb(k, Vector3(-0.32, 0.53, 0.21), Vector3(0.32, 0.8, 0.22), p["glass"])
			bb(k, Vector3(-0.32, 0.36, 0.22), Vector3(0.32, 0.42, 0.23), p["trim"])
			for i in 3:
				bb(k, Vector3(-0.25 + i * 0.2, 0.53, 0.0), Vector3(-0.15 + i * 0.2, 0.6, 0.12), [good, bad, ac][i])
			ArchKit.planter(k, Vector3(-0.68, 0, -0.38), t, 0.4)
			ArchKit.planter(k, Vector3(0.68, 0, -0.38), t, 0.4)
		3:
			_wing(k, "rlhf_gym", t, -1.0, "annex", 3.0)
			_wing(k, "rlhf_gym", t, 1.0, "canopy", 2.7)
			# the arena: stepped bleachers round a training floor, open to the sky
			bb(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, 0.15, -0.5), p["wall2"])
			bb(k, Vector3(-0.55, 0.15, -1.5), Vector3(0.55, 0.17, -0.75), Color(0.3, 0.5, 0.45))
			for i in 3:
				bb(k, Vector3(-0.55, 0.17, -1.45 + i * 0.3), Vector3(0.55, 0.18, -1.43 + i * 0.3), Color(0.95, 0.95, 0.9))
			for s in 4:
				var y := 0.15 + (s + 1) * 0.29
				bb(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, y, -1.5 - s * 0.09), p["wall"].lightened(0.05 * (s % 2)))
				bb(k, Vector3(-0.98, y - 0.04, -1.5 - s * 0.09 - 0.02), Vector3(0.98, y, -1.5 - s * 0.09 + 0.01), p["accent"])
				for sx in [-1.0, 1.0]:
					bb(k, Vector3(minf(sx * 0.98, sx * (0.6 + s * 0.095)), 0, -1.5), Vector3(maxf(sx * 0.98, sx * (0.6 + s * 0.095)), y, -0.5), p["wall"].lightened(0.05 * (s % 2)))
				for i in 5:
					var fx := -0.8 + i * 0.4
					bb(k, Vector3(fx - 0.06, y, -1.5 - s * 0.09 - 0.07), Vector3(fx + 0.06, y + 0.06, -1.5 - s * 0.09 - 0.01), [good, bad, ac, Color(0.5, 0.7, 0.95)][(i + s) % 4])
			# floodlight masts at the corners and a scoreboard gantry
			for q in [Vector2(-0.92, -1.8), Vector2(0.92, -1.8), Vector2(-0.92, -0.55), Vector2(0.92, -0.55)]:
				cy(k, 0.04, 3.6, p["trim"], Vector3(q.x, 0, q.y), 6)
				bb(k, Vector3(q.x - 0.15, 3.6, q.y - 0.06), Vector3(q.x + 0.15, 3.78, q.y + 0.06), p["dark"])
				bb(k, Vector3(q.x - 0.13, 3.62, q.y + (0.06 if q.y < -1.0 else -0.07)), Vector3(q.x + 0.13, 3.76, q.y + (0.07 if q.y < -1.0 else -0.06)), lit(Color(1, 1, 0.9), 0.3))
			bb(k, Vector3(-0.92, 2.7, -1.84), Vector3(0.92, 2.78, -1.76), p["trim"])
			bb(k, Vector3(-0.7, 2.0, -1.84), Vector3(0.7, 2.7, -1.78), p["dark"])
			for i in 3:
				screen(k, at(-0.45 + i * 0.45, 2.35, -1.77), 0.38, 0.5, [good, ac, Color(0.5, 0.86, 1.0)][i], 5)
			# the arm's plinth in the middle of the floor (arm = part)
			cy(k, 0.22, 0.3, p["dark"], Vector3(0, 0.17, -1.1), 10)
			cy(k, 0.24, 0.04, lit(ac, 0.4), Vector3(0, 0.44, -1.1), 10)
			# entrance gate at the front with turnstiles
			bb(k, Vector3(-0.4, 0, -0.55), Vector3(0.4, 0.15, -0.3), p["wall2"])
			for sx in [-0.3, 0.0, 0.3]:
				bb(k, Vector3(sx - 0.05, 0.15, -0.5), Vector3(sx + 0.05, 0.9, -0.35), p["metal"])
				bb(k, Vector3(sx - 0.03, 0.85, -0.36), Vector3(sx + 0.03, 0.88, -0.34), lit(good, 0.4))
			bb(k, Vector3(-0.42, 1.6, -0.56), Vector3(0.42, 1.95, -0.5), p["dark"])
			bb(k, Vector3(-0.36, 1.66, -0.5), Vector3(0.36, 1.89, -0.49), lit(ac, 0.45))
			for sx in [-0.4, 0.4]:
				bb(k, Vector3(sx - 0.03, 0.15, -0.55), Vector3(sx + 0.03, 1.6, -0.5), p["trim"])
		_:
			_wing(k, "rlhf_gym", t, -1.0, "podium", 2.0)
			_wing(k, "rlhf_gym", t, 1.0, "fin", 3.0)
			# the citadel: a stepped graphite ziggurat with glowing tiers
			var tiers := [[0.98, 0.65, 1.0], [0.82, 0.55, 0.9], [0.66, 0.45, 0.85], [0.48, 0.36, 0.8]]
			var y := 0.0
			var c := Vector3(0, 0, -1.2)
			for tr in tiers:
				var hw: float = tr[0]
				var hd: float = tr[1]
				var h: float = tr[2]
				bb(k, Vector3(c.x - hw, y, c.z - hd), Vector3(c.x + hw, y + h, c.z + hd), p["wall"] if y < 0.1 or int(y * 10) % 2 == 0 else p["wall2"])
				bb(k, Vector3(c.x - hw - 0.02, y + h - 0.06, c.z - hd - 0.02), Vector3(c.x + hw + 0.02, y + h, c.z + hd + 0.02), p["trim"])
				bb(k, Vector3(c.x - hw + 0.04, y + h * 0.4, c.z + hd), Vector3(c.x + hw - 0.04, y + h * 0.4 + 0.04, c.z + hd + 0.02), lit(ac, 0.45))
				fins(k, at(c.x, y + 0.1, c.z + hd), hw * 2.0 - 0.2, h * 0.3, int(hw * 6.0), 0.06)
				y += h
			# a giant brass arm on top (part), a glowing star crown
			cy(k, 0.3, 0.12, p["trim"], Vector3(c.x, y, c.z), 10)
			cy(k, 0.32, 0.04, lit(ac, 0.4), Vector3(c.x, y + 0.12, c.z), 10)
			# the entrance with a brass portal and glowing steps
			bb(k, Vector3(-0.3, 0, -0.55), Vector3(0.3, 0.9, -0.3), p["wall2"])
			bb(k, Vector3(-0.32, 0.9, -0.57), Vector3(0.32, 0.96, -0.28), p["trim"])
			bb(k, Vector3(-0.2, 0.05, -0.3), Vector3(0.2, 0.8, -0.29), lit(ac, 0.5))
			bb(k, Vector3(-0.35, 0, -0.28), Vector3(0.35, 0.05, -0.2), p["trim"])
			for sx in [-1.0, 1.0]:
				run(k, [Vector3(sx * 1.0, 0.6, -0.5), Vector3(sx * 0.85, 0.6, -0.5), Vector3(sx * 0.85, 2.2, -0.62)], 0.045, lit(p["accent2"], 0.45))
				_thumb(k, at(sx * 0.6, 1.4, -0.54), sx > 0.0, 1.6)



# ---------------------------------------------------------------- synth lab

## A round-bottom flask with glowing liquid (sits at p).
static func _flask(k: MeshKit, p: Vector3, r: float, col: Color) -> void:
	k.sphere(r, Color(0.8, 0.9, 0.95, 0.75), at(p.x, p.y + r, p.z), 8, 6)
	k.sphere(r * 0.8, lit(col, 0.45), xf(Vector3(p.x, p.y + r * 0.8, p.z), Vector3.ZERO, Vector3(1, 0.8, 1)), 8, 5)
	cy(k, r * 0.28, r * 1.1, Color(0.8, 0.9, 0.95, 0.75), Vector3(p.x, p.y + r * 1.8, p.z), 6)


static func _synth_lab(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("synth_lab")
	var goo := lit(ac, 0.45)
	match t:
		0:
			_wing(k, "synth_lab", t, -1.0, "shed", 1.75)
			_wing(k, "synth_lab", t, 1.0, "lean", 1.6)
			# a chemistry bench: flasks, a burner, a coiled condenser
			ArchKit.planks(k, at(0, 0, BK + 0.02), 1.96, 1.85, Color(0.72, 0.58, 0.4))
			var ty := 0.76
			bb(k, Vector3(-0.92, ty - 0.05, -1.82), Vector3(0.7, ty, -1.3), Color(0.9, 0.9, 0.88))
			bb(k, Vector3(-0.9, 0.0, -1.8), Vector3(0.68, ty - 0.05, -1.32), Color(0.66, 0.56, 0.42))
			for i in 4:
				bb(k, Vector3(-0.86 + i * 0.39, 0.1, -1.32), Vector3(-0.5 + i * 0.39, ty - 0.1, -1.31), Color(0.6, 0.5, 0.36))
			for i in 4:
				_flask(k, Vector3(-0.75 + i * 0.22, ty, -1.6 + (i % 2) * 0.12), 0.07 + (i % 2) * 0.02, [ac, Color(0.4, 0.9, 0.6), Color(1.0, 0.6, 0.3), ac][i])
			# a retort stand with a flask over a burner
			bb(k, Vector3(0.2, ty, -1.75), Vector3(0.4, ty + 0.02, -1.55), Color(0.3, 0.3, 0.32))
			cy(k, 0.012, 0.75, Color(0.6, 0.62, 0.66), Vector3(0.24, ty, -1.7), 5)
			seg(k, Vector3(0.24, ty + 0.4, -1.7), Vector3(0.33, ty + 0.4, -1.62), 0.015, Color(0.6, 0.62, 0.66))
			_flask(k, Vector3(0.33, ty + 0.3, -1.62), 0.1, ac)
			cy(k, 0.03, 0.18, Color(0.5, 0.52, 0.56), Vector3(0.33, ty, -1.62), 6)
			k.cone(0.03, 0.08, lit(Color(0.4, 0.6, 1.0), 0.3), at(0.33, ty + 0.19, -1.62), 6)
			# the coiled condenser running to a collecting beaker
			for i in 5:
				k.torus(0.06, 0.012, Color(0.8, 0.9, 0.95, 0.75), xf(Vector3(0.55, ty + 0.25 + i * 0.05, -1.62), Vector3(0, 0, 0)), 8, 3)
			seg(k, Vector3(0.38, ty + 0.62, -1.62), Vector3(0.55, ty + 0.5, -1.62), 0.02, Color(0.8, 0.9, 0.95, 0.75))
			cy(k, 0.06, 0.12, Color(0.8, 0.9, 0.95, 0.75), Vector3(0.55, ty, -1.62), 8)
			cy(k, 0.05, 0.06, goo, Vector3(0.55, ty, -1.62), 8)
			# shelves of jars, a fish tank bubbling, a fire extinguisher
			for s in 2:
				bb(k, Vector3(-0.9, 1.15 + s * 0.35, BK + 0.04), Vector3(0.3, 1.18 + s * 0.35, BK + 0.26), Color(0.62, 0.48, 0.32))
				for i in 8:
					cy(k, 0.045, 0.12 + (i % 3) * 0.03, Color(0.8, 0.9, 0.95, 0.75) if i % 3 else goo, Vector3(-0.83 + i * 0.15, 1.18 + s * 0.35, BK + 0.15), 6)
			bb(k, Vector3(0.38, 0.0, -1.22), Vector3(0.88, 0.5, -0.92), Color(0.3, 0.3, 0.32))
			bb(k, Vector3(0.4, 0.5, -1.2), Vector3(0.86, 0.85, -0.94), Color(0.5, 0.86, 0.8, 0.6))
			bb(k, Vector3(0.38, 0.85, -1.22), Vector3(0.88, 0.88, -0.92), Color(0.3, 0.3, 0.32))
			for i in 4:
				k.sphere(0.02, Color(0.9, 1.0, 1.0, 0.5), at(0.5 + i * 0.1, 0.6 + (i % 2) * 0.1, -0.93), 5, 3)
			cy(k, 0.06, 0.4, Color(0.86, 0.2, 0.18), Vector3(-0.85, 0, -0.95), 8)
			cy(k, 0.02, 0.06, Color(0.2, 0.2, 0.22), Vector3(-0.85, 0.4, -0.95), 5)
			# a jerry can of reagent, goggles on a hook, a hazard sign
			bb(k, Vector3(-0.7, 0, -1.05), Vector3(-0.5, 0.32, -0.92), Color(0.3, 0.5, 0.3))
			bx(k, Vector3(0.24, 0.24, 0.02), Color(0.98, 0.84, 0.3), Vector3(0.6, 1.4, BK + 0.05), Vector3(0, 0, 45))
			# the tinkering stool and the gyro-reactor prototype out front (part)
			crate(k, Vector3(0, 0, -0.2), Vector3(0.44, 0.48, 0.38), 3.0, Color(0.76, 0.62, 0.44))
			cy(k, 0.1, 0.04, Color(0.5, 0.36, 0.24), Vector3(0, 0.48, -0.2), 8)
			cy(k, 0.02, 0.18, Color(0.6, 0.62, 0.66), Vector3(0, 0.52, -0.2), 5)
			# a tarp canopy, string lights, cords
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.035, 0, -0.85), Vector3(sx + 0.035, 2.0, -0.78), Color(0.5, 0.36, 0.24))
			k.box(Vector3(2.0, 0.025, 1.0), Color(0.36, 0.58, 0.36), xf(Vector3(0, 2.1, -1.34), Vector3(-7, 0, 0)))
			ArchKit.string_lights(k, Vector3(-0.95, 1.95, -0.8), Vector3(0.95, 1.95, -0.8), 9, Color(0.85, 0.6, 1.0))
			cord(k, [Vector2(-1.0, -0.42), Vector2(-0.6, -0.7), Vector2(-0.3, -1.1), Vector2(0.2, -1.25)], Color(0.92, 0.5, 0.18))
		1:
			_wing(k, "synth_lab", t, -1.0, "cage", 1.9)
			_wing(k, "synth_lab", t, 1.0, "container", 1.3)
			# a steel fume cabinet with a glass sash and a duct to the roof
			bb(k, Vector3(-0.95, 0, -1.86), Vector3(0.0, 0.85, -1.2), p["wall"])
			bb(k, Vector3(-0.95, 0.85, -1.86), Vector3(0.0, 2.0, -1.8), p["wall"])
			for sx in [-0.95, 0.0]:
				bb(k, Vector3(sx - 0.02, 0.85, -1.86), Vector3(sx + 0.03, 2.0, -1.2), p["wall"])
			bb(k, Vector3(-0.97, 2.0, -1.88), Vector3(0.02, 2.25, -1.18), p["wall2"])
			bb(k, Vector3(-0.92, 1.25, -1.21), Vector3(-0.03, 1.95, -1.19), p["glass"])
			bb(k, Vector3(-0.92, 1.22, -1.22), Vector3(-0.03, 1.27, -1.18), p["trim"])
			bb(k, Vector3(-0.97, 0.82, -1.22), Vector3(0.02, 0.87, -1.15), p["trim"])
			for i in 3:
				_flask(k, Vector3(-0.75 + i * 0.25, 0.87, -1.5), 0.08, [ac, Color(0.4, 0.9, 0.6), ac][i])
			cy(k, 0.12, 0.9, Color(0.72, 0.74, 0.78), Vector3(-0.45, 2.25, -1.55), 8)
			cy(k, 0.15, 0.08, Color(0.6, 0.62, 0.66), Vector3(-0.45, 3.15, -1.55), 8)
			k.cone(0.16, 0.1, Color(0.6, 0.62, 0.66), at(-0.45, 3.28, -1.55), 8)
			for i in 3:
				bb(k, Vector3(-0.85 + i * 0.07, 0.6, -1.199), Vector3(-0.8 + i * 0.07, 0.65, -1.195), [Color(0.3, 0.9, 0.4), Color(0.9, 0.8, 0.3), Color(0.9, 0.3, 0.3)][i])
			# the flask rig: a steel frame holding a big glowing flask (ring = part)
			for q in [Vector2(0.2, -1.75), Vector2(0.9, -1.75), Vector2(0.2, -1.05), Vector2(0.9, -1.05)]:
				bb(k, Vector3(q.x - 0.03, 0, q.y - 0.03), Vector3(q.x + 0.03, 2.1, q.y + 0.03), p["trim"])
			for y in [0.3, 2.1]:
				bb(k, Vector3(0.17, y - 0.03, -1.78), Vector3(0.93, y + 0.03, -1.02), p["trim"])
			bb(k, Vector3(0.2, 0.3, -1.75), Vector3(0.9, 0.34, -1.05), p["metal"])
			_flask(k, Vector3(0.55, 0.62, -1.4), 0.28, ac)
			for sx in [-1.0, 1.0]:
				seg(k, Vector3(0.55 + sx * 0.35, 1.05, -1.4), Vector3(0.55 + sx * 0.2, 0.95, -1.4), 0.03, p["metal"])
			cy(k, 0.2, 0.28, Color(0.3, 0.32, 0.36), Vector3(0.55, 0.34, -1.4), 10)
			run(k, [Vector3(0.55, 1.5, -1.4), Vector3(0.55, 1.85, -1.4), Vector3(0.0, 1.85, -1.4)], 0.03, Color(0.8, 0.9, 0.95, 0.75))
			bb(k, Vector3(0.22, 1.6, -1.04), Vector3(0.88, 1.66, -1.02), p["accent"])
			# gas bottles chained to the frame, a drum with a hand pump
			for i in 3:
				gas_bottle(k, Vector3(-0.85 + i * 0.16, 0, -0.95), [Color(0.86, 0.86, 0.84), Color(0.3, 0.5, 0.8), Color(0.86, 0.3, 0.24)][i], 0.9, 0.065)
			bb(k, Vector3(-0.92, 0.65, -0.88), Vector3(-0.45, 0.67, -0.86), Color(0.6, 0.6, 0.62))
			drum(k, Vector3(0.0, 0, -0.75), ac.darkened(0.3), 0.15, 0.5)
			cy(k, 0.02, 0.3, Color(0.6, 0.62, 0.66), Vector3(0.0, 0.5, -0.75), 5)
			bb(k, Vector3(-0.08, 0.78, -0.77), Vector3(0.12, 0.8, -0.73), Color(0.6, 0.62, 0.66))
			# a lab cart at the front with a centrifuge
			bb(k, Vector3(-0.3, 0.55, -0.55), Vector3(0.3, 0.6, -0.2), Color(0.86, 0.87, 0.88))
			bb(k, Vector3(-0.3, 0.12, -0.55), Vector3(0.3, 0.15, -0.2), Color(0.86, 0.87, 0.88))
			for q in [Vector2(-0.27, -0.52), Vector2(0.27, -0.52), Vector2(-0.27, -0.23), Vector2(0.27, -0.23)]:
				bb(k, Vector3(q.x - 0.015, 0.05, q.y - 0.015), Vector3(q.x + 0.015, 0.55, q.y + 0.015), Color(0.6, 0.62, 0.66))
				cy(k, 0.03, 0.05, Color(0.2, 0.2, 0.22), Vector3(q.x, 0, q.y), 6)
			cy(k, 0.13, 0.15, Color(0.92, 0.92, 0.94), Vector3(-0.12, 0.6, -0.38), 10)
			bb(k, Vector3(0.05, 0.6, -0.5), Vector3(0.25, 0.68, -0.28), Color(0.3, 0.32, 0.36))
			bb(k, Vector3(-0.95, 0.03, -0.66), Vector3(0.95, 0.036, -0.62), p["accent"])
		2:
			_wing(k, "synth_lab", t, -1.0, "plant", 2.2)
			_wing(k, "synth_lab", t, 1.0, "glass", 2.5)
			# the lab: a white drum with a ribbed glass dome
			var c := Vector3(0, 0, -1.2)
			bb(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, 1.4, -0.55), Color(0.95, 0.95, 0.96))
			ArchKit.window_row(k, at(0, 0.8, -0.55), 1.6, 0.6, t)
			bb(k, Vector3(-0.98, 1.4, -1.86), Vector3(0.98, 1.5, -0.55), p["trim"])
			cy(k, 0.66, 0.5, Color(0.95, 0.95, 0.96), c + Vector3(0, 1.5, 0), 12)
			cy(k, 0.68, 0.05, p["trim"], c + Vector3(0, 1.95, 0), 12)
			var dc := c + Vector3(0, 2.0, 0)
			k.sphere(0.64, p["glass"], xf(dc, Vector3.ZERO, Vector3(1, 1, 1)), 10, 7)
			for i in 5:
				k.torus(0.645, 0.022, Color(0.95, 0.95, 0.96), xf(dc, Vector3(90, i * 36.0, 0)), 14, 3, PI)
			k.torus(0.62, 0.02, Color(0.95, 0.95, 0.96), at(dc.x, dc.y + 0.32, dc.z), 14, 3)
			cy(k, 0.12, 0.12, Color(0.95, 0.95, 0.96), dc + Vector3(0, 0.6, 0), 8)
			# a reactor orb crowning the dome (its gyro rings are the part)
			k.sphere(0.16, goo, at(dc.x, dc.y + 0.95, dc.z), 10, 6)
			cy(k, 0.03, 0.25, Color(0.85, 0.86, 0.88), dc + Vector3(0, 0.7, 0), 6)
			# white gas cabinets and pipework at the drum's side
			for i in 2:
				bb(k, Vector3(-0.92 + i * 0.3, 1.5, -1.85), Vector3(-0.7 + i * 0.3, 2.05, -1.65), Color(0.92, 0.93, 0.94))
				bb(k, Vector3(-0.88 + i * 0.3, 1.8, -1.65), Vector3(-0.74 + i * 0.3, 1.95, -1.64), lit(ac, 0.45))
			run(k, [Vector3(-0.7, 2.0, -1.66), Vector3(-0.7, 2.1, -1.4), Vector3(-0.5, 2.1, -1.3)], 0.03, Color(0.7, 0.72, 0.75))
			ArchKit.ac_unit(k, at(0.7, 1.5, -1.6), t, 0.5)
			# entrance canopy with the logo
			bb(k, Vector3(-0.4, 0, -0.55), Vector3(0.4, 1.2, -0.5), p["glass"])
			bb(k, Vector3(-0.5, 1.2, -0.55), Vector3(0.5, 1.26, -0.32), Color(0.95, 0.95, 0.96))
			k.sphere(0.07, lit(ac, 0.5), at(-0.3, 1.33, -0.42), 8, 5)
			bb(k, Vector3(-0.18, 1.29, -0.43), Vector3(0.38, 1.37, -0.41), p["dark"])
			ArchKit.planter(k, Vector3(-0.68, 0, -0.38), t, 0.4)
			ArchKit.planter(k, Vector3(0.68, 0, -0.38), t, 0.4)
		3:
			_wing(k, "synth_lab", t, -1.0, "canopy", 2.6)
			_wing(k, "synth_lab", t, 1.0, "annex", 3.1)
			# the reactor hall: an open steel frame round a spherical vessel
			var c := Vector3(0, 0, -1.2)
			var fh := 3.8
			for q in [Vector2(-0.92, -1.84), Vector2(0.92, -1.84), Vector2(-0.92, -0.56), Vector2(0.92, -0.56)]:
				bb(k, Vector3(q.x - 0.06, 0, q.y - 0.06), Vector3(q.x + 0.06, fh, q.y + 0.06), p["trim"])
			for z in [-1.84, -0.56]:
				bb(k, Vector3(-0.98, fh - 0.15, z - 0.06), Vector3(0.98, fh, z + 0.06), p["trim"])
				if z < -1.0:
					seg(k, Vector3(-0.92, 0.2, z), Vector3(0.92, fh - 0.2, z), 0.04, p["trim"])
			for x in [-0.92, 0.92]:
				bb(k, Vector3(x - 0.06, fh - 0.15, -1.84), Vector3(x + 0.06, fh, -0.56), p["trim"])
			ArchKit.truss(k, Vector3(0, fh + 0.05, -1.84), Vector3(0, fh + 0.05, -0.56), 0.18, p["trim"])
			# the vessel on legs, a mid-height platform, a glowing port band
			var vc := c + Vector3(0, 1.75, 0)
			k.sphere(0.6, Color(0.78, 0.8, 0.84), at(vc.x, vc.y, vc.z), 14, 9)
			k.torus(0.61, 0.035, lit(ac, 0.4), at(vc.x, vc.y, vc.z), 18, 4)
			for i in 6:
				var a := TAU * i / 6.0
				seg(k, vc + Vector3(cos(a) * 0.42, -0.4, sin(a) * 0.42), c + Vector3(cos(a) * 0.62, 0, sin(a) * 0.58), 0.07, p["dark"])
				k.cyl(0.06, 0.04, lit(ac, 0.4), xf(vc + Vector3(cos(a) * 0.52, 0.3, sin(a) * 0.52), Vector3(0, -rad_to_deg(a) + 90, 90)), 8)
			cy(k, 0.16, 0.4, Color(0.7, 0.72, 0.76), vc + Vector3(0, 0.55, 0), 10)
			cy(k, 0.2, 0.06, p["dark"], vc + Vector3(0, 0.95, 0), 10)
			deck(k, Vector3(0.6, 0, -1.86), Vector3(0.9, 1.5, -1.62), p["metal"], p["accent"], "rb")
			stair(k, Vector3(0.75, 0, -0.6), Vector3(0.75, 1.5, -1.62), 0.26, p["metal"], p["accent"])
			run(k, [vc + Vector3(-0.5, -0.32, 0), Vector3(-0.9, vc.y - 0.32, -1.2), Vector3(-0.9, vc.y - 0.32, -1.0), Vector3(-1.0, vc.y - 0.32, -1.0)], 0.06, Color(0.86, 0.6, 0.3))
			run(k, [vc + Vector3(0, 1.0, 0), Vector3(0, fh + 0.3, -1.2), Vector3(-0.98, fh + 0.3, -1.2)], 0.05, Color(0.36, 0.6, 0.86))
			run(k, [vc + Vector3(0, -0.6, 0), Vector3(0, 0.3, -1.2), Vector3(0, 0.3, -0.5)], 0.06, ac.darkened(0.2))
			bb(k, Vector3(-0.25, 0, -0.55), Vector3(0.25, 0.65, -0.25), p["wall"])
			bb(k, Vector3(-0.27, 0.65, -0.57), Vector3(0.27, 0.7, -0.23), p["trim"])
			screen(k, xf(Vector3(0, 0.45, -0.24)), 0.3, 0.16, ac, 4)
			bb(k, Vector3(-0.98, fh - 0.25, -0.5), Vector3(0.98, fh - 0.22, -0.48), lit(p["accent2"], 0.45))
			ArchKit.beacon(k, Vector3(0.9, fh, -0.6), 0.4)
		_:
			_wing(k, "synth_lab", t, -1.0, "fin", 3.2)
			_wing(k, "synth_lab", t, 1.0, "vault", 2.4)
			# a graphite plinth, a brass cradle, the glowing reactor sphere
			var c := Vector3(0, 0, -1.0)
			cy(k, 0.88, 0.25, p["dark"], c, 8)
			cy(k, 0.8, 0.75, p["wall"], c + Vector3(0, 0.25, 0), 8)
			cy(k, 0.84, 0.06, p["trim"], c + Vector3(0, 1.0, 0), 8)
			cy(k, 0.82, 0.04, lit(p["accent2"], 0.45), c + Vector3(0, 0.6, 0), 8)
			var sc := c + Vector3(0, 3.0, 0.15)
			for i in 4:
				var a := TAU * (i + 0.5) / 4.0
				var base := c + Vector3(cos(a) * 0.7, 1.06, sin(a) * 0.62)
				var mid := c + Vector3(cos(a) * 0.95, 2.0, sin(a) * 0.62 + 0.1)
				var tip := sc + Vector3(cos(a) * 0.55, -0.48, sin(a) * 0.5)
				seg(k, base, mid, 0.1, p["trim"])
				seg(k, mid, tip, 0.08, p["trim"])
				k.sphere(0.07, p["trim"], at(mid.x, mid.y, mid.z), 6, 4)
			k.sphere(0.72, lit(ac, 0.42), at(sc.x, sc.y, sc.z), 14, 9)
			k.sphere(0.45, lit(Color(1, 0.95, 1), 0.25), at(sc.x, sc.y, sc.z), 10, 6)
			k.torus(0.73, 0.03, p["trim"], at(sc.x, sc.y - 0.15, sc.z), 18, 4)
			# crown: a brass halo on a spire, a beacon
			cy(k, 0.05, 0.75, p["trim"], sc + Vector3(0, 0.7, 0), 6)
			k.torus(0.3, 0.025, p["trim"], at(sc.x, sc.y + 1.3, sc.z), 14, 3)
			ArchKit.beacon(k, sc + Vector3(0, 1.45, 0), 0.2)
			# glowing coolant loops from the wings into the plinth
			for sx in [-1.0, 1.0]:
				run(k, [Vector3(sx * 1.0, 0.5, -0.55), Vector3(sx * 0.6, 0.5, -0.55), Vector3(sx * 0.45, 0.5, -0.5)], 0.05, lit(p["accent2"], 0.45))
				run(k, [Vector3(sx * 1.0, 1.6, -1.75), Vector3(sx * 0.55, 1.6, -1.75), Vector3(sx * 0.45, 1.06, -1.6)], 0.045, lit(ac, 0.45))
			# a control lectern at the front
			bb(k, Vector3(-0.28, 0, -0.12), Vector3(0.28, 0.8, 0.12), p["wall2"])
			k.box(Vector3(0.6, 0.05, 0.32), p["trim"], xf(Vector3(0, 0.84, 0.0), Vector3(-20, 0, 0)))
			k.box(Vector3(0.48, 0.02, 0.22), lit(ac, 0.5), xf(Vector3(0, 0.875, 0.0), Vector3(-20, 0, 0)))



# ---------------------------------------------------------------- supply depot

## Depot roof slots (Growth): x, z on the back building's flat roof.
const DEPOT_ROOFS := [Vector2(-1.0, -1.45), Vector2(1.0, -1.45)]


## A forklift (forks to +z) at p.
static func forklift(k: MeshKit, p: Vector3, yaw: float, col: Color, t := 1) -> void:
	var b := xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.42, 0.3, 0.62), col, b * at(0, 0.25, -0.05))
	k.box(Vector3(0.4, 0.22, 0.2), Color(0.25, 0.26, 0.28), b * at(0, 0.3, -0.42))
	k.box(Vector3(0.24, 0.06, 0.2), Color(0.2, 0.2, 0.22), b * at(0, 0.43, -0.12))
	k.box(Vector3(0.22, 0.2, 0.04), Color(0.2, 0.2, 0.22), b * at(0, 0.55, -0.24))
	for sx in [-0.19, 0.19]:
		k.box(Vector3(0.03, 0.75, 0.03), Color(0.25, 0.26, 0.28), b * at(sx, 0.78, -0.3))
		k.box(Vector3(0.03, 0.03, 0.4), Color(0.25, 0.26, 0.28), b * xf(Vector3(sx, 1.15, -0.1), Vector3(-10, 0, 0)))
		k.box(Vector3(0.04, 0.95, 0.04), Color(0.3, 0.32, 0.36), b * at(sx * 0.9, 0.55, 0.3))
		k.box(Vector3(0.06, 0.03, 0.42), Color(0.3, 0.32, 0.36), b * at(sx * 0.6, 0.06, 0.55))
	k.box(Vector3(0.42, 0.04, 0.04), col, b * at(0, 1.15, -0.3))
	k.box(Vector3(0.36, 0.2, 0.04), Color(0.3, 0.32, 0.36), b * at(0, 0.2, 0.33))
	for sx in [-0.2, 0.2]:
		for sz in [-0.3, 0.18]:
			k.cyl(0.09, 0.07, Color(0.12, 0.12, 0.13), b * xf(Vector3(sx * 1.05, 0.09, sz), Vector3(0, 0, 90)), 8)
	k.box(Vector3(0.06, 0.04, 0.06), lit(Color(1.0, 0.6, 0.2), 0.4), b * at(0, 1.2, -0.3))
	if t >= 4:
		k.box(Vector3(0.44, 0.02, 0.64), lit(ArchKit.c(t, "accent2"), 0.4), b * at(0, 0.1, -0.05))


## Steel pallet racking along x (len), depth d, levels at heights.
static func racking(k: MeshKit, c: Vector3, len: float, d: float, levels: Array, up: Color, beam: Color, stock := true, seed := 0) -> void:
	var bays := maxi(1, int(len / 0.68))
	for i in bays + 1:
		var x := c.x - len * 0.5 + i * len / bays
		for sz in [-1.0, 1.0]:
			bb(k, Vector3(x - 0.03, 0, c.z + sz * d * 0.5 - 0.03), Vector3(x + 0.03, levels[-1] + 0.25, c.z + sz * d * 0.5 + 0.03), up)
		for j in 3:
			seg(k, Vector3(x, 0.1 + j * 0.6, c.z - d * 0.5), Vector3(x, 0.4 + j * 0.6, c.z + d * 0.5), 0.02, up)
	var cols := [Color(0.76, 0.62, 0.42), Color(0.82, 0.7, 0.5), Color(0.3, 0.5, 0.8), Color(0.86, 0.86, 0.84), Color(0.4, 0.6, 0.4), Color(0.8, 0.36, 0.28)]
	for y in levels:
		for sz in [-1.0, 1.0]:
			bb(k, Vector3(c.x - len * 0.5, y - 0.06, c.z + sz * d * 0.5 - 0.03), Vector3(c.x + len * 0.5, y, c.z + sz * d * 0.5 + 0.03), beam)
		if not stock:
			continue
		for i in bays:
			var bx0 := c.x - len * 0.5 + i * len / bays
			var bw := len / bays
			var hsh: int = (i * 7 + int(y * 10) + seed) % 6
			if hsh == 5:
				continue
			pallet(k, Vector3(bx0 + bw * 0.5, y, c.z), bw * 0.8, d * 0.9)
			var bh := 0.22 + (hsh % 3) * 0.08
			for m in 2:
				bb(k, Vector3(bx0 + bw * (0.12 + m * 0.4), y + 0.09, c.z - d * 0.38), Vector3(bx0 + bw * (0.48 + m * 0.4), y + 0.09 + bh, c.z + d * 0.38), cols[(hsh + m) % 6])


static func depot(t: int) -> Mesh:
	var k := MeshKit.new()
	t = clampi(t, 0, 4)
	var p := ArchKit.pal(t)
	var ac := Color(0.96, 0.7, 0.3)
	_lot(k, t)
	match t:
		0:
			# a tarp-covered heap of crates and sacks along the back
			var cc := [Color(0.76, 0.6, 0.4), Color(0.7, 0.54, 0.36), Color(0.82, 0.68, 0.48), Color(0.36, 0.5, 0.36)]
			for i in 8:
				var x := -1.6 + i * 0.46
				pallet(k, Vector3(x, 0, -1.4), 0.44, 0.8)
				crate(k, Vector3(x, 0.09, -1.55), Vector3(0.42, 0.45, 0.38), (i % 3) * 4.0 - 4.0, cc[i % 4])
				crate(k, Vector3(x, 0.09, -1.15), Vector3(0.42, 0.45 if i % 3 else 0.35, 0.36), 0.0, cc[(i + 1) % 4])
				if i % 4 != 3:
					crate(k, Vector3(x + 0.02, 0.54, -1.5), Vector3(0.4, 0.4, 0.42), (i % 2) * 6.0 - 3.0, cc[(i + 2) % 4])
			var tc := Color(0.26, 0.46, 0.78)
			bb(k, Vector3(-1.82, 1.0, -1.88), Vector3(-0.2, 1.04, -0.95), tc)
			bb(k, Vector3(0.2, 1.0, -1.88), Vector3(1.82, 1.04, -0.95), tc.darkened(0.06))
			k.box(Vector3(0.42, 0.03, 0.95), tc, xf(Vector3(0, 0.98, -1.41), Vector3(0, 0, 0)))
			k.box(Vector3(3.64, 0.55, 0.03), tc.darkened(0.1), xf(Vector3(0, 0.75, -0.93), Vector3(-10, 0, 0)))
			for sx in [-1.0, 1.0]:
				k.box(Vector3(0.03, 0.6, 0.95), tc.darkened(0.08), xf(Vector3(sx * 1.83, 0.72, -1.41), Vector3(0, 0, sx * 8)))
			for x in [-1.4, -0.6, 0.6, 1.4]:
				bb(k, Vector3(x - 0.01, 1.04, -1.88), Vector3(x + 0.01, 1.055, -0.95), Color(0.86, 0.8, 0.6))
				seg(k, Vector3(x, 1.0, -0.93), Vector3(x + 0.05, 0.0, -0.75), 0.012, Color(0.86, 0.8, 0.6))
			for q in [Vector2(-1.75, -1.82), Vector2(1.75, -1.82), Vector2(-1.75, -1.0), Vector2(1.75, -1.0), Vector2(0, -1.0)]:
				bb(k, Vector3(q.x - 0.07, 1.04, q.y - 0.05), Vector3(q.x + 0.07, 1.1, q.y + 0.05), Color(0.66, 0.36, 0.28))
			# the stock platform: pallets stacked three high
			for i in 3:
				for j in 2:
					var px := -0.74 + i * 0.74
					var pz := -0.52 + j * 0.62
					for m in 3:
						for r in 3:
							bb(k, Vector3(px - 0.33 + r * 0.29, m * 0.18, pz - 0.29), Vector3(px - 0.25 + r * 0.29, m * 0.18 + 0.1, pz + 0.29), Color(0.6, 0.47, 0.32).darkened(0.05 * ((i + j + m) % 3)))
						bb(k, Vector3(px - 0.36, m * 0.18 + 0.1, pz - 0.29), Vector3(px + 0.36, m * 0.18 + 0.18, pz + 0.29), Color(0.7, 0.56, 0.38).darkened(0.05 * ((i + j + m + 1) % 3)))
			bb(k, Vector3(-1.1, 0.54, -0.82), Vector3(1.1, 0.565, 0.42), Color(0.8, 0.66, 0.46))
			# a pallet jack, a hand truck, sacks, a chalkboard, lights
			bb(k, Vector3(1.3, 0.05, -0.75), Vector3(1.42, 0.1, -0.2), Color(0.9, 0.3, 0.22))
			bb(k, Vector3(1.6, 0.05, -0.75), Vector3(1.72, 0.1, -0.2), Color(0.9, 0.3, 0.22))
			bb(k, Vector3(1.28, 0.05, -0.85), Vector3(1.74, 0.3, -0.75), Color(0.9, 0.3, 0.22))
			seg(k, Vector3(1.51, 0.3, -0.85), Vector3(1.51, 1.0, -0.98), 0.04, Color(0.9, 0.3, 0.22))
			bb(k, Vector3(1.4, 0.98, -1.0), Vector3(1.62, 1.03, -0.96), Color(0.15, 0.15, 0.16))
			seg(k, Vector3(-1.45, 0, -0.5), Vector3(-1.45, 1.1, -0.65), 0.03, Color(0.3, 0.5, 0.8))
			seg(k, Vector3(-1.7, 0, -0.5), Vector3(-1.7, 1.1, -0.65), 0.03, Color(0.3, 0.5, 0.8))
			bb(k, Vector3(-1.75, 0.02, -0.52), Vector3(-1.4, 0.05, -0.38), Color(0.3, 0.5, 0.8))
			for i in 3:
				bx(k, Vector3(0.36, 0.16, 0.26), Color(0.88, 0.86, 0.78), Vector3(-1.58, 0.1 + i * 0.16, -0.68), Vector3(0, i * 25.0, 0))
			for sx in [0.97, 1.3]:
				seg(k, Vector3(sx, 0, 0.5), Vector3(sx, 1.1, 0.42), 0.03, Color(0.5, 0.36, 0.24))
			bb(k, Vector3(0.95, 0.65, 0.4), Vector3(1.32, 1.05, 0.43), Color(0.2, 0.22, 0.2))
			bb(k, Vector3(1.0, 0.95, 0.43), Vector3(1.27, 0.98, 0.435), Color(0.9, 0.9, 0.86))
			for sx in [-1.8, 1.8]:
				bb(k, Vector3(sx - 0.04, 0, -0.9), Vector3(sx + 0.04, 2.0, -0.82), Color(0.5, 0.36, 0.24))
			ArchKit.string_lights(k, Vector3(-1.8, 1.95, -0.86), Vector3(1.8, 1.95, -0.86), 14)
			drum(k, Vector3(-1.25, 0, -0.68), Color(0.3, 0.5, 0.74), 0.12, 0.42)
		1:
			# steel pallet racking under a canopy, a forklift, a loading dock
			var ch := 2.6
			racking(k, Vector3(0, 0, -1.42), 3.5, 0.7, [0.1, 0.85, 1.6], Color(0.92, 0.5, 0.2), Color(0.26, 0.42, 0.68), true, 1)
			for x in [-1.8, -0.6, 0.6, 1.8]:
				bb(k, Vector3(x - 0.05, 0, -0.95), Vector3(x + 0.05, ch, -0.85), p["trim"])
				bb(k, Vector3(x - 0.05, 0, -1.88), Vector3(x + 0.05, ch, -1.8), p["trim"])
			bb(k, Vector3(-1.86, ch, -1.9), Vector3(1.86, ch + 0.1, -0.8), p["trim"])
			bb(k, Vector3(-1.84, ch + 0.1, -1.88), Vector3(1.84, ch + 0.12, -0.82), p["roof"])
			for i in 12:
				bb(k, Vector3(-1.84 + i * 0.335, ch + 0.12, -1.88), Vector3(-1.8 + i * 0.335, ch + 0.13, -0.82), p["roof"].darkened(0.1))
			bb(k, Vector3(-1.86, ch - 0.12, -0.82), Vector3(1.86, ch, -0.78), p["accent"])
			for x in [-1.2, 0.0, 1.2]:
				bx(k, Vector3(0.3, 0.05, 0.12), lit(p["glow"], 0.35), Vector3(x, ch - 0.05, -1.2))
			# loading dock: concrete with a yellow nose and rubber bumpers
			bb(k, Vector3(-1.1, 0, -0.82), Vector3(1.1, 0.56, 0.42), Color(0.72, 0.72, 0.7))
			bb(k, Vector3(-1.12, 0.5, 0.38), Vector3(1.12, 0.56, 0.44), p["accent"])
			for i in 8:
				bx(k, Vector3(0.1, 0.05, 0.005), Color(0.15, 0.15, 0.16), Vector3(-0.98 + i * 0.28, 0.53, 0.445), Vector3(0, 0, 45))
			for sx in [-0.7, 0.7]:
				bb(k, Vector3(sx - 0.1, 0.15, 0.42), Vector3(sx + 0.1, 0.42, 0.5), Color(0.15, 0.15, 0.16))
			for i in 4:
				bb(k, Vector3(-1.1 + i * 0.73, 0.0, 0.42), Vector3(-1.08 + i * 0.73, 0.56, 0.43), Color(0.62, 0.62, 0.6))
			forklift(k, Vector3(1.5, 0, -0.45), 180.0, p["accent"])
			# a parts cage, a fire point, cones
			mesh_fence(k, Vector3(-1.85, 0, -0.75), Vector3(-1.25, 0, -0.75), 1.4)
			mesh_fence(k, Vector3(-1.25, 0, -0.75), Vector3(-1.25, 0, -0.2), 1.4)
			for i in 2:
				crate(k, Vector3(-1.6, i * 0.3, -0.45), Vector3(0.36, 0.3, 0.36), i * 10.0, Color(0.36, 0.5, 0.36))
			for q in [Vector2(-1.4, 0.2), Vector2(1.2, 0.6)]:
				k.cone(0.08, 0.28, Color(0.98, 0.5, 0.2), at(q.x, 0.03, q.y), 8)
				bb(k, Vector3(q.x - 0.1, 0.03, q.y - 0.1), Vector3(q.x + 0.1, 0.05, q.y + 0.1), Color(0.98, 0.5, 0.2))
			bb(k, Vector3(-1.86, 0.9, -0.8), Vector3(-1.82, 1.3, -0.6), Color(0.9, 0.2, 0.18))
		2:
			# a white logistics shed with two roll-up doors and a conveyor
			var sh := 2.5
			ArchKit.block(k, Vector3(0, 0, -1.37), Vector3(3.7, sh, 1.02), t, "", 1)
			for sx in [-0.75, 0.75]:
				ArchKit.rollup(k, at(sx, 0, -0.86), 0.9, 1.6, Color(0.3, 0.66, 0.68), 0.55 if sx < 0 else 0.0)
				bb(k, Vector3(sx - 0.55, 1.75, -0.86), Vector3(sx + 0.55, 1.8, -0.7), Color(0.95, 0.95, 0.96))
			bb(k, Vector3(-1.85, sh - 0.45, -0.86), Vector3(1.85, sh - 0.35, -0.84), p["trim"])
			bb(k, Vector3(-0.32, sh - 0.3, -0.86), Vector3(0.32, sh + 0.25, -0.8), Color(0.97, 0.97, 0.98))
			bb(k, Vector3(-0.26, sh - 0.22, -0.8), Vector3(-0.06, sh + 0.0, -0.79), ac)
			bb(k, Vector3(-0.02, sh - 0.15, -0.8), Vector3(0.26, sh - 0.07, -0.79), p["dark"])
			ArchKit.window_row(k, at(-1.55, 1.5, -0.86), 0.4, 0.5, t)
			ArchKit.window_row(k, at(1.55, 1.5, -0.86), 0.4, 0.5, t)
			# the dock with a conveyor along its back
			bb(k, Vector3(-1.1, 0, -0.82), Vector3(1.1, 0.5, 0.42), Color(0.9, 0.91, 0.92))
			bb(k, Vector3(-1.12, 0.5, -0.84), Vector3(1.12, 0.56, 0.44), Color(0.82, 0.84, 0.86))
			bb(k, Vector3(-1.12, 0.3, 0.42), Vector3(1.12, 0.36, 0.44), p["trim"])
			bb(k, Vector3(-1.1, 0.56, -0.8), Vector3(1.1, 0.62, -0.62), Color(0.3, 0.32, 0.36))
			for i in 14:
				bb(k, Vector3(-1.08 + i * 0.155, 0.62, -0.79), Vector3(-1.03 + i * 0.155, 0.63, -0.63), Color(0.5, 0.52, 0.56))
			k.box(Vector3(0.5, 0.06, 0.6), Color(0.3, 0.32, 0.36), xf(Vector3(-0.75, 0.72, -0.98), Vector3(-18, 0, 0)))
			# planters, bollards, a bike rack, a delivery van
			for sx in [-1.0, 1.0]:
				ArchKit.planter(k, Vector3(sx * 1.55, 0, -0.6), t, 0.5, true)
				for i in 2:
					cy(k, 0.05, 0.6, Color(0.95, 0.95, 0.96), Vector3(sx * (1.22 + i * 0.0), 0, 0.15 + i * 0.25), 8)
					cy(k, 0.052, 0.04, p["trim"], Vector3(sx * 1.22, 0.45, 0.15 + i * 0.25), 8)
		3:
			# an automated high-bay: steel cladding, a glazed slot onto the racks
			var hb := 4.4
			bb(k, Vector3(-1.86, 0, -1.88), Vector3(1.86, hb, -0.86), p["wall"])
			ArchKit.corrugated(k, at(0, 0, -0.86), 3.7, hb, p["wall2"], 0.16)
			bb(k, Vector3(-1.3, 0.6, -0.84), Vector3(1.3, hb - 0.4, -0.8), p["dark"])
			for i in 5:
				for j in 6:
					bb(k, Vector3(-1.22 + i * 0.5, 0.75 + j * 0.55, -0.8), Vector3(-0.82 + i * 0.5, 1.15 + j * 0.55, -0.79), [Color(0.76, 0.62, 0.42), Color(0.3, 0.5, 0.8), Color(0.86, 0.86, 0.84)][(i + j * 2) % 3])
			for j in 7:
				bb(k, Vector3(-1.3, 0.68 + j * 0.55, -0.79), Vector3(1.3, 0.72 + j * 0.55, -0.77), Color(0.92, 0.5, 0.2))
			# the stacker crane mast in the slot
			bb(k, Vector3(0.12, 0.6, -0.78), Vector3(0.24, hb - 0.4, -0.72), p["accent"])
			bb(k, Vector3(-0.05, 2.0, -0.76), Vector3(0.42, 2.2, -0.62), p["accent"])
			bb(k, Vector3(0.0, 2.2, -0.74), Vector3(0.36, 2.45, -0.64), Color(0.76, 0.62, 0.42))
			for sx in [-1.3, 1.3]:
				bb(k, Vector3(sx - 0.06, 0.55, -0.84), Vector3(sx + 0.06, hb - 0.35, -0.76), p["trim"])
			bb(k, Vector3(-1.36, 0.55, -0.84), Vector3(1.36, 0.6, -0.76), p["trim"])
			bb(k, Vector3(-1.36, hb - 0.4, -0.84), Vector3(1.36, hb - 0.35, -0.76), p["trim"])
			bb(k, Vector3(-1.9, hb, -1.9), Vector3(1.9, hb + 0.16, -0.84), p["trim"])
			bb(k, Vector3(-1.84, hb + 0.16, -1.86), Vector3(1.84, hb + 0.18, -0.88), p["roof"])
			bb(k, Vector3(-1.88, hb + 0.06, -0.84), Vector3(1.88, hb + 0.09, -0.82), lit(p["accent2"], 0.45))
			# a catwalk across the front at 2.6 m, stairs at the side
			ArchKit.catwalk(k, Vector3(-1.8, 2.6, -0.65), Vector3(1.8, 2.6, -0.65), 0.34, t, false)
			for x in [-1.75, 0.0, 1.75]:
				bb(k, Vector3(x - 0.04, 0, -0.68), Vector3(x + 0.04, 2.6, -0.62), p["trim"])
			# the dock: a roller conveyor bed with guard rails
			bb(k, Vector3(-1.1, 0, -0.82), Vector3(1.1, 0.45, 0.42), p["dark"])
			for i in 16:
				hcy(k, 0.035, 1.2, Color(0.72, 0.75, 0.8), Vector3(-1.04 + i * 0.139, 0.5, -0.2), false, 6)
			for sz in [-0.82, 0.42]:
				bb(k, Vector3(-1.1, 0.45, sz - 0.03), Vector3(1.1, 0.56, sz + 0.03), p["trim"])
			bb(k, Vector3(-1.1, 0.4, 0.42), Vector3(1.1, 0.43, 0.45), lit(p["accent2"], 0.45))
			for sx in [-1.12, 1.12]:
				stack_light(k, Vector3(sx, 0.56, 0.38), 0.4)
			# roof: a chiller, a hatch, beacon
			ArchKit.chiller(k, at(0, hb + 0.18, -1.3), 1.2, t, 2)
			ArchKit.beacon(k, Vector3(1.75, hb + 0.18, -0.95), 0.5)
			ArchKit.beacon(k, Vector3(-1.75, hb + 0.18, -0.95), 0.5)
		_:
			# a graphite robotic vault: glowing shuttle lanes, a brass vault door
			var vh := 4.2
			bb(k, Vector3(-1.86, 0, -1.88), Vector3(1.86, vh, -0.86), p["wall"])
			bb(k, Vector3(-1.88, 0, -1.9), Vector3(1.88, 0.2, -0.84), p["dark"])
			for j in 6:
				var y := 0.6 + j * 0.55
				bb(k, Vector3(-1.86, y, -0.86), Vector3(1.86, y + 0.04, -0.82), lit(p["accent2"], 0.45))
				for i in 3:
					var sx := -1.5 + fposmod(i * 1.3 + j * 0.77, 3.0)
					bb(k, Vector3(sx - 0.12, y + 0.04, -0.86), Vector3(sx + 0.12, y + 0.16, -0.8), p["trim"])
			for sx in [-1.84, -0.62, 0.62, 1.84]:
				bb(k, Vector3(sx - 0.05, 0, -0.88), Vector3(sx + 0.05, vh, -0.8), p["trim"])
			bb(k, Vector3(-1.9, vh - 0.1, -1.9), Vector3(1.9, vh, -0.8), p["trim"])
			bb(k, Vector3(-1.84, vh, -1.86), Vector3(1.84, vh + 0.02, -0.86), p["roof"])
			# the vault door
			k.cyl(0.55, 0.08, p["trim"], xf(Vector3(0, 1.4, -0.86), Vector3(90, 0, 0)), 16)
			k.cyl(0.45, 0.1, p["wall2"], xf(Vector3(0, 1.4, -0.84), Vector3(90, 0, 0)), 16)
			k.torus(0.3, 0.03, lit(p["glow"], 0.4), xf(Vector3(0, 1.4, -0.73), Vector3(90, 0, 0)), 16, 4)
			for i in 3:
				bx(k, Vector3(0.5, 0.04, 0.04), p["trim"], Vector3(0, 1.4, -0.72), Vector3(0, 0, i * 60.0))
			# the dock: graphite with glowing shuttle lanes
			bb(k, Vector3(-1.1, 0, -0.82), Vector3(1.1, 0.5, 0.42), p["wall"])
			bb(k, Vector3(-1.12, 0.5, -0.84), Vector3(1.12, 0.56, 0.44), p["wall2"])
			for i in 4:
				bb(k, Vector3(-0.9 + i * 0.6 - 0.015, 0.56, -0.84), Vector3(-0.9 + i * 0.6 + 0.015, 0.565, 0.44), lit(p["accent2"], 0.45))
			bb(k, Vector3(-1.12, 0.5, 0.42), Vector3(1.12, 0.56, 0.46), p["trim"])
			bb(k, Vector3(-1.1, 0.2, 0.42), Vector3(1.1, 0.24, 0.43), lit(p["glow"], 0.45))
			# the crown: a drone pad and a brass mast
			ArchKit.drone_pad(k, Vector3(0, vh + 0.02, -1.37), 0.45)
			for sx in [-1.75, 1.75]:
				ArchKit.beacon(k, Vector3(sx, vh, -0.95), 0.6)
	_depot_more(k, t)
	_depot_more2(k, t)
	_depot_more3(k, t)
	return k.commit()


## How tall the depot stands (labels float above it).
static func depot_height(t: int) -> float:
	return [2.0, 2.8, 2.8, 5.6, 5.1][clampi(t, 0, 4)]



## Second pass of chip-fab detail (facade kit, roof clutter, glow).
static func _fab_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("fab")
	var yel := Color(1.0, 0.82, 0.36)
	match t:
		0:
			# a bike against the crate pile, a spare monitor, solder fume fan
			for sz in [-0.62, -0.92]:
				k.torus(0.13, 0.015, Color(0.15, 0.15, 0.16), xf(Vector3(1.05, 0.15, sz), Vector3(0, 0, 90)), 10, 3)
			seg(k, Vector3(1.05, 0.15, -0.62), Vector3(1.05, 0.42, -0.78), 0.02, Color(0.8, 0.3, 0.24))
			seg(k, Vector3(1.05, 0.15, -0.92), Vector3(1.05, 0.42, -0.78), 0.02, Color(0.8, 0.3, 0.24))
			seg(k, Vector3(1.05, 0.42, -0.78), Vector3(1.05, 0.45, -0.66), 0.02, Color(0.8, 0.3, 0.24))
			bb(k, Vector3(1.02, 0.44, -0.84), Vector3(1.08, 0.47, -0.74), Color(0.15, 0.15, 0.16))
			bb(k, Vector3(-0.92, 0.0, -1.1), Vector3(-0.6, 0.28, -0.85), Color(0.8, 0.78, 0.7))
			bb(k, Vector3(-0.88, 0.04, -0.85), Vector3(-0.64, 0.24, -0.84), Color(0.2, 0.22, 0.26))
			for i in 4:
				bx(k, Vector3(0.14, 0.01, 0.1), Color(0.2, 0.52, 0.32), Vector3(-0.2 + i * 0.12, 0.04, -0.62 + (i % 2) * 0.05), Vector3(0, i * 30.0, 0))
		1:
			# booth side signage, a stack light, a fire extinguisher, a pallet
			bx(k, Vector3(0.5, 0.18, 0.02), p["accent"], Vector3(0.0, 1.9, -0.6))
			bx(k, Vector3(0.4, 0.08, 0.01), p["dark"], Vector3(0.0, 1.9, -0.588))
			stack_light(k, Vector3(0.82, 2.27, -0.66), 0.25)
			cy(k, 0.06, 0.4, Color(0.86, 0.2, 0.18), Vector3(0.75, 0, -0.5), 8)
			pallet(k, Vector3(0.6, 0, -0.95), 0.5, 0.4)
		2:
			# ground-floor gowning windows, teal roof band, solar strip, bike rack
			skin(k, Vector3(-0.98, 0, -1.88), Vector3(0.98, 3.3, -0.5), t, "lrb", 0.4)
			for sx in [-1.0, 1.0]:
				bb(k, Vector3(sx * 0.48, 0.3, -0.505), Vector3(sx * 0.9, 1.25, -0.49), p["glass"])
				for i in 3:
					bb(k, Vector3(sx * (0.48 + i * 0.21) - 0.015, 0.3, -0.49), Vector3(sx * (0.48 + i * 0.21) + 0.015, 1.25, -0.48), p["frame"])
				bb(k, Vector3(minf(sx * 0.46, sx * 0.92), 1.25, -0.5), Vector3(maxf(sx * 0.46, sx * 0.92), 1.3, -0.46), p["trim"])
			bb(k, Vector3(-0.99, 3.1, -0.505), Vector3(0.99, 3.18, -0.49), p["trim"])
			for i in 4:
				k.box(Vector3(0.36, 0.03, 0.2), Color(0.16, 0.24, 0.44), xf(Vector3(-0.6 + i * 0.4, 3.45, -0.75), Vector3(-20, 0, 0)))
		3:
			# process pipes up the bay front, a FAB 1 board, hazard diamonds
			skin(k, Vector3(-0.94, 0, -1.84), Vector3(0.94, 3.8, -0.62), t, "lrb")
			for i in 3:
				var px := -0.88 + i * 0.07
				run(k, [Vector3(px, 0.05, -0.5), Vector3(px, 3.6, -0.5), Vector3(px, 3.6, -0.75)], 0.025, [Color(0.86, 0.6, 0.3), Color(0.86, 0.86, 0.84), Color(0.36, 0.6, 0.86)][i])
				for y in [0.8, 1.9, 3.0]:
					bb(k, Vector3(px - 0.04, y, -0.54), Vector3(px + 0.04, y + 0.04, -0.46), p["trim"])
			bb(k, Vector3(0.42, 2.85, -0.52), Vector3(0.92, 3.25, -0.48), p["dark"])
			bb(k, Vector3(0.48, 2.98, -0.48), Vector3(0.86, 3.12, -0.47), lit(yel, 0.4))
			for sx in [0.5, 0.75]:
				bx(k, Vector3(0.14, 0.14, 0.02), Color(0.98, 0.84, 0.3), Vector3(sx, 1.0, -0.52), Vector3(0, 0, 45))
			# roof: ducts from the stacks to the scrubber, small AC units, rods
			for sx in [-0.62, 0.62]:
				run(k, [Vector3(sx, 4.3, -1.55), Vector3(sx * 0.5, 4.3, -1.55), Vector3(sx * 0.5, 4.3, -1.75)], 0.07, Color(0.78, 0.8, 0.82), 8)
			for sx in [-0.65, 0.65]:
				ArchKit.ac_unit(k, at(sx, 3.98, -1.05), t, 0.45)
			for q in [Vector2(-0.95, -1.85), Vector2(0.95, -1.85)]:
				cy(k, 0.012, 0.6, Color(0.6, 0.62, 0.66), Vector3(q.x, 3.98, q.y), 4)
		_:
			# graphite seams, brass pilasters, side fins, crown beams, a manifold
			skin(k, Vector3(-0.8, 0, -1.78), Vector3(0.8, 3.4, -0.62), t, "b")
			skin(k, Vector3(-0.8, 4.6, -1.78), Vector3(0.8, 5.4, -0.62), t, "lrb")
			skin(k, Vector3(-0.95, 3.42, -1.86), Vector3(0.95, 4.58, -0.36), t, "lrb")
			seams(k, at(0, 0.3, -0.62), 1.6, 5.0, 8, 10, p["wall2"])
			for sx in [-1.0, 1.0]:
				var side_face := xf(Vector3(sx * 0.8, 0, -1.2), Vector3(0, 90 * sx, 0))
				fins(k, side_face * at(0, 1.0, 0), 1.1, 2.3, 5, 0.1)
				seams(k, side_face * at(0, 3.4, 0.0), 1.1, 2.0, 5, 4, p["wall2"])
			bb(k, Vector3(-0.97, 3.36, -0.36), Vector3(0.97, 3.38, -0.34), lit(p["glow"], 0.4))
			for i in 8:
				var a := TAU * i / 8.0
				var q := Vector3(cos(a) * 0.58, 5.4, -1.2 + sin(a) * 0.45)
				if i % 2 == 1:
					bb(k, Vector3(q.x - 0.03, q.y, q.z - 0.03), Vector3(q.x + 0.03, q.y + 0.9, q.z + 0.03), p["trim"])
				bx(k, Vector3(0.015, 0.8, 0.015), lit(Color(0.8, 0.6, 1.0), 0.35), Vector3(cos(a) * 0.3, 5.95, -1.2 + sin(a) * 0.25))
			k.torus(0.62, 0.025, p["trim"], at(0, 5.55, -1.2), 16, 3)
			run(k, [Vector3(-1.0, 1.75, -0.5), Vector3(-0.7, 1.75, -0.5), Vector3(-0.7, 1.75, -0.6)], 0.05, lit(p["glow"], 0.45))
			run(k, [Vector3(1.0, 1.75, -0.5), Vector3(0.7, 1.75, -0.5), Vector3(0.7, 1.75, -0.6)], 0.05, lit(p["glow"], 0.45))
			for sx in [-0.18, 0.18]:
				for y in [0.15, 0.55, 0.95]:
					cy(k, 0.17, 0.03, p["trim"].lightened(0.15), Vector3(sx, y, -0.42), 10)



## Second pass of data-refinery detail.
static func _refinery_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("refinery")
	match t:
		0:
			# old towers and a printer in the back corner, a dish on the shed
			for i in 3:
				bb(k, Vector3(0.22 + i * 0.2, 0, -1.85), Vector3(0.38 + i * 0.2, 0.42 - i * 0.04, -1.45), Color(0.86, 0.84, 0.76).darkened(i * 0.05))
				bb(k, Vector3(0.24 + i * 0.2, 0.3 - i * 0.04, -1.449), Vector3(0.36 + i * 0.2, 0.33 - i * 0.04, -1.445), Color(0.2, 0.2, 0.22))
				bb(k, Vector3(0.33 + i * 0.2, 0.08, -1.449), Vector3(0.35 + i * 0.2, 0.1, -1.445), lit(Color(0.4, 1.0, 0.5), 0.4))
			bb(k, Vector3(0.25, 0.42, -1.85), Vector3(0.6, 0.6, -1.55), Color(0.9, 0.9, 0.88))
			bb(k, Vector3(0.3, 0.6, -1.7), Vector3(0.55, 0.62, -1.56), Color(0.96, 0.95, 0.9))
			k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.08, 0.015), Vector2(0.16, 0.05), Vector2(0.155, 0.05), Vector2(0.075, 0.02), Vector2(0, 0.008)]), Color(0.92, 0.92, 0.92), xf(Vector3(1.62, 1.55, -0.38), Vector3(-60, 20, 0)), 10)
			seg(k, Vector3(1.62, 1.5, -0.44), Vector3(1.62, 1.55, -0.38), 0.025, Color(0.5, 0.52, 0.56))
			cable(k, Vector3(1.6, 1.45, -0.44), Vector3(0.02, 0.74, -1.68), Color(0.15, 0.15, 0.16), 0.3, 0.015)
			# a recycling bin of paper, a mop bucket
			bb(k, Vector3(-0.1, 0, -1.05), Vector3(0.12, 0.38, -0.85), Color(0.3, 0.5, 0.8))
			for i in 4:
				bx(k, Vector3(0.14, 0.01, 0.18), Color(0.96, 0.95, 0.9), Vector3(0.0 + (i % 2) * 0.03, 0.39 + i * 0.01, -0.95), Vector3(0, i * 30.0, 0))
		1:
			# hopper sign, pendant lamps, a data bin at the chute, fans
			bb(k, Vector3(-0.35, 1.7, -0.8), Vector3(0.25, 1.88, -0.79), p["accent"])
			bb(k, Vector3(-0.3, 1.74, -0.789), Vector3(0.2, 1.84, -0.785), p["dark"])
			for x in [-0.4, 0.3]:
				seg(k, Vector3(x, 2.05, -0.9), Vector3(x, 1.8, -0.9), 0.01, Color(0.2, 0.2, 0.22))
				k.cyl(0.08, 0.06, p["trim"], at(x, 1.74, -0.9), 8, 0.0, 0.03)
				cy(k, 0.06, 0.01, lit(p["glow"], 0.3), Vector3(x, 1.735, -0.9), 8)
			drum(k, Vector3(-0.42, 0, -0.6), Color(0.3, 0.5, 0.8), 0.11, 0.36)
		2:
			# sunshade fins across the atrium, glass skylights on its roof
			for y in [1.0, 1.65, 2.3]:
				bb(k, Vector3(-0.97, y, -0.5), Vector3(0.97, y + 0.04, -0.36), Color(0.97, 0.97, 0.98))
			for i in 4:
				bb(k, Vector3(-0.85 + i * 0.45, 2.74, -0.85), Vector3(-0.55 + i * 0.45, 2.82, -0.6), p["glass"])
			ArchKit.railing(k, Vector3(-0.95, 2.74, -0.52), Vector3(0.95, 2.74, -0.52), 0.4, Color(0.85, 0.86, 0.88), 0.4)
			for i in 3:
				var x := -0.58 + i * 0.58
				k.torus(0.24, 0.02, lit(p["glow"], 0.4), at(x, 3.0, -1.2), 14, 3)
			bb(k, Vector3(-0.6, 3.25, -1.25), Vector3(0.6, 3.29, -1.15), Color(0.9, 0.91, 0.92))
			for sx in [-0.3, 0.3]:
				ArchKit.planter(k, Vector3(sx * 0.0 + sx, 2.75, -1.65), t, 0.35)
		3:
			# a flare stack up the stair tower, beacons, valves, an air cooler
			skin(k, Vector3(-0.95, 0, -0.95), Vector3(-0.2, 1.2, -0.5), t, "l")
			skin_cyl(k, Vector3(-0.45, 0.3, -1.3), 0.34, 6.2, t, 12, 0.55)
			skin_cyl(k, Vector3(0.5, 0.3, -1.28), 0.27, 5.0, t, 10, 0.55)
			cy(k, 0.05, 2.6, Color(0.7, 0.72, 0.76), Vector3(-1.72, 3.44, -1.8), 6)
			cy(k, 0.08, 0.15, p["dark"], Vector3(-1.72, 6.04, -1.8), 6)
			k.cone(0.07, 0.25, lit(Color(1.0, 0.6, 0.2), 0.3), at(-1.72, 6.19, -1.8), 6)
			for tw in [[Vector3(-0.45, 0, -1.3), 6.2], [Vector3(0.5, 0, -1.28), 5.0]]:
				var c: Vector3 = tw[0]
				ArchKit.beacon(k, c + Vector3(0, float(tw[1]) + 0.98, 0), 0.15)
			for q in [Vector3(-0.15, 0.6, -0.9), Vector3(0.3, 0.6, -0.9), Vector3(0.62, 1.6, -0.95)]:
				bx(k, Vector3(0.08, 0.1, 0.08), Color(0.3, 0.32, 0.36), q)
				k.torus(0.06, 0.012, Color(0.9, 0.25, 0.2), xf(q + Vector3(0, 0.08, 0), Vector3(0, 0, 0)), 8, 3)
			# an air-cooled exchanger on the control room roof
			bb(k, Vector3(-0.92, 1.28, -0.93), Vector3(-0.25, 1.5, -0.55), p["metal"])
			for sx in [-0.75, -0.42]:
				cy(k, 0.14, 0.03, Color(0.22, 0.23, 0.26), Vector3(sx, 1.5, -0.74), 10)
				bx(k, Vector3(0.26, 0.012, 0.03), Color(0.55, 0.57, 0.6), Vector3(sx, 1.535, -0.74), Vector3(0, 30, 0))
			bb(k, Vector3(-0.85, 0.85, -0.49), Vector3(-0.3, 0.98, -0.48), lit(ac, 0.4))
			ArchKit.cable_tray(k, Vector3(-0.98, 2.72, -0.38), Vector3(0.98, 2.72, -0.38), t)
		_:
			# a glowing lid on the crown, data streams, buttresses, base fins
			skin_cyl(k, Vector3(0, 0, -1.15), 0.72, 0.35, t, 16, 0.3)
			cy(k, 0.66, 0.02, lit(ac, 0.35), Vector3(0, 7.24, -1.15), 12)
			for i in 12:
				var a := TAU * i / 12.0
				bx(k, Vector3(0.018, 5.4, 0.018), lit(Color(0.8, 0.95, 1.0), 0.3), Vector3(cos(a) * 0.425, 3.6, -1.15 + sin(a) * 0.425))
			for i in 6:
				var a := TAU * i / 6.0 + 0.5
				var q := Vector3(cos(a) * 0.64, 0, -1.15 + sin(a) * 0.62)
				for y in [1.6, 3.2, 4.8]:
					bb(k, Vector3(q.x - 0.085, y, q.z - 0.085), Vector3(q.x + 0.085, y + 0.06, q.z + 0.085), p["trim"])
			for sx in [-1.0, 1.0]:
				seg(k, Vector3(sx * 1.02, 2.4, -1.2), Vector3(sx * 0.68, 4.0, -1.2), 0.06, p["trim"])
				seg(k, Vector3(sx * 1.02, 2.4, -0.7), Vector3(sx * 0.62, 3.3, -0.85), 0.05, p["trim"])
			for i in 10:
				var a := TAU * i / 10.0
				bx(k, Vector3(0.05, 0.3, 0.1), p["wall2"], Vector3(cos(a) * 0.72, 0.5, -1.15 + sin(a) * 0.68), Vector3(0, -rad_to_deg(a), 0))
				bx(k, Vector3(0.015, 0.26, 0.015), lit(p["glow"], 0.4), Vector3(cos(a) * 0.76, 0.5, -1.15 + sin(a) * 0.72))
			cy(k, 0.74, 0.02, lit(ac, 0.45), Vector3(0, 0.03, -1.15), 12)
			screen(k, at(0, 0.8, -0.18), 0.4, 0.1, ac, 6)




## Second pass of fine-tune lab detail.
static func _tune_lab_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("tune_lab")
	match t:
		0:
			# a guitar on a stand, a beanbag, a floor lamp, sticky notes
			k.cyl(0.11, 0.06, Color(0.78, 0.42, 0.2), xf(Vector3(0.8, 0.28, -1.45), Vector3(-75, 0, 0)), 10)
			k.cyl(0.08, 0.06, Color(0.78, 0.42, 0.2), xf(Vector3(0.8, 0.48, -1.5), Vector3(-75, 0, 0)), 10)
			seg(k, Vector3(0.8, 0.55, -1.5), Vector3(0.8, 0.95, -1.6), 0.03, Color(0.3, 0.2, 0.14))
			bb(k, Vector3(0.76, 0.95, -1.63), Vector3(0.84, 1.03, -1.58), Color(0.2, 0.14, 0.1))
			for sx in [-1.0, 1.0]:
				seg(k, Vector3(0.8, 0.3, -1.42), Vector3(0.8 + sx * 0.1, 0, -1.3), 0.015, Color(0.2, 0.2, 0.22))
			k.sphere(0.22, Color(0.32, 0.5, 0.7), xf(Vector3(0.72, 0.12, -0.6), Vector3.ZERO, Vector3(1.0, 0.6, 1.0)), 10, 6)
			cy(k, 0.1, 0.03, Color(0.2, 0.2, 0.22), Vector3(-0.55, 0, -0.9), 8)
			cy(k, 0.015, 1.4, Color(0.2, 0.2, 0.22), Vector3(-0.55, 0, -0.9), 5)
			k.cyl(0.12, 0.14, Color(0.96, 0.92, 0.8), at(-0.55, 1.4, -0.9), 8, 0.0, 0.07)
			cy(k, 0.1, 0.01, lit(Color(1.0, 0.85, 0.6), 0.3), Vector3(-0.55, 1.395, -0.9), 8)
			for i in 9:
				bx(k, Vector3(0.06, 0.06, 0.01), [Color(1.0, 0.9, 0.4), Color(1.0, 0.6, 0.7), Color(0.6, 0.9, 1.0)][i % 3], Vector3(-0.86 + (i % 3) * 0.08, 1.85 - (i / 3) * 0.08, BK + 0.12))
		1:
			# an ON AIR light, a ladder and rail on the booth, cable drops
			bb(k, Vector3(-0.2, 1.95, -0.8), Vector3(0.2, 2.1, -0.76), Color(0.15, 0.15, 0.16))
			bb(k, Vector3(-0.17, 1.97, -0.76), Vector3(0.17, 2.08, -0.755), lit(Color(1.0, 0.3, 0.25), 0.4))
			ArchKit.railing(k, Vector3(-0.92, 2.3, -0.82), Vector3(0.92, 2.3, -0.82), 0.5, p["accent"], 0.45)
			ArchKit.railing(k, Vector3(-0.92, 2.3, -1.84), Vector3(-0.92, 2.3, -0.82), 0.5, p["accent"], 0.45)
			for i in 4:
				seg(k, Vector3(-0.6 + i * 0.4, 2.35, -0.95), Vector3(-0.6 + i * 0.4, 1.9, -0.8), 0.02, Color(0.15, 0.15, 0.16))
			bx(k, Vector3(0.14, 0.14, 0.02), Color(0.96, 0.96, 0.94), Vector3(0.75, 1.6, -0.79))
			bx(k, Vector3(0.11, 0.11, 0.01), Color(0.2, 0.2, 0.22), Vector3(0.75, 1.6, -0.778))
		2:
			# fins down the studio's sides, a ticker, a rooftop rail
			skin(k, Vector3(-0.98, 0, -1.88), Vector3(0.98, 2.9, -0.46), t, "lrb", 0.4)
			bb(k, Vector3(-0.8, 1.52, WF + 0.06), Vector3(0.8, 1.56, WF + 0.075), lit(Color(1.0, 0.85, 0.5), 0.35))
			for i in 12:
				bb(k, Vector3(-0.78 + i * 0.135, 1.525, WF + 0.075), Vector3(-0.72 + i * 0.135, 1.555, WF + 0.08), Color(0.2, 0.2, 0.22))
			ArchKit.railing(k, Vector3(-0.95, 2.95, -0.5), Vector3(0.95, 2.95, -0.5), 0.35, Color(0.85, 0.86, 0.88), 0.4)
			for i in 3:
				bx(k, Vector3(0.12, 0.08, 0.3), Color(0.95, 0.95, 0.96), Vector3(-0.7 + i * 0.25, 2.95, -0.75))
		3:
			# a second fixed dish, warning lights, louvred plant, a sign
			skin(k, Vector3(-0.96, 0, -1.86), Vector3(0.96, 3.5, -0.6), t, "lrb")
			k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.12, 0.02), Vector2(0.24, 0.07), Vector2(0.23, 0.07), Vector2(0.11, 0.03), Vector2(0, 0.01)]), Color(0.92, 0.92, 0.92), xf(Vector3(0.7, 3.95, -0.8), Vector3(-50, -30, 0)), 10)
			cy(k, 0.03, 0.28, Color(0.6, 0.62, 0.66), Vector3(0.7, 3.67, -0.82), 6)
			for q in [Vector3(-0.25, 5.35, -1.5), Vector3(0.25, 5.35, -1.0)]:
				k.sphere(0.035, lit(Color(1.0, 0.3, 0.25), 0.3), at(q.x, q.y, q.z), 6, 4)
			ArchKit.louvres(k, at(-0.55, 3.67, -1.75), 0.6, 0.4, p["metal"], 4)
			bb(k, Vector3(-0.85, 3.67, -1.85), Vector3(-0.25, 4.07, -1.75), p["wall2"])
			bb(k, Vector3(-0.6, 2.86, -0.4), Vector3(0.6, 3.1, -0.36), p["dark"])
			bb(k, Vector3(-0.54, 2.92, -0.36), Vector3(0.54, 3.04, -0.355), lit(ac, 0.4))
			ArchKit.cable_tray(k, Vector3(0, 3.75, -1.25), Vector3(0, 3.75, -0.7), t)
		_:
			# petal fins round the drum's foot, glowing slots, a floor ring
			for i in 8:
				var a := TAU * (i + 0.5) / 8.0
				if sin(a) > -0.5:
					bx(k, Vector3(0.06, 0.6, 0.26), p["wall2"], Vector3(cos(a) * 0.92, 0.3, -1.02 + sin(a) * 0.92), Vector3(0, -rad_to_deg(a), 0))
					bx(k, Vector3(0.016, 0.5, 0.016), lit(ac, 0.4), Vector3(cos(a) * 1.05, 0.3, -1.02 + sin(a) * 1.05))
			cy(k, 0.86, 0.015, lit(ac, 0.45), Vector3(0, 0.035, -1.02), 12)
			for i in 8:
				var a := TAU * i / 8.0
				bx(k, Vector3(0.05, 0.05, 0.05), lit(ac, 0.35), Vector3(cos(a) * 0.45, 4.05, -1.02 + sin(a) * 0.45))



## Second pass of HBM works detail.
static func _hbm_works_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("hbm_works")
	var chip := Color(0.16, 0.17, 0.2)
	match t:
		0:
			# a bare bulb over the bench, a stool, a crate of chips, a sign
			seg(k, Vector3(-0.1, 2.08, -1.45), Vector3(-0.1, 1.75, -1.45), 0.01, Color(0.15, 0.15, 0.16))
			k.sphere(0.05, lit(Color(1.0, 0.85, 0.55), 0.3), at(-0.1, 1.72, -1.45), 6, 4)
			cy(k, 0.13, 0.04, Color(0.56, 0.42, 0.28), Vector3(0.3, 0.55, -0.95), 8)
			for i in 3:
				var a := TAU * i / 3.0
				seg(k, Vector3(0.3 + cos(a) * 0.06, 0.55, -0.95 + sin(a) * 0.06), Vector3(0.3 + cos(a) * 0.15, 0, -0.95 + sin(a) * 0.15), 0.025, Color(0.5, 0.36, 0.24))
			crate(k, Vector3(-0.6, 0, -0.8), Vector3(0.4, 0.3, 0.32), 8.0)
			for i in 4:
				bx(k, Vector3(0.06, 0.012, 0.06), chip, Vector3(-0.68 + i * 0.06, 0.31, -0.8 + (i % 2) * 0.05))
			bx(k, Vector3(0.5, 0.16, 0.03), Color(0.94, 0.92, 0.86), Vector3(0.0, 1.75, BK + 0.07), Vector3(0, 0, -2))
			for i in 4:
				bx(k, Vector3(0.08, 0.04, 0.01), [chip, ac][i % 2], Vector3(-0.15 + i * 0.1, 1.75, BK + 0.09))
		1:
			# hazard stripes round the press, a tool cart, pendant lights, a sign
			for i in 10:
				bx(k, Vector3(0.1, 0.006, 0.04), Color(0.1, 0.1, 0.12) if i % 2 else p["accent"], Vector3(-0.55 + i * 0.12, 0.034, -0.85), Vector3(0, 0, 0))
			bb(k, Vector3(-0.9, 0.05, -1.35), Vector3(-0.6, 0.7, -1.05), p["accent2"])
			for j in 3:
				bb(k, Vector3(-0.88, 0.18 + j * 0.17, -1.049), Vector3(-0.62, 0.2 + j * 0.17, -1.045), p["dark"])
			for sz in [-1.33, -1.07]:
				for sx in [-0.88, -0.62]:
					cy(k, 0.03, 0.05, Color(0.15, 0.15, 0.16), Vector3(sx, 0, sz), 6)
			bb(k, Vector3(-0.3, 2.72, -0.9), Vector3(0.3, 2.9, -0.88), p["accent"])
			bb(k, Vector3(-0.26, 2.76, -0.88), Vector3(0.26, 2.86, -0.875), p["dark"])
			for x in [-0.6, 0.6]:
				seg(k, Vector3(x, 3.05, -1.0), Vector3(x, 2.6, -1.0), 0.01, Color(0.2, 0.2, 0.22))
				k.cyl(0.08, 0.06, p["trim"], at(x, 2.54, -1.0), 8, 0.0, 0.03)
				cy(k, 0.06, 0.01, lit(p["glow"], 0.3), Vector3(x, 2.535, -1.0), 8)
			for i in 2:
				drum(k, Vector3(0.62 + i * 0.25, 0, -1.7), Color(0.3, 0.42, 0.62), 0.11, 0.38)
		2:
			# end fins on the stacked facade, a stack logo, a glass canopy
			skin(k, Vector3(-0.98, 0, -1.88), Vector3(0.98, 2.7, -0.62), t, "lrb", 0.4)
			for sx in [-0.95, 0.95]:
				bb(k, Vector3(sx - 0.03, 0.2, -0.64), Vector3(sx + 0.03, 2.6, -0.55), p["trim"])
			bb(k, Vector3(-0.98, 2.56, -0.64), Vector3(0.98, 2.62, -0.55), p["trim"])
			bb(k, Vector3(-0.6, 0.0, -0.55), Vector3(-0.32, 0.02, -0.3), p["trim"])
			for i in 3:
				if i != 1:
					bollard(k, Vector3(-0.85 + i * 0.25, 0, -0.42), t)
		3:
			# skylights and vents on the hall roof, a crane bridge, side glazing
			for i in 3:
				bb(k, Vector3(-0.85 + i * 0.6, 4.08, -1.75), Vector3(-0.45 + i * 0.6, 4.18, -1.55), p["glass"])
			for x in [-0.75, 0.75]:
				cy(k, 0.08, 0.3, p["metal"], Vector3(x, 4.08, -0.75), 8)
				k.cone(0.12, 0.08, p["metal"], at(x, 4.38, -0.75), 8)
			bb(k, Vector3(-0.95, 3.55, -1.25), Vector3(0.95, 3.68, -1.12), p["accent"])
			bb(k, Vector3(-0.15, 3.42, -1.28), Vector3(0.15, 3.55, -1.09), Color(0.3, 0.32, 0.36))
			ArchKit.beacon(k, Vector3(0.9, 4.08, -1.8), 0.4)
			bb(k, Vector3(-0.95, 2.2, -0.52), Vector3(0.95, 2.26, -0.48), p["trim"])
			for i in 6:
				bb(k, Vector3(-0.85 + i * 0.34, 2.26, -0.5), Vector3(-0.83 + i * 0.34, 2.4, -0.48), lit(p["glow"], 0.4))
		_:
			# brass corner pilasters, side TSVs, a glowing halo, collars
			for i in 9:
				var sy := 0.25 + i * 0.57
				var ox := 0.06 * ((i % 2) * 2 - 1)
				skin(k, Vector3(-0.82 + ox, sy, -1.82), Vector3(0.82 + ox, sy + 0.5, -0.62), 3, "flrb", 0.22)
			var top := 0.25 + 9 * 0.57
			for sx in [-0.86, 0.86]:
				for sz in [-1.86, -0.58]:
					bb(k, Vector3(sx - 0.04, 0.25, sz - 0.04), Vector3(sx + 0.04, top, sz + 0.04), p["trim"])
			for i in 9:
				var y := 0.25 + i * 0.57 + 0.5
				for sx in [-0.85, 0.85]:
					bb(k, Vector3(sx - 0.01, y, -1.8), Vector3(sx + 0.01, y + 0.07, -0.64), lit(ac.lightened(0.2), 0.35))
			k.torus(0.95, 0.03, lit(ac, 0.35), xf(Vector3(0, top + 1.4, -1.21), Vector3.ZERO, Vector3(1, 1, 0.65)), 18, 4)
			for i in 6:
				var a := TAU * i / 6.0
				bx(k, Vector3(0.06, 0.06, 0.06), p["trim"], Vector3(cos(a) * 0.95, top + 1.4, -1.21 + sin(a) * 0.62))
			for sx in [-0.98, 0.98]:
				for y in [1.2, 2.4, 3.6]:
					cy(k, 0.065, 0.06, p["trim"], Vector3(sx, y, -0.5), 8)



## Second pass of RLHF gym detail.
static func _rlhf_gym_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("rlhf_gym")
	var good := Color(0.4, 0.9, 0.5)
	var bad := Color(1.0, 0.36, 0.3)
	match t:
		0:
			# a punching bag on the tarp frame, kettlebells, a mini fridge
			seg(k, Vector3(0.75, 2.0, -0.82), Vector3(0.75, 1.55, -0.82), 0.015, Color(0.3, 0.3, 0.32))
			cy(k, 0.12, 0.6, Color(0.7, 0.24, 0.2), Vector3(0.75, 0.95, -0.82), 8)
			cy(k, 0.125, 0.04, Color(0.2, 0.2, 0.22), Vector3(0.75, 1.5, -0.82), 8)
			for i in 3:
				k.sphere(0.07, Color(0.2, 0.2, 0.22), at(0.3 + i * 0.18, 0.07, -0.62), 8, 5)
				k.torus(0.04, 0.012, Color(0.2, 0.2, 0.22), xf(Vector3(0.3 + i * 0.18, 0.15, -0.62), Vector3(90, 0, 0)), 8, 3)
			bb(k, Vector3(-0.92, 0, -1.25), Vector3(-0.62, 0.55, -0.98), Color(0.92, 0.92, 0.9))
			for i in 3:
				cy(k, 0.03, 0.1, [good, bad, ac][i], Vector3(-0.85 + i * 0.08, 0.55, -1.1), 6)
		1:
			# headphones on hooks, a vending machine glow, floor lanes
			for i in 3:
				var mx := -0.65 + i * 0.64
				k.torus(0.05, 0.012, Color(0.15, 0.15, 0.16), xf(Vector3(mx + 0.22, 1.5, -1.79), Vector3(90, 0, 0)), 8, 3, PI)
				bb(k, Vector3(mx - 0.25, 0.03, -1.0), Vector3(mx + 0.25, 0.036, -0.97), p["accent"])
			bb(k, Vector3(-0.95, 0, -0.92), Vector3(-0.62, 1.2, -0.75), Color(0.85, 0.3, 0.26))
			bb(k, Vector3(-0.92, 0.45, -0.75), Vector3(-0.7, 1.1, -0.745), lit(Color(1.0, 0.9, 0.7), 0.4))
			for j in 4:
				bb(k, Vector3(-0.91, 0.5 + j * 0.15, -0.744), Vector3(-0.71, 0.52 + j * 0.15, -0.74), [good, bad, ac, Color(0.5, 0.7, 1.0)][j])
		2:
			# banners on the facade, a painted track on the apron, a rooftop rail
			skin(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, 2.2, -0.6), t, "lrb", 0.4)
			for sx in [-0.6, 0.6]:
				bb(k, Vector3(sx - 0.12, 1.2, -0.56), Vector3(sx + 0.12, 2.0, -0.545), ac if sx < 0 else Color(0.3, 0.66, 0.68))
				_thumb(k, at(sx, 1.6, -0.54), sx < 0)
			for i in 2:
				bb(k, Vector3(-1.25, 0.03, 0.75 + i * 0.9), Vector3(1.25, 0.034, 0.79 + i * 0.9), Color(0.96, 0.96, 0.96))
			for x in [-1.25, 1.25]:
				bb(k, Vector3(x - 0.02, 0.03, 0.75), Vector3(x + 0.02, 0.034, 1.69), Color(0.96, 0.96, 0.96))
		3:
			# a crowd on the bleachers, flags on the masts, a giant thumb
			for s in 4:
				var y := 0.15 + (s + 1) * 0.29
				for i in 12:
					var fx := -0.9 + i * 0.16
					if (i + s * 3) % 4 != 0:
						bb(k, Vector3(fx - 0.035, y, -1.5 - s * 0.09 - 0.06), Vector3(fx + 0.035, y + 0.12, -1.5 - s * 0.09 + 0.0), [Color(0.3, 0.5, 0.8), Color(0.85, 0.35, 0.3), Color(0.95, 0.8, 0.3), Color(0.4, 0.7, 0.45), Color(0.9, 0.9, 0.9)][(i * 3 + s) % 5])
			for q in [Vector2(-0.92, -1.8), Vector2(0.92, -1.8)]:
				bx(k, Vector3(0.02, 0.22, 0.3), ac if q.x < 0 else good, Vector3(q.x, 3.3, q.y + 0.15))
			_thumb(k, at(0, 3.0, -1.76), true, 2.5)
		_:
			# glowing stars on the top tier's corners, brass thumbs, light lines
			var yy := 0.0
			for tr in [[0.98, 0.65, 1.0], [0.82, 0.55, 0.9], [0.66, 0.45, 0.85], [0.48, 0.36, 0.8]]:
				skin(k, Vector3(-float(tr[0]), yy, -1.2 - float(tr[1])), Vector3(float(tr[0]), yy + float(tr[2]), -1.2 + float(tr[1])), t, "flrb", 0.25)
				yy += float(tr[2])
			for q in [Vector2(-0.45, -1.52), Vector2(0.45, -1.52), Vector2(-0.45, -0.88), Vector2(0.45, -0.88)]:
				k.star(0.08, 0.035, 5, 0.03, lit(ac, 0.35), xf(Vector3(q.x, 3.62, q.y), Vector3(0, 0, 0)))
			for tr in [[0.98, 0.65, 0.0], [0.82, 0.55, 1.0], [0.66, 0.45, 1.9]]:
				var hw: float = tr[0]
				var hd: float = tr[1]
				var y: float = tr[2]
				for sx in [-1.0, 1.0]:
					bb(k, Vector3(sx * hw - 0.015, y + 0.12, -1.2 + hd - 0.02), Vector3(sx * hw + 0.015, y + 0.7, -1.2 + hd + 0.02), lit(p["glow"], 0.4))



## Second pass of synth lab detail.
static func _synth_lab_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent("synth_lab")
	match t:
		0:
			# a camp stove, a cooler, a poster, a hose, a skull sign
			bb(k, Vector3(0.45, 0, -0.75), Vector3(0.85, 0.32, -0.5), Color(0.3, 0.5, 0.8))
			bb(k, Vector3(0.45, 0.32, -0.75), Vector3(0.85, 0.36, -0.5), Color(0.92, 0.92, 0.9))
			bb(k, Vector3(-0.9, 1.0, BK + 0.05), Vector3(-0.45, 1.4, BK + 0.07), Color(0.94, 0.92, 0.86))
			for i in 6:
				for j in 3:
					bb(k, Vector3(-0.88 + i * 0.07, 1.05 + j * 0.11, BK + 0.07), Vector3(-0.83 + i * 0.07, 1.13 + j * 0.11, BK + 0.075), [ac, Color(0.4, 0.8, 0.5), Color(1.0, 0.6, 0.3), Color(0.5, 0.7, 1.0)][(i + j) % 4])
			cord(k, [Vector2(0.65, -0.5), Vector2(0.4, -0.4), Vector2(0.1, -0.5), Vector2(-0.2, -0.75)], Color(0.3, 0.6, 0.3))
			bx(k, Vector3(0.2, 0.2, 0.02), Color(0.98, 0.84, 0.3), Vector3(0.0, 1.62, -0.8), Vector3(0, 0, 45))
		1:
			# a safety shower, an exhaust fan on the duct, a lab coat
			cy(k, 0.03, 2.1, Color(0.3, 0.7, 0.4), Vector3(0.05, 0, -0.95), 6)
			seg(k, Vector3(0.05, 2.1, -0.95), Vector3(0.05, 2.1, -0.75), 0.04, Color(0.3, 0.7, 0.4))
			k.cyl(0.12, 0.06, Color(0.3, 0.7, 0.4), at(0.05, 2.04, -0.75), 8, 0.0, 0.05)
			seg(k, Vector3(0.1, 2.0, -0.95), Vector3(0.1, 1.6, -0.95), 0.008, Color(0.3, 0.7, 0.4))
			bx(k, Vector3(0.18, 0.18, 0.02), Color(0.3, 0.7, 0.4), Vector3(0.05, 1.3, -0.97))
			k.cyl(0.18, 0.08, Color(0.6, 0.62, 0.66), at(-0.45, 2.8, -1.55), 8)
			for i in 4:
				bx(k, Vector3(0.3, 0.01, 0.05), Color(0.3, 0.32, 0.36), Vector3(-0.45, 2.89, -1.55), Vector3(0, i * 45.0, 0))
			bx(k, Vector3(0.2, 0.45, 0.04), Color(0.96, 0.96, 0.96), Vector3(-0.15, 1.1, -1.18), Vector3(0, 0, 4))
		2:
			# a molecule logo, white pipe runs, a glass canopy, rooftop rail
			skin(k, Vector3(-0.98, 0, -1.86), Vector3(0.98, 1.4, -0.55), t, "lrb", 0.4)
			var mc := Vector3(0.62, 1.05, -0.53)
			for q in [Vector3(0, 0, 0), Vector3(0.12, 0.1, 0), Vector3(-0.12, 0.08, 0), Vector3(0.02, -0.13, 0)]:
				k.sphere(0.04 if q != Vector3.ZERO else 0.055, lit(ac, 0.4) if q == Vector3.ZERO else Color(0.95, 0.95, 0.96), at(mc.x + q.x, mc.y + q.y, mc.z), 8, 5)
				if q != Vector3.ZERO:
					seg(k, mc, mc + q, 0.015, Color(0.7, 0.72, 0.75))
			for i in 3:
				run(k, [Vector3(-0.95, 0.2 + i * 0.08, -0.53), Vector3(-0.55, 0.2 + i * 0.08, -0.53)], 0.02, [ac.lightened(0.3), Color(0.9, 0.9, 0.9), Color(0.5, 0.8, 0.9)][i])
			ArchKit.railing(k, Vector3(-0.95, 1.5, -0.57), Vector3(0.95, 1.5, -0.57), 0.4, Color(0.85, 0.86, 0.88), 0.4)
			for i in 6:
				var a := TAU * i / 6.0
				bb(k, Vector3(cos(a) * 0.68 - 0.02, 1.5, -1.2 + sin(a) * 0.68 - 0.02), Vector3(cos(a) * 0.68 + 0.02, 1.95, -1.2 + sin(a) * 0.68 + 0.02), Color(0.88, 0.9, 0.92))
		3:
			# nozzles on the vessel, valves, a control cabinet
			for q in [Vector3(-0.35, 2.25, -0.8), Vector3(0.35, 2.25, -0.8), Vector3(-0.35, 1.25, -0.8), Vector3(0.35, 1.25, -0.8)]:
				var d: Vector3 = (q - Vector3(0, 1.75, -1.2)).normalized()
				tube(k, Vector3(0, 1.75, -1.2) + d * 0.55, Vector3(0, 1.75, -1.2) + d * 0.72, 0.04, p["metal"])
				cy(k, 0.06, 0.03, p["trim"], Vector3(0, 1.75, -1.2) + d * 0.72, 8)
			for x in [-0.6, 0.6]:
				bb(k, Vector3(x - 0.15, 0, -1.84), Vector3(x + 0.15, 0.9, -1.6), p["wall"])
				if x < 0:
					bb(k, Vector3(x - 0.1, 0.5, -1.6), Vector3(x + 0.1, 0.8, -1.595), lit(ac, 0.4))
				else:
					screen(k, at(x, 0.65, -1.6), 0.2, 0.2, p["glow"], 3)
		_:
			# glowing slots in the plinth, brass rings on the arms, motes
			for i in 8:
				var a := TAU * (i + 0.5) / 8.0
				bx(k, Vector3(0.03, 0.5, 0.03), lit(ac, 0.4), Vector3(cos(a) * 0.81, 0.6, -1.0 + sin(a) * 0.81))
			for i in 10:
				var a := TAU * i / 10.0
				var r := 1.0 + (i % 3) * 0.08
				k.sphere(0.03, lit(Color(1, 0.9, 1), 0.3), at(cos(a) * r * 0.85, 3.0 + sin(i * 1.7) * 0.6, -0.85 + sin(a) * r * 0.7), 5, 3)
			cy(k, 0.88, 0.02, lit(ac, 0.45), Vector3(0, 0.03, -1.0), 8)



## Era cladding over a box volume (min a, max b): panel seams on the listed
## faces, corner strips, and (hyperscale) glowing reveals and brass bands.
static func skin(k: MeshKit, a: Vector3, b: Vector3, t: int, faces := "flrb", step := 0.32) -> void:
	var p := ArchKit.pal(t)
	var w := b.x - a.x
	var d := b.z - a.z
	var h := b.y - a.y
	var seam: Color = (p["wall"] as Color).darkened(0.16) if t < 4 else (p["wall2"] as Color).lightened(0.1)
	for f in faces:
		var face := Transform3D.IDENTITY
		var fw := w
		match f:
			"f":
				face = at((a.x + b.x) * 0.5, a.y, b.z)
			"b":
				face = xf(Vector3((a.x + b.x) * 0.5, a.y, a.z), Vector3(0, 180, 0))
			"l":
				face = xf(Vector3(a.x, a.y, (a.z + b.z) * 0.5), Vector3(0, -90, 0))
				fw = d
			"r":
				face = xf(Vector3(b.x, a.y, (a.z + b.z) * 0.5), Vector3(0, 90, 0))
				fw = d
		seams(k, face, fw - 0.04, h, maxi(1, int(fw / step)), maxi(1, int(h / (step * 1.5))), seam)
		if t >= 4:
			for j in range(1, int(h / 1.1) + 1):
				k.box(Vector3(fw - 0.08, 0.018, 0.012), lit(p["accent2"], 0.45), face * at(0, j * 1.1 - 0.12, 0.009))
			k.box(Vector3(fw, 0.05, 0.016), p["trim"], face * at(0, 0.06, 0.008))
		elif t == 3:
			k.box(Vector3(fw, 0.06, 0.02), p["trim"], face * at(0, 0.03, 0.01))
	var cc: Color = p["trim"] if t != 2 else Color(0.84, 0.86, 0.88)
	for q in [Vector2(a.x, a.z), Vector2(b.x, a.z), Vector2(a.x, b.z), Vector2(b.x, b.z)]:
		bb(k, Vector3(q.x - 0.02, a.y, q.y - 0.02), Vector3(q.x + 0.02, b.y, q.y + 0.02), cc)


## Era cladding round a cylinder: vertical seams and rings.
static func skin_cyl(k: MeshKit, c: Vector3, r: float, h: float, t: int, n := 12, ring_gap := 0.8) -> void:
	var p := ArchKit.pal(t)
	var seam: Color = (p["wall"] as Color).darkened(0.16) if t < 4 else (p["wall2"] as Color).lightened(0.1)
	for i in n:
		var a := TAU * i / n
		bx(k, Vector3(0.016, h, 0.016), seam, c + Vector3(cos(a) * (r + 0.005), h * 0.5, sin(a) * (r + 0.005)))
	for j in range(1, int(h / ring_gap) + 1):
		cy(k, r + 0.012, 0.02, lit(p["accent2"], 0.45) if t >= 4 else seam, c + Vector3(0, j * ring_gap - 0.1, 0), maxi(8, n))



## A grid of small glowing LED dots on a face frame (cols x rows).
static func leds(k: MeshKit, face: Transform3D, w: float, h: float, cols: int, rows: int, col: Color, seed := 0) -> void:
	for i in cols:
		for j in rows:
			if (i * 7 + j * 13 + seed) % 5 == 0:
				continue
			var c := col if (i + j + seed) % 4 else col.lerp(Color.WHITE, 0.5)
			k.box(Vector3(w / cols * 0.55, h / rows * 0.4, 0.01), lit(c, 0.4), face * at(-w * 0.5 + (i + 0.5) * w / cols, (j + 0.5) * h / rows, 0.006))


## Third pass for the industrial and hyperscale eras: dense kit that makes
## the late tiers the busiest (fins, ribs, rails, pipe bundles, LEDs).
static func _deluxe(k: MeshKit, kind: String, t: int) -> void:
	if t < 3:
		return
	var p := ArchKit.pal(t)
	var ac := _accent(kind)
	var gl: Color = p["glow"]
	var a2: Color = p["accent2"]
	match kind:
		"fab":
			if t == 3:
				# a pipe rack along the bay's foot, louvred penthouse, rails
				for i in 4:
					run(k, [Vector3(-0.94, 0.25 + i * 0.07, -0.56), Vector3(-0.4, 0.25 + i * 0.07, -0.56)], 0.022, [Color(0.86, 0.6, 0.3), Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84), Color(0.5, 0.78, 0.5)][i])
				for sx in [-0.85, -0.6]:
					bb(k, Vector3(sx - 0.02, 0, -0.6), Vector3(sx + 0.02, 0.55, -0.52), p["trim"])
				ArchKit.railing(k, Vector3(-0.92, 3.98, -0.66), Vector3(0.92, 3.98, -0.66), 0.5, p["accent"], 0.3)
				ArchKit.railing(k, Vector3(-0.92, 3.98, -1.82), Vector3(-0.92, 3.98, -0.66), 0.5, p["accent"], 0.3)
				leds(k, at(-0.6, 0.6, -0.565), 0.3, 0.3, 4, 3, Color(0.4, 1.0, 0.5))
				for i in 8:
					bx(k, Vector3(0.03, 0.03, 0.01), lit(a2, 0.4), Vector3(-0.9 + i * 0.25, 3.72, -0.6))
			else:
				# cantilever roof kit, brass vacuum lines, LED panels, ground lights
				for i in 5:
					bb(k, Vector3(-0.95, 4.64, -1.86 + i * 0.37 - 0.01), Vector3(-0.8, 4.65, -1.86 + i * 0.37 + 0.01), p["trim"])
					bb(k, Vector3(0.8, 4.64, -1.86 + i * 0.37 - 0.01), Vector3(0.95, 4.65, -1.86 + i * 0.37 + 0.01), p["trim"])
				bb(k, Vector3(-0.95, 4.64, -0.4), Vector3(0.95, 4.66, -0.36), lit(gl, 0.4))
				for i in 6:
					bx(k, Vector3(0.12, 0.08, 0.08), p["dark"], Vector3(-0.6 + i * 0.24, 4.68, -0.5))
					bx(k, Vector3(0.08, 0.012, 0.04), lit(a2, 0.4), Vector3(-0.6 + i * 0.24, 4.725, -0.5))
				for sx in [-0.18, 0.18]:
					run(k, [Vector3(sx, 1.15, -0.42), Vector3(sx, 1.6, -0.42), Vector3(sx * 2.0, 1.9, -0.58)], 0.035, p["trim"])
				for sx in [-1.0, 1.0]:
					leds(k, xf(Vector3(sx * 0.8, 1.0, -1.2), Vector3(0, 90 * sx, 0)) * at(0, 2.4, 0.02), 1.0, 0.8, 8, 5, ac, int(sx + 2))
				for i in 6:
					var gz := 0.85 + (i % 3) * 0.4
					bb(k, Vector3((-1.15 if i < 3 else 1.15) - 0.04, 0.03, gz - 0.04), Vector3((-1.15 if i < 3 else 1.15) + 0.04, 0.045, gz + 0.04), lit(gl, 0.4))
		"refinery":
			if t == 3:
				# platform grating round the tower feet, pumps, a pipe manifold
				deck(k, Vector3(-0.9, 0, -1.86), Vector3(0.9, 0.9, -1.72), p["metal"], p["accent"], "f")
				for i in 3:
					var px := -0.7 + i * 0.5
					bb(k, Vector3(px - 0.1, 0, -1.68), Vector3(px + 0.1, 0.18, -1.52), p["dark"])
					hcy(k, 0.07, 0.22, Color(0.3, 0.5, 0.8), Vector3(px, 0.28, -1.6), true, 8)
					cy(k, 0.05, 0.12, Color(0.86, 0.86, 0.84), Vector3(px + 0.08, 0.18, -1.6), 6)
				for i in 3:
					run(k, [Vector3(-0.9, 0.55 + i * 0.08, -1.5), Vector3(0.9, 0.55 + i * 0.08, -1.5)], 0.025, [Color(0.86, 0.6, 0.3), Color(0.86, 0.86, 0.84), Color(0.36, 0.6, 0.86)][i])
				leds(k, at(-0.58, 0.15, -0.495), 0.6, 0.3, 6, 2, ac)
			else:
				# fin crowns on each pier, brass rings, a glowing funnel lip
				for i in 6:
					var a := TAU * i / 6.0 + 0.5
					var q := Vector3(cos(a) * 0.64, 0, -1.15 + sin(a) * 0.62)
					bx(k, Vector3(0.05, 0.5, 0.22), p["trim"], q + Vector3(0, 6.35, 0), Vector3(0, -rad_to_deg(a), 0))
					bx(k, Vector3(0.012, 0.42, 0.012), lit(gl, 0.4), q + Vector3(cos(a) * 0.1, 6.35, sin(a) * 0.1))
					for y in [0.9, 2.3, 3.9, 5.5]:
						bx(k, Vector3(0.16, 0.16, 0.012), lit(ac, 0.45), q + Vector3(cos(a) * 0.08, y, sin(a) * 0.08), Vector3(0, -rad_to_deg(a) + 90, 0))
				k.torus(0.71, 0.03, lit(gl, 0.4), at(0, 7.2, -1.15), 18, 4)
				for sx in [-1.0, 1.0]:
					leds(k, at(sx * 0.62, 0.1, -0.46), 0.3, 0.6, 3, 6, ac, int(sx + 3))
		"tune_lab":
			if t == 3:
				# rooftop lights on the trusses, a cable tray maze, louvre bands
				for i in 3:
					for j in 4:
						bx(k, Vector3(0.08, 0.04, 0.08), lit(Color(1, 1, 0.9), 0.35), Vector3(-0.75 + j * 0.5, 3.75, -1.7 + i * 0.5))
				ArchKit.cable_tray(k, Vector3(-0.9, 3.8, -0.75), Vector3(0.9, 3.8, -0.75), t)
				ArchKit.louvres(k, at(0, 2.85, -0.6), 1.8, 0.5, p["metal"], 5)
				leds(k, at(-0.75, 0.25, -0.59), 0.25, 1.0, 2, 8, ac)
				leds(k, at(0.75, 0.25, -0.59), 0.25, 1.0, 2, 8, Color(0.5, 0.86, 1.0))
			else:
				# brass lattice round the dome base, LED crowns on the drum
				for i in 16:
					var a := TAU * i / 16.0
					seg(k, Vector3(cos(a) * 0.85, 3.2, -1.02 + sin(a) * 0.85), Vector3(cos(a + 0.4) * 0.74, 3.55, -1.02 + sin(a + 0.4) * 0.74), 0.02, p["trim"])
				for i in 24:
					var a := TAU * i / 24.0
					if sin(a) > -0.3:
						bx(k, Vector3(0.05, 0.05, 0.02), lit(ac if i % 3 else Color(1, 0.9, 0.7), 0.4), Vector3(cos(a) * 0.81, 2.6, -1.02 + sin(a) * 0.81), Vector3(0, -rad_to_deg(a) + 90, 0))
						bx(k, Vector3(0.05, 0.05, 0.02), lit(gl, 0.4), Vector3(cos(a) * 0.81, 0.9, -1.02 + sin(a) * 0.81), Vector3(0, -rad_to_deg(a) + 90, 0))
				for sx in [-0.32, 0.32]:
					cy(k, 0.04, 1.1, p["trim"], Vector3(sx * 1.25, 0, 0.0), 6)
					k.sphere(0.05, lit(ac, 0.35), at(sx * 1.25, 1.15, 0.0), 6, 4)
		"hbm_works":
			if t == 3:
				# hydraulic lines down the press posts, a crane rail, die racks
				for q in [Vector2(-0.48, -1.45), Vector2(0.48, -1.45), Vector2(-0.48, -0.85), Vector2(0.48, -0.85)]:
					run(k, [Vector3(q.x + 0.1, 3.3, q.y), Vector3(q.x + 0.1, 0.6, q.y)], 0.018, Color(0.15, 0.15, 0.16))
				for sz in [-1.84, -0.56]:
					bb(k, Vector3(-0.95, 3.45, sz - 0.04), Vector3(0.95, 3.55, sz + 0.04), p["accent"])
				leds(k, at(-0.55, 3.35, -0.695), 0.3, 0.12, 6, 1, gl)
				for i in 4:
					bb(k, Vector3(-0.92, 0.05 + i * 0.25, -1.82), Vector3(-0.66, 0.08 + i * 0.25, -1.62), p["accent2"])
					for m in 2:
						bb(k, Vector3(-0.9 + m * 0.12, 0.08 + i * 0.25, -1.8), Vector3(-0.8 + m * 0.12, 0.2 + i * 0.25, -1.64), Color(0.56, 0.58, 0.62))
			else:
				# glowing pins between the slabs, brass bolts, LED panels
				var top := 0.25 + 9 * 0.57
				for i in 9:
					var y := 0.25 + i * 0.57 + 0.5
					for j in 8:
						bx(k, Vector3(0.03, 0.07, 0.03), lit(ac.lightened(0.3), 0.35), Vector3(-0.7 + j * 0.2, y + 0.035, -0.6))
				for i in 4:
					for sx in [-0.7, 0.7]:
						cy(k, 0.03, 0.08, p["trim"], Vector3(sx, top + 1.82, -1.6 + i * 0.25), 6)
				leds(k, at(0, top + 1.52, -0.67), 1.2, 0.2, 12, 2, ac)
		"rlhf_gym":
			if t == 3:
				# flags and floodlight braces, a crowd barrier, a turf pattern
				for i in 4:
					bb(k, Vector3(-0.55 + i * 0.3, 0.17, -1.5), Vector3(-0.42 + i * 0.3, 0.172, -0.75), Color(0.36, 0.58, 0.5))
				ArchKit.railing(k, Vector3(-0.58, 0.17, -0.75), Vector3(0.58, 0.17, -0.75), 0.35, p["accent"], 0.29)
				for q in [Vector2(-0.92, -1.8), Vector2(0.92, -1.8), Vector2(-0.92, -0.55), Vector2(0.92, -0.55)]:
					seg(k, Vector3(q.x, 2.5, q.y), Vector3(q.x * 0.8, 3.5, q.y), 0.025, p["trim"])
				leds(k, at(0, 2.05, -1.765), 1.3, 0.1, 13, 1, Color(1, 0.9, 0.6))
			else:
				# glowing tread lines up the ziggurat, brass rails, LED tiers
				var yy := 0.0
				for tr in [[0.98, 0.65, 1.0], [0.82, 0.55, 0.9], [0.66, 0.45, 0.85], [0.48, 0.36, 0.8]]:
					var hw: float = tr[0]
					var hd: float = tr[1]
					var h: float = tr[2]
					leds(k, at(0, yy + h * 0.55, -1.2 + hd + 0.01), hw * 1.6, h * 0.35, int(hw * 12.0), 2, ac, int(yy * 10))
					ArchKit.railing(k, Vector3(-hw + 0.04, yy + h, -1.2 + hd - 0.04), Vector3(hw - 0.04, yy + h, -1.2 + hd - 0.04), 0.25, p["trim"], 0.3)
					yy += h
		"synth_lab":
			if t == 3:
				# instrument racks round the vessel, cable trays, sample lines
				for i in 3:
					rack(k, Vector3(-0.75 + i * 0.25, 0, -0.75), 1.0, t)
				ArchKit.cable_tray(k, Vector3(-0.92, 3.4, -0.62), Vector3(0.92, 3.4, -0.62), t)
				for i in 4:
					run(k, [Vector3(0.0, 1.75, -1.2) + Vector3(cos(i * 1.4) * 0.58, 0.3, sin(i * 1.4) * 0.58), Vector3(cos(i * 1.4) * 0.85, 3.6, -1.2 + sin(i * 1.4) * 0.5)], 0.02, [ac.lightened(0.2), Color(0.86, 0.86, 0.84)][i % 2])
				leds(k, at(0, 0.2, -0.235), 0.4, 0.2, 6, 2, ac)
			else:
				# a brass halo ring round the plinth, LED bands, a glow column
				k.torus(0.86, 0.03, p["trim"], at(0, 1.1, -1.0), 18, 4)
				for i in 16:
					var a := TAU * i / 16.0
					bx(k, Vector3(0.025, 0.12, 0.025), p["trim"], Vector3(cos(a) * 0.86, 1.18, -1.0 + sin(a) * 0.86))
				for i in 12:
					var a := TAU * i / 12.0
					bx(k, Vector3(0.12, 0.04, 0.02), lit(ac, 0.4), Vector3(cos(a) * 0.81, 0.4, -1.0 + sin(a) * 0.81), Vector3(0, -rad_to_deg(a) + 90, 0))
				cy(k, 0.05, 1.4, lit(ac, 0.35), Vector3(0, 1.06, -1.0), 8)



## A small quadcopter drone (on a pad).
static func drone(k: MeshKit, p: Vector3, col: Color, glow: Color) -> void:
	k.box(Vector3(0.16, 0.05, 0.16), col, at(p.x, p.y + 0.05, p.z))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			seg(k, p + Vector3(0, 0.06, 0), p + Vector3(sx * 0.14, 0.07, sz * 0.14), 0.02, col)
			cy(k, 0.06, 0.01, Color(0.6, 0.62, 0.66), p + Vector3(sx * 0.14, 0.085, sz * 0.14), 8)
	k.box(Vector3(0.06, 0.02, 0.02), lit(glow, 0.4), at(p.x, p.y + 0.05, p.z + 0.085))


## Second pass of depot detail.
static func _depot_more(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := Color(0.96, 0.7, 0.3)
	match t:
		0:
			# a sign on a stake, a lantern, a tarp roll, a broom, sacks
			seg(k, Vector3(-1.2, 0, 0.42), Vector3(-1.2, 1.0, 0.42), 0.04, Color(0.5, 0.36, 0.24))
			k.box(Vector3(0.44, 0.22, 0.03), Color(0.94, 0.92, 0.86), xf(Vector3(-1.2, 0.95, 0.44), Vector3(0, 0, -4)))
			k.box(Vector3(0.3, 0.07, 0.01), ac, xf(Vector3(-1.2, 0.96, 0.46), Vector3(0, 0, -4)))
			cy(k, 0.05, 0.12, Color(0.3, 0.3, 0.32), Vector3(0.6, 0.565, 0.25), 6)
			cy(k, 0.04, 0.08, lit(Color(1.0, 0.8, 0.45), 0.3), Vector3(0.6, 0.6, 0.25), 6)
			hcy(k, 0.09, 0.8, Color(0.26, 0.46, 0.78), Vector3(0.0, 0.66, -0.7), true, 8)
			for i in 4:
				if i < 2:
					bx(k, Vector3(0.34, 0.15, 0.24), Color(0.88, 0.86, 0.78), Vector3(-0.9 + i * 0.06, 0.64 + (i % 2) * 0.13, -0.55 + i * 0.03), Vector3(0, i * 23.0, 0))
		1:
			# a dock leveller, wheel chocks, a DOCK sign, a hose reel, pallets
			bb(k, Vector3(-0.5, 0.56, 0.2), Vector3(0.5, 0.575, 0.44), Color(0.5, 0.52, 0.56))
			for i in 6:
				bb(k, Vector3(-0.45 + i * 0.18, 0.575, 0.22), Vector3(-0.4 + i * 0.18, 0.58, 0.42), Color(0.42, 0.44, 0.48))
			bb(k, Vector3(-0.5, 2.48, -0.79), Vector3(0.5, 2.62, -0.775), Color(0.96, 0.96, 0.94))
			bb(k, Vector3(-0.42, 2.5, -0.775), Vector3(0.1, 2.6, -0.77), Color(0.2, 0.2, 0.22))
			bb(k, Vector3(0.18, 2.51, -0.775), Vector3(0.42, 2.59, -0.77), p["accent"])
			k.cyl(0.14, 0.08, Color(0.85, 0.2, 0.18), xf(Vector3(-0.6, 1.4, -0.84), Vector3(90, 0, 0)), 10)
		2:
			# a skinned shed, solar on the roof, a bike rack, wall lamps
			skin(k, Vector3(-1.85, 0, -1.88), Vector3(1.85, 2.5, -0.86), t, "lrb", 0.45)
			for i in 3:
				k.box(Vector3(0.36, 0.03, 0.22), Color(0.16, 0.24, 0.44), xf(Vector3(-0.42 + i * 0.42, 2.68, -1.4), Vector3(-20, 0, 0)))
				bb(k, Vector3(-0.44 + i * 0.42, 2.53, -1.42), Vector3(-0.4 + i * 0.42, 2.66, -1.38), Color(0.7, 0.72, 0.75))
			for x in [-1.3, -0.15, 0.15, 1.3]:
				bx(k, Vector3(0.1, 0.06, 0.1), lit(p["glow"], 0.35), Vector3(x, 2.0, -0.8))
		3:
			# skinned high-bay, a caged ladder, skylights, rooftop fans
			skin(k, Vector3(-1.86, 0, -1.88), Vector3(1.86, 4.4, -0.86), t, "lrb")
			ArchKit.ladder(k, at(-1.5, 0, -0.86), 4.6, p["accent"], true)
			for i in 4:
				if i != 1 and i != 2:
					bb(k, Vector3(-1.6 + i * 0.95, 4.58, -1.8), Vector3(-1.25 + i * 0.95, 4.66, -1.62), p["glass"])
			for x in [-0.45, 0.45]:
				cy(k, 0.12, 0.2, p["metal"], Vector3(x, 4.58, -0.98), 8)
				cy(k, 0.1, 0.02, Color(0.22, 0.23, 0.26), Vector3(x, 4.78, -0.98), 8)
			bb(k, Vector3(-0.8, 3.95, -0.84), Vector3(0.8, 4.25, -0.8), p["dark"])
			bb(k, Vector3(-0.72, 4.02, -0.8), Vector3(0.72, 4.18, -0.795), lit(p["glow"], 0.4))
			leds(k, at(1.55, 1.0, -0.84), 0.3, 1.4, 2, 8, Color(0.4, 1.0, 0.5))
		_:
			# skinned vault, drones on the pad, a brass crown frame, LED sign
			skin(k, Vector3(-1.86, 0, -1.88), Vector3(1.86, 4.2, -0.86), t, "lrb")
			drone(k, Vector3(-0.15, 4.29, -1.42), p["wall2"], p["accent2"])
			drone(k, Vector3(0.2, 4.29, -1.3), p["wall2"], p["accent2"])
			for q in [Vector2(-0.55, -1.8), Vector2(0.55, -1.8), Vector2(-0.55, -0.95), Vector2(0.55, -0.95)]:
				bb(k, Vector3(q.x - 0.03, 4.2, q.y - 0.03), Vector3(q.x + 0.03, 5.0, q.y + 0.03), p["trim"])
			for z in [-1.8, -0.95]:
				bb(k, Vector3(-0.58, 4.98, z - 0.03), Vector3(0.58, 5.04, z + 0.03), p["trim"])
			for x in [-0.55, 0.55]:
				bb(k, Vector3(x - 0.03, 4.98, -1.83), Vector3(x + 0.03, 5.04, -0.92), p["trim"])
			bb(k, Vector3(-0.6, 2.25, -0.86), Vector3(0.6, 2.5, -0.82), p["dark"])
			leds(k, at(0, 2.27, -0.82), 1.1, 0.2, 14, 2, p["accent2"])
			for sx in [-1.0, 1.0]:
				run(k, [Vector3(sx * 1.78, 0.3, -0.76), Vector3(sx * 1.78, 3.9, -0.76)], 0.04, lit(p["accent2"], 0.45))
				for y in [1.0, 2.0, 3.0]:
					cy(k, 0.06, 0.05, p["trim"], Vector3(sx * 1.78, y, -0.76), 8)



## Fourth pass: more workshop clutter, campus roof kit, hyperscale lattices.
static func _extra2(k: MeshKit, kind: String, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent(kind)
	match t:
		1:
			# every workshop: an overhead cable tray with drops, a pallet of
			# stock, a mop sink, a first-aid box, floor arrows, wall lamps
			ArchKit.cable_tray(k, Vector3(-0.95, 2.45, -0.5), Vector3(0.95, 2.45, -0.5), t)
			for sx in [-0.97, 0.97]:
				bb(k, Vector3(sx - 0.02, 0.0, -0.52), Vector3(sx + 0.02, 2.45, -0.48), p["trim"])
			for i in 5:
				seg(k, Vector3(-0.8 + i * 0.4, 2.45, -0.5), Vector3(-0.8 + i * 0.4 + 0.05, 2.25, -0.55), 0.015, [Color(0.2, 0.4, 0.8), Color(0.9, 0.6, 0.2), Color(0.25, 0.25, 0.27)][i % 3])
			for i in 3:
				bx(k, Vector3(0.14, 0.004, 0.035), p["accent"], Vector3(-0.045, 0.034, 0.8 + i * 0.35), Vector3(0, 40, 0))
				bx(k, Vector3(0.14, 0.004, 0.035), p["accent"], Vector3(0.045, 0.034, 0.8 + i * 0.35), Vector3(0, -40, 0))
			for sx in [-0.96, 0.96]:
				bb(k, Vector3(sx - 0.03, 1.2, -0.47), Vector3(sx + 0.03, 1.36, -0.43), Color(0.92, 0.92, 0.9))
				bb(k, Vector3(sx - 0.01, 1.25, -0.43), Vector3(sx + 0.01, 1.31, -0.425), Color(0.2, 0.7, 0.3))
		2:
			# every campus lab: a glass balustrade and solar strip on the hero
			# roof edge, flagpoles, a teal plinth band, a bike rack
			for sx in [-0.9, 0.9]:
				cy(k, 0.015, 2.6, Color(0.9, 0.91, 0.92), Vector3(sx, 0, -0.33), 5)
				k.sphere(0.025, Color(0.9, 0.91, 0.92), at(sx, 2.62, -0.33), 5, 3)
				bx(k, Vector3(0.34, 0.22, 0.015), ac if sx < 0 else p["trim"], Vector3(sx - signf(sx) * 0.18, 2.45, -0.33))
			bb(k, Vector3(-0.99, 0.0, -0.52), Vector3(0.99, 0.08, -0.47), p["trim"])
		4:
			match kind:
				"fab":
					# brass X-bracing up the tower front between the pilasters
					for j in 3:
						var y0 := 0.4 + j * 1.0
						seg(k, Vector3(-0.74, y0, -0.4), Vector3(0.74, y0 + 0.95, -0.4), 0.025, p["trim"])
						seg(k, Vector3(0.74, y0, -0.4), Vector3(-0.74, y0 + 0.95, -0.4), 0.025, p["trim"])
						bb(k, Vector3(-0.8, y0 + 0.95, -0.42), Vector3(0.8, y0 + 0.99, -0.38), p["trim"])
					for i in 2:
						for j in 12:
							bx(k, Vector3(0.04, 0.04, 0.02), lit(ac, 0.4) if (i + j) % 3 else lit(Color(0.8, 0.6, 1.0), 0.4), Vector3(-0.86 + i * 1.72, 0.5 + j * 0.4, -0.55))
				"refinery":
					# a glowing spiral of data treads climbing the column
					for i in 40:
						var a := i * 0.45
						var y := 0.8 + i * 0.14
						bx(k, Vector3(0.06, 0.025, 0.1), lit(ac.lerp(Color.WHITE, 0.3), 0.35), Vector3(cos(a) * 0.53, y, -1.15 + sin(a) * 0.53), Vector3(0, -rad_to_deg(a), 0))
				"tune_lab":
					# a colonnade of brass posts round the drum, glowing capitals
					for i in 12:
						var a := TAU * (i + 0.5) / 12.0
						if sin(a) > -0.6:
							var q := Vector3(cos(a) * 0.95, 0, -1.02 + sin(a) * 0.9)
							bb(k, Vector3(q.x - 0.03, 0, q.z - 0.03), Vector3(q.x + 0.03, 2.9, q.z + 0.03), p["trim"])
							bb(k, Vector3(q.x - 0.05, 2.9, q.z - 0.05), Vector3(q.x + 0.05, 2.96, q.z + 0.05), lit(ac, 0.4))
				"hbm_works":
					# a stair of glowing die edges down each side of the stack
					for i in 9:
						var y := 0.25 + i * 0.57
						for sx in [-1.0, 1.0]:
							bb(k, Vector3(sx * 0.9 - 0.04, y + 0.1, -1.7), Vector3(sx * 0.9 + 0.04, y + 0.4, -0.7), p["wall2"])
							bb(k, Vector3(sx * 0.95 - 0.006, y + 0.12, -1.65), Vector3(sx * 0.95 + 0.006, y + 0.38, -0.75), lit(ac, 0.4))
				"rlhf_gym":
					# a ceremonial stair up the ziggurat front with glowing risers
					for sx in [-0.62, 0.62]:
						for j in 3:
							k.star(0.07, 0.03, 5, 0.03, lit(ac, 0.35), xf(Vector3(sx, 1.0 + j * 0.85, -0.54), Vector3(90, 0, 0)))
				"synth_lab":
					# glowing motes drifting in front of the reactor
					for i in 4:
						var a := deg_to_rad(30.0 + i * 40.0)
						var q := Vector3(cos(a) * 1.0, 3.0 + sin(a * 2.0) * 0.3, -0.85 + sin(a) * 0.75)
						k.sphere(0.06, lit(ac.lerp(Color.WHITE, 0.4), 0.35), at(q.x, q.y, q.z), 6, 4)



## Fifth pass: campus roof kit and hyperscale LED skins, so detail keeps
## growing with the tier.
static func _extra3(k: MeshKit, kind: String, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent(kind)
	match t:
		2:
			match kind:
				"fab":
					for e in [[Vector3(-0.92, 3.6, -0.56), Vector3(0.92, 3.6, -0.56)], [Vector3(-0.92, 3.6, -1.84), Vector3(-0.92, 3.6, -0.56)], [Vector3(0.92, 3.6, -1.84), Vector3(0.92, 3.6, -0.56)]]:
						ArchKit.railing(k, e[0], e[1], 0.35, Color(0.85, 0.87, 0.9), 0.3)
					for sx in [0.45, 0.7]:
						cy(k, 0.06, 0.8, Color(0.84, 0.86, 0.88), Vector3(sx, 3.33, -1.75), 8)
						cy(k, 0.075, 0.05, p["trim"], Vector3(sx, 4.13, -1.75), 8)
				"refinery":
					ArchKit.railing(k, Vector3(-0.95, 2.76, -1.85), Vector3(0.95, 2.76, -1.85), 0.35, Color(0.85, 0.87, 0.9), 0.3)
					ArchKit.solar(k, at(0.0, 2.74, -1.52), 2, t, 18.0, 0.18)
				"tune_lab":
					for i in 3:
						var z0 := -1.85 + i * 0.47
						for j in 5:
							k.box(Vector3(0.3, 0.02, 0.4), Color(0.16, 0.24, 0.44), xf(Vector3(-0.76 + j * 0.38, 3.18, z0 + 0.235), Vector3(-28, 0, 0)))
					ArchKit.railing(k, Vector3(-0.95, 2.95, -1.86), Vector3(-0.95, 2.95, -0.5), 0.35, Color(0.85, 0.86, 0.88), 0.4)
					ArchKit.railing(k, Vector3(0.95, 2.95, -1.86), Vector3(0.95, 2.95, -0.5), 0.35, Color(0.85, 0.86, 0.88), 0.4)
				"hbm_works":
					ArchKit.solar(k, at(0.0, 2.73, -0.95), 2, t, 18.0, 0.2)
					bb(k, Vector3(0.35, 2.73, -1.05), Vector3(0.85, 2.8, -0.75), p["glass"])
					ArchKit.railing(k, Vector3(-0.95, 2.73, -1.85), Vector3(0.95, 2.73, -1.85), 0.35, Color(0.85, 0.86, 0.88), 0.4)
				"rlhf_gym":
					for j in 5:
						var z := -1.8 + j * 0.3
						for i in 9:
							var a0 := PI * i / 9.0
							var a1 := PI * (i + 1) / 9.0
							seg(k, Vector3(-cos(a0) * 1.0, 2.2 + sin(a0) * 0.77, z), Vector3(-cos(a1) * 1.0, 2.2 + sin(a1) * 0.77, z), 0.035, Color(0.97, 0.97, 0.98))
					bb(k, Vector3(-0.05, 2.92, -1.86), Vector3(0.05, 2.99, -0.6), Color(0.97, 0.97, 0.98))
				"synth_lab":
					for sx in [-0.78, 0.78]:
						ArchKit.planter(k, Vector3(sx, 1.5, -0.7), t, 0.26)
		3:
			# industrial labs: a ladder, junction boxes and a pipe stand by each wing
			for sx in [-0.97, 0.97]:
				jbox(k, at(sx * 0.98, 0.9, -0.45), p["metal"], p["glow"])
				for i in 3:
					run(k, [Vector3(sx, 0.05, -0.47 - i * 0.05), Vector3(sx, 2.2, -0.47 - i * 0.05)], 0.018, [Color(0.86, 0.6, 0.3), Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84)][i])
		4:
			# hyperscale labs: LED status matrices on the hero's flanks
			match kind:
				"fab":
					leds(k, at(0, 4.62, -0.355), 1.6, 0.16, 20, 2, ac)
				"refinery":
					for sx in [-1.0, 1.0]:
						leds(k, xf(Vector3(sx * 0.98, 0.5, -1.2), Vector3(0, -90 * sx, 0)), 0.9, 1.4, 6, 9, ac, int(sx + 5))
				"tune_lab":
					for i in 8:
						var a := TAU * (i + 0.5) / 8.0
						if sin(a) > 0.0:
							leds(k, xf(Vector3(cos(a) * 0.745, 1.25, -1.02 + sin(a) * 0.745), Vector3(0, 90 - rad_to_deg(a), 0)), 0.42, 0.8, 4, 6, ac, i)
				"hbm_works":
					for sx in [-1.0, 1.0]:
						leds(k, xf(Vector3(sx * 0.9, 0.4, -1.2), Vector3(0, 90 * sx, 0)), 0.9, 4.6, 6, 24, ac, int(sx + 7))
				"rlhf_gym":
					for sx in [-1.0, 1.0]:
						leds(k, xf(Vector3(sx * 0.98, 0.15, -1.2), Vector3(0, 90 * sx, 0)), 1.1, 0.7, 8, 4, ac, int(sx + 9))
				"synth_lab":
					for i in 8:
						var a := TAU * (i + 0.5) / 8.0
						if sin(a) > -0.2:
							leds(k, xf(Vector3(cos(a) * 0.745, 0.3, -1.0 + sin(a) * 0.745), Vector3(0, 90 - rad_to_deg(a), 0)), 0.42, 0.6, 4, 4, ac, i)



## An automated guided vehicle (low cart with lights) at p.
static func agv(k: MeshKit, p: Vector3, yaw: float, col: Color, glow: Color) -> void:
	var b := xf(p, Vector3(0, yaw, 0))
	k.box(Vector3(0.36, 0.1, 0.5), col, b * at(0, 0.07, 0))
	k.box(Vector3(0.3, 0.02, 0.44), Color(0.2, 0.2, 0.22), b * at(0, 0.13, 0))
	k.box(Vector3(0.2, 0.02, 0.02), lit(glow, 0.4), b * at(0, 0.08, 0.255))
	for sx in [-0.16, 0.16]:
		k.box(Vector3(0.03, 0.03, 0.03), lit(Color(1, 0.4, 0.3), 0.4), b * at(sx, 0.09, -0.255))
	k.box(Vector3(0.3, 0.16, 0.24), Color(0.76, 0.62, 0.42), b * at(0, 0.22, 0))


## Third pass of depot detail: the later eras get the most.
static func _depot_more2(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	match t:
		1:
			# canopy bracing and gutters, dock steps, a forklift charger
			for x in [-1.8, -0.6, 0.6, 1.8]:
				seg(k, Vector3(x, 2.2, -0.9), Vector3(x + (0.35 if x < 1.0 else -0.35), 2.6, -0.9), 0.04, p["trim"])
			bb(k, Vector3(-1.86, 2.5, -0.8), Vector3(1.86, 2.58, -0.74), Color(0.55, 0.57, 0.6))
			for sx in [-1.84, 1.84]:
				bb(k, Vector3(sx - 0.025, 0, -0.79), Vector3(sx + 0.025, 2.5, -0.75), Color(0.55, 0.57, 0.6))
			for i in 3:
				bb(k, Vector3(1.12, 0, 0.12 + i * 0.1), Vector3(1.4, 0.56 - i * 0.18, 0.22 + i * 0.1), Color(0.6, 0.6, 0.58))
				bb(k, Vector3(1.12, 0.54 - i * 0.18, 0.12 + i * 0.1), Vector3(1.4, 0.56 - i * 0.18, 0.15 + i * 0.1), p["accent"])
			bb(k, Vector3(1.3, 0, -0.98), Vector3(1.6, 0.6, -0.86), Color(0.3, 0.32, 0.36))
			bb(k, Vector3(1.35, 0.4, -0.86), Vector3(1.55, 0.5, -0.855), lit(Color(0.4, 1.0, 0.5), 0.4))
			cable(k, Vector3(1.45, 0.3, -0.86), Vector3(1.5, 0.3, -0.6), Color(0.15, 0.15, 0.16), 0.1, 0.02)
		2:
			# side windows, an office door, downpipes, a rooftop unit and
			# skylights, conveyor legs and a motor, dock lights
			for sx in [-1.0, 1.0]:
				var fo := xf(Vector3(sx * 1.81, 0, -1.37), Vector3(0, 90 * sx, 0))
				ArchKit.window_row(k, fo * at(0, 1.6, 0), 0.7, 0.5, t)
				run(k, [Vector3(sx * 1.8, 2.5, -0.82), Vector3(sx * 1.8, 0.05, -0.82)], 0.025, Color(0.85, 0.86, 0.88))
			door(k, at(1.55, 0, -0.86), t, 0.36, 1.2)
			ArchKit.ac_unit(k, at(-0.35, 2.53, -1.6), t, 0.5)
			for i in 2:
				bb(k, Vector3(0.0 + i * 0.35, 2.53, -1.15), Vector3(0.25 + i * 0.35, 2.6, -0.95), p["glass"])
			for sx in [-1.0, 0.0, 1.0]:
				bb(k, Vector3(sx - 0.02, 0.5, -0.78), Vector3(sx + 0.02, 0.56, -0.64), Color(0.5, 0.52, 0.56))
			bb(k, Vector3(-1.08, 0.56, -0.82), Vector3(1.08, 0.66, -0.8), p["trim"])
			bb(k, Vector3(-1.08, 0.56, -0.62), Vector3(1.08, 0.66, -0.6), p["trim"])
			bb(k, Vector3(0.75, 0.62, -0.95), Vector3(0.95, 0.8, -0.82), Color(0.3, 0.32, 0.36))
			for x in [-1.05, 1.05]:
				bx(k, Vector3(0.08, 0.05, 0.05), lit(p["glow"], 0.35), Vector3(x, 0.45, 0.45))
			leds(k, at(0.0, 1.85, -0.85), 1.0, 0.12, 10, 1, p["glow"])
		3:
			# AGVs instead of a driver, a second conveyor, more racking glow,
			# a lift beside the slot, rooftop fans and a vent penthouse
			agv(k, Vector3(-1.5, 0, -0.45), 0.0, Color(0.96, 0.6, 0.2), p["glow"])
			agv(k, Vector3(1.55, 0, -0.55), 180.0, Color(0.96, 0.6, 0.2), p["glow"])
			for j in 6:
				bb(k, Vector3(-1.28, 0.72 + j * 0.55, -0.795), Vector3(1.28, 0.735 + j * 0.55, -0.79), lit(p["accent2"], 0.4))
			bb(k, Vector3(-0.6, 0.6, -0.78), Vector3(-0.45, 3.9, -0.72), p["accent"])
			bb(k, Vector3(-0.8, 1.5, -0.76), Vector3(-0.3, 1.66, -0.62), p["accent"])
			bb(k, Vector3(-0.75, 1.66, -0.75), Vector3(-0.35, 1.88, -0.63), Color(0.3, 0.5, 0.8))
			bb(k, Vector3(-1.84, 4.58, -1.8), Vector3(-1.34, 5.0, -1.25), p["wall2"])
			ArchKit.louvres(k, at(-1.59, 4.6, -1.25), 0.42, 0.35, p["metal"], 4)
			for i in 8:
				bx(k, Vector3(0.1, 0.006, 0.04), p["accent"], Vector3(-1.5 + (i % 2) * 3.0, 0.034, -0.8 + (i / 2) * 0.15))
		4:
			# pick robots either side of the dock, brass fins on the facade,
			# shuttle LEDs, a glowing apron lane, a brass parapet
			for sx in [-1.0, 1.0]:
				var rb := MeshKit.new()
				_arm(rb, 0.6, p["trim"], p["wall"], lit(p["accent2"], 0.4))
				cy(k, 0.16, 0.2, p["dark"], Vector3(sx * 1.45, 0, -0.5), 10)
				k.merge(rb, xf(Vector3(sx * 1.45, 0.2, -0.5), Vector3(0, 180 if sx > 0 else 0, 0)))
			fins(k, at(-1.24, 0.3, -0.86), 0.8, 3.6, 5, 0.1, 4, p["accent2"])
			fins(k, at(1.24, 0.3, -0.86), 0.8, 3.6, 5, 0.1, 4, p["accent2"])
			leds(k, at(0, 3.75, -0.82), 2.4, 0.3, 24, 2, p["accent2"])
			for e in [[Vector3(-1.82, 4.22, -1.84), Vector3(1.82, 4.22, -1.84)], [Vector3(-1.82, 4.22, -0.9), Vector3(1.82, 4.22, -0.9)]]:
				ArchKit.railing(k, e[0], e[1], 0.3, p["trim"], 0.4)



## A roll cage (wheeled mesh trolley) with a few cartons.
static func roll_cage(k: MeshKit, p: Vector3, col: Color) -> void:
	bb(k, p + Vector3(-0.18, 0.05, -0.14), p + Vector3(0.18, 0.08, 0.14), col)
	for q in [Vector2(-0.17, -0.13), Vector2(0.17, -0.13), Vector2(-0.17, 0.13), Vector2(0.17, 0.13)]:
		bb(k, p + Vector3(q.x - 0.01, 0.08, q.y - 0.01), p + Vector3(q.x + 0.01, 0.9, q.y + 0.01), col)
		cy(k, 0.025, 0.05, Color(0.15, 0.15, 0.16), p + Vector3(q.x, 0, q.y), 6)
	for y in [0.35, 0.62, 0.9]:
		bb(k, p + Vector3(-0.18, y - 0.01, -0.14), p + Vector3(0.18, y + 0.01, -0.12), col)
		bb(k, p + Vector3(-0.18, y - 0.01, 0.12), p + Vector3(0.18, y + 0.01, 0.14), col)
	for i in 3:
		bb(k, p + Vector3(-0.15, 0.08 + i * 0.18, -0.1), p + Vector3(0.05 + (i % 2) * 0.08, 0.25 + i * 0.18, 0.1), Color(0.76, 0.62, 0.42).darkened(i * 0.06))


## Fourth pass of depot detail for the campus to hyperscale eras.
static func _depot_more3(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	match t:
		2:
			# totes on shelving inside the open door, roll cages, rooftop PV
			for j in 3:
				bb(k, Vector3(-1.15, 0.05 + j * 0.3, -1.0), Vector3(-0.35, 0.07 + j * 0.3, -0.9), Color(0.7, 0.72, 0.75))
				for i in 4:
					bb(k, Vector3(-1.12 + i * 0.2, 0.07 + j * 0.3, -0.99), Vector3(-0.96 + i * 0.2, 0.25 + j * 0.3, -0.91), [Color(0.3, 0.5, 0.8), Color(0.3, 0.66, 0.68), Color(0.86, 0.86, 0.84)][(i + j) % 3])
			roll_cage(k, Vector3(1.32, 0, -0.65), Color(0.6, 0.62, 0.66))
			roll_cage(k, Vector3(-1.32, 0, -0.65), Color(0.6, 0.62, 0.66))
			for e in [[Vector3(-1.82, 2.53, -1.86), Vector3(1.82, 2.53, -1.86)], [Vector3(-1.82, 2.53, -0.9), Vector3(1.82, 2.53, -0.9)]]:
				ArchKit.railing(k, e[0], e[1], 0.35, Color(0.85, 0.86, 0.88), 0.45)
		3:
			# louvre bands, an exit door, CCTV, floor lanes, a rooftop PV row
			for sx in [-1.0, 1.0]:
				ArchKit.louvres(k, at(sx * 1.58, 2.9, -0.86), 0.5, 1.0, p["metal"], 8)
				bx(k, Vector3(0.08, 0.06, 0.14), Color(0.9, 0.91, 0.92), Vector3(sx * 1.35, 3.6, -0.79))
				bx(k, Vector3(0.03, 0.03, 0.01), lit(Color(1, 0.3, 0.25), 0.4), Vector3(sx * 1.35, 3.6, -0.715))
			door(k, at(1.58, 0, -0.86), t, 0.36, 1.2)
			bb(k, Vector3(1.48, 1.32, -0.86), Vector3(1.68, 1.4, -0.84), lit(Color(0.4, 1.0, 0.5), 0.4))
			for sx in [-1.25, 1.25]:
				bb(k, Vector3(sx - 0.02, 0.03, -0.8), Vector3(sx + 0.02, 0.036, 0.4), lit(p["accent2"], 0.45))
		4:
			# glowing shuttle lanes across the dock, parked drones, LED pillars
			for i in 5:
				var z := -0.7 + i * 0.25
				bb(k, Vector3(-1.08, 0.565, z - 0.01), Vector3(1.08, 0.57, z + 0.01), lit(p["accent2"], 0.4))
			for sx in [-1.0, 1.0]:
				leds(k, xf(Vector3(sx * 1.86, 0.3, -1.37), Vector3(0, 90 * sx, 0)), 0.8, 3.4, 4, 14, p["accent2"], int(sx + 2))



## Sixth pass: a little more per lab where a tier fell behind the one below.
static func _extra4(k: MeshKit, kind: String, t: int) -> void:
	var p := ArchKit.pal(t)
	var ac := _accent(kind)
	match [kind, t]:
		["tune_lab", 1]:
			# monitor speakers on stands, a coffee trolley, cables to the booth
			for sx in [-0.42, 0.42]:
				cy(k, 0.012, 0.95, Color(0.2, 0.2, 0.22), Vector3(sx, 0, -0.55), 5)
				for i in 3:
					var a := TAU * i / 3.0
					seg(k, Vector3(sx, 0.2, -0.55), Vector3(sx + cos(a) * 0.12, 0, -0.55 + sin(a) * 0.12), 0.012, Color(0.2, 0.2, 0.22))
				bb(k, Vector3(sx - 0.07, 0.95, -0.62), Vector3(sx + 0.07, 1.17, -0.48), Color(0.16, 0.16, 0.18))
				k.cyl(0.04, 0.01, Color(0.4, 0.4, 0.42), xf(Vector3(sx, 1.02, -0.479), Vector3(90, 0, 0)), 8)
			for i in 3:
				cord(k, [Vector2(-0.3 + i * 0.25, -0.72), Vector2(-0.35 + i * 0.3, -0.76), Vector2(-0.4 + i * 0.35, -0.79)], [Color(0.2, 0.2, 0.22), Color(0.3, 0.5, 0.8), Color(0.9, 0.6, 0.2)][i])
		["synth_lab", 1]:
			# a lab fridge, a chemical cabinet, eye-wash sign, a drum dolly
			bb(k, Vector3(-0.38, 0, -1.18), Vector3(-0.08, 0.8, -0.98), Color(0.94, 0.94, 0.95))
			bb(k, Vector3(-0.36, 0.42, -0.98), Vector3(-0.1, 0.44, -0.975), Color(0.6, 0.62, 0.66))
			bx(k, Vector3(0.1, 0.06, 0.01), Color(0.3, 0.6, 0.9), Vector3(-0.23, 0.65, -0.975))
			bx(k, Vector3(0.16, 0.16, 0.02), Color(0.3, 0.7, 0.4), Vector3(0.05, 1.55, -0.96))
			cy(k, 0.18, 0.03, Color(0.3, 0.32, 0.36), Vector3(0.0, 0.02, -0.75), 8)
		["rlhf_gym", 1]:
			# a water cooler, a leaderboard TV, cables to the booths
			bb(k, Vector3(0.62, 0, -0.95), Vector3(0.85, 0.75, -0.78), Color(0.92, 0.92, 0.9))
			cy(k, 0.09, 0.3, Color(0.6, 0.86, 1.0, 0.7), Vector3(0.735, 0.75, -0.865), 8)
			screen(k, at(0.0, 2.55, -1.0), 0.6, 0.3, ac, 8)
			bb(k, Vector3(-0.02, 2.35, -1.02), Vector3(0.02, 2.4, -0.98), Color(0.2, 0.2, 0.22))
			for i in 3:
				cord(k, [Vector2(-0.65 + i * 0.64, -1.0), Vector2(-0.6 + i * 0.6, -0.85), Vector2(-0.12, -0.72)], Color(0.15, 0.15, 0.16))
		["tune_lab", 4], ["synth_lab", 4], ["rlhf_gym", 4]:
			# brass mullion grids and glowing slots on both wings' fronts
			for sx in [-1.0, 1.0]:
				var cx: float = sx * (WX + WX1) * 0.5
				for i in 4:
					bb(k, Vector3(cx - 0.3 + i * 0.2 - 0.01, 2.0, WF + 0.0), Vector3(cx - 0.3 + i * 0.2 + 0.01, 2.15, WF + 0.03), p["trim"])
				leds(k, at(cx, 0.25, WF + 0.005), 0.6, 0.12, 10, 1, ac, int(sx + 4))
			for i in 16:
				var a := TAU * i / 16.0
				bx(k, Vector3(0.03, 0.03, 0.03), lit(ac.lerp(Color.WHITE, 0.4), 0.35), Vector3(cos(a) * 0.4, 0.045, -0.05 + sin(a) * 0.12 + 0.95))


# ---------------------------------------------------------------- moving parts

## Where the moving part pivots (local).
static func anim_pivot(kind: String, t: int) -> Vector3:
	t = clampi(t, 0, 4)
	match kind:
		"fab": return [Vector3(0.02, 0.5, -0.15), Vector3(0, 0.755, -0.18), Vector3(0.56, 3.57, -0.96), Vector3(0, 0.6, -0.16), Vector3(0, 6.15, -1.2)][t]
		"refinery": return [Vector3(0.55, 0.9, -1.1), Vector3(-0.75, 0.2, -0.55), Vector3(0, 2.85, -1.2), Vector3(0.05, 0.25, -0.55), Vector3(0, 0.8, -1.15)][t]
		"tune_lab": return [Vector3(-0.15, 0.0, -1.1), Vector3(0.0, 0.8, -0.62), Vector3(0.6, 3.95, -0.82), Vector3(0, 5.29, -1.2), Vector3(0, 4.25, -1.02)][t]
		"hbm_works": return [Vector3(-0.13, 1.73, -1.42), Vector3(0, 2.3, -1.1), Vector3(0, 2.4, -0.32), Vector3(0, 3.3, -1.15), Vector3(0, 6.88, -1.21)][t]
		"rlhf_gym": return [Vector3(-0.05, 0.47, -0.3), Vector3(-0.12, 0.65, -0.62), Vector3(0, 0.53, -0.17), Vector3(0, 0.48, -1.1), Vector3(0, 3.71, -1.2)][t]
		"synth_lab": return [Vector3(0, 0.84, -0.2), Vector3(0.55, 0.9, -1.4), Vector3(0, 2.95, -1.2), Vector3(0, 1.75, -1.2), Vector3(0, 3.0, -0.85)][t]
	return Vector3(0, 1, -0.85)


## How far the refinery's rings rise and the press strokes, per tier.
static func stroke(kind: String, t: int) -> float:
	t = clampi(t, 0, 4)
	match kind:
		"refinery": return [0.4, 0.6, 0.4, 0.6, 1.25][t]
		"hbm_works": return [0.08, 0.4, 0.2, 0.4, 0.6][t]
	return 0.0


## A two-link robot arm with a gripper (scale s).
static func _arm(k: MeshKit, s: float, col: Color, joint: Color, tip: Color) -> void:
	k.cyl(0.12 * s, 0.2 * s, joint, at(0, 0, 0), 10)
	k.cyl(0.1 * s, 0.06 * s, col, at(0, 0.2 * s, 0), 10)
	k.box(Vector3(0.14, 0.7, 0.14) * s, col, xf(Vector3(0.15, 0.45, 0) * s, Vector3(0, 0, -25)))
	k.sphere(0.1 * s, joint, at(0.3 * s, 0.76 * s, 0), 8, 5)
	k.box(Vector3(0.6, 0.12, 0.12) * s, col, at(0.6 * s, 0.76 * s, 0))
	k.box(Vector3(0.1, 0.02, 0.13) * s, joint, at(0.5 * s, 0.83 * s, 0))
	k.cyl(0.06 * s, 0.06 * s, joint, xf(Vector3(0.92, 0.76, 0) * s, Vector3(0, 0, 90)), 8)
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.04, 0.16, 0.03) * s, joint, at(0.96 * s, 0.66 * s, sz * 0.05 * s))
	k.box(Vector3(0.05, 0.05, 0.05) * s, tip, at(0.96 * s, 0.58 * s, 0))


static func part(kind: String, t: int) -> Mesh:
	var k := MeshKit.new()
	t = clampi(t, 0, 4)
	var p := ArchKit.pal(t)
	var col := _accent(kind)
	match kind:
		"fab":
			match t:
				0:
					# a PCB on a lazy-susan under the magnifier
					cy(k, 0.15, 0.02, Color(0.3, 0.3, 0.32), Vector3.ZERO, 10)
					bx(k, Vector3(0.22, 0.015, 0.15), Color(0.2, 0.52, 0.32), Vector3(0, 0.028, 0))
					for i in 3:
						bx(k, Vector3(0.04, 0.02, 0.04), Color(0.15, 0.15, 0.16), Vector3(-0.06 + i * 0.06, 0.04, 0.02 * (i % 2)))
					bx(k, Vector3(0.03, 0.03, 0.03), lit(Color(1.0, 0.4, 0.3), 0.4), Vector3(0.08, 0.045, -0.05))
				1:
					# a wafer on the spin chuck, dies glowing
					cy(k, 0.14, 0.012, Color(0.62, 0.66, 0.74), Vector3.ZERO, 12)
					for i in 5:
						for j in 5:
							var q := Vector2(-0.1 + i * 0.05, -0.1 + j * 0.05)
							if q.length() < 0.12:
								bx(k, Vector3(0.04, 0.006, 0.04), lit(col, 0.6) if (i + j) % 2 == 0 else Color(0.5, 0.56, 0.7), Vector3(q.x, 0.015, q.y))
				2:
					# a rooftop exhaust fan
					cy(k, 0.06, 0.06, Color(0.3, 0.32, 0.36), Vector3.ZERO, 8)
					for i in 4:
						bx(k, Vector3(0.4, 0.015, 0.09), Color(0.7, 0.72, 0.76), Vector3(0, 0.04, 0), Vector3(12, i * 45.0, 0))
				3:
					# a wafer-handling robot: base, two links, end effector + wafer
					cy(k, 0.09, 0.26, Color(0.84, 0.86, 0.88), Vector3.ZERO, 8)
					bx(k, Vector3(0.24, 0.05, 0.08), Color(0.9, 0.91, 0.92), Vector3(0.1, 0.29, 0))
					bx(k, Vector3(0.2, 0.04, 0.07), Color(0.9, 0.91, 0.92), Vector3(0.26, 0.33, 0.04), Vector3(0, 30, 0))
					cy(k, 0.1, 0.008, Color(0.62, 0.66, 0.74), Vector3(0.36, 0.355, 0.1), 12)
					bx(k, Vector3(0.12, 0.01, 0.12), lit(col, 0.5), Vector3(0.36, 0.36, 0.1))
				_:
					# the EUV collector: a glowing tilted ring with brass mirrors
					k.torus(0.42, 0.025, lit(Color(0.8, 0.6, 1.0), 0.35), xf(Vector3.ZERO, Vector3(14, 0, 0)), 18, 4)
					for i in 4:
						var a := TAU * i / 4.0
						bx(k, Vector3(0.1, 0.1, 0.03), p["trim"], Vector3(cos(a) * 0.42, sin(a) * 0.1, sin(a) * 0.42), Vector3(0, -rad_to_deg(a) + 90, 0))
		"refinery":
			# glowing rings rising up a column, spaced one stroke apart
			var st := stroke(kind, t)
			match t:
				0:
					for i in 4:
						k.sphere(0.025 + (i % 2) * 0.01, Color(0.9, 1.0, 1.0, 0.45), at(-0.06 + i * 0.04, (i % 3) * 0.12, 0.05 * ((i % 2) * 2 - 1)), 6, 3)
				_:
					var r: float = [0.0, 0.135, 0.28, 0.165, 0.465][t]
					var n: int = [1, 2, 2, 3, 4][t]
					for i in n:
						k.torus(r, 0.02 if t < 4 else 0.025, lit(col.lightened(0.3), 0.35), at(0, i * st, 0), 16, 4)
		"tune_lab":
			match t:
				0:
					# a swivel chair at the desk
					for i in 5:
						var a := TAU * i / 5.0
						bx(k, Vector3(0.24, 0.03, 0.04), Color(0.2, 0.2, 0.22), Vector3(cos(a) * 0.12, 0.05, sin(a) * 0.12), Vector3(0, -rad_to_deg(a), 0))
						cy(k, 0.025, 0.03, Color(0.15, 0.15, 0.16), Vector3(cos(a) * 0.23, 0, sin(a) * 0.23), 6)
					cy(k, 0.025, 0.36, Color(0.4, 0.42, 0.46), Vector3(0, 0.06, 0), 6)
					bx(k, Vector3(0.4, 0.08, 0.38), Color(0.85, 0.42, 0.24), Vector3(0, 0.44, 0))
					bx(k, Vector3(0.38, 0.5, 0.07), Color(0.85, 0.42, 0.24), Vector3(0, 0.72, 0.2), Vector3(-8, 0, 0))
					bx(k, Vector3(0.3, 0.12, 0.08), Color(0.2, 0.2, 0.22), Vector3(0, 0.92, 0.23), Vector3(-8, 0, 0))
					for sx in [-0.2, 0.2]:
						bx(k, Vector3(0.04, 0.03, 0.26), Color(0.2, 0.2, 0.22), Vector3(sx, 0.62, 0.02))
						bx(k, Vector3(0.03, 0.16, 0.03), Color(0.2, 0.2, 0.22), Vector3(sx, 0.54, 0.1))
				1:
					# the big tuning dial
					cy(k, 0.11, 0.025, Color(0.82, 0.84, 0.86), Vector3.ZERO, 12)
					cy(k, 0.08, 0.05, Color(0.2, 0.2, 0.22), Vector3(0, 0.025, 0), 12)
					bx(k, Vector3(0.02, 0.012, 0.09), lit(col, 0.4), Vector3(0, 0.08, 0.04))
					for i in 8:
						var a := TAU * i / 8.0
						bx(k, Vector3(0.012, 0.01, 0.025), Color(0.15, 0.15, 0.16), Vector3(cos(a) * 0.1, 0.03, sin(a) * 0.1))
				2, 3:
					# a dish panning across the sky
					var s := 1.0 if t == 2 else 2.0
					cy(k, 0.06 * s, 0.08 * s, Color(0.4, 0.42, 0.46), Vector3.ZERO, 8)
					for sx in [-1.0, 1.0]:
						bx(k, Vector3(0.03, 0.22, 0.06) * s, Color(0.6, 0.62, 0.66), Vector3(sx * 0.12, 0.17, 0) * s)
					var dx := xf(Vector3(0, 0.28, 0) * s, Vector3(55, 0, 0))
					k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.18 * s, 0.025 * s), Vector2(0.35 * s, 0.1 * s), Vector2(0.34 * s, 0.1 * s), Vector2(0.17 * s, 0.04 * s), Vector2(0, 0.015 * s)]), Color(0.94, 0.94, 0.93), dx, 14)
					for i in 3:
						var a := TAU * i / 3.0
						seg(k, dx * Vector3(cos(a) * 0.3 * s, 0.09 * s, sin(a) * 0.3 * s), dx * Vector3(0, 0.3 * s, 0), 0.012 * s, Color(0.6, 0.62, 0.66))
					k.sphere(0.035 * s, lit(col, 0.4) if t == 3 else Color(0.3, 0.32, 0.36), dx * at(0, 0.31 * s, 0), 6, 4)
					bx(k, Vector3(0.12, 0.12, 0.12) * s, Color(0.3, 0.32, 0.36), (dx * at(0, -0.1 * s, 0)).origin)
				_:
					# a ring of holographic panels over the dome
					k.torus(0.85, 0.02, p["trim"], at(0, 0, 0), 24, 3)
					for i in 6:
						var a := TAU * i / 6.0
						bx(k, Vector3(0.36, 0.24, 0.015), lit(col.lerp(Color(1, 0.95, 0.85), 0.3), 0.35), Vector3(cos(a) * 0.85, 0.2, sin(a) * 0.85), Vector3(-10, -rad_to_deg(a) + 90, 0))
						seg(k, Vector3(cos(a) * 0.85, 0, sin(a) * 0.85), Vector3(cos(a) * 0.85, 0.08, sin(a) * 0.85), 0.02, p["trim"])
		"hbm_works":
			match t:
				0:
					# the arbor press ram with its lever
					bx(k, Vector3(0.05, 0.85, 0.05), Color(0.6, 0.62, 0.66), Vector3(0, -0.27, 0))
					bx(k, Vector3(0.07, 0.05, 0.07), Color(0.3, 0.32, 0.36), Vector3(0, -0.68, 0))
					seg(k, Vector3(0, -0.12, 0), Vector3(0.3, 0.12, 0.12), 0.03, Color(0.6, 0.62, 0.66))
					k.sphere(0.04, Color(0.86, 0.3, 0.24), at(0.3, 0.12, 0.12), 6, 4)
				1:
					cy(k, 0.08, 0.95, Color(0.82, 0.84, 0.88), Vector3(0, -0.95, 0), 10)
					bx(k, Vector3(0.62, 0.15, 0.28), Color(0.5, 0.52, 0.56), Vector3(0, -1.0, 0))
					bx(k, Vector3(0.5, 0.03, 0.22), Color(0.3, 0.32, 0.36), Vector3(0, -1.09, 0))
				2:
					cy(k, 0.05, 1.05, Color(0.86, 0.88, 0.9), Vector3(0, -1.05, 0), 8)
					cy(k, 0.11, 0.08, Color(0.92, 0.93, 0.94), Vector3(0, -1.1, 0), 10)
					cy(k, 0.09, 0.01, lit(col, 0.4), Vector3(0, -1.11, 0), 10)
				3:
					for sx in [-0.2, 0.2]:
						cy(k, 0.07, 1.8, Color(0.82, 0.84, 0.88), Vector3(sx, -1.8, 0), 10)
					bx(k, Vector3(0.86, 0.18, 0.5), p["accent"], Vector3(0, -1.9, 0))
					bx(k, Vector3(0.7, 0.03, 0.4), p["dark"], Vector3(0, -2.0, 0))
					for i in 4:
						bx(k, Vector3(0.12, 0.08, 0.02), p["dark"], Vector3(-0.3 + i * 0.2, -1.9, 0.25))
				_:
					cy(k, 0.1, 0.5, p["trim"], Vector3(0, -0.5, 0), 10)
					bx(k, Vector3(1.1, 0.12, 0.75), p["trim"], Vector3(0, -0.56, 0))
					bx(k, Vector3(1.0, 0.02, 0.65), lit(col, 0.35), Vector3(0, -0.63, 0))
		"rlhf_gym":
			var a: Color = Color(0.96, 0.6, 0.24) if t < 4 else p["trim"]
			var j: Color = Pal.STEEL_DARK if t < 4 else p["wall"]
			var s: float = [0.45, 0.75, 0.36, 1.3, 1.6][t]
			# built along +x, then turned to rest pointing forward (+z)
			var ak := MeshKit.new()
			_arm(ak, s, a, j, lit(col, 0.4))
			if t == 4:
				ak.star(0.14, 0.06, 5, 0.04, lit(col, 0.35), xf(Vector3(0.96, 0.5, 0) * s, Vector3(90, 0, 0)))
			k.merge(ak, xf(Vector3.ZERO, Vector3(0, -90, 0)))
		"synth_lab":
			match t:
				0:
					k.sphere(0.06, lit(col, 0.4), at(0, 0, 0), 8, 5)
					k.torus(0.12, 0.01, Color(0.8, 0.66, 0.4), xf(Vector3.ZERO, Vector3(90, 0, 0)), 14, 3)
					k.torus(0.14, 0.01, Color(0.8, 0.66, 0.4), xf(Vector3.ZERO, Vector3(0, 0, 70)), 14, 3)
				1:
					k.torus(0.31, 0.015, lit(col, 0.4), xf(Vector3.ZERO, Vector3(12, 0, 0)), 18, 3)
					for i in 3:
						var a := TAU * i / 3.0
						k.sphere(0.03, Color(0.9, 0.9, 0.92), at(cos(a) * 0.31, sin(a) * 0.06, sin(a) * 0.31), 6, 4)
				2:
					k.torus(0.26, 0.018, lit(col, 0.4), xf(Vector3.ZERO, Vector3(90, 0, 0)), 16, 3)
					k.torus(0.3, 0.015, Color(0.95, 0.95, 0.96), xf(Vector3.ZERO, Vector3(0, 0, 60)), 16, 3)
				3:
					k.torus(0.66, 0.03, lit(col, 0.4), xf(Vector3.ZERO, Vector3(14, 0, 0)), 24, 4)
					for i in 4:
						var a := TAU * i / 4.0
						bx(k, Vector3(0.1, 0.08, 0.08), p["metal"], Vector3(cos(a) * 0.66, sin(a) * 0.16, sin(a) * 0.64))
				_:
					k.torus(0.82, 0.03, lit(col, 0.4), xf(Vector3.ZERO, Vector3(18, 0, 0)), 24, 4)
					k.torus(0.88, 0.025, p["trim"], xf(Vector3.ZERO, Vector3(-12, 40, 0)), 24, 4)
	return k.commit()


static func animate(kind: String, n: Node3D, t: float, busy: bool) -> void:
	var sp := 1.0 if busy else 0.0
	var tier := int(n.get_meta("tier", 2))
	match kind:
		"fab", "synth_lab":
			n.rotation.y += 0.05 * (0.2 + sp * 1.6)
			if kind == "synth_lab" and tier in [0, 2]:
				n.rotation.x += 0.02 * (0.2 + sp)
		"refinery":
			if not n.has_meta("y0"):
				n.set_meta("y0", n.position.y)
			n.position.y = float(n.get_meta("y0")) + (fmod(t * 0.6, 1.0) * stroke(kind, tier) if busy else 0.0)
		"tune_lab":
			n.rotation.y = sin(t * 2.0) * 1.2 * sp
		"hbm_works":
			if not n.has_meta("y0"):
				n.set_meta("y0", n.position.y)
			n.position.y = float(n.get_meta("y0")) - absf(sin(t * 3.0)) * stroke(kind, tier) * sp
		"rlhf_gym":
			n.rotation.y = sin(t * 1.6) * 1.4 * sp
