class_name BuildingPanel
extends Sheet
## A building's card: what it's doing, its staff, the next upgrade (what
## changes, how long it takes, the price, and the look it gets), Move and
## Sell. Upgrades need a free builder.

signal move_requested(uid: int)

var world: World
var node: Building
var focus := ""
var _upgrade_btn: JuicyButton
var _lines_box: VBoxContainer
var _up_box: VBoxContainer
var _status: Label
var _staff_label: Label
var _sell_confirm := false
var _mega_btn: JuicyButton
var _staff_card: Control
var _up_card: Control


func _init() -> void:
	height_frac = 0.66


func setup(p_world: World, p_node: Building, p_focus := "") -> BuildingPanel:
	world = p_world
	node = p_node
	focus = p_focus
	title = node.def["name"]
	title_icon = node.def["icon"]
	return self


func _build() -> void:
	var head := Kit.hbox(12)
	body.add_child(head)
	if Bal.max_level(node.kind) > 1 and not node is SiteB:
		head.add_child(Kit.game("Lv %d" % node.level, 30, Color(1.0, 0.86, 0.42), 7))
	_status = Kit.label("", 18, Kit.MUTED, 0, false)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.custom_minimum_size.x = 380
	head.add_child(_status)
	var desc := Kit.label(node.def["desc"], 16, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 400
	body.add_child(desc)
	var info_card := Sheet.row_box()
	body.add_child(info_card)
	_lines_box = Kit.vbox(6)
	info_card.add_child(_lines_box)
	# staff (technicians on sources, engineers on servers and labs)
	var staff_role := ""
	if node is SourceB:
		staff_role = "tech"
	elif node is ServerB or node is MachineB:
		staff_role = "engineer"
	if staff_role != "":
		var sc := Sheet.row_box()
		_staff_card = sc
		body.add_child(sc)
		var h := Kit.hbox(10)
		sc.add_child(h)
		h.add_child(Kit.icon(staff_role, 56))
		_staff_label = Kit.game("", 20, Kit.INK, 0)
		_staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_staff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_staff_label.custom_minimum_size.x = 240
		h.add_child(_staff_label)
		var minus := Kit.juicy("", Kit.PAPER_DARK, Kit.LINE, 22, Vector2(64, 56))
		minus.set_glyph("remove", 28)
		minus.pressed.connect(func():
			if not Game.unassign(staff_role, node.uid):
				Sfx.play("deny")
			_refresh())
		h.add_child(minus)
		var plus := Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 22, Vector2(64, 56))
		plus.set_glyph("add", 30)
		plus.pressed.connect(func():
			if staff_role == "tech" and Game.workers_with("tech", node.uid) >= Bal.MAX_TECHS:
				Game.toast.emit("This source has all the technicians it can use", "tech")
				Sfx.play("deny")
				return
			if not Game.assign_courier(staff_role, node.uid):
				Sfx.play("deny")
				Kit.shake(plus)
				Game.toast.emit("Hire more staff first (Staff > Hire). One courier always stays a courier.", "hire")
				return
			Sfx.play("hire")
			_refresh())
		h.add_child(plus)
	# upgrade
	if Bal.max_level(node.kind) > 1 and not node is SiteB:
		var uc := Sheet.row_box()
		_up_card = uc
		body.add_child(uc)
		_up_box = Kit.vbox(4)
		uc.add_child(_up_box)
		_upgrade_btn = Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 24, Vector2(0, 74))
		_upgrade_btn.sound = ""
		_upgrade_btn.pressed.connect(_upgrade)
		body.add_child(_upgrade_btn)
	if node is MegaB:
		_mega_btn = Kit.juicy("", Kit.BRASS, Kit.BRASS_EDGE, 22, Vector2(0, 74))
		_mega_btn.sound = ""
		_mega_btn.pressed.connect(func():
			var p := node as MegaB
			if p.advance():
				Sfx.play("levelup")
				_refresh()
			else:
				Sfx.play("deny")
				Kit.shake(_mega_btn)
				Game.toast.emit(p.advance_block(), "mega"))
		body.add_child(_mega_btn)
	# move / sell
	if not node is SiteB:
		var row := Kit.hbox(10)
		body.add_child(row)
		var mv := Kit.juicy("Move", Kit.CHARCOAL, Kit.CHARCOAL_EDGE, 22, Vector2(0, 62))
		mv.set_glyph("move", 28)
		mv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		mv.pressed.connect(func():
			move_requested.emit(node.uid)
			close())
		row.add_child(mv)
		var sell := Kit.juicy("Sell", Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, 22, Vector2(0, 62))
		sell.set_glyph("delete", 28)
		sell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sell.pressed.connect(func():
			if _protected():
				Sfx.play("deny")
				Kit.shake(sell)
				Game.toast.emit("You need at least one of these to keep serving", "lock")
				return
			if not _sell_confirm:
				_sell_confirm = true
				var back := roundf(Bal.build_cost(node.kind, Game.count_of(node.kind) - 1) * 0.5)
				sell.set_text_value("Sell for $%s?" % Fmt.num(back) if Game.gem_price_of(node.kind) == 0 and node.kind != "hut" else "Remove?")
				Kit.shake(sell)
				return
			Game.remove(node.uid)
			close())
		row.add_child(sell)
	Game.money_changed.connect(_on_money)
	Game.workers_changed.connect(_refresh)
	Game.jobs_changed.connect(_refresh)
	node.changed.connect(_refresh)
	_refresh()
	if focus == "upgrade" and _up_card:
		_scroll_to.call_deferred(_up_card)
	elif focus == "staff" and _staff_card:
		_scroll_to.call_deferred(_staff_card)


func _scroll_to(c: Control) -> void:
	await get_tree().process_frame
	scroll.scroll_vertical = int(c.position.y)
	Kit.bounce(c, 0.04)


## The last server, solar farm, API depot or builder's hut can't be sold.
func _protected() -> bool:
	return node.kind in ["server", "src_power", "gateway", "hut"] and Game.count_of(node.kind) <= 1


func _on_money(_v: float, _d: float) -> void:
	_refresh()


var _tick := 0.0

func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(node):
		close()
		return
	_tick += dt
	if _tick > 0.5:
		_tick = 0.0
		_refresh()


func _refresh() -> void:
	if not is_instance_valid(node) or _status == null:
		return
	_status.text = node.status()
	for c in _lines_box.get_children():
		c.queue_free()
	var lines := node.info()
	if node.has_entrance() and not node.on_road() and not node is SiteB:
		lines.push_front(["lock", "No road reaches its entrance: clear the space in front so couriers can come."])
	for line in lines:
		var h := Kit.hbox(10)
		h.add_child(Kit.icon(line[0], 40))
		var l := Kit.game(line[1], 19, Kit.INK, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 300
		h.add_child(l)
		_lines_box.add_child(h)
	if _staff_label:
		var role := "tech" if node is SourceB else "engineer"
		var n := Game.workers_with(role, node.uid)
		_staff_label.text = ("%d technician%s (+1 who comes with the source)" % [n, "s" if n != 1 else ""]) if role == "tech" else ("%d engineer%s: x%.1f speed" % [n, "s" if n != 1 else "", Bal.engineer_boost(n)])
	if _up_box:
		_refresh_upgrade()
	if _mega_btn:
		var p := node as MegaB
		if p.complete():
			_mega_btn.set_text_value("Complete!")
			_mega_btn.set_colors(Kit.PAPER_DARK, Kit.LINE)
		elif p.building_stage():
			_mega_btn.set_text_value("Builders at work: %s" % Fmt.time(Game.job_left(Game.job_of(p.uid))))
			_mega_btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
		else:
			_mega_btn.set_text_value("Build %s  $%s  ·  %s" % [Defs.MEGA_STAGES[p.stage() + 1]["name"], Fmt.num(p.next_cost()), Fmt.time(p.next_time())])
			_mega_btn.set_colors(Kit.BRASS if p.can_advance() else Kit.GREY, Kit.BRASS_EDGE if p.can_advance() else Kit.GREY_EDGE)


func _refresh_upgrade() -> void:
	for c in _up_box.get_children():
		c.queue_free()
	var l := node.level
	var j := Game.job_of(node.uid)
	if not j.is_empty():
		_up_box.add_child(Kit.game("Upgrading to Lv %d" % (l + 1), 22, Kit.INK, 0))
		_up_box.add_child(Kit.label("%s left. Finish now for %s." % [Fmt.time(Game.job_left(j)), "free" if Bal.finish_gems(Game.job_left(j)) == 0 else "%d sparks" % Bal.finish_gems(Game.job_left(j))], 17, Kit.MUTED, 0))
		_upgrade_btn.set_icon("gem", 30)
		var g := Bal.finish_gems(Game.job_left(j))
		_upgrade_btn.set_text_value("Finish now" if g == 0 else "Finish  %d" % g)
		_upgrade_btn.set_colors(Kit.BRASS if Game.gems >= g else Kit.GREY, Kit.BRASS_EDGE)
		return
	var maxed := l >= Bal.max_level(node.kind)
	if maxed:
		_up_box.add_child(Kit.game("Max level!", 22, Kit.INK, 0))
		_upgrade_btn.visible = false
		return
	_up_box.add_child(Kit.game("Upgrade to Lv %d" % (l + 1), 22, Kit.INK, 0))
	for r in node.upgrade_info():
		var h2 := Kit.hbox(8)
		var a := Kit.label(r[0], 17, Kit.MUTED, 0)
		a.custom_minimum_size.x = 150
		h2.add_child(a)
		h2.add_child(Kit.game(str(r[1]), 19, Kit.INK, 0))
		h2.add_child(Kit.glyph("arrow", 20, Kit.MUTED))
		h2.add_child(Kit.game(str(r[2]), 19, Color(0.3, 0.52, 0.22), 0))
		_up_box.add_child(h2)
	var nt := Bal.next_tier_level(node.kind, l)
	if nt == l + 1:
		_up_box.add_child(Kit.label("Next level: a whole new look!", 16, Kit.TERRACOTTA_EDGE, 0))
	elif Growth.next_desc(node.kind, l) != "":
		var nl := Kit.label("Next level: %s" % Growth.next_desc(node.kind, l) + ("  ·  new look at Lv %d" % nt if nt > 0 else ""), 16, Kit.TERRACOTTA_EDGE, 0)
		nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_up_box.add_child(nl)
	elif nt > 0:
		_up_box.add_child(Kit.label("New look at Lv %d" % nt, 16, Kit.TERRACOTTA_EDGE, 0))
	var t := Bal.upgrade_time(node.kind, l)
	_up_box.add_child(Kit.label("Takes %s  ·  needs a free builder (%d / %d free)" % [Fmt.time(t) if t > 0.0 else "no time", Game.free_builders(), Game.builders()], 16, Kit.MUTED, 0))
	var cost := Bal.upgrade_cost(node.kind, l)
	_upgrade_btn.set_icon("coin", 30)
	_upgrade_btn.set_text_value("Upgrade  %s" % Fmt.num(cost))
	var ok := Game.upgrade_block(node.uid) == ""
	_upgrade_btn.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)


func _upgrade() -> void:
	var j := Game.job_of(node.uid)
	if not j.is_empty():
		var g := Bal.finish_gems(Game.job_left(j))
		if Game.finish_now(j):
			Sfx.play("upgrade")
		else:
			Sfx.play("deny")
			Kit.shake(_upgrade_btn)
			Game.toast.emit("Not enough sparks (%d needed): tap your sparks for the shop" % g, "gem")
		_refresh()
		return
	var why := Game.upgrade_block(node.uid)
	if why != "":
		Sfx.play("deny")
		Kit.shake(_upgrade_btn)
		Game.toast.emit(why, "hammer" if why.contains("builder") else "coin")
		return
	if Game.upgrade(node.uid):
		Sfx.play("upgrade")
		Kit.bounce(_upgrade_btn, 0.15)
		close()
