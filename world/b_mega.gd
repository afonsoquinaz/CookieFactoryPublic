class_name MegaB
extends Building
## The AGI Megacluster: the crown of the empire and the goal of the game.
## It rises in five stages. Each stage needs Frontier 1T tokens served to
## customers since the last stage (anywhere: API, café, contracts, agents,
## orbit) and a payment from the info panel. Finishing The Core wins the game.

var _label: Label3D
var _sparkle_t := 0.0


func _build() -> void:
	_label = UI3D.label("", 34, Color(0.6, 0.95, 1.0))
	_label.position = Vector3(0, 9.0, 0)
	add_child(_label)
	if not data.has("base"):
		data["base"] = float(Game.stats.get("frontier", 0.0))
	_update()


func stage() -> int:
	return int(data.get("stage", 0))


## Frontier tokens (K) served since this stage was finished.
func delivered() -> float:
	return maxf(0.0, float(Game.stats.get("frontier", 0.0)) - float(data.get("base", 0.0)))


## Frontier tokens needed to unlock the next stage.
func needed() -> float:
	var s := stage() + 1
	return float(Defs.MEGA_STAGES[s]["need"]) if s < Defs.MEGA_STAGES.size() else 0.0


func next_cost() -> float:
	var s := stage() + 1
	return float(Defs.MEGA_STAGES[s]["cost"]) if s < Defs.MEGA_STAGES.size() else 0.0


func complete() -> bool:
	return stage() >= Defs.MEGA_STAGES.size() - 1


func next_time() -> float:
	var s := stage() + 1
	return float(Defs.MEGA_STAGES[s]["time"]) * Bal.tool_mult() if s < Defs.MEGA_STAGES.size() else 0.0


func building_stage() -> bool:
	return not Game.job_of(uid).is_empty()


## Why the next stage can't start ("" when it can).
func advance_block() -> String:
	if complete():
		return "Complete"
	if building_stage():
		return "Builders are on it"
	if delivered() < needed():
		return "Serve %s more %s tokens" % [Fmt.tokens(needed() - delivered()), Defs.model_name(Defs.MEGA_MODEL)]
	if not Game.can_afford(next_cost()):
		return "Not enough money"
	if Game.free_builders() <= 0:
		return "All builders are busy"
	return ""


func can_advance() -> bool:
	return advance_block() == ""


## Starts building the next stage: money now, a builder for a while.
func advance() -> bool:
	if not can_advance():
		return false
	if not Game.start_stage(uid, next_cost(), next_time()):
		return false
	# the next stage counts what's served from now on
	data["base"] = float(Game.stats.get("frontier", 0.0))
	return true


func refresh() -> void:
	level = int(data["lvl"])
	var t := stage()
	if t != tier:
		var first := tier < 0
		tier = t
		if visual:
			visual.queue_free()
		visual = Node3D.new()
		add_child(visual)
		_visual(visual, tier)
		if not first:
			celebrate()
	_update()
	changed.emit()


func _update() -> void:
	if _label == null:
		return
	# above the cranes and stacks; above the Core's beam once it stands
	_label.position.y = 20.0 if stage() >= 4 else 9.0
	if complete():
		_label.text = "Complete!"
	else:
		_label.text = "%s  ·  Frontier %s / %s" % [Defs.MEGA_STAGES[stage() + 1]["name"], Fmt.tokens(minf(delivered(), needed())), Fmt.tokens(needed())]


func solid_rects() -> Array[Rect2]:
	return [Rect2(-5.0, -5.0, 10.0, 8.6)]


func _process(dt: float) -> void:
	super(dt)
	if int(_t) != int(_t - dt):
		_update()
	_sparkle_t -= dt
	if _sparkle_t <= 0.0 and stage() >= 3:
		_sparkle_t = 0.8
		Fx.puff(get_tree().current_scene, to_world(randf_range(-3, 3), randf_range(-3, 1), randf_range(4, 7)), Color(0.6, 0.95, 1.0), 2)


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("mega_%d" % t, func(): return MegaB.mesh(t)), root)


func status() -> String:
	if complete():
		return "Your megacluster is online. Welcome to the future."
	return "Next: %s. Serve %s %s tokens, then pay $%s." % [Defs.MEGA_STAGES[stage() + 1]["name"], Fmt.tokens(needed()), Defs.model_name(Defs.MEGA_MODEL), Fmt.num(next_cost())]


func info() -> Array:
	var out := [["mega", "Stage %d of %d: %s" % [stage() + 1, Defs.MEGA_STAGES.size(), Defs.MEGA_STAGES[stage()]["name"]]]]
	if not complete():
		out.append(["tk_" + Defs.MEGA_MODEL, "%s tokens served %s / %s" % [Defs.model_name(Defs.MEGA_MODEL), Fmt.tokens(minf(delivered(), needed())), Fmt.tokens(needed())]])
		out.append(["coin", "Then $%s" % Fmt.num(next_cost())])
	return out


## The megacluster site by stage. The site has zones that fill in stage by
## stage: the power plant along the back (1), cooling towers and halls on
## the sides (2), GPU halls at the front corners (3) and the Core in the
## middle (4). What isn't built yet is a construction site: cranes, a pit,
## rebar, steel frames, trucks, site offices. The final stage re-skins the
## campus in graphite and brass and crowns it with the glowing Core.
static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var y0 := _ground(k, t)
	if t >= 1:
		_power(k, t, y0)
	if t >= 2:
		for sx in [-1.0, 1.0]:
			_cooling(k, t, y0, sx)
	if t >= 3:
		for sx in [-1.0, 1.0]:
			_gpu_hall(k, t, y0, sx)
	_core(k, t, y0)
	if t < 4:
		_works(k, t, y0)
	else:
		_finale(k, y0)
	return k.commit()


static func _bx(k: MeshKit, size: Vector3, col: Color, x: float, y: float, z: float) -> void:
	k.box(size, col, MeshKit.at(x, y, z))


static func _wall(t: int) -> Color:
	return Color(0.86, 0.87, 0.88) if t < 4 else Color(0.19, 0.2, 0.23)


static func _trim(t: int) -> Color:
	return Color(0.36, 0.38, 0.42) if t < 4 else Pal.BRASS


static func _glow(t: int) -> Color:
	return Color(0.45, 0.75, 1.0, 0.45) if t < 4 else Color(1.0, 0.86, 0.5, 0.4)


# ---------------------------------------------------------------- ground

## Dirt and gravel (0), then a concrete plinth with steps that the campus
## sits on, dark tiles with glowing traces at the end. Returns its top.
static func _ground(k: MeshKit, t: int) -> float:
	var r := RandomNumberGenerator.new()
	r.seed = 5150
	if t == 0:
		_bx(k, Vector3(9.8, 0.02, 9.8), Color(0.6, 0.5, 0.38), 0, 0.01, 0)
		for i in 40:
			k.box(Vector3(r.randf_range(0.3, 1.0), 0.01, r.randf_range(0.2, 0.7)), Color(0.52, 0.43, 0.32) if i % 3 else Color(0.7, 0.66, 0.58), MeshKit.xf(Vector3(r.randf_range(-4.6, 4.6), 0.022, r.randf_range(-4.6, 4.6)), Vector3(0, r.randf_range(0, 180), 0)))
		# tyre tracks curving in from the gate
		for i in 14:
			var a := float(i) / 13.0
			var p := Vector3(lerpf(0.6, -0.4, a) + sin(a * 3.0) * 0.6, 0.025, lerpf(4.8, -0.5, a))
			for sx in [-0.35, 0.35]:
				k.box(Vector3(0.14, 0.01, 0.45), Color(0.46, 0.37, 0.27), MeshKit.xf(p + Vector3(sx, 0, 0), Vector3(0, cos(a * 3.0) * 25.0, 0)))
		for i in 4:
			k.cyl(r.randf_range(0.2, 0.4), 0.012, Color(0.46, 0.52, 0.56), MeshKit.xf(Vector3(r.randf_range(-3, 3), 0.02, r.randf_range(-1, 4)), Vector3.ZERO, Vector3(1.5, 1, 1)), 10)
		return 0.02
	var y0 := 0.25
	var top: Color = Color(0.72, 0.72, 0.7) if t < 4 else Color(0.2, 0.21, 0.24)
	_bx(k, Vector3(9.8, 0.02, 9.8), Color(0.56, 0.54, 0.5) if t < 4 else Color(0.16, 0.17, 0.2), 0, 0.01, 0)
	_bx(k, Vector3(9.7, y0, 8.4), top, 0, y0 * 0.5, -0.7)
	_bx(k, Vector3(9.74, 0.05, 8.44), _trim(t), 0, y0 - 0.02, -0.7)
	# joints / glowing traces
	if t < 4:
		for i in 9:
			_bx(k, Vector3(0.02, 0.005, 8.4), Color(0.62, 0.62, 0.6), -4.0 + i * 1.0, y0 + 0.003, -0.7)
		for j in 8:
			_bx(k, Vector3(9.7, 0.005, 0.02), Color(0.62, 0.62, 0.6), 0, y0 + 0.003, -4.4 + j * 1.0)
	else:
		for i in 16:
			var a := TAU * i / 16.0
			var d := Vector3(cos(a), 0, sin(a))
			var l := 3.2 + (i % 3) * 0.6
			TownArt.beam(k, Vector3(0, y0 + 0.006, -0.2) + d * 2.6, Vector3(0, y0 + 0.006, -0.2) + d * minf(l + 2.6, 4.6), 0.03, Color(0.42, 0.9, 1.0, 0.5), 0.01)
			var e := Vector3(0, y0 + 0.006, -0.2) + d * minf(l + 2.6, 4.6)
			k.cyl(0.06, 0.012, Color(0.42, 0.9, 1.0, 0.5), MeshKit.at(e.x, y0, clampf(e.z, -4.8, 3.3)), 6)
	# steps up from the front apron
	for i in 3:
		_bx(k, Vector3(3.6 - i * 0.3, 0.085, 0.3), top.lightened(0.05), 0, 0.04 + i * 0.085, 3.85 - i * 0.22)
	_bx(k, Vector3(9.7, 0.02, 0.03), _glow(t), 0, y0, 3.5)
	# the apron in front
	_bx(k, Vector3(9.8, 0.02, 1.3), Color(0.66, 0.66, 0.64) if t < 4 else Color(0.22, 0.23, 0.27), 0, 0.02, 4.2)
	return y0


# ---------------------------------------------------------------- 1 power

## Along the back: a turbine hall, three heat-recovery boilers with tall
## stacks, and a switchyard of transformers, gantries and a pylon.
static func _power(k: MeshKit, t: int, y0: float) -> void:
	var wall := _wall(t)
	var trim := _trim(t)
	var glow := _glow(t)
	var dark := Color(0.2, 0.21, 0.24)
	# the turbine hall
	var x0 := -4.75
	var x1 := 0.55
	var z0 := -3.95
	var z1 := -2.75
	var h := 2.6
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	_bx(k, Vector3(x1 - x0, h, z1 - z0), wall, cx, y0 + h * 0.5, cz)
	for i in int((x1 - x0) / 0.25):
		_bx(k, Vector3(0.05, h - 0.2, 0.03), wall.darkened(0.08), x0 + 0.12 + i * 0.25, y0 + h * 0.5, z1 + 0.012)
	_bx(k, Vector3(x1 - x0, 0.4, 0.04), Color(0.42, 0.62, 0.82, 0.62) if t < 4 else Color(0.32, 0.5, 0.7, 0.55), cx, y0 + 2.0, z1 + 0.03)
	for i in 14:
		_bx(k, Vector3(0.04, 0.42, 0.05), trim, x0 + 0.3 + i * 0.36, y0 + 2.0, z1 + 0.05)
	_bx(k, Vector3(x1 - x0 + 0.1, 0.14, z1 - z0 + 0.1), trim, cx, y0 + h + 0.07, cz)
	for dx in [-3.6, -1.6]:
		ArchKit.rollup(k, MeshKit.at(dx, y0, z1 + 0.01), 1.1, 1.5, Color(0.56, 0.6, 0.66) if t < 4 else Color(0.3, 0.31, 0.35))
	ArchKit.door(k, MeshKit.at(-0.2, y0, z1 + 0.01), 3, 0.6, 1.4)
	for lx in [-4.4, -2.6, -0.65]:
		ArchKit.louvres(k, MeshKit.at(lx, y0 + 0.4, z1 + 0.02), 0.5, 0.6, wall.darkened(0.1), 5)
	TownArt.word(k, MeshKit.at(-2.6, y0 + 2.3, z1 + 0.05), "POWER", 0.32, glow if t >= 3 else Color(0.2, 0.3, 0.5), 0.14, 0.03)
	# a monitor roof with louvres
	_bx(k, Vector3(4.8, 0.55, 0.6), wall.darkened(0.04), cx, y0 + h + 0.4, cz - 0.15)
	for sz in [-1.0, 1.0]:
		ArchKit.louvres(k, MeshKit.xf(Vector3(cx, y0 + h + 0.18, cz - 0.15 + sz * 0.3), Vector3(0, 0 if sz > 0 else 180, 0)), 4.6, 0.4, wall.darkened(0.15), 4)
	_bx(k, Vector3(4.9, 0.06, 0.7), trim, cx, y0 + h + 0.7, cz - 0.15)
	# three heat-recovery boilers with stacks behind the hall
	for i in 3:
		var bx := -3.9 + i * 1.6
		var bz := -4.4
		_bx(k, Vector3(1.0, 3.5, 0.8), wall.darkened(0.06), bx, y0 + 1.75, bz)
		for j in 5:
			_bx(k, Vector3(1.04, 0.06, 0.84), trim, bx, y0 + 0.5 + j * 0.7, bz)
		_bx(k, Vector3(0.6, 0.5, 0.4), wall.darkened(0.1), bx, y0 + 2.9, bz + 0.55)
		var sh := 6.0 + (i % 2) * 0.8
		var sc: Color = Color(0.82, 0.82, 0.8) if t < 4 else Color(0.22, 0.23, 0.27)
		k.cyl(0.3, 0.3, trim, MeshKit.at(bx, y0 + 3.5, bz), 8)
		k.cyl(0.26, sh, sc, MeshKit.at(bx, y0 + 3.8, bz), 8, 0.0, 0.22)
		var top := y0 + 3.8 + sh
		if t < 4:
			k.cyl(0.235, 0.4, Color(0.8, 0.3, 0.26), MeshKit.at(bx, top - 0.9, bz), 8, 0.0, -1.0, false)
			k.cyl(0.228, 0.4, Color(0.8, 0.3, 0.26), MeshKit.at(bx, top - 0.4, bz), 8, 0.0, -1.0, false)
		else:
			k.cyl(0.24, 0.06, glow, MeshKit.at(bx, top - 0.8, bz), 8)
			k.cyl(0.235, 0.06, glow, MeshKit.at(bx, top - 0.4, bz), 8)
		k.torus(0.42, 0.025, trim, MeshKit.at(bx, y0 + 3.8 + sh * 0.62, bz), 10, 3)
		k.cyl(0.42, 0.03, trim.darkened(0.2), MeshKit.at(bx, y0 + 3.75 + sh * 0.62, bz), 10)
		for j in int(sh / 0.5):
			_bx(k, Vector3(0.18, 0.02, 0.02), trim, bx, y0 + 3.9 + j * 0.5, bz + 0.27)
		ArchKit.beacon(k, Vector3(bx, top, bz), 0.2)
	# pipes between the boilers and the hall
	ArchKit.pipes(k, [Vector3(-4.6, y0 + 2.9, -3.9), Vector3(-4.6, y0 + 2.9, -4.85), Vector3(0.4, y0 + 2.9, -4.85)], 0.08, Color(0.86, 0.86, 0.84) if t < 4 else Color(0.42, 0.9, 1.0, 0.4))
	# ---- the switchyard on the right
	var yx0 := 1.0
	var yx1 := 4.8
	_bx(k, Vector3(yx1 - yx0, 0.02, 2.1), Color(0.5, 0.5, 0.48) if t < 4 else Color(0.14, 0.15, 0.17), (yx0 + yx1) * 0.5, y0 + 0.01, -3.8)
	ArchKit.fence(k, Vector3(yx0, y0, -2.75), Vector3(yx1, y0, -2.75), 1 if t < 4 else 4, 1.0)
	ArchKit.fence(k, Vector3(yx0, y0, -2.75), Vector3(yx0, y0, -4.85), 1 if t < 4 else 4, 1.0)
	for i in 3:
		var tx := 1.6 + i * 1.2
		ArchKit.transformer(k, MeshKit.at(tx, y0, -3.35), 3 if t < 4 else 4)
		# bushings up to the gantry
		for j in 3:
			TownArt.beam(k, Vector3(tx - 0.25 + j * 0.25, y0 + 1.5, -3.35), Vector3(tx - 0.25 + j * 0.25, y0 + 3.0, -4.15), 0.012, dark)
	# a gantry across the back with insulators
	for gx in [1.2, 4.6]:
		TownArt.lattice(k, Vector3(gx, y0, -4.15), Vector3(gx, y0 + 3.2, -4.15), 0.26, trim)
	TownArt.lattice(k, Vector3(1.2, y0 + 3.1, -4.15), Vector3(4.6, y0 + 3.1, -4.15), 0.22, trim)
	for i in 9:
		k.cyl(0.035, 0.3, Color(0.86, 0.6, 0.4) if t < 4 else Pal.BRASS, MeshKit.at(1.45 + i * 0.37, y0 + 2.7, -4.15), 5)
	# the pylon in the back corner, wires to the gantry
	_pylon(k, Vector3(3.2, y0, -4.62), 7.2, trim)
	for j in 3:
		var arm_y := y0 + 7.2 * (0.62 + j * 0.13)
		for sx in [-1.0, 1.0]:
			var w := 0.85 - j * 0.15
			TownArt.beam(k, Vector3(3.2 + sx * w, arm_y - 0.3, -4.62), Vector3(2.0 + sx * 1.3 + j * 0.5, y0 + 3.0, -4.15), 0.012, dark)
	# a cable trench toward the middle
	ArchKit.cable_tray(k, Vector3(1.0, y0 + 0.05, -2.6), Vector3(0.0, y0 + 0.05, -2.6), 3 if t < 4 else 4)


## A tapered lattice transmission pylon with three cross-arms.
static func _pylon(k: MeshKit, base: Vector3, h: float, col: Color) -> void:
	var b := 0.45
	var tp := 0.15
	var legs := [Vector3(-1, 0, -1), Vector3(1, 0, -1), Vector3(1, 0, 1), Vector3(-1, 0, 1)]
	for l in legs:
		TownArt.beam(k, base + l * b, base + l * tp + Vector3(0, h, 0), 0.05, col)
	var n := 7
	for i in n:
		var f0 := float(i) / n
		var f1 := float(i + 1) / n
		var w0 := lerpf(b, tp, f0)
		var w1 := lerpf(b, tp, f1)
		for s in 4:
			var c0: Vector3 = legs[s]
			var c1: Vector3 = legs[(s + 1) % 4]
			var p0 := base + c0 * w0 + Vector3(0, h * f0, 0)
			var p1 := base + c1 * w1 + Vector3(0, h * f1, 0)
			var p2 := base + c1 * w0 + Vector3(0, h * f0, 0)
			var p3 := base + c0 * w1 + Vector3(0, h * f1, 0)
			if s % 2 == 0:
				TownArt.beam(k, p0, p1, 0.025, col)
				TownArt.beam(k, p2, p3, 0.025, col)
			TownArt.beam(k, p0, p2, 0.025, col)
	for j in 3:
		var y := h * (0.62 + j * 0.13)
		var w := 0.85 - j * 0.15
		TownArt.beam(k, base + Vector3(-w, y, 0), base + Vector3(w, y, 0), 0.06, col)
		for sx in [-1.0, 1.0]:
			k.cyl(0.03, 0.3, Color(0.86, 0.6, 0.4), MeshKit.at(base.x + sx * w, base.y + y - 0.3, base.z), 5)
	ArchKit.beacon(k, base + Vector3(0, h, 0), 0.3)


# ---------------------------------------------------------------- 2 cooling

## A side's cooling: a hyperbolic tower with a plume, a cooling hall with
## chillers, pumps, a tank and pipes toward the middle.
static func _cooling(k: MeshKit, t: int, y0: float, sx: float) -> void:
	var wall := _wall(t)
	var trim := _trim(t)
	var glow := _glow(t)
	var tc := Vector3(sx * 3.75, y0, -1.5)
	var tw: Color = Color(0.88, 0.88, 0.86) if t < 4 else Color(0.24, 0.25, 0.29)
	var r := 1.05
	var hh := 5.0
	k.lathe(PackedVector2Array([Vector2(r, 0.5), Vector2(r * 0.86, hh * 0.38), Vector2(r * 0.68, hh * 0.72), Vector2(r * 0.74, hh), Vector2(r * 0.66, hh), Vector2(r * 0.6, hh * 0.75), Vector2(r * 0.8, hh * 0.4), Vector2(r * 0.92, 0.5)]), tw, MeshKit.at(tc.x, tc.y, tc.z), 14)
	k.cyl(r * 0.92, 0.1, Color(0.3, 0.42, 0.5), MeshKit.at(tc.x, tc.y + 0.02, tc.z), 14)
	for i in 10:
		var a := TAU * i / 10.0
		TownArt.beam(k, Vector3(tc.x + cos(a) * r * 0.96, tc.y, tc.z + sin(a) * r * 0.96), Vector3(tc.x + cos(a + 0.3) * r * 0.98, tc.y + 0.52, tc.z + sin(a + 0.3) * r * 0.98), 0.07, tw.darkened(0.25))
	# bands, a ladder, the rim
	for j in 3:
		var f := 0.3 + j * 0.25
		var rr := r * (0.86 - (0.86 - 0.68) * (f - 0.38) / 0.34) if f > 0.38 else r * (1.0 - 0.14 * f / 0.38)
		k.torus(rr + 0.01, 0.025, tw.darkened(0.12), MeshKit.at(tc.x, tc.y + hh * f, tc.z), 14, 3)
	k.torus(r * 0.74, 0.04, trim, MeshKit.at(tc.x, tc.y + hh, tc.z), 14, 3)
	if t >= 3:
		k.torus(r * 0.76, 0.035, glow, MeshKit.at(tc.x, tc.y + hh - 0.15, tc.z), 14, 3)
	# the plume
	for i in 4:
		k.ellipsoid(Vector3(0.7 + i * 0.12, 0.42, 0.6 + i * 0.12), Color(0.97, 0.97, 0.97).darkened(0.02 * i), MeshKit.at(tc.x + sx * i * 0.18, tc.y + hh + 0.35 + i * 0.5, tc.z - i * 0.1), 9, 5)
	# the cooling hall in front of the tower
	var hc := Vector3(sx * 3.7, y0, 0.32)
	var hw := 2.2
	var hd := 1.2
	var hhh := 1.5
	_bx(k, Vector3(hw, hhh, hd), wall, hc.x, y0 + hhh * 0.5, hc.z)
	for i in 8:
		_bx(k, Vector3(0.05, hhh - 0.15, 0.03), wall.darkened(0.08), hc.x - hw * 0.5 + 0.15 + i * 0.27, y0 + hhh * 0.5, hc.z + hd * 0.5 + 0.012)
	ArchKit.louvres(k, MeshKit.at(hc.x - sx * 0.4, y0 + 0.3, hc.z + hd * 0.5 + 0.01), 0.9, 0.8, wall.darkened(0.12), 6)
	ArchKit.door(k, MeshKit.at(hc.x + sx * 0.6, y0, hc.z + hd * 0.5 + 0.01), 3, 0.5, 1.15)
	ArchKit.parapet(k, Vector3(hc.x, y0 + hhh, hc.z), hw, hd, 3)
	ArchKit.chiller(k, MeshKit.at(hc.x, y0 + hhh, hc.z - 0.2), 1.9, 3 if t < 4 else 4, 2)
	ArchKit.cable_tray(k, Vector3(hc.x - hw * 0.45, y0 + hhh + 0.05, hc.z + 0.42), Vector3(hc.x + hw * 0.45, y0 + hhh + 0.05, hc.z + 0.42), 3 if t < 4 else 4)
	# pipes: hall to the tower basin, and a rack toward the middle
	var pc: Color = Color(0.36, 0.6, 0.86) if t < 4 else Color(0.42, 0.9, 1.0, 0.4)
	for j in 2:
		var px := hc.x - sx * (0.5 + j * 0.3)
		ArchKit.pipes(k, [Vector3(px, y0 + 0.4, hc.z - hd * 0.5), Vector3(px, y0 + 0.4, tc.z + r * 0.6)], 0.07, pc if j == 0 else Color(0.86, 0.86, 0.84))
	ArchKit.pipe_rack(k, MeshKit.xf(Vector3(sx * 2.25, y0, -1.2), Vector3(0, 90, 0)), 2.6, 1.6, 3 if t < 4 else 4, 3)
	# pumps and a tank
	for i in 2:
		var pp := Vector3(sx * (2.85 + i * 0.4), y0, 1.0)
		_bx(k, Vector3(0.3, 0.22, 0.4), Color(0.3, 0.32, 0.36), pp.x, y0 + 0.11, pp.z)
		k.cyl(0.1, 0.32, pc, MeshKit.xf(Vector3(pp.x, y0 + 0.3, pp.z - 0.15), Vector3(90, 0, 0)), 8)
	ArchKit.tank(k, MeshKit.at(sx * 2.85, y0, -0.25), 0.3, 1.3, Color(0.86, 0.87, 0.88) if t < 4 else Color(0.24, 0.25, 0.29), t)


# ---------------------------------------------------------------- 3 gpu halls

## A GPU hall at a front corner: a dark hall whose front is a wall of
## glowing racks, chillers and fans on the roof, a glass side with a sign.
static func _gpu_hall(k: MeshKit, t: int, y0: float, sx: float) -> void:
	var body: Color = Color(0.3, 0.33, 0.38) if t < 4 else Color(0.17, 0.18, 0.21)
	var trim := _trim(t)
	var x0 := sx * 1.95
	var x1 := sx * 4.8
	var cx := (x0 + x1) * 0.5
	var w := absf(x1 - x0)
	var z0 := 1.1
	var z1 := 3.4
	var cz := (z0 + z1) * 0.5
	var h := 2.5
	_bx(k, Vector3(w, h, z1 - z0), body, cx, y0 + h * 0.5, cz)
	# the rack wall on the front
	var cols := 8
	var rows := 2
	var rw := (w - 0.3) / cols
	_bx(k, Vector3(w - 0.2, h - 0.5, 0.04), Color(0.08, 0.09, 0.11), cx, y0 + h * 0.5, z1 + 0.02)
	for i in cols:
		for j in rows:
			var rx := cx - (w - 0.3) * 0.5 + (i + 0.5) * rw
			var ry := y0 + 0.4 + j * 0.92 + 0.42
			_bx(k, Vector3(rw - 0.06, 0.84, 0.03), Color(0.14, 0.15, 0.18), rx, ry, z1 + 0.05)
			for l in 4:
				var lc: Color = [Color(0.45, 0.75, 1.0, 0.4), Color(0.5, 1.0, 0.7, 0.4), Color(0.45, 0.75, 1.0, 0.4), Color(1.0, 0.86, 0.5, 0.4)][(i + j + l) % 4]
				_bx(k, Vector3(rw - 0.16, 0.025, 0.02), lc, rx, ry - 0.3 + l * 0.19, z1 + 0.07)
	for i in cols + 1:
		_bx(k, Vector3(0.05, h - 0.4, 0.08), trim, cx - (w - 0.3) * 0.5 + i * rw, y0 + h * 0.5, z1 + 0.05)
	_bx(k, Vector3(w, 0.06, 0.08), _glow(t), cx, y0 + h - 0.15, z1 + 0.06)
	# the glass side toward the middle with a sign and a door
	var face := MeshKit.xf(Vector3(x0, y0, cz), Vector3(0, -90.0 * sx, 0))
	ArchKit.curtain(k, face * MeshKit.at(0, 0.3, 0.01), z1 - z0 - 0.4, h - 0.6, 3 if t < 4 else 4, 4, 2)
	TownArt.word(k, face * MeshKit.at(0, h - 0.25, 0.04), "GPU", 0.2, _glow(t), 0.16, 0.03)
	# roof: two chillers, exhaust fans, a glowing skylight
	ArchKit.parapet(k, Vector3(cx, y0 + h, cz), w, z1 - z0, 3 if t < 4 else 4)
	for j in 2:
		ArchKit.chiller(k, MeshKit.at(cx, y0 + h, z0 + 0.7 + j * 1.1), w - 0.7, 3 if t < 4 else 4, 3)
	_bx(k, Vector3(w - 0.4, 0.04, 0.16), Color(0.45, 0.75, 1.0, 0.4), cx, y0 + h + 0.04, cz)
	# a generator and a transformer on the outer end
	ArchKit.louvres(k, MeshKit.xf(Vector3(x1, y0 + 0.4, cz), Vector3(0, 90.0 * sx, 0)), 1.6, 1.4, body.lightened(0.1), 8)
	# cable trays from the hall to the middle
	ArchKit.cable_tray(k, Vector3(x0, y0 + h - 0.2, z0 + 0.4), Vector3(sx * 1.4, y0 + h - 0.2, z0 + 0.4), 3 if t < 4 else 4)


# ---------------------------------------------------------------- the core

## The middle: a pit with piling (0), the poured foundation with starter
## bars (1), the first podium level in scaffolding (2), the podium and the
## core shaft rising under a climbing crane (3), the finished Core (4).
static func _core(k: MeshKit, t: int, y0: float) -> void:
	var cz := -0.2
	var concrete := Color(0.72, 0.72, 0.7)
	var rebar := Color(0.5, 0.32, 0.26)
	var ply := Color(0.78, 0.64, 0.44)
	match t:
		0:
			# the pit: sheet piles around a dark floor, pile caps, rebar cages
			_bx(k, Vector3(4.4, 0.02, 4.4), Color(0.44, 0.35, 0.27), 0, 0.03, cz)
			for sd in [-1.0, 1.0]:
				ArchKit.corrugated(k, MeshKit.xf(Vector3(0, 0, cz + sd * 2.2), Vector3(0, 0 if sd > 0 else 180, 0)), 4.4, 0.4, Color(0.42, 0.44, 0.48), 0.14)
				ArchKit.corrugated(k, MeshKit.xf(Vector3(sd * 2.2, 0, cz), Vector3(0, 90 * sd, 0)), 4.4, 0.4, Color(0.42, 0.44, 0.48), 0.14)
			for i in 4:
				for j in 4:
					var p := Vector3(-1.5 + i * 1.0, 0, cz - 1.5 + j * 1.0)
					k.cyl(0.2, 0.18, concrete, MeshKit.at(p.x, 0.03, p.z), 8)
					for b in 4:
						var a := TAU * b / 4.0 + 0.4
						_bx(k, Vector3(0.025, 0.4, 0.025), rebar, p.x + cos(a) * 0.12, 0.35, p.z + sin(a) * 0.12)
			for i in 3:
				TownArt.lattice(k, Vector3(-1.6 + i * 0.5, 0.15, 1.3), Vector3(-1.6 + i * 0.5, 0.15, -0.3), 0.3, rebar)
			# a piling rig with its tall mast
			_piling_rig(k, MeshKit.xf(Vector3(1.0, 0.03, -1.0), Vector3(0, -30, 0)))
			_excavator(k, MeshKit.xf(Vector3(-0.6, 0.03, -1.5), Vector3(0, 40, 0)), Color(0.96, 0.74, 0.2))
		1:
			# the foundation slab, starter bars, formwork at the edges
			_bx(k, Vector3(4.4, 0.25, 4.4), concrete.darkened(0.05), 0, y0 + 0.12, cz)
			for i in 9:
				for sd in [-1.0, 1.0]:
					_bx(k, Vector3(0.025, 0.7, 0.025), rebar, -2.0 + i * 0.5, y0 + 0.6, cz + sd * 2.0)
					_bx(k, Vector3(0.025, 0.7, 0.025), rebar, sd * 2.0, y0 + 0.6, cz - 2.0 + i * 0.5)
			for i in 5:
				for j in 5:
					_bx(k, Vector3(0.025, 1.0, 0.025), rebar, -1.0 + i * 0.5, y0 + 0.75, cz - 1.0 + j * 0.5)
			for sd in [-1.0, 1.0]:
				_bx(k, Vector3(4.6, 0.5, 0.06), ply, 0, y0 + 0.5, cz + sd * 2.25)
			for i in 6:
				_bx(k, Vector3(0.04, 0.6, 0.3), ply.darkened(0.15), -2.0 + i * 0.8, y0 + 0.5, cz + 2.4)
			_rebar_mat(k, Rect2(-1.8, cz - 1.8, 1.6, 1.4), y0 + 0.27)
		2:
			_podium(k, 1, y0, concrete)
			for i in 5:
				for j in 5:
					_bx(k, Vector3(0.03, 0.9, 0.03), rebar, -1.2 + i * 0.6, y0 + 1.6, cz - 1.2 + j * 0.6)
			_scaffold_ring(k, Rect2(-2.35, cz - 2.35, 4.7, 4.7), y0, 2.0)
			ArchKit.clutter(k, Vector3(0.9, y0 + 1.2, cz - 0.8), 1, 4)
			TownArt.pallet(k, MeshKit.at(-0.8, y0 + 1.2, cz + 0.9), "blocks")
		3:
			_podium(k, 2, y0, concrete)
			var sy := y0 + 2.2
			var sh := 4.6
			k.cyl(0.95, sh, concrete, MeshKit.at(0, sy, cz), 12)
			for i in 12:
				var a := TAU * i / 12.0
				_bx(k, Vector3(0.03, 0.8, 0.03), rebar, cos(a) * 0.85, sy + sh + 0.4, cz + sin(a) * 0.85)
			# scaffold wrap around the shaft
			for j in 5:
				k.torus(1.25, 0.03, Color(0.66, 0.66, 0.64), MeshKit.at(0, sy + 0.9 + j * 0.9, cz), 14, 3)
				k.cyl(1.25, 0.04, ply, MeshKit.at(0, sy + 0.88 + j * 0.9, cz), 12, 0.0, -1.0, true)
			for i in 10:
				var a2 := TAU * i / 10.0
				k.cyl(0.025, sh + 0.4, Color(0.66, 0.66, 0.64), MeshKit.at(cos(a2) * 1.28, sy, cz + sin(a2) * 1.28), 4)
			# the climbing crane on top of the shaft and a hoist tower
			TownArt.tower_crane(k, MeshKit.xf(Vector3(0, sy + sh, cz), Vector3(0, 35, 0)), 3.2, 5.2, 1.5, Color(0.96, 0.76, 0.2), 0.5, 3.0)
			TownArt.lattice(k, Vector3(1.5, y0 + 2.2, cz + 1.4), Vector3(1.5, sy + sh + 0.4, cz + 1.4), 0.4, Color(0.96, 0.76, 0.2), true)
			_bx(k, Vector3(0.5, 0.6, 0.5), Color(0.86, 0.3, 0.26), 1.5, sy + 2.5, cz + 1.9)
		_:
			_core_final(k, y0)


## The stepped podium of the Core up to `levels` levels (concrete while
## building, graphite and brass when done).
static func _podium(k: MeshKit, levels: int, y0: float, col: Color, done := false) -> float:
	var cz := -0.2
	var y := y0
	var sizes := [4.6, 3.6, 2.7]
	var hs := [1.2, 1.0, 0.9]
	for i in levels:
		var s: float = sizes[i]
		var hh: float = hs[i]
		_bx(k, Vector3(s, hh, s), col, 0, y + hh * 0.5, cz)
		if done:
			for sd in [-1.0, 1.0]:
				_bx(k, Vector3(s + 0.06, 0.07, 0.08), Pal.BRASS, 0, y + hh - 0.03, cz + sd * (s * 0.5 - 0.01))
				_bx(k, Vector3(0.08, 0.07, s + 0.06), Pal.BRASS, sd * (s * 0.5 - 0.01), y + hh - 0.03, cz)
			for j in 3:
				_bx(k, Vector3(s - 0.3, 0.008, 0.02), Color(0.42, 0.9, 1.0, 0.5), 0, y + hh + 0.004, cz - s * 0.25 + j * s * 0.25)
				_bx(k, Vector3(0.02, 0.008, s - 0.3), Color(0.42, 0.9, 1.0, 0.5), -s * 0.25 + j * s * 0.25, y + hh + 0.004, cz)
			for sd in [-1.0, 1.0]:
				for j in int(s / 0.3):
					var p := -s * 0.5 + 0.15 + j * 0.3
					_bx(k, Vector3(0.05, hh - 0.25, 0.08), Color(0.24, 0.25, 0.29), p, y + hh * 0.5, cz + sd * s * 0.5)
					_bx(k, Vector3(0.08, hh - 0.25, 0.05), Color(0.24, 0.25, 0.29), sd * s * 0.5, y + hh * 0.5, cz + p)
				_bx(k, Vector3(s - 0.2, 0.03, 0.03), Color(0.42, 0.9, 1.0, 0.45), 0, y + 0.2, cz + sd * (s * 0.5 + 0.03))
				_bx(k, Vector3(0.03, 0.03, s - 0.2), Color(0.42, 0.9, 1.0, 0.45), sd * (s * 0.5 + 0.03), y + 0.2, cz)
		else:
			for sd in [-1.0, 1.0]:
				for j in 3:
					_bx(k, Vector3(s * 0.2, hh * 0.5, 0.02), col.darkened(0.06), -s * 0.3 + j * s * 0.3, y + hh * 0.5, cz + sd * (s * 0.5 + 0.01))
		y += hh
	return y


## The finished Core: graphite podium, a shaft of glowing fins and brass
## rings, liquid-cooling loops spiralling up, a glowing sphere held in
## brass arms with orbiting rings, and a beam of light.
static func _core_final(k: MeshKit, y0: float) -> void:
	var cz := -0.2
	var g := Color(0.17, 0.18, 0.21)
	var g2 := Color(0.24, 0.25, 0.29)
	var brass := Pal.BRASS
	var cyan := Color(0.42, 0.9, 1.0, 0.45)
	var gold := Color(1.0, 0.86, 0.5, 0.4)
	var top := _podium(k, 3, y0, g, true)
	# the shaft: lighter graphite, fins with glow strips, rings, risers
	var sh := 8.0
	var gs := Color(0.27, 0.28, 0.33)
	k.cyl(0.95, sh, gs, MeshKit.at(0, top, cz), 12, 0.0, 0.72)
	for i in 8:
		var a := TAU * i / 8.0
		var p := Vector3(cos(a), 0, sin(a))
		var fr := 0.9
		TownArt.beam(k, Vector3(p.x * fr, top + 0.1, cz + p.z * fr), Vector3(p.x * 0.7, top + sh - 0.2, cz + p.z * 0.7), 0.1, g, 0.3)
		TownArt.beam(k, Vector3(p.x * (fr + 0.17), top + 0.4, cz + p.z * (fr + 0.17)), Vector3(p.x * 0.87, top + sh - 0.5, cz + p.z * 0.87), 0.03, cyan if i % 2 == 0 else gold)
	for j in 7:
		var f := (j + 0.5) / 7.0
		var rr := lerpf(0.95, 0.72, f)
		if j % 2 == 0:
			k.torus(rr + 0.02, 0.035, cyan, MeshKit.at(0, top + sh * f, cz), 16, 3)
		else:
			k.torus(rr + 0.08, 0.06, brass, MeshKit.at(0, top + sh * f, cz), 16, 3)
	# liquid-cooling risers between the fins, with brass collars
	for i in 4:
		var a2 := TAU * (i + 0.5) / 4.0 + PI * 0.125
		var d2 := Vector3(cos(a2), 0, sin(a2))
		var lo := Vector3(0, top + 0.05, cz) + d2 * 1.15
		var hi := Vector3(0, top + sh - 0.6, cz) + d2 * 0.92
		TownArt.rod(k, lo, hi, 0.07, cyan, 6)
		for c in 5:
			var q := lo.lerp(hi, (c + 0.5) / 5.0)
			k.cyl(0.09, 0.06, brass, MeshKit.at(q.x, q.y, q.z), 6)
	# a brass flare at the top of the shaft
	k.lathe(PackedVector2Array([Vector2(0.72, 0.0), Vector2(0.9, 0.3), Vector2(1.35, 0.7), Vector2(1.3, 0.75), Vector2(0.0, 0.75)]), brass, MeshKit.at(0, top + sh, cz), 16)
	k.torus(1.33, 0.04, gold, MeshKit.at(0, top + sh + 0.72, cz), 18, 3)
	# pipes from the cooling halls across to the podium
	for sx in [-1.0, 1.0]:
		ArchKit.pipes(k, [Vector3(sx * 2.25, y0 + 1.7, -0.2), Vector3(sx * 2.25, y0 + 1.7, 0.8), Vector3(sx * 1.8, y0 + 1.7, 0.8), Vector3(sx * 1.8, y0 + 1.25, 0.8)], 0.08, cyan)
	# the crown: brass arms cradling a glowing sphere, two orbiting rings
	var cy := top + sh + 1.8
	for i in 4:
		var a3 := TAU * i / 4.0 + PI * 0.25
		var d := Vector3(cos(a3), 0, sin(a3))
		TownArt.beam(k, Vector3(0, top + sh + 0.7, cz) + d * 1.1, Vector3(0, cy - 0.2, cz) + d * 1.25, 0.12, brass)
		TownArt.beam(k, Vector3(0, cy - 0.2, cz) + d * 1.25, Vector3(0, cy + 0.9, cz) + d * 0.9, 0.1, brass)
		k.sphere(0.08, gold, MeshKit.at(d.x * 0.9, cy + 0.95, cz + d.z * 0.9), 6, 3)
	k.sphere(1.05, Color(0.6, 0.96, 1.0, 0.35), MeshKit.at(0, cy, cz), 16, 10)
	k.sphere(0.6, Color(1.0, 1.0, 1.0, 0.25), MeshKit.at(0, cy, cz), 10, 6)
	k.torus(1.55, 0.08, brass, MeshKit.xf(Vector3(0, cy, cz), Vector3(70, 0, 20)), 24, 4)
	k.torus(1.8, 0.05, cyan, MeshKit.xf(Vector3(0, cy, cz), Vector3(20, 30, 70)), 24, 4)
	k.torus(2.05, 0.04, gold, MeshKit.xf(Vector3(0, cy, cz), Vector3(-50, 60, 10)), 24, 4)
	k.cyl(0.1, 5.0, Color(0.7, 0.98, 1.0, 0.5), MeshKit.at(0, cy + 1.0, cz), 8)
	ArchKit.beacon(k, Vector3(0, cy + 6.0, cz), 0.4)
	# a ring of light on the podium roof, beacons on its corners
	k.torus(1.25, 0.04, cyan, MeshKit.at(0, top + 0.05, cz), 20, 3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			ArchKit.beacon(k, Vector3(sx * 1.2, top, cz + sz * 1.2), 0.4)
	# drone pads on the podium's second level corners
	for sx in [-1.0, 1.0]:
		ArchKit.drone_pad(k, Vector3(sx * 1.55, y0 + 2.22, cz + 1.55), 0.35)


# ---------------------------------------------------------------- works

## What's still a building site at stage t: cranes, site offices, trucks,
## material yards, steel frames for the next halls, hoarding and lights.
static func _works(k: MeshKit, t: int, y0: float) -> void:
	var yel := Color(0.96, 0.76, 0.2)
	# hoarding along the sides and back with banners, floodlights
	var hc := Color(0.94, 0.94, 0.92)
	for side in [[Vector3(-4.85, 0, -4.85), Vector3(4.85, 0, -4.85)], [Vector3(-4.85, 0, -4.85), Vector3(-4.85, 0, 3.4)], [Vector3(4.85, 0, -4.85), Vector3(4.85, 0, 3.4)]]:
		var a: Vector3 = side[0]
		var b: Vector3 = side[1]
		var n := int(a.distance_to(b) / 1.2)
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			var along := (b - a).normalized()
			var yaw := rad_to_deg(atan2(along.x, along.z))
			k.box(Vector3(0.04, 1.1, 1.16), hc if i % 4 else Color(0.3, 0.66, 0.68), MeshKit.xf(p + Vector3(0, 0.57, 0), Vector3(0, yaw - 90.0, 0)) * MeshKit.xf(Vector3.ZERO, Vector3(0, 90, 0)))
			_bx(k, Vector3(0.06, 1.2, 0.06), Color(0.5, 0.52, 0.54), a.lerp(b, float(i) / n).x, 0.6, a.lerp(b, float(i) / n).z)
	for p in [Vector3(-4.5, 0, 3.1), Vector3(4.5, 0, 3.1)]:
		_bx(k, Vector3(0.5, 0.2, 0.5), yel, p.x, 0.1, p.z)
		k.cyl(0.04, 3.4, Color(0.7, 0.72, 0.74), MeshKit.at(p.x, 0.2, p.z), 6)
		for j in 2:
			for i in 2:
				TownArt.floodlight(k, MeshKit.xf(Vector3(p.x - 0.15 + i * 0.3, 3.4 + j * 0.25, p.z - 0.05), Vector3(0, 180, 0)))
	# cranes: three at the start, fewer as the site fills in
	match t:
		0:
			TownArt.tower_crane(k, MeshKit.xf(Vector3(-3.7, y0, 2.4), Vector3(0, -40, 0)), 9.0, 5.8, 1.6, yel, 0.5, 4.0)
			TownArt.tower_crane(k, MeshKit.xf(Vector3(3.9, y0, -3.9), Vector3(0, 150, 0)), 11.0, 6.4, 1.8, yel, 0.5, 6.0)
		1:
			TownArt.tower_crane(k, MeshKit.xf(Vector3(-2.6, y0, -1.9), Vector3(0, -15, 0)), 11.5, 6.4, 1.8, yel, 0.5, 5.0)
			TownArt.tower_crane(k, MeshKit.xf(Vector3(3.7, y0, 2.4), Vector3(0, 200, 0)), 8.5, 5.4, 1.5, Color(0.86, 0.3, 0.26), 0.45, 4.0)
		2:
			TownArt.tower_crane(k, MeshKit.xf(Vector3(-1.4, y0, 2.3), Vector3(0, 20, 0)), 10.0, 6.0, 1.6, yel, 0.5, 4.0)
	# site offices (stacked cabins) and parking at the front left until the halls
	if t <= 2:
		for j in 2:
			for i in 2:
				_cabin(k, Vector3(-3.4 + i * 0.0, y0 + j * 1.05, 1.6 + i * 1.15), [Color(0.94, 0.94, 0.92), Color(0.3, 0.5, 0.78)][(i + j) % 2])
		TownArt.stair(k, Vector3(-2.0, y0, 2.95), Vector3(-2.0, y0 + 1.05, 2.0), 0.4, Color(0.56, 0.58, 0.6), Color(0.36, 0.38, 0.42), yel)
		for i in 3:
			TownArt.cone_traffic(k, Vector3(-2.4 + i * 0.4, y0, 3.3))
	# the front right: trucks and a material yard, a steel frame at stage 2
	match t:
		0:
			_truck(k, MeshKit.xf(Vector3(2.9, y0, 2.5), Vector3(0, -20, 0)), "dump", yel)
			_excavator(k, MeshKit.xf(Vector3(3.9, y0, 0.6), Vector3(0, -120, 0)), Color(0.96, 0.6, 0.2))
			k.ellipsoid(Vector3(1.1, 0.5, 0.8), Color(0.56, 0.45, 0.34), MeshKit.at(3.6, 0.0, -0.9), 10, 5)
			k.ellipsoid(Vector3(0.7, 0.35, 0.6), Color(0.62, 0.5, 0.38), MeshKit.at(2.9, 0.0, -1.6), 9, 4)
			_yard(k, Vector3(-3.4, y0, -1.2), 0)
		1:
			_truck(k, MeshKit.xf(Vector3(2.7, y0, 2.6), Vector3(0, -90, 0)), "mixer", Color(0.94, 0.94, 0.92))
			_yard(k, Vector3(3.6, y0, -0.9), 1)
			_yard(k, Vector3(-3.6, y0, -1.0), 2)
			for sx in [-1.0, 1.0]:
				_rebar_mat(k, Rect2(sx * 3.75 - 1.0, -2.4, 2.0, 1.2), y0 + 0.02)
		2:
			_steel_frame(k, Rect2(1.95, 1.1, 2.85, 2.3), y0, 2.5)
			_truck(k, MeshKit.xf(Vector3(3.3, y0, 3.0), Vector3(0, -90, 0)), "flatbed", Color(0.3, 0.5, 0.78))
		3:
			ArchKit.clutter(k, Vector3(-1.5, y0, 2.6), 3, 9)
			ArchKit.clutter(k, Vector3(1.5, y0, 2.6), 3, 10)
	# portable toilets and skips
	for i in 2:
		var p2 := Vector3(-4.4 + i * 0.6, y0, -2.4) if t < 2 else Vector3(1.0 + i * 0.6, y0, 1.0)
		if t >= 2 and t == 3:
			break
		_bx(k, Vector3(0.5, 1.2, 0.5), Color(0.3, 0.52, 0.8), p2.x, p2.y + 0.6, p2.z)
		_bx(k, Vector3(0.54, 0.05, 0.54), Color(0.94, 0.94, 0.92), p2.x, p2.y + 1.22, p2.z)


## A stacked site cabin (along x) with a window and door.
static func _cabin(k: MeshKit, c: Vector3, col: Color) -> void:
	_bx(k, Vector3(2.4, 1.0, 1.05), col, c.x, c.y + 0.5, c.z)
	for i in 10:
		_bx(k, Vector3(0.04, 0.92, 1.07), col.darkened(0.08), c.x - 1.08 + i * 0.24, c.y + 0.5, c.z)
	_bx(k, Vector3(2.44, 0.06, 1.09), Color(0.4, 0.42, 0.46), c.x, c.y + 1.0, c.z)
	_bx(k, Vector3(0.5, 0.36, 0.04), Color(0.6, 0.78, 0.88, 0.75), c.x - 0.4, c.y + 0.6, c.z + 0.54)
	_bx(k, Vector3(0.38, 0.8, 0.04), Color(0.36, 0.4, 0.46), c.x + 0.7, c.y + 0.42, c.z + 0.54)
	_bx(k, Vector3(0.4, 0.14, 0.03), Color(0.96, 0.6, 0.24), c.x, c.y + 0.86, c.z + 0.54)


## A mat of rebar (a grid of thin bars) over a rectangle.
static func _rebar_mat(k: MeshKit, r: Rect2, y: float) -> void:
	var col := Color(0.5, 0.32, 0.26)
	for i in int(r.size.x / 0.2) + 1:
		_bx(k, Vector3(0.02, 0.02, r.size.y), col, r.position.x + i * 0.2, y + 0.01, r.get_center().y)
	for j in int(r.size.y / 0.2) + 1:
		_bx(k, Vector3(r.size.x, 0.02, 0.02), col, r.get_center().x, y + 0.03, r.position.y + j * 0.2)
	for i in 6:
		_bx(k, Vector3(0.06, 0.08, 0.06), Color(0.66, 0.66, 0.64), r.position.x + 0.2 + (i % 3) * r.size.x * 0.3, y, r.position.y + 0.2 + (i / 3) * r.size.y * 0.6)


## Scaffolding around a rectangle up to height h.
static func _scaffold_ring(k: MeshKit, r: Rect2, y0: float, h: float) -> void:
	var pole := Color(0.66, 0.66, 0.64)
	var plank := Color(0.78, 0.64, 0.44)
	var n := int(r.size.x / 0.9)
	for i in n + 1:
		var f := float(i) / n
		for z in [r.position.y, r.end.y]:
			k.cyl(0.025, h, pole, MeshKit.at(r.position.x + r.size.x * f, y0, z), 4)
		for x in [r.position.x, r.end.x]:
			k.cyl(0.025, h, pole, MeshKit.at(x, y0, r.position.y + r.size.y * f), 4)
	for lv in 2:
		var y := y0 + 0.9 + lv * 0.9
		for z in [r.position.y, r.end.y]:
			_bx(k, Vector3(r.size.x, 0.04, 0.3), plank, r.get_center().x, y, z)
			_bx(k, Vector3(r.size.x, 0.03, 0.03), pole, r.get_center().x, y + 0.5, z)
		for x in [r.position.x, r.end.x]:
			_bx(k, Vector3(0.3, 0.04, r.size.y), plank, x, y, r.get_center().y)
			_bx(k, Vector3(0.03, 0.03, r.size.y), pole, x, y + 0.5, r.get_center().y)
	for i in n:
		var xa := r.position.x + r.size.x * float(i) / n
		var xb := r.position.x + r.size.x * float(i + 1) / n
		TownArt.beam(k, Vector3(xa, y0, r.end.y), Vector3(xb, y0 + h * 0.9, r.end.y), 0.025, pole)


## A steel frame going up: columns, beams, a few bays of roof decking.
static func _steel_frame(k: MeshKit, r: Rect2, y0: float, h: float) -> void:
	var st := Color(0.56, 0.3, 0.24)
	var nx := 4
	var nz := 3
	for i in nx:
		for j in nz:
			var p := Vector3(r.position.x + r.size.x * i / (nx - 1), y0, r.position.y + r.size.y * j / (nz - 1))
			_bx(k, Vector3(0.12, h, 0.12), st, p.x, y0 + h * 0.5, p.z)
			_bx(k, Vector3(0.3, 0.06, 0.3), Color(0.66, 0.66, 0.64), p.x, y0 + 0.03, p.z)
	for j in nz:
		var z := r.position.y + r.size.y * j / (nz - 1)
		_bx(k, Vector3(r.size.x, 0.16, 0.08), st, r.get_center().x, y0 + h, z)
	for i in nx:
		var x := r.position.x + r.size.x * i / (nx - 1)
		_bx(k, Vector3(0.08, 0.16, r.size.y), st, x, y0 + h, r.get_center().y)
	for i in 2:
		var x2 := r.position.x + r.size.x * (i + 0.5) / (nx - 1)
		TownArt.beam(k, Vector3(x2 - r.size.x / (nx - 1) * 0.5, y0, r.end.y), Vector3(x2 + r.size.x / (nx - 1) * 0.5, y0 + h, r.end.y), 0.05, st)
	for i in 6:
		_bx(k, Vector3(r.size.x / (nx - 1) - 0.04, 0.03, 0.4), Color(0.6, 0.62, 0.64), r.position.x + r.size.x / (nx - 1) * 0.5, y0 + h + 0.1, r.position.y + 0.2 + i * 0.4)


## A material yard: pipe stacks, beams, cable drums, pallets.
static func _yard(k: MeshKit, c: Vector3, v: int) -> void:
	for i in 6:
		k.cyl(0.11, 1.6, [Color(0.36, 0.6, 0.86), Color(0.86, 0.86, 0.84), Color(0.4, 0.42, 0.46)][v % 3], MeshKit.xf(c + Vector3(-0.8, 0.11 + (i / 3) * 0.2, -0.3 + (i % 3) * 0.22 + (i / 3) * 0.11), Vector3(0, 0, -90)), 7)
	for i in 4:
		_bx(k, Vector3(1.6, 0.12, 0.14), Color(0.56, 0.3, 0.24), c.x, c.y + 0.08 + (i / 2) * 0.13, c.z + 0.6 + (i % 2) * 0.18)
	for i in 2:
		var d := c + Vector3(-0.5 + i * 0.7, 0, -0.9)
		k.cyl(0.32, 0.06, Pal.WOOD, MeshKit.xf(d + Vector3(0, 0.32, -0.15), Vector3(90, 0, 0)), 10)
		k.cyl(0.32, 0.06, Pal.WOOD, MeshKit.xf(d + Vector3(0, 0.32, 0.15), Vector3(90, 0, 0)), 10)
		k.cyl(0.24, 0.26, [Color(0.2, 0.2, 0.22), Color(0.96, 0.6, 0.2)][i], MeshKit.xf(d + Vector3(0, 0.32, 0.13), Vector3(90, 0, 0)), 10)
	TownArt.pallet(k, MeshKit.at(c.x + 0.6, c.y, c.z - 0.1), "bricks" if v == 0 else "sacks")


## A tracked excavator (facing local +z): tracks, house, cab, boom, bucket.
static func _excavator(k: MeshKit, base: Transform3D, col: Color) -> void:
	var dark := Color(0.2, 0.2, 0.22)
	for sx in [-0.38, 0.38]:
		k.rbox(Vector3(0.24, 0.26, 1.3), 0.1, dark, base * MeshKit.at(sx, 0.13, 0), 1)
		for i in 4:
			k.cyl(0.07, 0.25, Color(0.36, 0.36, 0.38), base * MeshKit.xf(Vector3(sx, 0.12, -0.45 + i * 0.3), Vector3(0, 0, 90)) * MeshKit.at(0, -0.125, 0), 6)
	k.box(Vector3(0.5, 0.12, 0.5), dark, base * MeshKit.at(0, 0.32, 0))
	k.box(Vector3(0.95, 0.38, 1.1), col, base * MeshKit.at(0, 0.56, -0.1))
	k.box(Vector3(0.98, 0.2, 0.3), col.darkened(0.2), base * MeshKit.at(0, 0.5, -0.62))
	k.box(Vector3(0.42, 0.5, 0.48), col, base * MeshKit.at(-0.22, 0.98, 0.18))
	k.box(Vector3(0.38, 0.32, 0.02), Color(0.4, 0.6, 0.76, 0.7), base * MeshKit.at(-0.22, 1.02, 0.43))
	k.box(Vector3(0.02, 0.32, 0.4), Color(0.4, 0.6, 0.76, 0.7), base * MeshKit.at(-0.44, 1.02, 0.18))
	var b0 := base * Vector3(0.18, 0.7, 0.35)
	var b1 := base * Vector3(0.18, 1.65, 1.15)
	var b2 := base * Vector3(0.18, 0.55, 1.75)
	TownArt.beam(k, b0, b1, 0.16, col, 0.22)
	TownArt.beam(k, b1, b2, 0.12, col, 0.16)
	TownArt.beam(k, base * Vector3(0.18, 0.9, 0.5), base * Vector3(0.18, 1.5, 1.0), 0.06, Color(0.7, 0.72, 0.74))
	k.box(Vector3(0.36, 0.26, 0.3), dark, Transform3D(base.basis, b2) * MeshKit.xf(Vector3(0, -0.1, 0.05), Vector3(30, 0, 0)))
	for i in 4:
		k.box(Vector3(0.04, 0.08, 0.04), Color(0.7, 0.72, 0.74), Transform3D(base.basis, b2) * MeshKit.at(-0.13 + i * 0.09, -0.27, 0.18))


## A truck (facing local +z): "dump", "mixer" or "flatbed".
static func _truck(k: MeshKit, base: Transform3D, kind: String, col: Color) -> void:
	var dark := Color(0.2, 0.2, 0.22)
	k.box(Vector3(0.8, 0.14, 2.6), dark, base * MeshKit.at(0, 0.3, 0))
	k.box(Vector3(0.86, 0.75, 0.62), col, base * MeshKit.at(0, 0.75, 0.95))
	k.box(Vector3(0.78, 0.3, 0.02), Color(0.4, 0.6, 0.76, 0.7), base * MeshKit.at(0, 0.92, 1.265))
	k.box(Vector3(0.88, 0.12, 0.08), Color(0.7, 0.72, 0.74), base * MeshKit.at(0, 0.38, 1.28))
	for sx in [-0.42, 0.42]:
		k.box(Vector3(0.04, 0.06, 0.1), Color(1.0, 0.95, 0.8, 0.4), base * MeshKit.at(sx * 0.8, 0.5, 1.28))
		for z in [0.9, -0.3, -0.85]:
			k.cyl(0.2, 0.16, Pal.RUBBER, base * MeshKit.xf(Vector3(sx, 0.2, z), Vector3(0, 0, 90)) * MeshKit.at(0, -0.08, 0), 8)
	match kind:
		"dump":
			k.box(Vector3(0.9, 0.55, 1.6), col.darkened(0.1), base * MeshKit.xf(Vector3(0, 0.75, -0.4), Vector3(8, 0, 0)))
			k.ellipsoid(Vector3(0.4, 0.2, 0.7), Color(0.56, 0.45, 0.34), base * MeshKit.at(0, 1.05, -0.45), 8, 4)
		"mixer":
			var dr := base * MeshKit.xf(Vector3(0, 0.95, -0.45), Vector3(-75, 0, 0))
			k.cyl(0.42, 0.8, Color(0.94, 0.94, 0.92), dr * MeshKit.at(0, -0.4, 0), 10, 0.0, 0.42)
			k.cyl(0.42, 0.6, Color(0.94, 0.94, 0.92), dr * MeshKit.at(0, 0.4, 0), 10, 0.0, 0.2)
			for j in 3:
				k.torus(0.4 - j * 0.04, 0.03, Color(0.96, 0.6, 0.24), dr * MeshKit.at(0, -0.2 + j * 0.3, 0), 10, 3)
			TownArt.beam(k, base * Vector3(0, 0.6, -1.2), base * Vector3(0, 0.2, -1.6), 0.1, Color(0.7, 0.72, 0.74))
		_:
			k.box(Vector3(0.9, 0.06, 1.7), Pal.WOOD, base * MeshKit.at(0, 0.4, -0.4))
			for i in 4:
				k.box(Vector3(0.12, 0.14, 1.6), Color(0.56, 0.3, 0.24), base * MeshKit.at(-0.25 + (i % 3) * 0.25, 0.5 + (i / 3) * 0.15, -0.4))


## A piling rig: tracks, a cab and a tall lattice leader mast.
static func _piling_rig(k: MeshKit, base: Transform3D) -> void:
	var col := Color(0.86, 0.3, 0.26)
	for sx in [-0.42, 0.42]:
		k.rbox(Vector3(0.26, 0.26, 1.4), 0.1, Color(0.2, 0.2, 0.22), base * MeshKit.at(sx, 0.13, 0), 1)
	k.box(Vector3(1.0, 0.5, 1.2), col, base * MeshKit.at(0, 0.55, -0.1))
	k.box(Vector3(0.4, 0.45, 0.4), col, base * MeshKit.at(-0.25, 1.02, 0.25))
	k.box(Vector3(0.36, 0.3, 0.02), Color(0.4, 0.6, 0.76, 0.7), base * MeshKit.at(-0.25, 1.08, 0.46))
	TownArt.lattice(k, base * Vector3(0.2, 0.3, 0.75), base * Vector3(0.2, 6.5, 0.75), 0.26, col)
	TownArt.beam(k, base * Vector3(0.2, 0.8, 0.0), base * Vector3(0.2, 3.5, 0.65), 0.08, col)
	k.box(Vector3(0.3, 0.6, 0.3), Color(0.24, 0.25, 0.27), base * MeshKit.at(0.2, 3.8, 0.95))
	k.cyl(0.1, 2.4, Color(0.4, 0.42, 0.46), base * MeshKit.at(0.2, 0.0, 0.95), 6)
	ArchKit.beacon(k, base * Vector3(0.2, 6.5, 0.75), 0.2)


# ---------------------------------------------------------------- finale

## The finished campus front: a brass gate with glowing "AGI", banners,
## planters with trees, glowing bollards and a low glass-and-brass fence.
static func _finale(k: MeshKit, y0: float) -> void:
	var brass := Pal.BRASS
	var gold := Color(1.0, 0.86, 0.5, 0.4)
	var g := Color(0.17, 0.18, 0.21)
	# the gate over the steps
	for sx in [-1.0, 1.0]:
		_bx(k, Vector3(0.3, 3.2, 0.3), g, sx * 1.55, y0 + 1.6, 3.2)
		_bx(k, Vector3(0.34, 0.08, 0.34), brass, sx * 1.55, y0 + 3.2, 3.2)
		_bx(k, Vector3(0.04, 2.8, 0.04), gold, sx * 1.55, y0 + 1.6, 3.37)
	_bx(k, Vector3(3.5, 0.4, 0.3), g, 0, y0 + 3.4, 3.2)
	_bx(k, Vector3(3.54, 0.05, 0.34), brass, 0, y0 + 3.62, 3.2)
	_bx(k, Vector3(3.54, 0.05, 0.34), brass, 0, y0 + 3.18, 3.2)
	TownArt.word(k, MeshKit.at(0, y0 + 3.7, 3.2), "AGI", 0.7, gold, 0.16, 0.08)
	# tall banners either side
	for sx in [-1.0, 1.0]:
		var bx: float = sx * 2.4
		k.cyl(0.04, 4.2, brass, MeshKit.at(bx, y0, 3.3), 6)
		_bx(k, Vector3(0.6, 2.2, 0.03), Color(0.3, 0.66, 0.68), bx + sx * 0.0, y0 + 2.9, 3.3)
		_bx(k, Vector3(0.62, 0.05, 0.05), brass, bx, y0 + 4.0, 3.3)
		Items.token_into(k, "frontier", 0.2, 0.04, MeshKit.xf(Vector3(bx, y0 + 3.3, 3.33), Vector3(90, 0, 0)))
	# planters with trees and glowing bollards along the front
	for i in 4:
		var px: float = [-4.2, -3.3, 3.3, 4.2][i]
		_bx(k, Vector3(0.6, 0.4, 0.6), g, px, y0 + 0.2, 3.1)
		_bx(k, Vector3(0.62, 0.04, 0.62), brass, px, y0 + 0.41, 3.1)
		TownArt.tree(k, Vector3(px, y0 + 0.42, 3.1), 1.6, Pal.LEAF_DARK, i + 20)
	for i in 6:
		var bx2 := -4.4 + i * 0.6 if i < 3 else 2.8 + (i - 3) * 0.6
		k.cyl(0.06, 0.5, g, MeshKit.at(bx2, 0.02, 3.95), 6)
		k.cyl(0.065, 0.08, gold, MeshKit.at(bx2, 0.4, 3.95), 6)
	for sx in [-1.0, 1.0]:
		ArchKit.fence(k, Vector3(sx * 4.85, y0, -4.85), Vector3(sx * 4.85, y0, 0.8), 4, 0.9)
	ArchKit.fence(k, Vector3(-4.85, y0, -4.85), Vector3(4.85, y0, -4.85), 4, 0.9)
