extends Node
## First scene: the Cookie Empire crest (emblem + title, laid out to fit any
## screen) with a progress bar while the game loads in the background. Then,
## still behind the cover, Warmup builds every mesh, compiles every shader and
## opens every panel once (a few small steps a frame, so the bar keeps moving),
## and the cover fades away onto a game that won't stutter the first time you
## do something.

const MAIN := "res://main.tscn"
const EMBLEM := preload("res://assets/emblem.png")

var _layer: CanvasLayer
var _cover: Control
var _crest: VBoxContainer
var _track: Panel
var _fill: Panel
var _tip: Label
var _status: Label
var _phase := 0
var _packed: PackedScene
var _shown := 0.0
var _target := 0.0
var _frames := 0
var _t := 0.0
var _warm: Warmup
var _warm_total := 1

const TIPS := [
	"Everything is open from the start: you decide what to build",
	"Builders keep building while you're away",
	"Jobs with 30 seconds left finish for free",
	"Every building gets a road to the High Street. Keep entrances clear",
	"Bushes, stumps and boulders often hide gems",
	"Every 3 Bakery levels add a silo for richer recipes",
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
	# laid out live (not a baked image) so it fits any screen shape
	_crest = Kit.vbox(0)
	_crest.alignment = BoxContainer.ALIGNMENT_CENTER
	_cover.add_child(_crest)
	var em := TextureRect.new()
	em.texture = EMBLEM
	em.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	em.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	em.custom_minimum_size = Vector2(170, 170)
	em.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_crest.add_child(em)
	var t1 := Kit.game("COOKIE", 62, Color(1.0, 0.93, 0.78), 11)
	t1.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crest.add_child(t1)
	var ribbon := PanelContainer.new()
	ribbon.add_theme_stylebox_override("panel", Kit.skin("ribbon", 52, Vector4(70, 6, 70, 22)))
	ribbon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_crest.add_child(ribbon)
	var t2 := Kit.game("EMPIRE", 36, Kit.WHITE, 7)
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ribbon.add_child(t2)
	_track = Panel.new()
	_track.add_theme_stylebox_override("panel", Kit.skin("track", 18))
	_cover.add_child(_track)
	_fill = Panel.new()
	_fill.add_theme_stylebox_override("panel", Kit.skin("fill_gold", 18))
	_track.add_child(_fill)
	_status = Kit.game("Opening the doors...", 18, Color(1.0, 0.86, 0.5), 4)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cover.add_child(_status)
	_tip = Kit.game(TIPS.pick_random(), 21, Color(0.9, 0.84, 0.74), 5)
	_tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cover.add_child(_tip)
	ResourceLoader.load_threaded_request(MAIN)
	if Shot.args().has("boottime"):
		get_tree().root.add_child.call_deferred(load("res://dev/boottime.gd").new())
	if Shot.args().has("bootshot"):
		Shot.attach.call_deferred(get_tree().root)
	_layout()
	get_viewport().size_changed.connect(_layout)


func _layout() -> void:
	var vs := get_viewport().get_visible_rect().size
	var cs := _crest.get_combined_minimum_size()
	# shrink the crest on narrow or short screens so it always fits
	var sc := minf(1.0, minf(vs.x * 0.62 / cs.x, vs.y * 0.4 / cs.y))
	_crest.size = cs
	_crest.pivot_offset = Vector2(cs.x * 0.5, 0)
	_crest.scale = Vector2.ONE * sc
	_crest.position = Vector2((vs.x - cs.x) * 0.5, vs.y * 0.42 - cs.y * sc * 0.5)
	var w := minf(vs.x - 120.0, 420.0)
	_track.size = Vector2(w, 30)
	_track.position = Vector2((vs.x - w) * 0.5, vs.y * 0.8)
	_status.size = Vector2(vs.x - 80, 30)
	_status.position = Vector2(40, vs.y * 0.8 - 36)
	_tip.size = Vector2(vs.x - 80, 80)
	_tip.position = Vector2(40, vs.y * 0.8 + 44)


func _process(dt: float) -> void:
	_t += dt
	match _phase:
		0:
			var prog := []
			var st := ResourceLoader.load_threaded_get_status(MAIN, prog)
			_target = 0.05 + 0.25 * float(prog[0]) if not prog.is_empty() else 0.05
			if st == ResourceLoader.THREAD_LOAD_LOADED:
				_packed = ResourceLoader.load_threaded_get(MAIN)
				_target = 0.32
				_phase = 1
			elif st == ResourceLoader.THREAD_LOAD_FAILED or st == ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
				get_tree().change_scene_to_file.call_deferred(MAIN)
				set_process(false)
		1:
			if _shown >= 0.3:
				_status.text = "Laying out your empire..."
				var game := _packed.instantiate()
				get_tree().root.add_child(game)
				get_tree().current_scene = game
				_target = 0.36
				_phase = 2
		2:
			# the world is up: start warming everything
			_frames += 1
			if _frames >= 2:
				var game2 := get_tree().current_scene
				_warm = Warmup.new(game2.get("world"), game2.get("ui"))
				_warm_total = maxi(1, _warm.steps.size())
				_phase = 3
		3:
			var done := _warm.run(10.0)
			var f := 1.0 - float(_warm.steps.size()) / float(_warm_total)
			_status.text = ["Raising the buildings...", "Stocking the pantry...", "Waking the staff...", "Warming the ovens..."][mini(3, int(f * 4.0))]
			_target = 0.36 + 0.6 * f
			if done:
				_warm.finish()
				_warm = null
				BuildPanel.last_tab = Defs.TABS[0][0]
				_frames = 0
				_phase = 4
		4:
			# a few calm frames before showing the world
			_frames += 1
			_target = 1.0
			_status.text = "Ready!"
			if _frames > 3 and _shown >= 0.999:
				_phase = 5
				var tw := create_tween()
				tw.tween_property(_cover, "modulate:a", 0.0, 0.5).set_trans(Tween.TRANS_SINE)
				tw.tween_callback(queue_free)
	# glide toward the target so the bar walks smoothly, never jumps
	_shown = move_toward(_shown, _target, minf(dt, 0.05) * (2.5 if _phase >= 4 else 0.9))
	_fill.position = Vector2(0, 0)
	_fill.size = Vector2(maxf(28.0, _track.size.x * _shown), _track.size.y)
