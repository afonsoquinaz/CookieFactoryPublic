class_name Customer
extends Node3D
## A Chat Café visitor: strolls in from the countryside, takes a seat, chats
## with your model on their phone for a while (the café's demand, served by
## your servers), and strolls off happy. If nobody answers, they get bored
## and leave early; with no seat free, they wander off.

enum S { IN, CHAT, LEAVE }

var shop: CafeB
var spawn := Vector3.ZERO
var ch: Character
var state := S.IN
var seat := -1
var _path := PackedVector3Array()
var _pi := 0
var _chat := 0.0
var _bored := 0.0
var _speed := 2.4
var _bubble: Label3D
var _phone: MeshInstance3D


func _ready() -> void:
	ch = Character.new()
	add_child(ch)
	ch.setup("customer", randi() % 10000)
	ch.scale = Vector3.ONE * randf_range(0.85, 0.98)
	_bubble = UI3D.label("", 40)
	_bubble.position = Vector3(0, 2.0, 0)
	add_child(_bubble)
	_speed = randf_range(2.0, 2.8)
	seat = shop.take_seat(self)
	if seat < 0:
		state = S.LEAVE
		_route_to(spawn + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)))
	else:
		_route_to(shop.seat_point(seat))


func _route_to(p: Vector3) -> void:
	_path = shop.world.grid.path(global_position, p)
	_pi = 0


func _process(dt: float) -> void:
	if not is_instance_valid(shop):
		queue_free()
		return
	match state:
		S.IN:
			if _walk(dt):
				state = S.CHAT
				_chat = randf_range(16.0, 32.0)
				_phone_on(true)
		S.CHAT:
			ch.move_speed = 0.0
			ch.work = "sit"
			ch.face(shop.global_transform.basis.z * -1.0, dt, 6.0)
			if shop.answered():
				_chat -= dt
				_bored = 0.0
				_bubble.text = ["", ".", "..", "..."][int(Time.get_ticks_msec() / 400) % 4]
			else:
				_bored += dt
				_bubble.text = "zzz"
			if _chat <= 0.0:
				shop.chat_done(self)
				_leave()
			elif _bored > 8.0:
				_leave()
		S.LEAVE:
			if _walk(dt):
				queue_free()


func _leave() -> void:
	_phone_on(false)
	_bubble.text = ""
	ch.work = ""
	if seat >= 0:
		shop.leave_seat(seat)
		seat = -1
	state = S.LEAVE
	_route_to(spawn)


func _phone_on(on: bool) -> void:
	if on and _phone == null:
		_phone = Mats.inst(MeshKit.cached("phone", func():
			var k := MeshKit.new()
			k.rbox(Vector3(0.1, 0.17, 0.02), 0.02, Color(0.14, 0.15, 0.18), Transform3D.IDENTITY)
			k.rbox(Vector3(0.08, 0.14, 0.01), 0.01, Color(0.5, 0.86, 1.0, 0.4), MeshKit.at(0, 0, 0.012))
			return k.commit()), ch.carry_mount, MeshKit.xf(Vector3(0, 0.55, 0.05), Vector3(-30, 0, 0)), false)
	elif not on and _phone:
		_phone.queue_free()
		_phone = null


func _walk(dt: float) -> bool:
	while _pi < _path.size() and Vector2(_path[_pi].x - global_position.x, _path[_pi].z - global_position.z).length() < 0.25:
		_pi += 1
	if _pi >= _path.size():
		ch.move_speed = 0.0
		return true
	var to := _path[_pi] - global_position
	to.y = 0
	var step := minf(to.length(), _speed * dt)
	global_position += to.normalized() * step
	ch.face(to, dt, 8.0)
	ch.move_speed = 0.7
	return false
