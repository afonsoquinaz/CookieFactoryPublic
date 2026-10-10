class_name OvenB
extends LineModule
## End of a production line. Dough balls roll into it and come out as a
## batch of cookies on the output bench. Shows what the line makes above it,
## or a warning while it isn't connected to a Mixer.

const TRAY_POS := Vector3(1.25, 0, 0.3)

var tray: Holder
var tray_zone: Zone
var queue := 0
var _bake_t := 0.0
var _glow: OmniLight3D
var _smoke_t := 0.0
var _make: Label3D
var _make_icon: Sprite3D
var _warn: Label3D
var _count: Label3D
var _chimney := Vector3.ZERO


func _build() -> void:
	var tr := Node3D.new()
	tr.position = TRAY_POS
	tr.name = "TrayRoot"
	add_child(tr)
	tray = Holder.new().setup(18, [], Holder.Layout.GRID)
	tray.grid = Vector2i(3, 2)
	tray.cell = Vector2(0.4, 0.38)
	tray.max_visible = 36
	tray.position = Vector3(0, 0.78, 0)
	tr.add_child(tray)
	tray_zone = add_zone(Zone.Kind.TAKE, [tray], Vector2(1.05, 1.45), Vector2(1.8, 1.0), Pal.COOKIE)
	add_port(tray, tray_zone, "out")
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.62, 0.32)
	_glow.omni_range = 3.0
	_glow.light_energy = 0.0
	_glow.position = Vector3(-0.25, 0.9, 0.6)
	add_child(_glow)
	_make = UI3D.label("", 36, Color(1, 1, 1))
	_make.position = Vector3(-0.25, 4.3, TUBE_Z)
	add_child(_make)
	_make_icon = UI3D.icon("ck_shortbread", 0.0036)
	_make_icon.position = Vector3(-0.25, 3.75, TUBE_Z)
	add_child(_make_icon)
	_warn = UI3D.label("Connect to a Mixer", 34, Color(1.0, 0.75, 0.6))
	_warn.position = Vector3(-0.25, 4.3, TUBE_Z)
	_warn.visible = false
	add_child(_warn)
	_count = UI3D.label("0", 30)
	_count.position = TRAY_POS + Vector3(0, 1.55, 0)
	add_child(_count)
	tray.changed.connect(_update)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -2.0, 4.0, 2.1), Rect2(TRAY_POS.x - 0.7, TRAY_POS.z - 0.5, 1.4, 1.0)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("oven_%d" % t, func(): return LineArt.oven(t)), root)
	Mats.inst(MeshKit.cached("tray_%d" % t, func(): return LineArt.tray(t)), root, MeshKit.at(TRAY_POS.x, 0, TRAY_POS.z))
	_chimney = LineArt.chimney_top(t)
	_cap_prev = null
	_cap_next = null


func _on_level() -> void:
	tray.capacity = Bal.tray_cap(level)
	_update()


func _on_links() -> void:
	if _warn == null:
		return
	_warn.visible = line == null
	_make.visible = line != null
	_make_icon.visible = line != null
	if line:
		var r := Defs.recipe(line.product)
		_make.text = "%s  $%s" % [r["name"], Fmt.num(Bal.item_value("c:" + line.product))]
		_make_icon.texture = Icons.tex("ck_" + line.product)


func _update() -> void:
	_count.text = str(tray.count())
	_count.visible = tray.count() > 0


func batch() -> int:
	return Bal.batch_size(level) + Game.perk("bigbatch")


## A dough ball arrived from the tube.
func receive() -> void:
	queue += 1
	Sfx.play("plop", -4.0)


func _process(dt: float) -> void:
	super(dt)
	var mult := Game.speed_mult() * staff_mult()
	var busy := queue > 0
	if busy and line and tray.space() >= batch():
		_bake_t += dt * mult
		if _bake_t >= Bal.bake_time(level):
			_bake_t = 0.0
			queue -= 1
			_finish()
	_glow.light_energy = lerpf(_glow.light_energy, (1.1 + sin(_t * 9.0) * 0.2) if busy else 0.25, clampf(dt * 3.0, 0.0, 1.0))
	if busy:
		_smoke_t -= dt
		if _smoke_t <= 0.0:
			_smoke_t = 0.45
			Fx.puff(get_tree().current_scene, to_world(_chimney.x, _chimney.z, _chimney.y), Color(0.92, 0.92, 0.92), 1)
	if _warn.visible:
		_warn.position.y = 4.3 + sin(_t * 3.0) * 0.06


func staff_mult() -> float:
	return Bal.chef_boost(Game.workers_with("chef", uid))


func _finish() -> void:
	var item := "c:" + line.product
	var n := batch()
	Game.stats["batches"] = int(Game.stats["batches"]) + 1
	Game.discover(line.product)
	Sfx.play("oven_ding", -10.0)
	var mouth := to_world(-0.25, 0.1, 0.95)
	for i in n:
		var c := Items.node(item)
		get_tree().current_scene.add_child(c)
		c.global_position = mouth
		c.scale = Vector3(0.5, 0.5, 0.5)
		tray.incoming += 1
		var tw := c.create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_property(c, "global_position", mouth + Vector3(0, 0.3, 0) + global_transform.basis.z * 0.3, 0.14)
		tw.parallel().tween_property(c, "scale", Vector3.ONE, 0.14)
		tw.tween_property(c, "global_position", tray.next_slot_global(), 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			c.queue_free()
			if is_instance_valid(tray):
				tray.incoming -= 1
				tray.add(item))
	Fx.puff(get_tree().current_scene, mouth + Vector3(0, 0.3, 0), Color(1, 0.97, 0.92), 4)
	bump(0.03)


func save_contents() -> Dictionary:
	return {"tray": tray.items.duplicate(), "queue": queue}


func load_contents(d: Dictionary) -> void:
	Building.fill(tray, d.get("tray", []))
	queue = int(d.get("queue", 0))


func status() -> String:
	if line == null:
		return "Not connected: needs a Mixer to its left, joined by tubes or hoppers"
	return "Bakes %s" % Defs.recipe(line.product)["name"]


func info() -> Array:
	var out := [
		["oven", "Bakes %d cookies every %.1fs" % [batch(), Bal.bake_time(level) / staff_mult()]],
		["cookie", "Output %d / %d" % [tray.count(), tray.capacity]],
	]
	var chefs := Game.workers_with("chef", uid)
	if chefs > 0:
		out.append(["chef", "%d chef%s: x%.1f speed" % [chefs, "s" if chefs > 1 else "", staff_mult()]])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var out := [["Bake time", "%.2fs" % Bal.bake_time(level), "%.2fs" % Bal.bake_time(n)]]
	if Bal.batch_size(n) > Bal.batch_size(level):
		out.append(["Batch", str(Bal.batch_size(level)), str(Bal.batch_size(n))])
	out.append(["Output", str(Bal.tray_cap(level)), str(Bal.tray_cap(n))])
	return out
