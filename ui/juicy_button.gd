class_name JuicyButton
extends Button
## Chunky candy button: coloured face with a darker bottom lip, squashes when
## pressed, springs back, clicks. Optional icon left of the text.

var face := Kit.YELLOW
var edge := Kit.YELLOW_EDGE
var row: HBoxContainer
var text_label: Label
var icon_rect: TextureRect
var sound := "click"
var _tw: Tween


func setup(t: String, f: Color, e: Color, font_size := 30, min_size := Vector2(120, 64)) -> void:
	face = f
	edge = e
	custom_minimum_size = min_size
	focus_mode = Control.FOCUS_NONE
	row = Kit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -6
	add_child(row)
	text_label = Kit.label(t, font_size, Kit.WHITE, 8)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if t != "":
		row.add_child(text_label)
	_restyle()
	button_down.connect(_down)
	button_up.connect(_up)
	resized.connect(func(): pivot_offset = size * 0.5)


func set_icon(name: String, s := 40.0) -> void:
	if icon_rect == null:
		icon_rect = Kit.icon(name, s)
		row.add_child(icon_rect)
		row.move_child(icon_rect, 0)
	icon_rect.texture = Icons.tex(name)
	icon_rect.custom_minimum_size = Vector2(s, s)


func set_text_value(t: String) -> void:
	text_label.text = t
	if text_label.get_parent() == null:
		row.add_child(text_label)


func set_colors(f: Color, e: Color) -> void:
	if f == face and e == edge:
		return
	face = f
	edge = e
	_restyle()


func _restyle() -> void:
	var r := int(minf(custom_minimum_size.y * 0.34, 24.0))
	var n := Kit.box(face, r, 0, Color.TRANSPARENT, 4)
	n.border_width_bottom = 7
	n.border_color = edge
	n.content_margin_bottom = 7
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = face.lightened(0.08)
	var p := n.duplicate() as StyleBoxFlat
	p.border_width_bottom = 2
	p.expand_margin_top = -5
	p.bg_color = face.darkened(0.05)
	var d := n.duplicate() as StyleBoxFlat
	d.bg_color = Kit.GREY
	d.border_color = Kit.GREY_EDGE
	add_theme_stylebox_override("normal", n)
	add_theme_stylebox_override("hover", h)
	add_theme_stylebox_override("pressed", p)
	add_theme_stylebox_override("disabled", d)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())


func _down() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "scale", Vector2(0.93, 0.9), 0.06)
	row.position.y = 3


func _up() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	row.position.y = 0
	if sound != "":
		Sfx.play(sound, -2.0, 1.0, 0.06)
	if Game.settings.get("haptics", true) and OS.has_feature("mobile"):
		Input.vibrate_handheld(8)
