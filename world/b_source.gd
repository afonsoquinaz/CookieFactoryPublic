class_name SourceB
extends Building
## A source making one raw resource: a fenced lot of work stations (solar
## panels, crawler dishes, chillers, dev desks...), technicians working them
## (one comes with the source, hired Technicians add more), and a crate at the
## gate where the output piles up. Sources on their favourite biome and near a
## Substation work faster. Higher levels make more and the lot visibly grows:
## a station every other level, gear in the yard (Growth), and with each
## tier a better fence, a control box, a utility shed, a wind turbine.

const PLOT := Rect2(-2.8, -2.8, 5.6, 3.8)
const CRATE_Z := 1.65
const PAD_Z := 2.5

var ing := "power"
var crate: Holder
var techs: Array[TechWorker] = []
var spots: Array[Dictionary] = []     # {pos, node (the product), ripe, busy}
var _plot: Node3D
var _count_label: Label3D
var _full: Label3D
var _animals: Array[Node3D] = []
var _spinners: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _build() -> void:
	ing = def["res"]
	_rng.seed = uid * 7 + hash(ing)
	var cb := Node3D.new()
	cb.position = Vector3(0, 0, CRATE_Z)
	add_child(cb)
	Mats.inst(MeshKit.cached("crate", SourceB.crate_mesh), cb)
	crate = Holder.new().setup(10, [ing], Holder.Layout.GRID)
	crate.grid = Vector2i(3, 2)
	crate.cell = Vector2(0.44, 0.42)
	crate.max_visible = 18
	crate.position = Vector3(0, 0.16, 0)
	cb.add_child(crate)
	add_port(crate, null, "out")
	var b := UI3D.badge(def["icon"], Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 1.3, CRATE_Z)
	add_child(b)
	_count_label = UI3D.label("0/10", 28)
	_count_label.position = Vector3(1.15, 0.5, CRATE_Z + 0.1)
	add_child(_count_label)
	_full = UI3D.label("FULL", 32, Color(1.0, 0.72, 0.6))
	_full.position = Vector3(0, 1.85, CRATE_Z)
	_full.visible = false
	add_child(_full)
	crate.changed.connect(_update_label)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.0, -3.0, 6.0, 4.15), Rect2(-0.8, CRATE_Z - 0.55, 1.6, 1.0)]


func _on_level() -> void:
	if spots.size() != SourceArt.station_count(ing, level):
		# a new station: lay the lot out again
		rebuild_visual()
		if is_inside_tree():
			Fx.puff(get_tree().current_scene, to_world(0, PLOT.get_center().y, 0.6), Pal.CREAM, 10)
	crate.capacity = Bal.src_crate_cap(level)
	sync_techs()
	_update_label()


func sync_techs() -> void:
	var want := 1 + Game.workers_with("tech", uid)
	while techs.size() < want:
		var fw := TechWorker.new()
		fw.source = self
		fw.index = techs.size()
		add_child(fw)
		fw.position = Vector3(_rng.randf_range(-1.2, 1.2), 0.07, 0.6)
		techs.append(fw)
	while techs.size() > want:
		var f: TechWorker = techs.pop_back()
		f.release()
		f.queue_free()


## Combined speed multiplier: biome, substations nearby, spark perk.
func speed() -> float:
	var m := 1.0
	if Defs.BIOMES[Terrain.biome_at(global_position)]["bonus"].has(ing):
		m += Bal.BIOME_BONUS
	m += world.aura(global_position, "source") if world else 0.0
	if ing == "rare" and world:
		m += minf(0.6, world.aura(global_position, "charm") * 3.0)
	m *= 1.0 + 0.1 * Game.perk("fertile")
	return m * Game.speed_mult()


func _update_label() -> void:
	_count_label.text = "%d/%d" % [crate.count(), crate.capacity]
	var full := crate.space() <= 0
	_full.visible = full
	_count_label.modulate = Color(1.0, 0.72, 0.6) if full else Color.WHITE


func _process(dt: float) -> void:
	super(dt)
	var grow := dt / Bal.src_regrow(level) * speed()
	for s in spots:
		if s["ripe"] < 1.0 and not s["busy"]:
			s["ripe"] = minf(1.0, s["ripe"] + grow)
		var n: Node3D = s["node"]
		var target: float = (0.15 + 0.85 * s["ripe"]) * float(n.get_meta("base_scale", 1.0))
		var sc := lerpf(n.scale.y, target, clampf(dt * 8.0, 0.0, 1.0))
		n.scale = Vector3(sc, sc, sc)
		if ing in ["data", "rare", "feedback", "silicon"]:
			n.rotation.y += dt * 0.8
	var sp := speed()
	for sn in _spinners:
		match ing:
			"data": sn.rotation.y = sin(_t * 0.5 + sn.get_parent().position.x) * 1.2
			"coolant": sn.rotation.y += dt * 9.0 * sp
			"fiber": sn.rotation.x += dt * 2.5 * sp
	for a in _animals:
		a.call("animate", dt)
	if _full.visible:
		_full.position.y = 1.85 + sin(_t * 3.0) * 0.05


func claim_spot() -> Dictionary:
	var best := {}
	var best_r := 0.55
	for s in spots:
		if not s["busy"] and s["ripe"] >= best_r:
			best = s
			best_r = s["ripe"] + _rng.randf() * 0.2
	if not best.is_empty():
		best["busy"] = true
	return best


func harvest(s: Dictionary) -> void:
	s["ripe"] = 0.0
	s["busy"] = false
	var n = s["node"]
	if is_instance_valid(n):
		(n as Node3D).scale = Vector3(0.2, 0.2, 0.2)


func crate_drop_point() -> Vector3:
	return Vector3(0.0, 0, CRATE_Z - 0.6)


## How the technician works this station.
func work_anim() -> String:
	match ing:
		"copper", "rare": return "hoe"
		"papers": return "pick"
		"power", "coolant", "fiber": return "milk"
	return "type"


static func crate_mesh() -> Mesh:
	var k := MeshKit.new()
	# a steel cargo tray with a teal frame and a status light
	k.rbox(Vector3(1.5, 0.12, 1.06), 0.04, Color(0.3, 0.32, 0.36), MeshKit.at(0, 0.06, 0))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.08, 0.34, 1.06), 0.03, Color(0.3, 0.66, 0.68), MeshKit.at(sx * 0.72, 0.2, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(1.5, 0.14, 0.07), 0.03, Color(0.86, 0.88, 0.9), MeshKit.at(0, 0.27, sz * 0.5))
		k.rbox(Vector3(1.5, 0.1, 0.07), 0.03, Color(0.3, 0.66, 0.68), MeshKit.at(0, 0.12, sz * 0.5))
	k.rbox(Vector3(0.1, 0.06, 0.02), 0.01, Color(0.5, 1.0, 0.6, 0.4), MeshKit.at(0.55, 0.28, 0.54))
	return k.commit()


# ---------------------------------------------------------------- visuals

func _visual(root: Node3D, t: int) -> void:
	for fw in techs:
		fw.release()
		if fw.state == TechWorker.S.TO_SPOT or fw.state == TechWorker.S.WORK:
			fw.state = TechWorker.S.SEEK
	_animals.clear()
	_spinners.clear()
	spots.clear()
	_plot = root
	var w := PLOT.size.x
	var d := PLOT.size.y
	var cz := PLOT.get_center().y
	Mats.inst(MeshKit.cached("srcbed_%s_%d" % [ing, t], func(): return SourceArt.bed(ing, w, d, t)), root, MeshKit.at(0, 0, cz))
	Mats.inst(MeshKit.cached("srcwall_%d" % t, func(): return SourceArt.wall(w + 0.3, d + 0.3, t)), root, MeshKit.at(0, 0, cz))
	Mats.inst(MeshKit.cached("srcextra_%s_%d" % [ing, t], func(): return SourceArt.extras(ing, w + 0.3, d + 0.3, t)), root, MeshKit.at(0, 0, cz))
	# stations, each with what it's making on it (more of them as it levels)
	var pp := Stations.product_at(ing)
	var ps := Stations.product_scale(ing)
	var sp := Stations.spinner_at(ing)
	for p in SourceArt.station_spots(ing, level, w, d, cz):
		var node := Node3D.new()
		node.position = p
		node.scale = Vector3.ONE * 1.22
		root.add_child(node)
		Mats.inst(MeshKit.cached("station_" + ing, func(): return Stations.station(ing)), node)
		if sp != Vector3.INF:
			var spin := Node3D.new()
			spin.position = sp
			node.add_child(spin)
			Mats.inst(MeshKit.cached("spinner_" + ing, func(): return Stations.spinner(ing)), spin, Transform3D.IDENTITY, false)
			_spinners.append(spin)
		var prod := Node3D.new()
		prod.position = pp
		node.add_child(prod)
		Mats.inst(Items.mesh(ing), prod, Transform3D.IDENTITY, false)
		prod.set_meta("base_scale", ps)
		spots.append({"pos": p, "node": prod, "ripe": 1.0, "busy": false})
	match ing:
		"data":
			for i in 2 + t:
				_animal("crawler", Rect2(-w * 0.5 + 0.4, PLOT.position.y + 0.4, w - 0.8, d - 1.0))
		"power":
			for i in (t + 1) / 2:
				_animal("drone", Rect2(-w * 0.5 + 0.3, PLOT.position.y + 0.3, w - 0.6, d - 0.6))
		"rare", "copper":
			for i in 1 + t / 2:
				_animal("cart", Rect2(-w * 0.5 + 0.6, PLOT.position.y + 0.6, w - 1.2, d - 1.4))


func _animal(k: String, bounds: Rect2) -> void:
	var a := Animal.new()
	a.kind = k
	a.bounds = bounds
	a.position = Vector3(_rng.randf_range(bounds.position.x, bounds.end.x), 0.07, _rng.randf_range(bounds.position.y, bounds.end.y))
	_plot.add_child(a)
	_animals.append(a)


# ---------------------------------------------------------------- save + info

func save_contents() -> Dictionary:
	return {"crate": crate.items.duplicate()}


func load_contents(d: Dictionary) -> void:
	Building.fill(crate, d.get("crate", []))


func status() -> String:
	var bits := []
	if Defs.BIOMES[Terrain.biome_at(global_position)]["bonus"].has(ing):
		bits.append("+40%% on %s" % Defs.BIOMES[Terrain.biome_at(global_position)]["name"])
	var a := world.aura(global_position, "source") if world else 0.0
	if a > 0.0:
		bits.append("+%d%% from substations" % roundi(a * 100))
	return "  ·  ".join(bits)


func info() -> Array:
	var per_min := 60.0 / (Bal.src_work_time(level) / speed() + 2.2) * Bal.src_yield(level) * techs.size()
	return [
		[ing, "About %s %s / min" % [Fmt.num(per_min), Defs.item_name(ing).to_lower()]],
		["tech", "%d technician%s working" % [techs.size(), "s" if techs.size() != 1 else ""]],
		["storage", "Crate %d / %d" % [crate.count(), crate.capacity]],
	]


func upgrade_info() -> Array:
	var n := level + 1
	var out := [
		["Work time", "%.2fs" % Bal.src_work_time(level), "%.2fs" % Bal.src_work_time(n)],
		["Crate", str(Bal.src_crate_cap(level)), str(Bal.src_crate_cap(n))],
	]
	if SourceArt.station_count(ing, n) > SourceArt.station_count(ing, level):
		out.append(["Stations", str(SourceArt.station_count(ing, level)), str(SourceArt.station_count(ing, n))])
	if Bal.src_yield(n) > Bal.src_yield(level):
		out.append(["Harvest", "x%d" % Bal.src_yield(level), "x%d" % Bal.src_yield(n)])
	return out
