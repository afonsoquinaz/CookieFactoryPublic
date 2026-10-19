class_name InfraArt
## Looks for the infrastructure buildings of the inference economy, in five
## tiers each (0 garage wood .. 4 black and brass):
##   gateway        API Gateway: a network hut with a big dish and a
##                  load-balancer pillar, fiber spools racked out front
##   edge           Edge PoP: a container datacenter with a cell tower
##   agent_hub      Agent Hub: a pavilion with a giant workflow screen
##   trainer        Training Cluster: a hall of GPU racks and a loss screen
##   launchpad      Launch Complex: pad, gantry, assembly bays
##   groundstation  Ground Station: big dishes and a control hut
## plus the rocket and the orbital datacenter's modules.

static func lit(c: Color, a := 0.42) -> Color:
	return Color(c.r, c.g, c.b, a)


static func wall(t: int) -> Color:
	return [Color(0.8, 0.68, 0.5), Color(0.8, 0.82, 0.85), Color(0.95, 0.95, 0.96), Color(0.48, 0.52, 0.58), Color(0.17, 0.18, 0.21)][clampi(t, 0, 4)]


static func trim(t: int) -> Color:
	return [Pal.WOOD_DARK, Color(0.36, 0.38, 0.42), Color(0.3, 0.66, 0.68), Color(0.24, 0.26, 0.3), Pal.BRASS][clampi(t, 0, 4)]


static func glow(t: int) -> Color:
	return [Color(1.0, 0.82, 0.5), Color(0.6, 1.0, 0.62), Color(0.42, 0.96, 0.9), Color(0.45, 0.75, 1.0), Color(1.0, 0.86, 0.5)][clampi(t, 0, 4)]


static func floor_slab(k: MeshKit, w: float, d: float, t: int, z := 0.0) -> void:
	var c: Color = [Color(0.64, 0.62, 0.58), Color(0.72, 0.72, 0.7), Color(0.84, 0.85, 0.86), Color(0.5, 0.53, 0.58), Color(0.22, 0.23, 0.26)][clampi(t, 0, 4)]
	k.rbox(Vector3(w, 0.12, d), 0.05, c, MeshKit.at(0, 0.06, z))
	if t >= 2:
		k.rbox(Vector3(w + 0.04, 0.04, 0.08), 0.01, trim(t), MeshKit.at(0, 0.1, z + d * 0.5 - 0.04))
	if t >= 3:
		k.rbox(Vector3(w - 0.3, 0.02, 0.04), 0.01, lit(glow(t)), MeshKit.at(0, 0.13, z + d * 0.5 - 0.15))


## A dish on a yoke (local: base on the ground, dish facing +y tilted to +z).
static func dish(k: MeshKit, p: Vector3, r: float, t: int, tilt := 40.0, yaw := 0.0) -> void:
	var base := MeshKit.xf(p, Vector3(0, yaw, 0))
	k.cyl(r * 0.32, r * 0.25, trim(t), base, 10, 0.03)
	k.cyl(r * 0.1, r * 0.9, Color(0.6, 0.62, 0.66), base * MeshKit.at(0, r * 0.25, 0), 8)
	var dx := base * MeshKit.xf(Vector3(0, r * 1.1, 0), Vector3(-tilt, 0, 0))
	k.lathe(PackedVector2Array([Vector2(0.0, 0.0), Vector2(r * 0.5, r * 0.06), Vector2(r, r * 0.28), Vector2(r * 0.95, r * 0.3), Vector2(r * 0.48, r * 0.1), Vector2(0.0, r * 0.04)]), Color(0.95, 0.95, 0.94), dx, 20)
	for i in 3:
		var a := TAU * i / 3.0
		k.cyl(r * 0.02, r * 0.85, Color(0.5, 0.52, 0.56), dx * MeshKit.xf(Vector3(cos(a) * r * 0.8, r * 0.28, sin(a) * r * 0.8), Vector3(rad_to_deg(sin(a)) * 30.0, 0, -rad_to_deg(cos(a)) * 30.0)), 4)
	k.sphere(r * 0.09, lit(Color(1.0, 0.45, 0.3)) if t >= 3 else Color(0.3, 0.32, 0.36), dx * MeshKit.at(0, r * 0.95, 0), 8, 5)


## A lattice tower of height h.
static func lattice(k: MeshKit, p: Vector3, h: float, w: float, col: Color) -> void:
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.03, h, col, MeshKit.xf(p + Vector3(sx * w, 0, sz * w), Vector3(-sz * 2.0, 0, sx * 2.0)), 5)
	for i in int(h / 0.45):
		var y := 0.2 + i * 0.45
		var r := w * (1.0 - y / h * 0.45)
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(r * 2.0, 0.03, 0.03), 0.005, Color(0.94, 0.94, 0.92), MeshKit.at(p.x, p.y + y, p.z + sz * r))
			k.rbox(Vector3(0.03, 0.03, r * 2.0), 0.005, Color(0.94, 0.94, 0.92), MeshKit.at(p.x + sz * r, p.y + y, p.z))


# ---------------------------------------------------------------- API Gateway (4 x 6 m)

static func gateway(t: int) -> Mesh:
	var k := MeshKit.new()
	floor_slab(k, 3.9, 5.9, t)
	var w := wall(t)
	var h := 2.4 + t * 0.2
	# the network hut at the back, a glass front with router stacks inside
	k.rbox(Vector3(3.6, h, 2.2), 0.08, w, MeshKit.at(0, h * 0.5 + 0.12, -1.7))
	k.rbox(Vector3(3.8, 0.16, 2.4), 0.04, trim(t), MeshKit.at(0, h + 0.2, -1.7))
	k.rbox(Vector3(2.4, 1.5, 0.06), 0.06, Color(0.62, 0.8, 0.9, 0.62), MeshKit.at(-0.3, 1.1, -0.58))
	for i in 3:
		var x := -1.0 + i * 0.7
		k.rbox(Vector3(0.5, 1.3, 0.4), 0.03, Color(0.16, 0.17, 0.2), MeshKit.at(x, 0.8, -0.95))
		for j in 6:
			k.rbox(Vector3(0.04, 0.025, 0.01), 0.005, lit(glow(t) if (i + j) % 3 else Color(0.5, 1.0, 0.6)), MeshKit.at(x - 0.14 + (j % 3) * 0.1, 0.5 + (j / 3) * 0.5, -0.74))
	k.rbox(Vector3(0.7, 1.7, 0.07), 0.04, trim(t), MeshKit.at(1.35, 0.97, -0.58))
	# the sign: "API" in three glowing blocks
	k.rbox(Vector3(1.6, 0.5, 0.1), 0.12, Color(0.14, 0.15, 0.18) if t > 0 else Color(0.95, 0.94, 0.9), MeshKit.at(0, h - 0.15, -0.55))
	for i in 3:
		k.rbox(Vector3(0.32, 0.3, 0.02), 0.04, lit(glow(t), 0.4) if t > 0 else trim(t), MeshKit.at(-0.45 + i * 0.45, h - 0.15, -0.49))
	# a dish on the roof, bigger each tier
	dish(k, Vector3(-0.9, h + 0.28, -2.0), 0.55 + t * 0.12, t, 35.0, 30.0)
	k.cyl(0.03, 1.0 + t * 0.3, Color(0.84, 0.86, 0.88), MeshKit.at(1.2, h + 0.28, -2.2), 5)
	k.sphere(0.05, lit(Color(1.0, 0.3, 0.3)), MeshKit.at(1.2, h + 1.3 + t * 0.3, -2.2), 6, 4)
	# the load balancer: a pillar of lights by the door
	k.rbox(Vector3(0.5, 1.6 + t * 0.15, 0.5), 0.06, Color(0.2, 0.21, 0.24), MeshKit.at(1.5, 0.9, 0.4))
	for j in 5:
		k.rbox(Vector3(0.52, 0.06, 0.52), 0.02, lit(glow(t)), MeshKit.at(1.5, 0.35 + j * 0.28, 0.4))
	# the fiber rack out front (spools sit on it: see GatewayB)
	k.rbox(Vector3(2.2, 0.12, 0.7), 0.03, trim(t), MeshKit.at(-0.6, 0.55, 1.15))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.08, 0.55, 0.7), 0.02, Pal.STEEL_DARK, MeshKit.at(-0.6 + sx * 1.05, 0.28, 1.15))
	# a glowing fiber trunk into the ground
	k.cyl(0.08, 1.4, Color(0.98, 0.64, 0.86) if t < 3 else lit(Color(0.98, 0.64, 0.86), 0.5), MeshKit.xf(Vector3(-1.75, 0.15, -0.5), Vector3(90, 0, 0)), 8)
	if t >= 2:
		for sx in [-1.0, 1.0]:
			k.cyl(0.04, 1.6, Pal.STEEL_DARK, MeshKit.at(sx * 1.75, 0, 2.6), 6)
			k.sphere(0.1, lit(glow(t)), MeshKit.at(sx * 1.75, 1.7, 2.6), 8, 5)
	if t >= 4:
		k.torus(0.7, 0.04, lit(Color(1.0, 0.86, 0.5)), MeshKit.at(-0.9, h + 2.1, -2.0), 20, 4)
	return k.commit()


## A fiber spool (installed in a gateway).
static func spool() -> Mesh:
	var k := MeshKit.new()
	for sz in [-1.0, 1.0]:
		k.cyl(0.16, 0.03, Pal.WOOD, MeshKit.xf(Vector3(0, 0.16, sz * 0.08), Vector3(90, 0, 0)), 12)
	k.cyl(0.12, 0.14, Color(0.98, 0.64, 0.86), MeshKit.xf(Vector3(0, 0.16, 0.07), Vector3(90, 0, 0)), 12)
	return k.commit()


# ---------------------------------------------------------------- Edge PoP (6 x 6 m)

static func edge(t: int) -> Mesh:
	var k := MeshKit.new()
	floor_slab(k, 5.9, 5.9, t)
	var w := wall(t)
	# a container datacenter: corrugated walls, doors, cooling units on top
	var cw := Color(0.3, 0.6, 0.86) if t == 0 else (Color(0.62, 0.66, 0.72) if t == 1 else w)
	k.rbox(Vector3(4.6, 2.2, 2.0), 0.06, cw, MeshKit.at(-0.3, 1.22, -1.6))
	for i in 18:
		k.rbox(Vector3(0.05, 2.0, 0.04), 0.01, cw.darkened(0.15), MeshKit.at(-2.5 + i * 0.25, 1.22, -0.59))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.9, 1.9, 0.05), 0.02, cw.darkened(0.25), MeshKit.at(-0.3 + sx * 0.46, 1.12, -0.56))
	k.rbox(Vector3(0.12, 0.3, 0.02), 0.01, lit(glow(t)), MeshKit.at(-0.3, 1.4, -0.53))
	for i in 3:
		var x := -1.9 + i * 1.6
		k.rbox(Vector3(1.1, 0.4, 1.2), 0.04, Color(0.88, 0.9, 0.92), MeshKit.at(x, 2.55, -1.6))
		k.cyl(0.35, 0.04, Color(0.22, 0.23, 0.26), MeshKit.at(x, 2.76, -1.6), 14)
	# the cell tower in the corner
	lattice(k, Vector3(2.2, 0.12, -1.8), 4.5 + t * 0.6, 0.35, Color(0.86, 0.3, 0.26) if t < 3 else Color(0.84, 0.86, 0.88))
	for i in 3:
		var a := TAU * i / 3.0
		k.rbox(Vector3(0.14, 0.7, 0.08), 0.03, Color(0.94, 0.94, 0.92), MeshKit.xf(Vector3(2.2 + cos(a) * 0.32, 4.0 + t * 0.6, -1.8 + sin(a) * 0.32), Vector3(0, -rad_to_deg(a), 0)))
	k.sphere(0.07, lit(Color(1.0, 0.3, 0.3)), MeshKit.at(2.2, 4.7 + t * 0.6, -1.8), 6, 4)
	# fiber conduits glowing out to the street
	for i in 3:
		k.cyl(0.06, 4.0, lit(Color(0.98, 0.64, 0.86), 0.5) if t >= 2 else Color(0.98, 0.64, 0.86), MeshKit.xf(Vector3(-1.8 + i * 0.25, 0.14, -0.4), Vector3(90, 0, 0)), 6)
	# a battery cabinet and a generator in front
	k.rbox(Vector3(0.9, 1.1, 0.6), 0.05, Color(0.92, 0.93, 0.94), MeshKit.at(1.9, 0.67, 0.4))
	k.rbox(Vector3(0.7, 0.05, 0.02), 0.01, lit(Color(0.5, 1.0, 0.6)), MeshKit.at(1.9, 0.9, 0.71))
	if t >= 2:
		k.rbox(Vector3(1.2, 0.8, 0.8), 0.06, Color(0.34, 0.58, 0.42), MeshKit.at(-2.2, 0.52, 0.5))
	if t >= 3:
		dish(k, Vector3(-2.2, 0.12, 2.0), 0.6, t, 30.0, -40.0)
	return k.commit()


# ---------------------------------------------------------------- Agent Hub (6 x 6 m)

static func agent_hub(t: int) -> Mesh:
	var k := MeshKit.new()
	floor_slab(k, 5.9, 5.9, t)
	var w := wall(t)
	var h := 3.0 + t * 0.2
	# a pavilion: a roof on slim columns over a plaza, a giant screen at the back
	k.rbox(Vector3(5.4, 0.2, 3.8), 0.08, w, MeshKit.at(0, h, -0.8))
	k.rbox(Vector3(5.5, 0.08, 3.9), 0.03, trim(t), MeshKit.at(0, h + 0.13, -0.8))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.1, h, trim(t), MeshKit.at(sx * 2.5, 0.12, -0.8 + sz * 1.7), 10)
	k.rbox(Vector3(4.6, 2.2, 0.2), 0.08, Color(0.14, 0.15, 0.18), MeshKit.at(0, 1.55, -2.5))
	k.rbox(Vector3(4.3, 1.9, 0.05), 0.04, lit(Color(0.2, 0.32, 0.46), 0.7), MeshKit.at(0, 1.55, -2.38))
	# a workflow drawn on the screen: boxes joined by arrows
	var nodes := [Vector2(-1.6, 0.4), Vector2(-0.5, 0.7), Vector2(-0.5, 0.0), Vector2(0.6, 0.4), Vector2(1.6, 0.4)]
	for i in nodes.size():
		var n: Vector2 = nodes[i]
		k.rbox(Vector3(0.6, 0.32, 0.02), 0.06, lit([Color(0.5, 0.86, 1.0), Color(0.6, 1.0, 0.7), Color(1.0, 0.8, 0.5)][i % 3], 0.4), MeshKit.at(n.x, 1.5 + n.y - 0.3, -2.34))
	for e in [[0, 1], [0, 2], [1, 3], [2, 3], [3, 4]]:
		var a: Vector2 = nodes[e[0]]
		var b: Vector2 = nodes[e[1]]
		var mid := (a + b) * 0.5
		var ang := rad_to_deg(atan2(b.y - a.y, b.x - a.x))
		k.rbox(Vector3(a.distance_to(b) - 0.5, 0.03, 0.01), 0.005, lit(Color(0.9, 0.95, 1.0), 0.35), MeshKit.xf(Vector3(mid.x, 1.5 + mid.y - 0.3, -2.33), Vector3(0, 0, ang)))
	# desks with monitors where agents' jobs get checked
	for i in 2:
		var x := -1.4 + i * 2.8
		k.rbox(Vector3(1.2, 0.08, 0.6), 0.03, Color(0.94, 0.95, 0.96), MeshKit.at(x, 0.76, 0.3))
		k.rbox(Vector3(1.1, 0.7, 0.05), 0.02, Pal.STEEL_DARK, MeshKit.at(x, 0.4, 0.05))
		k.rbox(Vector3(0.5, 0.32, 0.03), 0.02, Color(0.14, 0.15, 0.18), MeshKit.xf(Vector3(x, 1.0, 0.15), Vector3(-10, 0, 0)))
		k.rbox(Vector3(0.44, 0.26, 0.02), 0.02, lit(Color(0.5, 0.9, 1.0)), MeshKit.xf(Vector3(x, 1.0, 0.17), Vector3(-10, 0, 0)))
	# a robot dock: charging pads the agents' robots come back to
	for i in 3:
		k.cyl(0.32, 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(-1.2 + i * 1.2, 0.12, 2.0), 16)
		k.torus(0.26, 0.015, lit(glow(t)), MeshKit.at(-1.2 + i * 1.2, 0.17, 2.0), 16, 4)
	if t >= 3:
		k.torus(0.8, 0.05, lit(glow(t)), MeshKit.xf(Vector3(0, h + 0.8, -0.8), Vector3(90, 0, 0)), 24, 5)
		k.cyl(0.04, 0.6, trim(t), MeshKit.at(0, h + 0.16, -0.8), 6)
	return k.commit()


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

static func trainer(t: int) -> Mesh:
	var k := MeshKit.new()
	floor_slab(k, 7.9, 7.9, t)
	var w := wall(t)
	var h := 3.0 + t * 0.3
	# back wall with a huge loss-curve screen
	k.rbox(Vector3(7.8, h, 0.35), 0.06, w, MeshKit.at(0, h * 0.5 + 0.12, -3.75))
	k.rbox(Vector3(8.0, 0.2, 0.55), 0.04, trim(t), MeshKit.at(0, h + 0.2, -3.75))
	k.rbox(Vector3(4.4, 2.0, 0.12), 0.06, Color(0.12, 0.13, 0.16), MeshKit.at(0.6, h * 0.55 + 0.3, -3.52))
	k.rbox(Vector3(4.2, 1.8, 0.03), 0.04, lit(Color(0.14, 0.2, 0.3), 0.75), MeshKit.at(0.6, h * 0.55 + 0.3, -3.45))
	# axes on the screen (the curve itself is drawn by TrainerB)
	k.rbox(Vector3(3.8, 0.02, 0.01), 0.004, lit(Color(0.7, 0.8, 0.9), 0.4), MeshKit.at(0.6, h * 0.55 - 0.45, -3.43))
	k.rbox(Vector3(0.02, 1.5, 0.01), 0.004, lit(Color(0.7, 0.8, 0.9), 0.4), MeshKit.at(-1.3, h * 0.55 + 0.3, -3.43))
	# side walls
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.3, h * 0.7, 3.2), 0.05, w, MeshKit.at(sx * 3.8, h * 0.35 + 0.12, -2.0))
	# raised floor tiles where the racks stand
	for i in 6:
		for j in 3:
			k.rbox(Vector3(0.96, 0.03, 0.96), 0.02, (Color(0.82, 0.84, 0.86) if (i + j) % 2 == 0 else Color(0.76, 0.78, 0.8)) if t < 4 else Color(0.2, 0.21, 0.24), MeshKit.at(-2.5 + i * 1.0, 0.14, -2.6 + j * 1.0))
	# the cluster's own rack frames (GPUs light them up: see TrainerB)
	for i in 6:
		k.rbox(Vector3(0.7, 2.0, 0.08), 0.02, Color(0.2, 0.21, 0.24), MeshKit.at(-2.5 + i * 1.0, 1.15, -1.55))
		k.rbox(Vector3(0.7, 0.08, 0.9), 0.02, trim(t), MeshKit.at(-2.5 + i * 1.0, 2.18, -1.95))
	# input pads in front (data arrives here)
	k.rbox(Vector3(5.6, 0.1, 1.2), 0.04, trim(t), MeshKit.at(-0.6, 0.35, 1.0))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.1, 0.3, 1.2), 0.02, Pal.STEEL_DARK, MeshKit.at(-0.6 + sx * 2.75, 0.15, 1.0))
	# a cooling unit and a power cabinet at the side
	k.rbox(Vector3(1.0, 1.4, 1.2), 0.06, Color(0.88, 0.9, 0.92), MeshKit.at(3.2, 0.82, 1.0))
	k.cyl(0.38, 0.04, Color(0.22, 0.23, 0.26), MeshKit.at(3.2, 1.54, 1.0), 14)
	if t >= 2:
		for i in 3:
			k.cyl(0.07, 7.0, Color(0.36, 0.6, 0.86), MeshKit.xf(Vector3(-3.5, h - 0.3 - i * 0.18, -3.4), Vector3(0, 0, -90)), 8)
	if t >= 3:
		for sx in [-1.0, 1.0]:
			k.rbox(Vector3(0.08, 0.06, 3.0), 0.02, lit(glow(t)), MeshKit.at(sx * 3.6, h * 0.7 + 0.1, -2.0))
	return k.commit()


## One GPU's light in a training rack.
static func trainer_gpu(on: bool) -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.6, 0.2, 0.7), 0.02, Color(0.16, 0.17, 0.2), MeshKit.at(0, 0, 0))
	k.rbox(Vector3(0.52, 0.03, 0.01), 0.005, lit(Color(0.5, 1.0, 0.6) if on else Color(0.3, 0.3, 0.32), 0.35 if on else 1.0), MeshKit.at(0, 0.0, 0.36))
	return k.commit()


# ---------------------------------------------------------------- Launch Complex (8 x 8 m)

static func launchpad(t: int) -> Mesh:
	var k := MeshKit.new()
	floor_slab(k, 7.9, 7.9, t)
	# the pad: a raised ring with a flame trench
	k.cyl(2.2, 0.4, Color(0.56, 0.57, 0.58) if t < 4 else Color(0.22, 0.23, 0.26), MeshKit.at(0.8, 0.12, -1.4), 28, 0.06)
	k.cyl(1.0, 0.05, Color(0.2, 0.2, 0.22), MeshKit.at(0.8, 0.52, -1.4), 20)
	for i in 8:
		var a := TAU * i / 8.0
		k.rbox(Vector3(0.12, 0.06, 0.4), 0.02, Color(0.96, 0.8, 0.26), MeshKit.xf(Vector3(0.8 + cos(a) * 1.7, 0.53, -1.4 + sin(a) * 1.7), Vector3(0, -rad_to_deg(a) + 90, 0)))
	k.rbox(Vector3(1.0, 0.3, 3.0), 0.04, Color(0.3, 0.3, 0.32), MeshKit.at(0.8, 0.15, 1.2))
	# the gantry tower beside the pad
	lattice(k, Vector3(-1.9, 0.12, -1.4), 7.0 + t * 0.6, 0.45, Color(0.86, 0.3, 0.26) if t < 3 else Color(0.84, 0.86, 0.88))
	for i in 3:
		k.rbox(Vector3(1.6, 0.1, 0.24), 0.02, Pal.STEEL_DARK, MeshKit.at(-1.1, 2.2 + i * 2.0, -1.4))
	k.sphere(0.1, lit(Color(1.0, 0.3, 0.3)), MeshKit.at(-1.9, 7.2 + t * 0.6, -1.4), 6, 4)
	# assembly bays in front: three benches (GPUs, HBM, power land here)
	for i in 3:
		var x := -2.6 + i * 1.3
		k.rbox(Vector3(1.1, 0.7, 0.8), 0.05, Color(0.3, 0.32, 0.36), MeshKit.at(x, 0.47, 2.6))
		k.rbox(Vector3(1.15, 0.05, 0.85), 0.02, [Color(0.3, 0.62, 0.42), Color(0.24, 0.36, 0.56), Color(0.46, 0.82, 0.52)][i], MeshKit.at(x, 0.83, 2.6))
	# a control bunker with windows
	k.rbox(Vector3(1.6, 1.1, 1.4), 0.1, wall(t), MeshKit.at(3.0, 0.67, 2.4))
	k.rbox(Vector3(1.2, 0.3, 0.04), 0.03, Color(0.62, 0.8, 0.9, 0.62), MeshKit.at(3.0, 0.9, 1.68))
	# fuel tanks
	for i in 2:
		k.cyl(0.42, 1.8, Color(0.94, 0.94, 0.92), MeshKit.at(3.2, 0.12, -2.8 + i * 1.0), 14, 0.06)
		k.sphere(0.42, Color(0.94, 0.94, 0.92), MeshKit.at(3.2, 1.92, -2.8 + i * 1.0), 14, 7)
	if t >= 2:
		for sx in [-1.0, 1.0]:
			k.cyl(0.05, 4.5, Pal.STEEL_DARK, MeshKit.at(0.8 + sx * 2.5, 0.12, -1.4 - sx * 1.5), 6)
			k.sphere(0.14, lit(glow(t)), MeshKit.at(0.8 + sx * 2.5, 4.7, -1.4 - sx * 1.5), 8, 5)
	return k.commit()


## The rocket that carries an orbital module (origin at its base).
static func rocket() -> Mesh:
	var k := MeshKit.new()
	var white := Color(0.96, 0.96, 0.95)
	k.cyl(0.42, 4.6, white, MeshKit.at(0, 0.0, 0), 16, 0.04)
	k.cyl(0.43, 0.4, Color(0.2, 0.21, 0.24), MeshKit.at(0, 2.2, 0), 16)
	k.lathe(PackedVector2Array([Vector2(0.44, 0.0), Vector2(0.44, 0.9), Vector2(0.3, 1.5), Vector2(0.0, 1.9)]), white, MeshKit.at(0, 4.6, 0), 16)
	k.rbox(Vector3(0.36, 0.5, 0.02), 0.04, Color(0.3, 0.66, 0.68), MeshKit.at(0, 3.3, 0.43))
	for i in 4:
		var a := TAU * i / 4.0 + PI / 4.0
		k.prism(PackedVector2Array([Vector2(0, 0), Vector2(0.6, 0), Vector2(0, 1.0)]), 0.06, Color(0.2, 0.21, 0.24), MeshKit.xf(Vector3(cos(a) * 0.4, 0.0, sin(a) * 0.4), Vector3(90, -rad_to_deg(a), 0)))
	k.cyl(0.3, 0.3, Color(0.3, 0.32, 0.36), MeshKit.at(0, -0.25, 0), 12, 0.0, 0.38)
	return k.commit()


## The flame under a launching rocket.
static func flame() -> Mesh:
	var k := MeshKit.new()
	k.cone(0.4, 1.6, Color(1.0, 0.6, 0.2, 0.3), MeshKit.xf(Vector3(0, 0.0, 0), Vector3(180, 0, 0)), 12)
	k.cone(0.22, 1.0, Color(1.0, 0.92, 0.6, 0.25), MeshKit.xf(Vector3(0, 0.0, 0), Vector3(180, 0, 0)), 10)
	return k.commit()


# ---------------------------------------------------------------- Ground Station (6 x 6 m)

static func groundstation(t: int) -> Mesh:
	var k := MeshKit.new()
	floor_slab(k, 5.9, 5.9, t)
	dish(k, Vector3(-1.2, 0.12, -1.2), 1.4 + t * 0.12, t, 50.0, 20.0)
	dish(k, Vector3(1.8, 0.12, -1.8), 0.8 + t * 0.08, t, 40.0, -30.0)
	if t >= 2:
		dish(k, Vector3(1.9, 0.12, 0.6), 0.7, t, 60.0, 10.0)
	# the control hut with a status screen
	k.rbox(Vector3(1.8, 1.4, 1.2), 0.08, wall(t), MeshKit.at(-1.5, 0.82, 1.8))
	k.rbox(Vector3(2.0, 0.12, 1.4), 0.03, trim(t), MeshKit.at(-1.5, 1.58, 1.8))
	k.rbox(Vector3(0.9, 0.5, 0.04), 0.04, Color(0.14, 0.15, 0.18), MeshKit.at(-1.5, 1.0, 2.41))
	k.rbox(Vector3(0.8, 0.4, 0.02), 0.03, lit(Color(0.5, 0.9, 1.0)), MeshKit.at(-1.5, 1.0, 2.43))
	# cable trays to the dishes
	k.rbox(Vector3(0.3, 0.08, 3.0), 0.02, Pal.STEEL_DARK, MeshKit.at(-0.3, 0.16, 0.2))
	if t >= 3:
		k.rbox(Vector3(0.2, 0.03, 2.8), 0.01, lit(glow(t)), MeshKit.at(-0.3, 0.21, 0.2))
	return k.commit()


# ---------------------------------------------------------------- the orbital datacenter

## The station's spine: a long truss with a docking hub (modules attach
## along it, see orbit_module).
static func orbit_spine(n: int) -> Mesh:
	var k := MeshKit.new()
	var len := maxf(4.0, n * 1.6 + 2.0)
	k.rbox(Vector3(len, 0.3, 0.3), 0.04, Color(0.84, 0.86, 0.88), MeshKit.at(0, 0, 0))
	for i in int(len / 0.5):
		k.rbox(Vector3(0.03, 0.42, 0.42), 0.005, Color(0.6, 0.62, 0.66), MeshKit.at(-len * 0.5 + i * 0.5, 0, 0))
	k.cyl(0.6, 1.0, Color(0.94, 0.94, 0.92), MeshKit.xf(Vector3(0, -0.5, 0), Vector3.ZERO), 16, 0.08)
	k.torus(0.9, 0.06, lit(Color(0.5, 0.9, 1.0)), MeshKit.at(0, 0, 0), 24, 5)
	return k.commit()


## One orbital server module: a pressurised can of racks with solar wings
## and a radiator.
static func orbit_module() -> Mesh:
	var k := MeshKit.new()
	k.cyl(0.45, 1.3, Color(0.95, 0.95, 0.94), MeshKit.xf(Vector3(0, -0.65, 0), Vector3.ZERO), 14, 0.06)
	k.cyl(0.46, 0.08, Pal.BRASS, MeshKit.at(0, -0.1, 0), 14)
	for i in 4:
		k.rbox(Vector3(0.1, 0.04, 0.02), 0.005, lit(Color(0.5, 1.0, 0.6)), MeshKit.at(-0.15 + i * 0.1, 0.2, 0.46))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(0.05, 0.05, 1.4), 0.01, Color(0.6, 0.62, 0.66), MeshKit.at(0, 0.3, sz * 0.9))
		k.rbox(Vector3(1.1, 0.03, 1.4), 0.01, Color(0.18, 0.26, 0.48), MeshKit.at(0, 0.3, sz * 1.7))
		for i in 4:
			k.rbox(Vector3(1.12, 0.035, 0.02), 0.005, Color(0.84, 0.86, 0.88), MeshKit.at(0, 0.3, sz * (1.05 + i * 0.4)))
	k.rbox(Vector3(0.9, 0.02, 0.5), 0.01, Color(0.96, 0.96, 0.94), MeshKit.at(0, -0.5, 0.0))
	return k.commit()
