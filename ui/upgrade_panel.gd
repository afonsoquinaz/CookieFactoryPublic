class_name UpgradePanel
extends Sheet
## The upgrade shop: tabs per group, one row per upgrade showing what the
## next level changes ("Carry 9 → 12") and a price button.

var _tab := "farms"
var _tabs := {}
var _rows := []        # [id, button, level label, effect label]


func _init() -> void:
	title = "Upgrades"
	title_icon = "star"
	height_frac = 0.66


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(6)
	v.add_child(h)
	for g in Bal.UPGRADE_GROUPS:
		var b := Kit.juicy(g[1], Kit.PAPER_DARK, Kit.LINE, 17, Vector2(0, 46))
		b.sound = "click"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _select(g[0]))
		h.add_child(b)
		_tabs[g[0]] = b
	Game.money_changed.connect(_on_money)


func _on_money(_m: int, _d: int) -> void:
	_refresh()


func _build() -> void:
	_select(_tab)


func _select(tab: String) -> void:
	_tab = tab
	for k in _tabs:
		_tabs[k].set_colors(Kit.CHARCOAL if k == tab else Kit.PAPER_DARK, Kit.CHARCOAL_EDGE if k == tab else Kit.LINE)
	for c in body.get_children():
		c.queue_free()
	_rows.clear()
	for id in Bal.all_upgrade_ids():
		if Bal.upgrade_def(id)["group"] != tab:
			continue
		body.add_child(_row(id))
	_refresh()
	scroll.scroll_vertical = 0


func _row(id: String) -> Control:
	var d := Bal.upgrade_def(id)
	var box := Sheet.row_box()
	var h := Kit.hbox(14)
	box.add_child(h)
	var ic := Kit.icon(d["icon"], 72)
	h.add_child(ic)
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := Kit.hbox(10)
	v.add_child(top)
	top.add_child(Kit.label(d["name"], 23, Kit.INK, 0))
	var lv := Kit.label("", 17, Kit.MUTED, 0, false)
	top.add_child(lv)
	var desc := Kit.label(d["desc"], 17, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 300
	v.add_child(desc)
	var eff := Kit.label("", 18, Kit.SAGE_EDGE, 0)
	v.add_child(eff)
	var btn := Kit.juicy("", Kit.GREEN, Kit.GREEN_EDGE, 21, Vector2(150, 64))
	btn.set_icon("coin", 28)
	btn.sound = ""
	btn.pressed.connect(func(): _buy(id, btn, box))
	h.add_child(btn)
	_rows.append([id, btn, lv, eff, box])
	return box


func _refresh() -> void:
	for r in _rows:
		var id: String = r[0]
		var btn: JuicyButton = r[1]
		var lv: Label = r[2]
		var eff: Label = r[3]
		var box: Control = r[4]
		var lvl := Game.lvl(id)
		lv.text = "Lv %d" % lvl
		var maxed := Game.upgrade_maxed(id)
		var avail := Game.upgrade_available(id)
		box.modulate = Color(1, 1, 1, 1) if avail else Color(1, 1, 1, 0.55)
		if not avail:
			btn.set_text_value("Locked")
			btn.set_colors(Kit.GREY, Kit.GREY_EDGE)
			eff.text = "Build the %s first" % Defs.BUILDINGS[Bal.upgrade_def(id)["needs"]]["name"]
			continue
		if maxed:
			btn.set_text_value("MAX")
			btn.set_colors(Kit.PAPER_DARK, Kit.LINE)
			eff.text = effect_text(id, lvl, true)
			continue
		var cost := Game.upgrade_cost(id)
		btn.set_text_value(Fmt.num(cost))
		var ok := Game.can_afford(cost)
		btn.set_colors(Kit.GREEN if ok else Kit.GREY, Kit.GREEN_EDGE if ok else Kit.GREY_EDGE)
		eff.text = effect_text(id, lvl)


func _buy(id: String, btn: JuicyButton, box: Control) -> void:
	if Game.upgrade_maxed(id) or not Game.upgrade_available(id):
		Sfx.play("deny")
		Kit.shake(btn)
		return
	if Game.buy_upgrade(id):
		Sfx.play("upgrade")
		Kit.bounce(box, 0.06)
		Kit.bounce(btn, 0.15)
		_refresh()
	else:
		Sfx.play("deny")
		Kit.shake(btn)


static func effect_text(id: String, l: int, maxed := false) -> String:
	var n := l + 1
	var fmt2 := func(a, b, f: String) -> String:
		return (f % a) if maxed else (f % a) + "  →  " + (f % b)
	if id.begins_with("farm_"):
		var t: String = fmt2.call(Bal.farm_work_time(l), Bal.farm_work_time(n), "%.1fs")
		var c: String = fmt2.call(Bal.farm_crate_cap(l), Bal.farm_crate_cap(n), "%d")
		var extra := ""
		if not maxed and Bal.farm_yield(n) > Bal.farm_yield(l):
			extra = "  · ×%d harvest!" % Bal.farm_yield(n)
		elif not maxed and Bal.farm_tier(n) > Bal.farm_tier(l):
			extra = "  · Farm grows!"
		return "Work " + t + "   Crate " + c + extra
	match id:
		"carry": return "Carry " + fmt2.call(Bal.carry(l), Bal.carry(n), "%d")
		"speed": return "Speed " + fmt2.call(Bal.player_speed(l), Bal.player_speed(n), "%.1f")
		"belt": return "Belt " + fmt2.call(Bal.dough_speed(l), Bal.dough_speed(n), "%.1f m/s")
		"oven": return "Bake " + fmt2.call(Bal.bake_time(l), Bal.bake_time(n), "%.1fs")
		"batch": return "Cookies " + fmt2.call(Bal.batch_size(l), Bal.batch_size(n), "%d") + " per dough"
		"hopper": return "Holds " + fmt2.call(Bal.hopper_cap(l), Bal.hopper_cap(n), "%d")
		"recipe": return "Price " + fmt2.call(Bal.cookie_price(l, Game.cookie_grade()), Bal.cookie_price(n, Game.cookie_grade()), "$%d")
		"pantry": return "Each bin " + fmt2.call(Bal.pantry_cap(l), Bal.pantry_cap(n), "%d")
		"shelf": return "Holds " + fmt2.call(Bal.shelf_cap(l), Bal.shelf_cap(n), "%d")
		"truck": return "Trucks " + fmt2.call(Bal.truck_cap(l), Bal.truck_cap(n), "%d")
		"route": return "Trip " + fmt2.call(Bal.truck_trip(l), Bal.truck_trip(n), "%.0fs")
		"cabin": return "Staff " + fmt2.call(Bal.cabin_cap(l), Bal.cabin_cap(n), "%d")
		"wspeed": return "Speed " + fmt2.call(Bal.worker_speed(l), Bal.worker_speed(n), "%.1f")
		"wcarry": return "Carry " + fmt2.call(Bal.worker_carry(l), Bal.worker_carry(n), "%d")
	return ""
