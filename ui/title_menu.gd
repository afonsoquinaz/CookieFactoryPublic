class_name TitleMenu
extends Control
## The title screen: the island slowly drifts by under the Cookie Empire
## crest and a big PLAY button. Tapping it swoops the camera down to you.

signal play

var world: World
var _crest: Control
var _play: JuicyButton
var _t := 0.0
var _cam_t := 0.0
var _leaving := false
var _center := Vector3.ZERO


func _ready() -> void:
	# drift over the middle of your empire
	var n := 0
	for b in world.bnodes.values():
		_center += b.global_position
		n += 1
	if n > 0:
		_center /= float(n)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var shade := ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var gm := ShaderMaterial.new()
	gm.shader = preload("res://render/title_shade.gdshader")
	shade.material = gm
	add_child(shade)
	_crest = Kit.vbox(0)
	_crest.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_crest)
	var em := TextureRect.new()
	em.texture = load("res://assets/emblem.png")
	em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	em.custom_minimum_size = Vector2(150, 150)
	em.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_crest.add_child(em)
	var t1 := Kit.game("COOKIE", 62, Color(1.0, 0.93, 0.78), 11)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crest.add_child(t1)
	var ribbon := PanelContainer.new()
	ribbon.add_theme_stylebox_override("panel", Kit.skin("ribbon", 52, Vector4(70, 6, 70, 22)))
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crest.add_child(ribbon)
	var t2 := Kit.game("EMPIRE", 36, Kit.WHITE, 7)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_child(t2)
	_play = Kit.juicy("PLAY", Kit.SAGE, Kit.SAGE_EDGE, 46, Vector2(320, 120))
	_play.pressed.connect(_go)
	add_child(_play)
	Kit.pop_in.call_deferred(_crest, 0.1, 0.5)
	Kit.pop_in.call_deferred(_play, 0.35, 0.45)


func _process(dt: float) -> void:
	_t += dt
	var vs := get_viewport_rect().size
	var cs := _crest.get_combined_minimum_size()
	var sc := minf(1.0, minf(vs.x * 0.6 / maxf(cs.x, 1.0), vs.y * 0.36 / maxf(cs.y, 1.0)))
	_crest.size = cs
	_crest.pivot_offset = cs * 0.5
	if not _leaving:
		_crest.scale = Vector2.ONE * sc * (1.0 + sin(_t * 1.6) * 0.012)
	_crest.position = Vector2((vs.x - cs.x) * 0.5, vs.y * 0.16)
	_play.size = _play.custom_minimum_size
	_play.position = Vector2((vs.x - _play.size.x) * 0.5, vs.y * 0.72)
	_play.pivot_offset = _play.size * 0.5
	if not _leaving:
		_play.rotation = sin(_t * 3.0) * 0.02
		# the camera drifts slowly over the island behind the menu
		_cam_t += dt
		world.cam.free_focus = true
		world.cam.zoom = 1.45
		world.cam.global_position = _center + Vector3(sin(_cam_t * 0.12) * 5.0, 0, cos(_cam_t * 0.09) * 3.0 + 4.0)


func _go() -> void:
	if _leaving:
		return
	_leaving = true
	Sfx.play("upgrade", -4.0)
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.45)
	tw.tween_property(_crest, "position:y", _crest.position.y - 120, 0.45)
	tw.chain().tween_callback(queue_free)
	world.cam.free_focus = false
	world.cam.zoom = 1.45
	var tw2 := world.cam.create_tween()
	tw2.tween_property(world.cam, "zoom", 1.0, 1.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	play.emit()
