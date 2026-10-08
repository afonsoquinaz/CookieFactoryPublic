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
	var st := Sheet.row_box()
	var v := Kit.vbox(4)
	st.add_child(v)
	v.add_child(Kit.label("Your empire", 28, Kit.CHOCO, 0))
	var s: Dictionary = Game.stats
	for line in ["Cookies sold: %s" % Fmt.num(int(s["cookies"])), "Money earned: $%s" % Fmt.num(int(s["earned"])),
			"Dough balls baked: %s" % Fmt.num(int(s["batches"])), "Workers: %d" % Game.workers.size(),
			"Time played: %s" % Fmt.time(float(s["play_time"]))]:
		v.add_child(Kit.label(line, 22, Color(0.5, 0.36, 0.28), 0, false))
	body.add_child(st)
	var reset := Kit.juicy("Start over", Kit.CORAL, Kit.CORAL_EDGE, 26, Vector2(0, 70))
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
	var credit := Kit.label("Cookie Factory · made with Godot", 18, Color(0.6, 0.48, 0.4), 0, false)
	credit.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(credit)


func _toggle(text: String, key: String, apply: Callable) -> Control:
	var row := Sheet.row_box()
	var h := Kit.hbox(10)
	row.add_child(h)
	var l := Kit.label(text, 28, Kit.CHOCO, 0)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	h.add_child(l)
	var on: bool = Game.settings.get(key, true)
	var b := Kit.juicy("ON" if on else "OFF", Kit.GREEN if on else Kit.GREY, Kit.GREEN_EDGE if on else Kit.GREY_EDGE, 26, Vector2(130, 64))
	b.pressed.connect(func():
		var now: bool = not Game.settings.get(key, true)
		Game.settings[key] = now
		apply.call(now)
		b.set_text_value("ON" if now else "OFF")
		b.set_colors(Kit.GREEN if now else Kit.GREY, Kit.GREEN_EDGE if now else Kit.GREY_EDGE)
		Game.save_game())
	h.add_child(b)
	return row
