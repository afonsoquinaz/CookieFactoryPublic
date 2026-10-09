extends Control
## The HUD: money and level up top, big buttons along the bottom (Upgrades,
## Workers, Cookie Rush), the floating joystick, toasts, popups, and the goal
## card that guides you (with an arrow in the world).

var world: World
var joystick: Joystick
var _money_label: Label
var _money_pill: Control
var _income_label: Label
var _lvl_label: Label
var _lvl_title: Label
var _xp_fill: Panel
var _xp_back: Panel
var _btn_up: JuicyButton
var _btn_workers: JuicyButton
var _btn_rush: JuicyButton
var _up_badge: Label
var _work_badge: Label
var _toast_box: VBoxContainer
var _sheet: Sheet
var _shown_money := 0.0
var goals: Goals
var _route_role := ""
var _bar: HBoxContainer
var _top: HBoxContainer


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick = Joystick.new()
	add_child(joystick)
	_build_top()
	_build_bottom()
	_toast_box = Kit.vbox(8)
	_toast_box.alignment = BoxContainer.ALIGNMENT_BEGIN
	add_child(_toast_box)
	goals = Goals.new()
	goals.hud = self
	goals.world = world
	add_child(goals)
	_shown_money = Game.money
	Game.money_changed.connect(_on_money)
	Game.xp_changed.connect(func(_x, _n, _l): _update_level())
	Game.level_up.connect(_on_level_up)
	Game.toast.connect(toast)
	Game.rush_changed.connect(_on_rush)
	Game.built.connect(_on_built)
	world.sold.connect(_on_sold)
	_update_level()
	if Game.offline_reward > 0:
		_offline_popup.call_deferred(Game.offline_reward)


# ---------------------------------------------------------------- top bar

func _build_top() -> void:
	var top := Kit.hbox(10)
	add_child(top)
	_top = top
	# money pill
	var pill := PanelContainer.new()
	var st := Kit.box(Color(0.2, 0.11, 0.07, 0.72), 34, 4, Color(1, 1, 1, 0.25), 4)
	st.content_margin_left = 8
	st.content_margin_right = 24
	st.content_margin_top = 2
	st.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", st)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(pill)
	_money_pill = pill
	var mh := Kit.hbox(8)
	pill.add_child(mh)
	mh.add_child(Kit.icon("coin", 64))
	var mv := Kit.vbox(-6)
	mh.add_child(mv)
	_money_label = Kit.label("0", 42, Color(1.0, 0.92, 0.5), 9)
	mv.add_child(_money_label)
	_income_label = Kit.label("", 18, Color(0.85, 1.0, 0.75), 5)
	mv.add_child(_income_label)
	top.add_child(Kit.spacer(0, 0, true))
	# level pill: star with the level number + xp bar + title
	var lp := Control.new()
	lp.custom_minimum_size = Vector2(250, 82)
	lp.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top.add_child(lp)
	_xp_back = Panel.new()
	_xp_back.add_theme_stylebox_override("panel", Kit.box(Color(0.2, 0.11, 0.07, 0.72), 16, 3, Color(1, 1, 1, 0.25)))
	_xp_back.position = Vector2(46, 18)
	_xp_back.size = Vector2(200, 34)
	lp.add_child(_xp_back)
	_xp_fill = Panel.new()
	_xp_fill.add_theme_stylebox_override("panel", Kit.box(Color(0.45, 0.85, 1.0), 12))
	_xp_fill.position = Vector2(4, 4)
	_xp_fill.size = Vector2(40, 26)
	_xp_back.add_child(_xp_fill)
	var star := Kit.icon("star", 84)
	star.position = Vector2(0, -4)
	lp.add_child(star)
	_lvl_label = Kit.label("1", 32, Kit.WHITE, 8)
	_lvl_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lvl_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_lvl_label.position = Vector2(0, 14)
	_lvl_label.size = Vector2(84, 60)
	lp.add_child(_lvl_label)
	_lvl_title = Kit.label("", 19, Kit.WHITE, 6)
	_lvl_title.position = Vector2(82, 52)
	lp.add_child(_lvl_title)
	var gear := Kit.juicy("", Kit.CREAM, Kit.CREAM_DARK, 20, Vector2(70, 70))
	gear.set_icon("gear", 50)
	gear.pressed.connect(func(): open_sheet(SettingsPanel.new()))
	top.add_child(gear)


func _update_level() -> void:
	_lvl_label.text = str(Game.level)
	_lvl_title.text = Defs.level_title(Game.level)
	var f := float(Game.xp) / maxf(1.0, Bal.xp_needed(Game.level))
	var tw := create_tween()
	tw.tween_property(_xp_fill, "size:x", maxf(26.0, (_xp_back.size.x - 8) * f), 0.3)


func _on_money(_value: int, delta: int) -> void:
	if delta > 0:
		Kit.bounce(_money_pill, 0.06)


func _layout() -> void:
	# manual layout: robust on any aspect ratio (phones, tablets, desktop)
	var vs := get_viewport_rect().size
	var safe := DisplayServer.get_display_safe_area()
	var top_inset := 0.0
	if OS.has_feature("mobile") and safe.size.y > 0:
		top_inset = safe.position.y * vs.y / float(DisplayServer.window_get_size().y)
	_top.position = Vector2(16, 18 + top_inset)
	_top.size = Vector2(vs.x - 32, 86)
	var bw := minf(vs.x - 40, 700.0)
	_bar.position = Vector2((vs.x - bw) * 0.5, vs.y - 150)
	_bar.size = Vector2(bw, 118)
	_toast_box.size = Vector2(minf(vs.x - 40, 640), 0)
	_toast_box.position = Vector2((vs.x - _toast_box.size.x) * 0.5, 250 + top_inset)
	goals.layout(vs, top_inset)


func _process(dt: float) -> void:
	_layout()
	_shown_money = lerpf(_shown_money, float(Game.money), clampf(dt * 10.0, 0.0, 1.0))
	if absf(_shown_money - Game.money) < 1.0:
		_shown_money = Game.money
	_money_label.text = Fmt.num(roundf(_shown_money))
	var inc := Game.recent_income()
	_income_label.text = ("+$%s/min" % Fmt.num(inc * 60.0)) if inc > 0.05 else ""
	_update_buttons()


# ---------------------------------------------------------------- bottom buttons

func _build_bottom() -> void:
	var bar := Kit.hbox(14)
	bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(bar)
	_bar = bar
	_btn_up = _big_button("Upgrades", "star", Kit.YELLOW, Kit.YELLOW_EDGE)
	_btn_up.pressed.connect(func(): open_sheet(UpgradePanel.new()))
	bar.add_child(_btn_up)
	_btn_workers = _big_button("Workers", "hire", Kit.BLUE, Kit.BLUE_EDGE)
	_btn_workers.pressed.connect(_open_workers)
	bar.add_child(_btn_workers)
	_btn_rush = _big_button("Rush", "boost", Kit.PINK, Kit.PINK_EDGE)
	_btn_rush.pressed.connect(_rush)
	bar.add_child(_btn_rush)
	_up_badge = _badge(_btn_up)
	_work_badge = _badge(_btn_workers)


func _big_button(t: String, ic: String, face: Color, edge: Color) -> JuicyButton:
	var b := Kit.juicy("", face, edge, 24, Vector2(200, 112))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.set_icon(ic, 70)
	b.set_text_value(t)
	return b


func _badge(b: Control) -> Label:
	var l := Kit.label("!", 30, Kit.WHITE, 8)
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", Kit.box(Kit.CORAL, 22, 4, Kit.WHITE))
	p.size = Vector2(44, 44)
	p.position = Vector2(-8, -12)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(44, 40)
	p.add_child(l)
	b.add_child(p)
	return l


func _update_buttons() -> void:
	# "!" when something is affordable / waiting
	var any := false
	for id in Bal.all_upgrade_ids():
		if Game.upgrade_available(id) and not Game.upgrade_maxed(id) and Game.can_afford(Game.upgrade_cost(id)):
			any = true
			break
	_up_badge.get_parent().visible = any
	var idle := Game.idle_workers()
	_work_badge.get_parent().visible = idle > 0 or (Game.can_hire() and Game.can_afford(Game.hire_price()))
	_work_badge.text = str(idle) if idle > 0 else "+"
	if Game.rush_active():
		_btn_rush.set_text_value("x2 %ds" % ceili(Game.rush_time))
		_btn_rush.set_colors(Kit.PURPLE, Kit.PURPLE_EDGE)
	elif Game.rush_cooldown > 0.0:
		_btn_rush.set_text_value(Fmt.time(Game.rush_cooldown))
		_btn_rush.set_colors(Kit.GREY, Kit.GREY_EDGE)
	else:
		_btn_rush.set_text_value("Rush!")
		_btn_rush.set_colors(Kit.PINK, Kit.PINK_EDGE)


func _rush() -> void:
	if Game.start_rush():
		Sfx.play("levelup", -4.0, 1.3)
		toast("Cookie Rush! Everything runs 2x for %ds" % int(Bal.RUSH_DURATION), "boost")
		Fx.burst(get_tree().current_scene, world.player.global_position + Vector3(0, 1.5, 0), Pal.PINK, 24)
	else:
		Sfx.play("deny")
		Kit.shake(_btn_rush)


func _on_rush(active: bool) -> void:
	if not active:
		toast("Cookie Rush is over", "clock")


func _open_workers() -> void:
	var p := WorkerPanel.new()
	p.world = world
	p.preview_role.connect(func(r): world.show_route(r))
	p.closed.connect(func(): world.show_route(""))
	open_sheet(p)


func open_sheet(s: Sheet) -> void:
	if is_instance_valid(_sheet):
		_sheet.queue_free()
	_sheet = s
	joystick.visible = false
	world.player.input_enabled = false
	s.closed.connect(func():
		joystick.visible = true
		world.player.input_enabled = true
		world.cam.zoom = 1.0)
	add_child(s)
	world.cam.zoom = 1.25


# ---------------------------------------------------------------- feedback

func toast(text: String, icon := "") -> void:
	var p := PanelContainer.new()
	var st := Kit.box(Color(0.2, 0.11, 0.07, 0.82), 26, 3, Color(1, 1, 1, 0.3), 6)
	st.content_margin_left = 14
	st.content_margin_right = 20
	st.content_margin_top = 6
	st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := Kit.hbox(10)
	p.add_child(h)
	if icon != "":
		h.add_child(Kit.icon(icon, 48))
	var l := Kit.label(text, 26, Kit.WHITE, 7)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 480
	h.add_child(l)
	p.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_box.add_child(p)
	if _toast_box.get_child_count() > 3:
		_toast_box.get_child(0).queue_free()
	Kit.pop_in.call_deferred(p)
	var tw := p.create_tween()
	tw.tween_interval(2.6)
	tw.tween_property(p, "modulate:a", 0.0, 0.35)
	tw.tween_callback(p.queue_free)


func _on_sold(amount: int, _count: int, where: Vector3) -> void:
	# coins fly from the truck to the money counter
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.unproject_position(where)
	var to := _money_pill.global_position + Vector2(36, 36)
	for i in mini(10, 3 + amount / 40):
		var c := Kit.icon("coin", 46)
		add_child(c)
		c.position = from + Vector2(randf_range(-40, 40), randf_range(-30, 30))
		var mid := c.position + Vector2(randf_range(-80, 80), randf_range(-140, -60))
		var tw := c.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(c, "position", mid, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position", to - Vector2(23, 23), 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			c.queue_free()
			Sfx.play("coin", -6.0, 1.0 + randf() * 0.2)
			Kit.bounce(_money_pill, 0.05))


func _on_built(id: String) -> void:
	toast("%s built!" % Defs.BUILDINGS[id]["name"], Defs.BUILDINGS[id]["icon"])
	if id == "cabin":
		toast("Open Workers to hire your first helper", "hire")


func _on_level_up(level: int, reward: int) -> void:
	Sfx.play("levelup")
	Kit.bounce(_lvl_label.get_parent(), 0.25)
	var unlocks := []
	for id in Defs.BUILD_ORDER:
		if int(Defs.BUILDINGS[id]["lvl"]) == level:
			unlocks.append(Defs.BUILDINGS[id]["name"])
	var lines := ["+$%s reward" % Fmt.num(reward)]
	if unlocks.size() > 0:
		lines.append("Unlocked: " + ", ".join(unlocks))
	_popup("Level %d!" % level, Defs.level_title(level), "\n".join(lines), "star", "Awesome!")
	Fx.burst(get_tree().current_scene, world.player.global_position + Vector3(0, 2, 0), Pal.GOLD, 36)


func _offline_popup(amount: int) -> void:
	_popup("Welcome back!", "Your workers kept baking", "+$%s" % Fmt.num(amount), "cash", "Collect", func():
		Game.add_money(amount)
		Game.offline_reward = 0
		Sfx.play("cash"))


func _popup(head: String, sub: String, text: String, icon: String, btn_text: String, on_ok := Callable()) -> void:
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.15, 0.08, 0.05, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Kit.card(36))
	card.set_anchors_preset(Control.PRESET_CENTER)
	card.custom_minimum_size = Vector2(560, 0)
	root.add_child(card)
	var v := Kit.vbox(10)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var ic := Kit.icon(icon, 150)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var h := Kit.label(head, 52, Kit.YELLOW, 12)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var s := Kit.label(sub, 28, Kit.CHOCO, 0)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(s)
	var t := Kit.label(text, 30, Color(0.2, 0.6, 0.3), 0)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	var b := Kit.juicy(btn_text, Kit.GREEN, Kit.GREEN_EDGE, 34, Vector2(300, 90))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		if on_ok.is_valid():
			on_ok.call()
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 0.0, 0.2)
		tw.tween_callback(root.queue_free))
	v.add_child(b)
	card.resized.connect(func():
		card.position = (root.size - card.size) * 0.5)
	Kit.pop_in.call_deferred(card)
