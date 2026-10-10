class_name Goals
extends Control
## Guides the player: a goal card under the top bar ("Grab wheat from the
## Wheat Field"), a bouncing pin in the world over the place to go, an edge
## pointer when that place is off screen, and a pulsing pointer over a HUD
## button when the goal is a button. The first steps are a tutorial;
## afterwards it keeps pointing at the next thing worth doing.

var hud
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
var _tip_t := 0.0


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


func _first(kind: String) -> Building:
	var l := world.buildings_of(kind)
	return l[0] if not l.is_empty() else null


func _zone_pos(kind: String) -> Variant:
	var b := _first(kind)
	if b == null or b.ports.is_empty():
		return null
	for p in b.ports:
		if p["dir"] == "in":
			return (p["zone"] as Zone).global_position
	return (b.ports[0]["zone"] as Zone).global_position


func _evaluate() -> void:
	var p := world.player
	if hud.placement != null:
		_goal("", "")
		return
	match Game.tutorial_step:
		0:
			var mixer := _first("mixer") as MixerB
			if p.carry.count_of("wheat") > 0 or (mixer and mixer.wheat.count() > 0):
				_advance()
				return
			var farm := _first("farm_wheat") as FarmB
			_goal("Walk to the Wheat Field and pick up wheat", "wheat", farm.zone.global_position if farm else null)
		1:
			var m := _first("mixer") as MixerB
			if m and (m.wheat.count() > 0 or int(Game.stats["batches"]) > 0 or (m.line and not m.line.doughs.is_empty())):
				_advance()
				return
			_goal("Drop the wheat on the Dough Mixer's pad", "mixer", _zone_pos("mixer"))
		2:
			var o := _first("oven") as OvenB
			if int(Game.stats["batches"]) > 0 or (o and o.tray.count() > 0):
				_advance()
				return
			_goal("The dough rolls down the tube into the oven...", "oven", o.tray_zone.global_position if o else null)
		3:
			if p.carry.count() > 0 and Defs.is_product(p.carry.items[p.carry.items.size() - 1]) or int(Game.stats["cookies"]) > 0:
				_advance()
				return
			var o2 := _first("oven") as OvenB
			_goal("Fresh cookies! Pick them up at the oven", "ck_shortbread", o2.tray_zone.global_position if o2 else null)
		4:
			if int(Game.stats["cookies"]) > 0:
				_advance()
				return
			_goal("Load the cookies into the Delivery Van", "truck", _zone_pos("dock"))
		5:
			if Game.count_of("farm_sugar") > 0:
				_advance()
				return
			if Game.money < Game.price_of("farm_sugar"):
				_goal("Earn $%s for a Sugar Cane Field" % Fmt.num(Game.price_of("farm_sugar")), "sugar")
			else:
				_goal("Tap Build and place a Sugar Cane Field anywhere on your land", "hammer", null, hud.btn_build)
		6:
			if Game.count_of("hopper") > 0:
				_advance()
				return
			if Game.money < Game.price_of("hopper"):
				_goal("Earn $%s for a Sugar Hopper" % Fmt.num(Game.price_of("hopper")), "hopper")
			else:
				_goal("Build > Bakery: place a Sugar Hopper on one of the line's glass tubes", "hopper", null, hud.btn_build)
		7:
			if Game.known_recipes.has("sugar"):
				_advance()
				return
			_goal("Fill the Sugar Hopper with sugar cane: Sugar Cookies sell for double!", "sugar", _zone_pos("hopper"))
		8:
			if Game.count_of("cabin") > 0:
				_advance()
				return
			if Game.level < 2:
				_goal("Keep baking: reach Level 2 to unlock staff", "star")
			elif Game.money < Game.price_of("cabin"):
				_goal("Earn $%s for a Staff Cabin" % Fmt.num(Game.price_of("cabin")), "cabin")
			else:
				_goal("Build > Staff: place a Staff Cabin", "cabin", null, hud.btn_build)
		9:
			if Game.workers.size() > 0:
				_advance()
				return
			_goal("Open Staff and hire your first worker", "hire", null, hud.btn_staff)
		10:
			for w in Game.workers:
				if w["role"] != "":
					_advance()
					return
			_goal("Give them a job: tap + on Gatherer (or on a farm, + Farmer)", "gatherer", null, hud.btn_staff)
		11:
			for b in Game.buildings:
				if int(b["lvl"]) > 1:
					_advance()
					return
			_goal("Tap any building in the world to upgrade it", "star")
		12:
			if not world.links.is_empty():
				_advance()
				return
			if Game.level < 4:
				_free_goal()
				return
			_tip_t += get_process_delta_time()
			if _tip_t > 120.0:
				_advance()
				return
			_goal("Tip: buildings that touch pass things along by chute. Move a field next to a mixer, or a van next to an oven.", "conveyor")
		_:
			_free_goal()


func _free_goal() -> void:
	if Game.idle_workers() > 0 and Game.workers.size() > 0:
		_goal("%d worker%s resting: give them a job in Staff" % [Game.idle_workers(), "s" if Game.idle_workers() > 1 else ""], "hire", null, hud.btn_staff)
		return
	for n in world.bnodes.values():
		if n is OvenB and (n as OvenB).line == null:
			_goal("An oven isn't connected to a Mixer", "oven", n.global_position)
			return
		if n is MixerB and (n as MixerB).line == null:
			_goal("A mixer has no oven at the end of its line", "mixer", n.global_position)
			return
	for kind in Defs.BUILD_ORDER:
		if Game.count_of(kind) > 0 or kind == "tube" or Defs.BUILDINGS[kind]["cat"] == "decor":
			continue
		var d: Dictionary = Defs.BUILDINGS[kind]
		if Game.level < int(d["lvl"]):
			_goal("Reach Level %d to unlock the %s" % [int(d["lvl"]), d["name"]], "lock")
			return
		if Game.can_afford(Game.price_of(kind)):
			_goal("New: build a %s. %s" % [d["name"], d["desc"]], d["icon"], null, hud.btn_build)
		else:
			_goal("Save $%s for a %s" % [Fmt.num(Game.price_of(kind)), d["name"]], d["icon"])
		return
	if Game.count_of("palace") > 0 and not Game.won:
		var pal := _first("palace") as PalaceB
		_goal(pal.status(), "palace", pal.global_position)
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
