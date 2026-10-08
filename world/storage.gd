class_name Storage
extends Node3D
## Pantry (ingredient bins) and Packing Shelf (cookie stacks): buffers between
## the farms and the line, and between the ovens and the trucks. Workers fill
## and empty them; the player can use both pads too.

var kind := "pantry"
var bins := {}               # pantry: ing -> Holder; shelf: "cookie" -> Holder
var give_zone: Zone
var take_zone: Zone
var _labels := {}


func setup(p_kind: String) -> void:
	kind = p_kind
	name = kind.capitalize()
	if kind == "pantry":
		position = Lay.PANTRY_POS
		_build_pantry()
	else:
		position = Lay.SHELF_POS
		_build_shelf()
	refresh()


func refresh() -> void:
	if kind == "pantry":
		for ing in bins:
			bins[ing].capacity = Bal.pantry_cap(Game.lvl("pantry"))
	else:
		bins["cookie"].capacity = Bal.shelf_cap(Game.lvl("shelf"))
	_update_labels()


func holders() -> Array[Holder]:
	var out: Array[Holder] = []
	for k in bins:
		out.append(bins[k])
	return out


func _update_labels() -> void:
	for k in bins:
		var h: Holder = bins[k]
		_labels[k].text = "%d/%d" % [h.count(), h.capacity]


func _build_pantry() -> void:
	# a long market counter along z with five bins and a striped awning
	Mats.inst(MeshKit.cached("pantry", func():
		var k := MeshKit.new()
		var wood := Pal.WOOD
		k.rbox(Vector3(1.6, 0.8, 5.8), 0.1, wood, MeshKit.at(-0.1, 0.4, 0))
		k.rbox(Vector3(1.7, 0.1, 5.9), 0.05, Pal.WOOD_LIGHT, MeshKit.at(-0.1, 0.82, 0))
		k.rbox(Vector3(0.25, 2.3, 5.8), 0.08, Pal.WOOD_DARK, MeshKit.at(-0.95, 1.15, 0))
		for sz in [-1.0, 1.0]:
			k.cyl(0.07, 2.6, Pal.WOOD_DARK, MeshKit.at(0.55, 0, sz * 2.85), 8, 0.02)
		# awning: alternating stripes, tilted toward the front
		for i in 10:
			var c := Color(0.98, 0.42, 0.42) if i % 2 == 0 else Color(1, 0.97, 0.92)
			k.rbox(Vector3(1.9, 0.08, 0.6), 0.03, c, MeshKit.xf(Vector3(-0.1, 2.65, -2.7 + i * 0.6), Vector3(0, 0, -14)))
		for i in 10:
			var c2 := Color(0.98, 0.42, 0.42) if i % 2 == 0 else Color(1, 0.97, 0.92)
			k.ellipsoid(Vector3(0.3, 0.12, 0.3), c2, MeshKit.at(0.82, 2.42, -2.7 + i * 0.6), 10, 5)
		return k.commit()), self)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(1.9, 1.6, 5.9)
	cs.shape = sh
	cs.position = Vector3(-0.2, 0.8, 0)
	body.add_child(cs)
	add_child(body)
	var i := 0
	for ing in Defs.INGREDIENTS:
		var h := Holder.new().setup(12, [ing], Holder.Layout.GRID)
		h.grid = Vector2i(2, 2)
		h.cell = Vector2(0.48, 0.48)
		h.max_visible = 16
		h.position = Vector3(-0.15, 0.88, -2.3 + i * 1.15)
		add_child(h)
		h.changed.connect(_update_labels)
		bins[ing] = h
		var ic := UI3D.icon(ing, 0.0016)
		ic.position = Vector3(-0.92, 2.05, -2.3 + i * 1.15)
		add_child(ic)
		var l := UI3D.label("0/12", 34)
		l.position = Vector3(-0.9, 1.6, -2.3 + i * 1.15)
		add_child(l)
		_labels[ing] = l
		i += 1
	give_zone = Zone.make(Zone.Kind.GIVE, holders(), Vector2(1.5, 5.4), "storage", Color(0.75, 0.9, 1.0))
	give_zone.position = Vector3(1.55, 0, 0)
	add_child(give_zone)
	take_zone = Zone.make(Zone.Kind.TAKE, holders(), Vector2(1.6, 1.4), "feeder", Color(1.0, 0.75, 0.45))
	take_zone.position = Vector3(0.6, 0, 3.75)
	add_child(take_zone)


func _build_shelf() -> void:
	Mats.inst(MeshKit.cached("shelf", func():
		var k := MeshKit.new()
		var frame := Color(0.55, 0.5, 0.85)
		k.rbox(Vector3(2.0, 0.25, 1.6), 0.08, frame.darkened(0.2), MeshKit.at(0, 0.12, 0))
		k.rbox(Vector3(1.9, 0.08, 1.5), 0.04, Pal.WOOD_LIGHT, MeshKit.at(0, 0.28, 0))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				k.cyl(0.06, 2.0, frame, MeshKit.at(sx * 0.92, 0.2, sz * 0.72), 8, 0.02)
		k.rbox(Vector3(2.1, 0.12, 1.7), 0.05, frame, MeshKit.at(0, 2.25, 0))
		k.rbox(Vector3(1.3, 0.5, 0.08), 0.08, Color(1, 0.97, 0.9), MeshKit.at(0, 2.6, 0.3))
		Items.cookie_into(k, 0.18, 0.05, MeshKit.xf(Vector3(0, 2.6, 0.36), Vector3(90, 0, 0)))
		return k.commit()), self)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.0, 2.2, 1.6)
	cs.shape = sh
	cs.position = Vector3(0, 1.1, 0)
	body.add_child(cs)
	add_child(body)
	var h := Holder.new().setup(24, ["cookie"], Holder.Layout.GRID)
	h.grid = Vector2i(4, 3)
	h.cell = Vector2(0.42, 0.42)
	h.max_visible = 200
	h.position = Vector3(0, 0.33, 0)
	add_child(h)
	h.changed.connect(_update_labels)
	bins["cookie"] = h
	var l := UI3D.label("0/24", 40)
	l.position = Vector3(0, 3.2, 0)
	add_child(l)
	_labels["cookie"] = l
	give_zone = Zone.make(Zone.Kind.GIVE, holders(), Vector2(1.4, 1.7), "collector", Color(1.0, 0.95, 0.85))
	give_zone.position = Vector3(-1.85, 0, 0)
	add_child(give_zone)
	take_zone = Zone.make(Zone.Kind.TAKE, holders(), Vector2(1.4, 1.7), "loader", Color(1.0, 0.6, 0.55))
	take_zone.position = Vector3(1.85, 0, 0)
	add_child(take_zone)
