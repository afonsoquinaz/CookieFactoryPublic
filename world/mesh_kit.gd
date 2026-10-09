class_name MeshKit
extends RefCounted
## Builds smooth, rounded low-poly meshes with baked vertex colours.
##
## Everything in the game is assembled from a handful of primitives (rounded
## boxes, lathed profiles, spheres, tori), each placed with a Transform3D and
## a colour, then merged into one ArrayMesh drawn with the shared toon
## material. One mesh + one material per prop keeps draw calls low on phones.
##
##   var k := MeshKit.new()
##   k.rbox(Vector3(1, 0.5, 1), 0.12, Pal.WOOD)
##   k.sphere(0.3, Pal.RED, MeshKit.at(0, 0.6, 0))
##   var mesh := k.commit()
##
## A colour with alpha < 1 marks a glowing part (see toon.gdshader).

static var _cache := {}
## Global tessellation multiplier for round shapes (lower on weak devices).
static var detail := 0.75

var _v := PackedVector3Array()
var _n := PackedVector3Array()
var _c := PackedColorArray()
var _i := PackedInt32Array()


static func at(x: float, y: float, z: float) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(x, y, z))


## Transform with rotation in degrees (applied Y, then X, then Z) and scale.
static func xf(pos: Vector3, rot_deg := Vector3.ZERO, scl := Vector3.ONE) -> Transform3D:
	var b := Basis.from_euler(Vector3(deg_to_rad(rot_deg.x), deg_to_rad(rot_deg.y), deg_to_rad(rot_deg.z)), EULER_ORDER_YXZ)
	return Transform3D(b.scaled_local(scl), pos)


## Memoises a built mesh under a key so every instance shares one resource.
static func cached(key: String, build: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = build.call()
	return _cache[key]


func vertex_count() -> int:
	return _v.size()


func commit() -> ArrayMesh:
	var arr := []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = _v
	arr[Mesh.ARRAY_NORMAL] = _n
	arr[Mesh.ARRAY_COLOR] = _c
	arr[Mesh.ARRAY_INDEX] = _i
	var m := ArrayMesh.new()
	if _v.size() > 0:
		m.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return m


## Appends another builder's geometry (already in this space).
func merge(other: MeshKit, t := Transform3D.IDENTITY) -> void:
	_push(t, other._v, other._n, other._c, other._i)


func _push(t: Transform3D, vs: PackedVector3Array, ns: PackedVector3Array, cs: PackedColorArray, idx: PackedInt32Array) -> void:
	var base := _v.size()
	var nb := t.basis.inverse().transposed()
	var flip := t.basis.determinant() < 0.0
	for k in vs.size():
		_v.append(t * vs[k])
		_n.append((nb * ns[k]).normalized())
		_c.append(cs[k])
	if flip:
		for k in range(0, idx.size(), 3):
			_i.append(base + idx[k])
			_i.append(base + idx[k + 2])
			_i.append(base + idx[k + 1])
	else:
		for k in idx:
			_i.append(base + k)


# ------------------------------------------------------------------ primitives

## Box with rounded edges and corners (radius r), centred on the origin.
func rbox(size: Vector3, r: float, col: Color, t := Transform3D.IDENTITY, steps := -1) -> MeshKit:
	var h := size * 0.5
	if steps < 0:
		# small bevels don't need many rings
		steps = 1 if r < 0.07 else 2
	r = clampf(r, 0.0, minf(h.x, minf(h.y, h.z)) - 0.0001)
	if r <= 0.001:
		steps = 0
	var inner := h - Vector3(r, r, r)
	# per-axis sample coordinates: corners get tan-spaced samples so the
	# projected points land evenly on the rounded arc
	var axes := []
	for a in 3:
		var hi := inner[a]
		var coords := PackedFloat32Array()
		for s in range(steps, -1, -1):
			coords.append(-hi - r * tan(deg_to_rad(45.0 * s / maxf(steps, 1))))
		for s in range(0, steps + 1):
			coords.append(hi + r * tan(deg_to_rad(45.0 * s / maxf(steps, 1))))
		if steps == 0:
			coords = PackedFloat32Array([-h[a], h[a]])
		axes.append(coords)
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var cs := PackedColorArray()
	var idx := PackedInt32Array()
	# faces: normal axis, sign, u axis, v axis (u x v = normal for winding)
	var faces := [[0, 1, 1, 2], [0, -1, 2, 1], [1, 1, 2, 0], [1, -1, 0, 2], [2, 1, 0, 1], [2, -1, 1, 0]]
	for f in faces:
		var na: int = f[0]
		var sgn: float = f[1]
		var ua: int = f[2]
		var va: int = f[3]
		var uc: PackedFloat32Array = axes[ua]
		var vc: PackedFloat32Array = axes[va]
		var start := vs.size()
		for j in vc.size():
			for i in uc.size():
				var p := Vector3.ZERO
				p[na] = h[na] * sgn
				p[ua] = uc[i] if sgn > 0 else uc[i]
				p[va] = vc[j]
				var c := p.clamp(-inner, inner)
				var d := p - c
				var n := Vector3.ZERO
				n[na] = sgn
				if r > 0.001 and d.length() > 0.00001:
					n = d.normalized()
				vs.append(c + n * r if r > 0.001 else p)
				ns.append(n)
				cs.append(col)
		var w := uc.size()
		for j in vc.size() - 1:
			for i in w - 1:
				var a0 := start + j * w + i
				var a1 := a0 + 1
				var b0 := a0 + w
				var b1 := b0 + 1
				if sgn > 0:
					idx.append_array([a0, b0, a1, a1, b0, b1])
				else:
					idx.append_array([a0, a1, b0, a1, b1, b0])
	_fix_winding(vs, ns, idx)
	_push(t, vs, ns, cs, idx)
	return self


## Surface of revolution around +Y. profile: (radius, height) from bottom to
## top; repeat a point to make a hard edge there. cols: one colour per profile
## point (or a single colour).
func lathe(profile: PackedVector2Array, col, t := Transform3D.IDENTITY, segs := 16, arc := TAU) -> MeshKit:
	segs = maxi(5, int(round(segs * detail)))
	var count := profile.size()
	var pn := PackedVector2Array()
	pn.resize(count)
	for i in count:
		var acc := Vector2.ZERO
		if i > 0:
			var d := profile[i] - profile[i - 1]
			if d.length() > 0.00001:
				acc += Vector2(d.y, -d.x).normalized()
		if i < count - 1:
			var d2 := profile[i + 1] - profile[i]
			if d2.length() > 0.00001:
				acc += Vector2(d2.y, -d2.x).normalized()
		pn[i] = acc.normalized() if acc.length() > 0.0001 else Vector2(0, 1)
	var full := is_equal_approx(arc, TAU)
	var ring := segs + 1
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var cs := PackedColorArray()
	var idx := PackedInt32Array()
	for i in count:
		var c: Color = col[i] if col is Array or col is PackedColorArray else col
		for s in ring:
			var a := arc * float(s) / segs
			var ca := cos(a)
			var sa := sin(a)
			vs.append(Vector3(profile[i].x * ca, profile[i].y, profile[i].x * sa))
			ns.append(Vector3(pn[i].x * ca, pn[i].y, pn[i].x * sa).normalized())
			cs.append(c)
	for i in count - 1:
		if (profile[i + 1] - profile[i]).length() < 0.00001:
			continue
		for s in segs:
			var a0 := i * ring + s
			var a1 := a0 + 1
			var b0 := a0 + ring
			var b1 := b0 + 1
			idx.append_array([a0, a1, b0, a1, b1, b0])
	if not full:
		pass
	_fix_winding(vs, ns, idx)
	_push(t, vs, ns, cs, idx)
	return self


func sphere(r: float, col: Color, t := Transform3D.IDENTITY, segs := 16, rings := 10) -> MeshKit:
	rings = maxi(3, int(round(rings * detail)))
	var p := PackedVector2Array()
	for i in rings + 1:
		var a := -PI * 0.5 + PI * float(i) / rings
		p.append(Vector2(cos(a) * r, sin(a) * r))
	p[0].x = 0.0
	p[rings].x = 0.0
	return lathe(p, col, t, segs)


## Sphere squashed/stretched to radii rad.
func ellipsoid(rad: Vector3, col: Color, t := Transform3D.IDENTITY, segs := 16, rings := 10) -> MeshKit:
	var s := Transform3D(Basis.from_scale(rad), Vector3.ZERO)
	var k := MeshKit.new()
	k.sphere(1.0, col, Transform3D.IDENTITY, segs, rings)
	_push(t * s, k._v, k._n, k._c, k._i)
	return self


## Cylinder from y=0 to y=h with bevelled rims (bevel radius b). r2 = top radius.
func cyl(r: float, h: float, col, t := Transform3D.IDENTITY, segs := 16, b := 0.0, r2 := -1.0, caps := true) -> MeshKit:
	if r2 < 0.0:
		r2 = r
	b = minf(b, minf(minf(r, r2), h * 0.5) - 0.0001)
	var p := PackedVector2Array()
	var cols := []
	var c_bot: Color = col[0] if col is Array else col
	var c_top: Color = col[1] if col is Array else col
	if caps:
		p.append(Vector2(0, 0)); cols.append(c_bot)
	var bn := 3 if b > 0.05 else 2
	if b > 0.001:
		for k in bn + 1:
			var a := PI * 0.5 * float(k) / bn
			p.append(Vector2(r - b + sin(a) * b, b - cos(a) * b)); cols.append(c_bot)
		for k in bn + 1:
			var a := PI * 0.5 * float(k) / bn
			p.append(Vector2(r2 - b + cos(a) * b, h - b + sin(a) * b)); cols.append(c_top)
	else:
		if caps:
			p.append(Vector2(r, 0)); cols.append(c_bot)
		p.append(Vector2(r, 0)); cols.append(c_bot)
		p.append(Vector2(r2, h)); cols.append(c_top)
		if caps:
			p.append(Vector2(r2, h)); cols.append(c_top)
	if caps:
		p.append(Vector2(0, h)); cols.append(c_top)
	return lathe(p, cols, t, segs)


## Capsule standing on y=0, total height h.
func capsule(r: float, h: float, col: Color, t := Transform3D.IDENTITY, segs := 14, rings := 4) -> MeshKit:
	rings = maxi(2, int(round(rings * detail)))
	var p := PackedVector2Array()
	for i in rings + 1:
		var a := -PI * 0.5 + PI * 0.5 * float(i) / rings
		p.append(Vector2(cos(a) * r, r + sin(a) * r))
	for i in rings + 1:
		var a := PI * 0.5 * float(i) / rings
		p.append(Vector2(cos(a) * r, h - r + sin(a) * r))
	p[0].x = 0.0
	p[p.size() - 1].x = 0.0
	return lathe(p, col, t, segs)


## Torus in the XZ plane.
func torus(big_r: float, small_r: float, col: Color, t := Transform3D.IDENTITY, segs := 18, sides := 8, arc := TAU) -> MeshKit:
	sides = maxi(3, int(round(sides * detail)))
	var p := PackedVector2Array()
	for i in sides + 1:
		var a := TAU * float(i) / sides
		p.append(Vector2(big_r + cos(a) * small_r, sin(a) * small_r))
	return lathe(p, col, t, segs, arc)


## Cone / spike standing on y=0.
func cone(r: float, h: float, col: Color, t := Transform3D.IDENTITY, segs := 12) -> MeshKit:
	return lathe(PackedVector2Array([Vector2(0, 0), Vector2(r, 0), Vector2(r, 0), Vector2(0, h)]), col, t, segs)


## Flat polygon (in XZ) extruded upward by depth, with flat sides.
func prism(poly: PackedVector2Array, depth: float, col: Color, t := Transform3D.IDENTITY) -> MeshKit:
	var vs := PackedVector3Array()
	var ns := PackedVector3Array()
	var cs := PackedColorArray()
	var idx := PackedInt32Array()
	var tri := Geometry2D.triangulate_polygon(poly)
	for y in [0.0, depth]:
		var start := vs.size()
		for q in poly:
			vs.append(Vector3(q.x, y, q.y))
			ns.append(Vector3(0, 1 if y > 0 else -1, 0))
			cs.append(col)
		for k in range(0, tri.size(), 3):
			idx.append_array([start + tri[k], start + tri[k + 1], start + tri[k + 2]])
	var m := poly.size()
	for q in m:
		var a := poly[q]
		var b := poly[(q + 1) % m]
		var e := (b - a).normalized()
		var n := Vector3(e.y, 0, -e.x)
		var s := vs.size()
		vs.append_array([Vector3(a.x, 0, a.y), Vector3(b.x, 0, b.y), Vector3(a.x, depth, a.y), Vector3(b.x, depth, b.y)])
		ns.append_array([n, n, n, n])
		cs.append_array([col, col, col, col])
		idx.append_array([s, s + 1, s + 2, s + 1, s + 3, s + 2])
	_fix_winding(vs, ns, idx)
	_push(t, vs, ns, cs, idx)
	return self


## A rounded star badge (for icons on signs), in XZ, extruded.
func star(r_out: float, r_in: float, points: int, depth: float, col: Color, t := Transform3D.IDENTITY) -> MeshKit:
	var poly := PackedVector2Array()
	for k in points * 2:
		var a := -PI * 0.5 + PI * float(k) / points
		var rr := r_out if k % 2 == 0 else r_in
		poly.append(Vector2(cos(a) * rr, sin(a) * rr))
	return prism(poly, depth, col, t)


## Every triangle faces where its vertex normals point (Godot draws
## clockwise-wound triangles as front faces).
static func _fix_winding(vs: PackedVector3Array, ns: PackedVector3Array, idx: PackedInt32Array) -> void:
	for k in range(0, idx.size(), 3):
		var a := vs[idx[k]]
		var b := vs[idx[k + 1]]
		var c := vs[idx[k + 2]]
		var fn := (b - a).cross(c - a)
		var avg := ns[idx[k]] + ns[idx[k + 1]] + ns[idx[k + 2]]
		if fn.length_squared() < 1e-14:
			continue
		# Godot's front faces are clockwise as seen from the front: the
		# geometric normal (b-a)x(c-a) then points away from the viewer.
		if fn.dot(avg) > 0.0:
			var tmp := idx[k + 1]
			idx[k + 1] = idx[k + 2]
			idx[k + 2] = tmp
