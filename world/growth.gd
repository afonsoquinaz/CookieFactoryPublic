class_name Growth
## Everything a building gains level by level on top of its tier look, so
## every upgrade shows. Each kind lists slots (spots on the ground, on a roof
## or on a wall, each with the part it holds, see GrowthParts). Upgrades fill
## the slots one by one, then raise each part a grade (bigger, a second one,
## glowing), so a building that starts bare ends up busy with gear:
##   step s = slot s % slots, grade s / slots
## The first twenty or so upgrades each add a step; the rest are spread out
## to the top level (or crammed in, several per level, for short ladders).
## Roof heights come from world/growth_tops.gd (regenerate: godot --headless --path . res://dev/tops.tscn -- --write).

const GRADES := 4
const EARLY := 20                       # upgrades that each add one step

static var _plans := {}


# ---------------------------------------------------------------- slots

## Ordered slots for a kind at tier t: [{p: Vector3, yaw, part, top?}].
## The order is the order they fill in; the count is the same on every tier.
static func slots(kind: String, t: int) -> Array:
	var d: Dictionary = Defs.BUILDINGS[kind]
	match d["cat"]:
		"source": return _source(d["res"])
		"server": return _server(t)
		"lab", "pack":
			if kind == "depot":
				return _storage(kind)
			return _machine(kind)
		"train": return _trainer()
		"sell":
			match kind:
				"gateway": return _gateway()
				"cafe": return _cafe()
				"edge": return _edge()
				"agent_hub": return _agent_hub()
		"space":
			return _launchpad() if kind == "launchpad" else _groundstation()
		"staff":
			if kind == "dorm":
				return _dorm()
	return []


static func _s(x: float, z: float, part: String, yaw := 0.0, y := 0.0) -> Dictionary:
	return {"p": Vector3(x, y, z), "yaw": yaw, "part": part}


## A roof slot: its height comes from the growth_tops table.
static func _top(x: float, z: float, part: String, yaw := 0.0) -> Dictionary:
	return {"p": Vector3(x, 0, z), "yaw": yaw, "part": part, "top": true}


## The parts each source's front yard gathers (8 in the yard, 4 in the front
## corners inside its fence).
const SOURCE_PARTS := {
	"power": ["battery", "solar", "gen", "lamp", "cabinet", "battery", "plant", "crates", "lamp", "cabinet", "lamp", "battery"],
	"data": ["dish", "cabinet", "mast", "lamp", "robot", "crates", "kiosk", "plant", "cabinet", "lamp", "cabinet", "lamp"],
	"coolant": ["chiller", "pumps", "tanks", "lamp", "chiller", "drums", "plant", "kiosk", "tanks", "lamp", "pumps", "lamp"],
	"silicon": ["sandbags", "wafers", "drums", "lamp", "sandbags", "crates", "plant", "robot", "tanks", "lamp", "cabinet", "lamp"],
	"copper": ["ore", "drums", "reels", "lamp", "ore", "crates", "gen", "kiosk", "tanks", "lamp", "cabinet", "lamp"],
	"code": ["bench", "plant", "kiosk", "lamp", "bikes", "robot", "crates", "plant", "cabinet", "lamp", "plant", "lamp"],
	"labels": ["bench", "plant", "pallet", "lamp", "bikes", "kiosk", "crates", "plant", "cabinet", "lamp", "plant", "lamp"],
	"feedback": ["bench", "plant", "kiosk", "lamp", "bikes", "robot", "bench", "plant", "cabinet", "lamp", "plant", "lamp"],
	"rare": ["ore", "drums", "gen", "lamp", "ore", "tanks", "crates", "kiosk", "tanks", "lamp", "cabinet", "lamp"],
	"papers": ["books", "bench", "plant", "lamp", "books", "kiosk", "bikes", "plant", "plant", "lamp", "cabinet", "lamp"],
	"fiber": ["reels", "cabinet", "mast", "lamp", "reels", "crates", "dish", "kiosk", "cabinet", "lamp", "cabinet", "lamp"],
	"experts": ["bench", "plant", "kiosk", "lamp", "bikes", "robot", "books", "plant", "cabinet", "lamp", "plant", "lamp"],
}


static func _source(res: String) -> Array:
	var p: Array = SOURCE_PARTS.get(res, SOURCE_PARTS["code"])
	var sx := 2.62 if res == "power" else 2.52     # clear of the solar farm's wide stations
	# the front yard either side of the crate (back row tall, front row low),
	# then the front corners inside the fence (the back of the plot and the
	# back half of the side fences belong to the tier's buildings, SourceArt)
	return [
		_s(-1.55, 1.62, p[0]), _s(1.55, 1.62, p[1]), _s(-2.45, 1.62, p[2]), _s(2.45, 1.62, p[3]),
		_s(-1.55, 2.5, p[4]), _s(1.55, 2.5, p[5]), _s(-2.45, 2.5, p[6]), _s(2.45, 2.5, p[7]),
		_s(-2.45, 0.62, p[8], 90.0), _s(2.45, 0.62, p[9], -90.0), _s(-sx, -0.35, p[10], 90.0), _s(sx, -0.35, p[11], -90.0),
	]


static func _server(t: int) -> Array:
	# the server becomes a different building on every tier, so its art says
	# where the wall, roof and yard gear goes
	return ServerArt.slots(t)


## The parts a lab gathers, by slot: back corners, sides, front corners,
## front sides.
const MACHINE_PARTS := {
	"fab": ["chiller", "tanks", "cabinet", "wafers", "plant", "lamp", "crates", "battery"],
	"refinery": ["cabinet", "chiller", "drums", "cabinet", "plant", "lamp", "crates", "battery"],
	"tune_lab": ["chiller", "cabinet", "cabinet", "battery", "plant", "lamp", "kiosk", "crates"],
	"hbm_works": ["tanks", "chiller", "drums", "cabinet", "plant", "lamp", "wafers", "battery"],
	"rlhf_gym": ["cabinet", "chiller", "bikes", "battery", "plant", "lamp", "robot", "kiosk"],
	"synth_lab": ["chiller", "tanks", "cabinet", "drums", "plant", "lamp", "robot", "crates"],
}


static func _machine(kind: String) -> Array:
	var p: Array = MACHINE_PARTS.get(kind, MACHINE_PARTS["fab"])
	return [
		_s(-1.6, -1.6, p[0]), _s(1.6, 1.55, p[5]), _s(1.6, -1.6, p[1]), _s(-1.6, 1.55, p[4]),
		_s(-1.66, -0.55, p[2], 90.0), _s(1.66, -0.55, p[3], -90.0), _s(-1.72, 0.85, p[6], 90.0), _s(1.72, 0.85, p[7], -90.0),
	]


static func _storage(kind: String) -> Array:
	var tank := "pallet" if kind == "depot" else "cabinet"
	return [
		_s(-1.6, 1.55, "pallet"), _top(-1.0, -1.45, "ac"), _s(1.6, 1.55, "plant"), _top(1.0, -1.45, "solar_s"),
		_s(-1.66, 0.85, tank, 90.0), _s(1.66, 0.85, "battery", -90.0), _s(-1.66, 0.15, "kiosk", 90.0), _s(1.66, 0.15, "lamp", -90.0),
	]


static func _gateway() -> Array:
	# the front yard around the fiber rack, the hut's roof, along the sides
	return [
		_s(-1.0, 2.6, "pallet"), _top(0.3, -1.4, "ac"), _s(1.0, 2.6, "lamp"), _s(-1.85, 0.3, "cabinet", 90.0),
		_top(0.6, -1.0, "solar_s"), _s(1.6, 1.6, "kiosk", -90.0), _s(-1.85, 1.95, "reels", 90.0), _top(-1.4, -1.0, "vent"),
	]


static func _cafe() -> Array:
	return [
		_s(2.55, 1.5, "plant"), _top(-1.5, -1.3, "ac"), _s(-2.65, 1.55, "bench"), _top(2.2, -1.3, "solar_s"),
		_s(2.6, 0.55, "lamp", -90.0), _s(1.6, 1.6, "bikes"), _top(1.0, -1.4, "sign"), _top(-2.4, -1.4, "vent"),
		_s(-2.65, 0.75, "kiosk", 90.0),
	]


static func _edge() -> Array:
	# the yard in front of the container (its roof is all cooling units)
	return [
		_s(2.55, 2.55, "lamp"), _s(0.4, 2.55, "pallet"), _s(-0.3, 1.55, "chiller"), _s(2.65, 1.35, "kiosk", -90.0),
		_s(0.5, 0.65, "crates"), _s(1.25, 1.6, "cabinet"), _s(1.5, 2.6, "plant"), _s(-0.6, 2.6, "bench"),
		_s(-0.95, 0.6, "battery"),
	]


static func _agent_hub() -> Array:
	# around the plaza (its robots need the middle)
	return [
		_s(-2.65, 1.8, "plant", 90.0), _s(2.65, 1.8, "lamp", -90.0), _top(-1.5, -0.8, "solar_s"), _top(1.5, -0.8, "solar_s"),
		_s(-2.65, -1.6, "cabinet", 90.0), _s(2.65, -1.6, "battery", -90.0), _s(-2.6, 2.75, "kiosk"), _s(2.6, 2.75, "robot"),
		_top(0.0, -1.8, "ac"),
	]


static func _trainer() -> Array:
	return [
		_s(-3.4, 2.95, "chiller"), _top(-2.6, -3.75, "ac"), _s(2.0, 3.1, "plant"), _top(2.6, -3.75, "vent"),
		_s(-2.0, 3.1, "battery"), _s(3.6, -0.15, "cabinet", -90.0), _s(-3.65, -0.15, "tanks", 90.0), _s(0.0, 3.1, "kiosk"),
		_s(3.55, 3.4, "lamp"), _top(0.0, -3.75, "solar_s"),
	]


static func _launchpad() -> Array:
	return [
		_s(-3.4, -3.3, "tanks"), _s(3.5, 0.8, "lamp"), _s(-3.4, -0.2, "cabinet", 90.0), _top(3.0, 2.4, "dish_s"),
		_s(-3.6, 1.5, "battery", 90.0), _s(1.8, 3.4, "crates"), _s(3.6, -0.4, "chiller", -90.0), _s(-0.4, 3.5, "plant"),
	]


static func _groundstation() -> Array:
	return [
		_s(1.0, 2.5, "cabinet"), _s(2.5, 2.5, "lamp"), _top(-1.5, 1.8, "solar_s"), _s(-2.65, 0.4, "battery", 90.0),
		_s(0.6, 1.5, "kiosk"), _s(-2.6, -2.7, "plant"), _s(0.4, -2.7, "crates"), _s(2.6, 1.5, "chiller", -90.0),
	]


static func _dorm() -> Array:
	return [
		_top(-0.45, -1.55, "solar_s"), _s(1.85, 1.2, "lamp", -90.0), _s(-1.85, 1.2, "plant", 90.0), _top(0.45, -1.55, "dish_s"),
		_s(1.8, -0.6, "cabinet", -90.0), _s(1.8, -1.55, "tanks", -90.0),
	]


# ---------------------------------------------------------------- schedule

## The level at which each step appears.
static func plan(kind: String) -> PackedInt32Array:
	if _plans.has(kind):
		return _plans[kind]
	var n := slots(kind, 0).size() * GRADES
	var mx := Bal.max_level(kind)
	var out := PackedInt32Array()
	if n > 0 and mx > 1:
		if n > mx - 1:
			# more steps than upgrades: a few per level, evenly
			for i in n:
				out.append(2 + i * (mx - 1) / n)
		else:
			var early := mini(n, mini(EARLY, mx - 1))
			for i in n:
				if i < early:
					out.append(2 + i)
				else:
					var f := float(i - early + 1) / float(n - early)
					out.append(mini(mx, 1 + early + maxi(1, roundi(pow(f, 1.25) * float(mx - 1 - early)))))
	_plans[kind] = out
	return out


## How many steps a building has at level l.
static func count(kind: String, l: int) -> int:
	var c := 0
	for at in plan(kind):
		if l >= at:
			c += 1
	return c


## The grade of each slot after c steps (-1: not there yet).
static func grades(n_slots: int, c: int) -> PackedInt32Array:
	var g := PackedInt32Array()
	g.resize(n_slots)
	for i in n_slots:
		g[i] = -1
	for s in c:
		g[s % n_slots] = s / n_slots
	return g


# ---------------------------------------------------------------- meshes

static func mesh(kind: String, l: int, t: int) -> Mesh:
	var c := count(kind, l)
	return MeshKit.cached("growth_%s_%d_%d" % [kind, c, t], func(): return build(kind, c, t))


static func build(kind: String, c: int, t: int) -> Mesh:
	var k := MeshKit.new()
	var ss := slots(kind, t)
	if ss.is_empty():
		return k.commit()
	var g := grades(ss.size(), c)
	var col := colour(kind)
	for i in ss.size():
		if g[i] >= 0:
			k.add_mesh(part_mesh(ss[i]["part"], g[i], t, col), slot_xf(kind, ss[i], t))
	return k.commit()


## One part at one grade, built once and reused.
static func part_mesh(part: String, g: int, t: int, col: Color) -> Mesh:
	return MeshKit.cached("gpart_%s_%d_%d_%s" % [part, g, t, col.to_html(false)], func():
		var k := MeshKit.new()
		GrowthParts.draw(k, part, g, t, Transform3D.IDENTITY, col)
		return k.commit())


## Where slot s sits (local to the building).
static func slot_xf(kind: String, s: Dictionary, t: int) -> Transform3D:
	var p: Vector3 = s["p"]
	if s.get("top", false):
		p.y = top_y(kind, t, p.x, p.z)
	return MeshKit.xf(p, Vector3(0, float(s["yaw"]), 0), Vector3.ONE * scale_of(kind))


## Parts are drawn a bit bigger on big buildings.
static func scale_of(kind: String) -> float:
	match Defs.BUILDINGS[kind]["cat"]:
		"server": return 1.3
		"source": return 1.12
	return 1.0


## What step i brings: "New Rooftop AC", "Bigger GPU Crates"...
static func step_name(kind: String, i: int) -> String:
	var ss := slots(kind, 0)
	if ss.is_empty():
		return ""
	var nm: String = GrowthParts.NAMES.get(ss[i % ss.size()]["part"], "gear")
	return "%s %s" % [GrowthParts.GRADE_WORDS[clampi(i / ss.size(), 0, 3)], nm]


## What the next upgrade from level l adds ("" if nothing).
static func next_desc(kind: String, l: int) -> String:
	var a := count(kind, l)
	var b := count(kind, l + 1)
	if b <= a:
		return ""
	var names := []
	for i in range(a, b):
		names.append(step_name(kind, i))
	return ", ".join(names)


## Where step i shows (for the puff when it arrives).
static func step_pos(kind: String, i: int, t: int) -> Vector3:
	var ss := slots(kind, t)
	if ss.is_empty():
		return Vector3.ZERO
	return slot_xf(kind, ss[i % ss.size()], t).origin


## The building's own colour, for drums, crates, signs.
static func colour(kind: String) -> Color:
	var d: Dictionary = Defs.BUILDINGS[kind]
	if d.has("res"):
		return Defs.ITEMS[d["res"]]["color"]
	var outs: Dictionary = d.get("out", {})
	for o in outs:
		if Defs.ITEMS.has(o):
			return Defs.ITEMS[o]["color"]
	return Color(0.3, 0.66, 0.68)


# ---------------------------------------------------------------- roofs

## Roof height under a top slot (from the generated table).
static func top_y(kind: String, t: int, x: float, z: float) -> float:
	return float(GrowthTops.TOPS.get(_top_key(kind, t, x, z), [0.0, 0.0])[0])


static func _top_key(kind: String, t: int, x: float, z: float) -> String:
	return "%s:%d:%.2f:%.2f" % [kind, t, x, z]


## Every top slot: [kind, tier, x, z].
static func top_slots() -> Array:
	var out := []
	for kind in Defs.BUILD_ORDER:
		for t in 5:
			for s in slots(kind, t):
				if s.get("top", false):
					out.append([kind, t, s["p"].x, s["p"].z])
	return out


## Regenerates world/growth_tops.gd: the roof height under every top slot
## (highest point of the building's mesh over a 0.5 x 0.4 m patch) and how
## uneven that patch is.
static func write_tops() -> void:
	var lines := ["## Generated by dev/tops.tscn --write: roof height under each Growth top slot,", "## [height, unevenness]. Don't edit by hand.", "class_name GrowthTops", "", "const TOPS := {"]
	var cache := {}
	for e in top_slots():
		var key := "%s:%d" % [e[0], e[1]]
		if not cache.has(key):
			cache[key] = triangles(Previews.mesh(e[0], "", e[1]))
		var pts: Array[Vector2] = []
		for dx in [-0.25, 0.0, 0.25]:
			for dz in [-0.2, 0.0, 0.2]:
				pts.append(Vector2(e[2] + dx, e[3] + dz))
		var hs := heights(cache[key], pts)
		var lo := 99.0
		var hi := -99.0
		for h in hs:
			lo = minf(lo, h)
			hi = maxf(hi, h)
		lines.append('\t"%s": [%.3f, %.3f],' % [_top_key(e[0], e[1], e[2], e[3]), hi, hi - lo])
	lines.append("}")
	var f := FileAccess.open("res://world/growth_tops.gd", FileAccess.WRITE)
	f.store_string("\n".join(lines) + "\n")
	f.close()
	print("growth tops: %d slots" % top_slots().size())


## The mesh's triangles as a flat PackedVector3Array (3 per triangle).
static func triangles(m: Mesh) -> PackedVector3Array:
	var out := PackedVector3Array()
	for si in m.get_surface_count():
		var arr := m.surface_get_arrays(si)
		var vs: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
		var idx: PackedInt32Array = arr[Mesh.ARRAY_INDEX]
		if idx.is_empty():
			out.append_array(vs)
		else:
			for i in idx:
				out.append(vs[i])
	return out


## Highest surface over each point (-9 where there's nothing).
static func heights(tris: PackedVector3Array, pts: Array[Vector2]) -> PackedFloat32Array:
	var hs := PackedFloat32Array()
	hs.resize(pts.size())
	hs.fill(-9.0)
	for i in range(0, tris.size(), 3):
		var a := tris[i]
		var b := tris[i + 1]
		var c := tris[i + 2]
		var x0 := minf(a.x, minf(b.x, c.x))
		var x1 := maxf(a.x, maxf(b.x, c.x))
		var z0 := minf(a.z, minf(b.z, c.z))
		var z1 := maxf(a.z, maxf(b.z, c.z))
		var den := (b.z - c.z) * (a.x - c.x) + (c.x - b.x) * (a.z - c.z)
		if absf(den) < 1e-9:
			continue
		for j in pts.size():
			var p := pts[j]
			if p.x < x0 or p.x > x1 or p.y < z0 or p.y > z1:
				continue
			var w1 := ((b.z - c.z) * (p.x - c.x) + (c.x - b.x) * (p.y - c.z)) / den
			var w2 := ((c.z - a.z) * (p.x - c.x) + (a.x - c.x) * (p.y - c.z)) / den
			var w3 := 1.0 - w1 - w2
			if w1 < -1e-4 or w2 < -1e-4 or w3 < -1e-4:
				continue
			var y := w1 * a.y + w2 * b.y + w3 * c.y
			if y > hs[j]:
				hs[j] = y
	return hs
