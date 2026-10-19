class_name CafeB
extends Building
## The Chat Café: people stroll in from the countryside, sit at a table and
## chat live with one of your models (the snappiest earner you serve). Each
## chatting visitor is demand the Market serves at 1.3x the API price (more
## for a fast model); if your servers can't keep up, they get bored and
## leave. Planters, lamps, benches and trees nearby bring more visitors.

var _spawn_t := 3.0
var _customers: Array[Customer] = []
var _label: Label3D
var _seats_node: MeshInstance3D
var _taken := {}               # seat index -> Customer


func _build() -> void:
	_label = UI3D.label("", 28)
	_label.position = Vector3(-1.3, 1.75, 0.2)
	add_child(_label)
	var b := UI3D.badge("cafe", Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 3.9, -1.0)
	add_child(b)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.0, -2.0, 6.0, 1.65), Rect2(-2.45, -0.4, 2.3, 0.75)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("cafe_%d" % t, func(): return CafeB.mesh(t)), root)
	_seats_node = Mats.inst(null, root)


func _on_level() -> void:
	var n := seats()
	if _seats_node:
		_seats_node.mesh = MeshKit.cached("cafe_seats_%d_%d" % [n, tier], func(): return CafeB.seats_mesh(n, tier))


func seats() -> int:
	return Bal.cafe_seats(level)


## Where seat i is (local): two rows of tables on the terrace.
static func seat_local(i: int) -> Vector3:
	return Vector3(-1.8 + (i % 4) * 0.8 + (0.4 if i / 4 == 1 else 0.0), 0, 1.0 + (i / 4 % 2) * 0.65 + (i / 8) * 0.0)


func seat_point(i: int) -> Vector3:
	var p := seat_local(i)
	return to_world(p.x, p.z)


## A free seat for a visitor (-1 if full).
func take_seat(c: Customer) -> int:
	for i in seats():
		if not _taken.has(i) or not is_instance_valid(_taken[i]):
			_taken[i] = c
			return i
	return -1


func leave_seat(i: int) -> void:
	_taken.erase(i)


func charm() -> float:
	return world.aura(global_position, "charm") + world.aura(global_position, "walk") * 0.5


func rate() -> float:
	return Bal.cafe_rate(level) * (1.0 + charm())


## The model the café chats with: the best earner (with the snappy bonus)
## that some server is serving.
func model() -> String:
	var best := ""
	var bv := 0.0
	for rid in Market.cap:
		if float(Market.cap[rid]) <= 0.0:
			continue
		var v := Market.token_price(rid) * (1.0 + Bal.latency_bonus(rid))
		if v > bv:
			bv = v
			best = rid
	return best


func chatting() -> int:
	var n := 0
	for c in _customers:
		if is_instance_valid(c) and c.state == Customer.S.CHAT:
			n += 1
	return n


## K tokens/s its chatting visitors read.
func chat_demand() -> float:
	return chatting() * Bal.cafe_chat(Game.level)


## Whether chats are being answered (most of the café's demand served).
func answered() -> bool:
	var rid := model()
	if rid == "":
		return false
	var want := float(Market.want.get("cafe", {}).get(rid, 0.0))
	var got := float(Market.by_channel.get("cafe", {}).get(rid, 0.0))
	return want <= 0.0 or got >= want * 0.6


func _process(dt: float) -> void:
	super(dt)
	_spawn_t -= dt * Game.speed_mult()
	_customers = _customers.filter(func(c): return is_instance_valid(c))
	if _spawn_t <= 0.0:
		_spawn_t = 60.0 / rate() * randf_range(0.7, 1.3)
		if _customers.size() < seats() + 2 and model() != "":
			_spawn_customer()
	if int(_t) != int(_t - dt):
		var rid := model()
		_label.text = ("%d chatting  ·  %s" % [chatting(), Defs.model_name(rid)]) if rid != "" else "No model served"


func _spawn_customer() -> void:
	var c := Customer.new()
	c.shop = self
	var a := randf() * TAU
	var r := randf_range(22.0, 30.0)
	c.spawn = global_position + Vector3(cos(a) * r, 0, sin(a) * r)
	c.position = c.spawn
	world.actors.add_child(c)
	_customers.append(c)


## A visitor finished a chat (paid as they went, through the Market).
func chat_done(c: Customer) -> void:
	Game.stats["customers"] = int(Game.stats["customers"]) + 1
	Game.track("customers")
	UI3D.pop_text(get_tree().current_scene, c.global_position + Vector3(0, 2.2, 0), ":)", Color(1.0, 0.9, 0.5), 56)
	Sfx.play("cash", -10.0, 1.2)


func status() -> String:
	return "Visitors chat with %s at 1.3x the API price. %d%% more visitors from decor nearby." % [Defs.model_name(model()) if model() != "" else "your models", roundi(charm() * 100)]


func info() -> Array:
	return [
		["hire", "About %.0f visitors / min, %d seats" % [rate(), seats()]],
		["token", "Each reads about %s tokens/s while chatting" % Fmt.tokens(Bal.cafe_chat(Game.level))],
		["clock", "Models under %d ms earn up to +%d%%" % [int(Bal.SNAPPY_MS), roundi(Bal.SNAPPY_BONUS * 100)]],
	]


func upgrade_info() -> Array:
	var n := level + 1
	var out := [["Visitors / min", "%.1f" % Bal.cafe_rate(level), "%.1f" % Bal.cafe_rate(n)]]
	if Bal.cafe_seats(n) > seats():
		out.append(["Seats", str(seats()), str(Bal.cafe_seats(n))])
	return out


## Little tables with chairs on the terrace, one per seat; every era has its
## own furniture (the visitor sits at seat_local facing -z, table in front).
static func seats_mesh(n: int, t: int) -> Mesh:
	var k := MeshKit.new()
	for i in n:
		var p := seat_local(i)
		var tp := p + Vector3(0.0, 0, -0.28)
		match t:
			0: _seat_garage(k, p, tp, i)
			1: _seat_workshop(k, p, tp, i)
			2: _seat_campus(k, p, tp, i)
			3: _seat_loft(k, p, tp, i)
			_: _seat_lounge(k, p, tp, i)
	return k.commit()


## A folding wooden table and a folding chair in a random colour.
static func _seat_garage(k: MeshKit, p: Vector3, tp: Vector3, i: int) -> void:
	var cc: Color = [Color(0.36, 0.56, 0.4), Color(0.78, 0.36, 0.3), Color(0.3, 0.48, 0.72), Color(0.86, 0.68, 0.3)][i % 4]
	var tw := MeshKit.xf(tp, Vector3(0, (i * 23) % 13 - 6, 0))
	k.box(Vector3(0.5, 0.035, 0.42), Pal.WOOD_LIGHT, tw * MeshKit.at(0, 0.64, 0))
	k.box(Vector3(0.52, 0.04, 0.03), Pal.WOOD, tw * MeshKit.at(0, 0.61, 0.2))
	for sx in [-0.2, 0.2]:
		TownArt.beam(k, tw * Vector3(sx, 0.0, -0.16), tw * Vector3(sx, 0.62, 0.16), 0.025, Pal.WOOD_DARK)
		TownArt.beam(k, tw * Vector3(sx, 0.0, 0.16), tw * Vector3(sx, 0.62, -0.16), 0.025, Pal.WOOD_DARK)
	k.cyl(0.035, 0.08, Color(0.96, 0.95, 0.92), tw * MeshKit.at(0.1, 0.66, 0.05), 6)
	k.cyl(0.028, 0.012, Color(0.36, 0.22, 0.14), tw * MeshKit.at(0.1, 0.735, 0.05), 6)
	if i % 3 == 0:
		k.cyl(0.03, 0.1, Color(0.6, 0.78, 0.7), tw * MeshKit.at(-0.14, 0.66, -0.08), 6)
		k.sphere(0.04, Color(0.86, 0.5, 0.52), tw * MeshKit.at(-0.14, 0.8, -0.08), 5, 3)
	# folding chair (back toward +z)
	var cw := MeshKit.xf(p + Vector3(0, 0, 0.04), Vector3(0, (i * 41) % 17 - 8, 0))
	k.box(Vector3(0.34, 0.03, 0.3), cc, cw * MeshKit.at(0, 0.42, 0))
	k.box(Vector3(0.34, 0.2, 0.025), cc, cw * MeshKit.xf(Vector3(0, 0.7, 0.16), Vector3(-8, 0, 0)))
	for sx in [-0.16, 0.16]:
		TownArt.beam(k, cw * Vector3(sx, 0.0, -0.14), cw * Vector3(sx, 0.82, 0.17), 0.022, Color(0.5, 0.52, 0.54))
		TownArt.beam(k, cw * Vector3(sx, 0.0, 0.16), cw * Vector3(sx, 0.42, -0.1), 0.022, Color(0.5, 0.52, 0.54))


## A cable-spool table and a steel stool with a yellow seat.
static func _seat_workshop(k: MeshKit, p: Vector3, tp: Vector3, i: int) -> void:
	k.cyl(0.26, 0.04, Pal.WOOD_LIGHT, MeshKit.at(tp.x, 0.0, tp.z), 10)
	k.cyl(0.11, 0.56, Pal.WOOD, MeshKit.at(tp.x, 0.04, tp.z), 8)
	k.cyl(0.27, 0.05, Pal.WOOD_LIGHT, MeshKit.at(tp.x, 0.6, tp.z), 10)
	for j in 4:
		var a := TAU * j / 4.0 + 0.4
		k.box(Vector3(0.04, 0.012, 0.04), Pal.STEEL_DARK, MeshKit.at(tp.x + cos(a) * 0.2, 0.655, tp.z + sin(a) * 0.2))
	k.box(Vector3(0.18, 0.012, 0.12), Color(0.24, 0.25, 0.28), MeshKit.xf(Vector3(tp.x - 0.04, 0.66, tp.z + 0.02), Vector3(0, 15, 0)))
	k.box(Vector3(0.16, 0.004, 0.1), Color(0.5, 0.86, 1.0, 0.5), MeshKit.xf(Vector3(tp.x - 0.04, 0.668, tp.z + 0.02), Vector3(0, 15, 0)))
	k.cyl(0.035, 0.09, Color(0.95, 0.95, 0.94), MeshKit.at(tp.x + 0.14, 0.65, tp.z + 0.05), 6)
	# stool
	var sp := p + Vector3(0, 0, 0.03)
	k.cyl(0.15, 0.04, Color(0.96, 0.76, 0.2), MeshKit.at(sp.x, 0.4, sp.z), 8)
	for j in 3:
		var a2 := TAU * j / 3.0 + 0.5
		TownArt.beam(k, Vector3(sp.x + cos(a2) * 0.16, 0.0, sp.z + sin(a2) * 0.16), Vector3(sp.x + cos(a2) * 0.08, 0.4, sp.z + sin(a2) * 0.08), 0.025, Pal.STEEL_DARK)
	k.torus(0.12, 0.012, Pal.STEEL_DARK, MeshKit.at(sp.x, 0.16, sp.z), 8, 3)


## A white round table, a teal chair, an umbrella over every other table.
static func _seat_campus(k: MeshKit, p: Vector3, tp: Vector3, i: int) -> void:
	var teal := Color(0.3, 0.66, 0.68)
	k.cyl(0.13, 0.02, Color(0.8, 0.82, 0.84), MeshKit.at(tp.x, 0.0, tp.z), 8)
	k.cyl(0.03, 0.66, Color(0.86, 0.87, 0.88), MeshKit.at(tp.x, 0.02, tp.z), 6)
	k.cyl(0.22, 0.035, Color(0.97, 0.97, 0.97), MeshKit.at(tp.x, 0.66, tp.z), 10)
	k.cyl(0.04, 0.1, Color(0.97, 0.97, 0.97), MeshKit.at(tp.x + 0.1, 0.7, tp.z), 6)
	k.cyl(0.035, 0.02, Color(0.42, 0.26, 0.16), MeshKit.at(tp.x + 0.1, 0.79, tp.z), 6)
	k.box(Vector3(0.12, 0.012, 0.12), Color(0.98, 0.7, 0.3), MeshKit.at(tp.x - 0.08, 0.7, tp.z - 0.05))
	if i % 2 == 0:
		TownArt.umbrella(k, tp + Vector3(0, 0.7, 0), 1.5, 0.62, Color(0.97, 0.97, 0.96), teal)
	# moulded chair
	var cp := p + Vector3(0, 0, 0.03)
	k.box(Vector3(0.36, 0.04, 0.34), teal, MeshKit.at(cp.x, 0.42, cp.z))
	k.box(Vector3(0.36, 0.32, 0.04), teal, MeshKit.xf(Vector3(cp.x, 0.6, cp.z + 0.18), Vector3(-10, 0, 0)))
	for sx in [-0.15, 0.15]:
		for sz in [-0.14, 0.14]:
			k.box(Vector3(0.025, 0.4, 0.025), Color(0.86, 0.87, 0.88), MeshKit.at(cp.x + sx, 0.2, cp.z + sz))


## A reclaimed-wood table on hairpin legs and a black metal bistro chair,
## a little glowing jar lamp on the table.
static func _seat_loft(k: MeshKit, p: Vector3, tp: Vector3, i: int) -> void:
	var blk := Color(0.16, 0.16, 0.18)
	k.box(Vector3(0.5, 0.05, 0.42), Color(0.56, 0.38, 0.24).darkened(0.05 * (i % 3)), MeshKit.at(tp.x, 0.66, tp.z))
	for j in 3:
		k.box(Vector3(0.5, 0.004, 0.006), Color(0.42, 0.28, 0.18), MeshKit.at(tp.x, 0.686, tp.z - 0.13 + j * 0.13))
	for sx in [-0.2, 0.2]:
		for sz in [-0.16, 0.16]:
			TownArt.beam(k, Vector3(tp.x + sx, 0.0, tp.z + sz), Vector3(tp.x + sx * 0.8, 0.64, tp.z + sz * 0.8), 0.02, blk)
	k.cyl(0.035, 0.09, Color(1.0, 0.8, 0.5, 0.4), MeshKit.at(tp.x - 0.12, 0.69, tp.z - 0.08), 6)
	k.cyl(0.04, 0.09, Color(0.95, 0.95, 0.94), MeshKit.at(tp.x + 0.12, 0.69, tp.z + 0.06), 6)
	var cp := p + Vector3(0, 0, 0.03)
	k.box(Vector3(0.34, 0.035, 0.32), blk, MeshKit.at(cp.x, 0.42, cp.z))
	for j in 3:
		k.box(Vector3(0.3, 0.03, 0.02), blk, MeshKit.at(cp.x, 0.55 + j * 0.11, cp.z + 0.17))
	for sx in [-0.15, 0.15]:
		k.box(Vector3(0.025, 0.85, 0.025), blk, MeshKit.xf(Vector3(cp.x + sx, 0.42, cp.z + 0.15), Vector3(-6, 0, 0)))
		k.box(Vector3(0.025, 0.42, 0.025), blk, MeshKit.xf(Vector3(cp.x + sx, 0.21, cp.z - 0.13), Vector3(8, 0, 0)))


## A graphite table with a brass rim and a glowing edge, a lounge chair.
static func _seat_lounge(k: MeshKit, p: Vector3, tp: Vector3, i: int) -> void:
	var g := Color(0.17, 0.18, 0.21)
	k.cyl(0.16, 0.03, Pal.BRASS, MeshKit.at(tp.x, 0.0, tp.z), 8)
	k.cyl(0.05, 0.62, g, MeshKit.at(tp.x, 0.03, tp.z), 6, 0.0, 0.03)
	k.cyl(0.24, 0.04, g, MeshKit.at(tp.x, 0.64, tp.z), 10)
	k.torus(0.24, 0.015, Pal.BRASS, MeshKit.at(tp.x, 0.68, tp.z), 12, 3)
	k.cyl(0.245, 0.012, Color(1.0, 0.86, 0.5, 0.4), MeshKit.at(tp.x, 0.63, tp.z), 10)
	k.cyl(0.03, 0.12, Color(0.42, 0.9, 1.0, 0.45), MeshKit.at(tp.x + 0.1, 0.68, tp.z - 0.04), 6)
	var cp := p + Vector3(0, 0, 0.05)
	k.rbox(Vector3(0.42, 0.14, 0.38), 0.05, Color(0.24, 0.25, 0.29), MeshKit.at(cp.x, 0.33, cp.z), 1)
	k.box(Vector3(0.42, 0.38, 0.08), Color(0.2, 0.21, 0.24), MeshKit.xf(Vector3(cp.x, 0.58, cp.z + 0.18), Vector3(-12, 0, 0)))
	for sx in [-0.22, 0.22]:
		k.box(Vector3(0.05, 0.2, 0.38), Color(0.2, 0.21, 0.24), MeshKit.at(cp.x + sx, 0.4, cp.z))
		k.box(Vector3(0.055, 0.02, 0.38), Pal.BRASS, MeshKit.at(cp.x + sx, 0.51, cp.z))
	k.box(Vector3(0.36, 0.26, 0.3), Pal.BRASS.darkened(0.3), MeshKit.at(cp.x, 0.13, cp.z))


# ---------------------------------------------------------------- the café

## The café's look for era t (see ArchKit): a coffee cart under a striped
## canopy (0), a shipping-container café with a roof deck (1), a glass
## campus café with a big "Chat" neon (2), a brick-and-steel roastery loft
## (3), a graphite and brass sky lounge (4). The building keeps to the back
## (z < -0.35), the bar to its counter rect, the terrace stays open.
static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	match t:
		0: _garage(k)
		1: _workshop(k)
		2: _campus(k)
		3: _loft(k)
		_: _lounge(k)
	return k.commit()


static func _bx(k: MeshKit, size: Vector3, col: Color, x: float, y: float, z: float) -> void:
	k.box(size, col, MeshKit.at(x, y, z))


## Chalk scribbles on a board (local face frame, centred, facing +z).
static func _chalk(k: MeshKit, face: Transform3D, w: float, h: float, rows: int, seed := 0) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = 99 + seed
	for j in rows:
		var y := h * 0.5 - (j + 0.7) * h / (rows + 0.6)
		var x := -w * 0.42
		while x < w * 0.3:
			var l := r.randf_range(0.04, 0.16)
			k.box(Vector3(l, 0.018, 0.006), Color(0.93, 0.93, 0.9) if j > 0 else Color(0.98, 0.84, 0.5), face * MeshKit.xf(Vector3(x + l * 0.5, y + r.randf_range(-0.01, 0.01), 0.0), Vector3(0, 0, r.randf_range(-4, 4))))
			x += l + 0.03
		k.box(Vector3(0.06, 0.018, 0.006), Color(0.93, 0.93, 0.9), face * MeshKit.at(w * 0.4, y, 0.0))


# ---------------------------------------------------------------- 0 garage

static func _garage(k: MeshKit) -> void:
	var ply := Color(0.8, 0.66, 0.47)
	var ply2 := Color(0.7, 0.56, 0.4)
	var tin := Color(0.66, 0.68, 0.7)
	var dark := Color(0.22, 0.2, 0.19)
	var r := RandomNumberGenerator.new()
	r.seed = 77
	# ground: packed dirt with gravel patches and a tarp ground sheet
	_bx(k, Vector3(5.8, 0.02, 3.8), Color(0.62, 0.55, 0.44), 0, 0.01, 0)
	for i in 22:
		k.box(Vector3(r.randf_range(0.15, 0.5), 0.008, r.randf_range(0.1, 0.35)), Color(0.55, 0.49, 0.4) if i % 2 else Color(0.7, 0.66, 0.58), MeshKit.xf(Vector3(r.randf_range(-2.8, 2.8), 0.022, r.randf_range(-0.3, 1.8)), Vector3(0, r.randf_range(0, 180), 0)))
	for i in 9:
		k.sphere(0.06, Pal.GRASS_DARK, MeshKit.xf(Vector3(r.randf_range(-2.8, 2.8), 0.02, r.randf_range(1.6, 1.85)), Vector3.ZERO, Vector3(1.4, 0.8, 1.0)), 5, 3)
	# ---- the shack: plywood walls, a tin shed roof
	var z0 := -1.85
	var z1 := -0.45
	var hf := 2.3
	var hb := 2.02
	# back and side walls (plywood sheets with seams and battens)
	_bx(k, Vector3(5.7, hb, 0.05), ply2, 0, hb * 0.5, z0)
	for sx in [-1.0, 1.0]:
		k.prism(PackedVector2Array([Vector2(z0, 0), Vector2(z1, 0), Vector2(z1, hf), Vector2(z0, hb)]), 0.05, ply, Transform3D(Basis(Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)), Vector3(sx * 2.85 - 0.025, 0, 0)))
		for j in 3:
			_bx(k, Vector3(0.06, 2.0, 0.08), ply2, sx * 2.87, 1.0, z0 + 0.1 + j * 0.62)
	# the front wall: plywood on the left, planks on the right
	_bx(k, Vector3(3.3, hf, 0.05), ply, -1.2, hf * 0.5, z1)
	for i in 4:
		_bx(k, Vector3(0.02, hf, 0.06), ply2.darkened(0.15), -2.85 + i * 1.1, hf * 0.5, z1 + 0.01)
	ArchKit.planks(k, MeshKit.at(1.65, 0, z1), 2.4, hf, Color(0.66, 0.5, 0.34))
	# a hand-written chalkboard menu over the cart
	_bx(k, Vector3(1.7, 0.92, 0.05), Pal.WOOD_DARK, -1.25, 1.75, z1 + 0.04)
	_bx(k, Vector3(1.58, 0.8, 0.03), Color(0.18, 0.22, 0.2), -1.25, 1.75, z1 + 0.07)
	_chalk(k, MeshKit.at(-1.25, 1.75, z1 + 0.09), 1.5, 0.75, 5, 1)
	k.box(Vector3(0.12, 0.12, 0.01), Color(0.98, 0.84, 0.5), MeshKit.xf(Vector3(-0.62, 1.95, z1 + 0.09), Vector3(0, 0, 45)))
	# a doorway with a strip curtain, a window with a prop-up shutter
	_bx(k, Vector3(0.82, 1.9, 0.07), Pal.WOOD_DARK, 0.65, 0.95, z1 + 0.02)
	for i in 7:
		var cc: Color = [Color(0.86, 0.36, 0.3), Color(0.96, 0.8, 0.3), Color(0.3, 0.6, 0.86), Color(0.4, 0.7, 0.42)][i % 4]
		_bx(k, Vector3(0.09, 1.7, 0.02), cc, 0.35 + i * 0.1, 1.0, z1 + 0.07)
	_bx(k, Vector3(0.9, 0.62, 0.06), Pal.WOOD_DARK, 2.0, 1.45, z1 + 0.02)
	_bx(k, Vector3(0.78, 0.5, 0.04), Color(0.3, 0.26, 0.22), 2.0, 1.45, z1 + 0.05)
	k.box(Vector3(0.9, 0.62, 0.04), Color(0.66, 0.5, 0.34), MeshKit.xf(Vector3(2.0, 1.86, z1 + 0.28), Vector3(-62, 0, 0)))
	TownArt.beam(k, Vector3(1.62, 1.16, z1 + 0.06), Vector3(1.62, 1.74, z1 + 0.5), 0.025, Pal.WOOD_DARK)
	_bx(k, Vector3(1.0, 0.05, 0.18), Pal.WOOD, 2.0, 1.12, z1 + 0.1)
	for i in 3:
		k.cyl(0.05, 0.1, Color(0.7, 0.72, 0.74), MeshKit.at(1.75 + i * 0.25, 1.145, z1 + 0.1), 6)
		k.sphere(0.07, Pal.LEAF_LIGHT if i % 2 else Pal.LEAF, MeshKit.at(1.75 + i * 0.25, 1.3, z1 + 0.1), 6, 3)
	# mugs on hooks under the eave
	_bx(k, Vector3(1.4, 0.04, 0.04), Pal.WOOD_DARK, 2.0, 2.05, z1 + 0.06)
	for i in 6:
		k.cyl(0.035, 0.08, [Color(0.95, 0.95, 0.92), Color(0.86, 0.4, 0.32), Color(0.3, 0.5, 0.8)][i % 3], MeshKit.at(1.42 + i * 0.23, 1.9, z1 + 0.08), 6)
	# the tin roof: overlapping corrugated sheets, a rust patch, tyres, a stovepipe
	var ang := rad_to_deg(atan2(hf - hb, z1 - z0))
	for i in 6:
		var sx := -2.6 + i * 1.04
		var col := tin.darkened(0.05 * (i % 3)) if i != 4 else Color(0.62, 0.44, 0.32)
		ArchKit.corrugated(k, MeshKit.xf(Vector3(sx, hf + 0.03 + (i % 2) * 0.02, z1 + 0.18), Vector3(-90 - ang, 0, 0)), 1.1, z1 - z0 + 0.38, col, 0.14)
	for p in [Vector3(-0.6, 0, -0.8), Vector3(0.75, 0, -1.75)]:
		var y: float = hb + (hf - hb) * (p.z - z0) / (z1 - z0) + 0.1
		k.torus(0.2, 0.08, Pal.RUBBER, MeshKit.xf(Vector3(p.x, y, p.z), Vector3(-ang, 0, 0)), 10, 5)
	k.cyl(0.07, 1.2, Color(0.4, 0.4, 0.42), MeshKit.at(0.1, 2.0, -1.25), 8)
	k.cyl(0.12, 0.06, Color(0.32, 0.32, 0.34), MeshKit.at(0.1, 3.2, -1.25), 8)
	k.cone(0.14, 0.12, Color(0.32, 0.32, 0.34), MeshKit.at(0.1, 3.3, -1.25), 8)
	# a wifi dish and a hand-painted COFFEE board on the roof front
	k.cyl(0.015, 0.7, Color(0.7, 0.72, 0.74), MeshKit.at(-0.4, 2.3, -1.85), 4)
	k.cyl(0.12, 0.04, Color(0.92, 0.92, 0.9), MeshKit.xf(Vector3(-0.4, 3.0, -1.82), Vector3(70, 0, 0)), 8)
	for sx in [-0.85, 0.85]:
		_bx(k, Vector3(0.06, 0.6, 0.06), Pal.WOOD_DARK, sx, 2.55, -0.6)
	k.box(Vector3(2.0, 0.42, 0.05), Color(0.94, 0.9, 0.8), MeshKit.xf(Vector3(0, 2.72, -0.56), Vector3(0, 0, 1.5)))
	TownArt.word(k, MeshKit.xf(Vector3(-0.1, 2.6, -0.53), Vector3(0, 0, 1.5)), "COFFEE", 0.24, Color(0.62, 0.26, 0.2), 0.16, 0.02)
	k.cyl(0.07, 0.03, Color(0.36, 0.22, 0.14), MeshKit.xf(Vector3(1.05, 2.8, -0.53), Vector3(90, 0, 0)), 8)
	# ---- the coffee cart at the counter
	var cream := Color(0.94, 0.9, 0.8)
	var red := Color(0.74, 0.3, 0.26)
	_bx(k, Vector3(1.9, 0.62, 0.56), cream, -1.32, 0.68, -0.03)
	_bx(k, Vector3(1.92, 0.08, 0.58), red, -1.32, 0.42, -0.03)
	_bx(k, Vector3(1.92, 0.05, 0.58), red, -1.32, 0.92, -0.03)
	for i in 4:
		_bx(k, Vector3(0.02, 0.44, 0.02), cream.darkened(0.1), -2.2 + i * 0.58, 0.68, 0.26)
	_bx(k, Vector3(2.04, 0.05, 0.7), Pal.WOOD, -1.32, 1.01, 0.0)
	# the front panel: a chalk COFFEE sign and a cup
	_bx(k, Vector3(0.9, 0.3, 0.02), Color(0.18, 0.22, 0.2), -1.0, 0.68, 0.26)
	_chalk(k, MeshKit.at(-1.0, 0.68, 0.275), 0.84, 0.26, 2, 4)
	k.cyl(0.06, 0.1, Color(0.96, 0.96, 0.94), MeshKit.xf(Vector3(-1.85, 0.68, 0.27), Vector3(90, 0, 0)), 8)
	# a big spoked wheel, a prop leg, the handle
	var wc := Vector3(-1.95, 0.34, 0.3)
	k.torus(0.3, 0.035, Pal.WOOD_DARK, MeshKit.xf(wc, Vector3(90, 0, 0)), 14, 4)
	k.cyl(0.06, 0.06, Pal.STEEL_DARK, MeshKit.xf(wc - Vector3(0, 0, 0.03), Vector3(90, 0, 0)), 6)
	for i in 6:
		k.box(Vector3(0.025, 0.58, 0.025), Pal.WOOD_DARK, MeshKit.xf(wc, Vector3(0, 0, i * 30.0)))
	_bx(k, Vector3(0.05, 0.38, 0.05), Pal.STEEL_DARK, -0.5, 0.19, 0.0)
	TownArt.beam(k, Vector3(-0.36, 0.6, -0.2), Vector3(-0.15, 0.75, -0.2), 0.04, Pal.STEEL_DARK)
	TownArt.beam(k, Vector3(-0.36, 0.6, 0.15), Vector3(-0.15, 0.75, 0.15), 0.04, Pal.STEEL_DARK)
	_bx(k, Vector3(0.05, 0.05, 0.4), Pal.WOOD_DARK, -0.15, 0.75, -0.02)
	# on the cart: an espresso machine, a grinder, cups, a cake dome, jars
	var em := Vector3(-1.45, 1.035, -0.12)
	_bx(k, Vector3(0.5, 0.34, 0.3), Color(0.8, 0.82, 0.84), em.x, em.y + 0.17, em.z)
	_bx(k, Vector3(0.52, 0.04, 0.32), Color(0.62, 0.26, 0.22), em.x, em.y + 0.36, em.z)
	for sx in [-0.12, 0.12]:
		k.cyl(0.04, 0.06, Pal.STEEL_DARK, MeshKit.at(em.x + sx, em.y + 0.1, em.z + 0.17), 6)
		_bx(k, Vector3(0.03, 0.03, 0.14), Pal.RUBBER, em.x + sx, em.y + 0.1, em.z + 0.26)
	_bx(k, Vector3(0.44, 0.02, 0.1), Pal.STEEL_DARK, em.x, em.y + 0.01, em.z + 0.2)
	for i in 4:
		k.cyl(0.03, 0.06, Color(0.96, 0.96, 0.94), MeshKit.at(em.x - 0.15 + i * 0.1, em.y + 0.38, em.z), 6)
	k.cyl(0.07, 0.24, Color(0.24, 0.24, 0.26), MeshKit.at(-0.95, 1.035, -0.15), 8)
	k.cone(0.09, 0.14, Color(0.6, 0.66, 0.7), MeshKit.xf(Vector3(-0.95, 1.42, -0.15), Vector3(180, 0, 0)), 8)
	k.cyl(0.09, 0.03, Color(0.36, 0.22, 0.14), MeshKit.at(-0.95, 1.4, -0.15), 8)
	for i in 3:
		k.cyl(0.045, 0.12 + i * 0.03, Color(0.96, 0.96, 0.94), MeshKit.at(-2.15 + i * 0.1, 1.035, 0.1), 6)
	k.cyl(0.14, 0.02, Color(0.9, 0.9, 0.88), MeshKit.at(-0.65, 1.035, 0.08), 8)
	k.sphere(0.13, Color(0.8, 0.9, 0.95, 0.75), MeshKit.xf(Vector3(-0.65, 1.05, 0.08), Vector3.ZERO, Vector3(1, 0.8, 1)), 8, 4)
	k.cyl(0.08, 0.06, Color(0.86, 0.66, 0.42), MeshKit.at(-0.65, 1.055, 0.08), 8)
	k.cyl(0.05, 0.12, Color(0.8, 0.9, 0.95, 0.8), MeshKit.at(-1.85, 1.035, 0.12), 6)
	for i in 4:
		k.cyl(0.025, 0.14, [Color(0.86, 0.5, 0.3), Color(0.5, 0.3, 0.22), Color(0.9, 0.8, 0.4), Color(0.4, 0.6, 0.4)][i], MeshKit.at(-2.15 + i * 0.07, 1.035, -0.15), 5)
	# the striped cart canopy on four poles
	for sx in [-2.3, -0.38]:
		for sz in [-0.28, 0.28]:
			k.cyl(0.02, 0.9, Color(0.86, 0.86, 0.84), MeshKit.at(sx, 1.03, sz), 5)
	for i in 8:
		k.box(Vector3(0.25, 0.03, 0.8), red if i % 2 == 0 else cream, MeshKit.xf(Vector3(-2.2 + i * 0.25, 1.98, 0.0), Vector3(-8, 0, 0)))
	for i in 8:
		k.box(Vector3(0.25, 0.12, 0.02), red if i % 2 == 1 else cream, MeshKit.at(-2.2 + i * 0.25, 1.88, 0.41))
	# a bulb on a cord over the cart
	k.cyl(0.006, 0.4, dark, MeshKit.at(-1.32, 1.55, 0.05), 3)
	k.sphere(0.06, Color(1.0, 0.85, 0.55, 0.3), MeshKit.at(-1.32, 1.52, 0.05), 6, 3)
	# ---- crates and sacks of beans in the left corner
	for i in 3:
		TownArt.crate(k, Vector3(-2.65, (i / 2) * 0.42, -0.22 + (i % 2) * 0.45 - (i / 2) * 0.2), 0.42, (i * 17) % 20 - 10)
	TownArt.sacks(k, Vector3(-2.35, 0.0, 0.3), 2)
	# ---- right yard: a folding table with an urn, a laptop; a generator
	var ft := Vector3(1.95, 0, -0.1)
	_bx(k, Vector3(1.1, 0.04, 0.5), Color(0.92, 0.92, 0.9), ft.x, 0.74, ft.z)
	for sx in [-0.48, 0.48]:
		TownArt.beam(k, ft + Vector3(sx, 0, -0.2), ft + Vector3(sx, 0.72, 0.2), 0.025, Color(0.5, 0.52, 0.54))
		TownArt.beam(k, ft + Vector3(sx, 0, 0.2), ft + Vector3(sx, 0.72, -0.2), 0.025, Color(0.5, 0.52, 0.54))
	k.cyl(0.11, 0.32, Color(0.78, 0.8, 0.82), MeshKit.at(ft.x - 0.35, 0.76, ft.z), 8, 0.02)
	_bx(k, Vector3(0.04, 0.04, 0.06), Pal.RUBBER, ft.x - 0.35, 0.84, ft.z + 0.13)
	_bx(k, Vector3(0.3, 0.015, 0.22), Color(0.3, 0.32, 0.36), ft.x + 0.05, 0.765, ft.z + 0.04)
	k.box(Vector3(0.3, 0.2, 0.012), Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(ft.x + 0.05, 0.86, ft.z - 0.08), Vector3(-15, 0, 0)))
	k.box(Vector3(0.26, 0.16, 0.004), Color(0.5, 0.86, 1.0, 0.45), MeshKit.xf(Vector3(ft.x + 0.05, 0.86, ft.z - 0.072), Vector3(-15, 0, 0)))
	for i in 3:
		k.cyl(0.04, 0.16, Color(0.96, 0.96, 0.94), MeshKit.at(ft.x + 0.32 + (i % 2) * 0.09, 0.76, ft.z + (i / 2) * 0.1 - 0.05), 6)
	for i in 2:
		k.box(Vector3(0.36, 0.26, 0.28), [Color(0.3, 0.5, 0.8), Color(0.86, 0.36, 0.3)][i], MeshKit.xf(Vector3(ft.x - 0.2 + i * 0.4, 0.13, ft.z), Vector3(0, i * 12, 0)))
	var gen := Vector3(2.62, 0, 0.12)
	_bx(k, Vector3(0.44, 0.34, 0.32), Color(0.84, 0.3, 0.24), gen.x, 0.2, gen.z)
	for sx in [-0.2, 0.2]:
		_bx(k, Vector3(0.03, 0.4, 0.34), Pal.STEEL_DARK, gen.x + sx, 0.22, gen.z)
	_bx(k, Vector3(0.44, 0.03, 0.03), Pal.STEEL_DARK, gen.x, 0.42, gen.z)
	k.cyl(0.03, 0.08, Pal.STEEL_DARK, MeshKit.at(gen.x + 0.1, 0.37, gen.z), 5)
	k.cyl(0.1, 0.5, Color(0.3, 0.5, 0.86), MeshKit.at(2.75, 0.0, -0.3), 8, 0.03)
	k.cyl(0.03, 0.06, Pal.STEEL_DARK, MeshKit.at(2.75, 0.5, -0.3), 5)
	# the extension cord from the generator to the cart
	ArchKit.pipes(k, [Vector3(2.45, 0.2, 0.2), Vector3(2.2, 0.025, 0.3), Vector3(0.2, 0.025, 0.32), Vector3(-0.25, 0.025, 0.3), Vector3(-0.4, 0.5, 0.25)], 0.012, Color(0.96, 0.6, 0.2))
	# an A-frame chalkboard by the cart
	var af := MeshKit.xf(Vector3(0.05, 0, 0.4), Vector3(0, -20, 0))
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.44, 0.7, 0.03), Pal.WOOD_DARK, af * MeshKit.xf(Vector3(0, 0.34, sz * 0.09), Vector3(sz * -12.0, 0, 0)))
	k.box(Vector3(0.36, 0.56, 0.01), Color(0.18, 0.22, 0.2), af * MeshKit.xf(Vector3(0, 0.36, 0.115), Vector3(-12, 0, 0)))
	_chalk(k, af * MeshKit.xf(Vector3(0, 0.36, 0.125), Vector3(-12, 0, 0)), 0.32, 0.5, 4, 7)
	# ---- string lights from the eaves out to two front poles
	var pl := Vector3(-2.25, 0, 1.86)
	var pr := Vector3(1.22, 0, 1.86)
	for p in [pl, pr]:
		k.box(Vector3(0.08, 2.25, 0.08), Pal.WOOD, MeshKit.at(p.x, 1.125, p.z))
		k.box(Vector3(0.24, 0.06, 0.24), Pal.WOOD_DARK, MeshKit.at(p.x, 0.03, p.z))
	var gl := Color(1.0, 0.82, 0.5)
	ArchKit.string_lights(k, Vector3(-2.8, 2.28, -0.4), pl + Vector3(0, 2.2, 0), 7, gl)
	ArchKit.string_lights(k, pl + Vector3(0, 2.2, 0), pr + Vector3(0, 2.2, 0), 8, gl)
	ArchKit.string_lights(k, pr + Vector3(0, 2.2, 0), Vector3(2.8, 2.28, -0.4), 7, gl)
	ArchKit.string_lights(k, Vector3(-0.3, 2.3, -0.4), pl + Vector3(0, 2.2, 0), 7, gl)
	ArchKit.string_lights(k, Vector3(-0.3, 2.3, -0.4), pr + Vector3(0, 2.2, 0), 7, gl)


# ---------------------------------------------------------------- 1 workshop

static func _workshop(k: MeshKit) -> void:
	var rust := Color(0.66, 0.32, 0.24)
	var ochre := Color(0.88, 0.66, 0.24)
	var yel := Color(0.96, 0.76, 0.2)
	var steel := Color(0.36, 0.38, 0.42)
	var dark := Color(0.16, 0.17, 0.19)
	# ground: concrete with joints, tyre marks, a turf mat under the tables
	_bx(k, Vector3(5.8, 0.02, 3.8), Color(0.74, 0.74, 0.72), 0, 0.01, 0)
	for i in 5:
		_bx(k, Vector3(0.012, 0.006, 3.8), Color(0.64, 0.64, 0.62), -2.4 + i * 1.2, 0.022, 0)
	_bx(k, Vector3(5.8, 0.006, 0.012), Color(0.64, 0.64, 0.62), 0, 0.022, 0.5)
	_bx(k, Vector3(3.6, 0.012, 1.45), Color(0.42, 0.6, 0.36), -0.4, 0.026, 1.18)
	for i in 12:
		_bx(k, Vector3(0.012, 0.004, 1.45), Color(0.38, 0.54, 0.32), -2.15 + i * 0.32, 0.034, 1.18)
	_bx(k, Vector3(5.8, 0.012, 0.08), yel, 0, 0.026, 1.86)
	# ---- the main container (20 ft), rust red, along the back
	var z0 := -1.86
	var z1 := -0.42
	var h := 2.32
	var cz := (z0 + z1) * 0.5
	_container(k, Vector3(0, 0.06, cz), 5.76, h, z1 - z0, rust, false)
	# the serving hatch: an opening, the rolled-up shutter, a fold-down counter
	_bx(k, Vector3(2.5, 1.06, 0.04), dark, -1.3, 1.5, z1 + 0.02)
	_bx(k, Vector3(2.62, 0.2, 0.22), Color(0.6, 0.62, 0.64), -1.3, 2.12, z1 + 0.1)
	for i in 3:
		_bx(k, Vector3(2.5, 0.03, 0.03), Color(0.5, 0.52, 0.54), -1.3, 2.02 - i * 0.04, z1 + 0.2)
	for sx in [-1.0, 1.0]:
		_bx(k, Vector3(0.06, 1.1, 0.08), steel, -1.3 + sx * 1.28, 1.5, z1 + 0.04)
	_bx(k, Vector3(2.6, 0.06, 0.42), Pal.WOOD_LIGHT, -1.3, 0.98, z1 + 0.21)
	for sx in [-1.1, -0.0, 1.1]:
		TownArt.beam(k, Vector3(-1.3 + sx, 0.6, z1 + 0.02), Vector3(-1.3 + sx, 0.95, z1 + 0.38), 0.04, steel)
	# behind the hatch: shelves, a big espresso machine, a menu lightbox
	_bx(k, Vector3(2.3, 0.04, 0.2), steel, -1.3, 1.6, z1 - 0.08)
	for i in 8:
		k.cyl(0.04, 0.1 + (i % 3) * 0.03, [Color(0.95, 0.95, 0.94), Color(0.4, 0.26, 0.18), Color(0.86, 0.66, 0.3)][i % 3], MeshKit.at(-2.3 + i * 0.28, 1.62, z1 - 0.08), 6)
	_bx(k, Vector3(0.62, 0.36, 0.28), Color(0.82, 0.84, 0.86), -1.0, 1.2, z1 - 0.1)
	_bx(k, Vector3(0.64, 0.04, 0.3), Color(0.2, 0.2, 0.22), -1.0, 1.4, z1 - 0.1)
	for sx in [-0.18, 0.0, 0.18]:
		k.cyl(0.035, 0.07, dark, MeshKit.at(-1.0 + sx, 1.07, z1 + 0.03), 6)
	k.cyl(0.07, 0.3, dark, MeshKit.at(-1.75, 1.01, z1 - 0.05), 8)
	k.cone(0.09, 0.14, Color(0.6, 0.66, 0.7), MeshKit.xf(Vector3(-1.75, 1.45, z1 - 0.05), Vector3(180, 0, 0)), 8)
	_bx(k, Vector3(2.0, 0.42, 0.06), dark, -1.3, 2.48, z1 + 0.06)
	_bx(k, Vector3(1.9, 0.34, 0.02), Color(1.0, 0.95, 0.82, 0.55), -1.3, 2.48, z1 + 0.1)
	for j in 3:
		for i in 3:
			_bx(k, Vector3(0.42, 0.03, 0.01), Color(0.2, 0.2, 0.22), -1.95 + i * 0.65, 2.58 - j * 0.09, z1 + 0.115)
	for sx in [-1.95, -0.65]:
		k.cyl(0.006, 0.3, dark, MeshKit.at(sx, 1.7, z1 - 0.15), 3)
		k.sphere(0.06, Color(1.0, 0.85, 0.55, 0.3), MeshKit.at(sx, 1.68, z1 - 0.15), 6, 3)
	# bar stools along the counter
	for i in 4:
		var bx := -2.2 + i * 0.6
		k.cyl(0.14, 0.05, yel, MeshKit.at(bx, 0.72, 0.12), 8)
		k.cyl(0.025, 0.7, steel, MeshKit.at(bx, 0.02, 0.12), 5)
		k.cyl(0.15, 0.02, steel, MeshKit.at(bx, 0.02, 0.12), 8)
		k.torus(0.11, 0.012, steel, MeshKit.at(bx, 0.32, 0.12), 8, 3)
	# the right end: a glass door, a window, a split AC, a meter, conduits
	_bx(k, Vector3(0.84, 2.0, 0.05), steel, 0.55, 1.06, z1 + 0.02)
	_bx(k, Vector3(0.7, 1.86, 0.04), Color(0.6, 0.76, 0.86, 0.7), 0.55, 1.05, z1 + 0.05)
	_bx(k, Vector3(0.04, 0.5, 0.05), Color(0.8, 0.82, 0.84), 0.82, 1.05, z1 + 0.08)
	_bx(k, Vector3(1.1, 0.7, 0.05), steel, 1.75, 1.5, z1 + 0.02)
	_bx(k, Vector3(1.0, 0.6, 0.04), Color(0.6, 0.76, 0.86, 0.7), 1.75, 1.5, z1 + 0.05)
	_bx(k, Vector3(0.03, 0.6, 0.05), steel, 1.75, 1.5, z1 + 0.07)
	_bx(k, Vector3(0.7, 0.24, 0.18), Color(0.94, 0.94, 0.92), 1.75, 2.08, z1 + 0.1)
	_bx(k, Vector3(0.66, 0.03, 0.04), Color(0.7, 0.72, 0.74), 1.75, 1.97, z1 + 0.18)
	_bx(k, Vector3(0.26, 0.36, 0.1), Color(0.86, 0.87, 0.88), 2.58, 1.1, z1 + 0.06)
	_bx(k, Vector3(0.14, 0.1, 0.02), Color(0.2, 0.22, 0.24), 2.58, 1.18, z1 + 0.12)
	ArchKit.pipes(k, [Vector3(2.58, 1.3, z1 + 0.06), Vector3(2.58, 2.22, z1 + 0.06), Vector3(-2.7, 2.22, z1 + 0.06)], 0.02, Color(0.6, 0.62, 0.64))
	ArchKit.pipes(k, [Vector3(1.4, 2.08, z1 + 0.1), Vector3(1.25, 2.08, z1 + 0.1), Vector3(1.25, 0.3, z1 + 0.1), Vector3(1.4, 0.3, z1 + 0.2)], 0.02, Color(0.94, 0.94, 0.92))
	# an OPEN neon in the window and bunting along the deck
	TownArt.word(k, MeshKit.at(1.75, 1.36, z1 + 0.09), "OPEN", 0.18, Color(1.0, 0.42, 0.5, 0.35), 0.16, 0.02)
	for i in 12:
		var bp := Vector3(0.15 + i * 0.22, h + 0.98 - sin(float(i) / 11.0 * PI) * 0.12, z1 - 0.02)
		k.prism(PackedVector2Array([Vector2(-0.07, 0), Vector2(0.07, 0), Vector2(0, -0.14)]), 0.01, [Color(0.86, 0.3, 0.26), yel, Color(0.3, 0.5, 0.86), Color(0.4, 0.7, 0.42)][i % 4], Transform3D(Basis(Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)), bp))
	# a menu board on legs beside the door
	var mb := MeshKit.xf(Vector3(1.55, 0, 0.05), Vector3(0, -15, 0))
	for sx in [-0.28, 0.28]:
		k.box(Vector3(0.04, 1.3, 0.04), steel, mb * MeshKit.at(sx, 0.65, 0))
	k.box(Vector3(0.66, 0.8, 0.04), dark, mb * MeshKit.at(0, 0.95, 0))
	k.box(Vector3(0.6, 0.12, 0.01), yel, mb * MeshKit.at(0, 1.27, 0.025))
	for j in 5:
		k.box(Vector3(0.36, 0.03, 0.01), Color(0.95, 0.95, 0.94), mb * MeshKit.at(-0.08, 1.12 - j * 0.1, 0.025))
		k.box(Vector3(0.08, 0.03, 0.01), yel, mb * MeshKit.at(0.2, 1.12 - j * 0.1, 0.025))
	# ---- the stacked 10 ft container (ochre) on the left, a window, a logo
	var uz := cz
	_container(k, Vector3(-1.45, h + 0.06, uz), 2.9, h - 0.1, z1 - z0, ochre, true)
	_bx(k, Vector3(1.3, 0.7, 0.06), steel, -1.65, h + 1.25, z1 + 0.02)
	_bx(k, Vector3(1.2, 0.6, 0.04), Color(0.6, 0.76, 0.86, 0.7), -1.65, h + 1.25, z1 + 0.05)
	_bx(k, Vector3(0.03, 0.6, 0.05), steel, -1.65, h + 1.25, z1 + 0.07)
	k.rbox(Vector3(0.9, 0.5, 0.06), 0.2, Color(0.96, 0.96, 0.94), MeshKit.at(-0.45, h + 1.55, z1 + 0.05), 1)
	k.prism(PackedVector2Array([Vector2(-0.1, 0), Vector2(0.12, 0), Vector2(-0.16, 0.2)]), 0.05, Color(0.96, 0.96, 0.94), MeshKit.xf(Vector3(-0.55, h + 1.31, z1 + 0.03), Vector3(90, 0, 180)))
	for i in 3:
		k.sphere(0.06, Color(0.4, 0.9, 0.6, 0.4), MeshKit.at(-0.69 + i * 0.24, h + 1.55, z1 + 0.09), 6, 3)
	# ---- the roof deck on the right: planks, yellow rails, a parasol, a crate bar
	var dy := h + 0.1
	for i in 9:
		_bx(k, Vector3(2.8, 0.03, 0.15), Pal.WOOD_LIGHT.darkened(0.05 * (i % 3)), 1.45, dy + 0.015, z0 + 0.1 + i * 0.16)
	ArchKit.railing(k, Vector3(0.08, dy, z1 - 0.04), Vector3(1.85, dy, z1 - 0.04), 0.95, yel, 0.6)
	ArchKit.railing(k, Vector3(2.84, dy, z1 - 0.04), Vector3(2.84, dy, z0 + 0.04), 0.95, yel, 0.6)
	ArchKit.railing(k, Vector3(2.84, dy, z0 + 0.04), Vector3(0.08, dy, z0 + 0.04), 0.95, yel, 0.6)
	TownArt.umbrella(k, Vector3(0.55, dy, -0.82), 1.5, 0.5, yel, Color(0.96, 0.96, 0.94), steel)
	for sx in [0.3, 0.8]:
		k.cyl(0.11, 0.04, Color(0.3, 0.5, 0.86), MeshKit.at(sx, dy + 0.4, -0.75), 8)
		k.cyl(0.02, 0.4, steel, MeshKit.at(sx, dy, -0.75), 4)
	TownArt.crate(k, Vector3(0.55, dy, -0.85), 0.3)
	# a string of cage lamps along the deck rail
	for i in 4:
		k.sphere(0.05, Color(1.0, 0.85, 0.55, 0.3), MeshKit.at(0.3 + i * 0.5, dy + 1.0, z1 - 0.04), 6, 3)
	# ---- the stair up to the deck along the front, steel with yellow rails
	TownArt.stair(k, Vector3(0.95, 0.02, -0.12), Vector3(2.75, dy, -0.12), 0.5, Color(0.56, 0.58, 0.6), steel, yel)
	for sx in [1.5, 2.2]:
		_bx(k, Vector3(0.06, (sx - 0.95) / 1.8 * dy, 0.06), steel, sx, (sx - 0.95) / 1.8 * dy * 0.5, -0.12)
	# ---- the right yard: an AC condenser, bins, a beans pallet, chain-link
	ArchKit.ac_unit(k, MeshKit.xf(Vector3(2.45, 0.02, 0.15), Vector3(0, 90, 0)), 1, 0.6)
	ArchKit.pipes(k, [Vector3(2.3, 0.3, 0.0), Vector3(2.3, 0.3, -0.38), Vector3(2.3, 1.95, -0.38)], 0.02, Color(0.94, 0.94, 0.92))
	for i in 2:
		_bx(k, Vector3(0.36, 0.5, 0.34), [Color(0.3, 0.5, 0.36), Color(0.3, 0.42, 0.66)][i], -2.65, 0.27, -0.15 + i * 0.42)
		_bx(k, Vector3(0.38, 0.04, 0.36), [Color(0.24, 0.42, 0.3), Color(0.24, 0.34, 0.56)][i], -2.65, 0.54, -0.15 + i * 0.42)
	ArchKit.fence(k, Vector3(2.87, 0.0, 0.3), Vector3(2.87, 0.0, -0.36), 1, 1.0)
	# floodlights and a cable tray on the container
	ArchKit.cable_tray(k, Vector3(-2.7, h + 0.02, z1 + 0.18), Vector3(-0.1, h + 0.02, z1 + 0.18), 1)
	for sx in [-2.4, 2.6]:
		TownArt.floodlight(k, MeshKit.xf(Vector3(sx, h - 0.1, z1 + 0.1), Vector3(0, 0, 0)))


## A shipping container (centre of its floor at c, length along x).
static func _container(k: MeshKit, c: Vector3, l: float, h: float, d: float, col: Color, small: bool) -> void:
	var rail := col.darkened(0.25)
	_bx(k, Vector3(l, h, d), col, c.x, c.y + h * 0.5, c.z)
	# ribs on the back and the ends
	for i in int(l / 0.18):
		_bx(k, Vector3(0.07, h - 0.24, 0.03), col.darkened(0.12), c.x - l * 0.5 + 0.12 + i * 0.18, c.y + h * 0.5, c.z - d * 0.5 - 0.012)
	if small:
		for i in int(l / 0.18):
			_bx(k, Vector3(0.07, h - 0.24, 0.03), col.darkened(0.12), c.x - l * 0.5 + 0.12 + i * 0.18, c.y + h * 0.5, c.z + d * 0.5 + 0.012)
	for i in int(d / 0.18):
		_bx(k, Vector3(0.03, h - 0.24, 0.07), col.darkened(0.12), c.x - l * 0.5 - 0.012, c.y + h * 0.5, c.z - d * 0.5 + 0.12 + i * 0.18)
	# rails and corner posts with castings
	for sy in [0.06, h - 0.06]:
		_bx(k, Vector3(l + 0.02, 0.12, 0.08), rail, c.x, c.y + sy, c.z + d * 0.5 - 0.03)
		_bx(k, Vector3(l + 0.02, 0.12, 0.08), rail, c.x, c.y + sy, c.z - d * 0.5 + 0.03)
		_bx(k, Vector3(0.08, 0.12, d), rail, c.x - l * 0.5 + 0.03, c.y + sy, c.z)
		_bx(k, Vector3(0.08, 0.12, d), rail, c.x + l * 0.5 - 0.03, c.y + sy, c.z)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			_bx(k, Vector3(0.12, h, 0.12), rail, c.x + sx * (l * 0.5 - 0.05), c.y + h * 0.5, c.z + sz * (d * 0.5 - 0.05))
			for sy in [0.07, h - 0.07]:
				_bx(k, Vector3(0.15, 0.14, 0.15), rail.darkened(0.2), c.x + sx * (l * 0.5 - 0.06), c.y + sy, c.z + sz * (d * 0.5 - 0.06))
	# the door end (+x): two leaves, four locking bars with handles
	var ex := c.x + l * 0.5 + 0.015
	_bx(k, Vector3(0.02, h - 0.3, 0.012), rail, ex, c.y + h * 0.5, c.z)
	for i in 4:
		var z := c.z - d * 0.38 + i * d * 0.253
		_bx(k, Vector3(0.03, h - 0.3, 0.03), Color(0.62, 0.64, 0.66), ex + 0.01, c.y + h * 0.5, z)
		_bx(k, Vector3(0.04, 0.04, 0.16), Color(0.62, 0.64, 0.66), ex + 0.03, c.y + h * 0.42, z + 0.06)
	# a stencilled code on the back
	_bx(k, Vector3(0.9, 0.12, 0.01), Color(0.92, 0.9, 0.86), c.x + l * 0.3, c.y + h - 0.35, c.z - d * 0.5 - 0.03)


# ---------------------------------------------------------------- 2 campus

static func _campus(k: MeshKit) -> void:
	var white := Color(0.95, 0.95, 0.96)
	var white2 := Color(0.86, 0.88, 0.9)
	var teal := Color(0.3, 0.66, 0.68)
	var glass := Color(0.58, 0.8, 0.92, 0.66)
	var frame := Color(0.7, 0.73, 0.76)
	var dark := Color(0.26, 0.29, 0.33)
	var wood := Color(0.7, 0.54, 0.38)
	# ground: pale pavers, a timber deck under the tables, lawn edges, a kerb
	_bx(k, Vector3(5.8, 0.02, 3.8), Color(0.84, 0.84, 0.82), 0, 0.01, 0)
	for i in 15:
		_bx(k, Vector3(0.01, 0.005, 3.8), Color(0.76, 0.76, 0.74), -2.8 + i * 0.4, 0.022, 0)
	for j in 10:
		_bx(k, Vector3(5.8, 0.005, 0.01), Color(0.76, 0.76, 0.74), 0, 0.022, -1.8 + j * 0.4)
	for i in 10:
		_bx(k, Vector3(3.6, 0.02, 0.135), wood.darkened(0.04 * (i % 3)), -0.43, 0.025, 0.5 + i * 0.145)
	for sx in [-1.0, 1.0]:
		_bx(k, Vector3(0.5, 0.03, 2.2), Color(0.48, 0.62, 0.38), sx * 2.62, 0.02, 0.75)
	_bx(k, Vector3(5.8, 0.06, 0.1), Color(0.92, 0.92, 0.92), 0, 0.03, 1.85)
	# ---- ground floor: a glass box with white piers
	var z0 := -1.86
	var z1 := -0.42
	var cz := (z0 + z1) * 0.5
	var h1 := 2.5
	_bx(k, Vector3(5.76, h1, z1 - z0), white, 0, h1 * 0.5 + 0.02, cz)
	ArchKit.curtain(k, MeshKit.at(1.35, 0.06, z1 + 0.01), 3.0, h1 - 0.12, 2, 5, 3)
	ArchKit.curtain(k, MeshKit.at(-1.3, 0.06, z1 + 0.01), 2.3, h1 - 0.12, 2, 4, 2)
	for x in [-2.6, -0.15, 2.7]:
		_bx(k, Vector3(0.2, h1, 0.1), white, x, h1 * 0.5 + 0.02, z1 + 0.05)
	# the main door with a lit frame
	_bx(k, Vector3(0.96, 2.1, 0.08), dark, 0.42, 1.07, z1 + 0.09)
	for sx in [-0.22, 0.22]:
		_bx(k, Vector3(0.42, 2.0, 0.04), glass, 0.42 + sx, 1.02, z1 + 0.14)
		_bx(k, Vector3(0.03, 0.6, 0.05), Color(0.86, 0.87, 0.88), 0.42 + sx * 0.18, 1.05, z1 + 0.17)
	# ---- the coffee bar (counter rect): a white kiosk with an open front
	var bx0 := -2.42
	var bx1 := -0.18
	var bz := 0.3
	for x in [bx0 + 0.06, bx1 - 0.06]:
		_bx(k, Vector3(0.12, 2.3, 0.12), white, x, 1.17, bz - 0.06)
	_bx(k, Vector3(bx1 - bx0 + 0.1, 0.16, bz - z1 + 0.06), white, (bx0 + bx1) * 0.5, 2.38, (bz + z1) * 0.5)
	_bx(k, Vector3(bx1 - bx0 + 0.12, 0.08, 0.04), teal, (bx0 + bx1) * 0.5, 2.36, bz + 0.03)
	_bx(k, Vector3(bx1 - bx0 - 0.2, 0.02, 0.4), Color(1.0, 0.98, 0.92, 0.5), (bx0 + bx1) * 0.5, 2.29, (bz + z1) * 0.5)
	for x in [bx0 + 0.06, bx1 - 0.06]:
		_bx(k, Vector3(0.04, 2.2, bz - z1 - 0.12), glass, x, 1.15, (bz + z1) * 0.5 - 0.03)
	# the counter: white front, oak top, glowing pastry case, espresso machine
	_bx(k, Vector3(bx1 - bx0 - 0.24, 0.98, 0.32), white, (bx0 + bx1) * 0.5, 0.51, bz - 0.2)
	_bx(k, Vector3(bx1 - bx0 - 0.24, 0.05, 0.4), wood, (bx0 + bx1) * 0.5, 1.02, bz - 0.2)
	for i in 6:
		_bx(k, Vector3(0.02, 0.8, 0.02), white2, bx0 + 0.32 + i * 0.32, 0.5, bz - 0.035)
	_bx(k, Vector3(bx1 - bx0 - 0.3, 0.04, 0.02), teal, (bx0 + bx1) * 0.5, 0.12, bz - 0.03)
	_bx(k, Vector3(0.62, 0.3, 0.32), Color(0.8, 0.92, 0.96, 0.6), -1.95, 1.2, bz - 0.2)
	for i in 6:
		k.sphere(0.045, [Color(0.86, 0.66, 0.42), Color(0.9, 0.5, 0.5), Color(0.5, 0.32, 0.22)][i % 3], MeshKit.xf(Vector3(-2.15 + (i % 3) * 0.2, 1.1 + (i / 3) * 0.12, bz - 0.2), Vector3.ZERO, Vector3(1.2, 0.6, 1.2)), 6, 3)
	_bx(k, Vector3(0.56, 0.36, 0.3), Color(0.82, 0.84, 0.86), -1.15, 1.23, bz - 0.24)
	_bx(k, Vector3(0.58, 0.04, 0.32), teal, -1.15, 1.43, bz - 0.24)
	for sx in [-0.15, 0.0, 0.15]:
		k.cyl(0.035, 0.06, dark, MeshKit.at(-1.15 + sx, 1.1, bz - 0.06), 6)
	k.cyl(0.07, 0.28, dark, MeshKit.at(-0.62, 1.045, bz - 0.25), 8)
	k.cone(0.09, 0.14, Color(0.6, 0.66, 0.7), MeshKit.xf(Vector3(-0.62, 1.47, bz - 0.25), Vector3(180, 0, 0)), 8)
	for i in 4:
		k.cyl(0.04, 0.1, white, MeshKit.at(-0.4 + (i % 2) * 0.09, 1.045 + (i / 2) * 0.1, bz - 0.12), 6)
	# a menu of three glowing screens on the back wall, a cup shelf
	for i in 3:
		_bx(k, Vector3(0.6, 0.38, 0.04), dark, -1.95 + i * 0.68, 1.9, z1 + 0.03)
		_bx(k, Vector3(0.54, 0.32, 0.02), Color([0.5, 0.86, 1.0][0], [0.86, 1.0, 0.8][i % 3], 0.9, 0.5), -1.95 + i * 0.68, 1.9, z1 + 0.06)
		for j in 3:
			_bx(k, Vector3(0.36, 0.025, 0.01), white, -2.0 + i * 0.68, 1.98 - j * 0.07, z1 + 0.075)
	_bx(k, Vector3(2.0, 0.03, 0.16), wood, -1.3, 1.5, z1 + 0.08)
	for i in 9:
		k.cyl(0.035, 0.08, [white, teal, Color(0.98, 0.7, 0.3)][i % 3], MeshKit.at(-2.2 + i * 0.22, 1.515, z1 + 0.08), 6)
	# ---- the first floor slab: a deep teal-edged canopy over the front
	var sy := h1 + 0.02
	_bx(k, Vector3(5.8, 0.14, z1 - z0 + 0.3), white, 0, sy + 0.07, cz + 0.15)
	_bx(k, Vector3(5.82, 0.1, 0.04), teal, 0, sy + 0.07, z1 + 0.3)
	for i in 10:
		k.cyl(0.04, 0.012, Color(1.0, 0.95, 0.85, 0.4), MeshKit.at(-2.6 + i * 0.58, sy - 0.006, z1 + 0.15), 6)
	# a balcony on the slab with a glass balustrade and pot plants
	_bx(k, Vector3(2.7, 0.9, 0.03), Color(0.7, 0.86, 0.92, 0.8), 1.45, sy + 0.6, z1 + 0.26)
	_bx(k, Vector3(2.72, 0.04, 0.06), frame, 1.45, sy + 1.06, z1 + 0.26)
	for x in [0.12, 2.78]:
		_bx(k, Vector3(0.03, 0.9, 0.3), Color(0.7, 0.86, 0.92, 0.8), x, sy + 0.6, z1 + 0.12)
	for i in 3:
		k.cyl(0.1, 0.22, white2, MeshKit.at(0.6 + i * 0.85, sy + 0.14, z1 + 0.1), 8, 0.02, 0.08)
		k.sphere(0.13, Pal.LEAF if i % 2 else Pal.LEAF_LIGHT, MeshKit.at(0.6 + i * 0.85, sy + 0.46, z1 + 0.1), 7, 4)
	# ---- the first floor: white panels, a ribbon window, fins, a teal band
	var fz1 := z1 - 0.08
	var fy0 := sy + 0.14
	var h2 := 2.1
	_bx(k, Vector3(5.76, h2, fz1 - z0), white, 0, fy0 + h2 * 0.5, (z0 + fz1) * 0.5)
	_bx(k, Vector3(5.4, 0.9, 0.04), glass, 0, fy0 + 1.05, fz1 + 0.02)
	for i in 13:
		_bx(k, Vector3(0.07, 1.2, 0.22), white2 if i % 3 else teal, -2.7 + i * 0.45, fy0 + 1.05, fz1 + 0.12)
	_bx(k, Vector3(5.8, 0.12, 0.06), teal, 0, fy0 + 0.35, fz1 + 0.03)
	for i in 8:
		_bx(k, Vector3(0.6, 0.012, 0.012), white2, -2.5 + i * 0.72, fy0 + 0.2, fz1 + 0.01)
	# side windows and downpipes
	for sx in [-1.0, 1.0]:
		ArchKit.curtain(k, MeshKit.xf(Vector3(sx * 2.885, fy0 + 0.5, cz), Vector3(0, sx * 90.0, 0)), 1.0, 1.1, 2, 2, 1)
		k.cyl(0.04, fy0 + h2, white2, MeshKit.at(sx * 2.84, 0.0, z0 + 0.06), 6)
	var top := fy0 + h2
	ArchKit.parapet(k, Vector3(0, top, cz), 5.8, z1 - z0, 2)
	# ---- roof: a screened plant enclosure under a solar canopy
	var rx := 0.95
	for x in [-rx, rx]:
		ArchKit.louvres(k, MeshKit.xf(Vector3(x, top, -1.25), Vector3(0, 90.0 * signf(x), 0)), 1.1, 0.85, white2, 7)
	ArchKit.louvres(k, MeshKit.at(0, top, -0.68), 1.9, 0.85, white2, 7)
	ArchKit.louvres(k, MeshKit.xf(Vector3(0, top, -1.82), Vector3(0, 180, 0)), 1.9, 0.85, white2, 7)
	ArchKit.ac_unit(k, MeshKit.at(-0.45, top, -1.25), 2, 0.75)
	ArchKit.ac_unit(k, MeshKit.at(0.45, top, -1.25), 2, 0.75)
	for x in [-rx + 0.05, rx - 0.05]:
		for z in [-1.8, -0.7]:
			_bx(k, Vector3(0.06, 1.25, 0.06), frame, x, top + 0.62, z)
	for i in 4:
		k.box(Vector3(1.92, 0.04, 0.3), Color(0.16, 0.24, 0.44), MeshKit.xf(Vector3(0, top + 1.32 + i * 0.07, -1.68 + i * 0.3), Vector3(-14, 0, 0)))
		_bx(k, Vector3(1.94, 0.015, 0.02), Color(0.6, 0.64, 0.7), 0, top + 1.35 + i * 0.07, -1.55 + i * 0.3)
	# ---- the big "Chat" neon on the roof edge, with a speech bubble
	var ny := top + 0.3
	for x in [-1.25, 1.25]:
		_bx(k, Vector3(0.05, 0.9, 0.05), dark, x, ny + 0.2, -0.5)
	_bx(k, Vector3(2.6, 0.05, 0.05), dark, 0, ny + 0.05, -0.5)
	_bx(k, Vector3(2.6, 0.05, 0.05), dark, 0, ny + 0.65, -0.5)
	TownArt.word(k, MeshKit.at(0.4, ny + 0.02, -0.45), "Chat", 0.78, Color(0.42, 0.96, 0.9, 0.35), 0.12, 0.05)
	TownArt.word(k, MeshKit.at(0.4, ny + 0.02, -0.48), "Chat", 0.78, dark, 0.2, 0.02)
	k.rbox(Vector3(0.62, 0.46, 0.06), 0.2, Color(0.98, 0.7, 0.3, 0.45), MeshKit.at(-1.55, ny + 0.45, -0.45), 1)
	k.prism(PackedVector2Array([Vector2(-0.08, 0), Vector2(0.1, 0), Vector2(-0.14, 0.16)]), 0.06, Color(0.98, 0.7, 0.3, 0.45), MeshKit.xf(Vector3(-1.65, ny + 0.24, -0.48), Vector3(90, 0, 180)))
	for i in 3:
		k.sphere(0.045, white, MeshKit.at(-1.7 + i * 0.15, ny + 0.45, -0.41), 6, 3)
	# a green roof either side of the sign, pendants under the canopy
	for x in [-2.05, 2.05]:
		_bx(k, Vector3(1.4, 0.06, 0.45), Color(0.46, 0.6, 0.36), x, top + 0.05, -0.85)
		for i in 5:
			k.sphere(0.07, Color(0.56, 0.66, 0.4) if i % 2 else Color(0.82, 0.6, 0.7), MeshKit.xf(Vector3(x - 0.55 + i * 0.27, top + 0.09, -0.85 + (i % 2) * 0.1), Vector3.ZERO, Vector3(1, 0.6, 1)), 5, 3)
	for i in 4:
		var px := 1.05 + i * 0.5
		k.cyl(0.005, 0.32, dark, MeshKit.at(px, sy - 0.32, z1 + 0.2), 3)
		k.cone(0.09, 0.1, teal, MeshKit.xf(Vector3(px, sy - 0.3, z1 + 0.2), Vector3(180, 0, 0)), 8)
		k.sphere(0.04, Color(1.0, 0.92, 0.7, 0.35), MeshKit.at(px, sy - 0.42, z1 + 0.2), 5, 3)
	# a balcony table with two chairs, a sandwich board by the door
	k.cyl(0.14, 0.02, white, MeshKit.at(1.95, sy + 0.62, z1 + 0.12), 8)
	k.cyl(0.02, 0.6, frame, MeshKit.at(1.95, sy + 0.02, z1 + 0.12), 4)
	for sx in [-0.25, 0.25]:
		_bx(k, Vector3(0.2, 0.03, 0.18), teal, 1.95 + sx, sy + 0.42, z1 + 0.12)
		_bx(k, Vector3(0.2, 0.22, 0.03), teal, 1.95 + sx * 1.3, sy + 0.55, z1 + 0.12)
	var sb := MeshKit.xf(Vector3(-0.05, 0, 0.28), Vector3(0, 15, 0))
	for sz in [-1.0, 1.0]:
		k.box(Vector3(0.4, 0.66, 0.03), white, sb * MeshKit.xf(Vector3(0, 0.32, sz * 0.08), Vector3(sz * -12.0, 0, 0)))
	k.box(Vector3(0.32, 0.4, 0.01), teal, sb * MeshKit.xf(Vector3(0, 0.38, 0.105), Vector3(-12, 0, 0)))
	TownArt.word(k, sb * MeshKit.xf(Vector3(0, 0.44, 0.115), Vector3(-12, 0, 0)), "Chat", 0.1, white, 0.18, 0.01)
	# ---- planters along the glass, a tree, a recycling station
	_bx(k, Vector3(1.55, 0.42, 0.36), white, 1.98, 0.23, -0.18)
	_bx(k, Vector3(1.57, 0.03, 0.38), teal, 1.98, 0.44, -0.18)
	for i in 6:
		k.sphere(0.15, Pal.LEAF if i % 2 else Pal.LEAF_DARK, MeshKit.xf(Vector3(1.32 + i * 0.26, 0.55, -0.18), Vector3.ZERO, Vector3(1.0, 0.8, 0.9)), 7, 4)
	for i in 5:
		k.cone(0.05, 0.4, Pal.LEAF_LIGHT, MeshKit.xf(Vector3(1.45 + i * 0.27, 0.44, -0.1), Vector3(0, 0, (i % 3) * 8 - 8)), 5)
	k.cyl(0.24, 0.45, white, MeshKit.at(-2.68, 0.02, 0.02), 10, 0.03, 0.2)
	TownArt.tree(k, Vector3(-2.68, 0.47, 0.02), 1.9, Pal.LEAF, 5)
	# glass windbreak panels at the terrace sides
	for z in [0.65, 1.35]:
		_bx(k, Vector3(0.03, 0.9, 0.6), Color(0.7, 0.86, 0.92, 0.8), -2.2, 0.5, z)
		_bx(k, Vector3(0.05, 0.04, 0.62), frame, -2.2, 0.96, z)


# ---------------------------------------------------------------- 3 loft

static func _loft(k: MeshKit) -> void:
	var brick := Color(0.66, 0.36, 0.26)
	var mortar := Color(0.5, 0.27, 0.2)
	var blk := Color(0.14, 0.15, 0.17)
	var steel := Color(0.26, 0.28, 0.32)
	var glass := Color(0.42, 0.62, 0.82, 0.62)
	var warm := Color(1.0, 0.8, 0.5, 0.35)
	var wood := Color(0.52, 0.36, 0.24)
	var r := RandomNumberGenerator.new()
	r.seed = 303
	# ground: brick pavers in staggered rows
	_bx(k, Vector3(5.8, 0.015, 3.8), Color(0.42, 0.4, 0.38), 0, 0.008, 0)
	for j in 11:
		var z := -0.3 + j * 0.2
		for i in 15:
			var x := -2.8 + i * 0.4 + (0.2 if j % 2 else 0.0)
			if x > 2.75:
				continue
			k.box(Vector3(0.37, 0.012, 0.17), Color(0.62, 0.42, 0.34).darkened(r.randf_range(0.0, 0.14)), MeshKit.at(x, 0.02, z))
	# ---- the loft: a three-storey brick block
	var x0 := -2.88
	var x1 := 0.95
	var z0 := -1.86
	var z1 := -0.42
	var cx := (x0 + x1) * 0.5
	var cz := (z0 + z1) * 0.5
	var h := 6.1
	_bx(k, Vector3(x1 - x0, h, z1 - z0), brick, cx, h * 0.5, cz)
	_bx(k, Vector3(x1 - x0 + 0.04, 0.42, z1 - z0 + 0.04), Color(0.4, 0.4, 0.42), cx, 0.21, cz)
	# mortar courses on the front and the left side
	for j in 18:
		var y := 0.6 + j * 0.31
		_bx(k, Vector3(x1 - x0, 0.02, 0.012), mortar, cx, y, z1 + 0.006)
		_bx(k, Vector3(0.012, 0.02, z1 - z0), mortar, x0 - 0.006, y, cz)
	# random proud bricks
	for i in 30:
		k.box(Vector3(0.24, 0.08, 0.02), brick.darkened(r.randf_range(-0.08, 0.15)), MeshKit.at(r.randf_range(x0 + 0.2, x1 - 0.2), r.randf_range(3.7, 5.6), z1 + 0.01))
	# ground floor: a huge steel factory window and the door
	var gw := 2.2
	var gx := -1.45
	_bx(k, Vector3(gw + 0.16, 3.0, 0.06), blk, gx, 1.95, z1 + 0.02)
	_bx(k, Vector3(gw, 2.84, 0.04), glass, gx, 1.95, z1 + 0.05)
	for i in 7:
		_bx(k, Vector3(0.04, 2.84, 0.06), blk, gx - gw * 0.5 + i * gw / 6.0, 1.95, z1 + 0.07)
	for j in 6:
		_bx(k, Vector3(gw, 0.04, 0.06), blk, gx, 0.53 + j * 0.568, z1 + 0.07)
	_bx(k, Vector3(gw + 0.3, 0.24, 0.1), steel, gx, 3.55, z1 + 0.05)
	for i in 6:
		k.cyl(0.03, 0.02, Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(gx - gw * 0.5 + 0.1 + i * 0.4, 3.55, z1 + 0.11), Vector3(90, 0, 0)), 6)
	# the door: steel frame, glass, a transom, a lamp
	_bx(k, Vector3(0.9, 2.5, 0.08), blk, 0.4, 1.25, z1 + 0.03)
	_bx(k, Vector3(0.72, 1.9, 0.04), glass, 0.4, 0.98, z1 + 0.07)
	_bx(k, Vector3(0.72, 0.36, 0.04), glass, 0.4, 2.2, z1 + 0.07)
	_bx(k, Vector3(0.74, 0.04, 0.06), blk, 0.4, 1.98, z1 + 0.08)
	_bx(k, Vector3(0.04, 0.5, 0.06), Pal.BRASS, 0.66, 1.0, z1 + 0.1)
	k.box(Vector3(0.08, 0.06, 0.3), blk, MeshKit.at(0.4, 2.72, z1 + 0.15))
	k.cone(0.12, 0.12, blk, MeshKit.xf(Vector3(0.4, 2.72, z1 + 0.3), Vector3(180, 0, 0)), 8)
	k.sphere(0.06, warm, MeshKit.at(0.4, 2.58, z1 + 0.3), 6, 3)
	# upper floors: tall arched windows with brick lintels and sills
	for f in 2:
		var wy := 4.0 + f * 1.15
		for i in 4:
			var wx := x0 + 0.55 + i * 0.95
			_bx(k, Vector3(0.62, 0.86, 0.05), blk, wx, wy, z1 + 0.02)
			_bx(k, Vector3(0.54, 0.78, 0.04), glass if (i + f) % 3 else Color(1.0, 0.84, 0.55, 0.5), wx, wy, z1 + 0.04)
			_bx(k, Vector3(0.03, 0.78, 0.05), blk, wx, wy, z1 + 0.06)
			_bx(k, Vector3(0.54, 0.03, 0.05), blk, wx, wy + 0.1, z1 + 0.06)
			for j in 5:
				var a := deg_to_rad(180.0 * (j + 0.5) / 5.0)
				k.box(Vector3(0.1, 0.16, 0.06), brick.darkened(0.18), MeshKit.xf(Vector3(wx + cos(a) * 0.36, wy + 0.43 + sin(a) * 0.12, z1 + 0.03), Vector3(0, 0, rad_to_deg(a) - 90.0)))
			_bx(k, Vector3(0.7, 0.05, 0.12), Color(0.62, 0.6, 0.56), wx, wy - 0.46, z1 + 0.06)
	# tie-rod anchors and the corbelled cornice
	for i in 5:
		k.cyl(0.07, 0.03, blk, MeshKit.xf(Vector3(x0 + 0.08 + i * 0.95, 3.4, z1 + 0.02), Vector3(90, 0, 0)), 6)
		k.cyl(0.07, 0.03, blk, MeshKit.xf(Vector3(x0 + 0.08 + i * 0.95, 4.6, z1 + 0.02), Vector3(90, 0, 0)), 6)
	for j in 3:
		_bx(k, Vector3(x1 - x0 + 0.06 + j * 0.06, 0.1, z1 - z0 + 0.06 + j * 0.06), brick.darkened(0.08 * j), cx, h - 0.35 + j * 0.1, cz)
	for i in 16:
		_bx(k, Vector3(0.1, 0.14, 0.08), brick.darkened(0.15), x0 + 0.12 + i * 0.24, h - 0.46, z1 + 0.05)
	_bx(k, Vector3(x1 - x0 + 0.2, 0.1, z1 - z0 + 0.2), Color(0.62, 0.6, 0.56), cx, h + 0.05, cz)
	_bx(k, Vector3(x1 - x0 - 0.1, 0.03, z1 - z0 - 0.1), Color(0.34, 0.34, 0.36), cx, h + 0.1, cz)
	# ---- the outdoor bar under a steel canopy, pendant lamps
	_bx(k, Vector3(2.24, 0.96, 0.34), steel, -1.3, 0.5, 0.12)
	for i in 8:
		k.cyl(0.015, 0.01, Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(-2.3 + i * 0.29, 0.86, 0.295), Vector3(90, 0, 0)), 4)
		k.cyl(0.015, 0.01, Color(0.5, 0.52, 0.56), MeshKit.xf(Vector3(-2.3 + i * 0.29, 0.14, 0.295), Vector3(90, 0, 0)), 4)
	for i in 3:
		_bx(k, Vector3(0.62, 0.62, 0.02), wood.darkened(0.05 * i), -2.0 + i * 0.7, 0.5, 0.295)
	_bx(k, Vector3(2.34, 0.07, 0.44), wood, -1.3, 1.0, 0.12)
	# a copper espresso machine, cold-brew taps, jars of beans
	_bx(k, Vector3(0.6, 0.36, 0.3), Color(0.78, 0.5, 0.32), -1.6, 1.22, 0.02)
	k.cyl(0.1, 0.1, Color(0.78, 0.5, 0.32), MeshKit.at(-1.6, 1.4, 0.02), 8)
	k.sphere(0.1, Pal.BRASS, MeshKit.at(-1.6, 1.5, 0.02), 8, 4)
	for sx in [-0.16, 0.0, 0.16]:
		k.cyl(0.035, 0.07, blk, MeshKit.at(-1.6 + sx, 1.09, 0.19), 6)
	_bx(k, Vector3(0.36, 0.06, 0.08), blk, -0.75, 1.36, 0.0)
	for i in 3:
		k.cyl(0.015, 0.12, Pal.BRASS, MeshKit.at(-0.87 + i * 0.12, 1.24, 0.02), 4)
		k.cyl(0.02, 0.1, [Color(0.86, 0.3, 0.26), blk, Pal.BRASS][i], MeshKit.at(-0.87 + i * 0.12, 1.39, 0.0), 4)
	for i in 5:
		k.cyl(0.05, 0.16, Color(0.86, 0.9, 0.86, 0.85), MeshKit.at(-2.3 + i * 0.12, 1.035, 0.15), 6)
		k.cyl(0.045, 0.1, Color(0.4, 0.24, 0.14), MeshKit.at(-2.3 + i * 0.12, 1.04, 0.15), 6)
	for i in 4:
		k.cyl(0.04, 0.09, Color(0.95, 0.95, 0.94), MeshKit.at(-0.4 + (i % 2) * 0.09, 1.035 + (i / 2) * 0.09, 0.15), 6)
	# the canopy: I-beams from the façade, a glass roof, hanging lamps, a menu
	for x in [-2.35, -0.25]:
		_bx(k, Vector3(0.08, 0.16, 0.9), blk, x, 2.75, -0.02)
		TownArt.beam(k, Vector3(x, 2.0, z1 + 0.05), Vector3(x, 2.66, 0.3), 0.04, blk)
	_bx(k, Vector3(2.2, 0.16, 0.08), blk, -1.3, 2.75, 0.39)
	_bx(k, Vector3(2.2, 0.03, 0.82), Color(0.6, 0.76, 0.86, 0.8), -1.3, 2.86, -0.02)
	for i in 3:
		var lx := -2.0 + i * 0.7
		k.cyl(0.006, 0.6, blk, MeshKit.at(lx, 2.07, 0.12), 3)
		k.cone(0.13, 0.14, blk, MeshKit.xf(Vector3(lx, 2.18, 0.12), Vector3(180, 0, 0)), 8)
		k.sphere(0.06, warm, MeshKit.at(lx, 2.03, 0.12), 6, 3)
	_bx(k, Vector3(1.0, 0.36, 0.04), Color(0.18, 0.22, 0.2), -1.3, 2.42, 0.38)
	_chalk(k, MeshKit.at(-1.3, 2.42, 0.405), 0.9, 0.3, 3, 12)
	# ---- the steel gallery (mezzanine) along the façade, a fire escape
	var gy := 3.4
	_bx(k, Vector3(x1 - x0 - 0.1, 0.06, 0.38), steel, cx, gy, z1 + 0.19)
	for i in 4:
		TownArt.beam(k, Vector3(x0 + 0.3 + i * 1.1, gy - 0.5, z1), Vector3(x0 + 0.3 + i * 1.1, gy - 0.03, z1 + 0.36), 0.04, steel)
	ArchKit.railing(k, Vector3(x0 + 0.05, gy, z1 + 0.37), Vector3(x1 - 0.05, gy, z1 + 0.37), 0.9, blk, 0.4)
	for i in 12:
		_bx(k, Vector3(0.015, 0.85, 0.015), blk, x0 + 0.2 + i * 0.32, gy + 0.45, z1 + 0.37)
	ArchKit.ladder(k, MeshKit.xf(Vector3(x0 + 0.25, 0.0, z1 + 0.25), Vector3(0, 180, 0)), gy, blk)
	_bx(k, Vector3(0.9, 0.06, 0.38), steel, x0 + 0.5, 5.0, z1 + 0.19)
	ArchKit.railing(k, Vector3(x0 + 0.05, 5.0, z1 + 0.37), Vector3(x0 + 0.95, 5.0, z1 + 0.37), 0.9, blk, 0.3)
	TownArt.stair(k, Vector3(-1.0, gy, z1 + 0.2), Vector3(x0 + 0.95, 5.0, z1 + 0.2), 0.32, steel, blk, blk)
	# a vertical blade sign on the corner: C A F E, lit
	var sx := x1 - 0.05
	_bx(k, Vector3(0.08, 2.3, 0.6), blk, sx, 4.75, z1 + 0.4)
	_bx(k, Vector3(0.1, 2.36, 0.04), Pal.BRASS, sx, 4.75, z1 + 0.72)
	for i in 4:
		TownArt.word(k, MeshKit.xf(Vector3(sx + 0.05, 5.5 - i * 0.52, z1 + 0.4), Vector3(0, 90, 0)), "CAFE"[i], 0.36, warm, 0.14, 0.03)
		TownArt.word(k, MeshKit.xf(Vector3(sx - 0.05, 5.5 - i * 0.52, z1 + 0.4), Vector3(0, -90, 0)), "CAFE"[i], 0.36, warm, 0.14, 0.03)
	for j in 2:
		TownArt.beam(k, Vector3(x1 - 0.02, 3.8 + j * 1.9, z1 + 0.02), Vector3(sx, 3.6 + j * 2.3, z1 + 0.7), 0.025, blk)
	# ---- roof: a timber water tower on steel legs, an old chimney, vents
	var wt := Vector3(-0.3, h + 0.1, -1.18)
	for sx2 in [-0.36, 0.36]:
		for sz in [-0.36, 0.36]:
			_bx(k, Vector3(0.07, 1.3, 0.07), blk, wt.x + sx2, wt.y + 0.65, wt.z + sz)
	for j in 2:
		TownArt.beam(k, wt + Vector3(-0.36, 0.1 + j * 0.6, 0.36), wt + Vector3(0.36, 0.6 + j * 0.6, 0.36), 0.03, blk)
		TownArt.beam(k, wt + Vector3(-0.36, 0.1 + j * 0.6, -0.36), wt + Vector3(-0.36, 0.6 + j * 0.6, 0.36), 0.03, blk)
	_bx(k, Vector3(0.9, 0.06, 0.9), wood.darkened(0.2), wt.x, wt.y + 1.33, wt.z)
	k.cyl(0.46, 1.0, Color(0.6, 0.44, 0.3), MeshKit.at(wt.x, wt.y + 1.36, wt.z), 12)
	for i in 12:
		var a2 := TAU * i / 12.0
		k.box(Vector3(0.02, 1.0, 0.05), Color(0.5, 0.36, 0.24), MeshKit.xf(Vector3(wt.x + cos(a2) * 0.465, wt.y + 1.86, wt.z + sin(a2) * 0.465), Vector3(0, -rad_to_deg(a2), 0)))
	for j in 3:
		k.torus(0.475, 0.015, blk, MeshKit.at(wt.x, wt.y + 1.5 + j * 0.32, wt.z), 12, 3)
	k.cone(0.52, 0.42, Color(0.4, 0.3, 0.22), MeshKit.at(wt.x, wt.y + 2.36, wt.z), 12)
	k.sphere(0.05, blk, MeshKit.at(wt.x, wt.y + 2.8, wt.z), 5, 3)
	ArchKit.ladder(k, MeshKit.xf(Vector3(wt.x + 0.2, wt.y, wt.z + 0.5), Vector3(0, 180, 0)), 2.3, blk)
	_bx(k, Vector3(0.5, 1.2, 0.4), brick.darkened(0.1), 0.62, h + 0.6, -1.72)
	_bx(k, Vector3(0.56, 0.1, 0.46), Color(0.62, 0.6, 0.56), 0.62, h + 1.2, -1.72)
	_bx(k, Vector3(0.6, 0.12, 0.08), brick.darkened(0.1), cx, h + 0.16, z1 - 0.04)
	# ---- the roastery annex: corrugated steel, a glass garage door
	var ax0 := x1
	var ax1 := 2.88
	var ah := 3.25
	var acx := (ax0 + ax1) * 0.5
	var clad := Color(0.32, 0.38, 0.44)
	_bx(k, Vector3(ax1 - ax0, ah, z1 - z0), clad, acx, ah * 0.5, cz)
	for i in int((ax1 - ax0) / 0.14):
		_bx(k, Vector3(0.04, ah - 0.3, 0.025), clad.darkened(0.15), ax0 + 0.07 + i * 0.14, ah * 0.5 + 0.1, z1 + 0.012)
	for i in int((z1 - z0) / 0.14):
		_bx(k, Vector3(0.025, ah - 0.3, 0.04), clad.darkened(0.15), ax1 + 0.012, ah * 0.5 + 0.1, z0 + 0.07 + i * 0.14)
	_bx(k, Vector3(1.5, 2.3, 0.06), blk, acx, 1.2, z1 + 0.04)
	for j in 5:
		for i in 4:
			_bx(k, Vector3(0.33, 0.4, 0.03), glass if (i + j) % 4 else warm, acx - 0.54 + i * 0.36, 0.3 + j * 0.44, z1 + 0.07)
	_bx(k, Vector3(1.66, 0.28, 0.24), steel, acx, 2.48, z1 + 0.1)
	TownArt.word(k, MeshKit.at(2.33, 2.72, z1 + 0.04), "ROAST", 0.24, Color(0.95, 0.92, 0.84), 0.16, 0.02)
	ArchKit.parapet(k, Vector3(acx, ah, cz), ax1 - ax0, z1 - z0, 3)
	# the drum roaster outside: cabinet, drum, hopper, cooling tray, chimney
	var rx := 1.62
	_bx(k, Vector3(0.6, 0.5, 0.44), blk, rx, 0.27, -0.1)
	k.cyl(0.24, 0.5, Color(0.2, 0.2, 0.22), MeshKit.xf(Vector3(rx, 0.78, -0.33), Vector3(90, 0, 0)), 10)
	for j in 2:
		k.torus(0.245, 0.02, Pal.BRASS, MeshKit.xf(Vector3(rx, 0.78, -0.25 + j * 0.3), Vector3(90, 0, 0)), 10, 3)
	k.cyl(0.18, 0.04, Pal.BRASS, MeshKit.xf(Vector3(rx, 0.78, 0.17), Vector3(90, 0, 0)), 10)
	k.cyl(0.05, 0.25, Color(0.78, 0.5, 0.32), MeshKit.at(rx, 1.0, -0.15), 6)
	k.cone(0.18, 0.28, Color(0.78, 0.5, 0.32), MeshKit.xf(Vector3(rx, 1.5, -0.15), Vector3(180, 0, 0)), 8)
	k.cyl(0.18, 0.04, Color(0.4, 0.24, 0.14), MeshKit.at(rx, 1.47, -0.15), 8)
	var ct := Vector3(2.28, 0, 0.0)
	for sx3 in [-0.2, 0.2]:
		_bx(k, Vector3(0.05, 0.55, 0.05), blk, ct.x + sx3, 0.28, ct.z)
	k.cyl(0.32, 0.12, Color(0.3, 0.3, 0.32), MeshKit.at(ct.x, 0.55, ct.z), 12)
	k.cyl(0.28, 0.02, Color(0.42, 0.26, 0.16), MeshKit.at(ct.x, 0.66, ct.z), 12)
	_bx(k, Vector3(0.5, 0.03, 0.04), Pal.BRASS, ct.x, 0.7, ct.z)
	k.cyl(0.03, 0.12, Pal.BRASS, MeshKit.at(ct.x, 0.66, ct.z), 6)
	TownArt.beam(k, Vector3(rx, 0.75, 0.15), Vector3(ct.x - 0.25, 0.62, ct.z), 0.06, Color(0.2, 0.2, 0.22))
	ArchKit.pipes(k, [Vector3(rx, 0.95, -0.3), Vector3(rx, 1.1, -0.42), Vector3(rx, 1.1, -0.36), Vector3(rx, 7.4, -0.36)], 0.07, Color(0.6, 0.62, 0.66))
	for j in 4:
		k.cyl(0.085, 0.04, blk, MeshKit.at(rx, 1.6 + j * 1.4, -0.36), 8)
	k.cone(0.14, 0.14, Color(0.4, 0.42, 0.46), MeshKit.at(rx, 7.45, -0.36), 8)
	k.cyl(0.13, 0.03, Color(0.4, 0.42, 0.46), MeshKit.at(rx, 7.4, -0.36), 8)
	# burlap sacks of green beans
	for i in 3:
		k.rbox(Vector3(0.34, 0.2, 0.26), 0.07, Color(0.72, 0.6, 0.42).darkened(0.04 * i), MeshKit.xf(Vector3(1.18 + (i % 2) * 0.05, 0.11 + (i / 2) * 0.2, -0.22 + (i % 2) * 0.3), Vector3(0, i * 20, 0)), 1)
	# ---- a steel pergola over the terrace with pendants above the tables
	var pl := Vector3(-2.25, 0, 1.86)
	var pr := Vector3(1.22, 0, 1.86)
	var py := 3.05
	for p in [pl, pr]:
		_bx(k, Vector3(0.12, py, 0.12), blk, p.x, py * 0.5, p.z)
		_bx(k, Vector3(0.24, 0.06, 0.24), steel, p.x, 0.03, p.z)
		_bx(k, Vector3(0.1, 0.18, p.z - z1 + 0.1), blk, p.x, py, (p.z + z1) * 0.5 + 0.05)
	_bx(k, Vector3(pr.x - pl.x + 0.12, 0.18, 0.1), blk, (pl.x + pr.x) * 0.5, py, pl.z)
	for z in [0.72, 1.37]:
		TownArt.beam(k, Vector3(pl.x, py - 0.1, z), Vector3(pr.x, py - 0.1, z), 0.012, blk)
	for i in 8:
		var sp := seat_local(i) + Vector3(0, 0, -0.28)
		var drop := 0.7 + (i % 3) * 0.12
		k.cyl(0.005, drop, blk, MeshKit.at(sp.x, py - 0.1 - drop, sp.z), 3)
		k.cone(0.11, 0.12, blk if i % 2 else Color(0.78, 0.5, 0.32), MeshKit.xf(Vector3(sp.x, py - 0.1 - drop, sp.z), Vector3(180, 0, 0)), 8)
		k.sphere(0.045, warm, MeshKit.at(sp.x, py - 0.16 - drop, sp.z), 6, 3)
	# planters with grasses at the posts
	for p in [Vector3(-2.2, 0, 0.3), Vector3(1.3, 0, 0.55)]:
		_bx(k, Vector3(0.36, 0.36, 0.36), steel, p.x, 0.18, p.z)
		k.sphere(0.2, Pal.LEAF_DARK, MeshKit.xf(Vector3(p.x, 0.46, p.z), Vector3.ZERO, Vector3(1, 1.3, 1)), 7, 4)


# ---------------------------------------------------------------- 4 lounge

static func _lounge(k: MeshKit) -> void:
	var g := Color(0.17, 0.18, 0.21)
	var g2 := Color(0.24, 0.25, 0.29)
	var brass := Color(0.78, 0.63, 0.38)
	var glass := Color(0.32, 0.5, 0.7, 0.55)
	var cyan := Color(0.42, 0.9, 1.0, 0.45)
	var gold := Color(1.0, 0.86, 0.5, 0.4)
	# ground: graphite tiles, glowing seams, a brass threshold
	_bx(k, Vector3(5.8, 0.02, 3.8), Color(0.2, 0.21, 0.24), 0, 0.01, 0)
	for i in 12:
		_bx(k, Vector3(0.02, 0.006, 2.3), Color(0.42, 0.9, 1.0, 0.55), -2.75 + i * 0.5, 0.023, 0.75)
	for j in 5:
		_bx(k, Vector3(5.8, 0.006, 0.02), Color(0.42, 0.9, 1.0, 0.55), 0, 0.023, -0.35 + j * 0.55)
	_bx(k, Vector3(5.8, 0.03, 0.05), brass, 0, 0.03, 1.87)
	# ---- the podium: glass between graphite fins, brass bands
	var z0 := -1.86
	var z1 := -0.42
	var cz := (z0 + z1) * 0.5
	var h1 := 3.2
	_bx(k, Vector3(5.76, h1, z1 - z0), g, 0, h1 * 0.5, cz)
	_bx(k, Vector3(5.6, h1 - 0.5, 0.04), glass, 0, h1 * 0.5, z1 + 0.02)
	for i in 15:
		var fx := -2.8 + i * 0.4
		_bx(k, Vector3(0.07, h1 - 0.1, 0.24), g2, fx, h1 * 0.5, z1 + 0.12)
		if i % 2 == 0:
			_bx(k, Vector3(0.02, h1 - 0.6, 0.02), gold, fx, h1 * 0.5, z1 + 0.25)
	_bx(k, Vector3(5.8, 0.1, 0.3), brass, 0, h1 - 0.05, z1 + 0.14)
	_bx(k, Vector3(5.8, 0.03, 0.03), gold, 0, h1 - 0.14, z1 + 0.3)
	ArchKit.parapet(k, Vector3(0, h1, cz), 5.8, z1 - z0, 4)
	# side faces: fins and glass
	for sx in [-1.0, 1.0]:
		_bx(k, Vector3(0.04, h1 - 0.5, 1.2), glass, sx * 2.885, h1 * 0.5, cz)
		for j in 4:
			_bx(k, Vector3(0.2, h1 - 0.1, 0.06), g2, sx * 2.92, h1 * 0.5, z0 + 0.25 + j * 0.33)
	# the entrance: a brass portal and a revolving door
	_bx(k, Vector3(1.0, 2.5, 0.12), brass, 0.45, 1.25, z1 + 0.3)
	_bx(k, Vector3(0.8, 2.3, 0.14), g, 0.45, 1.15, z1 + 0.3)
	_bx(k, Vector3(0.84, 0.03, 0.16), gold, 0.45, 2.34, z1 + 0.3)
	k.cyl(0.36, 2.1, Color(0.42, 0.62, 0.8, 0.6), MeshKit.at(0.45, 0.02, z1 + 0.22), 10)
	k.cyl(0.37, 0.06, brass, MeshKit.at(0.45, 2.1, z1 + 0.22), 10)
	for i in 2:
		k.box(Vector3(0.7, 2.05, 0.02), g2, MeshKit.xf(Vector3(0.45, 1.05, z1 + 0.22), Vector3(0, 45 + i * 90, 0)))
	# ---- the glowing bar (counter rect) under a floating holographic menu
	var bx0 := -2.42
	var bx1 := -0.18
	var bcx := (bx0 + bx1) * 0.5
	k.rbox(Vector3(bx1 - bx0, 1.0, 0.5), 0.08, g, MeshKit.at(bcx, 0.5, 0.05), 1)
	for i in 14:
		_bx(k, Vector3(0.03, 0.72, 0.02), cyan if i % 2 else gold, bx0 + 0.12 + i * 0.155, 0.48, 0.31)
	_bx(k, Vector3(bx1 - bx0 + 0.06, 0.05, 0.56), brass, bcx, 1.02, 0.05)
	_bx(k, Vector3(bx1 - bx0 - 0.1, 0.012, 0.44), Color(0.1, 0.1, 0.12), bcx, 1.05, 0.05)
	_bx(k, Vector3(bx1 - bx0 + 0.08, 0.03, 0.04), gold, bcx, 0.06, 0.32)
	# bar tools: a graphite espresso machine, glowing glasses, a shaker
	_bx(k, Vector3(0.5, 0.32, 0.28), g2, -1.7, 1.22, -0.08)
	_bx(k, Vector3(0.52, 0.03, 0.3), brass, -1.7, 1.39, -0.08)
	for sx in [-0.14, 0.14]:
		k.cyl(0.035, 0.06, brass, MeshKit.at(-1.7 + sx, 1.08, 0.07), 6)
	for i in 5:
		k.cyl(0.03, 0.09, [cyan, gold, Color(0.9, 0.5, 1.0, 0.45)][i % 3], MeshKit.at(-1.15 + i * 0.12, 1.06, 0.18), 6)
	k.cyl(0.04, 0.16, brass, MeshKit.at(-0.4, 1.06, 0.1), 6)
	# brass emitters with beams up to three floating menu panels
	for i in 3:
		var mx := bx0 + 0.4 + i * 0.72
		k.cyl(0.05, 0.05, brass, MeshKit.at(mx, 1.06, -0.12), 8)
		k.box(Vector3(0.012, 0.65, 0.012), Color(0.42, 0.9, 1.0, 0.3), MeshKit.at(mx, 1.45, -0.12))
		var pf := MeshKit.xf(Vector3(mx, 2.15, -0.12), Vector3(-10, (i - 1) * -12.0, 0))
		k.box(Vector3(0.6, 0.62, 0.012), Color(0.42, 0.9, 1.0, 0.22), pf)
		k.box(Vector3(0.6, 0.02, 0.014), Color(0.6, 0.95, 1.0, 0.45), pf * MeshKit.at(0, 0.31, 0))
		k.box(Vector3(0.6, 0.02, 0.014), Color(0.6, 0.95, 1.0, 0.45), pf * MeshKit.at(0, -0.31, 0))
		for j in 5:
			k.box(Vector3(0.3 + (j % 2) * 0.1, 0.025, 0.014), Color(0.85, 1.0, 1.0, 0.45), pf * MeshKit.at(-0.08, 0.2 - j * 0.1, 0.004))
			k.box(Vector3(0.08, 0.025, 0.014), gold, pf * MeshKit.at(0.2, 0.2 - j * 0.1, 0.004))
	# a brass-framed glass canopy over the bar with downlights
	for x in [bx0 + 0.05, bx1 - 0.05]:
		TownArt.beam(k, Vector3(x, 2.2, z1 + 0.25), Vector3(x, 2.62, 0.32), 0.04, brass)
	_bx(k, Vector3(bx1 - bx0 + 0.1, 0.04, 0.78), Color(0.42, 0.62, 0.82, 0.6), bcx, 2.65, -0.05)
	_bx(k, Vector3(bx1 - bx0 + 0.12, 0.06, 0.05), brass, bcx, 2.65, 0.34)
	for i in 5:
		k.cyl(0.035, 0.012, gold, MeshKit.at(bx0 + 0.25 + i * 0.44, 2.62, 0.15), 6)
	# glowing coolant mains along the podium front with brass collars
	for j in 2:
		ArchKit.pipes(k, [Vector3(-2.85, 2.86 + j * 0.13, z1 + 0.3), Vector3(2.85, 2.86 + j * 0.13, z1 + 0.3)], 0.04, cyan if j == 0 else Color(1.0, 0.6, 0.35, 0.45))
	for i in 8:
		k.cyl(0.055, 0.05, brass, MeshKit.xf(Vector3(-2.6 + i * 0.74, 2.92, z1 + 0.3), Vector3(0, 0, 90)) * MeshKit.at(0, -0.025, 0), 6)
	# a delivery drone hovering over the pad
	var dp := Vector3(1.3, 8.75, -0.1)
	k.box(Vector3(0.22, 0.08, 0.22), g2, MeshKit.at(dp.x, dp.y, dp.z))
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			TownArt.beam(k, dp, dp + Vector3(sx * 0.2, 0.03, sz * 0.2), 0.02, g2)
			k.torus(0.08, 0.01, cyan, MeshKit.at(dp.x + sx * 0.2, dp.y + 0.05, dp.z + sz * 0.2), 8, 3)
	k.box(Vector3(0.14, 0.12, 0.14), Color(0.98, 0.7, 0.3), MeshKit.at(dp.x, dp.y - 0.12, dp.z))
	# a back bar of glowing bottles on the glass
	for j in 2:
		_bx(k, Vector3(2.0, 0.03, 0.14), brass, bcx, 1.35 + j * 0.42, z1 + 0.3)
		for i in 12:
			k.cyl(0.03, 0.18 + (i % 3) * 0.04, [cyan, gold, Color(0.9, 0.5, 1.0, 0.45), Color(0.5, 1.0, 0.6, 0.45)][(i + j) % 4], MeshKit.at(bx0 + 0.25 + i * 0.16, 1.37 + j * 0.42, z1 + 0.3), 5)
	# ---- planters with sculpted topiary in front of the right podium
	for i in 2:
		var px := 1.55 + i * 0.85
		_bx(k, Vector3(0.7, 0.44, 0.44), g2, px, 0.22, -0.12)
		_bx(k, Vector3(0.72, 0.03, 0.46), brass, px, 0.45, -0.12)
		_bx(k, Vector3(0.72, 0.02, 0.02), gold, px, 0.05, 0.11)
		for j in 3:
			k.sphere(0.18 - j * 0.04, Pal.CYPRESS.lightened(0.05 * j), MeshKit.at(px, 0.62 + j * 0.24, -0.12), 7, 4)
	# ---- the tower: a graphite core with glowing fins and brass rings
	var tx := 1.02
	var tz0 := -1.86
	var tz1 := -0.5
	var tcz := (tz0 + tz1) * 0.5
	var th := 9.0
	_bx(k, Vector3(tx * 2.0, th - h1, tz1 - tz0), g, 0, (h1 + th) * 0.5, tcz)
	_bx(k, Vector3(0.36, th - h1 - 0.3, 0.04), Color(0.42, 0.9, 1.0, 0.4), 0, (h1 + th) * 0.5, tz1 + 0.02)
	for i in 4:
		var fx2 := -0.8 + i * 0.53 + (0.0 if i < 2 else 0.0)
		if absf(fx2) < 0.3:
			continue
		_bx(k, Vector3(0.08, th - h1 - 0.2, 0.22), g2, fx2, (h1 + th) * 0.5, tz1 + 0.11)
		_bx(k, Vector3(0.02, th - h1 - 0.6, 0.02), gold, fx2, (h1 + th) * 0.5, tz1 + 0.23)
	for j in 5:
		_bx(k, Vector3(tx * 2.0 + 0.06, 0.06, tz1 - tz0 + 0.06), brass, 0, h1 + 0.5 + j * 1.15, tcz)
	# glowing coolant loops climbing the tower sides
	for sx in [-1.0, 1.0]:
		for j in 2:
			var px2: float = sx * (tx + 0.08)
			var pz := tcz - 0.25 + j * 0.5
			ArchKit.pipes(k, [Vector3(px2, h1 + 0.03, pz), Vector3(px2, th - 0.4, pz)], 0.05, Color(0.42, 0.9, 1.0, 0.4))
			for c in 5:
				k.cyl(0.065, 0.05, brass, MeshKit.at(px2, h1 + 0.9 + c * 1.1, pz), 6)
	# brass struts carrying the cantilever
	for sx in [-0.85, 0.85]:
		TownArt.beam(k, Vector3(sx, 4.2, tz1), Vector3(sx * 1.4, 6.0, 0.45), 0.09, brass)
	# ---- the sky lounge: a glass box cantilevered over the bar
	var lx0 := -2.35
	var lx1 := 1.95
	var lz0 := -1.0
	var lz1 := 0.5
	var ly := 6.0
	var lh := 1.55
	var lcx := (lx0 + lx1) * 0.5
	var lcz := (lz0 + lz1) * 0.5
	_bx(k, Vector3(lx1 - lx0, 0.22, lz1 - lz0), g2, lcx, ly + 0.11, lcz)
	for i in 8:
		k.cyl(0.04, 0.012, gold, MeshKit.at(lx0 + 0.3 + i * 0.52, ly - 0.006, lcz + 0.35), 6)
	_bx(k, Vector3(lx1 - lx0 - 0.04, lh, lz1 - lz0 - 0.04), glass, lcx, ly + 0.22 + lh * 0.5, lcz)
	for i in 11:
		_bx(k, Vector3(0.05, lh, 0.06), brass, lx0 + 0.02 + i * (lx1 - lx0 - 0.04) / 10.0, ly + 0.22 + lh * 0.5, lz1 - 0.01)
	for i in 5:
		for sx in [lx0, lx1]:
			_bx(k, Vector3(0.06, lh, 0.05), brass, sx, ly + 0.22 + lh * 0.5, lz0 + 0.02 + i * (lz1 - lz0 - 0.04) / 4.0)
	_bx(k, Vector3(lx1 - lx0 + 0.1, 0.18, lz1 - lz0 + 0.1), g, lcx, ly + 0.22 + lh + 0.09, lcz)
	_bx(k, Vector3(lx1 - lx0 + 0.12, 0.04, lz1 - lz0 + 0.12), brass, lcx, ly + 0.22 + lh + 0.2, lcz)
	_bx(k, Vector3(lx1 - lx0 + 0.12, 0.03, 0.03), gold, lcx, ly + 0.22 + lh, lz1 + 0.06)
	# a glowing SKY LOUNGE sign on the lounge's roof edge
	TownArt.word(k, MeshKit.at(-0.7, ly + 0.22 + lh + 0.24, lz1 + 0.02), "SKY LOUNGE", 0.26, gold, 0.14, 0.04)
	# horizontal brass louvres across the lounge glass
	for j in 3:
		_bx(k, Vector3(lx1 - lx0 - 0.06, 0.03, 0.12), brass, lcx, ly + 0.55 + j * 0.42, lz1 + 0.04)
	# silhouettes of the lounge inside: a long glowing bar and lamps
	_bx(k, Vector3(2.4, 0.04, 0.03), gold, lcx, ly + 0.7, lz1 + 0.01)
	for i in 6:
		k.sphere(0.05, gold, MeshKit.at(lx0 + 0.5 + i * 0.66, ly + 1.4, lz1 + 0.02), 6, 3)
	# the glass-floored terrace in front, balustrade, loungers
	var tz := lz1 + 0.5
	_bx(k, Vector3(lx1 - lx0 - 0.4, 0.06, 0.5), Color(0.42, 0.62, 0.82, 0.6), lcx, ly + 0.03, (lz1 + tz) * 0.5)
	_bx(k, Vector3(lx1 - lx0 - 0.4, 0.08, 0.04), brass, lcx, ly + 0.04, tz)
	_bx(k, Vector3(lx1 - lx0 - 0.4, 0.75, 0.03), Color(0.6, 0.8, 0.92, 0.7), lcx, ly + 0.45, tz)
	_bx(k, Vector3(lx1 - lx0 - 0.38, 0.04, 0.06), brass, lcx, ly + 0.84, tz)
	_bx(k, Vector3(lx1 - lx0 - 0.4, 0.02, 0.02), gold, lcx, ly - 0.01, tz - 0.01)
	for i in 3:
		var lpx := lx0 + 0.9 + i * 1.2
		k.rbox(Vector3(0.36, 0.1, 0.3), 0.04, Color(0.86, 0.84, 0.8), MeshKit.at(lpx, ly + 0.14, lz1 + 0.25), 1)
		k.box(Vector3(0.36, 0.22, 0.05), Color(0.86, 0.84, 0.8), MeshKit.xf(Vector3(lpx, ly + 0.26, lz1 + 0.1), Vector3(-20, 0, 0)))
	# ---- the crown: the tower top, a brass halo, a glowing ring, a beacon
	var cy := th
	_bx(k, Vector3(tx * 2.0 + 0.1, 0.12, tz1 - tz0 + 0.1), brass, 0, cy + 0.06, tcz)
	k.cyl(0.55, 0.3, g2, MeshKit.at(0, cy + 0.12, tcz), 10)
	k.torus(0.95, 0.07, brass, MeshKit.xf(Vector3(0, cy + 1.1, tcz), Vector3(70, 0, 0)), 20, 5)
	k.torus(0.8, 0.04, gold, MeshKit.xf(Vector3(0, cy + 1.1, tcz), Vector3(70, 0, 0)), 20, 4)
	k.sphere(0.32, Color(0.6, 0.96, 1.0, 0.35), MeshKit.at(0, cy + 1.1, tcz), 10, 6)
	k.cyl(0.04, 1.2, brass, MeshKit.at(0, cy + 0.4, tcz), 6)
	ArchKit.beacon(k, Vector3(0, cy + 1.6, tcz), 0.6)
	for sx in [-0.9, 0.9]:
		ArchKit.beacon(k, Vector3(sx, cy + 0.12, tcz - 0.5), 0.3)
	# a drone pad on the lounge roof
	ArchKit.drone_pad(k, Vector3(lx1 - 0.65, ly + 0.22 + lh + 0.22, lcz + 0.15), 0.5)
	# ---- a sky garden on the podium roof under the lounge
	for x in [-2.4, -1.65, 1.5, 2.3]:
		_bx(k, Vector3(0.5, 0.3, 0.4), g2, x, h1 + 0.15, -0.8)
		_bx(k, Vector3(0.52, 0.02, 0.42), brass, x, h1 + 0.3, -0.8)
		TownArt.tree(k, Vector3(x, h1 + 0.3, -0.8), 1.1, Pal.LEAF_DARK, int(x * 10))
	# glowing fins along the back of the podium roof
	for i in 8:
		var fx3 := -2.7 + i * 0.36
		if fx3 > -1.2:
			fx3 += 2.6
		_bx(k, Vector3(0.05, 0.45, 0.3), g2, fx3, h1 + 0.23, -1.78)
		_bx(k, Vector3(0.015, 0.4, 0.015), gold, fx3, h1 + 0.23, -1.62)
