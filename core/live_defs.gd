class_name LiveDefs
## The daily and weekly layer around the empire (see Live): the daily goal
## and streak, daily quests, the login calendar, supply crates, badges, the
## Benchmark League of rival AI labs, the monthly Lab Pass, events on the
## calendar and the reminders the game sends. Everything here is data and
## pure functions; Live holds the state.

# ---------------------------------------------------------------- streak

## Streak lengths that bring a reward and a card.
const STREAK_MILESTONES := {
	3: {"gems": 5, "warp15": 1},
	7: {"gems": 10, "freeze": 1, "crate": "server"},
	14: {"gems": 15, "crate": "server"},
	30: {"gems": 25, "freeze": 1, "crate": "gpu", "decor": "streak_flame"},
	50: {"gems": 30, "crate": "gpu"},
	100: {"gems": 50, "crate": "lab"},
	150: {"gems": 60, "crate": "lab"},
	200: {"gems": 75, "crate": "lab"},
	365: {"gems": 150, "crate": "lab"},
}
const MAX_FREEZES := 2
const FREEZE_PRICE := 10          # sparks
const REPAIR_BASE := 15           # sparks to repair a lost streak (plus 1 per day of it)


## Sparks to bring back a lost streak of n days.
static func repair_price(n: int) -> int:
	return REPAIR_BASE + mini(n, 85)


## The streak flame's look: grey, warm orange, blue at 30, purple at 100.
static func flame_color(streak: int, done: bool) -> Color:
	if not done:
		return Color(0.62, 0.64, 0.68)
	if streak >= 100:
		return Color(0.78, 0.5, 1.0)
	if streak >= 30:
		return Color(0.4, 0.8, 1.0)
	return Color(1.0, 0.62, 0.22)


# ---------------------------------------------------------------- daily goal

## Tokens to serve today: about ten minutes of serving at today's rate,
## snapped to a friendly number (fallback: a slice of the next Lab level).
static func daily_goal(rate: float, level: int) -> int:
	var by_rate := rate * 600.0
	var lv := clampi(level, 1, Defs.EMPIRE.size() - 1)
	var gap := float(Defs.EMPIRE[lv]["xp"]) - float(Defs.EMPIRE[lv - 1]["xp"])
	var by_level := gap * 0.2
	var g := by_rate if by_rate > 5.0 else by_level
	g = clampf(g, 20.0, maxf(20.0, by_level * 4.0))
	return int(snap(g))


## Rounds to 2 significant digits (20, 35, 120, 4500...).
static func snap(v: float) -> float:
	if v < 10.0:
		return roundf(v)
	var mag := pow(10.0, floorf(log(v) / log(10.0)) - 1.0)
	var s := roundf(v / mag) * mag
	if s >= 100.0:
		s = roundf(s / (mag * 5.0)) * mag * 5.0
	return s


# ---------------------------------------------------------------- daily quests

## Quest templates: what to count, how much, when it makes sense.
##   tier 0 easy, 1 medium, 2 hard. "n" is computed by quest_amount().
const QUESTS := {
	"serve": {"tier": 0, "text": "Serve %s tokens", "metric": "tokens", "icon": "token"},
	"upgrade2": {"tier": 0, "text": "Upgrade %s buildings", "metric": "upgrades", "icon": "hammer"},
	"earn": {"tier": 0, "text": "Earn $%s", "metric": "money", "icon": "coin"},
	"installs": {"tier": 0, "text": "Install %s GPUs or HBM stacks", "metric": "installs", "icon": "gpu"},
	"tunes": {"tier": 0, "text": "Tune servers %s times", "metric": "tunes", "icon": "engineer"},
	"cafe": {"tier": 1, "text": "Welcome %s visitors at the Chat Café", "metric": "customers", "icon": "cafe"},
	"contracts": {"tier": 1, "text": "Complete %s contracts", "metric": "orders", "icon": "desk"},
	"trend": {"tier": 1, "text": "Sell %s tokens of the trending model", "metric": "trend_tokens", "icon": "speed"},
	"clear": {"tier": 1, "text": "Clear %s obstacles", "metric": "clears", "icon": "gem"},
	"build": {"tier": 1, "text": "Build %s new buildings", "metric": "builds", "icon": "hammer"},
	"gateway": {"tier": 1, "text": "Serve %s tokens through the API", "metric": "api_tokens", "icon": "gateway"},
	"train": {"tier": 2, "text": "Finish %s training runs", "metric": "trainings", "icon": "trainer"},
	"launch": {"tier": 2, "text": "Launch %s orbital modules", "metric": "launches", "icon": "launchpad"},
	"serve_big": {"tier": 2, "text": "Serve %s tokens", "metric": "tokens", "icon": "token"},
	"upgrade5": {"tier": 2, "text": "Upgrade %s buildings", "metric": "upgrades", "icon": "hammer"},
	"research": {"tier": 2, "text": "Research %s upgrades", "metric": "research", "icon": "research"},
	"hire": {"tier": 2, "text": "Hire %s new staff", "metric": "hires", "icon": "hire"},
	"overclock": {"tier": 2, "text": "Overclock %s times", "metric": "overclock", "icon": "boost"},
	"agents": {"tier": 2, "text": "Serve %s tokens to agents", "metric": "agents", "icon": "agent_hub"},
	# Community Day quests
	"ev_serve": {"tier": 3, "text": "Community Day: serve %s tokens", "metric": "tokens", "icon": "token"},
	"ev_upgrade": {"tier": 3, "text": "Community Day: upgrade %s buildings", "metric": "upgrades", "icon": "hammer"},
	"ev_cafe": {"tier": 3, "text": "Community Day: sell %s tokens anywhere", "metric": "sales", "icon": "coin"},
}

## Rewards per quest tier: money in seconds of income, sparks, Pass and League points.
const QUEST_REWARDS := [
	{"money_s": 150.0, "gems": 0, "sp": 20, "bp": 10},
	{"money_s": 300.0, "gems": 1, "sp": 30, "bp": 15},
	{"money_s": 600.0, "gems": 2, "sp": 40, "bp": 25},
	{"money_s": 600.0, "gems": 3, "sp": 60, "bp": 30},
]


## How much a quest asks for, given today's goal and income.
static func quest_amount(id: String, goal: int, income: float) -> int:
	match id:
		"serve": return int(snap(goal * 0.8))
		"serve_big": return int(snap(goal * 2.5))
		"upgrade2": return 2
		"upgrade5": return 5
		"earn": return int(snap(maxf(100.0, income * 360.0)))
		"installs": return 3
		"tunes": return 25
		"cafe": return 20
		"contracts": return 2
		"trend": return int(snap(maxf(10.0, goal * 0.4)))
		"clear": return 1
		"build": return 1
		"gateway": return int(snap(goal * 0.5))
		"train": return 1
		"launch": return 1
		"research": return 1
		"hire": return 1
		"overclock": return 1
		"agents": return int(snap(maxf(20.0, goal * 0.3)))
		"ev_serve": return int(snap(goal * 1.5))
		"ev_upgrade": return 3
		"ev_cafe": return int(snap(goal * 0.8))
	return 1


# ---------------------------------------------------------------- login calendar

## The 7-day login calendar (it cycles; missing a day doesn't reset it).
const LOGIN := [
	{"money_s": 300.0, "label": "Cash"},
	{"gems": 3, "label": "3 sparks"},
	{"warp15": 1, "label": "Time Warp"},
	{"money_s": 900.0, "label": "Big cash"},
	{"gems": 5, "label": "5 sparks"},
	{"overclock": 1, "label": "Overclock"},
	{"crate": "server", "label": "Server Crate"},
]


# ---------------------------------------------------------------- crates

const CRATE_SLOTS := 4
const CRATES := {
	"supply": {"name": "Supply Crate", "time": 3 * 3600, "money_s": 600.0, "gems": [1, 2], "warp15": 0.3, "warp60": 0.0, "overclock": 0.0, "color": Color(0.82, 0.68, 0.48)},
	"server": {"name": "Server Crate", "time": 8 * 3600, "money_s": 1800.0, "gems": [3, 5], "warp15": 1.0, "warp60": 0.0, "overclock": 0.4, "color": Color(0.72, 0.76, 0.82)},
	"gpu": {"name": "GPU Crate", "time": 12 * 3600, "money_s": 3600.0, "gems": [6, 10], "warp15": 1.0, "warp60": 1.0, "overclock": 0.6, "color": Color(0.96, 0.78, 0.3)},
	"lab": {"name": "Lab Crate", "time": 24 * 3600, "money_s": 9000.0, "gems": [15, 25], "warp15": 2.0, "warp60": 2.0, "overclock": 1.0, "color": Color(0.7, 0.5, 1.0)},
}
const CRATE_ORDER := ["supply", "server", "gpu", "lab"]


## Sparks to open a crate now: one per 20 minutes left (at least one).
static func crate_skip_price(seconds_left: float) -> int:
	return maxi(1, int(ceil(seconds_left / 1200.0)))


## What a crate holds (rolled once, from its seed).
static func crate_loot(kind: String, seed: int, income: float) -> Dictionary:
	var d: Dictionary = CRATES[kind]
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var out := {}
	out["money"] = snap(maxf(100.0, income) * float(d["money_s"]) * rng.randf_range(0.85, 1.25))
	var g: Array = d["gems"]
	out["gems"] = rng.randi_range(int(g[0]), int(g[1]))
	for b in ["warp15", "warp60", "overclock"]:
		var p := float(d[b])
		var n := int(floor(p))
		if rng.randf() < p - n:
			n += 1
		if n > 0:
			out[b] = n
	if kind == "lab":
		out["freeze"] = 1
	return out


# ---------------------------------------------------------------- boosters

const BOOSTERS := {
	"warp15": {"name": "Time Warp 15m", "icon": "clock", "desc": "Takes 15 minutes off a builder's job."},
	"warp60": {"name": "Time Warp 1h", "icon": "clock", "desc": "Takes an hour off a builder's job."},
	"overclock": {"name": "Overclock Charge", "icon": "boost", "desc": "Overclock now, even while it's cooling down."},
	"freeze": {"name": "Streak Freeze", "icon": "freeze", "desc": "Keeps your streak alive on a day you miss."},
}


# ---------------------------------------------------------------- badges

## Tiered badges: [metric, tiers, name, icon, what].
const BADGES := {
	"tokens": {"name": "Token Tycoon", "icon": "token", "what": "Serve %s tokens", "tiers": [1000, 10000, 100000, 1000000, 10000000]},
	"models": {"name": "Model Zoo", "icon": "recipe", "what": "Serve %s different models", "tiers": [3, 6, 10, 14, 17]},
	"upgrades": {"name": "Upgrader", "icon": "hammer", "what": "Finish %s upgrades", "tiers": [10, 50, 150, 400, 1000]},
	"land": {"name": "Landlord", "icon": "land", "what": "Own %s plots of land", "tiers": [5, 8, 12, 20, 32]},
	"orders": {"name": "Contractor", "icon": "desk", "what": "Complete %s contracts", "tiers": [5, 25, 100, 300, 1000]},
	"customers": {"name": "Café Host", "icon": "cafe", "what": "Welcome %s café visitors", "tiers": [50, 500, 5000, 50000, 500000]},
	"streak": {"name": "On Fire", "icon": "flame", "what": "Reach a %s-day streak", "tiers": [3, 7, 30, 100, 365]},
	"quests": {"name": "Questor", "icon": "calendar", "what": "Finish %s daily quests", "tiers": [5, 30, 100, 300, 1000]},
	"clears": {"name": "Clean Sweep", "icon": "gem", "what": "Clear %s obstacles", "tiers": [5, 20, 50, 100, 200]},
	"hires": {"name": "Recruiter", "icon": "hire", "what": "Hire %s people", "tiers": [3, 10, 25, 50, 80]},
	"league": {"name": "Benchmarked", "icon": "trophy", "what": "Reach the %s League", "tiers": [2, 4, 6, 8, 9]},
	"crates": {"name": "Unboxer", "icon": "crate_supply", "what": "Open %s crates", "tiers": [5, 25, 100, 300, 1000]},
	"events": {"name": "Regular", "icon": "event", "what": "Finish %s Community Day quests", "tiers": [1, 3, 9, 30, 90]},
}
const BADGE_ORDER := ["tokens", "models", "upgrades", "streak", "quests", "league", "land", "orders", "customers", "clears", "hires", "crates", "events"]
const BADGE_GEMS := [3, 6, 12, 20, 40]
const TIER_NAMES := ["I", "II", "III", "IV", "V"]


# ---------------------------------------------------------------- model mastery

## Tokens of one model for each mastery star, the sparks each star brings,
## and how much more that model's tokens sell for per star.
const MASTERY := [100, 1000, 10000, 100000]
const MASTERY_GEMS := [2, 4, 8, 16]
const MASTERY_PRICE := 0.02


# ---------------------------------------------------------------- league

## The Benchmark League: a week of rival AI labs racing for benchmark points.
const LEAGUES := [
	{"name": "Bronze", "color": Color(0.8, 0.52, 0.32)},
	{"name": "Silver", "color": Color(0.74, 0.78, 0.84)},
	{"name": "Gold", "color": Color(1.0, 0.8, 0.3)},
	{"name": "Sapphire", "color": Color(0.3, 0.5, 1.0)},
	{"name": "Ruby", "color": Color(0.92, 0.24, 0.34)},
	{"name": "Emerald", "color": Color(0.2, 0.78, 0.46)},
	{"name": "Amethyst", "color": Color(0.66, 0.4, 0.96)},
	{"name": "Pearl", "color": Color(0.96, 0.9, 0.86)},
	{"name": "Obsidian", "color": Color(0.24, 0.24, 0.3)},
	{"name": "Diamond", "color": Color(0.5, 0.95, 1.0)},
]
const LEAGUE_SIZE := 30
const PROMOTE := 7
const DEMOTE := 5
## Rewards for finishing the week: rank 1, 2, 3, then the rest of the promotion zone.
const LEAGUE_REWARDS := [
	{"gems": 20, "crate": "gpu"},
	{"gems": 12, "crate": "server"},
	{"gems": 8, "crate": "server"},
	{"gems": 4, "crate": "supply"},
]

const LAB_ADJ := ["Nimbus", "Quill", "Deep", "Bright", "Vector", "Lumen", "Cobalt", "Sparrow", "Granite", "Helix",
	"Orbit", "Tensor", "Juniper", "Prism", "Atlas", "Ember", "Fjord", "Kestrel", "Mosaic", "Northwind",
	"Onyx", "Pixel", "Quasar", "Ripple", "Saffron", "Tidal", "Umber", "Velvet", "Willow", "Zephyr",
	"Cinder", "Delta", "Echo", "Falcon", "Garnet", "Harbor", "Iris", "Jade", "Kepler", "Lattice"]
const LAB_NOUN := ["AI", "Labs", "Mind", "Neural", "Compute", "Systems", "Intelligence", "Research", "Cortex", "Logic", "Works", "Foundry"]


## A rival lab's name and logo colour from a seed.
static func rival_name(seed: int) -> String:
	var a: String = LAB_ADJ[absi(seed) % LAB_ADJ.size()]
	var n: String = LAB_NOUN[absi(seed / LAB_ADJ.size()) % LAB_NOUN.size()]
	return "%s %s" % [a, n]


static func rival_color(seed: int) -> Color:
	return Color.from_hsv(float(absi(seed * 37) % 360) / 360.0, 0.55, 0.9)


## A typical rival's points on an active day in league tier t.
static func league_base(t: int) -> float:
	return 90.0 * pow(1.22, t)


# ---------------------------------------------------------------- Lab Pass (seasons)

const PASS_TIERS := 30
const PASS_TIER_SP := 100
const PASS_PRICE := 120          # sparks for the premium track
const SEASON_THEMES := ["Open Weights", "Long Context", "Multimodal Spring", "Agents Unleashed", "Reasoning Season", "Summer of Scale",
	"Synthetic Data", "Edge Inference", "Benchmark Fever", "Alignment Autumn", "Distillation", "Frontier Winter"]


## The reward on tier i (0-based) of the free or premium track.
static func pass_reward(i: int, premium: bool) -> Dictionary:
	var n := i + 1
	if premium:
		if n == 15:
			return {"decor": "holo_bot"}
		if n == PASS_TIERS:
			return {"crate": "lab", "gems": 30}
		if n % 5 == 0:
			return {"crate": "gpu"}
		if n % 3 == 0:
			return {"warp60": 1}
		return {"gems": 3 + n / 6}
	if n == 10:
		return {"decor": "neon_sign"}
	if n == PASS_TIERS:
		return {"crate": "gpu", "gems": 15}
	if n % 5 == 0:
		return {"crate": "server"}
	if n % 4 == 0:
		return {"warp15": 1}
	if n % 2 == 0:
		return {"gems": 2}
	return {"money_s": 300.0 + n * 30.0}


# ---------------------------------------------------------------- events

## Recurring events, in local time:
##   spotlight  Tuesdays 18:00-19:00: one model sells for 3x
##   hackathon  weekends: builds and upgrades take a quarter less time
##   community  the 2nd Saturday of each month, 14:00-17:00: tokens sell
##              for 2x, triple Pass points and Community Day quests
##   launch     the first week of each month: research is 20% cheaper
##   final      the last two days of each month: double Pass points
const EVENTS := {
	"spotlight": {"name": "Spotlight Hour", "icon": "speed", "desc": "One model sells for 3x for an hour."},
	"hackathon": {"name": "Hackathon Weekend", "icon": "hammer", "desc": "Builds and upgrades you start take 25% less time."},
	"community": {"name": "Community Day", "icon": "event", "desc": "Every lab at once: tokens sell for 2x, triple Pass points and special quests with a Liquid-Cooled Fountain to win."},
	"launch": {"name": "Launch Week", "icon": "research", "desc": "Research is 20% cheaper."},
	"final": {"name": "Final Push", "icon": "pass", "desc": "Double Lab Pass points before the season ends."},
}
const EVENT_ORDER := ["community", "spotlight", "hackathon", "launch", "final"]


## [start, end] (local unix) of event `id`'s occurrence that is running at
## or comes next after local time `lt` (a local-time unix stamp: seconds
## since 1970 in the player's clock).
static func event_window(id: String, lt: int) -> Array:
	var day := int(floor(lt / 86400.0))
	for d in range(day - 7, day + 70):
		var w := _event_on(id, d)
		if w.is_empty():
			continue
		if int(w[1]) > lt:
			return w
	return []


## The window of event `id` that starts on local day d, or [].
static func _event_on(id: String, d: int) -> Array:
	var dt := Time.get_datetime_dict_from_unix_time(d * 86400)
	var wd := int(dt["weekday"])             # 0 = Sunday
	var t0 := d * 86400
	match id:
		"spotlight":
			if wd == 2:
				return [t0 + 18 * 3600, t0 + 19 * 3600]
		"hackathon":
			if wd == 6:
				return [t0, t0 + 2 * 86400]
		"community":
			if wd == 6 and int(dt["day"]) >= 8 and int(dt["day"]) <= 14:
				return [t0 + 14 * 3600, t0 + 17 * 3600]
		"launch":
			if int(dt["day"]) == 1:
				return [t0, t0 + 7 * 86400]
		"final":
			var next := Time.get_datetime_dict_from_unix_time((d + 2) * 86400)
			if int(next["day"]) == 1:
				return [t0, t0 + 2 * 86400]
	return []


# ---------------------------------------------------------------- comeback

## Gifts for coming back after a while (days away).
static func comeback(days: int) -> Dictionary:
	if days >= 14:
		return {"money_s": 14400.0, "gems": 25, "warp60": 2, "crate": "server"}
	if days >= 3:
		return {"money_s": 3600.0, "gems": 10, "warp60": 1}
	return {}


# ---------------------------------------------------------------- exclusive decor

## Decor you can't buy until you've earned it, and how.
const EXCLUSIVE := {
	"neon_sign": "Lab Pass, tier 10",
	"holo_bot": "Lab Pass premium, tier 15",
	"server_fountain": "Finish the Community Day quests",
	"trophy": "Finish a Benchmark League week in the top 3",
	"streak_flame": "Reach a 30-day streak",
	"quantum_core": "Complete a Breakthrough (7 days of quests)",
}


# ---------------------------------------------------------------- reminders

## What the reminders say, by category; a few variations each ({n} etc.
## are filled in by Notifier).
const COPY := {
	"builders": [["Construction complete", "{what} is ready. Your builders want a new job."], ["Builders are free", "{what} finished. Hand them the next upgrade!"]],
	"crate": [["Crate unlocked", "Your {what} is open. Come see what's inside."], ["A crate is ready", "The {what} finished unlocking."]],
	"offline": [["Servers at capacity", "Your earnings are full. Collect before they stop piling up."], ["Your GPUs are waiting", "Earnings have hit the cap. Time to collect and reinvest."]],
	"streak": [["Your {n}-day streak", "It ends at midnight. Serve a few tokens to keep the flame lit."], ["Keep the flame lit", "{n} days in a row. Don't let today be the one you miss."], ["Streak at risk", "Your {n}-day streak is waiting for today's tokens."]],
	"quests": [["New quests are in", "Three fresh quests and a crate to win today."], ["Good morning, lab", "Today's quests are ready. Your rivals already started."]],
	"event": [["{what} starts soon", "{desc}"], ["{what} in 10 minutes", "{desc}"]],
	"league": [["League ends tonight", "You're #{n} in the {what} League. A few points could change everything."], ["Last hours of the week", "#{n} in the {what} League. Promotion is close."]],
	"comeback": [["We kept your servers warm", "Your lab misses you. There's a welcome-back gift waiting."], ["Your rivals are catching up", "Come back for a gift and a fresh week in the League."]],
}
const QUIET_START := 22          # no reminders from 22:00
const QUIET_END := 8             # ...to 08:00 local
