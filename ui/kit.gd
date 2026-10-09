class_name Kit
## UI building blocks for Cookie Empire's game UI: wood-framed parchment
## panels, glossy beveled buttons, ribbon banners and framed counters (9-patch
## textures drawn by tools/gen_ui.py), Lilita One for game text with a dark
## outline, Manrope for small print, Material Icons glyphs.

const FONT_FILE := preload("res://assets/fonts/Manrope.ttf")
const SERIF := preload("res://assets/fonts/DMSerifDisplay.ttf")
const GAME := preload("res://assets/fonts/LilitaOne.ttf")
const ICONS := preload("res://assets/fonts/MaterialIconsRound.otf")

static var _fonts := {}
static var _skins := {}

const INK := Color(0.32, 0.19, 0.11)
const OUTLINE := Color(0.2, 0.11, 0.06)
const MUTED := Color(0.52, 0.4, 0.3)
const WHITE := Color(1, 1, 1)
const PAPER := Color(0.97, 0.95, 0.91)
const PAPER_DARK := Color(0.9, 0.87, 0.81)
const LINE := Color(0.84, 0.8, 0.74)
const GLASS := Color(0.11, 0.1, 0.09, 0.74)
const TERRACOTTA := Color(0.76, 0.45, 0.33)
const TERRACOTTA_EDGE := Color(0.6, 0.33, 0.24)
const SAGE := Color(0.44, 0.55, 0.4)
const SAGE_EDGE := Color(0.32, 0.42, 0.29)
const BRASS := Color(0.82, 0.67, 0.4)
const BRASS_EDGE := Color(0.64, 0.5, 0.28)
const CHARCOAL := Color(0.22, 0.21, 0.21)
const CHARCOAL_EDGE := Color(0.1, 0.1, 0.1)
const GREY := Color(0.78, 0.76, 0.72)
const GREY_EDGE := Color(0.64, 0.62, 0.58)

# legacy names (older call sites) mapped onto the new palette
const CHOCO := INK
const CHOCO_DARK := INK
const CREAM := PAPER
const CREAM_DARK := PAPER_DARK
const YELLOW := BRASS
const YELLOW_EDGE := BRASS_EDGE
const GREEN := SAGE
const GREEN_EDGE := SAGE_EDGE
const BLUE := CHARCOAL
const BLUE_EDGE := CHARCOAL_EDGE
const PINK := TERRACOTTA
const PINK_EDGE := TERRACOTTA_EDGE
const CORAL := TERRACOTTA
const CORAL_EDGE := TERRACOTTA_EDGE
const PURPLE := CHARCOAL
const PURPLE_EDGE := CHARCOAL_EDGE

## Material Icons codepoints used by the UI.
const GLYPH := {
	"settings": 0xe8b8, "upgrades": 0xe8e5, "staff": 0xf233, "boost": 0xea0b, "close": 0xe5cd,
	"add": 0xe145, "remove": 0xe15b, "lock": 0xe897, "music": 0xe405, "sound": 0xe050,
	"vibrate": 0xe62d, "restart": 0xf053, "star": 0xe838, "truck": 0xe558, "hire": 0xe7fe,
	"arrow": 0xe5c8, "schedule": 0xe8b5, "delete": 0xe872,
}


## A 9-patch skin from assets/ui/<name>.png.
## margin = texture border kept unscaled; pad = content padding.
static func skin(name: String, margin := 40, pad := Vector4(24, 18, 24, 22)) -> StyleBoxTexture:
	var key := "%s_%d_%s" % [name, margin, pad]
	if not _skins.has(key):
		var s := StyleBoxTexture.new()
		s.texture = load("res://assets/ui/%s.png" % name)
		s.texture_margin_left = margin
		s.texture_margin_right = margin
		s.texture_margin_top = margin
		s.texture_margin_bottom = margin
		s.content_margin_left = pad.x
		s.content_margin_top = pad.y
		s.content_margin_right = pad.z
		s.content_margin_bottom = pad.w
		_skins[key] = s
	return _skins[key]


## Chunky game text with a dark outline and a drop shadow.
static func game(text: String, size := 30, color := WHITE, outline := 8) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = GAME
	ls.font_size = size
	ls.font_color = color
	if outline > 0:
		ls.outline_size = outline
		ls.outline_color = OUTLINE
		ls.shadow_size = 1
		ls.shadow_color = Color(0.1, 0.05, 0.02, 0.5)
		ls.shadow_offset = Vector2(0, maxf(2.0, outline * 0.45))
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Manrope at a weight (400 regular .. 800 extra bold).
static func font(weight := 700) -> Font:
	if not _fonts.has(weight):
		var f := FontVariation.new()
		f.base_font = FONT_FILE
		f.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
		_fonts[weight] = f
	return _fonts[weight]


static func box(c: Color, radius := 18, border := 0, border_c := Color.TRANSPARENT, shadow := 0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = c
	s.set_corner_radius_all(radius)
	s.corner_detail = 8
	if border > 0:
		s.set_border_width_all(border)
		s.border_color = border_c
	if shadow > 0:
		s.shadow_color = Color(0.1, 0.07, 0.05, 0.18)
		s.shadow_size = shadow
		s.shadow_offset = Vector2(0, shadow * 0.4)
	s.anti_aliasing = true
	return s


## Paper sheet with a hairline border.
static func card(radius := 28, face := PAPER, rim := LINE) -> StyleBoxFlat:
	var s := box(face, radius, 1, rim, 14)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 20
	s.content_margin_bottom = 22
	return s


## Dark glass pill over the 3D world.
static func glass(radius := 22) -> StyleBoxFlat:
	var s := box(GLASS, radius)
	s.content_margin_left = 14
	s.content_margin_right = 18
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s


## text label. `outline` > 0 now means "sits over the world": a soft shadow
## for legibility (no cartoon outlines). bold = 700 weight, else 500.
static func label(text: String, size := 26, color := INK, outline := 0, bold := true) -> Label:
	var l := Label.new()
	l.text = text
	var ls := LabelSettings.new()
	ls.font = font(700 if bold else 500)
	ls.font_size = size
	ls.font_color = color
	if outline > 0:
		ls.shadow_size = 4
		ls.shadow_color = Color(0, 0, 0, 0.35)
		ls.shadow_offset = Vector2(0, 2)
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Big numbers and titles: game font (outlined when light on dark).
static func title(text: String, size := 40, color := INK) -> Label:
	if color.get_luminance() > 0.6:
		return game(text, size, color, maxi(4, size / 7))
	var l := label(text, size, color)
	l.label_settings.font = GAME
	return l


static func glyph(name: String, size := 32, color := WHITE) -> Label:
	var l := Label.new()
	l.text = String.chr(GLYPH.get(name, 0xe838))
	var ls := LabelSettings.new()
	ls.font = ICONS
	ls.font_size = size
	ls.font_color = color
	l.label_settings = ls
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
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


static func juicy(text: String, face: Color, edge: Color, size := 26, min_size := Vector2(120, 60)) -> JuicyButton:
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


static func pop_in(c: Control, delay := 0.0, dur := 0.35) -> void:
	c.pivot_offset = c.size * 0.5
	c.scale = Vector2(0.92, 0.92)
	c.modulate.a = 0.0
	var tw := c.create_tween()
	tw.tween_interval(delay)
	tw.set_parallel()
	tw.tween_property(c, "scale", Vector2.ONE, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "modulate:a", 1.0, dur * 0.6)


static func bounce(c: Control, amount := 0.08) -> void:
	c.pivot_offset = c.size * 0.5
	var tw := c.create_tween()
	tw.tween_property(c, "scale", Vector2.ONE * (1.0 + amount), 0.08).set_trans(Tween.TRANS_SINE)
	tw.tween_property(c, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


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
		tw.tween_property(c, "position:x", x + (6.0 if i % 2 == 0 else -6.0) * (1.0 - i * 0.2), 0.04)
	tw.tween_property(c, "position:x", x, 0.04)
