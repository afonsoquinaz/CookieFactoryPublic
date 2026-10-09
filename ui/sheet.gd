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


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_dim = ColorRect.new()
	_dim.color = Color(0.06, 0.05, 0.04, 0.0)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_dim.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			close())
	add_child(_dim)
	panel = PanelContainer.new()
	var st := Kit.card(30)
	st.corner_radius_bottom_left = 0
	st.corner_radius_bottom_right = 0
	st.content_margin_bottom = 30
	panel.add_theme_stylebox_override("panel", st)
	panel.anchor_left = 0.0
	panel.anchor_right = 1.0
	panel.anchor_top = 1.0 - height_frac
	panel.anchor_bottom = 1.0
	panel.offset_left = 10
	panel.offset_right = -10
	panel.offset_bottom = 20
	add_child(panel)
	var v := Kit.vbox(12)
	panel.add_child(v)
	var head := Kit.hbox(12)
	v.add_child(head)
	if title_icon != "":
		head.add_child(Kit.icon(title_icon, 48))
	var tl := Kit.title(title, 40, Kit.INK)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(tl)
	var x := Kit.juicy("", Kit.PAPER_DARK, Kit.LINE, 22, Vector2(56, 56))
	x.set_glyph("close", 30)
	x.sound = "close"
	x.pressed.connect(close)
	head.add_child(x)
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
	tw.tween_property(_dim, "color:a", 0.3, 0.25)
	tw.tween_property(panel, "offset_top", 0.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(panel, "offset_bottom", 20.0, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Sfx.play("open")


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
static func row_box(face := Color(1, 1, 1, 0.7), rim := Kit.LINE) -> PanelContainer:
	var p := PanelContainer.new()
	var st := Kit.box(face, 18, 1, rim, 0)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 10
	st.content_margin_bottom = 12
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_PASS
	return p
