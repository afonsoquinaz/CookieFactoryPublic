class_name SettingsPanel
extends Sheet
## Sound, music, vibration, stats and a guarded "start over".

var _confirm := false


func _init() -> void:
	title = "Settings"
	title_icon = "gear"
	height_frac = 0.55


func _build() -> void:
	body.add_child(_toggle("Music", "music", func(on): Sfx.set_music(on)))
	body.add_child(_toggle("Sound effects", "sfx", func(on): Sfx.set_sfx(on)))
	body.add_child(_toggle("Vibration", "haptics", func(_on): pass))
	var hp := Sheet.row_box()
	var hv := Kit.vbox(6)
	hp.add_child(hv)
	hv.add_child(Kit.game("How to play", 30, Kit.INK, 0))
	for line in [
		["hammer", "Everything is open from the start: build and upgrade whatever you like. Sales raise your Empire level, and every level brings gems."],
		["builder", "Builders build and upgrade over time, even while you're away. Under 30 s left? Tap the timer: it's free."],
		["porter", "Porters carry everything along the roads. Every building's road builds itself to its entrance."],
		["bakery", "A Bakery bakes the recipe you choose (Bake). Upgrades add silos for richer recipes."],
		["gem", "Gems come from orders, obstacles and Empire levels. Spend them on builders or to finish jobs."],
	]:
		var row := Kit.hbox(10)
		row.add_child(Kit.icon(line[0], 44))
		var t := Kit.label(line[1], 16, Kit.MUTED, 0, false)
		t.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		t.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		t.custom_minimum_size.x = 300
		row.add_child(t)
		hv.add_child(row)
	body.add_child(hp)
	var st := Sheet.row_box()
	var v := Kit.vbox(4)
	st.add_child(v)
	v.add_child(Kit.game("Your empire", 30, Kit.INK, 0))
	var s: Dictionary = Game.stats
	for line in ["Cookies sold: %s" % Fmt.num(int(s["cookies"])), "Money earned: $%s" % Fmt.num(int(s["earned"])),
			"Batches baked: %s" % Fmt.num(int(s["batches"])), "Staff: %d  ·  Builders: %d" % [Game.workers.size(), Game.builders()],
			"Empire level %d: %s" % [Game.level, Defs.level_title(Game.level)],
			"Time played: %s" % Fmt.time(float(s["play_time"]))]:
		v.add_child(Kit.label(line, 18, Kit.MUTED, 0, false))
	body.add_child(st)
	var reset := Kit.juicy("Start over", Kit.TERRACOTTA, Kit.TERRACOTTA_EDGE, 22, Vector2(0, 64))
	reset.pressed.connect(func():
		if not _confirm:
			_confirm = true
			reset.set_text_value("Tap again to erase everything")
			Kit.shake(reset)
			return
		Game.wipe()
		Game.loaded = true
		get_tree().reload_current_scene())
	body.add_child(reset)
	var credit := Kit.label("Cookie Empire  ·  made with Godot", 15, Kit.MUTED, 0, false)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(credit)


func _toggle(text: String, key: String, apply: Callable) -> Control:
	var row := Sheet.row_box()
	var h := Kit.hbox(10)
	row.add_child(h)
	var l := Kit.game(text, 25, Kit.INK, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var on: bool = Game.settings.get(key, true)
	var b := Kit.juicy("On" if on else "Off", Kit.GREEN if on else Kit.GREY, Kit.GREEN_EDGE if on else Kit.GREY_EDGE, 19, Vector2(110, 52))
	b.pressed.connect(func():
		var now: bool = not Game.settings.get(key, true)
		Game.settings[key] = now
		apply.call(now)
		b.set_text_value("On" if now else "Off")
		b.set_colors(Kit.GREEN if now else Kit.GREY, Kit.GREEN_EDGE if now else Kit.GREY_EDGE)
		Game.save_game())
	h.add_child(b)
	return row
