class_name JuicyButton
extends Button
## Flat rounded button with a thin darker lip; presses down a little and
## springs back. Optional icon (texture) or glyph (Material Icons) before the text.

var face := Kit.SAGE
var edge := Kit.SAGE_EDGE
var row: HBoxContainer
var text_label: Label
var icon_rect: TextureRect
var glyph_label: Label
var sound := "click"
var text_color := Kit.WHITE
var _tw: Tween


func setup(t: String, f: Color, e: Color, font_size := 26, min_size := Vector2(120, 60)) -> void:
	face = f
	edge = e
	custom_minimum_size = min_size
	focus_mode = Control.FOCUS_NONE
	text_color = Kit.INK if f.get_luminance() > 0.62 else Kit.WHITE
	row = Kit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -3
	add_child(row)
	text_label = Kit.label(t, font_size, text_color)
	text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if t != "":
		row.add_child(text_label)
	_restyle()
	button_down.connect(_down)
	button_up.connect(_up)
	resized.connect(func(): pivot_offset = size * 0.5)


func set_icon(name: String, s := 36.0) -> void:
	if icon_rect == null:
		icon_rect = Kit.icon(name, s)
		row.add_child(icon_rect)
		row.move_child(icon_rect, 0)
	icon_rect.texture = Icons.tex(name)
	icon_rect.custom_minimum_size = Vector2(s, s)


func set_glyph(name: String, s := 30) -> void:
	if glyph_label == null:
		glyph_label = Kit.glyph(name, s, text_color)
		row.add_child(glyph_label)
		row.move_child(glyph_label, 0)
	glyph_label.text = String.chr(Kit.GLYPH.get(name, 0xe838))


func set_text_value(t: String) -> void:
	text_label.text = t
	if text_label.get_parent() == null:
		row.add_child(text_label)


func set_colors(f: Color, e: Color) -> void:
	if f == face and e == edge:
		return
	face = f
	edge = e
	text_color = Kit.INK if f.get_luminance() > 0.62 else Kit.WHITE
	text_label.label_settings.font_color = text_color
	if glyph_label:
		glyph_label.label_settings.font_color = text_color
	_restyle()


func _restyle() -> void:
	var r := int(minf(custom_minimum_size.y * 0.3, 18.0))
	var n := Kit.box(face, r, 0, Color.TRANSPARENT, 0)
	n.border_width_bottom = 3
	n.border_color = edge
	n.content_margin_bottom = 3
	var h := n.duplicate() as StyleBoxFlat
	h.bg_color = face.lightened(0.05)
	var p := n.duplicate() as StyleBoxFlat
	p.border_width_bottom = 1
	p.expand_margin_top = -2
	p.bg_color = face.darkened(0.06)
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
	_tw.tween_property(self, "scale", Vector2(0.96, 0.95), 0.05)
	row.position.y = 2


func _up() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	row.position.y = 0
	if sound != "":
		Sfx.play(sound, -4.0, 1.0, 0.04)
	if Game.settings.get("haptics", true) and OS.has_feature("mobile"):
		Input.vibrate_handheld(6)
