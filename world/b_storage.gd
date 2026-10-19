class_name StorageB
extends Building
## Supply Depot: a buffer for any hardware or resources near where it's
## used, so couriers keep things moving.

var store: Holder
var _label: Label3D
var _badge: Node3D


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
	_badge = UI3D.badge(def["icon"], Pal.STEEL_DARK, 0.6)
	_badge.position = Vector3(0, 3.8, -0.6)
	add_child(_badge)
	store.changed.connect(_update)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-2.0, -2.0, 4.0, 2.8)]


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("%s_%d" % [kind, t], func(): return StorageB.mesh(kind, t)), root)
	# the count and icon float above the roof
	var y := maxf(3.2, LabArt.depot_height(t) + 0.4)
	_label.position.y = y
	_badge.position.y = y + 0.6


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


## The depot's look for tier t (LabArt.depot: tarp heap, pallet racking,
## logistics shed, automated high-bay, robotic vault). The stock platform's
## top sits at 0.56 m under the holder.
static func mesh(_k: String, t: int) -> Mesh:
	return LabArt.depot(t)
