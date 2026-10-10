class_name StorageB
extends Building
## Pantry (any ingredients) and Cookie Rack (cookies, boxes, gifts): buffers
## near where things are made or sold, so porters keep things moving.

var store: Holder
var _label: Label3D


func _build() -> void:
	var pantry := kind == "pantry"
	store = Holder.new().setup(30, [], Holder.Layout.GRID)
	store.accept_cat = ["raw", "proc"] if pantry else ["cookie", "box", "gift"]
	store.grid = Vector2i(4, 2)
	store.cell = Vector2(0.44, 0.4)
	store.max_visible = 48
	store.position = Vector3(0, 0.62, -0.2)
	add_child(store)
	add_port(store, null, "in")
	add_port(store, null, "out")
	_label = UI3D.label("0/30", 28)
	_label.position = Vector3(0, 3.2, -0.6)
	add_child(_label)
	var b := UI3D.badge(def["icon"], Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 3.8, -0.6)
	add_child(b)
	store.changed.connect(_update)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -2.0, 4.0, 2.8)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("%s_%d" % [kind, t], func(): return StorageB.mesh(kind, t)), root)


func _on_level() -> void:
	store.capacity = Bal.pantry_cap(level) if kind == "pantry" else Bal.rack_cap(level)
	_update()


func _update() -> void:
	_label.text = "%d/%d" % [store.count(), store.capacity]


## Storage wants anything it accepts, but only a little (real consumers first).
func need(t: String) -> float:
	if not store.can_accept(t):
		return 0.0
	return 0.12 * (1.0 - float(store.count()) / maxf(1.0, store.capacity))


func save_contents() -> Dictionary:
	return {"store": store.items.duplicate()}


func load_contents(d: Dictionary) -> void:
	Building.fill(store, d.get("store", []))


func info() -> Array:
	var counts := {}
	for t in store.items:
		counts[t] = int(counts.get(t, 0)) + 1
	var out := [["storage", "Holds %d / %d" % [store.count(), store.capacity]]]
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	for i in mini(4, keys.size()):
		out.append([Defs.item_icon(keys[i]), "%s × %d" % [Defs.item_name(keys[i]), counts[keys[i]]]])
	return out


func upgrade_info() -> Array:
	if kind == "pantry":
		return [["Holds", str(Bal.pantry_cap(level)), str(Bal.pantry_cap(level + 1))]]
	return [["Holds", str(Bal.rack_cap(level)), str(Bal.rack_cap(level + 1))]]


## Low platform for the stock in front + shelving behind, richer per tier.
static func mesh(k_: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var pantry := k_ == "pantry"
	var wood: Color = [Pal.WOOD, Pal.WOOD, Pal.WOOD_DARK, Pal.STEEL_DARK, Color(0.3, 0.2, 0.15)][t]
	var light: Color = [Pal.WOOD_LIGHT, Pal.WOOD_LIGHT, Pal.CREAM, Pal.STEEL, Pal.CREAM][t]
	# stock platform
	k.rbox(Vector3(2.2, 0.5, 1.2), 0.05, wood, MeshKit.at(0, 0.25, -0.2))
	k.rbox(Vector3(2.1, 0.06, 1.1), 0.02, light, MeshKit.at(0, 0.53, -0.2))
	# shelving unit behind
	var h := 2.0 + t * 0.2
	k.rbox(Vector3(3.6, h, 0.6), 0.06, wood, MeshKit.at(0, h * 0.5, -1.55))
	for i in 3:
		var y := 0.5 + i * (h - 0.6) / 2.0
		k.rbox(Vector3(3.4, 0.06, 0.5), 0.02, light, MeshKit.at(0, y, -1.3))
		for j in 6:
			var x := -1.4 + j * 0.56
			if pantry:
				if (i + j) % 2 == 0:
					k.cyl(0.11, 0.26, Color(0.85, 0.9, 0.9, 0.55), MeshKit.at(x, y + 0.03, -1.3), 8, 0.02)
					k.cyl(0.115, 0.04, Pal.BRASS if t >= 3 else Pal.WOOD_DARK, MeshKit.at(x, y + 0.29, -1.3), 8)
				else:
					k.ellipsoid(Vector3(0.16, 0.16, 0.13), Color(0.86, 0.8, 0.66), MeshKit.at(x, y + 0.15, -1.3), 8, 5)
			else:
				k.rbox(Vector3(0.44, 0.03, 0.36), 0.01, Pal.STEEL_DARK if t < 4 else Pal.BRASS, MeshKit.at(x, y + 0.03, -1.3))
				for c in 3:
					Items.cookie_into(k, ["choc", "sugar", "butter", "jam"][(i + j + c) % 4], 0.06, 0.03, MeshKit.at(x - 0.12 + c * 0.12, y + 0.05, -1.3))
	# awning / crown per tier
	if t >= 1:
		for i in 8:
			var c2 := (Pal.SAGE if pantry else Pal.TERRACOTTA) if i % 2 == 0 else Pal.CREAM
			k.rbox(Vector3(0.48, 0.05, 0.7), 0.015, c2, MeshKit.xf(Vector3(-1.68 + i * 0.48, h + 0.2, -1.2), Vector3(-18, 0, 0)))
	if t >= 2:
		for sx in [-1.0, 1.0]:
			k.cyl(0.06, h + 0.3, wood, MeshKit.at(sx * 1.8, 0, -0.95), 8, 0.02)
	if t >= 3:
		k.rbox(Vector3(3.7, 0.12, 0.7), 0.03, Pal.STEEL_DARK, MeshKit.at(0, h + 0.05, -1.55))
		for sx in [-1.0, 1.0]:
			k.sphere(0.12, Color(1.0, 0.92, 0.7, 0.4), MeshKit.at(sx * 1.5, h + 0.45, -1.0), 8, 5)
	if t >= 4:
		k.rbox(Vector3(1.2, 0.5, 0.08), 0.08, Pal.BRASS, MeshKit.at(0, h + 0.75, -1.55))
		k.rbox(Vector3(1.0, 0.36, 0.09), 0.06, Pal.CHOCO, MeshKit.at(0, h + 0.75, -1.55))
	return k.commit()
