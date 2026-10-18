class_name MegaB
extends Building
## The AGI Megacluster: the crown of the empire and the goal of the game.
## It rises in five stages. Each stage needs Frontier 1T tokens delivered on
## its pad (batches and agent runs count 6) and a payment from the info
## panel. Finishing The Core wins the game.

var inbox: Holder
var _label: Label3D
var _sparkle_t := 0.0


func _build() -> void:
	inbox = Holder.new().setup(9999, [], Holder.Layout.NONE)
	inbox.accept_fn = func(t): return Defs.recipe_of(t) == Defs.MEGA_MODEL and delivered() < needed()
	inbox.position = Vector3(0, 1.5, 3.0)
	add_child(inbox)
	inbox.landed.connect(_on_landed)
	add_port(inbox, null, "in")
	_label = UI3D.label("", 34, Color(0.6, 0.95, 1.0))
	_label.position = Vector3(0, 9.0, 0)
	add_child(_label)
	_update()


func stage() -> int:
	return int(data.get("stage", 0))


func delivered() -> int:
	return int(data.get("frontier", 0))


## Frontier tokens needed to unlock the next stage.
func needed() -> int:
	var s := stage() + 1
	return int(Defs.MEGA_STAGES[s]["need"]) if s < Defs.MEGA_STAGES.size() else 0


func next_cost() -> float:
	var s := stage() + 1
	return float(Defs.MEGA_STAGES[s]["cost"]) if s < Defs.MEGA_STAGES.size() else 0.0


func complete() -> bool:
	return stage() >= Defs.MEGA_STAGES.size() - 1


func next_time() -> float:
	var s := stage() + 1
	return float(Defs.MEGA_STAGES[s]["time"]) * Bal.tool_mult() if s < Defs.MEGA_STAGES.size() else 0.0


func building_stage() -> bool:
	return not Game.job_of(uid).is_empty()


## Why the next stage can't start ("" when it can).
func advance_block() -> String:
	if complete():
		return "Complete"
	if building_stage():
		return "Builders are on it"
	if delivered() < needed():
		return "Deliver %d more %s tokens" % [needed() - delivered(), Defs.model_name(Defs.MEGA_MODEL)]
	if not Game.can_afford(next_cost()):
		return "Not enough money"
	if Game.free_builders() <= 0:
		return "All builders are busy"
	return ""


func can_advance() -> bool:
	return advance_block() == ""


## Starts building the next stage: money now, a builder for a while.
func advance() -> bool:
	if not can_advance():
		return false
	return Game.start_stage(uid, next_cost(), next_time())


func refresh() -> void:
	level = int(data["lvl"])
	var t := stage()
	if t != tier:
		var first := tier < 0
		tier = t
		if visual:
			visual.queue_free()
		visual = Node3D.new()
		add_child(visual)
		_visual(visual, tier)
		if not first:
			celebrate()
	_update()
	changed.emit()


func _on_landed(t: String) -> void:
	inbox.take(t)
	data["frontier"] = delivered() + (1 if Defs.cat(t) == "token" else Bal.BATCH_SIZE)
	_update()


func need(t: String) -> float:
	return 1.5 if inbox.can_accept(t) and not building_stage() else 0.0


func _update() -> void:
	if _label == null:
		return
	if complete():
		_label.text = "Complete!"
	else:
		_label.text = "%s  ·  Frontier %d / %d" % [Defs.MEGA_STAGES[stage() + 1]["name"], delivered(), needed()]


func solid_rects() -> Array[Rect2]:
	return [Rect2(-5.0, -5.0, 10.0, 8.6)]


func _process(dt: float) -> void:
	super(dt)
	_sparkle_t -= dt
	if _sparkle_t <= 0.0 and stage() >= 3:
		_sparkle_t = 0.8
		Fx.puff(get_tree().current_scene, to_world(randf_range(-3, 3), randf_range(-3, 1), randf_range(4, 7)), Color(0.6, 0.95, 1.0), 2)


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("mega_%d" % t, func(): return MegaB.mesh(t)), root)


func status() -> String:
	if complete():
		return "Your megacluster is online. Welcome to the future."
	return "Next: %s. Deliver %d %s tokens here, then pay $%s." % [Defs.MEGA_STAGES[stage() + 1]["name"], needed(), Defs.model_name(Defs.MEGA_MODEL), Fmt.num(next_cost())]


func info() -> Array:
	var out := [["mega", "Stage %d of %d: %s" % [stage() + 1, Defs.MEGA_STAGES.size(), Defs.MEGA_STAGES[stage()]["name"]]]]
	if not complete():
		out.append(["tk_" + Defs.MEGA_MODEL, "%s tokens %d / %d" % [Defs.model_name(Defs.MEGA_MODEL), delivered(), needed()]])
		out.append(["coin", "Then $%s" % Fmt.num(next_cost())])
	return out


static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var white := Color(0.95, 0.95, 0.96)
	var g := Color(0.17, 0.18, 0.21)
	var lit := func(c: Color, a := 0.45) -> Color: return Color(c.r, c.g, c.b, a)
	var cyan := Color(0.4, 0.92, 0.96)
	# groundbreaking: a concrete platform with steps (always)
	k.rbox(Vector3(10.0, 0.5, 8.6), 0.08, Color(0.7, 0.71, 0.72), MeshKit.at(0, 0.25, -0.7))
	for i in 3:
		k.rbox(Vector3(4.0 - i * 0.4, 0.17, 0.5), 0.03, Color(0.78, 0.79, 0.8), MeshKit.at(0, 0.08 + i * 0.17, 3.7 - i * 0.35))
	k.rbox(Vector3(9.8, 0.03, 0.06), 0.01, lit.call(cyan), MeshKit.at(0, 0.5, 3.55))
	if t == 0:
		# survey stakes, a crane and a few rebar cages
		for x in [-3.5, 0.0, 3.5]:
			for z in [-3.5, 0.5]:
				k.rbox(Vector3(0.1, 3.0, 0.1), 0.02, Color(0.96, 0.6, 0.24), MeshKit.at(x, 1.9, z))
		k.rbox(Vector3(8.0, 0.08, 0.3), 0.02, Color(0.96, 0.8, 0.26), MeshKit.at(0, 2.5, -3.5))
		for i in 6:
			k.rbox(Vector3(0.8, 0.5, 0.6), 0.05, Color(0.62, 0.62, 0.6), MeshKit.at(-3.0 + i * 1.2, 0.75, -1.5))
		return k.commit()
	# stage 1, the power plant: a long hall with transformers and pylons
	k.rbox(Vector3(8.6, 3.0, 6.0), 0.15, white, MeshKit.at(0, 2.0, -1.5))
	for i in 9:
		k.rbox(Vector3(0.06, 2.9, 6.02), 0.01, white.darkened(0.08), MeshKit.at(-3.9 + i * 0.975, 2.0, -1.5))
	for i in 5:
		k.rbox(Vector3(0.9, 0.9, 0.08), 0.06, Color(0.14, 0.15, 0.18), MeshKit.at(-3.0 + i * 1.5, 2.5, 1.52))
		k.rbox(Vector3(0.7, 0.7, 0.09), 0.05, lit.call(cyan, 0.5), MeshKit.at(-3.0 + i * 1.5, 2.5, 1.53))
	k.rbox(Vector3(1.8, 2.0, 0.1), 0.2, g, MeshKit.at(0, 1.5, 1.53))
	k.rbox(Vector3(1.6, 0.06, 0.02), 0.02, lit.call(cyan), MeshKit.at(0, 2.45, 1.6))
	k.rbox(Vector3(8.8, 0.3, 6.2), 0.08, Color(0.4, 0.42, 0.46), MeshKit.at(0, 3.6, -1.5))
	for sx in [-1.0, 1.0]:
		k.rbox(Vector3(0.8, 1.0, 0.7), 0.05, Color(0.56, 0.62, 0.58), MeshKit.at(sx * 3.9, 1.0, 2.6))
	if t >= 2:
		# cooling halls: four cooling towers at the corners
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p := Vector3(sx * 4.2, 0.5, -1.5 + sz * 2.9)
				k.lathe(PackedVector2Array([Vector2(1.0, 0), Vector2(0.72, 2.6), Vector2(0.66, 3.6), Vector2(0.8, 4.8), Vector2(0.7, 4.8), Vector2(0.56, 3.6), Vector2(0.62, 2.6), Vector2(0.9, 0.02)]), Color(0.88, 0.88, 0.86), MeshKit.at(p.x, p.y, p.z), 18)
				k.torus(0.72, 0.05, Color(0.36, 0.6, 0.86), MeshKit.at(p.x, p.y + 1.2, p.z), 18, 4)
				if t >= 3:
					k.torus(0.77, 0.06, lit.call(cyan), MeshKit.at(p.x, p.y + 4.75, p.z), 18, 4)
	if t >= 3:
		# GPU halls: a stepped graphite block of glowing racks on the roof
		k.rbox(Vector3(6.0, 1.6, 4.0), 0.12, g, MeshKit.at(0, 4.55, -1.5))
		for i in 10:
			k.rbox(Vector3(0.3, 1.2, 0.04), 0.03, lit.call([cyan, Color(0.5, 1.0, 0.6)][i % 2], 0.5), MeshKit.at(-2.5 + i * 0.55, 4.55, 0.52))
		k.rbox(Vector3(6.1, 0.1, 4.1), 0.03, Pal.BRASS, MeshKit.at(0, 5.38, -1.5))
		k.rbox(Vector3(4.0, 0.9, 2.6), 0.1, g, MeshKit.at(0, 5.85, -1.5))
	if t >= 4:
		# the core: a glowing sphere in a brass ring, a beam of light, banners
		k.sphere(1.0, lit.call(Color(0.6, 0.96, 1.0), 0.35), MeshKit.at(0, 7.6, -1.5), 22, 14)
		k.sphere(0.55, lit.call(Color(1, 1, 1), 0.25), MeshKit.at(0, 7.6, -1.5), 14, 8)
		k.torus(1.35, 0.1, Pal.BRASS, MeshKit.xf(Vector3(0, 7.6, -1.5), Vector3(90, 0, 0)), 28, 6)
		k.torus(1.55, 0.06, lit.call(cyan), MeshKit.xf(Vector3(0, 7.6, -1.5), Vector3(20, 0, 70)), 28, 5)
		k.cyl(0.1, 4.0, lit.call(Color(0.7, 0.98, 1.0), 0.6), MeshKit.at(0, 8.6, -1.5), 8)
		for sx in [-1.0, 1.0]:
			k.rbox(Vector3(0.7, 1.8, 0.05), 0.02, Color(0.3, 0.66, 0.68), MeshKit.at(sx * 2.2, 2.0, 1.6))
			Items.token_into(k, "frontier", 0.24, 0.05, MeshKit.xf(Vector3(sx * 2.2, 2.3, 1.64), Vector3(90, 0, 0)))
	return k.commit()
