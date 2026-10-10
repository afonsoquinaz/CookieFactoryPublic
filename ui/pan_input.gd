class_name PanInput
extends Control
## Touch input over the world: drag with one finger to slide the land, pinch
## to zoom (mouse wheel on desktop), tap to pick a building, an obstacle or a
## For Sale sign. A quick touch that barely moves is a tap.

signal tapped(pos: Vector2)

const TAP_MOVE := 16.0
const TAP_TIME := 0.4

var world: World
var _touches := {}
var _pinch := 0.0
var _down_t := 0.0
var _moved := 0.0
var _last_drag_t := 0.0
var _vel := Vector3.ZERO


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(e: InputEvent) -> void:
	var cam := world.cam
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
			if _touches.size() == 1:
				_down_t = Time.get_ticks_msec() / 1000.0
				_moved = 0.0
				_vel = Vector3.ZERO
				cam.velocity = Vector3.ZERO
				cam.dragging = true
		else:
			var was_single := _touches.size() == 1
			_touches.erase(e.index)
			if _touches.is_empty():
				cam.dragging = false
				var quick := Time.get_ticks_msec() / 1000.0 - _down_t < TAP_TIME
				if was_single and quick and _moved < TAP_MOVE:
					tapped.emit(e.position)
				elif Time.get_ticks_msec() / 1000.0 - _last_drag_t < 0.08:
					cam.release(_vel)
		_pinch = 0.0
		accept_event()
	elif e is InputEventScreenDrag and _touches.has(e.index):
		var prev: Vector2 = _touches[e.index]
		_touches[e.index] = e.position
		if _touches.size() == 1:
			_moved += (e.position - prev).length()
			if _moved < TAP_MOVE:
				return
			var a := cam.ground_at(prev)
			var b := cam.ground_at(e.position)
			var d := a - b
			cam.pan(d)
			var now := Time.get_ticks_msec() / 1000.0
			var dt := maxf(now - _last_drag_t, 0.008)
			_vel = _vel.lerp(d / dt, 0.4) if now - _last_drag_t < 0.1 else d / dt
			_last_drag_t = now
		elif _touches.size() == 2:
			_moved = TAP_MOVE
			var ps: Array = _touches.values()
			var dd: float = (ps[0] as Vector2).distance_to(ps[1])
			if _pinch > 0.0:
				cam.zoom_by(_pinch / dd)
			_pinch = dd
		accept_event()
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom_by(0.92)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom_by(1.08)
	elif e is InputEventMagnifyGesture:
		cam.zoom_by(1.0 / e.factor)


func _unhandled_key_input(e: InputEvent) -> void:
	# arrow keys / WASD pan on desktop
	if not (e is InputEventKey and e.pressed) or not is_visible_in_tree():
		return
	var d := Vector3.ZERO
	match e.keycode:
		KEY_W, KEY_UP: d.z = -1
		KEY_S, KEY_DOWN: d.z = 1
		KEY_A, KEY_LEFT: d.x = -1
		KEY_D, KEY_RIGHT: d.x = 1
	if d != Vector3.ZERO:
		world.cam.pan(d * 3.0)
