class_name NetworkView
extends Node3D
## The campus as a network you can watch working. Tokens aren't carried
## anywhere: they're a service, so what you see is traffic.
##   uplink   every API Gateway beams up to the sky (the internet): requests
##            stream down it (cyan), tokens stream back up (gold)
##   fiber    an aerial fiber cable runs from the gateway's mast to every
##            server's router: request pulses ride in, token pulses ride out,
##            as many as the server is actually serving
##   power    power lines from the Solar Farms to every server and Training
##            Cluster; energy pulses flow as they draw, and turn red when the
##            grid is short
##   cooling  a cooling pipe from the Cooling Towers to every server with GPUs,
##            blue pulses as the GPUs are cooled
##   clients  the Chat Café's visitors and the Agent Hub's agents call the
##            nearest server over their own fiber; an Edge PoP has a smaller
##            uplink of its own and a fiber to the nearest server
## Cables hang from masts on the buildings and sag between them. The layout
## is rebuilt when buildings come, go, move or change look; the pulses are a
## few MultiMeshes moved every frame.

const FIBER_H := 9.0          # mast tops (m)
const POWER_H := 11.0
const COOL_Y := 0.18          # cooling pipes run along the ground
const SKY := 90.0
const MAX_PULSES := 420

## Pulse kinds: [colour, size, speed m/s]
const KINDS := {
	"req": [Color(0.45, 0.95, 1.0), 0.2, 15.0],
	"tok": [Color(1.0, 0.8, 0.32), 0.24, 13.0],
	"pow": [Color(1.0, 0.95, 0.55), 0.15, 18.0],
	"cool": [Color(0.4, 0.75, 1.0), 0.14, 6.0],
}

var world
var links: Array[Dictionary] = []      # {kind, pts, cum, len, src, dst, node, gw}
var beams: Array[Dictionary] = []      # {gw, base, len, rate}
var _pulses := {}                      # kind -> Array[{link (or -1 beam index), beam, s, dir}]
var _mm := {}                          # kind -> MultiMeshInstance3D
var _mats := {}                        # kind -> StandardMaterial3D
var _cables: MeshInstance3D
var _beam_mesh: MeshInstance3D
var _sig := ""
var _check := 0.0
var _acc := {}                         # spawn accumulators per link / beam


func _ready() -> void:
	_cables = MeshInstance3D.new()
	_cables.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_cables.material_override = Mats.toon()
	add_child(_cables)
	_beam_mesh = MeshInstance3D.new()
	_beam_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var bm := StandardMaterial3D.new()
	bm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	bm.cull_mode = BaseMaterial3D.CULL_DISABLED
	bm.vertex_color_use_as_albedo = true
	bm.no_depth_test = false
	_beam_mesh.material_override = bm
	add_child(_beam_mesh)
	for k in KINDS:
		_pulses[k] = []
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		# a streak of light pointing along its cable
		var sm := CapsuleMesh.new()
		var r: float = KINDS[k][1]
		sm.radius = r * 0.55
		sm.height = r * 5.0
		sm.radial_segments = 6
		sm.rings = 1
		mm.mesh = sm
		mm.instance_count = 0
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = KINDS[k][0]
		m.emission_enabled = true
		m.emission = KINDS[k][0]
		m.emission_energy_multiplier = 2.0
		mi.material_override = m
		add_child(mi)
		_mm[k] = mi
		_mats[k] = m


# ---------------------------------------------------------------- layout

## Where a building's cables attach (world): [mast foot, mast top].
func _attach(n: Building, h: float, kind: String) -> Array:
	var foot := n.global_position + Vector3(0, 2.4, 0)
	if n is ServerB:
		match kind:
			"fiber": foot = n.to_world(ServerB.ROUTER_X, ServerB.BUS_Z, 2.6)
			"power": foot = n.to_world(ServerB.DOCK_POS.x, ServerB.DOCK_POS.z, 1.8)
			"cool": foot = n.to_world(ServerB.BENCH_POS.x, ServerB.BENCH_POS.z, COOL_Y)
	elif n is ChannelB:
		foot = (n as ChannelB).intake()
	elif n is SourceB:
		foot = n.to_world(0.0, SourceB.PLOT.get_center().y, 1.6)
	elif n is CafeB:
		foot = n.to_world(-2.4, -1.4, 3.0)
	var top := Vector3(foot.x, h, foot.z) if kind != "cool" else Vector3(foot.x, COOL_Y, foot.z)
	return [foot, top]


func _nearest(p: Vector3, kind_list: Array) -> Building:
	var best: Building = null
	var bd := INF
	for kk in kind_list:
		for n in world.buildings_of(kk):
			if n is SiteB:
				continue
			var d := (n as Node3D).global_position.distance_squared_to(p)
			if d < bd:
				bd = d
				best = n
	return best


func _signature() -> String:
	var parts := PackedStringArray()
	for n in world.bnodes.values():
		if n is ServerB or n is ChannelB or n is SourceB or n is TrainerB or n is CafeB:
			if n is SiteB:
				continue
			var extra := str((n as ServerB).gpus() > 0) if n is ServerB else ""
			parts.append("%d:%s:%d:%s:%s" % [n.uid, n.kind, n.tier, str(n.global_position.snapped(Vector3.ONE * 0.1)), extra])
	parts.sort()
	return ",".join(parts)


func _rebuild() -> void:
	links.clear()
	beams.clear()
	_acc.clear()
	for k in _pulses:
		_pulses[k].clear()
	var k := MeshKit.new()
	var masts := {}     # uid:kind -> true (one mast per building per network)
	var gws: Array = []
	for g in world.buildings_of("gateway"):
		if not g is SiteB:
			gws.append(g)
	for g in gws:
		var a := _attach(g, FIBER_H, "fiber")
		beams.append({"gw": g, "base": a[1], "len": SKY - FIBER_H, "edge": false})
		_mast(k, a, Color(0.82, 0.84, 0.86), masts, "%d:f" % g.uid, true)
	# the clients: café, agent hub and edge PoPs call the nearest server
	for kk in ["cafe", "agent_hub", "edge"]:
		for c in world.buildings_of(kk):
			if c is SiteB:
				continue
			var sv := _nearest(c.global_position, ["server"])
			if sv:
				_link(k, "fiber", c, sv, FIBER_H - 1.0, masts, -1)
				links[links.size() - 1]["client"] = kk
			if kk == "edge":
				var ea := _attach(c, FIBER_H - 1.0, "fiber")
				beams.append({"gw": c, "base": ea[1], "len": SKY - FIBER_H + 1.0, "edge": true})
	for n in world.bnodes.values():
		if n is SiteB:
			continue
		if n is ServerB:
			var s := n as ServerB
			var gw := _nearest(s.global_position, ["gateway"])
			if gw:
				_link(k, "fiber", gw, s, FIBER_H, masts, gws.find(gw))
			var pw := _nearest(s.global_position, ["src_power"])
			if pw:
				_link(k, "power", pw, s, POWER_H, masts, -1)
			if s.gpus() > 0:
				var cl := _nearest(s.global_position, ["src_coolant"])
				if cl:
					_link(k, "cool", cl, s, COOL_Y, masts, -1)
		elif n is TrainerB:
			var pw2 := _nearest(n.global_position, ["src_power"])
			if pw2:
				_link(k, "power", pw2, n, POWER_H, masts, -1)
	_cables.mesh = k.commit()
	_beam_mesh.mesh = _beam_geometry()


func _mast(k: MeshKit, a: Array, col: Color, masts: Dictionary, key: String, crossarm := false) -> void:
	if masts.has(key):
		return
	masts[key] = true
	var foot: Vector3 = a[0]
	var top: Vector3 = a[1]
	var h := top.y - foot.y
	if h <= 0.2:
		return
	k.box(Vector3(0.09, h, 0.09), col, MeshKit.at(foot.x, foot.y + h * 0.5, foot.z))
	if crossarm:
		k.box(Vector3(0.9, 0.06, 0.08), col, MeshKit.at(top.x, top.y - 0.15, top.z))
	k.box(Vector3(0.16, 0.16, 0.16), Color(0.25, 0.26, 0.28), MeshKit.at(top.x, top.y, top.z))


func _link(k: MeshKit, kind: String, from: Building, to: Building, h: float, masts: Dictionary, gw_index: int) -> void:
	var a := _attach(from, h, kind)
	var b := _attach(to, h, kind)
	var pts := PackedVector3Array()
	var col: Color
	match kind:
		"fiber":
			col = Color(0.95, 0.78, 0.25)
			_mast(k, a, Color(0.82, 0.84, 0.86), masts, "%d:f" % from.uid, true)
			_mast(k, b, Color(0.82, 0.84, 0.86), masts, "%d:f" % to.uid)
		"power":
			col = Color(0.16, 0.16, 0.18)
			_mast(k, a, Color(0.42, 0.32, 0.22), masts, "%d:p" % from.uid, true)
			_mast(k, b, Color(0.42, 0.32, 0.22), masts, "%d:p" % to.uid, true)
		_:
			col = Color(0.36, 0.6, 0.86)
	pts.append(a[0])
	pts.append(a[1])
	var p0: Vector3 = a[1]
	var p1: Vector3 = b[1]
	var span := p0.distance_to(p1)
	var segs := maxi(2, int(span / 1.5))
	var sag := 0.0 if kind == "cool" else minf(3.0, span * 0.06)
	for i in range(1, segs):
		var f := float(i) / segs
		var q := p0.lerp(p1, f)
		q.y -= sag * 4.0 * f * (1.0 - f)
		pts.append(q)
	pts.append(b[1])
	pts.append(b[0])
	# the cable itself: thin boxes along the polyline
	var w := 0.06 if kind == "fiber" else (0.05 if kind == "power" else 0.16)
	var cum := PackedFloat32Array([0.0])
	for i in pts.size() - 1:
		var p := pts[i]
		var q2 := pts[i + 1]
		var d := q2 - p
		var len := d.length()
		cum.append(cum[i] + len)
		if len < 0.01:
			continue
		var basis := Basis.looking_at(d.normalized(), Vector3.UP if absf(d.normalized().y) < 0.99 else Vector3.FORWARD)
		k.box(Vector3(w, w, len), col, Transform3D(basis, (p + q2) * 0.5))
	links.append({"kind": kind, "pts": pts, "cum": cum, "len": cum[cum.size() - 1], "src": from, "dst": to, "gw": gw_index})


func _beam_geometry() -> Mesh:
	var k := MeshKit.new()
	for b in beams:
		var base: Vector3 = b["base"]
		var len: float = b["len"]
		if b["edge"]:
			k.cyl(0.2, len, Color(0.6, 0.8, 1.0, 0.08), MeshKit.at(base.x, base.y, base.z), 10, 0.0, 0.08, false)
			k.cyl(0.05, len, Color(0.8, 0.95, 1.0, 0.28), MeshKit.at(base.x, base.y, base.z), 6, 0.0, -1.0, false)
			k.torus(0.3, 0.03, Color(0.5, 0.9, 1.0, 0.5), MeshKit.at(base.x, base.y + 0.25, base.z), 14, 4)
			continue
		k.cyl(0.38, len, Color(0.4, 0.85, 1.0, 0.09), MeshKit.at(base.x, base.y, base.z), 12, 0.0, 0.12, false)
		k.cyl(0.07, len, Color(0.8, 0.97, 1.0, 0.32), MeshKit.at(base.x, base.y, base.z), 6, 0.0, -1.0, false)
		for i in 3:
			k.torus(0.42 + i * 0.16, 0.035, Color(0.5, 0.9, 1.0, 0.5 - i * 0.12), MeshKit.at(base.x, base.y + 0.25 + i * 0.35, base.z), 16, 4)
	return k.commit()


# ---------------------------------------------------------------- traffic

## Pulses a second for a flow of `x` (K tokens/s, kW...): busy reads busy.
static func pulse_rate(x: float) -> float:
	if x <= 0.0:
		return 0.0
	return clampf(0.7 + 2.2 * log(1.0 + x * 4.0) / log(10.0), 0.4, 9.0)


func _process(dt: float) -> void:
	if world == null:
		return
	_check -= dt
	if _check <= 0.0:
		_check = 0.6
		var sig := _signature()
		if sig != _sig:
			_sig = sig
			_rebuild()
	_spawn(dt)
	_advance(dt)
	_draw()
	var short := Market.power_f < 0.98
	var pm: StandardMaterial3D = _mats["pow"]
	var pc: Color = Color(1.0, 0.35, 0.25) if short else KINDS["pow"][0]
	pm.albedo_color = pc
	pm.emission = pc


func _count() -> int:
	var n := 0
	for k in _pulses:
		n += (_pulses[k] as Array).size()
	return n


func _emit(kind: String, link: int, beam: int, dir: int) -> void:
	if _count() >= MAX_PULSES:
		return
	_pulses[kind].append({"link": link, "beam": beam, "s": 0.0, "dir": dir})


func _spawn(dt: float) -> void:
	var beam_rate := {}
	for i in links.size():
		var l: Dictionary = links[i]
		if not is_instance_valid(l["dst"]):
			continue
		var rate := 0.0
		var kinds: Array = []
		match l["kind"]:
			"fiber":
				if l.has("client"):
					var flow := _client_flow(l["client"])
					rate = pulse_rate(flow)
					kinds = [["req", 1], ["tok", -1]]
				else:
					var s: ServerB = l["dst"]
					rate = pulse_rate(s.load_now * s.last_cap)
					kinds = [["req", 1], ["tok", -1]]
					if l["gw"] >= 0:
						beam_rate[l["gw"]] = float(beam_rate.get(l["gw"], 0.0)) + s.load_now * s.last_cap
			"power":
				var draw := 0.0
				if l["dst"] is ServerB:
					var s2: ServerB = l["dst"]
					draw = s2.accels() * s2.load_now * Bal.KW_PER_ACCEL * Market.power_f
				elif l["dst"] is TrainerB and (l["dst"] as TrainerB).training():
					draw = (l["dst"] as TrainerB).accels() * Bal.KW_PER_ACCEL * Market.power_f
				rate = pulse_rate(draw * 0.25)
				kinds = [["pow", 1]]
			"cool":
				var s3: ServerB = l["dst"]
				rate = pulse_rate(s3.gpus() * s3.load_now * 0.2) * 0.6
				kinds = [["cool", 1]]
		if rate <= 0.0:
			continue
		var key := "l%d" % i
		_acc[key] = float(_acc.get(key, randf())) + rate * dt
		while _acc[key] >= 1.0:
			_acc[key] -= 1.0
			for kd in kinds:
				_emit(kd[0], i, -1, kd[1])
	for bi in beams.size():
		var flow2 := _client_flow("edge") if beams[bi]["edge"] else float(beam_rate.get(bi, 0.0))
		var r := pulse_rate(flow2) * (1.0 if beams[bi]["edge"] else 1.4)
		if r <= 0.0:
			continue
		var key2 := "b%d" % bi
		_acc[key2] = float(_acc.get(key2, randf())) + r * dt
		while _acc[key2] >= 1.0:
			_acc[key2] -= 1.0
			_emit("req", -1, bi, -1)      # down from the sky
			_emit("tok", -1, bi, 1)       # up to the sky


## Traffic one client building brings (K tokens/s): its channel's share.
func _client_flow(kind: String) -> float:
	var n: int = max(1, world.buildings_of(kind).size())
	match kind:
		"cafe": return Market.total(Market.by_channel.get("cafe", {})) / n
		"agent_hub": return Market.total(Market.by_channel.get("agent", {})) / n
		"edge":
			var r := Market.reach()
			return Market.total(Market.by_channel.get("api", {})) * (Bal.edge_demand(1) / maxf(0.01, r)) / n
	return 0.0


func _advance(dt: float) -> void:
	for kind in _pulses:
		var spd: float = KINDS[kind][2]
		var arr: Array = _pulses[kind]
		var i := arr.size() - 1
		while i >= 0:
			var p: Dictionary = arr[i]
			p["s"] = float(p["s"]) + spd * dt
			var length := _length(p)
			if length <= 0.0 or float(p["s"]) >= length:
				# a request reaching a server goes on down its request bus
				if kind == "req" and int(p["beam"]) < 0 and int(p["link"]) < links.size():
					var dst = links[int(p["link"])]["dst"]
					if dst is ServerB and is_instance_valid(dst):
						(dst as ServerB).network_request()
				arr.remove_at(i)
			i -= 1


func _length(p: Dictionary) -> float:
	if int(p["beam"]) >= 0:
		return float(beams[int(p["beam"])]["len"]) if int(p["beam"]) < beams.size() else 0.0
	var li := int(p["link"])
	return float(links[li]["len"]) if li < links.size() else 0.0


## World position of a pulse and the way it's heading: [pos, dir].
func _pos(p: Dictionary) -> Array:
	var s := float(p["s"])
	if int(p["beam"]) >= 0:
		var b: Dictionary = beams[int(p["beam"])]
		var base: Vector3 = b["base"]
		var len: float = b["len"]
		var up := int(p["dir"]) > 0
		var y := s if up else len - s
		# requests come down one side of the beam, tokens go up the other
		var side := 0.16 if up else -0.16
		return [base + Vector3(side, y, side * 0.5), Vector3.UP if up else Vector3.DOWN]
	var l: Dictionary = links[int(p["link"])]
	var total: float = l["len"]
	var d := s if int(p["dir"]) > 0 else total - s
	var cum: PackedFloat32Array = l["cum"]
	var pts: PackedVector3Array = l["pts"]
	var lo := 0
	var hi := cum.size() - 1
	while hi - lo > 1:
		var mid := (lo + hi) >> 1
		if cum[mid] <= d:
			lo = mid
		else:
			hi = mid
	var seg := cum[hi] - cum[lo]
	var f := (d - cum[lo]) / seg if seg > 0.0 else 0.0
	var dir := (pts[hi] - pts[lo]).normalized() * (1.0 if int(p["dir"]) > 0 else -1.0)
	# requests and tokens ride either side of the cable
	var side := Vector3(-dir.z, 0, dir.x).normalized() * (0.07 if int(p["dir"]) > 0 else -0.07)
	return [pts[lo].lerp(pts[hi], f) + side, dir]


func _draw() -> void:
	for kind in _pulses:
		var arr: Array = _pulses[kind]
		var mm: MultiMesh = (_mm[kind] as MultiMeshInstance3D).multimesh
		if mm.instance_count != arr.size():
			mm.instance_count = arr.size()
		if arr.is_empty():
			continue
		var buf := PackedFloat32Array()
		buf.resize(arr.size() * 12)
		var j := 0
		for p in arr:
			var pd := _pos(p)
			var o: Vector3 = pd[0]
			var d: Vector3 = pd[1]
			var bs: Basis
			if d.y < -0.999:
				bs = Basis(Vector3.RIGHT, PI)
			elif d.y > 0.999 or d.length_squared() < 0.0001:
				bs = Basis.IDENTITY
			else:
				bs = Basis(Quaternion(Vector3.UP, d))
			buf[j] = bs.x.x; buf[j + 1] = bs.y.x; buf[j + 2] = bs.z.x; buf[j + 3] = o.x
			buf[j + 4] = bs.x.y; buf[j + 5] = bs.y.y; buf[j + 6] = bs.z.y; buf[j + 7] = o.y
			buf[j + 8] = bs.x.z; buf[j + 9] = bs.y.z; buf[j + 10] = bs.z.z; buf[j + 11] = o.z
			j += 12
		mm.buffer = buf
