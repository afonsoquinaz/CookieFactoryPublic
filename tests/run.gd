extends Node
## Headless logic tests. Run: tools/test.sh
## Covers the economy tables, holders and transfers, game state + save
## round-trip, worker hiring rules, and a real assembly line baking cookies.

var _fails := 0
var _checks := 0


func _ready() -> void:
	Game.no_save = true
	Game.reset_state()
	_test_tables()
	_test_game_state()
	_test_save_roundtrip()
	await _test_holders()
	await _test_line()
	print("\n%d checks, %d failed" % [_checks, _fails])
	get_tree().quit(1 if _fails > 0 else 0)


func ok(cond: bool, what: String) -> void:
	_checks += 1
	if not cond:
		_fails += 1
		print("FAIL: ", what)


func _test_tables() -> void:
	for id in Bal.all_upgrade_ids():
		var d := Bal.upgrade_def(id)
		ok(Icons.tex(d["icon"]) != null, "icon exists for upgrade " + id)
		var start := 1 if id.begins_with("farm_") else 0
		var prev := -1
		for l in range(start, int(d["max"])):
			var c := Bal.cost(id, l - start)
			ok(c > prev, "%s cost grows at level %d (%d > %d)" % [id, l, c, prev])
			prev = c
	for l in 15:
		ok(Bal.carry(l + 1) > Bal.carry(l), "carry grows")
		ok(Bal.bake_time(l + 1) < Bal.bake_time(l), "bake time shrinks")
		ok(Bal.truck_trip(l + 1) <= Bal.truck_trip(l), "truck trip shrinks")
		ok(Bal.cookie_price(l + 1) >= Bal.cookie_price(l), "price grows")
		ok(Bal.xp_needed(l + 2) > Bal.xp_needed(l + 1), "xp curve grows")
	for l in range(1, Bal.FARM_MAX):
		ok(Bal.farm_work_time(l + 1) <= Bal.farm_work_time(l), "farm work time shrinks")
		ok(Bal.farm_crate_cap(l + 1) > Bal.farm_crate_cap(l), "farm crate grows")
	for ing in Defs.INGREDIENTS:
		ok(Icons.tex(ing) != null, "icon for " + ing)
		ok(Defs.ITEMS.has(ing), "item def for " + ing)
	for r in Defs.ROLE_ORDER:
		ok(Icons.tex(Defs.ROLES[r]["icon"]) != null, "icon for role " + r)
		ok(Defs.BUILDINGS.has(Defs.ROLES[r]["needs"]), "role %s needs a real building" % r)
	for b in Defs.BUILD_ORDER:
		ok(Icons.tex(Defs.BUILDINGS[b]["icon"]) != null, "icon for building " + b)


func _test_game_state() -> void:
	Game.reset_state()
	ok(Game.money == Bal.START_MONEY, "start money")
	ok(not Game.buy_upgrade("carry"), "can't buy without money")
	Game.add_money(1000)
	var cost := Game.upgrade_cost("carry")
	ok(Game.buy_upgrade("carry"), "buy carry")
	ok(Game.lvl("carry") == 1 and Game.money == 1000 - cost, "carry level + money spent")
	ok(Game.lvl("farm_wheat") == 1, "farms start at level 1")
	ok(not Game.upgrade_available("pantry"), "pantry upgrade locked before building")
	# workers need the cabin
	ok(not Game.can_hire(), "no hiring without cabin")
	Game.build("cabin")
	ok(Game.can_hire(), "hiring after cabin")
	var w := Game.hire()
	ok(not w.is_empty() and Game.workers.size() == 1, "hired one")
	ok(Game.idle_workers() == 1, "new worker is idle")
	ok(not Game.role_unlocked("gatherer"), "gatherer locked without pantry")
	Game.assign(int(w["id"]), "farmer", "milk")
	ok(Game.workers_with("farmer", "milk") == 1, "assigned farmer to milk")
	# levels
	var lvl := Game.level
	Game.add_xp(Bal.xp_needed(lvl) + 1)
	ok(Game.level == lvl + 1, "level up from xp")
	var before := Game.money
	var sold := Game.sell_cookies(10)
	ok(sold == 10 * Game.cookie_price() and Game.money >= before + sold, "selling pays")
	# recipe grows with every farm unlocked
	var p0 := Game.cookie_price()
	ok(Game.recipe().size() == 1 and Game.recipe()[0] == "wheat", "start recipe is just wheat")
	ok(not Game.upgrade_available("farm_sugar"), "sugar farm upgrade locked before the field exists")
	Game.build("plot_sugar")
	ok(Game.cookie_grade() == 1 and Game.cookie_price() > p0, "sugar raises the cookie price")
	ok(Game.upgrade_available("farm_sugar"), "sugar farm upgrade unlocked")
	# rush
	ok(Game.start_rush() and Game.speed_mult() == 2.0, "rush doubles speed")
	ok(not Game.start_rush(), "rush has a cooldown")


func _test_save_roundtrip() -> void:
	var d := Game.to_dict()
	var json := JSON.stringify(d)
	var back = JSON.parse_string(json)
	var money := Game.money
	var lvl := Game.level
	var ups := Game.upgrades.duplicate()
	Game.reset_state()
	Game.from_dict(back)
	ok(Game.money == money, "save keeps money")
	ok(Game.level == lvl, "save keeps level")
	ok(Game.lvl("carry") == int(ups["carry"]), "save keeps upgrades")
	ok(Game.workers.size() == 1 and Game.workers[0]["role"] == "farmer", "save keeps workers")
	ok(Game.has_building("cabin"), "save keeps buildings")


func _test_holders() -> void:
	var root := Node3D.new()
	add_child(root)
	var a := Holder.new().setup(5, [], Holder.Layout.COLUMN)
	var b := Holder.new().setup(3, ["wheat"], Holder.Layout.GRID)
	root.add_child(a)
	root.add_child(b)
	for i in 4:
		a.add("wheat", false)
	a.add("cookie", false)
	ok(a.count() == 5 and a.space() == 0, "holder fills to capacity")
	ok(not b.can_accept("cookie"), "filtered holder refuses other items")
	ok(Holder.fly(a, b, "wheat", 0.05), "fly starts")
	ok(b.incoming == 1 and b.space() == 2, "target reserves room while flying")
	Holder.fly(a, b, "wheat", 0.05)
	Holder.fly(a, b, "wheat", 0.05)
	ok(not Holder.fly(a, b, "wheat", 0.05), "can't overfill the target")
	await get_tree().create_timer(0.3).timeout
	ok(b.count() == 3 and b.incoming == 0, "items landed")
	ok(a.count_of("wheat") == 1 and a.count_of("cookie") == 1, "source lost what it gave")
	ok(a.take("cookie") == "cookie" and a.items.size() == 1 and a.items[0] == "wheat", "take by type")
	root.queue_free()


func _test_line() -> void:
	# just wheat: the first loop must be quick
	Game.reset_state()
	var l0 := Line.new()
	add_child(l0)
	l0.setup(0)
	for i in 2:
		l0.hoppers["wheat"].add("wheat", false)
	Engine.time_scale = 4.0
	var t0 := 0.0
	while l0.tray.count() < Bal.batch_size(0) and t0 < 30.0:
		await get_tree().process_frame
		t0 += get_process_delta_time()
	Engine.time_scale = 1.0
	ok(l0.tray.count() >= Bal.batch_size(0) and t0 < 9.0, "wheat-only line bakes fast (%.1fs)" % t0)
	ok(not l0.hopper_nodes["milk"].visible, "locked hoppers stay hidden")
	l0.queue_free()
	# the full recipe
	for ing in ["sugar", "cocoa", "egg", "milk"]:
		Game.buildings["plot_" + ing] = true
	var l := Line.new()
	add_child(l)
	l.setup(0)
	for ing in Defs.INGREDIENTS:
		for i in 3:
			l.hoppers[ing].add(ing, false)
	Engine.time_scale = 8.0
	var t := 0.0
	while l.tray.count() < Bal.batch_size(0) * 2 and t < 60.0:
		await get_tree().process_frame
		t += get_process_delta_time()
	Engine.time_scale = 1.0
	ok(l.tray.count() >= Bal.batch_size(0) * 2, "line baked two batches (%d cookies, %.1fs)" % [l.tray.count(), t])
	for ing in Defs.INGREDIENTS:
		ok(l.hoppers[ing].count() <= 1, "hopper %s was used" % ing)
	l.queue_free()
