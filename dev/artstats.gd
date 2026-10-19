extends Node
## Triangle count of every building's look per tier (art budget check).
##   godot --headless --path . res://dev/artstats.tscn [-- --kinds=server,fab]
func _ready() -> void:

	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--kinds="):
			only = a.substr(8)
	for kind in Defs.BUILD_ORDER:
		if only != "" and not only.split(",").has(kind):
			continue
		if Defs.BUILDINGS[kind]["cat"] == "decor":
			continue
		var line := "%-14s" % kind
		for t in 5:
			var m := Previews.mesh(kind, "", t)
			var tris := 0
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				var idx = arr[Mesh.ARRAY_INDEX]
				tris += (idx.size() / 3) if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX].size() / 3)
			var mx := Bal.max_level(kind)
			var g := Growth.mesh(kind, mx, t) if mx > 1 else null
			var gt := 0
			if g:
				for s in g.get_surface_count():
					var arr2 := g.surface_get_arrays(s)
					var idx2 = arr2[Mesh.ARRAY_INDEX]
					gt += (idx2.size() / 3) if idx2 != null and idx2.size() > 0 else 0
			line += "  t%d %6d (+%5d)" % [t, tris, gt]
		print(line)
	get_tree().quit()
