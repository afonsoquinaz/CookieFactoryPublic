class_name RecipePanel
extends Sheet
## Choose what a Bakery bakes. Auto keeps it on the best recipe your farms
## and kitchens can supply. Each recipe shows its price, the ingredients it
## needs (faded when you don't make them yet) and what's still missing: a
## bigger bakery (more silos) or a higher Cookie Hall.

var bakery: BakeryB


func _init() -> void:
	title = "What to bake"
	title_icon = "recipe"
	height_frac = 0.72


func setup(b: BakeryB) -> RecipePanel:
	bakery = b
	return self


func _build() -> void:
	var tip := Kit.label("This bakery has %d silo%s. Every recipe needs wheat plus one silo per ingredient." % [bakery.slots(), "s" if bakery.slots() > 1 else ""], 16, Kit.MUTED, 0, false)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	body.add_child(tip)
	body.add_child(_row("", "Auto", "Always the best recipe you can make right now (%s)" % Defs.recipe(bakery.auto_recipe())["name"], true, "recipe"))
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
	var ic := Kit.icon("ck_" + id, 66)
	if not known:
		ic.modulate = Color(0.25, 0.18, 0.14, 0.6)
	h.add_child(ic)
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	top.add_child(Kit.game(r["name"], 21, Kit.INK, 0))
	top.add_child(Kit.game("$%s" % Fmt.num(Bal.item_value("c:" + id)), 19, Color(0.3, 0.52, 0.22), 0))
	var row := Kit.hbox(3)
	v.add_child(row)
	row.add_child(Kit.icon("wheat", 28))
	for i in ings:
		var ii := Kit.icon(i, 28)
		if not Game.can_make(i):
			ii.modulate = Color(1, 1, 1, 0.35)
		row.add_child(ii)
	var why := ""
	var hall := Defs.recipe_level(id)
	if hall > Game.level:
		why = "Ingredients unlock at Cookie Hall %d" % hall
	elif ings.size() > bakery.slots():
		why = "Needs %d silos: Bakery level %d" % [ings.size(), Defs.slots_level(ings.size())]
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
	var ok := hall <= Game.level and ings.size() <= bakery.slots()
	h.add_child(_pick(id, ok))
	return box


func _pick(id: String, ok: bool) -> Control:
	var cur := bakery.chosen() == id
	var b := Kit.juicy("Baking" if cur else "Bake", Kit.BRASS if cur else (Kit.SAGE if ok else Kit.GREY), Kit.SAGE_EDGE, 20, Vector2(120, 60))
	b.pressed.connect(func():
		if not ok:
			Sfx.play("deny")
			Kit.shake(b)
			return
		bakery.choose(id)
		Sfx.play("upgrade", -4.0)
		close())
	return b
