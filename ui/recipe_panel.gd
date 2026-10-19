class_name RecipePanel
extends Sheet
## Choose the model a server serves. A model needs enough VRAM (GPUs and HBM
## stacks add it); then the server's accelerators decide how many tokens a
## second it can answer. Auto keeps it on the model that earns most with
## the demand still unserved. Models you don't own yet show how to get
## them: open weights to download, or data to train them on a Training
## Cluster.

var server: ServerB


func _init() -> void:
	title = "Which model to serve"
	title_icon = "recipe"
	height_frac = 0.78


func setup(b: ServerB) -> RecipePanel:
	server = b
	return self


func _build() -> void:
	var tip := Kit.label("This server: %d GB VRAM  ·  %s accelerators. Bigger models need more memory; each answers fewer tokens per GPU but sells for more." % [int(server.vram()), _acc(server.accels())], 16, Kit.MUTED, 0, false)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	body.add_child(tip)
	var a := server.auto_recipe()
	body.add_child(_row("", "Auto", "The model that earns most with the demand left (now %s)" % Defs.model_name(a), true, "recipe"))
	for r in Defs.RECIPES:
		body.add_child(_recipe_row(r))


static func _acc(v: float) -> String:
	return str(int(v)) if is_equal_approx(v, roundf(v)) else "%.1f" % v


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
	top.add_child(Kit.game("$%s/1K" % Fmt.num(Market.token_price(id)), 19, Color(0.16, 0.56, 0.5), 0))
	var fits := float(r["vram"]) <= server.vram()
	var tag := Kit.label("%d GB VRAM  ·  %d ms  ·  %s" % [int(r["vram"]), int(r["lat"]), r["tag"]], 14, Kit.MUTED, 0, false)
	tag.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tag.custom_minimum_size.x = 240
	v.add_child(tag)
	var line := ""
	var col := Kit.MUTED
	if known:
		if fits:
			var c := server.capacity_for(id)
			line = "Here: %s tok/s  ·  wanted %s, served %s" % [Fmt.tokens(c), Fmt.tokens(float(Market.demand.get(id, Market.api_demand(id)))), Fmt.tokens(float(Market.served.get(id, 0.0)))]
			col = Kit.SAGE_EDGE
		else:
			line = "Needs %d GB more VRAM: install GPUs or HBM" % ceili(float(r["vram"]) - server.vram())
			col = Kit.TERRACOTTA_EDGE
	elif int(r["open"]) >= 0:
		line = "Open weights: download the licence" if int(r["open"]) > 0 else "Open weights: free to download"
	else:
		var bits := []
		for t in r["train"]:
			bits.append("%d %s" % [int(r["train"][t]), Defs.item_name(t).to_lower()])
		line = "Train it at a Training Cluster: %s, %s GPU-s" % [", ".join(bits), Fmt.num(float(r["compute"]))]
		col = Kit.TERRACOTTA_EDGE if Game.count_ready("trainer") == 0 else Kit.MUTED
	var w := Kit.label(line, 14, col, 0, false)
	w.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	w.custom_minimum_size.x = 240
	v.add_child(w)
	if Game.trending == id:
		v.add_child(Kit.label("Trending now: twice the customers!", 14, Kit.SAGE_EDGE, 0))
	if known:
		h.add_child(_pick(id, fits))
	elif int(r["open"]) >= 0:
		h.add_child(_download(id, float(r["open"])))
	else:
		var b := Kit.juicy("Train", Kit.GREY, Kit.SAGE_EDGE, 20, Vector2(120, 60))
		b.pressed.connect(func():
			Sfx.play("deny")
			Kit.shake(b))
		h.add_child(b)
	return box


func _download(id: String, cost: float) -> Control:
	var ok := Game.can_afford(cost)
	var b := Kit.juicy("Free" if cost <= 0.0 else "$%s" % Fmt.num(cost), Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE, 20, Vector2(120, 60))
	b.pressed.connect(func():
		if not Game.download(id):
			Sfx.play("deny")
			Kit.shake(b)
			return
		Sfx.play("upgrade", -4.0)
		if float(Defs.recipe(id)["vram"]) <= server.vram():
			server.choose(id)
		close())
	return b


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
