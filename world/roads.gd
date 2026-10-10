class_name Roads
extends RefCounted
## The road network. Roads build themselves: every building's entrance (the
## cell or two in front of the middle of its front edge) gets a cobbled path
## to the Cookie Hall, joining the nearest road already there. Paths only run
## over free land you own, so they go around buildings, never through them,
## and turn as little as they can.
##
## Porters walk only on roads (a cell-sized A* over road cells), so a
## building whose entrance is walled in gets no deliveries until you make
## room.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const STEP_NEW := 3        # cost of paving a new cell
const STEP_ROAD := 1       # cost of walking an existing road
const TURN := 2            # extra cost of a turn

## cell -> bits: 1 = road, 2 << dir = a doorstep stub toward a building
var cells := {}
## uid -> true for buildings joined to the Hall
var connected := {}
## uid -> path cells from its entrance to the network (for the placement preview)
var paths := {}
var astar := AStarGrid2D.new()
var region := Rect2i()


## Rebuilds every road from scratch. `blocked(c)` says whether a cell is
## taken; `owned(c)` whether you own it. `entries` = [{uid, cells, stub, d}]
## with the Hall's first (d = distance to the hall, used for ordering).
func build(entries: Array, blocked: Callable, owned: Callable, bounds: Rect2i) -> void:
	cells.clear()
	connected.clear()
	paths.clear()
	region = bounds
	if entries.is_empty():
		_rebuild_astar()
		return
	var network := {}
	var hall: Dictionary = entries[0]
	for c in hall["cells"]:
		if owned.call(c) and not blocked.call(c):
			network[c] = true
	if not network.is_empty():
		connected[hall["uid"]] = true
	var rest := entries.slice(1)
	rest.sort_custom(func(a, b): return a["d"] < b["d"])
	for e in rest:
		var starts: Array[Vector2i] = []
		for c in e["cells"]:
			if owned.call(c) and not blocked.call(c):
				starts.append(c)
		if starts.is_empty() or network.is_empty():
			continue
		var p := _search(starts, network, blocked, owned)
		if p.is_empty():
			continue
		connected[e["uid"]] = true
		paths[e["uid"]] = p
		for c in p:
			network[c] = true
		for c in starts:
			network[c] = true
	for c in network:
		cells[c] = 1
	for e in entries:
		if not connected.has(e["uid"]):
			continue
		for c in e["cells"]:
			if cells.has(c):
				cells[c] = int(cells[c]) | (2 << int(e["stub"]))
	_rebuild_astar()


## Path (cells) from any of `starts` to the nearest network cell, preferring
## existing roads and straight runs. Empty if there's no way.
func _search(starts: Array[Vector2i], network: Dictionary, blocked: Callable, owned: Callable) -> Array[Vector2i]:
	var buckets := {}
	var best := {}
	var parent := {}
	var lo := 0
	for s in starts:
		var k := Vector3i(s.x, s.y, 4)
		best[k] = 0
		_push(buckets, 0, k)
	var hi := 0
	var limit := (region.size.x * region.size.y) * 6 + 10
	var cost := 0
	while cost <= hi and cost < limit:
		var b: Array = buckets.get(cost, [])
		if b.is_empty():
			buckets.erase(cost)
			cost += 1
			continue
		var cur: Vector3i = b.pop_back()
		if int(best.get(cur, 1 << 30)) < cost:
			continue
		var cc := Vector2i(cur.x, cur.y)
		if network.has(cc):
			var out: Array[Vector2i] = []
			var k2 := cur
			while true:
				out.append(Vector2i(k2.x, k2.y))
				if not parent.has(k2):
					break
				k2 = parent[k2]
			return out
		for d in 4:
			var nc := cc + DIRS[d]
			if not region.has_point(nc) or blocked.call(nc) or not owned.call(nc):
				continue
			var step := STEP_ROAD if network.has(nc) else STEP_NEW
			if cur.z != 4 and cur.z != d:
				step += TURN
			var nk := Vector3i(nc.x, nc.y, d)
			var nv := cost + step
			if nv < int(best.get(nk, 1 << 30)):
				best[nk] = nv
				parent[nk] = cur
				_push(buckets, nv, nk)
				hi = maxi(hi, nv)
	return []


static func _push(buckets: Dictionary, c: int, k: Vector3i) -> void:
	if not buckets.has(c):
		buckets[c] = []
	buckets[c].append(k)


func is_road(c: Vector2i) -> bool:
	return cells.has(c)


func _rebuild_astar() -> void:
	astar = AStarGrid2D.new()
	if region.size == Vector2i.ZERO:
		return
	astar.region = region
	astar.cell_size = Vector2(Grid.CELL, Grid.CELL)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_NEVER
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_MANHATTAN
	astar.update()
	astar.fill_solid_region(region, true)
	for c in cells:
		if region.has_point(c):
			astar.set_point_solid(c, false)


## Cells along the roads from one cell to another (both should be road cells).
func route(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if not region.has_point(from) or not region.has_point(to) or astar.is_point_solid(from) or astar.is_point_solid(to):
		return out
	for p in astar.get_id_path(from, to):
		out.append(p)
	return out
