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
		# a long market counter: back wall, five open crates, a short striped
		# awning over the back so the bins stay visible from above
		k.rbox(Vector3(1.6, 0.7, 5.9), 0.1, Pal.WOOD_DARK, MeshKit.at(-0.1, 0.35, 0))
		k.rbox(Vector3(0.22, 1.9, 5.9), 0.08, Pal.WOOD, MeshKit.at(-0.95, 0.95, 0))
		for i in 5:
			var z := -2.3 + i * 1.15
			k.rbox(Vector3(1.2, 0.16, 1.02), 0.04, Pal.WOOD_LIGHT, MeshKit.at(-0.15, 0.76, z))
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(1.2, 0.2, 0.07), 0.03, Pal.WOOD, MeshKit.at(-0.15, 0.88, z + sz * 0.5))
		for sz in [-1.0, 1.0]:
			k.cyl(0.07, 2.3, Pal.WOOD_DARK, MeshKit.at(-0.95, 0, sz * 2.9), 8, 0.02)
		for i in 10:
			var c := Pal.SAGE if i % 2 == 0 else Pal.CREAM
			k.rbox(Vector3(0.8, 0.05, 0.6), 0.015, c, MeshKit.xf(Vector3(-0.72, 2.2, -2.7 + i * 0.6), Vector3(0, 0, -18)))
		return k.commit()), self)
	var badge := UI3D.badge("storage", Pal.STEEL_DARK, 0.7)
	badge.position = Vector3(-0.95, 2.9, 0)
	add_child(badge)
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
		var ic := UI3D.icon(ing, 0.0018)
		ic.position = Vector3(-1.2, 1.55, -2.3 + i * 1.15)
		add_child(ic)
		var l := UI3D.label("0/12", 26)
		l.position = Vector3(0.75, 0.95, -2.3 + i * 1.15 + 0.3)
		add_child(l)
		_labels[ing] = l
		i += 1
	give_zone = Zone.make(Zone.Kind.GIVE, holders(), Vector2(1.5, 5.4), "storage", Pal.SAGE)
	give_zone.position = Vector3(1.55, 0, 0)
	add_child(give_zone)
	take_zone = Zone.make(Zone.Kind.TAKE, holders(), Vector2(1.6, 1.4), "feeder", Pal.OCHRE)
	take_zone.position = Vector3(0.6, 0, 3.75)
	add_child(take_zone)


func _build_shelf() -> void:
	Mats.inst(MeshKit.cached("shelf", func():
		var k := MeshKit.new()
		var frame := Pal.STEEL_DARK
		k.rbox(Vector3(2.0, 0.2, 1.6), 0.03, frame, MeshKit.at(0, 0.1, 0))
		k.rbox(Vector3(1.9, 0.06, 1.5), 0.02, Pal.WOOD, MeshKit.at(0, 0.27, 0))
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.06, 1.6, 0.06), 0.015, frame, MeshKit.at(sx * 0.95, 0.9, sz * 0.75))
		for sz in [-1.0, 1.0]:
			k.rbox(Vector3(1.96, 0.05, 0.05), 0.015, frame, MeshKit.at(0, 1.7, sz * 0.75))
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
	h.max_visible = 60
	h.position = Vector3(0, 0.33, 0)
	add_child(h)
	h.changed.connect(_update_labels)
	bins["cookie"] = h
	var l := UI3D.label("0/24", 30)
	l.position = Vector3(0, 2.3, 0)
	add_child(l)
	_labels["cookie"] = l
	give_zone = Zone.make(Zone.Kind.GIVE, holders(), Vector2(1.4, 1.7), "collector", Pal.CREAM)
	give_zone.position = Vector3(-1.85, 0, 0)
	add_child(give_zone)
	take_zone = Zone.make(Zone.Kind.TAKE, holders(), Vector2(1.4, 1.7), "loader", Pal.TERRACOTTA)
	take_zone.position = Vector3(1.85, 0, 0)
	add_child(take_zone)
