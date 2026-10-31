class_name Fly
extends Control
## Rewards you can watch land: coins (or sparks) burst out where you
## collected them, hang for a beat, then swoop in an arc into their counter
## at the top of the screen. Each one that lands ticks, pitched a little
## higher every time, and bumps the counter; the last one calls back (the
## money is paid as it arrives, so the number rolls up with the coins).

const MAX_LIVE := 60

var _live := 0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## from: screen position; to: the counter to fly into; icon: "coin" / "gem".
func fly(from: Vector2, to: Control, icon := "coin", n := 10, on_done := Callable()) -> void:
	n = clampi(n, 1, maxi(1, MAX_LIVE - _live))
	if to == null or not is_instance_valid(to) or not to.is_visible_in_tree():
		if on_done.is_valid():
			on_done.call()
		return
	var target := to.get_global_rect()
	var dest := Vector2(target.position.x + minf(target.size.y, target.size.x) * 0.5, target.get_center().y)
	var tex := Icons.tex(icon)
	for i in n:
		var c := TextureRect.new()
		c.texture = tex
		c.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		c.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var s := randf_range(44.0, 58.0)
		c.size = Vector2(s, s)
		c.pivot_offset = c.size * 0.5
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.position = from - c.size * 0.5
		c.scale = Vector2(0.2, 0.2)
		add_child(c)
		_live += 1
		# burst out in a ring, then swoop to the counter along a curve
		var a := randf() * TAU
		var spread := from + Vector2(cos(a), sin(a) * 0.7) * randf_range(40.0, 110.0) - Vector2(0, 30)
		var ctrl := Vector2(lerpf(spread.x, dest.x, 0.25) + randf_range(-120, 120), minf(spread.y, dest.y) - randf_range(40, 160))
		var delay := 0.04 * i
		var flight := randf_range(0.55, 0.75)
		var last := i == n - 1
		var tw := c.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(c, "position", spread - c.size * 0.5, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(c, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_interval(0.12 + randf() * 0.1)
		tw.tween_method(func(f: float):
			var p := spread.lerp(ctrl, f).lerp(ctrl.lerp(dest, f), f)
			c.position = p - c.size * 0.5
			c.scale = Vector2.ONE * lerpf(1.0, 0.55, f)
			c.rotation = f * 1.5, 0.0, 1.0, flight).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			_live -= 1
			c.queue_free()
			Kit.bounce(to, 0.07)
			Sfx.play("coin" if icon == "coin" else "pop", -6.0, 1.0 + 0.04 * i, 0.0)
			if last and on_done.is_valid():
				on_done.call())
