class_name CameraRig
extends Node3D
## A free camera over your empire, like a base builder: drag to pan (with a
## little glide when you let go), pinch or the mouse wheel to zoom, fixed
## angle so the layout always reads the same. It stays over your land.
## fly_to() glides to a building (tutorial pointers, selections).

var world: World
var cam: Camera3D
var zoom := 1.0                 # 0.55 (close) .. 2.2 (far)
var pitch := 58.0
var base_dist := 22.0
var shake := 0.0
var free_focus := false         # someone else drives global_position (title menu)
var velocity := Vector3.ZERO
var dragging := false
var _fly: Tween

const ZOOM_MIN := 0.5
const ZOOM_MAX := 2.2


func _ready() -> void:
	cam = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 40.0
	cam.near = 0.5
	cam.far = 260.0
	add_child(cam)
	cam.current = true


func snap() -> void:
	_place()


## Pans by a ground-space offset (from drag input).
func pan(delta: Vector3) -> void:
	_stop_fly()
	global_position += Vector3(delta.x, 0, delta.z)
	_clamp()


func release(vel: Vector3) -> void:
	velocity = Vector3(vel.x, 0, vel.z).limit_length(40.0)


func zoom_by(f: float) -> void:
	zoom = clampf(zoom * f, ZOOM_MIN, ZOOM_MAX)


## Glides to a point (and zoom) over ~0.6 s.
func fly_to(p: Vector3, z := -1.0, dur := 0.6) -> void:
	_stop_fly()
	velocity = Vector3.ZERO
	_fly = create_tween().set_parallel(true)
	_fly.tween_property(self, "global_position", Vector3(p.x, 0, p.z), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if z > 0.0:
		_fly.tween_property(self, "zoom", clampf(z, ZOOM_MIN, ZOOM_MAX), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)


func _stop_fly() -> void:
	if _fly and _fly.is_valid():
		_fly.kill()
	_fly = null


func _process(dt: float) -> void:
	if not free_focus and not dragging and velocity.length() > 0.05:
		global_position += velocity * dt
		velocity = velocity.lerp(Vector3.ZERO, clampf(dt * 4.5, 0.0, 1.0))
		_clamp()
	shake = move_toward(shake, 0.0, dt * 2.0)
	_place()


func _clamp() -> void:
	if world == null or free_focus:
		return
	var b := world._owned_bounds()
	if b.size == Vector2i.ZERO:
		return
	var m := 10.0
	var lo := Vector2(b.position) * Grid.CELL - Vector2(m, m)
	var hi := Vector2(b.end) * Grid.CELL + Vector2(m, m)
	global_position.x = clampf(global_position.x, lo.x, hi.x)
	global_position.z = clampf(global_position.z, lo.y, hi.y)


func _place() -> void:
	var d := base_dist * zoom
	var a := deg_to_rad(pitch)
	cam.position = Vector3(0, sin(a) * d, cos(a) * d)
	if shake > 0.0:
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.15
	cam.rotation = Vector3(-a, 0, 0)


## The point on the ground under a screen position.
func ground_at(sp: Vector2) -> Vector3:
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 0.001:
		return o
	return o + d * (-o.y / d.y)
