class_name Character
extends Node3D
## A tiny chibi person: big round head, dot eyes that blink, rosy cheeks,
## stubby limbs on pivots that are posed procedurally every frame.
##
## Looks: "player" (pink apron, ponytail), or a worker role from Defs.ROLES
## (each with its own shirt colour, hat and tool). Animation inputs:
##   move_speed  0..1 walk blend      carrying   arms forward holding a stack
##   work        "", "hoe", "pick", "milk", "scoop", "cheer", "sit", "push"

const HIP_Y := 0.27
const SHOULDER_Y := 0.55
const HEAD_Y := 0.86

var look := "player"
var skin := Color(1.0, 0.82, 0.68)
var hair := Color(0.35, 0.22, 0.14)
var shirt := Color(1.0, 1.0, 1.0)
var pants := Color(0.3, 0.45, 0.85)
var move_speed := 0.0
var carrying := false
var work := ""
var face_yaw := 0.0

var body: Node3D
var head: Node3D
var eyes: MeshInstance3D
var arm_l: Node3D
var arm_r: Node3D
var leg_l: Node3D
var leg_r: Node3D
var hand_r: Node3D
var carry_mount: Node3D
var back_mount: Node3D
var tool_node: Node3D
var _phase := 0.0
var _t := 0.0
var _blink := 2.0
var _squash := 0.0
var _seed := 0


## look: "player" or a role id or "idle". seed picks skin/hair.
func setup(p_look: String, p_seed := 0) -> void:
	look = p_look
	_seed = p_seed
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed * 7919 + 17
	skin = Pal.SKIN[rng.randi() % Pal.SKIN.size()]
	hair = Pal.HAIR[rng.randi() % Pal.HAIR.size()]
	_t = rng.randf() * 10.0
	match look:
		"player":
			skin = Pal.SKIN[0]
			hair = Color(0.45, 0.26, 0.15)
			shirt = Color(1.0, 0.97, 0.94)
			pants = Color(1.0, 0.5, 0.62)
		"idle", "":
			shirt = Color(0.85, 0.85, 0.9)
			pants = Color(0.62, 0.5, 0.92)
		_:
			shirt = Defs.ROLES[look]["color"]
			pants = Color(0.3, 0.45, 0.85)
			if look == "collector":
				pants = Color(0.38, 0.38, 0.44)
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	body = Node3D.new()
	add_child(body)
	var key := "%s_%s_%s" % [look, skin.to_html(), hair.to_html()]
	# torso
	Mats.inst(MeshKit.cached("torso_" + key, _torso_mesh), body)
	# head
	head = Node3D.new()
	head.position = Vector3(0, HEAD_Y, 0)
	body.add_child(head)
	Mats.inst(MeshKit.cached("head_" + key, _head_mesh), head)
	eyes = Mats.inst(MeshKit.cached("eyes", _eyes_mesh), head, Transform3D.IDENTITY, false)
	eyes.position = Vector3(0, 0.0, 0.0)
	var hat := _hat_mesh()
	if hat:
		Mats.inst(hat, head, Transform3D.IDENTITY, hat_casts_shadow())
	# limbs
	arm_l = _limb(Vector3(-0.2, SHOULDER_Y, 0), MeshKit.cached("arm_" + key, _arm_mesh))
	arm_r = _limb(Vector3(0.2, SHOULDER_Y, 0), MeshKit.cached("arm_" + key, _arm_mesh))
	leg_l = _limb(Vector3(-0.09, HIP_Y, 0), MeshKit.cached("leg_" + key, _leg_mesh))
	leg_r = _limb(Vector3(0.09, HIP_Y, 0), MeshKit.cached("leg_" + key, _leg_mesh))
	hand_r = Node3D.new()
	hand_r.position = Vector3(0, -0.28, 0)
	arm_r.add_child(hand_r)
	carry_mount = Node3D.new()
	carry_mount.position = Vector3(0, 0.38, 0.32)
	body.add_child(carry_mount)
	back_mount = Node3D.new()
	back_mount.position = Vector3(0, 0.45, -0.2)
	body.add_child(back_mount)
	_build_tool()


func _limb(pos: Vector3, mesh: Mesh) -> Node3D:
	var p := Node3D.new()
	p.position = pos
	body.add_child(p)
	# limbs skip the shadow pass: the body + head shadow reads the same, and
	# it halves the draw calls per character on phones
	Mats.inst(mesh, p, Transform3D.IDENTITY, false)
	return p


# ---------------------------------------------------------------- meshes

func _torso_mesh() -> Mesh:
	var k := MeshKit.new()
	# rounded bean body: pants below, shirt above
	var prof := PackedVector2Array([Vector2(0, 0.2), Vector2(0.15, 0.21), Vector2(0.19, 0.27), Vector2(0.2, 0.36),
		Vector2(0.2, 0.36), Vector2(0.2, 0.42), Vector2(0.19, 0.52), Vector2(0.15, 0.6), Vector2(0.07, 0.64), Vector2(0, 0.645)])
	var cols := [pants, pants, pants, pants, shirt, shirt, shirt, shirt, shirt, shirt]
	k.lathe(prof, cols, Transform3D.IDENTITY, 18)
	match look:
		"player":
			# pink apron: a shell over the front half of the body + a heart pocket
			var ap := PackedVector2Array([Vector2(0.17, 0.2), Vector2(0.205, 0.27), Vector2(0.212, 0.36), Vector2(0.21, 0.44), Vector2(0.2, 0.51)])
			k.lathe(ap, Color(1.0, 0.5, 0.63), MeshKit.xf(Vector3.ZERO, Vector3(0, -40, 0)), 12, PI * 0.95)
			for sx in [-1.0, 1.0]:
				k.sphere(0.03, Color(1.0, 0.85, 0.88), MeshKit.at(sx * 0.024, 0.37, 0.215), 8, 5)
			k.cone(0.04, 0.05, Color(1.0, 0.85, 0.88), MeshKit.xf(Vector3(0, 0.37, 0.212), Vector3(180, 0, 0)), 8)
		"idle", "":
			_overall_straps(k, Color(0.62, 0.5, 0.92))
		"collector":
			# chef jacket: double row of buttons + red neckerchief
			for i in 3:
				for sx in [-0.05, 0.05]:
					k.sphere(0.017, Color(0.85, 0.85, 0.9), MeshKit.at(sx, 0.32 + i * 0.07, 0.195), 6, 4)
			k.ellipsoid(Vector3(0.12, 0.04, 0.1), Pal.RED, MeshKit.at(0, 0.6, 0.06), 10, 5)
		_:
			_overall_straps(k, pants)
	return k.commit()


func _overall_straps(k: MeshKit, c: Color) -> void:
	# overalls bib + two straps + buttons
	k.rbox(Vector3(0.2, 0.14, 0.04), 0.03, c, MeshKit.xf(Vector3(0, 0.43, 0.18), Vector3(-8, 0, 0)))
	for sx in [-0.075, 0.075]:
		k.rbox(Vector3(0.04, 0.2, 0.03), 0.012, c, MeshKit.xf(Vector3(sx, 0.52, 0.15), Vector3(-30, 0, 0)))
		k.sphere(0.018, Pal.GOLD, MeshKit.at(sx, 0.48, 0.2), 6, 4)


func _head_mesh() -> Mesh:
	var k := MeshKit.new()
	k.ellipsoid(Vector3(0.27, 0.25, 0.25), skin, Transform3D.IDENTITY, 20, 14)
	# ears
	for sx in [-1.0, 1.0]:
		k.ellipsoid(Vector3(0.04, 0.06, 0.04), skin.darkened(0.04), MeshKit.at(sx * 0.265, -0.01, 0.0), 8, 5)
	# cheeks + little smile + nose
	for sx in [-1.0, 1.0]:
		k.ellipsoid(Vector3(0.05, 0.03, 0.02), Color(1.0, 0.55, 0.55), MeshKit.xf(Vector3(sx * 0.15, -0.075, 0.2), Vector3(0, sx * 32, 0)), 10, 5)
	k.ellipsoid(Vector3(0.035, 0.022, 0.03), skin.darkened(0.05), MeshKit.at(0, -0.035, 0.245), 8, 5)
	# smile: half a thin torus, tilted onto the face
	k.torus(0.04, 0.011, Color(0.45, 0.2, 0.18), MeshKit.xf(Vector3(0, -0.07, 0.232), Vector3(90 - 18, 0, 0)), 10, 5, PI)
	# hair: a cap over the top/back, a fringe
	k.ellipsoid(Vector3(0.28, 0.2, 0.27), hair, MeshKit.xf(Vector3(0, 0.07, -0.025), Vector3(-12, 0, 0)), 18, 10)
	for i in 5:
		var x := -0.16 + i * 0.08
		k.ellipsoid(Vector3(0.06, 0.05, 0.05), hair, MeshKit.xf(Vector3(x, 0.15 - absf(x) * 0.35, 0.18 - absf(x) * 0.25), Vector3(20, 0, x * 60)), 8, 5)
	if look == "player":
		# ponytail with a pink scrunchie
		k.torus(0.05, 0.022, Color(1.0, 0.45, 0.6), MeshKit.xf(Vector3(0, 0.18, -0.24), Vector3(60, 0, 0)), 12, 5)
		k.ellipsoid(Vector3(0.08, 0.15, 0.08), hair, MeshKit.xf(Vector3(0, 0.07, -0.33), Vector3(25, 0, 0)), 10, 7)
	return k.commit()


func _eyes_mesh() -> Mesh:
	var k := MeshKit.new()
	for sx in [-1.0, 1.0]:
		var p := Vector3(sx * 0.095, 0.015, 0.228)
		k.ellipsoid(Vector3(0.036, 0.05, 0.025), Color(0.13, 0.09, 0.09), MeshKit.xf(p, Vector3(0, sx * 22, 0)), 10, 7)
		k.sphere(0.012, Color(1, 1, 1), MeshKit.at(p.x + 0.012, p.y + 0.02, p.z + 0.02), 6, 4)
	return k.commit()


func _arm_mesh() -> Mesh:
	var k := MeshKit.new()
	k.capsule(0.06, 0.2, shirt, MeshKit.xf(Vector3(0, 0.02, 0), Vector3(180, 0, 0)), 10)
	k.sphere(0.065, skin, MeshKit.at(0, -0.24, 0), 10, 7)
	if look == "farmer" or look == "feeder" or look == "loader":
		k.sphere(0.07, Color(0.55, 0.38, 0.25) if look != "feeder" else Color(0.95, 0.85, 0.3), MeshKit.at(0, -0.24, 0), 10, 7)
	return k.commit()


func _leg_mesh() -> Mesh:
	var k := MeshKit.new()
	k.capsule(0.07, 0.22, pants, MeshKit.xf(Vector3(0, 0.03, 0), Vector3(180, 0, 0)), 10)
	var shoe := Color(0.45, 0.28, 0.18) if look != "player" else Color(1.0, 0.45, 0.55)
	k.ellipsoid(Vector3(0.075, 0.05, 0.1), shoe, MeshKit.at(0, -0.22, 0.025), 10, 6)
	return k.commit()


func _hat_mesh() -> Mesh:
	var hat := "none"
	if Defs.ROLES.has(look):
		hat = Defs.ROLES[look]["hat"]
	return MeshKit.cached("hat_" + hat, func(): return Character.build_hat(hat))


static func build_hat(hat: String) -> Mesh:
	var k := MeshKit.new()
	var b := MeshKit.new()
	match hat:
		"straw":
			var straw := Color(0.98, 0.84, 0.5)
			k.cyl(0.42, 0.03, straw, MeshKit.at(0, 0.14, 0), 22, 0.012)
			k.cyl(0.21, 0.16, straw, MeshKit.at(0, 0.15, 0), 18, 0.06, 0.18)
			k.cyl(0.215, 0.05, Pal.LEAF_DARK, MeshKit.at(0, 0.16, 0), 18, 0.01)
		"cap", "redcap":
			var c := Color(0.3, 0.58, 0.98) if hat == "cap" else Color(0.95, 0.3, 0.3)
			k.ellipsoid(Vector3(0.28, 0.17, 0.27), c, MeshKit.at(0, 0.1, -0.01), 18, 8)
			k.ellipsoid(Vector3(0.18, 0.025, 0.16), c.darkened(0.12), MeshKit.at(0, 0.11, 0.25), 14, 4)
			k.sphere(0.03, c.lightened(0.3), MeshKit.at(0, 0.27, 0), 8, 5)
		"hardhat":
			var o := Color(1.0, 0.6, 0.15)
			k.ellipsoid(Vector3(0.28, 0.21, 0.28), o, MeshKit.at(0, 0.09, 0), 18, 9)
			k.cyl(0.33, 0.03, o.darkened(0.1), MeshKit.at(0, 0.08, 0.02), 20, 0.012)
			k.rbox(Vector3(0.05, 0.05, 0.4), 0.02, o.lightened(0.15), MeshKit.at(0, 0.29, 0))
		"chef":
			var w := Color(0.99, 0.99, 1.0)
			k.cyl(0.24, 0.12, w, MeshKit.at(0, 0.1, 0), 18, 0.03)
			for i in 5:
				var a := TAU * i / 5.0
				k.sphere(0.13, w, MeshKit.at(cos(a) * 0.12, 0.3, sin(a) * 0.12), 12, 8)
			k.sphere(0.15, w, MeshKit.at(0, 0.36, 0), 12, 8)
		_:
			return null
	# hats sit a touch larger and higher so hair never pokes through
	b.merge(k, MeshKit.xf(Vector3(0, 0.025, 0), Vector3.ZERO, Vector3(1.07, 1.07, 1.07)))
	return b.commit()


func hat_casts_shadow() -> bool:
	return look == "farmer" or look == "collector"


func _build_tool() -> void:
	if not Defs.ROLES.has(look):
		return
	var tool: String = Defs.ROLES[look]["tool"]
	var mesh := MeshKit.cached("tool_" + tool, func(): return Character.build_tool(tool))
	match tool:
		"basket":
			tool_node = Mats.inst(mesh, back_mount, Transform3D.IDENTITY, false)
		"dolly":
			tool_node = Mats.inst(mesh, body, Transform3D.IDENTITY, false)
			tool_node.position = Vector3(0, 0, 0.42)
		_:
			tool_node = Mats.inst(mesh, hand_r, Transform3D.IDENTITY, false)


static func build_tool(tool: String) -> Mesh:
	var k := MeshKit.new()
	match tool:
		"hoe":
			k.cyl(0.022, 0.95, Pal.WOOD, MeshKit.at(0, -0.45, 0.02), 8)
			k.rbox(Vector3(0.15, 0.04, 0.17), 0.015, Pal.METAL, MeshKit.xf(Vector3(0, 0.48, 0.1), Vector3(-20, 0, 0)))
		"basket":
			var b := Color(0.86, 0.62, 0.32)
			k.cyl(0.17, 0.24, b, MeshKit.at(0, -0.12, -0.05), 14, 0.04, 0.2)
			k.torus(0.2, 0.025, b.darkened(0.15), MeshKit.at(0, 0.12, -0.05), 16, 5)
			for i in 3:
				k.torus(0.18 + i * 0.008, 0.012, b.darkened(0.1), MeshKit.at(0, -0.06 + i * 0.07, -0.05), 16, 4)
		"scoop":
			k.cyl(0.02, 0.28, Pal.WOOD, MeshKit.xf(Vector3(0, 0, 0), Vector3(90, 0, 0)), 8)
			k.rbox(Vector3(0.2, 0.08, 0.2), 0.04, Pal.METAL, MeshKit.at(0, 0.0, 0.34))
			k.rbox(Vector3(0.16, 0.05, 0.16), 0.03, Color(1.0, 0.85, 0.4), MeshKit.at(0, 0.035, 0.34))
		"tray":
			k.rbox(Vector3(0.42, 0.03, 0.3), 0.012, Pal.METAL, MeshKit.at(0, -0.01, 0.12))
			for x in [-0.12, 0.0, 0.12]:
				Items.cookie_into(k, 0.055, 0.03, MeshKit.at(x, 0.005, 0.12))
		"dolly":
			# hand truck: two handles, a nose plate, two wheels
			var r := Color(0.95, 0.3, 0.3)
			for sx in [-0.16, 0.16]:
				k.cyl(0.02, 0.62, r, MeshKit.xf(Vector3(sx, 0.05, 0.0), Vector3(-12, 0, 0)), 8)
				k.cyl(0.07, 0.04, Pal.RUBBER, MeshKit.xf(Vector3(sx + signf(sx) * 0.02, 0.07, 0.1), Vector3(0, 0, 90)), 12, 0.015)
			k.rbox(Vector3(0.38, 0.03, 0.18), 0.01, Pal.METAL_DARK, MeshKit.at(0, 0.03, 0.08))
			k.cyl(0.018, 0.34, r, MeshKit.xf(Vector3(-0.17, 0.62, -0.13), Vector3(0, 0, -90)), 8)
	return k.commit()


# ---------------------------------------------------------------- animation

func squash(amount := 1.0) -> void:
	_squash = maxf(_squash, amount)


func _process(dt: float) -> void:
	if body == null:
		return
	_t += dt
	var spd := move_speed
	_phase += dt * (4.0 + spd * 9.0) * (1.0 if spd > 0.05 else 0.0)
	var s := sin(_phase)
	var c := cos(_phase)
	var walk := clampf(spd, 0.0, 1.0)
	# body bob / lean / breathing / squash
	_squash = move_toward(_squash, 0.0, dt * 4.0)
	var sq := sin(_squash * PI) * 0.18 * _squash
	var breathe := sin(_t * 2.4) * 0.012 * (1.0 - walk)
	body.position.y = absf(s) * 0.055 * walk
	body.rotation.x = walk * 0.12
	body.rotation.z = c * 0.05 * walk
	body.scale = Vector3(1.0 + sq * 0.6, 1.0 - sq + breathe, 1.0 + sq * 0.6)
	head.rotation.z = -c * 0.06 * walk + sin(_t * 1.3) * 0.03 * (1.0 - walk)
	head.rotation.x = 0.0
	# legs
	leg_l.rotation.x = s * 0.7 * walk
	leg_r.rotation.x = -s * 0.7 * walk
	# arms
	var al := -s * 0.6 * walk
	var ar := s * 0.6 * walk
	var alz := 0.08
	var arz := -0.08
	if carrying:
		al = -1.35 + s * 0.05 * walk
		ar = al
		alz = -0.2
		arz = 0.2
	match work:
		"hoe":
			var w := sin(_t * 7.0)
			ar = -1.6 - w * 0.9
			al = ar
			alz = -0.25
			arz = 0.25
			body.rotation.x = 0.15 + maxf(0.0, -w) * 0.2
		"pick":
			ar = -2.6 + sin(_t * 6.0) * 0.4
			al = -2.6 - sin(_t * 6.0) * 0.4
			head.rotation.x = -0.25
		"milk":
			body.position.y = -0.1
			leg_l.rotation.x = -1.2
			leg_r.rotation.x = -1.2
			ar = -1.2 + sin(_t * 10.0) * 0.35
			al = -1.2 - sin(_t * 10.0) * 0.35
			body.rotation.x = 0.25
		"scoop":
			var w2 := sin(_t * 5.0)
			ar = -1.2 - w2 * 0.6
			al = ar
			alz = -0.25
			arz = 0.25
		"cheer":
			ar = -2.8 + sin(_t * 12.0) * 0.25
			al = -2.8 - sin(_t * 12.0) * 0.25
			alz = -0.3
			arz = 0.3
			body.position.y = absf(sin(_t * 6.0)) * 0.1
		"sit":
			body.position.y = -0.14
			leg_l.rotation.x = -1.5
			leg_r.rotation.x = -1.5
			ar = -0.4
			al = -0.4
			head.rotation.z = sin(_t * 0.8) * 0.12
		"push":
			ar = -1.1
			al = -1.1
			alz = -0.1
			arz = 0.1
	arm_l.rotation = Vector3(al, 0, alz)
	arm_r.rotation = Vector3(ar, 0, arz)
	if tool_node and Defs.ROLES.has(look) and Defs.ROLES[look]["tool"] == "dolly":
		tool_node.rotation.x = -0.35 if (walk > 0.05 or carrying) else 0.0
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
