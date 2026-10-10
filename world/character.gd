class_name Character
extends Node3D
## A cute toy-built person (chunky DEADGRID-style proportions: big rounded
## head, tapered torso, two-segment limbs, mitt hands, boots, ink outline) but
## dressed for the job: a real face with eyes, brows and cheeks, hair, and a
## work outfit per role (farmer in plaid + denim overalls + straw hat,
## gatherer in a field vest, feeder in hi-vis + hard hat, collector in chef
## whites, loader in a work jacket + beanie; you are the baker).
##
## Animation inputs:
##   move_speed  0..1 walk blend      carrying   arms forward holding a stack
##   work        "", "hoe", "pick", "milk", "scoop", "cheer", "sit", "push"

const HEAD_Y := 1.3

var look := "player"
var skin := Color(0.96, 0.8, 0.66)
var hair := Color(0.3, 0.2, 0.14)
var shirt := Color(0.95, 0.93, 0.88)
var pants := Color(0.3, 0.3, 0.32)
var boots := Color(0.34, 0.24, 0.18)
var hands := Color(0.96, 0.8, 0.66)
var outfit := ""            # overalls | vest | hivis | chef | jacket | apron | ""
var outfit_col := Color(0.4, 0.5, 0.7)
var move_speed := 0.0
var carrying := false
var work := ""

var body: Node3D           # the whole figure (bob / squash)
var upper: Node3D          # torso + head + arms (lean / roll)
var head: Node3D
var eyes: Node3D
var arm_l: Node3D
var arm_r: Node3D
var elbow_l: Node3D
var elbow_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var knee_l: Node3D
var knee_r: Node3D
var hand_r: Node3D
var carry_mount: Node3D
var back_mount: Node3D
var tool_node: Node3D
var _phase := 0.0
var _t := 0.0
var _squash := 0.0
var _blink := 2.0

## hat + tool per look
const LOOKS := {
	"farmer": ["straw", "hoe"], "gatherer": ["cap", "basket"], "feeder": ["hardhat", "scoop"],
	"collector": ["bandana", "tray"], "loader": ["redcap", "dolly"], "chef": ["chef", "whisk"],
	"customer": ["none", ""], "player": ["baker", ""], "builder": ["hardhat", "hammer"],
}
const CASUAL := [Color(0.42, 0.55, 0.68), Color(0.78, 0.5, 0.42), Color(0.55, 0.62, 0.45), Color(0.86, 0.76, 0.5),
	Color(0.62, 0.48, 0.62), Color(0.92, 0.9, 0.84), Color(0.36, 0.42, 0.5), Color(0.82, 0.62, 0.62)]

const SKINS := [Color(0.98, 0.84, 0.72), Color(0.92, 0.74, 0.6), Color(0.78, 0.58, 0.44), Color(0.6, 0.42, 0.31)]
const HAIRS := [Color(0.3, 0.2, 0.14), Color(0.16, 0.13, 0.12), Color(0.82, 0.62, 0.34), Color(0.6, 0.32, 0.2), Color(0.5, 0.42, 0.36)]


func setup(p_look: String, p_seed := 0) -> void:
	look = p_look
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed * 7919 + 17
	_t = rng.randf() * 10.0
	skin = SKINS[rng.randi() % SKINS.size()]
	hair = HAIRS[rng.randi() % HAIRS.size()]
	hands = skin
	match look:
		"player":
			skin = SKINS[0]
			hands = skin
			hair = Color(0.36, 0.22, 0.15)
			shirt = Color(0.96, 0.94, 0.9)
			pants = Color(0.3, 0.26, 0.24)
			outfit = "apron"
			outfit_col = Color(0.45, 0.28, 0.19)
		"farmer":
			shirt = Color(0.72, 0.3, 0.26)          # red plaid shirt
			outfit = "overalls"
			outfit_col = Color(0.33, 0.45, 0.66)    # denim
			pants = outfit_col
			hands = Color(0.55, 0.42, 0.3)
		"gatherer":
			shirt = Color(0.86, 0.84, 0.74)
			outfit = "vest"
			outfit_col = Color(0.44, 0.52, 0.34)    # field vest
			pants = Color(0.52, 0.44, 0.34)
		"builder":
			shirt = Color(0.86, 0.82, 0.74)
			outfit = "overalls"
			outfit_col = Color(0.88, 0.56, 0.24)    # orange work overalls
			pants = outfit_col
			hands = Color(0.62, 0.5, 0.36)
		"feeder":
			shirt = Color(0.56, 0.6, 0.66)
			outfit = "hivis"
			outfit_col = Color(0.96, 0.6, 0.22)
			pants = Color(0.26, 0.29, 0.34)
			hands = Color(0.9, 0.78, 0.36)
		"chef":
			shirt = Color(0.98, 0.98, 0.97)
			outfit = "chef"
			outfit_col = Color(0.98, 0.98, 0.97)
			pants = Color(0.3, 0.3, 0.32)
			boots = Color(0.92, 0.92, 0.9)
		"collector":
			shirt = Color(0.95, 0.92, 0.86)
			outfit = "apron"
			outfit_col = Color(0.62, 0.44, 0.58)    # pastry apron, mauve
			pants = Color(0.32, 0.3, 0.34)
		"customer":
			shirt = CASUAL[rng.randi() % CASUAL.size()]
			pants = [Color(0.3, 0.34, 0.44), Color(0.52, 0.46, 0.38), Color(0.24, 0.24, 0.26), Color(0.6, 0.56, 0.5)][rng.randi() % 4]
			outfit = "jacket" if rng.randf() < 0.35 else ""
			outfit_col = CASUAL[rng.randi() % CASUAL.size()].darkened(0.15)
			boots = [Color(0.34, 0.24, 0.18), Color(0.86, 0.84, 0.8), Color(0.2, 0.2, 0.22)][rng.randi() % 3]
		"loader":
			shirt = Color(0.88, 0.86, 0.8)
			outfit = "jacket"
			outfit_col = Color(0.28, 0.34, 0.46)
			pants = Color(0.24, 0.26, 0.3)
			hands = Color(0.5, 0.38, 0.28)
		_:
			shirt = Color(0.8, 0.79, 0.76)
			pants = Color(0.45, 0.45, 0.47)
	for c in get_children():
		c.queue_free()
	_build()


func _part(mesh: Mesh, parent: Node3D, pos := Vector3.ZERO, ink := true, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = Mats.inked() if ink else Mats.toon()
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


func _build() -> void:
	var key := "%s_%s_%s_%s" % [look, skin.to_html(), hair.to_html(), shirt.to_html()]
	body = Node3D.new()
	add_child(body)
	upper = Node3D.new()
	body.add_child(upper)
	_part(MeshKit.cached("ch_torso_" + key, _torso_mesh), upper, Vector3(0, 0.8, 0))
	head = Node3D.new()
	head.position = Vector3(0, HEAD_Y, 0)
	upper.add_child(head)
	_part(MeshKit.cached("ch_head_" + key, _head_mesh), head)
	eyes = Node3D.new()
	eyes.position = Vector3(0, -0.02, 0.245)
	head.add_child(eyes)
	_part(MeshKit.cached("ch_eyes", func():
		var k := MeshKit.new()
		for sd in [-1.0, 1.0]:
			k.rbox(Vector3(0.07, 0.1, 0.03), 0.03, Color(0.12, 0.09, 0.08), MeshKit.at(sd * 0.1, 0, 0))
			k.sphere(0.016, Color(1, 1, 1), MeshKit.at(sd * 0.1 + 0.015, 0.025, 0.016), 5, 3)
		return k.commit()), eyes, Vector3.ZERO, false, false)
	var hat := _hat_mesh()
	if hat:
		_part(hat, head, Vector3.ZERO, true, false)
	var arm_upper := MeshKit.cached("ch_armu_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.14, 0.2, 0.15), 0.03, _sleeve(), MeshKit.at(0, -0.1, 0))
		return k.shade_figure(1.05).commit())
	var arm_lower := MeshKit.cached("ch_arml_" + key, func():
		var k := MeshKit.new()
		var fore := skin if (look == "farmer" or look == "player" or look == "gatherer") else _sleeve()
		k.rbox(Vector3(0.11, 0.2, 0.12), 0.03, fore, MeshKit.at(0, -0.1, 0))
		k.rbox(Vector3(0.18, 0.18, 0.18), 0.07, hands, MeshKit.at(0, -0.27, 0))
		return k.shade_figure(0.85).commit())
	var leg_upper := MeshKit.cached("ch_legu_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.19, 0.22, 0.23), 0.03, pants, MeshKit.at(0, -0.11, 0))
		return k.shade_figure(0.52).commit())
	var leg_lower := MeshKit.cached("ch_legl_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.15, 0.19, 0.18), 0.03, pants, MeshKit.at(0, -0.095, 0))
		k.rbox(Vector3(0.22, 0.14, 0.32), 0.055, boots, MeshKit.at(0, -0.21, 0.04))
		return k.shade_figure(0.3).commit())
	arm_l = _limb(upper, Vector3(-0.27, 1.05, 0), arm_upper, arm_lower, 0.2)
	arm_r = _limb(upper, Vector3(0.27, 1.05, 0), arm_upper, arm_lower, 0.2)
	leg_l = _limb(body, Vector3(-0.13, 0.52, 0), leg_upper, leg_lower, 0.22)
	leg_r = _limb(body, Vector3(0.13, 0.52, 0), leg_upper, leg_lower, 0.22)
	elbow_l = arm_l.get_child(1)
	elbow_r = arm_r.get_child(1)
	knee_l = leg_l.get_child(1)
	knee_r = leg_r.get_child(1)
	hand_r = Node3D.new()
	hand_r.position = Vector3(0, -0.28, 0)
	elbow_r.add_child(hand_r)
	carry_mount = Node3D.new()
	# the stack rests on the hands held out in front of the chest
	carry_mount.position = Vector3(0, 0.84, 0.44)
	body.add_child(carry_mount)
	back_mount = Node3D.new()
	back_mount.position = Vector3(0, 0.9, -0.22)
	upper.add_child(back_mount)
	_build_tool()


func _sleeve() -> Color:
	match outfit:
		"chef": return outfit_col
		"jacket": return outfit_col
		"hivis": return shirt
	return shirt


func _torso_mesh() -> Mesh:
	var k := MeshKit.new()
	var base := shirt
	if outfit == "jacket" or outfit == "chef":
		base = outfit_col
	k.rbox(Vector3(0.42, 0.54, 0.34), 0.04, base)
	k.taper(func(y: float) -> Vector2:
		var t := clampf((y + 0.27) / 0.54, 0.0, 1.0)
		return Vector2(0.86 + 0.14 * t * t * (3.0 - 2.0 * t), 1.0))
	match outfit:
		"overalls":
			# plaid lines on the shirt, denim bib + straps + brass buttons
			for i in 3:
				k.rbox(Vector3(0.43, 0.025, 0.345), 0.01, shirt.darkened(0.25), MeshKit.at(0, 0.18 - i * 0.1, 0))
			k.rbox(Vector3(0.3, 0.26, 0.03), 0.02, outfit_col, MeshKit.at(0, -0.05, 0.172))
			k.rbox(Vector3(0.4, 0.14, 0.355), 0.02, outfit_col, MeshKit.at(0, -0.21, 0))
			for sd in [-1.0, 1.0]:
				k.rbox(Vector3(0.055, 0.3, 0.02), 0.01, outfit_col, MeshKit.xf(Vector3(sd * 0.11, 0.12, 0.17), Vector3(0, 0, sd * 8)))
				k.sphere(0.022, Pal.BRASS, MeshKit.at(sd * 0.1, 0.06, 0.19), 6, 4)
		"vest":
			for sd in [-1.0, 1.0]:
				k.rbox(Vector3(0.15, 0.48, 0.36), 0.03, outfit_col, MeshKit.at(sd * 0.13, -0.01, 0))
			k.rbox(Vector3(0.08, 0.06, 0.02), 0.01, outfit_col.darkened(0.2), MeshKit.at(-0.12, -0.08, 0.185))
		"hivis":
			k.rbox(Vector3(0.43, 0.42, 0.35), 0.03, outfit_col, MeshKit.at(0, -0.04, 0))
			for yy in [-0.12, 0.06]:
				k.rbox(Vector3(0.44, 0.035, 0.36), 0.01, Color(0.92, 0.92, 0.88), MeshKit.at(0, yy, 0))
		"chef":
			for i in 3:
				for sd in [-1.0, 1.0]:
					k.sphere(0.02, Color(0.75, 0.75, 0.78), MeshKit.at(sd * 0.06, 0.12 - i * 0.1, 0.175), 6, 4)
			k.ellipsoid(Vector3(0.12, 0.05, 0.08), Color(0.78, 0.32, 0.27), MeshKit.at(0, 0.27, 0.12), 8, 4)
		"jacket":
			k.rbox(Vector3(0.025, 0.5, 0.02), 0.01, outfit_col.darkened(0.25), MeshKit.at(0, -0.01, 0.172))
			k.rbox(Vector3(0.43, 0.06, 0.35), 0.02, outfit_col.darkened(0.15), MeshKit.at(0, 0.25, 0))
			k.ellipsoid(Vector3(0.16, 0.06, 0.13), Color(0.74, 0.36, 0.28), MeshKit.at(0, 0.27, 0.04), 8, 4)
		"apron":
			k.rbox(Vector3(0.3, 0.44, 0.03), 0.015, outfit_col, MeshKit.at(0, -0.06, 0.172))
			k.rbox(Vector3(0.36, 0.05, 0.355), 0.015, outfit_col.darkened(0.12), MeshKit.at(0, -0.12, 0))
			k.rbox(Vector3(0.12, 0.05, 0.03), 0.01, Color(0.86, 0.7, 0.42), MeshKit.at(0, 0.24, 0.17))
	k.shade_figure(0.8)
	return k.commit()


func _head_mesh() -> Mesh:
	var k := MeshKit.new()
	k.rbox(Vector3(0.5, 0.48, 0.46), 0.12, skin, Transform3D.IDENTITY, 2)
	k.taper(func(y: float) -> Vector2:
		var t := clampf((y + 0.24) / 0.2, 0.0, 1.0)
		return Vector2(0.92 + 0.08 * t * t * (3.0 - 2.0 * t), 1.0))
	# cheeks, a small nose, a smile
	for sd in [-1.0, 1.0]:
		k.ellipsoid(Vector3(0.045, 0.028, 0.015), Color(0.95, 0.6, 0.55), MeshKit.at(sd * 0.155, -0.085, 0.226), 8, 4)
		# brows
		k.rbox(Vector3(0.08, 0.022, 0.02), 0.008, hair.darkened(0.15), MeshKit.xf(Vector3(sd * 0.1, 0.075, 0.232), Vector3(0, 0, -sd * 8)))
	k.ellipsoid(Vector3(0.03, 0.025, 0.025), skin.darkened(0.08), MeshKit.at(0, -0.06, 0.235), 6, 4)
	k.torus(0.035, 0.009, Color(0.42, 0.2, 0.17), MeshKit.xf(Vector3(0, -0.125, 0.228), Vector3(90 - 15, 0, 0)), 8, 4, PI)
	# hair: a block cap on top and back with a side-swept fringe
	k.rbox(Vector3(0.53, 0.16, 0.49), 0.07, hair, MeshKit.at(0, 0.2, -0.01))
	k.rbox(Vector3(0.53, 0.32, 0.12), 0.05, hair, MeshKit.at(0, 0.08, -0.2))
	k.rbox(Vector3(0.3, 0.09, 0.1), 0.035, hair, MeshKit.xf(Vector3(-0.08, 0.15, 0.2), Vector3(0, 0, 10)))
	for sd in [-1.0, 1.0]:
		k.rbox(Vector3(0.06, 0.22, 0.32), 0.03, hair, MeshKit.at(sd * 0.25, 0.08, -0.05))
		# ears
		k.ellipsoid(Vector3(0.03, 0.06, 0.05), skin.darkened(0.04), MeshKit.at(sd * 0.255, -0.03, 0.02), 6, 4)
	if look == "player":
		k.sphere(0.09, hair, MeshKit.at(0, 0.2, -0.24), 10, 6)
	k.shade_figure(HEAD_Y)
	return k.commit()


## Two-segment limb: upper mesh on the root, lower mesh on a hidden joint.
func _limb(parent: Node3D, pos: Vector3, upper_mesh: Mesh, lower_mesh: Mesh, upper_h: float) -> Node3D:
	var root := Node3D.new()
	root.position = pos
	parent.add_child(root)
	_part(upper_mesh, root, Vector3.ZERO, true, false)
	var joint := Node3D.new()
	joint.position = Vector3(0, -upper_h, 0)
	root.add_child(joint)
	_part(lower_mesh, joint, Vector3.ZERO, true, false)
	return root


func _hat_mesh() -> Mesh:
	var hat: String = LOOKS[look][0] if LOOKS.has(look) else "none"
	return MeshKit.cached("dg_hat_" + hat, func(): return Character.build_hat(hat))


## Hats sit on the 0.56-wide head (top at y = +0.26 in head space).
static func build_hat(hat: String) -> Mesh:
	var k := MeshKit.new()
	match hat:
		"straw":
			var straw := Color(0.95, 0.82, 0.52)
			k.cyl(0.44, 0.035, straw, MeshKit.at(0, 0.18, 0), 20, 0.012)
			k.cyl(0.26, 0.17, straw, MeshKit.at(0, 0.2, 0), 18, 0.04, 0.22)
			k.cyl(0.265, 0.05, Color(0.72, 0.3, 0.26), MeshKit.at(0, 0.21, 0), 18, 0.01)
		"cap":
			var c := Color(0.42, 0.5, 0.34)
			k.rbox(Vector3(0.54, 0.14, 0.5), 0.06, c, MeshKit.at(0, 0.27, -0.01))
			k.rbox(Vector3(0.44, 0.035, 0.22), 0.015, c.darkened(0.15), MeshKit.at(0, 0.22, 0.3))
		"redcap":
			# knitted beanie with a turned-up cuff and a bobble
			var r := Color(0.74, 0.34, 0.27)
			k.rbox(Vector3(0.55, 0.2, 0.51), 0.09, r, MeshKit.at(0, 0.27, -0.01))
			k.rbox(Vector3(0.57, 0.07, 0.53), 0.03, r.darkened(0.12), MeshKit.at(0, 0.18, -0.01))
			k.sphere(0.07, Color(0.95, 0.92, 0.86), MeshKit.at(0, 0.41, 0), 8, 5)
		"hardhat":
			var o := Color(0.97, 0.78, 0.26)
			k.ellipsoid(Vector3(0.29, 0.17, 0.28), o, MeshKit.at(0, 0.24, 0), 16, 8)
			k.cyl(0.33, 0.03, o.darkened(0.08), MeshKit.at(0, 0.23, 0.02), 18)
			k.rbox(Vector3(0.06, 0.06, 0.46), 0.02, o.lightened(0.15), MeshKit.at(0, 0.4, 0))
		"chef":
			var w := Color(0.98, 0.98, 0.97)
			k.cyl(0.25, 0.2, w, MeshKit.at(0, 0.22, 0), 16, 0.03, 0.27)
			k.ellipsoid(Vector3(0.31, 0.13, 0.31), w, MeshKit.at(0, 0.48, 0), 16, 7)
		"bandana":
			var m := Color(0.62, 0.44, 0.58)
			k.ellipsoid(Vector3(0.29, 0.12, 0.28), m, MeshKit.at(0, 0.2, -0.02), 14, 6)
			k.ellipsoid(Vector3(0.08, 0.05, 0.12), m.darkened(0.12), MeshKit.xf(Vector3(0, 0.1, -0.29), Vector3(30, 0, 0)), 8, 4)
		"baker":
			# the founder's soft baker's beret
			var b := Color(0.45, 0.28, 0.19)
			k.ellipsoid(Vector3(0.3, 0.09, 0.28), b, MeshKit.xf(Vector3(0.03, 0.29, -0.02), Vector3(0, 0, -8)), 16, 6)
			k.sphere(0.035, b.darkened(0.2), MeshKit.at(0.03, 0.38, -0.02), 6, 4)
		_:
			return null
	return k.commit()


func _build_tool() -> void:
	if not LOOKS.has(look) or LOOKS[look][1] == "":
		return
	var tool: String = LOOKS[look][1]
	var mesh := MeshKit.cached("dg_tool_" + tool, func(): return Character.build_tool(tool))
	match tool:
		"basket":
			tool_node = _part(mesh, back_mount, Vector3.ZERO, true, false)
		"dolly":
			tool_node = _part(mesh, body, Vector3(0, 0, 0.5), true, false)
		_:
			tool_node = _part(mesh, hand_r, Vector3.ZERO, true, false)


static func build_tool(tool: String) -> Mesh:
	var k := MeshKit.new()
	match tool:
		"hoe":
			k.cyl(0.025, 0.95, Pal.WOOD, MeshKit.at(0, -0.4, 0.02), 6)
			k.rbox(Vector3(0.16, 0.04, 0.18), 0.015, Pal.STEEL, MeshKit.xf(Vector3(0, 0.55, 0.09), Vector3(-20, 0, 0)))
		"basket":
			var b := Color(0.72, 0.56, 0.36)
			k.cyl(0.2, 0.3, b, MeshKit.at(0, -0.18, -0.05), 12, 0.03, 0.23)
			k.torus(0.23, 0.02, b.darkened(0.15), MeshKit.at(0, 0.12, -0.05), 14, 4)
		"scoop":
			k.cyl(0.02, 0.28, Pal.WOOD_DARK, MeshKit.xf(Vector3(0, 0, 0), Vector3(90, 0, 0)), 6)
			k.rbox(Vector3(0.2, 0.08, 0.24), 0.04, Pal.STEEL, MeshKit.at(0, 0.0, 0.36))
		"tray":
			k.rbox(Vector3(0.46, 0.025, 0.32), 0.01, Pal.STEEL_DARK, MeshKit.at(0, -0.01, 0.16))
			for x in [-0.13, 0.0, 0.13]:
				Items.cookie_into(k, "choc", 0.055, 0.03, MeshKit.at(x, 0.005, 0.16))
		"hammer":
			k.cyl(0.025, 0.36, Pal.WOOD, MeshKit.at(0, -0.12, 0.02), 6)
			k.rbox(Vector3(0.08, 0.08, 0.2), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 0.24, 0.06))
		"whisk":
			k.cyl(0.022, 0.2, Pal.WOOD, MeshKit.at(0, -0.05, 0.02), 6)
			for i in 4:
				k.torus(0.05, 0.008, Pal.STEEL, MeshKit.xf(Vector3(0, 0.2, 0.02), Vector3(0, i * 45, 0), Vector3(1, 1.8, 1)), 10, 3)
		"dolly":
			var r := Pal.STEEL_DARK
			for sx in [-0.2, 0.2]:
				k.rbox(Vector3(0.04, 0.95, 0.04), 0.012, r, MeshKit.xf(Vector3(sx, 0.48, 0.0), Vector3(-10, 0, 0)))
				k.cyl(0.09, 0.05, Pal.RUBBER, MeshKit.xf(Vector3(sx + signf(sx) * 0.03, 0.09, 0.1), Vector3(0, 0, 90)), 10, 0.015)
			k.rbox(Vector3(0.46, 0.03, 0.24), 0.01, Pal.STEEL, MeshKit.at(0, 0.03, 0.11))
			k.rbox(Vector3(0.46, 0.04, 0.04), 0.012, r, MeshKit.at(0, 0.95, -0.16))
	return k.commit()


# ---------------------------------------------------------------- animation

func squash(amount := 1.0) -> void:
	_squash = maxf(_squash, amount)


func _process(dt: float) -> void:
	if body == null:
		return
	_t += dt
	var walk := clampf(move_speed, 0.0, 1.0)
	var moving := walk > 0.05
	_phase += dt * (3.0 + walk * 9.0)
	var s := sin(_phase)
	var swing := s if moving else sin(_phase * 0.3) * 0.1
	var amp := 0.7 if moving else 0.9
	_squash = move_toward(_squash, 0.0, dt * 5.0)
	var sq := sin(_squash * PI) * 0.1 * _squash
	var breathe := sin(_phase * 0.55) * 0.012
	body.scale = Vector3(1.0 + sq * 0.6, 1.0 - sq, 1.0 + sq * 0.6)
	body.position.y = absf(s) * 0.04 * walk
	# upper body roll + lean, head counter-roll and nod (DEADGRID poseLimbs)
	var roll := s * 0.08 if moving else 0.0
	upper.rotation = Vector3(0.08 * walk if moving else breathe, 0, roll)
	upper.position.y = 0.0 if moving else breathe * 0.5
	head.rotation = Vector3(absf(s) * 0.07 if moving else -breathe * 0.6, 0, -roll * 0.6)
	leg_l.rotation = Vector3(swing * amp, 0, s * 0.06 if moving else 0.0)
	leg_r.rotation = Vector3(-swing * amp, 0, -s * 0.06 if moving else 0.0)
	var lift_l := maxf(0.0, s) if moving else 0.0
	var lift_r := maxf(0.0, -s) if moving else 0.0
	knee_l.rotation.x = -lift_l * 0.62 + lift_r * 0.12
	knee_r.rotation.x = -lift_r * 0.62 + lift_l * 0.12
	var al := -swing * 0.72 * amp
	var ar := swing * 0.72 * amp
	var el := lift_r * 0.42 + lift_l * 0.1
	var er := lift_l * 0.42 + lift_r * 0.1
	var alz := -0.05 + (s * 0.1 if moving else 0.0)
	var arz := 0.05 - (s * 0.1 if moving else 0.0)
	if carrying:
		# forearms forward and level under the stack
		al = -0.55 + s * 0.03 * walk
		ar = al
		el = -0.95
		er = -0.95
		alz = -0.14
		arz = 0.14
	match work:
		"hoe":
			var w := sin(_t * 6.0)
			ar = -1.5 - w * 0.7
			al = ar
			el = -0.3
			er = -0.3
			upper.rotation.x = 0.15 + maxf(0.0, -w) * 0.15
		"pick":
			ar = -2.5 + sin(_t * 5.0) * 0.35
			al = -2.5 - sin(_t * 5.0) * 0.35
			el = -0.2
			er = -0.2
			head.rotation.x = -0.2
		"milk":
			body.position.y = -0.22
			leg_l.rotation.x = -1.2
			leg_r.rotation.x = -1.2
			knee_l.rotation.x = 1.6
			knee_r.rotation.x = 1.6
			ar = -1.0 + sin(_t * 9.0) * 0.3
			al = -1.0 - sin(_t * 9.0) * 0.3
			upper.rotation.x = 0.3
		"scoop":
			var w2 := sin(_t * 4.5)
			ar = -1.0 - w2 * 0.5
			al = ar
			el = -0.5
			er = -0.5
		"cheer":
			ar = -2.8 + sin(_t * 10.0) * 0.2
			al = -2.8 - sin(_t * 10.0) * 0.2
			arz = 0.3
			alz = -0.3
			body.position.y = absf(sin(_t * 6.0)) * 0.08
		"sit":
			body.position.y = -0.28
			leg_l.rotation.x = -1.5
			leg_r.rotation.x = -1.5
			knee_l.rotation.x = 1.5
			knee_r.rotation.x = 1.5
			ar = -0.4
			al = -0.4
			el = -0.5
			er = -0.5
			head.rotation.x = 0.12 + sin(_t * 0.8) * 0.05
		"push":
			ar = -0.9
			al = -0.9
			el = -0.4
			er = -0.4
	arm_l.rotation = Vector3(al, 0, alz)
	arm_r.rotation = Vector3(ar, 0, arz)
	elbow_l.rotation.x = el
	elbow_r.rotation.x = er
	if tool_node and LOOKS.has(look) and LOOKS[look][1] == "dolly":
		tool_node.rotation.x = -0.3 if (moving or carrying) else 0.0
	# blink
	_blink -= dt
	if _blink < 0.0:
		eyes.scale.y = 0.15
		if _blink < -0.11:
			_blink = randf_range(1.8, 4.5)
			eyes.scale.y = 1.0
	if work == "sit":
		eyes.scale.y = 0.15 if fmod(_t, 6.0) > 2.0 else eyes.scale.y


## Smoothly turns the character to face a world direction.
func face(dir: Vector3, dt: float, rate := 12.0) -> void:
	if dir.length_squared() < 0.0001:
		return
	var target := atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, target, clampf(dt * rate, 0.0, 1.0))
