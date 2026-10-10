class_name VehicleB
extends Building
## Sells what you load into it, then drives off and comes back:
##   dock     Delivery Van: drives out along its road onto the High Street and
##            off to town in the eastbound lane, comes back in the westbound
##            one, drives into its bay and the turntable turns it around
##   train    Rail Depot: a freight train leaves into the tunnel, big loads
##   airship  Airship Mast: an airship floats up into the clouds; gifts x2
## It leaves when full, or a few seconds after its last load.

enum S { PARKED, LEAVING, AWAY, RETURNING, TURNING }

var cargo: Holder
var state := S.PARKED
var vehicle: Node3D
var _vbody: Node3D
var _vmesh: MeshInstance3D
var _turn: Node3D                 # the van's turntable (dock)
var _props: MeshInstance3D        # things the depot gains as it levels up
var _props_n := -1
var _route: Curve3D               # the van's drive (world space)
var _route_len := 0.0
var _drive := 0.0                 # metres along the route
var _drive_t := 0.0               # seconds the drive should take
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
			_park = Vector3(0, 0.1, SalesArt.BAY_Z)
			_turn = Node3D.new()
			_turn.position = Vector3(0, 0.02, SalesArt.BAY_Z)
			add_child(_turn)
			remove_child(vehicle)
			_turn.add_child(vehicle)
			vehicle.rotation.y = -PI * 0.5
			_props = Mats.inst(null, self)
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
	vehicle.position = _park if kind != "dock" else Vector3(0, 0.08, 0)
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
		"dock": return [Rect2(-2.0, -3.0, 4.0, 1.5)]
		"train": return [Rect2(-3.0, -3.0, 6.0, 3.9)]
	return [Rect2(-2.2, -3.0, 4.4, 3.6)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("%s_site_%d" % [kind, t], func(): return SalesArt.site(kind, t)), root)
	if kind == "dock":
		for c in _turn.get_children():
			if c != vehicle:
				c.queue_free()
		Mats.inst(MeshKit.cached("turntable_%d" % t, SalesArt.turntable.bind(t)), _turn)
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
	if _props:
		var n := LevelArt.count(SalesArt.DOCK_PROPS.size(), level, Bal.max_level(kind))
		if n != _props_n:
			_props_n = n
			_props.mesh = MeshKit.cached("dock_props_%d_%d" % [n, tier], func(): return LevelArt.props(SalesArt.DOCK_PROPS, n, tier))
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
		S.RETURNING, S.TURNING:
			_label.text = "Arriving..."


func _process(dt: float) -> void:
	super(dt)
	if kind == "dock":
		_process_van(dt)
		return
	var mult := Game.speed_mult()
	match state:
		S.PARKED:
			if kind == "airship":
				vehicle.position.y = _park.y + sin(_t * 1.2) * 0.12
			else:
				_vbody.position.y = sin(_t * 12.0) * 0.006
			_check_depart(dt)
		S.LEAVING:
			_timer -= dt * mult
			if _move_out(dt):
				vehicle.visible = false
				state = S.AWAY
			_update_label()
		S.AWAY:
			_timer -= dt * mult
			if _timer <= 1.4:
				state = S.RETURNING
				vehicle.visible = true
				_start_return()
				Sfx.play("engine", -8.0)
			_update_label()
		S.RETURNING:
			_timer -= dt * mult
			if _move_in(dt):
				vehicle.position = _park
				_arrived()
			_update_label()


func _check_depart(dt: float) -> void:
	if cargo.count() > 0 and cargo.incoming == 0:
		_idle += dt
		if (cargo.space() <= 0 and _idle > 0.5) or _idle >= Bal.TRUCK_IDLE_DEPART:
			_depart()
	_update_label()


func _arrived() -> void:
	state = S.PARKED
	_idle = 0.0
	var tw := _vbody.create_tween()
	_vbody.scale = Vector3(1.05, 0.92, 1.05)
	tw.tween_property(_vbody, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Sfx.play("horn", -10.0, 1.2)


# ---------------------------------------------------------------- the van on the streets

func _process_van(dt: float) -> void:
	var mult := Game.speed_mult()
	match state:
		S.PARKED:
			_vbody.position.y = sin(_t * 12.0) * 0.006
			_check_depart(dt)
		S.LEAVING:
			_timer -= dt * mult
			if _drive_along(dt * mult, false):
				vehicle.visible = false
				state = S.AWAY
			_update_label()
		S.AWAY:
			_timer -= dt * mult
			# come back in time to drive in
			if _timer <= _drive_t:
				if _plan_route(true):
					state = S.RETURNING
					vehicle.visible = true
					Sfx.play("engine", -10.0)
				else:
					_park_van()
					_arrived()
			_update_label()
		S.RETURNING:
			_timer -= dt * mult
			if _drive_along(dt * mult, true):
				_spin_around()
			_update_label()


## Plans the drive (world space): out = from the bay along the road to the
## High Street and off east; back = in from the east and into the bay.
func _plan_route(back: bool) -> bool:
	var ents := entrance_cells()
	var pts := PackedVector3Array()
	var bay := to_world(0, SalesArt.BAY_Z, 0.08)
	var door := door_pos()
	var cells: Array[Vector2i] = []
	if world:
		cells = world.street_route(ents[0])
	if cells.is_empty() and not Roads.is_street(ents[0]):
		return false
	# side road cells up to (not including) the High Street
	var side := PackedVector3Array()
	var junction := Grid.cell_center(ents[0])
	for c in cells:
		if Roads.is_street(c):
			junction = Grid.cell_center(c)
			break
		side.append(Grid.cell_center(c))
	if cells.is_empty():
		junction = Grid.cell_center(ents[0])
	var row_z := (Roads.STREET_Y + 1) * Grid.CELL   # the centre line (world z)
	var north := door.z < row_z
	var east_z := row_z + Grid.CELL * 0.5           # eastbound lane
	var west_z := row_z - Grid.CELL * 0.5           # westbound lane
	var edge_z := row_z - Grid.CELL if north else row_z + Grid.CELL
	var far := 28.0
	if not back:
		pts.append(bay)
		pts.append(door)
		pts.append_array(side)
		pts.append(Vector3(junction.x, 0, edge_z))
		pts.append(Vector3(junction.x + 2.6, 0, east_z))
		pts.append(Vector3(junction.x + far, 0, east_z))
	else:
		pts.append(Vector3(junction.x + far, 0, west_z))
		pts.append(Vector3(junction.x + 2.6, 0, west_z))
		pts.append(Vector3(junction.x, 0, edge_z))
		for i in range(side.size() - 1, -1, -1):
			pts.append(side[i])
		pts.append(door)
		pts.append(bay)
	# drop points too close together (the door can sit on the first road cell)
	var clean := PackedVector3Array()
	for p in pts:
		if clean.is_empty() or clean[clean.size() - 1].distance_to(p) > 0.5:
			clean.append(Vector3(p.x, 0.08, p.z))
	_route = Curve3D.new()
	_route.bake_interval = 0.25
	for i in clean.size():
		var tin := Vector3.ZERO
		var tout := Vector3.ZERO
		if i > 0 and i < clean.size() - 1:
			var tan := (clean[i + 1] - clean[i - 1]).normalized()
			var hl := minf(clean[i].distance_to(clean[i - 1]), clean[i].distance_to(clean[i + 1])) * 0.45
			tin = -tan * hl
			tout = tan * hl
		_route.add_point(clean[i], tin, tout)
	_route_len = _route.get_baked_length()
	_drive = 0.0
	# the van keeps a lively pace whatever the trip time
	_drive_t = clampf(_route_len / 8.0, 2.0, maxf(2.0, trip_time() * 0.45))
	return true


## Moves along the planned route; true when it got to the end.
func _drive_along(dt: float, back: bool) -> bool:
	if _route == null or _route_len <= 0.0:
		return true
	var v := _route_len / _drive_t
	# ease in when leaving the bay, ease out when pulling in
	var near_bay := _drive if not back else _route_len - _drive
	var f := clampf(0.35 + near_bay / 6.0, 0.35, 1.0)
	_drive = minf(_route_len, _drive + v * f * 1.15 * dt)
	var p := _route.sample_baked(_drive)
	var ahead := _route.sample_baked(minf(_route_len, _drive + 0.6))
	var dir := ahead - p
	dir.y = 0.0
	if dir.length() > 0.01:
		dir = dir.normalized()
		var basis := Basis(dir, Vector3.UP, dir.cross(Vector3.UP))
		var cur := vehicle.global_transform.basis.orthonormalized()
		vehicle.global_transform = Transform3D(cur.slerp(basis, clampf(dt * 10.0, 0.0, 1.0)), p)
	else:
		vehicle.global_position = p
	_spin(dt * 2.0, 1.0)
	return _drive >= _route_len - 0.02


## Parked nose-in: the turntable turns the van to face the street again.
func _spin_around() -> void:
	vehicle.transform = Transform3D(Basis(Vector3.UP, PI * 0.5), Vector3(0, 0.08, 0))
	_turn.rotation.y = 0.0
	var tw := _turn.create_tween()
	tw.tween_property(_turn, "rotation:y", PI, 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		if is_instance_valid(self):
			_park_van()
			_arrived())
	state = S.TURNING
	_route = null
	Sfx.play("click", -10.0, 0.6)


## Back on the turntable facing the street.
func _park_van() -> void:
	_turn.rotation.y = 0.0
	vehicle.transform = Transform3D(Basis(Vector3.UP, -PI * 0.5), Vector3(0, 0.08, 0))
	vehicle.visible = true
	_route = null


func _move_out(dt: float) -> bool:
	match kind:
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
		"train":
			vehicle.position = _park + Vector3(-6.0, -3.3, 0)
		_:
			vehicle.position = _park + Vector3(-6.0, 22.0, 0)


func _move_in(dt: float) -> bool:
	var to := _park - vehicle.position
	vehicle.position += to * clampf(dt * 2.6, 0.0, 1.0)
	return to.length() < 0.03


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
	if kind == "dock":
		if _plan_route(false):
			Sfx.play("engine", -10.0)
		else:
			# no way out: it still makes the trip, out of sight
			vehicle.visible = false
			state = S.AWAY


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
