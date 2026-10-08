extends Node
## Game state: money, empire level, upgrade levels, buildings, workers.
## Owns saving/loading and offline earnings. Gameplay nodes read and change
## state only through here and listen to its signals.

signal money_changed(value: int, delta: int)
signal xp_changed(xp: int, need: int, level: int)
signal level_up(level: int, reward: int)
signal upgraded(id: String, level: int)
signal built(id: String)
signal workers_changed
signal rush_changed(active: bool)
signal toast(text: String, icon: String)

const SAVE_PATH := "user://cookie_save.json"
const VERSION := 1

var money := Bal.START_MONEY
var level := 1
var xp := 0
var upgrades := {}            # id -> level (farms start at 1, others 0)
var buildings := {}           # id -> true once built
var pad_paid := {}            # build pad id -> money paid so far
var workers: Array = []       # [{id, role, target}] role "" = idle at the cabin
var next_worker_id := 1
var hired := 0
var stats := {"cookies": 0, "earned": 0, "batches": 0, "play_time": 0.0}
var world_state := {}         # holder contents etc. (written by World)
var settings := {"music": true, "sfx": true, "haptics": true}
var tutorial_step := 0
var last_save_time := 0
var income_rate := 0.0        # $/s, smoothed while automation runs
var rush_time := 0.0          # >0 while Cookie Rush is active
var rush_cooldown := 0.0
var offline_reward := 0       # set on load; UI shows it

var _save_timer := 0.0
var _income_window: Array = []    # [time, amount]
var _clock := 0.0
var loaded := false
## When true (tests), nothing is written to disk.
var no_save := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_state()
	if not "--fresh" in OS.get_cmdline_user_args():
		load_game()


func reset_state() -> void:
	money = Bal.START_MONEY
	level = 1
	xp = 0
	upgrades = {}
	for id in Bal.all_upgrade_ids():
		upgrades[id] = 1 if id.begins_with("farm_") else 0
	buildings = {}
	pad_paid = {}
	workers = []
	next_worker_id = 1
	hired = 0
	stats = {"cookies": 0, "earned": 0, "batches": 0, "play_time": 0.0}
	world_state = {}
	tutorial_step = 0
	rush_time = 0.0
	rush_cooldown = 0.0


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
	_save_timer += dt
	if _save_timer > 8.0:
		_save_timer = 0.0
		save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		save_game()


# ---------------------------------------------------------------- money

func add_money(amount: int, earned := true) -> void:
	if amount == 0:
		return
	money += amount
	if earned and amount > 0:
		stats["earned"] = int(stats["earned"]) + amount
		_income_window.append([_clock, amount])
	money_changed.emit(money, amount)


func can_afford(amount: int) -> bool:
	return money >= amount


func spend(amount: int) -> bool:
	if money < amount:
		return false
	money -= amount
	money_changed.emit(money, -amount)
	return true


## Money per second over the last two minutes (for offline earnings + HUD).
func recent_income() -> float:
	while _income_window.size() > 0 and _clock - float(_income_window[0][0]) > 120.0:
		_income_window.pop_front()
	var s := 0.0
	for e in _income_window:
		s += float(e[1])
	return s / clampf(_clock, 30.0, 120.0)


# ---------------------------------------------------------------- level / xp

func add_xp(amount: int) -> void:
	xp += amount
	while level < Bal.MAX_LEVEL and xp >= Bal.xp_needed(level):
		xp -= Bal.xp_needed(level)
		level += 1
		var reward := Bal.level_reward(level)
		add_money(reward, false)
		level_up.emit(level, reward)
	xp_changed.emit(xp, Bal.xp_needed(level), level)


## A truck sold cookies.
func sell_cookies(count: int) -> int:
	var price := Bal.cookie_price(lvl("recipe"))
	var total := count * price
	stats["cookies"] = int(stats["cookies"]) + count
	add_money(total)
	add_xp(count)
	return total


# ---------------------------------------------------------------- upgrades

func lvl(id: String) -> int:
	return int(upgrades.get(id, 0))


func upgrade_cost(id: String) -> int:
	return Bal.cost(id, lvl(id) if not id.begins_with("farm_") else lvl(id) - 1)


func upgrade_maxed(id: String) -> bool:
	return lvl(id) >= int(Bal.upgrade_def(id)["max"])


func upgrade_available(id: String) -> bool:
	var d := Bal.upgrade_def(id)
	return not d.has("needs") or has_building(d["needs"])


func buy_upgrade(id: String) -> bool:
	if upgrade_maxed(id) or not upgrade_available(id):
		return false
	if not spend(upgrade_cost(id)):
		return false
	upgrades[id] = lvl(id) + 1
	upgraded.emit(id, upgrades[id])
	save_game()
	return true


# ---------------------------------------------------------------- buildings

func has_building(id: String) -> bool:
	return buildings.has(id)


func build(id: String) -> void:
	if buildings.has(id):
		return
	buildings[id] = true
	pad_paid.erase(id)
	built.emit(id)
	save_game()


# ---------------------------------------------------------------- workers

func cabin_capacity() -> int:
	return Bal.cabin_cap(lvl("cabin")) if has_building("cabin") else 0


func hire_price() -> int:
	return Bal.hire_cost(hired)


func can_hire() -> bool:
	return has_building("cabin") and workers.size() < cabin_capacity()


func hire() -> Dictionary:
	if not can_hire() or not spend(hire_price()):
		return {}
	var w := {"id": next_worker_id, "role": "", "target": ""}
	next_worker_id += 1
	hired += 1
	workers.append(w)
	workers_changed.emit()
	save_game()
	return w


func role_unlocked(role: String) -> bool:
	return has_building(Defs.ROLES[role]["needs"])


func assign(worker_id: int, role: String, target := "") -> void:
	for w in workers:
		if int(w["id"]) == worker_id:
			w["role"] = role
			w["target"] = target
	workers_changed.emit()
	save_game()


func workers_with(role: String, target := "*") -> int:
	var n := 0
	for w in workers:
		if w["role"] == role and (target == "*" or w["target"] == target):
			n += 1
	return n


func idle_workers() -> int:
	return workers_with("")


# ---------------------------------------------------------------- rush

func rush_active() -> bool:
	return rush_time > 0.0


func start_rush() -> bool:
	if rush_cooldown > 0.0 or rush_time > 0.0:
		return false
	rush_time = Bal.RUSH_DURATION
	rush_cooldown = Bal.RUSH_DURATION + Bal.RUSH_COOLDOWN
	rush_changed.emit(true)
	return true


## Global speed multiplier for production and workers.
func speed_mult() -> float:
	return 2.0 if rush_time > 0.0 else 1.0


# ---------------------------------------------------------------- save / load

func to_dict() -> Dictionary:
	return {
		"v": VERSION, "money": money, "level": level, "xp": xp, "upgrades": upgrades,
		"buildings": buildings, "pad_paid": pad_paid, "workers": workers,
		"next_worker_id": next_worker_id, "hired": hired, "stats": stats,
		"world": world_state, "settings": settings, "tutorial": tutorial_step,
		"time": int(Time.get_unix_time_from_system()), "income": recent_income(),
		"rush_cd": rush_cooldown,
	}


func from_dict(d: Dictionary) -> void:
	reset_state()
	money = int(d.get("money", 0))
	level = int(d.get("level", 1))
	xp = int(d.get("xp", 0))
	for k in d.get("upgrades", {}):
		if upgrades.has(k):
			upgrades[k] = int(d["upgrades"][k])
	buildings = d.get("buildings", {})
	pad_paid = d.get("pad_paid", {})
	workers = d.get("workers", [])
	for w in workers:
		w["id"] = int(w["id"])
	next_worker_id = int(d.get("next_worker_id", 1))
	hired = int(d.get("hired", workers.size()))
	var st: Dictionary = d.get("stats", {})
	for k in st:
		stats[k] = st[k]
	world_state = d.get("world", {})
	var s: Dictionary = d.get("settings", {})
	for k in s:
		settings[k] = s[k]
	tutorial_step = int(d.get("tutorial", 0))
	rush_cooldown = maxf(0.0, float(d.get("rush_cd", 0.0)) - float(Time.get_unix_time_from_system() - int(d.get("time", 0))))
	# offline earnings from the automation that was running when we left
	var away := float(Time.get_unix_time_from_system() - int(d.get("time", 0)))
	var rate := float(d.get("income", 0.0))
	offline_reward = 0
	if away > 60.0 and rate > 0.0 and workers.size() > 0:
		offline_reward = int(rate * minf(away, Bal.OFFLINE_CAP_HOURS * 3600.0) * Bal.OFFLINE_FACTOR)


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
	var txt := FileAccess.get_file_as_string(SAVE_PATH)
	var d = JSON.parse_string(txt)
	if d is Dictionary:
		from_dict(d)


func wipe() -> void:
	reset_state()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
