class_name OrbitView
extends Node3D
## The orbital datacenter, drawn in the sky over the Launch Complex: a truss
## with one server module per launch (solar wings out), turning slowly, its
## lights blinking, and a downlink beam to each Ground Station that pulses
## with the traffic it carries.

const HEIGHT := 9.0
const BACK := -3.0

var world
var _station: Node3D
var _shown := -1
var _beams: Array[MeshInstance3D] = []
var _beam_mat: StandardMaterial3D
var _t := 0.0


func _ready() -> void:
	_station = Node3D.new()
	add_child(_station)
	_beam_mat = StandardMaterial3D.new()
	_beam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_mat.albedo_color = Color(0.55, 0.95, 1.0, 0.25)
	_beam_mat.cull_mode = BaseMaterial3D.CULL_DISABLED


func _anchor() -> Vector3:
	var pads: Array = world.buildings_of("launchpad")
	if not pads.is_empty():
		return (pads[0] as Node3D).global_position
	return Vector3(0, 0, -24)


func _process(dt: float) -> void:
	_t += dt
	var n := Market.orbit_modules
	visible = n > 0
	if not visible:
		return
	if n != _shown:
		_rebuild(n)
	position = _anchor() + Vector3(0, HEIGHT + sin(_t * 0.4) * 0.3, BACK)
	_station.rotation.y = _t * 0.05
	_station.rotation.z = sin(_t * 0.2) * 0.05
	# downlink beams, one per ground station, pulsing with the traffic
	var gs: Array = world.buildings_of("groundstation")
	while _beams.size() < gs.size():
		var b := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.08
		cm.bottom_radius = 0.35
		cm.height = 1.0
		cm.radial_segments = 10
		b.mesh = cm
		b.material_override = _beam_mat
		b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(b)
		_beams.append(b)
	var load := Market.orbit_capacity() / maxf(0.001, Market.downlink())
	for i in _beams.size():
		var b2 := _beams[i]
		b2.visible = i < gs.size() and load > 0.0
		if not b2.visible:
			continue
		var to: Vector3 = (gs[i] as Node3D).global_position + Vector3(0, 1.2, 0) - global_position
		b2.position = to * 0.5
		var len := to.length()
		b2.basis = Basis(Quaternion(Vector3.DOWN, to.normalized())) * Basis.from_scale(Vector3(1, len, 1))
	_beam_mat.albedo_color.a = 0.12 + 0.18 * clampf(load, 0.0, 1.0) * (0.6 + 0.4 * sin(_t * 6.0))


func _rebuild(n: int) -> void:
	_shown = n
	for c in _station.get_children():
		c.queue_free()
	var shown := mini(n, 16)
	Mats.inst(MeshKit.cached("orbit_spine_%d" % shown, func(): return InfraArt.orbit_spine(shown)), _station)
	var len := maxf(4.0, shown * 1.6 + 2.0)
	var mm := MeshKit.cached("orbit_module", InfraArt.orbit_module)
	for i in shown:
		var x := -len * 0.5 + 1.4 + (i / 2) * 3.2
		var side := 1.0 if i % 2 == 0 else -1.0
		Mats.inst(mm, _station, MeshKit.xf(Vector3(x, side * 0.9, 0), Vector3(0, 0, 0 if side > 0 else 180)))
	# a ring of beacon lights
	var k := MeshKit.new()
	for i in 6:
		var a := TAU * i / 6.0
		k.sphere(0.12, Color(1.0, 0.4, 0.35, 0.3) if i % 2 else Color(0.5, 1.0, 0.6, 0.3), MeshKit.at(cos(a) * 1.1, 0, sin(a) * 1.1), 6, 4)
	var lights := Mats.inst(k.commit(), _station, Transform3D.IDENTITY, false)
	lights.material_override = Mats.glow()
	_station.scale = Vector3.ONE * 1.35
