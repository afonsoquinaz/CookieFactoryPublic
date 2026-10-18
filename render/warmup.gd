class_name Warmup
extends RefCounted
## Gets everything ready behind the loading screen so nothing freezes the
## first time you see it: builds every mesh the game makes on demand (every
## building at every look, construction sites, placement ghosts, items,
## people, decor, obstacles), draws each kind of material once so its shader
## is compiled (WebGL compiles shaders on first use, every session), opens
## every panel once (fonts, styles), and plays each effect once.
##
## The work comes as a list of small steps; the loading screen runs a few per
## frame so its progress bar keeps moving smoothly. Things are drawn on a
## stage at the camera's focus, under the cover, and freed a few frames later.

var world: World
var hud: Node
var steps: Array[Callable] = []
var _stage: Node3D
var _trash: Array = []           # [node, frames left]
var _uid := -100000


func _init(p_world: World, p_hud: Node) -> void:
	world = p_world
	hud = p_hud
	_stage = Node3D.new()
	_stage.name = "Warmup"
	world.add_child(_stage)
	_stage.global_position = world.cam.global_position
	Sfx.hush = true
	_plan()


func _plan() -> void:
	# every building at every look, and as a construction site
	for kind in Defs.BUILD_ORDER:
		var lv := _tier_levels(kind)
		for l in lv:
			steps.append(_building.bind(kind, l))
		steps.append(_building.bind(kind, 0))
		steps.append(_ghost.bind(kind))
	# materials that only show up now and then
	steps.append(_materials)
	# items: ingredients, then cookies, boxes and gifts of every recipe
	for t in Defs.ITEMS:
		steps.append(_item.bind(t))
	for r in Defs.RECIPES:
		steps.append(_cookie.bind(r["id"]))
	# people
	for look in Character.LOOKS:
		steps.append(_person.bind(look))
	# the land: decor of every biome, obstacles
	for k in Terrain.DECOR:
		steps.append(_mesh.bind("decor_" + k, Terrain.decor_mesh.bind(k)))
	for k in Defs.OBSTACLES:
		steps.append(_mesh.bind("obstacle_" + k, TownArt.obstacle.bind(k)))
	steps.append(_effects)
	# every panel once
	if hud:
		for tab in Defs.TABS:
			steps.append(_panel.bind("build", tab[0]))
		for p in ["staff", "research", "settings", "recipes", "building"]:
			steps.append(_panel.bind(p, ""))


## Levels that show each visual tier (and the top level, for level props).
static func _tier_levels(kind: String) -> Array[int]:
	var out: Array[int] = []
	var mx := Bal.max_level(kind)
	var tiers := Bal._tiers(kind)
	for t in tiers:
		if t <= mx and not out.has(t):
			out.append(t)
	if not out.has(mx):
		out.append(mx)
	return out


## Runs steps for up to `budget_ms`; true when everything is done.
func run(budget_ms: float) -> bool:
	_sweep()
	var t0 := Time.get_ticks_usec()
	while not steps.is_empty():
		var f: Callable = steps.pop_front()
		f.call()
		if (Time.get_ticks_usec() - t0) / 1000.0 >= budget_ms:
			break
	return steps.is_empty() and _trash.is_empty()


func finish() -> void:
	for e in _trash:
		if is_instance_valid(e[0]):
			e[0].queue_free()
	_trash.clear()
	if is_instance_valid(_stage):
		_stage.queue_free()
	Sfx.hush = false


## Keeps a node on stage for a few frames (so it gets drawn), then frees it.
func _show(n: Node, frames := 3) -> void:
	_trash.append([n, frames])


func _sweep() -> void:
	for i in range(_trash.size() - 1, -1, -1):
		var e: Array = _trash[i]
		e[1] = int(e[1]) - 1
		if int(e[1]) <= 0:
			if is_instance_valid(e[0]):
				e[0].queue_free()
			_trash.remove_at(i)


# ---------------------------------------------------------------- steps

func _building(kind: String, lvl: int) -> void:
	_uid -= 1
	var c := Grid.cell_of(_stage.global_position)
	var d := {"uid": _uid, "kind": kind, "cell": [c.x, c.y], "rot": 0, "lvl": lvl, "data": {}}
	if kind == "mega":
		d["stage"] = 4 if lvl > 0 else 0
	var n := Building.create(world, d)
	n.process_mode = Node.PROCESS_MODE_DISABLED
	_stage.add_child(n)
	n.remove_from_group("buildings")
	_show(n)


func _ghost(kind: String) -> void:
	var mi := MeshInstance3D.new()
	mi.mesh = Previews.mesh(kind, "", 0)
	mi.material_override = Mats.ghost()
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_stage.add_child(mi)
	_show(mi)


func _materials() -> void:
	var k := MeshKit.new()
	k.rbox(Vector3(1, 0.05, 1), 0.1, Color(1, 1, 1, 0.5))
	var quad := k.commit()
	var mats: Array[Material] = [Mats.tiles(), Mats.flat(Color(1.0, 0.86, 0.42, 0.95)), Mats.flat(Color(1.0, 0.92, 0.6, 0.85)),
		Mats.flat(Color(1, 1, 1)), Mats.flat(Color(1, 1, 1, 0.9), true), Mats.glow(), Mats.glass(), Mats.inked()]
	for m in mats:
		var mi := MeshInstance3D.new()
		mi.mesh = quad
		mi.material_override = m
		_stage.add_child(mi)
		_show(mi)


func _item(t: String) -> void:
	var n := Items.node(t)
	_stage.add_child(n)
	_show(n)


func _cookie(rid: String) -> void:
	for p in ["t:", "b:", "a:"]:
		_item(p + rid)


func _person(look: String) -> void:
	var ch := Character.new()
	_stage.add_child(ch)
	ch.setup(look, 3)
	ch.process_mode = Node.PROCESS_MODE_DISABLED
	_show(ch)


func _mesh(key: String, build: Callable) -> void:
	var mi := Mats.inst(MeshKit.cached(key, build), _stage)
	_show(mi)


func _effects() -> void:
	var p := _stage.global_position
	Fx.puff(_stage, p, Pal.CREAM, 3)
	Fx.burst(_stage, p, Pal.GOLD, 6)
	Fx.coins(_stage, p, 3)
	Fx.ring(_stage, p, Pal.MINT, 1.0)
	UI3D.pop_text(_stage, p + Vector3(0, 2, 0), "+$1", Color(1.0, 0.88, 0.3), 80)
	var b := UI3D.badge("power", Pal.STEEL_DARK, 0.6)
	_stage.add_child(b)
	_show(b)
	var ic := UI3D.icon("gem")
	_stage.add_child(ic)
	_show(ic)


func _panel(which: String, arg: String) -> void:
	var s: Sheet
	match which:
		"build":
			BuildPanel.last_tab = arg
			s = BuildPanel.new()
		"staff": s = StaffPanel.new()
		"research": s = ResearchPanel.new()
		"settings": s = SettingsPanel.new()
		"recipes":
			var bs := world.buildings_of("server")
			if bs.is_empty():
				return
			s = RecipePanel.new().setup(bs[0])
		"building":
			var bs2 := world.buildings_of("server")
			if bs2.is_empty():
				return
			s = BuildingPanel.new().setup(world, bs2[0], "")
	s.process_mode = Node.PROCESS_MODE_DISABLED
	hud.add_child(s)
	s.flush()
	_show(s, 2)
