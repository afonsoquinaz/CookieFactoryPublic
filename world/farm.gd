class_name Farm
extends Node3D
## One farm: a fenced plot growing one ingredient, little farmers working it
## (one comes with the farm, hired Farmers add more), and a crate at the gate
## where the harvest piles up for the player or Gatherers to collect.
##
## Farmers loop: walk to a ripe crop -> work it (tool animation) -> the crop
## pops off -> carry the item to the crate -> drop it in -> repeat. Upgrading
## the farm makes them work faster, harvest more and grows the plot visibly.

var ing := "wheat"
var crate: Holder
var zone: Zone
var farmers: Array[FarmWorker] = []
var spots: Array[Dictionary] = []     # {pos, node, ripe(0..1), busy}
var level := 1
var tier := -1
var _plot: Node3D
var _count_label: Label3D
var _full_icon: Label3D
var _animals: Array[Node3D] = []
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func setup(p_ing: String) -> void:
	ing = p_ing
	name = "Farm_" + ing
	_rng.seed = hash(ing)
	position = Vector3(Lay.FARM_X[ing], 0, Lay.FARM_Z)
	# crate at the gate (south side)
	var crate_base := Node3D.new()
	crate_base.position = Vector3(0, 0, Lay.CRATE_Z - Lay.FARM_Z)
	add_child(crate_base)
	Mats.inst(MeshKit.cached("crate", _crate_mesh), crate_base)
	crate = Holder.new().setup(10, [ing], Holder.Layout.GRID)
	crate.grid = Vector2i(3, 2)
	crate.cell = Vector2(0.44, 0.42)
	crate.max_visible = 18
	crate.position = Vector3(0, 0.16, 0)
	crate_base.add_child(crate)
	zone = Zone.make(Zone.Kind.TAKE, [crate], Vector2(1.9, 1.3), ing, Defs.ITEMS[ing]["color"].lightened(0.3))
	zone.position = Vector3(0, 0, Lay.CRATE_ZONE_Z - Lay.FARM_Z)
	add_child(zone)
	_count_label = UI3D.label("0/10", 40)
	_count_label.position = Vector3(0.55, 1.1, Lay.CRATE_Z - Lay.FARM_Z + 0.2)
	add_child(_count_label)
	_full_icon = UI3D.label("FULL!", 46, Color(1.0, 0.45, 0.4))
	_full_icon.position = Vector3(0, 2.1, Lay.CRATE_Z - Lay.FARM_Z)
	_full_icon.visible = false
	add_child(_full_icon)
	crate.changed.connect(_update_label)
	_build_static()
	refresh()


## Re-reads the farm level and farmer count from Game.
func refresh() -> void:
	level = Game.lvl("farm_" + ing)
	crate.capacity = Bal.farm_crate_cap(level)
	var t := Bal.farm_tier(level)
	if t != tier:
		var first := tier < 0
		tier = t
		_build_plot()
		if not first:
			_celebrate()
	var want := 1 + Game.workers_with("farmer", ing)
	while farmers.size() < want:
		var fw := FarmWorker.new()
		fw.farm = self
		fw.index = farmers.size()
		add_child(fw)
		fw.position = _spot_free_pos()
		farmers.append(fw)
	while farmers.size() > want:
		var f: FarmWorker = farmers.pop_back()
		f.release()
		f.queue_free()
	_update_label()


func _update_label() -> void:
	_count_label.text = "%d/%d" % [crate.count(), crate.capacity]
	var full := crate.space() <= 0
	_full_icon.visible = full
	_count_label.modulate = Color(1.0, 0.55, 0.5) if full else Color.WHITE


func _process(dt: float) -> void:
	_t += dt
	# crops regrow; idle animation for crops and animals
	var grow := dt / maxf(1.0, 6.0 * pow(0.92, level - 1)) * Game.speed_mult()
	for s in spots:
		if s["ripe"] < 1.0 and not s["busy"]:
			s["ripe"] = minf(1.0, s["ripe"] + grow)
		var n: Node3D = s["node"]
		var target: float = (0.25 + 0.75 * s["ripe"]) * float(n.get_meta("base_scale", 1.0))
		var sc := lerpf(n.scale.y, target, clampf(dt * 8.0, 0.0, 1.0))
		n.scale = Vector3(sc, sc, sc)
		if ing == "wheat" or ing == "sugar":
			n.rotation.z = sin(_t * 1.6 + n.position.x * 0.9 + n.position.z * 0.5) * 0.05
	for a in _animals:
		a.call("animate", dt)
	if _full_icon.visible:
		_full_icon.position.y = 2.1 + absf(sin(_t * 4.0)) * 0.15


## A ripe spot nobody is working on (or null).
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
	return Vector3(0.0, 0, Lay.CRATE_Z - Lay.FARM_Z - 0.55 * signf(Lay.CRATE_Z - Lay.FARM_Z))


func _spot_free_pos() -> Vector3:
	return Vector3(_rng.randf_range(-1.0, 1.0), 0, 1.4)


func _celebrate() -> void:
	Fx.burst(get_tree().current_scene, global_position + Vector3(0, 1, 0), Defs.ITEMS[ing]["color"], 26)
	var tw := _plot.create_tween()
	_plot.scale = Vector3(1, 0.4, 1)
	tw.tween_property(_plot, "scale", Vector3.ONE, 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


# ---------------------------------------------------------------- visuals

func _crate_mesh() -> Mesh:
	var k := MeshKit.new()
	# a low wooden pallet-crate with slatted sides
	k.rbox(Vector3(1.5, 0.12, 1.06), 0.04, Pal.WOOD_DARK, MeshKit.at(0, 0.06, 0))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.08, 0.34, 1.06), 0.03, Pal.WOOD, MeshKit.at(sx * 0.72, 0.2, 0))
	for sz in [-1.0, 1.0]:
		k.rbox(Vector3(1.5, 0.14, 0.07), 0.03, Pal.WOOD_LIGHT, MeshKit.at(0, 0.27, sz * 0.5))
		k.rbox(Vector3(1.5, 0.1, 0.07), 0.03, Pal.WOOD, MeshKit.at(0, 0.12, sz * 0.5))
	return k.commit()


## Things that never change with level: the badge over the crate.
func _build_static() -> void:
	var b := UI3D.badge(ing, Defs.ITEMS[ing]["color"].darkened(0.15), 0.95)
	b.position = Vector3(-0.15, 1.45, Lay.CRATE_Z - Lay.FARM_Z)
	add_child(b)


func _build_plot() -> void:
	if _plot:
		_plot.queue_free()
	# farmers working a crop of the old plot start over on the new one
	for fw in farmers:
		fw.release()
		if fw.state == FarmWorker.S.TO_SPOT or fw.state == FarmWorker.S.WORK:
			fw.state = FarmWorker.S.SEEK
	_animals.clear()
	spots.clear()
	_plot = Node3D.new()
	add_child(_plot)
	var w := Lay.FARM_SIZE.x
	var d := Lay.FARM_SIZE.y
	# ground bed + fence (fence gets nicer with tiers)
	var bed_col := Pal.SOIL
	if ing == "egg":
		bed_col = Color(0.93, 0.8, 0.55)
	elif ing == "milk":
		bed_col = Color(0.55, 0.82, 0.38)
	elif ing == "cocoa":
		bed_col = Color(0.48, 0.74, 0.34)
	Mats.inst(MeshKit.cached("bed_%s" % ing, func():
		var k := MeshKit.new()
		k.rbox(Vector3(w, 0.14, d), 0.07, bed_col, MeshKit.at(0, 0.0, 0))
		if ing == "wheat" or ing == "sugar":
			for r in 4:
				k.rbox(Vector3(w - 0.5, 0.08, 0.5), 0.04, bed_col.darkened(0.1), MeshKit.at(0, 0.07, -d * 0.5 + 0.7 + r * (d - 1.2) / 3.0))
		return k.commit()), _plot)
	Mats.inst(MeshKit.cached("fence_%d" % tier, func(): return Farm.fence_mesh(w + 0.3, d + 0.3, tier)), _plot)
	# crops / animals
	var count: int = [4, 6, 8, 10, 12][tier]
	var cols := 2 if count <= 4 else (3 if count <= 9 else 4)
	if ing == "wheat" or ing == "sugar":
		# fields are rows of crops: dense from the start
		count = [9, 12, 12, 16, 16][tier]
		cols = 3 if count <= 9 else 4
	var rows := int(ceil(float(count) / cols))
	var area := Vector2(w - 1.0, d - 1.3)
	for i in count:
		var cx: int = i % cols
		var cz: int = i / cols
		var p := Vector3(-area.x * 0.5 + area.x * (cx + 0.5) / cols, 0.07, -area.y * 0.5 + area.y * (cz + 0.5) / rows - 0.25)
		p.x += _rng.randf_range(-0.08, 0.08)
		var node := Node3D.new()
		node.position = p
		_plot.add_child(node)
		match ing:
			"wheat":
				Mats.inst(MeshKit.cached("wheat_clump", Crops.wheat), node)
			"sugar":
				Mats.inst(MeshKit.cached("sugar_clump", Crops.sugar), node)
			"cocoa":
				Mats.inst(MeshKit.cached("cocoa_tree", Crops.cocoa), node)
			"egg":
				Mats.inst(MeshKit.cached("nest", Crops.nest), node).scale = Vector3.ONE * 1.4
			"milk":
				Mats.inst(MeshKit.cached("milk_can", Crops.milk_can), node)
		node.rotation.y = _rng.randf_range(-0.5, 0.5) if ing != "cocoa" else _rng.randf() * TAU
		var sc: float = {"wheat": 1.3, "sugar": 1.1, "cocoa": 1.25}.get(ing, 1.0)
		node.set_meta("base_scale", sc)
		spots.append({"pos": p, "node": node, "ripe": 1.0, "busy": false})
	# animals and buildings
	if ing == "egg":
		var coop := Node3D.new()
		coop.position = Vector3(0.9, 0.07, -d * 0.5 + 0.75)
		_plot.add_child(coop)
		Mats.inst(MeshKit.cached("coop_%d" % mini(tier, 2), func(): return Crops.coop(mini(tier, 2))), coop)
		for i in 2 + tier:
			var ch := Animal.new()
			ch.kind = "chicken"
			ch.bounds = Rect2(-w * 0.5 + 0.4, -d * 0.5 + 0.4, w - 0.8, d - 1.0)
			ch.position = Vector3(_rng.randf_range(-1, 1), 0.07, _rng.randf_range(-1.2, 1.0))
			_plot.add_child(ch)
			_animals.append(ch)
	elif ing == "milk":
		for i in 1 + (tier + 1) / 2:
			var cow := Animal.new()
			cow.kind = "cow"
			cow.bounds = Rect2(-w * 0.5 + 0.7, -d * 0.5 + 0.6, w - 1.4, d - 1.6)
			cow.position = Vector3(-0.8 + i * 0.9, 0.07, -1.0 + (i % 2) * 0.8)
			_plot.add_child(cow)
			_animals.append(cow)
		var trough := Node3D.new()
		trough.position = Vector3(-0.9, 0.07, -d * 0.5 + 0.5)
		_plot.add_child(trough)
		Mats.inst(MeshKit.cached("trough", Crops.trough), trough)


static func fence_mesh(w: float, d: float, tier: int) -> Mesh:
	var k := MeshKit.new()
	var post := Pal.WOOD_DARK if tier < 2 else (Color(0.97, 0.97, 0.95) if tier < 4 else Color(0.96, 0.5, 0.45))
	var rail := Pal.WOOD if tier < 2 else (Color(1, 1, 1) if tier < 4 else Color(1.0, 0.95, 0.9))
	var h := 0.5 + tier * 0.03
	var gate := 1.3
	var edges := [[Vector2(-w * 0.5, -d * 0.5), Vector2(w * 0.5, -d * 0.5)],
		[Vector2(w * 0.5, -d * 0.5), Vector2(w * 0.5, d * 0.5)],
		[Vector2(-w * 0.5, d * 0.5), Vector2(-w * 0.5, -d * 0.5)]]
	# front edge with a gate gap in the middle
	edges.append([Vector2(w * 0.5, d * 0.5), Vector2(gate * 0.5, d * 0.5)])
	edges.append([Vector2(-gate * 0.5, d * 0.5), Vector2(-w * 0.5, d * 0.5)])
	for e in edges:
		var a: Vector2 = e[0]
		var b: Vector2 = e[1]
		var len := a.distance_to(b)
		var n := maxi(1, int(round(len / 0.9)))
		for i in n + 1:
			var p := a.lerp(b, float(i) / n)
			k.rbox(Vector3(0.11, h + 0.1, 0.11), 0.035, post, MeshKit.at(p.x, (h + 0.1) * 0.5, p.y))
			if tier >= 3:
				k.sphere(0.075, post, MeshKit.at(p.x, h + 0.12, p.y), 8, 5)
		var mid := (a + b) * 0.5
		var ang := rad_to_deg(atan2(b.y - a.y, b.x - a.x))
		for yy in [h * 0.45, h * 0.85]:
			k.rbox(Vector3(len, 0.07, 0.05), 0.025, rail, MeshKit.xf(Vector3(mid.x, yy, mid.y), Vector3(0, -ang, 0)))
	return k.commit()
