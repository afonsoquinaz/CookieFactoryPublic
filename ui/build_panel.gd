class_name BuildPanel
extends Sheet
## The build menu: everything you can place, by tab. Everything is
## available from the start; each card shows the price, how long a builder
## needs, how many you have, and what a kitchen needs to be useful.

signal chosen(kind: String)

static var last_tab := "farm"
var _tabs := {}
var _grid: GridContainer


func _init() -> void:
	title = "Build"
	title_icon = "hammer"
	height_frac = 0.72


func _header(v: VBoxContainer) -> void:
	var h := Kit.hbox(4)
	v.add_child(h)
	for c in Defs.TABS:
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
	var tip := Kit.label("Builders free: %d / %d  ·  Every building gets a road to its entrance by itself." % [Game.free_builders(), Game.builders()], 16, Kit.MUTED, 0, false)
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


func _select(tab: String) -> void:
	last_tab = tab
	for k in _tabs:
		_tabs[k].set_colors(Kit.BRASS if k == tab else Kit.PAPER_DARK, Kit.BRASS_EDGE if k == tab else Kit.LINE)
	for c in _grid.get_children():
		c.queue_free()
	_queue.clear()
	for kind in Defs.BUILD_ORDER:
		if Defs.BUILDINGS[kind]["tab"] == tab:
			later(_grid, _card.bind(kind))
	flush(4.0)
	scroll.scroll_vertical = 0


func _card(kind: String) -> Control:
	var d: Dictionary = Defs.BUILDINGS[kind]
	var box := Sheet.row_box()
	box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var mx := Defs.limit_of(kind)
	var own := Game.count_of(kind)
	var full := mx >= 0 and own >= mx
	var v := Kit.vbox(4)
	box.add_child(v)
	var top := Kit.hbox(8)
	v.add_child(top)
	top.add_child(Kit.icon(d["icon"], 64))
	var tv := Kit.vbox(0)
	tv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(tv)
	var name_l := Kit.game(d["name"], 20, Kit.INK, 0)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_l.custom_minimum_size.x = 150
	tv.add_child(name_l)
	var sz: Vector2i = d["size"]
	var sub := "%dx%d" % [sz.x, sz.y]
	if mx > 1:
		sub += "  ·  built %d / %d" % [own, mx]
	elif own > 0:
		sub += "  ·  have %d" % own
	tv.add_child(Kit.label(sub, 14, Kit.MUTED, 0, false))
	var t := Game.build_time_of(kind)
	if t > 0.0 and not full:
		tv.add_child(Kit.label("Build time %s" % Fmt.time(t), 14, Kit.MUTED, 0, false))
	# a kitchen is only useful once something makes what it needs
	var missing := []
	for i in d.get("in", {}):
		if not Game.can_make(i):
			missing.append(Defs.item_name(i).to_lower())
	if not missing.is_empty():
		var ml := Kit.label("Needs %s" % " and ".join(missing), 14, Kit.TERRACOTTA_EDGE, 0, false)
		ml.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		ml.custom_minimum_size.x = 150
		tv.add_child(ml)
	var desc := Kit.label(d["desc"], 14, Kit.MUTED, 0, false)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size.x = 260
	v.add_child(desc)
	var gp := Game.gem_price_of(kind)
	var price := Game.price_of(kind)
	var b := Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 20, Vector2(0, 56))
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.sound = ""
	if full:
		b.set_glyph("check", 22)
		b.set_text_value("All built" if mx > 1 else "Built")
		b.set_colors(Kit.PAPER_DARK, Kit.LINE)
	else:
		b.set_icon("gem" if gp > 0 else "coin", 26)
		b.set_text_value(str(gp) if gp > 0 else ("Free" if price <= 0.0 else Fmt.num(price)))
		var ok := Game.build_block(kind) == ""
		b.set_colors(Kit.SAGE if ok else Kit.GREY, Kit.SAGE_EDGE if ok else Kit.GREY_EDGE)
	b.pressed.connect(func():
		var why := Game.build_block(kind)
		if why != "":
			Sfx.play("deny")
			Kit.shake(b)
			Game.toast.emit(why, "hammer" if why.contains("builder") else d["icon"])
			return
		Sfx.play("click")
		chosen.emit(kind)
		close())
	v.add_child(b)
	return box
