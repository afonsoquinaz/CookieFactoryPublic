class_name Worker
extends Node3D
## A member of staff walking around the empire.
##   porter  asks the World's broker for the most useful delivery ("6 wheat
##           from the Wheat Field to the Bakery"), walks there along the
##           roads, loads up at the entrance, delivers, repeats.
##   chef    stands at their bakery or kitchen and works it.
## Staff with nothing to do rest on the Staff Cabins' benches.

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
var _src: Building
var _src_holder: Holder
var _dst: Building
var _path := PackedVector3Array()
var _pi := 0
var _goal := Vector3.INF
var _timer := 0.0
var _xfer := 0.0
var _badge: Node3D
var _bubble: Label3D
var _greet_t := 0.0
var _stuck := 0


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
	ch = Character.new()
	add_child(ch)
	ch.setup(_look(), int(data["id"]) * 13 + 5)
	ch.scale = Vector3.ONE * 0.95
	if role == "porter":
		ch.carry_mount.position = Vector3(0, 0.06, 0.6)
	carry = Holder.new().setup(Bal.worker_carry(), [], Holder.Layout.COLUMN)
	carry.sway = 0.05
	ch.carry_mount.add_child(carry)
	carry.changed.connect(func(): ch.carrying = carry.count() > 0)
	if role == "chef":
		var col: Color = Defs.ROLES[role]["color"]
		_badge = UI3D.badge(Defs.ROLES[role]["icon"], col.darkened(0.2), 0.5)
		_badge.position = Vector3(0, 2.05, 0)
		add_child(_badge)
	state = S.DECIDE
	_path = PackedVector3Array()


func _look() -> String:
	match role:
		"porter": return "loader"
		"chef": return "chef"
		"farmer": return "farmer"
	return "idle"


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
	if _reserved > 0 and is_instance_valid(_src_holder):
		world.unreserve(_src_holder, _item, _reserved)
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
		_badge.position.y = 2.05 + sin(Time.get_ticks_msec() * 0.004 + data["id"]) * 0.04
	_bubble.visible = state == S.WAIT and _bubble.text != ""
	match state:
		S.DECIDE:
			_decide()
		S.GO_TAKE:
			if not is_instance_valid(_src):
				_abort()
			elif _walk_to_door(_src, dt):
				state = S.TAKING
				_timer = 0.0
		S.TAKING:
			ch.move_speed = 0.0
			ch.face(_src.inward() if is_instance_valid(_src) else Vector3.FORWARD, dt, 8.0)
			if not is_instance_valid(_src) or not is_instance_valid(_src_holder):
				_abort()
				return
			var have := carry.count_of(_item) + carry.incoming
			if have >= _want or carry.space() <= 0:
				_after_take()
				return
			_xfer -= dt
			if _xfer <= 0.0:
				_xfer = 0.1
				if _src_holder.has(_item) and Holder.fly(_src_holder, carry, _item, 0.32):
					if _reserved > 0:
						world.unreserve(_src_holder, _item, 1)
						_reserved -= 1
					Sfx.play("pop", -10.0, 1.0 + carry.count() * 0.03)
					_timer = 0.0
				else:
					_timer += 0.1
			if _timer > 0.8:
				_after_take()
		S.GO_GIVE:
			if not is_instance_valid(_dst):
				_redirect()
			elif _walk_to_door(_dst, dt):
				state = S.GIVING
				_timer = 0.0
		S.GIVING:
			ch.move_speed = 0.0
			if not is_instance_valid(_dst):
				_redirect()
				return
			ch.face(_dst.inward(), dt, 8.0)
			if carry.count() == 0 and carry.incoming == 0:
				state = S.DECIDE
				return
			_xfer -= dt
			if _xfer <= 0.0:
				_xfer = 0.1
				var moved := false
				for i in range(carry.items.size() - 1, -1, -1):
					var t := carry.items[i]
					var h := _dst.in_holder_for(t)
					if h and Holder.fly(carry, h, t, 0.34):
						moved = true
						Sfx.play("drop", -8.0)
						break
				_timer = 0.0 if moved else _timer + 0.1
			if _timer > 0.6:
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


# ---------------------------------------------------------------- decisions

func _decide() -> void:
	release()
	_bubble.text = ""
	match role:
		"chef":
			state = S.STATION
			return
		"porter":
			pass
		_:
			state = S.REST
			return
	if carry.count() > 0:
		_redirect()
		return
	var job := world.find_job(global_position, carry.space())
	if job.is_empty():
		state = S.REST
		_timer = 1.5
		return
	_job = job
	_item = job["item"]
	_want = int(job["count"])
	_reserved = _want
	_src = job["src"]
	_src_holder = job["src_holder"]
	world.reserve(_src_holder, _item, _want)
	_dst = job["dst"]
	_goal = Vector3.INF
	state = S.GO_TAKE


func _after_take() -> void:
	release()
	if carry.count() + carry.incoming == 0:
		_wait("")
		return
	if is_instance_valid(_dst) and _dst.on_road() and _dst.need(_item) > 0.0:
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
	var d := world.find_dest(_item, global_position)
	if d == null:
		# nobody wants it and storage is full: leave the surplus and get back to work
		_stuck += 1
		if _stuck >= 3:
			_stuck = 0
			_dump()
			state = S.DECIDE
			return
		_wait("FULL")
		return
	_stuck = 0
	_dst = d
	_goal = Vector3.INF
	state = S.GO_GIVE


## Drops what we carry (it's surplus nobody can use right now).
func _dump() -> void:
	if carry.count() == 0:
		return
	var root := get_tree().current_scene
	Fx.puff(root, global_position + Vector3(0, 0.6, 0), Pal.CREAM, 6)
	carry.clear_all()


func _abort() -> void:
	release()
	state = S.DECIDE


func _wait(txt: String) -> void:
	_bubble.text = txt
	state = S.WAIT
	_timer = 1.0
	ch.work = ""


# ---------------------------------------------------------------- moving

## A spot at the entrance (a little spread so porters don't stack).
func _door_point(b: Building) -> Vector3:
	var off := (fmod(float(data["id"]) * 0.37, 0.8) - 0.4)
	return b.door_pos() + b.base_xf().basis.x * off


func _walk_to_door(b: Building, dt: float) -> bool:
	var target := _door_point(b)
	if _goal.distance_to(target) > 0.3:
		_goal = target
		_path = world.road_path(global_position, b)
		_path.append(target)
		_pi = 0
	return _follow(dt)


func _follow(dt: float) -> bool:
	while _pi < _path.size() and Vector2(_path[_pi].x - global_position.x, _path[_pi].z - global_position.z).length() < 0.15:
		_pi += 1
	if _pi >= _path.size():
		ch.move_speed = 0.0
		return true
	var to := _path[_pi] - global_position
	to.y = 0
	var spd := _speed()
	if to.length() > 0.001:
		global_position += to.normalized() * minf(to.length(), spd * dt)
		ch.face(to, dt, 10.0)
	global_position.y = 0.0
	ch.move_speed = clampf(spd / 4.0, 0.5, 1.0)
	ch.work = "push" if role == "porter" else ""
	return false


func _walk_point(target: Vector3, dt: float) -> bool:
	if _goal.distance_to(target) > 0.3:
		_goal = target
		_path = world.road_path_to_point(global_position, target)
		_pi = 0
	return _follow(dt)


func _rest(dt: float) -> void:
	_timer -= dt
	if role == "porter" and _timer <= 0.0:
		_timer = 1.0
		if carry.count() > 0 or not world.find_job(global_position, carry.space()).is_empty():
			state = S.DECIDE
			return
	var seat := world.rest_seat(self)
	var to := seat - global_position
	to.y = 0
	if to.length() > 0.15:
		ch.work = ""
		_walk_point(seat, dt)
	else:
		ch.move_speed = 0.0
		ch.work = "sit" if world.rest_sits(self) else ""
		ch.face(world.rest_face(self), dt, 4.0)


## Chefs stand in front of their machine and work it.
func _station(dt: float) -> void:
	var b: Building = world.building(int(data.get("target", 0)))
	if b == null:
		state = S.REST
		return
	var spot := b.to_world(-0.3 + fmod(float(data["id"]) * 0.7, 1.2), 0.45)
	if b is BakeryB:
		spot = b.to_world(BakeryB.OVEN_X - 1.2 + fmod(float(data["id"]) * 0.7, 1.4), 0.4)
	var to := spot - global_position
	to.y = 0
	if to.length() > 0.15:
		_walk_point(spot, dt)
	else:
		ch.move_speed = 0.0
		ch.work = "scoop"
		ch.face(b.inward(), dt, 5.0)
