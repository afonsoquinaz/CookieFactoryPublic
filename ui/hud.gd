extends Control
## The game HUD: a framed money counter with gems, a gold-star level badge
## with its XP bar, the trending cookie, chunky buttons along the bottom
## (Build, Staff, Research, Boost), a Drop button whenever you carry
## something, toasts and popups. Tap a building to see and upgrade it; tap a
## For Sale sign to buy land. Build mode hands the screen to Placement.

var world: World
var joystick: Joystick
var goals: Goals
var title: TitleMenu
var placement: Placement
var _money_label: Label
var _money_pill: Control
var _income_label: Label
var _gem_chip: PanelContainer
var _gem_label: Label
var _trend_chip: PanelContainer
var _trend_icon: TextureRect
var _trend_label: Label
var _lvl_label: Label
var _lvl_title: Label
var _xp_fill: Control
var _xp_back: Control
var _level_box: Control
var _gear: JuicyButton
var btn_build: JuicyButton
var btn_staff: JuicyButton
var btn_research: JuicyButton
var _btn_rush: JuicyButton
var _btn_drop: JuicyButton
var _build_dot: Control
var _research_dot: Control
var _staff_dot: Label
var _toast_box: VBoxContainer
var _sheet: Sheet
var _shown_money := 0.0
var _bar: HBoxContainer
var _vignette: ColorRect
var _rush_glow := 0.0
var _xp_shown := 0.0
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
	joystick = Joystick.new()
	joystick.tapped.connect(_on_tap)
	add_child(joystick)
	_build_top()
	_build_bottom()
	_toast_box = Kit.vbox(8)
	add_child(_toast_box)
	goals = Goals.new()
	goals.hud = self
	goals.world = world
	add_child(goals)
	_shown_money = Game.money
	Game.money_changed.connect(_on_money)
	Game.gems_changed.connect(func(g):
		_gem_label.text = str(g)
		Kit.bounce(_gem_chip, 0.15))
	Game.xp_changed.connect(func(_x, _n, _l): _update_level())
	Game.level_up.connect(_on_level_up)
	Game.toast.connect(toast)
	Game.rush_changed.connect(_on_rush)
	Game.building_added.connect(_on_built)
	Game.discovered.connect(_on_discovered)
	Game.trend_changed.connect(_on_trend)
	Game.land_bought.connect(func(_c): toast("New land! Build on it.", "land"))
	world.sold.connect(_on_sold)
	Game.victory.connect(func():
		Sfx.play("levelup")
		for i in 3:
			Fx.burst(get_tree().current_scene, world.player.global_position + Vector3(randf_range(-3, 3), 3, randf_range(-3, 3)), Pal.GOLD, 40)
		_popup("Cookie Empire!", "The Grand Cookie Palace is complete. Your cookies are a legend from coast to coast.",
			"%s cookies sold  ·  %s earned  ·  %s played" % [Fmt.num(int(Game.stats["cookies"])), "$" + Fmt.num(float(Game.stats["earned"])), Fmt.time(float(Game.stats["play_time"]))],
			"palace", "Keep baking"))
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
	world.player.input_enabled = false


func _start_playing() -> void:
	playing = true
	_set_hud_visible(true)
	world.player.input_enabled = true
	for c in [_money_pill, _level_box, _gear]:
		Kit.pop_in(c, 0.2)
	if Game.offline_reward > 0:
		_offline_popup.call_deferred(Game.offline_reward)


func skip_title() -> void:
	playing = true
	_set_hud_visible(true)
	if Game.offline_reward > 0:
		_offline_popup.call_deferred(Game.offline_reward)


func _set_hud_visible(on: bool) -> void:
	for c in [_money_pill, _level_box, _gear, _bar, goals, joystick, _btn_drop, _gem_chip, _trend_chip]:
		c.visible = on
	if on:
		_gem_chip.visible = Game.gems > 0 or Game.count_of("board") > 0
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
	# trending cookie
	_trend_chip = PanelContainer.new()
	_trend_chip.add_theme_stylebox_override("panel", Kit.skin("card_dark", 26, Vector4(10, 4, 16, 8)))
	_trend_chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_trend_chip)
	var th := Kit.hbox(6)
	_trend_chip.add_child(th)
	_trend_icon = Kit.icon("cookie", 34)
	th.add_child(_trend_icon)
	_trend_label = Kit.game("", 17, Color(1.0, 0.9, 0.55), 5)
	th.add_child(_trend_label)
	# level
	var lb := Control.new()
	lb.custom_minimum_size = Vector2(240, 84)
	lb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(lb)
	_level_box = lb
	_xp_back = Panel.new()
	_xp_back.add_theme_stylebox_override("panel", Kit.skin("track", 18))
	_xp_back.position = Vector2(54, 18)
	_xp_back.size = Vector2(180, 32)
	_xp_back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lb.add_child(_xp_back)
	_xp_fill = Panel.new()
	_xp_fill.add_theme_stylebox_override("panel", Kit.skin("fill_gold", 18))
	_xp_fill.size = Vector2(40, 32)
	_xp_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_xp_back.add_child(_xp_fill)
	var star := Kit.icon("star", 84)
	star.position = Vector2(0, -6)
	lb.add_child(star)
	_lvl_label = Kit.game("1", 30, Kit.WHITE, 7)
	_lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lvl_label.position = Vector2(0, 10)
	_lvl_label.size = Vector2(84, 60)
	lb.add_child(_lvl_label)
	_lvl_title = Kit.game("", 17, Kit.WHITE, 5)
	_lvl_title.position = Vector2(64, 52)
	lb.add_child(_lvl_title)
	_gear = Kit.juicy("", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 20, Vector2(72, 72))
	_gear.set_glyph("settings", 34)
	_gear.pressed.connect(func(): open_sheet(SettingsPanel.new()))
	add_child(_gear)


func _update_level() -> void:
	_lvl_label.text = str(Game.level)
	_lvl_title.text = Defs.level_title(Game.level)


func _on_money(_value: float, delta: float) -> void:
	if delta > 0:
		Kit.bounce(_money_pill, 0.06)


func _on_trend(rid: String) -> void:
	_trend_chip.visible = rid != "" and playing
	if rid == "":
		return
	_trend_icon.texture = Icons.tex("ck_" + rid)
	_trend_label.text = "Trending: %s  x%.1f" % [Defs.recipe(rid)["name"], 1.5 + 0.1 * Game.research("market")]
	if playing:
		toast("Customers are crazy about %s right now: it sells for more!" % Defs.recipe(rid)["name"], "ck_" + rid)


# ---------------------------------------------------------------- bottom

func _build_bottom() -> void:
	_bar = Kit.hbox(12)
	_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_bar)
	btn_build = _big_button("Build", "hammer", Kit.BRASS)
	btn_build.pressed.connect(open_build)
	btn_staff = _big_button("Staff", "hire", Kit.CHARCOAL)
	btn_staff.pressed.connect(open_staff)
	btn_research = _big_button("Research", "research", Kit.CHARCOAL)
	btn_research.pressed.connect(func(): open_sheet(ResearchPanel.new()))
	_btn_rush = _big_button("Boost", "boost", Kit.TERRACOTTA)
	_btn_rush.pressed.connect(_rush)
	_build_dot = _dot(btn_build)
	_research_dot = _dot(btn_research)
	_staff_dot = _dot(btn_staff).get_child(0)
	_btn_drop = Kit.juicy("Drop", Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, 18, Vector2(150, 64))
	_btn_drop.set_glyph("delete", 26)
	_btn_drop.pressed.connect(func():
		world.player.discard_all()
		toast("Hands emptied", ""))
	_btn_drop.visible = false
	add_child(_btn_drop)


func _big_button(t: String, icon: String, face: Color) -> JuicyButton:
	var b := Kit.juicy("", face, face, 18, Vector2(138, 116))
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
	p.position = Vector2(112, -8)
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
		Sfx.play("open", -6.0)
	elif not on:
		b.visible = false


var _dot_cd := 0.0

func _update_buttons(dt: float) -> void:
	_show_button(btn_build, true)
	_show_button(btn_staff, Game.level >= 2 or Game.count_of("cabin") > 0)
	_show_button(btn_research, int(Game.stats["cookies"]) > 0)
	_show_button(_btn_rush, Game.level >= 3)
	_btn_drop.visible = world.player.carry.count() > 0 and _sheet == null and placement == null
	_gem_chip.visible = Game.gems > 0 or Game.count_of("board") > 0
	_dot_cd -= dt
	if _dot_cd <= 0.0:
		_dot_cd = 0.5
		var any := false
		for id in Bal.RESEARCH_ORDER:
			if not Game.research_maxed(id) and Game.can_afford(Game.research_cost(id)):
				any = true
				break
		_research_dot.visible = any
		var can_build := false
		for kind in Defs.BUILD_ORDER:
			if Game.unlocked(kind) and Game.count_of(kind) == 0 and Game.can_afford(Game.price_of(kind)) and Defs.BUILDINGS[kind]["cat"] != "decor":
				can_build = true
				break
		_build_dot.visible = can_build
		var idle := Game.idle_workers()
		_staff_dot.get_parent().visible = idle > 0 or (Game.can_hire() and Game.can_afford(Game.hire_price()))
		_staff_dot.text = str(idle) if idle > 0 else "+"
	if _sheet != null:
		_build_dot.visible = false
		_research_dot.visible = false
		_staff_dot.get_parent().visible = false
	var rl: Label = _btn_rush.get_meta("label")
	if Game.rush_active():
		rl.text = "x2  %ds" % ceili(Game.rush_time)
	elif Game.rush_cooldown > 0.0:
		rl.text = Fmt.time(Game.rush_cooldown)
	else:
		rl.text = "Boost"
	_btn_rush.set_colors(Kit.GREY if Game.rush_cooldown > 0.0 and not Game.rush_active() else Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE)


func _rush() -> void:
	if Game.start_rush():
		Sfx.play("levelup", -6.0, 1.2)
		toast("Boost! Everything runs twice as fast for %ds" % int(Bal.rush_duration()), "boost")
	else:
		Sfx.play("deny")
		Kit.shake(_btn_rush)


func _on_rush(active: bool) -> void:
	if not active:
		toast("Boost finished", "clock")


func open_build() -> void:
	var p := BuildPanel.new()
	p.chosen.connect(func(kind, ing): start_placement.call_deferred(kind, ing, 0))
	open_sheet(p)


func open_staff() -> void:
	var p := StaffPanel.new()
	p.world = world
	p.preview_role.connect(func(r): world.show_route(r))
	p.closed.connect(func(): world.show_route(""))
	open_sheet(p)


func open_building(n: Building) -> void:
	var p := BuildingPanel.new().setup(world, n)
	p.move_requested.connect(func(uid): start_placement.call_deferred(n.kind, "", uid))
	open_sheet(p)


func open_sheet(s: Sheet) -> void:
	if is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = s
	joystick.visible = false
	world.player.input_enabled = false
	goals.visible = false
	s.closed.connect(func():
		if _sheet == s:
			_sheet = null
		if placement == null:
			joystick.visible = playing
			world.player.input_enabled = playing
			goals.visible = playing
			world.cam.zoom = 1.0)
	add_child(s)
	world.cam.zoom = 1.2


# ---------------------------------------------------------------- build mode

func start_placement(kind: String, ing := "", move_uid := 0) -> void:
	if placement:
		placement.finish(false)
	placement = Placement.new().setup(world, kind, ing, move_uid)
	placement.finished.connect(func(placed):
		placement = null
		_set_hud_visible(true)
		world.cam.zoom = 1.0
		if placed and move_uid == 0:
			toast("%s built!" % Defs.BUILDINGS[kind]["name"], Defs.BUILDINGS[kind]["icon"]))
	for c in [_bar, joystick, goals, _btn_drop, _trend_chip]:
		c.visible = false
	add_child(placement)
	world.cam.zoom = 1.35


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
			_land_popup(chunk)
			return
	# buildings: test along the ray from a little above the ground
	for y in [1.2, 0.6, 0.0]:
		var p2: Vector3 = o + d * ((y - o.y) / d.y)
		var b := world.building_at(p2)
		if b:
			Sfx.play("click")
			open_building(b)
			return


func _land_popup(chunk: Vector2i) -> void:
	var b := Terrain.biome(chunk)
	var bonus := []
	for i in Defs.BIOMES[b]["bonus"]:
		bonus.append(Defs.item_name(i))
	var price := Game.land_price()
	_popup(Defs.BIOMES[b]["name"], "Farms of %s grow 40%% faster here." % ", ".join(bonus), "$%s" % Fmt.num(price), "land",
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
	_level_box.size = _level_box.custom_minimum_size
	_level_box.position = Vector2(_gear.position.x - _level_box.size.x - 10, 12 + top)
	_trend_chip.size = _trend_chip.get_combined_minimum_size()
	_trend_chip.position = Vector2(vs.x - _trend_chip.size.x - 14, 92 + top)
	var bs := _bar.get_combined_minimum_size()
	_bar.size = Vector2(vs.x, bs.y)
	_bar.position = Vector2(0, vs.y - bs.y - 30)
	_btn_drop.size = _btn_drop.custom_minimum_size
	_btn_drop.position = Vector2(18, _bar.position.y - _btn_drop.size.y - 18)
	_toast_box.size = Vector2(minf(vs.x - 40, 600), 0)
	_toast_box.position = Vector2((vs.x - _toast_box.size.x) * 0.5, 200 + top)
	goals.layout(vs, top + (40.0 if _trend_chip.visible else 0.0))


func _process(dt: float) -> void:
	_layout()
	_shown_money = lerpf(_shown_money, Game.money, clampf(dt * 10.0, 0.0, 1.0))
	if absf(_shown_money - Game.money) < 1.0:
		_shown_money = Game.money
	_money_label.text = Fmt.num(roundf(_shown_money))
	var inc := Game.recent_income()
	_income_label.text = ("+%s/min" % Fmt.num(inc * 60.0)) if inc > 0.05 else ""
	var f := Game.xp / maxf(1.0, Bal.xp_needed(Game.level))
	_xp_shown = move_toward(_xp_shown, f, dt * 1.5) if f >= _xp_shown else f
	_xp_fill.size.x = maxf(30.0, _xp_back.size.x * _xp_shown)
	if playing and placement == null:
		_update_buttons(dt)
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


func _on_built(b: Dictionary) -> void:
	if b["kind"] == "cabin" and Game.count_of("cabin") == 1:
		toast("Tap Staff to hire your first worker", "hire")


func _on_discovered(rid: String) -> void:
	var r := Defs.recipe(rid)
	_popup("New cookie!", r["name"], "Sells for $%s each" % Fmt.num(Bal.item_value("c:" + rid)), "ck_" + rid, "Yum!")


func _on_level_up(level: int, reward: float) -> void:
	Sfx.play("levelup", -2.0)
	Kit.bounce(_level_box, 0.2)
	var unlocks := []
	for id in Defs.BUILD_ORDER:
		if int(Defs.BUILDINGS[id]["lvl"]) == level:
			unlocks.append(Defs.BUILDINGS[id]["name"])
	var lines := ["+$%s reward" % Fmt.num(reward)]
	if unlocks.size() > 0:
		lines.append("New: " + ", ".join(unlocks))
	_popup("Level %d!" % level, Defs.level_title(level), "\n".join(lines), "star", "Awesome!")
	Fx.burst(get_tree().current_scene, world.player.global_position + Vector3(0, 2, 0), Pal.GOLD, 26)


func _offline_popup(amount: float) -> void:
	_popup("Welcome back!", "Your staff kept baking while you were away", "+$%s" % Fmt.num(amount), "cash", "Collect", func():
		Game.add_money(amount)
		Game.offline_reward = 0
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
	var t := Kit.game(text, 26, Color(0.3, 0.55, 0.22), 0)
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
