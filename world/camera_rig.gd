class_name CameraRig
extends Node3D
## Follows the player from above and behind at a fixed angle (no rotation, so
## the layout always reads the same). Pinch or mouse wheel zooms.

var target: Node3D
var cam: Camera3D
var zoom := 1.0                 # 0.6 (close) .. 1.6 (far)
var pitch := 62.0
var base_dist := 15.5
var lead := Vector3.ZERO
var shake := 0.0
var free_focus := false        # the title menu drives global_position itself
var _touches := {}
var _pinch_d := 0.0


func _ready() -> void:
	cam = Camera3D.new()
	cam.keep_aspect = Camera3D.KEEP_WIDTH
	cam.fov = 44.0
	cam.near = 0.5
	cam.far = 200.0
	add_child(cam)
	cam.current = true


## Launch swoop: start high over the island and glide down to the player.
func intro() -> void:
	zoom = 2.3
	pitch = 70.0
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "zoom", 1.0, 2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.3)
	tw.tween_property(self, "pitch", 62.0, 2.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT).set_delay(0.3)


func snap() -> void:
	if target:
		global_position = _focus()
	_place()


func _focus() -> Vector3:
	return target.global_position + Vector3(0, 0, 1.0)


func _process(dt: float) -> void:
	if target == null:
		return
	if not free_focus:
		var f := _focus()
		global_position = global_position.lerp(f, clampf(dt * 3.0 if zoom > 1.05 else dt * 5.0, 0.0, 1.0))
	shake = move_toward(shake, 0.0, dt * 2.0)
	_place()


func _place() -> void:
	var d := base_dist * zoom
	var a := deg_to_rad(pitch)
	cam.position = Vector3(0, sin(a) * d, cos(a) * d)
	if shake > 0.0:
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake * 0.15
	cam.rotation = Vector3(-a, 0, 0)


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom = clampf(zoom - 0.08, 0.6, 1.6)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom = clampf(zoom + 0.08, 0.6, 1.6)
	elif e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
		_pinch_d = 0.0
	elif e is InputEventScreenDrag and _touches.has(e.index):
		_touches[e.index] = e.position
		if _touches.size() == 2:
			var ps: Array = _touches.values()
			var d: float = (ps[0] as Vector2).distance_to(ps[1])
			if _pinch_d > 0.0:
				zoom = clampf(zoom * _pinch_d / d, 0.6, 1.6)
			_pinch_d = d
	elif e is InputEventMagnifyGesture:
		zoom = clampf(zoom / e.factor, 0.6, 1.6)
