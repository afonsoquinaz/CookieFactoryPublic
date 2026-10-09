class_name LevelRing
extends Control
## Empire level: a dark glass disc with a brass progress ring and the level
## number in serif.

var level := 1
var target := 0.0
var _shown := 0.0


func _process(dt: float) -> void:
	_shown = move_toward(_shown, target, dt * 1.5) if target >= _shown else target
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.5
	draw_circle(c, r, Kit.GLASS)
	draw_arc(c, r - 5, 0, TAU, 64, Color(1, 1, 1, 0.12), 4.0, true)
	if _shown > 0.001:
		draw_arc(c, r - 5, -PI * 0.5, -PI * 0.5 + TAU * clampf(_shown, 0.0, 1.0), 64, Kit.BRASS, 4.5, true)
	var f := Kit.SERIF
	var s := str(level)
	var fs := 30
	var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(f, Vector2(c.x - w * 0.5, c.y + fs * 0.36), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Kit.WHITE)
