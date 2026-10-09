extends Node
## Game root: the world and the UI on top.

var world: World
var ui: Control


func _ready() -> void:
	var a := Shot.args()
	if a.has("fresh"):
		Game.reset_state()
	if a.has("money"):
		Game.money = int(a["money"])
	if a.has("level"):
		Game.level = int(a["level"])
	for b in a.get("build", "").split(",", false):
		Game.buildings[b] = true
	if a.has("demo"):
		_demo_state()
	world = World.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	if ResourceLoader.exists("res://ui/hud.gd"):
		ui = load("res://ui/hud.gd").new()
		ui.set("world", world)
		layer.add_child(ui)
	Sfx.start_music()
	if a.has("cam"):
		var p: PackedStringArray = a["cam"].split(",")
		world.player.global_position = Vector3(float(p[0]), 0, float(p[1]))
		world.cam.snap()
	if a.has("zoom"):
		world.cam.zoom = float(a["zoom"])
	if a.has("bot"):
		var bot := Bot.new()
		bot.world = world
		add_child(bot)
	if a.has("tscale"):
		Engine.time_scale = float(a["tscale"])
	if a.has("panel"):
		match a["panel"]:
			"upgrades": ui.call("open_sheet", UpgradePanel.new())
			"workers": ui.call("_open_workers")
			"settings": ui.call("open_sheet", SettingsPanel.new())
	Shot.attach(self)


## A mid-game factory for screenshots and testing (--demo).
func _demo_state() -> void:
	Game.reset_state()
	Game.no_save = true
	Game.money = 12500
	Game.level = 7
	Game.xp = 140
	Game.tutorial_step = 99
	for b in ["cabin", "pantry", "shelf", "dock2", "line2"]:
		Game.buildings[b] = true
	for ing in Defs.INGREDIENTS:
		Game.upgrades["farm_" + ing] = 11
	for id in ["carry", "speed", "belt", "oven", "hopper", "truck", "batch", "cabin", "wcarry", "wspeed"]:
		Game.upgrades[id] = 3
	var roles := [["farmer", "wheat"], ["farmer", "milk"], ["gatherer", ""], ["gatherer", ""], ["feeder", ""], ["feeder", ""], ["collector", ""], ["loader", ""], ["", ""]]
	var i := 1
	for r in roles:
		Game.workers.append({"id": i, "role": r[0], "target": r[1]})
		i += 1
	Game.next_worker_id = i
	Game.hired = i - 1
	var ws := {}
	for ing in Defs.INGREDIENTS:
		ws["farm_" + ing] = 12
		ws["pantry_" + ing] = 14
		ws["hop0_" + ing] = 14
		ws["hop1_" + ing] = 9
	ws["tray0"] = 12
	ws["tray1"] = 7
	ws["shelf"] = 40
	ws["dock0"] = 18
	ws["carry"] = ["cookie", "cookie", "cookie", "cookie", "cookie", "cookie", "cookie", "cookie"]
	Game.world_state = ws
