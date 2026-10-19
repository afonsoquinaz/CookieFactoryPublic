class_name ServerB
extends Building
## The Inference Server: a whole serving stack in one building. Couriers
## drop power cells in the dock by the Router and fill the module bays; the
## Router sends a request packet into the glass bus, it stops under each bay
## its model needs for a dose (growing and changing colour), then flows into
## the GPU Core, which puts a batch of tokens on the bench in front for
## couriers to take.
##
## You choose the model (or leave it on Auto: the best one you can feed).
## Every 3 levels adds a module bay, so bigger models need a bigger server.

const W := 10.0
const D := 6.0
const BUS_Z := -1.3           # bus line (local z)
const BUS_X0 := -3.4          # where requests enter the bus
const BUS_X1 := 1.6           # core inlet
const ROUTER_X := -4.0
const CORE_X := 3.5
const DOCK_POS := Vector3(-3.9, 0, 1.2)
const BENCH_POS := Vector3(3.3, 0, 1.0)
const BAY_GAP := 0.68

var cells: Holder
var bench: Holder
var bays := {}                # resource -> Holder
var recipe := "pico"
var queue := 0
var packets: Array[Dictionary] = []   # {s, stops, wait, node, mat, got, dosing}
var _spawn_cd := 0.0
var _infer_t := 0.0
var _glow: OmniLight3D
var _puff_t := 0.0
var _fan: Node3D
var _spin := 0.0
var _bay_root: Node3D
var _bay_nodes := {}          # resource -> Node3D (for the dose squash)
var _make_label: Label3D
var _make_icon: Sprite3D
var _bench_label: Label3D
var _vent := Vector3.ZERO
var _bay_x := {}              # resource -> local x
var _inited := false
var _recheck := 0.0
var _starve := 0.0
var _blocked := {}            # model -> game time until Auto won't pick it
var _avail := 1.0             # how often the inputs were there lately (0..1)
var _on_recipe := 0.0         # seconds on the current model
var _want: Node3D
var _want_icon := ""
var _built_slots := 0


func _build() -> void:
	var dock := Node3D.new()
	dock.position = DOCK_POS
	add_child(dock)
	cells = Holder.new().setup(12, ["power"], Holder.Layout.GRID)
	cells.grid = Vector2i(3, 2)
	cells.cell = Vector2(0.36, 0.34)
	cells.max_visible = 12
	cells.position = Vector3(0, 0.82, 0)
	dock.add_child(cells)
	add_port(cells, null, "in")
	var tr := Node3D.new()
	tr.position = BENCH_POS
	add_child(tr)
	bench = Holder.new().setup(18, [], Holder.Layout.GRID)
	bench.grid = Vector2i(3, 2)
	bench.cell = Vector2(0.4, 0.38)
	bench.max_visible = 36
	bench.position = Vector3(0, 0.78, 0)
	tr.add_child(bench)
	add_port(bench, null, "out")
	_bay_root = Node3D.new()
	add_child(_bay_root)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(0.45, 0.85, 1.0)
	_glow.omni_range = 3.0
	_glow.light_energy = 0.0
	_glow.position = Vector3(CORE_X - 0.25, 0.9, BUS_Z + 1.0)
	add_child(_glow)
	_make_icon = UI3D.icon("tk_pico", 0.0036)
	_make_icon.position = Vector3(CORE_X - 0.3, 4.4, BUS_Z)
	add_child(_make_icon)
	_make_label = UI3D.label("", 34)
	_make_label.position = Vector3(CORE_X - 0.3, 5.0, BUS_Z)
	add_child(_make_label)
	_bench_label = UI3D.label("", 28)
	_bench_label.position = BENCH_POS + Vector3(0, 1.55, 0)
	add_child(_bench_label)
	var wb := UI3D.badge("power", Pal.STEEL_DARK, 0.55)
	wb.position = DOCK_POS + Vector3(0, 1.6, 0)
	add_child(wb)
	bench.changed.connect(_update_labels)
	cells.changed.connect(_update_labels)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-W * 0.5 + 0.1, -D * 0.5 + 0.1, W - 0.2, D - 0.2)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("server_house_%d" % t, func(): return ServerArt.house(t, W, D)), root)
	var len := BUS_X1 - BUS_X0
	Mats.inst(MeshKit.cached("server_frame_%d" % int(len * 10), func(): return ServerArt.frame(len)), root, MeshKit.at((BUS_X0 + BUS_X1) * 0.5, 0, BUS_Z))
	var glass := MeshInstance3D.new()
	glass.mesh = MeshKit.cached("server_glass_%d" % int(len * 10), func():
		var k := MeshKit.new()
		k.rbox(Vector3(len, 0.94, 1.06), 0.04, Color(1, 1, 1), MeshKit.at(0, ServerArt.Y, 0), 1)
		return k.commit())
	glass.material_override = Mats.glass()
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.position = Vector3((BUS_X0 + BUS_X1) * 0.5, 0, BUS_Z)
	root.add_child(glass)
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(len, 0.03, 0.82)
	belt.mesh = bm
	belt.position = Vector3((BUS_X0 + BUS_X1) * 0.5, ServerArt.Y - 0.44, BUS_Z)
	belt.material_override = ServerArt.belt_material()
	root.add_child(belt)
	# the router and its spinning fan (ServerArt pieces sit 1 m behind their origin)
	Mats.inst(MeshKit.cached("router_%d" % t, func(): return ServerArt.router(t)), root, MeshKit.at(ROUTER_X, 0, BUS_Z - ServerArt.TZ))
	_fan = Node3D.new()
	_fan.position = Vector3(ROUTER_X + (0.35 if t == 0 else 0.0), ServerArt.fan_y(t), BUS_Z + (0.0 if t != 0 else -0.1))
	root.add_child(_fan)
	Mats.inst(MeshKit.cached("router_fan", ServerArt.fan), _fan, Transform3D.IDENTITY, false)
	Mats.inst(MeshKit.cached("power_dock_%d" % t, func(): return ServerArt.power_dock(t)), root, MeshKit.at(DOCK_POS.x, 0, DOCK_POS.z))
	Mats.inst(MeshKit.cached("core_%d" % t, func(): return ServerArt.core(t)), root, MeshKit.at(CORE_X, 0, BUS_Z - ServerArt.TZ))
	Mats.inst(MeshKit.cached("bench_%d" % t, func(): return ServerArt.bench(t)), root, MeshKit.at(BENCH_POS.x, 0, BENCH_POS.z))
	var vt := ServerArt.vent_top(t)
	_vent = Vector3(CORE_X + vt.x, vt.y, BUS_Z - ServerArt.TZ + vt.z)
	_build_bays()


func _on_level() -> void:
	cells.capacity = Bal.power_cap(level)
	bench.capacity = Bal.bench_cap(level)
	for k in bays:
		bays[k].capacity = Bal.bay_cap(level)
	_pick_recipe()


# ---------------------------------------------------------------- model

func slots() -> int:
	return Defs.server_slots(level)


## Models this server could serve (enough bays for their resources).
func choices() -> Array[String]:
	var out: Array[String] = []
	for r in Defs.RECIPES:
		if (r["ings"] as Array).size() <= slots():
			out.append(r["id"])
	return out


## The best model whose resources the empire makes right now and has in
## stock (Auto steps back down for a while if a model starves it).
func auto_recipe() -> String:
	var best := "pico"
	var best_p := 0.0
	var now := Game.clock
	for id in choices():
		var r := Defs.recipe(id)
		if float(_blocked.get(id, 0.0)) > now:
			continue
		var ok := true
		for i in r["ings"]:
			# stick with the current model; only move up when the stock is there
			if not Game.can_make(i) or (id != recipe and not _in_stock(i)):
				ok = false
				break
		if ok and float(r["price"]) > best_p:
			best_p = float(r["price"])
			best = id
	return best


## Some of this resource is around (in our bay, or anywhere in the empire).
func _in_stock(i: String) -> bool:
	if bays.has(i) and (bays[i] as Holder).count() > 0:
		return true
	return world != null and world.stock(i) >= 6


func chosen() -> String:
	return str(data.get("recipe", ""))


## Sets the model ("" = Auto).
func choose(id: String) -> void:
	data["recipe"] = id
	_pick_recipe()
	Game.save_game()


func _pick_recipe() -> void:
	var want := chosen()
	if want == "" or not choices().has(want):
		want = auto_recipe()
	if want != recipe or not _inited or _built_slots != slots():
		_inited = true
		if want != recipe:
			_on_recipe = 0.0
			_avail = 1.0
		recipe = want
		_rebuild_bay_holders()
		_build_bays()
	_update_labels()


func ings() -> Array:
	return Defs.recipe(recipe)["ings"]


func _rebuild_bay_holders() -> void:
	var keep := {}
	for i in ings():
		keep[i] = true
	# resources the new model doesn't use go back to a Supply Depot
	for k in bays.keys():
		if not keep.has(k):
			var h: Holder = bays[k]
			var back := h.items.duplicate()
			h.queue_free()
			bays.erase(k)
			_return_to_store(back)
	for i in ings():
		if not bays.has(i):
			var h2 := Holder.new().setup(Bal.bay_cap(level), [i], Holder.Layout.NONE)
			add_child(h2)
			bays[i] = h2
			h2.changed.connect(_update_labels)
	ports = ports.filter(func(p): return p["holder"] == cells or p["holder"] == bench)
	for i in ings():
		add_port(bays[i], null, "in")


func _return_to_store(items: Array) -> void:
	if world == null or items.is_empty():
		return
	for n in world.bnodes.values():
		if n is StorageB and (n as StorageB).store.can_accept(str(items[0])):
			for t in items:
				if (n as StorageB).store.space() > 0:
					(n as StorageB).store.add(str(t), false)
			return


## Module meshes over the bus: one per bay; used ones show their resource.
func _build_bays() -> void:
	if _bay_root == null:
		return
	for c in _bay_root.get_children():
		c.queue_free()
	_bay_nodes.clear()
	_bay_x.clear()
	var n := slots()
	_built_slots = n
	var used := ings()
	var mid := (BUS_X0 + BUS_X1) * 0.5 + 0.2
	for i in n:
		var x := mid + (i - (n - 1) * 0.5) * BAY_GAP
		var ing: String = used[i] if i < used.size() else ""
		var node := Node3D.new()
		node.position = Vector3(x, ServerArt.Y + 0.47, BUS_Z)
		_bay_root.add_child(node)
		var s := 0.62
		var mesh := MeshKit.cached("bay_%s_%d" % [ing if ing != "" else "empty", tier], func(): return ServerArt.module(ing, tier))
		Mats.inst(mesh, node, MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(s, s, s)))
		if ing != "" and bays.has(ing):
			var b := UI3D.badge(ing, Pal.STEEL_DARK, 0.42)
			b.position = Vector3(0, ServerArt.module_top(tier) * s + 0.25, 0)
			node.add_child(b)
			_bay_nodes[ing] = node
			_bay_x[ing] = x
			var h: Holder = bays[ing]
			h.position = node.position + Vector3(0, 0.8, 0)


# ---------------------------------------------------------------- simulation

func _process(dt: float) -> void:
	super(dt)
	# Auto picks up new sources and labs as soon as they're ready
	_recheck -= dt
	if _recheck <= 0.0:
		_recheck = 1.5
		_pick_recipe()
	var mult := Game.speed_mult() * staff_mult()
	_spin = maxf(0.0, _spin - dt * 0.8)
	if _fan:
		_fan.rotation.y += dt * (2.0 + _spin * 18.0)
	var spd := Bal.bus_speed(level) * mult
	var len := BUS_X1 - BUS_X0
	_spawn_cd -= dt * mult
	var room: bool = packets.is_empty() or packets[packets.size() - 1]["s"] > Bal.PACKET_GAP + 0.4
	var has := _has_inputs()
	if room and _spawn_cd <= 0.0 and packets.size() < 10 and has:
		_spawn_cd = Bal.router_interval(level)
		_consume()
		_spawn_packet()
	_starve = 0.0 if has else _starve + dt
	_on_recipe += dt
	var ready := has or bench.space() < batch() or packets.size() >= 3
	_avail = lerpf(_avail, 1.0 if ready else 0.0, clampf(dt / 45.0, 0.0, 1.0))
	if chosen() == "" and recipe != "pico" and _on_recipe > 60.0 and (_avail < 0.35 or _starve > 90.0):
		# Auto: this model's supply can't keep up; serve something else for a while
		_blocked[recipe] = Game.clock + 300.0
		_starve = 0.0
		_pick_recipe()
	_show_want(_missing_input() if _starve > 3.0 and packets.is_empty() else "")
	for i in packets.size():
		var d: Dictionary = packets[i]
		var stop := len
		if i > 0:
			stop = minf(stop, packets[i - 1]["s"] - Bal.PACKET_GAP)
		if d["wait"] > 0.0:
			d["wait"] -= dt * mult
			if d["wait"] <= 0.0:
				_dose_land(d)
		else:
			var st := _next_stop(d)
			if st >= 0.0 and d["s"] >= st - 0.02:
				d["s"] = st
				_dose(d)
			elif d["s"] < stop:
				var lim := stop if st < 0.0 else minf(stop, st)
				d["s"] = minf(lim, d["s"] + spd * dt)
		var n: Node3D = d["node"]
		n.position = Vector3(BUS_X0 + d["s"], ServerArt.Y - 0.36 + sin(_t * 6.0 + float(d["s"]) * 3.0) * 0.03, BUS_Z)
		n.rotation.y = d["s"] * 2.0
	while not packets.is_empty() and (packets[0]["stops"] as Array).is_empty() and packets[0]["wait"] <= 0.0 and packets[0]["s"] >= len - 0.01 and queue < 2:
		var d0: Dictionary = packets.pop_front()
		var node: Node3D = d0["node"]
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
		tw.tween_callback(node.queue_free)
		queue += 1
		Sfx.play("plop", -6.0, 1.3)
	# the GPU core
	var busy := queue > 0
	if busy and bench.space() >= batch():
		_infer_t += dt * mult
		if _infer_t >= Bal.infer_time(level):
			_infer_t = 0.0
			queue -= 1
			_finish()
	_glow.light_energy = lerpf(_glow.light_energy, (1.1 + sin(_t * 9.0) * 0.2) if busy else 0.25, clampf(dt * 3.0, 0.0, 1.0))
	if busy:
		_puff_t -= dt
		if _puff_t <= 0.0 and is_inside_tree():
			_puff_t = 0.6
			Fx.puff(get_tree().current_scene, to_world(_vent.x, _vent.z, _vent.y), Color(0.9, 0.95, 1.0), 1)


func _has_inputs() -> bool:
	if cells.count() <= 0:
		return false
	for i in ings():
		if not bays.has(i) or (bays[i] as Holder).count() <= 0:
			return false
	return true


## The first input that's run out ("" if none).
func _missing_input() -> String:
	if cells.count() <= 0:
		return "power"
	for i in ings():
		if not bays.has(i) or (bays[i] as Holder).count() <= 0:
			return i
	return ""


## A bobbing bubble over the server with what it's waiting for.
func _show_want(icon: String) -> void:
	if icon == _want_icon:
		if _want:
			_want.position.y = 5.2 + sin(_t * 3.0) * 0.12
		return
	_want_icon = icon
	if _want:
		_want.queue_free()
		_want = null
	if icon == "":
		return
	_want = UI3D.badge(icon, Pal.TERRACOTTA, 0.9)
	_want.position = Vector3(ROUTER_X + 1.2, 5.2, BUS_Z)
	add_child(_want)


func _consume() -> void:
	cells.take("power")
	for i in ings():
		(bays[i] as Holder).take(i)
	_spin = 1.0
	bump(0.02)


func _spawn_packet() -> void:
	var n := Node3D.new()
	add_child(n)
	n.position = Vector3(BUS_X0, ServerArt.Y - 0.36, BUS_Z)
	var mi := Mats.inst(MeshKit.cached("request_packet", func():
		var k := MeshKit.new()
		k.sphere(0.2, Color(1, 1, 1, 0.55), MeshKit.at(0, 0.24, 0), 14, 10)
		k.torus(0.24, 0.025, Color(1, 1, 1, 0.8), MeshKit.xf(Vector3(0, 0.24, 0), Vector3(90, 0, 0)), 16, 4)
		return k.commit()), n, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", Color(0.7, 0.86, 1.0))
	mi.material_override = m
	n.scale = Vector3(0.6, 0.6, 0.6)
	var stops: Array = []
	for i in ings():
		if _bay_x.has(i):
			stops.append(i)
	stops.sort_custom(func(a, b): return _bay_x[a] < _bay_x[b])
	packets.append({"s": 0.0, "stops": stops, "node": n, "wait": 0.0, "mat": m, "got": 0, "dosing": ""})


## Distance along the bus of the next bay this packet stops under (-1 = none).
func _next_stop(d: Dictionary) -> float:
	var stops: Array = d["stops"]
	# the model may have changed since this packet left the router
	while not stops.is_empty() and not _bay_x.has(stops[0]):
		stops.pop_front()
	if stops.is_empty():
		return -1.0
	return float(_bay_x[stops[0]]) - BUS_X0


func _dose(d: Dictionary) -> void:
	var ing: String = (d["stops"] as Array).pop_front()
	d["wait"] = 0.3
	d["dosing"] = ing
	var node: Node3D = _bay_nodes.get(ing)
	if node:
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(1.06, 0.92, 1.06), 0.08)
		tw.tween_property(node, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var drop := Items.node(ing)
	add_child(drop)
	var top := Vector3(BUS_X0 + float(d["s"]), ServerArt.Y + 0.4, BUS_Z)
	drop.position = top
	drop.scale = Vector3(0.45, 0.45, 0.45)
	var tw2 := drop.create_tween()
	tw2.tween_property(drop, "position:y", ServerArt.Y - 0.2, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(drop, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
	tw2.tween_callback(drop.queue_free)
	Sfx.play("dispense", -12.0)


func _dose_land(d: Dictionary) -> void:
	var ing: String = d["dosing"]
	d["got"] = int(d["got"]) + 1
	var n: Node3D = d["node"]
	# the packet takes on a little of each resource's colour
	var m: ShaderMaterial = d["mat"]
	var cur: Color = m.get_shader_parameter("tint")
	m.set_shader_parameter("tint", cur.lerp(Defs.item_color(ing).lightened(0.25), 0.55))
	var s := 0.6 + int(d["got"]) * 0.06
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3(s * 1.2, s * 0.84, s * 1.2), 0.08)
	tw.tween_property(n, "scale", Vector3(s, s, s), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sfx.play("plop", -14.0, 1.2 + int(d["got"]) * 0.08)


func batch() -> int:
	return Bal.batch_size(level) + Game.perk("bigbatch")


func staff_mult() -> float:
	return Bal.engineer_boost(Game.workers_with("engineer", uid)) * compute_mult()


func _finish() -> void:
	var item := "t:" + recipe
	var n := batch()
	Game.stats["batches"] = int(Game.stats["batches"]) + 1
	Game.track("batches")
	Game.discover(recipe)
	Sfx.play("oven_ding", -12.0, 1.25)
	var mouth := to_world(CORE_X - 0.25, BUS_Z + 0.95, 0.1)
	var root := get_tree().current_scene if is_inside_tree() else null
	for i in n:
		if root == null:
			bench.add(item, false)
			continue
		var c := Items.node(item)
		root.add_child(c)
		c.global_position = mouth
		c.scale = Vector3(0.5, 0.5, 0.5)
		bench.incoming += 1
		var tw := c.create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_property(c, "global_position", mouth + Vector3(0, 0.3, 0) + global_transform.basis.z * 0.3, 0.14)
		tw.parallel().tween_property(c, "scale", Vector3.ONE, 0.14)
		tw.tween_property(c, "global_position", bench.next_slot_global(), 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			if is_instance_valid(c):
				c.queue_free()
			if is_instance_valid(bench):
				bench.incoming -= 1
				bench.add(item))
	if root:
		Fx.burst(root, mouth + Vector3(0, 0.3, 0), Defs.item_color(item).lightened(0.3), 6, false)
	bump(0.02)


func _update_labels() -> void:
	if _make_label == null:
		return
	var r := Defs.recipe(recipe)
	_make_label.text = "%s  $%s" % [r["name"], Fmt.num(Bal.item_value("t:" + recipe))]
	_make_icon.texture = Icons.tex("tk_" + recipe)
	_bench_label.text = str(bench.count())
	_bench_label.visible = bench.count() > 0


## Wants power and its model's resources, more when running low.
func need(t: String) -> float:
	var h: Holder = cells if t == "power" else bays.get(t)
	if h == null or not h.can_accept(t):
		return 0.0
	return (1.0 - float(h.count()) / maxf(1.0, h.capacity)) * 1.2


func missing() -> Array[String]:
	var out: Array[String] = []
	for i in ings():
		if not Game.can_make(i):
			out.append(i)
	return out


func save_contents() -> Dictionary:
	var d := {"cells": cells.items.duplicate(), "bench": bench.items.duplicate(), "queue": queue}
	for k in bays:
		d["bay_" + k] = bays[k].items.duplicate()
	return d


func load_contents(d: Dictionary) -> void:
	Building.fill(cells, d.get("cells", []))
	Building.fill(bench, d.get("bench", []))
	queue = int(d.get("queue", 0))
	for k in bays:
		Building.fill(bays[k], d.get("bay_" + k, []))


## Tokens per minute at most (router or core, whichever is slower).
func max_rate() -> float:
	var router_rate := 60.0 / Bal.router_interval(level)
	var core_rate := 60.0 / Bal.infer_time(level) * staff_mult()
	return minf(router_rate, core_rate) * batch()


func status() -> String:
	var m := missing()
	if not m.is_empty():
		return "Needs %s: build its source or lab" % Defs.item_name(m[0]).to_lower()
	var r := Defs.recipe(recipe)
	return "Serves %s · %d ms%s" % [r["name"], int(r["lat"]), "  (Auto)" if chosen() == "" else ""]


func info() -> Array:
	var out := [
		["tk_" + recipe, "%s: up to %s tokens / min" % [Defs.recipe(recipe)["name"], Fmt.num(max_rate())]],
		["power", "Power %d / %d" % [cells.count(), cells.capacity]],
	]
	for i in ings():
		out.append([i, "%s %d / %d" % [Defs.item_name(i), bays[i].count(), bays[i].capacity]])
	out.append(["token", "Bench %d / %d" % [bench.count(), bench.capacity]])
	out.append(["bay", "%d module bay%s" % [slots(), "s" if slots() > 1 else ""]])
	var engs := Game.workers_with("engineer", uid)
	if engs > 0:
		out.append(["engineer", "%d engineer%s: x%.1f speed" % [engs, "s" if engs > 1 else "", Bal.engineer_boost(engs)]])
	if compute_mult() > 1.0:
		out.append(["rack_row", "Datacenter gear nearby: +%d%% speed" % roundi((compute_mult() - 1.0) * 100)])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var out := []
	if Defs.server_slots(n) > slots():
		out.append(["Module bays", str(slots()), str(Defs.server_slots(n))])
	out.append(["Request every", "%.2fs" % Bal.router_interval(level), "%.2fs" % Bal.router_interval(n)])
	out.append(["Inference", "%.2fs" % Bal.infer_time(level), "%.2fs" % Bal.infer_time(n)])
	if Bal.batch_size(n) > Bal.batch_size(level):
		out.append(["Batch", str(Bal.batch_size(level)), str(Bal.batch_size(n))])
	return out
