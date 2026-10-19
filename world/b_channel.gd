class_name ChannelB
extends Building
## Where customers' calls come from and the links that carry them (see
## Market):
##   gateway        API Gateway: developers' API calls arrive here (more
##                  customers for every model) and leave through its
##                  bandwidth; couriers rack fiber spools on it for more
##   edge           Edge PoP: closer to customers, 25 ms less latency for
##                  every model and customers in new regions
##   agent_hub      Agent Hub: AI agents running long jobs on tool-capable
##                  models, paying double; its robots trundle around
##   groundstation  Ground Station: downlink for the orbital datacenter

var fiber_in: Holder
var _spools: MeshInstance3D
var _label: Label3D
var _badge: Node3D
var _bots: Array[Node3D] = []
var _bot_goal: Array[Vector3] = []
var _beacon_t := 0.0
var _traffic_t := 0.0
var _in_flight := 0


func _build() -> void:
	if kind == "gateway":
		fiber_in = Holder.new().setup(1, ["fiber"], Holder.Layout.NONE)
		fiber_in.position = Vector3(-0.6, 1.2, 1.15)
		add_child(fiber_in)
		fiber_in.landed.connect(_install_fiber)
		add_port(fiber_in, null, "in")
	_label = UI3D.label("", 26, Color(0.7, 0.96, 1.0))
	_label.position = Vector3(0, _label_y(), 0.0)
	add_child(_label)
	_badge = UI3D.badge(def["icon"], Pal.STEEL_DARK, 0.6)
	_badge.position = Vector3(0, _label_y() + 0.7, 0.0)
	add_child(_badge)


func _label_y() -> float:
	return InfraArt.label_y(kind, maxi(tier, 0))


## Taller tiers lift the label clear of the roof.
func _place_label(t: int) -> void:
	if _label == null:
		return
	_label.position.y = InfraArt.label_y(kind, t)
	if _badge:
		_badge.position.y = InfraArt.label_y(kind, t) + 0.7


func solid_rects() -> Array[Rect2]:
	var s := size_m()
	return [Rect2(-s.x * 0.5 + 0.1, -s.y * 0.5 + 0.1, s.x - 0.2, s.y - 1.4)]


func _visual(root: Node3D, t: int) -> void:
	var mesh: Mesh
	match kind:
		"gateway": mesh = MeshKit.cached("gateway_%d" % t, func(): return InfraArt.gateway(t))
		"edge": mesh = MeshKit.cached("edge_%d" % t, func(): return InfraArt.edge(t))
		"agent_hub": mesh = MeshKit.cached("agent_hub_%d" % t, func(): return InfraArt.agent_hub(t))
		_: mesh = MeshKit.cached("groundstation_%d" % t, func(): return InfraArt.groundstation(t))
	Mats.inst(mesh, root)
	_place_label(t)
	if kind == "gateway":
		_spools = Mats.inst(null, root)
		_show_spools()
	if kind == "agent_hub":
		_bots.clear()
		_bot_goal.clear()
		for i in 3 + t:
			var n := Node3D.new()
			root.add_child(n)
			Mats.inst(MeshKit.cached("agent_bot_%d" % (i % 3), func(): return InfraArt.agent_bot([Color(0.5, 0.86, 1.0), Color(0.6, 1.0, 0.7), Color(1.0, 0.8, 0.5)][i % 3])), n)
			n.position = Vector3(randf_range(-2.0, 2.0), 0.12, randf_range(0.0, 2.4))
			_bots.append(n)
			_bot_goal.append(n.position)


func _on_level() -> void:
	_show_spools()
	_update()


# ---------------------------------------------------------------- fiber (gateways)

func fiber() -> int:
	return int(data.get("fiber", 0))


func fiber_slots() -> int:
	return Bal.fiber_slots(level)


func _install_fiber(t: String) -> void:
	fiber_in.take(t)
	if fiber() < fiber_slots():
		data["fiber"] = fiber() + 1
	Game.track("installs")
	_show_spools()
	if is_inside_tree():
		UI3D.pop_text(get_tree().current_scene, to_world(-0.6, 1.15, 2.0), "+%s tok/s bandwidth" % Fmt.tokens(3.0), Color(0.98, 0.7, 0.9), 44)
	Sfx.play("upgrade", -8.0, 1.3)


func _show_spools() -> void:
	if _spools == null:
		return
	var n := mini(fiber(), 12)
	_spools.mesh = MeshKit.cached("spools_%d" % n, func():
		var k := MeshKit.new()
		var sm := InfraArt.spool()
		for i in n:
			k.add_mesh(sm, MeshKit.at(-1.3 + (i % 6) * 0.34, 0.61 + (i / 6) * 0.34, 1.15))
		return k.commit())
	if fiber_in:
		fiber_in.capacity = 1 if fiber() < fiber_slots() else 0


func need(t: String) -> float:
	if t == "fiber" and fiber_in and fiber_in.can_accept(t) and fiber_in.incoming == 0:
		return 0.9
	return 0.0


# ---------------------------------------------------------------- what it does

func bandwidth() -> float:
	return Bal.gateway_bw(level, fiber()) if kind == "gateway" else 0.0


func _process(dt: float) -> void:
	super(dt)
	for i in _bots.size():
		var n := _bots[i]
		var to := _bot_goal[i] - n.position
		to.y = 0
		if to.length() < 0.1:
			_bot_goal[i] = Vector3(randf_range(-2.2, 2.2), 0.12, randf_range(-0.2, 2.4)) if randf() < 0.7 else Vector3(-1.2 + (i % 3) * 1.2, 0.12, 2.0)
		else:
			n.position += to.normalized() * minf(to.length(), dt * 0.9)
			n.rotation.y = lerp_angle(n.rotation.y, atan2(to.x, to.z), dt * 6.0)
		n.position.y = 0.12 + absf(sin(_t * 6.0 + i)) * 0.03
	if int(_t) != int(_t - dt):
		_update()
	if kind == "gateway" and is_inside_tree() and world:
		_traffic(dt)


## API traffic you can see: request packets (cyan) arc from the gateway to
## the servers answering them, token streams (gold) fly back. More traffic,
## more packets.
func _traffic(dt: float) -> void:
	var share := Market.used_bw / maxf(0.0001, Market.bandwidth)
	if share <= 0.0:
		return
	_traffic_t -= dt
	if _traffic_t > 0.0 or _in_flight >= 14:
		return
	_traffic_t = lerpf(1.2, 0.18, clampf(share, 0.0, 1.0)) * randf_range(0.7, 1.3)
	var busy: Array = []
	for n in world.buildings_of("server"):
		if (n as ServerB).load_now > 0.05:
			busy.append(n)
	if busy.is_empty():
		return
	var s: ServerB = busy[randi() % busy.size()]
	var router := s.to_world(ServerB.ROUTER_X, ServerB.BUS_Z, 1.6)
	var dish := intake()
	_fly(dish, router, Color(0.45, 0.95, 1.0), false)
	var vent := s.to_world(ServerB.CORE_X, ServerB.BUS_Z, 3.2)
	_fly(vent, dish, Color(1.0, 0.85, 0.4), true)


func _fly(a: Vector3, b: Vector3, c: Color, token: bool) -> void:
	var n := MeshInstance3D.new()
	n.mesh = MeshKit.cached("traffic_%s" % ("tok" if token else "req"), func():
		var k := MeshKit.new()
		if token:
			k.cyl(0.3, 0.1, Color(1.0, 0.85, 0.4, 0.3), MeshKit.xf(Vector3.ZERO, Vector3(90, 0, 0)), 10)
		else:
			k.rbox(Vector3(0.5, 0.32, 0.5), 0.08, Color(0.45, 0.95, 1.0, 0.3), MeshKit.at(0, 0, 0))
		return k.commit())
	n.material_override = Mats.glow()
	n.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	get_tree().current_scene.add_child(n)
	n.global_position = a
	_in_flight += 1
	var top := maxf(a.y, b.y) + 2.0 + a.distance_to(b) * 0.15
	var dur := clampf(a.distance_to(b) / 9.0, 0.6, 2.4)
	var tw := n.create_tween()
	tw.tween_method(func(f: float):
		var p := a.lerp(b, f)
		p.y = lerpf(a.y, b.y, f) + (top - maxf(a.y, b.y)) * 4.0 * f * (1.0 - f)
		n.global_position = p
		n.rotation.y = f * TAU, 0.0, 1.0, dur).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func():
		_in_flight -= 1
		n.queue_free())


func _update() -> void:
	if _label == null:
		return
	match kind:
		"gateway":
			_label.text = "%s tok/s link" % Fmt.tokens(bandwidth())
		"edge":
			_label.text = "-%d ms" % int(Bal.EDGE_MS)
		"agent_hub":
			var a := Market.total(Market.by_channel.get("agent", {}))
			_label.text = "%s tok/s for agents" % Fmt.tokens(a)
		_:
			_label.text = "%s tok/s downlink" % Fmt.tokens(Bal.ground_bw(level))


func status() -> String:
	match kind:
		"gateway":
			return "Brings developers' calls (+%d%% customers) and carries %s tok/s" % [roundi(Bal.gateway_demand(level) * 100), Fmt.tokens(bandwidth())]
		"edge":
			return "Every model answers %d ms sooner; +%d%% customers" % [int(Bal.EDGE_MS), roundi(Bal.edge_demand(level) * 100)]
		"agent_hub":
			return "Agents pay double on tool-capable models (Tool 30B and up)"
	return "Downlinks %s tok/s from orbit" % Fmt.tokens(Bal.ground_bw(level))


func info() -> Array:
	match kind:
		"gateway":
			return [
				["gateway", "Customers: +%d%% for every model" % roundi(Bal.gateway_demand(level) * 100)],
				["fiber", "Bandwidth %s tok/s  ·  fiber %d / %d" % [Fmt.tokens(bandwidth()), fiber(), fiber_slots()]],
				["speed", "All gateways: %s of %s tok/s in use" % [Fmt.tokens(Market.used_bw), Fmt.tokens(Market.bandwidth)]],
			]
		"edge":
			return [["clock", "%d ms less latency for every model" % int(Bal.EDGE_MS)], ["gateway", "+%d%% customers" % roundi(Bal.edge_demand(level) * 100)]]
		"agent_hub":
			return [["agent", "Agent demand x%.2f on tool-capable models" % Bal.hub_demand(level)], ["coin", "Agents pay x%.0f per token" % Bal.AGENT_PRICE]]
	return [["groundstation", "Downlink %s tok/s" % Fmt.tokens(Bal.ground_bw(level))], ["launchpad", "%d modules in orbit" % Market.orbit_modules]]


func upgrade_info() -> Array:
	var n := level + 1
	match kind:
		"gateway":
			return [["Customers", "+%d%%" % roundi(Bal.gateway_demand(level) * 100), "+%d%%" % roundi(Bal.gateway_demand(n) * 100)],
				["Bandwidth", Fmt.tokens(Bal.gateway_bw(level, fiber())), Fmt.tokens(Bal.gateway_bw(n, fiber()))],
				["Fiber slots", str(fiber_slots()), str(Bal.fiber_slots(n))]]
		"edge":
			return [["Customers", "+%d%%" % roundi(Bal.edge_demand(level) * 100), "+%d%%" % roundi(Bal.edge_demand(n) * 100)]]
		"agent_hub":
			return [["Agent demand", "x%.2f" % Bal.hub_demand(level), "x%.2f" % Bal.hub_demand(n)]]
	return [["Downlink", Fmt.tokens(Bal.ground_bw(level)), Fmt.tokens(Bal.ground_bw(n))]]


func save_contents() -> Dictionary:
	return {}


## Where request packets drop in from the sky (world): the dish.
func intake() -> Vector3:
	if kind == "gateway" or kind == "edge":
		var p := InfraArt.intake(kind, maxi(tier, 0))
		return to_world(p.x, p.z, p.y)
	return global_position + Vector3(0, 3, 0)
