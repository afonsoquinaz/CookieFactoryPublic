extends Node
## Autopilot that plays the real game for balance runs, like a sensible
## player who checks in now and then: finishes free jobs, upgrades the Cookie
## Hall whenever it can, builds the farms and kitchens its best recipe needs,
## more bakeries and sales, upgrades what's slowest, hires porters, clears
## obstacles, buys land when it runs out of room, researches, and finally
## builds the Palace. No gems are spent on timers except free finishes.
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
		if _hall():
			return
		if _palace():
			return
		if _build_needed():
			return
		if _upgrade():
			return
		_clear()
	_research()


## Money the Hall upgrade needs (kept aside once it's within reach).
func _hall_cost() -> float:
	return Bal.upgrade_cost("hall", Game.level) if Game.level < Defs.HALL.size() else INF


func _saving() -> bool:
	var inc := Game.recent_income() * 60.0
	return _hall_cost() < inc * 12.0 and _hall_cost() > Game.money


func _spare() -> float:
	return Game.money - (_hall_cost() if _saving() else 0.0)


func _hall() -> bool:
	var h := world.hall()
	if h == null or Game.level >= Defs.HALL.size() or not Game.job_of(h.uid).is_empty():
		return false
	if Game.upgrade_block(h.uid) == "":
		_kind = "hall"
		Game.upgrade(h.uid)
		return true
	return false


## Builds what's missing: farms for the best recipe, more bakeries, sales,
## cabins, storage.
func _build_needed() -> bool:
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
	want.append_array(["shop", "board", "pantry", "rack", "cabin", "packer", "train", "wrapper", "airship"])
	# more of what's already there once the hall allows it
	for k in ["bakery", "farm_wheat", "farm_sugar", "dock", "cabin", "shop"]:
		want.append(k)
	for k in want:
		if Game.build_block(k) != "":
			continue
		if Game.price_of(k) > _spare():
			continue
		if _place(k):
			return true
	return false


func _target_recipe() -> String:
	var best := "shortbread"
	var bp := 0.0
	var slots := 1
	for n in world.buildings_of("bakery"):
		slots = maxi(slots, (n as BakeryB).slots())
	for r in Defs.RECIPES:
		if Defs.recipe_level(r["id"]) <= Game.level and (r["ings"] as Array).size() <= slots + 1 and float(r["price"]) > bp:
			bp = float(r["price"])
			best = r["id"]
	return best


func _upgrade() -> bool:
	var best: Building = null
	var bc := INF
	for n in world.bnodes.values():
		if n is SiteB or n is HallB or Bal.max_level(n.kind) <= 1:
			continue
		if Game.upgrade_block(n.uid) != "":
			continue
		var c := Bal.upgrade_cost(n.kind, n.level)
		# bakeries and vans first: they're the bottleneck
		var w := c
		if n is BakeryB or n is VehicleB:
			w *= 0.5
		if w < bc and c <= _spare():
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


func _palace() -> bool:
	if Game.count_of("palace") == 0:
		if Game.build_block("palace") == "" and Game.price_of("palace") <= Game.money:
			return _place("palace")
		return false
	for n in world.buildings_of("palace"):
		var p := n as PalaceB
		if p.can_advance():
			_kind = "palace"
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
	var b := Game.place(kind, spot[0], spot[1], {"stage": 0} if kind == "palace" else {})
	if not b.is_empty():
		print("[%6.0fs] built %s" % [_t, kind])
		return true
	return false


## Nearest spot to the Hall that fits and gets a road.
func _find_spot(kind: String) -> Variant:
	var h := world.hall()
	var c := Grid.cell_of(h.global_position) if h else Vector2i.ZERO
	for r in range(2, 40):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for q in [Vector2i(dx, dy), Vector2i(dy, dx)]:
					for rot in [0, 2]:
						var o: Vector2i = c + q
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
		"first_sale": int(Game.stats["cookies"]) > 0,
		"hall2": Game.level >= 2, "hall3": Game.level >= 3, "hall4": Game.level >= 4, "hall5": Game.level >= 5,
		"hall6": Game.level >= 6, "hall8": Game.level >= 8, "hall10": Game.level >= 10, "hall12": Game.level >= 12,
		"hall15": Game.level >= 15, "sugar": Game.known_recipes.has("sugar"), "choc": Game.known_recipes.has("choc"),
		"royal": Game.known_recipes.has("royal"), "palace": Game.count_of("palace") > 0, "won": Game.won,
	}
	for k in checks:
		if checks[k] and not _first.has(k):
			_first[k] = int(_t)
			print("[%6.0fs] milestone %s  money=%s hall=%d" % [_t, k, Fmt.num(Game.money), Game.level])


func _print_status() -> void:
	var recipes := []
	for n in world.buildings_of("bakery"):
		recipes.append((n as BakeryB).recipe)
	print("[%6.0fs] $%s  +%s/min  hall %d  gems %d  cookies %d  bakeries %s  bld %d  land %d  staff %d  jobs %d/%d  spent=%s" % [
		_t, Fmt.num(Game.money), Fmt.num(Game.recent_income() * 60.0), Game.level, Game.gems, int(Game.stats["cookies"]),
		recipes, world.bnodes.size(), Game.land.size(), Game.workers.size(), Game.jobs.size(), Game.builders(), JSON.stringify(_spent)])
