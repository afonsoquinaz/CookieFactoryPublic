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
var _bots: Array[Node3D] = []
var _bot_goal: Array[Vector3] = []
var _beacon_t := 0.0


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
	var b := UI3D.badge(def["icon"], Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, _label_y() + 0.7, 0.0)
	add_child(b)


func _label_y() -> float:
	match kind:
		"gateway": return 4.4
		"edge": return 4.0
		"agent_hub": return 4.8
	return 3.6


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
	match kind:
		"gateway": return to_world(-0.9, -2.0, 3.6)
		"edge": return to_world(2.2, -1.8, 4.5)
	return global_position + Vector3(0, 3, 0)
