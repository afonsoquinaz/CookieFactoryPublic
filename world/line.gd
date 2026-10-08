class_name Line
extends Node3D
## An assembly line: a square glass tube on legs with five ingredient hoppers
## on top. Dough balls roll along inside; under each hopper a ball waits for
## its dose (the hopper squishes and drops it in, the ball grows and changes
## colour). After the last hopper the ball goes into the oven, which bakes
## it into a batch of cookies that slide out onto the tray.

signal baked(count: int)

const SPACING_MIN := 1.0

var index := 0
var hoppers := {}        # ing -> Holder (layout NONE)
var hopper_nodes := {}   # ing -> Node3D (for squish)
var hopper_fill := {}    # ing -> MeshInstance3D (fill level)
var hopper_labels := {}
var hopper_alert := {}
var zones := {}          # ing -> Zone
var tray: Holder
var tray_zone: Zone
var doughs: Array[Dictionary] = []   # {x, stage, node, wait}
var _spawn_cd := 0.0
var _oven_queue := 0       # balls inside the oven
var _bake_t := 0.0
var _oven: Node3D
var _oven_face: Node3D
var _oven_glow: OmniLight3D
var _chimney_t := 0.0
var _t := 0.0
var _stations := []        # x of each hopper (ingredient order)
var _belt_mat: ShaderMaterial
var _tray_label: Label3D


func setup(p_index: int) -> void:
	index = p_index
	name = "Line%d" % (index + 1)
	position = Vector3(0, 0, Lay.LINE_Z[index])
	_build_frame()
	for ing in Defs.INGREDIENTS:
		_build_hopper(ing)
		_stations.append(Lay.FARM_X[ing])
	_build_oven()
	refresh()


func refresh() -> void:
	var cap := Bal.hopper_cap(Game.lvl("hopper"))
	for ing in Defs.INGREDIENTS:
		hoppers[ing].capacity = cap
		_update_hopper(ing)
	tray.capacity = Bal.tray_cap(Game.lvl("batch"))
	_update_tray()


# ---------------------------------------------------------------- simulation

func _process(dt: float) -> void:
	_t += dt
	var mult := Game.speed_mult()
	var spd := Bal.dough_speed(Game.lvl("belt")) * mult
	var gap := Bal.dough_gap(Game.lvl("belt"))
	if _belt_mat:
		_belt_mat.set_shader_parameter("speed", spd if _moving() else 0.0)
	# spawn a fresh empty ball at the tube start when there's room and the
	# first hopper has something (keeps the tube from filling with blanks)
	_spawn_cd -= dt
	var first_x := Lay.TUBE_X0 + 0.5
	var room: bool = doughs.is_empty() or doughs[doughs.size() - 1]["x"] > first_x + gap
	if room and _spawn_cd <= 0.0 and doughs.size() < 8 and _any_stock():
		_spawn_cd = 0.4
		_spawn_dough(first_x)
	# move balls front to back; each stops at its next station until dosed,
	# and keeps `gap` behind the one in front
	var limit := Lay.TUBE_X1 + 0.6
	for i in doughs.size():
		var d: Dictionary = doughs[i]
		var stage: int = d["stage"]
		var stop := limit
		if stage < _stations.size():
			stop = _stations[stage]
		if i > 0:
			stop = minf(stop, doughs[i - 1]["x"] - gap)
		if d["wait"] > 0.0:
			d["wait"] -= dt * mult
			if d["wait"] <= 0.0:
				_dose_land(d)
		elif stage < _stations.size() and d["x"] >= _stations[stage] - 0.02:
			# parked under its next hopper (snap: float clamps can leave it a hair short)
			d["x"] = _stations[stage]
			_try_dose(d)
		elif d["x"] < stop:
			d["x"] = minf(stop, d["x"] + spd * dt)
		var n: Node3D = d["node"]
		n.position.x = d["x"]
		n.rotation.z = -d["x"] / 0.22
	# balls that reached the oven
	while not doughs.is_empty() and doughs[0]["stage"] >= _stations.size() and doughs[0]["x"] >= limit - 0.01:
		var d0: Dictionary = doughs.pop_front()
		var node: Node3D = d0["node"]
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
		tw.tween_callback(node.queue_free)
		_oven_queue += 1
		Sfx.play("plop", -4.0)
	# bake
	var bake := Bal.bake_time(Game.lvl("oven"))
	var batch := Bal.batch_size(Game.lvl("batch"))
	if _oven_queue > 0 and tray.space() >= batch:
		_bake_t += dt * mult
		if _bake_t >= bake:
			_bake_t = 0.0
			_oven_queue -= 1
			_finish_batch(batch)
	_animate_oven(dt, _oven_queue > 0)


func _moving() -> bool:
	return not doughs.is_empty()


func _any_stock() -> bool:
	return hoppers["wheat"].count() > 0


func _spawn_dough(x: float) -> void:
	var n := Node3D.new()
	n.position = Vector3(x, Lay.TUBE_Y - 0.36, 0)
	add_child(n)
	var mi := Mats.inst(MeshKit.cached("dough_ball", func():
		var k := MeshKit.new()
		k.sphere(0.24, Color(1, 1, 1), MeshKit.at(0, 0.24, 0), 14, 10)
		return k.commit()), n, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", Color(0.96, 0.88, 0.62))
	mi.material_override = m
	n.scale = Vector3(0.55, 0.55, 0.55)
	doughs.append({"x": x, "stage": 0, "node": n, "wait": 0.0, "mat": m})


func _try_dose(d: Dictionary) -> void:
	var ing: String = Defs.INGREDIENTS[d["stage"]]
	var h: Holder = hoppers[ing]
	if h.count() <= 0:
		hopper_alert[ing] = true
		return
	hopper_alert[ing] = false
	h.take(ing)
	_update_hopper(ing)
	d["wait"] = 0.35
	# hopper squish + a dose drops into the tube
	var hn: Node3D = hopper_nodes[ing]
	var tw := hn.create_tween()
	tw.tween_property(hn, "scale", Vector3(1.12, 0.86, 1.12), 0.08)
	tw.tween_property(hn, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var drop := Items.node(ing)
	add_child(drop)
	drop.position = Vector3(_stations[d["stage"]], Lay.TUBE_Y + 0.9, 0)
	drop.scale = Vector3(0.6, 0.6, 0.6)
	var tw2 := drop.create_tween()
	tw2.tween_property(drop, "position:y", Lay.TUBE_Y - 0.1, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(drop, "scale", Vector3(0.3, 0.3, 0.3), 0.3)
	tw2.tween_callback(drop.queue_free)
	Sfx.play("dispense", -6.0)


func _dose_land(d: Dictionary) -> void:
	d["stage"] += 1
	var stage: int = d["stage"]
	var n: Node3D = d["node"]
	# the ball grows and darkens toward chocolate dough
	var cols := [Color(0.96, 0.88, 0.62), Color(0.98, 0.9, 0.66), Color(1.0, 0.93, 0.74), Color(0.78, 0.55, 0.36), Color(0.95, 0.8, 0.5), Color(0.98, 0.84, 0.58)]
	var m: ShaderMaterial = d["mat"]
	m.set_shader_parameter("tint", cols[mini(stage, cols.size() - 1)])
	var s := 0.55 + stage * 0.09
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3(s * 1.25, s * 0.8, s * 1.25), 0.08)
	tw.tween_property(n, "scale", Vector3(s, s, s), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if stage == 3:
		# cocoa makes it chocolatey: add chips
		var chips := Mats.inst(MeshKit.cached("dough_chips", func():
			var k := MeshKit.new()
			for i in 7:
				var a := TAU * i / 7.0
				k.ellipsoid(Vector3(0.05, 0.035, 0.05), Pal.CHOCO, MeshKit.at(cos(a) * 0.19, 0.3 + sin(a * 3.0) * 0.1, sin(a) * 0.19), 6, 4)
			return k.commit()), n, Transform3D.IDENTITY, false)
		chips.name = "chips"
	Sfx.play("plop", -10.0, 1.0 + stage * 0.08)


func _finish_batch(batch: int) -> void:
	Game.stats["batches"] = int(Game.stats["batches"]) + 1
	Sfx.play("oven_ding", -4.0)
	var mouth := _oven.global_position + Vector3(0.9, 0.6, 0)
	for i in batch:
		var c := Items.node("cookie")
		get_tree().current_scene.add_child(c)
		c.global_position = mouth
		var delay := i * 0.08
		var target := tray
		c.scale = Vector3(0.5, 0.5, 0.5)
		tray.incoming += 1
		var tw := c.create_tween()
		tw.tween_interval(delay)
		tw.tween_property(c, "global_position", mouth + Vector3(0.8, 0.1, 0), 0.18)
		tw.parallel().tween_property(c, "scale", Vector3.ONE, 0.18)
		tw.tween_property(c, "global_position", tray.next_slot_global(), 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			c.queue_free()
			target.incoming -= 1
			target.add("cookie"))
	baked.emit(batch)
	var tw2 := _oven_face.create_tween()
	tw2.tween_property(_oven, "scale", Vector3(1.08, 0.92, 1.08), 0.08)
	tw2.tween_property(_oven, "scale", Vector3.ONE, 0.4).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	Fx.puff(get_tree().current_scene, mouth + Vector3(0.2, 0.4, 0), Color(1, 0.95, 0.85), 6)


# ---------------------------------------------------------------- visuals

func _update_hopper(ing: String) -> void:
	var h: Holder = hoppers[ing]
	var f: float = float(h.count()) / maxf(1.0, h.capacity)
	var fill: MeshInstance3D = hopper_fill[ing]
	fill.scale = Vector3(1, maxf(0.02, f), 1)
	fill.visible = h.count() > 0
	var l: Label3D = hopper_labels[ing]
	l.text = "%d/%d" % [h.count(), h.capacity]
	l.modulate = Color(1.0, 0.55, 0.5) if h.count() == 0 else Color.WHITE


func _update_tray() -> void:
	if _tray_label:
		_tray_label.text = "%d" % tray.count()


func _build_frame() -> void:
	var len := Lay.TUBE_X1 - Lay.TUBE_X0
	var cx := (Lay.TUBE_X0 + Lay.TUBE_X1) * 0.5
	var y := Lay.TUBE_Y
	# legs, rails and end caps (one mesh)
	var frame := MeshKit.cached("line_frame", func():
		var k := MeshKit.new()
		var purple := Color(0.6, 0.52, 0.9)
		var purple_dk := Color(0.46, 0.38, 0.74)
		var n := 7
		for i in n:
			var x := Lay.TUBE_X0 + 0.4 + (len - 0.8) * i / (n - 1)
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.16, y - 0.45, 0.16), 0.05, purple_dk, MeshKit.at(x, (y - 0.45) * 0.5, sz * 0.55))
				k.cyl(0.16, 0.08, purple_dk.darkened(0.2), MeshKit.at(x, 0, sz * 0.55), 10, 0.03)
			# a collar around the tube at every leg
			k.rbox(Vector3(0.18, 1.02, 1.24), 0.08, purple, MeshKit.at(x, y, 0))
		# bottom rail under the belt
		k.rbox(Vector3(len, 0.12, 1.16), 0.05, purple_dk, MeshKit.at(cx, y - 0.5, 0))
		# end caps
		k.rbox(Vector3(0.3, 1.08, 1.3), 0.1, Color(1.0, 0.78, 0.3), MeshKit.at(Lay.TUBE_X0 - 0.1, y, 0))
		return k.commit())
	Mats.inst(frame, self)
	# moving belt inside the tube
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(len, 0.04, 0.8)
	belt.mesh = bm
	belt.position = Vector3(cx, y - 0.42, 0)
	_belt_mat = ShaderMaterial.new()
	_belt_mat.shader = preload("res://render/belt.gdshader")
	belt.material_override = _belt_mat
	add_child(belt)
	# the glass tube (square section)
	var glass := MeshInstance3D.new()
	var gk := MeshKit.new()
	gk.rbox(Vector3(len, 0.9, 1.0), 0.14, Color(1, 1, 1), MeshKit.at(cx, y, 0), 3)
	glass.mesh = gk.commit()
	glass.material_override = Mats.glass()
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass)
	# collision: only the legs block (people walk under the tube)
	var body := StaticBody3D.new()
	add_child(body)
	for i in 7:
		var x := Lay.TUBE_X0 + 0.4 + (len - 0.8) * i / 6.0
		for sz in [-1.0, 1.0]:
			var cs := CollisionShape3D.new()
			var sh := CylinderShape3D.new()
			sh.radius = 0.16
			sh.height = 1.2
			cs.shape = sh
			cs.position = Vector3(x, 0.6, sz * 0.55)
			body.add_child(cs)


func _build_hopper(ing: String) -> void:
	var x: float = Lay.FARM_X[ing]
	var c: Color = Defs.ITEMS[ing]["color"]
	var root := Node3D.new()
	root.position = Vector3(x, Lay.TUBE_Y + 0.45, 0)
	add_child(root)
	var bowl := Node3D.new()
	bowl.scale = Vector3(0.78, 0.78, 0.78)
	root.add_child(bowl)
	hopper_nodes[ing] = root
	Mats.inst(MeshKit.cached("hopper_" + ing, func():
		var k := MeshKit.new()
		var body := c.lerp(Color(1, 1, 1), 0.08)
		var dark := c.darkened(0.25)
		# neck into the tube, a funnel bowl, a rim, and an icon sign on a pole
		k.cyl(0.2, 0.3, dark, MeshKit.at(0, -0.05, 0), 12, 0.04)
		var prof := PackedVector2Array([Vector2(0, 0.2), Vector2(0.22, 0.2), Vector2(0.3, 0.26), Vector2(0.62, 0.72),
			Vector2(0.66, 0.92), Vector2(0.66, 0.92), Vector2(0.58, 0.92), Vector2(0.58, 0.92), Vector2(0.52, 0.5), Vector2(0, 0.5)])
		k.lathe(prof, body, Transform3D.IDENTITY, 20)
		k.torus(0.64, 0.07, body.lightened(0.2), MeshKit.at(0, 0.93, 0), 22, 6)
		k.torus(0.4, 0.035, dark, MeshKit.at(0, 0.5, 0), 18, 5)
		# sign post behind the bowl
		k.cyl(0.05, 1.2, Pal.METAL_DARK, MeshKit.at(0, 0.9, -0.62), 8)
		return k.commit()), bowl)
	# fill level inside the bowl (ingredient colour)
	var fill := MeshInstance3D.new()
	var fk := MeshKit.new()
	fk.cyl(0.54, 0.38, c.lightened(0.15), MeshKit.at(0, 0, 0), 18, 0.12, 0.6)
	fill.mesh = fk.commit()
	fill.material_override = Mats.toon()
	fill.position = Vector3(0, 0.5, 0)
	bowl.add_child(fill)
	hopper_fill[ing] = fill
	var b := UI3D.badge(ing, c.darkened(0.15), 0.9)
	b.position = Vector3(0, 1.95, -0.48)
	root.add_child(b)
	var lab := UI3D.label("0/8", 44)
	lab.position = Vector3(0.62, 1.95, -0.3)
	root.add_child(lab)
	hopper_labels[ing] = lab
	var h := Holder.new().setup(8, [ing], Holder.Layout.NONE)
	h.position = Vector3(0, 0.7, 0)
	root.add_child(h)
	h.changed.connect(_update_hopper.bind(ing))
	h.landed.connect(func(_t): _hopper_bounce(ing))
	hoppers[ing] = h
	hopper_alert[ing] = false
	var z := Zone.make(Zone.Kind.GIVE, [h], Vector2(1.7, 1.3), ing, c.lightened(0.3))
	z.position = Vector3(x, 0, Lay.HOPPER_ZONE_DZ)
	add_child(z)
	zones[ing] = z


func _hopper_bounce(ing: String) -> void:
	var hn: Node3D = hopper_nodes[ing]
	hn.scale = Vector3(0.94, 1.08, 0.94)
	var tw := hn.create_tween()
	tw.tween_property(hn, "scale", Vector3.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_oven() -> void:
	_oven = Node3D.new()
	_oven.position = Vector3(Lay.OVEN_X, 0, 0)
	add_child(_oven)
	Mats.inst(MeshKit.cached("oven", Line.oven_mesh), _oven)
	_oven_face = Node3D.new()
	_oven_face.position = Vector3(0, 1.45, 0.92)
	_oven.add_child(_oven_face)
	Mats.inst(MeshKit.cached("oven_face", func():
		var k := MeshKit.new()
		for sx in [-1.0, 1.0]:
			k.ellipsoid(Vector3(0.09, 0.13, 0.05), Color(0.2, 0.12, 0.1), MeshKit.at(sx * 0.32, 0.55, 0), 10, 7)
			k.sphere(0.03, Color(1, 1, 1), MeshKit.at(sx * 0.32 + 0.03, 0.6, 0.04), 6, 4)
			k.ellipsoid(Vector3(0.11, 0.06, 0.03), Color(1.0, 0.55, 0.55), MeshKit.at(sx * 0.55, 0.4, -0.02), 10, 5)
		return k.commit()), _oven_face, Transform3D.IDENTITY, false)
	_oven_glow = OmniLight3D.new()
	_oven_glow.light_color = Color(1.0, 0.6, 0.25)
	_oven_glow.omni_range = 3.0
	_oven_glow.light_energy = 0.0
	_oven_glow.position = Vector3(0, 1.0, 1.3)
	_oven.add_child(_oven_glow)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(2.2, 2.4, 1.9)
	cs.shape = sh
	cs.position = Vector3(0, 1.2, 0)
	body.add_child(cs)
	_oven.add_child(body)
	# output tray (cookies pile up here)
	var tray_root := Node3D.new()
	tray_root.position = Vector3(Lay.TRAY_X, 0, 0)
	add_child(tray_root)
	Mats.inst(MeshKit.cached("tray", func():
		var k := MeshKit.new()
		k.rbox(Vector3(1.7, 0.7, 1.4), 0.12, Color(0.6, 0.52, 0.9), MeshKit.at(0, 0.35, 0))
		k.rbox(Vector3(1.55, 0.08, 1.25), 0.04, Pal.METAL, MeshKit.at(0, 0.71, 0))
		# a little chute from the oven
		k.rbox(Vector3(1.2, 0.08, 0.7), 0.03, Pal.METAL, MeshKit.xf(Vector3(-1.05, 0.95, 0), Vector3(0, 0, -14)))
		return k.commit()), tray_root)
	var tb := StaticBody3D.new()
	var tcs := CollisionShape3D.new()
	var tsh := BoxShape3D.new()
	tsh.size = Vector3(1.7, 0.8, 1.4)
	tcs.shape = tsh
	tcs.position = Vector3(0, 0.4, 0)
	tb.add_child(tcs)
	tray_root.add_child(tb)
	tray = Holder.new().setup(20, ["cookie"], Holder.Layout.GRID)
	tray.grid = Vector2i(3, 3)
	tray.cell = Vector2(0.42, 0.36)
	tray.max_visible = 45
	tray.position = Vector3(0, 0.76, 0)
	tray_root.add_child(tray)
	tray.changed.connect(_update_tray)
	_tray_label = UI3D.label("0", 44)
	_tray_label.position = Vector3(0, 2.0, 0)
	tray_root.add_child(_tray_label)
	tray_zone = Zone.make(Zone.Kind.TAKE, [tray], Vector2(1.8, 1.2), "cookie", Color(1.0, 0.85, 0.6))
	tray_zone.position = Vector3(Lay.TRAY_X, 0, 1.55)
	add_child(tray_zone)


static func oven_mesh() -> Mesh:
	var k := MeshKit.new()
	var body := Color(0.98, 0.62, 0.55)
	var trim := Color(1.0, 0.8, 0.35)
	var dark := Color(0.55, 0.38, 0.62)
	k.rbox(Vector3(2.2, 0.3, 1.9), 0.1, dark, MeshKit.at(0, 0.15, 0))
	k.rbox(Vector3(2.0, 1.9, 1.75), 0.45, body, MeshKit.at(0, 1.2, 0))
	k.ellipsoid(Vector3(1.0, 0.5, 0.875), body, MeshKit.at(0, 2.0, 0), 18, 8)
	# glowing window (vertex alpha < 1 = emissive)
	k.rbox(Vector3(1.2, 0.62, 0.1), 0.22, trim, MeshKit.at(0, 1.05, 0.86))
	k.rbox(Vector3(1.0, 0.46, 0.1), 0.18, Color(1.0, 0.62, 0.22, 0.55), MeshKit.at(0, 1.05, 0.89))
	# mouth slot facing the tube (west) and the tray (east)
	k.rbox(Vector3(0.12, 0.7, 1.0), 0.06, trim, MeshKit.at(-1.0, Lay.TUBE_Y, 0))
	k.rbox(Vector3(0.12, 0.4, 0.9), 0.06, Color(0.3, 0.16, 0.12), MeshKit.at(1.02, 0.95, 0))
	# chimney with a gold band
	k.cyl(0.24, 0.9, Pal.METAL_DARK, MeshKit.at(0.45, 2.1, -0.3), 14, 0.05)
	k.cyl(0.29, 0.14, trim, MeshKit.at(0.45, 2.92, -0.3), 14, 0.05)
	# dials
	for i in 2:
		k.cyl(0.1, 0.06, [Pal.MINT, Pal.PINK][i], MeshKit.xf(Vector3(0.75, 1.6 - i * 0.3, 0.86), Vector3(90, 0, 0)), 12, 0.02)
	return k.commit()


func _animate_oven(dt: float, busy: bool) -> void:
	_oven_glow.light_energy = lerpf(_oven_glow.light_energy, (1.2 + sin(_t * 9.0) * 0.25) if busy else 0.25, clampf(dt * 3.0, 0.0, 1.0))
	_oven_face.position.y = 1.45 + (sin(_t * 8.0) * 0.02 if busy else 0.0)
	if busy:
		_chimney_t -= dt
		if _chimney_t <= 0.0:
			_chimney_t = 0.35
			Fx.puff(get_tree().current_scene, _oven.global_position + Vector3(0.45, 3.1, -0.3), Color(1, 1, 1), 1)
