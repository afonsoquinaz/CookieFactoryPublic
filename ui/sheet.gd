class_name Sheet
extends Control
## A bottom sheet panel: dims the world, slides up, has a title row with an
## icon and a close button, and a scrolling body. Subclasses fill `body`.

signal closed

var title := ""
var title_icon := ""
var body: VBoxContainer
var panel: PanelContainer
var scroll: ScrollContainer
var height_frac := 0.62
var _dim: ColorRect
var _closing := false
var _ribbon: Control
var _close: Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.08, 0.05, 0.03, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			close())
	add_child(_dim)
	panel = PanelContainer.new()
	panel.add_theme_stylebox_override("panel", Kit.skin("panel", 60, Vector4(34, 62, 34, 34)))
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0 - height_frac
	panel.anchor_bottom = 1.0
	panel.offset_left = 8
	panel.offset_right = -8
	panel.offset_bottom = 20
	add_child(panel)
	var v := Kit.vbox(12)
	panel.add_child(v)
	# ribbon banner with the title, riding over the top edge of the frame
	var ribbon := PanelContainer.new()
	ribbon.add_theme_stylebox_override("panel", Kit.skin("ribbon", 70, Vector4(96, 12, 96, 30)))
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(ribbon)
	var rh := Kit.hbox(10)
	rh.alignment = BoxContainer.ALIGNMENT_CENTER
	ribbon.add_child(rh)
	if title_icon != "":
		rh.add_child(Kit.icon(title_icon, 46))
	rh.add_child(Kit.game(title, 38, Kit.WHITE, 8))
	ribbon.top_level = false
	_ribbon = ribbon
	var x := Kit.juicy("", Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, 22, Vector2(70, 70))
	x.set_glyph("close", 34)
	x.sound = "close"
	x.pressed.connect(close)
	add_child(x)
	_close = x
	_header(v)
	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.scroll_deadzone = 12
	v.add_child(scroll)
	body = Kit.vbox(12)
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.mouse_filter = Control.MOUSE_FILTER_PASS
	scroll.add_child(body)
	_build()
	# slide up
	panel.offset_top = 1000
	panel.offset_bottom = 1020
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.45, 0.25)
	tw.tween_property(panel, "offset_top", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "offset_bottom", 20.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("open")


func _process(_dt: float) -> void:
	# ribbon and close button float over the frame's top edge
	if _ribbon:
		var rs := _ribbon.get_combined_minimum_size()
		_ribbon.size = Vector2(minf(panel.size.x - 60, maxf(rs.x, 360)), rs.y)
		_ribbon.position = panel.position + Vector2((panel.size.x - _ribbon.size.x) * 0.5, -rs.y * 0.5)
	if _close:
		_close.size = _close.custom_minimum_size
		_close.position = panel.position + Vector2(panel.size.x - _close.size.x - 10, -24)


## Extra fixed content under the title (tabs etc.).
func _header(_v: VBoxContainer) -> void:
	pass


func _build() -> void:
	pass


func close() -> void:
	if _closing:
		return
	_closing = true
	Sfx.play("close")
	var tw := create_tween().set_parallel(true)
	tw.tween_property(_dim, "color:a", 0.0, 0.2)
	tw.tween_property(panel, "offset_top", 1000.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(panel, "offset_bottom", 1020.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(func():
		closed.emit()
		queue_free())


## A rounded row container used by list items.
static func row_box(_face := Color(1, 1, 1, 0.7), _rim := Kit.LINE) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Kit.skin("card", 30, Vector4(16, 12, 16, 18)))
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p
