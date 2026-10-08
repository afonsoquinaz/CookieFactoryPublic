class_name Bot
extends Node
## Autopilot that plays the real game: drives the player with the joystick
## input, builds pads, hires and assigns workers, buys upgrades. Used for
## headless playtests / balance runs:
##   godot --headless --path . res://main.tscn -- --fresh --bot --speed=4 --minutes=20

var world: World
var minutes := 20.0
var _t := 0.0
var _report := 0.0
var _target: Vector3
var _goal := ""
var _think := 0.0
var _log := []
var _first := {}


func _ready() -> void:
	var a := Shot.args()
	minutes = float(a.get("minutes", "20"))
	Engine.time_scale = float(a.get("speed", "4"))
	Engine.physics_ticks_per_second = 60
	Game.no_save = true


func _physics_process(dt: float) -> void:
	_t += dt
	_think -= dt
	if _think <= 0.0:
		_think = 0.25
		_decide()
		_manage()
	var p := world.player
	var next := _target
	if world.nav_ready:
		var path := NavigationServer3D.map_get_path(world.get_world_3d().navigation_map, p.global_position, _target, true)
		for q in path:
			if Vector2(q.x - p.global_position.x, q.z - p.global_position.z).length() > 0.35:
				next = q
				break
	var to := next - p.global_position
	if (_target - p.global_position).length() < 0.3:
		to = Vector3.ZERO
	to.y = 0
	if to.length() > 0.25:
		Player.joy = Vector2(to.x, to.z).normalized()
	else:
		Player.joy = Vector2.ZERO
	_report -= dt
	if _report <= 0.0:
		_report = 60.0
		_print_status()
	_milestones()
	if _t > minutes * 60.0:
		_print_status()
		print("BOT DONE ", JSON.stringify(_first))
		get_tree().quit()


func _milestones() -> void:
	var checks := {
		"first_cookie": int(Game.stats["batches"]) > 0,
		"first_sale": int(Game.stats["cookies"]) > 0,
		"cabin": Game.has_building("cabin"),
		"first_worker": Game.workers.size() > 0,
		"pantry": Game.has_building("pantry"),
		"shelf": Game.has_building("shelf"),
		"dock2": Game.has_building("dock2"),
		"line2": Game.has_building("line2"),
		"level5": Game.level >= 5,
		"level10": Game.level >= 10,
	}
	for k in checks:
		if checks[k] and not _first.has(k):
			_first[k] = int(_t)
			print("[%5.0fs] milestone %s  money=%d level=%d" % [_t, k, Game.money, Game.level])


func _print_status() -> void:
	var roles := {}
	for w in Game.workers:
		roles[w["role"]] = roles.get(w["role"], 0) + 1
	print("[%5.0fs] $%d lvl %d xp %d/%d cookies %d batches %d workers %s goal=%s ups=%s" % [_t, Game.money, Game.level, Game.xp,
		Bal.xp_needed(Game.level), int(Game.stats["cookies"]), int(Game.stats["batches"]), JSON.stringify(roles), _goal, _ups()])
	if _goal == "idle" or Shot.args().has("dump"):
		_dump()


func _dump() -> void:
	for l in world.lines:
		var ds := []
		for d in l.doughs:
			ds.append("%.1f/%d/%.2f" % [d["x"], d["stage"], d["wait"]])
		var hs := []
		for ing in Defs.INGREDIENTS:
			hs.append("%s=%d/%d" % [ing, l.hoppers[ing].count(), l.hoppers[ing].capacity])
		print("   line%d doughs=%s oven_q=%d tray=%d/%d inc=%d hop=%s" % [l.index, ds, l._oven_queue, l.tray.count(), l.tray.capacity, l.tray.incoming, hs])
	var fs := []
	for ing in world.farms:
		var f: Farm = world.farms[ing]
		var st := []
		for fw in f.farmers:
			st.append(fw.state)
		fs.append("%s=%d/%d %s" % [ing, f.crate.count(), f.crate.capacity, st])
	print("   farms ", fs, " carry=", world.player.carry.items, " pos=", world.player.global_position)
	if world.pantry:
		var ps := []
		for ing in Defs.INGREDIENTS:
			ps.append(world.pantry.bins[ing].count())
		print("   pantry ", ps)
	for w in world.workers.values():
		print("   worker ", w.role, " state=", w.state, " carry=", w.carry.items, " pos=", w.global_position)


func _ups() -> String:
	var s := []
	for id in Bal.all_upgrade_ids():
		var l := Game.lvl(id)
		if l > (1 if id.begins_with("farm_") else 0):
			s.append("%s%d" % [id.replace("farm_", "f_"), l])
	return ",".join(s)


func _decide() -> void:
	var p := world.player
	var c := p.carry
	# 1. pay for a pad we can afford
	for id in world.pads:
		var pad: BuildPad = world.pads[id]
		var left := pad.zone.price - pad.zone.paid
		if pad.zone.enabled and Game.money >= left:
			_go(pad.global_position, "build " + id)
			return
	# 2. deliver cookies
	if c.count_of("cookie") > 0:
		var d := world.parked_dock()
		if d:
			_go(d.zone.global_position, "truck")
			return
		if world.shelf and world.shelf.bins["cookie"].space() > 0:
			_go(world.shelf.give_zone.global_position, "shelf")
			return
	# 3. pick up cookies if a tray has plenty (or carrying nothing else)
	var tz := world.fullest_tray_zone()
	if tz and c.space() > 0 and (tz.holders[0].count() >= 6 or c.count() == 0) and Game.workers_with("collector") == 0:
		_go(tz.global_position, "tray")
		return
	# 4. carrying ingredients: put them in the emptiest matching hopper
	for i in range(c.items.size() - 1, -1, -1):
		var t := c.items[i]
		if t == "cookie":
			continue
		var hz := world.neediest_hopper_zone(t)
		if hz and hz.holders[0].space() > 0 and (c.space() == 0 or _no_more_to_collect()):
			_go(hz.global_position, "hopper " + t)
			return
	# 5. collect ingredients: the one the line needs most that a farm has
	if c.space() > 0:
		var best := ""
		var best_need := -1.0
		for ing in Defs.INGREDIENTS:
			var f: Farm = world.farms[ing]
			if f.crate.count() == 0:
				continue
			var have := c.count_of(ing)
			var need := 0.0
			for l in world.lines:
				need += float(l.hoppers[ing].space())
			need -= have * 1.0
			if need > best_need:
				best_need = need
				best = ing
		if best != "" and best_need > 0:
			_go(world.farms[best].zone.global_position, "farm " + best)
			return
	# 6. anything left in hand goes into hoppers
	for t2 in c.items:
		if t2 != "cookie":
			var hz2 := world.neediest_hopper_zone(t2)
			if hz2 and hz2.holders[0].space() > 0:
				_go(hz2.global_position, "hopper " + t2)
				return
	if tz:
		_go(tz.global_position, "tray (idle)")
		return
	_go(Lay.PLAYER_START, "idle")


func _no_more_to_collect() -> bool:
	for ing in Defs.INGREDIENTS:
		if world.farms[ing].crate.count() > 0 and world.player.carry.count_of(ing) < 2:
			return false
	return true


func _go(p: Vector3, goal: String) -> void:
	_target = p
	_goal = goal


## Workers + upgrades through the same Game API the UI uses.
func _manage() -> void:
	# keep some money for the next pad
	var reserve := 0
	for id in world.pads:
		var pad: BuildPad = world.pads[id]
		var left := pad.zone.price - pad.zone.paid
		if pad.zone.enabled and left < Game.money * 3:
			reserve = maxi(reserve, int(left * 0.6))
	if Game.can_hire() and Game.money - Game.hire_price() > reserve and Game.idle_workers() == 0:
		Game.hire()
	for w in Game.workers:
		if w["role"] == "":
			var r := _next_role()
			Game.assign(int(w["id"]), r, _farm_target() if r == "farmer" else "")
	# cheapest affordable upgrade
	var cheapest := ""
	var cost := 1 << 40
	for id in Bal.all_upgrade_ids():
		if not Game.upgrade_available(id) or Game.upgrade_maxed(id):
			continue
		var c := Game.upgrade_cost(id)
		if c < cost:
			cost = c
			cheapest = id
	if cheapest != "" and Game.money - cost >= reserve:
		Game.buy_upgrade(cheapest)


func _next_role() -> String:
	var want := ["farmer", "gatherer", "feeder", "collector", "loader"]
	var best := "farmer"
	var best_n := 999
	for r in want:
		if not Game.role_unlocked(r):
			continue
		var n := Game.workers_with(r)
		if r == "farmer":
			n = n / 2
		if n < best_n:
			best_n = n
			best = r
	return best


func _farm_target() -> String:
	var best := "wheat"
	var n := 999
	for ing in Defs.INGREDIENTS:
		var c := Game.workers_with("farmer", ing)
		if c < n:
			n = c
			best = ing
	return best
