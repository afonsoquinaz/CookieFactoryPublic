extends Control
## The game HUD, base-builder style. Top: money and gems, the builders chip
## (busy / total), the Empire level badge, settings. Bottom: Staff, Research,
## Boost and a big Build button. Tap a building (or an obstacle, or a For Sale
## sign) to select it: it lights up and an action bar replaces the bottom
## buttons. Floating timers sit over everything being built. Build mode
## hands the screen to Placement.

var world: World
var pan: PanInput
var goals: Goals
var title: TitleMenu
var placement: Placement
var actions: ActionBar
var timers: JobTimers
var selected: Building
var selected_ob := ""
var _money_label: Label
var _money_pill: Control
var _income_label: Label
var _gem_chip: PanelContainer
var _gem_label: Label
var _token_chip: PanelContainer
var _token_label: Label
var _builders_chip: JuicyButton
var _trend_chip: PanelContainer
var _trend_icon: TextureRect
var _trend_label: Label
var _lvl_box: Control
var _lvl_label: Label
var _lvl_title: Label
var _lvl_fill: Panel
var _gear: JuicyButton
var btn_build: JuicyButton
var btn_staff: JuicyButton
var btn_research: JuicyButton
var _btn_rush: JuicyButton
var _build_dot: Control
var _research_dot: Control
var _staff_dot: Label
var _toast_box: VBoxContainer
var _sheet: Sheet
var _shown_money := 0.0
var _bar: HBoxContainer
var _vignette: ColorRect
var _rush_glow := 0.0
var _sel_mark: MeshInstance3D
var _route_mark: MeshInstance3D
var _sel_t := 0.0
var playing := false


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = preload("res://render/vignette.gdshader")
	vm.set_shader_parameter("color", Color(1.0, 0.78, 0.3))
	_vignette.material = vm
	add_child(_vignette)
	pan = PanInput.new()
	pan.world = world
	pan.tapped.connect(_on_tap)
	add_child(pan)
	timers = JobTimers.new()
	timers.world = world
	timers.picked.connect(_on_timer)
	add_child(timers)
	_build_top()
	_build_bottom()
	actions = ActionBar.new()
	actions.action.connect(_on_action)
	actions.visible = false
	add_child(actions)
	_toast_box = Kit.vbox(8)
	add_child(_toast_box)
	goals = Goals.new()
	goals.hud = self
	goals.world = world
	add_child(goals)
	_sel_mark = MeshInstance3D.new()
	_sel_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_sel_mark.material_override = Mats.flat(Color(1.0, 0.86, 0.42, 0.95))
	_sel_mark.visible = false
	world.add_child(_sel_mark)
	_route_mark = MeshInstance3D.new()
	_route_mark.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_route_mark.material_override = Mats.flat(Color(1.0, 0.92, 0.6, 0.85))
	_route_mark.visible = false
	world.add_child(_route_mark)
	_shown_money = Game.money
	Game.money_changed.connect(_on_money)
	Game.gems_changed.connect(func(g):
		_gem_label.text = str(g)
		Kit.bounce(_gem_chip, 0.15))
	Game.level_up.connect(_on_level_up)
	Game.toast.connect(toast)
	Game.rush_changed.connect(_on_rush)
	Game.building_built.connect(_on_built)
	Game.job_done.connect(_on_job_done)
	Game.discovered.connect(_on_discovered)
	Game.trend_changed.connect(_on_trend)
	Game.land_bought.connect(func(_c): toast("New land! Clear it and build on it.", "land"))
	Game.obstacle_cleared.connect(func(_k, g): toast("Cleared!%s" % ("  +%d gems" % g if g > 0 else ""), "gem" if g > 0 else "hammer"))
	world.sold.connect(_on_sold)
	Game.victory.connect(func():
		Sfx.play("levelup")
		var c := world.cam.global_position
		for i in 3:
			Fx.burst(get_tree().current_scene, c + Vector3(randf_range(-3, 3), 3, randf_range(-3, 3)), Pal.GOLD, 40)
		_popup("Token Empire!", "The AGI Megacluster is online. Your tokens power the whole world.",
			"%s tokens served  ·  %s earned  ·  %s played" % [Fmt.num(int(Game.stats["tokens"])), "$" + Fmt.num(float(Game.stats["earned"])), Fmt.time(float(Game.stats["play_time"]))],
			"mega", "Keep serving"))
	_update_level()
	_on_trend(Game.trending)
	_gem_label.text = str(Game.gems)


## Show the title menu first (skipped for screenshots / bots).
func show_title() -> void:
	title = TitleMenu.new()
	title.world = world
	title.play.connect(_start_playing)
	add_child(title)
	_set_hud_visible(false)


func _start_playing() -> void:
	playing = true
	_set_hud_visible(true)
	for c in [_money_pill, _lvl_box, _gear, _builders_chip]:
		Kit.pop_in(c, 0.2)
	_welcome_back.call_deferred()


func skip_title() -> void:
	playing = true
	_set_hud_visible(true)
	_welcome_back.call_deferred()


func _welcome_back() -> void:
	if Game.offline_reward > 0:
		_offline_popup(Game.offline_reward)


func _set_hud_visible(on: bool) -> void:
	for c in [_money_pill, _lvl_box, _gear, _bar, goals, pan, _gem_chip, _token_chip, _trend_chip, _builders_chip, timers]:
		c.visible = on
	if on:
		_trend_chip.visible = Game.trending != ""


# ---------------------------------------------------------------- top

func _build_top() -> void:
	var pill := Control.new()
	pill.custom_minimum_size = Vector2(250, 76)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)
	_money_pill = pill
	var bar := Panel.new()
	bar.add_theme_stylebox_override("panel", Kit.skin("bar", 36))
	bar.position = Vector2(30, 8)
	bar.size = Vector2(220, 62)
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(bar)
	var coin := Kit.icon("coin", 78)
	coin.position = Vector2(-4, -2)
	pill.add_child(coin)
	_money_label = Kit.game("0", 38, Kit.WHITE, 8)
	_money_label.position = Vector2(82, 10)
	pill.add_child(_money_label)
	_income_label = Kit.game("", 15, Color(0.85, 1.0, 0.7), 5)
	_income_label.position = Vector2(84, 52)
	pill.add_child(_income_label)
	# gems
	_gem_chip = PanelContainer.new()
	_gem_chip.add_theme_stylebox_override("panel", Kit.skin("card_dark", 26, Vector4(10, 4, 16, 8)))
	_gem_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_gem_chip)
	var gh := Kit.hbox(6)
	_gem_chip.add_child(gh)
	gh.add_child(Kit.icon("gem", 34))
	_gem_label = Kit.game("0", 22, Kit.WHITE, 5)
	gh.add_child(_gem_label)
	# tokens served: the score of the game, with the serving rate
	_token_chip = PanelContainer.new()
	_token_chip.add_theme_stylebox_override("panel", Kit.skin("card_dark", 26, Vector4(10, 4, 16, 8)))
	_token_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_token_chip)
	var tkh := Kit.hbox(6)
	_token_chip.add_child(tkh)
	tkh.add_child(Kit.icon("token", 34))
	_token_label = Kit.game("0", 20, Color(0.7, 0.96, 1.0), 5)
	tkh.add_child(_token_label)
	# builders: busy / total
	_builders_chip = Kit.juicy("", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 20, Vector2(118, 60))
	_builders_chip.set_icon("builder", 40)
	_builders_chip.set_text_value("0/0")
	_builders_chip.pressed.connect(_on_builders)
	add_child(_builders_chip)
	# trending model
	_trend_chip = PanelContainer.new()
	_trend_chip.add_theme_stylebox_override("panel", Kit.skin("card_dark", 26, Vector4(10, 4, 16, 8)))
	_trend_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_trend_chip)
	var th := Kit.hbox(6)
	_trend_chip.add_child(th)
	_trend_icon = Kit.icon("token", 34)
	th.add_child(_trend_icon)
	_trend_label = Kit.game("", 17, Color(1.0, 0.9, 0.55), 5)
	th.add_child(_trend_label)
	# Lab level badge: grows with lifetime tokens served
	var hb := Control.new()
	hb.custom_minimum_size = Vector2(190, 84)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hb)
	_lvl_box = hb
	var back := Panel.new()
	back.add_theme_stylebox_override("panel", Kit.skin("bar", 30))
	back.position = Vector2(40, 12)
	back.size = Vector2(150, 56)
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(back)
	var star := Kit.icon("star", 84)
	star.position = Vector2(-6, -6)
	hb.add_child(star)
	_lvl_label = Kit.game("1", 30, Kit.WHITE, 7)
	_lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lvl_label.position = Vector2(-6, 6)
	_lvl_label.size = Vector2(84, 60)
	hb.add_child(_lvl_label)
	_lvl_title = Kit.game("", 17, Kit.WHITE, 5)
	_lvl_title.position = Vector2(80, 16)
	hb.add_child(_lvl_title)
	var track := Panel.new()
	track.add_theme_stylebox_override("panel", Kit.skin("track", 10))
	track.position = Vector2(82, 44)
	track.size = Vector2(98, 14)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_child(track)
	_lvl_fill = Panel.new()
	_lvl_fill.add_theme_stylebox_override("panel", Kit.skin("fill_gold", 10))
	_lvl_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_lvl_fill)
	_gear = Kit.juicy("", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 20, Vector2(72, 72))
	_gear.set_glyph("settings", 34)
	_gear.pressed.connect(func(): open_sheet(SettingsPanel.new()))
	add_child(_gear)


func _update_level() -> void:
	_lvl_label.text = str(Game.level)
	_lvl_title.text = Defs.level_title(Game.level)
	_lvl_fill.size = Vector2(maxf(10.0, 98.0 * Game.level_progress()), 14)


func _on_money(_value: float, delta: float) -> void:
	if delta > 0:
		_update_level()
		Kit.bounce(_money_pill, 0.06)


func _on_trend(rid: String) -> void:
	_trend_chip.visible = rid != "" and playing
	if rid == "":
		return
	_trend_icon.texture = Icons.tex("tk_" + rid)
	_trend_label.text = "Trending: %s  x%.1f" % [Defs.recipe(rid)["name"], 1.5 + 0.1 * Game.research("market")]
	if playing:
		toast("%s is trending: its tokens sell for more!" % Defs.recipe(rid)["name"], "tk_" + rid)


func _on_builders() -> void:
	if Game.jobs.is_empty():
		toast("Your builders are free: build or upgrade something!", "builder")
		return
	var j: Dictionary = Game.jobs[0]
	world.cam.fly_to(world.job_center(j))
	_on_timer(j)


# ---------------------------------------------------------------- bottom

func _build_bottom() -> void:
	_bar = Kit.hbox(12)
	_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_bar)
	btn_staff = _big_button("Staff", "hire", Kit.CHARCOAL)
	btn_staff.pressed.connect(open_staff)
	btn_research = _big_button("Research", "research", Kit.CHARCOAL)
	btn_research.pressed.connect(func(): open_sheet(ResearchPanel.new()))
	_btn_rush = _big_button("Overclock", "boost", Kit.TERRACOTTA)
	_btn_rush.pressed.connect(_rush)
	btn_build = _big_button("Build", "hammer", Kit.BRASS)
	btn_build.custom_minimum_size = Vector2(160, 128)
	btn_build.pressed.connect(open_build)
	_build_dot = _dot(btn_build)
	_research_dot = _dot(btn_research)
	_staff_dot = _dot(btn_staff).get_child(0)


func _big_button(t: String, icon: String, face: Color) -> JuicyButton:
	var b := Kit.juicy("", face, face, 18, Vector2(128, 116))
	b.row.queue_free()
	var v := Kit.vbox(-4)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	v.offset_bottom = -10
	b.add_child(v)
	var ic := Kit.icon(icon, 60)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var l := Kit.game(t, 20, Kit.WHITE, 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(l)
	b.set_meta("label", l)
	b.text_label = l
	b.row = Kit.hbox()
	b.visible = false
	_bar.add_child(b)
	return b


func _dot(b: Control) -> Control:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", Kit.box(Color(0.86, 0.26, 0.2), 16, 3, Kit.WHITE))
	p.size = Vector2(34, 34)
	p.position = Vector2(100, -8)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.z_index = 2
	var l := Kit.game("!", 18, Kit.WHITE, 4)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(34, 32)
	p.add_child(l)
	b.add_child(p)
	return p


func _show_button(b: JuicyButton, on: bool) -> void:
	if on and not b.visible:
		b.visible = true
		Kit.pop_in.call_deferred(b)
	elif not on:
		b.visible = false


var _dot_cd := 0.0

func _update_buttons(dt: float) -> void:
	var sel := selected != null or selected_ob != ""
	_bar.visible = not sel and placement == null
	actions.visible = sel and placement == null and _sheet == null
	_show_button(btn_build, true)
	_show_button(btn_staff, true)
	_show_button(btn_research, int(Game.stats["tokens"]) > 0)
	_show_button(_btn_rush, Game.level >= 2)
	_gem_chip.visible = true
	_builders_chip.set_text_value("%d/%d" % [Game.jobs.size(), Game.builders()])
	_builders_chip.set_colors(Kit.SAGE if Game.free_builders() > 0 else Kit.CHARCOAL, Kit.SAGE_EDGE)
	_dot_cd -= dt
	if _dot_cd <= 0.0:
		_dot_cd = 0.5
		var any := false
		for id in Bal.RESEARCH_ORDER:
			if not Game.research_maxed(id) and Game.can_afford(Game.research_cost(id)):
				any = true
				break
		_research_dot.visible = any and _sheet == null
		var can_build := false
		if Game.free_builders() > 0:
			for kind in Defs.BUILD_ORDER:
				if Defs.BUILDINGS[kind]["cat"] != "decor" and Game.count_of(kind) == 0 and Game.build_block(kind) == "":
					can_build = true
					break
		_build_dot.visible = can_build and _sheet == null
		var free_hire := Game.can_hire() and Game.can_afford(Game.hire_price())
		_staff_dot.get_parent().visible = free_hire and _sheet == null
		_staff_dot.text = "+"
	var rl: Label = _btn_rush.get_meta("label")
	if Game.rush_active():
		rl.text = "x2  %ds" % ceili(Game.rush_time)
	elif Game.rush_cooldown > 0.0:
		rl.text = Fmt.time(Game.rush_cooldown)
	else:
		rl.text = "Overclock"
	_btn_rush.set_colors(Kit.GREY if Game.rush_cooldown > 0.0 and not Game.rush_active() else Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE)


func _rush() -> void:
	if Game.start_rush():
		Sfx.play("levelup", -6.0, 1.2)
		toast("Overclocked! Everything runs twice as fast for %ds" % int(Bal.rush_duration()), "boost")
	else:
		Sfx.play("deny")
		Kit.shake(_btn_rush)


func _on_rush(active: bool) -> void:
	if not active:
		toast("Boost finished", "clock")


func open_build() -> void:
	deselect()
	var p := BuildPanel.new()
	p.chosen.connect(func(kind): start_placement.call_deferred(kind, 0))
	open_sheet(p)


func open_staff() -> void:
	deselect()
	open_sheet(StaffPanel.new())


func open_building(n: Building, focus := "") -> void:
	var p := BuildingPanel.new().setup(world, n, focus)
	p.move_requested.connect(func(uid): start_placement.call_deferred(n.kind, uid))
	open_sheet(p)


func open_recipes(n: ServerB) -> void:
	open_sheet(RecipePanel.new().setup(n))


func open_sheet(s: Sheet) -> void:
	if is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = s
	pan.visible = false
	goals.visible = false
	timers.visible = false
	s.closed.connect(func():
		if _sheet == s:
			_sheet = null
		if placement == null:
			pan.visible = playing
			goals.visible = playing
			timers.visible = playing)
	add_child(s)


# ---------------------------------------------------------------- selection

func select(n: Building) -> void:
	selected_ob = ""
	selected = n
	_sel_t = 0.0
	n.flash()
	Sfx.play("click")
	_refresh_actions()


func select_obstacle(key: String) -> void:
	selected = null
	selected_ob = key
	_sel_t = 0.0
	Sfx.play("click")
	var n: Node3D = world.obst_nodes.get(key)
	if n:
		var tw := n.create_tween()
		n.scale = Vector3(1.08, 0.9, 1.08)
		tw.tween_property(n, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_refresh_actions()


func deselect() -> void:
	selected = null
	selected_ob = ""
	_sel_mark.visible = false
	_route_mark.visible = false


func _refresh_actions() -> void:
	if selected_ob != "":
		var ob: Dictionary = Game.obstacles.get(selected_ob, {})
		if ob.is_empty():
			deselect()
			return
		var j := Game.job_of_obstacle(selected_ob)
		var name: String = Defs.OBSTACLES[ob["kind"]]["name"]
		var btns := []
		if j.is_empty():
			actions.set_title(name, "Clear it to make room%s" % ("  ·  hides sparks!" if int(ob["gems"]) > 0 else ""))
			btns.append(["clear", "hammer", "Clear $%s" % Fmt.num(Game.obstacle_price()), Kit.SAGE, Game.clear_block(selected_ob) == ""])
		else:
			actions.set_title(name, "Being cleared: %s left" % Fmt.time(Game.job_left(j)))
			btns.append(["finish", "gem", _finish_label(j), Kit.BRASS, true])
		actions.set_buttons(btns, "ob" + selected_ob)
		_mark_cells(Game.obstacle_cells(selected_ob, ob))
		return
	var n := selected
	if not is_instance_valid(n):
		deselect()
		return
	var d: Dictionary = n.def
	var j2 := Game.job_of(n.uid)
	var sub := ""
	if n is SiteB:
		sub = "Under construction"
	elif Bal.max_level(n.kind) > 1:
		sub = "Level %d" % n.level
	if not j2.is_empty():
		sub += ("  ·  " if sub != "" else "") + ("Upgrading" if j2["type"] == "upgrade" else "Building") + ": %s left" % Fmt.time(Game.job_left(j2))
	elif n.has_entrance() and not n.on_road() and not n is SiteB:
		sub += "  ·  No road! Clear the space in front"
	actions.set_title(d["name"], sub)
	var b := []
	b.append(["info", "research", "Info", Kit.CHARCOAL])
	if not j2.is_empty():
		b.append(["finish", "gem", _finish_label(j2), Kit.BRASS])
	elif not n is SiteB and Bal.max_level(n.kind) > 1 and n.level < Bal.max_level(n.kind):
		b.append(["upgrade", "hammer", "$" + Fmt.num(Bal.upgrade_cost(n.kind, n.level)), Kit.SAGE])
	if n is ServerB:
		b.append(["recipe", "tk_" + (n as ServerB).recipe, "Model", Kit.BRASS])
	if (n is SourceB or n is ServerB or n is MachineB) and not n is SiteB:
		b.append(["staff", "tech" if n is SourceB else "engineer", "Staff", Kit.CHARCOAL])
	if n is MegaB and j2.is_empty() and not (n as MegaB).complete():
		b.append(["stage", "mega", "Next stage", Kit.BRASS, (n as MegaB).can_advance()])
	if not n is SiteB:
		b.append(["move", "move", "Move", Kit.CHARCOAL])
	actions.set_buttons(b, "b%d" % n.uid)
	_mark_cells(Grid.cells(n.cell(), n.size(), n.rot()))
	_mark_route(n)


func _finish_label(j: Dictionary) -> String:
	var g := Bal.finish_gems(Game.job_left(j))
	return "Free!" if g == 0 else "%d sparks" % g


## Little glowing stones along the selected building's road to the High Street.
func _mark_route(n: Building) -> void:
	if not n.has_entrance() or not n.on_road():
		_route_mark.visible = false
		return
	var key := "%d_%d" % [n.uid, world.roads.cells.size()]
	if _route_mark.get_meta("key", "") == key:
		_route_mark.visible = true
		return
	_route_mark.set_meta("key", key)
	var r := world.street_route(n.entrance_cells()[0])
	var k := MeshKit.new()
	for i in r.size():
		var p := Grid.cell_center(r[i])
		k.cyl(0.16, 0.04, Color.WHITE, MeshKit.at(p.x, 0.07, p.z), 10)
		if i + 1 < r.size():
			var q := (p + Grid.cell_center(r[i + 1])) * 0.5
			k.cyl(0.11, 0.04, Color.WHITE, MeshKit.at(q.x, 0.07, q.z), 8)
	_route_mark.mesh = k.commit()
	_route_mark.visible = true


## A glowing outline around the selected footprint.
func _mark_cells(cells: Array) -> void:
	if cells.is_empty():
		_sel_mark.visible = false
		return
	var mn := Vector2i(1 << 20, 1 << 20)
	var mx := Vector2i(-(1 << 20), -(1 << 20))
	for c in cells:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	var a := Vector2(mn) * Grid.CELL
	var b := Vector2(mx + Vector2i.ONE) * Grid.CELL
	var k := MeshKit.new()
	var w := 0.14
	var cx := (a.x + b.x) * 0.5
	var cz := (a.y + b.y) * 0.5
	k.rbox(Vector3(b.x - a.x, 0.03, w), 0.05, Color.WHITE, MeshKit.at(cx, 0.08, a.y))
	k.rbox(Vector3(b.x - a.x, 0.03, w), 0.05, Color.WHITE, MeshKit.at(cx, 0.08, b.y))
	k.rbox(Vector3(w, 0.03, b.y - a.y), 0.05, Color.WHITE, MeshKit.at(a.x, 0.08, cz))
	k.rbox(Vector3(w, 0.03, b.y - a.y), 0.05, Color.WHITE, MeshKit.at(b.x, 0.08, cz))
	_sel_mark.mesh = k.commit()
	_sel_mark.visible = true


func _on_action(id: String) -> void:
	var n := selected
	match id:
		"info":
			open_building(n)
		"upgrade":
			open_building(n, "upgrade")
		"recipe":
			open_recipes(n as ServerB)
		"staff":
			open_building(n, "staff")
		"move":
			start_placement(n.kind, n.uid)
		"stage":
			if (n as MegaB).advance():
				Sfx.play("upgrade")
				toast("Builders started on %s!" % Defs.MEGA_STAGES[(n as MegaB).stage() + 1]["name"], "mega")
			else:
				Sfx.play("deny")
				toast((n as MegaB).advance_block(), "mega")
		"clear":
			if Game.clear_obstacle(selected_ob):
				Sfx.play("upgrade", -4.0)
			else:
				Sfx.play("deny")
				toast(Game.clear_block(selected_ob), "hammer")
		"finish":
			var j := Game.job_of_obstacle(selected_ob) if selected_ob != "" else Game.job_of(n.uid)
			_finish(j)
	_refresh_actions.call_deferred()


func _finish(j: Dictionary) -> void:
	if j.is_empty():
		return
	var g := Bal.finish_gems(Game.job_left(j))
	if Game.finish_now(j):
		Sfx.play("cash" if g > 0 else "upgrade")
	else:
		Sfx.play("deny")
		toast("Not enough gems (%d needed). Orders and obstacles give gems." % g, "gem")


func _on_timer(j: Dictionary) -> void:
	if Game.job_left(j) <= Bal.FREE_FINISH:
		_finish(j)
		return
	if str(j.get("ob", "")) != "":
		select_obstacle(j["ob"])
	else:
		var b := world.building(int(j["uid"]))
		if b:
			select(b)


# ---------------------------------------------------------------- build mode

func start_placement(kind: String, move_uid := 0) -> void:
	if placement:
		placement.finish(false)
	deselect()
	placement = Placement.new().setup(world, kind, move_uid)
	placement.finished.connect(func(placed):
		placement = null
		_set_hud_visible(true)
		if placed and move_uid == 0:
			toast(("%s: a builder is on it!" % Defs.BUILDINGS[kind]["name"]) if Game.jobs.size() > 0 and not Defs.is_instant(kind) else "%s built!" % Defs.BUILDINGS[kind]["name"], Defs.BUILDINGS[kind]["icon"]))
	for c in [_bar, pan, goals, _trend_chip, timers, actions]:
		c.visible = false
	add_child(placement)


# ---------------------------------------------------------------- taps in the world

func _on_tap(pos: Vector2) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var o := cam.project_ray_origin(pos)
	var d := cam.project_ray_normal(pos)
	if d.y > -0.01:
		return
	# a sale sign stands up; test a few heights along the ray
	for y in [1.4, 0.8, 0.0]:
		var p: Vector3 = o + d * ((y - o.y) / d.y)
		var chunk = world.terrain.sign_near(p, 1.6)
		if chunk != null:
			deselect()
			_land_popup(chunk)
			return
	# buildings and obstacles: test along the ray from a little above the ground
	for y in [2.0, 1.2, 0.6, 0.0]:
		var p2: Vector3 = o + d * ((y - o.y) / d.y)
		var b := world.building_at(p2)
		if b:
			if b == selected:
				open_building(b)
			else:
				select(b)
			return
		var key := world.obstacle_at(p2)
		if key != "":
			select_obstacle(key)
			return
	deselect()


func _land_popup(chunk: Vector2i) -> void:
	var b := Terrain.biome(chunk)
	var bonus := []
	for i in Defs.BIOMES[b]["bonus"]:
		bonus.append(Defs.item_name(i))
	var price := Game.land_price()
	_popup(Defs.BIOMES[b]["name"], "Sources of %s work 40%% faster here." % ", ".join(bonus), "$%s" % Fmt.num(price), "land",
		"Buy land" if Game.can_afford(price) else "Not enough money", func():
			if Game.buy_chunk(chunk):
				Sfx.play("cash")
			else:
				Sfx.play("deny"), true)


# ---------------------------------------------------------------- layout + frame

func _layout() -> void:
	var vs := get_viewport_rect().size
	var top := 0.0
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		if safe.size.y > 0:
			top = safe.position.y * vs.y / float(DisplayServer.window_get_size().y)
	_money_pill.position = Vector2(14, 16 + top)
	_money_pill.size = _money_pill.custom_minimum_size
	_gem_chip.size = _gem_chip.get_combined_minimum_size()
	_gem_chip.position = Vector2(40, 88 + top)
	_gear.size = _gear.custom_minimum_size
	_gear.position = Vector2(vs.x - _gear.size.x - 14, 14 + top)
	_lvl_box.size = _lvl_box.custom_minimum_size
	_lvl_box.position = Vector2(_gear.position.x - _lvl_box.size.x - 8, 12 + top)
	_builders_chip.size = _builders_chip.custom_minimum_size
	_builders_chip.position = Vector2(vs.x - _builders_chip.size.x - 14, 96 + top)
	_token_chip.size = _token_chip.get_combined_minimum_size()
	_token_chip.position = Vector2(_gem_chip.position.x + _gem_chip.size.x + 10, 88 + top)
	_trend_chip.size = _trend_chip.get_combined_minimum_size()
	_trend_chip.position = Vector2(40, 140 + top)
	var bs := _bar.get_combined_minimum_size()
	_bar.size = Vector2(vs.x, bs.y)
	_bar.position = Vector2(0, vs.y - bs.y - 30)
	actions.layout(vs)
	_toast_box.size = Vector2(minf(vs.x - 40, 600), 0)
	_toast_box.position = Vector2((vs.x - _toast_box.size.x) * 0.5, 230 + top)
	goals.layout(vs, top + 56.0)


func _process(dt: float) -> void:
	_layout()
	_shown_money = lerpf(_shown_money, Game.money, clampf(dt * 10.0, 0.0, 1.0))
	if absf(_shown_money - Game.money) < 1.0:
		_shown_money = Game.money
	_money_label.text = Fmt.num(roundf(_shown_money))
	var inc := Game.recent_income()
	_income_label.text = ("+%s/min" % Fmt.num(inc * 60.0)) if inc > 0.05 else ""
	var tr := Game.token_rate()
	_token_label.text = Fmt.num(int(Game.stats["tokens"])) + (("  ·  %s/s" % (("%.1f" % tr) if tr < 10.0 else Fmt.num(tr))) if tr > 0.05 else "")
	if playing and placement == null:
		_update_buttons(dt)
	_builders_chip.set_text_value("%d/%d" % [Game.jobs.size(), Game.builders()])
	if (selected != null or selected_ob != "") and placement == null:
		_sel_t += dt
		var m := _sel_mark.material_override as StandardMaterial3D
		m.albedo_color.a = 0.6 + sin(_sel_t * 5.0) * 0.3
		var m2 := _route_mark.material_override as StandardMaterial3D
		m2.albedo_color.a = 0.45 + sin(_sel_t * 4.0 - 1.0) * 0.3
		if int(_sel_t * 2.0) != int((_sel_t - dt) * 2.0):
			_refresh_actions()
	_rush_glow = move_toward(_rush_glow, 1.0 if Game.rush_active() else 0.0, dt * 2.0)
	(_vignette.material as ShaderMaterial).set_shader_parameter("strength", _rush_glow)
	_vignette.visible = _rush_glow > 0.001


# ---------------------------------------------------------------- feedback

func toast(text: String, icon := "") -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Kit.skin("card_dark", 30, Vector4(16, 10, 20, 16)))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := Kit.hbox(10)
	p.add_child(h)
	if icon != "":
		h.add_child(Kit.icon(icon, 40))
	var l := Kit.game(text, 21, Kit.WHITE, 5)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 420
	h.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_box.add_child(p)
	if _toast_box.get_child_count() > 3:
		_toast_box.get_child(0).queue_free()
	Kit.pop_in.call_deferred(p)
	var tw := p.create_tween()
	tw.tween_interval(2.8)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)


func _on_sold(amount: float, _count: int, where: Vector3) -> void:
	var cam := get_viewport().get_camera_3d()
	if cam == null or cam.is_position_behind(where):
		return
	var from := cam.unproject_position(where)
	var to := _money_pill.global_position + Vector2(36, 36)
	for i in mini(10, 3 + int(log(maxf(amount, 1.0)))):
		var c := Kit.icon("coin", 44)
		add_child(c)
		c.position = from + Vector2(randf_range(-30, 30), randf_range(-24, 24))
		var mid := c.position + Vector2(randf_range(-70, 70), randf_range(-120, -50))
		var tw := c.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(c, "position", mid, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position", to - Vector2(22, 22), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			c.queue_free()
			Sfx.play("coin", -8.0, 1.0 + randf() * 0.2)
			Kit.bounce(_money_pill, 0.04))


func _on_built(uid: int) -> void:
	var b := Game.building(uid)
	if b.is_empty():
		return
	toast("%s is ready!" % Defs.BUILDINGS[b["kind"]]["name"], Defs.BUILDINGS[b["kind"]]["icon"])


func _on_job_done(j: Dictionary) -> void:
	if j["type"] == "clear":
		if selected_ob == str(j.get("ob", "")):
			deselect()
	if selected and int(j.get("uid", 0)) == selected.uid:
		_refresh_actions.call_deferred()
	if j["type"] == "build" and selected and selected.uid == int(j["uid"]):
		# the site was replaced by the real building: keep it selected
		var nb := world.building(int(j["uid"]))
		if nb:
			selected = nb
			_refresh_actions.call_deferred()


func _on_discovered(rid: String) -> void:
	var r := Defs.recipe(rid)
	_popup("New model online!", r["name"], "%s  ·  %d ms  ·  $%s a token" % [r["params"], int(r["lat"]), Fmt.num(Bal.item_value("t:" + rid))], "tk_" + rid, "Ship it!")


func _on_level_up(level: int, gems: int) -> void:
	_update_level()
	Sfx.play("levelup", -2.0)
	Kit.bounce(_lvl_box, 0.2)
	_popup("Lab level %d!" % level, Defs.level_title(level), "+%d sparks" % gems if gems > 0 else "", "star", "Awesome!")
	Fx.burst(get_tree().current_scene, world.cam.global_position + Vector3(0, 4, 0), Pal.GOLD, 30)


func _offline_popup(amount: float) -> void:
	var away := Fmt.time(Game.offline_seconds)
	var toks := ("  ·  %s tokens" % Fmt.num(Game.offline_tokens)) if Game.offline_tokens > 0 else ""
	_popup("Welcome back!", "You were away %s. Your servers kept serving and your builders kept building." % away, "+$%s%s" % [Fmt.num(amount), toks], "cash", "Collect", func():
		Game.add_money(amount)
		Game.add_tokens(Game.offline_tokens)
		Game.offline_reward = 0
		Game.offline_tokens = 0
		Sfx.play("cash"))


func _popup(head: String, sub: String, text: String, icon: String, btn_text: String, on_ok := Callable(), cancel := false) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.05, 0.03, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Kit.skin("panel", 60, Vector4(36, 40, 36, 40)))
	card.custom_minimum_size = Vector2(minf(540, get_viewport_rect().size.x - 40), 0)
	root.add_child(card)
	var v := Kit.vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var ic := Kit.icon(icon, 120)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var h := Kit.game(head, 50, Color(1.0, 0.86, 0.42), 10)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(h)
	var s := Kit.game(sub, 24, Kit.INK, 0)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	var t := Kit.game(text, 24, Color(0.3, 0.55, 0.22), 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	v.add_child(Kit.spacer(0, 8))
	var close_it := func():
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 0.0, 0.2)
		tw.tween_callback(root.queue_free)
	var row := Kit.hbox(12)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	v.add_child(row)
	if cancel:
		var c := Kit.juicy("Later", Kit.PAPER_DARK, Kit.LINE, 24, Vector2(170, 80))
		c.pressed.connect(close_it)
		row.add_child(c)
	var b := Kit.juicy(btn_text, Kit.SAGE, Kit.SAGE_EDGE, 26, Vector2(260, 80))
	b.pressed.connect(func():
		if on_ok.is_valid():
			on_ok.call()
		close_it.call())
	row.add_child(b)
	var center := func():
		card.size = card.get_combined_minimum_size()
		card.position = (get_viewport_rect().size - card.size) * 0.5
		card.pivot_offset = card.size * 0.5
	center.call_deferred()
	card.minimum_size_changed.connect(center)
	Kit.pop_in.call_deferred(card)
