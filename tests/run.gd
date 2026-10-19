extends Node
## Headless logic tests. Run: tools/test.sh
## Covers the data tables (every building, recipe and item is complete and
## reachable), balance curves, Game state (Lab levels, builders and
## timers, placing, upgrading, finishing with gems, obstacles, land, staff,
## orders), save round-trip with time away, holders, the grid, the road
## network, and a real World where the server serves, couriers keep it fed,
## construction sites turn into buildings and every building spawns.

var _fails := 0
var _checks := 0


func _ready() -> void:
	Game.no_save = true
	Live.events_on = false
	Game.reset_state()
	Live.reset_state()
	Live.tick()
	_test_tables()
	_test_balance()
	_test_growth()
	_test_game_state()
	_test_save_roundtrip()
	_test_live()
	_test_store()
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
		ok(Defs.BUILD_ORDER.has(k), "%s is in the build menu" % k)
		ok(Icons.tex(d["icon"]) != null, "icon for building " + k)
		for f in ["name", "cat", "tab", "size", "cost", "growth", "up", "max", "time", "desc"]:
			ok(d.has(f), "%s has %s" % [k, f])
		ok(tabs.has(d["tab"]), "%s is on a real tab" % k)
		ok(not d.has("hall") and not d.has("n"), "%s: nothing gates it but its price" % k)
		if d.has("limit"):
			ok(int(d["limit"]) >= 1, "%s: a real limit" % k)
		ok(Previews.mesh(k).get_surface_count() > 0, "preview mesh for " + k)
		if d.has("in"):
			for t in d["in"]:
				ok(Defs.ITEMS.has(t), "%s input %s is an item" % [k, t])
			for t in d["out"]:
				ok(Defs.PROCESSED.has(t), "%s output %s is processed" % [k, t])
			ok(d.has("craft"), "%s has a craft time" % k)
	for t in Defs.ITEMS:
		ok(Icons.tex(t) != null, "icon for item " + t)
		ok(t == "power" or Defs.producer_of(t) != "", "something produces " + t)
		ok(Items.mesh(t).get_surface_count() > 0, "mesh for item " + t)
	var seen := {}
	for r in Defs.RECIPES:
		ok(not seen.has(r["id"]), "recipe id unique " + r["id"])
		seen[r["id"]] = true
		ok(Icons.tex("tk_" + r["id"]) != null, "token icon for " + r["id"])
		ok(Defs.MODEL_LOOK.has(r["id"]), "token look for " + r["id"])
		for i in r["train"]:
			ok(Defs.ITEMS.has(i) and i != "power", "%s trains on a real resource: %s" % [r["id"], i])
		ok(float(r["vram"]) > 0.0 and float(r["tps"]) > 0.0 and float(r["price"]) > 0.0 and float(r["demand"]) > 0.0, "%s: VRAM, speed, price and demand" % r["id"])
		ok(int(r["open"]) >= 0 or ((r["train"] as Dictionary).size() > 0 and float(r["compute"]) > 0.0), "%s: downloaded or trained" % r["id"])
		var top_vram := Bal.GARAGE_VRAM + Bal.gpu_slots(Bal.max_level("server")) * Bal.GPU_VRAM + Bal.hbm_slots(Bal.max_level("server")) * Bal.HBM_VRAM
		ok(float(r["vram"]) <= top_vram, "a top server can load %s (%d of %d GB)" % [r["id"], int(r["vram"]), int(top_vram)])
	for i in range(1, Defs.RECIPES.size()):
		var a: Dictionary = Defs.RECIPES[i - 1]
		var b: Dictionary = Defs.RECIPES[i]
		ok(float(b["price"]) > float(a["price"]) and float(b["vram"]) >= float(a["vram"]), "%s is bigger and pricier than %s" % [b["id"], a["id"]])
		ok(float(b["tps"]) * float(b["price"]) > float(a["tps"]) * float(a["price"]), "%s earns more per GPU than %s" % [b["id"], a["id"]])
	ok(float(Defs.recipe("pico")["vram"]) <= Bal.GARAGE_VRAM, "the garage card runs Pico")
	for role in Defs.ROLE_ORDER:
		ok(Icons.tex(Defs.ROLES[role]["icon"]) != null, "icon for role " + role)
	for k in Defs.OBSTACLES:
		ok(TownArt.obstacle(k).get_surface_count() > 0, "mesh for obstacle " + k)
	ok(Defs.LEVEL_TITLES.size() >= Defs.EMPIRE.size(), "a title for every Lab level")
	ok(Bal.latency_bonus("pico") > Bal.latency_bonus("chat13") and Bal.latency_bonus("chat13") > 0.0 and Bal.latency_bonus("frontier") == 0.0, "snappy models earn more at the Chat Café, slow ones don't")
	for r in Defs.RECIPES:
		ok(int(r["lat"]) > 0 and str(r["params"]) != "" and str(r["tag"]) != "", "%s has a size, a latency and a tagline" % r["id"])


func _test_balance() -> void:
	for l in range(1, Defs.EMPIRE.size()):
		ok(float(Defs.EMPIRE[l]["xp"]) > float(Defs.EMPIRE[l - 1]["xp"]), "empire level %d needs more than %d" % [l + 1, l])
		ok(int(Defs.EMPIRE[l]["gems"]) > 0, "empire level %d gives gems" % (l + 1))
	for k in Defs.BUILDINGS:
		var mx := Bal.max_level(k)
		if mx <= 1:
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
	ok(Bal.finish_gems(10.0) == 0 and Bal.finish_gems(30.0) == 0, "short jobs finish free")
	ok(Bal.finish_gems(60.0) >= 1 and Bal.finish_gems(3600.0) > Bal.finish_gems(600.0), "longer jobs cost more gems")
	ok(Bal.gpu_slots(1) == 2 and Bal.gpu_slots(5) == 4 and Bal.gpu_slots(40) == 20, "GPU slots grow with server level")
	ok(Bal.hbm_slots(1) == 0 and Bal.hbm_slots(4) == 1 and Bal.hbm_slots(40) == 12, "HBM slots too")
	ok(Bal.adoption(2) > Bal.adoption(1), "the market grows with the Lab level")
	ok(Bal.latency(100.0, 1.0, 0, 0.0) > Bal.latency(100.0, 0.2, 0, 0.0) and Bal.latency(100.0, 0.2, 1, 0.0) < Bal.latency(100.0, 0.2, 0, 0.0), "busy servers answer slower; Edge PoPs answer faster")
	ok(Bal.latency_factor(50.0) > Bal.latency_factor(600.0), "slow answers lose customers")
	ok(Defs.limit_of("src_power") == -1 and Defs.limit_of("planter") == -1, "sources and decor are unlimited")
	# eras: the town turns into a datacenter as the Lab levels up
	ok(Defs.era_for(1) == 0 and Defs.era_for(2) == 0, "it starts in the Garage era")
	for i in Defs.ERAS.size():
		var e: Dictionary = Defs.ERAS[i]
		ok(Defs.era_for(int(e["level"])) == i, "era %d (%s) starts at Lab level %d" % [i, e["name"], int(e["level"])])
		ok(i == 0 or int(e["level"]) > int(Defs.ERAS[i - 1]["level"]), "eras come in order")
		ok(Defs.BUILDINGS.has(e["icon"]) or FileAccess.file_exists("res://assets/icons/%s.png" % e["icon"]), "era %d has an icon" % i)
	ok(Defs.era_for(99) == Defs.ERAS.size() - 1, "the last era lasts forever")
	var compute := 0
	for k in Defs.BUILDINGS:
		var a: Dictionary = Defs.BUILDINGS[k].get("aura", {})
		if a.get("what", "") == "compute":
			compute += 1
			ok(float(a["v"]) > 0.0 and float(a["v"]) <= 0.3 and int(a["r"]) >= 2, "%s: a sensible compute aura" % k)
	ok(compute >= 5, "datacenter gear for every stage of the game (%d)" % compute)
	ok(Defs.limit_of("hut") == 5 and Defs.limit_of("desk") == 1 and Defs.limit_of("mega") == 1, "huts, the board and the palace are limited")


# ---------------------------------------------------------------- growth

func _test_growth() -> void:
	var parts: Array = GrowthParts.FLOOR + GrowthParts.TOP + GrowthParts.WALL
	for kind in Defs.BUILD_ORDER:
		var mx := Bal.max_level(kind)
		var ss := Growth.slots(kind, 0)
		if mx <= 1:
			continue
		ok(ss.size() >= 4, "%s: grows as it levels (%d slots)" % [kind, ss.size()])
		var sz: Vector2i = Defs.BUILDINGS[kind]["size"]
		var half := Vector2(sz) * Grid.CELL * 0.5
		for t in 5:
			var st := Growth.slots(kind, t)
			ok(st.size() == ss.size(), "%s: same slots on tier %d" % [kind, t])
			for sl in st:
				var p: Vector3 = sl["p"]
				ok(absf(p.x) <= half.x - 0.1 and absf(p.z) <= half.y - 0.1, "%s: slot %s inside the lot" % [kind, p])
				ok(parts.has(sl["part"]), "%s: knows part %s" % [kind, sl["part"]])
				if sl.get("top", false):
					var e: Array = GrowthTops.TOPS.get(Growth._top_key(kind, t, p.x, p.z), [])
					ok(e.size() == 2, "%s: roof height for %s on tier %d (run dev/tops.tscn --write)" % [kind, p, t])
					if e.size() == 2:
						ok(float(e[0]) > 0.4 and float(e[1]) < 0.35, "%s: a flat roof under %s on tier %d (%.2f, uneven %.2f)" % [kind, p, t, e[0], e[1]])
		var plan := Growth.plan(kind)
		ok(plan.size() == ss.size() * Growth.GRADES, "%s: every slot grows through every grade" % kind)
		var prev := 2
		for at in plan:
			ok(at >= prev and at <= mx, "%s: steps in order, by the top level" % kind)
			prev = at
		var early := mini(mx, Growth.EARLY + 1)
		var steady := true
		for l in range(2, early + 1):
			if Growth.count(kind, l) <= Growth.count(kind, l - 1):
				steady = false
		ok(steady, "%s: each of the first %d upgrades adds something you can see" % [kind, early - 1])
		ok(Growth.count(kind, mx) == plan.size(), "%s: everything there at the top level" % kind)
		ok(Growth.count(kind, 1) == 0, "%s: starts bare" % kind)
		var m := Growth.build(kind, plan.size(), 4)
		ok(m.get_surface_count() == 1, "%s: the full gear builds" % kind)
	for res in ["power", "data", "papers"]:
		var prev_n := 0
		for l in range(1, 61):
			var n := SourceArt.station_count(res, l)
			ok(n >= prev_n, "%s source: stations never go away (L%d)" % [res, l])
			prev_n = n
		ok(SourceArt.station_spots(res, 60, 5.6, 3.8, -0.9).size() == SourceArt.station_count(res, 60), "%s: a spot per station" % res)
	ok(SourceArt.station_count("data", 1) == 3 and SourceArt.station_count("data", 3) == 4 and SourceArt.station_count("power", 60) == 8, "stations: three to start, one every other level")


# ---------------------------------------------------------------- live (daily layer)

## Moves the Live clock so local time is `lt` (a local unix stamp).
func _live_at(lt: int) -> void:
	Live.debug_offset = lt - (Live.local() - Live.debug_offset)


func _test_live() -> void:
	Game.reset_state()
	Live.reset_state()
	# noon on a fixed day (the simulated league rivals are seeded by week, so a moving date makes results vary)
	var base := int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 10, "day": 28, "hour": 12, "minute": 0, "second": 0}))
	_live_at(base)
	Live.tick()
	ok(Live.local() == base, "the Live clock can be moved (tests)")
	# calendar maths
	ok(Live.week_of(0) == 0 and Live.week_of(4) == 1 and Live.week_start(1) == 4, "weeks start on Monday")
	ok(Live.season_of(0) == 1970 * 12, "seasons are calendar months")
	var d0 := Live.today()
	ok(Live.day == d0 and Live.quests.size() == 3, "a new day brings three quests")
	ok(Live.goal >= 20, "a daily goal (%d tokens)" % Live.goal)
	var tiers := []
	for q in Live.quests:
		tiers.append(int(LiveDefs.QUESTS[q["id"]]["tier"]))
	ok(tiers == [0, 1, 2], "an easy, a medium and a hard quest")
	ok(str(Live._roll_quests(d0)) == str(Live._roll_quests(d0)), "the same day rolls the same quests")
	# the streak
	ok(Live.streak == 0, "no streak to start")
	Game.track("tokens", Live.goal)
	ok(Live.goal_is_done and Live.streak == 1, "reaching the goal starts a streak")
	Game.track("tokens", Live.goal)
	ok(Live.streak == 1, "only once a day")
	_live_at(base + 86400)
	Live.tick()
	ok(Live.today() == d0 + 1 and not Live.goal_is_done and Live.streak == 1, "a new day: the streak waits for today's goal")
	var gems0 := Game.gems
	Game.track("tokens", Live.goal)
	ok(Live.streak == 2, "two days in a row")
	Live.freezes = 1
	_live_at(base + 3 * 86400)
	Live.tick()
	ok(Live.streak == 2 and Live.freezes == 0 and Live.day_mark(d0 + 2) == "freeze", "a missed day eats a freeze, not the streak")
	Game.track("tokens", Live.goal)
	ok(Live.streak == 3, "and it carries on (%d)" % Live.streak)
	ok(Game.gems == gems0 + int(LiveDefs.STREAK_MILESTONES[3]["gems"]), "a 3-day streak brings sparks")
	ok(int(Live.boosters["warp15"]) >= 1, "and a Time Warp")
	_live_at(base + 6 * 86400)
	Live.tick()
	ok(Live.streak == 0 and Live.lost_streak == 3 and Live.can_repair(), "two missed days without freezes: the streak is lost, but repairable")
	Game.gems = 200
	ok(Live.repair_streak() and Live.streak == 3 and Game.gems == 200 - LiveDefs.repair_price(3), "repairing brings it back for sparks")
	Game.track("tokens", Live.goal)
	ok(Live.streak == 4, "and today's goal adds to it")
	ok(Live.buy_freeze() and Live.freezes == 1, "freezes can be bought")
	# quests
	var q0: Dictionary = Live.quests[0]
	var m: String = LiveDefs.QUESTS[q0["id"]]["metric"]
	ok(not Live.quest_ready(q0) or int(q0["n"]) <= Live.quest_progress(q0), "quests start at zero")
	Game.track(m, float(q0["n"]))
	ok(Live.quest_ready(Live.quests[0]), "counting %s finishes the quest" % m)
	var money0 := Game.money
	ok(not Live.claim_quest(0).is_empty() and Game.money > money0, "claiming a quest pays")
	ok(Live.claim_quest(0).is_empty(), "only once")
	ok(Live.reroll(1) and not Live.reroll(2), "one swap a day")
	for i in [1, 2]:
		var q: Dictionary = Live.quests[i]
		Game.track(LiveDefs.QUESTS[q["id"]]["metric"], float(q["n"]) + 1.0)
		Live.claim_quest(i)
	ok(Live.quests_all_done() and Live.stamps == 1, "all three: a Breakthrough stamp")
	ok(Live.crates.size() == 1 and Live.crates[0]["kind"] == "supply", "and a Supply Crate")
	Live.stamps = 7
	ok(not Live.claim_breakthrough().is_empty() and Live.is_unlocked("quantum_core") and Live.stamps == 0, "seven stamps: a Breakthrough and the Quantum Core")
	# login calendar
	ok(not Live.claim_login().is_empty() and Live.claim_login().is_empty() and Live.login_idx == 1, "a login gift once a day")
	# crates
	Live.crates.clear()
	Live.inbox.clear()
	for i in 5:
		Live.add_crate("supply")
	ok(Live.crates.size() == LiveDefs.CRATE_SLOTS and Live.inbox.size() == 1, "four crate slots; an extra crate waits in the inbox")
	ok(Live.start_unlock(0) and not Live.start_unlock(1), "crates unlock one at a time")
	ok(Live.crate_skip_price(0) > 0, "opening early costs sparks")
	_live_at(base + 6 * 86400 + 3 * 3600 + 5)
	Live.tick()
	ok(Live.crates[0]["state"] == "ready" and Live.crate_skip_price(0) == 0, "a crate is ready when its timer runs out")
	var opened := int(Live.counters.get("crates", 0))
	ok(not Live.open_crate(0).is_empty() and Live.crates.size() == 3, "opening it gives its loot")
	ok(int(Live.counters.get("crates", 0)) == opened + 1, "crates opened are counted")
	ok(str(LiveDefs.crate_loot("gpu", 42, 10.0)) == str(LiveDefs.crate_loot("gpu", 42, 10.0)), "a crate's loot is fixed by its seed")
	ok(int(LiveDefs.crate_loot("lab", 7, 10.0).get("freeze", 0)) == 1, "lab crates hold a Streak Freeze")
	ok(not Live.claim_msg(int(Live.inbox[0]["id"])).is_empty() and Live.crates.size() == 4, "the waiting crate can be claimed once a slot is free")
	# boosters
	var j := Game._start_job("build", 999, 3000.0)
	Live.boosters["warp15"] = 1
	var end0 := float(j["end"])
	ok(Live.use_warp("warp15", j) and is_equal_approx(float(j["end"]), end0 - 900.0), "a Time Warp takes 15 minutes off a job")
	ok(not Live.use_warp("warp15", j), "only if you have one")
	Game.jobs.erase(j)
	# badges
	Live.counters["quests"] = 5.0
	ok(Live.badge_tier("quests") == 1 and Live.badge_claimable("quests"), "badges reach tiers")
	var g1 := Game.gems
	ok(not Live.claim_badge("quests").is_empty() and Game.gems == g1 + LiveDefs.BADGE_GEMS[0] and not Live.badge_claimable("quests"), "a badge tier pays sparks once")
	# mastery
	Game.track("served", 150.0, "mini")
	ok(Live.stars("mini") == 1 and Live.mastery_claimable("mini"), "serving a model earns mastery stars")
	ok(is_equal_approx(Live.price_mult("mini"), 1.0 + LiveDefs.MASTERY_PRICE), "a mastered model sells for more")
	ok(Bal.token_price("mini") > float(Defs.recipe("mini")["price"]) * Bal.price_mult(), "prices include mastery")
	# league
	var r1 := Live.rivals(100, 2)
	ok(r1.size() == LiveDefs.LEAGUE_SIZE - 1 and str(r1) == str(Live.rivals(100, 2)), "29 rival labs, the same all week")
	var ws := Live.week_start(100) * 86400
	var mono := true
	for r in r1:
		if Live.rival_points(r, 100, ws + 2 * 86400) > Live.rival_points(r, 100, ws + 5 * 86400):
			mono = false
	ok(mono, "rival points only go up during the week")
	ok(Live.rival_points(r1[0], 100, ws - 10) == 0, "and start at zero")
	var w := Live.week_of(Live.today())
	ok(int(Live.league["week"]) == w, "the league follows the week")
	Live.league["tier"] = 0
	Live.league["points"] = 0
	Live.league["joined"] = false
	Live.add_bp(100000)
	var rows := Live.standings()
	ok(rows.size() == LiveDefs.LEAGUE_SIZE and Live.my_rank(rows) == 1, "a big week puts you on top")
	Live.unlocked.erase("trophy")
	_live_at((Live.week_start(w + 1) * 86400) + 3600)
	Live.tick()
	ok(int(Live.league["tier"]) == 1 and int(Live.league["week"]) == w + 1, "top of the week: promoted to Silver")
	ok(Live.league_history.size() >= 1 and int(Live.league_history.back()["rank"]) == 1, "the result is kept")
	ok(not (Live.inbox[0]["reward"] as Dictionary).is_empty() and Live.inbox[0]["reward"].has("decor"), "the reward (and the trophy) waits in the inbox")
	Live.add_bp(1)
	_live_at((Live.week_start(w + 2) * 86400) + 3600)
	Live.tick()
	ok(int(Live.league["tier"]) == 0, "a one-point week in Silver: back to Bronze")
	_live_at((Live.week_start(w + 3) * 86400) + 3600)
	Live.tick()
	ok(int(Live.league["tier"]) == 0 and int(Live.league_history.back()["week"]) == w + 1, "skipping a week changes nothing")
	# Lab Pass
	var sid := int(Live.season["id"])
	Live.season["sp"] = 0
	Live.add_sp(LiveDefs.PASS_TIER_SP * 3)
	ok(Live.pass_tier() == 3, "Pass points fill tiers")
	ok(not Live.claim_pass(0, false).is_empty() and Live.claim_pass(0, false).is_empty(), "free rewards claim once")
	ok(not Live.pass_claimable(0, true), "premium needs the premium track")
	Game.gems = 500
	ok(Live.buy_premium() and Live.pass_claimable(0, true), "buying it opens the premium rewards")
	ok(LiveDefs.pass_reward(9, false).get("decor", "") == "neon_sign" and LiveDefs.pass_reward(14, true).get("decor", "") == "holo_bot", "the Pass holds exclusive decor")
	Live.inbox.clear()
	Live._new_season(sid + 1)
	ok(int(Live.season["id"]) == sid + 1 and int(Live.season["sp"]) == 0 and Live.inbox.size() == 1, "a new season: what you didn't claim goes to the inbox")
	# events (on the local calendar)
	var tue := int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 10, "day": 20, "hour": 18, "minute": 30, "second": 0}))
	var sw := LiveDefs.event_window("spotlight", tue)
	ok(not sw.is_empty() and tue >= int(sw[0]) and tue < int(sw[1]), "Spotlight Hour: Tuesday 18:00")
	var sat := int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 10, "day": 10, "hour": 15, "minute": 0, "second": 0}))
	var cw := LiveDefs.event_window("community", sat)
	ok(not cw.is_empty() and sat >= int(cw[0]) and sat < int(cw[1]), "Community Day: the second Saturday, 14:00-17:00")
	ok(LiveDefs.event_window("community", sat + 4 * 3600)[0] > sat + 20 * 86400, "then next month")
	var launch := int(Time.get_unix_time_from_datetime_dict({"year": 2026, "month": 11, "day": 3, "hour": 9, "minute": 0, "second": 0}))
	var lw := LiveDefs.event_window("launch", launch)
	ok(not lw.is_empty() and launch >= int(lw[0]), "Launch Week: the first week of the month")
	Live.events_on = true
	_live_at(sat)
	ok(Live.active_events().has("community") and Live.active_events().has("hackathon"), "on Community Day (a Saturday) both are on")
	ok(Live.price_mult("pico") >= 2.0 and is_equal_approx(Live.time_mult(), 0.75) and is_equal_approx(Live.sp_mult(), 3.0), "events change prices, timers and Pass points")
	Live.tick()
	ok(Live.event_quests["list"].size() == 3, "Community Day brings its quests")
	_live_at(tue)
	ok(is_equal_approx(Live.price_mult(Live.spotlight_model()), 3.0 * (1.0 + LiveDefs.MASTERY_PRICE * Live.stars(Live.spotlight_model()))), "Spotlight Hour: one model sells for 3x")
	Live.events_on = false
	_live_at(base + 6 * 86400 + 4 * 3600)
	Live.tick()
	# reminders
	Live.notify["quiet"] = true
	var nj := Game._start_job("upgrade", 998, 5000.0)
	Live.streak = 5
	Live.goal_is_done = false
	var pl := Notifier.plan()
	var cats := []
	var ok_times := true
	var quiet_ok := true
	for n in pl:
		cats.append(n["cat"])
		if int(n["at"]) <= Live.now():
			ok_times = false
		var h := float(posmod(Live.local(int(n["at"])), 86400)) / 3600.0
		if h >= LiveDefs.QUIET_START or h < LiveDefs.QUIET_END:
			quiet_ok = false
	ok(cats.has("builders") and cats.has("streak") and cats.has("quests"), "reminders: builders, the streak, new quests (%s)" % str(cats))
	ok(ok_times and quiet_ok and pl.size() <= Notifier.MAX, "all in the future, none in quiet hours, at most %d" % Notifier.MAX)
	var uniq := {}
	for c in cats:
		uniq[c] = true
	ok(uniq.size() == cats.size(), "one of each kind")
	Live.notify["cats"]["builders"] = false
	ok(not str(Notifier.plan()).contains("\"builders\""), "kinds can be switched off")
	Live.notify["cats"]["builders"] = true
	Game.jobs.erase(nj)
	ok(not Notifier._make("streak", 0, {"n": 5})["title"].contains("{"), "reminder text is filled in")
	# friends
	var code := Live.friend_code()
	ok(Live.code_valid(code) and not Live.code_valid(code.replace("TKN", "TKX")), "friend codes check themselves")
	ok(Live.redeem(code) != "", "your own code doesn't count")
	var other: String = Live.code_for("1234abcd")
	ok(Live.redeem(other) == "" and Live.redeem(other) != "", "a friend's code: a gift, once")
	# exclusive decor
	ok(Game.build_block("streak_flame").begins_with("Locked"), "exclusive decor starts locked")
	Live.grant({"decor": "streak_flame"})
	ok(not Game.build_block("streak_flame").begins_with("Locked"), "earning it unlocks it")
	# saving
	var dct := Live.to_dict()
	var js = JSON.parse_string(JSON.stringify(dct))
	Live.from_dict(js)
	ok(Live.streak == int(dct["streak"]) and Live.quests.size() == 3 and int(Live.league["tier"]) == int(dct["league"]["tier"]) and Live.unlocked.has("streak_flame"), "the daily layer saves and loads")
	ok(Live.claimables() >= 0, "claimables count")
	Live.reset_state()
	Live.debug_offset = 0
	Live.tick()
	Game.reset_state()


# ---------------------------------------------------------------- game state

func _test_game_state() -> void:
	Game.reset_state()
	ok(Game.level == 1, "a new lab is level 1")
	for k in ["server", "src_power", "gateway", "depot", "dorm"]:
		ok(Game.count_ready(k) == 1, "a new empire has a ready " + k)
	ok(Game.builders() == 2 and Game.free_builders() == 2, "two builders to start")
	ok(Game.workers_with("courier") == 3, "three couriers to start")
	ok(Game.obstacles.size() >= 5, "obstacles to clear on the starting land")
	ok(Game.build_block("src_silicon") == "Not enough money", "only money stands between you and silicon works")
	for k in Defs.BUILD_ORDER:
		var by := Game.build_block(k)
		if LiveDefs.EXCLUSIVE.has(k):
			ok(by.begins_with("Locked"), "%s is earned, not bought (%s)" % [k, by])
			continue
		ok(by == "" or by == "Not enough money" or by.begins_with("Needs") and by.contains("sparks"), "%s is open from the start (%s)" % [k, by])
	for b0 in Game.buildings:
		var ent := Building.entrance_of(b0["kind"], Game.cell_of(b0), int(b0["rot"]))
		ok(ent.is_empty() or World._street_dist(ent[0]) <= 1, "%s starts by the High Street" % b0["kind"])
		for c in Grid.cells(Game.cell_of(b0), Defs.size_of(b0["kind"]), int(b0["rot"])):
			ok(not Roads.is_street(c), "%s is off the High Street" % b0["kind"])
	Game.money = 1000.0
	ok(Game.build_block("src_data") == "", "a web crawler can be built")
	var b := Game.place("src_data", Vector2i(-7, 3), 0)
	ok(not b.is_empty() and int(b["lvl"]) == 0, "a new building starts under construction")
	ok(Game.jobs.size() == 1 and Game.free_builders() == 1, "a builder is busy on it")
	ok(Game.count_ready("src_data") == 0 and not Game.can_make("data"), "not working while being built")
	Game.clock += 2.0
	Game._check_jobs()
	ok(int(b["lvl"]) == 0, "still being built after 2 s")
	Game.clock += Bal.build_time("src_data", 0)
	Game._check_jobs()
	ok(int(b["lvl"]) == 1 and Game.jobs.is_empty() and Game.can_make("data"), "built when the timer runs out")
	# upgrades take a builder and time
	var bk: Dictionary = {}
	for x in Game.buildings:
		if x["kind"] == "server":
			bk = x
	var uid := int(bk["uid"])
	ok(Game.upgrade(uid), "server upgrade starts")
	ok(int(bk["lvl"]) == 1 and Game.job_of(uid).size() > 0, "upgrade in progress")
	ok(Game.upgrade_block(uid) != "", "can't upgrade twice at once")
	ok(Game.finish_now(Game.job_of(uid)), "short job finishes free")
	ok(int(bk["lvl"]) == 2, "server reached level 2")
	bk["lvl"] = 30
	Game.money = 1e9
	ok(Game.upgrade_block(uid) == "", "nothing caps building levels but their max")
	bk["lvl"] = 2
	# Lab levels come from tokens served, with sparks
	var gems0 := Game.gems
	Game.serve("pico", float(Defs.EMPIRE[2]["xp"]) + 10.0, 5.0)
	ok(Game.level == 3 and Game.gems == gems0 + int(Defs.EMPIRE[1]["gems"]) + int(Defs.EMPIRE[2]["gems"]), "serving tokens raises the Lab level, with sparks")
	Game.add_money(1e6)
	ok(Game.level == 3, "money alone doesn't raise the level")
	var m0 := Game.money
	Game.serve("pico", 2.0, 6.0, "agent")
	ok(is_equal_approx(float(Game.stats["tokens"]), float(Defs.EMPIRE[2]["xp"]) + 12.0) and is_equal_approx(Game.money, m0 + 6.0), "serving counts tokens and pays")
	ok(not Game.download("chat13") and Game.download("mini") and Game.known_recipes.has("mini"), "open weights download; your own models must be trained")
	ok(Game.level_progress() > 0.0 and Game.level_progress() < 1.0, "progress toward the next level")
	Game.money = 1e6
	ok(Game.build_block("src_coolant") == "", "a cooling tower right away")
	# both builders busy
	Game.upgrade(uid)
	Game.place("src_power", Vector2i(3, -8), 0)
	ok(Game.free_builders() == 0, "both builders busy")
	ok(Game.build_block("src_coolant").contains("builder"), "no free builder: can't build")
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
	ok(Game.assign_courier("tech", 7), "a courier becomes a technician")
	ok(Game.workers_with("tech", 7) == 1 and Game.workers_with("courier") == 2, "one technician, two couriers")
	Game.assign_courier("engineer", 8)
	ok(not Game.assign_courier("engineer", 8), "the last courier stays a courier")
	ok(Game.unassign("engineer", 8) and Game.workers_with("courier") == 2, "back to courier work")
	Game.money = 1e9
	var cap := Game.dorm_capacity()
	while Game.can_hire():
		Game.hire()
	ok(Game.workers.size() == cap, "hire up to what you can house")
	# orders
	Game.place("desk", Vector2i(-6, 6), 0, {}, false)
	Game.refill_orders()
	ok(Game.orders.size() == Game.order_slots(), "the board fills with contracts")
	var o: Dictionary = Game.orders[0]
	ok(Game.known_recipes.has(o["model"]) and float(o["count"]) > 0.0 and float(o["reward"]) > 0.0, "a contract for a model you serve")
	var g1 := Game.gems
	o["got"] = o["count"]
	Game.contract_done(o)
	ok(Game.gems > g1 and Game.orders.size() == Game.order_slots(), "a finished contract pays sparks and a new one comes in")
	Game.reset_state()


func _test_save_roundtrip() -> void:
	Game.reset_state()
	Game.money = 5000.0
	Game.place("src_data", Vector2i(-7, 3), 0)
	Game.buy_chunk(Vector2i(1, 0))
	var d := Game.to_dict()
	d = JSON.parse_string(JSON.stringify(d))
	Game.from_dict(d)
	ok(Game.count_of("src_data") == 1 and Game.jobs.size() == 1, "save keeps buildings and jobs")
	ok(Game.owns_chunk(Vector2i(1, 0)) and Game.obstacles.size() > 0, "save keeps land and obstacles")
	# an hour away: the build finished
	d["time"] = int(d["time"]) - 3600
	Game.from_dict(d)
	ok(Game.jobs.is_empty() and Game.count_ready("src_data") == 1, "builds finish while you're away")
	ok(Game.offline_seconds >= 3599.0, "time away is known")
	# servers kept serving: tokens away count for the Lab level once collected
	d["trate"] = 2.0
	Game.from_dict(d)
	var t0 := float(Game.stats["tokens"])
	ok(Game.offline_tokens > 1000.0, "tokens served while away (%s)" % Fmt.tokens(Game.offline_tokens))
	Game.add_tokens(Game.offline_tokens)
	ok(float(Game.stats["tokens"]) > t0 and Game.level > 1, "collected tokens raise the Lab level")
	# the market's state saves too
	Market.orbit_modules = 2
	Market.set_price("pico", 1.3)
	var d2: Dictionary = JSON.parse_string(JSON.stringify(Game.to_dict()))
	Market.reset_state()
	Game.from_dict(d2)
	ok(Market.orbit_modules == 2 and is_equal_approx(Market.price_of("pico"), 1.3), "prices and the orbit save")
	# version 1 saves move to the API economy
	var v1 := {"v": 1, "buildings": [{"uid": 1, "kind": "van", "cell": [0, 0], "rot": 0, "lvl": 3, "data": {"cargo": ["t:pico"]}}, {"uid": 2, "kind": "cache", "cell": [4, 0], "rot": 0, "lvl": 2, "data": {}}], "money": 10.0, "stats": {"tokens": 50}}
	var v2 := Game.migrate_v1(v1)
	ok(v2["buildings"].size() == 1 and v2["buildings"][0]["kind"] == "gateway" and not v2["buildings"][0]["data"].has("cargo") and float(v2["money"]) > 10.0, "old saves: vans become gateways, token caches are refunded")
	Game.reset_state()


func _test_store() -> void:
	Game.reset_state()
	Live.reset_state()
	Live.tick()
	Store.sandbox = false
	if Store.backend == "":
		ok(not Store.available() and Store.unavailable_reason() != "" and not Store.buy("sparks_80"), "no store here: the shop says so and sells nothing")
	Store.sandbox = true
	var g0 := Game.gems
	ok(Store.buy("sparks_500") and Game.gems == g0 + 500, "a spark pack grants its sparks")
	ok(Store.buy("starter") and Game.gems == g0 + 900 and int(Live.boosters.get("warp60", 0)) >= 3, "the Starter Pack: sparks, Time Warps, a crate")
	ok(not Store.buy("starter"), "the Starter Pack is once only")
	ok(not Store.buy("nonsense"), "unknown products don't sell")
	Game.money = 1e9
	var p1 := Store.exchange_price()
	var g1 := Game.gems
	ok(Store.exchange() and Game.gems == g1 + Store.EXCHANGE_GEMS, "the Spark Exchange trades money for sparks")
	ok(Store.exchange_price() > p1, "dearer with every trade")
	while Store.exchange():
		pass
	ok(Store.exchange_left() == 0 and not Store.exchange(), "five trades a day")
	var d: Dictionary = JSON.parse_string(JSON.stringify(Game.to_dict()))
	Store.reset_state()
	Game.from_dict(d)
	ok(Store.starter_bought and Store.exchange_left() == 0, "the shop's state saves")
	Store.sandbox = false
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
	ok(Building.entrance_of("src_power", Vector2i(0, 0), 0) == ([Vector2i(1, 3)] as Array[Vector2i]), "3-wide entrance is one cell in front")
	ok(Building.entrance_of("depot", Vector2i(0, 0), 0).size() == 2, "2-wide entrance is two cells")
	ok(Building.entrance_of("src_power", Vector2i(0, 0), 2) == ([Vector2i(1, -1)] as Array[Vector2i]), "turned around, the entrance is behind")
	ok(Building.entrance_of("planter", Vector2i(0, 0), 0).is_empty(), "decor has no entrance")


func _test_roads_unit() -> void:
	var r := Roads.new()
	var walls := {}
	for y in range(2, 9):
		walls[Vector2i(5, y)] = true
	for x in range(5, 12):
		walls[Vector2i(x, 2)] = true
	var region := Rect2i(0, -1, 12, 13)
	var owned := func(c): return region.has_point(c)
	var entries := [
		{"uid": 1, "cells": [Vector2i(1, 9)] as Array[Vector2i], "stub": 1, "d": 8},
		{"uid": 2, "cells": [Vector2i(9, 9)] as Array[Vector2i], "stub": 1, "d": 8},
		{"uid": 3, "cells": [Vector2i(3, 0)] as Array[Vector2i], "stub": 1, "d": 0},
	]
	r.build(entries, func(c): return walls.has(c), owned, region)
	ok(r.connected.size() == 3, "every entrance joins the High Street")
	ok(r.cells.has(Vector2i(0, -1)) and r.cells.has(Vector2i(11, 0)), "the High Street runs through all your land")
	ok((r.paths[3] as Array).is_empty(), "an entrance on the High Street needs no road")
	var crosses := false
	for c in r.cells:
		if walls.has(c):
			crosses = true
	ok(not crosses, "roads never run through buildings")
	ok(r.route(Vector2i(9, 9), Vector2i(9, 0)).size() > 0, "couriers can walk from the far building to the High Street")
	ok(r.route(Vector2i(1, 9), Vector2i(9, 9)).size() > 0, "and from building to building")
	# walled in: no road
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		walls[Vector2i(9, 9) + d] = true
	r.build(entries, func(c): return walls.has(c), owned, region)
	ok(not r.connected.has(2), "a walled-in entrance gets no road")
	ok(Roads.is_street(Vector2i(500, Roads.STREET_Y)) and not Roads.is_street(Vector2i(0, Roads.STREET_Y + 2)), "the High Street is two rows, horizon to horizon")


func _test_holders() -> void:
	var a := Holder.new().setup(5, ["power"], Holder.Layout.COLUMN)
	var b := Holder.new().setup(2, [], Holder.Layout.COLUMN)
	b.accept_cat = ["raw"]
	add_child(a)
	add_child(b)
	for i in 3:
		a.add("power", false)
	ok(not a.can_accept("data"), "typed holder refuses other items")
	ok(b.can_accept("power") and not b.can_accept("t:mini") and not b.can_accept("gpu"), "category filter")
	ok(Holder.fly(a, b, "power", 0.05), "fly starts")
	ok(a.count() == 2 and b.incoming == 1, "item in flight is reserved")
	await get_tree().create_timer(0.2).timeout
	ok(b.count() == 1 and b.incoming == 0, "item landed")
	Holder.fly(a, b, "power", 0.05)
	ok(not Holder.fly(a, b, "power", 0.05), "full target refuses")
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
	Game.obstacles.clear()
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
	var server: ServerB = w.buildings_of("server")[0]
	ok(server.recipe == "pico", "the first server serves Pico 1B")
	# serve for real: customers call the API and the garage card answers
	for i in 3:
		server.cells.add("power", false)
	var tok0 := float(Game.stats["tokens"])
	var money0 := Game.money
	var t := await _wait_until(func(): return float(Game.stats["tokens"]) > tok0 + 0.3, 40.0)
	ok(float(Game.stats["tokens"]) > tok0 + 0.3 and Game.money > money0, "customers' API calls were answered and paid (%.1fs)" % t)
	ok(float(Market.cap.get("pico", 0.0)) > 0.0 and float(Market.demand.get("pico", 0.0)) > 0.0, "the market sees capacity and demand for Pico")
	ok(float(Market.served.get("pico", 0.0)) <= float(Market.cap.get("pico", 0.0)) + 0.0001, "never more served than the servers can answer")
	ok(Market.bandwidth >= Bal.GARAGE_BW and Market.used_bw <= Market.bandwidth + 0.0001, "everything leaving fits through the gateways")
	# no power: offline
	server.cells.clear_all()
	server._pw = 0.0
	ok(server.capacity() == 0.0 and server.offline, "without power the server is offline")
	# couriers bring power from the solar farm
	var farm: SourceB = w.buildings_of("src_power")[0]
	for i in 6:
		farm.crate.add("power", false)
	t = await _wait_until(func(): return server.cells.count() > 0 or server._pw > 0.0, 60.0)
	ok(server.cells.count() > 0 or server._pw > 0.0, "couriers brought power along the road (%.1fs)" % t)
	# a GPU: much faster, and room for bigger models
	var c0 := server.capacity_for("pico")
	server.gpu_in.add("gpu", false)
	server._install_gpu("gpu")
	ok(server.gpus() == 1 and server.capacity_for("pico") > c0 * 2.0, "a GPU more than doubles the garage rig (%s -> %s tok/s)" % [Fmt.tokens(c0), Fmt.tokens(server.capacity_for("pico"))])
	ok(is_equal_approx(server.vram(), Bal.GARAGE_VRAM + Bal.GPU_VRAM), "and adds 80 GB of VRAM")
	ok(not server.choices().has("chat7"), "only models you own")
	Game.known_recipes["chat7"] = true
	ok(server.choices().has("chat7") and not server.choices().has("chat13"), "Chat 7B fits in 92 GB; a model you don't own can't be loaded")
	server.choose("chat7")
	ok(server.recipe == "chat7", "choosing a model loads it")
	server.choose("")
	# tapping tunes it
	var c1 := server.capacity_for("pico")
	server.tap(Bal.TUNE_PLAYER)
	ok(server.tune > 0.0 and server.capacity_for("pico") > c1, "tapping a server tunes it (+%d%%)" % roundi((server.capacity_for("pico") / c1 - 1.0) * 100))
	# pricing: customers are price-sensitive
	var d1 := Market.api_demand("pico")
	Market.set_price("pico", 2.0)
	ok(Market.api_demand("pico") < d1 * 0.5, "doubling the price loses most customers")
	Market.set_price("pico", 1.0)
	# a dead GPU stops serving until it's replaced
	server._gpu_fails()
	ok(server.gpus() == 0 and server.dead() == 1, "GPUs wear out")
	server.gpu_in.add("gpu", false)
	server._install_gpu("gpu")
	ok(server.gpus() == 1 and server.dead() == 0, "a courier's GPU replaces the dead board")
	# a web crawler is built by a builder
	var sb := Game.place("src_data", Vector2i(-7, 3), 2)
	await get_tree().process_frame
	var site := w.building(int(sb["uid"]))
	ok(site is SiteB, "a construction site while it's being built")
	ok(site.on_road(), "the site already has its road")
	Game.finish_now(Game.job_of(int(sb["uid"])))
	await get_tree().process_frame
	var built := w.building(int(sb["uid"]))
	ok(built is SourceB, "the site turned into the source")
	# datacenter gear next to the server speeds it up (the "compute" aura)
	ok(is_equal_approx(server.compute_mult(), 1.0), "no compute aura without datacenter gear")
	var gear_at := Vector2i(999, 999)
	var sc := server.cell()
	for d in range(1, 9):  # the nearest free spot, ring by ring
		for dy in range(-d, d + 1):
			for dx in range(-d, d + 1):
				if gear_at.x == 999 and maxi(absi(dx), absi(dy)) == d and w.check_spot("rack_row", sc + Vector2i(dx, dy), 0)["ok"]:
					gear_at = sc + Vector2i(dx, dy)
	var cap_plain := server.capacity_for("pico")
	if gear_at.x != 999:
		var gb := Game.place("rack_row", gear_at, 0)
		await get_tree().process_frame
		await get_tree().process_frame
		server._compute_t = 0.0
		ok(absf(server.compute_mult() - 1.1) < 0.001, "a Rack Row nearby: servers work 10%% faster (x%.2f)" % server.compute_mult())
		ok(server.capacity_for("pico") >= cap_plain * 1.099, "the boost goes into the server's capacity")
		ok((w.building(int(gb["uid"])) as DecorB).status().contains("10%"), "the Rack Row says what it does")
		Game.remove(int(gb["uid"]), false)
		await get_tree().process_frame
		server._compute_t = 0.0
		ok(is_equal_approx(server.compute_mult(), 1.0), "the boost goes away with it")
	else:
		ok(false, "found a spot for a Rack Row near the server")
	# a building on top of a road: the road goes around
	var before := w.roads.connected.size()
	var road_cell: Vector2i = w.roads.cells.keys()[w.roads.cells.size() / 2]
	var spot := w.check_spot("planter", road_cell, 0)
	if spot["ok"]:
		Game.place("planter", road_cell, 0)
		await get_tree().process_frame
		await get_tree().process_frame
		ok(not w.roads.is_road(road_cell), "no road under the new flower bed")
		ok(w.roads.connected.size() >= before - 0, "everything still connected (%d / %d)" % [w.roads.connected.size(), before])
	# a building that would wall another off can't go there
	var cut_ok := true
	for n in w.bnodes.values():
		if n.has_entrance():
			var path: Array = w.roads.paths.get(n.uid, [])
			if path.size() > 2:
				var c2: Vector2i = path[path.size() / 2]
				var s2 := w.check_spot("planter", c2, 0)
				# either it's fine (another way round) or it says what it would cut off
				if not s2["ok"] and not str(s2["reason"]).contains("cut off") and not str(s2["reason"]).contains("entrance"):
					cut_ok = false
	ok(cut_ok, "spots on roads are refused only for a reason")
	# entrances must stay clear
	var e: Vector2i = server.entrance_cells()[0]
	ok(not w.check_spot("planter", e, 0)["ok"], "can't build on the Bakery's entrance")
	ok(not w.check_spot("planter", Vector2i(3, Roads.STREET_Y), 0)["ok"], "can't build on the High Street")
	# every kind of building spawns, answers the info panel and shows every look
	Game.money = 1e15
	for c in [Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1), Vector2i(-1, 1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(3, 0), Vector2i(3, 1)]:
		Game.land[Game.chunk_key(c)] = true
	var cx := 4
	var cy := 10
	for kind in Defs.BUILD_ORDER:
		var sz: Vector2i = Defs.BUILDINGS[kind]["size"]
		if cx + sz.x > 60:
			cx = 4
			cy += 7
		var b := Game.place(kind, Vector2i(cx, cy), 0, {"stage": 0} if kind == "mega" else {}, false)
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
	# the Training Cluster turns datasets into your own model
	var tr: TrainerB = w.buildings_of("trainer")[0]
	tr.data["auto"] = false
	tr.start("chat13")
	ok(tr.job() == "chat13" and tr.inputs.has("dataset") and not tr.ready_to_train(), "a training job waits for its data")
	for i in int(Defs.recipe("chat13")["train"]["dataset"]):
		tr.inputs["dataset"].add("dataset", false)
	tr.cells.add("power", false)
	ok(tr.ready_to_train() and tr.rate() > 0.0, "with data and power it trains")
	tr.data["progress"] = tr.job_compute() - 0.01
	await _wait_until(func(): return Game.known_recipes.has("chat13"), 5.0)
	ok(Game.known_recipes.has("chat13") and tr.job() == "", "training done: you own Chat 13B")
	Market.quality["chat13"] = 0.8
	tr.start("chat13", true)
	ok(tr.job_compute() < TrainerB.compute_for("chat13", false), "a refresh is cheaper than training")
	tr._finish()
	ok(Market.quality_of("chat13") > 0.8, "a refresh brings quality back")
	# the Launch Complex sends a module into orbit
	var lp: LaunchB = w.buildings_of("launchpad")[0]
	var gs: Array = w.buildings_of("groundstation")
	ok(gs.size() > 0, "a ground station")
	var om := Market.orbit_modules
	for k in LaunchB.PARTS:
		for i in int(LaunchB.PARTS[k]):
			lp.bays[k].add(k, false)
	t = await _wait_until(func(): return Market.orbit_modules > om, 40.0, 8.0)
	ok(Market.orbit_modules == om + 1 and Market.orbit_model != "", "the rocket reached orbit (%.1fs)" % t)
	ok(Market.orbit_capacity() > 0.0 and Market.orbit_capacity() <= Market.downlink() + 0.001, "orbit serves, as much as the downlink carries")
	ok(lp.state == LaunchB.S.TURNAROUND, "the pad needs a turnaround")
	# the Megacluster counts Frontier served since its last stage
	var mg: MegaB = w.buildings_of("mega")[0]
	var dl := mg.delivered()
	Game.serve("frontier", 5.0, 1.0)
	ok(is_equal_approx(mg.delivered(), dl + 5.0), "Frontier tokens served count for the Megacluster")
	await get_tree().process_frame
	w.queue_free()
	await get_tree().process_frame
	Game.reset_state()
