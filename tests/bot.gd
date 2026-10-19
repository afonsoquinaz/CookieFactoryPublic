extends Node
## Autopilot that plays the real game for balance runs, like a sensible
## player who checks in now and then: finishes free jobs, downloads open
## models, builds a Chip Fab for GPUs and a Training Cluster with the labs
## its next model's data needs, adds servers when demand outruns capacity
## and customers (gateways, café, edge, agents) when capacity is idle,
## taps servers now and then, nudges prices, upgrades, hires, clears
## obstacles, buys land, researches, launches to orbit and finally builds
## the Megacluster. No sparks are spent on timers except free finishes.
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
	Live.events_on = false
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
	_download()
	_prices()
	_tap()
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


## Open weights as soon as they're affordable.
func _download() -> void:
	for r in Defs.RECIPES:
		if int(r["open"]) >= 0 and not Game.known_recipes.has(r["id"]) and float(r["open"]) <= _spare() * 0.5:
			_kind = "download"
			if Game.download(r["id"]):
				print("[%6.0fs] downloaded %s" % [_t, r["id"]])


## Busy servers: a little dearer; idle ones: a little cheaper.
func _prices() -> void:
	for rid in Market.cap:
		var c := float(Market.cap[rid])
		var u := float(Market.served.get(rid, 0.0)) / c if c > 0.0 else 0.0
		if u > 0.97:
			Market.set_price(rid, Market.price_of(rid) + 0.05)
		elif u < 0.6 and Market.price_of(rid) > 0.8:
			Market.set_price(rid, Market.price_of(rid) - 0.05)


## A player checking in taps a server or two.
var _tap_cd := 0.0
func _tap() -> void:
	_tap_cd -= 1.0
	if _tap_cd > 0.0:
		return
	_tap_cd = 6.0
	var low: ServerB = null
	for n in world.buildings_of("server"):
		if low == null or (n as ServerB).tune < low.tune:
			low = n
	if low:
		low.tap(Bal.TUNE_PLAYER)


## The next model to train: the first one you don't own.
func _next_model() -> Dictionary:
	for r in Defs.RECIPES:
		if not Game.known_recipes.has(r["id"]) and int(r["open"]) < 0:
			return r
	return {}


func _want_producer(want: Array[String], item: String) -> void:
	var p := Defs.producer_of(item)
	if p == "" or Game.count_of(p) > 0:
		return
	want.append(p)
	for j in Defs.BUILDINGS[p].get("in", {}):
		_want_producer(want, j)


## Builds what's missing: hardware supply, the next model's data, more
## servers when demand outruns them, more customers when they idle.
func _wants() -> Array[String]:
	var want: Array[String] = []
	var servers := Game.count_of("server")
	var cap := Market.total(Market.cap)
	var dem := Market.total(Market.demand)
	if Game.money > 400.0 or servers > 1:
		_want_producer(want, "gpu")
	if Game.count_of("fab") > 0 and Game.count_of("src_coolant") == 0:
		want.append("src_coolant")
	var nm := _next_model()
	if not nm.is_empty() and Game.level >= 2:
		if Game.count_of("trainer") == 0:
			want.append("trainer")
		for i in nm["train"]:
			_want_producer(want, i)
	if Game.level >= 5:
		_want_producer(want, "hbm")
	for k in ["cafe", "desk", "depot"]:
		if Game.count_of(k) == 0:
			want.append(k)
	if Game.level >= 6 and Game.count_of("edge") == 0:
		want.append("edge")
	if Game.level >= 9 and Game.count_of("agent_hub") == 0:
		want.append("agent_hub")
	if Game.level >= 11:
		for k in ["groundstation", "launchpad"]:
			if Game.count_of(k) == 0:
				want.append(k)
	# more of what's already there, in proportion
	if dem > cap * 1.15 and servers < 2 + Game.level:
		want.append("server")
	if Market.used_bw >= Market.bandwidth * 0.9 or cap > dem * 1.4:
		want.append("gateway")
	var more := {"src_power": servers * 2, "cafe": 1 + servers / 3}
	for k in more:
		if Game.count_of(k) < int(more[k]):
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


func _upgrade() -> bool:
	var best: Building = null
	var bc := INF
	for n in world.bnodes.values():
		if n is SiteB or Bal.max_level(n.kind) <= 1:
			continue
		if Game.upgrade_block(n.uid) != "":
			continue
		var c := Bal.upgrade_cost(n.kind, n.level)
		# servers and gateways first: they're the bottleneck
		var w := c
		if n is ServerB or n.kind == "gateway" or n is TrainerB:
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
	for id in ["recipe", "kv", "devrel", "wspeed", "wcarry", "tools", "spec", "tuning", "offline", "hiring", "market"]:
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
		"first_sale": float(Game.stats["tokens"]) > 0.0, "gpu": _any_gpu(), "trained": Game.known_recipes.has("chat13"), "orbit": Market.orbit_modules > 0,
		"lvl2": Game.level >= 2, "lvl3": Game.level >= 3, "lvl4": Game.level >= 4, "lvl5": Game.level >= 5,
		"lvl6": Game.level >= 6, "lvl8": Game.level >= 8, "lvl10": Game.level >= 10, "lvl12": Game.level >= 12,
		"lvl15": Game.level >= 15, "mini": Game.known_recipes.has("mini"), "code13": Game.known_recipes.has("code13"),
		"frontier": Game.known_recipes.has("frontier"), "mega": Game.count_of("mega") > 0, "won": Game.won,
	}
	for k in checks:
		if checks[k] and not _first.has(k):
			_first[k] = int(_t)
			print("[%6.0fs] milestone %s  money=%s level=%d" % [_t, k, Fmt.num(Game.money), Game.level])


func _any_gpu() -> bool:
	for n in world.buildings_of("server"):
		if (n as ServerB).gpus() > 0:
			return true
	return false


func _print_status() -> void:
	var recipes := []
	for n in world.buildings_of("server"):
		recipes.append("%s/%dg" % [(n as ServerB).recipe, (n as ServerB).gpus()])
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
			print("        %s %s" % [n.name, parts])
	print("[%6.0fs] $%s  +%s/min  lvl %d  sparks %d  tokens %s  cap %s dem %s bw %s/%s rep %.2f  servers %s  bld %d  land %d  staff %d  jobs %d/%d  spent=%s" % [
		_t, Fmt.num(Game.money), Fmt.num(Game.recent_income() * 60.0), Game.level, Game.gems, Fmt.tokens(float(Game.stats["tokens"])),
		Fmt.tokens(Market.total(Market.cap)), Fmt.tokens(Market.total(Market.demand)), Fmt.tokens(Market.used_bw), Fmt.tokens(Market.bandwidth), Market.rep,
		recipes, world.bnodes.size(), Game.land.size(), Game.workers.size(), Game.jobs.size(), Game.builders(), JSON.stringify(_spent)])
