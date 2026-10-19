class_name TrainPanel
extends Sheet
## What a Training Cluster trains. Every model you don't own lists the data
## it needs (couriers bring it from your labs and sources) and the compute
## it takes (the cluster's GPUs); models you own can be refreshed, which
## brings their quality back up as rivals ship better ones. Auto trains the
## next model whose data you make, and refreshes the stalest when there's
## nothing new.

var trainer: TrainerB


func _init() -> void:
	title = "Training"
	title_icon = "trainer"
	height_frac = 0.78


func setup(t: TrainerB) -> TrainPanel:
	trainer = t
	return self


func _build() -> void:
	var tip := Kit.label("This cluster does %s GPU-seconds a second. Bigger models need more data and far more compute." % Fmt.num(trainer.accels()), 16, Kit.MUTED, 0, false)
	tip.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tip.custom_minimum_size.x = 400
	body.add_child(tip)
	var auto := Sheet.row_box()
	var ah := Kit.hbox(10)
	auto.add_child(ah)
	ah.add_child(Kit.icon("recipe", 56))
	var av := Kit.vbox(2)
	av.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ah.add_child(av)
	av.add_child(Kit.game("Auto", 22, Kit.INK, 0))
	av.add_child(Kit.label("Train the next model whose data you make; refresh the stalest when there's nothing new.", 14, Kit.MUTED, 0, false))
	var ab := Kit.juicy("On" if trainer.auto() else "Off", Kit.BRASS if trainer.auto() else Kit.GREY, Kit.SAGE_EDGE, 20, Vector2(110, 60))
	ab.pressed.connect(func():
		trainer.set_auto(not trainer.auto())
		Sfx.play("upgrade", -6.0)
		close())
	ah.add_child(ab)
	body.add_child(auto)
	for r in Defs.RECIPES:
		var rid: String = r["id"]
		var known := Game.known_recipes.has(rid)
		if not known and int(r["open"]) >= 0:
			continue
		later(body, _row.bind(r, known))


func _row(r: Dictionary, known: bool) -> Control:
	var rid: String = r["id"]
	var box := Sheet.row_box()
	var h := Kit.hbox(10)
	box.add_child(h)
	var ic := Kit.icon("tk_" + rid, 60)
	if not known:
		ic.modulate = Color(0.5, 0.56, 0.66, 0.85)
	h.add_child(ic)
	var v := Kit.vbox(2)
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(v)
	v.add_child(Kit.game(("Refresh " if known else "") + r["name"], 20, Kit.INK, 0))
	var needs := TrainerB.needs_for(rid, known)
	var row := Kit.hbox(4)
	v.add_child(row)
	var all_ok := true
	for k in needs:
		var ii := Kit.icon(k, 28)
		if not Game.can_make(k):
			ii.modulate = Color(1, 1, 1, 0.35)
			all_ok = false
		row.add_child(ii)
		row.add_child(Kit.label("%d" % int(needs[k]), 14, Kit.MUTED, 0))
	var secs := TrainerB.compute_for(rid, known) / maxf(0.1, trainer.accels())
	var sub := "%s GPU-s  ·  about %s here" % [Fmt.num(TrainerB.compute_for(rid, known)), Fmt.time(secs)]
	if known:
		sub += "  ·  quality %d%%" % roundi(Market.quality_of(rid) * 100)
	elif not all_ok:
		var miss := []
		for k in needs:
			if not Game.can_make(k):
				miss.append(Defs.item_name(k).to_lower())
		sub += "\nYou don't make %s yet" % ", ".join(miss)
	var l := Kit.label(sub, 14, Kit.TERRACOTTA_EDGE if not all_ok else Kit.MUTED, 0, false)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.custom_minimum_size.x = 220
	v.add_child(l)
	var cur := trainer.job() == rid and trainer.refreshing() == known
	if cur:
		v.add_child(Kit.label("Training: %d%%" % roundi(trainer.progress() / maxf(1.0, trainer.job_compute()) * 100), 14, Kit.SAGE_EDGE, 0))
	var b := Kit.juicy("Training" if cur else ("Refresh" if known else "Train"), Kit.BRASS if cur else Kit.SAGE, Kit.SAGE_EDGE, 20, Vector2(120, 60))
	b.pressed.connect(func():
		if cur:
			return
		trainer.data["auto"] = false
		trainer.start(rid, known)
		Sfx.play("upgrade", -4.0)
		close())
	h.add_child(b)
	return box
