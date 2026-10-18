extends Node
func _ready():
	await get_tree().create_timer(1.0).timeout
	var hud = get_tree().current_scene.get("ui")
	for i in 3:
		for tab in ["source", "server", "town"]:
			BuildPanel.last_tab = tab
			var t0 := Time.get_ticks_usec()
			var p := BuildPanel.new()
			hud.add_child(p)
			var t1 := Time.get_ticks_usec()
			print("PB build %s %.1f ms" % [tab, (t1 - t0) / 1000.0])
			p.queue_free()
			await get_tree().process_frame
	var t2 := Time.get_ticks_usec()
	for i in 200:
		Kit.skin("card", 30, Vector4(16, 12, 16, 18))
	print("PB 200 skins %.1f ms" % ((Time.get_ticks_usec() - t2) / 1000.0))
	t2 = Time.get_ticks_usec()
	for i in 200:
		Kit.icon("power", 64).free()
	print("PB 200 icons %.1f ms" % ((Time.get_ticks_usec() - t2) / 1000.0))
	t2 = Time.get_ticks_usec()
	for i in 100:
		Kit.game("Hello", 20, Kit.INK, 0).free()
	print("PB 100 game labels %.1f ms" % ((Time.get_ticks_usec() - t2) / 1000.0))
	t2 = Time.get_ticks_usec()
	for i in 50:
		Kit.juicy("", Kit.SAGE, Kit.SAGE_EDGE, 20, Vector2(0, 56)).free()
	print("PB 50 juicy %.1f ms" % ((Time.get_ticks_usec() - t2) / 1000.0))
	get_tree().quit()
