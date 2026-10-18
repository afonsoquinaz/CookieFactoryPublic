class_name RecipePanel
extends Sheet
## Choose the model a server serves. Auto keeps it on the best model your
## sources and labs can feed. Each model shows its size, latency and token
## price, the resources it needs (faded when you don't make them yet) and
## what's still missing: a bigger server (more bays) or the sources and labs
## that make its resources.

var server: ServerB


func _init() -> void:
	title = "Which model to serve"
	title_icon = "recipe"
	height_frac = 0.72


func setup(b: ServerB) -> RecipePanel:
	server = b
	return self


func _build() -> void:
	var tip := Kit.label("This server has %d module bay%s. Every model needs power plus one bay per resource." % [server.slots(), "s" if server.slots() > 1 else ""], 16, Kit.MUTED, 0, false)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	body.add_child(tip)
	body.add_child(_row("", "Auto", "Always the best model you can feed right now (%s)" % Defs.recipe(server.auto_recipe())["name"], true, "recipe"))
	for r in Defs.RECIPES:
		body.add_child(_recipe_row(r))


func _row(id: String, name: String, sub: String, ok: bool, icon: String) -> Control:
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	h.add_child(Kit.icon(icon, 66))
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Kit.game(name, 22, Kit.INK, 0))
	var s := Kit.label(sub, 15, Kit.MUTED, 0, false)
	s.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	s.custom_minimum_size.x = 240
	v.add_child(s)
	h.add_child(_pick(id, ok))
	return box


func _recipe_row(r: Dictionary) -> Control:
	var id: String = r["id"]
	var ings: Array = r["ings"]
	var known: bool = Game.known_recipes.has(id)
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	var ic := Kit.icon("tk_" + id, 66)
	if not known:
		ic.modulate = Color(0.14, 0.18, 0.24, 0.6)
	h.add_child(ic)
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	top.add_child(Kit.game(r["name"], 21, Kit.INK, 0))
	top.add_child(Kit.game("$%s" % Fmt.num(Bal.item_value("t:" + id)), 19, Color(0.16, 0.56, 0.5), 0))
	var snappy := Bal.latency_bonus(id)
	var tag := Kit.label("%s params  ·  %d ms%s  ·  %s" % [r["params"], int(r["lat"]), ("  (+%d%% at cafés)" % roundi(snappy * 100)) if snappy > 0.0 else "", r["tag"]], 14, Kit.MUTED, 0, false)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = 240
	v.add_child(tag)
	var row := Kit.hbox(3)
	v.add_child(row)
	row.add_child(Kit.icon("power", 28))
	for i in ings:
		var ii := Kit.icon(i, 28)
		if not Game.can_make(i):
			ii.modulate = Color(1, 1, 1, 0.35)
		row.add_child(ii)
	var why := ""
	if ings.size() > server.slots():
		why = "Needs %d bays: server level %d" % [ings.size(), Defs.slots_level(ings.size())]
	else:
		var missing := []
		for i in ings:
			if not Game.can_make(i):
				missing.append(Defs.item_name(i).to_lower())
		if not missing.is_empty():
			why = "You don't make %s yet" % ", ".join(missing)
	if why != "":
		var w := Kit.label(why, 14, Kit.TERRACOTTA_EDGE, 0, false)
		w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		w.custom_minimum_size.x = 240
		v.add_child(w)
	if Game.trending == id:
		v.add_child(Kit.label("Trending now: sells for more!", 14, Kit.SAGE_EDGE, 0))
	var ok := ings.size() <= server.slots()
	h.add_child(_pick(id, ok))
	return box


func _pick(id: String, ok: bool) -> Control:
	var cur := server.chosen() == id
	var b := Kit.juicy("Serving" if cur else "Serve", Kit.BRASS if cur else (Kit.SAGE if ok else Kit.GREY), Kit.SAGE_EDGE, 20, Vector2(120, 60))
	b.pressed.connect(func():
		if not ok:
			Sfx.play("deny")
			Kit.shake(b)
			return
		server.choose(id)
		Sfx.play("upgrade", -4.0)
		close())
	return b
