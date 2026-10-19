class_name Goals
extends Control
## Guides the player, lightly. A few first hints (tap the server to tune it,
## upgrade it, finish a short job free, look at the Market, open Build);
## after that it stays out of the way and only speaks up when something
## holds the empire back (a building without a road, a server without power,
## demand far beyond capacity, full gateways). What to build and upgrade is
## the player's call.
## A goal card sits under the top bar, a brass pin bobs over the place to
## look at in the world (an edge arrow when it's off screen) and a pulsing
## pointer marks the button to press.

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
var _flown := -1


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card = PanelContainer.new()
	_card.add_theme_stylebox_override("panel", Kit.skin("card_dark", 30, Vector4(16, 10, 22, 16)))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.visible = false
	add_child(_card)
	var h := Kit.hbox(10)
	_card.add_child(h)
	_icon = Kit.icon("star", 50)
	h.add_child(_icon)
	_text = Kit.game("", 21, Kit.WHITE, 6)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size.x = 340
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_text)
	_arrow = Node3D.new()
	var k := MeshKit.new()
	# a slim brass map pin
	k.cone(0.3, 0.8, Pal.BRASS, MeshKit.xf(Vector3(0, 0.8, 0), Vector3(180, 0, 0)), 14)
	k.sphere(0.38, Pal.BRASS, MeshKit.at(0, 1.05, 0), 14, 8)
	k.sphere(0.14, Color(0.98, 0.96, 0.92), MeshKit.at(0, 1.08, 0.27), 8, 5)
	var mi := Mats.inst(k.commit(), _arrow, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("emit", 0.25)
	mi.material_override = m
	world.add_child(_arrow)


func layout(vs: Vector2, top_inset: float) -> void:
	var w := minf(vs.x - 230, 520.0)
	_card.size = Vector2(w, 0)
	_card.position = Vector2((vs.x - _card.size.x) * 0.5, 108 + top_inset)
	_card.pivot_offset = _card.size * 0.5


func _process(dt: float) -> void:
	_t += dt
	_evaluate()
	_arrow.visible = _has_world and visible
	if _has_world:
		_arrow.global_position = _target_world + Vector3(0, 0.3 + sin(_t * 3.0) * 0.25, 0)
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


func _site(kind: String) -> Building:
	for n in world.bnodes.values():
		if n.kind == kind:
			return n
	return null


func _top(n: Building) -> Variant:
	if n == null:
		return null
	return n.global_position + Vector3(0, clampf(maxf(n.size_m().x, n.size_m().y) * 0.6, 3.0, 6.5), 0)


## Glide the camera to a step's place once.
func _look(n: Building) -> void:
	if n and _flown != Game.tutorial_step:
		_flown = Game.tutorial_step
		world.cam.fly_to(n.global_position + Vector3(0, 0, 2), 1.0)


func _evaluate() -> void:
	if hud.placement != null:
		_goal("", "")
		return
	var server := _first("server") as ServerB
	match Game.tutorial_step:
		0:
			if server == null or server.tune >= 0.25 or server.level >= 2:
				_advance()
				return
			_look(server)
			_goal("Customers call your API and your garage server answers with Pico 1B. Tap it to tune it!", "server", _top(server))
		1:
			if server == null or server.level >= 2 or not Game.job_of(server.uid).is_empty():
				_advance()
				return
			if not hud.selected is ServerB:
				_goal("Every token answered is paid. Tap the server again...", "server", _top(server))
			elif Game.money < Bal.upgrade_cost("server", 1):
				_goal("Saving up: upgrades add GPU slots and faster kernels.", "coin")
			else:
				_goal("Upgrade it: room for a GPU, and it serves faster.", "hammer", null, hud.actions.find("upgrade"))
		2:
			if server == null or server.level >= 2 or Game.job_of(server.uid).is_empty():
				_advance()
				return
			_goal("Jobs with 30 s or less left finish free. Tap the timer!", "builder", _top(server))
		3:
			if hud.get("_sheet") is MarketPanel or Game.buildings.size() > 9:
				_advance()
				return
			_goal("Tap your tokens up top: the Market shows what customers want and what you can serve.", "gateway", null, hud.get("_token_chip"))
		4:
			if hud.get("_sheet") is BuildPanel or Game.buildings.size() > 9:
				_advance()
				return
			_goal("Grow it your way: a Chip Fab for GPUs, more servers, gateways for customers... Open Build!", "hammer", null, hud.btn_build)
		_:
			_free_goal()


## Only problems: a building without a road, a server missing power or
## coolant, the market's biggest bottleneck, and the Megacluster while it's
## being built.
func _free_goal() -> void:
	for n in world.bnodes.values():
		if n.has_entrance() and not n is SiteB and not n.on_road():
			_goal("%s has no road: clear the space in front of its entrance." % n.def["name"], "lock", _top(n))
			return
	for n2 in world.bnodes.values():
		if n2 is ServerB and not n2 is SiteB:
			var m := (n2 as ServerB).missing()
			if not m.is_empty() and Game.count_of(Defs.producer_of(m[0])) == 0:
				var p := Defs.producer_of(m[0])
				_goal("A server needs %s: build a %s." % [Defs.item_name(m[0]).to_lower(), Defs.BUILDINGS[p]["name"]], m[0], _top(n2))
				return
	for n3 in world.bnodes.values():
		if n3 is ServerB and not n3 is SiteB and (n3 as ServerB).offline and (n3 as ServerB).level >= 2:
			_goal("A server is out of power: more Solar Farms, or more couriers to carry the cells.", "power", _top(n3))
			return
	var cap := Market.total(Market.cap)
	var dem := Market.total(Market.demand)
	if cap > 0.0 and dem > cap * 2.0 and Game.count_of("fab") == 0 and Game.level >= 2:
		_goal("Customers want twice what you can answer. A Chip Fab makes GPUs: couriers slot them into servers.", "gpu")
		return
	if Market.bandwidth > 0.0 and Market.used_bw >= Market.bandwidth * 0.98 and Game.level >= 3 and Game.count_of("gateway") < 2:
		_goal("Your API Gateway is full: build another, or rack fiber spools on it.", "gateway", _top(_first("gateway")))
		return
	if Game.count_of("mega") > 0 and not Game.won:
		var pal := _first("mega") as MegaB
		if pal:
			_goal(pal.status(), "mega", _top(pal))
			return
	_goal("", "")


func _draw() -> void:
	# pointer over a HUD button
	if _target_ui and is_instance_valid(_target_ui) and _target_ui.is_visible_in_tree():
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
