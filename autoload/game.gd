extends Node
## Game state: money, gems, empire level, every placed building, owned land,
## research, perks, workers, orders. Owns saving/loading and offline
## earnings. Gameplay nodes read and change state only through here and
## listen to its signals.

signal money_changed(value: float, delta: float)
signal gems_changed(value: int)
signal xp_changed(xp: float, need: float, level: int)
signal level_up(level: int, reward: float)
signal building_added(b: Dictionary)
signal building_removed(uid: int)
signal building_moved(uid: int)
signal building_upgraded(uid: int, level: int)
signal land_bought(chunk: Vector2i)
signal researched(id: String, level: int)
signal workers_changed
signal rush_changed(active: bool)
signal orders_changed
signal trend_changed(recipe: String)
signal discovered(recipe: String)
signal toast(text: String, icon: String)

const SAVE_PATH := "user://cookie_empire_v3.json"
const VERSION := 3

var money := 0.0
var gems := 0
var level := 1
var xp := 0.0
var research_lv := {}         # id -> level
var perks := {}               # id -> level
var buildings: Array = []     # [{uid, kind, cell: [x, y], rot, lvl, ing?, stage?, data}]
var next_uid := 1
var land := {}                # "x,y" -> true for owned chunks
var land_bought_n := 0
var workers: Array = []       # [{id, role, target}] target = building uid (farmers/chefs)
var next_worker_id := 1
var hired := 0
var stats := {"cookies": 0, "earned": 0.0, "batches": 0, "play_time": 0.0, "orders": 0, "customers": 0, "royal": 0}
var known_recipes := {}       # recipe id -> true once baked
var orders: Array = []        # [{recipe, kind, count, got, reward, gems}]
var trending := ""
var trend_t := 0.0
var settings := {"music": true, "sfx": true, "haptics": true}
var tutorial_step := 0
var player_state := {}
var income_rate := 0.0
var rush_time := 0.0
var rush_cooldown := 0.0
var offline_reward := 0.0
var won := false

var _save_timer := 0.0
var _income_window: Array = []
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
	gems = 0
	level = 1
	xp = 0.0
	research_lv = {}
	perks = {}
	buildings = []
	next_uid = 1
	land = {}
	land_bought_n = 0
	workers = []
	next_worker_id = 1
	hired = 0
	stats = {"cookies": 0, "earned": 0.0, "batches": 0, "play_time": 0.0, "orders": 0, "customers": 0, "royal": 0}
	known_recipes = {}
	orders = []
	trending = ""
	trend_t = 60.0
	tutorial_step = 0
	player_state = {}
	rush_time = 0.0
	rush_cooldown = 0.0
	won = false
	_counts = {}
	_starting_empire()


## A new empire: four chunks of land, a wheat field, a short line (Mixer,
## two tubes, Oven) and a delivery van.
func _starting_empire() -> void:
	for x in [-1, 0]:
		for y in [-1, 0]:
			land["%d,%d" % [x, y]] = true
	_add("farm_wheat", Vector2i(-6, -6), 0)
	_add("mixer", Vector2i(-2, -5), 0)
	_add("tube", Vector2i(-1, -5), 0)
	_add("tube", Vector2i(0, -5), 0)
	_add("oven", Vector2i(1, -5), 0)
	_add("dock", Vector2i(4, -6), 0)
	known_recipes["shortbread"] = true


func _process(dt: float) -> void:
	_clock += dt
	stats["play_time"] = float(stats["play_time"]) + dt
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
		add_xp(amount)
	money_changed.emit(money, amount)


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


## Money per second over the last two minutes (offline earnings + HUD).
func recent_income() -> float:
	while _income_window.size() > 0 and _clock - float(_income_window[0][0]) > 120.0:
		_income_window.pop_front()
	var s := 0.0
	for e in _income_window:
		s += float(e[1])
	return s / clampf(_clock, 30.0, 120.0)


## Sells items through a channel. Returns the money made.
func sell(items: Array, mult := 1.0, gift_mult := 1.0) -> float:
	var total := 0.0
	var n := 0
	for t in items:
		var v := Bal.item_value(t) * mult
		if Defs.cat(t) == "gift":
			v *= gift_mult
		total += v
		match Defs.cat(t):
			"cookie": n += 1
			"box": n += Bal.BOX_SIZE
			"gift": n += Bal.BOX_SIZE
		if Defs.recipe_of(t) == "royal":
			stats["royal"] = int(stats["royal"]) + 1
	stats["cookies"] = int(stats["cookies"]) + n
	total = roundf(total)
	add_money(total)
	return total


# ---------------------------------------------------------------- level / xp

func add_xp(amount: float) -> void:
	xp += amount
	while level < Bal.MAX_LEVEL and xp >= Bal.xp_needed(level):
		xp -= Bal.xp_needed(level)
		level += 1
		var reward := Bal.level_reward(level)
		money += reward
		money_changed.emit(money, reward)
		level_up.emit(level, reward)
	xp_changed.emit(xp, Bal.xp_needed(level), level)


func unlocked(kind: String) -> bool:
	return level >= int(Defs.BUILDINGS[kind]["lvl"])


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


func price_of(kind: String) -> float:
	# tubes and decor are priced flat; everything else gets dearer the more you own
	return Bal.build_cost(kind, count_of(kind))


func building(uid: int) -> Dictionary:
	for b in buildings:
		if int(b["uid"]) == uid:
			return b
	return {}


static func cell_of(b: Dictionary) -> Vector2i:
	return Vector2i(int(b["cell"][0]), int(b["cell"][1]))


## Places a new building (money must already be checked by the caller).
func place(kind: String, cell: Vector2i, rot: int, extra := {}, pay := true) -> Dictionary:
	if pay and not spend(price_of(kind)):
		return {}
	var b := _add(kind, cell, rot, extra)
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
	buildings.erase(b)
	_counts.erase(b["kind"])
	var back := 0.0
	if refund:
		back = roundf(Bal.build_cost(b["kind"], count_of(b["kind"])) * 0.5)
		add_money(back, false)
	for w in workers:
		if int(w.get("target", 0)) == uid:
			w["target"] = 0
			w["role"] = ""
	building_removed.emit(uid)
	workers_changed.emit()
	save_game()
	return back


func upgrade(uid: int) -> bool:
	var b := building(uid)
	if b.is_empty():
		return false
	var l := int(b["lvl"])
	if l >= Bal.max_level(b["kind"]):
		return false
	if not spend(Bal.upgrade_cost(b["kind"], l)):
		return false
	b["lvl"] = l + 1
	building_upgraded.emit(uid, l + 1)
	save_game()
	return true


## Whether the empire can currently make an ingredient.
func can_make(ing: String) -> bool:
	if ing == "wheat":
		return true
	var p := Defs.producer_of(ing)
	return p != "" and count_of(p) > 0


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
	land_bought.emit(c)
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
	return Bal.research_cost(id, research(id))


func research_maxed(id: String) -> bool:
	return research(id) >= int(Bal.RESEARCH[id]["max"])


func buy_research(id: String) -> bool:
	if research_maxed(id) or not spend(research_cost(id)):
		return false
	research_lv[id] = research(id) + 1
	researched.emit(id, research_lv[id])
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


## Recipes the player has baked at least once.
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


## Keeps the order board full of orders for cookies you know how to bake.
func refill_orders() -> void:
	if count_of("board") == 0:
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
		var kind := "c"
		if count_of("packer") > 0 and randf() < 0.4:
			kind = "b"
		if count_of("wrapper") > 0 and randf() < 0.3:
			kind = "g"
		var n := Bal.order_count(float(r["price"]))
		if kind != "c":
			n = maxi(2, n / 6)
		var item := "%s:%s" % [kind, rid]
		var reward := roundf(Bal.item_value(item) * n * 2.5)
		var g := 1 + Defs.RECIPES.find(r) / 4 + (1 if kind != "c" else 0)
		orders.append({"item": item, "count": n, "got": 0, "reward": reward, "gems": g})
	orders_changed.emit()


## An item was delivered to the order board. Returns true if it was wanted.
func deliver(item: String) -> bool:
	for o in orders:
		if o["item"] == item and int(o["got"]) < int(o["count"]):
			o["got"] = int(o["got"]) + 1
			if int(o["got"]) >= int(o["count"]):
				orders.erase(o)
				add_money(float(o["reward"]))
				add_gems(int(o["gems"]))
				stats["orders"] = int(stats["orders"]) + 1
				toast.emit("Order complete! +$%s  +%d gems" % [Fmt.num(o["reward"]), int(o["gems"])], "gem")
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

func cabin_capacity() -> int:
	var n := 0
	for b in buildings:
		if b["kind"] == "cabin":
			n += Bal.cabin_cap(int(b["lvl"]))
	return n


func hire_price() -> float:
	return Bal.hire_cost(hired)


func can_hire() -> bool:
	return workers.size() < cabin_capacity()


func hire() -> Dictionary:
	if not can_hire() or not spend(hire_price()):
		return {}
	var w := {"id": next_worker_id, "role": "", "target": 0}
	next_worker_id += 1
	hired += 1
	workers.append(w)
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


func idle_workers() -> int:
	return workers_with("")


## Assigns an idle worker; returns false if nobody is free.
func assign_idle(role: String, target := 0) -> bool:
	for w in workers:
		if w["role"] == "":
			assign(int(w["id"]), role, target)
			return true
	return false


## Sends one worker with this role (and target) back to the cabin.
func unassign(role: String, target := -1) -> bool:
	for i in range(workers.size() - 1, -1, -1):
		var w: Dictionary = workers[i]
		if w["role"] == role and (target < 0 or int(w.get("target", 0)) == target):
			assign(int(w["id"]), "", 0)
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
	return true


func speed_mult() -> float:
	return 2.0 if rush_time > 0.0 else 1.0

# ---------------------------------------------------------------- save / load

func to_dict() -> Dictionary:
	return {
		"v": VERSION, "money": money, "gems": gems, "level": level, "xp": xp,
		"research": research_lv, "perks": perks, "buildings": buildings, "next_uid": next_uid,
		"land": land.keys(), "land_n": land_bought_n, "workers": workers,
		"next_worker_id": next_worker_id, "hired": hired, "stats": stats,
		"known": known_recipes.keys(), "orders": orders, "trending": trending, "trend_t": trend_t,
		"settings": settings, "tutorial": tutorial_step, "player": player_state,
		"time": int(Time.get_unix_time_from_system()), "income": recent_income(),
		"rush_cd": rush_cooldown, "won": won,
	}


func from_dict(d: Dictionary) -> void:
	reset_state()
	if int(d.get("v", 0)) != VERSION:
		return
	money = float(d.get("money", 0.0))
	gems = int(d.get("gems", 0))
	level = int(d.get("level", 1))
	xp = float(d.get("xp", 0.0))
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
	land = {}
	for k in d.get("land", []):
		land[str(k)] = true
	land_bought_n = int(d.get("land_n", 0))
	workers = d.get("workers", [])
	for w in workers:
		w["id"] = int(w["id"])
		w["target"] = int(w.get("target", 0))
	next_worker_id = int(d.get("next_worker_id", 1))
	hired = int(d.get("hired", workers.size()))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		stats[k] = st[k]
	known_recipes = {}
	for k in d.get("known", ["shortbread"]):
		known_recipes[str(k)] = true
	orders = d.get("orders", [])
	trending = str(d.get("trending", ""))
	trend_t = float(d.get("trend_t", 60.0))
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]
	tutorial_step = int(d.get("tutorial", 0))
	player_state = d.get("player", {})
	won = bool(d.get("won", false))
	rush_cooldown = maxf(0.0, float(d.get("rush_cd", 0.0)) - float(Time.get_unix_time_from_system() - int(d.get("time", 0))))
	var away := float(Time.get_unix_time_from_system() - int(d.get("time", 0)))
	var rate := float(d.get("income", 0.0))
	offline_reward = 0.0
	if away > 60.0 and rate > 0.0 and workers.size() > 0:
		offline_reward = roundf(rate * minf(away, Bal.offline_cap_hours() * 3600.0) * Bal.OFFLINE_FACTOR)


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
