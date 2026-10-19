class_name Building
extends Node3D
## Base for everything you can place: position on the grid, rotation,
## level and visual tier, the entrance where its road arrives, the holders
## couriers take from and bring to, colliders and walking solids.
##
## Local frame: the building's centre at the origin, its front facing +Z.
## Size in cells comes from Defs.BUILDINGS[kind].size (x = width, y = depth).
## A building still under construction (level 0) is a SiteB instead.

signal changed

var world: World
var data: Dictionary            # the Game.buildings entry (shared)
var uid := 0
var kind := ""
var def: Dictionary
var level := 1
var tier := -1
## {holder, dir ("in"/"out")} for the logistics broker
var ports: Array[Dictionary] = []
var visual: Node3D
var _body: StaticBody3D
var _props: MeshInstance3D       # things it gains as it levels up (LevelArt)
var _props_n := -1
var _t := 0.0
var _flash := 0.0
var _compute := 0.0              # datacenter decor nearby (cached, see compute_mult)
var _compute_t := 0.0


static func create(w: World, b: Dictionary) -> Building:
	var k: String = b["kind"]
	var node: Building
	var cat: String = Defs.BUILDINGS[k]["cat"]
	if int(b["lvl"]) <= 0:
		node = SiteB.new()
	elif cat == "source":
		node = SourceB.new()
	elif k == "server":
		node = ServerB.new()
	elif k == "hut":
		node = HutB.new()
	elif cat == "lab" or k == "batcher" or k == "agent_studio":
		node = MachineB.new()
	elif k == "depot" or k == "cache":
		node = StorageB.new()
	elif k in ["van", "hyperloop", "droneport"]:
		node = VehicleB.new()
	elif k == "cafe":
		node = CafeB.new()
	elif k == "desk":
		node = DeskB.new()
	elif k == "dorm":
		node = DormB.new()
	elif k == "mega":
		node = MegaB.new()
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

## Speed from datacenter decor nearby (the "compute" aura), capped at x2.
## Re-read about once a second; servers and labs ask every frame.
func compute_mult() -> float:
	if world and _t >= _compute_t:
		_compute_t = _t + 1.0
		_compute = minf(1.0, world.aura(global_position, "compute"))
	return 1.0 + _compute


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
	_update_props()
	_on_level()
	changed.emit()


## Shows the props this level has earned; a new one arrives with a puff.
func _update_props() -> void:
	if self is SiteB:
		return
	var a := LevelArt.anchors_for(kind)
	if a.is_empty():
		return
	var n := LevelArt.count(a.size(), level, Bal.max_level(kind))
	if n == _props_n:
		return
	var first := _props_n < 0
	var t := tier
	_props_n = n
	if _props == null:
		_props = Mats.inst(null, self)
	_props.mesh = MeshKit.cached("props_%s_%d_%d" % [kind, n, t], func(): return LevelArt.props(a, n, t))
	if not first and n > 0 and is_inside_tree():
		var p: Vector3 = a[n - 1][0]
		Fx.puff(get_tree().current_scene, to_world(p.x, p.z, 0.4), Pal.CREAM, 8)
		Fx.burst(get_tree().current_scene, to_world(p.x, p.z, 1.0), Pal.GOLD, 10, false)


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


# ---------------------------------------------------------------- entrance

## Whether couriers / builders come to this building (decor doesn't).
func has_entrance() -> bool:
	return Building.kind_has_entrance(kind)


static func kind_has_entrance(k: String) -> bool:
	return Defs.BUILDINGS[k]["cat"] != "decor"


## The cell (odd widths) or two cells (even widths) in front of the middle of
## the front edge, where the road arrives.
func entrance_cells() -> Array[Vector2i]:
	return Building.entrance_of(kind, cell(), rot())


static func entrance_of(k: String, origin: Vector2i, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not kind_has_entrance(k):
		return out
	var sz: Vector2i = Defs.BUILDINGS[k]["size"]
	var xf := Transform3D(Basis(Vector3.UP, Grid.yaw(r)), Grid.center_of(origin, sz, r))
	var z := sz.y * Grid.CELL * 0.5 + Grid.CELL * 0.5
	var xs := [0.0] if sz.x % 2 == 1 else [-Grid.CELL * 0.5, Grid.CELL * 0.5]
	for x in xs:
		out.append(Grid.cell_of(xf * Vector3(x, 0, z)))
	return out


## Direction (Roads.DIRS index) from the entrance toward the building.
static func stub_dir(r: int) -> int:
	return [3, 0, 1, 2][r % 4]


## Where couriers stand: the middle of the entrance, on the road.
func door_pos() -> Vector3:
	return to_world(0, size_m().y * 0.5 + Grid.CELL * 0.5)


## Facing from the door toward the building.
func inward() -> Vector3:
	return -base_xf().basis.z


# ---------------------------------------------------------------- ports

func add_port(h: Holder, _z: Variant, dir: String) -> void:
	ports.append({"holder": h, "dir": dir, "building": self})


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


func in_holder_for(t: String) -> Holder:
	for p in in_ports():
		if (p["holder"] as Holder).can_accept(t):
			return p["holder"]
	return null


## Whether the road reaches this building (couriers only serve those).
func on_road() -> bool:
	return world != null and world.roads.connected.has(uid)


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


## Speed multiplier from workers assigned here (technicians / engineers).
func staff_mult() -> float:
	return 1.0


func _process(dt: float) -> void:
	_t += dt
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - dt * 2.0)
