class_name StaffPanel
extends Sheet
## Your staff. Everyone you hire starts as a courier (they carry everything
## along the roads, no setup needed). On a source, server or lab, + turns a
## courier into a technician or engineer who works there. Staff Housing decides how
## many people you can house.

var _hire_btn: JuicyButton
var _staff_label: Label
var _cards := {}


func _init() -> void:
	title = "Staff"
	title_icon = "hire"
	height_frac = 0.62


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(12)
	v.add_child(h)
	_staff_label = Kit.game("", 20, Kit.INK, 0)
	_staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_staff_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	h.add_child(_staff_label)
	_hire_btn = Kit.juicy("Hire", Kit.SAGE, Kit.SAGE_EDGE, 21, Vector2(250, 64))
	_hire_btn.set_glyph("hire", 28)
	_hire_btn.sound = ""
	_hire_btn.pressed.connect(_hire)
	h.add_child(_hire_btn)
	Game.money_changed.connect(func(_a, _b): _refresh())
	Game.workers_changed.connect(_refresh)


func _build() -> void:
	for role in Defs.ROLE_ORDER:
		body.add_child(_card(role))
	var b := Sheet.row_box()
	var h := Kit.hbox(12)
	b.add_child(h)
	h.add_child(Kit.icon("builder", 76))
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Kit.game("Builders  ×%d" % Game.builders(), 24, Kit.INK, 0))
	var d := Kit.label("Build and upgrade. Each Builder's Hut houses one; more huts cost sparks (Build > Campus).", 15, Kit.MUTED, 0, false)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	d.custom_minimum_size.x = 300
	v.add_child(d)
	body.add_child(b)
	_refresh()


func _card(role: String) -> Control:
	var d: Dictionary = Defs.ROLES[role]
	var box := Sheet.row_box()
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
	var desc := Kit.label(d["desc"], 15, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 300
	mid.add_child(desc)
	if role != "courier":
		mid.add_child(Kit.label("Tap a %s in the world, then Staff, then +." % ("source" if role == "tech" else "server or lab"), 15, Kit.TERRACOTTA_EDGE, 0))
	_cards[role] = cnt
	return box


func _refresh() -> void:
	if not is_instance_valid(_staff_label):
		return
	_staff_label.text = "%d / %d housed" % [Game.workers.size(), Game.dorm_capacity()]
	if not Game.can_hire():
		_hire_btn.set_text_value("Full: build a Cabin")
		_hire_btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
	else:
		_hire_btn.set_text_value("Hire courier  $" + Fmt.num(Game.hire_price()))
		var ok := Game.can_afford(Game.hire_price())
		_hire_btn.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)
	for role in _cards:
		(_cards[role] as Label).text = "×%d" % Game.workers_with(role)


func _hire() -> void:
	if not Game.can_hire():
		Sfx.play("deny")
		Kit.shake(_hire_btn)
		Game.toast.emit("No room: build or upgrade a Staff Cabin", "dorm")
		return
	var w := Game.hire()
	if w.is_empty():
		Sfx.play("deny")
		Kit.shake(_hire_btn)
		return
	Sfx.play("hire")
	Kit.bounce(_hire_btn)
