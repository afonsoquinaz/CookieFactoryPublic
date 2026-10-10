extends Node
## Headless logic tests. Run: tools/test.sh
## Covers the data tables (every building, recipe and item is complete and
## reachable), balance curves, Game state (placing, moving, selling,
## upgrading, land, research, orders), save round-trip, holders, the grid,
## and a real World where lines connect, bake, and workers keep them fed.

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
	for k in Defs.BUILDINGS:
		var d: Dictionary = Defs.BUILDINGS[k]
		ok(Defs.BUILD_ORDER.has(k), "%s is in the build menu" % k)
		ok(Icons.tex(d["icon"]) != null, "icon for building " + k)
		for f in ["name", "cat", "size", "lvl", "cost", "growth", "up", "max", "desc"]:
			ok(d.has(f), "%s has %s" % [k, f])
		ok(Previews.mesh(k).get_surface_count() > 0, "preview mesh for " + k)
		if d.has("in"):
			for t in d["in"]:
				ok(Defs.ITEMS.has(t), "%s input %s is an item" % [k, t])
			for t in d["out"]:
				ok(Defs.PROCESSED.has(t), "%s output %s is processed" % [k, t])
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
			ok(Defs.ITEMS.has(i) and i != "wheat", "recipe %s ingredient %s" % [r["id"], i])
		ok(Defs.recipe_level(r["id"]) <= 40, "recipe %s reachable before level 40" % r["id"])
		for c in ["c", "b", "g"]:
			ok(Items.mesh("%s:%s" % [c, r["id"]]).get_surface_count() > 0, "mesh for %s:%s" % [c, r["id"]])
	# the best recipe always grows in value as recipes unlock
	var prev := 0.0
	for r in Defs.RECIPES:
		ok(float(r["price"]) > prev, "recipe prices rise: " + r["id"])
		prev = float(r["price"])
	for r in Defs.ROLE_ORDER:
		ok(Icons.tex(Defs.ROLES[r]["icon"]) != null, "icon for role " + r)
	for id in Bal.RESEARCH:
		ok(Icons.tex(Bal.RESEARCH[id]["icon"]) != null, "icon for research " + id)
	for id in Bal.PERKS:
		ok(Icons.tex(Bal.PERKS[id]["icon"]) != null, "icon for perk " + id)
	ok(Line.best_recipe({}) == "shortbread", "no hoppers: shortbread")
	ok(Line.best_recipe({"sugar": true}) == "sugar", "sugar hopper: sugar cookie")
	ok(Line.best_recipe({"sugar": true, "egg": true, "chocolate": true, "cocoa": true}) == "double", "best of several recipes")
	ok(Line.best_recipe({"egg": true}) == "shortbread", "unusable hopper still bakes shortbread")


func _test_balance() -> void:
	for k in Defs.BUILDINGS:
		var mx := Bal.max_level(k)
		if mx <= 1:
			continue
		var prev := 0.0
		for l in range(1, mx):
			var c := Bal.upgrade_cost(k, l)
			ok(c > prev, "%s upgrade cost grows at %d" % [k, l])
			prev = c
		ok(Bal.build_cost(k, 1) >= Bal.build_cost(k, 0), "%s second one costs more" % k)
	for l in range(1, 60):
		ok(Bal.farm_work_time(l + 1) <= Bal.farm_work_time(l), "farm work time shrinks")
		ok(Bal.farm_crate_cap(l + 1) > Bal.farm_crate_cap(l), "crate grows")
		ok(Bal.bake_time(l + 1) <= Bal.bake_time(l), "bake time shrinks")
		ok(Bal.batch_size(l + 1) >= Bal.batch_size(l), "batch grows")
		ok(Bal.mixer_interval(l + 1) <= Bal.mixer_interval(l), "mixer speeds up")
		ok(Bal.truck_cap(l + 1) > Bal.truck_cap(l), "truck grows")
		ok(Bal.xp_needed(l + 1) > Bal.xp_needed(l), "xp curve grows")
	for id in Bal.RESEARCH:
		ok(Bal.research_cost(id, 1) > Bal.research_cost(id, 0), "research %s cost grows" % id)
	ok(Bal.land_cost(5) > Bal.land_cost(4), "land gets dearer")
	ok(Bal.snap_price(12345.0) == 12000.0, "prices snap to friendly numbers")


func _test_game_state() -> void:
	Game.reset_state()
	ok(Game.count_of("farm_wheat") == 1 and Game.count_of("mixer") == 1 and Game.count_of("oven") == 1 and Game.count_of("dock") == 1, "new empire: field, line, van")
	ok(Game.owned_chunks().size() == 4, "new empire owns 4 chunks")
	ok(Game.owns_cell(Vector2i(0, 0)) and not Game.owns_cell(Vector2i(40, 0)), "land ownership by cell")
	Game.money = 0
	ok(Game.place("farm_sugar", Vector2i(-6, 1), 0).is_empty(), "can't place without money")
	Game.money = 1000
	var p0 := Game.price_of("farm_sugar")
	var b := Game.place("farm_sugar", Vector2i(-6, 1), 0)
	ok(not b.is_empty() and Game.money == 1000 - p0, "placing pays")
	ok(Game.price_of("farm_sugar") > p0, "the next one costs more")
	var uid := int(b["uid"])
	Game.money = 1e6
	ok(Game.upgrade(uid) and int(Game.building(uid)["lvl"]) == 2, "upgrade a building")
	Game.move(uid, Vector2i(-6, 2), 1)
	ok(Game.cell_of(Game.building(uid)) == Vector2i(-6, 2) and int(Game.building(uid)["rot"]) == 1, "move a building")
	var before := Game.money
	Game.remove(uid)
	ok(Game.building(uid).is_empty() and Game.money > before, "sell refunds")
	# land
	ok(not Game.can_buy_chunk(Vector2i(5, 5)), "only neighbouring land can be bought")
	ok(Game.can_buy_chunk(Vector2i(1, 0)), "neighbour land for sale")
	var lp := Game.land_price()
	ok(Game.buy_chunk(Vector2i(1, 0)) and Game.owns_chunk(Vector2i(1, 0)), "buy land")
	ok(Game.land_price() > lp, "land gets dearer")
	# research
	var c := Game.research_cost("carry")
	ok(Game.buy_research("carry") and Game.research("carry") == 1 and Bal.carry() == 9, "research carry")
	ok(Game.research_cost("carry") > c, "research gets dearer")
	ok(not Game.buy_perk("golden"), "perks need gems")
	Game.add_gems(10)
	ok(Game.buy_perk("golden") and Game.perk("golden") == 1, "buy a perk with gems")
	# workers
	ok(not Game.can_hire(), "no cabin: no hiring")
	Game.place("cabin", Vector2i(4, 2), 0)
	ok(Game.can_hire() and not Game.hire().is_empty(), "hire with a cabin")
	ok(Game.assign_idle("gatherer") and Game.workers_with("gatherer") == 1, "assign a hauler")
	ok(Game.unassign("gatherer") and Game.idle_workers() == 1, "send back to the cabin")
	# selling + xp
	var lvl := Game.level
	var m := Game.money
	var got := Game.sell(["c:sugar", "b:sugar", "g:sugar"])
	ok(got > 0 and Game.money >= m + got, "selling pays")
	var v := Bal.item_value("c:sugar")
	ok(Bal.item_value("b:sugar") > v * 6 and Bal.item_value("g:sugar") > Bal.item_value("b:sugar"), "boxes and gifts are worth more")
	ok(Game.level >= lvl, "xp from sales")
	# orders
	Game.reset_state()
	Game.known_recipes["sugar"] = true
	Game.place("board", Vector2i(-6, 2), 0, {}, false)
	Game.refill_orders()
	ok(Game.orders.size() == Game.order_slots(), "board fills with orders")
	var o: Dictionary = Game.orders[0]
	var gems0 := Game.gems
	for i in int(o["count"]):
		Game.deliver(o["item"])
	ok(Game.gems > gems0 and int(Game.stats["orders"]) == 1, "finished orders pay gems")
	ok(Game.orders.size() == Game.order_slots(), "a new order replaces it")
	Game.reset_state()


func _test_save_roundtrip() -> void:
	Game.reset_state()
	Game.money = 123456.0
	Game.level = 9
	Game.gems = 4
	Game.place("farm_cocoa", Vector2i(-6, 1), 2, {}, false)
	Game.buy_chunk(Vector2i(1, 0))
	Game.research_lv["recipe"] = 3
	Game.known_recipes["cocoa"] = true
	var d := Game.to_dict()
	var txt := JSON.stringify(d)
	Game.reset_state()
	Game.from_dict(JSON.parse_string(txt))
	ok(Game.level == 9 and Game.gems == 4, "save: level, gems")
	ok(Game.count_of("farm_cocoa") == 1, "save: buildings")
	var cb := {}
	for b in Game.buildings:
		if b["kind"] == "farm_cocoa":
			cb = b
	ok(int(cb["rot"]) == 2 and Game.cell_of(cb) == Vector2i(-6, 1), "save: building cell + rotation")
	ok(Game.research("recipe") == 3 and Game.known_recipes.has("cocoa"), "save: research, recipes")
	ok(Game.owned_chunks().size() >= 4, "save: land")
	Game.reset_state()


func _test_grid() -> void:
	ok(Grid.rotated(Vector2i(3, 2), 1) == Vector2i(2, 3), "rotation swaps footprint")
	ok(Grid.cell_of(Vector3(-0.1, 0, 3.9)) == Vector2i(-1, 1), "world -> cell")
	var g := Grid.new()
	g.fill(1, Vector2i(0, 0), Vector2i(2, 2), 0)
	ok(g.at(Vector2i(1, 1)) == 1 and g.at(Vector2i(2, 0)) == 0, "occupancy")
	ok(not g.is_free(Vector2i(1, 1), Vector2i(2, 2), 0), "overlap blocked")
	ok(g.is_free(Vector2i(1, 1), Vector2i(2, 2), 0, [1]), "moving ignores itself")
	var chunks: Array[Vector2i] = [Vector2i(0, 0)]
	g.rebuild(chunks)
	var solids: Array[Rect2] = [Rect2(4, 0, 2, 12)]
	g.set_solids(1, solids)
	var path := g.path(Vector3(1, 0, 4), Vector3(10, 0, 4))
	var crosses := false
	for p in path:
		if p.x > 4.2 and p.x < 5.8 and p.z < 11.5:
			crosses = true
	ok(path.size() > 1 and not crosses, "paths walk around walls")


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

func _test_world() -> void:
	Game.reset_state()
	Game.money = 1e6
	var w := World.new()
	add_child(w)
	await get_tree().process_frame
	ok(w.lines.size() == 1, "the starting line connects (mixer, tubes, oven)")
	var line: Line = w.lines[0]
	ok(line.product == "shortbread", "starting line bakes shortbread")
	# swap a tube for a sugar hopper: the line now bakes sugar cookies
	var tube: Building = w.buildings_of("tube")[0]
	var cell := tube.cell()
	Game.remove(tube.uid, false)
	Game.place("hopper", cell, 0, {"ing": "sugar"})
	await get_tree().process_frame
	await get_tree().process_frame
	if w.lines.size() != 1:
		for n in w.bnodes.values():
			if n is LineModule:
				print("  ", n.name, " cell ", n.cell(), " rot ", n.rot(), " start ", n.tube_start(), " end ", n.tube_end(), " next ", w.next_module(n))
	ok(w.lines.size() == 1 and w.lines[0].product == "sugar", "hopper on the tube: sugar cookies")
	line = w.lines[0]
	# moving the oven away breaks the line
	var oven: OvenB = w.buildings_of("oven")[0]
	var oc := oven.cell()
	Game.move(oven.uid, oc + Vector2i(0, 3), 0)
	await get_tree().process_frame
	ok(w.lines.is_empty(), "a gap breaks the line")
	Game.move(oven.uid, oc, 0)
	await get_tree().process_frame
	ok(w.lines.size() == 1, "back in place, connected again")
	line = w.lines[0]
	# bake for real
	var mixer: MixerB = w.buildings_of("mixer")[0]
	var hop: HopperB = w.buildings_of("hopper")[0]
	for i in 3:
		mixer.wheat.add("wheat", false)
		hop.store.add("sugar", false)
	Engine.time_scale = 6.0
	var t := 0.0
	while oven.tray.count() < oven.batch() and t < 40.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	Engine.time_scale = 1.0
	ok(oven.tray.count() >= oven.batch(), "the line baked a batch (%.1fs)" % t)
	ok(oven.tray.count() > 0 and oven.tray.items[0] == "c:sugar", "it baked sugar cookies")
	ok(Game.known_recipes.has("sugar"), "baking discovers the recipe")
	# a worker keeps the line fed
	Game.place("cabin", Vector2i(-2, 1), 0)
	var wk := Game.hire()
	Game.assign(int(wk["id"]), "gatherer")
	await get_tree().process_frame
	var farm: FarmB = w.buildings_of("farm_wheat")[0]
	for i in 6:
		farm.crate.add("wheat", false)
	mixer.wheat.clear_all()
	Engine.time_scale = 6.0
	t = 0.0
	while mixer.wheat.count() == 0 and line.doughs.is_empty() and t < 60.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	Engine.time_scale = 1.0
	ok(mixer.wheat.count() > 0 or not line.doughs.is_empty(), "a gatherer brought wheat to the mixer (%.1fs)" % t)
	# you can always empty your hands
	var p := w.player
	for it in ["wheat", "egg", "c:sugar"]:
		p.carry.add(it, false)
	p.discard_all()
	ok(p.carry.count() == 0 and not p.ch.carrying, "discard_all empties the hands")
	w.queue_free()
	await get_tree().process_frame
	Game.reset_state()
