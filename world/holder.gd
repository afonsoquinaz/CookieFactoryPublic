class_name Holder
extends Node3D
## A place that holds items: a character's carry stack, a farm crate, a
## hopper, a shelf, a truck. Data is a list of item types; the visual is one
## mesh per item (up to max_visible) laid out as a column or a grid.
##
## Items move between holders with Holder.fly(): the item leaves the source
## at once, flies along an arc, and lands in the target (which reserves room
## for it via `incoming` meanwhile).

signal changed
signal landed(t: String)

enum Layout { COLUMN, GRID, NONE }

var capacity := 10
var accepts: Array = []          # item types allowed (empty = anything)
var items: Array[String] = []
var incoming := 0
var layout := Layout.COLUMN
var grid := Vector2i(3, 3)       # GRID: columns (x) x rows (z) per layer
var cell := Vector2(0.44, 0.44)
var max_visible := 60
var sway := 0.0                  # COLUMN: lateral lag when the carrier moves
var label_name := ""

var _nodes: Array[Node3D] = []
var _mm := {}                    # GRID: item type -> MultiMeshInstance3D (one draw per type)
var _dirty := false
var _sway_v := Vector3.ZERO
var _last_pos := Vector3.ZERO


func setup(cap: int, p_accepts: Array = [], p_layout := Layout.COLUMN) -> Holder:
	capacity = cap
	accepts = p_accepts
	layout = p_layout
	return self


func count() -> int:
	return items.size()


func count_of(t: String) -> int:
	var n := 0
	for i in items:
		if i == t:
			n += 1
	return n


func space() -> int:
	return capacity - items.size() - incoming


func is_full() -> bool:
	return space() <= 0


func can_accept(t: String) -> bool:
	return space() > 0 and (accepts.is_empty() or accepts.has(t))


func has(t: String) -> bool:
	return items.has(t) if t != "" else items.size() > 0


## Adds an item (data + visual).
func add(t: String, animate := true) -> void:
	items.append(t)
	if layout == Layout.GRID:
		_dirty = true
		if animate:
			_bump()
		changed.emit()
		return
	if layout != Layout.NONE and _nodes.size() < max_visible:
		var n := Items.node(t)
		add_child(n)
		_nodes.append(n)
		n.transform = slot_transform(_nodes.size() - 1)
		if animate:
			n.scale = Vector3(1.3, 0.6, 1.3)
			var tw := n.create_tween()
			tw.tween_property(n, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	changed.emit()


## Removes the top-most item of type t ("" = the top item). Returns its type.
func take(t := "") -> String:
	if items.is_empty():
		return ""
	var idx := items.size() - 1
	if t != "":
		idx = items.rfind(t)
		if idx < 0:
			return ""
	var got := items[idx]
	items.remove_at(idx)
	if layout == Layout.GRID:
		_dirty = true
		changed.emit()
		return got
	if idx < _nodes.size():
		var n := _nodes[idx]
		_nodes.remove_at(idx)
		n.queue_free()
		# items above slide down into place
		for k in range(idx, _nodes.size()):
			var tw := _nodes[k].create_tween()
			tw.tween_property(_nodes[k], "transform", slot_transform(k), 0.12)
	# refill visuals beyond max_visible
	while _nodes.size() < mini(items.size(), max_visible) and layout != Layout.NONE:
		var n2 := Items.node(items[_nodes.size()])
		add_child(n2)
		_nodes.append(n2)
		n2.transform = slot_transform(_nodes.size() - 1)
	changed.emit()
	return got


## Rebuilds the item visuals (e.g. after the cookie mesh changed).
func refresh_visuals() -> void:
	for t in _mm:
		_mm[t].queue_free()
	_mm.clear()
	_dirty = layout == Layout.GRID
	if layout == Layout.COLUMN:
		for k in _nodes.size():
			_nodes[k].queue_free()
		_nodes.clear()
		for k in mini(items.size(), max_visible):
			var n := Items.node(items[k])
			add_child(n)
			_nodes.append(n)
			n.transform = slot_transform(k)


func clear_all() -> void:
	items.clear()
	_dirty = true
	for n in _nodes:
		n.queue_free()
	_nodes.clear()
	changed.emit()


## Local transform of visual slot i.
func slot_transform(i: int) -> Transform3D:
	match layout:
		Layout.COLUMN:
			var y := 0.0
			for k in mini(i, items.size()):
				y += Items.height(items[k])
			if i >= items.size() and items.size() > 0:
				pass
			var rot := Basis(Vector3.UP, (float((i * 37) % 11) - 5.0) * 0.012)
			return Transform3D(rot, Vector3(0, y, 0))
		Layout.GRID:
			var per := grid.x * grid.y
			var layer := i / per
			var r := i % per
			var gx := r % grid.x
			var gz := r / grid.x
			var x := (gx - (grid.x - 1) * 0.5) * cell.x
			var z := (gz - (grid.y - 1) * 0.5) * cell.y
			var h := Items.height(items[i]) if i < items.size() else 0.2
			return Transform3D(Basis(Vector3.UP, (float((i * 53) % 7) - 3.0) * 0.03), Vector3(x, layer * h, z))
	return Transform3D.IDENTITY


## World position where the next item would land.
func next_slot_global() -> Vector3:
	var i := mini(items.size() + incoming, max_visible - 1)
	if layout == Layout.NONE:
		return global_position
	if layout == Layout.COLUMN:
		var y := 0.0
		for k in items.size():
			y += Items.height(items[k])
		y += incoming * 0.2
		return global_transform * Vector3(0, y, 0)
	return global_transform * slot_transform(i).origin


## World position of the top-most item of type t.
func item_global(t := "") -> Vector3:
	var idx := items.size() - 1 if t == "" else items.rfind(t)
	if layout == Layout.GRID and idx >= 0:
		return global_transform * slot_transform(mini(idx, max_visible - 1)).origin
	if idx >= 0 and idx < _nodes.size():
		return _nodes[idx].global_position
	return global_position + Vector3(0, 0.3, 0)


func _bump() -> void:
	var tw := create_tween()
	scale = Vector3(1.04, 0.94, 1.04)
	tw.tween_property(self, "scale", Vector3.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _rebuild_mm() -> void:
	_dirty = false
	var per := {}
	for i in mini(items.size(), max_visible):
		var t := items[i]
		if not per.has(t):
			per[t] = []
		per[t].append(slot_transform(i))
	for t in _mm.keys():
		if not per.has(t):
			_mm[t].queue_free()
			_mm.erase(t)
	for t in per:
		var mmi: MultiMeshInstance3D = _mm.get(t)
		if mmi == null:
			mmi = MultiMeshInstance3D.new()
			mmi.material_override = Mats.toon()
			mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			var mm := MultiMesh.new()
			mm.transform_format = MultiMesh.TRANSFORM_3D
			mm.mesh = Items.mesh(t)
			mmi.multimesh = mm
			add_child(mmi)
			_mm[t] = mmi
		var xs: Array = per[t]
		var m: MultiMesh = mmi.multimesh
		if m.instance_count < xs.size() or m.instance_count > xs.size() + 16:
			m.instance_count = xs.size() + 8
		m.visible_instance_count = xs.size()
		for k in xs.size():
			m.set_instance_transform(k, xs[k])


func _process(dt: float) -> void:
	if _dirty:
		_rebuild_mm()
	if sway <= 0.0 or _nodes.is_empty():
		return
	# carried stacks lean against the motion and wobble back
	var p := global_position
	var vel := (p - _last_pos) / maxf(dt, 0.001)
	_last_pos = p
	var target := -vel * sway
	target.y = 0
	_sway_v = _sway_v.lerp(target, clampf(dt * 6.0, 0.0, 1.0))
	var local := global_transform.basis.inverse() * _sway_v
	for k in _nodes.size():
		var f := float(k) / maxf(1.0, _nodes.size())
		var base := slot_transform(k)
		base.origin += Vector3(local.x, 0, local.z) * f * f * 0.5
		_nodes[k].transform = base


# ---------------------------------------------------------------- transfers

## Moves one item of type t from `from` to `to` with a flying arc.
## Returns false if nothing could move.
static func fly(from: Holder, to: Holder, t := "", dur := 0.32, on_land := Callable()) -> bool:
	if t == "":
		if from.items.is_empty():
			return false
		t = from.items[from.items.size() - 1]
	if not from.has(t) or not to.can_accept(t):
		return false
	var start := from.item_global(t)
	from.take(t)
	to.incoming += 1
	var local_end := to.to_local(to.next_slot_global())
	var flyer := Items.node(t)
	var root: Node = from.get_tree().current_scene if from.get_tree().current_scene else from.get_tree().root
	root.add_child(flyer)
	flyer.global_position = start
	var rise := 0.8 + start.distance_to(to.global_transform * local_end) * 0.15
	var step := func(f: float) -> void:
		if not is_instance_valid(flyer) or not is_instance_valid(to):
			return
		var e: Vector3 = to.global_transform * local_end
		var peak := maxf(start.y, e.y) + rise
		var p := start.lerp(e, f)
		p.y = lerpf(lerpf(start.y, peak, f), lerpf(peak, e.y, f), f)
		flyer.global_position = p
		flyer.rotation.y = f * PI
		var sc := 1.0 + sin(f * PI) * 0.25
		flyer.scale = Vector3(sc, sc, sc)
	var land := func() -> void:
		flyer.queue_free()
		if is_instance_valid(to):
			to.incoming -= 1
			to.add(t)
			to.landed.emit(t)
			if on_land.is_valid():
				on_land.call(t)
	var tw := flyer.create_tween()
	tw.tween_method(step, 0.0, 1.0, dur)
	tw.tween_callback(land)
	return true
