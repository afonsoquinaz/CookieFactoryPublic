class_name World
extends Node3D
## The world: endless land, every building the player placed, the
## production lines that connect them, the player, workers and the camera.
## Keeps the scene in sync with Game state (placed / moved / sold / upgraded
## buildings, land, workers) and runs the logistics broker workers ask for
## jobs ("which crate has wheat, and who needs it most?").

signal sold(amount: float, count: int, where: Vector3)
signal lines_changed

var grid := Grid.new()
var terrain: Terrain
var actors: Node3D
var bnodes := {}                  # uid -> Building
var lines: Array[Line] = []
var player: Player
var workers := {}                 # id -> Worker
var cam: CameraRig
var sun: DirectionalLight3D
var _decor: Array[Building] = []
var _synced_once := false
var _store_cd := 0.0
var reserved := {}                # holder instance id -> items reserved by workers


func _ready() -> void:
	sun = Env.build(self)
	Quality.changed.connect(_on_quality)
	_on_quality.call_deferred(Quality.level)
	terrain = Terrain.new()
	terrain.world = self
	add_child(terrain)
	actors = Node3D.new()
	actors.name = "Actors"
	add_child(actors)
	for b in Game.buildings:
		_spawn(b)
	grid.rebuild(Game.owned_chunks())
	rebuild_lines()
	player = Player.new()
	actors.add_child(player)
	var ps: Dictionary = Game.player_state
	player.global_position = Vector3(float(ps.get("x", -1.0)), 0, float(ps.get("z", -6.5)))
	cam = CameraRig.new()
	add_child(cam)
	cam.target = player
	cam.snap()
	for t in ps.get("carry", []):
		if player.carry.space() > 0:
			player.carry.add(str(t), false)
	_sync_workers()
	Game.building_added.connect(_on_added)
	Game.building_removed.connect(_on_removed)
	Game.building_moved.connect(_on_moved)
	Game.building_upgraded.connect(_on_upgraded)
	Game.land_bought.connect(_on_land)
	Game.workers_changed.connect(_sync_workers)
	Game.researched.connect(func(_id, _l): _on_research())
	Game.money_changed.connect(func(_v, _d): terrain.refresh_prices())
	# a brand-new empire: a few sheaves are already waiting in the wheat crate
	if int(Game.stats["cookies"]) == 0 and float(Game.stats["earned"]) == 0.0:
		for n in bnodes.values():
			if n is FarmB and (n as FarmB).crate.count() == 0:
				for i in 4:
					(n as FarmB).crate.add("wheat", false)
				break


func _on_quality(lv: int) -> void:
	sun.shadow_enabled = Quality.LEVELS[lv]["shadows"]
	if lv >= 2:
		MeshKit.detail = 0.55


func _process(dt: float) -> void:
	_store_cd -= dt
	if _store_cd <= 0.0:
		_store_cd = 2.0
		store_state()


# ---------------------------------------------------------------- buildings

func _spawn(b: Dictionary) -> Building:
	var n := Building.create(self, b)
	add_child(n)
	bnodes[n.uid] = n
	grid.fill(n.uid, n.cell(), n.size(), n.rot())
	grid._solids[n.uid] = n.world_solids()
	if n.def["cat"] == "decor":
		_decor.append(n)
	return n


func building(uid: int) -> Building:
	return bnodes.get(uid)


func buildings_of(kind: String) -> Array[Building]:
	var out: Array[Building] = []
	for n in bnodes.values():
		if n.kind == kind:
			out.append(n)
	return out


func _on_added(b: Dictionary) -> void:
	var n := _spawn(b)
	grid.set_solids(n.uid, n.world_solids())
	n.appear()
	Sfx.play("upgrade", -4.0)
	if n is LineModule:
		rebuild_lines()
	terrain.mark_dirty()
	_unstick_player.call_deferred()
	_poke_workers()


func _on_removed(uid: int) -> void:
	var n: Building = bnodes.get(uid)
	if n == null:
		return
	bnodes.erase(uid)
	_decor.erase(n)
	grid.clear(uid)
	grid.remove_solids(uid)
	Fx.puff(get_tree().current_scene, n.global_position + Vector3(0, 0.5, 0), Pal.CREAM, 14)
	var was_line := n is LineModule
	n.queue_free()
	if was_line:
		rebuild_lines.call_deferred()
	terrain.mark_dirty()
	_poke_workers()


func _on_moved(uid: int) -> void:
	var n: Building = bnodes.get(uid)
	if n == null:
		return
	n.place_from_data()
	grid.fill(uid, n.cell(), n.size(), n.rot())
	grid.set_solids(uid, n.world_solids())
	n.appear()
	if n is LineModule:
		rebuild_lines()
	terrain.mark_dirty()
	_unstick_player.call_deferred()
	_poke_workers()


func _on_upgraded(uid: int, _lvl: int) -> void:
	var n: Building = bnodes.get(uid)
	if n:
		n.refresh()
		n.bump(0.08)
		Fx.burst(get_tree().current_scene, n.global_position + Vector3(0, 1.6, 0), Pal.GOLD, 10, false)


func _on_land(_c: Vector2i) -> void:
	grid.rebuild(Game.owned_chunks())
	terrain.refresh_land()
	Sfx.play("levelup", -6.0)


func _on_research() -> void:
	player.refresh()
	for w in workers.values():
		w.refresh()


func _poke_workers() -> void:
	for w in workers.values():
		if w.state == Worker.S.WAIT or w.state == Worker.S.REST:
			w.state = Worker.S.DECIDE


## Sum of decor auras of a type around a world point.
func aura(p: Vector3, what: String) -> float:
	var s := 0.0
	for n in _decor:
		var a: Dictionary = n.def.get("aura", {})
		if a.get("what", "") != what:
			continue
		var d := Vector2(n.global_position.x - p.x, n.global_position.z - p.z)
		var r := (float(a["r"]) + 1.5) * Grid.CELL
		if absf(d.x) <= r and absf(d.y) <= r:
			s += float(a["v"])
	return s

# ---------------------------------------------------------------- lines

## Line modules that touch end to end with the same rotation.
func next_module(m: LineModule) -> LineModule:
	var p := m.tube_end() + m.flow_dir() * 0.5
	var n: Building = bnodes.get(grid.at(Grid.cell_of(p)))
	if n is LineModule and n.rot() == m.rot() and n != m:
		var lm := n as LineModule
		if lm.tube_start().distance_to(m.tube_end()) < 0.3:
			return lm
	return null


func prev_module(m: LineModule) -> LineModule:
	var p := m.tube_start() - m.flow_dir() * 0.5
	var n: Building = bnodes.get(grid.at(Grid.cell_of(p)))
	if n is LineModule and n.rot() == m.rot() and n != m:
		var lm := n as LineModule
		if lm.tube_end().distance_to(m.tube_start()) < 0.3:
			return lm
	return null


func rebuild_lines() -> void:
	for l in lines:
		l.queue_free()
	lines.clear()
	var mods: Array[LineModule] = []
	for n in bnodes.values():
		if n is LineModule and not n.is_queued_for_deletion():
			mods.append(n)
			(n as LineModule).line = null
	for m in mods:
		if not m is MixerB:
			continue
		var chain: Array[LineModule] = [m]
		var cur: LineModule = m
		while true:
			var nx := next_module(cur)
			if nx == null or chain.has(nx) or nx is MixerB:
				break
			chain.append(nx)
			cur = nx
			if nx is OvenB:
				break
		if chain.size() >= 2 and chain[chain.size() - 1] is OvenB:
			var l := Line.new()
			l.name = "Line_%d" % m.uid
			l.setup(self, chain)
			add_child(l)
			lines.append(l)
	for m in mods:
		m.set_links(prev_module(m) != null and not m is MixerB, next_module(m) != null and not m is OvenB)
	lines_changed.emit()


# ---------------------------------------------------------------- logistics broker

## Which buildings a role may take from / bring to.
static func role_sources(role: String, n: Building) -> bool:
	match role:
		"gatherer": return n is FarmB
		"feeder": return (n is StorageB and n.kind == "pantry") or (n is MachineB and n.def["cat"] == "kitchen")
		"collector": return n is OvenB
		"loader": return (n is StorageB and n.kind == "rack") or (n is MachineB and n.def["cat"] == "pack")
	return false


func role_dest(role: String, n: Building) -> bool:
	match role:
		"gatherer":
			if n is MachineB and n.def["cat"] == "kitchen":
				return true
			if n is StorageB and n.kind == "pantry":
				return true
			return n is MixerB or n is HopperB
		"feeder":
			return n is MixerB or n is HopperB or (n is MachineB and n.def["cat"] == "kitchen")
		"collector":
			if n is MachineB and n.kind == "packer":
				return true
			if n is StorageB and n.kind == "rack":
				return true
			return n is VehicleB or n is ShopB or n is BoardB or n is PalaceB
		"loader":
			return n is VehicleB or n is ShopB or n is BoardB or n is PalaceB or (n is MachineB and n.kind == "wrapper")
	return false


func available(h: Holder, t: String) -> int:
	return h.count_of(t) - int(reserved.get(h.get_instance_id(), {}).get(t, 0))


func reserve(h: Holder, t: String, n: int) -> void:
	var id := h.get_instance_id()
	if not reserved.has(id):
		reserved[id] = {}
	reserved[id][t] = int(reserved[id].get(t, 0)) + n


func unreserve(h: Holder, t: String, n: int) -> void:
	if h == null or not is_instance_valid(h):
		return
	var id := h.get_instance_id()
	if reserved.has(id):
		reserved[id][t] = maxi(0, int(reserved[id].get(t, 0)) - n)


## How much a role should care about a destination's need: gatherers leave
## the line to feeders and collectors leave sales to loaders, unless it's
## starving or nobody does that job.
func _weigh(role: String, d: Building, nd: float) -> float:
	if role == "gatherer" and (d is MixerB or d is HopperB) and Game.workers_with("feeder") > 0:
		return nd if nd > 0.8 else nd * 0.35
	if role == "collector" and (d is VehicleB or d is ShopB or d is BoardB or d is PalaceB) and Game.workers_with("loader") > 0:
		return nd * 0.3
	return nd


## Best job for a role: {src: Building, src_holder, src_zone, dst: Building, item, count} or {}.
func find_job(role: String, from: Vector3, cap: int) -> Dictionary:
	var best := {}
	var best_score := -INF
	var srcs: Array[Building] = []
	var dsts: Array[Building] = []
	for n in bnodes.values():
		if role_sources(role, n):
			srcs.append(n)
		if role_dest(role, n):
			dsts.append(n)
	if srcs.is_empty() or dsts.is_empty():
		return {}
	for s in srcs:
		for p in s.out_ports():
			var h: Holder = p["holder"]
			if h.count() == 0:
				continue
			var kinds := {}
			for t in h.items:
				kinds[t] = true
			for t in kinds:
				var avail := available(h, t)
				if avail <= 0:
					continue
				for d in dsts:
					if d == s:
						continue
					var nd := _weigh(role, d, d.need(t))
					if nd <= 0.0:
						continue
					var dist_sd := s.global_position.distance_to(d.global_position)
					var dist_w := from.distance_to(s.global_position)
					var score := nd * 3.0 + float(h.count()) / maxf(1.0, h.capacity) - dist_sd / 30.0 - dist_w / 45.0
					if score > best_score:
						best_score = score
						best = {"src": s, "src_holder": h, "src_zone": p["zone"], "dst": d, "item": t, "count": mini(cap, avail)}
	return best


## Best place to deliver an item a worker is already carrying.
func find_dest(role: String, t: String, from: Vector3) -> Building:
	var best: Building = null
	var best_score := -INF
	for n in bnodes.values():
		if not role_dest(role, n):
			continue
		var nd: float = _weigh(role, n, n.need(t))
		if nd <= 0.0:
			continue
		var score := nd * 3.0 - from.distance_to(n.global_position) / 30.0
		if score > best_score:
			best_score = score
			best = n
	if best == null:
		# nobody wants it right now: park it in the nearest storage
		var bd := INF
		for n in bnodes.values():
			if n is StorageB and (n as StorageB).store.can_accept(t):
				var dd := from.distance_to(n.global_position)
				if dd < bd:
					bd = dd
					best = n
	return best


# ---------------------------------------------------------------- workers

func _sync_workers() -> void:
	var seen := {}
	for d in Game.workers:
		var id := int(d["id"])
		if d["role"] == "farmer":
			continue
		seen[id] = true
		if workers.has(id):
			var w: Worker = workers[id]
			if w.role != d["role"] or int(w.data.get("target", 0)) != int(d.get("target", 0)):
				w.data = d
				w.apply_role()
			else:
				w.data = d
		else:
			var w2 := Worker.new()
			w2.setup(self, d)
			actors.add_child(w2)
			var cabins := buildings_of("cabin")
			w2.global_position = cabins[0].to_world(0, 1.2) if not cabins.is_empty() else player.global_position + Vector3(1, 0, 1)
			workers[id] = w2
			if _synced_once:
				w2.greet()
	for id in workers.keys():
		if not seen.has(id):
			var w3: Worker = workers[id]
			Fx.ring(self, w3.global_position, Color(0.42, 0.78, 0.3), 1.5)
			w3.release()
			w3.queue_free()
			workers.erase(id)
	for n in bnodes.values():
		if n is FarmB:
			(n as FarmB).sync_farmers()
	_synced_once = true


## Seat for a resting worker at the nearest cabin.
func rest_seat(w: Worker) -> Vector3:
	var cabins := buildings_of("cabin")
	if cabins.is_empty():
		return player.global_position + Vector3(2, 0, 2)
	var i := 0
	for id in workers:
		if workers[id] == w:
			break
		if workers[id].role == "":
			i += 1
	var c: CabinB = cabins[i / 8 % cabins.size()]
	return c.seat(i % 8)

# ---------------------------------------------------------------- save state

func store_state() -> void:
	for n in bnodes.values():
		n.persist()
	Game.player_state = {"x": player.global_position.x, "z": player.global_position.z, "carry": player.carry.items.duplicate()}


## After something is built where you stand, step out of its walls.
func _unstick_player() -> void:
	await get_tree().physics_frame
	var space := get_world_3d().direct_space_state
	var q := PhysicsShapeQueryParameters3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.4
	cap.height = 1.2
	q.shape = cap
	q.collision_mask = 1
	var start := player.global_position
	for r in [0.0, 0.8, 1.4, 2.0, 2.8, 3.6, 4.6, 6.0]:
		for a in 12:
			var p: Vector3 = start + Vector3(sin(a * TAU / 12.0), 0, cos(a * TAU / 12.0)) * r
			q.transform = Transform3D(Basis.IDENTITY, p + Vector3(0, 0.62, 0))
			if space.intersect_shape(q, 1).is_empty():
				if r > 0.0:
					var tw := player.create_tween()
					tw.tween_property(player, "global_position", p, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
				return
			if r == 0.0:
				break


# ---------------------------------------------------------------- picking

## The building under a world point (on the ground), or null.
func building_at(p: Vector3) -> Building:
	return bnodes.get(grid.at(Grid.cell_of(p)))


# ---------------------------------------------------------------- route preview

var _route: Node3D

## Shows the buildings a role works between, "" hides it.
func show_route(role: String) -> void:
	if _route:
		_route.queue_free()
		_route = null
	if role == "" or not Defs.ROLES.has(role):
		return
	_route = Node3D.new()
	add_child(_route)
	var col: Color = Defs.ROLES[role]["color"]
	var pts := []
	for n in bnodes.values():
		if role_sources(role, n) or role_dest(role, n):
			pts.append(n.global_position)
	for p in pts:
		Fx.ring(_route, p, col, 2.0)
	var tw := _route.create_tween().set_loops()
	tw.tween_interval(0.9)
	tw.tween_callback(func():
		for p2 in pts:
			Fx.ring(_route, p2, col, 2.0))
