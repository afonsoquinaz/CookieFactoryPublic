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
	if a.has("demo"):
		_demo_state()
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
		world.player.global_position = Vector3(float(p[0]), 0, float(p[1]))
		world.cam.snap()
	if a.has("zoom"):
		world.cam.zoom = float(a["zoom"])
	if a.has("bot"):
		# loaded by path so exports can leave tests/ out
		var bot: Node = load("res://tests/bot.gd").new()
		bot.set("world", world)
		add_child(bot)
	if a.has("route"):
		world.show_route(a["route"])
	if a.has("place"):
		var pk: PackedStringArray = a["place"].split(":")
		ui.call("start_placement", pk[0], pk[1] if pk.size() > 1 else "", 0)
	if a.has("select"):
		for n in world.bnodes.values():
			if n.kind == a["select"]:
				ui.call("open_building", n)
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
	if a.has("pp"):
		add_child(load("res://dev/pp.gd").new())
	if a.has("wdbg"):
		add_child(load("res://dev/wdbg.gd").new())
	Shot.attach(self)


## A mid-game factory for screenshots and testing (--demo).
func _demo_state() -> void:
	Game.reset_state()
	Game.no_save = true
	Game.money = 48000
	Game.level = 12
	Game.tutorial_step = 99
	Game.gems = 7
	Game.stats["cookies"] = 900
	Game.stats["earned"] = 30000.0
	for c in [Vector2i(1, -1), Vector2i(1, 0), Vector2i(-2, -1), Vector2i(-2, 0), Vector2i(-1, 1), Vector2i(0, 1)]:
		Game.land[Game.chunk_key(c)] = true
	Game.land_bought_n = 6
	for b in Game.buildings:
		b["lvl"] = 6 if b["kind"] != "tube" else 1
	# a second line making chocolate chip: mixer, sugar, egg, chocolate hoppers, oven
	var x := -2
	var z := 0
	Game.place("mixer", Vector2i(x, z), 0, {"lvl": 11}, false)
	Game.place("hopper", Vector2i(x + 1, z), 0, {"ing": "sugar", "lvl": 8}, false)
	Game.place("hopper", Vector2i(x + 2, z), 0, {"ing": "egg", "lvl": 8}, false)
	Game.place("hopper", Vector2i(x + 3, z), 0, {"ing": "chocolate", "lvl": 8}, false)
	Game.place("oven", Vector2i(x + 4, z), 0, {"lvl": 13}, false)
	# farms and kitchens
	Game.place("farm_sugar", Vector2i(-10, -6), 0, {"lvl": 12}, false)
	Game.place("farm_egg", Vector2i(-14, -6), 0, {"lvl": 21}, false)
	Game.place("farm_cocoa", Vector2i(-10, -2), 0, {"lvl": 8}, false)
	Game.place("farm_milk", Vector2i(-14, -2), 0, {"lvl": 36}, false)
	Game.place("chocolatier", Vector2i(-6, -2), 0, {"lvl": 6}, false)
	Game.place("churn", Vector2i(-6, 1), 0, {"lvl": 2}, false)
	Game.place("pantry", Vector2i(-9, 2), 0, {"lvl": 4}, false)
	Game.place("rack", Vector2i(8, -1), 0, {"lvl": 4}, false)
	Game.place("packer", Vector2i(8, 2), 0, {"lvl": 5}, false)
	Game.place("shop", Vector2i(4, 3), 0, {"lvl": 13}, false)
	Game.place("dock", Vector2i(11, -6), 0, {"lvl": 25}, false)
	Game.place("cabin", Vector2i(-14, 2), 0, {"lvl": 3}, false)
	Game.place("board", Vector2i(1, 4), 0, {}, false)
	Game.place("well", Vector2i(-11, -3), 0, {}, false)
	Game.place("flowers", Vector2i(3, 5), 0, {}, false)
	Game.place("lamp", Vector2i(7, 3), 0, {}, false)
	Game.place("tree", Vector2i(7, 5), 0, {}, false)
	Game.place("fountain", Vector2i(-3, 5), 0, {}, false)
	for r in ["sugar", "cocoa", "milk", "butter", "choc"]:
		Game.known_recipes[r] = true
	var roles := [["gatherer", 0], ["gatherer", 0], ["feeder", 0], ["feeder", 0], ["collector", 0], ["loader", 0], ["", 0]]
	var i := 1
	for r in roles:
		Game.workers.append({"id": i, "role": r[0], "target": r[1]})
		i += 1
	Game.next_worker_id = i
	Game.hired = i - 1
	Game.player_state = {"x": 2.0, "z": 3.0, "carry": ["c:choc", "c:choc", "c:choc", "c:choc", "c:choc", "c:choc"]}


## Every building kind laid out in rows (--showcase[=tier]) for art reviews.
func _showcase(tier: int) -> void:
	Game.reset_state()
	Game.no_save = true
	Game.buildings.clear()
	Game.money = 1e12
	Game.level = 60
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
		if kind == "tube":
			continue
		var sz: Vector2i = Defs.BUILDINGS[kind]["size"]
		if cx + sz.x > 22:
			cx = x0
			cy += row_h + 1
			row_h = 0
		var t := tier if tier >= 0 else i % 5
		var l: int = mini(lv[t] if Defs.BUILDINGS[kind]["cat"] != "farm" else [1, 5, 10, 20, 35][t], Bal.max_level(kind))
		var extra := {"lvl": l}
		if kind == "hopper":
			extra["ing"] = "chocolate"
		if kind == "palace":
			extra["stage"] = 4
		Game.place(kind, Vector2i(cx, cy), 0, extra, false)
		cx += sz.x + 1
		row_h = maxi(row_h, sz.y)
		i += 1
	Game.player_state = {"x": 0.0, "z": -20.0}
