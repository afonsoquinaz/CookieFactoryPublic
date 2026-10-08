class_name Fx
## Little bursts of juice: puffs, confetti, sparkles, coin fountains.

static var _puff_mesh: Mesh
static var _chip_mesh: Mesh
static var _confetti_mesh: Mesh
static var _star_mesh: Mesh


static func _meshes() -> void:
	if _puff_mesh:
		return
	var k := MeshKit.new()
	k.sphere(0.12, Color(1, 1, 1), Transform3D.IDENTITY, 8, 6)
	_puff_mesh = k.commit()
	k = MeshKit.new()
	k.rbox(Vector3(0.12, 0.12, 0.12), 0.04, Color(1, 1, 1))
	_chip_mesh = k.commit()
	k = MeshKit.new()
	k.rbox(Vector3(0.14, 0.02, 0.08), 0.008, Color(1, 1, 1))
	_confetti_mesh = k.commit()
	k = MeshKit.new()
	k.star(0.12, 0.055, 5, 0.04, Color(1, 1, 1), MeshKit.xf(Vector3(0, 0, 0.02), Vector3(90, 0, 0)))
	_star_mesh = k.commit()


static func _piece(parent: Node, mesh: Mesh, col: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", col)
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	return mi


## Soft dust/leaf puff.
static func puff(parent: Node, pos: Vector3, col := Color(1, 1, 1), n := 6) -> void:
	if parent == null:
		return
	_meshes()
	for i in n:
		var p := _piece(parent, _puff_mesh, col.lerp(Color.WHITE, 0.4))
		p.global_position = pos
		var dir := Vector3(randf_range(-1, 1), randf_range(0.3, 1.0), randf_range(-1, 1)).normalized()
		var s := randf_range(0.5, 1.1)
		p.scale = Vector3.ONE * s * 0.3
		var tw := p.create_tween().set_parallel(true)
		tw.tween_property(p, "global_position", pos + dir * randf_range(0.4, 0.8), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.tween_property(p, "scale", Vector3.ONE * s, 0.2)
		tw.chain().tween_property(p, "scale", Vector3.ZERO, 0.3)
		tw.chain().tween_callback(p.queue_free)


## Colourful pieces flung up that fall back down (upgrades, builds).
static func burst(parent: Node, pos: Vector3, col := Color(1, 0.8, 0.3), n := 18, confetti := true) -> void:
	if parent == null:
		return
	_meshes()
	var palette := [col, Pal.PINK, Pal.YELLOW, Pal.MINT, Pal.SKY, Pal.WHITE]
	for i in n:
		var c: Color = palette[i % palette.size()] if confetti else col
		var mesh := _confetti_mesh if (confetti and i % 2 == 0) else (_star_mesh if i % 3 == 0 else _chip_mesh)
		var p := _piece(parent, mesh, c)
		p.global_position = pos
		var v := Vector3(randf_range(-2.4, 2.4), randf_range(4.0, 7.0), randf_range(-2.4, 2.4))
		var spin := Vector3(randf_range(-9, 9), randf_range(-9, 9), randf_range(-9, 9))
		var life := randf_range(0.9, 1.3)
		var step := func(t: float) -> void:
			if not is_instance_valid(p):
				return
			p.global_position = pos + v * t + Vector3(0, -9.0, 0) * t * t * 0.5
			p.rotation = spin * t
			p.scale = Vector3.ONE * clampf((life - t) * 4.0, 0.0, 1.0)
		var tw := p.create_tween()
		tw.tween_method(step, 0.0, life, life)
		tw.tween_callback(p.queue_free)


## Coins spring up and arc toward a point (e.g. the truck pays out).
static func coins(parent: Node, from: Vector3, n := 8) -> void:
	if parent == null:
		return
	for i in n:
		var c := Items.node("coin")
		parent.add_child(c)
		c.global_position = from
		var off := Vector3(randf_range(-1.2, 1.2), randf_range(2.0, 3.2), randf_range(-1.2, 1.2))
		var delay := i * 0.04
		c.scale = Vector3.ZERO
		var tw := c.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(c, "scale", Vector3.ONE * 1.2, 0.12)
		tw.parallel().tween_property(c, "global_position", from + off, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(c, "rotation:y", TAU * 2.0, 0.6)
		tw.tween_property(c, "global_position", from + off + Vector3(0, 0.6, 0), 0.25).set_ease(Tween.EASE_IN_OUT)
		tw.tween_property(c, "scale", Vector3.ZERO, 0.15)
		tw.tween_callback(c.queue_free)


## A ring that expands on the floor (pad completed, worker assigned).
static func ring(parent: Node, pos: Vector3, col := Color(1, 1, 1), r := 1.2) -> void:
	if parent == null:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = MeshKit.cached("fx_ring", func():
		var k := MeshKit.new()
		k.torus(1.0, 0.06, Color(1, 1, 1), Transform3D.IDENTITY, 32, 4)
		return k.commit())
	var m := Mats.flat(Color(col.r, col.g, col.b, 0.9)).duplicate() as StandardMaterial3D
	mi.material_override = m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)
	mi.global_position = pos + Vector3(0, 0.06, 0)
	mi.scale = Vector3(0.2, 1, 0.2)
	var tw := mi.create_tween().set_parallel(true)
	tw.tween_property(mi, "scale", Vector3(r, 1, r), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(m, "albedo_color:a", 0.0, 0.45)
	tw.chain().tween_callback(mi.queue_free)
