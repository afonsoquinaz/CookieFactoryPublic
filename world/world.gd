class_name World
extends Node3D
## The world: endless land, every building, the roads between them, the
## obstacles on your land, staff, builders and the camera. Keeps the scene in
## sync with Game state (placed / built / moved / sold / upgraded buildings,
## builder jobs, land, obstacles, staff) and runs the logistics broker porters
## ask for work ("which crate has wheat, and who needs it most?").

signal sold(amount: float, count: int, where: Vector3)
signal roads_changed

var grid := Grid.new()
var roads := Roads.new()
var terrain: Terrain
var actors: Node3D
var bnodes := {}                  # uid -> Building
var workers := {}                 # id -> Worker
var builders := {}                # hut uid -> Builder
var obst_nodes := {}              # obstacle key -> Node3D
var cam: CameraRig
var sun: DirectionalLight3D
var reserved := {}                # holder instance id -> {item: n} reserved by porters
var _decor: Array[Building] = []
var _scaffolds := {}              # uid -> Node3D (upgrade in progress)
var _synced_once := false
var _store_cd := 0.0
var _roads_dirty := true


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
	grid.rebuild(Game.owned_chunks())
	for b in Game.buildings:
		_spawn(b)
	_sync_obstacles()
	rebuild_roads()
	cam = CameraRig.new()
	add_child(cam)
	cam.world = self
	var h := hall()
	cam.global_position = (h.global_position + Vector3(0, 0, 3)) if h else Vector3.ZERO
	cam.snap()
	_sync_workers()
	_sync_jobs()
	Game.building_added.connect(_on_added)
	Game.building_built.connect(_on_built)
	Game.building_removed.connect(_on_removed)
	Game.building_moved.connect(_on_moved)
	Game.building_upgraded.connect(_on_upgraded)
	Game.land_bought.connect(_on_land)
	Game.obstacles_changed.connect(_on_obstacles)
	Game.workers_changed.connect(_sync_workers)
	Game.jobs_changed.connect(_sync_jobs)
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
	if _roads_dirty:
		rebuild_roads()
	_store_cd -= dt
	if _store_cd <= 0.0:
		_store_cd = 2.0
		store_state()


func hall() -> HallB:
	for n in bnodes.values():
		if n is HallB:
			return n
	return null


# ---------------------------------------------------------------- buildings

func _spawn(b: Dictionary) -> Building:
	var n := Building.create(self, b)
	add_child(n)
	bnodes[n.uid] = n
	grid.fill(n.uid, n.cell(), n.size(), n.rot())
	grid.set_solids(n.uid, n.world_solids())
	if n.def["cat"] == "decor" and not n is SiteB:
		_decor.append(n)
	return n


func building(uid: int) -> Building:
	return bnodes.get(uid)


func buildings_of(kind: String) -> Array[Building]:
	var out: Array[Building] = []
	for n in bnodes.values():
		if n.kind == kind and not n is SiteB:
			out.append(n)
	return out


func _despawn(uid: int) -> Building:
	var n: Building = bnodes.get(uid)
	if n == null:
		return null
	bnodes.erase(uid)
	_decor.erase(n)
	grid.clear(uid)
	grid.remove_solids(uid)
	if _scaffolds.has(uid):
		_scaffolds.erase(uid)
	n.queue_free()
	return n


func _on_added(b: Dictionary) -> void:
	var n := _spawn(b)
	n.appear()
	Sfx.play("upgrade", -4.0)
	terrain.mark_dirty()
	_roads_dirty = true
	_poke_workers()


## A construction finished: the site becomes the real building.
func _on_built(uid: int) -> void:
	var b := Game.building(uid)
	var old := _despawn(uid)
	if b.is_empty():
		return
	var n := _spawn(b)
	if old:
		n.global_position = old.global_position
	n.appear()
	n.celebrate()
	Sfx.play("levelup", -6.0)
	UI3D.pop_text(get_tree().current_scene, n.global_position + Vector3(0, 3.0, 0), "Built!", Color(1.0, 0.9, 0.5), 90)
	_roads_dirty = true
	_poke_workers()


func _on_removed(uid: int) -> void:
	var n := _despawn(uid)
	if n:
		Fx.puff(get_tree().current_scene, n.global_position + Vector3(0, 0.5, 0), Pal.CREAM, 14)
	terrain.mark_dirty()
	_roads_dirty = true
	_poke_workers()


func _on_moved(uid: int) -> void:
	var n: Building = bnodes.get(uid)
	if n == null:
		return
	n.place_from_data()
	grid.fill(uid, n.cell(), n.size(), n.rot())
	grid.set_solids(uid, n.world_solids())
	n.appear()
	terrain.mark_dirty()
	_roads_dirty = true
	_poke_workers()


func _on_upgraded(uid: int, _lvl: int) -> void:
	var n: Building = bnodes.get(uid)
	if n:
		n.refresh()
		n.bump(0.08)
		Fx.burst(get_tree().current_scene, n.global_position + Vector3(0, 2.0, 0), Pal.GOLD, 16, false)
		UI3D.pop_text(get_tree().current_scene, n.global_position + Vector3(0, 3.2, 0), "Level %d!" % n.level if not n is PalaceB else "New stage!", Color(1.0, 0.9, 0.5), 80)
		Sfx.play("upgrade", -2.0)
	_sync_jobs()


func _on_land(_c: Vector2i) -> void:
	grid.rebuild(Game.owned_chunks())
	terrain.refresh_land()
	_roads_dirty = true
	Sfx.play("levelup", -6.0)


func _on_research() -> void:
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


# ---------------------------------------------------------------- obstacles

func _on_obstacles() -> void:
	_sync_obstacles()
	_roads_dirty = true
	terrain.mark_dirty()


func _sync_obstacles() -> void:
	for k in obst_nodes.keys():
		if not Game.obstacles.has(k):
			var n: Node3D = obst_nodes[k]
			Fx.puff(get_tree().current_scene, n.global_position + Vector3(0, 0.6, 0), Color(0.75, 0.68, 0.55), 16)
			Fx.burst(get_tree().current_scene, n.global_position + Vector3(0, 1.0, 0), Pal.LEAF, 10, false)
			n.queue_free()
			obst_nodes.erase(k)
			grid.clear_obstacle(k)
	for k in Game.obstacles:
		if obst_nodes.has(k):
			continue
		var ob: Dictionary = Game.obstacles[k]
		var cells := Game.obstacle_cells(k, ob)
		var sz: Vector2i = Defs.OBSTACLES[ob["kind"]]["size"]
		var n2 := Node3D.new()
		n2.position = Grid.center_of(cells[0], sz, 0)
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(k)
		n2.rotation.y = rng.randf() * TAU
		add_child(n2)
		Mats.inst(MeshKit.cached("obstacle_" + ob["kind"], TownArt.obstacle.bind(ob["kind"])), n2)
		obst_nodes[k] = n2
		grid.set_obstacle(k, cells)


## The obstacle key under a world point ("" if none).
func obstacle_at(p: Vector3) -> String:
	return grid.obstacle_at(Grid.cell_of(p))


# ---------------------------------------------------------------- roads

func rebuild_roads() -> void:
	_roads_dirty = false
	var h := hall()
	var entries := []
	var hc := Vector2i.ZERO
	if h:
		var hcells := h.entrance_cells()
		hc = hcells[0]
		entries.append({"uid": h.uid, "cells": hcells, "stub": Building.stub_dir(h.rot()), "d": 0})
	for n in bnodes.values():
		if n == h or not n.has_entrance():
			continue
		var ec: Array[Vector2i] = n.entrance_cells()
		entries.append({"uid": n.uid, "cells": ec, "stub": Building.stub_dir(n.rot()), "d": absi(ec[0].x - hc.x) + absi(ec[0].y - hc.y)})
	roads.build(entries, func(c): return grid.blocked(c), func(c): return Game.owns_cell(c), _owned_bounds())
	terrain.set_roads(roads.cells)
	roads_changed.emit()


func _owned_bounds() -> Rect2i:
	var mn := Vector2i(1 << 20, 1 << 20)
	var mx := Vector2i(-(1 << 20), -(1 << 20))
	for c in Game.owned_chunks():
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	if mn.x > mx.x:
		return Rect2i()
	return Rect2i(mn * Bal.CHUNK, (mx - mn + Vector2i.ONE) * Bal.CHUNK)


## A walking route along the roads from a point to a building's entrance.
func road_path(from: Vector3, b: Building) -> PackedVector3Array:
	var out := PackedVector3Array()
	var ents := b.entrance_cells()
	if ents.is_empty():
		return out
	var start := _nearest_road(Grid.cell_of(from))
	var best: Array[Vector2i] = []
	for e in ents:
		var r := roads.route(start, e)
		if not r.is_empty() and (best.is_empty() or r.size() < best.size()):
			best = r
	if best.is_empty():
		return grid.path(from, b.door_pos())
	return _lane(best, from)


## Along the roads to any point (resting seats, chef stations).
func road_path_to_point(from: Vector3, to: Vector3) -> PackedVector3Array:
	var a := _nearest_road(Grid.cell_of(from))
	var z := _nearest_road(Grid.cell_of(to))
	var r := roads.route(a, z)
	if r.is_empty():
		return grid.path(from, to)
	var out := _lane(r, from)
	out.append(to)
	return out


func _nearest_road(c: Vector2i) -> Vector2i:
	if roads.is_road(c):
		return c
	for rad in range(1, 6):
		for dx in range(-rad, rad + 1):
			for dy in [-rad, rad]:
				for q in [c + Vector2i(dx, dy), c + Vector2i(dy, dx)]:
					if roads.is_road(q):
						return q
	return c


## Cell centres -> walking points, keeping to the right of the road.
func _lane(cells: Array[Vector2i], from: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in cells.size():
		var p := Grid.cell_center(cells[i])
		var dir := Vector2.ZERO
		if i + 1 < cells.size():
			dir = Vector2(cells[i + 1] - cells[i])
		elif i > 0:
			dir = Vector2(cells[i] - cells[i - 1])
		if dir != Vector2.ZERO:
			var right := Vector2(-dir.y, dir.x)
			p += Vector3(right.x, 0, right.y) * 0.32
		if i == 0 and from.distance_to(p) < 0.6:
			continue
		out.append(p)
	return out


## Where a building of `kind` could go: {ok, reason, bad: cells, path: cells}
func check_spot(kind: String, origin: Vector2i, rot: int, ignore := 0) -> Dictionary:
	var size := Defs.size_of(kind)
	var cells := Grid.cells(origin, size, rot)
	var bad: Array[Vector2i] = []
	var reason := ""
	for c in cells:
		if not Game.owns_cell(c):
			bad.append(c)
			reason = "You don't own this land yet. Tap a For Sale sign to buy it."
	if reason == "":
		for c in cells:
			var u := grid.at(c)
			if (u != 0 and u != ignore) or grid.obstacle_at(c) != "":
				bad.append(c)
				reason = "Something is in the way."
			elif _entrance_owner(c, ignore) != 0:
				bad.append(c)
				reason = "Keep building entrances clear."
	var ents := Building.entrance_of(kind, origin, rot)
	if reason == "":
		for e in ents:
			if not Game.owns_cell(e) or (grid.at(e) != 0 and grid.at(e) != ignore) or grid.obstacle_at(e) != "" or cells.has(e):
				bad.append(e)
				reason = "Its entrance is blocked: leave room in front for a road."
	return {"ok": reason == "", "reason": reason, "bad": bad, "entrance": ents}


func _entrance_owner(c: Vector2i, ignore: int) -> int:
	for n in bnodes.values():
		if n.uid != ignore and n.has_entrance() and n.entrance_cells().has(c):
			return n.uid
	return 0


## The road a new building at this spot would get (cells), for the preview.
func preview_road(kind: String, origin: Vector2i, rot: int, ignore := 0) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not Building.kind_has_entrance(kind):
		return out
	var fp := Grid.cells(origin, Defs.size_of(kind), rot)
	var ents := Building.entrance_of(kind, origin, rot)
	var starts: Array[Vector2i] = []
	for e in ents:
		if Game.owns_cell(e) and not grid.blocked(e) and not fp.has(e):
			starts.append(e)
	if starts.is_empty():
		return out
	var network := {}
	for c in roads.cells:
		if not fp.has(c):
			network[c] = true
	if network.is_empty():
		return out
	var blocked := func(c): return fp.has(c) or (grid.blocked(c) and grid.at(c) != ignore)
	var r := roads._search(starts, network, blocked, func(c): return Game.owns_cell(c))
	return r


# ---------------------------------------------------------------- jobs (builders + scaffolding)

func _sync_jobs() -> void:
	# scaffolding around buildings being upgraded
	var want := {}
	for j in Game.jobs:
		if j["type"] in ["upgrade", "stage"]:
			want[int(j["uid"])] = true
	for uid in _scaffolds.keys():
		if not want.has(uid):
			var s: Node3D = _scaffolds[uid]
			if is_instance_valid(s):
				s.queue_free()
			_scaffolds.erase(uid)
	for uid in want:
		var n: Building = bnodes.get(uid)
		if n == null or _scaffolds.has(uid):
			continue
		var sm := n.size_m()
		var h := clampf(maxf(sm.x, sm.y) * 0.5, 2.6, 6.5)
		var sc := Mats.inst(MeshKit.cached("scaffold_up_%d_%d" % [n.size().x, n.size().y], func(): return TownArt.scaffold(sm.x + 0.3, sm.y + 0.3, h)), n, Transform3D.IDENTITY, false)
		sc.scale = Vector3(1, 0.05, 1)
		var tw := sc.create_tween()
		tw.tween_property(sc, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_scaffolds[uid] = sc
	# builders: one per finished hut; each takes a job
	var huts: Array = []
	for n2 in bnodes.values():
		if n2 is HutB:
			huts.append(n2)
	huts.sort_custom(func(a, b): return a.uid < b.uid)
	for uid2 in builders.keys():
		var found := false
		for h in huts:
			if h.uid == uid2:
				found = true
		if not found:
			builders[uid2].queue_free()
			builders.erase(uid2)
	for h in huts:
		if not builders.has(h.uid):
			var bd := Builder.new()
			bd.world = self
			bd.hut_uid = h.uid
			actors.add_child(bd)
			bd.global_position = (h as HutB).rest_spot()
			builders[h.uid] = bd
	var taken := []
	for uid3 in builders:
		var bd2: Builder = builders[uid3]
		if not bd2.job.is_empty() and Game.jobs.has(bd2.job):
			taken.append(bd2.job)
		else:
			bd2.job = {}
	for j in Game.jobs:
		if taken.has(j):
			continue
		for uid4 in builders:
			var bd3: Builder = builders[uid4]
			if bd3.job.is_empty():
				bd3.job = j
				taken.append(j)
				break


## Centre of what a job works on (world).
func job_center(j: Dictionary) -> Vector3:
	if str(j.get("ob", "")) != "":
		var n: Node3D = obst_nodes.get(j["ob"])
		return n.global_position if n else Vector3.ZERO
	var b: Building = bnodes.get(int(j["uid"]))
	return b.global_position if b else Vector3.ZERO


## Where a builder stands to work on a job: beside the front corner.
func job_spot(j: Dictionary, seed_: int) -> Vector3:
	if str(j.get("ob", "")) != "":
		var n: Node3D = obst_nodes.get(j["ob"])
		if n == null:
			return Vector3.ZERO
		var ob: Dictionary = Game.obstacles.get(j["ob"], {"kind": "bush"})
		var sz: Vector2i = Defs.OBSTACLES[ob["kind"]]["size"]
		return n.global_position + Vector3(0, 0, sz.y * Grid.CELL * 0.5 + 0.5)
	var b: Building = bnodes.get(int(j["uid"]))
	if b == null:
		return Vector3.ZERO
	var s := b.size_m()
	var side := -1.0 if seed_ % 2 == 0 else 1.0
	return b.to_world(side * (s.x * 0.5 - 0.6), s.y * 0.5 + 0.55)


# ---------------------------------------------------------------- logistics broker

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


static func is_store(n: Building) -> bool:
	return n is StorageB


## Best delivery for a porter: {src, src_holder, dst, item, count} or {}.
func find_job(from: Vector3, cap: int) -> Dictionary:
	var best := {}
	var best_score := -INF
	var srcs: Array[Building] = []
	var dsts: Array[Building] = []
	for n in bnodes.values():
		if n is SiteB or not n.on_road():
			continue
		if not n.out_ports().is_empty():
			srcs.append(n)
		if not n.in_ports().is_empty():
			dsts.append(n)
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
					if d == s or (is_store(s) and is_store(d)):
						continue
					var nd := d.need(t)
					if nd <= 0.0:
						continue
					var dist_sd := s.global_position.distance_to(d.global_position)
					var dist_w := from.distance_to(s.global_position)
					# a full source (a crate or bench about to block) is urgent,
					# and bigger loads are worth the walk
					var fill := float(h.count()) / maxf(1.0, h.capacity)
					if is_store(s):
						fill *= 0.4
					var load := float(mini(cap, avail)) / maxf(1.0, cap)
					var score := nd * 2.0 + fill * 2.0 + load * 1.5 - dist_sd / 30.0 - dist_w / 45.0
					if score > best_score:
						best_score = score
						best = {"src": s, "src_holder": h, "dst": d, "item": t, "count": mini(cap, avail)}
	return best


## Best place to deliver an item a porter is already carrying.
func find_dest(t: String, from: Vector3) -> Building:
	var best: Building = null
	var best_score := -INF
	for n in bnodes.values():
		if n is SiteB or not n.on_road():
			continue
		var nd: float = n.need(t)
		if nd <= 0.0:
			continue
		var score := nd * 3.0 - from.distance_to(n.global_position) / 30.0
		if score > best_score:
			best_score = score
			best = n
	return best


# ---------------------------------------------------------------- staff

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
			var h := hall()
			w2.global_position = h.door_pos() if h else Vector3.ZERO
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


## Seat for a resting worker on the Hall's benches (or a cabin's).
func rest_seat(w: Worker) -> Vector3:
	var i := 0
	for id in workers:
		if workers[id] == w:
			break
		i += 1
	var cabins := buildings_of("cabin")
	var h := hall()
	if i < 6 or cabins.is_empty():
		return h.seat(i) if h else Vector3.ZERO
	var c: CabinB = cabins[(i - 6) / 8 % cabins.size()]
	return c.seat((i - 6) % 8)


# ---------------------------------------------------------------- save state

func store_state() -> void:
	for n in bnodes.values():
		n.persist()


# ---------------------------------------------------------------- picking

## The building under a world point (on the ground), or null.
func building_at(p: Vector3) -> Building:
	return bnodes.get(grid.at(Grid.cell_of(p)))
