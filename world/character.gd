class_name Character
extends Node3D
## A cute toy figure in the style of DEADGRID's characters: a big rounded-box
## head with a dark visor and two little eyes, a torso that narrows to the
## waist, two-segment limbs (hidden elbow/knee pivots) ending in chunky mitts
## and boots, an ink outline and a baked soft gradient.
##
## Looks: "player" (white suit, chocolate apron) or a worker role from
## Defs.ROLES (suit in the role colour + its hat and tool). Animation inputs:
##   move_speed  0..1 walk blend      carrying   arms forward holding a stack
##   work        "", "hoe", "pick", "milk", "scoop", "cheer", "sit", "push"

const HEAD_Y := 1.32

var look := "player"
var suit := Color(0.98, 0.98, 0.98)
var pants := Color(0.98, 0.98, 0.98)
var visor := Color(0.15, 0.2, 0.22)
var eye := Color(0.95, 0.97, 1.0)
var leather := Color(0.29, 0.35, 0.42)
var apron := Color(0, 0, 0, 0)
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


func setup(p_look: String, p_seed := 0) -> void:
	look = p_look
	var rng := RandomNumberGenerator.new()
	rng.seed = p_seed * 7919 + 17
	_t = rng.randf() * 10.0
	match look:
		"player":
			suit = Color(0.98, 0.98, 0.97)
			pants = suit
			apron = Color(0.42, 0.28, 0.2)
			leather = Color(0.36, 0.26, 0.2)
		"idle", "":
			suit = Color(0.78, 0.77, 0.75)
			pants = Color(0.6, 0.6, 0.6)
		_:
			var c: Color = Defs.ROLES[look]["color"]
			suit = c.lightened(0.08)
			pants = c.darkened(0.28)
			if look == "collector":
				suit = Color(0.97, 0.97, 0.96)
				pants = Color(0.36, 0.37, 0.4)
				apron = Color(0.93, 0.92, 0.89)
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
	var key := "%s_%s_%s" % [look, suit.to_html(), pants.to_html()]
	body = Node3D.new()
	add_child(body)
	upper = Node3D.new()
	body.add_child(upper)
	# torso: full width at the shoulders, narrowing to an 87% waist
	_part(MeshKit.cached("dg_torso_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.44, 0.54, 0.36), 0.03, suit)
		k.taper(func(y: float) -> Vector2:
			var t := clampf((y + 0.27) / 0.54, 0.0, 1.0)
			return Vector2(0.87 + 0.13 * t * t * (3.0 - 2.0 * t), 1.0))
		if apron.a > 0.0:
			# apron bib + skirt on the front, neck strap
			k.rbox(Vector3(0.3, 0.42, 0.03), 0.012, apron, MeshKit.at(0, -0.06, 0.182))
			k.rbox(Vector3(0.36, 0.05, 0.37), 0.015, apron.darkened(0.12), MeshKit.at(0, -0.12, 0))
		if look == "feeder" or look == "loader":
			k.rbox(Vector3(0.45, 0.05, 0.37), 0.015, Color(0.9, 0.84, 0.56), MeshKit.at(0, 0.08, 0))
		k.shade_figure(0.8)
		return k.commit()), upper, Vector3(0, 0.8, 0))
	# head + visor + eyes
	head = Node3D.new()
	head.position = Vector3(0, HEAD_Y, 0)
	upper.add_child(head)
	_part(MeshKit.cached("dg_head_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.56, 0.52, 0.52), 0.07, suit, Transform3D.IDENTITY, 2)
		k.taper(func(y: float) -> Vector2:
			var t := clampf((y + 0.26) / 0.22, 0.0, 1.0)
			return Vector2(0.93 + 0.07 * t * t * (3.0 - 2.0 * t), 1.0))
		# brow lip over the visor
		k.rbox(Vector3(0.52, 0.08, 0.11), 0.025, suit.darkened(0.3), MeshKit.at(0, 0.1, 0.235))
		k.rbox(Vector3(0.5, 0.26, 0.06), 0.025, visor, MeshKit.at(0, -0.06, 0.26))
		k.shade_figure(HEAD_Y)
		return k.commit()), head)
	eyes = Node3D.new()
	eyes.position = Vector3(0, -0.055, 0.295)
	head.add_child(eyes)
	_part(MeshKit.cached("dg_eyes", func():
		var k := MeshKit.new()
		for s in [-1.0, 1.0]:
			k.rbox(Vector3(0.11, 0.08, 0.03), 0.012, eye, MeshKit.at(s * 0.115, 0, 0))
		return k.commit()), eyes, Vector3.ZERO, false, false)
	var hat := _hat_mesh()
	if hat:
		_part(hat, head, Vector3.ZERO, true, false)
	# limbs
	var arm_upper := MeshKit.cached("dg_armu_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.145, 0.2, 0.155), 0.025, suit, MeshKit.at(0, -0.1, 0))
		return k.shade_figure(1.05).commit())
	var arm_lower := MeshKit.cached("dg_arml_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.115, 0.2, 0.125), 0.025, suit, MeshKit.at(0, -0.1, 0))
		k.rbox(Vector3(0.21, 0.21, 0.21), 0.075, leather, MeshKit.at(0, -0.28, 0))
		return k.shade_figure(0.85).commit())
	var leg_upper := MeshKit.cached("dg_legu_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.2, 0.22, 0.24), 0.025, pants, MeshKit.at(0, -0.11, 0))
		return k.shade_figure(0.52).commit())
	var leg_lower := MeshKit.cached("dg_legl_" + key, func():
		var k := MeshKit.new()
		k.rbox(Vector3(0.155, 0.19, 0.185), 0.025, pants, MeshKit.at(0, -0.095, 0))
		k.rbox(Vector3(0.235, 0.15, 0.34), 0.055, leather, MeshKit.at(0, -0.21, 0.04))
		return k.shade_figure(0.3).commit())
	arm_l = _limb(upper, Vector3(-0.28, 1.05, 0), arm_upper, arm_lower, 0.2)
	arm_r = _limb(upper, Vector3(0.28, 1.05, 0), arm_upper, arm_lower, 0.2)
	leg_l = _limb(body, Vector3(-0.14, 0.52, 0), leg_upper, leg_lower, 0.22)
	leg_r = _limb(body, Vector3(0.14, 0.52, 0), leg_upper, leg_lower, 0.22)
	elbow_l = arm_l.get_child(1)
	elbow_r = arm_r.get_child(1)
	knee_l = leg_l.get_child(1)
	knee_r = leg_r.get_child(1)
	hand_r = Node3D.new()
	hand_r.position = Vector3(0, -0.28, 0)
	elbow_r.add_child(hand_r)
	carry_mount = Node3D.new()
	carry_mount.position = Vector3(0, 0.72, 0.36)
	body.add_child(carry_mount)
	back_mount = Node3D.new()
	back_mount.position = Vector3(0, 0.9, -0.22)
	upper.add_child(back_mount)
	_build_tool()


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
	var hat := "baker" if look == "player" else "none"
	if Defs.ROLES.has(look):
		hat = Defs.ROLES[look]["hat"]
	return MeshKit.cached("dg_hat_" + hat, func(): return Character.build_hat(hat))


## Hats sit on the 0.56-wide head (top at y = +0.26 in head space).
static func build_hat(hat: String) -> Mesh:
	var k := MeshKit.new()
	match hat:
		"straw":
			var straw := Color(0.92, 0.8, 0.52)
			k.cyl(0.46, 0.035, straw, MeshKit.at(0, 0.2, 0), 20, 0.012)
			k.cyl(0.27, 0.16, straw, MeshKit.at(0, 0.22, 0), 18, 0.04, 0.24)
			k.cyl(0.275, 0.05, Color(0.38, 0.5, 0.3), MeshKit.at(0, 0.23, 0), 18, 0.01)
		"cap":
			var c := Color(0.3, 0.4, 0.52)
			k.rbox(Vector3(0.6, 0.14, 0.56), 0.06, c, MeshKit.at(0, 0.3, -0.01))
			k.rbox(Vector3(0.5, 0.04, 0.24), 0.02, c.darkened(0.15), MeshKit.at(0, 0.25, 0.34))
		"redcap":
			var r := Color(0.68, 0.34, 0.27)
			k.rbox(Vector3(0.6, 0.16, 0.56), 0.07, r, MeshKit.at(0, 0.3, -0.01))
			k.sphere(0.07, r.lightened(0.15), MeshKit.at(0, 0.42, 0), 8, 5)
		"hardhat":
			var o := Color(0.92, 0.72, 0.3)
			k.ellipsoid(Vector3(0.32, 0.17, 0.31), o, MeshKit.at(0, 0.26, 0), 16, 8)
			k.cyl(0.36, 0.03, o.darkened(0.08), MeshKit.at(0, 0.25, 0.02), 18)
			k.rbox(Vector3(0.06, 0.06, 0.5), 0.02, o.lightened(0.15), MeshKit.at(0, 0.42, 0))
		"chef":
			var w := Color(0.98, 0.98, 0.97)
			k.cyl(0.27, 0.22, w, MeshKit.at(0, 0.24, 0), 16, 0.03, 0.29)
			k.ellipsoid(Vector3(0.33, 0.14, 0.33), w, MeshKit.at(0, 0.52, 0), 16, 7)
		"baker":
			# the founder's soft baker's beret
			var b := Color(0.42, 0.28, 0.2)
			k.ellipsoid(Vector3(0.32, 0.09, 0.3), b, MeshKit.xf(Vector3(0.02, 0.3, -0.02), Vector3(0, 0, -6)), 16, 6)
			k.sphere(0.035, b.darkened(0.2), MeshKit.at(0.02, 0.39, -0.02), 6, 4)
		_:
			return null
	return k.commit()


func _build_tool() -> void:
	if not Defs.ROLES.has(look):
		return
	var tool: String = Defs.ROLES[look]["tool"]
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
				Items.cookie_into(k, 0.055, 0.03, MeshKit.at(x, 0.005, 0.16))
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
		al = -1.2 + s * 0.04 * walk
		ar = al
		el = -0.35
		er = -0.35
		alz = -0.12
		arz = 0.12
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
	if tool_node and Defs.ROLES.has(look) and Defs.ROLES[look]["tool"] == "dolly":
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
