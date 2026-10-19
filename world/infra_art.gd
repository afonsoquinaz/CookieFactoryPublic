class_name InfraArt
## Looks for the infrastructure buildings of the inference economy. Each
## evolves through ArchKit's five eras (garage, workshop, campus, industrial,
## hyperscale), and every era is a different building:
##   gateway        API Gateway: a tin shed with a router on a shelf and a TV
##                  aerial; a network container with a yagi mast; a glass NOC
##                  kiosk with a wall of screens and a dish; a steel network
##                  hall with a lattice mast and a load-balancer tower; a
##                  graphite antenna spire with brass rings and fiber trunks
##   edge           Edge PoP: a repeater on a pole; a container datacenter and
##                  cell tower; a white micro-datacenter; a container stack
##                  with catwalks; a graphite pylon with glowing data rings
##   agent_hub      Agent Hub: a gazebo with a whiteboard; a robot workshop; a
##                  glass pavilion with a workflow screen; a robot depot with a
##                  gantry crane; a graphite hive with docking bays and drones
##   trainer        Training Cluster: a garage of mining rigs; a steel hall; a
##                  white compute hall; a supercomputer hall with cooling
##                  towers; a graphite cathedral of compute
##   launchpad      Launch Complex: a backyard stand; a gravel pad and gantry;
##                  a white complex with a control tower; an industrial complex
##                  with a water tower and tank farm; a graphite spaceport
##   groundstation  Ground Station: a TV dish on a tripod; two dishes and a
##                  container; radomes; big steerable antennas; phased arrays
## plus the rocket and the orbital datacenter's modules.
## Gameplay anchors (holders, screens, the dish packets fly from) are fixed
## points the building scripts use; see the *_intake / *_label / trainer_*
## helpers below.

static func lit(c: Color, a := 0.42) -> Color:
	return Color(c.r, c.g, c.b, a)


static func at(x: float, y: float, z: float) -> Transform3D:
	return MeshKit.at(x, y, z)


static func xf(p: Vector3, rot := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	return MeshKit.xf(p, rot, scl)


# ---------------------------------------------------------------- anchors

## Where request packets leave a channel building (local, y up).
static func intake(kind: String, t: int) -> Vector3:
	match kind:
		"gateway": return [Vector3(1.45, 3.75, -2.45), Vector3(1.5, 5.2, -2.5), Vector3(-0.7, 5.9, -2.3), Vector3(1.35, 9.3, -2.35), Vector3(0.2, 13.2, -2.2)][clampi(t, 0, 4)]
		"edge": return [Vector3(-1.9, 5.2, -2.0), Vector3(2.15, 7.4, -2.0), Vector3(2.1, 7.0, -2.1), Vector3(2.15, 9.3, -2.1), Vector3(0.95, 10.7, -1.45)][clampi(t, 0, 4)]
	return Vector3(0, 3, 0)


## Label height over a channel building per tier.
static func label_y(kind: String, t: int) -> float:
	match kind:
		"gateway": return [3.4, 4.0, 5.6, 5.0, 6.4][clampi(t, 0, 4)]
		"edge": return [3.4, 4.0, 4.6, 6.4, 6.6][clampi(t, 0, 4)]
		"agent_hub": return [3.6, 4.2, 4.9, 5.6, 6.6][clampi(t, 0, 4)]
		"groundstation": return [3.2, 4.4, 5.2, 6.6, 6.4][clampi(t, 0, 4)]
	return 4.0


# ---------------------------------------------------------------- helpers

## A box between two points (square section th, or th x th2).
static func beam(k: MeshKit, a: Vector3, b: Vector3, th: float, col: Color, th2 := -1.0) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var z := d / l
	var up := Vector3.UP if absf(z.y) < 0.95 else Vector3.RIGHT
	var x := up.cross(z).normalized()
	var y := z.cross(x)
	k.box(Vector3(th, th2 if th2 > 0.0 else th, l), col, Transform3D(Basis(x, y, z), (a + b) * 0.5))


## A cylinder between two points.
static func rod(k: MeshKit, a: Vector3, b: Vector3, r: float, col: Color, segs := 6) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.001:
		return
	var y := d / l
	var ref := Vector3.RIGHT if absf(y.x) < 0.9 else Vector3.BACK
	var x := y.cross(ref).normalized()
	var z := x.cross(y)
	k.cyl(r, l, col, Transform3D(Basis(x, y, z), a), segs)


## A sagging cable (a few straight pieces).
static func cable(k: MeshKit, a: Vector3, b: Vector3, sag: float, col: Color, th := 0.025, n := 4) -> void:
	var prev := a
	for i in range(1, n + 1):
		var f := float(i) / n
		var q := a.lerp(b, f) - Vector3(0, sin(f * PI) * sag, 0)
		beam(k, prev, q, th, col)
		prev = q


## Block letters (3x5 pixels) on a face: centred on x, bottom at y=0,
## facing +z. px = pixel size.
const FONT := {
	"A": [".#.", "#.#", "###", "#.#", "#.#"], "P": ["##.", "#.#", "##.", "#..", "#.."], "I": ["###", ".#.", ".#.", ".#.", "###"],
	"G": [".##", "#..", "#.#", "#.#", ".##"], "E": ["###", "#..", "##.", "#..", "###"], "D": ["##.", "#.#", "#.#", "#.#", "##."],
	"N": ["#.#", "###", "###", "#.#", "#.#"], "T": ["###", ".#.", ".#.", ".#.", ".#."], "S": [".##", "#..", ".#.", "..#", "##."],
	"O": [".#.", "#.#", "#.#", "#.#", ".#."], "L": ["#..", "#..", "#..", "#..", "###"], "U": ["#.#", "#.#", "#.#", "#.#", "###"],
	"H": ["#.#", "#.#", "###", "#.#", "#.#"], "C": [".##", "#..", "#..", "#..", ".##"], "R": ["##.", "#.#", "##.", "#.#", "#.#"],
	"K": ["#.#", "#.#", "##.", "#.#", "#.#"], "W": ["#.#", "#.#", "#.#", "###", "#.#"], "X": ["#.#", "#.#", ".#.", "#.#", "#.#"],
	"M": ["#.#", "###", "#.#", "#.#", "#.#"], "B": ["##.", "#.#", "##.", "#.#", "##."], "F": ["###", "#..", "##.", "#..", "#.."],
	"V": ["#.#", "#.#", "#.#", "#.#", ".#."], "Y": ["#.#", "#.#", ".#.", ".#.", ".#."], "0": ["###", "#.#", "#.#", "#.#", "###"],
	"1": [".#.", "##.", ".#.", ".#.", "###"], "2": ["##.", "..#", ".#.", "#..", "###"], "3": ["##.", "..#", ".#.", "..#", "##."],
	"4": ["#.#", "#.#", "###", "..#", "..#"], "5": ["###", "#..", "##.", "..#", "##."], "6": [".##", "#..", "###", "#.#", "###"],
	"7": ["###", "..#", ".#.", ".#.", ".#."], "8": ["###", "#.#", "###", "#.#", "###"], "9": ["###", "#.#", "###", "..#", "##."],
	"!": [".#.", ".#.", ".#.", "...", ".#."], "-": ["...", "...", "###", "...", "..."], "/": ["..#", "..#", ".#.", "#..", "#.."],
}


static func text(k: MeshKit, s: String, face: Transform3D, px: float, col: Color, depth := 0.02) -> void:
	var n := s.length()
	var x0 := -(n * 4 - 1) * px * 0.5
	for ci in n:
		var g: Array = FONT.get(s[ci], [])
		for row in g.size():
			var line: String = g[row]
			var j := 0
			while j < 3:
				if line[j] == "#":
					var e := j
					while e + 1 < 3 and line[e + 1] == "#":
						e += 1
					var w := (e - j + 1) * px
					k.box(Vector3(w, px, depth), col, face * at(x0 + (ci * 4 + j) * px + w * 0.5, (4 - row) * px + px * 0.5, depth * 0.5))
					j = e + 1
				else:
					j += 1


## A glowing screen with a chart on it (local face frame, centre at origin).
static func screen(k: MeshKit, face: Transform3D, w: float, h: float, frame: Color, glow: Color, kind := 0) -> void:
	k.box(Vector3(w + 0.08, h + 0.08, 0.06), frame, face * at(0, 0, 0.03))
	k.box(Vector3(w, h, 0.02), lit(glow.darkened(0.55), 0.7), face * at(0, 0, 0.065))
	var c2 := lit(glow, 0.35)
	match kind % 3:
		0:  # bars
			var n := maxi(3, int(w / 0.12))
			for i in n:
				var bh := h * (0.2 + 0.6 * absf(sin(i * 1.7 + w)))
				k.box(Vector3(w / n * 0.6, bh, 0.01), c2, face * at(-w * 0.45 + (i + 0.5) * w * 0.9 / n, -h * 0.45 + bh * 0.5, 0.08))
		1:  # a line chart
			var m := 6
			var prev := Vector2(-w * 0.45, 0)
			for i in range(1, m + 1):
				var q := Vector2(-w * 0.45 + w * 0.9 * i / m, h * 0.35 * sin(i * 1.3 + h))
				var mid := (prev + q) * 0.5
				k.box(Vector3(prev.distance_to(q), 0.025, 0.01), c2, face * xf(Vector3(mid.x, mid.y, 0.08), Vector3(0, 0, rad_to_deg(atan2(q.y - prev.y, q.x - prev.x)))))
				prev = q
		2:  # text rows
			for i in 4:
				k.box(Vector3(w * (0.5 + 0.1 * (i % 3)), 0.03, 0.01), c2, face * at(-w * 0.1, h * 0.3 - i * h * 0.2, 0.08))


## A server rack (base at origin, front +z): cabinet, door frame, LED rows.
static func rack(k: MeshKit, base: Transform3D, h: float, body: Color, led: Color, w := 0.55, d := 0.6, rows := 6) -> void:
	k.box(Vector3(w, h, d), body, base * at(0, h * 0.5, 0))
	k.box(Vector3(w - 0.08, h - 0.12, 0.02), body.darkened(0.35), base * at(0, h * 0.5, d * 0.5 + 0.005))
	for j in rows:
		var y := 0.18 + j * (h - 0.3) / rows
		k.box(Vector3(w - 0.16, 0.025, 0.01), lit(led, 0.35) if j % 3 != 2 else Color(0.5, 0.52, 0.56), base * at(0, y, d * 0.5 + 0.02))
	k.box(Vector3(w + 0.02, 0.04, d + 0.02), body.lightened(0.1), base * at(0, h, 0))


## A shipping container (length along local x, front face +z, base at y=0).
static func container(k: MeshKit, base: Transform3D, len: float, col: Color, h := 2.5, w := 2.3, ribs := true) -> void:
	k.box(Vector3(len, h, w), col, base * at(0, h * 0.5, 0))
	var dk := col.darkened(0.22)
	if ribs:
		var n := int(len / 0.28)
		for i in n:
			var x := -len * 0.5 + 0.2 + (i + 0.5) * (len - 0.4) / n
			for sz in [-1.0, 1.0]:
				k.box(Vector3(0.07, h - 0.24, 0.04), dk, base * at(x, h * 0.5, sz * (w * 0.5 + 0.015)))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.14, h, 0.14), dk, base * at(sx * (len * 0.5 - 0.06), h * 0.5, sz * (w * 0.5 - 0.06)))
		# the end: doors with locking bars
		for j in 4:
			k.box(Vector3(0.03, h - 0.3, 0.04), Color(0.55, 0.56, 0.58), base * at(sx * (len * 0.5 + 0.02), h * 0.5, -w * 0.36 + j * w * 0.24))
	for sy in [0.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(len, 0.12, 0.08), dk, base * at(0, 0.06 + sy * (h - 0.12), sz * (w * 0.5 - 0.02)))


## A tapered lattice tower (square, legs w0 apart at the bottom, w1 at the top).
static func mast(k: MeshKit, base: Vector3, h: float, w0: float, w1: float, col: Color, seg := 0.9, th := 0.05, col2 := Color.TRANSPARENT) -> void:
	var n := maxi(2, int(h / seg))
	var c2 := col2 if col2.a > 0.0 else col
	var corner := func(i: int, y: float) -> Vector3:
		var w := lerpf(w0, w1, y / h) * 0.5
		var sx := -1.0 if i == 0 or i == 3 else 1.0
		var sz := -1.0 if i < 2 else 1.0
		return base + Vector3(sx * w, y, sz * w)
	for i in 4:
		beam(k, corner.call(i, 0.0), corner.call(i, h), th, col)
	for s in n:
		var y0 := h * s / n
		var y1 := h * (s + 1) / n
		var c := col if s % 2 == 0 else c2
		for i in 4:
			var j := (i + 1) % 4
			beam(k, corner.call(i, y1), corner.call(j, y1), th * 0.7, c)
			beam(k, corner.call(i, y0) if s % 2 == 0 else corner.call(j, y0), corner.call(j, y1) if s % 2 == 0 else corner.call(i, y1), th * 0.55, c)


## A parabolic dish on a pedestal (base on the ground, dish looking up and
## tilted toward +z, then turned by yaw). Returns the feed point.
static func sat_dish(k: MeshKit, base: Transform3D, r: float, t: int, tilt := 40.0, yaw := 0.0, ped := -1.0, col := Color(0.95, 0.95, 0.94)) -> Vector3:
	var p := ArchKit.pal(t)
	var b := base * xf(Vector3.ZERO, Vector3(0, yaw, 0))
	ped = ped if ped >= 0.0 else r * 0.8
	var metal: Color = p["metal"] if t != 4 else p["trim"]
	if ped > 0.0:
		k.cyl(r * 0.28, 0.12, p["dark"] if t >= 3 else Color(0.62, 0.62, 0.6), b, 8)
		k.cyl(r * 0.1, ped, metal, b * at(0, 0.1, 0), 8)
	# yoke
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, r * 0.35, 0.08), metal, b * at(sx * r * 0.18, ped + r * 0.12, 0))
	var dx := b * xf(Vector3(0, ped + r * 0.25, 0), Vector3(tilt, 0, 0))
	k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.5, r * 0.07), Vector2(r, r * 0.28), Vector2(r * 1.02, r * 0.3), Vector2(r * 0.5, r * 0.12), Vector2(0.0, r * 0.06)]), col, dx, 14)
	k.box(Vector3(r * 0.6, r * 0.12, r * 0.6), col.darkened(0.2), dx * at(0, -r * 0.02, 0))
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		beam(k, (dx * Vector3(cos(a) * r * 0.9, r * 0.27, sin(a) * r * 0.9)), dx * Vector3(0, r * 0.9, 0), r * 0.025, metal)
	k.cyl(r * 0.07, r * 0.12, Color(0.3, 0.32, 0.36), dx * at(0, r * 0.86, 0), 6)
	var feed: Vector3 = dx * Vector3(0, r * 0.98, 0)
	if t >= 3:
		k.sphere(r * 0.06, lit(ArchKit.c(t, "glow"), 0.3), at(feed.x, feed.y, feed.z), 6, 4)
	return feed


## A microwave drum dish (face +z): drum, radome, mounting arm.
static func drum(k: MeshKit, base: Transform3D, r: float, col := Color(0.92, 0.92, 0.9)) -> void:
	k.cyl(r, r * 0.5, col, base * xf(Vector3.ZERO, Vector3(90, 0, 0)), 10)
	k.cyl(r * 0.96, 0.04, Color(0.84, 0.84, 0.8), base * xf(Vector3(0, 0, 0.02), Vector3(90, 0, 0)), 10)
	k.box(Vector3(0.05, r * 1.4, 0.05), Color(0.5, 0.52, 0.56), base * at(0, 0, -r * 0.6))


## A sector panel antenna (base at its middle).
static func panel_ant(k: MeshKit, base: Transform3D, h := 0.9, col := Color(0.94, 0.94, 0.92)) -> void:
	k.box(Vector3(0.22, h, 0.08), col, base)
	k.box(Vector3(0.04, 0.12, 0.2), Color(0.5, 0.52, 0.56), base * at(0, h * 0.3, -0.1))
	k.box(Vector3(0.04, 0.12, 0.2), Color(0.5, 0.52, 0.56), base * at(0, -h * 0.3, -0.1))


## A yagi antenna along local +z (base at the boom's back end).
static func yagi(k: MeshKit, base: Transform3D, len: float, col := Color(0.8, 0.82, 0.84), n := 8) -> void:
	k.box(Vector3(0.03, 0.03, len), col, base * at(0, 0, len * 0.5))
	for i in n:
		var w := 0.7 - i * 0.04
		k.box(Vector3(w, 0.015, 0.015), col, base * at(0, 0, 0.08 + i * (len - 0.1) / n))
	k.box(Vector3(0.08, 0.06, 0.06), Color(0.2, 0.2, 0.22), base * at(0, -0.04, 0.12))


## A small quad drone hovering at p.
static func drone(k: MeshKit, p: Vector3, t: int, yaw := 0.0) -> void:
	var b := xf(p, Vector3(0, yaw, 0))
	var body: Color = ArchKit.c(t, "wall2") if t >= 4 else Color(0.9, 0.9, 0.9)
	k.box(Vector3(0.22, 0.07, 0.22), body, b)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			beam(k, b * Vector3(0, 0, 0), b * Vector3(sx * 0.2, 0.02, sz * 0.2), 0.025, body.darkened(0.2))
			k.cyl(0.09, 0.01, lit(ArchKit.c(t, "glow"), 0.6) if t >= 4 else Color(0.3, 0.3, 0.32), b * at(sx * 0.2, 0.04, sz * 0.2), 8)
	k.box(Vector3(0.1, 0.02, 0.02), lit(ArchKit.c(t, "accent2") if t >= 4 else Color(0.4, 1.0, 0.5), 0.3), b * at(0, -0.04, 0.11))


## A wooden crate.
static func crate(k: MeshKit, base: Transform3D, s := 0.4, col := Color(0.72, 0.56, 0.38)) -> void:
	k.box(Vector3(s, s * 0.8, s), col, base * at(0, s * 0.4, 0))
	for sz in [-1.0, 1.0]:
		k.box(Vector3(s + 0.02, 0.05, 0.02), col.darkened(0.2), base * at(0, s * 0.15, sz * s * 0.5))
		k.box(Vector3(s + 0.02, 0.05, 0.02), col.darkened(0.2), base * at(0, s * 0.65, sz * s * 0.5))
	k.box(Vector3(0.02, s * 0.8, s + 0.02), col.darkened(0.15), base * at(s * 0.5, s * 0.4, 0))


## A folding table (top at 0.74) or bench (h).
static func table(k: MeshKit, base: Transform3D, w: float, d: float, top: Color, legs: Color, h := 0.74) -> void:
	k.box(Vector3(w, 0.04, d), top, base * at(0, h - 0.02, 0))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.04, h - 0.04, 0.04), legs, base * at(sx * (w * 0.5 - 0.06), (h - 0.04) * 0.5, sz * (d * 0.5 - 0.06)))


## A chair (facing +z).
static func chair(k: MeshKit, base: Transform3D, col: Color) -> void:
	k.box(Vector3(0.42, 0.05, 0.4), col, base * at(0, 0.45, 0))
	k.box(Vector3(0.42, 0.42, 0.04), col, base * at(0, 0.7, -0.19))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.03, 0.45, 0.03), col.darkened(0.3), base * at(sx * 0.18, 0.22, sz * 0.17))


## A laptop on a surface (open, screen glowing).
static func laptop(k: MeshKit, base: Transform3D, glow := Color(0.5, 0.86, 1.0)) -> void:
	k.box(Vector3(0.34, 0.02, 0.24), Color(0.3, 0.31, 0.34), base * at(0, 0.01, 0))
	k.box(Vector3(0.34, 0.22, 0.015), Color(0.3, 0.31, 0.34), base * xf(Vector3(0, 0.11, -0.13), Vector3(-12, 0, 0)))
	k.box(Vector3(0.3, 0.18, 0.01), lit(glow, 0.4), base * xf(Vector3(0, 0.11, -0.12), Vector3(-12, 0, 0)))


## A shrub (or a small tree when h > 0).
static func shrub(k: MeshKit, p: Vector3, r: float, h := 0.0, col := Color(0.42, 0.6, 0.36)) -> void:
	if h > 0.0:
		k.cyl(0.05, h, Color(0.42, 0.32, 0.24), at(p.x, p.y, p.z), 5)
		k.sphere(r, col, at(p.x, p.y + h + r * 0.6, p.z), 8, 5)
		k.sphere(r * 0.7, col.darkened(0.08), at(p.x + r * 0.5, p.y + h + r * 0.2, p.z + r * 0.2), 7, 4)
	else:
		k.sphere(r, col, xf(Vector3(p.x, p.y + r * 0.6, p.z), Vector3.ZERO, Vector3(1.2, 0.8, 1.0)), 8, 4)


## A bollard.
static func bollard(k: MeshKit, p: Vector3, col: Color, h := 0.8) -> void:
	k.cyl(0.07, h, col, at(p.x, p.y, p.z), 6)
	k.box(Vector3(0.15, 0.06, 0.15), Color(0.16, 0.16, 0.18), at(p.x, p.y + h * 0.75, p.z))


## Ribbed corrugated roof sheet (centre c, size w x d, slope angle about x).
static func tin_roof(k: MeshKit, c: Vector3, w: float, d: float, col: Color, slope := 0.0, pitch := 0.18) -> void:
	var b := xf(c, Vector3(slope, 0, 0))
	k.box(Vector3(w, 0.04, d), col, b)
	for i in int(w / pitch):
		k.box(Vector3(0.05, 0.035, d), col.darkened(0.1), b * at(-w * 0.5 + (i + 0.5) * pitch, 0.03, 0))


## A box fan (face +z).
static func box_fan(k: MeshKit, base: Transform3D, s := 0.45) -> void:
	k.box(Vector3(s, s, 0.14), Color(0.9, 0.9, 0.88), base * at(0, s * 0.5, 0))
	k.cyl(s * 0.4, 0.02, Color(0.25, 0.26, 0.28), base * xf(Vector3(0, s * 0.5, 0.07), Vector3(90, 0, 0)), 8)
	k.box(Vector3(s * 0.7, 0.03, 0.02), Color(0.6, 0.62, 0.64), base * at(0, s * 0.5, 0.09))
	k.box(Vector3(0.03, s * 0.7, 0.02), Color(0.6, 0.62, 0.64), base * at(0, s * 0.5, 0.09))


## A traffic cone.
static func cone(k: MeshKit, p: Vector3) -> void:
	k.box(Vector3(0.26, 0.03, 0.26), Color(0.95, 0.45, 0.15), at(p.x, p.y + 0.015, p.z))
	k.cone(0.1, 0.42, Color(0.95, 0.45, 0.15), at(p.x, p.y, p.z), 6)
	k.cyl(0.065, 0.06, Color(0.96, 0.96, 0.94), at(p.x, p.y + 0.18, p.z), 6, 0.0, 0.05)


## A barrel / drum.
static func barrel(k: MeshKit, p: Vector3, col: Color, r := 0.2, h := 0.6) -> void:
	k.cyl(r, h, col, at(p.x, p.y, p.z), 8)
	k.cyl(r + 0.01, 0.03, col.darkened(0.25), at(p.x, p.y + h * 0.33, p.z), 8)
	k.cyl(r + 0.01, 0.03, col.darkened(0.25), at(p.x, p.y + h * 0.66, p.z), 8)


## A glowing ring (torus, flat in xz at p, or tilted).
static func ring(k: MeshKit, p: Vector3, R: float, r: float, col: Color, rot := Vector3.ZERO, segs := 18) -> void:
	k.torus(R, r, col, xf(p, rot), segs, 4)


## Cable ladder from a to b (two rails and rungs, with cables on it).
static func cable_ladder(k: MeshKit, a: Vector3, b: Vector3, w: float, col: Color, cab: Color) -> void:
	var d := b - a
	var l := d.length()
	if l < 0.05:
		return
	var z := d / l
	var up := Vector3.UP if absf(z.y) < 0.95 else Vector3.BACK
	var x := up.cross(z).normalized()
	for s in [-1.0, 1.0]:
		beam(k, a + x * s * w * 0.5, b + x * s * w * 0.5, 0.04, col)
	for i in int(l / 0.3):
		var q := a + z * (0.15 + i * 0.3)
		beam(k, q - x * w * 0.5, q + x * w * 0.5, 0.025, col)
	beam(k, a, b, w * 0.6, cab, 0.07)


## A grid of panel seams on a face (local face frame, bottom at y=0).
static func seams(k: MeshKit, face: Transform3D, w: float, h: float, nx: int, ny: int, col: Color) -> void:
	for i in range(1, nx):
		k.box(Vector3(0.025, h, 0.012), col, face * at(-w * 0.5 + i * w / nx, h * 0.5, 0.006))
	for j in range(1, ny):
		k.box(Vector3(w, 0.025, 0.012), col, face * at(0, j * h / ny, 0.006))


## Seams on a horizontal surface centred at c (w along x, d along z).
static func floor_grid(k: MeshKit, c: Vector3, w: float, d: float, nx: int, ny: int, col: Color) -> void:
	seams(k, xf(Vector3(c.x, c.y, c.z + d * 0.5), Vector3(-90, 0, 0)), w, d, nx, ny, col)


## Spots kept clear for Growth gear on kind at tier t (ground or roof slots),
## as rects in local metres.
static func slot_rects(kind: String, t: int, roof: bool) -> Array:
	var out := []
	for s in Growth.slots(kind, t):
		if bool(s.get("top", false)) != roof:
			continue
		var p: Vector3 = s["p"]
		var e := 0.34 if roof else 0.45
		out.append(Rect2(p.x - e, p.z - e, e * 2.0, e * 2.0))
	return out


static func _clear(p: Vector2, r: float, avoid: Array) -> bool:
	for a in avoid:
		if (a as Rect2).grow(r).has_point(p):
			return false
	return true


## Roof gear scattered over a flat roof rect at height y, era-appropriate,
## keeping clear of the avoid rects (roof slots).
static func roof_dress(k: MeshKit, r: Rect2, y: float, t: int, seed: int, avoid: Array, density := 0.5) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = seed * 9973 + t
	var p := ArchKit.pal(t)
	var nx := maxi(1, int(r.size.x / 0.55))
	var nz := maxi(1, int(r.size.y / 0.55))
	for i in nx:
		for j in nz:
			if g.randf() > density:
				continue
			var q := Vector2(r.position.x + (i + 0.5) * r.size.x / nx, r.position.y + (j + 0.5) * r.size.y / nz)
			q += Vector2(g.randf_range(-0.08, 0.08), g.randf_range(-0.08, 0.08))
			if not _clear(q, 0.25, avoid):
				continue
			var v := Vector3(q.x, y, q.y)
			match t:
				0:
					match g.randi() % 4:
						0: k.box(Vector3(0.22, 0.08, 0.1), Pal.BRICK, xf(v + Vector3(0, 0.04, 0), Vector3(0, g.randf() * 90.0, 0)))
						1: k.box(Vector3(0.5, 0.02, 0.4), Color(0.6, 0.62, 0.64).darkened(g.randf() * 0.2), xf(v + Vector3(0, 0.01, 0), Vector3(0, g.randf() * 40.0, 0)))
						2: k.cyl(0.08, 0.2, Color(0.62, 0.64, 0.66), at(v.x, v.y, v.z), 6)
						_: k.box(Vector3(0.7, 0.03, 0.08), Pal.WOOD_LIGHT, xf(v + Vector3(0, 0.015, 0), Vector3(0, g.randf() * 180.0, 0)))
				1:
					match g.randi() % 4:
						0: vent(k, v, p["metal"], 0.3)
						1: k.box(Vector3(0.35, 0.25, 0.3), Color(0.8, 0.82, 0.84), at(v.x, v.y + 0.125, v.z))
						2: ArchKit.pipes(k, [v + Vector3(-0.25, 0.08, 0), v + Vector3(0.25, 0.08, 0)], 0.03, Color(0.3, 0.3, 0.32))
						_: k.box(Vector3(0.4, 0.06, 0.4), p["trim"], at(v.x, v.y + 0.03, v.z))
				2:
					match g.randi() % 4:
						0: vent(k, v, p["metal"], 0.25)
						1: ArchKit.solar(k, at(v.x, v.y, v.z), 1, t, 15.0, 0.22)
						2: k.box(Vector3(0.4, 0.06, 0.4), lit(Color(0.7, 0.88, 0.95), 0.75), at(v.x, v.y + 0.03, v.z))
						_: k.box(Vector3(0.3, 0.2, 0.3), Color(0.92, 0.93, 0.94), at(v.x, v.y + 0.1, v.z))
				3:
					match g.randi() % 4:
						0: vent(k, v, p["metal"], 0.35, 0.08)
						1: duct(k, v + Vector3(-0.25, 0.12, 0), v + Vector3(0.25, 0.12, 0), 0.22, 0.18, p["metal"])
						2:
							k.box(Vector3(0.36, 0.3, 0.36), p["dark"], at(v.x, v.y + 0.15, v.z))
							k.box(Vector3(0.3, 0.02, 0.01), lit(p["glow"], 0.4), at(v.x, v.y + 0.22, v.z + 0.185))
						_: k.cyl(0.14, 0.08, Color(0.22, 0.23, 0.26), at(v.x, v.y, v.z), 8)
				_:
					match g.randi() % 3:
						0:
							k.box(Vector3(0.3, 0.2, 0.3), p["wall2"], at(v.x, v.y + 0.1, v.z))
							k.box(Vector3(0.32, 0.02, 0.32), p["trim"], at(v.x, v.y + 0.2, v.z))
						1: k.box(Vector3(0.05, 0.35, 0.35), p["wall2"], at(v.x, v.y + 0.175, v.z))
						_: k.box(Vector3(0.25, 0.04, 0.25), lit(p["accent2"], 0.5), at(v.x, v.y + 0.02, v.z))


## Small yard props scattered over a ground rect, era-appropriate, clear of
## the avoid rects (ground slots, paths).
static func yard_dress(k: MeshKit, r: Rect2, t: int, seed: int, avoid: Array, density := 0.45) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = seed * 7919 + t * 13
	var p := ArchKit.pal(t)
	var nx := maxi(1, int(r.size.x / 0.6))
	var nz := maxi(1, int(r.size.y / 0.6))
	for i in nx:
		for j in nz:
			if g.randf() > density:
				continue
			var q := Vector2(r.position.x + (i + 0.5) * r.size.x / nx, r.position.y + (j + 0.5) * r.size.y / nz)
			if not _clear(q, 0.2, avoid):
				continue
			var v := Vector3(q.x, 0.1, q.y)
			match t:
				0:
					match g.randi() % 5:
						0: crate(k, xf(v, Vector3(0, g.randf() * 40.0, 0)), 0.3 + g.randf() * 0.1)
						1: barrel(k, v, [Color(0.3, 0.46, 0.7), Color(0.78, 0.3, 0.26), Color(0.2, 0.5, 0.3)][g.randi() % 3], 0.16, 0.48)
						2: k.cyl(0.12, 0.22, Color(0.9, 0.9, 0.88), at(v.x, v.y, v.z), 8, 0.0, 0.14)
						3: k.torus(0.22, 0.08, Color(0.16, 0.16, 0.17), at(v.x, v.y + 0.08, v.z), 10, 4)
						_: shrub(k, v, 0.2)
				1:
					match g.randi() % 4:
						0: cone(k, v)
						1: ibc(k, xf(v, Vector3(0, g.randf() * 20.0, 0)))
						2: crate(k, xf(v, Vector3(0, g.randf() * 20.0, 0)), 0.4, Color(0.36, 0.5, 0.36))
						_: barrel(k, v, Color(0.2, 0.36, 0.66), 0.18, 0.55)
				2:
					match g.randi() % 3:
						0: shrub(k, v, 0.22)
						1: bin(k, v, p["accent"])
						_: k.box(Vector3(0.12, 0.5, 0.12), Color(0.94, 0.95, 0.96), at(v.x, v.y + 0.25, v.z))
				3:
					match g.randi() % 4:
						0: barrel(k, v, Color(0.3, 0.5, 0.8), 0.18, 0.55)
						1: bollard(k, v, p["accent"], 0.8)
						2: k.box(Vector3(0.45, 0.8, 0.35), p["dark"], at(v.x, v.y + 0.4, v.z))
						_: ibc(k, xf(v, Vector3.ZERO))
				_:
					match g.randi() % 3:
						0:
							k.cyl(0.08, 0.6, p["wall2"], at(v.x, v.y, v.z), 6)
							k.box(Vector3(0.17, 0.04, 0.17), lit(p["glow"], 0.35), at(v.x, v.y + 0.6, v.z))
						1:
							k.box(Vector3(0.5, 0.4, 0.5), p["wall2"], at(v.x, v.y + 0.2, v.z))
							k.sphere(0.22, Color(0.22, 0.36, 0.26), at(v.x, v.y + 0.55, v.z), 7, 4)
						_: k.box(Vector3(0.3, 0.005, 0.3), lit(p["accent2"], 0.5), at(v.x, v.y + 0.005, v.z))


## Wall gear on a face (local face frame, bottom at y=0): a downpipe, boxes,
## lights, vents and signs, era-appropriate.
static func wall_dress(k: MeshKit, face: Transform3D, w: float, h: float, t: int, seed: int) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = seed * 6007 + t
	var p := ArchKit.pal(t)
	var pc: Color = [Color(0.6, 0.62, 0.64), Color(0.62, 0.64, 0.68), Color(0.9, 0.9, 0.92), Color(0.36, 0.6, 0.86), p["trim"]][t]
	var ex := (w * 0.5 - 0.12) * (1.0 if g.randf() < 0.5 else -1.0)
	k.box(Vector3(0.07, h, 0.07), pc, face * at(ex, h * 0.5, 0.06))
	for i in 2 + int(w / 1.2):
		var x := g.randf_range(-w * 0.45, w * 0.45)
		var y := g.randf_range(0.5, h - 0.4)
		match g.randi() % 4:
			0: ebox(k, face * at(x, y, 0), p["metal"] if t != 4 else p["wall2"], 0.28, 0.36)
			1: ArchKit.louvres(k, face * at(x, y, 0), 0.3, 0.25, p["wall2"], 3)
			2:
				k.box(Vector3(0.22, 0.07, 0.1), p["dark"], face * at(x, y, 0.05))
				k.box(Vector3(0.18, 0.02, 0.05), lit(p["glow"], 0.35), face * at(x, y - 0.04, 0.08))
			_: k.box(Vector3(0.3, 0.2, 0.02), [Color(0.98, 0.84, 0.3), Color(0.95, 0.95, 0.95), p["accent"]][g.randi() % 3], face * at(x, y, 0.01))
	if t >= 1:
		k.box(Vector3(w - 0.3, 0.05, 0.05), pc.darkened(0.1), face * at(0, g.randf_range(0.6, h - 0.4), 0.05))


## A horizontal tank on saddles, centred (length along local x).
static func htank(k: MeshKit, base: Transform3D, r: float, len: float, col: Color) -> void:
	k.capsule(r, len, col, base * xf(Vector3(len * 0.5, r + 0.25, 0), Vector3(0, 0, 90)), 10, 3)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.12, r + 0.25, r * 1.5), Color(0.35, 0.36, 0.4), base * at(sx * len * 0.3, (r + 0.25) * 0.5, 0))
		k.box(Vector3(0.14, 0.04, r * 1.6), Color(0.3, 0.31, 0.34), base * at(sx * len * 0.3, 0.02, 0))
	k.cyl(0.05, 0.1, col.darkened(0.2), base * at(0, r * 2.0 + 0.24, 0), 6)


## A door with its frame but no canopy (local face frame).
static func door_plain(k: MeshKit, face: Transform3D, t: int, w := 0.8, h := 1.9) -> void:
	var p := ArchKit.pal(t)
	k.box(Vector3(w + 0.12, h + 0.08, 0.06), p["frame"], face * at(0, (h + 0.08) * 0.5, 0.03))
	k.box(Vector3(w, h, 0.05), p["wall2"].darkened(0.2) if t < 2 else p["glass"], face * at(0, h * 0.5, 0.05))
	k.box(Vector3(0.05, 0.12, 0.05), p["metal"], face * at(w * 0.35, h * 0.5, 0.09))
	k.box(Vector3(w + 0.2, 0.05, 0.12), p["trim"], face * at(0, h + 0.12, 0.06))


## A rectangular duct from a to b (w wide, h tall), with flanges.
static func duct(k: MeshKit, a: Vector3, b: Vector3, w: float, h: float, col: Color) -> void:
	beam(k, a, b, w, col, h)
	var l := a.distance_to(b)
	for i in int(l / 0.8) + 1:
		var q := a.lerp(b, minf(1.0, i * 0.8 / maxf(l, 0.01)))
		beam(k, q - (b - a).normalized() * 0.02, q + (b - a).normalized() * 0.02, w + 0.04, col.darkened(0.15), h + 0.04)


## A mushroom vent / stack on a roof.
static func vent(k: MeshKit, p: Vector3, col := Color(0.62, 0.64, 0.66), h := 0.35, r := 0.07) -> void:
	k.cyl(r, h, col, at(p.x, p.y, p.z), 6)
	k.cyl(r * 1.7, 0.05, col.darkened(0.15), at(p.x, p.y + h, p.z), 6)


## A roof hatch with a grab rail.
static func hatch(k: MeshKit, p: Vector3, col: Color) -> void:
	k.box(Vector3(0.7, 0.2, 0.7), col, at(p.x, p.y + 0.1, p.z))
	k.box(Vector3(0.74, 0.04, 0.74), col.darkened(0.2), at(p.x, p.y + 0.22, p.z))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.03, 0.5, 0.03), Color(0.95, 0.76, 0.2), at(p.x + sx * 0.3, p.y + 0.45, p.z - 0.36))
	k.box(Vector3(0.63, 0.03, 0.03), Color(0.95, 0.76, 0.2), at(p.x, p.y + 0.7, p.z - 0.36))


## A litter bin.
static func bin(k: MeshKit, p: Vector3, col: Color) -> void:
	k.cyl(0.16, 0.55, col, at(p.x, p.y, p.z), 8)
	k.cyl(0.18, 0.05, col.darkened(0.25), at(p.x, p.y + 0.55, p.z), 8)


## A fire hydrant.
static func hydrant(k: MeshKit, p: Vector3) -> void:
	k.cyl(0.08, 0.45, Color(0.85, 0.2, 0.18), at(p.x, p.y, p.z), 6)
	k.sphere(0.08, Color(0.85, 0.2, 0.18), at(p.x, p.y + 0.45, p.z), 6, 3)
	k.box(Vector3(0.26, 0.06, 0.06), Color(0.85, 0.2, 0.18), at(p.x, p.y + 0.32, p.z))


## A bicycle (local +z forward).
static func bike(k: MeshKit, base: Transform3D, col: Color) -> void:
	for sz in [-1.0, 1.0]:
		k.torus(0.24, 0.02, Color(0.15, 0.15, 0.16), base * xf(Vector3(0, 0.26, sz * 0.4), Vector3(0, 0, 90)), 10, 3)
	beam(k, base * Vector3(0, 0.3, -0.4), base * Vector3(0, 0.55, 0.05), 0.04, col)
	beam(k, base * Vector3(0, 0.55, 0.05), base * Vector3(0, 0.3, 0.4), 0.04, col)
	beam(k, base * Vector3(0, 0.6, -0.15), base * Vector3(0, 0.55, 0.3), 0.04, col)
	k.box(Vector3(0.4, 0.03, 0.03), Color(0.2, 0.2, 0.22), base * at(0, 0.75, 0.3))
	k.box(Vector3(0.1, 0.04, 0.2), Color(0.2, 0.2, 0.22), base * at(0, 0.66, -0.18))


## A wall-mounted electrical box / meter.
static func ebox(k: MeshKit, face: Transform3D, col := Color(0.82, 0.83, 0.84), w := 0.35, h := 0.45) -> void:
	k.box(Vector3(w, h, 0.14), col, face * at(0, 0, 0.07))
	k.box(Vector3(w * 0.6, 0.04, 0.01), Color(0.95, 0.8, 0.2), face * at(0, h * 0.3, 0.145))
	k.box(Vector3(0.04, h * 0.6, 0.02), col.darkened(0.3), face * at(w * 0.35, 0, 0.15))


## A CCTV camera on a bracket (local: wall at z=0).
static func cctv(k: MeshKit, face: Transform3D) -> void:
	k.box(Vector3(0.05, 0.05, 0.2), Color(0.3, 0.3, 0.32), face * at(0, 0, 0.1))
	k.box(Vector3(0.1, 0.1, 0.24), Color(0.92, 0.92, 0.9), face * xf(Vector3(0, -0.04, 0.24), Vector3(20, 0, 0)))
	k.box(Vector3(0.03, 0.02, 0.01), Color(1.0, 0.3, 0.25, 0.3), face * at(0.03, -0.02, 0.37))


## A pallet with a stack of boxes, wrapped (local, base at origin).
static func pallet(k: MeshKit, base: Transform3D, col: Color, n := 4) -> void:
	for j in 3:
		k.box(Vector3(1.0, 0.03, 0.12), Pal.WOOD_LIGHT, base * at(0, 0.115, -0.38 + j * 0.38))
	for sx in [-1.0, 0.0, 1.0]:
		k.box(Vector3(0.1, 0.1, 0.9), Pal.WOOD, base * at(sx * 0.44, 0.05, 0))
	for i in n:
		k.box(Vector3(0.45, 0.3, 0.38), col if i % 2 == 0 else col.darkened(0.08), base * at(-0.23 + (i % 2) * 0.46, 0.28 + (i / 2) * 0.31, (0.2 if (i / 2) % 2 == 0 else -0.2)))


## An IBC tote (a white tank in a steel cage).
static func ibc(k: MeshKit, base: Transform3D) -> void:
	k.box(Vector3(0.9, 0.12, 0.8), Color(0.4, 0.42, 0.46), base * at(0, 0.06, 0))
	k.box(Vector3(0.84, 0.78, 0.74), Color(0.92, 0.92, 0.88), base * at(0, 0.52, 0))
	for i in 4:
		k.box(Vector3(0.88, 0.03, 0.78), Color(0.6, 0.62, 0.64), base * at(0, 0.2 + i * 0.22, 0))
	k.cyl(0.1, 0.06, Color(0.2, 0.2, 0.22), base * at(0, 0.91, 0), 6)


## Tufts of grass and pebbles scattered over a rectangle (seeded).
static func tufts(k: MeshKit, r: Rect2, n: int, seed: int, col := Color(0.44, 0.58, 0.32)) -> void:
	var g := RandomNumberGenerator.new()
	g.seed = seed * 7121 + 3
	for i in n:
		var x := g.randf_range(r.position.x, r.end.x)
		var z := g.randf_range(r.position.y, r.end.y)
		if i % 3 == 0:
			k.box(Vector3(0.12, 0.04, 0.09), Color(0.6, 0.58, 0.54), xf(Vector3(x, 0.11, z), Vector3(0, g.randf() * 90.0, 0)))
		else:
			for j in 3:
				k.box(Vector3(0.03, 0.12, 0.03), col.darkened(j * 0.06), xf(Vector3(x + (j - 1) * 0.04, 0.15, z + (j % 2) * 0.03), Vector3((j - 1) * 18.0, 0, (j - 1) * 14.0)))


## A manhole cover.
static func manhole(k: MeshKit, p: Vector3, col := Color(0.32, 0.33, 0.35)) -> void:
	k.cyl(0.3, 0.015, col, at(p.x, p.y, p.z), 10)
	for i in 3:
		k.box(Vector3(0.44, 0.006, 0.03), col.darkened(0.2), at(p.x, p.y + 0.016, p.z - 0.1 + i * 0.1))


## Shelving with things on it (local: back at z=0 facing +z, base at origin).
static func shelving(k: MeshKit, base: Transform3D, w: float, h: float, levels: int, frame: Color, items: Array) -> void:
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, h, 0.4), frame, base * at(sx * w * 0.5, h * 0.5, 0.2))
	for j in levels:
		var y := 0.1 + j * (h - 0.1) / levels
		k.box(Vector3(w, 0.03, 0.4), frame, base * at(0, y, 0.2))
		var n := int(w / 0.3)
		for i in n:
			if (i * 7 + j * 3) % 5 == 4:
				continue
			var c: Color = items[(i + j) % items.size()]
			var hh := 0.12 + 0.1 * ((i + j * 2) % 3)
			k.box(Vector3(0.24, hh, 0.3), c, base * at(-w * 0.5 + 0.15 + i * 0.3, y + 0.015 + hh * 0.5, 0.2))


## A low hedge / bush row from a to b.
static func hedge(k: MeshKit, a: Vector3, b: Vector3, h := 0.5, col := Color(0.38, 0.56, 0.32)) -> void:
	var n := maxi(1, int(a.distance_to(b) / 0.45))
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		k.sphere(h * 0.6, col.darkened((i % 3) * 0.05), xf(Vector3(q.x, q.y + h * 0.5, q.z), Vector3.ZERO, Vector3(1.1, 0.9, 1.0)), 7, 4)


## A parasol over a small round table with two chairs.
static func cafe_set(k: MeshKit, p: Vector3, col: Color) -> void:
	k.cyl(0.3, 0.03, Color(0.95, 0.95, 0.95), at(p.x, p.y + 0.72, p.z), 10)
	k.cyl(0.03, 0.72, Color(0.6, 0.62, 0.64), at(p.x, p.y, p.z), 5)
	k.cyl(0.025, 2.1, Color(0.6, 0.62, 0.64), at(p.x, p.y, p.z), 5)
	k.cone(0.85, 0.35, col, at(p.x, p.y + 1.85, p.z), 8)
	for i in 2:
		chair(k, xf(Vector3(p.x + (i * 2 - 1) * 0.5, p.y, p.z), Vector3(0, 90 if i == 0 else -90, 0)), Color(0.95, 0.95, 0.95))


# ---------------------------------------------------------------- API Gateway (4 x 6 m)
# Anchors: the fiber rack at z = 1.15 (spools sit on y = 0.61, x -1.45..0.6;
# see ChannelB._show_spools), the packet dish (intake), roof slots at
# (0.3, -1.4), (0.6, -1.0), (-1.4, -1.0); the front 1.3 m stays walkable.

static func gateway(t: int) -> Mesh:
	var k := MeshKit.new()
	ArchKit.lot(k, 3.9, 5.9, t)
	match clampi(t, 0, 4):
		0: _gw0(k)
		1: _gw1(k)
		2: _gw2(k)
		3: _gw3(k)
		_: _gw4(k)
	match clampi(t, 0, 4):
		0: _gw0x(k)
		1:
			_gw1x(k)
			_gw1y(k)
		2:
			_gw2x(k)
			_gw2y(k)
		3:
			_gw3x(k)
			_gw3y(k)
		_:
			_gw4x(k)
			_gw4y(k)
	_life(k, "gateway", clampi(t, 0, 4))
	_finish(k, "gateway", clampi(t, 0, 4))
	return k.commit()


## The fiber rack the spools sit on (top at y = 0.61).
static func _gw_rack(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var z := 1.15
	match t:
		0:
			# a plank on two sawhorses
			k.box(Vector3(2.3, 0.05, 0.42), Pal.WOOD_LIGHT, at(-0.45, 0.585, z))
			for x in [-1.4, 0.5]:
				k.box(Vector3(0.08, 0.06, 0.5), Pal.WOOD, at(x, 0.53, z))
				for sz in [-1.0, 1.0]:
					for sx in [-1.0, 1.0]:
						beam(k, Vector3(x + sx * 0.04, 0.53, z + sz * 0.05), Vector3(x + sx * 0.12, 0.1, z + sz * 0.22), 0.05, Pal.WOOD_DARK)
		1:
			# steel pallet racking: blue frames, orange beams, mesh deck
			for x in [-1.62, 0.72]:
				for sz in [-1.0, 1.0]:
					k.box(Vector3(0.07, 1.55, 0.07), Color(0.2, 0.36, 0.66), at(x, 0.875, z + sz * 0.24))
				for y in [0.3, 0.9, 1.4]:
					k.box(Vector3(0.04, 0.04, 0.5), Color(0.2, 0.36, 0.66), at(x, y, z))
			for y in [0.56, 1.48]:
				for sz in [-1.0, 1.0]:
					k.box(Vector3(2.34, 0.08, 0.05), Color(0.94, 0.5, 0.16), at(-0.45, y, z + sz * 0.24))
			k.box(Vector3(2.3, 0.02, 0.5), Color(0.55, 0.57, 0.6), at(-0.45, 0.6, z))
			for i in 8:
				k.box(Vector3(0.02, 0.025, 0.5), Color(0.45, 0.47, 0.5), at(-1.55 + i * 0.3, 0.615, z))
		2:
			# a white fiber bench with a teal glow
			k.box(Vector3(2.4, 0.08, 0.56), Color(0.96, 0.96, 0.97), at(-0.45, 0.57, z))
			k.box(Vector3(2.3, 0.45, 0.4), p["wall2"], at(-0.45, 0.3, z - 0.02))
			k.box(Vector3(2.32, 0.03, 0.02), lit(p["glow"], 0.4), at(-0.45, 0.48, z + 0.19))
			for i in 5:
				k.box(Vector3(0.36, 0.3, 0.02), p["wall"], at(-1.35 + i * 0.45, 0.28, z + 0.19))
		3:
			# heavy steel rack with yellow guards and blue LEDs
			for x in [-1.62, 0.72]:
				k.box(Vector3(0.12, 1.6, 0.6), p["trim"], at(x, 0.9, z))
				k.box(Vector3(0.02, 1.4, 0.03), lit(p["accent2"], 0.4), at(x, 0.9, z + 0.31))
			k.box(Vector3(2.34, 0.1, 0.6), p["metal"], at(-0.45, 0.56, z))
			k.box(Vector3(2.34, 0.1, 0.6), p["metal"], at(-0.45, 1.65, z))
			k.box(Vector3(2.3, 0.02, 0.03), lit(p["glow"], 0.4), at(-0.45, 1.58, z + 0.29))
			for x in [-1.75, 0.85]:
				bollard(k, Vector3(x, 0.1, z + 0.45), p["accent"], 0.7)
		_:
			# graphite cradle with brass rails and an underglow
			k.box(Vector3(2.5, 0.1, 0.6), p["wall"], at(-0.45, 0.56, z))
			k.box(Vector3(2.52, 0.03, 0.62), p["trim"], at(-0.45, 0.61, z))
			for x in [-1.62, 0.72]:
				k.box(Vector3(0.14, 0.5, 0.5), p["wall2"], at(x, 0.3, z))
				k.box(Vector3(0.16, 0.03, 0.52), p["trim"], at(x, 0.08, z))
			k.box(Vector3(2.2, 0.02, 0.4), lit(p["accent2"], 0.4), at(-0.45, 0.12, z))
			for x in [-1.62, 0.72]:
				k.box(Vector3(0.05, 1.7, 0.05), p["trim"], at(x, 1.3, z - 0.28))
			k.box(Vector3(2.4, 0.05, 0.05), p["trim"], at(-0.45, 2.15, z - 0.28))


## Garage: a tin shed with a router on a shelf, a TV aerial, a hand-painted sign.
static func _gw0(k: MeshKit) -> void:
	var t := 0
	var tin := Color(0.68, 0.7, 0.72)
	var rust := Color(0.6, 0.4, 0.28)
	var ply := Color(0.8, 0.66, 0.46)
	var x0 := -1.8
	var x1 := 1.0
	var zb := -2.8
	var zf := -0.6
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var d := zf - zb
	# floor boards and a concrete step
	k.box(Vector3(w, 0.06, d), Color(0.56, 0.5, 0.42), at(cx, 0.13, (zb + zf) * 0.5))
	k.box(Vector3(1.6, 0.12, 0.4), Color(0.66, 0.64, 0.6), at(-0.25, 0.16, zf + 0.2))
	# corrugated walls: back, sides; a rusty patch
	ArchKit.corrugated(k, xf(Vector3(cx, 0.1, zb), Vector3(0, 180, 0)), w, 1.95, tin)
	ArchKit.corrugated(k, xf(Vector3(x0, 0.1, (zb + zf) * 0.5), Vector3(0, -90, 0)), d, 2.05, tin)
	ArchKit.corrugated(k, xf(Vector3(x1, 0.1, (zb + zf) * 0.5), Vector3(0, 90, 0)), d, 2.05, tin)
	k.box(Vector3(0.05, 0.8, 0.9), rust, at(x1 + 0.06, 0.8, -1.4))
	k.box(Vector3(0.05, 0.6, 0.6), rust.darkened(0.1), at(x0 - 0.06, 1.4, -2.2))
	# front: plywood either side of a wide opening, a lintel
	ArchKit.planks(k, at(-1.4, 0.1, zf), 0.8, 2.1, ply)
	ArchKit.planks(k, at(0.75, 0.1, zf), 0.5, 2.1, ply)
	k.box(Vector3(1.7, 0.4, 0.05), ply.darkened(0.08), at(-0.3, 1.95, zf + 0.02))
	for x in [-1.0, 0.5]:
		k.box(Vector3(0.1, 2.1, 0.1), Pal.WOOD_DARK, at(x, 1.15, zf + 0.03))
	# the roof: a tin sheet with an overhang, a tarp and tyres holding it
	tin_roof(k, Vector3(cx, 2.2, (zb + zf) * 0.5 + 0.12), w + 0.18, d + 0.25, tin, -3.0)
	k.box(Vector3(1.1, 0.04, 0.9), Color(0.26, 0.46, 0.78), xf(Vector3(-0.3, 2.3, -2.25), Vector3(-3, 6, 0)))
	k.torus(0.2, 0.07, Color(0.16, 0.16, 0.17), at(-0.6, 2.34, -2.3), 10, 4)
	k.torus(0.2, 0.07, Color(0.16, 0.16, 0.17), at(0.1, 2.33, -2.1), 10, 4)
	for i in 3:
		k.box(Vector3(0.22, 0.08, 0.1), Pal.BRICK, at(x0 + 0.2 + i * 1.1, 2.3, zb + 0.05))
	# inside: a shelf unit on the back wall with the router, a modem, cables
	var sz := zb + 0.25
	for x in [-0.95, 0.45]:
		k.box(Vector3(0.05, 1.7, 0.36), Pal.WOOD, at(x, 0.95, sz))
	for y in [0.55, 1.05, 1.5]:
		k.box(Vector3(1.45, 0.04, 0.38), Pal.WOOD_LIGHT, at(-0.25, y, sz))
	# the router: a black box with antennas and blinking lights
	k.box(Vector3(0.38, 0.07, 0.22), Color(0.12, 0.12, 0.14), at(-0.4, 1.11, sz + 0.02))
	for i in 4:
		beam(k, Vector3(-0.55 + i * 0.1, 1.14, sz - 0.06), Vector3(-0.58 + i * 0.12, 1.4, sz - 0.1), 0.015, Color(0.12, 0.12, 0.14))
		k.box(Vector3(0.025, 0.015, 0.01), lit(Color(0.5, 1.0, 0.6) if i % 2 == 0 else Color(1.0, 0.7, 0.3), 0.3), at(-0.52 + i * 0.07, 1.11, sz + 0.135))
	k.box(Vector3(0.22, 0.2, 0.16), Color(0.92, 0.92, 0.9), at(0.1, 1.17, sz))
	k.box(Vector3(0.12, 0.015, 0.01), lit(Color(0.5, 1.0, 0.6), 0.3), at(0.1, 1.22, sz + 0.085))
	# an old monitor and a desk fan on the lower shelf, cables hanging
	k.box(Vector3(0.36, 0.3, 0.3), Color(0.82, 0.8, 0.74), at(-0.6, 0.72, sz))
	k.box(Vector3(0.28, 0.22, 0.01), lit(Color(0.5, 0.9, 0.7), 0.5), at(-0.6, 0.73, sz + 0.155))
	k.cyl(0.13, 0.03, Color(0.3, 0.5, 0.75), xf(Vector3(0.15, 0.8, sz + 0.05), Vector3(80, 0, 0)), 8)
	k.box(Vector3(0.04, 0.2, 0.04), Color(0.3, 0.5, 0.75), at(0.15, 0.67, sz))
	for i in 5:
		var cc: Color = [Color(0.2, 0.4, 0.8), Color(0.95, 0.75, 0.2), Color(0.9, 0.3, 0.3), Color(0.2, 0.2, 0.2), Color(0.95, 0.95, 0.95)][i]
		cable(k, Vector3(-0.5 + i * 0.12, 1.08, sz + 0.1), Vector3(-0.3 + i * 0.1, 0.57, sz + 0.12), 0.12, cc, 0.015, 3)
	# boxes on the top shelf, a power strip
	crate(k, at(-0.75, 1.52, sz), 0.26, Color(0.78, 0.66, 0.46))
	crate(k, at(0.2, 1.52, sz), 0.3, Color(0.7, 0.58, 0.4))
	k.box(Vector3(0.4, 0.04, 0.06), Color(0.94, 0.94, 0.92), at(-0.25, 0.6, sz + 0.12))
	# a plastic chair and a crate desk inside the opening
	chair(k, xf(Vector3(-0.2, 0.15, -1.6), Vector3(0, 160, 0)), Color(0.94, 0.94, 0.92))
	# the hand-painted API sign over the opening
	k.box(Vector3(1.3, 0.42, 0.04), Color(0.95, 0.93, 0.86), xf(Vector3(-0.3, 1.92, zf + 0.06), Vector3(0, 0, -2)))
	text(k, "API", xf(Vector3(-0.3, 1.77, zf + 0.08), Vector3(0, 0, -2)), 0.06, Color(0.85, 0.24, 0.2))
	k.box(Vector3(0.3, 0.04, 0.01), Color(0.26, 0.46, 0.78), xf(Vector3(0.18, 1.75, zf + 0.09), Vector3(0, 0, 20)))
	# string lights along the eave
	ArchKit.string_lights(k, Vector3(x0, 2.12, zf + 0.25), Vector3(x1, 2.12, zf + 0.25), 9)
	# the TV aerial: a pole strapped to the shed, a fishbone on top
	var ap := Vector3(1.45, 0.1, -2.45)
	k.cyl(0.04, 3.55, Color(0.66, 0.68, 0.7), at(ap.x, ap.y, ap.z), 6)
	for y in [0.8, 1.7]:
		k.box(Vector3(0.5, 0.05, 0.05), Color(0.6, 0.62, 0.64), at(ap.x - 0.24, y, ap.z))
	yagi(k, xf(Vector3(ap.x, 3.55, ap.z - 0.4), Vector3(0, 20, 0)), 1.0, Color(0.82, 0.84, 0.86), 9)
	k.box(Vector3(0.5, 0.02, 0.02), Color(0.82, 0.84, 0.86), at(ap.x, 3.3, ap.z))
	for i in 4:
		beam(k, Vector3(ap.x, 3.3, ap.z), Vector3(ap.x + (i - 1.5) * 0.12, 3.05, ap.z + 0.3), 0.015, Color(0.82, 0.84, 0.86))
	cable(k, Vector3(ap.x, 3.0, ap.z), Vector3(x1, 1.8, -1.2), 0.3, Color(0.2, 0.2, 0.22), 0.02)
	# extension cords snaking out to the rack and a work light
	var ext := Color(0.95, 0.5, 0.15)
	ArchKit.pipes(k, [Vector3(-0.9, 0.13, zf + 0.1), Vector3(-1.1, 0.12, 0.2), Vector3(-0.6, 0.12, 0.7), Vector3(-0.2, 0.12, 0.9)], 0.018, ext)
	ArchKit.pipes(k, [Vector3(0.6, 0.13, zf + 0.1), Vector3(1.2, 0.12, -0.2), Vector3(1.35, 0.12, 0.3)], 0.018, ext)
	_gw_rack(k, t)
	# a folding table with a laptop and a mug, a cable drum, a jerry can
	table(k, at(1.35, 0.1, 0.25), 0.8, 0.55, Color(0.9, 0.9, 0.88), Color(0.4, 0.42, 0.45))
	laptop(k, xf(Vector3(1.3, 0.84, 0.25), Vector3(0, 200, 0)))
	k.cyl(0.04, 0.09, Color(0.85, 0.3, 0.25), at(1.6, 0.84, 0.4), 6)
	k.cyl(0.32, 0.04, Pal.WOOD, xf(Vector3(1.45, 0.42, -0.95), Vector3(0, 0, 90)), 10)
	k.cyl(0.32, 0.04, Pal.WOOD, xf(Vector3(1.8, 0.42, -0.95), Vector3(0, 0, 90)), 10)
	k.cyl(0.2, 0.32, Color(0.25, 0.25, 0.27), xf(Vector3(1.8, 0.42, -0.95), Vector3(0, 0, 90)), 10)
	k.box(Vector3(0.25, 0.35, 0.14), Color(0.8, 0.22, 0.2), at(1.75, 0.28, -0.4))
	crate(k, xf(Vector3(1.4, 0.1, -0.3), Vector3(0, 12, 0)), 0.36)
	# stepping stones to the door
	for i in 3:
		k.box(Vector3(0.36, 0.03, 0.26), Color(0.66, 0.64, 0.6), xf(Vector3(-0.1 + (i % 2) * 0.1, 0.11, 0.05 + i * 0.55), Vector3(0, i * 17.0, 0)))


## Workshop: a network container with patch panels, cable trays, a yagi mast.
static func _gw1(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var cc := Color(0.24, 0.44, 0.64)
	var y0 := 0.25
	var cx := -0.32
	var len := 3.05
	var cz := -1.75
	# concrete blocks under the container
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.3, 0.15, 0.3), Color(0.62, 0.62, 0.6), at(cx + sx * (len * 0.5 - 0.2), 0.17, cz + sz * 0.9))
	container(k, at(cx, y0, cz), len, cc, 2.5, 2.2)
	var top := y0 + 2.5
	k.box(Vector3(len - 0.1, 0.02, 2.1), cc.darkened(0.1), at(cx, top + 0.01, cz))
	# the open roll-up door: patch panels inside
	var fz := cz + 1.1
	k.box(Vector3(1.7, 2.0, 0.04), Color(0.12, 0.13, 0.15), at(-0.65, y0 + 1.05, fz + 0.02))
	ArchKit.rollup(k, at(-0.65, y0 + 0.05, fz + 0.04), 1.7, 2.0, p["wall"], 0.75)
	for i in 3:
		var x := -1.2 + i * 0.55
		k.box(Vector3(0.48, 1.45, 0.05), Color(0.18, 0.19, 0.22), at(x, y0 + 0.78, fz + 0.06))
		for j in 7:
			var y := y0 + 0.2 + j * 0.2
			k.box(Vector3(0.4, 0.05, 0.02), Color(0.3, 0.31, 0.34), at(x, y, fz + 0.09))
			for q in 5:
				k.box(Vector3(0.03, 0.025, 0.01), [Color(0.3, 0.6, 0.95), Color(0.95, 0.8, 0.3), Color(0.4, 0.85, 0.5)][(i + j + q) % 3], at(x - 0.16 + q * 0.08, y, fz + 0.105))
			if j % 3 == 1:
				k.box(Vector3(0.3, 0.012, 0.01), lit(p["glow"], 0.3), at(x, y + 0.06, fz + 0.1))
		# looped patch cables
		cable(k, Vector3(x - 0.18, y0 + 1.3, fz + 0.12), Vector3(x + 0.18, y0 + 1.25, fz + 0.12), 0.25, [Color(0.3, 0.6, 0.95), Color(0.95, 0.8, 0.3), Color(0.9, 0.35, 0.3)][i], 0.02, 4)
	# a steel side door and a split AC unit bolted on
	ArchKit.door(k, at(0.85, y0, fz + 0.02), t, 0.7, 1.9)
	k.box(Vector3(0.8, 0.3, 0.22), Color(0.92, 0.92, 0.92), at(0.85, y0 + 2.3, fz + 0.12))
	k.box(Vector3(0.7, 0.03, 0.02), Color(0.6, 0.62, 0.64), at(0.85, y0 + 2.18, fz + 0.24))
	ArchKit.ac_unit(k, xf(Vector3(1.0, 0.1, -0.35), Vector3(0, 0, 0)), t, 0.8)
	ArchKit.pipes(k, [Vector3(0.85, y0 + 2.2, fz + 0.15), Vector3(1.0, y0 + 2.2, fz + 0.3), Vector3(1.0, 0.6, fz + 0.3)], 0.025, Color(0.95, 0.95, 0.95))
	# the yellow sign
	k.box(Vector3(1.0, 0.36, 0.04), p["accent"], at(-1.4, y0 + 2.27, fz + 0.04))
	text(k, "API", at(-1.4, y0 + 2.15, fz + 0.06), 0.05, p["dark"])
	# hazard stripes along the container sill
	for i in 10:
		k.box(Vector3(0.14, 0.08, 0.02), p["accent"] if i % 2 == 0 else p["dark"], at(cx - 1.4 + i * 0.3, y0 + 0.1, fz + 0.03))
	# roof: AC units, a cable tray to the mast, a yellow guard rail
	ArchKit.ac_unit(k, at(-1.3, top, -2.4), t, 0.75)
	ArchKit.ac_unit(k, at(-0.3, top, -2.4), t, 0.75)
	ArchKit.cable_tray(k, Vector3(-1.8, top + 0.2, -2.0), Vector3(1.4, top + 0.2, -2.0), t)
	ArchKit.railing(k, Vector3(cx - len * 0.5 + 0.05, top, -2.8), Vector3(cx + len * 0.5 - 0.05, top, -2.8), 0.9, p["accent"])
	ArchKit.railing(k, Vector3(cx + len * 0.5 - 0.05, top, -2.8), Vector3(cx + len * 0.5 - 0.05, top, -1.75), 0.9, p["accent"])
	# a caged ladder up the right end
	ArchKit.ladder(k, xf(Vector3(cx + len * 0.5 + 0.13, 0.1, -1.1), Vector3(0, -90, 0)), top, p["accent"], true)
	# the yagi mast: a guyed steel pole, a yagi and a little grid dish
	var mp := Vector3(1.5, 0.1, -2.5)
	k.box(Vector3(0.4, 0.15, 0.4), Color(0.62, 0.62, 0.6), at(mp.x, 0.18, mp.z))
	k.cyl(0.06, 5.1, p["metal"], at(mp.x, 0.2, mp.z), 8)
	for y in [1.5, 3.0, 4.5]:
		k.box(Vector3(0.18, 0.08, 0.18), p["metal"].darkened(0.2), at(mp.x, y, mp.z))
	for g in [Vector3(1.9, 0.1, -0.6), Vector3(-0.5, top, -2.85), Vector3(1.9, 0.1, -2.9)]:
		beam(k, Vector3(mp.x, 4.0, mp.z), g, 0.012, Color(0.3, 0.3, 0.32))
	yagi(k, xf(Vector3(mp.x, 5.2, mp.z - 0.3), Vector3(0, 10, 0)), 1.3, Color(0.86, 0.88, 0.9), 10)
	yagi(k, xf(Vector3(mp.x, 4.6, mp.z + 0.3), Vector3(0, -80, 0)), 0.9, Color(0.86, 0.88, 0.9), 7)
	sat_dish(k, at(mp.x - 0.25, 3.6, mp.z + 0.2), 0.32, t, 70.0, 30.0, 0.0, Color(0.85, 0.86, 0.88))
	k.box(Vector3(0.2, 0.3, 0.15), Color(0.85, 0.86, 0.88), at(mp.x + 0.12, 2.4, mp.z + 0.1))
	ArchKit.beacon(k, Vector3(mp.x, 5.3, mp.z), 0.2)
	# the cable tray from the container down to the fiber rack
	ArchKit.cable_tray(k, Vector3(-1.75, 2.4, fz + 0.05), Vector3(-1.75, 2.4, 0.95), t)
	k.box(Vector3(0.08, 2.3, 0.08), p["trim"], at(-1.75, 1.25, 0.95))
	ArchKit.pipes(k, [Vector3(-1.75, 2.4, 0.95), Vector3(-1.6, 1.6, 1.15), Vector3(-1.3, 1.5, 1.15)], 0.03, Color(0.98, 0.64, 0.86))
	_gw_rack(k, t)
	# chain-link along the right edge, a floodlight, a pallet jack, cones
	ArchKit.fence(k, Vector3(1.88, 0.1, -0.7), Vector3(1.88, 0.1, 1.0), t, 1.4)
	ArchKit.lamp(k, Vector3(1.5, 0.1, 0.9), t, 2.8)
	k.box(Vector3(0.5, 0.06, 0.9), Color(0.85, 0.2, 0.18), at(1.05, 0.15, 0.55))
	k.box(Vector3(0.08, 0.9, 0.08), Color(0.85, 0.2, 0.18), xf(Vector3(1.05, 0.55, 0.05), Vector3(-15, 0, 0)))
	cone(k, Vector3(0.95, 0.1, 1.5))
	cone(k, Vector3(-1.2, 0.1, 0.1))
	k.box(Vector3(0.5, 0.7, 0.3), Color(0.6, 0.62, 0.64), at(0.3, 0.45, -0.4))
	k.box(Vector3(0.3, 0.04, 0.01), lit(p["glow"], 0.3), at(0.3, 0.6, -0.245))
	ArchKit.pipes(k, [Vector3(0.3, 0.8, -0.4), Vector3(0.3, 1.2, -0.55)], 0.03, Color(0.2, 0.2, 0.22))


## Campus: a glass NOC kiosk with a wall of screens, a dish, planters.
static func _gw2(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var zb := -2.85
	var zm := -1.75
	var zf := -0.6
	var h1 := 2.8
	# the back block: two white storeys; its front is the NOC's wall of screens
	var hb := 4.9
	k.rbox(Vector3(3.64, hb, zm - zb), 0.04, p["wall"], at(0, 0.1 + hb * 0.5, (zb + zm) * 0.5), 1)
	for r in 3:
		for c in 5:
			screen(k, at(-1.36 + c * 0.68, 0.85 + r * 0.6, zm), 0.62, 0.5, p["dark"], [Color(0.4, 0.9, 1.0), Color(0.5, 1.0, 0.7), Color(1.0, 0.8, 0.5)][(r * 2 + c) % 3], r * 5 + c)
	k.box(Vector3(3.5, 0.12, 0.2), p["dark"], at(0, 0.45, zm + 0.1))
	# the glass room in front: floor, slim side walls, mullions only (so you see in)
	k.box(Vector3(3.7, 0.08, zf - zm), p["floor"].lightened(0.05), at(0, 0.14, (zm + zf) * 0.5))
	for sx in [-1.0, 1.0]:
		ArchKit.curtain(k, xf(Vector3(sx * 1.8, 0.1, (zm + zf) * 0.5), Vector3(0, sx * 90.0, 0)), zf - zm, h1, t, 2, 3)
	for i in 8:
		k.box(Vector3(0.05, h1, 0.06), p["frame"], at(-1.75 + i * 0.5, 0.1 + h1 * 0.5, zf))
	k.box(Vector3(3.7, 0.06, 0.08), p["frame"], at(0, 0.18, zf))
	k.box(Vector3(3.7, 0.05, 0.06), p["frame"], at(0, 1.2, zf))
	# operators' desks, monitors, chairs
	for i in 3:
		var x := -1.15 + i * 1.15
		k.box(Vector3(0.95, 0.05, 0.45), Color(0.96, 0.96, 0.97), at(x, 0.82, -1.25))
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.04, 0.68, 0.4), p["wall2"], at(x + sx * 0.43, 0.48, -1.25))
		for j in 2:
			k.box(Vector3(0.32, 0.2, 0.02), p["dark"], xf(Vector3(x - 0.18 + j * 0.36, 1.0, -1.38), Vector3(-10, 0, 0)))
			k.box(Vector3(0.28, 0.16, 0.01), lit(Color(0.4, 0.9, 1.0), 0.4), xf(Vector3(x - 0.18 + j * 0.36, 1.0, -1.365), Vector3(-10, 0, 0)))
		chair(k, xf(Vector3(x, 0.15, -0.9), Vector3(0, 180, 0)), p["accent"])
	# the glass room's roof: a thin slab with a teal fascia (roof gear goes here)
	var rt := 0.1 + h1
	k.box(Vector3(3.78, 0.16, zf - zm + 0.3), p["wall"], at(0, rt + 0.08, (zm + zf) * 0.5 + 0.15))
	k.box(Vector3(3.78, 0.1, 0.04), p["trim"], at(0, rt + 0.06, zf + 0.31))
	k.box(Vector3(3.78, 0.04, 0.04), lit(p["glow"], 0.4), at(0, rt - 0.02, zf + 0.31))
	ArchKit.railing(k, Vector3(-1.85, rt + 0.16, zf + 0.25), Vector3(1.85, rt + 0.16, zf + 0.25), 0.5, p["frame"], 0.6)
	# the back block's upper face: strip windows and the logo
	ArchKit.window_row(k, at(0, rt + 1.25, zm), 3.4, 0.55, t)
	k.box(Vector3(3.66, 0.14, 0.04), p["trim"], at(0, rt + 0.5, zm + 0.01))
	k.box(Vector3(1.3, 0.5, 0.06), p["accent"], at(-1.1, rt + 1.85, zm + 0.03))
	text(k, "API", at(-1.1, rt + 1.7, zm + 0.07), 0.06, Color(0.98, 0.98, 0.98))
	for sx in [-1.0, 1.0]:
		ArchKit.window_row(k, xf(Vector3(sx * 1.82, rt + 1.25, (zb + zm) * 0.5), Vector3(0, sx * 90.0, 0)), 0.8, 0.5, t)
	var top := 0.1 + hb
	ArchKit.parapet(k, Vector3(0, top, (zb + zm) * 0.5), 3.64, zm - zb, t)
	# on top: the satellite dish, screened plant, a mast
	k.box(Vector3(0.9, 0.22, 0.9), p["wall2"], at(-0.8, top + 0.11, -2.3))
	sat_dish(k, at(-0.8, top + 0.22, -2.3), 0.9, t, 35.0, 10.0, 0.5)
	ArchKit.louvres(k, at(0.95, top, -1.85), 1.5, 0.75, p["wall2"], 6)
	ArchKit.ac_unit(k, at(0.95, top, -2.35), t, 0.7)
	k.cyl(0.03, 1.4, p["metal"], at(1.7, top, -2.7), 5)
	ArchKit.beacon(k, Vector3(1.7, top + 1.4, -2.7), 0.15)
	# the logo pylon at the front corner
	k.box(Vector3(0.45, 3.3, 0.3), p["accent"], at(1.62, 0.1 + 1.65, -0.35))
	text(k, "API", xf(Vector3(1.62, 2.4, -0.19), Vector3(0, 0, 90)), 0.07, Color(0.98, 0.98, 0.98))
	k.box(Vector3(0.47, 0.04, 0.32), lit(p["glow"], 0.4), at(1.62, 3.42, -0.35))
	# the front: planters with a tree, a bench, mat, a lamp
	ArchKit.planter(k, Vector3(1.45, 0.1, 0.55), t, 0.7, true)
	ArchKit.planter(k, Vector3(-1.45, 0.1, -0.25), t, 0.7, false)
	k.box(Vector3(0.8, 0.06, 0.32), Pal.WOOD_LIGHT, at(0.85, 0.5, -0.3))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 0.4, 0.28), p["wall2"], at(0.85 + sx * 0.34, 0.3, -0.3))
	k.box(Vector3(1.1, 0.02, 0.5), p["dark"], at(0, 0.11, zf + 0.3))
	_gw_rack(k, t)
	k.box(Vector3(0.5, 1.1, 0.4), p["wall"], at(1.05, 0.65, 1.2))
	k.box(Vector3(0.4, 0.03, 0.01), lit(p["glow"], 0.4), at(1.05, 1.0, 1.405))
	for i in 3:
		ArchKit.pipes(k, [Vector3(-1.2 + i * 0.25, 0.6, 1.0), Vector3(-1.2 + i * 0.25, 0.14, 0.75), Vector3(-1.2 + i * 0.25, 0.14, zf + 0.1)], 0.03, Color(0.98, 0.64, 0.86))
	ArchKit.lamp(k, Vector3(-1.75, 0.1, 1.0), t, 2.6)


## Industrial: a steel network hall, a lattice mast with microwave dishes,
## cable ladders and a load-balancer tower.
static func _gw3(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var x0 := -1.8
	var x1 := 1.0
	var zb := -2.85
	var zf := -0.55
	var h := 3.7
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var d := zf - zb
	# the hall: dark steel cladding, a glass clerestory, blue LEDs, louvres
	k.box(Vector3(w, h, d), p["wall"], at(cx, 0.1 + h * 0.5, (zb + zf) * 0.5))
	ArchKit.corrugated(k, at(cx, 0.1, zf), w, 2.3, p["wall2"], 0.14)
	ArchKit.curtain(k, at(cx, 2.45, zf + 0.01), w - 0.2, 0.9, t, 6, 1)
	k.box(Vector3(w + 0.04, 0.06, 0.06), lit(p["glow"], 0.4), at(cx, 3.42, zf + 0.04))
	for sx in [-1.0, 1.0]:
		ArchKit.corrugated(k, xf(Vector3(x1 if sx > 0 else x0, 0.1, (zb + zf) * 0.5), Vector3(0, sx * 90.0, 0)), d, h, p["wall2"], 0.14)
	# a roll-up door half open on racks with blue LEDs
	k.box(Vector3(1.4, 2.0, 0.04), Color(0.08, 0.09, 0.11), at(-0.7, 1.1, zf + 0.04))
	for i in 3:
		rack(k, at(-1.15 + i * 0.45, 0.12, zf - 0.32), 1.7, p["dark"], p["glow"], 0.4, 0.5, 7)
	ArchKit.rollup(k, at(-0.7, 0.1, zf + 0.05), 1.4, 2.0, p["metal"], 0.55)
	ArchKit.door(k, at(0.45, 0.1, zf + 0.02), t, 0.7, 1.9)
	ArchKit.louvres(k, at(0.45, 2.45, zf + 0.04), 0.8, 0.7, p["metal"], 6)
	# the sign
	ArchKit.sign(k, at(-0.7, 3.5, zf + 0.06), 1.6, 0.36, t)
	text(k, "API", at(-0.7, 3.6, zf + 0.16), 0.045, lit(Color(0.7, 0.9, 1.0), 0.35))
	# the roof: parapet, chiller unit, roof hatch
	var top := 0.1 + h
	ArchKit.parapet(k, Vector3(cx, top, (zb + zf) * 0.5), w, d, t)
	ArchKit.ac_unit(k, at(-1.2, top, -2.35), t, 0.9)
	ArchKit.ac_unit(k, at(-0.2, top, -2.35), t, 0.9)
	# the lattice mast at the back corner
	var mp := Vector3(1.42, 0.1, -2.35)
	k.box(Vector3(1.0, 0.3, 1.0), Color(0.6, 0.6, 0.6), at(mp.x, 0.25, mp.z))
	mast(k, mp + Vector3(0, 0.4, 0), 8.6, 0.8, 0.32, Color(0.84, 0.86, 0.88), 0.8, 0.05, Color(0.86, 0.3, 0.26))
	for y in [4.6, 7.4]:
		k.box(Vector3(1.0, 0.05, 1.0), p["metal"].darkened(0.2), at(mp.x, y, mp.z))
		ArchKit.railing(k, Vector3(mp.x - 0.48, y, mp.z + 0.48), Vector3(mp.x + 0.48, y, mp.z + 0.48), 0.6, p["accent"], 0.5)
	# microwave drums all round, sector panels on top
	drum(k, xf(Vector3(mp.x, 5.2, mp.z + 0.35), Vector3(0, 0, 0)), 0.32)
	drum(k, xf(Vector3(mp.x - 0.35, 6.2, mp.z), Vector3(0, -70, 0)), 0.28)
	drum(k, xf(Vector3(mp.x, 3.6, mp.z + 0.4), Vector3(0, 30, 0)), 0.24)
	drum(k, xf(Vector3(mp.x + 0.35, 6.6, mp.z + 0.1), Vector3(0, 80, 0)), 0.26)
	for i in 3:
		var a := TAU * i / 3.0
		panel_ant(k, xf(Vector3(mp.x + sin(a) * 0.3, 8.3, mp.z + cos(a) * 0.3), Vector3(0, rad_to_deg(a), 0)), 0.9)
	k.cyl(0.03, 0.9, p["metal"], at(mp.x, 9.0, mp.z), 5)
	ArchKit.beacon(k, Vector3(mp.x, 9.2, mp.z), 0.2)
	ArchKit.beacon(k, Vector3(mp.x + 0.4, 7.4, mp.z + 0.4), 0.2)
	# cable ladders: down the mast, across to the hall roof
	cable_ladder(k, Vector3(mp.x - 0.35, 4.5, mp.z + 0.3), Vector3(x1 - 0.1, top + 0.4, -2.0), 0.3, p["metal"], Color(0.15, 0.15, 0.17))
	cable_ladder(k, Vector3(x1 - 0.1, top + 0.4, -2.0), Vector3(-1.6, top + 0.4, -2.0), 0.3, p["metal"], Color(0.15, 0.15, 0.17))
	for x in [-1.2, -0.2, 0.7]:
		k.box(Vector3(0.05, 0.4, 0.05), p["trim"], at(x, top + 0.2, -2.0))
	# the load-balancer tower: a stack of glowing tiers by the door
	var lb := Vector3(1.45, 0.1, -0.15)
	k.box(Vector3(0.9, 0.2, 0.9), p["dark"], at(lb.x, 0.2, lb.z))
	for i in 9:
		var y := 0.35 + i * 0.5
		var s := 0.7 - i * 0.025
		k.box(Vector3(s, 0.4, s), p["dark"] if i % 2 == 0 else p["wall2"], at(lb.x, y + 0.2, lb.z))
		k.box(Vector3(s + 0.02, 0.04, s + 0.02), lit(p["glow"] if i % 3 else p["accent2"], 0.35), at(lb.x, y + 0.42, lb.z))
		for j in 3:
			k.box(Vector3(0.12, 0.03, 0.01), lit(Color(0.5, 1.0, 0.7), 0.3), at(lb.x - 0.18 + j * 0.18, y + 0.2, lb.z + s * 0.5 + 0.005))
	k.box(Vector3(0.5, 0.15, 0.5), p["metal"], at(lb.x, 4.95, lb.z))
	k.cyl(0.03, 0.8, p["metal"], at(lb.x, 5.0, lb.z), 5)
	k.sphere(0.08, lit(p["glow"], 0.3), at(lb.x, 5.85, lb.z), 6, 4)
	cable_ladder(k, Vector3(lb.x - 0.35, 3.8, lb.z), Vector3(x1 + 0.05, 3.4, -0.62), 0.25, p["metal"], Color(0.15, 0.15, 0.17))
	_gw_rack(k, t)
	# fiber conduits, a pipe along the wall, a transformer box
	for i in 3:
		ArchKit.pipes(k, [Vector3(-1.75, 1.4 - i * 0.2, 1.4), Vector3(-1.75, 1.4 - i * 0.2, zf + 0.1), Vector3(-1.75, 2.2 - i * 0.2, zf + 0.1)], 0.035, Color(0.98, 0.64, 0.86) if i != 1 else lit(Color(0.98, 0.64, 0.86), 0.5))
	ArchKit.pipes(k, [Vector3(x0 + 0.1, 3.0, zf + 0.12), Vector3(x1 - 0.1, 3.0, zf + 0.12)], 0.05, Color(0.36, 0.6, 0.86))
	ArchKit.lamp(k, Vector3(0.95, 0.1, 1.55), t, 2.6)
	for x in [-0.2, 0.3]:
		bollard(k, Vector3(x, 0.1, 0.25), p["accent"], 0.7)


## Hyperscale: a graphite antenna spire with brass rings and glowing fiber trunks.
static func _gw4(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var zb := -2.85
	var zf := -0.65
	var h1 := 2.9
	var g: Color = p["wall"]
	var brass: Color = p["trim"]
	var cyan := lit(p["accent2"], 0.45)
	var pink := lit(Color(0.98, 0.6, 0.86), 0.45)
	# the plinth: graphite with brass seams and glowing fins
	k.box(Vector3(3.8, h1, zf - zb), g, at(0, 0.1 + h1 * 0.5, (zb + zf) * 0.5))
	for y in [0.1, 1.5, h1 + 0.1]:
		k.box(Vector3(3.84, 0.05, zf - zb + 0.04), brass, at(0, y, (zb + zf) * 0.5))
	ArchKit.fins(k, at(-0.5, 0.1, zf), 2.6, h1 - 0.1, 9, t)
	# the entrance: a recessed brass portal
	k.box(Vector3(0.9, 2.1, 0.05), p["dark"], at(1.2, 1.15, zf + 0.03))
	k.box(Vector3(1.0, 0.06, 0.1), brass, at(1.2, 2.23, zf + 0.06))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 2.1, 0.1), brass, at(1.2 + sx * 0.47, 1.15, zf + 0.06))
	k.box(Vector3(0.7, 0.03, 0.02), lit(p["glow"], 0.35), at(1.2, 2.1, zf + 0.1))
	# the upper block: offset and cantilevered forward, a glass band
	var y1 := 0.1 + h1
	var h2 := 2.0
	var uz1 := zf + 0.75
	k.box(Vector3(3.76, h2, uz1 - zb - 0.2), p["wall2"], at(0.02, y1 + h2 * 0.5, (zb + 0.2 + uz1) * 0.5))
	k.box(Vector3(3.2, 0.6, 0.04), p["glass"], at(0.15, y1 + 1.1, uz1 + 0.01))
	for i in 9:
		k.box(Vector3(0.05, 0.7, 0.08), brass, at(-1.45 + i * 0.4, y1 + 1.1, uz1 + 0.03))
	k.box(Vector3(3.54, 0.05, 0.05), brass, at(0.15, y1 + 0.02, uz1 + 0.02))
	k.box(Vector3(3.54, 0.05, 0.05), lit(p["glow"], 0.4), at(0.15, y1 + 0.4, uz1 + 0.03))
	var top := y1 + h2
	ArchKit.parapet(k, Vector3(0.02, top, (zb + 0.2 + uz1) * 0.5), 3.76, uz1 - zb - 0.2, t)
	# the spire: four graphite legs closing in, brass rings, a glowing core
	var sp := Vector3(0.2, top, -2.2)
	var sh := 8.6
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		var b0 := sp + Vector3(cos(a) * 0.55, 0, sin(a) * 0.55)
		var b1 := sp + Vector3(cos(a) * 0.12, sh, sin(a) * 0.12)
		beam(k, b0, b1, 0.12, p["wall2"])
		beam(k, b0 + Vector3(0, 0.02, 0), b1, 0.03, brass)
	k.cyl(0.07, sh, cyan, at(sp.x, sp.y, sp.z), 6)
	for i in 6:
		var y := 0.7 + i * 1.3
		var r := lerpf(0.5, 0.15, y / sh) + 0.06
		ring(k, sp + Vector3(0, y, 0), r, 0.035, brass, Vector3.ZERO, 14)
		if i % 2 == 1:
			ring(k, sp + Vector3(0, y + 0.15, 0), r + 0.12, 0.02, lit(p["glow"], 0.35), Vector3.ZERO, 14)
	# phased-array panels on the spire, a crown with an orb
	for i in 3:
		var a2 := TAU * i / 3.0
		var pp := sp + Vector3(sin(a2) * 0.42, 3.0, cos(a2) * 0.42)
		k.box(Vector3(0.36, 1.0, 0.06), p["wall"], xf(pp, Vector3(0, rad_to_deg(a2), 0)))
		k.box(Vector3(0.28, 0.9, 0.02), lit(p["accent2"], 0.55), xf(pp, Vector3(0, rad_to_deg(a2), 0)) * at(0, 0, 0.04))
	for i in 8:
		var a3 := TAU * i / 8.0
		beam(k, sp + Vector3(cos(a3) * 0.2, sh - 0.2, sin(a3) * 0.2), sp + Vector3(cos(a3) * 0.36, sh + 0.5, sin(a3) * 0.36), 0.04, brass)
	ring(k, sp + Vector3(0, sh + 0.3, 0), 0.34, 0.04, brass, Vector3.ZERO, 14)
	k.sphere(0.2, lit(p["glow"], 0.3), at(sp.x, sp.y + sh + 0.45, sp.z), 8, 5)
	ArchKit.beacon(k, sp + Vector3(0, sh + 0.65, 0), 0.4)
	# a drone pad cantilevered off the roof
	ArchKit.drone_pad(k, Vector3(-0.95, top + 0.05, -0.2), 0.48, t)
	drone(k, Vector3(-0.95, top + 0.6, -0.2), t, 20.0)
	ArchKit.beacon(k, Vector3(1.75, top, -0.3), 0.4)
	# glowing fiber trunks: out of the ground, up the façade, into the spire
	for i in 3:
		var x := -1.7 + i * 0.16
		var c := pink if i != 1 else cyan
		ArchKit.pipes(k, [Vector3(x + 0.45, 0.12, 1.4), Vector3(x + 0.45, 0.12, zf + 0.3), Vector3(x, 0.12, zf + 0.15), Vector3(x, top - 0.2, zf + 0.15)], 0.05, c)
		ArchKit.pipes(k, [Vector3(sp.x - 0.5 + i * 0.12, top + 0.05, -2.75), Vector3(sp.x - 0.15 + i * 0.1, top + 0.8, sp.z - 0.2)], 0.045, c)
	for i in 4:
		k.box(Vector3(0.6, 0.06, 0.15), brass, at(-1.55, 0.5 + i * 1.3, zf + 0.15))
	# coolant loop on the side, glowing
	ArchKit.pipes(k, [Vector3(1.85, 0.3, -2.7), Vector3(1.85, 2.6, -2.7), Vector3(1.85, 2.6, -1.0), Vector3(1.85, 0.3, -1.0)], 0.05, lit(p["accent2"], 0.5))
	_gw_rack(k, t)
	# brass bollards, glowing kerb lights
	for x in [-1.75, 1.75]:
		k.cyl(0.08, 0.6, p["wall2"], at(x, 0.1, 2.85 - 0.25), 6)
		k.box(Vector3(0.17, 0.04, 0.17), lit(p["glow"], 0.35), at(x, 0.7, 2.6))
	ArchKit.lamp(k, Vector3(1.5, 0.1, 1.2), t, 2.8)


## A fiber spool (installed in a gateway).
static func spool() -> Mesh:
	var k := MeshKit.new()
	for sz in [-1.0, 1.0]:
		k.cyl(0.16, 0.03, Pal.WOOD, MeshKit.xf(Vector3(0, 0.16, sz * 0.08), Vector3(90, 0, 0)), 12)
	k.cyl(0.12, 0.14, Color(0.98, 0.64, 0.86), MeshKit.xf(Vector3(0, 0.16, 0.07), Vector3(90, 0, 0)), 12)
	return k.commit()


## Gateway detail passes (small believable gear per era).
static func _gw0x(k: MeshKit) -> void:
	var tin := Color(0.68, 0.7, 0.72)
	var rust := Color(0.6, 0.4, 0.28)
	tufts(k, Rect2(-1.8, -0.4, 3.6, 3.2), 26, 1)
	tufts(k, Rect2(1.0, -2.9, 0.9, 2.4), 8, 2)
	# rust streaks on the roof, a gutter and a downpipe, a leaning ladder
	for i in 4:
		k.box(Vector3(0.18, 0.012, 0.5 + i * 0.1), rust, xf(Vector3(-1.5 + i * 0.75, 2.26 - i * 0.0, -1.0 - i * 0.3), Vector3(-3, 0, 0)))
	k.box(Vector3(3.0, 0.08, 0.1), tin.darkened(0.1), at(-0.4, 2.12, -0.3))
	k.box(Vector3(0.07, 2.0, 0.07), tin.darkened(0.1), at(1.15, 1.1, -0.32))
	k.box(Vector3(0.2, 0.05, 0.2), tin.darkened(0.15), at(1.2, 0.13, -0.25))
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(1.2 + sx * 0.18, 0.1, -0.05), Vector3(1.08 + sx * 0.18, 2.3, -0.75), 0.04, Pal.WOOD_LIGHT)
	for i in 7:
		var f := (i + 0.5) / 7.0
		k.box(Vector3(0.36, 0.03, 0.03), Pal.WOOD_LIGHT, at(1.2 - f * 0.12, 0.1 + f * 2.2, -0.05 - f * 0.7))
	# a rain barrel, firewood, a bucket on the roof
	barrel(k, Vector3(1.5, 0.1, -1.7), Color(0.26, 0.42, 0.66), 0.22, 0.65)
	for i in 6:
		k.cyl(0.06, 0.6, Pal.WOOD if i % 2 else Pal.WOOD_DARK, xf(Vector3(1.45 + (i % 3) * 0.13, 0.17 + (i / 3) * 0.12, -2.2), Vector3(90, 0, 0)), 6)
	k.cyl(0.11, 0.18, Color(0.85, 0.75, 0.2), at(0.6, 2.28, -2.4), 8)
	# potted plants and a watering can by the door, a bucket in the yard
	for i in 3:
		k.cyl(0.12, 0.2, Pal.TERRACOTTA, at(-1.65 + i * 0.26, 0.1, -0.35), 8, 0.0, 0.15)
		shrub(k, Vector3(-1.65 + i * 0.26, 0.28, -0.35), 0.13)
	k.cyl(0.1, 0.18, Color(0.3, 0.6, 0.4), at(-1.0, 0.1, 1.95), 8)
	beam(k, Vector3(-1.0, 0.25, 1.95), Vector3(-0.8, 0.3, 1.95), 0.02, Color(0.3, 0.6, 0.4))
	k.cyl(0.13, 0.25, Color(0.9, 0.9, 0.88), at(-1.3, 0.1, 1.85), 8, 0.0, 0.15)
	# a mailbox on a post, a little window on the left wall
	k.box(Vector3(0.06, 1.0, 0.06), Pal.WOOD_DARK, at(0.75, 0.6, 1.75))
	k.box(Vector3(0.2, 0.18, 0.32), Color(0.85, 0.3, 0.26), at(0.75, 1.15, 1.75))
	k.box(Vector3(0.02, 0.1, 0.02), Color(0.95, 0.85, 0.3), at(0.86, 1.25, 1.62))
	k.box(Vector3(0.05, 0.5, 0.6), Color(0.66, 0.78, 0.84, 0.75), at(-1.84, 1.3, -1.6))
	k.box(Vector3(0.06, 0.6, 0.06), Pal.WOOD_DARK, at(-1.85, 1.3, -1.6))
	# a wifi sign scrawled on cardboard
	k.box(Vector3(0.5, 0.35, 0.02), Color(0.72, 0.58, 0.4), xf(Vector3(0.75, 0.9, -0.55), Vector3(0, 0, 6)))
	for i in 3:
		k.torus(0.05 + i * 0.05, 0.01, Color(0.2, 0.3, 0.6), xf(Vector3(0.75, 0.82, -0.53), Vector3(90, 0, 0)), 8, 3, PI)


static func _gw1x(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var cc := Color(0.24, 0.44, 0.64)
	var top := 2.75
	# slab joints, an oil stain, a drain
	floor_grid(k, Vector3(0, 0.104, 0), 3.9, 5.9, 4, 6, Color(0.6, 0.6, 0.58))
	k.cyl(0.35, 0.004, Color(0.4, 0.4, 0.4), at(0.9, 0.105, 0.9), 10)
	manhole(k, Vector3(-0.3, 0.105, 2.3))
	# container markings: an ID plate, a CSC plate, hazard diamonds, vents
	k.box(Vector3(0.9, 0.18, 0.02), Color(0.95, 0.95, 0.95), at(0.4, 2.45, -0.63))
	text(k, "TKN", at(0.4, 2.39, -0.62), 0.03, cc.darkened(0.3), 0.01)
	k.box(Vector3(0.2, 0.14, 0.02), Color(0.86, 0.86, 0.84), at(1.25, 1.2, -0.63))
	k.box(Vector3(0.16, 0.16, 0.02), Color(0.98, 0.84, 0.3), xf(Vector3(1.25, 1.6, -0.63), Vector3(0, 0, 45)))
	for i in 2:
		ArchKit.louvres(k, at(-1.6 + i * 2.6, 2.2, -0.62), 0.25, 0.2, cc.darkened(0.15), 3)
	# a wall lamp and a camera on the container, a danger sign
	k.box(Vector3(0.3, 0.1, 0.15), Color(0.2, 0.2, 0.22), at(-0.65, 2.55, -0.55))
	k.box(Vector3(0.24, 0.02, 0.1), lit(p["glow"], 0.35), at(-0.65, 2.5, -0.53))
	cctv(k, at(1.3, 2.5, -0.65))
	k.box(Vector3(0.24, 0.3, 0.02), Color(0.98, 0.84, 0.3), at(0.4, 1.7, -0.63))
	k.box(Vector3(0.08, 0.12, 0.01), Color(0.1, 0.1, 0.1), xf(Vector3(0.4, 1.7, -0.62), Vector3(0, 0, 20)))
	# roof: panel seams, a hatch, vents, a small solar panel, a weather station
	floor_grid(k, Vector3(-0.32, top + 0.025, -1.75), 3.0, 2.1, 6, 1, cc.darkened(0.25))
	hatch(k, Vector3(1.0, top, -2.35), p["trim"])
	vent(k, Vector3(-1.6, top, -1.65), p["metal"])
	vent(k, Vector3(-0.3, top, -0.9), p["metal"])
	ArchKit.solar(k, at(-0.6, top, -1.55), 1, t, 25.0, 0.3)
	k.cyl(0.02, 0.8, p["metal"], at(-1.75, top, -2.7), 4)
	k.box(Vector3(0.3, 0.02, 0.02), p["metal"], at(-1.75, top + 0.8, -2.7))
	for sx in [-1.0, 1.0]:
		k.sphere(0.04, Color(0.9, 0.9, 0.9), at(-1.75 + sx * 0.15, top + 0.82, -2.7), 6, 3)
	# mast base: equipment cabinets, a small fenced compound, cable runs up
	k.box(Vector3(0.35, 0.8, 0.3), Color(0.82, 0.83, 0.84), at(1.7, 0.5, -1.7))
	k.box(Vector3(0.25, 0.03, 0.01), lit(p["glow"], 0.3), at(1.7, 0.7, -1.545))
	k.box(Vector3(0.025, 4.8, 0.025), Color(0.15, 0.15, 0.17), at(1.68, 2.6, -2.42))
	k.box(Vector3(0.025, 4.6, 0.025), Color(0.15, 0.15, 0.17), at(1.53, 2.5, -2.48))
	ArchKit.fence(k, Vector3(1.25, 0.1, -1.95), Vector3(1.92, 0.1, -1.95), t, 1.0)
	# a stepladder, a pallet of boxes, a fire extinguisher post
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(-1.0 + sx * 0.18, 0.1, -0.15), Vector3(-1.0 + sx * 0.15, 1.3, -0.35), 0.04, p["accent"])
		beam(k, Vector3(-1.0 + sx * 0.18, 0.1, -0.6), Vector3(-1.0 + sx * 0.15, 1.3, -0.4), 0.04, p["accent"])
	for i in 4:
		k.box(Vector3(0.34, 0.03, 0.04), p["metal"], at(-1.0, 0.35 + i * 0.25, -0.2 - i * 0.05))
	k.box(Vector3(0.06, 1.0, 0.06), Color(0.85, 0.2, 0.18), at(1.6, 0.6, 1.15))
	k.box(Vector3(0.12, 0.32, 0.12), Color(0.85, 0.15, 0.15), at(1.6, 0.6, 1.24))
	# cable bundles off the tray down to the rack
	for i in 3:
		cable(k, Vector3(-1.75, 2.35, 0.9), Vector3(-1.4 + i * 0.3, 1.5, 1.15), 0.2, [Color(0.98, 0.64, 0.86), Color(0.95, 0.8, 0.3), Color(0.3, 0.6, 0.95)][i], 0.02, 3)


static func _gw2x(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var rt := 2.9
	# paving joints and a glass-room roof: seams, a skylight, vents
	floor_grid(k, Vector3(0, 0.104, 1.2), 3.4, 3.4, 6, 6, p["wall2"])
	floor_grid(k, Vector3(0, rt + 0.165, -1.05), 3.8, 1.4, 8, 2, p["wall2"])
	k.box(Vector3(0.7, 0.08, 0.9), lit(Color(0.7, 0.88, 0.95), 0.75), at(-0.5, rt + 0.2, -1.05))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 0.1, 0.94), p["frame"], at(-0.5 + sx * 0.35, rt + 0.21, -1.05))
	vent(k, Vector3(1.4, rt + 0.16, -1.5), p["metal"], 0.25)
	vent(k, Vector3(1.7, rt + 0.16, -0.7), p["metal"], 0.25)
	ArchKit.solar(k, at(1.45, rt + 0.16, -0.95), 1, t, 15.0, 0.25)
	# the back block: vertical fins, a second dish, a cable tray, a hatch
	for i in 7:
		k.box(Vector3(0.06, 1.6, 0.18), p["wall2"], at(-1.8 + i * 0.6, rt + 1.2, -1.66))
	var top := 5.0
	sat_dish(k, at(0.5, top, -2.6), 0.35, t, 50.0, -40.0, 0.4)
	hatch(k, Vector3(0.25, top, -2.0), p["wall2"])
	ArchKit.cable_tray(k, Vector3(-0.3, top + 0.15, -2.75), Vector3(1.5, top + 0.15, -2.75), t)
	for i in 3:
		vent(k, Vector3(-1.6 + i * 0.3, top, -1.95), p["metal"], 0.3)
	# inside the glass room: a reception counter, plants, ceiling lights
	k.box(Vector3(0.9, 0.9, 0.3), Color(0.96, 0.96, 0.97), at(1.2, 0.6, -0.85))
	k.box(Vector3(0.92, 0.04, 0.32), p["trim"], at(1.2, 1.06, -0.85))
	shrub(k, Vector3(-1.65, 0.18, -0.85), 0.2, 0.5)
	for i in 3:
		k.box(Vector3(0.9, 0.03, 0.06), lit(p["glow"], 0.4), at(-1.15 + i * 1.15, rt - 0.03, -1.0))
	# out front: low hedges, a bin, a bike rack with a bike, a flagpole
	hedge(k, Vector3(-1.75, 0.1, -0.35), Vector3(-1.1, 0.1, -0.35), 0.35)
	hedge(k, Vector3(0.7, 0.1, 0.05), Vector3(1.75, 0.1, 0.05), 0.3)
	bin(k, Vector3(-0.75, 0.1, 0.6), Color(0.3, 0.6, 0.6))
	for i in 3:
		k.box(Vector3(0.14, 0.004, 0.6), Color(0.98, 0.98, 0.98), at(-0.2 + i * 0.2, 0.106, -0.2))


static func _gw3x(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var top := 3.8
	var zf := -0.55
	# roof: membrane seams, a hatch, vent cluster, a walkway, a third AC
	floor_grid(k, Vector3(-0.45, top + 0.035, -1.7), 2.6, 2.1, 6, 3, p["roof"].darkened(0.15))
	hatch(k, Vector3(-0.6, top, -1.35), p["trim"])
	for i in 3:
		vent(k, Vector3(-0.85 + i * 0.25, top, -0.8), p["metal"], 0.3)
	ArchKit.ac_unit(k, at(0.6, top, -2.35), t, 0.7)
	for i in 6:
		k.box(Vector3(0.3, 0.03, 0.4), p["metal"].darkened(0.25), at(-1.7 + i * 0.36, top + 0.04, -1.85))
	# façade: pipes, electric boxes, a camera, wall lights, hazard stripes, a hose box
	ArchKit.pipes(k, [Vector3(-1.75, 0.2, zf + 0.12), Vector3(-1.75, 3.6, zf + 0.12)], 0.05, Color(0.9, 0.5, 0.3))
	ebox(k, at(0.0, 1.0, zf), p["metal"])
	ebox(k, at(0.0, 1.55, zf), p["metal"], 0.3, 0.3)
	cctv(k, at(0.8, 2.3, zf))
	for x in [-1.3, 0.1]:
		k.box(Vector3(0.24, 0.08, 0.12), p["dark"], at(x, 2.25, zf + 0.06))
		k.box(Vector3(0.2, 0.02, 0.06), lit(p["glow"], 0.35), at(x, 2.2, zf + 0.1))
	for i in 8:
		k.box(Vector3(0.12, 0.08, 0.02), p["accent"] if i % 2 == 0 else p["dark"], at(-1.35 + i * 0.18, 0.15, zf + 0.06))
	k.box(Vector3(0.4, 0.5, 0.14), Color(0.85, 0.2, 0.18), at(0.75, 1.1, zf + 0.07))
	# the mast: cable runs, GPS domes, a gated fence at its foot
	for i in 2:
		k.box(Vector3(0.03, 8.0, 0.03), Color(0.15, 0.15, 0.17), at(1.2 + i * 0.05, 4.4, -2.1))
	for i in 3:
		k.cyl(0.05, 0.1, Color(0.95, 0.95, 0.94), at(1.1 + i * 0.15, 7.45, -2.75), 6)
	ArchKit.fence(k, Vector3(0.95, 0.1, -1.7), Vector3(1.92, 0.1, -1.7), t, 1.0)
	# load balancer: cabinets at its foot, a status board
	k.box(Vector3(0.5, 0.7, 0.3), p["dark"], at(1.45, 0.45, 0.45))
	for j in 3:
		k.box(Vector3(0.36, 0.02, 0.01), lit(p["glow"], 0.35), at(1.45, 0.3 + j * 0.15, 0.605))
	# ground: drains, a manhole, yellow hatching
	manhole(k, Vector3(0.0, 0.105, 2.3), p["dark"])
	for i in 5:
		k.box(Vector3(0.5, 0.005, 0.07), p["accent"], xf(Vector3(1.4, 0.106, 1.0 + i * 0.22), Vector3(0, 45, 0)))
	k.box(Vector3(3.6, 0.02, 0.12), p["dark"], at(0, 0.11, zf + 0.25))


static func _gw4x(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var top := 5.0
	var zf := -0.65
	# roof: glowing seams, brass skylights, a coolant manifold, small fins
	for i in 4:
		k.box(Vector3(3.3, 0.01, 0.02), lit(p["accent2"], 0.5), at(0.15, top + 0.04, -2.5 + i * 0.6))
	for x in [-1.3, -0.5]:
		k.box(Vector3(0.5, 0.08, 0.6), p["glass"], at(x, top + 0.07, -2.3))
		k.box(Vector3(0.54, 0.03, 0.64), brass, at(x, top + 0.12, -2.3))
	ArchKit.pipes(k, [Vector3(1.1, top + 0.2, -2.6), Vector3(1.6, top + 0.2, -2.6), Vector3(1.6, top + 0.2, -1.5)], 0.05, lit(p["accent2"], 0.5))
	for i in 4:
		k.box(Vector3(0.05, 0.4, 0.4), p["wall2"], at(1.2 + i * 0.15, top + 0.2, -2.0))
	# the spire: struts between the legs at each ring, packets of light on the core
	var sp := Vector3(0.2, top, -2.2)
	for i in 6:
		var y := 0.7 + i * 1.3
		var r := lerpf(0.55, 0.12, y / 8.6)
		for j in 4:
			var a := TAU * j / 4.0 + PI / 4.0
			var b := TAU * (j + 1) / 4.0 + PI / 4.0
			beam(k, sp + Vector3(cos(a) * r, y, sin(a) * r), sp + Vector3(cos(b) * r, y, sin(b) * r), 0.04, p["wall2"])
	for i in 8:
		k.box(Vector3(0.12, 0.12, 0.12), lit(Color(0.98, 0.6, 0.86) if i % 2 else p["glow"], 0.35), at(sp.x, sp.y + 0.6 + i * 1.0, sp.z))
	for i in 4:
		var a2 := TAU * i / 4.0
		k.cyl(0.012, 0.9, brass, at(sp.x + cos(a2) * 0.25, sp.y + 8.7, sp.z + sin(a2) * 0.25), 4)
	# a canopy over the portal, glowing letters
	k.box(Vector3(1.3, 0.08, 0.7), p["wall2"], at(1.2, 2.45, zf + 0.35))
	k.box(Vector3(1.32, 0.03, 0.72), brass, at(1.2, 2.5, zf + 0.35))
	k.box(Vector3(1.2, 0.02, 0.04), lit(p["glow"], 0.4), at(1.2, 2.4, zf + 0.68))
	text(k, "API", at(-0.5, 2.45, zf + 0.32), 0.07, lit(p["glow"], 0.35), 0.03)
	# planters with dark sculpted shrubs, a bench
	for x in [-1.05, 1.6]:
		k.box(Vector3(0.6, 0.45, 0.6), p["wall2"], at(x, 0.32, 0.1))
		k.box(Vector3(0.62, 0.03, 0.62), brass, at(x, 0.56, 0.1))
		k.sphere(0.26, Color(0.22, 0.36, 0.26), at(x, 0.8, 0.1), 8, 5)
	k.box(Vector3(0.9, 0.06, 0.32), p["wall2"], at(0.3, 0.45, 0.1))
	k.box(Vector3(0.92, 0.02, 0.34), brass, at(0.3, 0.49, 0.1))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.08, 0.35, 0.3), p["wall"], at(0.3 + sx * 0.38, 0.27, 0.1))
	# fiber vault covers with a glow, brass kerb lights
	for z in [1.6, 2.2]:
		k.box(Vector3(0.6, 0.02, 0.45), p["wall2"], at(-1.55, 0.11, z))
		k.box(Vector3(0.5, 0.005, 0.03), lit(Color(0.98, 0.6, 0.86), 0.45), at(-1.55, 0.125, z))
	for i in 5:
		k.box(Vector3(0.08, 0.04, 0.08), lit(p["glow"], 0.35), at(-1.9 + i * 0.95, 0.12, 2.9))


## Gateway: a third pass of structure and gear.
static func _gw1y(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	# an awning over the container's open door, with work lights
	tin_roof(k, Vector3(-0.65, 2.55, -0.25), 2.0, 0.6, Color(0.62, 0.64, 0.68), 12.0, 0.2)
	for x in [-1.55, 0.25]:
		beam(k, Vector3(x, 2.5, 0.02), Vector3(x, 2.1, -0.53), 0.04, p["trim"])
	for i in 3:
		k.box(Vector3(0.24, 0.03, 0.08), lit(p["glow"], 0.35), at(-1.3 + i * 0.6, 2.5, -0.2))
	# chain-link along the left between the slots, a gate post with a sign
	ArchKit.fence(k, Vector3(-1.9, 0.1, 0.78), Vector3(-1.9, 0.1, 1.42), t, 1.4)
	# side wall dressing on the container's ends
	# a cable tray along the container front feeding the door AC and lamp
	ArchKit.cable_tray(k, Vector3(-1.75, 2.62, -0.48), Vector3(1.1, 2.62, -0.48), t)
	for x in [-1.2, -0.1, 0.9]:
		k.box(Vector3(0.04, 0.2, 0.18), p["trim"], at(x, 2.55, -0.55))


static func _gw2y(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var rt := 2.9
	# a green roof on the glass room around the roof slots
	var avoid := slot_rects("gateway", t, true)
	for i in 14:
		var q := Vector2(-1.55 + (i % 7) * 0.52, -1.6 + (i / 7) * 0.9)
		if not _clear(q, 0.2, avoid) or absf(q.x + 0.5) < 0.4:
			continue
		k.box(Vector3(0.5, 0.05, 0.5), Color(0.46, 0.6, 0.36), at(q.x, rt + 0.19, q.y))
		shrub(k, Vector3(q.x, rt + 0.2, q.y), 0.14)
	# a glass entrance canopy, a vertical garden up the right side wall
	k.box(Vector3(1.2, 0.05, 0.8), p["glass"], at(0.2, 2.4, -0.2))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 0.04, 0.8), p["frame"], at(0.2 + sx * 0.6, 2.38, -0.2))
		beam(k, Vector3(0.2 + sx * 0.55, 2.4, 0.18), Vector3(0.2 + sx * 0.55, 2.85, -0.6), 0.03, p["frame"])
	# people at the desks and in the lobby
	for i in 3:
		k.capsule(0.09, 0.55, [Color(0.3, 0.5, 0.8), Color(0.85, 0.4, 0.3), Color(0.3, 0.6, 0.4)][i], at(-1.15 + i * 1.15, 0.5, -0.82), 6, 2)
		k.sphere(0.08, Color(0.92, 0.78, 0.66), at(-1.15 + i * 1.15, 1.13, -0.82), 6, 3)
	# the back block's sides: louvre bands, a fire escape ladder
	ArchKit.ladder(k, xf(Vector3(1.5, 2.9, -1.62), Vector3(0, 180, 0)), 2.0, p["metal"], false)


static func _gw3y(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var zf := -0.55
	# a front catwalk at mezzanine level, reached by a caged ladder
	ArchKit.catwalk(k, Vector3(-1.8, 2.3, zf + 0.3), Vector3(0.95, 2.3, zf + 0.3), 0.5, t, false)
	for x in [-1.6, -0.4, 0.8]:
		beam(k, Vector3(x, 2.28, zf + 0.5), Vector3(x, 1.7, zf + 0.02), 0.05, p["trim"])
	ArchKit.ladder(k, xf(Vector3(0.95, 0.1, zf + 0.2), Vector3(0, -90, 0)), 2.3, p["accent"], true)
	# louvre banks down the left side, cable entries
	# the mast: a third platform, two more drums, an ice bridge to the tower
	var mp := Vector3(1.42, 0.1, -2.35)
	drum(k, xf(Vector3(mp.x - 0.3, 4.2, mp.z + 0.25), Vector3(0, -40, 0)), 0.22)
	drum(k, xf(Vector3(mp.x + 0.3, 5.6, mp.z - 0.2), Vector3(0, 120, 0)), 0.22)
	k.box(Vector3(0.9, 0.05, 0.9), p["metal"].darkened(0.2), at(mp.x, 2.6, mp.z))
	ArchKit.cable_tray(k, Vector3(mp.x, 2.7, mp.z + 0.4), Vector3(mp.x, 2.7, -0.6), t)
	# roof: a third AC, cable trays on stands
	ArchKit.cable_tray(k, Vector3(-1.7, 3.8 + 0.35, -2.7), Vector3(0.85, 3.8 + 0.35, -2.7), t)
	wall_dress(k, xf(Vector3(1.0, 0.1, -1.4), Vector3(0, 90, 0)), 1.2, 3.6, t, 23)


static func _gw4y(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var top := 5.0
	# glowing fins on the upper block's sides, brass ribs on the plinth sides
	for sx in [-1.0, 1.0]:
		for i in 5:
			k.box(Vector3(0.03, 2.7, 0.06), brass, at(sx * 1.885, 1.45, -2.6 + i * 0.45))
	# more phased panels up the spire, a ring of beacons at the crown
	var sp := Vector3(0.2, top, -2.2)
	for i in 3:
		var a := TAU * i / 3.0 + PI / 3.0
		var q := sp + Vector3(sin(a) * 0.3, 5.4, cos(a) * 0.3)
		k.box(Vector3(0.26, 0.8, 0.05), p["wall"], xf(q, Vector3(0, rad_to_deg(a), 0)))
		k.box(Vector3(0.2, 0.7, 0.02), lit(p["accent2"], 0.55), xf(q, Vector3(0, rad_to_deg(a), 0)) * at(0, 0, 0.035))
	for i in 4:
		var a2 := TAU * i / 4.0
		k.sphere(0.05, lit(Color(1.0, 0.3, 0.25), 0.3), at(sp.x + cos(a2) * 0.36, sp.y + 8.95, sp.z + sin(a2) * 0.36), 6, 3)
	# a holographic sign over the entrance on brass arms
	k.box(Vector3(1.2, 0.4, 0.02), lit(p["accent2"], 0.6), at(1.2, 3.2, -0.2))
	text(k, "API", at(1.2, 3.05, -0.18), 0.05, lit(p["glow"], 0.3), 0.02)
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(1.2 + sx * 0.55, 3.0, -0.2), Vector3(1.2 + sx * 0.55, 3.0, -0.66), 0.04, brass)
	# a dark roof terrace: planters along the parapet
	for i in 3:
		k.box(Vector3(0.35, 0.3, 0.3), p["wall2"], at(0.3 + i * 0.4, top + 0.15, -0.05))
		k.sphere(0.15, Color(0.22, 0.36, 0.26), at(0.3 + i * 0.4, top + 0.38, -0.05), 6, 4)


# ---------------------------------------------------------------- Edge PoP (6 x 6 m)
# Growth gear fills the front-right yard (x > -1.3, z > 0.3); the building
# keeps to the back half and the left strip.

static func edge(t: int) -> Mesh:
	var k := MeshKit.new()
	ArchKit.lot(k, 5.9, 5.9, t)
	match clampi(t, 0, 4):
		0: _edge0(k)
		1: _edge1(k)
		2: _edge2(k)
		3: _edge3(k)
		_: _edge4(k)
	match clampi(t, 0, 4):
		0: _edge0x(k)
		1:
			_edge1x(k)
			_edge1y(k)
		2:
			_edge2x(k)
			_edge2y(k)
		3:
			_edge3x(k)
			_edge3y(k)
		_:
			_edge4x(k)
			_edge4y(k)
	_life(k, "edge", clampi(t, 0, 4))
	_finish(k, "edge", clampi(t, 0, 4))
	_dense(k, "edge", clampi(t, 0, 4))
	return k.commit()


## Garage: a cell repeater on a wooden pole, a battery box, a tarp shelter.
static func _edge0(k: MeshKit) -> void:
	var t := 0
	var pole := Color(0.42, 0.3, 0.22)
	var pp := Vector3(-1.9, 0.1, -2.0)
	# the pole, step bolts, a crossarm with insulators
	k.cyl(0.11, 5.2, pole, at(pp.x, pp.y, pp.z), 8)
	for i in 8:
		k.box(Vector3(0.22, 0.025, 0.025), Color(0.5, 0.5, 0.52), at(pp.x, 1.2 + i * 0.42, pp.z + (0.05 if i % 2 else -0.05)))
	k.box(Vector3(1.4, 0.1, 0.1), pole.lightened(0.1), at(pp.x, 4.6, pp.z))
	for i in 3:
		k.cyl(0.04, 0.16, Color(0.4, 0.62, 0.5), at(pp.x - 0.55 + i * 0.55, 4.65, pp.z), 6)
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(pp.x, 4.2, pp.z), Vector3(pp.x + sx * 0.5, 4.58, pp.z), 0.04, pole)
	# the repeater: a white finned box, two panels and a little yagi on top
	k.box(Vector3(0.4, 0.55, 0.22), Color(0.94, 0.94, 0.92), at(pp.x, 3.4, pp.z + 0.2))
	for i in 5:
		k.box(Vector3(0.03, 0.45, 0.08), Color(0.8, 0.8, 0.78), at(pp.x - 0.16 + i * 0.08, 3.4, pp.z + 0.35))
	k.box(Vector3(0.1, 0.03, 0.01), lit(Color(0.5, 1.0, 0.6), 0.3), at(pp.x + 0.1, 3.6, pp.z + 0.315))
	panel_ant(k, xf(Vector3(pp.x - 0.25, 4.95, pp.z + 0.12), Vector3(0, -25, 0)), 0.7)
	panel_ant(k, xf(Vector3(pp.x + 0.25, 4.95, pp.z + 0.12), Vector3(0, 25, 0)), 0.7)
	yagi(k, xf(Vector3(pp.x, 5.15, pp.z - 0.2), Vector3(0, 30, 0)), 0.8, Color(0.82, 0.84, 0.86), 7)
	# cables down the pole, a guy wire
	k.box(Vector3(0.03, 3.2, 0.03), Color(0.15, 0.15, 0.16), at(pp.x + 0.12, 1.7, pp.z + 0.08))
	k.box(Vector3(0.03, 3.2, 0.03), Color(0.15, 0.15, 0.16), at(pp.x + 0.08, 1.7, pp.z + 0.12))
	beam(k, Vector3(pp.x, 4.4, pp.z), Vector3(-2.8, 0.15, -2.85), 0.015, Color(0.3, 0.3, 0.32))
	k.box(Vector3(0.1, 0.25, 0.1), Pal.WOOD_DARK, at(-2.78, 0.2, -2.82))
	# the battery box on a pallet: lid propped open, car batteries, cables
	var bb := Vector3(-1.55, 0.1, -1.1)
	for j in 3:
		k.box(Vector3(1.1, 0.04, 0.12), Pal.WOOD_LIGHT, at(bb.x, bb.y + 0.12, bb.z - 0.35 + j * 0.35))
	for sx in [-1.0, 0.0, 1.0]:
		k.box(Vector3(0.1, 0.1, 0.9), Pal.WOOD, at(bb.x + sx * 0.48, bb.y + 0.05, bb.z))
	k.box(Vector3(0.95, 0.5, 0.65), Color(0.3, 0.5, 0.34), at(bb.x, bb.y + 0.39, bb.z))
	k.box(Vector3(0.85, 0.02, 0.55), Color(0.12, 0.12, 0.13), at(bb.x, bb.y + 0.645, bb.z))
	k.box(Vector3(0.97, 0.04, 0.67), Color(0.3, 0.5, 0.34), xf(Vector3(bb.x, bb.y + 0.9, bb.z - 0.5), Vector3(-70, 0, 0)))
	for i in 3:
		k.box(Vector3(0.24, 0.2, 0.4), Color(0.16, 0.16, 0.18), at(bb.x - 0.28 + i * 0.28, bb.y + 0.74, bb.z))
		k.box(Vector3(0.04, 0.04, 0.04), Color(0.9, 0.25, 0.2), at(bb.x - 0.34 + i * 0.28, bb.y + 0.86, bb.z + 0.12))
		k.box(Vector3(0.04, 0.04, 0.04), Color(0.2, 0.2, 0.2), at(bb.x - 0.22 + i * 0.28, bb.y + 0.86, bb.z + 0.12))
	cable(k, Vector3(bb.x - 0.2, bb.y + 0.86, bb.z + 0.12), Vector3(pp.x + 0.1, 1.5, pp.z + 0.1), 0.2, Color(0.9, 0.25, 0.2), 0.02)
	cable(k, Vector3(bb.x + 0.1, bb.y + 0.86, bb.z + 0.12), Vector3(pp.x + 0.12, 1.4, pp.z + 0.12), 0.25, Color(0.15, 0.15, 0.16), 0.02)
	text(k, "12V", at(bb.x, bb.y + 0.25, bb.z + 0.33), 0.04, Color(0.95, 0.9, 0.6))
	# a solar panel on a wooden A-frame, a charge controller on a stake
	var sp := Vector3(-2.3, 0.1, 0.4)
	k.box(Vector3(1.0, 0.04, 0.7), Color(0.16, 0.24, 0.44), xf(Vector3(sp.x, sp.y + 0.7, sp.z), Vector3(-35, 90, 0)))
	k.box(Vector3(1.02, 0.045, 0.02), Color(0.7, 0.72, 0.74), xf(Vector3(sp.x, sp.y + 0.7, sp.z), Vector3(-35, 90, 0)))
	for sz in [-1.0, 1.0]:
		beam(k, Vector3(sp.x - 0.2, sp.y + 0.9, sp.z + sz * 0.4), Vector3(sp.x + 0.25, sp.y, sp.z + sz * 0.4), 0.05, Pal.WOOD)
		beam(k, Vector3(sp.x - 0.2, sp.y + 0.9, sp.z + sz * 0.4), Vector3(sp.x - 0.4, sp.y, sp.z + sz * 0.4), 0.05, Pal.WOOD)
	k.box(Vector3(0.06, 0.9, 0.06), Pal.WOOD_DARK, at(-1.75, 0.55, -0.2))
	k.box(Vector3(0.22, 0.3, 0.08), Color(0.2, 0.38, 0.7), at(-1.75, 0.95, -0.15))
	k.box(Vector3(0.12, 0.05, 0.01), lit(Color(0.5, 1.0, 0.6), 0.3), at(-1.75, 1.02, -0.105))
	ArchKit.pipes(k, [Vector3(sp.x, 0.5, sp.z), Vector3(-1.75, 0.12, 0.1), Vector3(-1.75, 0.8, -0.15)], 0.015, Color(0.15, 0.15, 0.16))
	# the tarp shelter: a router on a folding table, a camping chair
	var tz := -2.0
	for p2 in [Vector3(-0.4, 0, tz - 0.6), Vector3(1.6, 0, tz - 0.6), Vector3(-0.4, 0, tz + 0.7), Vector3(1.6, 0, tz + 0.7)]:
		k.box(Vector3(0.06, 2.0 if p2.z < tz else 1.75, 0.06), Pal.WOOD, at(p2.x, 0.1 + (1.0 if p2.z < tz else 0.875), p2.z))
	k.box(Vector3(2.3, 0.03, 1.6), Color(0.26, 0.46, 0.78), xf(Vector3(0.6, 2.0, tz + 0.05), Vector3(-9, 0, 0)))
	for i in 4:
		k.box(Vector3(0.02, 0.03, 1.6), Color(0.2, 0.36, 0.62), xf(Vector3(-0.3 + i * 0.6, 2.02, tz + 0.05), Vector3(-9, 0, 0)))
	for x in [-0.4, 1.6]:
		beam(k, Vector3(x, 1.85, tz + 0.75), Vector3(x + (0.3 if x > 0 else -0.3), 0.1, tz + 1.4), 0.012, Color(0.85, 0.85, 0.8))
	table(k, at(0.6, 0.1, tz - 0.1), 1.2, 0.6, Color(0.9, 0.9, 0.88), Color(0.4, 0.42, 0.45))
	k.box(Vector3(0.3, 0.06, 0.2), Color(0.12, 0.12, 0.14), at(0.3, 0.87, tz - 0.15))
	for i in 3:
		beam(k, Vector3(0.2 + i * 0.1, 0.9, tz - 0.22), Vector3(0.18 + i * 0.12, 1.12, tz - 0.25), 0.012, Color(0.12, 0.12, 0.14))
	laptop(k, xf(Vector3(0.85, 0.84, tz - 0.05), Vector3(0, 190, 0)))
	k.cyl(0.05, 0.12, Color(0.94, 0.94, 0.92), at(1.1, 0.84, tz - 0.2), 6)
	chair(k, xf(Vector3(0.6, 0.1, tz + 0.55), Vector3(0, 180, 0)), Color(0.3, 0.6, 0.4))
	ArchKit.string_lights(k, Vector3(-0.4, 1.95, tz + 0.75), Vector3(1.6, 1.95, tz + 0.75), 8)
	# the hand-painted sign on a plywood board
	k.box(Vector3(1.1, 0.5, 0.04), Color(0.82, 0.68, 0.48), xf(Vector3(-1.6, 0.85, 0.1), Vector3(0, 10, -3)))
	text(k, "EDGE", xf(Vector3(-1.6, 0.72, 0.13), Vector3(0, 10, -3)), 0.05, Color(0.2, 0.4, 0.75))
	k.box(Vector3(0.06, 0.8, 0.06), Pal.WOOD_DARK, xf(Vector3(-1.6, 0.4, 0.06), Vector3(0, 10, 0)))
	# back fence, a wheelbarrow, tyres, jerry cans, a cooler
	ArchKit.fence(k, Vector3(-2.88, 0.1, -2.88), Vector3(2.88, 0.1, -2.88), t, 1.0)
	ArchKit.fence(k, Vector3(2.88, 0.1, -2.88), Vector3(2.88, 0.1, 0.2), t, 1.0)
	for i in 3:
		k.torus(0.26, 0.09, Color(0.16, 0.16, 0.17), at(2.35, 0.19 + i * 0.17, -2.35), 10, 4)
	k.box(Vector3(0.5, 0.25, 0.7), Color(0.4, 0.55, 0.6), xf(Vector3(2.1, 0.45, -0.9), Vector3(8, 25, 0)))
	k.cyl(0.14, 0.06, Color(0.15, 0.15, 0.16), xf(Vector3(2.2, 0.24, -0.5), Vector3(0, 25, 90)), 8)
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(2.1 + sx * 0.2, 0.4, -1.2), Vector3(1.85 + sx * 0.2, 0.55, -1.6), 0.04, Pal.WOOD_DARK)
	for i in 2:
		k.box(Vector3(0.25, 0.35, 0.14), Color(0.8, 0.22, 0.2), at(2.45, 0.28, -1.5 + i * 0.2))
	k.box(Vector3(0.5, 0.35, 0.32), Color(0.2, 0.45, 0.75), at(1.7, 0.28, -0.6))
	k.box(Vector3(0.52, 0.06, 0.34), Color(0.95, 0.95, 0.94), at(1.7, 0.48, -0.6))
	ArchKit.clutter(k, Vector3(-0.2, 0.1, -0.5), t, 4)


## Workshop: a shipping-container datacenter and a lattice cell tower.
static func _edge1(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var cc := Color(0.72, 0.36, 0.24)
	var cx := -0.75
	var len := 4.2
	var cz := -1.7
	var y0 := 0.28
	for i in 3:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.3, 0.18, 0.3), Color(0.62, 0.62, 0.6), at(cx - 1.9 + i * 1.9, 0.19, cz + sz * 0.9))
	container(k, at(cx, y0, cz), len, cc, 2.5, 2.3)
	var fz := cz + 1.15
	var top := y0 + 2.5
	# the front: a door with steel steps, two wall AC units, vents, labels
	ArchKit.door(k, at(-2.0, y0, fz + 0.02), t, 0.8, 1.95)
	ArchKit.stairs(k, xf(Vector3(-2.0, 0.1, fz + 0.75), Vector3(0, 0, 0)), 0.9, y0, t, false)
	k.box(Vector3(1.0, 0.05, 0.6), p["metal"], at(-2.0, y0, fz + 0.32))
	ArchKit.railing(k, Vector3(-2.5, y0, fz + 0.6), Vector3(-2.5, y0, fz + 0.05), 0.9, p["accent"], 0.5)
	for i in 2:
		var x := -0.6 + i * 1.2
		k.box(Vector3(0.9, 0.7, 0.4), Color(0.9, 0.9, 0.9), at(x, y0 + 1.35, fz + 0.2))
		k.cyl(0.25, 0.03, Color(0.22, 0.23, 0.26), xf(Vector3(x, y0 + 1.35, fz + 0.4), Vector3(90, 0, 0)), 10)
		k.box(Vector3(0.5, 0.03, 0.02), Color(0.55, 0.57, 0.6), at(x, y0 + 1.35, fz + 0.43))
		for sx in [-1.0, 1.0]:
			beam(k, Vector3(x + sx * 0.35, y0 + 1.0, fz + 0.02), Vector3(x + sx * 0.35, y0 + 1.0, fz + 0.4), 0.04, p["trim"])
		ArchKit.pipes(k, [Vector3(x + 0.3, y0 + 1.7, fz + 0.2), Vector3(x + 0.3, y0 + 2.1, fz + 0.1)], 0.03, Color(0.95, 0.95, 0.95))
	ArchKit.louvres(k, at(1.0, y0 + 0.4, fz + 0.03), 0.6, 0.5, cc.darkened(0.1), 5)
	k.box(Vector3(0.9, 0.3, 0.03), p["accent"], at(0.9, y0 + 2.1, fz + 0.04))
	text(k, "EDGE", at(0.9, y0 + 2.0, fz + 0.06), 0.04, p["dark"])
	k.box(Vector3(0.2, 0.2, 0.02), Color(0.98, 0.84, 0.3), at(-1.4, y0 + 1.6, fz + 0.04))
	# on the roof: a cable tray, a railing, a vent
	ArchKit.railing(k, Vector3(cx - len * 0.5 + 0.1, top, cz - 1.1), Vector3(cx + len * 0.5 - 0.1, top, cz - 1.1), 0.9, p["accent"])
	for i in 3:
		k.cyl(0.08, 0.3, Color(0.7, 0.72, 0.74), at(-2.2 + i * 1.1, top, -2.4), 6)
		k.cyl(0.12, 0.05, Color(0.6, 0.62, 0.64), at(-2.2 + i * 1.1, top + 0.3, -2.4), 6)
	# the cell tower: red and white lattice, a triangular head, drums
	var tp := Vector3(2.15, 0.1, -2.0)
	k.box(Vector3(1.2, 0.3, 1.2), Color(0.6, 0.6, 0.6), at(tp.x, 0.25, tp.z))
	mast(k, tp + Vector3(0, 0.4, 0), 7.0, 0.95, 0.4, Color(0.86, 0.3, 0.26), 0.7, 0.05, Color(0.94, 0.94, 0.92))
	var hy := 7.0
	for i in 3:
		var a := TAU * i / 3.0
		var c0 := tp + Vector3(cos(a) * 0.5, hy, sin(a) * 0.5)
		var c1 := tp + Vector3(cos(a + TAU / 3.0) * 0.5, hy, sin(a + TAU / 3.0) * 0.5)
		beam(k, c0, c1, 0.05, Color(0.84, 0.86, 0.88))
		for j in 2:
			var q := c0.lerp(c1, 0.3 + j * 0.4)
			panel_ant(k, xf(q + Vector3(0, 0.1, 0), Vector3(0, -rad_to_deg(a + PI / 3.0) + 90.0, 0)), 0.9)
	drum(k, xf(tp + Vector3(0, 5.4, 0.4), Vector3(0, 10, 0)), 0.3)
	drum(k, xf(tp + Vector3(-0.38, 4.6, 0), Vector3(0, -80, 0)), 0.26)
	k.cyl(0.03, 0.8, p["metal"], at(tp.x, 7.4, tp.z), 5)
	ArchKit.beacon(k, tp + Vector3(0, 8.2, 0), 0.2)
	ArchKit.ladder(k, xf(tp + Vector3(0, 0.4, 0.5), Vector3(0, 180, 0)), 6.4, p["metal"], false)
	# the ice bridge: a cable tray from the tower to the container
	ArchKit.cable_tray(k, Vector3(tp.x - 0.5, 2.6, tp.z + 0.1), Vector3(cx + len * 0.5, 2.6, tp.z + 0.1), t)
	k.box(Vector3(0.08, 2.5, 0.08), p["trim"], at(1.5, 1.35, tp.z + 0.1))
	# a generator on a skid in the left strip, a fuel can, an extinguisher
	ArchKit.generator(k, xf(Vector3(-2.35, 0.1, 0.9), Vector3(0, 90, 0)), t)
	k.box(Vector3(0.12, 0.35, 0.12), Color(0.85, 0.15, 0.15), at(-1.7, 0.28, 0.1))
	# chain-link fence along the left, a floodlight, cones, cable reels
	ArchKit.fence(k, Vector3(-2.88, 0.1, -0.5), Vector3(-2.88, 0.1, 2.8), t, 1.4)
	ArchKit.lamp(k, Vector3(-1.6, 0.1, 2.5), t, 3.0)
	cone(k, Vector3(-1.6, 0.1, 1.9))
	for i in 2:
		k.cyl(0.35, 0.05, Pal.WOOD, xf(Vector3(1.0 + i * 0.12, 0.45, -0.25), Vector3(0, 0, 90)), 10)
	k.cyl(0.22, 0.12, Color(0.25, 0.25, 0.27), xf(Vector3(1.06, 0.45, -0.25), Vector3(0, 0, 90)), 10)
	# fiber conduits out to the street
	for i in 3:
		ArchKit.pipes(k, [Vector3(-1.2 + i * 0.12, y0 + 0.3, fz + 0.05), Vector3(-1.2 + i * 0.12, 0.13, fz + 0.3), Vector3(-1.2 + i * 0.12, 0.13, 2.9)], 0.03, Color(0.98, 0.64, 0.86))


## Campus: a white modular micro-datacenter, condensers on the roof, a
## slim monopole and a solar carport.
static func _edge2(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var x0 := -2.78
	var x1 := 1.3
	var zb := -2.85
	var zf := -0.45
	var h := 3.1
	var cx := (x0 + x1) * 0.5
	var w := x1 - x0
	var d := zf - zb
	# three white modules on a plinth with teal bands
	k.box(Vector3(w + 0.1, 0.25, d + 0.1), p["wall2"], at(cx, 0.22, (zb + zf) * 0.5))
	k.rbox(Vector3(w, h, d), 0.05, p["wall"], at(cx, 0.35 + h * 0.5, (zb + zf) * 0.5), 1)
	for i in 4:
		k.box(Vector3(0.04, h, d + 0.02), p["wall2"], at(x0 + i * w / 3.0, 0.35 + h * 0.5, (zb + zf) * 0.5))
	k.box(Vector3(w + 0.02, 0.18, d + 0.02), p["trim"], at(cx, 0.35 + h - 0.45, (zb + zf) * 0.5))
	# the front: glass entry with canopy, louvres, a status strip, the logo
	ArchKit.door(k, at(x0 + w / 6.0, 0.35, zf + 0.01), t, 0.9, 2.0)
	ArchKit.louvres(k, at(cx, 0.6, zf + 0.02), 1.0, 1.4, p["wall2"], 8)
	ArchKit.louvres(k, at(x1 - w / 6.0, 0.6, zf + 0.02), 1.0, 1.4, p["wall2"], 8)
	for i in 6:
		k.box(Vector3(0.1, 0.03, 0.02), lit(p["glow"] if i % 4 else Color(1.0, 0.8, 0.4), 0.35), at(cx - 0.3 + (i % 3) * 0.3, 2.3 + (i / 3) * 0.1, zf + 0.03))
	k.box(Vector3(1.3, 0.45, 0.06), Color(0.98, 0.98, 0.98), at(x1 - w / 6.0, 2.55, zf + 0.03))
	k.box(Vector3(0.3, 0.3, 0.02), p["accent"], at(x1 - w / 6.0 - 0.45, 2.55, zf + 0.07))
	text(k, "EDGE", at(x1 - w / 6.0 + 0.15, 2.45, zf + 0.07), 0.04, p["dark"])
	for sx in [-1.0, 1.0]:
		ArchKit.louvres(k, xf(Vector3(x1 if sx > 0 else x0, 0.6, (zb + zf) * 0.5), Vector3(0, sx * 90.0, 0)), 1.6, 1.4, p["wall2"], 8)
	# the roof: parapet, two condenser banks behind a screen
	var top := 0.35 + h
	ArchKit.parapet(k, Vector3(cx, top, (zb + zf) * 0.5), w, d, t)
	ArchKit.chiller(k, at(cx - 0.4, top, -2.25), 2.6, t, 3)
	for i in 3:
		ArchKit.ac_unit(k, at(x0 + 0.7 + i * 1.05, top, -1.0), t, 0.8)
	for i in 9:
		k.box(Vector3(0.06, 0.9, 0.06), p["frame"], at(x0 + 0.2 + i * 0.47, top + 0.45, zf - 0.15))
	k.box(Vector3(w - 0.3, 0.06, 0.06), p["frame"], at(cx, top + 0.88, zf - 0.15))
	for i in 3:
		k.box(Vector3(w - 0.3, 0.12, 0.02), p["wall2"], at(cx, top + 0.25 + i * 0.25, zf - 0.13))
	# the monopole: a slim white pole with a canister top and a ring of panels
	var mp := Vector3(2.1, 0.1, -2.1)
	k.box(Vector3(1.0, 0.25, 1.0), p["wall2"], at(mp.x, 0.22, mp.z))
	k.cyl(0.22, 6.2, p["wall"], at(mp.x, 0.35, mp.z), 10, 0.0, 0.14)
	for y in [2.0, 4.0]:
		k.cyl(0.2, 0.06, p["trim"], at(mp.x, y, mp.z), 10)
	for i in 6:
		var a := TAU * i / 6.0
		panel_ant(k, xf(mp + Vector3(cos(a) * 0.32, 6.3, sin(a) * 0.32), Vector3(0, -rad_to_deg(a) + 90.0, 0)), 0.8, p["wall"])
	k.cyl(0.32, 0.08, p["trim"], at(mp.x, 5.85, mp.z), 10)
	k.cyl(0.14, 0.9, p["wall"], at(mp.x, 6.7, mp.z), 10, 0.04)
	ArchKit.beacon(k, mp + Vector3(0, 7.6, 0), 0.15)
	k.box(Vector3(0.6, 1.2, 0.5), p["wall"], at(mp.x, 0.95, mp.z + 0.85))
	k.box(Vector3(0.5, 0.04, 0.02), lit(p["glow"], 0.4), at(mp.x, 1.3, mp.z + 1.11))
	# the solar carport over the left strip with an EV charger
	for z in [0.2, 2.5]:
		k.box(Vector3(0.1, 2.4, 0.1), p["frame"], at(-2.25, 1.3, z))
	solar(k, -2.2, 2.5, 1.3, 0.2, 2.5, t)
	k.box(Vector3(0.3, 1.2, 0.2), p["wall"], at(-2.65, 0.7, 1.3))
	k.box(Vector3(0.2, 0.25, 0.02), lit(p["glow"], 0.4), at(-2.65, 1.0, 1.41))
	ArchKit.vehicle(k, xf(Vector3(-2.05, 0.1, 1.45), Vector3(0, 0, 0)), t)
	ArchKit.planter(k, Vector3(-1.6, 0.1, -0.05), t, 0.6, false)
	ArchKit.planter(k, Vector3(0.2, 0.1, -0.15), t, 0.7, true)
	ArchKit.lamp(k, Vector3(-1.55, 0.1, 2.75), t, 2.6)
	for i in 3:
		ArchKit.pipes(k, [Vector3(-0.3 + i * 0.12, 0.4, zf + 0.05), Vector3(-0.3 + i * 0.12, 0.13, zf + 0.25), Vector3(-0.3 + i * 0.12, 0.13, 0.25)], 0.025, Color(0.98, 0.64, 0.86))


## A flat solar canopy over x (cx +- w/2), z0..z1 at height y.
static func solar(k: MeshKit, cx: float, y: float, w: float, z0: float, z1: float, t: int) -> void:
	k.box(Vector3(w + 0.1, 0.08, z1 - z0 + 0.3), ArchKit.c(t, "frame"), at(cx, y, (z0 + z1) * 0.5))
	var n := int((z1 - z0 + 0.2) / 0.62)
	for i in n:
		var z := z0 - 0.1 + (i + 0.5) * (z1 - z0 + 0.2) / n
		k.box(Vector3(w, 0.04, 0.58), Color(0.16, 0.24, 0.44), xf(Vector3(cx, y + 0.07, z), Vector3(0, 0, 4)))
		k.box(Vector3(0.02, 0.05, 0.58), Color(0.6, 0.64, 0.7), xf(Vector3(cx, y + 0.075, z), Vector3(0, 0, 4)))


## Industrial: a stack of containers with a stair, a catwalk, a generator
## and a heavy lattice tower.
static func _edge3(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var c1 := Color(0.4, 0.44, 0.5)
	var c2 := Color(0.28, 0.42, 0.6)
	var cz := -1.75
	# a steel base frame, two containers stacked
	k.box(Vector3(4.4, 0.25, 2.3), p["trim"], at(-0.7, 0.22, cz))
	container(k, at(-0.75, 0.35, cz), 4.2, c1, 2.5, 2.2)
	container(k, at(-1.0, 2.85, cz), 3.7, c2, 2.4, 2.2)
	var fz := cz + 1.1
	# lower: louvres, doors, blue LED strips
	for i in 3:
		ArchKit.louvres(k, at(-2.2 + i * 1.3, 0.75, fz + 0.03), 0.8, 1.3, c1.darkened(0.1), 7)
		k.box(Vector3(0.8, 0.03, 0.02), lit(p["accent2"], 0.4), at(-2.2 + i * 1.3, 2.3, fz + 0.04))
	ArchKit.door(k, at(1.0, 0.35, fz + 0.02), t, 0.7, 1.9)
	# upper: a door off the catwalk, a sign, a glowing strip
	ArchKit.door(k, at(-2.2, 2.85, fz + 0.02), t, 0.7, 1.9)
	ArchKit.louvres(k, at(-0.6, 3.3, fz + 0.03), 1.4, 0.8, c2.darkened(0.1), 6)
	ArchKit.sign(k, at(0.4, 4.3, fz + 0.05), 1.0, 0.36, t)
	text(k, "EDGE", at(0.4, 4.42, fz + 0.15), 0.035, lit(Color(0.7, 0.9, 1.0), 0.35))
	# the catwalk along the upper front and a stair down to the left strip
	ArchKit.catwalk(k, Vector3(-2.8, 2.85, fz + 0.4), Vector3(0.85, 2.85, fz + 0.4), 0.75, t, true)
	ArchKit.stairs(k, at(-2.35, 0.1, 1.95), 0.75, 2.75, t)
	# roof: chillers and pipes on the top container
	var top := 2.85 + 2.4
	ArchKit.chiller(k, xf(Vector3(0.15, top, -1.75), Vector3(0, 90, 0)), 1.8, t, 2)
	ArchKit.pipes(k, [Vector3(-0.55, top + 0.3, -0.85), Vector3(0.75, top + 0.3, -0.85)], 0.06, Color(0.36, 0.6, 0.86))
	ArchKit.beacon(k, Vector3(0.6, top, -2.7), 0.4)
	# the lower container's free roof: a walkway and AC units
	ArchKit.ac_unit(k, at(1.0, 2.85, -2.3), t, 0.8)
	ArchKit.railing(k, Vector3(0.9, 2.85, fz - 0.05), Vector3(1.3, 2.85, fz - 0.05), 0.9, p["accent"])
	# the generator, its fuel tank and a transformer on the right
	ArchKit.generator(k, xf(Vector3(2.3, 0.1, -0.15), Vector3(0, -90, 0)), t)
	ArchKit.transformer(k, at(1.75, 0.1, 0.55), t)
	k.box(Vector3(0.9, 0.04, 0.04), lit(p["glow"], 0.4), at(2.3, 0.4, 0.95))
	# the tower: heavy steel, platforms, dishes, panels
	var tp := Vector3(2.15, 0.1, -2.1)
	k.box(Vector3(1.2, 0.35, 1.2), Color(0.55, 0.56, 0.58), at(tp.x, 0.28, tp.z))
	mast(k, tp + Vector3(0, 0.45, 0), 8.6, 1.0, 0.45, Color(0.82, 0.84, 0.86), 0.75, 0.06)
	for y in [5.0, 8.2]:
		k.box(Vector3(1.2, 0.05, 1.2), p["metal"].darkened(0.2), at(tp.x, y, tp.z))
		ArchKit.railing(k, tp + Vector3(-0.58, y, 0.58), tp + Vector3(0.58, y, 0.58), 0.6, p["accent"], 0.5)
		ArchKit.railing(k, tp + Vector3(-0.58, y, -0.58), tp + Vector3(-0.58, y, 0.58), 0.6, p["accent"], 0.5)
	for i in 4:
		var a := TAU * i / 4.0 + 0.4
		panel_ant(k, xf(tp + Vector3(cos(a) * 0.55, 8.9, sin(a) * 0.55), Vector3(0, -rad_to_deg(a) + 90.0, 0)), 1.0)
	drum(k, xf(tp + Vector3(0, 6.0, 0.5), Vector3(0, 0, 0)), 0.36)
	drum(k, xf(tp + Vector3(-0.5, 6.8, 0), Vector3(0, -80, 0)), 0.3)
	drum(k, xf(tp + Vector3(0.1, 4.2, 0.48), Vector3(0, 20, 0)), 0.3)
	k.cyl(0.03, 0.9, p["metal"], at(tp.x, 9.1, tp.z), 5)
	ArchKit.beacon(k, tp + Vector3(0, 10.0, 0), 0.2)
	cable_ladder(k, tp + Vector3(-0.5, 4.8, 0.2), Vector3(0.9, top - 0.2, -2.0), 0.3, p["metal"], Color(0.15, 0.15, 0.17))
	# fiber conduits, a lamp
	for i in 3:
		ArchKit.pipes(k, [Vector3(-0.4 + i * 0.12, 0.6, fz + 0.05), Vector3(-0.4 + i * 0.12, 0.13, fz + 0.3), Vector3(-0.4 + i * 0.12, 0.13, 0.2)], 0.03, lit(Color(0.98, 0.64, 0.86), 0.5) if i == 1 else Color(0.98, 0.64, 0.86))
	ArchKit.lamp(k, Vector3(-1.55, 0.1, 2.75), t, 2.8)


## Hyperscale: a graphite edge pylon ringed with glowing data rings.
static func _edge4(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var g: Color = p["wall"]
	var g2: Color = p["wall2"]
	# the podium: graphite with brass seams and glowing fins
	var x0 := -2.85
	var x1 := 2.85
	var zb := -2.85
	var zf := -0.5
	var hp := 1.8
	k.box(Vector3(x1 - x0, hp, zf - zb), g, at(0, 0.1 + hp * 0.5, (zb + zf) * 0.5))
	k.box(Vector3(x1 - x0 + 0.04, 0.05, zf - zb + 0.04), brass, at(0, 0.1 + hp, (zb + zf) * 0.5))
	ArchKit.fins(k, at(-1.4, 0.1, zf), 2.8, hp - 0.1, 8, t)
	ArchKit.door(k, at(1.6, 0.1, zf + 0.02), t, 0.9, 1.6)
	k.box(Vector3(1.0, 0.25, 0.05), p["dark"], at(0.35, 1.4, zf + 0.03))
	text(k, "EDGE", at(0.35, 1.32, zf + 0.06), 0.035, lit(p["glow"], 0.35))
	var top := 0.1 + hp
	ArchKit.parapet(k, Vector3(0, top, (zb + zf) * 0.5), x1 - x0, zf - zb, t)
	# the pylon: a tapering graphite tower with brass bands and glowing seams
	var pp := Vector3(0.95, top, -1.45)
	var ph := 8.4
	k.lathe(PackedVector2Array([Vector2(0.95, 0), Vector2(0.95, 0.4), Vector2(0.62, ph * 0.55), Vector2(0.4, ph), Vector2(0.0, ph + 0.05)]), g2, at(pp.x, pp.y, pp.z), 6)
	for i in 6:
		var a := TAU * i / 6.0
		var b0 := pp + Vector3(cos(a) * 0.93, 0.4, sin(a) * 0.93)
		var b1 := pp + Vector3(cos(a) * 0.4, ph, sin(a) * 0.4)
		beam(k, b0, b1, 0.03, lit(p["accent2"], 0.45))
	for i in 5:
		var y := 1.0 + i * 1.6
		var r := lerpf(0.95, 0.4, clampf(y / ph, 0.0, 1.0))
		k.cyl(r + 0.04, 0.1, brass, at(pp.x, pp.y + y, pp.z), 6)
	# the data rings: glowing hoops orbiting the pylon at a tilt
	for i in 4:
		var y2 := 2.2 + i * 1.7
		var r2 := 1.42 - i * 0.2
		ring(k, pp + Vector3(0, y2, 0), r2, 0.05, lit(p["accent2"] if i % 2 == 0 else p["glow"], 0.4), Vector3(8.0 - i * 5.0, i * 40.0, 6.0), 20)
		for j in 3:
			var a2 := TAU * j / 3.0 + i
			beam(k, pp + Vector3(cos(a2) * 0.6, y2, sin(a2) * 0.6), pp + Vector3(cos(a2) * (r2 - 0.05), y2, sin(a2) * (r2 - 0.05)), 0.03, brass)
	# the crown: brass prongs, a glowing orb, a beacon
	for i in 6:
		var a3 := TAU * i / 6.0
		beam(k, pp + Vector3(cos(a3) * 0.3, ph - 0.3, sin(a3) * 0.3), pp + Vector3(cos(a3) * 0.5, ph + 0.7, sin(a3) * 0.5), 0.05, brass)
	k.sphere(0.28, lit(p["glow"], 0.3), at(pp.x, pp.y + ph + 0.4, pp.z), 8, 5)
	ArchKit.beacon(k, pp + Vector3(0, ph + 0.7, 0), 0.5)
	# a cantilevered pod on the left with a drone pad
	k.box(Vector3(2.0, 1.4, 1.8), g2, at(-1.6, top + 0.9, -1.8))
	k.box(Vector3(2.04, 0.05, 1.84), brass, at(-1.6, top + 1.6, -1.8))
	k.box(Vector3(1.8, 0.35, 0.04), p["glass"], at(-1.6, top + 0.95, -0.89))
	ArchKit.drone_pad(k, Vector3(-1.6, top + 1.62, -1.8), 0.7, t)
	drone(k, Vector3(-1.4, top + 2.4, -1.6), t, 30.0)
	# liquid-cooling loops: glowing coolant pipes out to dry coolers
	var cool := lit(p["accent2"], 0.5)
	for i in 2:
		ArchKit.pipes(k, [Vector3(0.2 + i * 0.2, top + 0.1, -0.8), Vector3(0.2 + i * 0.2, top + 0.6, -0.8), Vector3(pp.x - 0.9, top + 0.6, -1.0 - i * 0.3)], 0.05, cool)
	# glowing fiber conduits out to the street, brass bollards
	for i in 3:
		ArchKit.pipes(k, [Vector3(-0.3 + i * 0.14, 0.6, zf + 0.05), Vector3(-0.3 + i * 0.14, 0.13, zf + 0.3), Vector3(-0.3 + i * 0.14, 0.13, 0.25)], 0.035, lit(Color(0.98, 0.6, 0.86), 0.45))
	for z in [0.4, 1.4, 2.4]:
		k.cyl(0.08, 0.6, g2, at(-2.6, 0.1, z), 6)
		k.box(Vector3(0.17, 0.04, 0.17), lit(p["glow"], 0.35), at(-2.6, 0.7, z))
	ArchKit.lamp(k, Vector3(-1.6, 0.1, 2.7), t, 2.8)


## Edge detail passes.
static func _edge0x(k: MeshKit) -> void:
	var t := 0
	tufts(k, Rect2(-2.9, -2.8, 5.8, 5.6), 40, 11)
	# a ladder leaning on the pole, a lantern, a little generator, a cable drum
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(-1.45 + sx * 0.18, 0.1, -1.7), Vector3(-1.82 + sx * 0.14, 3.0, -1.95), 0.04, Pal.WOOD_LIGHT)
	for i in 9:
		var f := (i + 0.5) / 9.0
		k.box(Vector3(0.34, 0.03, 0.03), Pal.WOOD_LIGHT, at(-1.45 - f * 0.37, 0.1 + f * 2.9, -1.7 - f * 0.25))
	k.cyl(0.05, 0.14, lit(Color(1.0, 0.82, 0.5), 0.35), at(0.15, 0.84, -2.1), 6)
	k.box(Vector3(0.12, 0.02, 0.12), Color(0.2, 0.2, 0.22), at(0.15, 0.99, -2.1))
	k.box(Vector3(0.55, 0.4, 0.38), Color(0.92, 0.72, 0.2), at(-0.6, 0.3, -1.0))
	k.box(Vector3(0.5, 0.06, 0.4), Color(0.2, 0.2, 0.22), at(-0.6, 0.52, -1.0))
	k.cyl(0.03, 0.2, Color(0.3, 0.3, 0.32), at(-0.45, 0.55, -1.1), 5)
	ArchKit.pipes(k, [Vector3(-0.6, 0.2, -0.8), Vector3(-0.2, 0.12, -1.6), Vector3(0.3, 0.12, -2.0)], 0.018, Color(0.95, 0.5, 0.15))
	for sz in [-1.0, 1.0]:
		k.cyl(0.3, 0.04, Pal.WOOD, xf(Vector3(-2.5, 0.4, -0.7 + sz * 0.16), Vector3(90, 0, 0)), 10)
	k.cyl(0.2, 0.32, Color(0.2, 0.2, 0.22), xf(Vector3(-2.5, 0.4, -0.86), Vector3(90, 0, 0)), 10)
	# a doghouse with a bowl, a washing line between pole and fence
	var dh := Vector3(-2.35, 0.1, -2.4)
	k.box(Vector3(0.7, 0.5, 0.6), Color(0.85, 0.35, 0.28), at(dh.x, dh.y + 0.25, dh.z))
	k.prism(PackedVector2Array([Vector2(-0.42, 0), Vector2(0.42, 0), Vector2(0, 0.3)]), 0.7, Color(0.5, 0.36, 0.26), xf(Vector3(dh.x, dh.y + 0.5, dh.z + 0.35), Vector3(-90, 0, 0)))
	k.box(Vector3(0.25, 0.3, 0.02), Color(0.15, 0.12, 0.1), at(dh.x, dh.y + 0.18, dh.z + 0.31))
	k.cyl(0.08, 0.04, Color(0.3, 0.5, 0.8), at(dh.x + 0.4, dh.y, dh.z + 0.5), 8)
	cable(k, Vector3(-1.9, 2.0, -2.0), Vector3(2.8, 1.6, -2.8), 0.25, Color(0.9, 0.9, 0.88), 0.012, 6)
	for i in 4:
		var q := Vector3(-1.9, 2.0, -2.0).lerp(Vector3(2.8, 1.6, -2.8), 0.2 + i * 0.18)
		k.box(Vector3(0.3, 0.35, 0.01), [Color(0.9, 0.3, 0.3), Color(0.95, 0.95, 0.9), Color(0.3, 0.5, 0.85), Color(0.95, 0.8, 0.3)][i], xf(q - Vector3(0, 0.38, 0), Vector3(0, -10, 0)))
	# a gate in a side fence, a gravel path
	ArchKit.fence(k, Vector3(-2.88, 0.1, -2.88), Vector3(-2.88, 0.1, 1.2), t, 1.0)
	for i in 6:
		k.box(Vector3(0.3, 0.02, 0.24), Color(0.66, 0.64, 0.6), xf(Vector3(-1.8 + (i % 2) * 0.12, 0.11, 0.5 + i * 0.4), Vector3(0, i * 23.0, 0)))


static func _edge1x(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var top := 0.28 + 2.5
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.8, 5.9, 5, 5, Color(0.6, 0.6, 0.58))
	# the container roof: ribs, vents, a solar panel, a walkway of grating
	floor_grid(k, Vector3(-0.75, top + 0.01, -1.7), 4.0, 2.2, 14, 1, Color(0.6, 0.3, 0.2))
	ArchKit.solar(k, at(-1.9, top, -1.3), 2, t, 25.0, 0.3)
	for i in 5:
		k.box(Vector3(0.4, 0.03, 0.6), p["metal"].darkened(0.2), at(-0.6 + i * 0.42, top + 0.03, -1.2))
	ArchKit.ac_unit(k, at(0.8, top, -2.3), t, 0.7)
	# tower compound: a fence, cabinets, a cable ladder up, a GPS dome
	ArchKit.fence(k, Vector3(1.45, 0.1, -0.9), Vector3(2.88, 0.1, -0.9), t, 1.6)
	ArchKit.fence(k, Vector3(1.45, 0.1, -0.9), Vector3(1.45, 0.1, -1.5), t, 1.6)
	for i in 2:
		k.box(Vector3(0.45, 1.0, 0.35), Color(0.84, 0.85, 0.86), at(1.75 + i * 0.5, 0.6, -1.2))
		k.box(Vector3(0.3, 0.03, 0.01), lit(p["glow"], 0.3), at(1.75 + i * 0.5, 0.9, -1.02))
	k.box(Vector3(0.03, 6.6, 0.03), Color(0.15, 0.15, 0.17), at(2.0, 3.7, -1.55))
	k.box(Vector3(0.03, 6.6, 0.03), Color(0.15, 0.15, 0.17), at(2.08, 3.7, -1.55))
	k.cyl(0.06, 0.1, Color(0.95, 0.95, 0.94), at(1.7, 1.12, -1.2), 6)
	# a fuel tank beside the generator, drums, an extinguisher cabinet
	htank(k, xf(Vector3(-2.3, 0.1, 2.5), Vector3(0, 0, 0)), 0.25, 0.9, Color(0.9, 0.72, 0.2))
	for i in 3:
		barrel(k, Vector3(-1.62, 0.1, -0.15 + i * 0.4), Color(0.2, 0.36, 0.66), 0.17, 0.55)
	# labels, a meter box and a lamp on the container
	ebox(k, at(-1.4, 1.0, -0.53), p["metal"])
	k.box(Vector3(0.3, 0.1, 0.15), Color(0.2, 0.2, 0.22), at(-2.0, 2.55, -0.47))
	k.box(Vector3(0.24, 0.02, 0.1), lit(p["glow"], 0.35), at(-2.0, 2.5, -0.45))
	cctv(k, at(0.3, 2.5, -0.55))
	for i in 10:
		k.box(Vector3(0.14, 0.08, 0.02), p["accent"] if i % 2 == 0 else p["dark"], at(-2.6 + i * 0.3, 0.38, -0.53))


static func _edge2x(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var top := 0.35 + 3.1
	seams(k, xf(Vector3(0.2, 0.104, 2.95), Vector3(-90, 0, 0)), 5.4, 3.0, 9, 5, p["wall2"])
	# roof: membrane seams, refrigerant pipes, a hatch, cable trays
	floor_grid(k, Vector3(-0.78, top + 0.04, -1.65), 4.0, 2.3, 6, 3, p["wall2"])
	ArchKit.pipes(k, [Vector3(-1.9, top + 0.25, -1.7), Vector3(0.9, top + 0.25, -1.7)], 0.05, Color(0.9, 0.9, 0.92))
	ArchKit.pipes(k, [Vector3(-1.9, top + 0.35, -1.75), Vector3(0.9, top + 0.35, -1.75)], 0.04, Color(0.3, 0.66, 0.68))
	hatch(k, Vector3(0.75, top, -1.0), p["wall2"])
	for i in 4:
		vent(k, Vector3(-2.5 + i * 1.0, top, -0.75), p["metal"], 0.25)
	# façade: panel seams, a canopy over the door, downpipes, lights
	seams(k, at(-0.78, 0.35, -0.44), 4.1, 3.1, 6, 3, p["wall2"])
	k.box(Vector3(1.2, 0.06, 0.6), p["wall"], at(-2.15, 2.5, -0.15))
	k.box(Vector3(1.22, 0.04, 0.04), p["trim"], at(-2.15, 2.47, 0.15))
	for x in [-2.75, 1.2]:
		k.box(Vector3(0.07, 3.0, 0.07), Color(0.9, 0.9, 0.92), at(x, 1.85, -0.38))
	cctv(k, at(0.6, 2.8, -0.45))
	# monopole compound: a white screen fence, a second cabinet, a cable run
	for i in 6:
		k.box(Vector3(0.06, 1.2, 0.06), p["frame"], at(1.5 + i * 0.27, 0.7, -1.2))
	k.box(Vector3(1.4, 0.9, 0.03), p["wall2"], at(2.18, 0.65, -1.2))
	k.box(Vector3(0.5, 1.0, 0.4), p["wall"], at(2.55, 0.6, -2.7))
	ArchKit.pipes(k, [Vector3(2.1, 6.0, -2.0), Vector3(2.1, 0.5, -1.9), Vector3(1.4, 0.5, -1.9)], 0.04, Color(0.2, 0.2, 0.22))
	# planters with trees along the left, a bench, a bin, a bike rack
	hedge(k, Vector3(-2.75, 0.1, -0.25), Vector3(-1.5, 0.1, -0.25), 0.4)
	bin(k, Vector3(-1.4, 0.1, 2.75), p["accent"])
	for i in 3:
		k.torus(0.18, 0.02, p["metal"], xf(Vector3(-1.5, 0.1, 0.6 + i * 0.3), Vector3(0, 90, 90)), 8, 3, PI)


static func _edge3x(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.8, 5.9, 6, 6, p["floor"].darkened(0.12))
	# conduits up the stack, AC units on the upper container's side
	for i in 3:
		ArchKit.pipes(k, [Vector3(0.5 + i * 0.1, 0.4, -0.6), Vector3(0.5 + i * 0.1, 4.9, -0.6)], 0.03, [Color(0.36, 0.6, 0.86), Color(0.9, 0.5, 0.3), Color(0.15, 0.15, 0.17)][i])
	for i in 2:
		k.box(Vector3(0.7, 0.55, 0.35), Color(0.86, 0.87, 0.88), at(-2.4 + i * 0.9, 4.6, -0.48))
		k.cyl(0.2, 0.03, Color(0.22, 0.23, 0.26), xf(Vector3(-2.4 + i * 0.9, 4.6, -0.3), Vector3(90, 0, 0)), 10)
	# a fuel tank and drums behind the generator, a cable trench to the tower
	htank(k, xf(Vector3(2.3, 0.1, -1.0), Vector3(0, 0, 0)), 0.22, 0.8, Color(0.36, 0.4, 0.46))
	k.box(Vector3(0.4, 0.04, 2.0), p["dark"], at(1.55, 0.12, -1.9))
	for i in 5:
		k.box(Vector3(0.42, 0.02, 0.36), p["metal"], at(1.55, 0.15, -2.7 + i * 0.4))
	# barbed-wire fence along the left, floodlights on the stack, a camera
	ArchKit.fence(k, Vector3(-2.88, 0.1, 2.85), Vector3(-2.88, 0.1, -0.4), t, 1.6)
	for i in 3:
		k.torus(0.08, 0.008, Color(0.5, 0.52, 0.56), xf(Vector3(-2.88, 1.75, 2.6 - i * 1.1), Vector3(0, 0, 90)), 6, 3)
	for x in [-2.5, 0.6]:
		k.box(Vector3(0.3, 0.12, 0.2), p["dark"], at(x, 5.2, -0.6))
		k.box(Vector3(0.26, 0.02, 0.12), lit(p["glow"], 0.35), at(x, 5.14, -0.55))
	cctv(k, at(1.3, 2.4, -0.62))
	# roof dressing on the lower container's free end
	roof_dress(k, Rect2(0.95, -2.75, 0.4, 1.9), 2.85, t, 3, [], 0.8)


static func _edge4x(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var top := 1.9
	# podium roof: glowing seams, gear clear of the pylon and pod
	for i in 5:
		k.box(Vector3(5.6, 0.01, 0.02), lit(p["accent2"], 0.5), at(0, top + 0.04, -2.7 + i * 0.5))
	roof_dress(k, Rect2(2.0, -2.8, 0.8, 0.9), top + 0.03, t, 5, [], 0.9)
	# extra panels on the pylon, brass struts, packets of light
	var pp := Vector3(0.95, top, -1.45)
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		var q := pp + Vector3(cos(a) * 0.72, 3.4, sin(a) * 0.72)
		k.box(Vector3(0.4, 1.2, 0.06), p["wall"], xf(q, Vector3(0, -rad_to_deg(a) + 90.0, 0)))
		k.box(Vector3(0.32, 1.05, 0.02), lit(p["accent2"], 0.55), xf(q, Vector3(0, -rad_to_deg(a) + 90.0, 0)) * at(0, 0, 0.04))
	for i in 6:
		var a2 := TAU * i / 6.0
		k.box(Vector3(0.1, 0.1, 0.1), lit(p["glow"] if i % 2 else Color(0.98, 0.6, 0.86), 0.35), at(pp.x + cos(a2) * 0.7, pp.y + 1.0 + i * 1.1, pp.z + sin(a2) * 0.7))
	# dry coolers with glowing pipes along the right edge
	ArchKit.chiller(k, xf(Vector3(2.35, top, -1.0), Vector3(0, 90, 0)), 1.4, t, 1)
	# brass benches, planters, bollards across the front strip
	for x in [-2.4, -1.6]:
		k.box(Vector3(0.6, 0.45, 0.6), p["wall2"], at(x, 0.32, 0.0))
		k.box(Vector3(0.62, 0.03, 0.62), brass, at(x, 0.56, 0.0))
		k.sphere(0.26, Color(0.22, 0.36, 0.26), at(x, 0.8, 0.0), 8, 5)
	k.box(Vector3(0.06, 0.006, 5.6), lit(p["glow"], 0.4), at(-2.85, 0.106, 0.0))


# ---------------------------------------------------------------- Agent Hub (6 x 6 m)
# Robots trundle on the plaza (x within 2.4, z -0.4..2.6, at y 0.12) and
# charge on the three docks at z = 2.0; the building keeps behind z = -0.5.

const HUB_DOCKS := [Vector3(-1.2, 0, 2.0), Vector3(0, 0, 2.0), Vector3(1.2, 0, 2.0)]


static func agent_hub(t: int) -> Mesh:
	var k := MeshKit.new()
	ArchKit.lot(k, 5.9, 5.9, t)
	match clampi(t, 0, 4):
		0: _hub0(k)
		1: _hub1(k)
		2: _hub2(k)
		3: _hub3(k)
		_: _hub4(k)
	match clampi(t, 0, 4):
		0: _hub0x(k)
		1:
			_hub1x(k)
			_hub1y(k)
		2:
			_hub2x(k)
			_hub2y(k)
		3:
			_hub3x(k)
			_hub3y(k)
		_:
			_hub4x(k)
			_hub4y(k)
	_life(k, "agent_hub", clampi(t, 0, 4))
	_finish(k, "agent_hub", clampi(t, 0, 4))
	return k.commit()


## A workflow diagram (boxes joined by lines) on a face, centred.
static func _flow(k: MeshKit, face: Transform3D, w: float, h: float, cols: Array, line: Color, depth := 0.02) -> void:
	var nodes := [Vector2(-0.4, 0.1), Vector2(-0.15, 0.3), Vector2(-0.15, -0.15), Vector2(0.12, 0.1), Vector2(0.38, 0.25), Vector2(0.38, -0.12)]
	for e in [[0, 1], [0, 2], [1, 3], [2, 3], [3, 4], [3, 5]]:
		var a: Vector2 = nodes[e[0]] * Vector2(w, h * 1.6)
		var b: Vector2 = nodes[e[1]] * Vector2(w, h * 1.6)
		var mid := (a + b) * 0.5
		k.box(Vector3(a.distance_to(b), h * 0.025, depth * 0.5), line, face * xf(Vector3(mid.x, mid.y, depth * 0.5), Vector3(0, 0, rad_to_deg(atan2(b.y - a.y, b.x - a.x)))))
	for i in nodes.size():
		var n: Vector2 = nodes[i] * Vector2(w, h * 1.6)
		k.box(Vector3(w * 0.13, h * 0.16, depth), cols[i % cols.size()], face * at(n.x, n.y, depth))


## Garage: a gazebo with a whiteboard, laptops, docks taped on the dirt.
static func _hub0(k: MeshKit) -> void:
	var t := 0
	var wood := Pal.WOOD
	# the gazebo: four posts, braces, a flat tarp roof on rafters
	for sx in [-1.0, 1.0]:
		for z in [-0.6, -2.6]:
			k.box(Vector3(0.12, 2.35, 0.12), wood, at(sx * 1.7, 0.1 + 1.175, z))
			beam(k, Vector3(sx * 1.7, 1.9, z), Vector3(sx * 1.25, 2.38, z), 0.06, wood)
		k.box(Vector3(0.1, 0.16, 2.3), Pal.WOOD_DARK, at(sx * 1.7, 2.4, -1.6))
	for z in [-0.6, -2.6]:
		k.box(Vector3(3.6, 0.16, 0.1), Pal.WOOD_DARK, at(0, 2.4, z))
	for i in 7:
		k.box(Vector3(0.06, 0.08, 2.4), wood, at(-1.65 + i * 0.55, 2.52, -1.6))
	k.box(Vector3(3.75, 0.03, 2.45), Color(0.9, 0.78, 0.42), at(0, 2.58, -1.6))
	for i in 4:
		k.box(Vector3(3.75, 0.035, 0.05), Color(0.82, 0.68, 0.34), at(0, 2.6, -2.7 + i * 0.73))
	ArchKit.string_lights(k, Vector3(-1.7, 2.3, -0.58), Vector3(1.7, 2.3, -0.58), 10)
	# a folding table with laptops and coffee
	table(k, at(0.95, 0.1, -1.7), 1.3, 0.65, Color(0.9, 0.9, 0.88), Color(0.4, 0.42, 0.45))
	laptop(k, xf(Vector3(0.65, 0.84, -1.75), Vector3(0, 175, 0)))
	laptop(k, xf(Vector3(1.2, 0.84, -1.65), Vector3(0, 200, 0)), Color(0.6, 1.0, 0.7))
	for i in 2:
		k.cyl(0.04, 0.1, Color(0.94, 0.94, 0.92), at(0.4 + i * 1.0, 0.84, -1.5), 6)
	chair(k, xf(Vector3(0.75, 0.1, -1.1), Vector3(0, 170, 0)), Color(0.94, 0.94, 0.92))
	chair(k, xf(Vector3(1.4, 0.1, -1.15), Vector3(0, 200, 0)), Color(0.3, 0.6, 0.4))
	# a beanbag, a cardboard robot, a cooler, crates
	k.sphere(0.4, Color(0.85, 0.35, 0.3), xf(Vector3(-1.3, 0.3, -1.3), Vector3.ZERO, Vector3(1.0, 0.6, 1.0)), 10, 5)
	var cb := Color(0.72, 0.58, 0.4)
	k.box(Vector3(0.36, 0.4, 0.3), cb, at(-1.35, 0.3, -2.4))
	k.box(Vector3(0.26, 0.22, 0.24), cb, at(-1.35, 0.61, -2.4))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.05, 0.01), Color(0.2, 0.2, 0.22), at(-1.35 + sx * 0.06, 0.64, -2.275))
		k.box(Vector3(0.06, 0.28, 0.08), cb.darkened(0.1), at(-1.35 + sx * 0.22, 0.32, -2.4))
	k.box(Vector3(0.02, 0.18, 0.02), Color(0.3, 0.3, 0.3), at(-1.35, 0.8, -2.4))
	k.box(Vector3(0.5, 0.35, 0.32), Color(0.2, 0.45, 0.75), at(1.95, 0.28, -0.85))
	k.box(Vector3(0.52, 0.06, 0.34), Color(0.95, 0.95, 0.94), at(1.95, 0.48, -0.85))
	crate(k, xf(Vector3(1.9, 0.1, -2.3), Vector3(0, 10, 0)), 0.45)
	crate(k, xf(Vector3(1.95, 0.46, -2.25), Vector3(0, -8, 0)), 0.35, Color(0.66, 0.52, 0.36))
	# the hand-painted sign on the gazebo
	k.box(Vector3(1.3, 0.34, 0.04), Color(0.95, 0.93, 0.86), xf(Vector3(0.6, 2.1, -0.55), Vector3(0, 0, 2)))
	text(k, "AGENTS", xf(Vector3(0.6, 2.0, -0.53), Vector3(0, 0, 2)), 0.035, Color(0.26, 0.46, 0.78))
	# docks: plywood squares with tape crosses and phone chargers
	for d in HUB_DOCKS:
		k.box(Vector3(0.7, 0.03, 0.7), Color(0.78, 0.64, 0.44), at(d.x, 0.115, d.z))
		k.box(Vector3(0.6, 0.005, 0.06), Color(0.95, 0.8, 0.2), xf(Vector3(d.x, 0.132, d.z), Vector3(0, 45, 0)))
		k.box(Vector3(0.6, 0.005, 0.06), Color(0.95, 0.8, 0.2), xf(Vector3(d.x, 0.132, d.z), Vector3(0, -45, 0)))
		k.box(Vector3(0.12, 0.08, 0.06), Color(0.94, 0.94, 0.92), at(d.x + 0.3, 0.17, d.z + 0.38))
	ArchKit.pipes(k, [Vector3(-1.7, 0.12, -0.6), Vector3(-1.5, 0.12, 2.38), Vector3(1.5, 0.12, 2.38)], 0.018, Color(0.95, 0.5, 0.15))
	# chalk lanes on the dirt
	for i in 4:
		k.box(Vector3(0.6, 0.005, 0.05), Color(0.92, 0.9, 0.84), at(-1.8 + i * 1.2, 0.105, 0.6))
	ArchKit.fence(k, Vector3(-2.88, 0.1, -2.88), Vector3(2.88, 0.1, -2.88), t, 1.0)


## Workshop: a prefab steel shed with robot benches and charging docks.
static func _hub1(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var x0 := -2.25
	var x1 := 2.25
	var zb := -2.85
	var zf := -0.5
	var h := 2.9
	var d := zf - zb
	var shed: Color = p["wall"]
	k.box(Vector3(x1 - x0, h, d), shed, at(0, 0.1 + h * 0.5, (zb + zf) * 0.5))
	ArchKit.corrugated(k, at(-1.5, 0.1, zf), 1.5, h, shed.darkened(0.05))
	ArchKit.corrugated(k, at(1.75, 0.1, zf), 1.0, h, shed.darkened(0.05))
	for sx in [-1.0, 1.0]:
		ArchKit.corrugated(k, xf(Vector3(x1 if sx > 0 else x0, 0.1, (zb + zf) * 0.5), Vector3(0, sx * 90.0, 0)), d, h, shed.darkened(0.05))
	# the open roll-up: a lit workshop inside with robot benches
	k.box(Vector3(2.0, 2.2, 0.04), Color(0.2, 0.21, 0.24), at(0.25, 1.2, zf + 0.02))
	ArchKit.rollup(k, at(0.25, 0.1, zf + 0.04), 2.0, 2.2, p["wall2"], 0.8)
	k.box(Vector3(1.8, 0.05, 0.5), Pal.WOOD_LIGHT, at(0.25, 0.85, zf - 0.35))
	k.box(Vector3(1.8, 0.75, 0.05), p["trim"], at(0.25, 0.45, zf - 0.12))
	for i in 3:
		var x := -0.4 + i * 0.6
		# robot parts: a torso, a head, wheels
		k.box(Vector3(0.2, 0.25, 0.18), Color(0.95, 0.95, 0.94), at(x, 1.0, zf - 0.35))
		k.sphere(0.09, Color(0.95, 0.95, 0.94), at(x + 0.2, 0.96, zf - 0.3), 8, 4)
		k.cyl(0.07, 0.04, Color(0.2, 0.2, 0.22), xf(Vector3(x - 0.18, 0.95, zf - 0.25), Vector3(90, 0, 0)), 8)
		k.box(Vector3(0.12, 0.04, 0.01), lit([Color(0.5, 0.86, 1.0), Color(0.6, 1.0, 0.7), Color(1.0, 0.8, 0.5)][i], 0.35), at(x, 1.05, zf - 0.255))
	# a tool pegboard, a robot arm on a stand
	k.box(Vector3(1.2, 0.6, 0.03), Color(0.8, 0.66, 0.46), at(-0.2, 1.6, zf - 0.6))
	for i in 6:
		k.box(Vector3(0.04, 0.2, 0.02), Color(0.6, 0.62, 0.66) if i % 2 else Color(0.9, 0.3, 0.25), at(-0.65 + i * 0.18, 1.6, zf - 0.58))
	k.cyl(0.1, 0.8, Color(0.96, 0.6, 0.18), at(1.0, 0.1, zf - 0.4), 8)
	beam(k, Vector3(1.0, 0.9, zf - 0.4), Vector3(0.8, 1.4, zf - 0.3), 0.08, Color(0.96, 0.6, 0.18))
	beam(k, Vector3(0.8, 1.4, zf - 0.3), Vector3(0.6, 1.1, zf - 0.2), 0.06, Color(0.96, 0.6, 0.18))
	# the side door, a window, the sign
	ArchKit.door(k, at(-1.6, 0.1, zf + 0.02), t, 0.8, 1.95)
	k.box(Vector3(0.6, 0.45, 0.04), p["glass"], at(-0.8, 1.6, zf + 0.04))
	k.box(Vector3(1.6, 0.4, 0.05), p["accent"], at(0.25, 2.62, zf + 0.04))
	text(k, "AGENTS", at(0.25, 2.5, zf + 0.07), 0.04, p["dark"])
	# the roof: trim, AC units, a cable tray
	var top := 0.1 + h
	k.box(Vector3(x1 - x0 + 0.1, 0.12, d + 0.1), p["trim"], at(0, top + 0.06, (zb + zf) * 0.5))
	k.box(Vector3(x1 - x0 - 0.1, 0.02, d - 0.1), p["roof"], at(0, top + 0.12, (zb + zf) * 0.5))
	ArchKit.ac_unit(k, at(-1.4, top + 0.12, -2.3), t, 0.8)
	ArchKit.ac_unit(k, at(1.4, top + 0.12, -2.3), t, 0.8)
	ArchKit.cable_tray(k, Vector3(-2.0, top + 0.3, -1.25), Vector3(2.0, top + 0.3, -1.25), t)
	# the overhead cable gantry across the plaza feeding the docks
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.12, 2.7, 0.12), p["accent"], at(sx * 2.45, 1.45, 0.5))
		k.box(Vector3(0.3, 0.1, 0.3), Color(0.6, 0.6, 0.6), at(sx * 2.45, 0.15, 0.5))
	ArchKit.cable_tray(k, Vector3(-2.45, 2.8, 0.5), Vector3(2.45, 2.8, 0.5), t)
	ArchKit.cable_tray(k, Vector3(0.0, 2.8, zf), Vector3(0.0, 2.8, 0.5), t)
	# docks: hazard-striped pads, charging posts with arms and lights
	for d2 in HUB_DOCKS:
		k.box(Vector3(0.8, 0.03, 0.8), Color(0.3, 0.31, 0.33), at(d2.x, 0.115, d2.z))
		for i in 4:
			k.box(Vector3(0.8, 0.006, 0.08), p["accent"], xf(Vector3(d2.x, 0.132, d2.z - 0.3 + i * 0.2), Vector3(0, 0, 0)))
		k.box(Vector3(0.18, 1.0, 0.16), Color(0.92, 0.92, 0.9), at(d2.x, 0.6, d2.z + 0.52))
		k.box(Vector3(0.1, 0.06, 0.01), lit(p["glow"], 0.3), at(d2.x, 0.95, d2.z + 0.44))
		beam(k, Vector3(d2.x, 0.95, d2.z + 0.45), Vector3(d2.x, 0.5, d2.z + 0.25), 0.03, Color(0.15, 0.15, 0.17))
		ArchKit.pipes(k, [Vector3(d2.x, 1.1, d2.z + 0.52), Vector3(d2.x, 2.8, 0.5 if d2.x != 0.0 else 0.6)], 0.025, Color(0.15, 0.15, 0.17))
	# yellow lane lines and arrows
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.08, 0.005, 2.8), p["accent"], at(sx * 2.25, 0.105, 1.1))
	for i in 3:
		k.box(Vector3(0.3, 0.005, 0.08), Color(0.95, 0.95, 0.94), xf(Vector3(-0.1, 0.106, 0.2 + i * 0.5), Vector3(0, 45, 0)))
		k.box(Vector3(0.3, 0.005, 0.08), Color(0.95, 0.95, 0.94), xf(Vector3(0.1, 0.106, 0.2 + i * 0.5), Vector3(0, -45, 0)))
	# a parts container at the side, a fire extinguisher
	k.box(Vector3(0.12, 0.35, 0.12), Color(0.85, 0.15, 0.15), at(-2.0, 0.28, zf + 0.15))


## Campus: a white pavilion whose face is a giant workflow screen.
static func _hub2(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var x0 := -2.2
	var x1 := 2.2
	var zb := -2.85
	var zf := -0.55
	var h := 3.4
	var d := zf - zb
	# the glass box: curtain walls on the sides and back
	k.box(Vector3(x1 - x0, 0.15, d), p["floor"], at(0, 0.17, (zb + zf) * 0.5))
	for sx in [-1.0, 1.0]:
		ArchKit.curtain(k, xf(Vector3(x1 if sx > 0 else x0, 0.1, (zb + zf) * 0.5), Vector3(0, sx * 90.0, 0)), d, h, t, 4, 3)
	k.box(Vector3(x1 - x0, h, 0.2), p["wall"], at(0, 0.1 + h * 0.5, zb + 0.1))
	# the giant workflow screen as the façade
	k.box(Vector3(x1 - x0, h, 0.12), p["wall"], at(0, 0.1 + h * 0.5, zf - 0.06))
	k.box(Vector3(3.9, 2.5, 0.06), p["dark"], at(0, 1.75, zf + 0.03))
	k.box(Vector3(3.8, 2.4, 0.02), lit(Color(0.16, 0.26, 0.38), 0.7), at(0, 1.75, zf + 0.065))
	_flow(k, at(0, 1.75, zf + 0.07), 3.6, 1.4, [lit(Color(0.5, 0.86, 1.0), 0.4), lit(Color(0.6, 1.0, 0.7), 0.4), lit(Color(1.0, 0.8, 0.5), 0.4)], lit(Color(0.9, 0.95, 1.0), 0.35), 0.02)
	k.box(Vector3(3.6, 0.12, 0.01), lit(Color(0.5, 0.86, 1.0), 0.45), at(0, 2.82, zf + 0.08))
	k.box(Vector3(3.92, 0.06, 0.1), p["trim"], at(0, 0.48, zf + 0.04))
	# the roof: a thin white canopy with a teal fascia, solar and a screen
	var top := 0.1 + h
	k.box(Vector3(x1 - x0 + 0.6, 0.18, d + 0.5), p["wall"], at(0, top + 0.09, (zb + zf) * 0.5 + 0.2))
	k.box(Vector3(x1 - x0 + 0.62, 0.1, 0.04), p["trim"], at(0, top + 0.08, zf + 0.46))
	k.box(Vector3(x1 - x0 + 0.62, 0.03, 0.03), lit(p["glow"], 0.4), at(0, top - 0.02, zf + 0.46))
	ArchKit.solar(k, at(-1.2, top + 0.18, -2.3), 2, t, 22.0, 0.35)
	ArchKit.solar(k, at(1.2, top + 0.18, -2.3), 2, t, 22.0, 0.35)
	ArchKit.ac_unit(k, at(0.0, top + 0.18, -2.4), t, 0.7)
	# white docking pods with teal rings
	for d2 in HUB_DOCKS:
		k.cyl(0.4, 0.03, Color(0.92, 0.93, 0.94), at(d2.x, 0.1, d2.z), 12)
		ring(k, Vector3(d2.x, 0.135, d2.z), 0.33, 0.02, lit(p["glow"], 0.4), Vector3.ZERO, 14)
		k.rbox(Vector3(0.36, 0.9, 0.2), 0.08, Color(0.97, 0.97, 0.98), at(d2.x, 0.55, d2.z + 0.5), 1)
		k.box(Vector3(0.2, 0.3, 0.01), lit(p["glow"], 0.4), at(d2.x, 0.7, d2.z + 0.395))
	# planters and benches along the plaza sides, a lamp
	for sx in [-1.0, 1.0]:
		ArchKit.planter(k, Vector3(sx * 2.55, 0.1, 0.55), t, 0.6, true)
	k.box(Vector3(1.2, 0.05, 0.35), Pal.WOOD_LIGHT, at(-1.3, 0.48, -0.2))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.38, 0.3), p["wall2"], at(-1.3 + sx * 0.55, 0.29, -0.2))
	for i in 4:
		k.box(Vector3(4.6, 0.005, 0.04), p["wall2"], at(0, 0.106, 0.0 + i * 0.8))


## Industrial: a robot depot hall, an overhead conveyor and a gantry crane.
static func _hub3(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var x0 := -2.25
	var x1 := 2.25
	var zb := -2.85
	var zf := -0.45
	var h := 3.4
	var d := zf - zb
	k.box(Vector3(x1 - x0, h, d), p["wall"], at(0, 0.1 + h * 0.5, (zb + zf) * 0.5))
	# three open bays with racks of robots charging inside
	for i in 3:
		var x := -1.45 + i * 1.45
		k.box(Vector3(1.15, 1.9, 0.04), Color(0.08, 0.09, 0.11), at(x, 1.05, zf + 0.02))
		for j in 2:
			k.box(Vector3(1.0, 0.04, 0.3), p["metal"], at(x, 0.5 + j * 0.8, zf - 0.15))
			for q in 3:
				k.box(Vector3(0.18, 0.3, 0.16), Color(0.92, 0.92, 0.9), at(x - 0.32 + q * 0.32, 0.67 + j * 0.8, zf - 0.15))
				k.box(Vector3(0.1, 0.03, 0.01), lit(p["glow"], 0.3), at(x - 0.32 + q * 0.32, 0.72 + j * 0.8, zf - 0.065))
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.1, 2.0, 0.1), p["accent"], at(x + sx * 0.6, 1.1, zf + 0.05))
		k.box(Vector3(1.3, 0.12, 0.12), p["trim"], at(x, 2.06, zf + 0.06))
		k.box(Vector3(1.0, 0.03, 0.02), lit(p["accent2"], 0.4), at(x, 2.0, zf + 0.13))
	# the upper face: louvres, a sign, blue LED strip
	ArchKit.louvres(k, at(-1.2, 2.3, zf + 0.02), 1.6, 0.8, p["metal"], 6)
	ArchKit.sign(k, at(1.0, 2.35, zf + 0.04), 1.8, 0.5, t)
	text(k, "DEPOT", at(1.0, 2.5, zf + 0.14), 0.04, lit(Color(0.7, 0.9, 1.0), 0.35))
	for sx in [-1.0, 1.0]:
		ArchKit.louvres(k, xf(Vector3(x1 if sx > 0 else x0, 0.8, -1.2), Vector3(0, sx * 90.0, 0)), 0.9, 1.6, p["wall2"], 8)
	var top := 0.1 + h
	ArchKit.parapet(k, Vector3(0, top, (zb + zf) * 0.5), x1 - x0, d, t)
	ArchKit.chiller(k, at(-1.35, top, -2.3), 1.4, t, 1)
	ArchKit.chiller(k, at(1.35, top, -2.3), 1.4, t, 1)
	# the overhead conveyor along the hall's face, boxes riding on it
	var cy := 2.95
	k.box(Vector3(4.6, 0.12, 0.45), p["trim"], at(0, cy, zf + 0.35))
	for i in 20:
		k.box(Vector3(0.03, 0.05, 0.42), p["metal"], at(-2.2 + i * 0.23, cy + 0.08, zf + 0.35))
	for i in 5:
		crate(k, at(-1.9 + i * 0.95, cy + 0.1, zf + 0.35), 0.3, Color(0.86, 0.62, 0.32))
	for x in [-2.0, 0.0, 2.0]:
		beam(k, Vector3(x, cy - 0.05, zf + 0.5), Vector3(x, cy - 0.6, zf + 0.02), 0.06, p["trim"])
	# the gantry crane over the plaza: rails, a bridge, a trolley and hook
	var gy := 3.9
	for sx in [-1.0, 1.0]:
		var x: float = sx * 2.45
		k.box(Vector3(0.2, gy, 0.2), p["accent"], at(x, gy * 0.5 + 0.1, 0.6))
		k.box(Vector3(0.4, 0.15, 0.4), Color(0.5, 0.5, 0.52), at(x, 0.17, 0.6))
		k.box(Vector3(0.2, 0.25, 3.3), p["accent"], at(x, gy + 0.2, 0.85))
		beam(k, Vector3(x, gy - 0.8, 0.6), Vector3(x, gy + 0.1, -0.2), 0.08, p["accent"])
		beam(k, Vector3(x, gy - 0.8, 0.6), Vector3(x, gy + 0.1, 1.4), 0.08, p["accent"])
	var bz := 1.4
	k.box(Vector3(5.1, 0.35, 0.3), p["accent"], at(0, gy + 0.5, bz))
	for i in 12:
		k.box(Vector3(0.04, 0.33, 0.04), p["accent"].darkened(0.2), xf(Vector3(-2.3 + i * 0.42, gy + 0.5, bz + 0.16), Vector3(0, 0, 40 if i % 2 else -40)))
	for i in 9:
		k.box(Vector3(0.18, 0.004, 0.32), p["dark"], at(-2.4 + i * 0.6, gy + 0.68, bz))
	k.box(Vector3(0.6, 0.35, 0.5), p["dark"], at(0.6, gy + 0.18, bz))
	k.box(Vector3(0.3, 0.03, 0.01), lit(p["glow"], 0.4), at(0.6, gy + 0.18, bz + 0.255))
	k.box(Vector3(0.015, 1.2, 0.015), Color(0.2, 0.2, 0.22), at(0.55, gy - 0.6, bz))
	k.box(Vector3(0.015, 1.2, 0.015), Color(0.2, 0.2, 0.22), at(0.65, gy - 0.6, bz))
	k.box(Vector3(0.3, 0.15, 0.12), p["accent"], at(0.6, gy - 1.25, bz))
	k.box(Vector3(0.06, 0.2, 0.06), Color(0.3, 0.3, 0.32), at(0.6, gy - 1.43, bz))
	# industrial docks: steel arches with blue rings over striped pads
	for d2 in HUB_DOCKS:
		k.box(Vector3(0.8, 0.03, 0.8), p["dark"], at(d2.x, 0.115, d2.z))
		for i in 4:
			k.box(Vector3(0.1, 0.006, 0.8), p["accent"], at(d2.x - 0.3 + i * 0.2, 0.132, d2.z))
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.08, 1.2, 0.08), p["metal"], at(d2.x + sx * 0.42, 0.7, d2.z + 0.45))
		k.box(Vector3(0.92, 0.08, 0.1), p["metal"], at(d2.x, 1.3, d2.z + 0.45))
		k.box(Vector3(0.6, 0.03, 0.03), lit(p["glow"], 0.35), at(d2.x, 1.24, d2.z + 0.4))
		ring(k, Vector3(d2.x, 0.14, d2.z), 0.32, 0.018, lit(p["glow"], 0.4), Vector3.ZERO, 14)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.08, 0.006, 3.0), p["accent"], at(sx * 2.25, 0.106, 1.1))


## Hyperscale: a graphite hive with glowing hex docking bays and drones.
static func _hub4(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var g: Color = p["wall"]
	var g2: Color = p["wall2"]
	var brass: Color = p["trim"]
	var x0 := -2.25
	var x1 := 2.25
	var zb := -2.85
	var zf := -0.45
	var h := 3.2
	var d := zf - zb
	k.box(Vector3(x1 - x0, h, d), g, at(0, 0.1 + h * 0.5, (zb + zf) * 0.5))
	# the honeycomb façade: hex cells, the low ones are docking bays
	var cols := 7
	for r in 3:
		for c in cols:
			if r == 2 and (c == 0 or c == cols - 1):
				continue
			var x := -1.8 + c * 0.6 + (0.3 if r % 2 else 0.0)
			if absf(x) > 2.0:
				continue
			var y := 0.65 + r * 0.95
			var cell := xf(Vector3(x, y, zf), Vector3(90, 0, 0))
			k.cyl(0.33, 0.14, g2, cell, 6)
			k.cyl(0.26, 0.02, lit(p["accent2"] if (r + c) % 3 else p["glow"], 0.45 if r > 0 else 0.35), cell * at(0, 0.14, 0), 6)
			k.torus(0.3, 0.02, brass, cell * at(0, 0.15, 0), 6, 3)
	k.box(Vector3(x1 - x0 + 0.04, 0.06, 0.06), brass, at(0, 0.1, zf + 0.03))
	var top := 0.1 + h
	ArchKit.parapet(k, Vector3(0, top, (zb + zf) * 0.5), x1 - x0, d, t)
	# two hex towers at the back corners with drone pads
	for sx in [-1.0, 1.0]:
		var tp := Vector3(sx * 1.55, top, -2.2)
		k.cyl(0.66, 2.4, g2, at(tp.x, tp.y, tp.z), 6)
		for i in 3:
			k.cyl(0.68, 0.05, brass, at(tp.x, tp.y + 0.6 + i * 0.7, tp.z), 6)
			k.cyl(0.67, 0.03, lit(p["glow"], 0.4), at(tp.x, tp.y + 0.85 + i * 0.7, tp.z), 6)
		ArchKit.drone_pad(k, tp + Vector3(0, 2.42, 0), 0.55, t)
		drone(k, tp + Vector3(0.1, 3.1, 0.1), t, sx * 30.0)
	# a crown between the towers
	k.cyl(0.25, 1.4, g2, at(0, top, -2.55), 6)
	for i in 6:
		var a := TAU * i / 6.0
		beam(k, Vector3(cos(a) * 0.18, top + 1.3, -2.55 + sin(a) * 0.18), Vector3(cos(a) * 0.35, top + 1.9, -2.55 + sin(a) * 0.35), 0.04, brass)
	k.sphere(0.18, lit(p["glow"], 0.3), at(0, top + 1.75, -2.55), 8, 5)
	ArchKit.beacon(k, Vector3(0, top + 1.95, -2.55), 0.3)
	# a glowing ring canopy over the docks on brass arms
	ring(k, Vector3(0, 3.3, 1.2), 1.7, 0.06, lit(p["accent2"], 0.4), Vector3.ZERO, 24)
	ring(k, Vector3(0, 3.36, 1.2), 1.55, 0.03, brass, Vector3.ZERO, 24)
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(sx * 1.2, top - 0.3, zf), Vector3(sx * 1.2, 3.3, 0.0), 0.08, brass)
	# drones hovering over the plaza
	for i in 4:
		drone(k, Vector3(-1.5 + i * 1.0, 2.5 + (i % 2) * 0.6, 0.3 + (i % 3) * 0.6), t, i * 37.0)
	# graphite docking pods with glowing rings
	for d2 in HUB_DOCKS:
		k.cyl(0.42, 0.03, g2, at(d2.x, 0.1, d2.z), 6)
		ring(k, Vector3(d2.x, 0.135, d2.z), 0.34, 0.025, lit(p["glow"], 0.35), Vector3.ZERO, 12)
		k.box(Vector3(0.3, 1.0, 0.2), g2, at(d2.x, 0.6, d2.z + 0.52))
		k.box(Vector3(0.32, 0.04, 0.22), brass, at(d2.x, 1.1, d2.z + 0.52))
		k.box(Vector3(0.04, 0.8, 0.01), lit(p["accent2"], 0.4), at(d2.x, 0.6, d2.z + 0.415))
	for i in 5:
		k.box(Vector3(4.6, 0.006, 0.03), lit(p["accent2"], 0.5), at(0, 0.106, -0.2 + i * 0.7))


## Agent Hub detail passes.
static func _hub0x(k: MeshKit) -> void:
	var t := 0
	tufts(k, Rect2(-2.8, -2.8, 5.6, 5.6), 36, 21)
	# the whiteboard rolled out to the front of the gazebo, facing the plaza
	var wb := xf(Vector3(-1.0, 0.1, -0.85), Vector3(0, 6, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 1.7, 0.05), Color(0.6, 0.62, 0.64), wb * at(sx * 0.75, 0.85, 0))
		k.box(Vector3(0.3, 0.04, 0.3), Color(0.6, 0.62, 0.64), wb * at(sx * 0.75, 0.02, 0))
	k.box(Vector3(1.6, 0.95, 0.04), Color(0.97, 0.97, 0.96), wb * at(0, 1.25, 0.04))
	k.box(Vector3(1.66, 0.04, 0.08), Color(0.6, 0.62, 0.64), wb * at(0, 0.76, 0.08))
	_flow(k, wb * at(0, 1.25, 0.065), 1.4, 0.75, [Color(0.95, 0.85, 0.3), Color(0.95, 0.55, 0.7), Color(0.5, 0.8, 0.95)], Color(0.2, 0.3, 0.6), 0.015)
	for i in 4:
		k.box(Vector3(0.1, 0.1, 0.01), [Color(0.95, 0.85, 0.3), Color(0.6, 0.9, 0.5), Color(0.95, 0.55, 0.7)][i % 3], wb * at(0.95, 0.9 + i * 0.13, 0.03))
	# a striped canvas over the gazebo tarp, a sagging edge
	for i in 6:
		k.box(Vector3(0.3, 0.012, 2.45), Color(0.85, 0.35, 0.3), at(-1.55 + i * 0.62, 2.6, -1.6))
	for i in 7:
		k.box(Vector3(0.5, 0.18, 0.02), Color(0.9, 0.78, 0.42) if i % 2 == 0 else Color(0.85, 0.35, 0.3), at(-1.5 + i * 0.5, 2.45, -0.43))
	# chalk on the plaza: a robot lane loop, arrows, a smiley
	for i in 10:
		var a := TAU * i / 10.0
		k.box(Vector3(0.3, 0.004, 0.04), Color(0.92, 0.9, 0.84), xf(Vector3(cos(a) * 1.5, 0.104, 1.0 + sin(a) * 0.8), Vector3(0, -rad_to_deg(a) + 90.0, 0)))
	k.torus(0.25, 0.015, Color(0.95, 0.85, 0.3), at(-1.9, 0.104, 0.0), 10, 3)
	# side strips: crates, a cooler, a bike, potted plants, a stool
	crate(k, xf(Vector3(2.6, 0.1, -0.9), Vector3(0, 12, 0)), 0.4)
	crate(k, xf(Vector3(2.6, 0.1, -0.2), Vector3(0, -8, 0)), 0.36, Color(0.66, 0.52, 0.36))
	k.box(Vector3(0.5, 0.35, 0.32), Color(0.85, 0.35, 0.3), at(-2.6, 0.28, -0.6))
	k.box(Vector3(0.52, 0.06, 0.34), Color(0.95, 0.95, 0.94), at(-2.6, 0.48, -0.6))
	bike(k, xf(Vector3(-2.6, 0.1, 0.5), Vector3(0, 0, 0)), Color(0.3, 0.6, 0.85))
	for p in [Vector3(-2.6, 0.1, -2.5), Vector3(2.6, 0.1, -2.5)]:
		k.cyl(0.18, 0.3, Pal.TERRACOTTA, at(p.x, p.y, p.z), 8, 0.0, 0.22)
		shrub(k, p + Vector3(0, 0.3, 0), 0.22)
	# a sign: robots at play
	k.box(Vector3(0.05, 1.1, 0.05), Pal.WOOD_DARK, at(2.65, 0.65, 0.6))
	k.box(Vector3(0.45, 0.45, 0.03), Color(0.95, 0.8, 0.2), xf(Vector3(2.65, 1.25, 0.6), Vector3(0, -90, 45)))
	k.box(Vector3(0.14, 0.2, 0.01), Color(0.15, 0.15, 0.15), xf(Vector3(2.63, 1.25, 0.6), Vector3(0, -90, 0)))


static func _hub1x(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var top := 0.1 + 2.9 + 0.12
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.8, 3.5, 6, 4, Color(0.6, 0.6, 0.58))
	roof_dress(k, Rect2(-2.1, -2.05, 4.2, 1.4), top, t, 31, slot_rects("agent_hub", t, true), 0.45)
	floor_grid(k, Vector3(0, top + 0.005, -1.7), 4.3, 2.2, 8, 1, p["roof"].darkened(0.1))
	wall_dress(k, at(-1.5, 0.1, -0.47), 1.4, 2.8, t, 2)
	wall_dress(k, at(1.75, 0.1, -0.47), 0.9, 2.8, t, 3)
	# a "charging" board over the docks, chevrons in the lanes
	k.box(Vector3(1.6, 0.35, 0.05), p["accent"], at(0, 2.45, 0.5))
	text(k, "CHARGE", at(0, 2.33, 0.53), 0.035, p["dark"])
	for i in 4:
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.28, 0.005, 0.07), p["accent"], xf(Vector3(sx * 1.7 + 0.1, 0.106, -0.1 + i * 0.5), Vector3(0, 45, 0)))
			k.box(Vector3(0.28, 0.005, 0.07), p["accent"], xf(Vector3(sx * 1.7 - 0.1, 0.106, -0.1 + i * 0.5), Vector3(0, -45, 0)))
	# side strips: parts shelving, IBC, cones, a tool cart
	shelving(k, xf(Vector3(2.75, 0.1, -0.85), Vector3(0, -90, 0)), 0.6, 1.4, 3, p["trim"], [Color(0.95, 0.95, 0.94), Color(0.3, 0.5, 0.8), Color(0.9, 0.6, 0.2)])
	ibc(k, at(-2.42, 0.1, -0.85))
	cone(k, Vector3(-2.6, 0.1, 0.2))
	cone(k, Vector3(2.6, 0.1, 0.4))
	k.box(Vector3(0.5, 0.6, 0.35), Color(0.85, 0.2, 0.18), at(2.6, 0.4, -2.55))
	for j in 3:
		k.box(Vector3(0.46, 0.02, 0.02), Color(0.3, 0.3, 0.32), at(2.6, 0.25 + j * 0.15, -2.37))
	k.box(Vector3(0.5, 0.9, 0.3), Color(0.6, 0.62, 0.64), at(-2.6, 0.55, -2.55))
	k.box(Vector3(0.3, 0.03, 0.01), lit(p["glow"], 0.3), at(-2.6, 0.8, -2.39))


static func _hub2x(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var top := 0.1 + 3.4 + 0.18
	# plaza paving: a ring pattern and joints
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.4, 3.4, 9, 6, p["wall2"])
	ring(k, Vector3(0, 0.104, 1.0), 1.4, 0.03, p["trim"], Vector3.ZERO, 24)
	roof_dress(k, Rect2(-2.3, -1.9, 4.6, 1.3), top, t, 41, slot_rects("agent_hub", t, true), 0.55)
	# slim white columns at the canopy corners, downlights
	for sx in [-1.0, 1.0]:
		k.cyl(0.07, 3.4, Color(0.96, 0.96, 0.97), at(sx * 2.42, 0.1, -0.15), 8)
	for i in 5:
		k.box(Vector3(0.2, 0.02, 0.2), lit(p["glow"], 0.4), at(-1.8 + i * 0.9, 3.47, -0.2))
	# the glass sides: people inside at desks
	for sx in [-1.0, 1.0]:
		for i in 2:
			k.box(Vector3(0.4, 0.04, 0.6), Color(0.96, 0.96, 0.97), at(sx * 1.7, 0.8, -1.4 - i * 0.8))
			k.box(Vector3(0.04, 0.25, 0.35), p["dark"], at(sx * 1.85, 1.0, -1.4 - i * 0.8))
	# side strips: benches, an info kiosk, trees, bins
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.35, 0.05, 0.9), Pal.WOOD_LIGHT, at(sx * 2.65, 0.48, -0.55))
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.3, 0.38, 0.05), p["wall2"], at(sx * 2.65, 0.29, -0.55 + sz * 0.4))
		shrub(k, Vector3(sx * 2.5, 0.1, -2.5), 0.3, 0.9)
		bin(k, Vector3(sx * 2.65, 0.1, 1.05), p["accent"])
	k.box(Vector3(0.5, 1.5, 0.2), Color(0.97, 0.97, 0.98), at(2.6, 0.85, 0.3))
	k.box(Vector3(0.4, 0.9, 0.02), lit(Color(0.5, 0.86, 1.0), 0.45), at(2.6, 1.0, 0.41))


static func _hub3x(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var top := 0.1 + 3.4
	roof_dress(k, Rect2(-2.1, -1.65, 4.2, 1.0), top, t, 51, slot_rects("agent_hub", t, true), 0.7)
	floor_grid(k, Vector3(0, top + 0.035, -1.7), 4.3, 2.2, 6, 3, p["roof"].darkened(0.15))
	# steel floor plates and chevrons in the plaza
	for i in 5:
		for j in 3:
			k.box(Vector3(0.85, 0.008, 0.85), p["floor"].darkened(0.08 if (i + j) % 2 else 0.0), at(-1.9 + i * 0.95, 0.105, 0.0 + j * 0.95))
	for i in 3:
		k.box(Vector3(0.3, 0.006, 0.08), p["accent"], xf(Vector3(-0.1, 0.11, 0.0 + i * 0.5), Vector3(0, 45, 0)))
		k.box(Vector3(0.3, 0.006, 0.08), p["accent"], xf(Vector3(0.1, 0.11, 0.0 + i * 0.5), Vector3(0, -45, 0)))
	# robot arms working in the bays
	for i in 3:
		var x := -1.45 + i * 1.45
		k.cyl(0.08, 0.3, Color(0.96, 0.6, 0.18), at(x + 0.35, 1.32, -0.75), 8)
		beam(k, Vector3(x + 0.35, 1.6, -0.75), Vector3(x + 0.1, 1.85, -0.7), 0.06, Color(0.96, 0.6, 0.18))
		beam(k, Vector3(x + 0.1, 1.85, -0.7), Vector3(x - 0.15, 1.65, -0.68), 0.05, Color(0.96, 0.6, 0.18))
	# side strips: parts racks, a charging cabinet, a fire point
	shelving(k, xf(Vector3(2.75, 0.1, -0.9), Vector3(0, -90, 0)), 0.65, 1.6, 4, p["trim"], [Color(0.95, 0.95, 0.94), p["accent2"], Color(0.9, 0.6, 0.2)])
	shelving(k, xf(Vector3(-2.75, 0.1, -0.9), Vector3(0, 90, 0)), 0.65, 1.6, 4, p["trim"], [Color(0.95, 0.95, 0.94), p["accent2"], Color(0.9, 0.6, 0.2)])
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.5, 1.2, 0.4), p["dark"], at(sx * 2.6, 0.7, -2.55))
		for j in 4:
			k.box(Vector3(0.36, 0.02, 0.01), lit(p["glow"], 0.35), at(sx * 2.6, 0.4 + j * 0.2, -2.345))
	wall_dress(k, xf(Vector3(2.25, 0.1, -1.7), Vector3(0, 90, 0)), 2.2, 3.4, t, 4)
	wall_dress(k, xf(Vector3(-2.25, 0.1, -1.7), Vector3(0, -90, 0)), 2.2, 3.4, t, 5)


static func _hub4x(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var top := 0.1 + 3.2
	roof_dress(k, Rect2(-0.8, -1.4, 1.6, 0.9), top, t, 61, slot_rects("agent_hub", t, true), 0.8)
	# glowing hex tiles in the plaza
	for i in 6:
		for j in 4:
			var x := -2.0 + i * 0.8 + (0.4 if j % 2 else 0.0)
			if absf(x) > 2.3:
				continue
			k.torus(0.32, 0.012, lit(p["accent2"], 0.55), at(x, 0.107, -0.1 + j * 0.7), 6, 3)
	# window slits up the hex towers, drones parked on the roof
	for sx in [-1.0, 1.0]:
		for i in 3:
			var a := PI * 0.5 + (i - 1) * 0.6
			k.box(Vector3(0.1, 1.8, 0.02), lit(p["glow"], 0.45), xf(Vector3(sx * 1.55 + cos(a) * 0.67, top + 1.2, -2.2 + sin(a) * 0.67), Vector3(0, -rad_to_deg(a) + 90.0, 0)))
	for i in 3:
		drone(k, Vector3(-0.6 + i * 0.6, top + 0.08, -0.8), t, i * 25.0)
	# brass planters with dark shrubs and glow bollards on the sides
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.6, 0.45, 0.6), p["wall2"], at(sx * 2.6, 0.32, -0.6))
		k.box(Vector3(0.62, 0.03, 0.62), brass, at(sx * 2.6, 0.56, -0.6))
		k.sphere(0.26, Color(0.22, 0.36, 0.26), at(sx * 2.6, 0.8, -0.6), 8, 5)
		k.cyl(0.08, 0.6, p["wall2"], at(sx * 2.65, 0.1, 0.6), 6)
		k.box(Vector3(0.17, 0.04, 0.17), lit(p["glow"], 0.35), at(sx * 2.65, 0.7, 0.6))
		k.box(Vector3(0.5, 1.1, 0.4), p["wall2"], at(sx * 2.6, 0.65, -2.55))
		k.box(Vector3(0.04, 0.9, 0.01), lit(p["accent2"], 0.45), at(sx * 2.6, 0.65, -2.345))


## A little agent robot (it trundles around the hub's plaza).
static func agent_bot(c: Color) -> Mesh:
	var k := MeshKit.new()
	k.cyl(0.18, 0.1, Color(0.24, 0.25, 0.28), MeshKit.at(0, 0.02, 0), 12)
	k.capsule(0.15, 0.36, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.1, 0), 10, 3)
	k.sphere(0.14, Color(0.95, 0.95, 0.94), MeshKit.at(0, 0.56, 0), 10, 6)
	k.rbox(Vector3(0.18, 0.06, 0.02), 0.02, lit(c), MeshKit.at(0, 0.57, 0.13))
	k.cyl(0.012, 0.16, Pal.STEEL_DARK, MeshKit.at(0, 0.68, 0), 4)
	k.sphere(0.03, lit(c), MeshKit.at(0, 0.85, 0), 6, 4)
	return k.commit()


# ---------------------------------------------------------------- Training Cluster (8 x 8 m)
# Anchors (TrainerB): six rack columns at x = -2.5..2.5, z = -1.5, GPU trays
# at y = 0.45 + row * 0.42; the GPU hatch at (0, 2.4, -1.6); the input table
# at z = 1.0 (tops at y 0.45, x -3.2..1.2); the power stand at (3.2, 1.6, 2.4);
# the loss screen at trainer_screen(t); roof slots on the back strip at
# z = -3.75 (x -2.6, 0, 2.6). Everything in front of the racks stays low or
# high enough that the racks show from the camera.

## Where TrainerB draws the loss curve (it spans x +-1.8, y -0.6..0.7).
static func trainer_screen(t: int) -> Vector3:
	return [Vector3(0.6, 2.15, -3.25), Vector3(0.6, 5.05, 0.16), Vector3(0.6, 5.35, 0.36), Vector3(0.6, 5.85, 0.26), Vector3(0.6, 6.15, 0.42)][clampi(t, 0, 4)]


## Label height over the cluster per tier.
static func trainer_label_y(t: int) -> float:
	return [4.4, 6.6, 6.9, 7.4, 8.4][clampi(t, 0, 4)]


static func trainer(t: int) -> Mesh:
	var k := MeshKit.new()
	ArchKit.lot(k, 7.9, 7.9, t)
	t = clampi(t, 0, 4)
	_tr_racks(k, t)
	_tr_table(k, t)
	_tr_power(k, t)
	match t:
		0:
			_tr0(k)
			_tr0x(k)
		1:
			_tr1(k)
			_tr1x(k)
			_tr1y(k)
		2:
			_tr2(k)
			_tr2x(k)
			_tr2y(k)
		3:
			_tr3(k)
			_tr3x(k)
			_tr3y(k)
		_:
			_tr4(k)
			_tr4x(k)
			_tr4y(k)
	_life(k, "trainer", clampi(t, 0, 4))
	_finish(k, "trainer", clampi(t, 0, 4))
	return k.commit()


## The loss-curve screen behind TrainerB's curve.
static func _tr_screen(k: MeshKit, t: int, frame: Color) -> void:
	var s := trainer_screen(t)
	var c := Vector3(s.x, s.y + 0.05, s.z - 0.06)
	k.box(Vector3(4.3, 1.75, 0.08), frame, at(c.x, c.y, c.z - 0.02))
	k.box(Vector3(4.1, 1.55, 0.03), lit(Color(0.12, 0.18, 0.28), 0.75), at(c.x, c.y, c.z + 0.03))
	k.box(Vector3(3.8, 0.02, 0.01), lit(Color(0.7, 0.8, 0.9), 0.4), at(c.x, s.y - 0.62, s.z - 0.01))
	k.box(Vector3(0.02, 1.4, 0.01), lit(Color(0.7, 0.8, 0.9), 0.4), at(c.x - 1.85, s.y + 0.05, s.z - 0.01))
	for i in 4:
		k.box(Vector3(3.7, 0.008, 0.01), lit(Color(0.5, 0.6, 0.7), 0.6), at(c.x, s.y - 0.3 + i * 0.3, s.z - 0.015))
	k.box(Vector3(0.6, 0.12, 0.01), lit(Color(1.0, 0.8, 0.5), 0.4), at(c.x - 1.4, s.y + 0.62, s.z - 0.01))
	k.box(Vector3(0.4, 0.12, 0.01), lit(Color(0.5, 1.0, 0.7), 0.4), at(c.x + 1.5, s.y + 0.62, s.z - 0.01))


## The flat top of the trainer's back strip (roof gear sits up here).
static func _tr_strip_top(k: MeshKit, y: float, t: int) -> void:
	var p := ArchKit.pal(t)
	k.box(Vector3(7.78, 0.05, 0.6), p["roof"], at(0, y + 0.025, -3.65))
	k.box(Vector3(7.78, 0.06, 0.04), p["trim"] if t != 2 else p["wall2"], at(0, y + 0.03, -3.35))
	if t >= 3:
		k.box(Vector3(7.78, 0.02, 0.02), lit(p["glow"], 0.45), at(0, y - 0.05, -3.34))


## Rack frames around the GPU trays, in the tier's style.
static func _tr_racks(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var post: Color = [Color(0.78, 0.8, 0.82), Color(0.3, 0.32, 0.36), Color(0.95, 0.95, 0.96), Color(0.16, 0.17, 0.2), Color(0.12, 0.12, 0.14)][t]
	var h := 2.08
	for i in 6:
		var x := -2.5 + i * 1.0
		for sx in [-1.0, 1.0]:
			for z in [-1.86, -1.14]:
				k.box(Vector3(0.05 if t == 0 else 0.07, h, 0.05 if t == 0 else 0.07), post, at(x + sx * 0.34, 0.1 + h * 0.5, z))
		for r in 4:
			k.box(Vector3(0.66, 0.02, 0.74), post.darkened(0.15), at(x, 0.34 + r * 0.42, -1.5))
		k.box(Vector3(0.72, 0.06, 0.78), post if t != 4 else p["trim"], at(x, 0.1 + h, -1.5))
		match t:
			0:
				# risers and PSU on each open frame, a box fan on the side
				k.box(Vector3(0.3, 0.14, 0.18), Color(0.2, 0.2, 0.22), at(x, 0.2, -1.7))
				for r in 4:
					k.box(Vector3(0.02, 0.3, 0.02), Color(0.95, 0.8, 0.2), at(x + 0.25, 0.48 + r * 0.42, -1.82))
			1:
				k.box(Vector3(0.66, h, 0.02), post.darkened(0.3), at(x, 0.1 + h * 0.5, -1.9))
				k.box(Vector3(0.06, 0.06, 0.02), lit(p["glow"], 0.3), at(x + 0.28, 2.0, -1.12))
			2:
				k.box(Vector3(0.66, h, 0.02), Color(0.86, 0.88, 0.9), at(x, 0.1 + h * 0.5, -1.9))
				k.box(Vector3(0.72, 0.03, 0.02), lit(p["glow"], 0.4), at(x, 2.06, -1.11))
				for sx in [-1.0, 1.0]:
					k.box(Vector3(0.03, h - 0.1, 0.02), p["accent"], at(x + sx * 0.36, 0.1 + h * 0.5, -1.11))
			3:
				k.box(Vector3(0.66, h, 0.02), p["dark"], at(x, 0.1 + h * 0.5, -1.9))
				for sx in [-1.0, 1.0]:
					k.box(Vector3(0.02, h - 0.1, 0.02), lit(p["glow"], 0.4), at(x + sx * 0.36, 0.1 + h * 0.5, -1.1))
				# liquid-cooling hoses down the back
				k.box(Vector3(0.05, h, 0.05), Color(0.36, 0.6, 0.86), at(x - 0.2, 0.1 + h * 0.5, -1.95))
				k.box(Vector3(0.05, h, 0.05), Color(0.86, 0.4, 0.3), at(x + 0.2, 0.1 + h * 0.5, -1.95))
			_:
				k.box(Vector3(0.66, h, 0.02), p["dark"], at(x, 0.1 + h * 0.5, -1.9))
				for sx in [-1.0, 1.0]:
					k.box(Vector3(0.025, h - 0.1, 0.025), p["trim"], at(x + sx * 0.37, 0.1 + h * 0.5, -1.1))
				k.box(Vector3(0.6, 0.03, 0.02), lit(p["accent2"], 0.4), at(x, 2.1, -1.1))
				k.box(Vector3(0.07, h, 0.07), lit(p["accent2"], 0.5), at(x, 0.1 + h * 0.5, -1.97))
	# the floor under the racks
	var fc: Color = [Color(0.6, 0.58, 0.55), Color(0.62, 0.64, 0.66), Color(0.88, 0.89, 0.9), Color(0.26, 0.28, 0.32), Color(0.16, 0.16, 0.19)][t]
	for i in 7:
		for j in 2:
			k.box(Vector3(0.96, 0.03, 0.96), fc if (i + j) % 2 == 0 else fc.darkened(0.05), at(-3.0 + i * 1.0, 0.115, -1.0 - j * 1.0))


## The input table data lands on (tops at y 0.45).
static func _tr_table(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var z := 1.0
	match t:
		0:
			for i in 3:
				var x := -2.5 + i * 1.35
				table(k, at(x, 0.1, z), 1.3, 0.7, Color(0.9, 0.9, 0.88), Color(0.4, 0.42, 0.45), 0.35)
			k.box(Vector3(4.0, 0.01, 0.75), Color(0.85, 0.3, 0.28), at(-1.15, 0.455, z))
			for i in 8:
				k.box(Vector3(0.25, 0.012, 0.75), Color(0.96, 0.96, 0.94), at(-3.0 + i * 0.5, 0.457, z))
		1:
			k.box(Vector3(4.6, 0.1, 0.8), p["trim"], at(-1.0, 0.4, z))
			for x in [-3.2, -1.0, 1.2]:
				k.box(Vector3(0.1, 0.32, 0.7), p["wall2"], at(x, 0.2, z))
			k.box(Vector3(4.62, 0.04, 0.04), p["accent"], at(-1.0, 0.44, z + 0.4))
		2:
			k.box(Vector3(4.6, 0.08, 0.8), Color(0.97, 0.97, 0.98), at(-1.0, 0.41, z))
			k.box(Vector3(4.4, 0.3, 0.6), p["wall2"], at(-1.0, 0.22, z))
			k.box(Vector3(4.4, 0.02, 0.02), lit(p["glow"], 0.4), at(-1.0, 0.36, z + 0.31))
		3:
			k.box(Vector3(4.7, 0.1, 0.85), p["metal"], at(-1.0, 0.4, z))
			k.box(Vector3(4.5, 0.32, 0.7), p["trim"], at(-1.0, 0.2, z))
			for i in 9:
				k.box(Vector3(0.08, 0.02, 0.85), p["dark"], at(-3.2 + i * 0.55, 0.455, z))
			k.box(Vector3(4.5, 0.02, 0.02), lit(p["accent2"], 0.4), at(-1.0, 0.3, z + 0.36))
		_:
			k.box(Vector3(4.7, 0.08, 0.85), p["wall2"], at(-1.0, 0.41, z))
			k.box(Vector3(4.72, 0.02, 0.87), p["trim"], at(-1.0, 0.455, z))
			k.box(Vector3(4.3, 0.28, 0.6), p["wall"], at(-1.0, 0.22, z))
			k.box(Vector3(4.3, 0.02, 0.4), lit(p["accent2"], 0.4), at(-1.0, 0.12, z))


## The power stand the cells land on (top at y 1.58), with a cable to the racks.
static func _tr_power(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var c := Vector3(3.2, 0.1, 2.4)
	match t:
		0:
			for i in 3:
				crate(k, xf(c + Vector3(0, i * 0.48, 0), Vector3(0, i * 5.0, 0)), 0.6, Color(0.72, 0.56, 0.38) if i % 2 == 0 else Color(0.66, 0.5, 0.34))
			k.box(Vector3(1.1, 0.04, 0.6), Pal.WOOD_LIGHT, at(c.x, 1.56, c.z))
		1:
			k.box(Vector3(1.2, 1.46, 0.7), Color(0.92, 0.72, 0.2), at(c.x, 0.1 + 0.73, c.z))
			k.box(Vector3(1.24, 0.04, 0.74), p["trim"], at(c.x, 1.56, c.z))
			k.box(Vector3(0.8, 0.5, 0.02), p["dark"], at(c.x, 0.8, c.z + 0.36))
			k.box(Vector3(0.2, 0.2, 0.01), Color(0.98, 0.84, 0.3), at(c.x - 0.3, 1.25, c.z + 0.36))
		2:
			k.rbox(Vector3(1.2, 1.46, 0.7), 0.05, Color(0.97, 0.97, 0.98), at(c.x, 0.1 + 0.73, c.z), 1)
			k.box(Vector3(1.0, 0.03, 0.02), lit(p["glow"], 0.4), at(c.x, 1.2, c.z + 0.36))
		3:
			k.box(Vector3(1.2, 1.46, 0.7), p["dark"], at(c.x, 0.1 + 0.73, c.z))
			for i in 4:
				k.box(Vector3(0.9, 0.03, 0.02), lit(Color(0.5, 1.0, 0.6), 0.35), at(c.x, 0.4 + i * 0.25, c.z + 0.36))
		_:
			k.box(Vector3(1.2, 1.46, 0.7), p["wall2"], at(c.x, 0.1 + 0.73, c.z))
			k.box(Vector3(1.24, 0.04, 0.74), p["trim"], at(c.x, 1.56, c.z))
			k.box(Vector3(0.05, 1.2, 0.02), lit(p["glow"], 0.4), at(c.x, 0.8, c.z + 0.36))
	ArchKit.pipes(k, [Vector3(c.x, 0.4, c.z - 0.36), Vector3(c.x, 0.13, c.z - 0.6), Vector3(3.1, 0.13, -1.0), Vector3(2.9, 0.4, -1.4)], 0.04, Color(0.15, 0.15, 0.17) if t < 4 else lit(p["glow"], 0.5))


## Garage: plywood and tin walls, open rafters, mining-rig frames, box fans.
static func _tr0(k: MeshKit) -> void:
	var t := 0
	var tin := Color(0.66, 0.68, 0.7)
	var ply := Color(0.8, 0.66, 0.46)
	var wood := Pal.WOOD
	# the back lean-to: a flat tin roof over shelves (roof gear sits up here)
	var bz := -3.65
	k.box(Vector3(7.8, 2.8, 0.3), ply, at(0, 1.5, -3.8))
	ArchKit.planks(k, at(0, 0.1, -3.64), 7.8, 2.8, ply.darkened(0.04))
	k.box(Vector3(7.8, 0.08, 0.6), tin, at(0, 2.94, bz))
	for i in 40:
		k.box(Vector3(0.05, 0.035, 0.6), tin.darkened(0.1), at(-3.88 + (i + 0.5) * 0.194, 2.99, bz))
	# corrugated side walls
	for sx in [-1.0, 1.0]:
		ArchKit.corrugated(k, xf(Vector3(sx * 3.82, 0.1, -2.2), Vector3(0, sx * 90.0, 0)), 3.4, 2.6, tin)
		k.box(Vector3(0.12, 2.9, 0.12), wood, at(sx * 3.85, 1.55, -0.5))
	k.box(Vector3(0.04, 0.8, 1.2), Color(0.6, 0.4, 0.28), at(3.86, 0.9, -2.6))
	# open timber trusses across the bay, a tarp over one end
	for z in [-3.3, -2.2, -1.1]:
		k.box(Vector3(7.8, 0.12, 0.1), wood, at(0, 2.7, z))
		beam(k, Vector3(-3.85, 2.7, z), Vector3(0, 3.5, z), 0.1, wood)
		beam(k, Vector3(3.85, 2.7, z), Vector3(0, 3.5, z), 0.1, wood)
		k.box(Vector3(0.08, 0.8, 0.08), wood, at(0, 3.1, z))
	k.box(Vector3(0.12, 0.12, 2.3), wood, at(0, 3.5, -2.2))
	k.box(Vector3(2.4, 0.03, 2.6), Color(0.26, 0.46, 0.78), xf(Vector3(-2.65, 3.0, -2.2), Vector3(0, 0, 12)))
	# the projector screen hung from the lean-to, a projector on a crate
	_tr_screen(k, t, Color(0.94, 0.94, 0.92))
	k.box(Vector3(4.4, 0.06, 0.06), Color(0.3, 0.3, 0.32), at(0.6, 3.0, -3.3))
	crate(k, at(0.6, 0.1, -0.2), 0.45)
	k.box(Vector3(0.3, 0.12, 0.25), Color(0.2, 0.2, 0.22), at(0.6, 0.53, -0.2))
	k.cyl(0.04, 0.04, lit(Color(1.0, 0.9, 0.7), 0.3), xf(Vector3(0.6, 0.53, -0.32), Vector3(90, 0, 0)), 6)
	# shelves on the back wall with boxes and spare parts
	for x in [-3.0, 3.0]:
		for y in [0.6, 1.2, 1.8]:
			k.box(Vector3(1.2, 0.04, 0.35), Pal.WOOD_LIGHT, at(x, y, -3.45))
			crate(k, at(x - 0.3, y + 0.02, -3.45), 0.28, Color(0.78, 0.66, 0.46))
			k.box(Vector3(0.3, 0.12, 0.25), [Color(0.3, 0.5, 0.8), Color(0.85, 0.3, 0.28), Color(0.3, 0.6, 0.4)][int(y * 2) % 3], at(x + 0.25, y + 0.08, -3.45))
	# box fans blowing on the rigs, extension cords, power strips
	for i in 7:
		box_fan(k, xf(Vector3(-3.0 + i * 1.0, 0.1, -0.85), Vector3(0, 180, 0)), 0.42)
	for i in 3:
		box_fan(k, xf(Vector3(-3.0 + i * 0.5, 2.1 + (i % 2) * 0.0, -2.4), Vector3(0, 0, 0)), 0.4)
	ArchKit.pipes(k, [Vector3(-3.6, 0.12, -0.9), Vector3(3.6, 0.12, -0.9)], 0.02, Color(0.95, 0.5, 0.15))
	ArchKit.pipes(k, [Vector3(-3.6, 0.12, -0.9), Vector3(-3.6, 1.0, -3.5)], 0.02, Color(0.95, 0.5, 0.15))
	ArchKit.string_lights(k, Vector3(-3.85, 2.6, -0.5), Vector3(3.85, 2.6, -0.5), 14)
	# a fridge, a couch, a workbench at the sides
	k.box(Vector3(0.6, 1.5, 0.6), Color(0.92, 0.92, 0.9), at(-3.4, 0.85, -2.6))
	k.box(Vector3(0.02, 0.5, 0.02), Color(0.6, 0.62, 0.64), at(-3.15, 1.1, -2.29))
	k.box(Vector3(0.7, 0.4, 1.5), Color(0.4, 0.5, 0.36), at(3.45, 0.3, -2.6))
	k.box(Vector3(0.2, 0.4, 1.5), Color(0.36, 0.46, 0.32), at(3.75, 0.6, -2.6))
	table(k, at(-3.3, 0.1, 0.3), 0.8, 1.0, Pal.WOOD_LIGHT, wood, 0.9)
	k.box(Vector3(0.4, 0.2, 0.3), Color(0.85, 0.3, 0.28), at(-3.3, 1.0, 0.0))
	# a garage sign, an open roll-up track at the front
	k.box(Vector3(1.6, 0.4, 0.04), Color(0.95, 0.93, 0.86), xf(Vector3(-2.8, 2.5, -0.45), Vector3(0, 0, -2)))
	text(k, "GPU", xf(Vector3(-2.8, 2.38, -0.43), Vector3(0, 0, -2)), 0.05, Color(0.85, 0.24, 0.2))
	ArchKit.clutter(k, Vector3(2.5, 0.1, 0.1), t, 7)
	cone(k, Vector3(1.8, 0.1, 2.0))


## Workshop: a steel portal-frame hall open at the front, a wall loss chart
## on the fascia, a gantry crane rail inside.
static func _tr1(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var h := 4.2
	var steel: Color = p["wall"]
	var col := Color(0.3, 0.36, 0.5)
	# back strip and walls
	k.box(Vector3(7.8, 3.3, 0.6), steel, at(0, 0.1 + 1.65, -3.65))
	ArchKit.corrugated(k, at(0, 0.1, -3.34), 7.8, 3.3, steel.darkened(0.05))
	_tr_strip_top(k, 3.4, t)
	k.box(Vector3(7.8, h - 3.3, 0.2), steel, at(0, 3.4 + (h - 3.3) * 0.5, -3.3))
	for sx in [-1.0, 1.0]:
		ArchKit.corrugated(k, xf(Vector3(sx * 3.82, 0.1, -1.6), Vector3(0, sx * 90.0, 0)), 3.6, h, steel)
	# portal frames: blue I-beam columns and rafters
	for z in [-3.2, -1.6, 0.0]:
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.22, h, 0.16), col, at(sx * 3.75, 0.1 + h * 0.5, z))
			k.box(Vector3(0.3, 0.06, 0.24), col.darkened(0.2), at(sx * 3.75, 0.13, z))
		k.box(Vector3(7.7, 0.3, 0.14), col, at(0, h - 0.05, z))
		for sx in [-1.0, 1.0]:
			beam(k, Vector3(sx * 3.6, h - 0.8, z), Vector3(sx * 3.0, h - 0.15, z), 0.1, col)
	# the roof: sheets with skylights
	var rt := h + 0.12
	k.box(Vector3(7.8, 0.08, 3.9), p["roof"], at(0, rt, -1.45))
	for i in 4:
		k.box(Vector3(0.9, 0.04, 3.4), lit(Color(0.7, 0.85, 0.95), 0.75), at(-2.7 + i * 1.8, rt + 0.06, -1.6))
	for i in 24:
		k.box(Vector3(0.04, 0.03, 4.1), p["roof"].darkened(0.1), at(-3.9 + i * 0.34, rt + 0.05, -1.55))
	# the fascia over the open front with the loss chart
	k.box(Vector3(7.8, 1.9, 0.14), steel, at(0, rt + 0.95, 0.05))
	k.box(Vector3(7.8, 0.12, 0.18), p["trim"], at(0, rt + 1.9, 0.05))
	_tr_screen(k, t, p["dark"])
	k.box(Vector3(1.2, 0.5, 0.05), p["accent"], at(-2.95, rt + 0.95, 0.15))
	text(k, "TRAIN", at(-2.95, rt + 0.82, 0.18), 0.045, p["dark"])
	for i in 2:
		ArchKit.lamp(k, Vector3(-3.4 + i * 6.6, rt + 1.9, 0.0), t, 0.5)
	# inside: a crane rail along the back, cable trays to each rack
	k.box(Vector3(7.4, 0.2, 0.2), p["accent"], at(0, 3.2, -2.6))
	k.box(Vector3(0.5, 0.3, 0.4), p["accent"], at(-1.6, 3.0, -2.6))
	k.box(Vector3(0.02, 0.6, 0.02), Color(0.2, 0.2, 0.22), at(-1.6, 2.55, -2.6))
	ArchKit.cable_tray(k, Vector3(-3.5, 2.95, -1.5), Vector3(3.5, 2.95, -1.5), t)
	for i in 6:
		k.box(Vector3(0.04, 1.1, 0.04), p["trim"], at(-2.5 + i * 1.0, 3.5, -1.5 - 0.0))
	# yellow guard rails and floor lines
	for z in [-0.8, 0.45]:
		k.box(Vector3(6.6, 0.006, 0.08), p["accent"], at(-0.2, 0.106, z))
	for x in [-3.5, 3.5]:
		bollard(k, Vector3(x, 0.1, 0.3), p["accent"], 0.9)
	# side: AC units on the wall, a compressor, a toolbox, a forklift
	for i in 2:
		k.box(Vector3(0.9, 0.7, 0.45), Color(0.9, 0.9, 0.9), at(3.4, 0.5, -3.0 + i * 1.1))
		k.cyl(0.25, 0.03, Color(0.22, 0.23, 0.26), xf(Vector3(3.17, 0.5, -3.0 + i * 1.1), Vector3(0, 0, 90)), 10)
	k.box(Vector3(0.5, 0.9, 0.4), Color(0.85, 0.2, 0.18), at(-3.5, 0.55, -2.8))
	for j in 4:
		k.box(Vector3(0.46, 0.02, 0.02), Color(0.3, 0.3, 0.32), at(-3.5, 0.3 + j * 0.2, -2.59))
	pallet(k, at(2.6, 0.1, -0.5), Color(0.72, 0.56, 0.38), 6)


## Campus: a white compute hall, open bay with slender columns, glass
## gallery wings, solar on the roof.
static func _tr2(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var h := 4.4
	var w: Color = p["wall"]
	# the back strip: two white storeys
	k.rbox(Vector3(7.8, 3.6, 0.6), 0.04, w, at(0, 0.1 + 1.8, -3.65), 1)
	_tr_strip_top(k, 3.7, t)
	k.box(Vector3(5.6, h - 3.7, 0.25), w, at(0, 3.7 + (h - 3.7) * 0.5, -3.3))
	# glass gallery wings on both sides (two storeys, a balcony inside)
	for sx in [-1.0, 1.0]:
		var wx: float = sx * 3.3
		k.box(Vector3(1.1, h, 3.5), w, at(wx, 0.1 + h * 0.5, -1.6))
		ArchKit.curtain(k, xf(Vector3(wx - sx * 0.55, 0.3, -1.6), Vector3(0, -sx * 90.0, 0)), 3.3, h - 0.5, t, 5, 2)
		ArchKit.curtain(k, at(wx, 0.3, 0.15), 1.0, h - 0.5, t, 2, 2)
		k.box(Vector3(1.14, 0.08, 3.54), p["trim"], at(wx, 0.1 + h * 0.5, -1.6))
		for i in 3:
			k.box(Vector3(0.03, 0.02, 0.03), lit(p["glow"], 0.3), at(wx - sx * 0.58, 2.4 + i * 0.2, -1.6))
	# the roof slab over the bay, teal fascia, the screen above the front
	var rt := 0.1 + h
	k.box(Vector3(7.9, 0.22, 4.1), w, at(0, rt + 0.11, -1.4))
	k.box(Vector3(7.92, 0.12, 0.05), p["trim"], at(0, rt + 0.1, 0.66))
	k.box(Vector3(7.92, 0.03, 0.03), lit(p["glow"], 0.4), at(0, rt - 0.02, 0.67))
	k.box(Vector3(4.8, 2.1, 0.3), w, at(0.6, rt + 1.0, 0.08))
	_tr_screen(k, t, p["dark"])
	k.box(Vector3(4.82, 0.08, 0.32), p["trim"], at(0.6, rt + 2.06, 0.08))
	# slender front columns
	for x in [-2.85, 2.85]:
		k.cyl(0.09, h, Color(0.96, 0.96, 0.97), at(x, 0.1, 0.45), 8)
	# roof: solar rows and a screened plant (kept clear of the back strip)
	for i in 3:
		ArchKit.solar(k, at(-1.3 + i * 1.3 - 1.1, rt + 0.22, -2.6 + 0.0), 1, t, 22.0, 0.35)
	ArchKit.solar(k, at(-1.0, rt + 0.22, -1.6), 4, t, 22.0, 0.35)
	ArchKit.solar(k, at(-1.0, rt + 0.22, -0.7), 4, t, 22.0, 0.35)
	ArchKit.louvres(k, at(2.6, rt + 0.22, -0.4), 1.6, 0.8, p["wall2"], 6)
	ArchKit.ac_unit(k, at(2.6, rt + 0.22, -1.2), t, 0.8)
	ArchKit.ac_unit(k, at(2.6, rt + 0.22, -2.2), t, 0.8)
	# the logo on the back strip, planters out front, a bench
	k.box(Vector3(1.3, 0.5, 0.06), p["accent"], at(-2.4, 3.1, -3.33))
	text(k, "TRAIN", at(-2.4, 2.98, -3.29), 0.045, Color(0.98, 0.98, 0.98))
	ArchKit.planter(k, Vector3(2.3, 0.1, 1.2), t, 0.8, true)
	ArchKit.planter(k, Vector3(-3.4, 0.1, 1.7), t, 0.7, false)
	k.box(Vector3(1.2, 0.05, 0.35), Pal.WOOD_LIGHT, at(1.9, 0.48, 2.0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 0.38, 0.3), p["wall2"], at(1.9 + sx * 0.55, 0.29, 2.0))
	# an overhead white cable tray to the racks, pendant lights
	ArchKit.cable_tray(k, Vector3(-2.8, 3.0, -1.5), Vector3(2.8, 3.0, -1.5), t)
	for i in 4:
		k.box(Vector3(0.02, rt - 3.0, 0.02), Color(0.3, 0.3, 0.32), at(-2.0 + i * 1.3, 3.0 + (rt - 3.0) * 0.5, -0.4))
		k.box(Vector3(0.6, 0.05, 0.15), lit(p["glow"], 0.35), at(-2.0 + i * 1.3, 3.0, -0.4))


## Industrial: a supercomputer hall with rooftop cooling towers, pipe racks,
## catwalks and a stair tower.
static func _tr3(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var h := 4.8
	var w: Color = p["wall"]
	# the back strip (flat roof for gear) and the hall shell
	k.box(Vector3(7.8, 3.8, 0.6), w, at(0, 0.1 + 1.9, -3.65))
	_tr_strip_top(k, 3.9, t)
	k.box(Vector3(7.8, h - 3.9, 0.3), w, at(0, 3.9 + (h - 3.9) * 0.5, -3.2))
	for sx in [-1.0, 1.0]:
		ArchKit.corrugated(k, xf(Vector3(sx * 3.82, 0.1, -1.6), Vector3(0, sx * 90.0, 0)), 3.6, h, p["wall2"], 0.14)
	# heavy portal columns with blue LED strips
	for z in [-3.0, -1.5, 0.0]:
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.3, h, 0.3), p["trim"], at(sx * 3.7, 0.1 + h * 0.5, z))
			k.box(Vector3(0.03, h - 0.4, 0.03), lit(p["glow"], 0.4), at(sx * 3.54, 0.1 + h * 0.5, z + 0.16))
	var rt := 0.1 + h
	k.box(Vector3(7.9, 0.3, 3.9), p["roof"], at(0, rt + 0.15, -1.35))
	# the fascia with the screen, louvres, a catwalk along it
	k.box(Vector3(7.9, 2.0, 0.3), w, at(0, rt + 1.0, 0.05))
	_tr_screen(k, t, p["dark"])
	ArchKit.louvres(k, at(-3.0, rt + 0.3, 0.21), 1.4, 1.3, p["metal"], 7)
	ArchKit.catwalk(k, Vector3(-3.8, rt - 0.4, 0.55), Vector3(3.8, rt - 0.4, 0.55), 0.6, t, false)
	for x in [-3.0, -1.0, 1.0, 3.0]:
		beam(k, Vector3(x, rt - 0.42, 0.85), Vector3(x, rt + 0.3, 0.21), 0.06, p["trim"])
	k.box(Vector3(7.92, 0.04, 0.04), lit(p["accent2"], 0.4), at(0, rt + 2.0, 0.21))
	# a caged ladder up to the catwalk
	ArchKit.ladder(k, xf(Vector3(3.3, 0.1, 0.3), Vector3(0, 0, 0)), rt - 0.4, p["accent"], true)
	# the roof: two cooling towers, a pipe rack, chillers
	for sx in [-1.0, 1.0]:
		ArchKit.cooling_tower(k, at(sx * 2.5, rt + 0.3, -1.9), 0.85, 2.2, t)
	ArchKit.pipe_rack(k, at(0, rt + 0.3, -1.9), 3.2, 0.6, t, 4)
	ArchKit.chiller(k, at(0, rt + 0.3, -0.6), 3.0, t, 3)
	for sx in [-1.0, 1.0]:
		ArchKit.pipes(k, [Vector3(sx * 1.7, rt + 0.95, -1.9), Vector3(sx * 2.0, rt + 0.95, -1.9), Vector3(sx * 2.0, rt + 1.5, -1.9)], 0.08, Color(0.36, 0.6, 0.86))
	ArchKit.beacon(k, Vector3(3.6, rt + 0.3, -3.0), 0.5)
	# pipe racks down the left side into the hall
	ArchKit.pipe_rack(k, xf(Vector3(-3.35, 0.1, 1.9), Vector3(0, 90, 0)), 1.6, 2.4, t, 3)
	ArchKit.pipes(k, [Vector3(-3.35, 2.6, 1.1), Vector3(-3.35, 2.6, 0.0), Vector3(-3.35, 3.4, -0.6)], 0.08, Color(0.36, 0.6, 0.86))
	# inside: overhead cable ladders, hot aisle hood
	cable_ladder(k, Vector3(-3.0, 3.05, -1.5), Vector3(3.0, 3.05, -1.5), 0.4, p["metal"], Color(0.15, 0.15, 0.17))
	k.box(Vector3(6.4, 0.06, 0.9), p["dark"], at(0, 2.35, -2.35))
	for i in 7:
		k.box(Vector3(0.05, 0.6, 0.05), p["trim"], at(-3.0 + i * 1.0, 2.65, -2.35))
	for x in [-3.5, 2.4]:
		bollard(k, Vector3(x, 0.1, 0.4), p["accent"], 0.9)
	for z in [-0.75, 0.45]:
		k.box(Vector3(6.8, 0.006, 0.08), p["accent"], at(-0.3, 0.106, z))


## Hyperscale: a graphite cathedral of compute: a tall nave on buttresses,
## a rose screen, glowing coolant loops, cantilevered wings, a crown.
static func _tr4(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var g: Color = p["wall"]
	var g2: Color = p["wall2"]
	var brass: Color = p["trim"]
	var cool := lit(p["accent2"], 0.5)
	# the apse strip at the back (flat roof for gear), brass seams
	k.box(Vector3(7.8, 3.4, 0.6), g, at(0, 0.1 + 1.7, -3.65))
	_tr_strip_top(k, 3.5, t)
	# the nave: a tall graphite volume over the racks
	var h := 5.4
	k.box(Vector3(6.6, h - 3.5, 0.4), g, at(0, 3.5 + (h - 3.5) * 0.5, -3.15))
	var rt := 0.1 + h
	# a stepped, pointed roof
	for i in 4:
		var wy := 6.8 - i * 1.4
		k.box(Vector3(wy, 0.45, 3.5), g2 if i % 2 == 0 else g, at(0, rt + 0.225 + i * 0.45, -1.7))
		k.box(Vector3(wy + 0.04, 0.05, 0.05), brass, at(0, rt + 0.45 + i * 0.45, 0.06))
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.05, 0.05, 3.5), brass, at(sx * wy * 0.5, rt + 0.45 + i * 0.45, -1.7))
	# buttresses: graphite fins down both sides with glowing seams
	for z in [-3.0, -1.9, -0.8, 0.3]:
		for sx in [-1.0, 1.0]:
			k.box(Vector3(0.5, h + 0.2, 0.22), g2, at(sx * 3.55, 0.1 + (h + 0.2) * 0.5, z))
			beam(k, Vector3(sx * 3.72, 0.1, z), Vector3(sx * 3.35, h - 0.2, z), 0.18, g)
			k.box(Vector3(0.03, h - 0.4, 0.03), lit(p["glow"], 0.4), at(sx * 3.29, 0.1 + h * 0.5, z + 0.12))
	# cantilevered wings on the sides at height (glass bands, brass edges)
	for sx in [-1.0, 1.0]:
		var wx: float = sx * 3.2
		k.box(Vector3(1.3, 1.1, 3.6), g2, at(wx, 3.0, -1.4))
		k.box(Vector3(1.32, 0.4, 3.0), p["glass"], at(wx, 3.0, -1.4))
		k.box(Vector3(1.34, 0.04, 3.64), brass, at(wx, 3.55, -1.4))
		k.box(Vector3(1.34, 0.04, 3.64), brass, at(wx, 2.45, -1.4))
	# the façade: a rose screen in a brass frame, an arch of light over the bay
	for i in 4:
		var gw := 7.2 - i * 1.5
		k.box(Vector3(gw, 0.9, 0.4), g if i % 2 == 0 else g2, at(0, 4.1 + 0.45 + i * 0.9, 0.16))
		k.box(Vector3(gw + 0.04, 0.05, 0.44), brass, at(0, 4.1 + 0.9 + i * 0.9, 0.16))
	_tr_screen(k, t, brass)
	for i in 9:
		var a := PI * i / 8.0
		k.box(Vector3(0.2, 0.06, 0.05), lit(p["glow"], 0.35), xf(Vector3(0.0 + cos(a) * 3.0, 3.3 + sin(a) * 0.6, 0.38), Vector3(0, 0, rad_to_deg(a) + 90.0)))
	k.box(Vector3(7.24, 0.05, 0.44), brass, at(0, 4.08, 0.16))
	# glowing liquid-cooling loops across the façade and down the buttresses
	for i in 3:
		var y := 3.95 - i * 0.12
		ArchKit.pipes(k, [Vector3(-3.5, 0.3, 0.5 + i * 0.08), Vector3(-3.5, y, 0.5 + i * 0.08), Vector3(3.5, y, 0.5 + i * 0.08), Vector3(3.5, 0.3, 0.5 + i * 0.08)], 0.04, cool if i != 1 else lit(Color(1.0, 0.6, 0.4), 0.5))
	# the crown: a brass spire with rings and an orb over the apse
	var cp := Vector3(0, rt + 1.8, -1.7)
	k.cyl(0.3, 2.6, g2, at(cp.x, cp.y, cp.z), 6, 0.0, 0.12)
	for i in 3:
		ring(k, cp + Vector3(0, 0.6 + i * 0.7, 0), 0.38 - i * 0.07, 0.03, brass, Vector3.ZERO, 14)
	for i in 8:
		var a2 := TAU * i / 8.0
		beam(k, cp + Vector3(cos(a2) * 0.45, 0.05, sin(a2) * 0.45), cp + Vector3(cos(a2) * 0.12, 1.5, sin(a2) * 0.12), 0.04, brass)
	k.sphere(0.24, lit(p["glow"], 0.3), at(cp.x, cp.y + 2.8, cp.z), 8, 5)
	ArchKit.beacon(k, cp + Vector3(0, 3.0, 0), 0.4)
	# drone pads on the wings
	for sx in [-1.0, 1.0]:
		ArchKit.drone_pad(k, Vector3(sx * 3.2, 3.57, -2.4), 0.5, t)
	drone(k, Vector3(3.2, 4.2, -2.3), t, 40.0)
	# inside: glowing coolant manifold over the racks
	ArchKit.pipes(k, [Vector3(-3.0, 2.5, -2.0), Vector3(3.0, 2.5, -2.0)], 0.07, cool)
	ArchKit.pipes(k, [Vector3(-3.0, 2.7, -2.1), Vector3(3.0, 2.7, -2.1)], 0.07, lit(Color(1.0, 0.6, 0.4), 0.5))
	for i in 5:
		k.box(Vector3(5.8, 0.006, 0.03), lit(p["accent2"], 0.5), at(-0.2, 0.106, -0.6 + i * 0.6))
	for x in [-3.5, 2.4]:
		k.cyl(0.08, 0.7, g2, at(x, 0.1, 0.5), 6)
		k.box(Vector3(0.17, 0.04, 0.17), lit(p["glow"], 0.35), at(x, 0.8, 0.5))


## Training Cluster detail passes.
static func _tr0x(k: MeshKit) -> void:
	var t := 0
	tufts(k, Rect2(-3.9, 1.5, 7.8, 2.4), 30, 31)
	# tyre tracks into the garage, oil stains
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.22, 0.004, 3.4), Color(0.5, 0.46, 0.4), at(1.6 + sx * 0.6, 0.104, 2.2))
	k.cyl(0.4, 0.004, Color(0.36, 0.34, 0.32), at(-1.5, 0.105, -0.4), 10)
	# GPU boxes stacked by the rigs, a whiteboard of runs, a kettle on a crate
	for i in 4:
		k.box(Vector3(0.36, 0.12, 0.22), [Color(0.15, 0.15, 0.17), Color(0.4, 0.75, 0.3), Color(0.9, 0.3, 0.25)][i % 3], at(-3.4, 0.16 + i * 0.12, -1.3))
	k.box(Vector3(0.05, 0.9, 1.2), Color(0.97, 0.97, 0.96), at(-3.8, 1.5, -1.6))
	for i in 4:
		k.box(Vector3(0.01, 0.04, 0.8 - i * 0.15), Color(0.2, 0.3, 0.7), at(-3.77, 1.8 - i * 0.18, -1.6))
	crate(k, at(3.4, 0.1, -0.9), 0.4)
	k.cyl(0.08, 0.15, Color(0.9, 0.9, 0.88), at(3.4, 0.43, -0.9), 6)
	# the lean-to roof: patches, a bucket, a cable through a hole; rafter tarp ties
	roof_dress(k, Rect2(-3.8, -3.95, 7.6, 0.6), 2.98, t, 7, slot_rects("trainer", t, true), 0.6)
	for x in [-3.4, -2.2]:
		cable(k, Vector3(x, 3.0, -2.6), Vector3(x + 0.1, 2.7, -3.3), 0.05, Color(0.85, 0.85, 0.8), 0.012, 2)
	# a ceiling fan on the truss, a hanging work light
	k.box(Vector3(0.02, 0.4, 0.02), Color(0.3, 0.3, 0.32), at(1.5, 2.5, -2.2))
	for i in 3:
		k.box(Vector3(0.6, 0.015, 0.1), Color(0.6, 0.45, 0.3), xf(Vector3(1.5, 2.3, -2.2), Vector3(0, i * 60.0, 0)))
	k.box(Vector3(0.02, 0.6, 0.02), Color(0.2, 0.2, 0.22), at(-1.5, 2.4, -1.1))
	k.cyl(0.1, 0.1, lit(Color(1.0, 0.82, 0.5), 0.35), at(-1.5, 2.0, -1.1), 6)


static func _tr1x(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var rt := 4.2 + 0.12
	for z in [-3.36, 0.48]:
		k.box(Vector3(7.8, 0.1, 0.12), p["trim"], at(0, rt + 0.02, z))
	roof_dress(k, Rect2(-3.85, -3.95, 7.7, 0.6), 3.4 + 0.25, t, 17, slot_rects("trainer", t, true), 0.55)
	# floor markings in the bay, a workbench and a toolbox in the aisle
	for i in 7:
		k.box(Vector3(0.08, 0.005, 0.4), p["accent"], at(-3.0 + i * 1.0, 0.106, -0.6))
	k.box(Vector3(1.4, 0.05, 0.55), Pal.WOOD_LIGHT, at(-3.0, 0.95, -0.3))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 0.85, 0.5), p["trim"], at(-3.0 + sx * 0.65, 0.52, -0.3))
	k.box(Vector3(0.3, 0.2, 0.25), Color(0.85, 0.2, 0.18), at(-3.2, 1.08, -0.3))
	laptop(k, xf(Vector3(-2.7, 0.98, -0.3), Vector3(0, 200, 0)))
	# loading bay markings and a parking line out front
	for i in 6:
		k.box(Vector3(0.5, 0.005, 0.08), p["accent"] if i % 2 == 0 else p["dark"], xf(Vector3(-3.0 + i * 0.5, 0.106, 2.1), Vector3(0, 45, 0)))
	seams(k, xf(Vector3(0, 0.104, 3.95), Vector3(-90, 0, 0)), 7.8, 2.4, 6, 2, Color(0.6, 0.6, 0.58))


static func _tr2x(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var rt := 0.1 + 4.4 + 0.22
	# a green roof strip with shrubs, a skylight band, more solar rows
	k.box(Vector3(2.6, 0.08, 1.2), Color(0.46, 0.6, 0.36), at(-2.4, rt + 0.04, -0.3))
	for i in 6:
		shrub(k, Vector3(-3.4 + i * 0.4, rt + 0.06, -0.3 + (i % 2) * 0.3), 0.16)
	for i in 4:
		k.box(Vector3(0.7, 0.1, 0.5), lit(Color(0.7, 0.88, 0.95), 0.75), at(-0.2 + i * 0.85, rt + 0.05, -3.0))
		k.box(Vector3(0.74, 0.04, 0.54), p["frame"], at(-0.2 + i * 0.85, rt + 0.11, -3.0))
	ArchKit.solar(k, at(-1.0, rt, -2.4), 4, t, 22.0, 0.35)
	ArchKit.railing(k, Vector3(-3.9, rt, 0.62), Vector3(3.9, rt, 0.62), 0.6, p["frame"], 0.8)
	roof_dress(k, Rect2(-3.85, -3.95, 7.7, 0.6), 3.7 + 0.32, t, 27, slot_rects("trainer", t, true), 0.5)
	# the gallery wings: people on the balcony, a staircase inside the glass
	for sx in [-1.0, 1.0]:
		for i in 3:
			k.capsule(0.08, 0.5, [Color(0.3, 0.5, 0.8), Color(0.85, 0.4, 0.3), Color(0.3, 0.6, 0.4)][i], at(sx * 3.3, 2.45, -2.6 + i * 1.0), 6, 2)
			k.sphere(0.07, Color(0.92, 0.78, 0.66), at(sx * 3.3, 3.03, -2.6 + i * 1.0), 6, 3)
	# paving out front, a low planter row along the kerb, kerb lights
	seams(k, xf(Vector3(0, 0.104, 3.95), Vector3(-90, 0, 0)), 7.8, 2.4, 10, 3, p["wall2"])
	for i in 4:
		k.box(Vector3(0.12, 0.04, 0.12), lit(p["glow"], 0.35), at(-2.7 + i * 1.8, 0.12, 1.65))


static func _tr3x(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var rt := 0.1 + 4.8 + 0.3
	# roof: duct runs, exhaust stacks, a catwalk across, more chillers
	duct(k, Vector3(-3.4, rt + 0.25, -0.2), Vector3(3.4, rt + 0.25, -0.2), 0.4, 0.3, p["metal"])
	for x in [-3.3, 3.3]:
		k.cyl(0.14, 1.6, p["metal"], at(x, rt, -3.0), 8)
		k.cyl(0.18, 0.08, p["dark"], at(x, rt + 1.6, -3.0), 8)
	ArchKit.catwalk(k, Vector3(-3.6, rt + 0.6, -1.0), Vector3(3.6, rt + 0.6, -1.0), 0.5, t, false)
	for x in [-3.0, -1.0, 1.0, 3.0]:
		k.box(Vector3(0.06, 0.6, 0.06), p["trim"], at(x, rt + 0.3, -1.0))
	floor_grid(k, Vector3(0, rt + 0.005, -1.35), 7.8, 3.8, 8, 4, p["roof"].darkened(0.15))
	roof_dress(k, Rect2(-3.85, -3.95, 7.7, 0.6), 3.9 + 0.3, t, 37, slot_rects("trainer", t, true), 0.55)
	# aisle: a monitoring desk, floor LEDs, cable trench plates
	k.box(Vector3(1.4, 0.06, 0.5), p["dark"], at(2.2, 0.85, -0.4))
	for i in 3:
		k.box(Vector3(0.36, 0.24, 0.02), lit(Color(0.45, 0.75, 1.0), 0.4), xf(Vector3(1.8 + i * 0.4, 1.05, -0.55), Vector3(-10, 0, 0)))
	chair(k, xf(Vector3(2.2, 0.1, 0.0), Vector3(0, 180, 0)), p["dark"])
	for i in 7:
		k.box(Vector3(0.8, 0.02, 0.3), p["metal"], at(-3.0 + i * 1.0, 0.13, -0.5))
	for i in 7:
		k.box(Vector3(0.04, 0.006, 0.3), lit(p["glow"], 0.45), at(-3.0 + i * 1.0, 0.142, -0.5))
	# out front: steel plates and yellow hatching
	for i in 8:
		k.box(Vector3(0.6, 0.005, 0.09), p["accent"], xf(Vector3(-3.5 + i * 0.25, 0.106, 2.2), Vector3(0, 45, 0)))
	seams(k, xf(Vector3(0, 0.104, 3.95), Vector3(-90, 0, 0)), 7.8, 2.4, 6, 2, p["floor"].darkened(0.12))


static func _tr4x(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var rt := 0.1 + 5.4
	# glowing fins along each roof step, a coolant loop over the top
	for i in 4:
		var wy := 6.8 - i * 1.4
		var y := rt + 0.45 + i * 0.45
		for j in int(wy / 0.6):
			var x := -wy * 0.5 + 0.3 + j * 0.6
			k.box(Vector3(0.05, 0.25, 0.4), p["wall2"], at(x, y + 0.12, -3.2))
			k.box(Vector3(0.015, 0.2, 0.02), lit(p["glow"], 0.4), at(x, y + 0.12, -2.99))
	ArchKit.pipes(k, [Vector3(-2.8, rt + 0.6, -0.2), Vector3(-2.8, rt + 1.3, -1.7), Vector3(2.8, rt + 1.3, -1.7), Vector3(2.8, rt + 0.6, -0.2)], 0.05, lit(p["accent2"], 0.5))
	roof_dress(k, Rect2(-3.85, -3.95, 7.7, 0.6), 3.5 + 0.34, t, 47, slot_rects("trainer", t, true), 0.6)
	# brass ribs up the gable steps
	for sx in [-1.0, 1.0]:
		for i in 4:
			var gw := 7.2 - i * 1.5
			k.box(Vector3(0.06, 0.9, 0.06), brass, at(sx * gw * 0.5, 4.1 + 0.45 + i * 0.9, 0.38))
	# the aisle: glowing floor seams, a brass rail, standing screens
	for i in 6:
		k.box(Vector3(0.04, 0.006, 1.0), lit(p["accent2"], 0.5), at(-2.5 + i * 1.0, 0.107, -0.5))
	k.box(Vector3(6.6, 0.05, 0.05), brass, at(0, 0.95, 0.1))
	for i in 7:
		k.box(Vector3(0.04, 0.85, 0.04), brass, at(-3.0 + i * 1.0, 0.52, 0.1))
	# out front: glowing paving lines, brass bollards
	for i in 3:
		k.box(Vector3(7.6, 0.006, 0.03), lit(p["glow"], 0.4), at(0, 0.106, 2.0 + i * 0.6))


## One GPU's light in a training rack.
static func trainer_gpu(on: bool) -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.6, 0.2, 0.7), 0.02, Color(0.16, 0.17, 0.2), MeshKit.at(0, 0, 0))
	k.rbox(Vector3(0.52, 0.03, 0.01), 0.005, lit(Color(0.5, 1.0, 0.6) if on else Color(0.3, 0.3, 0.32), 0.35 if on else 1.0), MeshKit.at(0, 0.0, 0.36))
	return k.commit()


# ---------------------------------------------------------------- Launch Complex (8 x 8 m)
# Anchors (LaunchB): the pad top at PAD (0.8, 0.52, -1.4) where the rocket
# stands and climbs away toward +x; the three assembly benches at z = 2.6,
# x = -2.6, -1.3, 0 (tops at y 0.88); the control building's flat roof at
# (3.0, 2.4) (a roof slot). The gantry keeps to the -x side of the pad.

static func launchpad(t: int) -> Mesh:
	var k := MeshKit.new()
	ArchKit.lot(k, 7.9, 7.9, t)
	t = clampi(t, 0, 4)
	_lp_bays(k, t)
	match t:
		0:
			_lp0(k)
			_lp0x(k)
		1:
			_lp1(k)
			_lp1x(k)
			_lp1y(k)
		2:
			_lp2(k)
			_lp2x(k)
			_lp2y(k)
		3:
			_lp3(k)
			_lp3x(k)
			_lp3y(k)
		_:
			_lp4(k)
			_lp4x(k)
			_lp4y(k)
	_life(k, "launchpad", clampi(t, 0, 4))
	_finish(k, "launchpad", clampi(t, 0, 4))
	_dense(k, "launchpad", clampi(t, 0, 4))
	return k.commit()


## The three assembly benches (GPUs, HBM, power land on them).
static func _lp_bays(k: MeshKit, t: int) -> void:
	var p := ArchKit.pal(t)
	var cols := [Color(0.3, 0.62, 0.42), Color(0.24, 0.36, 0.56), Color(0.46, 0.82, 0.52)]
	for i in 3:
		var x := -2.6 + i * 1.3
		var c: Color = cols[i]
		match t:
			0:
				table(k, at(x, 0.1, 2.6), 1.1, 0.8, Color(0.92, 0.9, 0.86), Color(0.4, 0.42, 0.45), 0.78)
				k.box(Vector3(1.12, 0.012, 0.82), c, at(x, 0.885, 2.6))
				k.box(Vector3(1.12, 0.2, 0.01), c, at(x, 0.78, 3.01))
			1:
				k.box(Vector3(1.1, 0.06, 0.8), p["metal"], at(x, 0.85, 2.6))
				for sx in [-1.0, 1.0]:
					for sz in [-1.0, 1.0]:
						k.box(Vector3(0.06, 0.75, 0.06), p["trim"], at(x + sx * 0.48, 0.47, 2.6 + sz * 0.34))
				k.box(Vector3(1.0, 0.04, 0.7), p["trim"], at(x, 0.3, 2.6))
				k.box(Vector3(1.12, 0.03, 0.82), c, at(x, 0.885, 2.6))
			2:
				k.rbox(Vector3(1.1, 0.75, 0.8), 0.04, Color(0.96, 0.96, 0.97), at(x, 0.47, 2.6), 1)
				k.box(Vector3(1.12, 0.03, 0.82), c, at(x, 0.865, 2.6))
				k.box(Vector3(0.9, 0.02, 0.01), lit(p["glow"], 0.4), at(x, 0.7, 3.005))
			3:
				k.box(Vector3(1.1, 0.75, 0.8), p["dark"], at(x, 0.47, 2.6))
				k.box(Vector3(1.14, 0.04, 0.84), c, at(x, 0.865, 2.6))
				k.box(Vector3(1.0, 0.03, 0.01), lit(p["accent2"], 0.4), at(x, 0.6, 3.005))
				for j in 4:
					k.box(Vector3(0.12, 0.006, 0.84), p["accent"], at(x - 0.45 + j * 0.3, 0.11, 3.2))
			_:
				k.box(Vector3(1.1, 0.75, 0.8), p["wall2"], at(x, 0.47, 2.6))
				k.box(Vector3(1.14, 0.03, 0.84), p["trim"], at(x, 0.85, 2.6))
				k.box(Vector3(1.0, 0.012, 0.7), lit(c, 0.45), at(x, 0.87, 2.6))
				k.box(Vector3(0.05, 0.6, 0.01), lit(p["glow"], 0.4), at(x, 0.47, 3.005))


## A lightning mast with a finial (base on the ground).
static func _lightning_mast(k: MeshKit, p: Vector3, h: float, col: Color) -> Vector3:
	k.box(Vector3(0.5, 0.25, 0.5), Color(0.6, 0.6, 0.6), at(p.x, p.y + 0.125, p.z))
	mast(k, p + Vector3(0, 0.25, 0), h, 0.4, 0.12, col, 0.6, 0.035)
	k.cyl(0.02, 1.2, Color(0.7, 0.72, 0.74), at(p.x, p.y + h + 0.25, p.z), 4)
	ArchKit.beacon(k, p + Vector3(0, h * 0.6, 0.2), 0.1)
	return p + Vector3(0, h + 1.4, 0)


## Garage: a backyard launch stand, a folding table and a kid's countdown board.
static func _lp0(k: MeshKit) -> void:
	var t := 0
	var pad := Vector3(0.8, 0.1, -1.4)
	# lawn patches
	for i in 6:
		k.box(Vector3(1.4, 0.02, 1.0), Color(0.48, 0.6, 0.36), xf(Vector3(-2.8 + (i % 3) * 2.8, 0.105, -3.0 + (i / 3) * 3.4), Vector3(0, i * 23.0, 0)))
	# the stand: cinder blocks and a plywood deck (top at 0.52)
	for sx in [-1.0, 0.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.4, 0.2, 0.2), Color(0.66, 0.66, 0.64), at(pad.x + sx * 0.5, 0.2, pad.z + sz * 0.45))
			k.box(Vector3(0.4, 0.2, 0.2), Color(0.62, 0.62, 0.6), at(pad.x + sx * 0.5, 0.4, pad.z + sz * 0.45))
	k.box(Vector3(1.6, 0.03, 1.3), Pal.WOOD_LIGHT, at(pad.x, 0.505, pad.z))
	k.box(Vector3(1.1, 0.012, 1.1), Color(0.3, 0.3, 0.32), at(pad.x, 0.525, pad.z))
	# a kiddie pool as a flame bucket, buckets of water, a garden hose reel
	k.cyl(0.8, 0.25, Color(0.4, 0.75, 0.9), at(2.3, 0.1, -0.4), 12)
	k.cyl(0.72, 0.02, lit(Color(0.5, 0.8, 0.95), 0.75), at(2.3, 0.3, -0.4), 12)
	for i in 3:
		k.cyl(0.14, 0.3, Color(0.86, 0.3, 0.26) if i != 1 else Color(0.3, 0.5, 0.8), at(1.9 + i * 0.32, 0.1, 0.55), 8)
	k.cyl(0.3, 0.12, Color(0.3, 0.6, 0.34), xf(Vector3(-3.4, 0.4, -2.0), Vector3(0, 0, 90)), 10)
	k.box(Vector3(0.1, 0.6, 0.4), Color(0.3, 0.3, 0.32), at(-3.5, 0.4, -2.0))
	ArchKit.pipes(k, [Vector3(-3.3, 0.3, -2.0), Vector3(-2.0, 0.12, -1.5), Vector3(-0.2, 0.12, -1.2)], 0.02, Color(0.3, 0.6, 0.34))
	# the "gantry": a wooden scaffold with a ladder and a plank
	var gp := Vector3(-1.0, 0.1, -1.4)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.08, 3.6, 0.08), Pal.WOOD, at(gp.x + sx * 0.4, 1.9, gp.z + sz * 0.4))
	for y in [1.2, 2.4, 3.6]:
		k.box(Vector3(0.9, 0.05, 0.9), Pal.WOOD_LIGHT, at(gp.x, y, gp.z))
		beam(k, Vector3(gp.x - 0.4, y - 1.1, gp.z + 0.42), Vector3(gp.x + 0.4, y, gp.z + 0.42), 0.04, Pal.WOOD_DARK)
	k.box(Vector3(0.7, 0.04, 0.25), Pal.WOOD_LIGHT, at(gp.x + 0.75, 2.4, gp.z))
	ArchKit.ladder(k, xf(gp + Vector3(0, 0, 0.45), Vector3(0, 0, 0)), 3.6, Color(0.7, 0.72, 0.74))
	k.box(Vector3(0.3, 0.2, 0.2), Color(0.85, 0.3, 0.28), at(gp.x, 3.73, gp.z))
	# the kid's countdown board on an easel
	var cb := xf(Vector3(-2.6, 0.1, 0.4), Vector3(0, 25, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.05, 1.6, 0.05), Pal.WOOD, cb * xf(Vector3(sx * 0.5, 0.8, 0), Vector3(-8, 0, 0)))
	k.box(Vector3(1.2, 0.8, 0.04), Color(0.2, 0.28, 0.24), cb * xf(Vector3(0, 1.2, 0.06), Vector3(-8, 0, 0)))
	k.box(Vector3(1.26, 0.86, 0.03), Pal.WOOD_LIGHT, cb * xf(Vector3(0, 1.2, 0.04), Vector3(-8, 0, 0)))
	text(k, "321", cb * xf(Vector3(-0.15, 1.05, 0.1), Vector3(-8, 0, 0)), 0.06, Color(0.95, 0.95, 0.9))
	text(k, "GO", cb * xf(Vector3(0.38, 1.1, 0.1), Vector3(-8, 0, 0)), 0.04, Color(0.95, 0.85, 0.3))
	k.box(Vector3(0.9, 0.04, 0.04), Color(0.95, 0.5, 0.6), cb * xf(Vector3(0, 1.5, 0.1), Vector3(-8, 0, 0)))
	# the folding table with a laptop and a launch box with a big red button
	table(k, at(-0.9, 0.1, 0.5), 1.2, 0.6, Color(0.9, 0.9, 0.88), Color(0.4, 0.42, 0.45))
	laptop(k, xf(Vector3(-1.15, 0.84, 0.5), Vector3(0, 165, 0)))
	k.box(Vector3(0.25, 0.1, 0.18), Color(0.95, 0.8, 0.2), at(-0.55, 0.89, 0.5))
	k.cyl(0.05, 0.04, Color(0.9, 0.2, 0.2), at(-0.55, 0.94, 0.5), 8)
	cable(k, Vector3(-0.55, 0.84, 0.4), Vector3(pad.x - 0.6, 0.5, pad.z + 0.6), 0.2, Color(0.95, 0.5, 0.15), 0.015)
	for i in 3:
		chair(k, xf(Vector3(-1.6 + i * 0.7, 0.1, 1.2), Vector3(0, 180 + (i - 1) * 15.0, 0)), [Color(0.3, 0.6, 0.4), Color(0.85, 0.35, 0.3), Color(0.3, 0.5, 0.8)][i])
	# propane bottles for "fuel", a cooler, a toolbox
	for i in 3:
		k.cyl(0.16, 0.5, Color(0.92, 0.92, 0.9), at(2.7 + i * 0.36, 0.1, -3.2), 8)
		k.sphere(0.16, Color(0.92, 0.92, 0.9), at(2.7 + i * 0.36, 0.6, -3.2), 8, 4)
		k.cyl(0.04, 0.08, Color(0.3, 0.3, 0.32), at(2.7 + i * 0.36, 0.72, -3.2), 6)
	k.box(Vector3(0.5, 0.35, 0.32), Color(0.2, 0.45, 0.75), at(-0.2, 0.28, 1.4))
	k.box(Vector3(0.52, 0.06, 0.34), Color(0.95, 0.95, 0.94), at(-0.2, 0.48, 1.4))
	k.box(Vector3(0.45, 0.22, 0.2), Color(0.85, 0.2, 0.18), at(1.6, 0.21, -0.2))
	# the garden shed (mission control, flat roof)
	var sp := Vector3(3.0, 0.1, 2.4)
	ArchKit.planks(k, at(sp.x, 0.1, sp.z + 0.65), 1.7, 1.9, Color(0.66, 0.5, 0.36))
	ArchKit.planks(k, xf(Vector3(sp.x, 0.1, sp.z - 0.65), Vector3(0, 180, 0)), 1.7, 1.9, Color(0.66, 0.5, 0.36))
	for sx in [-1.0, 1.0]:
		ArchKit.planks(k, xf(Vector3(sp.x + sx * 0.85, 0.1, sp.z), Vector3(0, sx * 90.0, 0)), 1.3, 1.9, Color(0.66, 0.5, 0.36))
	k.box(Vector3(1.9, 0.08, 1.5), Color(0.3, 0.3, 0.32), at(sp.x, 2.04, sp.z))
	k.box(Vector3(0.6, 1.6, 0.05), Pal.WOOD_DARK, at(sp.x - 0.4, 0.9, sp.z + 0.69))
	k.box(Vector3(0.45, 0.35, 0.04), Color(0.66, 0.78, 0.84, 0.75), at(sp.x + 0.4, 1.3, sp.z + 0.7))
	k.box(Vector3(1.0, 0.3, 0.04), Color(0.95, 0.93, 0.86), at(sp.x, 1.75, sp.z + 0.72))
	text(k, "NASA", at(sp.x, 1.66, sp.z + 0.74), 0.035, Color(0.26, 0.46, 0.78))
	ArchKit.string_lights(k, Vector3(sp.x - 0.9, 1.95, sp.z + 0.75), Vector3(-2.0, 1.8, 1.9), 10)
	# picket fence around the yard
	ArchKit.fence(k, Vector3(-3.88, 0.1, -3.88), Vector3(3.88, 0.1, -3.88), t, 1.0)
	ArchKit.fence(k, Vector3(-3.88, 0.1, -3.88), Vector3(-3.88, 0.1, 0.8), t, 1.0)
	ArchKit.fence(k, Vector3(3.88, 0.1, -3.88), Vector3(3.88, 0.1, 0.2), t, 1.0)
	shrub(k, Vector3(-3.0, 0.1, -3.2), 0.5, 1.2)
	shrub(k, Vector3(1.9, 0.1, -3.2), 0.35)


## Workshop: a concrete pad on gravel, a red steel gantry, a container
## control room, gas bottle racks.
static func _lp1(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var pad := Vector3(0.8, 0.1, -1.4)
	# gravel apron, the concrete pad with a steel deflector plate
	k.cyl(2.3, 0.04, Color(0.6, 0.58, 0.54), at(pad.x, 0.1, pad.z), 16)
	for i in 14:
		var a := i * 2.3
		k.box(Vector3(0.12, 0.03, 0.09), Color(0.5, 0.48, 0.45), xf(Vector3(pad.x + cos(a) * (1.5 + (i % 3) * 0.25), 0.14, pad.z + sin(a) * (1.5 + (i % 3) * 0.25)), Vector3(0, i * 40.0, 0)))
	k.box(Vector3(2.0, 0.38, 2.0), Color(0.7, 0.7, 0.68), at(pad.x, 0.29, pad.z))
	k.box(Vector3(1.3, 0.04, 1.3), Color(0.36, 0.37, 0.4), at(pad.x, 0.5, pad.z))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.2, 0.2, 0.2), p["accent"], at(pad.x + sx * 0.6, 0.6, pad.z + sz * 0.6))
	# the gantry: a red lattice tower with service arms
	var gp := Vector3(-1.5, 0.1, -1.4)
	k.box(Vector3(1.4, 0.3, 1.4), Color(0.62, 0.62, 0.6), at(gp.x, 0.25, gp.z))
	mast(k, gp + Vector3(0, 0.4, 0), 8.0, 1.0, 0.8, Color(0.86, 0.3, 0.26), 0.8, 0.07)
	for i in 3:
		var y := 2.4 + i * 2.0
		k.box(Vector3(1.1, 0.06, 1.1), p["metal"].darkened(0.2), at(gp.x, y, gp.z))
		k.box(Vector3(1.6, 0.1, 0.3), p["trim"], at(gp.x + 1.1, y, gp.z))
		ArchKit.railing(k, Vector3(gp.x + 0.5, y, gp.z + 0.15), Vector3(gp.x + 1.85, y, gp.z + 0.15), 0.7, p["accent"], 0.45)
		ArchKit.pipes(k, [Vector3(gp.x + 0.5, y + 0.1, gp.z - 0.1), Vector3(gp.x + 1.85, y + 0.1, gp.z - 0.1)], 0.04, Color(0.2, 0.2, 0.22))
	ArchKit.ladder(k, xf(gp + Vector3(0, 0.4, 0.55), Vector3(0, 180, 0)), 7.6, p["metal"], true)
	k.box(Vector3(1.2, 0.3, 1.2), p["dark"], at(gp.x, 8.6, gp.z))
	ArchKit.beacon(k, gp + Vector3(0, 8.75, 0), 0.3)
	ArchKit.lamp(k, gp + Vector3(0.4, 8.55, 0.4), t, 0.3)
	# the container control room (flat roof at the slot)
	var cc := Color(0.9, 0.9, 0.88)
	container(k, at(3.0, 0.25, 2.4), 1.7, cc, 2.2, 1.5)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.25, 0.15, 1.3), Color(0.62, 0.62, 0.6), at(3.0 + sx * 0.6, 0.17, 2.4))
	k.box(Vector3(0.9, 0.5, 0.04), p["glass"], at(3.2, 1.45, 3.17))
	k.box(Vector3(1.0, 0.06, 0.12), p["trim"], at(3.2, 1.75, 3.2))
	ArchKit.door(k, xf(Vector3(2.15, 0.25, 2.4), Vector3(0, -90, 0)), t, 0.7, 1.9)
	k.box(Vector3(0.4, 0.15, 0.8), p["metal"], at(1.95, 0.17, 2.4))
	k.box(Vector3(0.7, 0.3, 0.4), Color(0.9, 0.9, 0.9), at(3.0, 0.5, 3.3))
	k.box(Vector3(1.2, 0.3, 0.04), p["accent"], at(3.0, 2.2, 3.17))
	text(k, "LAUNCH", at(3.0, 2.1, 3.2), 0.035, p["dark"])
	k.cyl(0.03, 1.4, p["metal"], at(3.6, 2.45, 1.9), 5)
	ArchKit.beacon(k, Vector3(3.6, 3.85, 1.9), 0.15)
	# gas bottle racks (fuel and oxidiser) at the back right, with pipes
	for r in 2:
		for i in 5:
			var c := Color(0.92, 0.92, 0.9) if r == 0 else Color(0.3, 0.5, 0.8)
			k.cyl(0.13, 1.1, c, at(2.4 + i * 0.32, 0.1, -3.4 + r * 0.45), 8)
			k.sphere(0.13, c, at(2.4 + i * 0.32, 1.2, -3.4 + r * 0.45), 8, 4)
		k.box(Vector3(1.7, 0.05, 0.05), p["accent"], at(3.04, 0.8, -3.2 + r * 0.45))
	ArchKit.pipes(k, [Vector3(2.4, 1.0, -2.8), Vector3(2.0, 0.2, -2.4), Vector3(pad.x + 0.9, 0.2, pad.z - 0.6)], 0.05, Color(0.3, 0.5, 0.8))
	# a water trailer, floodlight masts, chain-link, cones
	k.capsule(0.42, 1.6, Color(0.9, 0.9, 0.88), xf(Vector3(3.65, 0.8, -2.15), Vector3(0, 0, 90)), 10, 3)
	k.box(Vector3(1.8, 0.1, 0.8), p["trim"], at(2.85, 0.38, -2.15))
	for sz in [-1.0, 1.0]:
		k.cyl(0.18, 0.1, Color(0.15, 0.15, 0.16), xf(Vector3(2.85, 0.28, -2.15 + sz * 0.45), Vector3(90, 0, 0)), 8)
	ArchKit.lamp(k, Vector3(-3.5, 0.1, -3.4), t, 4.0)
	ArchKit.lamp(k, Vector3(-3.5, 0.1, 0.9), t, 3.2)
	ArchKit.fence(k, Vector3(-3.88, 0.1, -3.88), Vector3(3.88, 0.1, -3.88), t, 1.6)
	cone(k, Vector3(1.4, 0.1, 0.6))
	cone(k, Vector3(2.2, 0.1, 0.6))
	for i in 5:
		k.box(Vector3(0.4, 0.006, 0.12), p["accent"] if i % 2 == 0 else p["dark"], at(-0.3 + i * 0.4, 0.106, 1.4))


## Campus: a white launch complex: a flame trench, a white gantry with
## umbilical arms, spherical tanks and a glass control tower.
static func _lp2(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var pad := Vector3(0.8, 0.1, -1.4)
	var wc: Color = p["wall"]
	# the pad: a white plinth with a flame trench out to the right
	k.box(Vector3(2.8, 0.42, 2.8), wc, at(pad.x, 0.31, pad.z))
	k.cyl(0.85, 0.02, Color(0.3, 0.31, 0.34), at(pad.x, 0.51, pad.z), 14)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.16, 0.24, 0.16), p["trim"], at(pad.x + sx * 0.7, 0.64, pad.z + sz * 0.7))
	k.box(Vector3(1.7, 0.04, 0.9), Color(0.24, 0.25, 0.28), at(3.05, 0.12, pad.z))
	for sz in [-1.0, 1.0]:
		k.box(Vector3(1.7, 0.4, 0.15), wc, at(3.05, 0.3, pad.z + sz * 0.52))
	k.prism(PackedVector2Array([Vector2(0, -0.4), Vector2(0.9, -0.4), Vector2(0.9, 0.4), Vector2(0, 0.4)]), 0.3, Color(0.4, 0.42, 0.46), xf(Vector3(2.2, 0.12, pad.z), Vector3(0, 0, -15)))
	# the white gantry with teal bands and swing arms
	var gp := Vector3(-1.4, 0.1, -1.4)
	k.box(Vector3(1.3, 8.4, 1.3), wc, at(gp.x, 0.1 + 4.2, gp.z))
	for i in 7:
		k.box(Vector3(1.34, 0.1, 1.34), p["trim"] if i % 2 == 0 else p["wall2"], at(gp.x, 1.2 + i * 1.1, gp.z))
		k.box(Vector3(1.0, 0.3, 0.02), p["glass"], at(gp.x, 1.6 + i * 1.1, gp.z + 0.66))
	for y in [3.0, 5.2, 7.0]:
		k.box(Vector3(1.6, 0.25, 0.4), wc, at(gp.x + 1.4, y, gp.z))
		k.box(Vector3(1.6, 0.04, 0.42), p["trim"], at(gp.x + 1.4, y + 0.14, gp.z))
		ArchKit.pipes(k, [Vector3(gp.x + 0.7, y - 0.15, gp.z + 0.1), Vector3(gp.x + 2.1, y - 0.15, gp.z + 0.1)], 0.04, Color(0.86, 0.86, 0.84))
	k.box(Vector3(1.0, 0.6, 1.0), p["wall2"], at(gp.x, 8.8, gp.z))
	ArchKit.beacon(k, gp + Vector3(0, 9.1, 0), 0.3)
	# a white lightning mast at the back
	_lightning_mast(k, Vector3(-0.6, 0.1, -3.5), 7.5, Color(0.92, 0.92, 0.92))
	# spherical tanks on legs at the back right
	for i in 2:
		var tp := Vector3(2.45 + i * 0.85, 0.1, -3.1 + i * 0.4)
		for j in 4:
			var a := TAU * j / 4.0 + 0.4
			k.box(Vector3(0.07, 0.9, 0.07), p["metal"], at(tp.x + cos(a) * 0.32, 0.55, tp.z + sin(a) * 0.32))
		k.sphere(0.48, Color(0.97, 0.97, 0.97), at(tp.x, 1.3, tp.z), 12, 7)
		k.cyl(0.49, 0.06, p["trim"], at(tp.x, 1.3, tp.z), 12)
	ArchKit.pipes(k, [Vector3(2.6, 0.9, -2.6), Vector3(2.2, 0.25, -2.0), Vector3(pad.x + 1.4, 0.25, pad.z - 0.8)], 0.05, Color(0.86, 0.86, 0.84))
	# the glass control tower: a white shaft, a glass cab, a flat roof
	var cp := Vector3(2.9, 0.1, 2.4)
	k.rbox(Vector3(1.2, 4.2, 1.2), 0.05, wc, at(cp.x, 0.1 + 2.1, cp.z), 1)
	for i in 4:
		k.box(Vector3(0.6, 0.6, 0.03), p["glass"], at(cp.x, 0.9 + i * 0.9, cp.z + 0.61))
	k.box(Vector3(1.8, 0.15, 1.8), wc, at(cp.x, 4.35, cp.z))
	ArchKit.curtain(k, at(cp.x, 4.42, cp.z + 0.85), 1.7, 1.0, t, 4, 1)
	for sx in [-1.0, 1.0]:
		ArchKit.curtain(k, xf(Vector3(cp.x + sx * 0.85, 4.42, cp.z), Vector3(0, sx * 90.0, 0)), 1.7, 1.0, t, 4, 1)
	k.box(Vector3(1.7, 1.0, 0.05), p["wall2"], at(cp.x, 4.92, cp.z - 0.85))
	k.box(Vector3(1.95, 0.15, 1.95), wc, at(cp.x, 5.5, cp.z))
	k.box(Vector3(1.97, 0.06, 1.97), p["trim"], at(cp.x, 5.44, cp.z))
	k.box(Vector3(0.6, 1.9, 0.05), p["glass"], at(cp.x - 0.3, 1.05, cp.z + 0.62))
	# planters, a logo wall, kerb lights
	k.box(Vector3(1.6, 0.6, 0.2), wc, at(1.2, 0.4, 0.4))
	k.box(Vector3(0.4, 0.4, 0.02), p["accent"], at(0.65, 0.42, 0.51))
	text(k, "LAUNCH", at(1.35, 0.32, 0.51), 0.035, p["dark"])
	ArchKit.planter(k, Vector3(2.2, 0.1, 0.4), t, 0.6, true)
	ArchKit.planter(k, Vector3(-3.2, 0.1, -2.5), t, 0.7, true)
	ArchKit.lamp(k, Vector3(-3.4, 0.1, 0.9), t, 2.8)
	for i in 4:
		k.box(Vector3(0.12, 0.04, 0.12), lit(p["glow"], 0.35), at(-0.5 + i * 0.9, 0.12, 0.05))


## Industrial: a heavy service structure, a water tower, lightning masts with
## catenary wires, a fuel tank farm in a bund, pipe racks to the pad.
static func _lp3(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var pad := Vector3(0.8, 0.1, -1.4)
	# the pad: a stepped concrete mount, steel blast walls, a deflector
	k.box(Vector3(3.0, 0.2, 3.0), Color(0.56, 0.57, 0.58), at(pad.x, 0.2, pad.z))
	k.box(Vector3(2.2, 0.22, 2.2), Color(0.6, 0.61, 0.62), at(pad.x, 0.41, pad.z))
	k.cyl(0.8, 0.02, Color(0.2, 0.2, 0.22), at(pad.x, 0.52, pad.z), 14)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.2, 0.35, 0.2), p["accent"], at(pad.x + sx * 0.75, 0.65, pad.z + sz * 0.75))
	k.box(Vector3(3.2, 1.1, 0.25), p["wall2"], at(pad.x, 0.65, pad.z + 1.75))
	for i in 6:
		k.box(Vector3(0.06, 1.1, 0.04), p["trim"], at(pad.x - 1.5 + i * 0.6, 0.65, pad.z + 1.89))
	# the service structure: a heavy steel tower, a hammerhead crane, arms
	var gp := Vector3(-1.4, 0.1, -1.4)
	k.box(Vector3(1.6, 0.4, 1.6), Color(0.55, 0.56, 0.58), at(gp.x, 0.3, gp.z))
	mast(k, gp + Vector3(0, 0.5, 0), 9.0, 1.3, 1.1, p["metal"], 0.75, 0.09, p["trim"])
	for i in 4:
		var y := 2.2 + i * 1.9
		k.box(Vector3(1.4, 0.08, 1.4), p["trim"], at(gp.x, y, gp.z))
		k.box(Vector3(1.3, 0.25, 0.5), p["metal"], at(gp.x + 1.25, y, gp.z))
		ArchKit.railing(k, Vector3(gp.x + 0.7, y, gp.z + 0.25), Vector3(gp.x + 1.9, y, gp.z + 0.25), 0.8, p["accent"], 0.4)
		k.box(Vector3(1.2, 0.03, 0.03), lit(p["glow"], 0.4), at(gp.x + 1.25, y - 0.14, gp.z + 0.26))
	k.box(Vector3(3.6, 0.3, 0.35), p["accent"], at(gp.x + 0.4, 9.7, gp.z))
	k.box(Vector3(0.5, 0.5, 0.5), p["dark"], at(gp.x - 1.1, 9.5, gp.z))
	k.box(Vector3(0.02, 1.6, 0.02), Color(0.2, 0.2, 0.22), at(gp.x + 1.8, 8.8, gp.z))
	k.box(Vector3(0.2, 0.15, 0.15), p["accent"], at(gp.x + 1.8, 8.0, gp.z))
	ArchKit.beacon(k, gp + Vector3(0, 9.85, 0), 0.4)
	# a zigzag stair beside the tower
	for i in 3:
		ArchKit.stairs(k, xf(Vector3(-2.5, 0.1 + i * 1.9, -0.3 if i % 2 == 0 else -2.5), Vector3(0, 0 if i % 2 == 0 else 180, 0)), 0.45, 1.9, t)
		k.box(Vector3(0.5, 0.05, 0.5), p["metal"], at(-2.5, 0.1 + (i + 1) * 1.9, -2.5 if i % 2 == 0 else -0.3))
	for z in [-0.3, -2.5]:
		k.box(Vector3(0.06, 5.8, 0.06), p["trim"], at(-2.74, 2.95, z))
	# lightning masts and catenary wires over the pad
	var m1 := _lightning_mast(k, Vector3(-0.4, 0.1, -3.5), 9.0, Color(0.82, 0.84, 0.86))
	var m2 := _lightning_mast(k, Vector3(2.3, 0.1, -3.5), 9.0, Color(0.82, 0.84, 0.86))
	var m3 := _lightning_mast(k, Vector3(2.4, 0.1, 0.6), 8.0, Color(0.82, 0.84, 0.86))
	cable(k, m1 + Vector3(0, -0.6, 0), m2 + Vector3(0, -0.6, 0), 0.8, Color(0.3, 0.3, 0.32), 0.015, 6)
	cable(k, m2 + Vector3(0, -0.6, 0), m3 + Vector3(0, -0.6, 0), 0.8, Color(0.3, 0.3, 0.32), 0.015, 6)
	# the water tower at the back right corner
	var wt := Vector3(3.25, 0.1, -3.2)
	for j in 4:
		var a := TAU * j / 4.0 + PI / 4.0
		beam(k, wt + Vector3(cos(a) * 0.55, 0, sin(a) * 0.55), wt + Vector3(cos(a) * 0.35, 5.4, sin(a) * 0.35), 0.08, p["metal"])
	for y in [1.5, 3.0, 4.5]:
		for j in 4:
			var a1 := TAU * j / 4.0 + PI / 4.0
			var a2 := TAU * (j + 1) / 4.0 + PI / 4.0
			var r := lerpf(0.55, 0.35, y / 5.4)
			beam(k, wt + Vector3(cos(a1) * r, y, sin(a1) * r), wt + Vector3(cos(a2) * r, y, sin(a2) * r), 0.05, p["metal"])
	k.cyl(0.6, 1.3, Color(0.82, 0.84, 0.86), at(wt.x, 5.4, wt.z), 12)
	k.cone(0.65, 0.5, Color(0.7, 0.72, 0.74), at(wt.x, 6.7, wt.z), 12)
	k.box(Vector3(0.1, 5.4, 0.1), Color(0.36, 0.6, 0.86), at(wt.x - 0.45, 2.7, wt.z + 0.3))
	text(k, "H2O", at(wt.x, 5.9, wt.z + 0.6), 0.06, p["dark"])
	# the fuel tank farm in a bund wall on the right
	k.box(Vector3(1.4, 0.3, 0.1), p["wall2"], at(3.2, 0.25, -2.4))
	k.box(Vector3(1.4, 0.3, 0.1), p["wall2"], at(3.2, 0.25, -1.0))
	k.box(Vector3(0.1, 0.3, 1.4), p["wall2"], at(2.5, 0.25, -1.7))
	for i in 2:
		htank(k, xf(Vector3(3.2, 0.1, -2.05 + i * 0.7), Vector3(0, 0, 0)), 0.28, 1.0, Color(0.92, 0.92, 0.9) if i == 0 else Color(0.3, 0.5, 0.8))
	ArchKit.pipe_rack(k, xf(Vector3(1.8, 0.1, -0.5), Vector3(0, 0, 0)), 1.2, 1.0, t, 3)
	ArchKit.pipes(k, [Vector3(2.6, 0.6, -1.2), Vector3(2.4, 1.1, -0.5), Vector3(1.2, 1.1, -0.5), Vector3(pad.x + 0.3, 0.6, pad.z + 0.9)], 0.06, Color(0.36, 0.6, 0.86))
	# the blockhouse: a concrete bunker with slit windows and blue LEDs
	var cp := Vector3(3.0, 0.1, 2.4)
	k.rbox(Vector3(1.8, 2.0, 1.6), 0.08, Color(0.58, 0.59, 0.6), at(cp.x, 0.1 + 1.0, cp.z), 1)
	k.box(Vector3(1.4, 0.18, 0.04), p["glass"], at(cp.x, 1.55, cp.z + 0.81))
	k.box(Vector3(1.9, 0.12, 1.7), p["trim"], at(cp.x, 2.16, cp.z))
	k.box(Vector3(1.6, 0.03, 0.03), lit(p["glow"], 0.4), at(cp.x, 1.3, cp.z + 0.82))
	ArchKit.door(k, xf(Vector3(cp.x - 0.9, 0.1, cp.z), Vector3(0, -90, 0)), t, 0.7, 1.8)
	ArchKit.generator(k, xf(Vector3(-3.35, 0.1, -1.75), Vector3(0, 90, 0)), t)
	ArchKit.lamp(k, Vector3(-3.5, 0.1, 0.9), t, 3.2)
	for z in [-0.8, 1.4]:
		k.box(Vector3(5.0, 0.006, 0.08), p["accent"], at(0.0, 0.106, z))


## Hyperscale: a graphite spaceport: a glowing launch ring, a brass gantry
## with cantilevered arms, glowing cryo tanks, a control pavilion.
static func _lp4(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var g: Color = p["wall"]
	var g2: Color = p["wall2"]
	var brass: Color = p["trim"]
	var pad := Vector3(0.8, 0.1, -1.4)
	# the pad: a graphite disc, a glowing launch ring, brass clamps
	k.cyl(2.0, 0.42, g2, at(pad.x, 0.1, pad.z), 16, 0.04)
	k.cyl(0.8, 0.02, Color(0.06, 0.06, 0.08), at(pad.x, 0.52, pad.z), 14)
	ring(k, pad + Vector3(0, 0.46, 0), 1.6, 0.07, lit(p["accent2"], 0.4), Vector3.ZERO, 24)
	ring(k, pad + Vector3(0, 0.46, 0), 1.9, 0.03, brass, Vector3.ZERO, 24)
	ring(k, pad + Vector3(0, 1.6, 0), 1.25, 0.04, lit(p["glow"], 0.35), Vector3.ZERO, 24)
	for i in 6:
		var a := TAU * i / 6.0
		var q := pad + Vector3(cos(a) * 1.25, 0.42, sin(a) * 1.25)
		k.box(Vector3(0.14, 1.2, 0.14), g, at(q.x, q.y + 0.6, q.z))
		k.box(Vector3(0.16, 0.05, 0.16), brass, at(q.x, q.y + 1.2, q.z))
	# the gantry: a graphite tower, brass seams, cantilevered brass arms
	var gp := Vector3(-1.4, 0.1, -1.4)
	k.box(Vector3(1.2, 9.6, 1.2), g, at(gp.x, 0.1 + 4.8, gp.z))
	for i in 9:
		k.box(Vector3(1.24, 0.05, 1.24), brass, at(gp.x, 1.0 + i * 1.05, gp.z))
		k.box(Vector3(0.04, 0.8, 0.02), lit(p["accent2"], 0.4), at(gp.x + 0.3, 1.5 + i * 1.05, gp.z + 0.61))
		k.box(Vector3(0.04, 0.8, 0.02), lit(p["accent2"], 0.4), at(gp.x - 0.3, 1.5 + i * 1.05, gp.z + 0.61))
	for y in [2.8, 5.0, 7.2]:
		beam(k, Vector3(gp.x + 0.6, y, gp.z), Vector3(gp.x + 2.0, y, gp.z), 0.16, brass, 0.3)
		beam(k, Vector3(gp.x + 0.6, y - 0.9, gp.z), Vector3(gp.x + 1.6, y - 0.1, gp.z), 0.08, brass)
		k.box(Vector3(0.2, 0.32, 0.5), g2, at(gp.x + 2.0, y, gp.z))
		k.box(Vector3(1.3, 0.03, 0.03), lit(p["glow"], 0.4), at(gp.x + 1.3, y - 0.17, gp.z + 0.16))
	# the crown on the gantry
	for i in 6:
		var a2 := TAU * i / 6.0
		beam(k, gp + Vector3(cos(a2) * 0.3, 9.6, sin(a2) * 0.3), gp + Vector3(cos(a2) * 0.5, 10.4, sin(a2) * 0.5), 0.05, brass)
	k.sphere(0.24, lit(p["glow"], 0.3), at(gp.x, 10.2, gp.z), 8, 5)
	ArchKit.beacon(k, gp + Vector3(0, 10.4, 0), 0.4)
	# glowing cryo tanks at the back right, glowing fuel lines to the pad
	for i in 3:
		var tp := Vector3(2.4 + i * 0.6, 0.1, -3.3 + (i % 2) * 0.5)
		k.cyl(0.32, 2.6, g2, at(tp.x, tp.y, tp.z), 10)
		k.sphere(0.32, g2, xf(Vector3(tp.x, 2.7, tp.z), Vector3.ZERO, Vector3(1, 0.5, 1)), 10, 4)
		for j in 3:
			k.cyl(0.335, 0.05, brass, at(tp.x, 0.6 + j * 0.8, tp.z), 10)
		k.box(Vector3(0.04, 2.0, 0.02), lit(p["accent2"], 0.4), at(tp.x, 1.4, tp.z + 0.33))
	for i in 2:
		ArchKit.pipes(k, [Vector3(2.5 + i * 0.6, 0.4, -2.9), Vector3(2.3, 0.2, -2.2 + i * 0.15), Vector3(pad.x + 1.5, 0.2, pad.z - 0.5 + i * 0.15)], 0.05, lit(p["accent2"] if i == 0 else Color(1.0, 0.6, 0.4), 0.5))
	# the control pavilion: graphite, a brass-framed glass band, flat roof
	var cp := Vector3(3.0, 0.1, 2.4)
	k.box(Vector3(1.6, 2.6, 1.6), g, at(cp.x, 0.1 + 1.3, cp.z))
	k.box(Vector3(1.5, 0.7, 0.04), p["glass"], at(cp.x, 1.9, cp.z + 0.81))
	for i in 5:
		k.box(Vector3(0.04, 0.8, 0.06), brass, at(cp.x - 0.7 + i * 0.35, 1.9, cp.z + 0.83))
	k.box(Vector3(1.75, 0.12, 1.8), brass, at(cp.x, 2.76, cp.z))
	k.box(Vector3(1.66, 0.04, 1.7), g2, at(cp.x, 2.84, cp.z))
	ArchKit.fins(k, xf(Vector3(cp.x - 0.9, 0.1, cp.z), Vector3(0, -90, 0)), 1.4, 1.4, 4, t)
	# a drone pad on a graphite plinth, glowing runway lines, beacons
	k.box(Vector3(1.2, 0.6, 1.2), g, at(-3.1, 0.4, -0.6))
	ArchKit.drone_pad(k, Vector3(-3.1, 0.72, -0.6), 0.55, t)
	drone(k, Vector3(-2.9, 1.6, -0.5), t, 15.0)
	for i in 6:
		k.box(Vector3(0.05, 0.006, 1.0), lit(p["accent2"], 0.4), at(-0.9 + i * 0.45, 0.106, 0.6))
	for x in [-3.6, 3.6]:
		ArchKit.beacon(k, Vector3(x, 0.1, -3.6), 1.2)
	ArchKit.lamp(k, Vector3(-3.5, 0.1, 0.9), t, 3.0)


## Launch Complex detail passes.
static func _lp0x(k: MeshKit) -> void:
	var t := 0
	tufts(k, Rect2(-3.8, -3.8, 7.6, 7.6), 50, 41)
	# a wheelbarrow of sand, model kit boxes, a garden gnome, a trampoline
	k.box(Vector3(0.5, 0.25, 0.7), Color(0.3, 0.55, 0.4), xf(Vector3(-2.2, 0.45, -0.9), Vector3(8, 20, 0)))
	k.box(Vector3(0.45, 0.06, 0.6), Color(0.86, 0.78, 0.56), xf(Vector3(-2.2, 0.58, -0.9), Vector3(8, 20, 0)))
	k.cyl(0.14, 0.06, Color(0.15, 0.15, 0.16), xf(Vector3(-2.05, 0.24, -0.5), Vector3(0, 20, 90)), 8)
	for i in 3:
		k.box(Vector3(0.5, 0.12, 0.35), [Color(0.9, 0.3, 0.25), Color(0.3, 0.5, 0.85), Color(0.95, 0.8, 0.3)][i], xf(Vector3(0.2, 0.16 + i * 0.12, 0.9), Vector3(0, i * 9.0, 0)))
	k.cyl(0.07, 0.18, Color(0.3, 0.5, 0.8), at(-3.4, 0.1, 1.0), 6)
	k.cone(0.08, 0.2, Color(0.9, 0.25, 0.2), at(-3.4, 0.33, 1.0), 6)
	k.sphere(0.06, Color(0.95, 0.85, 0.75), at(-3.4, 0.3, 1.0), 6, 3)
	var tp := Vector3(-2.0, 0.1, -2.95)
	k.cyl(0.85, 0.04, Color(0.15, 0.15, 0.17), at(tp.x, 0.55, tp.z), 12)
	k.torus(0.88, 0.05, Color(0.3, 0.6, 0.85), at(tp.x, 0.57, tp.z), 14, 4)
	for i in 6:
		var a := TAU * i / 6.0
		k.box(Vector3(0.04, 0.5, 0.04), Color(0.6, 0.62, 0.64), at(tp.x + cos(a) * 0.85, 0.32, tp.z + sin(a) * 0.85))
	# launch wire on stakes from the button box to the stand, a fire extinguisher
	for i in 4:
		k.box(Vector3(0.03, 0.3, 0.03), Pal.WOOD, at(-0.3 + i * 0.32, 0.25, 0.2 - i * 0.4))
	k.box(Vector3(0.12, 0.35, 0.12), Color(0.85, 0.15, 0.15), at(1.7, 0.28, -0.65))
	# bunting along the fence
	for i in 12:
		k.prism(PackedVector2Array([Vector2(-0.1, 0), Vector2(0.1, 0), Vector2(0, -0.18)]), 0.01, [Color(0.9, 0.3, 0.25), Color(0.95, 0.85, 0.3), Color(0.3, 0.55, 0.9)][i % 3], xf(Vector3(-3.4 + i * 0.6, 1.0, -3.86), Vector3(-90, 0, 0)))


static func _lp1x(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 3.95), Vector3(-90, 0, 0)), 7.8, 7.8, 6, 6, Color(0.6, 0.6, 0.58))
	# a row of jersey barriers shielding the bays, sandbags
	for i in 5:
		var x := -0.9 + i * 0.8
		k.prism(PackedVector2Array([Vector2(-0.35, 0), Vector2(0.35, 0), Vector2(0.12, 0.6), Vector2(-0.12, 0.6)]), 0.75, Color(0.82, 0.82, 0.8), xf(Vector3(x - 0.37, 0.1, 0.65), Vector3(0, 90, 0)))
		k.box(Vector3(0.7, 0.06, 0.02), p["accent"] if i % 2 == 0 else Color(0.85, 0.2, 0.18), at(x, 0.5, 0.82))
	for i in 6:
		k.box(Vector3(0.4, 0.15, 0.25), Color(0.72, 0.64, 0.46), xf(Vector3(-3.4 + (i % 3) * 0.42, 0.18 + (i / 3) * 0.14, -2.6), Vector3(0, i * 7.0, 0)))
	# a cable trench from the control room to the pad
	k.box(Vector3(0.3, 0.03, 3.6), Color(0.4, 0.41, 0.44), at(2.0, 0.115, 0.4))
	for i in 9:
		k.box(Vector3(0.32, 0.015, 0.3), p["metal"], at(2.0, 0.135, -1.2 + i * 0.4))
	# a camera pole and a wind sock
	k.cyl(0.04, 3.0, p["metal"], at(-0.2, 0.1, -3.4), 6)
	k.box(Vector3(0.2, 0.15, 0.3), Color(0.2, 0.2, 0.22), at(-0.2, 3.0, -3.25))
	k.cyl(0.03, 3.5, p["metal"], at(3.7, 0.1, -1.2), 5)
	k.cyl(0.12, 0.6, Color(0.95, 0.5, 0.15), xf(Vector3(3.7, 3.5, -1.2), Vector3(0, 0, 80)), 8, 0.0, 0.06)
	# hazard stripes round the pad apron
	for i in 8:
		k.box(Vector3(0.3, 0.006, 0.1), p["accent"] if i % 2 == 0 else p["dark"], at(pad_x() - 1.05 + i * 0.3, 0.106, -0.15))


static func pad_x() -> float:
	return 0.8


static func _lp2x(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 3.95), Vector3(-90, 0, 0)), 7.8, 7.8, 10, 10, p["wall2"])
	# a deluge water tank on legs, flags, a visitor viewing stand
	var dt := Vector3(-2.2, 0.1, -3.3)
	for j in 4:
		var a := TAU * j / 4.0 + PI / 4.0
		k.box(Vector3(0.07, 2.2, 0.07), p["metal"], at(dt.x + cos(a) * 0.4, 1.2, dt.z + sin(a) * 0.4))
	k.cyl(0.55, 0.9, Color(0.97, 0.97, 0.97), at(dt.x, 2.3, dt.z), 12)
	k.cyl(0.56, 0.06, p["trim"], at(dt.x, 2.7, dt.z), 12)
	for i in 3:
		k.cyl(0.025, 2.6, p["metal"], at(-2.9 + i * 0.35, 0.1, 0.6), 5)
		k.box(Vector3(0.02, 0.3, 0.45), [p["accent"], Color(0.98, 0.98, 0.98), p["accent2"]][i], at(-2.9 + i * 0.35, 2.5, 0.82))
	# a white camera tower and floodlights on the pad plinth
	k.cyl(0.05, 4.0, Color(0.96, 0.96, 0.97), at(2.6, 0.1, 0.2), 6)
	k.box(Vector3(0.3, 0.2, 0.3), Color(0.25, 0.26, 0.28), at(2.6, 4.0, 0.25))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(0.12, 0.08, 0.12), lit(p["glow"], 0.35), at(pad_x() + sx * 1.3, 0.56, -1.4 + sz * 1.3))
	# white kerbs and lamp posts along a service road
	ArchKit.lamp(k, Vector3(-0.7, 0.1, -3.4), t, 2.4)


static func _lp3x(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 3.95), Vector3(-90, 0, 0)), 7.8, 7.8, 8, 8, p["floor"].darkened(0.12))
	# deluge pipes round the pad, sound-suppression nozzles
	ArchKit.pipes(k, [Vector3(-0.6, 0.55, -2.8), Vector3(2.2, 0.55, -2.8), Vector3(2.2, 0.55, 0.0), Vector3(-0.6, 0.55, 0.0), Vector3(-0.6, 0.55, -2.8)], 0.05, Color(0.36, 0.6, 0.86))
	for i in 8:
		var a := TAU * i / 8.0
		k.cyl(0.04, 0.2, p["metal"], xf(Vector3(pad_x() + cos(a) * 1.15, 0.52, -1.4 + sin(a) * 1.15), Vector3(0, 0, 0)), 5)
	# camera and flood poles, a cable trench to the blockhouse
	for pp in [Vector3(-0.6, 0.1, 0.6), Vector3(1.0, 0.1, -3.7)]:
		k.cyl(0.05, 3.6, p["metal"], at(pp.x, pp.y, pp.z), 6)
		k.box(Vector3(0.4, 0.2, 0.15), p["dark"], at(pp.x, 3.6, pp.z + 0.1))
		k.box(Vector3(0.34, 0.03, 0.02), lit(p["glow"], 0.35), at(pp.x, 3.55, pp.z + 0.18))
	k.box(Vector3(0.4, 0.03, 2.4), Color(0.3, 0.31, 0.34), at(2.1, 0.115, 1.2))
	for i in 6:
		k.box(Vector3(0.42, 0.015, 0.36), p["metal"], at(2.1, 0.135, 0.2 + i * 0.4))
	# hazard hatching round the pad
	for i in 10:
		k.box(Vector3(0.5, 0.006, 0.08), p["accent"], xf(Vector3(-0.6 + i * 0.3, 0.106, 0.25), Vector3(0, 45, 0)))


static func _lp4x(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	# a holographic countdown, glowing ground rings, brass inlays
	k.box(Vector3(1.4, 0.5, 0.06), p["dark"], at(-1.5, 1.6, 1.2))
	k.box(Vector3(1.44, 0.04, 0.08), brass, at(-1.5, 1.87, 1.2))
	text(k, "T-10", at(-1.5, 1.45, 1.24), 0.05, lit(p["accent2"], 0.35), 0.02)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 1.4, 0.06), brass, at(-1.5 + sx * 0.6, 0.8, 1.2))
	ring(k, Vector3(pad_x(), 0.106, -1.4), 2.2, 0.02, lit(p["accent2"], 0.5), Vector3.ZERO, 28)
	ring(k, Vector3(pad_x(), 0.106, -1.4), 2.45, 0.015, brass, Vector3.ZERO, 28)
	# a fleet of drones over the complex, a second beacon mast
	for i in 4:
		drone(k, Vector3(-2.8 + i * 1.6, 3.0 + (i % 2) * 0.8, 0.0 - (i % 3) * 0.8), t, i * 45.0)
	k.cyl(0.08, 3.6, p["wall2"], at(-2.4, 0.1, -3.6), 6)
	for i in 3:
		ring(k, Vector3(-2.4, 1.2 + i * 0.9, -3.6), 0.16, 0.02, brass, Vector3.ZERO, 10)
	ArchKit.beacon(k, Vector3(-2.4, 3.7, -3.6), 0.3)
	# glowing seams on the pad disc, brass plates over the fuel lines
	for i in 8:
		var a := TAU * i / 8.0
		k.box(Vector3(0.9, 0.01, 0.03), lit(p["glow"], 0.4), xf(Vector3(pad_x() + cos(a) * 1.0, 0.525, -1.4 + sin(a) * 1.0), Vector3(0, -rad_to_deg(a), 0)))
	for i in 4:
		k.box(Vector3(0.5, 0.03, 0.3), brass, at(1.9 + i * 0.3, 0.12, -1.9 + i * 0.2))


## The rocket that carries an orbital module (origin at its base): a white
## booster with panel rings, grid fins, landing legs, a cluster of engines,
## an interstage, a fairing with its seam and a window on the payload.
static func rocket() -> Mesh:
	var k := MeshKit.new()
	var white := Color(0.96, 0.96, 0.95)
	var dark := Color(0.2, 0.21, 0.24)
	var teal := Color(0.3, 0.66, 0.68)
	var r := 0.42
	# the booster
	k.cyl(r, 3.0, white, at(0, 0.0, 0), 14, 0.03)
	for i in 5:
		k.cyl(r + 0.008, 0.02, Color(0.82, 0.83, 0.84), at(0, 0.35 + i * 0.55, 0), 14, 0.0, -1.0, false)
	for i in 4:
		var a := TAU * i / 4.0
		k.box(Vector3(0.06, 2.6, 0.03), Color(0.86, 0.87, 0.88), xf(Vector3(cos(a) * r, 1.5, sin(a) * r), Vector3(0, -rad_to_deg(a), 0)))
	# a teal band with the logo and a black interstage
	k.cyl(r + 0.01, 0.35, teal, at(0, 1.9, 0), 14, 0.0, -1.0, false)
	text(k, "TOKEN", xf(Vector3(0, 1.0, r + 0.005), Vector3(0, 0, 90)), 0.045, dark, 0.012)
	k.cyl(r + 0.01, 0.45, dark, at(0, 3.0, 0), 14)
	for i in 4:
		var a2 := TAU * i / 4.0 + PI / 4.0
		var gf := xf(Vector3(cos(a2) * (r + 0.12), 3.25, sin(a2) * (r + 0.12)), Vector3(0, -rad_to_deg(a2) + 90.0, 0))
		k.box(Vector3(0.3, 0.22, 0.03), Color(0.3, 0.31, 0.34), gf)
		for j in 3:
			k.box(Vector3(0.3, 0.015, 0.035), Color(0.5, 0.52, 0.56), gf * at(0, -0.08 + j * 0.08, 0))
			k.box(Vector3(0.015, 0.22, 0.035), Color(0.5, 0.52, 0.56), gf * at(-0.1 + j * 0.1, 0, 0))
	# the upper stage
	k.cyl(r * 0.96, 1.15, white, at(0, 3.45, 0), 14)
	k.cyl(r * 0.96 + 0.008, 0.03, Color(0.82, 0.83, 0.84), at(0, 4.0, 0), 14, 0.0, -1.0, false)
	# the fairing: a cylinder and an ogive nose, a seam, a payload window
	k.lathe(PackedVector2Array([Vector2(r * 0.96, 0.0), Vector2(r * 1.02, 0.08), Vector2(r * 1.02, 0.9), Vector2(r * 0.86, 1.35), Vector2(r * 0.55, 1.75), Vector2(r * 0.18, 2.0), Vector2(0.0, 2.06)]), white, at(0, 4.6, 0), 14)
	k.box(Vector3(0.015, 1.4, r * 2.1), Color(0.8, 0.81, 0.82), at(0, 5.3, 0))
	k.box(Vector3(0.36, 0.5, 0.02), teal, at(0, 5.1, r * 1.02))
	k.box(Vector3(0.22, 0.14, 0.02), lit(Color(0.6, 0.9, 1.0), 0.45), at(0, 5.22, r * 1.03))
	# fins and landing legs
	for i in 4:
		var a3 := TAU * i / 4.0 + PI / 4.0
		k.prism(PackedVector2Array([Vector2(0, 0), Vector2(0.55, 0), Vector2(0, 0.95)]), 0.05, dark, xf(Vector3(cos(a3) * r, 0.0, sin(a3) * r), Vector3(90, -rad_to_deg(a3), 0)))
		var foot := Vector3(cos(a3) * (r + 0.55), -0.3, sin(a3) * (r + 0.55))
		beam(k, Vector3(cos(a3) * (r - 0.02), 0.6, sin(a3) * (r - 0.02)), foot, 0.06, Color(0.26, 0.27, 0.3))
		beam(k, Vector3(cos(a3) * r, 0.05, sin(a3) * r), foot + Vector3(0, 0.1, 0), 0.04, Color(0.4, 0.42, 0.46))
		k.box(Vector3(0.18, 0.04, 0.18), Color(0.26, 0.27, 0.3), at(foot.x, foot.y, foot.z))
	# the engine cluster: a thrust plate, nine bells
	k.cyl(r * 0.95, 0.08, Color(0.3, 0.32, 0.36), at(0, -0.05, 0), 12)
	for i in 9:
		var p := Vector2.ZERO if i == 0 else Vector2(cos(TAU * i / 8.0), sin(TAU * i / 8.0)) * 0.27
		k.cyl(0.05, 0.28, Color(0.36, 0.38, 0.42), at(p.x, -0.33, p.y), 6, 0.0, 0.09)
		k.cyl(0.04, 0.02, lit(Color(1.0, 0.7, 0.4), 0.6), at(p.x, -0.34, p.y), 6)
	# an umbilical plate and RCS blocks
	k.box(Vector3(0.18, 0.4, 0.04), Color(0.3, 0.32, 0.36), at(-r - 0.01, 2.6, 0))
	for i in 4:
		var a4 := TAU * i / 4.0
		k.box(Vector3(0.06, 0.08, 0.06), Color(0.3, 0.32, 0.36), at(cos(a4) * (r + 0.02), 4.45, sin(a4) * (r + 0.02)))
	return k.commit()


## The flame under a launching rocket.
static func flame() -> Mesh:
	var k := MeshKit.new()
	k.cone(0.4, 1.6, Color(1.0, 0.6, 0.2, 0.3), MeshKit.xf(Vector3(0, 0.0, 0), Vector3(180, 0, 0)), 12)
	k.cone(0.22, 1.0, Color(1.0, 0.92, 0.6, 0.25), MeshKit.xf(Vector3(0, 0.0, 0), Vector3(180, 0, 0)), 10)
	return k.commit()


# ---------------------------------------------------------------- Ground Station (6 x 6 m)
# The control building always sits at (-1.5, 1.8) with a flat roof (a roof
# slot); antennas take the back half and the right side.

static func groundstation(t: int) -> Mesh:
	var k := MeshKit.new()
	ArchKit.lot(k, 5.9, 5.9, t)
	match clampi(t, 0, 4):
		0: _gs0(k)
		1: _gs1(k)
		2: _gs2(k)
		3: _gs3(k)
		_: _gs4(k)
	match clampi(t, 0, 4):
		0: _gs0x(k)
		1:
			_gs1x(k)
			_gs1y(k)
		2:
			_gs2x(k)
			_gs2y(k)
		3:
			_gs3x(k)
			_gs3y(k)
		_:
			_gs4x(k)
			_gs4y(k)
	_life(k, "groundstation", clampi(t, 0, 4))
	_finish(k, "groundstation", clampi(t, 0, 4))
	return k.commit()


## A tripod (three legs from the ground up to a head at height h).
static func _tripod(k: MeshKit, p: Vector3, h: float, spread: float, col: Color) -> void:
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		beam(k, p + Vector3(cos(a) * spread, 0, sin(a) * spread), p + Vector3(0, h, 0), 0.035, col)
	k.box(Vector3(0.12, 0.1, 0.12), col.darkened(0.2), at(p.x, p.y + h, p.z))


## Garage: a satellite TV dish on a tripod, a laptop on a camping table,
## a handheld yagi on a camera tripod, a plywood shack.
static func _gs0(k: MeshKit) -> void:
	var t := 0
	# the dish on a tripod, weighted with sandbags
	var dp := Vector3(0.4, 0.1, -0.9)
	_tripod(k, dp, 1.1, 0.6, Color(0.6, 0.62, 0.64))
	sat_dish(k, at(dp.x, dp.y + 1.1, dp.z), 0.55, t, 45.0, 20.0, 0.1, Color(0.92, 0.92, 0.9))
	for i in 3:
		var a := TAU * i / 3.0 + 0.3
		k.box(Vector3(0.3, 0.12, 0.2), Color(0.72, 0.64, 0.46), xf(dp + Vector3(cos(a) * 0.6, 0.06, sin(a) * 0.6), Vector3(0, -rad_to_deg(a), 0)))
	# a yagi on a camera tripod pointed up at a passing satellite
	var yp := Vector3(1.9, 0.1, -1.9)
	_tripod(k, yp, 1.3, 0.4, Color(0.2, 0.2, 0.22))
	yagi(k, xf(yp + Vector3(0, 1.4, -0.3), Vector3(-40, 30, 0)), 1.2, Color(0.82, 0.84, 0.86), 8)
	# an eggbeater antenna on a pole
	k.cyl(0.03, 2.2, Color(0.6, 0.62, 0.64), at(-0.8, 0.1, -2.2), 5)
	for i in 2:
		k.torus(0.18, 0.012, Color(0.8, 0.82, 0.84), xf(Vector3(-0.8, 2.3, -2.2), Vector3(90, i * 90.0, 0)), 10, 3)
	# the camping table: a laptop, a radio, coffee
	table(k, at(-0.3, 0.1, 0.5), 1.0, 0.6, Color(0.3, 0.5, 0.7), Color(0.6, 0.62, 0.64), 0.7)
	laptop(k, xf(Vector3(-0.5, 0.8, 0.5), Vector3(0, 200, 0)), Color(0.5, 1.0, 0.7))
	k.box(Vector3(0.25, 0.12, 0.15), Color(0.2, 0.2, 0.22), at(0.0, 0.86, 0.45))
	k.box(Vector3(0.015, 0.3, 0.015), Color(0.2, 0.2, 0.22), at(0.08, 1.05, 0.42))
	k.cyl(0.04, 0.1, Color(0.85, 0.3, 0.25), at(0.15, 0.8, 0.65), 6)
	chair(k, xf(Vector3(-0.3, 0.1, 1.15), Vector3(0, 180, 0)), Color(0.3, 0.6, 0.4))
	cable(k, Vector3(-0.4, 0.8, 0.3), Vector3(dp.x, 1.1, dp.z + 0.1), 0.4, Color(0.15, 0.15, 0.16), 0.015)
	cable(k, Vector3(-0.2, 0.8, 0.3), Vector3(yp.x, 1.3, yp.z), 0.6, Color(0.15, 0.15, 0.16), 0.015)
	# a car battery and an inverter on the ground
	k.box(Vector3(0.3, 0.22, 0.2), Color(0.16, 0.16, 0.18), at(0.7, 0.21, 0.5))
	k.box(Vector3(0.22, 0.1, 0.15), Color(0.8, 0.3, 0.25), at(0.7, 0.15, 0.85))
	# the plywood shack (flat roof), a hand-painted sign
	var sp := Vector3(-1.5, 0.1, 1.8)
	ArchKit.planks(k, at(sp.x, 0.1, sp.z + 0.6), 1.6, 1.7, Color(0.8, 0.66, 0.46))
	ArchKit.planks(k, xf(Vector3(sp.x, 0.1, sp.z - 0.6), Vector3(0, 180, 0)), 1.6, 1.7, Color(0.8, 0.66, 0.46))
	for sx in [-1.0, 1.0]:
		ArchKit.planks(k, xf(Vector3(sp.x + sx * 0.8, 0.1, sp.z), Vector3(0, sx * 90.0, 0)), 1.2, 1.7, Color(0.8, 0.66, 0.46))
	k.box(Vector3(1.8, 0.06, 1.4), Color(0.62, 0.64, 0.66), at(sp.x, 1.83, sp.z))
	for i in 9:
		k.box(Vector3(0.04, 0.03, 1.4), Color(0.54, 0.56, 0.58), at(sp.x - 0.8 + i * 0.2, 1.87, sp.z))
	k.box(Vector3(0.6, 1.4, 0.04), Pal.WOOD_DARK, at(sp.x + 0.35, 0.8, sp.z + 0.63))
	k.box(Vector3(0.5, 0.35, 0.04), Color(0.66, 0.78, 0.84, 0.75), at(sp.x - 0.35, 1.2, sp.z + 0.63))
	k.box(Vector3(0.9, 0.3, 0.04), Color(0.95, 0.93, 0.86), xf(Vector3(sp.x, 1.95, sp.z + 0.66), Vector3(0, 0, 3)))
	text(k, "SAT", xf(Vector3(sp.x, 1.86, sp.z + 0.68), Vector3(0, 0, 3)), 0.04, Color(0.26, 0.46, 0.78))
	ArchKit.string_lights(k, Vector3(sp.x + 0.8, 1.8, sp.z + 0.65), Vector3(0.9, 1.0, -0.9), 8)
	# a tent, a cooler, crates, a rake of wooden fence
	k.prism(PackedVector2Array([Vector2(-0.6, 0), Vector2(0.6, 0), Vector2(0, 0.9)]), 1.4, Color(0.9, 0.55, 0.25), xf(Vector3(2.0, 0.1, 0.9), Vector3(-90, 0, 0)))
	k.box(Vector3(0.5, 0.35, 0.32), Color(0.2, 0.45, 0.75), at(1.2, 0.28, 1.0))
	crate(k, at(-2.4, 0.1, -0.6), 0.4)
	ArchKit.fence(k, Vector3(-1.9, 0.1, -2.88), Vector3(-0.1, 0.1, -2.88), t, 1.0)
	ArchKit.fence(k, Vector3(0.9, 0.1, -2.88), Vector3(2.88, 0.1, -2.88), t, 1.0)


## Workshop: two dishes on steel pedestals and a control container.
static func _gs1(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	# the big dish on a concrete block and a steel pedestal
	var d1 := Vector3(-0.5, 0.1, -1.2)
	k.box(Vector3(1.1, 0.3, 1.1), Color(0.66, 0.66, 0.64), at(d1.x, 0.25, d1.z))
	sat_dish(k, at(d1.x, 0.4, d1.z), 1.3, t, 42.0, 15.0, 0.9, Color(0.94, 0.94, 0.93))
	ArchKit.ladder(k, xf(d1 + Vector3(0, 0.3, 0.35), Vector3(0, 0, 0)), 1.1, p["accent"])
	# the second dish beside it
	var d2 := Vector3(1.9, 0.1, -1.6)
	k.box(Vector3(0.8, 0.3, 0.8), Color(0.66, 0.66, 0.64), at(d2.x, 0.25, d2.z))
	sat_dish(k, at(d2.x, 0.4, d2.z), 0.85, t, 55.0, -35.0, 0.7, Color(0.94, 0.94, 0.93))
	# cable trench covers to the container
	for i in 9:
		k.box(Vector3(0.36, 0.05, 0.32), p["metal"].darkened(0.1), at(-0.75 + i * 0.3, 0.13, 0.4))
	ArchKit.cable_tray(k, Vector3(d1.x, 0.5, d1.z + 0.6), Vector3(d1.x, 0.5, 0.4), t)
	ArchKit.cable_tray(k, Vector3(d2.x, 0.5, d2.z + 0.5), Vector3(d2.x, 0.5, 0.4), t)
	# the control container: door, window, AC, sign, roof rail
	var cc := Color(0.86, 0.88, 0.9)
	container(k, at(-1.5, 0.25, 1.8), 2.4, cc, 2.3, 1.4)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.3, 0.15, 1.2), Color(0.62, 0.62, 0.6), at(-1.5 + sx * 0.9, 0.17, 1.8))
	door_plain(k, at(-0.85, 0.25, 2.52), t, 0.7, 1.9)
	k.box(Vector3(0.7, 0.45, 0.04), p["glass"], at(-1.9, 1.5, 2.52))
	k.box(Vector3(0.8, 0.06, 0.12), p["trim"], at(-1.9, 1.77, 2.55))
	k.box(Vector3(0.7, 0.3, 0.35), Color(0.9, 0.9, 0.9), at(-2.4, 1.2, 2.7))
	k.box(Vector3(1.1, 0.28, 0.04), p["accent"], at(-1.6, 2.25, 2.52))
	text(k, "GROUND", at(-1.6, 2.16, 2.55), 0.03, p["dark"])
	k.cyl(0.03, 1.6, p["metal"], at(-2.5, 2.55, 1.3), 5)
	yagi(k, xf(Vector3(-2.5, 4.0, 1.0), Vector3(-30, 0, 0)), 0.8, Color(0.86, 0.88, 0.9), 6)
	# chain-link at the back, a floodlight, cones
	ArchKit.fence(k, Vector3(2.88, 0.1, -2.88), Vector3(2.88, 0.1, 0.9), t, 1.5)
	ArchKit.lamp(k, Vector3(2.4, 0.1, -0.3), t, 3.0)
	cone(k, Vector3(1.4, 0.1, 0.4))
	k.box(Vector3(0.6, 0.9, 0.4), Color(0.6, 0.62, 0.64), at(0.4, 0.55, -0.1))
	k.box(Vector3(0.4, 0.04, 0.01), lit(p["glow"], 0.3), at(0.4, 0.8, 0.105))


## Campus: white radomes on plinths, a small dish and a white control building.
static func _gs2(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var wc: Color = p["wall"]
	# the radomes: hexagon-panelled spheres on plinths
	for r in [[Vector3(-0.6, 0.1, -1.2), 1.25], [Vector3(1.85, 0.1, -1.7), 0.9]]:
		var c: Vector3 = r[0]
		var rr: float = r[1]
		k.cyl(rr * 0.8, 0.8, p["wall2"], at(c.x, c.y, c.z), 10)
		k.cyl(rr * 0.82, 0.08, p["trim"], at(c.x, c.y + 0.8, c.z), 10)
		k.sphere(rr, Color(0.97, 0.97, 0.97), at(c.x, c.y + 0.8 + rr * 0.55, c.z), 14, 9)
		for i in 6:
			var a := TAU * i / 6.0
			k.box(Vector3(0.02, rr * 1.2, 0.02), Color(0.86, 0.87, 0.88), xf(Vector3(c.x + cos(a) * rr * 0.99, c.y + 0.8 + rr * 0.55, c.z + sin(a) * rr * 0.99), Vector3(0, -rad_to_deg(a), 0)))
		ArchKit.door(k, at(c.x, c.y, c.z + rr * 0.8), t, 0.5, 0.7)
		ArchKit.beacon(k, c + Vector3(0, 0.8 + rr * 1.55, 0), 0.25)
	# a small open dish on the right
	k.box(Vector3(0.7, 0.2, 0.7), p["wall2"], at(2.2, 0.2, 0.3))
	sat_dish(k, at(2.2, 0.3, 0.3), 0.6, t, 55.0, -20.0, 0.6)
	# the control building: white box, a teal band, glass front, roof edge
	var cp := Vector3(-1.5, 0.1, 1.8)
	k.rbox(Vector3(2.2, 2.4, 1.5), 0.05, wc, at(cp.x, 0.1 + 1.2, cp.z), 1)
	ArchKit.curtain(k, at(cp.x + 0.25, 0.15, cp.z + 0.76), 1.5, 1.9, t, 4, 2)
	k.box(Vector3(2.22, 0.16, 1.52), p["trim"], at(cp.x, 2.2, cp.z))
	ArchKit.parapet(k, Vector3(cp.x, 2.5, cp.z), 2.2, 1.5, t)
	k.box(Vector3(0.36, 0.36, 0.04), p["accent"], at(cp.x - 0.85, 1.5, cp.z + 0.77))
	text(k, "SAT", at(cp.x - 0.85, 1.0, cp.z + 0.78), 0.035, p["dark"])
	# cable ducts, planters, a bench, a lamp
	k.box(Vector3(0.4, 0.06, 2.4), p["wall2"], at(-0.6, 0.13, 0.0))
	k.box(Vector3(2.4, 0.06, 0.4), p["wall2"], at(0.6, 0.13, -0.8))
	ArchKit.planter(k, Vector3(1.6, 0.1, 0.9), t, 0.6, true)
	ArchKit.planter(k, Vector3(-2.5, 0.1, -0.4), t, 0.6, false)
	ArchKit.lamp(k, Vector3(-0.2, 0.1, 2.6), t, 2.6)


## Industrial: a big steerable antenna on a concrete mount, a second one,
## a cable trench with grates, a concrete control bunker.
static func _gs3(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	# the big antenna: a concrete drum, a turning head, a yoke and a 4 m dish
	var bp := Vector3(-0.2, 0.1, -1.1)
	k.cyl(0.95, 1.4, Color(0.6, 0.61, 0.62), at(bp.x, bp.y, bp.z), 12)
	k.cyl(1.0, 0.1, p["trim"], at(bp.x, bp.y + 1.4, bp.z), 12)
	k.box(Vector3(1.4, 0.6, 1.1), p["wall"], at(bp.x, 1.8, bp.z))
	k.box(Vector3(1.0, 0.04, 0.02), lit(p["glow"], 0.4), at(bp.x, 1.8, bp.z + 0.56))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.2, 1.3, 0.5), p["wall"], at(bp.x + sx * 0.6, 2.7, bp.z))
	var dx := xf(Vector3(bp.x, 3.1, bp.z), Vector3(38, -15, 0))
	var r := 2.0
	k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.5, r * 0.07), Vector2(r, r * 0.28), Vector2(r * 1.02, r * 0.3), Vector2(r * 0.5, r * 0.12), Vector2(0.0, r * 0.06)]), Color(0.92, 0.93, 0.94), dx, 16)
	for i in 8:
		var a := TAU * i / 8.0
		beam(k, dx * Vector3(cos(a) * r * 0.3, r * 0.05, sin(a) * r * 0.3), dx * Vector3(cos(a) * r * 0.95, r * 0.2, sin(a) * r * 0.95), 0.05, Color(0.7, 0.72, 0.74))
	for i in 4:
		var a2 := TAU * i / 4.0 + PI / 4.0
		beam(k, dx * Vector3(cos(a2) * r * 0.7, r * 0.22, sin(a2) * r * 0.7), dx * Vector3(0, r * 0.8, 0), 0.05, p["metal"])
	k.cyl(0.18, 0.4, p["wall2"], dx * at(0, r * 0.75, 0), 8)
	var feed: Vector3 = dx * Vector3(0, r * 0.98, 0)
	k.sphere(0.1, lit(p["glow"], 0.3), at(feed.x, feed.y + 0.1, feed.z), 6, 4)
	k.box(Vector3(0.8, 0.8, 0.5), p["metal"], dx * at(0, -0.3, -0.2))
	ArchKit.ladder(k, xf(bp + Vector3(0, 0, 0.98), Vector3(0, 0, 0)), 1.5, p["accent"], false)
	ArchKit.railing(k, bp + Vector3(-0.7, 1.5, 0.95), bp + Vector3(0.7, 1.5, 0.95), 0.8, p["accent"], 0.5)
	# the second steerable dish on a steel pedestal
	var d2 := Vector3(2.15, 0.1, -0.2)
	k.box(Vector3(0.9, 0.3, 0.9), Color(0.6, 0.61, 0.62), at(d2.x, 0.25, d2.z))
	sat_dish(k, at(d2.x, 0.4, d2.z), 0.9, t, 50.0, -40.0, 1.0, Color(0.92, 0.93, 0.94))
	# a cable trench with steel grates to the bunker
	k.box(Vector3(0.5, 0.04, 2.6), Color(0.3, 0.31, 0.34), at(-0.2, 0.12, 0.9))
	for i in 8:
		k.box(Vector3(0.52, 0.02, 0.28), p["metal"], at(-0.2, 0.15, -0.1 + i * 0.32))
		for j in 3:
			k.box(Vector3(0.02, 0.025, 0.28), p["trim"], at(-0.36 + j * 0.16, 0.16, -0.1 + i * 0.32))
	k.box(Vector3(2.4, 0.04, 0.5), Color(0.3, 0.31, 0.34), at(1.0, 0.12, 0.6))
	for i in 7:
		k.box(Vector3(0.3, 0.02, 0.52), p["metal"], at(-0.0 + i * 0.34, 0.15, 0.6))
	# the concrete bunker with blue LEDs and a generator
	var cp := Vector3(-1.5, 0.1, 1.8)
	k.rbox(Vector3(2.2, 2.2, 1.5), 0.08, Color(0.58, 0.59, 0.6), at(cp.x, 0.1 + 1.1, cp.z), 1)
	k.box(Vector3(1.6, 0.2, 0.04), p["glass"], at(cp.x, 1.7, cp.z + 0.76))
	k.box(Vector3(2.24, 0.12, 1.54), p["trim"], at(cp.x, 2.26, cp.z))
	k.box(Vector3(2.0, 0.03, 0.03), lit(p["glow"], 0.4), at(cp.x, 1.4, cp.z + 0.77))
	door_plain(k, at(cp.x + 0.5, 0.1, cp.z + 0.75), t, 0.7, 1.8)
	ArchKit.sign(k, at(cp.x - 0.5, 0.9, cp.z + 0.76), 0.8, 0.3, t)
	ArchKit.generator(k, xf(Vector3(-2.3, 0.1, -1.4), Vector3(0, 90, 0)), t)
	ArchKit.lamp(k, Vector3(2.5, 0.1, -2.4), t, 3.2)
	for z in [-2.4, -0.4]:
		k.box(Vector3(0.08, 0.006, 1.6), p["accent"], at(1.2, 0.106, z + 0.8))


## Hyperscale: graphite phased-array panels on plinths, beams of light into
## the sky, a graphite control pavilion.
static func _gs4(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var g: Color = p["wall"]
	var g2: Color = p["wall2"]
	var brass: Color = p["trim"]
	var cyan: Color = p["accent2"]
	var panels := [[Vector3(-1.4, 0.1, -1.6), 0.0], [Vector3(0.6, 0.1, -1.9), -12.0], [Vector3(1.8, 0.1, -0.6), 20.0]]
	for e in panels:
		var c: Vector3 = e[0]
		var yaw: float = e[1]
		var b := xf(c, Vector3(0, yaw, 0))
		k.box(Vector3(1.4, 0.7, 0.8), g, b * at(0, 0.35, 0))
		k.box(Vector3(1.44, 0.05, 0.84), brass, b * at(0, 0.7, 0))
		var pf := b * xf(Vector3(0, 1.45, -0.1), Vector3(-62, 0, 0))
		k.box(Vector3(1.7, 1.5, 0.12), g2, pf)
		k.box(Vector3(1.74, 0.05, 0.14), brass, pf * at(0, 0.75, 0))
		k.box(Vector3(1.74, 0.05, 0.14), brass, pf * at(0, -0.75, 0))
		for i in 6:
			for j in 5:
				k.box(Vector3(0.22, 0.22, 0.02), lit(cyan if (i + j) % 3 else p["glow"], 0.5 if (i + j) % 2 else 0.65), pf * at(-0.68 + i * 0.27, -0.56 + j * 0.28, 0.07))
		# the beam into the sky
		var up: Vector3 = pf * Vector3(0, 0, 0.1)
		var dir: Vector3 = (pf.basis * Vector3(0, 0, 1)).normalized()
		rod(k, up, up + dir * 5.0, 0.2, lit(cyan, 0.85), 8)
		rod(k, up, up + dir * 5.6, 0.06, lit(Color(0.9, 1.0, 1.0), 0.5), 6)
		k.box(Vector3(0.5, 0.06, 0.4), brass, b * at(0, 0.74, 0.25))
	# glowing conduits between the panels and the pavilion
	for e in panels:
		var c2: Vector3 = e[0]
		ArchKit.pipes(k, [c2 + Vector3(0, 0.05, 0.45), Vector3(c2.x, 0.15, 0.6), Vector3(-1.5, 0.15, 0.9)], 0.04, lit(cyan, 0.5))
	# the control pavilion: graphite, a brass-framed glass band, flat roof
	var cp := Vector3(-1.5, 0.1, 1.8)
	k.box(Vector3(2.2, 2.3, 1.5), g, at(cp.x, 0.1 + 1.15, cp.z))
	k.box(Vector3(2.0, 0.6, 0.04), p["glass"], at(cp.x, 1.5, cp.z + 0.76))
	for i in 6:
		k.box(Vector3(0.04, 0.7, 0.06), brass, at(cp.x - 0.95 + i * 0.38, 1.5, cp.z + 0.78))
	k.box(Vector3(2.3, 0.1, 1.6), brass, at(cp.x, 2.45, cp.z))
	k.box(Vector3(2.2, 0.04, 1.5), g2, at(cp.x, 2.52, cp.z))
	ArchKit.fins(k, xf(Vector3(cp.x + 1.1, 0.1, cp.z), Vector3(0, 90, 0)), 1.3, 1.1, 4, t)
	door_plain(k, at(cp.x - 0.5, 0.1, cp.z + 0.75), t, 0.7, 1.0)
	# a graphite mast with a brass crown and a beacon
	k.cyl(0.12, 4.5, g2, at(2.4, 0.1, -2.5), 6)
	for i in 3:
		ring(k, Vector3(2.4, 1.6 + i * 1.1, -2.5), 0.2, 0.025, brass, Vector3.ZERO, 10)
	k.sphere(0.14, lit(p["glow"], 0.3), at(2.4, 4.7, -2.5), 8, 4)
	ArchKit.beacon(k, Vector3(2.4, 4.8, -2.5), 0.3)
	for i in 5:
		k.box(Vector3(5.0, 0.006, 0.03), lit(cyan, 0.5), at(0.2, 0.106, -2.6 + i * 0.6))


## Ground Station detail passes.
static func _gs0x(k: MeshKit) -> void:
	var t := 0
	tufts(k, Rect2(-2.9, -2.9, 5.8, 5.8), 40, 51)
	# a pass chart pinned on an easel, a ham radio stack, a mug
	var ez := xf(Vector3(0.9, 0.1, -0.1), Vector3(0, -30, 0))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 1.2, 0.04), Pal.WOOD, ez * xf(Vector3(sx * 0.3, 0.6, 0), Vector3(-8, 0, 0)))
	k.box(Vector3(0.7, 0.5, 0.02), Color(0.95, 0.95, 0.92), ez * xf(Vector3(0, 0.9, 0.04), Vector3(-8, 0, 0)))
	for i in 4:
		k.box(Vector3(0.5, 0.015, 0.01), Color(0.3, 0.5, 0.8) if i % 2 else Color(0.85, 0.3, 0.3), ez * xf(Vector3(0, 0.75 + i * 0.1, 0.055), Vector3(-8, 0, 15.0 - i * 10.0)))
	k.box(Vector3(0.3, 0.1, 0.2), Color(0.25, 0.25, 0.27), at(-0.7, 0.86, 0.7))
	k.box(Vector3(0.26, 0.04, 0.01), lit(Color(1.0, 0.7, 0.3), 0.4), at(-0.7, 0.88, 0.805))
	# a cool box, a bike, firewood, a campfire ring
	bike(k, xf(Vector3(2.4, 0.1, -0.4), Vector3(0, 10, 0)), Color(0.85, 0.3, 0.26))
	for i in 7:
		var a := TAU * i / 7.0
		k.box(Vector3(0.15, 0.1, 0.12), Color(0.6, 0.58, 0.54), xf(Vector3(1.0 + cos(a) * 0.35, 0.15, 0.25 + sin(a) * 0.35), Vector3(0, -rad_to_deg(a), 0)))
	for i in 3:
		k.cyl(0.04, 0.4, Pal.WOOD_DARK, xf(Vector3(1.0, 0.16, 0.25), Vector3(80, i * 60.0, 0)), 5)
	# a wooden cable spool table, stools
	k.cyl(0.4, 0.05, Pal.WOOD, at(-2.2, 0.55, -1.6), 10)
	k.cyl(0.15, 0.45, Pal.WOOD_DARK, at(-2.2, 0.1, -1.6), 8)
	for i in 2:
		k.cyl(0.14, 0.4, Pal.WOOD_LIGHT, at(-2.2 + (i * 2 - 1) * 0.55, 0.1, -1.4), 8)


static func _gs1x(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.8, 5.9, 5, 5, Color(0.6, 0.6, 0.58))
	# whip antennas and a GPS dome on the container roof, a cable reel
	for i in 3:
		k.cyl(0.015, 0.9, Color(0.2, 0.2, 0.22), at(-2.3 + i * 0.3, 2.55, 2.3), 4)
	k.cyl(0.08, 0.1, Color(0.95, 0.95, 0.94), at(-1.2, 2.55, 1.4), 6)
	for sz in [-1.0, 1.0]:
		k.cyl(0.35, 0.04, Pal.WOOD, xf(Vector3(1.1, 0.45, -0.2 + sz * 0.15), Vector3(90, 0, 0)), 10)
	k.cyl(0.22, 0.3, Color(0.2, 0.2, 0.22), xf(Vector3(1.1, 0.45, -0.35), Vector3(90, 0, 0)), 10)
	# dish pedestal details: cable entry boxes, warning signs
	for d in [Vector3(-0.5, 0.1, -1.2), Vector3(1.9, 0.1, -1.6)]:
		k.box(Vector3(0.3, 0.4, 0.2), Color(0.84, 0.85, 0.86), at(d.x + 0.4, 0.6, d.z + 0.45))
		k.box(Vector3(0.18, 0.18, 0.01), Color(0.98, 0.84, 0.3), xf(Vector3(d.x - 0.2, 0.4, d.z + 0.56), Vector3(0, 0, 45)))
	# a fuel tank and a small generator behind the container
	htank(k, at(-2.2, 0.1, -0.4), 0.22, 0.8, Color(0.92, 0.72, 0.2))
	k.box(Vector3(0.8, 0.6, 0.5), Color(0.92, 0.72, 0.2), at(-1.5, 0.4, 0.35))
	k.cyl(0.04, 0.5, Color(0.3, 0.3, 0.32), at(-1.2, 0.7, 0.3), 5)
	wall_dress(k, xf(Vector3(-2.7, 0.25, 1.8), Vector3(0, -90, 0)), 1.2, 2.2, t, 12)


static func _gs2x(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.8, 5.9, 8, 8, p["wall2"])
	# latitude rings on the radomes
	for r in [[Vector3(-0.6, 0.1, -1.2), 1.25], [Vector3(1.85, 0.1, -1.7), 0.9]]:
		var c: Vector3 = r[0]
		var rr: float = r[1]
		var cy := c.y + 0.8 + rr * 0.55
		for j in 3:
			var y := (j - 1) * rr * 0.45
			k.torus(sqrt(maxf(0.01, rr * rr - y * y)) + 0.005, 0.012, Color(0.86, 0.87, 0.88), at(c.x, cy + y, c.z), 14, 3)
	# paths and hedges between the radomes, a flag, the control roof gear
	hedge(k, Vector3(-2.1, 0.1, 0.5), Vector3(-0.8, 0.1, 0.5), 0.35)
	k.cyl(0.03, 3.0, p["metal"], at(0.6, 0.1, 0.3), 5)
	k.box(Vector3(0.02, 0.35, 0.55), p["accent"], at(0.6, 2.8, 0.58))
	roof_dress(k, Rect2(-2.5, 1.15, 2.0, 1.3), 2.5 + 0.03, t, 61, slot_rects("groundstation", t, true), 0.6)
	ArchKit.lamp(k, Vector3(2.6, 0.1, -0.3), t, 2.6)
	bin(k, Vector3(-0.1, 0.1, 1.2), p["accent"])


static func _gs3x(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	seams(k, xf(Vector3(0, 0.104, 2.95), Vector3(-90, 0, 0)), 5.8, 5.9, 6, 6, p["floor"].darkened(0.12))
	# a helix antenna mast at the back right, a small tracking dish
	var hp := Vector3(2.4, 0.1, -2.4)
	mast(k, hp, 4.5, 0.5, 0.25, Color(0.82, 0.84, 0.86), 0.6, 0.04)
	for i in 3:
		var hb := xf(hp + Vector3(0.1, 3.0 + i * 0.5, 0.3), Vector3(-50, 20, 0))
		k.cyl(0.05, 0.7, Color(0.95, 0.95, 0.94), hb, 6)
		for j in 6:
			k.torus(0.1, 0.008, Color(0.7, 0.72, 0.74), hb * at(0, 0.1 + j * 0.1, 0), 8, 3)
	ArchKit.beacon(k, hp + Vector3(0, 4.6, 0), 0.2)
	# a transformer, cable trays, floodlights, fence
	ArchKit.transformer(k, at(1.45, 0.1, -2.35), t)
	ArchKit.cable_tray(k, Vector3(-0.2, 1.6, -0.2), Vector3(-0.2, 1.6, 1.0), t)
	roof_dress(k, Rect2(-2.5, 1.15, 2.0, 1.3), 2.32, t, 71, slot_rects("groundstation", t, true), 0.6)


static func _gs4x(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	# a glowing ground ring linking the arrays, brass plinth lights
	ring(k, Vector3(0.5, 0.106, -1.2), 1.4, 0.02, lit(p["accent2"], 0.5), Vector3.ZERO, 24)
	ring(k, Vector3(0.5, 0.106, -1.2), 1.6, 0.015, brass, Vector3.ZERO, 24)
	# a brass crown on the pavilion, roof gear
	for i in 6:
		var a := TAU * i / 6.0
		beam(k, Vector3(-2.25 + cos(a) * 0.2, 2.54, 1.4 + sin(a) * 0.2), Vector3(-2.25 + cos(a) * 0.35, 3.1, 1.4 + sin(a) * 0.35), 0.035, brass)
	k.sphere(0.14, lit(p["glow"], 0.3), at(-2.25, 2.95, 1.4), 8, 4)
	roof_dress(k, Rect2(-2.5, 1.15, 0.6, 1.3), 2.55, t, 81, slot_rects("groundstation", t, true), 0.8)
	# drones on station duty
	for i in 3:
		drone(k, Vector3(-0.5 + i * 1.2, 3.2 + (i % 2) * 0.6, 0.6), t, i * 30.0)


# ---------------------------------------------------------------- third passes

static func _edge1y(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var top := 0.28 + 2.5
	# a backhaul dish and condensing units on the container, a tray to the bridge
	sat_dish(k, at(0.9, top, -1.15), 0.32, t, 50.0, 30.0, 0.25, Color(0.9, 0.9, 0.9))
	for i in 2:
		k.box(Vector3(0.6, 0.45, 0.4), Color(0.88, 0.89, 0.9), at(-2.4 + i * 0.7, top + 0.22, -2.45))
		k.cyl(0.16, 0.02, Color(0.22, 0.23, 0.26), xf(Vector3(-2.4 + i * 0.7, top + 0.22, -2.24), Vector3(90, 0, 0)), 8)
	ArchKit.cable_tray(k, Vector3(-2.6, top + 0.2, -0.85), Vector3(1.3, top + 0.2, -0.85), t)
	# gravel inside the tower compound, a picnic bench for the techs
	for i in 18:
		k.box(Vector3(0.1, 0.02, 0.08), Color(0.56, 0.54, 0.5), xf(Vector3(1.6 + fposmod(i * 0.37, 1.2), 0.11, -2.8 + fposmod(i * 0.53, 1.8)), Vector3(0, i * 31.0, 0)))


static func _edge2y(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var top := 0.35 + 3.1
	# a penthouse plant room with louvres on the roof (height on one side)
	k.rbox(Vector3(1.4, 1.2, 1.3), 0.04, p["wall"], at(0.45, top + 0.6, -2.1), 1)
	ArchKit.louvres(k, at(0.45, top + 0.2, -1.44), 1.1, 0.8, p["wall2"], 7)
	k.box(Vector3(1.44, 0.1, 1.34), p["trim"], at(0.45, top + 1.2, -2.1))
	vent(k, Vector3(0.2, top + 1.25, -2.3), p["metal"], 0.3)
	vent(k, Vector3(0.7, top + 1.25, -1.9), p["metal"], 0.3)
	# a glass vestibule at the door, a green wall by it
	k.box(Vector3(1.1, 2.1, 0.04), p["glass"], at(-2.15, 1.4, 0.1))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.04, 2.1, 0.55), p["glass"], at(-2.15 + sx * 0.55, 1.4, -0.17))
		k.box(Vector3(0.05, 2.15, 0.05), p["frame"], at(-2.15 + sx * 0.55, 1.4, 0.1))
	for j in 5:
		for i in 3:
			k.sphere(0.1, Color(0.38, 0.56, 0.32).darkened(((i + j) % 3) * 0.06), at(-1.3 + i * 0.2, 0.6 + j * 0.4, -0.38), 6, 3)
	# EV bay lines under the carport
	for z in [0.25, 2.45]:
		k.box(Vector3(1.2, 0.005, 0.06), Color(0.98, 0.98, 0.98), at(-2.2, 0.106, z))


static func _edge3y(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var c3 := Color(0.62, 0.36, 0.26)
	var cz := -1.75
	# a third container on top: the stack climbs to three
	var y3 := 2.85 + 2.4
	container(k, at(-1.75, y3, cz), 2.2, c3, 2.2, 2.2)
	ArchKit.louvres(k, at(-1.75, y3 + 0.4, cz + 1.12), 1.4, 1.2, c3.darkened(0.1), 7)
	k.box(Vector3(1.2, 0.03, 0.02), lit(p["accent2"], 0.4), at(-1.75, y3 + 1.9, cz + 1.13))
	ArchKit.ladder(k, xf(Vector3(-0.5, 2.85 + 2.4, cz + 1.0), Vector3(0, 0, 0)), 2.2, p["accent"], true)
	ArchKit.railing(k, Vector3(-2.8, y3 + 2.2, cz - 1.05), Vector3(-0.7, y3 + 2.2, cz - 1.05), 0.9, p["accent"])
	ArchKit.ac_unit(k, at(-2.2, y3 + 2.2, cz), t, 0.8)
	sat_dish(k, at(-1.2, y3 + 2.2, cz - 0.3), 0.35, t, 55.0, 20.0, 0.3)
	# cable trays down the stack, a fuel day tank with a bund
	ArchKit.cable_tray(k, Vector3(-0.65, 2.6, cz + 1.25), Vector3(-0.65, 5.0, cz + 1.25), t)
	k.box(Vector3(0.9, 0.2, 0.06), p["wall2"], at(2.3, 0.2, 1.05))


static func _edge4y(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var top := 1.9
	var pp := Vector3(0.95, top, -1.45)
	# a brass cage around the pylon's foot, glowing seams up the podium sides
	for i in 8:
		var a := TAU * i / 8.0
		beam(k, pp + Vector3(cos(a) * 1.15, 0.0, sin(a) * 1.15), pp + Vector3(cos(a) * 0.9, 1.6, sin(a) * 0.9), 0.04, brass)
	ring(k, pp + Vector3(0, 1.6, 0), 0.92, 0.035, brass, Vector3.ZERO, 16)
	ring(k, pp + Vector3(0, 0.05, 0), 1.15, 0.035, brass, Vector3.ZERO, 16)
	# a glowing coolant loop along the podium front, a holographic sign
	ArchKit.pipes(k, [Vector3(-2.7, 0.3, -0.38), Vector3(-2.7, 1.5, -0.38), Vector3(-0.2, 1.5, -0.38), Vector3(-0.2, 0.3, -0.38)], 0.045, lit(p["accent2"], 0.5))
	k.box(Vector3(1.4, 0.45, 0.02), lit(p["accent2"], 0.6), at(1.6, 2.3, -0.1))
	text(k, "EDGE", at(1.6, 2.13, -0.08), 0.045, lit(p["glow"], 0.3), 0.02)
	for sx in [-1.0, 1.0]:
		beam(k, Vector3(1.6 + sx * 0.65, 2.1, -0.1), Vector3(1.6 + sx * 0.65, 2.1, -0.5), 0.04, brass)
	# more drones on patrol
	for i in 3:
		drone(k, Vector3(-1.8 + i * 1.3, 4.0 + i * 0.5, -0.6 - i * 0.4), t, i * 50.0)


static func _hub1y(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var top := 0.1 + 2.9 + 0.12
	# a little site office on the shed roof with a stair up the side
	var o := Vector3(0.0, top, -2.5)
	k.box(Vector3(1.8, 1.7, 0.6), p["wall"], at(o.x, o.y + 0.85, o.z))
	ArchKit.corrugated(k, at(o.x, o.y, o.z + 0.3), 1.8, 1.7, p["wall"].darkened(0.05))
	k.box(Vector3(0.8, 0.5, 0.04), p["glass"], at(o.x - 0.4, o.y + 1.1, o.z + 0.33))
	k.box(Vector3(1.9, 0.08, 0.7), p["trim"], at(o.x, o.y + 1.74, o.z))
	ArchKit.ac_unit(k, at(o.x + 0.5, o.y + 1.78, o.z), t, 0.6)
	ArchKit.ladder(k, xf(Vector3(2.25, 0.1, -2.2), Vector3(0, 90, 0)), top, p["accent"], true)
	ArchKit.railing(k, Vector3(-2.2, top, -2.82), Vector3(2.2, top, -2.82), 0.9, p["accent"])


static func _hub2y(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var top := 0.1 + 3.4 + 0.18
	# a brise-soleil of slats over the middle of the canopy, a round skylight
	for i in 9:
		k.box(Vector3(0.05, 0.12, 0.7), Color(0.96, 0.96, 0.97), at(-0.8 + i * 0.2, top + 0.45, -0.95))
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.06, 0.45, 0.06), p["frame"], at(sx * 0.85, top + 0.22, -0.65))
		k.box(Vector3(0.06, 0.45, 0.06), p["frame"], at(sx * 0.85, top + 0.22, -1.25))
	k.box(Vector3(1.8, 0.05, 0.06), p["trim"], at(0, top + 0.5, -0.62))
	k.cyl(0.4, 0.1, lit(Color(0.7, 0.88, 0.95), 0.7), at(0, top, -2.45), 12)
	k.torus(0.42, 0.03, p["trim"], at(0, top + 0.1, -2.45), 12, 3)


static func _hub3y(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var top := 0.1 + 3.4
	# a sorting machine where the conveyor ends, a drone launch rail on the roof
	k.box(Vector3(0.5, 1.0, 0.6), p["dark"], at(-2.0, 3.1, -0.15))
	k.box(Vector3(0.4, 0.04, 0.02), lit(p["glow"], 0.4), at(-2.0, 3.3, 0.16))
	for i in 3:
		k.box(Vector3(0.12, 0.12, 0.02), lit([Color(0.5, 1.0, 0.6), Color(1.0, 0.8, 0.4), Color(1.0, 0.4, 0.3)][i], 0.35), at(-2.15 + i * 0.15, 3.45, 0.16))
	k.box(Vector3(0.12, 0.08, 1.6), p["metal"], at(-0.6, top + 0.5, -1.9))
	for z in [-2.6, -1.2]:
		k.box(Vector3(0.08, 0.5, 0.08), p["trim"], at(-0.6, top + 0.25, z))
	drone(k, Vector3(-0.6, top + 0.65, -1.4), t, 0.0)


static func _hub4y(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var top := 0.1 + 3.2
	# a hex lattice of brass over the towers, more cells glowing up their faces
	for sx in [-1.0, 1.0]:
		var tp := Vector3(sx * 1.55, top, -2.2)
		for i in 6:
			var a := TAU * i / 6.0
			beam(k, tp + Vector3(cos(a) * 0.7, 0.0, sin(a) * 0.7), tp + Vector3(cos(a) * 0.7, 2.4, sin(a) * 0.7), 0.035, brass)
	# drones docking: a column of them rising from the plaza ring
	for i in 5:
		drone(k, Vector3(-0.3 + sin(i * 1.3) * 0.6, 3.6 + i * 0.45, 1.1 + cos(i * 1.3) * 0.5), t, i * 33.0)


static func _tr1y(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	var rt := 4.2 + 0.12
	# a sawtooth of north lights over the hall roof
	for i in 4:
		var z0 := -3.2 + i * 0.95
		var b := xf(Vector3(0, rt + 0.3, z0 + 0.48), Vector3(-32, 0, 0))
		k.box(Vector3(7.6, 0.06, 1.1), p["roof"].lightened(0.06), b)
		k.box(Vector3(7.6, 0.55, 0.04), lit(Color(0.7, 0.85, 0.95), 0.7), at(0, rt + 0.32, z0 + 0.02))
		for j in 9:
			k.box(Vector3(0.05, 0.58, 0.06), p["frame"], at(-3.6 + j * 0.9, rt + 0.32, z0 + 0.03))


static func _tr2y(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	var rt := 0.1 + 4.4 + 0.22
	# a white pergola over the green roof, lanterns along the gallery wings
	for i in 7:
		k.box(Vector3(0.05, 0.1, 1.3), Color(0.96, 0.96, 0.97), at(-3.4 + i * 0.3, rt + 1.0, -0.3))
	for x in [-3.5, -1.6]:
		for z in [-0.85, 0.25]:
			k.box(Vector3(0.06, 1.0, 0.06), p["frame"], at(x, rt + 0.5, z))


static func _tr3y(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	var rt := 0.1 + 4.8 + 0.3
	# pipe bridges between the cooling towers, a second chiller row, cable trays
	for i in 2:
		ArchKit.pipes(k, [Vector3(-2.5, rt + 2.0 - i * 0.2, -2.6 + i * 0.15), Vector3(2.5, rt + 2.0 - i * 0.2, -2.6 + i * 0.15)], 0.07, Color(0.36, 0.6, 0.86) if i == 0 else Color(0.86, 0.86, 0.84))
	for x in [-1.2, 1.2]:
		k.box(Vector3(0.08, 2.0, 0.08), p["trim"], at(x, rt + 1.0, -2.55))


static func _tr4y(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	var rt := 0.1 + 5.4
	# four small spires at the nave corners, brass caps on the buttresses
	for sx in [-1.0, 1.0]:
		for z in [-3.1, 0.0]:
			var sp := Vector3(sx * 3.1, rt + 0.5, z)
			k.cyl(0.14, 1.6, p["wall2"], at(sp.x, sp.y, sp.z), 6, 0.0, 0.03)
			ring(k, sp + Vector3(0, 0.5, 0), 0.16, 0.025, brass, Vector3.ZERO, 8)
			k.sphere(0.08, lit(p["glow"], 0.3), at(sp.x, sp.y + 1.65, sp.z), 6, 3)
		for z in [-3.0, -1.9, -0.8, 0.3]:
			k.box(Vector3(0.54, 0.08, 0.26), brass, at(sx * 3.55, 0.1 + 5.6, z))


static func _lp1y(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	# a cable reel trailer by the gantry
	for sz in [-1.0, 1.0]:
		k.cyl(0.4, 0.05, Pal.WOOD, xf(Vector3(-3.2, 0.55, -0.9 + sz * 0.18), Vector3(90, 0, 0)), 10)
	k.cyl(0.26, 0.32, Color(0.2, 0.2, 0.22), xf(Vector3(-3.2, 0.55, -1.08), Vector3(90, 0, 0)), 10)
	k.box(Vector3(0.6, 0.08, 0.6), p["trim"], at(-3.2, 0.14, -0.9))


static func _lp2y(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	# a second lightning mast and a white catenary between the masts
	var m1 := Vector3(-0.6, 0.1, -3.5) + Vector3(0, 7.5 + 1.4, 0)
	var m2 := _lightning_mast(k, Vector3(1.2, 0.1, -3.6), 7.0, Color(0.92, 0.92, 0.92))
	cable(k, m1 + Vector3(0, -0.6, 0), m2 + Vector3(0, -0.6, 0), 0.6, Color(0.5, 0.52, 0.56), 0.012, 6)
	# a camera bunker in front of the pad
	k.rbox(Vector3(0.7, 0.4, 0.5), 0.1, Color(0.97, 0.97, 0.97), at(1.6, 0.3, 0.45), 1)
	k.box(Vector3(0.3, 0.12, 0.02), p["glass"], at(1.6, 0.35, 0.7))


static func _lp3y(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	# sound suppression: a water pipe from the tower to the pad, a valve house
	ArchKit.pipes(k, [Vector3(3.0, 5.0, -3.0), Vector3(3.0, 0.4, -3.0), Vector3(2.3, 0.4, -2.9)], 0.08, Color(0.36, 0.6, 0.86))
	k.box(Vector3(0.5, 0.6, 0.5), p["wall2"], at(1.6, 0.4, -3.55))
	k.box(Vector3(0.54, 0.06, 0.54), p["trim"], at(1.6, 0.72, -3.55))


static func _lp4y(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	# a second cantilevered brass arm crown on the gantry, glowing tank caps
	var gp := Vector3(-1.4, 0.1, -1.4)
	for y in [8.6, 9.3]:
		k.box(Vector3(1.4, 0.05, 1.4), brass, at(gp.x, y, gp.z))
	for i in 3:
		var tp := Vector3(2.4 + i * 0.6, 0.1, -3.3 + (i % 2) * 0.5)
		k.sphere(0.12, lit(p["glow"], 0.3), at(tp.x, 2.92, tp.z), 6, 3)


static func _gs1y(k: MeshKit) -> void:
	var t := 1
	var p := ArchKit.pal(t)
	# a guyed radio mast with yagis at the back left
	var mp := Vector3(-2.3, 0.1, -1.75)
	k.cyl(0.05, 4.0, p["metal"], at(mp.x, mp.y, mp.z), 6)
	for y in [2.6, 3.4, 4.0]:
		yagi(k, xf(mp + Vector3(0, y, 0), Vector3(-10, 40.0 * y, 0)), 0.8, Color(0.86, 0.88, 0.9), 6)
	for g in [Vector3(-2.85, 0.1, -1.4), Vector3(-1.4, 0.1, -2.85)]:
		beam(k, mp + Vector3(0, 3.0, 0), g, 0.012, Color(0.3, 0.3, 0.32))
	ArchKit.beacon(k, mp + Vector3(0, 4.0, 0), 0.2)


static func _gs2y(k: MeshKit) -> void:
	var t := 2
	var p := ArchKit.pal(t)
	# a third small radome and a covered walkway to the control building
	k.cyl(0.4, 0.5, p["wall2"], at(-2.35, 0.1, -1.25), 10)
	k.sphere(0.5, Color(0.97, 0.97, 0.97), at(-2.35, 0.85, -1.25), 12, 7)
	for i in 3:
		k.box(Vector3(0.06, 2.0, 0.06), p["frame"], at(-0.6, 1.1, -0.2 + i * 0.6))
	k.box(Vector3(0.6, 0.06, 1.6), p["wall"], at(-0.6, 2.1, 0.4))
	k.box(Vector3(0.62, 0.04, 1.62), p["trim"], at(-0.6, 2.14, 0.4))


static func _gs3y(k: MeshKit) -> void:
	var t := 3
	var p := ArchKit.pal(t)
	# a maintenance platform round the big antenna's drum, floodlights
	ring(k, Vector3(-0.2, 1.5, -1.1), 1.15, 0.04, p["accent"], Vector3.ZERO, 16)
	k.cyl(1.2, 0.05, p["metal"].darkened(0.2), at(-0.2, 1.45, -1.1), 14)
	for i in 6:
		var a := TAU * i / 6.0
		k.box(Vector3(0.04, 0.9, 0.04), p["accent"], at(-0.2 + cos(a) * 1.15, 1.95, -1.1 + sin(a) * 1.15))
	for pp in [Vector3(2.6, 0.1, -1.4), Vector3(2.6, 0.1, 0.9)]:
		k.cyl(0.04, 3.0, p["metal"], at(pp.x, pp.y, pp.z), 6)
		k.box(Vector3(0.3, 0.15, 0.15), p["dark"], at(pp.x, 3.1, pp.z))


static func _gs4y(k: MeshKit) -> void:
	var t := 4
	var p := ArchKit.pal(t)
	var brass: Color = p["trim"]
	# a fourth, smaller array on the pavilion's side and brass rings on the mast
	var b := xf(Vector3(-2.3, 0.1, -0.85), Vector3(0, 30, 0))
	k.box(Vector3(0.8, 0.5, 0.5), p["wall"], b * at(0, 0.25, 0))
	var pf := b * xf(Vector3(0, 1.0, 0), Vector3(-62, 0, 0))
	k.box(Vector3(0.9, 0.8, 0.08), p["wall2"], pf)
	for i in 3:
		for j in 3:
			k.box(Vector3(0.24, 0.22, 0.02), lit(p["accent2"], 0.55), pf * at(-0.28 + i * 0.28, -0.25 + j * 0.25, 0.05))
	var up: Vector3 = pf * Vector3(0, 0, 0.1)
	var dir: Vector3 = (pf.basis * Vector3(0, 0, 1)).normalized()
	rod(k, up, up + dir * 3.5, 0.12, lit(p["accent2"], 0.85), 6)


## A little person standing at p (hard hat for workshop/industrial crews).
static func person(k: MeshKit, p: Vector3, col: Color, hat := Color.TRANSPARENT) -> void:
	k.capsule(0.11, 0.62, col, at(p.x, p.y + 0.42, p.z), 6, 2)
	for sx in [-1.0, 1.0]:
		k.box(Vector3(0.08, 0.42, 0.09), Color(0.24, 0.26, 0.32), at(p.x + sx * 0.05, p.y + 0.21, p.z))
	k.sphere(0.09, Color(0.92, 0.78, 0.66), at(p.x, p.y + 1.12, p.z), 6, 3)
	if hat.a > 0.0:
		k.sphere(0.1, hat, xf(Vector3(p.x, p.y + 1.17, p.z), Vector3.ZERO, Vector3(1, 0.6, 1)), 6, 3)


## Last pass: people and vehicles that bring each era to life.
static func _life(k: MeshKit, kind: String, t: int) -> void:
	var hard := Color(0.98, 0.8, 0.22) if t == 1 or t == 3 else Color.TRANSPARENT
	var shirt: Color = [Color(0.85, 0.35, 0.3), Color(0.95, 0.55, 0.2), Color(0.3, 0.6, 0.68), Color(0.3, 0.42, 0.6), Color(0.2, 0.21, 0.24)][t]
	match kind:
		"gateway":
			match t:
				0: person(k, Vector3(-0.2, 0.15, -1.4), shirt)
				1: person(k, Vector3(-0.4, 0.3, -1.0), shirt, hard)
				2: person(k, Vector3(0.6, 0.15, -1.0), shirt)
				3: person(k, Vector3(-1.0, 0.1, -0.1), shirt, hard)
				_: person(k, Vector3(-0.3, 0.1, 0.5), Color(0.78, 0.63, 0.38))
		"edge":
			match t:
				0: person(k, Vector3(1.2, 0.1, -1.4), shirt)
				1:
					person(k, Vector3(1.7, 0.1, -1.65), shirt, hard)
				2: person(k, Vector3(-1.9, 0.1, 0.6), shirt)
				3:
					person(k, Vector3(-1.8, 2.9, -0.2), shirt, hard)
					person(k, Vector3(1.3, 0.1, -1.2), shirt, hard)
				_: person(k, Vector3(-1.9, 0.1, 0.9), Color(0.78, 0.63, 0.38))
		"agent_hub":
			match t:
				0: person(k, Vector3(0.2, 0.1, -1.0), shirt)
				1: person(k, Vector3(2.62, 0.1, 0.95), shirt, hard)
				3: person(k, Vector3(2.62, 0.1, 0.25), shirt, hard)
				_: pass
		"trainer":
			match t:
				0:
					person(k, Vector3(-2.0, 0.1, -0.5), shirt)
					person(k, Vector3(1.5, 0.1, -0.4), Color(0.3, 0.5, 0.8))
				1:
					person(k, Vector3(-2.0, 0.1, 0.15), shirt, hard)
					person(k, Vector3(1.5, 0.1, -0.7), shirt, hard)
				2:
					person(k, Vector3(-1.2, 0.1, -0.5), shirt)
					person(k, Vector3(2.2, 0.1, 0.3), Color(0.85, 0.5, 0.6))
				3:
					person(k, Vector3(1.2, 0.1, 0.0), shirt, hard)
					person(k, Vector3(-1.5, 4.55, 0.55), shirt, hard)
				_: person(k, Vector3(-1.0, 0.1, -0.5), Color(0.78, 0.63, 0.38))
		"launchpad":
			match t:
				0:
					person(k, Vector3(-1.25, 0.1, 1.55), Color(0.3, 0.5, 0.8))
					person(k, Vector3(-2.2, 0.1, 0.9), Color(0.95, 0.75, 0.3))
				1:
					person(k, Vector3(1.0, 0.1, 0.2), shirt, hard)
					ArchKit.vehicle(k, xf(Vector3(-2.2, 0.1, 1.2), Vector3(0, 0, 0)), 1)
				2:
					person(k, Vector3(2.2, 0.1, 1.2), shirt)
					ArchKit.vehicle(k, xf(Vector3(-0.3, 0.1, 1.3), Vector3(0, 90, 0)), 2)
				3:
					person(k, Vector3(1.6, 0.1, 0.9), shirt, hard)
					person(k, Vector3(-0.3, 2.3, -1.15), shirt, hard)
				_: ArchKit.vehicle(k, xf(Vector3(0.6, 0.1, 1.25), Vector3(0, 90, 0)), 4)
		"groundstation":
			match t:
				0: pass
				1:
					person(k, Vector3(0.3, 0.1, 0.5), shirt, hard)
				2: person(k, Vector3(0.0, 0.1, 0.6), shirt)
				3: person(k, Vector3(0.2, 1.5, -0.1), shirt, hard)
				_: person(k, Vector3(0.3, 0.1, 0.6), Color(0.78, 0.63, 0.38))


## Fences, shelving and finishing touches on the lightest looks.
static func _finish(k: MeshKit, kind: String, t: int) -> void:
	var p := ArchKit.pal(t)
	match kind:
		"groundstation":
			match t:
				1:
					# dishes on the control container's roof, a weather mast
					sat_dish(k, at(-2.35, 2.55, 1.6), 0.25, t, 50.0, 20.0, 0.2, Color(0.9, 0.9, 0.9))
					sat_dish(k, at(-0.65, 2.55, 2.1), 0.22, t, 55.0, -30.0, 0.2, Color(0.9, 0.9, 0.9))
					ArchKit.fence(k, Vector3(-2.88, 0.1, -2.2), Vector3(-2.88, 0.1, -0.2), t, 1.5)
				2:
					ArchKit.fence(k, Vector3(2.88, 0.1, -2.88), Vector3(2.88, 0.1, 0.9), t, 1.0)
					ArchKit.fence(k, Vector3(-2.88, 0.1, -2.2), Vector3(-2.88, 0.1, -0.1), t, 1.0)
				3:
					ArchKit.fence(k, Vector3(-2.88, 0.1, -2.2), Vector3(-2.88, 0.1, -0.1), t, 1.4)
					ArchKit.fence(k, Vector3(2.88, 0.1, -2.6), Vector3(2.88, 0.1, 0.9), t, 1.4)
					ArchKit.cable_tray(k, Vector3(2.15, 0.6, 0.3), Vector3(2.15, 0.6, 0.9), t)
				4:
					ArchKit.fence(k, Vector3(2.88, 0.1, -2.88), Vector3(2.88, 0.1, 0.9), t, 1.0)
					ArchKit.fence(k, Vector3(-2.88, 0.1, -2.2), Vector3(-2.88, 0.1, -0.1), t, 1.0)
		"trainer":
			match t:
				1:
					shelving(k, xf(Vector3(-3.75, 0.1, -1.7), Vector3(0, 90, 0)), 1.8, 2.0, 4, Color(0.2, 0.36, 0.66), [Color(0.72, 0.56, 0.38), Color(0.3, 0.5, 0.8), Color(0.15, 0.15, 0.17), Color(0.4, 0.75, 0.3)])
					for i in 4:
						k.box(Vector3(1.2, 0.04, 0.2), lit(p["glow"], 0.35), at(-2.7 + i * 1.8, 3.9, -0.8))
						k.box(Vector3(0.02, 0.3, 0.02), Color(0.3, 0.3, 0.32), at(-2.7 + i * 1.8, 4.07, -0.8))
				2:
					# a sculpture and white benches out front, info totems
					k.box(Vector3(0.6, 0.3, 0.6), Color(0.96, 0.96, 0.97), at(-2.4, 0.25, 2.2))
					k.box(Vector3(0.12, 1.4, 0.12), p["accent"], xf(Vector3(-2.4, 1.0, 2.2), Vector3(15, 30, 10)))
					k.sphere(0.2, lit(p["glow"], 0.4), at(-2.2, 1.75, 2.25), 8, 4)
				3:
					shelving(k, xf(Vector3(-3.7, 0.1, -2.3), Vector3(0, 90, 0)), 1.0, 2.0, 4, p["trim"], [p["dark"], Color(0.3, 0.5, 0.8), Color(0.9, 0.6, 0.2)])
		"agent_hub":
			match t:
				2:
					# white fence panels along the back, lanterns on the canopy edge
					for i in 6:
						k.box(Vector3(0.12, 0.3, 0.12), lit(p["glow"], 0.35), at(-2.3 + i * 0.92, 3.42, -0.06))
					ArchKit.fence(k, Vector3(-2.88, 0.1, -2.88), Vector3(-2.88, 0.1, -2.1), t, 1.0)
					ArchKit.fence(k, Vector3(2.88, 0.1, -2.88), Vector3(2.88, 0.1, -2.1), t, 1.0)
		"edge":
			match t:
				4:
					for i in 5:
						k.box(Vector3(0.05, 1.6, 0.3), p["wall2"], at(-2.85 + 0.03, 1.0, -2.6 + i * 0.5))
					ArchKit.fence(k, Vector3(-2.88, 0.1, 0.0), Vector3(-2.88, 0.1, 2.8), t, 1.0)


## Density: era-appropriate clutter in a few known-free spots.
static func _dense(k: MeshKit, kind: String, t: int) -> void:
	var p := ArchKit.pal(t)
	match kind:
		"edge":
			if t == 0:
				yard_dress(k, Rect2(-2.8, 1.0, 0.7, 1.8), t, 3, [], 0.7)
			elif t == 4:
				yard_dress(k, Rect2(-2.3, 0.2, 0.8, 2.2), t, 4, [], 0.8)
		"launchpad":
			if t == 1:
				for i in 24:
					k.box(Vector3(0.1, 0.02, 0.08), Color(0.56, 0.54, 0.5), xf(Vector3(-0.4 + fposmod(i * 0.61, 3.6), 0.11, 1.2 + fposmod(i * 0.29, 0.8)), Vector3(0, i * 29.0, 0)))


# ---------------------------------------------------------------- the orbital datacenter

## The station's spine: a long square truss (modules attach along it, see
## orbit_module), a pressurised docking hub with a glowing ring, solar wings
## and radiators at the ends.
static func orbit_spine(n: int) -> Mesh:
	var k := MeshKit.new()
	var len := maxf(4.0, n * 1.6 + 2.0)
	var white := Color(0.84, 0.86, 0.88)
	var grey := Color(0.6, 0.62, 0.66)
	var s := 0.36
	for sy in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.box(Vector3(len, 0.05, 0.05), white, at(0, sy * s * 0.5, sz * s * 0.5))
	var segs := int(len / 0.5)
	for i in segs + 1:
		var x := -len * 0.5 + i * len / segs
		k.box(Vector3(0.04, s + 0.05, 0.04), grey, at(x, 0, s * 0.5))
		k.box(Vector3(0.04, s + 0.05, 0.04), grey, at(x, 0, -s * 0.5))
		k.box(Vector3(0.04, 0.04, s + 0.05), grey, at(x, s * 0.5, 0))
		k.box(Vector3(0.04, 0.04, s + 0.05), grey, at(x, -s * 0.5, 0))
		if i < segs:
			var x2 := x + len / segs
			var f := 1.0 if i % 2 == 0 else -1.0
			beam(k, Vector3(x, -s * 0.5 * f, s * 0.5), Vector3(x2, s * 0.5 * f, s * 0.5), 0.025, grey)
			beam(k, Vector3(x, s * 0.5 * f, -s * 0.5), Vector3(x2, -s * 0.5 * f, -s * 0.5), 0.025, grey)
	# a cable run and a rail along the truss
	k.box(Vector3(len, 0.06, 0.06), Color(0.98, 0.64, 0.86, 0.5), at(0, 0, 0))
	k.box(Vector3(len, 0.03, 0.03), Color(0.78, 0.63, 0.38), at(0, s * 0.5 + 0.04, s * 0.5))
	# the docking hub
	k.cyl(0.6, 1.0, Color(0.94, 0.94, 0.92), at(0, -0.5, 0), 14, 0.08)
	for y in [-0.3, 0.0, 0.3]:
		k.cyl(0.61, 0.04, Color(0.78, 0.63, 0.38), at(0, y, 0), 14, 0.0, -1.0, false)
	for sz in [-1.0, 1.0]:
		k.cyl(0.3, 0.35, Color(0.9, 0.9, 0.88), xf(Vector3(0, 0, sz * 0.55), Vector3(sz * 90.0, 0, 0)), 10)
		k.torus(0.28, 0.03, Color(0.5, 0.9, 1.0, 0.45), xf(Vector3(0, 0, sz * 0.92), Vector3(90, 0, 0)), 12, 4)
	for i in 6:
		k.box(Vector3(0.1, 0.06, 0.02), Color(0.5, 1.0, 0.6, 0.4), xf(Vector3(cos(TAU * i / 6.0) * 0.61, 0.15, sin(TAU * i / 6.0) * 0.61), Vector3(0, -rad_to_deg(TAU * i / 6.0) + 90.0, 0)))
	k.torus(0.9, 0.06, Color(0.5, 0.9, 1.0, 0.42), at(0, 0, 0), 24, 5)
	# end caps with a small radiator and an antenna boom
	for sx in [-1.0, 1.0]:
		var ex: float = sx * (len * 0.5 + 0.1)
		k.box(Vector3(0.3, 0.3, 0.3), grey, at(ex, 0, 0))
		k.box(Vector3(0.03, 0.6, 0.5), Color(0.96, 0.96, 0.94), at(ex + sx * 0.18, 0.0, 0))
		for j in 4:
			k.box(Vector3(0.04, 0.02, 0.5), Color(0.82, 0.84, 0.86), at(ex + sx * 0.18, -0.24 + j * 0.16, 0))
		k.cyl(0.015, 0.6, grey, at(ex, 0.15, 0), 4)
		k.sphere(0.04, Color(1.0, 0.4, 0.35, 0.3), at(ex, 0.78, 0), 6, 3)
	return k.commit()


## One orbital server module: a pressurised can of racks with a glowing
## window strip, docking rings, solar wings on a truss, a radiator and a dish.
static func orbit_module() -> Mesh:
	var k := MeshKit.new()
	var white := Color(0.95, 0.95, 0.94)
	var grey := Color(0.6, 0.62, 0.66)
	var brass := Pal.BRASS
	k.cyl(0.45, 1.3, white, at(0, -0.65, 0), 14, 0.06)
	for y in [-0.45, -0.1, 0.25, 0.55]:
		k.cyl(0.46, 0.04, brass if y == -0.1 else Color(0.82, 0.83, 0.84), at(0, y, 0), 14, 0.0, -1.0, false)
	# a docking collar at the base, a hatch on top
	k.cyl(0.3, 0.12, Color(0.84, 0.85, 0.86), at(0, -0.77, 0), 10)
	k.torus(0.28, 0.025, Color(0.5, 0.9, 1.0, 0.45), at(0, -0.77, 0), 12, 4)
	k.cyl(0.22, 0.1, Color(0.84, 0.85, 0.86), at(0, 0.65, 0), 10)
	# window strips with rack lights inside (front and back)
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.36, 0.5, 0.02), Color(0.2, 0.22, 0.26), at(0, 0.05, sz * 0.45))
		for i in 4:
			k.box(Vector3(0.06, 0.02, 0.01), Color(0.5, 1.0, 0.6, 0.4) if i % 2 == 0 else Color(0.5, 0.86, 1.0, 0.4), at(-0.12 + i * 0.08, -0.05 + (i % 2) * 0.15, sz * 0.465))
			k.box(Vector3(0.06, 0.02, 0.01), Color(0.5, 0.86, 1.0, 0.4), at(-0.12 + i * 0.08, 0.2 - (i % 2) * 0.1, sz * 0.465))
	# handrails
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		k.box(Vector3(0.03, 1.0, 0.03), brass, at(cos(a) * 0.5, 0, sin(a) * 0.5))
	# the solar wings on a truss along z
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.06, 0.06, 1.5), grey, at(0, 0.3, sz * 0.95))
		k.box(Vector3(0.14, 0.14, 0.14), grey, at(0, 0.3, sz * 0.5))
		for w in 2:
			var wz: float = sz * (1.25 + w * 0.9)
			k.box(Vector3(1.1, 0.03, 0.82), Color(0.16, 0.24, 0.48), at(0, 0.3, wz))
			for j in 4:
				k.box(Vector3(1.12, 0.035, 0.015), Color(0.84, 0.86, 0.88), at(0, 0.3, wz - 0.3 + j * 0.2))
			for j in 3:
				k.box(Vector3(0.015, 0.035, 0.82), Color(0.7, 0.72, 0.76), at(-0.37 + j * 0.37, 0.3, wz))
	# a radiator panel and a little dish
	k.box(Vector3(0.9, 0.02, 0.5), Color(0.96, 0.96, 0.94), at(0, -0.5, 0.0))
	for j in 5:
		k.box(Vector3(0.9, 0.03, 0.02), Color(0.84, 0.86, 0.88), at(0, -0.49, -0.2 + j * 0.1))
	k.cyl(0.02, 0.25, grey, xf(Vector3(0.45, 0.4, 0), Vector3(0, 0, -90)), 4)
	k.lathe(PackedVector2Array([Vector2(0, 0), Vector2(0.12, 0.03), Vector2(0.18, 0.08), Vector2(0.0, 0.02)]), white, xf(Vector3(0.7, 0.4, 0), Vector3(0, 0, -70)), 10)
	k.sphere(0.03, Color(1.0, 0.4, 0.35, 0.3), at(0, 0.78, 0), 6, 4)
	# quilted thermal blanket panels round the can, a radiator fin array
	for i in 8:
		var an := TAU * i / 8.0 + PI / 8.0
		for j in 2:
			k.box(Vector3(0.28, 0.32, 0.02), Color(0.9, 0.88, 0.8) if (i + j) % 2 == 0 else Color(0.86, 0.84, 0.76), xf(Vector3(cos(an) * 0.455, -0.3 + j * 0.65, sin(an) * 0.455), Vector3(0, -rad_to_deg(an) + 90.0, 0)))
	for i in 6:
		k.box(Vector3(0.02, 0.5, 0.36), Color(0.96, 0.96, 0.94), at(-0.3 + i * 0.12, -0.25, -0.62))
	# a docking light ring and a star tracker
	for i in 6:
		var a2 := TAU * i / 6.0
		k.box(Vector3(0.05, 0.03, 0.05), Color(0.5, 1.0, 0.6, 0.4) if i % 2 else Color(1.0, 0.4, 0.35, 0.4), at(cos(a2) * 0.31, -0.7, sin(a2) * 0.31))
	k.box(Vector3(0.1, 0.12, 0.1), Color(0.3, 0.32, 0.36), at(-0.3, 0.7, 0.2))
	k.cyl(0.03, 0.05, Color(0.2, 0.2, 0.22), xf(Vector3(-0.3, 0.76, 0.26), Vector3(60, 0, 0)), 6)
	return k.commit()
