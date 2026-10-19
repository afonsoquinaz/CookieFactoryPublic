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
	if a.has("space"):
		_space_state()
	if a.has("tut"):
		Game.tutorial_step = int(a["tut"])
	if a.has("level"):
		Game.level = int(a["level"])
		Game.stats["earned"] = float(Defs.EMPIRE[Game.level - 1]["xp"])
	if a.has("showcase"):
		_showcase(int(a.get("tier", "-1")), a.has("top"))
	if a.has("era"):
		# preview an era: the Lab level it starts at, paved straight away
		Game.level = int(Defs.ERAS[clampi(int(a["era"]), 0, Defs.ERAS.size() - 1)]["level"])
		Game.stats["tokens"] = maxf(float(Game.stats["tokens"]), float(Defs.EMPIRE[Game.level - 1]["xp"]))
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
			"market": ui.call("open_sheet", MarketPanel.new())
			"shop": ui.call("open_sheet", ShopPanel.new())
			"today", "league", "pass", "events", "album", "me": ui.call("open_live", a["panel"])
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


## The space age for screenshots (--demo --space): a Launch Complex, two
## Ground Stations and four modules in orbit.
func _space_state() -> void:
	Game.money = 2e8
	for c in [Vector2i(-3, -1), Vector2i(-3, 0), Vector2i(-3, -2), Vector2i(-4, -1), Vector2i(-4, 0), Vector2i(-4, -2)]:
		Game.land[Game.chunk_key(c)] = true
	Game.place("launchpad", Vector2i(-22, -6), 0, {"lvl": 6}, false)
	Game.place("groundstation", Vector2i(-26, -5), 0, {"lvl": 4}, false)
	Game.place("groundstation", Vector2i(-17, -5), 0, {"lvl": 2}, false)
	Market.orbit_modules = 4
	Market.orbit_model = "chat13"


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
			"server":
				b["lvl"] = 8
				b["gpus"] = 4
				b["hbm"] = 1
				b["recipe"] = "chat13"
				b["data"] = {"cells": ["power", "power", "power", "power", "power", "power", "power", "power", "power", "power", "power", "power"], "coolant": ["coolant", "coolant", "coolant", "coolant", "coolant", "coolant"], "tune": 0.6}
			"src_power": b["lvl"] = 12
			"gateway":
				b["lvl"] = 9
				b["fiber"] = 2
	# north of the High Street, facing it
	Game.place("src_data", Vector2i(-10, -5), 0, {"lvl": 10}, false)
	Game.place("src_silicon", Vector2i(-14, -5), 0, {"lvl": 6}, false)
	Game.place("src_copper", Vector2i(-10, -9), 0, {"lvl": 5}, false)
	Game.place("src_coolant", Vector2i(-6, -9), 0, {"lvl": 4}, false)
	Game.place("fab", Vector2i(7, -4), 0, {"lvl": 2}, false)
	Game.place("refinery", Vector2i(10, -4), 0, {"lvl": 3}, false)
	Game.place("depot", Vector2i(13, -4), 0, {"lvl": 2}, false)
	# south of it, facing north
	Game.place("hut", Vector2i(7, 2), 2, {}, false)
	Game.place("cafe", Vector2i(9, 2), 2, {"lvl": 6}, false)
	Game.place("gateway", Vector2i(13, 2), 2, {"lvl": 4}, false)
	Game.place("desk", Vector2i(-7, 2), 2, {}, false)
	Game.place("substation", Vector2i(-15, 3), 0, {}, false)
	Game.place("rack_row", Vector2i(-1, -7), 0, {}, false)
	Game.place("net_cab", Vector2i(-3, -3), 0, {}, false)
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
	_demo_live()


## The daily layer mid-week, for screenshots: a streak, quests under way,
## crates in every state, a league week, a Pass season, an inbox message.
func _demo_live() -> void:
	Live.reset_state()
	Live.profile["name"] = "Nimbus Garage"
	Live.profile["logo"] = 3
	Live.tick()
	Live.streak = 12
	Live.streak_best = 12
	Live.last_goal_day = Live.today() - 1
	Live.goal_days = []
	for k in range(1, 13):
		Live.goal_days.append(Live.today() - k)
	Live.freeze_days = [Live.today() - 4]
	Live.goal_days.erase(Live.today() - 4)
	Live.freezes = 1
	Live.goal_got = int(Live.goal * 0.6)
	Live.day_counts = {}
	var q0: Dictionary = Live.quests[0]
	Live.day_counts[LiveDefs.QUESTS[q0["id"]]["metric"]] = float(q0["n"])
	Live.quests[1]["claimed"] = false
	Live.stamps = 4
	Live.login_idx = 3
	Live.crates = [
		{"kind": "server", "seed": 11, "state": "ready", "end": 0},
		{"kind": "gpu", "seed": 12, "state": "unlocking", "end": Live.now() + 5 * 3600 + 1234},
		{"kind": "supply", "seed": 13, "state": "locked", "end": 0},
	]
	Live.boosters = {"warp15": 2, "warp60": 1, "overclock": 1}
	Live.league["tier"] = 3
	Live.league["best"] = 3
	Live.league["joined"] = true
	Live.league["points"] = 640
	Live.season["sp"] = 1340
	Live.counters = {"quests": 34.0, "crates": 9.0, "upgrades": 62.0}
	Live.badges = {"quests": 1}
	Live.mastery = {"pico": 4200, "mini": 1300, "chat7": 240, "chat13": 60}
	Live.mastery_claimed = {"pico": 2}
	Live.add_msg("League week over", "You finished #3 in the Gold League with 1,240 points. Promoted to Sapphire!", "trophy", {"gems": 8, "crate": "server"})


## Every building kind laid out in rows (--showcase[=tier]) for art reviews;
## --top puts each at its top level (all its Growth gear).
func _showcase(tier: int, top := false) -> void:
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
		if top:
			l = Bal.max_level(kind)
		var extra := {"lvl": l}
		if kind == "mega":
			extra["stage"] = 4
		Game.place(kind, Vector2i(cx, cy), 0, extra, false)
		cx += sz.x + 1
		row_h = maxi(row_h, sz.y)
		i += 1
