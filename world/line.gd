class_name Line
extends Node3D
## A working production line: Mixer -> tubes / hoppers -> Oven, all with the
## same rotation, end to end. The line bakes the most valuable recipe whose
## ingredients are all among its hoppers. The Mixer turns wheat into dough
## balls; each ball rolls down the tube, stops under every hopper its recipe
## needs for a dose (growing and changing colour), then goes into the oven.

var world: World
var modules: Array[LineModule] = []
var mixer: MixerB
var oven: OvenB
var hoppers: Array[HopperB] = []
var product := "shortbread"
var recipe_ings: Array = []
var stations: Array[Dictionary] = []    # [{s, hopper}] in flow order
var doughs: Array[Dictionary] = []      # {s, need, st, node, mat, wait, got}
var start := Vector3.ZERO
var dir := Vector3.RIGHT
var length := 1.0
var _spawn_cd := 0.0

const TONES := {
	"sugar": Color(0.97, 0.9, 0.76), "cocoa": Color(0.7, 0.52, 0.4), "egg": Color(0.97, 0.86, 0.62),
	"milk": Color(0.98, 0.93, 0.8), "butter": Color(0.98, 0.88, 0.6), "chocolate": Color(0.62, 0.44, 0.32),
	"oats": Color(0.88, 0.78, 0.6), "jam": Color(0.9, 0.7, 0.62), "hazelnut": Color(0.8, 0.64, 0.46),
	"honey": Color(0.96, 0.8, 0.5), "caramel": Color(0.9, 0.7, 0.45), "vanilla": Color(0.98, 0.93, 0.8),
	"praline": Color(0.74, 0.56, 0.4), "cinnamon": Color(0.86, 0.66, 0.46), "candied": Color(0.96, 0.78, 0.5),
}


func setup(p_world: World, mods: Array[LineModule]) -> void:
	world = p_world
	modules = mods
	mixer = mods[0]
	oven = mods[mods.size() - 1]
	dir = mixer.flow_dir()
	start = mixer.to_world(0, LineModule.TUBE_Z, LineModule.TUBE_Y - 0.36)
	var inlet := oven.to_world(-1.2, LineModule.TUBE_Z, LineModule.TUBE_Y - 0.36)
	length = (inlet - start).dot(dir)
	var have := {}
	for m in mods:
		m.line = self
		if m is HopperB:
			hoppers.append(m)
			have[(m as HopperB).ing] = true
			stations.append({"s": (m.base_xf().origin - start).dot(dir), "hopper": m})
	product = best_recipe(have)
	recipe_ings = Defs.recipe(product)["ings"]


## The most valuable recipe whose ingredients are all available.
static func best_recipe(have: Dictionary) -> String:
	var best := "shortbread"
	var best_p := 0.0
	for r in Defs.RECIPES:
		var ok := true
		for i in r["ings"]:
			if not have.has(i):
				ok = false
				break
		if ok and float(r["price"]) > best_p:
			best_p = float(r["price"])
			best = r["id"]
	return best


func uses(ing: String) -> bool:
	return recipe_ings.has(ing)


func _ready() -> void:
	for m in modules:
		m.set_links(m.linked_prev, m.linked_next)


func _exit_tree() -> void:
	for d in doughs:
		if is_instance_valid(d["node"]):
			d["node"].queue_free()
	for h in hoppers:
		if is_instance_valid(h):
			h.waiting = false


# ---------------------------------------------------------------- simulation

func _process(dt: float) -> void:
	if not is_instance_valid(mixer) or not is_instance_valid(oven):
		return
	var mult := Game.speed_mult()
	var spd := Bal.belt_speed(mixer.level) * mult
	var gap := Bal.DOUGH_GAP
	_spawn_cd -= dt * mult
	var room: bool = doughs.is_empty() or doughs[doughs.size() - 1]["s"] > gap + 0.4
	if room and _spawn_cd <= 0.0 and doughs.size() < 12 and mixer.wheat.count() > 0:
		_spawn_cd = Bal.mixer_interval(mixer.level)
		mixer.wheat.take("wheat")
		mixer.mixed()
		_spawn_dough()
	for h in hoppers:
		h.waiting = false
	for i in doughs.size():
		var d: Dictionary = doughs[i]
		var st := _next_station(d)
		var target: float = st["s"] if not st.is_empty() else INF
		var stop := minf(target, length)
		if i > 0:
			stop = minf(stop, doughs[i - 1]["s"] - gap)
		if d["wait"] > 0.0:
			d["wait"] -= dt * mult
			if d["wait"] <= 0.0:
				_dose_land(d)
		elif not st.is_empty() and d["s"] >= target - 0.02:
			d["s"] = target
			_try_dose(d, st)
		elif d["s"] < stop:
			d["s"] = minf(stop, d["s"] + spd * dt)
		var n: Node3D = d["node"]
		n.global_position = start + dir * d["s"]
		n.rotation.z = -d["s"] / 0.22
	while not doughs.is_empty() and (doughs[0]["need"] as Array).is_empty() and doughs[0]["wait"] <= 0.0 and doughs[0]["s"] >= length - 0.01 and oven.queue < 2:
		var d0: Dictionary = doughs.pop_front()
		var node: Node3D = d0["node"]
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
		tw.tween_callback(node.queue_free)
		oven.receive()


## The next hopper this ball must stop at ({} when it can go to the oven).
func _next_station(d: Dictionary) -> Dictionary:
	var need: Array = d["need"]
	if need.is_empty():
		return {}
	for k in stations.size():
		var st: Dictionary = stations[k]
		if st["s"] < d["s"] - 0.03:
			continue
		var h: HopperB = st["hopper"]
		if not need.has(h.ing):
			continue
		if h.store.count() > 0:
			return st
		# empty: skip it if a later hopper of the same ingredient has some
		var later := false
		for j in range(k + 1, stations.size()):
			var h2: HopperB = stations[j]["hopper"]
			if h2.ing == h.ing and h2.store.count() > 0:
				later = true
				break
		if not later:
			return st
	return {}


func _spawn_dough() -> void:
	var n := Node3D.new()
	add_child(n)
	n.global_position = start
	var mi := Mats.inst(MeshKit.cached("dough_ball", func():
		var k := MeshKit.new()
		k.sphere(0.24, Color(1, 1, 1), MeshKit.at(0, 0.24, 0), 14, 10)
		return k.commit()), n, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", Color(0.94, 0.88, 0.74))
	mi.material_override = m
	n.scale = Vector3(0.6, 0.6, 0.6)
	doughs.append({"s": 0.0, "need": recipe_ings.duplicate(), "node": n, "wait": 0.0, "mat": m, "got": 0, "dosing": ""})


func _try_dose(d: Dictionary, st: Dictionary) -> void:
	var h: HopperB = st["hopper"]
	if h.store.count() <= 0:
		h.waiting = true
		return
	h.store.take(h.ing)
	h.dose()
	d["wait"] = 0.35
	d["dosing"] = h.ing
	var drop := Items.node(h.ing)
	add_child(drop)
	var top := start + dir * float(st["s"])
	drop.global_position = top + Vector3(0, 0.75, 0)
	drop.scale = Vector3(0.5, 0.5, 0.5)
	var tw2 := drop.create_tween()
	tw2.tween_property(drop, "global_position:y", top.y + 0.2, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(drop, "scale", Vector3(0.25, 0.25, 0.25), 0.3)
	tw2.tween_callback(drop.queue_free)
	Sfx.play("dispense", -10.0)


func _dose_land(d: Dictionary) -> void:
	var ing: String = d["dosing"]
	(d["need"] as Array).erase(ing)
	d["got"] = int(d["got"]) + 1
	var n: Node3D = d["node"]
	(d["mat"] as ShaderMaterial).set_shader_parameter("tint", TONES.get(ing, Color(0.95, 0.88, 0.72)))
	var s := 0.6 + int(d["got"]) * 0.07
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
	Sfx.play("plop", -12.0, 1.0 + int(d["got"]) * 0.08)


## Cookies per minute this line can make at most (for the info panel).
func max_rate() -> float:
	var per_ball := float(oven.batch())
	var mixer_rate := 60.0 / Bal.mixer_interval(mixer.level)
	var oven_rate := 60.0 / Bal.bake_time(oven.level) * oven.staff_mult()
	return minf(mixer_rate, oven_rate) * per_ball
