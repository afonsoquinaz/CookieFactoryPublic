class_name Building
extends Node3D
## Base for everything you can place: position on the grid, rotation,
## level and visual tier, interaction pads (zones), the holders workers and
## the player move items through, colliders and walking solids.
##
## Local frame: the building's centre at the origin, its front facing +Z.
## Size in cells comes from Defs.BUILDINGS[kind].size (x = width, y = depth).

signal changed

var world: World
var data: Dictionary            # the Game.buildings entry (shared)
var uid := 0
var kind := ""
var def: Dictionary
var level := 1
var tier := -1
## {holder, zone, dir ("in"/"out")} for the logistics broker
var ports: Array[Dictionary] = []
var visual: Node3D
var _body: StaticBody3D
var _t := 0.0
var _flash := 0.0


static func create(w: World, b: Dictionary) -> Building:
	var k: String = b["kind"]
	var node: Building
	var cat: String = Defs.BUILDINGS[k]["cat"]
	if cat == "farm":
		node = FarmB.new()
	elif k == "mixer":
		node = MixerB.new()
	elif k == "tube":
		node = TubeB.new()
	elif k == "hopper":
		node = HopperB.new()
	elif k == "oven":
		node = OvenB.new()
	elif cat == "kitchen" or k == "packer" or k == "wrapper":
		node = MachineB.new()
	elif k == "pantry" or k == "rack":
		node = StorageB.new()
	elif k in ["dock", "train", "airship"]:
		node = VehicleB.new()
	elif k == "shop":
		node = ShopB.new()
	elif k == "board":
		node = BoardB.new()
	elif k == "cabin":
		node = CabinB.new()
	elif k == "palace":
		node = PalaceB.new()
	else:
		node = DecorB.new()
	node.world = w
	node.data = b
	node.uid = int(b["uid"])
	node.kind = k
	node.def = Defs.BUILDINGS[k]
	node.name = "%s_%d" % [k, node.uid]
	return node


func _ready() -> void:
	add_to_group("buildings")
	place_from_data()
	_build()
	refresh()
	load_contents(data.get("data", {}))
	_make_body()


# ---------------------------------------------------------------- placement

func cell() -> Vector2i:
	return Game.cell_of(data)


func rot() -> int:
	return int(data["rot"])


func size() -> Vector2i:
	return def["size"]


## Footprint in metres (unrotated, local).
func size_m() -> Vector2:
	return Vector2(size().x, size().y) * Grid.CELL


func place_from_data() -> void:
	position = Grid.center_of(cell(), size(), rot())
	rotation = Vector3(0, Grid.yaw(rot()), 0)


## The building's placement (unscaled, unaffected by pop-in animations).
func base_xf() -> Transform3D:
	return Transform3D(Basis(Vector3.UP, Grid.yaw(rot())), Grid.center_of(cell(), size(), rot()))


## Local point (x, z on the ground) to world.
func to_world(x: float, z: float, y := 0.0) -> Vector3:
	return base_xf() * Vector3(x, y, z)


## Solid areas (walls, machines) in local metres; the rest is walkable.
## Default: everything but a 1.2 m apron along the front.
func solid_rects() -> Array[Rect2]:
	var s := size_m()
	return [Rect2(-s.x * 0.5 + 0.1, -s.y * 0.5 + 0.1, s.x - 0.2, s.y - 1.3)]


## The same rects in world space (axis-aligned, rotation is in 90° steps).
func world_solids() -> Array[Rect2]:
	var out: Array[Rect2] = []
	for r in solid_rects():
		var a := to_world(r.position.x, r.position.y)
		var b := to_world(r.end.x, r.end.y)
		out.append(Rect2(Vector2(minf(a.x, b.x), minf(a.z, b.z)), Vector2(absf(b.x - a.x), absf(b.z - a.z))))
	return out


func _make_body() -> void:
	if _body:
		_body.queue_free()
	_body = StaticBody3D.new()
	_body.collision_layer = 1
	add_child(_body)
	for r in solid_rects():
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(r.size.x, 1.4, r.size.y)
		cs.shape = sh
		cs.position = Vector3(r.get_center().x, 0.7, r.get_center().y)
		_body.add_child(cs)


# ---------------------------------------------------------------- level + look

func refresh() -> void:
	level = int(data["lvl"])
	var t := Bal.tier(kind, level)
	if t != tier:
		var first := tier < 0
		tier = t
		if visual:
			visual.queue_free()
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
		_visual(visual, tier)
		if not first:
			celebrate()
	_on_level()
	changed.emit()


## Called when the level changes (capacities, timers).
func _on_level() -> void:
	pass


## Builds holders, zones and anything that survives tier changes.
func _build() -> void:
	pass


## Builds the look for a tier under `root`.
func _visual(_root: Node3D, _tier: int) -> void:
	pass


func celebrate() -> void:
	if not is_inside_tree():
		return
	Fx.burst(get_tree().current_scene, global_position + Vector3(0, 1.5, 0), Pal.GOLD, 24)
	if visual:
		visual.scale = Vector3(1.08, 0.6, 1.08)
		var tw := visual.create_tween()
		tw.tween_property(visual, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


## Little squash when something happens here.
func bump(amount := 0.05) -> void:
	if visual == null:
		return
	visual.scale = Vector3(1.0 + amount, 1.0 - amount, 1.0 + amount)
	var tw := visual.create_tween()
	tw.tween_property(visual, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Pop-in after being placed.
func appear() -> void:
	scale = Vector3(0.6, 0.05, 0.6)
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.puff(get_tree().current_scene, global_position + Vector3(0, 0.3, 0), Pal.CREAM, 10)


## Briefly highlights the building (selected / tapped).
func flash() -> void:
	_flash = 1.0
	bump(0.06)


# ---------------------------------------------------------------- ports + zones

func add_zone(kind_: Zone.Kind, holders: Array, at: Vector2, sz := Vector2(1.6, 1.2), col := Color(1, 1, 1)) -> Zone:
	var z := Zone.make(kind_, holders, sz, "", col)
	z.position = Vector3(at.x, 0, at.y)
	add_child(z)
	return z


func add_port(h: Holder, z: Zone, dir: String) -> void:
	ports.append({"holder": h, "zone": z, "dir": dir, "building": self})


func out_ports() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in ports:
		if p["dir"] == "out":
			out.append(p)
	return out


func in_ports() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for p in ports:
		if p["dir"] == "in":
			out.append(p)
	return out


## How much this building wants item t right now (0 = not at all, 1 = empty).
## The broker uses this to pick where workers deliver.
func need(t: String) -> float:
	for p in in_ports():
		var h: Holder = p["holder"]
		if h.can_accept(t):
			return 1.0 - float(h.count()) / maxf(1.0, h.capacity)
	return 0.0


func in_zone_for(t: String) -> Zone:
	for p in in_ports():
		if (p["holder"] as Holder).can_accept(t):
			return p["zone"]
	return null


# ---------------------------------------------------------------- save

## Holder contents to save: name -> items.
func save_contents() -> Dictionary:
	return {}


func load_contents(_d: Dictionary) -> void:
	pass


func persist() -> void:
	data["data"] = save_contents()


static func fill(h: Holder, items: Array) -> void:
	for t in items:
		if h.count() < h.capacity:
			h.add(str(t), false)


# ---------------------------------------------------------------- info for the panel

## Lines for the info panel: [[icon, text], ...]
func info() -> Array:
	return []


## What the next level changes: [[label, now, next], ...]
func upgrade_info() -> Array:
	return []


## Status shown under the name (e.g. "Makes: Chocolate Chip").
func status() -> String:
	return ""


## Speed multiplier from workers assigned here (farmers / chefs).
func staff_mult() -> float:
	return 1.0


func _process(dt: float) -> void:
	_t += dt
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 2.0)
