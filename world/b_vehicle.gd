class_name VehicleB
extends Building
## Sells what you load into it, then drives off and comes back:
##   dock     Delivery Van: rolls into its garage at the back
##   train    Rail Depot: a freight train leaves into the tunnel, big loads
##   airship  Airship Mast: an airship floats up into the clouds; gifts x2
## It leaves when full, or a few seconds after its last load.

enum S { PARKED, LEAVING, AWAY, RETURNING }

var cargo: Holder
var state := S.PARKED
var vehicle: Node3D
var _vbody: Node3D
var _vmesh: MeshInstance3D
var _door: Node3D
var _wheels: Array[Node3D] = []
var _idle := 0.0
var _timer := 0.0
var _label: Label3D
var _park := Vector3.ZERO
var _vtier := -1


func _build() -> void:
	cargo = Holder.new().setup(10, [], Holder.Layout.GRID)
	cargo.accept_cat = ["cookie", "box", "gift"]
	vehicle = Node3D.new()
	add_child(vehicle)
	_vbody = Node3D.new()
	vehicle.add_child(_vbody)
	_vmesh = Mats.inst(null, _vbody)
	match kind:
		"dock":
			_park = Vector3(0, 0.08, -0.15)
			vehicle.rotation.y = PI * 0.5
			for p in [Vector3(-1.05, 0.32, 0.72), Vector3(-1.05, 0.32, -0.72), Vector3(1.0, 0.32, 0.72), Vector3(1.0, 0.32, -0.72)]:
				_wheel(p)
			cargo.grid = Vector2i(4, 3)
			cargo.cell = Vector2(0.36, 0.38)
			cargo.position = Vector3(-0.55, 0.92, 0)
		"train":
			_park = Vector3(0.4, 0.12, -1.4)
			cargo.grid = Vector2i(6, 3)
			cargo.cell = Vector2(0.34, 0.34)
			cargo.position = Vector3(0.95, 0.7, 0)
		"airship":
			_park = Vector3(0, 5.2, -0.6)
			cargo.grid = Vector2i(4, 3)
			cargo.cell = Vector2(0.34, 0.34)
			cargo.position = Vector3(0, -1.15, 0)
	cargo.max_visible = 60
	_vbody.add_child(cargo)
	vehicle.position = _park
	cargo.landed.connect(_on_load)
	add_port(cargo, null, "in")
	_label = UI3D.label("0/10", 30)
	_label.position = Vector3(0, 3.4 if kind != "airship" else 7.2, -0.6)
	add_child(_label)


func _wheel(p: Vector3) -> void:
	var w := Node3D.new()
	w.position = p
	_vbody.add_child(w)
	Mats.inst(MeshKit.cached("wheel", func():
		var k := MeshKit.new()
		k.cyl(0.3, 0.24, Pal.RUBBER, MeshKit.xf(Vector3(0, 0, -0.12), Vector3(90, 0, 0)), 16, 0.05)
		k.cyl(0.14, 0.26, Pal.STEEL, MeshKit.xf(Vector3(0, 0, -0.13), Vector3(90, 0, 0)), 10, 0.02)
		return k.commit()), w)
	_wheels.append(w)


func solid_rects() -> Array[Rect2]:
	match kind:
		"dock": return [Rect2(-2.0, -3.0, 4.0, 4.7)]
		"train": return [Rect2(-3.0, -3.0, 6.0, 3.9)]
	return [Rect2(-2.2, -3.0, 4.4, 3.6)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("%s_site_%d" % [kind, t], func(): return SalesArt.site(kind, t)), root)
	if kind == "dock":
		_door = Node3D.new()
		_door.position = Vector3(0, 2.3, -1.65)
		root.add_child(_door)
		Mats.inst(MeshKit.cached("garage_door", SalesArt.garage_door), _door)
	_set_vehicle_tier(t)


func _set_vehicle_tier(t: int) -> void:
	if t == _vtier:
		return
	_vtier = t
	match kind:
		"dock": _vmesh.mesh = MeshKit.cached("van_%d" % t, func(): return SalesArt.van(t))
		"train": _vmesh.mesh = MeshKit.cached("train_%d" % t, func(): return SalesArt.train(t))
		"airship": _vmesh.mesh = MeshKit.cached("airship_%d" % t, func(): return SalesArt.airship(t))


func _on_level() -> void:
	match kind:
		"dock": cargo.capacity = Bal.truck_cap(level)
		"train": cargo.capacity = Bal.train_cap(level)
		"airship": cargo.capacity = Bal.airship_cap(level)
	_update_label()


func trip_time() -> float:
	match kind:
		"train": return Bal.train_trip(level)
		"airship": return Bal.airship_trip(level)
	return Bal.truck_trip(level)


func need(t: String) -> float:
	if state != S.PARKED or not cargo.can_accept(t):
		return 0.0
	var f := float(cargo.count()) / maxf(1.0, cargo.capacity)
	# airships love gifts; everyone prefers topping up a nearly full load
	var w := 0.6 + f * 0.6
	if kind == "airship" and Defs.cat(t) == "gift":
		w += 0.6
	return w


func _on_load(_t2: String) -> void:
	_idle = 0.0
	_update_label()
	var tw := _vbody.create_tween()
	_vbody.scale = Vector3(1.02, 0.97, 1.02)
	tw.tween_property(_vbody, "scale", Vector3.ONE, 0.15)


func _update_label() -> void:
	match state:
		S.PARKED:
			var left := Bal.TRUCK_IDLE_DEPART - _idle
			_label.text = "%d/%d" % [cargo.count(), cargo.capacity] + ("  %ds" % ceili(left) if cargo.count() > 0 and left < 4.0 else "")
		S.LEAVING, S.AWAY:
			_label.text = "Back in %ds" % ceili(maxf(0.0, _timer))
		S.RETURNING:
			_label.text = "Arriving..."


func _process(dt: float) -> void:
	super(dt)
	var mult := Game.speed_mult()
	match state:
		S.PARKED:
			if kind == "airship":
				vehicle.position.y = _park.y + sin(_t * 1.2) * 0.12
			else:
				_vbody.position.y = sin(_t * 12.0) * 0.006
			if cargo.count() > 0 and cargo.incoming == 0:
				_idle += dt
				if (cargo.space() <= 0 and _idle > 0.5) or _idle >= Bal.TRUCK_IDLE_DEPART:
					_depart()
			_update_label()
		S.LEAVING:
			_timer -= dt * mult
			var done := _move_out(dt)
			if done:
				vehicle.visible = false
				state = S.AWAY
			_update_label()
		S.AWAY:
			_timer -= dt * mult
			if _timer <= 1.4:
				if _door:
					_door_to(1.0)
				state = S.RETURNING
				vehicle.visible = true
				_start_return()
				Sfx.play("engine", -8.0)
			_update_label()
		S.RETURNING:
			_timer -= dt * mult
			if _move_in(dt):
				if _door:
					_door_to(0.0)
				vehicle.position = _park
				state = S.PARKED
				_idle = 0.0
				var tw := _vbody.create_tween()
				_vbody.scale = Vector3(1.05, 0.92, 1.05)
				tw.tween_property(_vbody, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				Sfx.play("horn", -10.0, 1.2)
			_update_label()


func _move_out(dt: float) -> bool:
	match kind:
		"dock":
			# into the garage and down its ramp
			vehicle.position.z -= dt * (1.2 + (_park.z - vehicle.position.z) * 1.2)
			vehicle.position.y = _park.y - maxf(0.0, _park.z - vehicle.position.z - 0.6) * 0.75
			_spin(dt, 1.0)
			return vehicle.position.z < -3.6
		"train":
			# down the ramp into the tunnel
			vehicle.position.x -= dt * (1.5 + (_park.x - vehicle.position.x) * 1.4)
			vehicle.position.y = _park.y - maxf(0.0, _park.x - vehicle.position.x) * 0.55
			return vehicle.position.y < -3.2
		_:
			vehicle.position.y += dt * (1.0 + (vehicle.position.y - _park.y) * 0.8)
			vehicle.position.x += dt * 1.2
			return vehicle.position.y > 30.0


func _start_return() -> void:
	match kind:
		"dock":
			vehicle.position = _park + Vector3(0, -2.3, -3.6)
		"train":
			vehicle.position = _park + Vector3(-6.0, -3.3, 0)
		_:
			vehicle.position = _park + Vector3(-6.0, 22.0, 0)


func _move_in(dt: float) -> bool:
	var to := _park - vehicle.position
	vehicle.position += to * clampf(dt * 2.6, 0.0, 1.0)
	if kind == "dock":
		_spin(dt, -1.0)
	return to.length() < 0.03


func _door_to(open: float) -> void:
	if _door == null:
		return
	var tw := _door.create_tween()
	tw.tween_property(_door, "scale:y", 1.0 - open * 0.9, 0.35)


func _spin(dt: float, d: float) -> void:
	for w in _wheels:
		w.rotation.z -= dt * 8.0 * d


func _depart() -> void:
	var n := cargo.count()
	var mult := 1.0
	var gift := 1.0
	match kind:
		"train": mult = Bal.TRAIN_MULT
		"airship": gift = Bal.AIRSHIP_GIFT_MULT
	var amount := Game.sell(cargo.items.duplicate(), mult, gift)
	var where := vehicle.global_position + Vector3(0, 2.0, 0)
	world.sold.emit(amount, n, where)
	Fx.coins(get_tree().current_scene, where, mini(12, 3 + n / 4))
	UI3D.pop_text(get_tree().current_scene, where + Vector3(0, 0.8, 0), "+$%s" % Fmt.num(amount), Color(1.0, 0.88, 0.3), 80)
	Sfx.play("cash")
	Sfx.play("horn", -6.0)
	cargo.clear_all()
	state = S.LEAVING
	_timer = trip_time()
	_idle = 0.0
	if _door:
		_door_to(1.0)
		get_tree().create_timer(2.2).timeout.connect(func():
			if is_instance_valid(self) and state == S.AWAY:
				_door_to(0.0))


func save_contents() -> Dictionary:
	return {"cargo": cargo.items.duplicate() if state == S.PARKED else []}


func load_contents(d: Dictionary) -> void:
	Building.fill(cargo, d.get("cargo", []))


func status() -> String:
	match kind:
		"train": return "Sells for 15% more. Takes huge loads."
		"airship": return "Gifts sell for double."
	return "Leaves when full, or 3s after the last load."


func info() -> Array:
	return [
		["truck" if kind == "dock" else kind, "Carries %d" % cargo.capacity],
		["clock", "Trip %.0fs" % trip_time()],
	]


func upgrade_info() -> Array:
	var n := level + 1
	var cap_now := cargo.capacity
	var cap_next := 0
	var t_next := 0.0
	match kind:
		"dock":
			cap_next = Bal.truck_cap(n)
			t_next = Bal.truck_trip(n)
		"train":
			cap_next = Bal.train_cap(n)
			t_next = Bal.train_trip(n)
		_:
			cap_next = Bal.airship_cap(n)
			t_next = Bal.airship_trip(n)
	return [["Carries", str(cap_now), str(cap_next)], ["Trip", "%.0fs" % trip_time(), "%.0fs" % t_next]]
