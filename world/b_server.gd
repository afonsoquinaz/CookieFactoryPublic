class_name ServerB
extends Building
## The Inference Server (see DESIGN.md). It loads one model and answers API
## calls with it: request packets come in at the Router, run down the glass
## bus past the GPU trays and into the core, and the tokens stream back out
## to the network. How much it serves is up to the Market (customers) and
## its capacity:
##   accelerators  the garage card it comes with, plus up to 20 GPUs that
##                 couriers slot into the trays over the bus (more trays as
##                 it levels)
##   memory        a model needs VRAM: 12 GB on the card, 80 GB per GPU,
##                 40 GB per HBM stack (the shelf by the core)
##   power         every accelerator burns power cells while it serves;
##                 no power, no tokens
##   coolant       real GPUs run hot: without coolant they throttle to 60%
##   tune          engineers walk the trays and tap them (so can you): up
##                 to +50%, fading over time
## GPUs wear out under load: a dead board goes dark until a courier brings
## a new one. You choose the model, or leave it on Auto (the one that earns
## most with the demand that's left).

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
const PER_TRAY := 3

var cells: Holder              # power cells (dock)
var coolant: Holder            # coolant (bench)
var gpu_in: Holder             # GPUs on their way into a tray
var hbm_in: Holder             # HBM on its way onto the shelf
var recipe := "pico"
var load_now := 0.0            # share of capacity in use (Market)
var last_cap := 0.0            # K tokens/s it could serve last tick
var tune := 0.0                # 0..1
var throttled := false
var offline := false
var packets: Array[Dictionary] = []   # {s, node}
var _spawn_cd := 0.0
var _glow: OmniLight3D
var _fan: Node3D
var _spin := 0.0
var _bay_root: Node3D
var _hbm_node: MeshInstance3D
var _make_label: Label3D
var _make_icon: Sprite3D
var _rate_label: Label3D
var _tune_label: Label3D
var _vent := Vector3.ZERO
var _recheck := 0.0
var _want: Node3D
var _want_icon := ""
var _pw := 0.0                 # energy left from the last power cell
var _cl := 0.0                 # cooling left from the last coolant
var _wear := 0.0
var _earn := 0.0
var _earn_t := 0.0
var _stream_t := 0.0
var _shown := ""


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
	coolant = Holder.new().setup(10, ["coolant"], Holder.Layout.GRID)
	coolant.grid = Vector2i(3, 2)
	coolant.cell = Vector2(0.4, 0.38)
	coolant.max_visible = 12
	coolant.position = Vector3(0, 0.78, 0)
	tr.add_child(coolant)
	add_port(coolant, null, "in")
	gpu_in = Holder.new().setup(1, ["gpu"], Holder.Layout.NONE)
	gpu_in.position = Vector3(-0.7, ServerArt.Y + 1.2, BUS_Z)
	add_child(gpu_in)
	gpu_in.landed.connect(_install_gpu)
	add_port(gpu_in, null, "in")
	hbm_in = Holder.new().setup(1, ["hbm"], Holder.Layout.NONE)
	hbm_in.position = Vector3(CORE_X, 3.0, BUS_Z)
	add_child(hbm_in)
	hbm_in.landed.connect(_install_hbm)
	add_port(hbm_in, null, "in")
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
	_rate_label = UI3D.label("", 26, Color(0.7, 0.96, 1.0))
	_rate_label.position = Vector3(CORE_X - 0.3, 3.85, BUS_Z + 0.2)
	add_child(_rate_label)
	_tune_label = UI3D.label("", 24, Color(1.0, 0.86, 0.5))
	_tune_label.position = Vector3(-0.7, ServerArt.Y + 2.5, BUS_Z)
	add_child(_tune_label)
	var wb := UI3D.badge("power", Pal.STEEL_DARK, 0.55)
	wb.position = DOCK_POS + Vector3(0, 1.6, 0)
	add_child(wb)
	var cb := UI3D.badge("coolant", Pal.STEEL_DARK, 0.5)
	cb.position = BENCH_POS + Vector3(0, 1.6, 0)
	add_child(cb)
	cells.changed.connect(_update_labels)
	coolant.changed.connect(_update_labels)


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
	Mats.inst(MeshKit.cached("router_%d" % t, func(): return ServerArt.router(t)), root, MeshKit.at(ROUTER_X, 0, BUS_Z - ServerArt.TZ))
	_fan = Node3D.new()
	_fan.position = Vector3(ROUTER_X + (0.35 if t == 0 else 0.0), ServerArt.fan_y(t), BUS_Z + (0.0 if t != 0 else -0.1))
	root.add_child(_fan)
	Mats.inst(MeshKit.cached("router_fan", ServerArt.fan), _fan, Transform3D.IDENTITY, false)
	Mats.inst(MeshKit.cached("power_dock_%d" % t, func(): return ServerArt.power_dock(t)), root, MeshKit.at(DOCK_POS.x, 0, DOCK_POS.z))
	Mats.inst(MeshKit.cached("core_%d" % t, func(): return ServerArt.core(t)), root, MeshKit.at(CORE_X, 0, BUS_Z - ServerArt.TZ))
	Mats.inst(MeshKit.cached("bench_%d" % t, func(): return ServerArt.bench(t)), root, MeshKit.at(BENCH_POS.x, 0, BENCH_POS.z))
	_hbm_node = Mats.inst(null, root, MeshKit.at(BENCH_POS.x, 0.8, BENCH_POS.z - 0.25))
	var vt := ServerArt.vent_top(t)
	_vent = Vector3(CORE_X + vt.x, vt.y, BUS_Z - ServerArt.TZ + vt.z)
	_shown = ""
	_build_bays()


func _on_level() -> void:
	cells.capacity = Bal.power_cap(level)
	coolant.capacity = Bal.coolant_cap(level)
	_build_bays()
	_pick_recipe(true)


# ---------------------------------------------------------------- hardware

func gpus() -> int:
	return int(data.get("gpus", 0))


func dead() -> int:
	return int(data.get("dead", 0))


func hbm() -> int:
	return int(data.get("hbm", 0))


func gpu_slots() -> int:
	return Bal.gpu_slots(level)


func hbm_slots() -> int:
	return Bal.hbm_slots(level)


## Working accelerators (the garage card plus live GPUs).
func accels() -> float:
	return Bal.garage_accel(level) + gpus()


func vram() -> float:
	return Bal.GARAGE_VRAM + gpus() * Bal.GPU_VRAM + hbm() * Bal.HBM_VRAM


func _install_gpu(t: String) -> void:
	gpu_in.take(t)
	if dead() > 0:
		data["dead"] = dead() - 1
	if gpus() + dead() < gpu_slots():
		data["gpus"] = gpus() + 1
	Game.track("installs")
	_build_bays()
	_pick_recipe(true)
	if is_inside_tree():
		Fx.burst(get_tree().current_scene, to_world(_tray_x(gpus() - 1), BUS_Z, ServerArt.Y + 1.2), Color(0.5, 1.0, 0.6), 10, false)
		UI3D.pop_text(get_tree().current_scene, to_world(_tray_x(gpus() - 1), BUS_Z, ServerArt.Y + 2.4), "GPU installed!", Color(0.6, 1.0, 0.7), 46)
	Sfx.play("upgrade", -8.0, 1.2)
	bump(0.04)


func _install_hbm(t: String) -> void:
	hbm_in.take(t)
	if hbm() < hbm_slots():
		data["hbm"] = hbm() + 1
	Game.track("installs")
	_build_bays()
	_pick_recipe(true)
	if is_inside_tree():
		UI3D.pop_text(get_tree().current_scene, to_world(BENCH_POS.x, BENCH_POS.z, 2.2), "+40 GB HBM", Color(0.6, 0.86, 1.0), 44)
	Sfx.play("upgrade", -8.0, 1.3)


## x of tray holding GPU i.
func _tray_x(i: int) -> float:
	var n := trays()
	var mid := (BUS_X0 + BUS_X1) * 0.5 + 0.2
	var tray := clampi(i / PER_TRAY, 0, n - 1)
	return mid + (tray - (n - 1) * 0.5) * BAY_GAP


func trays() -> int:
	return clampi(int(ceil(gpu_slots() / float(PER_TRAY))), 1, 7)


## GPU trays over the bus (installed boards light up) and the HBM shelf.
func _build_bays() -> void:
	if _bay_root == null:
		return
	var sig := "%d_%d_%d_%d_%d" % [gpus(), dead(), hbm(), level, tier]
	if sig == _shown:
		return
	_shown = sig
	for c in _bay_root.get_children():
		c.queue_free()
	var n := trays()
	var left := gpus()
	var broken := dead()
	var slots := gpu_slots()
	var mid := (BUS_X0 + BUS_X1) * 0.5 + 0.2
	for i in n:
		var cap_here := mini(PER_TRAY, slots - i * PER_TRAY)
		var live := mini(left, cap_here)
		left -= live
		var dd := mini(broken, cap_here - live)
		broken -= dd
		var node := Node3D.new()
		node.position = Vector3(mid + (i - (n - 1) * 0.5) * BAY_GAP, ServerArt.Y + 0.47, BUS_Z)
		_bay_root.add_child(node)
		var mesh := MeshKit.cached("gpu_tray_%d_%d_%d" % [live + dd, dd, tier], func(): return ServerArt.gpu_tray(live + dd, dd, tier))
		Mats.inst(mesh, node, MeshKit.xf(Vector3.ZERO, Vector3.ZERO, Vector3(0.62, 0.62, 0.62)))
	if _hbm_node:
		var hs := hbm_slots()
		_hbm_node.mesh = MeshKit.cached("hbm_shelf_%d_%d_%d" % [hbm(), hs, tier], func(): return ServerArt.hbm_shelf(hbm(), hs, tier)) if hs > 0 else null
	gpu_in.capacity = 1 if gpus() + dead() < slots or dead() > 0 else 0
	hbm_in.capacity = 1 if hbm() < hbm_slots() else 0


# ---------------------------------------------------------------- model

## Models this server can load (enough VRAM).
func choices() -> Array[String]:
	var out: Array[String] = []
	for rid in Game.known_list():
		if float(Defs.recipe(rid)["vram"]) <= vram():
			out.append(rid)
	return out


func chosen() -> String:
	return str(data.get("recipe", ""))


## Sets the model ("" = Auto).
func choose(id: String) -> void:
	data["recipe"] = id
	_pick_recipe(true)
	Game.save_game()


## K tokens/s it would serve of a model at full load.
func capacity_for(rid: String) -> float:
	var r := Defs.recipe(rid)
	if r.is_empty() or float(r["vram"]) > vram():
		return 0.0
	var c := accels() * float(r["tps"]) * Bal.server_eff(level) * (1.0 + Bal.TUNE_BONUS * tune) * compute_mult() * Game.speed_mult()
	if throttled and gpus() > 0:
		c *= Bal.THROTTLE
	return c


## Auto: the model that earns most with the demand still unserved.
func auto_recipe() -> String:
	var best := "pico"
	var best_v := -1.0
	for rid in choices():
		var c := capacity_for(rid)
		var v := minf(c, Market.headroom(rid, self)) * Market.token_price(rid)
		if rid == recipe:
			v *= 1.15     # don't flip-flop
		if v > best_v:
			best_v = v
			best = rid
	return best


func _pick_recipe(force := false) -> void:
	var want := chosen()
	if want == "" or not choices().has(want):
		want = auto_recipe()
	if want != recipe or force:
		recipe = want
	_update_labels()


## What the Market can count on this tick (K/s); 0 when it's offline.
func capacity() -> float:
	offline = cells.count() == 0 and _pw <= 0.0
	last_cap = 0.0 if offline else capacity_for(recipe)
	return last_cap


func set_load(u: float) -> void:
	load_now = clampf(u, 0.0, 1.0)


## Money it just made (for the "+$" pop now and then).
func earned(m: float) -> void:
	_earn += m


## A tap on the server: an engineer's (small) or yours (bigger).
func tap(amount: float, at := Vector3.INF) -> void:
	tune = minf(1.0, tune + amount * Bal.tune_mult())
	Game.track("tunes")
	if not is_inside_tree():
		return
	var p := at if at != Vector3.INF else to_world(_tray_x(randi() % maxi(1, gpu_slots())), BUS_Z, ServerArt.Y + 1.0)
	Fx.burst(get_tree().current_scene, p, Color(1.0, 0.86, 0.4), 6, false)
	_spin = 1.0
	bump(0.015)


## Where engineers stand to tap a tray (world).
func tune_spot(i: int) -> Vector3:
	return to_world(_tray_x((i * PER_TRAY) % maxi(1, gpu_slots())), BUS_Z + 0.95)


# ---------------------------------------------------------------- simulation

func _process(dt: float) -> void:
	super(dt)
	_recheck -= dt
	if _recheck <= 0.0:
		_recheck = 3.0
		_pick_recipe()
	# power and coolant drain with load; GPUs wear
	var work := load_now * dt
	_pw -= accels() * work * Bal.POWER_PER_ACCEL
	while _pw <= 0.0 and cells.has("power"):
		cells.take("power")
		_pw += 1.0
	if _pw < 0.0:
		_pw = 0.0
	if gpus() > 0:
		_cl -= gpus() * work * Bal.COOLANT_PER_GPU
		while _cl <= 0.0 and coolant.has("coolant"):
			coolant.take("coolant")
			_cl += 1.0
		throttled = _cl <= 0.0
		if _cl < 0.0:
			_cl = 0.0
		_wear += gpus() * work * Bal.GPU_FAIL
		if _wear >= 1.0:
			_wear -= 1.0
			_gpu_fails()
	else:
		throttled = false
	tune = maxf(0.0, tune - Bal.TUNE_DECAY * dt)
	# the router fan and the request packets: as busy as the server
	var busy := load_now * last_cap
	_spin = maxf(0.0, _spin - dt * 0.8)
	if _fan:
		_fan.rotation.y += dt * (2.0 + load_now * 12.0 + _spin * 10.0)
	_spawn_cd -= dt
	if busy > 0.0 and _spawn_cd <= 0.0 and packets.size() < 12:
		_spawn_cd = clampf(1.2 / (0.4 + busy * 2.0), 0.18, 2.5)
		_spawn_packet()
	var spd := 2.2 + load_now * 2.0
	var len := BUS_X1 - BUS_X0
	for d in packets:
		d["s"] = minf(len, float(d["s"]) + spd * dt)
		var n: Node3D = d["node"]
		n.position = Vector3(BUS_X0 + d["s"], ServerArt.Y - 0.36 + sin(_t * 6.0 + float(d["s"]) * 3.0) * 0.03, BUS_Z)
	while not packets.is_empty() and float(packets[0]["s"]) >= len - 0.01:
		var d0: Dictionary = packets.pop_front()
		var node: Node3D = d0["node"]
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(0.15, 0.15, 0.15), 0.18)
		tw.tween_callback(node.queue_free)
	_glow.light_energy = lerpf(_glow.light_energy, (0.4 + load_now * 0.9 + sin(_t * 9.0) * 0.1) if busy > 0.0 else 0.15, clampf(dt * 3.0, 0.0, 1.0))
	# tokens streaming back out to the network
	_stream_t -= dt
	if busy > 0.0 and _stream_t <= 0.0 and is_inside_tree():
		_stream_t = clampf(0.9 / (0.3 + busy), 0.12, 1.6)
		_stream()
	_earn_t -= dt
	if _earn_t <= 0.0:
		_earn_t = 3.0
		if _earn >= 1.0 and is_inside_tree():
			UI3D.pop_text(get_tree().current_scene, to_world(CORE_X - 0.3, BUS_Z, 5.6), "+$%s" % Fmt.num(_earn), Color(1.0, 0.88, 0.3), 54)
		_earn = 0.0
	if int(_t * 2.0) != int((_t - dt) * 2.0):
		_update_labels()
	_show_want(_blocker_icon())


func _gpu_fails() -> void:
	if gpus() <= 0:
		return
	data["gpus"] = gpus() - 1
	data["dead"] = dead() + 1
	Game.track("gpu_failures")
	_build_bays()
	_pick_recipe(true)
	if is_inside_tree():
		var p := to_world(_tray_x(gpus()), BUS_Z, ServerArt.Y + 1.0)
		Fx.puff(get_tree().current_scene, p, Color(0.35, 0.35, 0.38), 8)
		UI3D.pop_text(get_tree().current_scene, p + Vector3(0, 1.2, 0), "GPU failed!", Color(1.0, 0.6, 0.5), 44)
	Sfx.play("deny", -10.0, 0.8)


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
	m.set_shader_parameter("tint", Defs.MODEL_LOOK.get(recipe, {"base": Color(0.7, 0.86, 1.0)})["base"].lightened(0.25))
	mi.material_override = m
	n.scale = Vector3(0.5, 0.5, 0.5)
	packets.append({"s": 0.0, "node": n})


## A little token rises from the core's vent and fades: tokens going back out.
func _stream() -> void:
	var c := Items.node("t:" + recipe)
	get_tree().current_scene.add_child(c)
	var p := to_world(_vent.x, _vent.z, _vent.y)
	c.global_position = p
	c.scale = Vector3(0.5, 0.5, 0.5)
	var tw := c.create_tween()
	tw.set_parallel(true)
	tw.tween_property(c, "global_position", p + Vector3(randf_range(-0.6, 0.6), 2.6, randf_range(-0.6, 0.6)), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "scale", Vector3(0.15, 0.15, 0.15), 1.1)
	tw.chain().tween_callback(c.queue_free)


## What's holding it back, for the bubble ("" = nothing).
func _blocker_icon() -> String:
	if offline:
		return "power"
	if throttled and gpus() > 0:
		return "coolant"
	if dead() > 0:
		return "gpu"
	return ""


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


func _update_labels() -> void:
	if _make_label == null:
		return
	var r := Defs.recipe(recipe)
	_make_label.text = "%s  $%s/1K" % [r["name"], Fmt.num(Market.token_price(recipe))]
	_make_icon.texture = Icons.tex("tk_" + recipe)
	if offline:
		_rate_label.text = "OFFLINE: no power"
		_rate_label.modulate = Color(1.0, 0.6, 0.5)
	else:
		_rate_label.text = "%s tok/s  ·  %d%% busy%s" % [Fmt.tokens(last_cap * load_now), roundi(load_now * 100), "  ·  HOT" if throttled and gpus() > 0 else ""]
		_rate_label.modulate = Color(1.0, 0.75, 0.5) if throttled and gpus() > 0 else Color(0.7, 0.96, 1.0)
	_tune_label.text = ("Tuned +%d%%" % roundi(Bal.TUNE_BONUS * tune * 100)) if tune > 0.02 else ""


## Power and coolant: more the emptier; a free GPU or HBM slot: urgent.
func need(t: String) -> float:
	match t:
		"power":
			return (1.0 - float(cells.count()) / maxf(1.0, cells.capacity)) * 1.2 if cells.can_accept(t) else 0.0
		"coolant":
			if gpus() + dead() == 0 or not coolant.can_accept(t):
				return 0.0
			return (1.0 - float(coolant.count()) / maxf(1.0, coolant.capacity)) * 1.0
		"gpu":
			return 1.5 if gpu_in.can_accept(t) and gpu_in.incoming == 0 else 0.0
		"hbm":
			return 1.3 if hbm_in.can_accept(t) and hbm_in.incoming == 0 else 0.0
	return 0.0


## Models it can't load yet for want of memory, for hints.
func missing() -> Array[String]:
	var out: Array[String] = []
	if chosen() != "" and not choices().has(chosen()):
		out.append("gpu")
	return out


func save_contents() -> Dictionary:
	return {"cells": cells.items.duplicate(), "coolant": coolant.items.duplicate(), "tune": tune}


func load_contents(d: Dictionary) -> void:
	Building.fill(cells, d.get("cells", []))
	Building.fill(coolant, d.get("coolant", []))
	tune = float(d.get("tune", 0.0))


func status() -> String:
	if offline:
		return "Offline: it needs power cells"
	var r := Defs.recipe(recipe)
	return "Serves %s · %s tok/s max%s" % [r["name"], Fmt.tokens(capacity_for(recipe)), "  (Auto)" if chosen() == "" else ""]


func info() -> Array:
	var out := [
		["tk_" + recipe, "%s: up to %s tokens/s, %d%% busy" % [Defs.recipe(recipe)["name"], Fmt.tokens(capacity_for(recipe)), roundi(load_now * 100)]],
		["gpu", "GPUs %d / %d%s  ·  garage card x%.2f" % [gpus(), gpu_slots(), ("  (%d dead)" % dead()) if dead() > 0 else "", Bal.garage_accel(level)]],
		["hbm", "VRAM %d GB  ·  HBM %d / %d" % [int(vram()), hbm(), hbm_slots()]],
		["power", "Power %d / %d  ·  %.1f cells/min at full load" % [cells.count(), cells.capacity, accels() * Bal.POWER_PER_ACCEL * 60.0]],
	]
	if gpus() + dead() > 0:
		out.append(["coolant", "Coolant %d / %d%s" % [coolant.count(), coolant.capacity, "  ·  throttling!" if throttled else ""]])
	out.append(["engineer", "Tuned +%d%%  ·  %d engineer%s tapping" % [roundi(Bal.TUNE_BONUS * tune * 100), Game.workers_with("engineer", uid), "" if Game.workers_with("engineer", uid) == 1 else "s"]])
	if compute_mult() > 1.0:
		out.append(["rack_row", "Datacenter gear nearby: +%d%% speed" % roundi((compute_mult() - 1.0) * 100)])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var out := []
	if Bal.gpu_slots(n) > gpu_slots():
		out.append(["GPU slots", str(gpu_slots()), str(Bal.gpu_slots(n))])
	if Bal.hbm_slots(n) > hbm_slots():
		out.append(["HBM slots", str(hbm_slots()), str(Bal.hbm_slots(n))])
	out.append(["Efficiency", "x%.2f" % Bal.server_eff(level), "x%.2f" % Bal.server_eff(n)])
	if Bal.garage_accel(n) > Bal.garage_accel(level) + 0.001:
		out.append(["Garage card", "x%.2f" % Bal.garage_accel(level), "x%.2f" % Bal.garage_accel(n)])
	out.append(["Power store", str(Bal.power_cap(level)), str(Bal.power_cap(n))])
	return out
