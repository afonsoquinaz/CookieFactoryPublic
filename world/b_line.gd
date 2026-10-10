class_name LineModule
extends Building
## A piece of a production line: Mixer, Glass Tube, Hopper or Oven. All of
## them carry the square glass tube along their back half, at the same height,
## running along their local +X. Modules with the same rotation that touch end
## to end connect; a line is Mixer -> (tubes / hoppers) -> Oven.

const TUBE_Y := 1.25
const TUBE_Z := -1.0
const PAD_Z := 1.05

var line: Line                 # set by World.rebuild_lines()
var linked_prev := false
var linked_next := false
var _cap_prev: Node3D
var _cap_next: Node3D


## Tube end points in world space.
func tube_start() -> Vector3:
	return to_world(-size_m().x * 0.5, TUBE_Z, TUBE_Y)


func tube_end() -> Vector3:
	return to_world(size_m().x * 0.5, TUBE_Z, TUBE_Y)


func flow_dir() -> Vector3:
	return base_xf().basis.x


func solid_rects() -> Array[Rect2]:
	var s := size_m()
	return [Rect2(-s.x * 0.5, -2.0, s.x, 1.85)]


## Tube segment + frame for this module's width.
func _tube(root: Node3D, len: float) -> void:
	Mats.inst(MeshKit.cached("tubeframe_%d" % int(len * 10), func(): return LineArt.frame(len)), root, MeshKit.at(0, 0, TUBE_Z))
	var glass := MeshInstance3D.new()
	glass.mesh = MeshKit.cached("tubeglass_%d" % int(len * 10), func():
		var k := MeshKit.new()
		k.rbox(Vector3(len, 0.94, 1.06), 0.04, Color(1, 1, 1), MeshKit.at(0, TUBE_Y, 0), 1)
		return k.commit())
	glass.material_override = Mats.glass()
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	glass.position.z = TUBE_Z
	root.add_child(glass)
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(len, 0.03, 0.82)
	belt.mesh = bm
	belt.position = Vector3(0, TUBE_Y - 0.44, TUBE_Z)
	belt.material_override = LineArt.belt_material()
	root.add_child(belt)
	# end caps (shown where nothing connects)
	_cap_prev = Mats.inst(MeshKit.cached("tubecap", LineArt.cap), root, MeshKit.xf(Vector3(-len * 0.5, 0, TUBE_Z), Vector3(0, 180, 0)))
	_cap_next = Mats.inst(MeshKit.cached("tubecap", LineArt.cap), root, MeshKit.at(len * 0.5, 0, TUBE_Z))
	set_links(linked_prev, linked_next)


func set_links(prev_ok: bool, next_ok: bool) -> void:
	linked_prev = prev_ok
	linked_next = next_ok
	if _cap_prev and is_instance_valid(_cap_prev):
		_cap_prev.visible = not prev_ok
	if _cap_next and is_instance_valid(_cap_next):
		_cap_next.visible = not next_ok
	_on_links()


func _on_links() -> void:
	pass
