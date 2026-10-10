class_name Worker
extends Node3D
## A hired worker. Their role reads at a glance (outfit, hat, tool, a coloured
## ring under their feet and a role badge). Haulers ask the World's broker
## for the best job they're allowed to do ("take 6 milk from the Dairy Barn
## to the Butter Churn"), walk there on the grid, load up, deliver, repeat:
##   gatherer  farm crates  -> kitchens, the pantry (or hoppers if no feeders)
##   feeder    pantry, kitchens -> mixers, hoppers, kitchens
##   collector ovens -> packers, racks (or sales if no loaders)
##   loader    racks, packers -> vans, trains, airships, shops, orders
## Chefs stand at their oven / machine and work it. Resting workers sit at a
## cabin.

enum S { DECIDE, GO_TAKE, TAKING, GO_GIVE, GIVING, WAIT, REST, STATION }

var world: World
var data: Dictionary            # {id, role, target}
var role := ""
var ch: Character
var carry: Holder
var state := S.DECIDE
var _job := {}
var _item := ""
var _want := 0
var _reserved := 0
var _take_zone: Zone
var _give_zone: Zone
var _dst: Building
var _path := PackedVector3Array()
var _pi := 0
var _path_cd := 0.0
var _goal := Vector3.INF
var _timer := 0.0
var _badge: Node3D
var _ring: MeshInstance3D
var _bubble: Label3D
var _greet_t := 0.0


func setup(p_world: World, p_data: Dictionary) -> void:
	world = p_world
	data = p_data
	name = "Worker%d" % int(data["id"])


func _ready() -> void:
	_bubble = UI3D.label("", 44)
	_bubble.position = Vector3(0, 2.0, 0)
	add_child(_bubble)
	apply_role()


func apply_role() -> void:
	release()
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
	ch.scale = Vector3.ONE * 0.95
	if role == "loader":
		ch.carry_mount.position = Vector3(0, 0.06, 0.6)
	carry = Holder.new().setup(Bal.worker_carry(), [], Holder.Layout.COLUMN)
	carry.sway = 0.05
	ch.carry_mount.add_child(carry)
	carry.changed.connect(func(): ch.carrying = carry.count() > 0)
	var col := Color(0.8, 0.8, 0.85)
	if role != "":
		col = Defs.ROLES[role]["color"]
		_badge = UI3D.badge(Defs.ROLES[role]["icon"], col.darkened(0.2), 0.5)
		_badge.position = Vector3(0, 2.05, 0)
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
	if is_inside_tree():
		Fx.ring(get_tree().current_scene, global_position, col, 1.6)


func greet() -> void:
	scale = Vector3(0.2, 0.2, 0.2)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.burst(get_tree().current_scene, global_position + Vector3(0, 1.2, 0), Pal.MINT, 18)
	UI3D.pop_text(get_tree().current_scene, global_position + Vector3(0, 2.4, 0), "Hi!", Color(1, 1, 1), 70)
	ch.work = "cheer"
	_greet_t = 1.4


func refresh() -> void:
	if carry:
		carry.capacity = Bal.worker_carry()


## Drops any reservation (job cancelled / worker removed).
func release() -> void:
	if _reserved > 0 and _job.has("src_holder"):
		world.unreserve(_job["src_holder"], _item, _reserved)
	_reserved = 0


func _speed() -> float:
	return Bal.worker_speed() * (1.0 + world.aura(global_position, "walk")) * Game.speed_mult()


func _process(dt: float) -> void:
	if _greet_t > 0.0:
		_greet_t -= dt
		ch.move_speed = 0.0
		if _greet_t <= 0.0:
			ch.work = ""
		return
	if _badge:
		_badge.position.y = 2.05 + carry.count() * 0.04 + sin(Time.get_ticks_msec() * 0.004 + data["id"]) * 0.04
	_bubble.visible = state == S.WAIT or state == S.REST
	match state:
		S.DECIDE:
			_decide()
		S.GO_TAKE:
			if not is_instance_valid(_take_zone):
				_abort()
			elif _walk_to(_take_zone, dt):
				state = S.TAKING
				_timer = 0.0
		S.TAKING:
			ch.move_speed = 0.0
			ch.work = _anim(true)
			if not is_instance_valid(_take_zone):
				_abort()
				return
			var have := carry.count_of(_item) + carry.incoming
			if have >= _want or carry.space() <= 0:
				_after_take()
				return
			if _take_zone.tick(self, carry, dt, 0.12, _item):
				_timer = 0.0
			else:
				_timer += dt
			if _timer > 1.0:
				_after_take()
		S.GO_GIVE:
			if not is_instance_valid(_give_zone):
				_redirect()
			elif _walk_to(_give_zone, dt):
				state = S.GIVING
				_timer = 0.0
		S.GIVING:
			ch.move_speed = 0.0
			ch.work = _anim(false)
			if not is_instance_valid(_give_zone):
				_redirect()
				return
			if carry.count() == 0 and carry.incoming == 0:
				state = S.DECIDE
				return
			var moved := _give_zone.tick(self, carry, dt, 0.12, _item)
			_timer = 0.0 if moved else _timer + dt
			if _timer > 1.0:
				_redirect()
		S.WAIT:
			ch.move_speed = 0.0
			ch.work = ""
			_timer -= dt
			if _timer <= 0.0:
				state = S.DECIDE
		S.REST:
			_rest(dt)
		S.STATION:
			_station(dt)


func _anim(taking: bool) -> String:
	match role:
		"gatherer": return "pick" if taking else "scoop"
		"feeder": return "scoop"
		"collector": return "pick" if taking else ""
		"loader": return "push"
	return ""


# ---------------------------------------------------------------- decisions

func _decide() -> void:
	release()
	_bubble.text = ""
	match role:
		"":
			state = S.REST
			_bubble.text = "z z"
			return
		"chef":
			state = S.STATION
			return
	if carry.count() > 0:
		_item = carry.items[carry.items.size() - 1]
		_redirect()
		return
	var job := world.find_job(role, global_position, carry.space())
	if job.is_empty():
		_wait("...")
		return
	_job = job
	_item = job["item"]
	_want = int(job["count"])
	_reserved = _want
	world.reserve(job["src_holder"], _item, _want)
	_take_zone = job["src_zone"]
	_dst = job["dst"]
	_goal = Vector3.INF
	state = S.GO_TAKE


func _after_take() -> void:
	release()
	if carry.count() + carry.incoming == 0:
		_wait("...")
		return
	if is_instance_valid(_dst) and _dst.need(_item) > 0.0:
		_give_zone = _dst.in_zone_for(_item)
		if _give_zone:
			_goal = Vector3.INF
			state = S.GO_GIVE
			return
	_redirect()


## Find somewhere (else) to deliver what we carry.
func _redirect() -> void:
	if carry.count() == 0:
		state = S.DECIDE
		return
	_item = carry.items[carry.items.size() - 1]
	var d := world.find_dest(role, _item, global_position)
	if d == null:
		_wait("FULL" if role in ["collector", "loader"] else "...")
		return
	_dst = d
	_give_zone = d.in_zone_for(_item)
	if _give_zone == null:
		_wait("...")
		return
	_goal = Vector3.INF
	state = S.GO_GIVE


func _abort() -> void:
	release()
	state = S.DECIDE


func _wait(txt: String) -> void:
	_bubble.text = txt
	state = S.WAIT
	_timer = 1.0
	ch.work = ""


# ---------------------------------------------------------------- moving

func _zone_point(z: Zone) -> Vector3:
	var off := Vector3(fmod(float(data["id"]) * 0.37, 0.6) - 0.3, 0, fmod(float(data["id"]) * 0.53, 0.4) - 0.2)
	return z.global_position + z.global_transform.basis * (off * Vector3(z.size.x / 1.8, 0, z.size.y / 1.4))


func _walk_to(z: Zone, dt: float) -> bool:
	if z.contains(global_position, -0.1):
		ch.move_speed = 0.0
		return true
	return _walk_point(_zone_point(z), dt)


func _walk_point(target: Vector3, dt: float) -> bool:
	_path_cd -= dt
	if _goal.distance_to(target) > 0.4 or _path_cd <= 0.0:
		_goal = target
		_path_cd = 2.0
		_path = world.grid.path(global_position, target)
		_pi = 0
	while _pi < _path.size() and Vector2(_path[_pi].x - global_position.x, _path[_pi].z - global_position.z).length() < 0.2:
		_pi += 1
	if _pi >= _path.size():
		var rest := target - global_position
		rest.y = 0
		if rest.length() < 0.12:
			ch.move_speed = 0.0
			return true
		_path = PackedVector3Array([target])
		_pi = 0
	var to := _path[_pi] - global_position
	to.y = 0
	var spd := _speed()
	if to.length() > 0.001:
		global_position += to.normalized() * minf(to.length(), spd * dt)
		ch.face(to, dt, 10.0)
	global_position.y = 0.0
	ch.move_speed = clampf(spd / 4.0, 0.5, 1.0)
	ch.work = "push" if role == "loader" else ""
	return false


func _rest(dt: float) -> void:
	var seat := world.rest_seat(self)
	var to := seat - global_position
	to.y = 0
	if to.length() > 0.15:
		_walk_point(seat, dt)
	else:
		ch.move_speed = 0.0
		ch.work = "sit"
		ch.face(Vector3(0, 0, 1), dt, 4.0)


## Chefs stand in front of their machine and work it.
func _station(dt: float) -> void:
	var b: Building = world.building(int(data.get("target", 0)))
	if b == null:
		_wait("?")
		return
	var spot := b.to_world(-0.3 + fmod(float(data["id"]) * 0.7, 1.2), 0.45 if not b is OvenB else 0.55)
	var to := spot - global_position
	to.y = 0
	if to.length() > 0.15:
		_walk_point(spot, dt)
	else:
		ch.move_speed = 0.0
		ch.work = "scoop"
		ch.face(-b.global_transform.basis.z, dt, 5.0)
