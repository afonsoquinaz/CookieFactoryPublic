extends Node
func _ready():
	await get_tree().create_timer(1.0).timeout
	var w: World = get_tree().current_scene.get("world")
	var t0 := Time.get_ticks_usec()
	w.rebuild_roads()
	print("BENCH rebuild_roads %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	var b: Building = w.buildings_of("bakery")[0]
	for dx in [0, 1, 2, 3]:
		t0 = Time.get_ticks_usec()
		var s := w.check_spot("bakery", b.cell() + Vector2i(dx, 0), b.rot(), b.uid)
		var t1 := Time.get_ticks_usec()
		var r := w.preview_road("bakery", b.cell() + Vector2i(dx, 0), b.rot(), b.uid)
		var t2 := Time.get_ticks_usec()
		print("BENCH check_spot %.1f ms (%s)  preview_road %.1f ms" % [(t1 - t0) / 1000.0, s["reason"], (t2 - t1) / 1000.0])
	t0 = Time.get_ticks_usec()
	var sp = Placement.free_spot(w, "farm_wheat", Vector2i(0, 0), 0)
	print("BENCH free_spot %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	for i in 3:
		t0 = Time.get_ticks_usec()
		w.terrain._rebuild_decor()
		var t1 := Time.get_ticks_usec()
		w.terrain._rebuild_signs()
		print("BENCH decor %.1f ms  signs %.1f ms" % [(t1 - t0) / 1000.0, (Time.get_ticks_usec() - t1) / 1000.0])
	t0 = Time.get_ticks_usec()
	w.terrain.refresh_prices()
	print("BENCH prices %.1f ms" % ((Time.get_ticks_usec() - t0) / 1000.0))
	get_tree().quit()
