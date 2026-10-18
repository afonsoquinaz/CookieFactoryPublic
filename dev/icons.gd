extends Node3D
## Icon renderer: draws every UI icon from the game's own meshes (items,
## tokens, buildings, people) plus small models for UI symbols, one at a time
## on a transparent background, and saves them as raw 512 px PNGs for
## tools/icon_post.py (trim, soft shadow, 256 px -> assets/icons/).
##   tools/icons.sh                 # every icon
##   tools/icons.sh gpu tk_pico     # only these

const OUT := "res://tools/icon_src/"
const SIZE := 512

var _stage: Node3D
var _cam: Camera3D
var _names: Array[String] = []
var _i := 0
var _wait := 0
var _busy := false


func _ready() -> void:
	MeshKit.detail = 1.4
	get_viewport().transparent_bg = true
	RenderingServer.set_default_clear_color(Color(0, 0, 0, 0))
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_CLEAR_COLOR
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.85, 0.88, 1.0)
	e.ambient_light_energy = 0.42
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.98
	e.tonemap_white = 6.0
	e.adjustment_enabled = true
	e.adjustment_saturation = 1.04
	e.adjustment_contrast = 1.06
	we.environment = e
	add_child(we)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-48, -52, 0)
	key.light_color = Color(1.0, 0.95, 0.86)
	key.light_energy = 1.05
	key.shadow_enabled = true
	key.shadow_bias = 0.02
	key.shadow_opacity = 0.55
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 140, 0)
	fill.light_color = Color(0.75, 0.85, 1.0)
	fill.light_energy = 0.35
	add_child(fill)
	_cam = Camera3D.new()
	_cam.fov = 26.0
	_cam.current = true
	add_child(_cam)
	_stage = Node3D.new()
	add_child(_stage)
	var want: Array = Array(OS.get_cmdline_user_args()).filter(func(a): return not str(a).begins_with("--"))
	for n in IconSet.names():
		if want.is_empty() or want.has(n):
			_names.append(n)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	_show()


func _show() -> void:
	for c in _stage.get_children():
		c.queue_free()
	if _i >= _names.size():
		print("icons done: %d" % _names.size())
		get_tree().quit()
		return
	var n: Node3D = IconSet.build(_names[_i])
	_stage.add_child(n)
	_frame(n)
	_wait = 4


## Points the camera at the node from a 3/4 view so it fills the frame.
func _frame(n: Node3D) -> void:
	var box := _aabb(n)
	var c := box.get_center()
	var yaw := deg_to_rad(float(n.get_meta("yaw", -32.0)))
	var pitch := deg_to_rad(float(n.get_meta("pitch", 28.0)))
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	var r := box.size.length() * 0.5
	var dist := r / tan(deg_to_rad(_cam.fov * 0.5)) * 1.02
	_cam.position = c + dir * dist
	_cam.look_at(c)
	_cam.near = maxf(0.01, dist - r * 2.0)
	_cam.far = dist + r * 2.0


func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array[Node] = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D and (x as MeshInstance3D).mesh:
			var mi := x as MeshInstance3D
			var b := mi.global_transform * mi.mesh.get_aabb()
			out = b if first else out.merge(b)
			first = false
		for ch in x.get_children():
			stack.append(ch)
	return out


func _process(_dt: float) -> void:
	if _i >= _names.size() or _busy:
		return
	_wait -= 1
	if _wait > 0:
		return
	_busy = true
	await RenderingServer.frame_post_draw
	_busy = false
	var img := get_viewport().get_texture().get_image()
	img.save_png(ProjectSettings.globalize_path(OUT + _names[_i] + ".png"))
	_i += 1
	_show()
