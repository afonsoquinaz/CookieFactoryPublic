extends Node
## Keeps the game smooth on older phones (from Protect the Sandcastle). It starts lower on old iPhones
## (A11 and older, and anything on the OpenGL fallback renderer), then
## watches the frame rate while you play and steps the quality down when a
## device can't keep up: render resolution, anti-aliasing, then shadows.
## It never steps back up within a session, so the picture doesn't pump.

signal changed(level: int)

const LEVELS := [
	# 3D resolution scale, MSAA, sun shadows
	{"scale": 1.0, "msaa": Viewport.MSAA_2X, "shadows": true},
	{"scale": 0.85, "msaa": Viewport.MSAA_DISABLED, "shadows": true},
	{"scale": 0.72, "msaa": Viewport.MSAA_DISABLED, "shadows": false},
	{"scale": 0.6, "msaa": Viewport.MSAA_DISABLED, "shadows": false},
]
const TARGET_FPS := 50.0
const WINDOW := 3.0             # seconds of frames per check

var level := 0
var watching := true
var _acc := 0.0
var _frames := 0
var _slow := 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	level = _start_level()
	_apply.call_deferred()


## Older devices start a notch or two down.
func _start_level() -> int:
	var lv := 0
	if RenderingServer.get_current_rendering_method() == "gl_compatibility":
		lv = 1
	if OS.has_feature("ios"):
		# "iPhone10,3" = iPhone X (A11); iPhone11,x (A12, XS/XR) and up are fine
		var model := OS.get_model_name()
		if model.begins_with("iPhone"):
			var major := model.trim_prefix("iPhone").get_slice(",", 0).to_int()
			if major > 0 and major <= 9:
				lv = maxi(lv, 2)      # iPhone 7 and older
			elif major == 10:
				lv = maxi(lv, 1)      # iPhone 8 / X
	if OS.get_processor_count() <= 2:
		lv = maxi(lv, 2)
	return lv


func _process(dt: float) -> void:
	if not watching or level >= LEVELS.size() - 1 or Engine.time_scale != 1.0:
		_acc = 0.0
		_frames = 0
		return
	_acc += dt
	_frames += 1
	if _acc < WINDOW:
		return
	var fps := _frames / _acc
	_acc = 0.0
	_frames = 0
	_slow = _slow + 1 if fps < TARGET_FPS else 0
	if _slow >= 2:
		_slow = 0
		level += 1
		_apply()


func _apply() -> void:
	var l: Dictionary = LEVELS[level]
	var vp := get_viewport()
	vp.scaling_3d_scale = l["scale"]
	vp.msaa_3d = l["msaa"]
	changed.emit(level)
