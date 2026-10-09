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
	_card.add_theme_stylebox_override("panel", Kit.skin("card_dark", 30, Vector4(16, 10, 22, 16)))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_card)
	var h := Kit.hbox(10)
	_card.add_child(h)
	_icon = Kit.icon("star", 50)
	h.add_child(_icon)
	_text = Kit.game("", 22, Kit.WHITE, 6)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 380
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_text)
	_arrow = Node3D.new()
	var k := MeshKit.new()
	# a slim brass map pin
	k.cone(0.2, 0.55, Pal.BRASS, MeshKit.xf(Vector3(0, 0.55, 0), Vector3(180, 0, 0)), 14)
	k.sphere(0.26, Pal.BRASS, MeshKit.at(0, 0.72, 0), 14, 8)
	k.sphere(0.1, Color(0.98, 0.96, 0.92), MeshKit.at(0, 0.74, 0.18), 8, 5)
	var mi := Mats.inst(k.commit(), _arrow, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("emit", 0.25)
	mi.material_override = m
	world.add_child(_arrow)


func layout(vs: Vector2, top_inset: float) -> void:
	var w := minf(vs.x - 40, 520.0)
	_card.size = Vector2(w, 0)
	_card.position = Vector2((vs.x - _card.size.x) * 0.5, 108 + top_inset)
	_card.pivot_offset = _card.size * 0.5


func _process(dt: float) -> void:
	_t += dt
	_evaluate()
	_arrow.visible = _has_world
	if _has_world:
		_arrow.global_position = _target_world + Vector3(0, 1.9 + sin(_t * 3.0) * 0.18, 0)
		_arrow.rotation.y += dt * 1.2
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
			_goal("Walk to the wheat field and pick up the wheat", "wheat", world.farms["wheat"].zone.global_position)
		1:
			if line.hoppers["wheat"].count() > 0 or line.doughs.size() > 0:
				_advance()
				return
			_goal("Drop the wheat on the pad under the hopper", "hopper", line.zones["wheat"].global_position)
		2:
			if int(Game.stats["batches"]) > 0 or line.tray.count() > 0:
				_advance()
				return
			_goal("The dough is rolling to the oven", "oven", line.tray_zone.global_position)
		3:
			if p.carry.count_of("cookie") > 0 or world.docks[0].cargo.count() > 0 or int(Game.stats["cookies"]) > 0:
				_advance()
				return
			_goal("Fresh cookies. Pick them up at the oven", "cookie", line.tray_zone.global_position)
		4:
			if int(Game.stats["cookies"]) > 0:
				_advance()
				return
			var dock := world.docks[0]
			if dock.cargo.count() > 0 and p.carry.count_of("cookie") == 0:
				_goal("The van leaves a moment after loading", "truck", dock.zone.global_position)
			else:
				_goal("Load the cookies into the delivery van", "truck", dock.zone.global_position)
		5:
			if Game.has_building("plot_sugar"):
				_advance()
				return
			_build_goal("plot_sugar", "Sugar makes cookies worth twice as much")
		6:
			if Game.has_building("cabin"):
				_advance()
				return
			if Game.level < 2:
				_goal("Keep baking: reach Level 2 to unlock staff", "star")
			else:
				_build_goal("cabin", "Build the Staff Cabin to hire help")
		7:
			if Game.workers.size() > 0:
				_advance()
				return
			_goal("Open Staff and hire your first worker", "hire", null, hud._btn_workers)
		8:
			for w in Game.workers:
				if w["role"] != "":
					_advance()
					return
			_goal("Give them a job: tap a field on the Farmer card", "farmer", null, hud._btn_workers)
		9:
			for id in Bal.all_upgrade_ids():
				if Game.lvl(id) > (1 if id.begins_with("farm_") else 0):
					_advance()
					return
			_goal("Open Upgrades and improve something", "star", null, hud._btn_up)
		_:
			_free_goal()


func _build_goal(id: String, why: String) -> void:
	var pad: BuildPad = world.pads.get(id)
	var d: Dictionary = Defs.BUILDINGS[id]
	var left := int(d["cost"]) - int(Game.pad_paid.get(id, 0))
	if Game.money < left:
		_goal("Earn $%s for the %s. %s" % [Fmt.num(left), d["name"], why], d["icon"], pad.global_position if pad else null)
	else:
		_goal("Stand on the pad to build the %s" % d["name"], d["icon"], pad.global_position if pad else null)


func _free_goal() -> void:
	if Game.idle_workers() > 0 and Game.workers.size() > 0:
		_goal("%d worker%s waiting for a job" % [Game.idle_workers(), "s" if Game.idle_workers() > 1 else ""], "hire", null, hud._btn_workers)
		return
	for id in Defs.BUILD_ORDER:
		if Game.has_building(id):
			continue
		var d: Dictionary = Defs.BUILDINGS[id]
		if Game.level < int(d["lvl"]):
			_goal("Reach Level %d to unlock the %s" % [int(d["lvl"]), d["name"]], "lock")
			return
		_build_goal(id, d["desc"])
		return
	_goal("", "")


func _draw() -> void:
	# pointer over a HUD button
	if _target_ui and _target_ui.is_visible_in_tree():
		var r := _target_ui.get_global_rect()
		var c := Vector2(r.get_center().x, r.position.y - 30 - absf(sin(_t * 5.0)) * 22)
		_draw_pointer(c, Vector2(0, 1))
		draw_arc(r.get_center(), r.size.x * 0.55 + sin(_t * 4.0) * 5, 0, TAU, 48, Color(1.0, 0.85, 0.35, 0.9), 5, true)
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
	var tip := at + dir * 30
	var pts := PackedVector2Array([tip, at - dir * 16 + n * 28, at - dir * 16 - n * 28])
	var sh := PackedVector2Array()
	for q in pts:
		sh.append(q + Vector2(0, 6))
	draw_colored_polygon(sh, Color(0.05, 0.04, 0.03, 0.35))
	var rim := PackedVector2Array(pts)
	rim.append(pts[0])
	draw_colored_polygon(pts, Color(1.0, 0.82, 0.3))
	draw_polyline(rim, Kit.OUTLINE, 5.0, true)
