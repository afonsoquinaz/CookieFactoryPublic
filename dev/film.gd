extends Node
## Dev: screenshots every --every seconds into --film=<dir> (n = --count),
## after optional setup: --van loads the first van so it drives off.

var dir := ""
var every := 0.5
var count := 10
var _t := 0.0
var _n := 0
var _wait := 1.0


func _ready() -> void:
	var a := Shot.args()
	dir = str(a.get("film", "/tmp"))
	every = float(a.get("every", "0.5"))
	count = int(a.get("count", "10"))
	_wait = float(a.get("wait", "1.0"))


func _process(dt: float) -> void:
	if _wait > 0.0:
		_wait -= dt
		return
	_t -= dt
	if _t <= 0.0:
		_t = every
		_snap()


func _snap() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%02d.png" % [dir, _n])
	_n += 1
	if _n >= count:
		get_tree().quit()
