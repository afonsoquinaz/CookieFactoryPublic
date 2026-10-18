class_name Animal
extends Node3D
## The little machines that bustle around some sources:
##   crawler  a six-legged crawler bot scurrying over the Web Crawler lot,
##            stopping to "read" the ground with its blinking eye
##   drone    a quadcopter that hovers over the solar panels, cleaning them
##   cart     an ore cart trundling around a mine

var kind := "crawler"
var bounds := Rect2(-1, -1, 2, 2)
var _target := Vector3.ZERO
var _wait := 0.0
var _t := 0.0
var _body: Node3D
var _head: Node3D


func _ready() -> void:
	_t = randf() * 10.0
	_body = Node3D.new()
	add_child(_body)
	_head = Node3D.new()
	_body.add_child(_head)
	match kind:
		"drone":
			Mats.inst(MeshKit.cached("bot_drone", _drone), _body, Transform3D.IDENTITY, false)
			position.y = randf_range(0.9, 1.4)
		"cart":
			Mats.inst(MeshKit.cached("bot_cart", _cart), _body)
		_:
			Mats.inst(MeshKit.cached("bot_crawler", _crawler), _body)
			_head.position = Vector3(0, 0.16, 0.1)
			Mats.inst(MeshKit.cached("bot_crawler_eye", func():
				var k := MeshKit.new()
				k.sphere(0.045, Items.lit(Color(0.4, 0.9, 1.0), 0.35), MeshKit.at(0, 0, 0.02), 8, 5)
				return k.commit()), _head, Transform3D.IDENTITY, false)
			scale = Vector3.ONE * randf_range(1.3, 1.5)
	_pick()


func _pick() -> void:
	_target = Vector3(randf_range(bounds.position.x, bounds.end.x), position.y, randf_range(bounds.position.y, bounds.end.y))
	_wait = randf_range(1.0, 3.5) * (2.0 if kind == "cart" else 1.0)


func animate(dt: float) -> void:
	_t += dt
	var to := _target - position
	to.y = 0
	if kind == "drone":
		if to.length() > 0.08:
			position += to.normalized() * 1.2 * dt
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), dt * 4.0)
			_body.rotation.x = 0.15
		else:
			_body.rotation.x = 0.0
			_wait -= dt
			if _wait <= 0.0:
				_pick()
				_target.y = randf_range(0.9, 1.4)
		position.y = lerpf(position.y, _target.y, dt)
		_body.position.y = sin(_t * 3.0) * 0.04
		return
	var spd := 0.8 if kind == "crawler" else 0.3
	if _wait > 0.0:
		_wait -= dt
		if kind == "crawler":
			# reading: the eye dips and blinks
			_head.rotation.x = maxf(0.0, sin(_t * 7.0)) * 0.6 if fmod(_t, 3.0) < 1.2 else 0.0
			_body.position.y = 0.0
	elif to.length() > 0.1:
		position += to.normalized() * spd * dt
		rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), dt * 6.0)
		if kind == "crawler":
			_body.position.y = absf(sin(_t * 18.0)) * 0.025
		else:
			_body.position.y = absf(sin(_t * 9.0)) * 0.008
	else:
		_pick()


func _crawler() -> Mesh:
	var k := MeshKit.new()
	k.ellipsoid(Vector3(0.12, 0.07, 0.15), Color(0.92, 0.93, 0.95), MeshKit.at(0, 0.14, 0), 12, 7)
	k.ellipsoid(Vector3(0.1, 0.03, 0.12), Color(0.36, 0.74, 0.92), MeshKit.at(0, 0.19, -0.01), 10, 5)
	for sx in [-1.0, 1.0]:
		for i in 3:
			var z := -0.08 + i * 0.08
			k.cyl(0.012, 0.16, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(sx * 0.1, 0.14, z), Vector3(0, 0, sx * 120)), 4)
			k.cyl(0.01, 0.14, Color(0.3, 0.32, 0.36), MeshKit.xf(Vector3(sx * 0.23, 0.07, z), Vector3(0, 0, sx * 20)), 4)
	k.cyl(0.006, 0.12, Pal.STEEL_DARK, MeshKit.at(0.04, 0.2, -0.08), 4)
	k.sphere(0.015, Items.lit(Color(1.0, 0.4, 0.4), 0.4), MeshKit.at(0.04, 0.33, -0.08), 5, 3)
	return k.commit()


func _drone() -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.18, 0.07, 0.18), 0.03, Color(0.94, 0.95, 0.96), MeshKit.at(0, 0, 0))
	k.rbox(Vector3(0.06, 0.02, 0.02), 0.008, Items.lit(Color(0.5, 1.0, 0.6), 0.4), MeshKit.at(0, 0, 0.095))
	for i in 4:
		var a := TAU * i / 4.0 + PI * 0.25
		var p := Vector3(cos(a) * 0.17, 0.02, sin(a) * 0.17)
		k.rbox(Vector3(0.18, 0.02, 0.025), 0.008, Color(0.3, 0.32, 0.36), MeshKit.xf(p * 0.5, Vector3(0, -rad_to_deg(a), 0)))
		k.cyl(0.02, 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(p.x, p.y, p.z), 6)
		k.cyl(0.085, 0.006, Color(0.8, 0.84, 0.88, 0.85), MeshKit.at(p.x, p.y + 0.045, p.z), 12)
	k.rbox(Vector3(0.12, 0.02, 0.04), 0.008, Color(0.4, 0.42, 0.46), MeshKit.at(0, -0.06, 0))
	return k.commit()


func _cart() -> Mesh:
	var k := MeshKit.new()
	var body := Color(0.42, 0.44, 0.48)
	k.cyl(0.24, 0.24, body, MeshKit.at(0, 0.12, 0), 4, 0.03, 0.3)
	k.ellipsoid(Vector3(0.2, 0.08, 0.2), Color(0.84, 0.5, 0.3), MeshKit.at(0, 0.38, 0), 8, 4)
	k.ellipsoid(Vector3(0.08, 0.05, 0.08), Color(0.72, 0.46, 0.8), MeshKit.at(0.08, 0.42, 0.06), 6, 3)
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k.cyl(0.06, 0.04, Pal.RUBBER, MeshKit.xf(Vector3(sx * 0.2, 0.06, sz * 0.14), Vector3(0, 0, 90)) * MeshKit.at(0, -0.02, 0), 8)
	return k.commit()
