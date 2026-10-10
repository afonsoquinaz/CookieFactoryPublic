class_name Customer
extends Node3D
## A shop customer: strolls in from the countryside, waits at the counter,
## buys a few cookies (they fly into their hands), pays and strolls off.

enum S { IN, WAIT, LEAVE }

var shop: ShopB
var spawn := Vector3.ZERO
var ch: Character
var carry: Holder
var state := S.IN
var _path := PackedVector3Array()
var _pi := 0
var _wait := 0.0
var _speed := 2.4
var _bubble: Label3D


func _ready() -> void:
	ch = Character.new()
	add_child(ch)
	ch.setup("customer", randi() % 10000)
	ch.scale = Vector3.ONE * randf_range(0.85, 0.98)
	carry = Holder.new().setup(12, [], Holder.Layout.COLUMN)
	ch.carry_mount.add_child(carry)
	_bubble = UI3D.label("", 40)
	_bubble.position = Vector3(0, 2.0, 0)
	add_child(_bubble)
	_speed = randf_range(2.0, 2.8)
	_route_to(shop.counter_point())


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
				state = S.WAIT
				_wait = 0.0
		S.WAIT:
			ch.move_speed = 0.0
			ch.face(shop.global_transform.basis.z * -1.0, dt, 6.0)
			_wait += dt
			if shop.serve(self):
				_bubble.text = ""
				state = S.LEAVE
				_route_to(spawn)
			elif _wait > 7.0:
				_bubble.text = "..."
				state = S.LEAVE
				_route_to(spawn)
		S.LEAVE:
			if _walk(dt):
				queue_free()


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
	ch.carrying = carry.count() > 0
	return false
