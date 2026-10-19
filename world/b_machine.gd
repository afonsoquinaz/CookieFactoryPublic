class_name MachineB
extends Building
## Labs turn resources into better ones (Chip Fab, Data Refinery, Fine-Tune
## Lab, HBM Works, RLHF Gym, Synth Lab). Inputs go on the left pad, results
## come off the right.

const IN_POS := Vector3(-1.05, 0, 0.15)
const OUT_POS := Vector3(1.05, 0, 0.15)

var inputs := {}               # item -> Holder
var output: Holder
var crafting := false
var _craft_t := 0.0
var _pending: Array[String] = []
var _anim: Node3D
var _labels := {}
var _out_label: Label3D
var _steam_t := 0.0
var _starve := 0.0
var _want: Node3D
var _want_icon := ""


func _build() -> void:
	var tb := Node3D.new()
	tb.position = IN_POS
	add_child(tb)
	var ob := Node3D.new()
	ob.position = OUT_POS
	add_child(ob)
	var hs: Array[Holder] = []
	var i := 0
	var n := (def["in"] as Dictionary).size()
	for t in def["in"]:
		var h2 := Holder.new().setup(10, [t], Holder.Layout.GRID)
		h2.grid = Vector2i(1, 2)
		h2.cell = Vector2(0.42, 0.36)
		h2.max_visible = 12
		h2.position = Vector3((i - (n - 1) * 0.5) * 0.5, 0.78, 0)
		tb.add_child(h2)
		inputs[t] = h2
		hs.append(h2)
		var l := UI3D.label("0", 24)
		l.position = IN_POS + Vector3((i - (n - 1) * 0.5) * 0.5, 1.45, 0.1)
		add_child(l)
		_labels[t] = l
		h2.changed.connect(_update)
		i += 1
	output = Holder.new().setup(10, [], Holder.Layout.GRID)
	output.grid = Vector2i(2, 2)
	output.cell = Vector2(0.42, 0.36)
	output.max_visible = 24
	output.position = Vector3(0, 0.78, 0)
	ob.add_child(output)
	for h3 in hs:
		add_port(h3, null, "in")
	add_port(output, null, "out")
	_out_label = UI3D.label("0", 26)
	_out_label.position = OUT_POS + Vector3(0, 1.45, 0.1)
	add_child(_out_label)
	output.changed.connect(_update)
	var icon: String = def["icon"]
	if def.has("out"):
		icon = (def["out"] as Dictionary).keys()[0]
	var b := UI3D.badge(icon, Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 3.4, -0.9)
	add_child(b)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -2.0, 4.0, 2.65)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("mach_%s_%d" % [kind, t], func(): return LabArt.machine(kind, t)), root)
	Mats.inst(MeshKit.cached("bench_%d" % t, func(): return LabArt.bench(t)), root, MeshKit.at(IN_POS.x, 0, IN_POS.z))
	Mats.inst(MeshKit.cached("bench_%d" % t, func(): return LabArt.bench(t)), root, MeshKit.at(OUT_POS.x, 0, OUT_POS.z))
	_anim = Node3D.new()
	_anim.position = LabArt.anim_pivot(kind, t)
	root.add_child(_anim)
	Mats.inst(MeshKit.cached("machpart_%s_%d" % [kind, t], func(): return LabArt.part(kind, t)), _anim, Transform3D.IDENTITY, false)


func _on_level() -> void:
	for t in inputs:
		inputs[t].capacity = Bal.machine_in_cap(level)
	output.capacity = Bal.machine_out_cap(level)
	_update()


func _update() -> void:
	for t in _labels:
		var h: Holder = inputs[t]
		var need: int = def["in"][t]
		(_labels[t] as Label3D).text = "%d" % h.count()
		(_labels[t] as Label3D).modulate = Color(1.0, 0.72, 0.62) if h.count() < need else Color(1, 1, 1)
	_out_label.text = "%d/%d" % [output.count(), output.capacity]


func craft_time() -> float:
	return Bal.craft_time(kind, level) / staff_mult()


func staff_mult() -> float:
	return Bal.engineer_boost(Game.workers_with("engineer", uid)) * compute_mult()


## What to make next: [consume {item: n}, produce [items]] or [].
func _recipe_ready() -> Array:
	for t in def["in"]:
		if inputs[t].count() < int(def["in"][t]):
			return []
	var outs: Array[String] = []
	for t in def["out"]:
		for i in int(def["out"][t]):
			outs.append(t)
	return [def["in"], outs]


func _process(dt: float) -> void:
	super(dt)
	var mult := Game.speed_mult()
	if not crafting:
		var r := _recipe_ready()
		if not r.is_empty() and output.space() >= (r[1] as Array).size():
			for t in r[0]:
				var src: Holder = inputs[t]
				for i in int(r[0][t]):
					src.take(t)
			_pending.assign(r[1])
			crafting = true
			_craft_t = 0.0
			output.incoming += _pending.size()
	else:
		_craft_t += dt * mult
		if _craft_t >= craft_time():
			crafting = false
			output.incoming -= _pending.size()
			for t in _pending:
				output.add(t)
			_pending.clear()
			bump(0.04)
			Sfx.play("pop", -10.0, 1.2)
	_starve = 0.0 if crafting else _starve + dt
	_show_want(_missing() if _starve > 4.0 else "")
	if _anim:
		LabArt.animate(kind, _anim, _t, crafting)
	if crafting and kind in ["fab", "hbm_works", "synth_lab"]:
		_steam_t -= dt
		if _steam_t <= 0.0:
			_steam_t = 0.5
			Fx.puff(get_tree().current_scene, _anim.global_position + Vector3(0, 0.5, 0), Color(0.95, 0.95, 0.95), 1)


## The input it's short of ("" if none or it's just full).
func _missing() -> String:
	if output.space() <= 0:
		return ""
	for t in def["in"]:
		if inputs[t].count() < int(def["in"][t]):
			return t
	return ""


func _show_want(icon: String) -> void:
	if icon == _want_icon:
		if _want:
			_want.position.y = 4.4 + sin(_t * 3.0) * 0.12
		return
	_want_icon = icon
	if _want:
		_want.queue_free()
		_want = null
	if icon == "":
		return
	_want = UI3D.badge(icon, Pal.TERRACOTTA, 0.8)
	_want.position = Vector3(0, 4.4, -0.9)
	add_child(_want)


## Needs whatever its recipe takes, more when nearly out.
func need(t: String) -> float:
	for k in inputs:
		var h: Holder = inputs[k]
		if h.can_accept(t):
			var f := float(h.count()) / maxf(1.0, h.capacity)
			return (1.0 - f) * 0.8
	return 0.0


func save_contents() -> Dictionary:
	var d := {"out": output.items.duplicate(), "pending": _pending.duplicate()}
	for t in inputs:
		d["in_" + t] = inputs[t].items.duplicate()
	return d


func load_contents(d: Dictionary) -> void:
	for t in inputs:
		Building.fill(inputs[t], d.get("in_" + t, []))
	Building.fill(output, d.get("out", []))
	for t in d.get("pending", []):
		if output.space() > 0:
			output.add(str(t), false)


func status() -> String:
	var a := []
	for t in def["in"]:
		a.append("%d %s" % [int(def["in"][t]), Defs.item_name(t).to_lower()])
	var b := []
	for t in def["out"]:
		b.append("%d %s" % [int(def["out"][t]), Defs.item_name(t).to_lower()])
	return "%s -> %s" % [" + ".join(a), " + ".join(b)]


func info() -> Array:
	var out := [["clock", "One batch every %.1fs" % craft_time()]]
	for t in inputs:
		var h: Holder = inputs[t]
		out.append([Defs.item_icon(t), "In: %d / %d" % [h.count(), h.capacity]])
	out.append(["storage", "Out: %d / %d" % [output.count(), output.capacity]])
	var engs := Game.workers_with("engineer", uid)
	if engs > 0:
		out.append(["engineer", "%d engineer%s: x%.1f speed" % [engs, "s" if engs > 1 else "", Bal.engineer_boost(engs)]])
	if compute_mult() > 1.0:
		out.append(["rack_row", "Datacenter gear nearby: +%d%% speed" % roundi((compute_mult() - 1.0) * 100)])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var now := Bal.craft_time(kind, level)
	var nxt := Bal.craft_time(kind, n)
	return [["Time", "%.2fs" % now, "%.2fs" % nxt],
		["Holds", str(Bal.machine_in_cap(level)), str(Bal.machine_in_cap(n))]]
