class_name TrainerB
extends Building
## The Training Cluster: where your own models come from (see DESIGN.md).
## Pick a model (or leave it on Auto: the next one you can feed); couriers
## bring its training data to the pads out front (datasets, code, labels,
## fine-tunes, reward models, papers, synthetic and expert data...), and
## once it's all there the cluster's accelerators grind through the compute
## (GPU-seconds) while the loss curve on the big screen falls. When it's
## done, the model is yours: servers with enough memory can load it.
## A refresh run (half the data, a third of the compute) makes a model you
## already have better again (quality drives its demand).
## Like a server it burns power cells, and couriers can slot GPUs into its
## racks to train faster.

const PAD := Vector3(-0.6, 0, 1.0)

var cells: Holder
var gpu_in: Holder
var inputs := {}               # item -> Holder
var _gpu_nodes: Array[MeshInstance3D] = []
var _curve: MeshInstance3D
var _label: Label3D
var _badge: Node3D
var _labels := {}
var _pw := 0.0
var _curve_step := -1
var _auto_t := 0.0
var _gpu_shown := -1


func _build() -> void:
	cells = Holder.new().setup(Bal.power_cap(1), ["power"], Holder.Layout.GRID)
	cells.grid = Vector2i(3, 2)
	cells.cell = Vector2(0.36, 0.34)
	cells.max_visible = 12
	cells.position = Vector3(3.2, 1.6, 2.4)
	add_child(cells)
	add_port(cells, null, "in")
	gpu_in = Holder.new().setup(1, ["gpu"], Holder.Layout.NONE)
	gpu_in.position = Vector3(0, 2.4, -1.6)
	add_child(gpu_in)
	gpu_in.landed.connect(_install_gpu)
	add_port(gpu_in, null, "in")
	_label = UI3D.label("", 30, Color(0.7, 0.96, 1.0))
	_label.position = Vector3(0.6, 5.0, -3.4)
	add_child(_label)
	_badge = UI3D.badge("trainer", Pal.STEEL_DARK, 0.6)
	_badge.position = Vector3(-2.8, 4.6, -3.4)
	add_child(_badge)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.9, -3.9, 7.8, 5.6)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("trainer_%d" % t, func(): return InfraArt.trainer(t)), root)
	_gpu_nodes.clear()
	for i in Bal.trainer_gpu_slots(Bal.max_level(kind)):
		var mi := Mats.inst(null, root, MeshKit.at(-2.5 + (i % 6) * 1.0, 0.45 + (i / 6) * 0.42, -1.5))
		_gpu_nodes.append(mi)
	var sp := InfraArt.trainer_screen(t)
	_curve = Mats.inst(null, root, MeshKit.at(sp.x, sp.y, sp.z), false)
	if _label:
		_label.position = Vector3(0.6, InfraArt.trainer_label_y(t), -1.5)
	if _badge:
		_badge.position = Vector3(-2.8, InfraArt.trainer_label_y(t) - 0.4, -1.5)
	_curve.material_override = Mats.glow()
	_gpu_shown = -1
	_curve_step = -1
	_show_gpus()


func _on_level() -> void:
	cells.capacity = Bal.power_cap(level)
	for k in inputs:
		inputs[k].capacity = int(job_needs().get(k, 0))
	_show_gpus()
	if job() == "" and auto():
		_auto_pick()


# ---------------------------------------------------------------- the job

func job() -> String:
	return str(data.get("job", ""))


func refreshing() -> bool:
	return bool(data.get("refresh", false))


func auto() -> bool:
	return bool(data.get("auto", true))


func progress() -> float:
	return float(data.get("progress", 0.0))


## Training data the current job needs: {item: n}.
func job_needs() -> Dictionary:
	return needs_for(job(), refreshing())


static func needs_for(rid: String, refresh: bool) -> Dictionary:
	var r := Defs.recipe(rid)
	if r.is_empty():
		return {}
	var out := {}
	for k in r["train"]:
		out[k] = maxi(1, int(r["train"][k]) / 2) if refresh else int(r["train"][k])
	if out.is_empty():
		out["data"] = 10 if refresh else 20
	return out


static func compute_for(rid: String, refresh: bool) -> float:
	var c := float(Defs.recipe(rid).get("compute", 0))
	if c <= 0.0:
		c = 300.0
	return c / 3.0 if refresh else c


func job_compute() -> float:
	return compute_for(job(), refreshing())


## Starts (or switches to) a job. Data already delivered for the old job
## goes back to a Supply Depot.
func start(rid: String, refresh := false) -> void:
	for k in inputs.keys():
		var h: Holder = inputs[k]
		h.queue_free()
	inputs.clear()
	ports = ports.filter(func(p): return p["holder"] == cells or p["holder"] == gpu_in)
	data["job"] = rid
	data["refresh"] = refresh
	data["progress"] = 0.0
	if rid == "":
		_update()
		return
	var i := 0
	var needs := job_needs()
	for k in needs:
		var h2 := Holder.new().setup(int(needs[k]), [k], Holder.Layout.GRID)
		h2.grid = Vector2i(2, 2)
		h2.cell = Vector2(0.36, 0.34)
		h2.max_visible = 8
		h2.position = PAD + Vector3(-2.2 + i * 0.9, 0.45, 0)
		add_child(h2)
		inputs[k] = h2
		add_port(h2, null, "in")
		h2.changed.connect(_update)
		i += 1
	_update()


func set_auto(on: bool) -> void:
	data["auto"] = on
	if on and job() == "":
		_auto_pick()


## Auto: the next model you don't have whose data the empire makes; or, with
## everything trained, a refresh for the stalest model.
func _auto_pick() -> void:
	for r in Defs.RECIPES:
		var rid: String = r["id"]
		if Game.known_recipes.has(rid) or int(r["open"]) >= 0 or _taken_by_other(rid):
			continue
		var ok := true
		for k in r["train"]:
			if not Game.can_make(k):
				ok = false
				break
		if ok:
			start(rid)
			return
	var stale := ""
	var lq := Bal.Q_MAX
	for rid in Game.known_list():
		if Market.quality_of(rid) < lq and Market.quality_of(rid) < 1.0:
			lq = Market.quality_of(rid)
			stale = rid
	if stale != "":
		start(stale, true)


func _taken_by_other(rid: String) -> bool:
	if world == null:
		return false
	for n in world.buildings_of("trainer"):
		if n != self and (n as TrainerB).job() == rid:
			return true
	return false


func ready_to_train() -> bool:
	for k in inputs:
		if (inputs[k] as Holder).count() < (inputs[k] as Holder).capacity:
			return false
	return job() != ""


# ---------------------------------------------------------------- compute

func gpus() -> int:
	return int(data.get("gpus", 0))


func accels() -> float:
	return Bal.trainer_accel(level) + gpus()


## GPU-seconds per second right now.
func rate() -> float:
	if cells.count() == 0 and _pw <= 0.0:
		return 0.0
	return accels() * compute_mult() * Bal.engineer_boost(Game.workers_with("engineer", uid)) * Game.speed_mult()


func _install_gpu(t: String) -> void:
	gpu_in.take(t)
	if gpus() < Bal.trainer_gpu_slots(level):
		data["gpus"] = gpus() + 1
	Game.track("installs")
	_show_gpus()
	Sfx.play("upgrade", -8.0, 1.2)


func _show_gpus() -> void:
	var slots := Bal.trainer_gpu_slots(level)
	if gpu_in:
		gpu_in.capacity = 1 if gpus() < slots else 0
	if _gpu_shown == gpus() * 100 + slots:
		return
	_gpu_shown = gpus() * 100 + slots
	for i in _gpu_nodes.size():
		var mi := _gpu_nodes[i]
		if i < slots:
			mi.mesh = MeshKit.cached("trainer_gpu_%s" % ("on" if i < gpus() else "off"), func(): return InfraArt.trainer_gpu(i < gpus()))
		else:
			mi.mesh = null


func _process(dt: float) -> void:
	super(dt)
	if job() == "":
		_auto_t -= dt
		if _auto_t <= 0.0:
			_auto_t = 5.0
			if auto():
				_auto_pick()
		return
	if not ready_to_train():
		return
	var r := rate()
	if r > 0.0:
		_pw -= accels() * dt * Bal.POWER_PER_ACCEL
		while _pw <= 0.0 and cells.has("power"):
			cells.take("power")
			_pw += 1.0
		_pw = maxf(0.0, _pw)
		data["progress"] = progress() + r * dt
		if progress() >= job_compute():
			_finish()
		elif int(_t * 2.0) != int((_t - dt) * 2.0):
			_update()


func _finish() -> void:
	var rid := job()
	var refresh := refreshing()
	for k in inputs:
		(inputs[k] as Holder).clear_all()
	if refresh:
		Market.refresh(rid)
		Game.toast.emit("%s refreshed: quality %d%%" % [Defs.model_name(rid), roundi(Market.quality_of(rid) * 100)], "tk_" + rid)
	else:
		Market.quality[rid] = Bal.Q_START
		Game.discover(rid)
	Game.track("trainings")
	if is_inside_tree():
		celebrate()
		UI3D.pop_text(get_tree().current_scene, global_position + Vector3(0, 5.5, 0), ("Refreshed!" if refresh else "Trained!"), Color(0.7, 0.96, 1.0), 90)
	start("")
	if auto():
		_auto_pick()


func _update() -> void:
	if _label == null:
		return
	if job() == "":
		_label.text = "Idle: pick a model"
		return
	var r := Defs.recipe(job())
	if not ready_to_train():
		var got := 0
		var need := 0
		for k in inputs:
			got += (inputs[k] as Holder).count()
			need += (inputs[k] as Holder).capacity
		_label.text = "%s %s: data %d/%d" % ["Refresh" if refreshing() else "Train", r["name"], got, need]
	else:
		_label.text = "%s %s  %d%%" % ["Refreshing" if refreshing() else "Training", r["name"], roundi(progress() / job_compute() * 100)]
	_draw_curve()


## The loss curve on the screen falls as training goes.
func _draw_curve() -> void:
	if _curve == null:
		return
	var f := clampf(progress() / maxf(1.0, job_compute()), 0.0, 1.0)
	var step := int(f * 24)
	if step == _curve_step:
		return
	_curve_step = step
	_curve.mesh = MeshKit.cached("loss_curve_%d" % step, func():
		var k := MeshKit.new()
		for i in step:
			var x0 := float(i) / 24.0
			var y0 := exp(-x0 * 3.2)
			var x1 := float(i + 1) / 24.0
			var y1 := exp(-x1 * 3.2)
			var a := Vector2(-1.8 + x0 * 3.6, -0.6 + y0 * 1.3)
			var b := Vector2(-1.8 + x1 * 3.6, -0.6 + y1 * 1.3)
			var mid := (a + b) * 0.5
			k.rbox(Vector3(a.distance_to(b) + 0.02, 0.04, 0.01), 0.01, Color(0.5, 1.0, 0.7, 0.35), MeshKit.xf(Vector3(mid.x, mid.y, 0.0), Vector3(0, 0, rad_to_deg(atan2(b.y - a.y, b.x - a.x)))))
		return k.commit())


func need(t: String) -> float:
	match t:
		"power":
			return (1.0 - float(cells.count()) / maxf(1.0, cells.capacity)) * 1.0 if cells.can_accept(t) and job() != "" else 0.0
		"gpu":
			return 1.1 if gpu_in.can_accept(t) and gpu_in.incoming == 0 else 0.0
	if inputs.has(t):
		var h: Holder = inputs[t]
		if h.can_accept(t):
			return 0.6 + 0.6 * (1.0 - float(h.count()) / maxf(1.0, h.capacity))
	return 0.0


func save_contents() -> Dictionary:
	var d := {"cells": cells.items.duplicate()}
	for k in inputs:
		d["in_" + k] = inputs[k].items.duplicate()
	return d


func load_contents(d: Dictionary) -> void:
	Building.fill(cells, d.get("cells", []))
	var p := progress()
	start(job(), refreshing())
	data["progress"] = p
	for k in inputs:
		Building.fill(inputs[k], d.get("in_" + k, []))
	_update()


func status() -> String:
	if job() == "":
		return "Idle"
	return "%s %s · %s GPU-s/s" % ["Refreshing" if refreshing() else "Training", Defs.model_name(job()), Fmt.num(rate())]


func info() -> Array:
	var out := []
	if job() != "":
		out.append(["tk_" + job(), "%s %s: %d%% of %s GPU-seconds" % ["Refresh" if refreshing() else "Train", Defs.model_name(job()), roundi(progress() / job_compute() * 100), Fmt.num(job_compute())]])
		for k in inputs:
			var h: Holder = inputs[k]
			out.append([k, "%s %d / %d" % [Defs.item_name(k), h.count(), h.capacity]])
		var left := (job_compute() - progress()) / maxf(0.01, rate())
		out.append(["clock", "About %s once the data is in" % Fmt.time(left) if not ready_to_train() else "About %s to go" % Fmt.time(left)])
	out.append(["gpu", "Accelerators x%.1f  ·  GPUs %d / %d" % [accels(), gpus(), Bal.trainer_gpu_slots(level)]])
	out.append(["power", "Power %d / %d" % [cells.count(), cells.capacity]])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var out := [["Accelerators", "x%.1f" % Bal.trainer_accel(level), "x%.1f" % Bal.trainer_accel(n)]]
	if Bal.trainer_gpu_slots(n) > Bal.trainer_gpu_slots(level):
		out.append(["GPU slots", str(Bal.trainer_gpu_slots(level)), str(Bal.trainer_gpu_slots(n))])
	return out
