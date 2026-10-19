extends Node
## Game state: money, sparks, the Lab level, every placed building,
## builders and their jobs, owned land and its obstacles, research, perks,
## staff, orders. Owns saving/loading and offline progress. Gameplay nodes
## read and change state only through here and listen to its signals.
##
## Time: `clock` is game time in seconds. It runs while you play and jumps
## ahead by the time you were away, so builds and upgrades finish offline,
## like in any base builder.

signal money_changed(value: float, delta: float)
signal gems_changed(value: int)
signal level_up(level: int, gems: int)
signal building_added(b: Dictionary)
signal building_built(uid: int)
signal building_removed(uid: int)
signal building_moved(uid: int)
signal building_upgraded(uid: int, level: int)
signal jobs_changed
signal job_done(job: Dictionary)
signal land_bought(chunk: Vector2i)
signal obstacles_changed
signal obstacle_cleared(key: String, gems: int)
signal researched(id: String, level: int)
signal workers_changed
signal rush_changed(active: bool)
signal orders_changed
signal trend_changed(recipe: String)
signal discovered(recipe: String)
signal toast(text: String, icon: String)
signal victory
signal tracked(metric: String, n: float, arg: String)   # for Live: quests, goals, badges

const SAVE_PATH := "user://token_empire_v1.json"
const VERSION := 1

var money := 0.0
var gems := 0
var level := 1                # Lab level: grows with lifetime tokens served
var clock := 0.0              # game time (s), includes time away
var research_lv := {}         # id -> level
var perks := {}               # id -> level
var buildings: Array = []     # [{uid, kind, cell: [x, y], rot, lvl, data, recipe?, stage?}] lvl 0 = being built
var next_uid := 1
var jobs: Array = []          # [{type: build|upgrade|clear|stage, uid, ob, start, end}]
var land := {}                # "x,y" -> true for owned chunks
var land_bought_n := 0
var obstacles := {}           # "x,y" (cell) -> {kind, gems}
var cleared := 0
var workers: Array = []       # [{id, role, target}] target = building uid (technicians/engineers)
var next_worker_id := 1
var hired := 0
var stats := {"tokens": 0, "earned": 0.0, "batches": 0, "play_time": 0.0, "orders": 0, "customers": 0, "frontier": 0}
var known_recipes := {}       # model id -> true once served
var orders: Array = []        # [{item, count, got, reward, gems}]
var trending := ""
var trend_t := 0.0
var settings := {"music": true, "sfx": true, "haptics": true}
var tutorial_step := 0
var income_rate := 0.0
var rush_time := 0.0
var rush_cooldown := 0.0
var offline_reward := 0.0
var offline_tokens := 0          # tokens served while you were away (collected with the reward)
var offline_seconds := 0.0
var won := false

var _save_timer := 0.0
var _income_window: Array = []
var _token_window: Array = []
var _clock := 0.0
var _counts := {}             # kind -> count (cache)
var loaded := false
## When true (tests), nothing is written to disk.
var no_save := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_state()
	if not "--fresh" in OS.get_cmdline_user_args():
		load_game()
	else:
		loaded = true


func reset_state() -> void:
	money = Bal.START_MONEY
	gems = Bal.START_GEMS
	level = 1
	clock = 0.0
	research_lv = {}
	perks = {}
	buildings = []
	next_uid = 1
	jobs = []
	land = {}
	land_bought_n = 0
	obstacles = {}
	cleared = 0
	workers = []
	next_worker_id = 1
	hired = 0
	stats = {"tokens": 0, "earned": 0.0, "batches": 0, "play_time": 0.0, "orders": 0, "customers": 0, "frontier": 0}
	known_recipes = {}
	orders = []
	trending = ""
	trend_t = 60.0
	tutorial_step = 0
	rush_time = 0.0
	rush_cooldown = 0.0
	offline_reward = 0.0
	offline_tokens = 0
	offline_seconds = 0.0
	won = false
	_counts = {}
	_starting_empire()


## A new empire on four plots of valley along the High Street: a Solar
## Farm, an Inference Server (a garage rig serving Pico 1B) and a Supply
## Depot on the north side; Staff Housing, an API Depot and two Builder's
## Huts on the south side; three couriers, and some brambles, e-waste and
## an old container to clear.
func _starting_empire() -> void:
	for x in [-1, 0]:
		for y in [-1, 0]:
			land["%d,%d" % [x, y]] = true
	_add("src_power", Vector2i(-6, -5), 0)
	_add("server", Vector2i(-2, -5), 0)
	_add("depot", Vector2i(4, -4), 0)
	_add("van", Vector2i(-1, 2), 2)
	_add("hut", Vector2i(3, 2), 2)
	_add("hut", Vector2i(5, 2), 2)
	_add("dorm", Vector2i(-4, 2), 2)
	known_recipes["pico"] = true
	for i in 3:
		workers.append({"id": next_worker_id, "role": "courier", "target": 0})
		next_worker_id += 1
	for ob in [["bush", Vector2i(-6, 3), 1], ["ewaste", Vector2i(-3, 5), 0], ["rock", Vector2i(6, 6), 2], ["oak", Vector2i(-7, 5), 3],
			["bush", Vector2i(6, -8), 0], ["pine", Vector2i(1, -8), 1], ["container", Vector2i(-8, -8), 2], ["bush", Vector2i(2, 5), 1]]:
		obstacles[cell_key(ob[1])] = {"kind": ob[0], "gems": ob[2]}


func _process(dt: float) -> void:
	_clock += dt
	clock += dt
	stats["play_time"] = float(stats["play_time"]) + dt
	_check_jobs()
	if rush_time > 0.0:
		rush_time -= dt
		if rush_time <= 0.0:
			rush_time = 0.0
			rush_changed.emit(false)
	if rush_cooldown > 0.0:
		rush_cooldown -= dt
	trend_t -= dt
	if trend_t <= 0.0:
		_new_trend()
	_save_timer += dt
	if _save_timer > 8.0:
		_save_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


# ---------------------------------------------------------------- money

func add_money(amount: float, earned := true) -> void:
	if amount == 0.0:
		return
	money += amount
	if earned and amount > 0.0:
		stats["earned"] = float(stats["earned"]) + amount
		_income_window.append([_clock, amount])
		track("money", amount)
	money_changed.emit(money, amount)
	if earned and amount > 0.0:
		_check_level()


## Lab level from lifetime tokens served.
static func level_for(earned: float) -> int:
	var l := 1
	for i in Defs.EMPIRE.size():
		if earned >= float(Defs.EMPIRE[i]["xp"]):
			l = i + 1
	return l


## Progress (0..1) toward the next Lab level.
func level_progress() -> float:
	if level >= Defs.EMPIRE.size():
		return 1.0
	var a := float(Defs.EMPIRE[level - 1]["xp"])
	var b := float(Defs.EMPIRE[level]["xp"])
	return clampf((float(stats["tokens"]) - a) / (b - a), 0.0, 1.0)


func _check_level() -> void:
	var l := level_for(float(stats["tokens"]))
	while level < l:
		level += 1
		var g := int(Defs.EMPIRE[level - 1]["gems"])
		add_gems(g)
		refill_orders()
		level_up.emit(level, g)


func can_afford(amount: float) -> bool:
	return money >= amount - 0.001


func spend(amount: float) -> bool:
	if not can_afford(amount):
		return false
	money = maxf(0.0, money - amount)
	money_changed.emit(money, -amount)
	return true


func add_gems(n: int) -> void:
	gems += n
	gems_changed.emit(gems)


## Tokens served per second over the last two minutes (HUD).
func token_rate() -> float:
	while _token_window.size() > 0 and _clock - float(_token_window[0][0]) > 120.0:
		_token_window.pop_front()
	var s := 0.0
	for e in _token_window:
		s += float(e[1])
	return s / clampf(_clock, 30.0, 120.0)


## Money per second over the last two minutes (offline earnings + HUD).
func recent_income() -> float:
	while _income_window.size() > 0 and _clock - float(_income_window[0][0]) > 120.0:
		_income_window.pop_front()
	var s := 0.0
	for e in _income_window:
		s += float(e[1])
	return s / clampf(_clock, 30.0, 120.0)


## Tokens served somewhere else (time away): they count for the Lab level.
func add_tokens(n: int) -> void:
	if n <= 0:
		return
	stats["tokens"] = int(stats["tokens"]) + n
	_check_level()


## Something happened that the daily layer counts (see Live.track).
func track(metric: String, n := 1.0, arg := "") -> void:
	tracked.emit(metric, n, arg)


## Sells items through a channel. Returns the money made.
func sell(items: Array, mult := 1.0, agent_mult := 1.0) -> float:
	var total := 0.0
	var n := 0
	for t in items:
		var v := Bal.item_value(t) * mult
		if Defs.cat(t) == "agent":
			v *= agent_mult
		total += v
		var tc := Defs.token_count(t)
		n += tc
		var rid := Defs.recipe_of(t)
		if rid == "frontier":
			stats["frontier"] = int(stats["frontier"]) + 1
		track("served", tc, rid)
		if rid == trending:
			track("trend_tokens", tc)
		if Defs.cat(t) == "agent":
			track("agents", 1)
	stats["tokens"] = int(stats["tokens"]) + n
	track("tokens", n)
	track("sales", n)
	_token_window.append([_clock, n])
	total = roundf(total)
	add_money(total)
	_check_level()
	return total


# ---------------------------------------------------------------- buildings

func _add(kind: String, cell: Vector2i, rot: int, extra := {}) -> Dictionary:
	var b := {"uid": next_uid, "kind": kind, "cell": [cell.x, cell.y], "rot": rot, "lvl": 1, "data": {}}
	for k in extra:
		b[k] = extra[k]
	next_uid += 1
	buildings.append(b)
	_counts.erase(kind)
	return b


func count_of(kind: String) -> int:
	if _counts.has(kind):
		return _counts[kind]
	var n := 0
	for b in buildings:
		if b["kind"] == kind:
			n += 1
	_counts[kind] = n
	return n


## Built and working (not still under construction).
func count_ready(kind: String) -> int:
	var n := 0
	for b in buildings:
		if b["kind"] == kind and int(b["lvl"]) > 0:
			n += 1
	return n


func price_of(kind: String) -> float:
	return Bal.build_cost(kind, count_of(kind))


## Spark price for the next copy (builder huts), 0 when it costs money.
func gem_price_of(kind: String) -> int:
	var g: Array = Defs.BUILDINGS[kind].get("gems", [])
	var n := count_of(kind)
	return int(g[n]) if n < g.size() else 0


func build_time_of(kind: String) -> float:
	return Bal.build_time(kind, count_of(kind))


## Why a new building can't be placed now ("" when it can).
func build_block(kind: String) -> String:
	if not Live.is_unlocked(kind):
		return "Locked: " + LiveDefs.EXCLUSIVE[kind]
	var mx := Defs.limit_of(kind)
	if mx >= 0 and count_of(kind) >= mx:
		return "You have all of these" if mx > 1 else "You already have one"
	var gp := gem_price_of(kind)
	if gp > 0 and gems < gp:
		return "Needs %d sparks" % gp
	if gp == 0 and not can_afford(price_of(kind)):
		return "Not enough money"
	if build_time_of(kind) > 0.0 and free_builders() <= 0:
		return "All builders are busy"
	return ""


func building(uid: int) -> Dictionary:
	for b in buildings:
		if int(b["uid"]) == uid:
			return b
	return {}


static func cell_of(b: Dictionary) -> Vector2i:
	return Vector2i(int(b["cell"][0]), int(b["cell"][1]))


## Places a new building. It's built by a builder over time unless it's
## instant (decor, huts). pay = false skips the price and the builder.
func place(kind: String, cell: Vector2i, rot: int, extra := {}, pay := true) -> Dictionary:
	var t := build_time_of(kind)
	if pay:
		if build_block(kind) != "":
			return {}
		var gp := gem_price_of(kind)
		if gp > 0:
			gems -= gp
			gems_changed.emit(gems)
		elif not spend(price_of(kind)):
			return {}
	var e := extra.duplicate()
	if pay and t > 0.0 and not e.has("lvl"):
		e["lvl"] = 0
	var b := _add(kind, cell, rot, e)
	if int(b["lvl"]) == 0:
		_start_job("build", int(b["uid"]), t)
	building_added.emit(b)
	save_game()
	return b


func move(uid: int, cell: Vector2i, rot: int) -> void:
	var b := building(uid)
	if b.is_empty():
		return
	b["cell"] = [cell.x, cell.y]
	b["rot"] = rot
	building_moved.emit(uid)
	save_game()


## Sells a building for half of what the next one would cost.
func remove(uid: int, refund := true) -> float:
	var b := building(uid)
	if b.is_empty():
		return 0.0
	for j in jobs.duplicate():
		if int(j.get("uid", 0)) == uid:
			jobs.erase(j)
	buildings.erase(b)
	_counts.erase(b["kind"])
	var back := 0.0
	if refund and gem_price_of(b["kind"]) == 0:
		back = roundf(Bal.build_cost(b["kind"], count_of(b["kind"])) * 0.5)
		add_money(back, false)
	for w in workers:
		if int(w.get("target", 0)) == uid:
			w["target"] = 0
			w["role"] = ""
	building_removed.emit(uid)
	workers_changed.emit()
	jobs_changed.emit()
	save_game()
	return back


## Why this building can't be upgraded now ("" when it can).
func upgrade_block(uid: int) -> String:
	var b := building(uid)
	if b.is_empty():
		return "?"
	var l := int(b["lvl"])
	var kind: String = b["kind"]
	if l <= 0 or job_of(uid).size() > 0:
		return "Already being built"
	if l >= Bal.max_level(kind):
		return "Max level"
	if free_builders() <= 0:
		return "All builders are busy"
	if not can_afford(Bal.upgrade_cost(kind, l)):
		return "Not enough money"
	return ""


## Starts an upgrade: pays, and a builder gets to work.
func upgrade(uid: int) -> bool:
	if upgrade_block(uid) != "":
		return false
	var b := building(uid)
	var l := int(b["lvl"])
	if not spend(Bal.upgrade_cost(b["kind"], l)):
		return false
	var t := Bal.upgrade_time(b["kind"], l)
	if t <= 0.0:
		_finish_upgrade(b)
	else:
		_start_job("upgrade", uid, t)
	save_game()
	return true


func _finish_upgrade(b: Dictionary) -> void:
	b["lvl"] = int(b["lvl"]) + 1
	var uid := int(b["uid"])
	building_upgraded.emit(uid, int(b["lvl"]))
	track("upgrades")


## Whether the empire can currently make an ingredient.
func can_make(ing: String) -> bool:
	if ing == "power":
		return true
	var p := Defs.producer_of(ing)
	return p != "" and count_ready(p) > 0


# ---------------------------------------------------------------- builders + jobs

func builders() -> int:
	return count_ready("hut")


func free_builders() -> int:
	return maxi(0, builders() - jobs.size())


func job_of(uid: int) -> Dictionary:
	for j in jobs:
		if int(j.get("uid", 0)) == uid:
			return j
	return {}


func job_of_obstacle(key: String) -> Dictionary:
	for j in jobs:
		if str(j.get("ob", "")) == key:
			return j
	return {}


func job_left(j: Dictionary) -> float:
	return maxf(0.0, float(j["end"]) - clock)


func job_progress(j: Dictionary) -> float:
	var total := float(j["end"]) - float(j["start"])
	return 1.0 if total <= 0.0 else clampf((clock - float(j["start"])) / total, 0.0, 1.0)


func _start_job(type: String, uid: int, seconds: float, ob := "") -> Dictionary:
	var j := {"type": type, "uid": uid, "ob": ob, "start": clock, "end": clock + seconds}
	jobs.append(j)
	jobs_changed.emit()
	return j


## Finishes a job now for sparks (free when nearly done).
func finish_now(j: Dictionary) -> bool:
	if not jobs.has(j):
		return false
	var g := Bal.finish_gems(job_left(j))
	if gems < g:
		return false
	gems -= g
	if g > 0:
		gems_changed.emit(gems)
	j["end"] = clock
	_check_jobs()
	return true


func _check_jobs() -> void:
	if jobs.is_empty():
		return
	var done := []
	for j in jobs:
		if clock >= float(j["end"]):
			done.append(j)
	for j in done:
		jobs.erase(j)
		_complete(j)
	if not done.is_empty():
		jobs_changed.emit()
		save_game()


func _complete(j: Dictionary) -> void:
	match j["type"]:
		"build":
			var b := building(int(j["uid"]))
			if not b.is_empty():
				b["lvl"] = maxi(1, int(b["lvl"]))
				_counts.erase(b["kind"])
				building_built.emit(int(b["uid"]))
				track("builds")
		"upgrade":
			var b2 := building(int(j["uid"]))
			if not b2.is_empty():
				_finish_upgrade(b2)
		"stage":
			var b3 := building(int(j["uid"]))
			if not b3.is_empty():
				b3["stage"] = int(b3.get("stage", 0)) + 1
				b3["frontier"] = 0
				building_upgraded.emit(int(b3["uid"]), int(b3["lvl"]))
				if int(b3["stage"]) >= Defs.MEGA_STAGES.size() - 1:
					won = true
					victory.emit()
		"clear":
			var ob: Dictionary = obstacles.get(j["ob"], {})
			if not ob.is_empty():
				var g := int(ob.get("gems", 0))
				obstacle_cleared.emit(j["ob"], g)
				obstacles.erase(j["ob"])
				cleared += 1
				track("clears")
				if g > 0:
					add_gems(g)
				obstacles_changed.emit()
	job_done.emit(j)


## Starts building the next Megacluster stage (money paid, a builder works on it).
func start_stage(uid: int, cost: float, seconds: float) -> bool:
	if free_builders() <= 0 or job_of(uid).size() > 0 or not spend(cost):
		return false
	_start_job("stage", uid, seconds)
	save_game()
	return true


# ---------------------------------------------------------------- obstacles

static func cell_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


static func key_cell(k: String) -> Vector2i:
	var p := k.split(",")
	return Vector2i(int(p[0]), int(p[1]))


func obstacle_price() -> float:
	return Bal.obstacle_cost(cleared)


func clear_block(key: String) -> String:
	if not obstacles.has(key):
		return "?"
	if job_of_obstacle(key).size() > 0:
		return "Being cleared"
	if free_builders() <= 0:
		return "All builders are busy"
	if not can_afford(obstacle_price()):
		return "Not enough money"
	return ""


func clear_obstacle(key: String) -> bool:
	if clear_block(key) != "":
		return false
	spend(obstacle_price())
	var ob: Dictionary = obstacles[key]
	_start_job("clear", 0, float(Defs.OBSTACLES[ob["kind"]]["time"]), key)
	save_game()
	return true


## Cells an obstacle covers.
static func obstacle_cells(key: String, ob: Dictionary) -> Array[Vector2i]:
	var c := key_cell(key)
	var sz: Vector2i = Defs.OBSTACLES[ob["kind"]]["size"]
	var out: Array[Vector2i] = []
	for x in sz.x:
		for y in sz.y:
			out.append(c + Vector2i(x, y))
	return out


## New land comes with a few things to clear.
func _spawn_obstacles(chunk: Vector2i) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(chunk * 4099 + Vector2i(7, 3))
	var n := rng.randi_range(3, 6)
	var kinds := Defs.OBSTACLES.keys()
	for i in n * 3:
		if n <= 0:
			break
		var k: String = kinds[rng.randi() % kinds.size()]
		var sz: Vector2i = Defs.OBSTACLES[k]["size"]
		var c := chunk * Bal.CHUNK + Vector2i(rng.randi_range(0, Bal.CHUNK - sz.x), rng.randi_range(0, Bal.CHUNK - sz.y))
		var ok := true
		for x in range(-1, sz.x + 1):
			for y in range(-1, sz.y + 1):
				if _cell_taken(c + Vector2i(x, y)):
					ok = false
		if not ok:
			continue
		var g := 0
		var r := rng.randf()
		if r < 0.35:
			g = 1
		elif r < 0.5:
			g = rng.randi_range(2, 4)
		obstacles[cell_key(c)] = {"kind": k, "gems": g}
		n -= 1


func _cell_taken(c: Vector2i) -> bool:
	if Roads.is_street(c) or Roads.is_street(c + Vector2i(0, 1)) or Roads.is_street(c - Vector2i(0, 1)):
		return true
	for k in obstacles:
		if obstacle_cells(k, obstacles[k]).has(c):
			return true
	for b in buildings:
		var cs := Grid.cells(cell_of(b), Defs.size_of(b["kind"]), int(b["rot"]))
		if cs.has(c):
			return true
	return false


# ---------------------------------------------------------------- land

static func chunk_key(c: Vector2i) -> String:
	return "%d,%d" % [c.x, c.y]


func owns_chunk(c: Vector2i) -> bool:
	return land.has(chunk_key(c))


func owns_cell(cell: Vector2i) -> bool:
	return owns_chunk(Vector2i(floori(float(cell.x) / Bal.CHUNK), floori(float(cell.y) / Bal.CHUNK)))


func land_price() -> float:
	return Bal.land_cost(land_bought_n)


func can_buy_chunk(c: Vector2i) -> bool:
	if owns_chunk(c):
		return false
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if owns_chunk(c + d):
			return true
	return false


func buy_chunk(c: Vector2i) -> bool:
	if not can_buy_chunk(c) or not spend(land_price()):
		return false
	land[chunk_key(c)] = true
	land_bought_n += 1
	_spawn_obstacles(c)
	land_bought.emit(c)
	obstacles_changed.emit()
	save_game()
	return true


func owned_chunks() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for k in land:
		var p: PackedStringArray = k.split(",")
		out.append(Vector2i(int(p[0]), int(p[1])))
	return out

# ---------------------------------------------------------------- research + perks

func research(id: String) -> int:
	return int(research_lv.get(id, 0))


func research_cost(id: String) -> float:
	return Bal.snap_price(Bal.research_cost(id, research(id)) * Live.research_mult())


func research_maxed(id: String) -> bool:
	return research(id) >= int(Bal.RESEARCH[id]["max"])


func buy_research(id: String) -> bool:
	if research_maxed(id) or not spend(research_cost(id)):
		return false
	research_lv[id] = research(id) + 1
	researched.emit(id, research_lv[id])
	track("research")
	save_game()
	return true


func perk(id: String) -> int:
	return int(perks.get(id, 0))


func buy_perk(id: String) -> bool:
	if perk(id) >= int(Bal.PERKS[id]["max"]):
		return false
	var c := Bal.perk_cost(id, perk(id))
	if gems < c:
		return false
	gems -= c
	perks[id] = perk(id) + 1
	gems_changed.emit(gems)
	researched.emit("perk_" + id, perks[id])
	if id == "orders":
		refill_orders()
	save_game()
	return true

# ---------------------------------------------------------------- recipes, trends, orders

func discover(rid: String) -> void:
	if known_recipes.has(rid):
		return
	known_recipes[rid] = true
	discovered.emit(rid)
	save_game()


## Models the player has served at least once.
func known_list() -> Array[String]:
	var out: Array[String] = []
	for r in Defs.RECIPES:
		if known_recipes.has(r["id"]):
			out.append(r["id"])
	return out


func _new_trend() -> void:
	trend_t = Bal.TREND_PERIOD
	var ks := known_list()
	if ks.size() < 2:
		trending = ""
		return
	var pick := trending
	while pick == trending:
		pick = ks[randi() % ks.size()]
	trending = pick
	trend_changed.emit(trending)


func order_slots() -> int:
	return Bal.ORDER_SLOTS + perk("orders")


## Keeps the Enterprise Desk full of contracts for models you know how to serve.
func refill_orders() -> void:
	if count_of("desk") == 0:
		return
	var ks := known_list()
	if ks.is_empty():
		return
	while orders.size() < order_slots():
		var rid: String = ks[randi() % ks.size()]
		# lean toward your better recipes
		if ks.size() > 2 and randf() < 0.6:
			rid = ks[ks.size() - 1 - randi() % mini(3, ks.size())]
		var r := Defs.recipe(rid)
		var kind := "t"
		if count_of("batcher") > 0 and randf() < 0.4:
			kind = "b"
		if count_of("agent_studio") > 0 and randf() < 0.3:
			kind = "a"
		var n := Bal.order_count(float(r["price"]))
		if kind != "t":
			n = maxi(2, n / 6)
		var item := "%s:%s" % [kind, rid]
		var reward := roundf(Bal.item_value(item) * n * 2.5)
		var g := 1 + Defs.RECIPES.find(r) / 4 + (1 if kind != "t" else 0)
		orders.append({"item": item, "count": n, "got": 0, "reward": reward, "gems": g})
	orders_changed.emit()


## An item was delivered to the Enterprise Desk. Returns true if it was wanted.
func deliver(item: String) -> bool:
	for o in orders:
		if o["item"] == item and int(o["got"]) < int(o["count"]):
			o["got"] = int(o["got"]) + 1
			if int(o["got"]) >= int(o["count"]):
				orders.erase(o)
				add_money(float(o["reward"]))
				add_gems(int(o["gems"]))
				stats["orders"] = int(stats["orders"]) + 1
				track("orders")
				toast.emit("Contract complete! +$%s  +%d sparks" % [Fmt.num(o["reward"]), int(o["gems"])], "gem")
				refill_orders()
			orders_changed.emit()
			return true
	return false


func wanted_items() -> Array[String]:
	var out: Array[String] = []
	for o in orders:
		if int(o["got"]) < int(o["count"]):
			out.append(o["item"])
	return out

# ---------------------------------------------------------------- workers

## Staff you can house: a few on campus plus every Staff Housing.
func dorm_capacity() -> int:
	var n := Bal.BASE_STAFF
	for b in buildings:
		if b["kind"] == "dorm" and int(b["lvl"]) > 0:
			n += Bal.dorm_cap(int(b["lvl"]))
	return n


func hire_price() -> float:
	return Bal.hire_cost(hired)


func can_hire() -> bool:
	return workers.size() < dorm_capacity()


func hire() -> Dictionary:
	if not can_hire() or not spend(hire_price()):
		return {}
	var w := {"id": next_worker_id, "role": "courier", "target": 0}
	next_worker_id += 1
	hired += 1
	workers.append(w)
	track("hires")
	workers_changed.emit()
	save_game()
	return w


func assign(worker_id: int, role: String, target := 0) -> void:
	for w in workers:
		if int(w["id"]) == worker_id:
			w["role"] = role
			w["target"] = target
	workers_changed.emit()
	save_game()


func workers_with(role: String, target := -1) -> int:
	var n := 0
	for w in workers:
		if w["role"] == role and (target < 0 or int(w.get("target", 0)) == target):
			n += 1
	return n


## Turns a courier into a technician or engineer for a building. One
## courier always stays a courier so deliveries never stop.
func assign_courier(role: String, target := 0) -> bool:
	if workers_with("courier") <= 1:
		return false
	for i in range(workers.size() - 1, -1, -1):
		var w: Dictionary = workers[i]
		if w["role"] == "courier":
			assign(int(w["id"]), role, target)
			return true
	return false


## Sends one worker with this role (and target) back to courier work.
func unassign(role: String, target := -1) -> bool:
	for i in range(workers.size() - 1, -1, -1):
		var w: Dictionary = workers[i]
		if w["role"] == role and (target < 0 or int(w.get("target", 0)) == target):
			assign(int(w["id"]), "courier", 0)
			return true
	return false

# ---------------------------------------------------------------- rush

func rush_active() -> bool:
	return rush_time > 0.0


func start_rush() -> bool:
	if rush_cooldown > 0.0 or rush_time > 0.0:
		return false
	rush_time = Bal.rush_duration()
	rush_cooldown = Bal.rush_duration() + Bal.rush_cooldown()
	rush_changed.emit(true)
	track("overclock")
	return true


func speed_mult() -> float:
	return 2.0 if rush_time > 0.0 else 1.0

# ---------------------------------------------------------------- save / load

func to_dict() -> Dictionary:
	return {
		"v": VERSION, "money": money, "gems": gems, "clock": clock,
		"research": research_lv, "perks": perks, "buildings": buildings, "next_uid": next_uid, "jobs": jobs,
		"land": land.keys(), "land_n": land_bought_n, "obstacles": obstacles, "cleared": cleared, "workers": workers,
		"next_worker_id": next_worker_id, "hired": hired, "stats": stats,
		"known": known_recipes.keys(), "orders": orders, "trending": trending, "trend_t": trend_t,
		"settings": settings, "tutorial": tutorial_step,
		"time": int(Time.get_unix_time_from_system()), "income": recent_income(), "trate": token_rate(),
		"rush_cd": rush_cooldown, "won": won,
	}


func from_dict(d: Dictionary) -> void:
	reset_state()
	if int(d.get("v", 0)) != VERSION:
		return
	money = float(d.get("money", 0.0))
	gems = int(d.get("gems", 0))
	clock = float(d.get("clock", 0.0))
	research_lv = d.get("research", {})
	perks = d.get("perks", {})
	buildings = []
	for b in d.get("buildings", []):
		b["uid"] = int(b["uid"])
		b["rot"] = int(b["rot"])
		b["lvl"] = int(b["lvl"])
		buildings.append(b)
	_counts = {}
	next_uid = int(d.get("next_uid", 1))
	jobs = []
	for j in d.get("jobs", []):
		j["uid"] = int(j.get("uid", 0))
		jobs.append(j)
	land = {}
	for k in d.get("land", []):
		land[str(k)] = true
	land_bought_n = int(d.get("land_n", 0))
	obstacles = d.get("obstacles", {})
	for k in obstacles:
		obstacles[k]["gems"] = int(obstacles[k].get("gems", 0))
	cleared = int(d.get("cleared", 0))
	workers = d.get("workers", [])
	for w in workers:
		w["id"] = int(w["id"])
		w["target"] = int(w.get("target", 0))
	next_worker_id = int(d.get("next_worker_id", 1))
	hired = int(d.get("hired", 0))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		stats[k] = st[k]
	known_recipes = {}
	for k in d.get("known", ["pico"]):
		known_recipes[str(k)] = true
	orders = d.get("orders", [])
	trending = str(d.get("trending", ""))
	trend_t = float(d.get("trend_t", 60.0))
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]
	tutorial_step = int(d.get("tutorial", 0))
	won = bool(d.get("won", false))
	level = level_for(float(stats["tokens"]))
	var away := maxf(0.0, float(Time.get_unix_time_from_system() - int(d.get("time", 0))))
	rush_cooldown = maxf(0.0, float(d.get("rush_cd", 0.0)) - away)
	# time away counts for builders
	clock += away
	offline_seconds = away
	_check_jobs()
	var rate := float(d.get("income", 0.0))
	offline_reward = 0.0
	if away > 60.0 and rate > 0.0:
		offline_reward = roundf(rate * minf(away, Bal.offline_cap_hours() * 3600.0) * Bal.OFFLINE_FACTOR)
	offline_tokens = 0
	if away > 60.0:
		offline_tokens = int(float(d.get("trate", 0.0)) * minf(away, Bal.offline_cap_hours() * 3600.0) * Bal.OFFLINE_FACTOR)


func save_game() -> void:
	if no_save or not loaded:
		return
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))


func load_game() -> void:
	loaded = true
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if d is Dictionary:
		from_dict(d)


func wipe() -> void:
	reset_state()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	Live.wipe()
