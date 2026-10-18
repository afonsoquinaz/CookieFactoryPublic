extends Node
## Autopilot that plays the real game for balance runs, like a sensible
## player who checks in now and then: finishes free jobs, saves up for and
## builds the sources and labs its best model needs, more servers and
## sales, upgrades what's slowest, hires couriers, clears obstacles, buys land
## when it runs out of room, researches, and finally builds the Megacluster.
## No sparks are spent on timers except free finishes.
##   tools/bot.sh [minutes]

var world: World
var minutes := 20.0
var _t := 0.0
var _report := 0.0
var _plan_cd := 0.0
var _first := {}
var _spent := {}
var _kind := "?"


func _ready() -> void:
	var a := Shot.args()
	minutes = float(a.get("minutes", "20"))
	seed(int(a.get("seed", "7")))
	Game.no_save = true
	Game.tutorial_step = 99
	Game.money_changed.connect(func(_v, d):
		if d < 0:
			_spent[_kind] = int(_spent.get(_kind, 0)) + int(-d))


func _process(dt: float) -> void:
	_t += dt
	_plan_cd -= dt
	if _plan_cd <= 0.0:
		_plan_cd = 1.0
		_manage()
	_report -= dt
	if _report <= 0.0:
		_report = 300.0 if _t > 1800.0 else 60.0
		_print_status()
	_milestones()
	if _t > minutes * 60.0:
		_print_status()
		print("BOT DONE ", JSON.stringify(_first))
		get_tree().quit()


# ---------------------------------------------------------------- planning

func _manage() -> void:
	for j in Game.jobs.duplicate():
		if Game.job_left(j) <= Bal.FREE_FINISH:
			Game.finish_now(j)
	_staff()
	if Game.free_builders() > 0:
		if _mega():
			return
		if _build_needed():
			return
		if _upgrade():
			return
		_clear()
	_research()


## The next new building worth saving for (its price is kept aside once
## it's within reach of about ten minutes of income).
func _goal_cost() -> float:
	var inc := Game.recent_income() * 60.0
	for k in _wants():
		if Game.count_of(k) > 0 or Game.build_block(k).begins_with("You"):
			continue
		var p := Game.price_of(k)
		if p < inc * 10.0 and p > Game.money:
			return p
		return 0.0
	return 0.0


func _spare() -> float:
	return Game.money - _goal_cost()


## Builds what's missing: sources for the best model, more servers, sales,
## housing, storage.
func _wants() -> Array[String]:
	var want: Array[String] = []
	var best := _target_recipe()
	for i in Defs.recipe(best)["ings"]:
		var p := Defs.producer_of(i)
		if Game.count_of(p) == 0:
			want.append(p)
		for j in Defs.BUILDINGS[p].get("in", {}):
			var p2 := Defs.producer_of(j)
			if p2 != "" and Game.count_of(p2) == 0:
				want.append(p2)
	for k in ["cafe", "desk", "depot", "cache", "batcher", "hyperloop", "agent_studio", "droneport"]:
		if Game.count_of(k) == 0:
			want.append(k)
	# more of what's already there, in proportion
	var servers := Game.count_of("server")
	var cap := {"server": 1 + Game.level / 3, "src_power": servers * 2, "src_data": servers, "van": servers, "cafe": 1 + servers / 2}
	for k in cap:
		if Game.count_of(k) < int(cap[k]):
			want.append(k)
	if not Game.can_hire() and Game.workers.size() < 2 + world.bnodes.size() / 3:
		want.append("dorm")
	return want


func _build_needed() -> bool:
	for k in _wants():
		if Game.build_block(k) != "":
			continue
		# new kinds may use the savings; more copies come out of spare money
		if Game.price_of(k) > (Game.money if Game.count_of(k) == 0 else _spare()):
			continue
		if _place(k):
			return true
	return false


func _target_recipe() -> String:
	var best := "pico"
	var bp := 0.0
	var slots := 1
	for n in world.buildings_of("server"):
		slots = maxi(slots, (n as ServerB).slots())
	for r in Defs.RECIPES:
		if (r["ings"] as Array).size() <= slots + 1 and float(r["price"]) > bp:
			bp = float(r["price"])
			best = r["id"]
	return best


func _upgrade() -> bool:
	var best: Building = null
	var bc := INF
	for n in world.bnodes.values():
		if n is SiteB or Bal.max_level(n.kind) <= 1:
			continue
		if Game.upgrade_block(n.uid) != "":
			continue
		var c := Bal.upgrade_cost(n.kind, n.level)
		# servers and vans first: they're the bottleneck
		var w := c
		if n is ServerB or n is VehicleB:
			w *= 0.5
		if w < bc and (c <= _spare() or c <= Game.money * 0.25):
			bc = w
			best = n
	if best:
		_kind = "upgrade"
		return Game.upgrade(best.uid)
	return false


func _clear() -> void:
	if Game.obstacle_price() > _spare() * 0.2:
		return
	for k in Game.obstacles:
		if Game.clear_block(k) == "":
			_kind = "clear"
			Game.clear_obstacle(k)
			return


func _staff() -> void:
	var want := 2 + world.bnodes.size() / 3
	if Game.workers.size() < want and Game.can_hire() and Game.hire_price() < _spare() * 0.4:
		_kind = "staff"
		Game.hire()


func _research() -> void:
	for id in ["recipe", "wspeed", "wcarry", "tools", "vehicles", "offline", "hiring", "market"]:
		if not Game.research_maxed(id) and Game.research_cost(id) < _spare() * 0.25:
			_kind = "research"
			Game.buy_research(id)
			return


func _mega() -> bool:
	if Game.count_of("mega") == 0:
		if Game.build_block("mega") == "" and Game.price_of("mega") <= Game.money:
			return _place("mega")
		return false
	for n in world.buildings_of("mega"):
		var p := n as MegaB
		if p.can_advance():
			_kind = "mega"
			return p.advance()
	return false


# ---------------------------------------------------------------- placing

func _place(kind: String) -> bool:
	var spot = _find_spot(kind)
	if spot == null:
		if _buy_land():
			spot = _find_spot(kind)
		if spot == null:
			return false
	_kind = "build"
	var b := Game.place(kind, spot[0], spot[1], {"stage": 0} if kind == "mega" else {})
	if not b.is_empty():
		print("[%6.0fs] built %s" % [_t, kind])
		return true
	return false


## Nearest spot to the middle of the High Street that fits and gets a road.
func _find_spot(kind: String) -> Variant:
	var c := Vector2i.ZERO
	for r in range(2, 40):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for q in [Vector2i(dx, dy), Vector2i(dy, dx)]:
					for rot in [0, 2]:
						var o: Vector2i = c + q
						# face the street
						if (rot == 0) != (o.y < Roads.STREET_Y):
							continue
						var s := world.check_spot(kind, o, rot)
						if not s["ok"]:
							continue
						if Building.kind_has_entrance(kind):
							var road := world.preview_road(kind, o, rot)
							var on := false
							for e in s["entrance"]:
								if world.roads.is_road(e):
									on = true
							if road.is_empty() and not on:
								continue
						# leave a gap so roads can pass
						if not _roomy(kind, o, rot):
							continue
						return [o, rot]
	return null


func _roomy(kind: String, o: Vector2i, rot: int) -> bool:
	var sz := Grid.rotated(Defs.size_of(kind), rot)
	var ring := 0
	for x in range(-1, sz.x + 1):
		for y in range(-1, sz.y + 1):
			if x >= 0 and y >= 0 and x < sz.x and y < sz.y:
				continue
			if world.grid.blocked(o + Vector2i(x, y)):
				ring += 1
	return ring <= (sz.x + sz.y)


func _buy_land() -> bool:
	if Game.land_price() > _spare():
		return false
	var best := Vector2i.ZERO
	var bd := INF
	for k in Game.land:
		var p: PackedStringArray = str(k).split(",")
		var c := Vector2i(int(p[0]), int(p[1]))
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			if Game.can_buy_chunk(c + d) and Vector2(c + d).length() < bd:
				bd = Vector2(c + d).length()
				best = c + d
	if bd < INF:
		_kind = "land"
		if Game.buy_chunk(best):
			print("[%6.0fs] bought land %s for $%s" % [_t, best, Fmt.num(Game.land_price())])
			return true
	return false


# ---------------------------------------------------------------- reporting

func _milestones() -> void:
	var checks := {
		"first_sale": int(Game.stats["tokens"]) > 0,
		"lvl2": Game.level >= 2, "lvl3": Game.level >= 3, "lvl4": Game.level >= 4, "lvl5": Game.level >= 5,
		"lvl6": Game.level >= 6, "lvl8": Game.level >= 8, "lvl10": Game.level >= 10, "lvl12": Game.level >= 12,
		"lvl15": Game.level >= 15, "mini": Game.known_recipes.has("mini"), "code13": Game.known_recipes.has("code13"),
		"frontier": Game.known_recipes.has("frontier"), "mega": Game.count_of("mega") > 0, "won": Game.won,
	}
	for k in checks:
		if checks[k] and not _first.has(k):
			_first[k] = int(_t)
			print("[%6.0fs] milestone %s  money=%s level=%d" % [_t, k, Fmt.num(Game.money), Game.level])


func _print_status() -> void:
	var recipes := []
	for n in world.buildings_of("server"):
		recipes.append((n as ServerB).recipe)
	var off := []
	for n in world.bnodes.values():
		if n.has_entrance() and not n is SiteB and not n.on_road():
			off.append(n.kind)
	var states := {}
	for w in world.workers.values():
		var k: String = Worker.S.keys()[w.state]
		states[k] = int(states.get(k, 0)) + 1
	if not off.is_empty() or _t < 1200.0:
		print("        off-road %s  couriers %s" % [off, states])
	if Game.recent_income() <= 0.0 and _t > 300.0:
		for w in world.workers.values():
			print("        worker %s carry %s dst %s" % [Worker.S.keys()[w.state], w.carry.items, w._dst.name if is_instance_valid(w._dst) else "-"])
		for n in world.bnodes.values():
			var parts := []
			for p in n.ports:
				var h: Holder = p["holder"]
				parts.append("%s %d/%d" % [p["dir"], h.count(), h.capacity])
			var extra := ""
			if n is VehicleB:
				extra = " state=%s" % VehicleB.S.keys()[(n as VehicleB).state]
			print("        %s %s%s" % [n.name, parts, extra])
	print("[%6.0fs] $%s  +%s/min  lvl %d  sparks %d  tokens %d  servers %s  bld %d  land %d  staff %d  jobs %d/%d  spent=%s" % [
		_t, Fmt.num(Game.money), Fmt.num(Game.recent_income() * 60.0), Game.level, Game.gems, int(Game.stats["tokens"]),
		recipes, world.bnodes.size(), Game.land.size(), Game.workers.size(), Game.jobs.size(), Game.builders(), JSON.stringify(_spent)])
