class_name ShopB
extends Building
## A cookie shop. Stock the display (left pad); customers stroll in from the
## countryside, buy a few cookies each and pay 30% more than a van would.
## Flower beds, lamps, benches and trees nearby bring more customers.

var display: Holder
var zone: Zone
var _spawn_t := 3.0
var _customers: Array[Customer] = []
var _label: Label3D


func _build() -> void:
	display = Holder.new().setup(20, [], Holder.Layout.GRID)
	display.accept_cat = ["cookie", "box", "gift"]
	display.grid = Vector2i(4, 2)
	display.cell = Vector2(0.42, 0.34)
	display.max_visible = 40
	display.position = Vector3(-1.3, 0.86, -0.05)
	add_child(display)
	zone = add_zone(Zone.Kind.GIVE, [display], Vector2(-1.3, 1.35), Vector2(2.2, 1.1), Pal.TERRACOTTA)
	add_port(display, zone, "in")
	_label = UI3D.label("0/20", 28)
	_label.position = Vector3(-1.3, 1.75, 0.2)
	add_child(_label)
	var b := UI3D.badge("market", Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 3.9, -1.0)
	add_child(b)
	display.changed.connect(_update)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.0, -2.0, 6.0, 1.65), Rect2(-2.45, -0.4, 2.3, 0.75)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("shop_%d" % t, func(): return ShopB.mesh(t)), root)


func _on_level() -> void:
	display.capacity = Bal.shop_cap(level)
	_update()


func _update() -> void:
	_label.text = "%d/%d" % [display.count(), display.capacity]


func counter_point() -> Vector3:
	return to_world(1.35 + randf_range(-0.4, 0.4), 1.0 + randf_range(-0.2, 0.3))


func charm() -> float:
	return world.aura(global_position, "charm") + world.aura(global_position, "walk") * 0.5


func rate() -> float:
	return Bal.shop_rate(level) * (1.0 + charm())


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
	var n := mini(Bal.shop_buy(level), display.count())
	var bought: Array[String] = []
	for i in n:
		var t := display.items[display.items.size() - 1]
		if Holder.fly(display, c.carry, t, 0.35):
			bought.append(t)
	var amount := Game.sell(bought, Bal.SHOP_MULT)
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
	return "Pays 30%% more than vans. %d%% more customers from decor nearby." % roundi(charm() * 100)


func info() -> Array:
	return [
		["hire", "About %.0f customers / min" % rate()],
		["cookie", "Each buys up to %d" % Bal.shop_buy(level)],
		["storage", "Display %d / %d" % [display.count(), display.capacity]],
	]


func upgrade_info() -> Array:
	var n := level + 1
	return [["Customers / min", "%.1f" % Bal.shop_rate(level), "%.1f" % Bal.shop_rate(n)],
		["Display", str(Bal.shop_cap(level)), str(Bal.shop_cap(n))]]


static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var wall: Color = [Color(0.94, 0.9, 0.82), Color(0.94, 0.88, 0.78), Color(0.86, 0.8, 0.72), Color(0.92, 0.92, 0.9), Color(0.96, 0.93, 0.86)][t]
	var awning: Color = [Pal.TERRACOTTA, Pal.SAGE, Pal.TERRACOTTA, Pal.SLATE, Pal.CHOCO][t]
	var trim: Color = [Pal.WOOD_DARK, Pal.WOOD_DARK, Pal.BRICK_DARK, Pal.STEEL_DARK, Pal.GOLD][t]
	var h := 2.6 + t * 0.25
	# the shop house
	k.rbox(Vector3(6.0, 0.2, 1.8), 0.05, Pal.STONE, MeshKit.at(0, 0.1, -1.1))
	k.rbox(Vector3(5.8, h, 1.5), 0.08, wall, MeshKit.at(0, h * 0.5 + 0.1, -1.2))
	if t == 2:
		for row in int(h / 0.3):
			k.rbox(Vector3(5.82, 0.02, 1.52), 0.005, Pal.BRICK.lightened(0.1), MeshKit.at(0, 0.3 + row * 0.3, -1.2))
	k.rbox(Vector3(6.0, 0.18, 1.7), 0.04, trim, MeshKit.at(0, h + 0.15, -1.2))
	# big display window + door
	k.rbox(Vector3(2.6, 1.3, 0.06), 0.06, Color(0.75, 0.86, 0.9, 0.55), MeshKit.at(-1.2, 1.2, -0.43))
	k.rbox(Vector3(2.7, 0.08, 0.1), 0.02, trim, MeshKit.at(-1.2, 1.88, -0.42))
	k.rbox(Vector3(0.9, 1.7, 0.06), 0.08, trim, MeshKit.at(1.5, 0.95, -0.43))
	k.rbox(Vector3(0.6, 0.8, 0.07), 0.06, Color(0.75, 0.86, 0.9, 0.55), MeshKit.at(1.5, 1.25, -0.41))
	# striped awning
	for i in 12:
		k.rbox(Vector3(0.5, 0.05, 1.2), 0.015, awning if i % 2 == 0 else Pal.CREAM, MeshKit.xf(Vector3(-2.75 + i * 0.5, 2.25 + t * 0.1, -0.05), Vector3(-20, 0, 0)))
	# sign with a cookie
	k.rbox(Vector3(2.2, 0.55, 0.1), 0.08, trim, MeshKit.at(0, h - 0.05, -0.4))
	k.rbox(Vector3(2.0, 0.42, 0.11), 0.06, Pal.CREAM, MeshKit.at(0, h - 0.05, -0.39))
	Items.cookie_into(k, "choc", 0.16, 0.04, MeshKit.xf(Vector3(-0.7, h - 0.05, -0.32), Vector3(90, 0, 0)))
	Items.cookie_into(k, "sugar", 0.16, 0.04, MeshKit.xf(Vector3(0.7, h - 0.05, -0.32), Vector3(90, 0, 0)))
	# display counter in front of the window
	k.rbox(Vector3(2.3, 0.8, 0.75), 0.06, trim, MeshKit.at(-1.3, 0.4, -0.05))
	k.rbox(Vector3(2.4, 0.06, 0.85), 0.02, Pal.CREAM, MeshKit.at(-1.3, 0.83, -0.05))
	if t >= 1:
		# potted plants by the door
		for sx in [0.85, 2.15]:
			k.cyl(0.18, 0.35, Pal.TERRACOTTA, MeshKit.at(sx, 0, -0.2), 10, 0.03, 0.22)
			k.sphere(0.25, Pal.LEAF, MeshKit.at(sx, 0.55, -0.2), 9, 6)
	if t >= 3:
		for sx in [-1.0, 1.0]:
			k.cyl(0.04, 0.5, Pal.STEEL_DARK, MeshKit.xf(Vector3(sx * 2.7, h - 0.4, -0.35), Vector3(-60, 0, 0)), 6)
			k.sphere(0.12, Color(1.0, 0.92, 0.7, 0.4), MeshKit.at(sx * 2.7, h - 0.6, -0.05), 8, 5)
	if t >= 4:
		k.cone(0.5, 0.9, Pal.GOLD, MeshKit.at(0, h + 0.25, -1.2), 12)
		k.sphere(0.15, Pal.GOLD, MeshKit.at(0, h + 1.2, -1.2), 8, 5)
	return k.commit()
