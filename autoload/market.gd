extends Node
## The inference market (see DESIGN.md). Tokens aren't things you carry:
## customers call your API, servers answer them as fast as their GPUs allow,
## and every token served is paid on the spot. Four times a second:
##   1. capacity: what the servers loaded with each model can serve (and the
##      orbital datacenter, and its downlink)
##   2. demand per model and channel:
##        api       developers' calls: AI adoption (the Lab level) x channels
##                  (organic + API Gateways + Edge PoPs) x reputation x
##                  quality x your price x latency x trends and events
##        cafe      visitors chatting live at the Chat Café (x1.3)
##        contract  enterprise contracts at the Desk (x1.2, plus a bonus)
##        agent     long agent jobs from the Agent Hub on tool-capable
##                  models (x2)
##   3. serving: each model serves min(demand, capacity), and everything that
##      leaves the campus fits through the gateways' bandwidth; the rest of
##      the demand is lost (and costs reputation)
##   4. money and tokens through Game.serve, load handed back to each server
##      (it burns power and coolant, wears GPUs and draws the traffic), and
##      latency for the next tick.
## Your price per model (0.5x to 2x) trades customers for margin.

signal ticked

const TICK := 0.25
const CHANNELS := ["api", "cafe", "contract", "agent"]

var world                                  # World (it registers itself)
var price := {}                            # model -> your price multiplier
var quality := {}                          # model -> 0.7..1.5
var rep := 0.75                            # reputation 0.2..1
var cap := {}                              # model -> K tokens/s capacity
var demand := {}                           # model -> K tokens/s wanted (all channels)
var served := {}                           # model -> K tokens/s served
var by_channel := {}                       # channel -> {model -> K/s served}
var want := {}                             # channel -> {model -> K/s wanted}
var lat := {}                              # model -> ms
var income := 0.0                          # $/s right now
var bandwidth := 0.0                       # K/s the gateways can carry
var used_bw := 0.0
var unmet := 0.0                           # K/s lost this tick (outside the campus)
var orbit_modules := 0
var orbit_model := ""
var _t := 0.0
var _servers := {}                         # model -> [ServerB]


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func reset_state() -> void:
	price = {}
	quality = {}
	rep = 0.75
	cap = {}
	demand = {}
	served = {}
	by_channel = {}
	want = {}
	lat = {}
	income = 0.0
	orbit_modules = 0
	orbit_model = ""


func _process(dt: float) -> void:
	if world == null or not is_instance_valid(world) or get_tree().paused:
		return
	_t += dt
	var n := 0
	while _t >= TICK and n < 8:
		_t -= TICK
		n += 1
		step(TICK)


# ---------------------------------------------------------------- settings

func price_of(rid: String) -> float:
	return float(price.get(rid, 1.0))


func set_price(rid: String, p: float) -> void:
	price[rid] = clampf(snappedf(p, 0.05), 0.5, 2.0)


func quality_of(rid: String) -> float:
	return float(quality.get(rid, Bal.Q_START))


func refresh(rid: String, amount := Bal.REFRESH_Q) -> void:
	quality[rid] = minf(Bal.Q_MAX, quality_of(rid) + amount)


## $ per K tokens on the API right now (your price included).
func token_price(rid: String) -> float:
	return Bal.token_price(rid) * price_of(rid)


# ---------------------------------------------------------------- demand

## Customers' channels outside the campus: organic + gateways + edge PoPs.
func reach() -> float:
	var r := Bal.ORGANIC
	if world:
		for g in world.buildings_of("gateway"):
			r += Bal.gateway_demand(g.level)
		for e in world.buildings_of("edge"):
			r += Bal.edge_demand(e.level)
	return r * Bal.demand_mult()


func edges() -> int:
	return world.buildings_of("edge").size() if world else 0


## API demand for a model (K tokens/s), before serving.
func api_demand(rid: String) -> float:
	var r := Defs.recipe(rid)
	var d := float(r["demand"]) * Bal.adoption(Game.level) * reach() * (0.5 + rep) * quality_of(rid)
	d *= pow(price_of(rid), -Bal.ELASTICITY)
	d *= Bal.latency_factor(float(lat.get(rid, r["lat"])))
	if Game.trending == rid:
		d *= 2.0
	return d * (1.5 if Live.active_events().has("community") else 1.0)


## Agent Hub demand for a model.
func agent_demand(rid: String) -> float:
	var r := Defs.recipe(rid)
	if not r.get("agent", false) or world == null:
		return 0.0
	var h := 0.0
	for n in world.buildings_of("agent_hub"):
		h += Bal.hub_demand(n.level)
	return float(r["demand"]) * Bal.adoption(Game.level) * h * (0.5 + rep) * quality_of(rid) * pow(price_of(rid), -Bal.ELASTICITY)


## What each channel wants, by model.
func _wants() -> Dictionary:
	var w := {"api": {}, "cafe": {}, "contract": {}, "agent": {}}
	for rid in Game.known_list():
		w["api"][rid] = api_demand(rid)
		var a := agent_demand(rid)
		if a > 0.0:
			w["agent"][rid] = a
	if world:
		for c in world.buildings_of("cafe"):
			var cr: String = c.model()
			if cr != "":
				w["cafe"][cr] = float(w["cafe"].get(cr, 0.0)) + c.chat_demand()
	for o in Game.orders:
		var left := float(o["count"]) - float(o["got"])
		if left > 0.0:
			var rid2: String = o["model"]
			w["contract"][rid2] = float(w["contract"].get(rid2, 0.0)) + maxf(left / Bal.CONTRACT_SECONDS, minf(left, 0.05))
	return w


# ---------------------------------------------------------------- the tick

func step(dt: float) -> void:
	# 1. capacity
	cap = {}
	_servers = {}
	var orbit_cap := orbit_capacity()
	for n in world.bnodes.values():
		if n is ServerB and not n is SiteB:
			var s := n as ServerB
			var c := s.capacity()
			if c <= 0.0:
				s.set_load(0.0)
				continue
			cap[s.recipe] = float(cap.get(s.recipe, 0.0)) + c
			if not _servers.has(s.recipe):
				_servers[s.recipe] = []
			_servers[s.recipe].append(s)
	if orbit_cap > 0.0 and orbit_model != "":
		cap[orbit_model] = float(cap.get(orbit_model, 0.0)) + orbit_cap
	# 2. demand
	want = _wants()
	demand = {}
	for ch in CHANNELS:
		for rid in want[ch]:
			demand[rid] = float(demand.get(rid, 0.0)) + float(want[ch][rid])
	# 3. serving: min(demand, capacity) per model, then bandwidth for what leaves campus
	served = {}
	by_channel = {"api": {}, "cafe": {}, "contract": {}, "agent": {}}
	var outbound := 0.0
	for rid in demand:
		var d := float(demand[rid])
		var s2 := minf(d, float(cap.get(rid, 0.0)))
		served[rid] = s2
		var f := s2 / d if d > 0.0 else 0.0
		for ch in CHANNELS:
			var x := float(want[ch].get(rid, 0.0)) * f
			if x > 0.0:
				by_channel[ch][rid] = x
				if ch != "cafe":
					outbound += x
	bandwidth = total_bandwidth()
	var bw_f := 1.0 if outbound <= bandwidth or outbound <= 0.0 else bandwidth / outbound
	used_bw = minf(outbound, bandwidth)
	if bw_f < 1.0:
		for ch in ["api", "contract", "agent"]:
			for rid in by_channel[ch]:
				var cut: float = by_channel[ch][rid] * (1.0 - bw_f)
				by_channel[ch][rid] = by_channel[ch][rid] * bw_f
				served[rid] = float(served[rid]) - cut
	# 4. money and tokens
	income = 0.0
	var mult := {"api": 1.0, "cafe": Bal.CAFE_MULT, "contract": Bal.CONTRACT_PRICE, "agent": Bal.AGENT_PRICE}
	for ch in CHANNELS:
		for rid in by_channel[ch]:
			var k: float = by_channel[ch][rid]
			var m := k * token_price(rid) * float(mult[ch])
			if ch == "cafe":
				m *= 1.0 + Bal.latency_bonus(rid)
			income += m
			Game.serve(rid, k * dt, m * dt, ch)
	_contracts(dt)
	# load back to each server (power, coolant, wear, traffic), orbit share
	for rid in _servers:
		var total := float(cap.get(rid, 0.0))
		var u := float(served.get(rid, 0.0)) / total if total > 0.0 else 0.0
		for s3 in _servers[rid]:
			s3.set_load(u)
			s3.earned(u * s3.last_cap * token_price(rid) * dt)
	# latency and reputation
	var lost := 0.0
	var wanted := 0.0
	for rid in demand:
		var c2 := float(cap.get(rid, 0.0))
		var u2 := float(served.get(rid, 0.0)) / c2 if c2 > 0.0 else 1.0
		var share := orbit_cap / c2 if c2 > 0.0 and rid == orbit_model else 0.0
		lat[rid] = Bal.latency(float(Defs.recipe(rid)["lat"]), u2, edges(), share)
		if c2 > 0.0:
			var out_d := float(demand[rid]) - float(want["cafe"].get(rid, 0.0))
			wanted += out_d
			lost += maxf(0.0, out_d - (float(served[rid]) - float(by_channel["cafe"].get(rid, 0.0))))
	unmet = lost
	# customers forgive a busy API (they retry), not one that's swamped: at
	# 1x demand reputation heads for 100%, at 5x or more for 40%
	var over := wanted / maxf(0.0001, wanted - lost) if wanted > 0.0 else 1.0
	var target := 1.0 - 0.6 * clampf((over - 1.0) / 4.0, 0.0, 1.0)
	rep = clampf(rep + (target - rep) * dt * 0.004, 0.2, 1.0)
	# models go stale as rivals ship better ones
	for rid in Game.known_list():
		var q := quality_of(rid)
		if q > Bal.Q_FLOOR:
			quality[rid] = maxf(Bal.Q_FLOOR, q - Bal.Q_DECAY * dt)
	ticked.emit()


func _contracts(dt: float) -> void:
	# a model's contract traffic is shared between its open contracts
	var left := {}
	for o in Game.orders:
		left[o["model"]] = float(left.get(o["model"], 0.0)) + maxf(0.0, float(o["count"]) - float(o["got"]))
	for o in Game.orders.duplicate():
		var rid: String = o["model"]
		var got := float(by_channel["contract"].get(rid, 0.0)) * dt
		var l := maxf(0.0, float(o["count"]) - float(o["got"]))
		if got <= 0.0 or l <= 0.0:
			continue
		o["got"] = float(o["got"]) + minf(l, got * l / maxf(0.001, float(left[rid])))
		if float(o["got"]) >= float(o["count"]) - 0.001:
			Game.contract_done(o)


# ---------------------------------------------------------------- bandwidth + orbit

func total_bandwidth() -> float:
	var b := 0.0
	if world:
		for g in world.buildings_of("gateway"):
			b += Bal.gateway_bw(g.level, g.fiber())
	return maxf(Bal.GARAGE_BW, b)


## What the orbital datacenter can serve (K/s), limited by ground stations.
func orbit_capacity() -> float:
	if orbit_modules <= 0 or orbit_model == "":
		return 0.0
	var r := Defs.recipe(orbit_model)
	if r.is_empty():
		return 0.0
	var c := orbit_modules * Bal.ORBIT_ACCELS * float(r["tps"]) * Bal.server_eff(20) * Game.speed_mult()
	return minf(c, downlink())


func downlink() -> float:
	var b := 0.0
	if world:
		for g in world.buildings_of("groundstation"):
			b += Bal.ground_bw(g.level)
	return b


## The best model an orbital module can hold (biggest price that fits).
func best_orbit_model() -> String:
	var best := ""
	var bp := -1.0
	for rid in Game.known_list():
		var r := Defs.recipe(rid)
		if float(r["vram"]) <= Bal.ORBIT_VRAM and float(r["tps"]) * float(r["price"]) > bp:
			bp = float(r["tps"]) * float(r["price"])
			best = rid
	return best


# ---------------------------------------------------------------- for the UI and Auto

## Demand left unserved for a model, without what server `except` serves.
func headroom(rid: String, except: Node = null) -> float:
	var s := float(served.get(rid, 0.0))
	if except and _servers.has(rid) and (_servers[rid] as Array).has(except):
		s -= (except as ServerB).load_now * (except as ServerB).last_cap
	return maxf(0.0, float(demand.get(rid, api_demand(rid))) - s)


func utilisation() -> float:
	var c := 0.0
	var s := 0.0
	for rid in cap:
		c += float(cap[rid])
		s += float(served.get(rid, 0.0))
	return s / c if c > 0.0 else 0.0


func total(d: Dictionary) -> float:
	var t := 0.0
	for k in d:
		t += float(d[k])
	return t


func to_dict() -> Dictionary:
	return {"price": price, "quality": quality, "rep": rep, "orbit": orbit_modules, "orbit_model": orbit_model}


func from_dict(d: Dictionary) -> void:
	reset_state()
	for k in d.get("price", {}):
		price[k] = float(d["price"][k])
	for k in d.get("quality", {}):
		quality[k] = float(d["quality"][k])
	rep = float(d.get("rep", 0.75))
	orbit_modules = int(d.get("orbit", 0))
	orbit_model = str(d.get("orbit_model", ""))
