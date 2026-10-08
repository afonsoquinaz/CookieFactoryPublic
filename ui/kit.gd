class_name Kit
## UI building blocks: fonts, colours, rounded panels, outlined labels,
## chunky candy buttons that squash and click, pop/bounce/shake tweens.

const FONT_BOLD := preload("res://assets/fonts/Fredoka-Bold.ttf")
const FONT := preload("res://assets/fonts/Fredoka-SemiBold.ttf")

const INK := Color(0.29, 0.17, 0.12)
const WHITE := Color(1, 1, 1)
const CREAM := Color(1.0, 0.96, 0.88)
const CREAM_DARK := Color(0.95, 0.86, 0.72)
const CHOCO := Color(0.45, 0.27, 0.17)
const CHOCO_DARK := Color(0.32, 0.18, 0.11)
const YELLOW := Color(1.0, 0.8, 0.22)
const YELLOW_EDGE := Color(0.88, 0.55, 0.08)
const GREEN := Color(0.42, 0.82, 0.36)
const GREEN_EDGE := Color(0.24, 0.58, 0.22)
const BLUE := Color(0.3, 0.64, 0.98)
const BLUE_EDGE := Color(0.16, 0.42, 0.76)
const PINK := Color(1.0, 0.52, 0.64)
const PINK_EDGE := Color(0.8, 0.3, 0.44)
const CORAL := Color(0.98, 0.42, 0.36)
const CORAL_EDGE := Color(0.72, 0.22, 0.2)
const PURPLE := Color(0.62, 0.48, 0.95)
const PURPLE_EDGE := Color(0.42, 0.3, 0.72)
const GREY := Color(0.72, 0.7, 0.72)
const GREY_EDGE := Color(0.5, 0.48, 0.5)
const SHADE := Color(0.18, 0.1, 0.08, 0.45)


static func box(c: Color, radius := 18, border := 0, border_c := Color.TRANSPARENT, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.corner_detail = 8
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_c
	if shadow > 0:
		s.shadow_color = Color(0.2, 0.1, 0.05, 0.3)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.5)
	s.anti_aliasing = true
	return s


## Cream card with a chocolate rim and a darker bottom lip.
static func card(radius := 26, face := CREAM, rim := CHOCO) -> StyleBoxFlat:
	var s := box(face, radius, 5, rim, 8)
	s.border_width_bottom = 10
	s.content_margin_left = 20
	s.content_margin_right = 20
	s.content_margin_top = 16
	s.content_margin_bottom = 20
	return s


static func label(text: String, size := 26, color := WHITE, outline := 8, bold := true) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = FONT_BOLD if bold else FONT
	ls.font_size = size
	ls.font_color = color
	if outline > 0:
		ls.outline_size = outline
		ls.outline_color = INK
		ls.shadow_size = 1
		ls.shadow_color = Color(0.2, 0.1, 0.05, 0.4)
		ls.shadow_offset = Vector2(0, maxf(2.0, outline * 0.4))
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func icon(name: String, s := 48.0) -> TextureRect:
	var t := TextureRect.new()
	t.texture = Icons.tex(name)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.custom_minimum_size = Vector2(s, s)
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


static func juicy(text: String, face: Color, edge: Color, size := 30, min_size := Vector2(120, 64)) -> JuicyButton:
	var b := JuicyButton.new()
	b.setup(text, face, edge, size, min_size)
	return b


static func hbox(sep := 10) -> HBoxContainer:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", sep)
	h.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return h


static func vbox(sep := 10) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", sep)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return v


static func spacer(w := 0.0, h := 0.0, expand := false) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(w, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if expand:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return c


static func pop_in(c: Control, delay := 0.0, dur := 0.45) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.4, 0.4)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.set_parallel()
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.4)


static func bounce(c: Control, amount := 0.18) -> void:
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * (1.0 + amount), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


static func shake(c: Control) -> void:
	if c.has_meta("shake_tw"):
		var old: Tween = c.get_meta("shake_tw")
		if old and old.is_valid():
			old.kill()
			c.position.x = float(c.get_meta("shake_x"))
	var x := c.position.x
	c.set_meta("shake_x", x)
	var tw := c.create_tween()
	c.set_meta("shake_tw", tw)
	for i in 4:
		tw.tween_property(c, "position:x", x + (8.0 if i % 2 == 0 else -8.0) * (1.0 - i * 0.2), 0.04)
	tw.tween_property(c, "position:x", x, 0.04)
