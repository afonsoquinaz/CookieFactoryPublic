class_name UI3D
## In-world labels, billboard icons and bubbles.

const FONT := preload("res://assets/fonts/Fredoka-Bold.ttf")


static func label(text: String, size := 48, color := Color.WHITE, outline := 14) -> Label3D:
	var l := Label3D.new()
	l.text = text
	l.font = FONT
	l.font_size = size
	l.pixel_size = 0.006
	l.modulate = color
	l.outline_size = outline
	l.outline_modulate = Color(0.24, 0.14, 0.1)
	l.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	l.no_depth_test = false
	l.render_priority = 2
	l.outline_render_priority = 1
	l.double_sided = false
	l.shaded = false
	return l


static var _badge_tex := {}


## A round white badge with a coloured rim (generated once per colour).
static func badge_texture(rim: Color) -> Texture2D:
	var key := rim.to_html()
	if _badge_tex.has(key):
		return _badge_tex[key]
	var n := 160
	var img := Image.create(n, n, true, Image.FORMAT_RGBA8)
	var c := Vector2(n, n) * 0.5
	for y in n:
		for x in n:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(0, -3))
			var ds := Vector2(x + 0.5, y + 0.5).distance_to(c + Vector2(0, 4))
			var col := Color(0, 0, 0, 0)
			# soft drop shadow
			col = Color(0.2, 0.1, 0.1, clampf((76.0 - ds) / 3.0, 0.0, 1.0) * 0.35)
			var a := clampf((74.0 - d) / 1.5, 0.0, 1.0)
			if a > 0.0:
				var inner := clampf((63.0 - d) / 1.5, 0.0, 1.0)
				var face := Color(1.0, 0.99, 0.95).lerp(Color(0.93, 0.9, 0.86), clampf((y - 20.0) / 140.0, 0.0, 1.0))
				var cc := rim.lerp(face, inner)
				col = col.blend(Color(cc.r, cc.g, cc.b, a))
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_badge_tex[key] = t
	return t


## Billboard badge: coloured rim + icon on top. Returns the root node.
static func badge(icon_name: String, rim: Color, size := 0.9) -> Node3D:
	var root := Node3D.new()
	var bg := Sprite3D.new()
	bg.texture = badge_texture(rim)
	bg.pixel_size = size / 160.0
	bg.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	bg.shaded = false
	bg.render_priority = 2
	bg.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.add_child(bg)
	var ic := icon(icon_name, size * 0.72 / 256.0)
	ic.render_priority = 3
	root.add_child(ic)
	return root


static func icon(name: String, px := 0.004) -> Sprite3D:
	var s := Sprite3D.new()
	s.texture = Icons.tex(name)
	s.pixel_size = px
	s.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	s.shaded = false
	s.alpha_cut = SpriteBase3D.ALPHA_CUT_DISABLED
	s.render_priority = 3
	s.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return s


## A floating "+$12" / "+1" text that rises and fades.
static func pop_text(parent: Node, pos: Vector3, text: String, color := Color(1.0, 0.9, 0.3), size := 64) -> void:
	var l := label(text, size, color, 16)
	parent.add_child(l)
	l.global_position = pos
	l.scale = Vector3(0.4, 0.4, 0.4)
	var tw := l.create_tween()
	tw.set_parallel(true)
	tw.tween_property(l, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "global_position", pos + Vector3(0, 1.6, 0), 1.1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(l, "modulate:a", 0.0, 0.4).set_delay(0.75)
	tw.tween_property(l, "outline_modulate:a", 0.0, 0.4).set_delay(0.75)
	tw.chain().tween_callback(l.queue_free)
