class_name JuicyButton
extends Button
## Glossy beveled game button (9-patch skin) that presses down onto its lip
## and springs back. Optional icon (texture) or glyph before the text.
## Colours map onto skins: green, gold, red, blue, wood, cream, grey.

var face := Kit.SAGE
var edge := Kit.SAGE_EDGE
var variant := "green"
var row: HBoxContainer
var text_label: Label
var icon_rect: TextureRect
var glyph_label: Label
var sound := "click"
var _tw: Tween
var _font_size := 26


static func variant_for(f: Color) -> String:
	if f == Kit.SAGE: return "green"
	if f == Kit.BRASS: return "gold"
	if f == Kit.TERRACOTTA: return "red"
	if f == Kit.CHARCOAL or f == Kit.GLASS: return "wood"
	if f == Kit.PAPER or f == Kit.PAPER_DARK: return "cream"
	if f == Kit.GREY: return "grey"
	return "blue"


func setup(t: String, f: Color, e: Color, font_size := 26, min_size := Vector2(120, 60)) -> void:
	face = f
	edge = e
	variant = variant_for(f)
	_font_size = font_size
	custom_minimum_size = min_size
	focus_mode = Control.FOCUS_NONE
	row = Kit.hbox(8)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_bottom = -8
	add_child(row)
	text_label = Kit.game(t, font_size + 2, Kit.WHITE, 7)
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
		glyph_label = Kit.glyph(name, s, Kit.WHITE)
		glyph_label.label_settings.outline_size = 6
		glyph_label.label_settings.outline_color = Kit.OUTLINE
		row.add_child(glyph_label)
		row.move_child(glyph_label, 0)
	glyph_label.text = String.chr(Kit.GLYPH.get(name, 0xe838))
	_text_colors()


func set_text_value(t: String) -> void:
	text_label.text = t
	if text_label.get_parent() == null:
		row.add_child(text_label)


func set_colors(f: Color, e: Color) -> void:
	var v := variant_for(f)
	face = f
	edge = e
	if v == variant:
		return
	variant = v
	_restyle()


func _text_colors() -> void:
	var dark := variant == "cream"
	text_label.label_settings.font_color = Kit.INK if dark else Kit.WHITE
	text_label.label_settings.outline_size = 0 if dark else 7
	if glyph_label:
		glyph_label.label_settings.font_color = Kit.INK if dark else Kit.WHITE
		glyph_label.label_settings.outline_size = 0 if dark else 6


func _restyle() -> void:
	var m := 34
	var n := Kit.skin("btn_" + variant, m, Vector4(14, 8, 14, 14))
	var p := Kit.skin("btn_%s_down" % variant, m, Vector4(14, 12, 14, 10))
	var d := Kit.skin("btn_grey", m, Vector4(14, 8, 14, 14))
	add_theme_stylebox_override("normal", n)
	add_theme_stylebox_override("hover", n)
	add_theme_stylebox_override("pressed", p)
	add_theme_stylebox_override("disabled", d)
	add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	_text_colors()


func _down() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "scale", Vector2(0.96, 0.94), 0.05)
	row.position.y = 4


func _up() -> void:
	if _tw:
		_tw.kill()
	_tw = create_tween()
	_tw.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	row.position.y = 0
	if sound != "":
		Sfx.play(sound, -4.0, 1.0, 0.04)
	if Game.settings.get("haptics", true) and OS.has_feature("mobile"):
		Input.vibrate_handheld(6)
