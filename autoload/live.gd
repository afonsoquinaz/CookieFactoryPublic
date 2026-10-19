extends Node
## The daily and weekly layer around the empire, the things that bring you
## back (Duolingo, Pokémon GO and Clash Royale style):
##   - a daily goal (serve some tokens) and a streak, with freezes and repair
##   - three daily quests (one reroll a day); finishing all three gives a
##     crate and a Breakthrough stamp; seven stamps open a Breakthrough
##   - a 7-day login calendar
##   - supply crates in four slots that unlock one at a time
##   - boosters: Time Warps, Overclock Charges, Streak Freezes
##   - tiered badges and model mastery stars (served tokens per model)
##   - the Benchmark League: a weekly race against 29 rival AI labs, top 7
##     move up, bottom 5 move down, ten leagues from Bronze to Diamond
##   - the Lab Pass: a monthly season of 30 tiers, free and premium tracks
##   - events on the calendar (Spotlight Hour, Hackathon Weekend, Community
##     Day, Launch Week, Final Push) that every player shares
##   - an inbox (league results, crates kept for you, gifts) and comeback
##     gifts after a few days away
##   - the lab's profile (name, logo colour, friend code)
## The game is offline, so rival labs are simulated, deterministic per week;
## events run on the local calendar. Saved in its own file next to the game.
## Data and rules live in LiveDefs; Notifier turns the state into reminders.

signal changed                              # anything here changed (UI refresh)
signal goal_done(streak: int)               # today's goal reached
signal milestone(days: int, reward: Dictionary)
signal reward(title: String, sub: String, items: Array)   # show a reward card
signal league_result(result: Dictionary)
signal event_started(id: String)

const SAVE_PATH := "user://token_empire_live_v1.json"
const VERSION := 1

var debug_offset := 0                       # seconds added to the clock (tests, --days)
var events_on := true                       # off in tests and the pacing bot
var loaded := false

var profile := {}
var day := -1                               # the local day the state is for
var goal := 0
var goal_got := 0
var goal_is_done := false
var streak := 0
var streak_best := 0
var last_goal_day := -100000
var freezes := 0
var lost_streak := 0
var lost_day := -100000
var goal_days: Array = []                   # local days the goal was reached (last 60)
var freeze_days: Array = []                 # local days a freeze kept the streak
var quests: Array = []                      # [{id, n, base, claimed}]
var rerolled := false
var stamps := 0
var login_idx := 0
var login_claimed := false
var crates: Array = []                      # [{kind, seed, state: locked|unlocking|ready, end}]
var boosters := {"warp15": 0, "warp60": 0, "overclock": 0}
var counters := {}                          # lifetime counts by metric
var day_counts := {}                        # today's counts by metric
var badges := {}                            # id -> tiers claimed
var mastery := {}                           # model -> tokens served
var mastery_claimed := {}                   # model -> stars claimed
var unlocked := {}                          # exclusive decor kind -> true
var league := {}
var league_history: Array = []
var season := {}
var inbox: Array = []
var next_msg := 1
var events_seen := {}                       # "id:start" -> true
var event_quests := {"start": -1, "list": [], "done": false}
var notify := {"on": true, "quiet": true, "cats": {}}
var last_seen := 0
var income_hint := 1.0                      # money/s, remembered for rewards
var ref_income := 1.0                       # today's reward scale (money/s)
var _bp_acc := 0.0
var _tick := 0.0
var _save_t := 0.0
var _active_events: Array = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	reset_state()
	var args := OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--days="):
			debug_offset = int(float(a.trim_prefix("--days=")) * 86400.0)
	if not "--fresh" in args:
		load_live()
	loaded = true
	Game.tracked.connect(track)
	Game.level_up.connect(func(_l, _g): add_bp(25))
	Game.building_upgraded.connect(func(_u, _l): add_bp(3))
	Game.land_bought.connect(func(_c): changed.emit())
	tick(true)


func reset_state() -> void:
	profile = {"name": "Garage Lab", "logo": 0, "id": _new_id(), "joined": now(), "referral": ""}
	day = -1
	goal = 0
	goal_got = 0
	goal_is_done = false
	streak = 0
	streak_best = 0
	last_goal_day = -100000
	freezes = 0
	lost_streak = 0
	lost_day = -100000
	goal_days = []
	freeze_days = []
	quests = []
	rerolled = false
	stamps = 0
	login_idx = 0
	login_claimed = false
	crates = []
	boosters = {"warp15": 0, "warp60": 0, "overclock": 0}
	counters = {}
	day_counts = {}
	badges = {}
	mastery = {}
	mastery_claimed = {}
	unlocked = {}
	league = {"tier": 0, "week": -1, "points": 0, "joined": false, "best": 0}
	league_history = []
	season = {"id": -1, "sp": 0, "premium": false, "free": [], "prem": []}
	inbox = []
	next_msg = 1
	events_seen = {}
	event_quests = {"start": -1, "list": [], "done": false}
	notify = {"on": true, "quiet": true, "cats": {}}
	for c in LiveDefs.COPY:
		notify["cats"][c] = true
	last_seen = 0
	income_hint = 1.0
	ref_income = 1.0
	_bp_acc = 0.0
	_active_events = []


static func _new_id() -> String:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	return "%08x" % (rng.randi() & 0x7fffffff)


# ---------------------------------------------------------------- time

func now() -> int:
	return int(Time.get_unix_time_from_system()) + debug_offset


## Local time as a unix-like stamp (seconds since 1970 on the player's clock).
func local(t := -1) -> int:
	if t < 0:
		t = now()
	return t + int(Time.get_time_zone_from_system().get("bias", 0)) * 60


func today() -> int:
	return int(floor(local() / 86400.0))


## Monday-based week index of a local day (1970-01-01 was a Thursday).
static func week_of(d: int) -> int:
	return int(floor((d + 3) / 7.0))


static func week_start(w: int) -> int:
	return w * 7 - 3


static func season_of(d: int) -> int:
	var dt := Time.get_datetime_dict_from_unix_time(d * 86400)
	return int(dt["year"]) * 12 + int(dt["month"]) - 1


## Seconds until local midnight.
func to_midnight() -> int:
	return (today() + 1) * 86400 - local()


# ---------------------------------------------------------------- the loop

func _process(dt: float) -> void:
	_tick += dt
	if _tick >= 1.0:
		_tick = 0.0
		tick()
	_save_t += dt
	if _save_t >= 10.0:
		_save_t = 0.0
		var inc := Game.recent_income()
		if inc > income_hint * 0.25 or income_hint <= 1.0:
			income_hint = maxf(income_hint * 0.5, inc) if inc > 0.0 else income_hint
		last_seen = now()
		save_live()


## Day, week and season changes, crates that finished, events starting.
func tick(_first := false) -> void:
	var d := today()
	if d != day:
		_new_day(d)
	var w := week_of(d)
	if int(league["week"]) != w:
		_new_week(w)
	var s := season_of(d)
	if int(season["id"]) != s:
		_new_season(s)
	var t := now()
	for c in crates:
		if c["state"] == "unlocking" and t >= int(c["end"]):
			c["state"] = "ready"
			changed.emit()
	var act := active_events()
	for id in act:
		if not _active_events.has(id):
			_event_begins(id)
	_active_events = act


func _new_day(d: int) -> void:
	var first := day < 0
	if not first:
		# a missed day eats a freeze, or the streak
		if streak > 0 and last_goal_day < d - 1:
			var missed := d - 1 - last_goal_day
			for i in missed:
				if freezes > 0:
					freezes -= 1
					freeze_days.append(last_goal_day + 1 + i)
				else:
					lost_streak = streak
					lost_day = d
					streak = 0
					break
			if streak > 0:
				# frozen days count as kept: the chain carries on from yesterday
				last_goal_day = d - 1
		var away := d - int(floor(local(last_seen) / 86400.0)) if last_seen > 0 else 0
		var cb := LiveDefs.comeback(away)
		if not cb.is_empty():
			add_msg("Welcome back!", "You were away %d days. Your lab kept warm; here's something to get going again." % away, "gift", cb)
	day = d
	ref_income = maxf(1.0, income_hint)
	goal = LiveDefs.daily_goal(Game.token_rate(), Game.level)
	goal_got = 0
	goal_is_done = false
	day_counts = {}
	rerolled = false
	login_claimed = false
	quests = _roll_quests(d)
	while goal_days.size() > 60:
		goal_days.pop_front()
	while freeze_days.size() > 60:
		freeze_days.pop_front()
	changed.emit()


# ---------------------------------------------------------------- tracking

## Counts something that happened (Game.tracked): quests, the daily goal,
## badges, mastery, league points.
func track(metric: String, n: float, arg := "") -> void:
	if day < 0:
		tick()
	day_counts[metric] = float(day_counts.get(metric, 0.0)) + n
	counters[metric] = float(counters.get(metric, 0.0)) + n
	match metric:
		"tokens":
			_tokens(int(n))
		"served":
			mastery[arg] = int(mastery.get(arg, 0)) + int(n)
		"upgrades", "orders", "builds":
			add_bp(2 if metric == "upgrades" else 5)
	changed.emit()


func _tokens(n: int) -> void:
	goal_got += n
	if not goal_is_done and goal_got >= goal:
		_reach_goal()
	# benchmark points: about 20 for a day's goal worth of tokens
	_bp_acc += float(n) / maxf(1.0, goal / 20.0)
	if _bp_acc >= 1.0:
		var p := int(_bp_acc)
		_bp_acc -= p
		add_bp(p)


func _reach_goal() -> void:
	goal_is_done = true
	var d := today()
	if last_goal_day != d:
		streak = (streak if last_goal_day >= d - 1 else 0) + 1
		last_goal_day = d
		goal_days.append(d)
		streak_best = maxi(streak_best, streak)
		lost_streak = 0
	add_bp(20)
	add_sp(30)
	goal_done.emit(streak)
	if LiveDefs.STREAK_MILESTONES.has(streak):
		var r: Dictionary = LiveDefs.STREAK_MILESTONES[streak]
		var items := grant(r)
		milestone.emit(streak, r)
		reward.emit("%d-day streak!" % streak, "You've hit your goal %d days in a row." % streak, items)
	save_live()


## Today's progress on a metric since `base`.
func got(metric: String, base := 0.0) -> float:
	return float(day_counts.get(metric, 0.0)) - base


# ---------------------------------------------------------------- streak

func repair_price() -> int:
	return LiveDefs.repair_price(lost_streak)


## A lost streak can be repaired on the day it was lost and the next.
func can_repair() -> bool:
	return lost_streak > 0 and today() - lost_day <= 1 and streak <= 1


func repair_streak() -> bool:
	if not can_repair() or Game.gems < repair_price():
		return false
	Game.add_gems(-repair_price())
	streak = lost_streak + (1 if goal_is_done else 0)
	streak_best = maxi(streak_best, streak)
	if not goal_is_done:
		last_goal_day = today() - 1
	lost_streak = 0
	changed.emit()
	save_live()
	return true


func buy_freeze() -> bool:
	if freezes >= LiveDefs.MAX_FREEZES or Game.gems < LiveDefs.FREEZE_PRICE:
		return false
	Game.add_gems(-LiveDefs.FREEZE_PRICE)
	freezes += 1
	changed.emit()
	save_live()
	return true


## The streak flame for a calendar day: "goal", "freeze" or "".
func day_mark(d: int) -> String:
	if goal_days.has(d):
		return "goal"
	if freeze_days.has(d):
		return "freeze"
	return ""


# ---------------------------------------------------------------- quests

## Three quests for day d: an easy one, a medium one, a hard one, chosen
## from those that make sense for this empire right now.
func _roll_quests(d: int, avoid: Array = []) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([d, profile.get("id", ""), avoid.size()])
	var out := []
	for tier in 3:
		var pool := []
		for id in LiveDefs.QUESTS:
			if int(LiveDefs.QUESTS[id]["tier"]) == tier and quest_ok(id) and not avoid.has(id):
				pool.append(id)
		if pool.is_empty():
			pool = [["serve", "upgrade2", "serve_big"][tier]]
		var id: String = pool[rng.randi() % pool.size()]
		out.append(_quest(id))
	return out


func _quest(id: String) -> Dictionary:
	var m: String = LiveDefs.QUESTS[id]["metric"]
	return {"id": id, "n": LiveDefs.quest_amount(id, goal, ref_income), "base": float(day_counts.get(m, 0.0)), "claimed": false}


## Whether a quest makes sense for the empire as it is.
func quest_ok(id: String) -> bool:
	match id:
		"batches": return Game.count_ready("server") > 0
		"cafe": return Game.count_ready("cafe") > 0
		"contracts": return Game.count_ready("desk") > 0
		"trend": return Game.trending != "" and Game.known_recipes.has(Game.trending)
		"clear": return _owned_obstacle()
		"van": return Game.count_ready("van") > 0
		"research": return Game.level >= 2
		"hire": return Game.can_hire()
		"overclock": return Game.level >= 3
		"agents": return Game.count_ready("agent_studio") > 0
		"upgrade5": return Game.buildings.size() >= 6
	return true


func _owned_obstacle() -> bool:
	for k in Game.obstacles:
		var p: PackedStringArray = str(k).split(",")
		if p.size() == 2 and Game.owns_cell(Vector2i(int(p[0]), int(p[1]))):
			return true
	return false


func quest_text(q: Dictionary) -> String:
	return LiveDefs.QUESTS[q["id"]]["text"] % Fmt.num(int(q["n"]))


func quest_progress(q: Dictionary) -> int:
	return mini(int(q["n"]), int(got(LiveDefs.QUESTS[q["id"]]["metric"], float(q["base"]))))


func quest_ready(q: Dictionary) -> bool:
	return not q["claimed"] and quest_progress(q) >= int(q["n"])


func quest_reward(q: Dictionary) -> Dictionary:
	var r: Dictionary = LiveDefs.QUEST_REWARDS[int(LiveDefs.QUESTS[q["id"]]["tier"])]
	return {"money": LiveDefs.snap(ref_income * float(r["money_s"])), "gems": int(r["gems"]), "sp": int(r["sp"]), "bp": int(r["bp"])}


func claim_quest(i: int) -> Array:
	if i < 0 or i >= quests.size() or not quest_ready(quests[i]):
		return []
	var q: Dictionary = quests[i]
	q["claimed"] = true
	var items := grant(quest_reward(q))
	counters["quests"] = float(counters.get("quests", 0.0)) + 1.0
	if quests_all_done():
		stamps = mini(7, stamps + 1)
		items += grant({"crate": "supply"})
		reward.emit("All quests done!", "A Supply Crate and a Breakthrough stamp (%d/7)." % stamps, items)
	changed.emit()
	save_live()
	return items


func quests_all_done() -> bool:
	for q in quests:
		if not q["claimed"]:
			return false
	return not quests.is_empty()


## Swaps one quest for another of the same difficulty (once a day).
func reroll(i: int) -> bool:
	if rerolled or i < 0 or i >= quests.size() or quests[i]["claimed"]:
		return false
	var tier := int(LiveDefs.QUESTS[quests[i]["id"]]["tier"])
	var pool := []
	for id in LiveDefs.QUESTS:
		if int(LiveDefs.QUESTS[id]["tier"]) == tier and quest_ok(id):
			var used := false
			for q in quests:
				if q["id"] == id:
					used = true
			if not used:
				pool.append(id)
	if pool.is_empty():
		return false
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([day, i, "reroll", profile.get("id", "")])
	quests[i] = _quest(pool[rng.randi() % pool.size()])
	rerolled = true
	changed.emit()
	return true


func breakthrough_ready() -> bool:
	return stamps >= 7


func claim_breakthrough() -> Array:
	if not breakthrough_ready():
		return []
	stamps = 0
	var r := {"crate": "gpu", "gems": 10}
	if not unlocked.has("quantum_core"):
		r["decor"] = "quantum_core"
	var items := grant(r)
	counters["breakthroughs"] = float(counters.get("breakthroughs", 0.0)) + 1.0
	reward.emit("Breakthrough!", "Seven days of quests. Your researchers cracked something big.", items)
	changed.emit()
	save_live()
	return items


# ---------------------------------------------------------------- login calendar

func login_reward() -> Dictionary:
	return LiveDefs.LOGIN[login_idx % LiveDefs.LOGIN.size()]


func claim_login() -> Array:
	if login_claimed:
		return []
	login_claimed = true
	var r := login_reward()
	login_idx += 1
	var items := grant(r)
	add_sp(10)
	changed.emit()
	save_live()
	return items


# ---------------------------------------------------------------- rewards

## Gives a reward: {money, money_s (seconds of income), gems, warp15,
## warp60, overclock, freeze, crate, decor, sp, bp}. Returns what was given
## as [[icon, text], ...] for the reward card.
func grant(r: Dictionary) -> Array:
	var items := []
	var money := float(r.get("money", 0.0))
	if r.has("money_s"):
		money += LiveDefs.snap(ref_income * float(r["money_s"]))
	if money > 0.0:
		Game.add_money(money, false)
		items.append(["coin", "$" + Fmt.num(money)])
	if int(r.get("gems", 0)) > 0:
		Game.add_gems(int(r["gems"]))
		items.append(["gem", "%d sparks" % int(r["gems"])])
	for b in ["warp15", "warp60", "overclock"]:
		if int(r.get(b, 0)) > 0:
			boosters[b] = int(boosters.get(b, 0)) + int(r[b])
			items.append([LiveDefs.BOOSTERS[b]["icon"], "%s x%d" % [LiveDefs.BOOSTERS[b]["name"], int(r[b])]])
	if int(r.get("freeze", 0)) > 0:
		var f := mini(int(r["freeze"]), LiveDefs.MAX_FREEZES - freezes)
		freezes += f
		if f < int(r["freeze"]):
			Game.add_gems((int(r["freeze"]) - f) * 5)
		items.append(["freeze", "Streak Freeze"])
	if r.has("crate"):
		add_crate(str(r["crate"]))
		items.append(["crate_" + str(r["crate"]), LiveDefs.CRATES[r["crate"]]["name"]])
	if r.has("decor"):
		unlock(str(r["decor"]))
		items.append([Defs.BUILDINGS[r["decor"]]["icon"], "Unlocked: " + Defs.BUILDINGS[r["decor"]]["name"]])
	if int(r.get("sp", 0)) > 0:
		add_sp(int(r["sp"]))
		items.append(["pass", "%d Pass points" % int(r["sp"])])
	if int(r.get("bp", 0)) > 0:
		add_bp(int(r["bp"]))
		items.append(["trophy", "%d league points" % int(r["bp"])])
	changed.emit()
	return items


## Words for a reward before it's claimed ("$1.2K, 3 sparks, Server Crate").
func describe(r: Dictionary) -> String:
	var bits := []
	if r.has("money"):
		bits.append("$" + Fmt.num(float(r["money"])))
	if r.has("money_s"):
		bits.append("$" + Fmt.num(LiveDefs.snap(ref_income * float(r["money_s"]))))
	if int(r.get("gems", 0)) > 0:
		bits.append("%d sparks" % int(r["gems"]))
	for b in ["warp15", "warp60", "overclock", "freeze"]:
		if int(r.get(b, 0)) > 0:
			bits.append(LiveDefs.BOOSTERS[b]["name"] + (" x%d" % int(r[b]) if int(r[b]) > 1 else ""))
	if r.has("crate"):
		bits.append(LiveDefs.CRATES[r["crate"]]["name"])
	if r.has("decor"):
		bits.append(Defs.BUILDINGS[r["decor"]]["name"])
	if int(r.get("sp", 0)) > 0:
		bits.append("%d Pass pts" % int(r["sp"]))
	return ", ".join(bits)


# ---------------------------------------------------------------- crates

func add_crate(kind: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	if crates.size() < LiveDefs.CRATE_SLOTS:
		crates.append({"kind": kind, "seed": rng.randi(), "state": "locked", "end": 0})
	else:
		add_msg("A crate waits for you", "Your crate slots were full, so we kept this %s here. Claim it when a slot is free." % LiveDefs.CRATES[kind]["name"], "crate_" + kind, {"crate": kind})
	changed.emit()


func unlocking() -> int:
	for i in crates.size():
		if crates[i]["state"] == "unlocking":
			return i
	return -1


func start_unlock(i: int) -> bool:
	if i < 0 or i >= crates.size() or crates[i]["state"] != "locked" or unlocking() >= 0:
		return false
	crates[i]["state"] = "unlocking"
	crates[i]["end"] = now() + int(LiveDefs.CRATES[crates[i]["kind"]]["time"])
	changed.emit()
	save_live()
	return true


func crate_left(i: int) -> float:
	var c: Dictionary = crates[i]
	match c["state"]:
		"ready": return 0.0
		"unlocking": return maxf(0.0, float(int(c["end"]) - now()))
	return float(LiveDefs.CRATES[c["kind"]]["time"])


func crate_skip_price(i: int) -> int:
	return 0 if crates[i]["state"] == "ready" else LiveDefs.crate_skip_price(crate_left(i))


## Opens crate i (with sparks if it isn't ready). Returns its loot items.
func open_crate(i: int) -> Array:
	if i < 0 or i >= crates.size():
		return []
	var price := crate_skip_price(i)
	if price > 0:
		if Game.gems < price:
			return []
		Game.add_gems(-price)
	var c: Dictionary = crates[i]
	crates.remove_at(i)
	var loot := LiveDefs.crate_loot(c["kind"], int(c["seed"]), ref_income)
	counters["crates"] = float(counters.get("crates", 0.0)) + 1.0
	var items := grant(loot)
	save_live()
	return items


# ---------------------------------------------------------------- boosters

## Takes 15 or 60 minutes off a builder's job.
func use_warp(kind: String, j: Dictionary) -> bool:
	if int(boosters.get(kind, 0)) <= 0 or not Game.jobs.has(j):
		return false
	boosters[kind] = int(boosters[kind]) - 1
	var cut := 900.0 if kind == "warp15" else 3600.0
	j["end"] = maxf(Game.clock, float(j["end"]) - cut)
	j["start"] = minf(float(j["start"]), float(j["end"]))
	Game.jobs_changed.emit()
	changed.emit()
	save_live()
	return true


## The best warp to use on a job with `left` seconds left ("" if none).
func best_warp(left: float) -> String:
	if left > 900.0 and int(boosters.get("warp60", 0)) > 0:
		return "warp60"
	if int(boosters.get("warp15", 0)) > 0:
		return "warp15"
	if int(boosters.get("warp60", 0)) > 0:
		return "warp60"
	return ""


func use_overclock() -> bool:
	if int(boosters.get("overclock", 0)) <= 0 or Game.rush_active():
		return false
	boosters["overclock"] = int(boosters["overclock"]) - 1
	Game.rush_cooldown = 0.0
	Game.start_rush()
	changed.emit()
	save_live()
	return true


# ---------------------------------------------------------------- badges

func badge_value(id: String) -> float:
	match id:
		"tokens": return float(Game.stats["tokens"])
		"models": return float(Game.known_recipes.size())
		"land": return float(Game.land.size())
		"orders": return float(Game.stats["orders"])
		"customers": return float(Game.stats["customers"])
		"streak": return float(streak_best)
		"clears": return float(Game.cleared)
		"hires": return float(Game.hired)
		"league": return float(int(league["best"]) + 1)
		"events": return float(counters.get("events", 0.0))
	return float(counters.get(id, 0.0))


## Tiers reached (0..5).
func badge_tier(id: String) -> int:
	var v := badge_value(id)
	var n := 0
	for t in LiveDefs.BADGES[id]["tiers"]:
		if v >= float(t):
			n += 1
	return n


func badge_claimable(id: String) -> bool:
	return badge_tier(id) > int(badges.get(id, 0))


func claim_badge(id: String) -> Array:
	if not badge_claimable(id):
		return []
	var t := int(badges.get(id, 0))
	badges[id] = t + 1
	var items := grant({"gems": LiveDefs.BADGE_GEMS[t]})
	save_live()
	return items


func badge_text(id: String, tier: int) -> String:
	var d: Dictionary = LiveDefs.BADGES[id]
	var tiers: Array = d["tiers"]
	var v: float = tiers[clampi(tier, 0, tiers.size() - 1)]
	if id == "league":
		return d["what"] % LiveDefs.LEAGUES[int(v) - 1]["name"]
	return d["what"] % Fmt.num(v)


# ---------------------------------------------------------------- model mastery

func stars(rid: String) -> int:
	var n := 0
	for t in LiveDefs.MASTERY:
		if int(mastery.get(rid, 0)) >= t:
			n += 1
	return n


func mastery_claimable(rid: String) -> bool:
	return stars(rid) > int(mastery_claimed.get(rid, 0))


func claim_mastery(rid: String) -> Array:
	if not mastery_claimable(rid):
		return []
	var s := int(mastery_claimed.get(rid, 0))
	mastery_claimed[rid] = s + 1
	var items := grant({"gems": LiveDefs.MASTERY_GEMS[s]})
	save_live()
	return items


# ---------------------------------------------------------------- multipliers (events, mastery)

## How much more a model's tokens sell for right now.
func price_mult(rid: String) -> float:
	var m := 1.0 + LiveDefs.MASTERY_PRICE * stars(rid)
	var ev := active_events()
	if ev.has("community"):
		m *= 2.0
	if ev.has("spotlight") and rid == spotlight_model():
		m *= 3.0
	return m


## Build and upgrade times for jobs started now.
func time_mult() -> float:
	return 0.75 if active_events().has("hackathon") else 1.0


func research_mult() -> float:
	return 0.8 if active_events().has("launch") else 1.0


func sp_mult() -> float:
	var ev := active_events()
	if ev.has("community"):
		return 3.0
	if ev.has("final"):
		return 2.0
	return 1.0


# ---------------------------------------------------------------- events

func active_events() -> Array:
	var out := []
	if not events_on:
		return out
	var lt := local()
	for id in LiveDefs.EVENT_ORDER:
		var w := LiveDefs.event_window(id, lt)
		if not w.is_empty() and lt >= int(w[0]) and lt < int(w[1]):
			out.append(id)
	return out


## [start, end] in local time of the event's current or next occurrence.
func event_window(id: String) -> Array:
	return LiveDefs.event_window(id, local())


## The model in this week's Spotlight Hour (one you can serve).
func spotlight_model() -> String:
	var known := Game.known_list()
	if known.is_empty():
		return "pico"
	return known[absi(hash([week_of(today()), "spot"])) % known.size()]


func _event_begins(id: String) -> void:
	var w := event_window(id)
	var key := "%s:%d" % [id, int(w[0]) if not w.is_empty() else 0]
	if events_seen.has(key):
		return
	events_seen[key] = true
	var d: Dictionary = LiveDefs.EVENTS[id]
	var body: String = d["desc"]
	if id == "spotlight":
		body = "%s sells for 3x for the next hour." % Defs.recipe(spotlight_model())["name"]
	if id == "community":
		event_quests = {"start": int(w[0]), "list": [_quest("ev_serve"), _quest("ev_upgrade"), _quest("ev_cafe")], "done": false}
	add_msg(d["name"] + " is on!", body, d["icon"])
	event_started.emit(id)
	changed.emit()


func event_quest_ready(i: int) -> bool:
	var l: Array = event_quests["list"]
	return i < l.size() and quest_ready(l[i]) and active_events().has("community")


func claim_event_quest(i: int) -> Array:
	if not event_quest_ready(i):
		return []
	var q: Dictionary = event_quests["list"][i]
	q["claimed"] = true
	var items := grant(quest_reward(q))
	counters["events"] = float(counters.get("events", 0.0)) + 1.0
	var all_done := true
	for e in event_quests["list"]:
		if not e["claimed"]:
			all_done = false
	if all_done and not event_quests["done"]:
		event_quests["done"] = true
		var r := {"crate": "gpu"}
		if not unlocked.has("server_fountain"):
			r["decor"] = "server_fountain"
		items += grant(r)
		reward.emit("Community Day complete!", "You finished all three Community Day quests.", items)
	changed.emit()
	save_live()
	return items


# ---------------------------------------------------------------- league

func add_bp(n: int) -> void:
	if n <= 0:
		return
	if not league["joined"]:
		league["joined"] = true
	league["points"] = int(league["points"]) + n
	changed.emit()


## The 29 rival labs of week w in league tier t.
func rivals(w: int, t: int) -> Array:
	var out := []
	for i in LiveDefs.LEAGUE_SIZE - 1:
		var s := absi(hash([w, t, i, profile.get("id", "")]))
		var rng := RandomNumberGenerator.new()
		rng.seed = s
		var ghost := rng.randf() < 0.12
		out.append({
			"name": LiveDefs.rival_name(s), "color": LiveDefs.rival_color(s), "seed": s,
			"mean": 0.0 if ghost else LiveDefs.league_base(t) * exp(rng.randfn(0.0, 0.55)),
			"p": rng.randf_range(0.35, 0.95), "h0": rng.randf_range(7.0, 21.0), "dur": rng.randf_range(0.7, 3.0),
		})
	return out


## A rival's points in week w up to local time lt.
static func rival_points(r: Dictionary, w: int, lt: int) -> int:
	var total := 0.0
	var d0 := week_start(w)
	for k in 7:
		var ds := (d0 + k) * 86400
		if lt <= ds:
			break
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(hash([int(r["seed"]), k]))
		if rng.randf() > float(r["p"]):
			continue
		var pts := float(r["mean"]) * rng.randf_range(0.4, 1.7)
		var h := float(lt - ds) / 3600.0
		var f := clampf((h - float(r["h0"])) / float(r["dur"]), 0.0, 1.0)
		total += pts * f
	return int(total)


## This week's table: [{name, color, points, me}] sorted by points.
func standings(at := -1) -> Array:
	var w := int(league["week"])
	var t := int(league["tier"])
	var lt := local() if at < 0 else at
	var rows := []
	for r in rivals(w, t):
		rows.append({"name": r["name"], "color": r["color"], "points": rival_points(r, w, lt), "me": false})
	rows.append({"name": profile["name"], "color": LiveDefs.rival_color(int(profile.get("logo", 0)) * 997 + 11), "points": int(league["points"]), "me": true})
	rows.sort_custom(func(a, b):
		if a["points"] == b["points"]:
			return a["me"]
		return a["points"] > b["points"])
	return rows


func my_rank(rows: Array = []) -> int:
	if rows.is_empty():
		rows = standings()
	for i in rows.size():
		if rows[i]["me"]:
			return i + 1
	return rows.size()


## Seconds left in the league week.
func league_left() -> int:
	return (week_start(int(league["week"]) + 1)) * 86400 - local()


func _new_week(w: int) -> void:
	var old := int(league["week"])
	if old >= 0 and league["joined"]:
		var end_t := week_start(old + 1) * 86400 - 1
		var rows := standings(end_t)
		var rank := my_rank(rows)
		var t := int(league["tier"])
		var move := 0
		if rank <= LiveDefs.PROMOTE and t < LiveDefs.LEAGUES.size() - 1:
			move = 1
		elif rank > LiveDefs.LEAGUE_SIZE - LiveDefs.DEMOTE and t > 0:
			move = -1
		var r := {}
		if rank <= 3:
			r = (LiveDefs.LEAGUE_REWARDS[rank - 1] as Dictionary).duplicate()
			if not unlocked.has("trophy"):
				r["decor"] = "trophy"
		elif rank <= LiveDefs.PROMOTE:
			r = LiveDefs.LEAGUE_REWARDS[3]
		var res := {"week": old, "tier": t, "rank": rank, "move": move, "points": int(league["points"]), "reward": r}
		league_history.append(res)
		while league_history.size() > 20:
			league_history.pop_front()
		league["tier"] = clampi(t + move, 0, LiveDefs.LEAGUES.size() - 1)
		league["best"] = maxi(int(league["best"]), int(league["tier"]))
		var lname: String = LiveDefs.LEAGUES[t]["name"]
		var nname: String = LiveDefs.LEAGUES[league["tier"]]["name"]
		var body := "You finished #%d in the %s League with %d points. " % [rank, lname, int(league["points"])]
		body += ["You stay in %s." % nname, "Promoted to %s!" % nname, "Down to %s; win it back this week." % nname][move if move >= 0 else 2]
		add_msg("League week over", body, "trophy", r)
		league_result.emit(res)
	league["week"] = w
	league["points"] = 0
	league["joined"] = false
	_bp_acc = 0.0
	changed.emit()


func league_name(t := -1) -> String:
	return LiveDefs.LEAGUES[int(league["tier"]) if t < 0 else t]["name"]


# ---------------------------------------------------------------- Lab Pass

func add_sp(n: int) -> void:
	if n <= 0:
		return
	season["sp"] = int(season["sp"]) + int(round(n * sp_mult()))
	changed.emit()


func pass_tier() -> int:
	return mini(LiveDefs.PASS_TIERS, int(season["sp"]) / LiveDefs.PASS_TIER_SP)


func pass_claimable(i: int, premium: bool) -> bool:
	if premium and not season["premium"]:
		return false
	return i < pass_tier() and not (season["prem" if premium else "free"] as Array).has(i)


func claim_pass(i: int, premium: bool) -> Array:
	if not pass_claimable(i, premium):
		return []
	(season["prem" if premium else "free"] as Array).append(i)
	var items := grant(LiveDefs.pass_reward(i, premium))
	save_live()
	return items


func pass_claimables() -> int:
	var n := 0
	for i in pass_tier():
		if pass_claimable(i, false):
			n += 1
		if pass_claimable(i, true):
			n += 1
	return n


func buy_premium() -> bool:
	if season["premium"] or Game.gems < LiveDefs.PASS_PRICE:
		return false
	Game.add_gems(-LiveDefs.PASS_PRICE)
	season["premium"] = true
	changed.emit()
	save_live()
	return true


func season_name(id := -1) -> String:
	if id < 0:
		id = int(season["id"])
	return LiveDefs.SEASON_THEMES[posmod(id, 12)]


## Seconds left in the season (local month).
func season_left() -> int:
	var dt := Time.get_datetime_dict_from_unix_time(local())
	var y := int(dt["year"])
	var m := int(dt["month"]) + 1
	if m > 12:
		m = 1
		y += 1
	return int(Time.get_unix_time_from_datetime_dict({"year": y, "month": m, "day": 1, "hour": 0, "minute": 0, "second": 0})) - local()


func _new_season(s: int) -> void:
	var old := int(season["id"])
	if old >= 0:
		# rewards reached but not claimed go to the inbox
		var r := {}
		var tiers := mini(LiveDefs.PASS_TIERS, int(season["sp"]) / LiveDefs.PASS_TIER_SP)
		var gems := 0
		var crates_left := []
		for i in tiers:
			for prem in [false, true]:
				if prem and not season["premium"]:
					continue
				if (season["prem" if prem else "free"] as Array).has(i):
					continue
				var pr := LiveDefs.pass_reward(i, prem)
				gems += int(pr.get("gems", 0)) + int(pr.get("warp15", 0)) * 2 + int(pr.get("warp60", 0)) * 5
				if pr.has("crate"):
					crates_left.append(pr["crate"])
				if pr.has("decor"):
					unlock(pr["decor"])
		if gems > 0:
			r["gems"] = gems
		if not crates_left.is_empty():
			r["crate"] = crates_left.back()
		add_msg("Season over: " + season_name(old), "You reached tier %d of the Lab Pass. Anything you hadn't claimed is here." % tiers, "pass", r)
	season = {"id": s, "sp": 0, "premium": false, "free": [], "prem": []}
	changed.emit()


# ---------------------------------------------------------------- exclusive decor

func unlock(kind: String) -> void:
	if not unlocked.has(kind):
		unlocked[kind] = true
		changed.emit()


func is_unlocked(kind: String) -> bool:
	return not LiveDefs.EXCLUSIVE.has(kind) or unlocked.has(kind)


# ---------------------------------------------------------------- inbox

func add_msg(title: String, body: String, icon := "mail", r := {}) -> void:
	inbox.push_front({"id": next_msg, "t": now(), "title": title, "body": body, "icon": icon, "reward": r, "read": false, "claimed": r.is_empty()})
	next_msg += 1
	while inbox.size() > 40:
		inbox.pop_back()
	changed.emit()


func claim_msg(id: int) -> Array:
	for m in inbox:
		if int(m["id"]) == id and not m["claimed"]:
			if (m["reward"] as Dictionary).has("crate") and crates.size() >= LiveDefs.CRATE_SLOTS:
				return []
			m["claimed"] = true
			m["read"] = true
			var items := grant(m["reward"])
			save_live()
			return items
	return []


func unread() -> int:
	var n := 0
	for m in inbox:
		if not m["read"] or not m["claimed"]:
			n += 1
	return n


func read_all() -> void:
	for m in inbox:
		m["read"] = true
	changed.emit()


# ---------------------------------------------------------------- profile

func set_lab_name(n: String) -> void:
	n = n.strip_edges().left(24)
	if n != "":
		profile["name"] = n
		changed.emit()
		save_live()


## The friend code: TKN-XXXX-YYYY, the lab id plus a check.
func friend_code() -> String:
	return code_for(str(profile.get("id", "0")))


static func code_for(id: String) -> String:
	var a := id.to_upper().left(8).lpad(8, "0")
	var check := "%04X" % (absi(hash("tkn" + a)) % 65536)
	return "TKN-%s-%s" % [a.left(4) + a.right(4), check]


static func code_valid(code: String) -> bool:
	var c := code.strip_edges().to_upper()
	var p := c.split("-")
	if p.size() != 3 or p[0] != "TKN" or p[1].length() != 8:
		return false
	return code_for(p[1]) == c


## A friend's code: a welcome gift once (not your own code).
func redeem(code: String) -> String:
	var c := code.strip_edges().to_upper()
	if not code_valid(c):
		return "That code doesn't look right."
	if c == friend_code():
		return "That's your own code. Share it with friends instead!"
	if str(profile.get("referral", "")) != "":
		return "You've already used a friend's code."
	profile["referral"] = c
	add_msg("A friend invited you", "Thanks for joining through a friend. Here's a welcome gift.", "gift", {"gems": 10, "crate": "server"})
	save_live()
	return ""


func invite_text() -> String:
	return "I'm running %s in Token Empire: %s tokens served, Lab level %d, a %d-day streak. Join me and enter my code %s for a gift!" % [
		profile["name"], Fmt.num(int(Game.stats["tokens"])), Game.level, streak, friend_code()]


# ---------------------------------------------------------------- badges for the HUD

## Things waiting to be claimed (for the red dot on the hub button).
func claimables() -> int:
	var n := 0
	for q in quests:
		if quest_ready(q):
			n += 1
	if not login_claimed:
		n += 1
	if breakthrough_ready():
		n += 1
	for c in crates:
		if c["state"] == "ready":
			n += 1
	if unlocking() < 0:
		for c in crates:
			if c["state"] == "locked":
				n += 1
				break
	for id in LiveDefs.BADGES:
		if badge_claimable(id):
			n += 1
	for rid in mastery:
		if mastery_claimable(rid):
			n += 1
	n += mini(1, pass_claimables())
	for i in event_quests["list"].size():
		if event_quest_ready(i):
			n += 1
	for m in inbox:
		if not m["claimed"]:
			n += 1
	return n


# ---------------------------------------------------------------- save / load

func to_dict() -> Dictionary:
	return {
		"v": VERSION, "profile": profile, "day": day, "goal": goal, "goal_got": goal_got, "goal_done": goal_is_done,
		"streak": streak, "best": streak_best, "last_goal": last_goal_day, "freezes": freezes,
		"lost": lost_streak, "lost_day": lost_day, "goal_days": goal_days, "freeze_days": freeze_days,
		"quests": quests, "rerolled": rerolled, "stamps": stamps, "login_idx": login_idx, "login_claimed": login_claimed,
		"crates": crates, "boosters": boosters, "counters": counters, "day_counts": day_counts, "badges": badges,
		"mastery": mastery, "mastery_claimed": mastery_claimed, "unlocked": unlocked, "league": league,
		"league_history": league_history, "season": season, "inbox": inbox, "next_msg": next_msg,
		"events_seen": events_seen, "event_quests": event_quests, "notify": notify, "last_seen": now(),
		"income": income_hint, "ref_income": ref_income,
	}


func from_dict(d: Dictionary) -> void:
	reset_state()
	if int(d.get("v", 0)) != VERSION:
		return
	for k in d.get("profile", {}):
		profile[k] = d["profile"][k]
	day = int(d.get("day", -1))
	goal = int(d.get("goal", 0))
	goal_got = int(d.get("goal_got", 0))
	goal_is_done = bool(d.get("goal_done", false))
	streak = int(d.get("streak", 0))
	streak_best = int(d.get("best", 0))
	last_goal_day = int(d.get("last_goal", -100000))
	freezes = int(d.get("freezes", 0))
	lost_streak = int(d.get("lost", 0))
	lost_day = int(d.get("lost_day", -100000))
	goal_days = _ints(d.get("goal_days", []))
	freeze_days = _ints(d.get("freeze_days", []))
	quests = d.get("quests", [])
	for q in quests:
		q["n"] = int(q["n"])
		q["base"] = float(q.get("base", 0.0))
	rerolled = bool(d.get("rerolled", false))
	stamps = int(d.get("stamps", 0))
	login_idx = int(d.get("login_idx", 0))
	login_claimed = bool(d.get("login_claimed", false))
	crates = d.get("crates", [])
	for c in crates:
		c["seed"] = int(c["seed"])
		c["end"] = int(c.get("end", 0))
	for k in d.get("boosters", {}):
		boosters[k] = int(d["boosters"][k])
	counters = d.get("counters", {})
	day_counts = d.get("day_counts", {})
	badges = d.get("badges", {})
	for k in badges:
		badges[k] = int(badges[k])
	mastery = d.get("mastery", {})
	for k in mastery:
		mastery[k] = int(mastery[k])
	mastery_claimed = d.get("mastery_claimed", {})
	for k in mastery_claimed:
		mastery_claimed[k] = int(mastery_claimed[k])
	unlocked = d.get("unlocked", {})
	for k in d.get("league", {}):
		league[k] = d["league"][k]
	for k in ["tier", "week", "points", "best"]:
		league[k] = int(league[k])
	league_history = d.get("league_history", [])
	for k in d.get("season", {}):
		season[k] = d["season"][k]
	season["id"] = int(season["id"])
	season["sp"] = int(season["sp"])
	season["free"] = _ints(season.get("free", []))
	season["prem"] = _ints(season.get("prem", []))
	inbox = d.get("inbox", [])
	for m in inbox:
		m["id"] = int(m["id"])
	next_msg = int(d.get("next_msg", 1))
	events_seen = d.get("events_seen", {})
	event_quests = d.get("event_quests", event_quests)
	for k in d.get("notify", {}):
		notify[k] = d["notify"][k]
	last_seen = int(d.get("last_seen", 0))
	income_hint = float(d.get("income", 1.0))
	ref_income = float(d.get("ref_income", 1.0))


static func _ints(a: Array) -> Array:
	var out := []
	for x in a:
		out.append(int(x))
	return out


func save_live() -> void:
	if Game.no_save or not loaded:
		return
	var f := FileAccess.open(SAVE_PATH + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(to_dict()))
	f.close()
	DirAccess.rename_absolute(ProjectSettings.globalize_path(SAVE_PATH + ".tmp"), ProjectSettings.globalize_path(SAVE_PATH))


func load_live() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if d is Dictionary:
		from_dict(d)


func wipe() -> void:
	reset_state()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
	tick()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		last_seen = now()
		save_live()
