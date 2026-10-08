class_name Shot
extends Node
## Saves a screenshot after N frames when the game runs with --shot=path
## (see tools/shot.sh), then quits. Also parses simple --key=value args.

var path := ""
var frames := 90
var _n := 0


static func args() -> Dictionary:
	var d := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			d[kv[0]] = kv[1] if kv.size() > 1 else "1"
	return d


static func attach(host: Node) -> void:
	var a := args()
	if a.has("shot"):
		var s := Shot.new()
		s.path = a["shot"]
		s.frames = int(a.get("frames", "90"))
		s.process_mode = Node.PROCESS_MODE_ALWAYS
		host.add_child(s)


func _process(_dt: float) -> void:
	_n += 1
	if _n == frames:
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		img.save_png(path)
		print("shot saved ", path)
		get_tree().quit()
