class_name Bal
## Every number in the game: building effects per level, prices, build and
## upgrade times, research, spark perks, land. Tuned for a long game (about two
## weeks to finish the AGI Megacluster; see tools/pacing.py). Timers do
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
		"source": g = 1.28
		"server": g = 1.32
		"lab": g = 1.3
		"pack": g = 1.32
		"sell": g = 1.32
		"staff": g = 1.6
	return snap_price(float(d["up"]) * pow(g, l - 1))


## Seconds to build a new copy when you already own `owned` of this kind.
static func build_time(kind: String, owned: int) -> float:
	var t := float(Defs.BUILDINGS[kind].get("time", 0))
	if t <= 0.0:
		return 0.0
	return minf(t * pow(2.0, owned), 4.0 * 3600.0) * tool_mult() * Live.time_mult()


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
	return roundf(t0 * pow(top / t0, pow(f, 0.75))) * tool_mult() * Live.time_mult()


static func tool_mult() -> float:
	return pow(0.95, Game.research("tools"))


## Sparks to finish a job right now. Short jobs (30 s or less) are free.
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
		"source": return Defs.SOURCE_TIERS
		"server": return Defs.SERVER_TIERS
	return Defs.MACHINE_TIERS


## Prices are rounded to friendly numbers.
static func snap_price(v: float) -> float:
	if v < 100.0:
		return roundf(v)
	var mag := pow(10.0, floorf(log(v) / log(10.0)) - 1.0)
	return roundf(v / mag) * mag

# sources
static func src_work_time(l: int) -> float: return maxf(0.25, 1.3 * pow(0.94, l - 1))
static func src_regrow(l: int) -> float: return maxf(1.0, 6.0 * pow(0.95, l - 1))
static func src_yield(l: int) -> int: return 1 + (l - 1) / 6
static func src_crate_cap(l: int) -> int: return 10 + (l - 1) * 3
static func src_walk_speed(l: int) -> float: return 2.2 + (l - 1) * 0.05
const MAX_TECHS := 4            # hired technicians per source (plus the one it comes with)
const BIOME_BONUS := 0.4        # sources on their favourite land work this much faster

# ---------------------------------------------------------------- inference (DESIGN.md)
## A server's accelerators: the garage card it comes with, plus the GPUs
## couriers slot in. Amounts of tokens are in thousands (K).
const GARAGE_VRAM := 12.0           # GB on the garage card
const GPU_VRAM := 80.0              # GB per data-centre GPU
const HBM_VRAM := 40.0              # GB per HBM stack
static func gpu_slots(l: int) -> int: return mini(20, 1 + (l - 1) / 2)
static func hbm_slots(l: int) -> int: return mini(12, (l - 1) / 3)
static func garage_accel(l: int) -> float: return 0.5 * pow(1.12, mini(l, 12) - 1)
## Kernels, batching and caching get better with every server level.
static func server_eff(l: int) -> float: return (1.0 + 0.08 * (l - 1)) * (1.0 + 0.06 * Game.research("kv")) * (1.0 + 0.05 * Game.perk("bigbatch"))
static func power_cap(l: int) -> int: return 12 + (l - 1) * 3
static func coolant_cap(l: int) -> int: return 10 + (l - 1) * 3
const POWER_PER_ACCEL := 1.0 / 15.0 # power cells per accelerator-second at full load
const COOLANT_PER_GPU := 1.0 / 25.0 # coolant per GPU-second at full load
const THROTTLE := 0.6               # throughput without coolant (GPUs only)
const GPU_FAIL := 1.0 / 10800.0     # failures per GPU-second at full load (one per ~3 h)
## Tuning: engineers and your taps; up to +50%, fading slowly.
const TUNE_BONUS := 0.5
const TUNE_ENGINEER := 0.05
const TUNE_PLAYER := 0.1
const TUNE_DECAY := 0.004           # per second
static func tune_mult() -> float: return 1.0 + 0.1 * Game.research("tuning")

# ---------------------------------------------------------------- market (DESIGN.md)
## AI adoption: every Lab level, the whole market grows.
static func adoption(level: int) -> float: return pow(1.32, level - 1)
const ORGANIC := 1.0                # demand with no channels at all
static func gateway_demand(l: int) -> float: return 0.6 + 0.08 * (l - 1)
static func gateway_bw(l: int, fiber: int) -> float: return 2.0 * pow(1.25, l - 1) + 3.0 * fiber
static func fiber_slots(l: int) -> int: return mini(30, 2 + (l - 1))
const GARAGE_BW := 1.0              # K tokens/s with no gateway at all
static func edge_demand(l: int) -> float: return 0.25 * (1.0 + 0.1 * (l - 1))
const EDGE_MS := 25.0
static func hub_demand(l: int) -> float: return 0.3 * pow(1.08, l - 1)
const AGENT_PRICE := 2.0
const CONTRACT_PRICE := 1.2
const CONTRACT_SECONDS := 900.0     # contracts send their tokens over about 15 minutes
const ELASTICITY := 1.6             # demand x price^-1.6
const ORBIT_MS := 80.0
const ORBIT_ACCELS := 48.0          # accelerators in one orbital module
const ORBIT_VRAM := 24 * 80.0 + 8 * 40.0
static func ground_bw(l: int) -> float: return 30.0 * pow(1.2, l - 1)
static func module_bw() -> float: return 10.0
## Latency rises steeply as servers fill up.
static func latency(base: float, util: float, edges: int, orbit_share: float) -> float:
	return maxf(5.0, base * (1.0 + 3.0 * pow(clampf(util, 0.0, 1.0), 3.0)) - EDGE_MS * edges * (1.0 - orbit_share) + ORBIT_MS * orbit_share) * pow(0.92, Game.research("spec"))
static func latency_factor(ms: float) -> float: return clampf(1.25 - ms / 800.0, 0.3, 1.2)
static func demand_mult() -> float: return (1.0 + 0.08 * Game.research("devrel"))
## A model's token price ($ per K) before channel multipliers and your price setting.
static func token_price(rid: String) -> float:
	var v := float(Defs.recipe(rid).get("price", 1.0)) * price_mult() * Live.price_mult(rid)
	if Game.trending == rid:
		v *= 1.5 + 0.1 * Game.research("market")
	return v
const OPEN_PRICE_GROWTH := 1.0      # open-weight licences cost what they say

# training
static func trainer_accel(l: int) -> float: return 2.0 * (1.0 + 0.1 * (l - 1))
static func trainer_gpu_slots(l: int) -> int: return mini(24, 2 + (l - 1) / 2)
static func trainer_in_cap(l: int) -> int: return 40 + (l - 1) * 15
const REFRESH_Q := 0.25             # a refresh run raises a model's quality this much
const Q_START := 1.0
const Q_FLOOR := 0.7
const Q_MAX := 1.5
const Q_DECAY := 0.02 / 3600.0      # quality lost per second (toward the floor) as rivals ship

# staff housed without any cabin
const BASE_STAFF := 1

# labs
static func craft_time(kind: String, l: int) -> float: return maxf(0.5, float(Defs.BUILDINGS[kind]["craft"]) * pow(0.95, l - 1))
static func machine_in_cap(l: int) -> int: return 10 + (l - 1) * 3
static func machine_out_cap(l: int) -> int: return 10 + (l - 1) * 3

# storage
static func depot_cap(l: int) -> int: return 40 + (l - 1) * 15

# the Chat Café: visitors chat live with a fast model
static func cafe_rate(l: int) -> float: return 10.0 * pow(1.07, l - 1)        # visitors / minute
static func cafe_seats(l: int) -> int: return mini(8, 4 + (l - 1) / 4)
## K tokens/s a chatting visitor reads (grows as chat gets richer with the Lab level).
static func cafe_chat(level: int) -> float: return 0.05 * pow(1.5, level - 1)
const CAFE_MULT := 1.3
const SNAPPY_MS := 160.0            # models faster than this earn a latency bonus at the Chat Café
const SNAPPY_BONUS := 0.25          # ... up to +25% for an instant model

# staff
static func dorm_cap(l: int) -> int: return 3 + (l - 1)
static func hire_cost(hired: int) -> float: return snap_price(40.0 * pow(1.25, hired) * pow(0.93, Game.research("hiring")))
static func worker_speed() -> float: return (3.6 + Game.research("wspeed") * 0.25) * (1.0 + Game.perk("swift") * 0.1)
static func worker_carry() -> int: return 8 + Game.research("wcarry") * 2
static func engineer_boost(n: int) -> float: return 1.0 + 0.5 * n   # lab speed multiplier with n engineers

# obstacles
static func obstacle_cost(cleared: int) -> float: return snap_price(20.0 * pow(1.35, cleared))

# ---------------------------------------------------------------- research
## Global upgrades bought in the Research panel. cost = base * growth^level.
const RESEARCH := {
	"tools": {"name": "Prefab Modules", "icon": "hammer", "base": 300, "growth": 2.1, "max": 12, "desc": "Building and upgrading take 5% less time"},
	"recipe": {"name": "Scaling Laws", "icon": "recipe", "base": 200, "growth": 1.72, "max": 40, "desc": "Smarter models: every token sells for 10% more"},
	"wspeed": {"name": "E-Scooters", "icon": "speed", "base": 120, "growth": 1.7, "max": 25, "desc": "Couriers move faster"},
	"wcarry": {"name": "Cargo Carts", "icon": "courier", "base": 150, "growth": 1.72, "max": 25, "desc": "Couriers carry 2 more items"},
	"hiring": {"name": "Employer Brand", "icon": "hire", "base": 400, "growth": 1.9, "max": 15, "desc": "Hiring costs 7% less"},
	"kv": {"name": "KV Cache", "icon": "server", "base": 500, "growth": 1.8, "max": 25, "desc": "Every server serves 6% more tokens"},
	"spec": {"name": "Speculative Decoding", "icon": "speed", "base": 900, "growth": 1.9, "max": 12, "desc": "Answers come 8% faster: lower latency, more demand"},
	"devrel": {"name": "Developer Relations", "icon": "gateway", "base": 700, "growth": 1.85, "max": 20, "desc": "8% more customers for every model"},
	"tuning": {"name": "Profiling Tools", "icon": "engineer", "base": 1000, "growth": 1.9, "max": 15, "desc": "Every tune (engineers' and yours) counts 10% more"},
	"market": {"name": "Hype Machine", "icon": "price", "base": 2000, "growth": 2.0, "max": 10, "desc": "Trending models sell for 10% more"},
	"offline": {"name": "Autoscaling", "icon": "clock", "base": 1500, "growth": 2.1, "max": 22, "desc": "Earn offline for 1 more hour"},
	"rush": {"name": "Overclocking", "icon": "boost", "base": 800, "growth": 1.9, "max": 15, "desc": "Overclock lasts 5 s longer"},
	"land": {"name": "Zoning Permits", "icon": "land", "base": 1200, "growth": 2.0, "max": 12, "desc": "Land costs 6% less"},
}
const RESEARCH_ORDER: Array[String] = ["recipe", "kv", "devrel", "wspeed", "wcarry", "tools", "spec", "tuning", "hiring", "market", "rush", "offline", "land"]


static func research_cost(id: String, l: int) -> float:
	var d: Dictionary = RESEARCH[id]
	return snap_price(float(d["base"]) * pow(float(d["growth"]), l))


## Spark perks (sparks come from enterprise contracts).
const PERKS := {
	"golden": {"name": "Brand Moat", "icon": "coin", "base": 3, "growth": 1.6, "max": 15, "desc": "All tokens sell for 10% more"},
	"fertile": {"name": "Supply Deals", "icon": "src_power", "base": 3, "growth": 1.6, "max": 15, "desc": "Sources work 10% faster"},
	"swift": {"name": "Team Spirit", "icon": "speed", "base": 3, "growth": 1.6, "max": 10, "desc": "Staff move 10% faster"},
	"bigbatch": {"name": "Continuous Batching", "icon": "gpu", "base": 5, "growth": 1.7, "max": 10, "desc": "Every server serves 5% more tokens"},
	"orders": {"name": "Sales Team", "icon": "desk", "base": 8, "growth": 2.5, "max": 2, "desc": "One more contract slot"},
	"rush": {"name": "Liquid Cooling", "icon": "boost", "base": 4, "growth": 1.8, "max": 8, "desc": "Overclock recharges 15% sooner"},
}
const PERK_ORDER: Array[String] = ["golden", "fertile", "swift", "bigbatch", "orders", "rush"]


static func perk_cost(id: String, l: int) -> int:
	var d: Dictionary = PERKS[id]
	return int(round(float(d["base"]) * pow(float(d["growth"]), l)))

# ---------------------------------------------------------------- prices

## Chat Café bonus for a snappy model (people chat live, so latency sells).
static func latency_bonus(rid: String) -> float:
	var lat := float(Defs.recipe(rid).get("lat", 999))
	return SNAPPY_BONUS * clampf((SNAPPY_MS - lat) / SNAPPY_MS, 0.0, 1.0)


static func price_mult() -> float:
	return pow(1.1, Game.research("recipe")) * (1.0 + 0.1 * Game.perk("golden")) * (1.0 + 0.05 * Game.count_of("gpu_statue"))

# ---------------------------------------------------------------- land
const CHUNK := 8                    # cells per land chunk side
static func land_cost(bought: int) -> float:
	return snap_price(120.0 * pow(1.68, bought) * pow(0.94, Game.research("land")))

# ---------------------------------------------------------------- orders
const ORDER_SLOTS := 2
## K tokens an enterprise contract wants: about 15 minutes of its market.
static func order_count(rid: String) -> float:
	var r := Defs.recipe(rid)
	return LiveDefs.snap(maxf(20.0, float(r.get("demand", 0.3)) * adoption(Game.level) * 0.6 * CONTRACT_SECONDS))

# ---------------------------------------------------------------- misc
const OFFLINE_FACTOR := 0.35
static func offline_cap_hours() -> float: return 2.0 + Game.research("offline")
static func rush_duration() -> float: return 45.0 + Game.research("rush") * 5.0
static func rush_cooldown() -> float: return 300.0 * pow(0.85, Game.perk("rush"))
const TREND_PERIOD := 900.0         # a new trending model every 15 minutes
