class_name PalaceB
extends Building
## The Grand Cookie Palace: the crown of the empire and the goal of the game.
## It rises in five stages. Each stage needs Royal Empire cookies delivered
## on its pad (boxes and gifts count 6) and a payment from the info panel.
## Finishing The Crown wins the game.

var inbox: Holder
var zone: Zone
var _label: Label3D
var _sparkle_t := 0.0


func _build() -> void:
	inbox = Holder.new().setup(9999, [], Holder.Layout.NONE)
	inbox.accept_fn = func(t): return Defs.recipe_of(t) == "royal" and delivered() < needed()
	inbox.position = Vector3(0, 1.5, 3.0)
	add_child(inbox)
	inbox.landed.connect(_on_landed)
	zone = add_zone(Zone.Kind.GIVE, [inbox], Vector2(0, 4.2), Vector2(3.0, 1.2), Pal.GOLD)
	add_port(inbox, zone, "in")
	_label = UI3D.label("", 34, Color(1.0, 0.9, 0.5))
	_label.position = Vector3(0, 9.0, 0)
	add_child(_label)
	_update()


func stage() -> int:
	return int(data.get("stage", 0))


func delivered() -> int:
	return int(data.get("royal", 0))


## Royal cookies needed to unlock the next stage.
func needed() -> int:
	var s := stage() + 1
	return int(Defs.PALACE_STAGES[s]["need"]) if s < Defs.PALACE_STAGES.size() else 0


func next_cost() -> float:
	var s := stage() + 1
	return float(Defs.PALACE_STAGES[s]["cost"]) if s < Defs.PALACE_STAGES.size() else 0.0


func complete() -> bool:
	return stage() >= Defs.PALACE_STAGES.size() - 1


func can_advance() -> bool:
	return not complete() and delivered() >= needed() and Game.can_afford(next_cost())


## Builds the next stage (money is paid here).
func advance() -> bool:
	if not can_advance() or not Game.spend(next_cost()):
		return false
	data["stage"] = stage() + 1
	data["royal"] = 0
	tier = -1
	refresh()
	Game.save_game()
	if complete():
		Game.won = true
		Game.toast.emit("The Grand Cookie Palace is complete!", "palace")
	return true


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
	data["royal"] = delivered() + (1 if Defs.cat(t) == "cookie" else Bal.BOX_SIZE)
	_update()


func need(t: String) -> float:
	return 1.5 if inbox.can_accept(t) else 0.0


func _update() -> void:
	if _label == null:
		return
	if complete():
		_label.text = "Complete!"
	else:
		_label.text = "%s  ·  Royal %d / %d" % [Defs.PALACE_STAGES[stage() + 1]["name"], delivered(), needed()]


func solid_rects() -> Array[Rect2]:
	return [Rect2(-5.0, -5.0, 10.0, 8.6)]


func _process(dt: float) -> void:
	super(dt)
	_sparkle_t -= dt
	if _sparkle_t <= 0.0 and stage() >= 3:
		_sparkle_t = 0.8
		Fx.puff(get_tree().current_scene, to_world(randf_range(-3, 3), randf_range(-3, 1), randf_range(4, 7)), Pal.GOLD, 2)


func _visual(root: Node3D, t: int) -> void:
	Mats.inst(MeshKit.cached("palace_%d" % t, func(): return PalaceB.mesh(t)), root)


func status() -> String:
	if complete():
		return "Your empire is legendary."
	return "Next: %s. Deliver %d Royal Empire cookies here, then pay $%s." % [Defs.PALACE_STAGES[stage() + 1]["name"], needed(), Fmt.num(next_cost())]


func info() -> Array:
	var out := [["palace", "Stage %d of %d: %s" % [stage() + 1, Defs.PALACE_STAGES.size(), Defs.PALACE_STAGES[stage()]["name"]]]]
	if not complete():
		out.append(["ck_royal", "Royal cookies %d / %d" % [delivered(), needed()]])
		out.append(["coin", "Then $%s" % Fmt.num(next_cost())])
	return out


static func mesh(t: int) -> Mesh:
	var k := MeshKit.new()
	var cream := Color(0.95, 0.91, 0.82)
	var biscuit := Color(0.86, 0.66, 0.42)
	# foundations: a stone terrace with steps (always)
	k.rbox(Vector3(10.0, 0.5, 8.6), 0.08, Pal.STONE, MeshKit.at(0, 0.25, -0.7))
	for i in 3:
		k.rbox(Vector3(4.0 - i * 0.4, 0.17, 0.5), 0.03, Pal.STONE.lightened(0.05), MeshKit.at(0, 0.08 + i * 0.17, 3.7 - i * 0.35))
	if t == 0:
		# scaffolding and a few blocks
		for x in [-3.5, 0.0, 3.5]:
			for z in [-3.5, 0.5]:
				k.rbox(Vector3(0.1, 3.0, 0.1), 0.02, Pal.WOOD, MeshKit.at(x, 1.9, z))
		k.rbox(Vector3(8.0, 0.08, 0.3), 0.02, Pal.WOOD, MeshKit.at(0, 2.5, -3.5))
		for i in 6:
			k.rbox(Vector3(0.8, 0.5, 0.6), 0.05, biscuit, MeshKit.at(-3.0 + i * 1.2, 0.75, -1.5))
		return k.commit()
	# biscuit walls
	k.rbox(Vector3(8.6, 3.0, 6.0), 0.15, biscuit, MeshKit.at(0, 2.0, -1.5))
	for row in 6:
		k.rbox(Vector3(8.62, 0.04, 6.02), 0.01, biscuit.darkened(0.12), MeshKit.at(0, 0.8 + row * 0.5, -1.5))
	for i in 5:
		k.rbox(Vector3(0.7, 1.2, 0.08), 0.3, Color(0.4, 0.3, 0.25), MeshKit.at(-3.0 + i * 1.5, 2.2, 1.52))
		k.rbox(Vector3(0.55, 1.0, 0.09), 0.25, Color(1.0, 0.8, 0.5, 0.35), MeshKit.at(-3.0 + i * 1.5, 2.2, 1.53))
	k.rbox(Vector3(1.6, 2.2, 0.1), 0.6, Pal.CHOCO, MeshKit.at(0, 1.6, 1.53))
	k.rbox(Vector3(8.8, 0.3, 6.2), 0.08, cream, MeshKit.at(0, 3.6, -1.5))
	if t >= 2:
		# cream towers at the corners
		for sx in [-1.0, 1.0]:
			for sz in [-1.0, 1.0]:
				var p := Vector3(sx * 4.2, 0.5, -1.5 + sz * 2.9)
				k.cyl(0.8, 4.8, cream, MeshKit.at(p.x, p.y, p.z), 16, 0.06)
				for y in [1.5, 3.0, 4.5]:
					k.torus(0.8, 0.06, biscuit, MeshKit.at(p.x, p.y + y, p.z), 16, 4)
				k.cone(0.95, 1.4, Pal.CHOCO if t < 3 else Pal.GOLD, MeshKit.at(p.x, p.y + 4.8, p.z), 16)
	if t >= 3:
		# golden domes
		k.ellipsoid(Vector3(2.2, 2.0, 2.0), Pal.GOLD, MeshKit.at(0, 3.75, -1.5), 20, 12)
		for sx in [-1.0, 1.0]:
			k.ellipsoid(Vector3(1.0, 1.0, 1.0), Pal.GOLD, MeshKit.at(sx * 2.6, 3.75, -1.5), 14, 8)
		k.cyl(0.06, 1.2, Pal.GOLD, MeshKit.at(0, 5.7, -1.5), 6)
	if t >= 4:
		# the crown on top: a giant royal cookie in a golden ring
		Items.cookie_into(k, "royal", 1.1, 0.4, MeshKit.xf(Vector3(0, 7.8, -1.3), Vector3(90, 0, 0)))
		k.torus(1.25, 0.1, Pal.GOLD, MeshKit.xf(Vector3(0, 7.8, -1.1), Vector3(90, 0, 0)), 28, 6)
		for i in 7:
			var a := TAU * i / 7.0
			k.cone(0.12, 0.45, Pal.GOLD, MeshKit.at(cos(a) * 1.25, 9.1 + sin(a) * 0.05, -1.3), 6)
		# banners
		for sx in [-1.0, 1.0]:
			k.rbox(Vector3(0.7, 1.8, 0.05), 0.02, Pal.TERRACOTTA, MeshKit.at(sx * 2.2, 2.4, 1.6))
			k.rbox(Vector3(0.5, 0.5, 0.06), 0.05, Pal.GOLD, MeshKit.at(sx * 2.2, 2.7, 1.62))
	return k.commit()
