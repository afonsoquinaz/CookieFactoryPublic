class_name Bal
## Every number in the game. Upgrades are table entries: cost curve + effect.

const START_MONEY := 0

# ---------------------------------------------------------------- upgrades
## Global upgrades. cost(level) = base * growth^level (level = current level,
## so the first purchase costs `base`). value(level) via Bal.value(id, level).
const UPGRADES := {
	# player
	"carry": {"name": "Big Arms", "icon": "backpack", "base": 30, "growth": 1.7, "max": 14,
		"desc": "Carry more items at once", "group": "you"},
	"speed": {"name": "Running Shoes", "icon": "speed", "base": 40, "growth": 1.75, "max": 10,
		"desc": "Walk faster", "group": "you"},
	# production line
	"belt": {"name": "Fast Belt", "icon": "conveyor", "base": 60, "growth": 1.6, "max": 15,
		"desc": "Dough moves through the tube faster", "group": "factory"},
	"oven": {"name": "Hot Oven", "icon": "oven", "base": 80, "growth": 1.6, "max": 15,
		"desc": "Bake cookies faster", "group": "factory"},
	"batch": {"name": "Bigger Batches", "icon": "dough", "base": 120, "growth": 1.9, "max": 10,
		"desc": "More cookies from every dough ball", "group": "factory"},
	"hopper": {"name": "Big Hoppers", "icon": "hopper", "base": 50, "growth": 1.55, "max": 12,
		"desc": "Hoppers hold more ingredients", "group": "factory"},
	"recipe": {"name": "Secret Recipe", "icon": "recipe", "base": 150, "growth": 2.0, "max": 15,
		"desc": "Every cookie sells for 20% more", "group": "factory"},
	# storage + logistics
	"pantry": {"name": "Pantry Shelves", "icon": "storage", "base": 120, "growth": 1.6, "max": 10,
		"desc": "Pantry stores more of each ingredient", "group": "storage", "needs": "pantry"},
	"shelf": {"name": "Packing Space", "icon": "storage", "base": 150, "growth": 1.6, "max": 10,
		"desc": "Packing Shelf holds more cookies", "group": "storage", "needs": "shelf"},
	"truck": {"name": "Bigger Trucks", "icon": "truck", "base": 90, "growth": 1.65, "max": 15,
		"desc": "Trucks carry more cookies per trip", "group": "storage"},
	"route": {"name": "Express Routes", "icon": "clock", "base": 110, "growth": 1.6, "max": 10,
		"desc": "Trucks come back sooner", "group": "storage"},
	# staff
	"cabin": {"name": "Bigger Cabin", "icon": "hire", "base": 120, "growth": 1.8, "max": 8,
		"desc": "Room for more workers", "group": "staff", "needs": "cabin"},
	"wspeed": {"name": "Worker Boots", "icon": "speed", "base": 150, "growth": 1.7, "max": 10,
		"desc": "Workers walk faster", "group": "staff", "needs": "cabin"},
	"wcarry": {"name": "Worker Baskets", "icon": "backpack", "base": 160, "growth": 1.75, "max": 10,
		"desc": "Workers carry more", "group": "staff", "needs": "cabin"},
}
const UPGRADE_GROUPS := [["farms", "Farms"], ["factory", "Factory"], ["storage", "Logistics"], ["you", "You"], ["staff", "Staff"]]

# farms: one upgrade per ingredient, "farm_<ingredient>"
const FARM_BASE := {"wheat": 15, "sugar": 30, "cocoa": 60, "egg": 120, "milk": 220}
const FARM_GROWTH := 1.42
const FARM_MAX := 25
## Farm levels where the farm visibly grows (more crops/animals, better fence).
const FARM_TIERS: Array[int] = [1, 5, 10, 15, 20]


static func upgrade_def(id: String) -> Dictionary:
	if id.begins_with("farm_"):
		var ing := id.substr(5)
		var d := {"name": Defs.FARM_NAMES[ing], "icon": ing, "base": FARM_BASE[ing], "growth": FARM_GROWTH,
			"max": FARM_MAX, "desc": "Grow %s faster and store more" % Defs.item_name(ing).to_lower(), "group": "farms"}
		if ing != "wheat":
			d["needs"] = "plot_" + ing
		return d
	return UPGRADES[id]


static func all_upgrade_ids() -> Array[String]:
	var out: Array[String] = []
	for ing in Defs.INGREDIENTS:
		out.append("farm_" + ing)
	for k in UPGRADES:
		out.append(k)
	return out


static func cost(id: String, level: int) -> int:
	var d := upgrade_def(id)
	return int(round(d["base"] * pow(d["growth"], level) / 5.0)) * 5 if level > 0 else int(d["base"])


# ---------------------------------------------------------------- effects
static func carry(l: int) -> int: return 6 + l * 3
static func player_speed(l: int) -> float: return 5.0 + l * 0.35
static func dough_speed(l: int) -> float: return 1.3 * pow(1.12, l)
static func dough_gap(l: int) -> float: return maxf(0.9, 2.2 * pow(0.93, l))   # metres between dough balls
static func bake_time(l: int) -> float: return 3.2 * pow(0.88, l)
static func batch_size(l: int) -> int: return 3 + l
static func hopper_cap(l: int) -> int: return 8 + l * 4
## Price per cookie: grows with every ingredient in the recipe and with the
## Secret Recipe upgrade.
const GRADE_PRICE := [3, 6, 11, 18, 28]
static func cookie_price(l: int, grade := 4) -> int: return int(round(GRADE_PRICE[clampi(grade, 0, 4)] * pow(1.2, l)))
static func pantry_cap(l: int) -> int: return 12 + l * 8
static func shelf_cap(l: int) -> int: return 24 + l * 16
static func tray_cap(l: int) -> int: return 16 + batch_size(l) * 4
static func truck_cap(l: int) -> int: return 8 + l * 6
static func truck_trip(l: int) -> float: return maxf(3.0, 8.0 * pow(0.88, l))
static func cabin_cap(l: int) -> int: return 4 + l * 2
static func worker_speed(l: int) -> float: return 3.0 + l * 0.3
static func worker_carry(l: int) -> int: return 4 + l * 2

# farms (level starts at 1)
static func farm_work_time(l: int) -> float: return maxf(0.3, 1.2 * pow(0.9, l - 1))
static func farm_yield(l: int) -> int: return 1 + int((l - 1) / 4)
static func farm_crate_cap(l: int) -> int: return 8 + (l - 1) * 2
static func farm_walk_speed(l: int) -> float: return 2.2 + (l - 1) * 0.08
static func farm_tier(l: int) -> int:
	var t := 0
	for k in FARM_TIERS.size():
		if l >= FARM_TIERS[k]:
			t = k
	return t

# ---------------------------------------------------------------- staff
static func hire_cost(hired: int) -> int:
	return int(round(30.0 * pow(1.45, hired) / 5.0)) * 5

const MAX_FARMERS_PER_FARM := 3

# ---------------------------------------------------------------- empire level
## XP to go from level l to l+1 (1 xp per cookie sold).
static func xp_needed(l: int) -> int:
	return int(round(20.0 * pow(1.5, l - 1)))

static func level_reward(l: int) -> int:
	return int(round(50.0 * pow(1.6, l - 2)))

const MAX_LEVEL := 40

# ---------------------------------------------------------------- misc
const TRUCK_IDLE_DEPART := 3.0      # a van leaves this long after its last load
const OFFLINE_CAP_HOURS := 3.0
const OFFLINE_FACTOR := 0.35
const RUSH_DURATION := 45.0         # Cookie Rush: everything 2x
const RUSH_COOLDOWN := 240.0
