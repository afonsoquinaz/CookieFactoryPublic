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


## Little round tables with stools on the terrace, one per seat.
static func seats_mesh(n: int, t: int) -> Mesh:
	var k := MeshKit.new()
	var top: Color = [Color(0.96, 0.96, 0.95), Color(0.96, 0.96, 0.95), Color(0.96, 0.96, 0.95), Color(0.62, 0.66, 0.72), Pal.BRASS][t]
	for i in n:
		var p := seat_local(i)
		var tp := p + Vector3(0.0, 0, -0.28)
		k.cyl(0.035, 0.66, Pal.STEEL_DARK, MeshKit.at(tp.x, 0, tp.z), 6)
		k.cyl(0.2, 0.04, top, MeshKit.at(tp.x, 0.66, tp.z), 12)
		k.rbox(Vector3(0.1, 0.06, 0.07), 0.02, Color(0.14, 0.15, 0.18), MeshKit.at(tp.x + 0.06, 0.72, tp.z))
		k.cyl(0.13, 0.04, Color(0.3, 0.66, 0.68), MeshKit.at(p.x, 0.42, p.z + 0.02), 10)
		k.cyl(0.03, 0.42, Pal.STEEL_DARK, MeshKit.at(p.x, 0, p.z + 0.02), 6)
	return k.commit()


static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var wall: Color = [Color(0.92, 0.88, 0.8), Color(0.95, 0.95, 0.94), Color(0.95, 0.95, 0.96), Color(0.62, 0.66, 0.72), Color(0.17, 0.18, 0.21)][t]
	var awning: Color = [Color(0.3, 0.6, 0.86), Color(0.3, 0.66, 0.68), Color(0.96, 0.6, 0.3), Color(0.36, 0.42, 0.58), Pal.BRASS][t]
	var trim: Color = [Pal.WOOD_DARK, Pal.STEEL_DARK, Color(0.3, 0.66, 0.68), Pal.STEEL_DARK, Pal.BRASS][t]
	var lit := func(c: Color) -> Color: return Color(c.r, c.g, c.b, 0.45)
	var h := 2.6 + t * 0.25
	# the café house
	k.rbox(Vector3(6.0, 0.2, 1.8), 0.05, Pal.STONE if t < 3 else Color(0.4, 0.42, 0.46), MeshKit.at(0, 0.1, -1.1))
	k.rbox(Vector3(5.8, h, 1.5), 0.08, wall, MeshKit.at(0, h * 0.5 + 0.1, -1.2))
	k.rbox(Vector3(6.0, 0.18, 1.7), 0.04, trim, MeshKit.at(0, h + 0.15, -1.2))
	# a big glass front with chat screens glowing inside, and a door
	k.rbox(Vector3(2.6, 1.3, 0.06), 0.06, Color(0.62, 0.8, 0.9, 0.6), MeshKit.at(-1.2, 1.2, -0.43))
	for i in 3:
		k.rbox(Vector3(0.5, 0.36, 0.03), 0.04, Color(0.14, 0.15, 0.18), MeshKit.at(-2.0 + i * 0.8, 1.35, -0.6))
		k.rbox(Vector3(0.42, 0.28, 0.02), 0.04, lit.call([Color(0.5, 0.86, 1.0), Color(0.6, 1.0, 0.7), Color(1.0, 0.8, 0.5)][i]), MeshKit.at(-2.0 + i * 0.8, 1.35, -0.585))
	k.rbox(Vector3(2.7, 0.08, 0.1), 0.02, trim, MeshKit.at(-1.2, 1.88, -0.42))
	k.rbox(Vector3(0.9, 1.7, 0.06), 0.08, trim, MeshKit.at(1.5, 0.95, -0.43))
	k.rbox(Vector3(0.6, 0.8, 0.07), 0.06, Color(0.62, 0.8, 0.9, 0.6), MeshKit.at(1.5, 1.25, -0.41))
	# awning
	for i in 12:
		k.rbox(Vector3(0.5, 0.05, 1.2), 0.015, awning if i % 2 == 0 else Color(0.96, 0.96, 0.95), MeshKit.xf(Vector3(-2.75 + i * 0.5, 2.25 + t * 0.1, -0.05), Vector3(-20, 0, 0)))
	# the sign: a speech bubble with three glowing dots
	k.rbox(Vector3(2.2, 0.6, 0.12), 0.26, Color(0.96, 0.96, 0.95) if t < 4 else Color(0.12, 0.12, 0.14), MeshKit.at(0, h - 0.02, -0.38))
	k.prism(PackedVector2Array([Vector2(-0.5, 0), Vector2(-0.15, 0), Vector2(-0.55, 0.32)]), 0.12, Color(0.96, 0.96, 0.95) if t < 4 else Color(0.12, 0.12, 0.14), MeshKit.xf(Vector3(0, h - 0.3, -0.44), Vector3(90, 0, 180)))
	for i in 3:
		k.sphere(0.09, lit.call(awning.lightened(0.2)), MeshKit.at(-0.45 + i * 0.45, h - 0.02, -0.3), 8, 5)
	# token counter in front of the window
	k.rbox(Vector3(2.3, 0.8, 0.75), 0.06, trim, MeshKit.at(-1.3, 0.4, -0.05))
	k.rbox(Vector3(2.4, 0.06, 0.85), 0.02, Color(0.96, 0.96, 0.95), MeshKit.at(-1.3, 0.83, -0.05))
	k.rbox(Vector3(2.2, 0.03, 0.03), 0.01, lit.call(awning.lightened(0.3)), MeshKit.at(-1.3, 0.7, 0.33))
	if t >= 1:
		# potted plants by the door
		for sx in [0.85, 2.15]:
			k.cyl(0.18, 0.35, Color(0.94, 0.95, 0.96), MeshKit.at(sx, 0, -0.2), 10, 0.03, 0.22)
			k.sphere(0.25, Pal.LEAF, MeshKit.at(sx, 0.55, -0.2), 9, 6)
	if t >= 2:
		# a café table with two stools outside
		k.cyl(0.04, 0.7, Pal.STEEL_DARK, MeshKit.at(2.6, 0, 0.3), 6)
		k.cyl(0.3, 0.04, Color(0.96, 0.96, 0.95), MeshKit.at(2.6, 0.7, 0.3), 12)
	if t >= 3:
		for sx in [-1.0, 1.0]:
			k.cyl(0.04, 0.5, Pal.STEEL_DARK, MeshKit.xf(Vector3(sx * 2.7, h - 0.4, -0.35), Vector3(-60, 0, 0)), 6)
			k.sphere(0.12, lit.call(Color(0.6, 0.9, 1.0)), MeshKit.at(sx * 2.7, h - 0.6, -0.05), 8, 5)
	if t >= 4:
		k.torus(0.5, 0.05, lit.call(Color(1.0, 0.86, 0.5)), MeshKit.at(0, h + 0.7, -1.2), 20, 4)
		k.cyl(0.06, 0.55, Pal.BRASS, MeshKit.at(0, h + 0.2, -1.2), 8)
	return k.commit()
