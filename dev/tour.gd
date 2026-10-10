extends Node
## Dev: plays the opening like a new player and saves a screenshot at every
## tutorial step (--tour=<dir>). Used to review onboarding.

var dir := ""
var hud
var world: World
var _n := 0


func _ready() -> void:
	dir = str(Shot.args().get("tour", "/tmp"))
	await get_tree().create_timer(0.5).timeout
	world = get_tree().current_scene.get("world")
	hud = get_tree().current_scene.get("ui")
	Game.money = 60
	await _shot("0_welcome")
	var bakery: BakeryB = world.buildings_of("bakery")[0]
	# a real tap on the bakery
	var cam := get_viewport().get_camera_3d()
	var sp := cam.unproject_position(bakery.global_position + Vector3(0, 0.5, 0))
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = sp
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame
	await _wait(0.6)
	print("tour tap selected: ", hud.selected == bakery)
	if hud.selected != bakery:
		hud.select(bakery)
	await _shot("1_selected")
	Game.money = 200
	await _wait(0.6)
	await _shot("1b_upgrade_ready")
	hud.open_building(bakery, "upgrade")
	await _wait(0.8)
	await _shot("1c_panel")
	Game.upgrade(bakery.uid)
	hud._sheet.close()
	await _wait(1.0)
	await _shot("2_timer")
	Game.finish_now(Game.job_of(bakery.uid))
	hud.deselect()
	await _wait(1.0)
	await _shot("3_build_sugar")
	hud.open_build()
	await _wait(0.8)
	await _shot("3b_build_panel")
	hud._sheet.close()
	await _wait(0.4)
	hud.start_placement("farm_sugar")
	await _wait(1.0)
	await _shot("3c_placing")
	hud.placement._confirm()
	await _wait(1.0)
	await _shot("4_site")
	var j: Dictionary = Game.jobs[0] if not Game.jobs.is_empty() else {}
	if not j.is_empty():
		Game.finish_now(j)
	await _wait(2.0)
	await _shot("5_sugar")
	Game.money = 500
	Game.tutorial_step = 6
	await _wait(1.5)
	await _shot("6_hall")
	hud.select(world.hall())
	await _wait(0.6)
	await _shot("6b_hall_selected")
	Game.upgrade(world.hall().uid)
	hud.deselect()
	await _wait(0.6)
	Game.finish_now(Game.jobs[0])
	await _wait(1.5)
	await _shot("6c_hall_popup")
	for c in hud.get_children():
		if c is Control and c.mouse_filter == Control.MOUSE_FILTER_STOP and c.get_child_count() > 1 and c.get_child(0) is ColorRect:
			c.queue_free()
	await _wait(1.0)
	await _shot("7_obstacle")
	Game.tutorial_step = 8
	await _wait(1.0)
	await _shot("8_hire")
	Game.tutorial_step = 99
	await _wait(1.0)
	await _shot("9_free")
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
	print("tour ", name)
