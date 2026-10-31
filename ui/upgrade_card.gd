class_name UpgradeCard
extends Control
## The quick upgrade confirm: the building's picture in a glow, "Level 3 ->
## 4", a bar per stat showing what you have and (in green) what you gain,
## what the next level adds, how long it takes, and one big price button.
## The full details stay in Info.

signal done(started: bool)

var hud
var node: Building
var _card: PanelContainer
var _btn: JuicyButton
var _rays: Rays


func setup(p_hud, n: Building) -> UpgradeCard:
	hud = p_hud
	node = n
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.05, 0.04, 0.5)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and not e.pressed:
			close(false))
	add_child(dim)
	_rays = Rays.new()
	_rays.size = Vector2(620, 620)
	_rays.count = 12
	_rays.alpha = 0.12
	_rays.color = Color(1.0, 0.92, 0.6)
	add_child(_rays)
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", Kit.skin("panel", 60, Vector4(34, 30, 34, 34)))
	_card.custom_minimum_size = Vector2(minf(520, get_viewport_rect().size.x - 40), 0)
	add_child(_card)
	var v := Kit.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	_card.add_child(v)
	var l := node.level
	var ic := Kit.icon(node.def["icon"], 132)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var name_l := Kit.game(node.def["name"], 36, Kit.INK, 0)
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(name_l)
	# Level 3 -> 4
	var lv := Kit.hbox(14)
	lv.alignment = BoxContainer.ALIGNMENT_CENTER
	lv.add_child(_level_badge(l, Kit.CHARCOAL))
	lv.add_child(Kit.glyph("arrow", 34, Kit.MUTED))
	lv.add_child(_level_badge(l + 1, Kit.SAGE))
	v.add_child(lv)
	# a bar per stat: now (dark) and the gain (green)
	var stats := Kit.vbox(8)
	for r in node.upgrade_info():
		stats.add_child(_stat_row(str(r[0]), str(r[1]), str(r[2])))
	v.add_child(stats)
	# what's new, how long
	var nt := Bal.next_tier_level(node.kind, l)
	var news := ""
	if nt == l + 1:
		news = "A whole new look!"
	elif Growth.next_desc(node.kind, l) != "":
		news = Growth.next_desc(node.kind, l)
	if news != "":
		var nl := Kit.game(news, 20, Kit.TERRACOTTA_EDGE, 0)
		nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(nl)
	var t := Bal.upgrade_time(node.kind, l)
	var info := Kit.hbox(8)
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.add_child(Kit.icon("clock", 30))
	info.add_child(Kit.game(Fmt.time(t) if t > 0.0 else "Instant", 22, Kit.INK, 0))
	info.add_child(Kit.spacer(16, 0))
	info.add_child(Kit.icon("builder", 30))
	info.add_child(Kit.game("%d / %d free" % [Game.free_builders(), Game.builders()], 22, Kit.INK, 0))
	v.add_child(info)
	v.add_child(Kit.spacer(0, 4))
	var cost := Bal.upgrade_cost(node.kind, l)
	var ok := Game.upgrade_block(node.uid) == ""
	_btn = Kit.juicy("  %s" % Fmt.num(cost), Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE, 34, Vector2(300, 96))
	_btn.set_icon("coin", 40)
	_btn.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_btn.pressed.connect(_go)
	v.add_child(_btn)
	if not ok:
		var why := Kit.label(Game.upgrade_block(node.uid), 17, Kit.TERRACOTTA_EDGE, 0)
		why.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		v.add_child(why)
	_center.call_deferred()
	_card.minimum_size_changed.connect(_center)
	Kit.pop_in.call_deferred(_card)
	Sfx.play("open", -6.0)


func _center() -> void:
	_card.size = _card.get_combined_minimum_size()
	_card.position = (get_viewport_rect().size - _card.size) * 0.5
	_card.pivot_offset = _card.size * 0.5
	_rays.position = _card.position + Vector2(_card.size.x * 0.5, 100) - _rays.size * 0.5


func _level_badge(l: int, col: Color) -> Control:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(18)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", sb)
	var t := Kit.game("Lv %d" % l, 30, Kit.WHITE, 6)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	p.add_child(t)
	return p


static func _num(s: String) -> float:
	var r := RegEx.create_from_string("-?[0-9]+(\\.[0-9]+)?")
	var m := r.search(s.replace(",", ""))
	return float(m.get_string()) if m else NAN


func _stat_row(label: String, now: String, next: String) -> Control:
	var box := Kit.vbox(2)
	var top := Kit.hbox(6)
	var a := Kit.game(label, 19, Kit.INK, 0)
	a.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(a)
	top.add_child(Kit.game(now, 19, Kit.MUTED, 0))
	top.add_child(Kit.glyph("arrow", 16, Kit.MUTED))
	top.add_child(Kit.game(next, 19, Color(0.3, 0.6, 0.24), 0))
	box.add_child(top)
	var n0 := _num(now)
	var n1 := _num(next)
	if not is_nan(n0) and not is_nan(n1) and n1 > 0.0:
		var bar := _Bar.new()
		bar.now = clampf(n0 / n1, 0.0, 1.0) if n1 >= n0 else 1.0
		bar.custom_minimum_size = Vector2(0, 16)
		box.add_child(bar)
	return box


func _go() -> void:
	var why := Game.upgrade_block(node.uid)
	if why != "":
		Sfx.play("deny")
		Kit.shake(_btn)
		Game.toast.emit(why, "hammer" if why.contains("builder") else "coin")
		return
	if Game.upgrade(node.uid):
		Sfx.play("build", -2.0)
		node.bump(0.12)
		Fx.puff(get_tree().current_scene, node.global_position + Vector3(0, 0.4, 0), Pal.CREAM, 12)
		close(true)


func close(started: bool) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	tw.tween_callback(func():
		done.emit(started)
		queue_free())


## A rounded bar: what you have (dark) and the gain to the next level
## (green, gently pulsing).
class _Bar extends Control:
	var now := 0.5
	var _t := 0.0

	func _process(dt: float) -> void:
		_t += dt
		queue_redraw()

	func _draw() -> void:
		var r := Rect2(Vector2.ZERO, size)
		draw_rect(r, Color(0.86, 0.84, 0.8), true)
		var g := 0.75 + 0.25 * sin(_t * 4.0)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, size.y)), Color(0.42 * g, 0.78 * g, 0.36 * g), true)
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * now, size.y)), Color(0.3, 0.32, 0.36), true)
