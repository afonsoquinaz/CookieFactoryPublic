class_name StorageB
extends Building
## Supply Depot: a buffer for any hardware or resources near where it's
## used, so couriers keep things moving.

var store: Holder
var _label: Label3D


func _build() -> void:
	store = Holder.new().setup(30, [], Holder.Layout.GRID)
	store.accept_cat = ["raw", "proc"]
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
	store.capacity = Bal.depot_cap(level)
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
	return [["Holds", str(Bal.depot_cap(level)), str(Bal.depot_cap(level + 1))]]


## Low platform for the stock in front + racking behind, richer per tier:
## crates and canisters.
static func mesh(k_: String, t: int) -> Mesh:
	var k := MeshKit.new()
	var depot := k_ == "depot"
	var frame: Color = [Pal.WOOD, Color(0.36, 0.38, 0.42), Color(0.92, 0.93, 0.94), Color(0.5, 0.54, 0.6), Color(0.17, 0.18, 0.21)][t]
	var light: Color = [Pal.WOOD_LIGHT, Color(0.72, 0.74, 0.78), Color(0.84, 0.86, 0.88), Color(0.72, 0.76, 0.82), Color(0.3, 0.32, 0.36)][t]
	var accent := Color(0.96, 0.7, 0.3) if depot else Color(0.4, 0.82, 0.98)
	# stock platform
	k.rbox(Vector3(2.2, 0.5, 1.2), 0.05, frame, MeshKit.at(0, 0.25, -0.2))
	k.rbox(Vector3(2.1, 0.06, 1.1), 0.02, light, MeshKit.at(0, 0.53, -0.2))
	if t >= 2:
		k.rbox(Vector3(2.0, 0.03, 0.03), 0.01, Items.lit(accent, 0.45), MeshKit.at(0, 0.4, 0.41))
	# racking behind
	var h := 2.0 + t * 0.2
	k.rbox(Vector3(3.6, h, 0.6), 0.06, frame, MeshKit.at(0, h * 0.5, -1.55))
	for i in 3:
		var y := 0.5 + i * (h - 0.6) / 2.0
		k.rbox(Vector3(3.4, 0.06, 0.5), 0.02, light, MeshKit.at(0, y, -1.3))
		for j in 6:
			var x := -1.4 + j * 0.56
			if depot:
				var ing: String = Defs.RAW[(i * 6 + j) % Defs.RAW.size()]
				if (i + j) % 2 == 0:
					Items.resource_into(k, ing, MeshKit.at(x, y + 0.03, -1.3))
				else:
					k.rbox(Vector3(0.42, 0.3, 0.36), 0.03, Pal.WOOD_LIGHT if t < 2 else Color(0.86, 0.88, 0.9), MeshKit.at(x, y + 0.18, -1.3))
					k.rbox(Vector3(0.12, 0.12, 0.01), 0.02, Defs.item_color(ing), MeshKit.at(x, y + 0.2, -1.115))
			else:
				# storage blades with status lights and a token or two on the shelf
				k.rbox(Vector3(0.46, 0.34, 0.4), 0.03, Color(0.2, 0.21, 0.24) if t != 2 else Color(0.9, 0.91, 0.92), MeshKit.at(x, y + 0.2, -1.35))
				for c in 3:
					k.rbox(Vector3(0.04, 0.04, 0.01), 0.01, Items.lit([Color(0.4, 0.9, 1.0), Color(0.5, 1.0, 0.6), Color(1.0, 0.8, 0.4)][(i + j + c) % 3], 0.4), MeshKit.at(x - 0.12 + c * 0.08, y + 0.3, -1.145))
				Items.token_into(k, ["pico", "chat7", "code13", "wiki13"][(i + j) % 4], 0.06, 0.03, MeshKit.at(x + 0.12, y + 0.06, -1.12))
	# canopy / crown per tier
	if t >= 1:
		k.rbox(Vector3(3.8, 0.08, 1.0), 0.03, frame.darkened(0.1), MeshKit.xf(Vector3(0, h + 0.2, -1.2), Vector3(-10, 0, 0)))
		k.rbox(Vector3(3.8, 0.05, 0.06), 0.02, accent, MeshKit.xf(Vector3(0, h + 0.16, -0.72), Vector3(-10, 0, 0)))
	if t >= 2:
		for sx in [-1.0, 1.0]:
			k.cyl(0.06, h + 0.3, frame.darkened(0.15), MeshKit.at(sx * 1.8, 0, -0.95), 8, 0.02)
	if t >= 3:
		for sx in [-1.0, 1.0]:
			k.sphere(0.12, Items.lit(accent.lightened(0.3), 0.4), MeshKit.at(sx * 1.5, h + 0.45, -1.0), 8, 5)
	if t >= 4:
		k.rbox(Vector3(1.2, 0.5, 0.08), 0.08, Pal.BRASS, MeshKit.at(0, h + 0.75, -1.55))
		k.rbox(Vector3(1.0, 0.36, 0.09), 0.06, Color(0.12, 0.12, 0.14), MeshKit.at(0, h + 0.75, -1.55))
		k.rbox(Vector3(0.7, 0.08, 0.02), 0.02, Items.lit(accent, 0.45), MeshKit.at(0, h + 0.75, -1.5))
	return k.commit()
