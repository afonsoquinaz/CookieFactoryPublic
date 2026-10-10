class_name BuildPanel
extends Sheet
## The build menu: everything you can place, by category. Tap a card to pick
## a spot for it. Locked cards say which empire level opens them.

signal chosen(kind: String, ing: String)

static var last_tab := "farm"
var _tabs := {}
var _grid: GridContainer


func _init() -> void:
	title = "Build"
	title_icon = "hammer"
	height_frac = 0.7


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(4)
	v.add_child(h)
	for c in Defs.CATS:
		var b := Kit.juicy("", Kit.PAPER_DARK, Kit.LINE, 14, Vector2(0, 74))
		b.sound = "click"
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.row.queue_free()
		var vv := Kit.vbox(-6)
		vv.alignment = BoxContainer.ALIGNMENT_CENTER
		vv.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		vv.offset_bottom = -8
		b.add_child(vv)
		var ic := Kit.icon(c[2], 42)
		ic.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		vv.add_child(ic)
		var l := Kit.game(c[1], 15, Kit.INK, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vv.add_child(l)
		b.row = Kit.hbox()
		b.pressed.connect(func(): _select(c[0]))
		h.add_child(b)
		_tabs[c[0]] = b
	var tip := Kit.label("Your land ends at the dashed line. Tap a For Sale sign there to buy more ($%s)." % Fmt.num(Game.land_price()), 16, Kit.MUTED, 0, false)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	v.add_child(tip)


func _build() -> void:
	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.add_theme_constant_override("h_separation", 10)
	_grid.add_theme_constant_override("v_separation", 10)
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(_grid)
	_select(last_tab)


func _select(cat: String) -> void:
	last_tab = cat
	for k in _tabs:
		_tabs[k].set_colors(Kit.BRASS if k == cat else Kit.PAPER_DARK, Kit.BRASS_EDGE if k == cat else Kit.LINE)
	for c in _grid.get_children():
		c.queue_free()
	for kind in Defs.BUILD_ORDER:
		if Defs.BUILDINGS[kind]["cat"] != cat and not (cat == "decor" and kind == "palace"):
			continue
		if kind == "hopper":
			for ing in _hopper_ings():
				_grid.add_child(_card(kind, ing))
		else:
			_grid.add_child(_card(kind, ""))
	scroll.scroll_vertical = 0


## Ingredients you could put in a hopper (anything but wheat, which goes in the Mixer).
static func _hopper_ings() -> Array[String]:
	var out: Array[String] = []
	for t in Defs.RAW + Defs.PROCESSED:
		if t == "wheat":
			continue
		out.append(t)
	out.sort_custom(func(a, b): return Defs.ingredient_level(a) < Defs.ingredient_level(b))
	return out


func _card(kind: String, ing: String) -> Control:
	var d: Dictionary = Defs.BUILDINGS[kind]
	var box := Sheet.row_box()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var lvl := int(d["lvl"]) if ing == "" else maxi(int(d["lvl"]), Defs.ingredient_level(ing))
	var locked := Game.level < lvl
	var maxed := kind == "board" and Game.count_of("board") > 0
	if kind == "palace" and Game.count_of("palace") > 0:
		maxed = true
	var v := Kit.vbox(4)
	box.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	var ic := Kit.icon(ing if ing != "" else d["icon"], 64)
	top.add_child(ic)
	var tv := Kit.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	var nm: String = d["name"] if ing == "" else "%s Hopper" % Defs.item_name(ing)
	var name_l := Kit.game(nm, 21, Kit.INK, 0)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size.x = 150
	tv.add_child(name_l)
	var sz: Vector2i = d["size"]
	var own := Game.count_of(kind)
	var sub := "%dx%d" % [sz.x, sz.y]
	if own > 0:
		sub += "  ·  have %d" % own
	tv.add_child(Kit.label(sub, 14, Kit.MUTED, 0, false))
	var desc_txt: String = d["desc"]
	if ing != "":
		desc_txt = "Adds %s to each dough ball." % Defs.item_name(ing).to_lower()
		if not Game.can_make(ing):
			desc_txt += " You don't make %s yet." % Defs.item_name(ing).to_lower()
	var desc := Kit.label(desc_txt, 14, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 260
	v.add_child(desc)
	var price := Game.price_of(kind)
	var b := Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 20, Vector2(0, 56))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.sound = ""
	if maxed:
		b.set_text_value("Built")
		b.set_colors(Kit.PAPER_DARK, Kit.LINE)
	elif locked:
		b.set_glyph("lock", 22)
		b.set_text_value("Level %d" % lvl)
		b.set_colors(Kit.GREY, Kit.GREY_EDGE)
		box.modulate = Color(1, 1, 1, 0.7)
	else:
		b.set_icon("coin", 26)
		b.set_text_value(Fmt.num(price))
		var ok := Game.can_afford(price)
		b.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)
	b.pressed.connect(func():
		if locked or maxed:
			Sfx.play("deny")
			Kit.shake(b)
			return
		if not Game.can_afford(price):
			Sfx.play("deny")
			Kit.shake(b)
			Game.toast.emit("Not enough money yet", "coin")
			return
		Sfx.play("click")
		chosen.emit(kind, ing)
		close())
	v.add_child(b)
	return box
