class_name Worker
extends Node3D
## A hired worker doing one job in a loop. Their role reads at a glance:
## shirt + hat + tool, a coloured ring under their feet and a role badge
## above their head. Jobs (see Defs.ROLES):
##   gatherer  farm crate -> pantry      feeder  pantry -> emptiest hopper
##   collector oven tray  -> shelf       loader  shelf  -> parked truck
## With no role they rest on the cabin bench.

enum S { DECIDE, GO_TAKE, TAKING, GO_GIVE, GIVING, WAIT, REST }

var world: World
var data: Dictionary            # {id, role, target}
var role := ""
var ch: Character
var carry: Holder
var state := S.DECIDE
var _path := PackedVector3Array()
var _path_i := 0
var _path_cd := 0.0
var _path_goal := Vector3.INF
var _take_zone: Zone
var _give_zone: Zone
var _filter := ""
var _want := 0
var _timer := 0.0
var _badge: Sprite3D
var _ring: MeshInstance3D
var _bubble: Label3D
var _stuck := 0.0
var _last_pos := Vector3.ZERO
var _seat := -1
var _greet_t := 0.0


func setup(p_world: World, p_data: Dictionary) -> void:
	world = p_world
	data = p_data
	name = "Worker%d" % int(data["id"])


func _ready() -> void:
	_bubble = UI3D.label("", 44)
	_bubble.position = Vector3(0, 2.35, 0)
	add_child(_bubble)
	apply_role()


func apply_role() -> void:
	role = data["role"]
	if ch:
		ch.queue_free()
	if _badge:
		_badge.queue_free()
		_badge = null
	if _ring:
		_ring.queue_free()
	ch = Character.new()
	add_child(ch)
	ch.setup(role if role != "" else "idle", int(data["id"]) * 13 + 5)
	ch.scale = Vector3.ONE * 1.35
	if role == "loader":
		# loaders stack cookies on their hand truck's nose plate
		ch.carry_mount.position = Vector3(0, 0.08, 0.52)
	carry = Holder.new().setup(Bal.worker_carry(Game.lvl("wcarry")), [], Holder.Layout.COLUMN)
	carry.sway = 0.05
	ch.carry_mount.add_child(carry)
	carry.changed.connect(func(): ch.carrying = carry.count() > 0)
	var col := Color(0.8, 0.8, 0.85)
	if role != "":
		col = Defs.ROLES[role]["color"]
		_badge = UI3D.icon(Defs.ROLES[role]["icon"], 0.0026)
		_badge.position = Vector3(0, 2.3, 0)
		add_child(_badge)
	_ring = MeshInstance3D.new()
	var k := MeshKit.new()
	k.torus(0.4, 0.04, Color(1, 1, 1), Transform3D.IDENTITY, 24, 4)
	_ring.mesh = k.commit()
	_ring.scale = Vector3.ONE * 1.3
	_ring.material_override = Mats.flat(Color(col.r, col.g, col.b, 0.95))
	_ring.position.y = 0.05
	_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_ring)
	state = S.DECIDE
	_seat = -1
	Fx.ring(get_tree().current_scene if is_inside_tree() else null, global_position, col, 1.6)


## Just hired: pop in, wave, confetti.
func greet() -> void:
	scale = Vector3(0.2, 0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.burst(get_tree().current_scene, global_position + Vector3(0, 1.2, 0), Pal.MINT, 18)
	UI3D.pop_text(get_tree().current_scene, global_position + Vector3(0, 2.4, 0), "Hi!", Color(1, 1, 1), 70)
	ch.work = "cheer"
	_greet_t = 1.4


func refresh() -> void:
	carry.capacity = Bal.worker_carry(Game.lvl("wcarry"))


func _speed() -> float:
	return Bal.worker_speed(Game.lvl("wspeed")) * Game.speed_mult()


func _process(dt: float) -> void:
	if _greet_t > 0.0:
		_greet_t -= dt
		ch.move_speed = 0.0
		if _greet_t <= 0.0:
			ch.work = ""
		return
	if _badge:
		_badge.position.y = 2.3 + carry.count() * 0.05 + sin(Time.get_ticks_msec() * 0.004 + data["id"]) * 0.04
	_bubble.visible = state == S.WAIT or state == S.REST
	match state:
		S.DECIDE:
			_decide()
		S.GO_TAKE:
			if _move_to(_take_zone, dt):
				state = S.TAKING
				_timer = 0.0
		S.TAKING:
			ch.move_speed = 0.0
			ch.work = _anim(true)
			var before := carry.count() + carry.incoming
			if before >= _want or carry.space() <= 0:
				_after_take()
				return
			if _take_zone.contains(global_position, 0.3):
				_take_zone.tick(self, carry, dt, 0.14, _filter)
			_timer += dt
			if _timer > 1.6:
				_after_take()
		S.GO_GIVE:
			if _move_to(_give_zone, dt):
				state = S.GIVING
				_timer = 0.0
		S.GIVING:
			ch.move_speed = 0.0
			ch.work = _anim(false)
			if carry.count() == 0 and carry.incoming == 0:
				state = S.DECIDE
				return
			var moved := _give_zone.tick(self, carry, dt, 0.14, _filter)
			_timer = 0.0 if moved else _timer + dt
			if _timer > 1.2:
				# target full: try somewhere else (or wait)
				_after_give_blocked()
		S.WAIT:
			ch.move_speed = 0.0
			_timer -= dt
			if _timer <= 0.0:
				state = S.DECIDE
		S.REST:
			_rest(dt)


## Each role has its own loading / unloading motion.
func _anim(taking: bool) -> String:
	match role:
		"gatherer": return "pick" if taking else "scoop"
		"feeder": return "scoop"
		"collector": return "pick" if taking else ""
		"loader": return "push"
	return ""


# ---------------------------------------------------------------- decisions

func _decide() -> void:
	_filter = ""
	match role:
		"":
			state = S.REST
			_bubble.text = "z z"
			return
		"gatherer":
			if carry.count() > 0:
				_filter = carry.items[0]
				_go_give(_gatherer_drop())
				return
			var farm: Farm = world.pick_farm_for_gatherer(data.get("target", ""))
			if farm == null or world.pantry == null:
				_wait("...")
				return
			_filter = farm.ing
			_want = carry.capacity
			_go_take(farm.zone)
		"feeder":
			if world.pantry == null:
				_wait("...")
				return
			if carry.count() > 0:
				var t := carry.items[0]
				var hz := world.neediest_hopper_zone(t)
				_filter = t
				_go_give(hz if hz else world.pantry.give_zone)
				return
			var pick: Array = world.pick_feeder_job()
			if pick.is_empty():
				_wait("...")
				return
			_filter = pick[0]
			_want = mini(carry.capacity, int(pick[1]))
			_go_take(world.pantry.take_zone)
		"collector":
			if world.shelf == null:
				_wait("...")
				return
			if carry.count() > 0:
				_go_give(_collector_drop())
				return
			var tz: Zone = world.fullest_tray_zone()
			if tz == null or (world.shelf.bins["cookie"].space() <= 0 and _collector_drop() == world.shelf.give_zone):
				_wait("...")
				return
			_filter = "cookie"
			_want = carry.capacity
			_go_take(tz)
		"loader":
			if world.shelf == null:
				_wait("...")
				return
			var dz: Dock = world.parked_dock()
			if carry.count() > 0:
				if dz:
					_go_give(dz.zone)
				else:
					_wait("...")
				return
			if dz == null or world.shelf.bins["cookie"].count() == 0:
				_wait("...")
				return
			_filter = "cookie"
			_want = mini(carry.capacity, dz.cargo.space())
			_go_take(world.shelf.take_zone)


func _go_take(z: Zone) -> void:
	if z == null:
		_wait("?")
		return
	_take_zone = z
	_set_target(z)
	state = S.GO_TAKE


func _go_give(z: Zone) -> void:
	if z == null:
		_wait("?")
		return
	_give_zone = z
	_set_target(z)
	state = S.GO_GIVE


func _wait(txt: String) -> void:
	_bubble.text = txt
	state = S.WAIT
	_timer = 0.8
	ch.work = ""


func _after_take() -> void:
	if carry.count() + carry.incoming == 0:
		_wait("...")
		return
	match role:
		"gatherer":
			_go_give(_gatherer_drop())
		"feeder":
			var hz := world.neediest_hopper_zone(_filter)
			_go_give(hz if hz else world.pantry.give_zone)
		"collector":
			_go_give(_collector_drop())
		"loader":
			var dz: Dock = world.parked_dock()
			if dz:
				_go_give(dz.zone)
			else:
				_wait("...")


## Without Feeders a Gatherer fills the hoppers itself; otherwise the Pantry.
func _gatherer_drop() -> Zone:
	if Game.workers_with("feeder") == 0:
		var hz := world.neediest_hopper_zone(_filter)
		if hz and hz.holders[0].space() > 0:
			return hz
	return world.pantry.give_zone if world.pantry else null


## Without Loaders a Collector loads the truck itself; otherwise the Shelf.
func _collector_drop() -> Zone:
	if Game.workers_with("loader") == 0:
		var d: Dock = world.parked_dock()
		if d:
			return d.zone
	return world.shelf.give_zone


func _after_give_blocked() -> void:
	match role:
		"feeder":
			var hz := world.neediest_hopper_zone(_filter)
			if hz and hz != _give_zone:
				_go_give(hz)
			else:
				_go_give(world.pantry.give_zone)
		"loader":
			var dz: Dock = world.parked_dock()
			if dz and dz.zone != _give_zone:
				_go_give(dz.zone)
			else:
				_wait("...")
		"gatherer":
			var z := _gatherer_drop()
			if z != _give_zone:
				_go_give(z)
			elif world.pantry and _give_zone != world.pantry.give_zone:
				_go_give(world.pantry.give_zone)
			else:
				_wait("FULL")
		"collector":
			var z2 := _collector_drop()
			if z2 != _give_zone:
				_go_give(z2)
			else:
				_wait("FULL")
		_:
			_wait("FULL")


# ---------------------------------------------------------------- moving

func _zone_point(z: Zone) -> Vector3:
	# spread workers over the pad so they don't stack on one spot
	var off := Vector3(fmod(float(data["id"]) * 0.37, 0.6) - 0.3, 0, fmod(float(data["id"]) * 0.53, 0.5) - 0.25)
	return z.global_position + off * Vector3(z.size.x / 1.6, 0, z.size.y / 1.6)


func _set_target(z: Zone) -> void:
	_path_goal = Vector3.INF
	_stuck = 0.0


## Next point to walk toward on the navmesh path to `target` (re-planned
## when the target changes or every second).
func _steer(target: Vector3, dt: float) -> Vector3:
	_path_cd -= dt
	if world.nav_ready and (_path_goal.distance_to(target) > 0.3 or _path_cd <= 0.0):
		_path_goal = target
		_path_cd = 1.0
		_path = NavigationServer3D.map_get_path(get_world_3d().navigation_map, global_position, target, true)
		_path_i = 0
	while _path_i < _path.size():
		var q := _path[_path_i]
		if Vector2(q.x - global_position.x, q.z - global_position.z).length() > 0.3:
			return q
		_path_i += 1
	return target


func _move_to(z: Zone, dt: float) -> bool:
	if z == null or not is_instance_valid(z):
		state = S.DECIDE
		return false
	if z.contains(global_position, -0.15):
		ch.move_speed = 0.0
		return true
	var target := _zone_point(z)
	var next := _steer(target, dt)
	var to := next - global_position
	to.y = 0
	if to.length() < 0.05:
		to = target - global_position
		to.y = 0
	var spd := _speed()
	var step := minf(to.length(), spd * dt)
	if to.length() > 0.001:
		global_position += to.normalized() * step
		ch.face(to, dt, 10.0)
	global_position.y = 0.0
	ch.move_speed = clampf(spd / 4.0, 0.5, 1.0)
	ch.work = "push" if role == "loader" else ""
	return false


func _rest(dt: float) -> void:
	if world.cabin == null:
		ch.move_speed = 0.0
		return
	if _seat < 0:
		_seat = world.idle_seat_index(self)
	var seat: Vector3 = world.cabin.seat(_seat)
	var to := seat - global_position
	to.y = 0
	if to.length() > 0.1:
		ch.work = ""
		var spd := _speed()
		global_position += to.normalized() * minf(to.length(), spd * dt)
		ch.move_speed = 0.7
		ch.face(to, dt)
	else:
		ch.move_speed = 0.0
		ch.work = "sit"
		ch.face(Vector3(0, 0, 1), dt, 4.0)
