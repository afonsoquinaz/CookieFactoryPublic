class_name LaunchB
extends Building
## The Launch Complex: your datacenter goes to space. Couriers bring an
## orbital module's parts to the assembly bays (24 GPUs, 8 HBM stacks, 60
## power cells); once they're all in, the rocket rolls out, counts down and
## launches. In orbit each module adds 48 accelerators' worth of serving
## for the best model that fits (free solar power and radiative cooling: no
## power cells, no coolant, no wear), 80 ms further away, and only as much
## as your Ground Stations can downlink. The pad needs a while to turn
## around between launches (less with each level).

enum S { ASSEMBLING, COUNTDOWN, FLIGHT, TURNAROUND }

const PARTS := {"gpu": 24, "hbm": 8, "power": 60}
const PAD := Vector3(0.8, 0.52, -1.4)

var bays := {}                 # item -> Holder
var state := S.ASSEMBLING
var _timer := 0.0
var _rocket: Node3D
var _flame: Node3D
var _label: Label3D
var _smoke_t := 0.0


func _build() -> void:
	var i := 0
	for k in PARTS:
		var h := Holder.new().setup(int(PARTS[k]), [k], Holder.Layout.GRID)
		h.grid = Vector2i(2, 2)
		h.cell = Vector2(0.4, 0.36)
		h.max_visible = 8
		h.position = Vector3(-2.6 + i * 1.3, 0.9, 2.6)
		add_child(h)
		bays[k] = h
		add_port(h, null, "in")
		h.changed.connect(_update)
		i += 1
	_label = UI3D.label("", 30, Color(0.7, 0.96, 1.0))
	_label.position = Vector3(0.8, 9.6, -1.4)
	add_child(_label)
	state = S.TURNAROUND if float(data.get("turn", 0.0)) > Game.clock else S.ASSEMBLING


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.9, -3.9, 7.8, 5.8)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("launchpad_%d" % t, func(): return InfraArt.launchpad(t)), root)


func _on_level() -> void:
	_update()


static func turnaround(l: int) -> float:
	return 900.0 * pow(0.93, l - 1)


func complete() -> bool:
	for k in bays:
		if (bays[k] as Holder).count() < (bays[k] as Holder).capacity:
			return false
	return true


func need(t: String) -> float:
	if state != S.ASSEMBLING or not bays.has(t):
		return 0.0
	var h: Holder = bays[t]
	if not h.can_accept(t):
		return 0.0
	return 0.7 + 0.5 * (1.0 - float(h.count()) / maxf(1.0, h.capacity))


func _process(dt: float) -> void:
	super(dt)
	match state:
		S.ASSEMBLING:
			if complete():
				_roll_out()
		S.COUNTDOWN:
			_timer -= dt
			_label.text = "Launch in %d" % ceili(_timer)
			if _timer <= 0.0:
				_lift_off()
		S.FLIGHT:
			_timer += dt
			var h := 0.6 * _timer * _timer * 4.0
			_rocket.position = PAD + Vector3(_timer * _timer * 0.3, h, 0)
			_rocket.rotation.z = -minf(0.5, _timer * 0.06)
			_flame.scale = Vector3.ONE * (1.0 + sin(_t * 30.0) * 0.15)
			_smoke_t -= dt
			if _smoke_t <= 0.0 and is_inside_tree():
				_smoke_t = 0.08
				Fx.puff(get_tree().current_scene, _rocket.global_position - Vector3(0, 0.6, 0), Color(0.92, 0.92, 0.9), 2)
			if _timer > 7.0:
				_arrive()
		S.TURNAROUND:
			var left := float(data.get("turn", 0.0)) - Game.clock
			_label.text = "Pad ready in %s" % Fmt.time(left)
			if left <= 0.0:
				state = S.ASSEMBLING
				_update()


func _roll_out() -> void:
	state = S.COUNTDOWN
	_timer = 10.0
	_rocket = Node3D.new()
	_rocket.position = PAD
	add_child(_rocket)
	Mats.inst(MeshKit.cached("rocket", InfraArt.rocket), _rocket)
	_flame = Node3D.new()
	_flame.position = Vector3(0, -0.4, 0)
	_flame.visible = false
	_rocket.add_child(_flame)
	var fm := Mats.inst(MeshKit.cached("rocket_flame", InfraArt.flame), _flame, Transform3D.IDENTITY, false)
	fm.material_override = Mats.glow()
	_rocket.scale = Vector3(1, 0.05, 1)
	var tw := _rocket.create_tween()
	tw.tween_property(_rocket, "scale", Vector3.ONE, 0.8).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for k in bays:
		(bays[k] as Holder).clear_all()
	Sfx.play("upgrade", -2.0, 0.8)


func _lift_off() -> void:
	state = S.FLIGHT
	_timer = 0.0
	_flame.visible = true
	_label.text = "Liftoff!"
	if is_inside_tree():
		Fx.burst(get_tree().current_scene, global_position + Vector3(PAD.x, 0.8, PAD.z), Color(1.0, 0.7, 0.3), 30, false)
		if world and world.cam:
			world.cam.shake = 0.6
	Sfx.play("levelup", -2.0, 0.7)


func _arrive() -> void:
	_rocket.queue_free()
	_rocket = null
	Market.orbit_modules += 1
	if Market.orbit_model == "" or float(Defs.recipe(Market.best_orbit_model()).get("price", 0.0)) > float(Defs.recipe(Market.orbit_model).get("price", 0.0)):
		Market.orbit_model = Market.best_orbit_model()
	Game.track("launches")
	Game.toast.emit("Module %d reached orbit! %s more tokens/s from space" % [Market.orbit_modules, Fmt.tokens(Bal.ORBIT_ACCELS * float(Defs.recipe(Market.orbit_model).get("tps", 0.0)))], "launchpad")
	data["turn"] = Game.clock + turnaround(level)
	state = S.TURNAROUND
	Game.save_game()


func _update() -> void:
	if _label == null or state != S.ASSEMBLING:
		return
	var bits := []
	for k in bays:
		var h: Holder = bays[k]
		bits.append("%d/%d" % [h.count(), h.capacity])
	_label.text = "Module %d: %s" % [Market.orbit_modules + 1, "  ".join(bits)]


func save_contents() -> Dictionary:
	var d := {}
	for k in bays:
		d["bay_" + k] = bays[k].items.duplicate()
	return d


func load_contents(d: Dictionary) -> void:
	for k in bays:
		Building.fill(bays[k], d.get("bay_" + k, []))
	_update()


func status() -> String:
	match state:
		S.COUNTDOWN, S.FLIGHT: return "Launching module %d" % (Market.orbit_modules + 1)
		S.TURNAROUND: return "Turning the pad around"
	return "Assembling orbital module %d" % (Market.orbit_modules + 1)


func info() -> Array:
	var out := [["launchpad", "%d modules in orbit, serving %s" % [Market.orbit_modules, Defs.model_name(Market.orbit_model) if Market.orbit_model != "" else "nothing yet"]]]
	for k in bays:
		var h: Holder = bays[k]
		out.append([k, "%s %d / %d" % [Defs.item_name(k), h.count(), h.capacity]])
	out.append(["groundstation", "Downlink %s of %s tok/s" % [Fmt.tokens(minf(Market.orbit_capacity(), Market.downlink())), Fmt.tokens(Market.downlink())]])
	return out


func upgrade_info() -> Array:
	return [["Pad turnaround", Fmt.time(turnaround(level)), Fmt.time(turnaround(level + 1))]]
