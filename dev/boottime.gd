extends Node
## Dev: logs frame times from boot until the loading cover is gone.
var _prev := 0
var _n := 0
var _worst := 0.0
func _ready():
	process_priority = -1000
	_prev = Time.get_ticks_usec()
func _process(_dt):
	var now := Time.get_ticks_usec()
	var ms := (now - _prev) / 1000.0
	_prev = now
	_n += 1
	_worst = maxf(_worst, ms)
	if ms > 60.0:
		print("BOOT frame %d %.1f ms" % [_n, ms])
	var boot := get_tree().root.get_node_or_null("Boot")
	if _n > 5 and boot == null:
		print("BOOT done after %d frames, %.2f s, worst %.1f ms" % [_n, Time.get_ticks_msec() / 1000.0, _worst])
		get_tree().quit()
