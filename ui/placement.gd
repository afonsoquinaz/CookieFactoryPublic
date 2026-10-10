class_name Placement
extends Control
## Build mode: a see-through ghost of the building sits in the middle of the
## screen, snapped to the grid. Drag anywhere to slide the land under it,
## pinch to zoom, Rotate to turn it, Place to build. Tiles turn green where
## it fits, red where something is in the way, amber on land you don't own.
## An arrow marks its entrance, and cobbles preview the road that will be
## built from it to the nearest road. Also used to move a building.

signal finished(placed: bool)

var world: World
var kind := ""
var move_uid := 0
var rot := 0
var origin := Vector2i(99999, 99999)
var valid := false
var reason := ""
var _ghost: Node3D
var _ghost_mi: MeshInstance3D
var _tiles: MeshInstance3D
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


func setup(p_world: World, p_kind: String, p_move := 0) -> Placement:
	world = p_world
	kind = p_kind
	move_uid = p_move
	rot = last_rot
	if move_uid:
		rot = int(Game.building(move_uid)["rot"])
	return self


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_banner = PanelContainer.new()
	_banner.add_theme_stylebox_override("panel", Kit.skin("card_dark", 30, Vector4(18, 12, 22, 16)))
	_banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_banner)
	var v := Kit.vbox(2)
	_banner.add_child(v)
	var h := Kit.hbox(12)
	v.add_child(h)
	h.add_child(Kit.icon(Defs.BUILDINGS[kind]["icon"], 54))
	var tv := Kit.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(tv)
	_title = Kit.game(Defs.BUILDINGS[kind]["name"], 28, Kit.WHITE, 6)
	tv.add_child(_title)
	_cost = Kit.game("", 21, Color(1.0, 0.88, 0.45), 5)
	tv.add_child(_cost)
	_hint = Kit.game("", 18, Color(0.92, 0.88, 0.8), 4)
	_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_hint.custom_minimum_size.x = 440
	v.add_child(_hint)
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
	_ghost = Node3D.new()
	world.add_child(_ghost)
	_gmat = StandardMaterial3D.new()
	_gmat.vertex_color_use_as_albedo = true
	_gmat.vertex_color_is_srgb = true
	_gmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_gmat.albedo_color = Color(1, 1, 1, 0.72)
	_ghost_mi = MeshInstance3D.new()
	_ghost_mi.mesh = Previews.mesh(kind, "", 0)
	_ghost_mi.material_override = _gmat
	_ghost_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ghost.add_child(_ghost_mi)
	_tiles = MeshInstance3D.new()
	_tiles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.render_priority = 1
	_tiles.material_override = m
	world.add_child(_tiles)
	if move_uid and world.building(move_uid):
		world.cam.fly_to(world.building(move_uid).global_position, -1.0, 0.3)
		world.building(move_uid).visible = false
	Kit.pop_in.call_deferred(_banner)


func _price_text() -> String:
	if move_uid:
		return "Moving"
	var gp := Game.gem_price_of(kind)
	var t := Game.build_time_of(kind)
	var s := ("%d gems" % gp) if gp > 0 else ("$" + Fmt.num(Game.price_of(kind)))
	if t > 0.0:
		s += "  ·  builds in %s" % Fmt.time(t)
	return s


func _process(dt: float) -> void:
	_t += dt
	_layout()
	var c := world.cam.ground_at(get_viewport_rect().size * Vector2(0.5, 0.45))
	var o := Grid.origin_for(c, Defs.size_of(kind), rot)
	if o != origin or _dirty:
		origin = o
		_dirty = false
		_evaluate()
	var target := Grid.center_of(origin, Defs.size_of(kind), rot)
	_ghost.global_position = _ghost.global_position.lerp(target, clampf(dt * 18.0, 0.0, 1.0)) if _ghost.global_position.distance_to(target) < 6.0 else target
	_ghost.rotation.y = lerp_angle(_ghost.rotation.y, Grid.yaw(rot), clampf(dt * 14.0, 0.0, 1.0))
	_ghost.position.y = 0.05 + sin(_t * 4.0) * 0.04


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


# ---------------------------------------------------------------- rules

func _evaluate() -> void:
	var spot := world.check_spot(kind, origin, rot, move_uid)
	valid = spot["ok"]
	reason = spot["reason"]
	if valid and move_uid == 0:
		var why := Game.build_block(kind)
		if why != "":
			valid = false
			reason = why
	var road: Array[Vector2i] = []
	if valid:
		road = world.preview_road(kind, origin, rot, move_uid)
	_cost.text = _price_text()
	_hint.text = reason if reason != "" else _advice(road)
	_paint(spot, road)
	_gmat.albedo_color = Color(1, 1, 1, 0.75) if valid else Color(1.0, 0.55, 0.5, 0.6)
	_ok.set_colors(Kit.SAGE if valid else Kit.GREY, Kit.SAGE_EDGE if valid else Kit.GREY_EDGE)


func _advice(road: Array[Vector2i]) -> String:
	var d: Dictionary = Defs.BUILDINGS[kind]
	var center := Grid.center_of(origin, Defs.size_of(kind), rot)
	var bits := []
	if Building.kind_has_entrance(kind):
		if road.is_empty() and not world.roads.cells.is_empty():
			var ents := Building.entrance_of(kind, origin, rot)
			var on := false
			for e in ents:
				if world.roads.is_road(e):
					on = true
			bits.append("Right on the road!" if on else "No road can reach this spot yet.")
		elif road.size() <= 2:
			bits.append("Right next to a road.")
		else:
			bits.append("A road of %d tiles will be built to it." % (road.size() - 1))
	if d["cat"] == "farm":
		var b := Terrain.biome_at(center)
		if Defs.BIOMES[b]["bonus"].has(d["crop"]):
			bits.append("%s: grows 40%% faster here!" % Defs.BIOMES[b]["name"])
	elif d.has("aura"):
		bits.append(str(d["desc"]))
	return "  ".join(bits)


func _paint(spot: Dictionary, road: Array[Vector2i]) -> void:
	var k := MeshKit.new()
	var size := Defs.size_of(kind)
	var cells := Grid.cells(origin, size, rot)
	var bad: Array = spot["bad"]
	# decor shows the area its effect reaches
	var aura: Dictionary = Defs.BUILDINGS[kind].get("aura", {})
	if int(aura.get("r", 0)) > 0:
		var r := int(aura["r"])
		var s0 := Grid.rotated(size, rot)
		for x in range(-r, s0.x + r):
			for y in range(-r, s0.y + r):
				if x >= 0 and y >= 0 and x < s0.x and y < s0.y:
					continue
				var ap := Grid.cell_center(origin + Vector2i(x, y))
				k.rbox(Vector3(Grid.CELL - 0.5, 0.02, Grid.CELL - 0.5), 0.2, Color(1.0, 0.9, 0.55, 0.22), MeshKit.at(ap.x, 0.04, ap.z))
	for c in cells:
		var col := Color(0.55, 0.85, 0.5, 0.55)
		if not Game.owns_cell(c):
			col = Color(0.95, 0.7, 0.3, 0.55)
		elif bad.has(c):
			col = Color(0.95, 0.4, 0.35, 0.6)
		var p := Grid.cell_center(c)
		k.rbox(Vector3(Grid.CELL - 0.16, 0.03, Grid.CELL - 0.16), 0.12, col, MeshKit.at(p.x, 0.06, p.z))
	# the road that will be built
	for c in road:
		var p2 := Grid.cell_center(c)
		k.rbox(Vector3(1.4, 0.03, 1.4), 0.5, Color(0.98, 0.9, 0.7, 0.55), MeshKit.at(p2.x, 0.07, p2.z))
	# the entrance: an arrow pointing in
	for e in spot["entrance"]:
		var ep := Grid.cell_center(e)
		var col2 := Color(0.95, 0.4, 0.35, 0.85) if bad.has(e) else Color(1.0, 0.95, 0.75, 0.9)
		var into := Basis(Vector3.UP, Grid.yaw(rot))
		var tr := Transform3D(into, ep + Vector3(0, 0.1, 0))
		k.rbox(Vector3(0.22, 0.03, 0.9), 0.05, col2, tr * MeshKit.at(0, 0, 0.15))
		k.prism(PackedVector2Array([Vector2(-0.38, -0.25), Vector2(0, -0.7), Vector2(0.38, -0.25)]), 0.03, col2, tr)
	_tiles.mesh = k.commit()


# ---------------------------------------------------------------- input

func _gui_input(e: InputEvent) -> void:
	var cam := world.cam
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
			cam.pan(cam.ground_at(prev) - cam.ground_at(e.position))
		elif _touches.size() == 2:
			var ps: Array = _touches.values()
			var dd: float = (ps[0] as Vector2).distance_to(ps[1])
			if _pinch > 0.0:
				cam.zoom_by(_pinch / dd)
			_pinch = dd
		accept_event()
	elif e is InputEventMouseButton and e.pressed:
		if e.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam.zoom_by(0.92)
		elif e.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam.zoom_by(1.08)
	elif e is InputEventMagnifyGesture:
		cam.zoom_by(1.0 / e.factor)


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
	if kind == "palace":
		extra["stage"] = 0
	var b := Game.place(kind, origin, rot, extra)
	if b.is_empty():
		Sfx.play("deny")
		return
	_placed_any = true
	last_rot = rot
	Kit.bounce(_ok, 0.12)
	# keep placing cheap decor
	if Defs.is_instant(kind) and kind != "statue" and Game.build_block(kind) == "":
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
	finished.emit(placed or _placed_any)
	queue_free()
