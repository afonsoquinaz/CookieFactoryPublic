class_name Grid
extends RefCounted
## The building grid. Cells are CELL metres square; cell (x, y) covers
## world x in [x*CELL, (x+1)*CELL) and world z in [y*CELL, (y+1)*CELL).
## Tracks which building occupies which cell and keeps an A* walking grid
## (SUB nodes per cell side) over the owned land for workers.

const CELL := 2.0
const SUB := 2                     # path nodes per cell side (1 m)
const STEP := CELL / SUB

var occ := {}                      # Vector2i -> uid
var _cells_of := {}                # uid -> Array[Vector2i]
var _solids := {}                  # uid -> Array[Rect2] (world xz)
var astar := AStarGrid2D.new()
var region := Rect2i()


static func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / CELL), floori(p.z / CELL))


static func cell_center(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * CELL, 0, (c.y + 0.5) * CELL)


static func rotated(size: Vector2i, rot: int) -> Vector2i:
	return Vector2i(size.y, size.x) if rot % 2 == 1 else size


## World centre of a footprint.
static func center_of(origin: Vector2i, size: Vector2i, rot: int) -> Vector3:
	var s := rotated(size, rot)
	return Vector3((origin.x + s.x * 0.5) * CELL, 0, (origin.y + s.y * 0.5) * CELL)


## Footprint origin so that its centre is as close as possible to p.
static func origin_for(p: Vector3, size: Vector2i, rot: int) -> Vector2i:
	var s := rotated(size, rot)
	return Vector2i(roundi(p.x / CELL - s.x * 0.5), roundi(p.z / CELL - s.y * 0.5))


static func cells(origin: Vector2i, size: Vector2i, rot: int) -> Array[Vector2i]:
	var s := rotated(size, rot)
	var out: Array[Vector2i] = []
	for x in s.x:
		for y in s.y:
			out.append(origin + Vector2i(x, y))
	return out


static func chunk_of(cell: Vector2i) -> Vector2i:
	return Vector2i(floori(float(cell.x) / Bal.CHUNK), floori(float(cell.y) / Bal.CHUNK))


## Rotation (radians, about Y) for rot steps: 0 = front faces +Z.
static func yaw(rot: int) -> float:
	return rot * PI * 0.5


# ---------------------------------------------------------------- occupancy

func fill(uid: int, origin: Vector2i, size: Vector2i, rot: int) -> void:
	clear(uid)
	var cs := cells(origin, size, rot)
	for c in cs:
		occ[c] = uid
	_cells_of[uid] = cs


func clear(uid: int) -> void:
	for c in _cells_of.get(uid, []):
		if occ.get(c, -1) == uid:
			occ.erase(c)
	_cells_of.erase(uid)


func at(c: Vector2i) -> int:
	return int(occ.get(c, 0))


## Free of other buildings (ignore = uid allowed to overlap, e.g. itself when moving).
func is_free(origin: Vector2i, size: Vector2i, rot: int, ignore := [] as Array) -> bool:
	for c in cells(origin, size, rot):
		var u := at(c)
		if u != 0 and not ignore.has(u):
			return false
	return true


func blockers(origin: Vector2i, size: Vector2i, rot: int) -> Array[int]:
	var out: Array[int] = []
	for c in cells(origin, size, rot):
		var u := at(c)
		if u != 0 and not out.has(u):
			out.append(u)
	return out

# ---------------------------------------------------------------- walking

## Rebuilds the A* grid over the owned land (+ a margin) with all solids.
func rebuild(chunks: Array[Vector2i]) -> void:
	if chunks.is_empty():
		return
	var mn := Vector2i(1 << 20, 1 << 20)
	var mx := Vector2i(-(1 << 20), -(1 << 20))
	for c in chunks:
		mn = Vector2i(mini(mn.x, c.x), mini(mn.y, c.y))
		mx = Vector2i(maxi(mx.x, c.x), maxi(mx.y, c.y))
	var n := Bal.CHUNK * SUB
	region = Rect2i(mn * n - Vector2i(4, 4), (mx - mn + Vector2i.ONE) * n + Vector2i(8, 8))
	astar.region = region
	astar.cell_size = Vector2(STEP, STEP)
	astar.offset = Vector2(STEP * 0.5, STEP * 0.5)
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	astar.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	astar.update()
	for uid in _solids:
		_mark(_solids[uid], true)


## World-space solid rects for a building (replaces the old ones).
func set_solids(uid: int, rects: Array[Rect2]) -> void:
	if _solids.has(uid):
		_mark(_solids[uid], false)
	_solids[uid] = rects
	_mark(rects, true)
	# a neighbour's solids may share nodes we just cleared
	for u in _solids:
		if u != uid:
			_mark(_solids[u], true)


func remove_solids(uid: int) -> void:
	if not _solids.has(uid):
		return
	_mark(_solids[uid], false)
	_solids.erase(uid)
	for u in _solids:
		_mark(_solids[u], true)


func _mark(rects: Array, solid: bool) -> void:
	if region.size == Vector2i.ZERO:
		return
	for r: Rect2 in rects:
		var a := Vector2i(floori(r.position.x / STEP + 0.15), floori(r.position.y / STEP + 0.15))
		var b := Vector2i(ceili(r.end.x / STEP - 0.15), ceili(r.end.y / STEP - 0.15))
		for x in range(a.x, b.x):
			for y in range(a.y, b.y):
				var p := Vector2i(x, y)
				if region.has_point(p):
					astar.set_point_solid(p, solid)


func _node(p: Vector3) -> Vector2i:
	return Vector2i(floori(p.x / STEP), floori(p.z / STEP))


func _nearest_open(n: Vector2i) -> Vector2i:
	if not region.has_point(n):
		n = Vector2i(clampi(n.x, region.position.x, region.end.x - 1), clampi(n.y, region.position.y, region.end.y - 1))
	if not astar.is_point_solid(n):
		return n
	for r in range(1, 8):
		for dx in range(-r, r + 1):
			for dy in [-r, r]:
				for q in [n + Vector2i(dx, dy), n + Vector2i(dy, dx)]:
					if region.has_point(q) and not astar.is_point_solid(q):
						return q
	return n


## Walking path between two world points (y = 0), smoothed a little.
func path(from: Vector3, to: Vector3) -> PackedVector3Array:
	var out := PackedVector3Array()
	if region.size == Vector2i.ZERO:
		out.append(to)
		return out
	var a := _nearest_open(_node(from))
	var b := _nearest_open(_node(to))
	var ids := astar.get_id_path(a, b, true)
	# string pulling: drop points while the straight line stays open
	var pts: Array[Vector2i] = []
	for p in ids:
		pts.append(p)
	var k := 0
	var keep: Array[Vector2i] = []
	while k < pts.size():
		keep.append(pts[k])
		var j := pts.size() - 1
		while j > k + 1 and not _clear_line(pts[k], pts[j]):
			j -= 1
		k = maxi(j, k + 1)
	for p in keep:
		out.append(Vector3((p.x + 0.5) * STEP, 0, (p.y + 0.5) * STEP))
	if out.size() > 0:
		out.remove_at(0)
	out.append(to)
	return out


func _clear_line(a: Vector2i, b: Vector2i) -> bool:
	var d := Vector2(b - a)
	var n := int(ceil(d.length() * 2.0))
	for i in range(1, n):
		var p := Vector2(a) + d * (float(i) / n)
		var q := Vector2i(roundi(p.x), roundi(p.y))
		if not region.has_point(q) or astar.is_point_solid(q):
			return false
	return true
