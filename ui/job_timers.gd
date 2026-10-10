class_name JobTimers
extends Control
## Floating timers over everything a builder is working on: a dark pill with
## a hammer, the time left and a progress bar. Under 30 seconds it turns
## into a green FREE button that finishes the job; otherwise tapping it
## selects the building.

signal picked(job: Dictionary)

var world: World
var _pills := {}           # job (instance key) -> Control


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _key(j: Dictionary) -> String:
	return "%s_%d_%s_%.1f" % [j["type"], int(j["uid"]), str(j.get("ob", "")), float(j["start"])]


func _process(_dt: float) -> void:
	var cam := get_viewport().get_camera_3d()
	var live := {}
	for j in Game.jobs:
		var k := _key(j)
		live[k] = true
		if not _pills.has(k):
			_pills[k] = _make(j)
		var p: Control = _pills[k]
		var wp := world.job_center(j) + Vector3(0, _height(j), 0)
		if cam == null or cam.is_position_behind(wp):
			p.visible = false
			continue
		p.visible = visible
		var sp := cam.unproject_position(wp)
		p.size = p.get_combined_minimum_size()
		p.position = sp - Vector2(p.size.x * 0.5, p.size.y)
		var left := Game.job_left(j)
		var free := left <= Bal.FREE_FINISH
		var lab: Label = p.get_meta("label")
		lab.text = ("FREE  " if free else "") + Fmt.time(left)
		var bar: Control = p.get_meta("bar")
		bar.size.x = maxf(8.0, 132.0 * Game.job_progress(j))
		var bg: PanelContainer = p.get_meta("bg")
		bg.add_theme_stylebox_override("panel", Kit.box(Color(0.35, 0.55, 0.3, 0.95) if free else Color(0.12, 0.1, 0.08, 0.82), 16, 2, Color(1, 1, 1, 0.25)))
	for k in _pills.keys():
		if not live.has(k):
			_pills[k].queue_free()
			_pills.erase(k)


func _height(j: Dictionary) -> float:
	if str(j.get("ob", "")) != "":
		return 2.4
	var b: Building = world.building(int(j["uid"]))
	if b == null:
		return 3.0
	return clampf(maxf(b.size_m().x, b.size_m().y) * 0.55, 3.0, 7.0)


func _make(j: Dictionary) -> Control:
	var root := Button.new()
	root.flat = true
	root.focus_mode = Control.FOCUS_NONE
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var bg := PanelContainer.new()
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(bg)
	var v := Kit.vbox(3)
	bg.add_child(v)
	var h := Kit.hbox(6)
	v.add_child(h)
	h.add_child(Kit.icon("hammer", 30))
	var l := Kit.game("", 19, Kit.WHITE, 5)
	h.add_child(l)
	var track := Panel.new()
	track.custom_minimum_size = Vector2(132, 10)
	track.add_theme_stylebox_override("panel", Kit.box(Color(0, 0, 0, 0.45), 5))
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(track)
	var fill := Panel.new()
	fill.size = Vector2(8, 10)
	fill.add_theme_stylebox_override("panel", Kit.box(Color(1.0, 0.8, 0.32), 5))
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	root.set_meta("label", l)
	root.set_meta("bar", fill)
	root.set_meta("bg", bg)
	bg.resized.connect(func(): root.custom_minimum_size = bg.size)
	root.pressed.connect(func(): picked.emit(j))
	return root
