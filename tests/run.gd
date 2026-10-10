extends Node
## Headless logic tests. Run: tools/test.sh
## Covers the data tables (every building, recipe and item is complete and
## reachable), balance curves, Game state (the Cookie Hall, builders and
## timers, placing, upgrading, finishing with gems, obstacles, land, staff,
## orders), save round-trip with time away, holders, the grid, the road
## network, and a real World where the bakery bakes, porters keep it fed,
## construction sites turn into buildings and every building spawns.

var _fails := 0
var _checks := 0


func _ready() -> void:
	Game.no_save = true
	Game.reset_state()
	_test_tables()
	_test_balance()
	_test_game_state()
	_test_save_roundtrip()
	_test_grid()
	_test_roads_unit()
	await _test_holders()
	await _test_world()
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("FAIL: ", what)


# ---------------------------------------------------------------- data

func _test_tables() -> void:
	for k in Defs.BUILD_ORDER:
		ok(Defs.BUILDINGS.has(k), "build order lists a real building: " + k)
	var tabs := {}
	for t in Defs.TABS:
		tabs[t[0]] = true
	for k in Defs.BUILDINGS:
		var d: Dictionary = Defs.BUILDINGS[k]
		ok(Defs.BUILD_ORDER.has(k) or k == "hall", "%s is in the build menu" % k)
		ok(Icons.tex(d["icon"]) != null, "icon for building " + k)
		for f in ["name", "cat", "tab", "size", "hall", "cost", "growth", "up", "max", "time", "desc"]:
			ok(d.has(f), "%s has %s" % [k, f])
		ok(tabs.has(d["tab"]), "%s is on a real tab" % k)
		ok(int(d["hall"]) >= 1 and int(d["hall"]) <= Defs.HALL.size(), "%s unlocks at a real Hall level" % k)
		if d.has("n"):
			ok(int(d["n"][0]) == int(d["hall"]), "%s: first copy at its unlock level" % k)
			var prev := 0
			for h in d["n"]:
				ok(int(h) >= prev, "%s: copies unlock in order" % k)
				prev = int(h)
		ok(Previews.mesh(k).get_surface_count() > 0, "preview mesh for " + k)
		if d.has("in"):
			for t in d["in"]:
				ok(Defs.ITEMS.has(t), "%s input %s is an item" % [k, t])
			for t in d["out"]:
				ok(Defs.PROCESSED.has(t), "%s output %s is processed" % [k, t])
			ok(d.has("craft"), "%s has a craft time" % k)
	for t in Defs.ITEMS:
		ok(Icons.tex(t) != null, "icon for item " + t)
		ok(t == "wheat" or Defs.producer_of(t) != "", "something produces " + t)
		ok(Items.mesh(t).get_surface_count() > 0, "mesh for item " + t)
	var seen := {}
	for r in Defs.RECIPES:
		ok(not seen.has(r["id"]), "recipe id unique " + r["id"])
		seen[r["id"]] = true
		ok(Icons.tex("ck_" + r["id"]) != null, "cookie icon for " + r["id"])
		ok(Defs.COOKIE_LOOK.has(r["id"]), "cookie look for " + r["id"])
		for i in r["ings"]:
			ok(Defs.ITEMS.has(i) and i != "wheat", "%s uses a real non-wheat ingredient %s" % [r["id"], i])
		ok(Defs.recipe_level(r["id"]) <= Defs.HALL.size(), "%s can be baked before the last Hall" % r["id"])
		ok((r["ings"] as Array).size() <= 7, "%s fits in a bakery (7 silos)" % r["id"])
		ok(Defs.slots_level((r["ings"] as Array).size()) <= Bal.max_level("bakery"), "a bakery can grow enough silos for " + r["id"])
	for role in Defs.ROLE_ORDER:
		ok(Icons.tex(Defs.ROLES[role]["icon"]) != null, "icon for role " + role)
	for k in Defs.OBSTACLES:
		ok(TownArt.obstacle(k).get_surface_count() > 0, "mesh for obstacle " + k)
	for i in Defs.HALL.size():
		ok(TownArt.hall(Bal.tier("hall", i + 1), i + 1).get_surface_count() > 0, "hall look at level %d" % (i + 1))
	ok(Defs.LEVEL_TITLES.size() >= Defs.HALL.size(), "a title for every Hall level")


func _test_balance() -> void:
	for l in range(2, Defs.HALL.size()):
		ok(float(Defs.HALL[l]["cost"]) > float(Defs.HALL[l - 1]["cost"]), "hall %d costs more than %d" % [l + 1, l])
		ok(float(Defs.HALL[l]["time"]) >= float(Defs.HALL[l - 1]["time"]), "hall %d takes at least as long" % (l + 1))
	for k in Defs.BUILDINGS:
		var mx := Bal.max_level(k)
		if mx <= 1 or k == "hall":
			continue
		ok(Bal.upgrade_time(k, 1) <= maxf(30.0, Bal.build_time(k, 0)), "%s: first upgrade is no slower than building it (%.0fs)" % [k, Bal.upgrade_time(k, 1)])
		ok(Bal.upgrade_time(k, mx - 1) >= 3600.0, "%s: top upgrades take hours" % k)
		ok(Bal.upgrade_time(k, mx - 1) <= 9.0 * 3600.0, "%s: but at most ~8h" % k)
		var prev := 0.0
		for l in range(1, mx):
			var t := Bal.upgrade_time(k, l)
			ok(t >= prev, "%s: upgrade %d takes no less than %d" % [k, l, l - 1])
			prev = t
			ok(Bal.upgrade_cost(k, l + 1) >= Bal.upgrade_cost(k, l), "%s: upgrades cost more each level" % k)
		ok(Bal.level_cap(k, 15) == mx, "%s: the last Hall allows max level" % k)
	ok(Bal.finish_gems(10.0) == 0 and Bal.finish_gems(30.0) == 0, "short jobs finish free")
	ok(Bal.finish_gems(60.0) >= 1 and Bal.finish_gems(3600.0) > Bal.finish_gems(600.0), "longer jobs cost more gems")
	ok(Defs.bakery_slots(1) == 1 and Defs.bakery_slots(4) == 2 and Defs.bakery_slots(40) == 7, "bakery silos grow with level")
	ok(Defs.max_count("farm_wheat", 1) == 1 and Defs.max_count("farm_wheat", 2) == 2, "more wheat fields as the Hall grows")
	ok(Defs.max_count("farm_egg", 2) == 0, "hen houses are locked before Hall 3")
	ok(Defs.max_count("flowers", 1) == -1, "decor is unlimited")
	ok(Defs.max_count("hut", 1) == 2 and Defs.max_count("hut", 9) == 5, "builder huts: 2 at first, 5 at the most")


# ---------------------------------------------------------------- game state

func _test_game_state() -> void:
	Game.reset_state()
	ok(Game.level == 1 and Game.count_of("hall") == 1, "a new empire has a level 1 Cookie Hall")
	for k in ["bakery", "farm_wheat", "dock"]:
		ok(Game.count_ready(k) == 1, "a new empire has a ready " + k)
	ok(Game.builders() == 2 and Game.free_builders() == 2, "two builders to start")
	ok(Game.workers_with("porter") == 3, "three porters to start")
	ok(Game.obstacles.size() >= 5, "obstacles to clear on the starting land")
	ok(Game.build_block("farm_egg").contains("Hall"), "locked buildings say which Hall")
	ok(Game.build_block("farm_wheat").contains("Hall 2") or Game.build_block("farm_wheat").contains("level 2"), "the second wheat field waits for Hall 2: " + Game.build_block("farm_wheat"))
	Game.money = 1000.0
	ok(Game.build_block("farm_sugar") == "", "a sugar field can be built")
	var b := Game.place("farm_sugar", Vector2i(-7, 3), 0)
	ok(not b.is_empty() and int(b["lvl"]) == 0, "a new building starts under construction")
	ok(Game.jobs.size() == 1 and Game.free_builders() == 1, "a builder is busy on it")
	ok(Game.count_ready("farm_sugar") == 0 and not Game.can_make("sugar"), "not working while being built")
	Game.clock += 2.0
	Game._check_jobs()
	ok(int(b["lvl"]) == 0, "still being built after 2 s")
	Game.clock += Bal.build_time("farm_sugar", 0)
	Game._check_jobs()
	ok(int(b["lvl"]) == 1 and Game.jobs.is_empty() and Game.can_make("sugar"), "built when the timer runs out")
	# upgrades take a builder and time; the Hall caps levels
	var bk: Dictionary = {}
	for x in Game.buildings:
		if x["kind"] == "bakery":
			bk = x
	var uid := int(bk["uid"])
	ok(Game.upgrade(uid), "bakery upgrade starts")
	ok(int(bk["lvl"]) == 1 and Game.job_of(uid).size() > 0, "upgrade in progress")
	ok(Game.upgrade_block(uid) != "", "can't upgrade twice at once")
	ok(Game.finish_now(Game.job_of(uid)), "short job finishes free")
	ok(int(bk["lvl"]) == 2, "bakery reached level 2")
	bk["lvl"] = Bal.level_cap("bakery", 1)
	ok(Game.upgrade_block(uid).contains("Hall"), "the Hall caps building levels")
	# the Hall
	var h := Game.hall()
	var gems0 := Game.gems
	Game.money = 1e6
	ok(Game.upgrade(int(h["uid"])), "hall upgrade starts")
	Game.clock += 1000.0
	Game._check_jobs()
	ok(Game.level == 2 and Game.gems > gems0, "hall level 2, with gems")
	ok(Game.build_block("farm_cocoa") == "", "Hall 2 unlocks the cocoa grove")
	# both builders busy
	Game.upgrade(int(h["uid"]))
	Game.place("farm_wheat", Vector2i(3, -8), 0)
	ok(Game.free_builders() == 0, "both builders busy")
	ok(Game.build_block("farm_cocoa").contains("builder"), "no free builder: can't build")
	Game.gems = 0
	var long := {}
	for j in Game.jobs:
		if Game.job_left(j) > 60.0:
			long = j
	ok(long.is_empty() or not Game.finish_now(long), "finishing a long job needs gems")
	Game.gems = 500
	ok(long.is_empty() or Game.finish_now(long), "with gems it finishes now")
	Game.clock += 100000.0
	Game._check_jobs()
	ok(Game.jobs.is_empty(), "all jobs done")
	# obstacles
	var key: String = Game.obstacles.keys()[0]
	var g0 := Game.gems
	var gift := int(Game.obstacles[key]["gems"])
	ok(Game.clear_obstacle(key), "clear an obstacle")
	Game.clock += 100.0
	Game._check_jobs()
	ok(not Game.obstacles.has(key) and Game.gems == g0 + gift and Game.cleared == 1, "cleared, with its gems")
	# land
	var n0 := Game.obstacles.size()
	ok(Game.buy_chunk(Vector2i(1, 0)), "buy a plot next to yours")
	ok(Game.obstacles.size() > n0, "new land comes with obstacles")
	ok(not Game.can_buy_chunk(Vector2i(5, 5)), "plots far away can't be bought")
	# staff
	ok(Game.assign_porter("farmer", 7), "a porter becomes a farmer")
	ok(Game.workers_with("farmer", 7) == 1 and Game.workers_with("porter") == 2, "one farmer, two porters")
	Game.assign_porter("chef", 8)
	ok(not Game.assign_porter("chef", 8), "the last porter stays a porter")
	ok(Game.unassign("chef", 8) and Game.workers_with("porter") == 2, "back to portering")
	Game.money = 1e9
	var cap := Game.cabin_capacity()
	while Game.can_hire():
		Game.hire()
	ok(Game.workers.size() == cap, "hire up to what you can house")
	# orders
	Game.place("board", Vector2i(-6, 6), 0, {}, false)
	Game.known_recipes["sugar"] = true
	Game.refill_orders()
	ok(Game.orders.size() == Game.order_slots(), "the board fills with orders")
	var o: Dictionary = Game.orders[0]
	var g1 := Game.gems
	for i in int(o["count"]):
		Game.deliver(o["item"])
	ok(Game.gems > g1, "a finished order pays gems")
	Game.reset_state()


func _test_save_roundtrip() -> void:
	Game.reset_state()
	Game.money = 5000.0
	Game.place("farm_sugar", Vector2i(-7, 3), 0)
	Game.buy_chunk(Vector2i(1, 0))
	var d := Game.to_dict()
	d = JSON.parse_string(JSON.stringify(d))
	Game.from_dict(d)
	ok(Game.count_of("farm_sugar") == 1 and Game.jobs.size() == 1, "save keeps buildings and jobs")
	ok(Game.owns_chunk(Vector2i(1, 0)) and Game.obstacles.size() > 0, "save keeps land and obstacles")
	# an hour away: the build finished
	d["time"] = int(d["time"]) - 3600
	Game.from_dict(d)
	ok(Game.jobs.is_empty() and Game.count_ready("farm_sugar") == 1, "builds finish while you're away")
	ok(Game.offline_seconds >= 3599.0, "time away is known")
	Game.reset_state()


func _test_grid() -> void:
	ok(Grid.rotated(Vector2i(3, 2), 1) == Vector2i(2, 3), "rotation swaps footprint")
	ok(Grid.cell_of(Vector3(-0.1, 0, 3.9)) == Vector2i(-1, 1), "world -> cell")
	var g := Grid.new()
	g.fill(1, Vector2i(0, 0), Vector2i(2, 2), 0)
	ok(g.at(Vector2i(1, 1)) == 1 and g.at(Vector2i(2, 0)) == 0, "occupancy")
	ok(not g.is_free(Vector2i(1, 1), Vector2i(2, 2), 0), "overlap blocked")
	ok(g.is_free(Vector2i(1, 1), Vector2i(2, 2), 0, [1]), "moving ignores itself")
	var cells: Array[Vector2i] = [Vector2i(5, 5)]
	g.set_obstacle("5,5", cells)
	ok(g.blocked(Vector2i(5, 5)) and g.obstacle_at(Vector2i(5, 5)) == "5,5", "obstacles block cells")
	g.clear_obstacle("5,5")
	ok(not g.blocked(Vector2i(5, 5)), "cleared")
	# entrances: the middle of the front edge, one or two cells
	ok(Building.entrance_of("farm_wheat", Vector2i(0, 0), 0) == ([Vector2i(1, 3)] as Array[Vector2i]), "3-wide entrance is one cell in front")
	ok(Building.entrance_of("hall", Vector2i(0, 0), 0).size() == 2, "4-wide entrance is two cells")
	ok(Building.entrance_of("farm_wheat", Vector2i(0, 0), 2) == ([Vector2i(1, -1)] as Array[Vector2i]), "turned around, the entrance is behind")
	ok(Building.entrance_of("flowers", Vector2i(0, 0), 0).is_empty(), "decor has no entrance")


func _test_roads_unit() -> void:
	var r := Roads.new()
	var walls := {}
	for y in range(0, 8):
		walls[Vector2i(5, y)] = true
	var entries := [
		{"uid": 1, "cells": [Vector2i(1, 1)] as Array[Vector2i], "stub": 3, "d": 0},
		{"uid": 2, "cells": [Vector2i(9, 1)] as Array[Vector2i], "stub": 3, "d": 8},
		{"uid": 3, "cells": [Vector2i(9, 9)] as Array[Vector2i], "stub": 3, "d": 16},
	]
	r.build(entries, func(c): return walls.has(c), func(c): return c.x >= 0 and c.y >= 0 and c.x < 12 and c.y < 12, Rect2i(0, 0, 12, 12))
	ok(r.connected.size() == 3, "every entrance joins the hall")
	var crosses := false
	for c in r.cells:
		if walls.has(c):
			crosses = true
	ok(not crosses, "roads never run through buildings")
	ok(r.cells.has(Vector2i(5, 8)) or r.cells.has(Vector2i(5, 9)), "the road goes around the wall")
	ok(r.route(Vector2i(1, 1), Vector2i(9, 9)).size() > 0, "porters can walk from hall to the far building")
	# walled in: no road
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		walls[Vector2i(9, 9) + d] = true
	r.build(entries, func(c): return walls.has(c), func(c): return c.x >= 0 and c.y >= 0 and c.x < 12 and c.y < 12, Rect2i(0, 0, 12, 12))
	ok(not r.connected.has(3), "a walled-in entrance gets no road")


func _test_holders() -> void:
	var a := Holder.new().setup(5, ["wheat"], Holder.Layout.COLUMN)
	var b := Holder.new().setup(2, [], Holder.Layout.COLUMN)
	b.accept_cat = ["raw"]
	add_child(a)
	add_child(b)
	for i in 3:
		a.add("wheat", false)
	ok(not a.can_accept("sugar"), "typed holder refuses other items")
	ok(b.can_accept("wheat") and not b.can_accept("c:sugar") and not b.can_accept("butter"), "category filter")
	ok(Holder.fly(a, b, "wheat", 0.05), "fly starts")
	ok(a.count() == 2 and b.incoming == 1, "item in flight is reserved")
	await get_tree().create_timer(0.2).timeout
	ok(b.count() == 1 and b.incoming == 0, "item landed")
	Holder.fly(a, b, "wheat", 0.05)
	ok(not Holder.fly(a, b, "wheat", 0.05), "full target refuses")
	await get_tree().create_timer(0.2).timeout
	a.queue_free()
	b.queue_free()


# ---------------------------------------------------------------- a real world

func _wait_until(cond: Callable, limit: float, scale := 6.0) -> float:
	Engine.time_scale = scale
	var t := 0.0
	while not cond.call() and t < limit:
		await get_tree().process_frame
		t += get_process_delta_time()
	Engine.time_scale = 1.0
	return t


func _test_world() -> void:
	Game.reset_state()
	Game.money = 1e6
	var w := World.new()
	add_child(w)
	await get_tree().process_frame
	await get_tree().process_frame
	for n in w.bnodes.values():
		if n.has_entrance():
			ok(n.on_road(), "%s is on the road" % n.kind)
	for c in w.roads.cells:
		ok(w.grid.at(c) == 0 and w.grid.obstacle_at(c) == "", "road cell %s is free land" % c)
	var bakery: BakeryB = w.buildings_of("bakery")[0]
	ok(bakery.recipe == "shortbread", "the first bakery bakes shortbread")
	# bake for real
	for i in 3:
		bakery.flour.add("wheat", false)
	var t := await _wait_until(func(): return bakery.tray.count() >= bakery.batch(), 40.0)
	ok(bakery.tray.count() >= bakery.batch(), "the bakery baked a batch (%.1fs)" % t)
	ok(bakery.tray.items[0] == "c:shortbread", "it baked shortbread")
	# porters bring wheat from the field
	bakery.flour.clear_all()
	var farm: FarmB = w.buildings_of("farm_wheat")[0]
	for i in 6:
		farm.crate.add("wheat", false)
	t = await _wait_until(func(): return bakery.flour.count() > 0 or not bakery.doughs.is_empty(), 60.0)
	ok(bakery.flour.count() > 0 or not bakery.doughs.is_empty(), "porters brought wheat along the road (%.1fs)" % t)
	# a sugar field is built by a builder, then the bakery bakes sugar cookies
	var sb := Game.place("farm_sugar", Vector2i(-7, 3), 0)
	await get_tree().process_frame
	var site := w.building(int(sb["uid"]))
	ok(site is SiteB, "a construction site while it's being built")
	ok(site.on_road(), "the site already has its road")
	Game.finish_now(Game.job_of(int(sb["uid"])))
	await get_tree().process_frame
	var built := w.building(int(sb["uid"]))
	ok(built is FarmB, "the site turned into the farm")
	t = await _wait_until(func(): return bakery.recipe == "sugar", 5.0, 1.0)
	ok(bakery.recipe == "sugar", "Auto switched the bakery to sugar cookies")
	ok(bakery.silos.has("sugar"), "a sugar silo")
	bakery.choose("shortbread")
	ok(bakery.recipe == "shortbread" and not bakery.silos.has("sugar"), "choosing a recipe changes the silos")
	bakery.choose("")
	# a building on top of a road: the road goes around
	var before := w.roads.connected.size()
	var road_cell: Vector2i = w.roads.cells.keys()[w.roads.cells.size() / 2]
	var spot := w.check_spot("flowers", road_cell, 0)
	if spot["ok"]:
		Game.place("flowers", road_cell, 0)
		await get_tree().process_frame
		await get_tree().process_frame
		ok(not w.roads.is_road(road_cell), "no road under the new flower bed")
		ok(w.roads.connected.size() >= before - 0, "everything still connected (%d / %d)" % [w.roads.connected.size(), before])
	# a building that would wall another off can't go there
	var cut_ok := true
	for n in w.bnodes.values():
		if n.has_entrance() and n != w.hall():
			var path: Array = w.roads.paths.get(n.uid, [])
			if path.size() > 2:
				var c2: Vector2i = path[path.size() / 2]
				var s2 := w.check_spot("flowers", c2, 0)
				# either it's fine (another way round) or it says what it would cut off
				if not s2["ok"] and not str(s2["reason"]).contains("cut off") and not str(s2["reason"]).contains("entrance"):
					cut_ok = false
	ok(cut_ok, "spots on roads are refused only for a reason")
	# entrances must stay clear
	var h := w.hall()
	var e: Vector2i = h.entrance_cells()[0]
	ok(not w.check_spot("flowers", e, 0)["ok"], "can't build on the Hall's entrance")
	# every kind of building spawns, answers the info panel and shows every look
	Game.money = 1e15
	Game.level = 15
	Game.hall()["lvl"] = 15
	for c in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 0), Vector2i(3, 1)]:
		Game.land[Game.chunk_key(c)] = true
	var cx := 4
	var cy := 10
	for kind in Defs.BUILD_ORDER:
		if kind == "hall":
			continue
		var sz: Vector2i = Defs.BUILDINGS[kind]["size"]
		if cx + sz.x > 60:
			cx = 4
			cy += 7
		var b := Game.place(kind, Vector2i(cx, cy), 0, {"stage": 0} if kind == "palace" else {}, false)
		cx += sz.x + 1
		await get_tree().process_frame
		var n := w.building(int(b["uid"]))
		ok(n != null, "spawned " + kind)
		if n == null:
			continue
		ok(n.status() is String and n.info() is Array and n.upgrade_info() is Array, "info for " + kind)
		for lv in [5, 12, 25, 40]:
			if lv <= Bal.max_level(kind):
				b["lvl"] = lv
				n.refresh()
		ok(n.visual != null and is_instance_valid(n.visual), "top look for " + kind)
	await get_tree().process_frame
	w.queue_free()
	await get_tree().process_frame
	Game.reset_state()
