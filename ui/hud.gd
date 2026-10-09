extends Control
## The HUD, kept calm: money top-left, level ring top-right, a slim goal line
## under them, and round glass buttons along the bottom that only appear once
## they mean something (Upgrades after your first sale, Staff after the
## cabin, Boost from level 3). Also toasts, popups and the joystick.

var world: World
var joystick: Joystick
var goals: Goals
var _money_label: Label
var _money_pill: Control
var _income_label: Label
var _ring: LevelRing
var _lvl_title: Label
var _gear: Control
var _btn_up: JuicyButton
var _btn_workers: JuicyButton
var _btn_rush: JuicyButton
var _up_dot: Control
var _work_dot: Label
var _toast_box: VBoxContainer
var _sheet: Sheet
var _shown_money := 0.0
var _bar: HBoxContainer
var _top_left: Control
var _top_right: HBoxContainer
var _vignette: ColorRect
var _rush_glow := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_vignette = ColorRect.new()
	_vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vm := ShaderMaterial.new()
	vm.shader = preload("res://render/vignette.gdshader")
	vm.set_shader_parameter("color", Color(0.85, 0.66, 0.36))
	_vignette.material = vm
	add_child(_vignette)
	joystick = Joystick.new()
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
	Game.xp_changed.connect(func(_x, _n, _l): _update_level())
	Game.level_up.connect(_on_level_up)
	Game.toast.connect(toast)
	Game.rush_changed.connect(_on_rush)
	Game.built.connect(_on_built)
	world.sold.connect(_on_sold)
	_update_level()
	if Game.offline_reward > 0:
		_offline_popup.call_deferred(Game.offline_reward)


# ---------------------------------------------------------------- top

func _build_top() -> void:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", Kit.glass(30))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(pill)
	_money_pill = pill
	_top_left = pill
	var mh := Kit.hbox(10)
	pill.add_child(mh)
	mh.add_child(Kit.icon("coin", 46))
	var mv := Kit.vbox(-8)
	mh.add_child(mv)
	_money_label = Kit.title("0", 40, Kit.WHITE)
	mv.add_child(_money_label)
	_income_label = Kit.label("", 15, Color(0.86, 0.84, 0.8), 0, false)
	mv.add_child(_income_label)
	_top_right = Kit.hbox(12)
	add_child(_top_right)
	var tv := Kit.vbox(-2)
	tv.alignment = BoxContainer.ALIGNMENT_CENTER
	_top_right.add_child(tv)
	_lvl_title = Kit.label("", 17, Kit.WHITE, 1)
	_lvl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tv.add_child(_lvl_title)
	_ring = LevelRing.new()
	_ring.custom_minimum_size = Vector2(70, 70)
	_top_right.add_child(_ring)
	var gear := JuicyButton.new()
	gear.setup("", Kit.GLASS, Color(0, 0, 0, 0.2), 20, Vector2(62, 62))
	gear.set_glyph("settings", 32)
	gear.pressed.connect(func(): open_sheet(SettingsPanel.new()))
	_top_right.add_child(gear)
	_gear = gear


func _update_level() -> void:
	_ring.level = Game.level
	_ring.target = float(Game.xp) / maxf(1.0, Bal.xp_needed(Game.level))
	_lvl_title.text = Defs.level_title(Game.level)


func _on_money(_value: int, delta: int) -> void:
	if delta > 0:
		Kit.bounce(_money_pill, 0.04)


# ---------------------------------------------------------------- bottom

func _build_bottom() -> void:
	_bar = Kit.hbox(18)
	_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(_bar)
	_btn_up = _round_button("Upgrades", "upgrades")
	_btn_up.pressed.connect(func(): open_sheet(UpgradePanel.new()))
	_btn_workers = _round_button("Staff", "staff")
	_btn_workers.pressed.connect(_open_workers)
	_btn_rush = _round_button("Boost", "boost")
	_btn_rush.pressed.connect(_rush)
	_up_dot = _dot(_btn_up)
	_work_dot = _dot(_btn_workers).get_child(0)


func _round_button(t: String, g: String) -> JuicyButton:
	var b := JuicyButton.new()
	b.setup("", Kit.GLASS, Color(0, 0, 0, 0.25), 15, Vector2(132, 92))
	b.row.queue_free()
	var v := Kit.vbox(0)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	v.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	b.add_child(v)
	var gl := Kit.glyph(g, 36, Kit.WHITE)
	v.add_child(gl)
	var l := Kit.label(t, 16, Color(0.92, 0.9, 0.86))
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
	p.add_theme_stylebox_override("panel", Kit.box(Kit.TERRACOTTA, 14))
	p.size = Vector2(28, 28)
	p.position = Vector2(104, -6)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := Kit.label("", 15, Kit.WHITE)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.size = Vector2(28, 28)
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


func _update_buttons() -> void:
	_show_button(_btn_up, int(Game.stats["cookies"]) > 0 or Game.money >= 15)
	_show_button(_btn_workers, Game.has_building("cabin"))
	_show_button(_btn_rush, Game.level >= 3)
	var any := false
	for id in Bal.all_upgrade_ids():
		if Game.upgrade_available(id) and not Game.upgrade_maxed(id) and Game.can_afford(Game.upgrade_cost(id)):
			any = true
			break
	_up_dot.visible = any
	var idle := Game.idle_workers()
	_work_dot.get_parent().visible = idle > 0 or (Game.can_hire() and Game.can_afford(Game.hire_price()))
	_work_dot.text = str(idle) if idle > 0 else "+"
	var rl: Label = _btn_rush.get_meta("label")
	if Game.rush_active():
		rl.text = "x2  %ds" % ceili(Game.rush_time)
	elif Game.rush_cooldown > 0.0:
		rl.text = Fmt.time(Game.rush_cooldown)
	else:
		rl.text = "Boost"
	_btn_rush.modulate.a = 0.6 if Game.rush_cooldown > 0.0 and not Game.rush_active() else 1.0


func _rush() -> void:
	if Game.start_rush():
		Sfx.play("levelup", -6.0, 1.2)
		toast("Boost: everything runs twice as fast for %ds" % int(Bal.RUSH_DURATION), "boost")
	else:
		Sfx.play("deny")
		Kit.shake(_btn_rush)


func _on_rush(active: bool) -> void:
	if not active:
		toast("Boost finished", "clock")


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
	goals.visible = false
	s.closed.connect(func():
		joystick.visible = true
		world.player.input_enabled = true
		goals.visible = true
		world.cam.zoom = 1.0)
	add_child(s)
	world.cam.zoom = 1.2


# ---------------------------------------------------------------- layout + frame

func _layout() -> void:
	var vs := get_viewport_rect().size
	var top := 0.0
	if OS.has_feature("mobile"):
		var safe := DisplayServer.get_display_safe_area()
		if safe.size.y > 0:
			top = safe.position.y * vs.y / float(DisplayServer.window_get_size().y)
	_top_left.position = Vector2(18, 20 + top)
	_top_left.size = _top_left.get_combined_minimum_size()
	var trs := _top_right.get_combined_minimum_size()
	_top_right.size = trs
	_top_right.position = Vector2(vs.x - trs.x - 18, 16 + top)
	var bs := _bar.get_combined_minimum_size()
	_bar.size = Vector2(vs.x, bs.y)
	_bar.position = Vector2(0, vs.y - bs.y - 34)
	_toast_box.size = Vector2(minf(vs.x - 40, 600), 0)
	_toast_box.position = Vector2((vs.x - _toast_box.size.x) * 0.5, 190 + top)
	goals.layout(vs, top)


func _process(dt: float) -> void:
	_layout()
	_shown_money = lerpf(_shown_money, float(Game.money), clampf(dt * 10.0, 0.0, 1.0))
	if absf(_shown_money - Game.money) < 1.0:
		_shown_money = Game.money
	_money_label.text = Fmt.num(roundf(_shown_money))
	var inc := Game.recent_income()
	_income_label.text = ("+$%s / min" % Fmt.num(inc * 60.0)) if inc > 0.05 else ""
	_income_label.visible = _income_label.text != ""
	_update_buttons()
	_rush_glow = move_toward(_rush_glow, 1.0 if Game.rush_active() else 0.0, dt * 2.0)
	(_vignette.material as ShaderMaterial).set_shader_parameter("strength", _rush_glow)
	_vignette.visible = _rush_glow > 0.001


# ---------------------------------------------------------------- feedback

func toast(text: String, icon := "") -> void:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", Kit.glass(22))
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var h := Kit.hbox(10)
	p.add_child(h)
	if icon != "":
		h.add_child(Kit.icon(icon, 36))
	var l := Kit.label(text, 19, Kit.WHITE)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 420
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
	var cam := get_viewport().get_camera_3d()
	if cam == null:
		return
	var from := cam.unproject_position(where)
	var to := _money_pill.global_position + Vector2(32, 34)
	for i in mini(8, 3 + amount / 40):
		var c := Kit.icon("coin", 38)
		add_child(c)
		c.position = from + Vector2(randf_range(-30, 30), randf_range(-24, 24))
		var mid := c.position + Vector2(randf_range(-60, 60), randf_range(-110, -50))
		var tw := c.create_tween()
		tw.tween_interval(i * 0.05)
		tw.tween_property(c, "position", mid, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "position", to - Vector2(19, 19), 0.42).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tw.tween_callback(func():
			c.queue_free()
			Sfx.play("coin", -8.0, 1.0 + randf() * 0.2)
			Kit.bounce(_money_pill, 0.03))


func _on_built(id: String) -> void:
	var d: Dictionary = Defs.BUILDINGS[id]
	if id.begins_with("plot_"):
		toast("%s ready. New recipe: %s, $%d each" % [d["name"], Defs.COOKIE_GRADES[Game.cookie_grade()], Game.cookie_price()], d["icon"])
	else:
		toast("%s built" % d["name"], d["icon"])
	if id == "cabin":
		toast("Tap Staff to hire your first worker", "hire")


func _on_level_up(level: int, reward: int) -> void:
	Sfx.play("levelup", -2.0)
	Kit.bounce(_ring, 0.15)
	var unlocks := []
	for id in Defs.BUILD_ORDER:
		if int(Defs.BUILDINGS[id]["lvl"]) == level:
			unlocks.append(Defs.BUILDINGS[id]["name"])
	var lines := ["+$%s reward" % Fmt.num(reward)]
	if unlocks.size() > 0:
		lines.append("New: " + ", ".join(unlocks))
	_popup("Level %d" % level, Defs.level_title(level), "\n".join(lines), "star", "Continue")


func _offline_popup(amount: int) -> void:
	_popup("Welcome back", "Your staff kept baking while you were away", "+$%s" % Fmt.num(amount), "cash", "Collect", func():
		Game.add_money(amount)
		Game.offline_reward = 0
		Sfx.play("cash"))


func _popup(head: String, sub: String, text: String, icon: String, btn_text: String, on_ok := Callable()) -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(root)
	var dim := ColorRect.new()
	dim.color = Color(0.08, 0.06, 0.05, 0.45)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.add_child(dim)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Kit.card(30))
	card.custom_minimum_size = Vector2(minf(520, get_viewport_rect().size.x - 48), 0)
	root.add_child(card)
	var v := Kit.vbox(8)
	v.alignment = BoxContainer.ALIGNMENT_CENTER
	card.add_child(v)
	var ic := Kit.icon(icon, 110)
	ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ic)
	var h := Kit.title(head, 50, Kit.INK)
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(h)
	var s := Kit.label(sub, 20, Kit.MUTED, 0, false)
	s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(s)
	v.add_child(Kit.spacer(0, 6))
	var t := Kit.label(text, 22, Kit.SAGE_EDGE)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(t)
	v.add_child(Kit.spacer(0, 10))
	var b := Kit.juicy(btn_text, Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 22, Vector2(260, 64))
	b.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func():
		if on_ok.is_valid():
			on_ok.call()
		var tw := root.create_tween()
		tw.tween_property(root, "modulate:a", 0.0, 0.2)
		tw.tween_callback(root.queue_free))
	v.add_child(b)
	var center := func():
		card.size = card.get_combined_minimum_size()
		card.position = (get_viewport_rect().size - card.size) * 0.5
		card.pivot_offset = card.size * 0.5
	center.call_deferred()
	card.minimum_size_changed.connect(center)
	Kit.pop_in.call_deferred(card)
