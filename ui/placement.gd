class_name Placement
extends Control
## Build mode: a see-through ghost of the building sits in the middle of the
## screen, snapped to the grid. Drag anywhere to slide the land under it,
## pinch to zoom, Rotate to turn it, Place to build. Tiles turn green where
## it fits, red where something is in the way, amber on land you don't own.
## Line parts snap their rotation to the line they touch and show whether
## they connect. Also used to move a building you already have.

signal finished(placed: bool)

var world: World
var kind := ""
var ing := ""
var move_uid := 0
var rot := 0
var origin := Vector2i(99999, 99999)
var valid := false
var reason := ""
var _replace_uid := 0
var _ghost: Node3D
var _ghost_mi: MeshInstance3D
var _tiles: MeshInstance3D
var _arrow: MeshInstance3D
var _gmat: StandardMaterial3D
var _touches := {}
var _pinch := 0.0
var _title: Label
var _cost: Label
var _hint: Label
var _ok: JuicyButton
var _rot_btn: JuicyButton
var _cancel: JuicyButton
var _banner: PanelContainer
var _dirty := true
var _placed_any := false
var _t := 0.0
static var last_rot := 0


func setup(p_world: World, p_kind: String, p_ing := "", p_move := 0) -> Placement:
	world = p_world
	kind = p_kind
	ing = p_ing
	move_uid = p_move
	rot = last_rot
	if move_uid:
		var b := Game.building(move_uid)
		rot = int(b["rot"])
		ing = str(b.get("ing", ""))
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	# banner
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", Kit.skin("card_dark", 30, Vector4(18, 12, 22, 16)))
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	var v := Kit.vbox(2)
	_banner.add_child(v)
	var h := Kit.hbox(12)
	v.add_child(h)
	h.add_child(Kit.icon(_icon(), 54))
	var tv := Kit.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	_title = Kit.game(_name(), 28, Kit.WHITE, 6)
	tv.add_child(_title)
	_cost = Kit.game("", 22, Color(1.0, 0.88, 0.45), 5)
	tv.add_child(_cost)
	_hint = Kit.game("", 19, Color(0.92, 0.88, 0.8), 4)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 440
	v.add_child(_hint)
	# buttons
	_cancel = Kit.juicy("", Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, 22, Vector2(110, 96))
	_cancel.set_glyph("close", 44)
	_cancel.sound = "close"
	_cancel.pressed.connect(func(): finish(false))
	add_child(_cancel)
	_rot_btn = Kit.juicy("", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 22, Vector2(110, 96))
	_rot_btn.set_icon("rotate", 56)
	_rot_btn.pressed.connect(_rotate)
	add_child(_rot_btn)
	_ok = Kit.juicy("Place" if move_uid == 0 else "Move here", Kit.SAGE, Kit.SAGE_EDGE, 30, Vector2(230, 96))
	_ok.sound = ""
	_ok.pressed.connect(_confirm)
	add_child(_ok)
	# ghost in the world
	_ghost = Node3D.new()
	world.add_child(_ghost)
	_gmat = StandardMaterial3D.new()
	_gmat.vertex_color_use_as_albedo = true
	_gmat.vertex_color_is_srgb = true
	_gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_gmat.albedo_color = Color(1, 1, 1, 0.72)
	_gmat.cull_mode = BaseMaterial3D.CULL_BACK
	_ghost_mi = MeshInstance3D.new()
	_ghost_mi.mesh = Previews.mesh(kind, ing)
	_ghost_mi.material_override = _gmat
	_ghost_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.add_child(_ghost_mi)
	_tiles = MeshInstance3D.new()
	_tiles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	world.add_child(_tiles)
	_arrow = MeshInstance3D.new()
	var ak := MeshKit.new()
	ak.rbox(Vector3(0.9, 0.04, 0.22), 0.05, Color(1, 1, 1), MeshKit.at(0, 0, 0))
	ak.prism(PackedVector2Array([Vector2(0, -0.32), Vector2(0.4, 0), Vector2(0, 0.32)]), 0.05, Color(1, 1, 1), MeshKit.xf(Vector3(0.45, -0.02, 0), Vector3(90, 0, 0)))
	_arrow.mesh = ak.commit()
	_arrow.material_override = Mats.flat(Color(1.0, 0.92, 0.6, 0.95))
	_arrow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_arrow.visible = Defs.LINE_KINDS.has(kind)
	_ghost.add_child(_arrow)
	# camera: free to pan, starts on you (or on the building being moved)
	world.cam.free_focus = true
	if move_uid and world.building(move_uid):
		world.cam.global_position = world.building(move_uid).global_position
		world.building(move_uid).visible = false
	world.player.input_enabled = false
	Kit.pop_in.call_deferred(_banner)


func _icon() -> String:
	if kind == "hopper" and ing != "":
		return ing
	return Defs.BUILDINGS[kind]["icon"]


func _name() -> String:
	if kind == "hopper" and ing != "":
		return "%s Hopper" % Defs.item_name(ing)
	return Defs.BUILDINGS[kind]["name"]


func _price() -> float:
	return 0.0 if move_uid else Game.price_of(kind)


# ---------------------------------------------------------------- per frame

func _process(dt: float) -> void:
	_t += dt
	_layout()
	var c := _screen_ground(get_viewport_rect().size * Vector2(0.5, 0.46))
	var o := Grid.origin_for(c, Defs.size_of(kind), rot)
	if Defs.LINE_KINDS.has(kind):
		o = _snap(c, o)
	if o != origin or _dirty:
		origin = o
		_dirty = false
		_evaluate()
	var target := Grid.center_of(origin, Defs.size_of(kind), rot)
	_ghost.global_position = _ghost.global_position.lerp(target, clampf(dt * 18.0, 0.0, 1.0)) if _ghost.global_position.distance_to(target) < 6.0 else target
	_ghost.rotation.y = lerp_angle(_ghost.rotation.y, Grid.yaw(rot), clampf(dt * 14.0, 0.0, 1.0))
	_ghost.position.y = 0.05 + sin(_t * 4.0) * 0.04
	_arrow.position = Vector3(0, LineModule.TUBE_Y + 0.75, LineModule.TUBE_Z)


func _layout() -> void:
	var vs := get_viewport_rect().size
	var bw := minf(vs.x - 32, 560.0)
	_banner.size = Vector2(bw, 0)
	_banner.size = Vector2(bw, _banner.get_combined_minimum_size().y)
	_banner.position = Vector2((vs.x - bw) * 0.5, 104)
	var y := vs.y - 130
	_cancel.size = _cancel.custom_minimum_size
	_rot_btn.size = _rot_btn.custom_minimum_size
	_ok.size = _ok.custom_minimum_size
	var total := _cancel.size.x + _rot_btn.size.x + _ok.size.x + 32
	var x := (vs.x - total) * 0.5
	_cancel.position = Vector2(x, y)
	_rot_btn.position = Vector2(x + _cancel.size.x + 16, y)
	_ok.position = Vector2(x + _cancel.size.x + _rot_btn.size.x + 32, y)


func _screen_ground(sp: Vector2) -> Vector3:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return Vector3.ZERO
	var o := cam.project_ray_origin(sp)
	var d := cam.project_ray_normal(sp)
	if absf(d.y) < 0.001:
		return o
	return o + d * (-o.y / d.y)


# ---------------------------------------------------------------- rules

func _evaluate() -> void:
	var size := Defs.size_of(kind)
	_replace_uid = 0
	valid = true
	reason = ""
	var ignore: Array = [move_uid] if move_uid else []
	# line parts turn to join the line they touch
	if Defs.LINE_KINDS.has(kind):
		var best := rot
		var best_s := _connect_score(rot)
		if best_s == 0:
			for r in 4:
				var s := _connect_score(r)
				if s > best_s:
					best_s = s
					best = r
		rot = best
	var cells := Grid.cells(origin, size, rot)
	var owned := true
	for c in cells:
		if not Game.owns_cell(c):
			owned = false
	var blockers := world.grid.blockers(origin, size, rot)
	blockers.erase(move_uid)
	if kind == "hopper" and blockers.size() == 1:
		var bn := world.building(blockers[0])
		if bn and bn.kind == "tube" and bn.cell() == origin and bn.rot() % 2 == rot % 2:
			_replace_uid = bn.uid
			rot = bn.rot()
			blockers.clear()
	if not owned:
		valid = false
		reason = "You don't own this land yet. Tap a For Sale sign to buy it."
	elif not blockers.is_empty():
		valid = false
		reason = "Something is in the way."
	elif not Game.can_afford(_price()):
		valid = false
		reason = "Not enough money."
	_cost.text = ("$" + Fmt.num(_price())) if not move_uid else "Moving"
	_cost.modulate = Color(1, 1, 1) if Game.can_afford(_price()) else Color(1.0, 0.6, 0.5)
	_hint.text = reason if reason != "" else _advice()
	_paint_tiles(cells, blockers)
	_gmat.albedo_color = Color(1, 1, 1, 0.75) if valid else Color(1.0, 0.55, 0.5, 0.6)
	_ok.set_colors(Kit.SAGE if valid else Kit.GREY, Kit.SAGE_EDGE if valid else Kit.GREY_EDGE)


## Line parts snap onto a nearby tube (hoppers) or to an open line end.
func _snap(c: Vector3, o: Vector2i) -> Vector2i:
	var best := o
	var best_d := 3.2
	for n in world.bnodes.values():
		if not n is LineModule or n.uid == move_uid:
			continue
		var m := n as LineModule
		if kind == "hopper" and m is TubeB:
			var d := Vector2(m.global_position.x - c.x, m.global_position.z - c.z).length()
			if d < best_d:
				best_d = d
				best = m.cell()
				rot = m.rot()
		# the open end of a line (no neighbour after it)
		if not m is OvenB and world.next_module(m) == null and kind != "mixer":
			var r := m.rot()
			var sz := Defs.size_of(kind)
			var half := sz.x * Grid.CELL * 0.5
			var center := m.tube_end() + m.flow_dir() * half
			center = center - Basis(Vector3.UP, Grid.yaw(r)) * Vector3(0, LineModule.TUBE_Y, LineModule.TUBE_Z)
			var d2 := Vector2(center.x - c.x, center.z - c.z).length()
			if d2 < best_d:
				best_d = d2
				best = Grid.origin_for(center, sz, r)
				rot = r
	return best


## Buildings the ghost would touch (they'll pass things along by chute).
func _neighbours() -> Array[String]:
	var out: Array[String] = []
	var sz := Grid.rotated(Defs.size_of(kind), rot)
	var seen := {}
	for x in range(-1, sz.x + 1):
		for y in range(-1, sz.y + 1):
			var u := world.grid.at(origin + Vector2i(x, y))
			if u != 0 and u != move_uid and u != _replace_uid and not seen.has(u):
				seen[u] = true
				var n := world.building(u)
				if n and not n is LineModule or n is OvenB:
					out.append(n.def["name"])
	return out


## How this spot fits: line joins, biome bonuses, auras.
func _advice() -> String:
	var nb := _neighbours()
	var chute := ""
	if not nb.is_empty() and not Defs.LINE_KINDS.has(kind) or (kind == "oven" and not nb.is_empty()):
		chute = "  Touching %s: they hand things over by chute." % ", ".join(nb.slice(0, 2))
	return _advice_base() + chute


func _advice_base() -> String:
	var center := Grid.center_of(origin, Defs.size_of(kind), rot)
	var d: Dictionary = Defs.BUILDINGS[kind]
	if Defs.LINE_KINDS.has(kind):
		var s := _connect_score(rot)
		var txt := "Line: Mixer -> Tubes / Hoppers -> Oven, end to end. "
		if _replace_uid:
			return "Replaces the tube here. " + txt
		if s > 0:
			return "Connects to the line here!"
		return txt + "Not touching a line here."
	if d["cat"] == "farm":
		var b := Terrain.biome_at(center)
		if Defs.BIOMES[b]["bonus"].has(d["crop"]):
			return "%s: this farm grows 40%% faster here!" % Defs.BIOMES[b]["name"]
		var fav := []
		for k in Defs.BIOMES:
			if Defs.BIOMES[k]["bonus"].has(d["crop"]):
				fav.append(Defs.BIOMES[k]["name"])
		return "Grows 40%% faster on %s land." % " or ".join(fav)
	return str(d["desc"])


## 0..2: how many line ends this module would join with rotation r.
func _connect_score(r: int) -> int:
	var size := Defs.size_of(kind)
	var c := Grid.center_of(origin, size, r)
	var basis := Basis(Vector3.UP, Grid.yaw(r))
	var half := size.x * Grid.CELL * 0.5
	var dir := basis.x
	var start := c + basis * Vector3(-half, LineModule.TUBE_Y, LineModule.TUBE_Z)
	var end := c + basis * Vector3(half, LineModule.TUBE_Y, LineModule.TUBE_Z)
	var s := 0
	if kind != "mixer":
		var a: Building = world.building(world.grid.at(Grid.cell_of(start - dir * 0.5)))
		if a is LineModule and a.uid != move_uid and a.rot() == r and (a as LineModule).tube_end().distance_to(start) < 0.3 and not a is OvenB:
			s += 1
	if kind != "oven":
		var b: Building = world.building(world.grid.at(Grid.cell_of(end + dir * 0.5)))
		if b is LineModule and b.uid != move_uid and b.rot() == r and (b as LineModule).tube_start().distance_to(end) < 0.3 and not b is MixerB:
			s += 1
	return s


func _paint_tiles(cells: Array[Vector2i], blockers: Array[int]) -> void:
	var k := MeshKit.new()
	# decor shows the area its effect reaches
	var aura: Dictionary = Defs.BUILDINGS[kind].get("aura", {})
	if int(aura.get("r", 0)) > 0:
		var r := int(aura["r"])
		var s0 := Grid.rotated(Defs.size_of(kind), rot)
		for x in range(-r, s0.x + r):
			for y in range(-r, s0.y + r):
				var ac := origin + Vector2i(x, y)
				if x >= 0 and y >= 0 and x < s0.x and y < s0.y:
					continue
				var ap := Grid.cell_center(ac)
				k.rbox(Vector3(Grid.CELL - 0.5, 0.02, Grid.CELL - 0.5), 0.2, Color(1.0, 0.9, 0.55, 0.22), MeshKit.at(ap.x, 0.04, ap.z))
	for c in cells:
		var col := Color(0.55, 0.85, 0.5, 0.55)
		if not Game.owns_cell(c):
			col = Color(0.95, 0.7, 0.3, 0.55)
		elif world.grid.at(c) != 0 and blockers.has(world.grid.at(c)):
			col = Color(0.95, 0.4, 0.35, 0.6)
		var p := Grid.cell_center(c)
		k.rbox(Vector3(Grid.CELL - 0.16, 0.03, Grid.CELL - 0.16), 0.12, col, MeshKit.at(p.x, 0.06, p.z))
	_tiles.mesh = k.commit()
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.render_priority = 1
	_tiles.material_override = m


# ---------------------------------------------------------------- input

func _gui_input(e: InputEvent) -> void:
	if e is InputEventScreenTouch:
		if e.pressed:
			_touches[e.index] = e.position
		else:
			_touches.erase(e.index)
		_pinch = 0.0
		accept_event()
	elif e is InputEventScreenDrag:
		if not _touches.has(e.index):
			return
		var prev: Vector2 = _touches[e.index]
		_touches[e.index] = e.position
		if _touches.size() == 1:
			var a := _screen_ground(prev)
			var b := _screen_ground(e.position)
			world.cam.global_position += (a - b) * Vector3(1, 0, 1)
		elif _touches.size() == 2:
			var ps: Array = _touches.values()
			var dd: float = (ps[0] as Vector2).distance_to(ps[1])
			if _pinch > 0.0:
				world.cam.zoom = clampf(world.cam.zoom * _pinch / dd, 0.6, 2.2)
			_pinch = dd
		accept_event()
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			world.cam.zoom = clampf(world.cam.zoom - 0.08, 0.6, 2.2)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			world.cam.zoom = clampf(world.cam.zoom + 0.08, 0.6, 2.2)
	elif e is InputEventMagnifyGesture:
		world.cam.zoom = clampf(world.cam.zoom / e.factor, 0.6, 2.2)


func _unhandled_key_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed:
		match e.keycode:
			KEY_R: _rotate()
			KEY_ENTER, KEY_SPACE: _confirm()
			KEY_ESCAPE: finish(false)


func _rotate() -> void:
	rot = (rot + 1) % 4
	last_rot = rot
	_dirty = true
	Sfx.play("click", 0.0, 1.2)


func _confirm() -> void:
	_evaluate()
	if not valid:
		Sfx.play("deny")
		Kit.shake(_ok)
		Kit.bounce(_banner, 0.04)
		return
	if move_uid:
		Game.move(move_uid, origin, rot)
		Sfx.play("upgrade", -4.0)
		finish(true)
		return
	var extra := {}
	if kind == "hopper":
		extra["ing"] = ing
	if kind == "palace":
		extra["stage"] = 0
	if _replace_uid:
		Game.remove(_replace_uid, true)
	var b := Game.place(kind, origin, rot, extra)
	if b.is_empty():
		Sfx.play("deny")
		return
	_placed_any = true
	last_rot = rot
	Kit.bounce(_ok, 0.12)
	# keep placing cheap repeatable things (tubes, hoppers, decor)
	var again: bool = kind in ["tube", "hopper"] or (Defs.BUILDINGS[kind]["cat"] == "decor" and kind != "palace" and kind != "statue")
	if again and Game.can_afford(Game.price_of(kind)):
		_dirty = true
		return
	finish(true)


func finish(placed: bool) -> void:
	if move_uid and world.building(move_uid):
		world.building(move_uid).visible = true
	if is_instance_valid(_ghost):
		_ghost.queue_free()
	if is_instance_valid(_tiles):
		_tiles.queue_free()
	world.cam.free_focus = false
	world.player.input_enabled = true
	finished.emit(placed or _placed_any)
	queue_free()
