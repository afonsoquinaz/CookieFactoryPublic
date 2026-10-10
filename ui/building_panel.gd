class_name BuildingPanel
extends Sheet
## Info for a placed building: what it does right now, its staff, the next
## upgrade (with what changes and when it gets a new look), Move and Sell.

signal move_requested(uid: int)

var world: World
var node: Building
var _upgrade_btn: JuicyButton
var _lines_box: VBoxContainer
var _up_box: VBoxContainer
var _status: Label
var _staff_label: Label
var _sell_confirm := false
var _palace_btn: JuicyButton


func _init() -> void:
	height_frac = 0.62


func setup(p_world: World, p_node: Building) -> BuildingPanel:
	world = p_world
	node = p_node
	title = _title_text()
	title_icon = _icon()
	return self


func _icon() -> String:
	if node is HopperB:
		return (node as HopperB).ing
	return node.def["icon"]


func _title_text() -> String:
	var n: String = node.def["name"]
	if node is HopperB:
		n = "%s Hopper" % Defs.item_name((node as HopperB).ing)
	return n


func _build() -> void:
	var head := Kit.hbox(12)
	body.add_child(head)
	var lv := Kit.game("Lv %d" % node.level, 30, Color(1.0, 0.86, 0.42), 7)
	if Bal.max_level(node.kind) > 1:
		head.add_child(lv)
	_status = Kit.label("", 18, Kit.MUTED, 0, false)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_status.custom_minimum_size.x = 380
	head.add_child(_status)
	var info_card := Sheet.row_box()
	body.add_child(info_card)
	_lines_box = Kit.vbox(6)
	info_card.add_child(_lines_box)
	# staff (farmers on farms, chefs on ovens / machines)
	var staff_role := ""
	if node is FarmB:
		staff_role = "farmer"
	elif node is OvenB or node is MachineB:
		staff_role = "chef"
	if staff_role != "":
		var sc := Sheet.row_box()
		body.add_child(sc)
		var h := Kit.hbox(10)
		sc.add_child(h)
		h.add_child(Kit.icon(staff_role, 56))
		_staff_label = Kit.game("", 21, Kit.INK, 0)
		_staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_staff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
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
			if staff_role == "farmer" and Game.workers_with("farmer", node.uid) >= Bal.MAX_FARMERS:
				Game.toast.emit("This farm has all the farmers it can use", "farmer")
				Sfx.play("deny")
				return
			if not Game.assign_idle(staff_role, node.uid):
				Sfx.play("deny")
				Kit.shake(plus)
				Game.toast.emit("No resting workers. Hire one in Staff" if Game.count_of("cabin") > 0 else "Build a Staff Cabin to hire workers", "hire")
				return
			Sfx.play("hire")
			_refresh())
		h.add_child(plus)
	# upgrade
	if Bal.max_level(node.kind) > 1:
		var uc := Sheet.row_box()
		body.add_child(uc)
		_up_box = Kit.vbox(4)
		uc.add_child(_up_box)
		_upgrade_btn = Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 24, Vector2(0, 70))
		_upgrade_btn.sound = ""
		_upgrade_btn.pressed.connect(_upgrade)
		body.add_child(_upgrade_btn)
	if node is PalaceB:
		_palace_btn = Kit.juicy("", Kit.BRASS, Kit.BRASS_EDGE, 24, Vector2(0, 74))
		_palace_btn.sound = ""
		_palace_btn.pressed.connect(func():
			if (node as PalaceB).advance():
				Sfx.play("levelup")
				_refresh()
			else:
				Sfx.play("deny")
				Kit.shake(_palace_btn))
		body.add_child(_palace_btn)
	# move / sell
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
			Game.toast.emit("You need at least one of these to keep baking", "lock")
			return
		if not _sell_confirm:
			_sell_confirm = true
			sell.set_text_value("Sell for $%s?" % Fmt.num(roundf(Bal.build_cost(node.kind, Game.count_of(node.kind) - 1) * 0.5)))
			Kit.shake(sell)
			return
		Game.remove(node.uid)
		close())
	row.add_child(sell)
	Game.money_changed.connect(_on_money)
	Game.workers_changed.connect(_refresh)
	node.changed.connect(_refresh)
	_refresh()
	node.flash()


## The last mixer, oven, wheat field or van can't be sold.
func _protected() -> bool:
	return node.kind in ["mixer", "oven", "farm_wheat", "dock"] and Game.count_of(node.kind) <= 1


func _on_money(_v: float, _d: float) -> void:
	_refresh()


func _process(dt: float) -> void:
	super(dt)
	if not is_instance_valid(node):
		close()


func _refresh() -> void:
	if not is_instance_valid(node) or _status == null:
		return
	_status.text = node.status()
	for c in _lines_box.get_children():
		c.queue_free()
	for line in node.info():
		var h := Kit.hbox(10)
		h.add_child(Kit.icon(line[0], 40))
		var l := Kit.game(line[1], 20, Kit.INK, 0)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		l.custom_minimum_size.x = 300
		h.add_child(l)
		_lines_box.add_child(h)
	if _staff_label:
		var role := "farmer" if node is FarmB else "chef"
		var n := Game.workers_with(role, node.uid)
		_staff_label.text = ("%d hired farmer%s (+1 who comes with the farm)" % [n, "s" if n != 1 else ""]) if role == "farmer" else ("%d chef%s: x%.1f speed" % [n, "s" if n != 1 else "", Bal.chef_boost(n)])
	if _up_box:
		for c in _up_box.get_children():
			c.queue_free()
		var l := node.level
		var maxed := l >= Bal.max_level(node.kind)
		var head := Kit.game("Max level!" if maxed else "Upgrade to Lv %d" % (l + 1), 22, Kit.INK, 0)
		_up_box.add_child(head)
		if not maxed:
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
			if nt > 0:
				var tip := Kit.label("New look at Lv %d" % nt, 16, Kit.TERRACOTTA_EDGE, 0)
				_up_box.add_child(tip)
			var cost := Bal.upgrade_cost(node.kind, l)
			_upgrade_btn.set_icon("coin", 30)
			_upgrade_btn.set_text_value(Fmt.num(cost))
			var ok := Game.can_afford(cost)
			_upgrade_btn.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)
		else:
			_upgrade_btn.visible = false
	if _palace_btn:
		var p := node as PalaceB
		if p.complete():
			_palace_btn.set_text_value("Complete!")
			_palace_btn.set_colors(Kit.PAPER_DARK, Kit.LINE)
		else:
			_palace_btn.set_text_value("Build %s  $%s" % [Defs.PALACE_STAGES[p.stage() + 1]["name"], Fmt.num(p.next_cost())])
			_palace_btn.set_colors(Kit.BRASS if p.can_advance() else Kit.GREY, Kit.BRASS_EDGE if p.can_advance() else Kit.GREY_EDGE)


func _upgrade() -> void:
	if Game.upgrade(node.uid):
		Sfx.play("upgrade")
		Kit.bounce(_upgrade_btn, 0.15)
		_refresh()
	else:
		Sfx.play("deny")
		Kit.shake(_upgrade_btn)
