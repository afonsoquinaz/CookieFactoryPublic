class_name ShopPanel
extends Sheet
## The sparks shop (see Store): the Starter Pack, spark packs, and the Spark
## Exchange that turns money into sparks a few times a day. Sparks finish
## jobs now, buy perks, Streak Freezes, crate skips and the premium Pass.

var _ex_btn: JuicyButton
var _ex_label: Label


func _init() -> void:
	title = "Sparks"
	title_icon = "gem"
	height_frac = 0.8


func _build() -> void:
	Store.changed.connect(_rebuild)
	Store.purchased.connect(_on_purchased)
	Store.failed.connect(func(_id, why): Game.toast.emit(why, "gem"))
	_fill()


func _rebuild() -> void:
	if not is_inside_tree():
		return
	for c in body.get_children():
		c.queue_free()
	_fill.call_deferred()


func _fill() -> void:
	var top := Kit.hbox(10)
	top.add_child(Kit.icon("gem", 46))
	var tl := Kit.game("You have %d sparks" % Game.gems, 24, Kit.INK, 0)
	tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tl)
	body.add_child(top)
	var why := Kit.label("Sparks finish builds and upgrades now, buy perks, Streak Freezes, crate unlocks and the premium Lab Pass.", 15, Kit.MUTED, 0, false)
	why.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	why.custom_minimum_size.x = 400
	body.add_child(why)
	var reason := Store.unavailable_reason()
	if reason != "":
		var rb := Sheet.row_box()
		var rl := Kit.label(reason, 16, Kit.TERRACOTTA_EDGE, 0, true)
		rl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rl.custom_minimum_size.x = 380
		rb.add_child(rl)
		body.add_child(rb)
	if not Store.starter_bought:
		body.add_child(_starter())
	for p in Store.PACKS:
		body.add_child(_pack_row(p))
	body.add_child(_exchange())


func _starter() -> Control:
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	h.add_child(Kit.icon("crate_lab", 76))
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Kit.game("Starter Pack", 24, Kit.INK, 0))
	var r: Dictionary = Store.STARTER["reward"]
	var l := Kit.label("%d sparks, %d one-hour Time Warps and a Lab Crate. Once only." % [int(r["gems"]), int(r["warp60"])], 15, Kit.MUTED, 0, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 220
	v.add_child(l)
	h.add_child(_buy_btn(Store.STARTER["id"], Kit.BRASS))
	return box


func _pack_row(p: Dictionary) -> Control:
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	var n := int(p["gems"])
	h.add_child(Kit.icon("gem", 44 + mini(30, int(log(float(n)) * 3.0))))
	var v := Kit.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Kit.game("%s sparks" % Fmt.num(n), 22, Kit.INK, 0))
	if str(p["tag"]) != "":
		v.add_child(Kit.label(p["tag"], 14, Kit.SAGE_EDGE, 0))
	h.add_child(_buy_btn(p["id"], Kit.SAGE))
	return box


func _buy_btn(id: String, face: Color) -> JuicyButton:
	var ok := Store.available()
	var b := Kit.juicy(Store.price_text(id), face if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE, 20, Vector2(130, 60))
	b.pressed.connect(func():
		if not Store.buy(id):
			Sfx.play("deny")
			Kit.shake(b))
	return b


func _exchange() -> Control:
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	h.add_child(Kit.icon("coin", 56))
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Kit.game("Spark Exchange", 22, Kit.INK, 0))
	_ex_label = Kit.label("", 14, Kit.MUTED, 0, false)
	_ex_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_ex_label.custom_minimum_size.x = 220
	v.add_child(_ex_label)
	_ex_btn = Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 18, Vector2(130, 60))
	_ex_btn.pressed.connect(func():
		if Store.exchange():
			Sfx.play("cash")
			Kit.bounce(_ex_btn)
			_rebuild()
		else:
			Sfx.play("deny")
			Kit.shake(_ex_btn))
	h.add_child(_ex_btn)
	_update_exchange()
	return box


func _update_exchange() -> void:
	if _ex_label == null:
		return
	var left := Store.exchange_left()
	_ex_label.text = "%d sparks for money. Dearer with every trade; %d left today." % [Store.EXCHANGE_GEMS, left]
	_ex_btn.set_text_value("$" + Fmt.num(Store.exchange_price()) if left > 0 else "Tomorrow")
	var ok := left > 0 and Game.can_afford(Store.exchange_price())
	_ex_btn.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)


func _on_purchased(_id: String, r: Dictionary) -> void:
	Sfx.play("levelup", -4.0)
	Game.toast.emit("Thank you! " + Live.describe(r), "gem")
	_rebuild()
