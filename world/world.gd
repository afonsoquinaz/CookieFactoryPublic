class_name World
extends Node3D
## Builds the island and everything on it, keeps it in sync with Game state
## (buildings, upgrades, workers), and answers the questions workers ask
## ("which farm crate is fullest?", "which hopper needs wheat most?").

signal sold(amount: int, count: int, where: Vector3)

var region: NavigationRegion3D
var actors: Node3D
var farms := {}                 # ing -> Farm
var lines: Array[Line] = []
var docks: Array[Dock] = []
var pantry: Storage
var shelf: Storage
var cabin: Cabin
var pads := {}                  # id -> BuildPad
var player: Player
var workers := {}               # id -> Worker
var cam: CameraRig
var nav_ready := false
var _bake_pending := false
var _bake_cd := 0.0
var _floors := {}


func _ready() -> void:
	Env.build(self)
	region = NavigationRegion3D.new()
	var nm := NavigationMesh.new()
	nm.geometry_parsed_geometry_type = NavigationMesh.PARSED_GEOMETRY_STATIC_COLLIDERS
	nm.geometry_collision_mask = 1
	nm.cell_size = 0.25
	nm.cell_height = 0.25
	nm.agent_radius = 0.25
	nm.agent_height = 1.2
	nm.agent_max_climb = 0.25
	nm.region_min_size = 4.0
	region.navigation_mesh = nm
	region.bake_finished.connect(func(): nav_ready = true)
	add_child(region)
	actors = Node3D.new()
	actors.name = "Actors"
	add_child(actors)
	Island.build(self, region)
	for ing in Defs.INGREDIENTS:
		var f := Farm.new()
		region.add_child(f)
		f.setup(ing)
		farms[ing] = f
		_farm_colliders(f)
	_spawn_line(0)
	_spawn_dock(0)
	for id in Defs.BUILD_ORDER:
		if Game.has_building(id):
			_spawn_building(id, false)
		else:
			_spawn_pad(id)
	player = Player.new()
	actors.add_child(player)
	player.global_position = Lay.PLAYER_START
	cam = CameraRig.new()
	add_child(cam)
	cam.target = player
	cam.snap()
	_restore_state()
	_sync_workers()
	Game.built.connect(_on_built)
	Game.upgraded.connect(_on_upgraded)
	Game.workers_changed.connect(_sync_workers)
	Game.level_up.connect(func(_l, _r): _refresh_pads())
	_request_bake()


func _process(dt: float) -> void:
	if _bake_pending:
		_bake_cd -= dt
		if _bake_cd <= 0.0 and not region.is_baking():
			_bake_pending = false
			region.bake_navigation_mesh(true)
	_store_state()


func _request_bake() -> void:
	_bake_pending = true
	_bake_cd = 0.2


# ---------------------------------------------------------------- spawning

func _spawn_line(i: int) -> void:
	var l := Line.new()
	region.add_child(l)
	l.setup(i)
	lines.append(l)
	Island.factory_floor(region, i)


func _spawn_dock(i: int) -> void:
	var d := Dock.new()
	region.add_child(d)
	d.setup(i)
	d.sold.connect(func(a, c, w): sold.emit(a, c, w))
	docks.append(d)
	Island.pier(region, i)


func _spawn_pad(id: String) -> void:
	var p := BuildPad.new()
	region.add_child(p)
	p.setup(id)
	pads[id] = p


func _refresh_pads() -> void:
	pass


func _spawn_building(id: String, animate: bool) -> void:
	var node: Node3D = null
	match id:
		"cabin":
			cabin = Cabin.new()
			region.add_child(cabin)
			node = cabin
		"pantry":
			pantry = Storage.new()
			region.add_child(pantry)
			pantry.setup("pantry")
			node = pantry
		"shelf":
			shelf = Storage.new()
			region.add_child(shelf)
			shelf.setup("shelf")
			node = shelf
		"line2":
			_spawn_line(1)
			node = lines[1]
		"line3":
			_spawn_line(2)
			node = lines[2]
		"dock2":
			_spawn_dock(1)
			node = docks[1]
		"dock3":
			_spawn_dock(2)
			node = docks[2]
	if animate and node:
		node.scale = Vector3(0.6, 0.05, 0.6)
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _on_built(id: String) -> void:
	pads.erase(id)
	_spawn_building(id, true)
	_request_bake()
	for w in workers.values():
		w.state = Worker.S.DECIDE


func _on_upgraded(id: String, _lvl: int) -> void:
	if id.begins_with("farm_"):
		farms[id.substr(5)].refresh()
	match id:
		"hopper", "batch":
			for l in lines:
				l.refresh()
		"truck":
			for d in docks:
				d.refresh()
		"pantry":
			if pantry:
				pantry.refresh()
		"shelf":
			if shelf:
				shelf.refresh()
		"wcarry":
			for w in workers.values():
				w.refresh()


func _sync_workers() -> void:
	var seen := {}
	for d in Game.workers:
		var id := int(d["id"])
		if d["role"] == "farmer":
			continue
		seen[id] = true
		if workers.has(id):
			var w: Worker = workers[id]
			if w.role != d["role"]:
				w.data = d
				w.apply_role()
			else:
				w.data = d
		else:
			var w2 := Worker.new()
			w2.setup(self, d)
			actors.add_child(w2)
			w2.global_position = cabin.global_position + Vector3(randf_range(-1, 1), 0, 2.5) if cabin else Lay.PLAYER_START
			workers[id] = w2
	for id in workers.keys():
		if not seen.has(id):
			var w3: Worker = workers[id]
			Fx.ring(self, w3.global_position, Color(0.42, 0.78, 0.3), 1.5)
			w3.queue_free()
			workers.erase(id)
	for f in farms.values():
		f.refresh()


func idle_seat_index(w: Worker) -> int:
	var i := 0
	for id in workers:
		if workers[id] == w:
			return i
		if workers[id].role == "":
			i += 1
	return i


# ---------------------------------------------------------------- queries

func pick_farm_for_gatherer(target: String) -> Farm:
	if pantry == null:
		return null
	if target != "":
		var f: Farm = farms[target]
		return f if f.crate.count() > 0 and pantry.bins[target].space() > 0 else null
	var best: Farm = null
	var best_score := 0.0
	for ing in farms:
		var f2: Farm = farms[ing]
		if f2.crate.count() == 0 or pantry.bins[ing].space() <= 0:
			continue
		# fuller crates and emptier pantry bins first
		var score: float = float(f2.crate.count()) / f2.crate.capacity + (1.0 - float(pantry.bins[ing].count()) / pantry.bins[ing].capacity) + randf() * 0.15
		if score > best_score:
			best_score = score
			best = f2
	return best


## [ingredient, amount] the feeders should bring next, or [].
func pick_feeder_job() -> Array:
	if pantry == null:
		return []
	var best := []
	var best_need := 0.0
	for l in lines:
		for ing in Defs.INGREDIENTS:
			var h: Holder = l.hoppers[ing]
			var need := h.space()
			var have: int = pantry.bins[ing].count()
			if need <= 0 or have <= 0:
				continue
			var score := float(need) / h.capacity + randf() * 0.1
			if score > best_need:
				best_need = score
				best = [ing, mini(need, have)]
	return best


func neediest_hopper_zone(ing: String) -> Zone:
	var best: Zone = null
	var best_space := 0
	for l in lines:
		var h: Holder = l.hoppers[ing]
		if h.space() > best_space:
			best_space = h.space()
			best = l.zones[ing]
	return best


func fullest_tray_zone() -> Zone:
	var best: Zone = null
	var most := 0
	for l in lines:
		if l.tray.count() > most:
			most = l.tray.count()
			best = l.tray_zone
	return best


func parked_dock() -> Dock:
	var best: Dock = null
	for d in docks:
		if d.state == Dock.S.PARKED and d.cargo.space() > 0:
			if best == null or d.cargo.count() > best.cargo.count():
				best = d
	return best


# ---------------------------------------------------------------- save state

var _store_cd := 0.0

func _store_state() -> void:
	_store_cd -= get_process_delta_time()
	if _store_cd > 0.0:
		return
	_store_cd = 2.0
	var s := {}
	for ing in farms:
		s["farm_" + ing] = farms[ing].crate.count()
	for i in lines.size():
		for ing in Defs.INGREDIENTS:
			s["hop%d_%s" % [i, ing]] = lines[i].hoppers[ing].count()
		s["tray%d" % i] = lines[i].tray.count()
	for i in docks.size():
		s["dock%d" % i] = docks[i].cargo.count() if docks[i].state == Dock.S.PARKED else 0
	if pantry:
		for ing in Defs.INGREDIENTS:
			s["pantry_" + ing] = pantry.bins[ing].count()
	if shelf:
		s["shelf"] = shelf.bins["cookie"].count()
	s["carry"] = player.carry.items.duplicate()
	Game.world_state = s


func _restore_state() -> void:
	var s: Dictionary = Game.world_state
	if s.is_empty():
		return
	var fill := func(h: Holder, t: String, n: int) -> void:
		for k in mini(n, h.capacity):
			h.add(t, false)
	for ing in farms:
		fill.call(farms[ing].crate, ing, int(s.get("farm_" + ing, 0)))
	for i in lines.size():
		for ing in Defs.INGREDIENTS:
			fill.call(lines[i].hoppers[ing], ing, int(s.get("hop%d_%s" % [i, ing], 0)))
		fill.call(lines[i].tray, "cookie", int(s.get("tray%d" % i, 0)))
	for i in docks.size():
		fill.call(docks[i].cargo, "cookie", int(s.get("dock%d" % i, 0)))
	if pantry:
		for ing in Defs.INGREDIENTS:
			fill.call(pantry.bins[ing], ing, int(s.get("pantry_" + ing, 0)))
	if shelf:
		fill.call(shelf.bins["cookie"], "cookie", int(s.get("shelf", 0)))
	for t in s.get("carry", []):
		if player.carry.space() > 0:
			player.carry.add(str(t), false)


func _farm_colliders(f: Farm) -> void:
	var body := StaticBody3D.new()
	f.add_child(body)
	var w := Lay.FARM_SIZE.x + 0.3
	var d := Lay.FARM_SIZE.y + 0.3
	var gate := 1.3
	var segs := [
		[Vector3(0, 0.4, -d * 0.5), Vector3(w, 0.8, 0.2)],
		[Vector3(-w * 0.5, 0.4, 0), Vector3(0.2, 0.8, d)],
		[Vector3(w * 0.5, 0.4, 0), Vector3(0.2, 0.8, d)],
		[Vector3(-(w + gate) * 0.25, 0.4, d * 0.5), Vector3((w - gate) * 0.5, 0.8, 0.2)],
		[Vector3((w + gate) * 0.25, 0.4, d * 0.5), Vector3((w - gate) * 0.5, 0.8, 0.2)],
		# the crate
		[Vector3(0, 0.3, Lay.CRATE_Z - Lay.FARM_Z), Vector3(1.5, 0.6, 1.0)],
	]
	for sg in segs:
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = sg[1]
		cs.shape = sh
		cs.position = sg[0]
		body.add_child(cs)


# ---------------------------------------------------------------- route preview

var _route: Node3D

## Shows where a role walks (dashed arrows between its pads), "" hides it.
func show_route(role: String) -> void:
	if _route:
		_route.queue_free()
		_route = null
	if role == "":
		return
	_route = Node3D.new()
	add_child(_route)
	var col: Color = Defs.ROLES[role]["color"]
	if role == "collector":
		col = Color(1.0, 0.85, 0.55)
	var pairs := []
	var rings := []
	match role:
		"farmer":
			for f in farms.values():
				rings.append(f.global_position)
		"gatherer":
			for f in farms.values():
				pairs.append([f.zone.global_position, pantry.give_zone.global_position if pantry else Lay.pad_pos("pantry")])
		"feeder":
			var src: Vector3 = pantry.take_zone.global_position if pantry else Lay.pad_pos("pantry")
			for l in lines:
				for ing in Defs.INGREDIENTS:
					pairs.append([src, l.zones[ing].global_position])
		"collector":
			for l in lines:
				pairs.append([l.tray_zone.global_position, shelf.give_zone.global_position if shelf else Lay.pad_pos("shelf")])
		"loader":
			var s2: Vector3 = shelf.take_zone.global_position if shelf else Lay.pad_pos("shelf")
			for d in docks:
				pairs.append([s2, d.zone.global_position])
	var mat := Mats.flat(Color(col.r, col.g, col.b, 0.95))
	for pr in pairs:
		var a: Vector3 = pr[0]
		var b: Vector3 = pr[1]
		var k := MeshKit.new()
		var len := a.distance_to(b)
		var dir := (b - a).normalized()
		var ang := rad_to_deg(atan2(dir.x, dir.z))
		var n := int(len / 0.6)
		for i in n:
			var p := a.lerp(b, (i + 0.5) / n)
			k.rbox(Vector3(0.14, 0.03, 0.32), 0.05, Color(1, 1, 1), MeshKit.xf(p + Vector3(0, 0.1, 0), Vector3(0, ang, 0)))
		k.cone(0.32, 0.6, Color(1, 1, 1), MeshKit.xf(b - dir * 0.9 + Vector3(0, 0.12, 0), Vector3(90, ang, 0)), 10)
		var mi := MeshInstance3D.new()
		mi.mesh = k.commit()
		mi.material_override = mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_route.add_child(mi)
		rings.append(a)
		rings.append(b)
	var uniq := []
	for r in rings:
		var dup := false
		for u in uniq:
			if (u as Vector3).distance_to(r) < 0.5:
				dup = true
		if not dup:
			uniq.append(r)
	rings = uniq
	for r in rings:
		Fx.ring(_route, r, col, 1.3)
	# keep the rings pulsing while the preview is up
	var tw := _route.create_tween().set_loops()
	tw.tween_interval(0.9)
	tw.tween_callback(func():
		for r2 in rings:
			Fx.ring(_route, r2, col, 1.3))
