extends Node
## First scene: keeps the launch splash (logo on cream) on screen with a
## chunky progress bar while the game loads in the background, lets the first
## frames of the world draw behind it (shader warm-up), then fades away.

const MAIN := "res://main.tscn"
const SPLASH := preload("res://assets/splash.png")

var _layer: CanvasLayer
var _cover: Control
var _logo: TextureRect
var _track: Panel
var _fill: Panel
var _tip: Label
var _phase := 0
var _packed: PackedScene
var _shown := 0.0
var _target := 0.0
var _frames := 0
var _t := 0.0

const TIPS := [
	"Stand on a pad to pick up or drop off",
	"Every new farm adds an ingredient — and raises the price of each cookie",
	"Hire staff to automate every step",
	"Vans leave when full, or a moment after loading",
	"A ! over a hopper means the line is waiting for it",
]


func _ready() -> void:
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)
	_cover = Control.new()
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.mouse_filter = Control.MOUSE_FILTER_STOP
	_layer.add_child(_cover)
	var bg := ColorRect.new()
	bg.color = Color(0.15, 0.1, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(bg)
	_logo = TextureRect.new()
	_logo.texture = SPLASH
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_logo.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(_logo)
	_track = Panel.new()
	_track.add_theme_stylebox_override("panel", Kit.box(Color(1, 1, 1, 0.08), 4))
	_cover.add_child(_track)
	_fill = Panel.new()
	_fill.add_theme_stylebox_override("panel", Kit.box(Kit.BRASS, 3))
	_track.add_child(_fill)
	_tip = Kit.label(TIPS.pick_random(), 19, Color(0.82, 0.76, 0.66), 0, false)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cover.add_child(_tip)
	ResourceLoader.load_threaded_request(MAIN)
	if Shot.args().has("bootshot"):
		Shot.attach.call_deferred(get_tree().root)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var w := minf(vs.x * 0.7, 520.0)
	_track.size = Vector2(w * 0.7, 8)
	_track.position = Vector2((vs.x - w * 0.7) * 0.5, vs.y * 0.8)
	_tip.size = Vector2(vs.x - 80, 80)
	_tip.position = Vector2(40, vs.y * 0.8 + 30)


func _process(dt: float) -> void:
	_t += dt
	match _phase:
		0:
			var prog := []
			var st := ResourceLoader.load_threaded_get_status(MAIN, prog)
			_target = 0.05 + 0.45 * float(prog[0]) if not prog.is_empty() else 0.05
			if st == ResourceLoader.THREAD_LOAD_LOADED:
				_packed = ResourceLoader.load_threaded_get(MAIN)
				_target = 0.55
				_phase = 1
			elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				get_tree().change_scene_to_file.call_deferred(MAIN)
				set_process(false)
		1:
			if _shown >= 0.5:
				var game := _packed.instantiate()
				get_tree().root.add_child(game)
				get_tree().current_scene = game
				_target = 0.7
				_phase = 2
		2:
			_frames += 1
			_target = minf(0.98, 0.7 + _frames * 0.01)
			if (_frames > 30 and dt < 0.05) or _frames > 240:
				_target = 1.0
				_phase = 3
		3:
			if _shown >= 0.999:
				_phase = 4
				var tw := create_tween()
				tw.tween_property(_cover, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
				tw.tween_callback(queue_free)
	_shown = move_toward(_shown, _target, dt * (2.5 if _phase >= 3 else 1.3))
	_fill.position = Vector2(0, 0)
	_fill.size = Vector2(maxf(8.0, _track.size.x * _shown), _track.size.y)
