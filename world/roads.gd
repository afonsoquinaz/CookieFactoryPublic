class_name Roads
extends RefCounted
## The road network. The High Street runs straight through your land from
## horizon to horizon (two cells wide, rows STREET_Y and STREET_Y + 1); vans
## drive off along it to sell. Side roads build themselves: every building's
## entrance (the cell or two in front of the middle of its front edge) gets a
## cobbled path to the High Street, joining the nearest road already there.
## Paths only run over free land you own, so they go around buildings, never
## through them, and turn as little as they can.
##
## Porters walk only on roads (a cell-sized A* over road cells), so a
## building whose entrance is walled in gets no deliveries until you make
## room.

const DIRS: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(0, -1)]
const STEP_NEW := 3        # cost of paving a new cell
const STEP_ROAD := 1       # cost of walking an existing road
const TURN := 2            # extra cost of a turn
const STREET_Y := -1       # the High Street covers rows STREET_Y and STREET_Y + 1

## cell -> bits: 1 = road, 2 << dir = a doorstep stub toward a building
var cells := {}
## uid -> true for buildings joined to the High Street
var connected := {}
## uid -> path cells from its entrance to the network (for the placement preview)
var paths := {}
var astar := AStarGrid2D.new()
var region := Rect2i()


static func is_street(c: Vector2i) -> bool:
	return c.y == STREET_Y or c.y == STREET_Y + 1


## Rebuilds every road from scratch. `blocked(c)` says whether a cell is
## taken; `owned(c)` whether you own it. `entries` = [{uid, cells, stub, d}]
## (d = distance to the High Street, used for ordering: nearest first).
func build(entries: Array, blocked: Callable, owned: Callable, bounds: Rect2i) -> void:
	cells.clear()
	connected.clear()
	paths.clear()
	region = bounds
	var network := {}
	if region.size != Vector2i.ZERO:
		for x in range(region.position.x, region.end.x):
			for y in [STREET_Y, STREET_Y + 1]:
				network[Vector2i(x, y)] = true
	var rest := entries.duplicate()
	rest.sort_custom(func(a, b): return a["d"] < b["d"])
	for e in rest:
		var starts: Array[Vector2i] = []
		for c in e["cells"]:
			if owned.call(c) and not blocked.call(c):
				starts.append(c)
		if starts.is_empty() or network.is_empty():
			continue
		var on := false
		for c in starts:
			if network.has(c):
				on = true
		if on:
			connected[e["uid"]] = true
			paths[e["uid"]] = [] as Array[Vector2i]
			for c in starts:
				network[c] = true
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
	# a lone grass cell boxed in by road reads as a hole: pave it
	var holes := []
	for c in cells:
		for d in DIRS:
			var h: Vector2i = c + d
			if cells.has(h) or blocked.call(h) or not owned.call(h):
				continue
			var n := 0
			for d2 in DIRS:
				if cells.has(h + d2):
					n += 1
			if n == 4 and not holes.has(h):
				holes.append(h)
	for h2 in holes:
		cells[h2] = 1
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
			var on_net := network.has(nc)
			if not region.has_point(nc) or (not on_net and (blocked.call(nc) or not owned.call(nc))):
				continue
			var step := STEP_ROAD if on_net else STEP_NEW
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
