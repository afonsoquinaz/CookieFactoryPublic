extends Node
## Autopilot that plays the real game for balance runs: walks the player
## through the early carry loop, then plans like a sensible player: farms and
## kitchens for the best recipe it can make, new production lines, staff,
## storage, sales, upgrades, research, land, and finally the Palace.
##   tools/bot.sh [minutes] [speed]
##   godot --headless --path . res://main.tscn -- --fresh --bot --minutes=60 --speed=10

var world: World
var minutes := 20.0
var _t := 0.0
var _report := 0.0
var _think := 0.0
var _target := Vector3.INF
var _path := PackedVector3Array()
var _pi := 0
var _path_cd := 0.0
var _goal := ""
var _first := {}
var _plan_cd := 0.0


func _ready() -> void:
	var a := Shot.args()
	minutes = float(a.get("minutes", "20"))
	Engine.time_scale = float(a.get("speed", "4"))
	Engine.physics_ticks_per_second = 30
	Game.no_save = true


func _physics_process(dt: float) -> void:
	_t += dt
	_think -= dt
	if _think <= 0.0:
		_think = 0.3
		_carry_loop()
	_plan_cd -= dt
	if _plan_cd <= 0.0:
		_plan_cd = 1.0
		_manage()
	_steer(dt)
	_report -= dt
	if _report <= 0.0:
		_report = 300.0 if _t > 1200.0 else 60.0
		_print_status()
	_milestones()
	if _t > minutes * 60.0:
		_print_status()
		print("BOT DONE ", JSON.stringify(_first))
		get_tree().quit()


func _steer(dt: float) -> void:
	var p := world.player
	if _target == Vector3.INF:
		Player.joy = Vector2.ZERO
		return
	_path_cd -= dt
	if _path_cd <= 0.0:
		_path_cd = 1.0
		_path = world.grid.path(p.global_position, _target)
		_pi = 0
	while _pi < _path.size() and Vector2(_path[_pi].x - p.global_position.x, _path[_pi].z - p.global_position.z).length() < 0.35:
		_pi += 1
	var next := _target if _pi >= _path.size() else _path[_pi]
	var to := next - p.global_position
	to.y = 0
	if (_target - p.global_position).length() < 0.3:
		Player.joy = Vector2.ZERO
	elif to.length() > 0.05:
		Player.joy = Vector2(to.x, to.z).normalized()


func _go(z: Zone, why: String) -> void:
	if z == null:
		return
	var p := z.global_position
	if _target.distance_to(p) > 0.3:
		_path_cd = 0.0
	_target = p
	_goal = why


# ---------------------------------------------------------------- the player's own loop

func _carry_loop() -> void:
	var p := world.player
	var c := p.carry
	# stand still once there are enough hands for every job
	if Game.workers_with("gatherer") > 0 and Game.workers_with("collector") > 0 and Game.workers_with("loader") + Game.workers_with("collector") >= 2:
		if c.count() == 0:
			_target = Vector3.INF
			_goal = "supervise"
			return
	# deliver products
	for i in range(c.items.size() - 1, -1, -1):
		var t := c.items[i]
		if Defs.is_product(t):
			var d := world.find_dest("loader", t, p.global_position)
			if d:
				_go(d.in_zone_for(t), "sell")
				return
	# deliver ingredients
	for i in range(c.items.size() - 1, -1, -1):
		var t2 := c.items[i]
		if Defs.is_ingredient(t2):
			var d2 := world.find_dest("feeder", t2, p.global_position)
			if d2 and (c.space() == 0 or _nothing_to_pick(t2)):
				_go(d2.in_zone_for(t2), "feed " + t2)
				return
	# collect cookies from a full-ish tray
	if c.space() > 0:
		for o in world.buildings_of("oven"):
			var oven := o as OvenB
			if oven.tray.count() >= 6 or (oven.tray.count() > 0 and c.count() == 0):
				_go(oven.tray_zone, "tray")
				return
	# collect what the lines need
	if c.space() > 0:
		var job := world.find_job("gatherer", p.global_position, c.space())
		if not job.is_empty():
			_go(job["src_zone"], "farm " + job["item"])
			return
	if c.count() > 0:
		var t3 := c.items[c.items.size() - 1]
		var d3 := world.find_dest("feeder" if Defs.is_ingredient(t3) else "loader", t3, p.global_position)
		if d3:
			_go(d3.in_zone_for(t3), "drop " + t3)
			return
	_goal = "idle"


func _nothing_to_pick(t: String) -> bool:
	for n in world.bnodes.values():
		if n is FarmB and (n as FarmB).ing == t and (n as FarmB).crate.count() > 2:
			return false
	return true


# ---------------------------------------------------------------- planning

func _manage() -> void:
	_palace()
	_staff()
	_upgrade()
	_research()
	if _improve_lines():
		return
	if _ensure_basics():
		return
	if _ensure_line():
		return
	_ensure_producers()


## Best recipe we can bake with the producers we already have.
func _makeable_recipe() -> String:
	var best := "shortbread"
	for r in Defs.RECIPES:
		var ok := true
		for i in r["ings"]:
			if not Game.can_make(i):
				ok = false
		if ok:
			best = r["id"]
	return best


## Turn tubes into hoppers so a line bakes the best recipe we can make.
func _improve_lines() -> bool:
	var target := _makeable_recipe()
	for l in world.lines:
		if _recipe_rank(l.product) >= _recipe_rank(target):
			continue
		var need: Array = []
		for i in Defs.recipe(target)["ings"]:
			var has := false
			for h in l.hoppers:
				if h.ing == i:
					has = true
			if not has:
				need.append(i)
		var tubes: Array[Building] = []
		for m in l.modules:
			if m is TubeB:
				tubes.append(m)
		if tubes.size() < need.size():
			continue
		if not Game.can_afford(Game.price_of("hopper") * need.size()):
			return true
		for i in need.size():
			var tb: Building = tubes[i]
			var c := tb.cell()
			var r := tb.rot()
			Game.remove(tb.uid, true)
			Game.place("hopper", c, r, {"ing": need[i]})
		print("[%5.0fs] line now makes %s" % [_t, target])
		return true
	return false


## The next recipe up from what we can make, if its ingredients are unlocked.
func _next_recipe() -> String:
	var cur := _recipe_rank(_makeable_recipe())
	for i in range(cur + 1, Defs.RECIPES.size()):
		var r: Dictionary = Defs.RECIPES[i]
		if Defs.recipe_level(r["id"]) <= Game.level:
			return r["id"]
	return ""


## The best recipe whose ingredients we can unlock by now.
func _target_recipe() -> String:
	var best := "shortbread"
	for r in Defs.RECIPES:
		if Defs.recipe_level(r["id"]) <= Game.level:
			best = r["id"]
	return best


func _line_products() -> Array:
	var out := []
	for l in world.lines:
		out.append(l.product)
	return out


func _recipe_rank(rid: String) -> int:
	for i in Defs.RECIPES.size():
		if Defs.RECIPES[i]["id"] == rid:
			return i
	return -1


## Build a line for the best reachable recipe, or another copy of the best line.
func _ensure_line() -> bool:
	var target := _makeable_recipe()
	var have := _line_products()
	var best_rank := -1
	for p in have:
		best_rank = maxi(best_rank, _recipe_rank(p))
	var want_new: bool = _recipe_rank(target) > best_rank and Defs.recipe(target)["ings"].size() > 2
	# another line of the best recipe once the economy can carry it
	var copies := have.count(target)
	if not want_new and copies < 1 + Game.level / 5 and world.lines.size() < 2 + Game.level / 3:
		want_new = Game.money > _line_cost(target) * 3.0
	if not want_new:
		return false
	# make sure we can make every ingredient first
	for i in Defs.recipe(target)["ings"]:
		if not Game.can_make(i):
			return false
	var cost := _line_cost(target)
	if not Game.can_afford(cost):
		return want_new and _recipe_rank(target) > best_rank   # save up for it
	var ings: Array = Defs.recipe(target)["ings"]
	var w := 1 + ings.size() + 2
	var spot = _find_spot(Vector2i(w, 2), 0, world.player.global_position, true)
	if spot == null:
		_buy_land()
		return true
	var o: Vector2i = spot
	Game.place("mixer", o, 0)
	var x := 1
	for i in ings:
		Game.place("hopper", o + Vector2i(x, 0), 0, {"ing": i})
		x += 1
	Game.place("oven", o + Vector2i(x, 0), 0)
	print("[%5.0fs] built a line for %s at %s" % [_t, target, o])
	return true


func _line_cost(rid: String) -> float:
	var n: int = Defs.recipe(rid)["ings"].size()
	var c := Game.price_of("mixer") + Game.price_of("oven")
	for i in n:
		c += Bal.build_cost("hopper", Game.count_of("hopper") + i)
	return c


## Farms / kitchens so every ingredient the lines use has a producer, more as lines grow.
func _ensure_producers() -> bool:
	var want := {"wheat": 0}
	for l in world.lines:
		want["wheat"] = int(want["wheat"]) + 1
		for i in l.recipe_ings:
			want[i] = int(want.get(i, 0)) + 1
	# plan one recipe ahead
	var nxt := _next_recipe()
	if nxt != "":
		for i in Defs.recipe(nxt)["ings"]:
			want[i] = maxi(1, int(want.get(i, 0)))
	# kitchen inputs
	for i in want.keys():
		var p := Defs.producer_of(i)
		if p != "" and Defs.BUILDINGS[p].has("in"):
			for j in Defs.BUILDINGS[p]["in"]:
				want[j] = int(want.get(j, 0)) + int(want[i])
	for i in want:
		var p2 := Defs.producer_of(i) if i != "wheat" else "farm_wheat"
		if p2 == "" or not Game.unlocked(p2):
			continue
		var need := ceili(int(want[i]) * (0.75 if Defs.BUILDINGS[p2]["cat"] == "farm" else 0.5))
		if Game.count_of(p2) < maxi(1, need):
			if not Game.can_afford(Game.price_of(p2)):
				return true
			if _place(p2):
				return true
	return false


func _ensure_basics() -> bool:
	var plan := [
		["cabin", 2, 1], ["pantry", 4, 1], ["rack", 6, 1], ["shop", 5, 1], ["board", 6, 1],
		["packer", 9, 1], ["well", 3, 1], ["dock", 7, 2], ["shop", 12, 2], ["train", 14, 1], ["fountain", 10, 1],
		["dock", 16, 3], ["wrapper", 20, 1], ["airship", 30, 1], ["statue", 25, 1], ["train", 26, 2],
	]
	# sales keep up with the lines
	plan.push_front(["dock", 3, maxi(1, (world.lines.size() + 1) / 2)])
	# more cabins as the staff grows
	if Game.workers.size() >= Game.cabin_capacity() and Game.count_of("cabin") > 0:
		plan.push_front(["cabin", 2, Game.count_of("cabin") + 1])
	for e in plan:
		var kind: String = e[0]
		if Game.level >= int(e[1]) and Game.count_of(kind) < int(e[2]) and Game.unlocked(kind):
			if not Game.can_afford(Game.price_of(kind)):
				return Game.price_of(kind) < Game.money * 4.0
			if _place(kind):
				return true
	return false


func _place(kind: String) -> bool:
	var spot = _find_spot(Defs.size_of(kind), 0, world.player.global_position, false)
	if spot == null:
		_buy_land()
		return false
	var b := Game.place(kind, spot, 0)
	if not b.is_empty():
		print("[%5.0fs] built %s" % [_t, kind])
	return not b.is_empty()


## A free spot (with a one-cell clear ring) on owned land, nearest to `near`.
func _find_spot(size: Vector2i, rot: int, near: Vector3, line := false) -> Variant:
	var nc := Grid.cell_of(near)
	var best = null
	var best_d := INF
	var chunks := Game.owned_chunks()
	for ch in chunks:
		for cx in Bal.CHUNK:
			for cy in Bal.CHUNK:
				var o := ch * Bal.CHUNK + Vector2i(cx, cy)
				var d := Vector2(o - nc).length()
				if d >= best_d:
					continue
				if _fits(o, size, rot, line):
					best_d = d
					best = o
	return best


func _fits(o: Vector2i, size: Vector2i, rot: int, line: bool) -> bool:
	var s := Grid.rotated(size, rot)
	var m := 2 if line else 1
	for x in range(-m, s.x + m):
		for y in range(-1, s.y + 1):
			var c := o + Vector2i(x, y)
			var inside := x >= 0 and y >= 0 and x < s.x and y < s.y
			if inside and not Game.owns_cell(c):
				return false
			if world.grid.at(c) != 0:
				return false
	return true


func _buy_land_if_cramped() -> bool:
	return false


func _buy_land() -> void:
	var best := Vector2i.ZERO
	var best_d := INF
	for c in Game.owned_chunks():
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = c + d
			if Game.can_buy_chunk(n) and Vector2(n).length() < best_d:
				best_d = Vector2(n).length()
				best = n
	if best_d < INF and Game.buy_chunk(best):
		print("[%5.0fs] bought land %s for $%s" % [_t, best, Fmt.num(Game.land_price())])


func _staff() -> void:
	if Game.count_of("cabin") == 0:
		return
	var farms := 0
	var machines := 0
	for n in world.bnodes.values():
		if n is FarmB:
			farms += 1
		elif n is MachineB and n.def["cat"] == "kitchen":
			machines += 1
	var lines := maxi(1, world.lines.size())
	var sellers := Game.count_of("rack") + Game.count_of("packer") > 0
	var want := {
		"gatherer": maxf(1.0, farms * 0.5),
		"collector": lines * 1.0,
		"loader": lines * 1.0 if sellers else 0.0,
		"feeder": (lines * 0.7 + machines * 0.5) if Game.count_of("pantry") > 0 or machines > 0 else 0.0,
	}
	var short := 0.0
	for r in want:
		short += maxf(0.0, ceilf(float(want[r])) - Game.workers_with(r))
	var spare := Game.workers_with("farmer") < farms and Game.workers_with("chef") < world.lines.size()
	if (short > Game.idle_workers() or (spare and Game.idle_workers() == 0)) and Game.can_hire() and Game.money > Game.hire_price() * 1.5:
		Game.hire()
	if Game.idle_workers() > 0:
		# the role furthest behind its target
		var best := ""
		var best_r := 1.0
		for r in want:
			if float(want[r]) <= 0.0:
				continue
			var ratio := Game.workers_with(r) / float(want[r])
			if ratio < best_r:
				best_r = ratio
				best = r
		if best != "":
			Game.assign_idle(best)
			return
		# spare hands: farmers on farms, chefs on ovens
		for n in world.bnodes.values():
			if n is OvenB and Game.workers_with("chef", n.uid) < 1:
				Game.assign_idle("chef", n.uid)
				return
		for n2 in world.bnodes.values():
			if n2 is FarmB and Game.workers_with("farmer", n2.uid) < 1:
				Game.assign_idle("farmer", n2.uid)
				return


func _upgrade() -> void:
	var best: Building = null
	var best_c := INF
	for n in world.bnodes.values():
		var b: Building = n
		if b.level >= Bal.max_level(b.kind) or Bal.max_level(b.kind) <= 1:
			continue
		var c := Bal.upgrade_cost(b.kind, b.level)
		# the line's bottlenecks first
		if b is OvenB or b is MixerB:
			c *= 0.6
		if b is FarmB and (b as FarmB).crate.count() < 3:
			c *= 0.7
		if c < best_c:
			best_c = c
			best = b
	if best and Game.money > Bal.upgrade_cost(best.kind, best.level) * 1.5:
		Game.upgrade(best.uid)


func _research() -> void:
	for id in ["recipe", "wcarry", "wspeed", "carry", "vehicles", "market", "hiring", "speed", "offline", "rush", "land"]:
		if not Game.research_maxed(id) and Game.money > Game.research_cost(id) * 3.0:
			Game.buy_research(id)
			return
	for id in Bal.PERK_ORDER:
		Game.buy_perk(id)


func _palace() -> void:
	var ps := world.buildings_of("palace")
	if ps.is_empty():
		if Game.unlocked("palace") and Game.can_afford(Game.price_of("palace")):
			if _place("palace"):
				print("[%5.0fs] PALACE founded" % _t)
		return
	var p := ps[0] as PalaceB
	if p.can_advance():
		p.advance()
		print("[%5.0fs] PALACE stage %d" % [_t, p.stage()])


# ---------------------------------------------------------------- reporting

func _milestones() -> void:
	var checks := {
		"first_cookie": int(Game.stats["batches"]) > 0,
		"first_sale": int(Game.stats["cookies"]) > 0,
		"sugar_cookie": Game.known_recipes.has("sugar"),
		"cabin": Game.count_of("cabin") > 0,
		"first_worker": Game.workers.size() > 0,
		"line2": world.lines.size() >= 2,
		"choc_chip": Game.known_recipes.has("choc"),
		"jam": Game.known_recipes.has("jam"),
		"caramel": Game.known_recipes.has("caramel"),
		"royal": Game.known_recipes.has("royal"),
		"palace": Game.count_of("palace") > 0,
		"won": Game.won,
	}
	for l in [5, 10, 15, 20, 25, 30, 35, 40, 45, 50]:
		checks["level%d" % l] = Game.level >= l
	for k in checks:
		if checks[k] and not _first.has(k):
			_first[k] = int(_t)
			print("[%5.0fs] milestone %s  money=%s level=%d" % [_t, k, Fmt.num(Game.money), Game.level])


func _print_status() -> void:
	var roles := {}
	for w in Game.workers:
		roles[w["role"]] = roles.get(w["role"], 0) + 1
	print("[%5.0fs] $%s  +%s/min  lvl %d  cookies %d  lines %s  bld %d  land %d  workers %s  goal=%s" % [_t, Fmt.num(Game.money),
		Fmt.num(Game.recent_income() * 60.0), Game.level, int(Game.stats["cookies"]), _line_products(), Game.buildings.size(),
		Game.owned_chunks().size(), JSON.stringify(roles), _goal])
	if Shot.args().has("dump"):
		for n in world.bnodes.values():
			var parts := []
			for p in n.ports:
				parts.append("%s%d" % [p["dir"], (p["holder"] as Holder).count()])
			print("   %s L%d %s" % [n.name, n.level, " ".join(parts)])
