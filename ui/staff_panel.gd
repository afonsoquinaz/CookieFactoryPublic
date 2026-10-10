class_name StaffPanel
extends Sheet
## Hire workers and give them jobs. Haulers (gatherer, feeder, collector,
## loader) get +/- here; farmers and chefs are assigned from their farm or
## machine (tap it in the world). Each card says FROM -> TO.

signal preview_role(role: String)

var world: World
var _hire_btn: JuicyButton
var _staff_label: Label
var _cards := {}


func _init() -> void:
	title = "Staff"
	title_icon = "hire"
	height_frac = 0.68


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(12)
	v.add_child(h)
	_staff_label = Kit.game("", 20, Kit.INK, 0)
	_staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_staff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(_staff_label)
	_hire_btn = Kit.juicy("Hire", Kit.SAGE, Kit.SAGE_EDGE, 21, Vector2(230, 64))
	_hire_btn.set_glyph("hire", 28)
	_hire_btn.sound = ""
	_hire_btn.pressed.connect(_hire)
	h.add_child(_hire_btn)
	Game.money_changed.connect(func(_a, _b): _refresh())
	Game.workers_changed.connect(_refresh)


func _build() -> void:
	for role in Defs.ROLE_ORDER:
		body.add_child(_card(role))
	_refresh()


func _card(role: String) -> Control:
	var d: Dictionary = Defs.ROLES[role]
	var box := Sheet.row_box()
	box.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			preview_role.emit(role))
	var h := Kit.hbox(12)
	box.add_child(h)
	h.add_child(Kit.icon(d["icon"], 76))
	var mid := Kit.vbox(2)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	var nr := Kit.hbox(8)
	mid.add_child(nr)
	nr.add_child(Kit.game(d["name"], 25, Kit.INK, 0))
	var cnt := Kit.game("×0", 21, Kit.MUTED, 0)
	nr.add_child(cnt)
	if d.has("from"):
		mid.add_child(Kit.game("%s  ->  %s" % [d["from"], d["to"]], 16, Color(0.3, 0.45, 0.6), 0))
	var desc := Kit.label(d["desc"], 15, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 300
	mid.add_child(desc)
	var plus: JuicyButton = null
	var minus: JuicyButton = null
	if Defs.HAULER_ROLES.has(role):
		var btns := Kit.vbox(6)
		h.add_child(btns)
		plus = Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 26, Vector2(64, 54))
		plus.set_glyph("add", 30)
		plus.pressed.connect(func():
			if not Game.assign_idle(role):
				Sfx.play("deny")
				Kit.shake(_hire_btn)
				Game.toast.emit("No resting workers. Hire one!", "hire")
				return
			Sfx.play("hire", 0.0, 1.15)
			preview_role.emit(role))
		btns.add_child(plus)
		minus = Kit.juicy("", Kit.PAPER_DARK, Kit.LINE, 26, Vector2(64, 48))
		minus.set_glyph("remove", 28)
		minus.pressed.connect(func():
			if not Game.unassign(role):
				Sfx.play("deny"))
		btns.add_child(minus)
	else:
		mid.add_child(Kit.label("Assign from a %s: tap it in the world." % ("farm" if role == "farmer" else "oven or kitchen machine"), 15, Kit.TERRACOTTA_EDGE, 0))
	_cards[role] = {"count": cnt, "plus": plus, "minus": minus}
	return box


func _refresh() -> void:
	if not is_instance_valid(_staff_label):
		return
	var idle := Game.idle_workers()
	_staff_label.text = "%d / %d hired  ·  %d resting" % [Game.workers.size(), Game.cabin_capacity(), idle]
	if Game.count_of("cabin") == 0:
		_hire_btn.set_text_value("Build a Cabin")
		_hire_btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
	elif not Game.can_hire():
		_hire_btn.set_text_value("Cabins full")
		_hire_btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
	else:
		_hire_btn.set_text_value("Hire  $" + Fmt.num(Game.hire_price()))
		var ok := Game.can_afford(Game.hire_price())
		_hire_btn.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)
	for role in _cards:
		var c: Dictionary = _cards[role]
		(c["count"] as Label).text = "×%d" % Game.workers_with(role)
		if c["plus"]:
			(c["plus"] as JuicyButton).set_colors(Kit.SAGE if idle > 0 else Kit.GREY, Kit.SAGE_EDGE if idle > 0 else Kit.GREY_EDGE)
			(c["minus"] as JuicyButton).modulate.a = 1.0 if Game.workers_with(role) > 0 else 0.4


func _hire() -> void:
	if Game.count_of("cabin") == 0:
		Sfx.play("deny")
		Kit.shake(_hire_btn)
		Game.toast.emit("Build a Staff Cabin first (Build > Staff)", "cabin")
		return
	var w := Game.hire()
	if w.is_empty():
		Sfx.play("deny")
		Kit.shake(_hire_btn)
		return
	Sfx.play("hire")
	Kit.bounce(_hire_btn)
