class_name Line
extends Node3D
## A production line: a square glass tube on a dark steel frame with a steel
## silo hopper on top for every ingredient in the recipe (a new hopper appears
## when you unlock its farm). Dough balls roll along inside and stop under
## each hopper for a dose; after the last one they go into the brick oven,
## which bakes them into a batch of cookies that slide onto the tray.

signal baked(count: int)

var index := 0
var hoppers := {}        # ing -> Holder (layout NONE); locked ones have capacity 0
var hopper_nodes := {}   # ing -> Node3D (for squish / show)
var hopper_fill := {}    # ing -> Node3D gauge bar (scale y = fill)
var hopper_labels := {}
var hopper_bang := {}    # ing -> Label3D "!" shown while the line waits on it
var zones := {}          # ing -> Zone
var tray: Holder
var tray_zone: Zone
var doughs: Array[Dictionary] = []   # {x, idx, got, node, mat, wait}
var _spawn_cd := 0.0
var _oven_queue := 0
var _bake_t := 0.0
var _oven: Node3D
var _oven_glow: OmniLight3D
var _door: Node3D
var _chimney_t := 0.0
var _t := 0.0
var _belt_mat: ShaderMaterial
var _tray_label: Label3D


func setup(p_index: int) -> void:
	index = p_index
	name = "Line%d" % (index + 1)
	position = Vector3(0, 0, Lay.LINE_Z[index])
	_build_frame()
	for ing in Defs.INGREDIENTS:
		_build_hopper(ing)
	_build_oven()
	refresh()


func refresh() -> void:
	var cap := Bal.hopper_cap(Game.lvl("hopper"))
	for ing in Defs.INGREDIENTS:
		var on := Game.ingredient_unlocked(ing)
		hoppers[ing].capacity = cap if on else 0
		hopper_nodes[ing].visible = on
		zones[ing].visible = on
		zones[ing].enabled = on
		_update_hopper(ing)
	tray.capacity = Bal.tray_cap(Game.lvl("batch"))
	_update_tray()


## A farm was just unlocked: its hopper rises onto the tube.
func unlock(ing: String) -> void:
	refresh()
	var hn: Node3D = hopper_nodes[ing]
	hn.scale = Vector3(0.2, 0.05, 0.2)
	var tw := hn.create_tween()
	tw.tween_property(hn, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.puff(get_tree().current_scene, hn.global_position + Vector3(0, 0.6, 0), Pal.CREAM, 8)


## x of the next hopper a dough ball must visit (or INF: on to the oven).
func _next_station(d: Dictionary) -> float:
	for i in range(int(d["idx"]), Lay.STATIONS.size()):
		if Game.ingredient_unlocked(Lay.STATIONS[i]):
			d["idx"] = i
			return Lay.FARM_X[Lay.STATIONS[i]]
	d["idx"] = Lay.STATIONS.size()
	return INF


## Dough balls start just before the first hopper in use (a short trip
## while the recipe is small).
func _start_x() -> float:
	for ing in Lay.STATIONS:
		if Game.ingredient_unlocked(ing):
			return maxf(Lay.TUBE_X0 + 0.5, Lay.FARM_X[ing] - 1.6)
	return Lay.TUBE_X0 + 0.5


# ---------------------------------------------------------------- simulation

func _process(dt: float) -> void:
	_t += dt
	var mult := Game.speed_mult()
	var spd := Bal.dough_speed(Game.lvl("belt")) * mult
	var gap := Bal.dough_gap(Game.lvl("belt"))
	if _belt_mat:
		_belt_mat.set_shader_parameter("speed", spd if not doughs.is_empty() else 0.0)
	_spawn_cd -= dt
	var first_x := _start_x()
	var room: bool = doughs.is_empty() or doughs[doughs.size() - 1]["x"] > first_x + gap
	if room and _spawn_cd <= 0.0 and doughs.size() < 8 and hoppers["wheat"].count() > 0:
		_spawn_cd = 0.4
		_spawn_dough(first_x)
	var limit := Lay.TUBE_X1 + 0.6
	for i in doughs.size():
		var d: Dictionary = doughs[i]
		var station := _next_station(d)
		var stop := minf(station, limit)
		if i > 0:
			stop = minf(stop, doughs[i - 1]["x"] - gap)
		if d["wait"] > 0.0:
			d["wait"] -= dt * mult
			if d["wait"] <= 0.0:
				_dose_land(d)
		elif station < INF and d["x"] >= station - 0.02:
			d["x"] = station
			_try_dose(d)
		elif d["x"] < stop:
			d["x"] = minf(stop, d["x"] + spd * dt)
		var n: Node3D = d["node"]
		n.position.x = d["x"]
		n.rotation.z = -d["x"] / 0.22
	while not doughs.is_empty() and _next_station(doughs[0]) == INF and doughs[0]["x"] >= limit - 0.01:
		var d0: Dictionary = doughs.pop_front()
		var node: Node3D = d0["node"]
		var tw := node.create_tween()
		tw.tween_property(node, "scale", Vector3(0.2, 0.2, 0.2), 0.25)
		tw.tween_callback(node.queue_free)
		_oven_queue += 1
		Sfx.play("plop", -4.0)
	var bake := Bal.bake_time(Game.lvl("oven"))
	var batch := Bal.batch_size(Game.lvl("batch"))
	if _oven_queue > 0 and tray.space() >= batch:
		_bake_t += dt * mult
		if _bake_t >= bake:
			_bake_t = 0.0
			_oven_queue -= 1
			_finish_batch(batch)
	_animate_oven(dt, _oven_queue > 0)
	for ing in hopper_bang:
		var waiting := false
		for d in doughs:
			if d["wait"] <= 0.0 and int(d["idx"]) < Lay.STATIONS.size() and Lay.STATIONS[int(d["idx"])] == ing and is_equal_approx(d["x"], Lay.FARM_X[ing]):
				waiting = true
		var b: Label3D = hopper_bang[ing]
		b.visible = waiting and hoppers[ing].count() == 0
		if b.visible:
			b.position.y = 2.15 + absf(sin(_t * 6.0)) * 0.25


func _spawn_dough(x: float) -> void:
	var n := Node3D.new()
	n.position = Vector3(x, Lay.TUBE_Y - 0.36, 0)
	add_child(n)
	var mi := Mats.inst(MeshKit.cached("dough_ball", func():
		var k := MeshKit.new()
		k.sphere(0.24, Color(1, 1, 1), MeshKit.at(0, 0.24, 0), 14, 10)
		return k.commit()), n, Transform3D.IDENTITY, false)
	var m := Mats.toon().duplicate() as ShaderMaterial
	m.set_shader_parameter("tint", Color(0.94, 0.88, 0.74))
	mi.material_override = m
	n.scale = Vector3(0.6, 0.6, 0.6)
	doughs.append({"x": x, "idx": 0, "got": 0, "node": n, "wait": 0.0, "mat": m})


func _try_dose(d: Dictionary) -> void:
	var ing: String = Lay.STATIONS[int(d["idx"])]
	var h: Holder = hoppers[ing]
	if h.count() <= 0:
		return
	h.take(ing)
	_update_hopper(ing)
	d["wait"] = 0.35
	var hn: Node3D = hopper_nodes[ing]
	var tw := hn.create_tween()
	tw.tween_property(hn, "scale", Vector3(1.06, 0.92, 1.06), 0.08)
	tw.tween_property(hn, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	var drop := Items.node(ing)
	add_child(drop)
	drop.position = Vector3(Lay.FARM_X[ing], Lay.TUBE_Y + 0.4, 0)
	drop.scale = Vector3(0.5, 0.5, 0.5)
	var tw2 := drop.create_tween()
	tw2.tween_property(drop, "position:y", Lay.TUBE_Y - 0.15, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw2.parallel().tween_property(drop, "scale", Vector3(0.25, 0.25, 0.25), 0.3)
	tw2.tween_callback(drop.queue_free)
	Sfx.play("dispense", -8.0)


func _dose_land(d: Dictionary) -> void:
	var ing: String = Lay.STATIONS[int(d["idx"])]
	d["idx"] = int(d["idx"]) + 1
	d["got"] = int(d["got"]) + 1
	var n: Node3D = d["node"]
	# the ball grows and takes on its new ingredient's tone
	var tones := {"wheat": Color(0.95, 0.88, 0.72), "sugar": Color(0.97, 0.9, 0.76), "cocoa": Color(0.88, 0.76, 0.6),
		"egg": Color(0.97, 0.86, 0.62), "milk": Color(0.98, 0.9, 0.72)}
	(d["mat"] as ShaderMaterial).set_shader_parameter("tint", tones[ing])
	var s := 0.6 + int(d["got"]) * 0.08
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector3(s * 1.2, s * 0.84, s * 1.2), 0.08)
	tw.tween_property(n, "scale", Vector3(s, s, s), 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	if ing == "cocoa":
		Mats.inst(MeshKit.cached("dough_chips", func():
			var k := MeshKit.new()
			for i in 7:
				var a := TAU * i / 7.0
				k.ellipsoid(Vector3(0.05, 0.035, 0.05), Pal.CHOCO, MeshKit.at(cos(a) * 0.19, 0.3 + sin(a * 3.0) * 0.1, sin(a) * 0.19), 6, 4)
			return k.commit()), n, Transform3D.IDENTITY, false)
	Sfx.play("plop", -12.0, 1.0 + int(d["got"]) * 0.08)


func _finish_batch(batch: int) -> void:
	Game.stats["batches"] = int(Game.stats["batches"]) + 1
	Sfx.play("oven_ding", -8.0)
	var mouth := _oven.global_position + Vector3(1.1, 0.95, 0)
	for i in batch:
		var c := Items.node("cookie")
		get_tree().current_scene.add_child(c)
		c.global_position = mouth
		var target := tray
		c.scale = Vector3(0.5, 0.5, 0.5)
		tray.incoming += 1
		var tw := c.create_tween()
		tw.tween_interval(i * 0.08)
		tw.tween_property(c, "global_position", mouth + Vector3(0.6, 0.05, 0), 0.16)
		tw.parallel().tween_property(c, "scale", Vector3.ONE, 0.16)
		tw.tween_property(c, "global_position", tray.next_slot_global(), 0.22).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			c.queue_free()
			target.incoming -= 1
			target.add("cookie"))
	baked.emit(batch)
	Fx.puff(get_tree().current_scene, mouth + Vector3(0.1, 0.3, 0), Color(1, 0.97, 0.92), 4)


# ---------------------------------------------------------------- visuals

func _update_hopper(ing: String) -> void:
	var h: Holder = hoppers[ing]
	var f: float = float(h.count()) / maxf(1.0, h.capacity)
	var fill: Node3D = hopper_fill[ing]
	fill.scale = Vector3(1, maxf(0.02, f), 1)
	fill.visible = h.count() > 0
	var l: Label3D = hopper_labels[ing]
	l.text = "%d/%d" % [h.count(), h.capacity]
	l.modulate = Color(1.0, 0.72, 0.62) if h.count() == 0 else Color(1, 1, 1)


func _update_tray() -> void:
	if _tray_label:
		_tray_label.text = "%d" % tray.count()
		_tray_label.visible = tray.count() > 0


func _build_frame() -> void:
	var len := Lay.TUBE_X1 - Lay.TUBE_X0
	var cx := (Lay.TUBE_X0 + Lay.TUBE_X1) * 0.5
	var y := Lay.TUBE_Y
	Mats.inst(MeshKit.cached("line_frame", func():
		var k := MeshKit.new()
		var steel := Pal.STEEL_DARK
		var n := 7
		for i in n:
			var x := Lay.TUBE_X0 + 0.4 + (len - 0.8) * i / (n - 1)
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.1, y - 0.45, 0.1), 0.02, steel, MeshKit.at(x, (y - 0.45) * 0.5, sz * 0.55))
				k.rbox(Vector3(0.22, 0.04, 0.22), 0.015, steel, MeshKit.at(x, 0.02, sz * 0.55))
			# a square ring around the tube at every leg
			for sy in [-1.0, 1.0]:
				k.rbox(Vector3(0.08, 0.06, 1.14), 0.015, steel, MeshKit.at(x, y + sy * 0.48, 0))
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.08, 1.0, 0.06), 0.015, steel, MeshKit.at(x, y, sz * 0.54))
				k.sphere(0.025, Pal.BRASS, MeshKit.at(x, y + 0.48, sz * 0.56), 5, 3)
		# long edge rails along the tube
		for sy in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(len, 0.04, 0.04), 0.012, steel, MeshKit.at(cx, y + sy * 0.48, sz * 0.54))
		# belt bed + end caps
		k.rbox(Vector3(len, 0.08, 1.04), 0.02, steel, MeshKit.at(cx, y - 0.5, 0))
		k.rbox(Vector3(0.14, 1.04, 1.14), 0.03, steel, MeshKit.at(Lay.TUBE_X0 - 0.05, y, 0))
		return k.commit()), self)
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(len, 0.03, 0.82)
	belt.mesh = bm
	belt.position = Vector3(cx, y - 0.44, 0)
	_belt_mat = ShaderMaterial.new()
	_belt_mat.shader = preload("res://render/belt.gdshader")
	belt.material_override = _belt_mat
	add_child(belt)
	var glass := MeshInstance3D.new()
	var gk := MeshKit.new()
	gk.rbox(Vector3(len, 0.94, 1.06), 0.04, Color(1, 1, 1), MeshKit.at(cx, y, 0), 1)
	glass.mesh = gk.commit()
	glass.material_override = Mats.glass()
	glass.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(glass)
	var body := StaticBody3D.new()
	add_child(body)
	for i in 7:
		var x := Lay.TUBE_X0 + 0.4 + (len - 0.8) * i / 6.0
		for sz in [-1.0, 1.0]:
			var cs := CollisionShape3D.new()
			var sh := CylinderShape3D.new()
			sh.radius = 0.12
			sh.height = 1.2
			cs.shape = sh
			cs.position = Vector3(x, 0.6, sz * 0.55)
			body.add_child(cs)


func _build_hopper(ing: String) -> void:
	var x: float = Lay.FARM_X[ing]
	var c: Color = Defs.ITEMS[ing]["color"]
	var root := Node3D.new()
	root.position = Vector3(x, Lay.TUBE_Y + 0.47, 0)
	add_child(root)
	hopper_nodes[ing] = root
	# steel silo: cone into the tube, a cylinder body with an ingredient band,
	# a domed lid with a brass cap
	Mats.inst(MeshKit.cached("silo_" + ing, func():
		var k := MeshKit.new()
		var steel := Pal.STEEL
		k.cyl(0.12, 0.18, Pal.STEEL_DARK, MeshKit.at(0, 0, 0), 12, 0.02)
		k.cyl(0.13, 0.45, steel.darkened(0.08), MeshKit.at(0, 0.16, 0), 18, 0.0, 0.44, false)
		k.cyl(0.44, 0.8, steel, MeshKit.at(0, 0.6, 0), 22, 0.03)
		k.cyl(0.448, 0.1, c, MeshKit.at(0, 0.9, 0), 22, 0.0)
		k.ellipsoid(Vector3(0.44, 0.16, 0.44), steel.lightened(0.05), MeshKit.at(0, 1.4, 0), 18, 6)
		k.cyl(0.07, 0.1, Pal.BRASS, MeshKit.at(0, 1.52, 0), 10, 0.02)
		# four slim legs down to the tube's top rails
		for a in 4:
			var ang := TAU * a / 4.0 + PI * 0.25
			k.rbox(Vector3(0.04, 0.5, 0.04), 0.01, Pal.STEEL_DARK, MeshKit.at(cos(ang) * 0.4, 0.3, sin(ang) * 0.4))
		# gauge slot on the front
		k.rbox(Vector3(0.12, 0.6, 0.03), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 0.98, 0.43))
		return k.commit()), root)
	# fill gauge (ingredient colour, grows upward inside the slot)
	var fill := Node3D.new()
	fill.position = Vector3(0, 0.7, 0.45)
	root.add_child(fill)
	var fk := MeshKit.new()
	fk.rbox(Vector3(0.08, 0.56, 0.02), 0.01, c.lightened(0.15), MeshKit.at(0, 0.28, 0))
	var fm := Mats.inst(fk.commit(), fill, Transform3D.IDENTITY, false)
	fm.material_override = Mats.glow()
	hopper_fill[ing] = fill
	var b := UI3D.badge(ing, Pal.STEEL_DARK, 0.6)
	b.position = Vector3(0, 2.0, 0)
	root.add_child(b)
	var lab := UI3D.label("0/8", 28)
	lab.position = Vector3(0.75, 1.15, 0.3)
	root.add_child(lab)
	hopper_labels[ing] = lab
	var bang := UI3D.label("!", 70, Color(1.0, 0.62, 0.5), 16)
	bang.position = Vector3(0.48, 2.15, 0)
	bang.visible = false
	root.add_child(bang)
	hopper_bang[ing] = bang
	var h := Holder.new().setup(8, [ing], Holder.Layout.NONE)
	h.position = Vector3(0, 1.0, 0)
	root.add_child(h)
	h.changed.connect(_update_hopper.bind(ing))
	h.landed.connect(func(_t): _hopper_bounce(ing))
	hoppers[ing] = h
	var z := Zone.make(Zone.Kind.GIVE, [h], Vector2(1.6, 1.25), ing, c)
	z.position = Vector3(x, 0, Lay.HOPPER_ZONE_DZ)
	add_child(z)
	zones[ing] = z


func _hopper_bounce(ing: String) -> void:
	var hn: Node3D = hopper_nodes[ing]
	hn.scale = Vector3(0.97, 1.04, 0.97)
	var tw := hn.create_tween()
	tw.tween_property(hn, "scale", Vector3.ONE, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _build_oven() -> void:
	_oven = Node3D.new()
	_oven.position = Vector3(Lay.OVEN_X, 0, 0)
	add_child(_oven)
	Mats.inst(MeshKit.cached("oven", Line.oven_mesh), _oven)
	_door = Node3D.new()
	_door.position = Vector3(0, 0.62, 1.08)
	_oven.add_child(_door)
	_oven_glow = OmniLight3D.new()
	_oven_glow.light_color = Color(1.0, 0.62, 0.32)
	_oven_glow.omni_range = 3.2
	_oven_glow.light_energy = 0.0
	_oven_glow.position = Vector3(0, 0.9, 1.5)
	_oven.add_child(_oven_glow)
	var body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var sh := CylinderShape3D.new()
	sh.radius = 1.15
	sh.height = 2.4
	cs.shape = sh
	cs.position = Vector3(0, 1.2, 0)
	body.add_child(cs)
	_oven.add_child(body)
	var tray_root := Node3D.new()
	tray_root.position = Vector3(Lay.TRAY_X, 0, 0)
	add_child(tray_root)
	Mats.inst(MeshKit.cached("tray", func():
		var k := MeshKit.new()
		# dark steel bench with a brushed top and a chute from the oven
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				k.rbox(Vector3(0.08, 0.72, 0.08), 0.02, Pal.STEEL_DARK, MeshKit.at(sx * 0.72, 0.36, sz * 0.55))
		k.rbox(Vector3(1.6, 0.06, 1.25), 0.02, Pal.STEEL_DARK, MeshKit.at(0, 0.72, 0))
		k.rbox(Vector3(1.5, 0.03, 1.15), 0.01, Pal.STEEL, MeshKit.at(0, 0.765, 0))
		k.rbox(Vector3(1.5, 0.06, 0.06), 0.01, Pal.WOOD, MeshKit.at(0, 0.36, 0))
		k.rbox(Vector3(0.9, 0.04, 0.6), 0.01, Pal.STEEL, MeshKit.xf(Vector3(-0.95, 0.9, 0), Vector3(0, 0, -12)))
		return k.commit()), tray_root)
	var tb := StaticBody3D.new()
	var tcs := CollisionShape3D.new()
	var tsh := BoxShape3D.new()
	tsh.size = Vector3(1.6, 0.8, 1.25)
	tcs.shape = tsh
	tcs.position = Vector3(0, 0.4, 0)
	tb.add_child(tcs)
	tray_root.add_child(tb)
	tray = Holder.new().setup(20, ["cookie"], Holder.Layout.GRID)
	tray.grid = Vector2i(3, 3)
	tray.cell = Vector2(0.42, 0.36)
	tray.max_visible = 36
	tray.position = Vector3(0, 0.78, 0)
	tray_root.add_child(tray)
	tray.changed.connect(_update_tray)
	_tray_label = UI3D.label("0", 34)
	_tray_label.position = Vector3(0, 1.75, 0)
	tray_root.add_child(_tray_label)
	tray_zone = Zone.make(Zone.Kind.TAKE, [tray], Vector2(1.7, 1.2), "cookie", Pal.COOKIE)
	tray_zone.position = Vector3(Lay.TRAY_X, 0, 1.5)
	add_child(tray_zone)


static func oven_mesh() -> Mesh:
	var k := MeshKit.new()
	var stone := Pal.STONE
	var iron := Pal.STEEL_DARK
	# stone plinth
	k.rbox(Vector3(2.6, 0.4, 2.4), 0.06, stone, MeshKit.at(0, 0.2, 0))
	k.rbox(Vector3(2.7, 0.06, 2.5), 0.03, Pal.STONE_DARK, MeshKit.at(0, 0.41, 0))
	# brick dome: alternating brick tones per course give a laid-brick look
	var prof := PackedVector2Array()
	var cols := []
	var courses := 11
	for i in courses + 1:
		var a := PI * 0.5 * float(i) / courses
		prof.append(Vector2(cos(a) * 1.12, 0.44 + sin(a) * 1.55))
		prof.append(Vector2(cos(a) * 1.12, 0.44 + sin(a) * 1.55))
		var c: Color = Pal.BRICK if i % 2 == 0 else Pal.BRICK.lerp(Pal.BRICK_DARK, 0.45)
		cols.append(c)
		cols.append(c)
	prof[prof.size() - 1] = Vector2(0, 1.99)
	prof[prof.size() - 2] = Vector2(0, 1.99)
	k.lathe(prof, cols, Transform3D.IDENTITY, 28)
	# arched iron mouth facing the camera with a warm glow inside
	k.rbox(Vector3(1.05, 0.95, 0.4), 0.3, iron, MeshKit.at(0, 0.92, 0.95))
	k.rbox(Vector3(0.82, 0.74, 0.4), 0.25, Color(1.0, 0.5, 0.2, 0.45), MeshKit.at(0, 0.9, 1.0))
	k.rbox(Vector3(0.9, 0.08, 0.3), 0.02, stone, MeshKit.at(0, 0.48, 1.18))
	# tube inlet (west) and output slot (east)
	k.rbox(Vector3(0.3, 1.0, 1.1), 0.04, iron, MeshKit.at(-1.05, Lay.TUBE_Y, 0))
	k.rbox(Vector3(0.3, 0.42, 0.85), 0.04, iron, MeshKit.at(1.05, 0.95, 0))
	# tall chimney: brick base, dark steel flue, brass band
	k.cyl(0.26, 0.5, Pal.BRICK_DARK, MeshKit.at(-0.35, 1.6, -0.35), 12, 0.02)
	k.cyl(0.17, 1.35, iron, MeshKit.at(-0.35, 2.05, -0.35), 12, 0.02)
	k.cyl(0.21, 0.08, Pal.BRASS, MeshKit.at(-0.35, 3.3, -0.35), 12, 0.02)
	return k.commit()


func _animate_oven(dt: float, busy: bool) -> void:
	_oven_glow.light_energy = lerpf(_oven_glow.light_energy, (1.1 + sin(_t * 9.0) * 0.2) if busy else 0.3, clampf(dt * 3.0, 0.0, 1.0))
	if busy:
		_chimney_t -= dt
		if _chimney_t <= 0.0:
			_chimney_t = 0.45
			Fx.puff(get_tree().current_scene, _oven.global_position + Vector3(-0.35, 3.55, -0.35), Color(0.92, 0.92, 0.92), 1)
