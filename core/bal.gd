class_name Bal
## Every number in the game: building effects per level, prices, build and
## upgrade times, research, gem perks, land. Tuned for a long game (about two
## weeks to finish the Grand Cookie Palace; see tools/pacing.py). Timers do
## most of the pacing, as in a base builder: they run while you're away.

const START_MONEY := 60
const START_GEMS := 25

# ---------------------------------------------------------------- buildings

## Price of the next building of a kind when you already own `owned`.
static func build_cost(kind: String, owned: int) -> float:
	var d: Dictionary = Defs.BUILDINGS[kind]
	return snap_price(float(d["cost"]) * pow(float(d["growth"]), owned))


## Cost to take a building from level l to l+1.
static func upgrade_cost(kind: String, l: int) -> float:
	var d: Dictionary = Defs.BUILDINGS[kind]
	var g := 1.3
	match d["cat"]:
		"farm": g = 1.28
		"bake": g = 1.32
		"kitchen": g = 1.3
		"pack": g = 1.32
		"sell": g = 1.32
		"staff": g = 1.6
	return snap_price(float(d["up"]) * pow(g, l - 1))


## Seconds to build a new copy when you already own `owned` of this kind.
static func build_time(kind: String, owned: int) -> float:
	var t := float(Defs.BUILDINGS[kind].get("time", 0))
	if t <= 0.0:
		return 0.0
	return minf(t * pow(2.0, owned), 4.0 * 3600.0) * tool_mult()


## Seconds to upgrade from level l to l+1. Short at first (a few seconds),
## up to about 8 hours for the top levels.
static func upgrade_time(kind: String, l: int) -> float:
	var d: Dictionary = Defs.BUILDINGS[kind]
	var mx := maxi(2, int(d["max"]))
	var t0 := maxf(4.0, float(d.get("time", 10)) * 0.6)
	var top := 8.0 * 3600.0
	if d["cat"] == "staff":
		top = 2.0 * 3600.0
	var f := float(l - 1) / float(mx - 2) if mx > 2 else 0.0
	return roundf(t0 * pow(top / t0, pow(f, 1.25))) * tool_mult()


static func tool_mult() -> float:
	return pow(0.95, Game.research("tools"))


## Gems to finish a job right now. Short jobs (30 s or less) are free.
static func finish_gems(seconds: float) -> int:
	if seconds <= FREE_FINISH:
		return 0
	return maxi(1, int(ceil(pow(seconds / 60.0, 0.78))))

const FREE_FINISH := 30.0


static func max_level(kind: String) -> int:
	return int(Defs.BUILDINGS[kind]["max"])


## Visual tier (0..4) for a building at level l.
static func tier(kind: String, l: int) -> int:
	var tiers := _tiers(kind)
	var t := 0
	for k in tiers.size():
		if l >= tiers[k]:
			t = k
	return t


static func next_tier_level(kind: String, l: int) -> int:
	for t in _tiers(kind):
		if t > l and t <= max_level(kind):
			return t
	return -1


static func _tiers(kind: String) -> Array[int]:
	match Defs.BUILDINGS[kind]["cat"]:
		"farm": return Defs.FARM_TIERS
		"bake": return Defs.BAKERY_TIERS
	return Defs.MACHINE_TIERS


## Prices are rounded to friendly numbers.
static func snap_price(v: float) -> float:
	if v < 100.0:
		return roundf(v)
	var mag := pow(10.0, floorf(log(v) / log(10.0)) - 1.0)
	return roundf(v / mag) * mag

# farms
static func farm_work_time(l: int) -> float: return maxf(0.25, 1.3 * pow(0.94, l - 1))
static func farm_regrow(l: int) -> float: return maxf(1.0, 6.0 * pow(0.95, l - 1))
static func farm_yield(l: int) -> int: return 1 + (l - 1) / 6
static func farm_crate_cap(l: int) -> int: return 10 + (l - 1) * 3
static func farm_walk_speed(l: int) -> float: return 2.2 + (l - 1) * 0.05
const MAX_FARMERS := 4          # hired farmers per farm (plus the one it comes with)
const BIOME_BONUS := 0.4        # farms on their favourite land grow this much faster

# bakery
static func mixer_interval(l: int) -> float: return maxf(0.45, 2.4 * pow(0.95, l - 1))
static func belt_speed(l: int) -> float: return 1.4 * pow(1.04, l - 1)
static func silo_cap(l: int) -> int: return 10 + (l - 1) * 4
static func flour_cap(l: int) -> int: return 12 + (l - 1) * 3
static func bake_time(l: int) -> float: return maxf(0.8, 3.0 * pow(0.95, l - 1))
static func batch_size(l: int) -> int: return 3 + (l - 1) / 3
static func tray_cap(l: int) -> int: return 18 + (l - 1) * 4
const DOUGH_GAP := 0.7          # metres between dough balls

# staff housed without any cabin
const BASE_STAFF := 1

# kitchen machines
static func craft_time(kind: String, l: int) -> float: return maxf(0.5, float(Defs.BUILDINGS[kind]["craft"]) * pow(0.95, l - 1))
static func machine_in_cap(l: int) -> int: return 10 + (l - 1) * 3
static func machine_out_cap(l: int) -> int: return 10 + (l - 1) * 3

# storage + packing
static func pantry_cap(l: int) -> int: return 40 + (l - 1) * 15
static func rack_cap(l: int) -> int: return 40 + (l - 1) * 20
static func pack_time(l: int) -> float: return maxf(0.4, 2.6 * pow(0.95, l - 1))
static func wrap_time(l: int) -> float: return maxf(0.5, 3.2 * pow(0.95, l - 1))
static func packer_in_cap(l: int) -> int: return 24 + (l - 1) * 6
static func packer_out_cap(l: int) -> int: return 8 + (l - 1) * 2
const BOX_SIZE := 6
const BOX_MULT := 1.25          # a box is worth this much more than its 6 cookies
const GIFT_MULT := 1.6          # a gift is worth this much more than its box

# sales
static func truck_cap(l: int) -> int: return 10 + (l - 1) * 6
static func truck_trip(l: int) -> float: return maxf(3.0, 9.0 * pow(0.95, l - 1)) * pow(0.95, Game.research("vehicles"))
static func shop_rate(l: int) -> float: return 10.0 * pow(1.07, l - 1)        # customers / minute
static func shop_cap(l: int) -> int: return 20 + (l - 1) * 8
static func shop_buy(l: int) -> int: return 3 + (l - 1) / 3
static func train_cap(l: int) -> int: return 80 + (l - 1) * 40
static func train_trip(l: int) -> float: return maxf(12.0, 40.0 * pow(0.96, l - 1)) * pow(0.95, Game.research("vehicles"))
static func airship_cap(l: int) -> int: return 60 + (l - 1) * 30
static func airship_trip(l: int) -> float: return maxf(20.0, 60.0 * pow(0.96, l - 1)) * pow(0.95, Game.research("vehicles"))
const SHOP_MULT := 1.3
const TRAIN_MULT := 1.15
const AIRSHIP_GIFT_MULT := 2.0
const TRUCK_IDLE_DEPART := 3.0      # a vehicle leaves this long after its last load

# staff
static func cabin_cap(l: int) -> int: return 3 + (l - 1)
static func hire_cost(hired: int) -> float: return snap_price(40.0 * pow(1.25, hired) * pow(0.93, Game.research("hiring")))
static func worker_speed() -> float: return (3.6 + Game.research("wspeed") * 0.25) * (1.0 + Game.perk("swift") * 0.1)
static func worker_carry() -> int: return 8 + Game.research("wcarry") * 2
static func chef_boost(n: int) -> float: return 1.0 + 0.5 * n   # speed multiplier with n chefs

# obstacles
static func obstacle_cost(cleared: int) -> float: return snap_price(20.0 * pow(1.35, cleared))

# ---------------------------------------------------------------- research
## Global upgrades bought in the Research panel. cost = base * growth^level.
const RESEARCH := {
	"tools": {"name": "Builder's Toolkit", "icon": "hammer", "base": 300, "growth": 2.1, "max": 12, "desc": "Building and upgrading take 5% less time"},
	"recipe": {"name": "Secret Recipes", "icon": "recipe", "base": 200, "growth": 1.72, "max": 40, "desc": "Every cookie sells for 10% more"},
	"wspeed": {"name": "Porter Boots", "icon": "speed", "base": 120, "growth": 1.7, "max": 25, "desc": "Porters walk faster"},
	"wcarry": {"name": "Porter Baskets", "icon": "porter", "base": 150, "growth": 1.72, "max": 25, "desc": "Porters carry 2 more items"},
	"hiring": {"name": "Good Reputation", "icon": "hire", "base": 400, "growth": 1.9, "max": 15, "desc": "Hiring costs 7% less"},
	"vehicles": {"name": "Better Roads", "icon": "truck", "base": 600, "growth": 1.85, "max": 20, "desc": "Vans, trains and airships return 5% sooner"},
	"market": {"name": "Marketing", "icon": "price", "base": 2000, "growth": 2.0, "max": 10, "desc": "Trending cookies sell for 10% more"},
	"offline": {"name": "Night Shift", "icon": "clock", "base": 1500, "growth": 2.1, "max": 22, "desc": "Earn offline for 1 more hour"},
	"rush": {"name": "Rush Hour", "icon": "boost", "base": 800, "growth": 1.9, "max": 15, "desc": "Cookie Rush lasts 5 s longer"},
	"land": {"name": "Land Surveyor", "icon": "land", "base": 1200, "growth": 2.0, "max": 12, "desc": "Land costs 6% less"},
}
const RESEARCH_ORDER: Array[String] = ["recipe", "wspeed", "wcarry", "tools", "hiring", "vehicles", "market", "rush", "offline", "land"]


static func research_cost(id: String, l: int) -> float:
	var d: Dictionary = RESEARCH[id]
	return snap_price(float(d["base"]) * pow(float(d["growth"]), l))


## Gem perks (gems come from special orders).
const PERKS := {
	"golden": {"name": "Golden Touch", "icon": "coin", "base": 3, "growth": 1.6, "max": 15, "desc": "All cookies sell for 10% more"},
	"fertile": {"name": "Fertile Soil", "icon": "farm", "base": 3, "growth": 1.6, "max": 15, "desc": "Farms work 10% faster"},
	"swift": {"name": "Swift Staff", "icon": "speed", "base": 3, "growth": 1.6, "max": 10, "desc": "Workers move 10% faster"},
	"bigbatch": {"name": "Big Batches", "icon": "oven", "base": 5, "growth": 1.7, "max": 10, "desc": "Every oven bakes 1 more cookie per batch"},
	"orders": {"name": "Busy Board", "icon": "board", "base": 8, "growth": 2.5, "max": 2, "desc": "One more order slot"},
	"rush": {"name": "Second Wind", "icon": "boost", "base": 4, "growth": 1.8, "max": 8, "desc": "Cookie Rush recharges 15% sooner"},
}
const PERK_ORDER: Array[String] = ["golden", "fertile", "swift", "bigbatch", "orders", "rush"]


static func perk_cost(id: String, l: int) -> int:
	var d: Dictionary = PERKS[id]
	return int(round(float(d["base"]) * pow(float(d["growth"]), l)))

# ---------------------------------------------------------------- prices

## Base sale price of an item (before channel multipliers).
static func item_value(t: String) -> float:
	var c := Defs.cat(t)
	if c == "raw" or c == "proc":
		return 0.0
	var r := Defs.recipe(Defs.recipe_of(t))
	var v: float = float(r.get("price", 1.0)) * price_mult()
	if Game.trending == Defs.recipe_of(t):
		v *= 1.5 + 0.1 * Game.research("market")
	match c:
		"box": v *= BOX_SIZE * BOX_MULT
		"gift": v *= BOX_SIZE * BOX_MULT * GIFT_MULT
	return v


static func price_mult() -> float:
	return pow(1.1, Game.research("recipe")) * (1.0 + 0.1 * Game.perk("golden")) * (1.0 + 0.05 * Game.count_of("statue"))

# ---------------------------------------------------------------- land
const CHUNK := 8                    # cells per land chunk side
static func land_cost(bought: int) -> float:
	return snap_price(120.0 * pow(1.68, bought) * pow(0.94, Game.research("land")))

# ---------------------------------------------------------------- orders
const ORDER_SLOTS := 2
static func order_count(price: float) -> int:
	# cheaper cookies come in bigger orders
	return clampi(int(round(90.0 / sqrt(maxf(price, 1.0)))), 6, 40)

# ---------------------------------------------------------------- misc
const OFFLINE_FACTOR := 0.35
static func offline_cap_hours() -> float: return 2.0 + Game.research("offline")
static func rush_duration() -> float: return 45.0 + Game.research("rush") * 5.0
static func rush_cooldown() -> float: return 300.0 * pow(0.85, Game.perk("rush"))
const TREND_PERIOD := 900.0         # a new trending cookie every 15 minutes
