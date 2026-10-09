class_name Goals
extends Control
## Guides the player: a goal card under the top bar ("Grab wheat from the
## Wheat Field"), a bouncing arrow in the world over the place to go, an
## edge pointer when that place is off screen, and a pulsing pointer over a
## HUD button when the goal is a button. The first steps are a tutorial;
## afterwards it keeps suggesting the next building / job.

var hud: Control
var world: World
var _card: PanelContainer
var _icon: TextureRect
var _text: Label
var _arrow: Node3D
var _target_world := Vector3.ZERO
var _has_world := false
var _target_ui: Control
var _t := 0.0
var _last_text := ""
var _done_flash := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = PanelContainer.new()
	var st := Kit.box(Color(1.0, 0.97, 0.9, 0.95), 24, 4, Kit.CHOCO, 6)
	st.border_width_bottom = 8
	st.content_margin_left = 10
	st.content_margin_right = 18
	st.content_margin_top = 6
	st.content_margin_bottom = 8
	_card.add_theme_stylebox_override("panel", st)
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	var h := Kit.hbox(10)
	_card.add_child(h)
	_icon = Kit.icon("star", 58)
	h.add_child(_icon)
	_text = Kit.label("", 26, Kit.CHOCO, 0)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 440
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_text)
	_arrow = Node3D.new()
	var k := MeshKit.new()
	k.cone(0.38, 0.7, Color(1.0, 0.85, 0.25), MeshKit.xf(Vector3(0, 0.7, 0), Vector3(180, 0, 0)), 16)
	k.cyl(0.16, 0.6, Color(1.0, 0.85, 0.25), MeshKit.at(0, 0.66, 0), 12, 0.06)
	var mi := Mats.inst(k.commit(), _arrow, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("emit", 0.35)
	mi.material_override = m
	world.add_child(_arrow)


func layout(vs: Vector2, top_inset: float) -> void:
	var w := minf(vs.x - 40, 600.0)
	_card.size = Vector2(w, 0)
	_card.position = Vector2((vs.x - _card.size.x) * 0.5, 120 + top_inset)
	_card.pivot_offset = _card.size * 0.5


func _process(dt: float) -> void:
	_t += dt
	_evaluate()
	_arrow.visible = _has_world
	if _has_world:
		_arrow.global_position = _target_world + Vector3(0, 2.2 + absf(sin(_t * 3.5)) * 0.5, 0)
		_arrow.rotation.y += dt * 2.0
	queue_redraw()


func _goal(text: String, icon: String, wpos = null, ui: Control = null) -> void:
	if text != _last_text:
		_last_text = text
		_text.text = text
		_icon.texture = Icons.tex(icon)
		_card.visible = text != ""
		if text != "":
			Kit.bounce(_card, 0.08)
	_has_world = wpos != null
	if wpos != null:
		_target_world = wpos
	_target_ui = ui


func _advance() -> void:
	Game.tutorial_step += 1
	Sfx.play("upgrade", -6.0, 1.3)
	Game.save_game()


func _evaluate() -> void:
	var p := world.player
	var line := world.lines[0]
	match Game.tutorial_step:
		0:
			if p.carry.count_of("wheat") > 0 or line.hoppers["wheat"].count() > 0:
				_advance()
				return
			_goal("Walk to the Wheat Field and grab some wheat", "wheat", world.farms["wheat"].zone.global_position)
		1:
			if line.hoppers["wheat"].count() > 0 or line.doughs.size() > 0:
				_advance()
				return
			_goal("Drop the wheat into the wheat hopper", "hopper", line.zones["wheat"].global_position)
		2:
			if int(Game.stats["batches"]) > 0 or line.tray.count() > 0:
				_advance()
				return
			for ing in Defs.INGREDIENTS:
				if line.hoppers[ing].count() == 0:
					var carrying := p.carry.count_of(ing) > 0
					var target: Vector3 = line.zones[ing].global_position if carrying else world.farms[ing].zone.global_position
					_goal("Fill every hopper: bring %s %s" % [Defs.item_name(ing).to_lower(), "to its hopper" if carrying else "from its farm"], ing, target)
					return
			_goal("The dough is on its way to the oven...", "oven", line.tray_zone.global_position)
		3:
			if p.carry.count_of("cookie") > 0 or world.docks[0].cargo.count() > 0 or int(Game.stats["cookies"]) > 0:
				_advance()
				return
			_goal("Fresh cookies! Pick them up at the oven", "cookie", line.tray_zone.global_position)
		4:
			if int(Game.stats["cookies"]) > 0:
				_advance()
				return
			var dock := world.docks[0]
			if dock.cargo.count() > 0 and p.carry.count_of("cookie") == 0:
				_goal("The truck leaves when it's full, or a few seconds after loading", "truck", dock.zone.global_position)
			else:
				_goal("Load the cookies into the delivery truck", "truck", dock.zone.global_position)
		5:
			if Game.has_building("cabin"):
				_advance()
				return
			var pad: BuildPad = world.pads.get("cabin")
			var cost := int(Defs.BUILDINGS["cabin"]["cost"]) - int(Game.pad_paid.get("cabin", 0))
			if Game.money < cost:
				_goal("Bake & sell more cookies: $%s builds the Staff Cabin" % Fmt.num(cost), "coin", pad.global_position if pad else null)
			else:
				_goal("Stand on the pad to build the Staff Cabin", "worker", pad.global_position if pad else null)
		6:
			if Game.workers.size() > 0:
				_advance()
				return
			_goal("Open Workers and hire your first helper", "hire", null, hud._btn_workers)
		7:
			for w in Game.workers:
				if w["role"] != "":
					_advance()
					return
			_goal("Give them a job: tap a farm on the Farmer card", "farmer", null, hud._btn_workers)
		8:
			for id in Bal.all_upgrade_ids():
				if Game.lvl(id) > (1 if id.begins_with("farm_") else 0):
					_advance()
					return
			_goal("Open Upgrades and make something better", "star", null, hud._btn_up)
		_:
			_free_goal()


func _free_goal() -> void:
	if Game.idle_workers() > 0 and Game.workers.size() > 0:
		_goal("%d worker%s resting — give them jobs!" % [Game.idle_workers(), "s" if Game.idle_workers() > 1 else ""], "worker", null, hud._btn_workers)
		return
	for id in Defs.BUILD_ORDER:
		if Game.has_building(id):
			continue
		var d: Dictionary = Defs.BUILDINGS[id]
		var pad: BuildPad = world.pads.get(id)
		if Game.level < int(d["lvl"]):
			_goal("Reach Level %d to unlock the %s" % [int(d["lvl"]), d["name"]], "lock")
			return
		var left := int(d["cost"]) - int(Game.pad_paid.get(id, 0))
		if Game.money >= left or Game.money >= left / 3:
			_goal("Build the %s — %s" % [d["name"], d["desc"]], d["icon"], pad.global_position if pad else null)
		else:
			_goal("Save $%s for the %s" % [Fmt.num(left), d["name"]], d["icon"], null)
		return
	_goal("", "")


func _draw() -> void:
	# pointer over a HUD button
	if _target_ui and _target_ui.is_visible_in_tree():
		var r := _target_ui.get_global_rect()
		var c := Vector2(r.get_center().x, r.position.y - 30 - absf(sin(_t * 5.0)) * 22)
		_draw_pointer(c, Vector2(0, 1))
		draw_arc(r.get_center(), r.size.x * 0.55 + sin(_t * 5.0) * 6, 0, TAU, 48, Color(1, 0.9, 0.3, 0.7), 5, true)
	# edge pointer when the world target is off screen
	if _has_world:
		var cam := get_viewport().get_camera_3d()
		if cam and not cam.is_position_behind(_target_world):
			var sp := cam.unproject_position(_target_world)
			var vr := get_viewport_rect().grow(-70)
			if not vr.has_point(sp):
				var center := vr.get_center()
				var dir := (sp - center).normalized()
				var edge := Vector2(clampf(sp.x, vr.position.x, vr.end.x), clampf(sp.y, vr.position.y + 140, vr.end.y - 160))
				_draw_pointer(edge, dir)


func _draw_pointer(at: Vector2, dir: Vector2) -> void:
	var n := Vector2(-dir.y, dir.x)
	var tip := at + dir * 26
	var pts := PackedVector2Array([tip, at - dir * 14 + n * 24, at - dir * 14 - n * 24])
	var sh := PackedVector2Array()
	for q in pts:
		sh.append(q + Vector2(0, 5))
	draw_colored_polygon(sh, Color(0.2, 0.1, 0.05, 0.35))
	draw_colored_polygon(pts, Color(1.0, 0.82, 0.22))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Kit.CHOCO, 4, true)
