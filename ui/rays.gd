class_name Rays
extends Control
## Celebration dressing for big moments (a new Lab level, a new model, a new
## era): warm sun rays turning slowly behind the card, and a shower of
## confetti from the top of the screen.

var color := Color(1.0, 0.86, 0.4)
var count := 14
var _t := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _process(dt: float) -> void:
	_t += dt
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := maxf(size.x, size.y) * 0.75
	var grow := clampf(_t / 0.5, 0.0, 1.0)
	for i in count:
		var a0 := _t * 0.35 + TAU * i / count
		var a1 := a0 + TAU / count * 0.45
		var pts := PackedVector2Array([c, c + Vector2(cos(a0), sin(a0)) * r * grow, c + Vector2(cos(a1), sin(a1)) * r * grow])
		var col := Color(color.r, color.g, color.b, 0.22)
		draw_colored_polygon(pts, col)
	# a soft glow in the middle
	for k in 6:
		draw_circle(c, (90.0 - k * 12.0) * grow, Color(1.0, 0.95, 0.75, 0.06))


## A one-shot confetti shower across the top of `parent`.
static func confetti(parent: Control) -> void:
	var w := parent.get_viewport_rect().size.x
	for side in [0.2, 0.5, 0.8]:
		var p := CPUParticles2D.new()
		p.position = Vector2(w * side, -10)
		p.amount = 40
		p.one_shot = true
		p.explosiveness = 0.85
		p.lifetime = 2.6
		p.direction = Vector2(0, 1)
		p.spread = 55.0
		p.initial_velocity_min = 220.0
		p.initial_velocity_max = 520.0
		p.gravity = Vector2(0, 420)
		p.angular_velocity_min = -360.0
		p.angular_velocity_max = 360.0
		p.scale_amount_min = 6.0
		p.scale_amount_max = 12.0
		p.damping_min = 20.0
		p.damping_max = 60.0
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
		g.colors = PackedColorArray([Color(1.0, 0.8, 0.3), Color(0.4, 0.85, 1.0), Color(1.0, 0.45, 0.5), Color(0.5, 0.9, 0.5), Color(0.85, 0.6, 1.0)])
		p.color_initial_ramp = g
		parent.add_child(p)
		p.emitting = true
		parent.get_tree().create_timer(3.2).timeout.connect(p.queue_free)
