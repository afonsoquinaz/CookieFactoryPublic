class_name WorkerPanel
extends Sheet
## Hire workers and give them jobs. Each role card shows the role's look
## (portrait, colour), exactly what they'll do as "FROM → TO" with icons, a
## short sentence, how many are on it, and -/+ to assign from the idle pool.
## Tapping a card shows that role's route in the world.

signal preview_role(role: String)

var world: World
var _hire_btn: JuicyButton
var _staff_label: Label
var _cards := {}       # role -> {count, plus, minus, chips}


func _init() -> void:
	title = "Workers"
	title_icon = "hire"
	height_frac = 0.66


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(12)
	v.add_child(h)
	_staff_label = Kit.label("", 26, Kit.CHOCO, 0)
	_staff_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(_staff_label)
	_hire_btn = Kit.juicy("Hire", Kit.GREEN, Kit.GREEN_EDGE, 28, Vector2(250, 78))
	_hire_btn.set_icon("hire", 50)
	_hire_btn.sound = ""
	_hire_btn.pressed.connect(_hire)
	h.add_child(_hire_btn)
	Game.money_changed.connect(_on_money)
	Game.workers_changed.connect(_refresh)


func _on_money(_m: int, _d: int) -> void:
	_refresh()


func _build() -> void:
	for role in Defs.ROLE_ORDER:
		body.add_child(_card(role))
	_refresh()


func _card(role: String) -> Control:
	var d: Dictionary = Defs.ROLES[role]
	var col: Color = d["color"]
	var box := Sheet.row_box(Color(1, 1, 1, 0.85), col.darkened(0.15) if role != "collector" else Color(0.8, 0.78, 0.75))
	box.gui_input.connect(func(e):
		if (e is InputEventMouseButton or e is InputEventScreenTouch) and e.pressed:
			preview_role.emit(role))
	var v := Kit.vbox(6)
	box.add_child(v)
	var h := Kit.hbox(12)
	v.add_child(h)
	h.add_child(Kit.icon(d["icon"], 96))
	var mid := Kit.vbox(4)
	mid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(mid)
	var name_row := Kit.hbox(8)
	mid.add_child(name_row)
	var nl := Kit.label(d["name"], 30, col if role != "collector" else Color(0.55, 0.5, 0.48), 0)
	name_row.add_child(nl)
	var cnt := Kit.label("×0", 26, Kit.WHITE, 7)
	name_row.add_child(cnt)
	# FROM → TO
	var flow := Kit.hbox(6)
	mid.add_child(flow)
	flow.add_child(Kit.icon(_place_icon(d["from"]), 40))
	flow.add_child(Kit.label(_place_name(d["from"]), 20, Kit.CHOCO, 0))
	flow.add_child(Kit.label("  →  ", 24, col.darkened(0.2) if role != "collector" else Kit.CHOCO, 0))
	flow.add_child(Kit.icon(_place_icon(d["to"]), 40))
	flow.add_child(Kit.label(_place_name(d["to"]), 20, Kit.CHOCO, 0))
	var desc := Kit.label(d["desc"], 19, Color(0.5, 0.36, 0.28), 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 330
	mid.add_child(desc)
	var btns := Kit.vbox(6)
	h.add_child(btns)
	var plus := Kit.juicy("+", Kit.GREEN, Kit.GREEN_EDGE, 36, Vector2(78, 62))
	plus.pressed.connect(func(): _add(role, ""))
	btns.add_child(plus)
	var minus := Kit.juicy("−", Kit.CORAL, Kit.CORAL_EDGE, 36, Vector2(78, 56))
	minus.pressed.connect(func(): _remove(role, ""))
	btns.add_child(minus)
	var lock := Kit.label("", 22, Kit.CORAL_EDGE, 0)
	v.add_child(lock)
	var chips := {}
	if role == "farmer":
		# one chip per farm: tap to send a farmer there
		plus.visible = false
		minus.visible = false
		var row := Kit.hbox(6)
		v.add_child(row)
		for ing in Defs.INGREDIENTS:
			var chip := Kit.juicy("", Kit.CREAM, Kit.CREAM_DARK, 22, Vector2(0, 66))
			chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			chip.set_icon(ing, 40)
			chip.text_label.label_settings = chip.text_label.label_settings.duplicate()
			chip.text_label.label_settings.font_color = Kit.CHOCO
			chip.text_label.label_settings.outline_size = 0
			chip.pressed.connect(func(): _add("farmer", ing))
			row.add_child(chip)
			chips[ing] = chip
		var hint := Kit.label("Tap a farm to add a farmer · long-press the farmer count to remove", 16, Color(0.55, 0.42, 0.34), 0, false)
		hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		v.add_child(hint)
		var rm := Kit.juicy("− remove a farmer", Kit.CORAL, Kit.CORAL_EDGE, 20, Vector2(0, 50))
		rm.pressed.connect(func(): _remove("farmer", ""))
		v.add_child(rm)
		hint.visible = false
	_cards[role] = {"count": cnt, "plus": plus, "minus": minus, "chips": chips, "lock": lock, "box": box}
	return box


static func _place_icon(p: String) -> String:
	match p:
		"farm": return "farm"
		"pantry": return "storage"
		"hopper": return "hopper"
		"oven": return "oven"
		"shelf": return "storage"
		"truck": return "truck"
	return "star"


static func _place_name(p: String) -> String:
	match p:
		"farm": return "Farms"
		"pantry": return "Pantry"
		"hopper": return "Hoppers"
		"oven": return "Oven"
		"shelf": return "Shelf"
		"truck": return "Truck"
	return p


func _refresh() -> void:
	if not is_instance_valid(_staff_label):
		return
	var idle := Game.idle_workers()
	_staff_label.text = "Staff %d/%d  ·  %d resting" % [Game.workers.size(), Game.cabin_capacity(), idle]
	var can := Game.can_hire()
	if not Game.has_building("cabin"):
		_hire_btn.set_text_value("Build Cabin")
		_hire_btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
	elif not can:
		_hire_btn.set_text_value("Cabin full")
		_hire_btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
	else:
		_hire_btn.set_text_value("Hire  $" + Fmt.num(Game.hire_price()))
		var ok := Game.can_afford(Game.hire_price())
		_hire_btn.set_colors(Kit.GREEN if ok else Kit.GREY, Kit.GREEN_EDGE if ok else Kit.GREY_EDGE)
	for role in _cards:
		var c: Dictionary = _cards[role]
		var unlocked := Game.role_unlocked(role)
		(c["count"] as Label).text = "×%d" % Game.workers_with(role)
		var lock: Label = c["lock"]
		lock.visible = not unlocked
		lock.text = "Needs the %s" % Defs.BUILDINGS[Defs.ROLES[role]["needs"]]["name"]
		(c["box"] as Control).modulate = Color(1, 1, 1, 1.0 if unlocked else 0.55)
		(c["plus"] as JuicyButton).set_colors(Kit.GREEN if unlocked and idle > 0 else Kit.GREY, Kit.GREEN_EDGE if unlocked and idle > 0 else Kit.GREY_EDGE)
		(c["minus"] as JuicyButton).set_colors(Kit.CORAL if Game.workers_with(role) > 0 else Kit.GREY, Kit.CORAL_EDGE if Game.workers_with(role) > 0 else Kit.GREY_EDGE)
		for ing in c["chips"]:
			var chip: JuicyButton = c["chips"][ing]
			var n := Game.workers_with("farmer", ing)
			chip.set_text_value("%d" % (n + 1))
			chip.set_colors(Kit.CREAM if n < Bal.MAX_FARMERS_PER_FARM else Kit.CREAM_DARK, Kit.CREAM_DARK)


func _hire() -> void:
	if not Game.has_building("cabin"):
		Sfx.play("deny")
		Kit.shake(_hire_btn)
		Game.toast.emit("Build the Staff Cabin first!", "worker")
		return
	var w := Game.hire()
	if w.is_empty():
		Sfx.play("deny")
		Kit.shake(_hire_btn)
		return
	Sfx.play("hire")
	Kit.bounce(_hire_btn)


func _add(role: String, target: String) -> void:
	if not Game.role_unlocked(role):
		Sfx.play("deny")
		Kit.shake(_cards[role]["box"])
		Game.toast.emit("Build the %s first!" % Defs.BUILDINGS[Defs.ROLES[role]["needs"]]["name"], "lock")
		return
	if role == "farmer" and Game.workers_with("farmer", target) >= Bal.MAX_FARMERS_PER_FARM:
		Sfx.play("deny")
		Game.toast.emit("That farm is full of farmers!", "farmer")
		return
	for w in Game.workers:
		if w["role"] == "":
			Game.assign(int(w["id"]), role, target)
			Sfx.play("hire", 0.0, 1.15)
			Kit.bounce(_cards[role]["box"], 0.05)
			preview_role.emit(role)
			return
	Sfx.play("deny")
	Kit.shake(_hire_btn)
	Game.toast.emit("No resting workers — hire one!", "hire")


func _remove(role: String, _target: String) -> void:
	for i in range(Game.workers.size() - 1, -1, -1):
		var w: Dictionary = Game.workers[i]
		if w["role"] == role:
			Game.assign(int(w["id"]), "", "")
			Sfx.play("click")
			return
	Sfx.play("deny")
