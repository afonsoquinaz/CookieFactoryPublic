class_name Dock
extends Node3D
## A delivery dock on the east pier with its truck. Load cookies onto the pad;
## when the truck is full (or nobody has loaded it for a few seconds) it
## honks, drives off over the bridge and the cookies are sold. It comes back
## empty after the trip time.

signal sold(amount: int, count: int, where: Vector3)

enum S { PARKED, LEAVING, AWAY, RETURNING }

var index := 0
var cargo: Holder
var zone: Zone
var state := S.PARKED
var truck: Node3D
var _truck_body: Node3D
var _wheels: Array[Node3D] = []
var _idle := 0.0
var _timer := 0.0
var _label: Label3D
var _t := 0.0
var _park_x := 0.0
var _truck_mesh: MeshInstance3D
var _tier := 0


func setup(p_index: int) -> void:
	index = p_index
	name = "Dock%d" % (index + 1)
	position = Vector3(0, 0, Lay.DOCK_Z[index])
	_park_x = Lay.TRUCK_X
	truck = Node3D.new()
	truck.position = Vector3(_park_x, 0.08, 0)
	add_child(truck)
	_truck_body = Node3D.new()
	truck.add_child(_truck_body)
	_truck_mesh = Mats.inst(MeshKit.cached("van_0", func(): return Dock.truck_mesh(0)), _truck_body)
	for p in [Vector3(-1.05, 0.32, 0.72), Vector3(-1.05, 0.32, -0.72), Vector3(1.0, 0.32, 0.72), Vector3(1.0, 0.32, -0.72)]:
		var w := Node3D.new()
		w.position = p
		truck.add_child(w)
		Mats.inst(MeshKit.cached("wheel", func():
			var k := MeshKit.new()
			k.cyl(0.3, 0.24, Pal.RUBBER, MeshKit.xf(Vector3(0, 0, -0.12), Vector3(90, 0, 0)), 16, 0.05)
			k.cyl(0.14, 0.26, Pal.STEEL, MeshKit.xf(Vector3(0, 0, -0.13), Vector3(90, 0, 0)), 10, 0.02)
			return k.commit()), w)
		_wheels.append(w)
	cargo = Holder.new().setup(10, ["cookie"], Holder.Layout.GRID)
	cargo.grid = Vector2i(4, 3)
	cargo.cell = Vector2(0.36, 0.38)
	cargo.max_visible = 60
	cargo.position = Vector3(-0.55, 0.92, 0)
	_truck_body.add_child(cargo)
	cargo.landed.connect(_on_load)
	zone = Zone.make(Zone.Kind.GIVE, [cargo], Vector2(1.7, 1.7), "truck", Pal.TERRACOTTA)
	zone.position = Vector3(Lay.DOCK_ZONE_X, 0, 0)
	add_child(zone)
	_label = UI3D.label("0/10", 32)
	_label.position = Vector3(_park_x - 0.4, 3.1, 0)
	add_child(_label)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(3.6, 2.0, 2.0)
	cs.shape = sh
	cs.position = Vector3(_park_x, 1.0, 0)
	body.add_child(cs)
	add_child(body)
	refresh(false)


func refresh(animate := true) -> void:
	cargo.capacity = Bal.truck_cap(Game.lvl("truck"))
	var l := Game.lvl("truck")
	var tier := 2 if l >= 10 else (1 if l >= 5 else 0)
	if tier != _tier:
		_tier = tier
		_truck_mesh.mesh = MeshKit.cached("van_%d" % tier, func(): return Dock.truck_mesh(tier))
		if animate:
			Fx.burst(get_tree().current_scene, truck.global_position + Vector3(0, 1.5, 0), Pal.GOLD, 20)
	_update_label()


func _on_load(_t2: String) -> void:
	_idle = 0.0
	_update_label()
	var tw := _truck_body.create_tween()
	_truck_body.scale = Vector3(1.02, 0.97, 1.02)
	tw.tween_property(_truck_body, "scale", Vector3.ONE, 0.15)


func _update_label() -> void:
	match state:
		S.PARKED:
			if cargo.count() > 0 and cargo.space() > 0:
				var left := Bal.TRUCK_IDLE_DEPART - _idle
				_label.text = "%d/%d" % [cargo.count(), cargo.capacity] + ("  %ds" % ceili(left) if left < 4.0 else "")
			else:
				_label.text = "%d/%d" % [cargo.count(), cargo.capacity]
		S.LEAVING, S.AWAY:
			_label.text = "Back in %ds" % ceili(maxf(0.0, _timer))
		S.RETURNING:
			_label.text = "Arriving..."


func _process(dt: float) -> void:
	_t += dt
	var mult := Game.speed_mult()
	match state:
		S.PARKED:
			zone.enabled = true
			_truck_body.position.y = sin(_t * 12.0) * 0.008
			if cargo.count() > 0 and cargo.incoming == 0:
				_idle += dt
				if cargo.space() <= 0 and _idle > 0.5:
					_depart()
				elif _idle >= Bal.TRUCK_IDLE_DEPART:
					_depart()
			_update_label()
		S.LEAVING:
			zone.enabled = false
			_timer -= dt * mult
			truck.position.x += dt * (3.0 + (truck.position.x - _park_x) * 2.5)
			_spin(dt, 1.0)
			if truck.position.x > _park_x + 14.0:
				truck.visible = false
				state = S.AWAY
			_update_label()
		S.AWAY:
			_timer -= dt * mult
			if _timer <= 1.2:
				state = S.RETURNING
				truck.visible = true
				truck.position.x = _park_x + 12.0
				Sfx.play("engine", -4.0)
			_update_label()
		S.RETURNING:
			_timer -= dt * mult
			var to := _park_x - truck.position.x
			truck.position.x += to * clampf(dt * 3.0, 0.0, 1.0)
			_spin(dt, -1.0)
			if absf(to) < 0.03:
				truck.position.x = _park_x
				state = S.PARKED
				_idle = 0.0
				var tw := _truck_body.create_tween()
				_truck_body.scale = Vector3(1.05, 0.92, 1.05)
				tw.tween_property(_truck_body, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				Sfx.play("horn", -8.0, 1.2)
			_update_label()


func _spin(dt: float, dir: float) -> void:
	for w in _wheels:
		w.rotation.z -= dt * 8.0 * dir


func _depart() -> void:
	var n := cargo.count()
	var amount := Game.sell_cookies(n)
	var where := truck.global_position + Vector3(0, 2.0, 0)
	sold.emit(amount, n, where)
	Fx.coins(get_tree().current_scene, where, mini(12, 3 + n / 4))
	UI3D.pop_text(get_tree().current_scene, where + Vector3(0, 0.8, 0), "+$%s" % Fmt.num(amount), Color(1.0, 0.88, 0.3), 80)
	Sfx.play("cash")
	Sfx.play("horn", -4.0)
	cargo.clear_all()
	state = S.LEAVING
	_timer = Bal.truck_trip(Game.lvl("route"))
	_idle = 0.0


## Tier 0: cream delivery truck, 1: sage, 2: charcoal with brass trim.
## Open slatted bed so the load of cookies stays visible.
static func truck_mesh(tier := 0) -> Mesh:
	var k := MeshKit.new()
	var cab: Color = [Color(0.92, 0.89, 0.81), Color(0.52, 0.6, 0.46), Color(0.24, 0.24, 0.25)][tier]
	var trim: Color = [Pal.TERRACOTTA, Pal.CREAM, Pal.BRASS][tier]
	var dark := Pal.STEEL_DARK
	k.rbox(Vector3(3.3, 0.24, 1.4), 0.04, dark, MeshKit.at(0, 0.45, 0))
	# cab (front = +x)
	k.rbox(Vector3(1.05, 1.0, 1.5), 0.12, cab, MeshKit.at(1.1, 1.05, 0))
	k.rbox(Vector3(0.7, 0.3, 1.52), 0.1, cab, MeshKit.at(1.38, 0.68, 0))
	k.rbox(Vector3(0.06, 0.42, 1.26), 0.03, Color(0.55, 0.66, 0.72, 0.85), MeshKit.at(1.63, 1.3, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(0.58, 0.38, 0.04), 0.03, Color(0.55, 0.66, 0.72, 0.85), MeshKit.at(1.08, 1.3, sz * 0.76))
		k.rbox(Vector3(1.06, 0.06, 0.03), 0.01, trim, MeshKit.at(1.1, 0.86, sz * 0.765))
		k.sphere(0.07, Color(1.0, 0.95, 0.8, 0.5), MeshKit.at(1.73, 0.74, sz * 0.52), 8, 5)
	k.rbox(Vector3(0.05, 0.22, 0.9), 0.02, dark, MeshKit.at(1.75, 0.68, 0))
	k.rbox(Vector3(0.1, 0.12, 1.56), 0.03, dark, MeshKit.at(1.76, 0.48, 0))
	# slatted wooden bed
	k.rbox(Vector3(2.1, 0.08, 1.5), 0.02, Pal.WOOD_DARK, MeshKit.at(-0.55, 0.62, 0))
	for sz in [-1.0, 1.0]:
		for yy in [0.78, 0.96, 1.14]:
			k.rbox(Vector3(2.1, 0.11, 0.05), 0.015, Pal.WOOD, MeshKit.at(-0.55, yy, sz * 0.72))
		for xx in [-1.55, -0.55, 0.45]:
			k.rbox(Vector3(0.07, 0.6, 0.07), 0.015, dark, MeshKit.at(xx, 0.93, sz * 0.72))
	for yy in [0.78, 0.96, 1.14]:
		k.rbox(Vector3(0.05, 0.11, 1.44), 0.015, Pal.WOOD, MeshKit.at(-1.6, yy, 0))
	# a small emblem on the cab door
	Items.cookie_into(k, 0.13, 0.03, MeshKit.xf(Vector3(1.05, 1.0, 0.77), Vector3(90, 0, 0)))
	if tier >= 1:
		k.rbox(Vector3(0.6, 0.08, 1.2), 0.03, dark, MeshKit.at(1.1, 1.59, 0))
	if tier >= 2:
		for sz in [-1.0, 1.0]:
			k.cyl(0.05, 0.9, Pal.BRASS, MeshKit.at(0.58, 0.9, sz * 0.62), 8, 0.01)
	return k.commit()
