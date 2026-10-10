class_name FarmB
extends Building
## A farm growing one crop: a walled plot, farmers working it (one comes with
## the farm, hired Farmers add more), and a crate at the gate where the
## harvest piles up. Farms on their favourite biome and near a Well work
## faster. Higher levels harvest more and the farm visibly grows: lanterns,
## a timber rail, a tool shed, a windmill, a brass gate.

const PLOT := Rect2(-2.8, -2.8, 5.6, 3.8)
const CRATE_Z := 1.65
const PAD_Z := 2.5

var ing := "wheat"
var crate: Holder
var zone: Zone
var farmers: Array[FarmWorker] = []
var spots: Array[Dictionary] = []     # {pos, node, ripe, busy}
var _plot: Node3D
var _count_label: Label3D
var _full: Label3D
var _animals: Array[Node3D] = []
var _rng := RandomNumberGenerator.new()


func _build() -> void:
	ing = def["crop"]
	_rng.seed = uid * 7 + hash(ing)
	var cb := Node3D.new()
	cb.position = Vector3(0, 0, CRATE_Z)
	add_child(cb)
	Mats.inst(MeshKit.cached("crate", FarmB.crate_mesh), cb)
	crate = Holder.new().setup(10, [ing], Holder.Layout.GRID)
	crate.grid = Vector2i(3, 2)
	crate.cell = Vector2(0.44, 0.42)
	crate.max_visible = 18
	crate.position = Vector3(0, 0.16, 0)
	cb.add_child(crate)
	zone = add_zone(Zone.Kind.TAKE, [crate], Vector2(0, PAD_Z), Vector2(2.0, 0.9), Defs.ITEMS[ing]["color"].lightened(0.3))
	add_port(crate, zone, "out")
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
	crate.capacity = Bal.farm_crate_cap(level)
	sync_farmers()
	_update_label()


func sync_farmers() -> void:
	var want := 1 + Game.workers_with("farmer", uid)
	while farmers.size() < want:
		var fw := FarmWorker.new()
		fw.farm = self
		fw.index = farmers.size()
		add_child(fw)
		fw.position = Vector3(_rng.randf_range(-1.2, 1.2), 0.07, 0.6)
		farmers.append(fw)
	while farmers.size() > want:
		var f: FarmWorker = farmers.pop_back()
		f.release()
		f.queue_free()


## Combined speed multiplier: biome, wells nearby, gem perk.
func speed() -> float:
	var m := 1.0
	if Defs.BIOMES[Terrain.biome_at(global_position)]["bonus"].has(ing):
		m += Bal.BIOME_BONUS
	m += world.aura(global_position, "farm") if world else 0.0
	if ing == "honey" and world:
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
	var grow := dt / Bal.farm_regrow(level) * speed()
	for s in spots:
		if s["ripe"] < 1.0 and not s["busy"]:
			s["ripe"] = minf(1.0, s["ripe"] + grow)
		var n: Node3D = s["node"]
		var target: float = (0.25 + 0.75 * s["ripe"]) * float(n.get_meta("base_scale", 1.0))
		var sc := lerpf(n.scale.y, target, clampf(dt * 8.0, 0.0, 1.0))
		n.scale = Vector3(sc, sc, sc)
		if ing in ["wheat", "sugar", "oats"]:
			n.rotation.z = sin(_t * 1.6 + n.position.x * 0.9 + n.position.z * 0.5) * 0.05
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


## How the farmer works this crop.
func work_anim() -> String:
	match ing:
		"wheat", "sugar", "oats": return "hoe"
		"cocoa", "hazelnut", "orange", "berry", "cinnamon", "vanilla": return "pick"
		_: return "milk"


static func crate_mesh() -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(1.5, 0.12, 1.06), 0.04, Pal.WOOD_DARK, MeshKit.at(0, 0.06, 0))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.08, 0.34, 1.06), 0.03, Pal.WOOD, MeshKit.at(sx * 0.72, 0.2, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(1.5, 0.14, 0.07), 0.03, Pal.WOOD_LIGHT, MeshKit.at(0, 0.27, sz * 0.5))
		k.rbox(Vector3(1.5, 0.1, 0.07), 0.03, Pal.WOOD, MeshKit.at(0, 0.12, sz * 0.5))
	return k.commit()


# ---------------------------------------------------------------- visuals

func _visual(root: Node3D, t: int) -> void:
	for fw in farmers:
		fw.release()
		if fw.state == FarmWorker.S.TO_SPOT or fw.state == FarmWorker.S.WORK:
			fw.state = FarmWorker.S.SEEK
	_animals.clear()
	spots.clear()
	_plot = root
	var w := PLOT.size.x
	var d := PLOT.size.y
	var cz := PLOT.get_center().y
	Mats.inst(MeshKit.cached("farmbed_%s_%d" % [ing, t], func(): return FarmArt.bed(ing, w, d, t)), root, MeshKit.at(0, 0, cz))
	Mats.inst(MeshKit.cached("farmwall_%d" % t, func(): return FarmArt.wall(w + 0.3, d + 0.3, t)), root, MeshKit.at(0, 0, cz))
	Mats.inst(MeshKit.cached("farmextra_%s_%d" % [ing, t], func(): return FarmArt.extras(ing, w + 0.3, d + 0.3, t)), root, MeshKit.at(0, 0, cz))
	if ing == "vanilla":
		var gl := MeshInstance3D.new()
		gl.mesh = MeshKit.cached("glassroof_%d" % t, func(): return FarmArt.glass_roof(w - 0.4, d - 0.4, t))
		gl.material_override = Mats.glass()
		gl.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		gl.position.z = cz
		root.add_child(gl)
	# crops / animals
	var layout := FarmArt.crop_layout(ing, t)
	var count: int = layout[0]
	var cols: int = layout[1]
	var rows := int(ceil(float(count) / cols))
	var area := Vector2(w - 1.0, d - 1.1)
	if ing == "vanilla":
		area = Vector2(w - 1.6, d - 1.4)
	for i in count:
		var cx: int = i % cols
		var cz2: int = i / cols
		var p := Vector3(-area.x * 0.5 + area.x * (cx + 0.5) / cols, 0.07, cz - area.y * 0.5 + area.y * (cz2 + 0.5) / rows - 0.15)
		p.x += _rng.randf_range(-0.08, 0.08)
		var node := Node3D.new()
		node.position = p
		root.add_child(node)
		Mats.inst(MeshKit.cached("crop_" + ing, func(): return Crops.crop(ing)), node)
		node.rotation.y = _rng.randf_range(-0.5, 0.5) if not ing in ["cocoa", "hazelnut", "orange", "cinnamon"] else _rng.randf() * TAU
		var sc: float = {"wheat": 1.3, "sugar": 1.1, "cocoa": 1.25, "oats": 1.25, "egg": 1.4}.get(ing, 1.0)
		node.set_meta("base_scale", sc)
		spots.append({"pos": p, "node": node, "ripe": 1.0, "busy": false})
	match ing:
		"egg":
			for i in 2 + t:
				_animal("chicken", Rect2(-w * 0.5 + 0.4, PLOT.position.y + 0.4, w - 0.8, d - 1.0))
		"milk":
			for i in 1 + (t + 1) / 2:
				_animal("cow", Rect2(-w * 0.5 + 0.7, PLOT.position.y + 0.6, w - 1.4, d - 1.4))
		"honey":
			for i in 3 + t * 2:
				_animal("bee", Rect2(-w * 0.5 + 0.3, PLOT.position.y + 0.3, w - 0.6, d - 0.6))


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
	var a := world.aura(global_position, "farm") if world else 0.0
	if a > 0.0:
		bits.append("+%d%% from wells" % roundi(a * 100))
	return "  ·  ".join(bits)


func info() -> Array:
	var per_min := 60.0 / (Bal.farm_work_time(level) / speed() + 2.2) * Bal.farm_yield(level) * farmers.size()
	return [
		[ing, "About %s %s / min" % [Fmt.num(per_min), Defs.item_name(ing).to_lower()]],
		["farmer", "%d farmer%s working" % [farmers.size(), "s" if farmers.size() != 1 else ""]],
		["storage", "Crate %d / %d" % [crate.count(), crate.capacity]],
	]


func upgrade_info() -> Array:
	var n := level + 1
	var out := [
		["Work time", "%.2fs" % Bal.farm_work_time(level), "%.2fs" % Bal.farm_work_time(n)],
		["Crate", str(Bal.farm_crate_cap(level)), str(Bal.farm_crate_cap(n))],
	]
	if Bal.farm_yield(n) > Bal.farm_yield(level):
		out.append(["Harvest", "x%d" % Bal.farm_yield(level), "x%d" % Bal.farm_yield(n)])
	return out
