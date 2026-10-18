extends Node
## Dev (--hitch): performs common actions one by one and reports how long
## each call took and the slowest frame right after it (first use of
## meshes, materials, shaders, panels). Used to hunt freezes.

var hud
var world: World
var _last := 0
var _worst := 0.0


func _ready() -> void:
	process_priority = -1000
	await get_tree().create_timer(1.5).timeout
	while get_tree().root.get_node_or_null("Boot") != null:
		await get_tree().process_frame
	await get_tree().create_timer(1.0).timeout
	world = get_tree().current_scene.get("world")
	hud = get_tree().current_scene.get("ui")
	Game.money = 1e9
	Game.gems = 9999
	for pass_i in int(Shot.args().get("passes", "1")):
		print("HITCH pass ", pass_i)
		await _run()
	get_tree().quit()


func _run() -> void:
	var server: Building = world.buildings_of("server")[0]
	await _act("select server", func(): hud.select(server))
	await _act("info panel", func(): hud.open_building(server))
	await _act("close panel", func(): hud._sheet.close())
	await _act("move server", func(): hud.start_placement("server", server.uid))
	for i in 4:
		await _act("slide %d" % i, func(): world.cam.global_position += Vector3(2.0, 0, 0))
	await _act("rotate", func(): hud.placement._rotate())
	await _act("cancel move", func(): hud.placement.finish(false))
	await _act("upgrade server", func(): Game.upgrade(server.uid) if Game.job_of(server.uid).is_empty() else Game.finish_now(Game.job_of(server.uid)))
	await _act("build panel", func(): hud.open_build())
	await _act("close build", func(): hud._sheet.close())
	await _act("staff panel", func(): hud.open_staff())
	await _act("close staff", func(): hud._sheet.close())
	await _act("research", func(): hud.open_sheet(ResearchPanel.new()))
	await _act("settings", func(): hud.open_sheet(SettingsPanel.new()))
	await _act("recipes", func(): hud.open_recipes(server))
	await _act("close", func(): hud._sheet.close())
	for kind in Defs.BUILD_ORDER:
		await _act("place " + kind, func(): hud.start_placement(kind, 0))
		await _act("slide " + kind, func(): world.cam.global_position += Vector3(2.0, 0, 2.0))
	await _act("cancel", func(): hud.placement.finish(false))


func _act(what: String, f: Callable) -> void:
	await get_tree().process_frame
	var t0 := Time.get_ticks_usec()
	f.call()
	var call_ms := (Time.get_ticks_usec() - t0) / 1000.0
	# the slowest of the next frames (rendering new things happens there)
	var worst := 0.0
	var prev := Time.get_ticks_usec()
	for i in 6:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		worst = maxf(worst, (now - prev) / 1000.0)
		prev = now
	print("HITCH %-28s call %7.1f ms   worst frame %7.1f ms" % [what, call_ms, worst])
