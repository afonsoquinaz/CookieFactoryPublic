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
	var server: ServerB = world.buildings_of("server")[0]
	# a real tap on the server
	var cam := get_viewport().get_camera_3d()
	var sp := cam.unproject_position(server.global_position + Vector3(0, 0.5, 0))
	for pressed in [true, false]:
		var e := InputEventScreenTouch.new()
		e.index = 0
		e.position = sp
		e.pressed = pressed
		Input.parse_input_event(e)
		await get_tree().process_frame
	await _wait(0.6)
	print("tour tap selected: ", hud.selected == server)
	if hud.selected != server:
		hud.select(server)
	await _shot("1_selected")
	Game.money = 200
	await _wait(0.6)
	await _shot("1b_upgrade_ready")
	hud.open_building(server, "upgrade")
	await _wait(0.8)
	await _shot("1c_panel")
	Game.upgrade(server.uid)
	hud._sheet.close()
	await _wait(1.0)
	await _shot("2_timer")
	Game.finish_now(Game.job_of(server.uid))
	hud.deselect()
	await _wait(1.0)
	await _shot("3_build_sugar")
	hud.open_build()
	await _wait(0.8)
	await _shot("3b_build_panel")
	hud._sheet.close()
	await _wait(0.4)
	hud.start_placement("src_data")
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
	hud.deselect()
	world.cam.fly_to(Vector3(2, 0, 6), 1.0)
	await _wait(1.5)
	await _shot("6_south_side")
	var dock: Building = world.buildings_of("van")[0]
	for i in 3:
		(dock as VehicleB).cargo.add("t:shortbread", false)
	(dock as VehicleB)._depart()
	await _wait(1.2)
	await _shot("7_van_out")
	print("tour step ", Game.tutorial_step)
	get_tree().quit()


func _wait(t: float) -> void:
	await get_tree().create_timer(t).timeout


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [dir, name])
	print("tour ", name)
