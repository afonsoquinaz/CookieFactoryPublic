extends Node
## Height maps of building meshes, seen from above, for placing roof parts.
##   godot --headless --path . res://dev/tops.tscn -- --map=cafe:2   # ASCII height map (0.25 m)
##   godot --headless --path . res://dev/tops.tscn -- --write        # regenerate world/growth_tops.gd


func _ready() -> void:
	var a := {}
	for s in OS.get_cmdline_user_args():
		var kv: PackedStringArray = s.trim_prefix("--").split("=", true, 1)
		a[kv[0]] = kv[1] if kv.size() > 1 else ""
	if a.has("map"):
		var p: PackedStringArray = str(a["map"]).split(":")
		_map(p[0], int(p[1]) if p.size() > 1 else 0, float(a.get("res", "0.25")))
	if a.has("write"):
		Growth.write_tops()
	get_tree().quit()


func _map(kind: String, t: int, res: float) -> void:
	var tris := Growth.triangles(Previews.mesh(kind, "", t))
	var sz: Vector2i = Defs.BUILDINGS[kind]["size"]
	var w := sz.x * Grid.CELL
	var d := sz.y * Grid.CELL
	print("%s tier %d  (%d tris)  x %.1f..%.1f across, z %.1f (top) .. %.1f (bottom), heights in dm" % [kind, t, tris.size() / 3, -w * 0.5, w * 0.5, -d * 0.5, d * 0.5])
	var nx := int(w / res)
	var nz := int(d / res)
	var pts: Array[Vector2] = []
	for j in nz:
		for i in nx:
			pts.append(Vector2(-w * 0.5 + (i + 0.5) * res, -d * 0.5 + (j + 0.5) * res))
	var hs := Growth.heights(tris, pts)
	var head := "      "
	for i in nx:
		head += ("%-3s" % str(snappedf(-w * 0.5 + (i + 0.5) * res, 0.1))) if i % 4 == 0 else "   "
	print(head)
	for j in nz:
		var line := "%5.2f " % (-d * 0.5 + (j + 0.5) * res)
		for i in nx:
			var h: float = hs[j * nx + i]
			line += ("%2d " % roundi(h * 10.0)) if h > -1.0 else " . "
		print(line)
