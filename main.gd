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
	if a.has("demo"):
		_demo_state()
	if a.has("tut"):
		Game.tutorial_step = int(a["tut"])
	if a.has("level"):
		Game.level = int(a["level"])
		Game.stats["earned"] = float(Defs.EMPIRE[Game.level - 1]["xp"])
	if a.has("showcase"):
		_showcase(int(a.get("tier", "-1")))
	world = World.new()
	add_child(world)
	var layer := CanvasLayer.new()
	add_child(layer)
	if ResourceLoader.exists("res://ui/hud.gd"):
		ui = load("res://ui/hud.gd").new()
		ui.set("world", world)
		layer.add_child(ui)
	Sfx.start_music()
	var menu := not a.has("shot") and not a.has("bot") and not a.has("nomenu")
	if a.has("title"):
		menu = true
	if menu:
		ui.call("show_title")
	else:
		ui.call("skip_title")
	if a.has("cam"):
		var p: PackedStringArray = a["cam"].split(",")
		world.cam.global_position = Vector3(float(p[0]), 0, float(p[1]))
		world.cam.snap()
	if a.has("zoom"):
		world.cam.zoom = float(a["zoom"])
	if a.has("bot"):
		# loaded by path so exports can leave tests/ out
		var bot: Node = load("res://tests/bot.gd").new()
		bot.set("world", world)
		add_child(bot)
	if a.has("place"):
		ui.call("start_placement", a["place"], 0)
	if a.has("select"):
		for n in world.bnodes.values():
			if n.kind == a["select"]:
				world.cam.global_position = n.global_position + Vector3(0, 0, 3)
				ui.call("select", n)
				if a.has("info"):
					ui.call("open_building", n)
				break
	if a.has("recipes"):
		for n in world.bnodes.values():
			if n is ServerB:
				ui.call("open_recipes", n)
				break
	if a.has("tscale"):
		Engine.time_scale = float(a["tscale"])
	if a.has("panel"):
		match a["panel"]:
			"research": ui.call("open_sheet", ResearchPanel.new())
			"staff": ui.call("open_staff")
			"build": ui.call("open_build")
			"settings": ui.call("open_sheet", SettingsPanel.new())
	if a.has("startup"):
		add_child(load("res://dev/startup.gd").new())
	if a.has("tris"):
		add_child(load("res://dev/tris.gd").new())
	if a.has("perf"):
		add_child(load("res://dev/perf.gd").new())
	if a.has("dbg"):
		add_child(load("res://dev/dbg.gd").new())
	if a.has("tour"):
		add_child(load("res://dev/tour.gd").new())
	if a.has("roadbench"):
		add_child(load("res://dev/roadbench.gd").new())
	if a.has("panelbench"):
		add_child(load("res://dev/panelbench.gd").new())
	if a.has("hitch"):
		add_child(load("res://dev/hitch.gd").new())
	if a.has("film"):
		add_child(load("res://dev/film.gd").new())
	if a.has("wdbg"):
		add_child(load("res://dev/wdbg.gd").new())
	Shot.attach(self)


## A mid-game empire for screenshots and testing (--demo).
func _demo_state() -> void:
	Game.reset_state()
	Game.no_save = true
	Game.money = 48000
	Game.gems = 37
	Game.tutorial_step = 99
	Game.stats["tokens"] = 6000
	Game.stats["earned"] = 30000.0
	Game.level = Game.level_for(6000.0)
	Game.obstacles.clear()
	for c in [Vector2i(1, -1), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(-1, -2), Vector2i(-2, -2)]:
		Game.land[Game.chunk_key(c)] = true
	Game.land_bought_n = 8
	for b in Game.buildings:
		match b["kind"]:
			"server": b["lvl"] = 8
			"src_power": b["lvl"] = 12
			"van": b["lvl"] = 9
	# north of the High Street, facing it
	Game.place("src_data", Vector2i(-10, -5), 0, {"lvl": 10}, false)
	Game.place("src_silicon", Vector2i(-14, -5), 0, {"lvl": 6}, false)
	Game.place("src_copper", Vector2i(-10, -9), 0, {"lvl": 5}, false)
	Game.place("src_coolant", Vector2i(-6, -9), 0, {"lvl": 4}, false)
	Game.place("fab", Vector2i(7, -4), 0, {"lvl": 2}, false)
	Game.place("refinery", Vector2i(10, -4), 0, {"lvl": 3}, false)
	Game.place("cache", Vector2i(13, -4), 0, {"lvl": 2}, false)
	# south of it, facing north
	Game.place("hut", Vector2i(7, 2), 2, {}, false)
	Game.place("cafe", Vector2i(9, 2), 2, {"lvl": 6}, false)
	Game.place("van", Vector2i(13, 2), 2, {"lvl": 4}, false)
	Game.place("desk", Vector2i(-7, 2), 2, {}, false)
	Game.place("substation", Vector2i(-15, 3), 0, {}, false)
	Game.place("planter", Vector2i(8, 5), 0, {}, false)
	Game.place("lamp", Vector2i(12, 1), 0, {}, false)
	Game.place("lamp", Vector2i(-2, 1), 0, {}, false)
	Game.place("tree", Vector2i(12, 6), 0, {}, false)
	Game.place("coffee", Vector2i(-1, 9), 0, {}, false)
	var s := Game.place("src_code", Vector2i(2, -9), 0, {"lvl": 0}, false)
	Game._start_job("build", int(s["uid"]), 90.0)
	for b in Game.buildings:
		if b["kind"] == "server":
			Game._start_job("upgrade", int(b["uid"]), 600.0)
	for r in ["mini", "chat7", "chat13", "wiki13", "code13"]:
		Game.known_recipes[r] = true
	for i in 5:
		Game.workers.append({"id": Game.next_worker_id, "role": "courier", "target": 0})
		Game.next_worker_id += 1
	Game.hired = 5
	Game.obstacles["4,10"] = {"kind": "oak", "gems": 2}
	Game.obstacles["2,13"] = {"kind": "rock", "gems": 1}


## Every building kind laid out in rows (--showcase[=tier]) for art reviews.
func _showcase(tier: int) -> void:
	Game.reset_state()
	Game.no_save = true
	Game.buildings.clear()
	Game.obstacles.clear()
	Game.money = 1e12
	Game.tutorial_step = 99
	for x in range(-3, 3):
		for y in range(-3, 3):
			Game.land[Game.chunk_key(Vector2i(x, y))] = true
	var lv := [1, 5, 12, 25, 40]
	var x0 := -22
	var cx := x0
	var cy := -22
	var row_h := 0
	var i := 0
	for kind in Defs.BUILD_ORDER:
		var sz: Vector2i = Defs.BUILDINGS[kind]["size"]
		if cx + sz.x > 22:
			cx = x0
			cy += row_h + 2
			row_h = 0
		# keep the High Street clear
		if cy <= Roads.STREET_Y + 1 and cy + sz.y > Roads.STREET_Y:
			cy = Roads.STREET_Y + 3
		var t := tier if tier >= 0 else i % 5
		var l: int = mini(lv[t] if Defs.BUILDINGS[kind]["cat"] != "source" else [1, 5, 10, 20, 35][t], Bal.max_level(kind))
		var extra := {"lvl": l}
		if kind == "mega":
			extra["stage"] = 4
		Game.place(kind, Vector2i(cx, cy), 0, extra, false)
		cx += sz.x + 1
		row_h = maxi(row_h, sz.y)
		i += 1
