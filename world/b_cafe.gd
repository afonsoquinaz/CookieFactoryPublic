class_name CafeB
extends Building
## The Chat Café. Stock the token counter (left pad); visitors stroll in
## from the countryside, chat with your models, spend a few tokens each and
## pay 30% more than a van would. Planters, lamps, benches and trees nearby
## bring more visitors.

var display: Holder
var _spawn_t := 3.0
var _customers: Array[Customer] = []
var _label: Label3D


func _build() -> void:
	display = Holder.new().setup(20, [], Holder.Layout.GRID)
	display.accept_cat = ["token", "batch", "agent"]
	display.grid = Vector2i(4, 2)
	display.cell = Vector2(0.42, 0.34)
	display.max_visible = 40
	display.position = Vector3(-1.3, 0.86, -0.05)
	add_child(display)
	add_port(display, null, "in")
	_label = UI3D.label("0/20", 28)
	_label.position = Vector3(-1.3, 1.75, 0.2)
	add_child(_label)
	var b := UI3D.badge("cafe", Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 3.9, -1.0)
	add_child(b)
	display.changed.connect(_update)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.0, -2.0, 6.0, 1.65), Rect2(-2.45, -0.4, 2.3, 0.75)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("cafe_%d" % t, func(): return CafeB.mesh(t)), root)


func _on_level() -> void:
	display.capacity = Bal.cafe_cap(level)
	_update()


func _update() -> void:
	_label.text = "%d/%d" % [display.count(), display.capacity]


func counter_point() -> Vector3:
	return to_world(1.35 + randf_range(-0.4, 0.4), 1.0 + randf_range(-0.2, 0.3))


func charm() -> float:
	return world.aura(global_position, "charm") + world.aura(global_position, "walk") * 0.5


func rate() -> float:
	return Bal.cafe_rate(level) * (1.0 + charm())


func need(t: String) -> float:
	if not display.can_accept(t):
		return 0.0
	return 0.8 * (1.0 - float(display.count()) / maxf(1.0, display.capacity)) + 0.2


func _process(dt: float) -> void:
	super(dt)
	_spawn_t -= dt * Game.speed_mult()
	_customers = _customers.filter(func(c): return is_instance_valid(c))
	if _spawn_t <= 0.0:
		_spawn_t = 60.0 / rate() * randf_range(0.7, 1.3)
		if _customers.size() < 5 and display.count() > 0:
			_spawn_customer()


func _spawn_customer() -> void:
	var c := Customer.new()
	c.shop = self
	var a := randf() * TAU
	var r := randf_range(22.0, 30.0)
	c.spawn = global_position + Vector3(cos(a) * r, 0, sin(a) * r)
	c.position = c.spawn
	world.actors.add_child(c)
	_customers.append(c)


## A customer at the counter wants to buy. Returns true when served.
func serve(c: Customer) -> bool:
	if display.count() == 0:
		return false
	var n := mini(Bal.cafe_buy(level), display.count())
	var bought: Array[String] = []
	for i in n:
		var t := display.items[display.items.size() - 1]
		if Holder.fly(display, c.carry, t, 0.35):
			bought.append(t)
	# snappy models earn a little more here: people are chatting live
	var amount := 0.0
	for t in bought:
		amount += Game.sell([t], Bal.CAFE_MULT * (1.0 + Bal.latency_bonus(Defs.recipe_of(t))))
	Game.stats["customers"] = int(Game.stats["customers"]) + 1
	var where := c.global_position + Vector3(0, 2.2, 0)
	UI3D.pop_text(get_tree().current_scene, where, "+$%s" % Fmt.num(amount), Color(1.0, 0.88, 0.3), 64)
	world.sold.emit(amount, bought.size(), where)
	Sfx.play("cash", -6.0, 1.1)
	return true


func save_contents() -> Dictionary:
	return {"display": display.items.duplicate()}


func load_contents(d: Dictionary) -> void:
	Building.fill(display, d.get("display", []))


func status() -> String:
	return "Pays 30%% more than vans, more for snappy models. %d%% more visitors from decor nearby." % roundi(charm() * 100)


func info() -> Array:
	return [
		["hire", "About %.0f visitors / min" % rate()],
		["token", "Each buys up to %d" % Bal.cafe_buy(level)],
		["clock", "Models under %d ms earn up to +%d%%" % [int(Bal.SNAPPY_MS), roundi(Bal.SNAPPY_BONUS * 100)]],
		["storage", "Counter %d / %d" % [display.count(), display.capacity]],
	]


func upgrade_info() -> Array:
	var n := level + 1
	return [["Visitors / min", "%.1f" % Bal.cafe_rate(level), "%.1f" % Bal.cafe_rate(n)],
		["Counter", str(Bal.cafe_cap(level)), str(Bal.cafe_cap(n))]]


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
