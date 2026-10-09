extends Node
## Lists which meshes cost the most triangles (--tris).
var n := 0
func _process(_dt):
	n += 1
	if n != 200:
		return
	var by := {}
	var stack: Array = [get_tree().root]
	while stack.size() > 0:
		var nd: Node = stack.pop_back()
		for c in nd.get_children():
			stack.append(c)
		if nd is MeshInstance3D and nd.mesh and nd.is_visible_in_tree():
			var m: Mesh = nd.mesh
			var t := 0
			for s in m.get_surface_count():
				var arr := m.surface_get_arrays(s)
				var idx = arr[Mesh.ARRAY_INDEX]
				t += (idx.size() / 3) if idx != null and idx.size() > 0 else (arr[Mesh.ARRAY_VERTEX].size() / 3)
			var key := str(nd.get_parent().name) + "/" + str(m.resource_name if m.resource_name != "" else str(m.get_instance_id()))
			key = nd.get_parent().get_class() + ":" + str(t)
			if not by.has(m):
				by[m] = [0, t, str(nd.get_path()).substr(0, 70)]
			by[m][0] += 1
	var rows := []
	for m in by:
		rows.append([by[m][0] * by[m][1], by[m][0], by[m][1], by[m][2]])
	rows.sort_custom(func(a, b): return a[0] > b[0])
	var total := 0
	for r in rows:
		total += r[0]
	print("TOTAL tris ", total)
	for i in mini(25, rows.size()):
		print(rows[i])
	get_tree().quit()
