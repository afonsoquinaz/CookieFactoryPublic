class_name HallB
extends StorageB
## The Cookie Hall: the heart of the empire. Every road leads here. It
## stores anything (ingredients, cookies, boxes) so porters always have
## somewhere to put things, houses the first porters (they rest on its
## benches), and its level unlocks the rest of the game. It gets a new look
## at Hall 3, 6, 9 and 12, and another pennant on the roof every level.

var _shown_level := -1


func _build() -> void:
	store = Holder.new().setup(30, [], Holder.Layout.NONE)
	store.position = Vector3(0, 1.0, 0.5)
	add_child(store)
	add_port(store, null, "in")
	add_port(store, null, "out")
	_label = UI3D.label("", 26)
	_label.visible = false
	add_child(_label)


func refresh() -> void:
	level = int(data["lvl"])
	if level != _shown_level:
		var first := _shown_level < 0
		var old_tier := tier
		_shown_level = level
		tier = Bal.tier(kind, level)
		if visual:
			visual.queue_free()
		visual = Node3D.new()
		visual.name = "Visual"
		add_child(visual)
		_visual(visual, tier)
		if not first and tier != old_tier:
			celebrate()
	_on_level()
	changed.emit()


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("hall_%d_%d" % [t, level], func(): return TownArt.hall(t, level)), root)


func solid_rects() -> Array[Rect2]:
	return [Rect2(-3.7, -3.8, 7.4, 5.4)]


func _on_level() -> void:
	store.capacity = Bal.hall_store(level)


## The Hall takes anything, but only as a last resort.
func need(t: String) -> float:
	if not store.can_accept(t):
		return 0.0
	return 0.05 * (1.0 - float(store.count()) / maxf(1.0, store.capacity))


## Bench seats in front where resting staff sit.
func seat(i: int) -> Vector3:
	var side := -1.0 if i % 2 == 0 else 1.0
	var k := (i / 2) % 3
	return to_world(side * (2.0 + k * 0.5), 2.3 + 0.45)


func status() -> String:
	return Defs.level_title(level)


func info() -> Array:
	var out := [
		["hall", "Level %d of %d: %s" % [level, Defs.HALL.size(), Defs.level_title(level)]],
		["hire", "Houses %d staff" % Bal.hall_staff(level)],
		["storage", "Storage %d / %d" % [store.count(), store.capacity]],
	]
	var counts := {}
	for t in store.items:
		counts[t] = int(counts.get(t, 0)) + 1
	var keys := counts.keys()
	keys.sort_custom(func(a, b): return counts[a] > counts[b])
	for i in mini(4, keys.size()):
		out.append([Defs.item_icon(keys[i]), "%s × %d" % [Defs.item_name(keys[i]), counts[keys[i]]]])
	return out


func upgrade_info() -> Array:
	var n := level + 1
	var out := [["Storage", str(Bal.hall_store(level)), str(Bal.hall_store(n))],
		["Staff housed", str(Bal.hall_staff(level)), str(Bal.hall_staff(n))]]
	return out


## What the next Hall level unlocks: [[icon, text], ...]
static func unlocks_at(lvl: int) -> Array:
	var out := []
	for k in Defs.BUILD_ORDER:
		var d: Dictionary = Defs.BUILDINGS[k]
		if int(d["hall"]) == lvl:
			out.append([d["icon"], "New: %s" % d["name"]])
		elif d.has("n") and (d["n"] as Array).find(lvl) > 0:
			out.append([d["icon"], "+1 %s" % d["name"]])
	return out
