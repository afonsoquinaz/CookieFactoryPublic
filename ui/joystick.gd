class_name Joystick
extends Control
## Floating joystick: touch anywhere (that isn't a button) and drag. The base
## appears under your thumb; the knob follows within its radius.

const RADIUS := 110.0

var _active := false
var _index := -1
var _origin := Vector2.ZERO
var _knob := Vector2.ZERO
var _fade := 0.0


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP


func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed and not _active:
			_active = true
			_index = e.index
			_origin = e.position
			_knob = e.position
			accept_event()
		elif not e.pressed and e.index == _index:
			_release()
	elif e is InputEventScreenDrag and _active and e.index == _index:
		var d: Vector2 = e.position - _origin
		if d.length() > RADIUS:
			# drag the base along so direction changes stay responsive
			_origin += d.normalized() * (d.length() - RADIUS)
			d = d.normalized() * RADIUS
		_knob = _origin + d
		Player.joy = d / RADIUS
		accept_event()


func _release() -> void:
	_active = false
	_index = -1
	Player.joy = Vector2.ZERO


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree():
		_release()


func _process(dt: float) -> void:
	_fade = move_toward(_fade, 1.0 if _active else 0.0, dt * 8.0)
	if _fade > 0.0 or _active:
		queue_redraw()


func _draw() -> void:
	if _fade <= 0.001:
		return
	var a := _fade
	draw_circle(_origin, RADIUS + 14, Color(1, 1, 1, 0.16 * a))
	draw_arc(_origin, RADIUS + 14, 0, TAU, 64, Color(1, 1, 1, 0.55 * a), 5.0, true)
	draw_circle(_knob + Vector2(0, 6), 52, Color(0.2, 0.1, 0.05, 0.25 * a))
	draw_circle(_knob, 52, Color(1.0, 0.97, 0.92, 0.95 * a))
	draw_circle(_knob, 40, Color(1.0, 0.62, 0.72, 0.95 * a))
	draw_circle(_knob + Vector2(-12, -14), 12, Color(1, 1, 1, 0.5 * a))
