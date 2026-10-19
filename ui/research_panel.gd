class_name ResearchPanel
extends Sheet
## Empire-wide improvements: Research (paid with money), Perks (paid with
## sparks from contracts) and the Model Book (every model, what it
## needs, and which you've baked).

static var last_tab := "research"
var _tabs := {}
var _rows := []


func _init() -> void:
	title = "Research"
	title_icon = "research"
	height_frac = 0.7


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(6)
	v.add_child(h)
	for t in [["research", "Research"], ["perks", "Perks"], ["recipes", "Models"]]:
		var b := Kit.juicy(t[1], Kit.PAPER_DARK, Kit.LINE, 19, Vector2(0, 58))
		b.sound = "click"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func(): _select(t[0]))
		h.add_child(b)
		_tabs[t[0]] = b
	Game.money_changed.connect(func(_a, _b): _refresh())
	Game.gems_changed.connect(func(_g): _refresh())


func _build() -> void:
	_select(last_tab)


func _select(tab: String) -> void:
	last_tab = tab
	for k in _tabs:
		_tabs[k].set_colors(Kit.BRASS if k == tab else Kit.PAPER_DARK, Kit.BRASS_EDGE if k == tab else Kit.LINE)
	for c in body.get_children():
		c.queue_free()
	_rows.clear()
	match tab:
		"research":
			for id in Bal.RESEARCH_ORDER:
				body.add_child(_row(id, false))
		"perks":
			var g := Kit.hbox(8)
			g.add_child(Kit.icon("gem", 40))
			g.add_child(Kit.game("%d sparks  ·  from contracts, obstacles and Lab levels" % Game.gems, 18, Kit.INK, 0))
			body.add_child(g)
			for id in Bal.PERK_ORDER:
				body.add_child(_row(id, true))
		"recipes":
			_recipes()
	_refresh()
	scroll.scroll_vertical = 0


func _row(id: String, perk: bool) -> Control:
	var d: Dictionary = Bal.PERKS[id] if perk else Bal.RESEARCH[id]
	var box := Sheet.row_box()
	var h := Kit.hbox(12)
	box.add_child(h)
	h.add_child(Kit.icon(d["icon"], 64))
	var v := Kit.vbox(0)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	top.add_child(Kit.game(d["name"], 23, Kit.INK, 0))
	var lv := Kit.label("", 16, Kit.MUTED, 0, false)
	top.add_child(lv)
	var desc := Kit.label(d["desc"], 16, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 260
	v.add_child(desc)
	var btn := Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 20, Vector2(150, 62))
	btn.set_icon("gem" if perk else "coin", 28)
	btn.sound = ""
	btn.pressed.connect(func():
		var ok := Game.buy_perk(id) if perk else Game.buy_research(id)
		if ok:
			Sfx.play("upgrade")
			Kit.bounce(box, 0.05)
		else:
			Sfx.play("deny")
			Kit.shake(btn)
		_refresh())
	h.add_child(btn)
	_rows.append([id, perk, btn, lv])
	return box


func _refresh() -> void:
	for r in _rows:
		var id: String = r[0]
		var perk: bool = r[1]
		var btn: JuicyButton = r[2]
		var lv: Label = r[3]
		var d: Dictionary = Bal.PERKS[id] if perk else Bal.RESEARCH[id]
		var l := Game.perk(id) if perk else Game.research(id)
		lv.text = "Lv %d / %d" % [l, int(d["max"])]
		if l >= int(d["max"]):
			btn.set_text_value("MAX")
			btn.set_colors(Kit.PAPER_DARK, Kit.LINE)
			continue
		var cost := float(Bal.perk_cost(id, l)) if perk else Game.research_cost(id)
		btn.set_text_value(Fmt.num(cost))
		var ok := Game.gems >= cost if perk else Game.can_afford(cost)
		btn.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)


func _recipes() -> void:
	var tip := Kit.label("Download open-weight models, or train your own on a Training Cluster from the data your labs make. A server loads any model that fits its VRAM.", 16, Kit.MUTED, 0, false)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	body.add_child(tip)
	for r in Defs.RECIPES:
		var known: bool = Game.known_recipes.has(r["id"])
		var box := Sheet.row_box()
		var h := Kit.hbox(10)
		box.add_child(h)
		var ic := Kit.icon("tk_" + r["id"], 66)
		if not known:
			ic.modulate = Color(0.14, 0.18, 0.24, 0.55)
		h.add_child(ic)
		var v := Kit.vbox(2)
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(v)
		var top := Kit.hbox(8)
		v.add_child(top)
		top.add_child(Kit.game(r["name"], 22, Kit.INK if known else Kit.MUTED, 0))
		top.add_child(Kit.game("$%s/1K" % Fmt.num(Bal.token_price(r["id"])), 20, Color(0.16, 0.56, 0.5), 0))
		v.add_child(Kit.label("%s params  ·  %d GB VRAM  ·  %s tok/s per GPU%s" % [r["params"], int(r["vram"]), Fmt.tokens(float(r["tps"])), "  ·  agents" if r["agent"] else ""], 14, Kit.MUTED, 0, false))
		if not known:
			var ings := Kit.hbox(4)
			v.add_child(ings)
			if int(r["open"]) >= 0:
				ings.add_child(Kit.label("Open weights: $%s in a server's Model list" % Fmt.num(float(r["open"])), 14, Kit.SAGE_EDGE, 0, false))
			else:
				for i in r["train"]:
					var ii := Kit.icon(i, 30)
					if not Game.can_make(i):
						ii.modulate = Color(1, 1, 1, 0.4)
					ings.add_child(ii)
					ings.add_child(Kit.label("%d" % int(r["train"][i]), 14, Kit.MUTED, 0))
		else:
			v.add_child(Kit.label("Quality %d%%  ·  served %s tok/s of %s wanted" % [roundi(Market.quality_of(r["id"]) * 100), Fmt.tokens(float(Market.served.get(r["id"], 0.0))), Fmt.tokens(float(Market.demand.get(r["id"], 0.0)))], 14, Kit.SAGE_EDGE, 0, false))
		if Game.trending == r["id"]:
			v.add_child(Kit.label("Trending now: twice the customers!", 14, Kit.SAGE_EDGE, 0))
		body.add_child(box)
