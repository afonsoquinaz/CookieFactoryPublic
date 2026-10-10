class_name BakeryB
extends Building
## The Bakery: a whole production line in one building. Porters drop wheat
## in the bin by the Mixer and fill the ingredient silos; the Mixer rolls a
## dough ball into the glass tube, it stops under each silo its recipe needs
## for a dose (growing and changing colour), then rolls into the Oven, which
## puts a batch of cookies on the bench in front for porters to take.
##
## You choose the recipe (or leave it on Auto: the best one you can make).
## Every 3 levels adds a silo, so richer recipes need a bigger bakery.

const W := 10.0
const D := 6.0
const TUBE_Z := -1.3           # tube line (local z)
const TUBE_X0 := -3.4          # where dough enters the tube
const TUBE_X1 := 1.6           # oven inlet
const MIXER_X := -4.0
const OVEN_X := 3.5
const BIN_POS := Vector3(-3.9, 0, 1.2)
const TRAY_POS := Vector3(3.3, 0, 1.0)
const SILO_GAP := 0.68

var flour: Holder
var tray: Holder
var silos := {}                # ingredient -> Holder
var recipe := "shortbread"
var queue := 0
var doughs: Array[Dictionary] = []   # {s, need, stops, wait, node, mat, got, dosing}
var _spawn_cd := 0.0
var _bake_t := 0.0
var _glow: OmniLight3D
var _smoke_t := 0.0
var _hook: Node3D
var _spin := 0.0
var _silo_root: Node3D
var _silo_nodes := {}          # ingredient -> Node3D (for the dose squash)
var _make_label: Label3D
var _make_icon: Sprite3D
var _tray_label: Label3D
var _chimney := Vector3.ZERO
var _silo_x := {}              # ingredient -> local x
var _inited := false
var _recheck := 0.0
var _built_slots := 0


func _build() -> void:
	var bin := Node3D.new()
	bin.position = BIN_POS
	add_child(bin)
	flour = Holder.new().setup(12, ["wheat"], Holder.Layout.GRID)
	flour.grid = Vector2i(3, 2)
	flour.cell = Vector2(0.36, 0.34)
	flour.max_visible = 12
	flour.position = Vector3(0, 0.82, 0)
	bin.add_child(flour)
	add_port(flour, null, "in")
	var tr := Node3D.new()
	tr.position = TRAY_POS
	add_child(tr)
	tray = Holder.new().setup(18, [], Holder.Layout.GRID)
	tray.grid = Vector2i(3, 2)
	tray.cell = Vector2(0.4, 0.38)
	tray.max_visible = 36
	tray.position = Vector3(0, 0.78, 0)
	tr.add_child(tray)
	add_port(tray, null, "out")
	_silo_root = Node3D.new()
	add_child(_silo_root)
	_glow = OmniLight3D.new()
	_glow.light_color = Color(1.0, 0.62, 0.32)
	_glow.omni_range = 3.0
	_glow.light_energy = 0.0
	_glow.position = Vector3(OVEN_X - 0.25, 0.9, TUBE_Z + 1.0)
	add_child(_glow)
	_make_icon = UI3D.icon("ck_shortbread", 0.0036)
	_make_icon.position = Vector3(OVEN_X - 0.3, 4.4, TUBE_Z)
	add_child(_make_icon)
	_make_label = UI3D.label("", 34)
	_make_label.position = Vector3(OVEN_X - 0.3, 5.0, TUBE_Z)
	add_child(_make_label)
	_tray_label = UI3D.label("", 28)
	_tray_label.position = TRAY_POS + Vector3(0, 1.55, 0)
	add_child(_tray_label)
	var wb := UI3D.badge("wheat", Pal.STEEL_DARK, 0.55)
	wb.position = BIN_POS + Vector3(0, 1.6, 0)
	add_child(wb)
	tray.changed.connect(_update_labels)
	flour.changed.connect(_update_labels)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-W * 0.5 + 0.1, -D * 0.5 + 0.1, W - 0.2, D - 0.2)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("bakery_house_%d" % t, func(): return TownArt.bakery_house(t, W, D)), root)
	var len := TUBE_X1 - TUBE_X0
	Mats.inst(MeshKit.cached("bakery_frame_%d" % int(len * 10), func(): return LineArt.frame(len)), root, MeshKit.at((TUBE_X0 + TUBE_X1) * 0.5, 0, TUBE_Z))
	var glass := MeshInstance3D.new()
	glass.mesh = MeshKit.cached("bakery_glass_%d" % int(len * 10), func():
		var k := MeshKit.new()
		k.rbox(Vector3(len, 0.94, 1.06), 0.04, Color(1, 1, 1), MeshKit.at(0, LineArt.Y, 0), 1)
		return k.commit())
	glass.material_override = Mats.glass()
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.position = Vector3((TUBE_X0 + TUBE_X1) * 0.5, 0, TUBE_Z)
	root.add_child(glass)
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(len, 0.03, 0.82)
	belt.mesh = bm
	belt.position = Vector3((TUBE_X0 + TUBE_X1) * 0.5, LineArt.Y - 0.44, TUBE_Z)
	belt.material_override = LineArt.belt_material()
	root.add_child(belt)
	# mixer and its spinning hook (LineArt pieces sit 1 m behind their origin)
	Mats.inst(MeshKit.cached("mixer_%d" % t, func(): return LineArt.mixer(t)), root, MeshKit.at(MIXER_X, 0, TUBE_Z - LineArt.TZ))
	_hook = Node3D.new()
	_hook.position = Vector3(MIXER_X, 1.85 * (1.0 + t * 0.06), TUBE_Z)
	root.add_child(_hook)
	Mats.inst(MeshKit.cached("mixer_hook", LineArt.hook), _hook, Transform3D.IDENTITY, false)
	Mats.inst(MeshKit.cached("flour_bin_%d" % t, func(): return TownArt.flour_bin(t)), root, MeshKit.at(BIN_POS.x, 0, BIN_POS.z))
	Mats.inst(MeshKit.cached("oven_%d" % t, func(): return LineArt.oven(t)), root, MeshKit.at(OVEN_X, 0, TUBE_Z - LineArt.TZ))
	Mats.inst(MeshKit.cached("tray_%d" % t, func(): return LineArt.tray(t)), root, MeshKit.at(TRAY_POS.x, 0, TRAY_POS.z))
	var ch := LineArt.chimney_top(t)
	_chimney = Vector3(OVEN_X + ch.x, ch.y, TUBE_Z - LineArt.TZ + ch.z)
	_build_silos()


func _on_level() -> void:
	flour.capacity = Bal.flour_cap(level)
	tray.capacity = Bal.tray_cap(level)
	for k in silos:
		silos[k].capacity = Bal.silo_cap(level)
	_pick_recipe()


# ---------------------------------------------------------------- recipe

func slots() -> int:
	return Defs.bakery_slots(level)


## Recipes this bakery could bake (enough silos, unlocked by the Hall).
func choices() -> Array[String]:
	var out: Array[String] = []
	for r in Defs.RECIPES:
		if (r["ings"] as Array).size() <= slots() and Defs.recipe_level(r["id"]) <= Game.level:
			out.append(r["id"])
	return out


## The best recipe whose ingredients the empire makes right now.
func auto_recipe() -> String:
	var best := "shortbread"
	var best_p := 0.0
	for id in choices():
		var r := Defs.recipe(id)
		var ok := true
		for i in r["ings"]:
			if not Game.can_make(i):
				ok = false
				break
		if ok and float(r["price"]) > best_p:
			best_p = float(r["price"])
			best = id
	return best


func chosen() -> String:
	return str(data.get("recipe", ""))


## Sets the recipe ("" = Auto).
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
		recipe = want
		_rebuild_silo_holders()
		_build_silos()
	_update_labels()


func ings() -> Array:
	return Defs.recipe(recipe)["ings"]


func _rebuild_silo_holders() -> void:
	var keep := {}
	for i in ings():
		keep[i] = true
	# ingredients the new recipe doesn't use go back to the Hall
	for k in silos.keys():
		if not keep.has(k):
			var h: Holder = silos[k]
			var back := h.items.duplicate()
			h.queue_free()
			silos.erase(k)
			_return_to_hall(back)
	for i in ings():
		if not silos.has(i):
			var h2 := Holder.new().setup(Bal.silo_cap(level), [i], Holder.Layout.NONE)
			add_child(h2)
			silos[i] = h2
			h2.changed.connect(_update_labels)
	ports = ports.filter(func(p): return p["holder"] == flour or p["holder"] == tray)
	for i in ings():
		add_port(silos[i], null, "in")


func _return_to_hall(items: Array) -> void:
	if world == null or items.is_empty():
		return
	for n in world.bnodes.values():
		if n is HallB:
			for t in items:
				if (n as HallB).store.space() > 0:
					(n as HallB).store.add(str(t), false)
			return


## Silo meshes over the tube: one per slot; used ones show their ingredient.
func _build_silos() -> void:
	if _silo_root == null:
		return
	for c in _silo_root.get_children():
		c.queue_free()
	_silo_nodes.clear()
	_silo_x.clear()
	var n := slots()
	_built_slots = n
	var used := ings()
	var mid := (TUBE_X0 + TUBE_X1) * 0.5 + 0.2
	for i in n:
		var x := mid + (i - (n - 1) * 0.5) * SILO_GAP
		var ing: String = used[i] if i < used.size() else ""
		var node := Node3D.new()
		node.position = Vector3(x, LineArt.Y + 0.47, TUBE_Z)
		_silo_root.add_child(node)
		var s := 0.62
		var mesh := MeshKit.cached("silo_%s_%d" % [ing if ing != "" else "empty", tier], func(): return LineArt.silo(ing if ing != "" else "wheat", tier) if ing != "" else _empty_silo(tier))
		Mats.inst(mesh, node, MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(s, s, s)))
		if ing != "" and silos.has(ing):
			var b := UI3D.badge(ing, Pal.STEEL_DARK, 0.42)
			b.position = Vector3(0, [1.25, 1.4, 1.75, 1.75, 1.75][tier], 0)
			node.add_child(b)
			_silo_nodes[ing] = node
			_silo_x[ing] = x
			var h: Holder = silos[ing]
			h.position = node.position + Vector3(0, 0.8, 0)


static func _empty_silo(t: int) -> Mesh:
	var k := MeshKit.new()
	k.add_mesh(LineArt.silo("milk", t))
	return k.commit()


# ---------------------------------------------------------------- simulation

func _process(dt: float) -> void:
	super(dt)
	# Auto picks up new farms and kitchens as soon as they're ready
	_recheck -= dt
	if _recheck <= 0.0:
		_recheck = 1.5
		_pick_recipe()
	var mult := Game.speed_mult() * staff_mult()
	_spin = maxf(0.0, _spin - dt * 0.8)
	if _hook:
		_hook.rotation.y += dt * (1.0 + _spin * 12.0)
	var spd := Bal.belt_speed(level) * mult
	var len := TUBE_X1 - TUBE_X0
	_spawn_cd -= dt * mult
	var room: bool = doughs.is_empty() or doughs[doughs.size() - 1]["s"] > Bal.DOUGH_GAP + 0.4
	if room and _spawn_cd <= 0.0 and doughs.size() < 10 and _has_inputs():
		_spawn_cd = Bal.mixer_interval(level)
		_consume()
		_spawn_dough()
	for i in doughs.size():
		var d: Dictionary = doughs[i]
		var stop := len
		if i > 0:
			stop = minf(stop, doughs[i - 1]["s"] - Bal.DOUGH_GAP)
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
		n.position = Vector3(TUBE_X0 + d["s"], LineArt.Y - 0.36, TUBE_Z)
		n.rotation.z = -d["s"] / 0.22
	while not doughs.is_empty() and (doughs[0]["stops"] as Array).is_empty() and doughs[0]["wait"] <= 0.0 and doughs[0]["s"] >= len - 0.01 and queue < 2:
		var d0: Dictionary = doughs.pop_front()
		var node: Node3D = d0["node"]
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
		tw.tween_callback(node.queue_free)
		queue += 1
		Sfx.play("plop", -6.0)
	# the oven
	var busy := queue > 0
	if busy and tray.space() >= batch():
		_bake_t += dt * mult
		if _bake_t >= Bal.bake_time(level):
			_bake_t = 0.0
			queue -= 1
			_finish()
	_glow.light_energy = lerpf(_glow.light_energy, (1.1 + sin(_t * 9.0) * 0.2) if busy else 0.25, clampf(dt * 3.0, 0.0, 1.0))
	if busy:
		_smoke_t -= dt
		if _smoke_t <= 0.0 and is_inside_tree():
			_smoke_t = 0.45
			Fx.puff(get_tree().current_scene, to_world(_chimney.x, _chimney.z, _chimney.y), Color(0.92, 0.92, 0.92), 1)


func _has_inputs() -> bool:
	if flour.count() <= 0:
		return false
	for i in ings():
		if not silos.has(i) or (silos[i] as Holder).count() <= 0:
			return false
	return true


func _consume() -> void:
	flour.take("wheat")
	for i in ings():
		(silos[i] as Holder).take(i)
	_spin = 1.0
	bump(0.02)


func _spawn_dough() -> void:
	var n := Node3D.new()
	add_child(n)
	n.position = Vector3(TUBE_X0, LineArt.Y - 0.36, TUBE_Z)
	var mi := Mats.inst(MeshKit.cached("dough_ball", func():
		var k := MeshKit.new()
		k.sphere(0.24, Color(1, 1, 1), MeshKit.at(0, 0.24, 0), 14, 10)
		return k.commit()), n, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", Color(0.94, 0.88, 0.74))
	mi.material_override = m
	n.scale = Vector3(0.6, 0.6, 0.6)
	var stops: Array = []
	for i in ings():
		if _silo_x.has(i):
			stops.append(i)
	stops.sort_custom(func(a, b): return _silo_x[a] < _silo_x[b])
	doughs.append({"s": 0.0, "stops": stops, "node": n, "wait": 0.0, "mat": m, "got": 0, "dosing": ""})


## Distance along the tube of the next silo this ball stops under (-1 = none).
func _next_stop(d: Dictionary) -> float:
	var stops: Array = d["stops"]
	if stops.is_empty():
		return -1.0
	return float(_silo_x[stops[0]]) - TUBE_X0


func _dose(d: Dictionary) -> void:
	var ing: String = (d["stops"] as Array).pop_front()
	d["wait"] = 0.3
	d["dosing"] = ing
	var node: Node3D = _silo_nodes.get(ing)
	if node:
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(1.06, 0.92, 1.06), 0.08)
		tw.tween_property(node, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var drop := Items.node(ing)
	add_child(drop)
	var top := Vector3(TUBE_X0 + float(d["s"]), LineArt.Y + 0.4, TUBE_Z)
	drop.position = top
	drop.scale = Vector3(0.45, 0.45, 0.45)
	var tw2 := drop.create_tween()
	tw2.tween_property(drop, "position:y", LineArt.Y - 0.2, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(drop, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
	tw2.tween_callback(drop.queue_free)
	Sfx.play("dispense", -12.0)


func _dose_land(d: Dictionary) -> void:
	var ing: String = d["dosing"]
	d["got"] = int(d["got"]) + 1
	var n: Node3D = d["node"]
	(d["mat"] as ShaderMaterial).set_shader_parameter("tint", Line_TONES.get(ing, Color(0.95, 0.88, 0.72)))
	var s := 0.6 + int(d["got"]) * 0.06
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3(s * 1.2, s * 0.84, s * 1.2), 0.08)
	tw.tween_property(n, "scale", Vector3(s, s, s), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if ing in ["chocolate", "cocoa", "hazelnut"]:
		Mats.inst(MeshKit.cached("dough_chips_" + ing, func():
			var k := MeshKit.new()
			for i in 7:
				var a := TAU * i / 7.0
				k.ellipsoid(Vector3(0.05, 0.035, 0.05), Pal.CHOCO if ing != "hazelnut" else Color(0.6, 0.4, 0.24), MeshKit.at(cos(a) * 0.19, 0.3 + sin(a * 3.0) * 0.1, sin(a) * 0.19), 6, 4)
			return k.commit()), n, Transform3D.IDENTITY, false)
	Sfx.play("plop", -14.0, 1.0 + int(d["got"]) * 0.08)


const Line_TONES := {
	"sugar": Color(0.97, 0.9, 0.76), "cocoa": Color(0.7, 0.52, 0.4), "egg": Color(0.97, 0.86, 0.62),
	"milk": Color(0.98, 0.93, 0.8), "butter": Color(0.98, 0.88, 0.6), "chocolate": Color(0.62, 0.44, 0.32),
	"oats": Color(0.88, 0.78, 0.6), "jam": Color(0.9, 0.7, 0.62), "hazelnut": Color(0.8, 0.64, 0.46),
	"honey": Color(0.96, 0.8, 0.5), "caramel": Color(0.9, 0.7, 0.45), "vanilla": Color(0.98, 0.93, 0.8),
	"praline": Color(0.74, 0.56, 0.4), "cinnamon": Color(0.86, 0.66, 0.46), "candied": Color(0.96, 0.78, 0.5),
}


func batch() -> int:
	return Bal.batch_size(level) + Game.perk("bigbatch")


func staff_mult() -> float:
	return Bal.chef_boost(Game.workers_with("chef", uid))


func _finish() -> void:
	var item := "c:" + recipe
	var n := batch()
	Game.stats["batches"] = int(Game.stats["batches"]) + 1
	Game.discover(recipe)
	Sfx.play("oven_ding", -12.0)
	var mouth := to_world(OVEN_X - 0.25, TUBE_Z + 0.95, 0.1)
	var root := get_tree().current_scene if is_inside_tree() else null
	for i in n:
		if root == null:
			tray.add(item, false)
			continue
		var c := Items.node(item)
		root.add_child(c)
		c.global_position = mouth
		c.scale = Vector3(0.5, 0.5, 0.5)
		tray.incoming += 1
		var tw := c.create_tween()
		tw.tween_interval(i * 0.06)
		tw.tween_property(c, "global_position", mouth + Vector3(0, 0.3, 0) + global_transform.basis.z * 0.3, 0.14)
		tw.parallel().tween_property(c, "scale", Vector3.ONE, 0.14)
		tw.tween_property(c, "global_position", tray.next_slot_global(), 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			if is_instance_valid(c):
				c.queue_free()
			if is_instance_valid(tray):
				tray.incoming -= 1
				tray.add(item))
	if root:
		Fx.puff(root, mouth + Vector3(0, 0.3, 0), Color(1, 0.97, 0.92), 4)
	bump(0.02)


func _update_labels() -> void:
	if _make_label == null:
		return
	var r := Defs.recipe(recipe)
	_make_label.text = "%s  $%s" % [r["name"], Fmt.num(Bal.item_value("c:" + recipe))]
	_make_icon.texture = Icons.tex("ck_" + recipe)
	_tray_label.text = str(tray.count())
	_tray_label.visible = tray.count() > 0


## Wants wheat and its recipe's ingredients, more when running low.
func need(t: String) -> float:
	var h: Holder = flour if t == "wheat" else silos.get(t)
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
	var d := {"flour": flour.items.duplicate(), "tray": tray.items.duplicate(), "queue": queue}
	for k in silos:
		d["silo_" + k] = silos[k].items.duplicate()
	return d


func load_contents(d: Dictionary) -> void:
	Building.fill(flour, d.get("flour", []))
	Building.fill(tray, d.get("tray", []))
	queue = int(d.get("queue", 0))
	for k in silos:
		Building.fill(silos[k], d.get("silo_" + k, []))


## Cookies per minute at most (mixer or oven, whichever is slower).
func max_rate() -> float:
	var mixer_rate := 60.0 / Bal.mixer_interval(level)
	var oven_rate := 60.0 / Bal.bake_time(level) * staff_mult()
	return minf(mixer_rate, oven_rate) * batch()


func status() -> String:
	var m := missing()
	if not m.is_empty():
		return "Needs %s: build its farm or kitchen" % Defs.item_name(m[0]).to_lower()
	return "Bakes %s%s" % [Defs.recipe(recipe)["name"], "  (Auto)" if chosen() == "" else ""]


func info() -> Array:
	var out := [
		["ck_" + recipe, "%s: up to %s cookies / min" % [Defs.recipe(recipe)["name"], Fmt.num(max_rate())]],
		["wheat", "Wheat %d / %d" % [flour.count(), flour.capacity]],
	]
	for i in ings():
		out.append([i, "%s %d / %d" % [Defs.item_name(i), silos[i].count(), silos[i].capacity]])
	out.append(["cookie", "Bench %d / %d" % [tray.count(), tray.capacity]])
	out.append(["hopper", "%d silo%s" % [slots(), "s" if slots() > 1 else ""]])
	var chefs := Game.workers_with("chef", uid)
	if chefs > 0:
		out.append(["chef", "%d chef%s: x%.1f speed" % [chefs, "s" if chefs > 1 else "", staff_mult()]])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var out := []
	if Defs.bakery_slots(n) > slots():
		out.append(["Silos", str(slots()), str(Defs.bakery_slots(n))])
	out.append(["Dough every", "%.2fs" % Bal.mixer_interval(level), "%.2fs" % Bal.mixer_interval(n)])
	out.append(["Bake time", "%.2fs" % Bal.bake_time(level), "%.2fs" % Bal.bake_time(n)])
	if Bal.batch_size(n) > Bal.batch_size(level):
		out.append(["Batch", str(Bal.batch_size(level)), str(Bal.batch_size(n))])
	return out
