class_name Animal
extends Node3D
## Chickens and cows that wander their pen: hop, peck, swish, bob.

var kind := "chicken"
var bounds := Rect2(-1, -1, 2, 2)
var _target := Vector3.ZERO
var _wait := 0.0
var _t := 0.0
var _body: Node3D
var _head: Node3D
var _tail: Node3D


func _ready() -> void:
	_t = randf() * 10.0
	_body = Node3D.new()
	add_child(_body)
	_head = Node3D.new()
	_body.add_child(_head)
	if kind == "chicken":
		Mats.inst(MeshKit.cached("chicken_body", _chicken_body), _body)
		_head.position = Vector3(0, 0.3, 0.1)
		Mats.inst(MeshKit.cached("chicken_head", _chicken_head), _head)
		scale = Vector3.ONE * randf_range(1.4, 1.6)
	else:
		Mats.inst(MeshKit.cached("cow_body", _cow_body), _body)
		_head.position = Vector3(0, 0.62, 0.45)
		Mats.inst(MeshKit.cached("cow_head", _cow_head), _head)
		_tail = Node3D.new()
		_tail.position = Vector3(0, 0.66, -0.42)
		_body.add_child(_tail)
		var tk := MeshKit.new()
		tk.cyl(0.02, 0.35, Color(1, 1, 1), MeshKit.xf(Vector3.ZERO, Vector3(160, 0, 0)), 6)
		tk.sphere(0.05, Color(0.2, 0.18, 0.2), MeshKit.at(0, -0.34, -0.12), 6, 4)
		Mats.inst(tk.commit(), _tail)
	_pick()


func _pick() -> void:
	_target = Vector3(randf_range(bounds.position.x, bounds.end.x), position.y, randf_range(bounds.position.y, bounds.end.y))
	_wait = randf_range(1.0, 3.5) * (2.5 if kind == "cow" else 1.0)


func animate(dt: float) -> void:
	_t += dt
	var to := _target - position
	to.y = 0
	var spd := 0.7 if kind == "chicken" else 0.25
	if _wait > 0.0:
		_wait -= dt
		# idle: peck / graze
		if kind == "chicken":
			_head.rotation.x = maxf(0.0, sin(_t * 9.0)) * 0.9 if fmod(_t, 3.0) < 1.0 else 0.0
			_body.position.y = 0.0
		else:
			_head.rotation.x = 0.35 + sin(_t * 1.5) * 0.12
			_tail.rotation.z = sin(_t * 2.5) * 0.4
	elif to.length() > 0.1:
		position += to.normalized() * spd * dt
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), dt * 6.0)
		if kind == "chicken":
			_body.position.y = absf(sin(_t * 14.0)) * 0.06
		else:
			_body.position.y = absf(sin(_t * 5.0)) * 0.02
			_head.rotation.x = sin(_t * 5.0) * 0.08
	else:
		_pick()


func _chicken_body() -> Mesh:
	var k := MeshKit.new()
	k.ellipsoid(Vector3(0.17, 0.16, 0.2), Color(1, 1, 0.98), MeshKit.at(0, 0.2, 0), 12, 8)
	k.ellipsoid(Vector3(0.06, 0.1, 0.07), Color(0.95, 0.95, 0.92), MeshKit.xf(Vector3(0, 0.3, -0.18), Vector3(-30, 0, 0)), 8, 5)
	for sx in [-1.0, 1.0]:
		k.ellipsoid(Vector3(0.04, 0.09, 0.13), Color(0.94, 0.94, 0.9), MeshKit.at(sx * 0.16, 0.21, -0.01), 8, 5)
		k.cyl(0.015, 0.08, Pal.ORANGE, MeshKit.at(sx * 0.06, 0.0, 0.0), 5)
	return k.commit()


func _chicken_head() -> Mesh:
	var k := MeshKit.new()
	k.sphere(0.1, Color(1, 1, 0.98), MeshKit.at(0, 0.03, 0.03), 10, 7)
	k.cone(0.035, 0.07, Pal.ORANGE, MeshKit.xf(Vector3(0, 0.02, 0.12), Vector3(90, 0, 0)), 6)
	for i in 3:
		k.sphere(0.03, Pal.RED, MeshKit.at(0, 0.13, -0.02 + i * 0.03), 6, 4)
	k.ellipsoid(Vector3(0.02, 0.035, 0.02), Pal.RED, MeshKit.at(0, -0.04, 0.1), 6, 4)
	for sx in [-1.0, 1.0]:
		k.sphere(0.017, Color(0.1, 0.08, 0.08), MeshKit.at(sx * 0.07, 0.05, 0.07), 6, 4)
	return k.commit()


func _cow_body() -> Mesh:
	var k := MeshKit.new()
	var white := Color(0.99, 0.98, 0.96)
	var spot := Color(0.2, 0.18, 0.22)
	k.rbox(Vector3(0.55, 0.42, 0.85), 0.2, white, MeshKit.at(0, 0.55, 0))
	k.ellipsoid(Vector3(0.2, 0.14, 0.2), spot, MeshKit.at(0.2, 0.66, 0.1), 10, 6)
	k.ellipsoid(Vector3(0.16, 0.12, 0.18), spot, MeshKit.at(-0.22, 0.52, -0.2), 10, 6)
	k.ellipsoid(Vector3(0.12, 0.08, 0.12), spot, MeshKit.at(0.05, 0.77, -0.25), 10, 6)
	k.ellipsoid(Vector3(0.1, 0.07, 0.1), Pal.PINK, MeshKit.at(0, 0.33, -0.15), 8, 5)
	for sx in [-0.17, 0.17]:
		for sz in [-0.27, 0.27]:
			k.cyl(0.075, 0.38, white, MeshKit.at(sx, 0.0, sz), 8, 0.03)
			k.cyl(0.08, 0.08, Color(0.35, 0.25, 0.22), MeshKit.at(sx, 0.0, sz), 8, 0.03)
	return k.commit()


func _cow_head() -> Mesh:
	var k := MeshKit.new()
	var white := Color(0.99, 0.98, 0.96)
	k.ellipsoid(Vector3(0.22, 0.21, 0.2), white, MeshKit.at(0, 0.05, 0.08), 12, 8)
	k.ellipsoid(Vector3(0.18, 0.12, 0.1), Color(1.0, 0.7, 0.72), MeshKit.at(0, -0.04, 0.24), 12, 7)
	for sx in [-1.0, 1.0]:
		k.sphere(0.022, Color(0.55, 0.3, 0.32), MeshKit.at(sx * 0.07, -0.03, 0.335), 6, 4)
		k.sphere(0.03, Color(0.1, 0.08, 0.08), MeshKit.at(sx * 0.1, 0.12, 0.23), 8, 5)
		k.ellipsoid(Vector3(0.1, 0.04, 0.06), white, MeshKit.xf(Vector3(sx * 0.24, 0.12, 0.04), Vector3(0, 0, sx * -20)), 8, 4)
		k.cone(0.035, 0.11, Color(1.0, 0.92, 0.7), MeshKit.xf(Vector3(sx * 0.12, 0.22, 0.02), Vector3(0, 0, -sx * 25)), 6)
	k.ellipsoid(Vector3(0.1, 0.07, 0.04), Color(0.2, 0.18, 0.22), MeshKit.at(0.08, 0.18, 0.18), 8, 4)
	return k.commit()
